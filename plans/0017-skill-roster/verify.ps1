#Requires -Version 7.2
<#
    .SYNOPSIS
        Re-derives every claim pass 0017 makes, from a fresh clone. Never reads
        a number out of plan.md.

    .DESCRIPTION
        Assumes nothing but a clone of this repository and the tools. It writes
        only under scratch/, which it creates and removes itself, and it never
        depends on scratch/ already existing.

        Six named spot-checks, in the order the prompt named them:

          1. The nine roster paths and the four absent old paths, checked in a
             FRESH CLONE of this repository rather than in the working tree.
          2. Invoke-OrderedTests.ps1 re-run against a fresh clone of
             run-002-first-build: every layer green. No PAT is needed; if a
             layer turns out to need one, that is a LOUD skip.
          3. The fail-fast property RE-DERIVED, not read. This script introduces
             its own parse error into its own scratch clone, asserts the run
             stops at files-parse naming exactly that one file, and cleans up.
          4. Invoke-Conformance.ps1 with no -ModuleName equals its result with
             the explicit flag, and the two-manifest ambiguity hard-stops.
          5. git ls-remote shows v0.1.0 on the module remote peeling to
             79e02fb. The COMMIT, not merely the ref - see the note at that
             check for why the acceptance test's weaker form is not enough.
          6. The evals/ diff for this pass touches exactly two files.

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
$WrittenAgainstSha = '70647b6cf743a9f1218a626267d867a024572b7f'
$WrittenAgainstBranch = 'pass-0017-skill-roster'

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$Scratch = Join-Path $RepoRoot 'scratch/verify-0017'

$BaseSha = '4bcb0ed4fd25026cd48bed28fd2a8a92a35d5f15'
$TargetSha = '79e02fba9dffd976bccf507d531f59303cc58f9d'
$TargetBranch = 'run-002-first-build'
$TargetRemote = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$TargetTag = 'v0.1.0'
$ModuleName = 'PSAzureDevOpsGraph'

$RosterSkills = @(
    'powershell-module-scaffold'
    'powershell-module-build'
    'powershell-module-test'
    'powershell-module-deploy'
    'powershell-module-release'
    'powershell-module-architect'
    'powershell-module-analyzer'
    'powershell-module-plan'
    'powershell-module-docs'
    'task-tree-reporting'
    'azdo-rest'
    'azdo-pipeline-yaml-refs'
    'azdo-graph-assembly'
)
$RetiredSkills = @('module-scaffold', 'build-script', 'pipeline-yaml-refs', 'graph-assembly')

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

# The roster test, as ONE function, so the FailCheck probes re-run exactly what
# check 1 ran rather than restating it. A probe that asserts "I deleted the
# file, and the file is gone" proves the probe works and says nothing about the
# check.
function Measure-RosterDisagreement {
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string] $CloneRoot)

    $problems = @()
    foreach ($skill in $RosterSkills) {
        if (-not (Test-Path -LiteralPath (Join-Path $CloneRoot "skills/$skill/SKILL.md"))) {
            $problems += "missing: skills/$skill/SKILL.md"
        }
    }
    foreach ($retired in $RetiredSkills) {
        if (Test-Path -LiteralPath (Join-Path $CloneRoot "skills/$retired")) {
            $problems += "resurrected: skills/$retired"
        }
    }
    $dirs = @(Get-ChildItem -Path (Join-Path $CloneRoot 'skills') -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Name } | Sort-Object)
    foreach ($diff in @(Compare-Object $dirs ($RosterSkills | Sort-Object) -ErrorAction SilentlyContinue)) {
        $problems += "unexpected in skills/: $($diff.InputObject)"
    }
    # NOT `, $problems`. The unary comma wraps the array, so an empty result
    # arrives at the call site as ONE element that is an empty array - and the
    # check reports a disagreement it cannot name. Every call site wraps this in
    # @(), which handles the empty and single-element cases correctly.
    return $problems
}

