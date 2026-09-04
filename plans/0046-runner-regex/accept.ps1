#Requires -Version 7.2
<#
.SYNOPSIS
    Acceptance test for pass 0046 - the runner's path-exclusion regex.

.DESCRIPTION
    LEDGER backlog 62. evals/conformance/Invoke-Conformance.ps1 writes the
    path-exclusion character class as '[\/]' where the three copies in the
    suite write '[\\/]'. Inside a character class '\/' is an escaped forward
    slash and NOTHING ELSE, so the runner's exclusion of
    output|scratch|.git|gallery|fixtures|node_modules has never fired on a
    Windows path - and every path it tests is a Windows path, built by
    .Substring() on a FileInfo.FullName.

    The defect has two directions and this script observes both, because only
    one of them has ever been seen and it is the harmless one.

    RED A - the refusal direction. With a manifest planted under output/, the
    runner counts two candidates named for the target, cannot decide, falls
    into its src/ rule, finds two manifests under src/ (the module's own and a
    vendored templateset one), and REFUSES. That is what pass 0045 hit. A
    refusal is the good direction: it is loud.

    RED B - the admission direction, the dangerous one. A manifest planted
    under scratch/ SURVIVES the runner's exclusion filter, because the filter
    cannot see a backslash. Nothing is printed. Rule F-8's own comment in the
    runner says that grading the wrong module silently is worse than grading
    nothing, and this is the door to it.

    Both are measured against a scratch clone of PSGraphRender with two
    manifests planted:
        output/PSGraphRender/PSGraphRender.psd1   (a copy of the real one)
        scratch/Fake/Fake.psd1

    The exclusion patterns are EXTRACTED FROM SOURCE, never retyped. A test
    that retypes the pattern it is testing tests the retyped copy.

    Exit 0 when every check agrees with the repaired state; non-zero, naming
    the checks that disagreed, otherwise. Run it before the repair and it is
    red; run it after and it is green. Writes only under scratch/ and removes
    what it wrote.

.PARAMETER RepoRoot
    Harness root - the instrument under test. Defaults to two levels above
    this script.
.PARAMETER TargetRemote
    Where to clone PSGraphRender from. Defaults to the origin of the sibling
    checkout when there is one, and to the known remote otherwise.
.PARAMETER Ref
    Commit or branch of PSGraphRender to clone. Default main.
.PARAMETER Keep
    Leave the planted clone in place for inspection instead of deleting it.
.EXAMPLE
    ./plans/0046-runner-regex/accept.ps1
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $Ref = 'main',
    [switch] $Keep
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$runner = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'
$suiteFile = Join-Path $RepoRoot 'evals/conformance/Conformance.Tests.ps1'
foreach ($f in @($runner, $suiteFile)) {
    if (-not (Test-Path -LiteralPath $f)) { throw "Not found: $f" }
}

if (-not $TargetRemote) {
    $sibling = Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender'
    if (Test-Path -LiteralPath (Join-Path $sibling '.git')) {
        $TargetRemote = (& git -C $sibling remote get-url origin).Trim()
    }
    else {
        $TargetRemote = 'https://github.com/JerryBalmer1/PSGraphRender.git'
    }
}

$work = Join-Path $RepoRoot 'scratch/accept-0046'
if (@($work -split '[\\/]') -notcontains 'scratch') { throw "Refusing to write outside scratch/: $work" }

$failures = [System.Collections.Generic.List[string]]::new()

function Assert-That {
    param(
        [Parameter(Mandatory)][string] $What,
        [Parameter(Mandatory)][bool] $Ok,
        [string] $Detail = ''
    )
    $suffix = ''
    if ($Detail) { $suffix = " - $Detail" }
    '  [{0}] {1}{2}' -f $(if ($Ok) { 'ok  ' } else { 'FAIL' }), $What, $suffix
    if (-not $Ok) { $script:failures.Add("$What$suffix") }
}

function Get-ExclusionPattern {
    <#
        Every single-quoted literal in a file that mentions the exclusion
        alternation, quotes stripped. Read from source so the test cannot
        disagree with the thing it grades.

        Zero matches is NOT an empty answer to return quietly: it would make
        every downstream comparison vacuous. The caller asserts the count.
    #>
    param([Parameter(Mandatory)][string] $Path)
    $text = Get-Content -LiteralPath $Path -Raw
    @([regex]::Matches($text, "'[^']*output\|scratch[^']*'") |
        ForEach-Object { $_.Value.Trim("'") })
}

