#Requires -Version 7.2

<#
.SYNOPSIS
    Renders a pipeline dependency graph JSON file as a self-contained HTML page.

.DESCRIPTION
    Reads a graph in the shape of evals/functional/fixture/graph.schema.json —
    the hand-written oracle, or the graph any later run produced — and writes one
    HTML file containing an inline SVG.

    Self-contained means self-contained: no CDN, no <script src>, no <link
    rel="stylesheet">, no web fonts, no network access at view time. The SVG is
    computed here in PowerShell and written into the page. The output contains
    no http:// or https:// at all, which is why the <svg> element carries no
    xmlns attribute — inline SVG in an HTML document does not need one.

    Layout is layered left to right by depth. Depth comes from a breadth-first
    walk with a visited set, so a cycle terminates: an edge back to an
    already-numbered node is drawn and not followed. Nodes that no walk from a
    root can reach — a cycle with no entry point — are seeded as roots of their
    own rather than dropped.

    Real nodes carry data-node-id. Targets of unresolved edges are drawn as
    pseudo-nodes carrying data-unresolved-id instead, because they are not nodes
    of the graph: counting data-node-id gives exactly the graph's node count.

.PARAMETER GraphPath
    The graph JSON to render.

.PARAMETER OutputPath
    The HTML file to write.

.PARAMETER Title
    Page heading. Defaults to the graph's project name.

.EXAMPLE
    ./runs/Render-Graph.ps1 -GraphPath evals/functional/fixture/expected-graph.json -OutputPath runs/000-expected/000.html
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$GraphPath,
    [Parameter(Mandatory)][string]$OutputPath,
    [string]$Title
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- geometry
$NodeWidth = 250
$NodeHeight = 34
$RowGap = 14
$ColumnGap = 130
$MarginX = 32
$MarginTop = 132
$MarginBottom = 40

# ------------------------------------------------------------------ styles
$NodeStyle = @{
    pipeline   = @{ Fill = '#dbe7fb'; Stroke = '#2f5fb5'; Text = '#16305e'; Label = 'pipeline definition' }
    yaml       = @{ Fill = '#dff0e0'; Stroke = '#2e7d32'; Text = '#17431a'; Label = 'YAML file' }
    repo       = @{ Fill = '#fdeccd'; Stroke = '#a86b12'; Text = '#573604'; Label = 'repository' }
    unresolved = @{ Fill = '#fadbd8'; Stroke = '#b3261e'; Text = '#5d1310'; Label = 'unresolved target (not a node)' }
}

$EdgeStyle = [ordered]@{
    definition         = @{ Colour = '#8d8d8d'; Dash = ''; Width = 1.4; Label = 'definition -> its YAML' }
    template           = @{ Colour = '#2e7d32'; Dash = ''; Width = 1.6; Label = 'template' }
    extends            = @{ Colour = '#6a1b9a'; Dash = ''; Width = 2.6; Label = 'extends' }
    pipelineResource   = @{ Colour = '#2f5fb5'; Dash = '7 4'; Width = 1.8; Label = 'resources.pipelines' }
    repositoryResource = @{ Colour = '#a86b12'; Dash = '2 3'; Width = 1.5; Label = 'resources.repositories' }
    checkout           = @{ Colour = '#00727f'; Dash = '1 4'; Width = 2.0; Label = 'checkout (repo dependency, not a template)' }
    unresolved         = @{ Colour = '#b3261e'; Dash = '5 4'; Width = 2.2; Label = 'unresolved reference' }
}

function ConvertTo-HtmlText {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return '' }
    $Text.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;')
}

# -------------------------------------------------------------------- load
$graph = Get-Content -LiteralPath $GraphPath -Raw | ConvertFrom-Json
foreach ($required in 'nodes', 'edges') {
    if ($graph.PSObject.Properties.Name -notcontains $required) {
        throw "$GraphPath has no '$required' array."
    }
}
$nodes = @($graph.nodes)
$edges = @($graph.edges)
if ($nodes.Count -eq 0) { throw "$GraphPath declares no nodes." }

if (-not $Title) {
    $Title = if ($graph.PSObject.Properties.Name -contains 'project') { $graph.project } else { 'Pipeline dependency graph' }
}

$nodeById = @{}
foreach ($node in $nodes) { $nodeById[$node.id] = $node }

