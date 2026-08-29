# PASS 0020 — Run 003: the plugin-off baseline

Tier: **full** (as stated in the prompt, and correct: the pass produces a
scored measurement line and commits an acceptance test and a verify script).

## 1. Prompt

```
# PASS 0020 — Run 003: the plugin-off baseline
Tier: full

## Repositories
- `AI.Agent.Claude.PowerShellModuleBuilder` — branch `pass-0020-baseline-off`
  cut from the pushed tip of `pass-0019-history-unification`. Record that
  SHA in the plan as the pinned HEAD; if `origin/main` does not equal it,
  stop (decision 0009 says they now move together).
- `PSAzureDevOpsGraph` — receives branch `run-003-baseline-off` only.
  Measurement line: no tag, no `main`, per decision 0008's amendment.

## What this run is
The number that answers "does the plugin earn its keep": the same seed and
brief, scored the same way, with the plugin's content unread. It is honest
only if Phase 1 stays blind. A bad score is the desired data as much as a
good one — 12/12 here would mean the model already knew, and that is worth
knowing before three reliability runs are spent.

## Phase 1 read-allowlist — until the built module is pushed
`evals/functional/seed/`, `evals/functional/BRIEF.md`
(blob must be `93c5cec3299da0ac27d3aea67f4fbcf0000001ec` — assert it),
`evals/functional/fixture/graph.schema.json`, this prompt, your plan file,
and the run directory. Explicitly forbidden until the gate: `skills/`,
`commands/`, `cases.md`, `expected-graph.json`, `fixture/repos/`, every
test and script under `evals/`, `runs/`, `plans/`, `journal/`,
`decisions/`, `method/`, and all of PSModuleGraph. Fixture coordinates so
nothing must be discovered: org `jlbalmerjr1`, project `ClaudeTesting`,
project-scoped REST only (PAT lacks vso.profile). Any read outside the
allowlist, and any Phase 1 choice traceable to this prompt's Phase 2 text
rather than the brief, goes in Deviations, named. Wall-clock cap per graph
command: 5 minutes; a hang is killed and recorded.

## Preconditions
Tree clean (rule 13 if not); branch created; oracle blob
`bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc` (assert via ls-tree without
opening the file); `$env:AZDO_PAT` set (report "set");
`scratch/runs/003-baseline-off` and remote branch `run-003-baseline-off`
both absent; tools recorded.

## Acceptance test — red first
Same shape as run 002's, created at
`plans/0020-baseline-off/accept.Tests.ps1`: run README exists with
`plugin: none (baseline-off)`, `target-sha:`, `seed-sha:`, `brief-sha:
93c5cec…`, `phase-1-minutes:`, `build:` line, `conformance: N / N`,
`functional: N / 12`; `graph.json`, `diff.txt`, `003.html`, `findings.md`
present. Write it, run it, report red.

## Plan
- [ ] 1. Acceptance red.
- [ ] 2. `Reset-Target.ps1 -Destination scratch/runs/003-baseline-off`.
      Timestamp: Phase 1 starts.
- [ ] 3. Build the module from seed and brief alone, to your own best
      practice. Commit at natural milestones. One attempt — no
      score-and-retry loop exists in a baseline; you stop when you judge
      the brief satisfied.
- [ ] 4. Export the graph, commit, push `run-003-baseline-off`, record the
      SHA. Timestamp: Phase 1 ends. **Gate.**
- [ ] 5. Score: `./build.ps1` if present (absence recorded as
      `build: no build script`); `Invoke-Conformance.ps1` all four tags;
      `Compare-Graph.ps1`. No fixes, no re-runs — the first scores stand.
- [ ] 6. `runs/003-baseline-off/`: README (fields above, plus "Baseline
      caveat: session opened with this prompt only, skills unread; the
      builder is still the same model family that wrote the skills"),
      `graph.json`, `diff.txt`, `003.html` via Render-Graph, `findings.md`
      sorted by mechanism with observed/inferred marked, and every failed
      case named.
- [ ] 7. Acceptance green. Plan, verify script, journal. Push the pass
      branch; fast-forward harness `main` per decision 0009.

## Named spot-checks — verify.ps1 re-derives
1. Fresh clone of `run-003-baseline-off`: import result and (if present)
   `build.ps1` exit match the record.
2. `Invoke-Conformance.ps1` re-run equals the committed result.json.
3. `Compare-Graph.ps1` on committed `graph.json` reproduces `diff.txt` and
   the score; with PAT, regenerate live and compare; without, loud skip.
4. Oracle blob unchanged; `evals/` diff this pass is empty.
5. PAT scan across run record and module clone: zero matches.

## Constraints
Azure DevOps read-only, never queue/create/modify/delete; the empty
`ClaudeTesting` repo untouched (case 12). PAT never echoed/written/in a URL.
No assertion weakened. No tag, no target `main` — measurement line.

## Report back
Run SHAs, three scores with failed cases named, Phase 1 wall-clock, count
of allowlist breaches (zero or itemised), findings count by mechanism.
```

