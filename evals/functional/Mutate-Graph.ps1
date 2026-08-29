#Requires -Version 7.2

<#
.SYNOPSIS
    Emits the graph a naive implementation failing one case would produce.

.DESCRIPTION
    Given expected-graph.json and a case id, writes the wrong graph that the
    *specific* naive failure declared for that case in fixture/cases.md would
    produce. One mutation per case.

    THE MUTATIONS ARE NOT INVENTED HERE. Each one is derived from that case's
    "How a naive implementation fails" section, and each carries the sentence it
    was derived from. A mutation invented to be convenient tests only that the
    comparator notices arbitrary damage; a mutation derived from the declared
    failure tests that it notices the failure the fixture was built to catch.

    NEVER MODIFIES ITS INPUT. The expected graph is re-read from disk as text
    and parsed fresh for every mutation, so nothing can write back through a
    shared object reference.

    Output belongs under scratch/, which is gitignored. Mutations are never
    committed: they are derived artifacts, and a committed one is a second copy
    of the oracle that can drift from it.

.PARAMETER CaseId
    A case id such as case-01. Use -List to see all supported cases.

.PARAMETER List
    List every supported case, its mutation, and the naive failure it emulates.

.EXAMPLE
    pwsh -NoProfile -File Mutate-Graph.ps1 -List
    pwsh -NoProfile -File Mutate-Graph.ps1 -CaseId case-01 -OutputPath scratch/m.json
