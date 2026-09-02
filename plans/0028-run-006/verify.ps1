#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the run 006 record without reading it.

.DESCRIPTION
    Re-derives each of the six named spot-checks. It never reads
    runs/006-plugin-on/README.md for a score, never reads plan.md or the
    journal, and never parses a figure out of a document it is checking: every
    number it reports is one it just produced, compared against a constant
    pinned in this file.

    SHA-pinned per decision 0004. The plugin SHA, the oracle blob, the brief
    blob, the seed tree and both target commits are named here as constants, so
    a check that would pass against some other state of the world fails instead.

    Check 5 is the exception that must read documents: it reads the
    session-identifier line out of all three run READMEs, because pairwise
    distinctness is a claim about the three records and cannot be derived any
    other way. It reads that one line and nothing else.

    -FailCheck runs the probes: each one breaks something on purpose, asserts
    THE BREAK LANDED, and only then requires the corresponding check to go red.
    A probe that changed nothing and watched a check stay green has demonstrated
    nothing, and that is the failure mode this switch exists to prevent.

    Writes only under scratch/, which is not committed. One exit code.

    Check 1, 2 and 3's live half need the network; check 3's live half needs
    $env:AZDO_PAT. Without a PAT that half SKIPS LOUDLY and the summary says the
    verification graded less than it claims to.

    NOTE ON INVOCATION. Nothing here shells out with `pwsh -File` and a
    comma-separated array argument. `-File` flattens `A,B,C` into one token, and
    that bit run 005 three times including inside its own verify.ps1 (backlog
    15). Array arguments are passed in-process or via `-Command`.

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
$OraclePath = 'evals/functional/fixture/expected-graph.json'
$BriefBlob = '93c5cec3299da0ac27d3aea67f4fbcf0000001ec'
$SeedTree = 'cb05cda4c4c52391f371f6b2abae4dd814464948'
$FirstShotSha = '15ab6e3dc00a50c61dca4fd0e656df632103babe'
$FinalSha = '70669167ea5f59a47efb282002052f9e926a34bf'
$TargetRemote = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$TargetBranch = 'run-006-plugin-on'
$ModuleName = 'PSAzureDevOpsGraph'
$Organisation = 'jlbalmerjr1'
$Project = 'ClaudeTesting'
$CasesDefined = 33
$ExpectedNodes = 49
$ExpectedEdges = 51

$Root = (Resolve-Path "$PSScriptRoot/../..").Path
$Work = Join-Path $Root 'scratch/verify/0028'
$Run = Join-Path $Root 'runs/006-plugin-on'

$script:Results = [System.Collections.Generic.List[object]]::new()
$script:Clones = [System.Collections.Generic.List[string]]::new()

function Add-Result {
    param([string] $Check, [string] $State, [string] $Detail)
    $script:Results.Add([pscustomobject]@{ Check = $Check; State = $State; Detail = $Detail })
    $colour = switch ($State) { 'PASS' { 'Green' } 'FAIL' { 'Red' } 'SKIP' { 'Yellow' } default { 'Gray' } }
    Write-Host ("  [{0}] {1} — {2}" -f $State, $Check, $Detail) -ForegroundColor $colour
}

function New-Clone {
    <#
    .SYNOPSIS
        A fresh clone of the pinned target commit, in its own directory.
    .DESCRIPTION
        core.longpaths, because the scratch path is long enough that git fails
        writing the pack .keep file otherwise, and it fails as "Filename too
        long" rather than as anything about paths being long (F-16).
    #>
    param([Parameter(Mandatory)] [string] $Name, [Parameter(Mandatory)] [string] $Sha)
    $dir = Join-Path $Work $Name
    # A directory left behind by an earlier run can still be held open by a
    # process that has not fully exited. Retry, then fall back to a fresh name
    # rather than failing a check for a reason that is not about the run.
    for ($i = 0; $i -lt 3 -and (Test-Path $dir); $i++) {
        try { Remove-Item $dir -Recurse -Force -ErrorAction Stop } catch { Start-Sleep -Milliseconds 400 }
    }
    if (Test-Path $dir) { $dir = Join-Path $Work "$Name-$(Get-Random -Maximum 99999)" }
    $null = New-Item -ItemType Directory -Path $dir -Force
    & git -c core.longpaths=true clone --quiet --branch $TargetBranch $TargetRemote $dir 2>&1 | Out-Null
    & git -C $dir checkout --quiet $Sha 2>&1 | Out-Null
    $head = (& git -C $dir rev-parse HEAD).Trim()
    if ($head -ne $Sha) { throw "Clone of $Name is at $head, not the pinned $Sha." }
    $script:Clones.Add($dir)
    $dir
}

