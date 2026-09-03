---
pass: 0041
title: The signals a reader can see, and the three defects between the palette and the page
date: 2026-09-02
artifacts:
  - plans/0041-operator-ux/plan.md
  - plans/0041-operator-ux/accept.Tests.ps1
  - plans/0041-operator-ux/accept-red.txt
  - plans/0041-operator-ux/accept-green.txt
  - plans/0041-operator-ux/verify.ps1
  - plans/0041-operator-ux/verify-run.txt
  - plans/0041-operator-ux/transcript.txt
  - plans/0041-operator-ux/Invoke-ColorByFalsification.ps1
  - plans/0041-operator-ux/colorby-falsification.txt
  - plans/0041-operator-ux/colorby-gate-falsification.txt
  - plans/0041-operator-ux/theme-gate-falsification.txt
  - plans/0041-operator-ux/Compare-Mermaid.ps1
  - plans/0041-operator-ux/mermaid-colour-falsification.txt
  - plans/0041-operator-ux/Test-Links.ps1
  - plans/0041-operator-ux/linkcheck.txt
  - plans/0041-operator-ux/fence-render.txt
  - plans/0041-operator-ux/hero-shot.txt
  - plans/0041-operator-ux/diagram-build.txt
  - README.md
  - PLAN-PROTOCOL.md
  - decisions/0013-harness-release-tagging.md
  - docs/media/flow.png
  - docs/diagram/README.md
  - docs/diagram/flow-graph.json
  - docs/diagram/flow.html
  - docs/ux/README.md
  - docs/ux/UX-001-routing-signals.md
  - docs/ux/UX-002-ends-with-tripwire.md
  - docs/ux/UX-003-report-contract.md
  - docs/ux/UX-004-heartbeats.md
  - docs/ux/UX-005-local-handoff.md
  - docs/ux/UX-006-presentation-standard.md
  - docs/creating-an-agent/01-the-two-claudes.md
  - docs/creating-an-agent/06-the-pass-protocol.md
  - docs/creating-an-agent/11-your-first-module.md
  - docs/testing/README.md
  - prompts/README.md
  - prompts/project-context-template.md
  - prompts/troubleshoot.md
  - skills/powershell-module-ux/SKILL.md
  - tools/diagram/Build-Diagram.ps1
---

# Pass 0041 — The signals a reader can see, and the three defects between the palette and the page

## Asked

Twelve tasks, full tier. Fix LEDGER 50 in `PSGraphRenderToHtml` and tag
`v0.1.1`. Regenerate `flow.html` coloured by layer from five colours declared
once in the graph, with the wheel zoom tuned down. Rebuild the README section
by section — badges, a hero shot of the diagram, every code fence
language-tagged, the Mermaid layer-coloured, the skills table and link map
hyperlinked, a description column, and a stated position on execute
affordances. Write the signal legend once, canonically, in the prompts kit.
Open `docs/ux/` with a registry and six seeded records. Put a signals section
at the top of the README. Retrofit the kit with routing circles and tripwires.
Apply three verbatim insertions to `PLAN-PROTOCOL.md` and one to decision 0013.
Add an error standard to `powershell-module-ux` as a release rider. Then the
item-19 docs, a link check, the acceptance test green, plan, journal, LEDGER,
push, `main`, and a LOCAL STATE table across all six repositories.

## Done

- `plans/0041-operator-ux/accept.Tests.ps1`, the supplied test verbatim. Red
  first at `Passed=0 Failed=12 Total=12`, green at the close.
- **LEDGER 50 fixed at the source.** `PSGraphRenderToHtml` `v0.1.1` aligns
  `-ColorBy` to the five values PSGraphRender's cytoscape settings schema
  actually declares, read out of `settings.schema.psd1` rather than guessed,
  and refuses anything else with a message naming both repositories and both
  sets. `Options.Tests.ps1` now reads that schema out of the resolved renderer
  and asserts every declared value is accepted — the cross-module test the
  ledger entry asked for, falsified by dropping one member and watching it
  report `REFUSED: reach`.
- **Two more ecosystem defects, `v0.1.2` and `v0.1.3`**, each found by trying
  to use the fix before it. See *Learned*.