## 2. Preconditions

| Precondition | Command | Output |
|---|---|---|
| Tree clean | `git status --porcelain` | empty |
| Pinned HEAD = pushed tip of 0019 | `git rev-parse pass-0019-history-unification` | `42c717b98ba048a1c8c134a480e308c310c19e9d` |
| `origin/main` equals it (decision 0009) | `git rev-parse origin/main` | `42c717b98ba048a1c8c134a480e308c310c19e9d` — equal, pass proceeds |
| Branch created | `git checkout -b pass-0020-baseline-off 42c717b98…` | `Switched to a new branch` |
| BRIEF blob | `git ls-tree pass-0019-history-unification -- evals/functional/BRIEF.md` | `93c5cec3299da0ac27d3aea67f4fbcf0000001ec` — asserted |
| Oracle blob, file never opened | `git ls-tree -r pass-0019-history-unification -- evals/functional \| grep bd7b3c4f…` | `bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc  evals/functional/fixture/expected-graph.json` |
| `$env:AZDO_PAT` | `if ($env:AZDO_PAT) {'set'}` | **set** (value never printed) |
| `scratch/runs/003-baseline-off` absent | `Test-Path` | absent |
| Remote branch absent | `git ls-remote --heads origin run-003-baseline-off` | no match; remote held only `main`, `run-002-first-build`, tags `v0.1.0`, `v0.2.0` |

Local `main` was at `51e2131626e9c424ccce3e7abdeace840ee66c57`, behind
`origin/main`. It is fast-forwarded in task 7 per decision 0009.

## 3. Environment

- pwsh **7.6.5**
- Pester **6.1.0** for the module and conformance suites (build.ps1 requires ≥5.0);
  **5.7.1** pinned for the acceptance test
- PSScriptAnalyzer present
- OS: Microsoft Windows NT **10.0.26200.0**
- Claude Code: VS Code extension; model Claude Opus 5 (1M context)
- Branch `pass-0020-baseline-off`, HEAD at start `42c717b98ba048a1c8c134a480e308c310c19e9d`

## 4. Acceptance test — red first

`plans/0020-baseline-off/accept.Tests.ps1`, written from the prompt's field
list. Run 002's equivalent lives under `plans/`, which the Phase 1 allowlist
forbids, so it was not opened; the prompt enumerates every field, so no
assertion was lost.

```
Invoke-Pester -Path 'plans/0020-baseline-off/accept.Tests.ps1'
Tests Passed: 0, Failed: 15
```

All fifteen failed for absence of the run record — six on missing files, nine
matching against an empty README string. Red before any work began.

## 5. Tasks

- [x] **1. Acceptance red.** 0 passed / 15 failed, output above.
      File: `plans/0020-baseline-off/accept.Tests.ps1`.

- [x] **2. Reset-Target.** `./evals/functional/Reset-Target.ps1 -Destination scratch/runs/003-baseline-off`,
      exit 0. Copied 4 files, seed commit `dee5c6980cd8c6f32cbdcead63452aa094c0ad6b`
      (`.gitattributes`, `.gitignore`, `LICENSE`, `README.md`). The script was
      run without being read — it is under `evals/`.
      **Phase 1 started 2026-08-29T09:44:07Z.**

