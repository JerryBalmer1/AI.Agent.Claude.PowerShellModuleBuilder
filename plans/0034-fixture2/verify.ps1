#Requires -Version 7.2
<#
.SYNOPSIS
    Verification for pass 0034 (the unannotated fixture, the tf skills, v1.1.0).
    Re-derives every claim the plan makes, from a FRESH CLONE at a pinned commit.

.DESCRIPTION
    This script exists so the operator can disprove the plan without reading it.
    It never parses plan.md and it never reads a number out of prose. Where the
    plan cites a committed report - sanitization.txt, mutations2.txt,
    readback2.txt - this script RE-RUNS the thing that produced the report and
    compares the verdict, rather than grepping the report for its own headline.

    Four checks reach the network:

      * check 5 asks the REMOTE for the tag, because a tag that exists only
        locally is exactly the failure that check is for;
      * checks 3, 4 and 6 talk to Azure DevOps and are PAT-gated. Without
        $env:AZDO_PAT they SKIP LOUDLY and the summary says so; they are never
        silently green.

    Nothing here writes to Azure DevOps, and nothing queues, runs or triggers a
    build. Check 6 asserts that, by asking.

.PARAMETER Sha
    The commit to verify. Defaults to HEAD of the repository this script sits in.

.PARAMETER SkipAzdo
    Skip the three PAT-gated checks even when a PAT is present. The skip is
    REPORTED, not silent.

.PARAMETER FailCheck
    Run the falsification probes instead of the checks. Each probe breaks the
    thing a check depends on, IN THE CLONE ONLY, and asserts the check goes red.
    A check that stays green under its own probe is reported as DOES NOT FIRE.

    Every probe asserts it actually changed its target before the check is
    re-run (evals/HARNESS.md hazards 4 and 6). A probe that changed nothing
    produces a green that proves nothing and reads exactly like a real one.
