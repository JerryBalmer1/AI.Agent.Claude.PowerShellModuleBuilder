# LEDGER — maintained by the agent as the last task of every pass

The chat context points here; this file is the source of truth
for counters and pins. Update it in the same commit as the work
that changes it.

## Passes
Last landed: **0047**. Next: the operator's. 0047 made a node link in
PSGraphRender **declared configuration** rather than a hardcoded scheme, and
released it as **v0.14.0** - the first change to that repository's `src/`
since the 0021 handoff. `LinkMode` is an Enum of `editor | hrefTemplate |
none` defaulting to `editor`, with `LinkHrefTemplate` beside it, both declared
as data in `Config/settings.schema.psd1`. **No new validator type and no
contract change**: `Enum` and `String` already existed, and every token
resolves from a field the view model already carries - checked against
`contract/viewmodel.schema.json` before any code was written, which is why
task 2's cross-repo stop never fired.

**The load-bearing decision was put to the operator rather than taken.**
Acceptance B's carve-out - no `vscode://` beyond the renderer's static UI
strings - is drawn precisely around the five `strings.psd1` messages and
precisely outside the one live scheme literal in `editor-link.js`. A runtime
branch leaves that literal in every shipped document, inert but present, and
fails B as worded. The operator ruled for **render-time slot selection**: the
acceptance's literal reading was achievable, so the implementation moved and
no acceptance text changed. `SlotsBySetting` in `templateset.psd1` now chooses
which files fill a slot, so a report carries one mode's code and not three.

**The no-regression control is what shaped the refactor, and it is the part
worth keeping.** An `editor`-mode document had to stay byte-identical to the
base for the same payload, which forbids code *moving* within the assembled
document - only into files re-inserted where it already sat. So the obvious
design, each mode exporting its actions and `menu.js` doing a `concat`, was
rejected: it changes bytes for no behavioural reason. `editor-link.js` split
into `link/common.js` plus one file per mode, carved by script and asserted
lossless before the original was deleted, and the menu entries, selection
action and diagnostics row became slots at their existing positions. The
result is a behaviour-preserving refactor **proved** byte for byte rather
than argued.

**A falsification probe disproved a claim the pass had written down.** P1b
asserted that flipping the shipped default would slip past the byte
comparison "because the mode is one value in one blob" - and the same
sentence sat in a test comment. True of a runtime design, false of this one:
assembly picks the files, so a flipped default moves the document body too.
Both were corrected. The byte comparison is stronger than it was credited
with being.

**The browser gate caught the only defect that would have shipped.**
`{relativePath}` first rendered as `src%2FPublic%2F...`; `encodeURIComponent`
over a whole path escapes its separators, which is right for a query value
and useless for a `/blob/main/{relativePath}` URL - the single case the
feature exists for. Every PowerShell-side assertion was green at that moment.
Only resolving a link in Chromium said the number was wrong.

Conformance held exactly: **66.27% over 166 cases at base and at head**,
measured at both commits inside the verify run rather than quoted, with no
assertion that passed at base failing at head. `CasesDefined` is **42** at
both ends, a third independent reproduction of backlog 63.

Three gates the change opened holes in, all closed here: `node --check`
rejected seven slot fragments (now declared by slot in `FragmentSlots`, not
by listing paths); `Module.Quality` walked `Slots` only, so two of three
modes would have shipped unasserted; and the producer-vocabulary check
flagged a Verb-Noun name in one of the pass's own comments. All three were
right. The second is the one worth remembering - it fails silently.

The examples earn it. `examples/links/forge-links.html` is the report pass
0043 wanted and had to stop short of: the same payload as `editor-links.html`
with one setting different, and **live GitHub links from a committed file**.
`hrefTemplate` never reads `meta.rootPath`, so the placeholder that keeps a
machine path out of the repository stays exactly where 0043 put it.

**The tag names the tip.** Verify green and falsified both ran against
`3f2ec85` before the tag was applied, adopting the recorded cheap fix - so
the tag-behind-tip pattern of 0033, 0034 and the 0046 stop report's F3 is
broken this time. `plans/0047-link-mode/verify.ps1`: six checks, six probes,
exit 0 plain and `-FailCheck`.

The workspace-file question 0046 left open is **ruled and closed**: the
operator's approval of the re-issue was the ruling, `*.code-workspace` is
ignored in the harness (`eef6e80`, its own commit), and suite `d5a90b2` is
unaffected by construction because it discovers with `git ls-files` and so
constrains tracked files only. The harness's own tracked workspace file stays
tracked, which is the correct outcome rather than an oversight.

0046 changed **one character**
of executable behaviour — `evals/conformance/Invoke-Conformance.ps1:122`,
`[\/]` to `[\\/]` — and closed backlog 62. Inside a character class `\/` is
an escaped forward slash and nothing else, so the runner's exclusion of
`output|scratch|.git|gallery|fixtures|node_modules` had never fired on a
Windows path, and every path it tests is a Windows path. All four copies of
that regex are now one byte-identical string. No module source, no build,
**no tag**: the pass changed no installed file.

**Both directions of the defect were observed red before the repair**, which
is the part worth keeping. The refusal direction is the one 0045 hit and it
is loud. The admission direction had never been seen: against a clone of
PSGraphRender with `output/PSGraphRender/PSGraphRender.psd1` and
`scratch/Fake/Fake.psd1` planted, the runner's candidate set held **four**
manifests where the suite's held **two**, and the two extra were the plants.
That is the door to grading the wrong module silently, which rule F-8's own
comment in the runner calls worse than grading nothing.

The larger half of the pass is **the tests whose absence let four copies of
one regex drift**, in a new `evals/harness/` — the harness's own tests,
which grade the instrument rather than any target. 93 cases: a polarity pair
over every discovered site (Windows, POSIX and nested paths under each of the
six excluded segments), substitution controls for `src/`-side and
target-root manifests, five near-miss segment names as scope controls, and a
copies-agree check that fails the next time any one copy is edited alone.
Three falsification probes, all recorded: the pre-repair spelling turns 13
cases red; **a semantically identical respelling of one site turns exactly
one red and leaves polarity green**, which is what makes them two independent
checks; and dropping the separators turns the scope controls red while every
exclusion case stays green.

