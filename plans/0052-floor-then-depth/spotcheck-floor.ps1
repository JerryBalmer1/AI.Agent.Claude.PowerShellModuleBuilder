#Requires -Version 7.0
<#
    SPOT-CHECK SC1 — the instrument survives every shipped background.

    Builds one scratch template set per value of every environment setting the
    3D backend declares, renders each one twice (with a payload and with
    nothing), and puts the repaired floor through four questions:

      separate  every environment separates a drawn view from an empty one
      noise     an empty document against a second capture of itself scores ~0,
                which is what a per-channel threshold of 12 is FOR
      blind     the old byte ratio, on a painted background, is still under the
                floor it used to carry - the red, kept runnable
      dark      a corrupted drawing falls under the floor, so the gate can
                still see a page that stopped drawing

    THE ENVIRONMENT VALUES ARE READ FROM THE SCHEMA, never listed here. A list
    in this file would go stale the day a value is added, and the value nobody
    added to the list is the one nobody checks.

    Exits 0 when every case agrees, non-zero otherwise.

      pwsh -NoProfile -File spotcheck-floor.ps1 -RenderRepo <path> [-Out <file>]
#>
param(
    [Parameter(Mandatory)] [string] $RenderRepo,
    [string] $Out,
    [int] $ChannelThreshold = 12,

    # Two captures of one empty document should differ in nothing. A ceiling
    # rather than zero because a ceiling can FAIL: asserting equality would make
    # the case unable to report how far off it was.
    [double] $NoiseCeiling = 0.0005
)

$ErrorActionPreference = 'Stop'

$manifestPath = Join-Path $RenderRepo 'output/PSGraphRender/PSGraphRender.psd1'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "No built module at $manifestPath. Run ./build.ps1 -Task Build in $RenderRepo first."
}
Import-Module $manifestPath -Force

$shipped = Join-Path $RenderRepo 'output/PSGraphRender/TemplateSets/forcegraph3d'
$setManifest = Import-PowerShellDataFile -LiteralPath (Join-Path $shipped 'templateset.psd1')
$schema = (Import-PowerShellDataFile -LiteralPath (Join-Path $shipped 'Config/settings.schema.psd1')).Entries

$selector = @($setManifest.Smoke.CanvasDelta.Keys)[0]
$floor = $setManifest.Smoke.CanvasDelta[$selector]
if (-not $selector) { throw 'the 3D backend declares no CanvasDelta selector, so there is no floor to spot-check' }

# Every Enum in the Environment group, and every one of its values. Derived, so
# a family added to the schema arrives already covered.
$environmentKeys = @(
    $schema.Keys | Where-Object { $schema[$_].Group -eq 'Environment' -and $schema[$_].Type -eq 'Enum' } | Sort-Object
)
if ($environmentKeys.Count -eq 0) {
    throw 'no Enum setting in the Environment group; this spot-check would check nothing, which is not the same as passing'
}

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) "psgraphrender-0052-sc1-$PID"
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

