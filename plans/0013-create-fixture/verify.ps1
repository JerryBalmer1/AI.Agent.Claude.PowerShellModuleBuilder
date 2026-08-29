#Requires -Version 7.2

<#
.SYNOPSIS
    Verifies Pass 0013 from a fresh clone.

.DESCRIPTION
    Re-derives every claim the plan makes rather than reading the plan. It does
    not parse plan.md, and it does not read the result of any Pester run to
    decide whether that run's subject is true.

    DELIBERATELY SELF-CONTAINED. This script does not dot-source
    evals/functional/AzdoClient.ps1 or FixtureCase.ps1. It carries its own
    Azure DevOps calls, its own checked-by parser and its own test-name
    extractor, independently written, so that agreement between this script and
    the suites is evidence rather than a tautology. Where the suites use the
    PowerShell AST to find test names, this uses a regex; where the suites parse
    a markdown table, this re-reads it separately.

    NETWORK. Checks 2, 3, 4 and 7 read Azure DevOps and need $env:AZDO_PAT.
    When that variable is unset they are SKIPPED with a clear message and the
    script still runs checks 1, 5, 6 and 8, which need nothing but the clone. A
    skipped check reports as skipped and never as agreeing; skips do not affect
    the exit code, and the summary states how many were skipped.

    THE PAT is read from $env:AZDO_PAT only. It is never echoed, never written,
    and never placed in a URL. Check 8 reports the PATHS of any file holding a
    PAT-shaped string and never the matching text.

    Exit 0 when everything it checked agrees, 1 otherwise, naming each check
    that did not.

.PARAMETER FailCheck
    Falsification probe. Names a check to sabotage so that this script can be
    shown capable of failing. Each probe asserts it changed something before the
    check runs. Never use outside a falsification run.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path,
    [ValidateSet('none', 'pat-scan', 'checked-by')]
    [string]$FailCheck = 'none'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Org      = 'jlbalmerjr1'
$Project  = 'ClaudeTesting'
$ApiVer   = '7.1'
$ApiBase  = "https://dev.azure.com/$Org/$Project/_apis"

$fixtureDir   = Join-Path $RepoRoot 'evals/functional'
$reposRoot    = Join-Path $fixtureDir 'fixture/repos'
$casesPath    = Join-Path $fixtureDir 'fixture/cases.md'
$graphPath    = Join-Path $fixtureDir 'fixture/expected-graph.json'
$suiteFixture = Join-Path $fixtureDir 'Fixture.Tests.ps1'
$suiteReadBack= Join-Path $fixtureDir 'ReadBack.Tests.ps1'
$summaryPath  = Join-Path $RepoRoot 'runs/001-fixture-create/create-summary.json'

$failures = [System.Collections.Generic.List[string]]::new()
$skipped  = [System.Collections.Generic.List[string]]::new()

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

function Skip-Check {
    param([string]$Check, [string]$Reason)
    Write-Host ("  SKIP  {0} -- {1}" -f $Check, $Reason) -ForegroundColor Yellow
    $skipped.Add("$Check -- $Reason")
}

$HasPat = [bool]$env:AZDO_PAT
$NoPatReason = 'AZDO_PAT is not set; this check needs the network. It is skipped, not satisfied.'

