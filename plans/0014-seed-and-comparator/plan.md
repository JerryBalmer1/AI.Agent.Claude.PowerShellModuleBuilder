# Pass 0014 — The seed, and the graph comparator

Tier: **full** (creates executable scripts and an acceptance suite).

## 1. Prompt

```
# PASS 0014 — The seed, and the graph comparator

Tier: full

Two artifacts the baseline run needs and does not have: the exact clean slate a
run starts from, and the tool that scores a produced graph against the declared
one. Neither the module nor the baseline run happens this pass.

Correction to record, mine: my claim that the committed PAT scan could not match
an 84-character token was asserted from memory and was wrong — the pattern is
unanchored. You measured it. That is rule 8, observed versus inferred, and I
broke it in a prompt about a check unable to fail. Note it in the journal's
Learned field, attributed to the prompt rather than the pass.

## Preconditions

Any failure is a hard stop — commit nothing, create nothing, report.

- [ ] On a pass branch, not `main`. Report branch and HEAD.
- [ ] Working tree clean. If dirty with a change this pass did not make, apply
      the standing rule: commit it alone first, naming it unrelated.
- [ ] `Fixture.Tests.ps1` green at 352 and `ReadBack.Tests.ps1` green at 76.
      Report both counts. ReadBack needs `$env:AZDO_PAT`; if unset, stop.
- [ ] `expected-graph.json`, `fixture/cases.md`, `runs/Render-Graph.ps1` exist.
- [ ] `pwsh --version`, resolved Pester 6.x, OS.

## Acceptance test — red first

Write `evals/functional/Compare.Tests.ps1` before writing the comparator, and
run it. It must be red. Record the red with failure messages.

It tests the comparator, not the fixture. Given `expected-graph.json` and a
candidate graph, `Compare-Graph.ps1` must report every difference and must
report none when the graphs agree.

1. A graph compared against itself reports zero differences and exits 0.
2. For each of the twelve cases, a deliberately wrong graph built to fail that
   case is reported as differing, and the report names the case. The wrong
   graphs are generated from `expected-graph.json` by the mutations in task 2,
   not authored by hand.
3. The comparator is order-insensitive: shuffling nodes and edges changes
   nothing.
4. The comparator distinguishes a missing edge, an extra edge, and an edge whose
   `to` resolves to the wrong node. Reporting all three as "differs" is not
   enough — a wrong resolution target is the failure case 1 and case 4 exist to
   catch, and it must be nameable.
5. Comparison is on graph content only. `cases` tags, ordering, and any field a
   module cannot know are excluded, and the exclusion list is explicit in the
   script rather than implied.

## Plan

- [ ] **1.** Write the acceptance test. Run it. Record the red.

- [ ] **2.** Write `evals/functional/Mutate-Graph.ps1`: given
      `expected-graph.json` and a case id, emit the graph a naive implementation
      failing that case would produce. One mutation per case, derived from the
      *How a naive implementation fails* section already in `cases.md` — not
      invented here. Examples of the shape, not a specification:

      - case-01: repoint the `template` edge out of `p01.yml` at the root-level
        `templates/steps-build.yml` instead of `pipelines/templates/`
      - case-02: drop every edge below depth 1 from the chain
      - case-07: duplicate the shared diamond node once per inbound path
      - case-08: expand the cycle into a tree by following it twice
      - case-09: delete both `unresolved` edges
      - case-10: remove the isolated `p10-orphan` node
      - case-12: add a `repo:ClaudeTesting` node

      Where a case's naive failure cannot be expressed as a graph mutation, say
      so and say why rather than inventing one. That is a finding about the
      case, not about the tool.

- [ ] **3.** Write `evals/functional/Compare-Graph.ps1`. Takes an expected graph
      and a candidate, emits a structured difference report as JSON plus a
      human-readable summary, exits 0 on agreement and non-zero otherwise.

      - Order-insensitive on both nodes and edges.
      - Reports differences by kind: missing node, extra node, missing edge,
        extra edge, wrong edge target, wrong node kind.
      - Names the affected case ids by looking up the tags on the expected side,
        so a report says which of the twelve a candidate failed.
      - Never modifies either input.
      - Excludes from comparison anything a module cannot know, listed
        explicitly in the script with a one-line reason each.

- [ ] **4.** Run the acceptance test. Record it green. Report the per-case
      results from assertion 2 as a table: case, mutation applied, differences
      reported, case named in the report.

- [ ] **5.** Falsify the comparator itself, not just the assertions. At minimum:
      - break the comparator so it ignores edge targets → assertion 4 red
      - break it so it compares by index rather than identity → assertion 3 red
      - a scope control: add a `cases` tag to the candidate → must stay green,
        because tags are excluded
      Each probe asserts it changed the file before the check runs.

- [ ] **6.** Create `evals/functional/seed/` — the exact clean slate a baseline
      run starts from. Nothing more than a repository would legitimately have
      before any work: `README.md`, `LICENSE`, `.gitignore`, `.gitattributes`
      carrying the same line-ending rules as this repository. No build file, no
      manifest, no source tree, no tests. The seed is what the run is measured
      *from*, so anything in it is a head start the score will not attribute.

      Write `evals/functional/seed/README.md` in the seed stating what the
      repository is meant to become, at the level a human would write before
      starting — not the brief, which is the specification, and not the
      conventions, which are what the plugin is supposed to supply.

- [ ] **7.** Write `evals/functional/Reset-Target.ps1`: materialises the seed
      into a run directory, `git init`, one commit. Refuses to run against any
      path not under `scratch/runs/`. Refuses if the destination exists and is
      non-empty unless `-Force`. This is the wipe half of wipe-and-rebuild and
      it never touches the real PSAzureDevOpsGraph repository — that receives
      only a promoted run, by hand, later.

- [ ] **8.** Record the two decisions from Pass 0013.

      `decisions/0004-plan-artifacts-are-frozen.md`: a plan and its verify
      script are valid against the commit that pass pushed, and are not
      maintained forward. Running a verify script against a later HEAD is a
      category error, and updating pinned numbers as the suite grows is a
      treadmill that lengthens with every pass. Each verify script records the
      SHA it was written against and reports plainly when HEAD differs rather
      than being edited. Record what was rejected: maintaining them forward, and
      removing the pins.

      Then apply it: add the SHA-and-warn to `plans/0013/verify.ps1`, and note in
      `plans/0011` and `plans/0012` verify scripts that they were edited in
      0013 before this rule existed.

      `evals/HARNESS.md` hazard 8: matching a phrase in hard-wrapped prose
      fails when the phrase spans a line break, and it recurred inside the
      falsification of its own fix. Every phrase check runs against a
      whitespace-collapsed copy, and a phrase check returning zero matches for
      text known to be present is a defect in the check, not evidence about the
      file.

- [ ] **9.** Commit and push to the pass branch. Report the pushed SHA.

## Named spot-checks

`verify.ps1` must independently re-derive, by name:

1. `Fixture.Tests.ps1` and `ReadBack.Tests.ps1` at their full case counts.
2. `Compare-Graph.ps1` against `expected-graph.json` compared with itself:
   zero differences, exit 0.
3. Three named case mutations — case-01, case-08, case-12 — each producing a
   difference report that names that case. Re-run the mutation, do not read
   task 4's output.
4. That the seed contains no build file, no manifest, no `src/`, and no
   `tests/`. A seed that has grown a head start is the failure this check
   exists for.
5. That `Reset-Target.ps1` refuses a destination outside `scratch/runs/`.
6. No PAT-shaped string under the corrected pattern, in any tracked file or
   anywhere under `runs/`.

Record the SHA this verify script was written against, per decision 0004, and
report when HEAD differs.

## Constraints

No network calls except `ReadBack.Tests.ps1` in the preconditions. No Azure
DevOps resource created, modified, or deleted. Nothing queued. The fixture is
not re-pushed and `Sync-Fixture.ps1` is not run.

`expected-graph.json` is not modified. Mutations are written to `scratch/` and
never committed. No fixture YAML changes. The real PSAzureDevOpsGraph repository
is not touched.

Push to the pass branch. No tags, no `main`, nothing published.

## Deviations

Required. Flag specifically: any case whose naive failure cannot be expressed as
a graph mutation, and why — that is a finding about the case's discriminating
power. Also flag anything in the seed you think is a head start.

## Journal

Write `journal/0014-seed-and-comparator.md` from this pass's artifacts. Include
the PAT-scan correction in Learned, attributed to the prompt. Capability only.

## Report back

Branch and pushed SHA; the plan path; red-first and green output for
`Compare.Tests.ps1`; the per-case mutation table from task 4; the three
comparator falsification results from task 5; the seed's file list; and any case
whose naive failure could not be expressed as a mutation.
```

