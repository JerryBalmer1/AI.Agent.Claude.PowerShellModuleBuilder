# Pass 0048 — the STRINGS block joins the byte gate (backlog 64)

**Tier: full.** One assertion changed, and that does not lower the tier —
PLAN-PROTOCOL's worked example on pass 0012 is this shape inverted.

**Target:** PSGraphRender `tests/` and `CHANGELOG.md` only. Harness: this plan
record, `verify.ps1`, LEDGER, journal.

**Landed:** PSGraphRender `pass-0048-strings-byte-gate` at `5501755`; harness
branch of the same name. No tag, no version bump — `[Unreleased]` only.

---

## 0. Provenance of the prompt this pass executed

The operator's execute authorization named the revised 0048 prompt as
"held on your side" and put a 🔴 on executing against a **recalled** prompt.
This session did not hold it: it began fresh, with no 0048 text in context.

The guard's own escape is that the text may be **located verbatim**, and it
was — a single file, written by the authoring session, no competing draft
anywhere on disk:

| | |
|---|---|
| path | the authoring session's scratchpad, `pass-0048-prompt.md` |
| size | 15,931 bytes, 110 lines |
| sha256 | `063e7722f4c72d32c4e1a0c460c937b1512a81caf74bdbc9e4702ae7bfbc41c9` |
| written | 2026-09-04 02:03, before that session wrote its own memories at 02:21 |
| identified as the revised copy by | line 106 carrying the per-set generalization — *"log it as a question about \*n\* sets rather than about `plain`"* — which is exactly what the authorization document names as the revision's content |

The only other `*0048*` file on disk is this session's own tool output. Nothing
was reconstructed. The verbatim text is in section 1.

---

## 1. Prompt (verbatim)

```markdown
# PASS 0048 — the STRINGS block joins the byte gate (backlog 64)

## Operator preamble (runs before Section 0)

R1. 🔵 **Frontier, three sources from `origin/main`:** all three must read **0047** (LEDGER `Last landed:`, highest `plans/NNNN-*`, highest `journal/NNNN-*.md`). 🔴 Any other value, or disagreement between them. Expected true at authoring: harness `main` at `50e1f0e`, PSGraphRender `main` at `3f2ec85`, both level with `origin`, both clean, tag `v0.14.0` on `3f2ec85` (the tip).

R2. 🔵 **The reference clone is out of the working set — verify, do not re-do.** Between 0047 and this pass the operator moved `AI.Agent.Claude.PowerShellModuleBuilder/scratch/PSModuleGraph` (74 MB, `main` @ `d39b125`, tree clean, nothing unpushed, nothing untracked) to `../scratch/PSModuleGraph-d39b125`, beside the `2d97a27` snapshot pass 0043's R4 put at `../scratch/PSModuleGraph`. Assert only this: no directory named `PSModuleGraph` exists anywhere within either session directory. 🔴 One exists. ⛔ Do not move, fetch, open or delete anything under `../scratch/` — both copies are outside both repositories and outside git, and the one at `../scratch/PSModuleGraph` is where an instructed relocation deliberately put it.

R3. Section 0's dirt check runs against that state. Both repos clean, no carve-outs.

---

## Signals

🔴 hard stop (report, never resolve) · 🟠 operator action · 🟢 agent task · 🔵 evidence gate · ⛔ never, whole pass. Per PLAN-PROTOCOL.

**Tier: full.** This pass changes an assertion. It writes few documents and that does not lower the tier — PLAN-PROTOCOL's worked example on pass 0012 is this exact shape, inverted. Preconditions, red-first acceptance, per-task evidence, `verify.ps1`, deviations, cost.

**Target repositories:** `PSGraphRender` (writable: `tests/` and `CHANGELOG.md` only) and `AI.Agent.Claude.PowerShellModuleBuilder` (plan record, `verify.ps1`, LEDGER, journal). This workspace holds exactly those two. ⛔ No `src/` change in PSGraphRender — see Constraints. ⛔ Nothing reaches Azure DevOps; no other repository is touched.

**Purpose.** Close **LEDGER backlog 64**. `tests/LinkMode.Tests.ps1` carries the strongest gate PSGraphRender has against a refactor that claims to preserve behaviour and does not: an `editor`-mode document must be byte-identical to the base's for the same payload. `Get-DocumentCode` (lines 125–135) removes the whole `STRINGS` block before that comparison, because acceptance B's carve-out for `vscode://` prose is exactly that block and one helper serves both. So **every user-visible string in the renderer is invisible to the byte gate.** Pass 0047 added three strings and proved them additive by reading the diff — which is the thing this gate exists to replace. Backlog 64 states the fix shape and names the pass that should take it: *"compare STRINGS the way CONFIG is already compared, where an existing key may not change value and only additions are permitted."* This is that pass.

