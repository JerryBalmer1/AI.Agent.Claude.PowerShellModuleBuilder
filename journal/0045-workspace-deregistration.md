---
pass: 0045
title: Deregister PSModuleGraph from the PSGraphRender workspace
date: 2026-09-03
artifacts:
  - plans/0045-workspace-deregistration/plan.md
  - plans/0045-workspace-deregistration/verify.ps1
  - LEDGER.md
---

# Pass 0045 — Deregister PSModuleGraph from the PSGraphRender workspace

## Asked

Delete the `{ "path": "../PSModuleGraph" }` folder object from
`PSGraphRender.code-workspace`, leaving `{ "path": "." }` and the `settings`
block byte-identical, and close LEDGER backlog 60. Observe the pass-0044
`Workspace composition` assertion red against the real repository before the
edit and green after; do not re-derive the assertion. One line in
`docs/HANDOFF.md` under a pass-0045 heading, its own commit. Harness records:
plan, `verify.ps1` with a `-FailCheck` polarity pair, LEDGER, journal.
Fast-forward both mains, no tag. Two spot-checks with red demos: the diff is
minimal, and the suite still runs against the target with only that one score
line moved. Backlog 61 explicitly out of scope.

## Done

`PSGraphRender`, branch `pass-0045-workspace-deregistration`, two commits, both
fast-forwarded onto `main`:

- `3973644` — `PSGraphRender.code-workspace`, 99 → 60 bytes, three lines removed
  and none added. Written with `printf` so the tabs, the LF line endings and the
  absent final newline survive.
- `cd4857d` — `docs/HANDOFF.md`, a `### Pass 0045` heading and one sentence at
  the end of the state section.

`AI.Agent.Claude.PowerShellModuleBuilder`, branch
`pass-0045-workspace-deregistration`, fast-forwarded onto `main`:

- `plans/0045-workspace-deregistration/plan.md`
- `plans/0045-workspace-deregistration/verify.ps1`
- `LEDGER.md` — counter to 0045; item 60 marked RESOLVED by pass 0045 in place
  with its number kept; item 62 added.
- `journal/0045-workspace-deregistration.md`

No tag in either repository. No module source, no build file, no test file, and
no other file in `PSGraphRender` changed. `scratch/PSModuleGraph` was not
touched, and nothing in the pass reached Azure DevOps.

## Why

The registration was inert — `../PSModuleGraph` has not existed at the workspace
root since pass 0043 moved the clone into `scratch/` — and that is the argument
for deleting it rather than against. An inert wrong entry is one that survives:
two sessions of 0043 looked for the reference and reported the repository clean,
because both looked for a directory on disk rather than for the file that puts
one there. The next `git clone` of PSGraphRender into a workspace that happens to
have a sibling by that name resurrects it silently.

The comma after `{ "path": "." }` went too. It is the array separator between two
elements and one element is gone; it belongs to neither object, so both objects
the prompt named are still byte-identical. Leaving it would have been legal
JSONC and a `folders` array the next reader has to stop and think about.

`verify.ps1` **measures** `CasesRun` at the base commit and at the branch head
rather than pinning the 161 this pass observed. Decision 0004 says pins are not
maintained forward, which is an argument for pinning a number that describes this
pass — but this number does not describe the pass. It describes the shape of the
tree it was measured in, and the local tree has an untracked `output/` directory
that a fresh clone does not. A pin would have reported that difference as a
failure of the pass. Measuring twice asserts the thing SC2 actually claims: that
the edit did not change what the suite discovers.

The `-FailCheck` probe copies the whole cloned repository rather than the one
file. The assertion finds its subject with `git ls-files '*.code-workspace'`, so
a damaged file in a bare directory is never discovered and the probe would report
ZERO CASES — which 0044 already paid for once, and which a probe reports as
"nothing to check" rather than as "the check never ran".

Rejected: re-dating `## State, as of pass 0043` in `docs/HANDOFF.md` while adding
the 0045 line. It would have been tidier and it would have claimed this pass
re-checked what that section says about 0043, which it did not.

