#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0049 made, from the repositories, without reading
    the plan.

.DESCRIPTION
    Pass 0049 added a third rendering backend to PSGraphRender: `forcegraph3d`,
    a 3d-force-graph (three.js) template set that reads the same contract 1.1.0
    payload as the other two and draws it in three dimensions.

    The claim under test is not "a 3D view exists". It is that a template set is
    a rendering backend - that adding one is a directory, that it needed no
    change to `src/*.ps1`, no change to `contract/`, and no change to the two
    backends already there. `plain` has carried that claim since v0.2.0 and
    docs/constraints.md says outright it is *trivial enough to prove less than
    it looks*. This backend has a library, a canvas, a vendoring question and
    all three link modes, and the claim had to survive it.

    Seven checks and six falsification probes. Every answer is re-derived from
    fresh clones, never from plan.md, per PLAN-PROTOCOL section 9. Nothing is
    quoted: both conformance scores, both cases-run figures and CasesDefined are
    measured here, at both commits.

    -FailCheck additionally damages the head clone in six ways the pass claims
    it would catch, and reports a probe that does NOT fail as a failure. A check
    that cannot fail has checked nothing.

    Writes only under scratch/ and removes what it wrote.

.PARAMETER RepoRoot
    The harness repository. Defaults to two levels above this script.

.PARAMETER TargetRemote
    PSGraphRender's origin. Derived from the sibling checkout when not given.

.PARAMETER HeadRef
    What to verify. Defaults to 'main'. Before the fast-forward, pass the pass
    branch tip - see the refusal below.

.PARAMETER BaseRef
    What to verify against: PSGraphRender at pass 0048, which is this pass's
    base and also the commit tests/ForceGraph.Tests.ps1 compares the two
    untouched backends against.

.PARAMETER FailCheck
    Run the deliberate-failure probes against the verifier itself.

.PARAMETER SkipBrowser
    Omit the two checks that need the headless browser harness. They are the
    only ones that establish the page runs, so skipping them is reported in the
    summary rather than passing quietly.

.EXAMPLE
    ./plans/0049-forcegraph3d/verify.ps1 -HeadRef pass-0049-forcegraph3d
.EXAMPLE
    ./plans/0049-forcegraph3d/verify.ps1
.EXAMPLE
    ./plans/0049-forcegraph3d/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $HeadRef = 'main',
    [string] $BaseRef = '5501755',
    [switch] $FailCheck,
    [switch] $SkipBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Decision 0004: a plan and its verify script are frozen at the commit that pass
# pushed. Recorded, compared, and reported - never edited forward when the
# repository grows past it.
$WrittenAgainstTarget = '0d2c5df'
$WrittenAgainstHarness = 'pass-0049-forcegraph3d'

$SetName = 'forcegraph3d'

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

$work = Join-Path $RepoRoot 'scratch/verify-0049'
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

function Invoke-Build {
    param([string] $Clone)
    $log = & pwsh -NoProfile -NonInteractive -Command "& '$(Join-Path $Clone 'build.ps1')' -Task Build" 2>&1
    if (-not (Test-Path -LiteralPath (Join-Path $Clone 'output/PSGraphRender/PSGraphRender.psd1'))) {
        throw "build produced nothing in $Clone : $(($log | Select-Object -Last 5) -join ' / ')"
    }
}

