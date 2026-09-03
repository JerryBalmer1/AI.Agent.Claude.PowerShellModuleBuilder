#Requires -Version 7.2
<#
.SYNOPSIS
    Materialise a minimal module that passes every assertion in Help.Tests.ps1.
.DESCRIPTION
    The falsification target. The reference implementation cannot serve as one
    for these assertions: it predates them and fails 219 of their cases, so a
    break against it is unobservable - the case was already red.

    Everything here exists to be broken. It is deliberately the smallest tree
    that is green on all eight assertions: two public functions (one with two
    parameter sets, one with one), a private function, a class, an enum, and an
    about_ topic.
.PARAMETER Path
    Where to write the fixture. Created; must not already hold one.
#>
[CmdletBinding()]
param([Parameter(Mandatory)] [string] $Path)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
$module = 'PSHelpFixture'
$root = Join-Path $Path "src/$module"
New-Item -ItemType Directory -Path (Join-Path $root 'Public') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'Private') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'Types') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $root 'en-US') -Force | Out-Null

Set-Content -LiteralPath (Join-Path $root "$module.psd1") -Encoding utf8 -Value @'
@{
    RootModule        = 'PSHelpFixture.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '2f1d6a4e-6b7c-4a51-9f2e-8c3b5d7e1a90'
    Author            = 'fixture'
    FunctionsToExport = @('Get-FixtureThing', 'Set-FixtureThing')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
'@

# Two parameter sets, two examples, one per set. This is the function the
# example/set rows are aimed at.
Set-Content -LiteralPath (Join-Path $root 'Public/Get-FixtureThing.ps1') -Encoding utf8 -Value @'
function Get-FixtureThing {
    <#
    .SYNOPSIS
        The fixture things, by name or by path.
    .DESCRIPTION
        Two parameter sets, because that is what the set-coverage assertion is
        for. Each set has one example, and each example names the parameter
        that discriminates its set.
    .PARAMETER Name
        The thing's name. Discriminates the ByName set.
    .PARAMETER Path
        A directory to read things from. Discriminates the ByPath set.
    .PARAMETER Detailed
        Include the slow fields. Belongs to both sets.
    .EXAMPLE
        $Name     = "widget"
        $Detailed = $true

        $thing = try {

            $params = @{
                Name     = $Name
                Detailed = $Detailed
            }

            Get-FixtureThing @params

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

            Get-FixtureThing @params

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
        [string] $Path,

        [Parameter(ParameterSetName = 'ByName')]
        [Parameter(ParameterSetName = 'ByPath')]
        [switch] $Detailed
    )
    "$($PSCmdlet.ParameterSetName)"
}
'@

# One parameter set, one example. The green control for "examples >= sets".
Set-Content -LiteralPath (Join-Path $root 'Public/Set-FixtureThing.ps1') -Encoding utf8 -Value @'
function Set-FixtureThing {
    <#
    .SYNOPSIS
        Writes one fixture thing.
    .DESCRIPTION
        A single parameter set with a single example - the shape the
        examples-versus-sets assertion must NOT fire on.
    .PARAMETER Name
        The thing to write.
    .EXAMPLE
        $Name = "widget"

        $written = try {

            $params = @{
                Name = $Name
            }

            Set-FixtureThing @params

        }
        catch {
            Write-Error "Could not write the thing: $_"
            $false
        }

        $written
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = 'The thing to write.')]
        [string] $Name
    )
    $true
}
'@

Set-Content -LiteralPath (Join-Path $root 'Private/Resolve-FixturePath.ps1') -Encoding utf8 -Value @'
function Resolve-FixturePath {
    <#
    .SYNOPSIS
        Normalises a fixture path.
    .DESCRIPTION
        Private, and documented anyway. The audience is the next maintainer
        rather than the next user, and that is the only thing that changes.
    .PARAMETER Path
        The path to normalise.
    .EXAMPLE
        Resolve-FixturePath -Path "C:/things/../things"
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string] $Path)
    $Path
}
'@

Set-Content -LiteralPath (Join-Path $root 'Types/FixtureThing.ps1') -Encoding utf8 -Value @'
<#
    A fixture thing.

    PowerShell classes support no comment-based help, so this block is the only
    documentation a reader of the source will ever get, and the about_ topic is
    the only documentation a USER will ever get. Both are asserted.
#>
class FixtureThing {
    [string] $Name
    [FixtureState] $State
}

<#
    What state a fixture thing is in.

    The value names say what each is called and never say when to choose one,
    which is the only thing a reader needs.
#>
enum FixtureState {
    Pending
    Ready
}
'@

Set-Content -LiteralPath (Join-Path $root "en-US/about_$module.help.txt") -Encoding utf8 -Value @'
TOPIC
    about_PSHelpFixture

SHORT DESCRIPTION
    The fixture module used to falsify the help assertions.

LONG DESCRIPTION
    Types shipped by this module:

    FixtureThing   a thing, with a Name and a State.
    FixtureState   Pending or Ready.
'@

Write-Host "fixture at $Path"
