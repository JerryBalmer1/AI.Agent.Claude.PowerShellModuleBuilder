# Pass 0049 — PSGraphRender 3D template set (operator-complete item 2)

**Tier: full.** New executable behaviour: a third template set, new tests,
a vendored library. PLAN-PROTOCOL's tier rule decides this, not the document
count.

**Target:** PSGraphRender — a new `TemplateSets/forcegraph3d/` directory, a new
test file, the build script, the browser harness, the examples and the docs.
Harness: this plan record, `verify.ps1`, LEDGER, journal.

**Landed:** PSGraphRender `pass-0049-forcegraph3d` at `0d2c5df`, tagged
**`v0.15.0`** on that commit; harness branch of the same name. Base was
`5501755` (pass 0048's tip).

---

## 1. The prompt this pass executed, verbatim

<details>
<summary>PASS 0049 — PSGraphRender 3D template set (operator-complete item 2)</summary>

```
# PASS 0049 — PSGraphRender 3D template set (operator-complete item 2)

Authored from the trees at PSGraphRender `main` = `5501755` (post-0048, no tag
at HEAD, newest tag v0.14.0) and harness `main` = `4666bbe` (frontier 0048,
next free backlog number 66). Every path, convention, and citation below was
read from those commits, not recalled.

## Signals

🔴 hard stop (report, never resolve) · 🟠 operator action · 🟢 agent task ·
🔵 evidence gate · ⛔ never, whole pass. Per PLAN-PROTOCOL.

**Tier:** full — new executable behaviour: a third template set, new tests,
vendored libraries. PLAN-PROTOCOL's tier rule decides this ("changes
executable behaviour"), not the document count.

**Target repositories:** `PSGraphRender` (writable) and
`AI.Agent.Claude.PowerShellModuleBuilder` (plan record, LEDGER, journal
only). ⛔ `contract/viewmodel.schema.json` does not change this pass — the
schema at 1.1.0 carries node `id`/`name`/`kind`/`path`/`startLine`/
`isExported`/`metrics` and `links[]` `source`/`target`/`resolution`, no
coordinate, position, or layout field, and that is expected to be sufficient
(see the 🔵 gate in task 2). ⛔ No `src/*.ps1` edit: `plain`'s own manifest
states the bar — "adding a backend is a directory: no .ps1 under src/ was
edited to make this render. If one ever has to be, that is a bug in the
design and belongs in docs/improvements.md rather than in a workaround" —
and `Resolve-RenderTemplateSetPath` confirms discovery is enumerating
directories under `TemplateSets/` containing a `templateset.psd1`, default
named by `TemplateSets/index.psd1`. A needed `.ps1` edit is a 🔴, not a
workaround.

**Purpose.** Operator-complete item 2: a `3d-force-graph` (three.js) based
template set consuming the same viewmodel, per-node click navigation via the
0047 link modes, delivered as a shipped set the way `plain` was — a
directory. The existing `cytoscape` set stays the default
(`TemplateSets/index.psd1` untouched) and `plain` stays untouched.

**Naming.** The set directory is `forcegraph3d`, lowercase single word like
its siblings. If precondition 4 surfaces a naming convention that forbids it,
follow the convention and record the deviation.

## 0. Sync

🟢 Fetch both workspace repos (`--all --tags --prune`), ff-only updates.
🔵 Report. 🔴 Divergence or dirt. 🔴 `PSModuleGraph` present in workspace
folders or the session's directory list.

## 1. Preconditions

1. **Frontier, three sources:** 🔴 any source shows 0049 assigned. 🔴 Sources
   disagree. 🔴 Frontier below 0048. Record the three values 🔵.
2. 🔴 Either repo not on `main`, not clean, or not ff-synced. PSGraphRender
   expected at `5501755`; 🔴 if `main` has moved — this prompt's citations
   were read from that tree.
3. 🔵 **Constraints read first:** `docs/constraints.md` in full; record "no
   conflict" or the colliding entry. Noted at authoring: the validation
   constraint ("`New-RenderDocument` is the only thing that checks a payload
   against the contract") means the new set validates nothing itself — 🔴 if
   any task drifts toward per-backend validation.
4. 🔵 **Design surface derived, not recalled** — read and record verbatim
   excerpts, at minimum:
   - `TemplateSets/plain/templateset.psd1` in full — the minimal-backend
     form this pass imitates;
   - `TemplateSets/cytoscape/templateset.psd1`: the `SlotsBySetting.LinkMode`
     structure (editor/hrefTemplate/none), `FragmentSlots` (`ArrayElements`),
     and the `Smoke` block with its `CanvasGrowth` commentary (ratio 4
     required, 12.2 measured at v0.5.0);
   - `scripts/link/common.js` and `scripts/link/href.js`: the token map —
     `{relativePath}` (segment-encoded, real slashes), `{path}`, `{id}`,
     `{label}` (from `name`), `{line}` (from `startLine`, default 1) — and
     the two-encoder rule (`encodePathSegments` vs `encodeURIComponent`);
   - `Config/settings.psd1` + `settings.schema.psd1`: how `LinkMode` and
     `LinkHrefTemplate` are declared and typed;
   - `vendor/vendor.psd1` and `docs/vendoring.md`: the provenance form
     (Name/Package/Version/Url/Integrity sha384/License), the update
     procedure, `tests/Vendor.Tests.ps1`'s per-file hash verification, and
     the network-blocked rationale;
   - `tests/browser/smoke.cjs`: job form, pinned viewport 1280×900 DSF 1,
     500 ms settle, the empty-render-in-same-run ratio mechanism;
   - `tests/Backend.Tests.ps1` ('A backend is a directory') and
     `tests/Module.Quality.Tests.ps1` (walks `Slots` **and**
     `SlotsBySetting` since 0047): what every-set gates will demand of the
     new directory;
   - `examples/Build-Examples.ps1` (overlay mechanism, `-Only` ValidateSet)
     and `examples/README.md` (row form: html · input · png · regen
     command).
   🔴 Any of these cannot be established unambiguously.
5. **Sequencing gates:** 🔴 any template-set authoring before task 2's 🔵
   vendoring gate passes. 🔴 any implementation before section 2's reds are
   observed (red here is mostly trivial — the set is absent — so the
   *meaningful* red is B's, observed against a scaffold once one exists;
   record what each red actually demonstrates rather than claiming more).

## 2. Acceptance — red first

🟢 Commit acceptance tests before implementation, in the repository's own
test form (a `ForceGraph.Tests.ps1` sibling to `LinkMode.Tests.ps1`, plus a
browser-gate job the way `tests/browser/` runs them):

- **A — the set renders and comes alive:** `New-RenderDocument -TemplateSet
  forcegraph3d` over `examples/input/ecosystem-viewmodel.json` produces a
  self-contained document that passes its own declared `Smoke` block in the
  browser gate, network blocked, including a `CanvasGrowth` floor against
  its own empty render. Red today: no such directory.
- **B — link modes, all three, token parity:** `hrefTemplate` resolves the
  same five tokens as cytoscape's `href.js`, same encoding split
  (`{relativePath}` segment-encoded with real slashes — the exact defect
  0047's browser gate caught), per-node click navigation; `none` ships a
  document with no scheme construction in it (assembly-time absence, the
  0047 ruling — `SlotsBySetting` with empty lists clearing action slots);
  `editor` produces working `vscode://file/` links from `meta.rootPath` +
  `path` + `startLine`. Red against the scaffold before link wiring.
- **C — the other two backends are untouched:** cytoscape and plain renders
  of the same viewmodel byte-identical to base `5501755` (modulo declared
  varying fields), and the seven existing examples regenerate comparable.
  Green before and green after; red-capability via a scratch mutation, the
  established pattern.

🔵 Record the conformance baseline at base: runner score / cases-run /
CasesDefined (expected 66.27% / 166 / 42 from the 0048 record — verify,
don't assume).

## 3. Tasks (serial unless marked; push after every task)

1. 🟢 Branch `pass-0049-forcegraph3d`; first commit the red acceptance
   tests.
2. 🟢 **Vendor first, and gate on what the artifact says.** Fetch the
   `3d-force-graph` distribution bundle (and whatever it requires) into
   `TemplateSets/forcegraph3d/vendor/` with a `vendor.psd1` in the recorded
   form — exact URL, pinned version, sha384 computed by the documented
   procedure, license. **Inspect, don't assume:** whether the bundle
   carries three.js inside it or three.js must be vendored beside it is
   established the way `cytoscape-dagre`'s bundled dagre was — "verified by
   inspection of the built bundle, not assumed from the package name" —
   and recorded in the manifest comment either way.
   🔵 **Requirement-direction gate, immediately after vendoring, before any
   template-set authoring:** establish from the vendored artifact whether
   its default force-directed mode REQUIRES positional input or COMPUTES
   positions from nodes+links. The d3-force lineage can *consume* fixed
   coordinates (fx/fy/fz pinning) — capability is not demand; the gate
   tests the requirement direction only. Record the evidence verbatim.
   🔴 If the vendored version's default mode demands positional input the
   viewmodel does not carry: STOP — that is the branch where the
   improvements-log open decision ("should a backend declare required
   contract fields?") fires, and it is the operator's to reopen, not this
   pass's. Otherwise the open decision stays standing and untouched.
3. 🟢 **The set, imitating `plain`'s economy:** `layout.html`, minimal
   partials/styles, `templateset.psd1` declaring `Layout`, `Slots`
   (VENDOR slot inlining the vendored file(s) — the page is one file that
   needs nothing), `SlotsBySetting.LinkMode` in the cytoscape structure
   with this set's own `scripts/link/` files, `FragmentSlots` for any
   array-literal slots, and its own `Config/` (`settings.psd1` declaring
   `LinkMode = 'editor'` default and `LinkHrefTemplate = ''` empty — "a
   plausible-looking default is one somebody ships by accident" —
   `settings.schema.psd1`, `theme.psd1` as the schema demands,
   `strings.psd1` if the set carries UI text — noting the 0048 gate now
   byte-compares STRINGS per-set). Nodes+links handed to the library via
   its data-loading surface; positions computed by its force simulation.
   Scope discipline: this is the *minimal alive* 3D view — graph, per-node
   click action, whatever the Smoke block needs. Sidebar/filters/focus
   parity with cytoscape is NOT in scope; anything tempting gets the size
   rules (small rides along, medium/large logged, not taken).
4. 🟢 **Smoke block earned, not copied:** declare `Text`/`Elements`/
   `Present`/`CanvasGrowth` for what THIS set actually draws. Before
   trusting the ratio, 🔵 probe that the empty render screenshots non-null
   in the harness's headless Chromium (a WebGL canvas that cannot
   initialize headlessly is a finding to report, not to sleep past).
   Measure the drawn/empty ratio in-run and record it in the manifest
   comment the way cytoscape recorded 12.2; set the required floor with the
   same margin philosophy ("four is not a marginal call").
5. 🟢 Green the acceptance tests. 🔵 All results verbatim, including the
   browser-gate run for all three link modes on this set.
6. 🟢 **Examples earn the feature** (parallel with 7): add the
   `forcegraph3d` example — committed html + png + input + regen command,
   README row, `Build-Examples.ps1` `-Only` ValidateSet extended.
   `hrefTemplate` mode with the live
   `https://github.com/JerryBalmer1/PSGraphRender/blob/main/{relativePath}#L{line}`
   template mirrors the forge example's proof. Public-artifact rule: no
   machine paths; the machine-identifying grep applies to everything
   committed.
7. 🟢 Docs (parallel with 6): `docs/improvements.md` item-2 large entry
   closed with this pass's reference, superseded text struck not deleted;
   `docs/vendoring.md` table gains the new file(s); `docs/HANDOFF.md`
   state; `CHANGELOG.md` — collecting the existing `[Unreleased]` (0048's
   entry) into this release per the file's own form.
8. 🟢 **Release:** expected **v0.15.0** (new capability, minor) unless
   `git tag` at run time says otherwise; 🔴 if LEDGER's version line and
   the tag list disagree. Annotated tag; verify falsification before the
   release commit so the tag names the pass tip (the 0047-proven
   ordering, 🔵 noted).
9. 🟢 Harness records: `plans/0049-forcegraph3d/plan.md` (prompt verbatim,
   the requirement-direction evidence, rulings restated: item 3 OUT,
   contract ⛔, per-set findings), `verify.ps1` (decision 0004;
   `-FailCheck`; scratch-only writes; `-BaseRef`/`-HeadRef` named, the
   twice-run pattern) — checks: acceptance A/B/C, examples regenerate,
   vendor hashes verify, conformance head ≥ base 🔵 both ends recorded,
   machine-identifying grep clean; LEDGER (counter 0049; version line to
   the tag; backlog 66 is next free — number any new findings from there);
   journal (six fields, Capability never benefit).
10. 🟢 Fast-forward both mains per 0009/0010. ⛔ Never force.

## 4. Spot-checks (🔵 each; red-capability stated per METHOD)

- **SC1 — a backend is a directory, still:** `git diff --stat` base..head
  shows zero changes under `src/PSGraphRender/**/*.ps1` and none to
  `TemplateSets/index.psd1`, `cytoscape/`, or `plain/`. Red demo: a
  scratch one-line `.ps1` edit caught by the same diff.
- **SC2 — nothing machine-identifying:** the established grep
  (drive-absolute paths; `vscode://` carrying a real path) across
  everything committed, vendored files exempted as third-party bytes.
  Red demo: the known-bad fixture form.
- **SC3 — injection surface, same bar as 0047:** a template with
  quotes/angle-brackets and a node label containing HTML render without
  script execution in the 3D document; resolved URLs attribute-encoded.
  Red demo: encoding disabled in a scratch render.
- **SC4 — `none` means none, in this set too:** the `none`-mode 3D
  document carries no scheme construction and no link action; the check
  that proves it goes red against the `editor`-mode document.
- **SC5 — offline is real:** the browser gate's attempted-request list is
  empty for the 3D cases — the vendored bundle actually satisfied the
  page. Red demo: a scratch render with the VENDOR slot emptied.

## 5. Constraints

⛔ No `contract/` change (task 2's gate is the only door, and it opens onto
a stop). ⛔ **Item 3 is OUT** — the render-complete signal is not taken,
not started, not "prepared for": the smoke gate decides readiness
declaratively per backend and consults no library completion signal, so
nothing in this pass needs it; if implementation appears to need it, that
is a 🔴 to report with the evidence, not a license. ⛔ `cytoscape` remains
the default set; `index.psd1` untouched. ⛔ No changes to
PSGraphRenderToHtml, producers, fixtures, or harness instruments. ⛔ No
per-backend payload validation (constraints ruling). Improvements-log size
rules for anything discovered en route. Public-artifact rule for every
committed artifact.

## 6. Local handoff — the last act

🟢 Both repos: checkout `main`, `pull --ff-only`, `fetch --tags --prune`,
status clean; 🔵 LOCAL STATE table (repo | branch | HEAD | clean).
Divergence or dirt reported, never resolved.
```

</details>

---

## 2. Preconditions, as measured

**Sync.** Both repositories clean, on `main`, ff-synced with origin.
PSGraphRender at `5501755` exactly as the prompt states; harness at `4666bbe`.

**`PSModuleGraph` — the 🔴 did not fire, and the reason is worth stating.** It
exists on disk at `<workspace parent>/scratch/PSModuleGraph`, which is neither a
workspace folder nor a session working directory. Both `.code-workspace` files
were read: the harness registers `.`, `../PSAzureDevOpsGraph`, `../PSGraphRender`,
`../PSGraphRenderToHtml`, `../PSTerraformGraph`; the PSGraphRender workspace
registers `.` and `../PSGraphRender`. Neither names it. This is the exposure
harness backlog 65 describes as standing — the assertion cannot see a clone
inside a folder already registered — and it did not fire here because the clone
is outside the harness directory entirely.

**Frontier, three sources, all agreeing that 0049 is free:**

| source | value |
|---|---|
| `LEDGER.md` | *"Last landed: **0048**"* |
| `plans/` | newest directory `0048-strings-byte-gate` |
| `journal/` | newest entry `0048-strings-byte-gate.md` |

Highest backlog number in use across LEDGER and journal: **65**. Next free: 66.

**Constraints (`docs/constraints.md`), read in full — no conflict.** Four
entries govern this pass rather than colliding with it:

- **`0003-t4`, validation happens in one place.** *"`New-RenderDocument` is the
  only thing that checks a payload against the contract… the alternative is
  every backend validating separately, which is how a backend ends up with its
  own idea of the contract."* The new backend validates nothing. No task drifted
  toward it.
- **`0002-t1`, `plain` is trivial enough to prove less than it looks.** This is
  the entry the whole pass answers, and it also warns against the shape of the
  answer: *"a second elaborate backend would prove the seam and would also hide
  a seam defect behind its own machinery."* Taken as scope discipline — see
  section 5.
- **`0004-t3`, closed rather than accepted.** *"Vendoring at v0.5.0 removed
  every request the page makes. A backend that fetches something re-raises it,
  and that is the right time."* The 3D backend vendors and fetches nothing.
- **`0005-t4`, a vendored file names a resource that is not vendored.** The
  accepted `sourceMappingURL` in `cytoscape-dagre.min.js`. Checked against the
  new bundle: it has none, so this backend does not inherit the trade.

**Design surface.** Every file the prompt names was read at `5501755` before any
authoring: both existing `templateset.psd1` files, `scripts/link/common.js` and
`href.js`, both `Config/` trees, `vendor/vendor.psd1`, `docs/vendoring.md`,
`tests/browser/smoke.cjs`, `tests/Backend.Tests.ps1`,
`tests/Module.Quality.Tests.ps1`, `tests/Vendor.Tests.ps1`,
`tests/TestHelpers.ps1`, `tests/LinkMode.Tests.ps1`,
`tests/BackendContract.Tests.ps1`, `tests/NoProducerKinds.Tests.ps1`,
`examples/Build-Examples.ps1`, `examples/README.md`, `tools/shoot.cjs`,
`PSGraphRender.build.ps1`, `Public/New-RenderDocument.ps1`,
`Public/Get-RenderTemplateSet.ps1`, `Private/Config/Resolve-RenderTemplateSetPath.ps1`
and `contract/viewmodel.schema.json`.

**One correction to the prompt's own citation.** The prompt writes the paths as
`TemplateSets/…`, `scripts/link/…`, `vendor/vendor.psd1`. They are relative to
`src/PSGraphRender/`, not to the repository root. Nothing turns on it; recorded
because a later reader following those paths from the root finds nothing.

**Conformance baseline at base, measured rather than assumed:**
**66.27%** over **166** cases, `CasesDefined` **42** — the 0048 record
reproduced exactly.

---

## 3. The requirement-direction gate — the load-bearing evidence

The prompt's 🔴 is: *if the vendored version's default mode demands positional
input the viewmodel does not carry, STOP.* That branch opens onto an operator
decision, so the gate had to be answered from the artifact and not from the
phrase "force-directed".

**Vendored:** `3d-force-graph` **1.80.0**, from
`https://cdn.jsdelivr.net/npm/3d-force-graph@1.80.0/dist/3d-force-graph.min.js`,
1,313,897 bytes, `sha384-Y7bC2PBKu8ujxtvo5+Z61OeGdSVRzFsYWBK4i5dnL/U6aFDTodk61qOUkTfInaxS`,
MIT. Two independent fetches of that URL produced byte-identical files.

**Static evidence, verbatim from the vendored bytes.** The simulation's node
initialisation, minified:

```
{if((t=e[n]).index=n,null!=t.fx&&(t.x=t.fx),null!=t.fy&&(t.y=t.fy),null!=t.fz&&(t.z=t.fz),
isNaN(t.x)||i>1&&isNaN(t.y)||i>2&&isNaN(t.z)){var s=10*(i>2?Math.cbrt(.5+n):i>1?Math.sqrt(.5+n):n),
a=n*ph,o=n*fh;1===i?t.x=s:2===i?(t.x=s*Math.cos(a),t.y=s*Math.sin(a)):(t.x=s*Math.sin(a)*Math.cos(o),t.y=s*Math…
```

Read plainly: `fx`/`fy`/`fz` are **consulted** when a node states one, and when
`x`/`y`/`z` are absent the code **assigns** them from a spherical phyllotaxis
lattice. That is the direction the gate asks about. Consuming coordinates is a
capability the library offers; it is not an input it demands.

**Live evidence, in the harness's own headless Chromium.** Twelve nodes carrying
only `id` and `name` — no `x`, `y`, `z`, `fx`, `fy` or `fz` — were handed to
`ForceGraph3D()` on a standalone page with the library inlined and the network
blocked. The same node objects came back with distinct three-dimensional
coordinates:

```
n0  x=-53.05  y=-52.03  z= 43.49
n1  x= -6.00  y=-54.09  z= 61.51
n2  x= 35.25  y=-25.74  z= 52.64
n3  x= 45.21  y= 10.93  z= 22.44
```

**Gate result: COMPUTES. The 🔴 did not fire, no contract change was needed, and
the improvements-log open decision stays standing and untouched** — annotated
with the worked example against it rather than resolved.

**And the same probe answered task 4's other 🔵 in the same run.** WebGL
initialises headlessly — `WebGL 2.0 (OpenGL ES 3.0 Chromium) | WebKit WebGL`,
one `<canvas>` in the container, a non-null screenshot of 14,299 bytes drawn
against 4,804 empty. Nothing here had to be slept past.

**Whether three.js needed vendoring beside it** was answered the way
`cytoscape-dagre`'s bundled dagre was — by reading the built bundle. It is
inside: `__THREE__`, the *"Multiple instances of Three.js being imported"*
warning that exists only in three.js's own source, `WebGLRenderer`,
`PerspectiveCamera`, `BufferGeometry`, `MeshLambertMaterial`, the
`meshphong_vert` shader chunk, and a `mrdoob/three.js` issue reference. Zero
`require(` calls, zero imports, and **no `sourceMappingURL`**.

---

## 4. What the reds actually demonstrated

The prompt is explicit that the first red is mostly trivial and asks for what
each red *demonstrates* rather than a claim.

**First red, before anything existed: 21 red, 6 green.** Acceptances A and B
entirely red — and what that demonstrates is only *the directory is absent*,
which is worth almost nothing. Acceptance C entirely green, which is the state
it has to be in before and after.

**The first red found a defect in the acceptance itself, which is the part worth
recording.** One assertion went **green** against a set that did not exist:

```powershell
@($manifest.Smoke.CanvasGrowth.Keys).Count | Should-BeGreaterThan 0
```

`Import-PowerShellDataFile` failed, `$manifest` was `$null`, property access on
`$null` yields `$null`, `@($null)` is a one-element array, and `1 > 0` passed. A
test that cannot go red for the thing it guards is not evidence. It now asserts
the manifest is there first, and the red became 21/6.

**The prompt's sequencing gate was not followed as written, and this is the
deviation to report.** It asks for B's *meaningful* red against a scaffold —
a set that draws but has no link wiring. No scaffold stage existed: the set was
authored in one piece and went from absent-red to green. The meaningful reds
were established afterwards, by scratch mutation against the working set, which
is the repository's own stated method (*break the thing the gate guards, run it,
read the message, restore*) but is **evidence collected after the fact rather
than before**. Six probes, each restored, each red for the right reason and with
the message read rather than the colour:

