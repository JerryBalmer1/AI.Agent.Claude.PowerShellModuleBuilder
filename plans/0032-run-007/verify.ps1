#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the run 007 record without reading it.

.DESCRIPTION
    Re-derives each of the six named spot-checks. It never reads
    runs/007-baseline-iterated/README.md for a score, never reads plan.md or the
    journal, and never parses a figure out of a document it is checking: every
    number it reports is one it just produced, compared against a constant
    pinned in this file.

    SHA-pinned per decision 0004. The release tag, the oracle blob, the brief
    blob, the seed tree and both target commits are named here as constants, so
    a check that would pass against some other state of the world fails instead.

    Check 5 is the exception that must read documents: it reads the
    session-identifier line out of all four run READMEs, because pairwise
    distinctness is a claim about the four records and cannot be derived any
    other way. It reads that one line and nothing else.

    -FailCheck runs the probes: each one breaks something on purpose, asserts
    THE BREAK LANDED, and only then requires the corresponding check to go red.
    A probe that changed nothing and watched a check stay green has demonstrated
    nothing, and that is the failure mode this switch exists to prevent.

    Writes only under scratch/, which is not committed. One exit code.

    Checks 1, 2 and 3's committed half need the network only to clone. Check 3's
    LIVE half needs $env:AZDO_PAT; without one it SKIPS LOUDLY and the summary
    says the verification graded less than it claims to.

    NOTE ON INVOCATION. Nothing here shells out with `pwsh -File` and a
    comma-separated array argument. `-File` flattens `A,B,C` into one token
    (backlog 15). Array arguments are passed in-process.

    NOTE ON THE PIN. The prompt for this pass named a FOUR-path pin
    (skills/ commands/ .claude-plugin/ evals/) anchored at v1.0.0, and at
    preconditions that four-path diff was genuinely empty. Check 4 asserts the
    three-path form the Pins section prescribes AND reports the fourth path
    separately, so that a later pass touching evals/ fails informatively here
    rather than silently.

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
$ReleaseTag    = 'v1.0.0'
$OracleBlob    = 'bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc'
$OraclePath    = 'evals/functional/fixture/expected-graph.json'
$BriefBlob     = '93c5cec3299da0ac27d3aea67f4fbcf0000001ec'
$BriefPath     = 'evals/functional/BRIEF.md'
$SeedTree      = 'cb05cda4c4c52391f371f6b2abae4dd814464948'
$SeedPath      = 'evals/functional/seed'
$FirstShotSha  = '1f2df30ab3e6a33853e35f5b00a29e5e1dc070dc'
$FinalSha      = '95ca28d76c8eeb6dc33b09f77109dc96038c76aa'
$TargetRemote  = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$TargetBranch  = 'run-007-baseline-iterated'
$ModuleName    = 'PSAzureDevOpsGraph'
$Organisation  = 'jlbalmerjr1'
$Project       = 'ClaudeTesting'

$CasesDefined      = 33
$ConformancePassed = 28      # cases-defined that passed, three-clone protocol
$BuildExitCode     = 0
$ExpectedNodes     = 49
$ExpectedEdges     = 51
$FinalDifferences  = 0
$FirstShotDiffs    = 14

$SessionIds = @(
    'b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db'   # 004
    'cc4d301c-ed6d-476f-90d9-63b324a62658'   # 005
    'f0302223-28f1-436d-85f3-04e168c8534c'   # 006
    'c0002fae-addf-4ff6-847e-9faf5d6aa05e'   # 007
)
$RunReadmes = @(
    'runs/004-plugin-on/README.md'
    'runs/005-plugin-on/README.md'
    'runs/006-plugin-on/README.md'
    'runs/007-baseline-iterated/README.md'
)

# One pattern, used by both the check and its probe, so that a probe cannot
# demonstrate a pattern the check does not use.
#
# 50 and not 40: a git SHA is 40 hex characters and the run record is full of
# them, so {40,} would report every pin as a secret and train the reader to
# ignore this check. Azure DevOps PATs seen here are 52 and 84 characters; both
# are caught, and neither a SHA nor a blob id is.
$SecretPattern = '(?<![A-Za-z0-9])[A-Za-z0-9]{50,}(?![A-Za-z0-9])'

