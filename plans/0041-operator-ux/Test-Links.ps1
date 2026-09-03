#Requires -Version 7.2
<#
.SYNOPSIS
    Resolve every internal link in the documents pass 0041 touched, every doc
    path in flow-graph.json, and every row of README's link map.
.DESCRIPTION
    A dead link in a document about where to find things is worse than no
    document: it reads exactly like a working one. This resolves them against
    the filesystem rather than against a reader's patience.

    THREE CLASSES, and the second and third are the ones a plain link checker
    misses:

    1. Markdown links in the touched files. Relative targets are resolved
       against the FILE's directory, and a `#anchor` on a .md target is
       checked against that file's actual headings, slugged GitHub's way. An
       anchor that no longer exists is a dead link that every checker written
       in an afternoon reports as live.
    2. Every `doc` attribute in docs/diagram/flow-graph.json. Those paths are
       the diagram's whole claim to be auditable, and nothing else reads them.
    3. Link-map COVERAGE: every node in the graph has a row in README's link
       map, and every row's target resolves. A map missing a row is not a dead
       link and is exactly as misleading as one.

    The file list is explicit rather than derived from `git diff`, so this runs
    identically in a fresh clone with no base commit to diff against.

    Pass 0040's copy with 0041's file list and one changed parser: the link map
    gained a "What it does" column, so the row regex reads four cells rather
    than three. Frozen plan artifacts are not edited (decision 0004), so this
    is a copy.

    Prints `DEAD LINKS: <n>` as its last line and exits non-zero above zero.
.PARAMETER RepoRoot
    Repository root. Defaults to two levels above this script.
.EXAMPLE
    $params = @{
        RepoRoot = 'C:/src/AI.Agent.Claude.PowerShellModuleBuilder'
    }

    $report = try {

        ./plans/0041-operator-ux/Test-Links.ps1 @params

    }
    catch {
        Write-Error "The link check could not run: $_"
        $null
    }

    $report
#>
[CmdletBinding()]
param([string] $RepoRoot = "$PSScriptRoot/../..")

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

# Everything pass 0040 created or edited. Named, so that a file added to the
# pass and forgotten here is a visible omission rather than a silent one.
$Touched = @(
    'README.md'
    'PLAN-PROTOCOL.md'
    'SECURITY.md'
    'LEDGER.md'
    'decisions/0013-harness-release-tagging.md'
    'docs/diagram/README.md'
    'docs/ux/README.md'
    'docs/ux/UX-001-routing-signals.md'
    'docs/ux/UX-002-ends-with-tripwire.md'
    'docs/ux/UX-003-report-contract.md'
    'docs/ux/UX-004-heartbeats.md'
    'docs/ux/UX-005-local-handoff.md'
    'docs/ux/UX-006-presentation-standard.md'
    'docs/creating-an-agent/01-the-two-claudes.md'
    'docs/creating-an-agent/06-the-pass-protocol.md'
    'docs/creating-an-agent/11-your-first-module.md'
    'docs/testing/README.md'
    'prompts/README.md'
    'prompts/project-context-template.md'
    'prompts/first-module.md'
    'prompts/new-feature.md'
    'prompts/release.md'
    'prompts/troubleshoot.md'
    'skills/powershell-module-ux/SKILL.md'
    'plans/0041-operator-ux/plan.md'
    'journal/0041-operator-ux.md'
)

function ConvertTo-Anchor {
    # GitHub's heading slug: lowercase, drop everything that is not a letter,
    # digit, space, hyphen or underscore, then spaces to hyphens. The em dash
    # this project writes in headings is DROPPED rather than replaced, leaving
    # the spaces either side of it - which is why "a - b" slugs with a double
    # hyphen. Implemented the same way here so the checker agrees with the
    # thing it is checking.
    param([Parameter(Mandatory)] [AllowEmptyString()] [string] $Heading)
    $text = $Heading.Trim() -replace '^#+\s*', ''
    $text = $text -replace '`', ''
    $text = $text.ToLowerInvariant()
    $text = $text -replace '[^\p{L}\p{Nd} _-]', ''
    ($text -replace ' ', '-')
}

$headingCache = @{}
function Get-Anchor {
    param([Parameter(Mandatory)] [string] $Path)
    if (-not $headingCache.ContainsKey($Path)) {
        $set = [System.Collections.Generic.HashSet[string]]::new()
        if (Test-Path -LiteralPath $Path) {
            $inFence = $false
            foreach ($line in Get-Content -LiteralPath $Path) {
                if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
                if ($inFence) { continue }
                if ($line -match '^#{1,6}\s') { $null = $set.Add((ConvertTo-Anchor -Heading $line)) }
            }
        }
        $headingCache[$Path] = $set
    }
    $headingCache[$Path]
}