| probe | mutation | what went red |
|---|---|---|
| P1 | `{id}` removed from this backend's token table | *token parity*, and **only** that one assertion of 27 |
| P2 | `none` mode assembles `editor.js` after all | the three `none` assertions |
| P3 | one line appended to cytoscape's `bootstrap.js` | *renders cytoscape byte-identically to the base* |
| P4 | the `VENDOR` slot emptied | the browser gate: *page did not reach its declared ready state: expected 6, found 0* |
| P5 | `graphData` handed an empty graph | *`#fg` drew 5168 bytes of PNG against 5168 … ratio 1.00, and 2 is required. The view is blank.* |
| P6 | token values handed over unencoded | *href carries an unencoded character: `https://example.invalid/src/a"b<c>.ps1?l="><script>alert(1)</script>`* |
| P7 | an external `<script src>` added to the layout | both offline checks: the gate named the URL it tried, and the document-side assertion went red |
| P8 | one line appended to a `.ps1` under `src/` | *edits no .ps1 under src to add a backend* |

**P5 is the one that earns the `CanvasGrowth` block.** The page ran, the counts
were right, `#fg canvas` was present, every DOM assertion passed — and nothing
was drawn. No other check in the repository can tell that from a working page.

---

## 5. Rulings restated

**⛔ Item 3 is OUT, and nothing needed it.** The render-complete signal was not
taken, started, or prepared for. The smoke gate decides readiness declaratively
from each backend's own `Smoke` block and consults no library completion signal.
Where a completion signal *was* touched — `onEngineStop`, to fit the view — it is
this backend's own use of its own library inside its own script, not a readiness
signal offered to anything above it, and the gate neither knows nor asks about
it.

