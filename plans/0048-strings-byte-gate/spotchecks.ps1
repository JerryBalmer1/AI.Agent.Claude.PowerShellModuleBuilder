#Requires -Version 7.2
<#
    PASS 0048 - Section 4. Spot-checks, each with red capability demonstrated in
    BOTH directions before its first counted result.

    Pass 0043 shipped three checks without that and all three were wrong - two
    would have gone red on good input and one green on bad, so no single
    direction would have found all three.

    SC1 the failure message is diagnosable.
    SC2 the checks are not one check written twice.
    SC3 the expectation is not vacuous.
    SC4 nothing machine-identifying in what this pass commits.

    SC1 and SC2 are read off the task-4 probe record rather than re-run here -
    P1 is SC1's known-bad, the control is its known-good, and P1/P4b are SC2's
    two directions. SC3 and SC4 are run here.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Harness,
    [Parameter(Mandatory)][string] $Target,
    [Parameter(Mandatory)][string] $Work
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$failures = [System.Collections.Generic.List[string]]::new()
function Assert-That {
    param([string] $What, [bool] $Ok, [string] $Detail = '')
    $suffix = ''; if ($Detail) { $suffix = " - $Detail" }
    '    [{0}] {1}{2}' -f $(if ($Ok) { 'ok  ' } else { 'FAIL' }), $What, $suffix
    if (-not $Ok) { $script:failures.Add("$What$suffix") }
}

# The 0043 grep, copied from plans/0047-link-mode/verify.ps1 so the check and
# its red demo run the same code.
function Test-NoMachineIdentity {
    param([string[]] $Files)

    $hits = @()
    foreach ($f in $Files) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        if ([System.IO.Path]::GetExtension($f) -in '.png', '.jpg', '.gif', '.ico') { continue }

        $text = [System.IO.File]::ReadAllText($f)
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -match '(^|[^A-Za-z0-9/])[A-Za-z]:[\\/]{1,2}[A-Za-z_.]' -and
                $line -notmatch 'fixtures[\\/]LinkMode|psgraphrender-|\$env:|TEMP|GetTempPath') {
                $hits += "$([System.IO.Path]::GetFileName($f)): drive path"
            }
            if ($line -match '/(Users|home)/[A-Za-z]') { $hits += "$([System.IO.Path]::GetFileName($f)): home dir" }
            if ($line -match 'jlbal') { $hits += "$([System.IO.Path]::GetFileName($f)): username" }
            # vscode:// carrying a real path, as opposed to the renderer's own
            # prose about what a blocked link looks like.
            if ($line -match 'vscode://file/[A-Za-z]:') { $hits += "$([System.IO.Path]::GetFileName($f)): vscode uri with a real path" }
        }
    }
    @($hits | Sort-Object -Unique)
}

if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force }
New-Item -ItemType Directory -Path $Work -Force | Out-Null

''
'PASS 0048 - SECTION 4: spot-checks, both directions.'
''

# ------------------------------------------------------------------------ SC3
# The expectation is not vacuous. Known-bad: the additions list emptied. The
# assertion must then go RED against the current head - "zero cases is not a
# pass" applies to an expectation as much as to a run.
'SC3 - the expectation is not vacuous.'
$clone = Join-Path $Work 'sc3'
& git clone --quiet --no-hardlinks $Target $clone 2>&1 | Out-Null
& git -C $clone checkout --quiet (& git -C $Target rev-parse HEAD).Trim() 2>&1 | Out-Null
& pwsh -NoProfile -NonInteractive -Command "& '$(Join-Path $clone 'build.ps1')' -Task Build" 2>&1 | Out-Null

$testFile = Join-Path $clone 'tests/LinkMode.Tests.ps1'
$pristineTest = [System.IO.File]::ReadAllText($testFile)