Rejected: fixing backlog 62 on sight. It is one character in
`Invoke-Conformance.ps1`, in a pass that had that repository open. A
one-character fix with no test is how three copies of the same regex came to
disagree in the first place, and the pass's writable scope in the harness was its
own records.

## Measured

| | Value | Artifact |
|---|---|---|
| Workspace file | 99 → 60 bytes, blob `b2ac63d` → `876a149` | `git hash-object`, plan §5 task 2 |
| Workspace commit diff | 1 file, +0 / −3, one `"path":` line removed | `git diff --numstat`, plan §7 SC1 |
| Assertion before the edit | passed 0, failed 1 — RED, 0 broken containers | plan §4 |
| Assertion after the edit | passed 1, failed 0 — GREEN, 0 broken containers | plan §5 task 3 |
| Suite `CasesRun` | 161 before, 161 after (and 161 in a fresh clone at both commits) | plan §7 SC2, `verify.ps1` check 4 |
| Suite `CasesDefined` | 36, unchanged | same |
| Suite failures | 57 → 56 | same |
| `ScorePct` | 64.6 → 65.22 | same |
| Score lines that moved | 1 of 34 | `Compare-Object`, plan §7 SC2 |
| Falsification driver | 5 of 5 rows correct, exit 0 | `plans/0044-method-corrections/Test-WorkspaceFalsification.ps1` |
| `verify.ps1` | exit 0, 11 assertions | plan §10 |
| `verify.ps1 -FailCheck` | exit 0, 11 assertions + 4 probes, every probe landed | plan §10 |
| Full suite runs | 6 | plan §12 |
| Builds | 0 | — |

## Learned

**The instrument had a defect the pass had to route around, and it was found by
running the instrument rather than by reading it.**
`Invoke-Conformance.ps1:122` excludes `output`, `scratch`, `.git`, `gallery`,
`fixtures` and `node_modules` from manifest discovery with `[\/]`, where
`Conformance.Tests.ps1:61` and `:148` do the same job with `[\\/]`. Inside a
character class `\/` is an escaped forward slash and nothing else, so the
runner's exclusion has never fired on a Windows path — every path it tests is a
Windows path built by `Substring` on a `FullName`. The visible symptom was the
runner refusing to derive `-ModuleName` for `PSGraphRender`, having counted
`output/PSGraphRender/PSGraphRender.psd1` as a second candidate named for the
target. The refusal is the good failure direction and it is luck: the same defect
admits a `scratch/` or `gallery/` manifest into the candidate set, where F-8's
own comment says the outcome — grading the wrong module silently — is worse than
grading nothing. LEDGER backlog 62.

**A near-miss on the pass's own record.** Backlog 62's entry is *about* the
difference between `[\/]` and `[\\/]`, and the first write of it collapsed one of
the two into the other, so the entry stated that the runner and the suite write
the same regex. Caught by reading back the committed bytes rather than trusting
the write. A record whose subject is an escaping difference is one that escaping
can silently destroy, and re-reading is the only thing that catches it.

**A three-source frontier that agrees is worth the two extra reads it costs.**
All three read 0044, and the pass took fifteen seconds to establish that. The
check exists because commit `b404734`, immediately before 0044, was a correction
of exactly the drift it guards.

**The green did not need arguing for.** The pass ran the 0044 falsification
driver unchanged and got five correct rows, then made `-FailCheck` show the same
assertion going red against a scratch copy of the real repository. Two independent
demonstrations that the instrument could still fail, on either side of a green
that took one line to produce.

## Capability

`Workspace composition` now carries no standing red among the repositories the
suite can reach, so the next red from it is a new violation rather than one more
line in a known-failure list. That is what the assertion could not do while
PSGraphRender failed it permanently: a check with a standing red is read as a
list, and a check with none is read as a signal.

One repository it applies to is still outside that claim. The harness has a
tracked `.code-workspace` of its own, the suite cannot run against the harness at
all (backlog 61), and the only thing covering that file is a check inside pass
0044's `verify.ps1` — a frozen plan artifact, not a standing guard.
