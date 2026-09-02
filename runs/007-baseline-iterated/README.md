# Run 007 — baseline off, iterated

The missing control. Run 003 was plugin-off but was never allowed a fix loop;
runs 004–006 were plugin-on with a budget of three iterations. This run is
plugin-off **with the ladder's iteration budget**, so that a first-shot line and
a converged line now exist on both sides of the comparison.

    plugin-surface:      v1.0.0 (present but UNREAD this run)
    harness-sha:         ec07aef8a468371bab6a3b3313f60e65ea863c22
    model-version:       claude-opus-5[1m]
    cc-identity:         Claude Code, VSCode native extension (recorded, not compared)
    session-identifier:  c0002fae-addf-4ff6-847e-9faf5d6aa05e
    target-sha:          95ca28d76c8eeb6dc33b09f77109dc96038c76aa
    first-shot-sha:      1f2df30ab3e6a33853e35f5b00a29e5e1dc070dc
    seed-sha:            cb05cda4c4c52391f371f6b2abae4dd814464948
    brief-sha:           93c5cec3299da0ac27d3aea67f4fbcf0000001ec
    oracle-blob:         bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc (ls-tree only, never opened)
    phase-1-minutes:     181
    build:               exit 0
    conformance:         28 / 33 (cases-defined)
    cases-run:           55
    functional (first-shot): 6 / 12
    functional (final):      12 / 12

`model-version` equals the ladder's pin, which is what makes the comparison
admissible. `session-identifier` was verified distinct from the three recorded in
`runs/004-plugin-on`, `runs/005-plugin-on` and `runs/006-plugin-on`; those three
are deliberately **not** quoted here, because the acceptance test asserts this
document does not contain them.

`plugin-surface` is pinned rather than absent: `skills/`, `commands/`,
`.claude-plugin/` and `evals/` are byte-identical to tag `v1.0.0`
(`git diff v1.0.0..main` over those paths is empty). The plugin was present on
disk and never read, before or after the gate.

Target branch: `run-007-baseline-iterated` in `PSAzureDevOpsGraph`. Orphan root,
no tag, no target `main` — this is a measurement line, per decision 0008's
amendment.

## Scores

**Build — exit 0.** PSScriptAnalyzer 0 findings; Pester 58 passed, 0 failed;
line coverage 86.48% against a declared target of 70%, measured against the
generated psm1. Scored from its own fresh clone of the pushed commit.

**Conformance — 28 / 33 (cases-defined), 50 / 55 cases-run, 90.91%**, all four
tags (Universal 9, Repository 4, HouseStyle 14, RequiresBuild 6). Scored from its
own fresh clone. Four of the five remaining failures are `RequiresBuild`
assertions that read `output/`, which is `.gitignore`d and so absent from a clone
that has not been built; re-scored in one clone with the build run first, the
same commit gives **32 / 33**. That supplementary number is *not* the reported
score — see [findings.md](findings.md) C-5, which also explains why the ladder's
33/33 may not be directly comparable.

**Functional — 6 / 12 first shot, 12 / 12 final.** 0 differences at the end.

## Iterations

| # | SHA | What changed | build | conformance | functional |
|---|---|---|---|---|---|
| first shot | `1f2df30` | — | exit 0, 24 passed | 19/33 (55 run) | **6 / 12** |
| 1 | `bbce522` | alias on declarations only; participating repos; no self-checkout edge; unresolved targets and reasons | exit 0, 24 passed | 19/33 (55 run) | **12 / 12** |
| 2 | `37c877b` | Invoke-Build task file, generated psm1, pinned requirements, analyzer settings, mocked end-to-end tests | exit 0, 58 passed, 86.48% | 27/33 (55 run) | **12 / 12** |
| 3 | `95ca28d` | Pester throws on failure; coverage gated against the configured target | exit 0, 58 passed, 86.48% | 28/33 (55 run) | **12 / 12** |

Three iterations of the three allowed. **The functional score reached 12/12 at
iteration 1**; iterations 2 and 3 spent the remaining budget on conformance,
which the protocol's trigger ("iterate if under 12/12") does not cover but does
not forbid. Nothing under `evals/` was touched at any point, and no assertion was
weakened.

## The 14 first-shot differences were five decisions

Grouped by mechanism before the count was read, per `producer-contract`:

| Count | Mechanism | Kind |
|---:|---|---|
| 8 | `alias` written on edges that *use* an alias | convention |
| 2 | `reason` written as a bare token, not `token: explanation` | convention |
| 2 | unresolved edge target written `unresolved:<ref>` | convention |
| 1 | `checkout: self` emitted as an edge | judgement |
| 1 | the empty repository emitted as a node | judgement |

**The dependency computation was right first time.** 0 `missingNode`, 0
`missingEdge`, 0 `wrongEdgeKind` — every node and edge the oracle has was
present and pointing at the right file, recorded under field conventions that
could not match. Both anchoring rules resolved correctly, the cycle terminated,
the diamond collapsed to one node with in-degree 2, `extends` was not confused
with `template`, the decoy parameter that looks like a template path was not
followed, and both unresolved references landed on the oracle's exact repository
and path.

Two defects were found by this run's own tests rather than by scoring: an empty
repository silently dropped by a StrictMode property read, and an absolute path
concatenated onto the working directory in `Export`. Both are in
[findings.md](findings.md) Part 4.

## Control comparison

### 007 vs 003 — first shot, both blind, both plugin-off

| | 003 | 007 |
|---|---|---|
| iterations allowed | 0 | 3 |
| functional, first shot | **0 / 12** | **6 / 12** |
| differences | 29 | 14 |
| conformance, first shot (cases-defined) | 19 / 33 (re-derived) | 19 / 33 |
| phase-1 minutes | 32.6 | 181 |

The two blind runs scored **identically on conformance at first shot — 19/33** —
and the functional difference is one property. Run 003's 29 differences were
`wrongNodeAttribute` 15, `wrongEdgeAttribute` 10, `wrongEdgeTarget` 2,
`extraNode` 1, `extraEdge` 1. Run 007's 14 were `wrongEdgeAttribute` 10,
`wrongEdgeTarget` 2, `extraNode` 1, `extraEdge` 1. **Subtract 003's fifteen
`repo`-on-`pipeline` differences and the two runs are identical, mechanism for
mechanism and count for count.**

Because the case tags live on `pipeline` nodes, that single omitted property
failed all twelve of 003's cases. 007 emitted it — from one line of the brief,
*"each with the repository and path its YAML lives at"* — and so failed only the
six cases the remaining fourteen differences touch. Two blind sessions, the same
five mistakes, one property apart. That is one observation and not a trend, and
it is as consistent with session variance as with anything about how the brief
was read.

### 007-final vs the ladder finals — the apples-to-apples the project lacked

| | 004 | 005 | 006 | **007** |
|---|---|---|---|---|
| plugin | on | on | on | **off** |
| functional, first shot | 1 / 12 | 1 / 12 | 1 / 12 | **6 / 12** |
| first-shot differences | 26 | 26 | 26 | **14** |
| functional, final | 12 / 12 | 12 / 12 | 12 / 12 | **12 / 12** |
| iterations to 12/12 | 1 | 1 | 2 | **1** |
| conformance, first shot | 33 / 33 | 33 / 33 | 33 / 33 | **19 / 33** |
| conformance, final | 33 / 33 | 33 / 33 | 33 / 33 | **28 / 33** (32/33 built-clone) |
| phase-1 minutes | 33 | 23 | 34 | **181** |

**Functional: the plugin made no difference to the converged result, and the
blind run's first shot was closer.** All four runs reach 12/12. 007 reached it in
one iteration — matching 004 and 005, and one fewer than 006. Its first shot was
14 differences against the ladder's uniform 26, because all three plugin-on runs
omitted `repo` from `pipeline` nodes and 007 did not.

**Conformance: the plugin made all of the difference.** The three plugin-on runs
scored 33/33 at first shot and never lost it. The blind run started at 19/33 and
reached 28/33 (32/33 measured in a built clone) after spending two of its three
iterations on nothing else. House style — the build file's name and task set, the
generated single `.psm1`, `Requirements.psd1`, the analyzer settings file, a test
per exported command — is not derivable from the brief, is not visible in the
fixture, and was only ever going to come from reading the house's own documents.
That is what the plugin supplies, and this control measures it at roughly
fourteen assertions.

**Iterations used: 3, against the ladder's 1 / 1 / 2.** The comparison is not
clean. 007's iteration 1 alone bought 12/12 functional; iterations 2 and 3 were
spent on conformance, which the plugin-on runs never needed to spend anything on.
Counting to convergence on the functional score, all four runs used 1–2.

