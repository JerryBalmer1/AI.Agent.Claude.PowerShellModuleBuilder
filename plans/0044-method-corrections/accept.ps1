#Requires -Version 7.0
<#
.SYNOPSIS
    Acceptance test for pass 0044 - method corrections carried over from 0043.

.DESCRIPTION
    Exits non-zero unless all four of the pass's deliverables are present:

      1. method/METHOD.md carries the two new rules (named-check polarity,
         conventions from the repo), in the document's own rule convention.
      2. PLAN-PROTOCOL.md carries the three additions (signal legend, frontier
         precondition, recovery-phase pattern).
      3. The conformance suite carries the workspace-composition assertion and
         its falsification-control row.
      4. LEDGER.md carries the backlog entries under '### Added by pass 0044'.

    Reads only. Writes nothing, anywhere - so it is safe to run at any point.

    NOTE ON RULE NUMBERING. The prompt asks that the two METHOD rules be
    "numbered continuously after its current last rule". METHOD.md has no rule
    numbering and never has: its 42 rules are bold-tagged paragraphs
    (**PORTABLE.** / **TUNE.** / **DOMAIN.**) under topic headings, and the only
    numbered list in the file is a four-item sub-list inside one rule. This test
    therefore checks the invariant the numbering requirement was standing in for
    - that each new rule parses as a rule of this document, carrying exactly one
    of the three tags in the document's own form. See plan.md, Deviation 2, and
    the repository's own precedent at commit 64fee46, "Replace an invented
    convention with the assertion it was standing in for".
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..')).Path

function Get-Text {
    param([string] $Relative)
    $p = Join-Path $repo $Relative
    if (-not (Test-Path -LiteralPath $p)) { return $null }
    return (Get-Content -LiteralPath $p -Raw)
}

# Signal markers by code point rather than by literal, so this script's own file
# encoding can never be the reason a check reports the wrong answer.
$SIG = @{
    Red    = [char]::ConvertFromUtf32(0x1F534)
    Orange = [char]::ConvertFromUtf32(0x1F7E0)
    Green  = [char]::ConvertFromUtf32(0x1F7E2)
    Blue   = [char]::ConvertFromUtf32(0x1F535)
    Never  = [char]::ConvertFromUtf32(0x26D4)
}

$findings = [System.Collections.Generic.List[string]]::new()

function Test-Check {
    param(
        [string] $Name,
        [scriptblock] $Body
    )
    $ok = $false
    $detail = ''
    try {
        $r = & $Body
        if ($r -is [array]) { $ok = [bool]$r[0]; $detail = [string]$r[1] }
        else { $ok = [bool]$r }
    }
    catch {
        $ok = $false
        $detail = $_.Exception.Message
    }
    if ($ok) {
        Write-Host ("  PASS  {0}" -f $Name)
    }
    else {
        $suffix = ''
        if ($detail) { $suffix = " - $detail" }
        Write-Host ("  FAIL  {0}{1}" -f $Name, $suffix)
        $script:findings.Add($Name)
    }
}

Write-Host ''
Write-Host 'ACCEPT 0044 - method corrections'
Write-Host ("repo: {0}" -f $repo)
Write-Host ''

# ---------------------------------------------------------------- Task 1
$method = Get-Text 'method/METHOD.md'

Write-Host 'Task 1 - METHOD.md, two new rules'

Test-Check 'METHOD.md is readable' { $null -ne $method }

Test-Check 'METHOD: named-check polarity rule present' {
    if (-not $method) { return @($false, 'no file') }
    $missing = @('known-bad', 'known-good', 'before its first counted result') |
        Where-Object { $method -notmatch [regex]::Escape($_) }
    if ($missing.Count) { return @($false, "missing phrase(s): $($missing -join '; ')") }
    return $true
}

Test-Check 'METHOD: polarity rule cites SC2, SC4 and pass 0043' {
    if (-not $method) { return @($false, 'no file') }
    foreach ($t in 'SC2', 'SC4', '0043') {
        if ($method -notmatch [regex]::Escape($t)) { return @($false, "missing $t") }
    }
    return $true
}

