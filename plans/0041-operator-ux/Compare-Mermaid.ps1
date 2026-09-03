#Requires -Version 7.2
<#
.SYNOPSIS
    Compare README.md's hand-written Mermaid block against
    docs/diagram/flow-graph.json - nodes, labels, layer membership, edges, and
    the five layer COLOURS.
.DESCRIPTION
    The Mermaid block is a MIRROR, written by hand, of a graph that lives in
    JSON. Two statements of one thing drift, and prose is the half nobody
    re-derives. This is the check that makes the mirror an artifact rather
    than a decoration.

    Pass 0040's copy, plus the two colour comparisons pass 0041 added. Frozen
    plan artifacts are not edited (decision 0004), so this is a copy rather
    than a change, and the addition is stated here rather than buried:
    comparisons 5 and 6 are new.

    Six comparisons, and the third onward are the ones that would catch a real
    mistake:

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
    5. classDef COLOURS against meta.layerPalette. The Mermaid restates five
       hexes the JSON declares, and a hand-copied colour is a second source of
       truth. This is the check that keeps one palette one palette.
    6. class MEMBERSHIP against node scope. A node in the right subgraph and
       the wrong colour class is a diagram that contradicts itself, and it is
       the failure a reader is least likely to doubt - the subgraph title says
       one layer and the fill says another, and the fill is the louder signal.

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
$mermaidClassFill = [ordered]@{}
$mermaidNodeClass = [ordered]@{}
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

    # classDef layerMethod fill:#A99BF2,stroke:...,color:#0b0f14;
    if ($text -match '^classDef\s+([A-Za-z0-9_]+)\s+(.+);$') {
        $className = $Matches[1]
        $style = $Matches[2]
        # An explicit Match rather than reading $Matches after a -notmatch.
        # The automatic variable does get set there, and a check that works by
        # accident is a check nobody can safely edit.
        $fill = [regex]::Match($style, 'fill:\s*(#[0-9A-Fa-f]{6})')
        if (-not $fill.Success) {
            throw "classDef '$className' declares no six-digit fill, so there is no colour to compare: '$style'"
        }
        $mermaidClassFill[$className] = $fill.Groups[1].Value.ToUpperInvariant()
        continue
    }

    # class a,b,c layerMethod;
    if ($text -match '^class\s+([A-Za-z0-9_,.-]+)\s+([A-Za-z0-9_]+);$') {
        $className = $Matches[2]
        foreach ($id in ($Matches[1] -split ',')) {
            $id = $id.Trim()
            if (-not $id) { continue }
            if ($mermaidNodeClass.Contains($id)) {
                throw "Mermaid assigns node '$id' to a colour class twice ('$($mermaidNodeClass[$id])' and '$className'); the later one wins silently and the diagram then contradicts its own subgraph."
            }
            $mermaidNodeClass[$id] = $className
        }
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

# --- 5. the palette ---------------------------------------------------------
$palette = $graph.meta.layerPalette
if (-not $palette) { throw 'flow-graph.json declares no meta.layerPalette, so the Mermaid colours have nothing to be checked against.' }
$paletteKeys = @($palette.PSObject.Properties.Name)
"colours: mermaid $($mermaidClassFill.Count) classDefs, json $($paletteKeys.Count) palette entries"

# layerMethod <-> method. Stated once, here, so the two naming conventions
# cannot be reconciled differently in two places.
function ConvertTo-LayerKey { param([string] $ClassName) ($ClassName -replace '^layer', '').ToLowerInvariant() }

foreach ($className in @($mermaidClassFill.Keys)) {
    $key = ConvertTo-LayerKey -ClassName $className
    if ($key -notin $paletteKeys) {
        $problems.Add("mermaid declares classDef '$className' and meta.layerPalette has no '$key'")
        continue
    }
    $want = ([string]$palette.$key).ToUpperInvariant()
    if ($mermaidClassFill[$className] -ne $want) {
        $problems.Add("COLOUR differs for layer '$key': mermaid '$($mermaidClassFill[$className])', json '$want'")
    }
}
foreach ($key in $paletteKeys) {
    $expected = 'layer' + $key.Substring(0, 1).ToUpper() + $key.Substring(1)
    if (-not $mermaidClassFill.Contains($expected)) {
        $problems.Add("meta.layerPalette names layer '$key' and the mermaid declares no classDef '$expected'")
    }
}

# --- 6. class membership ----------------------------------------------------
foreach ($id in @($jsonNodes.Keys)) {
    if (-not $mermaidNodeClass.Contains($id)) {
        $problems.Add("mermaid node '$id' is in no colour class, so it draws in the default fill and states no layer by colour")
        continue
    }
    $key = ConvertTo-LayerKey -ClassName $mermaidNodeClass[$id]
    if ($key -ne $jsonLayer[$id]) {
        $problems.Add("COLOUR CLASS differs for '$id': mermaid class says layer '$key', json says '$($jsonLayer[$id])'")
    }
}

if ($problems.Count -eq 0) {
    'MERMAID AND JSON AGREE: same ids, same labels, same layer membership, same edges, same five layer colours, same colour class per node'
    exit 0
}
'MERMAID AND JSON DISAGREE:'
$problems | ForEach-Object { "  $_" }
exit 1
