# AI.Agent.Claude.PowerShellModuleBuilder

A test-first harness that makes an AI coding agent's output **measurable**, and
the Claude Code plugin distilled from what the harness measured.

Two things live here, and the order matters. The harness came first: a
conformance suite, a hand-written oracle, and a scoring runner, all built and
falsified before any agent was asked to produce anything. The plugin —
`skills/` and `commands/` — is what the harness's findings hardened into.

The claim this repository exists to test is that the second measurably improves
the first's scores. **That claim has now been measured, four times, and the
answer is partly yes and partly no.** Both halves are below.

---

## With the plugin and without it

One baseline with the plugin unread, three consecutive runs with it readable.
Same seed, same brief, same fixture, same scoring, one blind session each.

| | [003](runs/003-baseline-off/) plugin **off** | [004](runs/004-plugin-on/) **on** | [005](runs/005-plugin-on/) **on** | [006](runs/006-plugin-on/) **on** |
|---|---|---|---|---|
| build | exit 0 | exit 0 | exit 0 | exit 0 |
| **conformance (cases-defined)** | **19 / 33** | **33 / 33** | **33 / 33** | **33 / 33** |
| conformance (cases-run) | 39 / 55 | 57 / 57 | 56 / 56 | 57 / 57 |
| **functional (first-shot)** | **0 / 12** | **1 / 12** | **1 / 12** | **1 / 12** |
| first-shot differences | 29 | 26 | 26 | 26 |
| **functional (final)** | *never permitted* | **12 / 12** | **12 / 12** | **12 / 12** |
| iterations allowed / used | 0 / — | ≤3 / 1 | ≤3 / 1 | ≤3 / **2** |
| Phase 1 wall clock | 32.6 min | 33 min | 23 min | 34 min |

