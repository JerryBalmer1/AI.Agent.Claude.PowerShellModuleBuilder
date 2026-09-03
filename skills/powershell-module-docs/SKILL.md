---
name: powershell-module-docs
description: Document a PowerShell module — comment-based help standards graded by the conformance suite, when platyPS earns its cost, about_ topics and the culture directory the build must copy, README structure, and examples that are real rather than invented. Use when writing help, a README, or an example that has never been run.
---

# Module documentation

## Comment-based help

**Every function gets full comment-based help — public *and* private.** The
house standard, all of it graded by `evals/conformance/Help.Tests.ps1`:

- `.SYNOPSIS`, one line.
- `.DESCRIPTION`, always, even when it feels redundant. The private helper you
  will not recognise in eight months is exactly the one nobody wrote it for.
- **A `.PARAMETER` entry for every declared parameter.** Every one, including
  the obvious ones.
- **At least as many `.EXAMPLE` blocks as the function has parameter sets, and
  each named set's signature appears in one of them.** A function with three
  parameter sets and one example has documented a third of itself. This is the
  rule that catches the case where a set was added and the help was not.
- `HelpMessage` on every mandatory parameter. It is what PowerShell prints when
  it prompts for the missing value, and without it the prompt is the bare
  parameter name — the least helpful moment in the whole module to say nothing.

Private is not an exemption. The one thing that changes for a private function
is the audience: the examples are for the next maintainer rather than the next
user, and they should show the call as it is actually made inside the module.

Two placements count — inside the function body, or in a block immediately
above the definition — and nothing may sit between the comment and the
`function` keyword but whitespace.

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

## The house `.EXAMPLE` standard

**The design goal is copy-paste-and-edit.** A reader lands on `Get-Help`,
copies the example whole into a new script, changes the values at the top, and
runs it. Every element of the standard exists to serve that one motion, and it
is the operator's convention rather than a general PowerShell one.

Four parts, in this order:

1. **Parameters assigned at the top, with aligned `=`.** The alignment is
   deliberate and is not cosmetic: it is what lets a reader see the parameters
   and their values at a glance, as one column, and spot the one they have to
   change.
2. **Splat through a `$params` hashtable.** Not a long line of `-Name value`
   pairs. A splatted call adds and removes a parameter by adding and removing a
   line, which is what a reader editing the example is about to do.
3. **A `try`/`catch` with a real error message.** Not `catch { }`, not
   `catch { throw }` — the message a user would actually want, naming what was
   being attempted.
4. **The result assigned and displayed.** The example ends holding something,
   because the reader's next line is going to use it.

```powershell
.EXAMPLE
    $ServerName   = "SomeServerName"
    $DatabaseName = "SomeDatabaseName"
    $Migrate      = $true
    $Force        = $true

    $serverMigrationResult = try {

        $params = @{
            ServerName   = $ServerName
            DatabaseName = $DatabaseName
            Migrate      = $Migrate
            Force        = $Force
        }

        Invoke-PSFunction @params

    }
    catch {
        Write-Error "An error occurred during the server migration: $_"
        $false
    }

    $serverMigrationResult
```

Keep the spaces around `=`. They are the alignment, and an autoformatter that
collapses them has removed the point of the block.

**One of these per parameter set**, per the standard above, and the set's own
parameters are the ones assigned at the top. That is what makes "examples ≥
parameter sets" a real check rather than a counting exercise: two examples that
call the same set differently do not satisfy it.

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

## Classes and enums: say plainly that help does not work

**PowerShell classes and enums do not support comment-based help. There is no
version of this that works, and no keyword that fixes it.** A complete
`.SYNOPSIS`/`.DESCRIPTION` block written above a `class` produces exactly
nothing:

```
matches for 'ZzUniqueThing': 0
typed lookup threw: HelpNotFoundException
```

That block is not help. It looks like help, it is indexed by nothing, and
`Get-Help` on the type name returns zero matches while `Get-Help ([Type])`
throws. Writing one and assuming a user can find it is the failure this section
exists to prevent — and it is a real failure, because the block is *visually
indistinguishable* from the working kind twenty lines away in the same file.

So the house standard says the checkable thing rather than the impossible one:

1. **A doc comment block immediately precedes every class and enum**, in the
   same shape as function help — synopsis line, then what a reader cannot infer
   from the property list. It is for the person reading the source, which is
   the only person who will ever see it, and that is worth stating in the
   review rather than discovering later.
2. **Every public class and enum is covered in `about_<Module>`**, which is the
   only place a *user* can find it. A module with public types and no `about_`
   topic has undocumented types no matter how good the source comments are.

Both are graded. The conformance suite cannot check that a class is documented
in the sense `Get-Help` means, because that sense does not exist — so it checks
the two things that do exist and are equivalent for the reader: the block is
there, and the topic ships. **Assert the checkable equivalent, and say in the
open that it is an equivalent rather than the thing itself.** A rule that
quietly asserts something weaker than it claims is how a gate stops meaning
anything.

Enums get the same treatment and are the more commonly skipped of the two,
usually because each value "explains itself". The value name says what it is
called and never says when to choose it, which is the only thing a reader
needs.

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
