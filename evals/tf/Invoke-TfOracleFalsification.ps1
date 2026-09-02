#Requires -Version 7.2
<#
.SYNOPSIS
    Prove Compare-TfGraph.ps1 can fail: run the seven one-directional mutations
    against the oracle and report which mechanism each was detected as.

.DESCRIPTION
    Pass 0023 did this from a script in scratch/ that was never committed, so
    pass 0025 - amending the oracle under decision 0012 - had to re-author it
    before it could re-falsify. That is the whole argument for this file
    existing: a falsification nobody can re-run is a claim, not evidence.

    The order of business is fixed and each step earns the next:

      1. CONTROL. The oracle against itself must report ZERO differences.
         Every detection below is meaningless if a document differs from
         itself.
      2. For each of the seven mutations: assert the mutation actually CHANGED
         the document before trusting its detection. A mutation that silently
         did nothing would otherwise be reported as a comparator that found
         nothing, which is the opposite conclusion.
      3. DISCRIMINATION. Each mutation must come back as its OWN category. A
         comparator that reported everything as MissingNode would score 7/7 and
         be useless.

    Writes nothing but the report. The oracle on disk is never touched - the
    mutator returns an object and the fixture is frozen.

    SEVEN, NOT EIGHT. Pass 0035 added mutation 8, `duplicate-id`, and did NOT
    add it here. It is the one mutation that has to be applied to the ORACLE as
    well as to the graph under test - a duplicated id is the same defect
    whichever side carries it, and the direction this driver cannot express is
    the one that made the control green over a broken document in the first
    place. It has its own two-directional probe:

        ./Invoke-TfDuplicateIdFalsification.ps1

    Running only this file therefore does NOT falsify the whole comparator, and
    the report says so where a reader will see it.

.PARAMETER Fixture
    Which fixture to falsify. Selects the default oracle and the mutation
    targets. Defaults to fixture1, so a caller written before pass 0034 runs
    exactly what it ran before.

.PARAMETER Oracle
    The oracle to falsify against. Defaults to the -Fixture switch's oracle.

.PARAMETER ReportPath
    Write the report here as well as to the pipeline.

.OUTPUTS
    The report text. Exit code 0 when all seven are detected as distinct
    mechanisms and the control is green; 1 otherwise.

.EXAMPLE
    ./Invoke-TfOracleFalsification.ps1 -ReportPath ../../plans/0025-findings-batch/mutations.txt

.EXAMPLE
    ./Invoke-TfOracleFalsification.ps1 -Fixture fixture2 -ReportPath ../../plans/0034-fixture2/mutations2.txt
#>
[CmdletBinding()]
param(
    [ValidateSet('fixture1', 'fixture2')]
    [string] $Fixture = 'fixture1',

    [string] $Oracle,

    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Oracle) {
    $Oracle = Join-Path $PSScriptRoot ($Fixture -eq 'fixture2' ? 'fixture2/expected-graph.json' : 'fixture/expected-graph.json')
}

$compare = Join-Path $PSScriptRoot 'Compare-TfGraph.ps1'
$mutate = Join-Path $PSScriptRoot 'Mutate-TfGraph.ps1'
foreach ($script in $compare, $mutate, $Oracle) {
    if (-not (Test-Path -LiteralPath $script)) { throw "Missing: '$script'." }
}

