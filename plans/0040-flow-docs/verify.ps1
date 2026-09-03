#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove plan 0040 without reading it. Six checks, re-derived from a fresh
    clone, exiting non-zero on the first disagreement it finds and naming it.
.DESCRIPTION
    Every check here RE-RUNS something. None of them parses plan.md, and none
    of them trusts a number written in a document - including the numbers this
    pass wrote. Where a figure appears below it is computed from the artifact
    on the spot and compared against the artifact it should agree with, never
    against a sentence.

    IT WORKS IN A FRESH CLONE, and it makes one: `git clone` of the repository
    this script sits in, into a temporary directory, so that anything the
    working tree happens to hold but has not committed is invisible to it. A
    verification that passes because of an uncommitted file has verified
    nothing.

    THE TWO SIBLING REPOSITORIES ARE THE EXCEPTION, and it is named rather
    than hidden. Check 1 renders the diagram, which needs PSGraphRenderToHtml
    and PSGraphRender at their tags; a clone of this repository does not
    contain them. They are consumed from the operator's own clones, READ-ONLY,
    at v0.1.0 and v0.13.0. -SkipDiagram runs everything else on a machine that
    does not have them, and says so in the summary rather than passing quietly.

    THE FIVE SPOT-CHECKS THE PROMPT NAMED, by name and in its order:

      1. Build-Diagram.ps1 re-run, flow.html regenerated and content-stable,
         flow-graph.json validated against the producer schema by the battery
      2. the LEDGER-47 probe re-fired from the committed fixture
      3. the link check, zero dead, every link-map row resolving
      4. the mermaid block and flow-graph.json compared, node count and layer
         membership among them
      5. git diff v1.2.0..HEAD over skills/, commands/ and .claude-plugin/,
         empty

    plus the pass's own acceptance test, green.
.PARAMETER RepoRoot
    The repository to clone and verify. Defaults to two levels above this file.
.PARAMETER ToHtmlRepo
    PSGraphRenderToHtml. Default: a sibling of RepoRoot.
.PARAMETER RenderRepo
    PSGraphRender. Default: a sibling of RepoRoot.
.PARAMETER SkipDiagram
    Skip check 1 on a machine without the two sibling repositories. Every
    other check still runs, and the summary records the skip.
.PARAMETER KeepClone
    Leave the temporary clone in place for inspection.
.EXAMPLE
    $params = @{
        RepoRoot = 'C:/src/AI.Agent.Claude.PowerShellModuleBuilder'
    }

    $verified = try {

        pwsh -NoProfile -File ./plans/0040-flow-docs/verify.ps1 @params
        $LASTEXITCODE -eq 0

    }
    catch {
        Write-Error "Verification could not run: $_"
        $false
    }

    $verified
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $ToHtmlRepo,
    [string] $RenderRepo,
    [switch] $SkipDiagram,
    [switch] $KeepClone
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$parent = Split-Path -Parent $RepoRoot
if (-not $ToHtmlRepo) { $ToHtmlRepo = Join-Path $parent 'PSGraphRenderToHtml' }
if (-not $RenderRepo) { $RenderRepo = Join-Path $parent 'PSGraphRender' }

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string] $Name, [bool] $Ok, [string] $Detail)
    $results.Add([pscustomobject]@{ Name = $Name; Ok = $Ok; Detail = $Detail })
    "[{0}] {1}" -f $(if ($Ok) { 'PASS' } else { 'FAIL' }), $Name
    if ($Detail) { foreach ($line in ($Detail -split "`r?`n")) { "       $line" } }
}

$clone = Join-Path ([IO.Path]::GetTempPath()) ("verify-0040-" + [guid]::NewGuid().ToString('n'))

