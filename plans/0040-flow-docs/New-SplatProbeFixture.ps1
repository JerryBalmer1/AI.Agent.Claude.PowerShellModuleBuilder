#Requires -Version 7.2
<#
.SYNOPSIS
    A minimal two-parameterset module whose examples follow the house splat
    standard exactly, with the dash form appearing nowhere.
.DESCRIPTION
    The probe for LEDGER 47. Built to the CONVENTION and then run against the
    CHECK, which is the whole point of item 47: a rule and its assertion are
    proved to agree by running one against the other, never by reading them
    side by side.
.PARAMETER Path
    Where to write the fixture.
#>
[CmdletBinding()]
param([Parameter(Mandatory)] [string] $Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
$module = 'PSSplatProbe'
$root = Join-Path $Path "src/$module"
New-Item -ItemType Directory -Path (Join-Path $root 'Public') -Force | Out-Null

Set-Content -LiteralPath (Join-Path $root "$module.psd1") -Encoding utf8 -Value @'
@{
    RootModule        = 'PSSplatProbe.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '7c9a1b32-0d54-4e6a-9b18-2f7c4d5e6a71'
    Author            = 'probe'
    FunctionsToExport = @('Get-ProbeThing')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
'@

Set-Content -LiteralPath (Join-Path $root 'Public/Get-ProbeThing.ps1') -Encoding utf8 -Value @'
function Get-ProbeThing {
    <#
    .SYNOPSIS
        A probe thing, by name or by path.
    .DESCRIPTION
        Two named parameter sets. Both examples are written to the house
        .EXAMPLE standard: values assigned at the top with aligned equals,
        splatted through a $params hashtable, wrapped in try/catch with a real
        message, and the result assigned and displayed. The dash form of a
        parameter appears nowhere in this file.
    .PARAMETER Name
        The thing's name. Discriminates the ByName set.
    .PARAMETER Path
        A directory to read things from. Discriminates the ByPath set.
    .EXAMPLE
        $Name = "widget"

        $thing = try {

            $params = @{
                Name = $Name
            }

            Get-ProbeThing @params

        }
        catch {
            Write-Error "Could not read the thing: $_"
            $null
        }

        $thing
    .EXAMPLE
        $Path = "C:/things"

        $things = try {

            $params = @{
                Path = $Path
            }

            Get-ProbeThing @params

        }
        catch {
            Write-Error "Could not read from the path: $_"
            @()
        }

        $things
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByName', HelpMessage = 'The thing to fetch.')]
        [string] $Name,

        [Parameter(Mandatory, ParameterSetName = 'ByPath', HelpMessage = 'Directory holding the things.')]
        [string] $Path
    )
    "$($PSCmdlet.ParameterSetName)"
}
'@

Write-Host "probe fixture at $Path"