## 0. Sync

🟢 Fetch both workspace repos (`--all --tags --prune`), ff-only updates. 🔵 Report branch, HEAD, ahead/behind and clean for each. 🔴 Divergence or dirt. 🔴 A directory named `PSModuleGraph` registered as a workspace folder **or present anywhere within a session directory** — this wording is amended from 0047's. That prompt said "present in this workspace's folders or the session's directory list", which a clone sitting *inside* a registered folder satisfies without firing; see task 7's backlog entry.

## 1. Preconditions

1. **Frontier, three sources:** 🔴 any source shows 0048 assigned — a `plans/0048-*`, a `journal/0048-*`, a LEDGER citation, or a `pass-0048-*` branch in either repository. 🔴 The three disagree with each other. Record all three 🔵.
2. 🔴 Either repo not on `main`, not clean, or not ff-synced. PSGraphRender expected at `3f2ec85` / `v0.14.0`; harness at `50e1f0e`. 🔴 If either `main` has moved, stop and report — every file citation below was read from those trees.
3. 🔵 **Constraints read first:** read `docs/constraints.md` in full; record "no conflict" or the specific entry a task collides with. 🔴 A collision — an accepted limitation is a ruling, and the operator reopens it, not this pass.
4. 🔵 **Design surface derived, not recalled.** Read and record verbatim excerpts of: `Get-DocumentCode` and `Get-DocumentBlockRange` / `Get-DocumentBlock` in `tests/LinkMode.Tests.ps1`; the CONFIG comparison at lines 346–367, which is the shape to mirror; the two byte comparisons at lines 326–344; the `STRINGS` read already in use at line 262; and `Config/strings.psd1` of the shipped `cytoscape` set. 🔴 Any of these cannot be established unambiguously.
5. 🔵 **The suite's assertion dialect.** The `Test` task sets `$config.Should.DisableV5 = $true`, so a classic `Should -Be` throws. Every assertion this pass writes uses the Pester 6 family the file already uses (`Should-Be`, `Should-BeCollection`, `Should-ContainCollection`, `Should-BeNull`, `Should-BeTrue`, `Should-BeFalse`, `Should-BeGreaterThan`). Record the line that sets it.
6. **Sequencing gate:** 🔴 task 2's assertion written before section 2's reds are observed and committed.

## 2. Acceptance — the blindness observed first, in both directions

The red-first artifact here is **not** a failing new assertion. It is the *existing* suite passing while the thing it should catch has already happened. Observe both directions against `3f2ec85` before writing anything, the way pass 0046 observed both directions of backlog 62.

🟢 Commit these observations, as recorded output under `plans/0048-strings-byte-gate/`, before any implementation.

- **D1 — a changed value is invisible.** In a scratch copy of the shipped `cytoscape` template set, change one existing string's value. `MenuOpenLink` at `Config/strings.psd1:139` is the natural choice, since 0047 added it and backlog 64 names it. Render, run the current acceptance-C comparisons against the base. 🔵 They come back **GREEN**. That is the hole.
- **D2 — an added key is invisible.** Same copy, add a key that does not exist. 🔵 The current comparisons come back **GREEN**.
- **D3 — the mutation actually landed.** 🔵 For each of D1 and D2, assert that the *rendered document* changed before the green is trusted. A substitution that matched nothing leaves the target intact and produces a green run that proves nothing — METHOD names this as the failure that reports toward the alarming answer, which is the one nobody double-checks. Diff the `STRINGS` block of the mutated render against the unmutated one and record it.

