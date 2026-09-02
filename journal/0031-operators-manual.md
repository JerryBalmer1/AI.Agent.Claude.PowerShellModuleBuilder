---
pass: 0031
title: The operator's manual, the testing reference, and a publish path that refuses
date: 2026-09-01
artifacts:
  - docs/creating-an-agent/ (eleven chapters)
  - docs/testing/README.md
  - .build.ps1
  - tools/publish/Publish-Local.ps1
  - tools/publish/Publish-Real.ps1
  - README.md
  - LEDGER.md
  - plans/0031-operators-manual/plan.md
  - plans/0031-operators-manual/verify.ps1
  - plans/0031-operators-manual/accept.Tests.ps1
  - plans/0031-operators-manual/audit-run-006.txt
  - plans/0031-operators-manual/publishlocal-transcript.txt
  - plans/0031-operators-manual/publishreal-guard.txt
---

# Pass 0031 — The operator's manual, the testing reference, and a publish path that refuses

## Asked

Write the manual that lets somebody else do this: eleven chapters under
`docs/creating-an-agent/`, in a voice where the reader is the hero and every
concept links the real pass, run or decision in this repository as its worked
example. Add `docs/testing/README.md` for a reader deciding whether the rigour
is worth it. Mark the project-specific spans of README and the manual with
`TEMPLATE:remove` / `TEMPLATE:replace`, in the documentation tier only. Add a
thin root `.build.ps1` with `PublishLocal` (stage a marketplace under
`scratch/`) and `PublishReal` (a guard that refuses until packaging lands), and
falsify both. Point the README at all of it. Leave `skills/`, `commands/`,
`.claude-plugin/`, `evals/` and `method/` untouched.

## Done

- **`docs/creating-an-agent/`** — eleven chapters, drafted by six parallel
  subagents against per-chapter briefs and reviewed serially in this session.
  The review re-derived rather than trusted: every quotation re-checked against
  its source with whitespace collapsed and a case-sensitive operator, every
  number traced to the file it came from, every relative link resolved.
- **`docs/testing/README.md`** — 655 lines, eight sections, each linking its
  artifact under `evals/` or `runs/`.
- **`.build.ps1`** and **`tools/publish/`** — two tasks, no logic at the root.
  `Publish-Local.ps1` stages, validates and prints; `Publish-Real.ps1` refuses
  and has no push path at all. Both falsified.
- **`README.md`** — the "Creating a new agent, start here:" section, the
  `docs/testing/` line, the "Try it locally" line, and eight marker blocks.
- **`plans/0031-operators-manual/`** — plan, `verify.ps1`, the acceptance test,
  and three transcripts: the worked audit of run 006, the PublishLocal run with
  its falsification rows, and the PublishReal guard with its clone-only flip.
- **`LEDGER.md`** — passes advanced; the doc-maintenance obligation appended
  as item 19; three new findings as 20, 21 and 22.

## Why

**The audit chapter had to contain a real audit, so one was run.** Chapter 05
claims you should never believe a report and always read the remotes. A chapter
making that claim while quoting numbers out of a run README would be refuting
itself on the page. So run 006 was audited end to end against the live remote —
`ls-remote`, clone at the claimed SHA, build from nothing, both scorers re-run,
result files diffed field by field, `merge-base --is-ancestor` for the ancestry
claim — and the transcript is committed beside the plan. Everything agreed.

**The audit's two near-misses were kept in the transcript, and they are worth
more than the agreements.** It printed a field called `CasesPassed` and got a
blank, because the result file has no such field. Then it went looking for the
functional `12 / 12`, found `cases: []`, and nearly concluded the claim was
unsupported by its own artifact — until reading `Compare-Graph.ps1` showed that
the array holds the cases a difference *touched*, so an empty array is exactly
what twelve of twelve looks like. **The score is recorded as an absence.** An
audit that had stopped there would have manufactured a finding out of its own
ignorance of the format, which is worse than not auditing, because it looks
like rigour.

**`PublishReal` has no push path, rather than a guarded one.** METHOD.md
reserves publishing to the operator's own shell. A `-Force` flag would make
that a matter of restraint; its absence makes it a matter of code, and this
project's whole argument is that those are different things.

**The two publish falsifications are a break and a control, not two breaks.**
Corrupting a byte proves the validator can go red. It does not prove the
validator is checking validity rather than refusing change — for that, the
control adds a harmless key, still valid JSON, and requires green. The
validator is one function reachable from both the staging path and
`-ValidateOnly`, so the control grades exactly the code the publish path runs;
re-staging would have erased the corruption and proved nothing.

## Measured

- Acceptance: **2 passed, 7 failed** before the work; **9 passed, 0 failed**
  after. Both of the initial passes were vacuous — they iterate directories
  that did not exist, so the loop body never ran.
- **Worked audit of run 006, every claim re-derived**
  (`plans/0031-operators-manual/audit-run-006.txt`): remote tip of
  `run-006-plugin-on` = `70669167ea5f59a47efb282002052f9e926a34bf`, equal to
  the claimed `target-sha`; clone `rev-parse HEAD` equal to both; build in the
  clone exit 0, 95 tests passed, coverage 89.81% against a declared 70%;
  conformance re-run **57/57 tests, CasesDefined 33, CasesRun 57, ScorePct
  100**, field-for-field equal to the run's committed
  `conformance-result.json`; `Compare-Graph` on the run's committed
  `graph.json` returns `agree: true`, `differenceCount: 0`, no affected cases —
  equal to the run's committed `compare-report.json`;
  `merge-base --is-ancestor` exit **1**, which is the answer decision 0008's
  amendment requires.
