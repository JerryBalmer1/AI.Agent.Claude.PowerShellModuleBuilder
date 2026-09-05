#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0050 made, from the repositories, without reading
    the plan.

.DESCRIPTION
    Pass 0050 moved the link probe out of PSGraphRender's build task and into
    each backend's own `templateset.psd1`, as a `LinkProbe` block beside `Smoke`.

    The claim under test is not "a manifest gained a key". It is that a backend's
    shape is written down in exactly ONE place - the backend - which is the rule
    `tests/browser/smoke.cjs` states about itself and which the link probe was
    breaking in two places at once: a `$LINK_PROBE` map in
    `PSGraphRender.build.ps1`, and a `DEFAULTS` object in
    `tests/browser/link-mode.cjs` holding cytoscape's selectors as fallbacks for
    every backend. Both are gone, and the probe must still probe identically.

    Seven checks and five falsification probes. Every answer is re-derived from
    fresh clones, never from plan.md, per PLAN-PROTOCOL section 9. Nothing is
    quoted: the case inventory at both ends, both conformance scores, both
    cases-run figures and CasesDefined are measured here, at both commits.

    -FailCheck additionally damages the head clone in five ways the pass claims
    it would catch, and reports a probe that does NOT fail as a failure. A check
    that cannot fail has checked nothing. P3 is the one that matters most: it
    corrupts a probe VALUE rather than removing a block, which is the only way
    to show the declaration is being consumed and not merely carried.

    Writes only under scratch/ and removes what it wrote.

.PARAMETER RepoRoot
    The harness repository. Defaults to two levels above this script.

.PARAMETER TargetRemote
    PSGraphRender's origin. Derived from the sibling checkout when not given.

.PARAMETER HeadRef
    What to verify. Defaults to 'main'. Before the fast-forward, pass the pass
    branch tip - see the refusal below.

.PARAMETER BaseRef
    What to verify against: PSGraphRender at v0.15.0, which is this pass's base
    and the commit every byte comparison here is made against.

.PARAMETER FailCheck
    Run the deliberate-failure probes against the verifier itself.

.PARAMETER SkipBrowser
    Omit the checks that need the headless browser harness. They are the only
    ones that establish a declared selector actually finds anything, so skipping
    them is reported in the summary rather than passing quietly.

.EXAMPLE
    ./plans/0050-link-probe-data/verify.ps1 -HeadRef pass-0050-link-probe-data
.EXAMPLE
    ./plans/0050-link-probe-data/verify.ps1
.EXAMPLE
    ./plans/0050-link-probe-data/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $HeadRef = 'main',
    [string] $BaseRef = '0d2c5df',
    [switch] $FailCheck,
    [switch] $SkipBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Decision 0004: a plan and its verify script are frozen at the commit that pass
# pushed. Recorded, compared, and reported - never edited forward when the
# repository grows past it.
$WrittenAgainstTarget = 'e7bbfca'
$WrittenAgainstHarness = 'pass-0050-link-probe-data'

# The fields link-mode.cjs cannot work without. Named here rather than read from
# the harness, so a harness that quietly stopped requiring one is a disagreement
# this script reports instead of inheriting.
$RequiredField = @('Canvas', 'Menu', 'Button', 'Ready')

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

$work = Join-Path $RepoRoot 'scratch/verify-0050'
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

function Invoke-BuildTask {
    param([string] $Clone, [string] $Task)
    $out = & pwsh -NoProfile -NonInteractive -Command "& '$(Join-Path $Clone 'build.ps1')' -Task $Task" 2>&1
    [pscustomobject]@{ Ok = ($LASTEXITCODE -eq 0); Text = ($out | Out-String) }
}

# Every backend a clone ships, with its manifest, discovered by the presence of
# templateset.psd1 - never from a list, which is the rule the repository states
# about itself in Get-BackendDirectory.
function Get-BackendManifest {
    param([string] $Clone)

    $root = Join-Path $Clone 'src/PSGraphRender/TemplateSets'
    foreach ($dir in (Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name)) {
        $file = Join-Path $dir.FullName 'templateset.psd1'
        if (-not (Test-Path -LiteralPath $file)) { continue }
        $m = Import-PowerShellDataFile -LiteralPath $file
        [pscustomobject]@{
            Name     = $dir.Name
            Path     = $file
            Manifest = $m
            HasModes = ($m.Contains('SlotsBySetting') -and $m.SlotsBySetting.Contains('LinkMode'))
            Probe    = $(if ($m.Contains('LinkProbe')) { $m.LinkProbe } else { $null })
        }
    }
}