## 2. Preconditions

All passed. The working tree was clean, so the standing rule from Pass 0013 did
not need to be applied.

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | On a pass branch | `git rev-parse --abbrev-ref HEAD` / `git rev-parse HEAD` | **pass** — `pass-0009-control-polarity` @ `82eae2da2f2040751dc95939c415f490b2dfedad` |
| 2 | Working tree clean | `git status --porcelain` | **pass** — empty |
| 3 | Both suites green | `Invoke-Pester` on each | **pass** — `Fixture.Tests.ps1` **352/352**, `ReadBack.Tests.ps1` **76/76**, 0 failed, 0 skipped |
| 4 | Three files exist | `test -f` each | **pass** — `expected-graph.json` 19,474 B; `fixture/cases.md` 15,806 B; `runs/Render-Graph.ps1` 14,973 B |
| 5 | pwsh / Pester / OS | `$PSVersionTable`, `Import-Module Pester` | **pass** — pwsh 7.6.5; Pester **6.1.0** resolved; Windows NT 10.0.26200.0 |

`$env:AZDO_PAT` was set (length 84), so precondition 3's ReadBack half ran
rather than stopping the pass.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 (resolved) |
| OS | Microsoft Windows NT 10.0.26200.0 |
| git | 2.41.0.windows.1 |
| Claude Code | not resolvable from the session shell; not guessed |
| Branch | `pass-0009-control-polarity` |
| HEAD at start | `82eae2da2f2040751dc95939c415f490b2dfedad` |

