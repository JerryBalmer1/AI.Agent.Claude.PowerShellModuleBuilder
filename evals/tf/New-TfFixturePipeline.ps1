#Requires -Version 7.2
<#
.SYNOPSIS
    Create the fixture's pipeline definitions. Never queues one.

.DESCRIPTION
    Five definitions across the three repositories, pinning four distinct
    Terraform versions. They exist so a producer has pipeline YAML to find and
    a version pin to read; nothing about this fixture is ever run.

    **A definition and a run are different objects.** This calls the
    definitions endpoint and nothing else. There is no queue call in this file,
    and `Assert-NoBuildsQueued` is the check that says so afterwards rather than
    a claim in a comment.

.PARAMETER Force
    Recreate a definition that already exists. Off by default.
#>
[CmdletBinding(SupportsShouldProcess)]
param([switch] $Force)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'TfAzdoClient.ps1')
Assert-TfAzdoScope

$base = Get-TfAzdoBaseUri

# Read from the fixture rather than listed here, so a pipeline added to a
# repository cannot be missed by a list nobody updated.
$definitions = foreach ($repo in (Get-TfFixtureRepoName)) {
    $pipelineDir = Join-Path $PSScriptRoot "fixture/repos/$repo/pipelines"
    if (-not (Test-Path -LiteralPath $pipelineDir)) { continue }
    foreach ($file in (Get-ChildItem -LiteralPath $pipelineDir -Filter *.yml -File | Sort-Object Name)) {
        [pscustomobject]@{
            Repo = $repo
            Name = "$repo-$($file.BaseName)"
            Yaml = "pipelines/$($file.Name)"
        }
    }
}

$repos = (Invoke-TfAzdoJson -Uri "$base/git/repositories?api-version=7.1").value
$existing = (Invoke-TfAzdoJson -Uri "$base/build/definitions?api-version=7.1").value

$created = 0
foreach ($definition in $definitions) {
    $repo = @($repos | Where-Object { $_.name -eq $definition.Repo }) | Select-Object -First 1
    if (-not $repo) { throw "Repository '$($definition.Repo)' does not exist; create it before its pipelines." }

    if (@($existing | Where-Object { $_.name -eq $definition.Name }).Count -gt 0 -and -not $Force) {
        '{0,-40} exists, skipped' -f $definition.Name
        continue
    }

    if (-not $PSCmdlet.ShouldProcess($definition.Name, "create a pipeline DEFINITION from $($definition.Yaml) (never queued)")) { continue }

    $body = @{
        name       = $definition.Name
        type       = 'build'
        quality    = 'definition'
        repository = @{
            id            = $repo.id
            name          = $definition.Repo
            type          = 'TfsGit'
            defaultBranch = 'refs/heads/main'
        }
        process    = @{
            type         = 2
            yamlFilename = $definition.Yaml
        }
        queue      = @{ name = 'Azure Pipelines' }
        # trigger: none is already in every YAML. Stated here too, because the
        # definition's own triggers are what a service uses if the YAML is ever
        # replaced, and this fixture must never run.
        triggers   = @()
    }

    $result = Invoke-TfAzdoJson -Uri "$base/build/definitions?api-version=7.1" -Method Post -Body $body
    '{0,-40} created id={1} yaml={2}' -f $definition.Name, $result.id, $definition.Yaml
    $created++
}

Write-Host "$created definition(s) created. No build was queued: this script has no queue call."
