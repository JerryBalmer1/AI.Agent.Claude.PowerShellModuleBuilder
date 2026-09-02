#Requires -Version 7.2
<#
.SYNOPSIS
    Verification for pass 0035 (the duplicate-id repair and the tf-003 kit).
    Re-derives every claim the plan makes, from a FRESH CLONE at a pinned
    commit.

.DESCRIPTION
    This script exists so the operator can disprove the plan without reading
    it. It never parses plan.md and it never reads a number out of prose.
    Where the plan cites a committed report - mutation8.txt, suites.txt,
    kit-sanitization.txt, reset-falsification.txt - this script RE-RUNS the
    thing that produced the report and compares the verdict, rather than
    grepping the report for its own headline.

    NOTHING HERE REACHES THE NETWORK, and that is a fact about this pass
    rather than a shortcut. Pass 0035 touched no fixture file and no Azure
    DevOps object; check 6 proves the first by diffing, and there is no second
    to prove, because nothing was pushed anywhere to prove it about. A PAT is
    neither used nor needed.

.PARAMETER Sha
    The commit to verify. Defaults to HEAD of the repository this script sits
    in.

.PARAMETER FailCheck
    Run the falsification probes instead of the checks. Each probe breaks the
    thing a check depends on, IN THE CLONE ONLY, and asserts the check goes
    red. A check that stays green under its own probe is reported as DOES NOT
    FIRE.

    Every probe asserts it actually changed its target before the check is
    re-run (evals/HARNESS.md hazards 4 and 6). A probe that changed nothing
    produces a green that proves nothing and reads exactly like a real one -
    which is how pass 0034's duplicate-id probe was found, and this whole pass
    followed from it.