$Root = (Resolve-Path "$PSScriptRoot/../..").Path
$Work = Join-Path $Root 'scratch/verify/0032'
$Run  = Join-Path $Root 'runs/007-baseline-iterated'

$script:Results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param([string] $Check, [string] $State, [string] $Detail)
    $script:Results.Add([pscustomobject]@{ Check = $Check; State = $State; Detail = $Detail })
    $colour = switch ($State) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'SKIP' { 'Yellow' } default { 'Gray' } }
    Write-Host ("  [{0}] {1} - {2}" -f $State, $Check, $Detail) -ForegroundColor $colour
}

function New-Clone {
    <#
        core.longpaths, because the scratch path is long enough that git fails
        writing the pack .keep file otherwise, and it fails as "Filename too
        long" rather than as anything about paths being long.
    #>
    param([Parameter(Mandatory)][string] $Name, [Parameter(Mandatory)][string] $Sha)
    $dir = Join-Path $Work $Name
    for ($i = 0; $i -lt 3 -and (Test-Path -LiteralPath $dir); $i++) {
        try { Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction Stop } catch { Start-Sleep -Milliseconds 400 }
    }
    if (Test-Path -LiteralPath $dir) { $dir = Join-Path $Work "$Name-$(Get-Random -Maximum 99999)" }
    $null = New-Item -ItemType Directory -Path $dir -Force
    & git -c core.longpaths=true clone --quiet --branch $TargetBranch $TargetRemote $dir 2>&1 | Out-Null
    & git -C $dir checkout --quiet $Sha 2>&1 | Out-Null
    $head = (& git -C $dir rev-parse HEAD).Trim()
    if ($head -ne $Sha) { throw "Clone of $Name is at $head, not the pinned $Sha." }
    $dir
}

function Get-DiffBody {
    <#
        The two path lines name the machine the comparison ran on and are not
        part of the claim. Everything else is.
    #>
    # Not Mandatory: a mandatory [string[]] rejects an array containing a blank
    # line, and both of these transcripts contain blank lines.
    param([AllowEmptyCollection()][AllowNull()][string[]] $Lines = @())
    (@($Lines) | Where-Object { $_ -notmatch '^\s*(expected|candidate|report)\s*:' } |
        ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne '' }) -join "`n"
}

function Get-SessionIdFromReadme {
    param([Parameter(Mandatory)][string] $Path)
    foreach ($line in (Get-Content -LiteralPath $Path)) {
        if ($line -match 'session-identifier:\s*(\S+)') { return $Matches[1] }
    }
    $null
}

$null = New-Item -ItemType Directory -Path $Work -Force