#>
[CmdletBinding()]
param(
    [string]$Sha,
    [switch]$SkipAzdo,
    [switch]$FailCheck
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$Tag = 'v1.1.0'
$Version = '1.1.0'
$PrevTag = 'v1.0.1'

# The fixture-2 freeze, from decision 0014. Pinned here rather than read from
# readback2.txt: a verify script that takes its expected values from the
# document it is checking has verified that document's internal consistency and
# nothing else.
$Fixture2Sha = [ordered]@{
    TfSiteCore = 'a228e78c247d2d4367303f303c4363d9906e06f2'
    TfSiteEdge = '1ae66c2712f799a69304cb4364e91e4d10d694c4'
    TfSiteOps  = 'fe27a34f7585b86b6fdbf12b609e17d4cb0f4b83'
}

# The fixture-1 freeze, from decision 0012 by way of the LEDGER's Pins section.
# This pass was told not to touch these and check 6 is how that is proved.
$Fixture1Sha = [ordered]@{
    TfFixtureShared  = '0af6ee33854bedb4147d0b13cc6db1311687775b'
    TfFixtureNetwork = '24f27be92e583b6dfc9208bca42f8ec0baf5004b'
    TfFixtureApp     = '44ea9338ff35aef328bfa8d51835fc32bea590dd'
}

# The oracle's own shape, stated so a silently shrinking fixture is a failure
# rather than a smaller green.
$Fixture2Nodes = 99
$Fixture2Edges = 88
$Fixture1Edges = 59

$TfSkills = @('tf-hcl-parse', 'tf-module-resolve', 'tf-graph-assembly')

if (-not $Sha) { $Sha = (git -C $RepoRoot rev-parse HEAD).Trim() }

$failures = [Collections.Generic.List[string]]::new()
$notes = [Collections.Generic.List[string]]::new()
$probes = [Collections.Generic.List[string]]::new()
$skipped = [Collections.Generic.List[string]]::new()
function Ok { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Bad { param($id, $m) Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:failures.Add("${id}: $m") }
function Note { param($m) Write-Host "  [note] $m" -ForegroundColor DarkGray; $script:notes.Add($m) }
function Skip { param($id, $m) Write-Host "  [skip] $m" -ForegroundColor Yellow; $script:skipped.Add("${id}: $m") }

# A probe's verdict is the change THIS check made to the failure list, never
# the list's total. A total is contaminated by every earlier check that failed
# for an unrelated reason, and reads as a probe firing when it did not.
$script:mark = 0
function Mark { $script:mark = $script:failures.Count }
function Fired {
    param($id, $desc)
    $went = $script:failures.Count -gt $script:mark
    if ($went) { Write-Host "  [fires] $desc" -ForegroundColor Green }
    else { Write-Host "  [DOES NOT FIRE] $desc" -ForegroundColor Red; $script:probes.Add("${id}: $desc") }
    while ($script:failures.Count -gt $script:mark) { $script:failures.RemoveAt($script:failures.Count - 1) }
}

# Short root on purpose. A long scratchpad path makes `git clone` fail with
# "cannot write keep file ... Filename too long" on Windows before it writes an
# object, which looks like a network fault and is not.
$work = Join-Path 'C:\Users\jlbal\AppData\Local\Temp' ("v0034-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
if (-not (Test-Path 'C:\Users\jlbal\AppData\Local\Temp')) {
    $work = Join-Path ([IO.Path]::GetTempPath()) ("v0034-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
}
$clone = Join-Path $work 'h'

$hasPat = -not [string]::IsNullOrWhiteSpace($env:AZDO_PAT)
$doAzdo = $hasPat -and -not $SkipAzdo

Write-Host 'Pass 0034 verification'
Write-Host "  repository : $RepoRoot"
Write-Host "  commit     : $Sha"
Write-Host "  clone      : $clone"
Write-Host "  azdo       : $(if ($doAzdo) { 'enabled' } elseif (-not $hasPat) { 'SKIPPED - AZDO_PAT not set' } else { 'SKIPPED - -SkipAzdo' })"
Write-Host "  mode       : $(if ($FailCheck) { 'FailCheck (falsification probes)' } else { 'checks' })"
Write-Host ''

New-Item -ItemType Directory -Path $work -Force | Out-Null
git -c core.longpaths=true clone -q $RepoRoot $clone
if ($LASTEXITCODE -ne 0) { throw 'clone failed' }
git -C $clone checkout -q $Sha
if ($LASTEXITCODE -ne 0) { throw "checkout $Sha failed" }

$tfDir = "$clone/evals/tf"
$oracle2 = "$tfDir/fixture2/expected-graph.json"
$oracle1 = "$tfDir/fixture/expected-graph.json"

function Invoke-InClone {
    <#
    .SYNOPSIS
        Run a script from the clone in a child pwsh, returning stdout+stderr and
        the exit code.
    .DESCRIPTION
        A child process, not dot-sourcing, because several of these scripts call
        `exit` and would take this one with them.
    #>
    param([Parameter(Mandatory)][string]$Path, [string[]]$Arguments = @())
    $out = & pwsh -NoProfile -File $Path @Arguments 2>&1 | Out-String
    [pscustomobject]@{ Output = $out; ExitCode = $LASTEXITCODE }
}

function Get-CloneOracle {
    param([Parameter(Mandatory)][string]$Path)
    (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json).graph
}

# ---------------------------------------------------------------------------
Write-Host '1. Both fixture suites, from the fresh clone.'
# ---------------------------------------------------------------------------
if ($FailCheck) {
    Mark
    # Break the fixture-2 oracle so it no longer agrees with itself: duplicate a
    # node id. The control must go non-zero.
    $before = Get-Content -LiteralPath $oracle2 -Raw
    $graph = $before | ConvertFrom-Json
    $extra = $graph.graph.nodes[2] | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $extra.label = 'probe-planted'
    $graph.graph.nodes = @($graph.graph.nodes) + @($extra)
    $after = $graph | ConvertTo-Json -Depth 30
    Set-Content -LiteralPath $oracle2 -Value $after -Encoding utf8NoBOM
    if ($after -eq $before) { Bad '1p' 'probe changed nothing' }
}

$suite1 = Invoke-Pester -Path "$tfDir/Compare-TfGraph.Tests.ps1" -PassThru -Output None
if ($suite1.FailedCount -eq 0 -and $suite1.PassedCount -eq 15) {
    Ok "fixture-1 comparator suite: $($suite1.PassedCount)/$($suite1.TotalCount)"
}
else {
    Bad '1a' "fixture-1 comparator suite: $($suite1.PassedCount) passed, $($suite1.FailedCount) failed (expected 15/15)"
}

$g1 = Get-CloneOracle -Path $oracle1
if (@($g1.edges).Count -eq $Fixture1Edges -and @($g1.nodes).Count -eq 78) {
    Ok "fixture-1 oracle unmoved: 78 nodes, $Fixture1Edges edges"
}
else {
    Bad '1b' "fixture-1 oracle moved: $(@($g1.nodes).Count) nodes, $(@($g1.edges).Count) edges (expected 78 / $Fixture1Edges)"
}

$control = & "$tfDir/Compare-TfGraph.ps1" -Expected $oracle2 -Actual $oracle2
if ($control.DifferenceCount -eq 0 -and $control.IsMatch) {
    Ok "fixture-2 control, oracle against itself: 0 differences over $($control.ExpectedNodeCount) nodes and $($control.ExpectedEdgeCount) edges"
}
else {
    Bad '1c' "fixture-2 control reported $($control.DifferenceCount) difference(s); it must be 0"
}

if ($control.ExpectedNodeCount -eq $Fixture2Nodes -and $control.ExpectedEdgeCount -eq $Fixture2Edges) {
    Ok "fixture-2 oracle is the pinned size: $Fixture2Nodes nodes, $Fixture2Edges edges"
}
else {
    Bad '1d' "fixture-2 oracle is $($control.ExpectedNodeCount) nodes / $($control.ExpectedEdgeCount) edges, pinned at $Fixture2Nodes / $Fixture2Edges"
}

# Structural self-check: the properties the plan claims of the oracle, re-derived.
$g2 = Get-CloneOracle -Path $oracle2
$ids = [Collections.Generic.HashSet[string]]::new()
$dupes = 0
foreach ($n in $g2.nodes) { if (-not $ids.Add([string]$n.id)) { $dupes++ } }
$badParent = @($g2.nodes | Where-Object { $null -ne $_.parentId -and -not $ids.Contains([string]$_.parentId) }).Count
$badEnd = 0
foreach ($e in $g2.edges) { if (-not $ids.Contains([string]$e.from)) { $badEnd++ }; if (-not $ids.Contains([string]$e.to)) { $badEnd++ } }
$depth = @($g2.nodes | Where-Object { $_.PSObject.Properties['depth'] }).Count
$badKind = @($g2.edges | Where-Object { $_.kind -notin @('sources', 'references', 'passes-to') }).Count
if (($dupes + $badParent + $badEnd + $depth + $badKind) -eq 0) {
    Ok 'fixture-2 oracle self-consistent: ids unique, parents and endpoints resolve, no depth, three edge kinds'
}
else {
    Bad '1e' "fixture-2 oracle: $dupes duplicate id(s), $badParent unresolvable parent(s), $badEnd unresolvable endpoint(s), $depth depth field(s), $badKind bad kind(s)"
}

if ($FailCheck) {
    Fired '1' 'a duplicated node id in the fixture-2 oracle turns the control red'
    Set-Content -LiteralPath $oracle2 -Value $before -Encoding utf8NoBOM -NoNewline
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '2. Mutations 2 and 6, regenerated here rather than read.'
# ---------------------------------------------------------------------------
# The seven mutations in the mutator's own order; 2 is extra-node and 6 is
# extra-edge. Named as well as numbered so a reordering cannot silently move
# what this check exercises.
$named = @(
    @{ N = 2; Mutation = 'extra-node'; Expect = 'ExtraNode' }
    @{ N = 6; Mutation = 'extra-edge'; Expect = 'ExtraEdge' }
)

if ($FailCheck) {
    Mark
    # Blind the comparator to extras: drop the two ExtraNode/ExtraEdge branches
    # by making their guards unreachable.
    $cmpPath = "$tfDir/Compare-TfGraph.ps1"
    $cmpBefore = Get-Content -LiteralPath $cmpPath -Raw
    $cmpAfter = $cmpBefore.Replace("Category = 'ExtraNode'", "Category = 'ExtraNodeDisabled'").Replace("Category = 'ExtraEdge'", "Category = 'ExtraEdgeDisabled'")
    if ($cmpAfter -eq $cmpBefore) { Bad '2p' 'probe changed nothing in Compare-TfGraph.ps1' }
    Set-Content -LiteralPath $cmpPath -Value $cmpAfter -Encoding utf8NoBOM -NoNewline
}

foreach ($case in $named) {
    $bad = & "$tfDir/Mutate-TfGraph.ps1" -Path $oracle2 -Mutation $case.Mutation -Fixture fixture2
    $badText = $bad | ConvertTo-Json -Depth 30 -Compress
    $oracleText = (Get-Content -LiteralPath $oracle2 -Raw | ConvertFrom-Json) | ConvertTo-Json -Depth 30 -Compress
    if ($badText -eq $oracleText) {
        Bad "2-$($case.N)a" "mutation $($case.N) ($($case.Mutation)) changed nothing; its detection would prove nothing"
        continue
    }
    $result = & "$tfDir/Compare-TfGraph.ps1" -Expected $oracle2 -ActualObject $bad
    $categories = @($result.Differences | ForEach-Object { $_.Category } | Sort-Object -Unique)
    if ($result.DifferenceCount -ge 1 -and $case.Expect -in $categories) {
        Ok "mutation $($case.N) ($($case.Mutation)) detected as $($case.Expect), $($result.DifferenceCount) difference(s)"
    }
    else {
        Bad "2-$($case.N)b" "mutation $($case.N) ($($case.Mutation)) not detected as $($case.Expect); got [$($categories -join ', ')]"
    }
}

if ($FailCheck) {
    Fired '2' 'a comparator blind to extras fails to detect mutations 2 and 6'
    Set-Content -LiteralPath "$tfDir/Compare-TfGraph.ps1" -Value $cmpBefore -Encoding utf8NoBOM -NoNewline
}

# The whole falsification, re-run, so the plan's 7/7 is re-derived and not read.
$fals = Invoke-InClone -Path "$tfDir/Invoke-TfOracleFalsification.ps1" -Arguments @('-Fixture', 'fixture2')
if ($fals.ExitCode -eq 0 -and $fals.Output -match 'DETECTED: 7 / 7' -and $fals.Output -match 'CONTROL GREEN') {
    Ok 'fixture-2 falsification re-run here: control green, DETECTED 7 / 7'
}
else {
    Bad '2c' "fixture-2 falsification re-run: exit $($fals.ExitCode), and the report does not carry both 'CONTROL GREEN' and 'DETECTED: 7 / 7'"
}

$fals1 = Invoke-InClone -Path "$tfDir/Invoke-TfOracleFalsification.ps1" -Arguments @('-Fixture', 'fixture1')
if ($fals1.ExitCode -eq 0 -and $fals1.Output -match 'DETECTED: 7 / 7') {
    Ok 'fixture-1 falsification still 7 / 7 after the parameterization'
}
else {
    Bad '2d' "fixture-1 falsification: exit $($fals1.ExitCode); the parameterization must not have weakened it"
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '3. Sanitization, against a fresh clone of a fixture-2 repository.'
# ---------------------------------------------------------------------------
# Local first, so the gate is exercised even without a PAT.
$sanLocal = Invoke-InClone -Path "$tfDir/Test-FixtureSanitization.ps1" -Arguments @('-Fixture', 'fixture2', '-FailCheck')
if ($sanLocal.ExitCode -eq 0 -and $sanLocal.Output -match 'FIXTURE2 SANITIZATION: clean' -and $sanLocal.Output -match 'FALSIFICATION PASSED') {
    Ok 'fixture-2 source scans clean, and the scanner was shown to catch a planted comment'
}
else {
    Bad '3a' "fixture-2 source scan: exit $($sanLocal.ExitCode); expected a clean verdict and a passing falsification"
}

# The discriminating control: the same scanner over fixture 1 must find the
# annotations pass 0033 found by hand. A scanner that says clean about
# everything is not a gate.
$sanF1 = Invoke-InClone -Path "$tfDir/Test-FixtureSanitization.ps1" -Arguments @('-Fixture', 'fixture1')
if ($sanF1.ExitCode -eq 1 -and $sanF1.Output -match 'FIXTURE1 SANITIZATION: \d+ finding\(s\)') {
    $n = [regex]::Match($sanF1.Output, 'FIXTURE1 SANITIZATION: (\d+) finding').Groups[1].Value
    Ok "control: the same scanner reports $n finding(s) against fixture 1, which is what makes 'clean' mean something"
}
else {
    Bad '3b' "control: the scanner did not report findings against the annotated fixture 1 (exit $($sanF1.ExitCode))"
}

if ($doAzdo) {
    $cloneWork = Join-Path $work 'azdo'
    New-Item -ItemType Directory -Path $cloneWork -Force | Out-Null
    $bytes = [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")
    $auth = 'Authorization: Basic ' + [Convert]::ToBase64String($bytes)
    $repoName = 'TfSiteOps'
    & git -c "http.extraHeader=$auth" clone --quiet "https://dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/$repoName" "$cloneWork/$repoName" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Bad '3c' "clone of $repoName failed with exit $LASTEXITCODE"
    }
    else {
        $tip = (& git -C "$cloneWork/$repoName" rev-parse HEAD).Trim()
        if ($tip -eq $Fixture2Sha[$repoName]) { Ok "$repoName is at its frozen SHA $tip" }
        else { Bad '3d' "$repoName is at $tip; decision 0014 freezes it at $($Fixture2Sha[$repoName])" }

        $message = (& git -C "$cloneWork/$repoName" log -1 --pretty=%B).Trim()

        if ($FailCheck) {
            Mark
            $plantPath = "$cloneWork/$repoName/main.tf"
            $planted = '# Case 6, the absence case: a graph that invents a reference for this is wrong.'
            $plantBefore = [IO.File]::ReadAllText($plantPath)
            [IO.File]::WriteAllText($plantPath, $planted + "`n" + $plantBefore)
            if ([IO.File]::ReadAllText($plantPath) -eq $plantBefore) { Bad '3p' 'probe changed nothing in the AzDO clone' }
        }

        $sanClone = Invoke-InClone -Path "$tfDir/Test-FixtureSanitization.ps1" -Arguments @('-Fixture', 'fixture2', '-FixtureRoot', $cloneWork, '-Label', 'CLONE')
        if ($sanClone.ExitCode -eq 0 -and $sanClone.Output -match 'CLONE SANITIZATION: clean') {
            Ok "the pushed $repoName scans clean, commit message included"
        }
        else {
            Bad '3e' "the pushed $repoName did not scan clean (exit $($sanClone.ExitCode))"
        }

        if ($FailCheck) {
            Fired '3' 'a case-naming comment planted in the pushed clone is caught by the scanner'
            [IO.File]::WriteAllText($plantPath, $plantBefore)
        }

        # The commit message is fixture content per decision 0014, so it is
        # checked as content and not merely as a string that exists.
        if ($message -notmatch '(?i)\b(fixture|oracle|case|graph|harness|scoring)\b') {
            Ok "the pushed commit message names none of the banned vocabulary: `"$message`""
        }
        else {
            Bad '3f' "the pushed commit message leaks harness vocabulary: `"$message`""
        }
    }
}
else {
    Skip '3' 'the AzDO half of check 3 (fresh clone of TfSiteOps, its frozen SHA, its commit message)'
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '4. Read-back, re-derived for one fixture-2 repository.'
# ---------------------------------------------------------------------------
if ($doAzdo) {
    $readback = Invoke-InClone -Path "$tfDir/Test-TfFixtureReadBack.ps1" -Arguments @('-Fixture', 'fixture2')
    if ($readback.ExitCode -eq 0 -and $readback.Output -match 'BYTE-IDENTICAL') {
        $compared = [regex]::Match($readback.Output, '(\d+) file\(s\) compared').Groups[1].Value
        Ok "read-back re-derived from the clone: BYTE-IDENTICAL over $compared files"
    }
    else {
        Bad '4a' "read-back re-derived: exit $($readback.ExitCode); expected BYTE-IDENTICAL"
    }

    foreach ($name in $Fixture2Sha.Keys) {
        if ($readback.Output -match [regex]::Escape($Fixture2Sha[$name])) {
            Ok "$name read back at its frozen SHA"
        }
        else {
            Bad '4b' "$name was not read back at $($Fixture2Sha[$name]); the freeze has moved"
        }
    }
}
else {
    Skip '4' 'the read-back re-derivation (needs AZDO_PAT)'
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host "5. What the release actually changed, $PrevTag..$Tag."
# ---------------------------------------------------------------------------
$remoteTag = & git -C $clone ls-remote --tags $RepoRoot "$Tag*" 2>&1
if ([string]::IsNullOrWhiteSpace(($remoteTag | Out-String))) {
    Bad '5a' "$Tag is not on the remote"
}
else {
    Ok "$Tag is on the remote"
}

$manifest = Get-Content -LiteralPath "$clone/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json
$market = Get-Content -LiteralPath "$clone/.claude-plugin/marketplace.json" -Raw | ConvertFrom-Json
$three = @($manifest.version, $market.metadata.version, $market.plugins[0].version)
if (@($three | Sort-Object -Unique).Count -eq 1 -and $three[0] -eq $Version) {
    Ok "all three version strings are $Version (LEDGER item 28)"
}
else {
    Bad '5b' "the three version strings are [$($three -join ', ')]; all must be $Version"
}

$tagExists = (& git -C $clone tag -l $Tag).Trim()
if ($tagExists -ne $Tag) {
    Bad '5c' "$Tag is not in the clone; the diff checks below cannot run"
}
else {
    $commandsDiff = & git -C $clone diff --name-only "$PrevTag..$Tag" -- commands/
    if ([string]::IsNullOrWhiteSpace(($commandsDiff | Out-String))) {
        Ok "git diff $PrevTag..$Tag -- commands/ is empty"
    }
    else {
        Bad '5d' "commands/ changed between $PrevTag and $Tag: $($commandsDiff -join ', ')"
    }

    $skillsDiff = @(& git -C $clone diff --name-only "$PrevTag..$Tag" -- skills/)
    $expectedNew = @($TfSkills | ForEach-Object { "skills/$_/SKILL.md" })
    $expectedEdited = @('skills/azdo-rest/SKILL.md', 'skills/powershell-module-scaffold/SKILL.md')
    $allowed = $expectedNew + $expectedEdited
    $unexpected = @($skillsDiff | Where-Object { $_ -notin $allowed })
    $missing = @($allowed | Where-Object { $_ -notin $skillsDiff })
    if ($unexpected.Count -eq 0 -and $missing.Count -eq 0) {
        Ok "skills/ diff is exactly the three new tf-* skills and the two edited files"
    }
    else {
        Bad '5e' "skills/ diff unexpected: [$($unexpected -join ', ')]; missing: [$($missing -join ', ')]"
    }

    # The two hardening lines are checked as CONTENT of the diff, not as the
    # existence of a changed file. A file can change for any reason.
    $hardening = & git -C $clone diff "$PrevTag..$Tag" -- skills/azdo-rest/SKILL.md skills/powershell-module-scaffold/SKILL.md | Out-String
    $addedOnly = ($hardening -split "`n" | Where-Object { $_ -match '^\+' }) -join "`n"
    $removed = @($hardening -split "`n" | Where-Object { $_ -match '^-[^-]' })
    if ($addedOnly -match 'PSObject\.Properties\[' -and $addedOnly -match 'StrictMode') {
        Ok 'the StrictMode absent-property line landed in an existing skill'
    }
    else {
        Bad '5f' 'the StrictMode absent-property line is not in the diff'
    }
    if ($addedOnly -match 'IsPathRooted' -and $addedOnly -match 'Join-Path') {
        Ok 'the Join-Path already-rooted line landed in an existing skill'
    }
    else {
        Bad '5g' 'the Join-Path already-rooted line is not in the diff'
    }
    if ($removed.Count -eq 0) {
        Ok 'the two edited skills gained lines and lost none'
    }
    else {
        Note "the two edited skills also removed $($removed.Count) line(s); read the diff before accepting"
    }
}

$skillDirs = @(Get-ChildItem "$clone/skills" -Directory | Select-Object -ExpandProperty Name)
$tfDirs = @($skillDirs | Where-Object { $_ -like 'tf-*' })
if (@($TfSkills | Where-Object { $_ -notin $tfDirs }).Count -eq 0) {
    Ok "the tf skill batch is present: $($tfDirs -join ', ')"
}
else {
    Bad '5h' "expected the tf skills [$($TfSkills -join ', ')]; found [$($tfDirs -join ', ')]"
}
if ($skillDirs.Count -eq 17) { Ok 'seventeen skill directories, as the README and SECURITY.md now say' }
else { Bad '5i' "$($skillDirs.Count) skill directories; the documents say seventeen" }

$changelog = Get-Content -LiteralPath "$clone/CHANGELOG.md" -Raw
if ($changelog -match '(?m)^## 1\.1\.0') { Ok 'CHANGELOG carries a 1.1.0 section' }
else { Bad '5j' 'CHANGELOG has no 1.1.0 section' }
if ($changelog -match '(?i)commands are unchanged|Your commands are unchanged') { Ok 'the CHANGELOG says the commands are unchanged' }
else { Bad '5k' 'the CHANGELOG does not state that the commands are unchanged' }

$readme = Get-Content -LiteralPath "$clone/README.md" -Raw
if ($readme -match [regex]::Escape("@$Tag")) { Ok "README install pin is @$Tag" }
else { Bad '5l' "README install pin is not @$Tag" }

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '6. Fixture 1 untouched, and nothing queued anywhere.'
# ---------------------------------------------------------------------------
if ($doAzdo) {
    . "$tfDir/TfAzdoClient.ps1"
    $base = Get-TfAzdoBaseUri
    $repos = Invoke-TfAzdoJson -Uri "$base/git/repositories?api-version=7.1"

    foreach ($name in $Fixture1Sha.Keys) {
        $repo = @($repos.value | Where-Object { $_.name -eq $name }) | Select-Object -First 1
        if (-not $repo) { Bad '6a' "$name is not in the project"; continue }
        $refs = Invoke-TfAzdoJson -Uri "$base/git/repositories/$($repo.id)/refs?filter=heads/&api-version=7.1"
        $tip = @($refs.value)[0].objectId
        if ($tip -eq $Fixture1Sha[$name]) { Ok "$name still at its decision-0012 SHA" }
        else { Bad '6b' "$name is at $tip; decision 0012 froze it at $($Fixture1Sha[$name])" }
    }

    $builds = Invoke-TfAzdoJson -Uri "$base/build/builds?api-version=7.1&`$top=50"
    if (@($builds.value).Count -eq 0) { Ok 'zero builds in ClaudeTestingTerraform, of any status' }
    else { Bad '6c' "$(@($builds.value).Count) build(s) exist in ClaudeTestingTerraform; this pass must have queued none" }

    $defs = Invoke-TfAzdoJson -Uri "$base/build/definitions?api-version=7.1"
    $defNames = @($defs.value | ForEach-Object { $_.name } | Sort-Object)
    $fixture2Defs = @($defNames | Where-Object { $_ -like 'TfSite*' })
    if ($fixture2Defs.Count -eq 0) { Ok "no pipeline definitions were created for fixture 2 (project holds $($defNames.Count), all fixture 1's)" }
    else { Bad '6d' "fixture-2 pipeline definitions exist: $($fixture2Defs -join ', ')" }

    # The harness copy of fixture 1 must also be untouched by this pass.
    $f1Diff = & git -C $clone diff --name-only "$PrevTag..$Sha" -- evals/tf/fixture/
    if ([string]::IsNullOrWhiteSpace(($f1Diff | Out-String))) {
        Ok "evals/tf/fixture/ unchanged since $PrevTag"
    }
    else {
        Bad '6e' "evals/tf/fixture/ changed since $PrevTag: $($f1Diff -join ', ')"
    }
}
else {
    Skip '6' 'the AzDO half of check 6 (fixture-1 SHAs, build list, pipeline definitions)'
    $f1Diff = & git -C $clone diff --name-only "$PrevTag..$Sha" -- evals/tf/fixture/
    if ([string]::IsNullOrWhiteSpace(($f1Diff | Out-String))) {
        Ok "evals/tf/fixture/ unchanged since $PrevTag (the half that needs no PAT)"
    }
    else {
        Bad '6e' "evals/tf/fixture/ changed since $PrevTag: $($f1Diff -join ', ')"
    }
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '7. The acceptance test, from the clone.'
# ---------------------------------------------------------------------------
$accept = Invoke-Pester -Path "$clone/plans/0034-fixture2/accept.Tests.ps1" -PassThru -Output None
if ($accept.FailedCount -eq 0) {
    Ok "acceptance: $($accept.PassedCount)/$($accept.TotalCount) green"
}
else {
    foreach ($t in ($accept.Tests | Where-Object Result -ne 'Passed')) { Bad '7' "acceptance failed: $($t.Name)" }
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '--- summary ---'
foreach ($s in $skipped) { Write-Host "  SKIPPED  $s" -ForegroundColor Yellow }
foreach ($n in $notes) { Write-Host "  note     $n" -ForegroundColor DarkGray }

Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

if ($FailCheck) {
    if ($probes.Count -eq 0) {
        Write-Host 'ALL PROBES FIRED - every check falsified was shown to be capable of failing.' -ForegroundColor Green
        exit 0
    }
    Write-Host "$($probes.Count) PROBE(S) DID NOT FIRE:" -ForegroundColor Red
    foreach ($p in $probes) { Write-Host "  $p" -ForegroundColor Red }
    exit 1
}

if ($failures.Count -eq 0) {
    if ($skipped.Count -gt 0) {
        Write-Host "VERIFIED, with $($skipped.Count) check(s) SKIPPED and named above." -ForegroundColor Yellow
    }
    else {
        Write-Host 'VERIFIED - every check re-derived and agreed.' -ForegroundColor Green
    }
    exit 0
}

Write-Host "$($failures.Count) CHECK(S) DISAGREED:" -ForegroundColor Red
foreach ($f in $failures) { Write-Host "  $f" -ForegroundColor Red }
exit 1
