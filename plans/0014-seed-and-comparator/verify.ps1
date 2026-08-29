#Requires -Version 7.2

<#
.SYNOPSIS
    Verifies Pass 0014 from a fresh clone.

.DESCRIPTION
    Re-derives every claim the plan makes rather than reading the plan. It does
    not parse plan.md, and it does not read the result of any Pester run to
    decide whether that run's subject is true. Check 3 re-runs the mutations
    rather than reading the table task 4 produced.

    NETWORK. Only check 1's ReadBack half, which reads Azure DevOps and needs
    $env:AZDO_PAT. When that variable is unset it is SKIPPED with a clear
    message and everything else still runs. A skipped check reports as skipped
    and never as agreeing. Nothing here creates, modifies or queues anything in
    Azure DevOps.

    NOTHING IS WRITTEN outside scratch/. The mutations check 3 regenerates go
    there, which is gitignored.

.PARAMETER FailCheck
    Falsification probe. Names a check to sabotage so this script can be shown
    capable of failing. Each probe asserts it changed something before the check
    runs. Never use outside a falsification run.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path,
    [ValidateSet('none', 'seed', 'comparator')]
    [string]$FailCheck = 'none'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================ frozen at a commit (decision 0004)
#
# This script verifies Pass 0014, which described one set of changes and landed
# at one commit. It is valid against that commit and is not maintained forward.
# Running it against a later HEAD is legitimate - it is how you find out what
# has moved - but reading its red as "Pass 0014 was wrong" is the category error
# decision 0004 exists to prevent. Pinned counts are not edited as the suites
# grow: a pin that no longer matches is information about drift.
#
# The SHA below is the commit carrying this pass's work. The commit that wrote
# the SHA into this file is its immediate child, so a difference of exactly one
# commit immediately after the pass is expected and is not drift.

$WrittenAgainstSha = 'PASS-0014-WORK-COMMIT'

$currentSha = $null
try {
    Push-Location $RepoRoot
    try { $currentSha = (& git rev-parse HEAD 2>$null).Trim() } finally { Pop-Location }
}
catch { $currentSha = $null }

if ($currentSha -and $WrittenAgainstSha -notmatch '^PASS-' -and $currentSha -ne $WrittenAgainstSha) {
    Write-Host ''
    Write-Host 'NOTE: the repository has moved since this script was written.' -ForegroundColor Yellow
    Write-Host ("  written against : {0}" -f $WrittenAgainstSha) -ForegroundColor Yellow
    Write-Host ("  current HEAD    : {0}" -f $currentSha) -ForegroundColor Yellow
    Write-Host '  Any disagreement below may be the repository having moved on rather' -ForegroundColor Yellow
    Write-Host '  than Pass 0014 having been wrong. See decisions/0004-plan-artifacts-are-frozen.md.' -ForegroundColor Yellow
    Write-Host ''
}

$functional = Join-Path $RepoRoot 'evals/functional'
$expectedGraph = Join-Path $functional 'fixture/expected-graph.json'
$comparePath   = Join-Path $functional 'Compare-Graph.ps1'
$mutatePath    = Join-Path $functional 'Mutate-Graph.ps1'
$resetPath     = Join-Path $functional 'Reset-Target.ps1'
$seedDir       = Join-Path $functional 'seed'
$scratch       = Join-Path $RepoRoot 'scratch/0014-verify'

if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch -Force | Out-Null }

$failures = [System.Collections.Generic.List[string]]::new()
$skipped  = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([string]$Check, [bool]$Condition, [string]$Detail = '')
    if ($Condition) { Write-Host ("  ok    {0}" -f $Check) -ForegroundColor DarkGreen }
    else {
        Write-Host ("  FAIL  {0}{1}" -f $Check, $(if ($Detail) { " -- $Detail" } else { '' })) -ForegroundColor Red
        $failures.Add("$Check$(if ($Detail) { " -- $Detail" })")
    }
}
function Skip-Check {
    param([string]$Check, [string]$Reason)
    Write-Host ("  SKIP  {0} -- {1}" -f $Check, $Reason) -ForegroundColor Yellow
    $skipped.Add("$Check -- $Reason")
}