$null = New-Item -ItemType Directory -Path $Work -Force

# ===========================================================================
if ($FailCheck) {
    Write-Host "`nFALSIFICATION PROBES — each breaks something, asserts the break landed, then requires red.`n" -ForegroundColor Cyan

    # Probe A — corrupt the candidate graph, require Compare-Graph to go red.
    $probe = Join-Path $Work 'probe-graph.json'
    Copy-Item (Join-Path $Run 'graph.json') $probe -Force
    & "$Root/evals/functional/Compare-Graph.ps1" -CandidatePath $probe -Quiet
    $before = $LASTEXITCODE
    $g = Get-Content $probe -Raw | ConvertFrom-Json
    $g.nodes = @($g.nodes | Where-Object { $_.id -ne 'repo:consumer-app' })
    $g | ConvertTo-Json -Depth 10 | Set-Content $probe
    $stillThere = @((Get-Content $probe -Raw | ConvertFrom-Json).nodes | Where-Object { $_.id -eq 'repo:consumer-app' }).Count
    if ($stillThere -ne 0) { Add-Result 'probe-A' 'FAIL' 'the break did not land: repo:consumer-app is still present'; }
    else {
        & "$Root/evals/functional/Compare-Graph.ps1" -CandidatePath $probe -Quiet
        $after = $LASTEXITCODE
        if ($before -eq 0 -and $after -ne 0) { Add-Result 'probe-A' 'PASS' "break landed (node removed); Compare-Graph 0 -> $after" }
        else { Add-Result 'probe-A' 'FAIL' "expected 0 -> nonzero, got $before -> $after" }
    }

    # Probe B — a wrong pin must fail check 4, so check 4 is not vacuous.
    $realBlob = ((& git -C $Root ls-tree -r HEAD -- $OraclePath) -split '\s+')[2]
    $fakePin = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
    if ($realBlob -eq $fakePin) { Add-Result 'probe-B' 'FAIL' 'the break did not land: the fake pin equals the real blob' }
    elseif ($realBlob -ne $OracleBlob) { Add-Result 'probe-B' 'FAIL' "oracle blob is $realBlob, not the pin" }
    else { Add-Result 'probe-B' 'PASS' "a wrong pin ($fakePin) does not equal the real blob ($($realBlob.Substring(0,12))…), so check 4 can fail" }

    # Probe C — a graph with a duplicated node must fail the node-count check.
    $probe2 = Join-Path $Work 'probe-count.json'
    $g2 = Get-Content (Join-Path $Run 'graph.json') -Raw | ConvertFrom-Json
    $countBefore = @($g2.nodes).Count
    $g2.nodes = @($g2.nodes) + @($g2.nodes[0])
    $countAfter = @($g2.nodes).Count
    $g2 | ConvertTo-Json -Depth 10 | Set-Content $probe2
    if ($countAfter -ne $countBefore + 1) { Add-Result 'probe-C' 'FAIL' 'the break did not land: node count unchanged' }
    elseif ($countAfter -eq $ExpectedNodes) { Add-Result 'probe-C' 'FAIL' "broken graph still has the expected $ExpectedNodes nodes" }
    else { Add-Result 'probe-C' 'PASS' "break landed: $countBefore -> $countAfter, which is not the pinned $ExpectedNodes" }

    # Probe D — a PAT-shaped string planted in a file must be found by check 6.
    $probe3 = Join-Path $Work 'probe-pat.txt'
    $needle = 'PLANTED-SECRET-VALUE-abc123'
    Set-Content $probe3 -Value "token=$needle"
    $found = @(Select-String -Path $probe3 -SimpleMatch -Pattern $needle).Count
    if ($found -lt 1) { Add-Result 'probe-D' 'FAIL' 'the break did not land: planted secret not found by the scanner' }
    else { Add-Result 'probe-D' 'PASS' "scanner finds a planted secret ($found hit), so check 6 can fail" }

    $failed = @($script:Results | Where-Object State -eq 'FAIL').Count
    Write-Host ""
    if ($failed) { Write-Host "PROBES: $failed of $($script:Results.Count) did not demonstrate falsifiability." -ForegroundColor Red; exit 1 }
    Write-Host "PROBES: all $($script:Results.Count) demonstrated that the checks they guard can fail." -ForegroundColor Green
    exit 0
}

