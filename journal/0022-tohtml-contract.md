---
pass: 0022
title: Put a contract and a battery between producers and the renderer
date: 2026-08-29
artifacts:
  - plans/0022-tohtml-contract/plan.md
  - plans/0022-tohtml-contract/accept.Tests.ps1
  - plans/0022-tohtml-contract/verify.ps1
---

# Pass 0022 — Put a contract and a battery between producers and the renderer

## Asked

Build PSGraphRenderToHtml: a producer-graph contract at 0.1.0, four commands
(validate, options, map to the render view model, export), and a parameterised
Pester battery any producer can run against its own output. Falsify the
contract against eight violating graphs and render the sample once per layout.
Release v0.1.0. Resumed after a session limit interrupted the first attempt
with 33 files uncommitted and nothing pushed.

## Done

- PSGraphRenderToHtml `main` at `bb2fbacbc6c1cded4d49fc17e79bf54a82150281`,
  fast-forwarded after `git merge-base --is-ancestor` returned 0. Tag `v0.1.0`
  annotated, dereferencing to the same SHA. Branch `pass-0022-contract` pushed.
- Six commits, first of them the inherited tree unrepaired and pushed before
  anything was touched.
- `contract/producer-graph.schema.json` 0.1.0; `Test-ProducerGraph`,
  `New-GraphRenderOptions`, `ConvertTo-GraphRenderViewModel`,
  `Export-ProducerGraphHtml`; `tests/ProducerContract.Battery.ps1`; six PreTag
  seals; `docs/HANDOFF.md`, `README.md`, `docs/worklog/v0.1.0.md`; five
  rendered samples committed.
- PSGraphRender `main` at `0156ba7be959c7873f05beb4a80c97aa6ab75277` — one
  README consumer line, on its own branch, ancestry checked.
- Harness branch `pass-0022-tohtml-contract` with the plan, the acceptance
  test, `verify.ps1` and a README ecosystem section naming all six
  repositories.

## Why

The mapping between a producer and the renderer — derive depth, count
dependents, decide what becomes a metric, carry an unresolved reference
through — lived inside the one producer that existed. One producer can hold
its own mapping. Two producers holding two copies is where they start
disagreeing about what depth means, neither of them wrong, and the reports stop
being comparable. It was extracted before the second producer rather than after.

The contract refuses to carry depth, and that is the load-bearing decision.
Depth is a function of the `parentId` chain, so a stored copy is a second
source of truth that nothing notices going stale until a layered layout puts a
node in the wrong row months later. `additionalProperties: false` at every
level makes a stored depth an error rather than a field nobody reads. The same
reasoning made containment `parentId` and never an edge.

Rejected: enumerating node types or edge kinds. They are free strings the
module never reads, because the moment it enumerated them it would know what a
producer's domain is and the second producer would need a code change here —
which is the exact coupling the renderer was extracted to remove.

Rejected: passing options to `New-RenderDocument`. It has no settings
parameter, deliberately, because PSGraphRender's rule is that adding a setting
must require editing data files only. Options are applied by materialising a
temporary overlay of the chosen backend and passing `-TemplateSetPath` — the
seam that repository documents for a backend it does not ship. It costs a
half-megabyte copy per render, which is recorded rather than hidden.

## Measured

From `scratchpad/0022-build.txt`, `0022-pretag.txt`,
`0022-F1-falsification.txt`, `0022-F2-integration.txt` and `0022-verify.txt`,
all quoted in `plans/0022-tohtml-contract/plan.md`:

| | Result |
| --- | --- |
| `./build.ps1` | 59 passed, 0 failed, coverage 87.74% against a target of 75 |
| `./build.ps1 -Task PreTag` | 6 passed, 0 failed |
| Battery on the committed sample | 7 passed, 0 failed |
| F1 violating graphs | **REJECTED 8 / 8, ACCEPTED 1 / 1** |
| F2 renders | **5 / 5, markers discriminating: yes** |
| `verify.ps1` from fresh clones | **17 checks, 0 failed** |

Acceptance: 5 passed / 1 failed at resume, 6 passed / 0 failed at the end.

F2's three cytoscape documents differ by one and two bytes — the length of the
layout name in the embedded configuration and nothing else.

## Learned

**A parameter and a loop variable that differ only in case are one variable.**
`Get-ProducerGraphDepth` took `$Node` and looped `foreach ($node in $Node)`.
The first loop overwrote the parameter with its last element; the second
iterated a single object. Fifteen nodes produced a depth table with one entry,
no error and no warning, surfacing three layers later as a null
`metrics.depth` against the render contract. Found by running, not by reading —
the same shape as every defect this project has recorded.

**A falsification set is worth running even when you wrote the thing it
tests.** F1 rejected all eight graphs on its first run and was still a finding:
every schema-layer violation reported the document root while the JSON Pointer
naming the real location sat unparsed in the message. The reds were all correct
and the report was useless, and only reading the transcript said so.

**A gate that cries wolf and a gate that finds a defect look identical on the
first run.** The new documentation-path seal flagged two things. One was real —
a README claiming a local vendoring document in a module that vendors nothing.
One was a false positive — a file a *producer* creates in its own repository.
Narrowing the gate mattered as much as fixing the defect, because a gate that
reports both trains a reader to ignore it.

**A task that can only fail is not a gate.** `-Task PreTag` existed with no
`PreTag`-tagged test, so its own zero-test guard failed it every run. Closing
that also let two guarantees come back that pass 0021 recorded as lost when
PSGraphRender's `Instructions.Tests.ps1` was deleted: documentation names only
paths that exist, and no document can cause a push by being followed.

**A gate outside the lint chain is a gate whose own defects arrive late.**
`PreTag` depends on `Build`, not on `Lint`, so an assignment to the automatic
variable `$matches` went green under `-Task PreTag` and red under the default
build.

**verify.ps1 earned its keep on its first run.** Three of seventeen checks
failed and all three were verify's own defects — but one of them is a real
ecosystem fact nothing else states: **a fresh consumer must build PSGraphRender,
not merely clone it**, because its manifest's `RootModule` names a psm1 the
build generates. The second was a 428-character difference measured rather than
assumed: exactly 428 carriage returns, from `.gitattributes` storing LF while a
Windows render writes CRLF.

**The plugin's scaffold skill has a gap.** Its manifest pattern makes `src/`
un-importable, which is correct for the build and wrong for anything that
imports the module without building first — including this pass's own
acceptance test, and including PSGraphRender today. A committed dev-loader
`.psm1` fixes it in one file. The skill mentions neither the problem nor the
fix.

## Capability

A producer can now be told what to emit and be checked against it mechanically.
`tests/ProducerContract.Battery.ps1` is parameterised on a graph file and runs
inside a producer's own build, and its last assertion is the one that matters:
that the graph maps to a view model **the renderer accepts**. A producer author
can be wrong about the contract and find out from their own suite rather than
from a broken report.

The ecosystem also gained a second worked example of the handoff shape — a
repository with `docs/HANDOFF.md`, a versioned contract of its own, PreTag
seals and no resident agent process — built from scratch to that shape rather
than converted to it.
