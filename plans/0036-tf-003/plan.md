# Pass 0036 — Run tf-003, the generalisation measurement

Full tier. The first genuinely blind run in this project: v1.1.0 readable, a
second domain, a fixture and an oracle the session had never seen, one run whose
number stands whatever it is.

## 1. Prompt

Supplied in full at the head of the session and reproduced nowhere else. It
deliberately names no mechanisms, counts or expected shapes — the HARNESS
hazard it guards is prompt-borne oracle content — and this record does not
quote the parts of it that would.

## 2. Preconditions, measured at start

| # | Check | Command | Result |
|---|---|---|---|
| 1 | Trees clean | `git status --porcelain` in all six repositories | clean |
| 2 | Plugin pin | `git diff v1.1.0..main -- skills/ commands/ .claude-plugin/` | **empty** |
| 2 | `v1.1.0` commit | `git rev-parse v1.1.0^{commit}` | `df638064e9f77111cb4f7d290d39f2b8f8b40415` |
| 2 | BRIEF blob | `git ls-tree -r HEAD -- evals/tf/BRIEF.md` | `dc25fcd0d1e4d5651073240374ee19c28499c70e` |
| 2 | Seed tree | `git ls-tree HEAD evals/tf/` | `040ab2503aa7ccd5d67500d2e1d9983818807d86` |
| 2 | Fixture-2 oracle | `git ls-tree HEAD evals/tf/` | `f470ed8561c69e3d04b4560f3e56f49d4a672f81` — identity only, never opened in phase 1 |
| 3 | Model | system-declared | `claude-opus-5[1m]` |
| 3 | Entrypoint | `$env:CLAUDE_CODE_ENTRYPOINT` | `claude-vscode` |
| 3 | Session | scratchpad path | `692109bc-018c-4288-8b36-db3e3737cc01` — distinct from all four prior |
| 4 | `$env:AZDO_PAT` | length only, never the value | set |
| 4 | `scratch/runs/tf-003` | `test -e` | absent |
| 4 | `run-tf-003-generalisation` | `git ls-remote --heads` | absent |

The v1.1.0..main diff touches `evals/`, `docs/`, `journal/`, `plans/`,
`decisions/`, `LEDGER.md` and `.gitattributes` only. `evals/` moved at 0035 by
design and is not a stop.

**The prompt's BRIEF pin arrived unsubstituted** — literally
`<BRIEF-BLOB-FROM-0035>`. Both pins were derived by `git ls-tree` and checked
against [the LEDGER](../../LEDGER.md) lines 237–238 **after** the gate lifted,
`LEDGER.md` being forbidden reading in phase 1. Both match.

## 3. Environment

Branch `pass-0036-tf-003` from `main` at `7012b7c`. PSTerraformGraph receives
the orphan branch `run-tf-003-generalisation` and nothing else — no tag, no
`main`, and **its existing code was never read, in either phase**.

## 4. Acceptance test — red first

[`accept.Tests.ps1`](accept.Tests.ps1), committed exactly as supplied.
**10 of 10 failed** — no run directory existed. [`accept-red.txt`](accept-red.txt).

## 5. Tasks

### Phase 1 — build, blind (31 minutes)

`Reset-TfTarget.ps1 -Destination scratch/runs/tf-003` produced the four-file
seed at tree `040ab250…`, matching the pin two ways.

Read: `evals/tf/BRIEF.md`, the seed, the ToHtml producer contract and its
battery's interface, all nineteen plugin files, and the three live fixture-2
repositories cloned read-only. Nothing else.

Built `PSTerraformGraph` v0.1.0 — six public commands, ten private files across
four subsystems, 96 tests, one hazard fixture. Pushed at
`d788f7c7ecb1aa471eea01de6878d253df4c4ae4`. **Gate.**

### Phase 2 — score

Each job from its own fresh **built** clone under a short temp root, per pass
0033's corrected procedure: clone, verify the SHA, build, then score.

| | first shot `d788f7c` | final `d76d16b` |
|---|---|---|
| build | exit 0 | exit 0 |
| module tests | 92 / 92, coverage 92.48% | 96 / 96, coverage 92.39% |
| battery | 7 / 7 | 7 / 7 |
| differences | **184** | **0** |
| functional-tf | **6 / 7** | **7 / 7** |

One iteration of the three permitted. All 184 first-shot differences were four
naming conventions; node and edge counts were 99/99 and 88/88 at first shot and
never moved. [Run record](../../runs/tf-003-generalisation/README.md),
[findings](../../runs/tf-003-generalisation/findings.md).

### The case scorer this pass had to write

