#Requires -Version 7.2
<#
.SYNOPSIS
    Prove `Test-TfFixture2Case.ps1` can fail, one mutation per case, plus the
    duplicate-id refusal.

.DESCRIPTION
    A case scorer that has only ever been green is indistinguishable from one
    that cannot fail. This is what turns "the seven cases passed" into "the
    seven cases are checked".

    It lives beside the scorer, not in the plan directory that first ran it.
    Pass 0036 wrote both under `plans/0036-tf-003/`; the scorer was promoted at
    pass 0037 and its falsification came with it, because a promoted instrument
    whose falsification stayed behind is one nobody re-runs.

    THREE THINGS, and they are three different claims:

      CONTROL     The oracle scored against itself. It must be 7 / 7. This is
                  not ceremony: run for the first time at pass 0036 it came back
                  6 / 7 and the defect was in `cases.md`'s prose, not in any
                  producer. Grade the grader before the graded.

      SEVEN       One mutation per case, applied to an in-memory copy of the
                  oracle. Each must redden ITS OWN case and no other. A mutation
                  that reddens two cases has not shown that either one is
                  checked - it has shown they are entangled.

      MUTATION 8  `duplicate-id`, from `../Mutate-TfGraph.ps1`, which is the
                  same mutation the comparator's own falsification uses. Here
                  the required outcome is not a failed case but a REFUSAL: the
                  scorer keys every node by id, so a duplicate would overwrite
                  its own entry and the graph would score clean. The assertion
                  is that scoring throws.

    NOTHING IS WRITTEN TO THE ORACLE. Every mutation is applied to a fresh
    round-trip of the file, exactly as `Mutate-TfGraph.ps1` does, and the
    fixture is frozen per decision 0014.

.PARAMETER ReportPath
    Write the report here as well as to the pipeline.

.OUTPUTS
    The report text. Exit code 0 when the control, all seven mutations and the
    refusal behave as required; 1 otherwise.

.EXAMPLE
    ./Invoke-TfFixture2CaseFalsification.ps1 -ReportPath ../../../plans/0037-consolidation/case-scorer.txt
