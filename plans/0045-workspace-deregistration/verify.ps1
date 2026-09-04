#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0045 made, from a fresh clone of PSGraphRender,
    without reading the plan.

.DESCRIPTION
    Pass 0045 deleted one folder object from PSGraphRender.code-workspace, the
    violation the 'Workspace composition' assertion (added by pass 0044) found on
    its first run against the real repositories. LEDGER backlog 60.

    Five checks. Each re-derives its answer from a repository rather than from
    plan.md, per PLAN-PROTOCOL section 9.

    1. The workspace file at the pass branch does not register PSModuleGraph,
       read semantically - JSONC stripped, folders[].path split on separators -
       by the same rule the suite's assertion uses.
    2. The acceptance instrument itself: the harness's 'Workspace composition'
       assertion, run against the clone, green. Broken containers are counted
       separately, so a discovery failure can never be reported as a green.
    3. SC1 - the workspace commit touches exactly one file, adds no lines, and
       removes exactly one folder object, with the settings block untouched.
    4. SC2 - the suite still discovers against the target. CasesRun at the base
       commit and at the branch head are MEASURED, both times, and compared.
       Nothing is pinned: a count measured in one tree shape and asserted in
       another is a pin that reports the tree's shape rather than the pass's
       claim.
    5. The entry was present at the base commit and absent at the branch head -
       an amendment, not an invention. The base is re-derived with merge-base
       rather than named, so a re-base cannot silently make this compare
       nothing.

    Two repositories are involved and only one of them is cloned. PSGraphRender
    is what this pass changed, so it comes from its remote rather than from any
    tree on this machine. The harness is the INSTRUMENT - it supplies the
    conformance suite - and is used where this script sits, because a script
    cannot verify an instrument by fetching a second copy of itself.

    Writes only under scratch/ and removes what it wrote.

.PARAMETER RepoRoot
    Harness root, which supplies the conformance suite. Defaults to two levels
    above this script.
.PARAMETER TargetRemote
    Where to clone PSGraphRender from. Defaults to the origin of the sibling
    checkout when there is one, and to the known remote otherwise, so this runs
    on a machine that has only the harness.
.PARAMETER Branch
    Branch of PSGraphRender to verify. Defaults to the pass branch, falling back
    to main once it has landed.
.PARAMETER FailCheck
    Run the deliberate-failure probes. A scratch copy of the clone has the
    ../PSModuleGraph entry RESTORED, and the acceptance assertion plus check 1
    are re-run against it and must go red; SC1 is re-run against a diff that
    also edits settings and touches a second file, and must go red. A check that
    cannot fail has checked nothing, so a probe that does NOT fail is itself
    reported as a failure.
.EXAMPLE
    ./plans/0045-workspace-deregistration/verify.ps1
.EXAMPLE
    ./plans/0045-workspace-deregistration/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $Branch = 'pass-0045-workspace-deregistration',
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$suite = Join-Path $RepoRoot 'evals/conformance/Conformance.Tests.ps1'
if (-not (Test-Path -LiteralPath $suite)) { throw "Conformance suite not found: $suite" }

if (-not $TargetRemote) {
    $sibling = Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender'
    if (Test-Path -LiteralPath (Join-Path $sibling '.git')) {
        $TargetRemote = (& git -C $sibling remote get-url origin).Trim()
    }
    else {
        $TargetRemote = 'https://github.com/JerryBalmer1/PSGraphRender.git'
    }
}

$work = Join-Path $RepoRoot 'scratch/verify-0045'
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

# ---------------------------------------------------------------- spot-checks
#
# Written as functions over an input so that the same code answers for the real
# artifact and for a deliberately damaged copy. A probe that runs different code
# from the check it is probing proves nothing about the check.

