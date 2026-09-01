# Pass 0027 — run 005, plugin-on

**Status: STOPPED at task 1. The acceptance test was not supplied.**

Pass number taken from the branch `pass-0027-run-005` and from the
numbering of `plans/0026-run-004/`, not from a prompt header, because the
prompt arrived without one. See Deviations D3.

## 1. Prompt

Reproduced verbatim as received. It begins mid-line, inside an `It` block,
with no header, no tier, no `Describe`, no `BeforeAll` and no `$RunDir`.
The leading indentation of the second and later lines is preserved: it is
itself evidence that lines above were lost.

````text
It 'states first-shot and final functional lines' { $r | Should -Match 'functional \(first-shot\):\s*\d+\s*/\s*12'; $r | Should -Match 'functional \(final\):\s*\d+\s*/\s*12' }
        It 'has a variance section vs run 004' { $r | Should -Match '(?m)^## Variance vs run 004' }
        It 'has graph, diff, html, findings' {
            foreach ($f in 'graph.json','diff.txt','005.html','findings.md') {
                Test-Path "$RunDir/$f" | Should -BeTrue } }
    }

Run it; report the red. Green at start stops the pass.

## Protocol (push early, after every group)
- [ ] 1. Acceptance red.
- [ ] 2. `Reset-Target.ps1 -Destination scratch/runs/005-plugin-on`.
      Timestamp: Phase 1 starts.
- [ ] 3. Build from seed + brief, following the plugin (/build, /test,
      the skills). Commit at natural milestones. Live fixture read
      through the module, read-only.
- [ ] 4. Export the graph, commit, push `run-005-plugin-on`, record the
      SHA. Timestamp: Phase 1 ends. **Gate — allowlist lifts.**