# One clone, one render, through whichever backend and settings are asked for.
# Settings are written as DATA into a copy of the built set, the same way a
# caller sets any other setting - there is no test-only mechanism here, which is
# the point.
function Get-RenderOf {
    param(
        [string] $Clone,
        [string] $Backend,
        [string] $OutFile,
        [hashtable] $Setting = @{},
        [string] $Fixture = 'examples/input/ecosystem-viewmodel.json'
    )

    $set = Join-Path $Clone "output/PSGraphRender/TemplateSets/$Backend"
    if ($Setting.Count) {
        $copy = Join-Path $work ("set-" + [guid]::NewGuid().ToString('n').Substring(0, 8))
        Copy-Item -LiteralPath $set -Destination $copy -Recurse -Force
        $file = Join-Path $copy 'Config/settings.psd1'
        $text = [System.IO.File]::ReadAllText($file)
        foreach ($key in ($Setting.Keys | Sort-Object)) {
            $assignment = "    $key = '$($Setting[$key].Replace("'", "''"))'"
            # REPLACE a shipped key, append only a new one. A duplicate key is a
            # parse error rather than an override: the file fails to load, the
            # resolver warns and falls back to schema defaults, and every case
            # quietly renders the DEFAULT mode.
            if ($text -match "(?m)^\s*$key\s*=") {
                $text = $text -replace "(?m)^\s*$key\s*=.*$", $assignment.Replace('$', '$$')
            }
            else {
                $text = $text.Insert($text.LastIndexOf('}'), $assignment + "`n")
            }
        }
        [System.IO.File]::WriteAllText($file, $text)
        $set = $copy
    }

    $payload = Join-Path $Clone $Fixture
    if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }
    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module '$(Join-Path $Clone 'output/PSGraphRender/PSGraphRender.psd1')' -Force
`$vm = Get-Content -LiteralPath '$payload' -Raw | ConvertFrom-Json
`$doc = New-RenderDocument -ViewModel `$vm.data -Meta `$vm.meta -Title 'Verify 0049' -TemplateSetPath '$set'
[System.IO.File]::WriteAllText('$OutFile', `$doc)
"@ 2>&1
    if (-not (Test-Path -LiteralPath $OutFile)) { throw "render produced nothing: $(($log | Select-Object -Last 5) -join ' / ')" }
    [System.IO.File]::ReadAllText($OutFile)
}

# The document minus the STRINGS block. That block holds the renderer's own UI
# messages, and one of them may legitimately say `vscode://` in prose about what
# a blocked link looks like - which is not construction of one. The same
# carve-out tests/LinkMode.Tests.ps1 draws for the reference backend.
function Get-DocumentCode {
    param([string] $Document)
    $lines = @($Document -split "`r?`n")
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^const STRINGS = ') { $start = $i; break }
    }
    if ($start -lt 0) { return ($lines -join "`n") }
    for ($j = $start; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match '^\};?\s*$') { break }
    }
    $keep = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -lt $start -or $i -gt $j) { $keep += $lines[$i] }
    }
    $keep -join "`n"
}

