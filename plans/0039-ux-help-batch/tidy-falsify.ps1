#Requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Harness,
    [Parameter(Mandatory)] [string] $Reference,
    [Parameter(Mandatory)] [string] $WorkDir
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Test-Path -LiteralPath $WorkDir) { Remove-Item -LiteralPath $WorkDir -Recurse -Force }
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

$clone = Join-Path $WorkDir 'ref'
git clone --quiet -- $Reference $clone
if ($LASTEXITCODE -ne 0) { throw 'clone failed' }

$tidy = Join-Path $Harness 'skills/powershell-module-tidy/scripts/Invoke-ModuleTidy.ps1'
$report = Join-Path $WorkDir 'r.json'

function Get-Rules {
    & $tidy -Path $clone -Check Naming, Parity, DeadFile -ReportPath $report -NoExitCode *>$null
    @((Get-Content -LiteralPath $report -Raw | ConvertFrom-Json).Findings | ForEach-Object { $_.Rule })
}

$baseline = @(Get-Rules)   # @() at the CALL SITE: a function returning an empty array unrolls to $null
Write-Host "BASELINE rules: $(if ($baseline.Count) { $baseline -join ',' } else { '(none)' })"
if ($baseline.Count -ne 0) { throw "Known-good is not clean; falsification rows would be unattributable. Got: $($baseline -join ',')" }

$rows = @(
    @{ Id = 'T1'; Kind = 'BREAK'; Rule = 'test-file-discoverable'
       Do = { Set-Content -LiteralPath (Join-Path $clone 'tests/Sneaky.ps1') -Value "Describe 'x' { It 'y' { 1 | Should -Be 1 } }" }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'tests/Sneaky.ps1') -Force } }

    @{ Id = 'T2'; Kind = 'CONTROL'; Rule = 'test-file-discoverable'
       Do = { Set-Content -LiteralPath (Join-Path $clone 'tests/Sneaky.ps1') -Value "# Describe 'x' { It 'y' { } }`n'not a test'" }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'tests/Sneaky.ps1') -Force } }

    @{ Id = 'T3'; Kind = 'BREAK'; Rule = 'approved-verb-noun'
       Do = { Copy-Item (Join-Path $clone 'src/PSModuleGraph/Private/Get-HashtableValue.ps1') `
                        (Join-Path $clone 'src/PSModuleGraph/Private/Frobnicate-Thing.ps1') }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/Frobnicate-Thing.ps1') -Force } }

    @{ Id = 'T4'; Kind = 'CONTROL'; Rule = 'approved-verb-noun'
       Do = { Copy-Item (Join-Path $clone 'src/PSModuleGraph/Private/Get-HashtableValue.ps1') `
                        (Join-Path $clone 'src/PSModuleGraph/Private/Resolve-Thing.ps1') }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/Resolve-Thing.ps1') -Force } }

    @{ Id = 'T5'; Kind = 'BREAK'; Rule = 'documented-unexported'
       Do = { Add-Content -LiteralPath (Join-Path $clone 'README.md') -Value "`nUse ``Get-PSModuleNonexistentThing`` to do the thing." }
       Undo = { git -C $clone checkout -- README.md } }

    @{ Id = 'T6'; Kind = 'CONTROL'; Rule = 'documented-unexported'
       Do = { Add-Content -LiteralPath (Join-Path $clone 'docs/improvements.md') -Value "`nInternally ``Get-PSModuleNonexistentThing`` would help." }
       Undo = { git -C $clone checkout -- docs/improvements.md } }

    @{ Id = 'T7'; Kind = 'BREAK'; Rule = 'exported-undocumented'
       Do = {
            $p = Join-Path $clone 'src/PSModuleGraph/PSModuleGraph.psd1'
            (Get-Content -LiteralPath $p -Raw) -replace "'Get-PSModuleFunction'", "'Get-PSModuleFunction', 'Get-PSModuleUndocumented'" |
                Set-Content -LiteralPath $p -NoNewline
       }
       Undo = { git -C $clone checkout -- src/PSModuleGraph/PSModuleGraph.psd1 } }

    @{ Id = 'T8'; Kind = 'BREAK'; Rule = 'unreferenced-private-function'
       Do = { Set-Content -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/Get-OrphanThing.ps1') `
                          -Value "function Get-OrphanThing { 'nobody calls me' }" }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/Get-OrphanThing.ps1') -Force } }

    @{ Id = 'T9'; Kind = 'CONTROL'; Rule = 'unreferenced-private-function'
       Do = { Set-Content -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/Get-OrphanThing.ps1') `
                          -Value "function Get-OrphanThing { 'x' }`nfunction Use-OrphanThing { Get-OrphanThing }`nUse-OrphanThing" }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/Get-OrphanThing.ps1') -Force } }

    @{ Id = 'T10'; Kind = 'CONTROL'; Rule = 'no-space-in-filename'
       Do = { New-Item -ItemType File -Path (Join-Path $clone 'tests/fixtures/data file.txt') -Force | Out-Null }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'tests/fixtures/data file.txt') -Force } }

    @{ Id = 'T11'; Kind = 'BREAK'; Rule = 'no-space-in-filename'
       Do = { New-Item -ItemType File -Path (Join-Path $clone 'tests/fixtures/data file.ps1') -Force | Out-Null }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'tests/fixtures/data file.ps1') -Force } }

    @{ Id = 'T12'; Kind = 'CONTROL'; Rule = 'pascalcase-directory'
       Do = { New-Item -ItemType Directory -Path (Join-Path $clone 'src/PSModuleGraph/fr-FR') -Force | Out-Null
              Set-Content -LiteralPath (Join-Path $clone 'src/PSModuleGraph/fr-FR/about_PSModuleGraph.help.txt') -Value 'x' }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'src/PSModuleGraph/fr-FR') -Recurse -Force } }

    @{ Id = 'T13'; Kind = 'BREAK'; Rule = 'pascalcase-directory'
       Do = { New-Item -ItemType Directory -Path (Join-Path $clone 'src/PSModuleGraph/Private/helpers') -Force | Out-Null
              Set-Content -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/helpers/Get-Thing.ps1') -Value '# no function here, so this row perturbs one rule and not two' }
       Undo = { Remove-Item -LiteralPath (Join-Path $clone 'src/PSModuleGraph/Private/helpers') -Recurse -Force } }
)