#>
[CmdletBinding()]
param(
    [string]$Sha,
    [switch]$FailCheck
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$Tag = 'v1.1.0'

# The pins, stated here rather than read from LEDGER.md: a verify script that
# takes its expected values from the document it is checking has verified that
# document's internal consistency and nothing else.
$BriefBlob = 'dc25fcd0d1e4d5651073240374ee19c28499c70e'
$SeedTree = '040ab2503aa7ccd5d67500d2e1d9983818807d86'

# The two suites' pinned sizes, and the oracles' pinned shapes. A silently
# shrinking instrument must be a failure rather than a smaller green.
$Fixture1Tests = 15
$Fixture1Nodes = 78
$Fixture1Edges = 59
$Fixture2Nodes = 99
$Fixture2Edges = 88
$Fixture1SanitizationFindings = 94

if (-not $Sha) { $Sha = (git -C $RepoRoot rev-parse HEAD).Trim() }

$failures = [Collections.Generic.List[string]]::new()
$notes = [Collections.Generic.List[string]]::new()
$probes = [Collections.Generic.List[string]]::new()
function Ok { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Bad { param($id, $m) Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:failures.Add("${id}: $m") }
function Note { param($m) Write-Host "  [note] $m" -ForegroundColor DarkGray; $script:notes.Add($m) }

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
$work = Join-Path 'C:\Users\jlbal\AppData\Local\Temp' ("v0035-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
if (-not (Test-Path 'C:\Users\jlbal\AppData\Local\Temp')) {
    $work = Join-Path ([IO.Path]::GetTempPath()) ("v0035-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
}
$clone = Join-Path $work 'h'

Write-Host 'Pass 0035 verification'
Write-Host "  repository : $RepoRoot"
Write-Host "  commit     : $Sha"
Write-Host "  clone      : $clone"
Write-Host "  network    : not used, and not needed - see the description"
Write-Host "  mode       : $(if ($FailCheck) { 'FailCheck (falsification probes)' } else { 'checks' })"
Write-Host ''

New-Item -ItemType Directory -Path $work -Force | Out-Null
git -c core.longpaths=true clone -q $RepoRoot $clone
if ($LASTEXITCODE -ne 0) { throw 'clone failed' }
git -C $clone checkout -q $Sha
if ($LASTEXITCODE -ne 0) { throw "checkout $Sha failed" }

$tfDir = "$clone/evals/tf"
$oracle1 = "$tfDir/fixture/expected-graph.json"
$oracle2 = "$tfDir/fixture2/expected-graph.json"

function Invoke-InClone {
    <#
    .SYNOPSIS
        Run a script from the clone in a child pwsh, returning stdout+stderr
        and the exit code.
    .DESCRIPTION
        A child process, not dot-sourcing, because several of these scripts
        call `exit` and would take this one with them.
    #>
    param([Parameter(Mandatory)][string]$Path, [string[]]$Arguments = @())
    $out = & pwsh -NoProfile -File $Path @Arguments 2>&1 | Out-String
    [pscustomobject]@{ Output = $out; ExitCode = $LASTEXITCODE }
}

function Invoke-CommandInClone {
    <#
    .SYNOPSIS
        The same, for a call that passes an ARRAY parameter.
    .DESCRIPTION
        `pwsh -File` flattens `-Path a,b` into the single token "a,b" - LEDGER
        item 15, and it cost this pass a confusing error the first time
        -RuleSet Kit was run. -Command with a real @(...) is the fix.
    #>
    param([Parameter(Mandatory)][string]$Command)
    $out = & pwsh -NoProfile -Command $Command 2>&1 | Out-String
    [pscustomobject]@{ Output = $out; ExitCode = $LASTEXITCODE }
}

# ---------------------------------------------------------------------------
Write-Host '1. Mutation 8, regenerated here rather than read.'
# ---------------------------------------------------------------------------
if ($FailCheck) {
    Mark
    # Blind Stage 0: rename the category so the finding is never raised. This
    # is the whole repair, disabled.
    $cmpPath = "$tfDir/Compare-TfGraph.ps1"
    $cmpBefore = Get-Content -LiteralPath $cmpPath -Raw
    $cmpAfter = $cmpBefore.Replace("Category = 'DuplicateId'", "Category = 'DuplicateIdDisabled'")
    if ($cmpAfter -eq $cmpBefore) { Bad '1p' 'probe changed nothing in Compare-TfGraph.ps1' }
    Set-Content -LiteralPath $cmpPath -Value $cmpAfter -Encoding utf8NoBOM -NoNewline
}

$m8 = Invoke-InClone -Path "$tfDir/Invoke-TfDuplicateIdFalsification.ps1" -Arguments @('-Fixture', 'fixture2')
$producerSide = $m8.Output -match 'DUPLICATE-ID: detected on producer side(?! - NOT PROVEN)'
$oracleSide = $m8.Output -match 'DUPLICATE-ID: detected on oracle side(?! - NOT PROVEN)'
if ($m8.ExitCode -eq 0 -and $producerSide -and $oracleSide) {
    Ok 'mutation 8 detected in BOTH directions, regenerated from the clone'
}
else {
    Bad '1a' "mutation 8: exit $($m8.ExitCode); producer side $producerSide, oracle side $oracleSide"
}

# The controls inside that report are the reason it means anything: a repair
# that made every document differ from itself would detect both directions.
if ($m8.Output -match 'CONTROL GREEN: fixture1' -and $m8.Output -match 'CONTROL GREEN: fixture2') {
    Ok 'both clean oracles still match themselves, before the mutation'
}
else {
    Bad '1b' 'the clean-oracle controls in the mutation-8 report are not green'
}

# Detected as its OWN mechanism, checked here rather than trusted from the
# report: a comparator that reported a duplicate as an ExtraNode would produce
# a detection and name the wrong defect.
$bad = & "$tfDir/Mutate-TfGraph.ps1" -Path $oracle2 -Mutation 'duplicate-id' -Fixture fixture2
$result = & "$tfDir/Compare-TfGraph.ps1" -Expected $oracle2 -ActualObject $bad
$categories = @($result.Differences | ForEach-Object { $_.Category } | Sort-Object -Unique)
if ((-not $result.IsMatch) -and $categories.Count -eq 1 -and $categories[0] -eq 'DuplicateId' -and
    $result.ActualDuplicateIdCount -eq 1 -and $result.ExpectedDuplicateIdCount -eq 0) {
    Ok "a duplicated id is one DuplicateId difference on the actual side, and nothing else"
}
else {
    Bad '1c' "duplicate-id came back as [$($categories -join ', ')], IsMatch=$($result.IsMatch)"
}

if ($FailCheck) {
    Fired '1' 'a comparator blind to duplicate ids fails mutation 8 in both directions'
    Set-Content -LiteralPath "$tfDir/Compare-TfGraph.ps1" -Value $cmpBefore -Encoding utf8NoBOM -NoNewline
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '2. Both suites, and mutations 1-7 on BOTH fixtures.'
# ---------------------------------------------------------------------------
if ($FailCheck) {
    Mark
    # Add a test to the fixture-1 suite. The suite still passes; what must go
    # red is the PINNED COUNT, which is the thing standing between this pass
    # and a repair that quietly changed the instrument.
    $suitePath = "$tfDir/Compare-TfGraph.Tests.ps1"
    $suiteBefore = Get-Content -LiteralPath $suitePath -Raw
    $suiteAfter = $suiteBefore + "`nDescribe 'probe' { It 'is an extra test' { 1 | Should-Be 1 } }`n"
    Set-Content -LiteralPath $suitePath -Value $suiteAfter -Encoding utf8NoBOM -NoNewline
    if ((Get-Content -LiteralPath $suitePath -Raw) -eq $suiteBefore) { Bad '2p' 'probe changed nothing in the suite' }
}

$suites = Invoke-InClone -Path "$tfDir/Invoke-TfSuite.ps1"
if ($suites.ExitCode -eq 0 -and
    $suites.Output -match "FIXTURE1: $Fixture1Tests passed, 0 failed" -and
    $suites.Output -match 'FIXTURE2: \d+ passed, 0 failed') {
    Ok "both suites green from the clone, fixture 1 at its pinned $Fixture1Tests"
}
else {
    $f1 = [regex]::Match($suites.Output, 'FIXTURE1: [^\r\n]*').Value
    $f2 = [regex]::Match($suites.Output, 'FIXTURE2: [^\r\n]*').Value
    Bad '2a' "suites: exit $($suites.ExitCode); '$f1' / '$f2'"
}

if ($FailCheck) {
    Fired '2' 'a suite that gained a test is reported as a failure, not as a bigger green'
    Set-Content -LiteralPath "$tfDir/Compare-TfGraph.Tests.ps1" -Value $suiteBefore -Encoding utf8NoBOM -NoNewline
}

foreach ($fixture in 'fixture1', 'fixture2') {
    $fals = Invoke-InClone -Path "$tfDir/Invoke-TfOracleFalsification.ps1" -Arguments @('-Fixture', $fixture)
    if ($fals.ExitCode -eq 0 -and $fals.Output -match 'DETECTED: 7 / 7' -and $fals.Output -match 'CONTROL GREEN') {
        Ok "$fixture mutations 1-7 still 7 / 7, control green"
    }
    else {
        Bad '2b' "$fixture falsification: exit $($fals.ExitCode); expected CONTROL GREEN and DETECTED: 7 / 7"
    }
}

# The oracles themselves have not moved. The repair is about the comparator.
foreach ($pair in @(
        @{ Name = 'fixture1'; Path = $oracle1; Nodes = $Fixture1Nodes; Edges = $Fixture1Edges }
        @{ Name = 'fixture2'; Path = $oracle2; Nodes = $Fixture2Nodes; Edges = $Fixture2Edges })) {
    $g = (Get-Content -LiteralPath $pair.Path -Raw | ConvertFrom-Json).graph
    $ids = @($g.nodes | ForEach-Object { [string]$_.id })
    $unique = @($ids | Sort-Object -Unique).Count
    if (@($g.nodes).Count -eq $pair.Nodes -and @($g.edges).Count -eq $pair.Edges -and $unique -eq $pair.Nodes) {
        Ok "$($pair.Name) oracle unmoved: $($pair.Nodes) nodes (all ids unique), $($pair.Edges) edges"
    }
    else {
        Bad '2c' "$($pair.Name) oracle: $(@($g.nodes).Count) nodes / $unique unique / $(@($g.edges).Count) edges"
    }
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '3. The reset guard, re-fired from the clone.'
# ---------------------------------------------------------------------------
if ($FailCheck) {
    Mark
    # Make the guard permissive: a raw prefix test on the unnormalised string,
    # which accepts a path that reaches back OUT through an allowed prefix.
    # That is the exact accident the guard exists to prevent, and it is the one
    # a naive implementation gets wrong.
    $resetPath = "$tfDir/Reset-TfTarget.ps1"
    $resetBefore = Get-Content -LiteralPath $resetPath -Raw
    $resetAfter = $resetBefore.Replace(
        '$full.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)',
        '(Join-Path $RepoRoot $Candidate).Replace("/", [IO.Path]::DirectorySeparatorChar).StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)')
    if ($resetAfter -eq $resetBefore) { Bad '3p' 'probe changed nothing in Reset-TfTarget.ps1' }
    Set-Content -LiteralPath $resetPath -Value $resetAfter -Encoding utf8NoBOM -NoNewline
}

$reset = Invoke-InClone -Path "$tfDir/Reset-TfTarget.ps1" -Arguments @('-FailCheck')
$refusals = @([regex]::Matches($reset.Output, 'REFUSED: outside scratch')).Count
if ($reset.ExitCode -eq 0 -and $reset.Output -match 'GUARD FALSIFIED' -and $refusals -ge 6) {
    Ok "the reset guard refused $refusals destinations and accepted a legitimate one"
}
else {
    Bad '3a' "reset guard: exit $($reset.ExitCode), $refusals refusal(s); expected GUARD FALSIFIED with at least 6"
}

if ($FailCheck) {
    Fired '3' 'a guard that tests the raw string lets a path traverse out of scratch/runs'
    Set-Content -LiteralPath "$tfDir/Reset-TfTarget.ps1" -Value $resetBefore -Encoding utf8NoBOM -NoNewline
}

# The happy-path tree, against the pin. Materialised INSIDE THE CLONE, so this
# never writes into the real repository's scratch/.
$dest = 'scratch/runs/0035-verify'
$happy = Invoke-CommandInClone -Command "Set-Location '$clone'; & './evals/tf/Reset-TfTarget.ps1' -Destination '$dest' -Force"
$producedTree = [regex]::Match($happy.Output, 'tree\s+:\s+([0-9a-f]{40})').Groups[1].Value
if ($producedTree -eq $SeedTree) {
    Ok "the reset produces the pinned seed tree $SeedTree"
}
else {
    Bad '3b' "the reset produced tree '$producedTree'; the pin is $SeedTree"
}

# And the same tree is what the repository stores, which is the second,
# independent derivation the plan claims.
$storedTree = (& git -C $clone rev-parse "${Sha}:evals/tf/seed").Trim()
if ($storedTree -eq $SeedTree) { Ok "git rev-parse ${Sha}:evals/tf/seed agrees: $storedTree" }
else { Bad '3c' "the stored seed tree is $storedTree; the pin is $SeedTree" }

$storedBrief = (& git -C $clone rev-parse "${Sha}:evals/tf/BRIEF.md").Trim()
if ($storedBrief -eq $BriefBlob) { Ok "the brief blob is the pinned $BriefBlob" }
else { Bad '3d' "the brief blob is $storedBrief; the pin is $BriefBlob" }

# The LEDGER must actually carry both pins - the acceptance test asserts the
# shape, this asserts the VALUES, which is a different claim.
$ledger = Get-Content -LiteralPath "$clone/LEDGER.md" -Raw
if ($ledger -match [regex]::Escape($BriefBlob) -and $ledger -match [regex]::Escape($SeedTree)) {
    Ok 'LEDGER.md carries both pinned values, not merely pin-shaped strings'
}
else {
    Bad '3e' 'LEDGER.md does not carry both pinned values'
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '4. The kit scanner, re-run over BRIEF and seed.'
# ---------------------------------------------------------------------------
if ($FailCheck) {
    Mark
    # Plant a case word in the BRIEF inside the clone. This is the probe the
    # plan claims: the scan must stop being clean.
    $briefPath = "$tfDir/BRIEF.md"
    $briefBefore = Get-Content -LiteralPath $briefPath -Raw
    $briefAfter = "Case 4 is the registry-style source, and the expected graph has twelve nodes.`n" + $briefBefore
    Set-Content -LiteralPath $briefPath -Value $briefAfter -Encoding utf8NoBOM -NoNewline
    if ((Get-Content -LiteralPath $briefPath -Raw) -eq $briefBefore) { Bad '4p' 'probe changed nothing in BRIEF.md' }
}

$kit = Invoke-CommandInClone -Command "Set-Location '$tfDir'; & ./Test-FixtureSanitization.ps1 -RuleSet Kit -Path @('./BRIEF.md','./seed') -Label 'TF003 KIT' -FailCheck"
if ($kit.ExitCode -eq 0 -and $kit.Output -match 'TF003 KIT SANITIZATION: clean' -and $kit.Output -match 'FALSIFICATION PASSED') {
    Ok 'the kit scans clean, and the scanner was shown to catch a planted line'
}
else {
    Bad '4a' "kit scan: exit $($kit.ExitCode); expected a clean verdict and a passing falsification"
}

if ($FailCheck) {
    Fired '4' 'a case word and a count planted in the brief are caught by the kit rules'
    Set-Content -LiteralPath "$tfDir/BRIEF.md" -Value $briefBefore -Encoding utf8NoBOM -NoNewline
}

# The STRONG control: the same kit rules against a real kit that was written
# without them in mind. Without this, "clean" is compatible with a rule set
# that fires at nothing.
$kitControl = Invoke-CommandInClone -Command "Set-Location '$tfDir'; & ./Test-FixtureSanitization.ps1 -RuleSet Kit -Path @('../functional/BRIEF.md','../functional/seed') -Label 'AZDO KIT CONTROL'"
if ($kitControl.ExitCode -eq 1 -and $kitControl.Output -match 'AZDO KIT CONTROL SANITIZATION: (\d+) finding') {
    $n = [regex]::Match($kitControl.Output, 'AZDO KIT CONTROL SANITIZATION: (\d+) finding').Groups[1].Value
    Ok "control: the same kit rules report $n finding(s) against the AzDO kit"
}
else {
    Bad '4b' "control: the kit rules did not report findings against the AzDO kit (exit $($kitControl.ExitCode))"
}

# The FIXTURE rule set is unmoved by having gained a second one. Both halves:
# clean where it was clean, and still discriminating where it was not.
$sanF2 = Invoke-InClone -Path "$tfDir/Test-FixtureSanitization.ps1" -Arguments @('-Fixture', 'fixture2', '-FailCheck')
if ($sanF2.ExitCode -eq 0 -and $sanF2.Output -match 'FIXTURE2 SANITIZATION: clean' -and $sanF2.Output -match 'FALSIFICATION PASSED') {
    Ok 'the fixture rule set still reports fixture 2 clean, and still catches its planted comment'
}
else {
    Bad '4c' "fixture-2 scan: exit $($sanF2.ExitCode); the fixture gate moved"
}

$sanF1 = Invoke-InClone -Path "$tfDir/Test-FixtureSanitization.ps1" -Arguments @('-Fixture', 'fixture1')
$f1Count = [regex]::Match($sanF1.Output, 'FIXTURE1 SANITIZATION: (\d+) finding').Groups[1].Value
if ($sanF1.ExitCode -eq 1 -and $f1Count -eq "$Fixture1SanitizationFindings") {
    Ok "the fixture rule set still reports $f1Count findings against fixture 1"
}
else {
    Bad '4d' "fixture-1 control is $f1Count finding(s), pinned at $Fixture1SanitizationFindings"
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '5. No release, and no fixture touched.'
# ---------------------------------------------------------------------------
$installed = & git -C $clone diff --name-only "$Tag..$Sha" -- skills/ commands/ .claude-plugin/
if ([string]::IsNullOrWhiteSpace(($installed | Out-String))) {
    Ok "git diff $Tag..HEAD -- skills/ commands/ .claude-plugin/ is empty"
}
else {
    Bad '5a' "the installed surface changed since ${Tag}: $($installed -join ', ')"
}

$fixtureDiff = & git -C $clone diff --name-only "$Tag..$Sha" -- evals/tf/fixture/ evals/tf/fixture2/
if ([string]::IsNullOrWhiteSpace(($fixtureDiff | Out-String))) {
    Ok "neither Terraform fixture changed since $Tag"
}
else {
    Bad '5b' "a fixture changed since ${Tag}: $($fixtureDiff -join ', ')"
}

# No new tag. This pass released nothing, and a tag appearing would be the
# quietest way for that claim to become false.
$tagsSince = @(& git -C $clone tag --contains $Sha)
if ($tagsSince.Count -eq 0) { Ok 'no tag points at or after this commit' }
else { Note "tags containing this commit: $($tagsSince -join ', ')" }

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '6. The acceptance test, from the clone.'
# ---------------------------------------------------------------------------
$accept = Invoke-Pester -Path "$clone/plans/0035-tf003-kit/accept.Tests.ps1" -PassThru -Output None
if ($accept.FailedCount -eq 0 -and $accept.PassedCount -eq 7) {
    Ok "acceptance: $($accept.PassedCount)/$($accept.TotalCount) green"
}
else {
    foreach ($t in ($accept.Tests | Where-Object Result -ne 'Passed')) { Bad '6' "acceptance failed: $($t.Name)" }
    if ($accept.TotalCount -ne 7) { Bad '6' "acceptance has $($accept.TotalCount) tests; the prompt specified 7" }
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '--- summary ---'
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
    Write-Host 'VERIFIED - every check re-derived and agreed.' -ForegroundColor Green
    exit 0
}

Write-Host "$($failures.Count) CHECK(S) DISAGREED:" -ForegroundColor Red
foreach ($f in $failures) { Write-Host "  $f" -ForegroundColor Red }
exit 1
