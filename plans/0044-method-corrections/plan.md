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

_(evidence appended per task, below)_

## 10. Deviations

_(written at landing)_
