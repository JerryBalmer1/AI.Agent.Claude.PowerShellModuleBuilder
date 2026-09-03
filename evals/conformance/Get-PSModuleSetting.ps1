#Requires -Version 7.2
<#
.SYNOPSIS
    Resolve psmodule.settings.psd1 at a target root, with precedence and a
    refusal for any key not on the enumerated list.
.DESCRIPTION
    One reader, used by every caller that honours the settings file, so that the
    precedence rule and the known-key list exist in exactly one place. Two
    readers that must agree on what a setting means will drift, and the drift is
    silent.

    PRECEDENCE, highest first:

        1. an explicit parameter passed by the caller
        2. psmodule.settings.psd1 at the target root
        3. the built-in default

    THE DEFAULTS ARE THE MEASURED CONFIGURATION. Every score this project has
    published was taken with the values in $KnownSetting below and no settings
    file present. That is the reason they are what they are, and it is the
    property that makes a default safe to leave alone: a target that ships no
    settings file is graded exactly as every recorded run was graded. Changing a
    default is therefore a change to what the published numbers mean, and is a
    release-note item rather than a tidy-up.

    AN UNKNOWN KEY IS A REFUSAL, NAMING IT. Not a warning, not ignored. A
    settings file is the one place a user states an intention to the grader, and
    silently discarding a misspelled key means the grader ran with settings the
    user believes it did not have. `CoverageThresold = 90` would otherwise be
    graded at 75 while the file on disk says 90, and nothing in the output would
    disagree with the file.

    Reads with Import-PowerShellDataFile, which parses .psd1 as restricted data
    and does not execute it. A settings file is untrusted input like any other
    file in a target repository.

.PARAMETER Path
    Repository root of the target. The settings file, if any, is
    <Path>/psmodule.settings.psd1.
.PARAMETER Override
    Settings the caller is passing explicitly, as a hashtable. These win over
    the file. Unknown keys here are refused on the same terms - a caller typo is
    no more acceptable than a user's.
.EXAMPLE
    $Path     = 'C:/repos/PSModuleGraph'
    $Override = @{ CoverageThreshold = 90 }

    $settings = try {

        $params = @{
            Path     = $Path
            Override = $Override
        }

        ./Get-PSModuleSetting.ps1 @params

    }
    catch {
        Write-Error "Settings could not be resolved: $_"
        $null
    }

    $settings.Values.CoverageThreshold
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Path,

    [hashtable] $Override = @{}
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# The enumerated known keys. This list IS the contract. A key not here is
# refused, which is why adding one is a deliberate act with a release note
# attached rather than an edit to a config schema nobody reads.
# ---------------------------------------------------------------------------
$KnownSetting = [ordered]@{
    CoverageThreshold = @{
        Default  = 75
        Validate = { param($v) $v -is [int] -and $v -ge 0 -and $v -le 100 }
        Expected = 'an integer from 0 to 100'
        Means    = 'the line-coverage percentage below which the Test task throws'
        # What flipping it invalidates. Stated per key, because a switch whose
        # consequence is not written down gets flipped to make a build green.
        Invalidates = 'every published conformance score. The recorded runs were taken at 75; a target graded at another value is not on the same scale and may not be compared to them.'
    }
    ModuleProfile = @{
        Default  = 'script'
        Validate = { param($v) $v -in 'script', 'hybrid' }
        Expected = "'script' or 'hybrid'"
        Means    = "which build shape the module uses. 'script' is the measured one; 'hybrid' is a PLACEHOLDER for a module carrying compiled assemblies and is not implemented"
        Invalidates = "every claim this plugin makes, all of which were measured against 'script' modules. 'hybrid' is reserved, not supported: nothing has been built or graded under it, and setting it asserts a capability that does not exist yet."
    }
    CompletionCacheDefault = @{
        Default  = $false
        Validate = { param($v) $v -is [bool] }
        Expected = '$true or $false'
        Means    = 'whether generated argument completers cache their candidate list in a session variable by default'
        Invalidates = 'nothing that has been measured - no scored run has used a completer. It changes generated code, so a module built with it on and one built with it off are different artifacts, and a score is about one of them.'
    }
}

$settingsPath = Join-Path $Path 'psmodule.settings.psd1'
$fromFile = @{}
$fileFound = Test-Path -LiteralPath $settingsPath

if ($fileFound) {
    try {
        $data = Import-PowerShellDataFile -LiteralPath $settingsPath -ErrorAction Stop
    }
    catch {
        throw "psmodule.settings.psd1 at '$settingsPath' does not parse as PowerShell data: $($_.Exception.Message)"
    }

    foreach ($key in $data.Keys) {
        if (-not $KnownSetting.Contains($key)) {
            $known = ($KnownSetting.Keys -join ', ')
            throw ("UNKNOWN KEY: refused. '$key' in '$settingsPath' is not a setting this plugin has. " +
                "Known keys: $known. A misspelled key silently ignored means the grader ran with settings " +
                'the file says it did not have, so this is a stop rather than a warning.')
        }
        $spec = $KnownSetting[$key]
        if (-not (& $spec.Validate $data[$key])) {
            throw ("INVALID VALUE: refused. '$key' in '$settingsPath' is '$($data[$key])'; expected $($spec.Expected).")
        }
        $fromFile[$key] = $data[$key]
    }
}

foreach ($key in $Override.Keys) {
    if (-not $KnownSetting.Contains($key)) {
        throw ("UNKNOWN KEY: refused. '$key' was passed as an override and is not a setting this plugin has. " +
            "Known keys: $($KnownSetting.Keys -join ', ').")
    }
    if (-not (& $KnownSetting[$key].Validate $Override[$key])) {
        throw ("INVALID VALUE: refused. Override '$key' is '$($Override[$key])'; expected $($KnownSetting[$key].Expected).")
    }
}

# Resolution, and the provenance of every value alongside it. A record that
# states a setting without saying where it came from cannot be used to reproduce
# the run that produced it.
$values = [ordered]@{}
$source = [ordered]@{}
foreach ($key in $KnownSetting.Keys) {
    if ($Override.ContainsKey($key)) {
        $values[$key] = $Override[$key]
        $source[$key] = 'parameter'
    }
    elseif ($fromFile.ContainsKey($key)) {
        $values[$key] = $fromFile[$key]
        $source[$key] = 'file'
    }
    else {
        $values[$key] = $KnownSetting[$key].Default
        $source[$key] = 'default'
    }
}

[pscustomobject]@{
    # [pscustomobject], not the ordered dictionary: ConvertTo-Json refuses
    # OrderedDictionary outright - "Keys must be strings" - even when every key
    # is one, and these go into result.json.
    Values     = [pscustomobject]$values
    Source     = [pscustomobject]$source
    FilePath   = if ($fileFound) { $settingsPath } else { $null }
    FileFound  = $fileFound
    # True when every value came from a built-in default, which is the
    # configuration every published score was taken under.
    IsMeasuredConfiguration = @($source.Values | Where-Object { $_ -ne 'default' }).Count -eq 0
}
