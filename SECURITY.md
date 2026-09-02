# Security

`psmodule` is a Claude Code plugin: fourteen skills and two commands, all of
them Markdown. It contains no compiled code, no installer, no service and no
network client of its own. What follows is about the code it *teaches an agent
to write*, and about the one credential that code handles.

## What the plugin touches

**A credential, `$env:AZDO_PAT`.** The rule, verbatim from this repository's
standing rules ([README](README.md#guardrails)):

> **Credentials.** `$env:AZDO_PAT`, and nothing else, everywhere. Never a
> parameter, never a file, never in a URL — a value passed as a parameter
> reaches `PSReadLine` history, `Start-Transcript` output and the ScriptBlock
> logging event log, and the token is a bearer credential for a whole
> organisation. Every run scans its own artifacts, its clones and its tracked
> blobs for the PAT **by value** before committing; all four runs report zero
> occurrences.

and, verbatim, from the fixture rules
([evals/functional/AZDO-FIXTURE.md](evals/functional/AZDO-FIXTURE.md)):

> **The PAT.** Read from `$env:AZDO_PAT` into a variable. Never echoed, never
> logged, never written to a file, never committed, never passed as a command
> parameter, and redacted in every transcript and plan entry. Any command whose
> output could contain it is either not run or has its output filtered before
> it reaches the plan.

The PAT is a bearer credential for an entire Azure DevOps organisation. Scope it
to **Code: Read** and **Build: Read** and nothing more. The plugin never asks
for a token, never stores one, and never transmits one anywhere except as the
authorization header of a request to your own Azure DevOps instance.

**The filesystem, within a repository you point it at.** Building a module means
writing files. It writes them where you ran it.

## What it never does

- **No network beyond the Azure DevOps REST API.** No telemetry, no analytics,
  no update check, no phone-home, no fetching of remote code at build time.
  Nothing in this plugin sends anything to the author or to any third party.
- **Never queues, runs or triggers a pipeline**, and never creates, updates or
  deletes anything in Azure DevOps. The target module is `GET` only. This is not
  a promise in prose: no command is named with a writing verb, and both claims
  are asserted structurally over the AST in a `PreTag` test.
- **Never publishes.** No `Publish-Module`, no `nuget push`. The publish tooling
  in `tools/publish/` has no push path at all — not a guarded one, not a
  `-Force` one. Adding one would make the rule a matter of restraint rather than
  of code, and this project's argument is that those are different.
- **Never rewrites history and never force-pushes.**

## What is *not* claimed

Read this section before deciding to trust the plugin.

- The plugin has never been **installed cold** by anyone. There is no transcript
  of a stranger adding the marketplace on a machine that has never cloned this
  repository. That proof is outstanding and is named as step 6 of the operator's
  checklist in `tools/publish/Publish-Real.ps1`.
- The marketplace file has **not been checked against the official schema
  validator**. `claude plugin validate` was attempted during the release pass
  and the CLI was not on PATH; the JSON checks that did run are weaker, and are
  recorded in `plans/0030-release/packaging.txt`.
- The plugin's measured effect is **uneven and partly nil** — see the
  with/without table in the [README](README.md#with-the-plugin-and-without-it).
  A security reader should treat the behavioural claims as measured on one
  fixture, not as general.
- The skills are **prose read by a language model**, not code that executes. An
  agent can decline to follow them, or follow them wrongly. Nothing here
  constrains a model at runtime; the conformance suite is what catches the
  result afterwards, and it runs on your machine, not the plugin's.

## Reporting a vulnerability

Open an issue at
<https://github.com/JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder/issues>.

If the report itself would disclose something sensitive, open an issue saying
only that you have one and asking for a contact address — do not put the detail
in the issue.

**Never include a PAT, a token, a connection string or an organisation URL in an
issue.** If you believe you have leaked a token anywhere, revoke it in Azure
DevOps first and report second; revocation is immediate and reporting is not.

This is a solo project with no security team and no paid support. See
[Support](README.md#support) for the cadence you can actually expect. If you
need a guaranteed response time, this project cannot give you one, and it is
better to know that before you depend on it.
