---
pass: 0019
title: Join the target's two roots; let the agent move both mains
date: 2026-08-29
artifacts:
  - plans/0019-history-unification/plan.md
  - plans/0019-history-unification/accept.Tests.ps1
  - decisions/0008-target-main-follows-tags.md
  - decisions/0009-agent-moves-both-mains.md
---

# Pass 0019 — Join the target's two roots; let the agent move both mains

## Asked

Resolve pass 0018's finding. `main` and the tagged line on PSAzureDevOpsGraph
had unrelated histories, so no fast-forward could ever exist and 0018 stopped
rather than force one. The operator chose the merge: join the two roots once with
`--allow-unrelated-histories`, tag the result `v0.2.0`, write a worklog inside
the merge commit, and record both the amendment that authorises it and a new
decision letting the agent move both `main`s at the end of a green pass. Also
fix nothing else — no changes to `Reset-Target.ps1`, `evals/`, or `skills/`.

## Done

- **`decisions/0008-target-main-follows-tags.md`**: amendment appended verbatim
  — the orphan-root finding, the one-off merge as its resolution, and the
  deliverable/measurement split.
- **`decisions/0009-agent-moves-both-mains.md`**: new, verbatim.
- **PSAzureDevOpsGraph `main` moved `2c74531` → `5fd814b`**, a merge commit with
  both roots as parents. Fast-forward, verified with `merge-base --is-ancestor`
  and confirmed by a `--dry-run` before the real push.
- **`docs/worklog/v0.2.0.md`** written inside that merge commit.
- **Annotated tag `v0.2.0`** at `5fd814b`, message carrying the carried-forward
  scores.
- **Harness `main` fast-forwarded** `d1647fa` → the 0019 pass tip, per decision
  0009.
- Acceptance test, plan file, this entry.

## Why

**The merge was the operator's choice among the four options pass 0018
reported**, and it is the one that preserves everything. Both roots survive as
roots; nothing was forced and no history was rewritten. The alternative that
would have been simplest — force-pushing the tag over `main`, discarding a
commit holding one line of README — was available and is exactly what decision
0008 forbids the agent from doing.

**Rejected: resolving the README collision by merging the two texts.** `main`'s
side was the single line `# PSAzureDevOpsGraph`, which the module's README
already opens with. Taking the module's file wholesale loses nothing and leaves
no conflict markers; hand-merging would have invented a third version of a file
neither side disagreed about.

**Rejected: changing `Reset-Target.ps1` to stop producing orphan roots.** It was
the obvious fix to the cause and the constraints forbade it, correctly. The
amendment reframes that orphan root as load-bearing instead: it is what marks a
measurement branch as structurally distinct from the deliverable line. A
property that was a defect in one reading is a guarantee in the other, and the
decision now says which reading is intended.

**Rejected: checking the harness ancestry where the prompt put it.** Task 6 puts
it at the very end. Pass 0018's own D-4 concluded that belongs at preconditions,
and this was the first chance to act on it. Checked before any work, re-checked
before the push.

## Measured

| Claim | Value | Artifact |
|---|---|---|
| Harness HEAD at start | `621d72eb26a890b1eec8eb79b29f68711742da8d`, tree clean | plan §2 |
| Acceptance, before any work | 0 passed / 4 failed | plan §4 |
| Acceptance, after | 4 passed / 0 failed | plan §5 task 6 |
| `git merge-base origin/main 'v0.1.0^{}'` at preconditions | no output, exit 1 — two roots | plan §2 |
| Target `main`, before | `2c745310a97a551acc834e4b299a676536ea1f07` | plan §2 |
| Target `main`, after | `5fd814b464272aa6e282ea46884546e8f8e736c9` | plan §5 task 4 |
| Merge commit parents | `2c745310` and `79e02fba` — both roots preserved | plan §5 task 4 |
| Merge collisions | **1**, `README.md` (add/add); 28 paths added clean | plan §5 task 4 |
| Conflict markers left in `README.md` | 0 | plan §5 task 4 |
| `v0.2.0` on the remote | annotated, peels to `5fd814b` | plan §5 task 4 |
| Harness `main`, before | `d1647fa3062fc36e6a1b6aa02a1f9e5608379d30`, 29 behind, 0 ahead | plan §2 |
| Harness `main`, after | the 0019 pass tip | plan §7 |
| `evals/`, `skills/`, `Reset-Target.ps1` changed | **0 files** | plan §6 |
| Force pushes | **0** | plan §9 |

## Learned

**An orphan root is not automatically a defect — it depends on which line the
branch belongs to.** Pass 0018 read `Reset-Target.ps1`'s independent `git init`
as the cause of a problem and proposed re-rooting it. The amendment makes the
opposite call: measurement branches *should* be structurally incapable of
reaching `main`, because that is what stops a scratch reliability run from ever
being mistaken for a deliverable. The same observable fact was a bug in one
framing and a guarantee in the other, and only the decision record settles which.
Worth remembering the next time a pass proposes fixing a cause: check whether
the cause is load-bearing somewhere else first.

**`merge-base` against a tag can fail for two different reasons with the same
exit code.** Exit 1 means "no common ancestor" — and also "that ref does not
resolve". A clone without the tags fetched produces the second while looking
exactly like the first, which is the shape of confirmation this project keeps
finding: a check that appears to pass because it could not run. I fetched tags
explicitly before the precondition rather than relying on clone defaults.

**Decision 0009 has a gap that starts immediately.** It triggers "at the end of
every pass whose acceptance test is green", and light-tier passes are defined by
PLAN-PROTOCOL as having no acceptance test. Pass 0018 was exactly that. Read
literally, the rule never fires for a records-only pass, so the harness landing
page still lags whenever a pass is light — the precise problem the decision's own
rationale names. Two readings exist and both change how future passes run;
neither was chosen here.

**The tier system has no axis for consequence outside the repository.** This pass
is *light* by the rule — it changed no executable — and it permanently altered
the deliverable repository's default branch and created a tag. Pass 0018, which
fixed two sentences, carries the same label. The acceptance test the prompt
required is doing the work the tier did not, which is the first visible case of
those two dimensions coming apart.

**Three consecutive passes each contained a SHA-level claim; the first two were
wrong and this one was right.** 0017's acceptance regex could not match a correct
tag, 0018's "fast-forward of `2c74531` → `79e02fb`" was not a fast-forward, and
0019's `d1647fa` was exactly correct. Recording the hit alongside the misses,
because a record that only notes prompts being wrong misrepresents the rate.

## Capability

The deliverable repository now has **one history**, so `main` is an ancestor of
anything branched from it and the rule that `main` follows tags by fast-forward
is satisfiable for the first time. No further unrelated-history merge should ever
be needed there.

Both landing pages now show the current work rather than lagging it: the target's
shows the module's README, `src`, `tests`, `build.ps1` and `docs` instead of an
empty initial commit, and the harness `main` is at the latest pass tip instead of
29 commits behind.

The agent can now **move both `main`s at the end of a green pass** without the
operator, bounded by fast-forward-only and a verification before every push —
subject to the trigger gap recorded in Learned.