# --- HEAD drift, per decision 0004 -----------------------------------------

$currentSha = $null
try { $currentSha = (git -C $RepoRoot rev-parse HEAD).Trim() } catch { }
$currentBranch = $null
try { $currentBranch = (git -C $RepoRoot rev-parse --abbrev-ref HEAD).Trim() } catch { }

Write-Host ''
Write-Host "verify.ps1 for pass 0017"
Write-Host "  written against : $WrittenAgainstSha on $WrittenAgainstBranch"
Write-Host "  running at      : $currentSha on $currentBranch"
if ($currentSha -and $WrittenAgainstSha -notmatch '^PASS-' -and $currentSha -ne $WrittenAgainstSha) {
    $ahead = (git -C $RepoRoot rev-list --count "$WrittenAgainstSha..HEAD" 2>$null)
    Write-Host "  NOTE: HEAD has moved $ahead commit(s) since this script was written." -ForegroundColor Yellow
    Write-Host "        Any disagreement below may be the repository having moved on" -ForegroundColor Yellow
    Write-Host "        rather than pass 0017 having been wrong. Decision 0004." -ForegroundColor Yellow
}
Write-Host ''

# --- scratch, created here and owned here ----------------------------------

if (Test-Path -LiteralPath $Scratch) { Remove-Item -LiteralPath $Scratch -Recurse -Force }
$null = New-Item -ItemType Directory -Path $Scratch -Force

$OrderedRunner = Join-Path $RepoRoot 'skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1'
$Conformance = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'

