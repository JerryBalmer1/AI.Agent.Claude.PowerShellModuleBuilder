# Pass 0052 — the floor learns to see, then the 3D view gets depth, menus, and its real default

Tier: **full**. Operator-prompted large item, two halves in one pass with a hard
internal order: the instrument is repaired before any feature that would blind
the old one is built.

Target repositories: `PSGraphRender` (writable) and
`AI.Agent.Claude.PowerShellModuleBuilder` (records only).

## 1. Prompt

```
# PASS 0052 — the floor learns to see, then the 3D view gets depth, menus, and its real default

Authored against PSGraphRender `main` = `dba1f4d` (v0.16.0 at HEAD) and
harness `main` = `a9b6d40` (frontier 0051; findings 67–70 filed, next
finding number 71). Operator-prompted large, two halves in one pass with
a hard internal order: **the instrument is repaired before any feature
that would blind the old one is built.** This is the 0046-before-0047
pattern applied inside a single pass, and the reason it is one pass, not
two: every feature in part 2 is unshippable as a default under the
current floor, and the operator wants the features.

## Signals

🔴 hard stop (report, never resolve) · 🟠 operator action · 🟢 agent task ·
🔵 evidence gate · ⛔ never, whole pass. Per PLAN-PROTOCOL.

**Tier:** full.

**Target repositories:** `PSGraphRender` (writable) and
`AI.Agent.Claude.PowerShellModuleBuilder` (records only). ⛔ No
`contract/` change. ⛔ No `src/*.ps1` edit. ⛔ `cytoscape` and `plain`
byte-identical to base; `index.psd1` untouched. ⛔ No conformance-
inventory change (`tests/browser/` is PSGraphRender's own instrument and
IS in scope; the harness repo's runner is not). ⛔ Item 3
(render-complete signal) stays OUT.

**Operator's words, so the target is unmistakable:** the current 3D
page has "nothing but a little extra" — no menus in the HTML, no grid
or environment giving the nodes depth and contrast, no controls for
zoom speed or focus-by-distance. The 2D report ships a full sidebar;
the 3D report ships a header. This pass closes that gap and promotes
the result to the default look.

## PART 1 — the floor instrument (finding 67 taken as work)

**The problem, from the 0051 record:** the canvas-growth floor is a
screenshot-byte ratio of drawn against empty. A painted background sits
in both numerator and denominator — vignette scored **1.05**, a
two-step gradient **1.14**, against 3.79 flat — so the only gate that
can tell a drawn 3D view from a blank one goes blind under exactly the
backgrounds the operator wants. `base.css` carried this warning as
prose; nothing ever made it a check (finding 67). The floor must become
an instrument that survives a painted background.

1. 🟢 **Red first:** demonstrate the blindness as the failing case —
   drawn-on-vignette vs empty-on-vignette under the CURRENT metric,
   reproducing the recorded ~1.05 non-separation with the shipped B1/B2
   variants. That observation is the red; read it, record it.
2. 🟢 **The repair:** replace ratio-against-empty with a
   difference-based measure — the drawn and empty screenshots ALREADY
   both exist in-run; compare them against each other (changed-pixel
   fraction above a per-channel threshold, or an equivalent smoke.cjs
   can honestly compute offline) so the background cancels instead of
   dominating. The declared form stays per-backend manifest data beside
   `Smoke`, replacing or superseding `CanvasGrowth` per the manifests'
   own conventions; the old key does not silently linger with a dead
   meaning.
3. 🟢 **Re-pin by measurement, both canvas backends:** cytoscape and
   forcegraph3d floors measured over multiple runs under the new
   metric, values and margins recorded in manifest comments the way
   3.50-over-2 and 2.25 were. `plain` declares no canvas and gains
   nothing.
4. 🔵 **The instrument proves itself both ways:** flat-background drawn
   vs empty separates; vignette-background drawn vs empty separates
   (the case the old metric failed); and the falsification probe stays
   the 0050/0051 form — corrupt, don't remove, so only the browser
   goes red.
5. 🟢 Finding 67's prose-only warning in `base.css` is either made
   obsolete by the new instrument (and updated to say what is now
   checked) or becomes a real check — it does not remain a sentence
   doing a gate's job.

**Sequencing gate:** 🔴 any part-2 environment, background, or default
work before part 1's gates are green.

## PART 2 — depth, menus, and the promoted default

### 2a. Environment and contrast

6. 🟢 **A grounded scene:** a `GridStyle` (or the settings file's own
   naming) environment family — at minimum `none`, a glowing
   floor-grid plane below the graph, and a space-grid/vignette depth
   environment — plus the existing `BackgroundStyle` values, all now
   legal as defaults because part 1's instrument can see through
   them. Depth cues sharpened: fog/falloff tuned so far nodes recede,
   near nodes pop; node materials gain the contrast the operator
   found missing (rim/edge definition against the environment rather
   than washed halos — the geometry-glow approach from 0051 stands,
   no second three.js copy; ⛔ a wholesale duplicate copy of three.js
   is a 🔴-report decision, not a vendoring choice).
7. 🟢 Links visible by default: width/opacity/particle defaults tuned
   so edges read against the new environment (values are theme data —
   one-line overturnable, per the established practice).

### 2b. The control panel — menus in the HTML

8. 🟢 An in-page, collapsible control panel in the 3D report,
   styled to the modern look (not the 2D sidebar transplanted), every
   control wired to the SAME declared settings that configure the
   defaults — the panel adjusts at runtime what `Config/` decides at
   render time. Controls, minimum set:
   - **View:** zoom speed (the existing setting, now user-adjustable
     live), zoom-to-fit, auto-rotate toggle.
   - **Depth/focus:** fog density / depth-falloff slider, and a
     focus mode — click-to-focus flies the camera to a node and its
     neighborhood (the library's own camera surface, derived in
     precondition); if true depth-of-field would require
     post-processing modules the vendoring gate rules out, the
     focus story is camera + fog and the limitation is recorded, not
     worked around with a network fetch.
   - **Display:** labels on/off, particles on/off, glow intensity.
   - **Filter:** kind checkboxes (the parity feature the 2D sidebar
     has and the operator noticed missing) — unchecked kinds and
     their orphaned links leave the scene.
   All panel text lives in `strings.psd1` (the 0048 per-set byte gate
   watches that file — new strings are expected additions, declared
   to it the way that gate demands). Panel presence and every
   control's effect asserted in the browser gates — value-reaches-
   controls for zoom speed, scene-state or pixel evidence for fog,
   filter, labels, particles; "asserted, not vibes" stands.

### 2c. The default moves

9. 🟢 The composed modern look — E1's treatments plus the environment
   and panel — becomes the **no-overlay default**. A0 re-renders as
   the new default (its byte-identity assertion is to the new
   no-overlay render); the previous flat look is preserved as a
   labeled catalog variant so reversal is a one-line ruling. Catalog
   regenerates: environment variants join as their own family or
   extend B, panel-visible screenshots throughout, captions updated.
   The live-links `threed/forcegraph3d.html` example regenerates
   under the new default.

## 0. Sync / 1. Preconditions

Sync per the established form (fetch both, ff-only, 🔴 divergence/dirt,
🔴 `PSModuleGraph`). Preconditions per the established form: frontier
three sources (🔴 0052 assigned / disagreement / below 0051);
PSGraphRender expected at `dba1f4d`, 🔴 if moved; `docs/constraints.md`
read first 🔵; design surface derived not recalled 🔵 — verbatim
excerpts at minimum of: `smoke.cjs`'s screenshot/ratio mechanism and
both existing screenshots' lifecycle; the `Smoke`/`LookProbe`/
`LinkProbe` blocks of both canvas backends; the 0051 measurement table
in `theme.psd1` (flat 3.79 / vignette 1.05 / gradient 1.14); the
vendored library's camera, controls, and event surface AS VENDORED
(the tree-shaken-bundle lesson: capability read from bytes, not docs);
`strings.psd1` and the 0048 gate's expected-additions mechanism; the
catalog `variants.psd1` form; the panel's nearest precedent in the 2D
set's sidebar scripts (for what, not how — the 3D panel is its own
design). 🔴 Any ambiguous. Sequencing: 🔴 implementation before
section-2 reds; 🔴 part 2 before part 1 green.

## Acceptance — red first (observed, messages read)

- **A (part 1):** the new floor separates drawn from empty on flat AND
  on vignette; the old metric's 1.05 non-separation is the recorded
  red. Floors re-pinned by measurement, both canvas backends.
- **B:** environment settings render their declared scenes,
  distinguished by TestLook pixels, on by default per task 9.
- **C:** the panel exists, collapses, and every listed control
  demonstrably changes the live scene or camera; kind filtering
  removes nodes and orphaned links; all UI text from `strings.psd1`.
  Red today: no panel exists.
- **D:** the no-overlay default is the composed look; A0 matches it
  byte-identically; the old look renders from its catalog variant.
- **E:** cytoscape/plain byte-identical to `dba1f4d`; all three link
  modes green on the new default; the four 0049 repairs and 0051's
  hover-state fix re-probed and holding; injection probes green on
  the new default and one high-glow variant; conformance
  66.27 / 166 / 42 at both ends against built trees.

## Tasks, spot-checks, constraints — the established form

Branch `pass-0052-floor-then-depth`; red acceptance first commit; part
1 (tasks 2–5 above) → gates → part 2 (6–9) → docs (`improvements.md`
logs this operator-prompted large per the log's form; 67's closure
recorded against the new instrument; HANDOFF; CHANGELOG) → release
expected **v0.17.0** (new setting types = the HANDOFF minor trigger;
🔴 LEDGER/tag disagreement; falsify before the release commit) →
harness records (`plans/0052-floor-then-depth/`; verify.ps1 per
decision 0004, `-FailCheck`, `-BaseRef`/`-HeadRef` twice-run,
SC4-hardened records; findings number from 71) → ff both mains per
0009/0010, ⛔ never force.

Spot-checks 🔵 each, red-capability stated: **SC1** the instrument
survives every shipped background (each environment variant's drawn vs
empty separates; red demo: the old ratio run on vignette). **SC2** the
panel is config-true (each control's default position matches
`Config/` values; red demo: a scratch settings flip the panel must
reflect). **SC3** catalog cannot drift (scratch add/remove, both
directions). **SC4** offline absolute — default, panel interactions,
and catalog page with network blocked, zero attempted requests.
**SC5** machine-identifying grep, hardened form, committed artifacts
and both verify records. **SC6** `none`-mode and `editor`-mode
documents keep their guarantees under the panel (no scheme
construction in `none`; the panel introduces no link path the mode
registry doesn't govern).

⛔ recap: contract; `src/*.ps1`; cytoscape/plain/index; item 3; second
three.js copy without a 🔴 report; hand-written catalog; network
anywhere. Size rules for anything discovered en route — the operator
prompted THIS large item, not its neighbors.

## Local handoff — the last act

The established form: both repos to `main`, ff-only, tags pruned,
status clean, 🔵 LOCAL STATE table. Divergence or dirt reported, never
resolved.
```

## 2. Preconditions

### Sync — the first act

| Check | Command | Result |
|---|---|---|
| Harness clean | `git status --porcelain` | empty ✅ |
| Harness HEAD | `git rev-parse HEAD` | `a9b6d404c17bc8fd1fb1437695850c0a272511a3` — the prompt's `a9b6d40` ✅ |
| Harness ff | `git fetch --prune --prune-tags --tags; git merge --ff-only origin/main` | `Already up to date.` ✅ |
| PSGraphRender clean | `git status --porcelain` | empty ✅ |
| PSGraphRender HEAD | `git rev-parse HEAD` | `dba1f4d145a28fc87351edbc48281cc7f0d7750b` — the prompt's `dba1f4d` ✅ |
| PSGraphRender ff | same | `Already up to date.` ✅ |
| v0.16.0 at HEAD | `git describe --tags --exact-match HEAD` | `v0.16.0` ✅ |
| 🔴 `PSModuleGraph` | `ls ../PSModuleGraph`; `cat *.code-workspace` | no such directory; neither workspace file registers it (pass 0045 deregistered it) ✅ |

**Stranded branches, reported not resolved.** Every `pass-*` and
`ledger-*` ref in both repositories was tested with `git merge-base
--is-ancestor <ref> main`. One is not an ancestor of its `main`:

    STRANDED: pass-0042-philosophy
    STRANDED: origin/pass-0042-philosophy

This is **not new and not a defect**: `LEDGER.md:439` records that "0042 is
consumed by decision 0016 and is not a frontier", and `decisions/0016-abandon-pass-0042.md`
is the ruling that abandoned it. PSGraphRender has no stranded branch.

### The frontier, from three sources

| Source | Command | Answer |
|---|---|---|
| LEDGER | `grep -n "Last landed" LEDGER.md` | `Last landed: **0051**` |
| Plans tree | `git ls-tree --name-only origin/main plans/` | `plans/0051-forcegraph3d-catalog` |
| Journal tree | `git ls-tree --name-only origin/main journal/` | `journal/0051-forcegraph3d-catalog.md` |

**All three agree at 0051.** The assigned number 0052 is free: no
`plans/0052-*`, no `journal/0052-*`, no LEDGER citation, and no
`pass-0052-*` branch in either repository before this pass created one.
Next free finding number is **71**, from the tail of the LEDGER backlog
(67–70 filed by pass 0051).

### `docs/constraints.md` — read first 🔵

Read in full before any other design file. What it rules on that bears on
this pass:

- **`plain` is trivial enough to prove less than it looks** (`0002-t1`).
  "Its triviality is what makes it a control." This is why `plain`
  declaring no canvas floor is correct rather than a gap.
- **Playwright was measured and nothing else was** (`0004-t4`). One
  engine, headless, pinned — which is what makes a pixel metric legible
  at all.
- **A sync check over documents that describe different repositories is a
  gate whose correct state is red** (`0010-t1`). The rule about gates
  that outlives the skills it was written for.

Nothing in the file rules against a difference-based floor; the floor's
own limitation was not in this file at all, it was in a comment.

### Design surface — derived, not recalled 🔵

Every item the prompt named, read out of the tree in this session:

| Surface | Where | What it says |
|---|---|---|
| screenshot/ratio mechanism | `tests/browser/smoke.cjs:48-75` | `screenshotBytes` returned `(await handle.screenshot()).length`; `measureEmpty` cached that **number** per `backend\|selector` |
| both screenshots' lifecycle | `smoke.cjs:87-97`, `62-75` | drawn: one context per case, closed in `finally`. empty: one context per `backend\|selector`, rendered by `PSGraphRender.build.ps1:355-360` from `@{nodes=@();links=@()}`, cached across cases |
| `Smoke` / `LookProbe` / `LinkProbe`, forcegraph3d | `TemplateSets/forcegraph3d/templateset.psd1:109-279` | `CanvasGrowth = @{ '#fg' = 2.25 }`; `LinkProbe.Button` must equal `settings.psd1`'s `NodeActionButton`; `LookProbe.Live = '#fg-live'` |
| `Smoke` / `LinkProbe`, cytoscape | `TemplateSets/cytoscape/templateset.psd1:107-144` | `CanvasGrowth = @{ '#cy' = 4 }`, measured at v0.5.0 as 53,971/4,413 = 12.2. **No `LookProbe`** |
| `plain` | `TemplateSets/plain/templateset.psd1:22-26` | `CanvasGrowth = @{}` — declares no canvas, gains nothing |
| the 0051 measurement table | `forcegraph3d/Config/theme.psd1:140-150` | verbatim: `flat 5,168 / 19,586 / 3.79`, `gradient 313,384 / 329,766 / 1.05`, `vignette` the same, and the two-step gradient at `122,355` / `1.14` |
| vendored camera / controls / events | `vendor/3d-force-graph.min.js`, by occurrence count | `cameraPosition` 12, `zoomToFit` 2, `controls` 31, `scene` 63, `renderer` 256, `nodeVisibility` 4, `linkVisibility` 4, `onNodeClick` 1, `onNodeHover` 1, `pauseAnimation` 2, `refresh` 8. Absent: `GridHelper` 0, `Line2` 0, `Float32BufferAttribute` 0 — the tree-shaking lesson holds |
| `strings.psd1` | `forcegraph3d/Config/strings.psd1` | 17 keys, all plain text, "Never markup: the page puts each of these in with textContent" |
| the 0048 gate | `tests/LinkMode.Tests.ps1:369-415` | **cytoscape only.** `$script:BaseSha = 'cd4857d'`; additions asserted BY NAME *and* BY VALUE; every base key pinned by value |
| catalog `variants.psd1` | `examples/threed/variants.psd1` | 19 rows, 5 families, 4 rules; `A0` has an EMPTY overlay and renders with no overlay directory at all (`Build-Examples.ps1:305-310`) |
| the 2D sidebar (for WHAT, not how) | `cytoscape/partials/sidebar.html`, `scripts/filters.js` | Order, Test order, Colour by, Search, **Kinds**, Filters, **Focus** (depth + direction), **View (zoom speed)**, buttons, Legend. Its labels are hardcoded English in markup — the 3D panel does not copy that |

**One precondition came back ambiguous, and it is reported rather than
resolved.** See Deviations 1: task 3 asks for cytoscape's floor to be
re-pinned "in manifest comments", and both the ⛔ list and acceptance E
require `cytoscape` byte-identical to `dba1f4d` —
`tests/ForceGraph3DLook.Tests.ps1:350` enforces that as a `git diff` over
the whole directory. The ⛔ was obeyed and the measurement taken anyway.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| OS | Microsoft Windows NT 10.0.26200.0 |
| node | v22.20.0 |
| Playwright | 1.49.1 (pinned in `Requirements.psd1`, installed, agree) |
| Branch | `pass-0052-floor-then-depth`, both repositories |
| HEAD at start | harness `a9b6d40`, PSGraphRender `dba1f4d` |

## 4. Acceptance test — red first

**Acceptance A's red is an observation, and it had to be.** There is no
assertion to write that fails first here: the defect is that the *existing*
gate reports a passing number for a page it cannot see. The thing to
demonstrate is the instrument going blind while the drawing stays the same,
so the red is a measurement of both metrics over the same four documents.

`observe-blindness.ps1` renders the 3D backend twice under each of two
backgrounds — once with `sample-module.json` and once with an empty payload —
and `observe-blindness.cjs` computes the shipped byte ratio and the proposed
changed-pixel fraction over the same pictures. Neither script touches the
shipped template set: each background gets a caller-owned copy, and the
mutation is read back and asserted before anything is rendered.

    pwsh -NoProfile -File observe-blindness.ps1 \
      -RenderRepo ../../../PSGraphRender -Out observe-blindness.txt

Captured in `observe-blindness.txt`:

| case | empty px | drawn px | **old ratio** | **new fraction** |
|---|---|---|---|---|
| forcegraph3d/flat | 5,168 | 22,305 | **4.316** | **0.0295** |
| forcegraph3d/vignette | 339,574 | 357,729 | **1.053** | **0.0258** |

**That is the red.** The same backend, the same payload, the same amount of
ink. Under `vignette` the shipped floor of **2.25** would have failed a page
that is drawing perfectly — 1.053 — while the proposed metric barely moves,
because the background is identical in both pictures and contributes no
changed pixels at all. The 1.05 reproduces pass 0051's recorded figure
exactly.

The empty capture is what moves: 5,168 bytes flat against 339,574 with a
vignette, a 66× difference in a picture of *nothing*. PNG cannot compress a
gradient, and the denominator is the whole defect.

## 4a. The operator stop, and the resume — 🔵

The pass was stopped by its operator part-way through part 2, on observing
uncommitted work. **The root cause is an authoring defect in the 0052
prompt, not in the work:** its task spine was compressed and lost the
explicit *"push after every task"* instruction that every prompt from 0047
through 0051 carried. The resume prompt repaired the tree state and made
the cadence a standing rule, landed in `PSGraphRender/docs/HANDOFF.md`.

### State verification — recorded verbatim, 🔵

Both repositories, before anything in the resume touched them.

    $ git -C AI.Agent.Claude.PowerShellModuleBuilder rev-parse --abbrev-ref HEAD
    pass-0052-floor-then-depth
    $ git -C AI.Agent.Claude.PowerShellModuleBuilder status
    On branch pass-0052-floor-then-depth
    nothing to commit, working tree clean
    $ git -C AI.Agent.Claude.PowerShellModuleBuilder log --oneline -5
    c1dceef Pass 0052: the red - the canvas floor goes blind under a painted background
    a9b6d40 Pass 0051: the verify run a later reader gets, against landed main
    4bc5899 Pass 0051: plan, verify.ps1, LEDGER and journal
    45af1e2 Pass 0050: the verify run a later reader gets, against landed main
    46aa750 Pass 0050: plan, verify.ps1, LEDGER and journal
    $ git -C AI.Agent.Claude.PowerShellModuleBuilder rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    fatal: no upstream configured for branch 'pass-0052-floor-then-depth'

    $ git -C PSGraphRender rev-parse --abbrev-ref HEAD
    pass-0052-floor-then-depth
    $ git -C PSGraphRender log --oneline -5
    efb6cee Pass 0052 part 1: the canvas floor becomes a difference, not a ratio
    dba1f4d Pass 0051: docs, and the version to v0.16.0
    2a81b11 Pass 0051: the variant catalogue, generated from its own table
    cb14c9f Pass 0051: the look and the machinery, and a floor re-measured
    d26b90a Pass 0051: the red acceptance, before any implementation
    $ git -C PSGraphRender rev-parse --abbrev-ref --symbolic-full-name '@{u}'
    fatal: no upstream configured for branch 'pass-0052-floor-then-depth'
    $ git -C PSGraphRender status
    On branch pass-0052-floor-then-depth
    Changes not staged for commit:
        modified:   PSGraphRender.build.ps1
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/Config/settings.psd1
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/Config/settings.schema.psd1
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/Config/strings.psd1
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/Config/theme.psd1
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/partials/graph.html
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/scripts/bootstrap.js
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/scripts/graph.js
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/scripts/labels.js
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/scripts/scene.js
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/scripts/shapes.js
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/styles/base.css
        modified:   src/PSGraphRender/TemplateSets/forcegraph3d/templateset.psd1
        modified:   tests/ForceGraph3DLook.Tests.ps1
        modified:   tests/browser/look.cjs
    Untracked files:
        claude-examples/
        src/PSGraphRender/TemplateSets/forcegraph3d/scripts/panel.js
        src/PSGraphRender/TemplateSets/forcegraph3d/styles/controls.css
    $ git -C PSGraphRender diff --stat | tail -1
     15 files changed, 1421 insertions(+), 69 deletions(-)

**Agrees with the operator's stop report in every particular.** Fifteen
modified files, two untracked source files and six untracked lab files is
the "~23 working-tree changes" it named; the part-1 commit is present; both
branches existed locally and neither was published. No foreign change, no
unexpected branch, no divergence. Nothing to report under 🔴.

### The 🟠 gate: the unsaved buffer

`claude-examples/1rackcontainerbase.html` is **zero bytes** on disk, mtime
`Sep 4 23:51` — the newest of the six lab files and the only empty one. Put
to the operator, who answered that it had been saved. Re-read: still zero
bytes, mtime unchanged.

So it is **not committed**, and that is a ruling rather than an oversight. An
empty file cannot be a design reference, and committing one under that label
would be exactly the guessed attribution step 2's 🔴 exists to forbid. It
stays untracked and untouched on disk; adding it later is one commit.

### The partition, and its reasoning — 🔵

The in-flight work was partitioned **from the diff content**, by reading each
file's diff and assigning it to the task it implements. Every hunk was
assignable; **nothing hit step 2's 🔴.** The whole of it is part 2 — part 1
had already landed as `efb6cee`.

| Commit | Task | Files |
|---|---|---|
| `bfc3a37` | pre-ruled step 1 | the five populated `claude-examples/` lab files |
| `c3ce97c` | **6 + 7** — part 2a | `theme.psd1`, `shapes.js`, `scene.js` whole; the `Grid*` hunks of `settings.schema.psd1`; the rim hunk of `graph.js`; the grid cases of `build.ps1`; the `Grid*` rows and the `BaseRef` bump of `ForceGraph3DLook.Tests.ps1` |
| `2ea178b` | **8** — part 2b | `graph.html`, `base.css`, `controls.css`, `panel.js`, `bootstrap.js`, `templateset.psd1`, `strings.psd1`, `settings.psd1`, `labels.js`, `look.cjs`; the `Controls`/`Focus` hunks of `settings.schema.psd1`; the panel machinery of `graph.js`; the panel cases of `build.ps1`; the Acceptance C block of `ForceGraph3DLook.Tests.ps1` |
| `ccd342c` | the resume's own rule | `docs/HANDOFF.md` |

**Why 6 and 7 share a commit rather than getting one each.** Task 7 is
connector and particle values in `theme.psd1`; task 6's environment work is
grid values in the same file. They are one file's data, and the prompt's own
section 2a. Splitting them would have produced two commits whose only
difference is which lines of one table moved.

**Why four files were split by hunk and the rest were not.** `scene.js` and
`graph.js` are woven together: `scene.js` renames `ringMaterial` to
`rimMaterial` (task 6) and `graph.js` holds the call site, so those must land
together; `graph.js`'s `publishLive` calls `panelState()` (task 8), which
lives in `panel.js`, so *those* must land together too. Where a seam existed
it was cut — the four files above carry their task-6 and task-8 additions in
separable regions. Where cutting would have produced a commit that does not
run, the file was kept whole and assigned to the task that needs it first.

**How the split was made, and how it was checked.** Filtered patches applied
to the *index* with `git apply --cached --recount`, so the working tree was
never edited and no work could be lost to the surgery. After both commits, a
byte-for-byte comparison of all seventeen files between `HEAD` and a
pre-partition snapshot:

    RESULT: the two commits reproduce the pre-partition tree exactly.

`git status` afterwards carries the zero-byte lab file and nothing else.

### Where the spine resumed, and which gates were re-run

Every gate whose inputs the uncommitted work touched was re-run, because the
work touched the defaults themselves: `Clean`, `Lint`, `LintJavaScript`,
`Build`, `LintDocument`, `Test`. One test failed, and it is the right one:

    [-] renders A0 identically to a no-overlay render of the shipped backend

That is **task 9 not yet done**, stated by the suite rather than by memory:
part 2 moved the default look and `A0` is still a picture of the old one. The
spine resumed at task 9.
