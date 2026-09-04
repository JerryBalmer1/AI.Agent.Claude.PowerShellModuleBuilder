#requires -Version 7.0
<#
.SYNOPSIS
    Verify pass 0043 - ecosystem examples showcase.
.DESCRIPTION
    SHA-pinned per decision 0004. This script verifies ONE pass, which
    described ONE set of changes, which landed at ONE commit per repository.
    Run against a later HEAD it is not verifying anything - it is comparing a
    past claim against a present repository - so it reports the drift and
    stops rather than editing its own pins.

    Writes nothing outside scratch/.
.PARAMETER WorkspaceRoot
    Directory holding the five repositories. Defaults to the workspace this
    harness lives in.
.PARAMETER FailCheck
    Prove the script can go red. Copies one repository's examples/ into
    scratch/, deletes a single artifact from the copy, and re-runs the artifact
    checks against it. A verification that has never been seen to fail is not
    evidence of anything.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $WorkspaceRoot,

    [Parameter()]
    [switch] $FailCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$harnessRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $WorkspaceRoot) { $WorkspaceRoot = Split-Path -Parent $harnessRoot }
$scratch = Join-Path $harnessRoot 'scratch/verify-0043'

# ---------------------------------------------------------------------------
# The pins. What this pass pushed, per decision 0004.
# ---------------------------------------------------------------------------
$Pinned = [ordered]@{
    'PSGraphRender'       = 'c7f382fd7603aa90d715ba66a6796e0724877c49'
    'PSGraphRenderToHtml' = '55deb2896a85aa9c7ae7e9afbbf2e93011b2342d'
    'PSAzureDevOpsGraph'  = '5551a20efeece2f1e39d7ab9335ad16b6164e135'
    'PSTerraformGraph'    = '0db7f1a7258b3fe56158b5fc6f3eb537f272d430'
}
$PinnedTag = 'v0.4.0'
$PinnedLastLanded = '0043'

$Artifacts = [ordered]@{
    'PSGraphRender'       = @(
        'examples/input/ecosystem-viewmodel.json', 'examples/input/links-viewmodel.json',
        'examples/input/theme-contrast.psd1',
        'examples/layouts/foundation.html', 'examples/layouts/foundation.png',
        'examples/layouts/testorder.html', 'examples/layouts/testorder.png',
        'examples/layouts/callflow.html', 'examples/layouts/callflow.png',
        'examples/theme/default.html', 'examples/theme/default.png',
        'examples/theme/contrast.html', 'examples/theme/contrast.png',
        'examples/links/editor-links.html', 'examples/links/editor-links.png',
        'examples/README.md'
    )
    'PSGraphRenderToHtml' = @(
        'examples/input/nested-graph.json', 'examples/input/precedence-graph.json',
        'examples/precedence/graphrender.defaults.psd1',
        'examples/nesting/nested.html', 'examples/nesting/nested.png',
        'examples/precedence/builtins.html', 'examples/precedence/builtins.png',
        'examples/precedence/file-defaults.html', 'examples/precedence/file-defaults.png',
        'examples/precedence/explicit.html', 'examples/precedence/explicit.png',
        'examples/README.md'
    )
    'PSAzureDevOpsGraph'  = @(
        'examples/input/claudetesting-graph.json',
        'examples/claudetesting.html', 'examples/claudetesting.png',
        'examples/README.md', 'docs/worklog/v0.4.0.md'
    )
    'PSTerraformGraph'    = @(
        'examples/input/claudetestingterraform-graph.json',
        'examples/claudetestingterraform.html', 'examples/claudetestingterraform.png',
        'examples/README.md'
    )
}

$Heroes = @{
    'PSGraphRender'       = 'examples/layouts/foundation.png'
    'PSGraphRenderToHtml' = 'examples/nesting/nested.png'
    'PSAzureDevOpsGraph'  = 'examples/claudetesting.png'
    'PSTerraformGraph'    = 'examples/claudetestingterraform.png'
}

$pass = 0
$fail = 0
function Assert-True([string] $Label, [bool] $Condition, [string] $Detail = '') {
    if ($Condition) {
        $script:pass++
        Write-Host ("  PASS  {0}" -f $Label) -ForegroundColor Green
    }
    else {
        $script:fail++
        Write-Host ("  FAIL  {0}" -f $Label) -ForegroundColor Red
        if ($Detail) { Write-Host ("        {0}" -f $Detail) -ForegroundColor DarkGray }
    }
}

