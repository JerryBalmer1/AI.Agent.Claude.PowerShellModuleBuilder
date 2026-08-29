---
name: powershell-module-docs
description: Document a PowerShell module — comment-based help standards graded by the conformance suite, when platyPS earns its cost, about_ topics and the culture directory the build must copy, README structure, and examples that are real rather than invented. Use when writing help, a README, or an example that has never been run.
---

# Module documentation

## Comment-based help

**Every exported function needs comment-based help with a `.SYNOPSIS`.** This is
graded. Two placements count — inside the function body, or in a block
immediately above the definition — and nothing may sit between the comment and
the `function` keyword but whitespace.

```powershell
function Get-AzDoPipeline {
    <#
    .SYNOPSIS
        The pipeline definitions registered in a project.
    .DESCRIPTION
        Each definition carries the repository and the path its YAML lives at.
        The list endpoint returns a reference that does not include either, so
        this fetches each definition by id.
    .PARAMETER Organisation
        The Azure DevOps organisation. Not discovered - the accounts API needs
        a scope a Code+Build read token does not have.
    .EXAMPLE
        Get-AzDoPipeline -Organisation contoso -Project platform

        Lists every definition in the project, with its YAML path.
    .OUTPUTS
        PSAzureDevOpsGraph.Pipeline
    #>
```

What each section is for, and the mistake each one prevents:

- **`.SYNOPSIS`** — one line, what it returns. Not what it does internally. This
  is what `Get-Command -Syntax` users and the conformance suite both read.
- **`.DESCRIPTION`** — the thing a reader cannot infer from the signature. The
  example above spends its description on *why there are two calls*, which is
  the only surprising fact about the command.
- **`.PARAMETER`** — one per parameter, and say what a caller must know to
  choose a value. "The organisation" is worthless; "not discovered, and why" is
  the whole point.
- **`.EXAMPLE`** — the command, a blank line, then what it produces. Multiple
  examples, cheapest first.
- **`.OUTPUTS`** — the `PSTypeName` you emit, so a reader can find the shape.

**Document the credential rule in the help, not only in the README.** A user
reads `Get-Help` at the moment they hit the error.

## Examples must be real

**An example that has never been run is a claim, and several will be wrong.**
Write examples against something that exists: the test fixture, a public
endpoint, or a local path the module itself creates.

The test is mechanical — can you paste the example into a shell and have it
work? If it needs a value you invented (`-Organisation contoso`), say in the
`about_` topic what a reader substitutes, and make sure everything *else* on the
line is real.

Where an example genuinely cannot run — it needs a credential, or a tenant
nobody reading has — say so on the line rather than letting it look runnable:

```powershell
.EXAMPLE
    # Needs $env:AZDO_PAT with Code (Read) and Build (Read).
    Get-AzDoPipelineDependencyGraph -Organisation <yours> -Project <yours>
```

**An example is a test that nobody runs.** If one matters enough, make it one
that somebody does: the fixture-backed cases in `tests/` are the examples that
cannot rot.

## `about_` topics and the culture directory

```
src/<Name>/en-US/about_<Name>.help.txt
```

The build **must copy culture directories** (`en-US`, `fr-FR`, anything matching
`^[a-z]{2}(-[A-Za-z]{2,4})?$`) into `output/<Name>/`, or `Get-Help about_<Name>`
finds nothing. This is the most commonly missed step in a module build, because
everything else works without it. Assert it: `Test-Path` the copied topic in the
built-module quality tests.

The `about_` topic carries what does not belong to any one command: the
credential model, the concepts and their names, the one worked end-to-end
sequence, and what the module deliberately will not do.

## When platyPS earns its cost

**Not by default.** Comment-based help is already in the file being edited, and
the conformance suite grades it there. platyPS adds a second copy of the same
text in a second format that must be kept in sync, and the sync is manual.

Adopt it when — and only when — one of these is true:

- **You are publishing updatable help.** `New-ExternalHelp` plus a
  `HelpInfoUri` in the manifest is the only supported way, and there is no
  alternative.
- **The help is longer than the code.** Some commands genuinely need pages of
  parameter interaction that would drown the function body.
- **Non-authors write the docs.** Markdown in a separate file is reviewable by
  someone who will not open a `.ps1`.

When you do adopt it, **generate in one direction only** — source of truth is
the markdown, and comment-based help is generated, or the reverse — and put the
regeneration in the build so drift is a failed build rather than a discovery.
Two texts that must agree and are edited in different files will drift silently.

## README structure

For a module repository, in this order. The order is the reading order of
someone deciding whether to use it.

1. **Name and one sentence.** What question it answers.
2. **The honest status.** What is measured, what is not, and against how many
   targets. A README that reads as finished when the work is not is the most
   expensive kind of wrong.
3. **Install / prerequisites.** Exact versions. Every runtime dependency,
   including the ones declared nowhere else — a module that imports
   `powershell-yaml` lazily and declares no `RequiredModules` must say so here
   until it declares it properly.
4. **A worked example that runs**, with its real output.
5. **The command surface**, as a table, one line each.
6. **Credentials**, if any: the mechanism and the forbidden alternatives.
7. **Running the tests**, with the exact commands.
8. **Known limits**, by name. What is implemented but unexercised; what is
   covered by one target only.
9. **Licence.**

**Never a benefit claim written mid-project.** Those are predictions and several
will be wrong. State capability — what is now possible that was not — and cite
the artifact that shows it. A number without an artifact behind it does not
belong in a README any more than in a plan.

## Where each document lives

| Document | Path | Holds |
|---|---|---|
| Command help | in the `.ps1` | one command |
| Concepts | `src/<Name>/en-US/about_<Name>.help.txt` | what spans commands |
| README | `README.md` | the decision to use it |
| Changelog | `CHANGELOG.md` | what changed, per version |
| Worklog | `docs/worklog/v<version>.md` | why, per version |
| Troubleshooting | `docs/TROUBLESHOOTING.md` | symptom → command that reveals → fix |
| External tools | `docs/knowledge/<tool>.md` | written when the dependency appears |
| Plans | `docs/plans/NNNN-<slug>.md` | one per piece of work |

**A fact needed only while performing a specific task lives with that task.**
Everything in the always-read tier is charged to every reader forever, so it has
to be true and needed *before the work is known*. Moving a paragraph down a tier
loses nothing; deleting it has a defender. Prefer the move.

## Related

- `powershell-module-architect` — the surface being documented.
- `powershell-module-analyzer` — writes `docs/knowledge/<tool>.md`.
- `powershell-module-release` — the changelog and worklog conventions.
