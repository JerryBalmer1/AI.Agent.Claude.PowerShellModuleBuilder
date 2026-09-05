#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0052 made, from the repositories, without reading
    the plan.

.DESCRIPTION
    Pass 0052 has two halves in one hard order: the canvas floor was repaired
    before anything was built that would have blinded the old one.

    The claim under test is not "a theme file gained more keys". It is four
    things that are each separately falsifiable:

      * the floor is a DIFFERENCE between two pictures rather than a RATIO of
        their sizes, so a painted background cancels instead of dominating -
        and the proof is that the shipped default now scores BELOW the floor
        the old metric used, on a page that draws perfectly;
      * the old key is GONE rather than left beside the new one, because two
        floors on one selector is two answers to one question;
      * every control in the new panel moves the object that CONSUMES a
        setting, not a variable beside it - a declaration being carried and a
        declaration being consumed look identical to every static check;
      * nothing else moved, and this pass had more chances to move something
        than any before it, because it changed the default look that every
        other gate renders against.

    Nine checks and six falsification probes. Every answer is re-derived from
    fresh clones, never from plan.md, per PLAN-PROTOCOL section 9. Nothing is
    quoted: the settings inventory, the variant inventory, both canvas metrics,
    the look-gate case list, both conformance scores and CasesDefined are all
    measured here.

    -FailCheck additionally damages the head clone in six ways the pass claims
    it would catch, and reports a probe that does NOT fail as a failure. A check
    that cannot fail has checked nothing. P3 is the one that matters most, and
    it is the 0050/0051 shape: it corrupts a probe VALUE rather than removing a
    block, leaving every static check green, so the only thing that can see it
    is a browser.

    Writes only under scratch/ and removes what it wrote.

.PARAMETER RepoRoot
    The harness repository. Defaults to two levels above this script.

.PARAMETER TargetRemote
    PSGraphRender's origin. Derived from the sibling checkout when not given.

.PARAMETER HeadRef
    What to verify. Defaults to 'main'. Before the fast-forward, pass the pass
    branch tip - see the refusal below.

.PARAMETER BaseRef
    What to verify against: PSGraphRender at v0.16.0, which is this pass's base
    and the commit every byte comparison here is made against.

.PARAMETER FailCheck
    Run the deliberate-failure probes against the verifier itself.

.PARAMETER SkipBrowser
    Omit the checks that need the headless browser harness. They are the only
    ones that establish a control actually reaches the object that consumes it,
    so skipping them is reported in the summary rather than passing quietly.

.EXAMPLE
    ./plans/0052-floor-then-depth/verify.ps1 -HeadRef pass-0052-floor-then-depth
.EXAMPLE
    ./plans/0052-floor-then-depth/verify.ps1
.EXAMPLE
    ./plans/0052-floor-then-depth/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $HeadRef = 'main',
    [string] $BaseRef = 'dba1f4d',
    [switch] $FailCheck,
    [switch] $SkipBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Decision 0004: a plan and its verify script are frozen at the commit that pass
# pushed. Recorded, compared, and reported - never edited forward when the
# repository grows past it.
$WrittenAgainstTarget = 'v0.17.0'
$WrittenAgainstHarness = 'pass-0052-floor-then-depth'

# The backend this pass is about. Named once; every check derives its files.
$Backend = 'forcegraph3d'

# The backends this pass promised not to touch. Named here rather than derived,
# deliberately: a fourth backend appearing is a thing this script should NOT
# silently start ignoring, and deriving "everything except forcegraph3d" would.
$Untouched = @('cytoscape', 'plain')

# The options this pass promised, by the file the schema must place them in.
# Written down because the PROMISE is what is being verified - deriving this
# list from the schema would ask the schema whether it contains what it
# contains, which is a check that cannot fail.
$PromisedSettings = @(
    'ShowControlPanel', 'AutoRotate', 'AutoRotateSpeed'
    'FocusOnClick', 'FocusDistance', 'FocusTransitionMs'
)
$PromisedTheme = @(
    'GridStyle', 'GridColor', 'GridOpacity', 'GridGlow'
    'GridDivisions', 'GridExtent', 'GridDrop', 'GridLineWidth'
)

# The panel's minimum control set, from the prompt rather than from the markup.
# Same argument as the settings lists: the markup is the answer, not the
# question.
$PromisedControls = @(
    'fg-zoom-speed', 'fg-fit', 'fg-rotate'
    'fg-fog', 'fg-grid', 'fg-focus'
    'fg-labels-on', 'fg-particles', 'fg-glow', 'fg-kinds'
)

# The look-gate cases this pass added. A gate that ran but stopped running one
# of these is a gate that went green over the feature it was written for.
$PromisedLookCases = @(
    'grid-drawn', 'live-grid-meshes'
    'panel-open', 'panel-collapsed'
    'control-zoom-speed', 'control-fog', 'control-grid', 'control-glow'
    'control-labels', 'control-particles', 'control-auto-rotate', 'control-focus'
    'filter-drops-nodes', 'filter-drops-links'
)

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

$work = Join-Path $RepoRoot 'scratch/verify-0052'
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
    [pscustomobject]@{ Name = `$_.ExpandedPath; Result = `$_.Result }
}) | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath '$jsonPath'
"@ 2>&1
    if (-not (Test-Path -LiteralPath $jsonPath)) {
        throw "the suite produced no result for $File : $(($log | Select-Object -Last 5) -join ' / ')"
    }
    @(Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json)
}

function Get-Row {
    param($Rows, [string] $Match)
    @($Rows | Where-Object { $_.Name -like "*$Match*" }) | Select-Object -First 1
}

