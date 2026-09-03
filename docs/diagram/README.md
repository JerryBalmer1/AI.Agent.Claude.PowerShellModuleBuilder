# The flow diagram

One graph, three renderings, one source. This page is what the diagram is, what
the colours mean, how to regenerate it, and why the two renderings can do
different things.

| File | What it is |
|---|---|
| [flow-graph.json](flow-graph.json) | **the source.** Hand-authored. Every node names the artifact behind it. |
| [flow.html](flow.html) | the full-fidelity rendering: interactive, filterable, every node's *who / what / why* in a panel. Open it from a clone — GitHub serves HTML as text. |
| [the Mermaid block](../../README.md#the-flow) | a hand-written mirror, so the README shows the shape without asking anyone to clone anything. |

The mirror is compared against the source by node count, ids, labels and layer
membership — see [which rendering is authoritative](../../README.md#which-rendering-is-authoritative).
A second rendering nobody diffs is a second source of truth.

## The layer palette

Five layers, five colours, **declared once** in `flow-graph.json` under
`graph.meta.layerPalette` and read from there by everything that draws them.

| Layer | Colour | What lives there |
|---|---|---|
| 🟪 method | `#A99BF2` | METHOD.md, PLAN-PROTOCOL.md, `decisions/` — the rules everything above rests on |
| 🟩 instruments | `#79D9A8` | the conformance suite, the functional oracle, the two Terraform fixtures, the comparators |
| 🟨 plugin | `#F2C14E` | `psmodule` — its commands, its stages and all nineteen skills |
| 🟦 module | `#7FC4F2` | what gets built: your module, and PSAzureDevOpsGraph |
| 🟥 user | `#F2A0BE` | you |

**Colour is never the only carrier.** The layer's *word* is on the subgraph
title in the Mermaid, in the sidebar in `flow.html`, and in the Layer column of
[the link map](../../README.md#the-link-map). Five hues at one lightness are one
colourblind reader away from carrying nothing, and the swatches above are a
second channel, not the channel.

**Every colour is light on purpose.** The cytoscape backend draws node labels in
a hardcoded near-black, centred inside the node. A fill dark enough to look
serious is a node nobody can read.

### How five layer colours become eleven renderer colours

The renderer colours by **classification**, which is the payload's node `type`
— it has never heard of a layer. There are eleven types and five layers, and the
producer is what makes the two the same fact: **every type in this graph occurs
under exactly one scope**, so a type→colour map *is* a layer→colour map.

`Resolve-LayerColor` in
[`tools/diagram/Build-Diagram.ps1`](../../tools/diagram/Build-Diagram.ps1) does
that translation and throws rather than guessing in three ways: a type under two
scopes, a scope with no palette entry, and a palette entry no node uses. A
diagram whose colours mean something for thirty-seven nodes and nothing for two
is worse than one that never claimed to.

## Regenerating it

    pwsh -NoProfile -File ./tools/diagram/Build-Diagram.ps1

    pwsh -NoProfile -File ./tools/diagram/Build-Diagram.ps1 -Check

The first writes `flow.html`; the second re-renders and diffs against the
committed copy, ignoring the one line two renders always differ on
(`meta.generatedAt`). `-Check` is the form `verify.ps1` runs.

**A pass that changes the flow re-runs the build and re-mirrors the Mermaid**,
both in the same commit. That obligation is item 19 in [the LEDGER](../../LEDGER.md).

Both sibling repositories are consumed **at their pinned tags** —
PSGraphRenderToHtml `v0.1.3`, PSGraphRender `v0.13.0` — materialised read-only
with `git archive`, so neither checkout is touched and a diagram rendered by
whatever happened to be checked out is not possible.

**A renderer warning ends the run.** That guard is not decoration: it is the
only reason this page is not grey. PSGraphRenderToHtml v0.1.2 wrote the theme
overlay with bare keys, `cross-cutting` parsed as a subtraction, the theme file
failed to parse *as a whole*, and PSGraphRender warned and fell back to its
built-in colours. The page rendered. It looked deliberate. None of the five
layer colours were in it, and nothing about the artifact said so.

## Why GitHub's Mermaid pane cannot be tuned and `flow.html` can

They are not two views of one renderer. The Mermaid block is text in a Markdown
file that **GitHub** renders, client-side, in a cross-origin frame on
`viewscreen.githubusercontent.com`. What it offers is what GitHub offers: pan,
a zoom control in the corner, and a full-screen button. Its zoom sensitivity,
its layout engine and its interaction model are GitHub's, and no line in this
repository changes any of them. `classDef` is the whole of the styling surface
that survives, which is why the layer colours are all the Mermaid carries.

`click` directives are also unavailable — not by policy but because the answer
was *unproven*: a relative link inside that frame resolves against
`viewscreen.githubusercontent.com` rather than this repository, and whether an
absolute one works could not be observed from a terminal. It was
[tested rather than assumed](../../plans/0040-flow-docs/mermaid-click.txt), and
an unproven affordance does not ship. **The link map is the navigation.**

`flow.html` is rendered *here*, by a renderer this project consumes at a pinned
tag and configures through an options surface. So it carries what the Mermaid
cannot:

- **wheel-zoom sensitivity, tuned.** `ZoomSpeed 0.6` against the renderer's
  `1.25` default. On a 39-node graph the default crossed most of the diagram in
  one notch, which makes the control useless for the thing it exists for.
- **the layer colours as a live channel**, with a sidebar that says what colour
  means and lets you re-encode it — structure, or a heat ramp over any metric
  the payload carries.
- **the details panel**: each node's *who / what / why* and the repository-
  relative path of the artifact behind it.
- **focus and filtering**, which is the point of an interactive graph at all.

The trade is honest and worth stating plainly: the Mermaid is the one **you can
see without cloning**, and the HTML is the one that answers questions. Neither
replaces the other, and the JSON is what they are both renderings of.
