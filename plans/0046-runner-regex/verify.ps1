#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0046 made, from the repository, without reading
    the plan.

.DESCRIPTION
    Pass 0046 repaired one character class in evals/conformance/Invoke-Conformance.ps1
    - '[\/]' to '[\\/]' - and added the tests whose absence let four copies of
    one regex drift. LEDGER backlog 62.

    Six checks and five falsification probes. Each check re-derives its answer
    from the repository or from a fresh clone of PSGraphRender, never from
    plan.md, per PLAN-PROTOCOL section 9.

    1. All four copies of the exclusion regex are one identical string, and
       that string excludes a Windows path. Both halves are needed: four
       copies of an equally wrong regex would satisfy the first alone.
    2. The harness's own tests are green, ran more than zero cases, and no
       container failed to load. Zero cases is not a pass and neither is a
       container that never ran.
    3. SC1 - the repair commit touches one file and one line, and the only
       thing that differs on that line is the exclusion literal. The commit is
       FOUND from the history rather than named, so a rebase cannot make this
       compare nothing.
    4. SC2 - CasesDefined is MEASURED at the base commit and at head, both
       times, against the same planted clone, and compared. Nothing is pinned:
       a count measured in one tree and asserted in another reports the tree's
       shape rather than the pass's claim. The runner's discovered container
       list is printed and asserted to hold no file this pass added.
    5. SC3 - this pass changed nothing under skills/, commands/ or
       .claude-plugin/. See the note this check prints: the pass prompt asked
       for the diff against v1.2.0 to be empty, and it is not - it has not been
       since pass 0041, which is LEDGER backlog 56, an unreleased skill edit
       recorded there on purpose. The repository wins over the prompt, so what
       is asserted is the claim the prompt was reaching for and the one that is
       this pass's to make.
    6. Acceptance, both directions: against a planted clone the runner REFUSES
       at the base commit and resolves at head, and the planted scratch/ and
       output/ manifests are candidates at base and are not at head.

    -FailCheck adds the probes. A check that cannot fail has checked nothing,
    so a probe that does NOT fail is itself reported as a failure.

    Writes only under scratch/ and removes what it wrote. Needs a fresh clone
    of this repository and the tools, nothing else.

.PARAMETER RepoRoot
    Harness root - the repository this pass changed. Defaults to two levels
    above this script.
.PARAMETER TargetRemote
    Where to clone PSGraphRender from, for the acceptance and denominator
    checks. Defaults to the origin of the sibling checkout when there is one,
    and to the known remote otherwise, so this runs on a machine that has only
    the harness.
.PARAMETER FailCheck
    Run the deliberate-failure probes.
.EXAMPLE
    ./plans/0046-runner-regex/verify.ps1
.EXAMPLE
    ./plans/0046-runner-regex/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$conformanceDir = Join-Path $RepoRoot 'evals/conformance'
$harnessDir = Join-Path $RepoRoot 'evals/harness'
$extractor = Join-Path $harnessDir 'ExclusionSites.ps1'
foreach ($p in @($conformanceDir, $harnessDir, $extractor)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Not found: $p" }
}
. $extractor

if (-not $TargetRemote) {
    $sibling = Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender'
    if (Test-Path -LiteralPath (Join-Path $sibling '.git')) {
        $TargetRemote = (& git -C $sibling remote get-url origin).Trim()
    }
    else {
        $TargetRemote = 'https://github.com/JerryBalmer1/PSGraphRender.git'
    }
}

$work = Join-Path $RepoRoot 'scratch/verify-0046'
if (@($work -split '[\\/]') -notcontains 'scratch') { throw "Refusing to write outside scratch/: $work" }

$failures = [System.Collections.Generic.List[string]]::new()

function Assert-That {
    param(
        [Parameter(Mandatory)][string] $What,
        [Parameter(Mandatory)][bool] $Ok,
        [string] $Detail = ''
    )
    $suffix = ''
    if ($Detail) { $suffix = " - $Detail" }
    '  [{0}] {1}{2}' -f $(if ($Ok) { 'ok  ' } else { 'FAIL' }), $What, $suffix
    if (-not $Ok) { $script:failures.Add("$What$suffix") }
}