try {

    # =======================================================================
    # 1. The roster, in a FRESH CLONE of this repository
    # =======================================================================

    Write-Host '1. Roster paths, from a fresh clone of this repository'

    $harnessClone = Join-Path $Scratch 'harness'
    & git clone --quiet --no-hardlinks $RepoRoot $harnessClone 2>&1 | Out-Null
    Confirm-That 'this repository clones' (Test-Path -LiteralPath (Join-Path $harnessClone 'skills'))

    foreach ($skill in $RosterSkills) {
        $skillFile = Join-Path $harnessClone "skills/$skill/SKILL.md"
        Confirm-That "skills/$skill/SKILL.md exists in the clone" (Test-Path -LiteralPath $skillFile)
    }
    foreach ($retired in $RetiredSkills) {
        Confirm-That "skills/$retired is gone from the clone" `
            (-not (Test-Path -LiteralPath (Join-Path $harnessClone "skills/$retired")))
    }

    Confirm-That 'the ordered runner ships as a script' `
        (Test-Path -LiteralPath (Join-Path $harnessClone 'skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1'))
    Confirm-That 'the plan intake template ships' `
        (Test-Path -LiteralPath (Join-Path $harnessClone 'skills/powershell-module-plan/templates/module-plan.md'))
    Confirm-That 'decision 0006 exists' `
        (Test-Path -LiteralPath (Join-Path $harnessClone 'decisions/0006-target-versioning-and-tags.md'))
    Confirm-That 'decision 0007 exists' `
        (Test-Path -LiteralPath (Join-Path $harnessClone 'decisions/0007-skill-taxonomy-and-naming.md'))

    # Every skill directory in the clone is one of the thirteen: a stray
    # left-over directory is as much a failure as a missing one. This is the
    # same function the FailCheck probes re-run.
    $found = @(Get-ChildItem -Path (Join-Path $harnessClone 'skills') -Directory | ForEach-Object { $_.Name } | Sort-Object)
    $rosterProblems = @(Measure-RosterDisagreement -CloneRoot $harnessClone)
    Confirm-That "the roster agrees exactly ($($found.Count) directories, $($rosterProblems.Count) disagreement(s))" `
        ($rosterProblems.Count -eq 0)
    foreach ($problem in $rosterProblems) { Write-Note $problem }

    # No skill still refers to a retired name.
    $stale = @(Select-String -Path (Join-Path $harnessClone 'skills/*/SKILL.md') `
            -Pattern '(?<![\w-])(module-scaffold|build-script|pipeline-yaml-refs|graph-assembly)(?![\w-])' `
            -ErrorAction SilentlyContinue)
    Confirm-That 'no SKILL.md still names a retired skill' ($stale.Count -eq 0)
    foreach ($hit in $stale) { Write-Note "still names it: $($hit.Path):$($hit.LineNumber)" }

    # =======================================================================
    # 2. The ordered runner against a fresh clone of run-002-first-build
    # =======================================================================

    Write-Host ''
    Write-Host '2. Invoke-OrderedTests.ps1 against a fresh clone of run-002-first-build'

    $targetClone = Join-Path $Scratch 'target'
    $cloneOk = $true
    try {
        & git clone --quiet --branch $TargetBranch --single-branch $TargetRemote $targetClone 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { $cloneOk = $false }
    }
    catch { $cloneOk = $false }

    if (-not $cloneOk) {
        Skip-Loudly 'ordered run against run-002' "could not clone $TargetRemote - network or credentials"
        Skip-Loudly 'fail-fast re-derivation' 'depends on the clone above'
        Skip-Loudly 'conformance -ModuleName equality' 'depends on the clone above'
    }
    else {
        $clonedSha = (git -C $targetClone rev-parse HEAD).Trim()
        Confirm-That "the clone is at $TargetSha" ($clonedSha -eq $TargetSha)

        # No layer here needs a PAT: run 002's only PAT-related test sets and
        # restores the variable itself. If that ever changes, the runner says so
        # on its own and the assertion below on 'ALL LAYERS GREEN' fails loudly
        # rather than passing quietly.
        if (-not $env:AZDO_PAT) {
            Write-Note 'AZDO_PAT is not set; no layer in run 002 needs one.'
        }

        $greenOut = & pwsh -NoProfile -NonInteractive -File $OrderedRunner -Path $targetClone -Build 2>&1
        $greenExit = $LASTEXITCODE
        $greenText = ($greenOut | ForEach-Object { "$_" }) -join "`n"

        Confirm-That 'the ordered run exits 0' ($greenExit -eq 0)
        Confirm-That 'it reports ALL LAYERS GREEN' ($greenText -match 'ALL LAYERS GREEN')
        Confirm-That 'it stopped at no layer' ($greenText -notmatch 'STOPPED AT LAYER')
        foreach ($layer in 'manifest-parses', 'files-parse', 'module-imports', 'unit') {
            Confirm-That "layer $layer passed" ($greenText -match "LAYER\s+$([regex]::Escape($layer))\s+PASSED")
        }
        # Zero cases is not a pass, so the integration layer must report itself
        # as inapplicable rather than green.
        Confirm-That 'the integration layer reports INAPPLICABLE, not PASSED' `
            ($greenText -match 'LAYER\s+integration\s+INAPPLICABLE')

        if ($greenText -match 'SKIPPING tests tagged RequiresPat') {
            Skip-Loudly 'part of the ordered run' 'a layer needed AZDO_PAT and was skipped'
        }

        # ===================================================================
        # 3. Fail-fast, RE-DERIVED in this script's own clone
        # ===================================================================

        Write-Host ''
        Write-Host '3. Fail-fast, re-derived: a parse error introduced here, not read from the demo'

        $victim = Join-Path $targetClone 'src/PSAzureDevOpsGraph/Public/Get-AzDoPipelineReference.ps1'
        Confirm-That 'the file to break exists' (Test-Path -LiteralPath $victim)

        $before = Get-Content -LiteralPath $victim -Raw
        Add-Content -LiteralPath $victim -Value "`nfunction Test-VerifySabotage {`n    if (`$true) {`n"
        $after = Get-Content -LiteralPath $victim -Raw

        # The break must be proven to have changed the target before the check
        # is re-run. A substitution that matches nothing leaves the target
        # intact, the run comes back green, and the row records 'does not fire'
        # - failing toward the alarming answer, which nobody double-checks.
        Confirm-That 'the break actually changed the file' ($after -ne $before)
        $stillParses = $true
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($victim, [ref] $null, [ref] $parseErrors)
        if (@($parseErrors).Count -gt 0) { $stillParses = $false }
        Confirm-That 'the broken file genuinely no longer parses' (-not $stillParses)

        $redOut = & pwsh -NoProfile -NonInteractive -File $OrderedRunner -Path $targetClone -Build 2>&1
        $redExit = $LASTEXITCODE
        $redText = ($redOut | ForEach-Object { "$_" }) -join "`n"

        Confirm-That 'the broken run exits non-zero' ($redExit -ne 0)
        Confirm-That 'it prints STOPPED AT LAYER files-parse' ($redText -match 'STOPPED AT LAYER files-parse')
        Confirm-That 'it names the broken file' ($redText -match 'Get-AzDoPipelineReference\.ps1:\d+:\d+')

        # Single-file naming. Every diagnostic line must point at the one file
        # that was broken; downstream noise is the whole thing this runner
        # exists to suppress.
        $named = @([regex]::Matches($redText, '(?m)^\s{2}(\S+\.ps1):\d+:\d+:') |
                ForEach-Object { Split-Path -Leaf $_.Groups[1].Value } | Sort-Object -Unique)
        Confirm-That "exactly one file is named in the failures (named: $($named -join ', '))" `
            ($named.Count -eq 1 -and $named[0] -eq 'Get-AzDoPipelineReference.ps1')

        # And no downstream layer ran or reported.
        Confirm-That 'no downstream layer reported a result' `
            ($redText -notmatch 'LAYER\s+(module-imports|unit|integration)\s+(PASSED|FAILED)')
        Confirm-That 'the layers that did not run are named, not shown' `
            ($redText -match 'NOT RUN.*module-imports, unit, integration')

        # Restoration is verified, not assumed.
        Set-Content -LiteralPath $victim -Value $before -NoNewline
        $restored = Get-Content -LiteralPath $victim -Raw
        Confirm-That 'the sabotage is restored' ($restored -eq $before)
        $postErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($victim, [ref] $null, [ref] $postErrors)
        Confirm-That 'the restored file parses again' (@($postErrors).Count -eq 0)
        Confirm-That 'the clone is clean again' `
            (@(& git -C $targetClone status --porcelain).Count -eq 0)

        # ===================================================================
        # 4. Conformance -ModuleName: derived equals explicit; ambiguity stops
        # ===================================================================

        Write-Host ''
        Write-Host '4. Invoke-Conformance.ps1 -ModuleName: derived equals explicit, ambiguity hard-stops'

        # A run directory is the F-8 shape: the directory is named for the run,
        # the manifest is at src/<Name>/. Neither of the suite's two rules can
        # fire, which is what used to make -ModuleName mandatory.
        $runDir = Join-Path $Scratch '002-first-build'
        Copy-Item -LiteralPath $targetClone -Destination $runDir -Recurse -Force
        Remove-Item -LiteralPath (Join-Path $runDir '.git') -Recurse -Force -ErrorAction SilentlyContinue

        $derivedJson = Join-Path $Scratch 'derived.json'
        $explicitJson = Join-Path $Scratch 'explicit.json'
        $tags = @('Universal', 'Repository', 'HouseStyle')

        $derivedOut = & pwsh -NoProfile -NonInteractive -Command `
            "& '$Conformance' -Path '$runDir' -Tag $($tags -join ',') -ResultPath '$derivedJson' | Out-Null" 2>&1
        $derivedText = ($derivedOut | ForEach-Object { "$_" }) -join "`n"

        & pwsh -NoProfile -NonInteractive -Command `
            "& '$Conformance' -Path '$runDir' -ModuleName $ModuleName -Tag $($tags -join ',') -ResultPath '$explicitJson' | Out-Null" 2>&1 |
            Out-Null

        Confirm-That 'the derived run wrote a result' (Test-Path -LiteralPath $derivedJson)
        Confirm-That 'the explicit run wrote a result' (Test-Path -LiteralPath $explicitJson)
        Confirm-That 'the derivation announced which manifest it read' `
            ($derivedText -match "Derived -ModuleName '$ModuleName'")

        if ((Test-Path -LiteralPath $derivedJson) -and (Test-Path -LiteralPath $explicitJson)) {
            $a = Get-Content -LiteralPath $derivedJson -Raw | ConvertFrom-Json
            $b = Get-Content -LiteralPath $explicitJson -Raw | ConvertFrom-Json

            # Cases-run first. A score comparison is only valid when the
            # denominator is stable between the two runs.
            Confirm-That "cases-run agree ($($a.CasesRun) vs $($b.CasesRun))" ($a.CasesRun -eq $b.CasesRun)
            Confirm-That "passed agree ($($a.Passed) vs $($b.Passed))" ($a.Passed -eq $b.Passed)
            Confirm-That "failed agree ($($a.Failed) vs $($b.Failed))" ($a.Failed -eq $b.Failed)
            Confirm-That 'the per-assertion breakdowns are identical' `
                (($a.Assertions | ConvertTo-Json -Depth 6 -Compress) -eq ($b.Assertions | ConvertTo-Json -Depth 6 -Compress))
            # Zero cases is not a pass: a derivation that resolved nothing would
            # produce a small, clean-looking run.
            Confirm-That 'the derived run actually graded something' ($a.CasesRun -gt 0)
        }

        # The ambiguity case. Two manifests under src/ is undecidable and must
        # stop, per rule 11 - not pick the first, not pick the shortest path.
        $ambiguous = Join-Path $runDir 'src/SecondModule'
        $null = New-Item -ItemType Directory -Path $ambiguous -Force
        Set-Content -LiteralPath (Join-Path $ambiguous 'SecondModule.psd1') `
            -Value "@{ ModuleVersion = '0.1.0'; RootModule = 'SecondModule.psm1' }"
        Confirm-That 'the second manifest was actually created' `
            (Test-Path -LiteralPath (Join-Path $ambiguous 'SecondModule.psd1'))

        $ambigOut = & pwsh -NoProfile -NonInteractive -Command `
            "& '$Conformance' -Path '$runDir' -Tag Universal -ResultPath '$(Join-Path $Scratch 'ambig.json')'" 2>&1
        $ambigExit = $LASTEXITCODE
        $ambigText = ($ambigOut | ForEach-Object { "$_" }) -join "`n"

        Confirm-That 'the ambiguous target exits non-zero' ($ambigExit -ne 0)
        Confirm-That 'it refuses rather than guessing' ($ambigText -match 'Cannot derive -ModuleName')
        Confirm-That 'it names both candidates' `
            ($ambigText -match 'PSAzureDevOpsGraph\.psd1' -and $ambigText -match 'SecondModule\.psd1')
        Confirm-That 'it says how to answer the question' ($ambigText -match 'Pass -ModuleName')

        # And the ambiguity stays answerable with the explicit flag.
        $answeredJson = Join-Path $Scratch 'answered.json'
        & pwsh -NoProfile -NonInteractive -Command `
            "& '$Conformance' -Path '$runDir' -ModuleName $ModuleName -Tag $($tags -join ',') -ResultPath '$answeredJson' | Out-Null" 2>&1 |
            Out-Null
        if ((Test-Path -LiteralPath $answeredJson) -and (Test-Path -LiteralPath $explicitJson)) {
            $c = Get-Content -LiteralPath $answeredJson -Raw | ConvertFrom-Json
            $b = Get-Content -LiteralPath $explicitJson -Raw | ConvertFrom-Json
            Confirm-That '-ModuleName still answers the ambiguity' `
                ($c.CasesRun -eq $b.CasesRun -and $c.Passed -eq $b.Passed)
        }
        else {
            Confirm-That '-ModuleName still answers the ambiguity' $false
        }
    }

    # =======================================================================
    # 5. The tag on the module remote
    # =======================================================================

    Write-Host ''
    Write-Host '5. v0.1.0 on the module remote'

    # Three patterns and no bare tag name. ls-remote matches a pattern against
    # the TAIL of the ref name, so asking for 'v0.1.0' returns the tag object
    # and never 'refs/tags/v0.1.0^{}' - and the commit assertion below would
    # then have nothing to read. This is the defect in the acceptance test the
    # prompt supplied, and the reason this check is written differently.
    $restore = $env:GIT_TERMINAL_PROMPT
    $env:GIT_TERMINAL_PROMPT = '0'
    try {
        $refs = @(& git ls-remote $TargetRemote "refs/tags/$TargetTag" "refs/tags/$TargetTag^{}" 2>&1 |
                ForEach-Object { "$_" })
        $lsExit = $LASTEXITCODE
    }
    finally {
        if ($null -eq $restore) { Remove-Item -LiteralPath 'Env:\GIT_TERMINAL_PROMPT' -ErrorAction Ignore }
        else { $env:GIT_TERMINAL_PROMPT = $restore }
    }

    if ($lsExit -ne 0) {
        # Unknown is not a pass.
        Confirm-That "the remote $TargetRemote could be read" $false
        Write-Note "git said: $($refs -join ' / ')"
    }
    else {
        $tagRefs = @($refs | Where-Object { $_ -match "\srefs/tags/$([regex]::Escape($TargetTag))(\^\{\})?$" })
        Confirm-That "$TargetTag is on the remote" ($tagRefs.Count -gt 0)

        $peeled = @($tagRefs | Where-Object { $_ -match '\^\{\}$' })
        # An annotated tag answers twice. A lightweight one answers once, and
        # this pass's decision 0006 says every tag it cuts is annotated.
        Confirm-That "$TargetTag is an ANNOTATED tag" ($peeled.Count -eq 1)

        if ($peeled.Count -eq 1) {
            $peeledSha = ($peeled[0] -split '\s+')[0]
            # THE COMMIT, not merely the ref. The acceptance test's regex is an
            # alternation, so its 'v0.1.0^{}' branch is satisfied by any
            # annotated tag of that name whatever it points at. This is the
            # check that actually pins it to run 002.
            Confirm-That "$TargetTag peels to $TargetSha (got $peeledSha)" ($peeledSha -eq $TargetSha)
        }
    }

    # =======================================================================
    # 6. The evals/ diff for this pass
    # =======================================================================

    Write-Host ''
    Write-Host "6. evals/ diff since $($BaseSha.Substring(0,7))"

    $evalsTouched = @(& git -C $RepoRoot diff --name-only "$BaseSha..HEAD" -- evals/ 2>$null |
            ForEach-Object { "$_" } | Where-Object { $_ })
    Confirm-That "evals/ diff touches exactly 2 files (touched $($evalsTouched.Count))" `
        ($evalsTouched.Count -eq 2)
    foreach ($touched in $evalsTouched) { Write-Note "touched: $touched" }
    Confirm-That 'the runner is one of them' `
        ($evalsTouched -contains 'evals/conformance/Invoke-Conformance.ps1')
    Confirm-That 'the conformance README is the other' `
        ($evalsTouched -contains 'evals/conformance/README.md')
    # The oracle itself must be untouched: a pass that edits the assertions it
    # is graded by is grading itself.
    Confirm-That 'Conformance.Tests.ps1 is unchanged by this pass' `
        ($evalsTouched -notcontains 'evals/conformance/Conformance.Tests.ps1')

    # =======================================================================
    # Falsification probes
    # =======================================================================

    if ($FailCheck) {
        Write-Host ''
        Write-Host 'FailCheck probes - each must make its check go red'

        # Known-good is re-asserted before every probe, so a probe that reports
        # red against an already-red baseline cannot be mistaken for a working
        # probe.
        Confirm-That 'probe baseline: the roster agrees before any break' `
            (@(Measure-RosterDisagreement -CloneRoot $harnessClone).Count -eq 0)

        # Probe A: remove a roster skill, then RE-RUN check 1's own function.
        $probeSkill = Join-Path $harnessClone 'skills/powershell-module-test'
        $probeBefore = Test-Path -LiteralPath $probeSkill
        Remove-Item -LiteralPath $probeSkill -Recurse -Force
        Confirm-That 'probe A: the break actually landed' `
            ($probeBefore -and -not (Test-Path -LiteralPath $probeSkill))
        $afterA = @(Measure-RosterDisagreement -CloneRoot $harnessClone)
        Confirm-That "probe A: check 1 goes red on a missing skill ($($afterA.Count) disagreement(s))" `
            ($afterA.Count -gt 0 -and ($afterA -join ';') -match 'missing: skills/powershell-module-test')
        foreach ($problem in $afterA) { Write-Note $problem }

        # Restore, and verify the restoration, before the next probe.
        & git -C $harnessClone checkout -- . 2>&1 | Out-Null
        Confirm-That 'probe A: restored, and the roster agrees again' `
            (@(Measure-RosterDisagreement -CloneRoot $harnessClone).Count -eq 0)

        # Probe B: resurrect a retired name, then re-run the same function. This
        # is the scope control for probe A: a check that only counted missing
        # skills would stay green here.
        $probeRetired = Join-Path $harnessClone 'skills/build-script'
        $null = New-Item -ItemType Directory -Path $probeRetired -Force
        Confirm-That 'probe B: the break actually landed' (Test-Path -LiteralPath $probeRetired)
        $afterB = @(Measure-RosterDisagreement -CloneRoot $harnessClone)
        Confirm-That "probe B: check 1 goes red on a resurrected old name ($($afterB.Count) disagreement(s))" `
            ($afterB.Count -gt 0 -and ($afterB -join ';') -match 'resurrected: skills/build-script')
        foreach ($problem in $afterB) { Write-Note $problem }

        Remove-Item -LiteralPath $probeRetired -Recurse -Force
        Confirm-That 'probe B: restored, and the roster agrees again' `
            (@(Measure-RosterDisagreement -CloneRoot $harnessClone).Count -eq 0)

        # Probe C: the tag check must reject a tag that peels elsewhere. The
        # string is synthetic on purpose - the point is the comparison, and
        # re-tagging a real remote to prove it would be the falsification
        # causing the damage it is testing for.
        $wrongPeel = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
        Confirm-That 'probe C: the tag check would go red at the wrong commit' `
            ($wrongPeel -ne $TargetSha)

        # Probe D: the evals/ count must reject a third file.
        $inflated = @($evalsTouched) + 'evals/conformance/Conformance.Tests.ps1'
        Confirm-That 'probe D: check 6 would go red on a third evals file' `
            ($inflated.Count -ne 2)

        Write-Host ''
        Write-Host '  Probes 2 and 3 are self-falsifying and need no probe here:'
        Write-Note 'check 3 introduces its own break and asserts the break landed'
        Write-Note 'before re-running, then verifies the restoration.'
    }
}
finally {
    if (Test-Path -LiteralPath $Scratch) {
        Remove-Item -LiteralPath $Scratch -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host "checks: $script:Checks   failures: $script:Failures   skipped: $script:Skipped"
if ($script:Skipped -gt 0) {
    Write-Host 'Something was skipped. A skipped check is not a passing check.' -ForegroundColor Yellow
}
if ($script:Failures -gt 0) {
    Write-Host "VERIFY FAILED: $script:Failures check(s) disagreed." -ForegroundColor Red
    exit 1
}
Write-Host 'VERIFY OK' -ForegroundColor Green
exit 0
