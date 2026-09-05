#Requires -Version 7.0
<#
    PASS 0052, PART 1, THE RED.

    Renders the 3D backend twice under each of two backgrounds - once with a
    payload and once with nothing - and runs both floor metrics over the four
    pictures.

    The claim being demonstrated is finding 67's: the shipped floor is a ratio
    of PNG byte lengths against an empty render of the same backend, and a
    painted background is in both pictures. Under `flat` the ratio separates a
    drawn view from a blank one. Under `vignette` it does not, and the shipped
    floor of 2.25 would fail a page that is drawing correctly.

    Nothing here is fixed. This script only observes, and it observes with the
    OLD metric alongside the new one so the red is a comparison rather than an
    announcement.

    Run from anywhere:
      pwsh -NoProfile -File observe-blindness.ps1 -RenderRepo <path> [-Out <file>]
#>
param(
    [Parameter(Mandatory)] [string] $RenderRepo,
    [string] $Out,
    [int] $ChannelThreshold = 12,
    [string] $Fixture = 'tests/fixtures/viewmodels/sample-module.json'
)

$ErrorActionPreference = 'Stop'

$manifest = Join-Path $RenderRepo 'output/PSGraphRender/PSGraphRender.psd1'
if (-not (Test-Path -LiteralPath $manifest)) {
    throw "No built module at $manifest. Run ./build.ps1 -Task Build in $RenderRepo first."
}
Import-Module $manifest -Force

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) "psgraphrender-0052-observe-$PID"
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

try {
    $payload = Get-Content -LiteralPath (Join-Path $RenderRepo $Fixture) -Raw | ConvertFrom-Json
    $shipped = Join-Path $RenderRepo 'output/PSGraphRender/TemplateSets/forcegraph3d'

    # A caller-owned copy per background. The shipped set is never edited: a
    # probe that rewrites what ships has stopped measuring what ships.
    function New-BackgroundSet {
        param([string] $Style)
        $dest = Join-Path $scratch "set-$Style"
        Copy-Item -LiteralPath $shipped -Destination $dest -Recurse -Force
        $themeFile = Join-Path $dest 'Config/theme.psd1'
        $text = [System.IO.File]::ReadAllText($themeFile)
        $text = $text -replace "(?m)^\s*BackgroundStyle\s*=.*$", "    BackgroundStyle     = '$Style'"
        [System.IO.File]::WriteAllText($themeFile, $text)

        # Proof the edit landed, because a probe whose mutation silently did
        # nothing reports the strongest result for the weakest reason.
        $back = (Import-PowerShellDataFile -LiteralPath $themeFile).BackgroundStyle
        if ($back -ne $Style) { throw "the scratch set for '$Style' still reads BackgroundStyle='$back'" }
        $dest
    }

    $cases = @()
    foreach ($style in 'flat', 'vignette') {
        $set = New-BackgroundSet -Style $style

        $drawn = Join-Path $scratch "$style-drawn.html"
        [System.IO.File]::WriteAllText($drawn, (New-RenderDocument -ViewModel $payload.data -Meta $payload.meta `
                    -Title 'observe drawn' -TemplateSetPath $set))

        $empty = Join-Path $scratch "$style-empty.html"
        [System.IO.File]::WriteAllText($empty, (New-RenderDocument `
                    -ViewModel ([pscustomobject]@{ nodes = @(); links = @() }) `
                    -Title 'observe empty' -TemplateSetPath $set))

        $cases += @{
            name       = "forcegraph3d/$style"
            background = $style
            drawn      = $drawn
            empty      = $empty
            selector   = '#fg'
        }
    }

    $jobFile = Join-Path $scratch 'job.json'
    [System.IO.File]::WriteAllText($jobFile, (@{ cases = $cases; threshold = $ChannelThreshold } | ConvertTo-Json -Depth 8))

    $probe = Join-Path $PSScriptRoot 'observe-blindness.cjs'
    $env:NODE_PATH = Join-Path $RenderRepo 'tests/browser/node_modules'
    Push-Location (Join-Path $RenderRepo 'tests/browser')
    try { $text = (& node $probe $jobFile 2>&1 | Out-String) }
    finally { Pop-Location }

    Write-Host $text
    if ($Out) { [System.IO.File]::WriteAllText($Out, $text) }

    $report = $text | ConvertFrom-Json
    Write-Host ''
    Write-Host ('{0,-24} {1,10} {2,10} {3,8} {4,11}' -f 'case', 'empty px', 'drawn px', 'ratio', 'delta')
    foreach ($r in $report.rows) {
        Write-Host ('{0,-24} {1,10} {2,10} {3,8} {4,11}' -f `
                $r.case, $r.oldMetric.emptyBytes, $r.oldMetric.drawnBytes, $r.oldMetric.ratio, $r.newMetric.fraction)
    }
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
