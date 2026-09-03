#Requires -Version 7.2
<#
.SYNOPSIS
    Re-derive every claim pass 0041 made, from a fresh clone, without reading
    the plan.
.DESCRIPTION
    Six checks, one per named spot-check in the prompt, run against a clone of
    this repository rather than against the working tree. That distinction is
    not ceremony: pass 0040's two line-ending defects passed in the working
    tree throughout and surfaced only from a clone.

    1. The README's presentation invariants: zero untagged code fences, four
       shields badges, and a hero that is a real PNG by its magic bytes.
    2. The Mermaid's layer colours against flow-graph.json's declared palette,
       by parsing both - never by reading either one's prose.
    3. PSGraphRenderToHtml at v0.1.1, cloned fresh, with the ColorBy
       falsification trio re-fired against a freshly built PSGraphRender
       v0.13.0. The baseline for the control is v0.1.0, which is the last tag
       BEFORE the fix - `origin/main` is no longer pre-fix and would compare
       the change against itself.
    4. Every link in every touched document, re-run cold.
    5. Every UX record parses to the four required headings, and the registry
       index and the files on disk name the same set.
    6. The plugin surface a consumer installs is untouched since v1.2.0:
       commands/ and .claude-plugin/ empty against the tag, and skills/
       changed in exactly one file.

    Checks 3 clones and builds two sibling repositories into a temporary
    directory. It needs network and a few minutes. -SkipEcosystem omits it and
    says so in the output rather than passing quietly.
.PARAMETER RepoRoot
    Used only to locate the repository's own remote URL, so the clone comes
    from the remote rather than from the tree being verified. Defaults to two
    levels above this script.
.PARAMETER SkipEcosystem
    Skip check 3, which clones and builds PSGraphRender and
    PSGraphRenderToHtml. The skip is reported, and a skipped check is not a
    passed one.
.EXAMPLE
    $params = @{
        RepoRoot = 'C:/src/AI.Agent.Claude.PowerShellModuleBuilder'
    }

    $verified = try {

        ./plans/0041-operator-ux/verify.ps1 @params
        $true

    }
    catch {
        Write-Error "Verification could not run: $_"
        $false
    }

    $verified
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [switch] $SkipEcosystem
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$origin = (& git -C $RepoRoot remote get-url origin).Trim()
$work = Join-Path ([IO.Path]::GetTempPath()) ("verify-0041-" + [guid]::NewGuid().ToString('n'))
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-That {
    param(
        [Parameter(Mandatory)] [string] $What,
        [Parameter(Mandatory)] [bool] $Ok,
        [string] $Detail = ''
    )
    "  [{0}] {1}{2}" -f $(if ($Ok) { 'ok  ' } else { 'FAIL' }), $What, $(if ($Detail) { " - $Detail" } else { '' })
    if (-not $Ok) { $script:failures.Add("$What$(if ($Detail) { " - $Detail" })") }
}

'VERIFY 0041 - operator experience and presentation'
"  origin: $origin"
"  work:   $work"
''

