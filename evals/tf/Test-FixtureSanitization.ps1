#Requires -Version 7.2
<#
.SYNOPSIS
    Refuse a fixture that tells a builder what its own cases are.

.DESCRIPTION
    Pass 0033 read the Terraform fixture by hand — 40 files, every comment,
    every `description` string, every README, against the oracle's case list —
    and found that the fixture names its cases by number, states the wrong
    answer to several, and points at `cases.md` by path. That scan was commands
    and reading; its verdict survives in
    `plans/0033-honest-headline/tf-fixture-comments.txt` and nothing else. A
    scan nobody can re-run is a claim, not a gate, which is why pass 0034
    promoted it to this file.

    What it enforces, from decision 0014:

        No comment, string, identifier, README line or commit message in a
        fixture may name a case, name the oracle, describe presence or absence
        as a case, use the word "graph", or point into the harness.

    Fixture 1 fails this and is expected to: it is frozen and its bound is
    disclosed rather than repaired. Fixture 2 was written to pass it, and this
    script is the standing gate that keeps it passing.

    THE COMMIT MESSAGE IS IN SCOPE. A repository whose files are mute and whose
    first commit says "Terraform fixture for PSTerraformGraph scoring" has
    leaked the same thing one `git log` later. The messages are read from
    `Get-TfFixtureCommitMessage`, the same function `Publish-TfFixture.ps1`
    pushes with, so the two cannot drift.

    TWO ALLOWLIST ENTRIES, both stated rather than silent:

      * `edge` (singular) is fixture 2's domain vocabulary — `TfSiteEdge`,
        `modules/edge`, `local.edge_name`. The plural `edges` is graph prose,
        never appears in the fixture, and is refused.
      * `presence` is refused except in `point(s) of presence`, which is
        networking vocabulary and is what `modules/pop` is.

    An allowlist is where a gate goes quietly useless, so -FailCheck plants a
    banned comment in a scratch copy and requires the scan to flag it before
    any clean verdict is trusted.

.PARAMETER Fixture
    Which fixture to scan. Selects the source root, the repository list and the
    commit messages.

.PARAMETER FixtureRoot
    Scan this directory instead of the fixture the -Fixture switch names. For
    scanning a fresh clone, or a scratch copy.

.PARAMETER Label
    The word the headline verdict carries. Defaults to FIXTURE1 / FIXTURE2.

.PARAMETER ReportPath
    Write the report here as well as to the pipeline.

.PARAMETER FailCheck
    Prove the scanner can fail: copy the fixture to a scratch directory, plant
    one case-naming comment, scan the copy, and require the finding. The copy is
    removed afterwards and the fixture itself is never written to.

.OUTPUTS
    The report text. Exit code 0 when the scan is clean and, if -FailCheck was
    asked for, the planted comment was caught; 1 otherwise.

.EXAMPLE
    ./Test-FixtureSanitization.ps1 -Fixture fixture2 -FailCheck -ReportPath ../../plans/0034-fixture2/sanitization.txt

.EXAMPLE
    ./Test-FixtureSanitization.ps1 -Fixture fixture1
    # Expected to report findings. Fixture 1 is frozen and annotated.
#>
[CmdletBinding()]
param(
    [ValidateSet('fixture1', 'fixture2')]
    [string] $Fixture = 'fixture2',

    [string] $FixtureRoot,

    [string] $Label,

    [string] $ReportPath,

    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'TfAzdoClient.ps1')

if (-not $FixtureRoot) {
    $FixtureRoot = Join-Path $PSScriptRoot ($Fixture -eq 'fixture2' ? 'fixture2/repos' : 'fixture/repos')
}
if (-not (Test-Path -LiteralPath $FixtureRoot)) { throw "No fixture source at '$FixtureRoot'." }
if (-not $Label) { $Label = $Fixture.ToUpperInvariant() }

