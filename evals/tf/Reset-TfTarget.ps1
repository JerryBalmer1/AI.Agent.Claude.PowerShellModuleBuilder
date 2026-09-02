#Requires -Version 7.2

<#
.SYNOPSIS
    Materialises the Terraform seed into a run directory as a fresh git
    repository.

.DESCRIPTION
    The wipe half of wipe-and-rebuild, for the Terraform line. Copies
    evals/tf/seed/ into a destination, runs git init, and makes one commit. The
    result is the clean slate a run starts from.

    WHAT IT NEVER TOUCHES. The real PSTerraformGraph repository. That receives
    only a promoted run, by hand, later, and never from this script. To make
    that difficult rather than merely discouraged, the destination must be under
    scratch/runs/ and anything else is refused - see Test-DestinationAllowed. A
    path-shaped guard is worth more than a sentence in a README, because the
    accident it prevents is a mistyped path, and a mistyped path does not read
    documentation.

    An existing non-empty destination is refused unless -Force, because the
    normal reason for one is that a run is already there and someone is about
    to lose it.

    NO NETWORK. This makes no Azure DevOps call and needs no token. It reads the
    seed and writes a directory.

    ONE DIFFERENCE FROM evals/functional/Reset-Target.ps1, WHICH IS OTHERWISE
    ITS TWIN. This script stamps a FIXED commit date rather than the wall clock.
    LEDGER item 16 recorded that the AzDO reset produces a different commit SHA
    on every run while the tree stays identical, so a check written against the
    commit fails for a reason that has nothing to do with the seed. Here the
    commit SHA is reproducible as well. The TREE is still what gets pinned - it
    is the thing that is actually about the seed's content - and the fixed date
    only removes a way of being wrong. The AzDO script is left alone on purpose:
    runs 004-006 were produced by it, and changing it would change an instrument
    three recorded runs were measured with.

.PARAMETER Destination
    Where to materialise the seed. Must be under scratch/runs/.

.PARAMETER Force
    Replace a destination that exists and is non-empty.

.PARAMETER SeedPath
    The seed to materialise. Defaults to evals/tf/seed/.

.PARAMETER FailCheck
    Prove the guard can refuse and can accept. Every destination in the refusal
    list below must be REFUSED, and a legitimate scratch/runs/ path must be
    ACCEPTED. Both halves are required: a guard that refused everything would
    pass a refusal-only probe and be useless, and that is the failure mode a
    path guard actually has.

    Writes only under scratch/runs/, and removes what it made.

.PARAMETER ReportPath
    With -FailCheck, write the report here as well as to the pipeline.

.EXAMPLE
    pwsh -NoProfile -File evals/tf/Reset-TfTarget.ps1 -Destination scratch/runs/tf-003

.EXAMPLE
    pwsh -NoProfile -File evals/tf/Reset-TfTarget.ps1 -FailCheck -ReportPath ../../plans/0035-tf003-kit/reset-falsification.txt
