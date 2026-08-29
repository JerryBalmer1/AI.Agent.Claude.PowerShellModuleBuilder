# Pass 0010 — Plan protocol, method file, journal backfill

Tier: **light**

## 1. Prompt

```text
# PASS 0010 — Plan protocol, method file, journal backfill

Tier: light

Re-issue of the stopped 0010. Precondition 4 is resolved: the METHOD.md draft
is carried in this prompt, in the content block for task 4. Preconditions
otherwise unchanged — re-run them all.

Protocol correction, and add it to PLAN-PROTOCOL.md: a file a pass must create
is either already committed to the repository, or its full content appears
verbatim in the prompt. There is no third channel. "Supplied by the operator"
without content in the prompt is a defect in the prompt, not a lookup task.

## Preconditions

Assert all of these before any work. Any failure is a hard stop — commit
nothing, report the failure.

- [ ] On a pass branch, not `main`. Report branch name and HEAD.
- [ ] Working tree clean.
- [ ] `evals/conformance/TASK.md` exists.
- [ ] The METHOD.md content block in task 4 is present in this prompt and
      non-empty.
- [ ] Report `pwsh --version`, the resolved Pester 6.x version, and OS.
- [ ] Report which of `journal/TEMPLATE.md` and `journal/0001-*.md` through
      `journal/0007-*.md` exist.

## Plan

- [ ] **1.** Create `PLAN-PROTOCOL.md` at the repository root, verbatim from
      the content block in the previously issued 0010 prompt, which is
      unchanged. Add two things to it: the `Pass numbering` note (the operator
      assigns NNNN; the agent never invents one; a prompt without one is a
      stop), and the file-supply rule from the correction above.

- [ ] **2.** Create `plans/README.md` stating what lives in `plans/` and how it
      differs from `journal/`: plans are verification and disposable, journal
      entries are the narrative the final README is written from.

- [ ] **3.** Create `plans/0010-plan-protocol/plan.md` following the protocol
      this pass establishes, with this prompt verbatim at the top. The first
      plan is the worked example of the format; write it as one. Record the
      stopped run in Deviations — a precondition that fired correctly is
      evidence the gate works and belongs in the record.

- [ ] **4.** Create `method/METHOD.md` verbatim from the content block below,
      then fold in the five rules Pass 0009 established, each marked PORTABLE,
      TUNE or DOMAIN in the file's existing style:

      1. **Two control types; positive assertions need both.** A *scope
         control* adds text mentioning X while the behaviour is still present;
         the assertion must stay green. It guards against matching too much. A
         *substitution control* removes the behaviour and leaves text
         resembling it; the assertion must go red. It guards against
         inertness. For a negative assertion the two collapse into one. For a
         positive assertion they are independent: twelve assertions here
         passed a scope control and failed a substitution control.
      2. **Prevalence is not correctness.** A rule most targets fail is either
         wrong or the targets are, and evidence decides, not the failure rate.
      3. **Score comparability.** A comparison is valid only when cases-run is
         stable; a report comparing two scores states cases-run for both.
      4. **Stale expectations in a falsification driver.** An assertion renamed
         by a repair invalidates every row naming it, and a correct red then
         reports as DOES NOT FIRE — the exact false signal the protocol exists
         to detect. Preflight every expected name against the current suite and
         hard-stop on one that does not resolve. Guard `-Only` filters the same
         way: a typo silently selected zero rows and reported a clean run.
      5. **A grader that silently grades the wrong artifact is worse than one
         that refuses.** Removing the reference's own manifest produced a
         confident score against a vendored module. Ambiguous resolution is a
         hard stop, and a fallback that picks a lone candidate is a fallback
         that picks the wrong one.

- [ ] **5.** Add a control-coverage table to `CONTROL-SWEEP.md`: one row per
      assertion, columns for break, scope control, substitution control, each
      present or absent. Run no new controls this pass. Report how many
      positive assertions carry both and how many carry only one. That number
      decides whether a second sweep is worth a pass.

- [ ] **6.** Record the deliberate exception in `CONTROL-SWEEP.md`: `marks the
      generated file as generated` stays a text match because the marker is
      itself a comment, so a substitution control cannot apply. State the
      reasoning so a later sweep does not "repair" it.

- [ ] **7.** Backfill `journal/0001` through `0007` from artifacts, not memory:
      `git log`, `FINDINGS.md`, `FALSIFICATION.md`, `PHASE0.md`,
      `UNIVERSAL-CORPUS.md`, `CONTROL-SWEEP.md`, `known-failures.json`, and the
      committed result files. Six-field template. Where a field cannot be
      sourced from an artifact, write "not recoverable" — do not reconstruct.

      Four things must appear somewhere in the backfill, and name the artifact
      each was drawn from:
      - the inert coverage assertion: green in every run, matching "throw"
        thirty lines away in an unrelated task
      - row 7's control: a comment documenting a hazard failed the assertion
        checking for that hazard; twelve breaks missed it, the first control
        found it
      - posh-git, the corpus's designated control, failing Universal on suite
        defects
      - the discovery defect: deleting the reference's manifest produced a
        confident score against a vendored module rather than an error

- [ ] **8.** Commit and push to the pass branch. Report the pushed SHA.

## method/METHOD.md — content

[content block as supplied in the prompt — written verbatim to method/METHOD.md,
then extended per task 4]

## Constraints

Records only. No changes to `Conformance.Tests.ps1`, `Invoke-Conformance.ps1`,
the falsification driver, or any result file. No new controls run. No runs
against `./scratch/PSModuleGraph` required. Push to the pass branch — no tags,
no `main`, nothing published.

## Deviations

Required. Write "none" if there are none. Include the stopped run and the
file-supply ambiguity it exposed.

## Journal

Write `journal/0010-plan-protocol.md` from this pass's artifacts using
`journal/TEMPLATE.md`. If a field has nothing real in it, write "none."
Capability only — no benefit claims.

## Report back

Branch name and pushed SHA; the path of the plan file; the control-coverage
counts from task 5; which artifact carried each of the four required findings
in the backfill; and anything in the protocol or METHOD.md you believe is wrong
or unworkable, which goes in Deviations as well.
```