function Test-NoRegistration {
    <#
        Check 1, and the -FailCheck probe for it. Semantic, not a text match:
        the registration is a folder entry, and a file that merely NAMES
        PSModuleGraph - in a comment, in a settings value - is not registering
        it. A text match would fire on every file that documents the rule.
    #>
    param([Parameter(Mandatory)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Ok = $false; Detail = "no such file: $Path" }
    }
    $raw = Get-Content -LiteralPath $Path -Raw

    # .code-workspace is JSONC. Strip whole-line comments only; a // inside a
    # string would be a URL.
    $stripped = ($raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"

    $doc = $null
    try { $doc = $stripped | ConvertFrom-Json } catch { }
    if (-not $doc) {
        return [pscustomobject]@{ Ok = $false; Detail = 'does not parse as JSON' }
    }

    $paths = @()
    if ($doc.PSObject.Properties.Name -contains 'folders') {
        $paths = @($doc.folders | ForEach-Object {
                if ($_.PSObject.Properties.Name -contains 'path') { $_.path }
            })
    }
    # Segment-wise, so ../PSModuleGraphTools does not match and ../x/PSModuleGraph does.
    $registered = @($paths | Where-Object { @($_ -split '[\\/]') -contains 'PSModuleGraph' })

    return [pscustomobject]@{
        Ok     = ($registered.Count -eq 0)
        Detail = if ($registered.Count) { "registers $($registered -join ', ')" }
                 else { "folders: $($paths -join ', ')" }
    }
}

function Test-Sc1 {
    <#
        Check 3, and the -FailCheck probe for it. Takes the two things a diff
        yields - the names of the files it touched and its unified text - so the
        probe can hand over a diff that is wrong in the two ways the prompt named
        without any of this code changing.
    #>
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]] $Files,
        [Parameter(Mandatory)][AllowEmptyString()][string] $DiffText
    )

    $changed = @($DiffText -split "`r?`n" | Where-Object {
            $_ -match '^[-+]' -and $_ -notmatch '^(\+\+\+|---)'
        })
    $added   = @($changed | Where-Object { $_.StartsWith('+') })
    $removed = @($changed | Where-Object { $_.StartsWith('-') })
    $removedFolderObjects = @($removed | Where-Object { $_ -match '"path"\s*:' })
    $touchesSettings = @($changed | Where-Object { $_ -match 'settings' })

    $problems = @()
    if ($Files.Count -ne 1) { $problems += "touches $($Files.Count) files: $($Files -join ', ')" }
    if ($added.Count -ne 0) { $problems += "adds $($added.Count) line(s)" }
    if ($removedFolderObjects.Count -ne 1) {
        $problems += "removes $($removedFolderObjects.Count) folder path line(s), expected 1"
    }
    if ($touchesSettings.Count -ne 0) {
        $problems += "changes $($touchesSettings.Count) line(s) mentioning settings"
    }

    return [pscustomobject]@{
        Ok     = ($problems.Count -eq 0)
        Detail = if ($problems.Count) { $problems -join '; ' }
                 else { "1 file, +0/-$($removed.Count), one folder object removed, settings untouched" }
    }
}

function Invoke-WorkspaceAssertion {
    <#
        Runs ONLY the 'Workspace composition' block against one target and
        returns its counts. Filtered by name rather than by tag so that a failure
        elsewhere in the suite cannot be mistaken for this assertion.

        A failed container is discovery blowing up and must never be reported as
        ZERO CASES, and ZERO CASES must never be reported as a pass. Both
        distinctions cost pass 0044 a run.
    #>
    param([Parameter(Mandatory)][string] $Target)

    $prevTarget = $env:CONFORMANCE_TARGET
    $prevName   = $env:CONFORMANCE_MODULE_NAME
    $env:CONFORMANCE_TARGET = $Target
    $env:CONFORMANCE_MODULE_NAME = 'PSGraphRender'
    try {
        $cfg = New-PesterConfiguration
        $cfg.Run.Path = $suite
        $cfg.Run.PassThru = $true
        $cfg.Filter.FullName = '*Workspace composition*'
        $cfg.Output.Verbosity = 'None'
        $r = Invoke-Pester -Configuration $cfg

        $broken = @($r.Containers | Where-Object { $_.Result -ne 'Passed' -and $_.ErrorRecord })
        if ($broken.Count) {
            return [pscustomobject]@{
                Passed = 0; Failed = 0; Verdict = 'DISCOVERY FAILED'
                Detail = [string]$broken[0].ErrorRecord
            }
        }
        return [pscustomobject]@{
            Passed  = $r.PassedCount
            Failed  = $r.FailedCount
            Detail  = "passed $($r.PassedCount), failed $($r.FailedCount)"
            Verdict = if ($r.FailedCount -gt 0) { 'RED' }
                      elseif ($r.PassedCount -gt 0) { 'GREEN' }
                      else { 'ZERO CASES' }
        }
    }
    finally {
        $env:CONFORMANCE_TARGET = $prevTarget
        $env:CONFORMANCE_MODULE_NAME = $prevName
    }
}

