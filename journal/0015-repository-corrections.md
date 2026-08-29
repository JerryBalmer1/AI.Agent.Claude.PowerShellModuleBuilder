---
pass: 0015
title: Repository corrections before the discovery run
date: 2026-08-29
artifacts:
  - plans/0015-repository-corrections/plan.md
  - plans/0015-repository-corrections/accept.Tests.ps1
  - plans/0015-repository-corrections/verify-runs/0011.txt
  - plans/0015-repository-corrections/verify-runs/0012.txt
  - plans/0015-repository-corrections/verify-runs/0014.txt
  - evals/functional/BRIEF.md
  - evals/conformance/TASK.md
  - decisions/0005-branch-and-merge-policy.md
---

# Pass 0015 — Repository corrections before the discovery run

## Asked

Four corrections before the discovery run, two of which change or characterise
its inputs: correct the brief's case count from ten to twelve, observe the three
verify scripts for passes 0011, 0012 and 0014 at their own landing commits and
record the exit codes, mark `evals/conformance/TASK.md` superseded so its
"continue from the first unfinished step" sentence stops reading as a live
instruction, and record the branch policy as decision 0005. No executable
behaviour changes; no assertion, script, hook, skill, manifest or runner
modified. The module is not built this pass and no run is scored.

## Done

- `evals/functional/BRIEF.md` — three lines, `ten cases` to `twelve cases`, at
  lines 42, 83 and 99. Blob `d0cd8c5` to `93c5cec3299da0ac27d3aea67f4fbcf0000001ec`.
- `evals/conformance/TASK.md` — four-line supersession blockquote inserted after
  the heading, citing `6655e1c` and `64fee46`. Five lines added, none removed.
- `decisions/0005-branch-and-merge-policy.md` — new; one branch per pass, only
  the operator moves `main`, "fresh clone" means the pass branch, history is
  never rewritten.
- `plans/0015-repository-corrections/verify-runs/{0011,0012,0014}.txt` — the
  complete output of each verify script run at its own landing commit, each
  ending in an observed `EXIT CODE:` line.
- `plans/0015-repository-corrections/accept.Tests.ps1` — six assertions,
  verbatim from the prompt.
- `plans/0015-repository-corrections/plan.md`.

## Why

**The three verify scripts were run in child processes, not dot-sourced.** A
script run in the current session leaves `$LASTEXITCODE` untouched unless it
calls `exit`, so an exit code read that way is partly a guess about the script's
control flow. `pwsh -NoProfile -File` produces a real process exit code that
means what the acceptance test says it means. Rejected: parsing the final
`VERIFY:` line out of the output, which would record what the script *said*
rather than what it *returned* — and the debt being closed here is precisely
that nobody had observed the return.

**Each script was run at its own landing commit in a detached worktree, not at
the branch tip.** Decision 0004 freezes plan artifacts, so a verify script that
went red at the tip could not be fixed anyway; running it where it was written
is the only reading that distinguishes "the script was wrong" from "the
repository moved underneath it". Rejected: running all three at `4dfbff0`, which
would have conflated the two.

**The decision file was not edited to say `origin/main`.** Its two numbers are
true of `origin/main` and false of the local `main` ref, and the temptation was
to disambiguate the text. Decision files are records of what was decided;
correcting one in flight makes the record follow the repository instead of the
other way round. The ambiguity is written up in the plan's Deviations instead.

**The untracked leftover was deleted rather than committed.** The standing rule
is to commit unrelated dirt alone, never revert it. Committing here would have
moved HEAD off the SHA precondition 1 asserts literally and precondition 2 uses
as the branch point, so the rule and the preconditions could not both be
honoured. The file was this session's own uncommitted output from an aborted
prompt, so deletion cost nothing recoverable — but the rule was still broken,
and it is flagged as D1 rather than absorbed.

## Measured

- **Acceptance test**: red **0 passed, 6 failed** (Pester exit 6); green
  **6 passed, 0 failed, 0 skipped**. `plans/0015-repository-corrections/accept.Tests.ps1`.
