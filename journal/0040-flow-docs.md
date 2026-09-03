---
pass: 0040
title: Draw the flow, write the prompts, and settle the red-target rule
date: 2026-09-02
artifacts:
  - plans/0040-flow-docs/plan.md
  - plans/0040-flow-docs/accept.Tests.ps1
  - plans/0040-flow-docs/accept-red.txt
  - plans/0040-flow-docs/accept-green.txt
  - plans/0040-flow-docs/verify.ps1
  - plans/0040-flow-docs/verify-run.txt
  - plans/0040-flow-docs/splat-coverage.txt
  - plans/0040-flow-docs/splat-probe.txt
  - plans/0040-flow-docs/New-SplatProbeFixture.ps1
  - plans/0040-flow-docs/Invoke-SplatProbe.ps1
  - plans/0040-flow-docs/Compare-Mermaid.ps1
  - plans/0040-flow-docs/Invoke-MermaidFalsification.ps1
  - plans/0040-flow-docs/mermaid-falsification.txt
  - plans/0040-flow-docs/mermaid-click.txt
  - plans/0040-flow-docs/Test-Links.ps1
  - plans/0040-flow-docs/linkcheck.txt
  - plans/0040-flow-docs/diagram-build.txt
  - docs/diagram/flow-graph.json
  - docs/diagram/flow.html
  - tools/diagram/Build-Diagram.ps1
  - decisions/0015-falsifying-against-a-red-target.md
  - docs/creating-an-agent/11-your-first-module.md
  - docs/design/hybrid-modules.md
  - prompts/README.md
  - PLAN-PROTOCOL.md
---

# Pass 0040 — Draw the flow, write the prompts, and settle the red-target rule

## Asked

Nine tasks, full tier, harness only, no release. Probe LEDGER 47's state and
record it. Write decision 0015 verbatim from the operator's text and fold a
paragraph into METHOD. Author a producer graph of the whole flow and render it
two ways — through PSGraphRenderToHtml and PSGraphRender at their pinned tags to
`docs/diagram/flow.html`, and by hand as Mermaid in a new README section headed
exactly *The flow* — with a link map under it and GitHub's Mermaid click support
**tested rather than assumed**. Write a six-file prompts kit for an end user.
Write chapter 11. Write the hybrid-modules design note. Apply three supplied
verbatim insertions. Then link-check everything touched, run the acceptance
test green, write the plan, journal and LEDGER, push, fast-forward `main`, and
end the pass with a LOCAL STATE table for all five workspace repositories.

The prompt arrived truncated mid-assertion. The pass stopped at that point,
under PLAN-PROTOCOL's file-supply rule, and reported the gap; the operator
resent from the truncation point.

## Done

- `plans/0040-flow-docs/accept.Tests.ps1`, the supplied test verbatim. Red
  first at Passed=0 Failed=11 Total=11, green at the close at Passed=11
  Failed=0.
- **LEDGER 47, probed rather than read.** `New-SplatProbeFixture.ps1` builds a
  two-parameter-set module whose examples follow the house splat standard with
  the dash form absent; `Invoke-SplatProbe.ps1` runs `Help.Tests.ps1`'s
  set-coverage assertion against it. `splat-coverage.txt` records
  `SPLAT EXAMPLE: passes as shipped`. Nothing under `evals/` changed;
  `cases-defined` stands at 41.
- `decisions/0015-falsifying-against-a-red-target.md`, and a PORTABLE paragraph
  in `method/METHOD.md`'s falsification section citing it.
- `docs/diagram/flow-graph.json` — 39 nodes, 49 edges, five layers carried in
  `scope`. `tools/diagram/Build-Diagram.ps1` renders it to
  `docs/diagram/flow.html` through PSGraphRenderToHtml `v0.1.0` and
  PSGraphRender `v0.13.0`, materialised from their tags with `git archive` and
  version-checked after import.
- README gains *The flow*: the hand-mirrored Mermaid block, a 39-row link map,
  and a statement of which rendering is authoritative. `eleven chapters` became
  `twelve`.
- `prompts/` — `README.md`, `project-context-template.md`, `first-module.md`,
  `new-feature.md`, `release.md`, `troubleshoot.md`.
- `docs/creating-an-agent/11-your-first-module.md`, listed in chapter 00.
- `docs/design/hybrid-modules.md`.
- `PLAN-PROTOCOL.md` gains *Sync and handoff*; `docs/creating-an-agent/01`
  closes on *Why the director stays human-paced*.
- `.gitattributes` gains `*.html text eol=lf`.
- Checks: `Compare-Mermaid.ps1` and its falsification harness, `Test-Links.ps1`,
  and `verify.ps1`.

## Why

**The diagram is a producer graph rather than a drawing.** This repository
ships a `producer-contract` skill telling other people to emit against a schema
they do not own and to run the consumer's battery over their output. Doing that
to its own diagram costs one script and makes the claim checkable: seven battery
cases run before every render.

**Rejected: `-EditorLinkMap`.** It emits `vscode://file/<absolute path>`, which
is right for a producer whose reader owns the disk. This artifact is committed
and read by strangers, so the repo-relative path rides in each node's `doc`
attribute and the README's link map is what makes it clickable.

**Rejected: shipping `click` directives.** The probe could not establish that
they work, and thirty-nine untested click lines in a README are a claim about
GitHub that nobody here has checked. The link map is better navigation anyway —
it survives in a plain-text diff and in every renderer.