$results = foreach ($row in $rows) {
    $before = @(Get-ChildItem -LiteralPath $clone -Recurse -Force -File | Measure-Object).Count
    & $row.Do
    $after = @(Get-ChildItem -LiteralPath $clone -Recurse -Force -File | Measure-Object).Count
    $dirty = (git -C $clone status --porcelain) -join ''
    if ($before -eq $after -and -not $dirty) { throw "$($row.Id): perturbation changed nothing. A row that does not perturb reports 'does not fire' and proves nothing." }

    $rules = @(Get-Rules)
    $fired = $rules -contains $row.Rule

    & $row.Undo
    $restored = @(Get-Rules)
    if ($restored.Count -ne 0) { throw "$($row.Id): restore left the tree dirty. Rules still firing: $($restored -join ',')" }

    $expected = $row.Kind -eq 'BREAK'
    [pscustomobject]@{
        Id = $row.Id; Kind = $row.Kind; Rule = $row.Rule
        Fired = $fired; Expected = $expected; Pass = ($fired -eq $expected)
        Collateral = @($rules | Where-Object { $_ -ne $row.Rule } | Sort-Object -Unique) -join ','
    }
}

$results | Format-Table -AutoSize
$breaks = @($results | Where-Object Kind -eq 'BREAK')
$controls = @($results | Where-Object Kind -eq 'CONTROL')
Write-Host ''
Write-Host ("BREAKS: {0} / {1} red" -f @($breaks | Where-Object Pass).Count, $breaks.Count)
Write-Host ("CONTROLS: {0} / {1} green" -f @($controls | Where-Object Pass).Count, $controls.Count)
$results
