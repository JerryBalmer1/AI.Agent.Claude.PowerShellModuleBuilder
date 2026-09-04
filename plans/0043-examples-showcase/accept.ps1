#requires -Version 7.0
<#
.SYNOPSIS
    Acceptance test for pass 0043 - ecosystem examples showcase.
.DESCRIPTION
    Written and observed RED before any example work, per section 2 of the pass
    prompt. It reads the four ecosystem WORKING TREES and exits non-zero unless
    every matrix row of section 3 is present as four committed artifacts, and
    unless each repository's top-level README points a first-time reader at them
    within the first screen.

    "Committed" is asserted with `git ls-files`, not `Test-Path`. A generated
    artifact sitting untracked in a working tree is exactly the failure this
    pass is meant to prevent: the showcase has to survive a fresh clone.

    The matrix below is the definition of done. Grading is per row, so a row
    that is absent names itself rather than collapsing the whole run into one
    unhelpful failure.
.PARAMETER WorkspaceRoot
    Directory holding the five repositories. Defaults to the parent of the
    harness repository, which is how the workspace is laid out.
.PARAMETER FailCheck
    Report the findings and always exit 1. Used to see the red output without
    relying on the tree actually being incomplete.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $WorkspaceRoot,

    [Parameter()]
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $WorkspaceRoot) {
    $harnessRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $WorkspaceRoot = Split-Path -Parent $harnessRoot
}

# ---------------------------------------------------------------------------
# The matrix. One entry per row of section 3; Html/Png/Input are repo-relative.
# ---------------------------------------------------------------------------
$Matrix = [ordered]@{
    'PSGraphRender'       = @{
        Hero = 'examples/layouts/foundation.png'
        Rows = @(
            @{ Id = 'R-layouts/foundation'; Input = 'examples/input/ecosystem-viewmodel.json'; Html = 'examples/layouts/foundation.html'; Png = 'examples/layouts/foundation.png' }
            @{ Id = 'R-layouts/testorder'; Input = 'examples/input/ecosystem-viewmodel.json'; Html = 'examples/layouts/testorder.html'; Png = 'examples/layouts/testorder.png' }
            @{ Id = 'R-layouts/callflow'; Input = 'examples/input/ecosystem-viewmodel.json'; Html = 'examples/layouts/callflow.html'; Png = 'examples/layouts/callflow.png' }
            @{ Id = 'R-theme/default'; Input = 'examples/input/ecosystem-viewmodel.json'; Html = 'examples/theme/default.html'; Png = 'examples/theme/default.png' }
            @{ Id = 'R-theme/contrast'; Input = 'examples/input/ecosystem-viewmodel.json'; Html = 'examples/theme/contrast.html'; Png = 'examples/theme/contrast.png' }
            @{ Id = 'R-links'; Input = 'examples/input/links-viewmodel.json'; Html = 'examples/links/editor-links.html'; Png = 'examples/links/editor-links.png' }
        )
    }
    'PSGraphRenderToHtml' = @{
        Hero = 'examples/nesting/nested.png'
        Rows = @(
            @{ Id = 'H-nesting'; Input = 'examples/input/nested-graph.json'; Html = 'examples/nesting/nested.html'; Png = 'examples/nesting/nested.png' }
            @{ Id = 'H-precedence/builtins'; Input = 'examples/input/precedence-graph.json'; Html = 'examples/precedence/builtins.html'; Png = 'examples/precedence/builtins.png' }
            @{ Id = 'H-precedence/file'; Input = 'examples/input/precedence-graph.json'; Html = 'examples/precedence/file-defaults.html'; Png = 'examples/precedence/file-defaults.png' }
            @{ Id = 'H-precedence/explicit'; Input = 'examples/input/precedence-graph.json'; Html = 'examples/precedence/explicit.html'; Png = 'examples/precedence/explicit.png' }
        )
    }
    'PSAzureDevOpsGraph'  = @{
        Hero = 'examples/claudetesting.png'
        Rows = @(
            @{ Id = 'A-live'; Input = 'examples/input/claudetesting-graph.json'; Html = 'examples/claudetesting.html'; Png = 'examples/claudetesting.png' }
        )
    }
    'PSTerraformGraph'    = @{
        Hero = 'examples/claudetestingterraform.png'
        Rows = @(
            @{ Id = 'T-fixture'; Input = 'examples/input/claudetestingterraform-graph.json'; Html = 'examples/claudetestingterraform.html'; Png = 'examples/claudetestingterraform.png' }
        )
    }
}