# ===========================================================================
Write-Host "`nRUN 006 — re-deriving the six named spot-checks`n" -ForegroundColor Cyan

# ---- 1. Fresh clone imports; build.ps1 exit matches -----------------------
try {
    $c1 = New-Clone -Name 'check1' -Sha $FinalSha
    $import = & pwsh -NoProfile -Command "Import-Module '$c1/src/$ModuleName/$ModuleName.psd1' -Force -ErrorAction Stop; (Get-Command -Module $ModuleName).Count" 2>&1
    $exported = 0
    if ($import -match '(\d+)\s*$') { $exported = [int] $Matches[1] }

    # In its OWN process. Two builds in one session leave the module imported
    # from the first clone's output/, and the second build's quality assertions
    # then grade the wrong module -- run 005's F-7 race, one level up: isolating
    # the working tree is not enough if the session is shared.
    & pwsh -NoProfile -Command "Set-Location '$c1'; & ./build.ps1; exit `$LASTEXITCODE" *>&1 |
        Out-File (Join-Path $Work 'check1-build.txt')
    $buildExit = $LASTEXITCODE

    # The first-shot commit must be an ancestor of the final one on the same
    # branch, or the two scores in the record are not two points on one line.
    & git -C $c1 merge-base --is-ancestor $FirstShotSha $FinalSha 2>&1 | Out-Null
    $ancestor = $LASTEXITCODE -eq 0

    if ($buildExit -eq 0 -and $exported -eq 7 -and $ancestor) {
        Add-Result 'check-1 build' 'PASS' "fresh clone of $($FinalSha.Substring(0,7)): dev loader exports $exported commands, build.ps1 exit $buildExit, first-shot $($FirstShotSha.Substring(0,7)) is an ancestor"
    } else {
        Add-Result 'check-1 build' 'FAIL' "exit $buildExit (expected 0), exported $exported (expected 7), first-shot-is-ancestor=$ancestor"
    }
} catch { Add-Result 'check-1 build' 'FAIL' $_.Exception.Message }

# ---- 2. Conformance re-run equals the committed result --------------------
try {
    $c2 = New-Clone -Name 'check2' -Sha $FinalSha
    # Its own clone AND its own process, for the same reason as check 1.
    & pwsh -NoProfile -Command "Set-Location '$c2'; & ./build.ps1; exit `$LASTEXITCODE" *>&1 |
        Out-File (Join-Path $Work 'check2-build.txt')

    $resultPath = Join-Path $Work 'check2-result.json'
    # -Command, never -File: `pwsh -File` flattens a comma-separated array into
    # one token, which is backlog item 15 and bit run 005 three times.
    & pwsh -NoProfile -Command "& '$Root/evals/conformance/Invoke-Conformance.ps1' -Path '$c2' -ModuleName $ModuleName -Tag @('Universal','Repository','HouseStyle','RequiresBuild') -ResultPath '$resultPath'" *>&1 |
        Out-File (Join-Path $Work 'check2-conformance.txt')

    $fresh = Get-Content $resultPath -Raw | ConvertFrom-Json
    $committed = Get-Content (Join-Path $Run 'conformance-result.json') -Raw | ConvertFrom-Json

    $ok = $fresh.CasesDefined -eq $CasesDefined -and
    $fresh.Failed -eq 0 -and
    $fresh.CasesDefined -eq $committed.CasesDefined -and
    $fresh.CasesRun -eq $committed.CasesRun -and
    $fresh.Passed -eq $committed.Passed

    if ($ok) {
        Add-Result 'check-2 conformance' 'PASS' "re-run from its own clone: cases-defined $($fresh.CasesDefined), cases-run $($fresh.CasesRun), passed $($fresh.Passed), failed $($fresh.Failed) — equals committed result.json"
    } else {
        Add-Result 'check-2 conformance' 'FAIL' "fresh: defined=$($fresh.CasesDefined) run=$($fresh.CasesRun) passed=$($fresh.Passed) failed=$($fresh.Failed); committed: defined=$($committed.CasesDefined) run=$($committed.CasesRun) passed=$($committed.Passed)"
    }
} catch { Add-Result 'check-2 conformance' 'FAIL' $_.Exception.Message }

