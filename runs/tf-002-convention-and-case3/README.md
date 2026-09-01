# Run tf-002 — the convention, and case 3 made mechanical

The second entry in the `tf-NNN` ledger. It re-scores PSTerraformGraph against
the fixture after decision 0012 repaired case 3 and after two producer defects
tf-001 recorded but could not fix inside its iteration cap.

```
plugin-sha:     5ac73ba2b1ddf2dda3f39d510cd3743350354fb8
target-sha:     1dd491335f8347f3985b4a5313b0e60a3b406bd9  (tag v0.2.0)
model-version:  claude-opus-5[1m]
build:          exit 0
module tests:   41 passed, 0 failed, line coverage 83.56% (target 70%)
battery:        7 / 7
functional-tf:  7 / 7
differences:    0
```

**Still not the generalisation measurement.** The oracle was visible, and this
pass amended it. tf-002 is a deliverable build and a regression check on two
named defects; the blind, measured run is tf-003 and is not yet scheduled.

### On `model-version` and the Claude Code version

`model-version` is the model that executed the pass. The **Claude Code version
is not recorded, because it was not observable from inside the session**:
`claude --version` is not on the PATH the session can reach and
`$env:CLAUDE_CODE_VERSION` is empty. What is observable is
`$env:CLAUDE_CODE_ENTRYPOINT = claude-vscode`, and that is recorded instead of a
guess. This is the same rule the plan protocol applies to token counts — a field
the agent cannot measure is a field it invents — and it wants fixing at the host
end rather than in the record.

## What changed since tf-001

| | tf-001 | tf-002 |
| --- | --- | --- |
| differences | 31 | **0** |
| functional-tf | 6 / 7 | **7 / 7** |
| oracle | 78 nodes, 57 edges | 78 nodes, **59** edges |
| module tests | 33 | 41 |
| coverage | 83.40% | 83.56% |

Three things moved, and they are three different kinds of thing.

**1. Case 3 became passable (fixture, decision 0012).** tf-001 found that case
3's cross-repository tie existed only in a variable's *description* — prose. No
parser can read it, so the case was not hard but impossible, and it was the one
case the three-repository fixture was built for. Decision 0012 authorised the
single amendment decision 0011 provides for: `TfFixtureApp` gained a
`module "network"` block sourcing TfFixtureNetwork's root by `git::` URL, and
the two prose-tied variables became two locals reading that module's outputs.
2 of tf-001's 31 differences.

**2. The `hasValidation` convention was settled in the producer.** The oracle
omits the field where a variable has no `validation` block; the producer wrote
`hasValidation: false`. The producer contract says an absent optional field
means NOT STATED, so the oracle was right and the producer now omits it.
**28 of tf-001's 31 differences — one convention, never 28 defects.**

`hasDefault` is deliberately *not* treated the same way and is still written as
an explicit `false`. "This variable is required" is a positive fact about the
configuration; "nothing validates it" is the absence of one. The oracle draws
the same line, and the asymmetry is worth knowing about rather than tidying
away.

**3. The 31st difference was named and fixed.** tf-001's record accounted for
28 + 2 and left one more. Re-running `Compare-TfGraph` against the committed
tf-001 graph named it:

    MissingEdge  TfFixtureNetwork:modules/segment/modules/subnet#output.id
              -> TfFixtureNetwork:modules/segment#output.subnet_ids   kind=references

The expression is `module.subnet[*].id`. The reference extractor captured
`module.<name>` and then required the dot immediately, so the **member** came
back empty, the reference resolved to no output, and the edge was dropped in
silence. A producer defect, one pattern, and the fixture was right about it.

The silence is the part worth keeping: the reference still *matched*, so nothing
looked broken. A pattern that half-matches is worse than one that does not
match at all.

## What it was scored against

| | |
| --- | --- |
| Fixture | `evals/tf/fixture/`, amended once under decision 0012 and re-frozen |
| Oracle | `evals/tf/fixture/expected-graph.json` — 78 nodes, 59 edges, hand-authored |
| Comparator | `evals/tf/Compare-TfGraph.ps1`, re-falsified 7/7 against the amended oracle |

Fixture clones, taken fresh from AzDO, three concurrent:

| Repository | Commit | |
| --- | --- | --- |
| TfFixtureShared | `0af6ee33854bedb4147d0b13cc6db1311687775b` | unchanged |
| TfFixtureNetwork | `24f27be92e583b6dfc9208bca42f8ec0baf5004b` | unchanged |
| TfFixtureApp | `44ea9338ff35aef328bfa8d51835fc32bea590dd` | amended |

