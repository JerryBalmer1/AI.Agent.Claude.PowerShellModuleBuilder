#Requires -Version 7.2
<#
.SYNOPSIS
    Refuse a document that tells a builder what its own cases are - a fixture,
    or the brief and seed a run is handed.

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

    TWO RULE SETS, added in pass 0035 for the tf-003 kit.

      -RuleSet Fixture  (default, unchanged) A Terraform repository a builder
                        clones and parses. It has to read as an ordinary
                        configuration written by someone doing their job, so
                        the word "graph" is itself a leak.

      -RuleSet Kit      The BRIEF and the SEED - what the customer hands over.
                        These must be free to say graph, producer, contract and
                        unresolved: that is the job being asked for, and a brief
                        that could not name its own deliverable would not be a
                        brief. What they must not do is say how many of anything
                        there is, which mechanisms are in play, or what the
                        answer looks like.

    THE TWO SETS OVERLAP AND NEITHER CONTAINS THE OTHER. Kit drops all of
    Fixture's graph-vocabulary category and one of its case patterns, and adds a
    category Fixture does not have - counts, shapes and stated expectations.
    Said plainly because a reader who assumed Kit was "Fixture minus some" would
    conclude the kit gate is strictly weaker, and on counts it is strictly
    stronger.

    -Path names what to scan when the subject is not one tree. A kit is a
    document and a directory sitting beside each other, and pointing -FixtureRoot
    at their common parent would scan the whole harness.

.PARAMETER Fixture
    Which fixture to scan. Selects the source root, the repository list and the
    commit messages. Ignored by -RuleSet Kit, which has no published
    repositories and therefore no commit messages.

.PARAMETER RuleSet
    Which rule set to apply: Fixture (default) or Kit. See the description.

.PARAMETER Path
    Scan these files and/or directories instead of a fixture root. A directory
    is scanned recursively; a file is scanned by itself.

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