**⛔ No contract change.** `contract/` is byte-identical between base and head;
`verify.ps1` check 1 asserts it.

**⛔ `cytoscape` remains the default.** `index.psd1` untouched, asserted twice —
in the suite and in `verify.ps1`.

**⛔ No per-backend validation.** The new backend contains no payload check.

**⛔ No `src/*.ps1` edit.** The diff over `src/PSGraphRender/**/*.ps1` between
base and head is empty, asserted in the suite and in `verify.ps1`, with P8 as
its red demonstration.

**Scope discipline held, and `0002-t1` is why.** No sidebar, no filters, no
focus mode. The constraint's own argument is that a second *elaborate* backend
hides a seam defect behind its own machinery, so the set carries only what the
seam has to survive: its own `vendor/`, its own four Config files, its own
`Smoke` block, all three link modes with token parity, and a per-item click
action.

---

## 6. Findings

**Four defects in the new backend, all found by running the page and looking at
it, none visible in the source.** They are recorded in the code where each bit:

1. **The library's tooltip inserts a string as markup.** The bundle branches
   `"string"==typeof content ? tooltipEl.html(content) : … append(content)`, and
   `.html()` sets `innerHTML`. A producer's label is free text. It goes in as an
   **element** whose `textContent` carries it — safe by construction rather than
   by an escaper this repository would have to get right.
