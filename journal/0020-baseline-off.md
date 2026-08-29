---
pass: 0020
title: Measure the module built with the plugin unread
date: 2026-08-29
artifacts:
  - runs/003-baseline-off/README.md
  - runs/003-baseline-off/findings.md
  - runs/003-baseline-off/graph.json
  - runs/003-baseline-off/diff.txt
  - runs/003-baseline-off/003.html
  - runs/003-baseline-off/compare-report.json
  - runs/003-baseline-off/conformance-result.json
  - plans/0020-baseline-off/plan.md
  - plans/0020-baseline-off/verify.ps1
  - plans/0020-baseline-off/accept.Tests.ps1
---

# Pass 0020 — Measure the module built with the plugin unread

## Asked

Build `PSAzureDevOpsGraph` from the seed and `BRIEF.md` alone, with `skills/`,
`commands/`, `cases.md`, `expected-graph.json`, `fixture/repos/` and every prior
run and plan unread, then score it the same way run 002 was scored. One attempt,
no score-and-retry. Push the result to `run-003-baseline-off` as a measurement
line: no tag, no target `main`. Report the three scores, Phase 1 wall-clock, and
any allowlist breach.

## Done

- `run-003-baseline-off` in `PSAzureDevOpsGraph`, tip
  `d852abcff0efae39978000f48190c7240c5418bd`, three commits on the seed. 13
  module files, 7 exported commands, 61 tests, `build.ps1`.
- `runs/003-baseline-off/` — `README.md`, `graph.json`, `diff.txt`, `003.html`,
  `findings.md`, plus the two grader outputs.
- `plans/0020-baseline-off/` — `plan.md`, `accept.Tests.ps1` (15 assertions, red
  then green), `verify.ps1` (exits 0; re-derives all five named spot-checks).
- No tag was created and no `main` in `PSAzureDevOpsGraph` was moved. `evals/` is
  byte-identical to `42c717b98…`, asserted by `verify.ps1`.

## Why

The acceptance test was written from the prompt's field list rather than by
copying run 002's, because `plans/` is forbidden during Phase 1 and the prompt
enumerates every field. Reading it would have been a breach for no gain.

`PLAN-PROTOCOL.md` sits on neither the allowlist nor the forbidden list. It was
deferred to after the gate rather than read on the argument that it "obviously
could not leak module design" — the rule is that anything outside the allowlist
is named, and an agent that grants itself exceptions on plausibility has no
allowlist.

The graph command was run inside `Start-Job` with `Wait-Job -Timeout 300` so the
prompt's five-minute cap is enforced by the harness rather than by watching. All
three exports finished in 14–17 s.

Rejected: re-scoring after a one-line fix. Fifteen of the twenty-nine
differences are one omitted property, and the temptation to fix it and re-run was
real. The prompt says the first scores stand, and a baseline that is quietly
improved before being written down measures the improver, not the baseline. The
fix is proposed in `findings.md` as a *separate, labelled* number for a later
pass instead.

Rejected: repairing the conformance grader defect found while reading the score
(Deviation 5). Altering a grader mid-measurement would break comparability with
run 002, which decision 0003 exists to protect.

## Measured

From `runs/003-baseline-off/conformance-result.json`, `compare-report.json` and
the build's exit code — each re-derived by `verify.ps1` from a fresh clone:

| Score | Result |
|---|---|
| build | exit 0, 61/61 tests, PSScriptAnalyzer clean |
| conformance (4 tags) | **39 / 55** (70.91%), 16 failures |
| functional | **0 / 12** — case-01 … case-12, all twelve |

Differences by kind (`compare-report.json` `.countsByKind`):
`wrongNodeAttribute` 15, `wrongEdgeAttribute` 10, `wrongEdgeTarget` 2,
`extraNode` 1, `extraEdge` 1, and **`missingNode` 0, `missingEdge` 0**.

Phase 1 (blind build): 2026-08-29T09:44:07Z → 10:16:44Z, **32.6 minutes**.
Allowlist breaches: **1**, itemised in the plan's Deviations.
Findings: **5 mechanisms** in `findings.md`.

## Learned

**The 0/12 is not a graph failure.** Nothing the oracle contains is missing from
the candidate. Every difference is an extra attribute, a naming convention, one
extra node or one extra edge. The blind build derived both anchoring rules,
terminated a cycle, collapsed a diamond, kept `extends` distinct from `template`,
refused a `template:` inside a shell script, and computed the missing file's path
character-for-character as the oracle has it — then recorded that correct
resolution under an id it could not match.

**One omitted property costs the entire functional score.** `repo` is declared on
the generic node in `graph.schema.json` but required only for `kind: yaml`. I
read the conditional as the specification. The oracle also carries it on
`pipeline` nodes, and because the case tags live there, that single omission
fails all twelve cases. The schema is a floor, not a description — and a
candidate cannot learn that from the schema.

**Volunteering schema-valid attributes is a way to lose.** Eight edges differ
only by an `alias` the oracle omits as recoverable from `ref`. Under a set
comparison, optional-and-permitted is not optional.

**A grader defect, found by being scored by it.** `Conformance.Tests.ps1:504`
asserts `@(Get-BuildTaskCommand …).Count | Should -BeGreaterThan 0`.
`Get-BuildTaskCommand` returns `$null` for a file that will not parse, and
`@($null).Count` is 1. So five "declares the task …" assertions pass against a
build file that does not exist — about nine points on 55. This run's 39/55 is
flattered by it, and so is run 002's number. Both need recomputing if it is
fixed. Ironic given the same block's comment records an earlier hardening
against exactly this class of false pass.

**A platform defect that cost real time twice.** On pwsh 7.6.5, `@($x)` throws
`ArgumentException` for any `List[object]`, while `.Count`, `foreach` and the
pipeline all work. It silently dropped every `resources:` block in nine fixture
files, and the exception was attributed to the `foreach` line rather than to
`@()`. It belongs in `method/`, not in one run's record: any run on this machine
can hit it.

**The breach was mine and it was avoidable.** `git ls-tree -r --name-only` to
locate the oracle blob printed every filename under `fixture/repos/`, disclosing
that cycles and diamonds are tested and that `steps-build.yml` exists at two
depths — the two areas where this run's correctness results are strongest.
`git rev-parse <ref>:<path>` would have asserted the blob and leaked nothing.

## Capability

The project can now state what the plugin is carrying on this task, with a
control to point at rather than an assumption: **convention transfer, not domain
reasoning.** A comparison of run 002 against run 003 is now possible on every
axis the graders measure, and `verify.ps1` lets an operator disprove the baseline
from a fresh clone without reading the plan.

What is *not* now possible, and should not be claimed: separating derivation from
recall. The builder is the same model family that wrote the skills, so some of
what reads as reasoning from the brief may be memory of the reasoning that
produced them. This run cannot tell the difference and its record says so.
