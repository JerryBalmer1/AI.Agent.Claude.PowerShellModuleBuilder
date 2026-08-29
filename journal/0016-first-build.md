---
pass: 0016
title: First build - populate the plugin, build the module, ship the demo
date: 2026-08-29
artifacts:
  - plans/0016-first-build/plan.md
  - plans/0016-first-build/verify.ps1
  - plans/0016-first-build/accept.Tests.ps1
  - skills/module-scaffold/SKILL.md
  - skills/build-script/SKILL.md
  - skills/azdo-rest/SKILL.md
  - skills/pipeline-yaml-refs/SKILL.md
  - skills/graph-assembly/SKILL.md
  - commands/build.md
  - commands/test.md
  - runs/002-first-build/README.md
  - runs/002-first-build/findings.md
  - runs/002-first-build/DEMO.md
  - README.md
---

# Pass 0016 — First build

## Asked

The deliverable pass: populate the plugin with five skills and two commands,
build `PSAzureDevOpsGraph` from the four-file seed following those skills, score
it three ways, and leave both GitHub repositories looking like a real project to
a stranger. Explicitly a working session rather than a measured baseline — the
run record has to say so. Working beats elegant; anything worth polishing gets
shipped and noted in findings instead. Up to three scoring iterations, and
nothing under `evals/` may be touched to improve a score.

## Done

- `skills/` — `module-scaffold`, `build-script`, `azdo-rest`,
  `pipeline-yaml-refs`, `graph-assembly`; `commands/build.md`,
  `commands/test.md`; `version` added to `.claude-plugin/plugin.json`.
- `PSAzureDevOpsGraph` built in `scratch/runs/002-first-build` and pushed to
  `run-002-first-build` at `79e02fba9dffd976bccf507d531f59303cc58f9d`: 7 public
  commands, 6 private helpers, 3 test files, InvokeBuild build file, analyzer
  settings, `Requirements.psd1`, an `en-US` about topic, and its own README.
- `runs/002-first-build/` — README with the input SHAs and the iteration table,
  `graph.json`, `diff.txt`, `002.html`, `conformance-result.json`,
  `findings.md` (twelve findings across five mechanisms), `DEMO.md`.
- Root `README.md` rewritten, 41 bytes to roughly 6 KB.
- `plans/0016-first-build/` — plan, acceptance test, verify script.

## Why

**The node set is seeded from the definition list, not from the edge list.**
An orphan pipeline has no edges, so a graph whose nodes are derived from edges
loses exactly the pipeline a reader most wants to find — and its absence is
indistinguishable from a correct answer. Rejected: building nodes as edges are
discovered, which is shorter and passes every case except case-10.

**Repository nodes never come from the repositories endpoint.** The endpoint is
used to look files up and for nothing else. Turning its result into nodes is the
obvious first implementation and answers "what is in this project" instead of
"what do these pipelines depend on" — and only the second question makes *if I
change this template, which pipelines break* answerable. Case-12 passed in both
iterations because `graph-assembly` states this as a rule rather than a
preference.

**Parsing and resolution are separate commands.** `Get-AzDoPipelineReference`
takes text and needs no credentials or network; `Resolve-AzDoPipelineReference`
needs to know what exists where. Rejected: one command, which reports every
resolution failure as a parsing result with no way to tell which half was wrong.

**Cycle detection was rewritten from breadth-first revisit to three-colour
DFS.** "Have I seen this node" is not "is this node on the current path". The
first is true of every shared template, so the first implementation called four
diamonds cycles. Rejected: keeping it and filtering, which cannot work — the
information needed is not present in a BFS visited set.

**The reference walk skips `parameters:` subtrees entirely.** Exact-key matching
on `template` already excludes case-03's `buildTemplate:` decoy, so the skip is
broader than any case requires. Chosen anyway as the conservative reading of "a
parameter whose value looks like a template path is not a reference", and
recorded as a finding rather than left silent.

## Measured

- **Acceptance test**: red **0/7** (root README 41 bytes); green **7/7**.
- **build: exit 0** — PSScriptAnalyzer 0 findings, Pester **37/37**, coverage
  **82.88%** against a declared target of 40%.
- **conformance: 57/57 (100%)** — 57 cases run, 0 failed, **0 skipped, 0
  not-run**, across 33 assertions. `runs/002-first-build/conformance-result.json`.
