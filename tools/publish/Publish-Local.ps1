#Requires -Version 7.2
<#
.SYNOPSIS
    Stage this repository's plugin as a local Claude Code marketplace under
    scratch/, and print the two commands the operator pastes into Claude Code.

.DESCRIPTION
    Copies .claude-plugin/plugin.json, skills/ and commands/ into a plugin
    directory beside a generated marketplace.json whose source is the relative
    path './<plugin>'. Nothing is pushed, tagged, or written outside the scratch
    root. Re-running restages from scratch, so the task is idempotent.

    Validation is a separate function called by both entry points, so that
    -ValidateOnly exercises exactly the code the staging path runs. That is what
    makes the falsification meaningful: corrupt a staged byte, run -ValidateOnly,
    and the red comes from the same validator that reported green a moment ago.

.PARAMETER ValidateOnly
    Validate the already-staged tree and exit. Does not copy, does not repair.
    Used by the falsification control.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path,
    [string]$StageRoot,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path $RepoRoot).Path
$scratch  = Join-Path $RepoRoot 'scratch'
if (-not $StageRoot) { $StageRoot = Join-Path $scratch 'local-marketplace' }

# --- Safety rail -----------------------------------------------------------
# METHOD.md: destructive work happens in a disposable copy, never in place.
# This script deletes and rewrites its stage root, so it refuses any path that
# is not under scratch/. Compared after normalising, so ../ cannot walk out.
$normStage   = [IO.Path]::GetFullPath($StageRoot)
$normScratch = [IO.Path]::GetFullPath($scratch)
if ($normStage -ne $normScratch -and
    -not $normStage.StartsWith($normScratch + [IO.Path]::DirectorySeparatorChar)) {
    throw "REFUSED: stage root '$normStage' is not under the scratch root '$normScratch'. This script only ever writes under scratch/."
}

$pluginName = 'psmodule'
$marketName = 'psmodule-local'
$pluginDir  = Join-Path $normStage $pluginName
$marketFile = Join-Path $normStage '.claude-plugin/marketplace.json'
$pluginFile = Join-Path $pluginDir '.claude-plugin/plugin.json'

function Test-StagedTree {
    <#
        Validates the staged marketplace. Returns a list of complaint strings;
        empty means it agrees. Never throws on a bad file - a validator that
        dies on the first problem reports one defect where there are three.
    #>
    param([string]$Stage, [string]$Plugin)

    $bad = [Collections.Generic.List[string]]::new()

    $mFile = Join-Path $Stage '.claude-plugin/marketplace.json'
    $pFile = Join-Path $Stage "$Plugin/.claude-plugin/plugin.json"

    foreach ($f in @($mFile, $pFile)) {
        if (-not (Test-Path -LiteralPath $f)) { $bad.Add("missing: $f"); continue }
        try { $null = Get-Content -LiteralPath $f -Raw | ConvertFrom-Json }
        catch { $bad.Add("does not parse as JSON: $f -- $($_.Exception.Message)") }
    }

    if ($bad.Count -eq 0) {
        $m = Get-Content -LiteralPath $mFile -Raw | ConvertFrom-Json
        if (-not $m.name)    { $bad.Add('marketplace.json has no name') }
        if (-not $m.plugins) { $bad.Add('marketplace.json lists no plugins') }
        else {
            foreach ($entry in @($m.plugins)) {
                if (-not $entry.source) {
                    $bad.Add("marketplace entry '$($entry.name)' has no source"); continue
                }
                if ($entry.source -notmatch '^\./') {
                    $bad.Add("marketplace entry '$($entry.name)' source '$($entry.source)' is not a relative './' path")
                }
                $resolved = Join-Path $Stage ($entry.source -replace '^\./', '')
                if (-not (Test-Path -LiteralPath $resolved)) {
                    $bad.Add("marketplace entry '$($entry.name)' source '$($entry.source)' does not exist at $resolved")
                }
            }
        }
        $p = Get-Content -LiteralPath $pFile -Raw | ConvertFrom-Json
        if (-not $p.name)    { $bad.Add('plugin.json has no name') }
        if (-not $p.version) { $bad.Add('plugin.json has no version') }
    }

    # A staged plugin with no skills is a staging bug, not a valid plugin.
    $skillCount = @(Get-ChildItem (Join-Path $Stage "$Plugin/skills") -Directory -ErrorAction SilentlyContinue).Count
    $cmdCount   = @(Get-ChildItem (Join-Path $Stage "$Plugin/commands") -Filter *.md -ErrorAction SilentlyContinue).Count
    if ($skillCount -eq 0) { $bad.Add('staged plugin contains no skills') }
    if ($cmdCount   -eq 0) { $bad.Add('staged plugin contains no commands') }

    , $bad
}

