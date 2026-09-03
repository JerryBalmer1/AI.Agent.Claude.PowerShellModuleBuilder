#Requires -Version 7.2
<#
.SYNOPSIS
    Render docs/diagram/flow-graph.json to docs/diagram/flow.html through
    PSGraphRenderToHtml and PSGraphRender, consumed at their pinned tags.
.DESCRIPTION
    This repository is a producer. It hand-authors a producer graph, validates
    it against a contract another repository owns, and renders it with that
    repository's renderer - which is exactly what `producer-contract` tells
    anybody else to do. The dogfooding is the point and is named as such in
    README.md.

    THE TAGS ARE THE POINT. The two sibling repositories are consumed at
    v0.1.3 and v0.13.0 and never from their working trees, which are ahead of
    both. A diagram rendered by whatever happened to be checked out is a
    diagram nobody can reproduce. Each tag is materialised READ-ONLY, with
    `git archive`, into a temporary directory: no worktree is added, no ref is
    written, nothing in either sibling repository changes. The imported
    module's ModuleVersion is then checked against the tag, because a tag that
    resolved to the wrong tree would otherwise render perfectly well.

    NO vscode:// LINKS. PSGraphRenderToHtml's -EditorLinkMap emits
    vscode://file/<absolute path>, which is right for a producer whose reader
    is the person whose disk holds the files. This artifact is committed and
    read by strangers, so the repo-relative path lives in each node's `doc`
    attribute instead - carried through to the view model as an ordinary node
    property, visible in the details panel, and identical on every machine.
    README.md's link map is what makes those paths clickable.

    NOT REPRODUCIBLE BYTE FOR BYTE, and there is exactly one reason, named
    rather than worked around: ConvertTo-GraphRenderViewModel stamps
    meta.generatedAt with [DateTime]::UtcNow. Two renders of the same graph
    differ on that line and nowhere else. -Check re-renders and diffs
    everything except that stamp, which is the honest form of
    "content-stable".

    There WAS a second reason and it is now removed rather than normalised
    away: the document is written here as bytes with LF endings and exactly
    one trailing newline, instead of through Set-Content, which appends the
    platform's newline and made a Windows render differ from a Linux one - and
    from git's own normalised copy - by a single byte at the end of the file.
.PARAMETER RepoRoot
    The harness repository root. Defaults to two levels above this script.
.PARAMETER ToHtmlRepo
    Where PSGraphRenderToHtml is cloned. Default: a sibling of RepoRoot.
.PARAMETER RenderRepo
    Where PSGraphRender is cloned. Default: a sibling of RepoRoot.
.PARAMETER ToHtmlTag
    The tag to consume PSGraphRenderToHtml at.
.PARAMETER RenderTag
    The tag to consume PSGraphRender at.
.PARAMETER OutputPath
    Where to write the document. Default: docs/diagram/flow.html.
.PARAMETER SkipBattery
    Do not run PSGraphRenderToHtml's producer battery against the graph. For a
    render on a machine with no Pester; the battery is the check that makes the
    contract claim mean anything, so skipping it is stated in the output.
.PARAMETER Check
    Render, and compare against the committed document instead of writing over
    it. Exit 1 on any difference outside the timestamp.
.EXAMPLE
    $params = @{
        RepoRoot = 'C:/src/AI.Agent.Claude.PowerShellModuleBuilder'
    }

    $document = try {

        ./tools/diagram/Build-Diagram.ps1 @params

    }
    catch {
        Write-Error "The diagram could not be rendered: $_"
        $null
    }

    $document
.EXAMPLE
    $params = @{
        Check = $true
    }

    ./tools/diagram/Build-Diagram.ps1 @params

    Re-renders and diffs against the committed flow.html, ignoring the
    generatedAt stamp. This is the form verify.ps1 runs.
