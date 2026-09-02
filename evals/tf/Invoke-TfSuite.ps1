#Requires -Version 7.2
<#
.SYNOPSIS
    Run both Terraform fixture suites and report one headline line each.

.DESCRIPTION
    "Both suites are still green" is the claim every change to the comparator
    has to make, and until pass 0035 it was made by running two different things
    by hand and reading two differently-shaped reports. This file is that pair,
    run together, with the two headline lines in a fixed form so a plan's
    acceptance test can assert on them instead of on prose.

    THE TWO SUITES ARE NOT THE SAME SHAPE, and the report says so rather than
    flattening them:

      FIXTURE1  Compare-TfGraph.Tests.ps1, the comparator's own Pester suite.
                Written and run RED before the comparator existed. It is keyed
                to fixture 1 - the oracle it hard-codes at 78 nodes and 59
                edges - and its count is a tripwire: 15, and a change that
                moves it has either weakened an assertion or moved the frozen
                fixture.

      FIXTURE2  TWO LAYERS, and since pass 0037 both are inside the headline.

                Layer 1, the ORACLE layer: Invoke-TfOracleFalsification.ps1
                -Fixture fixture2. One control (the oracle against itself) plus
                seven mutations, each of which must be detected AS ITS OWN
                MECHANISM. Fixture 2 has no Pester suite; this falsification is
                what stands in for one, and counting it as "8 checks" rather
                than "7/7" is what lets the two lines be read side by side.

                Layer 2, the CASE layer, new at pass 0037:
                fixture2/Invoke-TfFixture2CaseFalsification.ps1. The case scorer
                was written at pass 0036 into a plan directory, where the next
                run would not have found it; promoting it is backlog 36 and 29.
                Ten checks - one oracle-vs-self control, seven mutations one per
                case, the duplicate-id refusal, and the demonstration that the
                corrected case 6 is stricter than the form it replaced.

                THE COUNT WAS DELIBERATELY RE-PINNED 8 -> 18. A gained check
                reads as a failure until the pin moves, which is the point of
                pinning; moving it is an act with a reason, recorded here and in
                the LEDGER, not a number quietly kept in step with whatever ran.
                The two layers grade DIFFERENT INSTRUMENTS against the same
                fixture - the comparator, and the case scorer - so the report
                keeps their sub-lines separate even though the headline adds up.

    Mutation 8 is deliberately outside BOTH headlines, at the comparator level.
    It is two-directional and has its own probe,
    Invoke-TfDuplicateIdFalsification.ps1, which this script runs last as a
    third line - reported, never folded in, because folding it in would move the
    15 that is fixture 1's tripwire. The case scorer's own duplicate-id REFUSAL
    is a different check on a different instrument and is inside the case layer.

    A FAILURE IS NEVER A MISSING LINE. Every suite that cannot be run at all is
    reported with its failure count set to the number of checks it should have
    made, so a suite that blew up cannot read as a suite that passed quietly.

.PARAMETER ReportPath
    Write the report here as well as to the pipeline.

.OUTPUTS
    The report text. Exit code 0 when both suites are green; 1 otherwise.

.EXAMPLE
    ./Invoke-TfSuite.ps1 -ReportPath ../../plans/0035-tf003-kit/suites.txt
#>
[CmdletBinding()]
param(
    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$suite1Path = Join-Path $PSScriptRoot 'Compare-TfGraph.Tests.ps1'
$falsify = Join-Path $PSScriptRoot 'Invoke-TfOracleFalsification.ps1'
$duplicate = Join-Path $PSScriptRoot 'Invoke-TfDuplicateIdFalsification.ps1'
$caseFalsify = Join-Path $PSScriptRoot 'fixture2/Invoke-TfFixture2CaseFalsification.ps1'
foreach ($path in $suite1Path, $falsify, $duplicate, $caseFalsify) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing: '$path'." }
}

# The counts the two suites are pinned at. Written down rather than derived, for
# the same reason Compare-TfGraph.Tests.ps1 hard-codes 78 and 59: a number read
# out of the thing it is checking agrees with it wherever it goes.
$Fixture1Expected = 15
# Re-pinned 8 -> 18 by pass 0037, deliberately and with the composition stated:
#   ORACLE layer  1 control + 7 mutations                              =  8
#   CASE   layer  1 control + 7 mutations + 1 refusal + 1 strictening  = 10
$Fixture2Expected = 18
$Fixture2OracleExpected = 8
$Fixture2CaseExpected = 10

