#Requires -Version 7.2
<#
.SYNOPSIS
    Prove Compare-TfGraph.ps1's Stage 0 can fail: a duplicated node id is
    detected on the PRODUCER side and on the ORACLE side, and neither clean
    oracle has stopped matching itself.

.DESCRIPTION
    Mutation 8 does not belong in `Invoke-TfOracleFalsification.ps1`, and this
    file is where the reason lives.

    The other seven mutations are one-directional. They break the graph UNDER
    TEST and ask whether the comparator notices; breaking the oracle the same
    way would just be the same probe with the arguments swapped. A duplicated
    id is not like that. It is the same defect from two sides - a producer that
    emits an ambiguous id and an oracle that carries one are both un-comparable
    - and the comparator has to raise it against whichever side has it. A probe
    that only ever pointed at the actual graph would leave half the repair
    untested, and the half it left untested is the half that made the
    oracle-against-itself CONTROL green over a broken document.

    That is not a hypothetical either. Pass 0034's `verify.ps1` planted a
    duplicated node id in the fixture-2 oracle expecting the control to go red.
    It stayed green over a document that had grown to 100 nodes, because both
    graphs were keyed into ordered dictionaries by id and the duplicate
    overwrote its own entry on both sides. LEDGER backlog 32 is that finding;
    Stage 0 of the comparator is the repair; this script is what stops the
    repair from being taken on trust.

    THE ORDER OF BUSINESS, each step earning the next:

      1. CONTROLS FIRST. BOTH clean oracles against themselves must still report
         zero differences and IsMatch true. A repair that added detection by
         making every document differ from itself would look identical to a
         working one in every check below.
      2. THE MUTATION MUST LAND. Each direction asserts the document actually
         changed before its detection is trusted. A mutation that silently did
         nothing produces zero differences and reads exactly like a comparator
         that cannot see it - the opposite conclusion.
      3. PRODUCER SIDE. The clean oracle as expected, a duplicate-id graph as
         actual. The finding must be DuplicateId, must name the duplicated id,
         must count on the ACTUAL side, and IsMatch must be false.
      4. ORACLE SIDE. The mutated graph written to a SCRATCH file and passed as
         the oracle, the clean oracle on disk as actual. Same requirements, the
         count on the EXPECTED side.
      5. DISCRIMINATION. A duplicate must be reported as DuplicateId and NOT as
         an ExtraNode, a MissingNode or a WrongAttribute. Neither copy is the
         extra one; reporting it as anything else names a defect that is not
         the defect, and a reader could not act on it.

    THE FIXTURES ON DISK ARE NEVER WRITTEN TO. The mutator returns an object,
    and the one file this script creates is the scratch oracle for step 4, in
    the OS temp directory, removed in a finally. Both fixtures are frozen -
    decisions 0011 and 0014 - and a falsification that could edit its own
    subject would be one crash away from freezing the wrong thing.

.PARAMETER Fixture
    Which fixture to falsify both directions against. Defaults to fixture2, the
    measurement instrument. The clean-control step covers both fixtures
    regardless of this switch.

.PARAMETER ReportPath
    Write the report here as well as to the pipeline.

.OUTPUTS
    The report text. Exit code 0 when both controls are green and both
    directions are detected as DuplicateId; 1 otherwise.

.EXAMPLE
    ./Invoke-TfDuplicateIdFalsification.ps1 -ReportPath ../../plans/0035-tf003-kit/mutation8.txt

.EXAMPLE
    ./Invoke-TfDuplicateIdFalsification.ps1 -Fixture fixture1
