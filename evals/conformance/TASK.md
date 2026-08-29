# TASK — establish the conformance baseline

Standing instruction for the current pass. This file exists because a session
restart clears the conversation but not the repository. If you have lost
context, read this file and continue from the first unfinished step. Mark steps
done as you go by editing the checklist at the bottom and committing.

**Status: complete.** All steps done and committed in `64fee46` (suite
corrections) and `6655e1c` (baseline artifacts). Nothing pushed, no tags.
Results in `evals/conformance/baseline/`.

## Standing constraints

These apply to every step and are not negotiable within this task.

- Run against `./scratch/PSModuleGraph` only. Never `C:\__Code\PSModuleGraph`.
- Never modify the reference. Never modify PSAzureDevOpsGraph.
- Never weaken or delete an assertion because the reference fails it. Bring it
  to the operator instead.
- No new assertions beyond the one replacement specified in B1.
- No `git push`. No tags.
- If a step is blocked, stop and report. Do not work around it by skipping
  assertions or stubbing results.

## Verified state — do not re-establish

Five suite fixes from an earlier run survive in commit `d1647fa` and are all
correct. Do not redo or re-litigate them:

1. Manifest resolution: `$repoName` preference, relative-path exclusions for
   `output|scratch|.git|gallery|fixtures|node_modules`, `Select-Object -First 1`.
2. `@()` guards around helper returns.
3. `<_.Name>` instead of `<_>` in `-ForEach` test names.
4. `Describe 'House style: generated module' -Tag 'RequiresBuild'` alone.
5. `ScorePct` denominator is `PassedCount + FailedCount`.

Each is written up in full in `evals/conformance/baseline/FINDINGS.md` as
Bucket A entries A1-A5.

For the pre-fix baseline use git, not scratch:
`git show c1cf7ec:evals/conformance/Conformance.Tests.ps1`.
`scratch/Conformance.Tests.ps1.orig` has unknown provenance — ignore it.

Everything in `scratch/` is disposable and gitignored. That now also includes
`scratch/falsify-driver.ps1` and `scratch/falsification/`, written during
Step F. Nothing in `scratch/` is authoritative.

## Environment prerequisite