# What each mutation is meant to have done, in the mutator's own terms. Stated
# here so the report says what was broken and not merely that something was.
#
# Fixture 1's wording is frozen verbatim: plans/0030-release/mutations.txt is a
# committed artifact and a re-run has to be diffable against it.
$caseSets = @{
    fixture1 = @(
        @{ Mutation = 'missing-node'; Expect = 'MissingNode'; Changed = 'drop TfFixtureApp:modules/service#local.service_tags, a node the traceability chain runs through' }
        @{ Mutation = 'extra-node'; Expect = 'ExtraNode'; Changed = 'add a local nothing declares' }
        @{ Mutation = 'wrong-attribute'; Expect = 'WrongAttribute'; Changed = 'change the random provider pin from 3.6.0 to 9.9.9' }
        @{ Mutation = 'wrong-parent'; Expect = 'WrongParent'; Changed = 'reparent the third-level subnet module to the root, flattening the chain by one level' }
        @{ Mutation = 'missing-edge'; Expect = 'MissingEdge'; Changed = 'drop the local.merged_tags -> modules/service#var.tags passes-to edge' }
        @{ Mutation = 'extra-edge'; Expect = 'ExtraEdge'; Changed = 'invent a reference out of the deliberately unused variable' }
        @{ Mutation = 'wrong-edge-kind'; Expect = 'WrongEdgeKind'; Changed = 'change that same edge from passes-to to references' }
    )
    fixture2 = @(
        @{ Mutation = 'missing-node'; Expect = 'MissingNode'; Changed = 'drop TfSiteOps:modules/common#output.tag, the output both sides of the diamond read' }
        @{ Mutation = 'extra-node'; Expect = 'ExtraNode'; Changed = 'add a local nothing declares' }
        @{ Mutation = 'wrong-attribute'; Expect = 'WrongAttribute'; Changed = 'change the archive provider pin in TfSiteOps from 2.6.0 to 9.9.9, leaving the same provider pinned ~> 2.6 in TfSiteCore' }
        @{ Mutation = 'wrong-parent'; Expect = 'WrongParent'; Changed = 'reparent TfSiteOps:modules/common to one of its two CALLERS instead of its directory parent' }
        @{ Mutation = 'missing-edge'; Expect = 'MissingEdge'; Changed = 'drop the pop#var.probe_window -> probe#var.window passes-to edge, the hop where the value is renamed' }
        @{ Mutation = 'extra-edge'; Expect = 'ExtraEdge'; Changed = 'invent a reference out of the variable nothing references' }
        @{ Mutation = 'wrong-edge-kind'; Expect = 'WrongEdgeKind'; Changed = 'change that same edge from passes-to to references' }
    )
}
$cases = $caseSets[$Fixture]

$lines = [System.Collections.Generic.List[string]]::new()
$rule = '=' * 78
$thin = '-' * 78

$lines.Add($rule)
$lines.Add('FALSIFYING Compare-TfGraph.ps1')
$lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
$lines.Add('Oracle: ' + ((Resolve-Path -LiteralPath $Oracle).Path -replace '\\', '/'))
$lines.Add('Fixture: ' + $Fixture)
$lines.Add($rule)
$lines.Add('')
$lines.Add('A comparator is the one tool in a scoring harness that nothing else checks.')
$lines.Add('If it under-reports, every score it produces is flattering and nothing says so.')
$lines.Add('Each mutation below changes exactly ONE thing about a graph that is otherwise')
$lines.Add('the oracle, and each is proved to have changed the document before its')
$lines.Add('detection is trusted.')
$lines.Add('')
$lines.Add('SEVEN OF EIGHT. Mutation 8 (duplicate-id) is two-directional - it is applied')
$lines.Add('to the ORACLE as well as to the graph under test - and is falsified by')
$lines.Add('Invoke-TfDuplicateIdFalsification.ps1. This report does not cover it, and a')
$lines.Add('green here is not a falsified comparator on its own.')
$lines.Add('')

# The oracle's own text length, so "the mutation changed the document" is a
# measured claim rather than an assumed one.
$oracleObject = Get-Content -LiteralPath $Oracle -Raw | ConvertFrom-Json
$oracleText = $oracleObject | ConvertTo-Json -Depth 30 -Compress
$failures = [System.Collections.Generic.List[string]]::new()

