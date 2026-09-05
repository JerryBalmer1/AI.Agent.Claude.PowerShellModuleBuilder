---
pass: 0052
title: The floor learns to see, then the 3D view gets depth, menus and its real default
date: 2026-09-05
artifacts:
  - plans/0052-floor-then-depth/plan.md
  - plans/0052-floor-then-depth/verify.ps1
  - plans/0052-floor-then-depth/verify-run.txt
  - plans/0052-floor-then-depth/verify-failcheck.txt
  - plans/0052-floor-then-depth/verify-landed-main.txt
  - plans/0052-floor-then-depth/observe-blindness.ps1
  - plans/0052-floor-then-depth/observe-blindness.cjs
  - plans/0052-floor-then-depth/observe-blindness.txt
  - plans/0052-floor-then-depth/spotcheck-floor.ps1
  - plans/0052-floor-then-depth/spotcheck-floor.cjs
  - plans/0052-floor-then-depth/spotcheck-floor-part1.txt
  - PSGraphRender v0.17.0
---

# Pass 0052 — The floor learns to see, then the 3D view gets depth, menus and its real default

## Asked

The operator prompted a **large** item, the second in this project's record.
The 3D page had "nothing but a little extra" — no menus in the HTML, no grid or
environment giving the nodes depth and contrast, no controls for zoom speed or
focus-by-distance. The 2D report ships a full sidebar; the 3D report shipped a
header.

And a hard internal order, which is the whole reason it is one pass rather than
two: **the instrument is repaired before any feature that would blind the old
one is built.** Every feature in the second half is unshippable as a default
under the floor the first half replaces, and the operator wanted the features.

⛔ No `contract/` change, no `src/*.ps1` edit, `cytoscape`/`plain`/`index.psd1`
byte-identical, no second copy of three.js, offline absolute.

## Done

PSGraphRender **v0.17.0**. Twelve commits on `pass-0052-floor-then-depth`.

- **The floor is a difference, not a ratio.** `smoke.cjs` compares the drawn and
  empty screenshots against each other — the fraction of the rectangle whose
  pixels differ by more than 12/255 on any channel — decoded in the browser that
  is already open rather than by a PNG library. `CanvasGrowth` is **gone** from
  `forcegraph3d` and its absence asserted; `CanvasDelta` replaces it at 0.015.
  `cytoscape` keeps the byte ratio, and `smoke.cjs` now *measures* the near-blank
  precondition that metric assumes rather than assuming it.
- **An environment.** `GridStyle` — `none`, `floor`, `room` — plus seven theme
  values, built from the graph's own bounding box so it fits any payload. One
  mesh for the whole thing, from quads.
- **A control panel.** `ShowControlPanel` and ten controls: zoom speed, fit,
  auto-rotate; depth falloff, environment, click-to-focus; names, direction
  marks, glow; and one checkbox per classification the payload carries. Plus
  `AutoRotate`, `AutoRotateSpeed`, `FocusOnClick`, `FocusDistance`,
  `FocusTransitionMs`.
- **Two browser case kinds**, `panel` and `control`, which drive a control
  through its own DOM events and read the result off the live scene.
- **The composed look is the default.** Catalogue variant `E1` was promoted into
  `Config/` and its row retired; `A5` preserves the v0.16.0 default whole.
  Twenty-two variants in five families.
- 14 new settings, schema 48 → 62 entries, and **no schema type the module
  could not already validate**. `Boolean` is new to *this backend* — `AutoRotate`
  and `FocusOnClick` are the first booleans it declares — and it was already a
  case in `Private/Config/Test-RenderSettingValue.ps1`, which this pass did not
  touch. A backend using a type it had not used before is a data change; only a
  type the module cannot validate would be a module change.

## Why

**Because a gate that goes green over a blank page is worse than no gate.** The
old floor screenshotted `#fg` and divided by the same element in an empty
render, so anything painted in that rectangle sat in the numerator and the
denominator together. The same drawing scored **4.32 on flat and 1.05 under a
vignette** — below the 2.25 that shipped, on a page drawing perfectly. Every DOM
assertion in the `Smoke` block passes just as happily over an empty rectangle,
so the floor was the only thing that could tell a drawn 3D view from a blank
one, and a background removed it.

**Because the sentence had been there for a release.** `styles/base.css` said
the floor "stops discriminating long before it stops passing" at v0.15.0, and
nothing turned that into a check. Pass 0051 met it as a 1.05 reading and ruled
`flat` to keep the gate. This pass took finding 67 as work rather than shipping
around it again.

**Because the environment had to be scene geometry.** A perspective floor
painted in CSS costs nothing and looks right in a screenshot; it reads as broken
the instant a reader drags, because the one thing a ground plane has to do is
stay where the ground is.

**Because a panel is the one part of a page whose whole job is to be
interactive**, so its gate had to be too. A handler that was never attached and
a handler that does nothing look identical to any check that calls past them.
Both new case kinds go through the DOM's own events.

## Measured

| | old byte ratio | new changed-pixel fraction |
|---|---|---|
| forcegraph3d / flat | 4.316 | 0.0295 |
| forcegraph3d / vignette | **1.053** | 0.0258 |

The red, recorded before any implementation: the same backend, the same payload,
the same amount of ink. The empty capture is what moves — **5,168 bytes flat
against 339,574 with a vignette, a 66× difference in a picture of nothing.**

