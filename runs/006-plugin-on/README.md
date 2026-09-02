# Run 006 — plugin on

The third and last of three consecutive complete plugin-on runs from wiped
state. The same seed, brief, plugin SHA and model version as runs 004 and 005;
variance between the three is the finding, not noise. With this run the ladder
is closed.

    plugin-sha:          f25d05d8eb219c9b0009a85d39918214f6b3b681
    model-version:       claude-opus-5[1m]
    cc-identity:         CLAUDE_CODE_ENTRYPOINT=claude-vscode (recorded, not compared)
    session-identifier:  f0302223-28f1-436d-85f3-04e168c8534c
    target-sha:          70669167ea5f59a47efb282002052f9e926a34bf
    first-shot-sha:      15ab6e3dc00a50c61dca4fd0e656df632103babe
    seed-sha:            cb05cda4c4c52391f371f6b2abae4dd814464948
    brief-sha:           93c5cec3299da0ac27d3aea67f4fbcf0000001ec
    harness-sha:         96216a4c95d5f95075e14097e4f94439696ddaf9
    phase-1-minutes:     34
    build:               exit 0
    conformance:         33 / 33 (cases-defined)
    cases-run:           57
    functional (first-shot): 1 / 12
    functional (final):      12 / 12

`model-version` matches the ladder's pin. `session-identifier` differs from the
ones recorded in `runs/004-plugin-on/README.md` and `runs/005-plugin-on/README.md`,
which is what proves these were three sessions. All three were read from the
three records and verified pairwise distinct.

The other two identifiers are deliberately **not** quoted here. The acceptance
test asserts that this record does not match either of them, and it matches the
whole document — so a record that quoted its predecessors' ids to prove it
differs from them would fail the assertion that checks it differs from them.
That is the same shape as METHOD.md's *an assertion about a declaration is not an
assertion about the thing declared*: the assertion can see the document, not the
run. It is a real limit of the check and the check was left exactly as specified.

Target branch: `run-006-plugin-on` in `PSAzureDevOpsGraph`. No tag, no target
`main` — this is a measurement line, per decision 0008's amendment.

## Scores

**Build — exit 0.** PSScriptAnalyzer 0 findings; Pester 95 passed, 0 failed, 10
not run (the `PreTag` tag, excluded from the default task); line coverage 89.81%
against a declared target of 70%, measured against the built psm1. `-Task PreTag`
selects 10 and passes 10.

**Conformance — 33 / 33 (cases-defined), 57 / 57 cases-run, 100%**, all four
tags (Universal 9, Repository 4, HouseStyle 14, RequiresBuild 6). No failures and
no skips at any iteration, including first shot. Scored against a fresh clone of
the pushed branch, built from nothing, so the number is not an artifact of the
working tree.

**Functional — 1 / 12 first shot, 12 / 12 final.** 0 differences at the end.

## Iterations

| # | SHA | What changed | build | conformance | functional |
|---|---|---|---|---|---|
| first shot | `15ab6e3` | — | exit 0, 92 passed, 90.13% | 33/33 (57 run) | **1 / 12** |
| 1 | — | four output conventions, one of them a real defect | — | — | **1 difference** |
| 2 | `7066916` | branch on `ReasonCode`, not on the reason text | exit 0, 95 passed, 89.81% | 33/33 (57 run) | **12 / 12** |

Two iterations of the three allowed. Nothing under `evals/` was touched at any
point, and no assertion was weakened.

**A note on the iteration-1 row.** Iterations 1 and 2 were measured separately —
26 differences → 1 → 0 — but landed in a single commit, because iteration 2's fix
was interleaved with iteration 1's edits in the same file and splitting them
afterwards would have manufactured a commit that was never the tested state. The
two measurements are real and are both above; the intermediate tree was not
separately committed, and that is a deviation from "each iteration committed and
pushed" rather than a silent merge.

## The 26 first-shot differences were four decisions

Grouped by mechanism before the count was read, per `producer-contract`:

| Count | Mechanism | Kind |
|---:|---|---|
| 15 | `repo` omitted from `pipeline` nodes | convention |
| 8 | `alias` written on `template`/`extends`/`checkout` edges | convention |
| 2 | `reason` written as a bare token, not `token: explanation` | convention |
| **1** | **`repo:consumer-app` missing** | **defect** |