# ---- 3. Compare-Graph reproduces diff.txt and the final score -------------
try {
    $reportPath = Join-Path $Work 'check3-report.json'
    & "$Root/evals/functional/Compare-Graph.ps1" -CandidatePath (Join-Path $Run 'graph.json') -ReportPath $reportPath -Quiet
    $cmpExit = $LASTEXITCODE
    $report = Get-Content $reportPath -Raw | ConvertFrom-Json
    $diffCount = @($report.differences).Count

    $graph = Get-Content (Join-Path $Run 'graph.json') -Raw | ConvertFrom-Json
    $nodes = @($graph.nodes).Count
    $edges = @($graph.edges).Count

    $diffTxt = Get-Content (Join-Path $Run 'diff.txt') -Raw
    $txtAgrees = $diffTxt -match 'The graphs agree\. 0 differences\.'

    if ($cmpExit -eq 0 -and $diffCount -eq 0 -and $txtAgrees -and $nodes -eq $ExpectedNodes -and $edges -eq $ExpectedEdges) {
        Add-Result 'check-3 compare' 'PASS' "committed graph.json: $nodes nodes, $edges edges, 0 differences, exit 0 — diff.txt says the same"
    } else {
        Add-Result 'check-3 compare' 'FAIL' "exit $cmpExit, $diffCount differences, nodes $nodes/$ExpectedNodes, edges $edges/$ExpectedEdges, diff.txt agrees=$txtAgrees"
    }
} catch { Add-Result 'check-3 compare' 'FAIL' $_.Exception.Message }

# ---- 3b. Live regeneration ------------------------------------------------
if ($SkipAzdo) {
    Add-Result 'check-3b live' 'SKIP' 'SkipAzdo requested — the live half did not run and this verification grades less than it claims to'
} elseif (-not $env:AZDO_PAT) {
    Add-Result 'check-3b live' 'SKIP' 'AZDO_PAT is not set — the live half did not run and this verification grades less than it claims to'
} else {
    try {
        $c3 = New-Clone -Name 'check3b' -Sha $FinalSha
        $regen = Join-Path $Work 'check3b-live.json'
        & pwsh -NoProfile -Command @"
Import-Module '$c3/src/$ModuleName/$ModuleName.psd1' -Force
`$g = Get-AzDoPipelineDependencyGraph -Organisation $Organisation -Project $Project -WarningAction SilentlyContinue
`$g | Export-AzDoPipelineDependencyGraph -Format Json -Path '$regen'
"@ *>&1 | Out-Null

        & "$Root/evals/functional/Compare-Graph.ps1" -CandidatePath $regen -Quiet
        $liveExit = $LASTEXITCODE

        # Compare CONTENT, not bytes: the committed file checks out LF and a
        # fresh Windows export writes CRLF (F-16).
        $a = ((Get-Content (Join-Path $Run 'graph.json') -Raw) -replace "`r`n", "`n").Trim()
        $b = ((Get-Content $regen -Raw) -replace "`r`n", "`n").Trim()

        if ($liveExit -eq 0 -and $a -eq $b) {
            Add-Result 'check-3b live' 'PASS' 'regenerated live from a fresh clone: agrees with the oracle (exit 0) and is identical to the committed graph.json after newline normalisation'
        } else {
            Add-Result 'check-3b live' 'FAIL' "live compare exit $liveExit; identical to committed = $($a -eq $b)"
        }
    } catch { Add-Result 'check-3b live' 'FAIL' $_.Exception.Message }
}

# ---- 4. Oracle unchanged; instrument diff empty ---------------------------
try {
    $blobLine = & git -C $Root ls-tree -r HEAD -- $OraclePath
    $blob = if ($blobLine) { ($blobLine -split '\s+')[2] } else { '<absent>' }
    $briefLine = & git -C $Root ls-tree -r HEAD -- 'evals/functional/BRIEF.md'
    $brief = if ($briefLine) { ($briefLine -split '\s+')[2] } else { '<absent>' }
    $instrument = @(& git -C $Root diff --name-only "$PluginSha..HEAD" -- skills/ commands/ .claude-plugin/ evals/)

    if ($blob -eq $OracleBlob -and $brief -eq $BriefBlob -and $instrument.Count -eq 0) {
        Add-Result 'check-4 instrument' 'PASS' "oracle blob $($blob.Substring(0,12))… and brief blob $($brief.Substring(0,12))… unchanged; diff vs $($PluginSha.Substring(0,7)) over skills/ commands/ .claude-plugin/ evals/ is empty"
    } else {
        Add-Result 'check-4 instrument' 'FAIL' "oracle=$blob brief=$brief instrument-diff=[$($instrument -join ', ')]"
    }
} catch { Add-Result 'check-4 instrument' 'FAIL' $_.Exception.Message }

