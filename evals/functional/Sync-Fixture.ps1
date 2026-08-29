<#
.SYNOPSIS
    Creates the Azure DevOps functional fixture from the committed files.

.DESCRIPTION
    One script performs all creation, so a transcript carries one invocation
    rather than forty-five REST calls each bearing an Authorization header.

    WHAT IT DOES
      1. Asserts the organisation is jlbalmerjr1 and the project ClaudeTesting.
      2. Creates the four fixture repositories, skipping any that exist.
      3. Pushes fixture/repos/<name>/ to main in each, one commit per repository.
      4. Creates the fifteen pipeline definitions, p0* before x0*.
      5. Writes runs/001-fixture-create/create-summary.json.

    WHAT IT NEVER DOES
      It never queues, triggers or runs a pipeline, and issues no POST to any
      builds endpoint. It never touches the pre-existing ClaudeTesting
      repository. It never writes the PAT anywhere.

    THE PAT
      Read from $env:AZDO_PAT and nowhere else - not a parameter, not a file,
      not a default. It travels only in an Authorization header. It is never
      logged, never written to a file, never placed in a remote URL, and never
      passed as an argument to a child process. That last constraint is why
      files are pushed through the Git Pushes REST API rather than by shelling
      out to `git push`, which would need the PAT inside a remote URL where it
      would land in the reflog and in any process listing.

    ORDER
      All four repositories are pushed before any definition exists. p01.yml and
      azure-pipelines.yml declare `trigger: - main`, so a push landing after
      their definitions existed would queue a run. Creating definitions last
      means there is nothing to trigger. As a second guard, every push comment
      carries ***NO_CI***, which matters on a re-run against a half-built
      fixture where some definitions already exist.

    BYTES
      Files are pushed exactly as committed: read with [IO.File]::ReadAllBytes
      and base64-encoded, never read as text and never re-encoded. The fixture
      is canonically UTF-8 without BOM, LF-only, with a final newline; see
      AZDO-FIXTURE.md, "How assertion 3 compares bytes".

.PARAMETER DryRun
    Report exactly what would be created and change nothing.

.EXAMPLE
    pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1 -DryRun
    pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$SummaryPath
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'AzdoClient.ps1')

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).ProviderPath
if (-not $SummaryPath) {
    $SummaryPath = Join-Path $RepoRoot 'runs' '001-fixture-create' 'create-summary.json'
}

$EmptyObjectId = '0000000000000000000000000000000000000000'

function Write-Step { param([string]$Message) Write-Host $Message }

function New-AzdoRepository {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$ProjectId)
    Invoke-AzdoJson -Method Post `
        -Uri "$(Get-AzdoBaseUri -ProjectScoped)/git/repositories?api-version=$script:AzdoApi" `
        -Body @{ name = $Name; project = @{ id = $ProjectId } }
}

function Push-AzdoFixtureFile {
    <# One commit adding every file for a repository, on refs/heads/main.
       oldObjectId is the all-zero id, which is how the API expresses "this
       branch does not exist yet". #>
    param(
        [Parameter(Mandatory)][string]$RepositoryId,
        [Parameter(Mandatory)][array]$Files
    )
    $changes = foreach ($f in $Files) {
        $bytes = [IO.File]::ReadAllBytes($f.FullName)
        @{
            changeType = 'add'
            item       = @{ path = "/$($f.Path)" }
            newContent = @{
                content     = [Convert]::ToBase64String($bytes)
                contentType = 'base64encoded'
            }
        }
    }
    $body = @{
        refUpdates = @(@{ name = 'refs/heads/main'; oldObjectId = $EmptyObjectId })
        commits    = @(@{
            comment = 'Functional fixture, pushed by Sync-Fixture.ps1 ***NO_CI***'
            changes = @($changes)
        })
    }
    Invoke-AzdoJson -Method Post `
        -Uri "$(Get-AzdoBaseUri -ProjectScoped)/git/repositories/$RepositoryId/pushes?api-version=$script:AzdoApi" `
        -Body $body
}

function Get-AzdoDefaultQueue {
    <# The project's existing hosted queue. Referenced, never modified: no pool
       is created, resized or converted, and nothing self-hosted is touched. #>
    try {
        $q = Invoke-AzdoJson -Uri "$(Get-AzdoBaseUri -ProjectScoped)/distributedtask/queues?api-version=$script:AzdoApi-preview.1"
        if ($q -and $q.value) {
            $hosted = $q.value | Where-Object { $_.name -match 'Azure Pipelines' } | Select-Object -First 1
            if ($hosted) { return $hosted }
            return ($q.value | Select-Object -First 1)
        }
    }
    catch {
        Write-Step "    note: could not list queues ($($_.Exception.Message.Split([char]10)[0])); creating definition without an explicit queue"
    }
    $null
}