🔵 Also record the conformance baseline: `evals/conformance/Invoke-Conformance.ps1` (0046-repaired) against PSGraphRender at `3f2ec85`, **all four tags**, score and cases-run, plus `CasesDefined`. Expected at authoring: 66.27% over 166 cases, `CasesDefined` 42.

## 3. Tasks (serial unless marked)

1. 🟢 Branch `pass-0048-strings-byte-gate` in PSGraphRender; the section-2 observations are the first commit; push after every task.

2. 🟢 **Add the STRINGS comparison, mirroring CONFIG.** One new `It` inside `Describe 'Acceptance C: editor mode preserves the base document exactly'`, beside the CONFIG one at line 346, asserting against the base document that `Describe` already builds:
   - the set of `STRINGS` keys present at head and absent at base is **exactly** `MenuCopyLink`, `MenuOpenLink`, `ReasonNoTemplate` — the three 0047 added, **named rather than counted**;
   - **no key present at base has a different value at head**;
   - the failure message names the offending key and both values. A gate whose message says only "the documents differ" sends the reader back to a 3,000-line diff, which is the problem `Get-FirstDifference` already exists to solve.

   It goes in this file and this `Describe` because the base document is expensive — a clone plus a full build in a child process — and a second file would pay for it twice. ⛔ `Get-DocumentCode` is **not** changed: acceptances A and B need the carve-out it provides, and removing it turns acceptance B's `vscode://` assertion red against correct work.

3. 🟢 Green the new assertion. 🔵 Record the full `Test` task output including the coverage line — the 80% threshold throws, so it is a gate that can fail and its number belongs in the record.

4. 🟢 **Falsify it** (parallel with 5). Every probe mutates a scratch copy, 🔴 never `src/`, and each break asserts it changed the document before the suite is re-run:
   - **P1 — a changed value goes red.** D1's mutation, re-run against the new assertion. Red, with a message naming `MenuOpenLink` and both values.
   - **P2 — an added key goes red.** D2's mutation. Red, naming the unexpected key.
   - **P3 — a removed key goes red.** A shipped key deleted. State which clause catches it. If none does, that is a finding, and the assertion is amended before any result including it is counted.
   - **P4 — scope control, and it is the load-bearing probe.** Mutate something *outside* `STRINGS` — a `theme.psd1` value. 🔵 The new `It` stays **GREEN** while the existing body comparison goes **RED**. This is what proves the two are independent checks rather than one check written twice, and it is the probe 0047's P1b lesson asks for: assert the division of labour between checks, not only that each check works.

5. 🟢 Records (parallel with 4): `CHANGELOG.md` under `## [Unreleased]`, in the repository's own form. ⛔ **No tag and no version bump.** Nothing a consumer installs changes; the version ledger's "patch for a normal implementation" is about implementation, and `[Unreleased]` exists for exactly this case. 🔴 If the pass finds itself wanting a tag, stop and report rather than taking one.

6. 🟢 Harness records: `plans/0048-strings-byte-gate/plan.md` (prompt verbatim, evidence, Deviations) and `plans/0048-strings-byte-gate/verify.ps1` (decision 0004; `-FailCheck`; scratch-only writes).

   **The verify script's ref targets are named here rather than left to be deviated into** — that is 0047's recorded authoring debt, where tasks 6 and 8 conflicted for a main-only verifier and `-HeadRef` had to be invented mid-pass. `-BaseRef` defaults to `3f2ec85`; `-HeadRef` defaults to `main`; the script refuses to run when the two resolve to the same commit, because six green checks over an unchanged tree is the most confident wrong answer it can give. Run it twice: once with `-HeadRef <pass tip>` before task 8, and once against landed `main` after, as 0047 did at `50e1f0e`.

   Checks: the four probes above; the new assertion green; acceptances A, B and C green; conformance at head ≥ base 🔵 with **both scores and both cases-run measured in-run at both commits rather than quoted**; `CasesDefined` at both ends.