function Invoke-Child {
    <#
    .SYNOPSIS
        Run a script in a child pwsh, returning its output and exit code.
    .DESCRIPTION
        A child process rather than dot-sourcing, because the falsification
        drivers call `exit` and would take this script with them.
    #>
    param([Parameter(Mandatory)] [string] $Path, [string[]] $Arguments = @())
    $out = & pwsh -NoProfile -File $Path @Arguments 2>&1 | Out-String
    [pscustomobject]@{ Output = $out; ExitCode = $LASTEXITCODE }
}

$lines = [System.Collections.Generic.List[string]]::new()
$rule = '=' * 78
$thin = '-' * 78

$lines.Add($rule)
$lines.Add('BOTH TERRAFORM FIXTURE SUITES')
$lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
$lines.Add($rule)
$lines.Add('')
$lines.Add('FIXTURE1 is pinned at 15 and must come back exactly there: a suite that gained')
$lines.Add('or lost a test is not the suite the pin is about, and the pin is what would')
$lines.Add('notice an assertion weakened or a frozen fixture moved.')
$lines.Add('')
$lines.Add('FIXTURE2 was RE-PINNED 8 -> 18 at pass 0037, when the promoted case scorer and')
$lines.Add('its falsification joined the fixture-2 suite as a second layer. The move is')
$lines.Add('deliberate and additive - ten checks gained, none weakened, none removed - and')
$lines.Add('is stated here rather than absorbed, because a pin that follows whatever ran is')
$lines.Add('not a pin.')
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('SUITE 1 - Compare-TfGraph.Tests.ps1, the comparator Pester suite (fixture 1).')
$lines.Add('')
$suite1 = Invoke-Pester -Path $suite1Path -PassThru -Output None
foreach ($test in $suite1.Tests) {
    $lines.Add(('  [{0}] {1}' -f ($test.Result -eq 'Passed' ? 'ok  ' : 'FAIL'), $test.ExpandedName))
}
$lines.Add('')
$lines.Add("total $($suite1.TotalCount), pinned at $Fixture1Expected")
if ($suite1.TotalCount -ne $Fixture1Expected) {
    $lines.Add("COUNT MOVED: this suite ran $($suite1.TotalCount) test(s), not $Fixture1Expected.")
    $lines.Add('A suite that gained or lost a test is not the suite the pin is about.')
}
$lines.Add('')
$lines.Add("FIXTURE1: $($suite1.PassedCount) passed, $($suite1.FailedCount) failed")
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('SUITE 2, LAYER 1 (the ORACLE layer) - Invoke-TfOracleFalsification.ps1 -Fixture fixture2.')
$lines.Add('One control plus seven mutations, each detected as its own mechanism.')
$lines.Add('')
$suite2 = Invoke-Child -Path $falsify -Arguments @('-Fixture', 'fixture2')
$controlGreen = $suite2.Output -match 'CONTROL GREEN'
$sevenOfSeven = $suite2.Output -match 'DETECTED: 7 / 7'
$lines.Add("  [$(($controlGreen ? 'ok  ' : 'FAIL'))] control: the fixture-2 oracle against itself reports zero differences")
$lines.Add("  [$(($sevenOfSeven ? 'ok  ' : 'FAIL'))] seven mutations, each detected as its own mechanism")
foreach ($line in ($suite2.Output -split "`r?`n" | Where-Object { $_ -match '^(DETECTED:|FAILED:|distinct categories)' })) {
    $lines.Add('  ' + $line.Trim())
}
$oraclePassed = 0
if ($controlGreen) { $oraclePassed += 1 }
if ($sevenOfSeven) { $oraclePassed += 7 }
$oracleFailed = $Fixture2OracleExpected - $oraclePassed
if ($suite2.ExitCode -ne 0 -and $oracleFailed -eq 0) {
    # A non-zero exit with both headlines present means something failed that
    # neither headline covers. Counted as a failure rather than argued away.
    $lines.Add("  [FAIL] the driver exited $($suite2.ExitCode) with both headlines present; read the report")
    $oracleFailed = 1
    $oraclePassed = $Fixture2OracleExpected - 1
}
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('SUITE 2, LAYER 2 (the CASE layer) - fixture2/Invoke-TfFixture2CaseFalsification.ps1.')
$lines.Add('The case scorer promoted out of plans/0036-tf-003/ at pass 0037, and its own')
$lines.Add('falsification. A DIFFERENT INSTRUMENT from the comparator, against the same')
$lines.Add('fixture: it grades the seven named cases, not the difference count.')
$lines.Add('')
$suite2case = Invoke-Child -Path $caseFalsify
$caseChecks = [ordered]@{
    'control: the fixture-2 oracle scored against itself is 7 / 7' =
    [bool]($suite2case.Output -match 'ORACLE VS SELF: 7 / 7')
    'seven mutations, each defeating its OWN case and no other'    =
    [bool]($suite2case.Output -match 'FALSIFIED: 7 / 7 cases each defeated by its own mutation')
    'duplicate-id refused rather than scored'                      =
    [bool]($suite2case.Output -match 'DUPLICATE-ID \(mutation 8\): refused, not scored')
    'corrected case 6 is stricter than the form it replaced'       =
    [bool]($suite2case.Output -match 'STRICTER THAN THE PLANS-ERA FORM: demonstrated')
}
# Weights, so the ten checks are ten and not four: the seven mutations are one
# headline line but seven separate defeats, and the report says which.
$caseWeights = @(1, 7, 1, 1)
$casePassed = 0
$index = 0
foreach ($check in $caseChecks.GetEnumerator()) {
    $lines.Add(('  [{0}] {1}' -f ($check.Value ? 'ok  ' : 'FAIL'), $check.Key))
    if ($check.Value) { $casePassed += $caseWeights[$index] }
    $index++
}
foreach ($line in ($suite2case.Output -split "`r?`n" | Where-Object { $_ -match '^(ORACLE VS SELF:|FALSIFIED:|DUPLICATE-ID|STRICTER THAN|\d+ CHECK\(S\) FAILED)' })) {
    $lines.Add('  ' + $line.Trim())
}
$caseFailed = $Fixture2CaseExpected - $casePassed
if ($suite2case.ExitCode -ne 0 -and $caseFailed -eq 0) {
    $lines.Add("  [FAIL] the case driver exited $($suite2case.ExitCode) with every headline present; read the report")
    $caseFailed = 1
    $casePassed = $Fixture2CaseExpected - 1
}
$lines.Add('')
$lines.Add($thin)
$lines.Add(('FIXTURE2 layers: oracle {0}/{1}, case {2}/{3}   (pinned at {4} = {1} + {3})' -f
        $oraclePassed, $Fixture2OracleExpected, $casePassed, $Fixture2CaseExpected, $Fixture2Expected))
