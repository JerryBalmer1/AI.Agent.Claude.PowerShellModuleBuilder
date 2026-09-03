#Requires -Version 7.2
<#
.SYNOPSIS
    Compare README.md's hand-written Mermaid block against
    docs/diagram/flow-graph.json - nodes, labels, layer membership and edges.
.DESCRIPTION
    The Mermaid block is a MIRROR, written by hand, of a graph that lives in
    JSON. Two statements of one thing drift, and prose is the half nobody
    re-derives. This is the check that makes the mirror an artifact rather
    than a decoration.

    Four comparisons, and the third and fourth are the ones that would catch a
    real mistake:

    1. node COUNT - the cheap one, and the only one the prompt asked for.
    2. node IDS - a count agrees while a node is renamed.
    3. LABEL and LAYER per id. Layer membership is the reason the diagram is
       shaped the way it is; a node in the wrong subgraph reads as a claim
       about what rests on what.
    4. EDGES, orientation-corrected. The two files state the same pairs in
       OPPOSITE directions and this is deliberate: Mermaid's `a --> b` under
       `flowchart BT` draws b above a, so it reads "a, then b"; the producer
       contract's edge means "from depends on to", so `to` is drawn below.
       Mermaid `a --> b` therefore equals JSON { from: b, to: a }. Comparing
       them without the flip would report every edge as wrong, and comparing
       them as unordered pairs would let a genuinely reversed edge through.

    Exit 0 when they agree, 1 otherwise, naming what disagreed.
.PARAMETER RepoRoot
    Repository root. Defaults to two levels above this script.
.EXAMPLE
    $params = @{
        RepoRoot = 'C:/src/AI.Agent.Claude.PowerShellModuleBuilder'
    }

    $agreed = try {

        ./plans/0040-flow-docs/Compare-Mermaid.ps1 @params
        $true

    }
    catch {
        Write-Error "The two renderings could not be compared: $_"
        $false
    }

    $agreed
#>
[CmdletBinding()]
param([string] $RepoRoot = "$PSScriptRoot/../..")

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$readme = Get-Content -LiteralPath (Join-Path $RepoRoot 'README.md') -Raw
$graph = (Get-Content -LiteralPath (Join-Path $RepoRoot 'docs/diagram/flow-graph.json') -Raw | ConvertFrom-Json).graph

# ---------------------------------------------------------------------------
# The Mermaid side.
# ---------------------------------------------------------------------------
$blocks = @([regex]::Matches($readme, '(?s)```mermaid\r?\n(.*?)```'))
if ($blocks.Count -ne 1) {
    throw "README.md holds $($blocks.Count) mermaid block(s); this check assumes exactly one, and would compare the wrong one."
}
$lines = $blocks[0].Groups[1].Value -split "`r?`n"

$mermaidNodes = [ordered]@{}
$mermaidLayer = [ordered]@{}
$mermaidEdges = [System.Collections.Generic.List[string]]::new()
$layer = $null

foreach ($line in $lines) {
    $text = $line.Trim()
    if (-not $text -or $text.StartsWith('%%')) { continue }

    if ($text -match '^subgraph\s+layer_([A-Za-z]+)\[') { $layer = $Matches[1]; continue }
    if ($text -eq 'end') { $layer = $null; continue }
    if ($text -match '^flowchart\b') { continue }

    # An edge first: a node declaration never contains an arrow.
    if ($text -match '^([A-Za-z0-9_.-]+)\s*-->(?:\|[^|]*\|)?\s*([A-Za-z0-9_.-]+)\s*$') {
        # Mermaid a --> b is JSON { from = b; to = a }. Recorded in the JSON's
        # own orientation so the comparison below is a set difference.
        $mermaidEdges.Add("$($Matches[2])->$($Matches[1])")
        continue
    }

    if ($text -match '^([A-Za-z0-9_.-]+)\["(.+)"\]$') {
        $id = $Matches[1]
        if ($mermaidNodes.Contains($id)) { throw "Mermaid declares '$id' twice." }
        $mermaidNodes[$id] = $Matches[2]
        if (-not $layer) { throw "Mermaid node '$id' is declared outside any layer_* subgraph, so it states no layer." }
        $mermaidLayer[$id] = $layer
        continue
    }

    throw "Unparsed line in the mermaid block, so this check cannot claim to have compared everything: '$text'"
}

# ---------------------------------------------------------------------------
# The JSON side.
# ---------------------------------------------------------------------------
$jsonNodes = [ordered]@{}
$jsonLayer = [ordered]@{}
foreach ($node in $graph.nodes) { $jsonNodes[$node.id] = $node.label; $jsonLayer[$node.id] = $node.scope }
$jsonEdges = @($graph.edges | ForEach-Object { "$($_.from)->$($_.to)" })

# ---------------------------------------------------------------------------
# Compare.
# ---------------------------------------------------------------------------
$problems = [System.Collections.Generic.List[string]]::new()

"nodes:  mermaid $($mermaidNodes.Count), json $($jsonNodes.Count)"
"edges:  mermaid $($mermaidEdges.Count), json $($jsonEdges.Count)"
"layers: mermaid $(@($mermaidLayer.Values | Sort-Object -Unique).Count), json $(@($jsonLayer.Values | Sort-Object -Unique).Count)"

if ($mermaidNodes.Count -ne $jsonNodes.Count) {
    $problems.Add("node COUNT differs: mermaid $($mermaidNodes.Count), json $($jsonNodes.Count)")
}
foreach ($id in @($mermaidNodes.Keys)) {
    if (-not $jsonNodes.Contains($id)) { $problems.Add("mermaid has node '$id' and the json does not") }
}
foreach ($id in @($jsonNodes.Keys)) {
    if (-not $mermaidNodes.Contains($id)) { $problems.Add("the json has node '$id' and mermaid does not"); continue }
    if ($mermaidNodes[$id] -ne $jsonNodes[$id]) {
        $problems.Add("label differs for '$id': mermaid '$($mermaidNodes[$id])', json '$($jsonNodes[$id])'")
    }
    if ($mermaidLayer[$id] -ne $jsonLayer[$id]) {
        $problems.Add("LAYER differs for '$id': mermaid '$($mermaidLayer[$id])', json '$($jsonLayer[$id])'")
    }
}

$mermaidSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$mermaidEdges)
$jsonSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$jsonEdges)
foreach ($edge in $mermaidEdges) { if (-not $jsonSet.Contains($edge)) { $problems.Add("mermaid draws edge $edge and the json does not") } }
foreach ($edge in $jsonEdges) { if (-not $mermaidSet.Contains($edge)) { $problems.Add("the json states edge $edge and mermaid does not") } }

if ($problems.Count -eq 0) {
    'MERMAID AND JSON AGREE: same ids, same labels, same layer membership, same edges'
    exit 0
}
'MERMAID AND JSON DISAGREE:'
$problems | ForEach-Object { "  $_" }
exit 1