7. 🟢 LEDGER and journal. Counter to 0048. **Backlog 64 RESOLVED in place**, amended by dated append and never rewritten. **Backlog 65 opened** — the next free number, verified off the file, not off this prompt:

   > *The workspace-composition assertion cannot see a reference clone inside a registered folder.* `evals/conformance/Conformance.Tests.ps1:486` checks the `folders` entries of tracked `.code-workspace` files, and its own comment at lines 469–475 states the intent it serves — PSGraphRender's reference implementation is "kept out of the working set on purpose", because a reference in the editor's workspace is a writable working directory whose own instructions load into the session. The harness workspace file registers `"path": "."`, so a 74 MB clone under `scratch/` with its own 18.9 KB `CLAUDE.md` was inside the working set until the operator moved it on 2026-09-04 — its directory mtime read 2026-08-28, which dates the exposure but is not proof of it — and the assertion is structurally incapable of seeing it. The comment records that two sessions of pass 0043 "looked for a directory on disk rather than for the file that puts one there"; this is the same defect inverted — a check on the file that registers a folder, blind to a directory inside a folder already registered.

   **STANDING, not fixed here.** Repairing it changes a conformance assertion and therefore the denominator, which METHOD says wants its own red-first iteration with cases-run stated at both ends.

   Record also, as fact rather than as work: the operator's relocation of the `d39b125` clone; and this pass's **fourth** independent reproduction of `CasesDefined = 42` against a Pins section that still reads 41 (backlog 63, still STANDING — ⛔ do not move the pin, it carries a series boundary).

8. 🟢 Fast-forward both mains per decisions 0009 / 0010, ancestry verified by `git merge-base --is-ancestor`. ⛔ Never force. ⛔ No tags.

## 4. Spot-checks (🔵 each; red-capability demonstrated in BOTH directions per METHOD)

Every one gets a known-bad and a known-good input before its first counted result. Pass 0043 shipped three checks without that and all three were wrong — two would have gone red on good input and one green on bad, so no single-direction demonstration would have found all three.

- **SC1 — the message is diagnosable.** A mutated `MenuOpenLink` produces a failure naming the key and both values. Known-good: unmutated, green and silent.
- **SC2 — the two checks are not one check twice.** With `STRINGS` mutated, exactly the new `It` is red and the body comparisons green; with the body mutated, exactly the reverse. Both directions recorded.
- **SC3 — the expectation is not vacuous.** The additions list asserts three named keys against a base that genuinely lacks them. Known-bad: the list emptied — the assertion must then go **red** against the current head rather than passing on nothing. "Zero cases is not a pass" applies to an expectation as much as to a run.
- **SC4 — nothing machine-identifying.** The 0043 grep (drive-absolute paths; `vscode://` carrying a real path) across everything this pass commits. Red demo: the 0044-era fixture form.

## 5. Constraints

⛔ No `src/` change in PSGraphRender — not the strings, not the template sets, not the module. Every probe mutates a scratch copy.

⛔ `Get-DocumentCode` unchanged.

⛔ **Acceptance C's base SHA at line 286 stays `cd4857d`.** Re-baselining to `3f2ec85` is a separate claim, and it would empty the additions list — leaving a gate whose expectation is "nothing was added", vacuous by construction on the day it ships. Keeping `cd4857d` means the gate asserts 0047's three additions from its first run.

⛔ No tag, no release, no version bump. ⛔ No conformance assertion or harness instrument change — backlog 65 is logged, not taken. ⛔ No `contract/` change. ⛔ No changes to PSGraphRenderToHtml, producers, or fixtures.

Improvements-log size rules apply to anything found en route: small rides along in its own commit, medium and large are logged and stopped on.