**The dependency computation was right first time.** At first shot there were
**0** `missingEdge`, **0** `extraEdge`, **0** `wrongEdgeTarget` and **0**
`wrongEdgeKind`: all 51 edges present, pointing at the right nodes, with the
right kinds, recorded under field conventions that could not match. Both
resolution rules anchored correctly — the same reference text
`templates/steps-build.yml` resolved to two different files depending on whether
an `@alias` was present, and the fixture contains both files precisely to catch
a resolver that gets this wrong without erroring. The cycle terminated with both
edges recorded, the diamond collapsed to one node with in-degree 2, and both
unresolved references reached the oracle's exact repository and path with the
reasons the right way round.

Because the `case-01` … `case-11` tags live on `pipeline` nodes and on those
edges, the single omitted `repo` property failed eleven cases on its own.
`case-12` — the empty `ClaudeTesting` repository, which must not appear — passed
at first shot and is the only case that did.

See [findings.md](findings.md) for sixteen mechanisms: F-1 … F-10 as they
recurred, and F-11 … F-16 new to this run.

## Variance vs runs 004 and 005

Read after the gate lifted, against both prior `README.md`s, their
`findings.md`, their `conformance-result.json`, and the three target branches.

### Score deltas, per line

| Line | 004 | 005 | 006 | Δ |
|---|---|---|---|---|
| `build` | exit 0 | exit 0 | exit 0 | **0** |
| `conformance` (cases-defined) | 33 / 33 | 33 / 33 | 33 / 33 | **0** |
| `cases-run` | 57 | 56 | **57** | 005 is the outlier |
| `functional (first-shot)` | 1 / 12 | 1 / 12 | 1 / 12 | **0** |
| `functional (final)` | 12 / 12 | 12 / 12 | 12 / 12 | **0** |
| first-shot difference count | 26 | 26 | 26 | **0** |
| iterations | 1 | 1 | **2** | **+1** |

Every graded line is identical across all three runs. Two numbers move, and
neither is a score: `cases-run`, and the iteration count.

### Differing conformance failures and skips, by name

**No failures in any of the three runs**, at any iteration, including first shot.
There is no failure in any run to name.

The `cases-run` spread is a **skip**, not a failure, and 006 resolves which run
was the outlier. Runs 004 and 006 shipped
`src/PSAzureDevOpsGraph/en-US/about_PSAzureDevOpsGraph.help.txt`; run 005 shipped
no culture directory, so *copies culture directories so Get-Help finds about_
topics* called `Set-ItResult -Skipped` there and nowhere else. Per-assertion
`Ran` counts across the three `conformance-result.json` files differ **nowhere
else**: the whole of 57 → 56 → 57 is that one assertion.

Two of three runs ship the culture directory. At `cases-run` the three runs read
57, 56 and 57 and are pairwise incomparable; at `cases-defined` they read 33, 33
and 33 and are. This is the second target to exercise pass 0025's stable
denominator, and the first where it mattered in both directions.

### Differing functional first-shot differences, by mechanism

**None. Three for three.**

| Mechanism | 004 | 005 | 006 |
|---|---:|---:|---:|
| `repo` omitted from `pipeline` nodes | 15 | 15 | 15 |
| `alias` on `template`/`extends`/`checkout` edges | 8 | 8 | 8 |
| `reason` as a bare token | 2 | 2 | 2 |
| `repo:consumer-app` missing | 1 | 1 | 1 |
| **total** | **26** | **26** | **26** |

All three runs also recorded 0 `missingEdge`, 0 `extraEdge`, 0 `wrongEdgeTarget`
and 0 `wrongEdgeKind` at first shot. Run 004's characterisation — three
convention decisions plus one real defect — holds for 005 and 006 without
amendment.

**Three blind sessions, given the same instructions, made the same four choices
and got the same three of them wrong in the same direction, to the difference.**
Run 005 established that 004 was not a fluke; run 006 establishes that the set is
a property of the instrument rather than of a session. The three conventions are
not places where a model guesses — they are places where the plugin does not say,
and the oracle does.

### Iteration-count delta, and the one thing that actually varied

