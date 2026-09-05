# Pass 0050 — the link probe becomes backend data (backlog 66)

**Tier: full.** A build task, a browser-harness file and two shipped manifests
change. PLAN-PROTOCOL's tier rule decides this, not the document count.

**Target:** PSGraphRender — `PSGraphRender.build.ps1`, `tests/browser/link-mode.cjs`,
`cytoscape/templateset.psd1`, `forcegraph3d/templateset.psd1`, a new test file,
and the docs. Harness: this plan record, `verify.ps1`, LEDGER, journal.

**Landed:** PSGraphRender `pass-0050-link-probe-data` at `e7bbfca`, tagged
**`v0.15.1`** on that commit; harness branch of the same name. Base was
`0d2c5df` (pass 0049's tip, `v0.15.0`).

---

## 1. The prompt this pass executed, verbatim

<details>
<summary>PASS 0050 — the link probe becomes backend data (backlog 66)</summary>

```
# PASS 0050 — the link probe becomes backend data (backlog 66)

Authored from the trees at PSGraphRender `main` = `0d2c5df` (v0.15.0 at
HEAD) and harness `main` = `fd091e7` (frontier 0049, next free backlog
number 67). Every citation below was read from those commits.

## Signals

🔴 hard stop (report, never resolve) · 🟠 operator action · 🟢 agent task ·
🔵 evidence gate · ⛔ never, whole pass. Per PLAN-PROTOCOL.

**Tier:** full — the pass changes a build task, a browser-harness file, and
two shipped manifests.

**Target repositories:** `PSGraphRender` (writable — the probe, its
consumers, and the manifests all live in this tree) and
`AI.Agent.Claude.PowerShellModuleBuilder` (plan record, LEDGER, journal
only). ⛔ No conformance assertion or harness-instrument change — the link
probe is PSGraphRender's own `TestLinkMode` task and `tests/browser/`, not
the conformance inventory, and the denominator is expected NOT to move
(verified, not assumed — see task 7). ⛔ No `contract/` change. ⛔ No
rendered-document change: every byte gate stays green.

**Purpose.** Harness backlog 66 / the medium entry at
`docs/improvements.md:63` ("The link probe names each backend's selectors
in the build task"). `PSGraphRender.build.ps1`'s `TestLinkMode` carries a
`$LINK_PROBE` map — per backend: `canvas`, `menu`, `button`, and for
`forcegraph3d` also `open`, `ready`, `settle`, `hover` — which is a second
place a backend's shape is written down, the exact defect the `Smoke`
block was invented to remove from `smoke.cjs` ("a harness naming
'#c-nodes' would be a second place this backend's shape is written down").
The blocker that logged it instead of fixing it — 0049's control that
`cytoscape/` does not move at all — was pass-scoped and has expired.
The probe declaration moves into each `templateset.psd1` beside `Smoke`;
the build task reads manifests; the map dies.

**Derived at authoring, for the pass to confirm:** `link-mode.cjs:37` also
carries `DEFAULTS = { canvas: '#cy', menu: '#node-menu', button: 'right',
ready: '#cy canvas', hover: 0 }` — cytoscape's shape hardcoded inside the
harness file as fallbacks, a THIRD copy of the same knowledge. Once every
LinkMode-declaring backend must declare its probe, these defaults are dead
weight carrying one backend's selectors; the pass removes them (fields
required from the job) or records in Deviations why they must stay.

## 0. Sync

🟢 Fetch both repos (`--all --tags --prune`), ff-only. 🔵 Report.
🔴 Divergence or dirt. 🔴 `PSModuleGraph` in workspace folders or the
session's directory list.

## 1. Preconditions

1. **Frontier, three sources:** 🔴 any source shows 0050 assigned.
   🔴 Sources disagree. 🔴 Frontier below 0049. Record the values 🔵.
2. 🔴 Either repo not on `main`/clean/ff-synced. PSGraphRender expected at
   `0d2c5df`; 🔴 if moved — citations were read from that tree.
3. 🔵 **Constraints read first:** `docs/constraints.md` in full; record
   "no conflict" or the colliding entry.
4. 🔵 **Design surface derived, not recalled** — verbatim excerpts of:
   the `$LINK_PROBE` map and the throw-by-name guard in
   `PSGraphRender.build.ps1` (the guard's own comment: "a backend the
   probe skips is a mode nobody checked"); how `TestLinkMode` builds
   cases and copies probe keys onto them; `link-mode.cjs`'s job-field
   consumption including the `DEFAULTS` object and the settle/hover
   handling; the `Smoke` block's position and commentary in all three
   manifests (`plain` declares no `SlotsBySetting.LinkMode` and is
   skipped by discovery — it gains nothing this pass); how
   `tests/LinkMode.Tests.ps1`'s byte gate compares an editor-mode
   document to base (the manifest edit must be invisible to it); and
   whether anything else reads `templateset.psd1` keys such that an
   unknown top-level key breaks it (`Get-RenderTemplateSet.ps1`,
   `tests/Module.Quality.Tests.ps1`, `tests/Backend.Tests.ps1`).
   🔴 Any of these ambiguous.
5. **Sequencing gate:** 🔴 implementation before section 2's reds are
   observed.

## 2. Acceptance — red first

🟢 Commit acceptance tests before implementation:

- **A — the declaration is demanded:** a test asserting every backend
  whose manifest declares `SlotsBySetting.LinkMode` also declares a
  `LinkProbe` block beside `Smoke`, with the fields the harness consumes.
  Red today against both `cytoscape` and `forcegraph3d`: no such key
  exists in any manifest. Read the failure messages; a red that fires for
  a wrong reason is the `@($null)` lesson from 0049.
- **B — the probe still probes, identically:** `./build.ps1 -Task
  TestLinkMode` green after the move with the same case inventory as
  base — same backends, same modes, same case ids — and the guard still
  throws BY NAME for a scratch backend declaring `LinkMode` with no
  `LinkProbe`, now citing the manifest rather than the map. Red today in
  the inverted direction: the scratch backend currently throws citing
  `$LINK_PROBE`, which is the state being removed; record that
  observation as the base behaviour.
- **C — nothing rendered moves:** documents from all three backends
  byte-identical to base `0d2c5df` for the same payloads, and
  `tests/LinkMode.Tests.ps1`'s editor-mode byte gate green untouched —
  a new top-level manifest key must be invisible to assembly. Green
  before and after; red-capability via a scratch manifest edit that DOES
  flow into output (e.g. a `Slots` entry), caught by the same
  comparison.

🔵 Conformance baseline at base: score / cases-run / CasesDefined
(expected 66.27% / 166 / 42 — verify, don't assume).

## 3. Tasks (serial; push after every task)

1. 🟢 Branch `pass-0050-link-probe-data`; first commit the red acceptance.
2. 🟢 **Declare:** `LinkProbe` block in `cytoscape/templateset.psd1` and
   `forcegraph3d/templateset.psd1`, beside `Smoke`, carrying exactly the
   fields the map carries today — values moved, not re-derived; the
   forcegraph3d entry's settle/hover comments move with their data (the
   comment about a simulation still moving IS the reasoning, and data
   without it is a magic number). A `Smoke`-style header comment states
   what the block is, per the manifests' own documentation convention.
   `plain/` untouched.
3. 🟢 **Consume:** `TestLinkMode` reads `LinkProbe` from each discovered
   manifest; `$LINK_PROBE` deleted, its explanatory comment (523–526,
   which records why the map existed and cites the improvements entry)
   replaced by one line naming where the declaration now lives. The
   throw-by-name guard survives, inverted: fires for a manifest
   declaring `LinkMode` without `LinkProbe`, message naming the manifest
   and the missing key.
4. 🟢 **The third copy:** remove `link-mode.cjs`'s `DEFAULTS` fallbacks —
   required job fields, failing by name when absent — or record in
   Deviations why they stay. The harness file ends this pass knowing no
   backend's selectors.
5. 🟢 Green the acceptance. 🔵 Results verbatim, including the full
   `TestLinkMode` case list at base and head shown identical.
6. 🟢 Docs: `docs/improvements.md` medium entry (line 63) closed with
   this pass's reference, superseded text struck not deleted — the entry
   exists this time, verified at authoring; `docs/HANDOFF.md` state;
   `CHANGELOG.md` under the repo's own form.
7. 🟢 **Release:** expected **v0.15.1** — shipped manifest data moved,
   rendered output provably unchanged, which the repo's own CHANGELOG
   conventions should confirm reads as a patch; 🔴 if LEDGER's version
   line and the tag list disagree with each other; if the repo's
   conventions demand minor instead, record the reasoning and take it.
   Annotated tag; verify falsification before the release commit so the
   tag names the pass tip. 🔵 Conformance at head measured in-run:
   score / cases-run / CasesDefined recorded beside base — expected
   unchanged all three, and a moved denominator is a 🔴 (this pass has
   no license to change the conformance inventory).
8. 🟢 Harness records: `plans/0050-link-probe-data/plan.md` (prompt
   verbatim, evidence, Deviations); `verify.ps1` (decision 0004;
   `-FailCheck`; scratch-only writes; `-BaseRef`/`-HeadRef`, twice-run) —
   checks: acceptance A/B/C, guard fires by name on a scratch backend,
   grep proves `$LINK_PROBE` absent from the build task, byte gates
   green, machine-identifying grep clean, conformance both ends; LEDGER
   (counter 0050; version line to the tag; backlog 66 resolved in place,
   its text preserved per the ledger's own closed-item convention; new
   findings number from 67); journal (six fields, Capability never
   benefit).
9. 🟢 Fast-forward both mains per 0009/0010. ⛔ Never force.

## 4. Spot-checks (🔵 each; red-capability stated per METHOD)

- **SC1 — one place, checked by absence:** `grep -n 'LINK_PROBE'
  PSGraphRender.build.ps1` returns nothing, and `grep -n "'#cy'"
  tests/browser/link-mode.cjs` returns nothing — neither the task nor
  the harness knows a selector. Red demo: run both greps at base.
- **SC2 — the guard is real:** a scratch backend directory declaring
  `SlotsBySetting.LinkMode` and no `LinkProbe` fails the build by name
  before any browser launches. Red demo: the same scratch backend WITH a
  `LinkProbe` block proceeds to probing.
- **SC3 — output-invisible, from a fresh clone:** documents rendered at
  the tag from a fresh clone byte-identical to base's for all three
  backends. Red demo: the scratch `Slots` mutation from acceptance C.
- **SC4 — nothing machine-identifying:** the established grep across
  everything committed. Red demo: the known-bad fixture form.

## 5. Constraints

⛔ No conformance-inventory or harness-instrument change; a moved
denominator is a stop, not a finding. ⛔ No `contract/` change. ⛔ No
rendered-output change. ⛔ No new probe capabilities — fields move, they
do not grow; a field the move reveals as wanted is logged per the size
rules, not added. ⛔ `plain/` and `TemplateSets/index.psd1` untouched.
Improvements-log size rules for anything discovered en route.
Public-artifact rule for every committed artifact.

## 6. Local handoff — the last act

🟢 Both repos: checkout `main`, `pull --ff-only`, `fetch --tags --prune`,
status clean; 🔵 LOCAL STATE table (repo | branch | HEAD | clean).
Divergence or dirt reported, never resolved.
```

</details>

---

## 2. Preconditions, as measured

### Sync 🔵

| Repo | Branch | HEAD | vs `origin/main` | Clean |
| --- | --- | --- | --- | --- |
| `AI.Agent.Claude.PowerShellModuleBuilder` | `main` | `fd091e7` | 0 / 0 | yes |
| `PSGraphRender` | `main` | `0d2c5df` | 0 / 0 | yes |

`PSGraphRender` is at `0d2c5df` as the prompt expected, so every citation in it
was read from the tree this pass ran against. `PSModuleGraph` is in neither the
workspace folders nor the session's directory list.

### Frontier, three sources 🔵

| Source | Value |
| --- | --- |
| `LEDGER.md:8` `Last landed:` | **0049** |
| highest `plans/NNNN-*` | `plans/0049-forcegraph3d` |
| highest `journal/NNNN-*.md` | `journal/0049-forcegraph3d.md` |

All three agree, none shows 0050 assigned, and the highest numbered finding in
LEDGER is **66** — so **67 is the next free number**, as the prompt said.

### Constraints read in full 🔵

**No conflict.** `docs/constraints.md` has fourteen entries and none of them
touches where a backend's shape is declared. Two are adjacent and both argue
*for* this pass rather than against it:

- **`0002-t1`** — *`plain` is trivial enough to prove less than it looks.* It
  declares no `SlotsBySetting`, so it is skipped by discovery and gains nothing
  here. Its triviality being the point is why leaving it alone is correct rather
  than incomplete.
- **`0004-t4`** — *Playwright was measured and nothing else was.* One engine,
  headless, pinned. Unchanged by this pass; the probe drives the same engine.

### Design surface, derived from `0d2c5df` 🔵

**The map, `PSGraphRender.build.ps1:515–541`** — with the comment that logged
its own defect:

```powershell
        # How each backend's node actions are reached. Three fields: the element
        # to click in, the button that opens the actions, and the container they
        # land in. tests/browser/link-mode.cjs defaults to cytoscape's, so a
        # backend whose shape matches needs no entry.
        #
        # THIS IS A SECOND PLACE A BACKEND'S SHAPE IS WRITTEN DOWN, and that is
        # the same defect the Smoke block was invented to remove from
        # tests/browser/smoke.cjs. It is here rather than in each
        # templateset.psd1 for one reason: putting it there means editing
        # cytoscape's manifest, and this pass's no-regression control is that
        # cytoscape does not move at all. Logged rather than worked around
        # silently - see docs/improvements.md.
        $LINK_PROBE = @{
            cytoscape    = @{ canvas = '#cy'; menu = '#node-menu'; button = 'right' ; ready = '#cy canvas' }
            forcegraph3d = @{ canvas = '#fg'; menu = '#fg-actions'; open = '#fg-panel'; button = 'left'
                ready = '#fg canvas'
                settle = 3000
                hover = 150
            }
        }
```

**The guard, `:554–560`**, and how a case was assembled, `:566–572`:

```powershell
                if (-not $LINK_PROBE.ContainsKey($backend.Name)) {
                    throw ("$($backend.Name) declares link modes and this task does not know how to reach its " +
                        'node actions. Add an entry to $LINK_PROBE above; a backend the probe skips is a mode nobody checked.')
                }
                [pscustomobject]@{ Name = $backend.Name; Probe = $LINK_PROBE[$backend.Name] }
...
                    $case = @{ id = $id; file = $file; expect = $spec.expect }
                    foreach ($key in @($probe.Probe.Keys)) { $case[$key] = $probe.Probe[$key] }
```

**The third copy, `tests/browser/link-mode.cjs:31–55`** — the prompt derived it
at authoring and it is confirmed here exactly as stated:

```javascript
// ... The defaults are cytoscape's, so a job written
// before this file grew the fields behaves exactly as it did.
const DEFAULTS = { canvas: '#cy', menu: '#node-menu', button: 'right', ready: '#cy canvas', hover: 0 };

function selectorsFor(job) {
  const menu = job.menu || DEFAULTS.menu;
  return {
    canvas: job.canvas || DEFAULTS.canvas,
    menu: menu,
    open: job.open || menu,
    button: job.button || DEFAULTS.button,
    ready: job.ready || DEFAULTS.ready,
    hover: job.hover || DEFAULTS.hover
  };
}
```

with `await page.waitForTimeout(job.settle || SETTLE_MS);` at `:121`,
`SETTLE_MS = 500` at `:19`.

**The `Smoke` precedent settled the design.** `TestBrowser` passes the block
**whole and verbatim** under one job key — `smoke = $manifest.Smoke` at
`:373` — and `smoke.cjs` reads its **PascalCase** keys straight off it
(`smoke.Text`, `smoke.Elements`, `smoke.Present`, `smoke.CanvasGrowth`). It also
throws by name when the block is missing. `LinkProbe` therefore follows the same
three rules: PascalCase keys, passed through whole under one key, absent means
failing by name. Nothing about the shape was invented for this pass.

**Nothing rejects an unknown top-level manifest key.** `Get-RenderTemplateSet.ps1`
reads `Layout` (`:51`), `Slots` (`:55`) and `SlotsBySetting` (`:65`) and nothing
else. `Module.Quality.Tests.ps1:67` builds its "ships every file this manifest
names" list from `Layout` + `Slots` + `SlotsBySetting`, and `LinkProbe` names no
files. `Backend.Tests.ps1:133` writes its own one-key manifest. `Vendor.Tests.ps1`
reads `Slots`. No test enumerates top-level keys or rejects unknown ones.

**`tests/LinkMode.Tests.ps1`'s byte gate** clones the repo at a pinned
`$script:BaseSha = 'cd4857d'` (`:286`), builds it with its own `build.ps1` in a
child process, renders `sample-module.json` through the base's own cytoscape set,
and compares the head document to it with `CONFIG` stripped (`:326–344`). A key
invisible to assembly is invisible to that gate, so it should stay green with no
edit — asserted, below, rather than assumed.

---

## 3. What the reds actually demonstrated

The prompt names the `@($null)` lesson from 0049: a red that fires for a wrong
reason is not a red. Every failure message was read.

**Five reds, and two of them only became honest after the first run.** The
first pass at acceptance A had two `It` blocks that skipped a backend with no
`LinkProbe` and therefore **passed vacuously over an empty loop** — the same
shape of false green 0049 got from `@($null)`. Each grew a counter asserting it
examined every backend with link modes, and both went red for the right reason:

```
[-] declares a LinkProbe block for every backend that declares link modes
    Expected [bool] $true, because cytoscape declares SlotsBySetting.LinkMode,
    so something has to say how a browser reaches its node actions; without it
    the probe would either guess or skip the backend, but got: [bool] $false.
[-] carries every field the harness consumes, as a non-empty value
    Expected [int] 2, because every backend with link modes must have been
    examined here, not skipped past, but got [int] 0.
[-] names a real mouse button
    Expected [int] 2, ... but got [int] 0.
[-] keeps a probe map out of the build task
    Expected [bool] $false, because the build task must read the declaration,
    not carry a second copy of it, but got: [bool] $true.
[-] keeps every declared selector out of the browser harness
    Expected the actual value to be greater than [int] 3, because a check
    derived from an empty list checks nothing, but it was not. Actual: [int] 0
```

**The fifth red fires on its own guard, so the substantive form was
demonstrated separately.** The harness check derives the strings it forbids
*from the manifests*, and at base no manifest declares one — so it reports an
empty derivation rather than the thing it exists to catch. Fed the values the
map carried at base, the same comparison finds them
(`sc1-red-demo.txt`, and re-derived as verify check 2):

```
  NAMED IN HARNESS: '#cy'
  NAMED IN HARNESS: '#node-menu'
  NAMED IN HARNESS: 'right'
  NAMED IN HARNESS: '#cy canvas'
```

**Acceptance C was green before and after, which is what it claims.** Its
red-capability is a sibling `It` in the same file: the same fixture with a
`Slots` edit instead of a stripped `LinkProbe`, asserted to produce a
*different* document. Both were green at base, and both are green at head.

**The base guard behaviour, recorded before it was replaced.** A scratch copy of
`cytoscape` under a fourth directory name, at `0d2c5df`:

```
ERROR: zzscratch declares link modes and this task does not know how to reach
its node actions. Add an entry to $LINK_PROBE above; a backend the probe skips
is a mode nobody checked.
```

---

## 4. Rulings

**PascalCase keys, and the block passed through whole.** The alternative was to
keep the map's lowercase field names and go on flattening them onto each case.
Rejected: `Smoke` is the precedent this block is being moved *to sit beside*,
and it is PascalCase, passed under one key, read by the harness off that key.
A second convention in an adjacent block would be a new inconsistency bought to
avoid a rename. The values are moved verbatim; only the key names follow the
file they now live in.

**`Open`, `Hover` and `SETTLE_MS` keep their fallbacks, and this is a
Deviation from the plain reading of task 4.** The rule the pass is enforcing is
that *the harness knows no backend's selectors* — not that the harness has no
defaults at all:

- `Open` falls back to `Menu`. That is a relationship between two fields the job
  *did* supply, and the file already documents why it exists: the two are the
  same element for a context menu and different for a panel. cytoscape's
  `LinkProbe` declares no `Open`, exactly as its map entry declared no `open`.
- `Hover` falls back to `0` — the absence of a delay, which names nothing.
- `SETTLE_MS` (500) stays as the harness's own floor wait. Making `Settle`
  required would mean writing `Settle = 500` into cytoscape's manifest, a value
  the map never carried; the pass's own constraint is that **fields move, they
  do not grow**. Its comment no longer attributes the number to cytoscape.

What is gone is every selector: `Canvas`, `Menu`, `Button` and `Ready` are
required and missing fails by name. Verify check 2 tests this by *deriving* the
forbidden literals from the manifests, so the claim is not "these four strings
are absent" but "nothing any backend declares appears here".

**Failing inside the `try`.** `selectorsFor` moved into `runCase`'s try block, so
a job that declares too little fails as a named case in the JSON report rather
than as a crash with a browser context still open.

**Tasks 3 and 4 landed in one commit.** They are one swap: the job's shape
changes on both sides at once. Split, the middle state drives `forcegraph3d`
with cytoscape's fallback selectors — the exact defect being removed. Task 2
landed separately and is genuinely independent: with the map still in place the
new manifest key is inert and the build stays green on it.

**Rejected: a test asserting the moved values are the values the map held.**
It would be a fourth place the selectors are written down, in the file whose
whole purpose is that there is one. Acceptance A asserts the *fields* are
present and usable; the browser run asserts the *values* work; verify's P3
asserts they are what drives the probe.

---

## 5. Deviations

1. **`link-mode.cjs` keeps three fallbacks.** `Open → Menu`, `Hover → 0`,
   `Settle → SETTLE_MS`. Reasoned above under Rulings, and permitted by task 4's
   own "or record in Deviations why they stay". No selector remains.
2. **Tasks 3 and 4 are one commit**, for the reason above. Task 2 is its own.
3. **Acceptance B's live half is a build-task run, not a Pester assertion.**
   `TestLinkMode` needs a browser and forty seconds; it is not in the suite the
   `Test` task runs, and it was never going to be. Its case inventory is
   compared base-to-head in this pass and re-derived in `verify.ps1` check 4.
   The Pester-expressible half of B — no map in the task, no selector in the
   harness — is in `tests/LinkProbe.Tests.ps1`.
4. **SC4 went red against this pass's own harness records, and `verify.ps1` was
   fixed rather than the records sanitised.** Three things in the first draft
   would have shipped a machine's layout into the repository: `Copy-BrowserHarness`
   echoed the absolute source directory into both verify records; the
   machine-identity grep matched a username **written down as a literal**, which
   is 0047's form and puts a username into the verifier that exists to keep
   usernames out of files; and P5 assembled its known-bad path as a literal, so
   the verifier failed the check it verifies. Fixed at the source — the version
   without the path, `$env:USERNAME` derived with a length guard, and the bad
   path composed from pieces — and **both verify runs were re-run from scratch**
   so the committed records are what the fixed script actually produced.
5. **The conformance baseline was measured twice.** The first measurement ran
   against a clone that still carried the scratch backend from the guard
   observation. It returned 66.27 / 166 / 42 anyway, but a baseline taken from a
   dirty tree is not a baseline; it was re-taken from a pristine built clone and
   is reported from that. The intermediate observation is worth keeping for a
   different reason: run against an *unbuilt* clone the same command returns
   **63.25%**, because the `RequiresBuild` tag needs `output/`. A conformance
   figure quoted without saying whether the tree was built is not comparable to
   one that was.

---

## 6. Findings

**None new.** Everything this pass touched was already numbered: backlog **66**
is what it took, and it is resolved. **67 remains the next free number.**

The one thing worth recording is not a new finding but a correction to an
existing one, and it is written into 66's closure rather than given its own
number: **the entry undercounted the duplicate.** It described the map in the
build task as "a second place", and there were three — `link-mode.cjs`'s
`DEFAULTS` object held cytoscape's canvas, menu, ready selector and mouse button
as fallbacks for every backend. The third copy surfaced because the check was
derived from the manifests rather than from the entry's description.

---

## 7. Measurements

**The moved data, read back from the manifests after the move:**

| Backend | Declared |
| --- | --- |
| `cytoscape` | `Button=right Canvas=#cy Menu=#node-menu Ready=#cy canvas` |
| `forcegraph3d` | `Button=left Canvas=#fg Hover=150 Menu=#fg-actions Open=#fg-panel Ready=#fg canvas Settle=3000` |
| `plain` | *(none — declares no `SlotsBySetting.LinkMode`)* |

Identical to what `$LINK_PROBE` carried at `0d2c5df`, field for field.

**Acceptance, at head:** 9 assertions, 0 failed.

**Full build at head:** 180 tests passed / 0 failed, line coverage **81.36%**
(target 80), 33 scripts parse (9 as declared fragments), 5 assembled blocks
across 3 backends, 9 pages alive with the network blocked, 10 link-mode cases
resolved as configured. `PreTag` green: 9 assertions.

**The case inventory, base and head** (`verify-run.txt` check 4) — ten cases,
compared on the resolved href rather than the case id, so a case that ran and
resolved *differently* is as visible as one that stopped running:

```
  [ok  ] TestLinkMode is green at head - Link mode: 10 case(s) resolved as configured.
  [ok  ] and was green at base - Link mode: 10 case(s) resolved as configured.
  [ok  ] the case inventory did not move - 10 case(s) at base, 10 at head
```

**Byte identity, from fresh clones at the tag** (`sc3-fresh-clone.txt`):

```
  cytoscape     IDENTICAL  CA49B6D8C275DD2B
  forcegraph3d  IDENTICAL  3739940D9B7350AD
  plain         IDENTICAL  07A6FDFB959FA8D2
```

and in-run, against the base clone: 625,921 / 1,359,003 / 21,467 characters,
equal on both sides.

**Conformance** (`verify-run.txt` check 7), measured at both commits in the same
run, from clones, both built:

| | ScorePct | CasesRun | CasesDefined |
| --- | --- | --- | --- |
| base `0d2c5df` | 66.27% | 166 | 42 |
| head `e7bbfca` | 66.27% | 166 | 42 |

All three unchanged, as the prompt required. No assertion that passed at base
fails at head.

**A fourth backend, demonstrated** (`sc2-guard-both-ways.txt`, re-derived as
verify check 5). A scratch copy of `cytoscape` under a fourth directory name:
without a `LinkProbe` it fails the build **by name in two seconds, before a
browser starts**; with one, it runs all five link-mode cases — 15 total. One
data edit, no `.ps1`, no harness change.

---

## 8. Verification

`verify.ps1` re-derives everything from **fresh clones of the remote**, never
from this file. Seven checks:

1. every backend with link modes declares a usable `LinkProbe` and only those
   do — including that **no backend declared one at base**, so check 1 is
   measuring the change rather than the status quo;
2. the selectors are written down once, by absence at head **and presence at
   base** — the forbidden literals derived from the manifests, not listed;
3. all three backends byte-identical to base, plus `tests/LinkMode.Tests.ps1`
   (22 assertions) and `tests/LinkProbe.Tests.ps1` (9) run from the head clone;
4. `TestLinkMode` at both ends with the case inventories compared line for line;
5. the guard driven **both ways** with a scratch backend;
6. the machine-identity grep over the nine files the pass committed;
7. conformance at both ends, measured here.

`-FailCheck` adds five probes, each restored afterwards. All five went red for
the right reason (`verify-failcheck.txt`).

**P3 is the one that matters and is the reason not to pass `-SkipBrowser`.** The
other probes remove something; P3 *corrupts a value*, leaving the block present,
complete and wrong — `Canvas = '#not-a-canvas'`. The static suite stays green,
correctly, and the browser run goes red:

```
  [ok  ] P3: a wrong-but-well-formed selector passes every static check
         - 0 red in the suite - which is the point
  [ok  ] P3: and the browser run goes RED, so the declaration IS what drives the probe
         - "message": "Cannot read properties of null (reading 'boundingBox')",
```

Without it, every other check here could be green over a probe still driven by
something other than the manifest.

**The browser harness is `.gitignore`d, so a fresh clone cannot run checks 4 and
5.** As in 0049, `verify.ps1` lends the clone the pinned Playwright tree from the
checkout beside the harness, and only when the clone's own `Requirements.psd1`
pins the version that checkout has. `-SkipBrowser` records the skip as a failure
rather than passing quietly.

Artifacts: `verify-run.txt` (against the branch tip, before the tag),
`verify-failcheck.txt` (the probes), `sc1-red-demo.txt`,
`sc2-guard-both-ways.txt`, `sc3-fresh-clone.txt`.

---

## 9. Spot-checks 🔵

| SC | Where it is checked | Result | Red capability, demonstrated |
| --- | --- | --- | --- |
| **SC1** one place, by absence | `verify.ps1` check 2; `sc1-red-demo.txt` | neither grep finds anything at head; 4 `$LINK_PROBE` occurrences and 4 named literals at base | the same two greps at base |
| **SC2** the guard is real | `verify.ps1` check 5; `sc2-guard-both-ways.txt` | fails by name in 2s, before a browser | the same directory WITH a probe → 15 cases green |
| **SC3** output-invisible | `verify.ps1` check 3; `sc3-fresh-clone.txt` | all three backends identical from fresh clones at the tag | probe P4 (a `Slots` edit) → 629,398 vs 625,921 chars |
| **SC4** nothing machine-identifying | `verify.ps1` check 6, and run by hand over the 9 staged **harness** records | clean at both ends — after it went red against this pass's own records and `verify.ps1` was fixed (Deviation 4) | probe P5, the known-bad fixture form |