## 4. Acceptance test — red first

`evals/functional/Compare.Tests.ps1` was written and run **before**
`Compare-Graph.ps1` or `Mutate-Graph.ps1` existed.

```
==========================================
RED-FIRST RESULT
TOTAL=28 PASSED=1 FAILED=27 SKIPPED=0
==========================================
    0 passed   3 failed  Assertion 1: a graph compared against itself reports zero differences
    0 passed  13 failed  Assertion 2: each case has a wrong graph that is detected and named
    0 passed   1 failed  Assertion 3: the comparator is order-insensitive
    0 passed   5 failed  Assertion 4: missing, extra and wrong-target edges are distinguishable
    0 passed   5 failed  Assertion 5: comparison is on graph content only
    1 passed   0 failed  The comparator never modifies its inputs
------ first failure per context ------
### Assertion 1: a graph compared against itself reports zero differences
    test: the comparator script exists
    Expected $true, because Compare-Graph.ps1 is the subject of this suite, but got $false.
### Assertion 2: each case has a wrong graph that is detected and named
    test: the mutator script exists
    Expected $true, because wrong graphs are generated, never hand-authored, but got $false.
### Assertion 3: the comparator is order-insensitive
    test: shuffling nodes and edges changes nothing
    Expected 0, because nodes and edges are sets, not sequences, but got $null.
### Assertion 4: missing, extra and wrong-target edges are distinguishable
    test: a missing edge is reported as missingEdge
    Expected the actual value to be greater than 0, but got $null.
### Assertion 5: comparison is on graph content only
    test: the report declares its exclusion list
    Expected a value, but got $null or empty.
```

Assertion 2 discovered **13** tests: one "the mutator script exists" plus the
twelve cases parsed from `cases.md`, confirming the case list is read from the
document rather than hard-coded.

**The one passing test** is *"expected-graph.json is byte-identical after every
comparison above"*. It passed because nothing had run and so nothing could have
modified the oracle. That is the correct behaviour for an invariant guard — it
asserts something that must be true before, during and after — and it is the
same shape as Pass 0013's assertion 8. A guard that went red here would mean the
oracle was already wrong.

## 5. Tasks

### [x] 1. Write the acceptance test, run it, record the red

Recorded in §4. 28 assertions across the five declared groups plus the
inputs-unmodified guard.

### [x] 2. `Mutate-Graph.ps1`

One mutation per case. Each carries the sentence from that case's *How a naive
implementation fails* paragraph that it was derived from, so a reader can check
the derivation without trusting the author.

```
Case    Expect                                 Mutation
----    ------                                 --------
case-01 wrongEdgeTarget                        Repoint p01's template edge at the repo-root templates/steps-build.yml
case-02 missingEdge, missingNode               Drop every chain edge below depth 1, and the node only reachable through them
case-03 wrongEdgeKind                          Report p03's extends edge as kind template
case-04 wrongEdgeTarget, extraNode, missingNode Resolve common.yml's relative reference into pipelines-main
case-05 wrongEdgeKind                          Flatten p05's pipelineResource edge into the template kind
case-06 missingEdge, missingNode               Drop p06's variables-block template edge and the node it discovers
case-07 extraNode, wrongEdgeTarget, extraEdge  Duplicate the shared diamond node and its leaf, once per inbound path
case-08 missingEdge                            Drop the edge that closes the cycle, leaving a tree
case-09 missingEdge                            Delete both unresolved edges
case-10 missingNode, missingEdge               Remove the orphan pipeline, its YAML node, and the definition edge
case-11 wrongEdgeKind                          Collapse the checkout edge into the template kind
case-12 extraNode                              Add a repo:ClaudeTesting node
```

