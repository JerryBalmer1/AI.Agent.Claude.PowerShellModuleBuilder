#Requires -Version 7.2
<#
.SYNOPSIS
    Re-fire the LEDGER-47 probe: build the fixture to the convention, then run
    the check against it.
.DESCRIPTION
    One script rather than a transcript verify.ps1 retypes. LEDGER 47 says a
    pass that writes a rule and its check must RUN them against each other; a
    second copy of the commands that did so is a second thing that can drift
    from the first.

    Three claims, in order, and each is printed:

    1. The fixture contains no dash form of a parameter, so the assertion
       cannot pass by accident on a syntax the house standard forbids.
    2. Help.Tests.ps1's set-coverage assertion runs against it - the container
       loads, and the case is not INAPPLICABLE.
    3. It passes.
.PARAMETER RepoRoot
    The harness repository root. Defaults to two levels above this file, so a
    fresh clone needs no argument.
.PARAMETER WorkPath
    Where to materialise the fixture. Defaults to a new temp directory, which
    is removed afterwards.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $WorkPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$owned = -not $WorkPath
if ($owned) { $WorkPath = Join-Path ([IO.Path]::GetTempPath()) ("splat-probe-" + [guid]::NewGuid().ToString('n')) }

try {
    & "$PSScriptRoot/New-SplatProbeFixture.ps1" -Path $WorkPath | Out-Null
    $source = Join-Path $WorkPath 'src/PSSplatProbe/Public/Get-ProbeThing.ps1'

    "PROBE: LEDGER 47 - the house splat standard against the set-coverage assertion"
    "fixture:   $source"
    "assertion: evals/conformance/Help.Tests.ps1, 'shows every named parameter set of <_.Name> in an example'"
    ''

    # The dash form is what 0039's first draft looked for and what a conforming
    # example never writes. If one appeared here the probe would be green for
    # the wrong reason.
    $dash = @(Select-String -Path $source -Pattern '-(Name|Path)\b' | ForEach-Object { $_.Line.Trim() })
    "DASH FORM IN FIXTURE: $($dash.Count) occurrence(s)"
    $dash | ForEach-Object { "  $_" }
    if ($dash.Count -ne 0) { throw 'The fixture is not written to the house standard: it names a parameter in the dash form.' }
    ''

    Import-Module Pester -MinimumVersion 6.0.0
    $env:CONFORMANCE_TARGET = (Resolve-Path -LiteralPath $WorkPath).Path
    $env:CONFORMANCE_MODULE_NAME = 'PSSplatProbe'

    $cfg = New-PesterConfiguration
    $cfg.Run.Path = "$RepoRoot/evals/conformance/Help.Tests.ps1"
    $cfg.Filter.FullName = '*shows every named parameter set*'
    $cfg.Output.Verbosity = 'None'
    $cfg.Run.PassThru = $true
    $result = Invoke-Pester -Configuration $cfg

    # 45: a container that fails discovery takes its assertions with it and the
    # numbers still look ordinary. Named before the counts, not after.
    $broken = @($result.Containers | Where-Object { $_.ErrorRecord })
    "CONTAINERS FAILED: $($broken.Count)"
    if ($broken.Count) { $broken | ForEach-Object { "  $($_.ErrorRecord[0].Exception.Message)" } }

    foreach ($test in $result.Tests) { "[$($test.Result)] $($test.ExpandedName)" }
    "PASSED=$($result.PassedCount) FAILED=$($result.FailedCount) SELECTED=$($result.TotalCount - $result.NotRunCount)"
    ''

    $ok = $broken.Count -eq 0 -and $result.PassedCount -eq 1 -and $result.FailedCount -eq 0
    if ($ok) { 'SPLAT EXAMPLE: passes as shipped' } else { 'SPLAT EXAMPLE: FAILS - the assertion and the convention disagree' }
    if (-not $ok) { exit 1 }
}
finally {
    if ($owned -and (Test-Path -LiteralPath $WorkPath)) {
        Remove-Item -LiteralPath $WorkPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
