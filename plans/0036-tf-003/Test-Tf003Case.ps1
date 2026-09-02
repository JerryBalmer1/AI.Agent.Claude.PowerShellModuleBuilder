#Requires -Version 7.2
<#
.SYNOPSIS
    Score a produced graph against the seven NAMED cases in
    evals/tf/fixture2/cases.md, each by its own assertions.

.DESCRIPTION
    `evals/tf/Test-TfFixtureCase.ps1` scores fixture 1 and is hard-coded to
    TfFixtureShared / TfFixtureNetwork / TfFixtureApp. Fixture 2 arrived at pass
    0035 with cases.md, an oracle and a falsification driver, and NO case
    scorer, so "functional-tf: N / 7" had nothing to come from. This file is
    that scorer, written in the same shape as fixture 1's.

    It lives under plans/ rather than under evals/ because pass 0036 may not
    touch evals/. Promoting it is recorded as a backlog item; until then, a
    fixture-2 run has to carry its own scorer, which is exactly the kind of
    thing that goes stale.

    Every case is checked by assertions over the graph, NOT by asking whether
    the comparator found zero differences. Those are different claims: a graph
    can match the oracle exactly and the cases still be worth stating
    separately, and a case can pass while other differences remain.

    The ids are the ORACLE's ids, literally, as fixture 1's scorer uses fixture
    1's. A producer whose node carries the right meaning under a different id
    fails the case, because an id is what makes two producers' graphs mergeable
    and a case scorer that normalised ids would be grading something else.

.PARAMETER Path
    The produced graph to score.

.PARAMETER ReportPath
    Write the report here as well as returning it.

.OUTPUTS
    PSCustomObject: Passed, Total, Cases (Name, Result), Report.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter()]
    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) { throw "No such graph: '$Path'." }
$graph = (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json).graph

$byId = @{}
foreach ($node in @($graph.nodes)) { $byId[[string]$node.id] = $node }

function Test-Edge {
    param([string] $From, [string] $To, [string] $Kind)
    @(@($graph.edges) | Where-Object { $_.from -eq $From -and $_.to -eq $To -and $_.kind -eq $Kind }).Count
}
function Get-Attribute {
    param([string] $Id, [string] $Name)
    $node = $byId[$Id]
    if (-not $node) { return $null }
    $attributes = $node.PSObject.Properties['attributes']
    if (-not $attributes -or -not $attributes.Value) { return $null }
    $property = $attributes.Value.PSObject.Properties[$Name]
    if (-not $property) { return $null }
    $property.Value
}
function Get-Parent {
    param([string] $Id)
    $node = $byId[$Id]
    if (-not $node) { return $null }
    $property = $node.PSObject.Properties['parentId']
    if (-not $property) { return $null }
    $property.Value
}
function Test-EdgeField {
    param([string] $From, [string] $To, [string] $Name)
    $edge = @(@($graph.edges) | Where-Object { $_.from -eq $From -and $_.to -eq $To }) | Select-Object -First 1
    if (-not $edge) { return $null }
    $property = $edge.PSObject.Properties[$Name]
    if (-not $property) { return $null }
    $property.Value
}

$vendorProbe = 'TfSiteEdge:git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteVendor//modules/probe?ref=main'
$vault = 'TfSiteOps:../site-archive/modules/vault'

