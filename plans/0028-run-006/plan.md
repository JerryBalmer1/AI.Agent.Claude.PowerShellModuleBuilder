# Pass 0028 — run 006, the final rung

## What this pass is

The third of three consecutive complete plugin-on runs from wiped state, at the
same seed, brief, plugin SHA and model version as runs 004 and 005. The
deliverable is not a module — it is a **variance measurement**. With this run the
AzDO-module ladder is closed and the 0029 final-README rider becomes eligible.

## Preconditions, all verified before anything was built

| # | Check | Result |
|---|---|---|
| 1 | Trees clean, both repositories | clean |
| 2 | `git diff f25d05d..main -- skills/ commands/ .claude-plugin/ evals/` | **empty** |
| 3 | `model-version` equals the pin `claude-opus-5[1m]` | equal |
| 3 | `session-identifier` distinct from 004's and 005's | distinct from both |
| 4 | Oracle blob `bd7b3c4f…` (ls-tree only, never opened) | present at `evals/functional/fixture/expected-graph.json` |
| 4 | BRIEF blob `93c5cec3…` | matches |
| 5 | `$env:AZDO_PAT` set; `scratch/runs/006-plugin-on` absent; remote branch absent | set / absent / absent |
| 6 | 004 and 005 READMEs exist on `main`, by line count only | 135 and 257 lines, contents not read |

The oracle is not at `evals/functional/expected-graph.json`; it is one directory
lower, under `fixture/`. It was located **by blob SHA** with `git ls-tree | grep`,
which finds the path without opening the file.

## Phase 1 — blind build

Allowlist: the seed, `BRIEF.md`, `graph.schema.json`, the plugin, this prompt,
the run directory. Everything else forbidden, explicitly including `runs/`,
`cases.md`, `expected-graph.json` and `fixture/repos/`.

**One plugin instruction was declined.** `commands/build.md` step 1 directs the
builder to read `evals/conformance/Conformance.Tests.ps1`. That is outside the
allowlist. It was declined, the consequence stated at the time — the house
conventions come from the skills alone, so any convention encoded only in the
suite is missed — and the build continued. Declined, not breached. This is F-6,
for the third time.

**No declared read was needed.** Runs 004 and 005 each took a fragment-only grep
against `evals/functional/AzdoClient.ps1` for the fixture organisation and
project. This prompt supplies both coordinates directly, so the pre-authorised
read was not required and was not taken.

Built: seven public commands, twelve private helpers under `Rest/`, `Yaml/`,
`Graph/`, `Export/`, a committed dev loader, an `en-US` about topic, and 105
tests across unit, integration and PreTag layers.

Phase 1 ran **34 minutes**, ending at the push of `15ab6e3`, which is the gate.

## Scoring — three jobs, three fresh clones

Run 005's F-7 established the hazard: three scoring jobs sharing one working
tree let `build.ps1`'s `Clean` delete `output/` while the `RequiresBuild` tag was
reading it, producing a false 51/56. This pass applies the conclusion as method:
**each job clones the pushed commit itself and touches no other job's tree.**

The clones would not create inside the session scratchpad — `git clone` failed
with `cannot write keep file … Filename too long` for two of three directories
and succeeded for the third, whose name was one character shorter. Resolved with
`git -c core.longpaths=true clone`, in the scratchpad as intended.

## Results

| | first shot | final |
|---|---|---|
| build | exit 0, 92 passed, 90.13% | exit 0, 95 passed, 89.81% |
| conformance (cases-defined) | 33 / 33, 57 run | 33 / 33, 57 run |
| functional | **1 / 12**, 26 differences | **12 / 12**, 0 differences |

Two iterations of the three allowed. Nothing under `evals/` was touched.

The 26 first-shot differences were the same four mechanisms, at the same counts,
as runs 004 and 005: 15 pipeline-node `repo`, 8 edge `alias`, 2 bare `reason`,
1 missing `repo:consumer-app`. Zero structural edge errors in all three runs.

## The variance the ladder was built to measure

Every graded line is identical across the three runs. Two numbers move and
neither is a score:

- **`cases-run`** 57 / 56 / 57 — a single culture-directory skip in 005 only.
  `cases-defined` reads 33 in all three, which is what pass 0025's stable
  denominator was for.
- **iterations** 1 / 1 / **2** — the one substantive variance. 006's iteration 1
  fixed the same four mechanisms and introduced a regression the other two runs
  did not have: the graph builder branched on the *text* of `reason`, and
  rewording `reason` broke it. That is F-12. Same final answer, one extra step.

## Deviations, declared

1. **Iterations 1 and 2 landed in a single commit.** Both were measured
   separately — 26 → 1 → 0 — but iteration 2's fix was interleaved with
   iteration 1's edits in the same file, and splitting them afterwards would
   have manufactured a commit that was never the tested state. Stated in the run
   record's iteration table rather than hidden.
2. **The first-shot `compare` transcript was re-captured.** The original capture
   lost host output (Compare-Graph writes to the host, not the pipeline) and
   produced a 2-byte file. It was re-run against the preserved first-shot clone
   at the same commit; it reproduces the same 26 differences and the same failed
   cases. No score was re-run after being seen.
3. **The prompt leaked oracle-adjacent knowledge into Phase 1.** Task 7 states
   runs 004 and 005's first-shot difference mechanisms and counts, and the
   prompt is inside the Phase 1 allowlist. Flagged before any code was written
   and deliberately not acted on; three of the four conventions were then chosen
   wrongly anyway. Recorded in the run record's caveat section — the
   independence of 006's first-shot number is weakened by the prompt and is not
   established by this run alone.
4. **The acceptance assertion forced a change to the record, not to itself.**
   The whole-document "does not match either prior session id" check went red on
   a draft that quoted both predecessors' ids to prove it differed from them.
   The assertion was left exactly as specified and the record was rewritten.
   That is F-17.

## Gate falsification

The coverage gate was raised to 99% against real coverage of 90.13%, observed
red with exit 1 and a message naming both numbers, then restored to 70%. It had
been green on every prior build and, as first written, **could not fail** — F-1
and F-11.

## Task list, as executed

- [x] 1. Acceptance red — 0 passed, 11 failed.
- [x] 2. `Reset-Target.ps1 -Destination scratch/runs/006-plugin-on`; Phase 1 starts.
- [x] 3. Build from seed + brief, following the plugin; live fixture read read-only.
- [x] 4. Export the graph, commit, push `run-006-plugin-on` at `15ab6e3`; Phase 1 ends, gate lifts.
- [x] 5. Score in parallel, three jobs, three fresh clones; first scores recorded first.
- [x] 6. Two iterations, final at `7066916`.
- [x] 7. `runs/006-plugin-on/` written, with the variance section against both prior runs.
- [x] 8. Acceptance green — 11 passed, 0 failed. Plan, verify, journal, LEDGER, push, fast-forward.
