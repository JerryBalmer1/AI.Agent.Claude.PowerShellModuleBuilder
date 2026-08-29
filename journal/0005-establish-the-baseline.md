---
pass: 0005
title: Establish the conformance baseline
date: 2026-08-28
artifacts:
  - git commits 64fee46, 6655e1c
  - evals/conformance/TASK.md (Pass 1 section)
  - evals/conformance/baseline/PHASE0.md
  - evals/conformance/baseline/FINDINGS.md
  - evals/conformance/baseline/FALSIFICATION.md
  - evals/conformance/baseline/psmodulegraph-result.json
---

# Pass 0005 — Establish the conformance baseline

## Asked

Recoverable from `evals/conformance/TASK.md`, whose Pass 1 section is the
instruction as written: replace one assertion (B1), housekeeping (B2), record
Phase 0 (C), re-run both invocations (D), sort failures into buckets (E), and
run the falsification protocol (F). Standing constraints: run against
`./scratch/PSModuleGraph` only, never fix the reference, never weaken an
assertion because the reference fails it, no push, no tags.

## Done

`git show --stat 64fee46`: 4 files. `git show --stat 6655e1c`: 6 files, 448
insertions.

- **B1.** `Repository shape.has a test file for the exported command` replaced
  with `exercises the exported command <_.BaseName> somewhere in tests`, which
  parses every `.ps1` under `tests/` and looks for a `CommandAst` matching the
  name. Written up as A6 in `FINDINGS.md`.
- **B2.** `conformance-result.json` removed from tracking and added to
  `.gitignore`; the workspace file's `../../PSModuleGraph` entry dropped.
- **C.** `baseline/PHASE0.md`.
- **D.** Both result files regenerated against the scratch clone.
- **E.** `baseline/FINDINGS.md` — six Bucket A entries, one Bucket B.
- **F.** `baseline/FALSIFICATION.md` — twelve breaks.

## Why

From `FINDINGS.md` A6: all six failures against the reference were the same
assertion, and all six were the suite's fault. The rule — one test file named
for each exported command — was invented by the suite rather than extracted from
the reference, which groups tests by subsystem. `EditorLink.Tests.ps1` covers
both EditorLink commands; the Knowledge commands are exercised from
`tests/Private/`. The replacement asserts the thing worth asserting: that some
test *invokes* the command. A name inside a string literal does not count.

Rejected, per `FINDINGS.md`: fixing the reference, and weakening the assertion
to accommodate it.

## Measured

- `baseline/PHASE0.md`: `./build.ps1 -Bootstrap` exit 0; `./build.ps1` exit 0 —
  263 passed, 0 failed, 3 skipped, line coverage 77.97% against a target of 75;
  `./build.ps1 -Task PreTag` exit 1, 4 passed 1 failed. PreTag's failure is that
  the version it is sealing is already tagged, recorded as not a blocker.
- Before B1, `Universal,HouseStyle` scored 69/75 — 92%. After: **74/75, 98.67%**
  (`baseline/psmodulegraph-result.json`). With `RequiresBuild`: **80/81, 98.77%**.
- `baseline/FALSIFICATION.md`, as written this pass: twelve rows, **10 fire
  cleanly, 1 over-fires, 1 does not fire.**

## Learned

**One assertion could not fail at all.** `throws on coverage below target rather
than only reporting it` matched `(?s)CoveragePercent.*throw` against the build
file. `(?s)` plus an unbounded `.*` means any `throw` anywhere after the first
mention of `CoveragePercent` satisfies it, and the reference's build file
contains nine. Recorded in `FALSIFICATION.md` under "Row 8".

Two checks past what the row required established how far it was from working:
with the coverage `throw` deleted it stayed green on the word "throw" in the
**comment explaining the throw**; with that comment also deleted it stayed green
on the Pester version guard in the `PreTag` task thirty-odd lines further down.
No edit to the coverage gate could turn it red. It had passed in every green run
since it was written, contributing a point while testing nothing.

Also learned, from `FALSIFICATION.md`'s "What was fiddly": `git checkout -- .`
does not restore the clone — untracked and renamed files survive — and
`git clean -fd` must never carry `-x`, because build output is gitignored and
deleting it silently invalidates every `RequiresBuild` row that follows.

## Capability

- The grader asserts that exported commands are *exercised*, not that files are
  named a particular way.
- Every assertion has a falsification row, so a green run is evidence rather
  than an absence of evidence.
- Phase 0 is recorded, so a conformance failure can be attributed to the suite
  or to the target rather than to a broken build.
