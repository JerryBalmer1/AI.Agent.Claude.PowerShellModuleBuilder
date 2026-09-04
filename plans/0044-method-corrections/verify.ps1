#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0044 made, from a fresh clone, without reading
    the plan.

.DESCRIPTION
    Six checks. Each re-derives its answer from the repository rather than
    reading plan.md, per PLAN-PROTOCOL section 9 - including the "pre-edit
    excerpt" requirement, which is checked by reading the file as it stood at
    this pass's base commit rather than by trusting the excerpt quoted in the
    plan. An excerpt copied into a plan and an excerpt that was actually there
    are different claims, and only one of them is checkable.

    1. The acceptance test, run from the clone, green.
    2. SC1 - METHOD.md rule integrity. The prompt asked for "no gaps or
       duplicates" in rule numbering; METHOD.md has no rule numbering, so this
       checks the invariant that requirement stood in for - every rule opener
       carries exactly one of the document's three tags, both new rules among
       them. See plan.md Deviation 2.
    3. SC2 - assertion polarity. Runs the falsification driver from the clone
       (five rows) and re-runs the assertion against every workspace
       repository, recording each verdict.
    4. SC3 - backlog form. The 0044 entries run contiguously from the next free
       number with no gap and no reuse anywhere in the file.
    5. Doc edits are amendments, not inventions: each new rule is absent at the
       base commit and present at HEAD.
    6. The harness's own tracked workspace files do not register PSModuleGraph.
       This is here rather than in the suite because the suite cannot run
       against the harness at all - LEDGER backlog 61 - and the harness is the
       repository whose .code-workspace produced the finding in the first place.

    Writes only under scratch/ and removes what it wrote.

.PARAMETER RepoRoot
    Used to locate the remote, so the clone comes from the remote rather than
    from the tree being verified. Defaults to two levels above this script.
.PARAMETER Branch
    Branch to verify. Defaults to the pass branch, falling back to main.
.PARAMETER WorkspaceRoot
    Where the sibling repositories live, for check 3's real-repository sweep.
    Defaults to the parent of RepoRoot. Repositories not found are reported as
    not found, never silently skipped.
.PARAMETER FailCheck
    Run the deliberate-failure probes: SC1 and SC3 are re-run against damaged
    copies and must go red. A check that cannot fail has checked nothing, so a
    probe that does NOT fail is itself reported as a failure.
.EXAMPLE
    ./plans/0044-method-corrections/verify.ps1
.EXAMPLE
    ./plans/0044-method-corrections/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $Branch = 'pass-0044-method-corrections',
    [string] $WorkspaceRoot,
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
if (-not $WorkspaceRoot) { $WorkspaceRoot = Split-Path -Parent $RepoRoot }
$origin = (& git -C $RepoRoot remote get-url origin).Trim()

$work = Join-Path $RepoRoot 'scratch/verify-0044'
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
    "  [{0}] {1}{2}" -f $(if ($Ok) { 'ok  ' } else { 'FAIL' }), $What, $suffix
    if (-not $Ok) { $script:failures.Add("$What$suffix") }
}

# ---------------------------------------------------------------- spot-checks
# Written as functions over a file path so the same code answers for the real
# file and for a deliberately damaged copy. A probe that runs different code
# from the check it is probing proves nothing about the check.

function Test-Sc1 {
    <# METHOD.md rule integrity. Returns @{ Ok; Detail }. #>
    param([Parameter(Mandatory)][string] $Path)

    $lines = (Get-Content -LiteralPath $Path -Raw) -split "`r?`n"
    $tagged = @($lines | Where-Object { $_ -match '^\*\*(PORTABLE|TUNE|DOMAIN)\.\*\* ' })
    $bogus = @($lines | Where-Object {
            $_ -match '^\*\*[A-Z]+\.\*\*' -and $_ -notmatch '^\*\*(PORTABLE|TUNE|DOMAIN)\.\*\*'
        })
    if ($bogus.Count) {
        return @{ Ok = $false; Detail = "mis-tagged rule opener: $($bogus[0])" }
    }
    if ($tagged.Count -lt 44) {
        return @{ Ok = $false; Detail = "$($tagged.Count) tagged rules, expected at least 44" }
    }
    return @{ Ok = $true; Detail = "$($tagged.Count) tagged rules, none mis-tagged" }
}

