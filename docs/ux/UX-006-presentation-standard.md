# UX-006 — The presentation standard

Status: **in force** from pass 0041. Scope: `README.md`, and anything else a
stranger reads before deciding whether to trust this repository.

## Problem

**A repository whose subject is grading other people's output had a front door
nobody had graded.** Measured at `b02a501`, the commit this pass branched from,
`README.md` contained:

- **three fenced code blocks and four indented ones.** The indented blocks —
  the install commands, the uninstall commands, the bug-report commands — carry
  no language, so GitHub renders them grey and unhighlighted. They are the
  blocks a first-time reader is most likely to copy.
- **no badges**, so the release, the licence and the minimum PowerShell version
  were each a separate scroll away.
- **no image of any kind**, in a repository whose central artifact is a
  diagram, and which ships a renderer that produces one.
- **a diagram in one colour.** The layer structure — the whole argument of the
  page, that nothing above exists until the thing below it does — was carried
  by vertical position and subgraph titles alone.
- **a skills table of nineteen names, none of them a link**, each sitting
  beside a `SKILL.md` the reader had to go and find.

None of that is a defect in the sense the conformance suite means. All of it is
the difference between a page a stranger reads and one they close.

## Why

Because **presentation is the only part of this repository that nothing
measures**, and unmeasured things drift toward whatever was easiest to write.
Every number here has an artifact behind it and a script that re-derives it.
The page carrying those numbers had no such check, so it accumulated exactly
the flaws no test would ever mention.

There is a second, sharper reason, and it decides the *shape* of the standard
rather than its existence. The comparison the operator drew was to projects
whose README leads with a single line you paste into a shell — `irm <url> | iex`
— which is genuinely excellent presentation and is also a front door that turns
a reader into a runner before they have read anything. **This project cannot
copy that**, because its whole argument is that a claim you have not re-derived
is not evidence, and an install route nobody can audit is that same failure at
the level of trust.

So the standard has to be both: as legible as the pages that do that, and
deliberately without the affordance that makes them work. Which means the
absence has to be **stated**, not merely observed — otherwise it reads as an
omission rather than a position.

## What it solves

The standing rules, from pass 0041:

1. **Every code fence declares its language.** Zero untagged blocks, enforced
   by a regex in the acceptance test. An untagged block is one GitHub will not
   colour and a reader has to parse by eye.
2. **The badge row is the first thing under the title**: release, licence,
   minimum PowerShell, and one number this repository is actually about.
3. **A page about a diagram shows the diagram**, as an image, produced by this
   project's own renderer and linked to the interactive version. Never a
   hand-drawn or fabricated one, and never one that outlives the graph it was
   taken from.
4. **Colour carries the layer, and the word rides every marker.** Five layer
   colours, declared once in [`flow-graph.json`](../diagram/flow-graph.json),
   identical across the Mermaid, `flow.html` and the link map, and
   [compared by script](../../plans/0041-operator-ux/Compare-Mermaid.ps1)
   rather than by eye.
5. **A summary links what it summarises.** A section that states a finding and
   does not link the record it came from is prose.
6. **No execute affordances.** No `irm | iex`, no `curl | bash`, no one-click
   install, anywhere — and the README says so and says why, so the absence is a
   stated standard rather than a gap.

**A pass that changes what the README shows keeps this standard**, and that
obligation is recorded against item 19 in the [LEDGER](../../LEDGER.md),
alongside the diagram's.

## Evidence

- **The measurement**: three fenced blocks and four indented ones at
  `b02a501`. The end state is seven fenced blocks, zero untagged, verified by
  [`fence-render.txt`](../../plans/0041-operator-ux/fence-render.txt) — which
  parses the README with a CommonMark implementation and confirms every tagged
  opener produces exactly one block, rather than trusting the regex that counts
  them.
- **The hero**: [`docs/media/flow.png`](../media/flow.png), produced by
  PSGraphRender's own `tools/shoot.cjs` against this repository's committed
  `flow.html`. The transcript is
  [`hero-shot.txt`](../../plans/0041-operator-ux/hero-shot.txt), and it reports
  **zero page errors** — which is what makes it a picture of a working page
  rather than a picture.
- **The palette**: [`docs/diagram/README.md`](../diagram/README.md), and the
  four-way falsification of the colour comparison in
  [`mermaid-colour-falsification.txt`](../../plans/0041-operator-ux/mermaid-colour-falsification.txt)
  — a drifted hex, a node in the wrong colour class, a node in no class, and a
  palette entry with no `classDef`. Each break named the right thing, and the
  control was green either side.
- **What the standard cost to hold**: the layer colours could not be applied
  at all until three defects in PSGraphRenderToHtml were fixed — `-ColorBy`
  validated against a set the renderer does not have, `-Theme` unusable in
  every form, and a hyphenated classification silently losing the entire theme.
  All three were *declared, documented and never driven end to end*, which is
  the same shape as the problem above: something nobody had graded.
  [v0.1.1](https://github.com/JerryBalmer1/PSGraphRenderToHtml/releases/tag/v0.1.1),
  [v0.1.2](https://github.com/JerryBalmer1/PSGraphRenderToHtml/releases/tag/v0.1.2),
  [v0.1.3](https://github.com/JerryBalmer1/PSGraphRenderToHtml/releases/tag/v0.1.3).
- **The no-execute position**: [`SECURITY.md`](../../SECURITY.md), and the
  paragraph in the README's Install section that states it in the place a
  reader would otherwise look for the one-liner.
