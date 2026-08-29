#Requires -Version 7.2

<#
.SYNOPSIS
    Verifies Pass 0012 from a fresh clone.

.DESCRIPTION
    Re-derives every claim the plan makes, rather than reading the plan. It does
    not parse plan.md.

    NO NETWORK. This pass touched no Azure DevOps resource, so neither does
    this. It does not read $env:AZDO_PAT, does not read AzDoPAT.txt, and makes
    no outbound call of any kind. That is a property of Pass 0012 only; Pass
    0013's verify script will need the network.

    Check 2 does NOT reuse evals/functional/FixtureCase.ps1. It carries a
    second, independently written case-declaration reader, so that agreement
    between the two is evidence rather than a tautology.

    Exit 0 when everything agrees, 1 otherwise, naming each check that did not.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$testPath = Join-Path $RepoRoot 'evals/functional/Fixture.Tests.ps1'
$casesPath = Join-Path $RepoRoot 'evals/functional/fixture/cases.md'
$graphPath = Join-Path $RepoRoot 'evals/functional/fixture/expected-graph.json'
$protocolPath = Join-Path $RepoRoot 'PLAN-PROTOCOL.md'
$methodPath = Join-Path $RepoRoot 'method/METHOD.md'

$failures = [System.Collections.Generic.List[string]]::new()
function Assert-True {
    param([string]$Check, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host ("  ok    {0}" -f $Check) -ForegroundColor DarkGreen
    }
    else {
        Write-Host ("  FAIL  {0}{1}" -f $Check, $(if ($Detail) { " -- $Detail" } else { '' })) -ForegroundColor Red
        $failures.Add("$Check$(if ($Detail) { " -- $Detail" })")
    }
}

# ============================================================ check 1

Write-Host 'check 1 - the acceptance test is green at its full case count' -ForegroundColor Cyan
$pester = Get-Module -ListAvailable Pester | Where-Object Version -GE ([version]'6.0.0') | Select-Object -First 1
if (-not $pester) {
    Assert-True 'Pester 6 is available' $false 'install Pester 6 or later'
}
else {
    Import-Module $pester.Path -Force
    $config = New-PesterConfiguration
    $config.Run.Path = $testPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'None'
    $result = Invoke-Pester -Configuration $config
    Assert-True 'Fixture.Tests.ps1 is green' ($result.FailedCount -eq 0) "$($result.FailedCount) failed of $($result.TotalCount)"
    # Pass 0012 recorded 346. Pass 0013 added six assertions to the same suite:
    # one that both named suites exist, four that each test name quoted on a
    # **checked by:** line resolves to a real test, and one that every absence
    # case quotes at least one name - taking it to 352. The count is updated
    # rather than left to fail, because a verify script pinned to a count that a
    # later pass legitimately moved is itself the stale expectation of hazard 6.
    # What Pass 0012 claimed was that the suite is green and that its own twelve
    # cases hold; both still verify below.
    Assert-True 'Fixture.Tests.ps1 runs 352 cases' ($result.TotalCount -eq 352) "$($result.TotalCount) tests"
    Assert-True 'no container failed' (@($result.Containers | Where-Object { -not $_.Passed }).Count -eq 0)
}

# ============================================================ check 2

Write-Host 'check 2 - twelve cases, each with a kind, and the split matches the tags' -ForegroundColor Cyan

# An independent reader. Line based, walking the file top to bottom and
# attributing each marker to the heading above it, rather than slicing the text
# into sections by heading offset the way FixtureCase.ps1 does. Line endings are
# handled by Get-Content rather than by a -replace, which is the other half of
# the CRLF defect this pass found: two readers that both normalise the same way
# would agree while both being wrong.
$declared = [System.Collections.Generic.List[object]]::new()
$currentId = $null
foreach ($line in (Get-Content -LiteralPath $casesPath)) {
    $trimmed = $line.TrimEnd()
    if ($trimmed -match '^##[ \t]+(case-\d{2})\b') {
        $currentId = $Matches[1]
        $declared.Add([pscustomobject]@{ Id = $currentId; Kind = $null; CheckedBy = $null })
        continue
    }
    if (-not $currentId) { continue }
    if ($trimmed -match '^\*\*kind:\*\*[ \t]+(presence|absence)[ \t]*$') {
        $declared[-1].Kind = $Matches[1]
        continue
    }
    if ($trimmed -match '^\*\*checked by:\*\*[ \t]+(\S.*)$') {
        if (-not $declared[-1].CheckedBy) { $declared[-1].CheckedBy = $Matches[1] }
    }
}

