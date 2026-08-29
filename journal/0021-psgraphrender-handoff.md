---
pass: 0021
title: Hand PSGraphRender over and archive what ran it
date: 2026-08-29
artifacts:
  - plans/0021-psgraphrender-handoff/plan.md
  - plans/0021-psgraphrender-handoff/accept.Tests.ps1
  - plans/0021-psgraphrender-handoff/verify.ps1
  - decisions/0010-ecosystem-repo-governance.md
---

# Pass 0021 — Hand PSGraphRender over and archive what ran it

## Asked

Mark PSGraphRender's pre-handoff state with an annotated tag, add the vendor
tooling its manifests had only ever described in prose, strip the resident
agentic workflow (`CLAUDE.md`, `.claude/`, the thread ledger and its tool and
its two tests), carry everything durable in them into a new `docs/HANDOFF.md`,
and release it as `v0.13.0` with `main` fast-forwarded. Record the governance
decision in the harness. Three of the tasks to run as parallel jobs.

## Done

- PSGraphRender `main` at `964d73a4db2d13ed6a5873a53a8607a1ecc1a71a`,
  fast-forwarded from `4a367c6a…` after `git merge-base --is-ancestor` returned
  0. Branch `pass-0021-handoff` pushed. Tags `handoff-begin-2026-08-29`
  (dereferencing to `4a367c6a…`) and `v0.13.0` (to `964d73a4…`), both annotated.
- One commit, 41 files, +1403 −3365. Deleted `CLAUDE.md`, `.claude/` (6 files),
  `docs/threads.json`, `tools/threads.ps1`, `tests/Ledger.Tests.ps1`,
  `tests/Instructions.Tests.ps1`. `knowledge/ledger/` moved to
  `docs/ledger-archive/` as 13 renames, so history follows.
- Added `docs/HANDOFF.md` (236 lines), `docs/vendoring.md` (232),
  `tools/Update-Vendor.ps1` (647), `docs/worklog/v0.13.0.md` (111),
  `docs/ledger-archive/README.md`.
- Harness `main` at `8f7eb3a`, carrying
  `decisions/0010-ecosystem-repo-governance.md`, the plan, the acceptance test
  and `verify.ps1`, plus one unrelated commit for an editor-written workspace
  change that made the tree dirty at preconditions.
- Untouched, as required: PSModuleGraph, PSAzureDevOpsGraph, PSGraphRenderToHtml,
  PSTerraformGraph, `contract/viewmodel.schema.json`, both vendored `.js` files.

## Why

The seventeen open threads went into `HANDOFF.md` and the twenty-four
PSModuleGraph ones did not. `docs/threads.json` was a merged record across two
repositories, and filing another repository's threads under this one's handoff
would misfile them — they are live in PSModuleGraph, where they can be acted on.
Four of them are about this seam and are carried as a named subsection instead,
so the renderer's handoff says what its only consumer is still carrying about it.

Historical citations were repointed rather than deleted. A doc saying "*Ledger
`0008-t3`*" is still true after the ledger becomes an archive; the entry it
cites still exists, at a new path. Only *live pointers* — "see
`.claude/skills/instruction-prune/SKILL.md`" — were removed, because those break.
CHANGELOG entries under past version headings were left entirely alone: they
record what those releases contained, and editing them would falsify the history
this pass is trying to preserve.

`docs/render-architecture.md`'s decision log got a new dated entry rather than an
edit to the 2026-08-26 one. That log is append-only, and the old entry is still
true — it recorded why the knowledge store was never mirrored into this
repository, which is precisely why there was only a ledger to archive.

Rejected: adding a gate that the module manifest agrees with the tag. The
manifest was found a release behind (`0.11.0` at tag `v0.12.0`) and was
corrected, but building the gate that would catch it next time is a separate
change with its own falsification, and doing it inside a handoff pass would put
an unfalsified gate in the same commit as the removal of the machinery that used
to hold the gates. Logged instead.