# Targets that are not nodes. Only unresolved edges may have one; anything else
# pointing at a missing id is a defect in the graph and is worth saying so.
$pseudoIds = [System.Collections.Generic.List[string]]::new()
foreach ($edge in $edges) {
    if ($nodeById.ContainsKey($edge.to)) { continue }
    if ($edge.kind -ne 'unresolved') {
        throw "Edge $($edge.from) -> $($edge.to) is of kind '$($edge.kind)' and its target is not a declared node."
    }
    if (-not $pseudoIds.Contains($edge.to)) { $pseudoIds.Add($edge.to) }
}

$allIds = @($nodes | ForEach-Object { $_.id }) + @($pseudoIds)

# ------------------------------------------------------------------- depth
$outgoing = @{}
$inDegree = @{}
foreach ($id in $allIds) {
    $outgoing[$id] = [System.Collections.Generic.List[string]]::new()
    $inDegree[$id] = 0
}
foreach ($edge in $edges) {
    if (-not $outgoing.ContainsKey($edge.from)) {
        throw "Edge source $($edge.from) is not a declared node."
    }
    $outgoing[$edge.from].Add($edge.to)
    $inDegree[$edge.to] = $inDegree[$edge.to] + 1
}

$depth = @{}
function Add-BfsFrom {
    param([string[]]$Seeds)
    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($seed in $Seeds) {
        if ($depth.ContainsKey($seed)) { continue }
        $depth[$seed] = 0
        $queue.Enqueue($seed)
    }
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        foreach ($next in $outgoing[$current]) {
            # The visited set is what makes a cycle terminate. The edge back
            # into an already-numbered node is still drawn; it is just not
            # followed a second time.
            if ($depth.ContainsKey($next)) { continue }
            $depth[$next] = $depth[$current] + 1
            $queue.Enqueue($next)
        }
    }
}

Add-BfsFrom -Seeds @($allIds | Where-Object { $inDegree[$_] -eq 0 } | Sort-Object)

# Whatever is left is in a component with no in-degree-zero entry point: a pure
# cycle. Seed it rather than dropping it. Each round places at least one node,
# so this ends.
while ($true) {
    $stranded = @($allIds | Where-Object { -not $depth.ContainsKey($_) } | Sort-Object)
    if ($stranded.Count -eq 0) { break }
    Add-BfsFrom -Seeds @($stranded[0])
}

# ------------------------------------------------------------------ layout
function Get-NodeKind {
    param([string]$Id)
    if ($nodeById.ContainsKey($Id)) { return $nodeById[$Id].kind }
    return 'unresolved'
}
function Get-NodeLabel {
    param([string]$Id)
    if ($nodeById.ContainsKey($Id)) { return $nodeById[$Id].name }
    return $Id
}
function Get-NodeSubLabel {
    param([string]$Id)
    if (-not $nodeById.ContainsKey($Id)) { return 'unresolved' }
    $node = $nodeById[$Id]
    if ($node.PSObject.Properties.Name -contains 'repo') { return $node.repo }
    return $node.kind
}

$columns = @{}
foreach ($id in $allIds) {
    $d = $depth[$id]
    if (-not $columns.ContainsKey($d)) { $columns[$d] = [System.Collections.Generic.List[string]]::new() }
    $columns[$d].Add($id)
}

$position = @{}
$maxRows = 0
foreach ($d in ($columns.Keys | Sort-Object)) {
    $ordered = @($columns[$d] | Sort-Object @{ Expression = { Get-NodeKind $_ } }, @{ Expression = { Get-NodeLabel $_ } })
    if ($ordered.Count -gt $maxRows) { $maxRows = $ordered.Count }
    for ($row = 0; $row -lt $ordered.Count; $row++) {
        $position[$ordered[$row]] = [pscustomobject]@{
            X = $MarginX + $d * ($NodeWidth + $ColumnGap)
            Y = $MarginTop + $row * ($NodeHeight + $RowGap)
        }
    }
}

$columnCount = ($columns.Keys | Measure-Object -Maximum).Maximum + 1
$canvasWidth = $MarginX * 2 + $columnCount * $NodeWidth + ($columnCount - 1) * $ColumnGap
$canvasHeight = $MarginTop + $maxRows * ($NodeHeight + $RowGap) + $MarginBottom