**One finding this pass is expected to write, and it should be written knowing what is coming.** The `plain` template set has its own three-key `Config/strings.psd1` and no acceptance-C document, so this gate covers the `cytoscape` document only. Whether the gate should generalise across template sets is a **finding to log**, not work to take — but log it as a question about *n* sets rather than about `plain`: a third set is already on the operator's list (item 2, the 3D backend), it will arrive with its own strings, and a gate that has to be hand-written per set is one somebody forgets on the fourth. Name that in the entry so the next pass inherits the shape of the question instead of re-deriving it.

## 6. Local handoff — the last act

🟢 Both workspace repos: checkout `main`, `pull --ff-only`, `fetch --tags --prune`, status clean; 🔵 LOCAL STATE table (repo | branch | HEAD | clean). Divergence or dirt reported, never resolved.
```

---

## 2. Rulings in force (restated per the execute authorization)

1. **The revised copy supersedes the first 0048 in full.** Section 0 records how
   it was located and how it was identified as the revised copy.
2. **Per-set generalization ratified.** The gate question is asked about *n*
   template sets, because item 2 brings a third and a hand-written gate per set
   is the one somebody forgets on the fourth. Written that way in the LEDGER
   entry, not as a question about `plain`.
3. **All six authoring decisions from the original 0048 stand as ratified:**
   acceptance C's base at `cd4857d` (non-vacuous by construction — it asserts
   0047's three named strings on first execution; SC3 falsifies by emptying the
   expected-additions list); blindness-as-red-artifact (observe the existing
   suite green while a shipped string is mutated, both directions, D3 asserting
   the mutation reached the document); P4 as the load-bearing division-of-labour
   probe; tier full; **no tag**, with a 🔴 if the pass talks itself into one;
   `-BaseRef` / `-HeadRef` named at authoring with the twice-run pattern.
4. **Backlog 65 stays filed, not fixed.** The denominator move gets its own
   iteration.

---

## 3. Operator preamble and Section 0 🔵

| | expected | measured |
|---|---|---|
| harness `main` | `50e1f0e` | `50e1f0e` ✔ |
| PSGraphRender `main` | `3f2ec85` | `3f2ec85` ✔ |
| tag on PSGraphRender tip | `v0.14.0` | `v0.14.0` ✔ |
| both level with origin | 0 ahead / 0 behind | 0 / 0 both ✔ |
| both clean | yes | `git status --porcelain` empty in both ✔ |

**R2 — the reference clone.** `find` over both session directories for a
**directory** named `PSModuleGraph*` returns nothing. The only hits on that name
are two baseline result *files*, `evals/conformance/baseline/psmodulegraph-*.json`,
which are not what the assertion is about. Both copies remain at
`../scratch/PSModuleGraph` and `../scratch/PSModuleGraph-d39b125`, outside both
repositories; nothing under `../scratch/` was moved, fetched, opened or deleted.

---

## 4. Preconditions 🔵

**1 — frontier, three sources from `origin/main`.** LEDGER `Last landed: **0047**`;
highest `plans/` is `plans/0047-link-mode`; highest journal is
`journal/0047-link-mode.md`. All three agree. No `plans/0048-*`, no
`journal/0048-*`, no LEDGER citation of 0048, no `pass-0048-*` branch in either
repository at start.

**2 — repository state.** As the table above. Both on `main`, clean, ff-synced.

**3 — constraints read first.** `docs/constraints.md` read in full. **No
conflict.** Two entries sit adjacent to this work and neither collides:

- `0003-t1` — *"Semantic equivalence checks the dimensions somebody listed. Six
  were chosen; a difference outside all six passes. Every comparison of two
  documents is a chosen list."* That is about `Compare-RenderDocument`, which
  this pass does not touch, and its principle **supports** the work: adding
  `STRINGS` to a chosen list is what backlog 64 asks for.
- `0002-t1` — *"`plain` is trivial enough to prove less than it looks… its
  triviality is what makes it a control."* This is why the ratified framing is
  right. The question for `plain` specifically is already ruled; the open
  question is about *n* sets, which is how the LEDGER entry words it.

**4 — design surface, derived.** Read from `3f2ec85`, not recalled:

| what | where | what it says |
|---|---|---|
| `Get-DocumentCode` | `tests/LinkMode.Tests.ps1:125–135` | keeps every line **outside** the `STRINGS` block range; its own comment says "Acceptance B's carve-out is exactly this block and nothing else" |
| `Get-DocumentBlockRange` / `Get-DocumentBlock` | `:95–122` | locates `const NAME = {` … `};` by bounds, parses the block as JSON |
| the two byte comparisons | `:326–344` | `Get-DocumentCode` then `-replace '(?ms)^const CONFIG = \{.*?^\};'`, compared with `Get-FirstDifference … Should-BeNull` |
| the CONFIG comparison — **the shape to mirror** | `:346–367` | added names via `Should-BeCollection @('LinkHrefTemplate','LinkMode')`; **`$head.LinkMode \| Should-Be 'editor'`**; then every base key compared by compressed JSON with `-Because "setting '$name' must be untouched"` |
| the `STRINGS` read already in use | `:262` | `Get-DocumentBlock -Document $script:NoneDoc -Name 'STRINGS'` |
| acceptance C's base SHA | `:286` | `$script:BaseSha = 'cd4857d'` |
| `Config/strings.psd1`, shipped `cytoscape` | `:139`, `:140`, `:149` | `MenuOpenLink = 'Open Link'`, `MenuCopyLink = 'Copy Link'`, `ReasonNoTemplate = 'LinkHrefTemplate is not set'` |

That the CONFIG mirror **pins one added key's value** — `LinkMode` — is the
detail that decided how this pass ended. See section 7.

**5 — the suite's assertion dialect.** `$config.Should.DisableV5 = $true` at
`PSGraphRender.build.ps1:663` (the `Test` task) and again at `:727` (`PreTag`).
Pester pinned to `6.1.0` in `Requirements.psd1:12`. Every assertion written here
is `Should-Be` / `Should-BeCollection`.

**6 — sequencing gate.** Honoured. The section-2 observations are commit
`6dfd6e0` on the harness branch; the assertion is commit `616a03f` on the target
branch, written after.

---

## 5. Acceptance — the blindness, observed first 🔵

`observe.ps1` → `observe-blindness.txt`. The comparison logic in it is copied
**verbatim** from the suite; a probe running different code from the check it
probes proves nothing about the check.

**D3 ran before either green was trusted.** Both mutations demonstrably reached
the rendered document:

| | keys added | keys changed |
|---|---|---|
| D1 | (none) | `MenuOpenLink`: `[Open Link]` → `[MUTATED BY D1]` |
| D2 | `D2AddedKey` | (none) |

**D1 and D2 — the hole.** With the mutation in the document, the shipped
acceptance-C comparisons against the base:

| case | result |
|---|---|
| D1 (changed value) | **GREEN** — `Should-BeNull` passes |
| D2 (added key) | **GREEN** |
| control (unmutated) | GREEN |

Recorded beside it, and load-bearing for task 2: `STRINGS` at head over base is
**exactly** `MenuCopyLink`, `MenuOpenLink`, `ReasonNoTemplate` — none removed,
none changed, 78 keys → 81. The additions list is therefore non-vacuous by
construction, as ratification 3 says.

**Conformance baseline** 🔵 — `conformance-base.txt`, PSGraphRender at `3f2ec85`,
all four tags: **66.27% over 166 cases, Passed/Failed 110/56, `CasesDefined` 42.**
Matches the figure the prompt expected.

---

## 6. What was built

One `It`, inside `Describe 'Acceptance C: editor mode preserves the base document
exactly'`, beside the CONFIG one. Against the same `$script:BaseDoc`:

- the `STRINGS` keys present at head and absent at base are **exactly**
  `MenuCopyLink`, `MenuOpenLink`, `ReasonNoTemplate` — named, not counted;
- the three added keys are pinned **by value** as well as by name (see section 7);
- no key present at base has a different value at head, `-Because "string
  '$name' must be untouched"`, so the message names the key and `Should-Be`
  prints both values.

`Get-DocumentCode` is **unchanged**, per the constraint.

**Green** 🔵 — `test-task.txt`, full `Test` task: **144 passed, 0 failed,
line coverage 81.36% (target 80%)**, build succeeded.

---

## 7. The two probes that disagreed with the prompt

Both are recorded rather than quietly fixed, because both are the probes doing
their job.

### P1 — the gate could not see the keys it was about

Written as the prompt specifies — additions by **name**, existing keys by
**value** — a changed `MenuOpenLink` came back **GREEN**. The value clause
iterates `$baseNames`, the keys present at *base*; all three keys 0047 added are
by definition **not** in it. So the three strings whose arrival the gate exists
to describe were the only user-visible strings it still could not see — the same
class of hole the pass was written to close, on exactly the keys in question.

The prompt's own rule for this is attached to P3 and is general: *"If none does,
that is a finding, and the assertion is amended before any result including it is
counted."* Amended, and the amendment is the faithful CONFIG mirror rather than
an invention — the CONFIG case beside it already spends one assertion on
`$head.LinkMode | Should-Be 'editor'`, described in its own comment as "the half
of the control that pins WHICH value the default is". Commit `1683612`.

