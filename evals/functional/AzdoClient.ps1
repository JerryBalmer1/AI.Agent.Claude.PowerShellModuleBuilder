<#
    AzdoClient.ps1 - shared Azure DevOps helpers for the functional fixture.

    Dot-sourced by ReadBack.Tests.ps1, Sync-Fixture.ps1 and verify.ps1. It is a
    dot-sourced helper rather than functions declared in the test file because a
    top-level `function` in a Pester 6.1.0 test file breaks every `BeforeAll` in
    that file, reporting a misleading loop-label error.

    The PAT is read from $env:AZDO_PAT and nowhere else. It is never written to
    a file, never placed in a URL, never passed as an argument to a child
    process, and never returned by any function here. Only the Authorization
    header carries it.
#>

$script:AzdoOrg     = 'jlbalmerjr1'
$script:AzdoProject = 'ClaudeTesting'
$script:AzdoApi     = '7.1'

function Assert-AzdoScope {
    <# Refuses to operate against any organisation or project but the fixture's. #>
    param([string]$Organisation = $script:AzdoOrg, [string]$Project = $script:AzdoProject)
    if ($Organisation -cne 'jlbalmerjr1') {
        throw "Refusing to operate: organisation must be 'jlbalmerjr1', got '$Organisation'."
    }
    if ($Project -cne 'ClaudeTesting') {
        throw "Refusing to operate: project must be 'ClaudeTesting', got '$Project'."
    }
}