Node and edge counts of each generated graph, against the oracle's 49 / 51:

```
case-01: nodes=49 edges=51      case-07: nodes=51 edges=52
case-02: nodes=48 edges=49      case-08: nodes=49 edges=50
case-03: nodes=49 edges=51      case-09: nodes=49 edges=49
case-04: nodes=49 edges=51      case-10: nodes=47 edges=50
case-05: nodes=49 edges=51      case-11: nodes=49 edges=51
case-06: nodes=48 edges=50      case-12: nodes=50 edges=51
```

case-10 produces exactly the 47 nodes its *A wrong answer* paragraph predicts.

Two judgement calls, both recorded in Deviations: case-02 removes `chain-b` but
keeps `chain-c` (p05 references it at depth 1, so a depth-1 walk still finds
it), and the script refuses to emit a mutation whose output equals the oracle.

### [x] 3. `Compare-Graph.ps1`

Staged edge matching, so a repointed edge is one `wrongEdgeTarget` rather than a
missing-plus-extra pair:

1. exact — same `from`, `to`, `kind`, `ref`
2. same `from`, `kind`, `ref`, different `to` → `wrongEdgeTarget`
3. same `from`, `to`, `ref`, different `kind` → `wrongEdgeKind`
4. what remains → `missingEdge` / `extraEdge`

Difference kinds emitted: `missingNode`, `extraNode`, `wrongNodeKind`,
`wrongNodeAttribute`, `missingEdge`, `extraEdge`, `wrongEdgeTarget`,
`wrongEdgeKind`, `wrongEdgeAttribute`, `metadata`.

Exclusions, explicit in the script and echoed into every report:

| Field | Reason |
|---|---|
| `cases` | An oracle annotation. A module has never read `cases.md`. |
| `note` | Human prose. Carries no graph content. |
| `generatedBy` | Absent from the oracle by design, per `graph.schema.json`. |
| *(array order)* | Nodes and edges are sets. |

### [x] 4. Acceptance test green, and the per-case table

```
TOTAL=28 PASSED=28 FAILED=0
    3 passed   0 failed  Assertion 1: a graph compared against itself reports zero differences
   13 passed   0 failed  Assertion 2: each case has a wrong graph that is detected and named
    1 passed   0 failed  Assertion 3: the comparator is order-insensitive
    5 passed   0 failed  Assertion 4: missing, extra and wrong-target edges are distinguishable
    5 passed   0 failed  Assertion 5: comparison is on graph content only
    1 passed   0 failed  The comparator never modifies its inputs
```

Per-case results from assertion 2, regenerated for the table:

```
Case    Diffs Exit Kinds                                       Named AllCases
----    ----- ---- -----                                       ----- --------
case-01     1    1 wrongEdgeTarget=1                           YES   case-01
case-02     3    1 missingEdge=2 missingNode=1                 YES   case-02
case-03     1    1 wrongEdgeKind=1                             YES   case-03
case-04     3    1 extraNode=1 missingNode=1 wrongEdgeTarget=1 YES   case-04
case-05     1    1 wrongEdgeKind=1                             YES   case-05
case-06     2    1 missingEdge=1 missingNode=1                 YES   case-06
case-07     4    1 extraEdge=1 extraNode=2 wrongEdgeTarget=1   YES   case-07
case-08     1    1 missingEdge=1                               YES   case-08
case-09     2    1 missingEdge=2                               YES   case-09
case-10     3    1 missingEdge=1 missingNode=2                 YES   case-10
case-11     1    1 wrongEdgeKind=1                             YES   case-11
case-12     1    1 extraNode=1                                 YES   case-12
```

Every case names **itself and nothing else**. No mutation bleeds into another
case's tags, which would have made the naming useless.

### [x] 5. Falsifying the comparator itself

Each probe asserted the file changed — by SHA-256 before and after — before the
check ran.

**Probe 1 — ignore edge targets** (drop `$e.to -ceq $a.to` from stage 1):

