#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive pass 0036's claims from a fresh clone rather than reading them.

.DESCRIPTION
    Five named checks, from the pass prompt. Nothing here reads a number out of
    the record it is checking: the build is re-run, the graph is re-produced
    from the live repositories, and the comparator is re-run against the oracle.

    Scoring clones land under a SHORT root. The session scratchpad path is long
    enough that `git clone` dies with "cannot write keep file ... Filename too
    long" before writing an object -- observed in pass 0033 and again in run
    007, and it looks exactly like a network fault if you have not seen it.

.PARAMETER FailCheck
    Deliberately break one check, to prove it can fail. A verify script that has
    only ever been green is indistinguishable from one that cannot go red.

.PARAMETER SkipClone
    Skip checks 1 and 2, which need the network and a build.
#>
[CmdletBinding()]
param(
    [ValidateSet('None', '1', '2', '3', '4', '5')]
    [string] $FailCheck = 'None',
    [switch] $SkipClone
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Harness = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Run = Join-Path $Harness 'runs/tf-003-generalisation'
$Ecosystem = Split-Path -Parent $Harness
$Work = 'C:\Users\jlbal\AppData\Local\Temp\p0036\verify'
$Clones = Join-Path $Harness 'scratch/runs/tf-003-clones'

$FinalSha = 'd76d16bb5083f422ccc05671e21cefde3c1a004e'
$FixtureShas = [ordered]@{
    TfSiteCore = 'a228e78c247d2d4367303f303c4363d9906e06f2'
    TfSiteEdge = '1ae66c2712f799a69304cb4364e91e4d10d694c4'
    TfSiteOps  = 'fe27a34f7585b86b6fdbf12b609e17d4cb0f4b83'
}

$results = [System.Collections.Generic.List[object]]::new()
function Add-Result {
    param([string] $Check, [bool] $Passed, [string] $Detail, [switch] $Skipped)
    $state = $Skipped ? 'SKIP' : ($Passed ? 'PASS' : 'FAIL')
    $results.Add([pscustomobject]@{ Check = $Check; Result = $state; Detail = $Detail })
    Write-Host ('  {0,-5} {1,-52} {2}' -f $state, $Check, $Detail)
}

Write-Host "`nPass 0036 verification`n"

# ---- 1. Fresh built clone reproduces the build and the score ---------------
$graphPath = $null
if ($SkipClone) {
    Add-Result '1 fresh built clone reproduces build and score' $false 'skipped by request' -Skipped
    Add-Result '2 battery on the regenerated graph' $false 'skipped by request' -Skipped
}
elseif (-not $env:AZDO_PAT) {
    # Loud, never quiet: a check that reports success where nothing could
    # contradict it is worse than one that says it did not run.
    Add-Result '1 fresh built clone reproduces build and score' $false 'AZDO_PAT is not set: the live repositories cannot be cloned, so checks 1 and 2 GRADE NOTHING' -Skipped
    Add-Result '2 battery on the regenerated graph' $false 'AZDO_PAT is not set' -Skipped
}
else {
    if (Test-Path $Work) { Remove-Item $Work -Recurse -Force -ErrorAction SilentlyContinue }
    $null = New-Item -ItemType Directory -Path $Work -Force

    $target = Join-Path $Work 'target'
    git clone --quiet --branch run-tf-003-generalisation https://github.com/JerryBalmer1/PSTerraformGraph.git $target 2>&1 | Out-Null
    $sha = (git -C $target rev-parse HEAD).Trim()

    foreach ($name in $FixtureShas.Keys) {
        $dest = Join-Path $Work $name
        if (Test-Path $dest) { continue }
        $env:GIT_CONFIG_COUNT = '1'
        $env:GIT_CONFIG_KEY_0 = 'http.extraHeader'
        $env:GIT_CONFIG_VALUE_0 = 'Authorization: Basic ' +
        [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$env:AZDO_PAT"))
        git clone --quiet "https://dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/$name" $dest 2>&1 | Out-Null
        $env:GIT_CONFIG_COUNT = $null; $env:GIT_CONFIG_KEY_0 = $null; $env:GIT_CONFIG_VALUE_0 = $null
    }

    foreach ($module in 'PSGraphRender', 'PSGraphRenderToHtml') {
        $dir = Join-Path $Ecosystem "$module/output"
        if ($env:PSModulePath -notlike "*$dir*") { $env:PSModulePath = $dir + [IO.Path]::PathSeparator + $env:PSModulePath }
    }

    Push-Location $target
    $null = & pwsh -NoProfile -File ./build.ps1 2>&1
    $buildExit = $LASTEXITCODE
    Pop-Location

    Import-Module (Join-Path $target 'output/PSTerraformGraph/PSTerraformGraph.psd1') -Force
    $roots = $FixtureShas.Keys | ForEach-Object { Join-Path $Work $_ }
    $graph = Get-TfGraph -Path $roots
    $graphPath = Join-Path $Work 'graph.json'
    $null = Export-TfGraph -Graph $graph -Path $graphPath

    $comparison = & (Join-Path $Harness 'evals/tf/Compare-TfGraph.ps1') `
        -Expected (Join-Path $Harness 'evals/tf/fixture2/expected-graph.json') -Actual $graphPath

    $recordedHash = (Get-FileHash (Join-Path $Run 'graph.json')).Hash
    $freshHash = (Get-FileHash $graphPath).Hash
    if ($FailCheck -eq '1') { $freshHash = 'BROKEN-BY-FAILCHECK' }

    $ok = $sha -eq $FinalSha -and $buildExit -eq 0 -and $comparison.IsMatch -and
    $comparison.DifferenceCount -eq 0 -and $recordedHash -eq $freshHash
    Add-Result '1 fresh built clone reproduces build and score' $ok (
        'sha {0} | build exit {1} | differences {2} | graph bytes {3}' -f
        ($sha -eq $FinalSha ? 'matches' : "MISMATCH $sha"), $buildExit,
        $comparison.DifferenceCount, ($recordedHash -eq $freshHash ? 'identical to the record' : 'DIFFER'))

    $batteryInput = $graphPath
    if ($FailCheck -eq '2') {
        # An empty graph satisfies every schema rule and is exactly what a
        # producer that failed silently emits. The battery's "is not empty"
        # assertion exists for it.
        $batteryInput = Join-Path $Work 'empty-graph.json'
        @{ graph = @{ nodes = @(); edges = @(); meta = @{ producer = 'x'; producerVersion = '0' } } } |
            ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $batteryInput -Encoding utf8
    }
    $battery = Invoke-Pester -Container (New-PesterContainer `
            -Path (Join-Path $Ecosystem 'PSGraphRenderToHtml/tests/ProducerContract.Battery.ps1') `
            -Data @{ GraphPath = $batteryInput }) -PassThru -Output None
    $ran = $battery.PassedCount + $battery.FailedCount
    Add-Result '2 battery on the regenerated graph' ($battery.FailedCount -eq 0 -and $ran -gt 0) (
        '{0} / {1}{2}' -f $battery.PassedCount, $ran, ($ran -eq 0 ? '  ZERO CASES IS NOT A PASS' : ''))
}

# ---- 3. The duplicate-id assertion is active in the scoring path -----------
# Reading the comparator is not evidence that it detects anything. Plant a
# duplicate in a scratch COPY of the produced graph and require a refusal.
$source = $graphPath ? $graphPath : (Join-Path $Run 'graph.json')
$planted = Join-Path ([IO.Path]::GetTempPath()) 'p0036-duplicate.json'
$document = Get-Content -LiteralPath $source -Raw | ConvertFrom-Json
$clone = $document.graph.nodes[0].PSObject.Copy()
if ($FailCheck -eq '3') { $clone.id = 'not-actually-a-duplicate' }
$document.graph.nodes = @($document.graph.nodes) + @($clone)
$document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $planted -Encoding utf8

$planted3 = & (Join-Path $Harness 'evals/tf/Compare-TfGraph.ps1') `
    -Expected (Join-Path $Harness 'evals/tf/fixture2/expected-graph.json') -Actual $planted
$duplicateSeen = $planted3.ActualDuplicateIdCount -gt 0
Add-Result '3 duplicate-id assertion refuses a planted duplicate' (-not $planted3.IsMatch -and $duplicateSeen) (
    'IsMatch {0} | ActualDuplicateIdCount {1} | planted id ''{2}''' -f $planted3.IsMatch, $planted3.ActualDuplicateIdCount, $clone.id)
Remove-Item -LiteralPath $planted -Force -ErrorAction SilentlyContinue

# ---- 4. Fixtures untouched, and nothing was queued -------------------------
$fixtureOk = $true
$detail = [System.Collections.Generic.List[string]]::new()
foreach ($name in $FixtureShas.Keys) {
    $path = Join-Path $Clones $name
    if (-not (Test-Path $path)) { $detail.Add("$name absent"); continue }
    $actual = (git -C $path rev-parse HEAD).Trim()
    $want = $FailCheck -eq '4' ? 'deadbeef' : $FixtureShas[$name]
    if ($actual -ne $want) { $fixtureOk = $false; $detail.Add("$name $actual != $want") }
}
# Fixture 1 and fixture 2 are never edited by a run.
$dirty = @(@(git -C $Harness status --porcelain -- evals/) | Where-Object { $_ })
if ($dirty.Count) { $fixtureOk = $false; $detail.Add("evals/ dirty: $($dirty -join '; ')") }

$queued = 'not checked'
if ($env:AZDO_PAT) {
    try {
        $header = @{ Authorization = 'Basic ' + [Convert]::ToBase64String(
                [Text.Encoding]::ASCII.GetBytes(":$env:AZDO_PAT")) }
        $builds = Invoke-RestMethod -Method Get -Headers $header -ErrorAction Stop `
            -Uri 'https://dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_apis/build/builds?api-version=7.1'
        $since = [datetime]::Parse('2026-09-02T10:56:11-07:00').ToUniversalTime()
        $recent = @($builds.value | Where-Object { $_.PSObject.Properties['queueTime'] -and
                [datetime]::Parse($_.queueTime).ToUniversalTime() -ge $since })
        $queued = "$($recent.Count) since phase 1 started"
        if ($recent.Count) { $fixtureOk = $false }
    }
    catch { $queued = "could not be read ($($_.Exception.Message.Split([char]10)[0]))" }
}
else { $queued = 'AZDO_PAT unset: NOT CHECKED' }
Add-Result '4 fixtures at their pinned SHAs, zero builds queued' $fixtureOk (
    'fixture 2 pinned{0} | evals/ clean | builds queued: {1}' -f
    ($detail.Count ? " ($($detail -join '; '))" : ''), $queued)

# ---- 5. Five distinct session identifiers, and no PAT anywhere -------------
# The four prior ids are DERIVED from the acceptance test rather than retyped
# here: two copies of a list are two things that can disagree.
$acceptance = Get-Content (Join-Path $PSScriptRoot 'accept.Tests.ps1') -Raw
$prior = @([regex]::Matches($acceptance, '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') |
        ForEach-Object { $_.Value }) | Sort-Object -Unique
$record = Get-Content (Join-Path $Run 'README.md') -Raw
$mine = ([regex]::Match($record, 'session-identifier:\s*(\S+)')).Groups[1].Value
if ($FailCheck -eq '5') { $mine = $prior[0] }
$all = @($prior) + @($mine)
$distinct = @($all | Sort-Object -Unique).Count -eq 5 -and $all.Count -eq 5

# git grep exits 1 when it finds nothing, which PS 7.4 turns into a terminating
# error under $ErrorActionPreference = 'Stop'. Finding nothing is the wanted
# outcome here, so the exit code is read rather than thrown on.
$patScan = @()
$previous = $PSNativeCommandUseErrorActionPreference
$PSNativeCommandUseErrorActionPreference = $false
$scanned = @('runs/tf-003-generalisation', 'plans/0036-tf-003')
$patScan = @(git -C $Harness grep -I -n -E '[A-Za-z0-9+/]{60,}={0,2}' -- @scanned 2>$null)
# A literal assignment of the token anywhere in what this pass wrote.
$patScan += @(git -C $Harness grep -I -n -E 'AZDO_PAT\s*=\s*[^$"'']' -- @scanned 2>$null)
$PSNativeCommandUseErrorActionPreference = $previous
$patScan = @($patScan | Where-Object { $_ })

Add-Result '5 five distinct session ids, PAT scan zero' ($distinct -and $patScan.Count -eq 0) (
    '{0} ids, {1} distinct | credential-shaped strings in this pass''s records: {2}' -f
    $all.Count, @($all | Sort-Object -Unique).Count, $patScan.Count)

# ---- summary ---------------------------------------------------------------
$failed = @($results | Where-Object Result -EQ 'FAIL').Count
$skipped = @($results | Where-Object Result -EQ 'SKIP').Count
Write-Host ("`n{0} passed, {1} failed, {2} skipped." -f
    @($results | Where-Object Result -EQ 'PASS').Count, $failed, $skipped)
if ($skipped) { Write-Host 'A skipped check graded nothing. It is not a pass.' }
exit ($failed -gt 0 ? 1 : 0)