2. **The layout stops on a fifteen-second timer by default**, longer than any
   gate here waits and longer than a reader watches. "Fit the view when the
   layout settles" therefore never fitted anything. Bounded in ticks now
   (`WarmupTicks`, `CooldownTicks`), which also makes the same payload settle
   the same way on any machine.
3. **The canvas was opened at 1280×900 inside an 859px-tall box** and never
   corrected, so the bottom of every graph was outside its own element and the
   fit was computed against the wrong aspect. Found by reading `canvas.width`
   off the page. Sized from the container explicitly, and on resize.
4. **`#fg-notice` set `display`, which beats the user agent's
   `[hidden]{display:none}`.** A hidden `inset: 0` element became an invisible
   sheet across the viewport that swallowed every click on the canvas beneath
   it. Eighty-one grid clicks hit nothing, and a hunt through the camera code
   found nothing, before `elementFromPoint` named the notice. The same
   mis-declaration on the status bar had shown zero counts before anything
   filled them — the same cause, two failures that look nothing alike.

**One finding logged as work, medium, in `docs/improvements.md`.** The link
probe names each backend's selectors in `PSGraphRender.build.ps1`. That is a
second place a backend's shape is written down, which is exactly the defect the
`Smoke` block was invented to remove from `tests/browser/smoke.cjs`. It belongs
in each `templateset.psd1` beside `Smoke`, and it is not there because putting
it there means editing `cytoscape/templateset.psd1` — which this pass's
no-regression control forbids. The task throws by name for a backend it cannot
reach, so a fourth backend cannot arrive with its modes silently unchecked; that
is a guard against forgetting, not the fix.