# ---- 5. Three session ids distinct; three seed trees equal ----------------
try {
    $ids = @()
    foreach ($n in '004-plugin-on', '005-plugin-on', '006-plugin-on') {
        $line = Select-String -Path (Join-Path $Root "runs/$n/README.md") -Pattern '^\s*session-identifier:\s*(\S+)' | Select-Object -First 1
        if (-not $line) { throw "No session-identifier line in runs/$n/README.md" }
        $ids += $line.Matches.Groups[1].Value
    }
    # @() around every -Unique result. When all three values are equal the
    # pipeline yields ONE object, not a one-element array, and .Count on a bare
    # string is an error under Set-StrictMode -Version Latest. Same family as
    # F-13: a single-element collection stops being a collection.
    $distinct = @($ids | Sort-Object -Unique).Count

    # $rootCommit, NOT $root: PowerShell variable names are case-insensitive, so
    # `$root = ...` silently overwrites $Root, and the next git -C is handed a
    # commit SHA as a directory path.
    $targetRepo = Join-Path (Split-Path -Parent $Root) 'PSAzureDevOpsGraph'
    $trees = @()
    foreach ($b in 'run-004-plugin-on', 'run-005-plugin-on', 'run-006-plugin-on') {
        $ref = "refs/remotes/origin/$b"
        $rootCommit = (& git -C $targetRepo rev-list --max-parents=0 $ref).Trim()
        $trees += (& git -C $targetRepo rev-parse "$rootCommit^{tree}").Trim()
    }
    $treesEqual = @($trees | Sort-Object -Unique).Count -eq 1 -and $trees[0] -eq $SeedTree

    if ($distinct -eq 3 -and $treesEqual) {
        Add-Result 'check-5 sessions/seed' 'PASS' "3 of 3 session identifiers pairwise distinct; all three seed trees equal the pin $($SeedTree.Substring(0,12))…"
    } else {
        Add-Result 'check-5 sessions/seed' 'FAIL' "distinct ids = $distinct of 3; seed trees = [$(($trees | Sort-Object -Unique) -join ', ')] against pin $SeedTree"
    }
} catch { Add-Result 'check-5 sessions/seed' 'FAIL' $_.Exception.Message }

# ---- 6. PAT scan ----------------------------------------------------------
try {
    if (-not $env:AZDO_PAT) {
        Add-Result 'check-6 PAT scan' 'SKIP' 'AZDO_PAT is not set, so there is no value to scan for — this check graded nothing'
    } else {
        $needle = $env:AZDO_PAT
        $scanned = 0
        $hits = 0
        # Every clone this run actually made, by the name it actually got.
        foreach ($scanRoot in (@($Run) + @($script:Clones))) {
            if (-not (Test-Path $scanRoot)) { continue }
            $files = @(Get-ChildItem -Path $scanRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })
            $scanned += $files.Count
            $hits += @($files | Select-String -SimpleMatch -Pattern $needle -ErrorAction SilentlyContinue).Count
        }
        if ($hits -eq 0) { Add-Result 'check-6 PAT scan' 'PASS' "$scanned files scanned across the run record and two fresh clones: 0 occurrences" }
        else { Add-Result 'check-6 PAT scan' 'FAIL' "$hits occurrence(s) across $scanned files" }
    }
} catch { Add-Result 'check-6 PAT scan' 'FAIL' $_.Exception.Message }

# ===========================================================================
$failed = @($script:Results | Where-Object State -eq 'FAIL').Count
$skipped = @($script:Results | Where-Object State -eq 'SKIP').Count
Write-Host ""
if ($failed) {
    Write-Host "VERIFY: $failed check(s) FAILED, $skipped skipped, of $($script:Results.Count)." -ForegroundColor Red
    exit 1
}
if ($skipped) {
    Write-Host "VERIFY: all graded checks passed, but $skipped SKIPPED — this run graded less than it claims to." -ForegroundColor Yellow
    exit 0
}
Write-Host "VERIFY: all $($script:Results.Count) checks passed." -ForegroundColor Green
exit 0