Test-Check 'METHOD: conventions-from-the-repo rule present' {
    if (-not $method) { return @($false, 'no file') }
    $missing = @('never recalled', 'authoring time') |
        Where-Object { $method -notmatch [regex]::Escape($_) }
    if ($missing.Count) { return @($false, "missing phrase(s): $($missing -join '; ')") }
    return $true
}

Test-Check 'METHOD: conventions rule cites the 0043 verify path and the tag collision' {
    if (-not $method) { return @($false, 'no file') }
    foreach ($t in 'verify.ps1', 'v0.4.0') {
        if ($method -notmatch [regex]::Escape($t)) { return @($false, "missing $t") }
    }
    return $true
}

# The invariant the prompt's numbering requirement stood in for: each new rule
# parses as a rule of this document. Both new rules must open with exactly one of
# the document's three tags, and the tagged-rule count must have grown by two.
Test-Check 'METHOD: both new rules carry a document rule tag, and no rule is mis-tagged' {
    if (-not $method) { return @($false, 'no file') }
    $lines = $method -split "`r?`n"
    $tagged = @($lines | Where-Object { $_ -match '^\*\*(PORTABLE|TUNE|DOMAIN)\.\*\* ' })
    if ($tagged.Count -lt 44) {
        return @($false, "expected at least 44 tagged rules after this pass, found $($tagged.Count)")
    }
    $bogus = @($lines | Where-Object {
            $_ -match '^\*\*[A-Z]+\.\*\*' -and $_ -notmatch '^\*\*(PORTABLE|TUNE|DOMAIN)\.\*\*'
        })
    if ($bogus.Count) { return @($false, "mis-tagged rule opener: $($bogus[0])") }
    return $true
}

# ---------------------------------------------------------------- Task 2
$protocol = Get-Text 'PLAN-PROTOCOL.md'

Write-Host ''
Write-Host 'Task 2 - PLAN-PROTOCOL.md, three additions'

Test-Check 'PLAN-PROTOCOL.md is readable' { $null -ne $protocol }

Test-Check 'PROTOCOL: five-signal legend present, all five markers' {
    if (-not $protocol) { return @($false, 'no file') }
    $missing = @()
    foreach ($k in 'Red', 'Orange', 'Green', 'Blue', 'Never') {
        if (-not $protocol.Contains($SIG[$k])) { $missing += $k }
    }
    if ($missing.Count) { return @($false, "missing marker(s): $($missing -join ', ')") }
    return $true
}

Test-Check 'PROTOCOL: legend names each signal in words' {
    if (-not $protocol) { return @($false, 'no file') }
    foreach ($w in 'Hard stop', 'Operator action', 'Agent task', 'Evidence gate') {
        if ($protocol -notmatch [regex]::Escape($w)) { return @($false, "missing word: $w") }
    }
    return $true
}

Test-Check 'PROTOCOL: legend records the constraint it survived' {
    if (-not $protocol) { return @($false, 'no file') }
    foreach ($t in '0043', '0044') {
        if ($protocol -notmatch $t) { return @($false, "legend does not cite pass $t") }
    }
    return $true
}

Test-Check 'PROTOCOL: multi-source frontier precondition present' {
    if (-not $protocol) { return @($false, 'no file') }
    foreach ($t in 'LEDGER', 'plans tree', 'journal tree', '0032') {
        if ($protocol -notmatch [regex]::Escape($t)) { return @($false, "missing $t") }
    }
    return $true
}

Test-Check 'PROTOCOL: recovery-phase pattern present' {
    if (-not $protocol) { return @($false, 'no file') }
    foreach ($t in 'idempotent', 'check-then-act', 'pre-ratified', 'stop-and-relaunch') {
        if ($protocol -notmatch [regex]::Escape($t)) { return @($false, "missing $t") }
    }
    return $true
}

# ---------------------------------------------------------------- Task 3
$suite = Get-Text 'evals/conformance/Conformance.Tests.ps1'
$fals = Get-Text 'evals/conformance/baseline/FALSIFICATION.md'

Write-Host ''
Write-Host 'Task 3 - conformance suite, workspace-composition assertion'