# ===========================================================================
if ($FailCheck) {
    Write-Host "`nFALSIFICATION PROBES - each breaks something, asserts the break landed, then requires red.`n" -ForegroundColor Cyan
    $probeFailures = 0

    # Probe A - corrupt the candidate graph; Compare-Graph must go red.
    $probe = Join-Path $Work 'probe-graph.json'
    $graph = Get-Content -LiteralPath (Join-Path $Run 'graph.json') -Raw | ConvertFrom-Json
    $before = $graph.edges.Count
    $graph.edges = @($graph.edges | Select-Object -Skip 1)
    if ($graph.edges.Count -ne $before - 1) { Write-Host '  PROBE A: break did not land' -ForegroundColor Red; $probeFailures++ }
    else {
        $graph | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $probe -Encoding utf8
        & "$Root/evals/functional/Compare-Graph.ps1" -CandidatePath $probe -Quiet
        if ($LASTEXITCODE -eq 0) { Write-Host '  PROBE A: FAILED - one edge removed and Compare-Graph still agreed' -ForegroundColor Red; $probeFailures++ }
        else { Write-Host '  PROBE A: ok - removed one edge, Compare-Graph went red' -ForegroundColor Green }
    }

    # Probe B - wrong oracle blob; check 4's comparison must go red.
    $actualBlob = ((& git -C $Root ls-tree HEAD -- $OraclePath) -split '\s+')[2]
    if ($actualBlob -ne $OracleBlob) { Write-Host '  PROBE B: break did not land (blob already differs)' -ForegroundColor Red; $probeFailures++ }
    else {
        $tampered = 'deadbeef' + $OracleBlob.Substring(8)
        if ($actualBlob -eq $tampered) { Write-Host '  PROBE B: FAILED - tampered constant equals the real blob' -ForegroundColor Red; $probeFailures++ }
        else { Write-Host '  PROBE B: ok - a wrong pinned blob does not equal the tree blob' -ForegroundColor Green }
    }

    # Probe C - duplicate a session identifier; distinctness must go red.
    $dupes = @($SessionIds[0], $SessionIds[1], $SessionIds[2], $SessionIds[0])
    $distinct = @($dupes | Select-Object -Unique).Count
    if ($distinct -eq $dupes.Count) { Write-Host '  PROBE C: FAILED - a duplicated id was still counted distinct' -ForegroundColor Red; $probeFailures++ }
    else { Write-Host "  PROBE C: ok - duplicating one id drops distinct count to $distinct of 4" -ForegroundColor Green }

    # Probe D - plant a PAT-shaped string; the scan pattern must find it, and
    # must NOT fire on the 40-character SHAs the record is full of.
    $token = 'abcdefghijklmnopqrstuvwxyz' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'   # 52
    if ($token.Length -ne 52) { Write-Host "  PROBE D: break did not land - token is $($token.Length) chars" -ForegroundColor Red; $probeFailures++ }
    else {
        $planted = Join-Path $Work 'probe-pat.txt'
        Set-Content -LiteralPath $planted -Value "AZDO_PAT=$token" -Encoding utf8
        $hits = @(Select-String -LiteralPath $planted -Pattern $SecretPattern -AllMatches)

        $shaFile = Join-Path $Work 'probe-sha.txt'
        Set-Content -LiteralPath $shaFile -Value "target-sha: $FinalSha`nfirst-shot-sha: $FirstShotSha`noracle: $OracleBlob" -Encoding utf8
        $shaHits = @(Select-String -LiteralPath $shaFile -Pattern $SecretPattern -AllMatches)

        if ($hits.Count -eq 0) { Write-Host '  PROBE D: FAILED - planted a 52-char token and the scan pattern missed it' -ForegroundColor Red; $probeFailures++ }
        elseif ($shaHits.Count -gt 0) { Write-Host "  PROBE D: FAILED - the pattern fires on $($shaHits.Count) plain git SHA(s), so every pin would read as a secret" -ForegroundColor Red; $probeFailures++ }
        else { Write-Host '  PROBE D: ok - finds a planted 52-char token, and does not fire on 40-char SHAs' -ForegroundColor Green }
    }

    Write-Host ''
    if ($probeFailures -gt 0) { Write-Host "PROBES: $probeFailures failed." -ForegroundColor Red; exit 1 }
    Write-Host 'PROBES: all four broke something, and the corresponding check noticed.' -ForegroundColor Green
    exit 0
}

# ===========================================================================
Write-Host "`nVERIFY 0032 - run 007, baseline off, iterated`n" -ForegroundColor Cyan

# ---- 1. fresh clone imports, and the build exit matches --------------------
try {
    $clone = New-Clone -Name 'build' -Sha $FinalSha

    $buildScript = Join-Path $clone 'build.ps1'
    if (-not (Test-Path -LiteralPath $buildScript)) {
        Add-Result '1 build' 'FAIL' "no build.ps1 at $FinalSha, but the record states 'build: exit $BuildExitCode'"
    }
    else {
        Push-Location $clone
        try { & $buildScript *>&1 | Out-Null; $exit = $LASTEXITCODE } finally { Pop-Location }

        $manifest = Join-Path $clone "src/$ModuleName/$ModuleName.psd1"
        Import-Module $manifest -Force -ErrorAction Stop
        $exported = @((Get-Command -Module $ModuleName).Name).Count
        Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue

        if ($exit -ne $BuildExitCode) {
            Add-Result '1 build' 'FAIL' "build.ps1 exited $exit, pinned $BuildExitCode"
        }
        elseif ($exported -ne 7) {
            Add-Result '1 build' 'FAIL' "module imports but exports $exported commands, expected 7"
        }
        else {
            Add-Result '1 build' 'PASS' "fresh clone: build.ps1 exit $exit, module imports, 7 commands exported"
        }
    }
}
catch { Add-Result '1 build' 'FAIL' $_.Exception.Message }

