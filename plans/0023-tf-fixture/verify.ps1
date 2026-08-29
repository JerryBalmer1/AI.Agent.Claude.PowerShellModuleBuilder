#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the pass 0023 plan without reading it.

.DESCRIPTION
    Re-derives every named spot-check. It never reads plan.md and never trusts
    mutations.txt or readback.txt: it regenerates two of the seven mutations
    itself and re-runs the comparison, rather than reading what a previous run
    concluded.

    Checks 2 and 3 need $env:AZDO_PAT. Without one they SKIP LOUDLY and the
    summary says the run graded less than it claims to. A check that reports
    success where nothing could contradict it is worse than one that says it did
    not run.

.PARAMETER SkipAzdo
    Do not contact Azure DevOps even if a PAT is present.
#>
[CmdletBinding()]
param([switch] $SkipAzdo)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Skipped = [System.Collections.Generic.List[string]]::new()
$script:Checks = 0

function Confirm-Check {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [bool] $Ok,
        [string] $Detail = ''
    )
    $script:Checks++
    if ($Ok) {
        Write-Host ("PASS  {0}" -f $Name)
        if ($Detail) { Write-Host ("        {0}" -f $Detail) }
    }
    else {
        Write-Host ("FAIL  {0}" -f $Name)
        if ($Detail) { Write-Host ("        {0}" -f $Detail) }
        $script:Failures.Add($Name)
    }
}

function Skip-Check {
    param([Parameter(Mandatory)] [string] $Name, [Parameter(Mandatory)] [string] $Why)
    Write-Host ("SKIP  {0}" -f $Name)
    Write-Host ("        {0}" -f $Why)
    $script:Skipped.Add($Name)
}

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$tf = Join-Path $RepoRoot 'evals/tf'
$oracle = Join-Path $tf 'fixture/expected-graph.json'
$compare = Join-Path $tf 'Compare-TfGraph.ps1'
$mutate = Join-Path $tf 'Mutate-TfGraph.ps1'

# ---- 1. Comparator green oracle-vs-self; two mutations regenerated here ----

$control = & $compare -Expected $oracle -Actual $oracle
Confirm-Check -Name '1a control: the oracle compared with itself reports zero differences' `
    -Ok ($control.IsMatch -and $control.DifferenceCount -eq 0) `
    -Detail "$($control.DifferenceCount) difference(s) over $($control.ExpectedNodeCount) nodes and $($control.ExpectedEdgeCount) edges"

Confirm-Check -Name '1b the oracle is the size the fixture claims' `
    -Ok ($control.ExpectedNodeCount -eq 78 -and $control.ExpectedEdgeCount -eq 57) `
    -Detail "$($control.ExpectedNodeCount) nodes, $($control.ExpectedEdgeCount) edges"

# Mutations 2 and 5 of the seven, by the prompt's numbering: extra-node and
# missing-edge. Regenerated here rather than read from mutations.txt.
foreach ($case in @(
        @{ Mutation = 'extra-node'; Category = 'ExtraNode' }
        @{ Mutation = 'missing-edge'; Category = 'MissingEdge' }
    )) {
    $mutated = & $mutate -Path $oracle -Mutation $case.Mutation

    # The probe's own control: the mutation must have changed the document.
    $before = (Get-Content -LiteralPath $oracle -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 30)
    $after = ($mutated | ConvertTo-Json -Depth 30)
    Confirm-Check -Name "1c probe control: the $($case.Mutation) mutation changed the document" `
        -Ok ($before -ne $after) -Detail "$($before.Length) -> $($after.Length) chars"

    $result = & $compare -Expected $oracle -ActualObject $mutated
    $categories = @($result.Differences | ForEach-Object { $_.Category })
    Confirm-Check -Name "1d $($case.Mutation) is detected as $($case.Category)" `
        -Ok (-not $result.IsMatch -and $case.Category -in $categories) `
        -Detail "$($result.DifferenceCount) difference(s): $(($categories | Sort-Object -Unique) -join ', ')"
}

# ---- 4. The oracle validates against the producer contract ------------------

$toHtml = Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRenderToHtml/src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1'
if (-not (Test-Path -LiteralPath $toHtml)) {
    Skip-Check -Name '4 the oracle validates against the producer contract' `
        -Why "PSGraphRenderToHtml is not checked out beside this repository; the oracle's shape was NOT graded."
}
else {
    $validateScript = @'
param($ToHtml, $Oracle)
try {
    Import-Module $ToHtml -Force -ErrorAction Stop
} catch {
    "IMPORTFAILED $($_.Exception.Message)"
    exit 0
}
$r = Test-ProducerGraph -Path $Oracle
"VALIDATED $($r.IsValid) $($r.NodeCount) $($r.EdgeCount) $(@($r.Violations).Count)"
'@
    $validateFile = Join-Path ([System.IO.Path]::GetTempPath()) ('verify-0023-validate-' + [Guid]::NewGuid().ToString('N').Substring(0, 8) + '.ps1')
    Set-Content -LiteralPath $validateFile -Value $validateScript -Encoding utf8NoBOM
    try {
        $out = (& pwsh -NoProfile -File $validateFile $toHtml $oracle 2>&1) -join "`n"
    }
    finally { Remove-Item -LiteralPath $validateFile -Force -ErrorAction SilentlyContinue }

    if ($out -match 'IMPORTFAILED') {
        Skip-Check -Name '4 the oracle validates against the producer contract' `
            -Why "PSGraphRenderToHtml could not be imported (its own dependency PSGraphRender may not be installed); the oracle's shape was NOT graded."
    }
    else {
        Confirm-Check -Name '4 the oracle validates against the producer contract, with no violations' `
            -Ok ($out -match 'VALIDATED True 78 57 0') `
            -Detail (($out -split "`n" | Where-Object { $_ -like 'VALIDATED*' }) -join '')
    }
}

