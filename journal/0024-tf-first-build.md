---
pass: 0024
title: Build the second producer and measure the renderer's boundary
date: 2026-08-29
artifacts:
  - plans/0024-tf-first-build/plan.md
  - plans/0024-tf-first-build/accept.Tests.ps1
  - plans/0024-tf-first-build/verify.ps1
  - runs/tf-001-first-build/README.md
  - runs/tf-001-first-build/findings.md
  - runs/tf-001-first-build/graph.json
---

# Pass 0024 — Build the second producer and measure the renderer's boundary

## Asked

Build PSTerraformGraph with the plugin: a real HCL tokenizer and block parser,
graph assembly against PSGraphRenderToHtml's producer contract, rendering
delegated. Score it against the frozen Terraform fixture, iterating at most
three times. Record the run as `runs/tf-001-first-build`. Release v0.1.0.

## Done

- PSTerraformGraph `main` at `05fb60d5286e99b302afbfaf5eee87c866ecd14c`,
  annotated tag `v0.1.0` dereferencing to the same SHA, branch pushed, `main`
  fast-forwarded after ancestry check.
- Two exported commands, ten source files across `Private/Hcl`,
  `Private/Graph` and `Public`. 33 tests, 83.40% line coverage.
- `runs/tf-001-first-build/` — README, findings, `graph.json`, three rendered
  layouts.
- Consumer-list fan-out: PSGraphRenderToHtml `main` at `20877f75`,
  PSGraphRender `main` at `2231b4bd`, each a one-line commit on its own branch
  with ancestry checked.

## Why

**A tokenizer, not a pattern.** Decided before anything was written and it
never came back. The fixture has a brace inside a string, a `#` inside a
string, a heredoc, and block comments, and each defeats a regex differently.

**Parse, model, resolve as three stages.** The AzDO brief's parse-versus-resolve
precedent. It paid on the first scoring iteration: two of the three defects were
in the resolver and were fixed without touching the parser, and the third was in
the parser and did not touch the resolver.

**Scored by case, not by raw difference count.** 31 raw differences remained,
and 28 of them are one convention repeated. A count answers "how many lines
differ"; the seven named cases answer "what does it not understand", and only
the second is a score anybody can act on. Both are reported.

Rejected: fixing the two remaining fixable differences after the third
iteration. The cap was three and the score was taken; a defect found and quietly
fixed after the measurement makes the measurement a different thing. Both are
recorded in `findings.md` and in the module's own HANDOFF.

Rejected: editing the fixture when case 3 turned out to be unpassable. It is
frozen by decision 0011, and a fixture edited to match what the producer does
measures nothing.

## Measured

| | Result |
| --- | --- |
| Build | exit 0, 33 tests passed, 0 failed, coverage 83.40% (target 70%) |
| Battery | 7 / 7 — the graph satisfies the producer contract and maps to a view model the renderer accepts |
| **functional-tf** | **6 / 7** on the fixture's named cases |
| Raw differences | 94 → 68 → 31 across three iterations |
| `verify.ps1` | **12 checks, 0 failed, 0 skipped**, from fresh clones of all three repositories |

Acceptance: 0 passed / 4 failed before, 4 passed / 0 failed after.

Graph: 78 nodes (the oracle's exact count) and 54 edges of 57.

## Learned

**Three defects, and every one of them failed silently.** A local path
`./modules/service` is literally `namespace/name/provider`, so it matched the
Terraform registry pattern and every nested module resolved to a registry
address that does not exist. `required_providers` is a *block*, not an
attribute, so a reader looking for an attribute found no providers at all —
indistinguishable from a repository that pins none. And the parser rebuilds an
expression by joining tokens, so `var.tags` reaches the reference extractor as
`var . tags` and every pattern written against source text missed, costing 37
edges — the entire traceability chain.

None produced an error, a warning, or an empty result that looked wrong. The
hand-authored oracle is the only thing that found them, which is the whole
argument for building one before the producer.

**A fixture case can be unpassable, and only a producer finds out.** Case 3 ties
a variable to another repository's output through the variable's *description* —
prose. No parser can read that. It is also the only case a single-repository
parser could not see, so **the case the three-repository fixture was built for
is the one that does not work.** Written as a finding against a frozen fixture
rather than fixed, and it is the most important thing this pass learned.

**The renderer's boundary held its first real test.** PSTerraformGraph drives
PSGraphRender through PSGraphRenderToHtml and **not one line of either changed
to allow it.** That rule — the renderer knows about nodes and edges and nothing
about what they are — has been an assertion since the extraction. A second
producer, in a domain nobody had in mind, is the first evidence for it.

**A count and a score are different questions.** 31 differences sounds like 31
defects and is 3 mechanisms: one convention mismatch (28), one unpassable
fixture case (2), one genuine gap (1).

## Capability

The harness can now build and score a producer for a **non-PowerShell domain**,
end to end: a fixture in three repositories, a hand-authored oracle, a falsified
comparator, a module built to a contract it does not own, and a run record that
refuses to be read as more than it is.

It also has its first evidence about the plugin outside AzDO. `findings.md`
names four places the `powershell-module-*` skills were wrong or silent for this
target — the scaffold's un-importable `src/` chief among them, now the second
module in two passes to need the same fix — and proposes three `tf-<role>`
skills written from what actually cost time rather than from what a Terraform
module might plausibly need.