**One thing said plainly in `docs/improvements.md` rather than dressed up.** The
prompt asks for the item-2 entry to be closed *with superseded text struck, not
deleted*. **There was no entry.** The work was large — a directory, new tests, a
vendored dependency — and that file's own size rules say a large item is logged
and stopped on. It was held on the operator's list, outside the file, from
before v0.14.0 until now. The entry is written at its closure and says so;
inventing struck text for a claim nobody made would have been a nicer-looking
record and a false one.

**A measurement that fills a recorded gap.** Thread `0006-t2` says the
`CanvasGrowth` ratio *"has never met a legitimately sparse payload"* — 4×
required against measured values of 12.2 and 13.6, with nothing in between.
This backend's thinnest observed case is **3.50**, from a backend that draws
sparsely by nature rather than from a payload that happens to be thin.

---

## 7. Measurements

**Canvas growth**, at 1280×900 DSF 1, against this backend's own empty render
(5,168 bytes) in the same run, at two moments — because a force layout is still
moving when a check first looks at it:

| fixture | while settling | settled |
|---|---|---|
| `ambiguous` (6 nodes / 6 links) | 4.51 | 6.49 |
| `sample-module` (9 / 5) | 5.20 | 3.50 |
| `infrastructure` (17 / 20) | 6.26 | 4.77 |

