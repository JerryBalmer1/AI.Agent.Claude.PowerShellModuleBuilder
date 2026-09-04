# Pass 0043 — ecosystem examples showcase

Branch: `pass-0043-examples` in all five repositories.
Landed: 2026-09-03.

## Contents

- [The prompt, verbatim](#the-prompt-verbatim)
- [Phase R — recovery](#phase-r--recovery)
- [Preconditions](#preconditions)
- [Enumerations and comparison methods](#enumerations-and-comparison-methods)
- [Per-task evidence](#per-task-evidence)
- [Named spot-checks](#named-spot-checks)
- [Verify script](#verify-script)
- [Deviations](#deviations)

---

## The prompt, verbatim

````markdown
# PASS 0043 — ecosystem examples showcase

*(Third issue. History: misnumbered 0032, hard-stopped; renumbered 0043, hard-stopped twice more on the two operator-only blockers. This issue absorbs the operator mechanics into an idempotent Phase R so the file is run twice — once in the current session to clear the blockers, once in a fresh session to execute the pass. Operator approval of this file constitutes the ruling recorded in decision 0016. Sections 2–8 unchanged since the second issue.)*

## Signals — read this first

One channel per dimension, used everywhere below:

- 🔴 **Hard stop.** If this condition fails, stop, report, never resolve. Every 🔴 is a full-pass abort.
- 🟠 **Operator action.** Only the operator does this. The agent verifies it happened and 🔴-stops if it hasn't; the agent never performs it.
- 🟢 **Agent task.** The agent executes, with evidence.
- 🔵 **Evidence gate.** Something must be observed and recorded in `plan.md` (an exit code, an enumeration, a grep result) before the next step opens.

**Tier:** RequiresBuild (each module is imported and executed to generate its examples; no module source changes are intended — any source change required to produce an example is a Deviation, reported before it is made).

**Target repositories (named; nothing else is writable this pass):**
`PSGraphRender`, `PSGraphRenderToHtml`, `PSAzureDevOpsGraph`, `PSTerraformGraph`, and `AI.Agent.Claude.PowerShellModuleBuilder` (plan record, acceptance test, verify script, LEDGER, journal only — no harness behavior changes).
⛔ `PSModuleGraph`: never. ⛔ AzDO `ClaudeTesting` and `ClaudeTestingTerraform`: read-only, per standing rules and decision 0011.

**Purpose.** None of the four ecosystem repos shows a stranger what the modules actually produce. This pass gives each repo a committed `examples/` directory of real generated artifacts — input JSON, self-contained interactive HTML, a screenshot, and a paste-able regeneration command — and reworks each README so that a first-time reader is pointed at them within the first screen. The wow is the screenshot; the proof is the HTML plus the command that regenerates it.

**Session note (binding):** This pass reads the live `ClaudeTesting` fixture and the frozen TF fixture through the modules. This session is therefore **disqualified as a blind builder for any future measurement run** (tf-003 generalisation, ablation runs, or any run with a blind phase) and must not be reused for one.

---

## How this file runs — two sessions, one prompt

Phase R (below) is idempotent recovery: every step checks before it acts, so this file is safe to paste into any session at any state. First run (a session whose directory list still names PSModuleGraph): Phase R executes R1–R5, then R6 stops with the operator's two remaining touches. Second run (fresh session): R1–R5 find their work done and skip; R6 passes; the pass proper begins at Section 0.

## Before launch — operator

Reduced to what no agent can reach:

- 🟠 **Ruling on 0042 (made by approving this file):** pass 0042 is abandoned per the decision 0016 text embedded in R3. Approving this prompt is the ruling; the agent only records it. To complete 0042 instead, do not run this file — the operator supplies the truncated task-5 instruction and a different recovery prompt is issued.
- 🟠 **After Phase R stops at R6:** remove `PSModuleGraph` from the session's additional-working-directories configuration, close the `corpus.json` editor tab open from it, and launch a **fresh session**. The directory list is baked in at launch; no prompt run inside this session can clear it. Then paste this same file into the fresh session.

## Phase R — recovery (idempotent; runs before Section 0 every time)

**One-time authorization, this file only:** relocating the PSModuleGraph clone (R4) is normally never an agent action. This prompt authorizes exactly that move, exactly once, move-not-copy, no git operation against the clone. ⛔ Everything else about PSModuleGraph stays in force: never fetched, never modified, never opened.

- **R1 — State check.** 🟢 In the harness: 🔴 dirty tree. Record current branch. If already on `main` with decision 0016 present and no `PSModuleGraph` folder in the workspace tree, print `PHASE R: nothing to do` and go to R6.
- **R2 — Harness to main.** 🟢 If not on `main`: `git checkout main` then `git pull --ff-only`. ⛔ Never merge, delete, or touch `pass-0042-philosophy` — the branch is preserved unmerged as the record. 🔴 The checkout or pull fails for any reason.
- **R3 — Decision 0016, committed alone.** 🟢 If `decisions/0016-*` does not exist: create `decisions/0016-abandon-pass-0042.md` with exactly the text below (date = commit date), commit it as the only change in its commit, message `decision 0016: abandon pass 0042 (truncated prompt); branch preserved unmerged`, push. 🔵 Record the commit SHA. If it already exists, skip.

  [decision text omitted here — it is committed verbatim at decisions/0016-abandon-pass-0042.md]

- **R4 — Relocate the reference clone.** 🟢 If the folder `PSModuleGraph` exists at the workspace root: verify its tree is clean by `git status` (read-only), then **move** the entire folder to `scratch/PSModuleGraph` at the workspace root (`tf-fixture/` is its sibling there). Move, never copy; no fetch, no checkout, no delete of contents. 🔵 Record source path, destination path, and the clean-status output. 🔴 Its tree is dirty (report, never resolve). If already absent from the workspace root, skip.
- **R5 — Recovery state table.** 🔵 Print: harness branch and HEAD; decision 0016 present (SHA); `pass-0042-philosophy` still on the remote, unmerged; PSModuleGraph folder location. Push anything committed.
- **R6 — Session gate.** 🟢 Check this session's additional-working-directories list. If it names PSModuleGraph: 🛑 **STOP HERE — end of this session's work.** Print the two operator touches from the Before-launch block and nothing else. Do not proceed to Section 0; do not create any `pass-0043-*` branch or `plans/0043-*` directory. If the list is clean (fresh session): proceed to Section 0.

## 0. Sync — before preconditions

🟢 One parallel job per workspace repo: `git fetch --all --tags --prune`, then fast-forward-only updates (`merge --ff-only`; other branches via `fetch origin b:b` where behind). 🔵 Report per repo. Never force, reset, rebase, or discard. 🔴 Diverged local branch. 🔴 Dirty tree.

## 1. Preconditions

1. **Number check, three sources:** harness `LEDGER.md`, `git ls-tree origin/main plans/`, and the journal tree. 🔴 Any source shows pass **0043** assigned (a `plans/0043-*`, `journal/0043-*`, LEDGER citation of 0043, or a `pass-0043-*` branch in any repo) — stop; 🟠 the operator renumbers; the agent never renumbers. 🔴 The plans tree and journal tree disagree *with each other* about the landed frontier (a half-landed pass). **Known-drift exemption:** LEDGER's `Last landed:` line disagreeing with the plans/journal trees is the recorded counter drift that task 8 corrects — it is not a stop. 🔵 Record all three sources' frontier values in `plan.md` as the evidence task 8's commit cites. Any *other* disagreement remains 🔴.
2. 🔴 **Pass 0042 is closed** (landed, or abandoned by recorded decision — R3's decision 0016 satisfies this) and the harness working tree is on `main`, clean, ff-only synced. This pass does not open beside an in-flight harness pass — LEDGER is a single-writer file and pass branches must land ff-only. ⛔ `pass-0042-philosophy` remains preserved and unmerged throughout.
3. 🔴 All five workspace repos on `main`, clean, ff-only synced per step 0. 🔴 `PSModuleGraph` present at the workspace root (R4 relocates it; if it has reappeared, stop and report) or named in this session's additional-working-directories list (🟠 operator-only: config edit plus fresh session — R6 should have stopped before reaching here).
4. **PAT present:** `$env:AZDO_PAT` must exist under `pwsh -NoProfile` — matrix row A-live requires it. 🔴 It is absent or empty. Check by `.Length` only — never read, echoed, written, or placed in a URL. (A present 84-character value is the healthy state; SC3's grep guards against it leaking into commits, not against it existing.)
5. **Browser resolution:** 🟢 resolve a headless-screenshot-capable browser — PATH first (`chrome`, `msedge`), then the standard install locations (`C:\Program Files\Google\Chrome\Application\chrome.exe`, `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`). Prefer Chrome: the 2026-09-03 probe passed with Chrome under `--headless=new`, `--headless=old`, and bare `--headless` (non-blank 1600×900 PNG), while Edge produced no PNG. 🟢 Probe the resolved binary by rendering a trivial scratch HTML to PNG under harness `scratch/`. 🔵 Record the resolved absolute path and the flag variant used in `plan.md` — and nowhere else: the browser path is pass-time tooling and must never appear in any committed regen command or artifact (public-artifact rule, section 6). 🔴 No candidate binary produces a non-blank PNG.
6. **Sequencing gate, not a launch condition** (it cannot be true before the pass opens): 🔴 any section-3 example work begins before the acceptance test (section 2) is committed and observed **red**.

## 2. Acceptance test — write first, observe red

🟢 Commit `plans/0043-examples-showcase/accept.ps1` to the harness pass branch before any example work. It reads the four ecosystem working trees and exits non-zero unless, for each repo:

- `examples/` exists and contains every matrix row for that repo (section 3): input artifact, output HTML, screenshot PNG, and an `examples/README.md` index whose table has one row per example with a paste-able `pwsh -NoProfile` regeneration command.
- The repo's top-level `README.md` contains a hero image reference that resolves to a committed file, and an `## Examples` section appearing before any architecture/internals section, whose relative links all resolve to committed files.

🔵 Run it; record the red exit code and output in `plan.md` before any example work begins. Red-first exists to catch me in minute one.

## 3. Example matrix — the definition of done; grading is per row

Every row requires four committed artifacts in that repo's `examples/`: the input (JSON/psd1 as applicable), the output HTML, a PNG screenshot (fixed viewport 1600×900), and one paste-able regeneration command in the examples index that, run from the repo root under `pwsh -NoProfile`, regenerates the HTML. Structural equality is acceptable where timestamps or generated IDs vary; 🔵 state the comparison method in `plan.md`.

**PSGraphRender**
- **R-layouts:** one HTML per layout in the current option surface. 🔵 Enumerate the layouts from the repo's own contract/options documentation at run time; record the enumeration in `plan.md` — that count is this repo's cases-defined. All from one checked-in viewmodel JSON rich enough to differentiate layouts (nesting, multiple edge kinds).
- **R-theme:** one same-viewmodel pair rendered under two themes.
- **R-links:** one interaction demo with node links. Links are **https URLs into the repo on GitHub** — see the public-artifact rule in section 6.

**PSGraphRenderToHtml**
- **H-nesting:** one producer-contract graph exercising parent/child nesting and collapse, rendered end-to-end (producer graph → viewmodel → HTML).
- **H-precedence:** one graph rendered three ways — built-ins only, `graphrender.defaults.psd1` in-repo defaults, explicit parameters — visibly different outputs, three separate paste-able commands, precedence order stated in the index row (explicit > file > built-ins).

**PSAzureDevOpsGraph**
- **A-live:** the graph of the live `ClaudeTesting` fixture — committed graph JSON, plus HTML via PSGraphRenderToHtml → PSGraphRender, plus screenshot. Read-only REST, project-scoped routes, ≤ 8 concurrent, retry-on-429. This screenshot is the repo's hero image. The regen command reads the PAT from `$env:AZDO_PAT` by name; the index states the prerequisite, never a value.

**PSTerraformGraph**
- **T-fixture:** the graph of the frozen `ClaudeTestingTerraform` fixture repos, cloned read-only under harness `scratch/` at the read-back-verified SHAs recorded in decision 0011 — committed graph JSON, HTML, screenshot. The regen command clones to a caller-chosen scratch path (parameterized, no absolute path baked in).

## 4. Tasks

**Group P1 — parallel, one worker per repo, each confined to its own working tree; workers inherit all constraints in section 6:**

1. 🟢 Create branch `pass-0043-examples` (decision 0005) in each ecosystem repo. First commit — `examples/` scaffold plus index stub — **pushed to the remote branch immediately**, then push after every task group.
2. 🟢 Generate every matrix row for the repo. Renders within a repo may fan out; anything touching git or a shared file in one tree runs serially.
3. 🟢 Capture screenshots headlessly, 1600×900, one PNG per HTML.

**Group S1 — per repo, serial, after that repo's P1 completes:**

4. 🟢 Rework the top-level README to the presentation standard: badge row up top; hero image (the repo's best screenshot); `## Examples` immediately after the intro, as a table — example | what it shows | HTML · input · screenshot · regen command — with every artifact-naming cell hyperlinked; every code fence language-tagged; every section that summarizes a doc links it. Then a one-line pointer to `examples/README.md` for the full index. No claim without a citable artifact.
5. 🟢 Update `docs/HANDOFF.md` (state, this pass, next).
6. 🟢 **PSAzureDevOpsGraph only:** tag the next unclaimed minor version on the deliverable line per decision 0006, with the matching `docs/worklog/vX.Y.0.md`. 🔵 Determine the version from the repo's own `git tag` list and LEDGER's version line at run time; record both in `plan.md`. 🔴 The two sources disagree with each other. The other three repos take no tags this pass; their examples land as `main` commits under decision 0010.

**Group S2 — harness, serial:**

7. 🟢 Write `plans/0043-examples-showcase/plan.md` — prompt verbatim, per-task evidence with observed exits, layout enumeration and comparison methods, verify script, **Deviations** (the most valuable section). Push.
8. 🟢 **LEDGER drift correction, committed alone:** 🔵 verify the actual last-landed pass by listing `plans/` and `journal/` on `main`, and correct LEDGER's `Last landed:` line to match (it read `0040` while 0041 was on main with plan and journal; 0042's landing may have moved it again). One commit, this change only, message naming it a counter-drift correction.
9. 🟢 Update `LEDGER.md` for this pass (pass counter to 0043; PSAzureDevOpsGraph version line to the tag assigned in task 6). Separate commit from task 8.
10. 🔵 Re-run `accept.ps1`; record the green exit.
11. 🟢 Journal `journal/0043-examples-showcase.md` — six fields, Capability never benefit.

**Group S3 — serial, last:**

12. 🔵 Verify script (section 5) run once; exit observed and recorded.
13. 🟢 Fast-forward all touched `main`s per decisions 0009/0010; ff-only, never force.
14. 🟢 Local handoff (section 8).

## 5. Named spot-checks (each 🔵 — result recorded in `plan.md`)

- **SC1 — self-containment:** pick one R-layouts HTML; assert no external `http(s)` script/style/img references (data URIs excepted); record any exception verbatim.
- **SC2 — no machine paths:** grep every committed file in all four repos for `vscode://` and for drive-absolute paths (`[A-Za-z]:[\\/]`); zero hits in `examples/` and both READMEs per repo.
- **SC3 — PAT hygiene:** grep all committed files across all four repos for 84-character mixed-case alphanumeric runs; zero hits. Assert no captured command output in `plan.md` contains the PAT.
- **SC4 — screenshots non-blank:** each PNG exceeds a stated size threshold and shows pixel variance; record the threshold and method.
- **SC5 — regeneration:** re-run one regen command per repo from a **fresh clone under harness `scratch/`**; outputs structurally equal to the committed HTML; record the diff method and result.
- **SC6 — link resolution:** every relative link in each repo's README and examples index resolves to a committed file.

## 6. Constraints

- ⛔ PSModuleGraph: untouched, never cloned writable, never in the workspace.
- ⛔ `ClaudeTesting`: read-only forever. **Never queue, run, or trigger any pipeline; nothing that meters or bills.** ⛔ `ClaudeTestingTerraform`: frozen per 0011 — clones/reads only, at the recorded SHAs.
- ⛔ PAT: from `$env:AZDO_PAT` only; never echoed, written to any file, or embedded in a URL.
- ⛔ Git: no force, reset, rebase, rewrite, or discard anywhere; tags and ff-only `main` updates only as decisions 0006/0009/0010 permit; unrelated changes committed alone; created files committed or verbatim in the prompt/plan.
- **Public-artifact rule (this pass, deliberate divergence from the internal diagram convention — internal docs unchanged):** nothing committed by this pass contains machine-absolute paths or `vscode://` links. Node-link demos use https URLs into the repo on GitHub. 🔵 Record the divergence in Deviations so it is on the record, not silent.
- READMEs: paste-ables only — no `irm | iex`, no execute buttons; auditability is the brand.
- Blind-phase allowlists do not apply (this is not a measurement run), but the session-disqualification note in the header does.

## 7. Verify script

🟢 `verify/Verify-Pass0043.ps1` in the harness, SHA-pinned per decision 0004, supporting `-FailCheck`, writing only under `scratch/`. Checks: every matrix row's four artifacts exist and are non-empty per repo; each README has badge row, hero, and a resolving Examples section; SC2 and SC3 greps pass; `accept.ps1` exits green; the PSAzureDevOpsGraph tag and worklog from task 6 exist; LEDGER's `Last landed:` line matches the plans/journal trees. `-FailCheck` must demonstrate red against a scratch copy with one example deleted. 🔵 Run once when the pass lands; observe and record the exit code.

## 8. Local handoff — the last act

🟢 For every workspace repo: checkout `main`, `git pull --ff-only`, `git fetch --tags --prune`, `git status` clean — then 🔵 print the LOCAL STATE table (repo | branch | HEAD | clean). Divergence or dirt is reported, never resolved. Done means the operator's VS Code shows the result with zero commands.
````

---

## Phase R — recovery

Phase R found its work already done and skipped R2–R5, exactly as designed.

| Step | Finding |
| --- | --- |
| R1 | Harness on `main` @ 194e12f. Decision 0016 present. No `PSModuleGraph` at the workspace root. **Tree was dirty** — see Deviation 1. |
| R2 | Already on `main`, in sync. Skipped. `pass-0042-philosophy` never touched. |
| R3 | `decisions/0016-abandon-pass-0042.md` already present, committed alone at **194e12f**. Skipped. |
| R4 | Already relocated: `scratch/PSModuleGraph`, tree clean, `main` @ 2d97a27. Skipped. Never fetched, opened or modified during this pass. |
| R5 | Recovery state recorded — see below. |
| R6 | Session working-directory list named PSGraphRender, PSGraphRenderToHtml, PSAzureDevOpsGraph, PSTerraformGraph. **No PSModuleGraph. Gate passed.** |

`pass-0042-philosophy` confirmed on the remote at `80a0e4f` and **not merged** into
`origin/main`, before and after the pass.

## Preconditions

| # | Condition | Evidence |
| --- | --- | --- |
| 1 | Number check, three sources | LEDGER `0040`; `git ls-tree origin/main plans/` → `plans/0041-operator-ux`; journal tree → `journal/0041-operator-ux.md`. **Plans and journal agree at 0041**; LEDGER's disagreement is the known drift task 8 corrects. No `plans/0043-*`, `journal/0043-*`, LEDGER citation of 0043, or `pass-0043-*` branch on any remote. |
| 2 | Pass 0042 closed | Decision 0016, committed alone at 194e12f. Harness on `main`, clean, ff-synced. |
| 3 | Five repos | All `main`, clean, `0 0` ahead/behind upstream after `git fetch --all --tags --prune`. PSModuleGraph absent from the workspace root and from the session list. |
| 4 | PAT | `$env:AZDO_PAT` present under `pwsh -NoProfile`, `.Length` = **84**. Checked by length only; never read, echoed, written, or placed in a URL. |
| 5 | Browser | `C:\Program Files\Google\Chrome\Application\chrome.exe`, flag **`--headless=new`**. Probe: 1600x900, 15,197 bytes, 11 distinct colours from a trivial page under `scratch/probe/`. This path appears here and nowhere else — see Deviation 6. |
| 6 | Sequencing gate | Honoured. `accept.ps1` committed and observed red before the first example artifact existed. |

## Enumerations and comparison methods

### R-layouts — cases-defined is 3

Enumerated at run time from the repository's own option surface, and corroborated
by a second, independent source:

| Source | Values |
| --- | --- |
| `src/PSGraphRender/TemplateSets/cytoscape/Config/settings.schema.psd1`, `DefaultFlow.Values` | `foundation`, `testorder`, `callflow` |
| `src/PSGraphRender/TemplateSets/cytoscape/scripts/render.js`, `FLOW_LAYOUT` keys | `foundation`, `testorder`, `callflow` |

The two agree one for one. **cases-defined for PSGraphRender this pass = 3.**
Verified present in the rendered documents as `"DefaultFlow": "foundation"`,
`"testorder"` and `"callflow"` respectively.

### PSAzureDevOpsGraph version — two sources, agreeing

| Source | Value |
| --- | --- |
| `git tag --sort=-v:refname` in the repository | `v0.3.0`, `v0.2.0`, `v0.1.0` |
| `LEDGER.md` Versions line | `PSAzureDevOpsGraph: **v0.3.0**` |

No disagreement, so no hard stop. Next unclaimed minor: **`v0.4.0`**, taken.

### Comparison method for SC5

Regeneration is compared against the committed blob from the same fresh clone
(`git show HEAD:<path>`), after two normalisations:

1. **Line endings** — `.gitattributes` normalises every repository to LF, so a
   file written on Windows differs from its own blob by EOL alone.
2. **`meta.generatedAt`** — `ConvertTo-GraphRenderViewModel` stamps it from
   `[DateTime]::UtcNow` and ignores the producer's own `graph.meta.generatedUtc`,
   so any document rendered through PSGraphRenderToHtml carries a clock reading.

**PSGraphRender needs neither rule for content:** it has no timestamp at all,
its `generatedAt` comes from the committed input, and two consecutive builds of
`callflow.html` produced the same SHA-256 in the same working tree. The other
three are structurally equal under rule 2, which is the allowance section 3
grants for timestamps.

## Per-task evidence

| Task | Result |
| --- | --- |
| 1 — branches | `pass-0043-examples` created and pushed in all four ecosystem repositories and the harness. |
| 2 — matrix rows | 12 HTML, 8 checked-in inputs. All rows built. |
| 3 — screenshots | 12 PNGs, all 1600x900. |
| 4 — READMEs | All four reworked: badge row, hero, `## Examples` table before internals, every artifact cell hyperlinked, every code fence language-tagged. Three pre-existing untagged fences in PSAzureDevOpsGraph and one in PSGraphRender were tagged `text`. |
| 5 — HANDOFFs | All four gained a **State, as of pass 0043** section: where it is, what the pass did, what it found, next. |
| 6 — tag | `v0.4.0`, annotated, pushed, with `docs/worklog/v0.4.0.md`. |
| 7 — plan | This file. |
| 8 — drift correction | `b404734`, one file, one line, `0040` → `0041`, committed alone. |
| 9 — LEDGER | `50082e3`, counter → `0043`, PSAzureDevOpsGraph → `v0.4.0`. Separate commit. |
| 10 — accept green | Exit **0**, twice: working trees, and fresh clones (`accept-green.txt`). |
| 11 — journal | `journal/0043-examples-showcase.md`, six fields. |
| 12 — verify | **PASS 45, FAIL 0**, exit 0, with `-FailCheck` (`verify-run.txt`). |
| 13 — mains | All four ecosystem `main`s fast-forwarded and pushed; harness likewise. |
| 14 — handoff | LOCAL STATE table printed. |

### The matrix as built

| Repo | Row | HTML | PNG |
| --- | --- | --- | --- |
| PSGraphRender | R-layouts × 3 | `examples/layouts/{foundation,testorder,callflow}.html` | 3 |
| PSGraphRender | R-theme × 2 | `examples/theme/{default,contrast}.html` | 2 |
| PSGraphRender | R-links | `examples/links/editor-links.html` | 1 |
| PSGraphRenderToHtml | H-nesting | `examples/nesting/nested.html` | 1 |
| PSGraphRenderToHtml | H-precedence × 3 | `examples/precedence/{builtins,file-defaults,explicit}.html` | 3 |
| PSAzureDevOpsGraph | A-live | `examples/claudetesting.html` | 1 |
| PSTerraformGraph | T-fixture | `examples/claudetestingterraform.html` | 1 |

**A-live**, read live and read-only: 49 nodes and 51 edges returned; 51 nodes
after two unresolved reference targets are carried as invented nodes. GET
requests only; no pipeline queued, run or triggered; the module has no
parallelism, so concurrency was 1 against a ceiling of 8.

**T-fixture**: 78 nodes, 59 edges across `TfFixtureNetwork`, `TfFixtureApp` and
`TfFixtureShared`.

**H-precedence**, the three levels proved distinct in the rendered documents:

| | Layout | ColorBy | ZoomSpeed | Custom colour present |
| --- | --- | --- | --- | --- |
| builtins | `foundation` | `structure` | 1.25 | neither |
| file-defaults | `testorder` | `blastRadius` | **2.5** | the file's HeatRamp |
| explicit | `callflow` | `structure` | 1.25 | the options object's KindColor |

## Named spot-checks

| Check | Method | Result |
| --- | --- | --- |
| **SC1** self-containment | `examples/layouts/foundation.html`: count `(src\|href)="https?://` and `@import` | **0 and 0.** Six `http(s)` strings exist and none is a fetch — recorded verbatim below. |
| **SC2** machine paths | Every committed file under `examples/` plus `README.md`, all four repos, pattern `(?<![A-Za-z])[A-Za-z]:[\\/]` | **0 hits.** See Deviation 3 for the pattern correction and Deviation 4 for the `vscode://` narrowing. |
| **SC3** PAT hygiene | Same file set, `(?<![A-Za-z0-9])[A-Za-z0-9]{84}(?![A-Za-z0-9])` | **0 hits** in all four repositories. No captured output in this plan, the journal or any evidence file contains the token; it was checked by `.Length` only and never printed. |
| **SC4** screenshots | 1600x900 asserted; distinct ARGB colours sampled on a 5px grid **within the canvas region** (x 340–1590, y 60–890) | All 12 drawn: canvas colours **202–981**, against ~2 for a blank canvas. Threshold 10. See Deviation 5. |
| **SC5** regeneration | One regen command per repo from a fresh clone under `scratch/sc5`; compare with `git show HEAD:<path>` after EOL and `generatedAt` normalisation | **4 of 4 MATCH** (`sc5-regeneration.txt`). |
| **SC6** link resolution | `accept.ps1` resolves every relative markdown link in both READMEs per repo against `git ls-files` | Green against the working trees **and against fresh clones**. |

SC1's six URL strings, verbatim, none of them a fetch:

```text
http://127.0.0.1,                                  (help string, editor-link diagnostics)
http://en.wikipedia.org/wiki/MIT_License           (vendored licence comment, x2)
http://engelschall.com                             (vendored licence comment)
http://opensource.org/licenses/MIT                 (vendored licence comment)
https://github.com/cytoscape/cytoscape.js-dagre    (vendored licence comment)
```

## Verify script

`plans/0043-examples-showcase/verify.ps1` — see Deviation 2 for the path.
SHA-pinned per decision 0004 to the commits this pass pushed:

```text
PSGraphRender        c7f382fd7603aa90d715ba66a6796e0724877c49
PSGraphRenderToHtml  55deb2896a85aa9c7ae7e9afbbf2e93011b2342d
PSAzureDevOpsGraph   5551a20efeece2f1e39d7ab9335ad16b6164e135
PSTerraformGraph     0db7f1a7258b3fe56158b5fc6f3eb537f272d430
tag                  v0.4.0
LEDGER Last landed   0043
```

Eight sections: commit pins, artifacts, README standard, SC2/SC3, tag and
worklog, LEDGER counter against both trees, `accept.ps1`, and `-FailCheck`.
Writes only under `scratch/verify-0043`, which it removes.

**It found a real defect on its first run:** PSTerraformGraph's README had no
badge row. The other three had one and that one did not, and nothing else had
noticed. Fixed at `74d85ac`, after which: **PASS 45, FAIL 0.**

`-FailCheck` copies PSGraphRender's `examples/` to scratch, deletes
`layouts/foundation.png`, and re-runs the artifact check against the copy. The
deliberate failure is discounted from the tally; if it does *not* fail, that is
reported as a failure, because a check that passes against a damaged tree checks
nothing.

## Deviations

**1. Phase R's own dirty-tree hard stop fired, and was resolved by the operator
rather than by the agent.** R1 opens with 🔴 dirty tree. The tree was dirty by
exactly one tracked file — `AI.Agent.Claude.PowerShellModuleBuilder.code-workspace`,
with `../PSModuleGraph` removed from its folder list. That is the operator action
the Before-launch block required, and in this workspace the session's
working-directory list *is* that tracked file, so performing the required action
necessarily dirties the harness tree. Letter and intent disagreed. The agent
stopped and asked rather than resolving; the operator directed that it be
committed alone and the pass continue. Committed at `80a8723`, one file.

**2. The verify script is at `plans/0043-examples-showcase/verify.ps1`, not
`verify/Verify-Pass0043.ps1`.** Section 7 names a top-level `verify/` directory
that has never existed in this repository. Every pass from 0011 onward puts its
verify script at `plans/<pass>/verify.ps1`, and decision 0004 — the decision that
governs verify scripts — lists exactly that shape in its own artifacts. Creating
a divergent top-level directory to satisfy a path string was the worse option.

**3. SC2's stated pattern reports every clean artifact as a violation.** The
prompt gives the pattern as `[A-Za-z]:[\\/]`, which matches the `p:/` inside
`http://` and the `e:/` inside `vscode://` — every URL in every document. Run as
written it found 18 hits in each of six genuinely clean PSGraphRender artifacts.
The check needs a negative lookbehind: `(?<![A-Za-z])[A-Za-z]:[\\/]`. With that
correction, 0 hits everywhere. Recorded because the uncorrected pattern would
have aborted the pass on artifacts that were already correct.

**4. SC2's `vscode://` clause was narrowed to machine-identifying content, and
the R-links row was rescoped — operator ruling.** Two findings, reported before
any code was written:

- SC2's literal requirement of zero `vscode://` hits is unsatisfiable. Every
  cytoscape-rendered document contains about eight, of which five are UI copy in
  the renderer's own `strings.psd1` ("Your browser is blocking vscode:// links…")
  and the rest the hardcoded constant in `editor-link.js`. No producer can
  suppress them, and the showcase is built on cytoscape documents. Verified
  against artifacts committed by an earlier pass.
- R-links requires node links as **https URLs into the repo on GitHub**.
  `vsCodeUriFor` hardcodes the `vscode://file/` prefix and `NODE_ACTIONS` binds
  to it; no setting names an alternative. Setting `meta.rootPath` to a forge URL
  yields the broken `vscode://file/https:/github.com/…`. The requirement was
  architecturally unsatisfiable without changing a versioned module inside a
  documentation pass.

The operator's ruling: strike the https requirement — it came from the prompt,
not from the repository, and the repository's actual capability won. Keep the
row, with `meta.rootPath` set to the literal `REPLACE-WITH-YOUR-CLONE-PATH` so
the committed report demonstrates the editor-link action with visibly inert
placeholder links, and the index states that a local rebuild with the reader's
own `rootPath` produces live ones. Narrow SC2 to what it is for: zero
drive-absolute paths, zero links resolving to a real machine. Implement nothing;
file a backlog item instead. Done — **A node link can only ever be an editor
scheme**, logged as *large* in PSGraphRender's `docs/improvements.md`, wanting
its own red-first iteration.

**5. SC4's stated method cannot distinguish a drawn screenshot from a blank
one.** Section 5 asks for a size threshold and pixel variance over the image. The
78-node Terraform report renders as a race — identical invocations produced a
full canvas and an empty one at the same virtual-time budget, and a longer budget
did not settle it — and a blank canvas beside a fully populated sidebar still
measures 68,521 bytes and 169 distinct colours. Any threshold that passes the
9-node precedence graphs also passes that blank page. Sampling the **canvas
region alone** separates them without ambiguity: 2 colours blank against 971
drawn. The screenshot tool now measures that region and retries until it is
drawn, so no committed PNG rests on winning a race.

**6. The public-artifact rule was applied, and one pre-existing violation was
repaired.** Nothing this pass committed carries a machine-absolute path or a
`vscode://` link resolving to one; every input uses the literal
`REPLACE-WITH-YOUR-CLONE-PATH`, and the PSTerraformGraph builder rewrites both
`node.path` and `meta.roots` to be repository-relative after scanning. The
divergence from the internal diagram convention is deliberate and internal docs
are unchanged. One violation predated the pass:
`PSGraphRenderToHtml/README.md` illustrated the producer contract with
`"path": "C:/src/app/main.tf"`. It is fictional rather than anyone's machine, but
a documentation snippet is where a reader learns the shape to copy. Changed to
`/srv/src/app/main.tf` at `55deb28`. The resolved browser path appears in the
preconditions table above and in `scratch/Shoot.ps1`, which is pass-time tooling
and is committed to no repository.

**7. `meta.stats` in the R-layouts input claimed 33 links where there are 34.**
Hand-counted wrongly on the way in; the renderer's own header said 34 and was
right. Corrected before the artifacts were committed, and the affected documents
and screenshots regenerated. No claim without a citable artifact applies to the
inputs too.

**8. The R-theme pair is `default`/`contrast`, not `dark`/`light`.** The
acceptance test was written naming a dark/light pair before the theme surface
had been read. `theme.psd1` carries no page-background key — page chrome is CSS,
and what a theme controls is the node and edge palette, geometry and heat ramp.
A dark/light pair was therefore not achievable, and shipping artifacts named for
something they do not demonstrate is worse than renaming the row. The honest pair
is the shipped palette against a genuinely different one. The test was corrected
before any theme artifact was built.

**9. Two pre-existing drifts found in PSAzureDevOpsGraph, recorded and not
repaired.** Its manifest declares `ModuleVersion = '0.1.0'` while the tag line
has now reached `v0.4.0`, and its `PreTag` build task filters on a Pester tag
that no test in `tests/` carries — so `./build.ps1 -Task PreTag` runs zero tests
and reports success. Both predate this pass and both are in `src/`-adjacent
territory this pass had no mandate to touch. Recorded in that repository's
`docs/HANDOFF.md` and in its `v0.4.0` worklog.

**10. The Terraform fixture was read from the harness copy, because decision 0011
records no SHAs.** Section 3 says to clone "at the read-back-verified SHAs
recorded in decision 0011". Decision 0011 records no SHAs; what it does record is
that the three fixture repositories were "authored in the harness at
`evals/tf/fixture/repos/` and pushed; **the harness copy is the source of
truth**, verified by byte read-back". The fixture was therefore staged read-only
into `scratch/tf-fixture` from that source of truth and scanned there. Content
fingerprint of the three trees, for a later pass to compare against:
`18c84ed9eea5d6ca13b78d749a0a43ec07c20443b174aa17d20a3af12ddd37d4` (sorted
SHA-256 of every `.tf`). The committed regeneration command takes a
caller-chosen `-FixtureRoot` and clones from
`https://dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git` if the checkouts
are absent, so no path from this machine is baked into anything. Nothing was
written to the fixture.

**11. Every example builder also ships an offline path, which the prompt did not
ask for.** A-live and T-fixture regenerate from live sources, which a stranger
cannot do — one needs a token, the other needs access to a private project. Both
builders separate the read step from the render step, so `-Offline` rebuilds the
HTML from the committed graph with no network and no credential. The prompt's
regen command is still the default and still reads the PAT from `$env:AZDO_PAT`
by name. Added because a regeneration command that only its author can run is
not evidence a reader can check.