function Test-ArtifactsUnder {
    <#
        The artifact existence checks, factored so -FailCheck can point them at
        a deliberately damaged copy.
    #>
    param([string] $Root, [string[]] $Relative, [string] $Label)

    $missing = @()
    $empty = @()
    foreach ($rel in $Relative) {
        $full = Join-Path $Root $rel
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { $missing += $rel; continue }
        if ((Get-Item -LiteralPath $full).Length -eq 0) { $empty += $rel }
    }
    Assert-True "$Label - all $($Relative.Count) artifacts present and non-empty" `
        (($missing.Count -eq 0) -and ($empty.Count -eq 0)) `
        ("missing: $($missing -join ', ')  empty: $($empty -join ', ')")
    return ($missing.Count -eq 0 -and $empty.Count -eq 0)
}

Write-Host ''
Write-Host '=== VERIFY PASS 0043 ===' -ForegroundColor Cyan
Write-Host "workspace: $WorkspaceRoot"
Write-Host ''

# -- 1. pins ----------------------------------------------------------------
Write-Host '--- 1. commit pins (decision 0004) ---' -ForegroundColor Yellow
foreach ($repo in $Pinned.Keys) {
    $path = Join-Path $WorkspaceRoot $repo
    if (-not (Test-Path -LiteralPath $path)) {
        Assert-True "$repo present" $false "not found at $path"
        continue
    }
    Push-Location $path
    try {
        $head = (& git rev-parse HEAD).Trim()
        & git merge-base --is-ancestor $Pinned[$repo] HEAD 2>$null
        $contains = ($LASTEXITCODE -eq 0)
        Assert-True "$repo history contains the pinned commit $($Pinned[$repo].Substring(0,7))" $contains `
            "HEAD is $head; the pinned commit is not an ancestor, so this tree is not the one the pass described"
    }
    finally { Pop-Location }
}

# -- 2. artifacts -----------------------------------------------------------
Write-Host ''
Write-Host '--- 2. every matrix row, four artifacts each ---' -ForegroundColor Yellow
foreach ($repo in $Artifacts.Keys) {
    $null = Test-ArtifactsUnder -Root (Join-Path $WorkspaceRoot $repo) -Relative $Artifacts[$repo] -Label $repo
}

# -- 3. READMEs -------------------------------------------------------------
Write-Host ''
Write-Host '--- 3. README: badge row, hero, Examples section ---' -ForegroundColor Yellow
foreach ($repo in $Artifacts.Keys) {
    $readme = Join-Path $WorkspaceRoot "$repo/README.md"
    if (-not (Test-Path -LiteralPath $readme)) {
        Assert-True "$repo README present" $false
        continue
    }
    $text = Get-Content -LiteralPath $readme -Raw
    $head = ($text -split "`n" | Select-Object -First 12) -join "`n"

    Assert-True "$repo README has a badge row in the first 12 lines" `
        ([regex]::Matches($head, '\[!\[[^\]]*\]\([^)]*\)\]\([^)]*\)').Count -ge 3)

    $hero = $Heroes[$repo]
    Assert-True "$repo README embeds its hero image ($hero)" ($text -match [regex]::Escape($hero))
    Assert-True "$repo hero file exists" (Test-Path -LiteralPath (Join-Path $WorkspaceRoot "$repo/$hero"))

    $lines = Get-Content -LiteralPath $readme
    $ex = -1; $int = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($ex -lt 0 -and $lines[$i] -match '^#{2,3}\s+Examples\b') { $ex = $i }
        if ($int -lt 0 -and $lines[$i] -match '^#{2,3}\s+.*(architect|internal|how it works|design|contract|development|testing|vendor|view model|backend|build|command|reasoning|repositor|option|schema|graph shape)') { $int = $i }
    }
    Assert-True "$repo README has an Examples section" ($ex -ge 0)
    Assert-True "$repo README Examples precedes the internals" (($ex -ge 0) -and ($int -lt 0 -or $ex -lt $int)) `
        "Examples at line $($ex + 1), first internals heading at line $($int + 1)"
}

# -- 4. SC2 and SC3 ---------------------------------------------------------
Write-Host ''
Write-Host '--- 4. SC2 machine paths, SC3 credential shapes ---' -ForegroundColor Yellow
foreach ($repo in $Artifacts.Keys) {
    $root = Join-Path $WorkspaceRoot $repo
    Push-Location $root
    try {
        $files = @(& git ls-files 'examples/*' 'README.md') | Where-Object { $_ -notmatch '\.png$' }
    }
    finally { Pop-Location }

    $drive = 0
    $pat = 0
    foreach ($f in $files) {
        $full = Join-Path $root $f
        if (-not (Test-Path -LiteralPath $full)) { continue }
        $t = Get-Content -LiteralPath $full -Raw
        # NOT [A-Za-z]:[\\/] on its own - that matches http:// and vscode://
        # in every URL and reports every artifact as a violation.
        $drive += [regex]::Matches($t, '(?<![A-Za-z])[A-Za-z]:[\\/]').Count
        $pat += [regex]::Matches($t, '(?<![A-Za-z0-9])[A-Za-z0-9]{84}(?![A-Za-z0-9])').Count
    }
    Assert-True "$repo SC2 - no drive-absolute paths in examples/ or README" ($drive -eq 0) "$drive hit(s)"
    Assert-True "$repo SC3 - no 84-character credential-shaped runs" ($pat -eq 0) "$pat hit(s)"
}

# -- 5. the tag -------------------------------------------------------------
Write-Host ''
Write-Host '--- 5. PSAzureDevOpsGraph tag and worklog ---' -ForegroundColor Yellow
Push-Location (Join-Path $WorkspaceRoot 'PSAzureDevOpsGraph')
try {
    $tags = @(& git tag)
    Assert-True "tag $PinnedTag exists" ($tags -contains $PinnedTag)
    if ($tags -contains $PinnedTag) {
        $type = (& git cat-file -t $PinnedTag).Trim()
        Assert-True "tag $PinnedTag is annotated" ($type -eq 'tag') "object type is '$type'"
    }
}
finally { Pop-Location }
Assert-True "docs/worklog/$PinnedTag.md exists" `
    (Test-Path -LiteralPath (Join-Path $WorkspaceRoot "PSAzureDevOpsGraph/docs/worklog/$PinnedTag.md"))

# -- 6. LEDGER counter ------------------------------------------------------
Write-Host ''
Write-Host '--- 6. LEDGER counter matches the plans and journal trees ---' -ForegroundColor Yellow
$ledger = Get-Content -LiteralPath (Join-Path $harnessRoot 'LEDGER.md') -Raw
$m = [regex]::Match($ledger, 'Last landed:\s*\*\*(\d{4})\*\*')
Assert-True 'LEDGER states a Last landed number' $m.Success
if ($m.Success) {
    $stated = $m.Groups[1].Value
    $plansMax = (Get-ChildItem (Join-Path $harnessRoot 'plans') -Directory |
            ForEach-Object { if ($_.Name -match '^(\d{4})') { $Matches[1] } } | Sort-Object | Select-Object -Last 1)
    $journalMax = (Get-ChildItem (Join-Path $harnessRoot 'journal') -File -Filter '*.md' |
            ForEach-Object { if ($_.Name -match '^(\d{4})') { $Matches[1] } } | Sort-Object | Select-Object -Last 1)
    Assert-True "LEDGER Last landed ($stated) equals the plans tree frontier ($plansMax)" ($stated -eq $plansMax)
    Assert-True "LEDGER Last landed ($stated) equals the journal tree frontier ($journalMax)" ($stated -eq $journalMax)
    Assert-True "LEDGER Last landed is this pass ($PinnedLastLanded)" ($stated -eq $PinnedLastLanded)
}

# -- 7. accept.ps1 ----------------------------------------------------------
Write-Host ''
Write-Host '--- 7. accept.ps1 ---' -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'accept.ps1') -WorkspaceRoot $WorkspaceRoot | Out-Null
Assert-True 'accept.ps1 exits green' ($LASTEXITCODE -eq 0) "exit $LASTEXITCODE"