# The rules. Each is a pattern, the category it belongs to, and — where the
# fixture's own domain vocabulary collides with graph prose — the phrase that
# makes an occurrence legitimate. Patterns are matched case-insensitively.
$rules = @(
    @{ Category = 'A. points at the harness or the oracle'; Pattern = 'cases\.md' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = 'expected-graph' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = '\boracle\b' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = '\bharness\b' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = '\bevals/' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = '\b(plans|runs|skills|decisions|journal)/' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = 'PSTerraformGraph|PSGraphRender|PSAzureDevOpsGraph|PSModuleGraph' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = '\bdecision\s+\d' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = '\bLEDGER\b' }
    @{ Category = 'A. points at the harness or the oracle'; Pattern = '\bpass\s+00\d\d\b' }

    @{ Category = 'B. names a case or its answer'; Pattern = '\bcases?\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bfixtures?\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bdeliberate(ly)?\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bon purpose\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\btraps?\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bwrong answer\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bdiscriminat' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\babsence\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bpresence\b'; Unless = 'points?\s+of\s+presence' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bunused\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bunresolv' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bexercis(e|es|ed|ing)\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\blink (one|two|three|four|five)\b' }

    @{ Category = 'C. graph or producer vocabulary'; Pattern = '\bgraphs?\b' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = '\bnodes?\b' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = '\bedges\b' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = '\bparsers?\b' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = '\bproducers?\b' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = 'parentId' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = 'passes-to' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = '\btraceability\b' }
    @{ Category = 'C. graph or producer vocabulary'; Pattern = '\bcontract\b' }

    @{ Category = 'D. measurement vocabulary'; Pattern = '\bblind\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bscor(e|es|ed|ing)\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bmutations?\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bfalsif' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bconformance\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bmeasurements?\b' }
)

function Get-SanitizationFinding {
    <#
    .SYNOPSIS
        Every rule hit under one root, plus the commit messages, as findings.
    #>
    param(
        [Parameter(Mandatory)] [string] $Root,
        [string[]] $CommitMessage = @()
    )

    $findings = [System.Collections.Generic.List[object]]::new()

    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
        Sort-Object FullName)

    foreach ($file in $files) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
        $lines = [System.IO.File]::ReadAllLines($file.FullName)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            foreach ($rule in $rules) {
                if ($line -notmatch $rule.Pattern) { continue }
                if ($rule.Contains('Unless') -and $line -match $rule.Unless) { continue }
                $findings.Add([pscustomobject]@{
                        Category = $rule.Category
                        Location = "${relative}:$($i + 1)"
                        Token    = $rule.Pattern
                        Text     = $line.Trim()
                    })
            }
        }
    }

    foreach ($message in $CommitMessage) {
        foreach ($rule in $rules) {
            if ($message -notmatch $rule.Pattern) { continue }
            if ($rule.Contains('Unless') -and $message -match $rule.Unless) { continue }
            $findings.Add([pscustomobject]@{
                    Category = $rule.Category
                    Location = '<commit message>'
                    Token    = $rule.Pattern
                    Text     = $message
                })
        }
    }

    # Emitted unwrapped, NOT comma-wrapped. Every caller writes `@(...)` around
    # the call, and `@( , @(a,b) )` is a one-element array holding an array —
    # which reads as "one finding" and then fails on the first property access.
    # Cost twenty minutes once; stated so it costs nobody else any.
    $findings | Sort-Object Category, Location, Token
}

$repositories = @(Get-TfFixtureRepoName -Fixture $Fixture)
$messages = @(foreach ($name in $repositories) { Get-TfFixtureCommitMessage -Fixture $Fixture -RepositoryName $name })

$lines = [System.Collections.Generic.List[string]]::new()
$rule = '=' * 78
$thin = '-' * 78

$lines.Add($rule)
$lines.Add('FIXTURE SANITIZATION SCAN')
$lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
$lines.Add("Fixture: $Fixture")
$lines.Add('Root:    ' + ((Resolve-Path -LiteralPath $FixtureRoot).Path -replace '\\', '/'))
$lines.Add($rule)
$lines.Add('')
$lines.Add('Decision 0014: no comment, string, identifier, README line or commit message')
$lines.Add('in a fixture may name a case, name the oracle, describe presence or absence as')
$lines.Add('a case, use the word "graph", or point into the harness. Pass 0033 established')
$lines.Add('why by reading fixture 1 by hand and finding all four; this is that reading,')
$lines.Add('promoted to something anyone can re-run.')
$lines.Add('')
$lines.Add('COMMIT MESSAGES ARE IN SCOPE. They are read from Get-TfFixtureCommitMessage,')
$lines.Add('the same function Publish-TfFixture.ps1 pushes with, so a mute repository')
$lines.Add('cannot leak its cases one git log later.')
$lines.Add('')
$lines.Add('ALLOWLIST, stated rather than silent:')
$lines.Add('  edge (singular)  domain vocabulary here - TfSiteEdge, modules/edge. The')
$lines.Add('                   plural "edges" is graph prose and is refused.')
$lines.Add('  presence         allowed only inside "point(s) of presence".')
$lines.Add('')