function Get-SchemaEntries {
    param([string] $Clone)
    (Import-PowerShellDataFile -LiteralPath (Join-Path $Clone `
                "src/PSGraphRender/TemplateSets/$Backend/Config/settings.schema.psd1")).Entries
}

function Get-VariantTable {
    param([string] $Clone)
    Import-PowerShellDataFile -LiteralPath (Join-Path $Clone 'examples/threed/variants.psd1')
}

function Get-Manifest {
    param([string] $Clone, [string] $Set = $Backend)
    Import-PowerShellDataFile -LiteralPath (Join-Path $Clone `
            "src/PSGraphRender/TemplateSets/$Set/templateset.psd1")
}

# Everything the backend's own code can read a setting from: its scripts, its
# stylesheets, and the assembly-time chooser in its manifest. Three places, not
# one - LinkMode appears in no .js at all because SlotsBySetting decides which
# FILES are in the document rather than what a script branches on.
#
# TWO stylesheets since v0.17.0, and this globs rather than naming them: a
# panel whose styles moved to a third file must not read as an unconsumed
# setting.
function Get-ConsumedSettings {
    param([string] $Clone)
    $root = Join-Path $Clone "src/PSGraphRender/TemplateSets/$Backend"
    $code = (Get-ChildItem -LiteralPath (Join-Path $root 'scripts') -Recurse -Filter *.js |
            ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"
    $css = (Get-ChildItem -LiteralPath (Join-Path $root 'styles') -Filter *.css |
            ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"
    $manifest = Get-Manifest -Clone $Clone
    [pscustomobject]@{ Code = $code; Css = $css; AtAssembly = @($manifest.SlotsBySetting.Keys) }
}

function Get-Line {
    # One reported line, as a STRING, always. Pulling a line out of a task's
    # output and calling .Trim() on it works right up until the line is not
    # there, and then the pipeline yields an empty array and the whole verifier
    # dies inside a -Detail argument - reporting a method-not-found where a
    # check result belonged. Pass 0051 found that by running it.
    param([string] $Text, [string] $Match)
    $hit = @($Text -split "`r?`n" | Where-Object { $_ -match $Match } | Select-Object -First 1)
    if ($hit.Count -eq 0) { return '(not reported)' }
    ([string]$hit[0] -replace '\[[0-9;]*m', '').Trim()
}

# BOTH canvas metrics, as data, off the browser run's own report. The gate
# prints the changed-pixel fraction AND the byte ratio for every canvas on
# every run whichever one gated, which is what makes check 4 possible without
# re-implementing either measurement here.
#
#   canvas forcegraph3d/sample-module #fg: changed 35886/1103360 px = 0.0325
#     | bytes 407277 drawn / 360736 empty = ratio 1.13 | gated on CanvasDelta >= 0.015
function Get-CanvasMetrics {
    param([string] $Text)
    $out = @{}
    foreach ($line in ($Text -split "`r?`n")) {
        $clean = $line -replace '\x1b\[[0-9;]*m', ''
        if ($clean -match ('canvas\s+(\S+)\s+\S+:\s+changed\s+\d+/\d+\s+px\s+=\s+([0-9.]+)\s*\|' +
                '\s*bytes\s+(\d+)\s+drawn\s*/\s*(\d+)\s+empty\s*=\s*ratio\s+([0-9.]+)\s*\|' +
                '\s*gated on\s+(\w+)\s*>=\s*([0-9.]+)')) {
            $out[$Matches[1]] = [pscustomobject]@{
                Changed  = [double]$Matches[2]
                Drawn    = [int]$Matches[3]
                Empty    = [int]$Matches[4]
                Ratio    = [double]$Matches[5]
                GatedOn  = $Matches[6]
                Required = [double]$Matches[7]
            }
        }
    }
    $out
}

# The look gate's own report, one line per case, in the order the task ran them.
function Get-LookInventory {
    param([string] $Text)
    @($Text -split "`r?`n" |
            ForEach-Object { $_ -replace '\x1b\[[0-9;]*m', '' } |
            Where-Object { $_ -match '^\s*look \S+/\S+:' } |
            ForEach-Object { $_.Trim() })
}

function Test-NoMachineIdentity {
    param([string[]] $Files)
    $hits = @()
    foreach ($f in $Files) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        if ([System.IO.Path]::GetExtension($f) -in '.png', '.jpg', '.gif', '.ico') { continue }
        if (@($f -split '[\\/]') -contains 'vendor') { continue }
        # Shared read, because this scan includes THIS SCRIPT'S OWN RECORDS and
        # one of them is the transcript the run is being written into right now.
        # ReadAllText opens for exclusive read and threw on it. Found by running
        # the verifier, which is the only way it could be found: the file does
        # not exist until the run that reads it.
        $stream = [System.IO.FileStream]::new($f, [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $reader = [System.IO.StreamReader]::new($stream)
        try { $text = $reader.ReadToEnd() } finally { $reader.Dispose(); $stream.Dispose() }
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -match '(^|[^A-Za-z0-9/])[A-Za-z]:[\\/]{1,2}[A-Za-z_.]' -and
                $line -notmatch 'fixtures[\\/](LinkMode|Look)|psgraphrender-|\$env:|TEMP|GetTempPath') {
                $hits += "$([System.IO.Path]::GetFileName($f)): drive path"
            }
            if ($line -match '/(Users|home)/[A-Za-z]') { $hits += "$([System.IO.Path]::GetFileName($f)): home dir" }
            # The running user's name, derived rather than written down. 0047's
            # form spelled it out, which put a username into the verifier that
            # exists to keep usernames out of things. Guarded on length so a
            # short generic account name cannot fire on ordinary prose.
            if ($env:USERNAME -and $env:USERNAME.Length -ge 4 -and $line -match [regex]::Escape($env:USERNAME)) {
                $hits += "$([System.IO.Path]::GetFileName($f)): username"
            }
            if ($line -match 'vscode://file/[A-Za-z]:') { $hits += "$([System.IO.Path]::GetFileName($f)): vscode uri with a real path" }
        }
    }
    @($hits | Sort-Object -Unique)
}

# DAMAGE THAT IS ASSERTED RATHER THAN ASSUMED, and this exists because two of
# this script's own probes damaged nothing on their first run and said nothing
# about it. Both were string replacements against text that had moved: the
# manifest aligns `Live     = '#fg-live'` with padding, and `'#fg'` sits inside
# `CanvasDelta = @{ ... }` rather than at the start of its line. Neither
# `.Replace` matched, so the clone was pristine, the gate was correctly green,
# and the probe reported the gate as unfalsifiable.
#
# The framework caught it - "a probe that does not fail is a failure" is what
# turned two silent no-ops into two red lines - but it caught it one layer too
# late to say why. A probe that cannot prove it broke something has not run.
function Edit-Damaged {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Pattern,
        [Parameter(Mandatory)][string] $Replacement,
        [Parameter(Mandatory)][string] $What
    )
    $before = [System.IO.File]::ReadAllText($Path)
    $after = [regex]::Replace($before, $Pattern, $Replacement)
    if ($after -eq $before) {
        Assert-That -What "the probe's own damage landed: $What" -Ok $false `
            -Detail "pattern matched nothing in $([System.IO.Path]::GetFileName($Path)) - the probe below proves nothing"
        return $false
    }
    [System.IO.File]::WriteAllText($Path, $after)
    return $true
}

function Restore-Head {
    param([string] $Clone)
    & git -C $Clone checkout --quiet -- . 2>&1 | Out-Null
    & git -C $Clone clean --quiet -fd -- src examples 2>&1 | Out-Null
    Invoke-Build -Clone $Clone
}

# ------------------------------------------------------------------ run
try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    ''
    'VERIFY 0052 - the floor learns to see, then the 3D view gets depth and menus.'
    "  target remote : $TargetRemote"
    "  head ref      : $HeadRef"
    "  base ref      : $BaseRef (v0.16.0, pass 0051's tip)"
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
    $headDescribe = (& git -C $head describe --tags --always HEAD 2>&1).Trim()
    if ($headDescribe -notlike "$WrittenAgainstTarget*") {
        "  NOTE: written against target $WrittenAgainstTarget on harness branch $WrittenAgainstHarness;"
        "        this head describes as $headDescribe. Decision 0004: reported, not edited forward."
    }
    ''

    Invoke-Build -Clone $head
    Invoke-Build -Clone $base

    # The browser harness is not in a clone - node_modules is gitignored, and
    # ./build.ps1 -Task BootstrapBrowser is the documented way to get it. The
    # local checkout already has it at the version Requirements.psd1 pins, so it
    # is COPIED when one is there and installed when it is not: a verifier that
    # needs a network install to run four of its checks is a verifier that gets
    # skipped.
    if (-not $SkipBrowser) {
        $localHarness = Join-Path (Split-Path -Parent $RepoRoot) 'PSGraphRender/tests/browser/node_modules'
        foreach ($clone in @($head)) {
            $dest = Join-Path $clone 'tests/browser/node_modules'
            if (Test-Path -LiteralPath $dest) { continue }
            if (Test-Path -LiteralPath $localHarness) {
                Copy-Item -LiteralPath $localHarness -Destination $dest -Recurse -Force
            }
            else {
                $null = & pwsh -NoProfile -NonInteractive -Command `
                    "& '$(Join-Path $clone 'build.ps1')' -Task BootstrapBrowser" 2>&1
            }
            if (-not (Test-Path -LiteralPath (Join-Path $dest 'playwright'))) {
                throw "the browser harness could not be provided to the clone at $clone"
            }
        }
    }

    # --------------------------------------------------------------- check 1
    ''
    '1. Every promised option is DECLARED: typed, defaulted, and in the file the'
    '   schema says it belongs in. The list is the PROMISE; the schema is the'
    '   answer. Deriving the list from the schema would ask it whether it'
    '   contains what it contains.'
    $entries = Get-SchemaEntries -Clone $head
    $baseEntries = Get-SchemaEntries -Clone $base

    $missing = @()
    $misfiled = @()
    $undefaulted = @()
    foreach ($pair in @(
            @{ Keys = $PromisedSettings; In = 'Settings' }
            @{ Keys = $PromisedTheme; In = 'Theme' }
        )) {
        foreach ($k in $pair.Keys) {
            if (-not $entries.Contains($k)) { $missing += $k; continue }
            if ($entries[$k].In -ne $pair.In) { $misfiled += "$k is In=$($entries[$k].In), expected $($pair.In)" }
            if (-not $entries[$k].Contains('Default')) { $undefaulted += $k }
            if (-not $entries[$k].Contains('Type')) { $undefaulted += "$k (no Type)" }
        }
    }
    "     promised $($PromisedSettings.Count) behaviour + $($PromisedTheme.Count) appearance = $($PromisedSettings.Count + $PromisedTheme.Count)"
    "     schema carries $(@($entries.Keys).Count) entries at head, $(@($baseEntries.Keys).Count) at base"
    Assert-That -What 'every promised option has a schema entry' -Ok ($missing.Count -eq 0) `
        -Detail $(if ($missing) { $missing -join ', ' } else { 'all present' })
    Assert-That -What 'each is In the file the schema names for its kind' -Ok ($misfiled.Count -eq 0) `
        -Detail $(if ($misfiled) { $misfiled -join '; ' } else { 'behaviour in Settings, appearance in Theme' })
    Assert-That -What 'each carries a Type and a Default' -Ok ($undefaulted.Count -eq 0) `
        -Detail $(if ($undefaulted) { $undefaulted -join ', ' } else { 'typed and defaulted' })

    # Nothing the previous release declared was dropped. A settings surface that
    # grows by quietly losing an entry is a surface no caller can rely on.
    $lost = @($baseEntries.Keys | Where-Object { -not $entries.Contains($_) })
    Assert-That -What 'no v0.16.0 setting was dropped' -Ok ($lost.Count -eq 0) `
        -Detail $(if ($lost) { $lost -join ', ' } else { "all $(@($baseEntries.Keys).Count) still declared" })

    # NO SCHEMA TYPE WAS ADDED TO THE MODULE, which is the seam claim in its
    # sharpest form: a backend is a directory, and a new TYPE needs a validator
    # under src/PSGraphRender/Private/Config - a .ps1, which this pass is
    # forbidden to edit.
    #
    # ASKED OF THE VALIDATOR, NOT OF THE PREVIOUS SCHEMA. The first version of
    # this check compared the backend's types at head against its types at base
    # and called any difference a new type. That is the wrong subject and it
    # went red on correct work: `Boolean` is new to THIS BACKEND at v0.17.0 and
    # was already a validated type in `Test-RenderSettingValue.ps1`, untouched
    # by this pass. A backend using a type it had not used before is a data
    # change; only a type the module cannot validate is a module change.
    $validator = Join-Path $head 'src/PSGraphRender/Private/Config/Test-RenderSettingValue.ps1'
    $validatorText = [System.IO.File]::ReadAllText($validator)
    $headTypes = @($entries.Keys | ForEach-Object { $entries[$_].Type } | Sort-Object -Unique)
    $unvalidated = @($headTypes | Where-Object { $validatorText -notmatch "'$([regex]::Escape($_))'" })
    Assert-That -What 'every type the backend declares is one the MODULE already validates' `
        -Ok ($unvalidated.Count -eq 0) `
        -Detail "head types: $($headTypes -join ', ')$(if ($unvalidated) { " UNVALIDATED: $($unvalidated -join ', ')" })"

    # And the validator itself did not move, which is the other half: a type
    # that IS validated because this pass taught it to would pass the check
    # above and still be a module change.
    $validatorDiff = @(& git -C $head diff --name-only $BaseRef -- 'src/PSGraphRender/Private/Config' |
            Where-Object { $_ })
    Assert-That -What 'and the validator that decides them is byte-identical to base' `
        -Ok ($validatorDiff.Count -eq 0) `
        -Detail $(if ($validatorDiff) { $validatorDiff -join ', ' } else { 'unchanged' })

    # --------------------------------------------------------------- check 2
    ''
    '2. Every declared setting is CONSUMED somewhere, and every shipped value is'
    '   DECLARED. The two directions of the same claim, and the pair is what'
    '   keeps a settings surface from becoming a list of promises.'
    $consumed = Get-ConsumedSettings -Clone $head
    $unread = @($entries.Keys | Where-Object {
            $consumed.Code -notmatch [regex]::Escape($_) -and
            $consumed.Css -notmatch [regex]::Escape($_) -and
            $consumed.AtAssembly -notcontains $_
        })
    Assert-That -What 'no declared setting is read by nothing' -Ok ($unread.Count -eq 0) `
        -Detail $(if ($unread) { $unread -join ', ' } else { "all $(@($entries.Keys).Count) reached" })

    $shipped = @()
    foreach ($f in @('settings.psd1', 'theme.psd1')) {
        $v = Import-PowerShellDataFile -LiteralPath (Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/Config/$f")
        $shipped += @($v.Keys)
    }
    $undeclared = @($shipped | Where-Object { -not $entries.Contains($_) })
    Assert-That -What 'every shipped value has a schema entry' -Ok ($undeclared.Count -eq 0) `
        -Detail $(if ($undeclared) { $undeclared -join ', ' } else { "$($shipped.Count) shipped values, all declared" })

    # The panel's own text. Every word it shows has to be a key the backend
    # ships, or the page prints the KEY at a reader - the quiet failure the
    # string reader's fallback is designed to make visible.
    $panelScript = [System.IO.File]::ReadAllText(
        (Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/scripts/panel.js"))
    $panelMarkup = [System.IO.File]::ReadAllText(
        (Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/partials/graph.html"))
    $strings = Import-PowerShellDataFile -LiteralPath (
        Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/Config/strings.psd1")
    $asked = @(
        [regex]::Matches($panelScript, "setText\('[a-z0-9-]+',\s*'([A-Za-z]+)'\)") +
        [regex]::Matches($panelScript, "str\('([A-Za-z]+)'\)") |
            ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $absent = @($asked | Where-Object { -not $strings.Contains($_) })
    "     the panel asks for $($asked.Count) string(s); strings.psd1 ships $(@($strings.Keys).Count)"
    Assert-That -What 'every string the panel asks for is one the backend ships' `
        -Ok ($asked.Count -gt 12 -and $absent.Count -eq 0) `
        -Detail $(if ($absent) { $absent -join ', ' } else { 'all present' })

    # The prompt's minimum control set, declared AND wired. Presence is not
    # consumption - the lesson pass 0050 paid for.
    $undeclaredControls = @($PromisedControls | Where-Object { $panelMarkup -notmatch [regex]::Escape("id=`"$_`"") })
    $unwiredControls = @($PromisedControls | Where-Object { $panelScript -notmatch [regex]::Escape($_) })
    Assert-That -What 'every promised control is declared in the markup' -Ok ($undeclaredControls.Count -eq 0) `
        -Detail $(if ($undeclaredControls) { $undeclaredControls -join ', ' } else { "$($PromisedControls.Count) control(s)" })
    Assert-That -What 'and named by the script that wires it' -Ok ($unwiredControls.Count -eq 0) `
        -Detail $(if ($unwiredControls) { $unwiredControls -join ', ' } else { 'all wired' })

    # --------------------------------------------------------------- check 3
    ''
    '3. Acceptance A-E, run in the head clone. This is the pass''s own suite and'
    '   it is run rather than quoted.'
    $accept = Invoke-Suite -Clone $head -File 'tests/ForceGraph3DLook.Tests.ps1'
    $red = @($accept | Where-Object { $_.Result -ne 'Passed' })
    "     $(@($accept).Count) assertion(s)"
    Assert-That -What 'acceptance A-E all green' -Ok ($red.Count -eq 0) `
        -Detail $(if ($red) { ($red | ForEach-Object { $_.Name }) -join '; ' } else { 'no red' })

    # The repairs earlier passes paid for, by name, because a rewrite is exactly
    # when a repair is lost and the suite is the only thing that would notice.
    foreach ($repair in @(
            'builds the hover label as an ELEMENT'
            'still fits the view immediately as well as on settle'
            'still sizes the drawing buffer from the container'
            'still beats the user agent on'
        )) {
        $row = Get-Row -Rows $accept -Match $repair
        Assert-That -What "0049 repair still asserted: $repair" `
            -Ok ($null -ne $row -and $row.Result -eq 'Passed') `
            -Detail $(if ($row) { $row.Result } else { 'the assertion is not in the suite' })
    }

    # The panel says nothing of its own - the half of acceptance C a browser is
    # not needed for, and the half the 2D sidebar gets wrong.
    foreach ($claim in @(
            'writes no user-visible word of its own into the markup'
            'wires every control it declares'
            'names no classification anywhere in the panel'
        )) {
        $row = Get-Row -Rows $accept -Match $claim
        Assert-That -What "acceptance C asserts it: $claim" `
            -Ok ($null -ne $row -and $row.Result -eq 'Passed') `
            -Detail $(if ($row) { $row.Result } else { 'the assertion is not in the suite' })
    }

    # --------------------------------------------------------------- check 4
    ''
    '4. THE FLOOR IS A DIFFERENCE, NOT A RATIO - the first half of this pass and'
    '   the reason the second half could ship at all.'
    $headManifest = Get-Manifest -Clone $head
    $baseManifest = Get-Manifest -Clone $base
    $cyHead = Get-Manifest -Clone $head -Set 'cytoscape'

    $baseFloor = $baseManifest.Smoke.CanvasGrowth['#fg']
    "     base declared CanvasGrowth #fg = $baseFloor"

    # The old key is GONE rather than left beside the new one. Two floors on one
    # selector is two answers to one question, and the stale one is the one
    # nobody re-measures.
    $hasOld = $headManifest.Smoke.Contains('CanvasGrowth') -and
        @($headManifest.Smoke.CanvasGrowth.Keys).Count -gt 0
    Assert-That -What 'CanvasGrowth is GONE from the 3D backend, not left beside the new key' `
        -Ok (-not $hasOld) `
        -Detail $(if ($hasOld) { "still declares $(@($headManifest.Smoke.CanvasGrowth.Keys) -join ', ')" } else { 'absent' })

    $hasNew = $headManifest.Smoke.Contains('CanvasDelta') -and
        $headManifest.Smoke.CanvasDelta.Contains('#fg')
    Assert-That -What 'and CanvasDelta declares the new floor in its place' -Ok $hasNew `
        -Detail $(if ($hasNew) { "#fg >= $($headManifest.Smoke.CanvasDelta['#fg'])" } else { 'not declared' })

    # cytoscape keeps the byte ratio, because an empty cytoscape render really
    # is nearly blank. The claim is that this was RULED rather than overlooked.
    Assert-That -What 'cytoscape still gates on CanvasGrowth - the metric fits the backend' `
        -Ok ($cyHead.Smoke.Contains('CanvasGrowth') -and $cyHead.Smoke.CanvasGrowth.Contains('#cy')) `
        -Detail $(if ($cyHead.Smoke.Contains('CanvasGrowth')) { "#cy >= $($cyHead.Smoke.CanvasGrowth['#cy'])" } else { 'absent' })

    # --------------------------------------------------------------- check 5
    ''
    '5. The catalogue REGENERATES, and the promotion is visible in it.'
    $table = Get-VariantTable -Clone $head
    $variants = @($table.Variants)
    $labels = @($variants.Label)
    $families = @($variants.Family | Sort-Object -Unique)
    "     $($variants.Count) variant(s) in $($families.Count) famil(ies): $($families -join ', ')"
    Assert-That -What 'at least 16 variants across at least 5 families' `
        -Ok ($variants.Count -ge 16 -and $families.Count -ge 5) `
        -Detail "$($variants.Count) / $($families.Count)"

    # SC1, as a check rather than a note: a variant may only move configuration.
    $offTable = @()
    foreach ($v in $variants) {
        foreach ($k in @($v.Overlay.Keys)) { if (-not $entries.Contains($k)) { $offTable += "$($v.Label):$k" } }
    }
    Assert-That -What 'SC1 every variant is one overlay of DECLARED settings, nothing else' `
        -Ok ($offTable.Count -eq 0) -Detail $(if ($offTable) { $offTable -join ', ' } else { 'configuration only' })

    $a0 = @($variants | Where-Object { $_.Label -eq 'A0' })
    Assert-That -What 'A0 is the fixed origin and carries no overlay at all' `
        -Ok (@($a0).Count -eq 1 -and @($a0[0].Overlay.Keys).Count -eq 0) `
        -Detail "$(@($a0).Count) row(s), $(if (@($a0).Count) { @($a0[0].Overlay.Keys).Count } else { 'n/a' }) key(s)"

    # THE PROMOTION, as two facts rather than one. The previous default is kept
    # whole so the change can be looked at; the row that became the default is
    # gone so the catalogue has no second picture of A0.
    $a5 = @($variants | Where-Object { $_.Label -eq 'A5' })
    Assert-That -What 'the previous default is preserved as a labelled variant' `
        -Ok (@($a5).Count -eq 1 -and @($a5[0].Overlay.Keys).Count -gt 5) `
        -Detail "A5 carries $(if (@($a5).Count) { @($a5[0].Overlay.Keys).Count } else { 0 }) key(s)"
    Assert-That -What 'E1 is retired rather than left as a duplicate of the default' `
        -Ok ($labels -notcontains 'E1') `
        -Detail "labels: $($labels -join ' ')"
    Assert-That -What 'and its committed artifacts went with it' `
        -Ok (-not (Test-Path -LiteralPath (Join-Path $head 'examples/threed/catalog/E1.html')) -and
            -not (Test-Path -LiteralPath (Join-Path $head 'examples/threed/catalog/E1.png'))) `
        -Detail 'no E1.html, no E1.png'

    # The environment is IN the catalogue, which is what makes it reviewable.
    $gridVariants = @($variants | Where-Object { @($_.Overlay.Keys) -contains 'GridStyle' })
    Assert-That -What 'the environment family is in the catalogue' -Ok ($gridVariants.Count -ge 2) `
        -Detail "$(@($gridVariants.Label) -join ', ')"

    $committedCatalog = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
    $null = & pwsh -NoProfile -NonInteractive -Command `
        "& '$(Join-Path $head 'examples/Build-Examples.ps1')' -Variant all -SkipShots" 2>&1
    $rebuilt = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
    # Line endings normalised on both sides, and only line endings: .gitattributes
    # stores every text file as LF and the generator writes what the parts carry,
    # so a raw comparison measures git's normalisation rather than the generator.
    Assert-That -What 'the committed catalogue page is what its table generates' `
        -Ok (($committedCatalog -replace "`r`n", "`n") -eq ($rebuilt -replace "`r`n", "`n")) `
        -Detail "$(($committedCatalog -replace "`r`n", "`n").Length) char(s), identical after line-ending normalisation"

    $missingArtifacts = @()
    foreach ($v in $variants) {
        foreach ($ext in 'html', 'png') {
            if (-not (Test-Path -LiteralPath (Join-Path $head "examples/threed/catalog/$($v.Label).$ext"))) {
                $missingArtifacts += "$($v.Label).$ext"
            }
        }
        if ($committedCatalog -notlike "*$($v.Label)*") { $missingArtifacts += "$($v.Label) absent from the page" }
    }
    Assert-That -What 'every variant has a committed html, a committed png, and a place on the page' `
        -Ok ($missingArtifacts.Count -eq 0) `
        -Detail $(if ($missingArtifacts) { $missingArtifacts -join ', ' } else { "$($variants.Count * 2) artifact(s)" })

    Assert-That -What 'SC4 the catalogue page inlines no library and fetches nothing' `
        -Ok ($committedCatalog -notmatch '<script' -and $committedCatalog -notmatch 'https?://' -and $committedCatalog.Length -lt 200000) `
        -Detail "$($committedCatalog.Length) bytes, no script tag, no absolute URL"
    Restore-Head -Clone $head

    # --------------------------------------------------------------- check 6
    ''
    '6. Nothing else moved. Byte comparisons against the base commit, by git,'
    '   rather than by a snapshot this script could take of a tree it changed.'
    foreach ($set in $Untouched) {
        $diff = @(& git -C $head diff --name-only $BaseRef -- "src/PSGraphRender/TemplateSets/$set" |
                Where-Object { $_ })
        Assert-That -What "$set is byte-identical to base" -Ok ($diff.Count -eq 0) `
            -Detail $(if ($diff) { $diff -join ', ' } else { 'unchanged' })
    }
    foreach ($path in @(
            @{ P = 'src/PSGraphRender/TemplateSets/index.psd1'; W = 'the default backend did not move' }
            @{ P = 'contract'; W = 'no contract change' }
        )) {
        $diff = @(& git -C $head diff --name-only $BaseRef -- $path.P | Where-Object { $_ })
        Assert-That -What $path.W -Ok ($diff.Count -eq 0) `
            -Detail $(if ($diff) { $diff -join ', ' } else { 'unchanged' })
    }
    $psDiff = @(& git -C $head diff --name-only $BaseRef -- 'src' |
            Where-Object { $_ -like '*.ps1' -or $_ -like '*.psm1' })
    Assert-That -What 'no .ps1 or .psm1 under src/ was edited - a backend is still a directory' `
        -Ok ($psDiff.Count -eq 0) -Detail $(if ($psDiff) { $psDiff -join ', ' } else { 'none' })

    $manifestDiff = @(& git -C $head diff -U0 $BaseRef -- 'src/PSGraphRender/PSGraphRender.psd1' |
            Where-Object { $_ -match '^[+-][^+-]' })
    Assert-That -What 'the module manifest changed only its version line' `
        -Ok (@($manifestDiff | Where-Object { $_ -notmatch 'ModuleVersion' }).Count -eq 0) `
        -Detail (($manifestDiff | ForEach-Object { $_.Trim() }) -join ' | ')

    # Nothing new vendored, and every hash still matches. The environment is
    # built from vertices this repository owns rather than from a second copy of
    # three.js, and this is what says so.
    $vendorHead = Import-PowerShellDataFile -LiteralPath (Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/vendor/vendor.psd1")
    $vendorBase = Import-PowerShellDataFile -LiteralPath (Join-Path $base "src/PSGraphRender/TemplateSets/$Backend/vendor/vendor.psd1")
    Assert-That -What 'no file was vendored in this release - no second copy of three.js' `
        -Ok ((@($vendorHead.Files.Name) -join ',') -eq (@($vendorBase.Files.Name) -join ',')) `
        -Detail "base: $(@($vendorBase.Files.Name) -join ', ') / head: $(@($vendorHead.Files.Name) -join ', ')"
    $vendorSuite = Invoke-Suite -Clone $head -File 'tests/Vendor.Tests.ps1'
    $vendorRed = @($vendorSuite | Where-Object { $_.Result -ne 'Passed' })
    Assert-That -What 'every vendored file still matches its recorded sha384' -Ok ($vendorRed.Count -eq 0) `
        -Detail $(if ($vendorRed) { ($vendorRed | ForEach-Object { $_.Name }) -join '; ' } else { "$(@($vendorSuite).Count) assertion(s) green" })

    # --------------------------------------------------------------- check 7
    ''
    '7. The browser gates, and the measurement that is this pass''s whole point.'
    if ($SkipBrowser) {
        '  [skip] the browser checks were skipped, and they are the only ones that'
        '         establish a control reaches the object that consumes it'
        $failures.Add('browser checks skipped')
    }
    else {
        $smoke = Invoke-BuildTask -Clone $head -Task TestBrowser
        Assert-That -What 'TestBrowser green across every backend and fixture' -Ok $smoke.Ok `
            -Detail (Get-Line -Text $smoke.Text -Match 'Browser:')

        $metrics = Get-CanvasMetrics -Text $smoke.Text
        foreach ($k in ($metrics.Keys | Sort-Object)) {
            $m = $metrics[$k]
            "     $k changed $($m.Changed) / byte-ratio $($m.Ratio) / gated on $($m.GatedOn) >= $($m.Required)"
        }
        Assert-That -What 'the gate reports BOTH metrics for every canvas, whichever one gated' `
            -Ok (@($metrics.Keys).Count -ge 6) -Detail "$(@($metrics.Keys).Count) canvas measurement(s)"

        $fg = @($metrics.Keys | Where-Object { $_ -like "$Backend/*" })
        $cy = @($metrics.Keys | Where-Object { $_ -like 'cytoscape/*' })

        Assert-That -What 'the 3D backend is gated on the DIFFERENCE metric' `
            -Ok (@($fg | Where-Object { $metrics[$_].GatedOn -ne 'CanvasDelta' }).Count -eq 0) `
            -Detail (@($fg | ForEach-Object { $metrics[$_].GatedOn } | Sort-Object -Unique) -join ', ')
        Assert-That -What 'and cytoscape on the byte ratio' `
            -Ok (@($cy | Where-Object { $metrics[$_].GatedOn -ne 'CanvasGrowth' }).Count -eq 0) `
            -Detail (@($cy | ForEach-Object { $metrics[$_].GatedOn } | Sort-Object -Unique) -join ', ')

        $thinnest = ($fg | ForEach-Object { $metrics[$_].Changed } | Measure-Object -Minimum).Minimum
        $newFloor = $metrics[$fg[0]].Required
        Assert-That -What 'the re-pinned floor is met by every fixture with room to spare' `
            -Ok (@($fg | Where-Object { $metrics[$_].Changed -lt $metrics[$_].Required * 1.5 }).Count -eq 0) `
            -Detail "thinnest $thinnest against floor $newFloor - $([math]::Round($thinnest / $newFloor, 2))x"

        # THE CLAIM, MEASURED. The shipped default is a page that draws
        # perfectly, and under the metric this pass replaced it would now score
        # BELOW the floor that shipped at v0.16.0. That is not an argument about
        # what a ratio does to a gradient - it is the gate failing the product.
        $worstRatio = ($fg | ForEach-Object { $metrics[$_].Ratio } | Measure-Object -Minimum).Minimum
        Assert-That -What "the OLD metric would now FAIL the shipped default (ratio < $baseFloor)" `
            -Ok ($worstRatio -lt $baseFloor) `
            -Detail "worst byte ratio $worstRatio against the v0.16.0 floor of $baseFloor, on a page every other gate calls green"

        # And the new one is not merely different, it is INSENSITIVE to the
        # thing that broke the old one. The empty capture is what moved: a
        # picture of nothing costs 66x more bytes with a background behind it.
        Assert-That -What 'the empty render is expensive in bytes and cheap in difference' `
            -Ok ($metrics[$fg[0]].Empty -gt 100000 -and $thinnest -gt $newFloor) `
            -Detail "empty capture $($metrics[$fg[0]].Empty) bytes, and the difference metric is unmoved by it"

        $link = Invoke-BuildTask -Clone $head -Task TestLinkMode
        Assert-That -What 'TestLinkMode green on the NEW default look, all three modes' -Ok $link.Ok `
            -Detail (Get-Line -Text $link.Text -Match 'Link mode:')

        $look = Invoke-BuildTask -Clone $head -Task TestLook
        $inventory = Get-LookInventory -Text $look.Text
        foreach ($line in $inventory) { "     $line" }
        Assert-That -What 'TestLook green: environment drawn, panel wired, every control consumed' -Ok $look.Ok `
            -Detail "$($inventory.Count) case(s)"

        # BY NAME, not by count. A gate that quietly stopped running the panel
        # cases would still report a healthy total.
        $ran = @($inventory | ForEach-Object { if ($_ -match '^look \S+/([a-z0-9-]+):') { $Matches[1] } })
        $absentCases = @($PromisedLookCases | Where-Object { $ran -notcontains $_ })
        Assert-That -What 'every case this pass added actually ran' -Ok ($absentCases.Count -eq 0) `
            -Detail $(if ($absentCases) { $absentCases -join ', ' } else { "$($PromisedLookCases.Count) new case(s) present" })

        # SC3: the injection surface, re-probed on the new default AND on a
        # high-glow variant. The link gate carries the hostile payload; running
        # it against a variant is what makes "under the new look" mean something
        # other than "under the default".
        $themeFile = Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/Config/theme.psd1"
        $pristineTheme = [System.IO.File]::ReadAllText($themeFile)
        [System.IO.File]::WriteAllText($themeFile,
            ($pristineTheme -replace "(?m)^(\s*GlowStrength\s*=\s*)[0-9.]+", '${1}2.4' `
                    -replace "(?m)^(\s*GlowOpacity\s*=\s*)[0-9.]+", '${1}0.6' `
                    -replace "(?m)^(\s*GridStyle\s*=\s*)'[^']*'", "`${1}'room'"))
        Invoke-Build -Clone $head
        $glowLink = Invoke-BuildTask -Clone $head -Task TestLinkMode
        Assert-That -What 'SC3 the injection probes stay green on a high-glow enclosed variant too' -Ok $glowLink.Ok `
            -Detail (Get-Line -Text $glowLink.Text -Match 'Link mode:|failures across')
        Restore-Head -Clone $head
    }

    # --------------------------------------------------------------- check 8
    ''
    '8. SC5 - nothing machine-identifying, across everything this pass touched'
    '   and across this script and its own records.'
    $touched = @(& git -C $head diff --name-only $BaseRef | Where-Object { $_ } |
            ForEach-Object { Join-Path $head $_ })
    "     $($touched.Count) changed file(s) in the target"
    $ownRecords = @(Get-ChildItem -LiteralPath $PSScriptRoot -File | ForEach-Object { $_.FullName })
    $identity = @(Test-NoMachineIdentity -Files ($touched + $ownRecords))
    Assert-That -What 'no drive path, home directory, username or real vscode:// anywhere' `
        -Ok ($identity.Count -eq 0) -Detail $(if ($identity) { $identity -join '; ' } else { 'clean' })

    # --------------------------------------------------------------- check 9
    ''
    '9. Conformance, measured at both ends here rather than quoted, against'
    '   BUILT trees - pass 0033''s finding, and 0050 restated it.'
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
        -Detail "$($scores['base'].CasesDefined) -> $($scores['head'].CasesDefined) (the denominator)"

    $newFailures = @($scores['head'].Failures | ForEach-Object { $_.Name } |
            Where-Object { $_ -notin @($scores['base'].Failures | ForEach-Object { $_.Name }) })
    Assert-That -What 'no assertion that passed at base fails at head' -Ok ($newFailures.Count -eq 0) `
        -Detail $(if ($newFailures) { $newFailures -join '; ' } else { 'none' })

    # ------------------------------------------------------------- probes
    if ($FailCheck) {
        ''
        'FALSIFICATION - each damages the head clone and asserts the check goes RED.'
        ''

        $manifestFile = Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/templateset.psd1"
        $variantFile = Join-Path $head 'examples/threed/variants.psd1'

        # P1. SC1's red demo. A variant that reaches past configuration.
        $pristine = [System.IO.File]::ReadAllText($variantFile)
        [System.IO.File]::WriteAllText($variantFile,
            $pristine.Replace("Overlay = @{ KindShape = '' }",
                "Overlay = @{ KindShape = ''; 'scripts/panel.js' = 'edited' }"))
        $damagedTable = Import-PowerShellDataFile -LiteralPath $variantFile
        $off = @()
        foreach ($v in @($damagedTable.Variants)) {
            foreach ($k in @($v.Overlay.Keys)) { if (-not $entries.Contains($k)) { $off += "$($v.Label):$k" } }
        }
        Assert-That -What 'P1: a variant that edits a script turns SC1 RED' -Ok ($off.Count -gt 0) `
            -Detail ($off -join ', ')
        $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph3DLook.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'keeps every variant to one overlay diff'
        Assert-That -What 'P1: and the acceptance assertion goes RED too' `
            -Ok ($null -ne $row -and $row.Result -eq 'Failed') `
            -Detail $(if ($row) { $row.Result } else { 'the assertion is not in the suite' })
        Restore-Head -Clone $head

        # P2. SC2's red demo, BOTH WAYS. The claim is that the page cannot drift
        # from the table, which means removing a row must remove a card and
        # adding one must add a card. One direction alone would be satisfied by
        # a page that ignores the table entirely.
        $before = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
        [System.IO.File]::WriteAllText($variantFile,
            ([System.IO.File]::ReadAllText($variantFile) -replace "(?s)\s*@\{\s*\r?\n\s*Label = 'C3'.*?\r?\n\s*\}", ''))
        $null = & pwsh -NoProfile -NonInteractive -Command `
            "& '$(Join-Path $head 'examples/Build-Examples.ps1')' -Variant all -SkipShots" 2>&1
        $afterDrop = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
        Assert-That -What 'P2: a row removed from the table disappears from the generated page' `
            -Ok ($before -like '*>C3<*' -and $afterDrop -notlike '*>C3<*') `
            -Detail "C3 present before: $($before -like '*>C3<*'), after: $($afterDrop -like '*>C3<*')"
        Restore-Head -Clone $head

        [System.IO.File]::WriteAllText($variantFile,
            ([System.IO.File]::ReadAllText($variantFile)).Replace(
                "        # -- C: connectors ------------------------------------------------",
                "        @{`n            Label = 'B9'; Family = 'B'`n            Name = 'Probe'`n            Caption = 'A row added by the falsification probe.'`n            Overlay = @{ ParticleCount = 0 }`n        }`n`n        # -- C: connectors ------------------------------------------------"))
        $null = & pwsh -NoProfile -NonInteractive -Command `
            "& '$(Join-Path $head 'examples/Build-Examples.ps1')' -Variant all -SkipShots" 2>&1
        $afterAdd = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
        Assert-That -What 'P2: a row added to the table appears in the generated page' `
            -Ok ($afterAdd -like '*>B9<*') -Detail "B9 on the page: $($afterAdd -like '*>B9<*')"
        Restore-Head -Clone $head

        # P3. THE ONE THAT MATTERS. A probe value that is present, complete,
        # well-formed and WRONG - the shape pass 0050 established and 0051 kept.
        # Every static check stays green over it, because there is nothing
        # statically wrong; only a browser can tell a declaration that is
        # CARRIED from one that is CONSUMED.
        #
        # The panel reads its live state off the element LookProbe.Live names.
        # Point it at another real element and every file still parses, every
        # id is still declared, every control is still wired - and the whole
        # panel half of the look gate must go red.
        # Whitespace-tolerant, because the manifest ALIGNS its assignments and
        # the first version of this probe matched `Live = ` against a file that
        # says `Live     = `. It replaced nothing and proved nothing.
        if (Edit-Damaged -Path $manifestFile -What "LookProbe.Live -> #fg-resolved" `
                -Pattern "(?m)^(\s*Live\s*=\s*)'#fg-live'" -Replacement "`${1}'#fg-resolved'") {
            Invoke-Build -Clone $head
            $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph3DLook.Tests.ps1'
            Assert-That -What 'P3: a wrong-but-well-formed LookProbe value passes every static check' `
                -Ok (@($r | Where-Object { $_.Result -ne 'Passed' }).Count -eq 0) `
                -Detail "$(@($r | Where-Object { $_.Result -ne 'Passed' }).Count) red in the suite - which is the point"
            if (-not $SkipBrowser) {
                $t = Invoke-BuildTask -Clone $head -Task TestLook
                Assert-That -What 'P3: and the browser run goes RED, so the declaration IS what drives the gate' `
                    -Ok (-not $t.Ok) `
                    -Detail (Get-Line -Text $t.Text -Match 'failures across|reports no control panel|no live value')
            }
            else { '  [skip] P3 needs the browser harness, and P3 is the reason not to skip it' }
        }
        Restore-Head -Clone $head

        # P4. THE FLOOR'S OWN RED. The new metric is a number in a manifest like
        # the old one was, and a floor nobody can fail is not a floor. Raised to
        # something no drawing reaches, the browser gate must refuse the page.
        #
        # Corrupt rather than remove, per the 0050 form: the key stays, its type
        # stays, only its value moves - so every static check stays green.
        # Anchored on the KEY rather than on the selector's line position. The
        # first version required `'#fg'` to start its line, and it does not -
        # it sits inside `CanvasDelta = @{ '#fg' = 0.015 }`. Another probe that
        # damaged nothing.
        if (Edit-Damaged -Path $manifestFile -What 'CanvasDelta floor -> 0.90' `
                -Pattern "CanvasDelta\s*=\s*@\{\s*'#fg'\s*=\s*[0-9.]+" `
                -Replacement "CanvasDelta = @{ '#fg' = 0.90") {
            Invoke-Build -Clone $head
            if (-not $SkipBrowser) {
                $t = Invoke-BuildTask -Clone $head -Task TestBrowser
                Assert-That -What 'P4: an unreachable CanvasDelta floor turns the smoke gate RED' `
                    -Ok (-not $t.Ok) -Detail (Get-Line -Text $t.Text -Match 'forcegraph3d.*changed|failures across')
            }
            else { '  [skip] P4 needs the browser harness' }
        }
        Restore-Head -Clone $head

        # P5. SC3's red demo. The injection surface, disabled.
        $graphFile = Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/scripts/graph.js"
        [System.IO.File]::WriteAllText($graphFile,
            ([System.IO.File]::ReadAllText($graphFile)).Replace(
                'name.textContent = node.name || node.id;',
                'name.innerHTML = node.name || node.id;'))
        $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph3DLook.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'builds the hover label as an ELEMENT'
        Assert-That -What 'P5: markup assignment in the label path turns SC3 RED' `
            -Ok ($null -ne $row -and $row.Result -eq 'Failed') `
            -Detail $(if ($row) { $row.Result } else { 'the assertion is not in the suite' })
        Restore-Head -Clone $head

        # P6. SC5's red demo: the known-bad fixture form, in a file the pass
        # committed.
        #
        # Assembled from pieces rather than written as a literal. This file is a
        # committed artifact too, and the same grep runs over it: a verifier
        # that fails the check it verifies is a verifier nobody can leave
        # switched on.
        $badPath = 'C' + ':' + [string][char]92 + 'Users' + [string][char]92 + 'someone' + [string][char]92 + 'graph.json'
        $victim = Join-Path $head 'tests/ForceGraph3DLook.Tests.ps1'
        [System.IO.File]::WriteAllText($victim,
            [System.IO.File]::ReadAllText($victim) + "`n# $badPath`n")
        $hits = @(Test-NoMachineIdentity -Files @($victim))
        Assert-That -What 'P6: the known-bad fixture form turns check 8 RED' -Ok ($hits.Count -gt 0) `
            -Detail ($hits -join '; ')
        Restore-Head -Clone $head
    }

    # ------------------------------------------------------------- summary
    ''
    if ($failures.Count -eq 0) {
        'VERIFY 0052: every check passed.'
    }
    else {
        "VERIFY 0052: $($failures.Count) failure(s)."
        foreach ($f in $failures) { "  - $f" }
    }
    ''
    exit $(if ($failures.Count -eq 0) { 0 } else { 1 })
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
