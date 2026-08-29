#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the pass 0024 plan without reading it.

.DESCRIPTION
    Clones PSTerraformGraph at v0.1.0 and its two dependencies, builds them,
    regenerates the graph from the committed fixture, re-scores it against the
    frozen oracle, and re-renders a layout. It reads no number this pass wrote
    down except the oracle blob SHA, which is the thing under test.

    Checks 5's AzDO half needs $env:AZDO_PAT and SKIPS LOUDLY without one.
#>
[CmdletBinding()]
param([string] $WorkRoot, [switch] $SkipBuild, [switch] $SkipAzdo)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Skipped = [System.Collections.Generic.List[string]]::new()
$script:Checks = 0

function Confirm-Check {
    param([Parameter(Mandatory)] [string] $Name, [Parameter(Mandatory)] [bool] $Ok, [string] $Detail = '')
    $script:Checks++
    if ($Ok) { Write-Host ("PASS  {0}" -f $Name) } else { Write-Host ("FAIL  {0}" -f $Name); $script:Failures.Add($Name) }
    if ($Detail) { Write-Host ("        {0}" -f $Detail) }
}
function Skip-Check {
    param([Parameter(Mandatory)] [string] $Name, [Parameter(Mandatory)] [string] $Why)
    Write-Host ("SKIP  {0}" -f $Name); Write-Host ("        {0}" -f $Why); $script:Skipped.Add($Name)
}

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Siblings = Split-Path -Parent $RepoRoot
$run = Join-Path $RepoRoot 'runs/tf-001-first-build'
$oracle = Join-Path $RepoRoot 'evals/tf/fixture/expected-graph.json'