Any build against a clone outside `C:\__Code\` must set:

```powershell
$env:PSGRAPHRENDER_MODULE_PATH = 'C:\__Code\PSGraphRender\output'
```

The `Dependencies` task resolves PSGraphRender from a sibling checkout, and a
clone under `scratch/` has no sibling. Without this, Phase 0 and every rebuild
fail for a reason that has nothing to do with the reference. See
`evals/conformance/baseline/PHASE0.md`.

## Step B — corrections

### B1. Replace one assertion

DONE. The `has a test file for the exported command` It block in the
`Repository shape` Describe was replaced with `exercises the exported command
<_.BaseName> somewhere in tests`, an AST `CommandAst` check over the test tree.
Five of six failures disappeared. `Get-PSModuleAssembly` survived as predicted
and is confirmed as a genuine Bucket B finding — not fixed.

The AST limitation (`& $name`, splatting, aliases) is recorded as a known limit
in FINDINGS.md.

### B2. Housekeeping

DONE.

- `conformance-result.json` removed from tracking and added to `.gitignore`.
  Always pass `-ResultPath` explicitly.
- Trailing newlines: `Conformance.Tests.ps1` needed one and has it;
  `Invoke-Conformance.ps1` already had one.
- Workspace file edit dropping `../../PSModuleGraph` committed.

## Step C — record Phase 0

DONE. `evals/conformance/baseline/PHASE0.md`.

`-Bootstrap` green, default task green (263 passed, 0 failed, coverage 77.97%
against a target of 75), PreTag red on one assertion because the clone sits on
a sealed iteration whose successor has not bumped the version. Not a blocker.

## Step D — re-run both invocations

DONE.

| Output | Tags | Score |
|---|---|---|
| `baseline/psmodulegraph-result.json` | `Universal,HouseStyle` | 74/75 — 98.67% |
| `baseline/psmodulegraph-build-result.json` | `Universal,HouseStyle,RequiresBuild` | 80/81 — 98.77% |

## Step E — FINDINGS.md

DONE. Six Bucket A entries, one Bucket B entry, three known limits.

## Step F — Phase 2, falsification

DONE. `evals/conformance/baseline/FALSIFICATION.md`. Twelve breaks: ten fire
cleanly, one over-fires (`FunctionsToExport = '*'` turns three assertions red),
one does not fire at all (`throws on coverage below target`). The obsolete
filename-convention row was replaced in the README table with a break for the
new assertion, and the README now points at the recorded pass.

Non-firing assertions were left unfixed, per instruction. The coverage one
belongs in the next pass's Bucket A.

Notes on which steps were fiddly are in the "What was fiddly" section of
FALSIFICATION.md, as input to a later pass that turns this protocol into a
script and a skill. That automation was deliberately not built.

## Commits

Two, as specified:

- `64fee46` Replace an invented convention with the assertion it was standing in for
- `6655e1c` Record the baseline: Phase 0, both scores, and what the breaks proved

## Checklist

- [x] B1 assertion replaced
- [x] B2 housekeeping
- [x] C PHASE0.md written
- [x] D both result files regenerated
- [x] E FINDINGS.md written
- [x] F FALSIFICATION.md written
- [x] Commits made
- [x] Reported back

---

# Pass 2 — falsify what was recorded unfalsified

Opened after Pass 1 reported `throws on coverage below target` as inert. Two
assertions went into a scoring run without a confirmed red: B1, which was new,
and the coverage assertion, which had been inert since it was written. Same
defect, so the rule below is the first item.

## Standing constraints

Unchanged from Pass 1: `./scratch/PSModuleGraph` only, no fixes to the
reference, no weakening an assertion because the reference fails it, no push,
no tags. **No new assertions beyond G1.**

## New standing rule

An assertion does not count until it has a falsification row. Any assertion that
is added or changed gets a break, a confirmed red, and a restore before any
score including it is recorded. Added to `README.md`.

## G1 — replace the inert coverage assertion

`Should -Match '(?s)CoveragePercent.*throw'` cannot fail. Replace with an
AST-scoped assertion in the `House style: build file` Describe:

- Parse the build file. Locate the scriptblock of the Test task.
- Within that scriptblock only, find an `IfStatementAst` whose condition
  references the coverage percentage.
- Assert its body contains a `ThrowStatementAst`.

Constraints: confined to the Test task, must not match a throw belonging to any
other statement, must not depend on the wording of a comment.

Falsify before recording any score, with all three probes that defeated the old
assertion:

- a. delete the throw statement, keep the comment — must go red
- b. delete the throw statement and the comment — must go red
- c. coverage gate intact, delete an unrelated throw elsewhere in the build file
  (the Pester 6.x guard) — must stay green

If any probe gives the wrong answer, the assertion is not finished.

## G2 — fix the runner exit code

`Invoke-Conformance.ps1` exits non-zero on a red run, tracking the failure
count, contradicting its own comment and making a run harness read every red
conformance run as a crash. Add an explicit `exit 0` after the summary is
written, and a `-PassExitCode` switch for callers that do want the failure
count. Verify both paths via `$LASTEXITCODE` after a green run and a red one.

## G3 — record what G1 changes

- Re-run both invocations, overwriting both baseline result files.
- FINDINGS.md: add the inert assertion as Bucket A, and state plainly that the
  previous 74/75 included one assertion that could not fail, so the earned
  figure was 73/74 plus one unknown.
- FALSIFICATION.md: the three G1 probes and their outcomes.
- README falsification table: a row for the new assertion.
- Record the `FunctionsToExport = '*'` over-fire as expected coupling, not a
  fault. A wildcard export genuinely violates all three assertions. Do not
  decouple them.

## G4 — write the harness spec, do not build it

`evals/HARNESS.md`: what the run harness must do, from the Pass 1 notes. At
minimum the five hazards, each with the failure it causes. Specification only,
no code.

## Pass 2 outcome

- **G1.** Replaced with an AST-scoped assertion: `task Test` command -> its body
  scriptblock -> `IfStatementAst` whose condition reads the coverage percentage
  -> a `ThrowStatementAst` in that if's own body. Finds 1 gate and 1 throw
  against the reference, out of 9 throws in the build file.
- **G1 probes.** 8a red, 8b red, 8c (control) green. All three correct. The
  other 10 rows re-run unchanged to confirm no regression; the rebuild row too.
- **G2.** `exit 0` by default, `-PassExitCode` for the failure count. Verified:
  green/default 0, red/default 0, green/`-PassExitCode` 0, red/`-PassExitCode` 1.
  The summary object is still returned.
- **G3.** Both result files regenerated: 74/75 (98.67%) and 80/81 (98.77%) —
  numerically unchanged, but now every assertion in them is falsified.
- **G4.** `evals/HARNESS.md`, six hazards, specification only.

## Pass 2 checklist

- [x] Standing rule added to README
- [x] G1 assertion replaced
- [x] G1 probes a, b, c all give the right answer
- [x] G2 exit code fixed and both paths verified
- [x] G3 records updated, both result files regenerated
- [x] G4 HARNESS.md written
- [x] Commits made
- [x] Reported back

---

# Pass 3 — controls, and the closed loop

Opened after probe 8c turned out to be the result rather than a detail: a
negative control discriminates between two assertions that both pass the
positive break.

## Standing constraints

Unchanged. `./scratch/PSModuleGraph` only. Nothing from `gallery/modules/`
committed anywhere. No fixes to any corpus module. No new assertions. No
weakening an assertion because a target fails it. No push, no tags.

## New standing rule

A falsification row needs a negative control, not just a break. A break that
must go red proves the assertion can fail; a control that must stay green proves
it fails for the right reason. Added to `README.md` beside the Pass 2 rule, and
every row in the README table now carries a control column.

## Pass 3 outcome

- **Standing rule + control column.** Both in the README. Twelve controls
  designed, run, and recorded. **Eleven correct, one not:** adding a *comment*
  mentioning `Run.Exit = $true` turns `throws rather than exits` red. Twelve red
  breaks had not found that; the control did. Recorded, not fixed.
- **H1 — tag split.** `Repository shape` retagged `Universal` -> `Repository`.
  Runner `ValidateSet` and default tag set updated. Scores unchanged at 74/75
  and 80/81; per-tag counts 26 + 18 + 31 + 6 = 81, so nothing was dropped. All
  thirteen breaks and twelve controls re-run after the retag.
- **H2 — corpus.** All eight gallery modules fetched and run with `-Tag Universal`.
  Run as committed, **all eight collapse**: the suite cannot locate a published
  module's manifest, and on SqlServerDsc it silently graded a bundled helper
  module instead. Per-assertion data collected from a second pass with exactly
  two blockers neutralised outside the committed tree. **Five of ten Universal
  assertions survive all nine targets.** Seven Bucket A findings, four Bucket B.
  Nothing changed. See `baseline/UNIVERSAL-CORPUS.md`.
- **H3 — HARNESS.md.** Known-failure set respecified as persisted Bucket B
  classifications, keyed by assertion plus target, ratcheting both ways. Bucket
  A/B sorting recorded as not automatable, with the corpus evidence for why.
  Hazard 5 and the Phase 0 default-versus-sealing distinction marked
  *Evidence: 1 target*.

## Pass 3 checklist

- [x] Standing rule added to README
- [x] Control column backfilled across all 12 rows
- [x] Controls actually run, not just written down
- [x] H1 retag, ValidateSet, scores confirmed unchanged
- [x] H1 breaks and controls re-run after the retag
- [x] H2 corpus fetched, all eight run with -Tag Universal
- [x] H2 UNIVERSAL-CORPUS.md written, buckets sorted, nothing changed
- [x] H3 HARNESS.md revised
- [x] Commits made
- [x] Reported back
