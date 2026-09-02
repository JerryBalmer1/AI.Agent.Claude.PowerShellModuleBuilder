# Plan 0033 — the honest headline

Tier: **full**, per the prompt header.

**Status: complete.** This document replaces the stopped version committed at
`7484d23`, which recorded a truncated prompt as a file-supply defect under
`PLAN-PROTOCOL.md` §"File supply". The prompt was resent in full and the pass
resumed on the same branch. §2's preconditions were re-checked at resume, not
inherited.

## 1. Preconditions

All hold, re-checked at resume.

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | Sync | `git fetch --all --tags --prune` | up to date |
| 2 | Trees clean | `git status --porcelain` | harness clean but for the untracked acceptance test; `PSAzureDevOpsGraph` clean |
| 3 | Branch | `git rev-parse --abbrev-ref HEAD` | `pass-0033-honest-headline`, at `7484d23` |
| 4 | No `v1.0.1` on the remote | `git ls-remote --tags origin` | only `v1.0.0` → `361bc0c` (annotated), `^{}` → `a5aa4a9` |
| 5 | Installed surface unchanged | `git diff --name-only v1.0.0..HEAD -- skills/ commands/ .claude-plugin/` | **empty** |
| 6 | Both target commits reachable | `git cat-file -t` in `PSAzureDevOpsGraph` | `95ca28d` and `7066916` both `commit` |

Hazard 10 (poisoned memory) was verified clean by the stopped session and is
unchanged: no project memory content, no harness `CLAUDE.md`, no harness
`.claude/`. This session read everything and is not a blind builder.

## 2. Environment

- pwsh 7.6.5; Pester 6.1.0; InvokeBuild 5.14.23; PSScriptAnalyzer 1.25.0;
  powershell-yaml 0.4.12; git 2.41.0.windows.1
- Windows 11 Home 10.0.26200; Claude Code, VSCode native extension;
  model `claude-opus-5[1m]`
- `$env:AZDO_PAT` present (run 006's build runs live read-only integration
  tests; nothing was written to Azure DevOps)

## 3. Acceptance test — red first

`plans/0033-honest-headline/accept.Tests.ps1`, committed exactly as supplied.

**RED, 10 of 10 failing, before any work.** Transcript:
[`accept-red.txt`](accept-red.txt).

    Total: 10  Passed: 0  Failed: 10

Green at start would have stopped the pass; nothing was green. Two of the ten
failed by *file absence* (`rescore.txt`, `tf-fixture-comments.txt`) rather than
by assertion, which is recorded because a missing-file red and an assertion red
are not the same evidence.

## 4. Task 2 — the scoring repair, and the re-derivation

**The defect.** Four `RequiresBuild` assertions read `output/<Name>/`, which is
gitignored. The scoring protocol said "score from a fresh clone" and never said
to build it, so run 007's conformance clone was never built and those four
graded the absence of a directory. LEDGER item 24.

**The repair, and what it is not.** No assertion was added, removed, weakened or
edited — check 8 of `verify.ps1` asserts `Conformance.Tests.ps1` is
byte-identical to `v1.0.0`. What changed is the procedure:

- `evals/conformance/Score-Clone.ps1` — new. Clones, builds, scores, in that
  order, in one clone. Refuses a non-empty `WorkDir` (run 005's race), verifies
  the checked-out SHA against a full-SHA `-Ref`, and gates on a red build per
  HARNESS step 3. `-SkipBuild` reproduces the old procedure and exists only as
  a falsification control; `-ScoreAnyway` scores past a red build and exists
  only so the sabotage row can run.
- `evals/HARNESS.md` step 4 — the rule, with the numbers that paid for it.
- `evals/HARNESS.md` "What a run must record" — a new bullet: whether the
  conformance clone was built, and with which task.
- `method/METHOD.md` — the portable form, beside the existing per-clone
  isolation rule: *an isolated clone must still be put into the state the
  assertions grade.*
- `evals/conformance/README.md` — "Running it" now points at `Score-Clone.ps1`.

**One thing the repair had to learn.** The first implementation passed
`-Task .` to the target's `build.ps1`. Run 007's *first shot* declares
`[ValidateSet('Clean','Build','Test','All')]` and has no `.` task, so the build
failed with a parameter-validation error and the gate correctly refused to
score it. The wrapper now invokes the target's **own default** and asserts
nothing about its task names — which matters precisely because a non-house-style
build file is one of the things being graded.

### Falsification, four rows

Full transcript and reasoning: [`rescore.txt`](rescore.txt).

| Row | What it breaks | Expected | Observed |
|---|---|---|---|
| 1 control | nothing; scores an **unbuilt** clone | the four assertions still fail | **fires** — 28/33, exactly run 007's reported figure, four `generated module` assertions red |
| 2 sabotage | `throw` committed into the Build task | build red, the four fail | **fires** — build exit 1, same four red, `output/` absent |
| 2b gate | the same commit without `-ScoreAnyway` | no score at all | **fires** — throws, naming HARNESS step 3 |
| 3 positive | nothing; a built conforming clone | passes | **fires** — run 006 final, 33/33, zero failed assertions |

Row 1 is the row that matters. Had it gone green, the "repair" would have been
an assertion-weakening wearing a procedure's clothes.

### The re-derived scores

Both finals re-cloned from the pushed SHAs and scored under one procedure. The
first shots too, because the README's headline comparison is a first-shot
comparison and must not inherit the same defect.

| Commit | protocol | corrected |
|---|---|---|
| 007 first shot `1f2df30` | 19 / 33 | **20 / 33** |
| 007 final `95ca28d` | 28 / 33 | **32 / 33** |
| 006 first shot `15ab6e3` | 33 / 33 | 33 / 33 |
| 006 final `7066916` | 33 / 33 | 33 / 33 |

Run 006 was re-scored *because it was expected not to move.* A re-score that
touches only the number under suspicion says nothing about whether the new
procedure is sane.

007 first shot recovers only **one** of the four: the psm1 is produced, but is
not marked generated, does not set `$script:ModuleRoot` and does not export
exactly the manifest surface, so three stay red on their merits. The corrected
first-shot gap is 13 assertions, not 14.

### LADDER MECHANISM: explained

Every ladder conformance job had build output in its own tree by a **different
route**, and the written rule named none of them:

- **004** — `transcripts/final-b-conformance.txt` line 5 is
  `Build . ...\scratch\runs\004-verify-clone\PSAzureDevOpsGraph.build.ps1`, and
  the result file names that same directory as its target. The conformance job
  built its own clone.
- **005** — its own provenance: *"The conformance job scored a snapshot of the
  built tree"*. The snapshot carried `output/` with it, and then raced the build
  job's `Clean` (F-7).
- **006** — *"the only run where all three jobs cloned fresh **and** built from
  nothing"*. Its conformance target `f-conf` is a different directory from its
  build target `f-build`, and `produced output/.../PSAzureDevOpsGraph.psm1`
  passes in `f-conf`.
- **007** — target `Temp\r007\c`, never built. The first run to read "three
  clones" as "unbuilt clone", and the reading the rule permitted.

So the ladder's 33/33 and 007's 28/33 were never the same measurement, and the
project could not have known from the records: none of the four says what state
its conformance clone was in. That is now a required field.

## 5. Task 3 — the disclosures

**HARNESS.md gains two hazards**, 12 and 13.

*12 — prompt-borne oracle content.* A measured run's prompt is inside its own
allowlist by construction. Runs 006 and 007 both had their difference mechanisms
and counts written into their prompts, both flagged it themselves, and both
recorded the affected first-shot number as weakened. Promoted out of hazard 9's
tail on the principle that something two runs have tripped over is not a
corollary. The rule: a comparison specification goes **after the gate**,
referring to prior run records generically.

*13 — case-annotated comments.* The `ClaudeTesting` fixture names its own cases
in comments, and reading the fixture is the task, so every run has read them by
design. The fixture is frozen; stripping it now would invalidate five runs'
comparability. Disclosed, with the vocabulary corrected: **"blind" means the
oracle, the run records and the plugin were unread — never that the fixture was
unread.**

**Runs 003–007 each gain `## Blindness caveats`**, additive; every existing
caveat section stands. Each says which bounds apply *to that run*:

| Run | fixture comments | prompt-borne | scoring protocol |
|---|---|---|---|
| 003 | applies | does not — nothing preceded it to leak | **does not** — its conformance clone *was* built; `produced output/...psm1` passes in its own result file |
| 004 | applies | does not | does not — the conformance job built its own clone |
| 005 | applies | **weakly** — its prompt said 004's differences were "four convention decisions, zero edge errors", which is half the answer without the mechanisms | the raced first shot only, already corrected in its record |
| 006 | applies | **applies**, the worst instance | does not — all three jobs built |
| 007 | applies | **applies**, and it lands on the number the headline rests on | **applies** — 28/33 superseded by 32/33 |

Two corrections fell out of writing these, and both are in the run records:

1. Run 007's claim that it and 003 "scored identically on conformance at first
   shot — 19/33" does not survive. 003's clone was built, 007's was not; under
   one procedure they are 19 and 20. The larger point — same mistakes, mechanism
   for mechanism — is untouched.
2. Run 005's prompt leak was not previously recorded anywhere. It is weaker than
   006's and it is real.

**The TF fixture scan** — read-only, 40 files, every comment, every
`description` string, every README, against `evals/tf/fixture/cases.md`.
Verdict: **findings listed**, and worse than the AzDO fixture on this vector.
[`tf-fixture-comments.txt`](tf-fixture-comments.txt) has all of it; the
headline items are a comment reading *"Case 3, the cross-repository output
reference"*, a README pointing at `evals/tf/fixture/cases.md` **by path**, a
variable description reading *"The absence case: a graph that invents a
reference for this is wrong"*, and the case-5 dependency chain drawn as an
arrow diagram in a comment with each link numbered at its site.

**Nothing was amended** — decision 0011 freezes it. tf-003 moves to the top of
the backlog as a *decision*, not a run, with three costed options and a
recommendation (a second, unannotated fixture, which also answers backlog
item 9). The choice is the operator's.

## 6. Task 4 — the README rewrite

The with/without section is rebuilt on run 007's drafted sentence,
verbatim-in-substance. Its load-bearing claims, all of which move **down or
sideways**:

- all four runs permitted to iterate reached 12/12 within two iterations;
- the control's first shot was the closest of the four;
- what the plugin reliably supplies is first-shot conformance to house style —
  33/33 against 19/33, about fourteen assertions not derivable from the brief;
- **it buys shape, not correctness**;
- a **single control** cannot say whether the conventions are the hard part or
  the dependency computation was never hard for this model.

The table gains run 007's column with **both** conformance protocols and a
re-derived row. Five caveats are attached as `<sup>` markers with a prose list
under the table rather than a footnote block — each one links the artifact that
states it. The mechanism breakdown gains 007's column, and the line "the plugin
fixed four behavioural errors" becomes "the plugin fixes three behavioural
errors **at first shot**, and the control fixes them in one iteration", which is
what the five runs actually show.

Claims elsewhere in the README that the control moved: the intro's "four times",
"Status, honestly" (five bullets rewritten, three added), "What a run costs"
(007's 181 minutes, with the reason it is not comparable), "Why not just prompt
Claude", the PAT-scan count, the install-section pointer, and the tf-003
paragraph. The three install commands stay; see Deviation 3 on their tag.

## 7. Task 5 — item 19 doc maintenance

| Document | What landed |
|---|---|
| ch. 02 | run 007 closes the "baseline never iterated" gap, and what leaving it open cost; the scoring-state lesson at the point where the baseline is scored |
| ch. 04 | new §"It happened again, on the run the headline depends on" — the 007 recurrence, why it cost more than 006's, and hazard 12; new §"The fixture, when the fixture is chatty" — hazard 13 and the write-your-next-fixture-mute rule; a second honest limit (freshness bounds what a session *remembers*, not what it is *handed*); checklist step 6 strengthened |
| ch. 05 | new §"Re-derive, don't quote — the worked example": the 28→32 rescore, why 006 was re-scored *because it should not move*, and the falsification triple; one checklist line added |
| ch. 07 | three entries — the RequiresBuild/three-clone incompatibility (Scores that were not comparable), the fixture-comment bound (Contamination and blindness), the mechanism-list leak committed twice (The director's own mistakes) |
| docs/testing | §6 gains "A third thing the denominator does not protect you from" and the 007 first-shot/final table; §7 gains `Score-Clone.ps1` as step 0 and a fourth "not decoration" bullet; the tf-003 paragraph is now "blocked" |
| four documents | "the eleven hazards" → "the thirteen hazards" (README, ch. 07, ch. 10, docs/testing) |

Run 007's two Part-4 module defects are recorded as **LEDGER backlog items 26
and 27**, explicitly as candidate skill lines. **No skill was edited.**

## 8. Task 6 — the release

`.claude-plugin/plugin.json` → `1.0.1`. CHANGELOG `## 1.0.1`, user-facing, three
sections: the corrected claim, the scoring repair as it affects someone running
the suite against their own module, and the two disclosed limits — opening with
"Nothing you install changes."

Tag `v1.0.1`, annotated, message as specified. Branch and tag pushed.

**The tag is not the branch tip, and that is deliberate.** `v1.0.1` names
`1a947a4`, the commit that carries the release. `verify.ps1`'s falsification
and its two transcripts landed afterwards at `c58eb52`, because a verify script
cannot record the result of falsifying itself before it has been falsified. The
tag is a complete release on its own terms - `skills/` and `commands/`
byte-identical to `v1.0.0`, manifest `1.0.1`, CHANGELOG entry, rewritten
README - and the later commit adds no consumer-visible content. Pass 0030 hit
the same divergence and recorded it rather than moving a pushed tag; the same
is done here. Moving a published tag is not on the table.

## 9. Verification

`verify.ps1`, nine checks, re-derived from a fresh clone at the pinned commit.
Checks 1 and 2 clone and build the target module twice and take a few minutes;
`-SkipRescore` skips them and **reports the skip**.

**Checks: 9 of 9 agree, exit 0.** **Probes: 6 fire, 2 checks declare no probe
and say why, exit 0.** Full transcript: [`verify.txt`](verify.txt).

The probes cover checks 3, 4, 5, 6, 7 and 8. Checks 4 and 8 share one probe -
a commit that edits `skills/` *and* `Conformance.Tests.ps1`, with the local
`v1.0.1` tag force-moved onto it - because those two checks carry the pass's
two strongest claims (no skill changed, no assertion weakened) and a claim
that strong should not rest on a check nobody has broken. Checks 1 and 2 are
reported as having no probe, with the reason, rather than being quietly
absent: check 2 *is* a falsification, and its control row is its own probe.

**One probe did not fire on its first attempt, and the probe was at fault.**
It renamed `## Blindness caveats` to `## Blindness caveats REMOVED BY PROBE`,
which still matches `(?m)^## Blindness caveats` - so the file changed, the
did-this-change-anything guard was satisfied, and a check that was working
correctly was reported as DOES NOT FIRE. That is hazard 4 one level in: a
break that lands without breaking the thing under test. The probe now removes
the heading and asserts the check's own pattern is gone before the check
re-runs. Recorded here because a probe that reports a false DOES NOT FIRE is
the mirror image of the one that reports a false green, and the second is the
only one this project had written down.

A second defect in the first draft of `verify.ps1`, fixed before the recorded
run: `Fired` compared the failure list's **total** against zero, so a probe
would have reported "fires" on a failure some earlier check had produced for
an unrelated reason. It now measures the delta this check contributed, and
discards the deliberate failures so the summary stays honest.

## 10. Deviations

1. **The prompt's "EXACTLY one changed line" under `.claude-plugin/` is not
   achievable, and following it literally would ship a release the repository's
   own validator rejects.** `.claude-plugin/` carries **three** version strings:
   `plugin.json.version`, `marketplace.json.metadata.version`, and
   `marketplace.json.plugins[0].version`. `tools/publish/Publish-Local.ps1`
   asserts the first and third agree, citing decision 0013 in the comment.

   This was measured, not argued. With only `plugin.json` bumped:

       VALIDATION FAILED (committed marketplace):
         - committed entry 'psmodule' version '1.0.0' disagrees with
           plugin.json version '1.0.1'

   All three were bumped; the validator then passes, reporting
   `plugin entry : psmodule 1.0.1  source './'  version agrees`. The
   *intent* of the constraint is met exactly — `skills/` and `commands/` are
   byte-identical to `v1.0.0` and the only changes under `.claude-plugin/` are
   version fields going `1.0.0` → `1.0.1`. `verify.ps1` check 4 asserts that
   stronger form rather than the one the prompt named, and says so in a comment.
   Recorded as **LEDGER item 28**, because the one-line rule is written down in
   more than one place and should either become a three-line rule or be made
   true by deriving the marketplace versions at validation time.

2. **The `∥` markings were executed serially by one session, not in parallel.**
   The three jobs of task 3 are independent and were done in the marked order
   with the review the prompt asks for; nothing was delegated to a subagent.
   The outcome is identical and the artifacts are the same; only the wall-clock
   differs.

3. **The README's install pin moved from `@v1.0.0` to `@v1.0.1`.** The prompt
   says "the three install commands stay", which is read as *do not remove or
   restructure that section* — it is not read as *ship a release nobody can
   install by following the front page*. Three occurrences changed, all in the
   Install section, all the same tag string. This is not a claim moving up:
   `skills/` and `commands/` are byte-identical between the two tags, so a
   consumer pinned at either gets the same plugin.

4. **Scoring clones were made under `C:\Users\jlbal\AppData\Local\Temp\p0033`,
   not under the session scratchpad.** The scratchpad path is long enough that
   `git clone` dies with *"cannot write keep file … Filename too long"* before
   writing an object — observed, not assumed. Run 007 used `Temp\r007` for the
   same reason. `verify.ps1` carries the same short root and a comment saying
   why, so the next reader does not diagnose it as a network fault.

5. **The re-score was extended beyond the two commits the prompt named.** The
   prompt asks for both finals; both first shots were scored as well, because
   the README's headline comparison is a first-shot comparison and would
   otherwise have inherited the defect the pass exists to fix. It changed a
   number: 007's first shot is 20/33 corrected, not 19/33, so the "003 and 007
   scored identically at first shot" observation in run 007's record does not
   survive. Both figures are in `rescore.txt` and both are in the README table.

6. **Run 005's prompt leak is newly recorded and was not in the prompt's list.**
   The prompt names 007 for prompt-borne mechanisms and 006 for its own
   self-leak. Writing 005's caveat section required reading
   `plans/0027-run-005/plan.md`, whose task 7 tells the builder that run 004's
   differences were *"four convention decisions, zero edge errors"* — no
   mechanisms, no counts, but the shape of the answer. It is recorded as a weak
   instance rather than omitted because the section it sits in claims to say
   which caveats apply to that run.

7. **The "eleven hazards" count appears in four live documents and was
   corrected in all four.** Journal entries that say "eleven" are history and
   were left alone.

8. **The `v1.0.1` tag is one commit behind the branch tip**, for the reason in
   §8. Recorded rather than repaired: re-tagging a pushed tag is a history
   rewrite by another name, and decision 0009 forbids that shape of fix even
   where it is technically available.

9. **`verify.ps1`'s first draft had two probe defects**, both found by running
   `-FailCheck` rather than by reading it, both fixed before the recorded run,
   and both written up in §9. They are named here as well because the pass
   protocol asks for anything followed that seems mistaken, and "the verify
   script was believed before it was falsified" would have been exactly that.

## 11. Cost

- Wall-clock: about 3 hours, of which roughly 25 minutes is clone-and-build time
  across seven scoring runs (four re-scores, two falsification rows, one gate
  control).
- Suite runs: 7 conformance scoring runs, plus the acceptance suite 4 times and
  `verify.ps1`. Clones: 8 of the target, 1 of the harness per verify invocation.
- Target pushes: **0**. Azure DevOps: read-only, via run 006's build only.
- No token count: not measurable from inside the session.