function Test-CommittedMarketplace {
    <#
        Validates the REAL, committed .claude-plugin/marketplace.json - the file
        a stranger's `/plugin marketplace add` actually reads.

        Before pass 0030 this repository had no such file, so the only thing
        this script could exercise was the marketplace it generated itself, and
        a generated file proves nothing about a committed one. Both are checked
        now. Returns complaint strings; empty means it agrees.
    #>
    param([string]$Root)

    $bad = [Collections.Generic.List[string]]::new()
    $mFile = Join-Path $Root '.claude-plugin/marketplace.json'
    $pFile = Join-Path $Root '.claude-plugin/plugin.json'

    if (-not (Test-Path -LiteralPath $mFile)) {
        $bad.Add("missing: $mFile")
        , $bad
        return
    }
    try { $m = Get-Content -LiteralPath $mFile -Raw | ConvertFrom-Json }
    catch {
        $bad.Add("does not parse as JSON: $mFile -- $($_.Exception.Message)")
        , $bad
        return
    }
    $p = Get-Content -LiteralPath $pFile -Raw | ConvertFrom-Json

    if (-not $m.name)    { $bad.Add('committed marketplace.json has no name') }
    if (-not $m.plugins) { $bad.Add('committed marketplace.json lists no plugins'); , $bad; return }

    $entries = @($m.plugins)
    $mine = @($entries | Where-Object { $_.name -eq $p.name })
    if ($mine.Count -ne 1) {
        $bad.Add("committed marketplace.json has $($mine.Count) entries named '$($p.name)'; expected exactly 1")
    }

    foreach ($entry in $entries) {
        if (-not $entry.source) { $bad.Add("committed entry '$($entry.name)' has no source"); continue }
        if ($entry.source -notmatch '^\./') {
            $bad.Add("committed entry '$($entry.name)' source '$($entry.source)' is not a relative './' path")
        }
        # './' means the repository itself is the plugin. Resolve it and require
        # the plugin manifest to actually be there - a source that resolves to a
        # directory with no plugin.json installs nothing.
        $rel = ($entry.source -replace '^\./', '')
        $resolved = if ($rel) { Join-Path $Root $rel } else { $Root }
        if (-not (Test-Path -LiteralPath $resolved)) {
            $bad.Add("committed entry '$($entry.name)' source '$($entry.source)' does not exist at $resolved")
        }
        elseif (-not (Test-Path -LiteralPath (Join-Path $resolved '.claude-plugin/plugin.json'))) {
            $bad.Add("committed entry '$($entry.name)' source '$($entry.source)' has no .claude-plugin/plugin.json")
        }
        # The version a consumer is offered and the version the manifest states
        # must be the same number. Decision 0013: a tag whose manifest disagrees
        # with it is a defect, and this is where that is caught.
        if ($entry.name -eq $p.name -and $entry.version -and $entry.version -ne $p.version) {
            $bad.Add("committed entry '$($entry.name)' version '$($entry.version)' disagrees with plugin.json version '$($p.version)'")
        }
    }

    , $bad
}

if ($ValidateOnly) {
    Write-Host "Validating the staged tree at $normStage (no copy, no repair)."
    # Both helpers return a List via the `, $list` idiom, so they are assigned
    # and enumerated with foreach - piping unrolls only the outer array and
    # hands the List itself down as a single item.
    $complaints = [Collections.Generic.List[string]]::new()
    foreach ($c in (Test-StagedTree -Stage $normStage -Plugin $pluginName)) { $complaints.Add($c) }
    foreach ($c in (Test-CommittedMarketplace -Root $RepoRoot)) { $complaints.Add("committed: $c") }
    if ($complaints.Count) {
        Write-Host ''
        Write-Host 'VALIDATION FAILED:'
        $complaints | ForEach-Object { Write-Host "  - $_" }
        exit 1
    }
    Write-Host 'Validation passed.'
    exit 0
}

