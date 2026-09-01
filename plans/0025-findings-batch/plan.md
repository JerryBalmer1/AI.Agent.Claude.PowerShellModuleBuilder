# Pass 0025 — Findings to skills, oracle repair, tf-002, stable denominator, LEDGER

Tier: **full** (the prompt says full; the pass agrees — it amends a producer,
an oracle and a conformance denominator, all executable behaviour).

## 1. Prompt

The prompt as received. **It arrived truncated**, ending mid-sentence inside
plan item 2. It is reproduced here exactly as received, truncation included,
because the protocol says verbatim and a tidied prompt is not auditable.

```
# PASS 0025 — Findings to skills, oracle repair, tf-002, stable denominator, LEDGER
Tier: full

## Repositories
- Harness — branch `pass-0025-findings-batch` from `main`
  (`fc27c53b066473d58d793470fb132feb388ac214`). Skills, conformance
  denominator, decision 0012, run tf-002 record, LEDGER.md.
- `PSTerraformGraph` — producer fix; branch `pass-0025-hasvalidation` from
  `main` (`05fb60d5286e99b302afbfaf5eee87c866ecd14c`); tag `v0.2.0`.
- AzDO `ClaudeTestingTerraform` — the case-3 repair commits, per decision
  0012 below, then re-frozen. `ClaudeTesting` untouched.
- ToHtml, PSGraphRender — read-only except README status/consumer lines if
  a claim changes. PSModuleGraph — never.

Standing rules apply: sync first (fetch-all parallel, ff-only, divergence/
dirty = hard stop per rule 13), push early and after every task group,
parallel by default with degree recorded, mains fast-forwarded per
decisions 0009/0010 (ancestry checked, never forced).

## Preconditions
Sync; SHAs above hold; trees clean; `$env:AZDO_PAT` set (report "set");
`plans/0025-findings-batch/` absent; PSTerraformGraph tag `v0.2.0` absent;
`LEDGER.md` absent at harness root; fixture repos in ClaudeTestingTerraform
reachable at the SHAs pass 0023's read-back recorded (re-clone and assert —
mismatch is a hard stop, not a repair).

## Acceptance test — red first
`plans/0025-findings-batch/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0025 delivered' {
        It 'decision 0012 exists' {
            Test-Path "$RepoRoot/decisions/0012-fixture-case3-repair.md" | Should -BeTrue }
        It 'tf-002 is 7/7' {
            (Get-Content "$RepoRoot/runs/tf-002-convention-and-case3/README.md" -Raw) |
                Should -Match 'functional-tf:\s*7\s*/\s*7' }
        It 'tf-002 records the model version' {
            (Get-Content "$RepoRoot/runs/tf-002-convention-and-case3/README.md" -Raw) |
                Should -Match 'model-version:\s*\S+' }
        It 'oracle re-falsified after amendment' {
            (Get-Content "$RepoRoot/plans/0025-findings-batch/mutations.txt" -Raw) |
                Should -Match 'DETECTED: 7 / 7' }
        It 'new and amended skills exist' {
            Test-Path "$RepoRoot/skills/producer-contract/SKILL.md" | Should -BeTrue
            (Get-Content "$RepoRoot/skills/powershell-module-scaffold/SKILL.md" -Raw) |
                Should -Match 'dev.?loader' }
        It 'conformance states a stable denominator' {
            (Get-Content "$RepoRoot/plans/0025-findings-batch/denominator.txt" -Raw) |
                Should -Match 'cases-defined identical across shapes: True' }
        It 'LEDGER exists with the four registers' {
            $l = Get-Content "$RepoRoot/LEDGER.md" -Raw
            $l | Should -Match '(?m)^## Passes'
            $l | Should -Match '(?m)^## Runs'
            $l | Should -Match '(?m)^## Versions'
            $l | Should -Match '(?m)^## Backlog' }
    }

Run it; report the red with messages. Green at start stops the pass.

## Plan (∥ groups parallel; commit+push per group)
- [ ] 1. Acceptance red.
- [ ] 2. **Name the 31st difference.** tf-001 accounts for 28 + 2 of 31;
      re-run Compare-TfGraph on the committed tf-001 graph, identify the
