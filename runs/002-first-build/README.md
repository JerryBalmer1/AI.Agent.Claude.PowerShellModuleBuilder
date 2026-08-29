# Run 002 — first build

The first run that produced a working module. A populated plugin was seeded in
the same pass, and the builder read `fixture/cases.md`.

> **This run is not a zero-skill baseline: the plugin was seeded before it and
> the builder read the cases. Comparative scoring starts at run 003.**

What that costs: nothing here measures how an unaided agent performs. The
functional score in particular was reached by reading the twelve cases as a
specification and by reading one convention out of the oracle (see
[findings.md](findings.md), F-1). Treat 12/12 as evidence that the module works,
not as evidence about the plugin.

## Inputs

```
plugin-sha: 60821e922095f0df77c5cce972d1ab36bcfcd695
seed-sha:   cb05cda4c4c52391f371f6b2abae4dd814464948
brief-sha:  93c5cec3299da0ac27d3aea67f4fbcf0000001ec
target-sha: 79e02fba9dffd976bccf507d531f59303cc58f9d
oracle-sha: bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc
```

- **plugin-sha** — `pass-0016-first-build` HEAD at build time; the skills and
  commands the build followed.
- **target-sha** — `run-002-first-build` on
  [PSAzureDevOpsGraph](https://github.com/JerryBalmer1/PSAzureDevOpsGraph/tree/run-002-first-build).
- **oracle-sha** — unchanged by this run; `evals/` was read-only throughout.

| | |
|---|---|
| Fixture | `jlbalmerjr1` / `ClaudeTesting` — 15 definitions, 4 referenced repositories, 30 YAML files |
| Plugin | 5 skills, 2 commands |
| Wall clock | 22 minutes, `Reset-Target` to pushed module |
| Graph generation | 13.4 s for 30 files, well inside the 5-minute cap |
| Azure DevOps objects created or modified | **0** — every call a GET |

## Scores

```
build:       exit 0
conformance: 57 / 57
functional:  12 / 12
```

Three numbers, never averaged. Conformance measures **shape** — manifest,
layout, build file, tests, exported names. The build measures whether the thing
assembles and its own tests pass. Functional measures whether the answer is
**right**. A module can score 100% on conformance and return an empty graph.

### build: exit 0

| | |
|---|---|
| PSScriptAnalyzer | 0 findings (gate, not a report) |
| Pester | 37 / 37, 0 skipped |
| Coverage | **82.88%** against a declared target of 40% |

Command: `pwsh -NoProfile -File ./build.ps1` in the target root. Tasks
`Clean, Lint, Build, Test`.

### conformance: 57 / 57 (100%)

57 cases run, 57 passed, 0 failed, **0 skipped, 0 not-run**, across 33
assertions. Full result in [conformance-result.json](conformance-result.json).

```powershell
./evals/conformance/Invoke-Conformance.ps1 `
    -Path ./scratch/runs/002-first-build `
    -ModuleName PSAzureDevOpsGraph `
    -Tag @('Universal','Repository','HouseStyle','RequiresBuild') `
    -ResultPath ./runs/002-first-build/conformance-result.json
```

`-ModuleName` is required here and is not optional convenience — see
[findings.md](findings.md), F-4.

### functional: 12 / 12

**No failed cases.** The produced graph equals `expected-graph.json` exactly —
same ids, same kinds, same endpoints, same unresolved edges with the same
reasons. 49 nodes, 51 edges, 0 differences.

```powershell
./evals/functional/Compare-Graph.ps1 -CandidatePath ./runs/002-first-build/graph.json
```

Output in [diff.txt](diff.txt) (`The graphs agree. 0 differences.`, exit 0).

## Iterations

The trajectory, not just the endpoint. Two scoring iterations; the allowance was
three.

| # | What changed | build | conformance | functional |
|---|---|---|---|---|
| 1 | First complete module | exit 0 | not yet run | **1 / 12** — 60 differences; only case-12 passed |
| 2 | Five convention fixes + real cycle detection | exit 0 | **57 / 57** | **12 / 12** — 0 differences |

Iteration 1 got the **structure** right first time: 49 nodes and 51 edges,
exactly the oracle's counts, with every edge pairing by `from`/`to`/`kind`. All
60 differences were attribute conventions, not wrong answers:

- `pipeline` nodes did not carry `repo` (15 differences)
- `refKind` was emitted on every edge; the oracle carries it only on
  `unresolved` edges (29 differences)
- `repositoryResource` edges used the alias as `ref`; the oracle uses the
  `name:` value as written (8 + 8 as a missing/extra pair)
- `checkout` edges carried an `alias` field the oracle does not have
- `reason` was the bare code; the oracle carries `code: explanation`

Case-12 — the absence case — passed in **both** iterations. The repositories
endpoint was never used to emit nodes, so the pre-existing empty `ClaudeTesting`
repository never entered the graph.

Three defects were found by the build itself rather than by scoring, and are
written up in [findings.md](findings.md): a parse error the lint gate did not
catch (F-2), a cycle detector that called every diamond a cycle (F-3), and a
mandatory-parameter binding failure on an empty accumulator (F-6).

## Artifacts

| File | What it is |
|---|---|
| [graph.json](graph.json) | The graph the module produced from the live fixture |
| [diff.txt](diff.txt) | `Compare-Graph.ps1` output, verbatim, with its exit code |
| [002.html](002.html) | The graph rendered by `runs/Render-Graph.ps1` — 49 nodes, 2 pseudo-nodes, 0 external references |
| [conformance-result.json](conformance-result.json) | The conformance runner's own result |
| [findings.md](findings.md) | Everywhere a skill was wrong, silent, or guessed — sorted by mechanism |
| [DEMO.md](DEMO.md) | The exact commands a stranger pastes to reproduce the graph |

## Reproducing

See [DEMO.md](DEMO.md). Short version, from a fresh clone of the harness with
`$env:AZDO_PAT` set:

```powershell
./evals/functional/Reset-Target.ps1 -Destination scratch/runs/002-first-build
# ... build the module, or clone run-002-first-build ...
./evals/functional/Compare-Graph.ps1 -CandidatePath ./runs/002-first-build/graph.json
```

The verify script at `plans/0016-first-build/verify.ps1` re-derives all three
scores from a fresh clone rather than reading them from this file.