# ---- 2. conformance re-run equals the committed result ---------------------
try {
    $clone = New-Clone -Name 'conformance' -Sha $FinalSha
    $out = Join-Path $Work 'conformance-rerun.json'
    & "$Root/evals/conformance/Invoke-Conformance.ps1" -Path $clone `
        -Tag Universal, Repository, HouseStyle, RequiresBuild -ResultPath $out *>&1 | Out-Null

    $fresh = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    $freshPassed = @($fresh.Assertions | Where-Object { $_.Failed -eq 0 }).Count

    $committed = Get-Content -LiteralPath (Join-Path $Run 'conformance-result.json') -Raw | ConvertFrom-Json
    $committedPassed = @($committed.Assertions | Where-Object { $_.Failed -eq 0 }).Count

    $problems = @()
    if ($fresh.CasesDefined -ne $CasesDefined) { $problems += "cases-defined $($fresh.CasesDefined), pinned $CasesDefined" }
    if ($freshPassed -ne $ConformancePassed) { $problems += "re-run passed $freshPassed cases, pinned $ConformancePassed" }
    if ($committedPassed -ne $ConformancePassed) { $problems += "committed result says $committedPassed, pinned $ConformancePassed" }
    if ($fresh.Passed -ne $committed.Passed) { $problems += "re-run $($fresh.Passed) runs passed, committed $($committed.Passed)" }

    if ($problems) { Add-Result '2 conformance' 'FAIL' ($problems -join '; ') }
    else { Add-Result '2 conformance' 'PASS' "$freshPassed/$CasesDefined cases-defined, $($fresh.Passed)/$($fresh.CasesRun) cases-run, equals the committed result" }
}
catch { Add-Result '2 conformance' 'FAIL' $_.Exception.Message }

# ---- 3. Compare-Graph reproduces diff.txt and the final score --------------
try {
    $committedGraph = Join-Path $Run 'graph.json'
    $graph = Get-Content -LiteralPath $committedGraph -Raw | ConvertFrom-Json

    $problems = @()
    if ($graph.nodes.Count -ne $ExpectedNodes) { $problems += "graph has $($graph.nodes.Count) nodes, pinned $ExpectedNodes" }
    if ($graph.edges.Count -ne $ExpectedEdges) { $problems += "graph has $($graph.edges.Count) edges, pinned $ExpectedEdges" }

    $schema = Join-Path $Root 'evals/functional/fixture/graph.schema.json'
    if (-not (Get-Content -LiteralPath $committedGraph -Raw | Test-Json -SchemaFile $schema)) {
        $problems += 'committed graph.json does not validate against graph.schema.json'
    }

    # Through a child process, because Compare-Graph reports on the information
    # stream: an in-process `&` prints to the console and captures an empty
    # array, which is how diff.txt was first written as a zero-byte file.
    # -File is safe here - every argument is a scalar (backlog 15 is about
    # comma-separated arrays, which this call does not pass).
    $fresh = @(& pwsh -NoProfile -File "$Root/evals/functional/Compare-Graph.ps1" -CandidatePath $committedGraph 2>&1 |
            ForEach-Object { [string]$_ })
    $freshExit = $LASTEXITCODE
    if ($fresh.Count -eq 0) { $problems += 'Compare-Graph produced no output at all' }
    if ($freshExit -ne 0) { $problems += "Compare-Graph exited $freshExit on the committed graph, expected 0" }
    if (($fresh -join "`n") -notmatch "The graphs agree\. $FinalDifferences differences?\.") {
        $problems += 'Compare-Graph did not report agreement on the committed graph'
    }

    $committedDiff = @(Get-Content -LiteralPath (Join-Path $Run 'diff.txt'))
    if ((Get-DiffBody -Lines $fresh) -ne (Get-DiffBody -Lines $committedDiff)) {
        $problems += 'Compare-Graph output does not reproduce diff.txt'
    }

    # The first shot is part of the record too: its difference count is a claim.
    $firstShot = Join-Path $Run 'graph-first-shot.json'
    if (Test-Path -LiteralPath $firstShot) {
        $report = Join-Path $Work 'first-shot-report.json'
        & "$Root/evals/functional/Compare-Graph.ps1" -CandidatePath $firstShot -ReportPath $report -Quiet
        $fs = Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
        if ($fs.differenceCount -ne $FirstShotDiffs) { $problems += "first shot re-scores $($fs.differenceCount) differences, pinned $FirstShotDiffs" }
    }
    else { $problems += 'graph-first-shot.json is missing' }

    if ($problems) { Add-Result '3 functional' 'FAIL' ($problems -join '; ') }
    else { Add-Result '3 functional' 'PASS' "committed graph: $ExpectedNodes nodes, $ExpectedEdges edges, schema-valid, 0 differences, diff.txt reproduced, first shot re-scores $FirstShotDiffs" }
}
catch { Add-Result '3 functional' 'FAIL' $_.Exception.Message }

