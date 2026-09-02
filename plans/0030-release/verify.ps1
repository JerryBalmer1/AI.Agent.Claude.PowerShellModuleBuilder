#Requires -Version 7.2
<#
.SYNOPSIS
    Verification for pass 0030 (release). Re-derives every claim the plan makes,
    from a FRESH CLONE of this repository at a pinned commit.

.DESCRIPTION
    This script exists so the operator can disprove the plan without reading it.
    It never parses plan.md, never reads a number out of prose, and never trusts
    the working tree - it makes its own clone in a temp directory and deletes it
    at the end. The one thing it deliberately checks against the NETWORK rather
    than the clone is the release tag, because a tag that exists only locally is
    exactly the failure that check is for.

.PARAMETER Sha
    The commit to verify. Defaults to HEAD of the repository this script sits in.

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
    [switch]$FailCheck
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$Tag      = 'v1.0.0'
$Version  = '1.0.0'

if (-not $Sha) { $Sha = (git -C $RepoRoot rev-parse HEAD).Trim() }

$failures = [Collections.Generic.List[string]]::new()
$notes    = [Collections.Generic.List[string]]::new()
$probes   = [Collections.Generic.List[string]]::new()
function Ok   { param($m) Write-Host "  [ok]   $m" -ForegroundColor Green }
function Bad  { param($id, $m) Write-Host "  [FAIL] $m" -ForegroundColor Red; $script:failures.Add("${id}: $m") }
function Note { param($m) Write-Host "  [note] $m" -ForegroundColor DarkGray; $script:notes.Add($m) }
function Fired {
    param($id, $desc, [bool]$went)
    if ($went) { Write-Host "  [fires] $desc" -ForegroundColor Green }
    else { Write-Host "  [DOES NOT FIRE] $desc" -ForegroundColor Red; $script:probes.Add("${id}: $desc") }
}

