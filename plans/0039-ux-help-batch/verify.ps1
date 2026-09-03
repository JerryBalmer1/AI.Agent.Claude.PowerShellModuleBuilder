#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove plan 0039 without reading it.
.DESCRIPTION
    Assumes nothing but a fresh clone of this repository and the tools. It
    RE-DERIVES rather than reads: it re-runs the falsification harnesses, it
    re-scores the run-006 clone, it re-computes cases-defined against two
    differently shaped targets, and it compares what it gets against the
    committed artifacts. It never parses plan.md.

    Every one of the prompt's five named spot-checks is a numbered check here,
    by name.

    Exits 0 when everything agrees, non-zero otherwise, printing which check
    disagreed and what it expected.

.PARAMETER RepoRoot
    The clone to verify. Defaults to this script's repository.
.PARAMETER WorkDir
    Scratch root. MUST BE SHORT: the run-006 clone and the reference both carry
    paths that exceed MAX_PATH under a long root, and git fails with "Filename
    too long" rather than anything that mentions the length of your temp
    directory. C:/v39 is the default for that reason and no other.
.PARAMETER SkipNetwork
    Skip check 4 and the remote half of check 5, for a machine with no network.
    Reported as SKIPPED, never as passed - the same rule the suite applies to
    zero cases.
.EXAMPLE
    $RepoRoot = 'C:/repos/AI.Agent.Claude.PowerShellModuleBuilder'
    $WorkDir  = 'C:/v39'

    $verification = try {

        $params = @{
            RepoRoot = $RepoRoot
            WorkDir  = $WorkDir
        }

        ./verify.ps1 @params

    }
    catch {
        Write-Error "Verification could not run: $_"
        $null
    }

    $LASTEXITCODE
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
    [string] $WorkDir = 'C:/v39',
    [switch] $SkipNetwork
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$plan = Join-Path $RepoRoot 'plans/0039-ux-help-batch'
$conformance = Join-Path $RepoRoot 'evals/conformance'
$failures = [System.Collections.Generic.List[string]]::new()
$skipped = [System.Collections.Generic.List[string]]::new()

function Test-Check {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [scriptblock] $Body
    )
    Write-Host ''
    Write-Host "=== $Name"
    try {
        $problem = & $Body
        if ($problem) {
            foreach ($line in @($problem)) {
                Write-Host "    DISAGREES: $line"
                $failures.Add("$Name -> $line")
            }
        }
        else { Write-Host '    OK' }
    }
    catch {
        Write-Host "    ERROR: $($_.Exception.Message)"
        $failures.Add("$Name -> threw: $($_.Exception.Message)")
    }
}

if (Test-Path -LiteralPath $WorkDir) { Remove-Item -LiteralPath $WorkDir -Recurse -Force }
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