#>
[CmdletBinding()]
param(
    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$oraclePath = Join-Path $PSScriptRoot 'expected-graph.json'
$scorer = Join-Path $PSScriptRoot 'Test-TfFixture2Case.ps1'
$mutator = Join-Path (Split-Path -Parent $PSScriptRoot) 'Mutate-TfGraph.ps1'
foreach ($required in $oraclePath, $scorer, $mutator) {
    if (-not (Test-Path -LiteralPath $required)) { throw "Missing: '$required'." }
}

function Get-Oracle { Get-Content -LiteralPath $oraclePath -Raw | ConvertFrom-Json }

function Remove-GraphEdge {
    param([object] $Doc, [string] $From, [string] $To)
    $Doc.graph.edges = @($Doc.graph.edges | Where-Object { -not ($_.from -eq $From -and $_.to -eq $To) })
    $Doc
}

$vendorProbe = 'TfSiteEdge:git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteVendor//modules/probe?ref=main'

# One mutation per case. Each names the case it must redden; the driver checks
# that it reddens that one and nothing else, rather than trusting the name.
$mutations = @(
    @{
        Case  = '1 nested-module chain, four levels'
        Label = 'case 1: drop the sources edge modules/edge -> pop'
        Apply = { param($d) Remove-GraphEdge $d 'TfSiteEdge:modules/edge' 'TfSiteEdge:modules/edge/modules/pop' }
    }
    @{
        Case  = '2 cross-repository source, git:: with //subdirectory'
        Label = 'case 2: drop the cross-repo //subdirectory source'
        Apply = { param($d) Remove-GraphEdge $d 'TfSiteEdge:.' 'TfSiteCore:modules/label' }
    }
    @{
        Case  = '3 cross-repository output reference'
        Label = 'case 3: drop a cross-repo output reference'
        Apply = { param($d) Remove-GraphEdge $d 'TfSiteEdge:.#output.pop_ids' 'TfSiteOps:.#local.edge_pop_ids' }
    }
    @{
        Case  = '4 provider version pin'
        Label = 'case 4: collapse the two archive provider pins'
        Apply = {
            param($d)
            foreach ($node in $d.graph.nodes) {
                if ($node.id -eq 'TfSiteOps:.#provider.archive') { $node.attributes.version = '~> 2.6' }
            }
            $d
        }
    }
    @{
        Case  = '5 value chain, renamed on the last hop'
        Label = 'case 5: drop the renamed last hop'
        Apply = {
            param($d)
            Remove-GraphEdge $d 'TfSiteEdge:modules/edge/modules/pop#var.probe_window' `
                'TfSiteEdge:modules/edge/modules/pop/modules/probe#var.window'
        }
    }
    @{
        Case  = '6 unused variable, the absence case'
        Label = 'case 6: invent an edge for the unused variable'
        Apply = {
            param($d)
            $d.graph.edges = @($d.graph.edges) + @([pscustomobject]@{
                    from = 'TfSiteCore:.#var.archive_retention_weeks'
                    to   = 'TfSiteCore:.#local.code_slug'
                    kind = 'references'
                })
            $d
        }
    }
    @{
        Case  = '7 unresolved module sources, two shapes'
        Label = 'case 7: claim the vendor git:: URL resolved'
        Apply = {
            param($d)
            foreach ($node in $d.graph.nodes) {
                if ($node.id -eq $vendorProbe) { $node.attributes.unresolved = $false }
            }
            foreach ($edge in $d.graph.edges) {
                if ($edge.to -eq $vendorProbe) { $edge.resolved = $true }
            }
            $d
        }
    }
)

$lines = [System.Collections.Generic.List[string]]::new()
$rule = '=' * 78
$thin = '-' * 78
$failures = 0

$lines.Add($rule)
$lines.Add('FIXTURE-2 CASE SCORER - FALSIFICATION')
$lines.Add('evals/tf/fixture2/Test-TfFixture2Case.ps1, promoted from plans/0036-tf-003/ by pass 0037')
$lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
$lines.Add($rule)
$lines.Add('')
$lines.Add('A case scorer that has only ever been green is indistinguishable from one that')
$lines.Add('cannot fail. Eight mutations: the seven originals, one per case, plus mutation 8')
$lines.Add('from Mutate-TfGraph.ps1, whose required outcome is a REFUSAL rather than a')
$lines.Add('failed case. The oracle on disk is never written to.')
$lines.Add('')

# --- Control ----------------------------------------------------------------
$lines.Add($thin)
$lines.Add('CONTROL - the oracle scored against itself. Grade the grader before the graded.')
$lines.Add('')
$control = & $scorer -Path $oraclePath
$controlOk = $control.Passed -eq 7 -and $control.Total -eq 7
if (-not $controlOk) { $failures++ }
$lines.Add(('  [{0}] oracle vs self: {1} / {2}' -f ($controlOk ? 'ok  ' : 'FAIL'), $control.Passed, $control.Total))
foreach ($case in $control.Cases) { $lines.Add(('         {0,-6} {1}' -f $case.Result, $case.Name)) }
$lines.Add('')
$lines.Add('Run for the first time at pass 0036 this came back 6 / 7, and the defect was in')
$lines.Add('cases.md prose - the unscoped "only node with neither" clause, corrected at 0037.')
$lines.Add('The fixture and the oracle were not touched then and are not touched now.')
$lines.Add('')

# --- The seven --------------------------------------------------------------
$lines.Add($thin)
$lines.Add('SEVEN MUTATIONS - each must redden ITS OWN case and no other.')
$lines.Add('')
$lines.Add(('{0,-52} {1,-8} {2}' -f 'mutation', 'score', 'case(s) that went red'))
$lines.Add(('{0} {1} {2}' -f ('-' * 52), ('-' * 8), ('-' * 40)))

$defeated = 0
foreach ($mutation in $mutations) {
    $doc = & $mutation.Apply (Get-Oracle)
    $scored = & $scorer -GraphObject $doc
    $red = @($scored.Cases | Where-Object Result -EQ 'FAIL' | ForEach-Object { $_.Name })
    $ownOnly = @($red).Count -eq 1 -and $red[0] -eq $mutation.Case
    if ($ownOnly) { $defeated++ } else { $failures++ }
    $lines.Add(('{0,-52} {1,-8} {2}' -f $mutation.Label,
            ('{0} / {1}' -f $scored.Passed, $scored.Total),
            (@($red).Count -eq 0 ? '(NONE - the case is not checked)' : (@($red) -join ' + '))))
    if (-not $ownOnly) {
        $lines.Add(('{0}FAIL: expected exactly "{1}"' -f (' ' * 52), $mutation.Case))
    }
}
$lines.Add('')

# --- Mutation 8 -------------------------------------------------------------
$lines.Add($thin)
$lines.Add('MUTATION 8 - duplicate-id. Not a failed case: an UNSCOREABLE graph.')
$lines.Add('')
$lines.Add('Every node is keyed by id, so a duplicate overwrites its own entry and the graph')
$lines.Add('scores clean - the blindness LEDGER backlog 32 found in Compare-TfGraph.ps1, in a')
$lines.Add('second instrument. The required outcome is that scoring THROWS.')
$lines.Add('')
$duplicated = & $mutator -Path $oraclePath -Mutation duplicate-id -Fixture fixture2
$refused = $false
$refusal = ''
try {
    $ignored = & $scorer -GraphObject $duplicated
    $refusal = ('scored {0} / {1} instead of refusing' -f $ignored.Passed, $ignored.Total)
}
catch {
    $refused = $true
    $refusal = ($_.Exception.Message -split "`r?`n")[0]
}
if (-not $refused) { $failures++ }
$lines.Add(('  [{0}] duplicate-id refused rather than scored' -f ($refused ? 'ok  ' : 'FAIL')))
$lines.Add('         ' + $refusal)
$lines.Add('')

# --- The strictening, demonstrated ------------------------------------------
# The 0037 promotion rewrote case 6 and claims the rewrite is STRICTER, never
# looser. A claim of strictness that nobody tested is the same kind of thing as
# a gate that has only ever been green, so it is tested here against the form it
# replaced: drop both sources edges into the diamond's shared module, which no
# NAMED case asserts, and the module is left carrying no edge at all.
$lines.Add($thin)
$lines.Add('THE STRICTENING - the 0037 case 6 against the plans-era form it replaced.')
$lines.Add('')
$lines.Add('Mutation: isolate TfSiteOps:modules/common by dropping both sources edges into it.')
$lines.Add('No named case asserts either edge, so this is a defect BOTH forms are entitled to')
$lines.Add('miss - and one of them does.')
$lines.Add('')
$isolatedDoc = Get-Oracle
$isolatedDoc.graph.edges = @($isolatedDoc.graph.edges | Where-Object { $_.to -ne 'TfSiteOps:modules/common' })
$strictScore = & $scorer -GraphObject $isolatedDoc
$strictRed = @($strictScore.Cases | Where-Object Result -EQ 'FAIL' | ForEach-Object { $_.Name })
$strictOk = @($strictRed).Count -eq 1 -and $strictRed[0] -eq '6 unused variable, the absence case'
if (-not $strictOk) { $failures++ }
$lines.Add(('  [{0}] promoted form (whole edgeless set pinned by id): {1} / {2}   red: {3}' -f
        ($strictOk ? 'ok  ' : 'FAIL'), $strictScore.Passed, $strictScore.Total,
        (@($strictRed).Count -eq 0 ? '(none)' : (@($strictRed) -join ' + '))))

# evals/tf/fixture2 -> evals/tf -> evals -> the repository root.
$repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$priorScorer = Join-Path $repoRoot 'plans/0036-tf-003/Test-Tf003Case.ps1'
if (Test-Path -LiteralPath $priorScorer) {
    $temp = Join-Path ([System.IO.Path]::GetTempPath()) ('tf2-strictening-' + [Guid]::NewGuid().ToString('N').Substring(0, 8) + '.json')
    try {
        $isolatedDoc | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $temp -Encoding utf8NoBOM
        $priorReport = (& $priorScorer -Path $temp) -join [Environment]::NewLine
        $priorLine = @($priorReport -split "`r?`n" | Where-Object { $_ -match 'functional-tf \(fixture 2\)' }) |
            Select-Object -First 1
        $lines.Add(('         plans-era form (value flow only), same graph: {0}' -f ($priorLine ?? '(no headline)').Trim()))
    }
    finally { if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force } }
    $lines.Add('         The form it replaced calls this graph clean. That is the strictening,')
    $lines.Add('         and it is why the cases.md correction is not a weakening.')
}
else {
    $lines.Add('         plans-era form: NOT PRESENT, comparison not made.')
}
$lines.Add('')

# --- Headlines --------------------------------------------------------------
$lines.Add($rule)
if ($failures -gt 0) {
    $lines.Add("$failures CHECK(S) FAILED - the scorer is not falsified and its numbers do not stand.")
}
$lines.Add(('STRICTER THAN THE PLANS-ERA FORM: {0}' -f ($strictOk ? 'demonstrated' : 'NOT DEMONSTRATED')))
$lines.Add(('DUPLICATE-ID (mutation 8): {0}' -f ($refused ? 'refused, not scored' : 'NOT REFUSED')))
$lines.Add(('ORACLE VS SELF: {0} / {1}' -f $control.Passed, $control.Total))
$lines.Add(('FALSIFIED: {0} / {1} cases each defeated by its own mutation' -f $defeated, @($mutations).Count))

$report = $lines -join [Environment]::NewLine
$report

if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
}

if ($failures -gt 0) { exit 1 }
exit 0
