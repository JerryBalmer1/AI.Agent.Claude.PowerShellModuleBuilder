---
pass: 0004
title: Five suite fixes, the real runner, and the first baseline
date: 2026-08-28
artifacts:
  - git commit d1647fa
  - evals/conformance/baseline/FINDINGS.md (entries A1-A5)
  - evals/conformance/baseline/psmodulegraph-result.json (at d1647fa)
  - evals/conformance/baseline/psmodulegraph-build-result.json (at d1647fa)
---

# Pass 0004 — Five suite fixes, the real runner, and the first baseline

## Asked

Not recoverable. Commit subject is "force agent stop".

## Done

`git show --stat d1647fa`: 6 files, 230 insertions, 9 deletions.

- `evals/conformance/Conformance.Tests.ps1` — +53/-9, the five fixes below.
- `evals/conformance/Invoke-Conformance.ps1` — 89 lines, the runner written for
  the first time at the path the documentation names.
- `evals/conformance/baseline/psmodulegraph-result.json` and
  `psmodulegraph-build-result.json` — the first committed scores.
- `.gitignore` — one line, `scratch/`.
- `conformance-result.json` — 16 lines, committed **at the repository root**,
  from a zero-test run.

The five fixes, written up later as A1-A5 in `baseline/FINDINGS.md`:

1. **Manifest resolution picked the wrong module.** Candidates were filtered on
   absolute path and tie-broken by shortest path, so `corpus/PSCorpus/PSCorpus.psd1`
   beat `src/PSModuleGraph/PSModuleGraph.psd1` and the suite graded a vendored
   fixture. Fixed by preferring the manifest named for the repository directory,
   matching exclusions against the path *relative* to the target, and using
   `Select-Object -First 1` rather than `[0]`, which throws on an empty array
   under `Set-StrictMode -Version Latest`.
2. **`.Count` on a scalar threw under StrictMode.** A helper returning one
   element has it unrolled by the pipeline. `@()` guards added around helper
   returns.
3. **Test names were not stable across targets.** `<_>` in a `-ForEach` name
   stamped a `FileInfo`'s absolute path into the test name, so names in
   `result.json` changed with the target's location and scores could not be
   diffed between runs. Changed to `<_.Name>`.
4. **`House style: generated module` ran without a build.** The block carried
   `'HouseStyle', 'RequiresBuild'` and Pester's tag filter is an OR, so it ran
   under the documented no-build invocation against an absent psm1 — six
   guaranteed false failures. Changed to `'RequiresBuild'` alone.
5. **`ScorePct` charged the score for tests nobody ran.** The denominator was
   `TotalCount - SkippedCount`, which includes tests filtered out by `-Tag`.
   Changed to `PassedCount + FailedCount`.

## Why

Recoverable only from the fix comments in the suite, which are unusually full.
A1's comment records the specific failure: a repository can carry a second
module at a shallower path than its own. A5's records the specific number: a
`Universal,HouseStyle` run scored 85% instead of 92% purely because
`RequiresBuild` was excluded.

## Measured

From the result files committed at `d1647fa`:

- `Universal,HouseStyle`: 69/81, **85.19%**
- with `RequiresBuild`: 75/81, **92.59%**

Both name `Target: C:\__Code\PSModuleGraph` — the reference itself, not a
scratch clone.

## Learned

A1 is the project's first instance of what became a recurring shape: **the
grader silently grading the wrong artifact.** A vendored module won a
shortest-path tie-break and the suite reported a confident score about it. The
same shape recurred twice more — a bundled helper out of 51 manifests in
`baseline/UNIVERSAL-CORPUS.md` (A-C1), and a lone surviving candidate in
`baseline/CONTROL-SWEEP.md` — each time one selection rule further down than the
last repair reached.

Also visible in the artifact and corrected later: `conformance-result.json` was
committed at the repository root from a run with no tests, because the runner's
default `-ResultPath` was relative to the working directory.

## Capability

- The grader resolves the repository's own module rather than whichever manifest
  sorts first.
- It runs under `Set-StrictMode -Version Latest` without throwing.
- Its scores are comparable between runs, because test names no longer carry
  absolute paths and the denominator no longer counts tests that were filtered
  out.