function New-AzdoDefinition {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Repository,
        [Parameter(Mandatory)][string]$YamlPath,
        $Queue
    )
    $body = @{
        name       = $Name
        type       = 'build'
        quality    = 'definition'
        path       = '\'
        repository = @{
            id            = $Repository.id
            name          = $Repository.name
            type          = 'TfsGit'
            defaultBranch = 'refs/heads/main'
       }
        process    = @{ type = 2; yamlFilename = $YamlPath }
    }
    if ($Queue) { $body.queue = @{ id = $Queue.id } }

    Invoke-AzdoJson -Method Post `
        -Uri "$(Get-AzdoBaseUri -ProjectScoped)/build/definitions?api-version=$script:AzdoApi" `
        -Body $body
}

# ---------------------------------------------------------------- preflight --

Assert-AzdoScope
if (-not $env:AZDO_PAT) {
    throw 'Environment variable AZDO_PAT is not set. Set it at User scope and restart the editor; a variable set in a profile is invisible to "pwsh -NoProfile". See evals/functional/TROUBLESHOOTING.md.'
}

$mode = if ($DryRun) { 'DRY RUN - nothing will be created' } else { 'LIVE' }
Write-Step "Sync-Fixture: $mode"
Write-Step "  organisation : $script:AzdoOrg"
Write-Step "  project      : $script:AzdoProject"
Write-Step "  AZDO_PAT     : set, length $($env:AZDO_PAT.Length) (value never read, logged or written)"

$project = Invoke-AzdoJson -Uri "$(Get-AzdoBaseUri)/projects/$script:AzdoProject`?api-version=$script:AzdoApi"
Write-Step "  project id   : $($project.id)"

$spec = Get-FixtureSpec
$committed = @(Get-CommittedFixtureFile)
Write-Step "  declared     : $($spec.Repositories.Count) repositories, $($spec.Definitions.Count) definitions"
Write-Step "  committed    : $($committed.Count) files"
Write-Step ''

$summary = [ordered]@{
    organisation = $script:AzdoOrg
    project      = $script:AzdoProject
    projectId    = $project.id
    timestampUtc = (Get-Date).ToUniversalTime().ToString('o')
    dryRun       = [bool]$DryRun
    repositories = @()
    files        = @()
    definitions  = @()
}

# ------------------------------------------------------- 1. repositories -----

Write-Step '== Repositories =='
$existingRepos = @{}
foreach ($r in @(Get-AzdoRepository)) { $existingRepos[$r.name] = $r }

$repoObjects = @{}
foreach ($declared in $spec.Repositories) {
    $name = $declared.Name
    if ($existingRepos.ContainsKey($name)) {
        $repo = $existingRepos[$name]
        Write-Step "  already present : $name (id $($repo.id))"
        $repoObjects[$name] = $repo
        $summary.repositories += [ordered]@{ name = $name; id = $repo.id; action = 'already-present' }
    }
    elseif ($DryRun) {
        Write-Step "  WOULD CREATE    : $name"
        $summary.repositories += [ordered]@{ name = $name; id = $null; action = 'would-create' }
    }
    else {
        $repo = New-AzdoRepository -Name $name -ProjectId $project.id
        Write-Step "  created         : $name (id $($repo.id))"
        $repoObjects[$name] = $repo
        $summary.repositories += [ordered]@{ name = $name; id = $repo.id; action = 'created' }
    }
}
Write-Step ''

# --------------------------------------------------------------- 2. files ----

Write-Step '== Files =='
foreach ($declared in $spec.Repositories) {
    $name = $declared.Name
    $files = @($committed | Where-Object { $_.Repository -ceq $name } | Sort-Object Path)

    if ($DryRun -and -not $repoObjects.ContainsKey($name)) {
        Write-Step "  WOULD PUSH      : $($files.Count) files to $name (repository would be created first)"
        foreach ($f in $files) {
            $bytes = [IO.File]::ReadAllBytes($f.FullName)
            $summary.files += [ordered]@{
                repository = $name; path = $f.Path; bytes = $bytes.Length
                sha256 = (Get-Sha256Hex -Bytes $bytes); action = 'would-push'
            }
        }
        continue
    }

    $repo = $repoObjects[$name]
    $remote = @(Get-AzdoRepoItem -RepositoryId $repo.id -Branch 'main')

    if ($remote.Count -gt 0) {
        Write-Step "  already present : $name holds $($remote.Count) files on main; not pushing"
        foreach ($f in $files) {
            $bytes = [IO.File]::ReadAllBytes($f.FullName)
            $summary.files += [ordered]@{
                repository = $name; path = $f.Path; bytes = $bytes.Length
                sha256 = (Get-Sha256Hex -Bytes $bytes); action = 'already-present'
            }
        }
        continue
    }

    if ($DryRun) {
        Write-Step "  WOULD PUSH      : $($files.Count) files to $name on refs/heads/main"
        foreach ($f in $files) {
            $bytes = [IO.File]::ReadAllBytes($f.FullName)
            $summary.files += [ordered]@{
                repository = $name; path = $f.Path; bytes = $bytes.Length
                sha256 = (Get-Sha256Hex -Bytes $bytes); action = 'would-push'
            }
        }
        continue
    }

    $push = Push-AzdoFixtureFile -RepositoryId $repo.id -Files $files
    Write-Step "  pushed          : $($files.Count) files to $name on refs/heads/main (commit $($push.commits[0].commitId.Substring(0,10)))"
    foreach ($f in $files) {
        $bytes = [IO.File]::ReadAllBytes($f.FullName)
        $summary.files += [ordered]@{
            repository = $name; path = $f.Path; bytes = $bytes.Length
            sha256 = (Get-Sha256Hex -Bytes $bytes); action = 'pushed'
        }
    }
}
Write-Step ''