function Invoke-Suite {
    param([string]$Path)
    $cfg = New-PesterConfiguration
    $cfg.Run.Path = $Path
    $cfg.Run.PassThru = $true
    $cfg.Output.Verbosity = 'None'
    Invoke-Pester -Configuration $cfg
}

# ============================================================ check 1

Write-Host 'check 1 - Fixture.Tests.ps1 and ReadBack.Tests.ps1 at their full case counts' -ForegroundColor Cyan
$pester = Get-Module -ListAvailable Pester | Where-Object Version -GE ([version]'6.0.0') |
    Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester) {
    Assert-True 'Pester 6 is available' $false 'install Pester 6 or later'
}
else {
    Import-Module $pester.Path -Force

    $fx = Invoke-Suite (Join-Path $functional 'Fixture.Tests.ps1')
    Write-Host ("        Fixture.Tests.ps1  total={0} passed={1} failed={2}" -f $fx.TotalCount, $fx.PassedCount, $fx.FailedCount)
    Assert-True 'Fixture.Tests.ps1 has no failing test' ($fx.FailedCount -eq 0) "$($fx.FailedCount) failed"
    Assert-True 'Fixture.Tests.ps1 case count is 352' ($fx.TotalCount -eq 352) "count is $($fx.TotalCount); Pass 0014 recorded 352"

    if (-not $env:AZDO_PAT) {
        Skip-Check 'ReadBack.Tests.ps1 at its full case count' 'AZDO_PAT is not set; this check reads Azure DevOps. It is skipped, not satisfied.'
    }
    else {
        $rb = Invoke-Suite (Join-Path $functional 'ReadBack.Tests.ps1')
        Write-Host ("        ReadBack.Tests.ps1 total={0} passed={1} failed={2}" -f $rb.TotalCount, $rb.PassedCount, $rb.FailedCount)
        Assert-True 'ReadBack.Tests.ps1 has no failing test' ($rb.FailedCount -eq 0) "$($rb.FailedCount) failed"
        Assert-True 'ReadBack.Tests.ps1 case count is 76' ($rb.TotalCount -eq 76) "count is $($rb.TotalCount); Pass 0014 recorded 76"
    }
}

# ============================================================ check 2

Write-Host 'check 2 - the expected graph compared with itself: zero differences, exit 0' -ForegroundColor Cyan
$selfReport = Join-Path $scratch 'self.json'
& pwsh -NoProfile -File $comparePath -ExpectedPath $expectedGraph -CandidatePath $expectedGraph -ReportPath $selfReport -Quiet | Out-Null
$selfExit = $LASTEXITCODE
Assert-True 'self-comparison exits 0' ($selfExit -eq 0) "exit $selfExit"
if (Test-Path $selfReport) {
    $sr = Get-Content $selfReport -Raw | ConvertFrom-Json
    Assert-True 'self-comparison reports zero differences' ($sr.differenceCount -eq 0) "$($sr.differenceCount) differences"
    Assert-True 'self-comparison reports agreement' ([bool]$sr.agree)
}
else { Assert-True 'self-comparison wrote a report' $false 'no report file' }

# ============================================================ check 3