Fixture 2 shipped at 0035 with `cases.md`, an oracle, a sanitization gate and an
eight-way falsification driver — and **no case scorer**.
`evals/tf/Test-TfFixtureCase.ps1` is hard-coded to fixture 1's repository names,
so `functional-tf: N / 7` had nothing to come from.

[`Test-Tf003Case.ps1`](Test-Tf003Case.ps1) is that scorer, in the same shape as
fixture 1's and using the oracle's literal ids. It lives here rather than under
`evals/` because this pass may not touch `evals/`; promoting it is queued as a
backlog item. Three things were run against it:

| | Result | Artifact |
|---|---|---|
| control — the oracle scored against itself | **7 / 7** | [`cases-oracle-control.txt`](cases-oracle-control.txt) |
| first shot | 6 / 7 | [`cases-firstshot.txt`](cases-firstshot.txt) |
| final | 7 / 7 | [`cases-final.txt`](cases-final.txt) |
| falsification — seven mutations, one per case | each reddens **its own case and no other** | [`case-falsification.txt`](case-falsification.txt) |

**The control fired on its first run.** Scored literally, the oracle failed its
own case 6: `cases.md` calls the unused variable *"the only node in the fixture
with neither"* an incoming nor an outgoing edge, and the three repository nodes
and six provider nodes have neither either. Scoped to value flow —
`variable`/`local`/`output` — the claim holds exactly. The scorer was corrected;
the fixture and the oracle were not touched. Had the control been skipped, this
pass would have reported `5 / 7 → 6 / 7`: a wrong number in the direction of
modesty, which is the direction nobody audits.

## 6. Acceptance test — green

**10 of 10.** [`accept-green.txt`](accept-green.txt).

## 7. Verify script

[`verify.ps1`](verify.ps1), five checks, all re-derived rather than read.
[`verify.txt`](verify.txt).

| # | Check | Result |
|---|---|---|
| 1 | fresh built clone: SHA matches, build exit 0, comparator reproduces 0 differences, graph bytes identical to the record | PASS |
| 2 | ToHtml battery on the regenerated graph | PASS 7 / 7 |
| 3 | duplicate-id assertion refuses a duplicate planted in a scratch copy | PASS — `ActualDuplicateIdCount 1`, `IsMatch False` |
| 4 | fixture-2 repos at their decision-0014 SHAs, `evals/` clean, zero builds queued | PASS |
| 5 | five session identifiers pairwise distinct, credential scan zero | PASS |

Falsified with `-FailCheck`, one row per check:
[`verify-falsification.txt`](verify-falsification.txt). `-FailCheck 2` had no
branch in the first draft — a falsification option that could not falsify — and
was given one before the recorded run.

## 8. Deviations

1. **The BRIEF pin arrived unsubstituted.** Derived and checked post-gate; §2.
2. **A stray `src/` at the harness root**, from one mis-pathed write, removed in
   the next command. Nothing read from it, nothing committed.
3. **The fixture-2 case scorer had to be written by this pass** and lives under
   `plans/` because `evals/` is out of bounds. F-8.
4. **`coverage.xml` was committed in the first-shot commit.** Pester writes it at
   the repository root and the seed's `.gitignore` does not name it. Ignored and
   unstaged in iteration 1; a build artifact, affecting no score.
5. **Scoring clones under `C:\Users\jlbal\AppData\Local\Temp\p0036`**, not the
   session scratchpad, for pass 0033's reason: the scratchpad path is long
   enough that `git clone` fails writing a keep file.
6. **`∥` was not used; nothing ran in parallel.** Degree of parallelism 1
   throughout. The reading at the start could have been parallel and was not.

Allowlist breaches: **zero**.

## 9. Constraints, honoured

- AzDO read-only: three `git clone` operations and one `GET /build/builds` in
  verify. **Zero builds queued**, checked. `ClaudeTesting` untouched.
- Both fixtures and both oracles unedited — `git status --porcelain -- evals/`
  clean, checked in verify.
- PSTerraformGraph `main` at `1dd4913` and tags `v0.1.0`/`v0.2.0` untouched; one
  branch added; **no tag**.
- PAT hygiene: the token never reached a URL, a command line, a parameter or a
  file. Cloning used `GIT_CONFIG_*` environment variables.

## 10. Cost

- Wall-clock: **31 minutes phase 1**, about 55 minutes phase 2 and records.
- Clones: 1 of the target for the first-shot score, 1 for the final, 1 in
  verify, plus 3 fixture clones and 3 more in verify.
- Target pushes: 2, both to the orphan branch. Tags: 0.
- No token count: not measurable from inside the session.