Assert-True 'cases.md declares twelve cases' ($declared.Count -eq 12) "$($declared.Count)"
Assert-True 'every case declares a kind' (@($declared | Where-Object { -not $_.Kind }).Count -eq 0) `
    ((@($declared | Where-Object { -not $_.Kind } | ForEach-Object Id)) -join ', ')

$presenceIds = @($declared | Where-Object Kind -EQ 'presence' | ForEach-Object Id)
$absenceIds = @($declared | Where-Object Kind -EQ 'absence' | ForEach-Object Id)
Assert-True 'there is at least one presence case' ($presenceIds.Count -gt 0)
Assert-True 'there is at least one absence case' ($absenceIds.Count -gt 0)
Assert-True 'every absence case names the assertion that checks it' `
(@($declared | Where-Object { $_.Kind -eq 'absence' -and -not $_.CheckedBy }).Count -eq 0) `
    ((@($declared | Where-Object { $_.Kind -eq 'absence' -and -not $_.CheckedBy } | ForEach-Object Id)) -join ', ')

$graph = Get-Content -LiteralPath $graphPath -Raw | ConvertFrom-Json
$nodes = @($graph.nodes)
$edges = @($graph.edges)
$tagged = @(
    @($nodes) + @($edges) |
        Where-Object { $_ -and $_.PSObject.Properties.Name -contains 'cases' } |
        ForEach-Object { $_.cases } |
        Sort-Object -Unique
)
$untagged = @($presenceIds | Where-Object { $_ -notin $tagged })
$wronglyTagged = @($absenceIds | Where-Object { $_ -in $tagged })
$invented = @($tagged | Where-Object { $_ -notin $presenceIds })
Assert-True 'every presence case is tagged at least once' ($untagged.Count -eq 0) ($untagged -join ', ')
Assert-True 'no absence case is tagged' ($wronglyTagged.Count -eq 0) ($wronglyTagged -join ', ')
Assert-True 'the graph carries no tag that is not a presence case' ($invented.Count -eq 0) ($invented -join ', ')

# The CRLF property, re-derived here too. A fresh clone on Windows with
# core.autocrlf=true delivers this file CRLF, and the reader above must not care.
$crlfCopy = Join-Path ([System.IO.Path]::GetTempPath()) "verify-cases-$([guid]::NewGuid()).md"
try {
    $raw = Get-Content -LiteralPath $casesPath -Raw
    [System.IO.File]::WriteAllText($crlfCopy, ($raw -replace "`r`n", "`n" -replace "`n", "`r`n"))
    $crlfKinds = @()
    $cid = $null
    foreach ($line in (Get-Content -LiteralPath $crlfCopy)) {
        $t = $line.TrimEnd()
        if ($t -match '^##[ \t]+(case-\d{2})\b') { $cid = $Matches[1]; continue }
        if ($cid -and $t -match '^\*\*kind:\*\*[ \t]+(presence|absence)[ \t]*$') { $crlfKinds += "$cid=$($Matches[1])" }
    }
    $expected = @($declared | Where-Object Kind | ForEach-Object { "$($_.Id)=$($_.Kind)" })
    Assert-True 'the declarations read identically from a CRLF copy' (($crlfKinds -join ',') -eq ($expected -join ',')) `
        "crlf: $($crlfKinds.Count), lf: $($expected.Count)"
}
finally {
    Remove-Item -LiteralPath $crlfCopy -ErrorAction SilentlyContinue
}

# ============================================================ check 3

Write-Host 'check 3 - case 12: no node names the pre-existing ClaudeTesting repository' -ForegroundColor Cyan
$offenders = @(
    $nodes | Where-Object {
        $_.id -eq 'ClaudeTesting' -or
        $_.id -eq 'repo:ClaudeTesting' -or
        $_.name -eq 'ClaudeTesting' -or
        ($_.PSObject.Properties.Name -contains 'repo' -and $_.repo -eq 'ClaudeTesting')
    } | ForEach-Object { $_.id }
)
Assert-True 'no node is the ClaudeTesting repository' ($offenders.Count -eq 0) ($offenders -join ', ')
Assert-True 'the graph still has exactly four repo nodes' (@($nodes | Where-Object kind -EQ 'repo').Count -eq 4) `
    "$(@($nodes | Where-Object kind -EQ 'repo').Count)"
Assert-True 'case-12 appears nowhere in expected-graph.json' `
(-not ((Get-Content -LiteralPath $graphPath -Raw) -match 'case-12'))

# ============================================================ check 4

# Prose in these documents is hard-wrapped, so a multi-word phrase is routinely
# split across a line break and a naive -match fails on the wrapping rather than
# on the content. Every phrase check below runs against a whitespace-collapsed
# copy. The first version of check 5 reported METHOD.md uncorrected when it was
# correct, for exactly that reason.
function Get-FlatText {
    param([string]$Path)
    ((Get-Content -LiteralPath $Path -Raw) -replace '\s+', ' ')
}

