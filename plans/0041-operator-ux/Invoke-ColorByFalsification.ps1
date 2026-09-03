#Requires -Version 7.2
<#
.SYNOPSIS
    Falsify the LEDGER 50 fix: prove -ColorBy now reaches the renderer, refuses
    what the renderer never accepted, and leaves the control unchanged.
.DESCRIPTION
    LEDGER 50 is a cross-module ValidateSet that promised what the callee did
    not accept. A fix to that class of defect cannot be shown by reading the
    parameter block, because the whole defect WAS a parameter block that read
    correctly. So this drives real renders and reads what comes back.

    The observable is PSGraphRender's own warning. Handed a setting outside its
    schema it says so and substitutes the default - that is the "silently
    downgraded" of the ledger entry, and it is silent only in the sense that
    nothing was watching. This watches.

    Node FILLS are not readable from the document, and that is stated here so
    nobody re-attempts it: cytoscape computes each fill in the browser from
    ColorBy plus the theme, and draws it into a canvas. There is no per-node
    colour in the HTML and no DOM element to query for one. Reading fills would
    mean re-implementing the renderer's fillFor in the checker, which is the
    same class of mistake as the defect being fixed - a second copy of another
    repository's rule, drifting unobserved. The renderer's own acceptance is
    the evidence available, and it is the evidence that matters: the fill
    followed the setting all along, and the setting was what never arrived.

    THREE CHECKS.

    1. PREVIOUSLY DROPPED. `-ColorBy blastRadius` could not be passed at all
       before: v0.1.0's ValidateSet refused it while PSGraphRender has always
       drawn it. It must now bind, reach the document, and draw a render the
       renderer raises NO warning about.
    2. REFUSED, NAMING BOTH SIDES. `scope` and `type` were v0.1.0's own values
       and the renderer never took either. They must now fail before a render
       happens, with a message naming PSGraphRender - because a caller reading
       it is looking at the wrong repository's documentation. Then the same
       values are FORCED past the validator, reconstructing exactly what
       v0.1.0 did, to show the warning and the downgrade that used to be the
       whole of the behaviour.
    3. CONTROL UNCHANGED. `structure` is the one member the two sets always
       shared. Its document must be identical to the one the PRE-FIX module
       produces from the same graph, apart from the generatedAt stamp. The
       pre-fix module is materialised read-only from a git ref with
       `git archive`, so nothing in the checkout is touched.

    Check 1 is only evidence because check 3 pins the control: a fix that moved
    everything would satisfy 1 by accident.
.PARAMETER ToHtmlRoot
    A PSGraphRenderToHtml checkout. Its tests/TestHelpers.ps1 resolves the
    renderer the same way the build does.
.PARAMETER BaselineRef
    The git ref holding the PRE-FIX module, for check 3. Default: origin/main.
.PARAMETER GraphPath
    A producer graph to render. Default: the sample the repository ships.
.EXAMPLE
    $params = @{
        ToHtmlRoot = 'C:/src/PSGraphRenderToHtml'
    }

    $report = try {

        ./plans/0041-operator-ux/Invoke-ColorByFalsification.ps1 @params

    }
    catch {
        Write-Error "The falsification could not run: $_"
        $null
    }

    $report
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ToHtmlRoot,
    [string] $BaselineRef = 'origin/main',
    [string] $GraphPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ToHtmlRoot = (Resolve-Path -LiteralPath $ToHtmlRoot).Path
if (-not $GraphPath) { $GraphPath = Join-Path $ToHtmlRoot 'docs/samples/sample-graph.json' }
$GraphPath = (Resolve-Path -LiteralPath $GraphPath).Path

# The one line two renders of the same graph always differ on.
$VolatilePattern = '"generatedAt"\s*:\s*"[^"]*"'

. (Join-Path $ToHtmlRoot 'tests/TestHelpers.ps1')
Import-ToHtmlUnderTest

$toHtml = Get-Module PSGraphRenderToHtml
$render = Get-Module PSGraphRender
'COLORBY FALSIFICATION - LEDGER 50'
"  PSGraphRenderToHtml v$($toHtml.Version)  $($toHtml.Path)"
"  PSGraphRender       v$($render.Version)  $($render.Path)"
"  graph               $GraphPath"
"  baseline ref        $BaselineRef"
''

$failures = [System.Collections.Generic.List[string]]::new()