- **Three observed exit codes, all 0**, quoted back out of the written files:
  `0011.txt:EXIT CODE: 0`, `0012.txt:EXIT CODE: 0`, `0014.txt:EXIT CODE: 0`.
  0014 reports `(0 skipped)` explicitly; `$env:AZDO_PAT` was set for all three.
- **BRIEF.md**: `1 file changed, 3 insertions(+), 3 deletions(-)`; `ten cases`
  count 3 to **0**, `twelve cases` count 0 to **3**; 0 CR bytes.
- **TASK.md**: `1 file changed, 5 insertions(+)`; 442 to 447 lines.
- **0014 drift**: `git diff 57a449b 4dfbff0 --stat` names one file and one
  changed line — the `$WrittenAgainstSha` pin. Clean.
- **`origin/main` is 21 commits behind** `pass-0009-control-polarity`, tip
  `d1647fa` and parent `d432c38`, both named "force agent stop", on `c1cf7ec Init`.
  Local `main` at `51e2131` is **diverged**, 12 behind.
- **Worktrees**: 3 created, 3 removed; `git worktree list` ends at one entry.
- Azure DevOps objects created or modified: **0**. Pipelines queued: **0**.

## Learned

**The verify debt was a bookkeeping gap, not a defect.** All three scripts
passed at their landing commits with zero skips. The value of the pass is not
that it found breakage — it found none — but that three exit codes that had been
*assumed* for three passes are now *observed* and quoted from files. Recorded as
a negative result on purpose: an unrun check and a passing check are
indistinguishable until someone runs it, and the whole point of the harness is
that this distinction is never left implicit.

**Checking a prompt's claims against the wrong ref manufactured two phantom
errors.** Decision 0005 says `main` is 21 commits behind with two "force agent
stop" commits at its tip. Checked against the local `main`, that reads as 12
commits and a completely different tip — two apparent factual errors in an
operator-supplied file. Both dissolved against `origin/main`. The local `main`
has diverged from `origin/main`, so the bare word `main` in this repository
denotes two different histories depending on who reads it. This is the exact
hazard decision 0005 was written to fence off, and it demonstrated itself during
the act of recording the decision.

**A prompt's literal old-string was a prefix of the real line, and a line-address
substitution absorbed it without noticing.** The prompt quotes line 42 up to the
sentence end; the file's line 42 continues. Because the edit was applied as a
substring substitution at a named line address, it succeeded and produced the
right bytes. A stricter whole-line replacement would have failed loudly. The
looser tool got the right answer and told me less — worth remembering the next
time an edit method is chosen for a prompt that supplies exact old-strings.

**The discovery run cannot start from its own allowlist.** Established before
this pass, while attempting the prompt this one replaced: nothing in
`seed/`, `BRIEF.md` or `graph.schema.json` names the Azure DevOps organisation
or project, `$env:` carries only the PAT, and the PAT lacks `vso.profile` so the
accounts API returns 401 and cannot enumerate its own organisations. A blind
Phase 1 therefore has no way to locate the fixture it exists to read. Recorded
as D7 because it belongs to a prompt that produced no plan of its own.

**Running this pass contaminated the session for the discovery run.** Capturing
the three verify scripts' complete output — required by task 4 — printed fixture
repository names, aliases, unresolved targets and the cycle into this session.
Harmless here, disqualifying there. The discovery run needs a fresh session, and
nothing in the repository would have recorded that if the plan had not said so.

## Capability

The discovery run can now be started against inputs that agree with the fixture:
its `brief-sha` names a BRIEF that says twelve cases, matching the twelve the
comparator scores and the twelve `Mutate-Graph.ps1` can falsify — so a run
scored `N / 12` can no longer be read against a brief promising ten. The
harness's three existing verify scripts now have observed exit codes on file
rather than assumed ones, so a future regression in any of them is detectable as
a change from a recorded number. And `main` is no longer load-bearing: decision
0005 states which ref a verify script's "fresh clone" means, so the divergence
between local `main` and `origin/main` can no longer silently decide what a
verification ran against.
