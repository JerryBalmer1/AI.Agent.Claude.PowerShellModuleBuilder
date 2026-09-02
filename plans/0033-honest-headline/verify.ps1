#Requires -Version 7.2
<#
.SYNOPSIS
    Verification for pass 0033 (the honest headline). Re-derives every claim the
    plan makes, from a FRESH CLONE of this repository at a pinned commit.

.DESCRIPTION
    This script exists so the operator can disprove the plan without reading it.
    It never parses plan.md, never reads a number out of prose, and never trusts
    the working tree. Two things it deliberately checks against the NETWORK
    rather than the clone: the release tag, because a tag that exists only
    locally is exactly the failure that check is for, and the two target commits
    it re-scores, because a re-score against a local copy proves nothing about
    what was pushed.

    The heavy checks - 1 and 2 - each clone and BUILD the target module, which
    takes a few minutes and needs InvokeBuild, Pester, PSScriptAnalyzer,
    powershell-yaml and $env:AZDO_PAT. Pass -SkipRescore to run everything else.

.PARAMETER Sha
    The commit to verify. Defaults to HEAD of the repository this script sits in.

.PARAMETER SkipRescore
    Skip checks 1 and 2 (the re-score and the falsification triple), which are
    the only ones that clone and build the target module. Everything else still
    runs. The skip is REPORTED, not silent.

.PARAMETER FailCheck
    Runs the falsification probes instead of the checks: each probe breaks the
    thing a check depends on, IN THE CLONE ONLY, and asserts the check goes red.
    A check that stays green under its own probe is reported as DOES NOT FIRE.

    Every probe asserts it actually changed its target before the check is
    re-run (evals/HARNESS.md hazards 4 and 6). A probe that changed nothing
    produces a green that proves nothing and reads exactly like a real one.
