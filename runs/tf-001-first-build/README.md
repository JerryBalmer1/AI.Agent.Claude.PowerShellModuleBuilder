# Run tf-001 — PSTerraformGraph first build

The first entry in the `tf-NNN` ledger, which decision 0011 keeps separate from
the PSAzureDevOpsGraph `NNN` series.

```
plugin-sha:     0c9d8c059564c153c90062b87425cb9b7cee742f
build:          exit 0
module tests:   33 passed, 0 failed, line coverage 83.40% (target 70%)
battery:        7 / 7
functional-tf:  6 / 7
```

**This is the deliverable build, not the generalisation measurement: the oracle
was visible and iterated against. Line 1's generalisation claim needs its own
measured run.**

## What was built

`PSTerraformGraph` v0.1.0 — reads Terraform configuration across repositories
and produces a graph in PSGraphRenderToHtml's producer-contract shape.
Configuration only: **no terraform binary was installed or invoked**, no plan
was produced, no state was read.

Two exported commands: `Get-TfConfigurationGraph` and
`Export-TfConfigurationGraphHtml`.

## What it was scored against

| | |
| --- | --- |
| Fixture | `evals/tf/fixture/`, frozen by decision 0011 |
| Oracle | `evals/tf/fixture/expected-graph.json` — 78 nodes, 57 edges, hand-authored |
| Comparator | `evals/tf/Compare-TfGraph.ps1`, falsified 7/7 in pass 0023 |

Fixture clones, taken fresh from AzDO and identical to the SHAs pass 0023's
read-back verified:

| Repository | Commit |
| --- | --- |
| TfFixtureShared | `0af6ee33854bedb4147d0b13cc6db1311687775b` |
| TfFixtureNetwork | `24f27be92e583b6dfc9208bca42f8ec0baf5004b` |
| TfFixtureApp | `187ff229c0ad908eb39822f1bb78b6c0e3a206b3` |

## Iterations

Three, the cap the pass allowed. Each row is a full re-score against the frozen
oracle.

| # | Differences | Nodes | Edges | What changed, and what it cost |
| --- | --- | --- | --- | --- |
| 1 | **94** | 78 / 78 | 15 / 57 | first run. 6 extra nodes, 6 missing, 48 missing edges |
| 2 | **68** | 78 / 78 | 17 / 57 | local module sources were matching the *registry* address pattern — `./modules/service` is literally `name/name/name` — so every nested module resolved to a registry address that does not exist. And `required_providers` is a **block**, not an attribute, so no provider was found at all. Both fixed: all 12 node differences went |
| 3 | **31** | 78 / 78 | 54 / 57 | the parser rebuilds an expression by joining tokens with spaces, so `var.tags` arrives as `var . tags` and every reference pattern missed. Made whitespace-tolerant: 37 of the 40 missing edges went |

Final: **31 differences, and they are not 31 defects.** See below.

## functional-tf: 6 / 7

Scored by the seven named cases in `evals/tf/fixture/cases.md`, because a raw
difference count answers the wrong question — 28 of the 31 remaining
differences are one mechanism repeated.

| Case | Result |
| --- | --- |
| 1 nested-module chain, three levels | PASS |
| 2 cross-repository source (`git::` with a `//subdir`) | PASS |
| 3 cross-repository output reference | **FAIL** |
| 4 provider version pin | PASS |
| 5 variable → local → module → nested module | PASS |
| 6 unused variable, the absence case | PASS |
| 7 unresolved module source | PASS |

### The 31 remaining differences, by mechanism

**28 × `WrongAttribute`, all `hasValidation`.** The oracle omits the field where
a variable has no validation block; the producer writes `hasValidation: false`
explicitly. Absent versus false. This is a **convention mismatch between the
oracle and the producer, not 28 defects** — and the fixture is frozen, so it is
reported rather than reconciled. Whichever way it is settled, it should be
settled once and written into the contract: the producer contract says an absent
optional field means NOT STATED, which argues the oracle is right and the
producer should omit it.

**2 × `MissingEdge`, case 3.** `TfFixtureNetwork:.#output.segment_id →
TfFixtureApp:.#var.network_segment_id` and its `subnet_ids` twin. **These are
not mechanically derivable from the configuration.** The fixture ties them
together in a variable's *description* — prose — and nothing in the HCL says
that `var.network_segment_id` receives that output. A producer could only find
them by reading English. This is a defect in the oracle's case 3, not in the
producer: the case as written cannot be passed by any parser, and it is the one
case that made the fixture worth building across three repositories. Recorded as
a finding; the fixture is frozen and was not edited.

**1 × `MissingEdge`, splat syntax.**
`TfFixtureNetwork:modules/segment/modules/subnet#output.id →
…segment#output.subnet_ids`. The expression is `module.subnet[*].id`, and the
reference extractor's pattern captures `module.<name>.<member>` without handling
the `[*]` splat between them. **A genuine producer gap**, one line to fix, left
because the iteration cap was reached.

## Artifacts

| File | What |
| --- | --- |
| `graph.json` | the produced graph: 78 nodes, 54 edges |
| `tf-foundation.html` | 675,616 bytes |
| `tf-testorder.html` | 675,615 bytes |
| `tf-callflow.html` | 675,614 bytes |
| `findings.md` | what this run found, by mechanism |

Every render carries its own `DefaultFlow` marker and a `vscode://file/` link.
The three were produced concurrently, one ThreadJob per layout.

## Wall-clock and parallelism

Roughly 55 minutes for the build, three scoring iterations, the renders and the
records. Degree of parallelism: **3** for the render group (one job per layout);
**1** everywhere else — the parser, the assembler and the scoring iterations are
inherently serial, each depending on the previous answer.

## What this run does not measure

The oracle was visible throughout and was iterated against three times. That
makes this a deliverable build and **not** a measurement of whether the plugin
helps an agent build a module it has not seen the answers to. Line 1's
generalisation claim needs its own run, against an oracle the builder cannot
read.
