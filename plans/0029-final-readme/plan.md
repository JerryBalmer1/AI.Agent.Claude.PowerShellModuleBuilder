# Pass 0029 — the final README

## What this pass is

The rider on pass 0028, executed in the same session immediately after the
ladder closed. Its precondition — runs 004, 005 and 006 all showing three
complete score lines — was satisfied by 0028's own artifacts.

Contamination is irrelevant by this point: the rider runs **post-gate**, and
writing it requires reading the run records that a blind builder may not read.

## Tasks, as executed

- [x] 1. Acceptance red first — 3 passed, **21 failed** of 24.
- [x] 2. Final harness README, written from the journal and the four run records.
- [x] 3. Two folds into `method/METHOD.md`.
- [x] 4. Backlog items 12 / 13 / 14 folded into `evals/HARNESS.md` as hazards 9, 10, 11.
- [x] 5. LEDGER: passes last 0029 next 0030, resolved items, two new backlog items, and the pin consequence.
- [x] 6. Acceptance green — **24 / 24**.
- [x] 7. Plan and journal; push; fast-forward `main`.

## The number that had to be re-derived

The with/without table is specified on `cases-defined`, the stable denominator
introduced in pass 0025. **Run 003's committed `conformance-result.json` has no
`CasesDefined` field** — it predates that pass.

Rather than quote its `39 / 55` cases-run figure into a cases-defined column, run
003's pushed branch was re-cloned at its recorded `target-sha`
(`d852abc`), rebuilt, and re-scored with **today's** suite: the same instrument
against a different target, which is the only form of the comparison that means
anything. It reads **19 / 33 cases-defined**, 39 / 55 cases-run, 14 assertions
carrying failures. That is the number in the table.

## Two things the table must not be allowed to say

**It must not read as `0 → 12`.** Run 003 was run under a protocol that said
*"No fixes, no re-runs — the first scores stand"*. It has no final score because
it was never permitted one. The final row says *never permitted* and the README
says in the body that nobody knows what run 003 would have reached with three
iterations. The comparable row is first-shot: **0 / 12 against 1 / 12**, which is
nearly flat.

**It must not hide where the plugin did nothing.** Grouping the first-shot
differences by mechanism shows 25 of 29 unchanged between plugin-off and
plugin-on — the three field conventions the instrument never states. The plugin's
measured behavioural effect is four specific rules fixed and one error introduced:

| Mechanism | 003 off | 004/005/006 on |
|---|---:|---:|
| `repo` omitted from `pipeline` nodes | 15 | 15 |
| `alias` written where the oracle omits it | 8 | 8 |
| `reason` as a bare token | 2 | 2 |
| `extraNode` — empty repository emitted | 1 | **0** |
| `extraEdge` — `checkout: self` turned into an edge | 1 | **0** |
| `wrongEdgeTarget` — colliding unresolved ids | 2 | **0** |
| `missingNode` — `repo:consumer-app` | 0 | **1** |
| total | 29 | 26 |

Both statements are in the README body, not in a footnote.

## The `evals/` change, and what it breaks

Folding the hygiene items into `evals/HARNESS.md` is **the one sanctioned
post-ladder `evals/` documentation change**. Verified scope: `evals/HARNESS.md`
only, **+69 lines, 0 deletions**, no assertion, script or fixture touched.

    git diff --cached --stat f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/
    evals/HARNESS.md | 69 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++

**Consequence, recorded rather than discovered later.** Runs 004–006 asserted at
preconditions that

    git diff f25d05d..main -- skills/ commands/ .claude-plugin/ evals/

is empty. It no longer is, so a future blind run written against that exact
command hard-stops for a reason that has nothing to do with the instrument. The
plugin proper still checks empty:

    git diff f25d05d..main -- skills/ commands/ .claude-plugin/     # empty

The LEDGER's Pins section now carries this, with both forms.

## Deviations, declared

1. **The acceptance test was edited after its first red**, and the reason is
   not that it was inconvenient. Two prose assertions could not match a phrase
   that was demonstrably present, because the sentence wraps across a line break
   in a reflowed document. That is **hazard 8 in this repository's own
   `evals/HARNESS.md`**, and the protection that hazard prescribes is to collapse
   whitespace before matching — not to reflow the prose to suit the regex. The
   claim under test is unchanged; only the matching was fixed, and the reason is
   written into the test file beside it.
2. **Backlog item 13 does not exist as a numbered entry.** The LEDGER jumps 12 →
   14; item 13's wording was absorbed into item 12 when the memory clause was
   added, and `plans/0026-run-004/plan.md` refers to "the vector backlog item 13
   names". It is folded as hazard 10 and the LEDGER now says so, so the gap stops
   being a puzzle for the next reader.

## Evidence

| Claim | Where |
|---|---|
| Acceptance red then green | 21 / 24 failed, then 24 / 24 passed, both in this session |
| Run 003 re-scored on cases-defined | 19 / 33, re-derived from `d852abc` with today's suite |
| Difference breakdown, plugin off | `runs/003-baseline-off/compare-report.json` |
| Difference breakdown, plugin on ×3 | `runs/00{4,5,6}-plugin-on/compare-report*.json` |
| `evals/` change scope | `git diff --stat` above: one file, +69, −0 |
| Plugin proper untouched | `git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/` empty |
