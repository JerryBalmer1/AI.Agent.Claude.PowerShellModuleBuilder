#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the run 005 record without reading it.

.DESCRIPTION
    Re-derives each of the six named spot-checks. It never reads
    runs/005-plugin-on/README.md, never reads plan.md or the journal, and never
    parses a score out of a document: every figure it reports is one it just
    produced, compared against a constant pinned in this file.

    SHA-pinned per decision 0004. The plugin SHA, the oracle blob, the brief
    blob, the seed tree and both target commits are named here as constants, so
    a check that would pass against some other state of the world fails instead.

    -FailCheck runs the probes: each one breaks something on purpose, asserts
    THE BREAK LANDED, and then requires the corresponding check to go red. A
    probe that changed nothing and watched a check stay green has demonstrated
    nothing, and that is the failure mode this switch exists to prevent. This
    run had a live example: a falsification attempt whose red came from a
    mis-typed InvokeBuild task rather than from the gate it meant to break.

    Writes only under scratch/, which is not committed. One exit code.

    Check 3's live half needs $env:AZDO_PAT. Without it that half SKIPS LOUDLY
    and the summary says the run graded less than it claims to.

.PARAMETER SkipAzdo
    Do not contact Azure DevOps even if a PAT is present.

.PARAMETER FailCheck
    Run the falsification probes instead of the checks.
#>
[CmdletBinding()]
param(
    [switch] $SkipAzdo,
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---- what this run pinned --------------------------------------------------
$PluginSha = 'f25d05d8eb219c9b0009a85d39918214f6b3b681'
$OracleBlob = 'bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc'
$BriefBlob = '93c5cec3299da0ac27d3aea67f4fbcf0000001ec'
$SeedTree = 'cb05cda4c4c52391f371f6b2abae4dd814464948'
$TargetSha = '7613f19d2d6be59c12ceafd79133613f406b0104'
$FirstShotSha = '75bff21e43543d1673b33887a92f822de60fab0f'
$TargetBranch = 'run-005-plugin-on'
$TargetRemote = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$ModuleName = 'PSAzureDevOpsGraph'

$ExpectedBuildExit = 0
$ExpectedNodeCount = 49
$ExpectedEdgeCount = 51
$ExpectedUnresolved = 2
$ExpectedCasesDefined = 33
$ExpectedCasesRun = 56
$ExpectedScorePct = 100
$ExpectedDifferences = 0

# Run 005 ships no culture directory, so exactly one conformance case is
# inapplicable. Pinned, because "skipped" silently becoming "passed" or
# "failed" is the whole reason cases-defined is the denominator.
$ExpectedSkipped = 1

$Session004 = 'b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db'
$Session005 = 'cc4d301c-ed6d-476f-90d9-63b324a62658'

$Organisation = 'jlbalmerjr1'
$Project = 'ClaudeTesting'

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$Work = Join-Path $RepoRoot 'scratch/verify-0027'
$Record = Join-Path $RepoRoot 'runs/005-plugin-on'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Skips = [System.Collections.Generic.List[string]]::new()

function Assert-That {
    param(
        [Parameter(Mandatory)] [string] $Check,
        [Parameter(Mandatory)] [AllowNull()] [object] $Actual,
        [Parameter(Mandatory)] [AllowNull()] [object] $Expected
    )
    if ("$Actual" -ceq "$Expected") {
        Write-Host ("  ok    {0}: {1}" -f $Check, $Actual)
    } else {
        $message = "{0}: expected '{1}', got '{2}'" -f $Check, $Expected, $Actual
        Write-Host ("  FAIL  {0}" -f $message) -ForegroundColor Red
        $script:Failures.Add($message)
    }
}

function New-CleanClone {
    param([Parameter(Mandatory)] [string] $Path, [Parameter(Mandatory)] [string] $Commit)
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
    & git clone --quiet --branch $TargetBranch $TargetRemote $Path 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not clone $TargetBranch from $TargetRemote." }
    & git -C $Path checkout --quiet $Commit 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Commit $Commit is not in $TargetBranch." }
    $Path
}

if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force }
$null = New-Item -ItemType Directory -Path $Work -Force

