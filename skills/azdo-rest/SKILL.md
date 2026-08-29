---
name: azdo-rest
description: Call the Azure DevOps REST API from PowerShell read-only — PAT from $env:AZDO_PAT only, never a parameter and never in a URL, paged GETs against dev.azure.com/{org}/{project}/_apis. Use when a module reads repositories, pipeline definitions, or file content from Azure DevOps.
---

# Azure DevOps REST, read-only

## The credential rule

The PAT comes from `$env:AZDO_PAT` and from nowhere else.

**Never a parameter.** Not `-Pat`, not `-Token`, not `-Credential` with a
default that reads the variable. A value passed as a parameter ends up in
`PSReadLine` history, in `Start-Transcript` output, and in the
`ScriptBlock` logging event log. A PAT is a bearer credential for an entire
organisation, so the blast radius of one pasted issue is the whole org.

**Never a file.** Do not look for `~/.azdo`, do not accept a `-PatPath`, do not
fall back to anything. `.gitignore` should carry `*.pat`, `**/pat.txt` and
similar patterns to make the mistake harder — those patterns exist to block an
accident, not to support a supported path.

**Never in a URL.** Not as `https://user:pat@dev.azure.com/...`, not as a query
parameter. URLs are logged by proxies, written to `-Verbose` output, and
captured in exception messages.

**Fail by naming the variable.** When it is absent:

```powershell
if (-not $env:AZDO_PAT) {
    throw 'AZDO_PAT is not set. Set $env:AZDO_PAT to a personal access token with Code (Read) and Build (Read) scope.'
}
```

Do not prompt. Do not search. Do not continue with anonymous access.

## The header

Basic auth with an empty username:

```powershell
function Get-AzDoAuthHeader {
    if (-not $env:AZDO_PAT) { throw 'AZDO_PAT is not set. ...' }
    $bytes = [Text.Encoding]::ASCII.GetBytes(":$($env:AZDO_PAT)")
    @{ Authorization = 'Basic ' + [Convert]::ToBase64String($bytes) }
}
```

Build the header at the call site each time. Do not cache it in a module-scoped
variable that a `-Verbose` dump or an error record could surface.

## Read-only, permanently

`GET` only, with one exception: some Azure DevOps *read* queries require a POST
body. Those are still reads and are allowed. Nothing else is.

Forbidden without exception:

- **Never queue, run, or trigger a pipeline.** Not `POST /_apis/build/builds`,
  not `POST /_apis/pipelines/{id}/runs`, not behind a switch, not in a test.
- **Never create, update, or delete** a repository, definition, variable group,
  service connection, or anything else.
- No command in the module may be named with a writing verb. There is no
  `-Force` that changes this.

A tool that walks an organisation's pipelines is exactly the kind of thing that
gets run with a high-privilege token. That is the reason for the constraint, not
an exception to it.

## Routes

Project-scoped routes only. **Do not call the accounts or profile APIs** —
`app.vssps.visualstudio.com/_apis/profile/profiles/me` and `/_apis/accounts`
need `vso.profile` scope, which a Code+Build read token does not have, and they
return 401. The organisation and project are inputs, not things to discover.

Base: `https://dev.azure.com/{org}/{project}/_apis`

| What | Route |
|---|---|
| Repositories | `GET /git/repositories?api-version=7.1` |
| Build definitions (list) | `GET /build/definitions?api-version=7.1` |
| One definition, full | `GET /build/definitions/{id}?api-version=7.1` |
| File content | `GET /git/repositories/{repoId}/items?path={path}&includeContent=true&$format=json&api-version=7.1` |
| File existence | the same call; treat 404 as "absent", not as an error |

The list form of `build/definitions` returns a *reference* — it does not carry
`process.yamlFilename` or the repository. Fetch each definition by id to learn
which repository and path its YAML lives at.

## Paging

Azure DevOps pages with a continuation token in a **response header**, not in
the body:

```powershell
function Invoke-AzDoRestMethod {
    param([string] $Uri, [hashtable] $Query)

    $items = [System.Collections.Generic.List[object]]::new()
    $token = $null
    do {
        $q = ($Query.GetEnumerator() | ForEach-Object { "$($_.Key)=$([uri]::EscapeDataString([string]$_.Value))" })
        if ($token) { $q += "continuationToken=$([uri]::EscapeDataString($token))" }
        $full = "$Uri?$($q -join '&')"

        $response = Invoke-WebRequest -Uri $full -Headers (Get-AzDoAuthHeader) -Method Get -ErrorAction Stop
        $body = $response.Content | ConvertFrom-Json
        if ($null -ne $body.PSObject.Properties['value']) { $items.AddRange(@($body.value)) }
        else { $items.Add($body) }

        $token = $response.Headers['x-ms-continuationtoken'] | Select-Object -First 1
    } while ($token)
    $items
}
```

Use `Invoke-WebRequest`, not `Invoke-RestMethod`, when you need the token —
`Invoke-RestMethod` discards the headers.

## Errors worth handling by hand

- **404 on an item fetch** means the file is not in that repository. For a
  dependency graph that is a *result* — an unresolved reference with reason
  `file-not-found` — not an exception. Catch it and return `$null`.
- **203 with an HTML body** is Azure DevOps' sign-in page. It means the PAT is
  wrong or expired, and it arrives as a success status. Check the content type
  before parsing.
- **401** on a project route means the token lacks the scope; say so, and name
  the scopes needed rather than retrying.

## Never in output

Redact nothing at the end — put nothing in. No command in the module should
write the token into a message, a `-Verbose` line, an exception, or an exported
object. When in doubt, do not include the request URL in an error message either.

## Related

- `azdo-pipeline-yaml-refs` — what to do with the YAML once fetched.
