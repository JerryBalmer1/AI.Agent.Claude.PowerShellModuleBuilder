#Requires -Version 7.2
<#
    Falsification harness for evals/conformance/Help.Tests.ps1.

    Every row perturbs a known-good fixture, re-runs the assertions, and checks
    ONE named case. A BREAK row must turn that case red; a CONTROL row must
    leave it green.

    Three guards, all of which exist because their absence has produced a false
    clean run in this project before:

      1. Every expected case name is preflighted against the cases the suite
         actually produces, and an unresolved name is a hard stop. A renamed
         assertion otherwise reports as "does not fire", which is the alarming
         answer nobody double-checks.
      2. Every perturbation asserts it changed the file. A substitution that
         matches nothing leaves the target intact and the run comes back green.
      3. Known-good is re-asserted from a freshly materialised fixture before
         every row, rather than restored and assumed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Harness,
    [Parameter(Mandatory)] [string] $WorkDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fixtureScript = Join-Path $PSScriptRoot 'New-HelpFixture.ps1'
$suite = Join-Path $Harness 'evals/conformance/Help.Tests.ps1'
$fixture = Join-Path $WorkDir 'fx'

function Reset-Fixture {
    & $fixtureScript -Path $fixture *>$null
}

function Get-CaseResult {
    $env:CONFORMANCE_TARGET = $fixture
    $env:CONFORMANCE_MODULE_NAME = 'PSHelpFixture'
    $config = New-PesterConfiguration
    $config.Run.Path = $suite
    $config.Run.PassThru = $true
    $config.Run.Throw = $false
    $config.Filter.Tag = 'HouseStyle'
    $config.Run.FailOnNullOrEmptyForEach = $false
    $config.Output.Verbosity = 'None'
    $result = Invoke-Pester -Configuration $config

    $map = @{}
    foreach ($test in $result.Tests) {
        if ($test.Result -eq 'NotRun') { continue }
        $map[($test.ExpandedPath)] = [pscustomobject]@{
            Passed  = ($test.Result -eq 'Passed')
            Message = if ($test.ErrorRecord) { ($test.ErrorRecord.Exception.Message -split "`n")[0] } else { '' }
        }
    }
    $map
}

function Edit-File {
    param(
        [Parameter(Mandatory)] [string] $RelativePath,
        [Parameter(Mandatory)] [scriptblock] $Transform
    )
    $full = Join-Path $fixture $RelativePath
    $before = [System.IO.File]::ReadAllText($full)
    $after = & $Transform $before
    if ($after -eq $before) {
        throw "Perturbation of '$RelativePath' changed nothing. A probe that does not perturb reports 'does not fire' and proves nothing."
    }
    [System.IO.File]::WriteAllText($full, $after)
}

Import-Module Pester -MinimumVersion 6.0.0 -MaximumVersion 6.99 -Force

