# LEDGER — maintained by the agent as the last task of every pass

The chat context points here; this file is the source of truth
for counters and pins. Update it in the same commit as the work
that changes it.

## Passes
Last landed: 0031. Next: 0030 — packaging (marketplace.json,
cold-install proof). 0030 is still the next pass to run: 0031 was
taken out of order, deliberately, because the manual and the local
publish path do not depend on packaging and the guard in
`tools/publish/Publish-Real.ps1` is what refuses until 0030 lands.

## Runs
AzDO-module (runs/NNN-*): **ladder COMPLETE at 004–006** (passes
0026-0028). All three show three complete score lines, so the 0029
rider is eligible and ran. The next run series is the operator's
decision — nothing is scheduled.
Terraform (runs/tf-NNN-*): last tf-002, next tf-003 (measured,
blind — not yet scheduled).

## Versions
PSAzureDevOpsGraph: v0.2.0 (next touching plan: v0.3.0)
PSGraphRender: v0.13.0
PSGraphRenderToHtml: v0.1.0 (next: v0.2.0)
PSTerraformGraph: v0.2.0
psmodule manifest: 0.1.0 (re-versioned at packaging, 0030;
v1.0.0 reserved for "passed the ladder")

## Pins
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
TF fixture SHAs (decision-0012 re-freeze):
  TfFixtureShared   0af6ee33854bedb4147d0b13cc6db1311687775b  (unchanged)
  TfFixtureNetwork  24f27be92e583b6dfc9208bca42f8ec0baf5004b  (unchanged)
  TfFixtureApp      44ea9338ff35aef328bfa8d51835fc32bea590dd  (amended)

## Backlog (priority order; operator reorders)
1. Runs 004-006 + 0029 final README
2. 0030 packaging: marketplace.json, cold-install proof
3. Fixture restore drill (Sync-Fixture restore direction)
4. Per-skill ablation runs (suspects first)
5. Mirror assertion + dependency-wave ordering (post-ladder)
6. tf-003 generalisation measurement (blind Phase 1)
7. Portability / non-graph functional layer (on trigger only)

### Added by pass 0025

8. **PSTerraformGraph: `Export-TfConfigurationGraphHtml` is exported
   and no test invokes it.** Conformance 40/41 on that repository, the
   one failure being the invocation check. Found after v0.2.0 was
   tagged and pushed; fixing it would have meant rewriting a pushed tag
   or landing on `main` past the tag it follows, so it was recorded
   instead. Belongs to the next pass that opens that repository.
9. **The three `tf-<role>` skills tf-001 proposed were deliberately not
   written.** They would carry this fixture's specific answers, and
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

**Precondition note for any pass written against the four-path pin.**
Pass 0031's prompt asserted that
`git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/` is
empty at start. It was not, and has not been since pass 0029 — see the
Pins section above, which already prescribes the three-path form. The
second consecutive prompt to carry the stale form. Pass 0031 changed
nothing under any of the four paths; its `verify.ps1` asserts that
directly rather than asserting the pin the prompt named.
