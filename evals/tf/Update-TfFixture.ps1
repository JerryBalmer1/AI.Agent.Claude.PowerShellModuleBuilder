#Requires -Version 7.2
<#
.SYNOPSIS
    Push an AUTHORISED amendment of the harness fixture copy to AzDO, as an
    edit on top of what is already there.

.DESCRIPTION
    Publish-TfFixture.ps1 creates a repository and pushes its FIRST commit; its
    refUpdate carries an all-zero oldObjectId and it cannot amend anything. That
    limit is deliberate and stays. This is the separate, louder path for the one
    case decision 0011 provides for: a fixture change authorised by a new
    decision.

    It refuses to run without -Decision naming a decision file that exists, and
    the decision number goes in the commit message, because a fixture commit
    whose message does not say which decision permitted it is indistinguishable
    from an accident.

    The remote side is read by CLONING, the same way Test-TfFixtureReadBack.ps1
    reads it - a clone is the artifact whose bytes the read-back will later
    compare, so computing the change set from anything else would be comparing
    against a different thing from the one being verified. The change set is
    then file by file:

      add     present in the harness copy, absent on the remote
      edit    present on both, content differs
      delete  present on the remote, absent from the harness copy

    A repository with no differences is not pushed and says so. Content is
    normalised to LF, as Publish-TfFixture and Test-TfFixtureReadBack both do,
    because every fixture repository carries .gitattributes with
    `* text=auto eol=lf`.

    The push itself goes through the REST pushes API against the head the clone
    observed, so a concurrent write loses the race rather than being silently
    overwritten. The PAT travels in a header and never in a URL.

    **Nothing here queues a build.**

.PARAMETER Decision
    The decision authorising this amendment, e.g. 0012. Mandatory.

.PARAMETER Message
    One line saying what changed. Mandatory; it goes in the commit message.

.EXAMPLE
    ./Update-TfFixture.ps1 -Decision 0012 -Message 'Case 3 gains a mechanical cross-repository tie.'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^\d{4}$')]
    [string] $Decision,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Message
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'TfAzdoClient.ps1')
Assert-TfAzdoScope

$decisionMatch = @(Get-ChildItem -Path (Join-Path $PSScriptRoot '../../decisions') -Filter "$Decision-*.md" -File -ErrorAction SilentlyContinue)
if ($decisionMatch.Count -eq 0) {
    throw "No decision file matches 'decisions/$Decision-*.md'. A fixture amendment requires a committed decision authorising it - decision 0011."
}
Write-Host "Authorised by $($decisionMatch[0].Name)."

$fixtureRoot = Join-Path $PSScriptRoot 'fixture/repos'
$base = Get-TfAzdoBaseUri
$workRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('tf-update-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$null = New-Item -ItemType Directory -Path $workRoot -Force

function Get-TreeText {
    <# Repo-relative forward-slash paths to LF-normalised content. #>
    param([Parameter(Mandatory)] [string] $Root)
    $map = [ordered]@{}
    foreach ($file in (Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
        if ($relative -like '.git/*' -or $relative -eq '.git') { continue }
        $map["/$relative"] = [System.IO.File]::ReadAllText($file.FullName) -replace "`r`n", "`n"
    }
    $map
}

$results = [System.Collections.Generic.List[object]]::new()

try {
    foreach ($name in (Get-TfFixtureRepoName)) {
        $root = Join-Path $fixtureRoot $name
        if (-not (Test-Path -LiteralPath $root)) { throw "No fixture source for '$name' at $root." }

        $repos = Invoke-TfAzdoJson -Uri "$base/git/repositories?api-version=7.1"
        $repo = @($repos.value | Where-Object { $_.name -eq $name }) | Select-Object -First 1
        if (-not $repo) { throw "Repository '$name' does not exist. Use Publish-TfFixture.ps1 to create it." }

        $clone = Join-Path $workRoot $name
        $uri = "https://dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/$name"
        $bytes = [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")
        $auth = 'Authorization: Basic ' + [Convert]::ToBase64String($bytes)
        & git -c "http.extraHeader=$auth" clone --quiet $uri $clone 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "clone of $name failed with exit $LASTEXITCODE" }
        $head = (& git -C $clone rev-parse HEAD).Trim()

        $harness = Get-TreeText -Root $root
        $remote = Get-TreeText -Root $clone
        $changes = [System.Collections.Generic.List[object]]::new()

        foreach ($path in $harness.Keys) {
            if (-not $remote.Contains($path)) {
                $changes.Add(@{ changeType = 'add'; item = @{ path = $path }; newContent = @{ content = $harness[$path]; contentType = 'rawtext' } })
            }
            elseif ($remote[$path] -ne $harness[$path]) {
                $changes.Add(@{ changeType = 'edit'; item = @{ path = $path }; newContent = @{ content = $harness[$path]; contentType = 'rawtext' } })
            }
        }
        foreach ($path in $remote.Keys) {
            if (-not $harness.Contains($path)) {
                $changes.Add(@{ changeType = 'delete'; item = @{ path = $path } })
            }
        }

        if ($changes.Count -eq 0) {
            $results.Add([pscustomobject]@{ Name = $name; Changes = 0; CommitId = $head; Detail = 'no differences; not pushed' })
            continue
        }

        $summary = (@($changes | Group-Object { $_.changeType } | Sort-Object Name | ForEach-Object { "$($_.Count) $($_.Name)" })) -join ', '
        if (-not $PSCmdlet.ShouldProcess($name, "push $($changes.Count) change(s) on $head : $summary")) { continue }

        $push = @{
            refUpdates = @(@{ name = 'refs/heads/main'; oldObjectId = $head })
            commits    = @(@{
                    comment = "Fixture amendment authorised by decision $Decision. $Message The harness copy at evals/tf/fixture/repos/$name remains the source of truth."
                    changes = @($changes)
                })
        }
        $pushed = Invoke-TfAzdoJson -Uri "$base/git/repositories/$($repo.id)/pushes?api-version=7.1" -Method Post -Body $push

        $results.Add([pscustomobject]@{ Name = $name; Changes = $changes.Count; CommitId = $pushed.commits[0].commitId; Detail = $summary })
    }
}
finally {
    if (Test-Path -LiteralPath $workRoot) { Remove-Item -LiteralPath $workRoot -Recurse -Force -ErrorAction SilentlyContinue }
}

foreach ($result in ($results | Sort-Object Name)) {
    '{0,-20} changes={1,-3} {2}  {3}' -f $result.Name, $result.Changes, $result.CommitId, $result.Detail
}