$lines.Add($thin)
$lines.Add('CONTROL FIRST - the oracle against itself must report ZERO differences.')
$lines.Add('Every detection below is meaningless if a document differs from itself.')
$lines.Add('')
$control = & $compare -Expected $Oracle -Actual $Oracle
$lines.Add("IsMatch:          $($control.IsMatch)")
$lines.Add("DifferenceCount:  $($control.DifferenceCount)")
$lines.Add("compared:         $($control.ExpectedNodeCount) nodes, $($control.ExpectedEdgeCount) edges")
if ($control.DifferenceCount -eq 0 -and $control.IsMatch) {
    $lines.Add('CONTROL GREEN')
}
else {
    $lines.Add('CONTROL RED - nothing below can be trusted')
    $failures.Add("control: oracle-vs-self reported $($control.DifferenceCount) difference(s)")
}
$lines.Add('')

$detected = [System.Collections.Generic.List[object]]::new()

foreach ($case in $cases) {
    $lines.Add($thin)
    $lines.Add("MUTATION: $($case.Mutation)")
    $lines.Add("CHANGED:  $($case.Changed)")

    $bad = & $mutate -Path $Oracle -Mutation $case.Mutation -Fixture $Fixture
    $badText = $bad | ConvertTo-Json -Depth 30 -Compress

    # The probe's own control. A mutation that did nothing would produce zero
    # differences and read exactly like a comparator that cannot detect it.
    if ($badText -eq $oracleText) {
        $lines.Add('LANDED:   NO - the mutation did not change the document')
        $failures.Add("$($case.Mutation): the mutation did not change the document")
        $lines.Add("DETECTED: $($case.Mutation) NOT PROVEN")
        $lines.Add('')
        continue
    }
    $lines.Add("LANDED:   document changed, $($oracleText.Length) -> $($badText.Length) chars")

    $result = & $compare -Expected $Oracle -ActualObject $bad
    $lines.Add("IsMatch:          $($result.IsMatch)")
    $lines.Add("DifferenceCount:  $($result.DifferenceCount)")
    foreach ($difference in $result.Differences) {
        $lines.Add(('  {0,-15} {1}' -f $difference.Category, $difference.Id))
        $lines.Add(('                  {0}' -f $difference.Detail))
    }

    $categories = @($result.Differences | ForEach-Object { $_.Category } | Sort-Object -Unique)
    if ($result.DifferenceCount -ge 1 -and $case.Expect -in $categories) {
        $lines.Add("DETECTED: $($case.Mutation) [$($case.Expect)]")
        $detected.Add([pscustomobject]@{ Mutation = $case.Mutation; Category = $case.Expect; Count = $result.DifferenceCount })
    }
    else {
        $lines.Add("DETECTED: $($case.Mutation) NOT AS $($case.Expect) - got [$($categories -join ', ')]")
        $failures.Add("$($case.Mutation): expected category $($case.Expect), got '$($categories -join ', ')'")
    }
    $lines.Add('')
}

$lines.Add($thin)
$lines.Add('DISCRIMINATION - each mutation must be reported as its OWN mechanism.')
$lines.Add('A comparator that reported everything as MissingNode would score 7/7 above and')
$lines.Add('be useless, so the categories are checked to be distinct.')
$lines.Add('')
foreach ($row in $detected) {
    $lines.Add(('  {0,-18} -> {1,-15} ({2} difference(s) total)' -f $row.Mutation, $row.Category, $row.Count))
}
$distinct = @($detected | ForEach-Object { $_.Category } | Sort-Object -Unique).Count
$lines.Add("distinct categories exercised: $distinct of $($cases.Count)")
if ($distinct -ne $cases.Count) {
    $failures.Add("discrimination: $distinct distinct categories across $($cases.Count) mutations")
}
$lines.Add('')

$lines.Add($rule)
$lines.Add("DETECTED: $($detected.Count) / $($cases.Count)")
if ($failures.Count -gt 0) {
    $lines.Add('')
    foreach ($failure in $failures) { $lines.Add("FAILED: $failure") }
}
$lines.Add($rule)

$report = $lines -join [Environment]::NewLine
$report

if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
}

if ($failures.Count -gt 0) { exit 1 }
exit 0
