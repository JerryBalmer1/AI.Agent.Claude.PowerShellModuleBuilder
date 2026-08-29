#Requires -Version 7.2
<#
.SYNOPSIS
    Disproves plan 0020 if it can.

.DESCRIPTION
    Re-derives every number pass 0020 claims, from a fresh clone of the target
    branch and from the graders themselves. It never parses plan.md: a verify
    script that reads the plan checks the plan against itself.

    Assumes nothing but a fresh clone of this repository and the tools. It uses
    scratch/ for nothing -- scratch/ is not committed and does not exist in a
    fresh clone -- and works in a temporary directory it removes on the way out.

    Exits 0 only when every check agrees. Otherwise it prints the name of each
    check that disagreed and exits with the number of failures.

.PARAMETER KeepClone
    Leave the temporary clone in place for inspection.
#>
[CmdletBinding()]
param(
    [switch] $KeepClone
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$RunDir     = Join-Path $RepoRoot 'runs/003-baseline-off'
$TargetUrl  = 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git'
$TargetRef  = 'run-003-baseline-off'

# The facts this pass asserts. Every one is re-derived below; none is read
# from the plan.
$RunSha       = 'd852abcff0efae39978000f48190c7240c5418bd'
$HarnessSha   = '42c717b98ba048a1c8c134a480e308c310c19e9d'
$OracleBlob   = 'bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc'
$BriefBlob    = '93c5cec3299da0ac27d3aea67f4fbcf0000001ec'
$ExpectBuild  = 0
$ExpectCases  = @('case-01','case-02','case-03','case-04','case-05','case-06',
                  'case-07','case-08','case-09','case-10','case-11','case-12')
$ExpectDiffs  = 29
$ExpectKinds  = @{ wrongNodeAttribute = 15; wrongEdgeAttribute = 10
                   wrongEdgeTarget = 2; extraNode = 1; extraEdge = 1 }
$ExpectCommands = @(
    'Get-AzDoRepository', 'Get-AzDoPipeline', 'Get-AzDoPipelineYaml'
    'Get-AzDoPipelineReference', 'Resolve-AzDoPipelineReference'
    'Get-AzDoPipelineDependencyGraph', 'Export-AzDoPipelineDependencyGraph'
)

$Failures = New-Object System.Collections.Generic.List[string]
$Skips    = New-Object System.Collections.Generic.List[string]

function Confirm-That {
    param([string] $Check, [bool] $Condition, [string] $Detail = '')
    if ($Condition) {
        Write-Host ("  [ok]   {0}" -f $Check) -ForegroundColor Green
    }
    else {
        Write-Host ("  [FAIL] {0}{1}" -f $Check, $(if ($Detail) { " -- $Detail" } else { '' })) -ForegroundColor Red
        $Failures.Add($Check)
    }
}

function Write-Skip {
    param([string] $Check, [string] $Why)
    Write-Host ("  [SKIP] {0} -- {1}" -f $Check, $Why) -ForegroundColor Yellow
    $Skips.Add($Check)
}

function Write-Section { param([string] $Name) Write-Host ''; Write-Host "== $Name" -ForegroundColor Cyan }

$Temp = Join-Path ([System.IO.Path]::GetTempPath()) ("verify-0020-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$null = New-Item -ItemType Directory -Path $Temp -Force

try {
    # ---------------------------------------------------------------------
    Write-Section 'Spot-check 1 - fresh clone of run-003-baseline-off'

    $clone = Join-Path $Temp 'PSAzureDevOpsGraph'
    git clone --quiet --branch $TargetRef --single-branch $TargetUrl $clone 2>&1 | Out-Null

    if (-not (Test-Path -LiteralPath $clone)) {
        Confirm-That 'clone of the run branch succeeds' $false 'clone failed; the remaining clone checks cannot run'
    }
    else {
        $cloneSha = (git -C $clone rev-parse HEAD).Trim()
        Confirm-That 'run branch tip matches the recorded SHA' ($cloneSha -eq $RunSha) "clone at $cloneSha"

        # Import from the clone, in a child process so a broken module cannot
        # poison this session.
        $importProbe = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$($clone -replace "'","''")/src/PSAzureDevOpsGraph/PSAzureDevOpsGraph.psd1' -Force
(Get-Module PSAzureDevOpsGraph).ExportedFunctions.Keys | Sort-Object
"@
        $exported = & pwsh -NoProfile -Command $importProbe 2>&1
        $importOk = $LASTEXITCODE -eq 0
        Confirm-That 'the module imports from a fresh clone' $importOk ($exported -join '; ')

        if ($importOk) {
            $actual = @($exported | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
            $diff = Compare-Object -ReferenceObject ($ExpectCommands | Sort-Object) -DifferenceObject $actual
            Confirm-That 'it exports exactly the seven recorded commands' ($null -eq $diff) `
                ("got: " + ($actual -join ', '))
        }

        $buildFile = Join-Path $clone 'build.ps1'
        if (Test-Path -LiteralPath $buildFile) {
            Push-Location $clone
            try {
                & pwsh -NoProfile -File $buildFile -Task All *>&1 | Out-Null
                $buildExit = $LASTEXITCODE
            }
            finally { Pop-Location }
            Confirm-That "build.ps1 exits $ExpectBuild as recorded" ($buildExit -eq $ExpectBuild) "exit $buildExit"
        }
        else {
            Confirm-That 'build.ps1 is present as recorded' $false 'no build.ps1 in the clone'
        }
    }

    # ---------------------------------------------------------------------
    Write-Section 'Spot-check 2 - conformance re-run equals the committed result'

    $committedConf = Join-Path $RunDir 'conformance-result.json'
    if (-not (Test-Path -LiteralPath $committedConf)) {
        Confirm-That 'conformance-result.json is committed' $false
    }
    elseif (-not (Test-Path -LiteralPath $clone)) {
        Write-Skip 'conformance re-run' 'no clone to score'
    }
    else {
        $recorded = Get-Content -LiteralPath $committedConf -Raw | ConvertFrom-Json
        $freshPath = Join-Path $Temp 'conformance-rerun.json'

        # -Command, not -File: 'pwsh -File' hands every argument through as a
        # string, so a four-element -Tag arrives as one comma-joined value and
        # fails the script's own ValidateSet.
        $confScript = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'
        $confCall = "& '{0}' -Path '{1}' -Tag Universal,Repository,HouseStyle,RequiresBuild -ResultPath '{2}'" -f `
            ($confScript -replace "'", "''"), ($clone -replace "'", "''"), ($freshPath -replace "'", "''")
        & pwsh -NoProfile -Command $confCall *>&1 | Out-Null

        if (-not (Test-Path -LiteralPath $freshPath)) {
            Confirm-That 'the conformance suite produced a result' $false
        }
        else {
            $fresh = Get-Content -LiteralPath $freshPath -Raw | ConvertFrom-Json
            foreach ($field in 'Passed', 'Failed', 'CasesRun', 'ScorePct') {
                Confirm-That "conformance $field re-derives to $($recorded.$field)" `
                    ($fresh.$field -eq $recorded.$field) "re-run gave $($fresh.$field)"
            }
        }
    }

    # ---------------------------------------------------------------------
    Write-Section 'Spot-check 3 - Compare-Graph reproduces the score and the diff'

    $graphPath  = Join-Path $RunDir 'graph.json'
    $reportPath = Join-Path $RunDir 'compare-report.json'
    $compare    = Join-Path $RepoRoot 'evals/functional/Compare-Graph.ps1'

    if (-not (Test-Path -LiteralPath $graphPath)) {
        Confirm-That 'graph.json is committed' $false
    }
    else {
        $rerunReport = Join-Path $Temp 'compare-rerun.json'
        & pwsh -NoProfile -File $compare -CandidatePath $graphPath -ReportPath $rerunReport -Quiet
        $compareExit = $LASTEXITCODE

        Confirm-That 'Compare-Graph still reports disagreement (exit 1)' ($compareExit -eq 1) "exit $compareExit"

        if (Test-Path -LiteralPath $rerunReport) {
            $r = Get-Content -LiteralPath $rerunReport -Raw | ConvertFrom-Json

            Confirm-That "difference count re-derives to $ExpectDiffs" `
                ($r.differenceCount -eq $ExpectDiffs) "got $($r.differenceCount)"

            $cases = @($r.cases)
            $caseDiff = Compare-Object -ReferenceObject $ExpectCases -DifferenceObject $cases
            Confirm-That 'the same twelve cases fail' ($null -eq $caseDiff) ("got: " + ($cases -join ', '))

            foreach ($kind in $ExpectKinds.Keys) {
                $got = if ($r.countsByKind.PSObject.Properties.Name -contains $kind) { $r.countsByKind.$kind } else { 0 }
                Confirm-That "countsByKind.$kind is $($ExpectKinds[$kind])" ($got -eq $ExpectKinds[$kind]) "got $got"
            }

            foreach ($absent in 'missingNode', 'missingEdge') {
                $present = $r.countsByKind.PSObject.Properties.Name -contains $absent
                Confirm-That "no $absent differences (the run's central claim)" (-not $present) 'the graph is no longer structurally complete'
            }

            if (Test-Path -LiteralPath $reportPath) {
                $committed = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
                Confirm-That 'the committed report agrees with the re-run' `
                    ($committed.differenceCount -eq $r.differenceCount)
            }
        }
        else {
            Confirm-That 'Compare-Graph produced a report' $false
        }

        # diff.txt must be the comparator's own words, not a summary of them.
        $diffTxt = Join-Path $RunDir 'diff.txt'
        if (Test-Path -LiteralPath $diffTxt) {
            $text = Get-Content -LiteralPath $diffTxt -Raw
            Confirm-That 'diff.txt records the difference count' ($text -match '29 difference')
            Confirm-That 'diff.txt names the failed cases' ($text -match 'case-12')
        }
        else {
            Confirm-That 'diff.txt is committed' $false
        }
    }

    # ---- live regeneration, only with a PAT ------------------------------
    if ([string]::IsNullOrWhiteSpace($env:AZDO_PAT)) {
        Write-Skip 'live regeneration against the fixture' 'AZDO_PAT is not set. This check did NOT pass; it did not run.'
    }
    elseif (-not (Test-Path -LiteralPath $clone)) {
        Write-Skip 'live regeneration against the fixture' 'no clone to run'
    }
    else {
        $livePath = Join-Path $Temp 'graph-live.json'
        $regen = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$($clone -replace "'","''")/src/PSAzureDevOpsGraph/PSAzureDevOpsGraph.psd1' -Force
Get-AzDoPipelineDependencyGraph -Organisation 'jlbalmerjr1' -Project 'ClaudeTesting' |
    Export-AzDoPipelineDependencyGraph -Path '$($livePath -replace "'","''")'
"@
        & pwsh -NoProfile -Command $regen *>&1 | Out-Null
        $regenOk = ($LASTEXITCODE -eq 0) -and (Test-Path -LiteralPath $livePath)
        Confirm-That 'the module regenerates a graph from the live fixture' $regenOk

        if ($regenOk) {
            $a = (Get-Content -LiteralPath $graphPath -Raw) -replace "`r`n", "`n"
            $b = (Get-Content -LiteralPath $livePath  -Raw) -replace "`r`n", "`n"
            Confirm-That 'the live graph is byte-identical to the committed one' ($a -eq $b) `
                'the fixture or the module has changed since the run'
        }
    }

    # ---------------------------------------------------------------------
    Write-Section 'Spot-check 4 - oracle unchanged, evals/ untouched'

    $oracle = (git -C $RepoRoot ls-tree HEAD -- evals/functional/fixture/expected-graph.json) -split '\s+'
    Confirm-That "oracle blob is still $OracleBlob" ($oracle -contains $OracleBlob) `
        'the oracle changed; every score in this run is against a different answer'

    $brief = (git -C $RepoRoot ls-tree HEAD -- evals/functional/BRIEF.md) -split '\s+'
    Confirm-That "brief blob is still $BriefBlob" ($brief -contains $BriefBlob)

    $evalsDiff = git -C $RepoRoot diff --stat "$HarnessSha..HEAD" -- evals/
    Confirm-That 'this pass changed nothing under evals/' ([string]::IsNullOrWhiteSpace(($evalsDiff -join ''))) `
        ("diff: " + ($evalsDiff -join ' '))

    # ---------------------------------------------------------------------
    Write-Section 'Spot-check 5 - no credential anywhere'

    $patterns = @('AZDO_PAT\s*=\s*["'']?[A-Za-z0-9]{20,}', '[A-Za-z0-9]{52}', 'Authorization:\s*Basic\s+[A-Za-z0-9+/=]{20,}')
    $scanRoots = @($RunDir)
    if (Test-Path -LiteralPath $clone) { $scanRoots += $clone }

    $hits = New-Object System.Collections.Generic.List[string]
    foreach ($root in $scanRoots) {
        $files = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }
        foreach ($file in $files) {
            $text = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
            if (-not $text) { continue }
            foreach ($pattern in $patterns) {
                if ($text -match $pattern) { $hits.Add("$($file.FullName) ~ $pattern") }
            }
            if ($env:AZDO_PAT -and $text.Contains($env:AZDO_PAT)) {
                $hits.Add("$($file.FullName) contains the live token")
            }
        }
    }
    Confirm-That 'no credential-shaped string in the run record or the module clone' ($hits.Count -eq 0) `
        ($hits -join ' | ')

    # ---------------------------------------------------------------------
    Write-Section 'Run record completeness'

    foreach ($name in 'README.md', 'graph.json', 'diff.txt', '003.html', 'findings.md') {
        Confirm-That "runs/003-baseline-off/$name exists" (Test-Path -LiteralPath (Join-Path $RunDir $name))
    }

    $html = Join-Path $RunDir '003.html'
    if (Test-Path -LiteralPath $html) {
        $h = Get-Content -LiteralPath $html -Raw
        Confirm-That '003.html is self-contained (no http/https)' ($h -notmatch 'https?://')
        Confirm-That '003.html draws all 50 nodes' (([regex]::Matches($h, 'data-node-id')).Count -eq 50)
    }

    $schema = Join-Path $RepoRoot 'evals/functional/fixture/graph.schema.json'
    if ((Test-Path -LiteralPath $graphPath) -and (Test-Path -LiteralPath $schema)) {
        $valid = $false
        try { $valid = (Get-Content -LiteralPath $graphPath -Raw | Test-Json -Schema (Get-Content -LiteralPath $schema -Raw)) }
        catch { $valid = $false }
        Confirm-That 'graph.json validates against graph.schema.json' $valid
    }
}
finally {
    if ($KeepClone) { Write-Host ''; Write-Host "Clone kept at $Temp" -ForegroundColor Yellow }
    elseif (Test-Path -LiteralPath $Temp) {
        Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
if ($Skips.Count -gt 0) {
    Write-Host "SKIPPED ($($Skips.Count)): $($Skips -join '; ')" -ForegroundColor Yellow
    Write-Host 'A skipped check has not passed.' -ForegroundColor Yellow
}

if ($Failures.Count -eq 0) {
    Write-Host 'verify 0020: every check agreed.' -ForegroundColor Green
    exit 0
}

Write-Host "verify 0020: $($Failures.Count) check(s) disagreed:" -ForegroundColor Red
foreach ($f in $Failures) { Write-Host "  - $f" -ForegroundColor Red }
exit $Failures.Count