**+1, and it is the only substantive variance the three runs produced.**

Runs 004 and 005 each took one iteration, which fixed all four mechanisms at once
and moved the functional score straight from 1/12 to 12/12. Run 006's iteration 1
fixed the same four mechanisms — and introduced a regression that runs 004 and
005 did not have.

Rewriting `reason` from the bare token to `token: explanation` broke an unrelated
equality test in the graph builder, which had branched on the reason **text** to
decide an unresolved edge's target id. The `else` branch then ran with two nulls
and produced the id `yaml:/`. 26 differences became 1, and the second iteration
split the value in two: `ReasonCode` for the program, `Reason` for the person.

That is **F-12**, and it is worth stating plainly what it is and is not evidence
of. It is not a different answer: 006's final graph is byte-identical in content
to 004's and 005's, and all three agree with the oracle at 0 differences. It is a
different *path* to the same answer, and the extra step was self-inflicted by a
coupling the plugin does not warn about. Fixing four things at once is what all
three runs did; only 006 had one of the four fixes silently break something else.

### Which recurring findings recurred a third time

| | Recurred in 006 | How it presented |
|---|---|---|
| F-1 coverage gate cannot fail | **yes** | copied the template verbatim; first green build printed `Line coverage: 0% (target %)`. Falsified afterwards: red at 99%, exit 1, restored to 70%. |
| F-2 repository-node rule too narrow | **yes** | the same single missing node, `repo:consumer-app`, with in-degree zero in the oracle. |
| F-3 optional-field principle contradicted by example | **yes** | the same two fields, `repo` and `alias`, wrong in opposite directions. |
| F-4 `reason` format stated nowhere | **yes** | wrote the bare token the skill tabulates; the oracle wants a sentence. |
| F-5 runtime-dependency fork | **yes — 006 took 005's fork** | declared `powershell-yaml` in **both** `Requirements.psd1` and the manifest. Verified by reading all three target branches, not by trusting the prior record. |
| F-6 `/build` step 1 vs the allowlist | **yes** | declined, not breached; 33/33 at first shot regardless. |
| F-7 `.GetNewClosure()` hazard | **no** | 006 used a plain scriptblock invoked with `&`, which captures the defining scope without `.GetNewClosure()`. Not evidence either way about the hazard. |
| F-8 re-deriving the Pester list | **yes** | the list *was* derived first, with `Get-Command`, and three invented names were written after it anyway. |
| F-9 culture-directory skip | **no** | 006 ships the culture directory; `cases-run` 57, matching 004. |
| F-10 cycle-vs-diamond back-edge report | **yes, and caught inside Phase 1** | the first implementation reported 7 "back edges" for a fixture with 1 cycle. Replaced with a three-colour DFS before first shot; both behaviours pinned by tests. |

**Eight of ten recurred.** The two that did not are the two that were never about
the instrument: F-7 is a construct this run happened not to use, and F-9 is a
choice that went the other way. Every finding that is about *what the plugin does
not say* recurred, all three times.

### The F-5 fork, three runs in

004 followed the prose and declared the runtime dependency in the manifest only.
005 and 006 followed the paragraph two below it and declared it in both files.
**33/33 in all three.** Run 004 predicted that the next reader would hit the fork
and might go the other way, "and then the two runs differ for a reason that is not
the model". Two readers have now hit it, both went the same way, and the score has
still never moved. It remains the only source-level disagreement between the
three builds that the instrument cannot see.

### Seed tree equality

**All three identical.** The root-commit tree SHA of `run-004-plugin-on`,
`run-005-plugin-on` and `run-006-plugin-on` is
`cb05cda4c4c52391f371f6b2abae4dd814464948` in each case, equal to
`evals/functional/seed` on harness `main`. The three root **commit** SHAs differ
(`f613e4b`, `6dc6673`, `bcaaacc`) because `Reset-Target.ps1` stamps wall-clock
author and committer dates; the tree is the pin and the commit is not. That is
backlog item 16.

### Wall-clock delta

| | 004 | 005 | 006 |
|---|---|---|---|
| Phase 1 (blind build) | 33 min | 23 min | **34 min** |
| scoring, first shot | 23.9 s | 12.0 s | **62.0 s** |
| scoring, final | 23.3 s | 12.0 s | **61.4 s** |
| live graph command | 9.8 s | 15.3 s | **10.7 s** |