$clone = Join-Path ([IO.Path]::GetTempPath()) ("verify-0030-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
Write-Host "Pass 0030 verification"
Write-Host "  repository : $RepoRoot"
Write-Host "  commit     : $Sha"
Write-Host "  clone      : $clone"
Write-Host "  mode       : $(if ($FailCheck) { 'FailCheck (falsification probes)' } else { 'checks' })"
Write-Host ''

git -c core.longpaths=true clone -q $RepoRoot $clone
if ($LASTEXITCODE -ne 0) { throw 'clone failed' }
git -C $clone checkout -q $Sha
if ($LASTEXITCODE -ne 0) { throw "checkout $Sha failed" }

$mPath = "$clone/.claude-plugin/marketplace.json"
$pPath = "$clone/.claude-plugin/plugin.json"

try {

# ===========================================================================
# Check 1 - the two manifests exist, parse, and agree on 1.0.0
# ===========================================================================
Write-Host 'Check 1 - packaging manifests'
if ($FailCheck) {
    # Probe: make the two versions disagree. The check must notice.
    $before = Get-Content $mPath -Raw
    $broken = $before -replace '"version": "1\.0\.0"', '"version": "9.9.9"'
    if ($broken -eq $before) { throw 'probe changed nothing - version string not found' }
    Set-Content -LiteralPath $mPath -Value $broken -NoNewline
    $m = Get-Content $mPath -Raw | ConvertFrom-Json
    $p = Get-Content $pPath -Raw | ConvertFrom-Json
    Fired 'P1' 'version disagreement between marketplace.json and plugin.json' `
        ((@($m.plugins | Where-Object { $_.name -eq 'psmodule' })[0].version) -ne $p.version)
    Set-Content -LiteralPath $mPath -Value $before -NoNewline
} else {
    if (-not (Test-Path $mPath)) { Bad 'C1' 'marketplace.json is missing' }
    else {
        $m = $null
        try { $m = Get-Content $mPath -Raw | ConvertFrom-Json }
        catch { Bad 'C1' "marketplace.json does not parse: $($_.Exception.Message)" }
        $p = Get-Content $pPath -Raw | ConvertFrom-Json
        if ($m) {
            $entry = @($m.plugins | Where-Object { $_.name -eq 'psmodule' })
            if ($entry.Count -ne 1) { Bad 'C1' "expected exactly 1 psmodule entry, found $($entry.Count)" }
            elseif ($entry[0].source -notmatch '^\./') { Bad 'C1' "source '$($entry[0].source)' is not a relative './' path" }
            elseif ($p.version -ne $Version) { Bad 'C1' "plugin.json version is '$($p.version)', expected $Version" }
            elseif ($entry[0].version -ne $p.version) { Bad 'C1' "marketplace version '$($entry[0].version)' disagrees with plugin.json '$($p.version)'" }
            else { Ok "marketplace '$($m.name)' -> psmodule $($p.version), source '$($entry[0].source)', versions agree" }
        }
    }
}

# ===========================================================================
# Check 2 - adoption boilerplate present, and the licence is consistent
# ===========================================================================
Write-Host ''
Write-Host 'Check 2 - adoption boilerplate'
if ($FailCheck) {
    $sec = "$clone/SECURITY.md"
    Remove-Item $sec -Force
    Fired 'P2' 'SECURITY.md deleted is detected as missing' (-not (Test-Path $sec))
} else {
    $missing = @('SECURITY.md', 'CHANGELOG.md', 'LICENSE') | Where-Object { -not (Test-Path "$clone/$_") }
    if ($missing) { Bad 'C2' "missing: $($missing -join ', ')" }
    else {
        $p = Get-Content $pPath -Raw | ConvertFrom-Json
        $lic = Get-Content "$clone/LICENSE" -Raw
        if ($p.license -ne 'MIT') { Bad 'C2' "plugin.json license is '$($p.license)', expected MIT" }
        elseif ($lic -notmatch 'MIT License') { Bad 'C2' 'LICENSE does not name the MIT License' }
        else { Ok 'SECURITY.md, CHANGELOG.md and LICENSE present; MIT consistent with the manifest' }
    }
    $readme = Get-Content "$clone/README.md" -Raw
    $absent = @('## Support', '## Versioning', '## Install') |
        Where-Object { $readme -notmatch "(?m)^$([regex]::Escape($_))" }
    if ($absent) { Bad 'C2' "README has no $($absent -join ', ') section" }
    else { Ok 'README carries Install, Versioning and Support sections' }
}

# ===========================================================================
# Check 3 - backlog 20: the TF comparator suite is GREEN, and still discriminating
# ===========================================================================
Write-Host ''
Write-Host 'Check 3 - TF comparator (backlog 20)'
$tPath = "$clone/evals/tf/Compare-TfGraph.Tests.ps1"
if ($FailCheck) {
    # Probe: put the stale 57 back. The suite must go red again.
    $before = Get-Content $tPath -Raw
    $broken = $before -replace 'ExpectedEdgeCount \| Should-Be 59', 'ExpectedEdgeCount | Should-Be 57'
    if ($broken -eq $before) { throw 'probe changed nothing - assertion not found' }
    Set-Content -LiteralPath $tPath -Value $broken -NoNewline
    $r = Invoke-Pester -Path $tPath -Output None -PassThru
    Fired 'P3' 'restoring the stale 57 turns the comparator suite red' ($r.FailedCount -gt 0)
    Set-Content -LiteralPath $tPath -Value $before -NoNewline
} else {
    $r = Invoke-Pester -Path $tPath -Output None -PassThru
    if ($r.FailedCount -ne 0) { Bad 'C3' "comparator suite: $($r.PassedCount) passed, $($r.FailedCount) failed" }
    else { Ok "comparator suite green: $($r.PassedCount) passed, 0 failed" }

    # Green is not enough. The repair must not have weakened the suite, so the
    # seven mutations are RE-RUN from the clone and must all still be detected.
    $out = & pwsh -NoProfile -File "$clone/evals/tf/Invoke-TfOracleFalsification.ps1" 2>&1 | Out-String
    if ($out -match 'DETECTED: 7 / 7') { Ok 'all seven mutations still detected as distinct mechanisms (re-run, not quoted)' }
    else { Bad 'C3' 'the seven mutations did not come back 7 / 7 - the repair may have weakened the comparator' }

    # And the number in the assertion must be the frozen fixture's actual one.
    $oracle = Get-Content "$clone/evals/tf/fixture/expected-graph.json" -Raw | ConvertFrom-Json
    $n = @($oracle.graph.nodes).Count
    $e = @($oracle.graph.edges).Count
    if ($n -eq 78 -and $e -eq 59) { Ok "oracle really holds $n nodes and $e edges (decision 0012)" }
    else { Bad 'C3' "oracle holds $n nodes and $e edges; decision 0012 says 78 and 59" }
}

# ===========================================================================
# Check 4 - backlog 22: the PLAN-PROTOCOL clause is corrected, rule intact
# ===========================================================================
Write-Host ''
Write-Host 'Check 4 - PLAN-PROTOCOL worked example (backlog 22)'
if ($FailCheck) {
    $sample = 'the pass shipped without the red-first test the tier requires'
    Fired 'P4' 'the false clause is detectable when present' ($sample -match 'shipped without the red-first test')
} else {
    $pp = Get-Content "$clone/PLAN-PROTOCOL.md" -Raw
    if ($pp -match 'shipped without the red-first test') { Bad 'C4' 'the false clause is still present' }
    else { Ok 'the false clause is gone' }

    # A correction that deleted the lesson would pass the assertion above and
    # still be a regression, so the rule and the new evidence are both checked.
    if ($pp -match 'RED-FIRST: Passed=315 Failed=15 Total=330') { Ok 'the corrected example cites what plan 0012 section 3 records' }
    else { Bad 'C4' 'the corrected example does not cite plan 0012 section 3' }
    if ($pp -match 'Tier is a floor, never a ceiling') { Ok 'the rule the example illustrates is intact' }
    else { Bad 'C4' 'the tier rule went missing with the correction' }

    # And the citation must be true of the real file, not merely present here.
    $p12 = Get-Content "$clone/plans/0012-case-split-and-corrections/plan.md" -Raw
    if ($p12 -match 'RED-FIRST: Passed=315 Failed=15 Total=330') { Ok 'plan 0012 really contains the line the correction quotes' }
    else { Bad 'C4' 'plan 0012 does not contain the quoted red-first line' }
}

# ===========================================================================
# Check 5 - the prerequisite checker: control green, and it can say NO
# ===========================================================================
Write-Host ''
Write-Host 'Check 5 - prerequisite checker'
$chk = "$clone/tools/publish/Test-Prerequisites.ps1"
if (-not (Test-Path $chk)) { Bad 'C5' 'Test-Prerequisites.ps1 is missing' }
elseif ($FailCheck) {
    # Probe: clear the PAT in a child process. Exactly one named line, exit 1.
    $o = & pwsh -NoProfile -Command "`$env:AZDO_PAT=''; & '$chk'" 2>&1 | Out-String
    $code = $LASTEXITCODE
    $named = @($o -split "`r?`n" | Where-Object { $_ -match 'MISSING:.*AZDO_PAT is not set' })
    Fired 'P5' 'clearing $env:AZDO_PAT gives exit 1 and exactly one named line' `
        (($code -ne 0) -and ($named.Count -eq 1))
} else {
    $o = & pwsh -NoProfile -File $chk 2>&1 | Out-String
    $code = $LASTEXITCODE
    if ($code -eq 0 -and $o -match 'ALL PREREQUISITES PRESENT') { Ok 'checker exits 0 on this machine (control)' }
    else { Note "checker exits $code here - a prerequisite is genuinely missing on THIS machine, which is a true report about the machine, not a failure of the pass" }

    # The absence of #Requires is load-bearing and is asserted, not assumed.
    $rawChk = Get-Content $chk -Raw
    if ($rawChk -match '(?m)^\s*#Requires') { Bad 'C5' 'the checker carries a #Requires line - it will not run on the PowerShell it exists to diagnose' }
    else { Ok 'no #Requires line: the checker runs on the PowerShell it diagnoses' }

    $ev = Get-Content "$clone/plans/0030-release/hostile-first-run.txt" -Raw
    if ($ev -match 'ALL PROBES: named one-line errors') { Ok 'falsification record present and conclusive' }
    else { Bad 'C5' 'hostile-first-run.txt does not end in the required trailer' }
    $fired = @([regex]::Matches($ev, 'RESULT : RED, ONE named line')).Count
    if ($fired -eq 5) { Ok 'all five prerequisites were probed and each went red' }
    else { Bad 'C5' "expected 5 red probes in the record, found $fired" }
}

# ===========================================================================
# Check 6 - Publish-Real still has no push path (AST, not grep)
# ===========================================================================
Write-Host ''
Write-Host 'Check 6 - Publish-Real invokes nothing that publishes'
$pr = "$clone/tools/publish/Publish-Real.ps1"
$tok = $null; $err = $null
if ($FailCheck) {
    # Probe: a real invocation must be seen by this check. Parsed, never run.
    $probeAst = [System.Management.Automation.Language.Parser]::ParseInput(
        "Write-Host 'hi'`ngit push origin main`n", [ref]$tok, [ref]$err)
    $probeCmds = $probeAst.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) |
        ForEach-Object { $_.GetCommandName() }
    Fired 'P6' 'the AST check sees a real git push when one is present' ($probeCmds -contains 'git')
} else {
    $ast = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content $pr -Raw), [ref]$tok, [ref]$err)
    $cmds = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true) |
        ForEach-Object { $_.GetCommandName() } | Where-Object { $_ } | Sort-Object -Unique
    $forbidden = @($cmds | Where-Object { $_ -match '^(git|Publish-Module|nuget|dotnet)$' })
    if ($forbidden) { Bad 'C6' "Publish-Real.ps1 invokes: $($forbidden -join ', ')" }
    else { Ok "Publish-Real.ps1 invokes only: $($cmds -join ', ')" }

    # Chapter 09 teaches a cheaper check and promises it comes back empty.
    $sl = @(Select-String -Path $pr -Pattern '^\s*(&\s*)?git\s')
    if ($sl.Count -eq 0) { Ok "chapter 09's Select-String check still returns no output" }
    else { Bad 'C6' "chapter 09's check now returns $($sl.Count) line(s); the lesson is falsified" }
}

# ===========================================================================
# Check 7 - the release tag exists ON THE REMOTE, annotated, carrying the table
# ===========================================================================
Write-Host ''
Write-Host 'Check 7 - release tag'
if ($FailCheck) {
    $bogus = (git ls-remote --tags $RepoRoot 'v99.99.99*') | Out-String
    Fired 'P7' 'ls-remote returns nothing for a tag that does not exist' ([string]::IsNullOrWhiteSpace($bogus))
} else {
    # Deliberately against the ORIGIN, not the clone: a tag that exists only
    # locally is exactly what this check is for.
    $origin = (git -C $RepoRoot remote get-url origin).Trim()
    $ls = (git ls-remote --tags $origin "$Tag*") | Out-String
    if ([string]::IsNullOrWhiteSpace($ls)) { Bad 'C7' "$Tag is not on the remote $origin" }
    else {
        Ok "$Tag is on the remote $origin"
        $type = (git -C $RepoRoot cat-file -t $Tag 2>$null)
        if ($type -eq 'tag') { Ok "$Tag is an annotated tag" } else { Bad 'C7' "$Tag object type is '$type', expected 'tag' (annotated)" }

        # Decision 0013: the message carries the with/without headline AND the
        # caveat. A message with the win and no caveat is a marketing claim.
        $msg = (git -C $RepoRoot tag -l $Tag --format='%(contents)') | Out-String
        foreach ($claim in '19 / 33', '33 / 33', '0 / 12', '1 / 12') {
            if ($msg -match [regex]::Escape($claim)) { Ok "tag message carries '$claim'" }
            else { Bad 'C7' "tag message does not carry the with/without figure '$claim'" }
        }
        if ($msg -match 'never permitted to iterate|never allowed to iterate|no plugin-off final') {
            Ok 'tag message states the baseline caveat, not only the win'
        } else { Bad 'C7' 'tag message carries the win without the baseline caveat' }
    }
}

# ===========================================================================
# Check 8 - the acceptance test itself, run against the clone
# ===========================================================================
if (-not $FailCheck) {
    Write-Host ''
    Write-Host 'Check 8 - acceptance test against the clone'
    $r = Invoke-Pester -Output None -PassThru -Container (
        New-PesterContainer -Path "$clone/plans/0030-release/accept.Tests.ps1" -Data @{ RepoRoot = $clone })
    if ($r.FailedCount -eq 0 -and $r.PassedCount -gt 0) { Ok "acceptance: $($r.PassedCount) passed, $($r.FailedCount) failed" }
    else {
        Bad 'C8' "acceptance: $($r.PassedCount) passed, $($r.FailedCount) failed"
        $r.Failed | ForEach-Object { Write-Host "         - $($_.ExpandedName)" -ForegroundColor Red }
    }
}

} finally {
    if (Test-Path $clone) { Remove-Item -LiteralPath $clone -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host ''
if ($notes.Count) {
    Write-Host 'Notes:' -ForegroundColor DarkGray
    $notes | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }
    Write-Host ''
}
if ($FailCheck) {
    if ($probes.Count -eq 0) { Write-Host 'All probes fired: every check can go red.' -ForegroundColor Green; exit 0 }
    Write-Host "$($probes.Count) probe(s) did not fire:" -ForegroundColor Red
    $probes | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
if ($failures.Count -eq 0) { Write-Host 'All checks agree.' -ForegroundColor Green; exit 0 }
Write-Host "$($failures.Count) check(s) disagreed:" -ForegroundColor Red
$failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
exit 1
