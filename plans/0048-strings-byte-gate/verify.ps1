#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0048 made, from the repositories, without reading
    the plan.

.DESCRIPTION
    Pass 0048 closed LEDGER backlog 64. `tests/LinkMode.Tests.ps1` carries the
    strongest gate PSGraphRender has - an editor-mode document must be
    byte-identical to the base's for the same payload - and `Get-DocumentCode`
    removed the whole STRINGS block before that comparison, because acceptance
    B's carve-out for vscode:// prose is exactly that block and one helper
    serves both. Every user-visible string in the renderer was invisible to it.

    STRINGS is now compared the way CONFIG already was: an existing key may not
    change value, only the three named additions are permitted, and those three
    are pinned by value as well as by name.

    Six checks and five falsification probes. Every answer is re-derived from a
    fresh clone, never from plan.md, per PLAN-PROTOCOL section 9. Nothing is
    quoted: both conformance scores, both cases-run figures and CasesDefined
    are measured here, at both commits.

    -FailCheck additionally damages the head clone in two ways the pass claims
    it would catch, and reports a probe that does NOT fail as a failure. A check
    that cannot fail has checked nothing.

    Writes only under scratch/ and removes what it wrote.

.PARAMETER RepoRoot
    The harness repository. Defaults to two levels above this script.

.PARAMETER TargetRemote
    PSGraphRender's origin. Derived from the sibling checkout when not given.

.PARAMETER HeadRef
    What to verify. Defaults to 'main'. Before the fast-forward, pass the pass
    branch tip - see the note on the refusal below.

.PARAMETER BaseRef
    What to verify against: PSGraphRender at pass 0047, which is this pass's
    base. NOT acceptance C's own base - that is cd4857d and it stays there,
    inside the suite, for the reason recorded in the pass's constraints.

.PARAMETER FailCheck
    Run the deliberate-failure probes against the verifier itself.

.EXAMPLE
    ./plans/0048-strings-byte-gate/verify.ps1 -HeadRef pass-0048-strings-byte-gate
.EXAMPLE
    ./plans/0048-strings-byte-gate/verify.ps1
.EXAMPLE
    ./plans/0048-strings-byte-gate/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $HeadRef = 'main',
    [string] $BaseRef = '3f2ec85',
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Decision 0004: a plan and its verify script are frozen at the commit that pass
# pushed. Recorded, compared, and reported - never edited forward when the
# repository grows past it.
$WrittenAgainstTarget = '5501755'
$WrittenAgainstHarness = 'pass-0048-strings-byte-gate'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

if (-not $TargetRemote) {
    $sibling = Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender'
    if (Test-Path -LiteralPath (Join-Path $sibling '.git')) {
        $TargetRemote = (& git -C $sibling remote get-url origin).Trim()
    }
    else {
        $TargetRemote = 'https://github.com/JerryBalmer1/PSGraphRender.git'
    }
}

$work = Join-Path $RepoRoot 'scratch/verify-0048'
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

# ------------------------------------------------------------------ helpers
#
# Written as functions over an input so the same code answers for the real
# artifact and for a deliberately damaged copy. A probe running different code
# from the check it probes proves nothing about the check.

$STRINGS_IT = 'changes STRINGS only by adding the three link strings, and moves no shipped value'
$CONFIG_IT = 'changes CONFIG only by adding the two link settings, and defaults the mode to editor'
$BODY_ITS = @(
    'renders identically to the base with linkMode absent entirely'
    'renders identically to the base with linkMode set explicitly to editor'
)

function Get-BlockText {
    param([string] $Document, [string] $Name)
    $lines = @($Document -split "`r?`n")
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^const $Name = ") { $start = $i; break }
    }
    if ($start -lt 0) { throw "No $Name assignment in the document." }
    for ($j = $start; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match '^\};?\s*$') { return ($lines[$start..$j] -join "`n") }
    }
    throw "The $Name block is never closed."
}