try {
    $payload = Get-Content -LiteralPath (Join-Path $RenderRepo 'tests/fixtures/viewmodels/sample-module.json') -Raw |
        ConvertFrom-Json

    function New-ScratchSet {
        param([string] $Name, [hashtable] $Setting, [scriptblock] $Corrupt)

        $dest = Join-Path $scratch "set-$Name"
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        Copy-Item -LiteralPath $shipped -Destination $dest -Recurse -Force

        foreach ($key in $Setting.Keys) {
            if (-not $schema.Contains($key)) { throw "no schema entry for '$key'; a probe may only move declared settings" }
            $file = Join-Path $dest ('Config/' + $(if ($schema[$key].In -eq 'Settings') { 'settings.psd1' } else { 'theme.psd1' }))
            $text = [System.IO.File]::ReadAllText($file)
            $value = $Setting[$key]
            $assignment = if ($value -is [string]) { "    $key = '$($value.Replace("'", "''"))'" } else { "    $key = $value" }
            if ($text -match "(?m)^\s*$key\s*=") { $text = $text -replace "(?m)^\s*$key\s*=.*$", $assignment.Replace('$', '$$') }
            else { $text = $text.Insert($text.LastIndexOf('}'), $assignment + "`n") }
            [System.IO.File]::WriteAllText($file, $text)

            # The mutation is PROVED to have landed. A probe whose edit silently
            # did nothing reports the strongest result for the weakest reason.
            $back = (Import-PowerShellDataFile -LiteralPath $file)[$key]
            if ("$back" -ne "$value") { throw "the scratch set '$Name' still reads $key='$back' and '$value' was written" }
        }

        if ($Corrupt) { & $Corrupt $dest }
        $dest
    }

    function New-Pair {
        param([string] $Name, [string] $Set)
        $drawn = Join-Path $scratch "$Name-drawn.html"
        [System.IO.File]::WriteAllText($drawn, (New-RenderDocument -ViewModel $payload.data -Meta $payload.meta `
                    -Title 'sc1 drawn' -TemplateSetPath $Set))
        $empty = Join-Path $scratch "$Name-empty.html"
        [System.IO.File]::WriteAllText($empty, (New-RenderDocument `
                    -ViewModel ([pscustomobject]@{ nodes = @(); links = @() }) `
                    -Title 'sc1 empty' -TemplateSetPath $Set))
        @{ Drawn = $drawn; Empty = $empty }
    }

    $cases = @()

    # -- separate: every value of every environment setting --------------
    foreach ($key in $environmentKeys) {
        foreach ($value in @($schema[$key].Values)) {
            $name = "$key-$value"
            $pair = New-Pair -Name $name -Set (New-ScratchSet -Name $name -Setting @{ $key = $value })
            $cases += @{
                kind = 'separate'; name = $name; note = "$key = $value"
                a = $pair.Drawn; b = $pair.Empty; selector = $selector; floor = $floor
            }
        }
    }

    # -- noise: one empty document against a second capture of itself ----
    $flatSet = New-ScratchSet -Name 'noise' -Setting @{}
    $flatPair = New-Pair -Name 'noise' -Set $flatSet
    $cases += @{
        kind = 'noise'; name = 'empty-against-itself'; note = 'the same empty document, captured twice'
        a = $flatPair.Empty; b = $flatPair.Empty; selector = $selector; ceiling = $NoiseCeiling
    }

    # -- blind: the red, kept runnable -----------------------------------
    # The value the old ratio could not see through, against the floor the old
    # metric shipped at v0.16.0. Named here rather than derived, because it is
    # a historical number and there is nowhere left in the tree that holds it.
    $blindValue = 'vignette'
    $blindKey = 'BackgroundStyle'
    if ($schema.Contains($blindKey) -and @($schema[$blindKey].Values) -contains $blindValue) {
        $blindPair = New-Pair -Name 'blind' -Set (New-ScratchSet -Name 'blind' -Setting @{ $blindKey = $blindValue })
        $cases += @{
            kind = 'blind'; name = "old-ratio-on-$blindValue"; note = "$blindKey = $blindValue under the metric v0.16.0 shipped"
            a = $blindPair.Drawn; b = $blindPair.Empty; selector = $selector; oldFloor = 2.25
        }
    }
    else {
        throw "the schema no longer declares $blindKey = '$blindValue', so the red this spot-check preserves cannot be run"
    }

    # -- dark: the drawing CORRUPTED, never removed ----------------------
    # 0050's form. Deleting a script makes the page throw and every gate in the
    # repository goes red at once, which proves nothing about this one. A
    # payload the page cannot draw leaves the DOM assertions, the counts and
    # the link probe exactly as they were, and only a picture can tell.
    $dark = New-ScratchSet -Name 'dark' -Setting @{} -Corrupt {
        param($dest)
        $graph = Join-Path $dest 'scripts/graph.js'
        $text = [System.IO.File]::ReadAllText($graph)

        # The one line that hands the payload to the library, emptied. Chosen
        # because it is the narrowest edit that stops the drawing without
        # stopping the page: fillStatus still runs, #fg-nodes still says 9,
        # #fg canvas still exists, and nothing throws.
        $before = $text
        $text = $text -replace '\.graphData\(\{ nodes: laidOut, links: links\.slice\(\) \}\)', '.graphData({ nodes: [], links: [] })'
        if ($text -eq $before) { throw 'the corruption did not match anything in graph.js, so the falsification probe would prove nothing' }
        [System.IO.File]::WriteAllText($graph, $text)
    }
    $darkPair = New-Pair -Name 'dark' -Set $dark
    $cases += @{
        kind = 'dark'; name = 'corrupted-drawing'; note = 'graph.js hands the library an empty payload; every DOM assertion still passes'
        a = $darkPair.Drawn; b = $darkPair.Empty; selector = $selector; floor = $floor
    }

    $jobFile = Join-Path $scratch 'job.json'
    [System.IO.File]::WriteAllText($jobFile, (@{ cases = $cases; threshold = $ChannelThreshold } | ConvertTo-Json -Depth 8))

    $probe = Join-Path $PSScriptRoot 'spotcheck-floor.cjs'

    # The browser lives in the RENDERER's tree and this probe lives in the
    # harness's, so node cannot resolve it: module resolution walks up from the
    # script's directory and never from the working one. Told, not guessed.
    $playwright = Join-Path $RenderRepo 'tests/browser/node_modules/playwright'
    if (-not (Test-Path -LiteralPath $playwright)) {
        throw "No browser harness at $playwright. Run ./build.ps1 -Task BootstrapBrowser in $RenderRepo first."
    }
    $env:PSGR_PLAYWRIGHT = $playwright
    try { $text = (& node $probe $jobFile 2>&1 | Out-String); $exit = $LASTEXITCODE }
    finally { Remove-Item Env:\PSGR_PLAYWRIGHT -ErrorAction SilentlyContinue }

    Write-Host $text
    if ($Out) { [System.IO.File]::WriteAllText($Out, $text) }

    $report = $text | ConvertFrom-Json
    Write-Host ''
    Write-Host ('{0,-28} {1,-9} {2,10} {3,8} {4,6}' -f 'case', 'kind', 'fraction', 'ratio', 'ok')
    foreach ($r in $report.rows) {
        Write-Host ('{0,-28} {1,-9} {2,10} {3,8} {4,6}' -f $r.case, $r.kind, $r.fraction, $r.ratio, $r.ok)
        if (-not $r.ok) { Write-Host ("    -> $($r.why)") }
    }
    Write-Host ''
    Write-Host "SC1: $($report.cases) case(s), $($report.failed) failed, floor $floor on $selector, threshold $ChannelThreshold/255"
    exit $exit
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
