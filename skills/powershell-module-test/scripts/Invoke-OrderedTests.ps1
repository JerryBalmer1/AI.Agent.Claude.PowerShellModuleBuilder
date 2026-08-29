#Requires -Version 7.2

<#
.SYNOPSIS
    Run a module repository's checks in dependency order and stop at the first
    failing layer.

.DESCRIPTION
    Tests fail in cascades. One unparseable source file produces a lint that
    reports clean, a psm1 that will not import, nine import errors, and then
    every test in the suite failing on a module that is not loaded. All of that
    is one defect, and the wall of red buries the file name that would fix it.

    This runner executes five layers in dependency order. Each layer is a
    precondition for the next. The first layer that fails stops the run, and the
    only failures printed are that layer's:

        1. manifest-parses   the manifest is readable as PowerShell data
        2. files-parse       every .ps1 in src/ and tests/ parses
        3. module-imports    the module loads in a clean process
        4. unit              Pester, excluding integration and contract
        5. integration       Pester, integration and contract only

    Ordering, and stopping, are the whole point. A failure at layer 2 says
    "this file, this line". The same defect observed at layer 4 says "37 tests
    failed".

.PARAMETER Path
    Repository root of the module under test.

.PARAMETER ModuleName
    Which module the repository contains. Derived from src/<Name>/<Name>.psd1
    when omitted. Ambiguity is a hard stop, never a guess.

.PARAMETER Build
    Run ./build.ps1 -Task Build after files-parse and before module-imports.
    Needed when the tests import from output/, which is not committed. Without
    it, module-imports fails naming the command to run.

.PARAMETER IntegrationTag
    Pester tags that place a test in the integration layer regardless of which
    directory it lives in. Default: Integration, Contract.

.PARAMETER IntegrationDirectory
    Directory names under tests/ whose files are in the integration layer
    regardless of tag. Default: Integration, Contract.

.EXAMPLE
    ./Invoke-OrderedTests.ps1 -Path ./scratch/runs/002 -Build

.EXAMPLE
    ./Invoke-OrderedTests.ps1 -Path . -ModuleName PSAzureDevOpsGraph
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Path,

    [string] $ModuleName,

    [switch] $Build,

    [string[]] $IntegrationTag = @('Integration', 'Contract'),

    [string[]] $IntegrationDirectory = @('Integration', 'Contract')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Target = (Resolve-Path -LiteralPath $Path).ProviderPath

# ---------------------------------------------------------------------------
# Layer bookkeeping
#
# A layer reports one of PASSED, FAILED, or INAPPLICABLE. INAPPLICABLE is not a
# pass: a layer that produced zero cases graded nothing, and saying "passed"
# there is how a suite that stopped running starts looking healthy. Only FAILED
# stops the run.
# ---------------------------------------------------------------------------

$script:Layers = [System.Collections.Generic.List[object]]::new()

function Add-LayerResult {
    param(
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][ValidateSet('PASSED', 'FAILED', 'INAPPLICABLE')][string] $Status,
        [int] $Cases = 0,
        [string[]] $Failure = @(),
        [string] $Note
    )
    $script:Layers.Add([pscustomobject]@{
            Name    = $Name
            Status  = $Status
            Cases   = $Cases
            Failure = @($Failure)
            Note    = $Note
        })
}

function Write-LayerLine {
    param([Parameter(Mandatory)][object] $Layer)
    $suffix = if ($Layer.Note) { "  $($Layer.Note)" } else { '' }
    Write-Host ("LAYER {0,-16} {1,-12} {2} case(s){3}" -f
        $Layer.Name, $Layer.Status, $Layer.Cases, $suffix)
}

# ---------------------------------------------------------------------------
# Module discovery
#
# src/<Name>/<Name>.psd1 is the layout this repository's scaffold mandates, so
# it is a positive rule and not a lone-candidate fallback. More than one match
# is undecidable and stops; picking the survivor is how a suite silently grades
# the wrong module.
# ---------------------------------------------------------------------------