### Which of the four named mechanisms appeared in 007's first shot

| Mechanism | Ladder first shot | 007 first shot | Fixed in ≤3? |
|---|---|---|---|
| 15 × `repo` on `pipeline` nodes | present | **absent** | n/a — never occurred |
| 8 × `alias` on edges | present (8) | **present (8)** | yes, iteration 1 |
| 2 × bare `reason` | present (2) | **present (2)** | yes, iteration 1 |
| 1 × consumer-app | present — `repo:consumer-app` **missing** | present — an **extra** `checkout` edge to `repo:consumer-app` | yes, iteration 1 |

Three of the four recurred blind, two of them at exactly the ladder's counts. The
consumer-app difference recurred at the same site with the opposite polarity: the
ladder's runs omitted the node, 007 had the node and added a `checkout: self`
edge the oracle does not have. 007 also produced two mechanisms the ladder's
grouping does not name but run 003 did have — the unresolved-target convention
(2) and the empty-repository node (1).

**All five were fixed inside one iteration.** But "WITHOUT the conventions being
readable anywhere" is not what happened, and the sentence has to say so:
`Compare-Graph` prints the oracle's expected value for every
`wrongEdgeAttribute` and `wrongEdgeTarget`, so the exact 30-word `reason` string
was read out of the diff and reproduced rather than re-derived. The plugin was
unread; the conventions were still legible, one difference at a time, from the
scorer. See [findings.md](findings.md) Part 3, which also records that this
pass's own prompt named three of the four mechanisms and their counts to a
builder who had not yet written a line — a defect in the pass design that this
run cannot correct for.

### The sentence the README will need

Drafted here, to be applied in a later pass — **not** this one; the release
surface is tagged.

> Across three plugin-on runs and one plugin-off control, all four modules
> reached the functional oracle exactly — 12/12, zero differences — within two
> fix iterations, and the control's first shot was the closest of the four. What
> the plugin reliably supplies is conformance to house style, which is not
> derivable from the brief: plugin-on runs scored 33/33 at first shot and held
> it, while the control started at 19/33 and reached 28/33 only by spending two
> of its three iterations on house conventions alone. On the evidence so far the
> plugin buys shape, not correctness — and a single control cannot tell us
> whether that is because the conventions are the hard part or because the
> dependency computation was never the hard part for this model.

The current with/without section claims more for the plugin than these four runs
support, and rewriting it against 007 is queued for the next release pass.

## Contents

| File | What |
|---|---|
| `graph.json` | The module's final answer. 49 nodes, 51 edges, 2 unresolved. Validates against `fixture/graph.schema.json`. |
| `graph-first-shot.json` | The same, at `1f2df30`. 50 nodes, 52 edges. |
| `diff.txt` | `Compare-Graph` on `graph.json`, verbatim. 0 differences. |
| `diff-first-shot.txt` | `Compare-Graph` on the first shot, verbatim. 14 differences. |
| `007.html` | `Render-Graph` rendering. 49 `data-node-id`, 2 pseudo-nodes, no `http` at all. |
| `findings.md` | Findings by mechanism, and the channels the corrections came through. |
| `compare-report.json` / `compare-report-first-shot.json` | Structured difference reports. |
| `conformance-result.json` / `conformance-result-first-shot.json` | Conformance results, three-clone protocol. |
| `conformance-result-built-clone.json` | Supplementary: the same commit scored in one clone with the build run first. 32/33. Not the reported score. |

## Provenance

- Phase 1 (blind build): 2026-09-01T19:51:40−07:00 → 2026-09-01T22:52:25−07:00,
  181 minutes, ending at the push of `1f2df30`.
- Scoring: three jobs in parallel, each from its own fresh clone of the pushed
  commit, per run 005's race rule. Wall-clock 9s, 8s, 25s and 27s for the four
  scoring rounds.
- Live fixture read read-only throughout: `git/repositories`,
  `build/definitions` and `git/repositories/{id}/items` only. Nothing was
  queued, created, modified or deleted. The empty `ClaudeTesting` repository was
  read and not written.
- PAT hygiene: `$env:AZDO_PAT` only; scanned before every commit, zero
  occurrences in the tree.
- Allowlist breaches: **0**. The plugin was never read. Deviations from the
  prompt, none of them breaches, are itemised in `plans/0032-run-007/plan.md`.
