#Requires -Version 7.0
<#
.SYNOPSIS
    Run the harness's own tests - the ones that grade the conformance
    instrument rather than any target.

.DESCRIPTION
    evals/conformance/ grades a module. This directory grades THAT, and the two
    must not be run by the same command, because Invoke-Conformance.ps1's
    CasesDefined is the count of It statements it finds in its own directory
    and is the denominator every conformance score in this repository is
    reported against. A harness test that reached that inventory would move the
    denominator and make the scores incomparable.

    So: separate directory, separate runner, separate tag. Nothing here is ever
    discovered by Invoke-Conformance.ps1, whose discovery is
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.Tests.ps1 -File, with no
    -Recurse.

    FailOnNullOrEmptyForEach is deliberately left ON, which is the opposite of
    the conformance runner's setting and for the opposite reason. There, an
    empty -ForEach means the assertion is inapplicable to that target. Here,
    the -ForEach collections are built from the harness's own files, so an
    empty one means the extraction found nothing - and a run of zero cases that
    reported a pass is the exact false signal these tests exist to prevent.

.PARAMETER ConformanceDir
    Which conformance directory to grade. Defaults to ../conformance. A
    falsification probe points this at a scratch copy with a site deliberately
    broken, which is how the polarity of these tests is shown.
.PARAMETER Output
    Pester verbosity. Detailed by default.
.EXAMPLE
    ./evals/harness/Invoke-HarnessTests.ps1
.EXAMPLE
    ./evals/harness/Invoke-HarnessTests.ps1 -ConformanceDir ./scratch/broken/conformance
#>
[CmdletBinding()]
param(
    [string] $ConformanceDir,
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string] $Output = 'Detailed'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $ConformanceDir) {
    $ConformanceDir = Join-Path $PSScriptRoot '../conformance'
}
$ConformanceDir = (Resolve-Path -LiteralPath $ConformanceDir).Path
if (-not (Test-Path -LiteralPath $ConformanceDir)) {
    throw "Conformance directory not found: $ConformanceDir"
}

$pester = Get-Module -Name Pester -ListAvailable |
    Where-Object { $_.Version -ge [version]'6.0.0' -and $_.Version -lt [version]'7.0.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1
if (-not $pester) {
    throw 'Pester 6.x is required. Install-Module Pester -RequiredVersion 6.1.0 -Force'
}
Import-Module -Name $pester.Path -Force

$files = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.Tests.ps1 -File | Sort-Object Name)
if ($files.Count -eq 0) { throw "No *.Tests.ps1 in '$PSScriptRoot'." }

Write-Host "Harness tests: $($files.Name -join ', ')"
Write-Host "Grading:       $ConformanceDir"

$previous = $env:HARNESS_CONFORMANCE_DIR
$env:HARNESS_CONFORMANCE_DIR = $ConformanceDir
try {
    $config = New-PesterConfiguration
    $config.Run.Path = @($files.FullName)
    $config.Run.PassThru = $true
    $config.Run.Throw = $false
    $config.Output.Verbosity = $Output

    $result = Invoke-Pester -Configuration $config
}
finally {
    $env:HARNESS_CONFORMANCE_DIR = $previous
}

# A container whose discovery threw contributes no tests at all, so a run that
# only counted Failed would report it as a clean pass. Same rule the conformance
# runner learned the hard way: not run is not a pass.
$broken = @($result.Containers | Where-Object { @($_.ErrorRecord).Count -gt 0 })
$ran = $result.PassedCount + $result.FailedCount

Write-Host ''

# Per-Describe, on its own machine-readable line. A caller that wanted to know
# WHICH check went red would otherwise have to scrape Pester's own output,
# where a failure line carries the test name and not the block it belongs to -
# so a probe asking 'did the polarity pair fail?' would read zero and report
# the probe as not firing. That is the false 'does not fire' the falsification
# protocol exists to detect, manufactured by its own bookkeeping.
foreach ($group in ($result.Tests | Group-Object -Property { $_.Path[0] } | Sort-Object Name)) {
    $p = @($group.Group | Where-Object { $_.Result -eq 'Passed' }).Count
    $f = @($group.Group | Where-Object { $_.Result -eq 'Failed' }).Count
    Write-Host "Describe=$($group.Name) Passed=$p Failed=$f"
}

Write-Host "Passed=$($result.PassedCount) Failed=$($result.FailedCount) Ran=$ran BrokenContainers=$($broken.Count)"
foreach ($b in $broken) {
    Write-Host "  container failed: $(Split-Path -Leaf $b.Item.FullName): $(($b.ErrorRecord[0].Exception.Message -split "`n")[0])"
}

if ($broken.Count -gt 0) {
    Write-Host 'VERDICT=BROKEN'
    exit 2
}
if ($ran -eq 0) {
    Write-Host 'VERDICT=ZERO CASES'
    exit 3
}
if ($result.FailedCount -gt 0) {
    Write-Host 'VERDICT=RED'
    exit 1
}
Write-Host 'VERDICT=GREEN'
exit 0
