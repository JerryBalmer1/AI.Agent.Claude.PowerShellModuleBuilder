---
pass: 0006
title: Make the coverage assertion capable of failing; spec the harness
date: 2026-08-28
artifacts:
  - git commits 52498ec, a8cbef1, 49d214e
  - evals/conformance/TASK.md (Pass 2 section)
  - evals/conformance/baseline/FINDINGS.md (entry A7)
  - evals/conformance/baseline/FALSIFICATION.md (rows 8a-8c)
  - evals/HARNESS.md
---

# Pass 0006 — Make the coverage assertion capable of failing; spec the harness

## Asked

Recoverable from `evals/conformance/TASK.md`, Pass 2 section: replace the inert
coverage assertion with an AST-scoped one (G1) and falsify it with all three
probes that defeated the old one; fix the runner's exit code (G2); record what
G1 changes (G3); write the harness specification without building it (G4).

## Done

- `evals/conformance/TASK.md` committed to the repository (`52498ec`, 217
  lines). It had claimed to exist so a restart would not lose the pass, and did
  not exist.
- **G1.** The coverage assertion rewritten to parse the build file, find the
  `task Test` command, take its body scriptblock, find the `IfStatementAst`
  whose *condition* reads the coverage percentage, and require a
  `ThrowStatementAst` in that if's own body.
- **G2.** `Invoke-Conformance.ps1` gains an explicit `exit 0` and a
  `-PassExitCode` switch.
- **G3.** `FINDINGS.md` entry A7; `FALSIFICATION.md` rows 8a-8c; a README row.
- **G4.** `evals/HARNESS.md`, 169 lines, specification only.

## Why

From `FINDINGS.md` A7: the assertion was not weak but *inert*. Matching the
condition rather than the file is what stops a comment counting; searching only
that if's own body is what stops the other eight throws counting.

The standing rule added this pass — an assertion does not count until it has a
falsification row — is recorded in the README as written from a specific
failure: two assertions had by then entered a scoring run without a confirmed
red, A6 because it was new and A7 because it was inert.

`HARNESS.md` is specification and no code, deliberately: the notes from doing
the protocol by hand are the specification for the tool.

## Measured

- Reference unchanged across the pass: **74/75 (98.67%)** and **80/81 (98.77%)**
  (`baseline/psmodulegraph-result.json`, `psmodulegraph-build-result.json`).
- G1 probes, from `FALSIFICATION.md` rows 8a-8c: delete the throw keeping the
  comment → **red**; delete throw and comment → **red**; leave the gate intact
  and delete both Pester version guards → **green**.
- G2, from `TASK.md`'s Pass 2 outcome: green/default exit code 0, red/default 0,
  green with `-PassExitCode` 0, red with `-PassExitCode` 1.

## Learned

**A red probe alone does not finish an assertion.** An assertion scoped to the
Test task rather than to the coverage gate inside it passes probes 8a and 8b and
is still wrong — it would also go red when an unrelated `throw` in the same task
is deleted. Only 8c, the control that must stay **green**, separates the two.
One of the two guards 8c deletes is inside the Test task but outside the gate,
which is what makes it a discriminator rather than a formality.

Second, recorded in `FINDINGS.md`: the Pass 0005 figure of 74/75 should be read
as **73/74 plus one unknown**, because it included an assertion that could not
fail. The number after this pass is numerically identical and is now the whole
of it.

Third: the runner contradicted itself. Three lines of comment said a red run is
data, not a build failure, while Pester set the exit code to the failure count
even with both `Run.Throw` and `Run.Exit` off. A harness checking exit codes
would have discarded every red run without reading the score it had just
written.

## Capability

- The coverage assertion can fail, and fails only for its own reason.
- A red conformance run exits 0, so a harness can distinguish "the target scored
  badly" from "the runner crashed"; `-PassExitCode` restores the counting
  behaviour for a caller that wants it.
- The standing instruction survives a session restart, because it is a file in
  the repository rather than a conversation.
- The harness has a written specification, including the hazards that had
  actually bitten, each paired with the failure it causes.
