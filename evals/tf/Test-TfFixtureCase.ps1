#Requires -Version 7.2
<#
.SYNOPSIS
    Score a produced graph against the seven NAMED cases in fixture/cases.md,
    each by its own assertions.

.DESCRIPTION
    A raw difference count answers the wrong question. Run tf-001 closed on 31
    differences of which 28 were one convention repeated, and a reader looking
    at "31" cannot tell that from 31 defects. The cases are the unit that means
    something, and this file is where "functional-tf: N / 7" comes from.

    Every case is checked by assertions over the graph, NOT by asking whether
    the comparator found zero differences. Those are different claims: a graph
    can match the oracle exactly and the cases still be worth stating, and a
    case can pass while other differences remain. Deriving the case score from
    the difference count would collapse two measurements into one and lose the
    ability to say which case failed.

    Case 3 is checked in its post-decision-0012 form: a module block sourcing
    TfFixtureNetwork's ROOT by git:: URL with no //subdirectory, and two locals
    reading its outputs. Before that amendment the case asserted two edges that
    existed only in a variable's prose description and no producer could pass.

.PARAMETER Path
    The produced graph to score.

.PARAMETER GraphObject
    The graph already parsed, for a caller that has just produced one.

.OUTPUTS
    PSCustomObject: Passed, Total, Cases (Name, Result), Report.

.EXAMPLE
    ./Test-TfFixtureCase.ps1 -Path ./graph.json
#>
[CmdletBinding(DefaultParameterSetName = 'Path')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Path')]
    [ValidateNotNullOrEmpty()]
    [string] $Path,

    [Parameter(Mandatory, ParameterSetName = 'Object')]
    [ValidateNotNull()]
    [object] $GraphObject,

    [Parameter()]
    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($PSCmdlet.ParameterSetName -eq 'Path') {
    if (-not (Test-Path -LiteralPath $Path)) { throw "No such graph: '$Path'." }
    $graph = (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json).graph
}
else {
    $graph = ($GraphObject | ConvertTo-Json -Depth 30 | ConvertFrom-Json).graph
}

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
    if ($property) { return $property.Value }
    $null
}

