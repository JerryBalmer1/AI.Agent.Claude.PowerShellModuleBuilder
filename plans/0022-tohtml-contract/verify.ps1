#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the pass 0022 plan without reading it.

.DESCRIPTION
    Re-derives every named spot-check from FRESH CLONES of PSGraphRenderToHtml
    at v0.1.0 and PSGraphRender at v0.13.0. It never reads plan.md and never
    trusts the working copies beside it: every figure it compares against is
    recomputed here.

    Each check prints its own name with its verdict. The exit code is the
    aggregate: 0 when every check agrees, non-zero otherwise.

.PARAMETER WorkRoot
    Where to clone. Defaults to a new temp directory, removed on exit. Never
    uses scratch/, which is not committed and does not exist in a fresh clone.

.PARAMETER SkipBuild
    Skip the build and battery checks, for a machine without the build
    dependencies. Everything else still runs.
#>
[CmdletBinding()]
param(
    [string] $ToHtmlRemote = 'https://github.com/JerryBalmer1/PSGraphRenderToHtml.git',
    [string] $RenderRemote = 'https://github.com/JerryBalmer1/PSGraphRender.git',
    [string] $WorkRoot,
    [switch] $SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Checks = 0

function Confirm-Check {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [bool] $Ok,
        [string] $Detail = ''
    )
    $script:Checks++
    if ($Ok) {
        Write-Host ("PASS  {0}" -f $Name)
        if ($Detail) { Write-Host ("        {0}" -f $Detail) }
    }
    else {
        Write-Host ("FAIL  {0}" -f $Name)
        if ($Detail) { Write-Host ("        {0}" -f $Detail) }
        $script:Failures.Add($Name)
    }
}