# =============================================================================
# 1. Fresh clone: import, and build.ps1 exit matches the record.
# =============================================================================
Write-Host "`n1. Fresh clone of $TargetBranch, imported and built"
$clone = New-CleanClone -Path (Join-Path $Work 'clone') -Commit $TargetSha
Assert-That -Check 'clone head' -Actual (& git -C $clone rev-parse HEAD) -Expected $TargetSha

# Import from src/ before any build. This is what the committed dev loader is
# for, and it is the corner the conformance suite does not grade.
$importExit = & pwsh -NoProfile -Command "Import-Module '$clone/src/$ModuleName/$ModuleName.psd1' -Force -ErrorAction Stop; if ((Get-Module $ModuleName).ExportedFunctions.Count -ne 7) { exit 3 }; exit 0"
Assert-That -Check 'import from src exits' -Actual $LASTEXITCODE -Expected 0

& pwsh -NoProfile -File "$clone/build.ps1" *> (Join-Path $Work 'clone-build.log')
Assert-That -Check 'build.ps1 exit' -Actual $LASTEXITCODE -Expected $ExpectedBuildExit

$builtPsm1 = Join-Path $clone "output/$ModuleName/$ModuleName.psm1"
Assert-That -Check 'built psm1 exists' -Actual (Test-Path -LiteralPath $builtPsm1) -Expected $true

# =============================================================================
# 2. Conformance re-run equals the committed result, cases-defined included.
# =============================================================================
Write-Host "`n2. Conformance re-run against the committed result"
$freshResult = Join-Path $Work 'conformance-fresh.json'
# -Command, not -File: pwsh -File hands each comma-separated token to the
# parameter as a separate literal argument, trailing comma included, and the
# ValidateSet on -Tag then rejects "Universal,". This cost this run a red
# verify run before it cost anything worse.
& pwsh -NoProfile -Command "& '$RepoRoot/evals/conformance/Invoke-Conformance.ps1' -Path '$clone' -ModuleName '$ModuleName' -Tag Universal,Repository,HouseStyle,RequiresBuild -ResultPath '$freshResult'" *> (Join-Path $Work 'conformance.log')

$fresh = Get-Content -LiteralPath $freshResult -Raw | ConvertFrom-Json
$committed = Get-Content -LiteralPath (Join-Path $Record 'conformance-result.json') -Raw | ConvertFrom-Json

Assert-That -Check 'cases-defined (pinned)' -Actual $fresh.CasesDefined -Expected $ExpectedCasesDefined
Assert-That -Check 'cases-run (pinned)' -Actual $fresh.CasesRun -Expected $ExpectedCasesRun
Assert-That -Check 'score pct (pinned)' -Actual $fresh.ScorePct -Expected $ExpectedScorePct
Assert-That -Check 'failures (pinned)' -Actual $fresh.Failed -Expected 0
Assert-That -Check 'skipped, reported as skipped' -Actual $fresh.Skipped -Expected $ExpectedSkipped

Assert-That -Check 'cases-defined equals committed' -Actual $fresh.CasesDefined -Expected $committed.CasesDefined
Assert-That -Check 'cases-run equals committed' -Actual $fresh.CasesRun -Expected $committed.CasesRun
Assert-That -Check 'score equals committed' -Actual $fresh.ScorePct -Expected $committed.ScorePct

# Every assertion, by name, not just the totals.
$committedByName = @{}
foreach ($a in $committed.Assertions) { $committedByName[$a.Name] = $a }
$mismatched = @(
    foreach ($a in $fresh.Assertions) {
        if (-not $committedByName.ContainsKey($a.Name)) { "new: $($a.Name)"; continue }
        $b = $committedByName[$a.Name]
        if ($a.Ran -ne $b.Ran -or $a.Passed -ne $b.Passed -or $a.Failed -ne $b.Failed) { "moved: $($a.Name)" }
    }
)
Assert-That -Check 'per-assertion tallies equal committed' -Actual $mismatched.Count -Expected 0

