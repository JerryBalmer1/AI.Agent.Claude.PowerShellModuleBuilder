---
decision: 0003
title: A score comparison is valid only when cases-run is stable
date: 2026-08-28
status: accepted
passes: 0008, 0009
artifacts:
  - evals/conformance/baseline/UNIVERSAL-CORPUS.md
  - evals/conformance/Invoke-Conformance.ps1
---

# A score comparison is valid only when cases-run is stable

## Context

Pass 0008 repaired the suite's definition index so it reads `.psm1` files and
strips scope qualifiers from function names. The corpus was re-run and the
scores moved:

| Module | Before | After |
|---|---|---|
| SqlServerDsc | 8/11 (72.73%) | 170/171 (99.42%) |
| Pester | 9/11 (81.82%) | 36/36 (100%) |
| PSDepend | 18/19 (94.74%) | 18/18 (100%) |
| ImportExcel | 17/67 (25.37%) | 17/79 (21.52%) |

Read as percentages, SqlServerDsc improved by 27 points and ImportExcel got
worse by 4. Neither statement means anything. SqlServerDsc's 161 exported
functions live in a `.psm1` the suite could not previously open, so the earlier
run measured 11 cases where 171 applied. ImportExcel's score fell because the
help assertion reached 60 more of its functions, all of which are genuinely
undocumented — the module did not change and neither did its quality.

The denominator moved. The two runs are not two measurements of the same thing.

## Decision

**A score comparison is valid only when cases-run is stable between the two
runs. Any report comparing two scores must state cases-run for both.**

Not the percentages with cases-run in a footnote — both figures, side by side,
wherever the comparison is made. `17/79` next to `17/67` is self-evidently not a
4-point regression. `21.52%` next to `25.37%` reads as one.

Where cases-run differs, the report says what changed and why, and does not
present the delta as a result. The correct sentence for SqlServerDsc is "the
suite now measures 171 cases where it measured 11", not "SqlServerDsc improved".

## Why this needs saying

Every incentive runs the other way. A percentage is compact, comparable-looking,
and the thing a reader remembers. A suite that grades things will be asked
whether the number went up, and the honest answer is frequently "the number is
not answerable in that form this time".

The failure mode is specific and it is not hypothetical: an assertion that stops
producing cases makes a score go up. If the help assertion had been *broken*
rather than repaired — if it had silently stopped resolving exported functions —
every corpus module would have scored better, and a report tracking percentages
would have recorded an improvement. That is the same defect as the inert
coverage assertion, arriving through arithmetic instead of through a regex.

## Support in the tooling

`result.json` carries `CasesRun` beside `Total`, and an `Assertions` breakdown
giving `Ran`, `Passed` and `Failed` per assertion keyed by unexpanded test path.
An assertion that produced no cases is *absent* from that breakdown rather than
appearing as a pass, which is what makes a denominator change visible instead of
silent.

The runner's own summary line prints `Passed/CasesRun` and the assertion count,
not a bare percentage.

## What was rejected

**Normalising scores to a fixed denominator** so runs are always comparable.
Rejected: it would require deciding what an inapplicable assertion counts as,
and every available answer is wrong. Counting it as a pass rewards breakage;
counting it as a failure punishes a module for a directory it had no reason to
have; excluding it is what already happens and is exactly the thing that has to
be *stated* rather than smoothed over.

**Reporting only raw counts and dropping percentages.** Rejected as
over-correction. A percentage is useful within one run, across assertions. The
rule is about comparison across runs.

## Consequences

`UNIVERSAL-CORPUS.md` carries a before column with both figures and a paragraph
saying the case counts moved further than the scores. Any future pass reporting
a score change against an earlier one must do the same, or state that cases-run
was stable.
