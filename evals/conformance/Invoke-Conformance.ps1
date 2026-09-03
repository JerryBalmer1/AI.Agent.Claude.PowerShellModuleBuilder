#Requires -Version 7.0
<#
.SYNOPSIS
    Run the conformance suite against a PowerShell module repository.
.PARAMETER Path
    Repository root of the module under test.
.PARAMETER Tag
    Which assertion sets to run. Universal, Repository, HouseStyle,
    RequiresBuild. Default is Universal, Repository and HouseStyle, which need
    no build output.

    Universal alone is the set to run against a published package or any module
    that is not a repository - it makes no claim about build files or tests.
.PARAMETER ResultPath
    Where to write result.json. Default: alongside the target, ./conformance-result.json
.PARAMETER ModuleName
    Which module the target contains, when the suite cannot decide for itself.
    Discovery stops rather than guessing if more than one candidate manifest
    survives and none is preferred; this is the way to answer it. Grading the
    wrong module silently is worse than grading nothing.

    Defaulted from src/<Name>/<Name>.psd1 when omitted and the suite's own two
    rules cannot fire - which is the case for every run directory, because a
    directory named 002-first-build matches no manifest name and holds no
    manifest at its root. See the derivation block below for why that is a rule
    and not a fallback.
.PARAMETER PassExitCode
    Exit with the failure count instead of 0. Off by default: a red conformance
    run is data, and the harness reads the score from result.json, not from an
    exit code. Turn it on only for a caller that genuinely wants a red run to
    fail a pipeline step.
.EXAMPLE
    ./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph
.EXAMPLE
    ./Invoke-Conformance.ps1 -Path ./scratch/run-01/PSAzureDevOpsGraph -Tag Universal,HouseStyle,RequiresBuild
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Path,

    [ValidateSet('Universal', 'Repository', 'HouseStyle', 'RequiresBuild')]
    [string[]] $Tag = @('Universal', 'Repository', 'HouseStyle'),

    [string] $ResultPath,

    [string] $ModuleName,

    # Explicit settings, highest precedence. Passed straight to
    # Get-PSModuleSetting.ps1, which owns the known-key list and the refusal.
    [hashtable] $Setting = @{},

    [switch] $PassExitCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$target = (Resolve-Path -LiteralPath $Path).Path
if (-not $ResultPath) {
    $ResultPath = Join-Path (Get-Location) 'conformance-result.json'
}

# ---------------------------------------------------------------------------
# Settings, resolved FIRST so that an unknown key refuses before any grading
# happens. A refusal after a run has completed is a refusal the operator reads
# after they have already read a score.
#
# The values are echoed into result.json below with the provenance of each,
# because a score whose configuration is not recorded beside it cannot be
# compared with another score - and the whole point of cases-defined was that
# comparison needs the denominator stated. A threshold is the same kind of fact.
# ---------------------------------------------------------------------------
$settings = & (Join-Path $PSScriptRoot 'Get-PSModuleSetting.ps1') -Path $target -Override $Setting
if ($settings.FileFound) {
    Write-Host "Settings: $($settings.FilePath)"
}
Write-Host ('Settings: ' + ((@($settings.Values.PSObject.Properties) | ForEach-Object {
    '{0}={1} ({2})' -f $_.Name, $_.Value, $settings.Source.($_.Name)
}) -join ', '))

# ---------------------------------------------------------------------------
# -ModuleName default, for a target the suite's own rules cannot resolve.
#
# F-8. The suite prefers a manifest named for the target directory, then one
# sitting directly in the target, and has NO third rule on purpose: "if exactly
# one candidate survives, take it" once graded a vendored corpus module after the
# reference's own manifest was deleted, silently and confidently. That fallback
# is not coming back.
#
# A run directory fires neither rule. It is named for the run (002-first-build)
# and its manifest is at src/<Name>/<Name>.psd1, so every assertion failed for a
# reason that looked like the module's fault. Passing -ModuleName worked and was
# mandatory for every run.
#
# What is added here is a rule, not a fallback, and the difference is the whole
# point: src/<Name>/<Name>.psd1 is the layout this plugin's scaffold mandates and
# the conformance suite grades. Reading it is a positive claim about a known
# location. A lone survivor anywhere in the tree is not.
#
# It is deliberately the LAST rule tried. When either of the suite's rules can
# fire, nothing is passed and the suite decides exactly as before - so the
# reference, the gallery corpus, and every published-package target are
# untouched by this. Two manifests under src/ is undecidable and stops, naming
# both.
# ---------------------------------------------------------------------------

