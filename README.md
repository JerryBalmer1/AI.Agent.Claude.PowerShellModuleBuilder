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

<!-- TEMPLATE:replace — keep the shape of this section: prerequisites first,
     then the three commands, then how to remove it again. Swap the owner/repo
     slug, the marketplace name, the plugin name and the tag for your own. A
     new project's install section is the same shape with different nouns. -->

## Install

**Check your prerequisites first.** One command, and it names anything missing
with the exact line that fixes it. Run it in your own shell, not inside Claude
Code:

    pwsh -NoProfile -File ./tools/publish/Test-Prerequisites.ps1

It checks five things: PowerShell 7.2 or later, Pester, InvokeBuild, git, and
`$env:AZDO_PAT`. All five count as missing if absent, and the PAT line says in
so many words that it is needed only by the three Azure DevOps skills and not to
build a module — so a missing PAT is a `1 of 5 missing` you can knowingly
ignore, not a mystery. The checker itself runs under Windows PowerShell 5.1 on
purpose: a prerequisite checker that will not start on the wrong PowerShell is
useless exactly when you need it.

Then paste these three inside **Claude Code**, not in a shell:

    /plugin marketplace add JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder@v1.0.0
    /plugin install psmodule@psmodule-builder
    /psmodule:build

The first adds this repository as a plugin marketplace, **pinned to the
`v1.0.0` tag**. The pin is deliberate and is
[decision 0013](decisions/0013-harness-release-tagging.md): `main` moves as work
lands, and pinning means none of that reaches you until a release is tagged.
Drop the `@v1.0.0` and you are tracking whatever `main` happens to be, which is
not a release and is not what these measurements are about.