```
PROBE ASSERT file changed: 14dc56ad7b79 -> 212ef174b60e CHANGED
TOTAL=28 PASSED=23 FAILED=5
    3 failed  Assertion 4: missing, extra and wrong-target edges are distinguishable
    2 failed  Assertion 2: each case has a wrong graph that is detected and named
--- failing tests ---
  case-01 has a generated wrong graph that differs and is named in the report
  case-07 has a generated wrong graph that differs and is named in the report
  a target edge is reported as wrongEdgeTarget
  a wrong edge target is not reported as a missing-plus-extra pair
  the wrong-target report names both the expected and the actual target
```

Assertion 4 went red as designed. Unplanned and useful: assertion 2 went red for
exactly case-01 and case-07 — the two whose mutation is a repointed edge. The
per-case assertions are a second, independent detector of the same defect.

**Probe 2 — compare by index rather than identity** (key nodes by position):

```
PROBE ASSERT file changed: 14dc56ad7b79 -> c3e10afe67ee CHANGED
TOTAL=28 PASSED=27 FAILED=1
    1 failed  Assertion 3: the comparator is order-insensitive
--- failing tests ---
  shuffling nodes and edges changes nothing
```

Exactly one test, precisely the targeted one.

**Probe 3 — scope control, a `cases` tag added to the candidate:**

```
PROBE ASSERT: candidate now carries an invented tag: case-99
exit code       : 0
differenceCount : 0
RESULT          : GREEN - tags are excluded, as claimed
```

**Control on the control** (not asked for; added because a green scope control
proves nothing if the comparator is simply blind). Adding `cases` to the
compared attribute list:

```
PROBE ASSERT file changed: 14dc56ad7b79 -> 1d7ad89c5706 CHANGED
exit code       : 1
differenceCount : 1
RESULT          : RED - the exclusion is load-bearing; probe 3 green was a real exclusion, not blindness
```

`Compare-Graph.ps1` was restored with `git checkout --` after each probe and the
tree confirmed clean.

### [x] 6. The seed

```
evals/functional/seed/
    .gitattributes     579 bytes, CR=0
    .gitignore         359 bytes, CR=0
    LICENSE           1069 bytes, CR=0
    README.md
```

Four files. No build file, no manifest, no source tree, no tests — asserted by
`verify.ps1` check 4 and falsified by its `-FailCheck seed` probe.

`.gitattributes` carries the same `eol=lf` rules as this repository, for the
reason stated in the file: a run producing different bytes from the same source
because of where it was checked out would not be comparable.

`README.md` is written as a human would write it before starting — the problem,
what they want, two constraints they already know about, and "nothing built
yet". It contains no command surface, no module layout, and no conventions.
Anything debatable is in Deviations.

### [x] 7. `Reset-Target.ps1`

Materialises the seed, `git init --initial-branch=main`, one commit with a local
identity so it does not depend on global git config.

```
=== 1. legitimate reset ===
  files copied: 4
  commit      : a82c00970ad2b2b8365e8ca8553d26d9c7865e6e
  tracked     : 4 files
                .gitattributes / .gitignore / LICENSE / README.md

=== 2. refuses a path outside scratch/runs/ ===
  Refusing to reset '../PSAzureDevOpsGraph'.

=== 3. refuses traversal that escapes via .. ===
  Refusing to reset 'scratch/runs/../../../PSAzureDevOpsGraph'.

=== 4. refuses non-empty destination without -Force ===
  Refusing to reset 'scratch/runs/000-seed-check': it exists and is not empty (5 entries).

=== 5. -Force replaces it ===
  replacing existing destination (5 entries)
  files copied: 4
```

Case 3 is the one that matters. The guard compares **resolved** paths, not
strings: a prefix test on the raw text would accept
`scratch/runs/../../../PSAzureDevOpsGraph`, which is exactly the mistyped path
the guard exists to stop.

### [x] 8. The two decisions

`decisions/0004-plan-artifacts-are-frozen.md` — written, with both rejected
alternatives recorded (maintaining pins forward; removing the pins), plus a
third considered and rejected (deleting old verify scripts).

Applied:

- `plans/0013-create-fixture/verify.ps1` carries `$WrittenAgainstSha` and the
  HEAD-differs notice. Confirmed firing:

```
NOTE: the repository has moved since this script was written.
  written against : 82eae2da2f2040751dc95939c415f490b2dfedad
  current HEAD    : d82a1ae39aae96bdc58ccbbbc27c3e8030880a39
  Any disagreement below may be the repository having moved on rather
  than Pass 0013 having been wrong. See decisions/0004-plan-artifacts-are-frozen.md.
```

  It still runs and still exits non-zero on disagreement — the notice changes
  how a red is read, not whether one happens.

