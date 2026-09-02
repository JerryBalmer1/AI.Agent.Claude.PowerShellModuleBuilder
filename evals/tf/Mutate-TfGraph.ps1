#Requires -Version 7.2
<#
.SYNOPSIS
    Break the oracle in exactly one way, so the comparator can be shown to fail.

.DESCRIPTION
    Seven mutations, one per mechanism Compare-TfGraph.ps1 claims to detect. A
    comparator that has only ever agreed with itself is indistinguishable from
    one that cannot disagree, and these are what turn "it found the differences
    we showed it" into "it finds differences".

    Each mutation changes ONE thing about a graph that is otherwise the oracle,
    so a detection names the mechanism rather than a document. None of them
    writes: the mutated graph is returned, and the oracle on disk is never
    touched. The fixture is frozen per decision 0011, and a mutator that could
    edit it would be one force-push away from freezing the wrong thing.

.PARAMETER Path
    The oracle to mutate a copy of.

.PARAMETER Mutation
    Which mechanism to break.

.PARAMETER Fixture
    Which fixture's node and edge ids to aim at. Defaults to fixture1, so every
    caller written before pass 0034 mutates exactly what it mutated before and
    `plans/0030-release/mutations.txt` stays reproducible.

.OUTPUTS
    The mutated graph, as an object. Nothing is written.

.EXAMPLE
    $bad = ./Mutate-TfGraph.ps1 -Path fixture/expected-graph.json -Mutation missing-edge
    ./Compare-TfGraph.ps1 -Expected fixture/expected-graph.json -ActualObject $bad

.EXAMPLE
    $bad = ./Mutate-TfGraph.ps1 -Path fixture2/expected-graph.json -Mutation wrong-parent -Fixture fixture2
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter(Mandatory)]
    [ValidateSet('missing-node', 'extra-node', 'wrong-attribute', 'wrong-parent',
        'missing-edge', 'extra-edge', 'wrong-edge-kind')]
    [string] $Mutation,

    [ValidateSet('fixture1', 'fixture2')]
    [string] $Fixture = 'fixture1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) { throw "No such oracle: '$Path'." }

# Round-tripped rather than edited in place, so the mutation cannot reach the
# file the graph was read from.
$graph = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json

# The targets are named rather than positional. An index would silently point
# at something else the first time the oracle gains a node, and the mutation
# would still "work" while testing nothing anybody chose.
#
# One set per fixture. Fixture 2's targets are not translations of fixture 1's:
# each aims at a mechanism fixture 2 has and fixture 1 does not, so a producer
# that passes fixture 1 by remembering it is broken here in a way it has not
# seen. The mapping is stated in evals/tf/fixture2/cases.md.
$targetSets = @{
    fixture1 = @{
        Node          = 'TfFixtureApp:modules/service#local.service_tags'
        ParentNode    = 'TfFixtureNetwork:modules/segment/modules/subnet'
        NewParent     = 'TfFixtureNetwork:.'
        AttributeNode = 'TfFixtureShared:.#provider.random'
        EdgeFrom      = 'TfFixtureApp:.#local.merged_tags'
        EdgeTo        = 'TfFixtureApp:modules/service#var.tags'
        ExtraNodeId   = 'TfFixtureApp:.#local.invented_by_the_mutator'
        ExtraNodeScope = 'TfFixtureApp'
        ExtraNodeParent = 'TfFixtureApp:.'
        ExtraEdgeFrom = 'TfFixtureShared:.#var.unused_retention_days'
        ExtraEdgeTo   = 'TfFixtureShared:.#local.effective_prefix'
    }
    fixture2 = @{
        # The output BOTH sides of the diamond read.
        Node          = 'TfSiteOps:modules/common#output.tag'
        # Reparented to its CALLER instead of its directory parent - the exact
        # defect fixture 2 was shaped to catch, and one fixture 1 cannot pose
        # because there every module's caller is its parent.
        ParentNode    = 'TfSiteOps:modules/common'
        NewParent     = 'TfSiteOps:modules/collector'
        # archive is pinned ~> 2.6 in TfSiteCore and 2.6.0 here. A producer that
        # keys providers by name alone has already lost this before the mutation.
        AttributeNode = 'TfSiteOps:.#provider.archive'
        # The last hop of the value chain, and the one that is RENAMED on the way
        # through: probe_window arrives as window.
        EdgeFrom      = 'TfSiteEdge:modules/edge/modules/pop#var.probe_window'
        EdgeTo        = 'TfSiteEdge:modules/edge/modules/pop/modules/probe#var.window'
        ExtraNodeId   = 'TfSiteEdge:.#local.invented_by_the_mutator'
        ExtraNodeScope = 'TfSiteEdge'
        ExtraNodeParent = 'TfSiteEdge:.'
        ExtraEdgeFrom = 'TfSiteCore:.#var.archive_retention_weeks'
        ExtraEdgeTo   = 'TfSiteCore:.#local.code_slug'
    }
}
$targets = $targetSets[$Fixture]

$targetNode = $targets.Node
$targetParentNode = $targets.ParentNode
$targetAttributeNode = $targets.AttributeNode
$targetEdgeFrom = $targets.EdgeFrom
$targetEdgeTo = $targets.EdgeTo

switch ($Mutation) {
    'missing-node' {
        # A node the traceability chain runs through, so a comparator that
        # only counts would still see the count change.
        $graph.graph.nodes = @($graph.graph.nodes | Where-Object { $_.id -ne $targetNode })
    }

    'extra-node' {
        $graph.graph.nodes = @($graph.graph.nodes) + @([pscustomobject]@{
                id       = $targets.ExtraNodeId
                label    = 'invented_by_the_mutator'
                type     = 'local'
                scope    = $targets.ExtraNodeScope
                parentId = $targets.ExtraNodeParent
            })
    }

    'wrong-attribute' {
        # A provider version. The pin is the whole point of recording a
        # provider, so a comparator that ignores attributes ignores case 4.
        foreach ($node in $graph.graph.nodes) {
            if ($node.id -eq $targetAttributeNode) { $node.attributes.version = '9.9.9' }
        }
    }

    'wrong-parent' {
        # Fixture 1: the third-level module reparented to the root - the
        # nested-module chain flattened by one level, which is the most likely
        # real defect in a producer that mishandles nesting.
        # Fixture 2: the shared module reparented to one of its two callers -
        # containment taken from the call rather than from the path.
        foreach ($node in $graph.graph.nodes) {
            if ($node.id -eq $targetParentNode) { $node.parentId = $targets.NewParent }
        }
    }

    'missing-edge' {
        $graph.graph.edges = @($graph.graph.edges | Where-Object {
                -not ($_.from -eq $targetEdgeFrom -and $_.to -eq $targetEdgeTo)
            })
    }

    'extra-edge' {
        $graph.graph.edges = @($graph.graph.edges) + @([pscustomobject]@{
                from = $targets.ExtraEdgeFrom
                to   = $targets.ExtraEdgeTo
                kind = 'references'
            })
        # Deliberately the unused variable from case 6 - in both fixtures. This
        # is exactly the edge a producer that invents a reference for every
        # declaration would emit, so the mutation is a real defect rather than a
        # made-up one.
    }

    'wrong-edge-kind' {
        foreach ($edge in $graph.graph.edges) {
            if ($edge.from -eq $targetEdgeFrom -and $edge.to -eq $targetEdgeTo) {
                $edge.kind = 'references'
            }
        }
    }
}

$graph
