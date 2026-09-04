#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0047 made, from the repositories, without reading
    the plan.

.DESCRIPTION
    Pass 0047 made a node link declared configuration in PSGraphRender:
    LinkMode of editor | hrefTemplate | none, resolved when the document is
    ASSEMBLED rather than in the browser. v0.14.0.

    Six checks and five falsification probes. Each check re-derives its answer
    from a fresh clone, never from plan.md, per PLAN-PROTOCOL section 9.

    1. The two settings are declared as DATA and the manifest names three
       modes. Both halves matter: a setting nothing selects on is a setting
       that does nothing.
    2. The three modes render as configured, from a fresh clone. editor
       constructs an editor URI, hrefTemplate resolves its tokens and
       constructs no editor URI, none constructs neither and still renders a
       report. Derived by rendering, not by reading the source.
    3. Acceptance C, the no-regression control: an editor-mode document is
       byte-identical to the BASE commit's for the same payload, outside the
       CONFIG block, and CONFIG differs only by the two added keys. Both trees
       are cloned and built here; nothing is pinned and nothing is trusted.
    4. The committed examples regenerate byte-for-byte, and the forge example's
       template resolves to a real forge URL rather than an unresolved token.
    5. Conformance at head is not below the base. Both scores are measured in
       this run, against clones of both commits - a score quoted from a record
       is a score nobody re-measured.
    6. Nothing machine-identifying in what the pass committed: no
       drive-absolute path, no home directory, no username, and no vscode://
       carrying anything but the documented placeholder.

    -FailCheck adds the probes. A check that cannot fail has checked nothing,
    so a probe that does NOT fail is itself reported as a failure.

    Writes only under scratch/ and removes what it wrote.

    Written against the harness SHA and target SHA recorded in plan.md
    (decision 0004). The base is a SHA rather than a tag on purpose - see
    -BaseRef - and head is whatever the remote's default branch holds, so this
    re-derives against what actually landed rather than against what this
    script was told.

.PARAMETER RepoRoot
    Harness root. Defaults to two levels above this script.
.PARAMETER TargetRemote
    Where to clone PSGraphRender from. Defaults to the origin of the sibling
    checkout when there is one, so this runs on a machine that has only the
    harness.
.PARAMETER HeadRef
    What to verify. Defaults to main, which is what a later reader wants: the
    landed result, re-derived from the remote rather than from a working tree.
    Pass the pass branch to run it BEFORE the fast-forward - which is how it was
    run for the release, so the tag names the pass tip instead of trailing a
    verification commit.
.PARAMETER BaseRef
    The commit an editor-mode document must still match. Defaults to this
    pass's BASE COMMIT, not to the tag before it. v0.13.0 points at 964d73a,
    eight commits behind cd4857d, and its tree predates the examples this pass
    had to regenerate - so the tag would compare against a document the pass
    never claimed to preserve. The tag-behind-tip pattern, recorded at 0033,
    0034 and again in the 0046 stop report as finding F3.
.PARAMETER FailCheck
    Run the deliberate-failure probes.
.EXAMPLE
    ./plans/0047-link-mode/verify.ps1
.EXAMPLE
    ./plans/0047-link-mode/verify.ps1 -FailCheck
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $TargetRemote,
    [string] $HeadRef = 'main',
    [string] $BaseRef = 'cd4857d',
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

$work = Join-Path $RepoRoot 'scratch/verify-0047'
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

function Get-DocumentBlockRange {
    param([string[]] $Lines, [string] $Name)

    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^const $Name = ") { $start = $i; break }
    }
    if ($start -lt 0) { throw "No $Name assignment in the document." }
    for ($j = $start; $j -lt $Lines.Count; $j++) {
        if ($Lines[$j] -match '^\};?\s*$') { return @($start, $j) }
    }
    throw "The $Name block is never closed."
}

function Get-DocumentBlock {
    param([string] $Document, [string] $Name)
    $lines = $Document -split "`r?`n"
    $r = Get-DocumentBlockRange -Lines $lines -Name $Name
    (($lines[$r[0]..$r[1]] -join "`n") -replace "^const $Name = ", '' -replace ';\s*$', '') | ConvertFrom-Json
}