# -- 8. -FailCheck ----------------------------------------------------------
if ($FailCheck) {
    Write-Host ''
    Write-Host '--- 8. -FailCheck: the artifact check must go red ---' -ForegroundColor Yellow

    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratch -Force

    $victim = 'PSGraphRender'
    $copy = Join-Path $scratch $victim
    $null = New-Item -ItemType Directory -Path $copy -Force
    Copy-Item -LiteralPath (Join-Path $WorkspaceRoot "$victim/examples") -Destination (Join-Path $copy 'examples') -Recurse -Force

    $deleted = Join-Path $copy 'examples/layouts/foundation.png'
    Remove-Item -LiteralPath $deleted -Force
    Write-Host "        deleted from the copy: examples/layouts/foundation.png" -ForegroundColor DarkGray

    $before = $script:fail
    $null = Test-ArtifactsUnder -Root $copy -Relative $Artifacts[$victim] -Label "$victim (damaged scratch copy)"
    $wentRed = ($script:fail -gt $before)

    # That deliberate failure is the expected result, so it must not count
    # against the run.
    $script:fail = $before
    Assert-True '-FailCheck: a missing artifact is detected' $wentRed `
        'the artifact check passed against a copy with a deleted screenshot, so it checks nothing'

    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host ''
Write-Host ("PASS {0}   FAIL {1}" -f $pass, $fail) -ForegroundColor $(if ($fail) { 'Red' } else { 'Green' })
if ($fail) { exit 1 }
exit 0
