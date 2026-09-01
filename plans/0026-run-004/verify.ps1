#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the run 004 record without reading it.

.DESCRIPTION
    Re-derives each of the five named spot-checks. It never reads
    runs/004-plugin-on/README.md, never reads plan.md or the journal, and never
    parses a score out of a document: every figure it reports is one it just
    produced, compared against a constant pinned in this file.

    SHA-pinned per decision 0004. The plugin SHA, the oracle blob, the brief
    blob, the seed tree and the target commit are named here as constants, so a
    check that would pass against some other state of the world fails instead.

    -FailCheck runs the probes: each one breaks something on purpose, asserts
    THE BREAK LANDED, and then requires the corresponding check to go red. A
    probe that changed nothing and watched a check stay green has demonstrated
    nothing, and that is the failure mode this switch exists to prevent.

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
$PluginSha            = 'f25d05d8eb219c9b0009a85d39918214f6b3b681'
$OracleBlob           = 'bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc'
$BriefBlob            = '93c5cec3299da0ac27d3aea67f4fbcf0000001ec'
$SeedTree             = 'cb05cda4c4c52391f371f6b2abae4dd814464948'
$TargetSha            = '19837f9efa0d5196194aa737a069cb38493dc3ec'
$TargetBranch         = 'run-004-plugin-on'
$TargetRemote         = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$ModuleName           = 'PSAzureDevOpsGraph'

$ExpectedBuildExit    = 0
$ExpectedNodeCount    = 49
$ExpectedEdgeCount    = 51
$ExpectedUnresolved   = 2
$ExpectedCasesDefined = 33
$ExpectedCasesRun     = 57
$ExpectedScorePct     = 100
$ExpectedDifferences  = 0

$Organisation         = 'jlbalmerjr1'
$Project              = 'ClaudeTesting'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Skipped  = [System.Collections.Generic.List[string]]::new()
$script:Checks   = 0

function Confirm-Check {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [bool]   $Ok,
        [string] $Detail = ''
    )
    $script:Checks++
    if ($Ok) { Write-Host ("PASS  {0}" -f $Name) }
    else {
        Write-Host ("FAIL  {0}" -f $Name)
        $script:Failures.Add($Name)
    }
    if ($Detail) { Write-Host ("        {0}" -f $Detail) }
}

function Skip-Check {
    param([Parameter(Mandatory)] [string] $Name, [Parameter(Mandatory)] [string] $Why)
    Write-Host ("SKIP  {0}" -f $Name)
    Write-Host ("        {0}" -f $Why)
    $script:Skipped.Add($Name)
}

$RepoRoot    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$RunDir      = Join-Path $RepoRoot 'runs/004-plugin-on'
$ScratchRoot = Join-Path $RepoRoot 'scratch/verify-0026'

# A unique directory per invocation. A pwsh that has just exited can hold a
# handle on the tree it built in for longer than it is worth waiting for, and a
# verify that fails because Windows had not let go yet reports nothing about the
# thing it was asked to check. Old runs are pruned best-effort and never fatally.
$Scratch = Join-Path $ScratchRoot (Get-Date -Format 'yyyyMMdd-HHmmss')
$Clone   = Join-Path $Scratch 'clone'
$null = New-Item -ItemType Directory -Path $Scratch -Force

foreach ($old in Get-ChildItem -LiteralPath $ScratchRoot -Directory -ErrorAction SilentlyContinue) {
    if ($old.FullName -eq $Scratch) { continue }
    try { Remove-Item -LiteralPath $old.FullName -Recurse -Force -ErrorAction Stop } catch { }
}

Write-Host ''
Write-Host 'Verify — pass 0026, run 004'
Write-Host ("  repo    : {0}" -f $RepoRoot)
Write-Host ("  scratch : {0}" -f $Scratch)
Write-Host ''

# ---------------------------------------------------------------------------
# A fresh clone at the pinned commit. Everything downstream uses THIS, not the
# working tree, so a check cannot pass against uncommitted state.
# ---------------------------------------------------------------------------
git clone --quiet --branch $TargetBranch $TargetRemote $Clone 2>&1 | Out-Null
$clonedSha = (git -C $Clone rev-parse HEAD).Trim()
Confirm-Check -Name 'clone/0  fresh clone is at the pinned target commit' `
    -Ok ($clonedSha -eq $TargetSha) `
    -Detail ("cloned {0}, pinned {1}" -f $clonedSha, $TargetSha)