- [x] **3. Blind build.** Inputs read: `evals/functional/BRIEF.md`,
      `evals/functional/fixture/graph.schema.json`, the four seed files. Built
      in three commits on `run-003-baseline-off`:

      cfd6a95  Module skeleton: manifest, loader, YAML parser, path rules, REST client
      d29cdf6  The seven commands
      d852abc  Tests, build script, README, and the fixture graph

      13 module files, 7 exported commands, 61 tests. `./build.ps1 -Task All`
      exit 0, PSScriptAnalyzer clean.

      Four defects found and fixed inside Phase 1, all evidenced in the
      transcript: `resources:` blocks silently dropped in nine files (the `@()`
      platform bug, mechanism 5 of findings.md); `-f` inside a `.NET` method
      call binding its commas to the method; an absolute `-Path` joined onto the
      working directory; and a credential-file pattern matching `AzDoPath.ps1`.

- [x] **4. Export, push, gate.** Graph regenerated after the fixes, 17.0 s
      against a 300 s cap. 50 nodes, 52 edges, 2 unresolved, 0 errors;
      `Test-Json -Schema fixture/graph.schema.json` → **True**.
      Pushed `refs/heads/run-003-baseline-off` only — no tags, target `main`
      untouched.
      **Run SHA `d852abcff0efae39978000f48190c7240c5418bd`.**
      **Phase 1 ended 2026-08-29T10:16:44Z — 32.6 minutes.** Gate passed.

- [x] **5. Score.** First results, no fixes and no re-runs.

      | Score | Command | Artifact | Result |
      |---|---|---|---|
      | build | `./build.ps1 -Task All` | stdout, exit code | exit **0**, 61/61, analyzer clean |
      | conformance | `Invoke-Conformance.ps1 -Tag Universal,Repository,HouseStyle,RequiresBuild` | `runs/003-baseline-off/conformance-result.json` | **39 / 55** (70.91%) |
      | functional | `Compare-Graph.ps1` | `runs/003-baseline-off/compare-report.json` | **0 / 12**, 29 differences |

      Failed cases, from `compare-report.json` `.cases`: case-01, case-02,
      case-03, case-04, case-05, case-06, case-07, case-08, case-09, case-10,
      case-11, case-12.

      Differences by kind, from `.countsByKind`: `wrongNodeAttribute` 15,
      `wrongEdgeAttribute` 10, `wrongEdgeTarget` 2, `extraNode` 1, `extraEdge` 1,
      **`missingNode` 0, `missingEdge` 0**.

- [x] **6. Run record.** `runs/003-baseline-off/`: `README.md` (all required
      fields plus the baseline caveat), `graph.json`, `diff.txt` (Compare-Graph
      verbatim), `003.html` (Render-Graph: 50 `data-node-id`, 2
      `data-unresolved-id`, no `http`), `findings.md` (five mechanisms, each
      marked observed or inferred, every failed case named),
      `compare-report.json`, `conformance-result.json`.

- [x] **7. Close.** Acceptance green (below), plan, `verify.ps1`, journal entry
      `journal/0020-baseline-off.md`. Pass branch pushed; both `main`s
      fast-forwarded per decision 0009.

## 6. Acceptance test — green

```
Invoke-Pester -Path 'plans/0020-baseline-off/accept.Tests.ps1'
Tests Passed: 15, Failed: 0
```

## 7. Command transcript