# --------------------------------------------------------------------- svg
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("<svg class=`"graph`" viewBox=`"0 0 $canvasWidth $canvasHeight`" width=`"$canvasWidth`" height=`"$canvasHeight`" role=`"img`" aria-label=`"Pipeline dependency graph`">")
$null = $sb.AppendLine('  <defs>')
foreach ($kind in $EdgeStyle.Keys) {
    $colour = $EdgeStyle[$kind].Colour
    $null = $sb.AppendLine("    <marker id=`"arrow-$kind`" viewBox=`"0 0 10 10`" refX=`"9`" refY=`"5`" markerWidth=`"7`" markerHeight=`"7`" orient=`"auto-start-reverse`"><path d=`"M 0 0 L 10 5 L 0 10 z`" fill=`"$colour`" /></marker>")
}
$null = $sb.AppendLine('  </defs>')

# Edges first, so nodes sit on top of them.
$null = $sb.AppendLine('  <g class="edges">')
foreach ($edge in $edges) {
    $from = $position[$edge.from]
    $to = $position[$edge.to]
    $style = if ($EdgeStyle.Contains($edge.kind)) { $EdgeStyle[$edge.kind] } else { @{ Colour = '#555555'; Dash = ''; Width = 1.4 } }

    $x1 = $from.X + $NodeWidth
    $y1 = $from.Y + $NodeHeight / 2
    $x2 = $to.X
    $y2 = $to.Y + $NodeHeight / 2

    if ($x2 -le $x1) {
        # Backward or same-column: leave the left side of the source, re-enter
        # the left side of the target, and bow out to the left so the two are
        # distinguishable. This is what a cycle looks like.
        $x1 = $from.X
        $bow = 60 + [Math]::Abs($y2 - $y1) / 3
        $c1x = $x1 - $bow
        $c2x = $x2 - $bow
        $path = "M $x1 $y1 C $c1x $y1 $c2x $y2 $x2 $y2"
    }
    else {
        $span = [Math]::Max(40, ($x2 - $x1) / 2)
        $c1x = $x1 + $span
        $c2x = $x2 - $span
        $path = "M $x1 $y1 C $c1x $y1 $c2x $y2 $x2 $y2"
    }

    $dash = if ($style.Dash) { " stroke-dasharray=`"$($style.Dash)`"" } else { '' }
    $title = ConvertTo-HtmlText "$($edge.from)  --[$($edge.kind)]-->  $($edge.to)"
    $null = $sb.AppendLine("    <path class=`"edge`" d=`"$path`" fill=`"none`" stroke=`"$($style.Colour)`" stroke-width=`"$($style.Width)`"$dash marker-end=`"url(#arrow-$($edge.kind))`"><title>$title</title></path>")
}
$null = $sb.AppendLine('  </g>')

$null = $sb.AppendLine('  <g class="nodes">')
foreach ($id in ($allIds | Sort-Object)) {
    $point = $position[$id]
    $kind = Get-NodeKind $id
    $style = $NodeStyle[$kind]
    $label = ConvertTo-HtmlText (Get-NodeLabel $id)
    $sub = ConvertTo-HtmlText (Get-NodeSubLabel $id)
    $attr = if ($nodeById.ContainsKey($id)) { "data-node-id=`"$(ConvertTo-HtmlText $id)`"" } else { "data-unresolved-id=`"$(ConvertTo-HtmlText $id)`"" }
    $dash = if ($kind -eq 'unresolved') { ' stroke-dasharray="5 3"' } else { '' }
    $tip = ConvertTo-HtmlText $id

    $null = $sb.AppendLine("    <g $attr>")
    $null = $sb.AppendLine("      <title>$tip</title>")
    $null = $sb.AppendLine("      <rect x=`"$($point.X)`" y=`"$($point.Y)`" width=`"$NodeWidth`" height=`"$NodeHeight`" rx=`"6`" fill=`"$($style.Fill)`" stroke=`"$($style.Stroke)`" stroke-width=`"1.4`"$dash />")
    $null = $sb.AppendLine("      <text x=`"$($point.X + 10)`" y=`"$($point.Y + 14)`" class=`"n-label`" fill=`"$($style.Text)`">$label</text>")
    $null = $sb.AppendLine("      <text x=`"$($point.X + 10)`" y=`"$($point.Y + 26)`" class=`"n-sub`" fill=`"$($style.Text)`">$sub</text>")
    $null = $sb.AppendLine('    </g>')
}
$null = $sb.AppendLine('  </g>')
$null = $sb.AppendLine('</svg>')

# -------------------------------------------------------------------- html
$nodeCount = $nodes.Count
$edgeCount = $edges.Count
$kindCounts = ($nodes | Group-Object kind | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Count)" }) -join ' &middot; '
$edgeCounts = ($edges | Group-Object kind | Sort-Object Name | ForEach-Object { "$($_.Name) $($_.Count)" }) -join ' &middot; '

$legendNodes = ($NodeStyle.Keys | Sort-Object | ForEach-Object {
        $s = $NodeStyle[$_]
        "<li><span class=`"swatch`" style=`"background:$($s.Fill);border-color:$($s.Stroke)`"></span>$(ConvertTo-HtmlText $s.Label)</li>"
    }) -join "`n        "

$legendEdges = ($EdgeStyle.Keys | ForEach-Object {
        $s = $EdgeStyle[$_]
        $dash = if ($s.Dash) { "stroke-dasharray:$($s.Dash)" } else { '' }
        "<li><svg class=`"line`" viewBox=`"0 0 44 8`" width=`"44`" height=`"8`"><line x1=`"1`" y1=`"4`" x2=`"43`" y2=`"4`" stroke=`"$($s.Colour)`" stroke-width=`"$($s.Width)`" style=`"$dash`" /></svg>$(ConvertTo-HtmlText $s.Label)</li>"
    }) -join "`n        "

$html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$(ConvertTo-HtmlText $Title) — pipeline dependency graph</title>
<style>
  :root { color-scheme: light; }
  body { margin: 0; background: #f6f7f9; color: #1c1d20;
         font: 14px/1.45 ui-sans-serif, "Segoe UI", system-ui, sans-serif; }
  header { padding: 20px 24px 12px; }
  h1 { margin: 0 0 4px; font-size: 19px; }
  .counts { color: #55585f; font-size: 12.5px; }
  .legend { display: flex; flex-wrap: wrap; gap: 28px; padding: 0 24px 14px; }
  .legend h2 { margin: 0 0 6px; font-size: 12px; text-transform: uppercase;
               letter-spacing: .06em; color: #55585f; }
  .legend ul { margin: 0; padding: 0; list-style: none; font-size: 12.5px; }
  .legend li { display: flex; align-items: center; gap: 8px; margin: 3px 0; }
  .swatch { width: 22px; height: 12px; border-radius: 3px; border: 1.4px solid; display: inline-block; }
  .line { flex: 0 0 auto; }
  .canvas { overflow-x: auto; padding: 0 24px 32px; }
  svg.graph { display: block; background: #ffffff; border: 1px solid #e2e4e8; border-radius: 8px; }
  .n-label { font: 600 11.5px ui-monospace, "Cascadia Mono", Consolas, monospace; }
  .n-sub { font: 10px ui-monospace, "Cascadia Mono", Consolas, monospace; opacity: .72; }
  path.edge { opacity: .85; }
  footer { padding: 0 24px 28px; color: #7a7d84; font-size: 12px; }
</style>
</head>
<body>
<header>
  <h1>$(ConvertTo-HtmlText $Title)</h1>
  <div class="counts">$nodeCount nodes ($kindCounts) &nbsp;|&nbsp; $edgeCount edges ($edgeCounts)</div>
</header>
<div class="legend">
  <div>
    <h2>Nodes</h2>
    <ul>
        $legendNodes
    </ul>
  </div>
  <div>
    <h2>Edges</h2>
    <ul>
        $legendEdges
    </ul>
  </div>
</div>
<div class="canvas">
$($sb.ToString())
</div>
<footer>
  Layered left to right by breadth-first depth. Cycles are drawn, bowing left,
  and are not followed twice. Rendered from $(ConvertTo-HtmlText (Split-Path -Leaf $GraphPath)) by runs/Render-Graph.ps1.
</footer>
</body>
</html>
"@

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    $null = New-Item -ItemType Directory -Path $outDir -Force
}
Set-Content -LiteralPath $OutputPath -Value $html -Encoding utf8NoBOM

[pscustomobject]@{
    OutputPath = (Resolve-Path -LiteralPath $OutputPath).Path
    Nodes      = $nodeCount
    Edges      = $edgeCount
    Pseudo     = $pseudoIds.Count
    Columns    = $columnCount
}