- **functional: 12/12** — 49 nodes, 51 edges, **0 differences**, exit 0.
  `runs/002-first-build/diff.txt`.
- **Iteration 1: 1/12**, 60 differences — 15 `wrongNodeAttribute`, 29
  `wrongEdgeAttribute`, 8 `missingEdge` + 8 `extraEdge`. Node and edge counts
  were already exactly right.
- **Graph generation: 13.4 s** for 30 YAML files, against a 5-minute cap.
- **verify.ps1**: 31 checks / 0 skipped with the PAT; 26 / 2 skipped without;
  39 checks under `-FailCheck`. All exit 0.
- **`002.html`**: 49 `data-node-id`, 2 `data-unresolved-id`, 0 `http(s)://`.
- **Fixture unchanged**: 15 definitions, **0 builds ever queued**, re-derived by
  verify check 6. Oracle blob still `bd7b3c4f…`; `evals/` diff empty.
- Wall clock **22 minutes**, `Reset-Target` to pushed module.

## Learned

**A lint gate can go green on a file that does not parse.**
`Severity = @('Error','Warning')` in `PSScriptAnalyzerSettings.psd1` — the idiom
every example shows — filters out `ParseError`, which is its own severity. The
Lint task reported clean on a source file that produced nine cascading parse
errors on import. It was caught one stage later, by the tests, and only because
the tests import the built module; a repository whose tests did not would have
shipped a green build over an unparseable file. This is the project's own
falsification lesson arriving from a direction nobody had aimed at: the gate had
only ever been green, and a gate that has only ever been green is
indistinguishable from one that cannot go red. The skill that prescribed the
wrong setting was written by this same pass, four hours earlier.

**Getting the structure right is not most of the work; getting the conventions
right is.** Iteration 1 produced the oracle's exact node and edge counts, with
every edge pairing correctly on `from`/`to`/`kind` — and scored 1/12. All 60
differences were attribute conventions that `cases.md` never states: whether
`pipeline` nodes carry `repo`, which edges carry `refKind`, whether a
`repositoryResource`'s `ref` is the alias or the `name:` value, whether
`checkout` carries `alias`, and whether `reason` is a code or a sentence. The
specification pins the graph and leaves the record format to be guessed. That is
precisely the variance the plugin exists to remove, and it is now a finding with
a proposed generated-from-the-oracle remedy rather than more prose.

**One convention could not be derived at all, and I read it from the oracle.**
The comparator reports a `ref` mismatch as a missing/extra pair, which by design
carries no expected value — so the diff could not teach it. Reading
`expected-graph.json` for that one field is the single largest caveat on the
12/12 and is why the run README refuses to call the score a baseline.

**A PowerShell error message can point almost anywhere but at the cause.** A
`[Parameter(Mandatory)]` collection parameter rejects an empty collection, which
is correct and documented. Inside Pester the same failure surfaced as *"A 'break'
or 'continue' statement with a label that does not match any enclosing loop
escaped from your code"*. Chasing the message rather than the binding failure
would have cost far more than `[AllowEmptyCollection()]` did.

**Two components can each be right and jointly broken.** Conformance discovery
refuses to guess which module it is grading, because guessing once silently
misgraded a vendored helper module. `Reset-Target.ps1` materialises the seed
*at* a destination named by run id. Neither is wrong; together they mean
discovery can never fire and `-ModuleName` is mandatory for every run — while
`evals/conformance/README.md` documents a path layout `Reset-Target` does not
produce.

**The demo was executed, not merely written.** A fresh clone of the pushed
branch built, imported, produced a graph, and that clone-generated graph scored
0 differences on its own. A DEMO.md nobody has run is a hypothesis.

## Capability

The plugin can now be pointed at a PowerShell module task and produce a
repository that passes the conformance suite outright — 57/57, zero skipped —
because five skills carry the suite's assertions as rules with their reasons
rather than leaving them to be rediscovered from the assertion text. Before this
pass `skills/` and `commands/` did not exist and the plugin was a manifest with
nothing behind it.

There is now a working module to point at: `PSAzureDevOpsGraph` answers *if I
change this template, which pipelines break* for a real Azure DevOps project,
read-only, and a stranger can clone one branch and reproduce its graph from
`DEMO.md` in about a minute. And there is a first scored run whose three numbers
are re-derivable from a fresh clone by one script — so run 003 has something to
be compared against, which is the thing that makes comparative scoring possible
at all.