```powershell
# --- preconditions -------------------------------------------------------
git rev-parse --abbrev-ref HEAD; git status --porcelain
git rev-parse pass-0019-history-unification; git rev-parse origin/main; git rev-parse main
git ls-tree pass-0019-history-unification -- evals/functional/BRIEF.md
git ls-tree -r pass-0019-history-unification -- evals/functional | grep -i bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc
if ($env:AZDO_PAT) { 'AZDO_PAT: set' }
Test-Path scratch/runs/003-baseline-off
git -C ../PSAzureDevOpsGraph ls-remote --heads origin run-003-baseline-off
$PSVersionTable.PSVersion; git --version; Get-Module -ListAvailable Pester

# --- task 1: acceptance red ---------------------------------------------
git checkout -b pass-0020-baseline-off 42c717b98ba048a1c8c134a480e308c310c19e9d
Import-Module Pester -RequiredVersion 5.7.1 -Force
Invoke-Pester -Path 'plans/0020-baseline-off/accept.Tests.ps1' -PassThru -Output Detailed
git add -A; git commit -m "Pass 0020 step 1: acceptance test red before the baseline build"

# --- task 2: Phase 1 opens ----------------------------------------------
(Get-Date).ToUniversalTime().ToString('o')          # 2026-08-29T09:44:07.3501587Z
./evals/functional/Reset-Target.ps1 -Destination 'scratch/runs/003-baseline-off'

# --- task 3/4: blind build, in scratch/runs/003-baseline-off -------------
./build.ps1 -Task All                                # exit 0, 61/61, analyzer clean
Start-Job { Get-AzDoPipelineDependencyGraph -Organisation 'jlbalmerjr1' -Project 'ClaudeTesting' |
            Export-AzDoPipelineDependencyGraph -Path './graph.json' }
Wait-Job -Timeout 300                                # 17.0 s
Get-Content ./graph.json -Raw | Test-Json -Schema (Get-Content ../../../evals/functional/fixture/graph.schema.json -Raw)
git add -A; git commit                               # cfd6a95, d29cdf6, d852abc
git branch -m main run-003-baseline-off
git remote add origin https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
git push origin refs/heads/run-003-baseline-off:refs/heads/run-003-baseline-off
git rev-parse HEAD                                   # d852abcff0efae39978000f48190c7240c5418bd
(Get-Date).ToUniversalTime().ToString('o')           # 2026-08-29T10:16:44Z  -> 32.6 min

# --- task 5: scoring -----------------------------------------------------
./build.ps1 -Task All; $LASTEXITCODE                 # 0
./evals/conformance/Invoke-Conformance.ps1 `
    -Path './scratch/runs/003-baseline-off' `
    -Tag Universal,Repository,HouseStyle,RequiresBuild `
    -ResultPath './runs/003-baseline-off/conformance-result.json'
                                                     # 39/55 (70.91%)
Copy-Item './scratch/runs/003-baseline-off/graph.json' './runs/003-baseline-off/graph.json'
pwsh -NoProfile -File './evals/functional/Compare-Graph.ps1' `
    -CandidatePath './runs/003-baseline-off/graph.json' `
    -ReportPath './runs/003-baseline-off/compare-report.json'
                                                     # exit 1, 29 differences, 12 cases failed

# --- task 6: run record --------------------------------------------------
pwsh -NoProfile -File './runs/Render-Graph.ps1' `
    -GraphPath './runs/003-baseline-off/graph.json' `
    -OutputPath './runs/003-baseline-off/003.html' `
    -Title 'Run 003 - baseline, plugin off'          # 50 nodes, 52 edges, 2 pseudo

# --- task 7: close -------------------------------------------------------
Invoke-Pester -Path 'plans/0020-baseline-off/accept.Tests.ps1'   # 15/0
pwsh -NoProfile -File './plans/0020-baseline-off/verify.ps1'
git push origin pass-0020-baseline-off
git branch -f main pass-0020-baseline-off; git push origin main
```

## 8. Diff summary

Not required at full tier; the acceptance test and verify script stand in its
place. `evals/` is untouched this pass, which `verify.ps1` asserts.

## 9. Verify script

`plans/0020-baseline-off/verify.ps1`. Not reproduced here: it is too long for a
second copy to stay honest, and a fenced excerpt that drifts from the committed
script teaches a reader nothing about either (PLAN-PROTOCOL §9).

It re-derives rather than reads, and never parses this plan. It runs the five
spot-checks the prompt named, by name:

1. **Fresh clone of `run-003-baseline-off`** into a temp directory, asserts the
   run SHA, imports the module and asserts the seven exported commands, then
   runs `./build.ps1 -Task All` and compares its exit code with the recorded 0.
2. **Conformance re-run** with all four tags against the fresh clone, compared
   against the committed `conformance-result.json` — Passed, Failed, CasesRun
   and ScorePct must all agree.
3. **Compare-Graph re-run** on the committed `graph.json`, asserting the same
   29 differences, the same counts by kind and the same twelve failed cases;
   then, when `$env:AZDO_PAT` is set, regenerating the graph live from the
   fixture and comparing it to the committed one. Without a PAT it prints a
   loud SKIP and does not quietly pass.
4. **Oracle blob unchanged** (`bd7b3c4f…` via `git ls-tree`, without opening the
   file) and `git diff --stat 42c717b98… HEAD -- evals/` empty.
5. **PAT scan** across the run record and the fresh module clone: zero matches,
   including a scan for the live token's own value when one is present.

It exits 0 only when every check agrees, and prints the name of any that did not.
It uses `scratch/` for nothing.

## 10. Deviations

### 1. Filenames under `fixture/repos/` were disclosed — one allowlist breach

While asserting the oracle blob I ran

```
git ls-tree -r pass-0019-history-unification --name-only -- evals/functional
```

to locate `bd7b3c4f…`. That printed the *names* of every tracked file under
`evals/functional`, including `fixture/repos/`, which the allowlist forbids. No
file content was read, then or later, and no name was used to look anything up.

What the names disclosed, stated plainly so the score can be discounted for it:

- the four fixture repo names — `pipelines-main`, `templates-shared`,
  `templates-platform`, `consumer-app`;
- ten `p01`–`p10` definition YAMLs, with `p07a`/`p07b` splitting one case;
- template names `cycle-a`/`cycle-b`, `chain-a`/`b`/`c`,
  `diamond-shared`/`diamond-leaf` — which telegraph that cycles, chains and
  diamonds are tested;
- `steps-build.yml` existing at *both* `pipelines-main/pipelines/templates/`
  and `pipelines-main/templates/` — which telegraphs the relative-path versus
  root-anchored disambiguation.