$cases = [ordered]@{
    '1 nested-module chain, four levels'                  = {
        (Test-Edge 'TfSiteEdge:.' 'TfSiteEdge:modules/edge' 'sources') -eq 1 -and
        (Test-Edge 'TfSiteEdge:modules/edge' 'TfSiteEdge:modules/edge/modules/pop' 'sources') -eq 1 -and
        (Test-Edge 'TfSiteEdge:modules/edge/modules/pop' 'TfSiteEdge:modules/edge/modules/pop/modules/probe' 'sources') -eq 1 -and
        (Get-Parent 'TfSiteEdge:modules/edge') -eq 'TfSiteEdge:.' -and
        (Get-Parent 'TfSiteEdge:modules/edge/modules/pop') -eq 'TfSiteEdge:modules/edge' -and
        (Get-Parent 'TfSiteEdge:modules/edge/modules/pop/modules/probe') -eq 'TfSiteEdge:modules/edge/modules/pop'
    }

    '2 cross-repository source, git:: with //subdirectory' = {
        (Test-Edge 'TfSiteEdge:.' 'TfSiteCore:modules/label' 'sources') -eq 1 -and
        (Test-Edge 'TfSiteOps:.' 'TfSiteCore:modules/policy' 'sources') -eq 1
    }

    '3 cross-repository output reference'                  = {
        # The root-module call: no //subdirectory is what names the root.
        (Test-Edge 'TfSiteOps:.' 'TfSiteEdge:.' 'sources') -eq 1 -and
        # ... read into a local AND into an output.
        (Test-Edge 'TfSiteEdge:.#output.pop_ids' 'TfSiteOps:.#local.edge_pop_ids' 'references') -eq 1 -and
        (Test-Edge 'TfSiteEdge:.#output.edge_endpoint' 'TfSiteOps:.#output.edge_endpoint' 'references') -eq 1 -and
        # ... and through a //subdirectory call, which fixture 1 never does.
        (Test-Edge 'TfSiteCore:modules/label#output.prefix' 'TfSiteEdge:.#output.label_prefix' 'references') -eq 1 -and
        (Test-Edge 'TfSiteCore:modules/policy#output.steward' 'TfSiteOps:.#output.policy_steward' 'references') -eq 1 -and
        # Six passes-to edges crossing a repository boundary.
        (Test-Edge 'TfSiteEdge:.#var.site_name' 'TfSiteCore:modules/label#var.slug' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteEdge:.#var.region' 'TfSiteCore:modules/label#var.region' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteOps:.#var.site_name' 'TfSiteCore:modules/policy#var.steward' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteOps:.#var.region' 'TfSiteCore:modules/policy#var.region' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteOps:.#var.site_name' 'TfSiteEdge:.#var.site_name' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteOps:.#var.region' 'TfSiteEdge:.#var.region' 'passes-to') -eq 1
    }

    '4 provider version pin'                               = {
        (Get-Attribute 'TfSiteCore:.' 'requiredVersion') -eq '>= 1.6.0' -and
        (Get-Attribute 'TfSiteEdge:.' 'requiredVersion') -eq '~> 1.7.0' -and
        (Get-Attribute 'TfSiteOps:.' 'requiredVersion') -eq '>= 1.4.0, < 1.10.0' -and
        (Get-Attribute 'TfSiteCore:.#provider.tls' 'version') -eq '4.0.6' -and
        (Get-Attribute 'TfSiteEdge:.#provider.http' 'version') -eq '>= 3.4.0, < 4.0.0' -and
        (Get-Attribute 'TfSiteOps:.#provider.external' 'version') -eq '~> 2.3.4' -and
        # The same provider in two repositories is two nodes, pinned differently.
        (Get-Attribute 'TfSiteCore:.#provider.archive' 'version') -eq '~> 2.6' -and
        (Get-Attribute 'TfSiteOps:.#provider.archive' 'version') -eq '2.6.0'
    }

    '5 value chain, renamed on the last hop'               = {
        (Test-Edge 'TfSiteEdge:.#var.probe_interval_seconds' 'TfSiteEdge:.#local.probe_window' 'references') -eq 1 -and
        (Test-Edge 'TfSiteEdge:.#local.probe_window' 'TfSiteEdge:modules/edge#var.probe_window' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteEdge:modules/edge#var.probe_window' 'TfSiteEdge:modules/edge/modules/pop#var.probe_window' 'passes-to') -eq 1 -and
        # The rename: probe_window arrives as window.
        (Test-Edge 'TfSiteEdge:modules/edge/modules/pop#var.probe_window' 'TfSiteEdge:modules/edge/modules/pop/modules/probe#var.window' 'passes-to') -eq 1 -and
        # The diamond: one child variable, two incoming passes-to from two callers.
        (Test-Edge 'TfSiteOps:.#var.site_name' 'TfSiteOps:.#local.ops_name' 'references') -eq 1 -and
        (Test-Edge 'TfSiteOps:.#local.ops_name' 'TfSiteOps:modules/collector#var.name' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteOps:modules/collector#var.name' 'TfSiteOps:modules/collector#local.collector_name' 'references') -eq 1 -and
        (Test-Edge 'TfSiteOps:modules/collector#local.collector_name' 'TfSiteOps:modules/common#var.name' 'passes-to') -eq 1 -and
        (Test-Edge 'TfSiteOps:modules/reporter#local.reporter_name' 'TfSiteOps:modules/common#var.name' 'passes-to') -eq 1
    }

    '6 unused variable, the absence case'                  = {
        # cases.md calls this "the only node in the fixture with neither" an
        # incoming nor an outgoing edge. Read literally that is false OF THE
        # ORACLE: the three repository nodes and all six provider nodes have
        # neither either, because they take part in containment rather than in
        # value flow. Scored against the literal reading, the oracle fails its
        # own case -- which is what the control run is for.
        #
        # The claim the case is actually making is about VALUE FLOW, so the
        # uniqueness is asserted over variable, local and output nodes, where
        # it holds exactly.
        $id = 'TfSiteCore:.#var.archive_retention_weeks'
        $touched = @{}
        foreach ($edge in @($graph.edges)) { $touched[[string]$edge.from] = $true; $touched[[string]$edge.to] = $true }
        $isolated = @(@($graph.nodes) |
                Where-Object { $_.type -in 'variable', 'local', 'output' -and -not $touched.ContainsKey([string]$_.id) })

        $null -ne $byId[$id] -and -not $touched.ContainsKey($id) -and
        @($isolated).Count -eq 1 -and [string]$isolated[0].id -eq $id
    }

    '7 unresolved module sources, two shapes'              = {
        # A relative path that exists nowhere.
        $null -ne $byId[$vault] -and (Get-Attribute $vault 'unresolved') -eq $true -and
        (Test-Edge 'TfSiteOps:.' $vault 'sources') -eq 1 -and
        (Test-EdgeField 'TfSiteOps:.' $vault 'resolved') -eq $false -and
        -not [string]::IsNullOrWhiteSpace([string](Test-EdgeField 'TfSiteOps:.' $vault 'reason')) -and
        # A git:: URL naming a repository that does not exist -- the harder
        # half, where "this parses as a git source" is not "this resolves".
        $null -ne $byId[$vendorProbe] -and (Get-Attribute $vendorProbe 'unresolved') -eq $true -and
        (Test-Edge 'TfSiteEdge:.' $vendorProbe 'sources') -eq 1 -and
        (Test-EdgeField 'TfSiteEdge:.' $vendorProbe 'resolved') -eq $false -and
        -not [string]::IsNullOrWhiteSpace([string](Test-EdgeField 'TfSiteEdge:.' $vendorProbe 'reason')) -and
        # No invented endpoint: vendor_probe passes interval_seconds, and the
        # target module's variables are unknowable.
        @(@($graph.edges) | Where-Object { $_.kind -eq 'passes-to' -and ([string]$_.to).StartsWith($vendorProbe) }).Count -eq 0
    }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($entry in $cases.GetEnumerator()) {
    $passed = $false
    try { $passed = [bool](& $entry.Value) } catch { $passed = $false }
    $results.Add([pscustomobject]@{ Name = $entry.Key; Result = $passed ? 'PASS' : 'FAIL' })
}

$passedCount = @($results | Where-Object Result -EQ 'PASS').Count
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add(('functional-tf (fixture 2): {0} / {1}' -f $passedCount, $results.Count))
$lines.Add(('graph: {0}' -f $Path))
$lines.Add(('nodes: {0}   edges: {1}' -f @($graph.nodes).Count, @($graph.edges).Count))
$lines.Add('')
foreach ($result in $results) { $lines.Add(('  {0,-6} {1}' -f $result.Result, $result.Name)) }
$report = $lines -join [Environment]::NewLine

if ($ReportPath) { Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8 }
$report

[pscustomobject]@{
    Passed = $passedCount
    Total  = $results.Count
    Cases  = $results.ToArray()
    Report = $report
} | Out-Null