- **Instrument pin.** `git diff f25d05d..HEAD -- skills/ commands/
  .claude-plugin/` — **empty**. The four-path form including `evals/` is not
  empty and has not been since pass 0029 (`evals/HARNESS.md`, +69). Pass 0031
  changed **nothing** under any of the four paths; `verify.ps1` asserts that
  directly.
- **PublishLocal**: 20 files staged, **14 skills, 2 commands**, byte-identical
  to the repository's copies across 19 files compared, tree hash identical
  across two consecutive runs. `claude` CLI not on PATH, and the script says so
  rather than skipping quietly.
- **Falsification, PublishLocal**: break — `marketplace.json` byte 0 `0x7B` →
  `0x21`, sha256 changed, `-ValidateOnly` exit **1**, "does not parse as JSON":
  fires. Control — a harmless extra key, sha256 changed, exit **0**: correctly
  stays green. Scratch-root rail — `-StageRoot ./skills` exit **1**, `REFUSED`,
  `git status --porcelain skills` empty.
- **Falsification, PublishReal**: refuses at exit **1** with `GUARD: refused`,
  via InvokeBuild and directly. In a clone, a dummy `marketplace.json` flips it
  to the checklist path at exit **0**, still pushing nothing; the working
  repository confirmed afterwards to have no `marketplace.json`.
- **Markers**: **19** marker lines across README and the manual — 8 blocks in
  README, 11 in the chapters. The applying script was run four times with the
  file hash compared, stable after the first.
  Zero markers under `skills/`, `commands/`, `evals/` or `method/`.
- **`evals/tf/Compare-TfGraph.Tests.ps1` is red on `main`**: `Invoke-Pester`
  returns **14 passed, 1 failed**. Line 41 asserts 57 expected edges; the
  decision-0012 oracle holds 59 and the comparator returns 59.

## Learned

- **A guard can print its whole refusal and report success.** The first
  `.build.ps1` invoked its scripts with `&` in-process. `Invoke-Build
  PublishReal` printed `GUARD: refused` and twenty lines of explanation and
  then reported *Build succeeded. 1 tasks, 0 errors, 0 warnings*, because
  `exit 1` inside a `&`-invoked script unwinds that script and sets no
  `$LASTEXITCODE` InvokeBuild can see. The message was right and the exit code
  was wrong, and only the exit code is the gate. Found by looking at
  `$LASTEXITCODE` rather than at the output — which is the whole of chapter
  05's thesis, met while writing chapter 05.
- **My own idempotence guard failed twice, silently, while reporting
  success.** The marker script printed `markers inserted: 8` on its second run
  and duplicated all eight. The first guard checked the line immediately above
  the heading and found the block's trailing blank; the second looked further
  back and broke on the block's own continuation lines. Both reported the
  correct-looking number. Caught by running it twice and counting the file,
  not by reading it. Hazard 4, met in a tool nobody would have thought to
  falsify.
- **Two of six drafting subagents reported near-false-greens in their own link
  checkers, and both were the same defect.** One used
  `Get-ChildItem -Filter '0[01]-*.md'`, which matched zero files because the
  filesystem filter does not support character classes, and printed
  `ALL LINKS RESOLVE` over an empty set. That is hazard 6's *a run of zero rows
  is not a pass*, arriving inside the tooling written to check this pass's own
  work, twice, independently.
- **The pass's own acceptance test contains two vacuous assertions, and the
  right move was to report them rather than repair them.** Both iterate
  `Get-ChildItem` over directories that did not exist at red-first, so the loop
  body never ran and an assertion grading nothing reported green. The prompt
  supplied the file verbatim; the file-supply rule makes it the pass's job to
  run it as given and say what it saw.
- **Delegated drafting changes what a review is for, and three of the four most
  useful findings this pass produced came out of it.** No chapter's prose was
  written by the session that reviewed it. Two subagents refused a claim in
  their own brief and proved the refusal from the artifacts — the
  "stopped itself three times" framing, and the pass number attached to the
  33-untracked-files event. A third found that `PLAN-PROTOCOL.md`'s own worked
  example contains a false clause about pass 0012. A fourth re-ran the
  Terraform oracle instead of quoting it and found a red test on `main`. An
  agent that had accepted its brief would have produced four confident
  falsehoods instead.
- **The prompt's instrument pin was stale for the second consecutive pass.**
  The LEDGER has recorded the correct form since 0029, and two prompts since
  have carried the old one. A note in the ledger is not a fix; it is a message
  to whoever reads the ledger, and prompts are written by someone who may not.

## Capability

Somebody who is not the author can now be handed this repository and find out
what to do with it: eleven chapters that name the build order with real pass
numbers beside each stage, a testing reference that says what each layer
catches and what it does not prove, a paste-able local install that never
touches the network, and a publish path that refuses to publish. The audit
loop is written down as commands with a worked example behind it, so the claim
"do not trust the report" comes with the transcript of somebody not trusting
one. And the repository can be stripped for reuse: sixteen markers enumerate
every span that is this project's rather than the method's, and `verify.ps1`
asserts none of them leaked into the instrument.