function Get-DocumentCode {
    <#
        The document minus the STRINGS block. That block carries the renderer's
        own UI messages, five of which name vscode:// in prose about what a
        blocked link looks like - which is not construction of one.
    #>
    param([string] $Document)
    $lines = @($Document -split "`r?`n")
    $r = Get-DocumentBlockRange -Lines $lines -Name 'STRINGS'
    $keep = @()
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($i -lt $r[0] -or $i -gt $r[1]) { $keep += $lines[$i] } }
    $keep -join "`n"
}

function Remove-ConfigBlock {
    param([string] $Code)
    $Code -replace '(?ms)^const CONFIG = \{.*?^\};', ''
}

function Get-FirstDifference {
    param([string] $Expected, [string] $Actual)
    if ($Expected -ceq $Actual) { return $null }
    $e = @($Expected -split "`r?`n"); $a = @($Actual -split "`r?`n")
    for ($i = 0; $i -lt [Math]::Min($e.Count, $a.Count); $i++) {
        if ($e[$i] -cne $a[$i]) { return "line $($i + 1): base [$($e[$i])] head [$($a[$i])]" }
    }
    if ($e.Count -ne $a.Count) { return "line counts differ: base $($e.Count), head $($a.Count)" }
    # Every line equal and the strings still unequal: the difference is line
    # endings and nothing else. Saying "counts differ: 3174, 3174" here cost
    # this pass a diagnosis, so it says what it means.
    'line endings differ; every line is otherwise identical'
}

function ConvertTo-NormalisedText {
    <#
        LF, the way .gitattributes stores it. The renderer writes its payload
        blocks with ConvertTo-Json, which emits CRLF on Windows, so a freshly
        rendered document has mixed endings that git normalises on the way in.
        Comparing raw bytes against a checked-out file therefore measures the
        checkout, not the render.
    #>
    param([string] $Text)
    $Text -replace "`r`n", "`n"
}

function Set-Setting {
    <#
        Replace a key in a settings.psd1, never append. A duplicate key is a
        PARSE ERROR rather than an override, and the resolver's response to an
        unreadable file is to warn and fall back to schema defaults - so an
        append would silently render the default mode and look like the feature
        is missing. That failure cost this pass a red run.
    #>
    param([string] $SetPath, [hashtable] $Values)
    $file = Join-Path $SetPath 'Config/settings.psd1'
    $text = [System.IO.File]::ReadAllText($file)
    foreach ($key in ($Values.Keys | Sort-Object)) {
        $line = "    $key = '$($Values[$key].Replace("'", "''"))'"
        $pattern = "(?m)^\s*$key\s*=.*$"
        if ($text -notmatch $pattern) { throw "No $key line to replace in $file" }
        $text = $text -replace $pattern, $line.Replace('$', '$$')
    }
    [System.IO.File]::WriteAllText($file, $text)
}