Write-Host 'check 3 - case-01, case-08 and case-12 mutations each name their case' -ForegroundColor Cyan
Write-Host '          (mutations regenerated here, not read from the plan)'
foreach ($case in @('case-01', 'case-08', 'case-12')) {
    $mut = Join-Path $scratch "mutant-$case.json"
    $rep = Join-Path $scratch "report-$case.json"
    if (Test-Path $mut) { Remove-Item $mut -Force }

    & pwsh -NoProfile -File $mutatePath -CaseId $case -ExpectedPath $expectedGraph -OutputPath $mut | Out-Null
    Assert-True "$case mutation was generated" (Test-Path $mut)
    if (-not (Test-Path $mut)) { continue }

    # The mutation must have changed the graph, or a comparator that reports
    # nothing would satisfy this check.
    $sameAsOracle = (Get-FileHash -LiteralPath $mut -Algorithm SHA256).Hash -eq
                    (Get-FileHash -LiteralPath $expectedGraph -Algorithm SHA256).Hash
    Assert-True "$case mutation actually changed the graph" (-not $sameAsOracle)

    if ($FailCheck -eq 'comparator' -and $case -eq 'case-12') {
        # PROBE: replace the mutant with an unmutated copy of the oracle, so the
        # comparator has nothing to find. Asserted to have changed the file.
        $before = (Get-FileHash -LiteralPath $mut -Algorithm SHA256).Hash
        Copy-Item -LiteralPath $expectedGraph -Destination $mut -Force
        $after = (Get-FileHash -LiteralPath $mut -Algorithm SHA256).Hash
        Assert-True 'PROBE comparator actually replaced the mutant' ($before -ne $after)
        Write-Host '        PROBE ACTIVE: case-12 mutant replaced with an unmutated oracle' -ForegroundColor Magenta
    }

    & pwsh -NoProfile -File $comparePath -ExpectedPath $expectedGraph -CandidatePath $mut -ReportPath $rep -Quiet | Out-Null
    $exit = $LASTEXITCODE
    $r = Get-Content $rep -Raw | ConvertFrom-Json

    Assert-True "$case is reported as differing" ($r.differenceCount -gt 0) "$($r.differenceCount) differences"
    Assert-True "$case comparison exits non-zero" ($exit -ne 0) "exit $exit"
    Assert-True "$case is named in the report" (@($r.cases) -contains $case) "report named: $(@($r.cases) -join ', ')"
}

# ============================================================ check 4

Write-Host 'check 4 - the seed carries no head start' -ForegroundColor Cyan
Assert-True 'the seed directory exists' (Test-Path $seedDir -PathType Container)