- `plans/0011-*/verify.ps1` and `plans/0012-*/verify.ps1` carry a header note
  recording that Pass 0013 edited them before this rule existed, and that the
  originals are in the history. They are **not** reverted; reverting would make
  them red for a reason decision 0004 says is not a fault.

`evals/HARNESS.md` hazard 8 already existed from Pass 0013. Extended with the
diagnostic rule this prompt supplies — *a phrase check returning zero matches for
text known to be present is a defect in the check, not evidence about the file*
— stated as an instruction rather than an observation, because the hazard
recurred inside the falsification of its own fix.

### [x] 9. Commit and push

§7 and the transcript.

## 6. Acceptance test — green

```
TOTAL=28 PASSED=28 FAILED=0 SKIPPED=0
```

Per-assertion counts and the per-case table are in task 4.

**What this proves.** That the comparator detects the differences it is given,
including one deliberately generated per declared case. **What it does not
prove.** That `expected-graph.json` is a correct oracle. A candidate agreeing
with a wrong oracle scores perfectly and nothing here can tell. The oracle is
hand-authored, was not modified this pass, and is not confirmed by any of this.

## 7. Command transcript

```powershell
# --- preconditions -------------------------------------------------------
git rev-parse --abbrev-ref HEAD; git rev-parse HEAD; git status --porcelain
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/Fixture.Tests.ps1'    # 352/352
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/ReadBack.Tests.ps1'   # 76/76

# --- task 1: acceptance test, red first ----------------------------------
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/Compare.Tests.ps1'    # 28: 1 passed, 27 failed

# --- task 2: mutator ------------------------------------------------------
pwsh -NoProfile -File evals/functional/Mutate-Graph.ps1 -List
for c in 01..12: pwsh -NoProfile -File evals/functional/Mutate-Graph.ps1 `
                   -CaseId case-$c -OutputPath scratch/0014-compare/gen-case-$c.json

# --- tasks 3, 4: comparator and green -------------------------------------
pwsh -NoProfile -File evals/functional/Compare-Graph.ps1 `
    -CandidatePath evals/functional/fixture/expected-graph.json               # 0 differences, exit 0
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/Compare.Tests.ps1'    # 28/28

git add -A; git commit -F -                                                    # d82a1ae

# --- task 5: falsifying the comparator ------------------------------------
# probe 1: drop the `to` test from stage 1 -> 28: 23 passed, 5 failed; git checkout --
# probe 2: key nodes by position           -> 28: 27 passed, 1 failed; git checkout --
# probe 3: cases tag on candidate          -> 0 differences, exit 0 (control, stays green)
# control on the control: compare `cases`  -> 1 difference,  exit 1; git checkout --

# --- tasks 6, 7: seed and reset -------------------------------------------
pwsh -NoProfile -File evals/functional/Reset-Target.ps1 -Destination scratch/runs/000-seed-check
pwsh -NoProfile -File evals/functional/Reset-Target.ps1 -Destination ../PSAzureDevOpsGraph   # refused
pwsh -NoProfile -File evals/functional/Reset-Target.ps1 -Destination 'scratch/runs/../../../PSAzureDevOpsGraph'  # refused
pwsh -NoProfile -File evals/functional/Reset-Target.ps1 -Destination scratch/runs/000-seed-check -Force

# --- task 8 + verify ------------------------------------------------------
pwsh -NoProfile -File plans/0013-create-fixture/verify.ps1                      # HEAD-differs notice fires
pwsh -NoProfile -File plans/0014-seed-and-comparator/verify.ps1                 # exit 0, 0 skipped
pwsh -NoProfile -File plans/0014-seed-and-comparator/verify.ps1 -FailCheck seed       # exit 1
pwsh -NoProfile -File plans/0014-seed-and-comparator/verify.ps1 -FailCheck comparator # exit 1
pwsh -NoProfile -Command '$env:AZDO_PAT=$null; ./plans/0014-seed-and-comparator/verify.ps1'  # exit 0, 1 skipped

# --- constraint checks ----------------------------------------------------
git rev-parse 82eae2d:evals/functional/fixture/expected-graph.json             # bd7b3c4f... unchanged
git hash-object evals/functional/fixture/expected-graph.json                   # bd7b3c4f... unchanged
git diff --stat 82eae2d -- evals/functional/fixture/repos                      # empty
```

No command in this transcript echoes the PAT. **No redaction was necessary**, as
no command was run whose output could have contained it.

## 8. Diff summary

Not applicable — full tier.

## 9. Verify script

`plans/0014-seed-and-comparator/verify.ps1`, committed beside this plan and not
reproduced here: a second copy of an executable in the same commit can disagree
with the first, and nothing makes them agree again.

