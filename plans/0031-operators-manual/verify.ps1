#Requires -Version 7.2
<#
.SYNOPSIS
    Verification for pass 0031. Re-derives every spot-check the prompt named,
    from a FRESH CLONE of this repository at a pinned commit.

.DESCRIPTION
    This script exists so the operator can disprove the plan without reading it.
    It never parses plan.md, never reads a number out of prose, and never
    depends on the working tree's scratch/ - it makes its own clone in a temp
    directory and deletes it at the end.

    Exits 0 when every check agrees, non-zero otherwise, naming the checks that
    disagreed.

.PARAMETER Sha
    The commit to verify. Defaults to HEAD of the repository this script sits in.

.PARAMETER FailCheck
    Runs the falsification probes instead of the checks: each probe breaks the
    thing a check depends on, in the CLONE only, and asserts the check goes red.
    A check that stays green under its own probe is reported as DOES NOT FIRE.

    Every probe asserts that it actually changed the target before the check is
    re-run (evals/HARNESS.md hazards 4 and 6). A probe that changes nothing
    produces a green that proves nothing, and that green reads exactly like a
    real one.
#>
[CmdletBinding()]
param(
    [string]$Sha,
    [switch]$FailCheck
)

$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path "$PSScriptRoot/../..").Path
$PinnedSha  = 'f25d05d8eb219c9b0009a85d39918214f6b3b681'   # LEDGER: ladder plugin SHA
$PinnedPaths3 = @('skills/', 'commands/', '.claude-plugin/')
$PinnedPaths4 = $PinnedPaths3 + 'evals/'

if (-not $Sha) { $Sha = (git -C $RepoRoot rev-parse HEAD).Trim() }

