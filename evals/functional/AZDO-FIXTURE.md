# AZDO-FIXTURE — the creation plan for Pass 0013

What Pass 0013 creates in Azure DevOps, in what order, and under what
constraints. Nothing in this file has been executed. Pass 0011 made no network
call, created nothing, and did not read the PAT.

The YAML in `fixture/repos/` is the source of truth. Pass 0013 **pushes** it. It
does not author pipeline YAML in Azure DevOps and then copy it back; if the two
ever disagree, the repository wins and Azure DevOps is rebuilt.

## Constraints

These live here rather than only in a prompt, because a prompt is not in the
repository and this fixture will outlive the conversation that asked for it.

- **Scope.** Only the project `ClaudeTesting` in the organisation
  `https://dev.azure.com/jlbalmerjr1`. No other project, no other organisation,
  no Azure subscription, no resource outside that project.
- **Never queue, run, or trigger a pipeline.** Definitions are created and left
  alone. No manual run, no test run, no "just once to see". Two of the fifteen
  definitions would fail if run; the other thirteen would consume agent minutes.
  Neither is a reason — the rule is the same for all fifteen.
- **Nothing that meters or bills.** No Azure Artifacts feed, no Test Plans, no
  self-hosted or scale-set agent pool, no service connection to any Azure
  resource, no extension from the marketplace. Git repositories and pipeline
  definitions only.
- **The PAT.** Read from `$env:AZDO_PAT` into a variable. Never echoed, never
  logged, never written to a file, never committed, never passed as a command
  parameter, and redacted in every transcript and plan entry. Any command whose
  output could contain it is either not run or has its output filtered before it
  reaches the plan.
- **Idempotent and re-runnable.** Every step checks for existence before
  creating. Running the whole plan twice must leave the same fixture, not a
  duplicated one, so that the fixture can be rebuilt after a wipe.

`ClaudeTesting` is assumed to be a scratch project whose contents are
disposable. If it turns out to hold anything beyond the one repository named
below, Pass 0013 stops rather than adding to it.

## The pre-existing `ClaudeTesting` repository

The project already contains a Git repository named `ClaudeTesting`, created
with the project and empty. It is not part of the fixture and never becomes part
of it.

**Pass 0013 must not delete it, modify it, push to it, or create any pipeline
definition in it.** It is left exactly as found. The expected state before
creation is one repository, `ClaudeTesting`, and zero definitions; any other
state is a hard stop and a finding for the operator rather than something to
tidy up.

It is not merely tolerated — it is load-bearing. **Its presence is case 12**, an
absence case: a repository that exists in the project, that no pipeline
references, and that must therefore not appear in the graph. It discriminates
against an implementation that builds its repository nodes by calling the
repositories endpoint instead of deriving them from pipeline references. The
four `repo` nodes in `expected-graph.json` are there because pipeline YAML names
them through `resources.repositories` or `checkout`; `ClaudeTesting` is named by
neither, so a graph with five repository nodes is answering a different question
— "what is in this project" rather than "what do these pipelines depend on".

Because it is an absence case, nothing in `expected-graph.json` carries a
`case-12` tag; tagging a node with it would assert the opposite of the claim.
Its checks live elsewhere, and `fixture/cases.md` names them on case 12's
`**checked by:**` line: an assertion in `Fixture.Tests.ps1` that no node has an
id, name or repo equal to `ClaudeTesting`, and read-back assertion 8 below.

## Repositories

Four, all created empty and then pushed to. Create in this order — it does not
matter for Git, but it matters for the read-back check, which walks them in
order.

| # | Repository | Holds |
|---|---|---|
| 1 | `pipelines-main` | Eleven pipeline definitions' YAML and their local templates, plus one repo-root template |
| 2 | `templates-shared` | Templates consumed cross-repo, plus one pipeline of its own |
| 3 | `templates-platform` | A second template repo, consumed from outside it, plus one pipeline of its own |
| 4 | `consumer-app` | An application repo with two pipelines consuming both template repos |

Each repository's content is exactly `fixture/repos/<name>/`, pushed to `main`.
Nothing else: no README, no `.gitignore`, no branch policy, no default reviewer.
A file in Azure DevOps that is not in `fixture/repos/` is a defect, and the
read-back check treats it as one.

File counts, for the read-back:

| Repository | YAML files |
|---|---|
| `pipelines-main` | 21 |
| `templates-shared` | 3 |
| `templates-platform` | 3 |
| `consumer-app` | 3 |
| **total** | **30** |

## Pipeline definitions

Fifteen, all YAML pipelines. Each is created against a repository and a path,
with no variables, no triggers beyond what its YAML declares, and no schedule
configured in the UI.

Create the eleven `p0*` definitions **first**, then the four `x0*`. Two `x0*`
definitions declare a `resources.pipelines` dependency on `p01-simple-include`,
and one `p0*` YAML is a template target for two `x0*` pipelines; creating the
`p0*` set first means every `resources.pipelines` source name exists before
anything names it. Nothing else in the fixture depends on creation order —
`template:` and `extends:` references are resolved by Azure DevOps when a
pipeline runs, and these never run.

| # | Definition | Repository | YAML path |
|---|---|---|---|
| 1 | `p01-simple-include` | `pipelines-main` | `pipelines/p01.yml` |
| 2 | `p02-nested-chain` | `pipelines-main` | `pipelines/p02.yml` |
| 3 | `p03-extends-params` | `pipelines-main` | `pipelines/p03.yml` |
| 4 | `p04-cross-repo-template` | `pipelines-main` | `pipelines/p04.yml` |
| 5 | `p05-pipeline-resource` | `pipelines-main` | `pipelines/p05.yml` |
| 6 | `p06-variable-template` | `pipelines-main` | `pipelines/p06.yml` |
| 7 | `p07-diamond-a` | `pipelines-main` | `pipelines/p07a.yml` |
| 8 | `p07-diamond-b` | `pipelines-main` | `pipelines/p07b.yml` |
| 9 | `p08-cycle` | `pipelines-main` | `pipelines/p08.yml` |
| 10 | `p09-unresolved` | `pipelines-main` | `pipelines/p09.yml` |
| 11 | `p10-orphan` | `pipelines-main` | `pipelines/p10.yml` |
| 12 | `x01-consumer-build` | `consumer-app` | `azure-pipelines.yml` |
| 13 | `x02-platform-release` | `consumer-app` | `pipelines/release.yml` |
| 14 | `x03-shared-nightly` | `templates-shared` | `pipelines/nightly.yml` |
| 15 | `x04-cross-trigger` | `templates-platform` | `pipelines/trigger.yml` |

### The two that must never run

`p08-cycle` and `p09-unresolved` are definitions that would fail if they were
run. `p08` includes a template that includes it back; `p09` references a file
that does not exist and a repository alias that is not declared. Azure DevOps
reports both as template-expansion errors at queue time.

This is a fixture requirement, not an accident. Case 8 and case 9 exist to test
what the module does with a broken pipeline, and a broken pipeline is the only
way to test it. They are never run, which is already the rule for all fifteen.

A consequence worth knowing before it surprises someone: the Azure DevOps UI may
show these definitions with a validation warning, and any "validate YAML"
feature will report them as invalid. That is the correct result and is not a
defect to fix.

### Triggers

`p01.yml` and `azure-pipelines.yml` declare `trigger: - main`. Every other
pipeline declares `trigger: none`. The two CI triggers are deliberate: a
definition with no trigger at all is a slightly different object in the Azure
DevOps API, and the fixture should contain both shapes.

**A push to a repository will therefore queue `p01-simple-include` and
`x01-consumer-build` unless CI is suppressed.** Pass 0013 must either disable CI
triggers at the definition level after creation, or push with a commit message
containing `***NO_CI***`, or create the definitions only after the final push.
The last is simplest and is the recommended order: push all four repositories
first, then create all fifteen definitions. A definition created after the push
has nothing to trigger on.

If a pipeline is queued anyway, cancel it, record it in the plan's Deviations,
and do not treat it as harmless.

## Order of operations

1. Verify the PAT is present in `$env:AZDO_PAT` and that it authenticates
   against `ClaudeTesting`. One read call. If it fails, stop.
2. Confirm `ClaudeTesting` exists and record what it already contains. If it
   holds repositories or definitions that are not part of this fixture, stop and
   report rather than adding to it.
3. Create the four repositories, skipping any that already exist.
4. Push `fixture/repos/<name>/` to `main` in each. All four, before any
   definition exists.
