---
pass: 0007
title: Negative controls, the Universal/Repository split, and the corpus
date: 2026-08-28
artifacts:
  - git commits 652a2c8, 5de42c1
  - evals/conformance/TASK.md (Pass 3 section)
  - evals/conformance/baseline/FALSIFICATION.md (negative controls section)
  - evals/conformance/baseline/UNIVERSAL-CORPUS.md
  - evals/HARNESS.md
---

# Pass 0007 — Negative controls, the Universal/Repository split, and the corpus

## Asked

Recoverable from `evals/conformance/TASK.md`, Pass 3 section: add the standing
rule that a falsification row needs a negative control and backfill a control
column across every existing row; split the `Universal` tag into `Universal` and
`Repository` (H1); validate `Universal` against the eight-module gallery corpus
(H2); revise the known-failure set and the harness specification (H3).

Explicitly: collect first, change no assertion during H2, and bring the list
back rather than acting on it — "an assertion that eight dissimilar modules fail
is mine to fix, not yours to weaken."

## Done

`git show --stat 652a2c8`: 2 files. `git show --stat 5de42c1`: 7 files, 618
insertions.

- **Controls.** Twelve negative controls designed and run, one per falsification
  row, each chosen to be confusable with that row's break rather than merely
  unrelated. Recorded in `FALSIFICATION.md`.
- **H1.** `Repository shape` retagged from `Universal` to `Repository`; the
  runner's `ValidateSet` and default tag set updated.
- **H2.** All eight corpus modules fetched via `gallery/fetch.ps1` and run with
  `-Tag Universal`. `baseline/UNIVERSAL-CORPUS.md` written, 312 lines.
- **H3.** `HARNESS.md` revised: the known-failure set respecified as persisted
  Bucket B classifications keyed by assertion plus target; Bucket A/B sorting
  recorded as not automatable; two claims marked *Evidence: 1 target*.

## Why

From the README as changed this pass: the tag split was made on evidence, not
taste. A published package has no build file and no tests, so failing it for
their absence says nothing about the module.

From `HARNESS.md`: Bucket A/B sorting is not automatable because the same
assertion failing the same way is a suite bug against one target and a real
finding against another — `defines every function the manifest exports` fails on
Pester because the suite could not read a `.psm1`, and on ImportExcel because
two names in `FunctionsToExport` are aliases. The failure messages are
near-identical and nothing in the result file separates them.

Rejected, per `FALSIFICATION.md`: decoupling the three assertions that a
wildcard export turns red. A wildcard export genuinely violates all three and
each is independently worth asserting; the coupling is recorded rather than
removed.

## Measured

- H1: reference unchanged at **74/75** and **80/81**; per-tag selection
  26 + 18 + 31 + 6 = 81, so no test was dropped by the retag (`TASK.md`, Pass 3
  outcome).
- Controls: eleven of twelve correct, one not.
- H2, from `UNIVERSAL-CORPUS.md`: run on the committed suite, **all eight corpus
  modules collapsed** — 1/11 each with a container failure, except SqlServerDsc
  at 9/11, also with a container failure. Per-assertion data required a second
  pass with two blockers neutralised outside the tree. Of ten `Universal`
  assertions, **five survived all nine targets**; the comment-based-help
  assertion had run on **three** targets and 63 cases.
- Seven Bucket A findings, four Bucket B.

## Learned

**Row 7's control failed, and twelve breaks had not found it.** Adding a
*comment* reading "never set `Run.Exit = $true` here" — with no code changed —
turned `throws rather than exits when tests fail` red. A build file whose author
documented the hazard would fail the assertion that checks for the hazard.
Recorded in `FALSIFICATION.md` under "Row 7's control fails". This is the
mirror image of the inert coverage assertion from Pass 0006: one fired on
something it should ignore, the other ignored everything. Same cause, and only a
control could see either.

**posh-git, the corpus's designated control, failed `Universal` on suite
defects.** From `UNIVERSAL-CORPUS.md`: it failed `defines every function the
manifest exports somewhere in source` because its `function Global:Write-VcsStatus`
kept the scope qualifier in `FunctionDefinitionAst.Name` and never matched the
exported name, and `declares the PowerShell editions it claims to support`
because reading an absent key throws under StrictMode. Recorded there as: "The
corpus's designated control fails two Universal assertions, both for suite
reasons. That is the finding: if the control cannot pass, the tag is not
measuring what it claims."

**The suite could not find a published module at all,** and worse, could succeed
on the wrong one. `UNIVERSAL-CORPUS.md` A-C1: SqlServerDsc ships 51 manifests,
one of which — a bundled helper — satisfied the base-name-matches-directory
rule, so the suite graded that and reported 81.82% with nothing in the output to
say so. This is the second appearance of the shape first recorded as A1 in
`FINDINGS.md`, and not the last.

**An assertion that produced zero cases read as part of a green run.** The
comment-based-help assertion enumerated `Public/*.ps1`, which six of eight
modules do not have. It did not pass and did not fail; it did not run. This
became standing rule 9.

## Capability

- Every falsification row carries a negative control as well as a break.
- `Universal` and `Repository` are separate claims, so a module that is not a
  repository can be graded without being failed for what it is not.
- `Universal` has been run against nine targets rather than one, and the
  per-assertion survival count is recorded rather than asserted.
- Expected failures are declared in a checked-in file keyed by assertion plus
  target, so a new failure is separable from a known one.