try {
    $null = New-Item -ItemType Directory -Path $work -Force
    $clone = Join-Path $work 'harness'
    & git clone --quiet --branch main $origin $clone
    if ($LASTEXITCODE -ne 0) { throw "Cloning '$origin' failed; nothing below can be verified from a tree this script did not fetch." }
    "cloned harness at $((& git -C $clone rev-parse --short HEAD).Trim())"
    ''

    $readmePath = Join-Path $clone 'README.md'
    $readme = Get-Content -LiteralPath $readmePath -Raw

    # -- 1 ------------------------------------------------------------------
    '1. README presentation invariants'

    $bare = @([regex]::Matches($readme, '(?m)^```\s*$'))
    Assert-That -What 'zero untagged code fences' -Ok ($bare.Count -eq 0) -Detail "$($bare.Count) bare ``` line(s)"

    # And the half a count cannot see: that every tagged opener still CLOSES.
    # A four-backtick closer is what makes the count above meaningful, and a
    # count alone would pass a file in which one of them was mistyped.
    $openers = @([regex]::Matches($readme, '(?m)^```[a-z]+\s*$'))
    $closers = @([regex]::Matches($readme, '(?m)^````\s*$'))
    Assert-That -What 'every tagged opener has a closing fence' -Ok ($openers.Count -eq $closers.Count) `
        -Detail "$($openers.Count) tagged opener(s), $($closers.Count) closer(s)"
    Assert-That -What 'the README has code blocks at all' -Ok ($openers.Count -ge 5) -Detail "$($openers.Count) found"

    $badges = @([regex]::Matches($readme, '!\[[^\]]*\]\((https://img\.shields\.io/[^)]+)\)'))
    Assert-That -What 'four shields.io badges' -Ok ($badges.Count -eq 4) -Detail "$($badges.Count) found"
    $flat = @($badges | Where-Object { $_.Groups[1].Value -match 'style=flat' })
    Assert-That -What 'every badge uses the same flat style' -Ok ($flat.Count -eq $badges.Count) `
        -Detail "$($flat.Count) of $($badges.Count)"

    $heroRef = $readme -match 'docs/media/flow\.png'
    Assert-That -What 'the README embeds the hero' -Ok $heroRef
    $hero = Join-Path $clone 'docs/media/flow.png'
    if (Test-Path -LiteralPath $hero) {
        # Magic bytes, not the extension. A text file named .png embeds and
        # renders as a broken image, which looks like a network problem.
        $bytes = [IO.File]::ReadAllBytes($hero) | Select-Object -First 8
        $png = @(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
        $isPng = -not (Compare-Object $bytes $png)
        Assert-That -What 'the hero is a real PNG by its magic bytes' -Ok $isPng `
            -Detail "$((Get-Item $hero).Length) bytes"
    }
    else {
        Assert-That -What 'the hero file exists' -Ok $false -Detail 'docs/media/flow.png is absent and Deviations records no fallback'
    }
    ''

    # -- 2 ------------------------------------------------------------------
    '2. Mermaid layer colours against the declared palette'
    $comparer = Join-Path $clone 'plans/0041-operator-ux/Compare-Mermaid.ps1'
    $out = & pwsh -NoProfile -File $comparer -RepoRoot $clone 2>&1
    $ok = $LASTEXITCODE -eq 0
    Assert-That -What 'Mermaid and JSON agree on nodes, edges, layers and the five colours' -Ok $ok
    $out | ForEach-Object { "      $_" }

    # Independently of that script, because a comparison and its subject in one
    # repository can agree about the wrong thing: parse both files here too.
    $palette = (Get-Content -LiteralPath (Join-Path $clone 'docs/diagram/flow-graph.json') -Raw |
        ConvertFrom-Json).graph.meta.layerPalette
    $declared = [ordered]@{}
    foreach ($property in $palette.PSObject.Properties) { $declared[$property.Name] = ([string]$property.Value).ToUpperInvariant() }
    $inMermaid = [ordered]@{}
    foreach ($m in [regex]::Matches($readme, '(?m)^\s*classDef\s+layer([A-Za-z]+)\s+fill:(#[0-9A-Fa-f]{6})')) {
        $inMermaid[$m.Groups[1].Value.ToLowerInvariant()] = $m.Groups[2].Value.ToUpperInvariant()
    }
    Assert-That -What 'five layers declared, five classDefs' -Ok ($declared.Count -eq 5 -and $inMermaid.Count -eq 5) `
        -Detail "palette $($declared.Count), classDef $($inMermaid.Count)"
    foreach ($layer in $declared.Keys) {
        $same = $inMermaid.Contains($layer) -and $inMermaid[$layer] -eq $declared[$layer]
        Assert-That -What "layer '$layer' is $($declared[$layer]) in both" -Ok $same `
            -Detail $(if ($inMermaid.Contains($layer)) { "mermaid $($inMermaid[$layer])" } else { 'no classDef' })
    }

    # And in the rendered document, which is the third statement of the palette.
    $flow = Get-Content -LiteralPath (Join-Path $clone 'docs/diagram/flow.html') -Raw
    foreach ($layer in $declared.Keys) {
        Assert-That -What "layer '$layer' colour reaches flow.html" -Ok ($flow -match [regex]::Escape($declared[$layer]))
    }
    Assert-That -What 'flow.html carries the tuned wheel zoom' -Ok ($flow -match '"ZoomSpeed"\s*:\s*0\.6')
    ''

    # -- 3 ------------------------------------------------------------------
    '3. PSGraphRenderToHtml v0.1.1 - the ColorBy falsification trio, re-fired'
    if ($SkipEcosystem) {
        '  SKIPPED by -SkipEcosystem. A skipped check is not a passed one.'
        $failures.Add('check 3 was skipped, so the ecosystem fix is unverified in this run')
    }
    else {
        $renderRepo = Join-Path $work 'PSGraphRender'
        $toHtmlRepo = Join-Path $work 'PSGraphRenderToHtml'
        & git clone --quiet https://github.com/JerryBalmer1/PSGraphRender.git $renderRepo
        & git -C $renderRepo checkout --quiet v0.13.0
        & git clone --quiet https://github.com/JerryBalmer1/PSGraphRenderToHtml.git $toHtmlRepo
        & git -C $toHtmlRepo checkout --quiet v0.1.1
        "  PSGraphRender       v0.13.0  $((& git -C $renderRepo rev-parse --short HEAD).Trim())"
        "  PSGraphRenderToHtml v0.1.1   $((& git -C $toHtmlRepo rev-parse --short HEAD).Trim())"

        # output/ is a build product in both repositories and is not committed,
        # so PSGraphRender has no importable psm1 until it is built.
        Push-Location $renderRepo
        try {
            $log = & pwsh -NoProfile -File ./build.ps1 -Task Build 2>&1
            if ($LASTEXITCODE -ne 0) { throw "Building PSGraphRender v0.13.0 failed:`n$($log -join "`n")" }
        }
        finally { Pop-Location }
        $env:PSGRAPHRENDER_MODULE_PATH = Join-Path $renderRepo 'output/PSGraphRender/PSGraphRender.psd1'

        # v0.1.0 is the last tag BEFORE the fix. origin/main is now past it and
        # would compare the change against itself.
        $trio = Join-Path $clone 'plans/0041-operator-ux/Invoke-ColorByFalsification.ps1'
        $out = & pwsh -NoProfile -File $trio -ToHtmlRoot $toHtmlRepo -BaselineRef v0.1.0 2>&1
        $ok = $LASTEXITCODE -eq 0
        Assert-That -What 'dropped value renders, retired values refuse naming both sides, control unchanged' -Ok $ok
        $out | ForEach-Object { "      $_" }
        Remove-Item Env:\PSGRAPHRENDER_MODULE_PATH -ErrorAction SilentlyContinue
    }
    ''

    # -- 4 ------------------------------------------------------------------
    '4. Every link in every touched document, cold'
    $links = & pwsh -NoProfile -File (Join-Path $clone 'plans/0041-operator-ux/Test-Links.ps1') -RepoRoot $clone 2>&1
    $ok = $LASTEXITCODE -eq 0
    Assert-That -What 'no dead links' -Ok $ok -Detail ($links | Select-Object -Last 1)
    if (-not $ok) { $links | ForEach-Object { "      $_" } }

    # The skills table specifically, because it is nineteen links added at once.
    $skillRows = @([regex]::Matches($readme, '\| \[`([a-z0-9-]+)`\]\(skills/([a-z0-9-]+)/SKILL\.md\) \|'))
    Assert-That -What 'every skills-table row links its own SKILL.md' `
        -Ok ($skillRows.Count -ge 19 -and -not (@($skillRows | Where-Object { $_.Groups[1].Value -ne $_.Groups[2].Value }).Count)) `
        -Detail "$($skillRows.Count) rows"
    ''

    # -- 5 ------------------------------------------------------------------
    '5. UX records: shape, and the index against the files'
    $uxDir = Join-Path $clone 'docs/ux'
    $records = @(Get-ChildItem -LiteralPath $uxDir -Filter 'UX-*.md' | Sort-Object Name)
    Assert-That -What 'at least six UX records' -Ok ($records.Count -ge 6) -Detail "$($records.Count) found"
    foreach ($record in $records) {
        $body = Get-Content -LiteralPath $record.FullName -Raw
        $missing = @('## Problem', '## Why', '## What it solves', '## Evidence') |
            Where-Object { $body -notmatch ('(?m)^' + [regex]::Escape($_) + '\s*$') }
        Assert-That -What "$($record.Name) has all four headings" -Ok (-not $missing) -Detail ($missing -join ', ')
    }
    $index = Get-Content -LiteralPath (Join-Path $uxDir 'README.md') -Raw
    $listed = @([regex]::Matches($index, '\]\((UX-[^)]+\.md)\)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $present = @($records | ForEach-Object { $_.Name } | Sort-Object -Unique)
    Assert-That -What 'the registry index names exactly the files present' `
        -Ok (-not (Compare-Object $listed $present)) `
        -Detail "index $($listed.Count), on disk $($present.Count)"
    ''

    # -- 6 ------------------------------------------------------------------
    '6. The installable surface is untouched since v1.2.0'
    foreach ($path in 'commands', '.claude-plugin') {
        $diff = & git -C $clone diff --name-only v1.2.0..HEAD -- $path
        Assert-That -What "$path/ unchanged since v1.2.0" -Ok (-not $diff) -Detail ($diff -join ', ')
    }
    $skillsDiff = @(& git -C $clone diff --name-only v1.2.0..HEAD -- skills)
    Assert-That -What 'skills/ changed in exactly one file' -Ok ($skillsDiff.Count -eq 1) -Detail ($skillsDiff -join ', ')
    Assert-That -What 'and that file is powershell-module-ux' `
        -Ok ($skillsDiff.Count -eq 1 -and $skillsDiff[0] -eq 'skills/powershell-module-ux/SKILL.md') `
        -Detail ($skillsDiff -join ', ')
    $manifest = Get-Content -LiteralPath (Join-Path $clone '.claude-plugin/plugin.json') -Raw | ConvertFrom-Json
    Assert-That -What 'the plugin manifest still reads 1.2.0 - no harness release' -Ok ($manifest.version -eq '1.2.0') `
        -Detail $manifest.version
    ''
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failures.Count) {
    "VERIFY 0041: $($failures.Count) CHECK(S) DISAGREED"
    $failures | ForEach-Object { "  $_" }
    exit 1
}
'VERIFY 0041: every check agrees'
exit 0
