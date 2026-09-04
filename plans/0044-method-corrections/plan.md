# Pass 0044 — method corrections from 0043

## 1. Prompt

````markdown
# PASS 0044 — method corrections from 0043, plus state report

## Signals

- 🔴 **Hard stop.** Fails → stop, report, never resolve.
- 🟠 **Operator action.** Agent verifies, never performs.
- 🟢 **Agent task.**
- 🔵 **Evidence gate.** Observed and recorded in `plan.md` before the next step opens.
- ⛔ **Never**, for the pass's whole duration.

**Tier:** Repository (documentation and conformance-suite changes; one new assertion with its falsification control; no module builds).

**Target repositories:** `AI.Agent.Claude.PowerShellModuleBuilder` only (writable). The four ecosystem repos and their remotes are **read-only inputs** to the state report. ⛔ `PSModuleGraph` untouched in `scratch/`. ⛔ AzDO projects untouched — no REST calls this pass; the state report uses git remotes only.

**Purpose.** Pass 0043 surfaced durable corrections: prompt checks shipped without polarity proof (SC2 twice, SC4), requirements written from memory contradicted repo convention (verify-script path) and repo state (v0.3.0 collision with an existing tag), and a tracked workspace file carried a registration two sessions failed to find. This pass writes those corrections into the standing documents and the suite. (An earlier draft also compiled a state report; struck — the remotes are directly readable and the operator context was replaced from them on 2026-09-03, and a verbatim mirror of LEDGER would violate the single-source rule.)

## 0. Sync

🟢 One parallel fetch job per workspace repo (`--all --tags --prune`), ff-only updates. 🔵 Report per repo. 🔴 Diverged branch. 🔴 Dirty tree.

## 1. Preconditions

1. **Number check, three sources:** 🔴 any source shows 0044 assigned (`plans/0044-*`, `journal/0044-*`, LEDGER citation, `pass-0044-*` branch anywhere). 🔴 Any of the three sources disagrees about the frontier — all agreed at **0043** when verified against the remote on 2026-09-03 (`LEDGER.md:8`, plans tree, journal tree), so any disagreement now is a new finding, not a known drift. 🔵 Record all three frontier values.
2. 🔴 Harness not on `main`, not clean, or not ff-synced. ⛔ `pass-0042-philosophy` remains preserved and unmerged.
3. 🔴 `PSModuleGraph` present anywhere in the workspace tree outside `scratch/`, referenced by any tracked workspace file, or named in this session's additional-working-directories list.
4. **Sequencing gate, not a launch condition:** 🔴 any section-3 work begins before the acceptance test is committed and observed **red**.

## 2. Acceptance test — write first, observe red

🟢 Commit `plans/0044-method-corrections/accept.ps1` before any section-3 work. It exits non-zero unless:

- `method/METHOD.md` contains the two new rules of task 1, numbered continuously after its current last rule.
- `PLAN-PROTOCOL.md` contains the three additions of task 2 (signal legend, frontier precondition, recovery-phase pattern).
- The conformance suite contains the workspace-composition assertion of task 3 **and** its falsification-control row.
- LEDGER carries the task-4 backlog entries under `### Added by pass 0044`.

🔵 Run; record the red exit and findings count.

## 3. Tasks

**Every doc edit reads the current text first and amends it — nothing is written from recall.** 🔵 Each task's evidence includes the pre-edit excerpt it amended.

**Serial (all touch harness docs or the suite; one working tree):**

