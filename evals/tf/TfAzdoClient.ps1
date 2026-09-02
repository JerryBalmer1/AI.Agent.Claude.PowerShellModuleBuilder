<#
    TfAzdoClient.ps1 - Azure DevOps helpers for the Terraform fixture.

    A SEPARATE client from evals/functional/AzdoClient.ps1, deliberately. That
    one refuses to operate against any project but ClaudeTesting, and that guard
    is worth more than the code it duplicates: loosening it so one caller could
    reach a second project would remove the only thing standing between a script
    and the frozen AzDO fixture.

    The PAT is read from $env:AZDO_PAT and nowhere else. It is never written to
    a file, never placed in a URL, never passed as an argument to a child
    process, and never returned by any function here. Only the Authorization
    header carries it.
#>

$script:TfAzdoOrg = 'jlbalmerjr1'
$script:TfAzdoProject = 'ClaudeTestingTerraform'
$script:TfAzdoApi = '7.1'
$script:TfFixtureRepos = @('TfFixtureShared', 'TfFixtureNetwork', 'TfFixtureApp')

# Fixture 2, added by pass 0034 under decision 0014. A SECOND set of three
# repositories in the same project, not a replacement: fixture 1 is frozen and
# stays where it is. Every function below that takes -Fixture defaults to
# fixture1, so no caller written before 0034 changes behaviour.
$script:TfFixture2Repos = @('TfSiteCore', 'TfSiteEdge', 'TfSiteOps')

function Assert-TfAzdoScope {
    <#
    .SYNOPSIS
        Refuses to operate against anything but the Terraform fixture project.
    .DESCRIPTION
        ClaudeTesting is named explicitly in the refusal because it is the
        project this client must never touch, and a guard that only lists what
        is allowed says nothing about what went wrong when it fires.
    #>
    param(
        [string] $Organisation = $script:TfAzdoOrg,
        [string] $Project = $script:TfAzdoProject
    )
    if ($Organisation -cne 'jlbalmerjr1') {
        throw "Refusing to operate: organisation must be 'jlbalmerjr1', got '$Organisation'."
    }
    if ($Project -ceq 'ClaudeTesting') {
        throw "Refusing to operate: ClaudeTesting is the AzDO fixture and is frozen. This client is for ClaudeTestingTerraform only."
    }
    if ($Project -cne 'ClaudeTestingTerraform') {
        throw "Refusing to operate: project must be 'ClaudeTestingTerraform', got '$Project'."
    }
}

function Get-TfAzdoAuthHeader {
    <# Builds the Basic header from $env:AZDO_PAT. Returns a header hashtable,
       never the PAT itself. #>
    if (-not $env:AZDO_PAT) {
        throw "Environment variable AZDO_PAT is not set. Set it at User scope and restart the editor; a profile-set variable is invisible to 'pwsh -NoProfile'."
    }
    $bytes = [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")
    @{ Authorization = 'Basic ' + [Convert]::ToBase64String($bytes) }
}

function Get-TfAzdoBaseUri {
    param([switch] $OrganisationScoped)
    Assert-TfAzdoScope
    if ($OrganisationScoped) { "https://dev.azure.com/$script:TfAzdoOrg/_apis" }
    else { "https://dev.azure.com/$script:TfAzdoOrg/$script:TfAzdoProject/_apis" }
}

function Invoke-TfAzdoJson {
    <#
    .SYNOPSIS
        A REST call returning parsed JSON, with the 203 trap and 429 retry.
    .DESCRIPTION
        Azure DevOps answers an expired or under-scoped PAT with 203 and a
        sign-in page rather than 401, so a caller that only checks for 401
        reports "unexpected JSON" and sends the reader looking in the wrong
        place.

        429 is retried with the Retry-After the service asks for, because a
        fan-out over repositories is exactly the shape that earns one.
    #>
    param(
        [Parameter(Mandatory)] [string] $Uri,
        [string] $Method = 'Get',
        $Body,
        [int] $MaxAttempts = 5
    )

    $headers = Get-TfAzdoAuthHeader
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        $params = @{
            Uri                = $Uri
            Headers            = $headers
            Method             = $Method
            MaximumRedirection = 0
            SkipHttpErrorCheck = $true
            ErrorAction        = 'Stop'
        }
        if ($null -ne $Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 30 -Compress)
            $params.ContentType = 'application/json'
        }

        $response = Invoke-WebRequest @params

        if ($response.StatusCode -eq 203) {
            throw "Azure DevOps returned 203 (a sign-in page, not JSON) for $Uri. The PAT is expired or lacks the required scope."
        }
        if ($response.StatusCode -eq 429) {
            $wait = 5
            if ($response.Headers['Retry-After']) { $wait = [int]($response.Headers['Retry-After'] | Select-Object -First 1) }
            Write-Warning "429 from Azure DevOps; waiting $wait s (attempt $attempt of $MaxAttempts)."
            Start-Sleep -Seconds $wait
            continue
        }
        if ($response.StatusCode -ge 400) {
            throw "Azure DevOps returned HTTP $($response.StatusCode) for $Method $Uri : $($response.Content)"
        }

        if ([string]::IsNullOrWhiteSpace($response.Content)) { return $null }
        return $response.Content | ConvertFrom-Json
    }

    throw "Azure DevOps kept returning 429 for $Uri after $MaxAttempts attempts."
}

function Get-TfFixtureRepoName {
    <#
    .SYNOPSIS
        The three repositories a fixture is, stated once.
    .DESCRIPTION
        Defaults to fixture 1, so every caller written before pass 0034 keeps
        the behaviour it had.
    #>
    param([ValidateSet('fixture1', 'fixture2')] [string] $Fixture = 'fixture1')
    if ($Fixture -eq 'fixture2') { return $script:TfFixture2Repos }
    $script:TfFixtureRepos
}

function Get-TfFixtureCommitMessage {
    <#
    .SYNOPSIS
        The message a fixture repository's initial commit carries.
    .DESCRIPTION
        Stated here rather than at the push site because two things read it:
        Publish-TfFixture.ps1, which pushes with it, and
        Test-FixtureSanitization.ps1, which scans it. Decision 0014 puts commit
        messages in scope for sanitization — a repository whose files say
        nothing and whose first commit says "Terraform fixture for
        PSTerraformGraph scoring" has leaked the same thing one `git log`
        later — and a message the scanner cannot see is a message the gate does
        not cover.

        Fixture 1's message is reproduced verbatim from what pass 0023 pushed.
        It is frozen and this function does not get to improve it.
    #>
    param(
        [Parameter(Mandatory)] [ValidateSet('fixture1', 'fixture2')] [string] $Fixture,
        [Parameter(Mandatory)] [string] $RepositoryName
    )
    if ($Fixture -eq 'fixture2') { return "Add the $RepositoryName configuration." }
    "Terraform fixture for PSTerraformGraph scoring. Authored in the harness at evals/tf/fixture/repos/$RepositoryName and pushed by pass 0023; that copy is the source of truth."
}