Test-Check 'Conformance suite is readable' { $null -ne $suite }

Test-Check 'SUITE: workspace-composition Describe block present' {
    if (-not $suite) { return @($false, 'no file') }
    if ($suite -notmatch "Describe\s+'Workspace composition'") {
        return @($false, "no Describe 'Workspace composition'")
    }
    return $true
}

Test-Check 'SUITE: assertion names PSModuleGraph and reads workspace files' {
    if (-not $suite) { return @($false, 'no file') }
    if ($suite -notmatch 'PSModuleGraph') { return @($false, 'assertion does not name PSModuleGraph') }
    if ($suite -notmatch 'code-workspace') { return @($false, 'assertion does not read *.code-workspace') }
    return $true
}

Test-Check 'SUITE: assertion is discovered per file, so zero files reports as zero cases' {
    if (-not $suite) { return @($false, 'no file') }
    if ($suite -notmatch 'WorkspaceFiles') {
        return @($false, 'no per-file discovery collection; a suite-level It cannot report zero cases')
    }
    return $true
}

Test-Check 'FALSIFICATION.md carries the control row for the new assertion' {
    if (-not $fals) { return @($false, 'no file') }
    $rows = @(($fals -split "`r?`n") | Where-Object { $_ -match '^\|' -and $_ -match 'workspace' })
    if (-not $rows.Count) { return @($false, 'no falsification row mentioning a workspace break') }
    $control = @($rows | Where-Object { $_ -match 'Control' })
    if (-not $control.Count) { return @($false, 'a break row exists but no Control row beside it') }
    return $true
}

# ---------------------------------------------------------------- Task 4
$ledger = Get-Text 'LEDGER.md'

Write-Host ''
Write-Host 'Task 4 - LEDGER backlog entries'

Test-Check 'LEDGER.md is readable' { $null -ne $ledger }

Test-Check 'LEDGER: "### Added by pass 0044" section present' {
    if (-not $ledger) { return @($false, 'no file') }
    if ($ledger -notmatch '(?m)^###\s+Added by pass 0044\s*$') {
        return @($false, 'no "### Added by pass 0044" heading')
    }
    return $true
}

function Get-Ledger0044Body {
    param([string] $Text)
    $lines = $Text -split "`r?`n"
    $idx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^###\s+Added by pass 0044\s*$') { $idx = $i; break }
    }
    if ($idx -lt 0) { return $null }
    $body = @()
    for ($i = $idx + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^###\s+Added by pass ') { break }
        if ($lines[$i] -match '^##\s') { break }
        $body += $lines[$i]
    }
    return , $body
}

Test-Check 'LEDGER: 0044 section numbers run from 59 with no gap or reuse' {
    if (-not $ledger) { return @($false, 'no file') }
    $body = Get-Ledger0044Body -Text $ledger
    if ($null -eq $body) { return @($false, 'section absent') }
    $nums = @()
    foreach ($l in $body) {
        if ($l -match '^(\d+)\.\s+\*\*') { $nums += [int]$Matches[1] }
    }
    if (-not $nums.Count) { return @($false, 'section has no numbered entries') }
    $expected = 59
    foreach ($n in $nums) {
        if ($n -ne $expected) { return @($false, "gap or reuse: saw $n, expected $expected") }
        $expected++
    }
    return $true
}

Test-Check 'LEDGER: 0044 entries cross-reference their 0043 origins' {
    if (-not $ledger) { return @($false, 'no file') }
    $body = Get-Ledger0044Body -Text $ledger
    if ($null -eq $body) { return @($false, 'section absent') }
    $text = $body -join "`n"
    if ($text -notmatch '0043') { return @($false, 'no citation of pass 0043 in the section body') }
    return $true
}

# ---------------------------------------------------------------- Result
Write-Host ''
if ($findings.Count -eq 0) {
    Write-Host 'ACCEPT 0044: GREEN - 0 findings.'
    exit 0
}
Write-Host ("ACCEPT 0044: RED - {0} finding(s):" -f $findings.Count)
foreach ($f in $findings) { Write-Host ("  - {0}" -f $f) }
exit $findings.Count