Rejected: fixing `docs/contract.md`, which says the contract is 1.0.0 and the
module 0.3.0 when both are wrong. The pass constraints put the schema out of
scope, and a stale sentence discovered in passing is a finding to report, not a
licence to widen the diff.

## Measured

From `scratchpad/baseline-build.txt` and `scratchpad/final-build.txt`, both
quoted in `plans/0021-psgraphrender-handoff/plan.md`:

| | baseline (v0.12.0) | final (v0.13.0) | delta |
| --- | --- | --- | --- |
| default build, passed | 127 | 122 | −5 |
| default build, not-run | 15 | 9 | −6 |
| `-Task PreTag`, passed | 15 | 9 | −6 |
| line coverage | 81.75% | 81.75% | 0 |
| browser pages | 6 | 6 | 0 |

The −5 is `tests/Instructions.Tests.ps1`'s five tests; the −6 is
`tests/Ledger.Tests.ps1`'s six, which are `PreTag`-tagged and so appear as
not-run in the default run and as passed in the `PreTag` run. Nothing else moved.

Acceptance: 0 passed / 7 failed before, 7 passed / 0 failed after
(`scratchpad/accept-red.txt`, `scratchpad/accept-green.txt`).

`verify.ps1 -FailCheck`, from a fresh clone of the pushed tag: **22 checks, 0
failed**.

Group A: 3 jobs in parallel, 875s wall against 1850s of job time (875 + 707 +
268).

Thread salvage, re-derived by hand from `docs/threads.json` and confirmed
against `tools/threads.ps1` before both were deleted: 112 raised, 41 open, 46
closed, 24 accepted, 1 superseded. 17 of the 41 belong to PSGraphRender.

## Learned

**A falsification probe can fail to falsify anything and report green.** The
first tamper probe passed a git-bash path into `pwsh`, which resolved it as
`C:\c\Users\…`; the write failed, the file was never modified, and `-Verify`
returned 0 — the correct answer for an unmodified file and a worthless
falsification. The before/after hash comparison caught it. This is the exact
failure the practice exists to prevent, committed while applying the practice.
`verify.ps1` now asserts the break landed before trusting the check, behind
`-FailCheck`.

**Two parallel jobs can silently share an output file.** The task-5 grep sweep
ran patterns `CLAUDE` and `\.claude` whose output basenames collided on a
case-insensitive filesystem. One overwrote the other and the surviving counts
looked entirely plausible; the re-run found 7 hits the first pass had lost.
Parallelism that writes to derived filenames needs the filenames proved distinct.

**The documentation of a gate can rot independently of the gate.**
`docs/testing.md` described the `PreTag` gate as "one test", naming the only
`PreTag` test this pass deletes and omitting the three that survive. The gate was
green throughout and never wrong; only the prose was. Both a subagent and my own
survey found it independently, which is the only reason it did not ship.

**Extraction found less than expected, and that was the useful result.** Two of
the three facts the prompt named as certainly-orphaned were already documented.
The genuinely missing material was elsewhere: the gate-falsifiability method
itself returned zero hits for `falsifiab` anywhere under `docs/`. The
documentation had recorded instances of the practice for twelve releases without
ever recording the rule.

**A removal can lose a guarantee that nothing replaces.**
`tests/Instructions.Tests.ps1` enforced "no instruction file may cause a push by
being followed". There are no instruction files left, so deleting it is correct,
but the rule is still true and is now stated unenforced. Recorded rather than
glossed over.

## Capability

The harness can now govern a repository it did not build: decision 0010 extends
the branch-and-fast-forward policy to PSGraphRender, PSGraphRenderToHtml and
PSTerraformGraph, and this pass exercised it end to end — pass branch, green
build, annotated tags, ancestry-checked `main` move — on a repository that
previously governed itself. A repository can be moved from self-operation to
plan-by-plan operation without losing its accumulated reasoning, and the
`docs/HANDOFF.md` shape is what carries it.