# --- Stage -----------------------------------------------------------------
Write-Host "Repository: $RepoRoot"
Write-Host "Staging to: $normStage"

if (Test-Path -LiteralPath $normStage) { Remove-Item -LiteralPath $normStage -Recurse -Force }
New-Item -ItemType Directory -Path (Split-Path $marketFile -Parent) -Force | Out-Null
New-Item -ItemType Directory -Path (Split-Path $pluginFile -Parent) -Force | Out-Null

Copy-Item (Join-Path $RepoRoot '.claude-plugin/plugin.json') $pluginFile -Force
Copy-Item (Join-Path $RepoRoot 'skills')   (Join-Path $pluginDir 'skills')   -Recurse -Force
Copy-Item (Join-Path $RepoRoot 'commands') (Join-Path $pluginDir 'commands') -Recurse -Force

$src = Get-Content (Join-Path $RepoRoot '.claude-plugin/plugin.json') -Raw | ConvertFrom-Json

# The marketplace file is generated, never copied: this repository has no
# committed marketplace.json, and pass 0030 is what adds one. Publish-Real.ps1
# is the guard that says so.
$marketplace = [ordered]@{
    '$schema' = 'https://json.schemastore.org/claude-code-marketplace.json'
    name      = $marketName
    owner     = [ordered]@{ name = $src.author.name }
    plugins   = @(
        [ordered]@{
            name        = $src.name
            source      = "./$pluginName"
            description = $src.description
            version     = $src.version
        }
    )
}
$marketplace | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $marketFile -Encoding utf8

$skills   = @(Get-ChildItem (Join-Path $pluginDir 'skills') -Directory)
$commands = @(Get-ChildItem (Join-Path $pluginDir 'commands') -Filter *.md)
Write-Host "Staged $($skills.Count) skills and $($commands.Count) commands."

# --- Validate --------------------------------------------------------------
$complaints = Test-StagedTree -Stage $normStage -Plugin $pluginName
if ($complaints.Count) {
    Write-Host ''
    Write-Host 'VALIDATION FAILED (staged tree):'
    $complaints | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host 'Staged validation passed: both JSON files parse, the source path resolves, skills and commands are present.'

# --- The committed marketplace --------------------------------------------
# The file above was generated by this script, so agreeing with it proves only
# that the script agrees with itself. The file below is the one a stranger's
# `/plugin marketplace add` reads, and it is checked separately.
Write-Host ''
$committed = Join-Path $RepoRoot '.claude-plugin/marketplace.json'
$realComplaints = Test-CommittedMarketplace -Root $RepoRoot
if ($realComplaints.Count) {
    Write-Host 'VALIDATION FAILED (committed marketplace):'
    $realComplaints | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
$cm = Get-Content -LiteralPath $committed -Raw | ConvertFrom-Json
Write-Host "Committed marketplace validated: $committed"
Write-Host "  marketplace name : $($cm.name)"
foreach ($e in @($cm.plugins)) {
    Write-Host "  plugin entry     : $($e.name) $($e.version)  source '$($e.source)'"
}
Write-Host '  version agrees with .claude-plugin/plugin.json.'

# --- Optional CLI validation ----------------------------------------------
# Attempted, never required. Saying "the CLI is not on PATH" is a result; a
# missing tool silently skipping its own check is the failure this repository
# keeps recording.
$cli = Get-Command claude -ErrorAction SilentlyContinue
if ($cli) {
    Write-Host "claude CLI: $($cli.Source) - running 'claude plugin validate'."
    & claude plugin validate $pluginDir
    Write-Host "claude plugin validate exit code: $LASTEXITCODE"
} else {
    Write-Host 'claude CLI: not on PATH. Skipped the CLI schema check - the JSON checks above are what ran, and they are weaker.'
}

# --- The two commands ------------------------------------------------------
Write-Host ''
Write-Host 'Paste these two inside Claude Code (not in this shell):'
Write-Host ''
Write-Host "  /plugin marketplace add $normStage"
Write-Host "  /plugin install $($src.name)@$marketName"
Write-Host ''
Write-Host 'To remove it again:'
Write-Host ''
Write-Host "  /plugin uninstall $($src.name)@$marketName"
Write-Host "  /plugin marketplace remove $marketName"
Write-Host ''
Write-Host 'Nothing was pushed. Nothing outside scratch/ was written.'
exit 0
