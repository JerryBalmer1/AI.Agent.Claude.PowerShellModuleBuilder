---
pass: 0011
title: Design the Azure DevOps fixture and its acceptance criterion
date: 2026-08-28
artifacts:
  - evals/functional/Fixture.Tests.ps1
  - evals/functional/BRIEF.md
  - evals/functional/AZDO-FIXTURE.md
  - evals/functional/fixture/expected-graph.json
  - evals/functional/fixture/graph.schema.json
  - evals/functional/fixture/cases.md
  - evals/functional/fixture/repos/ (30 YAML files)
  - runs/Render-Graph.ps1
  - runs/000-expected/000.html
  - plans/0011-fixture-design/plan.md
  - plans/0011-fixture-design/verify.ps1
---

# Pass 0011 — Design the Azure DevOps fixture and its acceptance criterion

## Asked

Design the Azure DevOps fixture for `PSAzureDevOpsGraph`, declare the graph it
represents, state ten functional test cases, and render the expected graph.
Write the acceptance test first and record it red before authoring any fixture
content. No network call, no Azure DevOps resource created, and the PAT not
read. Twelve tasks, six named spot-checks in `verify.ps1`, full tier.

## Done

- `evals/functional/Fixture.Tests.ps1`, 522 lines. Seven assertion groups plus
  an eighth added this pass; 317 cases. Carries a small strict block-YAML reader
  and a structural reference extractor, because there is no YAML parser in a
  fresh pwsh and `verify.ps1` may assume nothing but a clone.
- `evals/functional/fixture/repos/`, 30 YAML files across four repository
  directories — `pipelines-main` (21), `templates-shared` (3),
  `templates-platform` (3), `consumer-app` (3).
- `evals/functional/fixture/expected-graph.json`, 49 nodes and 51 edges, written
  by hand from the YAML rather than generated from it.
- `evals/functional/fixture/graph.schema.json`, draft-07, `additionalProperties:
  false` on both node and edge, plus two `if`/`then` clauses.
- `evals/functional/fixture/cases.md`, ten cases, each naming the specific wrong
  implementation it catches.
- `evals/functional/BRIEF.md` and `evals/functional/AZDO-FIXTURE.md`.
- `runs/Render-Graph.ps1`, `runs/README.md`, `runs/000-expected/000.html` and its
  README.
- `.gitignore` +3 lines; a four-pattern scan over all 75 committable files,
  reporting paths only.
- `plans/0011-fixture-design/plan.md` and `verify.ps1`, seven checks.

No network call was made. No Azure DevOps resource exists.

## Why

The fixture's case-1 discriminator was not built as specified, and the plan says
so. The prompt's example — `template: ../templates/x.yml` from `pipelines/` —
normalises to the same path whether it is resolved relative to the including
file or to the repository root, so it cannot separate the correct implementation
from the wrong one. What was built is a reference with no `../` and no `@alias`
whose two resolutions land on two files that **both exist** with different
contents. The wrong resolver does not error; it answers confidently and wrongly,
which is the only kind of wrong worth building a fixture to catch.

Case 10's two claims were split across two pipelines. A pipeline that does
`checkout:` of a second repository has a `resources.repositories` entry and is
therefore not isolated, so "orphan" and "checkout-only" cannot be the same
definition. `p10-orphan` carries the first and `x01-consumer-build` the second.

`checkout` edges were folded into assertion 6 although the prompt's wording
excludes them. As specified, the one edge case 10 depends on could have drifted
from the YAML unchecked. `definition` edges were left outside deliberately: they
are a claim about the Azure DevOps project rather than about a file's text, and
Pass 0012's read-back is what checks them.

Rejected: checking that any reference resolves to the right target.
`expected-graph.json` is a hand-written oracle, and an oracle checked by a
resolver is worth exactly what the resolver is worth. `verify.ps1` re-derives
case 4's resolution because the prompt named it; the other 43 edges rest on
hand-authoring, and the plan says so rather than implying more.

Rejected: reproducing `verify.ps1` as a fenced block in the plan, which
`PLAN-PROTOCOL.md` §9 requires. That would put a second copy of a 343-line
executable in the same commit as the first, which is the stale-expectation
hazard applied to the one artifact whose job is to disprove the plan.

## Measured

- Acceptance test, red first, before any fixture existed: **1 passed, 6 failed,
  1 container failed** (`plans/0011-fixture-design/plan.md` §4).
