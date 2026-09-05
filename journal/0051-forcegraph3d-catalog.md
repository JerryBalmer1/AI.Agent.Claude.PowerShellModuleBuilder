---
pass: 0051
title: Give the 3D backend a look, an options surface and a labelled catalogue
date: 2026-09-04
artifacts:
  - plans/0051-forcegraph3d-catalog/plan.md
  - plans/0051-forcegraph3d-catalog/verify.ps1
  - plans/0051-forcegraph3d-catalog/verify-run.txt
  - plans/0051-forcegraph3d-catalog/verify-failcheck.txt
  - PSGraphRender v0.16.0 (tag on dba1f4d)
---

# Pass 0051 — Give the 3D backend a look, an options surface and a labelled catalogue

## Asked

The operator prompted a **large** item: `forcegraph3d` renders, links and passes
its gates, and looks like a tech demo — uniform blue spheres on black, no visual
language, no options. Four things were wanted: a modern look (emissive
materials, glow, link particles, depth cues, a background that reads as an
environment); real options declared as typed configuration (zoom speed, hover
behaviour and tooltip content, pointer-button mapping with `LinkProbe`
following it, particle density, bloom strength, fog depth, label visibility);
node geometry from a declared `kind → shape` mapping with a declared fallback,
size optionally from a `metrics` key, and `isExported` / `links[].resolution`
available as visual distinctions; and a labelled variant catalogue of at least
16 members across at least 5 families, generated rather than written.

⛔ No `contract/` change, no `src/*.ps1` edit, `cytoscape`/`plain`/`index.psd1`
byte-identical, offline absolute.

## Done

PSGraphRender **v0.16.0**, tagged on `dba1f4d`. Four commits on
`pass-0051-forcegraph3d-catalog`.

- **26 settings** on `forcegraph3d`: 7 behaviour (`ZoomSpeed`, `RotateSpeed`,
  `HoverMode`, `HoverTooltip`, `NodeActionButton`, `ShowLabels`,
  `LabelMaxNodes`), 19 appearance (shape mapping and fallbacks, size by metric,
  exported emphasis, glow, fog, environment, particles, link-resolution colour,
  exposure). Schema 22 → 48 entries, **zero new types**.
- **Four new script files** under the set: `shapes.js`, `scene.js`, `labels.js`,
  and a rewritten `graph.js`. `partials/graph.html` gained two hidden elements
  the page states its resolved mapping and its live values in.
- **`./build.ps1 -Task TestLook` and `tests/browser/look.cjs`**, driven by a
  **`LookProbe`** block each backend declares for itself beside `Smoke` and
  `LinkProbe`.
- **`examples/threed/variants.psd1`** — 19 variants, 5 families — and
  `examples/threed/catalog.html` generated from it by
  `examples/Build-Examples.ps1 -Variant`, plus 19 committed html + png pairs.
- `templateset.psd1`: `LinkProbe.Button` follows `NodeActionButton`;
  `Smoke.CanvasGrowth` floor 2 → 2.25 with its measurement table rewritten.
- `docs/improvements.md`, `docs/vendoring.md`, `docs/render-architecture.md`,
  `docs/HANDOFF.md`, `CHANGELOG.md`, `README.md`, `examples/README.md`.
- Harness: `plans/0051-forcegraph3d-catalog/` with `plan.md`, `verify.ps1`, and
  both run records.

## Why

**Every capability was read out of the vendored bundle before anything was
written**, because the requirement-direction gate exists for exactly this and a
claim about this library had been wrong before. What that found decided most of
the implementation:

- **`THREE` is not a global** — the UMD wrapper exports `ForceGraph3D` alone —
  so geometry is built from constructors harvested off a mesh the library has
  already made. Rejected: vendoring three.js a second time, which is what the
  bundle's own *"Multiple instances"* warning exists to report.
- **The bundle is tree-shaken.** Four of the eight shapes are not in it at all.
  Rejected: reading geometry constructors off instances, which reaches four
  shapes; explicit vertex arrays reach all eight and depend on nothing
  tree-shaking can remove.
- **There is no bloom pass.** Rejected: vendoring the addon, for the same
  reason. The glow is an emissive core in an additively-blended back-face shell.
- **`FogExp2`'s class is gone but the renderer's support is intact**, so fog is
  a duck-typed object carrying exactly the three things the renderer reads.

**`BackgroundStyle` ships `flat`, which is not what the operator asked for and
not the prettier answer.** A gradient is in the canvas-growth floor's picture of
an *empty* render as well as a drawn one, so it does not move that ratio, it
removes it. Rejected: shipping the environment and lowering the floor — the
floor is the only thing that can tell a drawn 3D view from a blank one, and
every DOM assertion in `Smoke` passes just as happily over a blank rectangle.

**`KindShape` is a `String` and should be a `ShapeMap`.** Rejected: adding the
type, which needs a validator under `src/` — the constraint that a backend is a
directory is the point, and it made the missing machinery visible rather than
letting a `.ps1` edit absorb it.

