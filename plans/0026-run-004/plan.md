# Pass 0026 — Run 004, plugin on

Tier: **full**. The first of three consecutive complete plugin-on runs from
wiped state — the reliability bar. Nothing in the plugin or the instrument
changes; the executable output is a module in a second repository and a run
record here.

## 1. Prompt

The prompt as received is reproduced in the pass record kept with the operator's
conversation. Its protocol, verbatim in structure, is the eight-item list
executed below; the acceptance test it specified is committed unmodified at
`plans/0026-run-004/accept.Tests.ps1` and is quoted in §4.

## 2. Preconditions

| Precondition | Command | Result |
| --- | --- | --- |
| Session gate — this prompt first in a new session | inspection of the context | **held.** No file content, tool output or prior turn preceded it. The environment block carried commit *subject lines* only, which are repository metadata, not run-record prose. |
| Both trees clean (rule 13) | `git status --porcelain` in harness and target | both empty |
| Harness synced | `git fetch --prune; git pull --ff-only` | already up to date at `bc1a0da` |
| Target synced | `git fetch --prune; git pull --ff-only` | already up to date at `5fd814b` |
| **The pin** | `git diff --name-only f25d05d..main -- skills/ commands/ .claude-plugin/ evals/` | **empty.** Checked with `--name-only`, never `git diff`, so a non-empty result could not have printed oracle content into a blind session. |
| Landings since the pin | `git log --oneline f25d05d..main` | one commit, `bc1a0da`, touching `LEDGER.md` only — records-only, permitted |
| Oracle blob | `git ls-tree -r HEAD \| grep bd7b3c4f…` | `evals/functional/fixture/expected-graph.json`. Located, never opened. |
| Brief blob | same | `evals/functional/BRIEF.md` at `93c5cec…` |
| `$env:AZDO_PAT` | presence test only, never printed | **set** |
| `scratch/runs/004-plugin-on` absent | `Test-Path` | `False` |
| Remote branch `run-004-plugin-on` absent | `git ls-remote --heads origin` | absent |
| Memory directory | listing of filenames only | **empty.** No `MEMORY.md`, no memory files, so the vector backlog item 13 names was not live in this run. |

All preconditions held. No hard stop.

## 3. Environment

```
pwsh                7.6.5
Pester              6.1.0        (pinned RequiredVersion in the built module)
InvokeBuild         5.14.23
PSScriptAnalyzer    1.25.0
powershell-yaml     0.4.12
git                 2.41.0.windows.1
OS                  Microsoft Windows 10.0.26200 (Windows 11 Home)
model-version       claude-opus-5[1m]          <- the ladder's pin for 005/006
Claude Code         NOT OBSERVABLE from inside the session.
                    $env:CLAUDE_CODE_ENTRYPOINT = claude-vscode, recorded not compared.
session-identifier  b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db   (scratchpad UUID)
harness branch      pass-0026-run-004 from main
target branch       run-004-plugin-on, orphan root from Reset-Target
```

## 4. Acceptance test — red first

Committed verbatim as specified at `plans/0026-run-004/accept.Tests.ps1`.

Run before anything else: **0 passed, 10 failed.** Every assertion red, because
`runs/004-plugin-on/` did not exist. Green at start would have stopped the pass;
it was not green.

## 5. Tasks

### - [x] 1. Acceptance red

10/10 failing, committed and pushed at `dfac91a` before the clock started.

### - [x] 2. Reset-Target

`evals/functional/Reset-Target.ps1 -Destination scratch/runs/004-plugin-on`,
invoked without being read — it is under `evals/` and therefore outside the
Phase 1 allowlist. Orphan root `f613e4b`, four seed files.

**Phase 1 starts 2026-09-01T13:39:52-07:00.**

### - [x] 3. Build from seed + brief, following the plugin

Read in Phase 1, and nothing else: `evals/functional/seed/`,
`evals/functional/BRIEF.md`, `evals/functional/fixture/graph.schema.json`,
`skills/` (all 16 files), `commands/`, `.claude-plugin/`.

`commands/build.md` step 1 instructs reading
`evals/conformance/Conformance.Tests.ps1`. **That path is outside this run's
allowlist and was not read.** The instruction was declined rather than followed,
and the collision is recorded as finding F-6 rather than as a breach — the
conventions came from the skills alone.

Built: 7 public commands, 15 private helpers across `Rest/`, `Yaml/` and
`Graph/`, a committed dev loader, `build.ps1` + `PSAzureDevOpsGraph.build.ps1`
with Clean/Lint/Build/Test/PreTag, `PSScriptAnalyzerSettings.psd1` listing
`ParseError` explicitly, `Requirements.psd1`, an `about_` topic, README,
CHANGELOG, worklog, plan, and 118 tests across unit, private, quality, integration
and PreTag layers.

Three defects were found and fixed during the build, each recorded in
`findings.md`:

- **The coverage gate could not fail** (F-1). The build skill's `Test` task
  template omits `Run.PassThru`, so `$result` is `$null`, the gate compares
  `0 -lt ''`, and it passes every run. Observed printing `Line coverage: 0%
  (target %)` and exiting 0 while Pester had just reported 90.31%. Fixed in both
  `Test` and `PreTag`, then **falsified**: target raised to 99 against real
  coverage of 94.91%, build went red with exit 1, restored to 70.
- **`.GetNewClosure()` on the existence predicate** rebound it to a fresh
  dynamic module where module-private functions are invisible (F-7). It surfaced
  as the opaque `'break' or 'continue' escaped from your code` against a whole
  container; the skill's own prescription — call the code under test directly —
  produced the real error in one step.