$dead = [System.Collections.Generic.List[string]]::new()
$checked = 0

function Test-Target {
    param(
        [Parameter(Mandatory)] [string] $Target,
        [Parameter(Mandatory)] [string] $FromFile,
        [Parameter(Mandatory)] [string] $Context
    )

    if ($Target -match '^(https?:|mailto:|#)') {
        if ($Target.StartsWith('#')) {
            $anchors = Get-Anchor -Path $FromFile
            $script:checked++
            if (-not $anchors.Contains($Target.TrimStart('#'))) {
                $script:dead.Add("$Context -> '$Target' (no such heading in this file)")
            }
        }
        return
    }

    $path, $fragment = $Target -split '#', 2
    $path = [uri]::UnescapeDataString($path)
    $base = Split-Path -Parent $FromFile
    $resolved = Join-Path $base $path
    $script:checked++

    if (-not (Test-Path -LiteralPath $resolved)) {
        $script:dead.Add("$Context -> '$Target' (no such path)")
        return
    }
    if ($fragment -and $resolved -match '\.md$') {
        $full = (Resolve-Path -LiteralPath $resolved).Path
        if (-not (Get-Anchor -Path $full).Contains($fragment)) {
            $script:dead.Add("$Context -> '$Target' (file exists, heading does not)")
        }
    }
}

'LINK CHECK - pass 0041'
"root: $RepoRoot"
''

# --- 1. markdown links in the touched files --------------------------------
foreach ($relative in $Touched) {
    $file = Join-Path $RepoRoot $relative
    if (-not (Test-Path -LiteralPath $file)) {
        $dead.Add("TOUCHED FILE MISSING: $relative")
        continue
    }
    $text = Get-Content -LiteralPath $file -Raw
    # Strip fenced blocks: a path inside a pasteable prompt is an instruction
    # to the reader's own repository, not a link into this one.
    $prose = [regex]::Replace($text, '(?s)```.*?```', '')
    $before = $dead.Count
    foreach ($match in [regex]::Matches($prose, '\[(?:[^\]]*)\]\(([^)\s]+)\)')) {
        Test-Target -Target $match.Groups[1].Value -FromFile (Resolve-Path -LiteralPath $file).Path -Context $relative
    }
    "{0,-58} {1}" -f $relative, $(if ($dead.Count -eq $before) { 'ok' } else { "$($dead.Count - $before) DEAD" })
}

# --- 2. every doc attribute in the graph -----------------------------------
''
$graphPath = Join-Path $RepoRoot 'docs/diagram/flow-graph.json'
$graph = (Get-Content -LiteralPath $graphPath -Raw | ConvertFrom-Json).graph
$before = $dead.Count
foreach ($node in $graph.nodes) {
    $checked++
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $node.attributes.doc))) {
        $dead.Add("flow-graph.json node '$($node.id)' -> '$($node.attributes.doc)' (no such path)")
    }
}
"{0,-58} {1}" -f 'docs/diagram/flow-graph.json (doc attributes)', $(if ($dead.Count -eq $before) { "ok, $(@($graph.nodes).Count) nodes" } else { "$($dead.Count - $before) DEAD" })

# --- 3. link-map coverage ---------------------------------------------------
$readme = Get-Content -LiteralPath (Join-Path $RepoRoot 'README.md') -Raw
$section = [regex]::Match($readme, '(?s)### The link map(.*?)(?=\r?\n### )')
if (-not $section.Success) { throw 'README.md has no "### The link map" section, so its coverage cannot be checked.' }
$mapped = @{}
# Four cells now: Node | Layer | What it does | The artifact behind it. The
# Layer cell carries a link of its own, so the artifact link is the LAST one
# on the row rather than the second.
foreach ($row in [regex]::Matches($section.Groups[1].Value, '(?m)^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*\[[^\]]+\]\(([^)]+)\)\s*\|')) {
    $mapped[$row.Groups[1].Value] = $row.Groups[4].Value
}
$before = $dead.Count
foreach ($node in $graph.nodes) {
    if (-not $mapped.ContainsKey($node.label)) {
        $dead.Add("link map has no row for node '$($node.id)' (label '$($node.label)')")
    }
}
"{0,-58} {1}" -f 'README.md link map (coverage)', $(if ($dead.Count -eq $before) { "ok, $($mapped.Count) rows for $(@($graph.nodes).Count) nodes" } else { "$($dead.Count - $before) MISSING" })

''
"links resolved: $checked"
if ($dead.Count) {
    'DEAD:'
    $dead | ForEach-Object { "  $_" }
    ''
}
"DEAD LINKS: $($dead.Count)"
if ($dead.Count) { exit 1 }