function Test-Sc3 {
    <# Backlog numbering. Returns @{ Ok; Detail }. #>
    param([Parameter(Mandatory)][string] $Path)

    $lines = (Get-Content -LiteralPath $Path -Raw) -split "`r?`n"

    # Every numbered backlog entry in the file, in order of appearance.
    $all = @()
    foreach ($l in $lines) {
        if ($l -match '^(\d+)\.\s+\*\*') { $all += [int]$Matches[1] }
    }
    $dupes = @($all | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($dupes.Count) {
        return @{ Ok = $false; Detail = "number(s) reused: $($dupes -join ', ')" }
    }

    # The 0044 section specifically: contiguous, and starting at one past the
    # highest number that existed before it.
    $idx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^###\s+Added by pass 0044\s*$') { $idx = $i; break }
    }
    if ($idx -lt 0) { return @{ Ok = $false; Detail = 'no "### Added by pass 0044" section' } }

    $before = @()
    for ($i = 0; $i -lt $idx; $i++) {
        if ($lines[$i] -match '^(\d+)\.\s+\*\*') { $before += [int]$Matches[1] }
    }
    $mine = @()
    for ($i = $idx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^###\s+Added by pass ') { break }
        if ($lines[$i] -match '^##\s') { break }
        if ($lines[$i] -match '^(\d+)\.\s+\*\*') { $mine += [int]$Matches[1] }
    }
    if (-not $mine.Count) { return @{ Ok = $false; Detail = '0044 section has no numbered entries' } }

    $nextFree = (($before | Measure-Object -Maximum).Maximum) + 1
    if ($mine[0] -ne $nextFree) {
        return @{ Ok = $false; Detail = "0044 opens at $($mine[0]); next free was $nextFree" }
    }
    $expect = $nextFree
    foreach ($n in $mine) {
        if ($n -ne $expect) { return @{ Ok = $false; Detail = "gap or reuse: saw $n, expected $expect" } }
        $expect++
    }
    return @{ Ok = $true; Detail = "$($mine -join ', ') from next-free $nextFree, no reuse in $($all.Count) entries" }
}