if (Test-Path $seedDir) {
    $seedFiles = @(Get-ChildItem -LiteralPath $seedDir -Recurse -File -Force |
        ForEach-Object { $_.FullName.Substring($seedDir.Length).TrimStart('\', '/') -replace '\\', '/' } |
        Sort-Object)

    if ($FailCheck -eq 'seed') {
        # PROBE: plant a module manifest in the seed. Asserted to have created
        # the file before the check reads the list.
        $planted = Join-Path $seedDir 'PSAzureDevOpsGraph.psd1'
        Set-Content -LiteralPath $planted -Value "@{ ModuleVersion = '0.1.0' }" -Encoding utf8NoBOM
        Assert-True 'PROBE seed actually planted a manifest' (Test-Path $planted)
        Write-Host "        PROBE ACTIVE: planted $planted" -ForegroundColor Magenta
        $seedFiles = @(Get-ChildItem -LiteralPath $seedDir -Recurse -File -Force |
            ForEach-Object { $_.FullName.Substring($seedDir.Length).TrimStart('\', '/') -replace '\\', '/' } |
            Sort-Object)
    }

    Write-Host ("        seed holds {0} files: {1}" -f $seedFiles.Count, ($seedFiles -join ', '))

    # A seed that has grown a head start is the failure this check exists for.
    $forbidden = @(
        @{ Label = 'module manifest'; Pattern = '\.psd1$' }
        @{ Label = 'module file';     Pattern = '\.psm1$' }
        @{ Label = 'build file';      Pattern = '(^|/)(build\.ps1|.*\.build\.ps1|psakefile\.ps1|invoke-build\.ps1|Makefile)$' }
        @{ Label = 'source tree';     Pattern = '(^|/)(src|Public|Private)/' }
        @{ Label = 'test tree';       Pattern = '(^|/)(tests?|spec)/' }
        @{ Label = 'test file';       Pattern = '\.Tests\.ps1$' }
    )
    foreach ($f in $forbidden) {
        $hits = @($seedFiles | Where-Object { $_ -imatch $f.Pattern })
        Assert-True ("the seed contains no {0}" -f $f.Label) ($hits.Count -eq 0) ($hits -join ', ')
    }

    $expectedSeed = @('.gitattributes', '.gitignore', 'LICENSE', 'README.md') | Sort-Object
    Assert-True 'the seed is exactly README.md, LICENSE, .gitignore and .gitattributes' `
        (($seedFiles -join ',') -ceq ($expectedSeed -join ',')) ($seedFiles -join ', ')

    if ($FailCheck -eq 'seed') {
        Remove-Item -LiteralPath (Join-Path $seedDir 'PSAzureDevOpsGraph.psd1') -Force -ErrorAction SilentlyContinue
        Write-Host '        PROBE CLEANED: planted manifest removed' -ForegroundColor Magenta
    }
}

# ============================================================ check 5

Write-Host 'check 5 - Reset-Target.ps1 refuses a destination outside scratch/runs/' -ForegroundColor Cyan
foreach ($bad in @('../PSAzureDevOpsGraph', 'evals/functional/seed', 'scratch/runs/../../../PSAzureDevOpsGraph')) {
    $refused = $false
    $out = & pwsh -NoProfile -File $resetPath -Destination $bad 2>&1
    if ($LASTEXITCODE -ne 0 -or ($out | Out-String) -match 'Refusing to reset') { $refused = $true }
    Assert-True ("refuses '{0}'" -f $bad) $refused 'it did not refuse'
}
# And the control: an allowed destination is accepted, or the refusal above
# proves only that the script always fails.
$ok = Join-Path $RepoRoot 'scratch/runs/verify-0014-control'
& pwsh -NoProfile -File $resetPath -Destination 'scratch/runs/verify-0014-control' -Force *> $null
Assert-True 'accepts a destination under scratch/runs/' (Test-Path (Join-Path $ok '.git')) 'the allowed destination was not created'

# ============================================================ check 6

Write-Host 'check 6 - no PAT-shaped string in any tracked file or under runs/' -ForegroundColor Cyan

<#
    The corrected pattern, carried forward from Pass 0013.

    An 84-character mixed-case alphanumeric run is the measured shape of the PAT
    in use. Pure lower-hex runs of exactly 40 or 64 characters are excluded:
    they are git object ids and SHA-256 digests, thirty of which are in
    runs/001-fixture-create/create-summary.json by design. A PAT cannot hide
    behind the exclusion - 84 is neither 40 nor 64, and a mixed-case token is
    not lower-hex.
#>
$patPatterns = @('[A-Za-z0-9]{52,}', '[a-z2-7]{52,}', 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}')

Push-Location $RepoRoot
try { $tracked = @(& git ls-files 2>$null) } finally { Pop-Location }
Assert-True 'git ls-files returned files' ($tracked.Count -gt 0) 'run from a git clone'

$targets = [System.Collections.Generic.List[string]]::new()
foreach ($t in $tracked) { $targets.Add((Join-Path $RepoRoot $t)) }
$runsDir = Join-Path $RepoRoot 'runs'
if (Test-Path $runsDir) {
    foreach ($f in (Get-ChildItem -LiteralPath $runsDir -Recurse -File)) { $targets.Add($f.FullName) }
}

$hits = [System.Collections.Generic.List[string]]::new()
$scanned = 0
foreach ($full in @($targets | Sort-Object -Unique)) {
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $full -Raw -ErrorAction SilentlyContinue
    if (-not $text) { continue }
    $scanned++
    $flagged = $false
    foreach ($pattern in $patPatterns) {
        foreach ($m in [regex]::Matches($text, $pattern)) {
            $v = $m.Value
            if ($v -cmatch '^[0-9a-f]+$' -and ($v.Length -eq 40 -or $v.Length -eq 64)) { continue }
            $flagged = $true; break
        }
        if ($flagged) { break }
    }
    # Paths are reported. The matching text never is.
    if ($flagged) { $hits.Add($full.Replace($RepoRoot, '').TrimStart('\', '/')) }
}
Write-Host ("        scanned {0} files" -f $scanned)
Assert-True 'the scan actually read files' ($scanned -gt 0)
Assert-True 'no scanned file contains a PAT-shaped string' ($hits.Count -eq 0) ($hits -join ', ')

# ============================================================ result

Write-Host ''
if ($skipped.Count -gt 0) {
    Write-Host ("{0} check(s) SKIPPED - reported as skipped, never as agreeing:" -f $skipped.Count) -ForegroundColor Yellow
    foreach ($s in $skipped) { Write-Host "  - $s" -ForegroundColor Yellow }
    Write-Host ''
}
if ($failures.Count -eq 0) {
    Write-Host ("verify.ps1: every check that ran agreed ({0} skipped)" -f $skipped.Count) -ForegroundColor Green
    exit 0
}
Write-Host ("verify.ps1: {0} check(s) disagreed" -f $failures.Count) -ForegroundColor Red
foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
exit 1