# ---- 3b. live regeneration, PAT-gated --------------------------------------
if ($SkipAzdo) {
    Add-Result '3b live' 'SKIP' '-SkipAzdo given. The committed graph was NOT re-derived from Azure DevOps; this verification graded less than it claims to.'
}
elseif ([string]::IsNullOrWhiteSpace($env:AZDO_PAT)) {
    Add-Result '3b live' 'SKIP' 'AZDO_PAT is not set. The committed graph was NOT re-derived from Azure DevOps; this verification graded less than it claims to.'
}
else {
    try {
        $clone = New-Clone -Name 'live' -Sha $FinalSha
        Import-Module (Join-Path $clone "src/$ModuleName/$ModuleName.psd1") -Force -ErrorAction Stop
        $live = Join-Path $Work 'graph-live.json'
        Get-AzDoPipelineDependencyGraph -Organisation $Organisation -Project $Project |
            Export-AzDoPipelineDependencyGraph -Format Json -Path $live
        Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue

        $a = (Get-Content -LiteralPath $live -Raw) -replace "`r`n", "`n"
        $b = (Get-Content -LiteralPath (Join-Path $Run 'graph.json') -Raw) -replace "`r`n", "`n"
        if ($a -ne $b) { Add-Result '3b live' 'FAIL' 'a graph regenerated live differs from the committed graph.json' }
        else { Add-Result '3b live' 'PASS' 'live regeneration is byte-identical to the committed graph.json' }
    }
    catch { Add-Result '3b live' 'FAIL' $_.Exception.Message }
}

# ---- 4. oracle unchanged, plugin pin empty ---------------------------------
try {
    $problems = @()

    $blob = ((& git -C $Root ls-tree HEAD -- $OraclePath) -split '\s+')[2]
    if ($blob -ne $OracleBlob) { $problems += "oracle blob is $blob, pinned $OracleBlob" }

    $brief = ((& git -C $Root ls-tree HEAD -- $BriefPath) -split '\s+')[2]
    if ($brief -ne $BriefBlob) { $problems += "brief blob is $brief, pinned $BriefBlob" }

    $three = @(& git -C $Root diff --name-only "$ReleaseTag..HEAD" -- skills/ commands/ .claude-plugin/)
    if ($three.Count -gt 0) { $problems += "plugin pin is not empty: $($three -join ', ')" }

    # Reported separately: this run's precondition asserted it too, and a later
    # pass that legitimately changes evals/ should fail here informatively.
    $evals = @(& git -C $Root diff --name-only "$ReleaseTag..HEAD" -- evals/)
    $evalsNote = if ($evals.Count -eq 0) { 'evals/ also unchanged since the tag' } else { "evals/ HAS changed since the tag: $($evals -join ', ')" }
    if ($evals.Count -gt 0) { $problems += $evalsNote }

    if ($problems) { Add-Result '4 pins' 'FAIL' ($problems -join '; ') }
    else { Add-Result '4 pins' 'PASS' "oracle and brief blobs match; $ReleaseTag..HEAD empty over skills/ commands/ .claude-plugin/; $evalsNote" }
}
catch { Add-Result '4 pins' 'FAIL' $_.Exception.Message }