Floor set to **2**: 1.75× below the thinnest thing observed, where the reference
backend's 4 sits 1.84× below its own thinnest of 7.34. The same daylight, not
the same digit.

**One measurement that changed the layout rather than the number.** With the
status bar floating over a full-bleed canvas, the same payload rated **3.07**
and the empty render was **9,252** bytes — the chrome was inside both
screenshots. Moved above the canvas, the empty render fell to **5,168** and the
same payload rated **3.95**. Chrome over a canvas does not make a blank page
look drawn; it makes a drawn page look less drawn, and the floor stops
discriminating long before it stops passing.

**Gate runs at head:** 171 tests passed, 0 failed; 81.36% line coverage; 33
scripts parse, 9 of them as declared fragments; 5 assembled blocks parse across
3 backends; 9 pages came alive with the network blocked; 10 link-mode cases
resolved as configured across the two backends that have modes.

**Conformance:** 66.27% over 166 cases, `CasesDefined` 42 — **at base and at
head**, measured inside `verify.ps1` at both commits rather than quoted. A fifth
consecutive reproduction of the figure backlog 63's pin still disagrees with.

---

## 8. Verification

`verify.ps1` re-derives everything from **fresh clones of the remote**, never
from this file. Eight checks:

1. a backend is a directory — the set exists, three backends are discovered, no
   `.ps1` moved, `contract/` did not move, `index.psd1`/`cytoscape/`/`plain/`
   are untouched, cytoscape is still the default;