$suite2Passed = $oraclePassed + $casePassed
$suite2Failed = $oracleFailed + $caseFailed
$lines.Add('')
$lines.Add("FIXTURE2: $suite2Passed passed, $suite2Failed failed")
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('MUTATION 8, AT THE COMPARATOR - reported, NOT folded into either headline above.')
$lines.Add('')
$lines.Add('duplicate-id is two-directional and belongs to neither suite. Folding it in')
$lines.Add('would move the 15 that is fixture 1 tripwire, which is the one thing this')
$lines.Add('report exists to notice. Not to be confused with the case layer duplicate-id')
$lines.Add('REFUSAL above: that is the same mutation put to a different instrument, and it')
$lines.Add('is inside FIXTURE2 because the case scorer is what fixture 2 suite grades.')
$lines.Add('')
$mutation8 = Invoke-Child -Path $duplicate -Arguments @('-Fixture', 'fixture2')
$bothDirections = ($mutation8.Output -match 'DUPLICATE-ID: detected on producer side') -and
    ($mutation8.Output -match 'DUPLICATE-ID: detected on oracle side')
$lines.Add("  [$(($bothDirections ? 'ok  ' : 'FAIL'))] mutation 8 detected on both the producer side and the oracle side")
$lines.Add("MUTATION8: exit $($mutation8.ExitCode)")
$lines.Add('')

# ---------------------------------------------------------------------------
$failed = $suite1.FailedCount + $suite2Failed + ($bothDirections ? 0 : 1) +
    ($suite1.TotalCount -ne $Fixture1Expected ? 1 : 0)

$lines.Add($rule)
if ($failed -eq 0) {
    $lines.Add("BOTH SUITES GREEN, at their pinned counts: FIXTURE1 $Fixture1Expected, FIXTURE2 $Fixture2Expected.")
}
else {
    $lines.Add("$failed CHECK(S) FAILED across the two suites and mutation 8.")
}
$lines.Add($rule)

$report = $lines -join [Environment]::NewLine
$report

if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
}

if ($failed -gt 0) { exit 1 }
exit 0
