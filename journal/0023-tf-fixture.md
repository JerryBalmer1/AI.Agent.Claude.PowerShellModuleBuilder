---
pass: 0023
title: Build a Terraform fixture and an oracle worth scoring against
date: 2026-08-29
artifacts:
  - plans/0023-tf-fixture/plan.md
  - plans/0023-tf-fixture/accept.Tests.ps1
  - plans/0023-tf-fixture/verify.ps1
  - plans/0023-tf-fixture/mutations.txt
  - plans/0023-tf-fixture/readback.txt
  - decisions/0011-terraform-fixture-and-run-ledger.md
  - evals/tf/fixture/cases.md
  - evals/tf/fixture/expected-graph.json
---

# Pass 0023 — Build a Terraform fixture and an oracle worth scoring against

## Asked

Author three Terraform repositories in the harness, push them to a new AzDO
project, hand-author the combined configuration graph as an oracle in the
producer-contract shape, and write a comparator plus a mutator — red-first,
then falsified against seven mutations. Verify the push by byte read-back.
Create pipeline definitions and never queue one.

## Done

- Harness `main` at `<recorded in the plan>`, branch `pass-0023-tf-fixture`
  pushed after every task group.
- AzDO project **ClaudeTestingTerraform** created by REST (it did not exist);
  three repositories created and pushed concurrently:

  | Repository | Files | Initial commit |
  | --- | --- | --- |
  | TfFixtureShared | 13 | `0af6ee33854bedb4147d0b13cc6db1311687775b` |
  | TfFixtureNetwork | 14 | `24f27be92e583b6dfc9208bca42f8ec0baf5004b` |
  | TfFixtureApp | 13 | `187ff229c0ad908eb39822f1bb78b6c0e3a206b3` |

- Four pipeline definitions (ids 16–19). **Zero builds queued**, confirmed by
  querying the project's entire build history.
- `evals/tf/fixture/expected-graph.json` — 78 nodes, 57 edges, valid against
  the producer contract with zero violations.
- `evals/tf/Compare-TfGraph.ps1`, `Mutate-TfGraph.ps1`,
  `Compare-TfGraph.Tests.ps1` (15 assertions, red before either script
  existed), `TfAzdoClient.ps1`, `Publish-TfFixture.ps1`,
  `New-TfFixturePipeline.ps1`, `Test-TfFixtureReadBack.ps1`.
- `decisions/0011-terraform-fixture-and-run-ledger.md`, verbatim as directed.

## Why

**The oracle was hand-authored from reading the configuration and never
produced by parsing it.** An oracle derived from a parser is a second copy of
the thing under test, and two copies of one mistake agree with each other. The
counts are stated in `cases.md` per repository and per type so a reader can
check the total rather than trust it — and the check found a real error in the
prose, which is the point of stating them.

**A separate AzDO client, rather than loosening the existing one.**
`evals/functional/AzdoClient.ps1` refuses to operate against any project but
`ClaudeTesting`. That guard is worth more than the code it duplicates: making
it reach a second project would remove the only thing standing between a script
and the frozen AzDO fixture. The new client refuses `ClaudeTesting` **by name**,
so its failure says what went wrong rather than only what was allowed.

**The comparator stages its matching**, and the two extra categories are the
reason. A node whose parent moved is one defect; reported as a removal plus an
addition a reader cannot tell it from two unrelated ones, and a score built on
it counts one mistake twice. Same for an edge whose kind changed. Two of the
fifteen assertions exist only to hold that distinction.

Rejected: modelling the unresolvable module as a dangling edge. The producer
contract requires every edge endpoint to resolve, so the fixture emits a node
for the unresolvable target and marks the edge `resolved: false` with a reason.
That is a decision the contract forced and it is documented as case 7, because
the alternative — a producer inventing a rule at scoring time — is how two
producers end up disagreeing.

Rejected: using the existing `Terraform` project in the organisation. The
prompt names `ClaudeTestingTerraform` and a project that happens to have a
similar name is not the one authorised.

## Measured

From `plans/0023-tf-fixture/mutations.txt`, `readback.txt` and the verify run:

| | Result |
| --- | --- |
| Oracle | 78 nodes, 57 edges, 0 contract violations |
| by type | 3 repository, 10 module, 33 variable, 9 local, 17 output, 6 provider |
| by edge kind | 9 `sources`, 28 `references`, 20 `passes-to` |
| Comparator suite | 15 passed, 0 failed — red 15/15 before implementation |
| Mutations | **DETECTED: 7 / 7**, 7 of 7 distinct categories, control green |
| Read-back | **BYTE-IDENTICAL**, 40 files across 3 repositories |
| Builds queued | **0**, over the project's entire history |
| `verify.ps1` | **13 checks, 0 failed, 0 skipped** |

Acceptance: 0 passed / 5 failed before, 5 passed / 0 failed after.

## Learned

**Stating a count is what makes it checkable, and it caught me.** `cases.md`
claimed five pipeline definitions; there are four. Nothing would have noticed
if the number had been left vague — the value of writing "four distinct
versions across four definitions" is precisely that somebody can count them.

**A mutation that changes nothing is the failure mode of a falsification set.**
Every mutation here proves it changed the document before its detection is
trusted, and one of the seven — the provider version pin — changes the document
without changing its length, so the check has to compare text rather than size.
A length comparison would have passed it while proving nothing.

**`-WhatIf` on a publisher is worth having before the first real run.** The dry
run reported the exact file counts per repository and created nothing, which is
what made the real run a prediction rather than a hope. This fixture is frozen
the moment its oracle is falsified; there is no second first push.

**Line endings need normalising on both sides of a read-back, and the reason
needs writing down.** Every fixture repository carries
`.gitattributes` with `* text=auto eol=lf`, so git checks out LF while a Windows
working copy may hold CRLF. Comparing raw bytes would report a mismatch that is
about line endings and nothing else — the same trap that made pass 0022's
verify report a 428-character difference that turned out to be exactly 428
carriage returns.

## Capability

The harness can now score a producer against a **multi-repository**
configuration graph. Everything before this measured one repository at a time;
the Terraform fixture's cases 2 and 3 — a module sourced across repositories,
and an output consumed across repositories — cannot be seen at all by a
producer that treats each repository as a closed world, and now there is an
oracle that says so.

It also has a second scoring ledger. Per decision 0011, PSTerraformGraph runs
are `runs/tf-NNN-<slug>`, separate from the PSAzureDevOpsGraph `NNN` series, so
two lines of measurement can proceed without renumbering each other.