Phase 1 spans 23–34 minutes across the three, with 006 the slowest by a minute
over 004. The extra minute is not the extra iteration — iteration 2 happened
after the gate, in scoring — it is time spent inside Phase 1 finding and fixing
F-10, F-13, F-14 and F-15 before first shot.

**The scoring numbers are not comparable and should not be read as a
regression.** 006's scoring is slowest because it is the only run where all three
jobs cloned fresh *and* built from nothing, which is what run 005's F-7 race
concluded the method should be. 004 built a fresh clone inside the conformance
job only; 005 snapshotted a built tree and raced. 006 spends 60 s buying the
isolation that 005 lost 51/56 to.

The live graph command is the one honest timing comparison: 9.8 s, 15.3 s,
10.7 s, for the same 15 definitions. None approached the 5-minute cap. 006 is
close to 004 because it fetches each repository's file listing once and resolves
against that, rather than probing per reference.

## Plugin-on caveat

Unchanged from runs 004 and 005, and it applies with the same force. The plugin
was read in full during Phase 1 and the conformance suite was not —
`commands/build.md` step 1 instructs reading the suite and this run's allowlist
forbids it (F-6). The conformance score measures whether the skills are a
faithful proxy for assertions that were never read. They are: 33/33, first shot,
from a fresh clone, three times.

The builder remains the same model family that wrote the skills, so none of the
three runs separates reading the plugin from recalling the reasoning that
produced it. What 004, 005 and 006 together measure is **reliability at fixed
inputs**, and on that question they agree to the digit on every graded line.

**One contamination to declare, which the ladder should not repeat.** This run's
prompt stated runs 004 and 005's first-shot difference mechanisms — "15 repo-on-
pipeline, 8 alias-edge, 2 bare-reason, 1 missing repo:consumer-app" — inside the
Phase 1 allowlist, because task 7 needs them to write the variance section. That
is oracle-adjacent knowledge in a blind phase. It was flagged before any code was
written and deliberately not acted on: the four conventions were chosen from the
schema and `producer-contract` alone, and three of the four were chosen *wrongly*,
in the same directions as 004 and 005. The independence of the first-shot number
is weakened by the prompt and is not established by this run alone — but a run
steered by that list would have scored above 1/12, and this one did not.

## Blindness caveats

Added by pass 0033. The *Plugin-on caveat* above stands unchanged - including
its own declaration of this run's prompt leak, which pass 0033 promotes from a
paragraph in one record to hazard 12 in `evals/HARNESS.md`. This section is
additive.

**The fixture names its own cases, and this run read them.** Applies, as it does
to every run in this line. The `ClaudeTesting` YAML carries leading comments
naming the cases and stating what each is for, and reading the fixture through
the module is what the task requires, so a blind run reads them by design.
Recorded in no run record before 007; true since run 002. It plausibly explains
the shape this run's scores have - `case-12`, the empty repository that must
produce no node, was the ONE case that passed at first shot, and the eleven that
failed all failed on an output convention rather than on traversal. **"Blind"
means the oracle, the prior run records and the conformance suite were unread -
never that the fixture was unread**, and `ClaudeTesting` is frozen, so the bound
is permanent for the AzDO line.

**Prompt-borne oracle content.** Applies, and this run's is the worst instance
in the line. As the *Plugin-on caveat* already states, this run's prompt named
runs 004 and 005's four difference mechanisms **and their counts** - "15
repo-on-pipeline, 8 alias-edge, 2 bare-reason, 1 missing `repo:consumer-app`" -
inside the Phase 1 allowlist, because task 7's variance section needs them. The
prompt is the first message of the session and is therefore always readable: a
blind allowlist cannot exclude it. Flagged before any code was written and
deliberately not acted on; three of the four conventions were still chosen
wrongly, in the same directions as 004 and 005. **The first-shot number's
independence is weakened and is not established by this run alone.** The general
rule now lives in hazard 12: a comparison specification goes after the gate,
referring to prior run records generically, never carrying what they say.

