#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the pass 0025 plan without reading it.

.DESCRIPTION
    Re-derives each of the six named spot-checks. It never reads plan.md, never
    reads mutations.txt, readback.txt, denominator.txt or the run README, and
    never parses a number out of a document: every figure it reports is one it
    just produced.

    SHA-pinned per decision 0004. The fixture SHAs and the PSTerraformGraph tag
    are named here as constants, so a check that would pass against some other
    state of the world fails instead.

    -FailCheck runs the probes: each one breaks something on purpose, asserts
    THE BREAK LANDED, and then requires the check to go red. A probe that
    changed nothing and watched a check stay green has demonstrated nothing, and
    that is the failure mode this switch exists to prevent.

    Writes only under scratch/, which is not committed. One exit code.

    Checks 1, 2 and 6 need $env:AZDO_PAT and a built PSTerraformGraph. Without
    them they SKIP LOUDLY and the summary says the run graded less than it
    claims to.

.PARAMETER SkipAzdo
    Do not contact Azure DevOps even if a PAT is present.

.PARAMETER FailCheck
    Run the falsification probes instead of the checks.
#>
[CmdletBinding()]
param(
    [switch] $SkipAzdo,
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---- what this pass pinned -------------------------------------------------
$ExpectedFixtureSha = [ordered]@{
    TfFixtureShared  = '0af6ee33854bedb4147d0b13cc6db1311687775b'
    TfFixtureNetwork = '24f27be92e583b6dfc9208bca42f8ec0baf5004b'
    TfFixtureApp     = '44ea9338ff35aef328bfa8d51835fc32bea590dd'
}
$ExpectedNodeCount = 78
$ExpectedEdgeCount = 59
$ExpectedCasesDefined = 33
$TerraformTag = 'v0.2.0'

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
    if ($Ok) { Write-Host ("PASS  {0}" -f $Name) }
    else {
        Write-Host ("FAIL  {0}" -f $Name)
        $script:Failures.Add($Name)
    }
    if ($Detail) { Write-Host ("        {0}" -f $Detail) }
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
$caseScore = Join-Path $tf 'Test-TfFixtureCase.ps1'
$conformance = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'
$suite = Join-Path $RepoRoot 'evals/conformance/Conformance.Tests.ps1'

$scratch = Join-Path $RepoRoot 'scratch/verify-0025'
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
$null = New-Item -ItemType Directory -Path $scratch -Force

$tfRepo = Join-Path (Split-Path -Parent $RepoRoot) 'PSTerraformGraph'
$toHtmlRepo = Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRenderToHtml'

# ===========================================================================
# -FailCheck: break each thing, PROVE the break landed, require red.
# ===========================================================================
if ($FailCheck) {
    Write-Host 'FALSIFICATION PROBES - each breaks something, proves the break landed, and requires red.'
    Write-Host ''
    $probeFailures = [System.Collections.Generic.List[string]]::new()

    function Confirm-Probe {
        param(
            [Parameter(Mandatory)] [string] $Name,
            [Parameter(Mandatory)] [bool] $BreakLanded,
            [Parameter(Mandatory)] [bool] $WentRed,
            [string] $Detail = ''
        )
        if (-not $BreakLanded) {
            Write-Host ("PROBE-VOID  {0}  the break changed nothing; this probe proved nothing" -f $Name)
            $probeFailures.Add("$Name (break did not land)")
        }
        elseif ($WentRed) { Write-Host ("PROBE-OK    {0}  broke it, went red" -f $Name) }
        else {
            Write-Host ("PROBE-FAIL  {0}  broke it and the check stayed GREEN" -f $Name)
            $probeFailures.Add($Name)
        }
        if ($Detail) { Write-Host ("            {0}" -f $Detail) }
    }

    # P1 - the oracle comparison. Drop a case-3 edge; the comparator must see it.
    $good = Get-Content -LiteralPath $oracle -Raw | ConvertFrom-Json
    $before = ($good | ConvertTo-Json -Depth 30 -Compress).Length
    $good.graph.edges = @($good.graph.edges | Where-Object {
            -not ($_.from -eq 'TfFixtureNetwork:.#output.segment_id' -and
                $_.to -eq 'TfFixtureApp:.#local.network_segment_id') })
    $after = ($good | ConvertTo-Json -Depth 30 -Compress).Length
    $r = & $compare -Expected $oracle -ActualObject $good
    Confirm-Probe -Name 'P1 comparator sees a dropped case-3 edge' `
        -BreakLanded ($after -ne $before) -WentRed ($r.DifferenceCount -ge 1) `
        -Detail "document $before -> $after chars; $($r.DifferenceCount) difference(s)"

    # P2 - the case scorer. Same break must take case 3 down specifically.
    $s = & $caseScore -GraphObject $good
    $case3 = @($s.Cases | Where-Object { $_.Name -like '3 *' })[0]
    Confirm-Probe -Name 'P2 case scorer fails case 3 when its edge is gone' `
        -BreakLanded ($after -ne $before) -WentRed ($s.Passed -lt $s.Total -and $case3.Result -eq 'FAIL') `
        -Detail "functional-tf $($s.Passed)/$($s.Total); case 3 = $($case3.Result)"

    # P3 - the mutation harness. A mutation must be detected as its mechanism.
    foreach ($mutation in 'missing-edge', 'wrong-parent') {
        $bad = & $mutate -Path $oracle -Mutation $mutation
        $badText = ($bad | ConvertTo-Json -Depth 30 -Compress)
        $oracleText = (Get-Content -LiteralPath $oracle -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 30 -Compress)
        $m = & $compare -Expected $oracle -ActualObject $bad
        Confirm-Probe -Name "P3 mutation '$mutation' is detected" `
            -BreakLanded ($badText -ne $oracleText) -WentRed ($m.DifferenceCount -ge 1) `
            -Detail "$($m.DifferenceCount) difference(s): $(@($m.Differences | ForEach-Object { $_.Category }) -join ', ')"
    }

    # P4 - the denominator. Deleting an It from a COPY of the suite must lower
    # cases-defined. The copy is what keeps this out of the committed suite.
    $suiteCopy = Join-Path $scratch 'Conformance.Copy.Tests.ps1'
    $text = Get-Content -LiteralPath $suite -Raw
    $cut = $text -replace "(?s)\n    It 'declares a RootModule' \{.*?\n    \}\n", "`n"
    Set-Content -LiteralPath $suiteCopy -Value $cut -Encoding utf8NoBOM
    $countIn = {
        param($Path)
        $errs = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errs)
        @($ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) |
                Where-Object { $_.GetCommandName() -eq 'It' }).Count
    }
    $originalIts = & $countIn $suite
    $cutIts = & $countIn $suiteCopy
    Confirm-Probe -Name 'P4 removing an It lowers the assertion inventory' `
        -BreakLanded ($cut.Length -ne $text.Length) -WentRed ($cutIts -lt $originalIts) `
        -Detail "It statements $originalIts -> $cutIts"

    Write-Host ''
    if ($probeFailures.Count -gt 0) {
        Write-Host 'Probes that did not demonstrate what they claim:'
        foreach ($p in $probeFailures) { Write-Host ("  {0}" -f $p) }
        exit 1
    }
    Write-Host 'All probes broke something and drove their check red.'
    exit 0
}