- `docs/diagram/flow-graph.json` gains `meta.layerPalette`: five colours, one
  declaration. `Build-Diagram.ps1` translates them to the renderer's
  classification-keyed theme, tunes `ZoomSpeed` to `0.6`, and **throws on any
  renderer warning**. `flow.html` re-rendered at ToHtml `v0.1.3`, battery 7/7,
  `-Check` byte-identical.
- `docs/media/flow.png` — the hero, shot by PSGraphRender's own `shoot.cjs`
  against the committed `flow.html`, zero page errors.
- README: four badges, the hero, **zero untagged fences** (from four indented
  blocks and three fenced), five `classDef`s carrying the palette's own hexes,
  nineteen linked skills, a 39-row link map generated from the graph's own
  attributes, a hyperlinked layout table, and a stated no-execute position.
- `prompts/README.md` § *The legend* — one visual channel per dimension,
  declared once. Every kit file retrofitted with a routing banner and an
  `ENDS WITH` line; `troubleshoot.md` gains two symptoms;
  `project-context-template.md` gains *Trust* and *Presentation*.
- `docs/ux/` — a registry and six records, each with problem, why, what it
  solves and evidence.
- `PLAN-PROTOCOL.md` § *Signals, reports and records*, three sections verbatim.
  Decision 0013's amendment appended verbatim, settling LEDGER 49.
- `powershell-module-ux` gains the error standard, unreleased and recorded as
  such (LEDGER 56).
- Chapters 01, 06 and 11 and `docs/testing/` updated under item 19, which now
  carries the presentation standard as standing scope.
- Link check: `DEAD LINKS: 0` over 524 links in 26 documents.

## Learned

**The three defects between a palette and a page were all the same defect, and
it is not a coding mistake.** `-ColorBy` validated against another repository's
list without a test that ran through the real consumer. `-Theme` was declared,
documented, carried into the options object and covered by a test that checked
it *reached* the options object — and threw on every input, because nothing had
ever rendered with one. The overlay writer's round trip had never been
round-tripped. Each of the three was **declared, documented, and never driven
end to end**, and each was found within minutes of the attempt to use the one
before it.

A parameter nobody can use has no wrong behaviour to report. That is why none
of them surfaced across a release and a second producer's adoption, and it is
why the thing that found all three was a consumer following the module's own
advice on the afternoon it was written.

**The worst failure available is a render that succeeds.** `cross-cutting`
written bare into a `.psd1` parses as a subtraction, so the theme file failed to
parse *as a whole*; PSGraphRender warned once, fell back to its built-in
colours, and drew a perfectly good diagram in which every node was the fallback
grey. The build printed `WROTE`. Nothing about the artifact said it was wrong.
The fix is one line of consumer-side discipline — capture the render's warnings
and throw — and it is the only reason the committed diagram carries any colour
at all.

**PowerShell resolves a hashtable member against the entries before the
properties, and it cost this pass twice in one afternoon in opposite
directions.** `$entry.Values` returned every field of a schema entry instead of
the enum it declares; `$map.Keys` returned the value of an entry called `Keys`.
`.PSBase.Keys` on anything a producer keys.

**A supplied regex can force a real design decision, and the honest move is to
find the reading that keeps it a gate.** Counting bare ``` lines to zero looks
impossible, because a closing fence is bare. Four-backtick closers make it
possible, and — this is the part worth keeping — they make the count *mean*
something: the only bare fence the file can then contain is an untagged opener.
Four-backtick openers, or tilde fences, would have passed the same test while
measuring nothing.

**Two of this pass's own new checks caught two of this pass's own new bugs.** A
`{ }` inside a `ValidateScript` `ErrorMessage` broke `String.Format`, and the
falsification script reported it rather than review catching it. A stray `0x08`
byte from an escaping mistake made the Mermaid comparator refuse every
`classDef` it was written to read. A falsification that only ever confirms has
not been tried.

**Nothing here was measured.** Six UX records state what problem each convention
answers; not one claims a measured improvement, because none was taken. The
registry's own rule — a convention without a problem statement is decoration —
is enforced by nothing but the people following it, and that is written down as
LEDGER 57 rather than implied.

## Cost

About 4 hours 15 minutes. Twelve `PSGraphRenderToHtml` builds and three PreTag
runs; four diagram renders and one `-Check`; one `shoot.cjs` shot with zero page
errors; three acceptance runs and four progress runs; three gate falsifications
comprising eleven deliberate breaks; one link check over 524 links; one
`verify.ps1` from a fresh clone. No token count.
