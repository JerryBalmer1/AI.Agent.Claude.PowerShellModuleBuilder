#Requires -Version 7.2

<#
.SYNOPSIS
    Scores a candidate pipeline graph against the declared one.

.DESCRIPTION
    Emits a structured difference report as JSON plus a human-readable summary.
    Exits 0 when the graphs agree and 1 when they do not.

    WHAT IT CLAIMS. That a candidate graph does or does not match
    expected-graph.json. It does NOT claim expected-graph.json is correct - that
    is a hand-authored oracle and nothing here can verify it. A candidate that
    agrees with a wrong oracle scores perfectly, and this script cannot tell.

    NEVER MODIFIES EITHER INPUT. Both are read as text and parsed; nothing is
    written back to either path.

    ORDER-INSENSITIVE. Nodes and edges are sets, not sequences. A graph is not
    more or less correct for having been assembled in a different order, and a
    comparator that cares would fail every candidate for a reason the candidate
    cannot control.

    EDGE MATCHING is staged, so that a repointed edge is reported as a wrong
    target rather than as one missing edge plus one extra edge:

      1. exact       - same from, to, kind and ref
      2. same from, kind and ref, different to  -> wrongEdgeTarget
      3. same from, to and ref, different kind  -> wrongEdgeKind
      4. whatever is left  -> missingEdge (expected) / extraEdge (candidate)

    A wrong resolution target is the failure cases 01 and 04 exist to catch.
    Reporting it as a missing-plus-extra pair is true and useless: it says the
    edge is absent when in fact it is present and pointing at the wrong file,
    which is a different defect with a different fix.

    CASE NAMING works by reading the `cases` tags on the EXPECTED side, so a
    report says which of the twelve declared cases a candidate failed. Absence
    cases cannot work that way - see $AbsenceCaseRules below.

.PARAMETER ExpectedPath
    The declared graph. Defaults to fixture/expected-graph.json.

.PARAMETER CandidatePath
    The graph to score.

.PARAMETER ReportPath
    Optional. Writes the structured JSON report here.

.PARAMETER Quiet
    Suppress the human-readable summary. The exit code and -ReportPath still work.

.EXAMPLE
    pwsh -NoProfile -File Compare-Graph.ps1 -CandidatePath runs/002-first/graph.json
#>
[CmdletBinding()]
param(
    [string]$ExpectedPath = (Join-Path $PSScriptRoot 'fixture/expected-graph.json'),

    [Parameter(Mandatory)]
    [string]$CandidatePath,

    [string]$ReportPath,

    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ==================================================================== scope ==
#
# EXCLUSIONS. Explicit, with a reason each, rather than implied by whatever the
# comparison code happens not to look at. An exclusion nobody wrote down is
# indistinguishable from a field somebody forgot to compare.

$Exclusions = @(
    @{
        field  = 'cases'
        reason = 'An oracle annotation. A module has never read cases.md and cannot produce case tags, so requiring them would fail every candidate for something it cannot know.'
    }
    @{
        field  = 'note'
        reason = 'Human prose explaining a node or edge to a reader. Carries no graph content.'
    }
    @{
        field  = 'generatedBy'
        reason = 'Names the command that produced a run graph. Absent from the oracle by design, per graph.schema.json, so comparing it would fail every real candidate.'
    }
    @{
        field  = '(array order)'
        reason = 'Nodes and edges are sets. A graph is not more correct for having been assembled in a particular order.'
    }
)

# Fields compared on each element, beyond identity.
$NodeAttributes = @('name', 'repo', 'path')
$EdgeAttributes = @('ref', 'refKind', 'alias', 'reason')

# ==================================================== absence-case naming ====
#
# An absence case claims something is NOT in the graph, so nothing in
# expected-graph.json can carry its tag - tagging a node with it would assert
# the opposite of the case. The tag lookup that names every presence case
# therefore cannot name an absence case, structurally, and no amount of care
# with the tags will change that.
#
# These rules are how an absence case gets named. They are deliberately few,
# explicit, and each carries the claim it comes from.

$AbsenceCaseRules = @(
    @{
        case   = 'case-12'
        reason = 'cases.md case-12: a repository nothing references is not in the graph. The pre-existing ClaudeTesting repository exists in the project and is referenced by no pipeline, so a node for it is exactly the failure the case describes.'
        test   = {
            param($d)
            $d.kind -eq 'extraNode' -and
            ($d.id -ceq 'repo:ClaudeTesting' -or $d.id -ceq 'ClaudeTesting' -or $d.name -ceq 'ClaudeTesting')
        }
    }
)

# ================================================================== reading ==

foreach ($p in @($ExpectedPath, $CandidatePath)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        Write-Error "Graph not found: $p"
        exit 2
    }
}