- **Two regex backslashes eaten by a shell heredoc**, giving `-replace '\', '/'`.
  Both failed loudly at build time and were rewritten through a path that does
  not re-interpret content.

Committed at `2421740` and `a0b764e`.

### - [x] 4. Export the graph, push, record the SHA

Live fixture read through the module, read-only: **9.8 s** for 15 definitions and
38 file fetches, against a 5-minute cap. Nothing was killed. 49 nodes, 51 edges,
2 unresolved; validates against `graph.schema.json`.

The README's worked example had been written before the module ran, and two of
its three columns were wrong — the exact failure `powershell-module-docs` names
("an example that has never been run is a claim, and several will be wrong").
Replaced with the real rows.

Pushed `run-004-plugin-on` at **`9924bf7`**.

**Phase 1 ends 2026-09-01T14:13:16-07:00 — 33 minutes. Gate: allowlist lifts.**

### - [x] 5. Score — three parallel jobs, three transcripts

23.9 s wall clock. The conformance job cloned the pushed branch and built it
itself, so it could not race the build job's `Clean`; the three are genuinely
independent.

**First-shot lines, recorded before anything else happened:**

```
build:                   exit 0 | analyzer 0 | pester 110/110 | coverage 94.91% (target 70%)
conformance:             33 / 33 (cases-defined)   cases-run: 57   100%
functional (first-shot): 1 / 12      26 differences
```

### - [x] 6. Iterate — one of three allowed

26 differences grouped by mechanism before the number was reacted to, per
`producer-contract`: **four decisions, not 26 mistakes.** 15 × `repo` missing
from pipeline nodes, 8 × `alias` written where the contract wants silence,
2 × `reason` as a bare code, and **1** genuine defect — `repo:consumer-app`.

At first shot there were **0** `missingEdge`, **0** `extraEdge`, **0**
`wrongEdgeTarget` and **0** `wrongEdgeKind`. The dependency computation was right
first time; only the field conventions were wrong.

Iteration 1 at **`19837f9`**: four fixes, tests updated to the corrected
conventions, worklog rewritten because its stated reasoning was now wrong.

```
build:                   exit 0 | analyzer 0 | pester 111/111 | coverage 94.61% (target 70%)
conformance:             33 / 33 (cases-defined)   cases-run: 57   100%
functional (final):      12 / 12     0 differences
```

Nothing under `evals/` was touched at any point. No assertion was weakened.

### - [x] 7. Records

`runs/004-plugin-on/` mirroring run 003's format plus plugin-sha, model-version,
entrypoint, session-identifier, the iteration table, and both functional lines.
`004.html` rendered by `runs/Render-Graph.ps1`: 49 `data-node-id`, 2
`data-unresolved-id`, 0 http(s) references. `findings.md` carries eight findings
by mechanism.

### - [x] 8. Acceptance green, verify, LEDGER

Acceptance: **10/10**. Verify: **16 checks, 0 failed, 0 skipped, exit 0**;
`-FailCheck`: **23 checks, 0 failed** — every check demonstrated red.

## 6. Acceptance test — green

```
Tests Passed: 10, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

## 7. Verify script

`plans/0026-run-004/verify.ps1`, per decision 0004: SHA-pinned constants
(plugin, oracle blob, brief blob, seed tree, target commit, node/edge counts,
cases-defined, cases-run), `-FailCheck` probes, writes only under `scratch/`,
one exit code, and a loud skip if `AZDO_PAT` is absent.

It re-derives all five named spot-checks, and does so from a **fresh clone at the
pinned commit** rather than from the working tree, so no check can pass against
uncommitted state.

Two defects in verify itself were found and fixed before it was trusted:

- Under `pwsh -File` every argument is a literal, so `-Tag a,b,c,d` arrives as
  one value the `ValidateSet` rejects against a set whose text it exactly
  matches, and `-Tag a b c d` makes the last three positional. Switched to
  `-Command`.
- The credential scan fired on **documentation**: the README's
  `$env:AZDO_PAT = '<your token>'`, the `about_` topic, a test's deliberately
  labelled dummy, and verify's own probe literal. Scanning for the variable's
  *name* is not scanning for a credential. Rewritten to judge the assigned
  **value** — 20+ characters, letters and digits only — with the probe token now
  generated at runtime so the file contains no secret-shaped literal of its own.
  P3c asserts it still tolerates all four placeholders, so the tightening cannot
  drift into a check that fires on nothing.

## 8. Deviations

**Allowlist breaches: zero.**

One instruction was declined rather than obeyed: `commands/build.md` step 1
requires reading `evals/conformance/Conformance.Tests.ps1`, which this run's
Phase 1 allowlist forbids. Declining it is not a breach of the allowlist — it is
a collision between the plugin and the protocol, recorded as F-6, with a
consequence worth stating plainly: **the conformance score measures whether the
skills are a faithful proxy for the assertions, with the assertions unread.**

Two scoring-adjacent choices worth naming:

- The conformance job builds its own fresh clone. The prompt asks for three
  parallel jobs; `RequiresBuild` reads `output/`, which the build job's `Clean`
  deletes. Running them against one working tree would have been a race, and a
  conformance number produced from a half-deleted `output/` is not a number.
  This also discharges spot-check 1 as a by-product.
- `runs/004-plugin-on/004.html` is `Render-Graph.ps1`'s rendering, not the
  module's own HTML export, because that is what run 003's record format is. The
  module's own three exports are committed in the target repository under
  `artifacts/`.

## 9. Cost

Phase 1 (blind build) 33 minutes. Scoring 23.9 s + 23.3 s wall clock, three jobs
in parallel each time. One iteration. Live graph command 9.8 s against a
300 s cap.