function Invoke-Render {
    <#
        Render, and hand back the document with the renderer's warnings beside
        it. The warnings are the observable; a renderer that complains into a
        stream nobody captured is where this defect lived for a version.
    #>
    param([Parameter(Mandatory)] $Options)
    $warnings = @()
    $document = Export-ProducerGraphHtml -Path $GraphPath -Options $Options `
        -WarningVariable warnings -WarningAction SilentlyContinue
    [pscustomobject]@{
        Document = $document
        Warnings = @($warnings | ForEach-Object { $_.Message })
    }
}

function New-ForcedOption {
    <#
        The options object v0.1.0 produced for a value it accepted and the
        renderer did not. Hand-built, because the fixed module will no longer
        make one - and the point of check 2 is to show what it was making.
    #>
    param([Parameter(Mandatory)] [string] $ColorBy)
    [pscustomobject]@{
        PSTypeName      = 'PSGraphRenderToHtml.RenderOptions'
        Backend         = 'cytoscape'
        Layout          = 'foundation'
        Title           = 'falsification'
        ColorBy         = $ColorBy
        Settings        = [ordered]@{
            DefaultFlow     = 'foundation'
            ColorBy         = $ColorBy
            ZoomSpeed       = 1.25
            FocusDepth      = 2
            NodeLimit       = 400
            MinReadableZoom = 0.45
        }
        Theme           = @{}
        EditorLinkMap   = @{}
        ContractVersion = '0.1.0'
    }
}

# --- 1. the previously-dropped value ---------------------------------------
'1. PREVIOUSLY DROPPED - blastRadius: refused by v0.1.0, drawn by the renderer'
$heat = Invoke-Render -Options (New-GraphRenderOptions -ColorBy blastRadius -Title 'falsification')
"   bound, and rendered $($heat.Document.Length) characters"
"   renderer warnings: $($heat.Warnings.Count)"
$heat.Warnings | ForEach-Object { "     $_" }
if ($heat.Warnings.Count -ne 0) {
    $failures.Add("blastRadius still warns: $($heat.Warnings -join '; ')")
}
if ($heat.Document -notmatch 'blastRadius') {
    $failures.Add('blastRadius does not appear in the rendered document, so the request did not arrive.')
}
else {
    "   the setting reaches the document: 'blastRadius' occurs $(([regex]::Matches($heat.Document, 'blastRadius')).Count) times in it"
}
''

# --- 2. the values the renderer never accepted ------------------------------
'2. REFUSED, NAMING BOTH SIDES - scope and type, the values v0.1.0 accepted'
foreach ($value in 'scope', 'type') {
    $message = $null
    try {
        $null = New-GraphRenderOptions -ColorBy $value
        $failures.Add("-ColorBy $value was ACCEPTED; the fix is not in.")
        "   ${value}: ACCEPTED  <-- the fix is not in"
        continue
    }
    catch { $message = $_.Exception.Message }
    "   ${value}: refused before any render happened"
    "      $message"
    foreach ($side in 'PSGraphRender', 'blastRadius') {
        if ($message -notmatch [regex]::Escape($side)) {
            $failures.Add("-ColorBy $value refused without naming '$side'; the message must name both sides.")
        }
    }
}
''
'   and forced past the validator, which is what v0.1.0 did every time:'
foreach ($value in 'scope', 'type') {
    $forced = Invoke-Render -Options (New-ForcedOption -ColorBy $value)
    "   ${value}: renderer warnings $($forced.Warnings.Count)"
    $forced.Warnings | ForEach-Object { "      $_" }
    if ($forced.Warnings.Count -eq 0) {
        $failures.Add("Forcing '$value' past the validator produced no renderer warning, so the downgrade this fix is about cannot be demonstrated and the premise needs re-checking.")
    }
}
''

# --- 3. the control ---------------------------------------------------------
'3. CONTROL UNCHANGED - structure, against the PRE-FIX module'
$control = Invoke-Render -Options (New-GraphRenderOptions -ColorBy structure -Title 'falsification')
"   post-fix: $($control.Document.Length) characters, $($control.Warnings.Count) warnings"

$work = Join-Path ([IO.Path]::GetTempPath()) ("colorby-baseline-" + [guid]::NewGuid().ToString('n'))
try {
    $null = New-Item -ItemType Directory -Path $work -Force
    $zip = Join-Path $work 'tree.zip'
    & git -C $ToHtmlRoot archive --format=zip --output=$zip $BaselineRef
    if ($LASTEXITCODE -ne 0) { throw "git archive failed for '$BaselineRef'." }
    Expand-Archive -LiteralPath $zip -DestinationPath $work -Force
    Remove-Item -LiteralPath $zip -Force

    $baselineManifest = Join-Path $work 'src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1'
    "   baseline module: v$((Import-PowerShellDataFile -LiteralPath $baselineManifest).ModuleVersion) from $BaselineRef"
    Import-Module -Name $baselineManifest -Force

    $baseline = Invoke-Render -Options (New-GraphRenderOptions -ColorBy structure -Title 'falsification')
    "   pre-fix:  $($baseline.Document.Length) characters, $($baseline.Warnings.Count) warnings"

    $a = $control.Document -replace $VolatilePattern, '"generatedAt":"<stamp>"'
    $b = $baseline.Document -replace $VolatilePattern, '"generatedAt":"<stamp>"'
    if ($a -eq $b) {
        '   identical apart from the generatedAt stamp'
    }
    else {
        "   DIFFERS: post-fix $($a.Length) vs pre-fix $($b.Length) characters"
        $failures.Add('The control render changed across the fix; structure was not meant to move.')
    }

    # And the half that makes the pair a before/after rather than two renders.
    try {
        $null = New-GraphRenderOptions -ColorBy blastRadius
        $failures.Add('The PRE-FIX module accepted blastRadius, so it was never dropped and check 1 proves nothing.')
        '   pre-fix accepted blastRadius  <-- the premise is wrong'
    }
    catch { '   pre-fix refused blastRadius, which is the drop this pass removed' }
}
finally {
    Import-ToHtmlUnderTest
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
''

if ($failures.Count) {
    'FALSIFICATION FAILURES:'
    $failures | ForEach-Object { "  $_" }
    ''
    "FALSIFICATION: $($failures.Count) FAILED"
    exit 1
}
'FALSIFICATION: 3 of 3 - the dropped value now reaches the renderer unwarned, the values it never accepted refuse naming both sides, and the control is byte-identical to pre-fix'