#>
[CmdletBinding()]
param(
    [string]$Sha,
    [switch]$SkipRescore,
    [switch]$FailCheck
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$Tag      = 'v1.0.1'
$Version  = '1.0.1'
$PrevTag  = 'v1.0.0'

# The two commits re-scored by task 2, and the third the README's first-shot
# claim rests on. Pinned here, not read from rescore.txt - a verify script that
# reads its numbers out of the document it is checking has verified the
# document's internal consistency and nothing else.
$TargetUrl   = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$Sha007Final = '95ca28d76c8eeb6dc33b09f77109dc96038c76aa'
$Sha006Final = '70669167ea5f59a47efb282002052f9e926a34bf'

if (-not $Sha) { $Sha = (git -C $RepoRoot rev-parse HEAD).Trim() }

$failures = [Collections.Generic.List[string]]::new()
$notes    = [Collections.Generic.List[string]]::new()
$probes   = [Collections.Generic.List[string]]::new()
$skipped  = [Collections.Generic.List[string]]::new()
function Ok   { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Bad  { param($id, $m) Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:failures.Add("${id}: $m") }
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
    # Discard the deliberate failures so the run's own summary stays honest.
    while ($script:failures.Count -gt $script:mark) { $script:failures.RemoveAt($script:failures.Count - 1) }
}

# Short root on purpose. The session scratchpad path is long enough that
# `git clone` fails with "cannot write keep file ... Filename too long" on
# Windows before it writes a single object - which looks like a network fault.
$work  = Join-Path 'C:\Users\jlbal\AppData\Local\Temp' ("v0033-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
if (-not (Test-Path 'C:\Users\jlbal\AppData\Local\Temp')) {
    $work = Join-Path ([IO.Path]::GetTempPath()) ("v0033-" + [guid]::NewGuid().ToString('N').Substring(0, 6))
}
$clone = Join-Path $work 'h'

Write-Host 'Pass 0033 verification'
Write-Host "  repository : $RepoRoot"
Write-Host "  commit     : $Sha"
Write-Host "  clone      : $clone"
Write-Host "  mode       : $(if ($FailCheck) { 'FailCheck (falsification probes)' } else { 'checks' })"
Write-Host ''

New-Item -ItemType Directory -Path $work -Force | Out-Null
git -c core.longpaths=true clone -q $RepoRoot $clone
if ($LASTEXITCODE -ne 0) { throw 'clone failed' }
git -C $clone checkout -q $Sha
if ($LASTEXITCODE -ne 0) { throw "checkout $Sha failed" }

$readme    = "$clone/README.md"
$rescore   = "$clone/plans/0033-honest-headline/rescore.txt"
$tfScan    = "$clone/plans/0033-honest-headline/tf-fixture-comments.txt"
$harness   = "$clone/evals/HARNESS.md"
$scoreTool = "$clone/evals/conformance/Score-Clone.ps1"

# The score a conformance result carries, computed the way the project reports
# it: assertions passed against cases-defined. Duplicated here rather than
# imported, so a defect in Score-Clone.ps1 cannot make this script agree with it.
function Get-AssertionScore {
    param([string]$ResultPath)
    $j = Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json
    $failed = @($j.Assertions | Where-Object { $_.Failed -gt 0 }).Count
    [pscustomobject]@{
        Score        = [int]$j.CasesDefined - $failed
        CasesDefined = [int]$j.CasesDefined
        CasesRun     = [int]$j.CasesRun
        Failed       = $failed
    }
}

try {

# ===========================================================================
# Check 1 - the rescore, re-derived from fresh clones of both final SHAs
# ===========================================================================
Write-Host 'Check 1 - rescore reproduced under the corrected procedure'
if ($FailCheck) {
    Skip 1 'no probe: check 1 re-derives against the network and cannot be broken in the clone. Its own falsification is check 2.'
}
elseif ($SkipRescore) {
    Skip 1 'rescore skipped by -SkipRescore (checks 1 and 2 are the only ones that build the target)'
}
else {
    $expect = @(
        @{ id = '007-final'; sha = $Sha007Final; score = 32 }
        @{ id = '006-final'; sha = $Sha006Final; score = 33 }
    )
    foreach ($e in $expect) {
        $dir = Join-Path $work $e.id
        $r = & $scoreTool -Source $TargetUrl -Ref $e.sha -WorkDir $dir *>&1 |
            Where-Object { $_ -is [pscustomobject] } | Select-Object -Last 1
        if (-not $r) { Bad 1 "$($e.id): Score-Clone.ps1 produced no result object"; continue }
        if ($r.BuildExitCode -ne 0) { Bad 1 "$($e.id): build exited $($r.BuildExitCode); the score is unattributable" }
        if ($r.Score -ne $e.score) {
            Bad 1 "$($e.id): re-derived $($r.Score)/$($r.CasesDefined), rescore.txt records $($e.score)/33"
        }
        else {
            Ok "$($e.id) at $($e.sha.Substring(0,7)) re-derives $($r.Score)/33 (cases $($r.CasesPassed)/$($r.CasesRun)), built"
        }
    }

    # The corrected pair must also be the pair the README quotes, and the file
    # must carry the ladder-mechanism verdict either way.
    $t = Get-Content $rescore -Raw
    foreach ($pat in @(
            'run 007 final \(corrected\):\s*32\s*/\s*33',
            'run 006 final \(corrected\):\s*33\s*/\s*33',
            'LADDER MECHANISM: (explained|unexplained)')) {
        if ($t -notmatch $pat) { Bad 1 "rescore.txt does not carry /$pat/" }
    }
    if ($t -match 'LADDER MECHANISM: explained') { Ok 'rescore.txt states the ladder mechanism as explained' }
    elseif ($t -match 'LADDER MECHANISM: unexplained') { Note 'rescore.txt states the ladder mechanism as UNEXPLAINED' }
}

# ===========================================================================
# Check 2 - the falsification triple for the scoring repair, re-fired
#
# The control is the one that matters. If an unbuilt clone stops failing the
# RequiresBuild assertions, the "repair" weakened them instead of correcting
# the procedure, and every number in check 1 is worthless.
# ===========================================================================
Write-Host 'Check 2 - falsification triple for the scoring repair'
if ($FailCheck) {
    Skip 2 'no probe: check 2 IS the falsification, and its own control row (an unbuilt clone must still fail) is the probe.'
}
elseif ($SkipRescore) {
    Skip 2 'falsification triple skipped by -SkipRescore'
}
else {
    # Row 1 - unbuilt clone must STILL fail, at exactly the reported 28/33.
    $u = & $scoreTool -Source $TargetUrl -Ref $Sha007Final -WorkDir (Join-Path $work 'f1') -SkipBuild *>&1 |
        Where-Object { $_ -is [pscustomobject] } | Select-Object -Last 1
    $reqBuild = @($u.FailedAssertions | Where-Object { $_ -match 'generated module' })
    if ($u.Score -eq 28 -and $reqBuild.Count -eq 4) {
        Ok "control: unbuilt clone still fails 4 generated-module assertions, 28/33 as originally reported"
    }
    else {
        Bad 2 "control: unbuilt clone scored $($u.Score)/33 with $($reqBuild.Count) generated-module failures; expected 28 and 4"
    }

    # Row 2 - sabotage the build. Staged as a commit so Score-Clone.ps1 runs
    # unmodified: it clones what it is given, and it is given a broken commit.
    $stage = Join-Path $work 'stage'
    git clone -q --no-checkout -- $TargetUrl $stage
    git -C $stage checkout -q --detach $Sha007Final
    $bf = Join-Path $stage 'PSAzureDevOpsGraph.build.ps1'
    $before = Get-Content $bf -Raw
    $after = $before -replace "(?m)^task Build \{", "task Build {`r`n    throw 'VERIFY SABOTAGE'"
    if ($after -eq $before) { throw 'probe changed nothing - the Build task was not found' }
    Set-Content -LiteralPath $bf -Value $after -NoNewline
    git -C $stage checkout -q -b sabotage
    git -C $stage -c user.name=v -c user.email=v@local commit -q -am 'sabotage'

    $s = & $scoreTool -Source $stage -Ref sabotage -WorkDir (Join-Path $work 'f2') -ScoreAnyway *>&1 |
        Where-Object { $_ -is [pscustomobject] } | Select-Object -Last 1
    $sabReq = @($s.FailedAssertions | Where-Object { $_ -match 'generated module' })
    if ($s.BuildExitCode -ne 0 -and $sabReq.Count -eq 4) {
        Ok "sabotage: build exits $($s.BuildExitCode) and the 4 generated-module assertions go red"
    }
    else {
        Bad 2 "sabotage: build exit $($s.BuildExitCode), $($sabReq.Count) generated-module failures; expected non-zero and 4"
    }

    # Row 2b - the Phase 0 gate. The same broken commit WITHOUT -ScoreAnyway
    # must refuse to produce a score at all.
    $gateFired = $false
    try { & $scoreTool -Source $stage -Ref sabotage -WorkDir (Join-Path $work 'f2b') *> $null }
    catch { $gateFired = $_.Exception.Message -match 'gates on Phase 0' }
    if ($gateFired) { Ok 'gate: a red build refuses to become a conformance number' }
    else { Bad 2 'gate: a red build was scored without -ScoreAnyway' }

    # Row 3 - a built conforming clone passes. Already scored in check 1; this
    # asserts the row explicitly so check 2 stands alone.
    if (-not $SkipRescore) {
        $g = Get-AssertionScore -ResultPath (Join-Path $work '006-final/conformance-result.json')
        if ($g.Score -eq 33 -and $g.Failed -eq 0) { Ok 'positive: built conforming clone passes 33/33, zero failed assertions' }
        else { Bad 2 "positive: built conforming clone scored $($g.Score)/33 with $($g.Failed) failed assertions" }
    }
}

# ===========================================================================
# Check 3 - every number in the README's with/without section resolves to an
# artifact. Read out of the README, matched against the run records and
# rescore.txt - never against the plan.
# ===========================================================================
Write-Host 'Check 3 - README claims resolve to artifacts'
$r = Get-Content $readme -Raw
if ($FailCheck) {
    Mark
    $broken = $r -replace '\*\*32 / 33\*\*', '**99 / 33**'
    if ($broken -eq $r) { throw 'probe changed nothing - the corrected 007 figure was not found in README' }
    Set-Content -LiteralPath $readme -Value $broken -NoNewline
    $r = Get-Content $readme -Raw
}

$section = if ($r -match '(?s)## With the plugin and without it(.+?)## The variance') { $Matches[1] } else { '' }
if (-not $section) { Bad 3 'the with/without section could not be located in README.md' }

# Each claim, with the artifact that has to agree with it.
$claims = @(
    @{ pat = '\*\*32 / 33\*\*';  where = 'rescore.txt'; art = $rescore; artPat = 'run 007 final \(corrected\):\s*32\s*/\s*33' }
    @{ pat = '19 / 33';          where = 'runs/007 record'; art = "$clone/runs/007-baseline-iterated/README.md"; artPat = '19/33 \(55 run\)' }
    @{ pat = '28 / 33';          where = 'runs/007 record'; art = "$clone/runs/007-baseline-iterated/README.md"; artPat = 'conformance:\s*28 / 33' }
    @{ pat = '\*\*6 / 12\*\*';   where = 'runs/007 record'; art = "$clone/runs/007-baseline-iterated/README.md"; artPat = 'functional \(first-shot\):\s*6 / 12' }
    @{ pat = '\*\*14\*\*';       where = 'runs/007 record'; art = "$clone/runs/007-baseline-iterated/README.md"; artPat = '14 first-shot differences|14 were `wrongEdgeAttribute`' }
    @{ pat = '181 min';          where = 'runs/007 record'; art = "$clone/runs/007-baseline-iterated/README.md"; artPat = 'phase-1-minutes:\s*181' }
    @{ pat = '\*\*33 / 33\*\*';  where = 'runs/006 record'; art = "$clone/runs/006-plugin-on/README.md"; artPat = 'conformance:\s*33 / 33' }
)
foreach ($c in $claims) {
    if ($section -notmatch $c.pat) { Bad 3 "README with/without section does not state /$($c.pat)/"; continue }
    $a = Get-Content -LiteralPath $c.art -Raw
    if ($a -notmatch $c.artPat) { Bad 3 "/$($c.pat)/ in README does not resolve to $($c.where)" }
    else { Ok "README /$($c.pat)/ resolves to $($c.where)" }
}

# The controlled claim itself, and the limit that travels with it.
foreach ($p in @('buys shape, not correctness', 'single control', "control's first shot was the closest")) {
    if ($section -notmatch [regex]::Escape($p)) { Bad 3 "the with/without section does not carry '$p'" }
    else { Ok "the with/without section carries '$p'" }
}
# Claims may move down or sideways, never up. The pre-0033 overstatement is the
# one thing that must NOT be there any more.
if ($section -match 'nearly flat') { Bad 3 'the superseded "nearly flat" framing is still in the with/without section' }
else { Ok 'the superseded "nearly flat" framing is gone' }

if ($FailCheck) {
    Fired 3 'a wrong corrected figure in README is caught against rescore.txt'
    git -C $clone checkout -q -- README.md
    $r = Get-Content $readme -Raw
}

# ===========================================================================
# Check 4 - the installed surface between the two tags
#
# The prompt pinned this as "EXACTLY one changed line: the plugin.json version
# field". That is not what the tree contains: .claude-plugin/ carries THREE
# version strings and Publish-Local.ps1 rejects a partial bump. So the check is
# written against what must actually be true - skills/ and commands/ byte-
# identical, and every changed line under .claude-plugin/ a version field going
# 1.0.0 -> 1.0.1 - which is a stronger assertion than the one the prompt named.
# ===========================================================================
Write-Host 'Check 4 - installed surface unchanged between the tags'
git -C $clone fetch -q --tags origin 2>&1 | Out-Null
if ($FailCheck) {
    # Probe: commit a change to skills/ AND to the conformance suite, then move
    # the LOCAL v1.0.1 tag onto it. Checks 4 and 8 both read that tag range, so
    # this one probe falsifies the two strongest claims of the pass - "no skill
    # changed" and "no assertion weakened". Done after the fetch, so the fetch
    # cannot quietly put the tag back.
    Mark
    $skillFile = @(Get-ChildItem "$clone/skills" -Recurse -Filter *.md -File | Select-Object -First 1)[0]
    $suiteFile = "$clone/evals/conformance/Conformance.Tests.ps1"
    $skillBefore = (Get-FileHash -LiteralPath $skillFile.FullName).Hash
    $suiteBefore = (Get-FileHash -LiteralPath $suiteFile).Hash
    Add-Content -LiteralPath $skillFile.FullName -Value "`n<!-- verify probe -->"
    Add-Content -LiteralPath $suiteFile -Value "`n# verify probe"
    if ((Get-FileHash -LiteralPath $skillFile.FullName).Hash -eq $skillBefore -or
        (Get-FileHash -LiteralPath $suiteFile).Hash -eq $suiteBefore) {
        throw 'probe changed nothing - skills/ or the suite file did not move'
    }
    git -C $clone -c user.name=v -c user.email=v@local commit -q -am 'verify probe'
    git -C $clone tag -f -a $Tag -m 'probe' HEAD 2>&1 | Out-Null
}
$tagsPresent = (git -C $clone tag -l $PrevTag) -and (git -C $clone tag -l $Tag)
if (-not $tagsPresent) {
    Bad 4 "one or both of $PrevTag / $Tag is not present in the clone after fetching tags"
}
else {
    $surface = @(git -C $clone diff --name-only "$PrevTag..$Tag" -- skills/ commands/)
    if ($surface.Count -eq 0) { Ok "skills/ and commands/ are byte-identical between $PrevTag and $Tag" }
    else { Bad 4 "skills/ or commands/ changed between the tags: $($surface -join ', ')" }

    $plugin = @(git -C $clone diff --unified=0 "$PrevTag..$Tag" -- .claude-plugin/ |
        Where-Object { $_ -match '^[+-]' -and $_ -notmatch '^(\+\+\+|---)' })
    $added   = @($plugin | Where-Object { $_.StartsWith('+') })
    $removed = @($plugin | Where-Object { $_.StartsWith('-') })
    $allVersionLines =
        ($added.Count -eq 3 -and $removed.Count -eq 3) -and
        (@($removed | Where-Object { $_ -match '"version":\s*"1\.0\.0"' }).Count -eq 3) -and
        (@($added   | Where-Object { $_ -match '"version":\s*"1\.0\.1"' }).Count -eq 3)
    if ($allVersionLines) {
        Ok '.claude-plugin/ changes are exactly three version lines, all 1.0.0 -> 1.0.1'
    }
    else {
        Bad 4 (".claude-plugin/ diff is not three version lines: $($removed.Count) removed, " +
               "$($added.Count) added -- $($plugin -join ' | ')")
    }
}
if ($FailCheck) { Fired 4 'a change to skills/ inside the tag range is caught' }

# ===========================================================================
# Check 5 - the manifest, the tag, and the remote agree
# ===========================================================================
Write-Host 'Check 5 - manifest, tag and remote agree'
if ($FailCheck) {
    Mark
    $pf = "$clone/.claude-plugin/plugin.json"
    $before = Get-Content $pf -Raw
    $broken = $before -replace '"version": "1\.0\.1"', '"version": "9.9.9"'
    if ($broken -eq $before) { throw 'probe changed nothing - plugin.json version not found' }
    Set-Content -LiteralPath $pf -Value $broken -NoNewline
}
$manifestVersion = (Get-Content "$clone/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version
if ($manifestVersion -eq $Version) { Ok "plugin.json version is $Version" }
else { Bad 5 "plugin.json version is '$manifestVersion', expected '$Version'" }

$market = Get-Content "$clone/.claude-plugin/marketplace.json" -Raw | ConvertFrom-Json
$entry = @($market.plugins | Where-Object { $_.name -eq 'psmodule' })[0]
if ($entry.version -eq $Version) { Ok "marketplace entry version is $Version" }
else { Bad 5 "marketplace entry version is '$($entry.version)', expected '$Version'" }

$remoteTag = @(git -C $RepoRoot ls-remote --tags origin "$Tag*")
if ($remoteTag.Count -gt 0) { Ok "$Tag is on the remote" }
else { Bad 5 "$Tag is not on the remote" }

$changelog = Get-Content "$clone/CHANGELOG.md" -Raw
if ($changelog -match '(?m)^## 1\.0\.1') { Ok 'CHANGELOG carries a 1.0.1 section' }
else { Bad 5 'CHANGELOG has no 1.0.1 section' }
if ($FailCheck) {
    Fired 5 'a manifest version that disagrees with the tag is caught'
    git -C $clone checkout -q -- .claude-plugin/plugin.json
}

# ===========================================================================
# Check 6 - link check across README and every chapter this pass touched
# ===========================================================================
Write-Host 'Check 6 - relative links resolve'
$touched = @(
    'README.md', 'CHANGELOG.md', 'LEDGER.md',
    'evals/HARNESS.md', 'evals/conformance/README.md', 'method/METHOD.md',
    'docs/testing/README.md',
    'docs/creating-an-agent/02-order-of-operations.md',
    'docs/creating-an-agent/04-fresh-sessions-and-contamination.md',
    'docs/creating-an-agent/05-calling-bullshit-verification.md',
    'docs/creating-an-agent/07-failure-catalog.md',
    'runs/003-baseline-off/README.md', 'runs/004-plugin-on/README.md',
    'runs/005-plugin-on/README.md', 'runs/006-plugin-on/README.md',
    'runs/007-baseline-iterated/README.md'
)
if ($FailCheck) {
    Mark
    $f = "$clone/README.md"
    $before = Get-Content $f -Raw
    $broken = $before -replace '\(LEDGER\.md\)', '(LEDGER-does-not-exist.md)'
    if ($broken -eq $before) { throw 'probe changed nothing - no (LEDGER.md) link in README' }
    Set-Content -LiteralPath $f -Value $broken -NoNewline
}
$dead = [Collections.Generic.List[string]]::new()
foreach ($rel in $touched) {
    $full = Join-Path $clone $rel
    if (-not (Test-Path -LiteralPath $full)) { Bad 6 "touched file missing: $rel"; continue }
    $dir = Split-Path -Parent $full
    foreach ($m in [regex]::Matches((Get-Content $full -Raw), '\]\(([^)]+)\)')) {
        $link = $m.Groups[1].Value
        if ($link -match '^(https?:|mailto:|#)') { continue }
        $path = ($link -split '#')[0]
        if (-not $path) { continue }
        if (-not (Test-Path -LiteralPath (Join-Path $dir $path))) { $dead.Add("$rel -> $link") }
    }
}
if ($dead.Count -eq 0) { Ok "no dead relative links across $($touched.Count) touched documents" }
else { foreach ($d in $dead) { Bad 6 "dead link: $d" } }
if ($FailCheck) {
    Fired 6 'a dead relative link is caught'
    git -C $clone checkout -q -- README.md
}

# ===========================================================================
# Check 7 - the disclosures landed where they were promised
# ===========================================================================
Write-Host 'Check 7 - hazards and blindness caveats'
if ($FailCheck) {
    Mark
    # The heading must actually GO. The first version of this probe renamed it
    # to '## Blindness caveats REMOVED BY PROBE', which still matches
    # /(?m)^## Blindness caveats/ - the file changed, the guard was satisfied,
    # and the probe reported DOES NOT FIRE against a check that was working.
    # That is hazard 4 one level in: a break that lands without breaking the
    # thing under test. The guard now asserts the check's own pattern is gone.
    $rf = "$clone/runs/005-plugin-on/README.md"
    $before = Get-Content $rf -Raw
    $broken = $before -replace '(?m)^## Blindness caveats.*$', '## Section removed by probe'
    if ($broken -eq $before) { throw 'probe changed nothing - no ## Blindness caveats heading in runs/005' }
    if ($broken -match '(?m)^## Blindness caveats') { throw "probe changed the file but the check's own pattern still matches" }
    Set-Content -LiteralPath $rf -Value $broken -NoNewline
}
$h = Get-Content $harness -Raw
foreach ($p in @('prompt-borne oracle content', 'case-annotated comments')) {
    if ($h -match [regex]::Escape($p)) { Ok "HARNESS.md carries the hazard '$p'" }
    else { Bad 7 "HARNESS.md is missing the hazard '$p'" }
}
foreach ($n in '003-baseline-off', '004-plugin-on', '005-plugin-on', '006-plugin-on', '007-baseline-iterated') {
    $rr = Get-Content "$clone/runs/$n/README.md" -Raw
    if ($rr -match '(?m)^## Blindness caveats') { Ok "runs/$n carries ## Blindness caveats" }
    else { Bad 7 "runs/$n has no ## Blindness caveats section" }
}
$tf = Get-Content $tfScan -Raw
if ($tf -match 'TF FIXTURE CASE-COMMENT SCAN: (clean|findings listed)') {
    Ok "the TF fixture scan states a verdict: $($Matches[1])"
}
else { Bad 7 'the TF fixture scan states no verdict' }

# The scan is read-only. The fixture must be byte-identical to the tag.
$fixtureDiff = @(git -C $clone diff --name-only "$PrevTag..$Tag" -- evals/tf/fixture/)
if ($fixtureDiff.Count -eq 0) { Ok 'the Terraform fixture is untouched between the tags' }
else { Bad 7 "the Terraform fixture changed: $($fixtureDiff -join ', ')" }
if ($FailCheck) {
    Fired 7 'a run record missing its Blindness caveats section is caught'
    git -C $clone checkout -q -- runs/005-plugin-on/README.md
}

# ===========================================================================
# Check 8 - no conformance assertion was weakened
#
# The whole repair rests on this. The suite file must be byte-identical to the
# previous tag: the procedure changed, the oracle did not.
# ===========================================================================
Write-Host 'Check 8 - the conformance suite is unchanged'
if ($tagsPresent) {
    $suiteDiff = @(git -C $clone diff --name-only "$PrevTag..$Tag" -- evals/conformance/Conformance.Tests.ps1)
    if ($suiteDiff.Count -eq 0) { Ok 'Conformance.Tests.ps1 is byte-identical to the previous tag' }
    else { Bad 8 'Conformance.Tests.ps1 changed - a procedure repair must not touch the assertions' }
}
else { Skip 8 'tags not present; suite comparison not run' }
if ($FailCheck) { Fired 8 'an edited conformance assertion inside the tag range is caught' }

# ===========================================================================
# Check 9 - the acceptance suite, run from the clone
# ===========================================================================
Write-Host 'Check 9 - acceptance suite'
$acc = Invoke-Pester -Path "$clone/plans/0033-honest-headline/accept.Tests.ps1" -PassThru -Output None
if ($acc.FailedCount -eq 0 -and $acc.PassedCount -gt 0) { Ok "acceptance $($acc.PassedCount)/$($acc.TotalCount) green" }
else { Bad 9 "acceptance $($acc.PassedCount) passed, $($acc.FailedCount) failed" }

}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
if ($FailCheck) {
    if ($probes.Count -eq 0) { Write-Host 'All probes fired.' -ForegroundColor Green; exit 0 }
    Write-Host "PROBES THAT DID NOT FIRE: $($probes.Count)" -ForegroundColor Red
    foreach ($p in $probes) { Write-Host "  $p" }
    exit 1
}
foreach ($n in $notes)   { Write-Host "note: $n" -ForegroundColor DarkGray }
foreach ($k in $skipped) { Write-Host "skipped: $k" -ForegroundColor Yellow }
if ($failures.Count -eq 0) {
    Write-Host "All checks agree.$(if ($skipped.Count) { "  ($($skipped.Count) skipped, listed above.)" })" -ForegroundColor Green
    exit 0
}
Write-Host "FAILURES: $($failures.Count)" -ForegroundColor Red
foreach ($f in $failures) { Write-Host "  $f" }
exit 1
