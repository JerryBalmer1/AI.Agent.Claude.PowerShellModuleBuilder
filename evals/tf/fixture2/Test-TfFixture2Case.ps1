#Requires -Version 7.2
<#
.SYNOPSIS
    Score a produced graph against the seven NAMED cases in
    evals/tf/fixture2/cases.md, each by its own assertions.

.DESCRIPTION
    The fixture-2 counterpart of `evals/tf/Test-TfFixtureCase.ps1`, which scores
    fixture 1 and is hard-coded to TfFixtureShared / TfFixtureNetwork /
    TfFixtureApp throughout. Fixture 2 arrived at pass 0035 with cases.md, an
    oracle and an eight-way falsification driver, and NO case scorer, so
    "functional-tf: N / 7" had nothing to come from. Pass 0036 wrote one under
    `plans/0036-tf-003/` because that pass could not touch `evals/`; pass 0037
    promoted it here. A scorer living in a plan directory is one the next run
    does not find.

    FIXTURE 1'S SCORER WAS LEFT ALONE rather than given a `-Fixture` parameter.
    It is the instrument tf-001 and tf-002 were scored with, and the two
    fixtures' cases differ in substance and not only in ids - fixture 2's case 1
    is four levels deep, its case 3 lands in outputs as well as locals, its
    case 7 has two shapes. One script with two rule sets would have to say which
    fixture each clause belonged to on every line, which is what two files
    already say.

    Every case is checked by assertions over the graph, NOT by asking whether
    the comparator found zero differences. Those are different claims: a graph
    can match the oracle exactly and the cases still be worth stating
    separately, and a case can pass while other differences remain.

    The ids are the ORACLE's ids, literally, as fixture 1's scorer uses fixture
    1's. A producer whose node carries the right meaning under a different id
    fails the case, because an id is what makes two producers' graphs mergeable
    and a case scorer that normalised ids would be grading something else.

    IT REFUSES A DUPLICATE NODE ID RATHER THAN SCORING IT. Every node is keyed
    into a dictionary by id, so a duplicate overwrites its own entry and the
    scorer would grade a defective graph clean - the same blindness LEDGER
    backlog 32 found in `Compare-TfGraph.ps1`, in a second instrument. A
    duplicate is not a failed case: it means the graph cannot be scored, so this
    throws instead of returning a number.
    `Invoke-TfFixture2CaseFalsification.ps1` exercises the refusal as mutation 8.

.PARAMETER Path
    The produced graph to score.

.PARAMETER GraphObject
    The graph already parsed, for a caller that has just produced or mutated
    one. The same parameter set fixture 1's scorer offers.

.PARAMETER ReportPath
    Write the report here as well as returning it on the object.

.OUTPUTS
    PSCustomObject: Passed, Total, Cases (Name, Result), Report.

.EXAMPLE
    ./Test-TfFixture2Case.ps1 -Path ./graph.json

.EXAMPLE
    ./Test-TfFixture2Case.ps1 -Path ./expected-graph.json -ReportPath ./control.txt
    # The oracle against itself. It must come back 7 / 7, and pass 0036 records
    # what happened the first time it did not.
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
    $source = $Path
}
else {
    $graph = ($GraphObject | ConvertTo-Json -Depth 30 | ConvertFrom-Json).graph
    $source = '(object)'
}

# --- Stage 0: refuse rather than score. -------------------------------------
# Before the first assignment into a dictionary, for the reason Compare-TfGraph's
# own Stage 0 exists: after it, a duplicate is invisible.
$seen = @{}
$duplicates = [System.Collections.Generic.List[string]]::new()
foreach ($node in @($graph.nodes)) {
    $id = [string]$node.id
    if ($seen.ContainsKey($id)) { if (-not $duplicates.Contains($id)) { $duplicates.Add($id) } }
    $seen[$id] = $true
}
if ($duplicates.Count -gt 0) {
    throw ("Cannot score '{0}': {1} duplicated node id(s) - {2}. A graph whose ids are not unique is not scoreable; every case here is keyed by id." -f
        $source, $duplicates.Count, (($duplicates | Sort-Object) -join ', '))
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
        # THE DISCRIMINATOR IS SCOPED TO VALUE FLOW, and cases.md now says so.
        #
        # It used to read "the only node in the fixture with neither" an incoming
        # nor an outgoing edge. That is false OF THE ORACLE: ten nodes satisfy it
        # literally - this variable, three `repository` nodes and six `provider`
        # nodes - because the latter nine take part in containment rather than in
        # value flow. Scored against the literal reading the oracle failed its own
        # case, which is what pass 0036's control caught and LEDGER backlog 40
        # recorded. The PROSE was wrong; the fixture and the oracle are untouched.
        #
        # The WHOLE isolated set is asserted, not only the uniqueness among
        # variable/local/output. That is strictly stronger than the pass-0036
        # form: it pins which nine others are allowed to be edgeless, so a
        # producer that drops every edge from a module fails here too.
        $id = 'TfSiteCore:.#var.archive_retention_weeks'
        $expectedIsolated = @(
            'TfSiteCore:.#var.archive_retention_weeks'
            'repo:TfSiteCore', 'repo:TfSiteEdge', 'repo:TfSiteOps'
            'TfSiteCore:.#provider.tls', 'TfSiteCore:.#provider.archive'
            'TfSiteEdge:.#provider.tls', 'TfSiteEdge:.#provider.http'
            'TfSiteOps:.#provider.archive', 'TfSiteOps:.#provider.external'
        ) | Sort-Object

        $touched = @{}
        foreach ($edge in @($graph.edges)) { $touched[[string]$edge.from] = $true; $touched[[string]$edge.to] = $true }
        $isolated = @(@($graph.nodes) |
                Where-Object { -not $touched.ContainsKey([string]$_.id) } |
                ForEach-Object { [string]$_.id } | Sort-Object)

        # The unused variable is present, has neither edge direction, and is the
        # only variable/local/output that does ...
        $null -ne $byId[$id] -and -not $touched.ContainsKey($id) -and
        @(@($graph.nodes) | Where-Object {
                $_.type -in 'variable', 'local', 'output' -and -not $touched.ContainsKey([string]$_.id)
            }).Count -eq 1 -and
        # ... and nothing else in the graph is edgeless except the nine the
        # oracle accounts for by name.
        ((@($isolated) -join '|') -eq (@($expectedIsolated) -join '|'))
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
$lines.Add('functional-tf, by the named cases in evals/tf/fixture2/cases.md')
$lines.Add('')
$lines.Add(('graph: {0}' -f $source))
$lines.Add(('nodes: {0}   edges: {1}' -f @($graph.nodes).Count, @($graph.edges).Count))
$lines.Add('')
foreach ($result in $results) { $lines.Add(('  {0,-6} {1}' -f $result.Result, $result.Name)) }
$lines.Add('')
$lines.Add(('functional-tf (fixture 2): {0} / {1}' -f $passedCount, $results.Count))
$report = $lines -join [Environment]::NewLine

if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
}

[pscustomobject]@{
    PSTypeName = 'TfGraph.CaseScore'
    Passed     = $passedCount
    Total      = $results.Count
    Cases      = $results
    Report     = $report
}

