---
pass: 0043
title: Give each ecosystem repository a committed examples directory
date: 2026-09-03
artifacts:
  - plans/0043-examples-showcase/plan.md
  - plans/0043-examples-showcase/accept.ps1
  - plans/0043-examples-showcase/verify.ps1
  - decisions/0016-abandon-pass-0042.md
  - https://github.com/JerryBalmer1/PSGraphRender/tree/main/examples
  - https://github.com/JerryBalmer1/PSGraphRenderToHtml/tree/main/examples
  - https://github.com/JerryBalmer1/PSAzureDevOpsGraph/tree/main/examples
  - https://github.com/JerryBalmer1/PSTerraformGraph/tree/main/examples
---

# Pass 0043 — Give each ecosystem repository a committed examples directory

## Asked

Give each of the four ecosystem repositories an `examples/` directory of real
generated artifacts — input, self-contained interactive HTML, a 1600x900
screenshot, and a paste-able regeneration command — and rework each README so a
first-time reader meets them within the first screen. A named matrix defined the
rows: three layouts, a theme pair and a node-link demo for PSGraphRender;
nesting and a three-way option-precedence demonstration for PSGraphRenderToHtml;
the live `ClaudeTesting` graph for PSAzureDevOpsGraph; the frozen Terraform
fixture for PSTerraformGraph. RequiresBuild: modules imported and executed, no
module source changes intended, any source change required is a Deviation
reported before it is made. Six named spot-checks. The file also carried an
idempotent Phase R to clear two operator-only blockers left by the pass's two
earlier hard stops.

## Done

Phase R found its work already done — harness on `main`, decision 0016
committed, PSModuleGraph relocated to `scratch/` — and R6's session gate passed.

- `plans/0043-examples-showcase/accept.ps1`, committed and observed red
  (exit 1, 49 findings) before any example work.
- **PSGraphRender** — 6 reports from 2 checked-in viewmodels: `foundation`,
  `testorder`, `callflow`, a shipped/contrast theme pair, and a node-link demo.
  `docs/improvements.md` gained one logged backlog item.
- **PSGraphRenderToHtml** — 4 reports from 2 producer graphs: nesting four deep,
  and the same nine-node graph rendered under built-ins, a defaults file, and
  explicit options.
- **PSAzureDevOpsGraph** — the live `ClaudeTesting` graph, 51 nodes and 51
  edges, as committed JSON, HTML and the pass's hero screenshot. Tagged
  `v0.4.0` with `docs/worklog/v0.4.0.md`.
- **PSTerraformGraph** — the frozen fixture read as one configuration, 78 nodes
  and 59 edges.
- Four READMEs reworked: badge row, hero image, `## Examples` table before any
  internals, every artifact cell hyperlinked, every code fence language-tagged.
  Four `docs/HANDOFF.md` files updated.
- `LEDGER.md` counter-drift correction (0040 → 0041) committed alone, then the
  pass entry (→ 0043, PSAzureDevOpsGraph → v0.4.0) committed separately.

## Why

**The acceptance test asserts `git ls-files`, not `Test-Path`.** An artifact
generated into a working tree and never staged passes an existence check and
fails a stranger cloning the repository, which is the exact reader this pass
exists for.

**Layout variants are template-set overlays, not source edits.** PSGraphRender
takes no `-Setting` parameter by design; configuration reaches it only through a
template-set directory. Each variant copies the shipped `cytoscape` set to a
temporary directory, edits one data file, and passes `-TemplateSetPath` — the
same seam a third-party backend uses. Rejected: adding a settings parameter, and
editing the shipped set in place. Both make generating an example a source
change.

**The mapping onto the producer contract lives in each example, not in the
producer.** PSAzureDevOpsGraph emits its own older shape and needs ~40 lines to
render; PSTerraformGraph already emits the contract and needs none. Rejected:
teaching PSAzureDevOpsGraph the render stack, which would have made a docs pass
create a dependency between two repositories.

**The prompt's `https` node-link requirement was struck rather than
implemented.** `vsCodeUriFor` hardcodes `vscode://file/` and `NODE_ACTIONS`
binds to it; no setting names an alternative, so the requirement could not be
met without changing a versioned module inside a documentation pass. Reported
before anything was built. The operator struck the requirement, kept the row
with `meta.rootPath` as the literal `REPLACE-WITH-YOUR-CLONE-PATH`, and had the
capability logged instead. Rejected: adding a link-template setting (a feature
change wanting its own red-first pass and a version bump), and committing a
forked copy of the renderer's JS under `examples/` (a fork that would silently
drift).

**SC2 was narrowed to machine-identifying content.** Its literal grep for
`vscode://` was unsatisfiable: PSGraphRender's own template set puts ~8
occurrences in every cytoscape document — five are UI copy in `strings.psd1` —
which no producer can suppress. Narrowed to what the check is for: zero
drive-absolute paths, zero links resolving to a real machine.

**The verify script went to `plans/0043-examples-showcase/verify.ps1`, not the
`verify/Verify-Pass0043.ps1` the prompt named.** Every prior pass puts it under
`plans/<pass>/`, and decision 0004 — which governs verify scripts — cites that
shape. Creating a top-level directory that has never existed to satisfy a path
string was the worse of the two.

