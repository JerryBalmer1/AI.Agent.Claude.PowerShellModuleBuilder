#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0051 made, from the repositories, without reading
    the plan.

.DESCRIPTION
    Pass 0051 gave PSGraphRender's `forcegraph3d` backend a designed look, an
    options surface, and a labelled variant catalogue.

    The claim under test is not "a theme file gained keys". It is three things
    that are each separately falsifiable:

      * every appearance and interaction choice is DECLARED as a typed setting
        with a default, and every declared setting is CONSUMED - a schema entry
        proves the first and only a live page proves the second;
      * the catalogue is GENERATED from its table, so a variant is in it because
        it is in the table and for no other reason;
      * nothing else moved - and this pass had more chances to move something
        than any before it, because it edited the backend that shares a browser
        harness, a build task and a canvas-growth floor with the other two.

    Eight checks and six falsification probes. Every answer is re-derived from
    fresh clones, never from plan.md, per PLAN-PROTOCOL section 9. Nothing is
    quoted: the settings inventory, the variant inventory, the canvas-growth
    ratios, both conformance scores and CasesDefined are measured here.

    -FailCheck additionally damages the head clone in six ways the pass claims
    it would catch, and reports a probe that does NOT fail as a failure. A check
    that cannot fail has checked nothing. P3 is the one that matters most, and
    it is the same shape pass 0050 established: it corrupts a probe VALUE rather
    than removing a block, leaving every static check green, so the only thing
    that can see it is a browser. That is what separates a declaration being
    CARRIED from a declaration being CONSUMED.

    Writes only under scratch/ and removes what it wrote.

.PARAMETER RepoRoot
    The harness repository. Defaults to two levels above this script.

.PARAMETER TargetRemote
    PSGraphRender's origin. Derived from the sibling checkout when not given.

.PARAMETER HeadRef
    What to verify. Defaults to 'main'. Before the fast-forward, pass the pass
    branch tip - see the refusal below.

.PARAMETER BaseRef
    What to verify against: PSGraphRender at v0.15.1, which is this pass's base
    and the commit every byte comparison here is made against.

.PARAMETER FailCheck
    Run the deliberate-failure probes against the verifier itself.

.PARAMETER SkipBrowser
    Omit the checks that need the headless browser harness. They are the only
    ones that establish a declared setting actually reaches the object that
    consumes it, so skipping them is reported in the summary rather than
    passing quietly.

.EXAMPLE
    ./plans/0051-forcegraph3d-catalog/verify.ps1 -HeadRef pass-0051-forcegraph3d-catalog
.EXAMPLE
    ./plans/0051-forcegraph3d-catalog/verify.ps1
.EXAMPLE
    ./plans/0051-forcegraph3d-catalog/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $HeadRef = 'main',
    [string] $BaseRef = 'e7bbfca',
    [switch] $FailCheck,
    [switch] $SkipBrowser
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Decision 0004: a plan and its verify script are frozen at the commit that pass
# pushed. Recorded, compared, and reported - never edited forward when the
# repository grows past it.
$WrittenAgainstTarget = 'v0.16.0'
$WrittenAgainstHarness = 'pass-0051-forcegraph3d-catalog'

# The backend this pass is about. Named once; every check derives its files.
$Backend = 'forcegraph3d'

# The backends this pass promised not to touch. Named here rather than derived,
# deliberately: a fourth backend appearing is a thing this script should NOT
# silently start ignoring, and deriving "everything except forcegraph3d" would.
$Untouched = @('cytoscape', 'plain')