# The 0043 grep. A drive path, a home directory, a username, or a vscode:// URI
# carrying a real path, in anything the pass commits.
function Test-NoMachineIdentity {
    param([string[]] $Files)
    $hits = @()
    foreach ($f in $Files) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        if ([System.IO.Path]::GetExtension($f) -in '.png', '.jpg', '.gif', '.ico') { continue }
        $text = [System.IO.File]::ReadAllText($f)
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -match '(^|[^A-Za-z0-9/])[A-Za-z]:[\\/]{1,2}[A-Za-z_.]' -and
                $line -notmatch 'fixtures[\\/]LinkMode|psgraphrender-|\$env:|TEMP|GetTempPath') {
                $hits += "$([System.IO.Path]::GetFileName($f)): drive path"
            }
            if ($line -match '/(Users|home)/[A-Za-z]') { $hits += "$([System.IO.Path]::GetFileName($f)): home dir" }
            if ($line -match 'vscode://file/[A-Za-z]:') { $hits += "$([System.IO.Path]::GetFileName($f)): vscode uri with a real path" }
        }
    }
    @($hits | Sort-Object -Unique)
}

# One clone, one render, with whatever state its built template set is in.
function Get-RenderOf {
    param([string] $Clone, [string] $OutFile)
    $set = Join-Path $Clone 'output/PSGraphRender/TemplateSets/cytoscape'
    $fixture = Join-Path $Clone 'tests/fixtures/viewmodels/sample-module.json'
    if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }
    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module '$(Join-Path $Clone 'output/PSGraphRender/PSGraphRender.psd1')' -Force
`$vm = Get-Content -LiteralPath '$fixture' -Raw | ConvertFrom-Json
`$doc = New-RenderDocument -ViewModel `$vm.data -Meta `$vm.meta -Title 'Link mode fixture' -TemplateSetPath '$set'
[System.IO.File]::WriteAllText('$OutFile', `$doc)
"@ 2>&1
    if (-not (Test-Path -LiteralPath $OutFile)) { throw "render produced nothing: $($log -join ' / ')" }
    [System.IO.File]::ReadAllText($OutFile)
}

# The link-mode suite only, in the Pester 6 dialect the build sets. One row per
# It, so a check can name which assertion moved instead of reporting a total.
function Invoke-LinkModeSuite {
    param([string] $Clone)
    $jsonPath = Join-Path $work 'suite.json'
    if (Test-Path -LiteralPath $jsonPath) { Remove-Item -LiteralPath $jsonPath -Force }
    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module Pester -RequiredVersion 6.1.0 -Force
`$cfg = New-PesterConfiguration
`$cfg.Run.Path = '$(Join-Path $Clone 'tests/LinkMode.Tests.ps1')'
`$cfg.Run.PassThru = `$true
`$cfg.Run.Throw = `$false
`$cfg.Should.DisableV5 = `$true
`$cfg.Output.Verbosity = 'None'
`$r = Invoke-Pester -Configuration `$cfg
@(`$r.Tests | ForEach-Object {
    [pscustomobject]@{ Name = `$_.Name; Result = `$_.Result
        Message = if (`$_.ErrorRecord) { (`$_.ErrorRecord | ForEach-Object { `$_.ToString() }) -join ' ' } else { '' } }
}) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath '$jsonPath'
"@ 2>&1
    if (-not (Test-Path -LiteralPath $jsonPath)) { throw "the suite produced no result: $(($log | Select-Object -Last 5) -join ' / ')" }
    @(Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json)
}

function Get-Row {
    param($Rows, [string] $Name)
    $r = @($Rows | Where-Object { $_.Name -eq $Name })
    if ($r.Count -ne 1) { return $null }
    $r[0]
}