**The placement is the load-bearing decision, and it was derived rather than
assumed.** `Invoke-Conformance.ps1` inventories `*.Tests.ps1` in its own
directory, non-recursively, and that count is `CasesDefined` — the
denominator every conformance score is reported against. `evals/harness/` is
outside it, `CasesDefined` is 36 per-target and 42 global at base and at
head, and `verify.ps1 -FailCheck` measures what happens otherwise: a tagged
container in that directory moves the denominator 36 → 37, and a copy of
this pass's own test file makes the conformance runner **refuse to report a
score at all**. Placement is the guard; the `Harness` tag is only the belt.

`plans/0046-runner-regex/verify.ps1` re-derives all of it — six checks, five
probes, exit 0 both plain and `-FailCheck` — from the repository and a fresh
clone, measuring `CasesDefined` at base and head rather than pinning either.

**Three findings, and one question for the operator.** Backlog 63 is new:
the Pins section's `cases-defined: 41` is stale by one and has been since
pass 0044 added the `Workspace composition` assertion; the measured figure is
42, `HouseStyle` 23. Backlog 62's own text undercounted the sites as three
and is corrected below by dated append. SC3's premise as written in the
prompt is false and has been since pass 0041 — that is backlog 56, already
recorded, and the **third consecutive prompt** to carry the stale form of
this pin. The question: an untracked `PSGraphRender.code-workspace` appeared
at the harness root mid-pass, which no part of this pass wrote; it has been
left in place and reported, never resolved.

0045 deleted one folder
object from `PSGraphRender.code-workspace` — the `../PSModuleGraph`
entry that had been there since that repository's initial commit — and
closed backlog 60. One tracked file changed, in a commit of three
removed lines and no added ones; `docs/HANDOFF.md` took the record in a
second commit. No module source, no build, and **no tag**: a
workspace-file edit is not semver material, on the 0038 precedent that a
docs-and-config sync earns no minor.

The pass is small and what it is worth is in the polarity. The assertion
0044 added was observed **red against the real repository before the
edit and green after**, with the suite's `CasesRun` unchanged at 161 and
each of the other 33 score lines identical — so the green is a fact about
the file rather than about an assertion that had quietly stopped being
able to fail. `plans/0045-workspace-deregistration/verify.ps1` re-derives
all of it from a fresh clone, measuring both case counts rather than
pinning either, because the local tree carries an untracked `output/`
that a clone does not and a pinned count would have reported the tree's
shape. Its `-FailCheck` restores the entry in a scratch copy of the whole
repository — a whole repository, because the assertion finds its subject
with `git ls-files` and a lone file never reaches it — and shows the
assertion going red again.

**One finding, backlog 62, and it is in the instrument rather than in
the work.** `Invoke-Conformance.ps1` writes its path-exclusion regex as
`[\/]` where the suite writes `[\\/]`. Inside a character class that is
an escaped forward slash and nothing else, so the runner's
`output|scratch|gallery|fixtures` exclusion has never fired on a Windows
path. It surfaced as the runner refusing to derive `-ModuleName` for
`PSGraphRender`, having counted a manifest under `output/` as a second
candidate named for the target. A refusal is the good direction, and it
is luck: the same defect admits a `scratch/` or `gallery/` manifest into
the candidate set, where rule F-8's own comment says the outcome is worse
than grading nothing. Found by running the runner, not by reading it.

0044 wrote pass 0043's
corrections into the standing documents and the suite, and changed no
module source anywhere. `method/METHOD.md` gained two rules — a named
check counts only after its polarity is shown against a known-bad and a
known-good input, and conventions come from the repository at authoring
time rather than from recall. `PLAN-PROTOCOL.md` gained three: the five
task signals (with `docs/ux/UX-007`), a three-source frontier
precondition, and the recovery-phase pattern generalised from 0043's
Phase R. The conformance suite gained one assertion, `Workspace
composition`, with five falsification rows.

**The assertion found a real violation on its first run against the
real repositories.** `PSGraphRender.code-workspace` registers
`../PSModuleGraph` and has since that repository's initial commit —
backlog 60, unrepaired here because 0044 held the ecosystem
repositories read-only. Two other things surfaced that were not about
polarity. Pester 6 treats an empty `-ForEach` as a discovery error that
fails the whole file rather than as zero cases, which is why the suite
cannot run against the harness at all (backlog 61) — so the one
`.code-workspace` that motivated the assertion is the one it cannot
reach. And the pass's own falsification driver reported ZERO CASES on
all four rows when the truth was that discovery had failed; a driver
that cannot tell "nothing to check" from "never ran" can report a green
that means nothing, and fixing that is what made row 18e worth having.

The prompt for this pass supplied three requirements the repository
contradicted, which is the failure its own new rules describe: METHOD
has no rule numbering to number continuously from, the "0032
misnumbering" it cited is 0031's and is about backlog numbers, and its
precondition 3 read literally would have hard-stopped the pass on the
finding it was commissioning. All three are in that pass's Deviations.

0043 gave each of the four
ecosystem repositories a committed `examples/` directory — real
generated artifacts, not prose: 12 HTML reports, 12 screenshots, their
checked-in inputs, and a paste-able command per row that regenerates
the HTML. All four READMEs now lead with a screenshot and an Examples
table. PSAzureDevOpsGraph took `v0.4.0`; the other three landed on
`main` under decision 0010 without tags. **No module source changed in
any repository.**

Three things the pass found by building rather than reading. An
explicit `-Options` object beats `graphrender.defaults.psd1` on *every*
key, including ones the caller never named, because
`New-GraphRenderOptions` returns a complete object rather than a patch —
`examples/precedence/` now demonstrates it deliberately.
`ConvertTo-GraphRenderViewModel` stamps `meta.generatedAt` from
`UtcNow` and ignores the producer's own `graph.meta.generatedUtc`, so
those reports are not byte-reproducible. And a node link in
PSGraphRender can only ever be an editor scheme: `vsCodeUriFor`
hardcodes `vscode://file/` and no setting names an alternative, which
made the prompt's "https URLs into the repo on GitHub" requirement
architecturally unsatisfiable. The operator struck the requirement
rather than opening a renderer change inside a docs pass; it is logged
in PSGraphRender's `docs/improvements.md` as large, wanting its own
red-first iteration. **RESOLVED by pass 0047** (2026-09-04, appended
here rather than rewritten): `LinkMode` makes it configuration,
`hrefTemplate` is exactly the "https URLs into the repo on GitHub" shape
the prompt asked for, and `examples/links/forge-links.html` is that
report with live links. The requirement was architecturally
unsatisfiable when it was struck; it is satisfiable now, and striking it
rather than forcing it is what made this a red-first iteration instead
of a widening docs pass.