# Every option the pass promised, by the file the schema must place it in.
# Written down because the PROMISE is what is being verified - deriving this
# list from the schema would ask the schema whether it contains what it
# contains, which is a check that cannot fail.
$PromisedSettings = @(
    'ZoomSpeed', 'RotateSpeed', 'HoverMode', 'HoverTooltip', 'NodeActionButton'
    'ShowLabels', 'LabelMaxNodes'
)
$PromisedTheme = @(
    'KindShape', 'NodeShapeFallback', 'UnresolvedShape', 'NodeSizeMetric'
    'NodeSizeMetricMax', 'ExportedEmphasis', 'GlowStrength', 'GlowSize'
    'GlowOpacity', 'FogDensity', 'FogColor', 'BackgroundStyle'
    'BackgroundGlowColor', 'ParticleCount', 'ParticleSpeed', 'ParticleWidth'
    'ParticleColor', 'LinkResolutionColor', 'ToneMappingExposure'
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

$work = Join-Path $RepoRoot 'scratch/verify-0051'
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

# Everything the backend's own code can read a setting from: its scripts, its
# stylesheet, and the assembly-time chooser in its manifest. Three places, not
# one - LinkMode appears in no .js at all because SlotsBySetting decides which
# FILES are in the document rather than what a script branches on.
function Get-ConsumedSettings {
    param([string] $Clone)
    $root = Join-Path $Clone "src/PSGraphRender/TemplateSets/$Backend"
    $code = (Get-ChildItem -LiteralPath (Join-Path $root 'scripts') -Recurse -Filter *.js |
            ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"
    $css = (Get-ChildItem -LiteralPath (Join-Path $root 'styles') -Filter *.css |
            ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $root 'templateset.psd1')
    [pscustomobject]@{ Code = $code; Css = $css; AtAssembly = @($manifest.SlotsBySetting.Keys) }
}

# The canvas-growth ratios the browser gate reports, as data. Derived from the
# run rather than from the manifest, so a floor that stopped being met is as
# visible as a floor that was never declared.
function Get-Line {
    # One reported line, as a STRING, always. Pulling a line out of a task's
    # output and calling .Trim() on it works right up until the line is not
    # there, and then the pipeline yields an empty array and the whole verifier
    # dies inside a -Detail argument - reporting a method-not-found where a
    # check result belonged. Found by running it.
    param([string] $Text, [string] $Match)
    $hit = @($Text -split "`r?`n" | Where-Object { $_ -match $Match } | Select-Object -First 1)
    if ($hit.Count -eq 0) { return '(not reported)' }
    ([string]$hit[0] -replace '\[[0-9;]*m', '').Trim()
}

function Get-CanvasRatio {
    param([string] $Text)
    $out = @{}
    foreach ($line in ($Text -split "`r?`n")) {
        $clean = $line -replace '\x1b\[[0-9;]*m', ''
        if ($clean -match 'canvas\s+(\S+)\s+\S+:\s+\d+\s+bytes drawn against\s+(\d+)\s+empty\s+-\s+ratio\s+([0-9.]+),\s+required\s+([0-9.]+)') {
            $out[$Matches[1]] = [pscustomobject]@{
                Empty = [int]$Matches[2]; Ratio = [double]$Matches[3]; Required = [double]$Matches[4]
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
        $text = [System.IO.File]::ReadAllText($f)
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
    'VERIFY 0051 - the 3D backend''s look as configuration, re-derived from fresh clones.'
    "  target remote : $TargetRemote"
    "  head ref      : $HeadRef"
    "  base ref      : $BaseRef (v0.15.1, pass 0050's tip)"
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
    # needs a network install to run three of its checks is a verifier that gets
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

    # No new schema TYPE. This is the seam claim in its sharpest form: a backend
    # is a directory, and adding a type is a module change.
    $headTypes = @($entries.Keys | ForEach-Object { $entries[$_].Type } | Sort-Object -Unique)
    $baseTypes = @($baseEntries.Keys | ForEach-Object { $baseEntries[$_].Type } | Sort-Object -Unique)
    $newTypes = @($headTypes | Where-Object { $_ -notin $baseTypes })
    Assert-That -What 'no schema TYPE was added - twenty-six settings, zero types' `
        -Ok ($newTypes.Count -eq 0) `
        -Detail "head types: $($headTypes -join ', ')$(if ($newTypes) { " NEW: $($newTypes -join ', ')" })"

    # --------------------------------------------------------------- check 2
    ''
    '2. Every declared setting is CONSUMED somewhere. The inverse of check 1,'
    '   and the one that keeps a settings surface from becoming a list of'
    '   promises. Three places count, not one.'
    $consumed = Get-ConsumedSettings -Clone $head
    $unread = @($entries.Keys | Where-Object {
            $consumed.Code -notmatch [regex]::Escape($_) -and
            $consumed.Css -notmatch [regex]::Escape($_) -and
            $consumed.AtAssembly -notcontains $_
        })
    Assert-That -What 'no declared setting is read by nothing' -Ok ($unread.Count -eq 0) `
        -Detail $(if ($unread) { $unread -join ', ' } else { "all $(@($entries.Keys).Count) reached" })

    # And every SHIPPED value is declared. The other direction: a value with no
    # schema entry applies, warns on every render, and cannot be reproduced.
    $shipped = @()
    foreach ($f in @('settings.psd1', 'theme.psd1')) {
        $v = Import-PowerShellDataFile -LiteralPath (Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/Config/$f")
        $shipped += @($v.Keys)
    }
    $undeclared = @($shipped | Where-Object { -not $entries.Contains($_) })
    Assert-That -What 'every shipped value has a schema entry' -Ok ($undeclared.Count -eq 0) `
        -Detail $(if ($undeclared) { $undeclared -join ', ' } else { "$($shipped.Count) shipped values, all declared" })

    # --------------------------------------------------------------- check 3
    ''
    '3. Acceptance A-E, run in the head clone. This is the pass''s own suite and'
    '   it is run rather than quoted.'
    $accept = Invoke-Suite -Clone $head -File 'tests/ForceGraph3DLook.Tests.ps1'
    $red = @($accept | Where-Object { $_.Result -ne 'Passed' })
    "     $(@($accept).Count) assertion(s)"
    Assert-That -What 'acceptance A-E all green' -Ok ($red.Count -eq 0) `
        -Detail $(if ($red) { ($red | ForEach-Object { $_.Name }) -join '; ' } else { 'no red' })

    # The 0049 repairs, by name, because a rewrite is exactly when a repair is
    # lost and the suite is the only thing that would notice.
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

    # --------------------------------------------------------------- check 4
    ''
    '4. The catalogue REGENERATES. Rebuilt from its own table in the clone and'
    '   compared with what is committed - the claim is that the page cannot'
    '   drift from the table, and the only way to check it is to regenerate.'
    $table = Get-VariantTable -Clone $head
    $variants = @($table.Variants)
    $families = @($variants.Family | Sort-Object -Unique)
    "     $($variants.Count) variant(s) in $($families.Count) famil(ies): $($families -join ', ')"
    Assert-That -What 'at least 16 variants across at least 5 families' `
        -Ok ($variants.Count -ge 16 -and $families.Count -ge 5) `
        -Detail "$($variants.Count) / $($families.Count)"

    $perFamily = @($families | ForEach-Object { $f = $_; @($variants | Where-Object { $_.Family -eq $f }).Count })
    Assert-That -What 'at least 3 members in every family' -Ok (@($perFamily | Where-Object { $_ -lt 3 }).Count -eq 0) `
        -Detail (@(0..($families.Count - 1) | ForEach-Object { "$($families[$_])=$($perFamily[$_])" }) -join ' ')

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

    $committedCatalog = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
    $regen = & pwsh -NoProfile -NonInteractive -Command `
        "& '$(Join-Path $head 'examples/Build-Examples.ps1')' -Variant all -SkipShots" 2>&1
    $rebuilt = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
    # Line endings normalised on both sides, and only line endings: .gitattributes
    # stores every text file as LF and the generator writes what the parts carry,
    # so a raw comparison measures git's normalisation rather than the generator.
    $committedNorm = $committedCatalog -replace "`r`n", "`n"
    $rebuiltNorm = $rebuilt -replace "`r`n", "`n"
    Assert-That -What 'the committed catalogue page is what its table generates' `
        -Ok ($committedNorm -eq $rebuiltNorm) `
        -Detail "$($committedNorm.Length) char(s), identical after line-ending normalisation"

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

    # The catalogue page is a page ABOUT the renderer, not one it made.
    Assert-That -What 'SC4 the catalogue page inlines no library and fetches nothing' `
        -Ok ($committedCatalog -notmatch '<script' -and $committedCatalog -notmatch 'https?://' -and $committedCatalog.Length -lt 200000) `
        -Detail "$($committedCatalog.Length) bytes, no script tag, no absolute URL"
    Restore-Head -Clone $head

    # --------------------------------------------------------------- check 5
    ''
    '5. Nothing else moved. Byte comparisons against the base commit, by git,'
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

    # The manifest is the ONE .psd1 under src/ this pass is allowed to move, and
    # only for the version. Asserted so a stray edit is visible.
    $manifestDiff = @(& git -C $head diff -U0 $BaseRef -- 'src/PSGraphRender/PSGraphRender.psd1' |
            Where-Object { $_ -match '^[+-][^+-]' })
    Assert-That -What 'the module manifest changed only its version line' `
        -Ok (@($manifestDiff | Where-Object { $_ -notmatch 'ModuleVersion' }).Count -eq 0) `
        -Detail (($manifestDiff | ForEach-Object { $_.Trim() }) -join ' | ')

    # Nothing new vendored, and every hash still matches.
    $vendorHead = Import-PowerShellDataFile -LiteralPath (Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/vendor/vendor.psd1")
    $vendorBase = Import-PowerShellDataFile -LiteralPath (Join-Path $base "src/PSGraphRender/TemplateSets/$Backend/vendor/vendor.psd1")
    Assert-That -What 'no file was vendored in this release' `
        -Ok ((@($vendorHead.Files.Name) -join ',') -eq (@($vendorBase.Files.Name) -join ',')) `
        -Detail "base: $(@($vendorBase.Files.Name) -join ', ') / head: $(@($vendorHead.Files.Name) -join ', ')"
    $vendorSuite = Invoke-Suite -Clone $head -File 'tests/Vendor.Tests.ps1'
    $vendorRed = @($vendorSuite | Where-Object { $_.Result -ne 'Passed' })
    Assert-That -What 'every vendored file still matches its recorded sha384' -Ok ($vendorRed.Count -eq 0) `
        -Detail $(if ($vendorRed) { ($vendorRed | ForEach-Object { $_.Name }) -join '; ' } else { "$(@($vendorSuite).Count) assertion(s) green" })

    # --------------------------------------------------------------- check 6
    ''
    '6. The browser gates. Three of them now, and the third exists because'
    '   neither of the other two can see a look.'
    if ($SkipBrowser) {
        '  [skip] the browser checks were skipped, and they are the only ones that'
        '         establish a declared setting reaches the object that consumes it'
        $failures.Add('browser checks skipped')
    }
    else {
        $smoke = Invoke-BuildTask -Clone $head -Task TestBrowser
        Assert-That -What 'TestBrowser green across every backend and fixture' -Ok $smoke.Ok `
            -Detail (Get-Line -Text $smoke.Text -Match 'Browser:')

        $ratios = Get-CanvasRatio -Text $smoke.Text
        foreach ($k in ($ratios.Keys | Sort-Object)) {
            "     $k ratio $($ratios[$k].Ratio) against $($ratios[$k].Empty) empty, floor $($ratios[$k].Required)"
        }
        $fg = @($ratios.Keys | Where-Object { $_ -like "$Backend/*" })
        Assert-That -What 'the re-measured floor is met by every fixture with room to spare' `
            -Ok (@($fg | Where-Object { $ratios[$_].Ratio -lt $ratios[$_].Required * 1.5 }).Count -eq 0) `
            -Detail "thinnest $(($fg | ForEach-Object { $ratios[$_].Ratio } | Measure-Object -Minimum).Minimum) against floor $($ratios[$fg[0]].Required)"

        # The floor MOVED, and that is the pass's own claim about it. A floor
        # left where it was under a changed look is the "quietly wrong" this
        # pass was told to prevent.
        $baseFloor = (Import-PowerShellDataFile -LiteralPath (Join-Path $base `
                    "src/PSGraphRender/TemplateSets/$Backend/templateset.psd1")).Smoke.CanvasGrowth['#fg']
        $headFloor = (Import-PowerShellDataFile -LiteralPath (Join-Path $head `
                    "src/PSGraphRender/TemplateSets/$Backend/templateset.psd1")).Smoke.CanvasGrowth['#fg']
        Assert-That -What 'the canvas-growth floor was re-examined and moved' -Ok ($headFloor -ne $baseFloor) `
            -Detail "$baseFloor -> $headFloor"

        $link = Invoke-BuildTask -Clone $head -Task TestLinkMode
        Assert-That -What 'TestLinkMode green on the NEW default look, all three modes' -Ok $link.Ok `
            -Detail (Get-Line -Text $link.Text -Match 'Link mode:')

        $look = Invoke-BuildTask -Clone $head -Task TestLook
        $inventory = Get-LookInventory -Text $look.Text
        foreach ($line in $inventory) { "     $line" }
        Assert-That -What 'TestLook green: shapes resolved, geometry drawn, settings consumed' -Ok $look.Ok `
            -Detail "$($inventory.Count) case(s)"

        # SC3: the injection surface, re-probed on the new default AND on a
        # high-glow variant. The link gate carries the hostile payload; running
        # it against a variant is what makes "under the new look" mean something
        # other than "under the default".
        $themeFile = Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/Config/theme.psd1"
        $pristineTheme = [System.IO.File]::ReadAllText($themeFile)
        [System.IO.File]::WriteAllText($themeFile,
            ($pristineTheme -replace "(?m)^(\s*GlowStrength\s*=\s*)[0-9.]+", '${1}2.4' `
                    -replace "(?m)^(\s*GlowOpacity\s*=\s*)[0-9.]+", '${1}0.6' `
                    -replace "(?m)^(\s*BackgroundStyle\s*=\s*)'[^']*'", "`${1}'vignette'"))
        Invoke-Build -Clone $head
        $glowLink = Invoke-BuildTask -Clone $head -Task TestLinkMode
        Assert-That -What 'SC3 the injection probes stay green on a high-glow variant too' -Ok $glowLink.Ok `
            -Detail (Get-Line -Text $glowLink.Text -Match 'Link mode:|failures across')
        Restore-Head -Clone $head
    }

    # --------------------------------------------------------------- check 7
    ''
    '7. SC5 - nothing machine-identifying, across everything this pass touched'
    '   and across this script and its own records.'
    $touched = @(& git -C $head diff --name-only $BaseRef | Where-Object { $_ } |
            ForEach-Object { Join-Path $head $_ })
    "     $($touched.Count) changed file(s) in the target"
    $ownRecords = @(Get-ChildItem -LiteralPath $PSScriptRoot -File | ForEach-Object { $_.FullName })
    $identity = @(Test-NoMachineIdentity -Files ($touched + $ownRecords))
    Assert-That -What 'no drive path, home directory, username or real vscode:// anywhere' `
        -Ok ($identity.Count -eq 0) -Detail $(if ($identity) { $identity -join '; ' } else { 'clean' })

    # --------------------------------------------------------------- check 8
    ''
    '8. Conformance, measured at both ends here rather than quoted, against'
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

        $schemaFile = Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/Config/settings.schema.psd1"
        $manifestFile = Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/templateset.psd1"
        $variantFile = Join-Path $head 'examples/threed/variants.psd1'

        # P1. SC1's red demo. A variant that reaches past configuration.
        $pristine = [System.IO.File]::ReadAllText($variantFile)
        [System.IO.File]::WriteAllText($variantFile,
            $pristine.Replace("Overlay = @{ KindShape = '' }",
                "Overlay = @{ KindShape = ''; 'scripts/graph.js' = 'edited' }"))
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
                "        # -- B: colour and mood ------------------------------------------",
                "        @{`n            Label = 'A9'; Family = 'A'`n            Name = 'Probe'`n            Caption = 'A row added by the falsification probe.'`n            Overlay = @{ ParticleCount = 0 }`n        }`n`n        # -- B: colour and mood ------------------------------------------"))
        $null = & pwsh -NoProfile -NonInteractive -Command `
            "& '$(Join-Path $head 'examples/Build-Examples.ps1')' -Variant all -SkipShots" 2>&1
        $afterAdd = [System.IO.File]::ReadAllText((Join-Path $head 'examples/threed/catalog.html'))
        Assert-That -What 'P2: a row added to the table appears in the generated page' `
            -Ok ($afterAdd -like '*>A9<*') -Detail "A9 on the page: $($afterAdd -like '*>A9<*')"
        Restore-Head -Clone $head

        # P3. THE ONE THAT MATTERS. A LookProbe value that is present, complete,
        # well-formed and WRONG - the shape pass 0050 established. Every static
        # check stays green over it, because there is nothing statically wrong;
        # only a browser can tell a declaration that is carried from one that is
        # consumed.
        [System.IO.File]::WriteAllText($manifestFile,
            ([System.IO.File]::ReadAllText($manifestFile)).Replace(
                "Resolved = '#fg-resolved'", "Resolved = '#fg-status'"))
        Invoke-Build -Clone $head
        $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph3DLook.Tests.ps1'
        Assert-That -What 'P3: a wrong-but-well-formed LookProbe value passes every static check' `
            -Ok (@($r | Where-Object { $_.Result -ne 'Passed' }).Count -eq 0) `
            -Detail "$(@($r | Where-Object { $_.Result -ne 'Passed' }).Count) red in the suite - which is the point"
        if (-not $SkipBrowser) {
            $t = Invoke-BuildTask -Clone $head -Task TestLook
            Assert-That -What 'P3: and the browser run goes RED, so the declaration IS what drives the gate' `
                -Ok (-not $t.Ok) `
                -Detail (Get-Line -Text $t.Text -Match 'failures across|states no resolved')
        }
        else { '  [skip] P3 needs the browser harness, and P3 is the reason not to skip it' }
        Restore-Head -Clone $head

        # P4. SC3's red demo. The injection surface, disabled.
        $graphFile = Join-Path $head "src/PSGraphRender/TemplateSets/$Backend/scripts/graph.js"
        [System.IO.File]::WriteAllText($graphFile,
            ([System.IO.File]::ReadAllText($graphFile)).Replace(
                'name.textContent = node.name || node.id;',
                'name.innerHTML = node.name || node.id;'))
        $r = Invoke-Suite -Clone $head -File 'tests/ForceGraph3DLook.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'builds the hover label as an ELEMENT'
        Assert-That -What 'P4: markup assignment in the label path turns SC3 RED' `
            -Ok ($null -ne $row -and $row.Result -eq 'Failed') `
            -Detail $(if ($row) { $row.Result } else { 'the assertion is not in the suite' })
        Restore-Head -Clone $head

        # P5. SC4's red demo. The vendored library removed from its slot, which
        # is the failure the page reports about itself rather than going blank.
        [System.IO.File]::WriteAllText($manifestFile,
            ([System.IO.File]::ReadAllText($manifestFile)).Replace(
                "VENDOR = @('vendor/3d-force-graph.min.js')", "VENDOR = @()"))
        Invoke-Build -Clone $head
        $r = Invoke-Suite -Clone $head -File 'tests/Vendor.Tests.ps1'
        $row = Get-Row -Rows $r -Match 'names every vendored file in the template set manifest'
        Assert-That -What 'P5: emptying the VENDOR slot turns the vendor gate RED' `
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
        Assert-That -What 'P6: the known-bad fixture form turns check 7 RED' -Ok ($hits.Count -gt 0) `
            -Detail ($hits -join '; ')
        Restore-Head -Clone $head
    }

    # ------------------------------------------------------------- summary
    ''
    if ($failures.Count -eq 0) {
        'VERIFY 0051: every check passed.'
    }
    else {
        "VERIFY 0051: $($failures.Count) failure(s)."
        foreach ($f in $failures) { "  - $f" }
    }
    ''
    exit $(if ($failures.Count -eq 0) { 0 } else { 1 })
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
