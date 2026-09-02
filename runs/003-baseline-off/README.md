# Run 003 — baseline, plugin off

The control for the plugin: the same seed and the same brief as run 002, scored
the same way, with the plugin's content unread throughout Phase 1.

    plugin:            none (baseline-off)
    target-sha:        d852abcff0efae39978000f48190c7240c5418bd
    seed-sha:          dee5c6980cd8c6f32cbdcead63452aa094c0ad6b
    brief-sha:         93c5cec3299da0ac27d3aea67f4fbcf0000001ec
    harness-sha:       42c717b98ba048a1c8c134a480e308c310c19e9d
    phase-1-minutes:   32.6
    build:             ./build.ps1 -Task All — exit 0, 61/61 tests, analyzer clean
    conformance:       39 / 55
    functional:        0 / 12

Target branch: `run-003-baseline-off` in `PSAzureDevOpsGraph`. No tag, no
target `main` — this is a measurement line, per decision 0008's amendment.

## Scores

**Conformance 39 / 55 (70.91%)**, all four tags
(Universal, Repository, HouseStyle, RequiresBuild). Sixteen failures, all
house-convention: the build file's name and shape, the generated psm1, the two
missing root files, one-function-per-file, and three exported commands no test
invokes.

**Functional 0 / 12.** Every case failed:
case-01, case-02, case-03, case-04, case-05, case-06, case-07, case-08,
case-09, case-10, case-11, case-12.

The score is 0, and the shape of the 29 differences is the actual finding:

| Kind | Count |
|---|---|
| wrongNodeAttribute | 15 |
| wrongEdgeAttribute | 10 |
| wrongEdgeTarget | 2 |
| extraNode | 1 |
| extraEdge | 1 |
| **missingNode** | **0** |
| **missingEdge** | **0** |

Nothing is absent. The graph has every node and every edge the oracle has; it
records some of them differently. Fifteen of the differences are one omitted
property — `repo` on `pipeline` nodes — and because the case tags live on
those nodes, that single omission fails all twelve cases on its own.

The dependency computation itself held up: the relative-versus-aliased anchoring
rules resolved to the right files, the cycle terminated, the diamond collapsed to
one node with two in-edges, and the missing-file case resolved to
`pipelines/templates/missing-steps.yml` in `pipelines-main` — the oracle's exact
repository and path, recorded under an id convention that could not match.

See [findings.md](findings.md) for the five mechanisms.

## Baseline caveat

The session was opened with the pass prompt only, skills unread; the builder is
still the same model family that wrote the skills. What reads as derivation from
the brief may in part be recall of the reasoning that produced the plugin. This
run cannot separate the two, and its result should not be read as though it
could.

## Blindness caveats

Added by pass 0033. The *Baseline caveat* above stands unchanged; this section
is additive and states which of the project's now-disclosed bounds apply to this
run specifically. See `evals/HARNESS.md` hazards 12 and 13.

**The fixture names its own cases, and this run read them.** Applies. The
`ClaudeTesting` YAML carries leading comments that name the cases and state what
each is for — *"Both exist, so the wrong answer is a wrong file rather than an
error"* and similar. Reading the fixture through the module is what the task
requires, so every run from 002 onward has read them, this one included. It was
recorded in no run record before 007 and has been true throughout. What it
plausibly explains is why this run's dependency traversal was largely right
while every output convention was wrong. **"Blind" here means the oracle, the
prior run records and the plugin were unread. It has never meant the fixture was
unread.** `ClaudeTesting` is frozen, so this bound is permanent for the AzDO
line.

**Prompt-borne oracle content.** Does not apply. This was the first plugin-off
measurement in the line and no prior AzDO first-shot mechanism list existed to
leak into its prompt.

**Scoring protocol.** Does not apply, and the evidence is in this run's own
result file. Pass 0033 found that four `RequiresBuild` assertions grade a
gitignored `output/` and so fail in a clone that was never built (LEDGER item
24). This run's conformance clone *was* built: `produced
output/<ModuleName>/<ModuleName>.psm1` **passes** in
[conformance-result.json](conformance-result.json). The 19/33 re-derived from
this run is a built-clone number and needs no correction.

**One consequence for run 007's comparison.** Run 007's record observes that 003
and 007 "scored identically on conformance at first shot — 19/33". Under a
single procedure they do not: 003's 19/33 is a built clone, 007's first-shot
19/33 was an unbuilt one, and 007's first shot re-derived built is **20/33**.
The two runs differ by one assertion, not zero. See
[plans/0033-honest-headline/rescore.txt](../../plans/0033-honest-headline/rescore.txt).

## Contents

| File | What |
|---|---|
| `graph.json` | The module's answer for the fixture. 50 nodes, 52 edges, 2 unresolved. Validates against `fixture/graph.schema.json`. |
| `diff.txt` | Compare-Graph output, verbatim. |
| `003.html` | Render-Graph rendering. 50 `data-node-id`, 2 pseudo-nodes, no network reference. |
| `findings.md` | Findings by mechanism, observed vs inferred. |
| `compare-report.json` | Structured difference report. |
| `conformance-result.json` | Conformance result. |

## Provenance

- Phase 1 (blind build): 2026-08-29T09:44:07Z → 2026-08-29T10:16:44Z, 32.6 min.
- Allowlist breaches: **1**, itemised in the plan's Deviations — a `git ls-tree`
  run to assert the oracle blob printed the *names* of files under
  `fixture/repos/`. No file content was read. What the names disclosed, and why
  it cannot be argued away, is recorded there.
- Azure DevOps was read-only throughout: the REST helper's method is `Get` and is
  not a parameter. The empty `ClaudeTesting` repository was enumerated and never
  written.
- No assertion was weakened, and no score was re-run after seeing it.
- Tools: pwsh 7.6.5, git 2.41.0.windows.1, Pester 6.1.0, Windows 10.0.26200.
