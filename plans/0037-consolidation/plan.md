# Pass 0037 — Consolidation: fixture-2 case scorer, the bounded claim, v1.1.1

Full tier. Harness only. The pass that puts tf-003's instrument where the next
run will find it, says what tf-003's number licenses, and releases both.

## 1. Prompt

Supplied in full at the head of the session. Seven task groups, five named
spot-checks, an acceptance test to be committed verbatim.

## 2. Preconditions, measured at start

| # | Check | Result |
|---|---|---|
| 1 | Harness tree clean, on `main` at `245b18f` | clean |
| 2 | Branch `pass-0037-consolidation` created from it | yes |
| 3 | No tag `v1.1.1`, locally or on the remote | absent |
| 4 | `evals/tf/fixture2/Test-TfFixture2Case.ps1` | absent |
| 5 | `plans/0036-tf-003/Test-Tf003Case.ps1` | present |
| 6 | `git diff v1.1.0..main -- skills/ commands/` | **empty** |

## 3. Acceptance test — red first

[`accept.Tests.ps1`](accept.Tests.ps1), committed exactly as supplied.
**7 of 8 failed.** [`accept-red.txt`](accept-red.txt).

**The eighth was green at start, and for the wrong reason.** *"cases.md false
clause corrected"* asserts `Should -Not -Match 'only node in the fixture with
neither'`, and the clause it names is **line-wrapped** in the file
(`cases.md:246-247`), so the one-line pattern never had anything to match. The
assertion cannot witness the correction in either direction. It was recorded and
**not rewritten** — a plan's acceptance test is frozen under
[decision 0004](../../decisions/0004-plan-artifacts-are-frozen.md) — and the
correction is witnessed by the falsification set instead. This is
[hazard 8](../../evals/HARNESS.md) again, arriving inside an acceptance test
this time.

## 4. Tasks

### Group 2 — the case scorer, promoted (backlog 29, and half of 36)

`plans/0036-tf-003/Test-Tf003Case.ps1` →
[`evals/tf/fixture2/Test-TfFixture2Case.ps1`](../../evals/tf/fixture2/Test-TfFixture2Case.ps1),
with its falsification promoted beside it as
[`Invoke-TfFixture2CaseFalsification.ps1`](../../evals/tf/fixture2/Invoke-TfFixture2CaseFalsification.ps1).
Backlog 36 offered a `-Fixture` switch on fixture 1's scorer as the alternative;
**a second file was taken**, because fixture 1's is the instrument tf-001 and
tf-002 were scored with, and the two fixtures' cases differ in substance rather
than only in ids.

Two things changed in the promotion beyond paths:

1. **Case 6's rule**, per the prompt, and it is the one wrong case rule.
2. **A duplicate node id is now refused rather than scored** — the scorer keys
   every node by id, so a duplicate overwrites its own entry and a defective
   graph scores clean. That is the scorer-side half of the blindness
   [backlog 32](../../LEDGER.md) found in the comparator, in a second
   instrument, and it is a refusal rather than a failed case because an
   unscoreable graph is not a graph with a low score.

**The `cases.md` correction, and what it is a correction to.** Case 6 called the
unused variable *"the only node in the fixture with neither"* an incoming nor an
outgoing edge. Derived from the oracle rather than assumed: **ten** nodes satisfy
that literally — the variable, three `repository` nodes and six `provider` nodes,
which take part in containment rather than value flow. The corrected clause is
scoped to value flow, the superseded wording is **struck through rather than
deleted**, and the note says in the document that this corrects prose *about* the
oracle: `expected-graph.json` and the fixture repositories are untouched, and the
nine nodes are the evidence the sentence was wrong.

**The rewritten discriminator is stricter, and that is measured.** It pins the
whole edgeless set of ten by id. A graph with the diamond's shared module
isolated — a defect no named case asserts against — scores **7 / 7 under the
plans-era form and 6 / 7 under the promoted one**, and that comparison is a row
in the falsification report rather than a sentence here.

[`case-scorer.txt`](case-scorer.txt): control 7 / 7, seven mutations each
defeating its own case and no other, mutation 8 refused, the strictening
demonstrated.