function Get-CasesRun {
    <#
        Check 4. Runs the whole suite through the harness runner and returns what
        it discovered. -ModuleName is passed explicitly: the runner's own
        derivation is not what this check is about, and letting it vary would put
        a second variable into a comparison of one.
    #>
    param(
        [Parameter(Mandatory)][string] $Target,
        [Parameter(Mandatory)][string] $ResultPath
    )
    $runner = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'
    & $runner -Path $Target -ModuleName 'PSGraphRender' -ResultPath $ResultPath *> $null
    $d = Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json
    return $d
}

# --------------------------------------------------------------------- run

try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $work -Force

    ''
    "VERIFY 0045 - workspace deregistration"
    "  harness (instrument): $RepoRoot"
    "  target remote:        $TargetRemote"
    ''

    # The clone directory is named PSGraphRender on purpose: the suite resolves
    # its manifest partly by comparing the target's leaf name, and a directory
    # named 'clone' would be answering a different question from the real one.
    $clone = Join-Path $work 'PSGraphRender'
    & git clone --quiet $TargetRemote $clone 2>&1 | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $clone '.git'))) {
        throw "Clone failed: $TargetRemote"
    }

    # Asked by LISTING the remote branches rather than by rev-parse --verify on
    # the one wanted. pwsh 7.4 turned $PSNativeCommandUseErrorActionPreference on
    # by default, so a native command that exits non-zero under
    # $ErrorActionPreference = 'Stop' now throws - and "this branch is absent" is
    # the expected answer here, not an error.
    $remoteBranches = @(& git -C $clone branch -r --format='%(refname:short)')
    $branchToUse = $Branch
    if ($remoteBranches -notcontains "origin/$Branch") {
        $branchToUse = 'main'
        "  branch '$Branch' not on the remote - verifying 'main', where it will have landed"
    }
    & git -C $clone checkout --quiet $branchToUse
    $head = (& git -C $clone rev-parse --short HEAD).Trim()
    "  verifying: $branchToUse @ $head"
    ''

    $wsFile = Join-Path $clone 'PSGraphRender.code-workspace'

    # ------------------------------------------------------------------ 1
    '1. The workspace file does not register PSModuleGraph'
    $c1 = Test-NoRegistration -Path $wsFile
    Assert-That -What 'workspace file registers no PSModuleGraph folder' -Ok $c1.Ok -Detail $c1.Detail
    ''

    # ------------------------------------------------------------------ 2
    '2. Acceptance: the harness assertion, against the clone'
    $c2 = Invoke-WorkspaceAssertion -Target $clone
    Assert-That -What 'Workspace composition is GREEN' -Ok ($c2.Verdict -eq 'GREEN') `
        -Detail "$($c2.Verdict) - $($c2.Detail)"
    Assert-That -What 'the assertion ran at all (not ZERO CASES, not a discovery failure)' `
        -Ok ($c2.Passed + $c2.Failed -eq 1) -Detail "cases: $($c2.Passed + $c2.Failed)"
    ''

    # ------------------------------------------------------------------ 3
    '3. SC1 - the workspace commit is one file and one folder object'
    $base = (& git -C $clone merge-base origin/main HEAD).Trim()
    if ($branchToUse -eq 'main') {
        # After the fast-forward there is no fork point to take. The workspace
        # commit is the one that last touched the file, and it is found rather
        # than named.
        $wsCommit = (& git -C $clone log -1 --format=%H -- 'PSGraphRender.code-workspace').Trim()
        $base = (& git -C $clone rev-parse "$wsCommit^").Trim()
    }
    else {
        $wsCommit = (& git -C $clone log -1 --format=%H -- 'PSGraphRender.code-workspace').Trim()
    }
    Assert-That -What 'workspace commit resolved' -Ok ([bool]$wsCommit) `
        -Detail (& git -C $clone log -1 --format='%h %s' $wsCommit)

    $files = @(& git -C $clone diff --name-only "$wsCommit^" $wsCommit | Where-Object { $_ })
    $diffText = (& git -C $clone diff "$wsCommit^" $wsCommit) -join "`n"
    $c3 = Test-Sc1 -Files $files -DiffText $diffText
    Assert-That -What 'SC1: one file, no additions, one folder object removed, settings untouched' `
        -Ok $c3.Ok -Detail $c3.Detail
    ''

    # ------------------------------------------------------------------ 4
    '4. SC2 - the suite still discovers against the target'
    $headResult = Get-CasesRun -Target $clone -ResultPath (Join-Path $work 'head.json')

    & git -C $clone checkout --quiet $base
    $baseResult = Get-CasesRun -Target $clone -ResultPath (Join-Path $work 'base.json')
    & git -C $clone checkout --quiet $branchToUse

    Assert-That -What 'CasesRun is unchanged by the edit' `
        -Ok ($headResult.CasesRun -eq $baseResult.CasesRun) `
        -Detail "base $($baseResult.CasesRun), head $($headResult.CasesRun)"
    Assert-That -What 'CasesDefined is unchanged by the edit' `
        -Ok ($headResult.CasesDefined -eq $baseResult.CasesDefined) `
        -Detail "base $($baseResult.CasesDefined), head $($headResult.CasesDefined)"
    Assert-That -What 'exactly one failure fewer at head than at base' `
        -Ok ($headResult.Failed -eq $baseResult.Failed - 1) `
        -Detail "base failed $($baseResult.Failed), head failed $($headResult.Failed)"

    # The one that moved must be THIS one. A pass that fixed some other assertion
    # by accident would satisfy the counts above and nothing else here.
    $movedName = 'Workspace composition.does not register PSModuleGraph as a folder: <_.Rel>'
    $baseLine = @($baseResult.Assertions | Where-Object { $_.Name -eq $movedName })
    $headLine = @($headResult.Assertions | Where-Object { $_.Name -eq $movedName })
    Assert-That -What 'the workspace assertion is red at base' `
        -Ok ($baseLine.Count -eq 1 -and $baseLine[0].Failed -eq 1) `
        -Detail $(if ($baseLine.Count) { "ran $($baseLine[0].Ran), passed $($baseLine[0].Passed), failed $($baseLine[0].Failed)" } else { 'score line absent' })
    Assert-That -What 'the workspace assertion is green at head' `
        -Ok ($headLine.Count -eq 1 -and $headLine[0].Passed -eq 1 -and $headLine[0].Failed -eq 0) `
        -Detail $(if ($headLine.Count) { "ran $($headLine[0].Ran), passed $($headLine[0].Passed), failed $($headLine[0].Failed)" } else { 'score line absent' })

    # And nothing else moved. Compared by score line rather than by count, so a
    # pair of offsetting changes cannot pass.
    $fmt = { param($a) $a | ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.Name, $_.Ran, $_.Passed, $_.Failed } }
    $baseLines = @(& $fmt $baseResult.Assertions | Where-Object { $_ -notlike "$movedName|*" } | Sort-Object)
    $headLines = @(& $fmt $headResult.Assertions | Where-Object { $_ -notlike "$movedName|*" } | Sort-Object)
    $moved = @(Compare-Object $baseLines $headLines)
    Assert-That -What 'no other assertion score line moved' -Ok ($moved.Count -eq 0) `
        -Detail "$($moved.Count) other line(s) differ"
    ''

    # ------------------------------------------------------------------ 5
    '5. An amendment: the entry was present at the base commit'
    $thenText = (& git -C $clone show "${base}:PSGraphRender.code-workspace") -join "`n"
    $thenFile = Join-Path $work 'at-base.code-workspace'
    Set-Content -LiteralPath $thenFile -Value $thenText -Encoding utf8 -NoNewline
    $c5 = Test-NoRegistration -Path $thenFile
    Assert-That -What "the entry WAS registered at base $(($base).Substring(0,7))" -Ok (-not $c5.Ok) `
        -Detail $c5.Detail
    ''

    # -------------------------------------------------------------- probes
    if ($FailCheck) {
        '-FailCheck: the deliberate-failure probes'

        $probe = Join-Path $work 'probe'
        $null = New-Item -ItemType Directory -Path $probe -Force

        # A whole copy of the clone, because the assertion grades a REPOSITORY:
        # it discovers the tracked workspace file with git ls-files, so a lone
        # file in a bare directory would never reach the assertion at all. That
        # false ZERO CASES is what pass 0044's first falsification run reported.
        $damaged = Join-Path $probe 'PSGraphRender'
        Copy-Item -LiteralPath $clone -Destination $damaged -Recurse -Force

        $damagedWs = Join-Path $damaged 'PSGraphRender.code-workspace'
        $good = Get-Content -LiteralPath $damagedWs -Raw
        $bad = $good -replace '(?s)(\{\s*"path":\s*"\."\s*\})',
                              "`$1,`n`t`t{`n`t`t`t`"path`": `"../PSModuleGraph`"`n`t`t}"
        Set-Content -LiteralPath $damagedWs -Value $bad -Encoding utf8 -NoNewline
        Assert-That -What 'probe actually restored the entry' -Ok ($bad -ne $good) `
            -Detail 'a substitution that matched nothing would be recorded as a passing check'

        $p1 = Test-NoRegistration -Path $damagedWs
        Assert-That -What 'probe: check 1 goes red on the restored entry' -Ok (-not $p1.Ok) -Detail $p1.Detail

        $p2 = Invoke-WorkspaceAssertion -Target $damaged
        Assert-That -What 'probe: the acceptance assertion goes RED on the restored entry' `
            -Ok ($p2.Verdict -eq 'RED') -Detail "$($p2.Verdict) - $($p2.Detail)"

        # SC1 probe: a diff that removes the folder object but also edits settings
        # and touches a second file - the two ways the prompt named.
        $badDiff = @(
            'diff --git a/Demo.code-workspace b/Demo.code-workspace',
            '--- a/Demo.code-workspace',
            '+++ b/Demo.code-workspace',
            '-		"path": "../PSModuleGraph"',
            '-	"settings": {}',
            '+	"settings": {',
            '+		"files.autoSave": "off"',
            '+	}'
        ) -join "`n"
        $p3 = Test-Sc1 -Files @('Demo.code-workspace', 'other.txt') -DiffText $badDiff
        Assert-That -What 'probe: SC1 goes red on a diff that edits settings and a second file' `
            -Ok (-not $p3.Ok) -Detail $p3.Detail
        ''
    }
}
catch {
    # Without this the script would print its error and still exit 0, because a
    # terminating error skips the exit lines below and $LASTEXITCODE is never
    # set. A verify script that reports success while crashing is a false green
    # arriving in the one artifact whose job is to disprove the plan; pass 0044's
    # verifier did exactly that, and this is the fix it landed.
    ''
    'VERIFY 0045: ERROR - the script could not complete, so nothing below it ran.'
    "  $($_.Exception.Message)"
    "  at $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())"
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    exit 99
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failures.Count) {
    "VERIFY 0045: FAIL - $($failures.Count) check(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'VERIFY 0045: PASS - every check re-derived and agreed.'
exit 0