### P4 — the prompt named the wrong check

P4 says: mutate a `theme.psd1` value, and *"the new `It` stays GREEN while the
existing body comparison goes RED"*. The first half holds. The second does not.

**Every theme value the page uses is emitted into the `CONFIG` block**, and the
byte comparison strips `CONFIG` before comparing. Measured: eight mutated colours,
all eight at lines 802–846, inside `CONFIG` (which spans 798–851). So a theme
edit turns the **CONFIG** comparison red and leaves the body comparisons green.

Split into two halves, which together are what P4 was reaching for:

| probe | mutation | STRINGS gate | CONFIG | body |
|---|---|---|---|---|
| P4a | a `theme.psd1` colour | GREEN | **RED** | GREEN |
| P4b | a line in `scripts/sidebar.js` | GREEN | — | **RED** |

That is the division of labour actually asserted: three checks that partition the
document, not one check written three times.

---

## 8. Falsification 🔵 — `probes-run.txt`

Every probe mutates a scratch **clone**, never `src/`, and every probe asserts
its mutation reached the rendered document before the suite is re-run.

| probe | claim | result |
|---|---|---|
| P1 | a changed value goes RED, naming key and both values | ok — message: `Expected 'Open Link', because added string 'MenuOpenLink' is pinned by value…, but got 'MUTATED BY P1'` |
| P2 | an added key goes RED, naming the unexpected key | ok — names `P2UnexpectedKey` |
| P3 | a removed key goes RED, and **which clause** catches it | ok — **the value clause**: a removed key reads `null` at head against `"Copy Path"` at base |
| P4a | theme → gate GREEN, CONFIG RED, body GREEN | ok |
| P4b | script line → gate GREEN, body RED | ok |
| control | nothing mutated → all four green | ok |

`TASK 4: PASS`.

---

## 9. Spot-checks 🔵 — `spotchecks-run.txt`

- **SC1 — the message is diagnosable.** Known-bad is P1 above (names the key and
  both values); known-good is the control (green and silent).
- **SC2 — not one check twice.** Both directions recorded: P1 (STRINGS mutated →
  gate red, body green) and P4b (body mutated → gate green, body red). P4a adds
  the third region.
- **SC3 — the expectation is not vacuous.** Known-good: the shipped list is
  green. Known-bad: the list emptied goes **RED**, and the message names what
  actually arrived — `@('MenuCopyLink', 'MenuOpenLink', 'ReasonNoTemplate')`.
- **SC4 — nothing machine-identifying.** Clean over 7 files; red demo catches a
  planted drive path, home dir and `vscode://` URI; known-good file produces no
  hit. **The detector is carved out of its own scan by exact leaf name** — a
  check for drive paths and `vscode://` URIs necessarily contains both, as a
  regex and as its own red demo. The carve-out is held to acceptance B's
  standard: an assertion proves it excludes something that really does match (4
  hits inside it), and another proves it left the pass's own files scanned.