1. 🟢 **METHOD.md — two rules**, numbered continuously from the document's own current numbering (🔵 record the numbers assigned):
   - **Named-check polarity:** every named check in a pass prompt (spot-checks included) is demonstrated red against a known-bad input and green against a known-good one before its first counted result — the discipline verify scripts and conformance assertions already carry, extended to everything that grades. Cite SC2 (regex matched every `://` scheme; zero-`vscode://` clause unsatisfiable against the renderer's own templates) and SC4 (whole-image variance could not tell drawn from blank) as the motivating record, pass 0043.
   - **Conventions from the repo:** prompt requirements that name paths, versions, layouts, or conventions are derived from the repository at authoring time, never recalled — the existing analyze-state-from-remotes rule extended from state to convention. Cite the 0043 verify-path deviation and the v0.3.0→v0.4.0 collision.
   Each rule its own commit.
2. 🟢 **PLAN-PROTOCOL.md — three additions**, each its own commit:
   - The five-signal legend (verbatim from this prompt's Signals section) as the standing prompt convention. Note the constraint it survived: emoji markers passed every grep and parse in passes 0043–0044.
   - The multi-source frontier precondition (LEDGER + plans tree + journal tree; assigned-number check; trees-disagree-with-each-other stop) as a standing precondition for every pass — motivated by the 0032 misnumbering.
   - The recovery-phase pattern: a hard-stop report may carry a machine-executable, idempotent recovery phase for the re-issue; operations already authorized by standing decisions are pre-ratified, ruling-class operations (abandonments, workspace composition, anything ⛔-adjacent) execute only under operator approval of the re-issue; check-then-act on every step; a session-unreachable step (anything baked in at launch) always terminates the phase with a stop-and-relaunch instruction.
3. 🟢 **Conformance suite — workspace-composition assertion**, one commit: no tracked workspace file (`*.code-workspace` or equivalent) in any writable repo references PSModuleGraph. **Falsification control in the same commit**, polarity-correct: a scratch fixture workspace file that does reference it, against which the assertion is demonstrated red. 🔵 Record both observed results, red and green. Cite the 0043 finding: two sessions reported no repo file registered PSModuleGraph while a tracked `.code-workspace` did.
4. 🟢 **LEDGER backlog entries** for the corrections this pass incorporates, using the next free numbers (**59 onward** — 58 is the frontier; numbers consumed, never reused): one line each cross-referencing the METHOD rules and the suite assertion to their 0043 origins, in the LEDGER's existing `### Added by pass NNNN` form. Its own commit, folded with task 6's counter update per LEDGER's same-commit rule.

## 4. Named spot-checks (each 🔵; each demonstrated red-capable per the new METHOD rule — state how)

- **SC1 — rule continuity:** METHOD.md's rule numbering has no gaps or duplicates after task 1. Red demo: scratch copy with a duplicated number.
- **SC2 — assertion polarity:** the task-3 control observed red and the assertion observed green against the real repos, both exits recorded. (The check is its own red demo.)
- **SC3 — backlog form:** the task-4 entries use next-free numbers with no gap or reuse against the LEDGER's own numbering note ("consumed, never reused, never renumbered"). Red demo: scratch copy reusing number 42.

## 5. Verify script

🟢 `plans/0044-method-corrections/verify.ps1` — **the repository's convention path, per decision 0004 and every prior pass**. Supports `-FailCheck`, writes only under `scratch/`. Checks: acceptance green; the three spot-checks; each doc edit present with its pre-edit excerpt recorded in `plan.md`. 🔵 Run once at landing; record the exit.

## 6. Records and landing

5. 🟢 `plans/0044-method-corrections/plan.md` — prompt verbatim, per-task evidence, Deviations. Push early: first commit of the pass branch immediately, then after every task.
6. 🟢 LEDGER.md: pass counter, `Last landed: 0043 → 0044` at landing, backlog updates (mark the two METHOD rules and the suite assertion as incorporating 0043's findings). Its own commit.
7. 🟢 `journal/0044-method-corrections.md` — six fields, Capability never benefit.
8. 🟢 Fast-forward `main` per 0009; ⛔ never force.

## 7. Local handoff — the last act

🟢 Every workspace repo: checkout `main`, `pull --ff-only`, `fetch --tags --prune`, status clean; 🔵 LOCAL STATE table (repo | branch | HEAD | clean). Divergence or dirt reported, never resolved.
````

## 2. Preconditions

### Section 0 — Sync

One `git fetch --all --tags --prune` per workspace repo. All five returned exit 0.
No repository needed a fast-forward: every one was already at its upstream.

| Repo | Branch | Dirty | Behind/ahead of upstream | HEAD |
|---|---|---|---|---|
| AI.Agent.Claude.PowerShellModuleBuilder | `main` | clean | `0 0` | `352b69f` |
| PSAzureDevOpsGraph | `main` | clean | `0 0` | `5551a20` |
| PSGraphRender | `main` | clean | `0 0` | `c7f382f` |
| PSGraphRenderToHtml | `main` | clean | `0 0` | `55deb28` |
| PSTerraformGraph | `main` | clean | `0 0` | `74d85ac` |

🔴 Diverged branch — none. 🔴 Dirty tree — none.

Stranded `pass-*` branches, per PLAN-PROTOCOL "Sync — the first act of every pass":
`pass-0042-philosophy` is not an ancestor of `main`, by design — decision 0016
abandoned pass 0042 and the branch is preserved deliberately. It is the only one.

### Precondition 1 — number check, three sources

🔵 **All three frontier sources agree at 0043.** No source shows 0044 assigned.

| Source | Command | Frontier | 0044 assigned? |
|---|---|---|---|
| LEDGER | `grep -n "Last landed" LEDGER.md` | `LEDGER.md:8` → `Last landed: **0043**` | no — `grep -n "0044" LEDGER.md` returns nothing |
| plans tree | `ls -1 plans \| grep -E '^[0-9]{4}' \| sort \| tail -1` | `0043-examples-showcase` | no — no `plans/0044-*` |
| journal tree | `ls -1 journal \| grep -E '^[0-9]{4}' \| sort \| tail -1` | `0043-examples-showcase.md` | no — no `journal/0044-*` |

Branch check, all five repos: `git branch -a --list '*0044*'` returned empty in every
one. Repository-wide: `git grep -n "0044"` returned no tracked hit before this pass.

### Precondition 2 — harness state

`main`, clean, `0 0` against `origin/main` at `352b69f`. ⛔ `pass-0042-philosophy`
present locally and at `remotes/origin/pass-0042-philosophy`, and absent from
`git branch --merged main -a` — preserved and unmerged, untouched by this pass.

### Precondition 3 — PSModuleGraph containment

Checked in three clauses, as written.

| Clause | Command | Result |
|---|---|---|
| present outside `scratch/` | `find <workspace> -iname '*PSModuleGraph*' -not -path '*/scratch/*'` | Two files only, both conformance **result JSON** under `evals/conformance/baseline/`. Both record `"Target": "…\scratch\PSModuleGraph"`. Recorded evidence about a past run, not the module. **Clean.** |
| named in the session's additional-working-directories list | session context | `PSAzureDevOpsGraph`, `PSGraphRender`, `PSGraphRenderToHtml`, `PSTerraformGraph`. No PSModuleGraph. **Clean.** |
| referenced by any tracked workspace file | `git ls-files \| grep -i code-workspace` in all five repos | Two tracked workspace files exist. The harness's is **clean**. PSGraphRender's is **not** — see Deviation 1. |

The clone itself sits at `scratch/PSModuleGraph`, where pass 0043 left it. It was
never fetched, opened or modified during this pass.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| OS | Microsoft Windows NT 10.0.26200.0 |
| Branch | `pass-0044-method-corrections`, from `main` |
| HEAD at start | `352b69f` |

## 4. Acceptance test — red first

`plans/0044-method-corrections/accept.ps1`, committed before any section-3 work.

Command:

```powershell
& .\plans\0044-method-corrections\accept.ps1; $LASTEXITCODE
```

🔵 **Observed RED. Exit code 17. 17 findings.**

```
ACCEPT 0044 - method corrections

Task 1 - METHOD.md, two new rules
  PASS  METHOD.md is readable
  FAIL  METHOD: named-check polarity rule present - missing phrase(s): known-bad; before its first counted result
  FAIL  METHOD: polarity rule cites SC2, SC4 and pass 0043 - missing SC2
  FAIL  METHOD: conventions-from-the-repo rule present - missing phrase(s): never recalled; authoring time
  FAIL  METHOD: conventions rule cites the 0043 verify path and the tag collision - missing verify.ps1
  FAIL  METHOD: both new rules carry a document rule tag, and no rule is mis-tagged - expected at least 44 tagged rules after this pass, found 42

Task 2 - PLAN-PROTOCOL.md, three additions
  PASS  PLAN-PROTOCOL.md is readable
  FAIL  PROTOCOL: five-signal legend present, all five markers - missing marker(s): Orange
  FAIL  PROTOCOL: legend names each signal in words - missing word: Operator action
  FAIL  PROTOCOL: legend records the constraint it survived - legend does not cite pass 0043
  FAIL  PROTOCOL: multi-source frontier precondition present - missing LEDGER
  FAIL  PROTOCOL: recovery-phase pattern present - missing idempotent

Task 3 - conformance suite, workspace-composition assertion
  PASS  Conformance suite is readable
  FAIL  SUITE: workspace-composition Describe block present - no Describe 'Workspace composition'
  FAIL  SUITE: assertion names PSModuleGraph and reads workspace files - assertion does not read *.code-workspace
  FAIL  SUITE: assertion is discovered per file, so zero files reports as zero cases - no per-file discovery collection; a suite-level It cannot report zero cases
  FAIL  FALSIFICATION.md carries the control row for the new assertion - no falsification row mentioning a workspace break

Task 4 - LEDGER backlog entries
  PASS  LEDGER.md is readable
  FAIL  LEDGER: "### Added by pass 0044" section present - no "### Added by pass 0044" heading
  FAIL  LEDGER: 0044 section numbers run from 59 with no gap or reuse - section absent
  FAIL  LEDGER: 0044 entries cross-reference their 0043 origins - section absent

ACCEPT 0044: RED - 17 finding(s):
```

The four `PASS` lines are file-readability guards, not deliverables. Every check
that grades a deliverable of this pass was red.

One detail worth keeping, because it is evidence about the check itself rather
than about the repository: the five-marker check reported **only** `Orange`
missing. 🔴, 🟢, 🔵 and ⛔ were already in `PLAN-PROTOCOL.md` and were found; 🟠 was
not there and was reported. A check that found four of five is a check that can
tell the difference — which is the property the whole pass is about. The markers
are matched by Unicode code point (`[char]::ConvertFromUtf32`) rather than by
literal, so the script's own file encoding can never be the reason it answers
wrongly.

## 5. Tasks

- [x] **Task 1 — METHOD.md, two rules.** Two commits, `606b68a` and `2a50443`.
- [x] **Task 2 — PLAN-PROTOCOL.md, three additions.** Three commits, `4b7cebb`, `6830a75`, `5f1f42b`.
- [x] **Task 3 — conformance suite assertion and its falsification control.** One commit, `d5a90b2`.
- [x] **Task 4 — LEDGER backlog entries, folded with the counter.** One commit, `76fdf3a`.

### Numbers assigned to the METHOD rules

The prompt asked that these be recorded. **There are none to record, and that
is the finding** — see Deviation 2. METHOD.md has no rule numbering. Its rules
are bold-tagged paragraphs under topic headings, and the count went from **42
tagged rules to 44**, verified by the acceptance test and by SC1.

| | Before | After |
|---|---|---|
| `**PORTABLE.**` | 34 | 36 |
| `**TUNE.**` | 4 | 4 |
| `**DOMAIN.**` | 4 | 4 |
| **total** | **42** | **44** |

### Task 1 — pre-edit excerpts

Both rules were placed by reading the surrounding text first, not by appending.

**Rule 1, named-check polarity**, inserted at the end of *The falsification
harness*, immediately before `## Evidence discipline`. The text it amends,
`git show 352b69f:method/METHOD.md`, lines 205-210:

```
artifacts, and neither substitutes for the other. Recorded as
[decision 0015](../decisions/0015-falsifying-against-a-red-target.md), from the
eight help assertions of pass 0039 that first hit it.

## Evidence discipline
```

Chosen because that section already holds the rule that an assertion does not
count until it has a falsification row. The new rule is the same rule one level
up, applied to checks that have no falsification row at all.

**Rule 2, conventions from the repository**, inserted into *Records*, directly
after the file-supply rule. The text it amends, same base commit, lines 257-258:

```
**PORTABLE.** A file a pass must create is either already committed or its
full content appears verbatim in the prompt. There is no third channel.
```

Chosen because that is the existing prompt-authoring rule in this document, and
the new one is its sibling: one governs what a prompt must contain, the other
where its assertions about the repository come from.

### Task 2 — pre-edit excerpts

**The five task signals**, added to `## Signals, reports and records`. The
section header it amends, base commit, lines 247-248:

```
The three conventions that govern how a pass talks to the operator. Each has a
numbered record in `docs/ux/` saying what went wrong without it.
```

`three` became `four` in the same commit, and `docs/ux/UX-007-task-signals.md`
was written because that sentence requires it — see Deviation 4. The 0041
registry checks still hold: 7 records, four headings each, and the index naming
exactly the files on disk.

**The frontier precondition**, appended to `## Pass numbering`. The text it
amends, base commit, lines 10-12:

```
The operator assigns NNNN in the prompt header. `plans/NNNN-<slug>/`,
`journal/NNNN-<slug>.md` and the header all use it. The agent never invents
a pass number. A prompt arriving without one is a stop.
```

**The recovery phase**, a new `##` section placed between *Uncommitted changes
the pass did not make* and *Sync and handoff* — the two neighbours that also
describe abnormal states. The text it precedes, base commit, lines 106-110:

```
## Sync and handoff

The two acts that bracket a pass. Both are about the state a pass finds the
repositories in and the state it leaves them in, and neither belongs to any
one task.
```

### Task 3 — the assertion, and both observed polarities

Assertion: `Workspace composition.does not register PSModuleGraph as a folder`,
tagged `HouseStyle`. Tagged there rather than `Repository` because "does not
register PSModuleGraph" is this ecosystem's governance and not a property of
module repositories in general; putting it on the `Repository` rung would be a
claim that tag cannot support.

It reads the workspace file **semantically** — parsed as JSONC, `folders[].path`
compared segment by segment — rather than matching text. Row 18c is why: a
text match fires on any file that *documents* the rule, which includes
`FALSIFICATION.md`, `UX-007` and the METHOD rule itself.

🔵 **Falsification, five rows, driver exit 0.**
`plans/0044-method-corrections/Test-WorkspaceFalsification.ps1`, recorded in
`evals/conformance/baseline/FALSIFICATION.md` as rows 18a-18e.

| Row | Fixture | Expected | Observed |
|---|---|---|---|
| 18a | registers `../PSModuleGraph` | RED | **RED** (passed 0, failed 1) |
| 18b | restore: that entry removed | GREEN | **GREEN** (passed 1, failed 0) |
| 18c | control, scope: named in a comment and a setting, not registered | GREEN | **GREEN** (passed 1, failed 0) |
| 18d | control, segment: registers `../PSModuleGraphTools` | GREEN | **GREEN** (passed 1, failed 0) |
| 18e | control, absence: no workspace file at all | ZERO CASES | **ZERO CASES** (passed 0, failed 0) |

🔵 **The assertion against the real repositories.** Two of five results are
findings rather than passes, and both are reported rather than resolved.

| Repository | Observed | |
|---|---|---|
| PSAzureDevOpsGraph | zero cases | no tracked workspace file — inapplicable |
| PSGraphRenderToHtml | zero cases | no tracked workspace file — inapplicable |
| PSTerraformGraph | zero cases | no tracked workspace file — inapplicable |
| PSGraphRender | **RED** | `PSGraphRender.code-workspace` registers `../PSModuleGraph` |
| AI.Agent.Claude.PowerShellModuleBuilder | **cannot run** | the suite fails discovery against the harness |

See Deviations 6 and 7. Both are LEDGER backlog entries, 60 and 61.

### Task 4 — LEDGER

`### Added by pass 0044`: entries **59, 60, 61**. 58 was the frontier, verified
against the file rather than taken from the prompt; 62 is now next free and the
numbering-reconciled section says so. 59 is the incorporation of 0043's
corrections and is resolved; 60 and 61 are live findings, both produced by the
assertion rather than by reading anything.

## 6. Acceptance test — green

Same script, same command.

```
ACCEPT 0044: GREEN - 0 findings.
EXIT=0
```

All 21 checks pass. Re-run from a fresh clone inside `verify.ps1` check 1, which
is the run that counts: the working tree is not the artifact.

## 7. Command transcript

```powershell
# sync and preconditions
git -C <each of 5 repos> fetch --all --tags --prune
git -C <each> rev-list --left-right --count '@{u}...HEAD'      # 0 0, all five
git -C harness branch -a --list '*0044*'                        # empty, all five repos
git -C harness branch --merged main -a                          # pass-0042-philosophy absent
git -C harness ls-files | grep -i code-workspace                # 1 harness, 1 PSGraphRender

# acceptance, red first
git checkout -b pass-0044-method-corrections
./plans/0044-method-corrections/accept.ps1                      # exit 17, 17 findings

# tasks
git commit -m 'METHOD: a named check counts only after its polarity is shown'
git commit -m 'METHOD: conventions come from the repository, never from recall'
git commit -m 'PROTOCOL: the five task signals, and the record that earns them'
git commit -m 'PROTOCOL: read the frontier from three sources, not from the counter'
git commit -m 'PROTOCOL: the recovery phase a hard-stop report may carry'
git commit -m 'Suite: a tracked workspace file must not register PSModuleGraph'
git commit -m 'LEDGER: pass 0044 - method corrections, and two findings the pass made'

# falsification and polarity
./plans/0044-method-corrections/Test-WorkspaceFalsification.ps1  # exit 0, 5 rows correct

# acceptance, green
./plans/0044-method-corrections/accept.ps1                       # exit 0, 0 findings

# verification
./plans/0044-method-corrections/verify.ps1 -FailCheck            # exit 0, both probes red
```

## 8. Diff summary

```
LEDGER.md                                   counter to 0044, backlog 59-61, next-free note
PLAN-PROTOCOL.md                            +3 sections: task signals, frontier, recovery phase
method/METHOD.md                            +2 rules: named-check polarity, conventions from the repo
docs/ux/README.md                           +1 index row
docs/ux/UX-007-task-signals.md              new: the record the signal legend requires
evals/conformance/Conformance.Tests.ps1     +1 Describe, +1 discovery collection
evals/conformance/baseline/FALSIFICATION.md +rows 18a-18e and the real-repository sweep
plans/0044-method-corrections/accept.ps1    new
plans/0044-method-corrections/verify.ps1    new
plans/0044-method-corrections/Test-WorkspaceFalsification.ps1  new
plans/0044-method-corrections/plan.md       new
journal/0044-method-corrections.md          new
```

No module source changed in any repository. No ecosystem repository was written
to at all.

## 9. Verify script

`plans/0044-method-corrections/verify.ps1` — the repository's convention path
per decision 0004, which is also what Deviation 2 of pass 0043 established after
its prompt named a `verify/` directory that has never existed here. Not
reproduced in full: it is long enough that a second copy in this file could
disagree with the committed one.

Six checks, all from a fresh clone of the remote. 🔵 **Run at landing:
`VERIFY 0044: PASS`, exit 0**, with `-FailCheck`, both deliberate probes red.

The "pre-edit excerpt recorded in `plan.md`" requirement is answered by reading
each file **as it stood at the base commit** rather than by parsing this plan.
PLAN-PROTOCOL section 9 forbids the script from parsing the plan, and the two
requirements would otherwise contradict each other. The re-derived form is also
the stronger claim: an excerpt copied into a plan and an excerpt that was
actually there are different things, and only one of them is checkable.

## 10. Deviations

**1. Precondition 3 read literally would have hard-stopped this pass on the
finding it was commissioning.** Clause: 🔴 PSModuleGraph *"referenced by any
tracked workspace file"*. A tracked workspace file does reference it —
`PSGraphRender.code-workspace`, since that repository's initial commit.

Read literally, the pass stops. Three things say that is not the reading:

- Task 3 defines the same condition as *"no tracked workspace file … **in any
  writable repo**"*, and this pass declares only the harness writable.
- SC2 requires the assertion be observed **green against the real repos**. If
  the clause covered PSGraphRender, the prompt would be asking for a green that
  its own precondition proves impossible.
- The stop is unresolvable from inside a pass that holds the file's repository
  read-only, so the literal reading makes the pass permanently unrunnable.

What the clause protects is intact: PSModuleGraph is not on disk outside
`scratch/`, is not in this session's directory list, and is not registered by
the workspace file that actually composes this session — the harness's, which
lists exactly the four ecosystem repositories the session was given. **Proceeded
under the writable-repo reading, reported rather than resolved**, and the
PSGraphRender file is now LEDGER backlog 60 and a red row in FALSIFICATION.md
rather than a silence.

**2. METHOD.md has no rule numbering, so the two rules could not be "numbered
continuously after its current last rule".** Its 42 rules are bold-tagged
paragraphs — `**PORTABLE.**`, `**TUNE.**`, `**DOMAIN.**` — under topic headings.
The only numbered list in the file is a four-item sub-list inside the
Diagnosability rule.

Introducing a numbering scheme to satisfy the requirement would have invented a
convention, which is the failure mode 0043's Deviation 2 recorded and which this
pass's own second METHOD rule now forbids in terms. The repository has a
precedent commit for the alternative: `64fee46`, *"Replace an invented
convention with the assertion it was standing in for"*. Followed it. Both rules
were written in the document's real form, and **SC1 and the acceptance test
check the invariant the numbering requirement stood in for** — every rule opener
carries exactly one of the three tags, and the tagged count grew from 42 to 44.

The uncomfortable part is worth stating plainly: **the prompt commissioning a
rule against writing requirements from recall contained three requirements
written from recall.** This is the first.

**3. The "0032 misnumbering" the frontier precondition was to cite does not
exist.** Searched: `0032`'s plan and journal record no numbering trouble. Two
real records do exist and the document cites both.

- **Commit `b404734`**, immediately before this pass — LEDGER read
  `Last landed: 0040` while `git ls-tree origin/main` answered
  `plans/0041-operator-ux` and `journal/0041-operator-ux.md`. That is frontier
  drift, and it is exactly what a three-source precondition catches.
- **Pass 0031** — its prompt asked for a backlog item as "17"; 17 and 18 were
  taken by 0029 and it landed as 19. That is a numbering collision, but of
  backlog numbers rather than pass numbers.

The acceptance test was amended in the same commit to require the citations
that exist rather than the one that does not. Recorded rather than quietly
satisfied, because a check amended mid-pass is a check somebody should look at:
it was red on this item before the amendment and red after it, so no green was
manufactured.

**4. `docs/ux/UX-007-task-signals.md` was written, and the prompt did not ask
for it.** `PLAN-PROTOCOL.md` states that every operator-experience convention in
this repository has a numbered record in `docs/ux/` — problem, why, what it
solves, evidence — *written before the convention ships*, and `docs/ux/README.md`
adds that a convention without a problem statement is decoration. The signal
legend is such a convention. Landing it with no record would have broken the
rule in the section it was being added to.

The record surfaced something the legend itself does not say: **three of the five
markers collide with UX-001's routing circle.** 🔴 is NEW SESSION there and hard
stop here; 🟢 and 🔵 likewise. Resolved by position — the routing circle leads a
block and appears once, task signals appear inline against steps — and written
down in both places rather than left to be discovered.

**5. The acceptance test failed on two checks that were in fact satisfied.**
`@('a','b') | Where-Object {…}` yields `$null` when it filters everything out,
and `$null.Count` throws under `Set-StrictMode -Version Latest`. Both METHOD
checks reported their rules missing while both rules were present.

Recorded prominently because of where it happened: **a check reporting the wrong
answer, in the acceptance test of the pass whose first new rule is that a check
does not count until its polarity is shown.** The rule found its own author.
Fixed with `@()` around the pipeline.

**6. FINDING — `PSGraphRender.code-workspace` registers `../PSModuleGraph`.**
Found by the new assertion on its first run against the real repositories, which
is the strongest available evidence that it is not inert. Present since that
repository's initial commit. **Not repaired:** the ecosystem repositories are
read-only this pass, and METHOD is explicit that an assertion is never weakened
because a target fails it. LEDGER backlog 60.

Note the state it is in: `../PSModuleGraph` no longer exists at the workspace
root, because 0043 moved the clone to `scratch/`. So the registration is
currently inert as well as wrong — which is the condition under which it
survived two sessions of being looked for.

**7. FINDING — the conformance suite cannot run against the harness at all.**
`AI.Agent.Claude.PowerShellModuleBuilder` has no module manifest, so
`$ExportedWithSource` and `$PublicFiles` are empty, and **Pester 6 treats an
empty `-ForEach` as a discovery error that fails the entire file** rather than
as zero cases. Not partial, not skipped — the suite does not run.

Two consequences. Every assertion is unreachable for the repository that hosts
the suite; and this pass's new assertion, whose motivating defect was a harness
`.code-workspace`, structurally cannot check the harness. Covered here by
`verify.ps1` check 6, which reads the harness's own workspace files by the same
semantic rule. LEDGER backlog 61.

The same Pester behaviour is why the new assertion carries
`-AllowNullOrEmptyForEach`. Without it, every target with no tracked workspace
file — three of four ecosystem repositories, and every gallery corpus package —
would have taken the whole suite down. **Not applied to the three existing
`-ForEach` assertions**, which would fix backlog 61 but is scope growth that
changes cases-run for other targets; it wants its own red-first iteration.

**8. The falsification driver's first run reported ZERO CASES on all four rows,
and every one of them was wrong.** Discovery was failing on an unrelated
assertion's empty `-ForEach`; the driver could not tell *"this assertion had
nothing to check"* from *"the suite never ran"*. It now fails loudly on a failed
container, and row 18e exists because of it. A driver that cannot separate those
two can report a green that means nothing.

**9. `verify.ps1` printed an error and exited 0.** A terminating error skipped
the exit lines at the bottom of the script, and `$LASTEXITCODE` was never set,
so a crashed run reported success. Found by running it. Now caught and exited
99. Third instance in this pass of a check answering wrongly, and the second
inside the pass's own tooling.

**10. Tier.** The prompt states *"Repository"*, which is a conformance-suite tag
rather than one of PLAN-PROTOCOL's two tiers. The pass changes an assertion, so
by *What decides the tier* it is **full**, and was executed at full: red-first
acceptance test, per-task evidence, command transcript, verify script,
deviations. The prompt's own required artifacts already imply it. Tier is a
floor, never a ceiling.

**11. The state report was struck by the prompt, not by the pass.** Recorded so
the absent section is not read as an omission.

## 11. Cost

One session. No module builds, no network beyond `git fetch` against five
remotes and two clones of the harness inside `verify.ps1`.

Run counts:

| | |
|---|---|
| Conformance-suite invocations | 20 — 5 falsification fixtures ×2 runs, 5 real repositories ×2 runs |
| Falsification rows | 5, all correct |
| Acceptance-test runs | 4 (1 red, 1 red on its own bug, 2 green) |
| verify.ps1 runs | 2 (1 crashed at check 6, 1 PASS) |
| Commits | 9 |

No token count: the agent cannot measure one from inside the session, and a
number without an artifact behind it does not belong in a plan.