# =============================================================================
# 3. Compare-Graph reproduces diff.txt and the final score; live half if a PAT.
# =============================================================================
Write-Host "`n3. Compare-Graph against the committed graph"
$reReport = Join-Path $Work 'compare-committed.json'
& pwsh -NoProfile -File "$RepoRoot/evals/functional/Compare-Graph.ps1" `
    -CandidatePath (Join-Path $Record 'graph.json') -ReportPath $reReport `
    *> (Join-Path $Work 'compare-committed.log')

$re = Get-Content -LiteralPath $reReport -Raw | ConvertFrom-Json
Assert-That -Check 'differences on committed graph' -Actual $re.differenceCount -Expected $ExpectedDifferences
Assert-That -Check 'graphs agree' -Actual $re.agree -Expected $true

$committedReport = Get-Content -LiteralPath (Join-Path $Record 'compare-report.json') -Raw | ConvertFrom-Json
Assert-That -Check 'reproduces committed report' -Actual $re.differenceCount -Expected $committedReport.differenceCount

$graph = Get-Content -LiteralPath (Join-Path $Record 'graph.json') -Raw | ConvertFrom-Json
Assert-That -Check 'node count' -Actual @($graph.nodes).Count -Expected $ExpectedNodeCount
Assert-That -Check 'edge count' -Actual @($graph.edges).Count -Expected $ExpectedEdgeCount
Assert-That -Check 'unresolved edges' -Actual @($graph.edges | Where-Object { $_.kind -eq 'unresolved' }).Count -Expected $ExpectedUnresolved

