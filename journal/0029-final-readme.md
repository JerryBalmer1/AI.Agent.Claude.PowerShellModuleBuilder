---
pass: 0029
title: The final README, and what the four runs actually measured
date: 2026-09-01
artifacts:
  - README.md
  - method/METHOD.md
  - evals/HARNESS.md
  - LEDGER.md
  - plans/0029-final-readme/plan.md
  - plans/0029-final-readme/accept.Tests.ps1
---

# Pass 0029 — The final README, and what the four runs actually measured

## Asked

The rider on pass 0028, to run in the same session once the ladder closed and
only if runs 004, 005 and 006 all showed three complete score lines. Write the
final harness README from the journal and the run records: the with/without table
on `cases-defined` with first-shot and final separated, per-run variance stated
plainly, the wall-clock cost of a run, the recurring findings, three paste-able
commands, the guardrails, and a direct answer to "why not just prompt Claude to
write a module". Every number cites its artifact; ugly numbers get printed.
tf-001/tf-002 and the ecosystem get their own section. Fold two rules into
METHOD.md and backlog items 12/13/14 into `evals/HARNESS.md` as numbered hazards.
Update the LEDGER; plan and journal; push; fast-forward `main`.

## Done

- `README.md` rewritten end to end. It had still described run 002 as "the latest
  run" and said the plugin's effect was "unmeasured — that is what run 003 is
  for".
- `method/METHOD.md`: two PORTABLE rules added to *The falsification harness* —
  an assertion about a declaration is not an assertion about the thing declared,
  and parallel scoring jobs must be isolated per clone.
- `evals/HARNESS.md`: hazards **9, 10, 11** — the blind-session gate and run
  records as oracle knowledge; the memory-poisoning vector; the commit-subject
  convention. One file, +69 lines, 0 deletions, no assertion, script or fixture
  touched.
- `LEDGER.md`: passes last 0029 next 0030; item 1 and items 12/13/14 marked
  resolved; new items 17 and 18; and the pin consequence of the `evals/` edit.
- `plans/0029-final-readme/` — acceptance test and plan.
- Run 003 re-scored from its pushed branch with today's suite to obtain a
  `cases-defined` figure its own artifact does not carry.

## Why

**The table had to be built from a re-derivation, not a quotation.** Run 003's
`conformance-result.json` predates pass 0025 and has no `CasesDefined`. Quoting
its 39/55 into a cases-defined column would have been a category error, so its
branch was re-cloned at `d852abc`, rebuilt and re-scored with the current suite:
19/33. Same instrument, different target, which is the only comparison that
means anything.

**The headline number is the one that flatters least.** Reading the table as
`0 → 12` is wrong twice over: run 003 was never permitted a final score, and the
comparable first-shot row moves 0/12 → 1/12. The README says both in the body.
The honest result is that the plugin's large, repeatable effect is on **shape**
(19/33 → 33/33, three times) and its behavioural effect is exactly four rules,
against one error it introduces itself.

**Grouping the differences by mechanism is what makes the result legible.** 25 of
the 29 baseline differences are the three conventions the instrument never
states, and they are unchanged with the plugin. A reader given only the scores
would conclude the plugin fixed the graph; a reader given the breakdown can see
that it fixed `checkout: self`, the empty-repository node, and the unresolved-id
scheme, and nothing else.

**The `evals/` fold breaks the ladder's own precondition, so it is written down.**
Runs 004–006 assert that the diff over `skills/ commands/ .claude-plugin/ evals/`
is empty; after this pass it is not. Leaving that for the next blind run to
discover as a hard stop would have cost a session for a reason that is not about
the instrument.

## Measured

- Acceptance: **21 of 24 failed** before the work, **24 of 24 pass** after.
- Run 003 re-scored on the stable denominator: **19 / 33 cases-defined**,
  39 / 55 cases-run, 14 assertions carrying failures — re-derived from
  `d852abcff0efae39978000f48190c7240c5418bd` with the current suite.
- With/without, `cases-defined`: **19/33 off** → **33/33 on**, in each of runs
  004, 005 and 006.
- Functional first-shot: **0/12 off** → **1/12 on**, all three plugin runs.
  Functional final: *never permitted* off → **12/12** on, all three.
- First-shot differences: **29 off** → **26 on**, identical across the three
  plugin runs. By mechanism, off → on: `repo` 15 → 15, `alias` 8 → 8, `reason`
  2 → 2, `extraNode` 1 → **0**, `extraEdge` 1 → **0**, `wrongEdgeTarget` 2 → **0**,
  `missingNode` 0 → **1**.
- Recurrence: **8 of 10** prior findings recurred in run 006.
- Cost of a run: Phase 1 **23–34 minutes**; scoring **~60 s** for three parallel
  jobs from three fresh clones; live graph command **9.8 / 15.3 / 10.7 s** against
  a 5-minute cap.
- `evals/` change scope: `evals/HARNESS.md` only, **+69 / −0**. Plugin proper
  diff vs `f25d05d`: **empty**.

## Learned

- **The instrument's silence is where the model's variance lives, and it is not
  random.** Three blind sessions guessed the same three conventions wrong in the
  same direction, and the plugin-off run guessed them wrong in exactly the same
  direction too. All four runs, plugin or no plugin, produced identical counts of
  15 / 8 / 2 on those mechanisms. That is a much stronger statement than any score
  on the page, and it was only visible after grouping.
- **The baseline is the weakest link in the whole comparison**, and finishing the
  ladder made that obvious rather than hiding it. One plugin-off run, never
  allowed to iterate, against three plugin-on runs allowed three iterations each.
  A second plugin-off run under the same rules is now the highest-value single
  run remaining (backlog 17).
- **This repository's own hazard 8 caught me while I was folding hazards 9–11.**
  Two acceptance assertions reported a phrase absent that was demonstrably
  present, because the sentence wrapped across a line break. The documented
  protection — collapse whitespace before matching — was the fix, and writing the
  hazard down had not been enough to avoid it. That is the second time this
  project has recorded the hazard recurring inside work on the hazard itself.
- **Wrong prediction, corrected by the artifact:** I expected run 003's two
  `wrongEdgeTarget` differences to be mis-anchored resolution — the wrong file
  chosen by the wrong rule. They were not. Both were unresolved-target *id
  scheme* differences, and run 003's own README is right that the anchoring rules
  resolved correctly. The README says so rather than claiming a resolution win
  the evidence does not support.

## Capability

It is now possible to state what this plugin does to an agent's output with an
artifact behind every number, and to state equally precisely what it does not do:
shape 19/33 → 33/33 repeatably, four named behavioural rules fixed, one error
introduced, and three field conventions untouched. The harness can also now be
handed to someone else — three paste-able commands reproduce a run end to end,
and the eleven hazards in `evals/HARNESS.md` include the three that make a blind
measurement possible at all.