# ------------------------------------------------------------------ run
try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    ''
    'VERIFY 0048 - STRINGS joins the byte gate, re-derived from fresh clones.'
    "  target remote : $TargetRemote"
    "  head ref      : $HeadRef"
    "  base ref      : $BaseRef (pass 0047's tip - NOT acceptance C's cd4857d)"
    ''

    $head = Join-Path $work 'head'
    $base = Join-Path $work 'base'
    & git clone --quiet $TargetRemote $head 2>&1 | Out-Null
    & git clone --quiet $TargetRemote $base 2>&1 | Out-Null
    & git -C $head checkout --quiet $HeadRef 2>&1 | Out-Null
    & git -C $base checkout --quiet $BaseRef 2>&1 | Out-Null

    # A head that is already the base verifies nothing and would report every
    # check green for it. The most likely cause is running against main before
    # the fast-forward; see -HeadRef.
    if ((& git -C $head rev-parse HEAD).Trim() -eq (& git -C $base rev-parse HEAD).Trim()) {
        throw "head ($HeadRef) and base ($BaseRef) are the same commit - there is nothing to verify."
    }

    $headSha = (& git -C $head rev-parse --short HEAD).Trim()
    $baseSha = (& git -C $base rev-parse --short HEAD).Trim()
    "  head = $headSha, base = $baseSha"
    if ($headSha -notlike "$WrittenAgainstTarget*") {
        "  NOTE: written against target $WrittenAgainstTarget on harness branch"
        "        $WrittenAgainstHarness. Head is $headSha, so any disagreement"
        '        below may be the repository having moved on rather than the'
        '        pass having been wrong (decision 0004).'
    }
    ''

    foreach ($tree in @($head, $base)) {
        & pwsh -NoProfile -NonInteractive -Command "& '$(Join-Path $tree 'build.ps1')' -Task Build" 2>&1 | Out-Null
    }

    # --------------------------------------------------------------- check 1
    '1. The gate exists at head, is green, and did not exist at base.'
    $headRows = Invoke-LinkModeSuite -Clone $head
    $gate = Get-Row -Rows $headRows -Name $STRINGS_IT
    Assert-That -What 'the STRINGS gate exists at head' -Ok ($null -ne $gate) `
        -Detail $(if ($gate) { "one It named for it" } else { 'absent' })
    if ($gate) {
        Assert-That -What 'the STRINGS gate is green at head' -Ok ($gate.Result -eq 'Passed') -Detail $gate.Result
    }

    $baseRows = Invoke-LinkModeSuite -Clone $base
    Assert-That -What 'the STRINGS gate did NOT exist at base' -Ok ($null -eq (Get-Row -Rows $baseRows -Name $STRINGS_IT)) `
        -Detail 'otherwise the pass added nothing and every green below is about the base'

    # --------------------------------------------------------------- check 2
    ''
    '2. Acceptances A, B and C are green at head - the pass broke nothing.'
    $describes = @($headRows | ForEach-Object { $_.Name })
    foreach ($n in (@($CONFIG_IT) + $BODY_ITS)) {
        $r = Get-Row -Rows $headRows -Name $n
        Assert-That -What "green: '$($n.Substring(0, [Math]::Min(52, $n.Length)))'" `
            -Ok ($null -ne $r -and $r.Result -eq 'Passed') -Detail $(if ($r) { $r.Result } else { 'absent' })
    }
    $red = @($headRows | Where-Object { $_.Result -eq 'Failed' })
    Assert-That -What 'nothing in the link-mode suite is red at head' -Ok ($red.Count -eq 0) `
        -Detail "$($headRows.Count) case(s), $($red.Count) red"

    # --------------------------------------------------------------- check 3
    ''
    '3. The gate asserts the three additions BY NAME and BY VALUE.'
    $testText = [System.IO.File]::ReadAllText((Join-Path $head 'tests/LinkMode.Tests.ps1'))
    foreach ($key in @('MenuCopyLink', 'MenuOpenLink', 'ReasonNoTemplate')) {
        Assert-That -What "the additions list names $key" -Ok ($testText -match "'$key'")
    }
    Assert-That -What 'acceptance C''s base SHA is still cd4857d' -Ok ($testText -match "BaseSha = 'cd4857d'") `
        -Detail 're-baselining would empty the additions list and make the gate vacuous on the day it ships'
    Assert-That -What 'Get-DocumentCode still carves out the STRINGS block' `
        -Ok ($testText -match "Get-DocumentBlockRange -Lines \`$lines -Name 'STRINGS'") `
        -Detail 'widening it would turn acceptance B red against correct work'

    # --------------------------------------------------------------- check 4
    ''
    '4. Falsification. Each probe mutates the head clone''s BUILT template set,'
    '   proves the mutation reached the rendered document, and re-runs the suite.'
    $builtSet = Join-Path $head 'output/PSGraphRender/TemplateSets/cytoscape'
    $stringsFile = Join-Path $builtSet 'Config/strings.psd1'
    $themeFile = Join-Path $builtSet 'Config/theme.psd1'
    $scriptFile = Join-Path $builtSet 'scripts/sidebar.js'
    $pristine = @{
        $stringsFile = [System.IO.File]::ReadAllText($stringsFile)
        $themeFile   = [System.IO.File]::ReadAllText($themeFile)
        $scriptFile  = [System.IO.File]::ReadAllText($scriptFile)
    }
    function Restore-Head { foreach ($f in $pristine.Keys) { [System.IO.File]::WriteAllText($f, $pristine[$f]) } }

    $pristineDoc = Get-RenderOf -Clone $head -OutFile (Join-Path $work 'pristine.html')
    $pristineStringsBlock = Get-BlockText -Document $pristineDoc -Name 'STRINGS'

    function Invoke-Probe {
        param([string] $Id, [scriptblock] $Mutate, [string] $Landed, [scriptblock] $Test, [scriptblock] $Expect)
        Restore-Head
        & $Mutate
        $doc = Get-RenderOf -Clone $head -OutFile (Join-Path $work "$Id.html")
        # A substitution that matched nothing leaves the target intact and
        # produces a green run that proves nothing.
        $didLand = [bool] (& $Test $doc)
        Assert-That -What "$Id`: the mutation reached the rendered document" -Ok $didLand -Detail $Landed
        if ($didLand) { & $Expect (Invoke-LinkModeSuite -Clone $head) }
        Restore-Head
    }

    Invoke-Probe -Id 'P1' -Landed 'MenuOpenLink changed value' `
        -Mutate { [System.IO.File]::WriteAllText($stringsFile,
            ([System.IO.File]::ReadAllText($stringsFile) -replace "(?m)^(\s*MenuOpenLink\s*=\s*)'Open Link'", "`$1'MUTATED'")) } `
        -Test { param($d) (Get-BlockText -Document $d -Name 'STRINGS').Contains('MUTATED') } `
        -Expect {
            param($rows)
            $r = Get-Row -Rows $rows -Name $STRINGS_IT
            Assert-That -What 'P1: a changed value goes RED' -Ok ($r.Result -eq 'Failed') -Detail $r.Result
            Assert-That -What 'P1: the message names the key and both values' `
                -Ok ($r.Message -match 'MenuOpenLink' -and $r.Message -match 'Open Link' -and $r.Message -match 'MUTATED')
        }

    Invoke-Probe -Id 'P2' -Landed 'an unexpected key is present' `
        -Mutate { $t = [System.IO.File]::ReadAllText($stringsFile)
            [System.IO.File]::WriteAllText($stringsFile, $t.Insert($t.LastIndexOf('}'), "    ProbeAddedKey = 'x'`n")) } `
        -Test { param($d) (Get-BlockText -Document $d -Name 'STRINGS').Contains('ProbeAddedKey') } `
        -Expect {
            param($rows)
            $r = Get-Row -Rows $rows -Name $STRINGS_IT
            Assert-That -What 'P2: an added key goes RED' -Ok ($r.Result -eq 'Failed') -Detail $r.Result
            Assert-That -What 'P2: the message names the unexpected key' -Ok ($r.Message -match 'ProbeAddedKey')
        }

    Invoke-Probe -Id 'P3' -Landed 'a shipped key is gone' `
        -Mutate { [System.IO.File]::WriteAllText($stringsFile,
            ([System.IO.File]::ReadAllText($stringsFile) -replace "(?m)^\s*MenuCopyPath\s*=.*\r?\n", '')) } `
        -Test { param($d) -not (Get-BlockText -Document $d -Name 'STRINGS').Contains('MenuCopyPath') } `
        -Expect {
            param($rows)
            $r = Get-Row -Rows $rows -Name $STRINGS_IT
            Assert-That -What 'P3: a removed key goes RED' -Ok ($r.Result -eq 'Failed') -Detail $r.Result
            # WHICH clause catches it: a removed key reads null at head against a
            # string at base, so it is the value loop, not the additions list.
            Assert-That -What 'P3: caught by the value clause, naming the key' `
                -Ok ($r.Message -match 'MenuCopyPath' -and $r.Message -match 'null')
        }

    # P4a and P4b are the scope control, and they are the load-bearing probes.
    # Every theme value the page uses is emitted INTO the CONFIG block, which
    # the byte comparison strips - so a theme edit turns CONFIG red and leaves
    # the body green. A script line is what actually lands in the compared body.
    # Together they prove the three checks divide the document between them
    # rather than being one check written three times.
    Invoke-Probe -Id 'P4a' -Landed 'the change is in CONFIG, and STRINGS is untouched' `
        -Mutate { [System.IO.File]::WriteAllText($themeFile,
            ([System.IO.File]::ReadAllText($themeFile) -replace "(?m)^(\s*\w+\s*=\s*)'#([0-9a-fA-F]{6})'", "`$1'#ABCDEF'")) } `
        -Test { param($d)
            (Get-BlockText -Document $d -Name 'CONFIG').Contains('#ABCDEF') -and
            ((Get-BlockText -Document $d -Name 'STRINGS') -ceq $pristineStringsBlock) } `
        -Expect {
            param($rows)
            Assert-That -What 'P4a: a theme value leaves the STRINGS gate GREEN' `
                -Ok ((Get-Row -Rows $rows -Name $STRINGS_IT).Result -eq 'Passed')
            Assert-That -What 'P4a: and turns the CONFIG comparison RED' `
                -Ok ((Get-Row -Rows $rows -Name $CONFIG_IT).Result -eq 'Failed')
            foreach ($n in $BODY_ITS) {
                Assert-That -What 'P4a: the body comparison stays GREEN (theme lives in CONFIG)' `
                    -Ok ((Get-Row -Rows $rows -Name $n).Result -eq 'Passed')
            }
        }

    Invoke-Probe -Id 'P4b' -Landed 'the marker is in the body, outside CONFIG and STRINGS' `
        -Mutate { [System.IO.File]::WriteAllText($scriptFile,
            ([System.IO.File]::ReadAllText($scriptFile) + "`n// PROBE MARKER`n")) } `
        -Test { param($d)
            $d.Contains('PROBE MARKER') -and
            -not (Get-BlockText -Document $d -Name 'CONFIG').Contains('PROBE MARKER') -and
            ((Get-BlockText -Document $d -Name 'STRINGS') -ceq $pristineStringsBlock) } `
        -Expect {
            param($rows)
            Assert-That -What 'P4b: a body change leaves the STRINGS gate GREEN' `
                -Ok ((Get-Row -Rows $rows -Name $STRINGS_IT).Result -eq 'Passed')
            foreach ($n in $BODY_ITS) {
                Assert-That -What 'P4b: and turns the body comparison RED' `
                    -Ok ((Get-Row -Rows $rows -Name $n).Result -eq 'Failed')
            }
        }
    Restore-Head

    # --------------------------------------------------------------- check 5
    ''
    '5. Conformance at head is not below base. Both ends measured here, not quoted.'
    $runner = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'
    $scores = @{}
    foreach ($pair in @(@{ N = 'base'; P = $base }, @{ N = 'head'; P = $head })) {
        $out = Join-Path $work "conformance-$($pair.N).json"
        # -Command, not -File: with -File every argument arrives as one string,
        # so the tag ARRAY becomes one comma-joined value and the runner's own
        # ValidateSet rejects it against a set it is a comma-join of.
        $runLog = & pwsh -NoProfile -NonInteractive -Command `
            "& '$runner' -Path '$($pair.P)' -Tag Universal,Repository,HouseStyle,RequiresBuild -ModuleName 'PSGraphRender' -ResultPath '$out'" 2>&1
        if (-not (Test-Path -LiteralPath $out)) {
            throw "the conformance runner produced no result for $($pair.N): $(($runLog | Select-Object -Last 3) -join ' / ')"
        }
        $scores[$pair.N] = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    }
    "     base: $($scores['base'].ScorePct)% over $($scores['base'].CasesRun) case(s), CasesDefined $($scores['base'].CasesDefined)"
    "     head: $($scores['head'].ScorePct)% over $($scores['head'].CasesRun) case(s), CasesDefined $($scores['head'].CasesDefined)"

    Assert-That -What 'head conformance is not below base' `
        -Ok ($scores['head'].ScorePct -ge $scores['base'].ScorePct) `
        -Detail "$($scores['base'].ScorePct) -> $($scores['head'].ScorePct)"
    Assert-That -What 'cases-run did not move' -Ok ($scores['head'].CasesRun -eq $scores['base'].CasesRun) `
        -Detail "$($scores['base'].CasesRun) -> $($scores['head'].CasesRun)"
    Assert-That -What 'CasesDefined did not move' -Ok ($scores['head'].CasesDefined -eq $scores['base'].CasesDefined) `
        -Detail "$($scores['base'].CasesDefined) -> $($scores['head'].CasesDefined) (the denominator; backlog 63 is about the PIN, not this figure)"

    $newFailures = @($scores['head'].Failures | ForEach-Object { $_.Name } |
            Where-Object { $_ -notin @($scores['base'].Failures | ForEach-Object { $_.Name }) })
    Assert-That -What 'no assertion that passed at base fails at head' -Ok ($newFailures.Count -eq 0) `
        -Detail $(if ($newFailures) { $newFailures -join '; ' } else { 'none' })

    # --------------------------------------------------------------- check 6
    ''
    '6. Nothing machine-identifying, and no tag was taken.'
    $passFiles = @(& git -C $head diff --name-only "$BaseRef...HEAD") |
        Where-Object { $_ } | ForEach-Object { Join-Path $head $_ }
    # The detector is exempt from itself by exact leaf name: a check for drive
    # paths and vscode:// URIs necessarily contains both.
    $scanned = @($passFiles | Where-Object { (Split-Path $_ -Leaf) -notin @('verify.ps1', 'spotchecks.ps1') })
    $hits = @(Test-NoMachineIdentity -Files $scanned)
    Assert-That -What 'no machine identity in what the pass changed in the target' -Ok ($hits.Count -eq 0) `
        -Detail $(if ($hits.Count) { $hits -join '; ' } else { "clean over $($scanned.Count) file(s)" })

    $tagsOnHead = @(& git -C $head tag --points-at HEAD | Where-Object { $_ })
    Assert-That -What 'no tag was taken by this pass' -Ok ($tagsOnHead.Count -eq 0) `
        -Detail $(if ($tagsOnHead.Count) { $tagsOnHead -join ', ' } else { 'none' })

    $manifestVersion = (Import-PowerShellDataFile -LiteralPath (Join-Path $head 'src/PSGraphRender/PSGraphRender.psd1')).ModuleVersion
    $baseVersion = (Import-PowerShellDataFile -LiteralPath (Join-Path $base 'src/PSGraphRender/PSGraphRender.psd1')).ModuleVersion
    Assert-That -What 'no version bump' -Ok ($manifestVersion -eq $baseVersion) -Detail "$baseVersion -> $manifestVersion"

    $srcMoved = @(& git -C $head diff --name-only "$BaseRef...HEAD" -- src/ | Where-Object { $_ })
    Assert-That -What 'no src/ change' -Ok ($srcMoved.Count -eq 0) `
        -Detail $(if ($srcMoved.Count) { $srcMoved -join ', ' } else { 'tests and CHANGELOG only' })

    # ------------------------------------------------------------ FailCheck
    if ($FailCheck) {
        ''
        'FALSIFICATION OF THE VERIFIER - each probe must make a check above go red.'
        $testFile = Join-Path $head 'tests/LinkMode.Tests.ps1'
        $pristineTest = [System.IO.File]::ReadAllText($testFile)
        try {
            # F1 - the gate deleted. Check 1 must notice it is gone.
            $withoutGate = $pristineTest -replace "(?ms)\r?\n    It 'changes STRINGS only by adding.*?\r?\n    \}\r?\n", "`n"
            if ($withoutGate -ceq $pristineTest) { throw 'F1: the gate It was not found to delete.' }
            [System.IO.File]::WriteAllText($testFile, $withoutGate)
            $rows = Invoke-LinkModeSuite -Clone $head
            Assert-That -What 'F1: a deleted gate is detected as absent' -Ok ($null -eq (Get-Row -Rows $rows -Name $STRINGS_IT)) `
                -Detail 'check 1 asks whether the It exists, not only whether it is green'

            # F2 - the additions list emptied. It must go red rather than pass
            # on nothing: zero cases is not a pass, for an expectation either.
            [System.IO.File]::WriteAllText($testFile, $pristineTest.Replace(
                    "Should-BeCollection @('MenuCopyLink', 'MenuOpenLink', 'ReasonNoTemplate')",
                    'Should-BeCollection @()'))
            $rows = Invoke-LinkModeSuite -Clone $head
            $r = Get-Row -Rows $rows -Name $STRINGS_IT
            Assert-That -What 'F2: an emptied additions list goes RED' -Ok ($null -ne $r -and $r.Result -eq 'Failed') `
                -Detail $(if ($r) { $r.Result } else { 'absent' })
        }
        finally {
            [System.IO.File]::WriteAllText($testFile, $pristineTest)
        }
        ''
    }
}
catch {
    # Without this the script prints its error and still exits 0, because a
    # terminating error skips the exit lines below. A verify script reporting
    # success while crashing is a false green in the one artifact whose job is
    # to disprove the plan; pass 0044's verifier did exactly that.
    ''
    'VERIFY 0048: ERROR - the script could not complete, so nothing below it ran.'
    "  $($_.Exception.Message)"
    "  at $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())"
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    exit 99
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

''
if ($failures.Count) {
    "VERIFY 0048: FAIL - $($failures.Count) check(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'VERIFY 0048: PASS - every check re-derived and agreed.'
exit 0