# ---------------------------------------------------------------------------
# Spot-check 1. Fresh clone: verify regenerates the two-set-example break and
# the scope control itself; red/green as recorded.
# ---------------------------------------------------------------------------
Test-Check -Name 'Spot-check 1: the help falsification re-runs, red/green as recorded' -Body {
    $output = & pwsh -NoProfile -File (Join-Path $plan 'help-falsify.ps1') `
        -Harness $RepoRoot -WorkDir (Join-Path $WorkDir 'h') 2>&1 | Out-String

    $problems = @()
    # The two figures the record commits to.
    if ($output -notmatch 'BREAKS:\s*7\s*/\s*7\s*red') { $problems += 'BREAKS is not 7 / 7 red' }
    if ($output -notmatch 'CONTROLS:\s*5\s*/\s*5\s*green') { $problems += 'CONTROLS is not 5 / 5 green' }
    if ($output -notmatch 'PREFLIGHT:\s*12\s*/\s*12') { $problems += 'preflight did not resolve 12 / 12 case names' }
    if ($output -notmatch 'KNOWN-GOOD:\s*\d+ cases, 0 failing') { $problems += 'the fixture is not green at known-good' }

    # And the two rows the prompt names by name, individually, so that a row
    # flipping while the totals stay put cannot pass this check.
    foreach ($row in 'H1', 'H2') {
        if ($output -notmatch "(?m)^$row\s+BREAK\s+True\s+True\s+True\s+True") {
            $problems += "$row (the two-set example break) did not go red"
        }
    }
    if ($output -notmatch '(?m)^H5\s+CONTROL\s+False\s+False\s+True\s+True') {
        $problems += 'H5 (the unattached comment block, the scope control) did not stay green'
    }

    # Cross-check against what was committed, so a harness edited to agree with
    # itself is still caught.
    $committed = Get-Content -LiteralPath (Join-Path $plan 'help-falsification.txt') -Raw
    if ($committed -notmatch 'BREAKS:\s*7\s*/\s*7\s*red') { $problems += 'help-falsification.txt does not record 7 / 7' }
    if ($committed -notmatch 'CONTROLS:\s*5\s*/\s*5\s*green') { $problems += 'help-falsification.txt does not record 5 / 5' }
    $problems
}

# ---------------------------------------------------------------------------
# Spot-check 2. The settings triple re-fired: unknown refused / known honoured /
# absent defaults.
# ---------------------------------------------------------------------------
Test-Check -Name 'Spot-check 2: the settings triple re-fires' -Body {
    $fixture = Join-Path $WorkDir 's'
    & pwsh -NoProfile -File (Join-Path $plan 'New-HelpFixture.ps1') -Path $fixture *>$null

    $output = & pwsh -NoProfile -File (Join-Path $plan 'settings-falsify.ps1') `
        -Harness $RepoRoot -Fixture $fixture 2>&1 | Out-String

    $problems = @()
    if ($output -notmatch 'ABSENT FILE: defaults\s+CoverageThreshold=75 source=default IsMeasuredConfiguration=True') {
        $problems += 'an absent settings file did not resolve to the measured defaults'
    }
    if ($output -notmatch 'UNKNOWN KEY: refused') { $problems += 'an unknown key was not refused' }
    if ($output -notmatch "CoverageThresold") { $problems += 'the refusal did not name the offending key' }
    if ($output -notmatch 'KNOWN KEY: honoured\s+CoverageThreshold=90 source=file') {
        $problems += 'a known key was not honoured from the file'
    }
    if ($output -notmatch 'PARAM > FILE: CoverageThreshold=60 source=parameter') {
        $problems += 'an explicit parameter did not beat the file'
    }
    if ($output -notmatch 'INVALID VALUE: refused') { $problems += 'a near-miss value was coerced rather than refused' }

    $committed = Get-Content -LiteralPath (Join-Path $plan 'settings-falsification.txt') -Raw
    if ($committed -notmatch 'UNKNOWN KEY: refused') { $problems += 'settings-falsification.txt does not record the refusal' }
    $problems
}