#>
[CmdletBinding(DefaultParameterSetName = 'Reset')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Reset')]
    [string]$Destination,

    [Parameter(ParameterSetName = 'Reset')]
    [switch]$Force,

    [string]$SeedPath = (Join-Path $PSScriptRoot 'seed'),

    [Parameter(Mandatory, ParameterSetName = 'FailCheck')]
    [switch]$FailCheck,

    [Parameter(ParameterSetName = 'FailCheck')]
    [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).ProviderPath
$AllowedRoot = Join-Path $RepoRoot 'scratch' 'runs'

# A fixed point in time rather than the wall clock. See the note in the
# description: this is what makes the commit SHA, and not only the tree,
# reproducible across machines and across days.
$CommitDate = '2026-01-01T00:00:00+00:00'

function Test-DestinationAllowed {
    <#
        True only when $Candidate is at or below scratch/runs/ in this
        repository.

        Compared after normalisation, so that a path reaching outside through
        .. segments is rejected on what it RESOLVES TO rather than on how it is
        spelled. A prefix test on the raw string would accept
        scratch/runs/../../../PSTerraformGraph, which is the exact accident this
        exists to prevent - and the falsification below fires that path at it.
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

function Invoke-Reset {
    <#
    .SYNOPSIS
        The reset proper. Throws on a refused destination.
    #>
    param(
        [Parameter(Mandatory)] [string] $To,
        [switch] $Replace,
        [Parameter(Mandatory)] [string] $Seed
    )

    if (-not (Test-Path -LiteralPath $Seed -PathType Container)) {
        throw "Seed not found at $Seed"
    }

    if (-not (Test-DestinationAllowed -Candidate $To)) {
        throw @"
REFUSED: outside scratch. Refusing to reset '$To'.

The destination must be under scratch/runs/. This script materialises a clean
slate by deleting and recreating a directory, and the real PSTerraformGraph
repository must never be a candidate for that. A promoted run is copied there
by hand, deliberately, and never by this script.

Allowed root: $AllowedRoot
"@
    }

    $fullDest = [IO.Path]::GetFullPath((Join-Path $RepoRoot $To))
    if ([IO.Path]::IsPathRooted($To)) { $fullDest = [IO.Path]::GetFullPath($To) }

    if (Test-Path -LiteralPath $fullDest) {
        $existing = @(Get-ChildItem -LiteralPath $fullDest -Force -ErrorAction SilentlyContinue)
        if ($existing.Count -gt 0 -and -not $Replace) {
            throw @"
Refusing to reset '$To': it exists and is not empty ($($existing.Count) entries).

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
    $seedFull = (Resolve-Path -LiteralPath $Seed).ProviderPath
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
    # BOTH DATES, via the environment. `git commit --date=` sets only the AUTHOR
    # date; the COMMITTER date still comes from the wall clock, and a commit
    # SHA is a function of both. Measured, not assumed: with --date alone, two
    # resets of the same seed produced the same tree and DIFFERENT commits as
    # soon as a second elapsed between them - and a reproducibility check that
    # ran them back to back agreed with itself for exactly that long.
    $priorAuthor = $env:GIT_AUTHOR_DATE
    $priorCommitter = $env:GIT_COMMITTER_DATE
    try {
        $env:GIT_AUTHOR_DATE = $CommitDate
        $env:GIT_COMMITTER_DATE = $CommitDate

        & git init --quiet --initial-branch=main 2>&1 | Out-Null
        & git add -A 2>&1 | Out-Null
        # A local identity, so the commit does not depend on global git config
        # being set on whichever machine runs this.
        & git -c user.name='Reset-TfTarget' -c user.email='reset-tftarget@localhost' `
            -c 'core.autocrlf=false' `
            commit --quiet -m 'Seed' 2>&1 | Out-Null
        $sha = (& git rev-parse HEAD).Trim()
        $tree = (& git rev-parse 'HEAD^{tree}').Trim()
        $stamped = (& git log -1 --pretty='%aI|%cI').Trim()
        $tracked = @(& git ls-files)
    }
    finally {
        $env:GIT_AUTHOR_DATE = $priorAuthor
        $env:GIT_COMMITTER_DATE = $priorCommitter
        Pop-Location
    }

    [pscustomobject]@{
        Destination = $fullDest
        FilesCopied = $copied
        Commit      = $sha
        Tree        = $tree
        Stamped     = $stamped
        Tracked     = $tracked
    }
}

# ---------------------------------------------------------------------------
if ($FailCheck) {
    # Destinations that must be REFUSED. Each is a real way to get this wrong,
    # not a made-up string: the sibling deliverable repository by relative path
    # and by absolute path, the same repository reached by traversing OUT of an
    # allowed prefix, a directory whose name merely starts the same way, and the
    # harness root itself.
    $mustRefuse = [ordered]@{
        'the deliverable repository, relatively'      = '../PSTerraformGraph'
        'the deliverable repository, absolutely'      = (Join-Path (Split-Path -Parent $RepoRoot) 'PSTerraformGraph')
        'traversal out of an allowed prefix'          = 'scratch/runs/../../PSTerraformGraph'
        'a sibling of scratch/runs with a like name'  = 'scratch/runs-not-really/x'
        'the harness root itself'                     = '.'
        'a fixture source tree'                       = 'evals/tf/fixture2/repos'
    }
    $mustAccept = 'scratch/runs/0035-reset-falsification'

    $lines = [System.Collections.Generic.List[string]]::new()
    $failures = [System.Collections.Generic.List[string]]::new()
    $bar = '=' * 78
    $thin = '-' * 78

    $lines.Add($bar)
    $lines.Add('FALSIFYING Reset-TfTarget.ps1 - THE DESTINATION GUARD')
    $lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
    $lines.Add('Allowed root: ' + ($AllowedRoot -replace '\\', '/'))
    $lines.Add($bar)
    $lines.Add('')
    $lines.Add('This script deletes and recreates a directory. The one accident it exists to')
    $lines.Add('prevent is a mistyped destination taking out the real deliverable repository,')
    $lines.Add('and a guard nobody has fired at is a comment with an if-statement around it.')
    $lines.Add('')
    $lines.Add('BOTH HALVES ARE CHECKED. A guard that refused everything would pass a')
    $lines.Add('refusal-only probe while making the script useless, and that is the failure')
    $lines.Add('mode a path guard actually has. So: every destination below must be refused,')
    $lines.Add('AND a legitimate one must be accepted.')
    $lines.Add('')

    $lines.Add($thin)
    $lines.Add('MUST REFUSE')
    $lines.Add('')
    foreach ($why in $mustRefuse.Keys) {
        $candidate = $mustRefuse[$why]
        $refused = $false
        $message = ''
        try {
            $null = Invoke-Reset -To $candidate -Seed $SeedPath
        }
        catch {
            $message = ($_.Exception.Message -split "`n")[0].Trim()
            $refused = $message -match 'REFUSED: outside scratch'
        }
        $lines.Add("  $why")
        $lines.Add("    destination : $candidate")
        if ($refused) {
            $lines.Add("    REFUSED: outside scratch")
        }
        else {
            $lines.Add("    NOT REFUSED - the guard let this through" + ($message ? " ($message)" : ''))
            $failures.Add("guard did not refuse '$candidate' ($why)")
        }
        # A destination that was refused must also not exist afterwards. A guard
        # that throws AFTER creating the directory has already done the damage.
        $probe = [IO.Path]::IsPathRooted($candidate) ? $candidate : (Join-Path $RepoRoot $candidate)
        $probeFull = [IO.Path]::GetFullPath($probe)
        if ($refused -and $probeFull -ne [IO.Path]::GetFullPath($RepoRoot) -and
            -not (Test-Path -LiteralPath $probeFull) -and $candidate -notlike '*PSTerraformGraph*') {
            $lines.Add('    and nothing was created there')
        }
        $lines.Add('')
    }

    $lines.Add($thin)
    $lines.Add('MUST ACCEPT - the control. Without this, refusing everything would score')
    $lines.Add('perfectly above.')
    $lines.Add('')
    $accepted = $null
    try {
        $accepted = Invoke-Reset -To $mustAccept -Seed $SeedPath -Replace
        $lines.Add("  destination : $mustAccept")
        $lines.Add("  ACCEPTED, and the seed was materialised")
        $lines.Add("  files copied: $($accepted.FilesCopied)")
        $lines.Add("  commit      : $($accepted.Commit)")
        $lines.Add("  tree        : $($accepted.Tree)")
        $lines.Add('  tracked     :')
        foreach ($t in $accepted.Tracked) { $lines.Add("                $t") }
    }
    catch {
        $lines.Add("  REFUSED a legitimate destination: $($_.Exception.Message)")
        $failures.Add("guard refused the legitimate destination '$mustAccept'")
    }
    $lines.Add('')

    if ($accepted) {
        # Reproducibility, measured rather than asserted: reset the same
        # destination again and require the same tree AND the same commit.
        $again = Invoke-Reset -To $mustAccept -Seed $SeedPath -Replace
        $lines.Add($thin)
        $lines.Add('REPRODUCIBLE - the same seed reset twice.')
        $lines.Add('')
        $lines.Add("  tree   : $($accepted.Tree) / $($again.Tree)")
        $lines.Add("  commit : $($accepted.Commit) / $($again.Commit)")
        $lines.Add("  stamps : $($accepted.Stamped) / $($again.Stamped)")
        if ($again.Tree -eq $accepted.Tree) { $lines.Add('  TREE STABLE') }
        else { $failures.Add('the seed tree differs between two resets of the same seed') }
        if ($again.Commit -eq $accepted.Commit) { $lines.Add('  COMMIT STABLE') }
        else { $failures.Add('the seed commit differs between two resets; the fixed date is not taking effect') }

        # The MECHANISM, not just the outcome. Two resets run inside the same
        # second produce the same commit whether the date is fixed or not, so
        # equality alone is a probe that agrees with itself for a second and
        # then stops. Reading the stamps back is what actually says the dates
        # were pinned - and it was written after --date alone was found to pin
        # only the author half.
        $wanted = ([DateTimeOffset]::Parse($CommitDate)).ToUniversalTime()
        $halves = @($accepted.Stamped -split '\|')
        $pinned = @($halves | Where-Object { $_ } | ForEach-Object {
                ([DateTimeOffset]::Parse($_)).ToUniversalTime() -eq $wanted })
        if ($halves.Count -eq 2 -and $pinned.Count -eq 2 -and ($pinned -notcontains $false)) {
            $lines.Add("  BOTH STAMPS PINNED at $CommitDate - author AND committer")
        }
        else {
            $lines.Add("  STAMPS NOT PINNED: got $($accepted.Stamped), wanted both at $CommitDate")
            $failures.Add('the commit carries a wall-clock date; the SHA is reproducible only by luck')
        }
        $lines.Add('')

        Remove-Item -LiteralPath $accepted.Destination -Recurse -Force -ErrorAction SilentlyContinue
        $lines.Add("The accepted destination has been removed: $mustAccept")
        $lines.Add('')
        $lines.Add('SEED TREE: ' + $accepted.Tree)
        $lines.Add('')
    }

    $lines.Add($bar)
    if ($failures.Count -eq 0) {
        $lines.Add('GUARD FALSIFIED - it refuses what it must and accepts what it must.')
    }
    else {
        foreach ($f in $failures) { $lines.Add("FAILED: $f") }
    }
    $lines.Add($bar)

    $report = $lines -join [Environment]::NewLine
    $report

    if ($ReportPath) {
        $parent = Split-Path -Parent $ReportPath
        if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
    }

    if ($failures.Count -gt 0) { exit 1 }
    exit 0
}

# ---------------------------------------------------------------------------
$result = Invoke-Reset -To $Destination -Replace:$Force -Seed $SeedPath

Write-Host "Reset-TfTarget"
Write-Host "  seed        : $((Resolve-Path -LiteralPath $SeedPath).ProviderPath)"
Write-Host "  destination : $($result.Destination)"
Write-Host "  files copied: $($result.FilesCopied)"
Write-Host "  commit      : $($result.Commit)"
Write-Host "  tree        : $($result.Tree)"
Write-Host "  stamped     : $($result.Stamped)"
Write-Host "  tracked     : $($result.Tracked.Count) files"
foreach ($t in $result.Tracked) { Write-Host "                $t" }

$result