# ---------------------------------------------------------------------------
# 1. Import, and build.ps1 exit matches the record.
# ---------------------------------------------------------------------------
$buildOut = Join-Path $Scratch 'build.txt'
$build = Start-Process pwsh -PassThru -Wait -NoNewWindow `
    -ArgumentList @('-NoProfile', '-File', (Join-Path $Clone 'build.ps1')) `
    -WorkingDirectory $Clone -RedirectStandardOutput $buildOut -RedirectStandardError (Join-Path $Scratch 'build.err.txt')
Confirm-Check -Name '1a  build.ps1 in a fresh clone exits as recorded' `
    -Ok ($build.ExitCode -eq $ExpectedBuildExit) `
    -Detail ("exit {0}, pinned {1}" -f $build.ExitCode, $ExpectedBuildExit)

$manifest = Join-Path $Clone "output/$ModuleName/$ModuleName.psd1"
$imported = $null
if (Test-Path -LiteralPath $manifest) {
    Import-Module -Name $manifest -Force -ErrorAction Stop
    $imported = Get-Module $ModuleName
}
Confirm-Check -Name '1b  the built module imports and exports seven commands' `
    -Ok ($null -ne $imported -and $imported.ExportedFunctions.Count -eq 7) `
    -Detail ("exported {0}" -f $(if ($imported) { $imported.ExportedFunctions.Count } else { 'nothing' }))

# ---------------------------------------------------------------------------
# 2. Conformance re-run equals the committed result, cases-defined included.
# ---------------------------------------------------------------------------
$freshResultPath = Join-Path $Scratch 'conformance-result.json'
$conformanceOut = Join-Path $Scratch 'conformance.txt'
# -Command, not -File. Under -File every argument is a literal string, so a
# [string[]] parameter binds only the next token: 'a,b,c,d' arrives as one value
# the ValidateSet rejects against a set whose text it exactly matches, and four
# separate tokens make the last three positional. -Command lets PowerShell parse
# the array the way the call site reads.
$conformanceScript = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'
$conformanceCommand = "& '$conformanceScript' -Path '$Clone' -ModuleName '$ModuleName' " +
    "-Tag Universal,Repository,HouseStyle,RequiresBuild -ResultPath '$freshResultPath'"
$null = Start-Process pwsh -PassThru -Wait -NoNewWindow `
    -ArgumentList @('-NoProfile', '-Command', $conformanceCommand) `
    -WorkingDirectory $RepoRoot -RedirectStandardOutput $conformanceOut -RedirectStandardError (Join-Path $Scratch 'conformance.err.txt')

$fresh = Get-Content -LiteralPath $freshResultPath -Raw | ConvertFrom-Json
Confirm-Check -Name '2a  conformance cases-defined is the stable denominator' `
    -Ok ([int] $fresh.CasesDefined -eq $ExpectedCasesDefined) `
    -Detail ("cases-defined {0}, pinned {1}" -f $fresh.CasesDefined, $ExpectedCasesDefined)
Confirm-Check -Name '2b  conformance cases-run and score match the pinned values' `
    -Ok ([int] $fresh.CasesRun -eq $ExpectedCasesRun -and [int] $fresh.ScorePct -eq $ExpectedScorePct -and [int] $fresh.Failed -eq 0) `
    -Detail ("cases-run {0}, score {1}%, failed {2}" -f $fresh.CasesRun, $fresh.ScorePct, $fresh.Failed)

$committedResult = Join-Path $RunDir 'conformance-result.json'
$committed = Get-Content -LiteralPath $committedResult -Raw | ConvertFrom-Json
$sameAsCommitted = ([int] $committed.CasesDefined -eq [int] $fresh.CasesDefined) -and
                   ([int] $committed.CasesRun -eq [int] $fresh.CasesRun) -and
                   ([int] $committed.Passed -eq [int] $fresh.Passed) -and
                   ([int] $committed.Failed -eq [int] $fresh.Failed)
Confirm-Check -Name '2c  the re-run equals the committed result.json' `
    -Ok $sameAsCommitted `
    -Detail ("committed {0}/{1} defined={2}; re-run {3}/{4} defined={5}" -f
        $committed.Passed, $committed.Total, $committed.CasesDefined,
        $fresh.Passed, $fresh.Total, $fresh.CasesDefined)

