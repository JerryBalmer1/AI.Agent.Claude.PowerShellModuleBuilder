#Requires -Version 7.2
<#
.SYNOPSIS
    Compare a producer graph against the hand-authored oracle, by mechanism.

.DESCRIPTION
    Staged matching, in the style of the AzDO fixture's Compare-Graph: nodes are
    matched by id first, then everything that survives is compared field by
    field, then edges are matched by (from, to) and only then by kind. The
    staging is what lets one defect be reported as one difference.

    Eight categories, one per mechanism a graph can be wrong in:

      DuplicateId      one graph uses the same node id twice; see Stage 0
      MissingNode      the oracle has a node the actual does not
      ExtraNode        the actual has a node the oracle does not
      WrongAttribute   both have the node; a field disagrees
      WrongParent      both have the node; its parentId disagrees
      MissingEdge      the oracle has an edge the actual does not
      ExtraEdge        the actual has an edge the oracle does not
      WrongEdgeKind    both have an edge between the same pair; the kind differs

    DuplicateId is checked BEFORE anything is keyed, and it is the one category
    that can be raised against the ORACLE as well as against the graph under
    test. See Stage 0 for why it has to come first.

    WrongParent and WrongEdgeKind exist so that a moved thing reads as ONE
    difference rather than as a removal plus an addition. Reported the second
    way, a reader cannot tell a moved node from two unrelated defects, and a
    score built on it counts one mistake twice.

    Every difference names the thing that differs. A count without an id is a
    score nobody can act on.

    Sorting is stable and total - by category, then id, then detail - so two
    runs over the same pair produce a byte-identical diff. A diff whose order
    moves cannot be compared against a committed one, and every scoring run
    would look like a regression.

.PARAMETER Expected
    Path to the oracle.

.PARAMETER Actual
    Path to the graph under test.

.PARAMETER ActualObject
    The graph under test, already parsed. For a caller that has just produced
    one and does not want to serialise it to compare it.

.PARAMETER DiffPath
    Write the human diff here as well as returning it.

.OUTPUTS
    PSCustomObject: IsMatch, DifferenceCount, Differences, Diff, and the counts
    of what was compared.

.EXAMPLE
    ./Compare-TfGraph.ps1 -Expected fixture/expected-graph.json -Actual graph.json

.EXAMPLE
    $result = ./Compare-TfGraph.ps1 -Expected $oracle -ActualObject $graph
    $result.Differences | Where-Object Category -eq 'MissingEdge'
#>
[CmdletBinding(DefaultParameterSetName = 'Path')]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Expected,

    [Parameter(Mandatory, ParameterSetName = 'Path')]
    [ValidateNotNullOrEmpty()]
    [string] $Actual,

    [Parameter(Mandatory, ParameterSetName = 'Object')]
    [ValidateNotNull()]
    [object] $ActualObject,

    [Parameter()]
    [string] $DiffPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-Field {
    param([Parameter(Mandatory)] [AllowNull()] [object] $Object, [Parameter(Mandatory)] [string] $Name)
    if ($null -eq $Object) { return $null }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $null
}

function Get-FieldName {
    param([Parameter(Mandatory)] [AllowNull()] [object] $Object)
    if ($null -eq $Object) { return @() }
    if ($Object -is [System.Collections.IDictionary]) { return @($Object.Keys) }
    return @($Object.PSObject.Properties.Name)
}

if (-not (Test-Path -LiteralPath $Expected)) { throw "No such oracle: '$Expected'." }
$expectedGraph = (Get-Content -LiteralPath $Expected -Raw | ConvertFrom-Json).graph

if ($PSCmdlet.ParameterSetName -eq 'Path') {
    if (-not (Test-Path -LiteralPath $Actual)) { throw "No such graph: '$Actual'." }
    $actualGraph = (Get-Content -LiteralPath $Actual -Raw | ConvertFrom-Json).graph
}
else {
    # Round-tripped through JSON deliberately, so an in-memory hashtable and a
    # file are compared as the same shape. A comparison that behaves
    # differently depending on how it was handed the graph is a comparison
    # nobody can reason about.
    $actualGraph = ($ActualObject | ConvertTo-Json -Depth 30 | ConvertFrom-Json).graph
}

$differences = [System.Collections.Generic.List[object]]::new()

$expectedNodes = @($expectedGraph.nodes)
$actualNodes = @($actualGraph.nodes)