function Get-AzdoAuthHeader {
    <# Builds the Basic header from $env:AZDO_PAT. Returns a header hashtable,
       never the PAT itself. #>
    if (-not $env:AZDO_PAT) {
        throw "Environment variable AZDO_PAT is not set. Set it at User scope and restart the editor; a profile-set variable is invisible to 'pwsh -NoProfile'."
    }
    $bytes = [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")
    @{ Authorization = 'Basic ' + [Convert]::ToBase64String($bytes) }
}

function Get-AzdoBaseUri {
    param([switch]$ProjectScoped)
    if ($ProjectScoped) { "https://dev.azure.com/$script:AzdoOrg/$script:AzdoProject/_apis" }
    else                { "https://dev.azure.com/$script:AzdoOrg/_apis" }
}

function Invoke-AzdoJson {
    <# GET/POST/PUT returning parsed JSON. Detects the 203 sign-in page, which
       Azure DevOps returns instead of 401 when a PAT is expired or
       under-scoped. #>
    param(
        [Parameter(Mandatory)][string]$Uri,
        [string]$Method = 'Get',
        $Body
    )
    $headers = Get-AzdoAuthHeader
    $params = @{
        Uri                = $Uri
        Headers            = $headers
        Method             = $Method
        MaximumRedirection = 0
        SkipHttpErrorCheck = $true
        ErrorAction        = 'Stop'
    }
    if ($null -ne $Body) {
        $params.Body        = ($Body | ConvertTo-Json -Depth 20 -Compress)
        $params.ContentType = 'application/json'
    }
    $resp = Invoke-WebRequest @params
    if ($resp.StatusCode -eq 203) {
        throw "Azure DevOps returned 203 (a sign-in page, not JSON) for $Uri. The PAT is expired or lacks the required scope. See evals/functional/TROUBLESHOOTING.md."
    }
    if ($resp.StatusCode -ge 400) {
        throw "HTTP $($resp.StatusCode) for $Uri : $($resp.Content)"
    }
    if (-not $resp.Content) { return $null }
    $resp.Content | ConvertFrom-Json
}

function Get-AzdoRepository {
    <# All repositories in the project, or just the named one if -Name is given
       (and $null when that name is absent). #>
    param([string]$Name)
    $all = (Invoke-AzdoJson -Uri "$(Get-AzdoBaseUri -ProjectScoped)/git/repositories?api-version=$script:AzdoApi").value
    if ($Name) { return ($all | Where-Object { $_.name -ceq $Name }) }
    $all
}

function Get-AzdoRepoItem {
    <# Every blob path on a branch, as repo-relative paths with no leading
       slash. Returns an empty array for an empty repository, which has no
       branch and so answers 404. #>
    param([Parameter(Mandatory)][string]$RepositoryId, [string]$Branch = 'main')
    $uri = "$(Get-AzdoBaseUri -ProjectScoped)/git/repositories/$RepositoryId/items" +
           "?recursionLevel=Full&versionDescriptor.versionType=branch" +
           "&versionDescriptor.version=$Branch&api-version=$script:AzdoApi"
    try { $r = Invoke-AzdoJson -Uri $uri } catch { return @() }
    if (-not $r) { return @() }
    if ($r.PSObject.Properties.Name -notcontains 'value') { return @() }
    @($r.value |
        Where-Object { $_.gitObjectType -eq 'blob' } |
        ForEach-Object { $_.path.TrimStart('/') })
}

function Get-AzdoFileBytes {
    <# Raw bytes of one file on a branch. Uses HttpClient and ReadAsByteArrayAsync
       so nothing decodes the body to a string or translates line endings. This
       is the read path for read-back assertion 3; see AZDO-FIXTURE.md, "How
       assertion 3 compares bytes". #>
    param(
        [Parameter(Mandatory)][string]$RepositoryId,
        [Parameter(Mandatory)][string]$Path,
        [string]$Branch = 'main'
    )
    $enc = [Uri]::EscapeDataString("/$($Path.TrimStart('/'))")
    $uri = "$(Get-AzdoBaseUri -ProjectScoped)/git/repositories/$RepositoryId/items" +
           "?path=$enc&versionDescriptor.versionType=branch&versionDescriptor.version=$Branch" +
           "&download=true&`$format=octetStream&api-version=$script:AzdoApi"
    $client = [Net.Http.HttpClient]::new()
    try {
        $client.DefaultRequestHeaders.Authorization =
            [Net.Http.Headers.AuthenticationHeaderValue]::new(
                'Basic',
                [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")))
        $resp = $client.GetAsync($uri).GetAwaiter().GetResult()
        if ([int]$resp.StatusCode -eq 203) {
            throw "203 sign-in page fetching '$Path'. PAT expired or under-scoped."
        }
        if (-not $resp.IsSuccessStatusCode) {
            throw "HTTP $([int]$resp.StatusCode) fetching '$Path' from repository $RepositoryId"
        }
        $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
    }
    finally { $client.Dispose() }
}

function Get-AzdoDefinition {
    <# Build definitions in the project. -Full expands each one, because the
       list endpoint returns neither process.yamlFilename nor repository.name. #>
    param([switch]$Full)
    $list = (Invoke-AzdoJson -Uri "$(Get-AzdoBaseUri -ProjectScoped)/build/definitions?api-version=$script:AzdoApi").value
    if (-not $Full) { return $list }
    if (-not $list) { return @() }
    @($list | ForEach-Object {
        Invoke-AzdoJson -Uri "$(Get-AzdoBaseUri -ProjectScoped)/build/definitions/$($_.id)?api-version=$script:AzdoApi"
    })
}

function Get-AzdoBuildCount {
    <# Number of builds ever recorded for a definition. Read-only: this never
       queues anything. Assertion 7 requires zero for all fifteen. #>
    param([Parameter(Mandatory)][int]$DefinitionId)
    $uri = "$(Get-AzdoBaseUri -ProjectScoped)/build/builds?definitions=$DefinitionId&api-version=$script:AzdoApi"
    $r = Invoke-AzdoJson -Uri $uri
    if (-not $r) { return 0 }
    [int]$r.count
}

function Get-FixtureRoot {
    <# Root of the committed fixture, resolved from this file's own location so
       it works from any working directory. #>
    Join-Path $PSScriptRoot 'fixture'
}

function Get-FixtureSpec {
    <# Parses evals/functional/AZDO-FIXTURE.md and returns the fixture's declared
       shape. Parsed rather than duplicated: a second copy of the definition
       table inside a script is hazard 6 - a stale expectation reporting the
       wrong answer confidently - and nothing would make the two agree again. #>
    $doc = Join-Path $PSScriptRoot 'AZDO-FIXTURE.md'
    if (-not (Test-Path $doc)) { throw "AZDO-FIXTURE.md not found at $doc" }
    $lines = [IO.File]::ReadAllLines($doc)

    # Definitions table rows:  | n | `name` | `repo` | `path` |
    $defs = foreach ($l in $lines) {
        if ($l -match '^\|\s*(\d+)\s*\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|\s*`([^`]+)`\s*\|\s*$') {
            [pscustomobject]@{
                Order      = [int]$Matches[1]
                Name       = $Matches[2]
                Repository = $Matches[3]
                YamlPath   = $Matches[4]
            }
        }
    }

    # File-count table rows:  | `name` | 21 |
    $repos = foreach ($l in $lines) {
        if ($l -match '^\|\s*`([^`]+)`\s*\|\s*(\d+)\s*\|\s*$') {
            [pscustomobject]@{ Name = $Matches[1]; FileCount = [int]$Matches[2] }
        }
    }

    [pscustomobject]@{
        Organisation = $script:AzdoOrg
        Project      = $script:AzdoProject
        Repositories = @($repos)
        Definitions  = @($defs | Sort-Object Order)
    }
}

function Get-CommittedFixtureFile {
    <# The committed fixture as {Repository, Path, FullName}. Path is
       repo-relative with forward slashes, matching Azure DevOps item paths. #>
    $reposDir = Join-Path (Get-FixtureRoot) 'repos'
    if (-not (Test-Path $reposDir)) { throw "Fixture repos directory not found at $reposDir" }
    foreach ($repoDir in (Get-ChildItem -LiteralPath $reposDir -Directory | Sort-Object Name)) {
        foreach ($f in (Get-ChildItem -LiteralPath $repoDir.FullName -Recurse -File | Sort-Object FullName)) {
            $rel = $f.FullName.Substring($repoDir.FullName.Length + 1) -replace '\\', '/'
            [pscustomobject]@{
                Repository = $repoDir.Name
                Path       = $rel
                FullName   = $f.FullName
            }
        }
    }
}

function Get-Sha256Hex {
    <# SHA-256 over raw bytes. Both sides of assertion 3 go through this. #>
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
