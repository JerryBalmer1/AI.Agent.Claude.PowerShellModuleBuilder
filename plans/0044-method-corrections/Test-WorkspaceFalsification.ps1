#Requires -Version 7.0
#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0' }
<#
.SYNOPSIS
    Falsification driver for the 'Workspace composition' assertion (pass 0044).

.DESCRIPTION
    The assertion says a tracked workspace file must not register PSModuleGraph
    as a folder. This script proves it can go red, proves it goes red for the
    right reason, and proves it stays green where it must.

    Five fixtures, built under scratch/ at run time so that nothing here depends
    on scratch/ existing in a fresh clone. Each is a minimal module repository,
    for the reason given on New-Fixture below:

      18a  break           registers ../PSModuleGraph       must be RED
      18b  restore         the same file, folder removed     must be GREEN
      18c  scope control   names it in a comment and in a
                           settings value, registers only
                           siblings                          must be GREEN
      18d  segment control registers ../PSModuleGraphTools   must be GREEN
      18e  absence control no workspace file at all          must be ZERO CASES

    18c is the control that matters. A text match for 'PSModuleGraph' would fire
    on it, and would therefore fire on any file that documents the rule -
    including this repository's own records. 18d guards the other direction: a
    sibling whose name merely starts with the reference's is not the reference.
    18e is the one that is not about this assertion's polarity at all but about
    the suite's: zero cases must report as inapplicable and must never be
    counted as a pass, and it must not take the rest of the suite down with it.

.PARAMETER ScratchRoot
    Where the fixtures are built. Must be under a directory named scratch.
.PARAMETER KeepFixtures
    Leave the fixtures on disk for inspection. Off by default.