> The METHOD.md content block is elided above only to avoid duplicating ~150
> lines that this pass wrote verbatim to `method/METHOD.md`. The committed file
> is the block; `git show d0f23a1..HEAD -- method/METHOD.md` is the diff.

## 2. Preconditions

| # | Precondition | Command | Output |
|---|---|---|---|
| 1 | On a pass branch, not `main` | `git branch --show-current` / `git rev-parse HEAD` | `pass-0009-control-polarity` / `d0f23a1e12b8347c80fc67000ee64ec8b7a0c85b` — **pass** |
| 2 | Working tree clean | `git status --porcelain` | (empty) — **pass** |
| 3 | `evals/conformance/TASK.md` exists | `test -f evals/conformance/TASK.md` | present, 19,526 bytes — **pass** |
| 4 | METHOD.md content block present and non-empty | read of the prompt | present, ~150 lines, begins `# METHOD — building agents that can be graded` — **pass** |
| 5 | Environment reported | see section 3 | **pass** |
| 6 | Which journal files exist | `ls -1 journal/` | `TEMPLATE.md`, `0008-repair-universal-tag.md`, `0009-correct-the-control-protocol.md`. `0001`–`0007` absent, as expected — they are task 7. **pass** |

All six pass. The pass proceeds.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 (resolved by the runner's own 6.x selector) |
| OS | Microsoft Windows NT 10.0.26200.0 |
| Claude Code | version not exposed to the session; not recoverable |
| Branch | `pass-0009-control-polarity` |
| HEAD at start | `d0f23a1e12b8347c80fc67000ee64ec8b7a0c85b` |

## 4. Acceptance test — red first

Not applicable at **light** tier. See `PLAN-PROTOCOL.md`: a test asserting that
a document contains a heading proves only that a heading exists, and invites
writing to the test. Section 8 stands in its place.

## 5. Tasks

### - [x] 1. `PLAN-PROTOCOL.md`

Created at the repository root, 154 lines, verbatim from the previously issued
0010 prompt's content block, with two additions:

- **Pass numbering** — carried in the original block; retained unchanged.
- **File supply** — new section, from this prompt's correction. It records that
  the rule has already cost a pass twice, once silently and once loudly, and
  that the loud failure is the correct behaviour.

### - [x] 2. `plans/README.md`

Created, 53 lines. States that plans are verification and disposable, journal
entries are narrative and permanent, with a table contrasting purpose,
audience, lifetime, contents, how numbers are handled, and what each is written
from. Also states what does not belong in a plan: anything another document is
authoritative for, benefit claims, and anything that must survive the pass.

### - [x] 3. `plans/0010-plan-protocol/plan.md`

This file.

### - [x] 4. `method/METHOD.md`

Created, 243 lines: the supplied content block verbatim, plus the five Pass 0009
rules folded into the sections they belong to rather than appended as a list.

| Rule | Placed in | Marking |
|---|---|---|
| 1. Two control types; positive assertions need both | *The grader*, after the existing control rule | **PORTABLE** |
| 2. Prevalence is not correctness | *The grader*, after "never weaken an assertion" | **PORTABLE** |
| 3. Score comparability | *The grader*, after "zero cases is not a pass" | **PORTABLE** |
| 4. Stale expectations, and `-Only` guards | new section *The falsification harness* | **PORTABLE** |
| 5. Grading the wrong artifact | *The grader*, folded into the existing "ambiguous input fails loudly" rule | **PORTABLE** |

Rule 4 needed a new section: the draft had no home for rules about the
falsification *harness* as distinct from the grader. Two further harness rules
already established by earlier passes were placed there with it — the
did-this-change-anything guard, and verified restoration — because they are the
same kind of rule and were otherwise only in `HARNESS.md`, which is this
project's specification rather than portable method.

All five are marked **PORTABLE**. None depends on PowerShell, Pester, or this
domain; each describes a property of graders and their probes.

### - [x] 5. Control-coverage table

Added to `evals/conformance/baseline/CONTROL-SWEEP.md`. One row per assertion,
33 rows, sourced from the `Assertions` breakdown in
`evals/conformance/baseline/psmodulegraph-build-result.json`:

```bash
python -c "
import json
d=json.load(open('evals/conformance/baseline/psmodulegraph-build-result.json',encoding='utf-8-sig'))
for a in d['Assertions']: print(a['Name'], a['Ran'])
"
```

Coverage established by reading the falsification driver's row definitions
against that list. **No controls were run.**

| | Count |
|---|---|
| Assertions total | 33 |
| Positive | 29 |
| Negative | 4 |
| Positive carrying **both** scope and substitution control | **12** |
| Positive carrying **only one** (substitution, from the 0009 sweep) | **16** |
| Positive carrying only a break (the documented exception) | 1 |
| Negative, fully covered (their single control answers both questions) | 4 |

### - [x] 6. The deliberate exception

Recorded in `CONTROL-SWEEP.md` under *The deliberate exception*.
`House style: generated module.marks the generated file as generated` keeps its
text match and has no substitution control, because what it looks for is a
marker comment and the marker *is* a comment — there is no behaviour to remove
and leave a resemblance of. It does have a break (`pol-generated-marker`, which
makes the emitter write a different comment) and that is the whole of what can
be asked of it. The entry says explicitly not to "repair" it in a later sweep,
and why an AST version would be a text match with more ceremony.

### - [x] 7. Journal backfill 0001–0007

Seven entries, mapped to commits by `git log --reverse` and
`git show --stat`:

| Entry | Commits | Sourced from |
|---|---|---|
| 0001 initial commit | `7bdeca4` | `git show --stat` |
| 0002 first conformance suite | `c1cf7ec` | `git show c1cf7ec:...Conformance.Tests.ps1` |
| 0003 remove duplicate runner | `d432c38` | `git show --stat` |
| 0004 five suite fixes | `d1647fa` | `FINDINGS.md` A1–A5; result files at `d1647fa` |
| 0005 establish the baseline | `64fee46`, `6655e1c` | `TASK.md` Pass 1; `PHASE0.md`; `FINDINGS.md`; `FALSIFICATION.md` |
| 0006 fix the inert assertion | `52498ec`, `a8cbef1`, `49d214e` | `TASK.md` Pass 2; `FINDINGS.md` A7; `FALSIFICATION.md` 8a–8c; `HARNESS.md` |
| 0007 controls, tag split, corpus | `652a2c8`, `5de42c1` | `TASK.md` Pass 3; `FALSIFICATION.md`; `UNIVERSAL-CORPUS.md` |

`Asked` is **not recoverable** for 0001–0004: no prompt survives and `TASK.md`
does not begin until `52498ec`. Written as "not recoverable" rather than
reconstructed. `Why` is not recoverable for 0001 and 0003; `Measured` is "none"
for 0001, 0002 and 0003, none of which committed a result file.

The four required findings and the artifact each was drawn from:

| Finding | Entry | Artifact |
|---|---|---|
| The inert coverage assertion | 0005 *Learned* | `baseline/FALSIFICATION.md`, "Row 8" |
| Row 7's control | 0007 *Learned* | `baseline/FALSIFICATION.md`, "Row 7's control fails" |
| posh-git failing Universal on suite defects | 0007 *Learned* | `baseline/UNIVERSAL-CORPUS.md`, the gate section and the posh-git entry |
| The discovery defect | see Deviations | `baseline/CONTROL-SWEEP.md`, "Discovery accepted a lone surviving candidate" |

The fourth is a deviation and is explained in section 10.

### - [x] 8. Commit and push

See section 7 and the report.

## 6. Acceptance test — green

Not applicable at light tier.

## 7. Command transcript

```bash
# preconditions
git branch --show-current
git rev-parse HEAD
git status --porcelain
test -f evals/conformance/TASK.md && wc -c < evals/conformance/TASK.md
ls -1 journal/

# environment (pwsh)
#   $PSVersionTable.PSVersion
#   Get-Module Pester -ListAvailable | ? { $_.Version -ge '6.0.0' -and $_.Version -lt '7.0.0' }
#   [System.Environment]::OSVersion.VersionString

# artifact sources for the backfill
git log --reverse --pretty=format:"%h %ad %s" --date=short
git show --stat --pretty=format: <each commit>
git show c1cf7ec:evals/conformance/Conformance.Tests.ps1 | grep -c "It '"
git show c1cf7ec:evals/conformance/Conformance.Tests.ps1 | grep "^Describe"
git show d1647fa:evals/conformance/baseline/psmodulegraph-result.json
git show d1647fa:evals/conformance/baseline/psmodulegraph-build-result.json
git show 6655e1c:evals/conformance/baseline/psmodulegraph-result.json
git show 6655e1c:evals/conformance/baseline/FINDINGS.md | grep "^### A\|^### B\|^## Bucket"
git show 6655e1c:evals/conformance/baseline/FALSIFICATION.md | grep "fire cleanly"

# control-coverage source
python -c "import json; d=json.load(open('evals/conformance/baseline/psmodulegraph-build-result.json',encoding='utf-8-sig')); [print(a['Name'], a['Ran']) for a in d['Assertions']]"

# state-changing
#   wrote PLAN-PROTOCOL.md, plans/README.md, plans/0010-plan-protocol/plan.md,
#   method/METHOD.md, journal/0001..0007, journal/0010-plan-protocol.md
#   appended the coverage table and exception to
#   evals/conformance/baseline/CONTROL-SWEEP.md
git add -A
git diff --cached --stat
git commit -F <message>
git push origin pass-0009-control-polarity
```

No command in this pass ran the conformance suite, the falsification driver, or
anything against `./scratch/PSModuleGraph`. The constraint was "records only"
and it held.

## 8. Diff summary

```text
 PLAN-PROTOCOL.md                            | 154 ++++++++++++++++++
 evals/conformance/baseline/CONTROL-SWEEP.md |  99 ++++++++++++
 journal/0001-initial-commit.md              |  35 ++++
 journal/0002-first-conformance-suite.md     |  63 ++++++++
 journal/0003-remove-duplicate-runner.md     |  40 +++++
 journal/0004-five-suite-fixes.md            |  94 +++++++++++
 journal/0005-establish-the-baseline.md      |  92 +++++++++++
 journal/0006-fix-the-inert-assertion.md     |  89 ++++++++++
 journal/0007-controls-tag-split-corpus.md   | 116 +++++++++++++
 method/METHOD.md                            | 243 ++++++++++++++++++++++++++++
 plans/README.md                             |  53 ++++++
 11 files changed, 1078 insertions(+)
```

`plans/0010-plan-protocol/plan.md` and `journal/0010-plan-protocol.md` are added
by the same commit and are not in the stat above, which was taken before they
were written.

| File | Change | Why |
|---|---|---|
| `PLAN-PROTOCOL.md` | new | Task 1. The plan format, plus the pass-numbering and file-supply rules. |
| `plans/README.md` | new | Task 2. What `plans/` holds and how it differs from `journal/`. |
| `plans/0010-plan-protocol/plan.md` | new | Task 3. This file, the format's worked example. |
| `method/METHOD.md` | new | Task 4. Supplied draft verbatim plus five Pass 0009 rules. |
| `evals/conformance/baseline/CONTROL-SWEEP.md` | +99 | Tasks 5 and 6. Coverage table, counts, and the documented exception. Nothing existing was edited. |
| `journal/0001`–`0007` | new | Task 7. Backfill from artifacts. |
| `journal/0010-plan-protocol.md` | new | The pass's own entry. |

No file under `evals/conformance/` other than `CONTROL-SWEEP.md` was touched.
`Conformance.Tests.ps1`, `Invoke-Conformance.ps1` and both result files are
byte-identical to `d0f23a1`.

## 9. Verify script

Not applicable at light tier.

## 10. Deviations

**1. The stopped run, and the gate that stopped it.** This pass was issued once
before and stopped at precondition 4: `method/METHOD.md` was named as "present
in the repository or supplied by the operator", and it was neither. I searched
the working tree, every branch's history via `git log --all --name-only`,
untracked files, and the parent directory — including opening a stray
`__Temp.md` in case it was the draft under another name, which it was not — then
stopped and committed nothing. That is the gate working. Recorded here because
a precondition that fires correctly is evidence, and because the previous
occurrence of the same gap (K4 in Pass 0009) blocked *silently* and cost a pass.

**2. The ambiguity that caused it is now a rule.** "Supplied by the operator"
had no defined channel. It is now the *File supply* section of
`PLAN-PROTOCOL.md`: committed, or verbatim in the prompt, and nothing else.

**3. The fourth required finding could not be backfilled into 0001–0007.** The
prompt requires that "deleting the reference's manifest produced a confident
score against a vendored module rather than an error" appear in the backfill.
It cannot honestly: that defect was found in **Pass 0009**, by the polarity
sweep, and is already recorded in `journal/0009-correct-the-control-protocol.md`
and in `baseline/CONTROL-SWEEP.md`. Backdating it into an entry for 0001–0007
would be reconstruction of exactly the kind task 7 forbids.

What *is* in the backfill is its lineage, which I think is the more useful
record: the same shape appears three times, each one selection rule further down
than the last repair reached.

| Occurrence | Entry | Artifact |
|---|---|---|
| Shortest-path tie-break graded the vendored `corpus/PSCorpus` | 0004 *Learned* | `FINDINGS.md` A1 |
| A bundled helper out of 51 manifests graded as SqlServerDsc, 81.82% | 0007 *Learned* | `UNIVERSAL-CORPUS.md` A-C1 |
| The lone-candidate fallback graded `PSCorpus` when the manifest was deleted | 0009 (already written) | `CONTROL-SWEEP.md` |

Entry 0004 states the lineage explicitly and names the two later occurrences.

**4. `method/METHOD.md` needed a section the draft did not have.** Rule 4 is
about the falsification *harness*, and the draft's headings covered the grader,
evidence, mechanisms, diagnosability, records and safety — but not the harness
that runs the probes. I added *The falsification harness* rather than filing a
harness rule under *The grader*, and moved two existing harness rules into it.
Flagging it because it is a structural change to a supplied document, not just
an addition.

**5. One thing in `METHOD.md` I think is wrong as written.** Under *Known limits*:
"On a small project, use the minimum: an oracle, falsification with controls,
and a journal. Skip the corpus, the harness, and the decisions log." Skipping
the corpus is the one I would not recommend. The corpus is what broke this
project's closed loop, and it cost one pass to fetch and run because it already
existed. The expensive parts were the harness and the records; the corpus was
cheap and it invalidated five of ten assertions in the tag it tested. I have
left the text verbatim as instructed and flag it here rather than editing it.

**6. A smaller one in `PLAN-PROTOCOL.md`.** Section 11 requires a token count,
and I have no reliable way to measure one from inside the session — I can report
wall-clock and an order of magnitude, not a count. Section 11 below says so
rather than inventing a number. If the figure matters, it needs to come from the
host rather than the agent.

**7. Nothing was verified by running it.** This is a light-tier pass and the
tier is correct, but it means the control-coverage table in task 5 is derived by
*reading* the driver's row definitions against the assertion list, not by
executing anything. The counts are as good as that reading. A cheap future check
would be to have the driver emit its own coverage map, which would make the
table generated rather than transcribed.

## 11. Cost

Wall-clock: approximately 35 minutes from preconditions to push, of which the
journal backfill was the largest share and no time was spent running the suite.

Token count: not measurable from inside the session. Order of magnitude is tens
of thousands of output tokens; the pass read `git show` output for eleven
commits and wrote roughly 1,400 lines across thirteen files. See Deviations 6.
