#Requires -Version 7.2
<#
.SYNOPSIS
    Score a commit for conformance from a fresh clone that has been BUILT.
.DESCRIPTION
    The scoring procedure, as one command, because the procedure was the defect.

    Four `RequiresBuild` assertions read `output/<Name>/`, which is `.gitignore`d
    and therefore absent from any clone that has not run the build. The scoring
    protocol as written said "score in a fresh clone" and said nothing about
    building it, so run 007's conformance clone was never built and those four
    assertions could not pass - they graded the absence of a directory, not the
    module. That is LEDGER item 24, and it is a defect in the PROCEDURE: no
    assertion is wrong, and none is changed here.

    The rule this script enforces: the conformance clone is built before it is
    scored. `RequiresBuild` grades build output or it grades nothing.

    It is deliberately not a harness. It clones, builds, scores, and prints what
    it did. Everything it does was previously done by hand in three or four
    shell steps, differently in each of runs 004, 005, 006 and 007 - which is
    exactly why the ladder's numbers and 007's were not the same measurement.

.PARAMETER Source
    Repository to clone from: a URL, or a path to another clone. Never the
    working checkout being scored - hazard 5.
.PARAMETER Ref
    Commit-ish to score. A full SHA is checked against what was actually
    checked out and the script stops if they differ.
.PARAMETER WorkDir
    Where the clone is made. Must not already exist as a non-empty directory:
    scoring into a reused tree is how run 005 raced its own build.
.PARAMETER Tag
    Conformance tags. Defaults to all four, which is what a run is scored at.
.PARAMETER ResultPath
    Where result.json goes. Defaults to <WorkDir>/conformance-result.json.
.PARAMETER ModuleName
    Passed through when the suite's rules and the runner's derivation cannot
    decide. Normally unnecessary for a run directory.
.PARAMETER BuildTask
    Task for the target's ./build.ps1. Omitted by default, so the target's OWN
    default runs and nothing is assumed about its task names. That is not
    fussiness: run 007's first shot declares
    `[ValidateSet('Clean','Build','Test','All')]` and no '.' task at all, so a
    wrapper that hard-codes `-Task .` fails the build of the very commits whose
    non-house-style build file is the thing being graded.
.PARAMETER SkipBuild
    Reproduce the OLD, defective procedure: score an unbuilt clone. This exists
    for the falsification control - the unbuilt clone must still fail the four
    `RequiresBuild` assertions, or the repair proves nothing. Never use it to
    produce a reported score.
.PARAMETER ScoreAnyway
    Score past a red build. HARNESS.md step 3 gates on Phase 0 for a reason: a
    conformance failure against a target that does not build is unattributable.
    This switch overrides the gate, and exists so the sabotage falsification row
    can be run at all.
.EXAMPLE
    ./Score-Clone.ps1 -Source https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git `
                      -Ref 95ca28d76c8eeb6dc33b09f77109dc96038c76aa `
                      -WorkDir $env:TEMP/score-007
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Source,
    [Parameter(Mandatory)] [string] $Ref,
    [Parameter(Mandatory)] [string] $WorkDir,

    [ValidateSet('Universal', 'Repository', 'HouseStyle', 'RequiresBuild')]
    [string[]] $Tag = @('Universal', 'Repository', 'HouseStyle', 'RequiresBuild'),

    [string] $ResultPath,
    [string] $ModuleName,
    [string[]] $BuildTask,
    [switch] $SkipBuild,
    [switch] $ScoreAnyway
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Test-Path -LiteralPath $WorkDir) {
    if (@(Get-ChildItem -LiteralPath $WorkDir -Force).Count -gt 0) {
        throw "WorkDir '$WorkDir' exists and is not empty. Scoring into a reused tree is what run 005's race was."
    }
}
else {
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
}
$WorkDir = (Resolve-Path -LiteralPath $WorkDir).Path

Write-Host "==> clone  $Source -> $WorkDir"
git clone --quiet --no-checkout -- $Source $WorkDir
if ($LASTEXITCODE -ne 0) { throw "git clone failed with exit $LASTEXITCODE." }
git -C $WorkDir checkout --quiet --detach $Ref
if ($LASTEXITCODE -ne 0) { throw "git checkout '$Ref' failed with exit $LASTEXITCODE." }