#>
[CmdletBinding()]
param(
    [string] $ScratchRoot,
    [switch] $KeepFixtures
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..')).Path
$suite = Join-Path $repo 'evals/conformance/Conformance.Tests.ps1'
if (-not (Test-Path -LiteralPath $suite)) { throw "Conformance suite not found: $suite" }

if (-not $ScratchRoot) { $ScratchRoot = Join-Path $repo 'scratch/falsify-0044' }
if (@($ScratchRoot -split '[\\/]') -notcontains 'scratch') {
    throw "Refusing to write outside scratch/: $ScratchRoot"
}

if (Test-Path -LiteralPath $ScratchRoot) { Remove-Item -LiteralPath $ScratchRoot -Recurse -Force }
$null = New-Item -ItemType Directory -Path $ScratchRoot -Force

function New-Fixture {
    <#
        A fixture is a minimal module repository, not a bare directory holding a
        workspace file. It has to be: Pester 6 treats an empty -ForEach as a
        discovery error that fails the whole file, and the suite's existing
        assertions iterate the exported surface. A directory with no manifest
        therefore never reaches this assertion at all - which is exactly the
        false ZERO CASES the first run of this script reported.
    #>
    param(
        [Parameter(Mandatory)][string] $Name,
        [string] $Content
    )
    $dir = Join-Path $ScratchRoot $Name
    $null = New-Item -ItemType Directory -Path (Join-Path $dir 'Public') -Force

    if ($Content) {
        Set-Content -LiteralPath (Join-Path $dir "$Name.code-workspace") -Value $Content -Encoding utf8
    }

    Set-Content -LiteralPath (Join-Path $dir "$Name.psd1") -Encoding utf8 -Value @"
@{
    RootModule        = '$Name.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '$([guid]::NewGuid())'
    FunctionsToExport = @('Get-FixtureThing')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
"@

    Set-Content -LiteralPath (Join-Path $dir 'Public/Get-FixtureThing.ps1') -Encoding utf8 -Value @'
function Get-FixtureThing {
    <#
        .SYNOPSIS
            Exists so the suite has an exported surface to discover.
    #>
    [CmdletBinding()]
    param()
    'thing'
}
'@

    return $dir
}

function Invoke-WorkspaceAssertion {
    <#
        Runs ONLY the 'Workspace composition' block against one target and
        returns its counts. Filtered by name rather than by tag so that a
        failure elsewhere in the suite cannot be mistaken for this assertion.
    #>
    param([Parameter(Mandatory)][string] $Target)

    $previous = $env:CONFORMANCE_TARGET
    $env:CONFORMANCE_TARGET = $Target
    try {
        $cfg = New-PesterConfiguration
        $cfg.Run.Path = $suite
        $cfg.Run.PassThru = $true
        $cfg.Filter.FullName = '*Workspace composition*'
        $cfg.Output.Verbosity = 'None'
        $r = Invoke-Pester -Configuration $cfg

        # A failed container is discovery blowing up, and it must never be
        # reported as ZERO CASES. The first version of this script did exactly
        # that: all four rows came back ZERO CASES while the real cause was an
        # unrelated assertion's empty -ForEach failing discovery for the whole
        # file. A driver that cannot tell "inapplicable" from "the suite did not
        # run" can report a green that means nothing.
        $broken = @($r.Containers | Where-Object { $_.Result -ne 'Passed' -and $_.ErrorRecord })
        if ($broken.Count) {
            return [pscustomobject]@{
                Passed  = 0; Failed = 0; Total = 0
                Verdict = 'DISCOVERY FAILED'
                Detail  = [string]$broken[0].ErrorRecord
            }
        }

        return [pscustomobject]@{
            Passed  = $r.PassedCount
            Failed  = $r.FailedCount
            Total   = $r.TotalCount
            Detail  = ''
            Verdict = if ($r.FailedCount -gt 0) { 'RED' }
                      elseif ($r.PassedCount -gt 0) { 'GREEN' }
                      else { 'ZERO CASES' }
        }
    }
    finally {
        $env:CONFORMANCE_TARGET = $previous
    }
}

# ------------------------------------------------------------------ fixtures

$break = New-Fixture -Name 'break' -Content @'
{
	"folders": [
		{ "path": "." },
		{ "path": "../PSModuleGraph" }
	],
	"settings": {}
}
'@

$restore = New-Fixture -Name 'restore' -Content @'
{
	"folders": [
		{ "path": "." },
		{ "path": "../PSGraphRender" }
	],
	"settings": {}
}
'@

$scope = New-Fixture -Name 'scope' -Content @'
{
	// PSModuleGraph is the read-only reference and is deliberately NOT
	// registered here. This comment mentions it on purpose.
	"folders": [
		{ "path": "." },
		{ "path": "../PSGraphRender" }
	],
	"settings": {
		"conformance.referenceNote": "PSModuleGraph lives under scratch/"
	}
}
'@

$segment = New-Fixture -Name 'segment' -Content @'
{
	"folders": [
		{ "path": "." },
		{ "path": "../PSModuleGraphTools" }
	],
	"settings": {}
}
'@

# ------------------------------------------------------------------ protocol

$none = New-Fixture -Name 'none'

$rows = @(
    @{ Id = '18a'; Name = 'break: registers ../PSModuleGraph'; Target = $break; Expect = 'RED' }
    @{ Id = '18b'; Name = 'restore: folder removed'; Target = $restore; Expect = 'GREEN' }
    @{ Id = '18c'; Name = 'CONTROL scope: named in a comment and a setting, not registered'; Target = $scope; Expect = 'GREEN' }
    @{ Id = '18d'; Name = 'CONTROL segment: registers ../PSModuleGraphTools'; Target = $segment; Expect = 'GREEN' }
    @{ Id = '18e'; Name = 'CONTROL absence: no workspace file at all - inapplicable, not a pass'; Target = $none; Expect = 'ZERO CASES' }
)

Write-Host ''
Write-Host 'FALSIFICATION 0044 - Workspace composition'
Write-Host ''

$bad = 0
$results = foreach ($row in $rows) {
    $r = Invoke-WorkspaceAssertion -Target $row.Target
    $ok = ($r.Verdict -eq $row.Expect)
    if (-not $ok) { $bad++ }
    $mark = if ($ok) { 'OK  ' } else { 'WRONG' }
    Write-Host ("  {0} {1}  expected {2,-5} observed {3,-10} (passed {4}, failed {5}) - {6}" -f `
            $mark, $row.Id, $row.Expect, $r.Verdict, $r.Passed, $r.Failed, $row.Name)
    [pscustomobject]@{
        Row = $row.Id; Expected = $row.Expect; Observed = $r.Verdict
        Passed = $r.Passed; Failed = $r.Failed; Correct = $ok; Name = $row.Name
    }
}

Write-Host ''
if (-not $KeepFixtures) { Remove-Item -LiteralPath $ScratchRoot -Recurse -Force }

if ($bad -gt 0) {
    Write-Host ("FALSIFICATION 0044: {0} row(s) did not behave as required." -f $bad)
    $results | Format-Table -AutoSize | Out-String | Write-Host
    exit $bad
}
Write-Host 'FALSIFICATION 0044: all 5 rows correct - the assertion fires on its break, and both controls hold.'
exit 0
