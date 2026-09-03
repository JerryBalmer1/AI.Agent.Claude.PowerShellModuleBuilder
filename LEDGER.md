# LEDGER — maintained by the agent as the last task of every pass

The chat context points here; this file is the source of truth
for counters and pins. Update it in the same commit as the work
that changes it.

## Passes
Last landed: **0038**. Next: the operator's. The generalisation claim
still has the number and the bound 0037 gave it; the two things that
would move it are unchanged — a plugin-off control on the Terraform
domain (backlog 42) or a third domain the `tf-*` skills say nothing
about.

0038 is a light-tier cross-repo claim sync and released **no harness
tag**. Nothing under `skills/`, `commands/`, `.claude-plugin/` or
`evals/` changed. What it did was carry the measurement history to the
four sibling repositories the measurements were about, which had never
received it.

**PSAzureDevOpsGraph, tagged `v0.3.0`** (annotated, pushed, `main`
fast-forwarded `5fd814b..fdf4a27` per decision 0008). The README's
`Status` section — three run-002 numbers and nothing else — is replaced
by *How this module was measured*: run 002 labelled as not a zero-skill
baseline, the 004–006 ladder, the 007 control, the sentence the control
forced, and the three bounds, each figure linking its run record. New
`docs/HANDOFF.md`, which decision 0010 has required of every governed
repository and which this repository never had. `docs/worklog/v0.3.0.md`
states why a docs-only minor exists. **Module code is byte-identical to
`v0.2.0`** and the worklog asserts it with the diff and its exit code.