**Wired into `Invoke-TfSuite.ps1`, and the count deliberately re-pinned 8 → 18**
— oracle layer 8, case layer 10 (control, seven mutations, the refusal, the
strictening). The composition is stated in the runner, in the report it prints
and in the LEDGER. Fixture 1 stays at 15.
[`suites.txt`](suites.txt): `FIXTURE1: 15 passed, 0 failed`,
`FIXTURE2: 18 passed, 0 failed`.

**Both new checks were broken on purpose and seen red before the 18 was
trusted** — [`case-layer-falsification.txt`](case-layer-falsification.txt).
Disabling the refusal, and reverting case 6 to the value-flow-only form, each
takes the case layer to 9 / 10 and the suite to `FIXTURE2: 17 passed, 1 failed`
with exit 1. The scorer is restored from a backup in a `finally` block and the
clean re-run is in the same report.

### Group 3 — tf-003, re-scored

The run's numbers were taken with an instrument that no longer exists in that
form, so they were **re-derived, not re-read**. Fresh clones of both of the
run's own commits under a short temp root, built, with the graphs regenerated
from read-only clones of the three fixture repositories at their decision-0014
SHAs — verified as matching before anything was scored.

| | recorded | re-derived | held |
|---|---|---|---|
| build, first shot / final | exit 0 / exit 0 | exit 0 / exit 0 | yes |
| module tests | 92 / 92, 96 / 96 | 92 / 92, 96 / 96 | yes |
| coverage | 92.48%, 92.39% | 92.48%, 92.39% | yes |
| differences | 184 → 0 | 184 → 0 | yes |
| nodes / edges | 99 / 99, 88 / 88 | 99 / 99, 88 / 88 | yes |
| **functional-tf** | **6 / 7 → 7 / 7** | **6 / 7 → 7 / 7** | **yes** |

Case 7 is still the single first-shot failure, still on the id convention alone.
The regenerated final graph is **byte-identical** to the `graph.json` the record
ships. [`tf-003-rescore.txt`](tf-003-rescore.txt).

The run record is **appended to, never rewritten**: pass 0036's text stands and
a dated correction note sits below it.

### Group 4 — the bounded claim (backlog 36)

`README.md`'s *"The cross-language measurement"* said tf-003 was **blocked** and
that no generalisation claim existed. Replaced with the result and the bound
given the same weight, built on the run record's drafted sentence in substance,
plus a three-run comparison table with four footnotes each naming its artifact
and the standing warning that the raw counts do not compare across the three.

Three *Status, honestly* bullets replace the stale one. **Claims moved down and
sideways; none moved up.**

### Group 5 — the manual (backlog 19)

- **Chapter 02** gains **stage 7b**, the generalisation run: what it licenses,
  what it does not, and the ordering rule that a plugin-off control is decided
  *before* the plugin-on numbers exist. Stage 8 corrected — it still said
  packaging had not landed.
- **Chapter 03** gains **section (e), grade the grader before the graded**.
- **Chapter 07** gains two entries: the oracle that failed its own case, and a
  pin that arrived as its own placeholder — where the rule is derive-then-verify
  and the dangerous version is a *stale* substituted value, not an empty one.
- **docs/testing** gains the case layer as a seventh layer, and the 8 → 18
  re-pin with its reason.

### Group 6 — v1.1.1

PATCH under [decision 0013](../../decisions/0013-harness-release-tagging.md).
Three version strings, the README install pin, a user-facing CHANGELOG entry
saying that 1.1.0's *"the Terraform skills are unmeasured"* no longer holds —
and what the measurement does not license. Annotated tag carrying the
with/without headline and the bound, branch and tag pushed.

### Group 7 — records

Acceptance **8 of 8** ([`accept-green.txt`](accept-green.txt)), this file,
[`verify.ps1`](verify.ps1), [`journal 0037`](../../journal/0037-consolidation.md),
the LEDGER, and `main` fast-forwarded per
[decision 0009](../../decisions/0009-agent-moves-both-mains.md).

## 5. Verify script