# ---- 2 and 3. Azure DevOps, PAT-gated -------------------------------------

if ($SkipAzdo) {
    Skip-Check -Name '2 the AzDO fixture matches the harness copy' -Why '-SkipAzdo was given.'
    Skip-Check -Name '3 the project holds the expected repositories and zero queued builds' -Why '-SkipAzdo was given.'
}
elseif (-not $env:AZDO_PAT) {
    Skip-Check -Name '2 the AzDO fixture matches the harness copy' `
        -Why 'AZDO_PAT is not set. The fixture on the remote was NOT compared against the harness copy.'
    Skip-Check -Name '3 the project holds the expected repositories and zero queued builds' `
        -Why 'AZDO_PAT is not set. Nothing confirmed that no build has ever been queued.'
}
else {
    . (Join-Path $tf 'TfAzdoClient.ps1')

    # Re-clone and re-hash, rather than reading readback.txt.
    $readBack = Join-Path $tf 'Test-TfFixtureReadBack.ps1'
    $reportPath = Join-Path ([System.IO.Path]::GetTempPath()) ('verify-0023-readback-' + [Guid]::NewGuid().ToString('N').Substring(0, 8) + '.txt')
    & pwsh -NoProfile -File $readBack -ReportPath $reportPath *> $null
    $readBackExit = $LASTEXITCODE
    $report = if (Test-Path -LiteralPath $reportPath) { Get-Content -LiteralPath $reportPath -Raw } else { '' }
    Remove-Item -LiteralPath $reportPath -Force -ErrorAction SilentlyContinue

    $compared = if ($report -match '(\d+) file\(s\) compared') { [int]$Matches[1] } else { 0 }
    Confirm-Check -Name '2 the AzDO fixture is byte-identical to the harness copy' `
        -Ok ($readBackExit -eq 0 -and $report -match 'BYTE-IDENTICAL' -and $compared -ge 40) `
        -Detail "exit $readBackExit, $compared file(s) re-cloned and re-hashed"

    $base = Get-TfAzdoBaseUri
    $repos = (Invoke-TfAzdoJson -Uri "$base/git/repositories?api-version=7.1").value
    $names = @($repos | ForEach-Object { $_.name })
    $expected = @(Get-TfFixtureRepoName)
    $present = @($expected | Where-Object { $_ -in $names })

    $builds = (Invoke-TfAzdoJson -Uri "$base/build/builds?api-version=7.1").value
    $definitions = (Invoke-TfAzdoJson -Uri "$base/build/definitions?api-version=7.1").value

    Confirm-Check -Name '3a the project holds all three fixture repositories' `
        -Ok ($present.Count -eq 3) -Detail "$($present.Count) of 3 present; project has $(@($names).Count) repositories"

    Confirm-Check -Name '3b the pipeline definitions exist' `
        -Ok (@($definitions).Count -ge 4) -Detail "$(@($definitions).Count) definition(s)"

    Confirm-Check -Name '3c no build has ever been queued' `
        -Ok (@($builds).Count -eq 0) -Detail "$(@($builds).Count) build(s) in the project's entire history"
}

# ---- 5. The fixture is what the decision says it is ------------------------

Confirm-Check -Name '5a decision 0011 exists and freezes the fixture' `
    -Ok ((Test-Path -LiteralPath (Join-Path $RepoRoot 'decisions/0011-terraform-fixture-and-run-ledger.md')) -and
        ((Get-Content -LiteralPath (Join-Path $RepoRoot 'decisions/0011-terraform-fixture-and-run-ledger.md') -Raw) -match 'frozen')) `
    -Detail 'decisions/0011-terraform-fixture-and-run-ledger.md'

$repoCount = @(Get-ChildItem -LiteralPath (Join-Path $tf 'fixture/repos') -Directory).Count
Confirm-Check -Name '5b the harness holds all three fixture repositories' `
    -Ok ($repoCount -eq 3) -Detail "$repoCount directories under evals/tf/fixture/repos"

Write-Host ''
Write-Host ("{0} check(s), {1} failed, {2} skipped." -f $script:Checks, $script:Failures.Count, $script:Skipped.Count)
if ($script:Skipped.Count -gt 0) {
    Write-Host 'This run graded LESS than a full run. Skipped:'
    foreach ($s in $script:Skipped) { Write-Host ("  {0}" -f $s) }
}
if ($script:Failures.Count -gt 0) {
    Write-Host 'Checks that disagreed:'
    foreach ($f in $script:Failures) { Write-Host ("  {0}" -f $f) }
    exit 1
}
exit 0
