#Requires -Version 7.2
<#
.SYNOPSIS
    Disprove the pass 0021 plan without reading it.

.DESCRIPTION
    Re-derives every named spot-check from a FRESH CLONE of PSGraphRender at
    v0.13.0. It never reads plan.md, never trusts the working copy beside it,
    and never reads a number this pass wrote down: every figure it compares
    against is recomputed here.

    Assumes only a clone of this repository, pwsh 7.2+, git, node and network
    access to the PSGraphRender remote.

    Each check prints its own name with its verdict. The exit code is the
    aggregate: 0 when every check agrees, 1 when any disagrees.

    -FailCheck runs the tamper probes' own controls: it asserts that each
    deliberate break actually changed the bytes on disk before asking the
    tool about them. A probe that silently failed to break anything would
    otherwise report a meaningless green - which happened once during the
    pass and is why this switch exists.

.PARAMETER Remote
    The PSGraphRender repository to clone. Defaults to the public remote.

.PARAMETER WorkRoot
    Where to make the scratch clone. Defaults to a new temp directory, which
    is removed on exit. Never uses scratch/, which is not committed.

.PARAMETER SkipBuild
    Skip check 1's ./build.ps1 run. Everything else still runs. For a machine
    with no node, which cannot run the browser gate.
#>
[CmdletBinding()]
param(
    [string] $Remote = 'https://github.com/JerryBalmer1/PSGraphRender.git',
    [string] $WorkRoot,
    [switch] $SkipBuild,
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Checks = 0

function Confirm-Check {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [bool] $Ok,
        [string] $Detail = ''
    )
    $script:Checks++
    if ($Ok) {
        Write-Host ("PASS  {0}" -f $Name)
        if ($Detail) { Write-Host ("        {0}" -f $Detail) }
    }
    else {
        Write-Host ("FAIL  {0}" -f $Name)
        if ($Detail) { Write-Host ("        {0}" -f $Detail) }
        $script:Failures.Add($Name)
    }
}