# ===========================================================================
# Spot-check 3 - conformance re-derives an identical cases-defined
# (first, because it needs neither a PAT nor a built module)
# ===========================================================================

$errs = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($suite, [ref]$null, [ref]$errs)
$commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
$itCount = @($commands | Where-Object { $_.GetCommandName() -eq 'It' }).Count
Confirm-Check -Name '3a the suite defines the number of assertions the denominator claims' `
    -Ok ($itCount -eq $ExpectedCasesDefined) `
    -Detail "$itCount It statements in Conformance.Tests.ps1, expected $ExpectedCasesDefined"

# Two differently shaped targets. The harness itself is not a module, so the
# shapes used are the two sibling module repositories when present.
$shapes = @(
    @{ Name = 'PSTerraformGraph'; Path = $tfRepo; Module = 'PSTerraformGraph' }
    @{ Name = 'PSGraphRenderToHtml'; Path = $toHtmlRepo; Module = 'PSGraphRenderToHtml' }
) | Where-Object { Test-Path -LiteralPath $_.Path }

if (@($shapes).Count -lt 2) {
    Skip-Check -Name '3b cases-defined is identical across two differently shaped targets' `
        -Why 'needs two sibling module repositories checked out beside this one'
}
else {
    $results = foreach ($shape in $shapes) {
        $resultPath = Join-Path $scratch "$($shape.Name)-conformance.json"
        & $conformance -Path $shape.Path -Tag Universal, Repository, HouseStyle `
            -ResultPath $resultPath -ModuleName $shape.Module *> $null
        Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
    }
    $defined = @($results | ForEach-Object { $_.CasesDefined } | Sort-Object -Unique)
    $run = @($results | ForEach-Object { $_.CasesRun })
    Confirm-Check -Name '3b cases-defined is identical across two differently shaped targets' `
        -Ok (@($defined).Count -eq 1) `
        -Detail "cases-defined $(@($defined) -join ', ') ; cases-run $(@($run) -join ', ') ; public surfaces differ"

    # The other half: a denominator that never moves measures nothing.
    $narrowPath = Join-Path $scratch 'narrow-conformance.json'
    & $conformance -Path $shapes[0].Path -Tag Universal `
        -ResultPath $narrowPath -ModuleName $shapes[0].Module *> $null
    $narrow = Get-Content -LiteralPath $narrowPath -Raw | ConvertFrom-Json
    Confirm-Check -Name '3c cases-defined moves with the tag SELECTION, not the target' `
        -Ok ($narrow.CasesDefined -lt $results[0].CasesDefined) `
        -Detail "Universal alone = $($narrow.CasesDefined); three tags = $($results[0].CasesDefined)"
}

# ===========================================================================
# Spot-check 2 - the mutations are regenerated here, not read
# ===========================================================================

$control = & $compare -Expected $oracle -Actual $oracle
Confirm-Check -Name '2a control: the amended oracle compared with itself reports zero differences' `
    -Ok ($control.IsMatch -and $control.DifferenceCount -eq 0) `
    -Detail "$($control.DifferenceCount) difference(s) over $($control.ExpectedNodeCount) nodes, $($control.ExpectedEdgeCount) edges"

Confirm-Check -Name '2b the amended oracle is the size decision 0012 states' `
    -Ok ($control.ExpectedNodeCount -eq $ExpectedNodeCount -and $control.ExpectedEdgeCount -eq $ExpectedEdgeCount) `
    -Detail "$($control.ExpectedNodeCount) nodes, $($control.ExpectedEdgeCount) edges (expected $ExpectedNodeCount / $ExpectedEdgeCount)"

# Mutations 3 and 6 of the seven, by the mutator's own ordering:
# wrong-attribute and extra-edge. Regenerated against the AMENDED oracle,
# because the previous falsification was against a different document.
foreach ($case in @(
        @{ Mutation = 'wrong-attribute'; Expect = 'WrongAttribute' }
        @{ Mutation = 'extra-edge'; Expect = 'ExtraEdge' })) {
    $bad = & $mutate -Path $oracle -Mutation $case.Mutation
    $badText = ($bad | ConvertTo-Json -Depth 30 -Compress)
    $oracleText = (Get-Content -LiteralPath $oracle -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 30 -Compress)

    Confirm-Check -Name "2c probe control: the $($case.Mutation) mutation changed the document" `
        -Ok ($badText -ne $oracleText) `
        -Detail "$($oracleText.Length) -> $($badText.Length) chars"

    $result = & $compare -Expected $oracle -ActualObject $bad
    $categories = @($result.Differences | ForEach-Object { $_.Category } | Sort-Object -Unique)
    Confirm-Check -Name "2d the $($case.Mutation) mutation is detected as $($case.Expect)" `
        -Ok ($result.DifferenceCount -ge 1 -and $case.Expect -in $categories) `
        -Detail "$($result.DifferenceCount) difference(s): $($categories -join ', ')"
}

# ===========================================================================
# Spot-checks 1 and 4 - a fresh build, a regenerated graph, the battery,
# and one layout re-rendered
# ===========================================================================

$builtManifest = Join-Path $tfRepo 'output/PSTerraformGraph/PSTerraformGraph.psd1'
$srcManifest = Join-Path $tfRepo 'src/PSTerraformGraph/PSTerraformGraph.psd1'
$toHtmlManifest = Join-Path $toHtmlRepo 'output/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1'

if (-not (Test-Path -LiteralPath $srcManifest)) {
    Skip-Check -Name '1 the producer reproduces the recorded score' -Why "no PSTerraformGraph checkout at $tfRepo"
    Skip-Check -Name '4 battery and render' -Why "no PSTerraformGraph checkout at $tfRepo"
}
else {
    # 1a. The module imports from src/ AND from output/ - the dev-loader claim.
    Get-Module PSTerraformGraph, PSGraphRenderToHtml | Remove-Module -Force -ErrorAction SilentlyContinue
    $srcImport = $false
    try {
        Import-Module (Join-Path $toHtmlRepo 'src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1') -Force -ErrorAction Stop
        Import-Module $srcManifest -Force -ErrorAction Stop
        $manifest = Import-PowerShellDataFile -LiteralPath $srcManifest
        $exported = @((Get-Module PSTerraformGraph).ExportedFunctions.Keys | Sort-Object)
        $srcImport = -not (Compare-Object $exported @($manifest.FunctionsToExport | Sort-Object))
    }
    catch { $srcImport = $false }
    Confirm-Check -Name '1a the module imports from src/ and exports exactly its manifest surface' `
        -Ok $srcImport -Detail "src manifest: $srcManifest"

    $tagged = (& git -C $tfRepo tag -l $TerraformTag)
    Confirm-Check -Name "1b PSTerraformGraph carries the tag $TerraformTag" `
        -Ok ([bool]$tagged) -Detail "tags: $((& git -C $tfRepo tag -l) -join ', ')"

    if (-not (Test-Path -LiteralPath $builtManifest) -or -not (Test-Path -LiteralPath $toHtmlManifest)) {
        Skip-Check -Name '1c the built module reproduces the recorded score' `
            -Why 'output/ is absent in PSTerraformGraph or PSGraphRenderToHtml; run ./build.ps1 in both'
        Skip-Check -Name '4 battery and render' -Why 'output/ is absent; run ./build.ps1 in both'
    }
    else {
        Get-Module PSTerraformGraph, PSGraphRenderToHtml | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module $toHtmlManifest -Force
        Import-Module $builtManifest -Force

        $version = (Get-Module PSTerraformGraph).Version.ToString()
        Confirm-Check -Name '1c the built module is the tagged version' `
            -Ok ($version -eq $TerraformTag.TrimStart('v')) -Detail "built module version $version"

        # The graph is regenerated from the HARNESS copy of the fixture. The
        # AzDO clone is checked separately, in 6, where the PAT is available.
        $roots = @('TfFixtureShared', 'TfFixtureNetwork', 'TfFixtureApp') |
            ForEach-Object { Join-Path $tf "fixture/repos/$_" }
        $graph = Get-TfConfigurationGraph -Path $roots `
            -RepositoryName @('TfFixtureShared', 'TfFixtureNetwork', 'TfFixtureApp')
        $graphPath = Join-Path $scratch 'graph.json'
        $graph | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $graphPath -Encoding utf8NoBOM

        $score = & $compare -Expected $oracle -Actual $graphPath
        Confirm-Check -Name '1d the regenerated graph reproduces 0 differences against the oracle' `
            -Ok ($score.DifferenceCount -eq 0) `
            -Detail "$($score.DifferenceCount) difference(s); $($score.ActualNodeCount) nodes, $($score.ActualEdgeCount) edges"

        $cases = & $caseScore -Path $graphPath
        Confirm-Check -Name '1e the seven named cases reproduce 7 / 7' `
            -Ok ($cases.Passed -eq 7 -and $cases.Total -eq 7) `
            -Detail "functional-tf $($cases.Passed) / $($cases.Total)"

        # 4a. The consumer's battery, from the consumer's repository.
        $battery = Join-Path $toHtmlRepo 'tests/ProducerContract.Battery.ps1'
        if (Test-Path -LiteralPath $battery) {
            $b = Invoke-Pester -Container (New-PesterContainer -Path $battery -Data @{ GraphPath = $graphPath }) `
                -Output None -PassThru
            Confirm-Check -Name '4a the consumer battery is green on the regenerated graph' `
                -Ok ($b.FailedCount -eq 0 -and $b.PassedCount -ge 7) `
                -Detail "battery $($b.PassedCount) / $($b.PassedCount + $b.FailedCount)"
        }
        else { Skip-Check -Name '4a the consumer battery' -Why "no battery at $battery" }

        # 4b. One layout re-rendered, with its editor links present.
        $htmlPath = Join-Path $scratch 'tf-foundation.html'
        Export-TfConfigurationGraphHtml -Path $roots -OutputPath $htmlPath `
            -Options (New-GraphRenderOptions -Layout foundation -Title 'Terraform configuration') `
            -DefaultsRoot $scratch | Out-Null
        $html = [System.IO.File]::ReadAllText($htmlPath)
        $links = @([regex]::Matches($html, 'vscode://file/')).Count
        Confirm-Check -Name '4b one layout re-renders with its vscode link present' `
            -Ok ((Test-Path -LiteralPath $htmlPath) -and $links -gt 0 -and $html -match '"DefaultFlow":\s*"foundation"') `
            -Detail "$((Get-Item $htmlPath).Length) bytes, $links vscode://file/ occurrence(s)"
    }
}

# ===========================================================================
# Spot-check 5 - the LEDGER's Pins match git ls-remote reality
# ===========================================================================

$ledgerPath = Join-Path $RepoRoot 'LEDGER.md'
if (-not (Test-Path -LiteralPath $ledgerPath)) {
    Confirm-Check -Name '5a LEDGER.md exists with its four registers' -Ok $false -Detail 'LEDGER.md is absent'
}
else {
    $ledger = Get-Content -LiteralPath $ledgerPath -Raw
    $registers = @('## Passes', '## Runs', '## Versions', '## Backlog') |
        Where-Object { $ledger -match "(?m)^$([regex]::Escape($_))" }
    Confirm-Check -Name '5a LEDGER.md exists with its four registers' `
        -Ok (@($registers).Count -eq 4) -Detail "$(@($registers).Count) of 4 registers present"

    # The pins are claims about remotes. Check them against the remotes.
    if (Test-Path -LiteralPath $tfRepo) {
        $remoteTag = (& git -C $tfRepo ls-remote --tags origin) -match "refs/tags/$TerraformTag$"
        Confirm-Check -Name "5b the LEDGER's PSTerraformGraph pin matches the remote" `
            -Ok ($ledger -match [regex]::Escape($TerraformTag) -and [bool]$remoteTag) `
            -Detail "$TerraformTag on origin: $([bool]$remoteTag)"
    }
    else { Skip-Check -Name "5b the LEDGER's PSTerraformGraph pin" -Why 'no PSTerraformGraph checkout' }

    $pinnedShas = @([regex]::Matches($ledger, '\b[0-9a-f]{40}\b') | ForEach-Object { $_.Value })
    $fixturePinned = @($ExpectedFixtureSha.Values | Where-Object { $_ -in $pinnedShas })
    Confirm-Check -Name "5c the LEDGER pins the decision-0012 fixture SHAs" `
        -Ok (@($fixturePinned).Count -eq 3) `
        -Detail "$(@($fixturePinned).Count) of 3 fixture SHAs found in LEDGER.md"
}

# ===========================================================================
# Spot-check 6 - PAT-gated. The AzDO fixture at the decision-0012 SHAs,
# and zero builds ever queued.
# ===========================================================================

if ($SkipAzdo) {
    Skip-Check -Name '6 the AzDO fixture is at the decision-0012 SHAs' -Why '-SkipAzdo was passed'
}
elseif (-not $env:AZDO_PAT) {
    Skip-Check -Name '6 the AzDO fixture is at the decision-0012 SHAs' `
        -Why 'AZDO_PAT is not set; nothing here could contradict the claim, so it is not graded'
}
else {
    . (Join-Path $tf 'TfAzdoClient.ps1')
    $base = Get-TfAzdoBaseUri
    $repos = Invoke-TfAzdoJson -Uri "$base/git/repositories?api-version=7.1"

    $mismatches = [System.Collections.Generic.List[string]]::new()
    foreach ($name in $ExpectedFixtureSha.Keys) {
        $repo = @($repos.value | Where-Object { $_.name -eq $name }) | Select-Object -First 1
        if (-not $repo) { $mismatches.Add("$name : absent"); continue }
        $refs = Invoke-TfAzdoJson -Uri "$base/git/repositories/$($repo.id)/refs?filter=heads/main&api-version=7.1"
        $head = @($refs.value | Where-Object { $_.name -eq 'refs/heads/main' })[0].objectId
        if ($head -ne $ExpectedFixtureSha[$name]) {
            $mismatches.Add("$name : $head, expected $($ExpectedFixtureSha[$name])")
        }
    }
    Confirm-Check -Name '6a the three fixture repositories are at the decision-0012 SHAs' `
        -Ok ($mismatches.Count -eq 0) `
        -Detail $(if ($mismatches.Count -eq 0) { 'all three match' } else { $mismatches -join '; ' })

    # Zero builds ever queued. Definitions may exist; runs may not.
    $builds = Invoke-TfAzdoJson -Uri "$base/build/builds?api-version=7.1&`$top=1"
    $buildCount = @($builds.value).Count
    Confirm-Check -Name '6b no build has ever been queued in ClaudeTestingTerraform' `
        -Ok ($buildCount -eq 0) -Detail "$buildCount build run(s) reported by the builds API"
}

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