Byte read-back before scoring: `BYTE-IDENTICAL`, 40 files across 3
repositories. Azure DevOps objects created or modified: **1 commit on
TfFixtureApp**, authorised by decision 0012. Builds queued: **0**.

## Iterations

**None.** The pass allowed up to three; the first score was 0 differences and
there was nothing to iterate towards.

Everything here was regenerated once after the fact, and for a reason worth
recording: the first `graph.json` carried `producerVersion: 0.1.0`, because it
was produced before the manifest was bumped. The score was identical, but an
artifact stating a version the record does not claim is the kind of small
disagreement that later reads as a mystery. The graph, the diff, the case
score, the battery and all three renders were re-derived from the tagged v0.2.0
build. The two producer fixes were written
red-first against unit tests before the fixture was ever regenerated, so the
scoring run was a check rather than a search — which is the difference between
this run and tf-001, where three iterations were spent discovering what the
parser had got wrong.

That also means this run tests less than tf-001 did. A score reached without
iterating proves the fixes were right; it does not prove the harness would have
caught them if they were not. The falsification of the comparator is what
carries that claim, and it was re-run against the amended oracle: 7/7, control
at zero.

## functional-tf: 7 / 7

Scored by `evals/tf/Test-TfFixtureCase.ps1` against the seven named cases in
`evals/tf/fixture/cases.md`, each checked by its own assertions over the
produced graph rather than inferred from the difference count being zero. Those
are different claims, and collapsing them would lose the ability to say *which*
case failed.

The scorer is committed rather than run from a shell, and it discriminates: the
same script scores **6 / 7 against run tf-001's committed graph**, failing
exactly case 3. A case scorer that has only ever agreed with a passing graph is
indistinguishable from one that cannot disagree.

| Case | Result |
| --- | --- |
| 1 nested-module chain, three levels | PASS |
| 2 cross-repository source (`git::` with a `//subdir`) | PASS |
| 3 cross-repository output reference | **PASS** — was FAIL |
| 4 provider version pin | PASS |
| 5 variable → local → module → nested module | PASS |
| 6 unused variable, the absence case | PASS |
| 7 unresolved module source | PASS |

Case 3 now also exercises a `git::` source with **no** `//subdirectory`, which
is what names a repository's root module. Case 2 exercises only the
subdirectory form, and a resolver that requires one would pass case 2 and fail
case 3. `Resolve-TfModuleSource` already handled it — the `//` search returns
-1 and the subpath falls back to `.` — so this was capability the producer had
and the fixture had never asked for.

## battery: 7 / 7

`PSGraphRenderToHtml/tests/ProducerContract.Battery.ps1` against this run's
`graph.json`. All seven, including the one that earns its keep — that the graph
maps to a view model **PSGraphRender accepts** (contract 1.1.0), not merely one
that satisfies the producer contract.

## Artifacts

| File | What |
| --- | --- |
| `graph.json` | the produced graph: 78 nodes, 59 edges, `producerVersion` 0.2.0 |
| `diff.txt` | `Compare-TfGraph` output, verbatim: `No differences.` |
| `cases.txt` | `Test-TfFixtureCase` output, verbatim: 7 / 7 |
| `tf-foundation.html` | 675,182 bytes |
| `tf-testorder.html` | 675,181 bytes |
| `tf-callflow.html` | 675,180 bytes |

Each render carries its own `"DefaultFlow": "<layout>"` and **74**
`vscode://file/` links — one per node that names a file, which is every node but
the three repository nodes and the unresolvable `legacy` module target
(78 − 4 = 74). They resolve to 37 distinct targets: 28 `.tf` files, and the 9
module directories that are the 10 module nodes less the unresolvable one.

A raw `grep` for `vscode://file/` returns 77, not 74: three of them are inside
the renderer's own JavaScript and its comments, and are not links. The
difference is small and is stated because a count taken the easy way was the
first number written here. The three were produced concurrently, one ThreadJob
per layout.

## Wall-clock and parallelism

Degree of parallelism: **3** for the fixture clones, **3** for the renders,
**1** everywhere else. The parser, the comparison and the case scoring are
serial by nature — each depends on the previous answer.

## What this run does not measure

The same caveat tf-001 carried, and one more.

The oracle was visible throughout, and this pass **amended** it. A run that
changes the oracle and then scores against it cannot be read as evidence about
the producer alone; what protects the number here is that the amendment is
written down in decision 0012 before the fact, the comparator was re-falsified
against the amended oracle, and the two producer fixes were driven by unit
tests that never mention the fixture.

Line 1's generalisation claim still needs its own run against an oracle the
builder cannot read. That is tf-003, and it is not yet scheduled.