# One clone, one render, one backend, one payload. No settings written: this
# pass changes nothing a setting selects, so the comparison is of the default
# document each backend produces.
function Get-RenderOf {
    param(
        [string] $Clone,
        [string] $Backend,
        [string] $OutFile,
        [string] $Fixture = 'examples/input/ecosystem-viewmodel.json'
    )

    $set = Join-Path $Clone "output/PSGraphRender/TemplateSets/$Backend"
    $payload = Join-Path $Clone $Fixture
    if (Test-Path -LiteralPath $OutFile) { Remove-Item -LiteralPath $OutFile -Force }
    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module '$(Join-Path $Clone 'output/PSGraphRender/PSGraphRender.psd1')' -Force
`$vm = Get-Content -LiteralPath '$payload' -Raw | ConvertFrom-Json
`$doc = New-RenderDocument -ViewModel `$vm.data -Meta `$vm.meta -Title 'Verify 0050' -TemplateSetPath '$set'
[System.IO.File]::WriteAllText('$OutFile', `$doc)
"@ 2>&1
    if (-not (Test-Path -LiteralPath $OutFile)) { throw "render produced nothing: $(($log | Select-Object -Last 5) -join ' / ')" }
    [System.IO.File]::ReadAllText($OutFile)
}

# The probe's own report, as data: one line per case, in the order the task ran
# them. This is what "the same case inventory" is compared on, and it carries
# the resolved href rather than just the case id, so a case that ran and
# resolved differently is as visible as a case that stopped running.
function Get-CaseInventory {
    param([string] $Text)
    @($Text -split "`r?`n" |
            ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' } |
            Where-Object { $_ -match '^\s*link mode \S+/\S+:' } |
            ForEach-Object { $_.Trim() })
}

# JS with comments removed. The harness is allowed to DISCUSS '#cy' in the
# sentence explaining why it must not contain one; the check is about code.
function Remove-JavaScriptComment {
    param([string] $Source)
    $text = [regex]::Replace($Source, '(?s)/\*.*?\*/', '')
    ($text -split "`n" | ForEach-Object { if ($_ -match '^\s*//') { '' } else { $_ } }) -join "`n"
}

# Every string value any backend declares in its LinkProbe, as a quoted JS
# literal. Derived from the manifests rather than from a list of known
# selectors, so a fourth backend's shape is covered the day it is declared.
function Get-ForbiddenLiteral {
    param($Backends)
    $values = @(
        foreach ($b in $Backends) {
            if (-not $b.Probe) { continue }
            foreach ($k in @($b.Probe.Keys)) {
                $v = $b.Probe[$k]
                if ($v -is [string] -and $v) { $v }
            }
        }
    ) | Sort-Object -Unique
    foreach ($v in $values) { "'$v'"; '"' + $v + '"' }
}

# A scratch backend: a copy of one that ships, with its manifest mutated. This
# is how the guard is driven both ways without editing anything that ships.
function New-ScratchBackend {
    param(
        [string] $Clone,
        [string] $From,
        [string] $Name,
        [Parameter(Mandatory)][scriptblock] $Mutate
    )

    $root = Join-Path $Clone 'src/PSGraphRender/TemplateSets'
    $dest = Join-Path $root $Name
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    Copy-Item -LiteralPath (Join-Path $root $From) -Destination $dest -Recurse -Force

    $file = Join-Path $dest 'templateset.psd1'
    [System.IO.File]::WriteAllText($file, (& $Mutate ([System.IO.File]::ReadAllText($file))))
    $dest
}

# Delete one top-level block from a manifest, by counting braces from its
# opening line. Text surgery on a data file is worth distrusting, so callers
# assert the result still parses and no longer carries the key.
function Remove-ManifestBlock {
    param([string] $Text, [string] $Key)

    $lines = $Text -split "`r?`n"
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*$Key\s*=\s*@\{") { $start = $i; break }
    }
    if ($start -lt 0) { return $Text }

    $depth = 0
    $end = -1
    for ($i = $start; $i -lt $lines.Count; $i++) {
        $depth += ([regex]::Matches($lines[$i], '\{')).Count
        $depth -= ([regex]::Matches($lines[$i], '\}')).Count
        if ($depth -le 0) { $end = $i; break }
    }
    if ($end -lt 0) { return $Text }
    while ($start -gt 0 -and $lines[$start - 1] -match '^\s*#') { $start-- }

    (@($lines[0..($start - 1)]) + @($lines[($end + 1)..($lines.Count - 1)])) -join "`n"
}

# The 0043 grep. A drive path, a home directory, a username, or a vscode:// URI
# carrying a real path, in anything the pass commits. Vendored files are exempt
# as third-party bytes this repository did not write and may not edit.
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
            # The running user's name, derived rather than written down. 0047's
            # form spelled it out, which put a username into the verifier that
            # exists to keep usernames out of things - and it only ever matched
            # one machine anyway. Guarded on length so a short generic account
            # name cannot make this fire on ordinary prose.
            if ($env:USERNAME -and $env:USERNAME.Length -ge 4 -and $line -match [regex]::Escape($env:USERNAME)) {
                $hits += "$([System.IO.Path]::GetFileName($f)): username"
            }
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
Import-Module Pester -MinimumVersion 6.0.0 -Force
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

# The browser harness is a node_modules tree, and .gitignore keeps it out of the
# repository - correctly, but it means a FRESH CLONE cannot run the checks that
# establish a declared selector finds anything. The build task fails by name
# rather than skipping, which is right, and here it would read as a defect in
# the pass rather than as a missing install.
#
# So it is copied in from the checkout beside this harness, and only when the
# clone's own Requirements.psd1 pins the version that checkout has.
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
    # The version, not the path it came from. This line lands in a committed
    # verify record, and the public-artifact rule applies to those too - naming
    # the source directory would put one machine's layout in the repository.
    "copied Playwright $have from the sibling checkout"
}