# ------------------------------------------------------------------ helpers
#
# Written as functions over an input so the same code answers for the real
# artifact and for a deliberately damaged copy. A probe running different code
# from the check it probes proves nothing about the check.

function Test-CopiesAgree {
    param([Parameter(Mandatory)][string] $Dir)
    $sites = @(Get-ExclusionSite -ConformanceDir $Dir)
    $distinct = @($sites | ForEach-Object { $_.Pattern } | Sort-Object -Unique)
    [pscustomobject]@{
        Count    = $sites.Count
        Distinct = $distinct.Count
        Ok       = ($sites.Count -ge 4 -and $distinct.Count -eq 1)
        Detail   = "$($sites.Count) copies, $($distinct.Count) distinct: " +
                   (@($sites | ForEach-Object { $_.Site }) -join ', ')
        Pattern  = if ($distinct.Count -ge 1) { $distinct[0] } else { '' }
    }
}

function Test-Sc1Diff {
    <#
        SC1 over the two things a diff yields - the files it touched and its
        unified text - so a probe can hand over a wrong diff without any of
        this code changing.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Files,
        [Parameter(Mandatory)][AllowEmptyString()][string] $DiffText
    )
    $changed = @($DiffText -split "`r?`n" | Where-Object {
            $_ -match '^[-+]' -and $_ -notmatch '^(\+\+\+|---)'
        })
    $added = @($changed | Where-Object { $_.StartsWith('+') })
    $removed = @($changed | Where-Object { $_.StartsWith('-') })
    $offTopic = @($changed | Where-Object { $_ -notmatch 'output\|scratch' })

    $problems = @()
    if ($Files.Count -ne 1) { $problems += "touches $($Files.Count) file(s): $($Files -join ', ')" }
    if ($added.Count -ne 1) { $problems += "adds $($added.Count) line(s), expected 1" }
    if ($removed.Count -ne 1) { $problems += "removes $($removed.Count) line(s), expected 1" }
    if ($offTopic.Count -ne 0) {
        $problems += "$($offTopic.Count) changed line(s) are not the exclusion literal"
    }
    [pscustomobject]@{
        Ok     = ($problems.Count -eq 0)
        Detail = if ($problems.Count) { $problems -join '; ' } else { '1 file, +1/-1, the exclusion literal only' }
    }
}

function Invoke-HarnessSuite {
    <#
        Runs the harness's own tests against one conformance directory and
        reports what happened per Describe, so a probe can assert that the
        RIGHT checks went red rather than merely that something did.
    #>
    param([Parameter(Mandatory)][string] $Dir)

    $runner = Join-Path $harnessDir 'Invoke-HarnessTests.ps1'
    $out = (& pwsh -NoProfile -File $runner -ConformanceDir $Dir -Output Normal 2>&1 | Out-String)
    $exit = $LASTEXITCODE
    $lines = @($out -split "`r?`n")
    $summary = @($lines | Where-Object { $_ -match '^Passed=\d+' })

    # The per-Describe lines the runner prints, not Pester's own output. A
    # failure line in Pester's output carries the test name and not the block
    # it belongs to, so scraping it would answer zero to 'did the polarity pair
    # fail?' and report a firing probe as one that does not fire.
    function Get-DescribeFailed {
        param([string] $Name)
        $line = @($lines | Where-Object { $_ -match "^Describe=$([regex]::Escape($Name)) " })
        if ($line.Count -eq 0) { return -1 }   # absent, which is not zero
        if ($line[0] -match 'Failed=(\d+)') { return [int]$Matches[1] }
        return -1
    }

    [pscustomobject]@{
        Exit            = $exit
        Summary         = if ($summary.Count) { $summary[0] } else { '(no summary line)' }
        Verdict         = @($lines | Where-Object { $_ -match '^VERDICT=' } | Select-Object -Last 1)
        FailedPolarity  = Get-DescribeFailed -Name 'Path exclusion polarity'
        FailedAgreement = Get-DescribeFailed -Name 'Path exclusion copies agree'
    }
}