**PSTerraformGraph**, no tag (`main` fast-forwarded `1dd4913..80fc6bb`
per decision 0010; a docs sync earns no minor on a module's semver).
The HANDOFF said *"Nothing here has met configuration it was not built
for"* and that the blind run *"is not yet scheduled"*. tf-003 had
happened. Both files now separate the two measurements rather than
blending them: tf-002 scored the shipped code on a visible oracle, and
tf-003 scored a module **built fresh from the seed** in an orphan branch
that never read this repository — so its 6/7 → 7/7 says nothing directly
about `main`. The plugin bound travels with the number in both files.

**PSGraphRenderToHtml and PSGraphRender**, one commit each, mains
fast-forwarded `20877f7..ac76bc4` and `2231b4b..a4c18c0`.

### The gap this pass exists to close, and it is standing

**The measurement line updates a claim in the harness and leaves the
repository the claim is about saying the old thing.** Every run from 003
to tf-003 landed its numbers here and in `runs/`, and no run moved a
sibling README. Five runs accumulated before PSAzureDevOpsGraph's own
landing page mentioned any of them, and PSTerraformGraph's HANDOFF was
asserting an unseen fixture had never been met two passes after one had.

**Standing instruction: a pass that produces a measured result adds a
LEDGER line naming which sibling READMEs and HANDOFFs its result
stales.** Not a fix for the result's own pass to make — a measured run
should not be editing deliverable-line documents in the same session it
is being scored in — but the next docs pass then has a list rather than
a memory.

**Pass 0038 found the second half of the same gap by tripping over it.**
`PSGraphRenderToHtml` and `PSGraphRender` each had a pass-0024 commit
pushed to `origin/pass-0024-consumer-ref` and never merged: the mains
had been sitting a commit behind since. One of them was the tf-002
currency update this pass was about to write from scratch. 0038 branched
from those tips rather than from `main`, so both are now on `main` and
nothing was stranded or rewritten — every push in this pass was
fast-forward-only. **A pass that pushes a branch and does not move the
main is not finished, and nothing in this project was checking.**

0037 is a consolidation pass and released **v1.1.1**, a PATCH: `skills/`
and `commands/` are byte-identical to v1.1.0 and `git diff
v1.1.0..v1.1.1 -- skills/ commands/` is empty. It did four things.

**Promoted the fixture-2 case scorer** out of `plans/0036-tf-003/` to
`evals/tf/fixture2/Test-TfFixture2Case.ps1`, with its falsification
beside it, closing backlog 29 and the scorer half of 36. Fixture 1's
scorer was left alone on purpose — it is the instrument tf-001 and
tf-002 were scored with.

**Corrected `cases.md` case 6** (backlog 40), and the correction is to
the PROSE: ten nodes satisfy the unscoped "with neither" clause, so the
oracle failed its own case. `expected-graph.json` and the fixture
repositories are untouched. The rewritten discriminator is **stricter**
and that is demonstrated rather than asserted — a graph the plans-era
form scores 7 / 7 the promoted form reddens. The scorer also now
**refuses a duplicated node id** instead of scoring it, which is the
scorer-side half of the blindness backlog 32 found in the comparator.

**Re-scored tf-003 with the promoted scorer**, from fresh built clones
of both of the run's own commits, graphs regenerated from read-only
fixture clones at their decision-0014 SHAs. **Every number held** —
6 / 7 first shot, 7 / 7 final, 184 → 0 differences, 99/99 and 88/88 —
and the regenerated final graph is byte-identical to the `graph.json`
the record ships. The run record is **appended to, never rewritten**.

**Stated the bounded claim in the README** (backlog 36): the result and
the bound in the same breath, with tf-003 joining tf-001 and tf-002 in a
footnoted comparison table and a standing warning that the raw counts do
not compare across the three.

Its own instrument change is the one to watch: the fixture-2 suite gained
a second layer and was **re-pinned 8 → 18**, deliberately, with both new
checks broken on purpose and seen red before the 18 was trusted
(`plans/0037-consolidation/case-layer-falsification.txt`). Fixture 1 is
still 15.

0036 **ran tf-003**, the first genuinely blind measurement in this
project: plugin v1.1.0 readable, fixture 2 and its oracle unread until
the built module was pushed, PSTerraformGraph's existing code unread in
both phases. **battery 7/7; 184 differences → 0 in one iteration of
three; functional-tf 6/7 first shot → 7/7 final; node and edge counts
99/99 and 88/88 at first shot and never moved.** All 184 first-shot
differences were four naming conventions and none was structural. The
run record states, and the README rewrite must carry, that this is
**not yet a generalisation result**: v1.1.0's three `tf-*` skills were
written from tf-001 and tf-002 and cite their findings by count, so the
fixture was unseen but the mechanism catalogue was not — exactly the
contamination tf-002 predicted when it left those skills unwritten.

0036 also closed the instrument gap it walked into: **fixture 2 had no
case scorer** (backlog 29), so `functional-tf: N / 7` had nothing to
come from. One was written and falsified, but it lives under `plans/`
because 0036 may not touch `evals/` — see backlog 36.

0035 is a harness-only pass and released nothing; `git diff
v1.1.0..main -- skills/ commands/ .claude-plugin/` is empty and its
`verify.ps1` asserts that directly. It did the three things that stood
between pass 0034 and a measurement: **repaired the comparator's
blindness to duplicate node ids** (backlog 32, Stage 0 plus a
two-directional falsification), **settled the pipeline-definition
question in decision 0014** rather than in a plan (backlog 31), and
**authored the tf-003 kit** — `evals/tf/BRIEF.md`, `evals/tf/seed/`,
`Reset-TfTarget.ps1` — gated by a new `-RuleSet Kit` for the
sanitization scanner whose strong control is the Azure DevOps kit at
41 findings. Both fixture suites returned at their pinned counts and
the fixture-1 sanitization control is still 94: detection was added
and nothing was weakened.

Its two own mistakes are items 33 and 34, both found by the work
rather than by review, and both written up in
[journal 0035](journal/0035-tf003-kit.md).

0034 is a constructive pass: it took decision
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
Terraform (runs/tf-NNN-*): **tf-003 COMPLETE (pass 0036).** Nothing
scheduled after it.

**tf-003 — the blind generalisation measurement**
(`runs/tf-003-generalisation`, target branch
`run-tf-003-generalisation`, first shot `d788f7c`, final `d76d16b`,
session `692109bc-018c-4288-8b36-db3e3737cc01`, plugin surface
`v1.1.0` present and **READ**): build exit 0; module tests 96/96,
coverage 92.39% (target 70%); battery **7/7**; comparator **184
differences → 0**; functional-tf **6/7 first shot → 7/7 final**; one
iteration of three used; phase 1 **31 minutes**, parallelism 1.
Nodes 99/99 and edges 88/88 **at first shot**, never moved — all 184
first-shot differences were four naming conventions (`label` 94,
`varType`-vs-`type` 70, `resolved` 12, unresolved-node id 8) and none
was structural. Case 7 is the only first-shot FAIL and it failed on
the id convention alone; the run record states the alternative reading
that would score it 7/7 blind rather than choosing the flattering one
silently.

**The bound travels with the number.** v1.1.0 contains three `tf-*`
skills written from tf-001 and tf-002 that cite those runs' mechanisms
and counts. The fixture was unseen; the mechanism catalogue was not.
What tf-003 establishes is that a plugin carrying a domain's recorded
findings stops those findings recurring on a fresh fixture in that
domain. It does **not** establish generalisation, and the drafted
README sentence in the run record says so.

The historical note below is kept because it is what the run was
scored against.

Fixture 2, the target — **as set up by pass 0034:** Pass 0033 scanned fixture 1 for
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
- comparator `Compare-TfGraph.ps1` **as repaired by pass 0035** — it
  now refuses to call a graph a match while any node id is ambiguous;
  the mutator, the falsification driver, the publisher and the
  read-back take `-Fixture fixture2`;
- the kit: `evals/tf/BRIEF.md` and `evals/tf/seed/`, at the Pins
  blob and tree below. `Reset-TfTarget.ps1 -Destination
  scratch/runs/tf-003` is how a run starts;
- plugin surface pinned at **v1.1.0**, which is the first release
  carrying the three `tf-*` skills. Pinning v1.0.1 measures a plugin
  with no Terraform skills in it and is a different question.
- **`evals/tf/Test-FixtureSanitization.ps1 -Fixture fixture2` must be
  clean at the run's preconditions.** It is the gate that says the
  instrument is still mute.

**One of the two gaps pass 0034 left is closed.** `Compare-TfGraph.ps1`
now detects a duplicate node id as its own category, on either side,
and `IsMatch` cannot be true while one exists — so the workaround that
entry recommended (`ActualNodeCount -eq ExpectedNodeCount` beside
`IsMatch`) is **not** needed and should not be written: it is a proxy
that reads clean on a graph with one node duplicated and one missing.
See *Resolved by pass 0035*.

**The other was closed by the run itself.** A fixture-2 counterpart to
`Test-TfFixtureCase.ps1` did not exist (**backlog 29**), so pass 0036
wrote `plans/0036-tf-003/Test-Tf003Case.ps1` — same shape as fixture
1's, the oracle's literal ids, falsified seven ways, one mutation per
case, plus a control run of the oracle against itself. **Promoting it
into `evals/` is backlog 36**, and until then a fixture-2 run has to
carry its own scorer, which is exactly the kind of thing that goes
stale.

**Pass 0037 promoted it, and re-scored this run with it.** The promoted
scorer is not the same instrument: its case 6 is corrected and stricter,
and it refuses a duplicated node id rather than scoring it. So the
numbers above were re-derived rather than re-read — fresh built clones of
`d788f7c` and `d76d16b`, graphs regenerated from read-only fixture
clones. **Every one held**, and the regenerated final graph is
byte-identical to the recorded `graph.json`. The scores in this section
therefore stand under an instrument stricter than the one that produced
them. `plans/0037-consolidation/tf-003-rescore.txt`, and a dated
correction note appended — never rewritten — to the run record.

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
PSAzureDevOpsGraph: **v0.3.0** (docs-only minor, pass 0038, decision 0006;
module code byte-identical to v0.2.0. Next touching plan: v0.4.0)
PSGraphRender: v0.13.0
PSGraphRenderToHtml: v0.1.0 (next: v0.2.0)
PSTerraformGraph: v0.2.0
psmodule manifest: **1.1.1**, released and tagged `v1.1.1` by pass 0037
under decision 0013. **PATCH, and the installed surface does not move:**
`git diff v1.1.0..v1.1.1 -- skills/ commands/` is empty and every changed
line under `.claude-plugin/` is a version field, both asserted by that
pass's `verify.ps1`. What the release carries is a claim change — 1.1.0's
CHANGELOG said the three `tf-*` skills were **unmeasured**, and tf-003
measured them. The 1.1.1 entry states the result and the bound in the
same breath, and also records the `cases.md` correction even though it
changes no installed file.

Previously **1.1.0**, released and tagged `v1.1.0` by
pass 0034 under decision 0013. **MINOR, and the first release since
v1.0.0 to change `skills/`:** three new `tf-<role>` skills, plus two
hardening lines added to `azdo-rest` and
`powershell-module-scaffold`. `commands/` is byte-identical to
`v1.0.1` and `git diff v1.0.1..v1.1.0 -- commands/` is empty. The
seventeen-skill count is now stated in `README.md`, `SECURITY.md` and
chapters 07/08/09; the *fourteen* that remain in ablation sentences
are deliberate and refer to the roster the ladder measured.

**The tag names `df63806`, one commit behind the pass tip `3b66366`** —
the third consecutive release to diverge this way, and for the same
reason every time: `verify.ps1`'s falsification can only be
transcribed after it has run, so the commit recording it necessarily
lands after the commit being tagged. Here that later commit also
carries **backlog 32**, a comparator defect the falsification found.
The tag is a complete release; the later commit is plan artifacts, a
LEDGER entry and a corrected probe description, and touches nothing
under `skills/`, `commands/` or `.claude-plugin/`. A pushed tag is not
moved. **This is now a pattern rather than an accident, and the
cheapest fix is ordering** — run the verify falsification before the
release commit, so the tag can name the tip.

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

Harness main: fast-forwarded to the `pass-0035-tf003-kit` tip at
pass 0035's close, per decision 0009. Before that: pass-0028-run-006
tip, fast-forwarded at pass close,
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
none`, and nothing was ever queued. Backlog 31 asked whether that
asymmetry had to be repaired before tf-003; **pass 0035 settled it as
an amendment to decision 0014 — pipeline definitions are outside the
TF measurement surface**, and no definitions are to be created.

**The tf-003 kit (pass 0035).** What a builder is handed for the
Terraform measurement line, pinned so a run can prove it was handed
the same thing this pass wrote:

  tf-003 brief blob: dc25fcd0d1e4d5651073240374ee19c28499c70e
  tf-003 seed tree:  040ab2503aa7ccd5d67500d2e1d9983818807d86

`git rev-parse <commit>:evals/tf/BRIEF.md` and
`git rev-parse <commit>:evals/tf/seed` re-derive both. **The seed tree
is derivable a second, independent way:** `Reset-TfTarget.ps1`
materialises the seed into a fresh `git init` and the commit it makes
carries that same tree, because a tree object is a function of the
bytes and names and nothing else. The two agreeing is what says the
thing on disk and the thing a run starts from are the same thing.

**What tf-003 actually used (pass 0036).** Both pins re-derived by
`git ls-tree` at the start of the run and checked against the two lines
above **after the gate lifted**, `LEDGER.md` being forbidden reading in
phase 1. Both matched. The pass prompt's copy of the brief pin arrived
**unsubstituted** — literally `<BRIEF-BLOB-FROM-0035>` — so the derived
value is the one that was used; a prompt is not a pin.

  tf-003 target, first shot: d788f7c7ecb1aa471eea01de6878d253df4c4ae4
  tf-003 target, final:      d76d16bb5083f422ccc05671e21cefde3c1a004e
  fixture-2 oracle tree:     f470ed8561c69e3d04b4560f3e56f49d4a672f81

Both target SHAs are on `run-tf-003-generalisation` in PSTerraformGraph,
an orphan branch sharing no history with that repository's `main`, which
stayed at `1dd4913` with tags `v0.1.0` and `v0.2.0` untouched. The
oracle tree is recorded because phase 1 established the oracle's
**identity** by `ls-tree` without ever opening it.

The seed COMMIT is `81ba3e97adc0fcf048da631828d1cbbb6e202c17` and is
reproducible, unlike the AzDO seed's — see item 16, which is why
`Reset-TfTarget.ps1` pins **both** git stamps rather than passing
`--date`. It is recorded, not pinned: the tree is what the pin is
about, and a check written against the commit would fail for reasons
that are not about the seed.

**TF comparator, post-repair (backlog 32):**

  Compare-TfGraph.ps1   6475606ab7c5767fb1b4aa5f4b0d221abbd0c8c3
  Mutate-TfGraph.ps1    012ca8fab4da96a2f5122ad04a1f74aa5a6f7c68

Stage 0 asserts node-id uniqueness on both graphs before anything is
keyed. Falsified in both directions by
`Invoke-TfDuplicateIdFalsification.ps1` →
`plans/0035-tf003-kit/mutation8.txt`. Both fixture suites re-run at
their pinned counts → `plans/0035-tf003-kit/suites.txt`.

**Plugin pin, unchanged by pass 0035: `v1.1.0` =
`df638064e9f77111cb4f7d290d39f2b8f8b40415`.** Pass 0035 is harness-only
and released nothing; `git diff v1.1.0..HEAD -- skills/ commands/
.claude-plugin/` is empty and its `verify.ps1` asserts that directly.
The installed surface a tf-003 builder reads is therefore the one
v1.1.0 published.

**The fixture-2 case scorer (pass 0037).** Promoted out of `plans/` so a
run can find it. It is a scoring instrument like the comparator, so its
identity is pinned the same way:

  Test-TfFixture2Case.ps1                  evals/tf/fixture2/
  Invoke-TfFixture2CaseFalsification.ps1   evals/tf/fixture2/

Falsified in one report — `plans/0037-consolidation/case-scorer.txt`:
oracle-vs-self **7 / 7**, seven mutations each defeating its own case and
no other, mutation 8 **refused rather than scored**, and the corrected
case 6 demonstrated stricter than the plans-era form. The fixture-2 suite
line is **re-pinned 8 → 18** (oracle layer 8, case layer 10); fixture 1
is unchanged at 15. Both new checks were broken on purpose and seen red
before the 18 was trusted:
`plans/0037-consolidation/case-layer-falsification.txt`.

**tf-003, re-scored (pass 0037).** The run's numbers were taken with the
plans-era scorer, which has since been corrected and tightened, so they
were re-derived rather than re-read: fresh built clones of `d788f7c` and
`d76d16b`, graphs regenerated from read-only fixture clones at the
decision-0014 SHAs. **All held** — 6 / 7 → 7 / 7, 184 → 0, 99/99 and
88/88 — and the regenerated final graph is byte-identical to the
recorded `graph.json` (SHA256 `203e80a6…`).
`plans/0037-consolidation/tf-003-rescore.txt`.

**Plugin pin, moved by pass 0037: `v1.1.1`.** The tag names this pass's
release commit. `skills/` and `commands/` are byte-identical to `v1.1.0`,
so the *instrument* a Terraform run reads is unchanged and tf-003's
plugin pin still resolves to what it resolved to; what moved is the
version string and the claims around it.

## Backlog (priority order; operator reorders)
1. Runs 004-006 + 0029 final README
2. 0030 packaging: marketplace.json, cold-install proof
3. Fixture restore drill (Sync-Fixture restore direction)
4. Per-skill ablation runs (suspects first)
5. Mirror assertion + dependency-wave ordering (post-ladder)
6. **~~tf-003 — the blind Terraform run.~~ DONE by pass 0036.** See
   *Runs* above for the one-line result and `runs/tf-003-generalisation/`
   for the record. It did not settle the generalisation claim; it
   produced a number and named what still contaminates it.
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
31. **~~Fixture 2 has pipeline YAML files but no AzDO pipeline
    definitions.~~ CLOSED by pass 0035 — see *Resolved by pass 0035*.**
    The original entry stands below, unedited, because a closed item
    whose text is rewritten stops explaining why it was open.

    Fixture 1 has four definitions, created by pass 0023
    and never queued; fixture 2 has four YAML files in its repositories
    and zero definitions, because pass 0034's plan asked for repository
    creation and a push and nothing else. A producer that reads
    pipelines from the **REST API** rather than from repository files
    therefore sees fixture 1 and not fixture 2, which is an asymmetry
    between the two instruments. Decide before tf-003 whether the run
    reads pipelines from files or from the API; if from the API, the
    four definitions have to be created first, and creating them is a
    change to a frozen fixture and therefore a new decision.

32. **~~`Compare-TfGraph.ps1` cannot see a duplicate node id, and a
    producer that emits one scores clean.~~ CLOSED by pass 0035 — see
    *Resolved by pass 0035*.** The original entry stands below,
    unedited.

    Found by falsifying pass
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

### Resolved by pass 0035

- Item **32** (the comparator cannot see a duplicate node id):
  **CLOSED.** `Compare-TfGraph.ps1` gained a Stage 0 that asserts id
  uniqueness on **both** graphs before the first assignment into a
  dictionary. A duplicate is its own category, `DuplicateId`, naming
  every duplicated id and which side carries it — neither copy is the
  extra one, so reporting it as `ExtraNode` or `WrongAttribute` would
  name a defect that is not the defect. `IsMatch` states the check a
  second time rather than resting on the difference count, so a later
  change that filtered the list cannot quietly restore the blindness.

  The item offered two repairs — a category, or asserting
  `ActualNodeCount -eq ExpectedNodeCount` in the run's scoring step.
  **The category was taken, and the count assertion was not, on
  purpose.** The counts are equal in the case that matters least: a
  graph with one node duplicated and one node missing has the right
  total and two defects, and a count check calls it clean. Uniqueness
  is the property; the count is a proxy for it that is wrong in exactly
  the situation a scoring run will meet.

  Mutation 8 (`duplicate-id`) duplicates a node byte-identically —
  identical so the detection names one mechanism rather than two — and
  is **two-directional**, so it is falsified by its own script rather
  than folded into the seven-mutation driver.
  `Invoke-TfDuplicateIdFalsification.ps1` →
  `plans/0035-tf003-kit/mutation8.txt`: detected on the producer side
  and on the oracle side, with both clean oracles matching themselves
  before and after. The driver's own report now says it covers seven of
  eight, so a green there is not read as a falsified comparator.

  **Nothing was weakened.** `plans/0035-tf003-kit/suites.txt`:
  `FIXTURE1: 15 passed, 0 failed` (the count is pinned, and a suite
  that gained or lost a test is itself reported as a failure) and
  `FIXTURE2: 8 passed, 0 failed` — one control plus seven mechanisms.
- Item **31** (fixture 2 has pipeline YAML but no AzDO definitions):
  **CLOSED, by narrowing rather than by building.** Amendment to
  decision 0014: *pipeline definitions are outside the TF measurement
  surface.* The asymmetry is real in the Azure DevOps project and empty
  in the measurement — checked rather than assumed: both oracles hold
  six node types, all of them HCL, and **zero** pipeline nodes, while
  both fixtures carry four pipeline YAML files as content. Fixture 1's
  four definitions are an artifact of the order pass 0023 did things
  in, not part of what tf-001 or tf-002 scored.

  Creating four more would have bought parity in a dimension no oracle
  reads, at the cost of editing a fixture decision 0014 froze. The
  amendment also closes the cheap path in advance: a capability that
  reads definitions through the REST API gets its own fixture decision
  before it gets a run.
- Item **6** (tf-003): the last thing blocking it is gone. The
  instrument is repaired, the kit exists and is pinned, and the
  definition question is answered. **tf-003 is the next run**, and it
  targets fixture 2. It is not run by this pass — a pass that authored
  the brief cannot be the session that builds against it.
- Item **16** (`Reset-Target.ps1` stamps wall-clock dates): **half
  taken.** The new `Reset-TfTarget.ps1` pins both git stamps, so its
  commit SHA is reproducible as well as its tree; `Reset-Target.ps1` is
  **left alone on purpose**, because runs 004–006 were produced by it
  and changing it would change an instrument three recorded runs were
  measured with. The item stays open for the AzDO line.

### Added by pass 0035

33. **`git commit --date=` pins only the AUTHOR date.** The committer
    date still comes from the wall clock and a commit SHA is a function
    of both, so a "reproducible" seed commit written with `--date`
    alone drifts as soon as a second passes. Worse, the obvious probe
    hides it: two resets run back to back agree with each other for
    exactly as long as the clock takes to tick. Found in this pass, in
    `Reset-TfTarget.ps1`, by resetting twice with a gap rather than
    without one. Set `GIT_AUTHOR_DATE` **and** `GIT_COMMITTER_DATE`, and
    check the mechanism — read the stamps back — rather than comparing
    two SHAs made in the same second. Skill-line candidate for a git or
    PowerShell authoring skill. **Recorded, not taken.**
34. **A file that matches no extension rule falls to `* text=auto` and
    checks out CRLF on Windows.** The root `.gitattributes` already
    carried this lesson for `evals/functional/seed/`, and
    `evals/tf/seed/LICENSE` walked into it anyway: `git ls-files --eol`
    showed `attr/text=auto` with no `eol`, so a fresh Windows clone
    would have produced different bytes and a different seed tree from
    the one pinned above. The rule exists; what was missing was
    **applying it to the new directory**. Any pass adding a seed, a
    fixture or anything else copied byte-for-byte should run
    `git ls-files --eol` over it before pinning anything derived from
    its bytes. **Recorded, and the rule was added.**
35. **The kit rule set's allowlist has the same decay risk as the
    fixture one, and one fewer control.** `-RuleSet Kit` is falsified
    two ways today — a planted line, and 41 findings against the Azure
    DevOps kit — but the AzDO kit is frozen, so that strong control can
    never get any stronger and will not notice a kit rule that stops
    firing. If a third kit is ever written, scan it with both rule sets
    and record the difference. **Recorded, not taken.**

### Added by pass 0036

36. **The README's generalisation section needs rewriting, and the
    sentence is already drafted.** `README.md` §"The cross-language
    measurement" still says tf-003 is *blocked* and that no
    generalisation claim exists. It has now run. The replacement
    sentence is written verbatim at the end of
    `runs/tf-003-generalisation/README.md` and claims what the run
    supports and no more. **This is a separate pass; 0036 did not touch
    the README.** The same pass should promote
    `plans/0036-tf-003/Test-Tf003Case.ps1` into `evals/tf/` — as
    `Test-Tf2FixtureCase.ps1` or by giving the existing script a
    `-Fixture` parameter — carrying its seven-mutation falsification
    and its oracle-against-itself control with it. A scorer living in a
    plan directory is one the next run will not find. **Closes the
    remaining half of backlog 29.**
37. **The plugin's two commands are written for the AzDO ladder's
    shape and do not fit a `tf` run.** `commands/build.md` step 1 says
    to read `evals/conformance/Conformance.Tests.ps1` and
    `evals/functional/BRIEF.md`; `commands/test.md` runs
    `evals/conformance/Invoke-Conformance.ps1` and reports a
    conformance score. For tf-003 the brief is `evals/tf/BRIEF.md` and
    there is **no conformance suite in the measurement at all**, so
    both commands were silent while every skill they delegate to
    carried over intact. Either generalise the two commands to take
    the eval suite as an input, or state in them that they are the
    AzDO ladder's entry points. Touching `commands/` moves the plugin
    surface and needs a version decision. **Recorded, not taken.**
38. **Skill-line candidate, and it is a defect in a published
    example.** `powershell-module-build`'s `Resolve-BuildDependency`
    ends `Write-Build Green "..."` then `$resolved`. **InvokeBuild's
    `Write-Build` writes to the OUTPUT stream** — colour is all it adds
    — so the function returns a two-element array and the caller's log
    line silently vanishes from the build output. Assigning that to a
    path fails three tasks later with `Cannot find drive '  PSGraph…'`
    and nothing points at the resolver. Hit in this pass. The fix is
    one line: return an object and let the caller print. **Recorded;
    the skill is pinned at v1.1.0 and was not edited.**
39. **Skill-line candidate: a Pester gate that reads a null result
    cannot fail.** `Invoke-Pester -Configuration` returns nothing
    without `$cfg.Run.PassThru = $true`. The coverage gate then rounds
    `$null` to 0 and compares it against a `$null` target — false — so
    it passes on every run, and the `PreTag` guard fails on every run
    for the mirror reason. It printed `Line coverage: 0% (target %)`
    for one build; the exit code said nothing.
    `powershell-module-build` gives the gate's shape and the assertion
    that grades it, and neither catches this. **Recorded, not taken.**
40. **`cases.md` for fixture 2 overstates case 6.** It calls the unused
    variable *"the only node in the fixture with neither"* an incoming
    nor an outgoing edge. Read literally that is false of the oracle:
    three `repository` nodes and six `provider` nodes have neither
    either, because they take part in containment rather than value
    flow. Scoped to `variable`/`local`/`output` the claim holds
    exactly. Caught by scoring **the oracle against itself**, which
    came back 6/7 before the scorer was corrected. `cases.md` is
    fixture-2 case knowledge and 0036 may not touch `evals/`; the
    wording wants one clause. **Recorded, not taken.**

### Resolved by pass 0037

- Item **29** (no fixture-2 counterpart to `Test-TfFixtureCase.ps1`):
  **CLOSED.** `evals/tf/fixture2/Test-TfFixture2Case.ps1`, promoted with
  its falsification and wired into `Invoke-TfSuite.ps1`; the control the
  item asked for is the oracle scored against itself, 7 / 7.
- Item **36** (README generalisation rewrite, and promote the scorer):
  **CLOSED, both halves.** The README states the claim and its bound in
  the same breath, with tf-003 in a footnoted comparison table; the
  scorer is promoted. Taken as a file rather than as a `-Fixture` switch
  on fixture 1's scorer, which the item offered as the alternative:
  fixture 1's is the instrument tf-001 and tf-002 were scored with, and
  the two fixtures' cases differ in substance, not only in ids.
- Item **40** (`cases.md` overstates case 6): **CLOSED, in the prose.**
  The clause is scoped to value flow, the superseded wording is struck
  through rather than deleted, and the oracle and the fixture are
  untouched. The rewritten discriminator is **stricter** — it pins the
  whole edgeless set by id — and the strictness is a falsification row,
  not an assertion, because a correction that makes a case easier to
  pass cannot be told from abandoning it.

### Added by pass 0037

41. **The plugin's two commands do not fit a `tf` run, and fixing it is
    a v1.2.0.** This is item **37** promoted from "recorded, not taken"
    to a named release candidate, because 0037 is the pass that had the
    evidence and could not act on it: `commands/` is installed surface,
    and 0037 is a PATCH whose whole claim is that `skills/` and
    `commands/` are byte-identical to v1.1.0. Touching either would have
    made the release a MINOR and put the plugin-pin story for tf-003 in
    question in the same pass that was re-scoring it. **The work, when a
    v1.2.0 opens:** `commands/build.md` step 1 names
    `evals/conformance/Conformance.Tests.ps1` and
    `evals/functional/BRIEF.md`; `commands/test.md` runs
    `evals/conformance/Invoke-Conformance.ps1` and reports a conformance
    score. Neither exists for a `tf` run — the brief is
    `evals/tf/BRIEF.md` and there is no conformance suite in that
    measurement at all. Either generalise both to take the eval suite as
    an input, or state in them that they are the Azure DevOps ladder's
    entry points. **The finding underneath it is the interesting half
    and should survive the fix:** every skill the two commands delegate
    to carried over to a second domain intact, and the commands did not.
    Skills generalised; entry points did not.
42. tf-004 plugin-off control: OPERATOR DECISION — one fresh session,
    plugin unread, fixture 2, ladder iteration budget; would convert the
    bounded claim's "or" into a measurement; costs one
    contaminated-forever session identifier and ~2–4h

    Stated as a decision rather than scheduled, because it is the
    operator's to take and because the cost is not only time: the
    session that runs it can never be used for a plugin-on run of the
    same fixture, and the identifier is spent permanently. It is the
    cheaper of the two things that would move the generalisation claim —
    the other being a third domain the `tf-*` skills say nothing about,
    which needs a fixture, an oracle and a brief before it needs a run.
    **The ordering lesson is already recorded** in chapter 02 stage 7b:
    a control is decided before the plugin-on numbers exist, because
    afterwards it is decided while looking at a result one would like to
    keep. This project got that ordering wrong, and this line is what
    that mistake looks like written down.

### Added by pass 0038

43. **A measured result stales sibling documents and nothing names
    which.** STANDING. Every run from 003 to tf-003 wrote its numbers
    into `runs/` and the harness README, and not one of them recorded
    which sibling `README.md` or `docs/HANDOFF.md` its result had just
    made false. The cost was visible by 0038: PSAzureDevOpsGraph's
    landing page still quoted run 002's three scores and nothing else
    after five further runs, and PSTerraformGraph's HANDOFF was still
    saying *"Nothing here has met configuration it was not built for"*
    and that the blind run *"is not yet scheduled"* two passes after
    tf-003 ran.

    **The instruction, and it is deliberately not "fix it in the same
    pass":** a pass that produces a measured result adds one LEDGER line
    naming the sibling documents its numbers stale. A measured run must
    not be editing deliverable-line documents in the session it is being
    scored in — that is the two-lines rule, and it is worth more than
    the convenience. The next docs pass then works from a list instead
    of from a re-read of every sibling.

44. **A pass can push a branch, not move the main, and nothing notices.**
    STANDING, and it is the same gap one level down. 0038 found
    `PSGraphRenderToHtml` and `PSGraphRender` each holding a
    pass-0024 commit pushed to `origin/pass-0024-consumer-ref` and never
    merged; both mains had been a commit behind ever since, and one of
    those commits was the tf-002 currency line 0038 was about to write
    from scratch. Decisions 0009 and 0010 say the agent moves the mains
    at the end of a green pass. **Nothing checks that it happened.**

    0038 branched from those tips rather than from `main`, so both
    commits are on `main` now and every push in the pass stayed
    fast-forward-only. That is a repair, not a check. The check that
    would have caught it is one command per governed repository —
    `git for-each-ref --contains` against `main` over the `pass-*`
    branches, or simply `git branch --no-merged main` — and it belongs
    in whatever a future pass uses to verify its own close.

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
- **29, 30, 31 and 32 were consumed by pass 0034**; 31 and 32 were
  **resolved by pass 0035**, 29 and 30 remain open. 32 was written late
  in that pass, after `verify.ps1`'s own falsification produced a probe
  that did not fire for the reason it was written to prove. Pass 0030
  consumes none: everything it touched was already numbered.
- **33, 34 and 35 were consumed by pass 0035.** All three were found by
  the pass's own work going wrong rather than by review: a
  reproducibility claim that was true only within one second, a
  line-ending rule that existed and was not applied, and a control that
  cannot get stronger.
- **41 and 42 were consumed by pass 0037**; 0037 resolved 29, 36 and 40
  and consumed no number for any
  of its own work, because everything it did was already numbered — which
  is what a consolidation pass should look like. 41 is item 37 promoted
  to a named v1.2.0 candidate rather than a new finding, and it is
  numbered separately rather than edited into 37 so that a citation
  against 37 keeps resolving. 42 is written as an operator decision with
  its cost attached, including the cost that is not time.
- **43 and 44 were consumed by pass 0038**; **45 is the next free
  number.** Both are STANDING instructions rather than tasks with a
  done state: 43 is that a measured result must name the sibling
  documents it stales, and 44 is that nothing checks whether a pass
  actually moved the mains its governing decisions tell it to move.
  0038 repaired two instances of 44 and wrote no check for it, which is
  why it is numbered rather than closed.
- **36 to 40 were consumed by pass 0036.** 36 closes the remaining half of 29 and queues the README
  rewrite the run's own record drafts. 38, 39 and 40 continue the
  pattern above — each was found by this pass's work going wrong, and
  two of them are defects in things the pass was following rather than
  in what it wrote: a published skill example whose return value is
  polluted by its own log line, and a gate shape the skill states that
  passes on a null result. 40 was caught by scoring the oracle against
  itself, which is the control that exists for exactly that.

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