# ---- Stage 0: id uniqueness, on BOTH graphs, before anything is keyed ----

function Get-DuplicateId {
    <#
    .SYNOPSIS
        Every node id that occurs more than once, with how many times.
    .DESCRIPTION
        Counted off the raw node list, deliberately, because the dictionary
        that every later stage uses is exactly what cannot see this.
    #>
    param([Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $Node)

    $count = [ordered]@{}
    foreach ($item in $Node) {
        $id = [string](Get-Field -Object $item -Name 'id')
        if ($count.Contains($id)) { $count[$id] = $count[$id] + 1 }
        else { $count[$id] = 1 }
    }
    foreach ($id in $count.Keys) {
        if ($count[$id] -gt 1) { [pscustomobject]@{ Id = $id; Count = $count[$id] } }
    }
}

# A DICTIONARY IS A DEDUPLICATOR. Every stage below keys nodes by id, and
# `$byId[$node.id] = $node` silently discards the earlier entry - so a graph
# carrying the same id twice is compared as though it had one fewer node, on
# whichever side the duplicate is. The oracle against itself is the worst case:
# both sides lose the same entry, the counts agree, and a document with a
# repeated id reports ZERO differences against itself.
#
# That is not a hypothetical. Pass 0034's own verify.ps1 planted a duplicated
# node id in the fixture-2 oracle expecting the control to go red; the control
# stayed green over a document that now held 100 nodes, and LEDGER backlog 32
# is the write-up. A producer that emitted a duplicate scored clean.
#
# So it is checked HERE, before the first assignment into a hashtable, and on
# BOTH graphs. A duplicate is its own category rather than an ExtraNode or a
# WrongAttribute on the survivor, because neither copy is the extra one: the id
# is ambiguous, and every comparison keyed on it - fields, parents, edge
# endpoints - is meaningless rather than merely wrong. Reporting it as anything
# else would name a defect that is not the defect.
$expectedDuplicates = @(Get-DuplicateId -Node $expectedNodes)
$actualDuplicates = @(Get-DuplicateId -Node $actualNodes)

foreach ($duplicate in $expectedDuplicates) {
    $differences.Add([pscustomobject]@{
            Category = 'DuplicateId'
            Id       = $duplicate.Id
            Detail   = "on the expected side: the id occurs $($duplicate.Count) times; every comparison keyed on it is ambiguous"
        })
}
foreach ($duplicate in $actualDuplicates) {
    $differences.Add([pscustomobject]@{
            Category = 'DuplicateId'
            Id       = $duplicate.Id
            Detail   = "on the actual side: the id occurs $($duplicate.Count) times; every comparison keyed on it is ambiguous"
        })
}

# ---- Stage 1: nodes, matched by id --------------------------------------

$expectedById = [ordered]@{}
foreach ($node in $expectedNodes) { $expectedById[[string]$node.id] = $node }
$actualById = [ordered]@{}
foreach ($node in $actualNodes) { $actualById[[string]$node.id] = $node }

foreach ($id in $expectedById.Keys) {
    if (-not $actualById.Contains($id)) {
        $differences.Add([pscustomobject]@{
                Category = 'MissingNode'
                Id       = $id
                Detail   = "type=$(Get-Field -Object $expectedById[$id] -Name 'type') scope=$(Get-Field -Object $expectedById[$id] -Name 'scope')"
            })
    }
}
foreach ($id in $actualById.Keys) {
    if (-not $expectedById.Contains($id)) {
        $differences.Add([pscustomobject]@{
                Category = 'ExtraNode'
                Id       = $id
                Detail   = "type=$(Get-Field -Object $actualById[$id] -Name 'type') scope=$(Get-Field -Object $actualById[$id] -Name 'scope')"
            })
    }
}

# ---- Stage 2: fields of the nodes both graphs have ----------------------

foreach ($id in $expectedById.Keys) {
    if (-not $actualById.Contains($id)) { continue }
    $want = $expectedById[$id]
    $got = $actualById[$id]

    # parentId is its own category: a moved node is one defect, not a removal
    # and an addition.
    $wantParent = [string](Get-Field -Object $want -Name 'parentId')
    $gotParent = [string](Get-Field -Object $got -Name 'parentId')
    if ($wantParent -ne $gotParent) {
        $differences.Add([pscustomobject]@{
                Category = 'WrongParent'
                Id       = $id
                Detail   = "expected parentId '$wantParent', got '$gotParent'"
            })
    }

    foreach ($field in 'label', 'type', 'scope') {
        $wantValue = [string](Get-Field -Object $want -Name $field)
        $gotValue = [string](Get-Field -Object $got -Name $field)
        if ($wantValue -ne $gotValue) {
            $differences.Add([pscustomobject]@{
                    Category = 'WrongAttribute'
                    Id       = $id
                    Detail   = "$field : expected '$wantValue', got '$gotValue'"
                })
        }
    }

    $wantAttributes = Get-Field -Object $want -Name 'attributes'
    $gotAttributes = Get-Field -Object $got -Name 'attributes'
    $names = @(@(Get-FieldName -Object $wantAttributes) + @(Get-FieldName -Object $gotAttributes)) | Sort-Object -Unique
    foreach ($name in $names) {
        $wantValue = [string](Get-Field -Object $wantAttributes -Name $name)
        $gotValue = [string](Get-Field -Object $gotAttributes -Name $name)
        if ($wantValue -ne $gotValue) {
            $differences.Add([pscustomobject]@{
                    Category = 'WrongAttribute'
                    Id       = $id
                    Detail   = "attributes.$name : expected '$wantValue', got '$gotValue'"
                })
        }
    }
}

# ---- Stage 3: edges, matched by endpoints before kind ------------------

function Get-EdgeKey {
    param([Parameter(Mandatory)] [object] $Edge)
    '{0} -> {1}' -f (Get-Field -Object $Edge -Name 'from'), (Get-Field -Object $Edge -Name 'to')
}

# Grouped by endpoint pair, because the fixture legitimately carries more than
# one edge between the same two nodes (a value both referenced and passed on).
# Matching by pair alone would report a kind change on the wrong one.
$expectedEdges = @{}
foreach ($edge in @($expectedGraph.edges)) {
    $key = Get-EdgeKey -Edge $edge
    if (-not $expectedEdges.ContainsKey($key)) { $expectedEdges[$key] = [System.Collections.Generic.List[object]]::new() }
    $expectedEdges[$key].Add($edge)
}
$actualEdges = @{}
foreach ($edge in @($actualGraph.edges)) {
    $key = Get-EdgeKey -Edge $edge
    if (-not $actualEdges.ContainsKey($key)) { $actualEdges[$key] = [System.Collections.Generic.List[object]]::new() }
    $actualEdges[$key].Add($edge)
}

foreach ($key in $expectedEdges.Keys) {
    $want = $expectedEdges[$key]
    if (-not $actualEdges.ContainsKey($key)) {
        foreach ($edge in $want) {
            $differences.Add([pscustomobject]@{
                    Category = 'MissingEdge'
                    Id       = $key
                    Detail   = "kind=$(Get-Field -Object $edge -Name 'kind')"
                })
        }
        continue
    }

    $got = $actualEdges[$key]
    $wantKinds = @($want | ForEach-Object { [string](Get-Field -Object $_ -Name 'kind') } | Sort-Object)
    $gotKinds = @($got | ForEach-Object { [string](Get-Field -Object $_ -Name 'kind') } | Sort-Object)

    if (($wantKinds -join ',') -ne ($gotKinds -join ',')) {
        if ($wantKinds.Count -eq $gotKinds.Count) {
            # Same number of edges between the same pair, different kinds. One
            # edge moved, which is one difference.
            for ($i = 0; $i -lt $wantKinds.Count; $i++) {
                if ($wantKinds[$i] -ne $gotKinds[$i]) {
                    $differences.Add([pscustomobject]@{
                            Category = 'WrongEdgeKind'
                            Id       = $key
                            Detail   = "expected kind '$($wantKinds[$i])', got '$($gotKinds[$i])'"
                        })
                }
            }
        }
        else {
            foreach ($kind in $wantKinds) {
                if ($kind -notin $gotKinds) {
                    $differences.Add([pscustomobject]@{ Category = 'MissingEdge'; Id = $key; Detail = "kind=$kind" })
                }
            }
            foreach ($kind in $gotKinds) {
                if ($kind -notin $wantKinds) {
                    $differences.Add([pscustomobject]@{ Category = 'ExtraEdge'; Id = $key; Detail = "kind=$kind" })
                }
            }
        }
    }

    # resolved is a claim about confidence and is compared where the oracle
    # states one. Absent in the oracle means NOT STATED, and a producer is free
    # to say more than the oracle does.
    for ($i = 0; $i -lt [Math]::Min($want.Count, $got.Count); $i++) {
        $wantResolved = Get-Field -Object $want[$i] -Name 'resolved'
        if ($null -eq $wantResolved) { continue }
        $gotResolved = Get-Field -Object $got[$i] -Name 'resolved'
        if ([string]$wantResolved -ne [string]$gotResolved) {
            $differences.Add([pscustomobject]@{
                    Category = 'WrongAttribute'
                    Id       = $key
                    Detail   = "resolved : expected '$wantResolved', got '$gotResolved'"
                })
        }
    }
}

foreach ($key in $actualEdges.Keys) {
    if ($expectedEdges.ContainsKey($key)) { continue }
    foreach ($edge in $actualEdges[$key]) {
        $differences.Add([pscustomobject]@{
                Category = 'ExtraEdge'
                Id       = $key
                Detail   = "kind=$(Get-Field -Object $edge -Name 'kind')"
            })
    }
}

# ---- Report -------------------------------------------------------------

# Total and stable: category, then id, then detail. Ordinal, so the order does
# not depend on the machine's culture.
$sorted = @($differences | Sort-Object `
    @{ Expression = { $_.Category } }, `
    @{ Expression = { $_.Id } }, `
    @{ Expression = { $_.Detail } })

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("expected: $(@($expectedNodes).Count) node(s), $(@($expectedGraph.edges).Count) edge(s)")
$lines.Add("actual:   $(@($actualNodes).Count) node(s), $(@($actualGraph.edges).Count) edge(s)")
if ($expectedDuplicates.Count -gt 0 -or $actualDuplicates.Count -gt 0) {
    # Said at the top of the diff and not only in the list below, because every
    # other line in this report was computed by keying on ids that are not
    # unique, and a reader needs to know that before reading any of them.
    $lines.Add("AMBIGUOUS: $($expectedDuplicates.Count) duplicated id(s) on the expected side, $($actualDuplicates.Count) on the actual side.")
    $lines.Add('           Nothing else in this report was compared on a stable key.')
}
$lines.Add('')
if ($sorted.Count -eq 0) {
    $lines.Add('No differences.')
}
else {
    $lines.Add("$($sorted.Count) difference(s):")
    foreach ($difference in $sorted) {
        $lines.Add(('  {0,-15} {1}' -f $difference.Category, $difference.Id))
        $lines.Add(('                  {0}' -f $difference.Detail))
    }
    $lines.Add('')
    $lines.Add('by category:')
    foreach ($group in ($sorted | Group-Object Category | Sort-Object Name)) {
        $lines.Add(('  {0,-15} {1}' -f $group.Name, $group.Count))
    }
}
$diff = $lines -join [Environment]::NewLine

if ($DiffPath) {
    $parent = Split-Path -Parent $DiffPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $DiffPath -Value $diff -Encoding utf8NoBOM
}

# IsMatch names the duplicate check a SECOND time rather than resting on the
# difference count alone. The two are equivalent today - a duplicate is added to
# the list like anything else - and the redundancy is the point: a later change
# that filtered, capped or categorised the list differently could make the count
# zero again, and this line makes that change fail loudly instead of quietly
# restoring the blindness backlog 32 was about. A graph whose ids are ambiguous
# has not been compared, whatever else came back.
$duplicateIdCount = $expectedDuplicates.Count + $actualDuplicates.Count

[pscustomobject]@{
    PSTypeName               = 'TfGraph.ComparisonResult'
    IsMatch                  = ($sorted.Count -eq 0 -and $duplicateIdCount -eq 0)
    DifferenceCount          = $sorted.Count
    Differences              = $sorted
    Diff                     = $diff
    ExpectedNodeCount        = @($expectedNodes).Count
    ExpectedEdgeCount        = @($expectedGraph.edges).Count
    ActualNodeCount          = @($actualNodes).Count
    ActualEdgeCount          = @($actualGraph.edges).Count
    # Which SIDE carries a duplicate, as numbers rather than as prose a caller
    # would have to parse out of Detail.
    ExpectedDuplicateIdCount = $expectedDuplicates.Count
    ActualDuplicateIdCount   = $actualDuplicates.Count
}