The second installs the plugin from that marketplace. The third is the plugin
doing something — run it in a PowerShell module repository and it builds to the
conventions the [skills](#the-skills) describe.

**To remove it again:**

    /plugin uninstall psmodule@psmodule-builder
    /plugin marketplace remove psmodule-builder

**Prefer to try it without touching anything public?**
[Chapter 9](docs/creating-an-agent/09-try-before-you-trust.md) stages the same
plugin as a local marketplace under `scratch/` and installs it from a path on
your own disk. Nothing is fetched and nothing is pushed.

**Before you install, read what this does and does not do.** The
[with/without table](#with-the-plugin-and-without-it) is the measured effect and
one of its two rows is nearly flat; [Status, honestly](#status-honestly) is the
list of what is still unproven, including the fact that nobody has yet installed
this cold on a machine that has never cloned the repository.

## Creating a new agent, start here:

Everything here was built by directing Claude, and the method is written down
so you can do the same thing on your own domain. Start at
[docs/creating-an-agent/00-start-here.md](docs/creating-an-agent/00-start-here.md)
— eleven chapters, each one worked against a real pass, run or decision in this
repository, including the mistakes.

**Deciding whether this much testing is worth it?**
[docs/testing/](docs/testing/README.md) explains what each layer of the stack
catches that the others do not, with the artifact behind every claim.

**Try it locally first.**
[Chapter 9](docs/creating-an-agent/09-try-before-you-trust.md) installs and
drives the plugin entirely on your own machine, and shows you how to remove it
again, before anything public is involved.

---

<!-- TEMPLATE:remove — every score below this line to the end of "The
     recurring findings" is a measurement of THIS agent against THIS
     fixture. A new project has taken no measurements, and a table of
     scores with the numbers blanked out invites filling them in with
     guesses. Delete the four sections; do not adapt them. -->

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

<!-- TEMPLATE:replace — a reader of a templated copy still needs three
     paste-able commands in exactly this position. The script paths, the
     module name and the tag set are this project's; the shape is not. -->

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

<!-- TEMPLATE:replace — keep the section and the discipline. $env:AZDO_PAT,
     the read-only claim and the Azure DevOps coordinates are DOMAIN in
     method/METHOD.md's sense; the credential rule and the blind gate are
     PORTABLE and should survive re-nouning. -->

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

<!-- TEMPLATE:remove — this section argues from this project's four runs.
     The argument is only as good as the measurements behind it, and a
     templated repository has none yet. Write it again at the end, from
     your own journal, the way pass 0029 wrote this one. -->

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

<!-- TEMPLATE:replace — a plugin needs a table of what it contains and what
     each part is for. These fourteen names, their prefixes and the two
     findings noted against them are this project's. -->

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

<!-- TEMPLATE:replace — a new project also has more than one repository and
     also needs one place saying which they are and which is governed from
     where. Swap the rows, keep the table. Everything from here to the end
     of the tf-001/tf-002 subsection is this project's content. -->

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

<!-- TEMPLATE:replace — the directory contract is worth keeping almost
     verbatim; only the evals/ rows describe a domain. -->

## Layout

| Path | What |
|---|---|
| `skills/` | The plugin's fourteen skills |
| `commands/` | `/build` and `/test` |
| `evals/conformance/` | The shape oracle: `Conformance.Tests.ps1`, its runner, the falsification record |
| `evals/functional/` | The behaviour oracle: `BRIEF.md`, `fixture/`, the comparator, the seed |
| `evals/HARNESS.md` | What a run consists of, and the thirteen hazards |
| `runs/` | One directory per scored run, with its artifacts and transcripts |
| `plans/` | One per pass: evidence per task, deviations, a verify script that re-derives the scores |
| `journal/` | Append-only, six fields per pass |
| `decisions/` | Append-only decision records |
| `method/` | The method, including its known limits |

---

<!-- TEMPLATE:remove — an honest status section is mandatory and its
     CONTENT cannot be inherited. Delete these bullets and write your own
     the first time you have something to be honest about. -->

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

<!-- TEMPLATE:replace — every project that becomes installable needs a
     versioning promise and a support statement, and both must be honest about
     what THIS maintainer can actually sustain. Keep both sections; rewrite the
     cadence, the scope of a major, and the contact route for your own. Do not
     inherit a cadence you have not agreed to. -->

## Versioning

Releases are tagged `vMAJOR.MINOR.PATCH`
([decision 0013](decisions/0013-harness-release-tagging.md)), and the tag is
what you install. The number on the tag and the `version` in
`.claude-plugin/plugin.json` always agree; if they ever disagree, that is a
defect, not a variant.

| | What may change | What you should do |
|---|---|---|
| **PATCH** — `1.0.x` | Corrected documents, clarified skill wording, fixed defects. Nothing changes what the plugin asks a builder to do. | Upgrade freely. |
| **MINOR** — `1.x.0` | New skills, new commands, new conventions. Existing conventions keep meaning what they meant. | Upgrade freely; read the [CHANGELOG](CHANGELOG.md) for what is new. |
| **MAJOR** — `x.0.0` | A skill removed or renamed, a command's contract changed, or a convention the conformance suite enforces **reversed**. Your existing use can break. | Read the CHANGELOG before upgrading. Modules built to the old conventions may stop conforming. |

**The pin is the promise.** Because you added the marketplace at a tag, none of
this reaches you until you change the tag. `main` moves whenever a pass lands —
that is work in progress, not a release, and pinning is what keeps the two
apart. To move to a later release, remove the marketplace and add it again at
the new tag.

**A caution about MAJOR.** This project's conventions are graded by a
conformance suite. A reversed convention does not merely change advice — it
changes what your module must look like to score. That is why it is a major, and
why the CHANGELOG will say so in those terms.

## Support

**This is a solo project.** One person, no team, no company behind it, no paid
tier and no service-level agreement. That is not a disclaimer added for form; it
is the single most useful thing to know before you depend on this.

**Issues:** <https://github.com/JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder/issues>

**The cadence, stated so you can plan around it:** issues are read in batches,
roughly **weekly**. Security reports are looked at first — see
[SECURITY.md](SECURITY.md). Everything else is triaged when the batch is read,
and a reply may be "not planned", which is a real answer and is better than
silence. There is no on-call and there is no guaranteed response time. If you
need one, this project cannot give it to you.

**What a good bug report contains.** The audit commands are the same ones
[chapter 05](docs/creating-an-agent/05-calling-bullshit-verification.md) uses to
check any claim made in this repository, including the maintainer's. Run them
and paste the output — a report with them is actionable, a report without them
usually turns into three round-trips before anything can start:

    # 1. What you are running, exactly.
    pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
    pwsh -NoProfile -File ./tools/publish/Test-Prerequisites.ps1

    # 2. Which version of the plugin, and whether it is the tagged one.
    #    Run inside Claude Code:
    #      /plugin
    #    and report the version shown against psmodule.

    # 3. If you cloned the repository, where its HEAD actually is.
    git -C <your-clone> rev-parse HEAD
    git -C <your-clone> describe --tags --always
    git -C <your-clone> status --porcelain

    # 4. The failure itself, re-run rather than remembered.
    #    Paste the command you ran and its complete output, not a summary.

Then say **what you expected and what happened**, in that order, and separately.
The most common unactionable report is one that states a conclusion — "the build
skill is broken" — without the transcript that led to it. If a score or a count
is involved, say which command produced it: this repository's own rule is that a
number nobody re-derived is a claim, and that applies to reports as much as to
its own documents.

**Never paste a PAT, a token or an organisation URL into an issue.** If you
think you have leaked one, revoke it first and report second.

**What is most useful of all:** a cold-install report. Nobody has yet installed
this on a machine that has never cloned the repository. If you are the first,
say so and say what happened, and that is worth more than a bug report.

## Licence

MIT — see [LICENSE](LICENSE).

Copyright (c) 2026 Jerry Balmer. The licence file, the `license` field in
`.claude-plugin/plugin.json` and the entry in `.claude-plugin/marketplace.json`
all say MIT, and the release pass checks that they agree.
