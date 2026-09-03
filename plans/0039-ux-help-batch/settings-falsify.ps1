param([string]$Harness,[string]$Fixture)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$runner = Join-Path $Harness 'evals/conformance/Invoke-Conformance.ps1'
$file   = Join-Path $Fixture 'psmodule.settings.psd1'
function Clear-Settings { if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force } }
function Invoke-Run {
    & $runner -Path $Fixture -Tag HouseStyle -ModuleName PSHelpFixture -ResultPath (Join-Path $Fixture 'r.json') 6>$null 2>$null |
        Select-Object -Last 1
}

Clear-Settings
Write-Host '--- ROW 1 CONTROL: no settings file, defaults ARE the measured configuration ---'
$r = Invoke-Run
Write-Host ("ABSENT FILE: defaults  CoverageThreshold={0} source={1} IsMeasuredConfiguration={2}" -f
    $r.Settings.Values.CoverageThreshold, $r.Settings.Source.CoverageThreshold, $r.Settings.IsMeasuredConfiguration)

Write-Host ''
Write-Host '--- ROW 2 BREAK: an unknown key must be refused, naming it ---'
Set-Content -LiteralPath $file -Value "@{`n    CoverageThresold = 90`n}"
try { $null = Invoke-Run; Write-Host 'NOT REFUSED (defect): the run produced a score with a key it silently discarded' }
catch { Write-Host ("UNKNOWN KEY: refused  -> " + ($_.Exception.Message -split "`n")[0]) }

Write-Host ''
Write-Host '--- ROW 3 BREAK: a known key must be HONOURED, and its provenance recorded ---'
Set-Content -LiteralPath $file -Value "@{`n    CoverageThreshold = 90`n}"
$r = Invoke-Run
Write-Host ("KNOWN KEY: honoured   CoverageThreshold={0} source={1} IsMeasuredConfiguration={2}" -f
    $r.Settings.Values.CoverageThreshold, $r.Settings.Source.CoverageThreshold, $r.Settings.IsMeasuredConfiguration)

Write-Host ''
Write-Host '--- ROW 4 CONTROL: a NEAR-MISS value on a known key is refused, not coerced ---'
Set-Content -LiteralPath $file -Value "@{`n    CoverageThreshold = '90'`n}"
try { $null = Invoke-Run; Write-Host 'COERCED (defect): a string was accepted where an integer is the contract' }
catch { Write-Host ("INVALID VALUE: refused -> " + ($_.Exception.Message -split "`n")[0]) }

Write-Host ''
Write-Host '--- ROW 5 BREAK: precedence, an explicit parameter beats the file ---'
Set-Content -LiteralPath $file -Value "@{`n    CoverageThreshold = 90`n}"
$r = & $runner -Path $Fixture -Tag HouseStyle -ModuleName PSHelpFixture -ResultPath (Join-Path $Fixture 'r.json') -Setting @{ CoverageThreshold = 60 } 6>$null 2>$null | Select-Object -Last 1
Write-Host ("PARAM > FILE: CoverageThreshold={0} source={1}" -f $r.Settings.Values.CoverageThreshold, $r.Settings.Source.CoverageThreshold)

Write-Host ''
Write-Host '--- ROW 6 CONTROL: an unknown key passed as a PARAMETER is refused on the same terms ---'
Clear-Settings
try { $null = & $runner -Path $Fixture -Tag HouseStyle -ModuleName PSHelpFixture -ResultPath (Join-Path $Fixture 'r.json') -Setting @{ Nonsense = 1 } 6>$null 2>$null; Write-Host 'NOT REFUSED (defect): a caller typo is more acceptable than a user one' }
catch { Write-Host ("UNKNOWN KEY: refused  -> " + ($_.Exception.Message -split "`n")[0]) }
Clear-Settings