**Rejected: generating the Mermaid block from the JSON.** It would have made the
prompt's spot-check 4 trivially true and deleted the only thing it tests. The
mirror is written by hand and then compared, and the comparison is broken four
ways to show it can fail.

**Rejected: two edges that would have drawn backwards.** `you --starts-at-->
new` is true and renders as an arrow from `new` up to `you`, in a diagram where
every other upward arrow means *and then this*. The fact moved into the node's
attributes and the edge went.

**Rejected: normalising line endings inside `-Check`.** A comparison taught to
ignore a difference stops being able to see that class of difference again. The
artifact was fixed instead.

## Measured

- Acceptance: `Passed=0 Failed=11 Total=11` red
  (`plans/0040-flow-docs/accept-red.txt`), `Passed=11 Failed=0 Total=11` green
  (`accept-green.txt`).
- LEDGER-47 probe: `DASH FORM IN FIXTURE: 0 occurrence(s)`,
  `CONTAINERS FAILED: 0`, `PASSED=1 FAILED=0 SELECTED=1`
  (`plans/0040-flow-docs/splat-probe.txt`).
- Graph: 39 nodes, 49 edges, 5 scopes, 11 kinds — re-derived from the rendered
  page's own payload (`NodeCount: 39`, `EdgeCount: 49`, `ScopeCount: 5`,
  `KindCount: 11` in `docs/diagram/flow.html`).
- Producer battery: `Passed=7 Failed=0 Total=7`
  (`plans/0040-flow-docs/diagram-build.txt`).
- Mirror: `nodes: mermaid 39, json 39 / edges: mermaid 49, json 49 / layers:
  mermaid 5, json 5`, agreeing on ids, labels, layer membership and edges
  (`plans/0040-flow-docs/verify-run.txt`).
- Mirror falsification: 1 control green, 4 breaks red
  (`plans/0040-flow-docs/mermaid-falsification.txt`).
- Links: `links resolved: 245`, `DEAD LINKS: 0`, `39 rows for 39 nodes`
  (`plans/0040-flow-docs/linkcheck.txt`).
- Verify, from a fresh clone: `checks: 6, failed: 0`
  (`plans/0040-flow-docs/verify-run.txt`).
- `git diff v1.2.0..HEAD -- skills/ commands/ .claude-plugin/` — empty.
- `cases-defined`: 41, unchanged.

## Learned

**LEDGER 47 was already repaired, and only running it could say so.** The
assertion's own comment says it matches both syntaxes. Reading that comment is
exactly what item 47 forbids as proof, so the probe was built anyway. The two
agreed, which is the outcome nobody would have checked.

**A `ValidateSet` can promise something the consumer never agreed to.**
PSGraphRenderToHtml v0.1.0 validates `-ColorBy` against
`{ structure, scope, type }`; PSGraphRender v0.13.0 accepts
`{ structure, dependents, blastRadius, dependencies, reach }`. One member in
common. `type` is accepted by the validator, warned about by the renderer, and
silently downgraded. Numbered 50.

**The same difference arrived twice wearing different clothes, and both times
with the least diagnosable symptom available.** `flow.html` had no line-ending
rule, so a Windows checkout gave CRLF against the renderer's LF; then
`Set-Content` appended the platform's newline, leaving a one-byte difference at
the end of the file. Both produced identical line counts, no differing line, and
a reporter with nothing to point at. **Neither was visible from the working
tree** — `-Check` passed there throughout, and they surfaced only because
`verify.ps1` clones. Numbered 51.

**A supplied verbatim insertion broke the assertion written to check for it.**
The stranded-branch paragraph wrapped between "not an" and "ancestor"; the
assertion matches `not an ancestor of.*main` against the raw file, and `.` does
not cross a newline. Hazard 8, arriving inside the fix for a different gap.
Numbered 52.

**Two decision records disagree about who may move the harness `main`.** 0009
grants it to the agent in terms; 0013 says it is operator-only and justifies
that by enumerating 0008 and 0010 — omitting 0009, the decision that grants it.
The pass followed 0009 and the prompt, and is flagging rather than settling.
Numbered 49, STANDING.

**A Mermaid node id beginning `end` collides with the subgraph terminator.**
`end-user` was renamed `you`, in both renderings.

**GitHub Mermaid clicks could not be settled from a terminal, and the attempt
was still worth it.** It established the render path — a cross-origin frame fed
by postMessage, `securityLevel: "antiscript"`, click URLs sanitised rather than
dropped — and therefore that a *relative* click target cannot resolve to this
repository under any security level. That much is settled; the rest is not, and
is recorded as unproven.

**The prompt arrived truncated, and stopping was correct.** The acceptance test
was specified verbatim and arrived cut mid-assertion. Inventing the remainder
would have produced a test the operator did not write, and the file-supply rule
exists for exactly that.

## Capability

The repository can now render its own architecture from a machine-readable
source through the ecosystem's own producer contract, and prove the two
renderings agree — `Build-Diagram.ps1` for the interactive document,
`Compare-Mermaid.ps1` for the README mirror, both re-run by `verify.ps1` from a
fresh clone. A pass that changes the flow can no longer leave the picture
behind without failing a check.

A stranger can now build a module with this plugin from paste-able text rather
than by reading the method: six documents in `prompts/`, walked end to end by
chapter 11.

Every pass now ends by returning the operator's workspace to inspectable truth
and printing a LOCAL STATE table, and the absence of that table is defined as
*not done* rather than as a matter of taste.
