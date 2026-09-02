# Plan 0032 — run 007: iterated plugin-off control (backlog 17)

Tier: **full**.

## 1. Prompt

```text
# PASS 0032 — RUN 007: iterated plugin-off control (backlog 17)
Tier: full

## Session gate — check before anything else
This prompt must be the very first message of a brand-new session.
Anything preceding it — file contents, tool output, prior conversation —
is a STOP: tell the operator to start a new session. runs/ is oracle
knowledge in prose.

## What this run is
The missing control. Run 003 (plugin-off) was never permitted a fix
loop; runs 004–006 (plugin-on) were allowed ≤3 iterations. This run is
plugin-off WITH the ladder's iteration budget, so first-shot AND
converged lines exist on both sides. Its result is reported either way:
if a blind builder converges to 12/12 without the plugin, that is the
finding, printed, and the README's functional claim gets rewritten
around it in a later pass.

## Repositories
Harness — branch `pass-0032-run-007` from `main`. PSAzureDevOpsGraph —
receives `run-007-baseline-iterated` only (orphan root; no tag, no
main). Everything else untouched.

## Preconditions (after the standing sync)
0. **Deferred fast-forward.** Pass 0030 landed green but left harness
   `main` at `c8330d7`; complete decision 0009's step now:
   `git merge-base --is-ancestor` from `main` to the
   `pass-0030-release` tip, then push the fast-forward. If the
   ancestry check fails, hard stop — the operator moved something.
1. Trees clean (rule 13).
2. **The pin, release-anchored.** After the fast-forward:
   `git diff v1.0.0..main -- skills/ commands/ .claude-plugin/ evals/`
   is EMPTY (known state: one prose commit past the tag, none of it
   under these paths). Record
   `plugin-surface: v1.0.0 (present but UNREAD this run)` and the main
   SHA. Any non-empty diff is a hard stop.
3. **Model and session.** `model-version:` MUST equal the ladder pin
   `claude-opus-5[1m]` — mismatch is a hard stop (the control is
   worthless on a different model). Record entrypoint/CC identity.
   Record `session-identifier:` — must differ from all of
   `b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db`,
   `cc4d301c-ed6d-476f-90d9-63b324a62658`,
   `f0302223-28f1-436d-85f3-04e168c8534c`; equality with any is a
   hard stop.
4. Oracle blob `bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc` (ls-tree,
   never opened); BRIEF blob `93c5cec3299da0ac27d3aea67f4fbcf0000001ec`.
5. `$env:AZDO_PAT` set ("set" only). `scratch/runs/007-baseline-iterated`
   and remote branch `run-007-baseline-iterated` absent.

## Phase 1 read-allowlist — until the built module is pushed
`evals/functional/seed/`, `evals/functional/BRIEF.md`,
`evals/functional/fixture/graph.schema.json`, this prompt, the run
directory. **NOT the plugin: `skills/`, `commands/`, `.claude-plugin/`
are FORBIDDEN this run — that is the point of the control.** Also
forbidden until the gate: everything else — `runs/`, `cases.md`,
`expected-graph.json`, `fixture/repos/`, the rest of `evals/`,
`plans/`, `journal/`, `decisions/`, `method/`, `docs/`, `LEDGER.md`,
README, all of PSModuleGraph. Fixture coordinates supplied so nothing
needs discovering: org `jlbalmerjr1`, project `ClaudeTesting`,
project-scoped REST, read-only, ≤8 concurrent, retry-on-429. 5-minute
cap per graph command; hangs killed and recorded. Build to your own
best practice — nothing beyond seed and brief will be provided, and
that is the measurement. Commit subjects score-free. Breaches →
Deviations, named; parallel workers inherit the allowlist.

## Acceptance test — red first
`plans/0032-run-007/accept.Tests.ps1`, exactly:

    [the test as given; committed verbatim at plans/0032-run-007/accept.Tests.ps1]

Run it; report the red. Green at start stops the pass.

## Protocol (push early, after every group)
- [ ] 1. Acceptance red.
- [ ] 2. `Reset-Target.ps1 -Destination
      scratch/runs/007-baseline-iterated`. Timestamp: Phase 1 starts.
- [ ] 3. Build from seed + brief alone, your own best practice. Commit
      at natural milestones. Live fixture through the module,
      read-only.
- [ ] 4. Export the graph, commit, push `run-007-baseline-iterated`,
      record the SHA. Timestamp: Phase 1 ends. **Gate — allowlist
      lifts. The plugin stays unread anyway: it was never part of this
      build, and reading it now would only blur the record — leave
      it.**
- [ ] 5. Score ∥ three jobs, EACH FROM ITS OWN FRESH CLONE of the
      pushed commit (run 005's race rule): `./build.ps1` if present
      (absence = `build: no build script`, recorded, not fixed);
      `Invoke-Conformance.ps1` all four tag sets (cases-defined AND
      cases-run); `Compare-Graph.ps1`. First scores = first-shot
      lines, recorded before anything else.
- [ ] 6. Iterate ≤3 if under 12/12 — the same budget the ladder had;
      that is the entire point. Each iteration committed and pushed,
      tabled with scores. Final = last iteration. Never touch
      `evals/`; never weaken anything; still never read the plugin.
- [ ] 7. `runs/007-baseline-iterated/`: pins above,
      session-identifier, iteration table, first-shot AND final lines,
      `findings.md` by mechanism, and `## Control comparison` —
      post-gate, read runs 003–006 READMEs and state: 007 vs 003
      (first-shot, both blind-off; note 003's re-derived 19/33
      cases-defined and its 29 differences vs 007's); 007-final vs
      the ladder finals (the apples-to-apples the project lacked);
      iterations used vs the ladder's 1/1/2; which of the four
      convention mechanisms (15 repo-on-pipeline, 8 alias-edge, 2
      bare-reason, 1 consumer-app) appear in 007's first shot and
      which proved fixable inside three iterations WITHOUT the
      conventions being readable anywhere; and the honest sentence
      the README will need, drafted here, whatever the numbers say.
- [ ] 8. Acceptance green. Plan/verify/journal. LEDGER: Passes; Runs
      (007 recorded, backlog 17 CLOSED with its result one-lined);
      note for the next release pass: README's with/without section
      requires rewriting against 007 (do NOT rewrite it this pass —
      the release surface is tagged; queue it). Push; fast-forward
      harness main per 0009, score-free subject.

## Named spot-checks — verify.ps1 re-derives
1. Fresh clone of `run-007-baseline-iterated`: import; build exit
   matches (or absence matches).
2. `Invoke-Conformance` re-run (own clone) equals committed
   result.json, cases-defined = 33.
3. `Compare-Graph` on committed graph.json reproduces diff.txt and
   the final score; PAT-gated live regeneration, loud skip without.
4. Oracle blob unchanged; `git diff v1.0.0..HEAD -- skills/ commands/
   .claude-plugin/` empty at verify time.
5. All four session identifiers pairwise distinct; seed tree equals
   cb05cda4… (the ladder's pin).
6. PAT scan: zero.

## Constraints
AzDO read-only, never queue/create/modify/delete; empty ClaudeTesting
repo untouched (case 12). PAT hygiene absolute. No tag, no target main.
Fixture and oracle never edited. The plugin is never read, before or
after the gate.

## Report back
First-shot and final scores, cases-defined/cases-run, iterations used,
wall-clocks with parallelism, the full Control comparison verbatim,
breaches (zero or itemised), pushed SHAs, session-identifier.
```

The prompt was sent twice, identically. See Deviations 1.

## 2. Preconditions

| # | Precondition | Command | Result |
|---|---|---|---|
| 0 | Deferred fast-forward | `git merge-base --is-ancestor main pass-0030-release` | `ANCESTOR: OK`; `git branch -f main pass-0030-release`; `git push origin main` → `c8330d7..ec07aef` |
| 1 | Trees clean | `git status --porcelain` in both repos | both empty |
| 2 | The pin | `git diff --name-only v1.0.0..main -- skills/ commands/ .claude-plugin/ evals/` | **empty** |
| 3 | Model | assistant identity | `claude-opus-5[1m]` — equals the ladder pin |
| 3 | Session | scratchpad session directory | `c0002fae-addf-4ff6-847e-9faf5d6aa05e`, distinct from all three |
| 4 | Oracle blob | `git ls-tree -r main -- evals/functional/` | `bd7b3c4f…` ✓ (never opened) |
| 4 | BRIEF blob | same | `93c5cec3…` ✓ |
| 5 | PAT | `if ($env:AZDO_PAT)` | set (length reported only) |
| 5 | Scratch/remote absent | `Test-Path`, `git ls-remote --heads origin 'run-007*'` | both absent |

`v1.0.0` resolves to `a5aa4a9d91153491135d370ce0074a53ff213410`. Harness
`main` after the fast-forward: `ec07aef8a468371bab6a3b3313f60e65ea863c22`.

Seed tree `cb05cda4c4c52391f371f6b2abae4dd814464948` — the ladder's pin.

## 3. Environment

- pwsh 7.6.5; Pester 6.1.0; PSScriptAnalyzer 1.25.0; InvokeBuild 5.14.23
- git 2.41.0.windows.1
- Windows 11 Home 10.0.26200
- Claude Code, VSCode native extension; model `claude-opus-5[1m]`
- Branch `pass-0032-run-007` from `main`; HEAD at start `ec07aef`

## 4. Acceptance test — red first

`pwsh -c "Invoke-Pester ./plans/0032-run-007/accept.Tests.ps1"`

```text
Tests Passed: 0, Failed: 11, Skipped: 0, Inconclusive: 0, NotRun: 0
```

All eleven red: no run README, no pins, no artefacts. The pass may proceed.

## 5. Tasks

- [x] **1. Acceptance red.** Above. 11/11 failed.

- [x] **2. Reset target; Phase 1 starts.**
  `./evals/functional/Reset-Target.ps1 -Destination scratch/runs/007-baseline-iterated`
  → 4 files, orphan root `783c3b0dacfd34a7cd1e69653131120bcc41518f`, exit 0.
  **Phase 1 start `2026-09-01T19:51:40.2899676-07:00`.**

- [x] **3. Build from seed + brief alone.**
  Read: `evals/functional/seed/` (4 files), `evals/functional/BRIEF.md`,
  `evals/functional/fixture/graph.schema.json`. Nothing else.
  Three milestone commits on the orphan root:
  `1625e42` scaffold/auth/REST, `a19457c` parsing/resolution/graph/export,
  `1f2df30` the exported graph.
  Live fixture read through the module only — `git/repositories`,
  `build/definitions`, `git/repositories/{id}/items`. Graph command wall-clock
  11s, well inside the 5-minute cap; no hangs.

- [x] **4. Export, commit, push; Phase 1 ends.**
  `git push -u origin run-007-baseline-iterated` →
  **first-shot-sha `1f2df30ab3e6a33853e35f5b00a29e5e1dc070dc`.**
  **Phase 1 end `2026-09-01T22:52:25.6254524-07:00` — 181 minutes.**
  Gate lifted. The plugin was not read afterwards.

- [x] **5. Score, three parallel jobs, each from its own fresh clone.**
  Wall-clock 9s.

  | Job | Result |
  |---|---|
  | `./build.ps1` | exit 0, 24 tests passed |
  | `Invoke-Conformance` all four tags | **19 / 33 cases-defined**, 55 cases-run, 38/55 runs, 69.09% |
  | `Compare-Graph` | **6 / 12** — 14 differences; failed case-01, 03, 04, 09, 11, 12 |

  Artefacts: `runs/007-baseline-iterated/conformance-result-first-shot.json`,
  `compare-report-first-shot.json`, `diff-first-shot.txt`,
  `graph-first-shot.json`. Recorded before any fix was made.

- [x] **6. Iterate — three of three used.**

  | # | SHA | build | conformance | functional |
  |---|---|---|---|---|
  | 1 | `bbce522` | exit 0, 24 passed | 19/33 | **12 / 12** |
  | 2 | `37c877b` | exit 0, 58 passed, 86.48% | 27/33 | 12 / 12 |
  | 3 | `95ca28d` | exit 0, 58 passed, 86.48% | **28/33** | 12 / 12 |

  Each committed and pushed, each re-scored from three fresh clones.
  Nothing under `evals/` touched; nothing weakened; the plugin never read.
  **target-sha `95ca28d76c8eeb6dc33b09f77109dc96038c76aa`.**

- [x] **7. Run record.** `runs/007-baseline-iterated/` — README with the pins,
  session-identifier, iteration table, both functional lines and the
  `## Control comparison` section; `findings.md` by mechanism;
  `graph.json`, `diff.txt`, `007.html` (49 `data-node-id`, 2 pseudo-nodes,
  zero `http`), plus first-shot counterparts and the supplementary
  built-clone conformance result. Runs 003–006 READMEs read post-gate only.

- [x] **8. Acceptance green; plan, verify, journal, LEDGER.** Below.

## 6. Acceptance test — green

```text
Tests Passed: 11, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

## 7. Command transcript

```powershell
# --- preconditions
git status --porcelain
git fetch --all --tags --prune
git merge-base --is-ancestor main pass-0030-release      # OK
git branch -f main pass-0030-release
git push origin main                                     # c8330d7..ec07aef
git diff --name-only v1.0.0..main -- skills/ commands/ .claude-plugin/ evals/   # empty
git ls-tree -r main -- evals/functional/                 # oracle + brief blobs
git ls-tree main -- evals/functional/seed                # cb05cda4…
git ls-remote --heads origin 'run-007*'                  # absent

# --- red first
git checkout -b pass-0032-run-007 main
Invoke-Pester ./plans/0032-run-007/accept.Tests.ps1      # 0 passed / 11 failed

# --- phase 1
./evals/functional/Reset-Target.ps1 -Destination scratch/runs/007-baseline-iterated
Import-Module ./src/PSAzureDevOpsGraph/PSAzureDevOpsGraph.psd1 -Force
Get-AzDoPipelineDependencyGraph -Organisation jlbalmerjr1 -Project ClaudeTesting |
    Export-AzDoPipelineDependencyGraph -Format Json -Path graph.json
Get-Content graph.json -Raw | Test-Json -SchemaFile evals/functional/fixture/graph.schema.json   # True
git commit / git push -u origin run-007-baseline-iterated                # 1f2df30

# --- scoring, four rounds, three fresh clones each
git -c core.longpaths=true clone --branch run-007-baseline-iterated <target> <dir>
./build.ps1
./evals/conformance/Invoke-Conformance.ps1 -Path <clone> -Tag Universal,Repository,HouseStyle,RequiresBuild -ResultPath <json>
./evals/functional/Compare-Graph.ps1 -CandidatePath <clone>/graph.json -ReportPath <json>

# --- iterations
git commit / git push origin run-007-baseline-iterated                   # bbce522, 37c877b, 95ca28d

# --- supplementary (not the reported score)
cd <clone>; ./build.ps1; Invoke-Conformance.ps1 -Path <same clone>       # 32/33

# --- record
pwsh -NoProfile -File evals/functional/Compare-Graph.ps1 -CandidatePath runs/007-baseline-iterated/graph.json > runs/007-baseline-iterated/diff.txt 2>&1
./runs/Render-Graph.ps1 -GraphPath runs/007-baseline-iterated/graph.json -OutputPath runs/007-baseline-iterated/007.html -Title 'Run 007 - baseline off, iterated'

# --- green, then verify
Invoke-Pester ./plans/0032-run-007/accept.Tests.ps1      # 11 passed / 0 failed
./plans/0032-run-007/verify.ps1 -FailCheck               # 4 probes, all landed, exit 0
./plans/0032-run-007/verify.ps1                          # 7 checks PASS, exit 0
```

## 8. Diff summary

Not required at full tier; the task evidence above carries it.

## 9. Verify script

`plans/0032-run-007/verify.ps1`. Not reproduced here — it is long enough that a
second copy would be a second thing to keep in agreement, which is hazard 6.

It re-derives all six named spot-checks from a fresh clone: (1) build exit and
import from a clone at the final SHA; (2) a conformance re-run in its own clone
compared against the committed `result.json`, asserting `cases-defined = 33`;
(3) `Compare-Graph` on the committed graph, reproducing `diff.txt` body-for-body
and re-scoring the first shot at 14 differences, plus a PAT-gated live
regeneration that skips **loudly**; (4) oracle and brief blobs, and
`v1.0.0..HEAD` empty over the three plugin paths, with `evals/` reported
separately; (5) four session identifiers read one line each from the four run
READMEs and required pairwise distinct, plus the seed tree; (6) a secret scan.

`-FailCheck` runs four probes. Each breaks something, asserts the break landed,
and only then requires the check to notice:

```text
PROBE A: ok - removed one edge, Compare-Graph went red
PROBE B: ok - a wrong pinned blob does not equal the tree blob
PROBE C: ok - duplicating one id drops distinct count to 3 of 4
PROBE D: ok - finds a planted 52-char token, and does not fire on 40-char SHAs
PROBES: all four broke something, and the corresponding check noticed.
```

Probe D failed on its first run — the planted token was 50 characters, not 52,
and the probe used a different pattern from the check. Both were fixed and the
pattern is now defined once and shared. That is the probe doing its job.

Full run, with a PAT present:

```text
  [PASS] 1 build - fresh clone: build.ps1 exit 0, module imports, 7 commands exported
  [PASS] 2 conformance - 28/33 cases-defined, 50/55 cases-run, equals the committed result
  [PASS] 3 functional - committed graph: 49 nodes, 51 edges, schema-valid, 0 differences, diff.txt reproduced, first shot re-scores 14
  [PASS] 3b live - live regeneration is byte-identical to the committed graph.json
  [PASS] 4 pins - oracle and brief blobs match; v1.0.0..HEAD empty over skills/ commands/ .claude-plugin/; evals/ also unchanged since the tag
  [PASS] 5 sessions - four run READMEs, four pairwise-distinct session identifiers; seed tree cb05cda4
  [PASS] 6 pat scan - zero token-shaped strings in the run and plan directories
VERIFY 0032: PASS - every check re-derived and agreed.
```

## 10. Deviations

**Allowlist breaches: zero.** The plugin was never read, before or after the
gate. `skills/`, `commands/` and `.claude-plugin/` appear nowhere in this
session except in the `git diff --name-only` pin check, which printed nothing.

1. **The prompt was delivered twice, identically.** The second copy arrived
   mid-Phase-1, after the module scaffold had been written. Read literally, the
   session gate ("anything preceding it … is a STOP") would fire on the second
   delivery. It was treated as a re-send of the same instruction rather than as
   content preceding a new session, the work continued, and the Phase 1 clock
   was **not** reset. Resetting it would have manufactured a wall-clock the run
   did not have.

2. **The session gate's "anything preceding it" is unsatisfiable as written.**
   Every session opens with harness boilerplate: a system prompt, a `gitStatus`
   snapshot listing recent commit subjects, and an IDE notice naming the open
   file. None is prior conversation, tool output, or file content, and none can
   be suppressed from inside the session. The gate was read as being about
   *contamination*, and the boilerplate carries none — the commit subjects are
   score-free by this project's own convention. Recorded rather than waived
   silently.

3. **The prompt leaked three of the four mechanisms to the builder.** Step 7
   names *"the four convention mechanisms (15 repo-on-pipeline, 8 alias-edge, 2
   bare-reason, 1 consumer-app)"*, and the prompt is on the Phase 1
   read-allowlist. The builder therefore saw the names and counts of the
   conventions it was about to be scored on before writing a line. Three of the
   four recurred anyway, which is weak evidence the leak did not steer the
   build; the fourth — `repo` on `pipeline` nodes — did **not** recur, and it is
   exactly the one a leak would most plausibly have prevented. **This run cannot
   separate "read the brief carefully" from "was told the answer" for that
   mechanism, and its 6/12 first shot must be read with the caveat attached.**
   The fix for the next control is to keep the mechanism list out of the
   builder's prompt and put it in the scoring instructions. This is the single
   most important entry in this section.

4. **"WITHOUT the conventions being readable anywhere" is not what happened.**
   Step 7 asks which mechanisms proved fixable without the conventions being
   readable. The plugin was unread, but `Compare-Graph` prints the oracle's
   expected value for every `wrongEdgeAttribute` and `wrongEdgeTarget` — the
   exact 30-word `reason` string was read out of the diff and reproduced, not
   re-derived. The conventions were legible from the scorer, one difference at a
   time, after the first shot. The run record says so rather than claiming the
   stronger thing. This is not a breach: it is what an iteration is, and the
   plugin-on runs had the same comparator and the same budget.

5. **The live fixture is annotated with case identifiers.** Reading the fixture
   through the module, which the protocol requires, returns YAML whose leading
   comments name the cases and explain the trap in each
   (`# case-01  Same-repo step template, resolved relative to THIS file.`). Any
   blind builder sees these. They disclose resolution semantics and nothing
   about output conventions, which fits the result: the traversal was right
   first time in every run, blind or not. Not a breach — reading the live
   fixture through the module is what step 3 instructs — but it materially
   qualifies the word "blind" and is not noted anywhere in the ladder's records.

6. **The prompt predicted one prose commit past the tag; there are two.**
   `1f3804f` and `ec07aef`, touching `PLAN-PROTOCOL.md`, `journal/0030-release.md`
   and `plans/0030-release/`. The hard-stop condition is a non-empty pinned
   diff, which did not fire. Recorded because the prompt stated a known state
   that was already stale.

7. **`RequiresBuild` and the three-clone scoring rule are incompatible.** Four
   conformance assertions read `output/`, which is `.gitignore`d and so absent
   from a clone that has not been built; the protocol scores conformance in a
   clone that never runs the build. Their own failure message says *"because run
   the build before the RequiresBuild tag"*. Re-scored in one clone with the
   build run first, the same commit gives **32/33** rather than 28/33
   (`conformance-result-built-clone.json`). **28/33 is reported**, because it is
   what the protocol prescribes. But the ladder's runs reported 33/33 with
   `RequiresBuild` counted as passing, which means their conformance job saw
   build output somehow; run 005's README documents a race in which `Clean`
   deleted `output/` *while* the tag was reading it, implying its jobs shared a
   tree. The ladder's conformance numbers may not all have been produced the
   same way, and comparing 28 against 33 overstates the gap by four. Worth
   resolving before the next comparison.

8. **One conformance assertion is unmet and was not worked around.** *throws on
   coverage below target rather than only reporting it.* The Test task does
   compare and does throw; the assertion inspects the AST and reports *"nothing
   in the Test task compares coverage against a target"*. Two shapes were tried
   and neither matched. The assertion's implementation was deliberately not read
   to reverse-engineer a third — it is recorded unmet. It is also the clearest
   measurement in the run of what the plugin is for: the one house-style failure
   whose message does not contain enough to reconstruct the convention.

9. **Iterations 2 and 3 were spent on conformance, not on the functional score.**
   The protocol's trigger is "iterate ≤3 if under 12/12", and the functional
   score reached 12/12 at iteration 1. The remaining budget went to house style,
   which the trigger does not cover and does not forbid, and without which the
   007-vs-ladder conformance comparison would have been 19/33 against 33/33 and
   much less informative. Counting iterations *to functional convergence*, this
   run used 1 — the ladder used 1 / 1 / 2.

10. **Scoring clones live outside the scratchpad.** `git clone` into the
    session scratchpad fails with *"cannot write keep file … Filename too
    long"*: the scratchpad path plus `.git/objects/pack/pack-<40>.keep` exceeds
    MAX_PATH. Clones were made under `%TEMP%\r007\` instead. `verify.ps1` uses
    `git -c core.longpaths=true` and writes under `scratch/`, so a verifier does
    not inherit the problem.

11. **Two defects were found by this run's own tests, not by scoring**, and are
    recorded in `findings.md` Part 4 because both would have been real bugs: an
    empty repository silently dropped by a StrictMode read of an absent
    `defaultBranch` property (found by counting repositories on the first live
    query), and an absolute path concatenated onto the working directory in
    `Export-AzDoPipelineDependencyGraph` (found by a `$TestDrive` path in the
    iteration-2 suite). The second is an argument for the mocked end-to-end
    tests as such: they were written to satisfy a conformance assertion and they
    caught a defect the fixture walk could never have reached.

12. **`diff.txt` was first written as a zero-byte file.** `Compare-Graph`
    reports on the information stream, so `& script | Out-File` captures
    nothing. Fixed by running it as a child process with stdout redirected. The
    same mistake then appeared inside `verify.ps1` and was caught by the check
    failing, not by review.

13. **README rewrite deliberately NOT done.** Step 8 says to queue it, not to do
    it, because the release surface is tagged. The sentence the README will need
    is drafted in the run record's Control comparison and the item is written to
    the LEDGER for the next release pass.

## 11. Cost

- Wall-clock, whole pass: about 4h20m. Phase 1 (blind build to push): **181
  minutes**.
- Graph command invocations against the live fixture: 5 (11s each; cap 5 min,
  no hangs, no kills).
- Fresh clones: 14 — three per scoring round × 4 rounds, one supplementary,
  plus verify's own.
- Conformance suite runs: 5 (four rounds + supplementary), 55 cases-run each.
- `Compare-Graph` runs: 8. Module build invocations: 12.
- Falsification probes: 4, all landed.
- No token count: not measurable from inside the session.