[`verify.ps1`](verify.ps1), five checks, **5 / 5**
([`verify.txt`](verify.txt)). Checks 1, 2 and 4 run from a **fresh clone of the
harness at the committed tip**, not from the working tree — the artifacts above
were produced from the working tree, and re-running the same scripts there
would re-derive nothing about what was committed. Check 1 **regenerates
mutations 3 and 8 itself** rather than asking the falsification driver whether
its own report is right.

| # | Check | Result |
|---|---|---|
| 1 | promoted scorer from a clone: control 7 / 7, mutation 3 reddens only case 3, mutation 8 refused | PASS |
| 2 | fixture 1 at 15 / 15, fixture 2 green at its new pin 18 / 18 | PASS |
| 3 | tf-003 rescore reproduced from fresh built clones; graph byte-identical; the note is present | PASS |
| 4 | every number in the README generalisation section resolves to a run record or plan artifact (10 / 10) | PASS |
| 5 | `git diff v1.1.0..v1.1.1 -- skills/ commands/` empty; all six changed `.claude-plugin/` lines are version fields | PASS |

Falsified with `-FailCheck`, one row per check:
[`verify-falsification.txt`](verify-falsification.txt). **Each break reddens its
own check and only its own** — a break that reddened two would not have shown
that either was discriminating.

## 6. Deviations

1. **The tag was cut after the LEDGER entry, not between groups 6 and 7.** The
   prompt orders the release before the records, but decision 0013 says *"not
   green except for the tag's own assertion"*, and the LEDGER line is a separate
   assertion in the same acceptance test. The LEDGER landed first so that
   nothing but the tag's own assertion was outstanding when `v1.1.1` was cut;
   `accept-green.txt` records that it read 7 / 1 at that moment.
2. **One acceptance assertion was green at start**, for the line-wrapping reason
   in §3. Recorded, not repaired.
3. **The old wording survives once in `cases.md`, struck through**, as the
   superseded text. A whitespace-insensitive search still finds it; a literal
   one does not. Recorded because "the false clause is gone" would otherwise be
   an overstatement — what is gone is the *claim*.
4. **The falsification driver was written into `evals/` rather than into this
   plan directory.** The prompt asked for the scorer to be falsified in place
   and did not say where the driver lives; putting it beside the scorer is the
   whole point of backlog 36, and leaving it here would have re-created the
   problem this pass exists to fix.
5. **Two extra checks beyond the seven mutations** — the duplicate-id refusal
   and the strictening demonstration — so the case layer is ten and not eight.
   Both are additive; neither weakens anything.
6. **`plans/0036-tf-003/Test-Tf003Case.ps1` was left in place**, not deleted.
   Decision 0004 freezes plan artifacts, and the strictening check reads it as
   the baseline it is compared against.
7. **Chapter 02 stage 8 was corrected** beyond the named scope: it asserted that
   packaging had not landed, which has been false since pass 0030. A false
   statement left in a file being edited for accuracy is not a scope boundary.
8. **Scoring and verify clones under `C:\Users\jlbal\AppData\Local\Temp\p0037`**,
   not the session scratchpad, for pass 0033's reason: the scratchpad path is
   long enough that `git clone` fails writing a keep file.
9. **Two pre-existing broken relative links** in the tf-003 record's drafted
   README sentence — `evals/tf/fixture2/` and
   `runs/tf-002-convention-and-case3/`, written README-relative because the
   block is a draft *for* the README. Not repaired: the record is append-only,
   and the sentence has now landed in the README where those paths resolve.
10. **`∥` was not used; nothing ran in parallel.** Degree of parallelism 1.

Allowlist breaches: **zero**. AzDO access was six read-only clones and no
writes; **zero builds queued**. Both oracles, both fixtures' repositories and
all AzDO objects are untouched — `git status --porcelain -- evals/tf/fixture/
evals/tf/fixture2/repos/ evals/tf/fixture2/expected-graph.json` clean
throughout. No target pushes. `skills/` and `commands/` unedited.

## 7. Cost

- Six clones of PSTerraformGraph and the three fixture repositories across
  scoring and verify; four builds of the target.
- Target pushes: **0**. Harness tags: 1 (`v1.1.1`).
- No token count: not measurable from inside the session.