0042 is consumed by decision 0016 and is not a frontier. 0040 was the
queued
diagram / prompts / flow-documents pass; it released nothing, touched
no assertion, and left `cases-defined` at 41. The generalisation claim
still has the number and the bound 0037 gave it; the two things that
would move it are unchanged — a plugin-off control on the Terraform
domain (backlog 42) or a third domain the `tf-*` skills say nothing
about. 0039 did not touch that claim, and said so in the tag message
rather than letting a release imply otherwise.

### 0040 — the flow made visible

Documents, one decision, and no release. **Nothing under `skills/`,
`commands/`, `.claude-plugin/` or `evals/` changed** — asserted, not
claimed: `git diff v1.2.0..HEAD -- skills/ commands/ .claude-plugin/` is
empty and is spot-check 5 of the pass's own `verify.ps1`.
**`cases-defined` stands at 41.**

What landed: `docs/diagram/flow-graph.json`, a hand-authored producer
graph of 39 nodes and 49 edges in five layers, rendered to
`docs/diagram/flow.html` by `tools/diagram/Build-Diagram.ps1` through
PSGraphRenderToHtml `v0.1.0` and PSGraphRender `v0.13.0` — consumed at
their tags via `git archive`, read-only, and version-checked after
import. The same graph is mirrored by hand as Mermaid in README's *The
flow*, with a 39-row link map underneath it. `prompts/` is a six-file kit
for a stranger building their own module. Chapter 11 walks the flow end
to end. `docs/design/hybrid-modules.md` enumerates what a binary/hybrid
target would break, against the real instruments, and stops before
designing anything. Decision 0015 settles item 48.

**The pass's own checks, all green from a fresh clone**: acceptance
11/11, the diagram re-rendered byte-identical apart from its timestamp
with the producer battery at 7/7, the LEDGER-47 probe re-fired, 245 links
resolved with zero dead and 39 link-map rows for 39 nodes, and the
Mermaid mirror agreeing with the JSON on ids, labels, layers and edges -
with that comparison itself broken four ways and red for each.

**GitHub Mermaid `click`: tested, and not relied on.** The diagram
renders client-side in a cross-origin frame on
`viewscreen.githubusercontent.com` fed by postMessage, so a relative
click target cannot resolve to this repository at all, and whether an
absolute one becomes a working link could not be observed from a
terminal. No `click` directive ships; the link map is the navigation.
`plans/0040-flow-docs/mermaid-click.txt` has the commands.

### 0039 — the first time cases-defined moved

Two new skills (nineteen now), five amended, eight new `HouseStyle`
assertions in a second conformance container, an optional settings file,
and `v1.2.0`. **`cases-defined` 33 → 41**, which is the first movement of
that denominator since it was introduced, and the reason this pass has a
series boundary rather than a comparison.