Write-Host 'check 4 - PLAN-PROTOCOL.md corrections' -ForegroundColor Cyan
$protocol = Get-FlatText $protocolPath
# The requirement is gone; the sentence explaining its absence is allowed to
# name it. "-match 'token count'" cannot tell those apart and was wrong.
Assert-True 'no longer requires "an approximate token count"' (-not ($protocol -cmatch 'approximate token count'))
Assert-True 'states that there is no token count' ($protocol -cmatch 'No token count\.')
Assert-True 'section 11 asks for wall-clock and run counts' ($protocol -match '11\. Cost Wall-clock for the pass, plus any run counts')
Assert-True 'no longer requires verify.ps1 fenced unconditionally' `
(-not ($protocol -match 'verify\.ps1., in a fenced block in the plan and committed beside it'))
Assert-True 'section 9 states the conditional form' ($protocol -match 'only when short enough that no reader will diff the two copies')

# ============================================================ check 5

Write-Host 'check 5 - method/METHOD.md no longer says to skip the corpus' -ForegroundColor Cyan
$method = Get-FlatText $methodPath
# Case-sensitive on purpose: "Skip the corpus" and "not skip the corpus" differ
# only in the words before them, and -match is case-insensitive by default, so
# the negation matched its own prohibition.
Assert-True 'does not instruct "Skip the corpus"' (-not ($method -cmatch '(?<!not )Skip the corpus'))
Assert-True 'does not list the corpus among things to skip' `
(-not ($method -match 'Skip the corpus, the harness, and the decisions log'))
Assert-True 'says the corpus is not to be skipped' ($method -match 'Do not skip the corpus')
Assert-True 'gives the reason the corpus stays' ($method -match 'it is what breaks the closed loop')

# ============================================================ check 6

Write-Host 'check 6 - no PAT-shaped string in any tracked file' -ForegroundColor Cyan
Push-Location $RepoRoot
try { $tracked = @(& git ls-files 2>$null) } finally { Pop-Location }
if ($tracked.Count -eq 0) {
    Assert-True 'git ls-files returned files' $false 'run from a git clone'
}
else {
    # Corrected by Pass 0013. The original pattern set assumed a 52-character
    # lowercase base32 token. The PAT actually in use is 84 characters,
    # mixed-case alphanumeric, one unbroken run - measured, never printed.
    #
    # Measured correction: the original set was NOT blind to it. Its second
    # pattern, '[A-Za-z0-9]{52}', is unanchored, so a 52-character window inside
    # an 84-character run matched. This scan could fail, and would have. It is
    # widened anyway, because catching an 84-character secret with a
    # 52-character window is an accident of length rather than a property of the
    # pattern: a PAT containing one non-alphanumeric character would break into
    # runs shorter than 52 and slip through.
    #
    # The exclusion is the substantive change. Pass 0013 committed
    # runs/001-fixture-create/create-summary.json, which carries thirty
    # 64-character SHA-256 digests, and documented 40-character git object ids.
    # Both match '[A-Za-z0-9]{52}'. Without the exclusion below, this check goes
    # red on files that contain no secret, and a check that cries wolf is a check
    # that gets switched off. A PAT cannot hide behind the exclusion: 84 is
    # neither 40 nor 64, and a mixed-case token is not lower-hex.
    $patterns = @(
        '[A-Za-z0-9]{52,}'
        '[a-z2-7]{52,}'
        'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
    )
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($relative in $tracked) {
        $full = Join-Path $RepoRoot $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        $text = Get-Content -LiteralPath $full -Raw -ErrorAction SilentlyContinue
        if (-not $text) { continue }
        $flagged = $false
        foreach ($pattern in $patterns) {
            foreach ($m in [regex]::Matches($text, $pattern)) {
                $v = $m.Value
                # git object id (40) or SHA-256 digest (64), and nothing else.
                if ($v -cmatch '^[0-9a-f]+$' -and ($v.Length -eq 40 -or $v.Length -eq 64)) { continue }
                $flagged = $true
                break
            }
            if ($flagged) { break }
        }
        if ($flagged) { $hits.Add($relative) }
    }
    # Paths are reported. The matching text never is.
    Assert-True 'no tracked file contains a PAT-shaped token' ($hits.Count -eq 0) ($hits -join ', ')
    Assert-True 'AzDoPAT.txt is not tracked' ($tracked -notcontains 'AzDoPAT.txt')
    Assert-True 'no tracked file is named like a PAT file' `
    (@($tracked | Where-Object { $_ -match '(^|/)(AzDoPAT\.txt|pat\.txt)$' -or $_ -match '\.pat$' }).Count -eq 0)
}

# ============================================================ result

Write-Host ''
if ($failures.Count -eq 0) {
    Write-Host 'VERIFY: all checks agree.' -ForegroundColor Green
    exit 0
}
Write-Host "VERIFY: $($failures.Count) check(s) disagreed:" -ForegroundColor Red
$failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
exit 1