if (-not $ModuleName) {
    # The same candidate test the suite applies, so the two agree on what a
    # candidate is: a manifest named for its own directory, or one under a
    # version directory named for its grandparent. Same exclusions, matched
    # against the path RELATIVE to the target.
    $allCandidates = @(
        Get-ChildItem -Path $target -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.BaseName -eq $_.Directory.Name -or
                ($_.Directory.Name -match '^\d+(\.\d+)*([-+].*)?$' -and
                    $_.Directory.Parent -and $_.BaseName -eq $_.Directory.Parent.Name)
            } |
            Where-Object {
                $_.FullName.Substring($target.Length) -notmatch
                    '[\/](output|scratch|\.git|gallery|fixtures|node_modules)[\/]'
            }
    )

    $targetLeaf = Split-Path -Leaf $target
    $suiteCanDecide =
        @($allCandidates | Where-Object { $_.BaseName -eq $targetLeaf }).Count -eq 1 -or
        @($allCandidates | Where-Object { $_.Directory.FullName -eq $target }).Count -eq 1

    if (-not $suiteCanDecide) {
        $srcRoot = Join-Path $target 'src'
        $underSrc = @($allCandidates | Where-Object {
                $_.FullName.StartsWith($srcRoot + [System.IO.Path]::DirectorySeparatorChar,
                    [StringComparison]::OrdinalIgnoreCase)
            })

        if ($underSrc.Count -eq 1) {
            $ModuleName = $underSrc[0].BaseName
            Write-Host ("Derived -ModuleName '$ModuleName' from " +
                "$($underSrc[0].FullName.Substring($target.Length).TrimStart('\','/')).")
        }
        elseif ($underSrc.Count -gt 1) {
            # Rule 11. The operator gets an explicit way to answer the question
            # the runner could not, and the runner does not answer it for them.
            $names = @($underSrc | ForEach-Object {
                    $_.FullName.Substring($target.Length).TrimStart('\', '/')
                })
            throw ("Cannot derive -ModuleName: $($underSrc.Count) manifests under " +
                "'$srcRoot', none preferred. Candidates: $($names -join '; '). " +
                'Pass -ModuleName to choose.')
        }
        # Zero under src/ is absence, not ambiguity. Nothing is passed and the
        # suite reports it - either as a missing manifest, or with its own
        # ambiguity throw when the tree holds more than one candidate elsewhere.
    }
}

# ---------------------------------------------------------------------------
# The assertion inventory: what the suite DEFINES, per tag.
#
# CasesRun below is what executed, and it depends on the SHAPE of the target: an
# It with -ForEach over the public functions produces seven cases against a
# module with seven commands and one against a module with one. That makes a
# score comparable to itself and to nothing else, and it is why two runs of the
# same suite against two builds of the same module reported 57 and 55.
#
# cases-defined is the count of It statements the selected tags select, read
# from the suite's own SOURCE by parsing it. It cannot vary with the target
# because the target is not consulted: no file of the target is read, no
# -ForEach is expanded, nothing is discovered. That is the whole property.
#
# It is READING ONLY. No assertion is weakened, none is skipped, and CasesRun
# and the score are computed exactly as before. This adds a denominator that
# holds still; it does not change what is graded.
#
# Read from the AST rather than with a regex, for the reason the suite itself
# gives about the build file: a block comment quoting `It 'x' {` is not an It,
# and every regex written against this kind of file has eventually been defeated
# by one.
# ---------------------------------------------------------------------------

function Get-AssertionInventory {
    param([Parameter(Mandatory)] [string] $SuitePath)

    # Declared before the [ref], because Set-StrictMode refuses an undefined
    # variable and this file runs under it.
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($SuitePath, [ref]$null, [ref]$parseErrors)
    if ($parseErrors) { throw "Cannot parse '$SuitePath': $($parseErrors[0].Message)" }

    $commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)

    $describes = @($commands | Where-Object { $_.GetCommandName() -eq 'Describe' })
    $its = @($commands | Where-Object { $_.GetCommandName() -eq 'It' })

    $inventory = [ordered]@{}
    foreach ($describe in $describes) {
        # The -Tag argument, as written. A Describe carries the tag for every It
        # inside it; this suite has no Context that re-tags, and an It that
        # carried its own -Tag would need handling here rather than silently
        # counting under its parent.
        $tags = @()
        $elements = @($describe.CommandElements)
        for ($i = 0; $i -lt $elements.Count - 1; $i++) {
            $element = $elements[$i]
            if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and
                $element.ParameterName -eq 'Tag') {
                $value = $elements[$i + 1]
                if ($value -is [System.Management.Automation.Language.ArrayLiteralAst]) {
                    $tags = @($value.Elements | ForEach-Object { $_.Value })
                }
                elseif ($value.PSObject.Properties['Value']) { $tags = @($value.Value) }
            }
        }
        if (-not $tags) { continue }

        # Its inside THIS Describe, by source extent. Nested Describes would
        # double-count; this suite has none, and a change that introduced one
        # would need this to compare against the innermost enclosing Describe.
        $start = $describe.Extent.StartOffset
        $end = $describe.Extent.EndOffset
        $count = @($its | Where-Object { $_.Extent.StartOffset -ge $start -and $_.Extent.EndOffset -le $end }).Count

        foreach ($tag in $tags) {
            if (-not $inventory.Contains($tag)) { $inventory[$tag] = 0 }
            $inventory[$tag] += $count
        }
    }
    $inventory
}

