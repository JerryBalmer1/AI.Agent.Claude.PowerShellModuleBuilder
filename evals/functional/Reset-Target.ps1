#Requires -Version 7.2

<#
.SYNOPSIS
    Materialises the seed into a run directory as a fresh git repository.

.DESCRIPTION
    The wipe half of wipe-and-rebuild. Copies evals/functional/seed/ into a
    destination, runs git init, and makes one commit. The result is the exact
    clean slate a baseline run starts from.

    WHAT IT NEVER TOUCHES. The real PSAzureDevOpsGraph repository. That receives
    only a promoted run, by hand, later, and never from this script. To make
    that difficult rather than merely discouraged, the destination must be under
    scratch/runs/ and the script refuses anything else - see Test-DestinationAllowed.
    A path-shaped guard is worth more than a sentence in a README, because the
    accident this prevents is a mistyped path, and a mistyped path does not read
    documentation.

    An existing non-empty destination is refused unless -Force, because the
    normal reason for one is that a run is already there and someone is about to
    lose it.

    NO NETWORK. This makes no Azure DevOps call and needs no PAT. It reads the
    seed and writes a directory.

.PARAMETER Destination
    Where to materialise the seed. Must be under scratch/runs/.

.PARAMETER Force
    Replace a destination that exists and is non-empty.

.PARAMETER SeedPath
    The seed to materialise. Defaults to evals/functional/seed/.

.EXAMPLE
    pwsh -NoProfile -File evals/functional/Reset-Target.ps1 -Destination scratch/runs/002-first-resolver
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Destination,

    [switch]$Force,

    [string]$SeedPath = (Join-Path $PSScriptRoot 'seed')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).ProviderPath
$AllowedRoot = Join-Path $RepoRoot 'scratch' 'runs'

function Test-DestinationAllowed {
    <#
        True only when $Candidate is at or below scratch/runs/ in this
        repository.

        Compared after normalisation, so that a path reaching outside through
        .. segments is rejected on what it resolves to rather than on how it is
        spelled. A prefix test on the raw string would accept
        scratch/runs/../../../PSAzureDevOpsGraph, which is the exact accident
        this exists to prevent.
    #>
    param([string]$Candidate)

    $full = [IO.Path]::GetFullPath((Join-Path $RepoRoot $Candidate))
    if ([IO.Path]::IsPathRooted($Candidate)) {
        $full = [IO.Path]::GetFullPath($Candidate)
    }
    $allowed = [IO.Path]::GetFullPath($AllowedRoot)

    $sep = [IO.Path]::DirectorySeparatorChar
    $allowedPrefix = $allowed.TrimEnd($sep) + $sep

    # Case-insensitive: this is Windows, where two spellings of one path are the
    # same path.
    $full.StartsWith($allowedPrefix, [StringComparison]::OrdinalIgnoreCase)
}

if (-not (Test-Path -LiteralPath $SeedPath -PathType Container)) {
    throw "Seed not found at $SeedPath"
}

if (-not (Test-DestinationAllowed -Candidate $Destination)) {
    throw @"
Refusing to reset '$Destination'.

The destination must be under scratch/runs/. This script materialises a clean
slate by deleting and recreating a directory, and the real PSAzureDevOpsGraph
repository must never be a candidate for that. A promoted run is copied there by
hand, deliberately, and never by this script.

Allowed root: $AllowedRoot
"@
}

$fullDest = [IO.Path]::GetFullPath((Join-Path $RepoRoot $Destination))
if ([IO.Path]::IsPathRooted($Destination)) { $fullDest = [IO.Path]::GetFullPath($Destination) }

if (Test-Path -LiteralPath $fullDest) {
    $existing = @(Get-ChildItem -LiteralPath $fullDest -Force -ErrorAction SilentlyContinue)
    if ($existing.Count -gt 0 -and -not $Force) {
        throw @"
Refusing to reset '$Destination': it exists and is not empty ($($existing.Count) entries).

The usual reason for a non-empty destination is that a run is already there.
Re-run with -Force to replace it.
"@
    }
    if ($existing.Count -gt 0) {
        Write-Host "  replacing existing destination ($($existing.Count) entries)"
        Remove-Item -LiteralPath $fullDest -Recurse -Force
    }
}

New-Item -ItemType Directory -Path $fullDest -Force | Out-Null

# Copy the seed, contents only, preserving bytes. Copy-Item rather than any
# text-mode operation: the seed's line endings are part of what it is.
$seedFull = (Resolve-Path -LiteralPath $SeedPath).ProviderPath
$copied = 0
foreach ($item in (Get-ChildItem -LiteralPath $seedFull -Force -Recurse -File)) {
    $rel = $item.FullName.Substring($seedFull.Length).TrimStart([IO.Path]::DirectorySeparatorChar)
    $target = Join-Path $fullDest $rel
    $targetDir = Split-Path -Parent $target
    if ($targetDir -and -not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    Copy-Item -LiteralPath $item.FullName -Destination $target -Force
    $copied++
}

Push-Location $fullDest
try {
    & git init --quiet --initial-branch=main 2>&1 | Out-Null
    & git add -A 2>&1 | Out-Null
    # A local identity, so the commit does not depend on global git config being
    # set on whichever machine runs this.
    & git -c user.name='Reset-Target' -c user.email='reset-target@localhost' `
        commit --quiet -m 'Seed' 2>&1 | Out-Null
    $sha = (& git rev-parse HEAD).Trim()
    $tracked = @(& git ls-files)
}
finally { Pop-Location }

Write-Host "Reset-Target"
Write-Host "  seed        : $seedFull"
Write-Host "  destination : $fullDest"
Write-Host "  files copied: $copied"
Write-Host "  commit      : $sha"
Write-Host "  tracked     : $($tracked.Count) files"
foreach ($t in $tracked) { Write-Host "                $t" }

[pscustomobject]@{
    Destination = $fullDest
    FilesCopied = $copied
    Commit      = $sha
    Tracked     = $tracked
}
