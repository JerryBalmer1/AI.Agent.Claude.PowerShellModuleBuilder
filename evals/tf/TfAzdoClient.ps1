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
    <# The three repositories this fixture is, stated once. #>
    $script:TfFixtureRepos
}