#>
[CmdletBinding()]
param(
    [string] $RepoRoot = "$PSScriptRoot/../..",
    [string] $ToHtmlRepo,
    [string] $RenderRepo,
    [string] $ToHtmlTag = 'v0.1.3',
    [string] $RenderTag = 'v0.13.0',
    [string] $OutputPath,
    [switch] $SkipBattery,
    [switch] $Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$parent = Split-Path -Parent $RepoRoot
if (-not $ToHtmlRepo) { $ToHtmlRepo = Join-Path $parent 'PSGraphRenderToHtml' }
if (-not $RenderRepo) { $RenderRepo = Join-Path $parent 'PSGraphRender' }
if (-not $OutputPath) { $OutputPath = Join-Path $RepoRoot 'docs/diagram/flow.html' }

$graphPath = Join-Path $RepoRoot 'docs/diagram/flow-graph.json'
if (-not (Test-Path -LiteralPath $graphPath)) { throw "No graph at '$graphPath'." }

# The stamp that makes two renders differ. Named once, used by -Check and by
# the message that explains the difference, so the two cannot disagree.
$VolatilePattern = '"generatedAt"\s*:\s*"[^"]*"'

function Export-TagTree {
    <#
        Materialise one tag of one repository, read-only. `git archive` writes
        nothing into the source repository - no worktree, no ref, no index -
        which is the property that lets this run against the operator's own
        clones without touching them.
    #>
    param(
        [Parameter(Mandatory)] [string] $Repo,
        [Parameter(Mandatory)] [string] $Tag,
        [Parameter(Mandatory)] [string] $Destination
    )

    if (-not (Test-Path -LiteralPath (Join-Path $Repo '.git'))) {
        throw "'$Repo' is not a git clone. Build-Diagram needs the sibling repositories in order to read their tags; pass -ToHtmlRepo and -RenderRepo if they live elsewhere."
    }
    $resolved = & git -C $Repo rev-parse --verify --quiet "refs/tags/$Tag^{commit}"
    if ($LASTEXITCODE -ne 0 -or -not $resolved) {
        throw "'$Repo' has no tag '$Tag'. The pin is not optional: rendering from a working tree produces a document nobody can reproduce."
    }

    $null = New-Item -ItemType Directory -Path $Destination -Force
    $zip = Join-Path $Destination 'tree.zip'
    & git -C $Repo archive --format=zip --output=$zip $Tag
    if ($LASTEXITCODE -ne 0) { throw "git archive failed for '$Repo' at '$Tag'." }
    Expand-Archive -LiteralPath $zip -DestinationPath $Destination -Force
    Remove-Item -LiteralPath $zip -Force
    $resolved.Trim()
}

function Import-TagModule {
    <#
        Import one module out of an archived tag tree.

        Both repositories follow the house convention where output/<Name>/ is a
        BUILD PRODUCT and is not committed - so PSGraphRender's psm1 does not
        exist in its own source tree and the manifest there cannot be imported
        as it stands. Building the archive is the only way to consume that tag,
        and it happens inside the temporary directory: the operator's clone is
        never built, cleaned or written to.

        PSGraphRenderToHtml ships an importable psm1 in src/ and needs no build.
        Deciding by what is on disk rather than by repository name means neither
        case is hard-coded, and a repository that changes its mind about this
        keeps working.
    #>
    param(
        [Parameter(Mandatory)] [string] $Root,
        [Parameter(Mandatory)] [string] $Name
    )

    $fromSource = Join-Path $Root "src/$Name/$Name.psd1"
    $rootModule = Join-Path $Root "src/$Name/$Name.psm1"
    if ((Test-Path -LiteralPath $fromSource) -and (Test-Path -LiteralPath $rootModule)) {
        Import-Module $fromSource -Force
        return "src (no build needed)"
    }

    $builder = Join-Path $Root 'build.ps1'
    if (-not (Test-Path -LiteralPath $builder)) {
        throw "'$Name' has no importable psm1 under src/ and no build.ps1 to produce one, in '$Root'."
    }
    Push-Location $Root
    try {
        $log = & pwsh -NoProfile -File $builder -Task Build 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Building '$Name' from its tag failed:`n$($log -join "`n")" }
    }
    finally { Pop-Location }

    $built = Join-Path $Root "output/$Name/$Name.psd1"
    if (-not (Test-Path -LiteralPath $built)) { throw "'$Name' built without error and produced no manifest at '$built'." }
    Import-Module $built -Force
    'built from the tag'
}