It re-derives the six named spot-checks. Check 3 **regenerates** the case-01,
case-08 and case-12 mutations rather than reading task 4's table, and asserts
each mutation actually changed the graph before comparing — a mutation that
mutated nothing would satisfy a comparator that reports nothing.

Only check 1's ReadBack half needs the network; without `$env:AZDO_PAT` it is
**skipped with a clear message** and everything else still runs.

Per decision 0004, it records the SHA it was written against and prints a notice
when HEAD differs.

**With `AZDO_PAT` set:** all checks agree, exit 0, 0 skipped.
**Without it:** exit 0, **1 skipped**, checks 2–6 still verified.

**Falsification, two probes, each asserting it changed something first:**

| Probe | Assertion that it changed something | Result |
|---|---|---|
| `-FailCheck seed` | `PROBE seed actually planted a manifest` — ok | `FAIL the seed contains no module manifest`, `FAIL the seed is exactly …`, **exit 1** |
| `-FailCheck comparator` | `PROBE comparator actually replaced the mutant` — ok | `FAIL case-12 is reported as differing`, `FAIL case-12 comparison exits non-zero`, `FAIL case-12 is named in the report`, **exit 1** |

Both probes clean up after themselves; the seed was confirmed back to its four
files afterwards.

Check 5 carries its own control: after asserting three disallowed destinations
are refused, it asserts an allowed one is **accepted**. Three refusals alone
would also be satisfied by a script that always fails.

## 10. Deviations

**1. Two cases have a naive failure that no graph mutation can express, and one
of them matters.**

- **case-08.** Its declared failure has two modes: *"By recursing without a
  visited set"* — a hang or a stack overflow — *"or by adding one and then
  dropping the edge that closes the cycle"*. The first produces **no graph at
  all**, so the comparator can never see it: there is nothing to compare. Only
  the second is expressible, and that is the mutation used. This is a real limit
  on case-08's discriminating power *as scored by this comparator*: an
  implementation that hangs fails the case by producing nothing, which a run
  harness must catch as a timeout, not something the comparator can report.
- **case-03 and case-11** each declare *two* wrong answers, and one mutation
  covers one. case-03: an `extends` edge reported as `template` (used), **or** a
  spurious fourth edge from the `parameters.buildTemplate` value. case-11: a
  `checkout` collapsed into `template` (used), **or** an invented `template` edge
  into `templates-shared`, **or** no edge at all. Both uncovered halves *are*
  expressible as mutations; the prompt asked for one per case, so they are not
  covered. A future pass wanting full coverage needs a mutation-per-wrong-answer
  scheme rather than mutation-per-case.

No case was untestable for lack of a mutation. Nothing was invented to fill a
gap.

**2. An absence case cannot be named by the mechanism the prompt specifies.**
Task 3 says to name cases "by looking up the tags on the expected side". Nothing
in `expected-graph.json` can carry case-12's tag — tagging a node with it would
assert the opposite of the case, which `cases.md` and `AZDO-FIXTURE.md` both say
explicitly. So the tag lookup has nothing to find and case-12 could never be
named. `Compare-Graph.ps1` therefore carries an explicit `$AbsenceCaseRules`
table, one entry, carrying the claim it comes from. Flagged because it is an
addition to the specified mechanism, not an implementation of it.

**3. `verify.ps1` makes a network call, which the Constraints section
disallows.** The constraint says "No network calls except `ReadBack.Tests.ps1`
in the preconditions", but named spot-check 1 requires `verify.ps1` to re-derive
`ReadBack.Tests.ps1` at its full case count, which reads Azure DevOps. The two
cannot both hold. Resolved in favour of the spot-check, since a verify script
that skipped half of check 1 unconditionally would be verifying less than the
prompt asked. The call is read-only; nothing is created, modified or queued.

**4. Hazard 8 already existed.** Task 8 asks for it as though new; Pass 0013
added it. Extended rather than duplicated, with the diagnostic rule this prompt
supplies, which was the part that was missing.

**5. A judgement call in the case-02 mutation.** The prompt's example says "drop
every edge below depth 1 from the chain". Dropping only edges leaves `chain-b`
as a node no depth-1 walk would ever discover, so the mutation also removes that
node. It does **not** remove `chain-c`, because `p05.yml` references it directly
at depth 1 and a depth-1 implementation still finds it. Recorded because it is a
choice about faithfulness that the prompt's one-line example did not settle.

**6. Things in the seed that could be argued as a head start.** Reviewed
deliberately, since the prompt asks:

- **`.gitattributes` with `eol=lf`.** The strongest candidate. A real developer
  starting fresh would probably *not* write this, and it encodes a lesson this
  project learned the hard way in Pass 0013. It is kept because the prompt
  requires it explicitly, and because without it a run's bytes depend on where it
  was checked out, which would make runs incomparable — but it is a head start,
  and it is the one I would remove if the criterion were strict realism.
- **The `.gitignore` credential patterns** (`*.pat`, `pat.txt`, `AzDoPAT.txt`).
  These hint that credentials are a concern. Mild; a security-conscious developer
  writes these on day one, and the comment says they exist to make a mistake
  harder rather than to support any supported mechanism.
- **`README.md` naming `$env:AZDO_PAT` and "read-only".** Both are genuine
  pre-work constraints a human would record, and both are in `BRIEF.md` too.
  Judged not a head start: they state *what* is required, not *how* to build
  anything.
- **The `output/` and `testResults/` ignores.** These name directories the
  plugin's conventions might choose. Weakest of the four, but a developer who has
  used PowerShell build tooling writes them reflexively.

Nothing else in the seed carries information about structure, layout,
conventions, or the command surface.

**7. `Reset-Target.ps1` sets a local git identity** (`-c user.name=… -c
user.email=…`) so the seed commit does not depend on global git config being set
on whichever machine runs it. Not asked for; without it the script fails on a
fresh machine with an unhelpful git error.

**8. The SHA recorded in this pass's `verify.ps1` cannot be its own commit.**
Decision 0004 requires each verify script to record the SHA it was written
against, but the SHA of a commit cannot be known before that commit exists. This
script records the SHA of the commit carrying the pass's **work**, written in by
its immediate child commit, and says so in the file. A one-commit difference
immediately after the pass is therefore expected and is not drift.

**9. The seed was byte-unstable across clones, and staging it is what revealed
that.** Three of the seed's four files - `.gitattributes`, `.gitignore` and
`LICENSE` - match none of the extension rules in the repository-root
`.gitattributes` (`*.yml`, `*.json`, `*.md`, `*.ps1`) and fell through to
`* text=auto`. With `core.autocrlf=true` at system scope, that means **CRLF on
any Windows clone**. Measured with `git check-attr text eol`:

```
.gitattributes   text: auto   eol: unspecified
.gitignore       text: auto   eol: unspecified
LICENSE          text: auto   eol: unspecified
README.md        text: set    eol: lf
```

Only the `.md` file was protected. This is the same defect Pass 0013 fixed for
the fixture, in a directory created after that fix, and it defeats the seed's
own stated purpose: `Reset-Target.ps1` copies bytes verbatim, so a run
materialised from a Windows clone would have started from different bytes than
one materialised here.

Fixed by adding to the root `.gitattributes`:

```
evals/functional/seed/** text eol=lf
.gitattributes text eol=lf
.gitignore     text eol=lf
```

After the fix all four seed files resolve to `eol: lf`, `git add` emits no CRLF
warning, and `Reset-Target.ps1` materialises all four with CR=0.

**How it surfaced, which is worth recording.** A `git stash`/`git stash pop` run
during an unrelated clone check round-tripped the working tree through a
checkout and converted the three unprotected files to CRLF in place. The
resulting `git add` warnings are what exposed the gap. **The fixture was
unaffected** - 0 CR bytes across all 30 files and 0 blob mismatches against
`82eae2d` - which is a live confirmation that Pass 0013's `eol=lf` rules protect
what they were built to protect. The files that moved were precisely the ones no
rule covered.

## 11. Cost

| | |
|---|---|
| Wall clock | ~1h 10m (`82eae2d` at 2026-08-28 23:04 −0700 to final commit) |
| `Compare.Tests.ps1` runs | 6 (1 red, 1 green, 3 probes, 1 confirmation) |
| `Fixture.Tests.ps1` runs | 4 |
| `ReadBack.Tests.ps1` runs | 3 |
| Mutations generated | 48 (12 ×2 for the table, 12 in the suite, 12 in verify runs) |
| Comparator invocations | ~70 across suite, table and verify |
| `verify.ps1` runs | 4 (1 full, 2 probes, 1 no-PAT) |
| `Reset-Target.ps1` runs | 8 (5 by hand, 3 in verify) |
| Azure DevOps objects created or modified | **0** |
| Pipelines queued | **0** |

No token count: the agent cannot measure one from inside the session, and this
project's rule is that a number without an artifact behind it does not belong in
a plan.
