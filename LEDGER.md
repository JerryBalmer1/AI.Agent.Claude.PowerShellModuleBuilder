# LEDGER — maintained by the agent as the last task of every pass

The chat context points here; this file is the source of truth
for counters and pins. Update it in the same commit as the work
that changes it.

## Passes
Last landed: **0034**. Next: **tf-003**, which is now unblocked — see
Runs and backlog 6. 0034 is a constructive pass: it took decision
0014, built a **second Terraform fixture** (`TfSiteCore`,
`TfSiteEdge`, `TfSiteOps`) written without case annotations, promoted
pass 0033's hand-scan to `evals/tf/Test-FixtureSanitization.ps1` as a
standing gate, wrote the three `tf-<role>` skills backlog 9 had
withheld, landed the two run-007 hardening lines, and released
**v1.1.0**. It is the first release since v1.0.0 to change `skills/`;
`commands/` is byte-identical to v1.0.1.

0033 was a docs/method patch: it rewrote the with/without claim
against run 007, repaired the conformance scoring procedure,
disclosed two blindness bounds, and released **v1.0.1**. It changed
nothing under `skills/` or `commands/`. 0030 ran after 0031 because 0031 was taken out of order
deliberately (the manual and the local publish path do not depend on
packaging), so the numbers do not read in landing order and that is
expected. The guard in `tools/publish/Publish-Real.ps1` no longer
refuses: 0030 landed the committed marketplace and it now prints the
operator's checklist.

0032 completed decision 0009's deferred step, which 0030 left
outstanding: harness `main` was fast-forwarded `c8330d7..ec07aef`
before any work began.

