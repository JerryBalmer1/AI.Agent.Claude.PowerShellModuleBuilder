---
pass: 0050
title: Move the link probe out of the build task and into each backend
date: 2026-09-04
artifacts:
  - plans/0050-link-probe-data/plan.md
  - plans/0050-link-probe-data/verify.ps1
  - plans/0050-link-probe-data/verify-run.txt
  - plans/0050-link-probe-data/verify-failcheck.txt
  - plans/0050-link-probe-data/sc1-red-demo.txt
  - plans/0050-link-probe-data/sc2-guard-both-ways.txt
  - plans/0050-link-probe-data/sc3-fresh-clone.txt
---

# Pass 0050 — Move the link probe out of the build task and into each backend

## Asked

Backlog 66, and the medium entry at `docs/improvements.md:63`.
`PSGraphRender.build.ps1`'s `TestLinkMode` carried a `$LINK_PROBE` map naming
each backend's canvas, menu, mouse button and readiness selector — a second
place a backend's shape is written down, which is the defect the `Smoke` block
exists to remove. The declaration moves into each `templateset.psd1` beside
`Smoke`, the build task reads manifests, the map dies. The blocker that logged it
rather than fixing it — pass 0049's control that `cytoscape/` does not move at
all — was pass-scoped and had expired. Full tier.

The prompt also carried a derivation for the pass to confirm: `link-mode.cjs:37`
holds a `DEFAULTS` object with cytoscape's selectors as fallbacks, a **third**
copy. Remove it — required job fields, failing by name — or record in Deviations
why it stays.

Four prohibitions: no conformance-inventory or harness-instrument change, and a
moved denominator is a stop rather than a finding; no `contract/` change; no
rendered-output change; **no new probe capabilities — fields move, they do not
grow**. `plain/` and `TemplateSets/index.psd1` untouched.

Acceptance in three parts, red first: the declaration is demanded; the probe
still probes with the same case inventory and the guard still throws by name,
now citing the manifest; nothing rendered moves. Then docs, a release, harness
records, and a local handoff.

## Done

**PSGraphRender**, branch `pass-0050-link-probe-data`, tagged **`v0.15.1`** on
`e7bbfca`. Base `0d2c5df` (`v0.15.0`).

- `src/PSGraphRender/TemplateSets/cytoscape/templateset.psd1` and
  `.../forcegraph3d/templateset.psd1` — a `LinkProbe` block beside `Smoke`.
  cytoscape: `Canvas`, `Button`, `Menu`, `Ready`. forcegraph3d: those plus
  `Open`, `Settle`, `Hover`. Values moved from the map field for field; keys
  PascalCase, following `Smoke`.
- `PSGraphRender.build.ps1` — `$LINK_PROBE` deleted with its twelve-line
  comment. `TestLinkMode` reads `LinkProbe` off the manifest it already imports
  and passes the block whole under one job key, `probe`, as `TestBrowser`
  already does with `Smoke`. The guard is inverted: it fires for a manifest
  declaring `SlotsBySetting.LinkMode` and no `LinkProbe`, naming the manifest
  and the key.
- `tests/browser/link-mode.cjs` — `DEFAULTS` deleted. `Canvas`, `Menu`,
  `Button`, `Ready` required, missing throws by name from inside `runCase`'s
  try so it reports as a named case. `Open → Menu`, `Hover → 0`,
  `Settle → SETTLE_MS` remain.
- `tests/LinkProbe.Tests.ps1` — 9 assertions across acceptance A, B and C,
  including a red-capability sibling that asserts a `Slots` edit *does* move
  the document.