31 falsification rows fired — 13 tidy, 12 help, 6 settings — plus two
probes on a new guard. Three findings came out of the pass's own work
going wrong rather than out of review, and all three are numbered below.

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
PSAzureDevOpsGraph: **v0.4.0** (docs-and-artifacts minor, pass 0043,
decision 0006; module code byte-identical to v0.2.0 still. Ships the
ClaudeTesting graph as committed JSON, HTML and a screenshot. Next
touching plan: v0.5.0)
PSGraphRender: **v0.14.0** (minor, pass 0047: link mode. No setting TYPE was
added, but a setting was and the shipped template set changed, which is minor
per that repository's own rule. Tagged `v0.14.0` on `3f2ec85`, which is the
branch tip - verify ran before the tag rather than after. Next: the
operator's)
PSGraphRenderToHtml: **v0.1.3** (three patches in pass 0041: v0.1.1 aligns
`-ColorBy` to the renderer's declared set and closes LEDGER 50; v0.1.2 and
v0.1.3 each fix a defect found by trying to use the previous fix — LEDGER 54
and 55. Read from `git ls-remote --tags`, not from prose. The harness consumes
v0.1.3: `tools/diagram/Build-Diagram.ps1`'s $ToHtmlTag default. Next: v0.2.0)
PSTerraformGraph: v0.2.0
psmodule manifest: **1.2.0**, released and tagged `v1.2.0` by pass 0039
under decision 0013. **MINOR, and the installed surface grows:** two new
skills — `powershell-module-ux` and `powershell-module-tidy`, taking the
plugin from seventeen to **nineteen** — plus five amended and the tidy
skill's two `scripts/`. `git diff v1.1.1..v1.2.0 -- commands/` is empty
and every changed line under `.claude-plugin/` is a version field, both
asserted by that pass's `verify.ps1`, spot-check 5.

The release also carries the first **series boundary**: `cases-defined`
moved 33 → 41, so conformance scores taken before and after `v1.2.0` are
separate series and are not compared. Nothing earlier is restated. The
CHANGELOG, the README's own score table, `docs/testing/` and the tag
message all say so, and all four say in the same breath what the
boundary does **not** license — it is not a reset, and the ladder's
numbers stand exactly as measured on the 33-case series.

Previously **1.1.1**, released and tagged `v1.1.1` by pass 0037
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
**cases-defined: 41** (new at 0039; was 33 from pass 0025 to pass 0038).
Per tag: `HouseStyle` 22, `Universal` 9, `RequiresBuild` 6,
`Repository` 4. **⚠ This figure is stale by one and has been since pass
0044 — see backlog 63.** Measured from a clone by pass 0046 at two
commits: 42, with `HouseStyle` 23. The series-boundary claim below is
unaffected; what is wrong is the number, not the boundary. The eight added are `evals/conformance/Help.Tests.ps1`,
all `HouseStyle`; `Conformance.Tests.ps1` is untouched and no assertion
was weakened, renamed or removed. **Scores either side of `v1.2.0` are
separate series and are not compared** — see
`plans/0039-ux-help-batch/denominator-v2.txt`, re-derived across targets
whose cases-run are 477 / 154 / 98 / 60.

The derivation's INPUT SET changed with it: `Invoke-Conformance.ps1`
inventories and runs every `*.Tests.ps1` in the directory rather than one
named file. A second container running its assertions while absent from
`cases-defined` would grow the numerator while the denominator held
still, which reads as an improvement.

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

    **Added by 0040: a pass that changes the flow re-runs
    `tools/diagram/Build-Diagram.ps1` and re-mirrors the Mermaid block in
    README's *The flow*, in the same commit.** The two renderings come
    from one source and neither updates itself. `verify.ps1`'s
    spot-check 4 compares them on ids, labels, layer membership and
    edges, so a pass that moves one and not the other fails a check
    rather than shipping a diagram that quietly disagrees with the
    repository.

    **Added by 0041: a pass that changes what README.md SHOWS keeps the
    presentation standard**, which is `docs/ux/UX-006`: every code fence
    language-tagged, the badge row intact, the hero regenerated when the
    diagram moves, the five layer colours identical in all three
    renderings, every summary linking what it summarises, and no execute
    affordance anywhere. Presentation is the only part of this repository
    nothing else measures, which is exactly why it needs a standing owner
    rather than a pass that happened to care. 0041's `verify.ps1` re-runs
    all six from a fresh clone, and its `Compare-Mermaid.ps1` extends
    0040's to the colours.
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
    **CLOSED by 0040**: PLAN-PROTOCOL's new *Sync* step reports any
    `pass-*` branch whose tip is not an ancestor of its repository's
    `main`, at the start of every pass, where a stranded branch is cheap
    rather than releases later. It is the same gap one level down. 0038 found
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

### Added by pass 0039

45. **A suite container that fails discovery is invisible, and the score
    it leaves behind looks normal.** RESOLVED in the same pass, and
    numbered because the shape will recur.

    `Help.Tests.ps1` lost its whole container to a member access on an
    empty array during discovery. Every one of its assertions vanished
    from the run. `CasesDefined` still counted them — it is parsed from
    the suite's SOURCE and does not know a file failed to load — so the
    numerator and the denominator shrank together and the percentage was
    unremarkable. Pester printed `Container failed: 1` in its own output
    and nothing downstream read it. It survived a full scoring run of the
    reference before anyone noticed the help assertions were absent from
    the breakdown.

    **This is *not run is not a pass*, one level above the zero-cases
    rule the suite already had.** Zero cases is an assertion that had
    nothing to run against; this is an assertion that was never loaded,
    and only the first was guarded.

    `Invoke-Conformance.ps1` now hard-stops on a container-level
    `ErrorRecord` and writes no `result.json`. Falsified: control silent,
    break fires, no result file. It keys on the `ErrorRecord` and **not**
    on the container's `Result`, because a container holding a merely
    failing test also reports `Failed`, and turning every red run into a
    crash is the opposite of what the runner promises three comments
    above.

46. **An assertion can be inert because it was scoped by the wrong
    noun.** RESOLVED in the same pass; numbered because it is a third
    entry in a catalogue that had two.

    `powershell-module-tidy`'s `documented-unexported` rule derived the
    module's command prefix from the module NAME. This plugin's own
    convention — stated in `powershell-module-architect` — is a command
    prefix that is *not* the module name: the reference is
    `PSModuleGraph` and its commands are `Get-PSModule*`. Every command
    the rule existed to catch fell outside its own pattern, and it would
    have shipped green forever.

    The catalogue of ways an assertion can be inert now reads: satisfied
    by a comment quoting the code it looks for; comparing against `$null`
    so the condition cannot be true; and **scoped by a plausible
    identifier that is the wrong one**. The third is the hardest to see
    in review, because the scoping line reads as obviously correct.

    The derivation now groups the exported nouns by their first four
    characters and takes each group's longest common prefix, which yields
    `{PSModule, Knowledge}` for the reference. It was caught by a probe,
    not by reading.

47. **A pass that writes both a convention and its assertion must RUN
    them against each other, not review them against each other.**
    STANDING as an instruction; **the 0039 instance is CLOSED by 0040**,
    which built a minimal module to the house splat standard and ran the
    set-coverage assertion against it rather than reading the two side by
    side — `SPLAT EXAMPLE: passes as shipped`,
    `plans/0040-flow-docs/splat-coverage.txt`, re-fired by that pass's
    `verify.ps1`.

    0039 wrote the house `.EXAMPLE` standard, which mandates splatting,
    and a set-coverage assertion that looked for the `-Name` dash form.
    A conforming example names its parameters as hashtable keys and never
    writes `-Name` at all, so **the assertion was unsatisfiable by
    exactly the examples it rewards**. Read side by side the two rules
    look entirely consistent; nothing found it but building a fixture to
    one and running the other against it.

    **The instruction:** when a single pass produces a rule and the check
    for that rule, the pass builds an artifact that satisfies the rule
    and runs the check against it, before either is committed. A green on
    a target that predates both proves nothing about their agreement, and
    a review of the two documents proves less.

48. **The falsification protocol has no rule for a NEW assertion whose
    target is already red.** **CLOSED by 0040** as
    `decisions/0015-falsifying-against-a-red-target.md`: two claims, two
    artifacts — capability on a purpose-built known-good, the target's
    real behaviour measured and Bucket-sorted separately — with the rule
    folded into METHOD's falsification section. 0039 worked around it
    rather than settling it, and settling it was the operator's.

    The protocol says break the reference. For the eight help
    assertions that was impossible: the reference predates them and fails
    219 of their cases, so the case a break would turn red is already
    red. 0039 built a purpose-made known-good fixture
    (`plans/0039-ux-help-batch/New-HelpFixture.ps1`) and falsified
    against that, then recorded the reference's actual standing behaviour
    separately as declared Bucket B.

    Both halves of the protocol are satisfied — by two artifacts instead
    of one — and the reasoning is at the top of
    `help-falsification.txt` rather than left for a reader to notice.
    What is NOT settled is whether that is the general rule for a new
    assertion, or a one-off. It is the operator's to decide, and it wants
    a decision entry rather than a precedent buried in one pass's record.

### Added by pass 0040

49. **Two decision records disagree about who may move the harness
    `main`.** STANDING, and it is the operator's to settle.

    Decision 0009 says in terms that "at the end of every pass whose
    acceptance test is green, the agent fast-forwards `main` — on the
    harness to the pass tip". Decision 0013's *What is unchanged* section
    says "**Harness `main` remains operator-only.** This decision permits
    tags. It does not permit the agent to move `main`" — and justifies it
    by enumerating "Decision 0008's fast-forward permission is for
    PSAzureDevOpsGraph and decision 0010's for the three ecosystem
    repos".

    **That enumeration omits 0009, which is the decision that grants the
    harness permission.** So 0013 argues from a list that does not
    contain the counter-example, and the two records now say opposite
    things about the same act. Practice has followed 0009 — the Pins
    section records the harness main fast-forwarded at pass 0035's close,
    per 0009 — and pass 0040's prompt directed the same. 0040 followed
    0009 and is flagging the contradiction rather than picking a winner:
    whichever is right, one of the two records needs a line, and a pass
    should not have to re-derive this from two documents that disagree.

50. **An option can be validated against a list the module that consumes
    it does not have.** RESOLVED here by not passing the option; the
    defect is in the ecosystem and is not this repository's to fix.

    `PSGraphRenderToHtml` v0.1.0 validates `-ColorBy` against
    `{ structure, scope, type }`. `PSGraphRender` v0.13.0's cytoscape
    settings schema accepts `{ structure, dependents, blastRadius,
    dependencies, reach }`. **The two sets share exactly one member.**
    Passing `type` — which this pass wanted, so that colour carried the
    skill families while position carried the layer — is accepted by the
    validator, warned about by the renderer, and silently downgraded to
    `structure`.

    The shape is worth the number: a `ValidateSet` is a promise about
    what the CALLEE will accept, and here the callee is a different
    repository at a different version. ToHtml's own docstring says its
    layout names and interaction defaults were READ from PSGraphRender
    v0.13.0 rather than guessed. `ColorBy` either was not, or the two
    drifted afterwards, and nothing in either repository would notice. A
    cross-module `ValidateSet` needs a test that runs every member of it
    through the real consumer.

51. **A generated artifact that anything COMPARES needs a line-ending
    rule and a byte-exact writer, and this pass needed both.** RESOLVED,
    and numbered because it arrived twice in one afternoon in two
    different disguises.

    `docs/diagram/flow.html` is generated, committed, and re-rendered by
    `Build-Diagram.ps1 -Check`. First: `.gitattributes` documents this
    exact hazard twice already — for the fixture read back byte-for-byte,
    and for the two seeds whose tree SHAs are pinned above — and its
    extension list covered `yml`, `json`, `md` and `ps1` but not `html`,
    so a Windows checkout translated the file to CRLF while the renderer
    wrote LF. Second, after that was fixed: `Set-Content` appends the
    PLATFORM's newline, so the fresh render still differed from the
    committed copy by **one byte at the end of the file**.

    **Both had the same symptom, and it is the least diagnosable one
    available**: identical line counts, no differing line, and a reporter
    that printed "DIFFERS" with nothing to point at. The fix for the
    second was to write the bytes rather than normalise the comparison -
    a comparison taught to ignore a difference stops being able to see
    that class of difference again.

    **Neither was visible from the working tree.** `-Check` passed there
    throughout. They surfaced only because `verify.ps1` clones the
    repository rather than reading it, which is the property that makes a
    verification worth running.

52. **A supplied verbatim insertion broke the acceptance test written to
    check for it, by wrapping.** RESOLVED in the pass; numbered because
    it is hazard 8 arriving inside the fix for a different gap.

    Pass 0040's prompt supplied a paragraph for PLAN-PROTOCOL's sync step
    and an assertion matching `not an ancestor of.*main` against the raw
    file. As given, the paragraph wrapped between "not an" and
    "ancestor", and `.` does not cross a newline in .NET regex, so the
    verbatim text would have failed the check written for it. The
    paragraph was rewrapped and the deviation recorded.

    Hazard 8 is *an absence check on prose defeated by a line break*, and
    it has now recurred inside the falsification of its own fix (0035)
    and inside a supplied insertion (0040). **A prose assertion that
    spans more than about six words is a line-break bug waiting for a
    re-wrap**, and the durable answer is to match on a short phrase that
    cannot wrap, or to normalise whitespace before matching.

53. **A second rendering of one source is a claim, and needs a check that
    has been broken.** RESOLVED in the pass.

    README's Mermaid block is a hand-written mirror of
    `flow-graph.json`. It agreed with the source on the first run, which
    establishes nothing: `Compare-Mermaid.ps1` had never been red.
    Breaking it four ways — a deleted node, a node moved between layers,
    a reversed edge, a retyped label — with the control green is what
    makes the agreement evidence.

    **The layer break is the one that pays for the rule.** The prompt
    asked for node count and layer membership; through that break the
    node count stayed at 39 and only the layer moved, so a check written
    to the count alone would have passed a diagram claiming the wrong
    thing about what rests on what.

### Resolved by pass 0041

- Item **49** (two decision records disagree about who may move harness
  `main`): **settled by the operator, in decision 0013.** An amendment
  appended to that record says decision 0009 governs `main` and 0013
  governs releases, that 0013's earlier enumeration omitted 0009 and is
  superseded, and that where they appear to conflict 0009 wins on `main`
  and 0013 wins on tags. The superseded bullet is left standing with a
  forward pointer rather than rewritten: a record edited to look as
  though it never disagreed stops explaining why the disagreement was
  worth a LEDGER item.
- Item **50** (an option validated against a list the consuming module
  does not have): **fixed in the ecosystem, not worked around.**
  PSGraphRenderToHtml **v0.1.1** aligns `-ColorBy` to the set
  PSGraphRender's cytoscape settings schema actually declares, and
  refuses anything else with a message naming both repositories and both
  sets. The entry asked for the durable form of the fix — *"a
  cross-module `ValidateSet` needs a test that runs every member of it
  through the real consumer"* — and got it: `Options.Tests.ps1` now reads
  `TemplateSets/cytoscape/Config/settings.schema.psd1` out of the
  resolved renderer and asserts that every value it declares is accepted
  here. Falsified by dropping one member and watching the test name it:
  `REFUSED: reach`. The harness consumes v0.1.1 onward, so the fix is a
  thing that happened rather than a thing that was written.

### Added by pass 0041

54. **A parameter nobody can use has no wrong behaviour to report.**
    RESOLVED in the ecosystem as PSGraphRenderToHtml **v0.1.2**, and
    numbered because it is the same shape as 50 and was found by fixing
    50.

    v0.1.1's `-ColorBy` help says, in terms, to colour by layer through
    `-Theme`'s `KindColor` map. That advice could not be followed:
    **every** `-Theme` value threw, scalar ones included, on a key the
    caller had never mentioned. `New-TemplateSetOverlay` merges the
    caller's keys over the backend's `theme.psd1` and writes the WHOLE
    merged file back; `Write-PowerShellDataFile` handled scalars only;
    and PSGraphRender's `theme.psd1` declares three maps. So the first
    pass over a file the caller had barely touched threw on
    `EdgeResolutionStyle`.

    **The reason nothing had noticed is the finding.** `-Theme` was
    declared, documented, carried into the options object, and covered by
    a test that checked it *reached* the options object. Nothing had ever
    rendered with one. A parameter with no behaviour has no wrong
    behaviour, and no amount of testing at the surface finds that — only
    driving it end to end does, which is what a consumer following the
    advice an hour after it shipped amounts to.

55. **A silent fallback is worse than a failure, and the renderer's
    warning stream is where this one lived.** RESOLVED as
    PSGraphRenderToHtml **v0.1.3** plus a consumer-side guard in
    `tools/diagram/Build-Diagram.ps1`.

    The first real theme was a `KindColor` map keyed by this repository's
    own node types, two of which are `cross-cutting` and
    `powershell-module`. Written bare into a `.psd1`, `cross-cutting`
    parses as `cross` minus `cutting`, so the file failed to parse **as a
    whole**. PSGraphRender warned, fell back to its built-in theme, and
    drew a perfectly good page in which every node was the fallback grey.

    **The page rendered. It looked deliberate. None of the five layer
    colours were in it, and nothing about the artifact said so** — the
    build printed `WROTE` and handed back a document nobody could tell
    was wrong. `Build-Diagram.ps1` now captures the render's warnings and
    throws on any of them, and that guard is the only reason the
    committed diagram is not grey.

    A second defect sat beside it: the writer walked `$map.Keys`, and
    PowerShell resolves a member name against a hashtable's ENTRIES
    before its properties, so a map with a key called `Keys` answers with
    that entry's value. `Keys`, `Values` and `Count` are all plausible
    node types. **The identical trap bit this pass's own new ColorBy test
    three hours earlier, from the other direction** — `$entry.Values`
    returning every field of a schema entry instead of the enum it
    declares. Twice in one afternoon in opposite directions is what makes
    it worth a number: use `.PSBase.Keys` on anything a producer keys.

56. **The error standard in `powershell-module-ux` is written and
    unreleased.** STANDING — a rider on the next harness release.

    The skill now carries the rule that every terminal error states the
    fix or names the doc, in one line, before any detail, with
    `Test-Prerequisites.ps1` as the worked example and `docs/ux/UX-003`
    as the record. Pass 0041 shipped no harness tag, so **no installed
    plugin has it**: a consumer at `v1.2.0` gets the skill without this
    section, and its frontmatter `description` without the clause that
    would make the skill fire on an error-message question. The next
    release pass folds it in, and until then the gap is written here
    rather than implied by a version number that did not move.

57. **`docs/ux/` is a registry with six records and no enforcement that
    a new convention gets one.** STANDING.

    `PLAN-PROTOCOL.md` now says every operator-experience convention has
    a numbered record written before the convention ships, and
    `docs/ux/README.md` says a convention without a problem statement is
    decoration and does not land. **Neither is checked.** 0041's
    acceptance test asserts that the six existing records carry the four
    headings and that the index matches the files on disk; nothing
    asserts that a convention introduced by pass 0042 acquired a record
    at all, because nothing can enumerate "conventions" mechanically.

    Recorded rather than solved, with the honest bound stated: this is a
    rule held by the people following it, which is the category of rule
    this project is otherwise trying to get out of. The cheapest partial
    check is a per-pass question in the plan protocol rather than an
    assertion, and it was not added because a question nobody answers is
    the same rule with more ceremony.

### Added by the recovery of pass 0041

58. **A checker that silently checks less is worse than one that fails,
    and the link checker is one.** STANDING.

    `plans/0041-operator-ux/Test-Links.ps1` strips fenced code blocks
    before scanning, using `[regex]::Replace($text, '(?s)` + three
    backticks + `.*?` + three backticks + `', '')`. The pattern is
    unanchored and non-greedy, so it pairs runs of three backticks by
    position, with no notion of which open a fence, which close one, and
    which are inline code spans containing backticks — of which
    `plans/0041-operator-ux/plan.md` has several, because its deviation 1
    is prose about fences.

    **Observed, not theorised.** Appending one ordinary fenced block to
    that plan moved the stripped region and took `links resolved` from
    **539 to 536**. `DEAD LINKS` stayed `0` throughout. Three links
    stopped being examined and nothing reported it: not as dead, not as
    skipped, not at all. Removing the block restored 539.

    This is the checker reproducing, internally, the exact failure it was
    written to catch — *a dead link reads exactly like a working one*, and
    a link that is never examined reads exactly like one that passed. The
    only channel carrying the difference is the total, and nothing
    compares that total to anything.

    **The durable form of the fix is not a better regex.** It is that the
    count becomes an assertion rather than a number in a log: the checker
    should state how many links it expected to examine and go red when it
    examines fewer, so that a stripping bug is a failure rather than a
    quieter success. Line-anchoring the fence pattern is the cheap half
    and would have caught this instance; the assertion is what makes the
    next instance report itself.

    Not fixed in 0041: `Test-Links.ps1` is a frozen plan artifact under
    decision 0004, and the pass was being recovered rather than extended.
    The recovery worked around it by indenting an example instead of
    fencing it, and that workaround is recorded as deviation 16 of that
    plan rather than left to look like a formatting preference.

### Added by pass 0044

59. **The 0043 method corrections, incorporated.** RESOLVED by pass 0044.

    Three standing documents now carry what 0043 learned the hard way.
    One line each, cross-referenced to the origin:

    - **`method/METHOD.md`, named-check polarity** — every named check in
      a prompt, spot-checks included, is demonstrated red against a
      known-bad input and green against a known-good one before its first
      counted result. Origin: pass 0043 deviations 3, 4 and 5 — SC2 wrong
      in two independent ways and SC4 unable to tell a drawn canvas from a
      blank one.
    - **`method/METHOD.md`, conventions from the repository** — a prompt
      requirement naming a path, version, layout or convention is derived
      from the repository at authoring time, never recalled. Origin: pass
      0043 deviation 2, a verify-script directory that has never existed
      here, and the `v0.3.0` collision that made the release land as
      `v0.4.0`.
    - **`evals/conformance/Conformance.Tests.ps1`, `Workspace
      composition`** — a tracked workspace file must not register
      PSModuleGraph as a folder, with falsification rows 18a-18e. Origin:
      pass 0043, where two sessions reported that no repository file
      registered PSModuleGraph while a tracked `.code-workspace` did.
    - **`PLAN-PROTOCOL.md`** also gained the five task signals (with
      `docs/ux/UX-007`), the three-source frontier precondition, and the
      recovery-phase pattern generalised from 0043's Phase R.

    Grouped under one number rather than four because the LEDGER's
    numbers are what later passes cite, and what will be cited here is
    "the 0043 corrections" — while 60 and 61 below are live findings that
    will each be cited on their own.

60. **`PSGraphRender.code-workspace` registers `../PSModuleGraph`, and
    has since that repository's initial commit.** RESOLVED by pass 0045.

    Found by the assertion added as part of 59, on its first run against
    the real repositories — which is the strongest evidence available
    that the assertion is not inert. `PSGraphRender` is the only one of
    the five workspace repositories that goes red; the other three
    ecosystem repositories have no tracked workspace file at all.

    **Not repaired by 0044,** which holds the ecosystem repositories
    read-only. Never weaken an assertion because a target fails it: this
    is a finding and it goes to the operator. The fix is one folder entry
    and is a one-line commit in `PSGraphRender` whenever a pass has that
    repository writable.

    Note what the file points at: `../PSModuleGraph`, a path that no
    longer exists at the workspace root, because pass 0043 relocated the
    clone to `scratch/`. So the registration is currently inert as well
    as wrong — which is exactly the state in which it survives another
    two sessions unnoticed.

    **Repaired by pass 0045**, `PSGraphRender` commit `3973644`: the
    folder object is deleted, `{ "path": "." }` and the `settings` block
    are byte-identical, and the commit changes nothing else. The
    assertion that found it was observed red against the real repository
    before the edit and green after, with the suite's `CasesRun`
    unchanged at 161 and no other score line moved. No tag was taken —
    a workspace-file edit is not module semver material.

61. **The conformance suite cannot grade the harness repository, and the
    one file that motivated assertion 59 lives there.** STANDING.

    `AI.Agent.Claude.PowerShellModuleBuilder` has no module manifest, so
    `$ExportedWithSource` and `$PublicFiles` are empty, and Pester 6
    treats an empty `-ForEach` as a **discovery error that fails the
    entire file** rather than as zero cases. The suite therefore does not
    run against the harness at all — not partially, not with skips.

    Two consequences, and the second is the uncomfortable one. Every
    assertion in the suite is unreachable for the repository that hosts
    it; and the `Workspace composition` assertion, whose motivating
    defect was a harness `.code-workspace`, structurally cannot check the
    harness. 0044 covered that one file with a direct check in
    `plans/0044-method-corrections/verify.ps1` rather than leaving it
    uncovered, but a plan artifact is frozen at its pass and is not a
    standing guard.

    The cheap half of the fix is `-AllowNullOrEmptyForEach` on the three
    existing `-ForEach` assertions, which converts a whole-file discovery
    failure into per-assertion zero-cases — the behaviour METHOD already
    prescribes. **Not done by 0044:** the pass was scoped to one new
    assertion, and changing three existing ones to make a fourth reachable
    is the kind of quiet scope growth that makes a score incomparable
    across passes. It wants its own red-first iteration, with cases-run
    stated before and after.

### Added by pass 0045

62. **`Invoke-Conformance.ps1`'s path-exclusion regex is inert on
    Windows.** **RESOLVED by pass 0046.**

    `evals/conformance/Invoke-Conformance.ps1:122` excludes `output`,
    `scratch`, `.git`, `gallery`, `fixtures` and `node_modules` from
    manifest discovery with

        '[\/](output|scratch|\.git|gallery|fixtures|node_modules)[\/]'

    where `Conformance.Tests.ps1:61` and `:148` do the same job with
    `[\\/]`. Inside a character class `\/` is an escaped forward slash and
    nothing else, so the runner's version matches forward slashes only —
    and every path it tests is a Windows path built by `Substring` on a
    `FullName`. Demonstrated rather than asserted, in
    `plans/0045-workspace-deregistration/plan.md` Deviation 2:
    `\output\PSGraphRender\PSGraphRender.psd1` is excluded by the suite's
    form and not by the runner's.

    What it did to pass 0045: the runner counted
    `output/PSGraphRender/PSGraphRender.psd1` as a second candidate named
    for the target, decided it could not choose, and demanded
    `-ModuleName` for a repository whose layout the suite itself resolves
    unaided. That is a refusal rather than a wrong answer, which is the
    good direction — but only because `output/` happened to hold a
    manifest named for the target. The same defect admits a manifest
    under `scratch/` or `gallery/` into the candidate set, where rule
    F-8's own comment says the outcome is worse than grading nothing:
    grading the wrong module silently.

    Found by running the runner, not by reading it. Not repaired by 0045,
    which may write to the harness for its records only; the fix is one
    character and belongs with a red-first test of the runner's
    discovery, because a one-character fix with no test is how the
    divergence between these three regexes arose in the first place.

    **Appended 2026-09-03 by pass 0046.** Three corrections and a
    resolution. The text above is left as written, per the rule that a
    numbered item is amended by append and never rewritten.

    - **There are four copies, not three.** `Help.Tests.ps1:55` is a
      third correct one, alongside `Conformance.Tests.ps1:61` and `:148`.
      The item names two and says "these three regexes", counting the
      broken one; the inventory is four sites in three files.
    - **The refusal message names neither plant, and the causal chain has
      two links.** The `output/` manifest surviving exclusion is what
      makes `$suiteCanDecide` false; the runner then falls into its
      `src/` rule and refuses because `src/` holds two manifests — the
      module's own and `TemplateSets/cytoscape/vendor/vendor.psd1`, whose
      base name equals its directory name. The item is right about the
      cause and does not match the text of the refusal. Repairing the
      regex makes `$suiteCanDecide` true and the `src/` block never runs,
      so the vendored manifest is never reached and is not a defect.
    - **The dangerous direction was observed, not merely argued.** With
      `scratch/Fake/Fake.psd1` planted in a clone, the runner's candidate
      set held four manifests and the suite's held two.
      `plans/0046-runner-regex/accept-red.txt` records both sets.

    Repaired at `Invoke-Conformance.ps1:122`; all four copies are now one
    byte-identical string. The standing guard the item asked for is
    `evals/harness/ExclusionPattern.Tests.ps1`, deliberately outside the
    conformance inventory, with three falsification probes recorded in
    `plans/0046-runner-regex/`.

### Added by pass 0046

63. **The Pins section's `cases-defined` figure is stale by one.**
    STANDING.

    The Pins section reads **cases-defined: 41** (new at 0039), per tag
    `HouseStyle` 22, `Universal` 9, `RequiresBuild` 6, `Repository` 4.
    Measured by pass 0046 at its base commit `13e1ea9` and at its head,
    from a clone, with all four tags selected: it is **42**, with
    `HouseStyle` **23**. The default three-tag figure is **36**, which is
    what pass 0045 recorded and what 0046 re-derived twice.

    Pass 0044 added the `Workspace composition` assertion — one
    `HouseStyle` `It` — and did not move the pin. Nothing checks that a
    pass which changes the assertion inventory updates the figure the
    inventory is pinned at, which is backlog 44's shape one level down:
    a measured result must name the sibling documents it stales, and
    nothing enforces it.

    **Not repaired by 0046.** The pin is not a number in isolation — it
    carries a series boundary, and scores either side of `v1.2.0` are
    declared incomparable against it. Moving it is a claim about which
    scores may be compared with which, and that wants its own red-first
    iteration with the affected documents enumerated, not a drive-by edit
    inside a pass about a regex. What is cheap and worth doing there: a
    check that re-derives `CasesDefined` from the suite and compares it
    against the pinned figure, so the next drift is loud.

    **Third measurement, pass 0047 (2026-09-04).** Measured again at
    `cd4857d` and at `3f2ec85`, all four tags, inside
    `plans/0047-link-mode/verify.ps1`: **42** at both ends. Three
    independent runs across two passes now disagree with the pin, and
    none has moved it. Still STANDING for the reason 0046 gave - the pin
    carries a series boundary, and moving it is a claim about which
    scores may be compared with which.

### Added by pass 0047

64. **The editor-mode byte control does not cover the STRINGS block.**
    STANDING.

    `tests/LinkMode.Tests.ps1` in PSGraphRender asserts that an
    `editor`-mode document is byte-identical to the base's for the same
    payload - the strongest gate that repository has against a
    refactor that claims to preserve behaviour and does not. It compares
    the document with the `STRINGS` block removed, because acceptance B's
    carve-out for `vscode://` prose is exactly that block and the same
    helper serves both.

    So a change to the renderer's own UI strings is invisible to the one
    check that would otherwise catch it. Pass 0047 added three strings
    (`MenuOpenLink`, `MenuCopyLink`, `ReasonNoTemplate`); they are
    additive and no existing string changed, but **the control is not
    what proves that** - it was checked by reading the diff, which is the
    thing this gate exists to replace.

    Found while writing the deviation that describes it rather than by a
    failure, which is why it is logged and not fixed here: closing it is
    a change to a suite in another repository, and it belongs to a pass
    already touching that suite. The shape of the fix is known - compare
    STRINGS the way CONFIG is already compared, where an existing key may
    not change value and only additions are permitted.

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
- **49, 50, 51, 52 and 53 were consumed by pass 0040**; **54 is the next
  free number.** 49 is the only one that is not this pass's own work
  going wrong: it is two decision records found to disagree, and it is
  STANDING because a pass may not settle a decision. 50 is a defect in a
  sibling repository, recorded here because this repository is the one
  that found it and the one whose diagram it degraded. 51, 52 and 53
  continue the pattern 0035, 0036 and 0039 recorded — each was found by
  this pass's own work going wrong, and 51 was invisible from the working
  tree until `verify.ps1` cloned.

- **45, 46, 47 and 48 were consumed by pass 0039**; 49 was the next free
  number until 0040 took it. 45 and 46 were RESOLVED in the same pass and are
  numbered anyway, because both are shapes rather than incidents: a
  container that did not run, and an assertion scoped by the wrong
  noun. 47 and 48 are STANDING — 47 is an instruction for any pass
  that writes a rule and its check together, and 48 is a gap in the
  falsification protocol that 0039 worked around and did not settle,
  so it wants a decision entry rather than a precedent buried in one
  pass's record. All four were found by this pass's own work going
  wrong rather than by review, which continues the pattern 0035 and
  0036 recorded.

- **43 and 44 were consumed by pass 0038**; 45 was the next free
  number until 0039 took it. Both are STANDING instructions rather than tasks with a
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

- **59, 60 and 61 were consumed by pass 0044**; 62 was the next free
  number until 0045 took it. 59 is the incorporation of 0043's
  corrections and is resolved; 60 and 61 are live findings, both produced
  by the assertion 59 added rather than by reading anything. **60 was
  resolved by pass 0045** and keeps its number where it is.
- **62 was consumed by pass 0045**; 63 was the next free number until 0046
  took it. 0045
  consumed one number for one finding and none for its own work, which is
  what a single-edit pass should look like. 62 is a defect in the
  instrument the pass was using rather than in anything the pass wrote,
  and it was found by running that instrument rather than by reading it —
  the pattern 0035, 0036, 0039 and 0040 each recorded.
- **64 was consumed by pass 0047**; **65 is the next free number.** 64 is a
  gap in a gate the pass itself built, found while writing the deviation
  that describes it rather than by any instrument - the first entry in
  five passes that no run turned up.
- **63 was consumed by pass 0046**; 64 was the next free number until 0047 **62
  was resolved by pass 0046** and keeps its number where it is, amended by
  dated append rather than rewritten — three corrections, one of them to
  its own count of the sites. 63 is again a defect in the instrument
  rather than in the pass's work, and again found by measuring rather than
  by reading: the pass had to measure `CasesDefined` at two commits to
  prove it had not moved it, and the pinned figure disagreed with both.
  That is the fourth consecutive pass to consume a number for something
  its own measurement turned up, and the second in a row where the finding
  is in the bookkeeping around a number rather than in the number.

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