```

**The prompt ends there.** Item 2 from "identify the" onward, and every item
after it, are missing.

## 2. Preconditions

| Precondition | Command | Result |
| --- | --- | --- |
| Sync — fetch all six, parallel | `git -C <repo> fetch --all --tags --prune` × 6, backgrounded, `wait` | all exit 0; degree of parallelism **6** |
| No divergence, no dirty tree | `git rev-list --left-right --count main...origin/main`; `git status --porcelain` | `0	0` in all six; every tree clean |
| Harness SHA | `git rev-parse main` | `fc27c53b066473d58d793470fb132feb388ac214` — matches the prompt |
| PSTerraformGraph SHA | `git rev-parse main` | `05fb60d5286e99b302afbfaf5eee87c866ecd14c` — matches the prompt |
| `$env:AZDO_PAT` | `if ($env:AZDO_PAT) { ... }` | **set** (84 characters; the value is not recorded) |
| `plans/0025-findings-batch/` absent | `ls plans` | absent |
| PSTerraformGraph tag `v0.2.0` absent | `git tag` | only `v0.1.0` present |
| `LEDGER.md` absent at harness root | `ls LEDGER.md` | `No such file or directory` |
| Fixture repos at pass 0023's SHAs | `evals/tf/Test-TfFixtureReadBack.ps1 -WorkRoot $env:TEMP\tfrb25` | **BYTE-IDENTICAL**, exit 0, 40 files across 3 repositories |

Fresh-clone SHAs, against the values run tf-001 recorded:

| Repository | Cloned at | Expected | Agrees |
| --- | --- | --- | --- |
| TfFixtureShared | `0af6ee33854bedb4147d0b13cc6db1311687775b` | same | yes |
| TfFixtureNetwork | `24f27be92e583b6dfc9208bca42f8ec0baf5004b` | same | yes |
| TfFixtureApp | `187ff229c0ad908eb39822f1bb78b6c0e3a206b3` | same | yes |

All preconditions pass. The fixture is verified **pre-repair**; this read-back
is the baseline any case-3 repair will be measured against.

### A precondition that failed for a reason that was not the fixture

The first read-back attempt failed with `clone of TfFixtureShared failed with
exit 128`. The cause was neither AzDO nor the fixture: the session scratchpad
path is 149 characters before the clone directory is appended, and git on
Windows hit `MAX_PATH` writing loose objects —

```
error: unable to write file C:/Users/jlbal/AppData/Local/Temp/claude/c----Code---AI-Agent-Claude-PowerShellModuleBuilder-AI-Agent-Claude-PowerShellModuleBuilder/ace79446-.../scratchpad/diag-clone/TfFixtureShared/.git/objects/1f/7cca16fbdd972a117eba7d692fdc797c02cec6: Filename too long
fatal: unpack-objects failed
```

Re-running from `$env:TEMP\tfrb25` succeeded unchanged. Recorded because the
script's own default work root is `[System.IO.Path]::GetTempPath()`, which is
short and would not have hit this — the failure was caused by passing
`-WorkRoot` into the scratchpad, that is, by the caller and not by the script.

It leaves a backlog line behind it. `Test-TfFixtureReadBack.ps1` throws
`clone of $name failed with exit $LASTEXITCODE` and pipes git's stderr to
`Out-Null`, so the message names the failure and destroys the only evidence of
its cause. Diagnosing it needed a separate hand-run clone. That is
`method/METHOD.md` § Diagnosability — "there is a named command that reveals
why" — not being met by a script whose whole job is to be believed.

## 3. Environment

| | |
| --- | --- |
| pwsh | 7.6.5 |
| Pester | 5.7.1 (6.1.0 also installed; the suite is pinned to 5.x) |
| git | 2.41.0.windows.1 |
| OS | Microsoft Windows 10.0.26200 |
| Claude Code | VSCode extension host; `claude` is not on PATH, so no version string could be read |
| model-version | `claude-opus-5[1m]` |
| Harness branch | `pass-0025-findings-batch`, from `main` at `fc27c53b0664` |
| PSTerraformGraph branch | `pass-0025-hasvalidation`, from `main` at `05fb60d5286e` |

## 4. Acceptance test — red first

```
pwsh> Invoke-Pester plans/0025-findings-batch/accept.Tests.ps1 -Output Detailed
Tests Passed: 0, Failed: 7, Skipped: 0, Inconclusive: 0, NotRun: 0
```

All seven red, each with its reason:

| # | Test | Failure |
| --- | --- | --- |
| 1 | decision 0012 exists | `Expected $true, but got $false.` |
| 2 | tf-002 is 7/7 | `Cannot find path '…\runs\tf-002-convention-and-case3\README.md'`; `Expected regular expression 'functional-tf:\s*7\s*/\s*7' to match $null` |
| 3 | tf-002 records the model version | same missing file; `Expected regular expression 'model-version:\s*\S+' to match $null` |
| 4 | oracle re-falsified after amendment | `Cannot find path '…\plans\0025-findings-batch\mutations.txt'`; `Expected regular expression 'DETECTED: 7 / 7' to match $null` |
| 5 | new and amended skills exist | `Expected $true, but got $false.` (`skills/producer-contract/SKILL.md`) |
| 6 | conformance states a stable denominator | `Cannot find path '…\plans\0025-findings-batch\denominator.txt'`; `Expected regular expression 'cases-defined identical across shapes: True' to match $null` |
| 7 | LEDGER exists with the four registers | `Cannot find path '…\LEDGER.md'`; `Expected regular expression '(?m)^## Passes' to match $null` |

Red on every assertion, before any work. The pass may proceed.

## 5. Tasks

- [x] 1. Acceptance red. Evidence in section 4.
- [ ] 2. Name the 31st difference. **Blocked — the instruction is truncated.**
- [ ] … remaining items unknown.

## Pause — the prompt is truncated

The pass has committed task 1 and pauses there rather than proceeding, and
says so rather than filling the gap by inference.

`PLAN-PROTOCOL.md` § File supply: what a pass must produce is either already
committed or appears verbatim in the prompt, and a gap is "a defect in the
prompt, not a lookup task, and the pass stops on it rather than searching or
inventing." That rule is about file content, but its reasoning covers a
truncated task list exactly, and the protocol records that the same gap has
already cost this project two passes — once silently, which was the bad
outcome, and once loudly, which was the correct one. This is the loud one.

The acceptance test names the deliverables. It does not supply the decisions
behind them:

| Deliverable the test names | What the truncated region held |
| --- | --- |
| `decisions/0012-fixture-case3-repair.md` | what the case-3 repair *is*. The prompt says "the case-3 repair commits, **per decision 0012 below**", and "below" is inside the truncation. tf-001 found case 3 unpassable by any parser, because the fixture ties the output to the variable in an English *description* rather than in HCL. Repairing it means editing frozen fixture configuration on three AzDO repositories, and more than one repair is defensible. |
| `runs/tf-002-convention-and-case3/README.md` at `functional-tf: 7 / 7` | whether tf-002 is a fresh scored run against the repaired fixture, its iteration cap, and whether the oracle is visible — tf-001 was explicit that a visible oracle makes a build, not a generalisation measurement |
| `plans/0025-findings-batch/mutations.txt` with `DETECTED: 7 / 7` | which seven mutations, and after which oracle amendment. `evals/tf/Mutate-TfGraph.ps1` exists and pass 0023 falsified 7/7 against the *unamended* oracle. |
| `skills/producer-contract/SKILL.md`, and `dev.?loader` in `powershell-module-scaffold` | which findings become which skills. "Findings to skills" is the pass title; the mapping is truncated. |
| `plans/0025-findings-batch/denominator.txt` with `cases-defined identical across shapes: True` | what "shapes" ranges over, and whether the denominator is to be *reported* or *enforced* by an assertion under `evals/conformance/` |
| `LEDGER.md` with `## Passes ## Runs ## Versions ## Backlog` | what populates the four registers, and how far back |
| PSTerraformGraph `pass-0025-hasvalidation`, tag `v0.2.0` | the branch name matches tf-001's 28 × `WrongAttribute` finding on `hasValidation`. But tf-001 argued the *oracle* is right and the **producer** should omit the field, while this same task list also amends the oracle. Which side moves — and whether the splat gap, the 31st difference, ships in the same tag — is truncated. |