function Get-Sha384 {
    param([Parameter(Mandatory)] [string] $Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    'sha384-' + [Convert]::ToBase64String(
        [System.Security.Cryptography.SHA384]::Create().ComputeHash($bytes))
}

# The one constant this script is allowed to carry: the SHA the begin tag is a
# claim about. It is the thing under test, not a derived figure.
$PreHandoffMain = '4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995'

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$temporary = -not $WorkRoot
if ($temporary) {
    $WorkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('verify-0021-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
}
New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null

try {
    $clone = Join-Path $WorkRoot 'PSGraphRender'
    Write-Host "Cloning $Remote at v0.13.0 into $clone ..."
    & git clone --quiet $Remote $clone 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "clone failed with exit $LASTEXITCODE" }
    & git -C $clone checkout --quiet v0.13.0 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "checkout of v0.13.0 failed with exit $LASTEXITCODE" }

    # ---- 1. Fresh clone builds green; absent paths absent; archive populated --

    if ($SkipBuild) {
        Write-Host 'SKIP  1a ./build.ps1 in a fresh clone (-SkipBuild)'
    }
    else {
        Push-Location $clone
        try {
            & pwsh -NoProfile -Command './build.ps1 -Task BootstrapBrowser' 2>&1 | Out-Null
            $buildOutput = & pwsh -NoProfile -Command './build.ps1' 2>&1
            $buildExit = $LASTEXITCODE
        }
        finally { Pop-Location }

        $text = $buildOutput -join "`n"
        Confirm-Check -Name '1a ./build.ps1 exits 0 in a fresh clone at v0.13.0' `
            -Ok ($buildExit -eq 0) -Detail "exit $buildExit"

        # Re-derived from the run, never from the plan.
        $passed = if ($text -match 'Tests Passed:\s*(\d+)') { [int]$Matches[1] } else { -1 }
        $failed = if ($text -match 'Failed:\s*(\d+)') { [int]$Matches[1] } else { -1 }
        Confirm-Check -Name '1b the suite reports no failures' `
            -Ok ($failed -eq 0 -and $passed -gt 0) -Detail "$passed passed, $failed failed"

        Confirm-Check -Name '1c the browser gate actually ran' `
            -Ok ($text -match 'Browser: \d+ page\(s\) came alive') `
            -Detail $(if ($text -match '(Browser: [^\r\n]+)') { $Matches[1] } else { 'no browser line' })
    }

    $absent = 'CLAUDE.md', '.claude', 'docs/threads.json', 'tools/threads.ps1',
    'tests/Ledger.Tests.ps1', 'tests/Instructions.Tests.ps1', 'knowledge'
    $present = @($absent | Where-Object { Test-Path (Join-Path $clone $_) })
    Confirm-Check -Name '1d every stripped path is absent' `
        -Ok ($present.Count -eq 0) `
        -Detail $(if ($present.Count) { 'still present: ' + ($present -join ', ') } else { "$($absent.Count) paths checked" })

    $archive = @(Get-ChildItem (Join-Path $clone 'docs/ledger-archive') -Filter *.md -ErrorAction SilentlyContinue)
    Confirm-Check -Name '1e docs/ledger-archive is populated' `
        -Ok ($archive.Count -gt 10) -Detail "$($archive.Count) markdown files"

    # ---- 2. Both vendored files re-hashed here, independent of tool and tests -

    $vendorDir = Join-Path $clone 'src/PSGraphRender/TemplateSets/cytoscape/vendor'
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $vendorDir 'vendor.psd1')
    $mismatch = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $manifest.Files) {
        $path = Join-Path $vendorDir $entry.Name
        if (-not (Test-Path -LiteralPath $path)) { $mismatch.Add("$($entry.Name) missing"); continue }
        $computed = Get-Sha384 -Path $path
        if ($computed -ne $entry.Integrity) { $mismatch.Add("$($entry.Name) $computed != $($entry.Integrity)") }
    }
    Confirm-Check -Name '2 both vendored files match the manifest, hashed by verify itself' `
        -Ok ($mismatch.Count -eq 0 -and @($manifest.Files).Count -eq 2) `
        -Detail $(if ($mismatch.Count) { $mismatch -join '; ' } else { "$(@($manifest.Files).Count) files, sha384 recomputed here" })

    # ---- 3. Tamper a byte in verify's own scratch clone ----------------------

    $tamperRoot = Join-Path $WorkRoot 'tamper'
    Copy-Item -LiteralPath $clone -Destination $tamperRoot -Recurse -Force
    Remove-Item -LiteralPath (Join-Path $tamperRoot '.git') -Recurse -Force -ErrorAction SilentlyContinue

    $tool = Join-Path $clone 'tools/Update-Vendor.ps1'
    $target = Join-Path $tamperRoot 'src/PSGraphRender/TemplateSets/cytoscape/vendor/cytoscape.min.js'

    # Control first: the untouched copy must be green, or a red below proves
    # nothing about the tamper.
    $cleanOutput = & pwsh -NoProfile -File $tool -Verify -Root $tamperRoot 2>&1
    $cleanExit = $LASTEXITCODE
    Confirm-Check -Name '3a control: an untouched copy verifies green' `
        -Ok ($cleanExit -eq 0) -Detail "exit $cleanExit"

    $before = Get-Sha384 -Path $target
    $bytes = [System.IO.File]::ReadAllBytes($target)
    $bytes[1000] = $bytes[1000] -bxor 1
    [System.IO.File]::WriteAllBytes($target, $bytes)
    $after = Get-Sha384 -Path $target

    if ($FailCheck) {
        Confirm-Check -Name '3b probe control: the tamper actually changed the file' `
            -Ok ($before -ne $after) -Detail "before $($before.Substring(0,20))... after $($after.Substring(0,20))..."
    }

    $tamperOutput = (& pwsh -NoProfile -File $tool -Verify -Root $tamperRoot 2>&1) -join "`n"
    $tamperExit = $LASTEXITCODE
    Confirm-Check -Name '3c a tampered file makes -Verify exit nonzero' `
        -Ok ($tamperExit -ne 0) -Detail "exit $tamperExit"
    Confirm-Check -Name '3d -Verify names the tampered file' `
        -Ok ($tamperOutput -match 'cytoscape\.min\.js') `
        -Detail 'output names cytoscape.min.js'
    Confirm-Check -Name '3e -Verify leaves the untampered file green' `
        -Ok ($tamperOutput -match 'OK\s+\S*cytoscape-dagre\.min\.js') `
        -Detail 'cytoscape-dagre.min.js still reported OK'

    # ---- 4. Tag topology -----------------------------------------------------

    $begin = (& git -C $clone rev-parse 'handoff-begin-2026-08-29^{}' 2>$null)
    Confirm-Check -Name '4a handoff-begin-2026-08-29 dereferences to the pre-handoff main' `
        -Ok ($begin -eq $PreHandoffMain) -Detail "$begin"

    $beginType = (& git -C $clone cat-file -t (& git -C $clone rev-parse 'handoff-begin-2026-08-29') 2>$null)
    Confirm-Check -Name '4b the begin tag is annotated, not lightweight' `
        -Ok ($beginType -eq 'tag') -Detail "object type: $beginType"

    $release = (& git -C $clone rev-parse 'v0.13.0^{}' 2>$null)
    $releaseType = (& git -C $clone cat-file -t (& git -C $clone rev-parse 'v0.13.0') 2>$null)
    Confirm-Check -Name '4c v0.13.0 is annotated' `
        -Ok ($releaseType -eq 'tag') -Detail "object type: $releaseType"

    & git -C $clone merge-base --is-ancestor $begin $release 2>&1 | Out-Null
    Confirm-Check -Name '4d v0.13.0 descends from the begin tag' `
        -Ok ($LASTEXITCODE -eq 0) -Detail "$begin -> $release"

    $remoteMain = (& git -C $clone ls-remote origin refs/heads/main) -split '\s+' | Select-Object -First 1
    Confirm-Check -Name '4e origin/main equals v0.13.0' `
        -Ok ($remoteMain -eq $release) -Detail "origin/main $remoteMain"

    # ---- 5. Harness decision 0010 -------------------------------------------

    $decision = Join-Path $RepoRoot 'decisions/0010-ecosystem-repo-governance.md'
    $decisionOk = Test-Path -LiteralPath $decision
    $decisionText = if ($decisionOk) { Get-Content -LiteralPath $decision -Raw } else { '' }
    Confirm-Check -Name '5a harness decision 0010 exists' `
        -Ok $decisionOk -Detail $decision
    Confirm-Check -Name '5b decision 0010 governs this repository by name' `
        -Ok ($decisionText -match 'PSGraphRender' -and $decisionText -match 'merge-base --is-ancestor') `
        -Detail 'names PSGraphRender and the ancestry check'

    # ---- 6. HANDOFF.md carries what the pass claimed -------------------------

    $handoff = Get-Content -LiteralPath (Join-Path $clone 'docs/HANDOFF.md') -Raw
    foreach ($needle in @(
            @{ Name = 'the schema path'; Pattern = 'viewmodel\.schema\.json' }
            @{ Name = 'the contract version'; Pattern = '1\.1\.0' }
            @{ Name = 'a Boundaries section'; Pattern = '(?m)^## Boundaries' }
            @{ Name = 'an Open section'; Pattern = '(?m)^## Open' }
        )) {
        Confirm-Check -Name ('6 docs/HANDOFF.md carries {0}' -f $needle.Name) `
            -Ok ($handoff -match $needle.Pattern) -Detail $needle.Pattern
    }
}
finally {
    if ($temporary -and (Test-Path -LiteralPath $WorkRoot)) {
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host ''
Write-Host ("{0} check(s), {1} failed." -f $script:Checks, $script:Failures.Count)
if ($script:Failures.Count -gt 0) {
    Write-Host 'Checks that disagreed:'
    foreach ($f in $script:Failures) { Write-Host ("  {0}" -f $f) }
    exit 1
}
exit 0
