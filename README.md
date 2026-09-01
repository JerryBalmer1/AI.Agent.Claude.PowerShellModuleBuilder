# AI.Agent.Claude.PowerShellModuleBuilder

A test-first harness that makes an AI coding agent's output **measurable**, and
the Claude Code plugin distilled from what the harness measured.

Two things live here, and the order matters. The harness came first: a
conformance suite, a hand-written oracle, and a scoring runner, all built and
falsified before any agent was asked to produce anything. The plugin —
`skills/` and `commands/` — is what the harness's findings hardened into. The
claim this repository exists to test is that the second measurably improves the
first's scores, and that claim is not yet proven.

## The latest run

[Run 002 — first build](runs/002-first-build/) built
[PSAzureDevOpsGraph](https://github.com/JerryBalmer1/PSAzureDevOpsGraph/tree/run-002-first-build),
a read-only Azure DevOps pipeline dependency grapher, from a four-file seed.

```
build:       exit 0
conformance: 57 / 57
functional:  12 / 12
```

| Score | Means | Evidence |
|---|---|---|
| **build: exit 0** | It assembles; analyzer clean, 37/37 tests, 82.88% coverage against a 40% target | [run README](runs/002-first-build/README.md) |
| **conformance: 57/57** | **Shape** — manifest, layout, build file, tests, exported names | [conformance-result.json](runs/002-first-build/conformance-result.json) |
| **functional: 12/12** | **Behaviour** — the graph equals the hand-written oracle exactly | [diff.txt](runs/002-first-build/diff.txt), [graph.json](runs/002-first-build/graph.json), [002.html](runs/002-first-build/002.html) |

**Read that honestly.** Run 002 is *not* a baseline: the plugin was seeded in
the same pass and the builder read the twelve cases as a specification. It
measures that the module works, not that the plugin helps. Comparative scoring
starts at run 003. The twelve
[findings](runs/002-first-build/findings.md) are the actual product of the run —
including a lint gate that went green on a file that could not be parsed.

## The method

**Red first, always.** Every acceptance test is written and *run* before the
thing it tests exists, and the red output is recorded with its failure messages.
A test first seen green proves nothing about whether it can fail. Run 002's
acceptance test failed 7/7 before the work and passes 7/7 after; both outputs are
in [the plan](plans/0016-first-build/plan.md).

**An assertion does not count until it has been falsified — with a control.**
Breaking the reference and confirming an assertion goes red proves it *can*
fail. A near-miss control that must stay **green** proves it fails for the
*right reason*. The two are different claims and the first does not imply the
second: five build-file assertions passed their red probes and were still inert,
satisfied by a block comment quoting the code they looked for. The table of
breaks and controls is in
[evals/conformance/README.md](evals/conformance/README.md); one control is
currently failing and says so.

**Shape and function are scored separately and never averaged.** Conformance
measures conformity: manifest keys, directory layout, build tasks, export lists.
It cannot tell whether the module does anything. A separate functional check
compares a produced graph against a hand-written oracle. A module can score 100%
on one and zero on the other, in either direction, and collapsing them into one
percentage destroys both numbers.

**Runs are evidence, not anecdotes.** Every run records the SHAs of its inputs —
plugin, seed, brief, target — its wall clock, the exact commands that produced
every artifact, and a verify script that **re-derives** the scores from a fresh
clone rather than reading them from the write-up. A number without an artifact
behind it does not belong in a plan.

**Variance is the signal.** Where the brief under-specifies something, the agent
must flip a coin, and different runs flip differently. Those coin-flips are
recorded by name — run 002 found five field conventions the specification never
states — because removing that variance is precisely what the plugin is for.

## The skills

Named by scope, per [decision 0007](decisions/0007-skill-taxonomy-and-naming.md):
`powershell-module-<role>` for anything generic to building a PowerShell module,
`azdo-<role>` for what is specific to the Azure DevOps target. Dots are not legal
in skill names, which is what rules out the `powershell.module.x` form.

`producer-contract` fits neither prefix, and that is a gap in decision 0007's
taxonomy rather than a naming slip: it is about emitting against a contract
another repository owns, which is not a PowerShell-module lifecycle stage and
not specific to any one target. Recorded in pass 0025 for the operator to
settle if a second cross-cutting skill ever appears.

Rule 9 governs what goes where inside one: judgment is the `SKILL.md`,
deterministic mechanics are scripts under the skill's `scripts/`, and user entry
points are commands.

| Skill | Role |
|---|---|
| `powershell-module-plan` | Intake and planning. A fixed question set, a plan file generated into the target, and a definition-of-done section that must name how the work will be tested before the work starts. |
| `powershell-module-architect` | Command-surface design — verb-noun, one command one question, parameter sets, when to split, `Public/` versus `Private/`. |
| `powershell-module-scaffold` | The repository layout the conformance suite grades: manifest, `Public/` flat, `Private/` nested, explicit exports. |
| `powershell-module-build` | `build.ps1` and `<Name>.build.ps1` — InvokeBuild tasks, the analyzer severity list including `ParseError`, the coverage gate, exit-code discipline. |
| `powershell-module-test` | The Pester suite, and `scripts/Invoke-OrderedTests.ps1` — five layers in dependency order, stopping at the first failure so one defect reports as one file. |
| `powershell-module-analyzer` | AST-driven analysis that never runs the code it reads, and writes `docs/knowledge/<tool>.md` when a dependency turns up that nothing has documented. |
| `powershell-module-docs` | Comment-based help, `about_` topics and the culture directory the build must copy, README structure, examples that are real. |
| `powershell-module-deploy` | Staging and output layout, prerequisites verified before anything ships, and why `Publish-Module` is the operator's alone. |
| `powershell-module-release` | Semver against a module surface, release notes by change type, changelog and worklog conventions, what a release checklist verifies. |
| `azdo-rest` | The Azure DevOps REST API, read-only. `$env:AZDO_PAT` and nothing else, ever. |
| `azdo-pipeline-yaml-refs` | Extracting and resolving pipeline YAML references, with parsing separated from resolution. |
| `azdo-graph-assembly` | Turning those references into a graph — identity by what a node is, never by where a traversal reached it. |
| `producer-contract` | Emitting data against a schema another repository owns: absent versus false for optional fields, running the consumer's battery in your own build, never renaming what the contract names. |
| `task-tree-reporting` | Response formatting during multi-skill work. Markdown structure only, so the tree survives transcripts and commits. |

## Layout

| Path | What |
|---|---|
| `skills/` | The plugin's fourteen skills — see [the roster](#the-skills) above |
| `commands/` | `/build` and `/test` |
| `evals/conformance/` | The shape oracle: `Conformance.Tests.ps1`, its runner, and the falsification record |
| `evals/functional/` | The behaviour oracle: `BRIEF.md`, `fixture/`, the comparator, the seed |
| `runs/` | One directory per scored run, with its artifacts |
| `plans/` | One per pass: the prompt verbatim, evidence per task, deviations, a verify script |
| `journal/` | Append-only, six fields per pass |
| `decisions/` | Append-only decision records |
| `method/` | The method, including its known limits |

## Running it

Needs PowerShell 7.2+, Pester 6.x, PSScriptAnalyzer, InvokeBuild.

```powershell
# Shape. Read the score from result.json, never from the exit code -
# a red conformance run is data, and the runner exits 0 on purpose.
./evals/conformance/Invoke-Conformance.ps1 `
    -Path <module repo> -ModuleName <Name> `
    -Tag @('Universal','Repository','HouseStyle','RequiresBuild')

# Behaviour. Needs $env:AZDO_PAT only if you regenerate the graph.
./evals/functional/Compare-Graph.ps1 -CandidatePath <graph.json>

# The fixture and oracle agree with each other, in both directions.
Invoke-Pester ./evals/functional/Fixture.Tests.ps1     # 352 cases
Invoke-Pester ./evals/functional/ReadBack.Tests.ps1    #  76 cases, needs AZDO_PAT
Invoke-Pester ./evals/functional/Compare.Tests.ps1     #  28 cases
```

`-ModuleName` is optional. When the repository root is a run directory the
runner derives it from `src/<Name>/<Name>.psd1`; two manifests under `src/` is
undecidable and stops, naming both, rather than grading the wrong module
silently.

## Credentials

`$env:AZDO_PAT`, and nothing else, everywhere. Never a parameter, never a file,
never in a URL. Every run scans its own artifacts for PAT-shaped strings before
committing; run 002's scan is in its
[plan](plans/0016-first-build/plan.md).

## The ecosystem

Six repositories, governed from here. `main` moves in each only by
fast-forward after a green pass, ancestry checked and never forced — decision
[0009](decisions/0009-agent-moves-both-mains.md) for the target,
[0010](decisions/0010-ecosystem-repo-governance.md) for the rest.

| Repository | What it is | State |
| --- | --- | --- |
| this one | the harness, the oracle, and the plugin distilled from what they measured | — |
| [PSAzureDevOpsGraph](https://github.com/JerryBalmer1/PSAzureDevOpsGraph) | the build target: a read-only AzDO pipeline dependency grapher | built and scored, runs 002–003 |
| [PSGraphRender](https://github.com/JerryBalmer1/PSGraphRender) | the renderer. Takes a view model, writes one self-contained HTML page, and knows nothing about what the nodes are | v0.13.0, handed over |
| [PSGraphRenderToHtml](https://github.com/JerryBalmer1/PSGraphRenderToHtml) | the battery between a producer and the renderer: producer-graph contract, options, mapping, and the contract battery a producer runs against its own output | v0.1.0 |
| [PSModuleGraph](https://github.com/JerryBalmer1/PSModuleGraph) | the first producer, and the repository the renderer was extracted from | the renderer's only consumer today |
| [PSTerraformGraph](https://github.com/JerryBalmer1/PSTerraformGraph) | the second producer, and the first that is not PowerShell | v0.2.0, scored in [tf-001](runs/tf-001-first-build/) and [tf-002](runs/tf-002-convention-and-case3/) |

The renderer's boundary is the claim the ecosystem exists to test: **a producer
in any language can drive it without changing it.** As of run tf-001 that is a
measurement rather than an assertion: PSTerraformGraph drives PSGraphRender
through PSGraphRenderToHtml, in a domain nobody had in mind when the renderer
was extracted, and **not one line of either changed to allow it**. Run tf-002
re-scored it at **0 differences and 7/7** after the fixture's case 3 was
repaired under [decision 0012](decisions/0012-fixture-case3-repair.md) and two
producer defects were closed — still with the oracle visible, so it remains a
statement about one fixture and not a generalisation claim.

## Status, honestly

- The conformance suite is **falsified against one reference module**; every
  break turns its assertion red and eleven of twelve controls stay green. The
  twelfth is documented as failing.
- `Universal` has run against nine targets; **seven of nine assertions survive
  all nine**. The corpus control does not pass clean.
- The functional oracle covers **one** 15-pipeline fixture. Twelve cases, each
  naming the specific wrong answer it catches.
- **One module has been built and scored.** The plugin's effect on scores is
  unmeasured — that is what run 003 is for.
- `main` on this repository is far behind the working branch; see
  [decision 0005](decisions/0005-branch-and-merge-policy.md).

## Licence

MIT.