# A probe damages the head clone, re-runs one check, and asserts it goes RED.
# Restored from git afterwards, so the next probe starts from the landed tree.
# node_modules is deliberately not cleaned: it is not tracked and re-copying it
# costs a minute per probe.
function Restore-Head {
    param([string] $Clone)
    & git -C $Clone checkout --quiet -- . 2>&1 | Out-Null
    & git -C $Clone clean --quiet -fd -- src 2>&1 | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $Clone 'src/PSGraphRender/TemplateSets') -Directory |
        Where-Object { $_.Name -like 'zz*' } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
    Invoke-Build -Clone $Clone
}

# ------------------------------------------------------------------ run
try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    ''
    'VERIFY 0050 - the link probe as backend data, re-derived from fresh clones.'
    "  target remote : $TargetRemote"
    "  head ref      : $HeadRef"
    "  base ref      : $BaseRef (v0.15.0, pass 0049's tip)"
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
        "        below may be a later change rather than a defect in 0050."
    }
    ''

    Invoke-Build -Clone $head
    Invoke-Build -Clone $base

    # --------------------------------------------------------------- check 1
    ''
    '1. Every backend with link modes declares how to reach them, and only those do.'

    $headBackends = @(Get-BackendManifest -Clone $head)
    $baseBackends = @(Get-BackendManifest -Clone $base)

    $withModes = @($headBackends | Where-Object { $_.HasModes })
    $without = @($headBackends | Where-Object { -not $_.HasModes })
    "     backends: $(($headBackends | ForEach-Object { $_.Name }) -join ', ')"
    "     with link modes: $(($withModes | ForEach-Object { $_.Name }) -join ', ')"

    # A rule that applies to everything or to nothing is not discriminating.
    Assert-That -What 'the rule has backends on both sides of it' `
        -Ok ($withModes.Count -gt 1 -and $without.Count -gt 0) `
        -Detail "$($withModes.Count) with, $($without.Count) without"

    $undeclared = @($withModes | Where-Object { -not $_.Probe } | ForEach-Object { $_.Name })
    Assert-That -What 'every backend with link modes declares a LinkProbe' -Ok ($undeclared.Count -eq 0) `
        -Detail $(if ($undeclared) { $undeclared -join ', ' } else { 'all of them' })

    $incomplete = @(
        foreach ($b in $withModes) {
            if (-not $b.Probe) { continue }
            foreach ($f in $RequiredField) {
                if (-not $b.Probe.Contains($f) -or [string]::IsNullOrWhiteSpace([string]$b.Probe[$f])) { "$($b.Name).$f" }
            }
        }
    )
    Assert-That -What "every LinkProbe carries $($RequiredField -join ', ')" -Ok ($incomplete.Count -eq 0) `
        -Detail $(if ($incomplete) { $incomplete -join ', ' } else { 'complete' })

    $badButton = @($withModes | Where-Object { $_.Probe -and [string]$_.Probe.Button -notin @('left', 'right', 'middle') } |
            ForEach-Object { "$($_.Name)=$($_.Probe.Button)" })
    Assert-That -What 'every declared button is one a browser can press' -Ok ($badButton.Count -eq 0) `
        -Detail $(if ($badButton) { $badButton -join ', ' } else { (($withModes | ForEach-Object { "$($_.Name)=$($_.Probe.Button)" }) -join ', ') })

    $spurious = @($without | Where-Object { $_.Probe } | ForEach-Object { $_.Name })
    Assert-That -What 'a backend with no link modes declares no probe' -Ok ($spurious.Count -eq 0) `
        -Detail $(if ($spurious) { $spurious -join ', ' } else { "$(($without | ForEach-Object { $_.Name }) -join ', ') declare none, correctly" })

    # And the base did not already have this, or check 1 is measuring nothing.
    $baseDeclared = @($baseBackends | Where-Object { $_.Probe } | ForEach-Object { $_.Name })
    Assert-That -What 'no backend declared a LinkProbe at base' -Ok ($baseDeclared.Count -eq 0) `
        -Detail $(if ($baseDeclared) { $baseDeclared -join ', ' } else { 'none - so this is the change, not the status quo' })

    # --------------------------------------------------------------- check 2
    ''
    '2. The selectors are written down once. By absence, at both ends.'

    $headBuild = [System.IO.File]::ReadAllText((Join-Path $head 'PSGraphRender.build.ps1'))
    $baseBuild = [System.IO.File]::ReadAllText((Join-Path $base 'PSGraphRender.build.ps1'))
    Assert-That -What 'no $LINK_PROBE in the build task at head' -Ok (-not $headBuild.Contains('$LINK_PROBE'))
    Assert-That -What 'and it WAS there at base, so this check can fail' -Ok ($baseBuild.Contains('$LINK_PROBE')) `
        -Detail "$(([regex]::Matches($baseBuild, '\$LINK_PROBE')).Count) occurrence(s) at $baseSha"

    $forbidden = @(Get-ForbiddenLiteral -Backends $headBackends)
    "     $($forbidden.Count) literal(s) derived from the manifests, e.g. $(($forbidden | Select-Object -First 3) -join ' ')"
    Assert-That -What 'the derived list is not empty' -Ok ($forbidden.Count -gt 6) -Detail "$($forbidden.Count)"

    $headHarness = Remove-JavaScriptComment -Source ([System.IO.File]::ReadAllText((Join-Path $head 'tests/browser/link-mode.cjs')))
    $baseHarness = Remove-JavaScriptComment -Source ([System.IO.File]::ReadAllText((Join-Path $base 'tests/browser/link-mode.cjs')))

    $headNamed = @($forbidden | Where-Object { $headHarness.Contains($_) })
    $baseNamed = @($forbidden | Where-Object { $baseHarness.Contains($_) })
    Assert-That -What 'the browser harness names no declared selector at head' -Ok ($headNamed.Count -eq 0) `
        -Detail $(if ($headNamed) { $headNamed -join ', ' } else { 'none of them' })
    Assert-That -What 'and it DID at base, so this check can fail' -Ok ($baseNamed.Count -gt 0) `
        -Detail "$($baseNamed -join ', ') at $baseSha"

    Assert-That -What 'the DEFAULTS object is gone from the harness' -Ok (-not $headHarness.Contains('DEFAULTS')) `
        -Detail $(if ($baseHarness.Contains('DEFAULTS')) { 'present at base' } else { 'and was not at base either' })

    # --------------------------------------------------------------- check 3
    ''
    '3. Nothing rendered moved. All three backends, byte-for-byte against base.'

    foreach ($b in $headBackends) {
        $h = Get-RenderOf -Clone $head -Backend $b.Name -OutFile (Join-Path $work "head-$($b.Name).html")
        $x = Get-RenderOf -Clone $base -Backend $b.Name -OutFile (Join-Path $work "base-$($b.Name).html")
        Assert-That -What "$($b.Name) renders byte-identically to $baseSha" -Ok ($h -eq $x) `
            -Detail "$($h.Length) vs $($x.Length) char(s)"
    }

    $suite = Invoke-Suite -Clone $head -File 'tests/LinkMode.Tests.ps1'
    $red = @($suite | Where-Object { $_.Result -ne 'Passed' })
    Assert-That -What "the editor-mode byte gate is green and untouched ($($suite.Count) assertions)" `
        -Ok ($red.Count -eq 0) -Detail $(if ($red) { ($red | ForEach-Object { $_.Name }) -join '; ' } else { 'all passed' })

    $probeSuite = Invoke-Suite -Clone $head -File 'tests/LinkProbe.Tests.ps1'
    $probeRed = @($probeSuite | Where-Object { $_.Result -ne 'Passed' })
    Assert-That -What "the acceptance suite is green ($($probeSuite.Count) assertions)" -Ok ($probeRed.Count -eq 0) `
        -Detail $(if ($probeRed) { ($probeRed | ForEach-Object { $_.Name }) -join '; ' } else { 'all passed' })

    # --------------------------------------------------------------- check 4
    ''
    '4. The probe still probes, identically. The same cases, in a real browser.'

    if ($SkipBrowser) {
        '     SKIPPED by -SkipBrowser. These are the only checks that establish a'
        '     declared selector finds anything; the rest read text PowerShell made.'
        $script:failures.Add('checks 4 and 5 were skipped, so nothing here drove a browser')
    }
    else {
        $lend = Copy-BrowserHarness -Clone $head -From (Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender')
        "     browser harness (head): $lend"
        $lendBase = Copy-BrowserHarness -Clone $base -From (Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender')
        "     browser harness (base): $lendBase"

        $headRun = Invoke-BuildTask -Clone $head -Task TestLinkMode
        $baseRun = Invoke-BuildTask -Clone $base -Task TestLinkMode
        $headCases = @(Get-CaseInventory -Text $headRun.Text)
        $baseCases = @(Get-CaseInventory -Text $baseRun.Text)

        Assert-That -What 'TestLinkMode is green at head' -Ok $headRun.Ok `
            -Detail (($headRun.Text -split "`r?`n" | Where-Object { $_ -match 'Link mode:' } | Select-Object -Last 1) -replace '\x1b\[[0-9;]*m', '')
        Assert-That -What 'and was green at base' -Ok $baseRun.Ok `
            -Detail (($baseRun.Text -split "`r?`n" | Where-Object { $_ -match 'Link mode:' } | Select-Object -Last 1) -replace '\x1b\[[0-9;]*m', '')

        Assert-That -What 'the case inventory did not move' `
            -Ok ($headCases.Count -gt 0 -and ($headCases -join "`n") -eq ($baseCases -join "`n")) `
            -Detail "$($baseCases.Count) case(s) at base, $($headCases.Count) at head"
        foreach ($c in $headCases) { "       $c" }

        # --------------------------------------------------------------- check 5
        ''
        '5. The guard, driven both ways with a scratch backend.'

        $null = New-ScratchBackend -Clone $head -From 'cytoscape' -Name 'zzscratch' -Mutate {
            param($t) Remove-ManifestBlock -Text $t -Key 'LinkProbe'
        }
        $stripped = Import-PowerShellDataFile -LiteralPath (Join-Path $head 'src/PSGraphRender/TemplateSets/zzscratch/templateset.psd1')
        Assert-That -What 'the scratch backend declares link modes and no LinkProbe' `
            -Ok ($stripped.SlotsBySetting.Contains('LinkMode') -and -not $stripped.Contains('LinkProbe')) `
            -Detail "LinkMode=$($stripped.SlotsBySetting.Contains('LinkMode')) LinkProbe=$($stripped.Contains('LinkProbe'))"

        $guard = Invoke-BuildTask -Clone $head -Task TestLinkMode
        $named = ($guard.Text -replace '\x1b\[[0-9;]*m', '') -match 'zzscratch declares link modes and no LinkProbe block'
        Assert-That -What 'a backend with modes and no probe fails the build BY NAME' -Ok ((-not $guard.Ok) -and $named) `
            -Detail $(if ($named) { 'names the backend, the manifest and the missing key' } else { 'the message does not name it' })

        # The other direction. Without this the guard could be firing for any
        # reason a fourth directory exists at all.
        $null = New-ScratchBackend -Clone $head -From 'cytoscape' -Name 'zzscratch' -Mutate { param($t) $t }
        $allowed = Invoke-BuildTask -Clone $head -Task TestLinkMode
        $allowedCases = @(Get-CaseInventory -Text $allowed.Text)
        $scratchCases = @($allowedCases | Where-Object { $_ -match 'zzscratch/' })
        Assert-That -What 'and the same backend WITH a probe is driven through every mode' `
            -Ok ($allowed.Ok -and $scratchCases.Count -eq 5) `
            -Detail "$($allowedCases.Count) case(s) total, $($scratchCases.Count) of them zzscratch"

        Restore-Head -Clone $head
    }

    # --------------------------------------------------------------- check 6
    ''
    '6. Nothing machine-identifying in what the pass committed.'
    $touched = @(& git -C $head diff --name-only "$BaseRef..HEAD" | ForEach-Object { Join-Path $head $_ })
    "     $($touched.Count) file(s) changed since $baseSha"
    foreach ($t in $touched) { "       $($t.Substring($head.Length).TrimStart([char]92, [char]47))" }
    $identity = @(Test-NoMachineIdentity -Files $touched)
    Assert-That -What 'no drive path, home directory, username or real vscode:// in any changed file' `
        -Ok ($identity.Count -eq 0) -Detail $(if ($identity) { $identity -join '; ' } else { 'clean' })

    # --------------------------------------------------------------- check 7
    ''
    '7. Conformance, measured at both ends here rather than quoted.'
    '   This pass has no licence to change the inventory, so a moved denominator'
    '   is a failure and not a finding.'
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

    # ------------------------------------------------------------- probes
    if ($FailCheck) {
        ''
        'FALSIFICATION - each damages the head clone and asserts the check goes RED.'
        ''

        # P1. A selector goes back into the harness. This is the defect the
        # whole pass is about, and check 2 is the only thing that sees it.
        $harnessFile = Join-Path $head 'tests/browser/link-mode.cjs'
        $pristine = [System.IO.File]::ReadAllText($harnessFile)
        [System.IO.File]::WriteAllText($harnessFile,
            $pristine.Replace('const REQUIRED =', "const FALLBACK = { canvas: '#cy' };`nconst REQUIRED ="))
        $damaged = Remove-JavaScriptComment -Source ([System.IO.File]::ReadAllText($harnessFile))
        Assert-That -What "P1: a selector back in the harness turns check 2 RED" `
            -Ok (@($forbidden | Where-Object { $damaged.Contains($_) }).Count -gt 0) `
            -Detail (@($forbidden | Where-Object { $damaged.Contains($_) }) -join ', ')
        $r = Invoke-Suite -Clone $head -File 'tests/LinkProbe.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'keeps every declared selector out of the browser harness'
        Assert-That -What 'P1: and turns the acceptance assertion RED too' `
            -Ok ($null -ne $row -and $row.Result -eq 'Failed') `
            -Detail $(if ($row) { $row.Result } else { 'the assertion is not in the suite' })
        Restore-Head -Clone $head

        # P2. A shipped backend loses its declaration. Acceptance A must see it,
        # and so must the build task's guard.
        $fgManifest = Join-Path $head 'src/PSGraphRender/TemplateSets/forcegraph3d/templateset.psd1'
        [System.IO.File]::WriteAllText($fgManifest,
            (Remove-ManifestBlock -Text ([System.IO.File]::ReadAllText($fgManifest)) -Key 'LinkProbe'))
        Invoke-Build -Clone $head
        $r = Invoke-Suite -Clone $head -File 'tests/LinkProbe.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'declares a LinkProbe block for every backend'
        Assert-That -What 'P2: a shipped backend losing its LinkProbe turns acceptance A RED' `
            -Ok ($null -ne $row -and $row.Result -eq 'Failed') `
            -Detail $(if ($row) { $row.Message } else { 'the assertion is not in the suite' })
        if (-not $SkipBrowser) {
            $t = Invoke-BuildTask -Clone $head -Task TestLinkMode
            Assert-That -What 'P2: and the build task throws by name' `
                -Ok ((-not $t.Ok) -and (($t.Text -replace '\x1b\[[0-9;]*m', '') -match 'forcegraph3d declares link modes and no LinkProbe'))
        }
        else { '  [skip] P2s build half needs the browser harness' }
        Restore-Head -Clone $head

        # P3. THE probe for this pass. A declared VALUE is corrupted rather than
        # removed: the block is present, complete and wrong. Nothing static can
        # see it, and if the browser run still passes then the declaration is
        # being carried rather than consumed - which would make every other
        # check here green over a probe still driven by something else.
        $cyManifest = Join-Path $head 'src/PSGraphRender/TemplateSets/cytoscape/templateset.psd1'
        [System.IO.File]::WriteAllText($cyManifest,
            ([System.IO.File]::ReadAllText($cyManifest)).Replace("Canvas = '#cy'", "Canvas = '#not-a-canvas'"))
        Invoke-Build -Clone $head
        $r = Invoke-Suite -Clone $head -File 'tests/LinkProbe.Tests.ps1'
        Assert-That -What 'P3: a wrong-but-well-formed selector passes every static check' `
            -Ok (@($r | Where-Object { $_.Result -ne 'Passed' }).Count -eq 0) `
            -Detail "$(@($r | Where-Object { $_.Result -ne 'Passed' }).Count) red in the suite - which is the point"
        if (-not $SkipBrowser) {
            $t = Invoke-BuildTask -Clone $head -Task TestLinkMode
            Assert-That -What 'P3: and the browser run goes RED, so the declaration IS what drives the probe' `
                -Ok (-not $t.Ok) `
                -Detail (($t.Text -split "`r?`n" | Where-Object { $_ -match 'failures across|Cannot read' } | Select-Object -First 1) -replace '\x1b\[[0-9;]*m', '')
        }
        else { '  [skip] P3 needs the browser harness, and P3 is the reason not to skip it' }
        Restore-Head -Clone $head

        # P4. A manifest edit that DOES reach the document. Check 3 asserts the
        # LinkProbe block is invisible to assembly; this shows the comparison it
        # makes that claim with can fail.
        [System.IO.File]::WriteAllText($cyManifest,
            ([System.IO.File]::ReadAllText($cyManifest)).Replace(
                "STYLES           = @('styles/base.css',", "STYLES           = @('styles/base.css', 'styles/base.css',"))
        Invoke-Build -Clone $head
        $h = Get-RenderOf -Clone $head -Backend 'cytoscape' -OutFile (Join-Path $work 'p4.html')
        $x = [System.IO.File]::ReadAllText((Join-Path $work 'base-cytoscape.html'))
        Assert-That -What 'P4: a Slots edit turns the byte comparison RED' -Ok ($h -ne $x) `
            -Detail "$($h.Length) vs $($x.Length) char(s)"
        Restore-Head -Clone $head

        # P5. The known-bad fixture form, in a file the pass committed.
        #
        # Assembled from pieces rather than written as a literal. This file is a
        # committed artifact too, and the same grep runs over it: a verifier
        # that fails the check it verifies is a verifier nobody can leave
        # switched on.
        $badPath = 'C' + ':' + [string][char]92 + 'Users' + [string][char]92 + 'someone' + [string][char]92 + 'graph.json'
        $victim = Join-Path $head 'tests/LinkProbe.Tests.ps1'
        [System.IO.File]::WriteAllText($victim,
            [System.IO.File]::ReadAllText($victim) + "`n# $badPath`n")
        $hits = @(Test-NoMachineIdentity -Files @($victim))
        Assert-That -What 'P5: the known-bad fixture form turns check 6 RED' -Ok ($hits.Count -gt 0) `
            -Detail ($hits -join '; ')
        Restore-Head -Clone $head
    }

    # ------------------------------------------------------------- summary
    ''
    if ($failures.Count -eq 0) {
        'VERIFY 0050: every check passed.'
    }
    else {
        "VERIFY 0050: $($failures.Count) failure(s)."
        foreach ($f in $failures) { "  - $f" }
    }
    ''
    exit $(if ($failures.Count -eq 0) { 0 } else { 1 })
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