function Get-CandidateSet {
    <#
        The runner's own candidate filter, with the exclusion pattern as a
        parameter. Same two Where-Object clauses, in the same order, over the
        same Get-ChildItem - so the only thing that varies between two calls is
        the pattern, which is the variable under test.
    #>
    param(
        [Parameter(Mandatory)][string] $Target,
        [Parameter(Mandatory)][string] $Pattern
    )
    @(Get-ChildItem -Path $Target -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $_.BaseName -eq $_.Directory.Name -or
            ($_.Directory.Name -match '^\d+(\.\d+)*([-+].*)?$' -and
                $_.Directory.Parent -and $_.BaseName -eq $_.Directory.Parent.Name)
        } |
        Where-Object {
            $_.FullName.Substring($Target.Length) -notmatch $Pattern
        } |
        ForEach-Object { $_.FullName.Substring($Target.Length).TrimStart('\', '/') } |
        Sort-Object)
}

try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $work -Force

    ''
    'ACCEPT 0046 - runner path-exclusion regex'
    "  instrument (harness): $RepoRoot"
    "  target remote:        $TargetRemote"
    ''

    # Named PSGraphRender on purpose: the runner compares the target's LEAF
    # name against candidate manifest base names, so a directory called 'clone'
    # would be answering a different question from the real one.
    $clone = Join-Path $work 'PSGraphRender'
    & git clone --quiet $TargetRemote $clone 2>&1 | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $clone '.git'))) { throw "Clone failed: $TargetRemote" }
    & git -C $clone checkout --quiet $Ref
    $head = (& git -C $clone rev-parse --short HEAD).Trim()
    "  cloned: $Ref @ $head"

    # ------------------------------------------------------------- planting
    $realManifest = Join-Path $clone 'src/PSGraphRender/PSGraphRender.psd1'
    if (-not (Test-Path -LiteralPath $realManifest)) { throw "No src manifest in the clone: $realManifest" }

    $plantedOutput = Join-Path $clone 'output/PSGraphRender/PSGraphRender.psd1'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $plantedOutput) -Force
    Copy-Item -LiteralPath $realManifest -Destination $plantedOutput -Force

    $plantedScratch = Join-Path $clone 'scratch/Fake/Fake.psd1'
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $plantedScratch) -Force
    Copy-Item -LiteralPath $realManifest -Destination $plantedScratch -Force

    # A plant that did not land makes every check below vacuous, and it would
    # fail toward green. Assert it, do not assume it.
    Assert-That -What 'planted output/PSGraphRender/PSGraphRender.psd1' `
        -Ok (Test-Path -LiteralPath $plantedOutput) -Detail 'copy of the real manifest'
    Assert-That -What 'planted scratch/Fake/Fake.psd1' `
        -Ok (Test-Path -LiteralPath $plantedScratch) -Detail 'copy of the real manifest'
    ''

    # --------------------------------------------------- the patterns, read
    'PATTERNS, extracted from source'
    $runnerPatterns = @(Get-ExclusionPattern -Path $runner)
    $suitePatterns = @(Get-ExclusionPattern -Path $suiteFile)
    Assert-That -What 'exactly one exclusion literal in Invoke-Conformance.ps1' `
        -Ok ($runnerPatterns.Count -eq 1) -Detail "found $($runnerPatterns.Count)"
    Assert-That -What 'two exclusion literals in Conformance.Tests.ps1' `
        -Ok ($suitePatterns.Count -eq 2) -Detail "found $($suitePatterns.Count)"
    if ($runnerPatterns.Count -lt 1 -or $suitePatterns.Count -lt 1) {
        throw 'Pattern extraction found nothing. Every check below would be vacuous.'
    }
    $runnerPattern = $runnerPatterns[0]
    $suitePattern = $suitePatterns[0]
    "  runner: $runnerPattern"
    "  suite:  $suitePattern"
    ''

    # ---------------------------------------------------------------- RED B
    #
    # First, because it is the direction nobody has seen and it needs no run of
    # anything: the character class either matches a backslash or it does not.
    'B. ADMISSION DIRECTION - does the exclusion see a Windows path?'
    $winPaths = @(
        '\output\PSGraphRender\PSGraphRender.psd1'
        '\scratch\Fake\Fake.psd1'
    )
    $rows = foreach ($p in $winPaths) {
        [pscustomobject]@{
            Path           = $p
            RunnerExcludes = [bool]($p -match $runnerPattern)
            SuiteExcludes  = [bool]($p -match $suitePattern)
        }
    }
    ($rows | Format-Table -AutoSize | Out-String).TrimEnd()
    ''
    foreach ($row in $rows) {
        Assert-That -What "runner pattern excludes '$($row.Path)'" -Ok $row.RunnerExcludes `
            -Detail "suite pattern excludes it: $($row.SuiteExcludes)"
    }

    # And the same claim end to end, through the runner's own filter shape.
    $underRunner = @(Get-CandidateSet -Target $clone -Pattern $runnerPattern)
    $underSuite = @(Get-CandidateSet -Target $clone -Pattern $suitePattern)
    ''
    "  candidate set under the RUNNER's pattern ($($underRunner.Count)):"
    foreach ($c in $underRunner) { "    $c" }
    "  candidate set under the SUITE's pattern ($($underSuite.Count)):"
    foreach ($c in $underSuite) { "    $c" }
    ''
    Assert-That -What 'the planted scratch/ manifest is NOT a runner candidate' `
        -Ok ($underRunner -notcontains 'scratch\Fake\Fake.psd1') `
        -Detail "$($underRunner.Count) candidates"
    Assert-That -What 'the planted output/ manifest is NOT a runner candidate' `
        -Ok ($underRunner -notcontains 'output\PSGraphRender\PSGraphRender.psd1') `
        -Detail "$($underRunner.Count) candidates"
    Assert-That -What 'the runner and the suite agree on the candidate set' `
        -Ok (@(Compare-Object $underRunner $underSuite).Count -eq 0) `
        -Detail "runner $($underRunner.Count), suite $($underSuite.Count)"
    ''

    # ---------------------------------------------------------------- RED A
    'A. REFUSAL DIRECTION - does the runner resolve the target unaided?'
    $resultA = Join-Path $work 'derive.json'
    $stdout = ''
    $threw = $false
    $message = ''
    try {
        $stdout = (& $runner -Path $clone -ResultPath $resultA 2>&1 | Out-String)
    }
    catch {
        $threw = $true
        $message = $_.Exception.Message
    }
    if (-not $threw -and $stdout -match 'Cannot derive -ModuleName') {
        # The refusal can surface as an error record in the merged stream
        # rather than as a terminating error here. Either way it is a refusal,
        # and reading only the catch block would report one as a green.
        $threw = $true
        $message = @($stdout -split "`r?`n" | Where-Object { $_ -match 'Cannot derive -ModuleName' })[0]
    }
    if ($threw) {
        '  REFUSED:'
        foreach ($line in ($message -split "`r?`n")) { "    $line" }
    }
    else {
        '  no refusal; the run completed'
        foreach ($line in @($stdout -split "`r?`n" | Where-Object { $_ -match '^(Derived|Settings:|Conformance:|cases-defined)' })) {
            "    $line"
        }
    }
    ''
    Assert-That -What 'the runner does not refuse to resolve the planted clone' -Ok (-not $threw) `
        -Detail $(if ($threw) { ($message -split "`r?`n")[0] } else { 'ran' })
    ''

    # -------------------------------------------------------- denominator
    'C. DENOMINATOR - CasesDefined, global and against the planted clone'
    $resultC = Join-Path $work 'denominator.json'
    & $runner -Path $clone -ModuleName 'PSGraphRender' -ResultPath $resultC *> $null
    $d = Get-Content -LiteralPath $resultC -Raw | ConvertFrom-Json
    $perTag = @($d.CasesDefinedPerTag.PSObject.Properties | ForEach-Object { '{0}={1}' -f $_.Name, $_.Value }) -join ', '
    "  PSGraphRender: CasesDefined = $($d.CasesDefined)  ($perTag)"
    "  PSGraphRender: CasesRun     = $($d.CasesRun)   Passed=$($d.Passed) Failed=$($d.Failed) ScorePct=$($d.ScorePct)"

    # CasesDefined is target-independent by construction - it is parsed from the
    # suite's own source and consults no file of the target. Measured against a
    # second target rather than assumed, because that property is exactly what
    # this pass must not break: a new test file inside the inventory scope would
    # move it, and it would move it for every target at once.
    $resultG = Join-Path $work 'global.json'
    & $runner -Path $RepoRoot -ModuleName 'PSGraphRender' -ResultPath $resultG *> $null
    $g = Get-Content -LiteralPath $resultG -Raw | ConvertFrom-Json
    "  harness itself: CasesDefined = $($g.CasesDefined)"
    Assert-That -What 'CasesDefined is the same figure whatever the target' `
        -Ok ($g.CasesDefined -eq $d.CasesDefined) `
        -Detail "harness $($g.CasesDefined), PSGraphRender $($d.CasesDefined)"
    ''
}
catch {
    # Without this the script prints its error and still exits 0, because a
    # terminating error skips the exit lines below. A green reported by a
    # script that crashed is the worst artifact this repository can produce.
    ''
    'ACCEPT 0046: ERROR - the script could not complete, so nothing below it ran.'
    "  $($_.Exception.Message)"
    "  at $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())"
    if (-not $Keep -and (Test-Path -LiteralPath $work)) {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit 99
}
finally {
    if (-not $Keep -and (Test-Path -LiteralPath $work)) {
        Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($failures.Count) {
    "ACCEPT 0046: RED - $($failures.Count) check(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'ACCEPT 0046: GREEN - every check agreed.'
exit 0