# ---------------------------------------------------------------------------
# 3. Compare-Graph on the committed graph reproduces diff.txt and the score;
#    with a PAT, regenerate live and compare.
# ---------------------------------------------------------------------------
$committedGraph = Join-Path $RunDir 'graph.json'
$reportPath = Join-Path $Scratch 'compare-report.json'
$compareOut = Join-Path $Scratch 'compare.txt'
$compare = Start-Process pwsh -PassThru -Wait -NoNewWindow -ArgumentList @(
    '-NoProfile', '-File', (Join-Path $RepoRoot 'evals/functional/Compare-Graph.ps1'),
    '-CandidatePath', $committedGraph, '-ReportPath', $reportPath) `
    -WorkingDirectory $RepoRoot -RedirectStandardOutput $compareOut -RedirectStandardError (Join-Path $Scratch 'compare.err.txt')

$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
Confirm-Check -Name '3a  Compare-Graph on the committed graph reports the pinned difference count' `
    -Ok ([int] $report.differenceCount -eq $ExpectedDifferences -and $compare.ExitCode -eq 0) `
    -Detail ("differences {0}, exit {1}" -f $report.differenceCount, $compare.ExitCode)

# diff.txt is reproduced, not parsed for a number: the freshly produced text and
# the committed text must carry the same verdict line.
$committedDiff = (Get-Content -LiteralPath (Join-Path $RunDir 'diff.txt') -Raw)
$freshDiff = (Get-Content -LiteralPath $compareOut -Raw)
$verdict = 'The graphs agree. 0 differences.'
Confirm-Check -Name '3b  the committed diff.txt carries the verdict this run just reproduced' `
    -Ok ($committedDiff -match [regex]::Escape($verdict) -and $freshDiff -match [regex]::Escape($verdict)) `
    -Detail 'both texts state the same verdict'

$graph = Get-Content -LiteralPath $committedGraph -Raw | ConvertFrom-Json
$unresolvedCount = @($graph.edges | Where-Object { $_.kind -eq 'unresolved' }).Count
Confirm-Check -Name '3c  the committed graph has the pinned shape' `
    -Ok (@($graph.nodes).Count -eq $ExpectedNodeCount -and
         @($graph.edges).Count -eq $ExpectedEdgeCount -and
         $unresolvedCount -eq $ExpectedUnresolved) `
    -Detail ("{0} nodes, {1} edges, {2} unresolved" -f @($graph.nodes).Count, @($graph.edges).Count, $unresolvedCount)

if ($SkipAzdo) {
    Skip-Check -Name '3d  live regeneration' -Why '-SkipAzdo was given. Nothing contacted Azure DevOps, so this run did not check that the graph is still reproducible from the fixture.'
} elseif ([string]::IsNullOrWhiteSpace($env:AZDO_PAT)) {
    Skip-Check -Name '3d  live regeneration' -Why 'AZDO_PAT is not set. The committed graph was compared to the oracle but NOT regenerated, so this run cannot say the module still produces it.'
} elseif ($null -eq $imported) {
    Skip-Check -Name '3d  live regeneration' -Why 'The clone did not build, so there is no module to regenerate with.'
} else {
    $live = Get-AzDoPipelineDependencyGraph -Organisation $Organisation -Project $Project
    $livePath = Join-Path $Scratch 'live-graph.json'
    Export-AzDoPipelineDependencyGraph -Graph $live -Format Json -Path $livePath
    $liveReport = Join-Path $Scratch 'live-compare-report.json'
    $liveCompare = Start-Process pwsh -PassThru -Wait -NoNewWindow -ArgumentList @(
        '-NoProfile', '-File', (Join-Path $RepoRoot 'evals/functional/Compare-Graph.ps1'),
        '-CandidatePath', $livePath, '-ReportPath', $liveReport, '-Quiet') `
        -WorkingDirectory $RepoRoot -RedirectStandardOutput (Join-Path $Scratch 'live-compare.txt') -RedirectStandardError (Join-Path $Scratch 'live-compare.err.txt')
    $liveResult = Get-Content -LiteralPath $liveReport -Raw | ConvertFrom-Json
    Confirm-Check -Name '3d  a graph regenerated live still agrees with the oracle' `
        -Ok ([int] $liveResult.differenceCount -eq $ExpectedDifferences -and $liveCompare.ExitCode -eq 0) `
        -Detail ("differences {0}, exit {1}" -f $liveResult.differenceCount, $liveCompare.ExitCode)

    $liveNormalised = (Get-Content -LiteralPath $livePath -Raw) -replace "`r`n", "`n"
    $committedNormalised = (Get-Content -LiteralPath $committedGraph -Raw) -replace "`r`n", "`n"
    Confirm-Check -Name '3e  the live graph is byte-identical to the committed one' `
        -Ok ($liveNormalised.Trim() -eq $committedNormalised.Trim()) `
        -Detail 'determinism: the export is sorted, so two runs produce the same bytes'
}