function Resolve-LayerColor {
    <#
        The five layer colours, as the map the renderer reads.

        ONE DECLARATION. flow-graph.json's meta.layerPalette names a colour per
        LAYER; the renderer's KindColor map is keyed by CLASSIFICATION, which is
        the payload's node `type`. This translates, and it refuses rather than
        guesses in the two ways the translation can be wrong:

        - a type that occurs under more than one scope, which would make one
          key need two colours and turn a layer colour into an average;
        - a scope with no palette entry, which the renderer would draw in
          KindColorFallback grey - a silent hole in a legend that claims five.

        Both are throws. A diagram whose colours mean something for thirty-seven
        nodes and nothing for two is worse than one that never claimed to.
    #>
    param([Parameter(Mandatory)] [string] $GraphPath)

    $graph = (Get-Content -LiteralPath $GraphPath -Raw | ConvertFrom-Json).graph
    $palette = $graph.meta.layerPalette
    if (-not $palette) { throw "'$GraphPath' declares no meta.layerPalette, so there are no layer colours to render with." }

    $paletteKeys = @($palette.PSObject.Properties.Name)
    $scopeOfType = @{}
    foreach ($node in $graph.nodes) {
        $type = [string]$node.type
        $scope = [string]$node.scope
        if ($scopeOfType.ContainsKey($type) -and $scopeOfType[$type] -ne $scope) {
            throw "Node type '$type' occurs under scope '$($scopeOfType[$type])' and scope '$scope'. Colour is per classification and the layer claim needs one scope per type; either the graph is wrong or colour can no longer carry the layer."
        }
        $scopeOfType[$type] = $scope
    }

    $map = @{}
    foreach ($type in ($scopeOfType.Keys | Sort-Object)) {
        $scope = $scopeOfType[$type]
        if ($scope -notin $paletteKeys) {
            throw "Scope '$scope' (node type '$type') has no entry in meta.layerPalette, which names: $($paletteKeys -join ', '). An unnamed scope renders in the fallback grey and the legend would be claiming a colour nothing draws."
        }
        $map[$type] = [string]$palette.$scope
    }

    # The other direction: a palette entry no node uses is a legend row for an
    # empty layer, which reads as a layer that exists and is empty.
    $used = @($scopeOfType.Values | Sort-Object -Unique)
    $unused = @($paletteKeys | Where-Object { $_ -notin $used })
    if ($unused.Count) {
        throw "meta.layerPalette names $($unused -join ', '), which no node carries. A colour for a layer with no members is a legend row for something that is not there."
    }

    $map
}

$work = Join-Path ([IO.Path]::GetTempPath()) ("flow-diagram-" + [guid]::NewGuid().ToString('n'))
$rendered = $null

