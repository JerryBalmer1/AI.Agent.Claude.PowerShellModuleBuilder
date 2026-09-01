# Run 004 — plugin on

The first of three consecutive complete plugin-on runs from wiped state. The
same seed, brief, plugin SHA and model version as runs 005 and 006 will use;
variance between the three is the finding, not noise.

    plugin-sha:          f25d05d8eb219c9b0009a85d39918214f6b3b681
    model-version:       claude-opus-5[1m]
    cc-identity:         CLAUDE_CODE_ENTRYPOINT=claude-vscode (recorded, not compared)
    session-identifier:  b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db
    target-sha:          19837f9efa0d5196194aa737a069cb38493dc3ec
    first-shot-sha:      9924bf7f3662d755bea21b661c52e54379a6b0d5
    seed-sha:            cb05cda4c4c52391f371f6b2abae4dd814464948
    brief-sha:           93c5cec3299da0ac27d3aea67f4fbcf0000001ec
    harness-sha:         dfac91acbbc1755594ea9e99e4b63244f4e6687c
    phase-1-minutes:     33
    build:               exit 0
    conformance:         33 / 33 (cases-defined)
    cases-run:           57
    functional (first-shot): 1 / 12
    functional (final):      12 / 12

`model-version` is the ladder's pin: runs 005 and 006 hard-stop if theirs
differs. `session-identifier` must differ in each of the three, which is what
proves they were three sessions.

Target branch: `run-004-plugin-on` in `PSAzureDevOpsGraph`. No tag, no target
`main` — this is a measurement line, per decision 0008's amendment.

## Scores

**Build — exit 0.** PSScriptAnalyzer 0 findings; Pester 111 passed, 0 failed,
7 not run (the `PreTag` tag, excluded from the default task); line coverage
94.61% against a declared target of 70%, measured against the built psm1.
`-Task PreTag` selects 7 and passes 7.

**Conformance — 33 / 33 (cases-defined), 57 / 57 cases-run, 100%**, all four
tags (Universal 9, Repository 4, HouseStyle 14, RequiresBuild 6). No failures at
any iteration, including first shot. Scored against a fresh clone of the pushed
branch, built from nothing, so the number is not an artifact of the working tree.

**Functional — 1 / 12 first shot, 12 / 12 final.** 0 differences at the end.

## Iterations

| # | SHA | What changed | build | conformance | functional |
|---|---|---|---|---|---|
| first shot | `9924bf7` | — | exit 0, 110 passed, 94.91% | 33/33 (57 run) | **1 / 12** |
| 1 | `19837f9` | four output conventions, one of them a real defect | exit 0, 111 passed, 94.61% | 33/33 (57 run) | **12 / 12** |

One iteration of the three allowed. Nothing under `evals/` was touched at any
point, and no assertion was weakened.

## The 26 first-shot differences were four decisions

Grouped by mechanism before the count was read, per `producer-contract`:

| Count | Mechanism | Kind |
|---:|---|---|
| 15 | `repo` omitted from `pipeline` nodes | convention |
| 8 | `alias` written on `template`/`extends`/`checkout` edges | convention |
| 2 | `reason` written as a bare code, not `code: explanation` | convention |
| **1** | **`repo:consumer-app` missing** | **defect** |

25 of 26 were three one-line conventions. The twenty-sixth was the only thing
actually wrong with the traversal, and it is the smallest number on the page —
which is the pattern `producer-contract` predicts and the reason for grouping
before reacting.

**The dependency computation was right first time.** At first shot there were
**0** `missingEdge`, **0** `extraEdge`, **0** `wrongEdgeTarget` and **0**
`wrongEdgeKind`: every node and every edge the oracle has was present and
pointing at the right thing, recorded under a field convention that could not
match. Both resolution rules anchored correctly, the cycle terminated with both
edges recorded, the diamond collapsed to one node with in-degree 2, and both
unresolved references resolved to the oracle's exact repository and path with
the reasons the right way round.

Because `case-01` … `case-11` tags live on `pipeline` nodes and on those edges,
the single omitted `repo` property failed eleven cases on its own. `case-12` —
the empty `ClaudeTesting` repository, which must not appear — passed at first
shot and is the only case that did.

See [findings.md](findings.md) for the eight mechanisms, including the one that
matters most: the build skill's `Test` task template ships a coverage gate that
cannot fail.

## Plugin-on caveat

The plugin was read in full during Phase 1 and the conformance suite was not —
`commands/build.md` step 1 instructs reading the suite, and this run's allowlist
forbids it (F-6). The conformance score therefore measures whether the skills are
a faithful proxy for the assertions, with the assertions unread. They are:
33/33, first shot.

The builder remains the same model family that wrote the skills, so this run
cannot separate reading the plugin from recalling the reasoning that produced it.
Runs 005 and 006 do not fix that either; what the three of them measure is
reliability at fixed inputs.

## Contents

| File | What |
|---|---|
| `graph.json` | The module's answer for the fixture. 49 nodes, 51 edges, 2 unresolved. Validates against `fixture/graph.schema.json`. |
| `diff.txt` | Compare-Graph output, verbatim. 0 differences. |
| `004.html` | `runs/Render-Graph.ps1` rendering. 49 `data-node-id`, 2 `data-unresolved-id`, 0 http(s) references. |
| `findings.md` | Eight findings by mechanism, observed vs inferred. |
| `compare-report.json` | Structured difference report. |
| `conformance-result.json` | Conformance result, all four tags. |
| `transcripts/` | The three scoring jobs, first-shot and final, as run. |

## Provenance

- Phase 1 (blind build): 2026-09-01T13:39:52-07:00 → 2026-09-01T14:13:16-07:00,
  **33 minutes**, ending at the push of `9924bf7`.
- Scoring ran as three parallel jobs with three transcripts: **23.9 s** wall
  clock first-shot, **23.3 s** final. The conformance job built its own fresh
  clone so it could not race the build job's `Clean`.
- No graph command approached the 5-minute cap: the live run took **9.8 s** for
  15 definitions and 38 file fetches. Nothing was killed.
- Allowlist breaches: **zero**. `commands/build.md` step 1 was declined rather
  than followed, and that decision is F-6 rather than a breach.
- Azure DevOps was read-only throughout. Every request is `GET`; `-Method` is
  never a parameter and a `PreTag` test asserts that structurally over the AST.
  The empty `ClaudeTesting` repository was enumerated by the repositories
  endpoint and never fetched from.
- The PAT was read from `$env:AZDO_PAT` only. Scanned for in this record and in
  the module clone: **zero occurrences**.
- The coverage gate was falsified before being trusted: raised to 99% against
  real coverage of 94.91%, observed red with exit 1, restored to 70%.
- No score was re-run after being seen, and the first-shot lines above were
  recorded before any fix was made.
- Tools: pwsh 7.6.5, git 2.41.0.windows.1, Pester 6.1.0, InvokeBuild 5.14.23,
  PSScriptAnalyzer 1.25.0, powershell-yaml 0.4.12, Windows 10.0.26200.