The obvious next candidates, none of them chosen: the cold-install
proof (backlog 2's remaining half), per-skill ablation (backlog 18),
and the tf-003 decision — which is now a **decision** rather than a
run, and is described under backlog item 6.

## Runs
AzDO-module (runs/NNN-*): **ladder COMPLETE at 004–006** (passes
0026-0028), **control COMPLETE at 007** (pass 0032). All four show
three complete score lines. The next run series is the operator's
decision — nothing is scheduled.
Terraform (runs/tf-NNN-*): last tf-002, next tf-003 — **UNBLOCKED by
pass 0034, and it targets FIXTURE 2.** Pass 0033 scanned fixture 1 for
the vector in hazard 13 and it is not clean: it names its own cases by
number, states the wrong answer to several, and one README points at
`evals/tf/fixture/cases.md` by path. Fixture 1 is frozen (decision
0011) and stays annotated; its bound is disclosed, not repaired.
Decision 0014 built fixture 2 unannotated for exactly this
measurement.

**What tf-003 must now use:**
- oracle `evals/tf/fixture2/expected-graph.json` — 99 nodes, 88 edges;
- cases `evals/tf/fixture2/cases.md` — **oracle content, disqualifying
  to read before a blind build**, same as fixture 1's;
- repositories `TfSiteCore`, `TfSiteEdge`, `TfSiteOps` in
  `ClaudeTestingTerraform`, at the Pins SHAs below;
- comparator `Compare-TfGraph.ps1` unchanged; the mutator, the
  falsification driver, the publisher and the read-back take
  `-Fixture fixture2`;
- plugin surface pinned at **v1.1.0**, which is the first release
  carrying the three `tf-*` skills. Pinning v1.0.1 measures a plugin
  with no Terraform skills in it and is a different question.
- **`evals/tf/Test-FixtureSanitization.ps1 -Fixture fixture2` must be
  clean at the run's preconditions.** It is the gate that says the
  instrument is still mute.

Two known gaps tf-003 has to close or accept, both found by pass 0034:
a fixture-2 counterpart to `Test-TfFixtureCase.ps1` does not exist
(**backlog 29**); and `Compare-TfGraph.ps1` cannot see a duplicate
node id, so `IsMatch` alone is not a sufficient verdict on a
producer's graph — assert `ActualNodeCount -eq ExpectedNodeCount`
beside it, or fix the comparator first (**backlog 32**).

**007 — baseline off, iterated** (`runs/007-baseline-iterated`,
target `run-007-baseline-iterated`, final `95ca28d`, first shot
`1f2df30`, session `c0002fae-addf-4ff6-847e-9faf5d6aa05e`, plugin
surface `v1.0.0` present but UNREAD): build exit 0; conformance
**19/33 → 28/33** cases-defined, 55 cases-run; functional **6/12
first shot → 12/12 final**, 3 iterations used but 12/12 reached at
iteration 1. Two caveats that travel with the number: the pass prompt
itself named three of the four convention mechanisms to the builder,
and `Compare-Graph` prints the oracle's expected values, so
"converged without the plugin" is true while "without the conventions
being readable anywhere" is not. See `runs/007-baseline-iterated/findings.md`
Part 3.

**007's conformance figures were re-derived by pass 0033 and the
final one moved: 28/33 as reported, 32/33 under the corrected
procedure** (the conformance clone is now built before it is scored).
First shot 19/33 → 20/33 the same way. Run 006 re-scored under the
same procedure and did not move, at either commit — which is what
makes it the control for the repair. `plans/0033-honest-headline/rescore.txt`.

## Versions
PSAzureDevOpsGraph: v0.2.0 (next touching plan: v0.3.0)
PSGraphRender: v0.13.0
PSGraphRenderToHtml: v0.1.0 (next: v0.2.0)
PSTerraformGraph: v0.2.0
psmodule manifest: **1.1.0**, released and tagged `v1.1.0` by
pass 0034 under decision 0013. **MINOR, and the first release since
v1.0.0 to change `skills/`:** three new `tf-<role>` skills, plus two
hardening lines added to `azdo-rest` and
`powershell-module-scaffold`. `commands/` is byte-identical to
`v1.0.1` and `git diff v1.0.1..v1.1.0 -- commands/` is empty. The
seventeen-skill count is now stated in `README.md`, `SECURITY.md` and
chapters 07/08/09; the *fourteen* that remain in ablation sentences
are deliberate and refer to the roster the ladder measured.
Previously **1.0.1**, released and tagged `v1.0.1` by
pass 0033 under decision 0013. That tag names `1a947a4`, one commit
behind the pass tip: `verify.ps1`'s falsification transcripts could
only land after the falsification ran. The tag is a complete release
and the later commit is plan artifacts only. Same divergence pass
0030 recorded; a pushed tag is not moved — a docs/method patch with `skills/`
and `commands/` byte-identical to `v1.0.0`. Before that, **1.0.0**,
tagged `v1.0.0` by pass 0030. The reservation is spent: v1.0.0 was
"passed the ladder" and the ladder is closed. Next release version
is decided by what changes — MAJOR breaks a consumer's existing
use, MINOR adds skills/commands/conventions, PATCH corrects
documents and defects (README "Versioning" states this in consumer
words). The tag and `.claude-plugin/plugin.json` must always agree;
`Publish-Local.ps1` checks it and `plans/0030-release/verify.ps1`
re-derives it.

## Pins
**Consumer pin (new at 0030).** Strangers install the plugin pinned
to a release tag, not to a branch — `/plugin marketplace add
JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder@v1.0.0`. This
is decision 0013 and it is why `main` can now move freely: work
landing on `main` reaches no consumer until a release is tagged.
Do not confuse it with the instrument pin below, which is about
blind runs; the two are independent and neither constrains the
other.

Harness main: pass-0028-run-006 tip, fast-forwarded at pass close,
then pass-0029-final-readme on top of it in the same session.
Verified by ancestry and by `git ls-remote`, never by quoting a
SHA this file cannot know about itself. It read
pass-0025-findings-batch until pass 0027; pass 0026 landed run 004
and moved main without updating this line, which is why it is
worth re-reading rather than trusting.
Ladder plugin SHA: f25d05d8eb219c9b0009a85d39918214f6b3b681
Ladder model version: claude-opus-5[1m]
Oracle blob (AzDO): bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc

**The ladder pin check must be amended before the next blind run.**
Runs 004-006 asserted that

    git diff f25d05d..main -- skills/ commands/ .claude-plugin/ evals/

is EMPTY. Pass 0029 landed its one sanctioned documentation change
inside that path — `evals/HARNESS.md`, +69 lines, hazards 9/10/11,
no assertion, script or fixture touched — so that command is no
longer empty and a future run written against it hard-stops for a
reason that is not about the instrument.

The plugin proper is untouched and still checks empty:

    git diff f25d05d..main -- skills/ commands/ .claude-plugin/

Use that form, or exclude `evals/HARNESS.md` explicitly, and
re-verify the oracle and BRIEF blobs separately as runs 004-006
already do. This is a precondition edit, not a new pin: the plugin
SHA above is unchanged and still names the instrument that produced
all three ladder runs.
TF fixture 1 SHAs (decision-0012 re-freeze):
  TfFixtureShared   0af6ee33854bedb4147d0b13cc6db1311687775b  (unchanged)
  TfFixtureNetwork  24f27be92e583b6dfc9208bca42f8ec0baf5004b  (unchanged)
  TfFixtureApp      44ea9338ff35aef328bfa8d51835fc32bea590dd  (amended)
Re-verified untouched by pass 0034, along with "zero builds in the
project" and "the only pipeline definitions are fixture 1's four".

**TF fixture 2 SHAs (decision-0014 freeze, pass 0034).** Read back
byte-identical, 46 files across three repositories
(`plans/0034-fixture2/readback2.txt`):
  TfSiteCore        a228e78c247d2d4367303f303c4363d9906e06f2
  TfSiteEdge        1ae66c2712f799a69304cb4364e91e4d10d694c4
  TfSiteOps         fe27a34f7585b86b6fdbf12b609e17d4cb0f4b83
Frozen on decision 0011's terms: changes require a new decision. A
defect found in it is a finding, not an edit. **No pipeline
definitions were created for these three**, deliberately — the YAML
files exist in the repositories and carry `trigger: none` / `pr:
none`, and nothing was ever queued. See backlog 31 if a future run
wants definition parity with fixture 1.

## Backlog (priority order; operator reorders)
1. Runs 004-006 + 0029 final README
2. 0030 packaging: marketplace.json, cold-install proof
3. Fixture restore drill (Sync-Fixture restore direction)
4. Per-skill ablation runs (suspects first)
5. Mirror assertion + dependency-wave ordering (post-ladder)
6. **tf-003 — the blind Terraform run. UNBLOCKED, and top of the
   backlog.** Pass 0033's scan said fixture 1 names its own cases by
   number and one README points at the oracle by path, so a run
   against it measures parsing, not generalisation. Option (c) was
   taken: **decision 0014, and pass 0034 built fixture 2.** The
   decision is made and the instrument exists. What remains is the
   run itself, against fixture 2, with the plugin pinned at v1.1.0 —
   the full precondition list is in **Runs** above. It stays top of
   the backlog because it is still the only generalisation claim the
   project has queued, and now nothing is in its way.
7. Portability / non-graph functional layer (on trigger only)

### Added by pass 0025

8. **PSTerraformGraph: `Export-TfConfigurationGraphHtml` is exported
   and no test invokes it.** Conformance 40/41 on that repository, the
   one failure being the invocation check. Found after v0.2.0 was
   tagged and pushed; fixing it would have meant rewriting a pushed tag
   or landing on `main` past the tag it follows, so it was recorded
   instead. Belongs to the next pass that opens that repository.
9. **~~The three `tf-<role>` skills tf-001 proposed were deliberately
   not written.~~ CLOSED by pass 0034 — see *Resolved by pass 0034*.**
   The original entry stands below, unedited, because a closed item
   whose text is rewritten stops explaining why it was open.

   They would carry this fixture's specific answers, and
   tf-003 is meant to be the blind measurement against that same
   fixture. Writing them first measures the plugin's memory of tf-001
   rather than its generality. An operator decision, recorded not
   taken — see `runs/tf-002-convention-and-case3/findings.md` section C.
   Cleanest orders: write them after tf-003, or build a second Terraform
   fixture they were not written against.
10. **PSGraphRender cannot be imported from `src/`.** The third module
    to need the committed dev loader; noted as pending in its own
    HANDOFF and not applied, because pass 0025 was scoped to leave that
    repository's code untouched.
11. **Decision 0007's skill taxonomy has no bucket for a cross-cutting
    skill.** `producer-contract` is neither `powershell-module-<role>`
    nor `azdo-<role>`. Left as-is and flagged in the README rather than
    bent into a name that lies; worth settling if a second one appears.

### Blind-run hygiene — operator-directed, landed ahead of run 004

12. **HARNESS.md hazard entry — run records are oracle knowledge in
    prose; a session that has read `runs/` is disqualified as a blind
    builder; blind-run prompts are the first message of a fresh session;
    AND nothing may ever write run scores, fixture findings, or oracle
    content into session memory, `MEMORY.md`, `CLAUDE.md`, or any
    auto-loading location — a poisoned memory fails the gate permanently
    and silently** (fold in at 0029; `evals/` frozen until then).

    Raised when pass 0026 stopped at its own session gate: pass 0025 had
    read `runs/002-first-build/README.md` and `runs/003-baseline-off/`
    legitimately, to rebuild those clones for the conformance-denominator
    falsification, and that alone disqualified the session from building
    run 004 blind. The reading had nothing to do with the AzDO fixture's
    answers and burned the session anyway.

    The memory clause is the half with no visible failure. A context
    window is cleared by `/clear`; an auto-loading file is not, so a
    single score written to memory disqualifies **every** future session
    and nothing announces it. Verified empty at the time of writing:

        <project>/memory/           empty, no MEMORY.md
        harness CLAUDE.md           absent
        harness .claude/            absent

    Keeping it empty is the enforcement until the hazard entry lands.
    `evals/HARNESS.md` is the destination and is frozen behind the
    ladder, which is why this sits here and not there.

    **Run 004's task 8 is satisfied for this item — append nothing, and
    do not restate it.** Its shorter wording is superseded by the text
    above.

14. **Run-record commit subjects leak scores into every future session
    via git log at preconditions** — message convention: run and pass
    commits carry no scores in subjects; scores live in README/plan
    bodies only (fold into HARNESS.md with 12/13 at 0029).

### Added by pass 0028

15. **`pwsh -File` flattens a comma-separated array into one token** —
    `-Tag Universal,Repository,HouseStyle,RequiresBuild` arrives as a
    single string and the tag filter then selects nothing, or the wrong
    set, without erroring. Bit run 005 three times, including inside its
    own `verify.ps1`. Use `-Command` with a real `@(...)`, or call the
    script in-process. Skill line for `powershell-module-build` /
    `powershell-module-test` when the plugin unpins.

16. **`Reset-Target.ps1` stamps wall-clock author and committer dates**,
    so the seed COMMIT SHA is irreproducible by design and differs in
    every run — 004 `f613e4b`, 005 `6dc6673`, 006 `bcaaacc` — while the
    seed TREE is identical in all three (`cb05cda4c4c52391f371f6b2abae4dd814464948`).
    The tree is the pin; the commit is not, and a check written against
    the commit SHA fails for a reason that is not about the seed. Either
    document it or add `-Epoch` when `evals/` unfreezes.

### Resolved by pass 0029

- Item **1** (runs 004-006 + 0029 final README): **done.** Ladder
  complete, final README written from the journal and the four run
  records.
- Items **12 / 13 / 14** (blind-run hygiene): **folded into
  `evals/HARNESS.md` as hazards 9, 10 and 11** — the session gate and
  the run-records-are-oracle-knowledge rule, the memory-poisoning
  vector, and the commit-subject convention. Item 13 never had its own
  numbered entry; its wording was absorbed into item 12 and is now
  hazard 10. Nothing else under `evals/` was touched.

### Added by pass 0029

17. **The baseline has one run and it was never allowed to iterate.**
    Run 003's protocol was "no fixes, no re-runs — the first scores
    stand", so the with/without table has no plugin-off final column
    and cannot have one. A second plugin-off run under runs 004-006's
    rules — three iterations allowed, scored from fresh clones — is the
    missing control, and until it exists nobody knows what a
    plugin-off run reaches given the same budget. Highest-value single
    run remaining.
18. **Per-skill ablation is still unmeasured** (was backlog 4, now
    sharpened). The measured plugin effect is 19/33 → 33/33 on shape
    and four specific behavioural rules; which of the fourteen skills
    carries which part is unknown. Suspects first:
    `powershell-module-build` and `powershell-module-scaffold` for the
    conformance delta, `azdo-graph-assembly` and
    `azdo-pipeline-yaml-refs` for the four behavioural fixes.

### Added by pass 0031

The prompt for this pass asked for the first of these as "17". Items 17
and 18 were already taken by pass 0029, so it lands as 19 with its
wording unchanged. Recorded rather than silently renumbered, because a
backlog item whose number moved is a backlog item somebody will cite
wrongly later.

19. **Doc maintenance is a standing obligation** — any pass that changes
    behavior the manual or docs/testing describes updates those chapters
    in the same pass; 0029/0030 outcomes fold into chapters 02/05/07/09
    and docs/testing when they land.
20. **`evals/tf/Compare-TfGraph.Tests.ps1` is RED as committed on
    `main`.** Line 41 asserts `$result.ExpectedEdgeCount | Should-Be 57`.
    The oracle amended under decision 0012 holds **59** edges and the
    comparator returns 59. Measured, not inferred: `Invoke-Pester` on
    that file returns 14 passed, 1 failed, and the failing case is
    `states what it compared, not just that it matched`. Found by pass
    0031's testing document re-running the artifact instead of quoting
    it. Not fixed there because `evals/` was read-only to that pass, and
    a one-line edit inside a pinned path is what the pin exists to
    prevent. Belongs to the next pass that opens `evals/tf/`.
21. **Three documents disagree about the falsification controls and the
    corpus figures, and the drift is one-directional.**
    (a) `README.md` and `evals/conformance/README.md` say eleven of
    twelve controls stay green with the twelfth documented as failing;
    `evals/conformance/baseline/FALSIFICATION.md` says all twelve are now
    correct because pass 0008 converted row 7's assertion to AST, and
    `TASK.md`'s pass 0008 outcome says "control now green". One of the
    two is stale and only reading the suite settles which.
    (b) `evals/conformance/README.md`'s *Validation status* paragraph
    says five of ten `Universal` assertions survive all nine targets;
    its own *Known limits* section, `README.md` and `UNIVERSAL-CORPUS.md`
    all say seven of nine, and UNIVERSAL-CORPUS.md records it explicitly
    as "up from five of ten". `evals/HARNESS.md`'s Open questions still
    carries the stale five-of-ten too. Two files carry both numbers in
    different sections, which is how this survived four passes.
22. **`PLAN-PROTOCOL.md`'s own worked example contains a false clause.**
    Its tier section says pass 0012 "shipped without the red-first test
    the tier requires". `plans/0012-case-split-and-corrections/plan.md`
    §3 is headed *Acceptance test — red first* and records
    `RED-FIRST: Passed=315 Failed=15 Total=330`; the pass's prompt
    required both a red-first test and a `verify.ps1` regardless of the
    light label, and both are present. Everything else in the example is
    correct — the pass did amend an assertion in `Fixture.Tests.ps1` and
    did flag the mislabel itself. The rule the example teaches is right;
    one clause of its evidence is not. Correcting the protocol document
    is a deliberate act and was left to a pass that owns it.

### Resolved by pass 0030

- Item **2** (0030 packaging: marketplace.json, cold-install proof):
  **half done.** `.claude-plugin/marketplace.json` is committed, the
  manifest is 1.0.0, both are validated by `Publish-Local.ps1` and the
  validator was falsified on all six rules it enforces. **The
  cold-install proof is NOT done** and remains outstanding — nobody
  has installed this on a machine that has never cloned the
  repository. It is step 6 of the checklist `Publish-Real.ps1` now
  prints, and it is named as unproven in README "Status, honestly",
  SECURITY.md and CHANGELOG.md. Do not read this item as closed.
- Item **20** (`Compare-TfGraph.Tests.ps1` red on `main`): **fixed.**
  Line 41 now asserts 59, hard-coded with a comment citing decision
  0012 rather than derived, because the fixture is frozen and a
  derived count would follow a drifting fixture instead of catching
  it. Suite 15/15. Proved not to be assertion-weakening by re-running
  the seven mutations: `DETECTED: 7 / 7`
  (`plans/0030-release/mutations.txt`).
- Item **22** (`PLAN-PROTOCOL.md`'s false clause): **fixed.** The
  worked example now says what plan 0012 §3 records — a near miss
  whose full-tier artifacts existed because the prompt required them,
  not because the light label did. The rule it teaches is unchanged.
- Item **19** (doc maintenance as a standing obligation): **honoured
  for this pass, and it stays open** — it is an obligation, not a
  task. Chapter 09 and `method/METHOD.md` were updated in the same
  pass as the behaviour they describe.

### Resolved by pass 0032

- Item **17** (the baseline has one run and was never allowed to
  iterate): **CLOSED.** Run 007 is the missing control — plugin-off,
  same seed, brief and model pin as the ladder, with the ladder's
  three-iteration budget. **It converged: 6/12 first shot → 12/12
  final, in one iteration, with the plugin unread throughout.**
  Conformance went 19/33 → 28/33 against the ladder's flat 33/33. The
  with/without table now has its plugin-off final column, and it says
  the plugin buys conformance rather than correctness.

  Read the number with its two caveats attached (pass 0032 Deviations
  3 and 4): the pass prompt named three of the four mechanisms and
  their counts to the builder before it wrote a line, and
  `Compare-Graph` discloses the oracle's expected value for every
  wrong attribute. The plugin was unread; the conventions were still
  legible from the scorer. A cleaner control keeps the mechanism list
  out of the builder's prompt.

### Added by pass 0032

23. **The README's with/without section overstates the plugin.** Four
    runs now exist and all four reach 12/12 functional within two
    iterations; the measured plugin effect is on conformance
    (33/33 first shot versus 19/33), not on correctness. The
    replacement sentence is drafted verbatim in
    `runs/007-baseline-iterated/README.md` under *The sentence the
    README will need*. **Not applied by 0032 on purpose** — the
    release surface is tagged at v1.0.0 and rewriting it is a pass
    that owns it. For the next release pass.
24. **`RequiresBuild` and the three-clone scoring rule are
    incompatible.** Four conformance assertions read `output/`, which
    is gitignored and therefore absent from a clone that has not been
    built; the protocol scores conformance in a clone that never runs
    the build, so those four can never pass. Run 007 measures 28/33
    under the protocol and 32/33 in one clone with the build run
    first (`conformance-result-built-clone.json`). The ladder reported
    33/33 with them passing, so its jobs saw build output somehow —
    and run 005's README documents a race implying its jobs shared a
    tree. **Until this is resolved, 007's 28 and the ladder's 33 are
    not the same measurement**, and the gap is overstated by four.
    Fix the rule or fix the tag; do not compare across it.
25. **The live fixture is annotated with case identifiers and
    explanations.** Reading it through the module — which every run's
    protocol requires — returns YAML whose comments name each case and
    state the trap. Every run, blind or not, has had this. It is a
    plausible explanation for why the traversal is right first time in
    all four runs while the output conventions never are, and it is
    recorded in no run record before 007. Decide whether "blind" is
    meant to exclude it; if so, the fixture needs stripped comments
    and a re-run.

Item **21** (three documents disagreeing about the falsification
controls and corpus figures) was **not** touched and stays open.

### Resolved by pass 0033

- Item **23** (the README's with/without section overstates the
  plugin): **CLOSED.** Rewritten against run 007 from its drafted
  sentence; the table carries 007's row, both conformance protocols,
  and every caveat footnoted to its artifact. The claim is now "the
  plugin buys shape, not correctness", with the limit that a single
  control cannot say why.
- Item **24** (`RequiresBuild` and the three-clone rule are
  incompatible): **CLOSED.** The procedure was the defect and it is
  repaired — the conformance clone is built before it is scored,
  as `evals/conformance/Score-Clone.ps1`, HARNESS step 4 and
  METHOD.md. No assertion changed. Falsified four ways (unbuilt
  control still red at exactly 28/33, sabotaged build red, Phase-0
  gate fires, built conforming clone green at 33/33). Both runs
  re-scored: 007 final 28 → **32/33**, 006 final unchanged at
  **33/33**. The ladder mechanism is **explained, not assumed**:
  each ladder run had build output in its conformance tree by a
  different improvised route (004 built inside the conformance
  clone, 005 scored a snapshot of a built tree, 006 built all
  three), so "three clones" never meant "unbuilt clone" and 007 was
  the first to read it that way.
  `plans/0033-honest-headline/rescore.txt`.
- Item **25** (the live fixture is annotated with case identifiers):
  **CLOSED as disclosed, not as fixed.** `ClaudeTesting` is frozen
  and all five AzDO runs were scored against the annotated form, so
  stripping it now would cost more comparability than the bound is
  worth. It is `evals/HARNESS.md` hazard 13, it is in the README's
  honest-status list, and runs 003–007 each carry a
  `## Blindness caveats` section. The vocabulary is corrected with
  it: "blind" means the oracle, the run records and the plugin were
  unread — never that the fixture was unread. The same scan was run
  against the Terraform fixture and it is **not** clean; see backlog
  item 6.
- Item **19** (doc maintenance as a standing obligation):
  **honoured, and it stays open** — it is an obligation, not a
  task. Chapters 02, 04, 05 and 07, `docs/testing/README.md`,
  `method/METHOD.md` and `evals/conformance/README.md` were updated
  in the same pass as the behaviour they describe, and the
  "eleven hazards" count was corrected to thirteen in the four live
  documents that state it.

### Added by pass 0033

26. **Skill-line candidate: a StrictMode property read drops the
    object instead of erroring.** Run 007 D-1. `Get-AzDoRepository`
    read `$repo.defaultBranch` directly; a repository with no commits
    has no such property *at all*, so under
    `Set-StrictMode -Version Latest` the read threw, the pipeline
    swallowed the terminating error per object, and four repositories
    came back where five exist — with no gap in the output. Test
    `PSObject.Properties[...]` before reading, and mock the missing
    property by *omitting* it: an object that sets it to `$null` does
    not reproduce the failure. Candidate line for
    `powershell-module-analysis` or the AzDO client skill.
    **Skill edits are not this pass's work** — recorded, not taken.
27. **Skill-line candidate: `Join-Path` on an already-rooted path.**
    Run 007 D-2. `Join-Path (Get-Location) $Path` produces
    `C:\here\C:	here` when `$Path` is absolute. Every use in that
    run passed a relative path so it never fired; the first absolute
    path came from `$TestDrive`. Test `IsPathRooted` first, and
    resolve against `(Get-Location).ProviderPath` rather than the
    process working directory, which PowerShell does not keep in step
    with `Set-Location`. Candidate line for
    `powershell-module-commands`. **Recorded, not taken.**
28. **`.claude-plugin/` carries three version strings, not one.**
    `plugin.json.version`, `marketplace.json.metadata.version` and
    `marketplace.json.plugins[0].version`. `Publish-Local.ps1`
    enforces agreement between the first and the third and ignores
    the second. Pass 0033's prompt pinned the release to "the single
    version line" and there is no single version line; bumping only
    `plugin.json` makes the committed-marketplace validator go red,
    which was observed before all three were bumped together. Either
    derive the marketplace versions from the manifest at validation
    time, or state the three-line rule wherever the one-line rule is
    currently written.

### Resolved by pass 0034

- Item **9** (the three `tf-<role>` skills deliberately not written):
  **CLOSED.** All three are written and released at v1.1.0 —
  `tf-hcl-parse`, `tf-module-resolve`, `tf-graph-assembly`. The
  objection that closed them was that they carry fixture 1's answers
  and tf-003 would be scored against fixture 1. **Decision 0014
  removed the premise rather than the objection:** tf-003 now targets
  fixture 2, which was authored in pass 0034, after tf-001 and tf-002
  had run and after their findings were written down. Nothing that
  produced those findings has seen it.

  Every line in the three cites a recorded failure —
  `runs/tf-001-first-build/findings.md` B-1/B-2/B-3 and D-1,
  `runs/tf-002-convention-and-case3/findings.md` D. Nothing
  speculative, and no fixture-specific ids appear in any of them.

  **The three are unmeasured, and the CHANGELOG says so in those
  words.** No run has yet scored a Terraform build with them readable
  against one without. tf-003 is that run.
- Item **6** (tf-003, operator decision first): the **decision half is
  done**; the item stays open for the run. Restated above.
- Item **26** (StrictMode absent-property read): **CLOSED.** Landed in
  `skills/azdo-rest/SKILL.md` as *"Read a response property that may
  not be there, or lose the object"*, including the half that matters —
  the regression test must mock the failure by **omitting** the
  property, because an object setting it to `$null` does not reproduce
  it.
- Item **27** (`Join-Path` on an already-rooted path): **CLOSED.**
  Landed in `skills/powershell-module-scaffold/SKILL.md` as *"A command
  that takes a `-Path` must handle an absolute one"*, with both halves:
  the `IsPathRooted` test, and resolving against
  `(Get-Location).ProviderPath` rather than the process working
  directory.
- Item **28** (three version strings, not one): **honoured, not
  closed.** All three were bumped together and `Publish-Local.ps1`
  validated the pair it enforces. The item stays open because the
  underlying defect — the validator ignores
  `marketplace.json.metadata.version` — is unchanged; this pass
  followed the rule rather than fixing the tooling.
- Item **19** (doc maintenance as a standing obligation):
  **honoured, and it stays open.** Chapters 02 (a new stage 3b, the
  second fixture, and its dependency line), 04 (how the chatty-fixture
  story ended and what it cost), 07/08/09 (the skill count, and
  chapter 09's transcript left as captured with its date stated), and
  `docs/testing/README.md` (a sixth layer, the fixture comparison
  table, and the sanitization gate) were updated in the same pass as
  the behaviour they describe.

### Added by pass 0034

29. **There is no fixture-2 counterpart to
    `evals/tf/Test-TfFixtureCase.ps1`.** That script scores a produced
    graph case by case against fixture 1 and is fixture-1 specific
    throughout. Pass 0034's prompt named only `Compare-TfGraph.ps1`
    and `Mutate-TfGraph.ps1` for wiring, so it was left alone rather
    than half-generalised. **tf-003 needs one**, and it needs the same
    control tf-002 gave the original: score it against a graph known to
    be wrong in one case and confirm it fails exactly there. Recorded,
    not taken.
30. **Skill-line candidate: a function that comma-wraps its array
    output, called inside `@(...)`, silently returns one element.**
    Found in this pass, in `Test-FixtureSanitization.ps1`. The idiom
    `, @($items | Sort-Object …)` exists to stop a single-item result
    unrolling; combined with a caller that writes `@(Get-Thing …)` it
    produces a one-element array **holding an array**. `.Count` reads 1,
    which looks like one finding, and the first property access throws
    *"The property 'X' cannot be found on this object"* — an error that
    points at the consumer and not at the producer. Pick one of the two
    conventions per function and say which in the function's comment.
    Candidate line for a PowerShell authoring skill. **Recorded, not
    taken.**
31. **Fixture 2 has pipeline YAML files but no AzDO pipeline
    definitions.** Fixture 1 has four definitions, created by pass 0023
    and never queued; fixture 2 has four YAML files in its repositories
    and zero definitions, because pass 0034's plan asked for repository
    creation and a push and nothing else. A producer that reads
    pipelines from the **REST API** rather than from repository files
    therefore sees fixture 1 and not fixture 2, which is an asymmetry
    between the two instruments. Decide before tf-003 whether the run
    reads pipelines from files or from the API; if from the API, the
    four definitions have to be created first, and creating them is a
    change to a frozen fixture and therefore a new decision.

32. **`Compare-TfGraph.ps1` cannot see a duplicate node id, and a
    producer that emits one scores clean.** Found by falsifying pass
    0034's own `verify.ps1`: a probe written to prove that duplicating
    a node turns the oracle-vs-self control red **did not fire on the
    control**. Both graphs are keyed into an ordered dictionary by id
    (`$expectedById[[string]$node.id] = $node`, and the same for the
    actual), so a duplicated id overwrites its own entry on both sides
    and the staged matching never sees it.

    Demonstrated directly, not inferred: the fixture-2 oracle with one
    node appended twice returns

        IsMatch: True   DifferenceCount: 0   ActualNodeCount: 100

    against an `ExpectedNodeCount` of 99. **The evidence is printed in
    the diff header the whole time** — `expected: 99 node(s)` above
    `actual: 100 node(s)` — and the verdict is still clean, which is
    the worst combination: a reader who trusts the verdict never reads
    the header.

    **Not fixed in 0034, and the reason is a rule.** The tag was
    already pushed; `Compare-TfGraph.ps1` is a scoring instrument, and
    fixture 1's falsification report is byte-pinned against
    `plans/0030-release/mutations.txt`, so adding a category is a
    change that has to be re-falsified against both fixtures in a pass
    that owns it. **No current score is affected** — both oracles are
    verified duplicate-free by pass 0034's verify check 1e.

    **It matters for tf-003**, which scores a producer's graph rather
    than an oracle, and where a node emitted twice is a plausible
    defect. Either add the check (an `id` seen twice is its own
    category, so it reads as one defect) or assert
    `ActualNodeCount -eq ExpectedNodeCount` alongside `IsMatch` in the
    run's own scoring step. Belongs to the next pass that opens
    `evals/tf/Compare-TfGraph.ps1`.

### Numbering, reconciled by pass 0030

Pass 0031 recorded a 17→19 drift and asked that numbers never move. This is
the sequence as it actually stands, so the next pass does not have to
re-derive it:

- **1–12** exist as numbered entries.
- **13 does not exist and never did.** No entry was ever written under that
  number. It is cited once — in *Resolved by pass 0029*, as "Items 12 / 13 /
  14" — because its intended wording was absorbed into item 12 before either
  was written down, and it landed in `evals/HARNESS.md` as hazard 10. The gap
  is left open on purpose. Closing it would move 14 and every number above it.
- **14–22** exist as numbered entries.
- **23, 24 and 25 were consumed by pass 0032**, and all three were
  **resolved by pass 0033**.
- **26, 27 and 28 were consumed by pass 0033**; 26 and 27 were
  **resolved by pass 0034** and 28 remains open.
- **29, 30, 31 and 32 were consumed by pass 0034**; **33 is the next
  free number.** 32 was written late in the pass, after `verify.ps1`'s
  own falsification produced a probe that did not fire for the reason
  it was written to prove. Pass 0030 consumes none: everything it
  touched was already numbered.

Numbers are consumed, never reused and never renumbered — including the ones
belonging to resolved items, which stay where they are so that a citation
written against them keeps resolving.

**Precondition note for any pass written against the four-path pin.**
Pass 0031's prompt asserted that
`git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/` is
empty at start. It was not, and has not been since pass 0029 — see the
Pins section above, which already prescribes the three-path form. The
second consecutive prompt to carry the stale form. Pass 0031 changed
nothing under any of the four paths; its `verify.ps1` asserts that
directly rather than asserting the pin the prompt named.