Evidence: each run's `README.md`, `conformance-result.json`, `compare-report.json`
and `diff.txt` in the directories linked above. `cases-defined` is the stable
denominator introduced in pass 0025; run 003's result file predates it, so its
19 / 33 was **re-derived** for this table by re-scoring
[its pushed branch](https://github.com/JerryBalmer1/PSAzureDevOpsGraph/tree/run-003-baseline-off)
with today's suite — the same instrument against a different target.

**Read the "final" row honestly.** Run 003 was run under a protocol that said
*"No fixes, no re-runs — the first scores stand"*
([plan](plans/0020-baseline-off/plan.md)). It has no final score because it was
never allowed one, not because it failed to reach one. Nobody knows what run 003
would have scored with three iterations, and this table cannot say.

**The fair comparison is the first-shot row, and it is nearly flat: 0 / 12
against 1 / 12.** The plugin moved the functional score by one case out of
twelve, and that one case is the absence case. Anyone reading `0 → 12` off this
table has read it wrong.

### Where the plugin actually moved the number

The functional score is dominated by one omitted property, so it hides the
result. The difference *breakdown* does not. Every plugin-on run produced
**exactly the same 26 differences by the same four mechanisms**, so one column
covers all three:

| Mechanism | 003 off | 004 / 005 / 006 on | |
|---|---:|---:|---|
| `repo` omitted from `pipeline` nodes | 15 | 15 | unchanged |
| `alias` written where the oracle omits it | 8 | 8 | unchanged |
| `reason` written as a bare token | 2 | 2 | unchanged |
| `extraNode` — the empty repository emitted as a node | **1** | **0** | fixed |
| `extraEdge` — `checkout: self` turned into an edge | **1** | **0** | fixed |
| `wrongEdgeTarget` — unresolved targets given colliding ids | **2** | **0** | fixed |
| `missingNode` — `repo:consumer-app` | 0 | **1** | **introduced** |
| **total** | **29** | **26** | |

Read across, that is the whole result:

- **The plugin fixed four behavioural errors and nothing else.** `checkout: self`
  produces nothing; a repository nothing references is not a node (that is
  case 12, which run 003 failed and all three plugin runs passed); an unresolved
  edge's target must not collide with a real node. Those are four rules the
  skills state and the brief does not.
- **The plugin changed nothing about the three conventions**, 25 of the 29
  differences. It does not state them either. Three blind sessions guessed, and
  all three guessed the same three things wrong in the same direction.
- **The plugin introduced one error of its own.** `azdo-graph-assembly` states
  the repository-node rule too narrowly, and every run that follows it exactly
  is missing one node. That is F-2, below.
- **The unambiguous win is shape, not behaviour: 19 / 33 → 33 / 33**, three
  times, first shot, from a fresh clone. Fourteen house-style assertions about
  the build file, the generated psm1, one-function-per-file and root files.

---

## The variance across the three plugin runs

Runs 004 and 005 were **difference-for-difference identical**: the same 26
differences, the same four mechanisms at the same counts, the same 1 / 12 and
12 / 12, the same single iteration, zero structural edge errors each. Run 006
reproduced all of it. Every graded line matches across the three.

Two numbers move, and neither is a score:

- **`cases-run` 57 / 56 / 57.** Run 005 shipped no culture directory, so one
  assertion graded nothing and was reported skipped rather than passed. At
  `cases-run` the three runs are incomparable; at `cases-defined` they read 33,
  33 and 33. This is exactly what the stable denominator was for.
- **iterations 1 / 1 / 2.** Run 006's single iteration fixed the same four
  mechanisms and broke something else: the graph builder had branched on the
  *text* of the `reason` field, and improving that text produced the node id
  `yaml:/`. Same final answer, one extra step, and the fix was to split the
  machine-readable code from the human-readable message. See
  [F-12](runs/006-plugin-on/findings.md).

**F-5 is the one the instrument cannot see.** `powershell-module-build` says
`Requirements.psd1` is the only place dependencies are pinned, and two paragraphs
later says a runtime dependency belongs in the manifest. `powershell-yaml` is
honestly both. Run 004 read the first sentence and declared it in the manifest
alone; runs 005 and 006 read the second and declared it in both files. **All
three scored 33 / 33.** It is a real source-level disagreement between the three
builds that no assertion in the harness can detect, and it was predicted by run
004 before runs 005 and 006 existed.

---

## What a run costs

| | |
|---|---|
| Phase 1, blind build | **23–34 minutes** (33, 23, 34 across runs 004–006) |
| Scoring, three jobs in parallel from three fresh clones | **~60 seconds**, twice — first shot and final |
| The live graph command against a 15-definition fixture | **9.8 s / 15.3 s / 10.7 s**, against a 5-minute cap |
| Iterations | 1–2, of 3 allowed |

Provenance sections in each run README. The scoring figures are not comparable
between runs 004/005 and 006 — 006 is slowest because it is the only one where
every job both cloned fresh *and* built from nothing, which is what run 005's
race concluded the method should be.

---

## The recurring findings

Ten findings were recorded across runs 004 and 005. **Eight of the ten recurred
in run 006**, in a session that had not read either record. The two that did not
are the two that were never about the instrument. Full text:
[004](runs/004-plugin-on/findings.md),
[005](runs/005-plugin-on/findings.md),
[006](runs/006-plugin-on/findings.md).

| | What it is | 004 | 005 | 006 |
|---|---|---|---|---|
| **F-1** | the build skill's coverage-gate template **cannot fail** as shipped | ✔ | ✔ | ✔ |
| **F-2** | the repository-node rule, followed exactly, is short by one node | ✔ | ✔ | ✔ |
| **F-3** | the optional-field principle is contradicted by the schema it cites | ✔ | ✔ | ✔ |
| **F-4** | the `reason` format is stated nowhere | ✔ | ✔ | ✔ |
| **F-5** | the runtime-dependency fork — two readings, both defensible | ✔ | ✔ | ✔ |
| **F-6** | `/build` step 1 instructs a read the measurement forbids | ✔ | ✔ | ✔ |
| **F-7** | the `.GetNewClosure()` hazard | ✔ | ✔ | — |
| **F-8** | the Pester 6 assertion list cannot be written from memory | ✔ | ✔ | ✔ |
| **F-9** | the culture-directory skip | — | ✔ | — |
| **F-10** | a back-edge report that cannot tell a cycle from a diamond | — | ✔ | ✔ |

**F-1 is the most serious and it is in the plugin's own template.** Copied
faithfully, the `Test` task prints `Line coverage: 0% (target %)`, exits 0 and
grades nothing, because `Invoke-Pester` returns nothing without
`Run.PassThru` — so the gate compares `0 -lt $null` and never fires, and the
`PreTag` guard compares `($null + $null) -eq 0` and always fires. One missing
line, two dead gates, no symptom. Every run falsified its own gate afterwards and
watched it go red.

F-2, F-3, F-4 and F-5 are the four places the instrument is silent and the
producer must guess. Three independent sessions guessed identically. **That is
the strongest single result in this repository**: at fixed inputs the model is
repeatable to the difference, so a difference between runs is information about
the instrument, not noise.

---

## Running it

Needs PowerShell 7.2+, Pester 6.x, PSScriptAnalyzer, InvokeBuild. Three commands
reproduce a run end to end.

```powershell
# 1. Wipe the target back to the four-file seed. This is the start of a run.
./evals/functional/Reset-Target.ps1 -Destination scratch/runs/007-my-run

# 2. Shape. Read the score from result.json, never from the exit code — a red
#    conformance run is data, and the runner exits 0 on purpose.
#    Use -Command, never `pwsh -File`: -File flattens the comma-separated -Tag
#    into a single token and the filter then selects the wrong set, silently.
./evals/conformance/Invoke-Conformance.ps1 `
    -Path scratch/runs/007-my-run -ModuleName PSAzureDevOpsGraph `
    -Tag @('Universal','Repository','HouseStyle','RequiresBuild') `
    -ResultPath scratch/runs/007-my-run/conformance-result.json

# 3. Behaviour. Scores a produced graph against the hand-written oracle.
./evals/functional/Compare-Graph.ps1 `
    -CandidatePath scratch/runs/007-my-run/artifacts/graph.json `
    -ReportPath scratch/runs/007-my-run/compare-report.json
```

The fixture and the oracle also check each other, in both directions:

```powershell
Invoke-Pester ./evals/functional/Fixture.Tests.ps1     # 352 cases
Invoke-Pester ./evals/functional/ReadBack.Tests.ps1    #  76 cases, needs AZDO_PAT
Invoke-Pester ./evals/functional/Compare.Tests.ps1     #  28 cases
```

`-ModuleName` is optional. When the repository root is a run directory the runner
derives it from `src/<Name>/<Name>.psd1`; two manifests under `src/` is
undecidable and stops, naming both, rather than grading the wrong module silently.

---

## Guardrails

**Credentials.** `$env:AZDO_PAT`, and nothing else, everywhere. Never a
parameter, never a file, never in a URL — a value passed as a parameter reaches
`PSReadLine` history, `Start-Transcript` output and the ScriptBlock logging event
log, and the token is a bearer credential for a whole organisation. Every run
scans its own artifacts, its clones and its tracked blobs for the PAT **by value**
before committing; all four runs report zero occurrences.

**Read-only, permanently.** The target module never queues, runs or triggers a
pipeline and never creates, updates or deletes anything. It is `GET` only, no
command is named with a writing verb, and both claims are asserted structurally
over the AST in a `PreTag` test rather than in prose.

**The blind gate.** A measured run is the first message of a fresh session, and a
session that has read anything under `runs/` is disqualified as a blind builder —
run records are oracle knowledge in prose. Nothing may write scores, fixture
findings or oracle content into session memory or any auto-loading file; a
context window is cleared, a memory file is not. Hazards 9–11 in
[evals/HARNESS.md](evals/HARNESS.md).

**Never edit the oracle to fit.** Run 006 found that `cases.md` justifies four
repository nodes with a rule that produces three. Nothing under `evals/` was
touched; it is recorded as a finding for a decision to repair.

**`main` moves only by fast-forward** after a green pass, ancestry checked, never
forced — [0009](decisions/0009-agent-moves-both-mains.md) for the target,
[0010](decisions/0010-ecosystem-repo-governance.md) for the rest.

---

## Why not just prompt Claude to write a module?

You can, and it will produce something that looks right. The four runs above are
what happens when you then try to find out whether it *is* right.

- **Without the plugin, the module scored 19 / 33 on shape and emitted a node for
  a repository nothing references** — the empty repository sitting in the same
  project, which the naive implementation picks up from the repositories
  endpoint. Nothing about the output announces that. It reads as a complete
  graph, and it answers a different question from the one asked.
- **The conventions the brief does not state get guessed**, and three
  independent sessions guessed the same three things wrong. A prompt does not
  fix that; a scored oracle finds it in one run.
- **The gates you write to catch this are themselves usually broken.** F-1 is a
  coverage gate, copied from a skill, that could not fail. It was green on every
  build until somebody raised the threshold on purpose and watched it go red.
  An assertion that has only ever passed is indistinguishable from one that
  cannot fail.

The plugin is not the interesting artifact here — the measurement is. What this
repository provides is a way to state, with an artifact behind every number, what
an agent's output actually does: **33 / 33 on shape, 12 / 12 on behaviour, in one
or two iterations, at 23–34 minutes a run, reproducibly, three times.** And
equally, where it does not help: four conventions, unchanged, run after run.

---

## The skills

Named by scope, per [decision 0007](decisions/0007-skill-taxonomy-and-naming.md):
`powershell-module-<role>` for anything generic to building a PowerShell module,
`azdo-<role>` for what is specific to the Azure DevOps target. Dots are not legal
in skill names, which rules out the `powershell.module.x` form.

`producer-contract` fits neither prefix, and that is a gap in the taxonomy rather
than a naming slip: it is about emitting against a contract another repository
owns. Recorded for the operator to settle if a second cross-cutting skill appears.

| Skill | Role |
|---|---|
| `powershell-module-plan` | Intake and planning; a definition-of-done that names how the work will be tested before the work starts. |
| `powershell-module-architect` | Command-surface design — verb-noun, one command one question, when to split, `Public/` versus `Private/`. |
| `powershell-module-scaffold` | The layout the conformance suite grades: manifest, `Public/` flat, `Private/` nested, explicit exports, the committed dev loader. |
| `powershell-module-build` | `build.ps1` and `<Name>.build.ps1` — InvokeBuild tasks, `ParseError` in the analyzer severity list, the coverage gate, exit-code discipline. **Carries F-1.** |
| `powershell-module-test` | The Pester suite and the ordered five-layer runner that stops at the first failing layer. |
| `powershell-module-analyzer` | AST-driven analysis that never runs the code it reads. |
| `powershell-module-docs` | Comment-based help, `about_` topics and the culture directory the build must copy. |
| `powershell-module-deploy` | Staging and output layout; why `Publish-Module` is the operator's alone. |
| `powershell-module-release` | Semver against a module surface, changelog and worklog conventions. |
| `azdo-rest` | The Azure DevOps REST API, read-only. `$env:AZDO_PAT` and nothing else, ever. |
| `azdo-pipeline-yaml-refs` | Extracting and resolving pipeline YAML references, parsing separated from resolution. |
| `azdo-graph-assembly` | Turning references into a graph — identity by what a node is, never where a traversal reached it. **Carries F-2.** |
| `producer-contract` | Emitting against a schema another repository owns: absent versus false, the consumer's battery, never renaming what the contract names. |
| `task-tree-reporting` | Response formatting during multi-skill work. |

---

## The ecosystem

Six repositories, governed from here.

| Repository | What it is | State |
| --- | --- | --- |
| this one | the harness, the oracle, and the plugin distilled from what they measured | ladder complete at runs 004–006 |
| [PSAzureDevOpsGraph](https://github.com/JerryBalmer1/PSAzureDevOpsGraph) | the build target: a read-only AzDO pipeline dependency grapher | built and scored, runs 002–006 |
| [PSGraphRender](https://github.com/JerryBalmer1/PSGraphRender) | the renderer. Takes a view model, writes one self-contained HTML page, knows nothing about what the nodes are | v0.13.0, handed over |
| [PSGraphRenderToHtml](https://github.com/JerryBalmer1/PSGraphRenderToHtml) | the contract between a producer and the renderer, and the battery a producer runs against its own output | v0.1.0 |
| [PSModuleGraph](https://github.com/JerryBalmer1/PSModuleGraph) | the first producer, and the repository the renderer was extracted from | the renderer's first consumer |
| [PSTerraformGraph](https://github.com/JerryBalmer1/PSTerraformGraph) | the second producer, and the first that is not PowerShell | v0.2.0 |

### The cross-language measurement — tf-001 and tf-002

The renderer's boundary is the claim the ecosystem exists to test: **a producer in
any language can drive it without changing it.**

[**tf-001**](runs/tf-001-first-build/) is where that stopped being an assertion.
PSTerraformGraph drives PSGraphRender through PSGraphRenderToHtml, over Terraform
HCL — a domain nobody had in mind when the renderer was extracted — and **not one
line of either changed to allow it.**

[**tf-002**](runs/tf-002-convention-and-case3/) re-scored it at **0 differences
and 7 / 7**, after the fixture's case 3 was repaired under
[decision 0012](decisions/0012-fixture-case3-repair.md) and two producer defects
were closed. The oracle was visible for both, so this is a statement about one
fixture and **not** a generalisation claim; tf-003 is the blind measurement and is
not yet scheduled. Two of tf-002's own findings — that the `tf-<role>` skills were
deliberately *not* written, because writing them first would measure the plugin's
memory of tf-001 rather than its generality — are in
[the LEDGER backlog](LEDGER.md).

---

## Layout

| Path | What |
|---|---|
| `skills/` | The plugin's fourteen skills |
| `commands/` | `/build` and `/test` |
| `evals/conformance/` | The shape oracle: `Conformance.Tests.ps1`, its runner, the falsification record |
| `evals/functional/` | The behaviour oracle: `BRIEF.md`, `fixture/`, the comparator, the seed |
| `evals/HARNESS.md` | What a run consists of, and the eleven hazards |
| `runs/` | One directory per scored run, with its artifacts and transcripts |
| `plans/` | One per pass: evidence per task, deviations, a verify script that re-derives the scores |
| `journal/` | Append-only, six fields per pass |
| `decisions/` | Append-only decision records |
| `method/` | The method, including its known limits |

---

## Status, honestly

- **The ladder is complete**: three consecutive blind plugin-on runs at a fixed
  seed, brief, plugin SHA and model version, each scored from fresh clones. Every
  graded line matches.
- **The plugin's effect is measured and it is uneven.** Large and repeatable on
  shape (19 / 33 → 33 / 33). Nearly nil on the functional first-shot score
  (0 / 12 → 1 / 12). Real but narrow on behaviour: four rules fixed, one error
  introduced.
- **The baseline is one run and it was not allowed to iterate.** A second
  plugin-off run, permitted the same three iterations, is the missing control.
  Nothing here says what run 003 would have reached.
- **The builder is the same model family that wrote the skills.** None of the
  four runs can separate reading the plugin from recalling the reasoning that
  produced it. What they measure is reliability at fixed inputs.
- **Run 006's prompt leaked** the prior runs' difference mechanisms into its own
  blind phase. Flagged and deliberately not acted on — three of four conventions
  were still chosen wrongly — but the independence of that run's first-shot
  number is weakened and is stated as weakened in its record.
- The conformance suite is **falsified against one reference module**; eleven of
  twelve controls stay green and the twelfth is documented as failing.
- `Universal` has run against nine targets; **seven of nine assertions survive
  all nine**. The corpus control does not pass clean.
- The functional oracle covers **one** 15-pipeline fixture, and it contains a
  known contradiction (F-2) that no implementation following the stated rule can
  satisfy.
- Per-skill ablation — which of the fourteen skills carries the 19 → 33 — is
  **unmeasured**, and is the next question worth a run.

## Licence

MIT.