$actual = (git -C $WorkDir rev-parse HEAD).Trim()
if ($Ref -match '^[0-9a-f]{40}$' -and $actual -ne $Ref) {
    throw "Checked out '$actual' but was asked for '$Ref'."
}
Write-Host "    HEAD $actual"

# ---------------------------------------------------------------------------
# The repair. Everything above this comment was already the protocol; the build
# is what was missing, and its absence is the whole of the 28-versus-32 gap.
# ---------------------------------------------------------------------------
$buildExit = $null
if ($SkipBuild) {
    Write-Warning 'SkipBuild: scoring an UNBUILT clone. This is the defective procedure and is a control, not a score.'
}
else {
    $buildScript = Join-Path $WorkDir 'build.ps1'
    if (-not (Test-Path -LiteralPath $buildScript)) {
        throw "No build.ps1 at the root of '$WorkDir'. A target without a build entrypoint cannot be scored at RequiresBuild; run with -Tag excluding it, and say so in the record."
    }
    $buildArgs = @()
    if ($PSBoundParameters.ContainsKey('BuildTask')) { $buildArgs = @('-Task') + $BuildTask }
    Write-Host "==> build  ./build.ps1 $($buildArgs -join ' ')".TrimEnd()
    & pwsh -NoProfile -File $buildScript @buildArgs *>&1 |
        ForEach-Object { Write-Host "    $_" }
    $buildExit = $LASTEXITCODE
    Write-Host "    build exit $buildExit"

    if ($buildExit -ne 0 -and -not $ScoreAnyway) {
        throw ("Build exited $buildExit. HARNESS.md step 3 gates on Phase 0: a conformance " +
            'failure against a target that does not build is unattributable. Pass -ScoreAnyway ' +
            'only to run a falsification row.')
    }
}

if (-not $ResultPath) { $ResultPath = Join-Path $WorkDir 'conformance-result.json' }

$conformanceArgs = @{
    Path       = $WorkDir
    Tag        = $Tag
    ResultPath = $ResultPath
}
if ($ModuleName) { $conformanceArgs['ModuleName'] = $ModuleName }

Write-Host "==> score  Invoke-Conformance.ps1 -Tag $($Tag -join ',')"
$summary = & (Join-Path $PSScriptRoot 'Invoke-Conformance.ps1') @conformanceArgs |
    Select-Object -Last 1

# The comparable score is per ASSERTION against cases-defined, not per case: an
# It with -ForEach produces a target-shaped number of cases, and two runs of the
# same suite against two builds of the same module reported 57 and 55. An
# assertion counts as failed if any of its cases failed.
$failedAssertions = @($summary.Assertions | Where-Object { $_.Failed -gt 0 })
$score = [int]$summary.CasesDefined - $failedAssertions.Count
$buildNote = if ($SkipBuild) { 'SKIPPED (control)' } else { "exit $buildExit" }

Write-Host ''
$settingNote = if ($summary.Settings.IsMeasuredConfiguration) { 'defaults (the measured configuration)' }
              else { (@($summary.Settings.Values.PSObject.Properties) | ForEach-Object {
                      '{0}={1} ({2})' -f $_.Name, $_.Value, $summary.Settings.Source.($_.Name) }) -join ', ' }
Write-Host ("SCORE  $score / $($summary.CasesDefined) (cases-defined)   " +
    "cases-run $($summary.Passed)/$($summary.CasesRun)   build $buildNote")
Write-Host ("       settings: $settingNote")
foreach ($a in $failedAssertions) { Write-Host "  FAILED  $($a.Name)" }

[pscustomobject]@{
    Ref              = $actual
    # Carried through from the conformance summary rather than re-resolved, so a
    # run record and the result.json beside it cannot state different settings.
    Settings         = $summary.Settings
    WorkDir          = $WorkDir
    Built            = -not $SkipBuild
    BuildExitCode    = $buildExit
    Score            = $score
    CasesDefined     = [int]$summary.CasesDefined
    CasesRun         = [int]$summary.CasesRun
    CasesPassed      = [int]$summary.Passed
    FailedAssertions = @($failedAssertions | ForEach-Object { $_.Name })
    ResultPath       = $ResultPath
}