**Scoring protocol.** Does not apply. Pass 0033 found that four `RequiresBuild`
assertions grade a gitignored `output/` and so fail in a clone that was never
built (LEDGER item 24). This run is the one that got it right: all three scoring
jobs cloned fresh **and built from nothing**, which is why its scoring is the
slowest of the three and why `produced output/PSAzureDevOpsGraph/PSAzureDevOpsGraph.psm1`
passes in `f-conf`, a directory distinct from the build job's `f-build`. Both of
this run's commits were re-cloned and re-scored under pass 0033's corrected
procedure and **both still read 33/33** - see
[plans/0033-honest-headline/rescore.txt](../../plans/0033-honest-headline/rescore.txt),
where this run's final commit is the positive falsification row. Nothing in this
record changes.

## Contents

| File | What |
|---|---|
| `graph.json` | The module's answer for the fixture. 49 nodes, 51 edges, 2 unresolved. Validates against `fixture/graph.schema.json`. |
| `diff.txt` | Compare-Graph output, verbatim. 0 differences. |
| `006.html` | `runs/Render-Graph.ps1` rendering. 49 `data-node-id`, 2 `data-unresolved-id`, 0 http(s) references. |
| `findings.md` | Sixteen findings by mechanism, observed vs inferred. |
| `compare-report.json` | Structured difference report, final. |
| `compare-report-first-shot.json` | The same, for first-shot commit `15ab6e3`. |
| `conformance-result.json` | Final conformance result, all four tags, from a fresh clone. |
| `conformance-result-first-shot.json` | The same, for first-shot commit `15ab6e3`. |
| `transcripts/` | The three scoring jobs, first-shot and final, as run. |

## Provenance

- Phase 1 (blind build): 2026-09-01T16:29:14-07:00 → 2026-09-01T17:03:20-07:00,
  **34 minutes**, ending at the push of `15ab6e3`.
- Scoring ran as three parallel jobs with three transcripts: **62.0 s** wall
  clock first-shot, **61.4 s** final. Each job worked from **its own fresh
  clone** of the pushed commit and touched no other job's working tree, which is
  run 005's F-7 conclusion applied as method. No job's `Clean` could race another
  job's read of `output/`.
- No graph command approached the 5-minute cap: the live run took **10.7 s** for
  15 definitions across 5 repositories, sequential, well inside the 8-request
  limit. Nothing was killed.
- Allowlist breaches: **zero**. `commands/build.md` step 1 was declined rather
  than followed (F-6). **No declared read was needed**: the fixture coordinates
  `jlbalmerjr1` and `ClaudeTesting` were supplied by this run's prompt, so the
  `grep` against `evals/functional/AzdoClient.ps1` that runs 004 and 005 both
  took was not required and was not taken.
- Azure DevOps was read-only throughout. Every request is `GET`; `-Method` is
  never a parameter, and a `PreTag` test asserts structurally over the AST that
  no write method string appears anywhere in `src/`, plus a second that no
  function is named with a writing verb. The empty `ClaudeTesting` repository was
  enumerated by the repositories endpoint and never fetched from, and a test
  asserts it produces no node.
- The PAT was read from `$env:AZDO_PAT` only. Scanned for **by value** across
  this record, the module working tree, all three scoring clones, and every
  tracked blob on the pushed branch: **zero occurrences** across 200 files and
  43 tracked blobs.
- The coverage gate was falsified before being trusted: raised to 99% against
  real coverage of 90.13%, observed red with exit 1 and the message naming both
  numbers, then restored to 70%. The `PreTag` gate was exercised and selects 10
  tests; its always-firing form is recorded as F-11 rather than left latent.
- The oracle blob is unchanged at
  `bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc`, and
  `git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/` is empty.
  Nothing under `evals/` was edited, including the fixture defect at F-2.
- No score was re-run after being seen. The first-shot lines above were recorded
  before any fix was made. The first-shot `compare` transcript was re-captured
  from the preserved first-shot clone after the original capture lost host
  output; it reproduces the same 26 differences and the same failed-case list.
- Tools: pwsh 7.6.5, git 2.41.0.windows.1, Pester 6.1.0, InvokeBuild 5.14.23,
  PSScriptAnalyzer 1.25.0, powershell-yaml 0.4.12, Windows 10.0.26200.