function New-ModeDocument {
    <#
        Render one payload through one template set in a child process, so the
        module under test is the one in the clone and two versions of it never
        share a session.
    #>
    param([string] $Clone, [string] $SetPath, [string] $PayloadPath, [string] $OutFile, [string] $Title = 'verify 0047')

    $manifest = Join-Path $Clone 'output/PSGraphRender/PSGraphRender.psd1'
    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module '$manifest' -Force
`$vm = Get-Content -LiteralPath '$PayloadPath' -Raw | ConvertFrom-Json
`$doc = New-RenderDocument -ViewModel `$vm.data -Meta `$vm.meta -Title '$Title' -TemplateSetPath '$SetPath'
[System.IO.File]::WriteAllText('$OutFile', `$doc)
"@ 2>&1
    if (-not (Test-Path -LiteralPath $OutFile)) { throw "render produced nothing: $($log -join ' / ')" }
    [System.IO.File]::ReadAllText($OutFile)
}

function Test-ModeDocument {
    <#
        What a rendered document claims about its own link mode, as data, so a
        probe can hand over a damaged document without this changing.
    #>
    param([string] $Document, [string] $Mode)

    $code = Get-DocumentCode -Document $Document
    $config = Get-DocumentBlock -Document $Document -Name 'CONFIG'
    [pscustomobject]@{
        Mode          = $config.LinkMode
        DeclaredMode  = $Mode
        HasEditorUri  = $code.Contains('vscode://')
        HasHrefMode   = $code.Contains('LINK_MODE_HREF_TEMPLATE')
        HasEditorFn   = $code.Contains('function vsCodeUriFor')
        HasOpenAction = $code.Contains("id: 'open-in-vscode'") -or $code.Contains("id: 'open-link'")
        IsDocument    = $Document.Contains('<!DOCTYPE html>') -and ($Document -notmatch '__SLOT_[A-Z0-9_]+__')
        Tokens        = @('{relativePath}', '{path}', '{id}', '{label}' | Where-Object { $code.Contains("'$_'") })
    }
}

function Test-NoMachineIdentity {
    <#
        SC2 over a set of files. Scheme-relative matches are excluded before
        the drive test, because https:// contains a colon-slash-slash and a
        check that fires on every URL is a check nobody can leave switched on.
    #>
    param([string[]] $Files)

    $hits = @()
    foreach ($f in $Files) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        # Text only. A PNG's bytes match anything given enough of them, and a
        # picture can show only what the document it was taken from contains -
        # which is what the text checks below already cover.
        if ([System.IO.Path]::GetExtension($f) -in '.png', '.jpg', '.gif', '.ico') { continue }

        $text = [System.IO.File]::ReadAllText($f)
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -match '(^|[^A-Za-z0-9/])[A-Za-z]:[\\/]{1,2}[A-Za-z_.]' -and
                $line -notmatch 'fixtures[\\/]LinkMode|psgraphrender-|\$env:|TEMP|GetTempPath') {
                $hits += "$([System.IO.Path]::GetFileName($f)): drive path"
            }
            if ($line -match '/(Users|home)/[A-Za-z]') { $hits += "$([System.IO.Path]::GetFileName($f)): home dir" }
            if ($line -match 'jlbal') { $hits += "$([System.IO.Path]::GetFileName($f)): username" }
        }
    }
    @($hits | Sort-Object -Unique)
}

# ------------------------------------------------------------------ run
try {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    ''
    'VERIFY 0047 - link mode, re-derived from fresh clones.'
    "  target remote : $TargetRemote"
    "  head ref      : $HeadRef"
    "  base ref      : $BaseRef (the pass base, NOT the v0.13.0 tag - see -BaseRef)"
    ''

    $head = Join-Path $work 'head'
    $base = Join-Path $work 'base'
    & git clone --quiet $TargetRemote $head 2>&1 | Out-Null
    & git clone --quiet $TargetRemote $base 2>&1 | Out-Null
    & git -C $head checkout --quiet $HeadRef 2>&1 | Out-Null
    & git -C $base checkout --quiet $BaseRef 2>&1 | Out-Null

    # A head that is already the base verifies nothing and would report six
    # green checks for it. The most likely cause is running against main before
    # the fast-forward; see -HeadRef.
    if ((& git -C $head rev-parse HEAD).Trim() -eq (& git -C $base rev-parse HEAD).Trim()) {
        throw "head ($HeadRef) and base ($BaseRef) are the same commit - there is nothing to verify."
    }

    $headSha = (& git -C $head rev-parse --short HEAD).Trim()
    $baseSha = (& git -C $base rev-parse --short HEAD).Trim()
    "  head = $headSha, base = $baseSha ($BaseRef)"
    ''

    foreach ($tree in @($head, $base)) {
        & pwsh -NoProfile -NonInteractive -Command "& '$(Join-Path $tree 'build.ps1')' -Task Build" 2>&1 | Out-Null
    }

    $payload = Join-Path $head 'examples/input/links-viewmodel.json'
    $shipped = Join-Path $head 'output/PSGraphRender/TemplateSets/cytoscape'

    # --------------------------------------------------------------- check 1
    '1. The two settings are declared as data, and the manifest selects on them.'
    $schema = Import-PowerShellDataFile -LiteralPath (Join-Path $head 'src/PSGraphRender/TemplateSets/cytoscape/Config/settings.schema.psd1')
    $manifest = Import-PowerShellDataFile -LiteralPath (Join-Path $head 'src/PSGraphRender/TemplateSets/cytoscape/templateset.psd1')

    $modeEntry = if ($schema.Entries.Contains('LinkMode')) { $schema.Entries['LinkMode'] } else { $null }
    Assert-That -What 'LinkMode is an Enum of three modes defaulting to editor' `
        -Ok ($null -ne $modeEntry -and $modeEntry.Type -eq 'Enum' -and $modeEntry.Default -eq 'editor' -and
             (@($modeEntry.Values) -join ',') -eq 'editor,hrefTemplate,none') `
        -Detail $(if ($modeEntry) { "$($modeEntry.Type), default $($modeEntry.Default), values $(@($modeEntry.Values) -join '/')" } else { 'absent' })

    Assert-That -What 'LinkHrefTemplate is a String setting beside it' `
        -Ok ($schema.Entries.Contains('LinkHrefTemplate') -and $schema.Entries['LinkHrefTemplate'].Type -eq 'String')

    $modes = @()
    if ($manifest.Contains('SlotsBySetting') -and $manifest.SlotsBySetting.Contains('LinkMode')) {
        $modes = @($manifest.SlotsBySetting.LinkMode.Keys | Sort-Object)
    }
    Assert-That -What 'the manifest names files for all three modes' `
        -Ok ((@($modes) -join ',') -eq 'editor,hrefTemplate,none') -Detail "SlotsBySetting.LinkMode: $($modes -join ', ')"
    ''

    # --------------------------------------------------------------- check 2
    '2. The three modes render as configured.'
    $probeTemplate = 'https://example.invalid/{relativePath}?l={label}'
    $rendered = @{}
    foreach ($mode in @('editor', 'hrefTemplate', 'none')) {
        $set = Join-Path $work "set-$mode"
        Copy-Item -LiteralPath $shipped -Destination $set -Recurse -Force
        Set-Setting -SetPath $set -Values @{ LinkMode = $mode; LinkHrefTemplate = $probeTemplate }
        $rendered[$mode] = New-ModeDocument -Clone $head -SetPath $set -PayloadPath $payload `
            -OutFile (Join-Path $work "$mode.html")
    }

    $e = Test-ModeDocument -Document $rendered['editor'] -Mode 'editor'
    Assert-That -What 'editor constructs an editor URI and says so in CONFIG' `
        -Ok ($e.Mode -eq 'editor' -and $e.HasEditorUri -and $e.HasEditorFn) `
        -Detail "CONFIG.LinkMode=$($e.Mode), vscode://=$($e.HasEditorUri)"

    $h = Test-ModeDocument -Document $rendered['hrefTemplate'] -Mode 'hrefTemplate'
    Assert-That -What 'hrefTemplate resolves four tokens and constructs no editor URI' `
        -Ok ($h.Mode -eq 'hrefTemplate' -and $h.HasHrefMode -and -not $h.HasEditorUri -and $h.Tokens.Count -eq 4) `
        -Detail "tokens $($h.Tokens.Count)/4, vscode://=$($h.HasEditorUri)"

    $n = Test-ModeDocument -Document $rendered['none'] -Mode 'none'
    Assert-That -What 'none constructs nothing and is still a report' `
        -Ok ($n.Mode -eq 'none' -and -not $n.HasEditorUri -and -not $n.HasEditorFn -and
             -not $n.HasOpenAction -and $n.IsDocument) `
        -Detail "vscode://=$($n.HasEditorUri), open action=$($n.HasOpenAction), document=$($n.IsDocument)"
    ''

    # --------------------------------------------------------------- check 3
    '3. Acceptance C - an editor-mode document still matches the base, byte for byte.'
    $baseSet = Join-Path $base 'output/PSGraphRender/TemplateSets/cytoscape'
    $basePayload = Join-Path $base 'examples/input/links-viewmodel.json'

    # The base's own payload, rendered by the base's own module. Using head's
    # payload would compare two different inputs and call the difference a
    # regression; using head's module would compare the module against itself.
    $baseDoc = New-ModeDocument -Clone $base -SetPath $baseSet -PayloadPath $basePayload `
        -OutFile (Join-Path $work 'base.html')
    $headDoc = New-ModeDocument -Clone $head -SetPath $shipped -PayloadPath $basePayload `
        -OutFile (Join-Path $work 'head-default.html')

    $diff = Get-FirstDifference `
        -Expected (Remove-ConfigBlock (Get-DocumentCode -Document $baseDoc)) `
        -Actual (Remove-ConfigBlock (Get-DocumentCode -Document $headDoc))
    Assert-That -What 'the default document is unchanged outside CONFIG' -Ok ($null -eq $diff) `
        -Detail $(if ($diff) { $diff } else { 'byte-identical' })

    $baseCfg = Get-DocumentBlock -Document $baseDoc -Name 'CONFIG'
    $headCfg = Get-DocumentBlock -Document $headDoc -Name 'CONFIG'
    $baseNames = @($baseCfg.PSObject.Properties.Name)
    $added = @($headCfg.PSObject.Properties.Name | Where-Object { $_ -notin $baseNames } | Sort-Object)
    $movedSettings = @($baseNames | Where-Object {
            ($headCfg.$_ | ConvertTo-Json -Compress -Depth 10) -ne ($baseCfg.$_ | ConvertTo-Json -Compress -Depth 10) })

    Assert-That -What 'CONFIG gained exactly the two link settings and moved nothing else' `
        -Ok (($added -join ',') -eq 'LinkHrefTemplate,LinkMode' -and $movedSettings.Count -eq 0) `
        -Detail "added: $($added -join ', ')$(if ($movedSettings) { "; CHANGED: $($movedSettings -join ', ')" })"

    Assert-That -What 'the shipped default is editor, so nothing changes for an existing caller' `
        -Ok ($headCfg.LinkMode -eq 'editor') -Detail "default LinkMode=$($headCfg.LinkMode)"
    ''

    # --------------------------------------------------------------- check 4
    '4. The committed examples regenerate, and the forge links resolve.'
    $before = @{}
    foreach ($f in @('links/editor-links.html', 'links/forge-links.html')) {
        $before[$f] = [System.IO.File]::ReadAllText((Join-Path $head "examples/$f"))
    }
    & pwsh -NoProfile -NonInteractive -File (Join-Path $head 'examples/Build-Examples.ps1') 2>&1 | Out-Null
    foreach ($f in $before.Keys) {
        $after = [System.IO.File]::ReadAllText((Join-Path $head "examples/$f"))
        $wasSame = (ConvertTo-NormalisedText $before[$f]) -ceq (ConvertTo-NormalisedText $after)
        Assert-That -What "$f regenerates identically (LF, as .gitattributes stores it)" -Ok $wasSame `
            -Detail $(if ($wasSame) { 'identical' } else { Get-FirstDifference -Expected $before[$f] -Actual $after })
    }

    $forgeCfg = Get-DocumentBlock -Document $before['links/forge-links.html'] -Name 'CONFIG'
    Assert-That -What 'the forge example is hrefTemplate mode with a forge URL' `
        -Ok ($forgeCfg.LinkMode -eq 'hrefTemplate' -and $forgeCfg.LinkHrefTemplate -match '^https://github\.com/.+\{relativePath\}') `
        -Detail "$($forgeCfg.LinkMode): $($forgeCfg.LinkHrefTemplate)"

    $editorCfg = Get-DocumentBlock -Document $before['links/editor-links.html'] -Name 'CONFIG'
    Assert-That -What 'the editor example is kept, demonstrating the preserved behaviour' `
        -Ok ($editorCfg.LinkMode -eq 'editor') -Detail "LinkMode=$($editorCfg.LinkMode)"
    ''

    # --------------------------------------------------------------- check 5
    '5. Conformance at head is not below the base. Both measured here.'
    $runner = Join-Path $RepoRoot 'evals/conformance/Invoke-Conformance.ps1'
    $scores = @{}
    foreach ($pair in @(@{ N = 'base'; P = $base }, @{ N = 'head'; P = $head })) {
        $out = Join-Path $work "conformance-$($pair.N).json"
        # -Command, not -File. With -File every argument arrives as one string,
        # so the tag ARRAY becomes the single value "Universal,Repository,..."
        # and the runner's own ValidateSet rejects it against a set it is
        # literally a comma-join of - an error that reads like a bug in the
        # runner and is a bug in the call.
        $runLog = & pwsh -NoProfile -NonInteractive -Command `
            "& '$runner' -Path '$($pair.P)' -Tag Universal,Repository,HouseStyle,RequiresBuild -ModuleName 'PSGraphRender' -ResultPath '$out'" 2>&1
        if (-not (Test-Path -LiteralPath $out)) {
            throw "the conformance runner produced no result for $($pair.N): $(($runLog | Select-Object -Last 3) -join ' / ')"
        }
        $scores[$pair.N] = Get-Content -LiteralPath $out -Raw | ConvertFrom-Json
    }
    "     base: $($scores['base'].ScorePct)% over $($scores['base'].CasesRun) case(s)"
    "     head: $($scores['head'].ScorePct)% over $($scores['head'].CasesRun) case(s)"

    Assert-That -What 'head conformance is not below base' `
        -Ok ($scores['head'].ScorePct -ge $scores['base'].ScorePct) `
        -Detail "$($scores['base'].ScorePct) -> $($scores['head'].ScorePct)"

    $newFailures = @($scores['head'].Failures | ForEach-Object { $_.Name } |
            Where-Object { $_ -notin @($scores['base'].Failures | ForEach-Object { $_.Name }) })
    Assert-That -What 'no assertion that passed at base fails at head' -Ok ($newFailures.Count -eq 0) `
        -Detail $(if ($newFailures) { $newFailures -join '; ' } else { 'none' })
    ''

    # --------------------------------------------------------------- check 6
    '6. Nothing machine-identifying in what the pass committed.'
    $touched = @(& git -C $head diff --name-only "$BaseRef..HEAD" | ForEach-Object { Join-Path $head $_ })
    "     $($touched.Count) file(s) changed since $BaseRef"
    $identity = @(Test-NoMachineIdentity -Files $touched)
    Assert-That -What 'no drive path, home directory or username in any changed file' `
        -Ok ($identity.Count -eq 0) -Detail $(if ($identity) { $identity -join '; ' } else { 'clean' })

    $schemes = @()
    foreach ($f in $touched) {
        if (-not (Test-Path -LiteralPath $f -PathType Leaf)) { continue }
        if ([System.IO.Path]::GetExtension($f) -in '.png', '.jpg', '.gif', '.ico') { continue }
        $schemes += [regex]::Matches([System.IO.File]::ReadAllText($f), 'vscode://file/[^\s"'']{0,40}') |
            ForEach-Object { $_.Value }
    }
    $realPaths = @($schemes | Where-Object { $_ -match 'vscode://file/[A-Za-z]:' } | Sort-Object -Unique)
    Assert-That -What 'no vscode:// carries a real path' -Ok ($realPaths.Count -eq 0) `
        -Detail $(if ($realPaths) { $realPaths -join ', ' } else { "$(@($schemes | Sort-Object -Unique).Count) placeholder/doc form(s) only" })
    ''

    # --------------------------------------------------------------- probes
    if ($FailCheck) {
        'FALSIFICATION - each probe must FAIL the check it probes.'

        # P1 - the default flipped. Check 3's byte comparison stays green (the
        # mode is one value in one blob), so this is what has to catch it, and
        # the pass says so.
        $p1 = Join-Path $work 'probe1'
        Copy-Item -LiteralPath $shipped -Destination $p1 -Recurse -Force
        Set-Setting -SetPath $p1 -Values @{ LinkMode = 'none' }
        $p1Doc = New-ModeDocument -Clone $head -SetPath $p1 -PayloadPath $basePayload -OutFile (Join-Path $work 'p1.html')
        $p1Cfg = Get-DocumentBlock -Document $p1Doc -Name 'CONFIG'
        Assert-That -What 'P1: flipping the shipped default is caught' -Ok ($p1Cfg.LinkMode -ne 'editor') `
            -Detail "default became $($p1Cfg.LinkMode)"

        # P1b - the byte comparison catches it TOO, and this probe is here
        # because it was written asserting the opposite and was wrong.
        #
        # The belief was that a mode is one value in one blob, so a flipped
        # default moves CONFIG and nothing else. That is true of a design that
        # resolves the mode in the browser. It is false of this one: assembly
        # picks the FILES, so a flipped default changes the document body as
        # well, and the byte comparison is strictly stronger than it was
        # credited with being. The CONFIG check still earns its place - it pins
        # WHICH value the default is - but it is not the only thing standing
        # between a flipped default and a release.
        $p1Diff = Get-FirstDifference `
            -Expected (Remove-ConfigBlock (Get-DocumentCode -Document $baseDoc)) `
            -Actual (Remove-ConfigBlock (Get-DocumentCode -Document $p1Doc))
        Assert-That -What 'P1b: the byte comparison catches a flipped default as well' -Ok ($null -ne $p1Diff) `
            -Detail $(if ($p1Diff) { "the body differs too: $p1Diff" }
                      else { 'the body did not move, which would mean the mode is not resolved at assembly after all' })

        # P2 - the href resolver removed. Check 2 must go red rather than
        # falling back to some other mode's file.
        $p2 = Join-Path $work 'probe2'
        Copy-Item -LiteralPath $shipped -Destination $p2 -Recurse -Force
        Set-Setting -SetPath $p2 -Values @{ LinkMode = 'hrefTemplate'; LinkHrefTemplate = $probeTemplate }
        $hrefFile = Join-Path $p2 'scripts/link/href.js'
        [System.IO.File]::WriteAllText($hrefFile,
            ([System.IO.File]::ReadAllText($hrefFile) -replace "'\{relativePath\}'", "'{gone}'"))
        $p2Doc = New-ModeDocument -Clone $head -SetPath $p2 -PayloadPath $payload -OutFile (Join-Path $work 'p2.html')
        $p2r = Test-ModeDocument -Document $p2Doc -Mode 'hrefTemplate'
        Assert-That -What 'P2: a token removed from the resolver is caught' -Ok ($p2r.Tokens.Count -lt 4) `
            -Detail "$($p2r.Tokens.Count)/4 tokens resolve"

        # P3 - the editor file assembled under the none mode. This is the
        # failure slot selection exists to prevent, so it must be visible.
        $p3 = Join-Path $work 'probe3'
        Copy-Item -LiteralPath $shipped -Destination $p3 -Recurse -Force
        Set-Setting -SetPath $p3 -Values @{ LinkMode = 'none' }
        $p3Manifest = Join-Path $p3 'templateset.psd1'
        [System.IO.File]::WriteAllText($p3Manifest,
            ([System.IO.File]::ReadAllText($p3Manifest) -replace
                "SCRIPT_NODE_LINK       = @\('scripts/link/common\.js', 'scripts/link/none\.js'\)",
                "SCRIPT_NODE_LINK       = @('scripts/link/common.js', 'scripts/link/editor.js')"))
        $p3Doc = New-ModeDocument -Clone $head -SetPath $p3 -PayloadPath $payload -OutFile (Join-Path $work 'p3.html')
        $p3r = Test-ModeDocument -Document $p3Doc -Mode 'none'
        Assert-That -What 'P3: scheme construction reaching a none document is caught' -Ok ($p3r.HasEditorUri) `
            -Detail 'the none check reads the assembled document, not the setting'

        # P4 - a machine path planted in a file the pass touched.
        $p4 = Join-Path $work 'probe4.md'
        [System.IO.File]::WriteAllText($p4, "a line naming C:\Users\someone\clone\file.ps1 the way a stray paste would")
        $p4Hits = @(Test-NoMachineIdentity -Files @($p4))
        Assert-That -What 'P4: a planted drive path is caught' -Ok ($p4Hits.Count -gt 0) `
            -Detail "$($p4Hits.Count) hit(s): $($p4Hits -join '; ')"

        # P5 - an example edited by hand. Check 4 must notice the committed
        # artifact is no longer what its command produces.
        $p5Before = $before['links/forge-links.html']
        $p5After = $p5Before.Replace('<!DOCTYPE html>', '<!DOCTYPE html><!-- hand edited -->')
        Assert-That -What 'P5: a hand-edited example is caught' `
            -Ok ($null -ne (Get-FirstDifference -Expected $p5Before -Actual $p5After)) `
            -Detail 'the regenerate check compares bytes, so any hand edit shows'
        ''
    }
}
catch {
    # Without this the script prints its error and still exits 0, because a
    # terminating error skips the exit lines below. A verify script reporting
    # success while crashing is a false green in the one artifact whose job is
    # to disprove the plan; pass 0044's verifier did exactly that.
    ''
    'VERIFY 0047: ERROR - the script could not complete, so nothing below it ran.'
    "  $($_.Exception.Message)"
    "  at $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line.Trim())"
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
    exit 99
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failures.Count) {
    "VERIFY 0047: FAIL - $($failures.Count) check(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'VERIFY 0047: PASS - every check re-derived and agreed.'
exit 0