$describe = 'House style: help'
$rows = @(
    @{ Id = 'H1'; Kind = 'BREAK'
       Case = "$describe.gives Get-FixtureThing at least as many examples as parameter sets"
       Note = 'strip one example from a two-set function'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Public/Get-FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)\r?\n\s*\.EXAMPLE\r?\n\s*\$Path = "C:/things".*?(?=\r?\n\s*#>)', '' } } }

    @{ Id = 'H2'; Kind = 'BREAK'
       Case = "$describe.shows every named parameter set of Get-FixtureThing in an example"
       Note = 'same strip; the failure must NAME the uncovered set'
       Expect = 'ByPath'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Public/Get-FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)\r?\n\s*\.EXAMPLE\r?\n\s*\$Path = "C:/things".*?(?=\r?\n\s*#>)', '' } } }

    @{ Id = 'H3'; Kind = 'CONTROL'
       Case = "$describe.gives Set-FixtureThing at least as many examples as parameter sets"
       Note = 'single-set function with one example, while the two-set function is broken'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Public/Get-FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)\r?\n\s*\.EXAMPLE\r?\n\s*\$Path = "C:/things".*?(?=\r?\n\s*#>)', '' } } }

    @{ Id = 'H4'; Kind = 'BREAK'
       Case = "$describe.gives every parameter of Get-FixtureThing a .PARAMETER entry"
       Note = 'remove one .PARAMETER entry; the failure must NAME the parameter'
       Expect = 'Detailed'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Public/Get-FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)\r?\n\s*\.PARAMETER Detailed\r?\n[^\r\n]*\r?\n', "`n" } } }

    @{ Id = 'H5'; Kind = 'CONTROL'
       Case = "$describe.gives every parameter of Get-FixtureThing a .PARAMETER entry"
       Note = 'SCOPE: an unattached comment block quoting help keywords, real help left intact'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Public/Get-FixtureThing.ps1' -Transform {
                param($t) $t + "`n<#`n    .SYNOPSIS`n        Not help - attached to nothing.`n    .PARAMETER Detailed`n        Nor this.`n    .EXAMPLE`n        Nor this.`n#>`n" } } }

    @{ Id = 'H6'; Kind = 'BREAK'
       Case = "$describe.gives Resolve-FixturePath comment-based help with a synopsis"
       Note = 'SUBSTITUTION: delete the real help, leave a detached block that still says .SYNOPSIS'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Private/Resolve-FixturePath.ps1' -Transform {
                param($t)
                "<#`n    .SYNOPSIS`n        Detached on purpose - a statement stands between this and the function.`n#>`n" +
                "`$script:NotHelp = 1`n`n" +
                ($t -replace '(?ms)\r?\n\s*<#\s*\r?\n\s*\.SYNOPSIS.*?#>\r?\n', "`n") } } }

    @{ Id = 'H7'; Kind = 'BREAK'
       Case = "$describe.precedes class FixtureThing with a doc comment block"
       Note = 'remove the block above the class'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Types/FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)\A<#.*?#>\r?\n', '' } } }

    @{ Id = 'H8'; Kind = 'CONTROL'
       Case = "$describe.precedes class FixtureThing with a doc comment block"
       Note = 'SCOPE: remove the block above the ENUM instead; the class case must stay green'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Types/FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)<#\s*\r?\n\s*What state a fixture thing is in\..*?#>\r?\n', '' } } }

    @{ Id = 'H9'; Kind = 'BREAK'
       Case = "$describe.ships about_PSHelpFixture when the module defines types"
       Note = 'delete the about_ topic from a module that defines types'
       Do = { $p = Join-Path $fixture 'src/PSHelpFixture/en-US/about_PSHelpFixture.help.txt'
              if (-not (Test-Path -LiteralPath $p)) { throw 'nothing to delete' }
              Remove-Item -LiteralPath $p -Force } }

    @{ Id = 'H10'; Kind = 'CONTROL'
       Case = "$describe.ships about_PSHelpFixture when the module defines types"
       Note = 'SCOPE: delete a DIFFERENT about_ topic in the same culture directory'
       Do = { $d = Join-Path $fixture 'src/PSHelpFixture/en-US'
              Set-Content -LiteralPath (Join-Path $d 'about_Other.help.txt') -Value 'decoy'
              Remove-Item -LiteralPath (Join-Path $d 'about_Other.help.txt') -Force
              # The decoy is created and removed so the row perturbs and restores
              # in one step; the assertion must be indifferent to both.
              $p = Join-Path $d 'about_PSHelpFixture.help.txt'
              [System.IO.File]::WriteAllText($p, [System.IO.File]::ReadAllText($p) + "`nstill here`n") } }

    @{ Id = 'H11'; Kind = 'BREAK'
       Case = "$describe.gives Set-FixtureThing a help description"
       Note = 'strip .DESCRIPTION from a function whose synopsis and example remain'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Public/Set-FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)\r?\n\s*\.DESCRIPTION\r?\n.*?(?=\r?\n\s*\.PARAMETER)', '' } } }

    @{ Id = 'H12'; Kind = 'CONTROL'
       Case = "$describe.gives Get-FixtureThing a help description"
       Note = 'SCOPE: the same strip, watched on the OTHER function'
       Do = { Edit-File -RelativePath 'src/PSHelpFixture/Public/Set-FixtureThing.ps1' -Transform {
                param($t) $t -replace '(?ms)\r?\n\s*\.DESCRIPTION\r?\n.*?(?=\r?\n\s*\.PARAMETER)', '' } } }
)

Reset-Fixture
$baseline = Get-CaseResult
$baselineFailed = @($baseline.GetEnumerator() | Where-Object { -not $_.Value.Passed })
Write-Host "KNOWN-GOOD: $($baseline.Count) cases, $($baselineFailed.Count) failing"
if ($baselineFailed.Count -ne 0) {
    throw ("The fixture is not green, so no row is attributable. Failing: " +
        (($baselineFailed | ForEach-Object { $_.Key }) -join '; '))
}

# Guard 1. Preflight every expected case name against what the suite produces.
foreach ($row in $rows) {
    if (-not $baseline.ContainsKey($row.Case)) {
        throw ("$($row.Id) names a case the suite does not produce: '$($row.Case)'. " +
            'An assertion renamed by a repair invalidates every row naming it, and the row would ' +
            'report "does not fire" - the exact false signal this protocol exists to detect.')
    }
}
Write-Host "PREFLIGHT: $($rows.Count) / $($rows.Count) case names resolve"
Write-Host ''

$results = foreach ($row in $rows) {
    Reset-Fixture
    $check = Get-CaseResult
    if (@($check.GetEnumerator() | Where-Object { -not $_.Value.Passed }).Count -ne 0) {
        throw "$($row.Id): known-good is not green before the row ran."
    }

    & $row.Do
    $after = Get-CaseResult

    $fired = -not $after[$row.Case].Passed
    $expected = $row.Kind -eq 'BREAK'
    $named = if ($row.ContainsKey('Expect')) {
        $after[$row.Case].Message -match [regex]::Escape($row.Expect)
    }
    else { $true }

    $collateral = @($after.GetEnumerator() |
            Where-Object { -not $_.Value.Passed -and $_.Key -ne $row.Case } |
            ForEach-Object { $_.Key -replace [regex]::Escape("$describe."), '' })

    [pscustomobject]@{
        Id         = $row.Id
        Kind       = $row.Kind
        Fired      = $fired
        Expected   = $expected
        Named      = $named
        Pass       = ($fired -eq $expected) -and $named
        Collateral = $collateral.Count
        Note       = $row.Note
    }
}

$results | Format-Table Id, Kind, Fired, Expected, Named, Pass, Collateral, Note -AutoSize -Wrap
$breaks = @($results | Where-Object Kind -eq 'BREAK')
$controls = @($results | Where-Object Kind -eq 'CONTROL')
Write-Host ''
Write-Host ("BREAKS: {0} / {1} red" -f @($breaks | Where-Object Pass).Count, $breaks.Count)
Write-Host ("CONTROLS: {0} / {1} green" -f @($controls | Where-Object Pass).Count, $controls.Count)
Reset-Fixture