function Get-WorkspaceRegistrations {
    <#
        PSModuleGraph folder registrations in one workspace file, read the same
        semantic way the suite assertion reads them: parsed JSONC, folders[].path,
        compared by path segment. A mention is not a registration.
    #>
    param([Parameter(Mandatory)][string] $Path)

    $raw = Get-Content -LiteralPath $Path -Raw
    $stripped = ($raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"
    $doc = $null
    try { $doc = $stripped | ConvertFrom-Json } catch { }
    if (-not $doc) { return @('<unparseable>') }
    $folders = @()
    if ($doc.PSObject.Properties.Name -contains 'folders') {
        $folders = @($doc.folders | ForEach-Object {
                if ($_.PSObject.Properties.Name -contains 'path') { $_.path }
            })
    }
    return @($folders | Where-Object { @($_ -split '[\\/]') -contains 'PSModuleGraph' })
}

function Invoke-WorkspaceBlock {
    <# The suite's Workspace composition block against one target. #>
    param(
        [Parameter(Mandatory)][string] $Suite,
        [Parameter(Mandatory)][string] $Target
    )
    $previous = $env:CONFORMANCE_TARGET
    $env:CONFORMANCE_TARGET = $Target
    try {
        $cfg = New-PesterConfiguration
        $cfg.Run.Path = $Suite
        $cfg.Run.PassThru = $true
        $cfg.Filter.FullName = '*Workspace composition*'
        $cfg.Output.Verbosity = 'None'
        $r = Invoke-Pester -Configuration $cfg
        $broken = @($r.Containers | Where-Object { $_.Result -ne 'Passed' -and $_.ErrorRecord })
        if ($broken.Count) { return 'DISCOVERY FAILED' }
        if ($r.FailedCount -gt 0) { return 'RED' }
        if ($r.PassedCount -gt 0) { return 'GREEN' }
        return 'ZERO CASES'
    }
    finally { $env:CONFORMANCE_TARGET = $previous }
}

# ---------------------------------------------------------------------- setup

'VERIFY 0044 - method corrections from 0043'
"  origin: $origin"
"  work:   $work"
''

if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
$null = New-Item -ItemType Directory -Path $work -Force

try {
    $clone = Join-Path $work 'harness'
    & git clone --quiet $origin $clone
    if ($LASTEXITCODE -ne 0) { throw "Cloning '$origin' failed; nothing below can be verified from a tree this script did not fetch." }

    $checkedOut = $Branch
    & git -C $clone checkout --quiet $Branch 2>$null
    if ($LASTEXITCODE -ne 0) {
        & git -C $clone checkout --quiet main
        $checkedOut = 'main'
    }
    $head = (& git -C $clone rev-parse --short HEAD).Trim()
    "  branch: $checkedOut @ $head"
    ''

    # -- 1 ------------------------------------------------------------------
    '1. Acceptance test, from the clone'
    & (Join-Path $clone 'plans/0044-method-corrections/accept.ps1') | Out-Null
    $acceptExit = $LASTEXITCODE
    Assert-That -What 'accept.ps1 exits 0' -Ok ($acceptExit -eq 0) -Detail "exit $acceptExit"
    ''

    # -- 2 ------------------------------------------------------------------
    '2. SC1 - METHOD.md rule integrity'
    $methodPath = Join-Path $clone 'method/METHOD.md'
    $sc1 = Test-Sc1 -Path $methodPath
    Assert-That -What 'SC1: every rule opener carries one of the three tags' -Ok $sc1.Ok -Detail $sc1.Detail
    ''

    # -- 3 ------------------------------------------------------------------
    '3. SC2 - assertion polarity'
    $driver = Join-Path $clone 'plans/0044-method-corrections/Test-WorkspaceFalsification.ps1'
    & $driver | Out-Null
    $falsifyExit = $LASTEXITCODE
    Assert-That -What 'SC2: falsification driver, all five rows correct' -Ok ($falsifyExit -eq 0) -Detail "exit $falsifyExit"

    $suite = Join-Path $clone 'evals/conformance/Conformance.Tests.ps1'
    $expected = @{
        'PSAzureDevOpsGraph'                      = 'ZERO CASES'
        'PSGraphRenderToHtml'                     = 'ZERO CASES'
        'PSTerraformGraph'                        = 'ZERO CASES'
        'PSGraphRender'                           = 'RED'
        'AI.Agent.Claude.PowerShellModuleBuilder' = 'DISCOVERY FAILED'
    }
    foreach ($name in ($expected.Keys | Sort-Object)) {
        $target = Join-Path $WorkspaceRoot $name
        if (-not (Test-Path -LiteralPath $target)) {
            Assert-That -What "SC2: $name present to be graded" -Ok $false -Detail "not found at $target"
            continue
        }
        $verdict = Invoke-WorkspaceBlock -Suite $suite -Target $target
        Assert-That -What "SC2: $name" -Ok ($verdict -eq $expected[$name]) `
            -Detail "expected $($expected[$name]), observed $verdict"
    }
    ''

    # -- 4 ------------------------------------------------------------------
    '4. SC3 - backlog form'
    $ledgerPath = Join-Path $clone 'LEDGER.md'
    $sc3 = Test-Sc3 -Path $ledgerPath
    Assert-That -What 'SC3: 0044 entries contiguous from next free, no reuse' -Ok $sc3.Ok -Detail $sc3.Detail
    ''

    # -- 5 ------------------------------------------------------------------
    '5. Doc edits are amendments: absent at the base commit, present at HEAD'
    # The base is this branch's fork point from main, re-derived rather than
    # named, so a rebase does not silently make this check compare nothing.
    $base = (& git -C $clone merge-base origin/main HEAD).Trim()
    Assert-That -What 'base commit resolved' -Ok ([bool]$base) -Detail $base

    $edits = @(
        @{ File = 'method/METHOD.md'; Phrase = 'before its first counted result'; What = 'METHOD named-check polarity' }
        @{ File = 'method/METHOD.md'; Phrase = 'never recalled'; What = 'METHOD conventions from the repository' }
        @{ File = 'PLAN-PROTOCOL.md'; Phrase = 'The five task signals'; What = 'PROTOCOL signal legend' }
        @{ File = 'PLAN-PROTOCOL.md'; Phrase = 'The frontier is read from three sources'; What = 'PROTOCOL frontier precondition' }
        @{ File = 'PLAN-PROTOCOL.md'; Phrase = 'The recovery phase'; What = 'PROTOCOL recovery-phase pattern' }
        @{ File = 'evals/conformance/Conformance.Tests.ps1'; Phrase = "Describe 'Workspace composition'"; What = 'suite assertion' }
        @{ File = 'docs/ux/UX-007-task-signals.md'; Phrase = '## Problem'; What = 'UX-007 record' }
    )
    foreach ($e in $edits) {
        $now = & git -C $clone show "HEAD:$($e.File)" 2>$null
        $then = & git -C $clone show "${base}:$($e.File)" 2>$null
        $nowText = ($now -join "`n")
        $thenText = ($then -join "`n")
        $presentNow = $nowText.Contains($e.Phrase)
        $absentThen = -not $thenText.Contains($e.Phrase)
        Assert-That -What "$($e.What): present at HEAD" -Ok $presentNow -Detail $e.File
        Assert-That -What "$($e.What): absent at base $base" -Ok $absentThen `
            -Detail 'an edit already present before the pass is not an amendment this pass made'
    }
    ''

    # -- 6 ------------------------------------------------------------------
    '6. The harness''s own workspace files (the suite cannot reach these)'
    $harnessWs = @(& git -C $clone ls-files '*.code-workspace')
    Assert-That -What 'harness has at least one tracked workspace file' -Ok ($harnessWs.Count -ge 1) `
        -Detail "$($harnessWs.Count) found"
    foreach ($rel in $harnessWs) {
        # @() at the call site: PowerShell unrolls an empty array on return, so
        # a function that finds nothing hands back $null and $null.Count throws.
        $hits = @(Get-WorkspaceRegistrations -Path (Join-Path $clone $rel))
        Assert-That -What "$rel does not register PSModuleGraph" -Ok (-not $hits.Count) `
            -Detail $(if ($hits.Count) { "registers $($hits -join ', ')" } else { 'no PSModuleGraph folder entry' })
    }
    ''

    # -- FailCheck ----------------------------------------------------------
    if ($FailCheck) {
        'FailCheck - the deliberate failures. Each MUST go red.'
        $probeDir = Join-Path $work 'probes'
        $null = New-Item -ItemType Directory -Path $probeDir -Force

        # SC1 probe: the analogue of the prompt's "duplicated number" in a
        # document that has no numbers - a rule opener carrying a tag that is
        # not one of the three.
        $badMethod = Join-Path $probeDir 'METHOD.md'
        $mText = Get-Content -LiteralPath $methodPath -Raw
        $mBad = [regex]::Replace($mText, '(?m)^\*\*PORTABLE\.\*\* ', '**PORTABLE.** ', 1)
        $mBad = $mBad -replace '(?m)^\*\*TUNE\.\*\* ', "**MAYBE.** "
        Set-Content -LiteralPath $badMethod -Value $mBad -Encoding utf8
        Assert-That -What 'SC1 probe actually changed the file' -Ok ($mBad -ne $mText) `
            -Detail 'a probe that matched nothing would be recorded as a passing check'
        $p1 = Test-Sc1 -Path $badMethod
        Assert-That -What 'SC1 probe: mis-tagged rule opener goes red' -Ok (-not $p1.Ok) -Detail $p1.Detail

        # SC3 probe: reuse number 42, exactly as the prompt names.
        $badLedger = Join-Path $probeDir 'LEDGER.md'
        $lText = Get-Content -LiteralPath $ledgerPath -Raw
        $lBad = $lText -replace '(?m)^59\. \*\*', '42. **'
        Set-Content -LiteralPath $badLedger -Value $lBad -Encoding utf8
        Assert-That -What 'SC3 probe actually changed the file' -Ok ($lBad -ne $lText) `
            -Detail 'a probe that matched nothing would be recorded as a passing check'
        $p2 = Test-Sc3 -Path $badLedger
        Assert-That -What 'SC3 probe: reusing number 42 goes red' -Ok (-not $p2.Ok) -Detail $p2.Detail
        ''
    }
}
catch {
    # Without this the script printed its error and still exited 0, because the
    # terminating error skipped the exit lines below and $LASTEXITCODE was never
    # set. A verify script that reports success while crashing is the exact
    # false-green this pass is about; it was found by this script doing it.
    ''
    "VERIFY 0044: ERROR - the script could not complete, so nothing below it ran."
    "  $($_.Exception.Message)"
    "  at $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())"
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    exit 99
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failures.Count) {
    "VERIFY 0044: FAIL - $($failures.Count) check(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'VERIFY 0044: PASS - every check re-derived and agreed.'
exit 0