**Labels are DOM elements over the canvas, not sprites.** Rejected: sprites,
which are textures, which means drawing a producer's free text into a 2D canvas.
An element carrying `textContent` cannot become markup — the same property pass
0049 established for the tooltip, extended to the second place a producer's
string is now shown.

## Measured

- **Canvas growth, three runs**, against an empty render still 5,168 bytes:
  ambiguous 8.96 / 9.01 / 9.04; sample-module 4.28 / 4.24 / 4.03;
  infrastructure 6.09 / 5.86 / 5.90. Against v0.15.1's settled 6.49 / 3.50 /
  4.77. Thinnest 4.03; floor 2 → **2.25**, which is 1.79× of daylight against
  the manifest's own 1.75× and the reference backend's 1.84×.
  `plans/0051-forcegraph3d-catalog/plan.md`, `verify-run.txt`.
- **Background against the floor**, sample-module at 1280×900: flat 5,168 empty
  / 19,586 drawn / **3.79**; gradient and vignette 313,384 / 329,766 / **1.05**.
  A gradient two steps per channel from flat: 122,355 empty, **1.14**.
  `src/PSGraphRender/TemplateSets/forcegraph3d/Config/theme.psd1`.
- **Camera distance after fit**, which is why fog is normalised: ambiguous 224,
  ecosystem 362, sample-module 568, infrastructure 565 — 2.5× range, against
  extents of 156 / 256 / 312 / 367. `scripts/scene.js`.
- **Bundle inspection**: `UnrealBloomPass` 0 occurrences, `ShaderPass` 0,
  `OctahedronGeometry` 0, `TorusGeometry` 0, `TetrahedronGeometry` 0,
  `IcosahedronGeometry` 0; `FogExp2` 3, all of them the `isFogExp2` flag.
  `docs/vendoring.md`.
- **Acceptance**: 76 of 88 red at `d26b90a`; 107 of 107 green at `dba1f4d`.
- **Browser gates**: TestBrowser 9 cases, TestLinkMode 10, TestLook 12.
- **Conformance**, both ends against BUILT trees: 66.27% over 166 cases,
  CasesDefined 42, unmoved. `verify-run.txt`.
- **Catalogue size**: 26 MB of HTML on disk, ~3.7 MB packed (repo 6.89 → 10.62
  MiB), because 19 documents sharing a 1.3 MB vendored library delta against
  each other.

## Learned

**The browser gate found two things on its first run, and neither was findable
any other way.** The hover count was always zero while the drawing was visibly
highlighting: `labelFor` published the hover state again when the library asked
for a tooltip, with no set, so the tooltip's publish landed last and overwrote a
real count. **A DOM-only check would have gone green**, because the DOM said
what the page claimed rather than what it did — which is why the gate reads
pixels as well.

**A check that fails against correct work is a defect in the check.** The fog
case asserted `fogDensity == 0.004` and failed against a correct page reporting
`0.00399`. Fog density is normalised by camera distance so one value means one
appearance on any payload, so no single reading can be compared to the setting.
The fix was to assert the property that is actually true — proportionality over
two documents — rather than to relax the number or to drop the normalisation.

**Five catalogue variants rendered the default look while the catalogue claimed
otherwise.** The overlay writer tested for a multi-line map with `-match`, which
takes no `RegexOptions`, so the guard ran without `Singleline` while the replace
used it; a map key failed the test, fell through to the single-line branch, and
orphaned the rest of its block. The file stopped parsing and the resolver did
the right thing with a file it cannot parse, which is warn and use defaults.
**Found because the five had byte counts identical to each other and to nothing
else** — the same shape of evidence as pass 0050's identical-manifest finding.

**Two channels the theme controls separately must not be one channel in the
page.** E3 turns the glow off and asks for a ring, and got none, because the
ring borrowed the glow shell's material and therefore its opacity.

**A look is judged by looking, and six rounds of it moved numbers chosen by
reasoning.** Custom node objects ignore `nodeRelSize`, so the first render drew
items at 0.42× the size the backend had always drawn them. Fog normalised by
graph extent was still wrong because fog attenuates by *camera* distance, which
does not track extent — measured at 2.5× spread across four fixtures. three.js's
default lights are already near-full intensity, so emissive on top clips to
white. `zoomToFit` frames node positions rather than glow shells, so the
outermost haloes fell off the bottom of the frame.

**The prettiest default lost to a gate, and the loss is the entry.** The
temptation was to ship the vignette and lower the floor to 1.05. That would have
kept a background and thrown away the only check that can tell a drawn 3D view
from a blank one.

## Capability

A caller can change what the 3D backend DRAWS — geometry per classification,
size by any metric the payload carries, glow, depth, environment, link
particles, link confidence, exported emphasis — and how it BEHAVES — camera
speed, hover highlighting and tooltip content, which pointer button opens an
item's actions, whether names are always visible — by editing two data files in
a copied template-set directory, with no code change anywhere.

A backend can now declare how a gate checks its DRAWING, in its own manifest,
the way it already declares how a gate checks that it came alive and where its
links go.

An operator can name a look by coordinate — `A3`, `C1`, `E2` — from a generated
catalogue that cannot disagree with the table it is generated from, and promote
any of them to the default by moving its values into the theme file.