$cases = [ordered]@{
    '1 nested-module chain, three levels'            = {
        (Test-Edge 'TfFixtureNetwork:.' 'TfFixtureNetwork:modules/segment' 'sources') -eq 1 -and
        (Test-Edge 'TfFixtureNetwork:modules/segment' 'TfFixtureNetwork:modules/segment/modules/subnet' 'sources') -eq 1 -and
        $byId['TfFixtureNetwork:modules/segment'].parentId -eq 'TfFixtureNetwork:.' -and
        $byId['TfFixtureNetwork:modules/segment/modules/subnet'].parentId -eq 'TfFixtureNetwork:modules/segment' -and
        # containment is parentId and never an edge
        @(@($graph.edges) | Where-Object { $_.kind -eq 'contains' }).Count -eq 0
    }
    '2 cross-repository source (git:: with //subdir)' = {
        (Test-Edge 'TfFixtureApp:.' 'TfFixtureShared:modules/naming' 'sources') -eq 1 -and
        (Test-Edge 'TfFixtureApp:.' 'TfFixtureShared:modules/tags' 'sources') -eq 1
    }
    '3 cross-repository output reference'             = {
        # Post-decision-0012. The git:: source with NO //subdirectory is what
        # names the other repository's root module.
        (Test-Edge 'TfFixtureApp:.' 'TfFixtureNetwork:.' 'sources') -eq 1 -and
        (Test-Edge 'TfFixtureNetwork:.#output.segment_id' 'TfFixtureApp:.#local.network_segment_id' 'references') -eq 1 -and
        (Test-Edge 'TfFixtureNetwork:.#output.subnet_ids' 'TfFixtureApp:.#local.network_subnet_ids' 'references') -eq 1 -and
        (Test-Edge 'TfFixtureApp:.#var.application_name' 'TfFixtureNetwork:.#var.network_name' 'passes-to') -eq 1 -and
        (Test-Edge 'TfFixtureApp:.#local.network_segment_id' 'TfFixtureApp:.#local.merged_tags' 'references') -eq 1 -and
        (Test-Edge 'TfFixtureApp:.#local.network_subnet_ids' 'TfFixtureApp:modules/service#var.subnet_ids' 'passes-to') -eq 1
    }
    '4 provider version pin'                         = {
        @(@($graph.nodes) | Where-Object { $_.type -eq 'provider' }).Count -eq 6 -and
        (Get-Attribute 'TfFixtureApp:.' 'requiredVersion') -eq '~> 1.0.11' -and
        (Get-Attribute 'TfFixtureNetwork:.' 'requiredVersion') -eq '>= 1.5.0' -and
        (Get-Attribute 'TfFixtureShared:.' 'requiredVersion') -eq '>= 1.3.0, < 2.0.0' -and
        # three pin syntaxes: exact, pessimistic, ranged
        (Get-Attribute 'TfFixtureShared:.#provider.random' 'version') -eq '3.6.0' -and
        (Get-Attribute 'TfFixtureShared:.#provider.time' 'version') -eq '~> 0.11.1' -and
        (Get-Attribute 'TfFixtureApp:.#provider.null' 'version') -eq '>= 3.0.0, < 4.0.0'
    }
    '5 variable -> local -> module -> nested module'  = {
        (Test-Edge 'TfFixtureApp:.#var.tags' 'TfFixtureApp:.#local.merged_tags' 'references') -eq 1 -and
        (Test-Edge 'TfFixtureApp:.#local.merged_tags' 'TfFixtureApp:modules/service#var.tags' 'passes-to') -eq 1 -and
        (Test-Edge 'TfFixtureApp:modules/service#var.tags' 'TfFixtureApp:modules/service#local.service_tags' 'references') -eq 1 -and
        (Test-Edge 'TfFixtureApp:modules/service#local.service_tags' 'TfFixtureApp:modules/service/modules/worker#var.tags' 'passes-to') -eq 1
    }
    '6 unused variable, the absence case'            = {
        # Checkable only by absence, which is why it is a named case rather
        # than left to chance.
        $null -ne $byId['TfFixtureShared:.#var.unused_retention_days'] -and
        @(@($graph.edges) | Where-Object { $_.from -eq 'TfFixtureShared:.#var.unused_retention_days' }).Count -eq 0
    }
    '7 unresolved module source'                     = {
        $target = 'TfFixtureApp:../shared-legacy/modules/archive'
        $edges = @(@($graph.edges) | Where-Object { $_.to -eq $target })
        $null -ne $byId[$target] -and
        $byId[$target].type -eq 'module' -and
        $byId[$target].scope -eq 'TfFixtureApp' -and
        $edges.Count -eq 1 -and
        $edges[0].kind -eq 'sources' -and
        $edges[0].resolved -eq $false -and
        [bool]($edges[0].PSObject.Properties['reason'] -and $edges[0].reason -match 'shared-legacy')
    }
}

$results = [System.Collections.Generic.List[object]]::new()
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('functional-tf, by the named cases in evals/tf/fixture/cases.md')
$lines.Add('')

foreach ($name in $cases.Keys) {
    $ok = [bool](& $cases[$name])
    $results.Add([pscustomobject]@{ Name = $name; Result = $(if ($ok) { 'PASS' } else { 'FAIL' }) })
    $lines.Add(('  {0,-4} {1}' -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $name))
}

$passed = @($results | Where-Object { $_.Result -eq 'PASS' }).Count
$lines.Add('')
$lines.Add("functional-tf: $passed / $($cases.Count)")
$report = $lines -join [Environment]::NewLine

if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
}

[pscustomobject]@{
    PSTypeName = 'TfGraph.CaseScore'
    Passed     = $passed
    Total      = $cases.Count
    Cases      = $results
    Report     = $report
}