5. Create the fifteen pipeline definitions, `p0*` before `x0*`, skipping any
   that already exist by name.
6. Read back and verify (below).
7. Confirm no pipeline was queued: the run history of all fifteen definitions is
   empty.

## Read-back verification

Pass 0013 is verified by reading Azure DevOps, not by trusting that the create
calls returned 200.

1. **Five** repositories exist: the four above, plus the pre-existing
   `ClaudeTesting`. No others. The count is five and not four on purpose — see
   *The pre-existing `ClaudeTesting` repository*, and note that an earlier
   version of this file said "four ... and no others", which would have failed
   the read-back against a correct project.
2. Each repository's file list on `main` equals `fixture/repos/<name>/` exactly —
   same paths, no extras, 30 files in total.
3. Every file's content on `main` is byte-identical to the committed file.
4. Fifteen definitions exist, named exactly as above, and no others.
5. Each definition's repository and YAML path match the table above.
6. Every definition's run history is empty.
7. The `ClaudeTesting` repository still exists, is still empty, and no
   definition targets it. This is read-back assertion 8 and it is case 12's
   external check: it is what makes "nothing carries the tag" mean something.

### How assertion 3 compares bytes

A byte comparison is only meaningful if both sides say what "the bytes" are.
This is that statement, and it is what read-back assertion 3 implements.

**The fixture's canonical form.** Every file under `fixture/repos/` is UTF-8
without a byte-order mark, uses LF (`0x0A`) alone as its newline, and ends with
a final newline. Measured, not assumed: all 30 files are BOM-free, contain no
byte above `0x7F`, contain no `0x0D` at all, and end in `0x0A`. Because the
content is a pure ASCII subset, UTF-8 and ASCII agree byte for byte here; the
canonical encoding is still UTF-8, and a future file containing a non-ASCII
character does not change the rule.

**How the comparison is performed.** Both sides are read as raw bytes with no
line-ending translation, no encoding detection, and no string conversion at any
point:

- The committed side is read with `[IO.File]::ReadAllBytes`, never
  `Get-Content`, whose default splits on newlines and reassembles them.
- The Azure DevOps side is fetched from the Git items endpoint as a byte stream
  and read into a byte array, never through a property that has already been
  decoded to a string.
- Each side is hashed with SHA-256 over those bytes, and the two hashes are
  compared. Lengths are compared too, so a mismatch reports how far apart the
  sides are rather than only that they differ.

Nothing in the comparison path calls `-split`, `-replace`, `Get-Content`,
`Out-File`, or `Set-Content`. Each of those translates line endings on Windows
by default, and a comparison that translates both sides identically will pass
while the fixture on the server is wrong.

**Why this needs saying.** `core.autocrlf=true` is the Git for Windows installer
default and arrives at **system** scope, so it is what any Windows clone of this
repository gets. Measured on this machine before `.gitattributes` existed:
`pipelines/p01.yml` is 449 bytes with 0 CR in the working tree and in the git
blob, but **461 bytes with 12 CR in a fresh clone**. The working tree and the
blob agree only because these files were written into the tree rather than
checked out; the gap appears the moment anyone clones. Pushing a clone's bytes
would put CRLF into Azure DevOps, and a comparison that read both sides through
a newline-translating API would not notice.

The repository-root `.gitattributes` prevents this, pinning `*.yml`, `*.json`,
`*.md` and `*.ps1` to `eol=lf` so a checkout on any platform reproduces the
canonical bytes. Prevention alone is not enough: `Fixture.Tests.ps1` keeps its
CRLF regression assertion, because prevention that nothing detects is prevention
nobody notices failing.

Check 3 is the one that matters. Checks 1, 2, 4 and 5 confirm that the right
names exist; only 3 confirms that what was pushed is what the module will later
read. A fixture whose YAML differs from `fixture/repos/` by one line makes every
subsequent functional result unattributable — the module could be wrong, or the
fixture could be, and nothing in the output would say which.

## Rebuilding after a wipe

The plan is re-runnable end to end. If `ClaudeTesting` is emptied, running steps
1–7 again reproduces the fixture from `fixture/repos/` with no manual step. That
is the reason for the existence checks in steps 3 and 5, and it is the reason
the YAML lives in this repository rather than only in Azure DevOps.