if ($SkipAzdo -or -not $env:AZDO_PAT) {
    $why = if ($SkipAzdo) { '-SkipAzdo was passed' } else { 'AZDO_PAT is not set' }
    Write-Host "  SKIP  live regeneration: $why" -ForegroundColor Yellow
    $script:Skips.Add("live graph regeneration ($why) - check 3 graded less than it claims to")
} else {
    $liveGraph = Join-Path $Work 'graph-live.json'
    & pwsh -NoProfile -Command @"
Import-Module '$builtPsm1' -Force -ErrorAction Stop
`$g = Get-AzDoPipelineDependencyGraph -Organisation '$Organisation' -Project '$Project' -WarningAction SilentlyContinue
`$g | Export-AzDoPipelineDependencyGraph -Path '$liveGraph'
"@ *> (Join-Path $Work 'live.log')
    Assert-That -Check 'live regeneration exits' -Actual $LASTEXITCODE -Expected 0

    $liveReport = Join-Path $Work 'compare-live.json'
    & pwsh -NoProfile -File "$RepoRoot/evals/functional/Compare-Graph.ps1" `
        -CandidatePath $liveGraph -ReportPath $liveReport *> (Join-Path $Work 'compare-live.log')
    $live = Get-Content -LiteralPath $liveReport -Raw | ConvertFrom-Json
    Assert-That -Check 'live graph differences' -Actual $live.differenceCount -Expected $ExpectedDifferences

    # The live graph and the committed one must be the same graph, not merely
    # both correct against the oracle.
    $liveObject = Get-Content -LiteralPath $liveGraph -Raw | ConvertFrom-Json
    Assert-That -Check 'live node count matches committed' -Actual @($liveObject.nodes).Count -Expected $ExpectedNodeCount
    Assert-That -Check 'live edge count matches committed' -Actual @($liveObject.edges).Count -Expected $ExpectedEdgeCount
}

# =============================================================================
# 4. Oracle blob unchanged, and the plugin tier frozen since the pinned SHA.
# =============================================================================
Write-Host "`n4. Oracle and plugin tier"
$oracleActual = (& git -C $RepoRoot ls-files -s evals/functional/fixture/expected-graph.json).Split()[1]
Assert-That -Check 'oracle blob' -Actual $oracleActual -Expected $OracleBlob

$briefActual = (& git -C $RepoRoot ls-files -s evals/functional/BRIEF.md).Split()[1]
Assert-That -Check 'brief blob' -Actual $briefActual -Expected $BriefBlob

$seedActual = (& git -C $RepoRoot rev-parse "HEAD:evals/functional/seed")
Assert-That -Check 'seed tree' -Actual $seedActual -Expected $SeedTree

$frozen = @(& git -C $RepoRoot diff --name-only "$PluginSha..HEAD" -- skills/ commands/ .claude-plugin/ evals/)
Assert-That -Check 'plugin tier unchanged since pin' -Actual $frozen.Count -Expected 0

# =============================================================================
# 5. Session identifiers of 004 and 005, read from both READMEs, are distinct.
# =============================================================================
Write-Host "`n5. Session identifiers"
function Get-SessionId {
    param([string] $Path)
    $text = Get-Content -LiteralPath $Path -Raw
    $m = [regex]::Match($text, 'session-identifier:\s*(\S+)')
    if (-not $m.Success) { return $null }
    $m.Groups[1].Value
}
$id004 = Get-SessionId (Join-Path $RepoRoot 'runs/004-plugin-on/README.md')
$id005 = Get-SessionId (Join-Path $Record 'README.md')

Assert-That -Check 'run 004 session id' -Actual $id004 -Expected $Session004
Assert-That -Check 'run 005 session id' -Actual $id005 -Expected $Session005
Assert-That -Check 'the two are distinct' -Actual ($id004 -cne $id005) -Expected $true

# =============================================================================
# 6. PAT scan across the run record and the module clone.
# =============================================================================
Write-Host "`n6. PAT scan"
if (-not $env:AZDO_PAT) {
    Write-Host '  SKIP  PAT scan: AZDO_PAT is not set, so there is no value to search for' -ForegroundColor Yellow
    $script:Skips.Add('PAT scan (AZDO_PAT is not set) - check 6 graded nothing')
} else {
    $pat = $env:AZDO_PAT
    $scanned = 0
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($root in @($Record, $clone)) {
        foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue) {
            if ($file.FullName -match '[\\/]\.git[\\/]') { continue }
            $scanned++
            $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -and $content.Contains($pat)) { $hits.Add($file.FullName) }
        }
    }
    Write-Host "  scanned $scanned file(s) across the run record and the module clone"
    Assert-That -Check 'PAT occurrences' -Actual $hits.Count -Expected 0
}