# ---------------------------------------------------------------------------
# 4. The oracle and the instrument did not move.
# ---------------------------------------------------------------------------
$oracleNow = (git -C $RepoRoot rev-parse 'HEAD:evals/functional/fixture/expected-graph.json').Trim()
Confirm-Check -Name '4a  the oracle blob is unchanged' `
    -Ok ($oracleNow -eq $OracleBlob) `
    -Detail ("blob {0}, pinned {1}" -f $oracleNow, $OracleBlob)

$briefNow = (git -C $RepoRoot rev-parse 'HEAD:evals/functional/BRIEF.md').Trim()
Confirm-Check -Name '4b  the brief blob is unchanged' `
    -Ok ($briefNow -eq $BriefBlob) -Detail ("blob {0}" -f $briefNow)

$seedNow = (git -C $RepoRoot rev-parse 'HEAD:evals/functional/seed').Trim()
Confirm-Check -Name '4c  the seed tree is unchanged' `
    -Ok ($seedNow -eq $SeedTree) -Detail ("tree {0}" -f $seedNow)

$pinDiff = @(git -C $RepoRoot diff --name-only "$PluginSha..HEAD" -- skills/ commands/ .claude-plugin/ evals/)
Confirm-Check -Name '4d  plugin and instrument unchanged since the pinned SHA' `
    -Ok ($pinDiff.Count -eq 0) `
    -Detail $(if ($pinDiff.Count) { "changed: $($pinDiff -join ', ')" } else { 'no paths changed' })

# ---------------------------------------------------------------------------
# 5. No credential anywhere in the record or the module.
# ---------------------------------------------------------------------------
# A credential is a high-entropy SECRET VALUE, not the name of the variable that
# holds one. Scanning for the name alone fires on every place the credential rule
# is documented - the README's `$env:AZDO_PAT = '<your token>'`, the about_ topic,
# a test's deliberately labelled dummy - and a check that cries wolf on its own
# documentation gets deleted rather than fixed.
#
# So: find assignments to the variable, then judge the VALUE. A placeholder has
# angle brackets or spaces; a labelled dummy has hyphenated words; a real Azure
# DevOps PAT is a long unbroken run of letters and digits.
function Test-SecretShaped {
    param([Parameter(Mandatory)] [AllowEmptyString()] [string] $Value)
    # 20+ characters, letters and digits only. 'test-token-not-a-real-credential'
    # fails on the hyphens, '<your token>' on the brackets and the space.
    $Value -match '^[A-Za-z0-9]{20,}$'
}

$scanRoots = @($RunDir, $Clone, (Join-Path $RepoRoot 'plans/0026-run-004'))
$patHits = [System.Collections.Generic.List[string]]::new()
$assignment = '(?:AZDO_PAT|PAT|Token|Password|Secret)\s*=\s*[''"]([^''"]+)[''"]'
$bearer = 'Authorization\s*[:=]\s*[''"]Basic\s+([A-Za-z0-9+/=]{20,})'

foreach ($root in $scanRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue) {
        if ($file.FullName -match '[\\/](\.git|output|node_modules)[\\/]') { continue }
        if ($file.Length -gt 2MB) { continue }
        $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $text) { continue }

        foreach ($match in [regex]::Matches($text, $assignment)) {
            if (Test-SecretShaped $match.Groups[1].Value) {
                $patHits.Add(("{0}  [a secret-shaped assignment]" -f $file.FullName))
            }
        }
        foreach ($match in [regex]::Matches($text, $bearer)) {
            $patHits.Add(("{0}  [a literal Basic auth header]" -f $file.FullName))
        }
        # The live value itself, never printed - only its presence is reported.
        # This is the check that cannot be fooled by a shape heuristic.
        if ($env:AZDO_PAT -and $text.Contains($env:AZDO_PAT)) {
            $patHits.Add(("{0}  [the live token, verbatim]" -f $file.FullName))
        }
    }
}
Confirm-Check -Name '5   no credential in the run record or the module clone' `
    -Ok ($patHits.Count -eq 0) `
    -Detail $(if ($patHits.Count) { "hits: $($patHits -join '; ')" } else { 'scanned run record, module clone and plan; zero hits' })