#>
[CmdletBinding(DefaultParameterSetName = 'Mutate')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Mutate')]
    [string]$CaseId,

    [Parameter(ParameterSetName = 'Mutate')]
    [string]$OutputPath,

    [string]$ExpectedPath = (Join-Path $PSScriptRoot 'fixture/expected-graph.json'),

    [Parameter(Mandatory, ParameterSetName = 'List')]
    [switch]$List
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------ helpers --

function Get-FreshGraph {
    # Parsed from text every time. Two mutations can never share an object.
    Get-Content -LiteralPath $ExpectedPath -Raw | ConvertFrom-Json
}

function Remove-GraphEdge {
    param($Graph, [string]$From, [string]$To, [string]$Kind)
    $before = @($Graph.edges).Count
    $Graph.edges = @($Graph.edges | Where-Object {
        -not ($_.from -ceq $From -and $_.to -ceq $To -and $_.kind -ceq $Kind)
    })
    if (@($Graph.edges).Count -eq $before) {
        throw "Remove-GraphEdge matched nothing: $From -[$Kind]-> $To"
    }
}

function Remove-GraphNode {
    param($Graph, [string]$Id)
    $before = @($Graph.nodes).Count
    $Graph.nodes = @($Graph.nodes | Where-Object { -not ($_.id -ceq $Id) })
    if (@($Graph.nodes).Count -eq $before) {
        throw "Remove-GraphNode matched nothing: $Id"
    }
}

function Add-GraphNode {
    param($Graph, [hashtable]$Node)
    $Graph.nodes = @($Graph.nodes) + @([pscustomobject]$Node)
}

function Add-GraphEdge {
    param($Graph, [hashtable]$Edge)
    $Graph.edges = @($Graph.edges) + @([pscustomobject]$Edge)
}

function Set-GraphEdgeTarget {
    param($Graph, [string]$From, [string]$To, [string]$Kind, [string]$NewTo)
    $hit = 0
    foreach ($e in $Graph.edges) {
        if ($e.from -ceq $From -and $e.to -ceq $To -and $e.kind -ceq $Kind) {
            $e.to = $NewTo; $hit++
        }
    }
    if ($hit -eq 0) { throw "Set-GraphEdgeTarget matched nothing: $From -[$Kind]-> $To" }
}

function Set-GraphEdgeKind {
    param($Graph, [string]$From, [string]$To, [string]$Kind, [string]$NewKind)
    $hit = 0
    foreach ($e in $Graph.edges) {
        if ($e.from -ceq $From -and $e.to -ceq $To -and $e.kind -ceq $Kind) {
            $e.kind = $NewKind; $hit++
        }
    }
    if ($hit -eq 0) { throw "Set-GraphEdgeKind matched nothing: $From -[$Kind]-> $To" }
}

# ---------------------------------------------------------------- mutations --

$P  = 'yaml:pipelines-main/pipelines'
$T  = 'yaml:pipelines-main/pipelines/templates'

$Mutations = [ordered]@{

    'case-01' = @{
        Mutation = "Repoint p01's template edge at the repo-root templates/steps-build.yml"
        Derived  = 'By joining the reference to the repository root. Both files exist, so a root-relative resolver does not error - it returns the wrong file, confidently.'
        Expect   = 'wrongEdgeTarget'
        Apply    = {
            param($g)
            Set-GraphEdgeTarget $g "$P/p01.yml" "$T/steps-build.yml" 'template' `
                'yaml:pipelines-main/templates/steps-build.yml'
        }
    }

    'case-02' = @{
        Mutation = 'Drop every chain edge below depth 1, and the node only reachable through them'
        Derived  = "By reading the pipeline's own YAML, recording what it references, and stopping. Depth 1 is the shape of every first attempt."
        Expect   = 'missingEdge, missingNode'
        Apply    = {
            param($g)
            Remove-GraphEdge $g "$T/chain-a.yml" "$T/chain-b.yml" 'template'
            Remove-GraphEdge $g "$T/chain-b.yml" "$T/chain-c.yml" 'template'
            # chain-b is reachable only through the edge just removed, so a
            # depth-1 walk never discovers it. chain-c survives: p05 references
            # it directly, at depth 1.
            Remove-GraphNode $g "$T/chain-b.yml"
        }
    }

    'case-03' = @{
        Mutation = "Report p03's extends edge as kind template"
        Derived  = 'By scanning the YAML text for anything that looks like a path, or by matching the substring template: - which also matches buildTemplate:.'
        Expect   = 'wrongEdgeKind'
        Apply    = {
            param($g)
            Set-GraphEdgeKind $g "$P/p03.yml" 'yaml:templates-platform/jobs/release.yml' 'extends' 'template'
        }
    }

    'case-04' = @{
        Mutation = "Resolve common.yml's relative reference into pipelines-main, the repo the traversal started in"
        Derived  = 'By carrying "the current repository" as a single value for the whole traversal instead of a property of the file being read.'
        Expect   = 'wrongEdgeTarget, extraNode, missingNode'
        Apply    = {
            param($g)
            $wrong = 'yaml:pipelines-main/steps/notify.yml'
            Set-GraphEdgeTarget $g 'yaml:templates-shared/steps/common.yml' `
                'yaml:templates-shared/steps/notify.yml' 'template' $wrong
            # The wrongly-resolved file is what such an implementation emits,
            # and the correct one is never reached.
            Add-GraphNode $g @{
                id = $wrong; kind = 'yaml'; name = 'notify.yml'
                repo = 'pipelines-main'; path = 'repos/pipelines-main/steps/notify.yml'
            }
            Remove-GraphNode $g 'yaml:templates-shared/steps/notify.yml'
        }
    }

    'case-05' = @{
        Mutation = "Flatten p05's pipelineResource edge into the template kind"
        Derived  = 'By flattening every reference into one "depends on" kind. p05 carries one edge of each kind precisely so the collapse shows up as two edges of the same kind out of one file.'
        Expect   = 'wrongEdgeKind'
        Apply    = {
            param($g)
            Set-GraphEdgeKind $g "$P/p05.yml" 'pipeline:p01-simple-include' 'pipelineResource' 'template'
        }
    }

    'case-06' = @{
        Mutation = "Drop p06's variables-block template edge and the node it discovers"
        Derived  = 'By walking a hard-coded list of blocks. It is the most tempting shortcut in the whole problem.'
        Expect   = 'missingEdge, missingNode'
        Apply    = {
            param($g)
            Remove-GraphEdge $g "$P/p06.yml" "$T/vars-common.yml" 'template'
            Remove-GraphNode $g "$T/vars-common.yml"
        }
    }

    'case-07' = @{
        Mutation = 'Duplicate the shared diamond node and its leaf, once per inbound path'
        Derived  = "By building the graph as a tree per pipeline and concatenating the results, so a node's identity is its position in one traversal rather than its file."
        Expect   = 'extraNode, wrongEdgeTarget, extraEdge'
        Apply    = {
            param($g)
            $dupShared = "$T/diamond-shared.yml#2"
            $dupLeaf   = "$T/diamond-leaf.yml#2"
            Add-GraphNode $g @{
                id = $dupShared; kind = 'yaml'; name = 'diamond-shared.yml'
                repo = 'pipelines-main'; path = 'repos/pipelines-main/pipelines/templates/diamond-shared.yml'
            }
            Add-GraphNode $g @{
                id = $dupLeaf; kind = 'yaml'; name = 'diamond-leaf.yml'
                repo = 'pipelines-main'; path = 'repos/pipelines-main/pipelines/templates/diamond-leaf.yml'
            }
            Set-GraphEdgeTarget $g "$P/p07b.yml" "$T/diamond-shared.yml" 'template' $dupShared
            Add-GraphEdge $g @{
                from = $dupShared; to = $dupLeaf; kind = 'template'; ref = 'diamond-leaf.yml'
            }
        }
    }

    'case-08' = @{
        Mutation = 'Drop the edge that closes the cycle, leaving a tree'
        Derived  = 'By adding a visited set and then dropping the edge that closes the cycle instead of recording it and not descending. The second failure is worse than the first, because it produces a clean-looking answer.'
        Expect   = 'missingEdge'
        Apply    = {
            param($g)
            Remove-GraphEdge $g "$T/cycle-b.yml" "$T/cycle-a.yml" 'template'
        }
    }

    'case-09' = @{
        Mutation = 'Delete both unresolved edges'
        Derived  = 'By dropping what it cannot resolve. A broken pipeline then looks identical to a clean one.'
        Expect   = 'missingEdge'
        Apply    = {
            param($g)
            Remove-GraphEdge $g "$P/p09.yml" "$T/missing-steps.yml" 'unresolved'
            Remove-GraphEdge $g "$P/p09.yml" 'yaml:@ghostTemplates/steps/common.yml' 'unresolved'
        }
    }

    'case-10' = @{
        Mutation = 'Remove the orphan pipeline, its YAML node, and the definition edge joining them'
        Derived  = 'By building the node set from the edge list, so anything with no edges ceases to exist.'
        Expect   = 'missingNode, missingEdge'
        Apply    = {
            param($g)
            Remove-GraphEdge $g 'pipeline:p10-orphan' "$P/p10.yml" 'definition'
            Remove-GraphNode $g 'pipeline:p10-orphan'
            Remove-GraphNode $g "$P/p10.yml"
        }
    }

    'case-11' = @{
        Mutation = 'Collapse the checkout edge into the template kind'
        Derived  = 'By treating every repository a pipeline mentions as a source of templates. Inventing a template dependency from it produces an edge that is plausible, resolves, and is wrong.'
        Expect   = 'wrongEdgeKind'
        Apply    = {
            param($g)
            Set-GraphEdgeKind $g 'yaml:consumer-app/azure-pipelines.yml' 'repo:templates-shared' 'checkout' 'template'
        }
    }

    'case-12' = @{
        Mutation = 'Add a repo:ClaudeTesting node'
        Derived  = 'By calling the repositories endpoint and turning every repository into a node, rather than deriving the repository set from what the pipelines reference.'
        Expect   = 'extraNode'
        Apply    = {
            param($g)
            Add-GraphNode $g @{
                id = 'repo:ClaudeTesting'; kind = 'repo'; name = 'ClaudeTesting'
            }
        }
    }
}

# ------------------------------------------------------------------- action --

if ($List) {
    foreach ($k in $Mutations.Keys) {
        [pscustomobject]@{
            Case     = $k
            Expect   = $Mutations[$k].Expect
            Mutation = $Mutations[$k].Mutation
        }
    }
    return
}

if (-not $Mutations.Contains($CaseId)) {
    throw "No mutation defined for '$CaseId'. Supported: $(($Mutations.Keys) -join ', '). Run with -List for detail."
}

if (-not (Test-Path -LiteralPath $ExpectedPath)) {
    throw "Expected graph not found at $ExpectedPath"
}

$graph = Get-FreshGraph
$originalNodeCount = @($graph.nodes).Count
$originalEdgeCount = @($graph.edges).Count

& $Mutations[$CaseId].Apply $graph

# A mutation that changed nothing would make the acceptance test pass against a
# comparator that reports nothing. Refuse to emit one.
$changed = (@($graph.nodes).Count -ne $originalNodeCount) -or
           (@($graph.edges).Count -ne $originalEdgeCount)
if (-not $changed) {
    # Counts can be unchanged when the mutation repoints or re-kinds an edge, so
    # fall back to comparing serialised content.
    $before = (Get-Content -LiteralPath $ExpectedPath -Raw)
    $after  = ($graph | ConvertTo-Json -Depth 20)
    $normBefore = ((Get-FreshGraph) | ConvertTo-Json -Depth 20)
    if ($after -ceq $normBefore) {
        throw "The mutation for $CaseId changed nothing. A mutation that does not mutate cannot falsify anything."
    }
}

if ($OutputPath) {
    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $json = ($graph | ConvertTo-Json -Depth 20) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($OutputPath, $json + "`n", [Text.UTF8Encoding]::new($false))
    Write-Verbose "Wrote $CaseId mutation to $OutputPath"
}
else {
    $graph | ConvertTo-Json -Depth 20
}