# Every *.Tests.ps1 in this directory is a container of the suite, and every
# one of them is inventoried. Naming Conformance.Tests.ps1 alone is how a
# second container would run its assertions and be absent from cases-defined -
# the denominator would hold still while the numerator grew, which reads as an
# improvement and is a bookkeeping error. Sorted so the figure does not depend
# on directory enumeration order.
$script:SuiteFiles = @(
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.Tests.ps1 -File |
        Sort-Object Name
)
if ($SuiteFiles.Count -eq 0) { throw "No *.Tests.ps1 containers in '$PSScriptRoot'." }

$inventory = [ordered]@{}
foreach ($suiteFile in $SuiteFiles) {
    foreach ($entry in (Get-AssertionInventory -SuitePath $suiteFile.FullName).GetEnumerator()) {
        if (-not $inventory.Contains($entry.Key)) { $inventory[$entry.Key] = 0 }
        $inventory[$entry.Key] += [int]$entry.Value
    }
}
$definedPerTag = [ordered]@{}
# $selectedTag, NOT $tag. PowerShell variable names are case-insensitive, so a
# loop variable named $tag IS the $Tag parameter: iterating it rebinds the
# parameter to the last element, and every tag but one silently stops being
# selected. That happened here - the run reported 17 cases instead of 57 and
# looked like a filter bug in Pester.
foreach ($selectedTag in ($Tag | Sort-Object)) {
    $definedPerTag[$selectedTag] = if ($inventory.Contains($selectedTag)) { [int]$inventory[$selectedTag] } else { 0 }
}
$casesDefined = [int](@($definedPerTag.Values) | Measure-Object -Sum).Sum

$pester = Get-Module -Name Pester -ListAvailable |
    Where-Object { $_.Version -ge [version]'6.0.0' -and $_.Version -lt [version]'7.0.0' } |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pester) {
    throw 'Pester 6.x is required. Install-Module Pester -RequiredVersion 6.1.0 -Force'
}
Import-Module -Name $pester.Path -Force

# The suite reads its target from the environment because Pester needs the path
# at discovery time to enumerate public functions for -ForEach.
$env:CONFORMANCE_TARGET = $target
$env:CONFORMANCE_MODULE_NAME = $ModuleName

$config = New-PesterConfiguration
$config.Run.Path = @($SuiteFiles.FullName)
$config.Run.PassThru = $true
# Deliberately NOT Run.Throw. A red conformance run is data, not a build
# failure - the harness records the score and moves on to the next run.
$config.Run.Throw = $false
$config.Filter.Tag = $Tag
$config.Output.Verbosity = 'Detailed'
# An It whose -ForEach collection is empty is INAPPLICABLE to this target, not a
# failure of the file that contains it. Left at the default, one such It aborted
# the whole container: six of the eight gallery corpus modules have no Public/
# directory, so every assertion in the suite stopped, including ones that had
# already passed. Zero cases is not a pass either - CasesRun below is what says
# how much of the suite actually applied.
$config.Run.FailOnNullOrEmptyForEach = $false

$result = Invoke-Pester -Configuration $config

# ---------------------------------------------------------------------------
# A container that did not run is a MISSING MEASUREMENT, not a red run.
#
# A red run is data and exits 0 deliberately. A container whose discovery threw
# is a different thing entirely: its assertions are absent from $result.Tests,
# absent from the Assertions breakdown, and absent from CasesRun - while
# CasesDefined still counts them, because CasesDefined is parsed from the source
# and does not know the file failed to load. The score then divides a smaller
# numerator by a smaller denominator and looks entirely normal.
#
# This is not hypothetical. Help.Tests.ps1 lost its whole container to a member
# access on an empty array during discovery, and the run printed a score with
# every one of its assertions silently missing. Pester said "Container failed: 1"
# in its own output and nothing downstream read it.
#
# Same rule as zero cases, one level up: not run is not a pass, and the honest
# response to a measurement that did not happen is to refuse to report one.
# ---------------------------------------------------------------------------
# ErrorRecord, NOT Result. A container holding a failing test also reports
# Result = 'Failed', and treating that as a missing measurement would turn every
# red run into a crash - which is the opposite of the contract this runner
# states three comments above. Only a container-level ErrorRecord means the file
# itself did not run.
$failedContainers = @($result.Containers | Where-Object { @($_.ErrorRecord).Count -gt 0 })
if ($failedContainers.Count -gt 0) {
    $names = @($failedContainers | ForEach-Object {
            $reason = ($_.ErrorRecord[0].Exception.Message -split "`n")[0]
            "$(Split-Path -Leaf $_.Item.FullName): $reason"
        })
    throw ("$($failedContainers.Count) suite container(s) failed to run, so no score is being reported. " +
        "CasesDefined counts their assertions and CasesRun cannot, which makes any percentage " +
        "meaningless rather than merely low. Containers: $($names -join ' | ')")
}

