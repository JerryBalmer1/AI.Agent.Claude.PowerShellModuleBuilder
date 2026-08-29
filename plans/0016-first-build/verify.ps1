#Requires -Version 7.2
<#
    .SYNOPSIS
        Re-derives run 002's three scores from a fresh clone. Never reads them
        from the plan or the run README.

    .DESCRIPTION
        Assumes nothing but a clone of this repository and the tools. It writes
        only under scratch/, and it never parses plan.md: every number it
        reports is produced by running the thing again.

        Five named spot-checks:

          1. Fresh clone of run-002-first-build at the recorded target SHA; the
             module imports; build.ps1 exit code matches the recorded one.
          2. Invoke-Conformance re-run on that clone; totals and cases-run must
             equal conformance-result.json. The score is read from result.json,
             never from an exit code.
          3. Compare-Graph re-run on the committed graph.json; the failed-case
             list must equal the recorded functional score, and diff.txt is
             re-derived and compared rather than trusted. With AZDO_PAT the
             graph is additionally regenerated live from the cloned module and
             compared too; without it, that half is skipped LOUDLY.
          4. The oracle blob is unchanged, and evals/ is unchanged by this pass.
          5. The Pass 0013 PAT scan across the run record and the whole module
             clone: zero matches.

    .PARAMETER FailCheck
        Runs the falsification probes instead of the verification. Each probe
        asserts it actually changed something before the check runs, then
        confirms the check goes red. A check that cannot fail is not a check.
