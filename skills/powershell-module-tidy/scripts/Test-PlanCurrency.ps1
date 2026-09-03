#Requires -Version 7.2
<#
.SYNOPSIS
    Decide whether docs/PLAN.md is newer than the work it describes.
.DESCRIPTION
    The mechanical half of the master-plan obligation. `powershell-module-plan`
    says every module carries docs/PLAN.md and that it is always current;
    `powershell-module-tidy` blocks a release when it is not. This script is
    what "not" means, so that the answer is a command rather than an opinion.

    Stale is defined as: the newest commit touching $SourcePath is newer than
    the newest commit touching docs/PLAN.md. Both SHAs and both dates are
    printed, so a disagreement can be argued rather than merely disbelieved.

    Deliberately blunt. A typo fix under src/ does not really invalidate a
    plan, and this will say it does. The intended response is to touch the plan
    with a line saying the work landed - which is the behaviour the rule exists
    to produce. There is no exemption list on purpose: an exemption list is how
    a check stops firing.

    Reads git. Writes nothing.
.PARAMETER Path
    Repository root.
.PARAMETER PlanPath
    The plan, relative to Path. Default docs/PLAN.md.
.PARAMETER SourcePath
    The tree whose changes stale the plan, relative to Path. Default src.
.EXAMPLE
    $params = @{
        Path       = 'C:/repos/PSModuleGraph'
        PlanPath   = 'docs/PLAN.md'
        SourcePath = 'src'
    }

    $planCurrency = try {
        ./Test-PlanCurrency.ps1 @params
    }
    catch {
        Write-Error "Could not determine plan currency: $_"
        $null
    }

    $planCurrency.IsCurrent
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Path,

    [string] $PlanPath = 'docs/PLAN.md',

    [string] $SourcePath = 'src'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $Path).Path

if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    throw "Not a git repository: '$root'. Plan currency is a claim about commit order and cannot be answered without one."
}

function Get-NewestCommit {
    param([string] $Spec)

    # -1 for the newest, --format for the two fields, -- to end options so a
    # path that looks like a revision is not treated as one.
    $line = & git -C $root log -1 --format='%H%x09%cI' -- $Spec 2>$null
    if ($LASTEXITCODE -ne 0) { throw "git log failed for '$Spec'." }
    if (-not $line) { return $null }

    $parts = $line -split "`t"
    [pscustomobject]@{
        Sha  = $parts[0]
        Date = [datetimeoffset]::Parse($parts[1])
    }
}

$planFull = Join-Path $root $PlanPath
$planExists = Test-Path -LiteralPath $planFull

$plan = if ($planExists) { Get-NewestCommit -Spec $PlanPath } else { $null }
$source = Get-NewestCommit -Spec $SourcePath

# Four outcomes, and only one of them is "current". They are separated because
# "there is no plan" and "the plan is behind" need different fixes, and a single
# boolean would send both to the same one.
$reason, $isCurrent = switch ($true) {
    (-not $planExists) {
        "MISSING: '$PlanPath' does not exist. Every module carries one.", $false
        break
    }
    ($null -eq $plan) {
        "UNTRACKED: '$PlanPath' exists but has never been committed, so its currency cannot be established.", $false
        break
    }
    ($null -eq $source) {
        "NO SOURCE HISTORY: nothing under '$SourcePath' has ever been committed. Nothing can have staled the plan.", $true
        break
    }
    ($source.Date -gt $plan.Date) {
        ("STALE: '$SourcePath' moved at $($source.Date.ToString('u')) ($($source.Sha.Substring(0,7))), " +
            "'$PlanPath' last moved at $($plan.Date.ToString('u')) ($($plan.Sha.Substring(0,7)))."), $false
        break
    }
    default {
        ("CURRENT: '$PlanPath' at $($plan.Date.ToString('u')) ($($plan.Sha.Substring(0,7))) is not behind " +
            "'$SourcePath' at $($source.Date.ToString('u'))."), $true
    }
}

Write-Host $reason

[pscustomobject]@{
    Check      = 'PlanCurrency'
    IsCurrent  = $isCurrent
    Reason     = $reason
    PlanPath   = $PlanPath
    PlanSha    = if ($plan) { $plan.Sha } else { $null }
    PlanDate   = if ($plan) { $plan.Date } else { $null }
    SourcePath = $SourcePath
    SourceSha  = if ($source) { $source.Sha } else { $null }
    SourceDate = if ($source) { $source.Date } else { $null }
}