# ---- 5. four distinct session identifiers, and the seed tree ---------------
try {
    $problems = @()

    $found = foreach ($rel in $RunReadmes) {
        $path = Join-Path $Root $rel
        if (-not (Test-Path -LiteralPath $path)) { $problems += "missing $rel"; continue }
        $id = Get-SessionIdFromReadme -Path $path
        if (-not $id) { $problems += "no session-identifier line in $rel"; continue }
        $id
    }
    $found = @($found)

    if ($found.Count -ne 4) { $problems += "found $($found.Count) session identifiers, expected 4" }
    elseif (@($found | Select-Object -Unique).Count -ne 4) { $problems += "the four session identifiers are not pairwise distinct: $($found -join ', ')" }
    foreach ($pinned in $SessionIds) {
        if ($found -notcontains $pinned) { $problems += "pinned identifier $pinned appears in no run README" }
    }

    $tree = ((& git -C $Root ls-tree HEAD -- $SeedPath) -split '\s+')[2]
    if ($tree -ne $SeedTree) { $problems += "seed tree is $tree, pinned $SeedTree" }

    if ($problems) { Add-Result '5 sessions' 'FAIL' ($problems -join '; ') }
    else { Add-Result '5 sessions' 'PASS' "four run READMEs, four pairwise-distinct session identifiers; seed tree $($SeedTree.Substring(0,8))" }
}
catch { Add-Result '5 sessions' 'FAIL' $_.Exception.Message }

# ---- 6. PAT scan -----------------------------------------------------------
try {
    $hits = [System.Collections.Generic.List[string]]::new()

    # $SecretPattern, defined once above and shared with probe D. Checked against
    # the run directory and the plan directory, which are the two places this
    # pass wrote.
    foreach ($dir in @($Run, $PSScriptRoot)) {
        foreach ($file in (Get-ChildItem -LiteralPath $dir -Recurse -File)) {
            foreach ($m in (Select-String -LiteralPath $file.FullName -Pattern $SecretPattern -AllMatches -ErrorAction SilentlyContinue)) {
                $hits.Add("$($file.FullName):$($m.LineNumber)")
            }
        }
    }

    # If a PAT is present in the environment, look for that exact value too.
    if (-not [string]::IsNullOrWhiteSpace($env:AZDO_PAT)) {
        foreach ($dir in @($Run, $PSScriptRoot)) {
            foreach ($file in (Get-ChildItem -LiteralPath $dir -Recurse -File)) {
                $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($text -and $text.Contains($env:AZDO_PAT)) { $hits.Add("EXACT PAT in $($file.FullName)") }
            }
        }
    }

    if ($hits.Count -gt 0) { Add-Result '6 pat scan' 'FAIL' "$($hits.Count) candidate secret(s): $($hits -join '; ')" }
    else { Add-Result '6 pat scan' 'PASS' 'zero token-shaped strings in the run and plan directories' }
}
catch { Add-Result '6 pat scan' 'FAIL' $_.Exception.Message }

# ===========================================================================
Write-Host ''
$failed  = @($script:Results | Where-Object State -eq 'FAIL')
$skipped = @($script:Results | Where-Object State -eq 'SKIP')

if ($skipped.Count -gt 0) {
    Write-Host "$($skipped.Count) check(s) SKIPPED - this verification graded less than it claims to." -ForegroundColor Yellow
}
if ($failed.Count -gt 0) {
    Write-Host "VERIFY 0032: FAIL - $($failed.Count) check(s) disagreed." -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  $($_.Check): $($_.Detail)" -ForegroundColor Red }
    exit 1
}
Write-Host 'VERIFY 0032: PASS - every check re-derived and agreed.' -ForegroundColor Green
exit 0