- Acceptance test, green: **317 passed, 0 failed** in 4.02s
  (`plan.md` §6). Per assertion: 4 / 2 / 80 / 104 / 31 / 30 / 61 / 5.
- `expected-graph.json`: **49 nodes** — 30 yaml, 15 pipeline, 4 repo — and
  **51 edges** — 21 template, 15 definition, 8 repositoryResource,
  3 pipelineResource, 2 unresolved, 1 extends, 1 checkout.
- 30 YAML files on disk, in bijection with the 30 `yaml` nodes.
- Falsification of the acceptance test: **10 probes, 7 breaks and 3 controls,
  0 wrong** (`plan.md` §5, task 1). Four of the seven breaks fire exactly one
  assertion.
- `runs/000-expected/000.html`: 41 017 bytes, **0** occurrences of `http://` or
  `https://`, 49 `data-node-id` and 2 `data-unresolved-id`.
- PAT scan: **0 matches in 75 committable files** (`plan.md` §5, task 10).
- `verify.ps1`: 7 checks, 38 assertions, all agree; proved capable of failing by
  2 probes (`plan.md` §9).

## Learned

**The red-first rule paid for itself in the first run.** With no fixture on
disk, `node ids are unique` passed — zero ids contain no duplicates. That is an
inert assertion, the third this project has found, and it was visible only
because the test ran against nothing before it ran against something. It now
carries a count guard. Written after the fixture, it would have been green from
birth and indistinguishable from a working assertion.

**A test green on its first real run has told you nothing yet.** 317 of 317
passed against a hand-authored 49-node graph, which is either two careful pieces
of authoring or a test that cannot fail. Ten probes separated the two. Both
defects they found were in the probes and the reporting rather than in the test:
one probe's filter matched a node line as well as the edge line it meant to
delete, so its red was four assertions wider than intended; and every failure
name expanded to `$null`, because Pester's `<Name>` expansion reads a *variable*
and the `-ForEach` items were `PSCustomObject`s. 317 tests with nine distinct
names, none of which said which file.

**A probe that silently fails to apply reports the control it never ran.** The
second `verify.ps1` probe used `($text -replace 'a', 'b' + "`n" + 'c')`, which
is a parse error — `-replace` takes two operands. The injection never happened,
`verify.ps1` printed "all checks agree", and reading only that line would have
recorded check 5 as falsified. The tell was the empty failure list, not the exit
code. This is hazard 6 in `evals/HARNESS.md` — a stale or unapplied expectation
turning a correct green into a confirmed control — arriving in a third distinct
form. It has now cost time in Pass 0009, in the K2 preflight, and here.

**Two documents in the repository asked for things that cannot both be done.**
The prompt's Constraints say the PAT is not read; task 10 asks for a scan of the
tree against the PAT's literal content, which requires reading it. The
constraint won, the check was not performed, and the gap is stated. Separately,
`PLAN-PROTOCOL.md` §11 requires a token count the agent has no way to measure —
flagged in Pass 0010, unchanged, and flagged again.

**The fixture is held to a subset of YAML, and that is a real limit.** No block
scalars, no flow collections, no anchors. Real pipeline YAML uses `script: |`
constantly. The reader is strict rather than lenient, so straying outside the
subset fails assertion 5 loudly instead of being mis-parsed — the safe
direction — but the fixture cannot grow a block scalar until the reader grows
first.

## Capability

- There is a fixture with a declared right answer: 30 YAML files and a
  49-node, 51-edge graph, in the repository, independent of Azure DevOps.
- The fixture and its oracle cannot drift apart unnoticed. Every reference in
  every YAML file and every edge in the graph are compared in both directions,
  by two separately written extractors — a structural parser in the test and a
  line scanner in `verify.ps1` — so agreement between them is evidence.
- A functional acceptance criterion exists and is stated as separate from the
  conformance score, so "conforms" and "works" are two answers rather than one
  average.
- Ten named cases exist, each with the wrong implementation it catches, so a
  later module can be told which of them it fails rather than only that it is
  wrong.
- A graph — the oracle or any later run's — can be rendered to one
  self-contained HTML file with no network access at view time, and a cycle in
  it renders and terminates.
- Pass 0012 can create the Azure DevOps fixture from a written plan that lives
  in the repository, with its constraints, its creation order, its trigger
  hazard and its read-back checks stated before anything external happens.
