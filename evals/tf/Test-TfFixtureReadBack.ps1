#Requires -Version 7.2
<#
.SYNOPSIS
    Clone each fixture repository fresh and hash every file against the harness copy.

.DESCRIPTION
    The harness copy under fixture/repos/ is the source of truth. This proves
    the AzDO side is that copy and not something like it: every file on both
    sides is hashed, and the sets are compared in both directions so a file
    present on one side only is a named mismatch rather than a silent pass.

    Content is normalised to LF before hashing, on BOTH sides, and the reason
    is stated rather than assumed: every fixture repository carries
    .gitattributes with `* text=auto eol=lf`, so git checks out LF while a
    Windows working copy may hold CRLF. Comparing the raw bytes would report a
    mismatch that is about line endings and nothing else. `.git` is excluded
    because it is not fixture content.

    A mismatch is a hard stop. The whole point of a frozen fixture is that a
    later score means something, and a score against a fixture nobody verified
    means nothing.
#>
[CmdletBinding()]
param(
    [string] $WorkRoot,
    [string] $ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'TfAzdoClient.ps1')
Assert-TfAzdoScope

$fixtureRoot = Join-Path $PSScriptRoot 'fixture/repos'
$temporary = -not $WorkRoot
if ($temporary) {
    $WorkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('tf-readback-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
}
$null = New-Item -ItemType Directory -Path $WorkRoot -Force

function Get-NormalisedHash {
    <# SHA256 over the file's content with line endings normalised to LF. #>
    param([Parameter(Mandatory)] [string] $Path)
    $text = [System.IO.File]::ReadAllText($Path) -replace "`r`n", "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '')
}

function Get-TreeHash {
    <# Every file under a root, as relative path -> normalised hash. #>
    param([Parameter(Mandatory)] [string] $Root)
    $map = [ordered]@{}
    foreach ($file in (Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
        if ($relative -like '.git/*' -or $relative -eq '.git') { continue }
        $map[$relative] = Get-NormalisedHash -Path $file.FullName
    }
    $map
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('=' * 78)
$lines.Add('READ-BACK - the AzDO fixture against the harness copy')
$lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
$lines.Add('=' * 78)
$lines.Add('')
$lines.Add('The harness copy under evals/tf/fixture/repos/ is the source of truth per')
$lines.Add('decision 0011. Every file on both sides is hashed (SHA256 over content with')
$lines.Add('line endings normalised to LF on BOTH sides, because every fixture repository')
$lines.Add('carries .gitattributes with `* text=auto eol=lf`) and the sets are compared in')
$lines.Add('both directions, so a file present on one side only is a named mismatch.')
$lines.Add('')

$mismatches = [System.Collections.Generic.List[string]]::new()
$totalFiles = 0

try {
    foreach ($name in (Get-TfFixtureRepoName)) {
        $lines.Add('-' * 78)
        $lines.Add("REPOSITORY: $name")

        $clone = Join-Path $WorkRoot $name
        $uri = "https://dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/$name"

        # The PAT travels in a header, never in the URL. git is told to use an
        # Authorization header via -c http.extraHeader, and the value is built
        # here and never written anywhere.
        $bytes = [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")
        $auth = 'Authorization: Basic ' + [Convert]::ToBase64String($bytes)

        & git -c "http.extraHeader=$auth" clone --quiet $uri $clone 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "clone of $name failed with exit $LASTEXITCODE" }

        $commit = (& git -C $clone rev-parse HEAD).Trim()
        $lines.Add("  cloned at $commit")

        $harness = Get-TreeHash -Root (Join-Path $fixtureRoot $name)
        $remote = Get-TreeHash -Root $clone

        $lines.Add("  harness files: $($harness.Count)   remote files: $($remote.Count)")

        foreach ($path in $harness.Keys) {
            $totalFiles++
            if (-not $remote.Contains($path)) {
                $mismatches.Add("$name/$path : present in the harness copy, absent on the remote")
                $lines.Add("  MISSING ON REMOTE  $path")
                continue
            }
            if ($harness[$path] -ne $remote[$path]) {
                $mismatches.Add("$name/$path : content differs")
                $lines.Add("  DIFFERS            $path")
                $lines.Add("                     harness $($harness[$path])")
                $lines.Add("                     remote  $($remote[$path])")
                continue
            }
            $lines.Add("  OK                 $path  $($harness[$path].Substring(0,16))")
        }
        foreach ($path in $remote.Keys) {
            if (-not $harness.Contains($path)) {
                $mismatches.Add("$name/$path : present on the remote, absent from the harness copy")
                $lines.Add("  EXTRA ON REMOTE    $path")
            }
        }
        $lines.Add('')
    }
}
finally {
    if ($temporary -and (Test-Path -LiteralPath $WorkRoot)) {
        Remove-Item -LiteralPath $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$lines.Add('-' * 78)
$lines.Add("$totalFiles file(s) compared across $((Get-TfFixtureRepoName).Count) repositories.")
$lines.Add('')
if ($mismatches.Count -eq 0) {
    $lines.Add('BYTE-IDENTICAL')
}
else {
    $lines.Add("$($mismatches.Count) MISMATCH(ES):")
    foreach ($mismatch in $mismatches) { $lines.Add("  $mismatch") }
}
$lines.Add('=' * 78)

$report = $lines -join [Environment]::NewLine
$report

if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
}

if ($mismatches.Count -gt 0) { exit 1 }
exit 0