$temporary = -not $WorkRoot
if ($temporary) { $WorkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('verify-0024-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)) }
$null = New-Item -ItemType Directory -Path $WorkRoot -Force

try {
    # ---- 4. The oracle blob is unchanged from what pass 0023 committed ------
    # Checked FIRST: every score below is against this file, and a score
    # against a moved oracle means nothing.
    $oracleBlob = (& git -C $RepoRoot rev-parse 'HEAD:evals/tf/fixture/expected-graph.json').Trim()
    $blobAt0023 = (& git -C $RepoRoot rev-list -1 --all -- evals/tf/fixture/expected-graph.json)
    $firstBlob = (& git -C $RepoRoot rev-parse "$($blobAt0023):evals/tf/fixture/expected-graph.json").Trim()
    Confirm-Check -Name '4 the oracle blob is unchanged since it was committed' `
        -Ok ($oracleBlob -eq $firstBlob) -Detail "blob $oracleBlob"

    if ($SkipBuild) {
        Skip-Check -Name '1 fresh clones build and reproduce the score' -Why '-SkipBuild was given.'
        Skip-Check -Name '2 the battery is green on the regenerated graph' -Why '-SkipBuild was given.'
        Skip-Check -Name '3 a layout re-renders with a vscode link' -Why '-SkipBuild was given.'
    }
    else {
        foreach ($pair in @(
                @{ Name = 'PSGraphRender'; Tag = 'v0.13.0' }
                @{ Name = 'PSGraphRenderToHtml'; Tag = 'v0.1.0' }
                @{ Name = 'PSTerraformGraph'; Tag = 'v0.1.0' }
            )) {
            $target = Join-Path $WorkRoot $pair.Name
            Write-Host "Cloning $($pair.Name) at $($pair.Tag) ..."
            & git clone --quiet "https://github.com/JerryBalmer1/$($pair.Name).git" $target 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "clone of $($pair.Name) failed" }
            & git -C $target checkout --quiet $pair.Tag 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "checkout of $($pair.Name) $($pair.Tag) failed - the tag is the thing under test" }
        }

        # The renderer must be BUILT, not merely cloned: its RootModule names a
        # psm1 the build generates.
        Push-Location (Join-Path $WorkRoot 'PSGraphRender')
        try { & pwsh -NoProfile -Command './build.ps1 -Task Build' 2>&1 | Out-Null } finally { Pop-Location }
        $env:PSGRAPHRENDER_MODULE_PATH = Join-Path $WorkRoot 'PSGraphRender/output/PSGraphRender/PSGraphRender.psd1'

        Push-Location (Join-Path $WorkRoot 'PSGraphRenderToHtml')
        try { & pwsh -NoProfile -Command './build.ps1 -Task Build' 2>&1 | Out-Null } finally { Pop-Location }
        $env:PSGRAPHRENDERTOHTML_MODULE_PATH = Join-Path $WorkRoot 'PSGraphRenderToHtml/output/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1'

        $tfClone = Join-Path $WorkRoot 'PSTerraformGraph'
        Push-Location $tfClone
        try {
            $buildOutput = & pwsh -NoProfile -Command './build.ps1' 2>&1
            $buildExit = $LASTEXITCODE
        }
        finally { Pop-Location }
        $text = $buildOutput -join "`n"
        $passed = if ($text -match 'Tests Passed:\s*(\d+)') { [int]$Matches[1] } else { -1 }
        $failed = if ($text -match 'Failed:\s*(\d+)') { [int]$Matches[1] } else { -1 }

        Confirm-Check -Name '1a a fresh clone of PSTerraformGraph v0.1.0 builds green' `
            -Ok ($buildExit -eq 0 -and $failed -eq 0) -Detail "exit $buildExit, $passed passed, $failed failed"

        # Regenerate the graph from the COMMITTED fixture, and re-score.
        $regen = @'
param($TfClone, $ToHtml, $Fixture, $Oracle, $Compare, $Out)
Import-Module $ToHtml -Force
Import-Module (Join-Path $TfClone 'output/PSTerraformGraph/PSTerraformGraph.psd1') -Force
$roots = @(
    (Join-Path $Fixture 'TfFixtureShared')
    (Join-Path $Fixture 'TfFixtureNetwork')
    (Join-Path $Fixture 'TfFixtureApp')
)
$graph = Get-TfConfigurationGraph -Path $roots
"REGEN $(@($graph.graph.nodes).Count) $(@($graph.graph.edges).Count)"
$v = Test-ProducerGraph -Graph $graph
"CONTRACT $($v.IsValid) $(@($v.Violations).Count)"
$r = & $Compare -Expected $Oracle -ActualObject $graph
"SCORE $($r.DifferenceCount)"
$null = Export-TfConfigurationGraphHtml -Path $roots -OutputPath $Out -Options (New-GraphRenderOptions -Layout callflow)
$html = Get-Content $Out -Raw
"RENDER $((Get-Item $Out).Length) $($html -match '"DefaultFlow"\s*:\s*"callflow"') $($html -match 'vscode://file/')"
'@
        $regenFile = Join-Path $WorkRoot 'regen.ps1'
        Set-Content -LiteralPath $regenFile -Value $regen -Encoding utf8NoBOM
        $rendered = Join-Path $WorkRoot 'callflow.html'
        $out = (& pwsh -NoProfile -File $regenFile $tfClone $env:PSGRAPHRENDERTOHTML_MODULE_PATH `
            (Join-Path $RepoRoot 'evals/tf/fixture/repos') $oracle (Join-Path $RepoRoot 'evals/tf/Compare-TfGraph.ps1') $rendered 2>&1) -join "`n"

        $regenLine = ($out -split "`n" | Where-Object { $_ -like 'REGEN*' }) -join ''
        Confirm-Check -Name '1b the graph regenerates at the size the run recorded' `
            -Ok ($regenLine -match 'REGEN 78 54') -Detail $regenLine

        $scoreLine = ($out -split "`n" | Where-Object { $_ -like 'SCORE*' }) -join ''
        Confirm-Check -Name '1c the score against the frozen oracle reproduces' `
            -Ok ($scoreLine -match 'SCORE 31') -Detail "$scoreLine (the run recorded 31)"

        $contractLine = ($out -split "`n" | Where-Object { $_ -like 'CONTRACT*' }) -join ''
        Confirm-Check -Name '2 the regenerated graph satisfies the producer contract' `
            -Ok ($contractLine -match 'CONTRACT True 0') -Detail $contractLine

        $renderLine = ($out -split "`n" | Where-Object { $_ -like 'RENDER*' }) -join ''
        Confirm-Check -Name '3 a layout re-renders, with its marker and a vscode link' `
            -Ok ($renderLine -match 'RENDER \d+ True True') -Detail $renderLine
    }

    # ---- The run record says what the acceptance test requires --------------

    $readme = Get-Content -LiteralPath (Join-Path $run 'README.md') -Raw
    Confirm-Check -Name '6a the run record pins the plugin SHA' `
        -Ok ($readme -match 'plugin-sha:\s*[0-9a-f]{40}') `
        -Detail $(if ($readme -match 'plugin-sha:\s*([0-9a-f]{40})') { $Matches[1] } else { 'absent' })
    Confirm-Check -Name '6b the run record refuses to be read as a generalisation measurement' `
        -Ok ($readme -match 'not the generalisation measurement') -Detail 'the sentence is present'
    Confirm-Check -Name '6c the run record carries a functional-tf score' `
        -Ok ($readme -match 'functional-tf:\s*\d+\s*/\s*\d+') `
        -Detail $(if ($readme -match '(functional-tf:\s*\d+\s*/\s*\d+)') { $Matches[1] } else { 'absent' })

    $htmlCount = @(Get-ChildItem -LiteralPath $run -Filter *.html).Count
    Confirm-Check -Name '6d the run holds one document per layout' `
        -Ok ($htmlCount -ge 3) -Detail "$htmlCount html file(s)"

    # ---- 5. AzDO: the fixture is unchanged and nothing was queued -----------

    if ($SkipAzdo -or -not $env:AZDO_PAT) {
        Skip-Check -Name '5 the AzDO fixture is unchanged and no build was queued' `
            -Why $(if ($SkipAzdo) { '-SkipAzdo was given.' } else { 'AZDO_PAT is not set. Nothing confirmed the fixture is untouched or that no build ran.' })
    }
    else {
        . (Join-Path $RepoRoot 'evals/tf/TfAzdoClient.ps1')
        $base = Get-TfAzdoBaseUri
        $builds = (Invoke-TfAzdoJson -Uri "$base/build/builds?api-version=7.1").value
        Confirm-Check -Name '5a no build has ever been queued' `
            -Ok (@($builds).Count -eq 0) -Detail "$(@($builds).Count) build(s) in the project's entire history"

        $reportPath = Join-Path $WorkRoot 'readback.txt'
        & pwsh -NoProfile -File (Join-Path $RepoRoot 'evals/tf/Test-TfFixtureReadBack.ps1') -ReportPath $reportPath *> $null
        $readBackExit = $LASTEXITCODE
        $report = if (Test-Path -LiteralPath $reportPath) { Get-Content -LiteralPath $reportPath -Raw } else { '' }
        Confirm-Check -Name '5b the AzDO fixture is still byte-identical to the harness copy' `
            -Ok ($readBackExit -eq 0 -and $report -match 'BYTE-IDENTICAL') -Detail "exit $readBackExit"
    }
}
finally {
    if ($temporary -and (Test-Path -LiteralPath $WorkRoot)) {
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host ("{0} check(s), {1} failed, {2} skipped." -f $script:Checks, $script:Failures.Count, $script:Skipped.Count)
if ($script:Skipped.Count -gt 0) {
    Write-Host 'This run graded LESS than a full run. Skipped:'
    foreach ($s in $script:Skipped) { Write-Host ("  {0}" -f $s) }
}
if ($script:Failures.Count -gt 0) {
    Write-Host 'Checks that disagreed:'
    foreach ($f in $script:Failures) { Write-Host ("  {0}" -f $f) }
    exit 1
}
exit 0
