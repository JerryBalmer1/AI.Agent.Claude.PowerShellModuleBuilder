# TROUBLESHOOTING — the Azure DevOps fixture

Pass 0013 shipped a surface that reaches the network and depends on a
credential, so it can fail on a machine that is not the one it was built on.
`method/METHOD.md` makes diagnosability part of done: every failure below is
listed as a **symptom**, the **named command** that reveals why, and the
**prerequisite** that was not met.

Nothing here asks you to print the PAT. No command below echoes it, and none
should be modified to. If a command's output could contain it, it is not in this
file.

---

## `AZDO_PAT` is not set

**Symptom.** `Sync-Fixture.ps1` throws immediately:

    Environment variable AZDO_PAT is not set.

Or `ReadBack.Tests.ps1` fails every test in the file with the same message from
its `BeforeAll`.

**Reveals why.**

    pwsh -NoProfile -Command "if ($env:AZDO_PAT) { 'set, length ' + $env:AZDO_PAT.Length } else { 'NOT SET' }"

**Prerequisite.** A personal access token in `$env:AZDO_PAT`, with **Code
(read & write)** and **Build (read & execute)** scopes on the organisation
`jlbalmerjr1`. Expect a length of 84.

---

## The environment-inheritance trap

This one costs the most time, because the variable is visibly set in one shell
and absent in the next.

**Symptom.** `$env:AZDO_PAT` is set when you check it interactively, but
`Sync-Fixture.ps1` throws "not set" — or it works in the terminal and fails when
run from a task, a hook, or an agent.

**Why.** A variable set in a PowerShell profile (`$PROFILE`) exists only in
shells that load the profile. Every command in this pass runs with
`pwsh -NoProfile`, deliberately, so that behaviour does not depend on a personal
profile. A profile-set variable is invisible to all of them. The same applies to
a variable set with `$env:AZDO_PAT = '...'` in one terminal: it dies with that
process and is never seen by another.

**Reveals why.** Compare the two — the first loads your profile, the second does
not:

    pwsh -Command        "'with profile:    ' + [bool]$env:AZDO_PAT"
    pwsh -NoProfile -Command "'without profile: ' + [bool]$env:AZDO_PAT"

If the first says True and the second False, the variable is coming from your
profile and nothing in this pass will see it.

Check where it actually lives:

    pwsh -NoProfile -Command "'User scope:    ' + [bool][Environment]::GetEnvironmentVariable('AZDO_PAT','User')"
    pwsh -NoProfile -Command "'Machine scope: ' + [bool][Environment]::GetEnvironmentVariable('AZDO_PAT','Machine')"

**Prerequisite.** Set it at **User** scope, in the registry, so every process
inherits it:

    [Environment]::SetEnvironmentVariable('AZDO_PAT', '<token>', 'User')

Then **restart the editor completely** — not just the integrated terminal. A
running VS Code inherited its environment when it started and passes that stale
copy to every terminal it spawns, so a new terminal in an old editor still will
not see the change. Verify from a *fresh* integrated terminal with the
`-NoProfile` command above. This is what works; a profile assignment is what
does not.

---

## HTTP 203, and why it reads as a parse failure

**Symptom.** A call fails with something about invalid JSON, an unexpected
character, or `ConvertFrom-Json` failing on `<!DOCTYPE html>`. Or the helpers
here throw:

    Azure DevOps returned 203 (a sign-in page, not JSON)

**Why.** When a PAT is expired, revoked, or lacks the scope for the endpoint,
Azure DevOps does **not** return 401. It returns **203 Non-Authoritative
Information** with an HTML sign-in page as the body. Any client that assumes a
2xx status means success will hand that HTML to a JSON parser, and the error you
see will be about JSON syntax — pointing at your parsing code, which is fine,
instead of at your credential, which is not.

`Invoke-AzdoJson` in `AzdoClient.ps1` checks for 203 explicitly and says so,
which is why the message above exists at all.

