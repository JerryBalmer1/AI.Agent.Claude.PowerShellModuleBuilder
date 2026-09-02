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

if ($ValidateOnly) {
    Write-Host "Validating the staged tree at $normStage (no copy, no repair)."
    $complaints = Test-StagedTree -Stage $normStage -Plugin $pluginName
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
    Write-Host 'VALIDATION FAILED:'
    $complaints | ForEach-Object { Write-Host "  - $_" }
    exit 1
}
Write-Host 'Validation passed: both JSON files parse, the source path resolves, skills and commands are present.'

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