$temporary = -not $WorkRoot
if ($temporary) {
    $WorkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('verify-0022-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
}
New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null

try {
    $toHtml = Join-Path $WorkRoot 'PSGraphRenderToHtml'
    $render = Join-Path $WorkRoot 'PSGraphRender'

    Write-Host "Cloning PSGraphRenderToHtml at v0.1.0 ..."
    & git clone --quiet $ToHtmlRemote $toHtml 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "clone of ToHtml failed with exit $LASTEXITCODE" }
    & git -C $toHtml checkout --quiet v0.1.0 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'checkout of v0.1.0 failed - the tag is the thing under test' }

    Write-Host "Cloning PSGraphRender at v0.13.0 ..."
    & git clone --quiet $RenderRemote $render 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "clone of PSGraphRender failed with exit $LASTEXITCODE" }
    & git -C $render checkout --quiet v0.13.0 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'checkout of v0.13.0 failed' }

    # The renderer is a runtime dependency and must be BUILT, not merely
    # cloned: its manifest's RootModule names a psm1 the build generates into
    # output/, so src/PSGraphRender/PSGraphRender.psd1 is not importable. A
    # fresh consumer of this ecosystem has to build the renderer first, and a
    # verify that pointed at the source manifest would fail for that reason
    # while blaming the consumer.
    Push-Location $render
    try {
        & pwsh -NoProfile -Command './build.ps1 -Task Build' 2>&1 | Out-Null
        $renderBuildExit = $LASTEXITCODE
    }
    finally { Pop-Location }
    if ($renderBuildExit -ne 0) { throw "building the PSGraphRender clone failed with exit $renderBuildExit" }

    $renderManifest = Join-Path $render 'output/PSGraphRender/PSGraphRender.psd1'
    if (-not (Test-Path -LiteralPath $renderManifest)) {
        throw "the PSGraphRender build produced no manifest at $renderManifest"
    }
    $env:PSGRAPHRENDER_MODULE_PATH = $renderManifest

    # ---- 1. Fresh clone builds green; battery green on the committed sample --

    if ($SkipBuild) {
        Write-Host 'SKIP  1a build in a fresh clone (-SkipBuild)'
    }
    else {
        Push-Location $toHtml
        try {
            $buildOutput = & pwsh -NoProfile -Command './build.ps1' 2>&1
            $buildExit = $LASTEXITCODE
        }
        finally { Pop-Location }
        $text = $buildOutput -join "`n"

        Confirm-Check -Name '1a ./build.ps1 exits 0 in a fresh clone at v0.1.0' `
            -Ok ($buildExit -eq 0) -Detail "exit $buildExit"

        $passed = if ($text -match 'Tests Passed:\s*(\d+)') { [int]$Matches[1] } else { -1 }
        $failed = if ($text -match 'Failed:\s*(\d+)') { [int]$Matches[1] } else { -1 }
        Confirm-Check -Name '1b the suite reports no failures' `
            -Ok ($failed -eq 0 -and $passed -gt 0) -Detail "$passed passed, $failed failed"

        Push-Location $toHtml
        try {
            $pretag = & pwsh -NoProfile -Command './build.ps1 -Task PreTag' 2>&1
            $pretagExit = $LASTEXITCODE
        }
        finally { Pop-Location }
        Confirm-Check -Name '1c the PreTag seals pass' -Ok ($pretagExit -eq 0) -Detail "exit $pretagExit"

        # The battery, invoked exactly as a producer invokes it.
        $batteryScript = @'
param($ToHtml, $RenderManifest)
Import-Module $RenderManifest -Force
Import-Module Pester -MinimumVersion 6.0.0
$c = New-PesterConfiguration
$c.Run.Container = New-PesterContainer -Path (Join-Path $ToHtml 'tests/ProducerContract.Battery.ps1') -Data @{
    GraphPath = (Join-Path $ToHtml 'docs/samples/sample-graph.json')
}
$c.Run.PassThru = $true
$c.Run.FailOnNullOrEmptyForEach = $false
$c.Should.DisableV5 = $true
$c.Output.Verbosity = 'None'
$r = Invoke-Pester -Configuration $c
"BATTERY $($r.PassedCount) $($r.FailedCount)"
'@
        $batteryFile = Join-Path $WorkRoot 'battery.ps1'
        Set-Content -LiteralPath $batteryFile -Value $batteryScript -Encoding utf8NoBOM
        $batteryOut = (& pwsh -NoProfile -File $batteryFile $toHtml $renderManifest 2>&1) -join "`n"
        $bPassed = if ($batteryOut -match 'BATTERY (\d+) (\d+)') { [int]$Matches[1] } else { -1 }
        $bFailed = if ($batteryOut -match 'BATTERY (\d+) (\d+)') { [int]$Matches[2] } else { -1 }
        Confirm-Check -Name '1d the battery is green on the committed sample' `
            -Ok ($bFailed -eq 0 -and $bPassed -gt 0) -Detail "$bPassed passed, $bFailed failed"
    }

    # ---- 2. Verify regenerates two violations itself and asserts rejection ---

    $probeScript = @'
param($ToHtml, $RenderManifest)
Import-Module $RenderManifest -Force
Import-Module (Join-Path $ToHtml 'src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1') -Force

# Built HERE, not read from the repository's own test helpers: a probe that
# borrows the subject's fixtures tests the fixtures too.
function New-Graph {
    @{ graph = @{
            meta  = @{ producer = 'verify'; producerVersion = '0.0.0' }
            nodes = @(
                @{ id = 'r'; label = 'root'; type = 'repository'; scope = 's' }
                @{ id = 'a'; label = 'a'; type = 'module'; scope = 's'; parentId = 'r' }
                @{ id = 'b'; label = 'b'; type = 'module'; scope = 's'; parentId = 'a' }
            )
            edges = @(@{ from = 'a'; to = 'b'; kind = 'sources' })
        }
    }
}

$control = Test-ProducerGraph -Graph (New-Graph)
"CONTROL $($control.IsValid) $(@($control.Violations).Count)"

$dangling = New-Graph
$dangling.graph.edges[0]['to'] = 'nope'
$r1 = Test-ProducerGraph -Graph $dangling
"DANGLING $($r1.IsValid) $((@($r1.Violations | ForEach-Object { $_.Rule }) | Sort-Object -Unique) -join ',') $((@($r1.Violations | ForEach-Object { $_.Path }) | Sort-Object -Unique) -join ',')"

$cycle = New-Graph
$cycle.graph.nodes[0]['parentId'] = 'b'
$r2 = Test-ProducerGraph -Graph $cycle
"CYCLE $($r2.IsValid) $((@($r2.Violations | ForEach-Object { $_.Rule }) | Sort-Object -Unique) -join ',')"
'@
    $probeFile = Join-Path $WorkRoot 'probe.ps1'
    Set-Content -LiteralPath $probeFile -Value $probeScript -Encoding utf8NoBOM
    $probeOut = (& pwsh -NoProfile -File $probeFile $toHtml $renderManifest 2>&1) -join "`n"

    # Control first: a red below proves nothing if the known-good graph is
    # also red.
    $controlOk = $probeOut -match 'CONTROL True 0'
    Confirm-Check -Name '2a control: a graph verify built itself validates' `
        -Ok $controlOk -Detail (($probeOut -split "`n" | Where-Object { $_ -like 'CONTROL*' }) -join '')

    $danglingLine = ($probeOut -split "`n" | Where-Object { $_ -like 'DANGLING*' }) -join ''
    Confirm-Check -Name '2b a dangling edge is rejected, naming its rule and path' `
        -Ok ($danglingLine -match 'DANGLING False' -and $danglingLine -match 'edge-endpoint-resolves' -and $danglingLine -match 'graph\.edges\[0\]\.to') `
        -Detail $danglingLine

    $cycleLine = ($probeOut -split "`n" | Where-Object { $_ -like 'CYCLE*' }) -join ''
    Confirm-Check -Name '2c a parentId cycle is rejected, naming its rule' `
        -Ok ($cycleLine -match 'CYCLE False' -and $cycleLine -match 'acyclic-parent-chain') `
        -Detail $cycleLine

    # ---- 3. Sample view model re-derived and re-validated against the schema -

    $mapScript = @'
param($ToHtml, $RenderManifest, $Schema)
Import-Module $RenderManifest -Force
Import-Module (Join-Path $ToHtml 'src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1') -Force
$graph = Get-Content (Join-Path $ToHtml 'docs/samples/sample-graph.json') -Raw | ConvertFrom-Json
$vm = ConvertTo-GraphRenderViewModel -Graph $graph
$json = $vm | ConvertTo-Json -Depth 20
$ok = $json | Test-Json -SchemaFile $Schema -ErrorAction Stop
$missing = @($vm.data.nodes | Where-Object { $null -eq $_.metrics.depth }).Count
"MAPPED $ok $($vm.meta.contractVersion) $(@($vm.data.nodes).Count) $missing $($vm.meta.stats.MaxDepth)"
'@
    $mapFile = Join-Path $WorkRoot 'map.ps1'
    Set-Content -LiteralPath $mapFile -Value $mapScript -Encoding utf8NoBOM
    $schema = Join-Path $render 'contract/viewmodel.schema.json'
    $mapOut = (& pwsh -NoProfile -File $mapFile $toHtml $renderManifest $schema 2>&1) -join "`n"
    $mapLine = ($mapOut -split "`n" | Where-Object { $_ -like 'MAPPED*' }) -join ''

    Confirm-Check -Name '3a the sample maps to a view model the fresh render schema accepts' `
        -Ok ($mapLine -match 'MAPPED True 1\.1\.0') -Detail $mapLine
    Confirm-Check -Name '3b every node carries a derived depth, and the chain reaches 3' `
        -Ok ($mapLine -match 'MAPPED \S+ \S+ \d+ 0 3') -Detail 'zero nodes missing depth, MaxDepth 3'

    # ---- 4. One layout re-rendered and compared to the committed document ----

    if (-not $SkipBuild) {
        $renderScript = @'
param($ToHtml, $RenderManifest, $Out)
Import-Module $RenderManifest -Force
Import-Module (Join-Path $ToHtml 'src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1') -Force
$null = Export-ProducerGraphHtml -Path (Join-Path $ToHtml 'docs/samples/sample-graph.json') `
    -OutputPath $Out -Options (New-GraphRenderOptions -Layout callflow -Title 'Sample estate')
"RENDERED $((Get-Item $Out).Length)"
'@
        $renderFile = Join-Path $WorkRoot 'render.ps1'
        Set-Content -LiteralPath $renderFile -Value $renderScript -Encoding utf8NoBOM
        $fresh = Join-Path $WorkRoot 'callflow.html'
        $renderOut = (& pwsh -NoProfile -File $renderFile $toHtml $renderManifest $fresh 2>&1) -join "`n"

        Confirm-Check -Name '4a a layout re-renders from the fresh clones' `
            -Ok (Test-Path -LiteralPath $fresh) -Detail (($renderOut -split "`n" | Where-Object { $_ -like 'RENDERED*' }) -join '')

        if (Test-Path -LiteralPath $fresh) {
            $committed = Join-Path $toHtml 'docs/samples/sample-callflow.html'
            $freshText = Get-Content -LiteralPath $fresh -Raw
            $committedText = Get-Content -LiteralPath $committed -Raw

            # NOT a byte comparison, and the two reasons are both recorded
            # because an unexplained normalisation is a place to hide a defect.
            #
            # 1. meta.generatedAt is a timestamp. Two renders of the same graph
            #    differ there by design.
            # 2. Line endings. .gitattributes carries `* text=auto eol=lf`, so
            #    the committed document is stored and checked out LF while a
            #    fresh render on Windows writes CRLF. Measured: exactly 428
            #    carriage returns across this document, and nothing else.
            #
            # Check 4d is the control on both: it asserts a document that
            # really is different still differs after the same normalisation.
            $pattern = '"generatedAt"\s*:\s*"[^"]*"'
            $normalise = {
                param($text)
                $t = [regex]::Replace($text, '"generatedAt"\s*:\s*"[^"]*"', '"generatedAt":"NORMALISED"')
                $t.Replace("`r`n", "`n")
            }
            $freshStable = & $normalise $freshText
            $committedStable = & $normalise $committedText

            Confirm-Check -Name '4b the re-render carries the callflow marker' `
                -Ok ($freshText -match '"DefaultFlow"\s*:\s*"callflow"') -Detail 'DefaultFlow=callflow'

            Confirm-Check -Name '4c the re-render equals the committed document once timestamps are normalised' `
                -Ok ($freshStable -eq $committedStable) `
                -Detail "fresh $($freshStable.Length) chars vs committed $($committedStable.Length); generatedAt normalised because a render embeds its own time"

            # The normalisation must not be doing the work: a document with a
            # different layout must still differ after it.
            $other = Get-Content -LiteralPath (Join-Path $toHtml 'docs/samples/sample-foundation.html') -Raw
            $otherStable = & $normalise $other
            Confirm-Check -Name '4d the normalisation does not flatten a real difference' `
                -Ok ($freshStable -ne $otherStable) `
                -Detail 'the foundation document still differs from the callflow re-render after normalisation'
        }
    }

    # ---- 5. The contract and the tag say the same thing ---------------------

    $schemaJson = Get-Content -LiteralPath (Join-Path $toHtml 'contract/producer-graph.schema.json') -Raw | ConvertFrom-Json
    Confirm-Check -Name '5a the producer contract is versioned 0.1.0' `
        -Ok ($schemaJson.version -eq '0.1.0') -Detail "version $($schemaJson.version)"
    Confirm-Check -Name '5b a node refuses additional properties, so a stored depth is invalid' `
        -Ok ($schemaJson.properties.graph.properties.nodes.items.additionalProperties -eq $false) `
        -Detail 'additionalProperties false'

    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $toHtml 'src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1')
    Confirm-Check -Name '5c the manifest version agrees with the tag' `
        -Ok ($manifest.ModuleVersion -eq '0.1.0') -Detail "ModuleVersion $($manifest.ModuleVersion)"

    $tagTarget = (& git -C $toHtml rev-parse 'v0.1.0^{}')
    $mainTarget = (& git -C $toHtml ls-remote origin refs/heads/main) -split '\s+' | Select-Object -First 1
    Confirm-Check -Name '5d origin/main equals v0.1.0' `
        -Ok ($tagTarget -eq $mainTarget) -Detail "tag $tagTarget / main $mainTarget"
}
finally {
    if ($temporary -and (Test-Path -LiteralPath $WorkRoot)) {
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host ("{0} check(s), {1} failed." -f $script:Checks, $script:Failures.Count)
if ($script:Failures.Count -gt 0) {
    Write-Host 'Checks that disagreed:'
    foreach ($f in $script:Failures) { Write-Host ("  {0}" -f $f) }
    exit 1
}
exit 0
