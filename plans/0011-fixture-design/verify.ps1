#Requires -Version 7.2

<#
.SYNOPSIS
    Verifies Pass 0011 from a fresh clone.

.DESCRIPTION
    Re-derives every claim the plan makes, rather than reading the plan. It does
    not parse plan.md, does not read AzDoPAT.txt, and makes no network call.

    Check 1 deliberately does NOT reuse the acceptance test's YAML reader. It
    contains a second, cruder, line-based extractor written independently, so
    that agreement between the two is evidence rather than a tautology. If the
    two disagree, one of them is wrong and this exits non-zero — which is the
    outcome worth having.


    EDITED DURING PASS 0013, BEFORE DECISION 0004 EXISTED.

    Pass 0013 modified this script: it corrected the PAT-shape scan, and (in
    0012's copy) changed the pinned Fixture.Tests.ps1 case count from 346 to
    352 after adding six assertions to that suite.

    Under decisions/0004-plan-artifacts-are-frozen.md those edits would not be
    made today: a plan and its verify script are valid against the commit that
    pass pushed and are not maintained forward. The edits are not reverted -
    reverting them would make this script red for a reason decision 0004 says
    is not a fault - but they are recorded here so that nobody reads the
    current contents as what this pass originally asserted. The originals are
    in the history, at the commit that pass pushed.

    Exit 0 when everything agrees, 1 otherwise, naming each check that did not.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$fixture = Join-Path $RepoRoot 'evals/functional/fixture'
$repos = Join-Path $fixture 'repos'
$graphPath = Join-Path $fixture 'expected-graph.json'
$htmlPath = Join-Path $RepoRoot 'runs/000-expected/000.html'
$testPath = Join-Path $RepoRoot 'evals/functional/Fixture.Tests.ps1'

$failures = [System.Collections.Generic.List[string]]::new()
function Assert-True {
    param([string]$Check, [bool]$Condition, [string]$Detail = '')
    if ($Condition) {
        Write-Host ("  ok    {0}" -f $Check) -ForegroundColor DarkGreen
    }
    else {
        Write-Host ("  FAIL  {0}{1}" -f $Check, $(if ($Detail) { " -- $Detail" } else { '' })) -ForegroundColor Red
        $failures.Add("$Check$(if ($Detail) { " -- $Detail" })")
    }
}

# ============================================================ helpers

$graph = Get-Content -LiteralPath $graphPath -Raw | ConvertFrom-Json
$nodes = @($graph.nodes)
$edges = @($graph.edges)
$nodeById = @{}
foreach ($n in $nodes) { $nodeById[$n.id] = $n }

function Get-RelativeFixturePath {
    param([string]$FullPath)
    ($FullPath.Substring($fixture.Length + 1) -replace '\\', '/')
}

function Get-NodeIdForRelative {
    param([string]$Relative)
    $hit = @($nodes | Where-Object { $_.kind -eq 'yaml' -and $_.path -eq $Relative })
    if ($hit.Count -eq 1) { return $hit[0].id }
    return $null
}

# --- the independent extractor -------------------------------------------
#
# Line based, no structure, no parser. It knows four things: a `template:` key
# preceded by nothing but whitespace or a dash; whether the nearest enclosing
# block is `extends:`; a `resources.repositories`/`resources.pipelines` section;
# and a `checkout:`. Written to be a different implementation from the one in
# Fixture.Tests.ps1, not a copy of it.

function Get-CrudeYamlReference {
    param([string]$Path)

    $raw = Get-Content -LiteralPath $Path
    $out = [System.Collections.Generic.List[object]]::new()

    $extendsIndent = -1     # indent of an open `extends:` block, or -1
    $resourceSection = ''   # '', 'repositories', 'pipelines'
    $resourceIndent = -1
    $pendingAlias = $null

    foreach ($line in $raw) {
        # Strip a comment. Good enough for this fixture: no '#' appears inside a
        # quoted scalar anywhere in it, and the acceptance test would fail if one
        # were introduced with a reference hiding behind it.
        $code = $line -replace '(?<=^|\s)#.*$', ''
        if ($code.Trim() -eq '') { continue }
        $indent = $code.Length - $code.TrimStart(' ').Length
        $body = $code.Trim()

        if ($extendsIndent -ge 0 -and $indent -le $extendsIndent) { $extendsIndent = -1 }
        if ($resourceIndent -ge 0 -and $indent -le $resourceIndent) { $resourceSection = ''; $resourceIndent = -1 }

        if ($body -eq 'extends:') { $extendsIndent = $indent; continue }
        if ($body -eq 'repositories:') { $resourceSection = 'repositories'; $resourceIndent = $indent; continue }
        if ($body -eq 'pipelines:') { $resourceSection = 'pipelines'; $resourceIndent = $indent; continue }

        if ($body -match '^-?\s*template:\s*(\S+)$') {
            $kind = if ($extendsIndent -ge 0) { 'extends' } else { 'template' }
            $out.Add([pscustomobject]@{ Kind = $kind; Ref = $Matches[1]; Alias = $null })
            continue
        }
        if ($body -match '^-\s*checkout:\s*(\S+)$') {
            if ($Matches[1] -notin 'self', 'none') {
                $out.Add([pscustomobject]@{ Kind = 'checkout'; Ref = $Matches[1]; Alias = $null })
            }
            continue
        }
        if ($body -match '^-\s*repository:\s*(\S+)$') { $pendingAlias = $Matches[1]; continue }
        if ($body -match '^-\s*pipeline:\s*(\S+)$') { $pendingAlias = $Matches[1]; continue }
        if ($resourceSection -eq 'repositories' -and $body -match '^name:\s*(\S+)$') {
            $out.Add([pscustomobject]@{ Kind = 'repositoryResource'; Ref = $Matches[1]; Alias = $pendingAlias })
            continue
        }
        if ($resourceSection -eq 'pipelines' -and $body -match '^source:\s*(\S+)$') {
            $out.Add([pscustomobject]@{ Kind = 'pipelineResource'; Ref = $Matches[1]; Alias = $pendingAlias })
            continue
        }
    }
    # Emitted, not wrapped: every caller either pipes this or wraps it in @().
    return $out
}

function Get-DeclaredReference {
    param([string]$NodeId)
    foreach ($e in $edges) {
        if ($e.from -ne $NodeId) { continue }
        $kind = if ($e.kind -eq 'unresolved') { $e.refKind } else { $e.kind }
        if ($kind -eq 'definition') { continue }
        if ($e.PSObject.Properties.Name -notcontains 'ref') { continue }
        [pscustomobject]@{ Kind = $kind; Ref = $e.ref }
    }
}

function Get-RepositoryAlias {
    param([string]$Path)
    $map = @{}
    foreach ($r in (Get-CrudeYamlReference -Path $Path)) {
        if ($r.Kind -eq 'repositoryResource' -and $r.Alias) { $map[$r.Alias] = ($r.Ref -split '/')[-1] }
    }
    return $map
}

# ============================================================ check 0

Write-Host 'check 0 - the acceptance test passes' -ForegroundColor Cyan
$pester = Get-Module -ListAvailable Pester | Where-Object Version -GE ([version]'6.0.0') | Select-Object -First 1
if (-not $pester) {
    Assert-True 'Pester 6 is available' $false 'install Pester 6 or later'
}
else {
    Import-Module $pester.Path -Force
    $config = New-PesterConfiguration
    $config.Run.Path = $testPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'None'
    $result = Invoke-Pester -Configuration $config
    Assert-True 'Fixture.Tests.ps1 is green' ($result.FailedCount -eq 0) "$($result.FailedCount) failed of $($result.TotalCount)"
    Assert-True 'Fixture.Tests.ps1 ran a non-trivial number of cases' ($result.TotalCount -ge 300) "$($result.TotalCount) tests"
}

# ============================================================ check 1

Write-Host 'check 1 - assertion 6 re-derived, both directions, by a second extractor' -ForegroundColor Cyan
$yamlFiles = @(Get-ChildItem -LiteralPath $repos -Recurse -File | Where-Object { $_.Extension -in '.yml', '.yaml' } | Sort-Object FullName)
Assert-True 'every YAML file under repos/ is present' ($yamlFiles.Count -eq 30) "$($yamlFiles.Count) files"

$drift = [System.Collections.Generic.List[string]]::new()
foreach ($file in $yamlFiles) {
    $relative = Get-RelativeFixturePath $file.FullName
    $nodeId = Get-NodeIdForRelative $relative
    if (-not $nodeId) { $drift.Add("$relative has no declared node"); continue }

    $found = @(Get-CrudeYamlReference -Path $file.FullName | ForEach-Object { "$($_.Kind)|$($_.Ref)" } | Sort-Object)
    $declared = @(Get-DeclaredReference -NodeId $nodeId | ForEach-Object { "$($_.Kind)|$($_.Ref)" } | Sort-Object)

    foreach ($f in $found) { if ($f -notin $declared) { $drift.Add("$relative contains '$f' which the graph does not declare") } }
    foreach ($d in $declared) { if ($d -notin $found) { $drift.Add("$relative is declared to contain '$d' which is not in the file") } }
}
Assert-True 'the YAML and the declared graph agree in both directions' ($drift.Count -eq 0) ($drift -join ' ; ')

# ============================================================ check 2

Write-Host 'check 2 - case 4, the cross-repo edges out of p04.yml' -ForegroundColor Cyan
$p04 = Join-Path $repos 'pipelines-main/pipelines/p04.yml'
Assert-True 'p04.yml exists' (Test-Path -LiteralPath $p04)
$aliases = Get-RepositoryAlias -Path $p04
Assert-True 'p04.yml declares two repository aliases' ($aliases.Count -eq 2) ("aliases: " + (($aliases.Keys | Sort-Object) -join ', '))

foreach ($ref in 'steps/common.yml@sharedTemplates', 'steps/deploy.yml@platformTemplates') {
    $path, $alias = $ref -split '@', 2
    if (-not $aliases.ContainsKey($alias)) {
        Assert-True "alias '$alias' is declared in p04.yml" $false
        continue
    }
    $repoName = $aliases[$alias]
    # Cross-repo template paths resolve from the ROOT of the aliased repository.
    $resolvedFile = Join-Path $repos (Join-Path $repoName $path)
    $expectedId = "yaml:$repoName/$path"
    $declaredEdge = @($edges | Where-Object { $_.from -eq 'yaml:pipelines-main/pipelines/p04.yml' -and $_.ref -eq $ref })

    Assert-True "$ref resolves to a file that exists" (Test-Path -LiteralPath $resolvedFile) $resolvedFile
    Assert-True "$ref has exactly one declared edge" ($declaredEdge.Count -eq 1) "$($declaredEdge.Count) edges"
    if ($declaredEdge.Count -eq 1) {
        Assert-True "$ref points at $expectedId" ($declaredEdge[0].to -eq $expectedId) "declared: $($declaredEdge[0].to)"
        Assert-True "$ref is of kind template" ($declaredEdge[0].kind -eq 'template') $declaredEdge[0].kind
    }
}

# The wrong-repo answer must be wrong. steps/deploy.yml must NOT exist in
# templates-shared, or resolving in the wrong repo would still find a file.
Assert-True 'steps/deploy.yml does not exist in templates-shared' `
    (-not (Test-Path -LiteralPath (Join-Path $repos 'templates-shared/steps/deploy.yml')))

# ============================================================ check 3

Write-Host 'check 3 - case 9, both unresolved targets genuinely do not exist' -ForegroundColor Cyan
$unresolved = @($edges | Where-Object kind -EQ 'unresolved')
Assert-True 'there are exactly two unresolved edges' ($unresolved.Count -eq 2) "$($unresolved.Count)"

$missingFile = Join-Path $repos 'pipelines-main/pipelines/templates/missing-steps.yml'
Assert-True 'templates/missing-steps.yml does not exist anywhere under repos/' `
(-not (Test-Path -LiteralPath $missingFile)) $missingFile
Assert-True 'no file named missing-steps.yml exists in any repository' `
    (@(Get-ChildItem -LiteralPath $repos -Recurse -File -Filter 'missing-steps.yml').Count -eq 0)

$p09Aliases = Get-RepositoryAlias -Path (Join-Path $repos 'pipelines-main/pipelines/p09.yml')
Assert-True "alias 'ghostTemplates' is not declared in p09.yml" (-not $p09Aliases.ContainsKey('ghostTemplates')) `
(($p09Aliases.Keys | Sort-Object) -join ', ')

foreach ($u in $unresolved) {
    Assert-True "unresolved target '$($u.to)' is not a declared node" (-not $nodeById.ContainsKey($u.to))
    Assert-True "unresolved edge '$($u.ref)' states a reason" ([bool]$u.reason)
}

# ============================================================ check 4

Write-Host 'check 4 - case 8, a traversal from p08 terminates and reports a cycle' -ForegroundColor Cyan
$adjacency = @{}
foreach ($e in $edges) {
    if (-not $adjacency.ContainsKey($e.from)) { $adjacency[$e.from] = [System.Collections.Generic.List[string]]::new() }
    $adjacency[$e.from].Add($e.to)
}

$visited = [System.Collections.Generic.HashSet[string]]::new()
$onPath = [System.Collections.Generic.HashSet[string]]::new()
$backEdges = [System.Collections.Generic.List[string]]::new()
$steps = 0
$budget = 10000

function Invoke-Walk {
    param([string]$Id)
    $script:steps++
    if ($script:steps -gt $budget) { throw "traversal exceeded $budget steps: it is not terminating" }
    if (-not $onPath.Add($Id)) { return }
    $null = $visited.Add($Id)
    if ($adjacency.ContainsKey($Id)) {
        foreach ($next in $adjacency[$Id]) {
            if ($onPath.Contains($next)) {
                $backEdges.Add("$Id -> $next")
                continue
            }
            Invoke-Walk -Id $next
        }
    }
    $null = $onPath.Remove($Id)
}

$terminated = $true
try { Invoke-Walk -Id 'pipeline:p08-cycle' } catch { $terminated = $false; Write-Host "    $($_.Exception.Message)" -ForegroundColor Red }
Assert-True 'the traversal from p08 terminates' $terminated "steps: $steps"
Assert-True 'the traversal reports exactly one back edge' ($backEdges.Count -eq 1) ($backEdges -join ', ')
Assert-True 'the back edge is cycle-b -> cycle-a' `
($backEdges.Count -eq 1 -and $backEdges[0] -eq 'yaml:pipelines-main/pipelines/templates/cycle-b.yml -> yaml:pipelines-main/pipelines/templates/cycle-a.yml') `
    ($backEdges -join ', ')
Assert-True 'both halves of the cycle were reached' `
($visited.Contains('yaml:pipelines-main/pipelines/templates/cycle-a.yml') -and $visited.Contains('yaml:pipelines-main/pipelines/templates/cycle-b.yml'))

# ============================================================ check 5

Write-Host 'check 5 - the rendered HTML' -ForegroundColor Cyan
Assert-True '000.html exists' (Test-Path -LiteralPath $htmlPath)
if (Test-Path -LiteralPath $htmlPath) {
    $html = Get-Content -LiteralPath $htmlPath -Raw
    Assert-True '000.html is not empty' ($html.Length -gt 1000) "$($html.Length) bytes"
    Assert-True '000.html contains no external script reference' (-not ([regex]::IsMatch($html, '<script[^>]*\ssrc\s*=')))
    Assert-True '000.html contains no external stylesheet reference' (-not ([regex]::IsMatch($html, '<link[^>]*rel\s*=\s*["'']?stylesheet')))
    Assert-True '000.html contains no @import' (-not ($html -match '@import'))
    Assert-True '000.html contains no http:// or https:// at all' (-not ([regex]::IsMatch($html, 'https?://')))
    $rendered = ([regex]::Matches($html, 'data-node-id=')).Count
    Assert-True '000.html node count matches expected-graph.json' ($rendered -eq $nodes.Count) "html: $rendered, graph: $($nodes.Count)"
    $renderedUnresolved = ([regex]::Matches($html, 'data-unresolved-id=')).Count
    Assert-True '000.html draws both unresolved targets as pseudo-nodes' ($renderedUnresolved -eq 2) "$renderedUnresolved"
}

# ============================================================ check 6

Write-Host 'check 6 - no PAT-shaped string in any tracked file' -ForegroundColor Cyan
Push-Location $RepoRoot
try {
    $tracked = @(& git ls-files 2>$null)
}
finally {
    Pop-Location
}
if ($tracked.Count -eq 0) {
    Assert-True 'git ls-files returned files' $false 'run from a git clone'
}
else {
    # Corrected by Pass 0013. The original pattern set assumed a 52-character
    # lowercase base32 token. The PAT actually in use is 84 characters,
    # mixed-case alphanumeric, one unbroken run - measured, never printed.
    #
    # Measured correction: the original set was NOT blind to it. Its second
    # pattern, '[A-Za-z0-9]{52}', is unanchored, so a 52-character window inside
    # an 84-character run matched. This scan could fail, and would have. It is
    # widened anyway, because catching an 84-character secret with a
    # 52-character window is an accident of length rather than a property of the
    # pattern: a PAT containing one non-alphanumeric character would break into
    # runs shorter than 52 and slip through.
    #
    # The exclusion is the substantive change. Pass 0013 committed
    # runs/001-fixture-create/create-summary.json, which carries thirty
    # 64-character SHA-256 digests, and documented 40-character git object ids.
    # Both match '[A-Za-z0-9]{52}'. Without the exclusion below, this check goes
    # red on files that contain no secret, and a check that cries wolf is a check
    # that gets switched off. A PAT cannot hide behind the exclusion: 84 is
    # neither 40 nor 64, and a mixed-case token is not lower-hex.
    $patterns = @(
        '[A-Za-z0-9]{52,}'
        '[a-z2-7]{52,}'
        'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
    )
    $hits = [System.Collections.Generic.List[string]]::new()
    foreach ($relative in $tracked) {
        $full = Join-Path $RepoRoot $relative
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { continue }
        $text = Get-Content -LiteralPath $full -Raw -ErrorAction SilentlyContinue
        if (-not $text) { continue }
        $flagged = $false
        foreach ($pattern in $patterns) {
            foreach ($m in [regex]::Matches($text, $pattern)) {
                $v = $m.Value
                # git object id (40) or SHA-256 digest (64), and nothing else.
                if ($v -cmatch '^[0-9a-f]+$' -and ($v.Length -eq 40 -or $v.Length -eq 64)) { continue }
                $flagged = $true
                break
            }
            if ($flagged) { break }
        }
        if ($flagged) { $hits.Add($relative) }
    }
    # The path is reported. The matching text never is.
    Assert-True 'no tracked file contains a PAT-shaped token' ($hits.Count -eq 0) ($hits -join ', ')
    Assert-True 'AzDoPAT.txt is not tracked' ($tracked -notcontains 'AzDoPAT.txt')
    Assert-True 'no tracked file is named like a PAT file' `
    (@($tracked | Where-Object { $_ -match '(^|/)(AzDoPAT\.txt|pat\.txt)$' -or $_ -match '\.pat$' }).Count -eq 0)
}

# ============================================================ result

Write-Host ''
if ($failures.Count -eq 0) {
    Write-Host 'VERIFY: all checks agree.' -ForegroundColor Green
    exit 0
}
Write-Host "VERIFY: $($failures.Count) check(s) disagreed:" -ForegroundColor Red
$failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
exit 1