.EXAMPLE
    ./Test-FixtureSanitization.ps1 -RuleSet Kit -Path ./BRIEF.md, ./seed `
        -Label 'TF003 KIT' -FailCheck
#>
[CmdletBinding()]
param(
    [ValidateSet('fixture1', 'fixture2')]
    [string] $Fixture = 'fixture2',

    [ValidateSet('Fixture', 'Kit')]
    [string] $RuleSet = 'Fixture',

    [string] $FixtureRoot,

    [string[]] $Path,

    [string] $Label,

    [string] $ReportPath,

    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'TfAzdoClient.ps1')

# What gets scanned. -Path wins, then -FixtureRoot, then the fixture the
# -Fixture switch names - so every caller written before pass 0035 scans exactly
# what it scanned before.
if ($Path) {
    $targets = @($Path)
}
else {
    if (-not $FixtureRoot) {
        $FixtureRoot = Join-Path $PSScriptRoot ($Fixture -eq 'fixture2' ? 'fixture2/repos' : 'fixture/repos')
    }
    $targets = @($FixtureRoot)
}
foreach ($target in $targets) {
    if (-not (Test-Path -LiteralPath $target)) { throw "Nothing to scan at '$target'." }
}
if (-not $Label) { $Label = $RuleSet -eq 'Kit' ? 'KIT' : $Fixture.ToUpperInvariant() }

# The rules. Each is a pattern, the category it belongs to, and — where the
# document's own domain vocabulary collides with graph prose — the phrase that
# makes an occurrence legitimate. Patterns are matched case-insensitively.
#
# FIXTURE: a Terraform repository that has to read as an ordinary configuration.
# Unchanged since pass 0034; the 94 findings it reports against fixture 1 are
# what make its "clean" about fixture 2 mean something, and a pattern edited
# here moves that control.
$fixtureRules = @(
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

# KIT: the brief and the seed. A DIFFERENT DOCUMENT WITH A DIFFERENT JOB.
#
# What changes, and why each change is not a weakening:
#
#   dropped   the whole graph-and-producer category (graph, node, edges, parser,
#             producer, parentId, passes-to, traceability, contract). A brief
#             that cannot name its own deliverable is not a brief. These words
#             describe the JOB; in a fixture they would describe the ANSWER.
#
#   dropped   \bunresolv. "Tell me about the sources you could not resolve
#             rather than dropping them" is the customer's requirement, and it
#             is the single most important thing a brief can ask for. In a
#             fixture the same word points at WHICH source is the unresolvable
#             one, which is why it stays banned there.
#
#   added     category C. Counts, shapes and stated expectations - the three
#             ways a brief leaks without ever saying "case". "Twelve cases" is
#             obvious; "three repositories", "four levels deep" and "the
#             expected graph" are the same leak wearing ordinary clothes. The
#             fixture set has no equivalent, so on this axis Kit is STRICTER.
#
#   added     \bfixtures?\b and \btf-\d\d\d\b to category A. The module names
#             are NOT banned: a brief has to name what is being built and cite
#             the schema it emits against.
#
# The worked control is evals/functional/BRIEF.md, the Azure DevOps brief. It
# was written long before any of this and names its cases by number - so this
# rule set scanning it must report findings. A kit gate that called every brief
# clean would be a gate against nothing.
$kitRules = @(
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = 'cases\.md' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = 'expected-graph' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\boracle\b' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\bharness\b' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\bevals/' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\b(plans|runs|decisions|journal)/' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\bdecision\s+\d' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\bLEDGER\b' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\bpass\s+00\d\d\b' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\bfixtures?\b' }
    @{ Category = 'A. points at the harness or the answer sheet'; Pattern = '\btf-\d\d\d\b' }

    @{ Category = 'B. names a case or its answer'; Pattern = '\bcases?\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bdeliberate(ly)?\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bon purpose\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\btraps?\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\b(wrong|right|correct) answer\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bdiscriminat' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\babsence\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bpresence\b'; Unless = 'points?\s+of\s+presence' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bunused\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\bexercis(e|es|ed|ing)\b' }
    @{ Category = 'B. names a case or its answer'; Pattern = '\blink (one|two|three|four|five)\b' }

    @{ Category = 'C. states a count, a shape or an expectation'; Pattern = '\b(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|\d+)\s+(\w+\s+)?(nodes?|edges?|cases?|mechanisms?|levels?|repositor(y|ies)|repos|variables?|locals?|outputs?|providers?|modules?|blocks?|files?|sources?)\b' }
    @{ Category = 'C. states a count, a shape or an expectation'; Pattern = '\bexpected\s+(graph|answer|result|shape|output|node|edge)' }
    @{ Category = 'C. states a count, a shape or an expectation'; Pattern = '\bmust (equal|match)\b' }
    @{ Category = 'C. states a count, a shape or an expectation'; Pattern = '\b(exactly|precisely)\b' }
    @{ Category = 'C. states a count, a shape or an expectation'; Pattern = '\blevels? (deep|of nesting)\b' }
    @{ Category = 'C. states a count, a shape or an expectation'; Pattern = '\bnesting depth\b' }
    @{ Category = 'C. states a count, a shape or an expectation'; Pattern = '\bdiamond\b' }

    @{ Category = 'D. measurement vocabulary'; Pattern = '\bblind\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bscor(e|es|ed|ing)\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bmutations?\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bfalsif' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bconformance\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bmeasurements?\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bgrade[ds]?\b' }
    @{ Category = 'D. measurement vocabulary'; Pattern = '\bbenchmark' }
)

# One line, so the report and every scan below agree about which set is in play.
$rules = $RuleSet -eq 'Kit' ? $kitRules : $fixtureRules

function Get-ScanFile {
    <#
    .SYNOPSIS
        Every file under the given targets, with the name the report shows it by.
    .DESCRIPTION
        A target is either a directory - scanned recursively, its files named
        relative to it - or a single file, named by its leaf. That is what lets
        a kit be scanned as what it is: a document and a directory sitting side
        by side, with no common parent that is not the whole harness.

        .git is skipped. A pack file is not prose, and a scan that read one
        would report on compressed bytes.
    #>
    param([Parameter(Mandatory)] [string[]] $Target)

    foreach ($item in $Target) {
        $resolved = (Resolve-Path -LiteralPath $item).ProviderPath
        if (Test-Path -LiteralPath $resolved -PathType Container) {
            $files = @(Get-ChildItem -LiteralPath $resolved -Recurse -File -Force |
                Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' } |
                Sort-Object FullName)
            foreach ($file in $files) {
                [pscustomobject]@{
                    FullName = $file.FullName
                    Relative = $file.FullName.Substring($resolved.Length).TrimStart('\', '/') -replace '\\', '/'
                }
            }
        }
        else {
            [pscustomobject]@{ FullName = $resolved; Relative = (Split-Path -Leaf $resolved) }
        }
    }
}

function Get-SanitizationFinding {
    <#
    .SYNOPSIS
        Every rule hit under the given targets, plus the commit messages, as
        findings.
    #>
    param(
        [Parameter(Mandatory)] [string[]] $Target,
        [string[]] $CommitMessage = @()
    )

    $findings = [System.Collections.Generic.List[object]]::new()

    foreach ($file in @(Get-ScanFile -Target $Target)) {
        $relative = $file.Relative
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

# Commit messages are fixture content and only a fixture has them. A kit is
# scanned before anything is published anywhere, so there is nothing to read;
# the report says "0 commit message(s)" rather than staying quiet about it.
$messages = @()
if ($RuleSet -eq 'Fixture') {
    $repositories = @(Get-TfFixtureRepoName -Fixture $Fixture)
    $messages = @(foreach ($name in $repositories) { Get-TfFixtureCommitMessage -Fixture $Fixture -RepositoryName $name })
}

$lines = [System.Collections.Generic.List[string]]::new()
$rule = '=' * 78
$thin = '-' * 78

$lines.Add($rule)
$lines.Add('SANITIZATION SCAN')
$lines.Add('Generated ' + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
$lines.Add("Rule set: $RuleSet")
if ($RuleSet -eq 'Fixture') { $lines.Add("Fixture:  $Fixture") }
foreach ($target in $targets) {
    $lines.Add('Target:   ' + ((Resolve-Path -LiteralPath $target).Path -replace '\\', '/'))
}
$lines.Add($rule)
$lines.Add('')
if ($RuleSet -eq 'Fixture') {
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
}
else {
    $lines.Add('THE KIT RULE SET. The subject is a BRIEF and a SEED - what a customer hands')
    $lines.Add('over - and not a repository that has to look innocent. So it is free to say')
    $lines.Add('graph, producer, contract and unresolved: that is the job being asked for,')
    $lines.Add('and a brief that could not name its own deliverable would not be a brief.')
    $lines.Add('')
    $lines.Add('WHAT IT MAY NOT DO: name a case, state how many of anything there is, name a')
    $lines.Add('mechanism, state what the answer looks like, or point into the harness.')
    $lines.Add('Category C - counts, shapes and expectations - exists only in this rule set,')
    $lines.Add('and it is the half that catches a brief leaking without ever saying "case".')
    $lines.Add('')
    $lines.Add('NEITHER RULE SET CONTAINS THE OTHER. Kit drops the graph-vocabulary category')
    $lines.Add('and the unresolved pattern; it adds category C and two category A patterns.')
    $lines.Add('On counts and stated expectations it is STRICTER than the fixture set.')
    $lines.Add('')
    $lines.Add('ALLOWLIST, stated rather than silent:')
    $lines.Add('  presence         allowed only inside "point(s) of presence".')
}
$lines.Add('')

$lines.Add($thin)
$lines.Add("RULES: $($rules.Count) patterns in four categories.")
foreach ($group in ($rules | Group-Object { $_.Category } | Sort-Object Name)) {
    $lines.Add("  $($group.Name) - $($group.Count) pattern(s)")
}
$lines.Add('')

# Enumerated from the targets actually scanned, not from the fixture's
# repository list, because -FixtureRoot is routinely pointed at a single fresh
# clone and a report that said "3 repositories" over one would be quietly wrong.
# EVERY FILE IS NAMED. A count on its own cannot tell a scan that covered the
# kit from one that covered half of it, and half a kit scanning clean is the
# failure this whole gate is against.
$scannedFiles = @(Get-ScanFile -Target $targets)
$lines.Add($thin)
$lines.Add("SCANNED: $($scannedFiles.Count) file(s) across $($targets.Count) target(s):")
foreach ($file in $scannedFiles) { $lines.Add('         ' + $file.Relative) }
$lines.Add("         plus $($messages.Count) commit message(s).")
$lines.Add('')

$findings = @(Get-SanitizationFinding -Target $targets -CommitMessage $messages)

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
        # Every target is copied, each under its own leaf name, so a kit's brief
        # and seed are both present in the copy and the plant lands inside the
        # same set of files the clean scan just read.
        $null = New-Item -ItemType Directory -Path $scratch -Force
        foreach ($item in $targets) {
            $resolved = (Resolve-Path -LiteralPath $item).ProviderPath
            Copy-Item -LiteralPath $resolved -Destination (Join-Path $scratch (Split-Path -Leaf $resolved)) -Recurse -Force
        }

        # A main.tf if there is one - which keeps the fixture falsification
        # planting exactly where it has planted since pass 0034 - and otherwise
        # the first file, so a kit with no Terraform in it is still falsifiable.
        $candidate = @(Get-ChildItem -LiteralPath $scratch -Recurse -File -Filter 'main.tf' | Sort-Object FullName)
        if ($candidate.Count -eq 0) {
            $candidate = @(Get-ChildItem -LiteralPath $scratch -Recurse -File -Force | Sort-Object FullName)
        }
        if ($candidate.Count -eq 0) { throw "Nothing to plant into: the copy at '$scratch' holds no files." }
        $plantTarget = $candidate[0]

        $planted = '# Case 6, the absence case: a graph that invents a reference for this is wrong.'
        $before = [System.IO.File]::ReadAllText($plantTarget.FullName)
        [System.IO.File]::WriteAllText($plantTarget.FullName, $planted + "`n" + $before)

        $plantedRelative = $plantTarget.FullName.Substring($scratch.Length).TrimStart('\', '/') -replace '\\', '/'
        $lines.Add("PLANTED into the copy at ${plantedRelative}:1")
        $lines.Add("  $planted")
        $lines.Add('')

        # Scanned as ONE root here, so the planted path is reported relative to
        # the copy. The rules are the same object either way.
        $caught = @(Get-SanitizationFinding -Target @($scratch))
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
    $lines.Add('The scratch copy has been removed. What was scanned is unchanged on disk.')
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