The last two are genuinely informative and I cannot un-know them. Cycle safety
and correct relative-path anchoring are things any competent graph walker needs,
and the brief states the two-rule problem in its own words ("resolve by two
different rules depending on whether an `@alias` is present"), so I believe both
would have been built regardless — but I cannot prove a counterfactual, and the
run's two strongest correctness results are in exactly those two areas. The
breach is recorded rather than argued away.

A cheaper probe that would not have leaked:

```
git rev-parse pass-0019-history-unification:evals/functional/fixture/expected-graph.json
```

That is what a later pass should use, and it is worth putting in the prompt
template so the next baseline does not repeat this.

### 2. `PLAN-PROTOCOL.md` is on neither list, and was deferred

It is not on the allowlist and not on the forbidden list. Reading it during
Phase 1 could not have leaked module design, but the rule is that anything
outside the allowlist is named here, so I deferred it instead and wrote a
working plan from the prompt's own checklist. It was read after the gate and
this plan conformed to it then. No content was lost; the plan file simply
reached its required shape late.

### 3. Run 002's acceptance test was not read

`plans/` is forbidden in Phase 1, so "same shape as run 002's" was satisfied
from the prompt's enumeration of the fields instead. No assertion was dropped.
I added two beyond the list — `graph.json` parses as JSON, and the README
carries the baseline caveat — which strengthen it.

### 4. The build script is `build.ps1`, and the prompt's step 5 anticipated it

Step 5 says "`./build.ps1` if present (absence recorded as `build: no build
script`)". A blind builder reading that line could infer that the house expects
a root build script named exactly `build.ps1`. I had already chosen that name
from the seed's `.gitignore` (which ignores `output/` and `testResults/`, both
of which a build produces) before re-reading step 5, so I do not believe the
choice was contaminated — but the prompt does contain the hint, and the rule
asks for Phase 1 choices traceable to Phase 2 text to be named. Recorded.

It scored as a miss anyway: the house build file is
`PSAzureDevOpsGraph.build.ps1`, an Invoke-Build file.

### 5. The conformance suite scores five passes against a file that does not exist

Not asked about; found while reading the score, then traced to its cause.

`House style: build file` reports `has a build file named
PSAzureDevOpsGraph.build.ps1` as **failed**, and then reports `declares the task
Clean`, `Lint`, `Build`, `Test` and `PreTag` as five **passes** — against the
file it has just established is absent. `result.json` records it as
`declares the task <_>; Ran=5; Passed=5; Failed=0`. My `build.ps1` contains no
task named `Lint` or `PreTag` at all, so these are not near-misses.

The mechanism is a null-versus-empty slip, confirmed rather than guessed:

```powershell
# Conformance.Tests.ps1:504
@(Get-BuildTaskCommand -Path $BuildFile -TaskName $_).Count |
    Should -BeGreaterThan 0 -Because 'a commented-out task is not a task'
```

`Get-BuildTaskCommand` returns `$null` when the file will not parse
(`if ($errors) { return $null }`, line 276) — and a path that does not exist is
one such case. In PowerShell `@($null)` is a one-element array whose element is
`$null`:

```
@($null).Count        ->  1
@($null).Count -gt 0  ->  True
```

So the assertion passes on a missing build file. `Should -Not -BeNullOrEmpty`,
or comparing against `$null` before wrapping, would close it.

The comment above the assertion says it was hardened once already, from a regex
that a block comment could satisfy, to a structural AST check. The hardening is
sound; the null guard did not come with it.

This inflates every candidate that ships no build file by five cases out of 55 —
about nine points. **This run's 39/55 is flattered by it**, and so is any run
002 number scored by the same code. Two later assertions in the same block fail
correctly (`Get-BuildTaskBody` throws on the null), so the block disagrees with
itself rather than being uniformly wrong.

I did not change it. This pass must not touch `evals/`, and altering a grader
mid-measurement would break comparability with run 002 — decision 0003's whole
subject. Flagged for its own pass. If it is fixed, run 002's and run 003's
conformance numbers both need recomputing before they are compared with each
other or with anything later.

### 6. `Get-Module -ListAvailable Pester` resolves to 6.1.0, not 5.x

`build.ps1` asks for `-MinimumVersion 5.0` and got Pester 6.1.0; the conformance
suite ran on 6.1.0 too. The acceptance test is pinned to 5.7.1 explicitly. No
failure resulted, but the module's tests and the graders are running on a
different major version from the one the acceptance test pins, and nothing in
the harness pins either. Worth a decision.

### 7. A platform defect that will affect every run on this machine

On pwsh 7.6.5, `@($x)` throws `ArgumentException: Argument types do not match`
for any `System.Collections.Generic.List[object]`. It silently dropped every
`resources:` block in nine fixture files before it was caught. Full evidence in
`runs/003-baseline-off/findings.md`, mechanism 5. This belongs in `method/`
rather than in one run's record, since any future run here can hit it.

## 11. Cost

- Wall-clock, whole pass: **2026-08-29T09:36Z → 2026-08-29T10:47Z, ≈71 minutes**,
  of which Phase 1 (the blind build) was **32.6 minutes**.
- Build invocations: **5** (`build.ps1 -Task All`), of which the first four were
  during Phase 1 development and the fifth is the recorded score.
- Graph exports against the live fixture: **3** (two during development, one
  recorded), each inside the 300 s cap — 15.6 s, 14.0 s, 17.0 s. None killed.
- Conformance suite runs: **1** (55 cases).
- Compare-Graph runs: **1**.
- Acceptance test runs: **2** (red, green).
- Azure DevOps REST calls: read-only throughout; no write, no queue, no delete.

No token count: the agent cannot measure one from inside the session, and this
project does not carry numbers without an artifact behind them.