$lines.Add($thin)
$lines.Add("RULES: $($rules.Count) patterns in four categories.")
foreach ($group in ($rules | Group-Object { $_.Category } | Sort-Object Name)) {
    $lines.Add("  $($group.Name) - $($group.Count) pattern(s)")
}
$lines.Add('')

$scannedFiles = @(Get-ChildItem -LiteralPath $FixtureRoot -Recurse -File -Force |
    Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' })
# Counted from the root actually scanned, not from the fixture's repository
# list, because -FixtureRoot is routinely pointed at a single fresh clone and a
# report that said "3 repositories" over one would be quietly wrong.
$scannedDirs = @(Get-ChildItem -LiteralPath $FixtureRoot -Directory | Sort-Object Name)
$lines.Add($thin)
$lines.Add("SCANNED: $($scannedFiles.Count) file(s) under $($scannedDirs.Count) top-level director(ies):")
$lines.Add('         ' + (($scannedDirs.Name) -join ', '))
$lines.Add("         plus $($messages.Count) commit message(s) for $Fixture.")
$lines.Add('')

$findings = @(Get-SanitizationFinding -Root $FixtureRoot -CommitMessage $messages)

$lines.Add($thin)
if ($findings.Count -eq 0) {
    $lines.Add('FINDINGS: none.')
}
else {
    $lines.Add("FINDINGS: $($findings.Count)")
    $lines.Add('')
    foreach ($group in ($findings | Group-Object Category | Sort-Object Name)) {
        $lines.Add($group.Name)
        foreach ($finding in $group.Group) {
            $lines.Add(('  {0}   [{1}]' -f $finding.Location, $finding.Token))
            $lines.Add(('      {0}' -f $finding.Text))
        }
        $lines.Add('')
    }
}
$lines.Add('')

$falsificationFailed = $false
if ($FailCheck) {
    $lines.Add($thin)
    $lines.Add('FALSIFICATION - a scan that has only ever agreed with a clean fixture is')
    $lines.Add('indistinguishable from a scan that cannot disagree. One banned comment is')
    $lines.Add('planted in a SCRATCH COPY; the fixture itself is never written to.')
    $lines.Add('')

    $scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('tf-sanitization-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
    try {
        Copy-Item -LiteralPath $FixtureRoot -Destination $scratch -Recurse -Force
        $target = @(Get-ChildItem -LiteralPath $scratch -Recurse -File -Filter 'main.tf' | Sort-Object FullName)[0]
        $planted = '# Case 6, the absence case: a graph that invents a reference for this is wrong.'
        $before = [System.IO.File]::ReadAllText($target.FullName)
        [System.IO.File]::WriteAllText($target.FullName, $planted + "`n" + $before)

        $plantedRelative = $target.FullName.Substring($scratch.Length).TrimStart('\', '/') -replace '\\', '/'
        $lines.Add("PLANTED into the copy at ${plantedRelative}:1")
        $lines.Add("  $planted")
        $lines.Add('')

        $caught = @(Get-SanitizationFinding -Root $scratch)
        $onLineOne = @($caught | Where-Object { $_.Location -eq "${plantedRelative}:1" })
        $lines.Add("CAUGHT: $($onLineOne.Count) finding(s) on the planted line, across these rules:")
        foreach ($finding in $onLineOne) { $lines.Add("  [$($finding.Token)]  $($finding.Category)") }

        if ($onLineOne.Count -eq 0) {
            $lines.Add('FALSIFICATION FAILED - the planted comment was not flagged. Nothing this')
            $lines.Add('script reports about any fixture can be trusted.')
            $falsificationFailed = $true
        }
        else {
            $lines.Add('FALSIFICATION PASSED - the scanner can fail.')
        }
    }
    finally {
        if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
    }
    $lines.Add('')
    $lines.Add('The scratch copy has been removed. The fixture on disk is unchanged.')
    $lines.Add('')
}

$lines.Add($rule)
if ($findings.Count -eq 0) { $lines.Add("$Label SANITIZATION: clean") }
else { $lines.Add("$Label SANITIZATION: $($findings.Count) finding(s)") }
if ($FailCheck) {
    $lines.Add("$Label FALSIFICATION: " + ($falsificationFailed ? 'FAILED' : 'the scanner was shown to fail'))
}
$lines.Add($rule)

$report = $lines -join [Environment]::NewLine
$report

if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
    Set-Content -LiteralPath $ReportPath -Value $report -Encoding utf8NoBOM
}

if ($findings.Count -gt 0 -or $falsificationFailed) { exit 1 }
exit 0