- `CHANGELOG.md` (`[0.15.1]`), `docs/improvements.md` (entry closed, superseded
  text struck), `docs/HANDOFF.md` (a Pass 0050 section, the module version, a
  version-ledger row, and 0049's paragraph about the map struck).
- `src/PSGraphRender/PSGraphRender.psd1` — `ModuleVersion` 0.15.0 → 0.15.1.

**Not changed:** any `.ps1` under `src/PSGraphRender/`, `contract/`,
`TemplateSets/index.psd1`, `TemplateSets/plain/`, `tests/LinkMode.Tests.ps1`,
`tests/browser/smoke.cjs`, the conformance inventory.

**Harness**, branch `pass-0050-link-probe-data`: `plans/0050-link-probe-data/`
(plan, `verify.ps1`, two verify records, three spot-check records); `LEDGER.md`
(counter, version line, backlog 66 resolved in place); this entry.

## Why

**`Smoke` decided the shape, so nothing about it was invented.** `TestBrowser`
hands `smoke.cjs` the block whole under one job key and the harness reads its
PascalCase keys straight off it; it also throws by name when the block is
missing. `LinkProbe` follows all three rules. The alternative — keeping the
map's lowercase names and going on flattening them onto each case — was
rejected: a second convention in the block sitting directly beside `Smoke`
would be a new inconsistency bought to avoid a rename.

**Flattening was what made the harness a third copy.** With the fields spread
onto the case, `link-mode.cjs` had to decide what to do about each one
individually, and what it did was default it — to cytoscape's. Passing the block
whole removes the question.

**Three fallbacks were kept, and the rule they are measured against is stated
rather than assumed.** The rule is *the harness knows no backend's selectors*,
not *the harness has no defaults*. `Open → Menu` is a relationship between two
fields the job did supply, and the file already documents why: the two are the
same element for a context menu and different for a panel that names an item
before listing what it offers. `Hover → 0` is the absence of a delay.
`SETTLE_MS` is a wait, and making `Settle` required would mean writing
`Settle = 500` into cytoscape's manifest — a value the map never carried, which
the pass's own "fields move, they do not grow" forbids. Its comment no longer
attributes the number to a backend.

**Rejected: a test asserting the moved values equal the values the map held.**
It would be a fourth place the selectors are written down, inside the file whose
entire purpose is that there is one. Acceptance A asserts the fields are present
and usable, the browser run asserts the values work, and verify's P3 asserts
they are what drives the probe.

**Rejected: listing the selectors the harness must not contain.** The check
derives them from the manifests, so a fourth backend's shape is covered the day
it is declared rather than the day somebody remembers to add it. That decision
is also what found the third copy.

**Tasks 3 and 4 landed in one commit** because they are one swap — the job's
shape changes on both sides at once, and the middle state drives `forcegraph3d`
with cytoscape's fallbacks, which is the defect being removed. Task 2 landed on
its own: with the map still in place the new key is inert.

## Measured

**The moved data, read back after the move** (`plan.md` §7): cytoscape
`Button=right Canvas=#cy Menu=#node-menu Ready=#cy canvas`; forcegraph3d
`Button=left Canvas=#fg Hover=150 Menu=#fg-actions Open=#fg-panel Ready=#fg
canvas Settle=3000`; `plain` none. Field for field what `$LINK_PROBE` held at
`0d2c5df`.

**Full build at head** (`plan.md` §7): 180 tests passed / 0 failed, line
coverage **81.36%** (target 80), 33 scripts parse (9 as declared fragments), 5
assembled blocks across 3 backends, 9 pages alive with the network blocked, 10
link-mode cases resolved as configured. `PreTag`: 9 assertions green.

**The case inventory** (`verify-run.txt` check 4), compared on the resolved
href rather than the case id: **10 at base, 10 at head, identical line for
line**.

**Byte identity from fresh clones at the tag** (`sc3-fresh-clone.txt`):
cytoscape `CA49B6D8C275DD2B`, forcegraph3d `3739940D9B7350AD`, plain
`07A6FDFB959FA8D2` — all three IDENTICAL to `0d2c5df`. In-run against the base
clone: 625,921 / 1,359,003 / 21,467 characters, equal both sides.

**The guard, both ways** (`sc2-guard-both-ways.txt`, verify check 5): a scratch
backend with modes and no probe fails **by name in 2.07s, before a browser
starts**; the same directory with a `LinkProbe` block runs all five of its
modes — **15 cases** total.

**Conformance** (`verify-run.txt` check 7), measured at both commits in the same
run from built clones: **66.27% over 166 cases, `CasesDefined` 42**, at base and
at head. Unchanged on all three figures.

**Falsification** (`verify-failcheck.txt`): five probes, all red for the right
reason. P3 is the load-bearing one — a corrupted `Canvas = '#not-a-canvas'`
leaves *0 red in the Pester suite* and turns the browser run red on `Cannot read
properties of null (reading 'boundingBox')`.

**SC1's red demo** (`sc1-red-demo.txt`): at base, `grep -n 'LINK_PROBE'` returns
4 lines and `grep -n "'#cy'"` returns line 37. At head both return nothing.

## Learned

**An item written from one copy of a duplicate undercounts the duplicate.**
Backlog 66 said *a second place*. There were three. The entry was written by
someone looking at the map, and `link-mode.cjs`'s `DEFAULTS` was the fallback
the map's own comment mentioned in passing — "tests/browser/link-mode.cjs
defaults to cytoscape's, so a backend whose shape matches needs no entry" — as a
convenience rather than as a second copy of the same knowledge. A check written
to the entry's description would have gone green over it. What found it was
deriving the forbidden strings **from the manifests** instead.

**Presence is not consumption, and only the browser can tell them apart.** The
first four falsification probes all delete something a static check can see, and
any of them would have passed against an implementation that carried the
manifest data and still probed from somewhere else. P3 corrupts a value and
leaves the block present, complete and well-formed. It was written specifically
because every other check in the pass would have been green over that failure.

**Two acceptance assertions passed vacuously on the first run**, for the same
shape of reason 0049's `@($null)` did: they skipped a backend with no
`LinkProbe`, and at base every backend had none, so the loop examined nothing
and reported green. Each grew a counter asserting it examined every backend with
link modes. The lesson is not new — it is that the 0049 lesson has to be applied
to *each* new loop, because "skip what does not apply" and "skip everything" are
the same code.

**A conformance figure means nothing without saying whether the tree was
built.** The baseline was first measured against a clone that still carried the
scratch backend, so it was re-taken from a pristine one. Along the way the same
command against an *unbuilt* clone returned **63.25%** rather than 66.27%,
because the `RequiresBuild` tag needs `output/`. Six passes have now reproduced
66.27 and none of them recorded that the number is conditional on a build having
run.

**The verifier failed the check it verifies, and SC4 caught it before the
commit.** `verify.ps1`'s first draft echoed the absolute path it copied the
Playwright tree from into both committed records; matched a username **written
as a literal**, which is 0047's form and puts a username into the file that
exists to keep usernames out of files; and composed P5's known-bad path as a
literal, so the verifier's own text failed its own grep. All three fixed at the
source — the version without the path, `$env:USERNAME` derived with a length
guard, the bad path assembled from pieces — and both runs re-run from scratch so
the committed records are what the fixed script produces. Sanitising the records
instead would have committed output no script produces, which is the same defect
one layer further down.

**Nothing went wrong with the plan's predictions.** Every 🔴 stop was checked
and none fired: the frontier agreed across three sources, both repos were where
the prompt said, `docs/constraints.md` had no colliding entry, no test rejects an
unknown top-level manifest key, the denominator did not move, and the repo's own
written rule made the release a patch rather than a minor.

## Capability

A backend can now state **how to drive it** as well as what it looks like alive.
`Smoke` said what "this page came alive" means for a backend; `LinkProbe` says
where a browser clicks to reach that backend's node actions. Adding a fourth
backend with working link modes is a data edit in one directory: demonstrated,
with a scratch backend going from a named build failure to five green link-mode
cases without a `.ps1` or a harness line changing.

`tests/browser/link-mode.cjs` can drive a backend it has never heard of. It
holds no selector for any backend, and a job that declares too little fails by
name instead of being driven against cytoscape's shape.

`tests/LinkProbe.Tests.ps1` turns a missing or unusable declaration red at build
time rather than forty seconds into a browser run, and derives the selectors it
forbids in the harness from the manifests — so the check covers a backend that
does not exist yet.