$failures = [Collections.Generic.List[string]]::new()
$notes    = [Collections.Generic.List[string]]::new()
function Ok   { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Bad  { param($id, $m) Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:failures.Add("$id`: $m") }
function Note { param($m) Write-Host "  [note] $m" -ForegroundColor DarkGray; $script:notes.Add($m) }

# --------------------------------------------------------------- fresh clone --
$clone = Join-Path ([IO.Path]::GetTempPath()) ("verify-0031-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
Write-Host "Pass 0031 verification"
Write-Host "  repository : $RepoRoot"
Write-Host "  commit     : $Sha"
Write-Host "  clone      : $clone"
Write-Host "  mode       : $(if ($FailCheck) { 'FailCheck (falsification probes)' } else { 'checks' })"
Write-Host ''

git -c core.longpaths=true clone -q $RepoRoot $clone
if ($LASTEXITCODE -ne 0) { throw "clone failed" }
git -C $clone -c advice.detachedHead=false checkout -q $Sha
if ($LASTEXITCODE -ne 0) { throw "checkout $Sha failed" }

try {

# ===========================================================================
# Check 1 - no dead relative links in either docs tree
# ===========================================================================
Write-Host 'Check 1 - dead relative links in docs/creating-an-agent and docs/testing'

function Get-DeadLinks {
    param([string]$Root)
    $bad = [Collections.Generic.List[string]]::new()
    $dirs = @("$Root/docs/creating-an-agent", "$Root/docs/testing") | Where-Object { Test-Path $_ }
    if ($dirs.Count -ne 2) { $bad.Add("expected both docs trees to exist; found $($dirs.Count)"); return , $bad }
    foreach ($f in Get-ChildItem $dirs -Filter *.md) {
        foreach ($m in [regex]::Matches((Get-Content $f.FullName -Raw), '\]\((\.\.?/[^)#]+)')) {
            $p = Join-Path $f.DirectoryName $m.Groups[1].Value
            if (-not (Test-Path $p)) { $bad.Add("$($f.Name): $($m.Groups[1].Value)") }
        }
    }
    , $bad
}

if ($FailCheck) {
    # Probe: point one link at a file that does not exist. The checker must find it.
    $victim = Get-ChildItem "$clone/docs/creating-an-agent" -Filter '00-*.md' | Select-Object -First 1
    $before = (Get-FileHash $victim.FullName).Hash
    (Get-Content $victim.FullName -Raw) -replace '\]\(\.\./\.\./LEDGER\.md\)', '](../../NO-SUCH-FILE.md)' |
        Set-Content -LiteralPath $victim.FullName -NoNewline
    $after = (Get-FileHash $victim.FullName).Hash
    if ($before -eq $after) {
        Bad 'C1' 'PROBE DID NOT APPLY - the link substitution changed nothing, so the red below would prove nothing (hazard 4).'
    } else {
        $dead = Get-DeadLinks $clone
        if ($dead.Count -gt 0) { Ok "probe fired: checker reported $($dead.Count) dead link(s), including the injected one" }
        else { Bad 'C1' 'DOES NOT FIRE - a link was pointed at a non-existent file and the checker still reported clean.' }
    }
    git -C $clone checkout -q -- docs/
} else {
    $dead = Get-DeadLinks $clone
    if ($dead.Count -eq 0) { Ok 'zero dead relative links' }
    else { $dead | ForEach-Object { Bad 'C1' "dead link: $_" } }
}

# ===========================================================================
# Check 2 - PublishLocal stages a byte-identical marketplace, in the clone
# ===========================================================================
Write-Host ''
Write-Host 'Check 2 - PublishLocal in the fresh clone'

$stage = Join-Path $clone 'scratch/local-marketplace'
& pwsh -NoProfile -File "$clone/tools/publish/Publish-Local.ps1" -RepoRoot $clone *>&1 | Out-Null
$stageExit = $LASTEXITCODE

if ($stageExit -ne 0) {
    Bad 'C2' "Publish-Local.ps1 exited $stageExit"
} else {
    $mFile = Join-Path $stage '.claude-plugin/marketplace.json'
    $pFile = Join-Path $stage 'psmodule/.claude-plugin/plugin.json'

    if (Test-Path $mFile) { Ok 'staged marketplace.json present' } else { Bad 'C2' 'no staged marketplace.json' }
    foreach ($f in @($mFile, $pFile)) {
        if (-not (Test-Path $f)) { Bad 'C2' "missing $f"; continue }
        try { $null = Get-Content $f -Raw | ConvertFrom-Json; Ok "parses as JSON: $(Split-Path $f -Leaf)" }
        catch { Bad 'C2' "does not parse: $f" }
    }

    $skills = @(Get-ChildItem (Join-Path $stage 'psmodule/skills') -Directory -ErrorAction SilentlyContinue)
    $cmds   = @(Get-ChildItem (Join-Path $stage 'psmodule/commands') -Filter *.md -ErrorAction SilentlyContinue)
    if ($skills.Count -eq 14) { Ok '14 skills staged' } else { Bad 'C2' "expected 14 skills, staged $($skills.Count)" }
    if ($cmds.Count   -eq 2)  { Ok '2 commands staged' } else { Bad 'C2' "expected 2 commands, staged $($cmds.Count)" }

    # Byte comparison against the clone's own copies - re-derived, not read.
    $mismatch = 0; $compared = 0
    $a = (Get-FileHash "$clone/.claude-plugin/plugin.json").Hash
    $b = (Get-FileHash $pFile).Hash
    $compared++; if ($a -ne $b) { $mismatch++ }
    foreach ($d in 'skills', 'commands') {
        foreach ($f in Get-ChildItem "$clone/$d" -Recurse -File) {
            $rel = $f.FullName.Substring($clone.Length + 1) -replace '\\', '/'
            $st = Join-Path $stage "psmodule/$rel"
            $compared++
            if (-not (Test-Path $st)) { $mismatch++; continue }
            if ((Get-FileHash $f.FullName).Hash -ne (Get-FileHash $st).Hash) { $mismatch++ }
        }
    }
    if ($mismatch -eq 0) { Ok "byte-identical to the repository's copies ($compared files compared)" }
    else { Bad 'C2' "$mismatch of $compared staged files differ from the repository's copies" }

    if ($FailCheck) {
        # Probe: corrupt one byte of the staged marketplace and re-validate.
        $before = (Get-FileHash $mFile).Hash
        $bytes = [IO.File]::ReadAllBytes($mFile); $bytes[0] = [byte][char]'!'
        [IO.File]::WriteAllBytes($mFile, $bytes)
        if ((Get-FileHash $mFile).Hash -eq $before) {
            Bad 'C2' 'PROBE DID NOT APPLY - the byte was not changed (hazard 4).'
        } else {
            & pwsh -NoProfile -File "$clone/tools/publish/Publish-Local.ps1" -RepoRoot $clone -ValidateOnly *>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { Ok 'probe fired: -ValidateOnly went red on one corrupted byte' }
            else { Bad 'C2' 'DOES NOT FIRE - validation stayed green over unparseable JSON.' }
        }
    }
}

# ===========================================================================
# Check 3 - PublishReal refuses, and can be made to stop refusing
# ===========================================================================
Write-Host ''
Write-Host 'Check 3 - PublishReal guard'

$out  = & pwsh -NoProfile -File "$clone/tools/publish/Publish-Real.ps1" -RepoRoot $clone 2>&1
$code = $LASTEXITCODE
$text = ($out | Out-String)

if ($code -ne 0) { Ok "exits non-zero ($code)" } else { Bad 'C3' "expected a non-zero exit, got $code" }
if ($text -cmatch 'GUARD: refused') { Ok "'GUARD: refused' present in output" } else { Bad 'C3' "'GUARD: refused' absent from output" }

if ($FailCheck) {
    # Probe: give the CLONE a marketplace.json. The guard must flip to the
    # checklist path. Clone only - the working repository must never grow one
    # before pass 0030.
    $dummy = Join-Path $clone '.claude-plugin/marketplace.json'
    if (Test-Path $dummy) { Bad 'C3' 'PROBE ABORTED - the clone already has a marketplace.json.' }
    else {
        '{ "name": "dummy-marketplace", "owner": { "name": "falsification" }, "plugins": [ { "name": "psmodule", "source": "./" } ] }' |
            Set-Content -LiteralPath $dummy
        if (-not (Test-Path $dummy)) {
            Bad 'C3' 'PROBE DID NOT APPLY - the dummy file was not written (hazard 4).'
        } else {
            $o2 = & pwsh -NoProfile -File "$clone/tools/publish/Publish-Real.ps1" -RepoRoot $clone 2>&1
            $c2 = $LASTEXITCODE
            $t2 = ($o2 | Out-String)
            if ($c2 -eq 0 -and $t2 -cmatch 'GUARD: passed') {
                Ok 'probe fired: with a marketplace.json present the guard flips to the checklist path (exit 0)'
            } else {
                Bad 'C3' "DOES NOT FIRE - guard did not flip; exit $c2. A guard that always refuses is not a guard."
            }
            if ($t2 -cmatch 'No push was made by this script') { Ok 'checklist path still pushes nothing' }
            else { Bad 'C3' 'checklist path did not state that it pushed nothing' }
            Remove-Item -LiteralPath $dummy -Force
        }
    }
    # The working repository must be untouched by any of this.
    if (Test-Path "$RepoRoot/.claude-plugin/marketplace.json") {
        Bad 'C3' 'THE WORKING REPOSITORY GREW A marketplace.json. The probe escaped the clone.'
    } else { Ok 'working repository has no marketplace.json (probe stayed in the clone)' }
}

# ===========================================================================
# Check 4 - the instrument pin
# ===========================================================================
Write-Host ''
Write-Host 'Check 4 - instrument pin against f25d05d'

$d3 = git -C $clone diff --stat "$PinnedSha..$Sha" -- $PinnedPaths3
if ([string]::IsNullOrWhiteSpace(($d3 | Out-String))) {
    Ok 'plugin proper (skills/ commands/ .claude-plugin/) is byte-identical to the pin'
} else {
    Bad 'C4' "the plugin proper differs from the pin:`n$($d3 | Out-String)"
}

# The four-path form the prompt named is NOT empty, and has not been since
# pass 0029. Report it honestly rather than asserting something false.
$d4files = @(git -C $clone diff --name-only "$PinnedSha..$Sha" -- $PinnedPaths4)
$unexpected = @($d4files | Where-Object { $_ -ne 'evals/HARNESS.md' })
if ($unexpected.Count -eq 0) {
    if ($d4files.Count -eq 0) {
        Ok 'four-path pin is empty'
    } else {
        Note "four-path pin is NOT empty: $($d4files -join ', '). This is pass 0029's +69 lines in evals/HARNESS.md, recorded in LEDGER.md, which prescribes the three-path form above. Pass 0031 added nothing to it - see the next line."
    }
} else {
    Bad 'C4' "pinned paths changed beyond the documented evals/HARNESS.md: $($unexpected -join ', ')"
}

# The assertion that actually belongs to THIS pass: it changed nothing pinned.
$base = (git -C $clone merge-base origin/main $Sha 2>$null)
if (-not $base) { $base = (git -C $RepoRoot merge-base main $Sha 2>$null) }
if ($base) {
    $base = "$base".Trim()
    $mine = @(git -C $clone diff --name-only "$base..$Sha" -- $PinnedPaths4)
    if ($mine.Count -eq 0) { Ok "pass 0031 changed nothing under the four pinned paths (base $($base.Substring(0,7)))" }
    else { Bad 'C4' "pass 0031 changed pinned paths: $($mine -join ', ')" }
} else {
    Bad 'C4' 'could not resolve a merge base to check what this pass changed'
}

# ===========================================================================
# Check 5 - template markers are enumerable
# ===========================================================================
Write-Host ''
Write-Host 'Check 5 - template markers'

$markers = @(Select-String -Path "$clone/README.md", "$clone/docs/creating-an-agent/*.md" `
                           -Pattern 'TEMPLATE:(remove|replace)' -AllMatches)
if ($markers.Count -gt 0) {
    Ok "$($markers.Count) marker line(s), enumerated:"
    $markers | ForEach-Object {
        Write-Host ("         {0,-36} line {1,4}  {2}" -f (Split-Path $_.Path -Leaf), $_.LineNumber,
                    ($_.Matches[0].Value))
    }
} else {
    Bad 'C5' 'no TEMPLATE markers found in README.md or the manual'
}

# Markers must NOT appear in the pinned paths.
$leak = @(Select-String -Path "$clone/skills/*/*.md", "$clone/commands/*.md", "$clone/evals/*.md", "$clone/method/*.md" `
                        -Pattern 'TEMPLATE:(remove|replace)' -ErrorAction SilentlyContinue)
if ($leak.Count -eq 0) { Ok 'no markers under skills/, commands/, evals/ or method/' }
else { Bad 'C5' "markers leaked into pinned/instrument paths: $(($leak | ForEach-Object { $_.Path }) -join ', ')" }

# ===========================================================================
# Check 6 - the acceptance test itself, run against the clone
# ===========================================================================
Write-Host ''
Write-Host 'Check 6 - acceptance test against the clone'
$r = Invoke-Pester -Path "$clone/plans/0031-operators-manual/accept.Tests.ps1" `
                   -Output None -PassThru -Container (
                       New-PesterContainer -Path "$clone/plans/0031-operators-manual/accept.Tests.ps1" `
                                           -Data @{ RepoRoot = $clone })
if ($r.FailedCount -eq 0 -and $r.PassedCount -gt 0) {
    Ok "acceptance: $($r.PassedCount) passed, $($r.FailedCount) failed"
} else {
    Bad 'C6' "acceptance: $($r.PassedCount) passed, $($r.FailedCount) failed"
    $r.Failed | ForEach-Object { Write-Host "         - $($_.ExpandedName)" -ForegroundColor Red }
}

} finally {
    if (Test-Path $clone) { Remove-Item -LiteralPath $clone -Recurse -Force -ErrorAction SilentlyContinue }
}

# ---------------------------------------------------------------- verdict --
Write-Host ''
if ($notes.Count) {
    Write-Host 'Notes:' -ForegroundColor DarkGray
    $notes | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }
    Write-Host ''
}
if ($failures.Count -eq 0) {
    Write-Host 'All checks agree.' -ForegroundColor Green
    exit 0
} else {
    Write-Host "$($failures.Count) check(s) disagreed:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