$srcRoot = Join-Path $script:Target 'src'
$candidates = @()
if (Test-Path -LiteralPath $srcRoot) {
    $candidates = @(
        Get-ChildItem -Path $srcRoot -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -eq $_.Directory.Name }
    )
}

if ($ModuleName) {
    $named = @($candidates | Where-Object { $_.BaseName -eq $ModuleName })
    if ($named.Count -ne 1) {
        throw ("-ModuleName '$ModuleName' matched $($named.Count) manifests under '$srcRoot'.")
    }
    $manifestFile = $named[0]
}
elseif ($candidates.Count -eq 1) {
    $manifestFile = $candidates[0]
    $ModuleName = $manifestFile.BaseName
}
elseif ($candidates.Count -gt 1) {
    $names = @($candidates | ForEach-Object { $_.FullName.Substring($script:Target.Length).TrimStart('\', '/') })
    throw ("Cannot determine which module '$script:Target' is: $($candidates.Count) manifests under src/, " +
        "none preferred. Candidates: $($names -join '; '). Pass -ModuleName to choose.")
}
else {
    throw ("No manifest found under '$srcRoot'. Expected src/<Name>/<Name>.psd1.")
}

$testsRoot = Join-Path $script:Target 'tests'
$outRoot = Join-Path (Join-Path $script:Target 'output') $ModuleName

Write-Host ''
Write-Host "Ordered test run: $ModuleName"
Write-Host "  target:   $script:Target"
Write-Host "  manifest: $($manifestFile.FullName.Substring($script:Target.Length).TrimStart('\','/'))"
Write-Host ''

# ---------------------------------------------------------------------------
# Stop check, used after every layer
# ---------------------------------------------------------------------------

function Test-ShouldStop {
    [OutputType([bool])]
    param()
    $last = $script:Layers[-1]
    Write-LayerLine -Layer $last
    return ($last.Status -eq 'FAILED')
}

function Complete-Run {
    param([string[]] $NotRun)

    $failed = @($script:Layers | Where-Object { $_.Status -eq 'FAILED' })
    Write-Host ''

    if ($failed.Count -eq 0) {
        $inapplicable = @($script:Layers | Where-Object { $_.Status -eq 'INAPPLICABLE' })
        Write-Host ("ALL LAYERS GREEN — {0} passed, {1} inapplicable." -f
            @($script:Layers | Where-Object { $_.Status -eq 'PASSED' }).Count, $inapplicable.Count)
        if ($inapplicable.Count) {
            Write-Host ("  inapplicable (graded nothing, not a pass): {0}" -f
                (($inapplicable | ForEach-Object { $_.Name }) -join ', '))
        }
        Write-Host ''
        exit 0
    }

    $stopped = $failed[0]
    Write-Host "STOPPED AT LAYER $($stopped.Name)"
    Write-Host ''
    foreach ($line in $stopped.Failure) {
        Write-Host "  $line"
    }
    Write-Host ''
    if ($NotRun) {
        # Named, not shown. Which layers never ran is a fact about the run; their
        # output would be the cascade this runner exists to suppress.
        Write-Host ("NOT RUN (a failing layer is a precondition for these): {0}" -f ($NotRun -join ', '))
        Write-Host ''
    }
    exit 1
}

# ---------------------------------------------------------------------------
# Layer 1 — manifest-parses
# ---------------------------------------------------------------------------

$failures = @()
try {
    $null = Import-PowerShellDataFile -LiteralPath $manifestFile.FullName -ErrorAction Stop
}
catch {
    # Import-PowerShellDataFile raises a NON-terminating error on a manifest it
    # cannot parse, so -ErrorAction Stop is what makes this catch run at all.
    $failures += "$($manifestFile.Name): $($_.Exception.Message)"
}

if ($failures) { Add-LayerResult -Name 'manifest-parses' -Status 'FAILED' -Cases 1 -Failure $failures }
else { Add-LayerResult -Name 'manifest-parses' -Status 'PASSED' -Cases 1 }

if (Test-ShouldStop) { Complete-Run -NotRun @('files-parse', 'module-imports', 'unit', 'integration') }

# ---------------------------------------------------------------------------
# Layer 2 — files-parse
#
# The layer that exists because a lint gate cannot be trusted to find this.
# PSScriptAnalyzer's Severity list does not include ParseError unless it is
# named, so a settings file listing @('Error','Warning') reports clean on a file
# that does not parse at all.
# ---------------------------------------------------------------------------

$scriptFiles = @(
    foreach ($root in @($manifestFile.Directory.FullName, $testsRoot)) {
        if (Test-Path -LiteralPath $root) {
            Get-ChildItem -Path $root -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue
        }
    }
) | Sort-Object FullName

$failures = @()
foreach ($file in $scriptFiles) {
    $tokens = $null
    $parseErrors = $null
    # ParseFile, never ParseInput: ParseInput leaves Extent.File null, so a
    # diagnostic cannot name the file it came from - which is the only thing
    # this layer is for.
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $file.FullName, [ref] $tokens, [ref] $parseErrors)

    foreach ($parseError in @($parseErrors)) {
        $relative = $file.FullName.Substring($script:Target.Length).TrimStart('\', '/')
        $failures += ("{0}:{1}:{2}: {3}" -f
            $relative,
            $parseError.Extent.StartLineNumber,
            $parseError.Extent.StartColumnNumber,
            $parseError.Message)
    }
}

if ($scriptFiles.Count -eq 0) {
    Add-LayerResult -Name 'files-parse' -Status 'FAILED' -Cases 0 `
        -Failure @("No .ps1 files under $($manifestFile.Directory.FullName) or $testsRoot.")
}
elseif ($failures) {
    Add-LayerResult -Name 'files-parse' -Status 'FAILED' -Cases $scriptFiles.Count -Failure $failures
}
else {
    Add-LayerResult -Name 'files-parse' -Status 'PASSED' -Cases $scriptFiles.Count
}

if (Test-ShouldStop) { Complete-Run -NotRun @('module-imports', 'unit', 'integration') }

# ---------------------------------------------------------------------------
# Optional build, between files-parse and module-imports
#
# Deliberately not a layer. Building is not a check; it is what makes the next
# check possible. It runs after files-parse so that an unparseable file is
# reported by name rather than as a build failure three stages downstream.
# ---------------------------------------------------------------------------

if ($Build) {
    $buildScript = Join-Path $script:Target 'build.ps1'
    if (-not (Test-Path -LiteralPath $buildScript)) {
        Add-LayerResult -Name 'module-imports' -Status 'FAILED' -Cases 1 `
            -Failure @("-Build was passed and there is no build.ps1 at $buildScript.")
        Write-LayerLine -Layer $script:Layers[-1]
        Complete-Run -NotRun @('unit', 'integration')
    }
    Write-Host "  building (-Build): $buildScript"
    $buildOutput = & pwsh -NoProfile -NonInteractive -File $buildScript -Task Build 2>&1
    if ($LASTEXITCODE -ne 0) {
        Add-LayerResult -Name 'module-imports' -Status 'FAILED' -Cases 1 `
            -Failure @("build.ps1 -Task Build exited $LASTEXITCODE.") + @($buildOutput | ForEach-Object { "$_" })
        Write-LayerLine -Layer $script:Layers[-1]
        Complete-Run -NotRun @('unit', 'integration')
    }
    Write-Host ''
}

# ---------------------------------------------------------------------------
# Layer 3 — module-imports
#
# In a child process. This is the first layer that executes the module's own
# code: importing runs the module's top level, its ScriptsToProcess, and any
# class static constructors. A failure that happens in this process would
# contaminate every layer after it.
# ---------------------------------------------------------------------------

$importTarget = $null
$builtManifest = Join-Path $outRoot "$ModuleName.psd1"
$devLoader = Join-Path $manifestFile.Directory.FullName "$ModuleName.psm1"

if (Test-Path -LiteralPath $builtManifest) { $importTarget = $builtManifest }
elseif (Test-Path -LiteralPath $devLoader) { $importTarget = $manifestFile.FullName }

if (-not $importTarget) {
    Add-LayerResult -Name 'module-imports' -Status 'FAILED' -Cases 1 -Failure @(
        "No importable module."
        "  built manifest: $builtManifest (absent)"
        "  dev loader:     $devLoader (absent)"
        "output/ is a build product and is not committed. Run ./build.ps1 in the target, or re-run this script with -Build."
    )
}
else {
    $env:ORDEREDTESTS_IMPORT_TARGET = $importTarget
    $importOutput = & pwsh -NoProfile -NonInteractive -Command `
        'Import-Module -Name $env:ORDEREDTESTS_IMPORT_TARGET -Force -ErrorAction Stop; Write-Output "IMPORT-OK"' 2>&1
    $importExit = $LASTEXITCODE
    Remove-Item -LiteralPath 'Env:\ORDEREDTESTS_IMPORT_TARGET' -ErrorAction Ignore

    if ($importExit -ne 0 -or -not (@($importOutput) -match 'IMPORT-OK')) {
        Add-LayerResult -Name 'module-imports' -Status 'FAILED' -Cases 1 -Failure (
            @("Import-Module '$importTarget' failed (exit $importExit).") +
            @($importOutput | ForEach-Object { "  $_" })
        )
    }
    else {
        Add-LayerResult -Name 'module-imports' -Status 'PASSED' -Cases 1 `
            -Note "($(Split-Path -Leaf (Split-Path -Parent $importTarget)))"
    }
}

if (Test-ShouldStop) { Complete-Run -NotRun @('unit', 'integration') }

# ---------------------------------------------------------------------------
# Layers 4 and 5 — Pester
#
# Layer membership two ways, because neither alone covers a real repository:
#
#   directory  tests/Integration/ and tests/Contract/ are the integration layer
#   tag        an It or Describe tagged Integration or Contract is too, wherever
#              its file lives
#
# The directory rule is what a new repository gets for free. The tag rule is
# what lets one file hold a command's unit tests and its contract test without
# splitting it.
# ---------------------------------------------------------------------------

$pester = Get-Module -Name Pester -ListAvailable |
    Where-Object { $_.Version -ge [version]'6.0.0' -and $_.Version -lt [version]'7.0.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pester) {
    Add-LayerResult -Name 'unit' -Status 'FAILED' -Cases 0 `
        -Failure @('Pester 6.x is required. Install-Module Pester -RequiredVersion 6.1.0 -Force')
    if (Test-ShouldStop) { Complete-Run -NotRun @('integration') }
}
Import-Module -Name $pester.Path -Force

$allTestFiles = @()
if (Test-Path -LiteralPath $testsRoot) {
    $allTestFiles = @(Get-ChildItem -Path $testsRoot -Filter '*.Tests.ps1' -File -Recurse |
            Sort-Object FullName)
}

function Test-IsIntegrationPath {
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $FullName)
    $relative = $FullName.Substring($testsRoot.Length).TrimStart('\', '/')
    $segments = $relative -split '[\\/]'
    foreach ($segment in $segments[0..([Math]::Max(0, $segments.Count - 2))]) {
        if ($IntegrationDirectory -contains $segment) { return $true }
    }
    return $false
}

$unitFiles = @($allTestFiles | Where-Object { -not (Test-IsIntegrationPath -FullName $_.FullName) })
$integrationFiles = @($allTestFiles | Where-Object { Test-IsIntegrationPath -FullName $_.FullName })

function Invoke-PesterLayer {
    param(
        [string[]] $TestPath,
        [string[]] $IncludeTag = @(),
        [string[]] $ExcludeTag = @()
    )
    if (-not $TestPath) { return $null }

    $config = New-PesterConfiguration
    $config.Run.Path = $TestPath
    $config.Run.PassThru = $true
    # NOT Run.Throw. This runner decides what stops the run; a throw from inside
    # Pester would take the decision away and lose the per-layer accounting.
    $config.Run.Throw = $false
    # An It whose -ForEach collection is empty is inapplicable, not a failure of
    # the file that contains it. Left at the default, one such It aborts the
    # whole container and takes every assertion that had already passed with it.
    $config.Run.FailOnNullOrEmptyForEach = $false
    $config.Output.Verbosity = 'None'
    if ($IncludeTag) { $config.Filter.Tag = $IncludeTag }
    if ($ExcludeTag) { $config.Filter.ExcludeTag = $ExcludeTag }

    Invoke-Pester -Configuration $config
}

function Get-PesterFailure {
    param([object] $Result)
    @($Result.Failed | ForEach-Object {
            $message = ($_.ErrorRecord.Exception.Message -split "`n")[0]
            "$($_.ExpandedPath): $message"
        })
}

# --- unit ---

$unitResult = Invoke-PesterLayer -TestPath ($unitFiles | ForEach-Object { $_.FullName }) `
    -ExcludeTag $IntegrationTag

if ($null -eq $unitResult) {
    Add-LayerResult -Name 'unit' -Status 'FAILED' -Cases 0 `
        -Failure @("No *.Tests.ps1 outside $($IntegrationDirectory -join '/') under $testsRoot. A module with no unit tests has not been tested.")
}
else {
    $cases = $unitResult.PassedCount + $unitResult.FailedCount
    if ($cases -eq 0) {
        Add-LayerResult -Name 'unit' -Status 'FAILED' -Cases 0 `
            -Failure @("$($unitFiles.Count) test file(s) discovered and 0 cases ran. Zero cases is not a pass.")
    }
    elseif ($unitResult.FailedCount -gt 0) {
        Add-LayerResult -Name 'unit' -Status 'FAILED' -Cases $cases `
            -Failure (Get-PesterFailure -Result $unitResult)
    }
    else {
        Add-LayerResult -Name 'unit' -Status 'PASSED' -Cases $cases
    }
}

if (Test-ShouldStop) { Complete-Run -NotRun @('integration') }

# --- integration / contract ---
#
# Credentials are a prerequisite, and an absent one is announced rather than
# quietly turned into a green run. A layer that reports success where nothing
# could contradict it is worse than a layer that says it did not run.

$patNeeded = @()
foreach ($file in $allTestFiles) {
    if ((Get-Content -LiteralPath $file.FullName -Raw) -match 'RequiresPat') {
        $patNeeded += $file.Name
    }
}
$excludeForPat = @()
if ($patNeeded -and -not $env:AZDO_PAT) {
    Write-Host ''
    Write-Host "  SKIPPING tests tagged RequiresPat: `$env:AZDO_PAT is not set."
    Write-Host "  Affected file(s): $($patNeeded -join ', ')"
    Write-Host '  This layer therefore grades less than it claims to. Set AZDO_PAT to close the gap.'
    $excludeForPat = @('RequiresPat')
}

$integrationResults = @()

if ($integrationFiles) {
    $integrationResults += Invoke-PesterLayer `
        -TestPath ($integrationFiles | ForEach-Object { $_.FullName }) -ExcludeTag $excludeForPat
}
if ($unitFiles) {
    # Tagged integration/contract cases living in otherwise-unit files.
    $integrationResults += Invoke-PesterLayer `
        -TestPath ($unitFiles | ForEach-Object { $_.FullName }) `
        -IncludeTag $IntegrationTag -ExcludeTag $excludeForPat
}

$integrationResults = @($integrationResults | Where-Object { $null -ne $_ })
$integrationCases = 0
$integrationFailed = 0
$integrationFailures = @()
foreach ($result in $integrationResults) {
    $integrationCases += $result.PassedCount + $result.FailedCount
    $integrationFailed += $result.FailedCount
    $integrationFailures += Get-PesterFailure -Result $result
}

if ($integrationCases -eq 0) {
    Add-LayerResult -Name 'integration' -Status 'INAPPLICABLE' -Cases 0 `
        -Note "(no test in $($IntegrationDirectory -join '/') and none tagged $($IntegrationTag -join '/'))"
}
elseif ($integrationFailed -gt 0) {
    Add-LayerResult -Name 'integration' -Status 'FAILED' -Cases $integrationCases `
        -Failure $integrationFailures
}
else {
    Add-LayerResult -Name 'integration' -Status 'PASSED' -Cases $integrationCases
}

$null = Test-ShouldStop
Complete-Run -NotRun @()