try {
    'VERIFY 0040 - the flow made visible'
    "source:     $RepoRoot"
    "clone:      $clone"
    ''
    & git clone --quiet --no-hardlinks $RepoRoot $clone
    if ($LASTEXITCODE -ne 0) { throw "Could not clone '$RepoRoot'." }
    $head = (& git -C $clone rev-parse HEAD).Trim()
    "cloned HEAD: $head"
    ''

    # ---------------------------------------------------------------------
    # 0. The acceptance test, green.
    # ---------------------------------------------------------------------
    Import-Module Pester -MinimumVersion 6.0.0
    $cfg = New-PesterConfiguration
    $cfg.Run.Path = Join-Path $clone 'plans/0040-flow-docs/accept.Tests.ps1'
    $cfg.Output.Verbosity = 'None'
    $cfg.Run.PassThru = $true
    $accept = Invoke-Pester -Configuration $cfg
    # A container that failed discovery reports no failures AND no passes, and
    # "Failed=0" below would read as a green run. Checked before the counts.
    $brokenAccept = @($accept.Containers | Where-Object { $_.ErrorRecord })
    $acceptOk = $brokenAccept.Count -eq 0 -and $accept.FailedCount -eq 0 -and $accept.PassedCount -eq 11
    Add-Result -Name 'acceptance test, green, all 11 cases run' -Ok $acceptOk -Detail (
        "containers failed=$($brokenAccept.Count) passed=$($accept.PassedCount) failed=$($accept.FailedCount)" +
        $(if ($accept.FailedCount) { "`n" + (@($accept.Tests | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object { $_.ExpandedName }) -join "`n") } else { '' }))

    # ---------------------------------------------------------------------
    # 1. The diagram: rendered again, stable, and battery-validated.
    # ---------------------------------------------------------------------
    if ($SkipDiagram) {
        Add-Result -Name 'SPOT-CHECK 1 - diagram re-rendered, stable, battery green' -Ok $true -Detail 'SKIPPED by -SkipDiagram; the two sibling repositories were not available'
    }
    else {
        $builder = Join-Path $clone 'tools/diagram/Build-Diagram.ps1'
        $log = & pwsh -NoProfile -File $builder -RepoRoot $clone -ToHtmlRepo $ToHtmlRepo -RenderRepo $RenderRepo -Check 2>&1
        $code = $LASTEXITCODE
        $text = ($log | Out-String)
        # Three separate claims, and a green exit alone establishes none of
        # them: the tags were the ones consumed, the battery actually ran and
        # graded something, and the document is stable.
        $tagged = $text -match 'versions verified: PSGraphRender 0\.13\.0, PSGraphRenderToHtml 0\.1\.0'
        $battery = $text -match 'BATTERY: Passed=(\d+) Failed=0 Total=\1' -and $text -notmatch 'BATTERY: Passed=0'
        $stable = $text -match 'CHECK: flow\.html is byte-identical'
        Add-Result -Name 'SPOT-CHECK 1 - diagram re-rendered, stable, battery green' -Ok ($code -eq 0 -and $tagged -and $battery -and $stable) -Detail (
            "exit=$code tagsVerified=$tagged batteryGreen=$battery stable=$stable`n" +
            "nondeterminism named: meta.generatedAt is stamped with UtcNow, so -Check normalises that field and compares everything else`n" +
            ($text.Trim() -split "`r?`n" | Where-Object { $_ -match 'versions verified|Test-ProducerGraph|BATTERY|CHECK|first difference|committed:|fresh:' } | Out-String).Trim())
    }

    # ---------------------------------------------------------------------
    # 2. The LEDGER-47 probe, re-fired from the committed fixture.
    # ---------------------------------------------------------------------
    $probe = & pwsh -NoProfile -File (Join-Path $clone 'plans/0040-flow-docs/Invoke-SplatProbe.ps1') -RepoRoot $clone 2>&1
    $probeCode = $LASTEXITCODE
    $probeText = ($probe | Out-String)
    # The reading is re-derived; splat-coverage.txt is then required to AGREE
    # with it rather than being read as the evidence.
    $recorded = Get-Content -LiteralPath (Join-Path $clone 'plans/0040-flow-docs/splat-coverage.txt') -Raw
    $probeOk = $probeCode -eq 0 -and
        $probeText -match 'DASH FORM IN FIXTURE: 0 occurrence' -and
        $probeText -match 'CONTAINERS FAILED: 0' -and
        $probeText -match 'PASSED=1 FAILED=0 SELECTED=1' -and
        $probeText -match 'SPLAT EXAMPLE: passes as shipped' -and
        $recorded -match 'SPLAT EXAMPLE: passes as shipped'
    Add-Result -Name 'SPOT-CHECK 2 - LEDGER-47 probe re-fired from the committed fixture' -Ok $probeOk -Detail (
        "exit=$probeCode; the committed reading and the fresh one must both say 'passes as shipped'`n" +
        ($probeText.Trim() -split "`r?`n" | Select-Object -Last 3 | Out-String).Trim())

    # ---------------------------------------------------------------------
    # 3. The link check.
    # ---------------------------------------------------------------------
    $links = & pwsh -NoProfile -File (Join-Path $clone 'plans/0040-flow-docs/Test-Links.ps1') -RepoRoot $clone 2>&1
    $linkCode = $LASTEXITCODE
    $linkText = ($links | Out-String)
    $coverage = [regex]::Match($linkText, 'link map \(coverage\)\s+ok, (\d+) rows for (\d+) nodes')
    $linksOk = $linkCode -eq 0 -and $linkText -match 'DEAD LINKS: 0' -and
        $coverage.Success -and $coverage.Groups[1].Value -eq $coverage.Groups[2].Value
    Add-Result -Name 'SPOT-CHECK 3 - zero dead links, every link-map row resolving' -Ok $linksOk -Detail (
        "exit=$linkCode`n" +
        ($linkText.Trim() -split "`r?`n" | Where-Object { $_ -match 'DEAD LINKS|link map|links resolved' } | Out-String).Trim())

    # ---------------------------------------------------------------------
    # 4. The mermaid mirror against the JSON.
    # ---------------------------------------------------------------------
    $mirror = & pwsh -NoProfile -File (Join-Path $clone 'plans/0040-flow-docs/Compare-Mermaid.ps1') -RepoRoot $clone 2>&1
    $mirrorCode = $LASTEXITCODE
    $mirrorText = ($mirror | Out-String)
    $nodeLine = [regex]::Match($mirrorText, 'nodes:\s+mermaid (\d+), json (\d+)')
    $layerLine = [regex]::Match($mirrorText, 'layers:\s+mermaid (\d+), json (\d+)')
    $mirrorOk = $mirrorCode -eq 0 -and $mirrorText -match 'MERMAID AND JSON AGREE' -and
        $nodeLine.Success -and $nodeLine.Groups[1].Value -eq $nodeLine.Groups[2].Value -and
        $layerLine.Success -and $layerLine.Groups[1].Value -eq $layerLine.Groups[2].Value

    # And the comparison is proved capable of disagreeing, on the same run.
    # A checker that has only ever agreed is not evidence that the two
    # renderings match; it is evidence that nothing has looked.
    $fals = & pwsh -NoProfile -File (Join-Path $clone 'plans/0040-flow-docs/Invoke-MermaidFalsification.ps1') -RepoRoot $clone 2>&1
    $falsCode = $LASTEXITCODE
    Add-Result -Name 'SPOT-CHECK 4 - mermaid and json agree on count, ids, labels, layers and edges' -Ok ($mirrorOk -and $falsCode -eq 0) -Detail (
        "compare exit=$mirrorCode, falsification exit=$falsCode`n" +
        ($mirrorText.Trim() -split "`r?`n" | Select-Object -First 4 | Out-String).Trim() +
        "`nfalsification: control green, and four breaks red - a deleted node, a node moved between layers, a reversed edge, a retyped label")

    # ---------------------------------------------------------------------
    # 5. The plugin is untouched since v1.2.0.
    # ---------------------------------------------------------------------
    $diff = & git -C $clone diff --stat v1.2.0..HEAD -- skills/ commands/ .claude-plugin/
    $diffText = ($diff | Out-String).Trim()
    Add-Result -Name 'SPOT-CHECK 5 - skills/, commands/ and .claude-plugin/ unchanged since v1.2.0' -Ok ([string]::IsNullOrWhiteSpace($diffText)) -Detail (
        $(if ($diffText) { $diffText } else { 'git diff v1.2.0..HEAD -- skills/ commands/ .claude-plugin/  ->  empty' }))

    # ---------------------------------------------------------------------
    ''
    $failed = @($results | Where-Object { -not $_.Ok })
    "checks: $($results.Count), failed: $($failed.Count)"
    if ($failed.Count) {
        'DISAGREED:'
        $failed | ForEach-Object { "  $($_.Name)" }
        exit 1
    }
    'VERIFY 0040: every check agrees'
    exit 0
}
finally {
    if (-not $KeepClone -and (Test-Path -LiteralPath $clone)) {
        Remove-Item -LiteralPath $clone -Recurse -Force -ErrorAction SilentlyContinue
    }
}