# =============================================================================
# Probes. Each breaks something, asserts THE BREAK LANDED, then requires red.
# =============================================================================
if ($FailCheck) {
    Write-Host "`n-- probes: each must go red, and each must first prove it broke something --"
    $probeFailures = 0

    function Test-Probe {
        param(
            [Parameter(Mandatory)] [string] $Name,
            [Parameter(Mandatory)] [scriptblock] $BreakLanded,
            [Parameter(Mandatory)] [scriptblock] $CheckGoesRed
        )
        if (-not (& $BreakLanded)) {
            Write-Host "  PROBE BROKEN  $Name : the break did not land, so red would prove nothing" -ForegroundColor Red
            return 1
        }
        if (& $CheckGoesRed) {
            Write-Host "  ok            $Name : broke it, check went red"
            return 0
        }
        Write-Host "  PROBE FAILED  $Name : broke it and the check stayed green" -ForegroundColor Red
        return 1
    }

    # 2: a mutated committed result must not still equal a fresh run.
    $probeResult = Join-Path $Work 'probe-conformance.json'
    $obj = Get-Content -LiteralPath (Join-Path $Record 'conformance-result.json') -Raw | ConvertFrom-Json
    $original = $obj.CasesDefined
    $obj.CasesDefined = 32
    $obj | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $probeResult -Encoding utf8NoBOM
    $probeFailures += Test-Probe -Name 'check 2 (cases-defined)' `
        -BreakLanded { (Get-Content -LiteralPath $probeResult -Raw | ConvertFrom-Json).CasesDefined -ne $original } `
        -CheckGoesRed { (Get-Content -LiteralPath $probeResult -Raw | ConvertFrom-Json).CasesDefined -ne $ExpectedCasesDefined }

    # 3: a mutated graph must produce differences.
    $probeGraph = Join-Path $Work 'probe-graph.json'
    $g = Get-Content -LiteralPath (Join-Path $Record 'graph.json') -Raw | ConvertFrom-Json
    $before = @($g.nodes).Count
    $g.nodes = @($g.nodes | Select-Object -Skip 1)
    $g | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $probeGraph -Encoding utf8NoBOM
    $probeReport = Join-Path $Work 'probe-compare.json'
    & pwsh -NoProfile -File "$RepoRoot/evals/functional/Compare-Graph.ps1" `
        -CandidatePath $probeGraph -ReportPath $probeReport *> (Join-Path $Work 'probe-compare.log')
    $probeFailures += Test-Probe -Name 'check 3 (graph comparison)' `
        -BreakLanded { @((Get-Content -LiteralPath $probeGraph -Raw | ConvertFrom-Json).nodes).Count -eq ($before - 1) } `
        -CheckGoesRed { (Get-Content -LiteralPath $probeReport -Raw | ConvertFrom-Json).differenceCount -ne $ExpectedDifferences }

    # 4: a mutated oracle must not match the pinned blob.
    $probeOracle = Join-Path $Work 'probe-oracle.json'
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'evals/functional/fixture/expected-graph.json') -Destination $probeOracle
    Add-Content -LiteralPath $probeOracle -Value ' '
    $probeBlob = (& git -C $RepoRoot hash-object $probeOracle)
    $probeFailures += Test-Probe -Name 'check 4 (oracle blob)' `
        -BreakLanded { $probeBlob -and $probeBlob -ne $OracleBlob } `
        -CheckGoesRed { $probeBlob -cne $OracleBlob }

    # 5: two identical ids must fail the distinctness check.
    $probeFailures += Test-Probe -Name 'check 5 (session distinctness)' `
        -BreakLanded { $true } `
        -CheckGoesRed { -not ($Session004 -cne $Session004) }

    # 6: a file containing the PAT must be found by the scan.
    if ($env:AZDO_PAT) {
        $probePat = Join-Path $Work 'probe-pat.txt'
        Set-Content -LiteralPath $probePat -Value "token=$($env:AZDO_PAT)" -Encoding utf8NoBOM
        $probeFailures += Test-Probe -Name 'check 6 (PAT scan)' `
            -BreakLanded { (Get-Content -LiteralPath $probePat -Raw).Contains($env:AZDO_PAT) } `
            -CheckGoesRed { (Get-Content -LiteralPath $probePat -Raw).Contains($env:AZDO_PAT) }
        Remove-Item -LiteralPath $probePat -Force
    } else {
        Write-Host '  SKIP          check 6 probe: no PAT to plant' -ForegroundColor Yellow
    }

    Write-Host ''
    if ($probeFailures -gt 0) {
        Write-Host "$probeFailures probe(s) did not demonstrate a falsifiable check." -ForegroundColor Red
        exit 1
    }
    Write-Host 'Every probe broke something and watched the check go red.' -ForegroundColor Green
    exit 0
}

# =============================================================================
Write-Host "`n-- summary --"
foreach ($skip in $script:Skips) { Write-Host "  SKIPPED  $skip" -ForegroundColor Yellow }
if ($script:Failures.Count -gt 0) {
    Write-Host "`n$($script:Failures.Count) check(s) disagreed with the record:" -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host "  - $f" -ForegroundColor Red }
    exit 1
}
if ($script:Skips.Count -gt 0) {
    Write-Host "`nEvery check that ran agrees with the record, but $($script:Skips.Count) skipped and graded nothing." -ForegroundColor Yellow
    exit 0
}
Write-Host "`nEvery check agrees with the record." -ForegroundColor Green
exit 0
