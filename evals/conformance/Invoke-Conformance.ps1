#Requires -Version 7.0
<#
.SYNOPSIS
    Run the conformance suite against a PowerShell module repository.
.PARAMETER Path
    Repository root of the module under test.
.PARAMETER Tag
    Which assertion sets to run. Universal, HouseStyle, RequiresBuild.
    Default is Universal and HouseStyle, which need no build output.
.PARAMETER ResultPath
    Where to write result.json. Default: alongside the target, ./conformance-result.json
.PARAMETER PassExitCode
    Exit with the failure count instead of 0. Off by default: a red conformance
    run is data, and the harness reads the score from result.json, not from an
    exit code. Turn it on only for a caller that genuinely wants a red run to
    fail a pipeline step.
.EXAMPLE
    ./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph
.EXAMPLE
    ./Invoke-Conformance.ps1 -Path ./scratch/run-01/PSAzureDevOpsGraph -Tag Universal,HouseStyle,RequiresBuild
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Path,

    [ValidateSet('Universal', 'HouseStyle', 'RequiresBuild')]
    [string[]] $Tag = @('Universal', 'HouseStyle'),

    [string] $ResultPath,

    [switch] $PassExitCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$target = (Resolve-Path -LiteralPath $Path).Path
if (-not $ResultPath) {
    $ResultPath = Join-Path (Get-Location) 'conformance-result.json'
}

$pester = Get-Module -Name Pester -ListAvailable |
    Where-Object { $_.Version -ge [version]'6.0.0' -and $_.Version -lt [version]'7.0.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pester) {
    throw 'Pester 6.x is required. Install-Module Pester -RequiredVersion 6.1.0 -Force'
}
Import-Module -Name $pester.Path -Force

# The suite reads its target from the environment because Pester needs the path
# at discovery time to enumerate public functions for -ForEach.
$env:CONFORMANCE_TARGET = $target

$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot 'Conformance.Tests.ps1'
$config.Run.PassThru = $true
# Deliberately NOT Run.Throw. A red conformance run is data, not a build
# failure - the harness records the score and moves on to the next run.
$config.Run.Throw = $false
$config.Filter.Tag = $Tag
$config.Output.Verbosity = 'Detailed'

$result = Invoke-Pester -Configuration $config

$summary = [pscustomobject]@{
    Target      = $target
    Tags        = $Tag
    RunAt       = (Get-Date).ToString('o')
    Total       = $result.TotalCount
    Passed      = $result.PassedCount
    Failed      = $result.FailedCount
    Skipped     = $result.SkippedCount
    NotRun      = $result.NotRunCount
    # Denominator is what actually executed. TotalCount includes tests filtered
    # out by -Tag (NotRun), so dividing by Total - Skipped charged the score for
    # assertions the caller deliberately did not select: a Universal,HouseStyle
    # run scored 85% instead of 92% purely because RequiresBuild was excluded.
    ScorePct    = if (($result.PassedCount + $result.FailedCount) -gt 0) {
                      [math]::Round(100 * $result.PassedCount / ($result.PassedCount + $result.FailedCount), 2)
                  } else { 0 }
    Failures    = @($result.Failed | ForEach-Object {
                      [pscustomobject]@{
                          Name    = $_.ExpandedPath
                          Message = ($_.ErrorRecord.Exception.Message -split "`n")[0]
                      }
                  })
}

$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ResultPath -Encoding utf8
Write-Host ''
Write-Host "Conformance: $($summary.Passed)/$($summary.Passed + $summary.Failed) ($($summary.ScorePct)%)  ->  $ResultPath"

$summary

# Invoke-Pester sets $LASTEXITCODE to the failure count even with Run.Throw and
# Run.Exit both off, so a red conformance run left this script looking like a
# crash - the exact opposite of the contract three lines of comment above claim.
# A harness that checks exit codes would have treated every red run as a broken
# runner and never read the score it wrote.
#
# A red run is data. Say so in the exit code, and give the callers who really do
# want a red run to fail a pipeline step an explicit way to ask.
if ($PassExitCode) { exit $summary.Failed }
exit 0