# ---------------------------------------------------------------------------
# Spot-check 3. cases-defined post-figure re-derived and equal to
# denominator-v2.txt across two differently-shaped clones.
# ---------------------------------------------------------------------------
Test-Check -Name 'Spot-check 3: cases-defined is 41 across differently shaped targets' -Body {
    $problems = @()

    $recorded = Get-Content -LiteralPath (Join-Path $plan 'denominator-v2.txt') -Raw
    if ($recorded -notmatch 'cases-defined \(pre\):\s*33') { $problems += 'denominator-v2.txt does not record pre = 33' }
    if ($recorded -notmatch 'cases-defined \(post\):\s*41') { $problems += 'denominator-v2.txt does not record post = 41' }
    if ($recorded -notmatch 'series boundary: v1\.2\.0') { $problems += 'denominator-v2.txt does not carry the series boundary line' }

    # Target A: the help fixture - three functions, two types, no build.
    $a = Join-Path $WorkDir 'd1'
    & pwsh -NoProfile -File (Join-Path $plan 'New-HelpFixture.ps1') -Path $a *>$null

    # Target B: a tree of a deliberately different SHAPE - many more public
    # functions, no types, so that cases-run must differ if cases-defined is
    # doing its job. Built here rather than cloned, so the check needs no
    # network and no second repository.
    $b = Join-Path $WorkDir 'd2'
    $bSrc = Join-Path $b 'src/PSShapeTwo'
    New-Item -ItemType Directory -Path (Join-Path $bSrc 'Public') -Force | Out-Null
    $names = 1..9 | ForEach-Object { "Get-ShapeTwoThing$_" }
    foreach ($name in $names) {
        Set-Content -LiteralPath (Join-Path $bSrc "Public/$name.ps1") -Encoding utf8 -Value @"
function $name {
    <#
    .SYNOPSIS
        One of nine, so this target's cases-run differs from the other's.
    .DESCRIPTION
        Shape, not content: the point is that cases-run moves and
        cases-defined does not.
    .EXAMPLE
        $name
    #>
    [CmdletBinding()] param()
    1
}
"@
    }
    Set-Content -LiteralPath (Join-Path $bSrc 'PSShapeTwo.psd1') -Encoding utf8 -Value @"
@{
    RootModule        = 'PSShapeTwo.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '7a2b91c4-3d5e-4f60-8a71-2c9d4e6f8b13'
    Author            = 'fixture'
    FunctionsToExport = @($(($names | ForEach-Object { "'$_'" }) -join ', '))
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
"@

    $runner = Join-Path $conformance 'Invoke-Conformance.ps1'
    $seen = @{}
    foreach ($pair in @(@{ Path = $a; Name = 'PSHelpFixture' }, @{ Path = $b; Name = 'PSShapeTwo' })) {
        $summary = & $runner -Path $pair.Path -ModuleName $pair.Name `
            -Tag Universal, Repository, HouseStyle, RequiresBuild `
            -ResultPath (Join-Path $pair.Path 'r.json') 6>$null | Select-Object -Last 1
        $seen[$pair.Name] = [pscustomobject]@{
            Defined = [int]$summary.CasesDefined
            Run     = [int]$summary.CasesRun
            PerTag  = $summary.CasesDefinedPerTag
        }
        Write-Host ("    $($pair.Name): cases-defined $($seen[$pair.Name].Defined), cases-run $($seen[$pair.Name].Run)")
        if ($seen[$pair.Name].Defined -ne 41) {
            $problems += "$($pair.Name) reports cases-defined $($seen[$pair.Name].Defined), not 41"
        }
        foreach ($tag in @{ HouseStyle = 22; Universal = 9; RequiresBuild = 6; Repository = 4 }.GetEnumerator()) {
            $actual = $seen[$pair.Name].PerTag.($tag.Key)
            if ($actual -ne $tag.Value) {
                $problems += "$($pair.Name) reports $($tag.Key) = $actual, not $($tag.Value)"
            }
        }
    }
    # The whole point of the property: the shapes differ, so cases-run must too.
    # If both targets happened to produce the same cases-run, this check would be
    # comparing one shape with itself and proving nothing.
    if ($seen['PSHelpFixture'].Run -eq $seen['PSShapeTwo'].Run) {
        $problems += 'the two targets produced the same cases-run, so they are not differently shaped and this check proves nothing'
    }
    $problems
}

# ---------------------------------------------------------------------------
# Spot-check 4. run-006 clone rescored; matches refscore.txt including the
# Bucket-B count.
# ---------------------------------------------------------------------------
Test-Check -Name 'Spot-check 4: the run-006 clone rescores to 38 / 41 with 3 Bucket-B failures' -Body {
    if ($SkipNetwork) {
        $skipped.Add('Spot-check 4 (needs the network to clone run 006)')
        Write-Host '    SKIPPED (-SkipNetwork). Not a pass.'
        return $null
    }
    $problems = @()
    $recorded = Get-Content -LiteralPath (Join-Path $plan 'refscore.txt') -Raw
    if ($recorded -notmatch 'RUN-006 CLONE \(built\): 38 / 41, 3 new-rule failures Bucket B declared') {
        $problems += 'refscore.txt does not carry the recorded headline'
    }

    $result = & (Join-Path $conformance 'Score-Clone.ps1') `
        -Source 'https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git' `
        -Ref '70669167ea5f59a47efb282002052f9e926a34bf' `
        -WorkDir (Join-Path $WorkDir 'r6') 6>$null | Select-Object -Last 1

    Write-Host ("    scored $($result.Score) / $($result.CasesDefined), " +
        "cases-run $($result.CasesPassed)/$($result.CasesRun), build exit $($result.BuildExitCode)")

    if ($result.Score -ne 38) { $problems += "scored $($result.Score), not 38" }
    if ($result.CasesDefined -ne 41) { $problems += "cases-defined $($result.CasesDefined), not 41" }
    if ($result.BuildExitCode -ne 0) { $problems += "the clone did not build (exit $($result.BuildExitCode)); a conformance failure against a target that does not build is unattributable" }
    if (@($result.FailedAssertions).Count -ne 3) {
        $problems += "$(@($result.FailedAssertions).Count) failing assertions, not the 3 declared Bucket B"
    }
    # Every failure must be one of the three DECLARED ones. A different failure
    # of the same count would pass a count-only check.
    $declared = @(
        'House style: help.gives <_.Name> at least as many examples as parameter sets'
        'House style: help.gives <_.Name> at least one example'
        'House style: help.shows every named parameter set of <_.Name> in an example'
    )
    foreach ($failed in @($result.FailedAssertions)) {
        if ($failed -notin $declared) { $problems += "undeclared failure: $failed" }
    }
    $problems
}

# ---------------------------------------------------------------------------
# Spot-check 5. git diff v1.1.1..v1.2.0 -- commands/ empty; skills diff = the
# two new directories plus the five named amendments; every .claude-plugin/
# change a version field.
# ---------------------------------------------------------------------------
Test-Check -Name 'Spot-check 5: the v1.1.1..v1.2.0 diff is exactly what the release claims' -Body {
    $problems = @()

    $tags = @(& git -C $RepoRoot tag --list 'v1.1.1' 'v1.2.0')
    if ($tags.Count -ne 2) {
        $problems += "expected both v1.1.1 and v1.2.0 locally; found: $($tags -join ', ')"
        return $problems
    }

    $commands = @(& git -C $RepoRoot diff --name-only v1.1.1..v1.2.0 -- commands/)
    if ($commands.Count -ne 0) { $problems += "commands/ changed between the tags: $($commands -join ', ')" }

    $skills = @(& git -C $RepoRoot diff --name-only v1.1.1..v1.2.0 -- skills/)
    $expected = @(
        'skills/powershell-module-analyzer/SKILL.md'
        'skills/powershell-module-architect/SKILL.md'
        'skills/powershell-module-build/SKILL.md'
        'skills/powershell-module-docs/SKILL.md'
        'skills/powershell-module-plan/SKILL.md'
        'skills/powershell-module-tidy/SKILL.md'
        'skills/powershell-module-tidy/scripts/Invoke-ModuleTidy.ps1'
        'skills/powershell-module-tidy/scripts/Test-PlanCurrency.ps1'
        'skills/powershell-module-ux/SKILL.md'
    )
    foreach ($path in $skills) {
        if ($path -notin $expected) { $problems += "unexpected skills/ change: $path" }
    }
    foreach ($path in $expected) {
        if ($path -notin $skills) { $problems += "expected skills/ change missing: $path" }
    }

    # Every changed line under .claude-plugin/ must be a version field.
    $lines = @(& git -C $RepoRoot diff --unified=0 v1.1.1..v1.2.0 -- .claude-plugin/ |
            Where-Object { $_ -match '^[+-]' -and $_ -notmatch '^(\+\+\+|---)' })
    foreach ($line in $lines) {
        if ($line -notmatch '^\s*[+-]\s*"version":') {
            $problems += "a non-version line changed under .claude-plugin/: $line"
        }
    }
    if ($lines.Count -eq 0) { $problems += 'no lines changed under .claude-plugin/, so the version was not bumped' }

    # The three version strings agree with the tag.
    $manifest = Get-Content -LiteralPath (Join-Path $RepoRoot '.claude-plugin/plugin.json') -Raw | ConvertFrom-Json
    if ($manifest.version -ne '1.2.0') { $problems += "plugin.json says $($manifest.version), not 1.2.0" }
    $market = Get-Content -LiteralPath (Join-Path $RepoRoot '.claude-plugin/marketplace.json') -Raw | ConvertFrom-Json
    if ($market.metadata.version -ne '1.2.0') { $problems += "marketplace metadata says $($market.metadata.version), not 1.2.0" }
    if ($market.plugins[0].version -ne '1.2.0') { $problems += "marketplace plugin entry says $($market.plugins[0].version), not 1.2.0" }

    if (-not $SkipNetwork) {
        $remote = @(& git -C $RepoRoot ls-remote --tags origin 'v1.2.0*')
        if ($remote.Count -eq 0) { $problems += 'v1.2.0 is not on the remote' }
    }
    else { $skipped.Add('Spot-check 5, remote-tag half (-SkipNetwork)') }

    $problems
}

# ---------------------------------------------------------------------------
# Not a numbered spot-check, but the claim the whole pass rests on: no existing
# assertion was weakened or removed. Re-derived, not asserted.
# ---------------------------------------------------------------------------
Test-Check -Name 'Constraint: no existing assertion weakened or removed' -Body {
    $problems = @()
    $changed = @(& git -C $RepoRoot diff --name-only v1.1.1..v1.2.0 -- evals/conformance/Conformance.Tests.ps1)
    if ($changed.Count -ne 0) {
        $problems += 'Conformance.Tests.ps1 changed between the tags; this pass claimed only to add'
    }
    # The pre-change per-tag split, still intact for the three untouched tags.
    $pre = Get-Content -LiteralPath (Join-Path $plan 'pre-inventory.json') -Raw | ConvertFrom-Json
    if ([int]$pre.CasesDefined -ne 33) { $problems += "pre-inventory.json records $($pre.CasesDefined), not 33" }
    foreach ($tag in 'Universal', 'Repository', 'RequiresBuild') {
        if ([int]$pre.CasesDefinedPerTag.$tag -ne @{ Universal = 9; Repository = 4; RequiresBuild = 6 }[$tag]) {
            $problems += "pre-inventory.json's $tag does not match the recorded split"
        }
    }
    $problems
}

# ---------------------------------------------------------------------------
Write-Host ''
Write-Host '======================================================================'
foreach ($note in $skipped) { Write-Host "SKIPPED  $note  (skipped is not passed)" }
if ($failures.Count -eq 0) {
    Write-Host "VERIFY 0039: every check agrees.$(if ($skipped.Count) { " $($skipped.Count) skipped." })"
    exit 0
}
Write-Host "VERIFY 0039: $($failures.Count) check(s) disagree."
foreach ($failure in $failures) { Write-Host "  $failure" }
exit 1