And the claim proved on the shipped product rather than on a demo:

    canvas forcegraph3d/sample-module #fg: changed 35886/1103360 px = 0.0325
      | bytes 407277 drawn / 360736 empty = ratio 1.13
      | gated on CanvasDelta >= 0.015

**The default that ships now would score 1.13 against the 2.25 floor v0.16.0
used.** The old gate would fail the product. That is not an argument about what
a ratio does to a gradient; it is the measurement.

Floors re-pinned from three consecutive runs, twice — once on the v0.16.0 look
that part 1 measured against, thinnest 0.0271, and again on the default part 2
actually ships:

| fixture | run 1 | run 2 | run 3 |
|---|---|---|---|
| ambiguous (6/6) | 0.0638 | 0.0601 | 0.0638 |
| sample-module (9/5) | 0.0324 | 0.0325 | 0.0325 |
| infrastructure (17/20) | 0.0409 | 0.0409 | 0.0409 |

**Every fixture went up**, because the new default draws more. The floor stayed
at 0.015 and that is a decision: it is pinned under the thinnest thing this
backend has ever been observed to draw, which is still 0.0271 on the plain look
a caller gets by turning the environment off. Daylight went from 1.81× to
2.16×, and this file's own standard is 1.75× to 1.84×.

Gates: default build 8 tasks green; `TestLook` **26 cases**; `TestLinkMode` 10
cases across three modes and two backends; `PreTag` 9. Conformance unmoved at
both ends.

## Learned

**The second thing that needs a mechanism is what finds the first one's bug.**
`ShowLabels = 'always'` shipped at v0.16.0 and never drew a single label.
`ForceGraph3D` *empties* the container it is handed, `#fg-labels` was nested
inside `#fg`, so the layer was deleted before `startLabels` looked for it,
`getElementById` returned null, and the function returned silently. Two
catalogue variants are pictures of the feature not happening, captioned as
though it were — and the look gate at 0051 had no case for labels, so nothing
was lying, nothing was looking. It was found because the control panel
disappeared exactly the same way.

**A comment doing a gate's job is a defect with a long fuse.** Finding 67 was
prose in `base.css` for one release before it cost anything. This pass shipped
the same shape of claim and caught it inside the pass: the environment's
material said it "never occludes an item", and `room` rules its near wall across
the graph. Corrected in all three files that repeated it, and filed rather than
fixed, because the fix is shipped geometry.

**An assertion that names a constant can be orphaned by a rename, and it fails
in the safe-looking direction.** The suite had an `It` called "re-measured the
canvas-growth floor under the new look" that matched the manifest for
`CanvasGrowth` and `v0.16.0`. Part 1 renamed that key to `CanvasDelta` and
deleted it, so the word survived only in the comment explaining its removal and
the version survived as a label on a historical table. Both patterns went on
matching while both subjects moved out from under them — and the record they
guarded had shipped with `__RM1__` through `__RM9__` still in it, a
re-measurement table written to be filled after part 2 and never filled. Neither
was found by anything running. Both halves are derived now, and a placeholder
token anywhere in the block fails the check. Finding 75.

**A probe that damages nothing proves nothing, and it looks identical to a gate
that cannot be falsified.** Two of this pass's six probes were string
replacements against text that had moved — the manifest aligns
`Live     = '#fg-live'`, and `'#fg'` sits inside `CanvasDelta = @{ ... }`. Both
matched nothing, so the clone stayed pristine and the gate was correctly green,
and both probes reported their gates as unfalsifiable. **The framework caught
it** — "a probe that does not fail is a failure" is the rule that turned two
silent no-ops into two red lines — but it could not say why, because a gate that
was never damaged and a gate that cannot go red produce the same message. Probes
now assert their own damage landed before they judge anything. Finding 76.

**Capability read from bytes, not documentation, twice more.** There is no
`Line` constructor anywhere in the live scene, because the bundle draws every
link as a cylinder — so the grid is quads. And the controls the library builds
are `TrackballControls`, whose own keys are `rotateSpeed`, `zoomSpeed`,
`panSpeed`, `noRotate`, `staticMoving`, `dynamicDampingFactor` and `target`,
with no `autoRotate` among them — so auto-rotate is turned by hand.

**A promoted variant should leave the table.** `E1` became the default, so a row
for it would be a second picture of `A0`, and the catalogue's rule — one caption
saying what this changes *from default* — cannot be written for a variant that
changes nothing. Its coordinate is retired rather than reused: a label is a
thing the operator points with.

**And the pass was stopped by its own prompt.** The operator halted the run on
twenty-three files of finished, unpushed work. The root cause was an authoring
defect — the prompt's task spine had been compressed and dropped the "push after
every task" line that 0047 through 0051 all carried. The rule now lives in
`PSGraphRender/docs/HANDOFF.md` beside the other commit conventions, where a
prompt's brevity cannot repeal it. The in-flight work was partitioned back into
task-shaped commits from the diff content rather than from memory, and the
partition was proved byte-for-byte against a pre-partition snapshot.

## Capability

The 3D backend is now a report rather than a drawing: it has an environment that
gives it depth, a panel that lets a reader change what they are looking at
without a re-render, and a filter with parity to the 2D sidebar. The settings
surface is 62 entries and still zero schema types, so a backend is still a
directory.

More durably: **this repository now has an instrument that survives the thing it
measures.** The canvas floor can see a drawn page through a painted background,
which is what makes any future look work shippable as a default at all. The
pattern — repair the instrument in the same pass as the feature that would blind
it, in that order — is the 0046-before-0047 shape applied inside one pass, and it
is the second time this project has needed it.