# Headings that mean "internals". The Examples section must come before the
# first of them: a reader who has to scroll past the architecture to find the
# pictures has not been pointed at them within the first screen.
$InternalsPattern = '^#{2,3}\s+.*(architect|internal|how it works|design|contract|development|testing|vendor|' +
    'view model|backend|build|command|reasoning|repositor|option|schema|graph shape)'

$failures = [System.Collections.Generic.List[string]]::new()
function Add-Failure([string] $Repo, [string] $Text) {
    $script:failures.Add(('[{0}] {1}' -f $Repo, $Text))
}

function Get-TrackedFiles([string] $RepoPath) {
    Push-Location $RepoPath
    try {
        $out = & git ls-files 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        $set = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($line in $out) { if ($line) { [void]$set.Add($line.Replace('\', '/')) } }
        return $set
    }
    finally { Pop-Location }
}

# A link resolves when it points at a tracked file. Anchors, external URLs and
# in-page fragments are not this test's business.
function Test-RelativeLink {
    param([string] $Link, [string] $FromRelDir, [System.Collections.Generic.HashSet[string]] $Tracked)

    if ([string]::IsNullOrWhiteSpace($Link)) { return $false }
    if ($Link -match '^(https?:|mailto:|#)') { return $true }

    $clean = ($Link -split '#')[0]
    if ([string]::IsNullOrWhiteSpace($clean)) { return $true }
    $clean = [uri]::UnescapeDataString($clean)

    $combined = if ($FromRelDir) { "$FromRelDir/$clean" } else { $clean }

    # Normalise ./ and ../ without touching the filesystem.
    $parts = [System.Collections.Generic.List[string]]::new()
    foreach ($seg in ($combined -replace '\\', '/' -split '/')) {
        if ($seg -eq '' -or $seg -eq '.') { continue }
        if ($seg -eq '..') { if ($parts.Count -gt 0) { $parts.RemoveAt($parts.Count - 1) }; continue }
        $parts.Add($seg)
    }
    $resolved = $parts -join '/'
    if ($Tracked.Contains($resolved)) { return $true }

    # A link to a directory is legitimate markdown, and `git ls-files` lists no
    # directories - only their contents. Treat it as resolving when the tree
    # holds anything beneath it. Without this the checker fails a correct link.
    $prefix = $resolved.TrimEnd('/') + '/'
    foreach ($t in $Tracked) {
        if ($t.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

Write-Host ''
Write-Host '=== PASS 0043 ACCEPTANCE ===' -ForegroundColor Cyan
Write-Host "workspace: $WorkspaceRoot"
Write-Host ''

foreach ($repo in $Matrix.Keys) {
    $spec = $Matrix[$repo]
    $repoPath = Join-Path $WorkspaceRoot $repo

    if (-not (Test-Path -LiteralPath $repoPath -PathType Container)) {
        Add-Failure $repo 'repository directory not found'
        continue
    }

    $tracked = Get-TrackedFiles $repoPath
    if ($null -eq $tracked) {
        Add-Failure $repo 'not a git repository (git ls-files failed)'
        continue
    }

    Write-Host "--- $repo ---" -ForegroundColor Yellow

    # -- matrix rows: four committed artifacts each -------------------------
    foreach ($row in $spec.Rows) {
        foreach ($kind in 'Input', 'Html', 'Png') {
            $rel = $row[$kind]
            $full = Join-Path $repoPath $rel
            if (-not $tracked.Contains($rel)) {
                Add-Failure $repo ('{0}: {1} not committed ({2})' -f $row.Id, $kind.ToLower(), $rel)
            }
            elseif (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                Add-Failure $repo ('{0}: {1} missing on disk ({2})' -f $row.Id, $kind.ToLower(), $rel)
            }
            elseif ((Get-Item -LiteralPath $full).Length -eq 0) {
                Add-Failure $repo ('{0}: {1} is empty ({2})' -f $row.Id, $kind.ToLower(), $rel)
            }
        }
    }

    # -- examples index -----------------------------------------------------
    $indexRel = 'examples/README.md'
    $indexPath = Join-Path $repoPath $indexRel
    if (-not $tracked.Contains($indexRel)) {
        Add-Failure $repo 'examples/README.md not committed'
    }
    else {
        $index = Get-Content -LiteralPath $indexPath -Raw

        # One table row per example, each carrying a paste-able command.
        foreach ($row in $spec.Rows) {
            $htmlLeaf = [regex]::Escape((Split-Path -Leaf $row.Html))
            if ($index -notmatch $htmlLeaf) {
                Add-Failure $repo ('examples index has no row for {0} (no mention of {1})' -f $row.Id, (Split-Path -Leaf $row.Html))
            }
        }

        $regenCount = ([regex]::Matches($index, 'pwsh\s+-NoProfile')).Count
        if ($regenCount -lt $spec.Rows.Count) {
            Add-Failure $repo ('examples index has {0} `pwsh -NoProfile` regeneration commands; needs one per example ({1})' -f $regenCount, $spec.Rows.Count)
        }

        foreach ($m in [regex]::Matches($index, '\[[^\]]*\]\(([^)]+)\)')) {
            $link = $m.Groups[1].Value.Trim()
            if (-not (Test-RelativeLink -Link $link -FromRelDir 'examples' -Tracked $tracked)) {
                Add-Failure $repo ('examples index link does not resolve: {0}' -f $link)
            }
        }
    }

    # -- top-level README ---------------------------------------------------
    $readmeRel = 'README.md'
    $readmePath = Join-Path $repoPath $readmeRel
    if (-not $tracked.Contains($readmeRel)) {
        Add-Failure $repo 'README.md not committed'
        continue
    }

    $readme = Get-Content -LiteralPath $readmePath -Raw
    $readmeLines = Get-Content -LiteralPath $readmePath

    # Hero image: an image reference that resolves to a committed file.
    $heroFound = $false
    foreach ($m in [regex]::Matches($readme, '!\[[^\]]*\]\(([^)]+)\)')) {
        $target = $m.Groups[1].Value.Trim()
        if (Test-RelativeLink -Link $target -FromRelDir '' -Tracked $tracked) {
            if ($target -notmatch '^https?:') { $heroFound = $true; break }
        }
    }
    if (-not $heroFound) {
        Add-Failure $repo 'README has no hero image resolving to a committed file'
    }
    elseif (-not $tracked.Contains($spec.Hero)) {
        Add-Failure $repo ('declared hero image not committed: {0}' -f $spec.Hero)
    }

    # Examples section, and it must precede the first internals heading.
    $examplesIdx = -1
    $internalsIdx = -1
    for ($i = 0; $i -lt $readmeLines.Count; $i++) {
        $line = $readmeLines[$i]
        if ($examplesIdx -lt 0 -and $line -match '^#{2,3}\s+Examples\b') { $examplesIdx = $i }
        if ($internalsIdx -lt 0 -and $line -match $InternalsPattern) { $internalsIdx = $i }
    }

    if ($examplesIdx -lt 0) {
        Add-Failure $repo 'README has no "## Examples" section'
    }
    elseif ($internalsIdx -ge 0 -and $examplesIdx -gt $internalsIdx) {
        Add-Failure $repo ('README "## Examples" (line {0}) comes after an internals heading (line {1}: {2})' -f
            ($examplesIdx + 1), ($internalsIdx + 1), $readmeLines[$internalsIdx].Trim())
    }

    foreach ($m in [regex]::Matches($readme, '\[[^\]]*\]\(([^)]+)\)')) {
        $link = $m.Groups[1].Value.Trim()
        if (-not (Test-RelativeLink -Link $link -FromRelDir '' -Tracked $tracked)) {
            Add-Failure $repo ('README link does not resolve: {0}' -f $link)
        }
    }
}

Write-Host ''
if ($failures.Count -eq 0 -and -not $FailCheck) {
    Write-Host 'ACCEPT: GREEN - every matrix row committed, every README points at it.' -ForegroundColor Green
    exit 0
}

Write-Host ('ACCEPT: RED - {0} finding(s)' -f $failures.Count) -ForegroundColor Red
foreach ($f in $failures) { Write-Host "  $f" }
if ($FailCheck) { Write-Host '  (-FailCheck forced a non-zero exit)' }
exit 1