`SECTION 4: PASS`.

---

## 10. Verify 🔵 — decision 0004

`verify.ps1`, `-BaseRef 3f2ec85` (pass 0047's tip, **not** acceptance C's
`cd4857d`), `-HeadRef main`, refusing to run when the two resolve to the same
commit. Scratch-only writes, removed afterwards. `$WrittenAgainstTarget` recorded
at the top, with a drift notice rather than a maintained-forward pin.

Six checks and five probes, re-derived from fresh clones:

1. the gate exists at head, is green, and **did not exist at base**;
2. acceptances A, B and C green — 22 cases, 0 red;
3. the three additions named, `cd4857d` still the base SHA, `Get-DocumentCode`
   still carving out `STRINGS`;
4. P1, P2, P3, P4a, P4b;
5. **conformance measured in-run at both commits, nothing quoted** — base
   66.27% over 166, head 66.27% over 166, `CasesDefined` 42 at both ends, no
   assertion that passed at base failing at head;
6. no machine identity, **no tag**, no version bump (`0.14.0 → 0.14.0`), no
   `src/` change.

`verify-run.txt` — **PASS**, exit 0, against the pass tip `5501755`.
`verify-failcheck.txt` — **PASS**, exit 0, with F1 (gate deleted → detected as
absent) and F2 (additions list emptied → RED) both firing.
`verify-landed-main.txt` — the run a later reader gets, against landed `main`.

---

## 11. Deviations

1. **The prompt was recovered from disk, not held in session.** The guard
   permits this — it stops only on a prompt that can be neither held nor located
   verbatim. Provenance in section 0, including the hash and the marker that
   identifies it as the revised copy. Flagged because the operator should know
   the recovery path was used.

2. **The harness took a pass branch; the prompt names one only for
   PSGraphRender.** Decision 0005 rule 1 gives every pass its own branch, and
   0047's branchless harness was a recorded exception with a cause that does not
   apply here. Both branches fast-forwarded at task 8.

3. **Task 1 says the section-2 observations are the first commit on the
   PSGraphRender branch; they were committed to the harness instead.** Forced,
   not chosen: the prompt's own target-repository rule makes PSGraphRender
   writable at `tests/` and `CHANGELOG.md` only, and section 2 puts the
   observations under `plans/0048-strings-byte-gate/`, which is the harness.
   Read as ordering rather than location, the two agree — and the ordering was
   honoured.

4. **The assertion was amended mid-pass to pin the added keys by value.** P1's
   finding, section 7. Taken under the prompt's own amendment rule, before any
   counted result included it.

5. **P4 was split into P4a and P4b because the prompt named the wrong check.**
   Section 7. The prompt's stated intent — assert the division of labour — is met
   more completely by the split than by the form as written.

6. **SC4 needed a carve-out for the detector, which the prompt does not
   mention.** A check for machine identity contains machine identity. Narrow
   (two exact leaf names), stated, and proved non-empty in both directions.

7. **Machine paths in the committed console captures are replaced with
   placeholders**, with a header on each saying so. SC4 forbids a drive-absolute
   path in anything the pass commits, and a console log is something the pass
   commits. Noted as a finding: `plans/0047-link-mode/probe-red-full.txt` carries
   five such lines, so either SC4 has not in practice been run over log
   artifacts, or 0047 shipped a violation of it. Not fixed here — 0047's plan
   artifacts are frozen by decision 0004.

8. **No deviation on the tag.** The pass did not want one and did not take one;
   `verify.ps1` check 6 asserts it.

---

## 12. Cost

Two source files changed in the target (`tests/LinkMode.Tests.ps1`,
`CHANGELOG.md`), 53 lines added to the suite. Harness: this record, `verify.ps1`,
three evidence scripts and six captured runs. Two full verify runs at roughly
four minutes each, dominated by four clone-and-build cycles and two conformance
runs over 166 cases.