Inferring these would produce a plan whose numbers have no prompt behind them,
in a repository whose own rule is that a number without an artifact does not
belong in a plan. Task 1 is committed, the branches exist, and the acceptance
test is red and re-runnable. The pass resumes on the rest of the prompt.

## 10. Deviations

1. **The prompt is truncated mid-item-2.** The pass paused rather than
   inferring the remainder. See above.
2. **A precondition failed for a caller-side reason.** The fixture read-back
   failed first with a `MAX_PATH` clone error caused by the scratchpad path
   passed as `-WorkRoot`, not by the fixture. Re-run from a short root it
   exits 0, byte-identical. Recorded in section 2 rather than quietly re-run.
3. **`Test-TfFixtureReadBack.ps1` destroys the evidence of its own failure.**
   It pipes git's stderr to `Out-Null` and reports only an exit code. Offered
   as a backlog line, not fixed — it is not in the visible task list.
4. **Claude Code has no readable version here.** `claude` is not on PATH in
   the VSCode extension host, so section 3 records the model version instead.
   The acceptance test's `model-version:` assertion suggests that is the
   intent, and it is the first pass to record one.

## 11. Cost

Wall-clock to the pause: roughly 12 minutes. Runs produced: 1 fixture
read-back (3 clones, 40 files hashed on both sides), 1 acceptance suite run
(7 tests). Degree of parallelism: **6** for the fetch group, 1 elsewhere.