**Reveals why.**

    pwsh -NoProfile -Command @'
      $h = @{ Authorization = 'Basic ' + [Convert]::ToBase64String(
               [Text.Encoding]::ASCII.GetBytes(':' + $env:AZDO_PAT)) }
      $r = Invoke-WebRequest -Uri 'https://dev.azure.com/jlbalmerjr1/_apis/projects/ClaudeTesting?api-version=7.1' `
             -Headers $h -SkipHttpErrorCheck -MaximumRedirection 0
      'status: ' + $r.StatusCode
    '@

`200` is healthy. **`203` means the credential, never the code.** Reissue the
PAT.

**Prerequisite.** A PAT that is not expired and carries the needed scope.

---

## The PAT lacks Code or Build scope

**Symptom.** Reading the project succeeds (200) but a specific operation fails
with 203 or 403: repositories list but pushes fail, or repositories work
entirely and `build/definitions` fails.

**Why.** Scopes are per-area. A token scoped only to Code authenticates
perfectly against `git/repositories` and gets a sign-in page from `build`.

**Reveals why.** Probe the two areas separately — the first needs Code, the
second Build:

    pwsh -NoProfile -Command @'
      . ./evals/functional/AzdoClient.ps1
      try { 'repos : ' + @(Get-AzdoRepository).Count } catch { 'repos : ' + $_.Exception.Message }
      try { 'defs  : ' + @(Get-AzdoDefinition).Count } catch { 'defs  : ' + $_.Exception.Message }
    '@

If one line reports a count and the other reports 203, the scope is missing for
whichever failed.

**Prerequisite.** **Code (read & write)** for creating repositories and pushing;
**Build (read & execute)** for creating and reading definitions.

---

## Wrong project or organisation

**Symptom.** `Assert-AzdoScope` throws before anything runs:

    Refusing to operate: project must be 'ClaudeTesting', got '...'

**Why.** Deliberate. The fixture is scoped to one organisation and one project,
and the scripts refuse rather than create objects somewhere else. A typo in a
project name is otherwise a silent way to scatter fifteen pipeline definitions
across an unrelated project.

**Reveals why.**

    pwsh -NoProfile -Command "curl.exe -s -o /dev/null -w '%{http_code}' https://dev.azure.com/jlbalmerjr1/_apis/projects?api-version=7.1"

**Prerequisite.** Organisation `jlbalmerjr1`, project `ClaudeTesting`. These are
not parameters. Changing them means editing `AzdoClient.ps1`, which is the point.

---

## A partially created fixture

**Symptom.** `ReadBack.Tests.ps1` fails a subset of assertions — some
repositories exist and others do not, or repositories exist but definitions do
not. This is the normal state after an interrupted run.

**Why.** `Sync-Fixture.ps1` creates in order and is not transactional. An
interruption leaves everything created so far in place.

**Reveals why.** Ask what is actually there:

    pwsh -NoProfile -Command @'
      . ./evals/functional/AzdoClient.ps1
      'repositories:'; @(Get-AzdoRepository) | ForEach-Object { '  ' + $_.name }
      'definitions:';  @(Get-AzdoDefinition)  | ForEach-Object { '  ' + $_.name }
    '@

**The fix.** Re-run it. `Sync-Fixture.ps1` is idempotent: it checks for existence
before creating and reports "already present" per item, so a re-run completes
whatever is missing and touches nothing that exists.

    pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1 -DryRun   # see the gap
    pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1           # close it

A repository that exists but is empty is pushed to on the re-run. A repository
that already has files on `main` is left alone — so if a push landed *partially*,
delete that repository in the Azure DevOps UI and re-run, rather than expecting
the script to reconcile file by file. It does not do that, deliberately: a
reconciling push is a push that can overwrite, and this script never overwrites.

---

## A CRLF round trip fails assertion 3

**Symptom.** `ReadBack.Tests.ps1` assertion 3 fails for some or all of the 30
files, with a message like:

    raw bytes differ for pipelines-main/pipelines/p01.yml
      committed: 449 bytes, CR=0, LF=12
      server   : 461 bytes, CR=12, LF=12

**Why.** `core.autocrlf=true` is the Git for Windows installer default and
arrives at **system** scope, so it is what any Windows clone gets. Without the
repository-root `.gitattributes`, a clone checks the fixture out as CRLF, and
pushing those bytes puts CRLF on the server. The committed side and the server
side then differ by exactly one CR per line.

**Which side normalised.** The CR counts in the failure message answer this
directly: **CR=0 committed, CR>0 on the server** means the local checkout was
translated and the wrong bytes were pushed. The reverse would mean something
translated on the way back, which would be a bug in `Get-AzdoFileBytes`.

**Reveals why.** Measure all three sides — working tree, git blob, and a fresh
clone. The working tree and the blob can agree while a clone differs, which is
the case that catches people out:

    git config --show-origin --get core.autocrlf
    git check-attr text eol -- evals/functional/fixture/repos/pipelines-main/pipelines/p01.yml

    pwsh -NoProfile -Command @'
      $p = 'evals/functional/fixture/repos/pipelines-main/pipelines/p01.yml'
      $b = [IO.File]::ReadAllBytes($p)
      'working tree: {0} bytes, CR={1}' -f $b.Length, @($b | Where-Object { $_ -eq 13 }).Count
    '@

`git check-attr` must report `text: auto` and `eol: lf`. If it reports
`unspecified`, `.gitattributes` is missing or does not cover the path.

**Prerequisite.** The repository-root `.gitattributes` pinning `*.yml`, `*.json`,
`*.md` and `*.ps1` to `eol=lf`, present in the commit you cloned. Note that
adding `.gitattributes` does not fix an already-checked-out tree; re-clone, or
run `git add --renormalize .` followed by a checkout.

**Clone to a short path.** A clone-and-compare check fails on Windows with
`Filename too long` if the destination is deep: the scratch prefix plus the
deepest fixture path exceeds the 260-character limit. Clone to something like
`C:\t13\check` and record the path used.

---

## A top-level `function` breaks every `BeforeAll` in a Pester 6.1.0 test file

**Symptom.** Every `BeforeAll` in one test file fails, and the error mentions
loop labels rather than functions:

    A 'break' or 'continue' statement with a label that does not match any
    enclosing loop escaped from your code.

Nothing in the message names a function, and the file's tests all fail with it.

**Why.** Declaring a `function` at the top level of a Pester 6.1.0 test file
breaks every `BeforeAll` in that file. Reduced to the smallest case: a file
containing only `function Probe-It { 'hello' }` plus a `Describe` whose
`BeforeAll` runs `Get-Command Probe-It` fails the same way.

**The fix.** Put the function in its own `.ps1` and dot-source it. The identical
function dot-sourced from another file works. That is why
`evals/functional/FixtureCase.ps1` and `evals/functional/AzdoClient.ps1` exist as
separate files rather than as functions inside the suites that use them, and why
they are dot-sourced from both `BeforeDiscovery` and `BeforeAll`.

**Reveals why.** Search the failing file for a top-level declaration:

    pwsh -NoProfile -Command "Select-String -Path evals/functional/*.Tests.ps1 -Pattern '^function '"

Any hit is the cause.
