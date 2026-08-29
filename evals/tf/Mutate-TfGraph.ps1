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

.OUTPUTS
    The mutated graph, as an object. Nothing is written.

.EXAMPLE
    $bad = ./Mutate-TfGraph.ps1 -Path fixture/expected-graph.json -Mutation missing-edge
    ./Compare-TfGraph.ps1 -Expected fixture/expected-graph.json -ActualObject $bad
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter(Mandatory)]
    [ValidateSet('missing-node', 'extra-node', 'wrong-attribute', 'wrong-parent',
        'missing-edge', 'extra-edge', 'wrong-edge-kind')]
    [string] $Mutation
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
$targetNode = 'TfFixtureApp:modules/service#local.service_tags'
$targetParentNode = 'TfFixtureNetwork:modules/segment/modules/subnet'
$targetAttributeNode = 'TfFixtureShared:.#provider.random'
$targetEdgeFrom = 'TfFixtureApp:.#local.merged_tags'
$targetEdgeTo = 'TfFixtureApp:modules/service#var.tags'

switch ($Mutation) {
    'missing-node' {
        # A node the traceability chain runs through, so a comparator that
        # only counts would still see the count change.
        $graph.graph.nodes = @($graph.graph.nodes | Where-Object { $_.id -ne $targetNode })
    }

    'extra-node' {
        $graph.graph.nodes = @($graph.graph.nodes) + @([pscustomobject]@{
                id       = 'TfFixtureApp:.#local.invented_by_the_mutator'
                label    = 'invented_by_the_mutator'
                type     = 'local'
                scope    = 'TfFixtureApp'
                parentId = 'TfFixtureApp:.'
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
        # The third-level module reparented to the root: the nested-module
        # chain flattened by one level, which is the most likely real defect
        # in a producer that mishandles nesting.
        foreach ($node in $graph.graph.nodes) {
            if ($node.id -eq $targetParentNode) { $node.parentId = 'TfFixtureNetwork:.' }
        }
    }

    'missing-edge' {
        $graph.graph.edges = @($graph.graph.edges | Where-Object {
                -not ($_.from -eq $targetEdgeFrom -and $_.to -eq $targetEdgeTo)
            })
    }

    'extra-edge' {
        $graph.graph.edges = @($graph.graph.edges) + @([pscustomobject]@{
                from = 'TfFixtureShared:.#var.unused_retention_days'
                to   = 'TfFixtureShared:.#local.effective_prefix'
                kind = 'references'
            })
        # Deliberately the unused variable from case 6: this is exactly the
        # edge a producer that invents a reference for every declaration would
        # emit, so the mutation is a real defect rather than a made-up one.
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