function Read-Graph {
    param([string]$Path)
    try { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
    catch { Write-Error "Could not parse JSON from ${Path}: $($_.Exception.Message)"; exit 2 }
}

$expected  = Read-Graph $ExpectedPath
$candidate = Read-Graph $CandidatePath

function Get-Prop {
    param($Object, [string]$Name)
    if ($null -eq $Object) { return $null }
    if ($Object.PSObject.Properties.Name -contains $Name) { return $Object.$Name }
    $null
}

$differences = [System.Collections.Generic.List[object]]::new()

function Add-Difference {
    param([hashtable]$Difference)
    $script:differences.Add([pscustomobject]$Difference)
}

# ================================================================= metadata ==

foreach ($field in @('version', 'organisation', 'project')) {
    $e = Get-Prop $expected $field
    $a = Get-Prop $candidate $field
    if ("$e" -cne "$a") {
        Add-Difference @{
            kind = 'metadata'; field = $field
            expectedValue = "$e"; actualValue = "$a"
            cases = @()
            detail = "graph $field is '$a', expected '$e'"
        }
    }
}

# ==================================================================== nodes ==

$expNodes = @{}
foreach ($n in @($expected.nodes)) { $expNodes[$n.id] = $n }
$candNodes = @{}
foreach ($n in @($candidate.nodes)) { $candNodes[$n.id] = $n }

foreach ($id in @($expNodes.Keys | Sort-Object)) {
    $e = $expNodes[$id]
    $eCases = @(Get-Prop $e 'cases')

    if (-not $candNodes.ContainsKey($id)) {
        Add-Difference @{
            kind = 'missingNode'; id = $id
            nodeKind = (Get-Prop $e 'kind'); name = (Get-Prop $e 'name')
            cases = $eCases
            detail = "node '$id' is in the expected graph and not in the candidate"
        }
        continue
    }

    $a = $candNodes[$id]

    if ((Get-Prop $e 'kind') -cne (Get-Prop $a 'kind')) {
        Add-Difference @{
            kind = 'wrongNodeKind'; id = $id
            expectedValue = (Get-Prop $e 'kind'); actualValue = (Get-Prop $a 'kind')
            cases = $eCases
            detail = "node '$id' has kind '$(Get-Prop $a 'kind')', expected '$(Get-Prop $e 'kind')'"
        }
    }

    foreach ($attr in $NodeAttributes) {
        $ev = Get-Prop $e $attr
        $av = Get-Prop $a $attr
        if ("$ev" -cne "$av") {
            Add-Difference @{
                kind = 'wrongNodeAttribute'; id = $id; field = $attr
                expectedValue = "$ev"; actualValue = "$av"
                cases = $eCases
                detail = "node '$id' has $attr '$av', expected '$ev'"
            }
        }
    }
}

foreach ($id in @($candNodes.Keys | Sort-Object)) {
    if ($expNodes.ContainsKey($id)) { continue }
    $a = $candNodes[$id]
    Add-Difference @{
        kind = 'extraNode'; id = $id
        nodeKind = (Get-Prop $a 'kind'); name = (Get-Prop $a 'name')
        cases = @()
        detail = "node '$id' is in the candidate and not in the expected graph"
    }
}

# ==================================================================== edges ==
#
# Staged matching. Each stage consumes the pairs it matches, so a later stage
# never re-matches something an earlier one already explained.

function Get-EdgeRef { param($Edge) $r = Get-Prop $Edge 'ref'; if ($null -eq $r) { '' } else { "$r" } }

$expEdges  = [System.Collections.Generic.List[object]]::new()
foreach ($e in @($expected.edges))  { $expEdges.Add($e) }
$candEdges = [System.Collections.Generic.List[object]]::new()
foreach ($e in @($candidate.edges)) { $candEdges.Add($e) }

# --- stage 1: exact (from, to, kind, ref)
$matchedPairs = [System.Collections.Generic.List[object]]::new()
for ($i = $expEdges.Count - 1; $i -ge 0; $i--) {
    $e = $expEdges[$i]
    for ($j = 0; $j -lt $candEdges.Count; $j++) {
        $a = $candEdges[$j]
        if ($e.from -ceq $a.from -and $e.to -ceq $a.to -and $e.kind -ceq $a.kind -and
            (Get-EdgeRef $e) -ceq (Get-EdgeRef $a)) {
            $matchedPairs.Add(@{ Expected = $e; Actual = $a })
            $expEdges.RemoveAt($i); $candEdges.RemoveAt($j)
            break
        }
    }
}

# --- stage 2: same from, kind, ref; different to  -> wrongEdgeTarget
for ($i = $expEdges.Count - 1; $i -ge 0; $i--) {
    $e = $expEdges[$i]
    for ($j = 0; $j -lt $candEdges.Count; $j++) {
        $a = $candEdges[$j]
        if ($e.from -ceq $a.from -and $e.kind -ceq $a.kind -and
            (Get-EdgeRef $e) -ceq (Get-EdgeRef $a) -and $e.to -cne $a.to) {
            Add-Difference @{
                kind = 'wrongEdgeTarget'
                from = $e.from; edgeKind = $e.kind; ref = (Get-EdgeRef $e)
                expectedTo = $e.to; actualTo = $a.to
                cases = @(Get-Prop $e 'cases')
                detail = "edge '$($e.from)' -[$($e.kind)]-> resolves to '$($a.to)', expected '$($e.to)'"
            }
            $matchedPairs.Add(@{ Expected = $e; Actual = $a })
            $expEdges.RemoveAt($i); $candEdges.RemoveAt($j)
            break
        }
    }
}

# --- stage 3: same from, to, ref; different kind  -> wrongEdgeKind
for ($i = $expEdges.Count - 1; $i -ge 0; $i--) {
    $e = $expEdges[$i]
    for ($j = 0; $j -lt $candEdges.Count; $j++) {
        $a = $candEdges[$j]
        if ($e.from -ceq $a.from -and $e.to -ceq $a.to -and
            (Get-EdgeRef $e) -ceq (Get-EdgeRef $a) -and $e.kind -cne $a.kind) {
            Add-Difference @{
                kind = 'wrongEdgeKind'
                from = $e.from; to = $e.to; ref = (Get-EdgeRef $e)
                expectedValue = $e.kind; actualValue = $a.kind
                cases = @(Get-Prop $e 'cases')
                detail = "edge '$($e.from)' -> '$($e.to)' has kind '$($a.kind)', expected '$($e.kind)'"
            }
            $matchedPairs.Add(@{ Expected = $e; Actual = $a })
            $expEdges.RemoveAt($i); $candEdges.RemoveAt($j)
            break
        }
    }
}

# --- stage 4: whatever is left
foreach ($e in $expEdges) {
    Add-Difference @{
        kind = 'missingEdge'
        from = $e.from; to = $e.to; edgeKind = $e.kind; ref = (Get-EdgeRef $e)
        cases = @(Get-Prop $e 'cases')
        detail = "edge '$($e.from)' -[$($e.kind)]-> '$($e.to)' is in the expected graph and not in the candidate"
    }
}
foreach ($a in $candEdges) {
    Add-Difference @{
        kind = 'extraEdge'
        from = $a.from; to = $a.to; edgeKind = $a.kind; ref = (Get-EdgeRef $a)
        cases = @()
        detail = "edge '$($a.from)' -[$($a.kind)]-> '$($a.to)' is in the candidate and not in the expected graph"
    }
}

# --- attributes on edges that matched exactly on identity
foreach ($pair in $matchedPairs) {
    $e = $pair.Expected; $a = $pair.Actual
    foreach ($attr in $EdgeAttributes) {
        if ($attr -eq 'ref') { continue }   # part of identity, already equal
        $ev = Get-Prop $e $attr
        $av = Get-Prop $a $attr
        if ("$ev" -cne "$av") {
            Add-Difference @{
                kind = 'wrongEdgeAttribute'
                from = $e.from; to = $e.to; edgeKind = $e.kind; field = $attr
                expectedValue = "$ev"; actualValue = "$av"
                cases = @(Get-Prop $e 'cases')
                detail = "edge '$($e.from)' -[$($e.kind)]-> '$($e.to)' has $attr '$av', expected '$ev'"
            }
        }
    }
}

# =========================================================== absence cases ==

foreach ($d in $differences) {
    foreach ($rule in $AbsenceCaseRules) {
        if (& $rule.test $d) {
            $existing = @($d.cases)
            if ($existing -notcontains $rule.case) {
                $d.cases = @($existing + $rule.case)
            }
        }
    }
}

# =================================================================== report ==

$affectedCases = @($differences | ForEach-Object { @($_.cases) } | Where-Object { $_ } | Sort-Object -Unique)

$report = [ordered]@{
    expected        = (Resolve-Path -LiteralPath $ExpectedPath).ProviderPath
    candidate       = (Resolve-Path -LiteralPath $CandidatePath).ProviderPath
    agree           = ($differences.Count -eq 0)
    differenceCount = $differences.Count
    cases           = $affectedCases
    countsByKind    = [ordered]@{}
    excluded        = $Exclusions
    differences     = @($differences)
}
foreach ($k in @($differences | ForEach-Object { $_.kind } | Sort-Object -Unique)) {
    $report.countsByKind[$k] = @($differences | Where-Object { $_.kind -eq $k }).Count
}

if ($ReportPath) {
    $dir = Split-Path -Parent $ReportPath
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $json = ($report | ConvertTo-Json -Depth 20) -replace "`r`n", "`n"
    [IO.File]::WriteAllText($ReportPath, $json + "`n", [Text.UTF8Encoding]::new($false))
}

if (-not $Quiet) {
    Write-Host "Compare-Graph"
    Write-Host "  expected  : $ExpectedPath"
    Write-Host "  candidate : $CandidatePath"
    Write-Host ''
    if ($differences.Count -eq 0) {
        Write-Host '  The graphs agree. 0 differences.' -ForegroundColor Green
    }
    else {
        Write-Host ("  {0} difference(s)" -f $differences.Count) -ForegroundColor Red
        foreach ($k in $report.countsByKind.Keys) {
            Write-Host ("    {0,-20} {1}" -f $k, $report.countsByKind[$k])
        }
        Write-Host ''
        foreach ($d in $differences) {
            $tag = if (@($d.cases).Count) { " [$(@($d.cases) -join ', ')]" } else { '' }
            Write-Host ("    {0,-20} {1}{2}" -f $d.kind, $d.detail, $tag)
        }
        if ($affectedCases.Count) {
            Write-Host ''
            Write-Host ("  cases failed: {0}" -f ($affectedCases -join ', ')) -ForegroundColor Red
        }
    }
    if ($ReportPath) { Write-Host ''; Write-Host "  report    : $ReportPath" }
}

if ($differences.Count -eq 0) { exit 0 } else { exit 1 }