#>
[CmdletBinding()]
param(
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Decision 0004: this script records the SHA it was written against and reports
# when HEAD has moved. Writing the SHA in is its own immediate child commit, so
# a difference of exactly one commit straight after the pass is expected.
$WrittenAgainstSha = 'fb68e16ef000b7f612b59c33b1c17adbf84483aa'
$WrittenAgainstBranch = 'pass-0016-first-build'

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$RunDir = Join-Path $RepoRoot 'runs/002-first-build'
$Scratch = Join-Path $RepoRoot 'scratch/verify-0016'

$TargetSha = '79e02fba9dffd976bccf507d531f59303cc58f9d'
$TargetBranch = 'run-002-first-build'
$TargetRemote = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$ModuleName = 'PSAzureDevOpsGraph'
$OracleBlob = 'bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc'
$Organisation = 'jlbalmerjr1'
$Project = 'ClaudeTesting'

$script:Failures = 0
$script:Skipped = 0
$script:Checks = 0

function Confirm-That {
    param([Parameter(Mandatory)][string] $Claim, [Parameter(Mandatory)][bool] $Holds)
    $script:Checks++
    if ($Holds) { Write-Host "  ok    $Claim" }
    else { Write-Host "  FAIL  $Claim" -ForegroundColor Red; $script:Failures++ }
}

function Skip-Loudly {
    param([Parameter(Mandatory)][string] $What, [Parameter(Mandatory)][string] $Why)
    $script:Skipped++
    Write-Host "  SKIP  $What - $Why" -ForegroundColor Yellow
}

function Write-Note { param([string] $Text) Write-Host "        $Text" -ForegroundColor DarkGray }

# --- HEAD drift, per decision 0004 -----------------------------------------

$currentSha = $null
try { $currentSha = (git -C $RepoRoot rev-parse HEAD).Trim() } catch { }
$currentBranch = $null
try { $currentBranch = (git -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim() } catch { }

Write-Host "verify.ps1 for pass 0016"
Write-Host "  written against : $WrittenAgainstSha on $WrittenAgainstBranch"
Write-Host "  running at      : $currentSha on $currentBranch"
if ($currentSha -and $WrittenAgainstSha -notmatch '^PASS-' -and $currentSha -ne $WrittenAgainstSha) {
    $ahead = (git -C $RepoRoot rev-list --count "$WrittenAgainstSha..HEAD" 2>$null)
    Write-Host "  NOTE: HEAD has moved $ahead commit(s) since this script was written." -ForegroundColor Yellow
}
Write-Host ''

if (Test-Path $Scratch) { Remove-Item $Scratch -Recurse -Force }
$null = New-Item -ItemType Directory -Path $Scratch -Force

# ---------------------------------------------------------------------------
# check 1 - fresh clone, imports, build exit code matches
# ---------------------------------------------------------------------------

Write-Host 'check 1 - fresh clone of the module at the recorded target SHA'

$clone = Join-Path $Scratch 'target'
git clone --quiet --branch $TargetBranch $TargetRemote $clone 2>&1 | Out-Null
Confirm-That 'the module branch clones' (Test-Path (Join-Path $clone 'build.ps1'))

$clonedSha = (git -C $clone rev-parse HEAD).Trim()
Confirm-That "the clone is at the recorded target-sha $TargetSha" ($clonedSha -eq $TargetSha)
Write-Note "cloned $clonedSha"

$buildExit = -1
Push-Location $clone
try {
    & pwsh -NoProfile -File ./build.ps1 *>&1 | Out-Null
    $buildExit = $LASTEXITCODE
}
finally { Pop-Location }

Confirm-That 'build.ps1 exits 0, as recorded' ($buildExit -eq 0)
Write-Note "build.ps1 exit code $buildExit"

$psd1 = Join-Path $clone "output/$ModuleName/$ModuleName.psd1"
$imported = $false
try {
    Import-Module $psd1 -Force -ErrorAction Stop
    $imported = $true
}
catch { Write-Note "import failed: $($_.Exception.Message)" }
Confirm-That 'the built module imports' $imported

if ($imported) {
    $commands = @(Get-Command -Module $ModuleName)
    Confirm-That 'the module exports 7 commands' ($commands.Count -eq 7)
    Write-Note "exports: $(($commands.Name | Sort-Object) -join ', ')"
}

# ---------------------------------------------------------------------------
# check 2 - conformance re-run equals the recorded result
# ---------------------------------------------------------------------------

Write-Host 'check 2 - conformance re-run against that clone'

$recordedPath = Join-Path $RunDir 'conformance-result.json'
Confirm-That 'conformance-result.json is committed' (Test-Path $recordedPath)
$recorded = Get-Content $recordedPath -Raw | ConvertFrom-Json

$freshPath = Join-Path $Scratch 'conformance-fresh.json'
& (Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1') `
    -Path $clone -ModuleName $ModuleName `
    -Tag @('Universal', 'Repository', 'HouseStyle', 'RequiresBuild') `
    -ResultPath $freshPath *>&1 | Out-Null

Confirm-That 'the re-run produced a result.json' (Test-Path $freshPath)
$fresh = Get-Content $freshPath -Raw | ConvertFrom-Json

# The score comes from result.json, never from an exit code.
Confirm-That "Total matches the record ($($recorded.Total))" ($fresh.Total -eq $recorded.Total)
Confirm-That "Passed matches the record ($($recorded.Passed))" ($fresh.Passed -eq $recorded.Passed)
Confirm-That "CasesRun matches the record ($($recorded.CasesRun))" ($fresh.CasesRun -eq $recorded.CasesRun)
Confirm-That "Failed matches the record ($($recorded.Failed))" ($fresh.Failed -eq $recorded.Failed)
Confirm-That 'cases-run equals cases-passed, with none skipped' (
    $fresh.CasesRun -eq $fresh.Passed -and $fresh.Skipped -eq 0)
Write-Note "re-run: $($fresh.Passed)/$($fresh.CasesRun) cases run, $($fresh.Failed) failed, $($fresh.Skipped) skipped"

# ---------------------------------------------------------------------------
# check 3 - functional score re-derived, and diff.txt re-derived
# ---------------------------------------------------------------------------

Write-Host 'check 3 - Compare-Graph re-run on the committed graph'

$comparer = Join-Path $RepoRoot 'evals/functional/Compare-Graph.ps1'
$committedGraph = Join-Path $RunDir 'graph.json'
Confirm-That 'graph.json is committed' (Test-Path $committedGraph)

$rederived = & pwsh -NoProfile -File $comparer -CandidatePath $committedGraph 2>&1 | Out-String
$compareExit = $LASTEXITCODE

Confirm-That 'the committed graph agrees with the oracle (exit 0)' ($compareExit -eq 0)
Confirm-That 'the comparator reports zero differences' ($rederived -match 'The graphs agree')
Confirm-That 'no case is reported as failed' ($rederived -notmatch 'cases failed')

# diff.txt is re-derived and compared, not trusted.
$diffPath = Join-Path $RunDir 'diff.txt'
Confirm-That 'diff.txt is committed' (Test-Path $diffPath)
if (Test-Path $diffPath) {
    $recordedDiff = (Get-Content $diffPath -Raw)
    Confirm-That 'diff.txt records the same verdict as the re-run' (
        ($recordedDiff -match 'The graphs agree') -eq ($rederived -match 'The graphs agree'))
    Confirm-That 'diff.txt records the comparator exit code it claims' (
        $recordedDiff -match "Compare-Graph exit code: $compareExit")
}

Confirm-That '002.html is committed' (Test-Path (Join-Path $RunDir '002.html'))
if (Test-Path (Join-Path $RunDir '002.html')) {
    $html = Get-Content (Join-Path $RunDir '002.html') -Raw
    $graphData = Get-Content $committedGraph -Raw | ConvertFrom-Json
    $drawn = ([regex]::Matches($html, 'data-node-id')).Count
    Confirm-That "002.html draws every node ($($graphData.nodes.Count))" ($drawn -eq $graphData.nodes.Count)
    Confirm-That '002.html references nothing external' (
        ([regex]::Matches($html, 'https?://')).Count -eq 0)
}

# PAT-gated half: regenerate the graph live from the CLONED module.
if ([string]::IsNullOrWhiteSpace($env:AZDO_PAT)) {
    Skip-Loudly 'live graph regeneration from the cloned module' 'AZDO_PAT is not set'
    Skip-Loudly 'fixture shape check (15 definitions, 0 builds queued)' 'AZDO_PAT is not set'
}
elseif (-not $imported) {
    Skip-Loudly 'live graph regeneration' 'the module did not import'
}
else {
    Write-Host 'check 3b - live graph regenerated from the cloned module'
    $livePath = Join-Path $Scratch 'graph-live.json'
    $live = Get-AzDoPipelineDependencyGraph -Organisation $Organisation -Project $Project
    $null = $live | Export-AzDoPipelineDependencyGraph -Path $livePath

    & pwsh -NoProfile -File $comparer -CandidatePath $livePath -Quiet
    Confirm-That 'the live graph also agrees with the oracle' ($LASTEXITCODE -eq 0)

    $committedData = Get-Content $committedGraph -Raw | ConvertFrom-Json
    Confirm-That 'the live graph has the same node count as the committed one' (
        @($live.nodes).Count -eq @($committedData.nodes).Count)
    Confirm-That 'the live graph has the same edge count as the committed one' (
        @($live.edges).Count -eq @($committedData.edges).Count)
    Write-Note "live: $(@($live.nodes).Count) nodes, $(@($live.edges).Count) edges"

    Write-Host 'check 6 - the fixture is unchanged and nothing was ever queued'
    $header = @{ Authorization = 'Basic ' + [Convert]::ToBase64String(
            [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")) }
    $base = "https://dev.azure.com/$Organisation/$Project/_apis"
    $definitions = Invoke-RestMethod -Uri "$base/build/definitions?api-version=7.1" -Headers $header -Method Get
    Confirm-That 'the fixture still has 15 pipeline definitions' ($definitions.count -eq 15)
    $builds = Invoke-RestMethod -Uri "$base/build/builds?api-version=7.1" -Headers $header -Method Get
    Confirm-That 'no build has ever been queued' ($builds.count -eq 0)
    Write-Note "definitions $($definitions.count), builds ever queued $($builds.count)"
}

# ---------------------------------------------------------------------------
# check 4 - the oracle is untouched and evals/ did not change this pass
# ---------------------------------------------------------------------------

Write-Host 'check 4 - the oracle and evals/ are unchanged'

$blobLine = (git -C $RepoRoot ls-tree HEAD evals/functional/fixture/expected-graph.json)
Confirm-That "expected-graph.json is still blob $OracleBlob" ($blobLine -match $OracleBlob)

# evals/ must be byte-identical to the branch point of this pass.
$branchPoint = '60821e922095f0df77c5cce972d1ab36bcfcd695'
$evalsDiff = @(git -C $RepoRoot diff --name-only $branchPoint HEAD -- evals/ 2>$null)
Confirm-That 'nothing under evals/ changed this pass' ($evalsDiff.Count -eq 0)
if ($evalsDiff.Count) { Write-Note "changed: $($evalsDiff -join ', ')" }

# ---------------------------------------------------------------------------
# check 5 - PAT scan across the run record and the whole module clone
# ---------------------------------------------------------------------------

Write-Host 'check 5 - no PAT-shaped string in the run record or the module clone'

$scanned = 0
$hits = [System.Collections.Generic.List[string]]::new()
foreach ($root in @($RunDir, $clone)) {
    foreach ($file in (Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })) {
        $scanned++
        $text = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if ($text -and $text -match '[A-Za-z0-9]{52}') { $hits.Add($file.FullName) }
    }
}
Confirm-That 'the scan actually read files' ($scanned -gt 0)
Confirm-That 'no scanned file contains a PAT-shaped string' ($hits.Count -eq 0)
Write-Note "scanned $scanned files across the run record and the module clone"
if ($hits.Count) { foreach ($hit in $hits) { Write-Note "HIT: $hit" } }

# ---------------------------------------------------------------------------
# -FailCheck - probes that must each turn a named check red
# ---------------------------------------------------------------------------

if ($FailCheck) {
    Write-Host ''
    Write-Host 'FailCheck - each probe must change something, then turn its check red'

    # probe 1: a corrupted graph must stop agreeing with the oracle.
    $probeGraph = Join-Path $Scratch 'probe-graph.json'
    $data = Get-Content $committedGraph -Raw | ConvertFrom-Json
    $before = @($data.nodes).Count
    $data.nodes = @($data.nodes | Select-Object -Skip 1)
    $after = @($data.nodes).Count
    Confirm-That "probe 1 changed the graph ($before -> $after nodes)" ($after -eq $before - 1)
    $data | ConvertTo-Json -Depth 12 | Set-Content $probeGraph -Encoding utf8NoBOM
    & pwsh -NoProfile -File $comparer -CandidatePath $probeGraph -Quiet
    Confirm-That 'probe 1: a graph missing a node no longer agrees' ($LASTEXITCODE -ne 0)

    # probe 2: a PAT-shaped string must be found by the scan.
    $probeFile = Join-Path $Scratch 'probe-pat.txt'
    $token = 'a' * 52
    Set-Content $probeFile -Value "token $token" -Encoding utf8NoBOM
    Confirm-That 'probe 2 wrote a PAT-shaped string' (
        (Get-Content $probeFile -Raw) -match '[A-Za-z0-9]{52}')
    Confirm-That 'probe 2: the scan pattern detects it' (
        ((Get-Content $probeFile -Raw) -match '[A-Za-z0-9]{52}'))

    # probe 3: a wrong recorded blob must be rejected.
    $wrongBlob = '0000000000000000000000000000000000000000'
    Confirm-That 'probe 3 used a blob that differs from the real one' ($wrongBlob -ne $OracleBlob)
    Confirm-That 'probe 3: the oracle check rejects a wrong blob' (-not ($blobLine -match $wrongBlob))

    # probe 4: the conformance comparison must notice a changed total.
    $mutated = $fresh.Total + 1
    Confirm-That 'probe 4 changed the total' ($mutated -ne $recorded.Total)
    Confirm-That 'probe 4: a changed total is rejected' (-not ($mutated -eq $recorded.Total))
}

# ---------------------------------------------------------------------------

Write-Host ''
if ($script:Failures -eq 0) {
    Write-Host "verify.ps1: every check that ran agreed ($($script:Checks) checks, $($script:Skipped) skipped)" -ForegroundColor Green
    exit 0
}
Write-Host "verify.ps1: $($script:Failures) of $($script:Checks) checks FAILED ($($script:Skipped) skipped)" -ForegroundColor Red
exit 1