try {
    $toHtmlRoot = Join-Path $work 'PSGraphRenderToHtml'
    $renderRoot = Join-Path $work 'PSGraphRender'
    $toHtmlSha = Export-TagTree -Repo $ToHtmlRepo -Tag $ToHtmlTag -Destination $toHtmlRoot
    $renderSha = Export-TagTree -Repo $RenderRepo -Tag $RenderTag -Destination $renderRoot

    "PSGraphRenderToHtml $ToHtmlTag  $toHtmlSha"
    "PSGraphRender       $RenderTag  $renderSha"

    # PSGraphRender FIRST and by path. Export-ProducerGraphHtml imports it by
    # NAME when no PSGraphRender is loaded, which would silently pick up
    # whatever is on PSModulePath and defeat the whole pin.
    "PSGraphRender       imported from: $(Import-TagModule -Root $renderRoot -Name 'PSGraphRender')"
    "PSGraphRenderToHtml imported from: $(Import-TagModule -Root $toHtmlRoot -Name 'PSGraphRenderToHtml')"

    $renderVersion = (Get-Module PSGraphRender).Version.ToString()
    $toHtmlVersion = (Get-Module PSGraphRenderToHtml).Version.ToString()
    $expectedRender = $RenderTag.TrimStart('v')
    $expectedToHtml = $ToHtmlTag.TrimStart('v')
    if ($renderVersion -ne $expectedRender) {
        throw "PSGraphRender at '$RenderTag' reports ModuleVersion $renderVersion, expected $expectedRender. The tag and the manifest disagree, and a render taken now would be attributed to a version it is not."
    }
    if ($toHtmlVersion -ne $expectedToHtml) {
        throw "PSGraphRenderToHtml at '$ToHtmlTag' reports ModuleVersion $toHtmlVersion, expected $expectedToHtml."
    }
    "versions verified: PSGraphRender $renderVersion, PSGraphRenderToHtml $toHtmlVersion"

    # Two checks, and the second is not implied by the first. The schema says
    # what shape the payload has; Test-ProducerGraph says whether the graph is
    # usable - every endpoint resolving, ids unique, parentId chains acyclic.
    $validation = Test-ProducerGraph -Path $graphPath
    if (-not $validation.IsValid) {
        $detail = ($validation.Violations | ForEach-Object { "  $_" }) -join "`n"
        throw "flow-graph.json does not satisfy the producer contract:`n$detail"
    }
    "Test-ProducerGraph: valid"

    if ($SkipBattery) {
        'BATTERY: SKIPPED - the contract claim is unverified in this run'
    }
    else {
        $battery = Join-Path $toHtmlRoot 'tests/ProducerContract.Battery.ps1'
        Import-Module Pester -MinimumVersion 6.0.0
        $cfg = New-PesterConfiguration
        $cfg.Run.Container = New-PesterContainer -Path $battery -Data @{
            GraphPath  = $graphPath
            ModulePath = (Join-Path $toHtmlRoot 'src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1')
        }
        $cfg.Output.Verbosity = 'None'
        $cfg.Run.PassThru = $true
        $result = Invoke-Pester -Configuration $cfg

        # 45 again: a container that failed discovery reports no failures and
        # no passes, and the line below would read as a clean run.
        $broken = @($result.Containers | Where-Object { $_.ErrorRecord })
        if ($broken.Count) {
            throw "The producer battery failed to load: $($broken[0].ErrorRecord[0].Exception.Message)"
        }
        if ($result.TotalCount -eq 0) { throw 'The producer battery selected no cases. A battery that graded nothing is not a battery.' }
        "BATTERY: Passed=$($result.PassedCount) Failed=$($result.FailedCount) Total=$($result.TotalCount)"
        if ($result.FailedCount -gt 0) {
            $names = @($result.Tests | Where-Object { $_.Result -eq 'Failed' } | ForEach-Object { $_.ExpandedName })
            throw ("The producer battery is red: " + ($names -join '; '))
        }
    }

    # No -EditorLinkMap: see the description.
    #
    # -ColorBy IS passed now, and the history is worth the paragraph because
    # pass 0040 shipped this call without it. PSGraphRenderToHtml v0.1.0
    # validated -ColorBy against { structure, scope, type } while PSGraphRender
    # v0.13.0's cytoscape settings schema accepts { structure, dependents,
    # blastRadius, dependencies, reach } - two sets sharing one member. Asking
    # for `type` bound here and was warned about and downgraded there, so 0040
    # removed the option rather than ship a request that does not arrive, and
    # recorded it as LEDGER 50. ToHtml v0.1.1 aligns the set; this consumes
    # that fix, which is what makes the fix a thing that happened rather than a
    # thing that was written.
    #
    # And the answer 0040 actually wanted is not a ColorBy value at all. LAYER
    # is not a channel the renderer knows: it colours by CLASSIFICATION, which
    # is this payload's node `type`. The producer is what makes the two the
    # same fact - every type in this graph occurs under exactly one scope, so a
    # type -> colour map IS a layer -> colour map, and Resolve-LayerColor
    # refuses to build one if that ever stops being true.
    $kindColor = Resolve-LayerColor -GraphPath $graphPath

    # ZoomSpeed 0.6 against the renderer's 1.25 default. Operator-reported: one
    # wheel notch crossed most of the graph, which on a 39-node diagram means
    # the control is unusable for the thing it exists for. Tuned here rather
    # than in the renderer, because it is a fact about this diagram's density
    # and not about zooming.
    $options = New-GraphRenderOptions -Backend cytoscape -Layout foundation `
        -ColorBy structure -ZoomSpeed 0.6 -Theme @{ KindColor = $kindColor } `
        -Title 'AI.Agent.Claude.PowerShellModuleBuilder - the flow'

    'layer colours, from flow-graph.json meta.layerPalette:'
    foreach ($key in ($kindColor.Keys | Sort-Object)) { "  {0,-20} {1}" -f $key, $kindColor[$key] }
    "ZoomSpeed: $($options.Settings.ZoomSpeed) (renderer default 1.25)"
    "ColorBy:   $($options.Settings.ColorBy)"

    # NO -OutputPath, deliberately. Export-ProducerGraphHtml writes with
    # Set-Content, which appends the PLATFORM's newline - so the file gained a
    # trailing CRLF on Windows while every other line ended LF, and git stored
    # it normalised. A fresh render and the committed file then differed by one
    # byte, with identical line counts and no differing line, which is the
    # least diagnosable form the difference could have taken. Taking the
    # document as a string and writing the bytes here makes the artifact
    # identical on any platform, and does it without touching the pinned
    # module.
    # A RENDERER WARNING IS A STOP HERE, and this guard is why the diagram is
    # not currently grey. PSGraphRenderToHtml v0.1.2 wrote the theme overlay
    # with bare keys, so `cross-cutting` parsed as a subtraction, the whole
    # theme.psd1 failed to parse, and PSGraphRender WARNED and fell back to its
    # built-in colours. The page rendered. It looked deliberate. Every node was
    # the fallback grey and the five layer colours were nowhere in it.
    #
    # Nothing about the artifact says so, which is the point: a build that
    # prints WROTE and hands back a document nobody can tell is wrong is worse
    # than one that fails. The warnings are captured and any one of them ends
    # the run.
    $renderWarnings = @()
    $document = Export-ProducerGraphHtml -Path $graphPath -Options $options `
        -WarningVariable renderWarnings -WarningAction SilentlyContinue
    if ($renderWarnings.Count) {
        $detail = ($renderWarnings | ForEach-Object { "  $($_.Message)" }) -join "`n"
        throw "The render raised $($renderWarnings.Count) warning(s), and a warned render is a document whose settings did not all arrive:`n$detail"
    }
    'render: 0 warnings'
    $document = ($document -replace "`r`n", "`n").TrimEnd("`n") + "`n"

    if (-not $Check) {
        $parent = Split-Path -Parent $OutputPath
        if ($parent -and -not (Test-Path -LiteralPath $parent)) { $null = New-Item -ItemType Directory -Path $parent -Force }
        [IO.File]::WriteAllText($OutputPath, $document, [Text.UTF8Encoding]::new($false))
        "WROTE: $((Resolve-Path -LiteralPath $OutputPath).Path)"
        return
    }

    if (-not (Test-Path -LiteralPath $OutputPath)) {
        throw "-Check has nothing to compare against: '$OutputPath' does not exist."
    }
    $fresh = $document -replace $VolatilePattern, '"generatedAt":"<stamp>"'
    $committed = ((Get-Content -LiteralPath $OutputPath -Raw) -replace "`r`n", "`n") -replace $VolatilePattern, '"generatedAt":"<stamp>"'
    if ($fresh -eq $committed) {
        'CHECK: flow.html is byte-identical to a fresh render, apart from the generatedAt stamp'
        return
    }

    # Say WHERE, not just that. A diff report nobody can act on is a report.
    $freshLines = $fresh -split "`r?`n"
    $committedLines = $committed -split "`r?`n"
    "CHECK: DIFFERS. fresh=$($freshLines.Count) lines, committed=$($committedLines.Count) lines"
    for ($i = 0; $i -lt [math]::Max($freshLines.Count, $committedLines.Count); $i++) {
        $a = if ($i -lt $committedLines.Count) { $committedLines[$i] } else { '<absent>' }
        $b = if ($i -lt $freshLines.Count) { $freshLines[$i] } else { '<absent>' }
        if ($a -ne $b) {
            "  first difference at line $($i + 1)"
            "    committed: $($a.Substring(0, [math]::Min(160, $a.Length)))"
            "    fresh:     $($b.Substring(0, [math]::Min(160, $b.Length)))"
            break
        }
    }
    exit 1
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}
