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

      FIXTURE2  Invoke-TfOracleFalsification.ps1 -Fixture fixture2. One control
                (the oracle against itself) plus seven mutations, each of which
                must be detected AS ITS OWN MECHANISM. Fixture 2 has no Pester
                suite; this falsification is what stands in for one, and
                counting it as "8 checks" rather than "7/7" is what lets the
                two lines be read side by side.

    Mutation 8 is deliberately in NEITHER. It is two-directional and has its own
    probe, Invoke-TfDuplicateIdFalsification.ps1, which this script runs last as
    a third line - reported, never folded into either headline, because folding
    it in would move the 15 and the 7/7 that are the tripwires.

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
foreach ($path in $suite1Path, $falsify, $duplicate) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing: '$path'." }
}

# The counts the two suites are pinned at. Written down rather than derived, for
# the same reason Compare-TfGraph.Tests.ps1 hard-codes 78 and 59: a number read
# out of the thing it is checking agrees with it wherever it goes.
$Fixture1Expected = 15
$Fixture2Expected = 8   # one control + seven mutations

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
$lines.Add('Run after the Stage 0 duplicate-id repair (LEDGER backlog 32). The repair ADDS')
$lines.Add('a detection and weakens nothing, so both suites must come back exactly where')
$lines.Add('they were - a repair that moved either number would have changed the')
$lines.Add('instrument while claiming to fix it.')
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
$lines.Add('SUITE 2 - Invoke-TfOracleFalsification.ps1 -Fixture fixture2.')
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
$suite2Passed = 0
if ($controlGreen) { $suite2Passed += 1 }
if ($sevenOfSeven) { $suite2Passed += 7 }
$suite2Failed = $Fixture2Expected - $suite2Passed
if ($suite2.ExitCode -ne 0 -and $suite2Failed -eq 0) {
    # A non-zero exit with both headlines present means something failed that
    # neither headline covers. Counted as a failure rather than argued away.
    $lines.Add("  [FAIL] the driver exited $($suite2.ExitCode) with both headlines present; read the report")
    $suite2Failed = 1
    $suite2Passed = $Fixture2Expected - 1
}
$lines.Add('')
$lines.Add("FIXTURE2: $suite2Passed passed, $suite2Failed failed")
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('MUTATION 8 - reported, NOT folded into either headline above.')
$lines.Add('')
$lines.Add('duplicate-id is two-directional and belongs to neither suite. Folding it in')
$lines.Add('would move the 15 and the 7/7 that are those suites tripwires, which is the')
$lines.Add('one thing this report exists to notice.')
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
    $lines.Add('BOTH SUITES GREEN, at the counts they were pinned at before the repair.')
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