# ---------------------------------------------------------------------------
# Probes. Each breaks something, asserts the break landed, then requires red.
# ---------------------------------------------------------------------------
if ($FailCheck) {
    Write-Host ''
    Write-Host 'Probes — each breaks something on purpose and requires the check to go red'
    Write-Host ''

    # P1 against check 3a/3c: drop one node from a COPY of the graph.
    $broken = Join-Path $Scratch 'broken-graph.json'
    $g = Get-Content -LiteralPath $committedGraph -Raw | ConvertFrom-Json
    $before = @($g.nodes).Count
    $g.nodes = @($g.nodes | Select-Object -Skip 1)
    $after = @($g.nodes).Count
    $g | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $broken -Encoding utf8NoBOM
    Confirm-Check -Name 'P1a the break landed: one node removed from the copy' `
        -Ok ($after -eq $before - 1) -Detail ("{0} -> {1} nodes" -f $before, $after)

    $brokenReport = Join-Path $Scratch 'broken-report.json'
    $brokenRun = Start-Process pwsh -PassThru -Wait -NoNewWindow -ArgumentList @(
        '-NoProfile', '-File', (Join-Path $RepoRoot 'evals/functional/Compare-Graph.ps1'),
        '-CandidatePath', $broken, '-ReportPath', $brokenReport, '-Quiet') `
        -WorkingDirectory $RepoRoot -RedirectStandardOutput (Join-Path $Scratch 'broken.txt') -RedirectStandardError (Join-Path $Scratch 'broken.err.txt')
    $brokenResult = Get-Content -LiteralPath $brokenReport -Raw | ConvertFrom-Json
    Confirm-Check -Name 'P1b check 3 goes red on the broken graph' `
        -Ok ([int] $brokenResult.differenceCount -gt 0 -and $brokenRun.ExitCode -ne 0) `
        -Detail ("differences {0}, exit {1}" -f $brokenResult.differenceCount, $brokenRun.ExitCode)

    # P2 against check 4d: the pin check must notice a base it should not match.
    $wrongBase = (git -C $RepoRoot rev-list --max-parents=0 HEAD | Select-Object -Last 1).Trim()
    $wrongDiff = @(git -C $RepoRoot diff --name-only "$wrongBase..HEAD" -- skills/ commands/ .claude-plugin/ evals/)
    Confirm-Check -Name 'P2  check 4d goes red against a base the plugin did not come from' `
        -Ok ($wrongDiff.Count -gt 0) `
        -Detail ("{0} paths differ from the root commit" -f $wrongDiff.Count)

    # P3 against check 5: plant a credential and require a hit. The token is
    # GENERATED, not written as a literal, so this file never contains a
    # 52-character secret-shaped string for its own scanner to find.
    $alphabet = [char[]] 'abcdefghijklmnopqrstuvwxyz234567'
    $fakeToken = -join (1..52 | ForEach-Object { $alphabet | Get-Random })
    $planted = Join-Path $Scratch 'planted.txt'
    "AZDO_PAT = `"$fakeToken`"" | Set-Content -LiteralPath $planted -Encoding utf8NoBOM

    $plantedText = Get-Content -LiteralPath $planted -Raw
    $plantedHit = $false
    foreach ($match in [regex]::Matches($plantedText, $assignment)) {
        if (Test-SecretShaped $match.Groups[1].Value) { $plantedHit = $true }
    }
    Confirm-Check -Name 'P3a the break landed: a real-shaped token was written' `
        -Ok ($fakeToken.Length -eq 52) -Detail '52 characters, letters and digits only'
    Confirm-Check -Name 'P3b check 5 finds it' `
        -Ok $plantedHit -Detail 'the scanner is not vacuously clean'

    # P3c: and it still does NOT fire on the placeholders it must tolerate, or
    # the check would be deleted the first time someone documented the rule.
    $tolerated = @('<your token>', 'test-token-not-a-real-credential', '$env:AZDO_PAT', '')
    $falsePositive = @($tolerated | Where-Object { Test-SecretShaped $_ })
    Confirm-Check -Name 'P3c check 5 tolerates placeholders and labelled dummies' `
        -Ok ($falsePositive.Count -eq 0) `
        -Detail ("{0} of {1} documented placeholders would fire" -f $falsePositive.Count, $tolerated.Count)

    # P4 against check 2a: the denominator must be read, not assumed.
    Confirm-Check -Name 'P4  check 2a would go red on a different denominator' `
        -Ok ([int] $fresh.CasesDefined -ne ($ExpectedCasesDefined + 1)) `
        -Detail ("cases-defined is {0}; the check compares it rather than restating it" -f $fresh.CasesDefined)
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host ("Checks run : {0}" -f $script:Checks)
Write-Host ("Failed     : {0}" -f $script:Failures.Count)
Write-Host ("Skipped    : {0}" -f $script:Skipped.Count)
if ($script:Skipped.Count) {
    Write-Host ''
    Write-Host 'THIS RUN GRADED LESS THAN IT CLAIMS TO:'
    foreach ($name in $script:Skipped) { Write-Host ("  - {0}" -f $name) }
}
if ($script:Failures.Count) {
    Write-Host ''
    foreach ($name in $script:Failures) { Write-Host ("  FAILED: {0}" -f $name) }
    exit 1
}
exit 0