# --------------------------------------------------------- 3. definitions ----

Write-Step '== Definitions =='
Write-Step '  (created last, so that no push can trigger one)'

$existingDefs = @{}
foreach ($d in @(Get-AzdoDefinition)) { $existingDefs[$d.name] = $d }

$queue = $null
if (-not $DryRun) { $queue = Get-AzdoDefaultQueue }

# Refresh repository handles: a repository created above needs its id here.
if (-not $DryRun) {
    foreach ($r in @(Get-AzdoRepository)) { $repoObjects[$r.name] = $r }
}

foreach ($def in $spec.Definitions) {
    if ($existingDefs.ContainsKey($def.Name)) {
        $d = $existingDefs[$def.Name]
        Write-Step "  already present : $($def.Name) (id $($d.id))"
        $summary.definitions += [ordered]@{
            name = $def.Name; id = $d.id; repository = $def.Repository
            yamlPath = $def.YamlPath; action = 'already-present'
        }
        continue
    }

    if ($DryRun) {
        Write-Step "  WOULD CREATE    : $($def.Name) -> $($def.Repository)/$($def.YamlPath)"
        $summary.definitions += [ordered]@{
            name = $def.Name; id = $null; repository = $def.Repository
            yamlPath = $def.YamlPath; action = 'would-create'
        }
        continue
    }

    $repo = $repoObjects[$def.Repository]
    if (-not $repo) { throw "Repository '$($def.Repository)' not found; cannot create definition '$($def.Name)'." }

    $created = New-AzdoDefinition -Name $def.Name -Repository $repo -YamlPath $def.YamlPath -Queue $queue
    Write-Step "  created         : $($def.Name) (id $($created.id)) -> $($def.Repository)/$($def.YamlPath)"
    $summary.definitions += [ordered]@{
        name = $def.Name; id = $created.id; repository = $def.Repository
        yamlPath = $def.YamlPath; action = 'created'
    }
}
Write-Step ''

# ------------------------------------------------------------- 4. summary ----

$summary.counts = [ordered]@{
    repositories = @($summary.repositories).Count
    files        = @($summary.files).Count
    definitions  = @($summary.definitions).Count
    reposCreated = @($summary.repositories | Where-Object { $_.action -eq 'created' }).Count
    filesPushed  = @($summary.files       | Where-Object { $_.action -eq 'pushed' }).Count
    defsCreated  = @($summary.definitions | Where-Object { $_.action -eq 'created' }).Count
}

Write-Step '== Summary =='
Write-Step "  repositories : $($summary.counts.repositories) declared, $($summary.counts.reposCreated) created this run"
Write-Step "  files        : $($summary.counts.files) declared, $($summary.counts.filesPushed) pushed this run"
Write-Step "  definitions  : $($summary.counts.definitions) declared, $($summary.counts.defsCreated) created this run"

if ($DryRun) {
    Write-Step ''
    Write-Step 'DRY RUN complete. Nothing was created and no summary was written.'
    return
}

$summaryDir = Split-Path -Parent $SummaryPath
if (-not (Test-Path $summaryDir)) { New-Item -ItemType Directory -Path $summaryDir -Force | Out-Null }
# Written with explicit LF newlines and no BOM. Set-Content would emit CRLF
# on Windows, which .gitattributes then normalises on commit, leaving the
# working tree and the blob disagreeing about a file this script produced.
$json = ($summary | ConvertTo-Json -Depth 10) -replace "`r`n", "`n"
[IO.File]::WriteAllText($SummaryPath, $json + "`n", [Text.UTF8Encoding]::new($false))
Write-Step "  summary      : $SummaryPath"