# The 0043 grep. A drive path, a home directory, or a vscode:// URI carrying a
# real path, in anything the pass commits. Vendored files are exempt as
# third-party bytes this repository did not write and may not edit.
function Test-NoMachineIdentity {
    param([string[]] $Files)
    $hits = @()
    foreach ($f in $Files) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        if ([System.IO.Path]::GetExtension($f) -in '.png', '.jpg', '.gif', '.ico') { continue }
        if (@($f -split '[\\/]') -contains 'vendor') { continue }
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

# One test file, in the Pester 6 dialect the build sets. One row per It, so a
# check can name which assertion moved instead of reporting a total.
function Invoke-Suite {
    param([string] $Clone, [string] $File)
    $jsonPath = Join-Path $work 'suite.json'
    if (Test-Path -LiteralPath $jsonPath) { Remove-Item -LiteralPath $jsonPath -Force }
    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module Pester -RequiredVersion 6.1.0 -Force
`$cfg = New-PesterConfiguration
`$cfg.Run.Path = '$(Join-Path $Clone $File)'
`$cfg.Run.PassThru = `$true
`$cfg.Run.Throw = `$false
`$cfg.Should.DisableV5 = `$true
`$cfg.Output.Verbosity = 'None'
`$r = Invoke-Pester -Configuration `$cfg
@(`$r.Tests | ForEach-Object {
    [pscustomobject]@{ Name = `$_.ExpandedPath; Result = `$_.Result
        Message = if (`$_.ErrorRecord) { (`$_.ErrorRecord | ForEach-Object { `$_.ToString() }) -join ' ' } else { '' } }
}) | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath '$jsonPath'
"@ 2>&1
    if (-not (Test-Path -LiteralPath $jsonPath)) { throw "the suite produced no result: $(($log | Select-Object -Last 5) -join ' / ')" }
    @(Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json)
}

function Get-Row {
    param($Rows, [string] $Match)
    $r = @($Rows | Where-Object { $_.Name -like "*$Match*" })
    if ($r.Count -lt 1) { return $null }
    $r[0]
}

function Invoke-BuildTask {
    param([string] $Clone, [string] $Task)
    $out = & pwsh -NoProfile -NonInteractive -Command "& '$(Join-Path $Clone 'build.ps1')' -Task $Task" 2>&1
    [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Text = ($out | Out-String) }
}

# The browser harness is a node_modules tree, and .gitignore keeps it out of the
# repository - correctly, but it means a FRESH CLONE cannot run the two checks
# that establish the page runs. The build task fails by name rather than
# skipping, which is right, and here it would read as a defect in the pass
# rather than as a missing install.
#
# So it is copied in from the checkout beside this harness, and the copy is only
# taken when the clone's own Requirements.psd1 pins the version that checkout
# has. A harness at a different version would be measuring something other than
# what the pass shipped, and that is the failure this guard exists for.
function Copy-BrowserHarness {
    param([string] $Clone, [string] $From)

    $dest = Join-Path $Clone 'tests/browser/node_modules'
    if (Test-Path -LiteralPath $dest) { return 'already present in the clone' }

    $source = Join-Path $From 'tests/browser/node_modules'
    if (-not (Test-Path -LiteralPath $source)) {
        return "not installed in $From either - run ./build.ps1 -Task BootstrapBrowser there"
    }

    $pinned = (Import-PowerShellDataFile -LiteralPath (Join-Path $Clone 'Requirements.psd1')).Tools.Playwright.RequiredVersion
    $have = (Get-Content -LiteralPath (Join-Path $source 'playwright/package.json') -Raw | ConvertFrom-Json).version
    if ($have -ne $pinned) {
        return "the checkout has Playwright $have and the clone pins $pinned"
    }

    Copy-Item -LiteralPath $source -Destination $dest -Recurse -Force
    "copied Playwright $have from $From"
}

# A probe damages the head clone, re-runs one check, and asserts it goes RED.
# Restored from git afterwards, so the next probe starts from the landed tree.
function Restore-Head {
    param([string] $Clone)
    & git -C $Clone checkout --quiet -- . 2>&1 | Out-Null
    & git -C $Clone clean --quiet -fd -- src tests examples 2>&1 | Out-Null
    Invoke-Build -Clone $Clone
}

# ------------------------------------------------------------------ run
try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    ''
    'VERIFY 0049 - a third backend, re-derived from fresh clones.'
    "  target remote : $TargetRemote"
    "  head ref      : $HeadRef"
    "  base ref      : $BaseRef (pass 0048's tip)"
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
        "        below may be a later change rather than a defect in 0049."
    }
    ''

    Invoke-Build -Clone $head
    Invoke-Build -Clone $base

    # --------------------------------------------------------------- check 1
    ''
    '1. A backend is a directory: the set exists, is discovered, and cost no code.'

    $setDir = Join-Path $head "src/PSGraphRender/TemplateSets/$SetName"
    Assert-That -What "$SetName ships as a directory with a templateset.psd1" `
        -Ok (Test-Path -LiteralPath (Join-Path $setDir 'templateset.psd1'))

    $discovered = & pwsh -NoProfile -NonInteractive -Command @"
Import-Module '$(Join-Path $head 'output/PSGraphRender/PSGraphRender.psd1')' -Force
(Get-ChildItem -LiteralPath '$(Join-Path $head 'output/PSGraphRender/TemplateSets')' -Directory |
    Where-Object { Test-Path (Join-Path `$_.FullName 'templateset.psd1') } |
    Select-Object -ExpandProperty Name | Sort-Object) -join ','
"@ 2>&1
    $names = ($discovered | Select-Object -Last 1).ToString().Trim()
    Assert-That -What 'three backends ship, discovered rather than registered' `
        -Ok ($names -eq 'cytoscape,forcegraph3d,plain') -Detail $names

    # THE claim. Adding a backend must be a data change.
    $touchedPs1 = @(& git -C $head diff --name-only "$BaseRef..HEAD" -- 'src/PSGraphRender/*.ps1' 'src/PSGraphRender/**/*.ps1')
    Assert-That -What 'no .ps1 under src changed between base and head' `
        -Ok ($touchedPs1.Count -eq 0) -Detail ($touchedPs1 -join ', ')

    $touchedContract = @(& git -C $head diff --name-only "$BaseRef..HEAD" -- 'contract/')
    Assert-That -What 'the contract did not change' `
        -Ok ($touchedContract.Count -eq 0) -Detail ($touchedContract -join ', ')

    $touchedOthers = @(& git -C $head diff --name-only "$BaseRef..HEAD" -- `
            'src/PSGraphRender/TemplateSets/index.psd1' `
            'src/PSGraphRender/TemplateSets/cytoscape/' `
            'src/PSGraphRender/TemplateSets/plain/')
    Assert-That -What 'index.psd1, cytoscape/ and plain/ are untouched' `
        -Ok ($touchedOthers.Count -eq 0) -Detail ($touchedOthers -join ', ')

    $default = (Import-PowerShellDataFile -LiteralPath (
            Join-Path $head 'src/PSGraphRender/TemplateSets/index.psd1')).Default
    Assert-That -What 'cytoscape is still the default backend' -Ok ($default -eq 'cytoscape') -Detail $default

    # --------------------------------------------------------------- check 2
    ''
    '2. Acceptance A/B/C, run from the head clone.'
    $rows = Invoke-Suite -Clone $head -File 'tests/ForceGraph.Tests.ps1'
    $red = @($rows | Where-Object { $_.Result -ne 'Passed' })
    Assert-That -What 'every acceptance assertion passes at head' `
        -Ok ($red.Count -eq 0) -Detail "$($rows.Count) assertion(s), $($red.Count) red: $(@($red | ForEach-Object { $_.Name }) -join '; ')"

    foreach ($needed in 'renders cytoscape byte-identically to the base',
        'renders plain byte-identically to the base',
        'resolves every token cytoscape resolves',
        'edits no .ps1 under src to add a backend') {
        Assert-That -What "the suite actually contains '$needed'" `
            -Ok ($null -ne (Get-Row -Rows $rows -Match $needed))
    }

    # --------------------------------------------------------------- check 3
    ''
    '3. All three link modes, in the document the caller receives.'
    $editorDoc = Get-RenderOf -Clone $head -Backend $SetName -OutFile (Join-Path $work 'fg-editor.html') `
        -Setting @{ LinkMode = 'editor' }
    $hrefDoc = Get-RenderOf -Clone $head -Backend $SetName -OutFile (Join-Path $work 'fg-href.html') `
        -Setting @{ LinkMode = 'hrefTemplate'; LinkHrefTemplate = 'https://example.invalid/{relativePath}#L{line}' }
    $noneDoc = Get-RenderOf -Clone $head -Backend $SetName -OutFile (Join-Path $work 'fg-none.html') `
        -Setting @{ LinkMode = 'none' }

    $editorCode = Get-DocumentCode -Document $editorDoc
    $hrefCode = Get-DocumentCode -Document $hrefDoc
    $noneCode = Get-DocumentCode -Document $noneDoc

    Assert-That -What 'editor mode constructs the editor scheme' -Ok ($editorCode.Contains('vscode://file/'))
    Assert-That -What 'hrefTemplate mode does not' -Ok (-not $hrefCode.Contains('vscode://'))
    Assert-That -What 'none mode constructs no URI at all' `
        -Ok (-not $noneCode.Contains('vscode://') -and -not $noneCode.Contains('function nodeLinkUriFor'))

    # Token parity, derived from the OTHER backend's resolver rather than from a
    # list here. A list would be a second statement of one fact, and the two
    # would drift on the day a sixth token is added to one backend only.
    $cytoHref = [System.IO.File]::ReadAllText(
        (Join-Path $head 'src/PSGraphRender/TemplateSets/cytoscape/scripts/link/href.js'))
    $block = [regex]::Match($cytoHref, '(?s)var LINK_TOKENS = \{.*?\n    \};').Value
    $tokens = @([regex]::Matches($block, "'\{([a-zA-Z]+)\}'") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    Assert-That -What 'the reference resolver still declares five tokens to compare against' `
        -Ok ($tokens.Count -eq 5) -Detail ($tokens -join ', ')
    $missing = @($tokens | Where-Object { -not $hrefCode.Contains("'{$_}'") })
    Assert-That -What 'the 3D backend resolves every one of them' `
        -Ok ($missing.Count -eq 0) -Detail "missing: $($missing -join ', ')"

    # --------------------------------------------------------------- check 4
    ''
    '4. Vendoring: provenance, hash, and one file rather than two.'
    $vendorDir = Join-Path $setDir 'vendor'
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $vendorDir 'vendor.psd1')
    $onDisk = @(Get-ChildItem -LiteralPath $vendorDir -File | Where-Object { $_.Name -ne 'vendor.psd1' })
    Assert-That -What 'the 3D backend vendors exactly one file' -Ok ($onDisk.Count -eq 1) `
        -Detail (@($onDisk | ForEach-Object { $_.Name }) -join ', ')

    foreach ($entry in $manifest.Files) {
        $path = Join-Path $vendorDir $entry.Name
        $bytes = [System.IO.File]::ReadAllBytes($path)
        $computed = 'sha384-' + [Convert]::ToBase64String(
            [System.Security.Cryptography.SHA384]::Create().ComputeHash($bytes))
        Assert-That -What "$($entry.Name) matches its recorded integrity hash" `
            -Ok ($computed -eq $entry.Integrity) -Detail "$($entry.Version), $($entry.License)"
        Assert-That -What "$($entry.Name)'s URL pins the version the entry states" `
            -Ok ($entry.Url -like "*@$($entry.Version)/*") -Detail $entry.Url

        # The claim the manifest makes about three.js, checked against the bytes
        # rather than against the note. If this goes red the note is wrong, and a
        # note nobody can check is worth nothing.
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        Assert-That -What 'three.js really is inside that one file' `
            -Ok ($text.Contains('__THREE__') -and $text.Contains('WebGLRenderer')) `
            -Detail 'looked for the global three.js registers itself under, and its renderer'
        Assert-That -What 'and the bundle asks for nothing at load time' `
            -Ok (-not $text.Contains('sourceMappingURL')) -Detail 'no source map named and not shipped, unlike cytoscape-dagre'
    }

    # --------------------------------------------------------------- check 5
    ''
    '5. The examples regenerate, and the seven that existed do not move.'
    $rebuild = & pwsh -NoProfile -NonInteractive -File (Join-Path $head 'examples/Build-Examples.ps1') 2>&1
    $moved = @(& git -C $head diff --numstat -- examples/ | Where-Object { $_ -notmatch 'Build-Examples' })
    Assert-That -What 'a full example rebuild changes no committed example' `
        -Ok ($moved.Count -eq 0) -Detail "$(($moved -join '; ')) $(($rebuild | Select-Object -Last 1))"
    Assert-That -What 'the 3D example is committed with its picture' `
        -Ok ((Test-Path -LiteralPath (Join-Path $head 'examples/threed/forcegraph3d.html')) -and
            (Test-Path -LiteralPath (Join-Path $head 'examples/threed/forcegraph3d.png')))

    # --------------------------------------------------------------- check 6
    ''
    '6. Nothing committed names the machine that built it.'
    $committed = @(& git -C $head diff --name-only "$BaseRef..HEAD" | ForEach-Object { Join-Path $head $_ })
    # @() at the CALL SITE: an empty pipeline result collapses to $null under
    # StrictMode, and .Count on it throws - which reads as a broken verifier
    # rather than as a clean grep.
    $identity = @(Test-NoMachineIdentity -Files $committed)
    Assert-That -What 'no drive path, home directory or real-path vscode URI in anything this pass added' `
        -Ok ($identity.Count -eq 0) -Detail ($identity -join '; ')
    Assert-That -What 'and the grep read something, so its silence means something' `
        -Ok ($committed.Count -gt 10) -Detail "$($committed.Count) file(s) changed"

    # --------------------------------------------------------------- check 7
    ''
    '7. The page runs, and its links resolve, in a real browser with the network blocked.'
    if ($SkipBrowser) {
        '     SKIPPED by -SkipBrowser. These are the only two checks that'
        '     establish the page runs at all; the rest read text PowerShell made.'
        $script:failures.Add('checks 7a and 7b were skipped, so nothing here ran the page')
    }
    else {
        $lend = Copy-BrowserHarness -Clone $head -From (Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender')
        "     browser harness: $lend"

        $smoke = Invoke-BuildTask -Clone $head -Task TestBrowser
        Assert-That -What '7a. every backend and fixture came alive, nothing fetched' -Ok $smoke.Ok `
            -Detail (($smoke.Text -split "`r?`n" | Where-Object { $_ -match 'Browser:|ratio' } | Select-Object -Last 4) -join ' | ')

        $links = Invoke-BuildTask -Clone $head -Task TestLinkMode
        Assert-That -What '7b. every link mode resolved as configured, in both backends that have them' -Ok $links.Ok `
            -Detail (($links.Text -split "`r?`n" | Where-Object { $_ -match 'Link mode:' } | Select-Object -Last 1))
    }

    # --------------------------------------------------------------- check 8
    ''
    '8. Conformance at head is not below base. Both ends measured here, not quoted.'
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
        -Detail ($newFailures -join '; ')

    # ------------------------------------------------------------- probes
    if ($FailCheck) {
        ''
        'FALSIFICATION - each damages the head clone and asserts the check goes RED.'
        ''

        # P1. A token silently stops resolving in one backend and not the other.
        # This is the defect the parity assertion exists for, and the reason it
        # is derived from cytoscape's own table rather than from a list.
        $hrefJs = Join-Path $head "src/PSGraphRender/TemplateSets/$SetName/scripts/link/href.js"
        $pristine = [System.IO.File]::ReadAllText($hrefJs)
        [System.IO.File]::WriteAllText($hrefJs,
            $pristine.Replace("        '{id}': function (node) { return encodeURIComponent(node.id || ''); },`n", ''))
        Invoke-Build -Clone $head
        $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'resolves every token cytoscape resolves'
        Assert-That -What 'P1: a dropped token turns token parity RED' -Ok ($null -ne $row -and $row.Result -eq 'Failed') `
            -Detail $(if ($row) { $row.Message } else { 'the assertion is not in the suite' })
        Assert-That -What 'P1: and nothing else in the suite moves' `
            -Ok (@($r | Where-Object { $_.Result -ne 'Passed' }).Count -eq 1) `
            -Detail "$(@($r | Where-Object { $_.Result -ne 'Passed' }).Count) red"
        Restore-Head -Clone $head

        # P2. `none` mode assembles the editor files after all. The whole 0047
        # ruling is that absence has to be absence from the ARTIFACT.
        $mf = Join-Path $head "src/PSGraphRender/TemplateSets/$SetName/templateset.psd1"
        $pristineMf = [System.IO.File]::ReadAllText($mf)
        [System.IO.File]::WriteAllText($mf, $pristineMf.Replace(
                "                SCRIPT_NODE_LINK  = @('scripts/link/none.js')",
                "                SCRIPT_NODE_LINK  = @('scripts/link/common.js', 'scripts/link/editor.js')"))
        Invoke-Build -Clone $head
        $doc = Get-RenderOf -Clone $head -Backend $SetName -OutFile (Join-Path $work 'p2.html') -Setting @{ LinkMode = 'none' }
        Assert-That -What 'P2: none mode leaking the editor scheme is visible in the document' `
            -Ok ((Get-DocumentCode -Document $doc).Contains('vscode://'))
        $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph.Tests.ps1'
        Assert-That -What 'P2: and turns the none-mode assertions RED' `
            -Ok (@($r | Where-Object { $_.Result -ne 'Passed' -and $_.Name -like '*none*' }).Count -gt 0)
        Restore-Head -Clone $head

        # P3. One line added to the reference backend. The no-regression control
        # has to see a change to a backend this pass is not supposed to touch.
        $cytoBoot = Join-Path $head 'src/PSGraphRender/TemplateSets/cytoscape/scripts/bootstrap.js'
        [System.IO.File]::WriteAllText($cytoBoot, [System.IO.File]::ReadAllText($cytoBoot) + "`n// PROBE MARKER`n")
        Invoke-Build -Clone $head
        $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'renders cytoscape byte-identically to the base'
        Assert-That -What 'P3: a line added to cytoscape turns the no-regression control RED' `
            -Ok ($null -ne $row -and $row.Result -eq 'Failed') `
            -Detail $(if ($row) { $row.Message } else { 'the assertion is not in the suite' })
        Restore-Head -Clone $head

        # P4. The library is no longer in the document. The page must say so
        # rather than going blank, and the gate must not report it alive.
        [System.IO.File]::WriteAllText($mf, [System.IO.File]::ReadAllText($mf).Replace(
                "        VENDOR = @('vendor/3d-force-graph.min.js')", '        VENDOR = @()'))
        Invoke-Build -Clone $head
        if (-not $SkipBrowser) {
            $t = Invoke-BuildTask -Clone $head -Task TestBrowser
            Assert-That -What 'P4: an empty VENDOR slot turns the browser gate RED' -Ok (-not $t.Ok) `
                -Detail (($t.Text -split "`r?`n" | Where-Object { $_ -match 'ready state' } | Select-Object -First 1))
        }
        else { '  [skip] P4 needs the browser harness' }
        Restore-Head -Clone $head

        # P5. THE probe for the canvas-growth floor. The page runs, the counts
        # are right, every DOM assertion passes - and nothing is drawn. No other
        # check in this repository can tell that from a working page.
        $graphJs = Join-Path $head "src/PSGraphRender/TemplateSets/$SetName/scripts/graph.js"
        [System.IO.File]::WriteAllText($graphJs, [System.IO.File]::ReadAllText($graphJs).Replace(
                '            .graphData({ nodes: withInventedTargets(nodes, links), links: links.slice() });',
                '            .graphData({ nodes: [], links: [] });'))
        Invoke-Build -Clone $head
        if (-not $SkipBrowser) {
            $t = Invoke-BuildTask -Clone $head -Task TestBrowser
            Assert-That -What 'P5: a page that runs and draws nothing turns the growth floor RED' -Ok (-not $t.Ok) `
                -Detail (($t.Text -split "`r?`n" | Where-Object { $_ -match 'The view is blank' } | Select-Object -First 1))
        }
        else { '  [skip] P5 needs the browser harness' }
        Restore-Head -Clone $head

        # P6. Token values handed over unencoded. SC3: a producer's label is one
        # step from changing the shape of a URL.
        $unsafe = [System.IO.File]::ReadAllText($hrefJs)
        $unsafe = $unsafe.Replace("'{label}': function (node) { return encodeURIComponent(node.name || ''); },",
            "'{label}': function (node) { return String(node.name || ''); },")
        $unsafe = $unsafe.Replace("'{relativePath}': function (node) { return encodePathSegments(urlPathFor(node)); },",
            "'{relativePath}': function (node) { return urlPathFor(node); },")
        [System.IO.File]::WriteAllText($hrefJs, $unsafe)
        Invoke-Build -Clone $head
        if (-not $SkipBrowser) {
            $t = Invoke-BuildTask -Clone $head -Task TestLinkMode
            Assert-That -What 'P6: unencoded token values turn the injection case RED' -Ok (-not $t.Ok) `
                -Detail (($t.Text -split "`r?`n" | Where-Object { $_ -match 'unencoded character' } | Select-Object -First 1))
        }
        else { '  [skip] P6 needs the browser harness' }
        Restore-Head -Clone $head
    }

    # ------------------------------------------------------------- summary
    ''
    if ($failures.Count -eq 0) {
        'VERIFY 0049: every check passed.'
    }
    else {
        "VERIFY 0049: $($failures.Count) failure(s)."
        foreach ($f in $failures) { "  - $f" }
    }
    ''
    exit $(if ($failures.Count -eq 0) { 0 } else { 1 })
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
