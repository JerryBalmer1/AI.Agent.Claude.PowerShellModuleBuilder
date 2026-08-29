---
pass: 0010
title: Plan protocol, method file, journal backfill
date: 2026-08-28
artifacts:
  - PLAN-PROTOCOL.md
  - plans/README.md
  - plans/0010-plan-protocol/plan.md
  - method/METHOD.md
  - evals/conformance/baseline/CONTROL-SWEEP.md
  - journal/0001-initial-commit.md through journal/0007-controls-tag-split-corpus.md
---

# Pass 0010 — Plan protocol, method file, journal backfill

## Asked

Establish the plan format every later pass follows and apply it to this pass;
create the method file from a supplied draft and fold in the five rules Pass
0009 established; add a control-coverage table and record one deliberate
exception; backfill journal entries 0001 through 0007 from artifacts rather
than memory. Records only — no changes to the suite, the runner, the
falsification driver, or any result file, and no controls run.

A re-issue: the same pass stopped at its preconditions when the method draft
was named but not supplied.

## Done

- `PLAN-PROTOCOL.md`, 154 lines, at the repository root. The supplied format,
  plus a *Pass numbering* section and a new *File supply* section: a file a pass
  must create is either already committed or its full content appears verbatim
  in the prompt, and there is no third channel.
- `plans/README.md`, 53 lines. Plans are verification and disposable; journal
  entries are narrative and permanent.
- `plans/0010-plan-protocol/plan.md`. This pass's plan, written as the format's
  worked example.
- `method/METHOD.md`, 243 lines. The supplied draft verbatim, with the five Pass
  0009 rules folded into the sections they belong to, all marked **PORTABLE**. A
  new section, *The falsification harness*, was added to hold rule 4 and two
  existing harness rules that had no home in the draft.
- `evals/conformance/baseline/CONTROL-SWEEP.md`, +99 lines: a 33-row control
  coverage table, the counts, and the documented exception.
- `journal/0001` through `journal/0007`, seven entries mapped to eleven commits.

## Why

The backfill's pass boundaries are drawn from `git log --reverse` and
`git show --stat`, one entry per logical unit of work rather than one per
commit — 0005 covers two commits, 0006 covers three. The alternative was one
entry per commit, which would have split a single pass across three entries and
made `Asked` unanswerable for two of them.

`Asked` is written as "not recoverable" for 0001 through 0004 rather than
inferred from the diff. `evals/conformance/TASK.md` does not exist until commit
`52498ec`, so for the four passes before it there is no record of what was
asked, only of what was done. Inferring the instruction from the outcome is the
one thing a backfill must not do, because it makes every pass look like it did
what it was told.

Rule 4 got a new section rather than being filed under *The grader*. The draft
had rules about the grader and none about the harness that probes it, and a rule
about stale expectations in a falsification driver is not a rule about graders.

## Measured

No measurement was taken this pass; nothing was executed. The one number
produced is a count over an existing artifact.

From the `Assertions` breakdown in
`evals/conformance/baseline/psmodulegraph-build-result.json`, cross-referenced
against the falsification driver's row definitions:

- 33 assertions — 29 positive, 4 negative
- **12** positive assertions carry both a scope control and a substitution
  control
- **16** positive assertions carry only one, the substitution control from the
  Pass 0009 sweep
- 1 positive assertion carries only a break, by design
- 4 negative assertions are fully covered, their single control answering both
  questions

Reference scores were not re-run and are unchanged from `d0f23a1`: 74/75 and
80/81.

## Learned

- **A gate that stops a pass is cheaper than one that does not.** The first
  issue of this pass stopped at precondition 4 with nothing committed. The same
  missing file had blocked a task in Pass 0009 *silently*, and cost a pass. The
  difference between the two outcomes was entirely whether the requirement was
  stated as a precondition.
- **One of the four findings the prompt required in the backfill could not
  honestly go there.** The discovery defect — deleting the reference's manifest
  producing a confident score against a vendored module — was found in Pass
  0009 and is recorded in `journal/0009`. Backdating it into 0001–0007 would be
  the reconstruction the same task forbids. What went in instead is its
  lineage: the same shape appears three times, in `FINDINGS.md` A1,
  `UNIVERSAL-CORPUS.md` A-C1, and `CONTROL-SWEEP.md`, each occurrence one
  selection rule further down than the last repair had reached.
- **Reading the artifacts contradicted what I would have written from memory
  in one place.** The falsification summary I would have recalled for Pass 0005
  was "twelve rows, all fire but one"; `FALSIFICATION.md` at `6655e1c` says "10
  fire cleanly, 1 over-fires, 1 does not fire". The over-fire is the wildcard
  export coupling, which is a deliberate finding rather than a clean pass, and
  the difference matters.
- **The coverage table is transcribed, not generated.** It was built by reading
  the driver's row definitions against the assertion list. That is as reliable
  as the reading, and a driver that emitted its own coverage map would remove
  the transcription step.

## Capability

- Every later pass has a stated format, in the repository, that survives a
  session restart: prompt verbatim, preconditions with their output, per-task
  evidence, transcript, deviations, and a verify script at full tier.
- A pass can be stopped by its preconditions with nothing committed, and the
  stop is itself a recorded artifact.
- The general method is separable from this project: `method/METHOD.md` carries
  it with each rule marked PORTABLE, TUNE or DOMAIN, so a reader can tell what
  travels.
- The project's history is readable from `journal/0001` through `0010` without
  reading a diff, and every number in it names the artifact it came from.
- Control coverage is countable, so the question "is a second sweep worth a
  pass" has a number behind it rather than an impression.