function Get-RunnerAnswer {
    <#
        What the runner does with a target, using a NAMED conformance directory
        so the base commit's runner and head's runner can both be asked the
        same question about the same tree.

        Returns whether it refused, and the candidate set its own pattern
        produces. Both halves matter: the refusal is the loud direction and the
        candidate set is the silent one.
    #>
    param(
        [Parameter(Mandatory)][string] $Dir,
        [Parameter(Mandatory)][string] $Target,
        [Parameter(Mandatory)][string] $ResultPath
    )
    $runner = Join-Path $Dir 'Invoke-Conformance.ps1'
    $out = (& pwsh -NoProfile -File $runner -Path $Target -ResultPath $ResultPath 2>&1 | Out-String)
    $refused = [bool]($out -match 'Cannot derive -ModuleName')

    $sites = @(Get-ExclusionSite -ConformanceDir $Dir |
            Where-Object { $_.File -eq 'Invoke-Conformance.ps1' })
    $candidates = @()
    if ($sites.Count -ge 1) {
        $pattern = $sites[0].Pattern
        $candidates = @(Get-ChildItem -Path $Target -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.BaseName -eq $_.Directory.Name -or
                    ($_.Directory.Name -match '^\d+(\.\d+)*([-+].*)?$' -and
                        $_.Directory.Parent -and $_.BaseName -eq $_.Directory.Parent.Name)
                } |
                Where-Object { $_.FullName.Substring($Target.Length) -notmatch $pattern } |
                ForEach-Object { $_.FullName.Substring($Target.Length).TrimStart('\', '/') } |
                Sort-Object)
    }
    [pscustomobject]@{
        Refused    = $refused
        Candidates = $candidates
        Message    = if ($refused) { @($out -split "`r?`n" | Where-Object { $_ -match 'Cannot derive' })[0] } else { '' }
    }
}

function Get-CasesDefined {
    param(
        [Parameter(Mandatory)][string] $Dir,
        [Parameter(Mandatory)][string] $Target,
        [Parameter(Mandatory)][string] $ResultPath
    )
    $runner = Join-Path $Dir 'Invoke-Conformance.ps1'
    # -ModuleName is passed explicitly. The runner's own derivation is what
    # check 6 is about; letting it vary here would put a second variable into a
    # comparison of one.
    & pwsh -NoProfile -File $runner -Path $Target -ModuleName 'PSGraphRender' -ResultPath $ResultPath *> $null
    Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json
}

function Copy-TreeAtRef {
    <#
        A directory as it stood at a commit, materialised under scratch/.
        git show per file rather than a worktree or a second clone, so nothing
        about the caller's repository state is changed by verifying it.
    #>
    param(
        [Parameter(Mandatory)][string] $Ref,
        [Parameter(Mandatory)][string] $TreePath,
        [Parameter(Mandatory)][string] $Destination
    )
    $null = New-Item -ItemType Directory -Path $Destination -Force
    $names = @(& git -C $RepoRoot ls-tree -r --name-only $Ref -- $TreePath)
    if ($names.Count -eq 0) { throw "No files under '$TreePath' at $Ref." }
    foreach ($name in $names) {
        $relative = $name.Substring($TreePath.Length).TrimStart('/')
        $dest = Join-Path $Destination $relative
        $parent = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        $bytes = & git -C $RepoRoot show "${Ref}:$name"
        Set-Content -LiteralPath $dest -Value ($bytes -join "`n") -Encoding utf8
    }
    $names.Count
}

function Add-PlantedManifest {
    param([Parameter(Mandatory)][string] $Clone)
    $real = Join-Path $Clone 'src/PSGraphRender/PSGraphRender.psd1'
    if (-not (Test-Path -LiteralPath $real)) { throw "No src manifest in the clone: $real" }
    foreach ($rel in @('output/PSGraphRender/PSGraphRender.psd1', 'scratch/Fake/Fake.psd1')) {
        $dest = Join-Path $Clone $rel
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force
        Copy-Item -LiteralPath $real -Destination $dest -Force
        if (-not (Test-Path -LiteralPath $dest)) { throw "Plant did not land: $dest" }
    }
}

# --------------------------------------------------------------------- run

try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $work -Force

    ''
    'VERIFY 0046 - runner path-exclusion regex'
    "  repository:    $RepoRoot"
    "  target remote: $TargetRemote"

    # Two commits, FOUND rather than named, and they answer different
    # questions. Both survive a rebase and both survive the fast-forward to
    # main - a merge-base against origin/main would collapse to HEAD once the
    # pass has landed, and would then compare nothing while reporting green.
    #
    # REPAIR is the commit that last touched the runner. SC1 is about that
    # commit alone: it must be one file and one line.
    #
    # PASS BASE is the parent of the commit that introduced this plan
    # directory - the state of the repository before the pass began. SC2 and
    # SC3 are about the whole pass, not about one commit inside it.
    $repairCommit = (& git -C $RepoRoot log -1 --format=%H -- 'evals/conformance/Invoke-Conformance.ps1').Trim()
    if (-not $repairCommit) { throw 'No commit touches evals/conformance/Invoke-Conformance.ps1.' }
    $repairBase = (& git -C $RepoRoot rev-parse "$repairCommit^").Trim()

    $firstCommit = @(& git -C $RepoRoot log --diff-filter=A --format=%H -- 'plans/0046-runner-regex/accept.ps1')
    if ($firstCommit.Count -eq 0) { throw 'No commit introduces plans/0046-runner-regex/accept.ps1.' }
    $base = (& git -C $RepoRoot rev-parse "$($firstCommit[-1].Trim())^").Trim()
    $head = (& git -C $RepoRoot rev-parse HEAD).Trim()
    "  repair commit: $(& git -C $RepoRoot log -1 --format='%h %s' $repairCommit)"
    "  repair base:   $($repairBase.Substring(0,7))   (SC1)"
    "  pass base:     $($base.Substring(0,7))   (SC2, SC3 - the state before the pass began)"
    ''

    # ------------------------------------------------------------------ 1
    '1. All four copies of the exclusion regex are one string, and it sees a backslash'
    $c1 = Test-CopiesAgree -Dir $conformanceDir
    Assert-That -What 'four or more copies, exactly one distinct string' -Ok $c1.Ok -Detail $c1.Detail
    Assert-That -What 'that string excludes a Windows-style path under scratch' `
        -Ok ('\scratch\Fake\Fake.psd1' -match $c1.Pattern) -Detail $c1.Pattern
    Assert-That -What 'that string does not exclude a src/-side manifest' `
        -Ok ('\src\PSGraphRender\PSGraphRender.psd1' -notmatch $c1.Pattern) -Detail $c1.Pattern
    ''

    # ------------------------------------------------------------------ 2
    "2. The harness's own tests, against the repository's conformance directory"
    $c2 = Invoke-HarnessSuite -Dir $conformanceDir
    "  $($c2.Summary)"
    Assert-That -What 'harness tests exit 0' -Ok ($c2.Exit -eq 0) -Detail "exit $($c2.Exit), $($c2.Verdict)"
    Assert-That -What 'the harness tests ran at all (not zero cases, no broken container)' `
        -Ok ($c2.Summary -match 'Ran=(\d+)' -and [int]$Matches[1] -gt 0 -and $c2.Summary -match 'BrokenContainers=0') `
        -Detail $c2.Summary
    ''

    # ------------------------------------------------------------------ 3
    '3. SC1 - the repair is one file, one line, the exclusion literal only'
    $files = @(& git -C $RepoRoot diff --name-only $repairBase $repairCommit | Where-Object { $_ })
    $diffText = (& git -C $RepoRoot diff $repairBase $repairCommit) -join "`n"
    $c3 = Test-Sc1Diff -Files $files -DiffText $diffText
    Assert-That -What 'SC1: minimal repair diff' -Ok $c3.Ok -Detail $c3.Detail
    ''

    # ------------------------------------------------------------------ 4/6
    #
    # One clone serves both, because both ask about the same planted tree and
    # cloning it twice would let them disagree about what they were asking of.
    '4/6. A planted clone of PSGraphRender: denominator, and both defect directions'
    $clone = Join-Path $work 'PSGraphRender'
    & git clone --quiet $TargetRemote $clone 2>&1 | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $clone '.git'))) { throw "Clone failed: $TargetRemote" }
    $cloneHead = (& git -C $clone rev-parse --short HEAD).Trim()
    Add-PlantedManifest -Clone $clone
    "  clone: main @ $cloneHead, with output/ and scratch/ manifests planted"

    $baseDir = Join-Path $work 'conformance-at-base'
    $count = Copy-TreeAtRef -Ref $base -TreePath 'evals/conformance' -Destination $baseDir
    "  conformance directory at base: $count file(s) materialised"

    $baseResult = Get-CasesDefined -Dir $baseDir -Target $clone -ResultPath (Join-Path $work 'base.json')
    $headResult = Get-CasesDefined -Dir $conformanceDir -Target $clone -ResultPath (Join-Path $work 'head.json')
    "  base: CasesDefined=$($baseResult.CasesDefined) CasesRun=$($baseResult.CasesRun)"
    "  head: CasesDefined=$($headResult.CasesDefined) CasesRun=$($headResult.CasesRun)"
    Assert-That -What 'SC2: CasesDefined unchanged between base and head' `
        -Ok ($baseResult.CasesDefined -eq $headResult.CasesDefined) `
        -Detail "base $($baseResult.CasesDefined), head $($headResult.CasesDefined)"
    Assert-That -What 'SC2: CasesRun unchanged between base and head' `
        -Ok ($baseResult.CasesRun -eq $headResult.CasesRun) `
        -Detail "base $($baseResult.CasesRun), head $($headResult.CasesRun)"

    # The discovered set, printed. This is the scope the series guard is about:
    # the runner discovers *.Tests.ps1 in its OWN directory, not recursively.
    $discovered = @(Get-ChildItem -LiteralPath $conformanceDir -Filter *.Tests.ps1 -File |
            Sort-Object Name | ForEach-Object { $_.Name })
    $harnessTests = @(Get-ChildItem -LiteralPath $harnessDir -Filter *.Tests.ps1 -File |
            ForEach-Object { $_.Name })
    "  discovered containers ($($discovered.Count)): $($discovered -join ', ')"
    "  harness test files ($($harnessTests.Count)): $($harnessTests -join ', ')"
    Assert-That -What 'SC2: no file this pass added is in the discovered set' `
        -Ok (@($discovered | Where-Object { $harnessTests -contains $_ }).Count -eq 0) `
        -Detail "discovered: $($discovered -join ', ')"
    Assert-That -What 'SC2: the discovered set is the two known containers' `
        -Ok (@(Compare-Object $discovered @('Conformance.Tests.ps1', 'Help.Tests.ps1')).Count -eq 0) `
        -Detail ($discovered -join ', ')
    Assert-That -What 'SC2: the harness tests exist and are not empty' `
        -Ok ($harnessTests.Count -ge 1) -Detail "$($harnessTests.Count) file(s)"
    ''

    '   both defect directions, base against head'
    $atBase = Get-RunnerAnswer -Dir $baseDir -Target $clone -ResultPath (Join-Path $work 'derive-base.json')
    $atHead = Get-RunnerAnswer -Dir $conformanceDir -Target $clone -ResultPath (Join-Path $work 'derive-head.json')
    "   base candidates ($($atBase.Candidates.Count)): $($atBase.Candidates -join '; ')"
    "   head candidates ($($atHead.Candidates.Count)): $($atHead.Candidates -join '; ')"
    Assert-That -What 'refusal direction: the runner REFUSED at base' -Ok $atBase.Refused `
        -Detail $(if ($atBase.Refused) { 'and the message named the src/ ambiguity' } else { 'it did not refuse - this check has stopped being able to fail' })
    Assert-That -What 'refusal direction: the runner resolves at head' -Ok (-not $atHead.Refused) `
        -Detail $(if ($atHead.Refused) { $atHead.Message } else { 'no refusal' })
    Assert-That -What 'admission direction: the scratch/ plant WAS a candidate at base' `
        -Ok ($atBase.Candidates -contains 'scratch\Fake\Fake.psd1') `
        -Detail "$($atBase.Candidates.Count) candidates at base"
    Assert-That -What 'admission direction: the scratch/ plant is NOT a candidate at head' `
        -Ok ($atHead.Candidates -notcontains 'scratch\Fake\Fake.psd1') `
        -Detail "$($atHead.Candidates.Count) candidates at head"
    Assert-That -What 'admission direction: the output/ plant is NOT a candidate at head' `
        -Ok ($atHead.Candidates -notcontains 'output\PSGraphRender\PSGraphRender.psd1') `
        -Detail "$($atHead.Candidates.Count) candidates at head"
    ''

    # ------------------------------------------------------------------ 5
    '5. SC3 - the plugin surface, untouched by this pass'
    #
    # The prompt asked for `git diff v1.2.0..HEAD -- skills/ commands/
    # .claude-plugin/` to be empty. It is NOT, and has not been since pass
    # 0041: skills/powershell-module-ux/SKILL.md carries an error-message
    # standard that no released tag has, which is LEDGER backlog 56, recorded
    # there deliberately. Asserting the prompt's form would fail for a reason
    # that has nothing to do with this pass, so what is asserted is this pass's
    # own claim - it changed nothing under those paths - which is what the
    # prompt was reaching for. Pass 0031 met the same stale pin and did the
    # same thing.
    $surface = @(& git -C $RepoRoot diff --name-only "$base" $head -- 'skills/' 'commands/' '.claude-plugin/' |
            Where-Object { $_ })
    Assert-That -What 'SC3: this pass changed nothing under skills/, commands/, .claude-plugin/' `
        -Ok ($surface.Count -eq 0) -Detail "$($surface.Count) file(s): $($surface -join ', ')"

    $sinceTag = @(& git -C $RepoRoot diff --name-only 'v1.2.0' $head -- 'skills/' 'commands/' '.claude-plugin/' |
            Where-Object { $_ })
    "  for the record, v1.2.0..HEAD over the same paths: $($sinceTag.Count) file(s) - $($sinceTag -join ', ')"
    '  that is LEDGER backlog 56 and predates this pass; see the comment in this script.'
    ''

    # -------------------------------------------------------------- probes
    if ($FailCheck) {
        '-FailCheck: the deliberate-failure probes'
        $probeRoot = Join-Path $work 'probe'
        $null = New-Item -ItemType Directory -Path $probeRoot -Force

        # P1 - the pre-repair spelling restored. Both named checks must go red.
        $p1Dir = Join-Path $probeRoot 'pre-repair'
        Copy-Item -LiteralPath $conformanceDir -Destination $p1Dir -Recurse -Force
        $p1File = Join-Path $p1Dir 'Invoke-Conformance.ps1'
        $good = Get-Content -LiteralPath $p1File -Raw
        $bad = $good -replace [regex]::Escape('[\\/](output|scratch'), '[\/](output|scratch' `
            -replace [regex]::Escape('node_modules)[\\/]'), 'node_modules)[\/]'
        Assert-That -What 'P1 probe actually restored the pre-repair spelling' -Ok ($bad -ne $good) `
            -Detail 'a substitution that matched nothing would be recorded as a passing check'
        Set-Content -LiteralPath $p1File -Value $bad -Encoding utf8 -NoNewline

        $p1 = Invoke-HarnessSuite -Dir $p1Dir
        "  P1: $($p1.Summary)  exit=$($p1.Exit)"
        Assert-That -What 'P1: the harness tests go red on the pre-repair spelling' -Ok ($p1.Exit -ne 0) `
            -Detail "exit $($p1.Exit), $($p1.Verdict)"
        Assert-That -What 'P1: the POLARITY pair is among the reds' -Ok ($p1.FailedPolarity -gt 0) `
            -Detail "$($p1.FailedPolarity) polarity case(s) red"
        Assert-That -What 'P1: COPIES-AGREE is among the reds' -Ok ($p1.FailedAgreement -gt 0) `
            -Detail "$($p1.FailedAgreement) agreement case(s) red"

        $p1c = Test-CopiesAgree -Dir $p1Dir
        Assert-That -What 'P1: check 1 goes red on the pre-repair spelling' -Ok (-not $p1c.Ok) -Detail $p1c.Detail

        # P2 - one site altered to a SEMANTICALLY IDENTICAL spelling. Only
        # copies-agree may fail. This is what separates the two checks: if
        # polarity also went red here, the agreement check would be riding on
        # the polarity check and would not be an independent guard at all.
        $p2Dir = Join-Path $probeRoot 'one-site'
        Copy-Item -LiteralPath $conformanceDir -Destination $p2Dir -Recurse -Force
        $p2File = Join-Path $p2Dir 'Conformance.Tests.ps1'
        $lines = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $p2File).Path)
        $altered = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match [regex]::Escape('[\\/](output|scratch')) {
                $lines[$i] = $lines[$i].Replace('[\\/]', '[/\\]')
                $altered = $true
                break
            }
        }
        Assert-That -What 'P2 probe actually altered one site' -Ok $altered `
            -Detail 'and only one, to a spelling that means exactly the same thing'
        [System.IO.File]::WriteAllLines((Resolve-Path -LiteralPath $p2File).Path, $lines)

        $p2 = Invoke-HarnessSuite -Dir $p2Dir
        "  P2: $($p2.Summary)  exit=$($p2.Exit)"
        Assert-That -What 'P2: the harness tests go red on one altered site' -Ok ($p2.Exit -ne 0) `
            -Detail "exit $($p2.Exit), $($p2.Verdict)"
        Assert-That -What 'P2: COPIES-AGREE is red' -Ok ($p2.FailedAgreement -gt 0) `
            -Detail "$($p2.FailedAgreement) agreement case(s) red"
        Assert-That -What 'P2: POLARITY stays green, which is what makes the two checks independent' `
            -Ok ($p2.FailedPolarity -eq 0) -Detail "$($p2.FailedPolarity) polarity case(s) red"

        # P3 - SC1 against a diff that touches a second site and a second file.
        $badDiff = @(
            'diff --git a/evals/conformance/Invoke-Conformance.ps1 b/evals/conformance/Invoke-Conformance.ps1',
            '--- a/evals/conformance/Invoke-Conformance.ps1',
            '+++ b/evals/conformance/Invoke-Conformance.ps1',
            "-                    '[\/](output|scratch|\.git|gallery|fixtures|node_modules)[\/]'",
            "+                    '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'",
            '-    $config.Output.Verbosity = ''Detailed''',
            '+    $config.Output.Verbosity = ''Normal'''
        ) -join "`n"
        $p3 = Test-Sc1Diff -Files @('evals/conformance/Invoke-Conformance.ps1', 'evals/conformance/Help.Tests.ps1') -DiffText $badDiff
        Assert-That -What 'P3: SC1 goes red on a diff touching a second file and an unrelated line' `
            -Ok (-not $p3.Ok) -Detail $p3.Detail

        # P4a - SC2's denominator clause. A container carrying a SELECTED tag,
        # dropped into the inventoried scope, must move CasesDefined. This is
        # the clause that would report an improvement while the numerator grew.
        $p4aDir = Join-Path $probeRoot 'inventory-growth-tagged'
        Copy-Item -LiteralPath $conformanceDir -Destination $p4aDir -Recurse -Force
        $tagged = @(
            "Describe 'Inventory growth probe' -Tag 'HouseStyle' {",
            "    It 'is one extra It inside the inventoried scope' { 1 | Should -Be 1 }",
            '}'
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $p4aDir 'Zz-Probe.Tests.ps1') -Value $tagged -Encoding utf8

        $p4aResult = Get-CasesDefined -Dir $p4aDir -Target $clone -ResultPath (Join-Path $work 'probe4a.json')
        "  P4a: CasesDefined $($headResult.CasesDefined) -> $($p4aResult.CasesDefined)"
        Assert-That -What 'P4a: SC2 goes red - CasesDefined moves when a tagged container enters the scope' `
            -Ok ($p4aResult.CasesDefined -ne $headResult.CasesDefined) `
            -Detail "head $($headResult.CasesDefined), probe $($p4aResult.CasesDefined)"

        # P4b - SC2's discovery clause, and it is worse than a moved
        # denominator. This pass's own test file, copied into the inventoried
        # scope, is DISCOVERED by the conformance runner and then fails to
        # load, because its BeforeDiscovery looks for a conformance directory
        # beside itself and there is none. The runner refuses to report a score
        # at all. That is why placement is the guard: the Harness tag keeps the
        # denominator still, and does nothing whatever about this.
        $p4bDir = Join-Path $probeRoot 'inventory-growth-harness'
        Copy-Item -LiteralPath $conformanceDir -Destination $p4bDir -Recurse -Force
        Copy-Item -LiteralPath (Join-Path $harnessDir 'ExclusionPattern.Tests.ps1') `
            -Destination (Join-Path $p4bDir 'ExclusionPattern.Tests.ps1') -Force

        $p4bDiscovered = @(Get-ChildItem -LiteralPath $p4bDir -Filter *.Tests.ps1 -File |
                Sort-Object Name | ForEach-Object { $_.Name })
        Assert-That -What 'P4b probe actually grew the discovered set' `
            -Ok ($p4bDiscovered.Count -gt $discovered.Count) `
            -Detail "$($discovered.Count) -> $($p4bDiscovered.Count): $($p4bDiscovered -join ', ')"
        Assert-That -What 'P4b: SC2 goes red - a harness test file inside the scope is discovered' `
            -Ok ($p4bDiscovered -contains 'ExclusionPattern.Tests.ps1') `
            -Detail ($p4bDiscovered -join ', ')

        $p4bRunner = Join-Path $p4bDir 'Invoke-Conformance.ps1'
        $p4bOut = (& pwsh -NoProfile -File $p4bRunner -Path $clone -ModuleName 'PSGraphRender' `
                -ResultPath (Join-Path $work 'probe4b.json') 2>&1 | Out-String)
        $p4bRefused = [bool]($p4bOut -match 'container\(s\) failed to run')
        Assert-That -What 'P4b: the conformance runner then reports no score at all' -Ok $p4bRefused `
            -Detail $(if ($p4bRefused) { 'refused: a container that did not run is a missing measurement' }
                      else { 'it reported a score, which is the outcome this placement rule exists to prevent' })

        # P5 - SC3 against a range that does touch the plugin surface. The
        # v1.2.0 range measured in check 5 is the known-bad input, and it is
        # non-empty for a reason this pass did not create.
        Assert-That -What 'P5: SC3 goes red on a range that does touch skills/' `
            -Ok ($sinceTag.Count -gt 0) `
            -Detail "v1.2.0..HEAD: $($sinceTag -join ', ')"
        ''
    }
}
catch {
    # Without this the script prints its error and still exits 0, because a
    # terminating error skips the exit lines below and $LASTEXITCODE is never
    # set. A verify script reporting success while crashing is a false green in
    # the one artifact whose job is to disprove the plan; pass 0044's verifier
    # did exactly that, and this is the fix it landed.
    ''
    'VERIFY 0046: ERROR - the script could not complete, so nothing below it ran.'
    "  $($_.Exception.Message)"
    "  at $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())"
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    exit 99
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failures.Count) {
    "VERIFY 0046: FAIL - $($failures.Count) check(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'VERIFY 0046: PASS - every check re-derived and agreed.'
exit 0
