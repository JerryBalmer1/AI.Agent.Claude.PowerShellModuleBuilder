---
name: powershell-module-tidy
description: The pre-release sweep for a PowerShell module — naming and layout conformance, public surface versus documentation parity in both directions, dead-file detection, a docs/PLAN.md currency check that blocks a release when the plan has gone stale, and a final conformance run that refuses to bless the release while any Bucket-A item is open. Use immediately before cutting a version, and never as a substitute for the conformance suite.
---

# Tidy — the pre-release sweep

One verb, run once, immediately before a release: **tidy**. It aggregates the
checks that are individually too small to remember and collectively decide
whether a version is fit to cut.

It is not a linter and it is not the conformance suite. It sits between them —
conformance grades the module against the conventions, tidy grades the
*repository* against itself, and the difference is that most of what tidy finds
is drift between two things that were both correct when they were written.

## Run it

```powershell
./skills/powershell-module-tidy/scripts/Invoke-ModuleTidy.ps1 `
    -Path       <repo root> `
    -ReportPath ./tidy-report.json
```

Exit `0` means blessed. Exit `1` means at least one blocker. The report JSON
carries every finding with its file and line, so the fix list is machine-read
rather than scraped from console output.

**Everything deterministic is in the script, not in this page.** Per rule 9 of
this plugin's own taxonomy, judgment is the skill and mechanics are the
scripts — and the mechanics here are exactly the kind that drift when they live
in prose. Two scripts:

| Script | Answers |
|---|---|
| `scripts/Invoke-ModuleTidy.ps1` | naming, surface/docs parity, dead files, and the aggregation |
| `scripts/Test-PlanCurrency.ps1` | is `docs/PLAN.md` newer than the work it describes? |

## The four sweeps

### 1. Naming and layout conformance

The rules the conformance suite does not grade, because they are about the
repository rather than the module:

- No filename contains a space. A space survives every tool on Windows and
  breaks the first script someone writes on Linux without quoting.
- Directories under `src/` are PascalCase. `Private/rest/` and `Private/Rest/`
  are the same directory on Windows and two different ones in git.
- Every `.ps1` under `Public/` and `Private/` is named `Verb-Noun` with a verb
  from `Get-Verb`. Conformance grades `Public/`; `Private/` is where the
  unapproved verb actually accumulates, because nothing exports it.
- Every file under `tests/` that contains a `Describe` is named `*.Tests.ps1`.
  A test file Pester does not discover is a test that silently does not run,
  and it is indistinguishable from a passing one.

The last is the one that has teeth. The others are hygiene; that one is a gate
that cannot fire.

### 2. Public surface versus documentation parity — both directions

Two failures, and they are not the same failure:

- **Exported and undocumented.** A command in `FunctionsToExport` that appears
  in no README table and no `about_` topic. The user cannot discover it.
- **Documented and unexported.** A `Verb-Noun` name in the README that the
  module does not export. The user tries it and it does not exist, which is
  worse, because the README is the reason they tried.

The second direction is the one that gets left out of every hand-rolled
version of this check, and it is the one that produces a bug report. Tidy
reports both and blocks on both.

### 3. Dead files

A `Private/` function whose name is referenced by nothing in `src/` or `tests/`
is dead until proven otherwise. It is reported, **not deleted** — the script
finds candidates and a human decides, because the two legitimate exceptions are
real: a function invoked only through a name built at runtime, and a function
that exists to be called by a consumer through `using module`.

Matching is structural. A name appearing inside a comment is not a reference,
and a text search says it is; that mistake is the same one that made five
build-file assertions in this project's conformance suite inert.

### 4. `docs/PLAN.md` currency — a stale plan blocks the release

**Every module carries `docs/PLAN.md`, and a release with a stale one does not
go out.** The rule and the document's contents belong to
`powershell-module-plan`; tidy is where it is enforced, and this is the only
check in the sweep that blocks on the age of a file rather than its content.

Stale means, mechanically: the newest commit touching `src/` is newer than the
newest commit touching `docs/PLAN.md`. `Test-PlanCurrency.ps1` computes both
from git and prints the two SHAs and dates, so a disagreement is arguable
rather than mysterious.

This is a deliberately blunt rule and it will sometimes be wrong — a typo fix
in `src/` does not invalidate a plan. The response to a false positive is to
touch the plan with a line saying the work landed, which takes ten seconds and
is the behaviour the rule exists to produce. **Do not add an exemption list.**
An exemption list is how the check stops firing.

## The conformance run, and the refusal

Tidy ends by running the conformance suite against the target and **refuses to
bless the release while any Bucket-A item is open.**

The buckets are this project's, and the distinction is the whole point:

- **Bucket A — the grader is wrong.** An assertion that fires on the wrong
  thing, is inert, or cannot fire at all. An open Bucket-A item means the score
  you are looking at is partly a measurement of nothing, so **it blocks
  regardless of what the score says** — including a green one, which is the
  case where it matters, because nobody investigates a green run.
- **Bucket B — the module is genuinely like that.** A real property, declared
  in the module's own known-failures file with a reason and a citation. It does
  not block. It was already argued.

A failure in neither bucket is **new**, and new blocks. That is the ratchet from
`evals/HARNESS.md` applied at release time: an undeclared failure is a finding
and an entry that has stopped failing is stale, and neither may be resolved by
the tool on its own.

**Tidy never weakens an assertion and never adds a known-failure entry.** It
reports and it refuses. Classifying a failure is human judgment and is not
automatable — the script presents each failure with enough context to sort it
quickly and does not attempt the sort.

## What tidy is not

- **Not a formatter.** It changes no file. A sweep that edits while it reports
  makes its own next run meaningless.
- **Not a replacement for conformance.** It calls the suite; it does not
  reimplement any assertion. Two graders that must agree will drift, and the
  drift is silent.
- **Not run in CI on every commit.** It is a release verb. Most of its findings
  are only defects at the moment a version is cut — a stale plan mid-pass is
  normal and blocking on it every commit would train people to ignore it.

## The pre-release checklist

- [ ] `Invoke-ModuleTidy.ps1` exits 0, or every finding is triaged in writing
- [ ] Both parity directions clean — nothing exported-undocumented, nothing
      documented-unexported
- [ ] Dead-file candidates each either deleted or annotated with why they stay
- [ ] `docs/PLAN.md` says where the module stands **as of this version**
- [ ] Conformance run attached to the release record, with cases-defined stated
- [ ] Zero open Bucket-A items
- [ ] Every Bucket-B failure has a known-failures entry with a reason

## Related

- `powershell-module-plan` — owns `docs/PLAN.md` and what belongs in it.
- `powershell-module-release` — the version, changelog and tag that follow.
- `powershell-module-docs` — the README table parity is measured against.
- `powershell-module-analyzer` — the AST walk the dead-file sweep is built on.