#>
[CmdletBinding()]
param(
    [ValidateSet('fixture1', 'fixture2')]
    [string] $Fixture = 'fixture2',

    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$compare = Join-Path $PSScriptRoot 'Compare-TfGraph.ps1'
$mutate = Join-Path $PSScriptRoot 'Mutate-TfGraph.ps1'
$oracles = [ordered]@{
    fixture1 = Join-Path $PSScriptRoot 'fixture/expected-graph.json'
    fixture2 = Join-Path $PSScriptRoot 'fixture2/expected-graph.json'
}
foreach ($path in @($compare, $mutate) + @($oracles.Values)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing: '$path'." }
}
$oracle = $oracles[$Fixture]

$lines = [System.Collections.Generic.List[string]]::new()
$failures = [System.Collections.Generic.List[string]]::new()
$rule = '=' * 78
$thin = '-' * 78

$lines.Add($rule)
$lines.Add('FALSIFYING Compare-TfGraph.ps1 STAGE 0 - THE DUPLICATE-ID REPAIR')
$lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
$lines.Add('Fixture: ' + $Fixture)
$lines.Add('Oracle:  ' + ((Resolve-Path -LiteralPath $oracle).Path -replace '\\', '/'))
$lines.Add($rule)
$lines.Add('')
$lines.Add('LEDGER backlog 32: the comparator could not see a duplicate node id, and a')
$lines.Add('producer that emitted one scored clean. Both graphs were keyed into ordered')
$lines.Add('dictionaries by id, so a duplicate overwrote its own entry ON BOTH SIDES and')
$lines.Add('even the oracle-against-itself control stayed green over a document that had')
$lines.Add('grown by a node. A DICTIONARY IS A DEDUPLICATOR.')
$lines.Add('')
$lines.Add('The repair is Stage 0: uniqueness is asserted on both graphs before the first')
$lines.Add('assignment into a hashtable. This report is that repair, falsified - in both')
$lines.Add('directions, because a duplicated id is the same defect whichever side has it.')
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('STEP 1 - CONTROLS. Both CLEAN oracles against themselves.')
$lines.Add('')
$lines.Add('A repair that added detection by making every document differ from itself')
$lines.Add('would pass every step below and be worthless. These two are what say the')
$lines.Add('detections further down are detections and not noise.')
$lines.Add('')
foreach ($name in $oracles.Keys) {
    $control = & $compare -Expected $oracles[$name] -Actual $oracles[$name]
    $ok = ($control.DifferenceCount -eq 0 -and $control.IsMatch -and
        $control.ExpectedDuplicateIdCount -eq 0 -and $control.ActualDuplicateIdCount -eq 0)
    $lines.Add(('  {0}  IsMatch={1}  differences={2}  duplicated ids={3}  over {4} nodes / {5} edges' -f
            $name.PadRight(9), $control.IsMatch, $control.DifferenceCount,
        ($control.ExpectedDuplicateIdCount + $control.ActualDuplicateIdCount),
            $control.ExpectedNodeCount, $control.ExpectedEdgeCount))
    if ($ok) { $lines.Add("  CONTROL GREEN: $name") }
    else {
        $lines.Add("  CONTROL RED: $name - nothing below can be trusted")
        $failures.Add("control: $name against itself reported $($control.DifferenceCount) difference(s)")
    }
}
$lines.Add('')

# The mutated graph, made once and used in both directions so the two steps are
# demonstrably about the same document.
$oracleText = (Get-Content -LiteralPath $oracle -Raw | ConvertFrom-Json) | ConvertTo-Json -Depth 30 -Compress
$mutated = & $mutate -Path $oracle -Mutation 'duplicate-id' -Fixture $Fixture
$mutatedText = $mutated | ConvertTo-Json -Depth 30 -Compress

$lines.Add($thin)
$lines.Add('THE MUTATION - mutation 8, duplicate-id.')
$lines.Add('')
$lines.Add('CHANGED:  duplicate one node under its own id, byte-identical. Identical on')
$lines.Add('          purpose: a copy with a changed field would ALSO be detectable as a')
$lines.Add('          WrongAttribute on whichever copy the dictionary kept, and a')
$lines.Add('          mutation detected by two mechanisms cannot tell you which one you')
$lines.Add('          have.')
if ($mutatedText -eq $oracleText) {
    $lines.Add('LANDED:   NO - the mutation did not change the document')
    $failures.Add('mutation 8: the mutation did not change the document; neither detection below proves anything')
}
else {
    $lines.Add("LANDED:   document changed, $($oracleText.Length) -> $($mutatedText.Length) chars")
}
$duplicatedId = @($mutated.graph.nodes | Group-Object id | Where-Object Count -gt 1 | ForEach-Object Name)
$lines.Add('ID:       ' + ($duplicatedId -join ', '))
$lines.Add('')

function Test-Direction {
    <#
    .SYNOPSIS
        One direction: assert the finding is DuplicateId, names the id, counts
        on the expected side, and is not confused for another mechanism.
    #>
    param(
        [Parameter(Mandatory)] [object] $Result,
        [Parameter(Mandatory)] [ValidateSet('expected', 'actual')] [string] $Side,
        [Parameter(Mandatory)] [string[]] $Id,
        [Parameter(Mandatory)] [string] $Verdict
    )

    $out = [System.Collections.Generic.List[string]]::new()
    $bad = [System.Collections.Generic.List[string]]::new()

    $out.Add("IsMatch:          $($Result.IsMatch)")
    $out.Add("DifferenceCount:  $($Result.DifferenceCount)")
    $out.Add("duplicated ids:   expected side $($Result.ExpectedDuplicateIdCount), actual side $($Result.ActualDuplicateIdCount)")
    foreach ($difference in $Result.Differences) {
        $out.Add(('  {0,-15} {1}' -f $difference.Category, $difference.Id))
        $out.Add(('                  {0}' -f $difference.Detail))
    }

    $found = @($Result.Differences | Where-Object { $_.Category -eq 'DuplicateId' })
    $named = @($found | ForEach-Object { $_.Id } | Sort-Object -Unique)
    $sideCount = $Side -eq 'expected' ? $Result.ExpectedDuplicateIdCount : $Result.ActualDuplicateIdCount
    $otherCount = $Side -eq 'expected' ? $Result.ActualDuplicateIdCount : $Result.ExpectedDuplicateIdCount

    # Discrimination. Neither copy is the extra one, so a duplicate reported as
    # any of these three names a defect that is not the defect.
    $confused = @($Result.Differences | Where-Object { $_.Category -in @('ExtraNode', 'MissingNode', 'WrongAttribute') })

    if ($found.Count -eq 0) { $bad.Add('no DuplicateId difference was raised at all') }
    if (@($Id | Where-Object { $_ -notin $named }).Count -gt 0) {
        $bad.Add("the finding does not name every duplicated id: named [$($named -join ', ')], expected [$($Id -join ', ')]")
    }
    if ($sideCount -lt 1) { $bad.Add("the duplicate was not counted on the $Side side") }
    if ($otherCount -ne 0) { $bad.Add("a duplicate was also counted on the other side; only one graph was mutated") }
    if ($Result.IsMatch) { $bad.Add('IsMatch is TRUE over a graph with an ambiguous id') }
    if ($confused.Count -gt 0) {
        $bad.Add("the duplicate was also reported as [$(@($confused | ForEach-Object { $_.Category } | Sort-Object -Unique) -join ', ')]")
    }

    if ($bad.Count -eq 0) { $out.Add($Verdict) }
    else {
        $out.Add("$Verdict - NOT PROVEN")
        foreach ($b in $bad) { $out.Add("  ! $b") }
    }

    [pscustomobject]@{ Lines = $out; Failures = $bad }
}

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('STEP 2 - PRODUCER SIDE. The clean oracle as expected; the duplicate-id graph')
$lines.Add('as the graph under test. This is the direction that matters for scoring: a')
$lines.Add('producer emitting an ambiguous id used to score clean.')
$lines.Add('')
$producer = & $compare -Expected $oracle -ActualObject $mutated
$step = Test-Direction -Result $producer -Side 'actual' -Id $duplicatedId -Verdict 'DUPLICATE-ID: detected on producer side'
foreach ($l in $step.Lines) { $lines.Add($l) }
foreach ($f in $step.Failures) { $failures.Add("producer side: $f") }
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('STEP 3 - ORACLE SIDE. The MUTATED graph written to a scratch file and passed')
$lines.Add('as the oracle; the clean oracle on disk as the graph under test. This is the')
$lines.Add('direction pass 0034 discovered by accident: a broken oracle used to agree')
$lines.Add('with everything, including itself.')
$lines.Add('')
$lines.Add('The fixture on disk is NOT written to. The scratch file is created in the OS')
$lines.Add('temp directory and removed in a finally.')
$lines.Add('')
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('tf-duplicate-id-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    $null = New-Item -ItemType Directory -Path $scratch -Force
    $scratchOracle = Join-Path $scratch 'mutated-oracle.json'
    Set-Content -LiteralPath $scratchOracle -Value ($mutated | ConvertTo-Json -Depth 30) -Encoding utf8NoBOM
    $lines.Add("SCRATCH ORACLE: $($scratchOracle -replace '\\', '/')")

    # The scratch oracle must be the mutated document and not a fresh copy of a
    # clean one - a round trip through the disk is exactly where a mutation
    # quietly stops existing.
    $readBack = @((Get-Content -LiteralPath $scratchOracle -Raw | ConvertFrom-Json).graph.nodes |
            Group-Object id | Where-Object Count -gt 1)
    if ($readBack.Count -eq 0) {
        $lines.Add('LANDED:   NO - the scratch oracle read back with unique ids')
        $failures.Add('oracle side: the mutation did not survive the round trip to disk')
    }
    else {
        $lines.Add("LANDED:   the scratch oracle reads back with $($readBack.Count) duplicated id(s)")
    }
    $lines.Add('')

    $oracleSide = & $compare -Expected $scratchOracle -Actual $oracle
    $step = Test-Direction -Result $oracleSide -Side 'expected' -Id $duplicatedId -Verdict 'DUPLICATE-ID: detected on oracle side'
    foreach ($l in $step.Lines) { $lines.Add($l) }
    foreach ($f in $step.Failures) { $failures.Add("oracle side: $f") }
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}
$lines.Add('')
$lines.Add('The scratch oracle has been removed. Both fixtures on disk are unchanged.')
$lines.Add('')

# ---------------------------------------------------------------------------
$lines.Add($thin)
$lines.Add('STEP 4 - THE CONTROLS AGAIN, after everything above.')
$lines.Add('')
$lines.Add('Cheap, and it closes the one way this report could lie: a probe that left a')
$lines.Add('fixture edited behind it would have produced its detections honestly and')
$lines.Add('broken the instrument for everyone after.')
$lines.Add('')
foreach ($name in $oracles.Keys) {
    $after = & $compare -Expected $oracles[$name] -Actual $oracles[$name]
    $lines.Add(('  {0}  IsMatch={1}  differences={2}  {3} nodes / {4} edges' -f
            $name.PadRight(9), $after.IsMatch, $after.DifferenceCount, $after.ExpectedNodeCount, $after.ExpectedEdgeCount))
    if (-not ($after.DifferenceCount -eq 0 -and $after.IsMatch)) {
        $failures.Add("control after: $name no longer matches itself")
    }
}
$lines.Add('')

$lines.Add($rule)
if ($failures.Count -eq 0) {
    $lines.Add('MUTATION 8: detected in BOTH directions, controls green before and after.')
}
else {
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