function Invoke-SuiteRow {
    param([string] $Name)
    $jsonPath = Join-Path $Work 'sc3-result.json'
    if (Test-Path -LiteralPath $jsonPath) { Remove-Item -LiteralPath $jsonPath -Force }
    $log = & pwsh -NoProfile -NonInteractive -Command @"
Import-Module Pester -RequiredVersion 6.1.0 -Force
`$cfg = New-PesterConfiguration
`$cfg.Run.Path = '$testFile'
`$cfg.Run.PassThru = `$true
`$cfg.Run.Throw = `$false
`$cfg.Should.DisableV5 = `$true
`$cfg.Output.Verbosity = 'None'
`$r = Invoke-Pester -Configuration `$cfg
@(`$r.Tests | ForEach-Object {
    [pscustomobject]@{ Name = `$_.Name; Result = `$_.Result
        Message = if (`$_.ErrorRecord) { (`$_.ErrorRecord | ForEach-Object { `$_.ToString() }) -join ' ' } else { '' } }
}) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath '$jsonPath'
"@ 2>&1
    if (-not (Test-Path -LiteralPath $jsonPath)) { throw "no suite result: $(($log | Select-Object -Last 5) -join ' / ')" }
    $rows = @(Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json)
    $r = @($rows | Where-Object { $_.Name -eq $Name })
    if ($r.Count -ne 1) { throw "expected one It named '$Name', found $($r.Count)" }
    $r[0]
}

$STRINGS_IT = 'changes STRINGS only by adding the three link strings, and moves no shipped value'

try {
    # Known-good first: as shipped, the expectation names three keys the base
    # genuinely lacks, and the It is green.
    $good = Invoke-SuiteRow -Name $STRINGS_IT
    Assert-That -What 'SC3 known-good: the shipped additions list is GREEN' -Ok ($good.Result -eq 'Passed') -Detail $good.Result

    # Known-bad: empty the list. Head really does add three keys, so an emptied
    # expectation must FAIL rather than pass on nothing.
    $emptied = $pristineTest.Replace(
        "Should-BeCollection @('MenuCopyLink', 'MenuOpenLink', 'ReasonNoTemplate')",
        'Should-BeCollection @()')
    if ($emptied -ceq $pristineTest) { throw 'SC3: the additions list was not found to empty - the check would prove nothing.' }
    [System.IO.File]::WriteAllText($testFile, $emptied)

    $bad = Invoke-SuiteRow -Name $STRINGS_IT
    Assert-That -What 'SC3 known-bad: an EMPTIED additions list goes RED' -Ok ($bad.Result -eq 'Failed') -Detail $bad.Result
    Assert-That -What 'SC3: the message names what actually arrived' `
        -Ok ($bad.Message -match 'MenuCopyLink' -and $bad.Message -match 'MenuOpenLink' -and $bad.Message -match 'ReasonNoTemplate') `
        -Detail ($bad.Message -replace '\s+', ' ')
}
finally {
    [System.IO.File]::WriteAllText($testFile, $pristineTest)
}
''

# ------------------------------------------------------------------------ SC4
'SC4 - nothing machine-identifying in what this pass commits.'

# Everything this pass adds or changes, in both repositories, derived from git
# rather than listed by hand: a hand-list is the one that misses the file.
$harnessFiles = @(& git -C $Harness diff --name-only main...HEAD) + @(& git -C $Harness diff --name-only HEAD) |
    Where-Object { $_ } | Sort-Object -Unique | ForEach-Object { Join-Path $Harness $_ }
$targetFiles = @(& git -C $Target diff --name-only main...HEAD) + @(& git -C $Target diff --name-only HEAD) |
    Where-Object { $_ } | Sort-Object -Unique | ForEach-Object { Join-Path $Target $_ }
$committed = @($harnessFiles + $targetFiles)

'  files this pass touches:'
foreach ($f in $committed) { "    $(Split-Path $f -Leaf)" }

# The detector is exempt from itself, by exact leaf name and nothing wider.
# A check for drive paths, home directories, usernames and vscode:// URIs
# necessarily CONTAINS all four - as a regex and as the planted line its own
# red demo needs - so scanning it reports the check working as the check
# failing. This is the same carve-out shape acceptance B uses for the STRINGS
# block, and it is held to the same standard below: a carve-out nobody proves
# is excluding something real is a carve-out that could be eating the file.
$detectors = @('spotchecks.ps1', 'verify.ps1')
$scanned = @($committed | Where-Object { (Split-Path $_ -Leaf) -notin $detectors })
$excluded = @($committed | Where-Object { (Split-Path $_ -Leaf) -in $detectors })
"  excluded as detectors: $(if ($excluded.Count) { (@($excluded | ForEach-Object { Split-Path $_ -Leaf }) -join ', ') } else { '(none present)' })"

$hits = @(Test-NoMachineIdentity -Files $scanned)
Assert-That -What 'SC4: no machine identity in the pass''s own files' -Ok ($hits.Count -eq 0) `
    -Detail $(if ($hits.Count) { $hits -join '; ' } else { "clean over $($scanned.Count) file(s)" })

# The carve-out excludes something real. Without this, SC4 would pass just as
# happily if $detectors had grown to swallow the whole file list.
if ($excluded.Count) {
    $excludedHits = @(Test-NoMachineIdentity -Files $excluded)
    Assert-That -What 'SC4: the detector carve-out excludes something that really does match' `
        -Ok ($excludedHits.Count -gt 0) -Detail "$($excludedHits.Count) hit(s) inside the excluded detector(s)"
}
Assert-That -What 'SC4: the carve-out is by exact name and leaves the pass''s own files scanned' `
    -Ok ($scanned.Count -gt 0 -and $excluded.Count -lt $committed.Count) `
    -Detail "$($scanned.Count) scanned, $($excluded.Count) excluded, $($committed.Count) touched"

# Red demo, the 0044-era fixture form: the check must fire on a planted line.
$planted = Join-Path $Work 'planted.md'
[System.IO.File]::WriteAllText($planted, @"
a line naming C:\Users\someone\clone\file.ps1 the way a stray paste would
and one carrying vscode://file/C:/Users/someone/repo/src/Thing.ps1:12
"@)
$plantedHits = @(Test-NoMachineIdentity -Files @($planted))
Assert-That -What 'SC4 red demo: a planted drive path and vscode:// URI are caught' -Ok ($plantedHits.Count -gt 0) `
    -Detail "$($plantedHits.Count) hit(s): $($plantedHits -join '; ')"

# Known-good control: a file with neither.
$clean = Join-Path $Work 'clean.md'
[System.IO.File]::WriteAllText($clean, "a line naming tests/LinkMode.Tests.ps1 and nothing else`n")
Assert-That -What 'SC4 known-good: a clean file produces no hit' -Ok (@(Test-NoMachineIdentity -Files @($clean)).Count -eq 0)
''

if ($failures.Count) {
    "SECTION 4: FAIL - $($failures.Count) spot-check(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'SECTION 4: PASS - every spot-check demonstrated red capability in both directions.'
exit 0
