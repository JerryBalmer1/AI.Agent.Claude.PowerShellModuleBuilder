<#
.SYNOPSIS
    Check the five things whose absence makes a first run of this repository
    fail confusingly. Names each missing one on ONE line, with the exact command
    that fixes it.

.DESCRIPTION
    Note what this file deliberately does NOT have: a `#Requires -Version 7.2`
    line. Every other script here has one. A prerequisite checker that refuses
    to run when a prerequisite is missing is useless precisely when it is
    needed - it would hand a Windows PowerShell 5.1 user the engine's own
    "script cannot be run because it contained a #Requires statement" and never
    reach the line that says which PowerShell to install and how.

    So this script is written to parse and run under Windows PowerShell 5.1 as
    well as pwsh 7.x, and it does the version check itself. That is also what
    makes the version check falsifiable: it is probed by running it under a real
    5.1, not by simulating one.

    One line per failure, each naming the thing and the fix, because the failure
    this script exists to prevent is a newcomer reading a stack trace about a
    missing command and concluding the repository is broken.

.PARAMETER Quiet
    Print only failures. Exit code is unchanged.

.OUTPUTS
    Exit 0 when all five are satisfied; 1 otherwise.

.EXAMPLE
    pwsh -NoProfile -File ./tools/publish/Test-Prerequisites.ps1
#>
[CmdletBinding()]
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'

$problems = New-Object 'System.Collections.Generic.List[string]'
$okLines  = New-Object 'System.Collections.Generic.List[string]'

function Add-Problem { param([string]$Text) $problems.Add($Text) }
function Add-Ok      { param([string]$Text) $okLines.Add($Text) }

# --- 1. PowerShell 7.2 or later -------------------------------------------
$v = $PSVersionTable.PSVersion
if ($v -lt [version]'7.2') {
    Add-Problem "MISSING: PowerShell 7.2 or later - this host is $v. Fix: winget install --id Microsoft.PowerShell --source winget   (then re-run with 'pwsh', not 'powershell')"
} else {
    Add-Ok "PowerShell $v (need 7.2 or later)"
}

# --- 2. Pester -------------------------------------------------------------
# Resolvable AND importable are different claims. A module that lists but will
# not import is the more confusing failure of the two, so both are checked.
$pester = Get-Module -ListAvailable -Name Pester |
    Where-Object { $_.Version -ge [version]'5.0' } |
    Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester) {
    Add-Problem "MISSING: Pester 5.0 or later is not installed. Fix: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force"
} else {
    try {
        Import-Module -Name $pester.Path -Force -ErrorAction Stop
        Add-Ok "Pester $($pester.Version) (imports cleanly)"
    } catch {
        Add-Problem "MISSING: Pester $($pester.Version) is installed but will not import - $($_.Exception.Message). Fix: Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force -AllowClobber"
    }
}

# --- 3. git ----------------------------------------------------------------
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Add-Problem "MISSING: git is not on PATH. Fix: winget install --id Git.Git --source winget   (then open a new shell)"
} else {
    Add-Ok "git at $($git.Source)"
}

# --- 4. InvokeBuild --------------------------------------------------------
$ib = Get-Module -ListAvailable -Name InvokeBuild |
    Sort-Object Version -Descending | Select-Object -First 1
if (-not $ib) {
    Add-Problem "MISSING: InvokeBuild is not installed. Fix: Install-Module InvokeBuild -Scope CurrentUser -Force"
} else {
    Add-Ok "InvokeBuild $($ib.Version)"
}

# --- 5. $env:AZDO_PAT ------------------------------------------------------
# EXISTENCE ONLY. The value is never read, never printed, never measured beyond
# whether it is empty - it is a bearer credential for a whole organisation and
# this script is one a newcomer will paste the output of into an issue.
if ([string]::IsNullOrWhiteSpace($env:AZDO_PAT)) {
    Add-Problem "MISSING: `$env:AZDO_PAT is not set - needed only by the three Azure DevOps skills, not to build a module. Fix: [Environment]::SetEnvironmentVariable('AZDO_PAT','<your-token>','User')   (then open a new shell; scope the token to Code:Read and Build:Read)"
} else {
    Add-Ok "`$env:AZDO_PAT is set (existence checked; value never read)"
}

# --- Report ----------------------------------------------------------------
if (-not $Quiet) {
    Write-Host "Prerequisites for the psmodule plugin"
    Write-Host ""
    foreach ($line in $okLines) { Write-Host "  [ok]      $line" }
}
foreach ($line in $problems) { Write-Host "  $line" }

Write-Host ""
if ($problems.Count -eq 0) {
    Write-Host "ALL PREREQUISITES PRESENT. ($($okLines.Count) of 5 checked, 0 missing.)"
    exit 0
}
Write-Host "$($problems.Count) of 5 prerequisites missing. Each line above names the fix."
exit 1
