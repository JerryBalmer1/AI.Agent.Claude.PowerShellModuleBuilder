#Requires -Version 7.2
<#
.SYNOPSIS
    Create the three fixture repositories in AzDO and push the harness copy.

.DESCRIPTION
    The harness copy under fixture/repos/ is the source of truth; this pushes
    it. Per decision 0011 the AzDO side is a mirror, verified by byte read-back,
    and never edited there.

    Repositories are created and their initial commit pushed with a single
    pushes API call each, so a repository never exists in a half-populated
    state. The three run concurrently.

    **Nothing here queues a build.** Pipeline definitions are created; the
    definition and the run are different objects and only the first is made.

.PARAMETER Fixture
    Which fixture to publish. Defaults to fixture1, so a caller written before
    pass 0034 still points at the three repositories it always pointed at.

.PARAMETER Force
    Push into a repository that already has commits. Off by default: this
    fixture is frozen once its oracle is falsified, and an accidental second
    push is the way that freeze gets broken.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('fixture1', 'fixture2')]
    [string] $Fixture = 'fixture1',

    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'TfAzdoClient.ps1')
Assert-TfAzdoScope

$fixtureRoot = Join-Path $PSScriptRoot ($Fixture -eq 'fixture2' ? 'fixture2/repos' : 'fixture/repos')
$base = Get-TfAzdoBaseUri

function Get-FixtureFile {
    <#
    .SYNOPSIS
        Every file of one fixture repository, as repo-relative forward-slash
        paths with their content.
    .DESCRIPTION
        Content is read as raw text and pushed with LF endings regardless of
        what the working copy holds, because every fixture repository carries
        .gitattributes with `* text=auto eol=lf` and a read-back that compared
        CRLF against LF would report a mismatch that is not one.
    #>
    param([Parameter(Mandatory)] [string] $Root)

    $files = Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
        $text = (Get-Content -LiteralPath $file.FullName -Raw) -replace "`r`n", "`n"
        [pscustomobject]@{ Path = "/$relative"; Content = $text }
    }
}

$jobs = foreach ($name in (Get-TfFixtureRepoName -Fixture $Fixture)) {
    $root = Join-Path $fixtureRoot $name
    if (-not (Test-Path -LiteralPath $root)) { throw "No fixture source for '$name' at $root." }

    $files = @(Get-FixtureFile -Root $root)
    if ($files.Count -eq 0) { throw "'$name' has no files; refusing to create an empty repository." }

    # The commit message is fixture-scoped and comes from the client, because
    # Test-FixtureSanitization.ps1 scans the same function. Decision 0014 puts
    # commit messages in scope: a mute repository whose first commit names the
    # harness has leaked the same thing one `git log` later.
    $comment = Get-TfFixtureCommitMessage -Fixture $Fixture -RepositoryName $name

    if (-not $PSCmdlet.ShouldProcess($name, "create the repository and push $($files.Count) file(s)")) { continue }

    Start-ThreadJob -Name $name -ArgumentList $name, $base, $files, $Force.IsPresent, (Join-Path $PSScriptRoot 'TfAzdoClient.ps1'), $comment -ScriptBlock {
        param($Name, $Base, $Files, $ForcePush, $ClientPath, $Comment)

        . $ClientPath
        $result = [pscustomobject]@{ Name = $Name; Created = $false; Pushed = $false; FileCount = @($Files).Count; CommitId = $null; Detail = '' }

        try {
            $existing = Invoke-TfAzdoJson -Uri "$Base/git/repositories?api-version=7.1"
            $repo = @($existing.value | Where-Object { $_.name -eq $Name }) | Select-Object -First 1

            if (-not $repo) {
                $repo = Invoke-TfAzdoJson -Uri "$Base/git/repositories?api-version=7.1" -Method Post -Body @{ name = $Name }
                $result.Created = $true
            }

            $refs = Invoke-TfAzdoJson -Uri "$Base/git/repositories/$($repo.id)/refs?filter=heads/&api-version=7.1"
            $hasCommits = @($refs.value).Count -gt 0
            if ($hasCommits -and -not $ForcePush) {
                $result.Detail = 'already has commits; not pushed (use -Force)'
                return $result
            }

            $changes = foreach ($file in $Files) {
                @{
                    changeType = 'add'
                    item       = @{ path = $file.Path }
                    newContent = @{ content = $file.Content; contentType = 'rawtext' }
                }
            }

            $push = @{
                refUpdates = @(@{ name = 'refs/heads/main'; oldObjectId = '0000000000000000000000000000000000000000' })
                commits    = @(@{
                        comment = $Comment
                        changes = @($changes)
                    })
            }

            $pushed = Invoke-TfAzdoJson -Uri "$Base/git/repositories/$($repo.id)/pushes?api-version=7.1" -Method Post -Body $push
            $result.Pushed = $true
            $result.CommitId = $pushed.commits[0].commitId
            $result.Detail = "pushed $(@($Files).Count) file(s)"
        }
        catch {
            $result.Detail = "FAILED: $($_.Exception.Message)"
        }
        $result
    }
}

if ($jobs) {
    $results = @(Receive-Job -Job $jobs -Wait -AutoRemoveJob)
    foreach ($result in ($results | Sort-Object Name)) {
        '{0,-20} created={1,-6} pushed={2,-6} files={3,-3} {4} {5}' -f `
            $result.Name, $result.Created, $result.Pushed, $result.FileCount,
        ($result.CommitId ?? ''), $result.Detail
    }
    $failed = @($results | Where-Object { $_.Detail -like 'FAILED*' })
    if ($failed) { throw "$($failed.Count) repository push(es) failed." }
    Write-Host ("{0} repositories, run concurrently on ThreadJob." -f @($results).Count)
}