- [ ] 5. Score ∥ three jobs, three transcripts: `./build.ps1`;
      `Invoke-Conformance.ps1` all four tag sets (record cases-defined
      AND cases-run per 0025's rule); `Compare-Graph.ps1`. The first
      scores are the first-shot lines, recorded before anything else
      happens.
- [ ] 6. Iterate ≤3 if under 12/12: each iteration committed and pushed
      to the run branch, tabled with its scores. Final lines = last
      iteration. Never touch `evals/`; never weaken anything.
- [ ] 7. `runs/005-plugin-on/` mirroring run 004's record format:
      plugin-sha, model-version, entrypoint/CC identity,
      session-identifier, iteration table, first-shot AND final lines,
      `findings.md` by mechanism, and a `## Variance vs run 004`
      section — now that the gate has lifted, read
      `runs/004-plugin-on/README.md` and state: score deltas per line,
      differing conformance failures by name, differing functional
      first-shot differences by mechanism (004's were four convention
      decisions, zero edge errors), iteration-count delta, wall-clock
      delta, and whether 004's findings recurred.
- [ ] 8. Acceptance green. Plan/verify/journal. Update LEDGER: Runs
      (last 005, next 006) ONLY — the Pins are already set and correct;
      backlog items 12 and 13 exist; append nothing. Push; fast-forward
      harness main per decision 0009.

## Named spot-checks — verify.ps1 re-derives
1. Fresh clone of `run-005-plugin-on`: import; `build.ps1` exit matches
   the record.
2. `Invoke-Conformance` re-run equals committed result.json, including
   cases-defined = 33.
3. `Compare-Graph` on committed graph.json reproduces diff.txt and the
   final score; with PAT, regenerate live and compare; without, loud
   skip.
4. Oracle blob unchanged; `git diff f25d05d..HEAD -- skills/ commands/
   .claude-plugin/ evals/` empty at verify time.
5. Session identifiers of 004 and 005 read from both READMEs and
   asserted distinct.
6. PAT scan across run record and module clone: zero.

Verify per decision 0004: SHA-pinned, `-FailCheck` probes, scratch-only
writes, one exit code.

## Constraints
AzDO read-only, never queue/create/modify/delete; empty ClaudeTesting
repo untouched (case 12). PAT hygiene absolute. No tag, no target main —
measurement line. Fixture and oracle are never edited for any reason;
their defects are findings.

## Report back
First-shot and final scores, cases-defined/cases-run, iteration count,
phase wall-clocks with parallelism, the full variance section vs 004,
allowlist breaches (zero or itemised), pushed SHAs, and the
session-identifier.
````

## 2. Preconditions

Every precondition the prompt implies was checked before the stop was
declared, so that the operator's next message can supply one missing file
and nothing else.

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | Fresh session, has not read `runs/` | n/a — this prompt is the first message of the session | **PASS.** No file under `runs/` has been read. See D5 for the one leak that did occur. |
| 2 | Agent memory empty (backlog item 12) | `ls -a <project>/memory/` | **PASS.** `.` and `..` only; no `MEMORY.md`. |
| 3 | No auto-loading harness instruction file | `ls -d CLAUDE.md .claude` | **PASS.** Both absent. |
| 4 | Clean working tree | `git status --porcelain` | **PASS.** Empty. |
| 5 | Branch and HEAD | `git rev-parse --abbrev-ref HEAD; git rev-parse HEAD` | `pass-0027-run-005` at `ed7280f84ff8c0939f4fed580aeb7ebf62e4efdf`. |
| 6 | Plugin tier frozen since the pinned SHA | `git diff --stat f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/` | **PASS.** Empty diff. The pinned ladder plugin SHA `f25d05d` is still the plugin. This is spot-check 4's second half, passing before the pass starts. |
| 7 | Oracle blob unchanged | `git ls-files -s \| grep bd7b3c4f…` | **PASS.** `100644 bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc 0 evals/functional/fixture/expected-graph.json`. Blob identity checked; content not read. |
| 8 | Seed and brief committed — task 3's inputs | `git ls-files \| grep -iE 'seed\|brief'` | **PASS.** `evals/functional/BRIEF.md` and `evals/functional/seed/`. Both are supplied through the committed channel, which is why the acceptance test's absence is the only supply failure. |
| 9 | Named harness scripts exist | `git ls-files \| grep -iE 'Reset-Target\|Invoke-Conformance\|Compare-Graph'` | **PASS.** All three under `evals/`. `Reset-Target.ps1` takes `-Destination` and refuses any destination outside `scratch/runs/`. |
| 10 | `runs/005-plugin-on/` does not yet exist | `ls -d runs/005*` | **PASS.** Absent, as a not-yet-run run should be. |
| 11 | AzDO PAT available for the live read | `if ($env:AZDO_PAT) { $env:AZDO_PAT.Length }` | **PASS.** Present, 84 characters. Length only; the value was never printed, logged or written. |
| 12 | Origin reachable | `git ls-remote --heads origin` | **PASS.** `main` = `ed7280f`, equal to local `main` and to this branch's base. |
| 13 | **Acceptance test supplied** | see §4 | **FAIL. This is the stop.** |

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| OS | Microsoft Windows NT 10.0.26200.0 (Windows 11 Home) |
| Model | claude-opus-5[1m] — matches the pinned ladder model version |
| Entrypoint | Claude Code, VS Code extension |
| Branch | `pass-0027-run-005` |
| HEAD at start | `ed7280f84ff8c0939f4fed580aeb7ebf62e4efdf` |
| Stop declared | 2026-09-01T21:58:45Z |

## 4. Acceptance test — not red, and not green: absent

Task 1 is "Acceptance red." It cannot be executed, because there is no
acceptance test to execute.

**It is not committed.** The convention is
`plans/NNNN-<slug>/accept.Tests.ps1`; every full-tier pass from 0015 to
0026 has one. `plans/0027-run-005/` did not exist before this file, and
`git ls-files` lists no acceptance test for run 005.

**It is not in the prompt.** The prompt supplies the last three `It`
blocks and one closing brace of a Pester file. It does not supply the
`$RunDir` assignment, the `Describe`, the `BeforeAll` that binds `$r`, or
the `It` blocks above the ones shown. Both `$r` and `$RunDir` are used by
the supplied text and defined nowhere in it.

The scale of the loss is measurable without reading anything about run
004's results. `plans/0026-run-004/accept.Tests.ps1` — read for its
scaffolding shape only, by grepping for structural lines and for `It`
names — is a `Describe` with a `$RunDir`, a `BeforeAll` binding
`$script:r = Get-Content "$RunDir/README.md" -Raw`, and **ten** `It`
blocks:

```text
It 'has a run README'
It 'records the pinned plugin sha'
It 'records the model version'
It 'records a session identifier'
It 'records seed, brief, target'
It 'records phase wall-clock'
It 'states build'
It 'states conformance on the stable denominator'
It 'states first-shot and final functional lines'   <- supplied
It 'has graph, diff, html, findings'                <- supplied
```

Run 005's test adds `It 'has a variance section vs run 004'`, so it is
presumably eleven. Three arrived. **Eight `It` blocks and the entire
scaffold are missing** — including every assertion that pins the run
record's provenance: the plugin SHA, the model version, the session
identifier, seed/brief/target, phase wall-clock, the build line, and the
conformance line on the stable denominator.

**Evidence that the supplied text is not a test file.** Written verbatim
to a scratch file and run under Pester 6.1.0:

```text
[-] Discovery in …\fragment.Tests.ps1 failed with:
System.Management.Automation.ParseException: At …\fragment.Tests.ps1:6 char:5
+     }
+     ~
Unexpected token '}' in expression or statement.
Tests completed in 111ms
Tests Passed: 0, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
Container failed: 1
```

Zero tests discovered. This is worth stating precisely, because a reader
skimming for a non-zero exit could mistake it for the red that task 1
asks for. It is not. The red task 1 requires is *assertions failing
against a run record that does not exist yet*. What this is, is a file
that does not parse. A parse error proves nothing about run 005, and it
would turn green the moment the braces balanced, whatever the README said.

## 5. Tasks

Not started. Tasks 2 through 8 are unticked in the prompt above and remain
unticked. Nothing was built, no target was reset, no run branch was
pushed, and no Azure DevOps call of any kind was made.

## 7. Command transcript

Every command that changed state, and every command whose output produced
a number appearing above. Exploratory reads excluded.

```bash
git rev-parse HEAD
git rev-parse --abbrev-ref HEAD
git status --porcelain
git diff --stat f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/
git ls-files -s | grep bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc
git ls-files | grep -i -E 'seed|brief'
git ls-files | grep -i -E 'Reset-Target|Invoke-Conformance|Compare-Graph|build\.ps1|Sync-Fixture'
git ls-remote --heads origin
ls -a "C:/Users/jlbal/.claude/projects/<project>/memory/"
ls -d CLAUDE.md .claude
ls -d runs/005*
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString(); (Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString(); [System.Environment]::OSVersion.VersionString'
pwsh -NoProfile -Command 'if ($env:AZDO_PAT) { "AZDO_PAT: present, length {0}" -f $env:AZDO_PAT.Length } else { "AZDO_PAT: absent" }'
grep -n -E '^\s*(Describe|Context|BeforeAll|\}|\$RunDir|\$r )' plans/0026-run-004/accept.Tests.ps1
grep -o "It '[^']*'" plans/0026-run-004/accept.Tests.ps1
# the supplied fragment, written verbatim to the scratchpad and run:
pwsh -NoProfile -Command "Invoke-Pester -Path '<scratchpad>/fragment.Tests.ps1' -Output Detailed"
mkdir -p plans/0027-run-005
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

## 9. Verify script

None. A stopped pass has nothing to disprove: it changed no executable
behaviour, produced no score, and made no claim that re-derivation could
falsify. The preconditions table above is re-runnable line by line, which
is the whole of what this pass asserts.

## 10. Deviations

**D1 — The prompt is truncated, and that is the stop.** The acceptance
test is neither committed nor present in full in the prompt.
`PLAN-PROTOCOL.md` § *File supply* is unambiguous: "A file a pass must
create is either already committed to the repository, or its full content
appears verbatim in the prompt. There is no third channel. … the pass
stops on it rather than searching or inventing." It also records that the
rule has already cost a pass twice — once silently, when a missing draft
blocked a task and the pass carried on without saying so, and once loudly
— and that "the loud failure is the correct behaviour." Pass 0025 stopped
the same way (`116d50c`, "paused on a truncated prompt"). This is that
stop, on the same rule, from the same cause.

**D2 — Why the missing blocks were not reconstructed.** They could be
guessed; run 004's `It` names are right there, and the diff between the
two tests is probably one new `It`. Two reasons not to.

The first is the protocol's own: an agent that writes the assertions it
will then be graded against is writing to the test. The eight missing
blocks are precisely the eight that pin provenance — plugin SHA, model
version, session identifier, seed/brief/target, wall-clock, build,
conformance denominator. A reconstructed accept test that quietly omits,
loosens, or misspells one of those would grade a run 005 record that never
had to prove it, and would pass. Those are the assertions a blind
measurement can least afford to have authored by the thing being measured.

The second is that Phase 1 is not repeatable. A blind build happens once
per session; a wrong guess would not surface until the operator's real
test ran at task 8, after the run branch was pushed and the record
written, and the run would be void with no way to re-run it from this
session. The cost of being wrong is the whole run. The cost of stopping is
one message.

**D3 — No pass header.** The prompt has no header, so no pass number and
no tier. `PLAN-PROTOCOL.md` § *Pass numbering*: "The agent never invents a
pass number. A prompt arriving without one is a stop." `0027` here is read
from the operator-created branch `pass-0027-run-005` and from
`plans/0026-run-004/`, which is reading rather than inventing, but it is
not the stated channel and is recorded as a deviation. The tier is
likewise unstated; run-record passes have been full tier (0026 shipped a
`verify.ps1`), and this stop record changes no executable behaviour.

**D4 — The LEDGER's Passes counter is stale, and one pin with it.** Not
asked about; found at preconditions.

- `## Passes` reads "Last landed: 0025. Next: 0026." Pass 0026 has landed:
  `plans/0026-run-004/`, `journal/0026-run-004.md`, branch
  `pass-0026-run-004`, and `origin/main` at its tip `ed7280f`. The line
  should read "Last landed: 0026. Next: 0027." The `## Runs` line beside
  it *was* advanced to "last 004, next 005" in that same commit, so this
  is a half-applied update rather than a forgotten one — which is the more
  interesting failure, because the half that was applied is the half a
  reader is likely to check.
- `## Pins → Harness main` reads "pass-0025-findings-batch tip". Main is
  now `ed7280f`, the pass-0026 tip. The prompt's task 8 states "the Pins
  are already set and correct"; this one line is not. The others are:
  ladder plugin SHA `f25d05d` — **correct**, precondition 6 proves the
  plugin tier unchanged since it; model version `claude-opus-5[1m]` —
  **correct**, matches this session; oracle blob — **correct**,
  precondition 7.

Not corrected here. Task 8 is where the LEDGER is written and task 8 was
not reached, and a stopped pass editing counters for work it did not do is
how a ledger stops being trustworthy.

**D5 — One contamination leak, recorded rather than hidden.** `git log`,
run to establish HEAD and branch at preconditions, prints commit subjects,
and `ed7280f`'s subject is "Run 004: the first plugin-on rung, 12/12 and
33/33". Run 004's headline scores are therefore known to this session
without `runs/` having been opened.

Assessment: it does not disqualify a blind build. The blind-run hazard is
knowledge of *the fixture's answers* — what the graph should contain,
which conformance cases failed, which conventions run 004 chose. A pair of
totals carries none of that and cannot tell a builder what to build. It
does mildly bias the `## Variance vs run 004` section at task 7, which is
written after the gate lifts and against the full README anyway.

Worth the operator's attention as a hygiene defect in its own right:
**run-record commit subjects are the one part of `runs/` that no session
gate can exclude**, because reading HEAD is a precondition of every pass.
If that matters, the fix belongs in the commit-message convention — "Run
004: the first plugin-on rung", and leave the scores to the record — not
in anything a session can do about itself. Offered for backlog item 12's
eventual `HARNESS.md` entry; deliberately not appended to the LEDGER, per
task 8's instruction to append nothing.

**D6 — What was deliberately not read.** To keep this session eligible to
execute run 005 blind if the operator supplies the missing test:
`runs/**` (nothing), `plans/0026-run-004/plan.md` and its `verify.ps1`
(nothing), `plans/0025-findings-batch/plan.md` (nothing — it discusses the
run 002 and 003 clones), and `evals/functional/fixture/expected-graph.json`
(blob SHA only, never content). `plans/0026-run-004/accept.Tests.ps1` was
read structurally — `grep` for `Describe`/`BeforeAll`/`$RunDir` and for
`It` names, both quoted in §4 — and not otherwise. That file asserts the
*shape* of a run README and contains no fixture answers; the prompt's own
fragment is three of its assertions, so its format is pre-gate knowledge
by the operator's own framing.

## 11. Cost

No wall-clock is reported. The pass stopped at task 1, before the task 2
timestamp that starts the clock, and no start timestamp was taken at
preconditions — so any duration here would be a figure with no artifact
behind it, which this protocol does not allow. The stop timestamp is in
§3.

Zero suite runs, zero build invocations, zero probe rows, zero Azure
DevOps calls. One Pester invocation, on a scratch copy of the supplied
fragment, which discovered no tests.