2. acceptance A/B/C run from the head clone, plus a guard that the four
   load-bearing assertions are actually present in it;
3. all three link modes in the document a caller receives, with token parity
   derived from the reference backend's own resolver;
4. vendoring — one file, hash, URL/version agreement, and the three.js claim
   checked against the bytes rather than against the note;
5. every example regenerates and none of the seven that existed moves;
6. the machine-identity grep over everything the pass committed, with a guard
   that it read something;
7. the two browser gates;
8. conformance at both ends, measured here.

`-FailCheck` adds six probes, each restored afterwards. All six went red for the
right reason; the messages are in `verify-failcheck.txt`.

**The browser harness is `.gitignore`d, so a fresh clone cannot run checks 7a
and 7b.** The build task fails by name rather than skipping, which is right, and
in a verifier it reads as a defect in the pass rather than a missing install. So
`verify.ps1` lends the clone the pinned Playwright tree from the checkout beside
the harness, and **only** when the clone's own `Requirements.psd1` pins the
version that checkout has — a harness at a different version would be measuring
something other than what the pass shipped. `-SkipBrowser` exists and records
the skip as a failure rather than passing quietly.

Artifacts: `verify-run.txt` (against the branch tip), `verify-failcheck.txt`
(the probes), `verify-landed-main.txt` (against landed `main`).