## Measured

- Acceptance red before the work: **exit 1, 49 findings**
  (`plans/0043-examples-showcase/accept-red.txt`).
- Acceptance green after it, and green again against **fresh clones** of all
  four repositories (`accept-green.txt`, exit 0 both times).
- Verify: **PASS 45, FAIL 0**, including `-FailCheck`
  (`plans/0043-examples-showcase/verify-run.txt`).
- Matrix: **12 HTML reports, 12 PNGs, 8 checked-in inputs** across four
  repositories.
- Live read: **49 nodes, 51 edges** from `ClaudeTesting`, becoming 51 nodes
  after unresolved targets are carried
  (`PSAzureDevOpsGraph/examples/input/claudetesting-graph.json`).
- Terraform fixture: **78 nodes, 59 edges** across three repositories
  (`PSTerraformGraph/examples/input/claudetestingterraform-graph.json`).
- Layout enumeration: **3**, from `DefaultFlow.Values` in
  `settings.schema.psd1`, corroborated by `FLOW_LAYOUT` in `render.js`.
- SC1: **0** external script/style/img references in a rendered report; the 6
  `http(s)` strings present are vendored licence comments and one help string.
- SC2: **0** drive-absolute paths across all committed `examples/` and READMEs
  in four repositories. SC3: **0** 84-character credential-shaped runs.
- SC4: all 12 PNGs 1600x900, canvas-region distinct colours **202–981** against
  a blank-canvas floor of ~2.
- SC5: **4 of 4** regenerated artifacts identical to the committed ones from
  fresh clones, after end-of-line and `generatedAt` normalisation
  (`plans/0043-examples-showcase/sc5-regeneration.txt`).

## Learned

**A guard that tests the wrong thing fails the one case it should pass.** The
first overlay writer asserted `$updated -ne $text` to prove the `DefaultFlow`
line had been found. Setting `foundation` over `foundation` is a legitimate
no-op, so the very first render aborted. The assertion belonged on the pattern
matching, not on the text changing.

**Two module objects, one name, and the error arrives three layers away.**
Importing PSGraphRenderToHtml before PSGraphRender lets PowerShell satisfy
`RequiredModules` from the module path, and importing a sibling copy afterwards
leaves two `PSGraphRender` modules loaded. `Export-ProducerGraphHtml` resolves
the backend with `Get-Module -Name PSGraphRender`, gets an array, and the
failure surfaces as *"Cannot process argument transformation on parameter
'TemplateSetPath'"*. Every example script now imports the renderer first,
unloads first where a producer has already pulled one in, and asserts exactly
one is loaded.

**`[A-Za-z]:[\\/]` matches every URL.** The prompt's own SC2 pattern reported 18
drive-absolute paths in each clean artifact — `http://` and `vscode://` both
match `letter` `:` `/`. The corrected pattern needs a negative lookbehind, and
the difference between the two is the difference between a passing pass and a
false abort.

**Measuring a whole screenshot cannot tell drawn from blank.** The 78-node
Terraform render is a race: identical invocations produced a full canvas and an
empty one at the same virtual-time budget, and a longer budget did not settle
it. A blank canvas beside a populated sidebar still scores ~169 distinct
colours, above any threshold a small graph could clear. Sampling the canvas
region alone separates them cleanly — 2 versus 971 — and the screenshot tool now
retries until the region is drawn.

**A comment asserting a behaviour the artifact disproves.** The precedence
script claimed the defaults file's `ZoomSpeed 2.5` survives an explicit
`-Options`. The rendered document said `1.25`. `New-GraphRenderOptions` returns
a complete object, so an explicit object outranks the file on every key,
including ones the caller never named. The examples now demonstrate this on
purpose; the whole-key merge is the level below.

**Dropping what will not fit is the failure both contracts exist to prevent,
and it was the first thing written.** Two of ClaudeTesting's 51 edges point at
targets that are not nodes. The first mapping filtered them out and rendered 49
edges from a 51-edge graph — beside a comment saying unresolved references are
carried, not dropped. Carrying them means inventing a node for the missing
target.

**A scan is faithful to where it ran, and a committed artifact must not be.**
Every `node.path` and every `meta.roots` entry from the Terraform scan carried
the absolute scratch path. `meta.roots` is the one that would have been missed:
`ConvertTo-GraphRenderViewModel` takes `roots[0]` as the view model's
`rootPath`, so it reaches the rendered HTML too. Both were found by grepping the
committed artifacts, not by reading the code.

**Two pre-existing drifts in PSAzureDevOpsGraph, recorded not repaired.** Its
manifest still declares `ModuleVersion = '0.1.0'` while the tag line reached
`v0.4.0`, and the `PreTag` task filters on a Pester tag no test in `tests/`
carries — so `./build.ps1 -Task PreTag` runs zero tests and reports success.

## Capability

The plugin can now hand a stranger a rendered artifact instead of a description
of one. Each of the four ecosystem repositories carries the graph it produces —
input, interactive HTML, screenshot — with a single paste-able command per row
that regenerates the HTML from a fresh clone, verified to reproduce the
committed bytes. Two of the four regenerate with no network and no credential at
all; the two that read live sources take their token from a named environment
variable and commit neither it nor any path from the machine that ran them.