function Invoke-Azdo {
    param([string]$Uri)
    $h = @{ Authorization = 'Basic ' + [Convert]::ToBase64String(
        [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")) }
    $r = Invoke-WebRequest -Uri $Uri -Headers $h -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction Stop
    if ($r.StatusCode -eq 203) { throw "203 sign-in page for $Uri (PAT expired or under-scoped)" }
    if ($r.StatusCode -ge 400) { throw "HTTP $($r.StatusCode) for $Uri" }
    $r.Content | ConvertFrom-Json
}

function Get-RemoteBytes {
    param([string]$RepoId, [string]$Path)
    $enc = [Uri]::EscapeDataString("/$($Path.TrimStart('/'))")
    $uri = "$ApiBase/git/repositories/$RepoId/items?path=$enc" +
           "&versionDescriptor.versionType=branch&versionDescriptor.version=main" +
           "&download=true&`$format=octetStream&api-version=$ApiVer"
    $c = [Net.Http.HttpClient]::new()
    try {
        $c.DefaultRequestHeaders.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new(
            'Basic', [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")))
        $resp = $c.GetAsync($uri).GetAwaiter().GetResult()
        if (-not $resp.IsSuccessStatusCode) { throw "HTTP $([int]$resp.StatusCode) fetching $Path" }
        $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    }
    finally { $c.Dispose() }
}

function Get-Sha256 {
    param([byte[]]$Bytes)
    $s = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($s.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $s.Dispose() }
}

# ============================================================ check 1

Write-Host 'check 1 - Fixture.Tests.ps1 is green at its full case count' -ForegroundColor Cyan
$pester = Get-Module -ListAvailable Pester | Where-Object Version -GE ([version]'6.0.0') |
    Sort-Object Version -Descending | Select-Object -First 1
if (-not $pester) {
    Assert-True 'Pester 6 is available' $false 'install Pester 6 or later'
}
else {
    Import-Module $pester.Path -Force
    $cfg = New-PesterConfiguration
    $cfg.Run.Path = $suiteFixture
    $cfg.Run.PassThru = $true
    $cfg.Output.Verbosity = 'None'
    $res = Invoke-Pester -Configuration $cfg
    Write-Host ("        total={0} passed={1} failed={2} skipped={3}" -f `
        $res.TotalCount, $res.PassedCount, $res.FailedCount, $res.SkippedCount)
    Assert-True 'Fixture.Tests.ps1 has no failing test' ($res.FailedCount -eq 0) "$($res.FailedCount) failed"
    Assert-True 'Fixture.Tests.ps1 has no skipped test' ($res.SkippedCount -eq 0) "$($res.SkippedCount) skipped"
    Assert-True 'Fixture.Tests.ps1 case count is 352' ($res.TotalCount -eq 352) `
        "count is $($res.TotalCount); Pass 0013 recorded 352. Movement is a finding, not something to absorb."
}

# ============================================================ check 2

Write-Host 'check 2 - read-back assertion 3: all 30 files byte-identical (hashed here, not read from the test)' -ForegroundColor Cyan
if (-not $HasPat) { Skip-Check 'read-back assertion 3 re-derived over all 30 files' $NoPatReason }
else {
    $repos = @((Invoke-Azdo "$ApiBase/git/repositories?api-version=$ApiVer").value)
    $repoById = @{}
    foreach ($r in $repos) { $repoById[$r.name] = $r.id }

    $localFiles = @(Get-ChildItem -LiteralPath $reposRoot -Directory | Sort-Object Name | ForEach-Object {
        $rn = $_.Name
        Get-ChildItem -LiteralPath $_.FullName -Recurse -File | Sort-Object FullName | ForEach-Object {
            [pscustomobject]@{
                Repo = $rn
                Path = ($_.FullName.Substring((Join-Path $reposRoot $rn).Length + 1) -replace '\\', '/')
                Full = $_.FullName
            }
        }
    })

    Assert-True 'the committed fixture holds exactly 30 files' ($localFiles.Count -eq 30) "found $($localFiles.Count)"

    $mismatch = [System.Collections.Generic.List[string]]::new()
    $compared = 0
    foreach ($f in $localFiles) {
        if (-not $repoById.ContainsKey($f.Repo)) { $mismatch.Add("$($f.Repo) missing"); continue }
        $localHash  = Get-Sha256 ([IO.File]::ReadAllBytes($f.Full))
        $remoteHash = Get-Sha256 (Get-RemoteBytes -RepoId $repoById[$f.Repo] -Path $f.Path)
        $compared++
        if ($localHash -ne $remoteHash) { $mismatch.Add("$($f.Repo)/$($f.Path)") }
    }
    Write-Host ("        hashed {0} file pairs independently" -f $compared)
    Assert-True 'all 30 file pairs were compared' ($compared -eq 30) "compared $compared"
    Assert-True 'every committed file is byte-identical on the server' ($mismatch.Count -eq 0) ($mismatch -join ', ')
}

# ============================================================ check 3

Write-Host 'check 3 - read-back assertion 7: every definition build count is zero' -ForegroundColor Cyan
if (-not $HasPat) { Skip-Check 'every definition has never run' $NoPatReason }
else {
    $defs = @((Invoke-Azdo "$ApiBase/build/definitions?api-version=$ApiVer").value)
    Assert-True 'the project holds exactly 15 definitions' ($defs.Count -eq 15) "found $($defs.Count)"
    $ran = [System.Collections.Generic.List[string]]::new()
    foreach ($d in $defs) {
        $b = Invoke-Azdo "$ApiBase/build/builds?definitions=$($d.id)&api-version=$ApiVer"
        if ([int]$b.count -ne 0) { $ran.Add("$($d.name)=$($b.count)") }
    }
    Assert-True 'no definition has ever been run' ($ran.Count -eq 0) ($ran -join ', ')
}

# ============================================================ check 4

Write-Host 'check 4 - read-back assertion 8: ClaudeTesting exists, is empty, no definition targets it' -ForegroundColor Cyan
if (-not $HasPat) { Skip-Check 'ClaudeTesting is present, empty and unreferenced' $NoPatReason }
else {
    $allRepos = @((Invoke-Azdo "$ApiBase/git/repositories?api-version=$ApiVer").value)
    $ct = $allRepos | Where-Object { $_.name -ceq 'ClaudeTesting' }
    Assert-True 'the ClaudeTesting repository exists' ([bool]$ct)

    if ($ct) {
        Assert-True 'the ClaudeTesting repository reports size 0' ([int]$ct.size -eq 0) "size=$($ct.size)"
        $items = @()
        try {
            $r = Invoke-Azdo ("$ApiBase/git/repositories/$($ct.id)/items?recursionLevel=Full" +
                 "&versionDescriptor.versionType=branch&versionDescriptor.version=main&api-version=$ApiVer")
            if ($r.PSObject.Properties.Name -contains 'value') {
                $items = @($r.value | Where-Object { $_.gitObjectType -eq 'blob' })
            }
        }
        catch { $items = @() }   # an empty repository has no main branch and answers 404
        Assert-True 'the ClaudeTesting repository holds no file' ($items.Count -eq 0) "$($items.Count) files"
    }

    $fullDefs = @((Invoke-Azdo "$ApiBase/build/definitions?api-version=$ApiVer").value | ForEach-Object {
        Invoke-Azdo "$ApiBase/build/definitions/$($_.id)?api-version=$ApiVer"
    })
    $targeting = @($fullDefs | Where-Object { $_.repository.name -ceq 'ClaudeTesting' } | ForEach-Object { $_.name })
    Assert-True 'no definition targets the ClaudeTesting repository' ($targeting.Count -eq 0) ($targeting -join ', ')
}

# ============================================================ check 5

Write-Host "check 5 - case 12's absence: no graph node is ClaudeTesting" -ForegroundColor Cyan
$graph = Get-Content -LiteralPath $graphPath -Raw | ConvertFrom-Json
$nodes = @($graph.nodes)
Assert-True 'expected-graph.json has nodes' ($nodes.Count -gt 0) "found $($nodes.Count)"
$offenders = @($nodes | Where-Object {
    $_.id -ceq 'ClaudeTesting' -or
    $_.id -ceq 'repo:ClaudeTesting' -or
    $_.name -ceq 'ClaudeTesting' -or
    ($_.PSObject.Properties.Name -contains 'repo' -and $_.repo -ceq 'ClaudeTesting')
} | ForEach-Object { $_.id })
Assert-True 'no node has an id, name or repo equal to ClaudeTesting' ($offenders.Count -eq 0) ($offenders -join ', ')

# ============================================================ check 6

Write-Host 'check 6 - every checked-by test name resolves to a real test' -ForegroundColor Cyan

# Independently written: the suite uses the AST, this uses a regex, and the two
# must agree. Whitespace is collapsed before matching because a quoted test name
# is hard-wrapped prose and routinely straddles a line break (HARNESS.md hazard 8).
$casesRaw = (Get-Content -LiteralPath $casesPath -Raw) -replace "`r`n", "`n"

$suiteNames = @{}
foreach ($s in @(@{ N = 'Fixture.Tests.ps1'; P = $suiteFixture }, @{ N = 'ReadBack.Tests.ps1'; P = $suiteReadBack })) {
    $txt = Get-Content -LiteralPath $s.P -Raw
    $names = @([regex]::Matches($txt, "(?m)^\s*It\s+(['`"])(?<n>.*?)\1") |
        ForEach-Object { ($_.Groups['n'].Value -replace '\s+', ' ').Trim() })
    $suiteNames[$s.N] = $names
}
Assert-True 'Fixture.Tests.ps1 declares tests'  ($suiteNames['Fixture.Tests.ps1'].Count  -gt 0) "found $($suiteNames['Fixture.Tests.ps1'].Count)"
Assert-True 'ReadBack.Tests.ps1 declares tests' ($suiteNames['ReadBack.Tests.ps1'].Count -gt 0) "found $($suiteNames['ReadBack.Tests.ps1'].Count)"

if ($FailCheck -eq 'checked-by') {
    # PROBE: rename a quoted test in the extracted set. Asserted below to have
    # changed something before the check runs.
    $before = $suiteNames['ReadBack.Tests.ps1'].Count
    $suiteNames['ReadBack.Tests.ps1'] = @($suiteNames['ReadBack.Tests.ps1'] |
        Where-Object { $_ -cne 'the ClaudeTesting repository is still empty' })
    $after = $suiteNames['ReadBack.Tests.ps1'].Count
    Assert-True 'PROBE checked-by actually removed a test name' ($after -eq $before - 1) "before=$before after=$after"
    Write-Host '        PROBE ACTIVE: one quoted test name was removed from the resolvable set' -ForegroundColor Magenta
}

$allNames = @($suiteNames.Values | ForEach-Object { $_ })
$blocks = [regex]::Matches($casesRaw, '(?ms)^\*\*checked by:\*\*[ \t]+(.*?)(?:\n[ \t]*\n|\z)')
Assert-True 'cases.md contains at least one checked-by block' ($blocks.Count -gt 0) "found $($blocks.Count)"

$unresolved = [System.Collections.Generic.List[string]]::new()
$pointerCount = 0
foreach ($b in $blocks) {
    $collapsed = ($b.Groups[1].Value -replace '\s+', ' ').Trim()
    $suites = @([regex]::Matches($collapsed, '`([A-Za-z0-9._-]+\.Tests\.ps1)`') |
        ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    foreach ($q in [regex]::Matches($collapsed, '"([^"]+)"')) {
        $pointerCount++
        $wanted = ($q.Groups[1].Value -replace '\s+', ' ').Trim()
        $candidates = @()
        foreach ($sn in $suites) { if ($suiteNames.ContainsKey($sn)) { $candidates += $suiteNames[$sn] } }
        if ($candidates.Count -eq 0) { $candidates = $allNames }
        if ($candidates -cnotcontains $wanted) { $unresolved.Add($wanted) }
    }
}
Write-Host ("        {0} quoted pointers across {1} checked-by blocks" -f $pointerCount, $blocks.Count)
Assert-True 'at least one quoted pointer exists' ($pointerCount -gt 0) 'nothing to resolve means nothing is checked'
Assert-True 'every quoted checked-by test name resolves' ($unresolved.Count -eq 0) ($unresolved -join ' | ')

# ============================================================ check 7

Write-Host 'check 7 - create-summary.json lists 4 repositories, 30 files, 15 definitions, all ids resolving' -ForegroundColor Cyan
Assert-True 'create-summary.json exists' (Test-Path -LiteralPath $summaryPath)
if (Test-Path -LiteralPath $summaryPath) {
    $sum = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
    Assert-True 'summary names organisation jlbalmerjr1' ($sum.organisation -ceq 'jlbalmerjr1') $sum.organisation
    Assert-True 'summary names project ClaudeTesting'   ($sum.project -ceq 'ClaudeTesting')     $sum.project
    Assert-True 'summary is not a dry run'              (-not $sum.dryRun)
    Assert-True 'summary lists exactly 4 repositories'  (@($sum.repositories).Count -eq 4) "$(@($sum.repositories).Count)"
    Assert-True 'summary lists exactly 30 files'        (@($sum.files).Count -eq 30)       "$(@($sum.files).Count)"
    Assert-True 'summary lists exactly 15 definitions'  (@($sum.definitions).Count -eq 15) "$(@($sum.definitions).Count)"

    if (-not $HasPat) { Skip-Check 'every id in create-summary.json resolves in Azure DevOps' $NoPatReason }
    else {
        $bad = [System.Collections.Generic.List[string]]::new()
        foreach ($r in @($sum.repositories)) {
            try {
                $got = Invoke-Azdo "$ApiBase/git/repositories/$($r.id)?api-version=$ApiVer"
                if ($got.name -cne $r.name) { $bad.Add("repo id $($r.id) is '$($got.name)' not '$($r.name)'") }
            }
            catch { $bad.Add("repo id $($r.id) ($($r.name)) did not resolve") }
        }
        foreach ($d in @($sum.definitions)) {
            try {
                $got = Invoke-Azdo "$ApiBase/build/definitions/$($d.id)?api-version=$ApiVer"
                if ($got.name -cne $d.name) { $bad.Add("definition id $($d.id) is '$($got.name)' not '$($d.name)'") }
            }
            catch { $bad.Add("definition id $($d.id) ($($d.name)) did not resolve") }
        }
        Assert-True 'every id in create-summary.json resolves to the object it names' ($bad.Count -eq 0) ($bad -join '; ')
    }
}

# ============================================================ check 8

Write-Host 'check 8 - no PAT-shaped string in any tracked file, in create-summary.json, or under runs/' -ForegroundColor Cyan

<#
    THE CORRECTED PATTERN.

    The scan originally assumed a 52-character lowercase base32 token
    ('[a-z2-7]{52}'). The PAT in use is 84 characters, mixed-case alphanumeric,
    one unbroken run - measured, never printed.

    Measured correction to the prompt's premise: the previously committed scan
    was NOT blind to it. Its second pattern, '[A-Za-z0-9]{52}', is unanchored,
    so a 52-character window inside an 84-character alphanumeric run matches.
    Verified against the real value: '[a-z2-7]{52}' False, '[A-Za-z0-9]{52}'
    True. The scan could fail, and would have.

    It is corrected anyway, because catching an 84-character secret with a
    52-character window is an accident of length rather than a property of the
    pattern: a PAT containing one non-alphanumeric character would break into
    runs shorter than 52 and slip through.

    FALSE POSITIVES. Two shapes of long alphanumeric run exist in this
    repository, both lower-hex digests: 40-character git object ids and
    64-character SHA-256 hashes, thirty of which are in create-summary.json by
    design. A pure lower-hex run of exactly 40 or 64 characters is therefore
    excluded. Nothing else is excluded, and a PAT cannot hide behind the
    exclusion: 84 is neither 40 nor 64, and a mixed-case token is not lower-hex.
#>
$patPatterns = @(
    @{ Name = 'alphanumeric run >= 52 (covers the measured 84-char PAT)'; Pattern = '[A-Za-z0-9]{52,}' }
    @{ Name = 'legacy base32 run >= 52';                                  Pattern = '[a-z2-7]{52,}' }
    @{ Name = 'JWT';                                                      Pattern = 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' }
    @{ Name = 'assigned secret literal';                                  Pattern = '(?i)(pat|token|secret|password)\s*[=:]\s*["''][^"'']{24,}["'']' }
)

function Test-PatShaped {
    param([string]$Text)
    foreach ($p in $patPatterns) {
        foreach ($m in [regex]::Matches($Text, $p.Pattern)) {
            $v = $m.Value
            # Exclude git object ids and SHA-256 digests, and nothing else.
            if ($v -cmatch '^[0-9a-f]+$' -and ($v.Length -eq 40 -or $v.Length -eq 64)) { continue }
            return $true
        }
    }
    $false
}

Push-Location $RepoRoot
try { $tracked = @(& git ls-files 2>$null) } finally { Pop-Location }
Assert-True 'git ls-files returned files' ($tracked.Count -gt 0) 'run from a git clone'

$scanTargets = [System.Collections.Generic.List[string]]::new()
foreach ($t in $tracked) { $scanTargets.Add((Join-Path $RepoRoot $t)) }
$runsDir = Join-Path $RepoRoot 'runs'
if (Test-Path $runsDir) {
    foreach ($f in (Get-ChildItem -LiteralPath $runsDir -Recurse -File)) { $scanTargets.Add($f.FullName) }
}
$scanTargets = @($scanTargets | Sort-Object -Unique)

if ($FailCheck -eq 'pat-scan') {
    # PROBE: plant an 84-character mixed-case alphanumeric string, the measured
    # shape, in a scratch COPY of a tracked file. The copy is added to the scan
    # set; no tracked file is modified.
    $probeDir = Join-Path ([IO.Path]::GetTempPath()) ("verify-probe-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
    $source = Join-Path $RepoRoot 'README.md'
    $probeFile = Join-Path $probeDir 'README.md'
    Copy-Item -LiteralPath $source -Destination $probeFile
    $rand = [Random]::new(20260828)
    # Built from character ranges, not written as a literal. A literal alphabet
    # is itself a 62-character alphanumeric run and the scan below flags it -
    # correctly, by its own rules, and uselessly, since it is not a secret. This
    # script must not trip the check it exists to run.
    $alphabet = [char[]](([int][char]'a'..[int][char]'z') +
                         ([int][char]'A'..[int][char]'Z') +
                         ([int][char]'0'..[int][char]'9'))
    $synthetic = -join (1..84 | ForEach-Object { $alphabet[$rand.Next(0, $alphabet.Length)] })
    Add-Content -LiteralPath $probeFile -Value "`nAZDO_PAT=$synthetic`n"

    $probeText = Get-Content -LiteralPath $probeFile -Raw
    Assert-True 'PROBE pat-scan actually planted an 84-char token' `
        ($probeText.Length -gt (Get-Content -LiteralPath $source -Raw).Length -and $synthetic.Length -eq 84) `
        "probe file did not change"
    Write-Host "        PROBE ACTIVE: planted an 84-char mixed-case token in $probeFile" -ForegroundColor Magenta
    $scanTargets = @($scanTargets) + @($probeFile)
}

$hits = [System.Collections.Generic.List[string]]::new()
$scanned = 0
foreach ($full in $scanTargets) {
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
    $text = Get-Content -LiteralPath $full -Raw -ErrorAction SilentlyContinue
    if (-not $text) { continue }
    $scanned++
    # Paths are reported. The matching text never is.
    if (Test-PatShaped -Text $text) {
        $hits.Add(($full.Replace($RepoRoot, '').TrimStart('\', '/')))
    }
}
if ($FailCheck -eq 'pat-scan' -and $probeDir -and (Test-Path $probeDir)) {
    # The probe planted a synthetic token on disk; remove it now that it has
    # been scanned, so no PAT-shaped string is left lying around.
    Remove-Item -LiteralPath $probeDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host '        PROBE CLEANED: synthetic token removed from disk' -ForegroundColor Magenta
}

Write-Host ("        scanned {0} files (tracked + everything under runs/)" -f $scanned)
Assert-True 'the scan actually read files' ($scanned -gt 0)
Assert-True 'no scanned file contains a PAT-shaped string' ($hits.Count -eq 0) ($hits -join ', ')
Assert-True 'no tracked file is named like a PAT file' `
    (@($tracked | Where-Object { $_ -match '(^|/)(AzDoPAT\.txt|pat\.txt)$' -or $_ -match '\.pat$' }).Count -eq 0)

# ============================================================ result

Write-Host ''
if ($skipped.Count -gt 0) {
    Write-Host ("{0} check(s) SKIPPED - reported as skipped, never as agreeing:" -f $skipped.Count) -ForegroundColor Yellow
    foreach ($s in $skipped) { Write-Host "  - $s" -ForegroundColor Yellow }
    Write-Host ''
}
if ($failures.Count -eq 0) {
    Write-Host ("verify.ps1: every check that ran agreed ({0} skipped)" -f $skipped.Count) -ForegroundColor Green
    exit 0
}
Write-Host ("verify.ps1: {0} check(s) disagreed" -f $failures.Count) -ForegroundColor Red
foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
exit 1