# Per-assertion breakdown, keyed by the UNEXPANDED path so that every case of a
# -ForEach It groups under the assertion that generated them. An assertion
# missing from this list entirely produced no cases and did not apply to this
# target - which is a different statement from passing, and the reason the list
# is here.
$assertions = @(
    $result.Tests |
        Where-Object { $_.Result -ne 'NotRun' } |
        Group-Object -Property { $_.Path -join '.' } |
        Sort-Object Name |
        ForEach-Object {
            [pscustomobject]@{
                Name   = $_.Name
                Ran    = $_.Count
                Passed = @($_.Group | Where-Object { $_.Result -eq 'Passed' }).Count
                Failed = @($_.Group | Where-Object { $_.Result -eq 'Failed' }).Count
            }
        }
)

$summary = [pscustomobject]@{
    Target      = $target
    Tags        = $Tag
    RunAt       = (Get-Date).ToString('o')
    Total       = $result.TotalCount
    Passed      = $result.PassedCount
    Failed      = $result.FailedCount
    Skipped     = $result.SkippedCount
    NotRun      = $result.NotRunCount
    # What actually executed. Total counts tests filtered out by -Tag, and says
    # nothing about how many of the selected assertions had anything to run
    # against.
    CasesRun    = $result.PassedCount + $result.FailedCount
    # The stable denominator. Read from the suite's source, per selected tag,
    # without consulting the target - so two differently shaped targets graded
    # with the same tags report the SAME CasesDefined and may report different
    # CasesRun. Compare runs on CasesDefined; report CasesRun beside it.
    CasesDefined = $casesDefined
    # [pscustomobject], not the ordered dictionary itself: ConvertTo-Json
    # refuses OrderedDictionary outright - "Keys must be strings" - even when
    # every key is a string, and the result file is the artifact the harness
    # reads.
    CasesDefinedPerTag = [pscustomobject]$definedPerTag
    # The configuration this score was taken under, with the provenance of every
    # value. IsMeasuredConfiguration is true when every one came from a built-in
    # default - which is the configuration every published number in this
    # repository was taken under.
    Settings           = $settings
    # Denominator is what actually executed. TotalCount includes tests filtered
    # out by -Tag (NotRun), so dividing by Total - Skipped charged the score for
    # assertions the caller deliberately did not select: a Universal,HouseStyle
    # run scored 85% instead of 92% purely because RequiresBuild was excluded.
    ScorePct    = if (($result.PassedCount + $result.FailedCount) -gt 0) {
                      [math]::Round(100 * $result.PassedCount / ($result.PassedCount + $result.FailedCount), 2)
                  } else { 0 }
    Assertions  = $assertions
    Failures    = @($result.Failed | ForEach-Object {
                      [pscustomobject]@{
                          Name    = $_.ExpandedPath
                          Message = ($_.ErrorRecord.Exception.Message -split "`n")[0]
                      }
                  })
}

$summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ResultPath -Encoding utf8
Write-Host ''
Write-Host ("Conformance: $($summary.Passed)/$($summary.CasesRun) ($($summary.ScorePct)%) " +
    "across $(@($assertions).Count) assertions  ->  $ResultPath")
Write-Host ("cases-defined: $($summary.CasesDefined)  (" +
    ((@($definedPerTag.Keys) | ForEach-Object { '{0}={1}' -f $_, $definedPerTag[$_] }) -join ', ') +
    ")   cases-run: $($summary.CasesRun)")

$summary

# Invoke-Pester sets $LASTEXITCODE to the failure count even with Run.Throw and
# Run.Exit both off, so a red conformance run left this script looking like a
# crash - the exact opposite of the contract three lines of comment above claim.
# A harness that checks exit codes would have treated every red run as a broken
# runner and never read the score it wrote.
#
# A red run is data. Say so in the exit code, and give the callers who really do
# want a red run to fail a pipeline step an explicit way to ask.
if ($PassExitCode) { exit $summary.Failed }
exit 0
