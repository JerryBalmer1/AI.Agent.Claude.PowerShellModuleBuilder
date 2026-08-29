---
pass: 0018
title: Record the target-main policy; the first push it asks for is impossible
date: 2026-08-29
artifacts:
  - plans/0018-target-main-policy/plan.md
  - decisions/0008-target-main-follows-tags.md
  - README.md
  - commands/test.md
---

# Pass 0018 — Record the target-main policy; the first push it asks for is impossible

## Asked

Record a standing policy — on PSAzureDevOpsGraph only, `main` fast-forwards to
each newly pushed `v0.<minor>.0` tag, so the landing page shows the latest
tagged deliverable — then apply it by fast-forwarding `main` from `2c74531` to
`79e02fb`. Also close pass 0017's D-6: two documents still say `-ModuleName` is
mandatory for a run directory, which 0017 made false. Light tier.

## Done

- **`decisions/0008-target-main-follows-tags.md`**, verbatim from the prompt.
- **`README.md`** and **`commands/test.md`**: the two stale `-ModuleName`
  statements corrected to describe the derivation and the ambiguity stop. 9
  insertions, 7 deletions across the two files, nothing else in either.
- **The push to target `main` was not made.** It is not a fast-forward and
  cannot be: `main` and the tagged line have unrelated histories. Verified with
  `git merge-base --is-ancestor` (exit 1), confirmed by the absence of any merge
  base, and by git's own `--dry-run` verdict `! [rejected] ... (non-fast-forward)`.
  The remote was re-read afterwards and is byte-identical to its precondition
  reading.
- Plan file and this entry.

## Why

**Decision 0008 was created even though the push it authorises could not be
made.** The policy outlives this pass, and its hard-stop clause — "a
non-fast-forward push is a hard stop and a finding, never forced" — is exactly
what governed the outcome. A rule written and then immediately exercised in the
refusing direction is better evidence that it works than one written against a
case that succeeded.

**Rejected: forcing the push.** `2c74531` holds one `README.md` and discarding it
would cost almost nothing in substance. It is still a force-push, decision 0008
forbids the agent from making one, and "the commit was cheap" is the reasoning
that turns a rail into a suggestion.

**Rejected: merging with `--allow-unrelated-histories` on the agent's own
initiative.** It would work and would make every future fast-forward possible,
but it puts a meaningless merge commit at the head of the deliverable
repository. That is a shape decision, and it is the operator's.

**Rejected: silently reporting task 2 as done because the policy document
exists.** The landing page still shows an empty initial commit. The intent is
unmet and says so.

## Measured

| Claim | Value | Artifact |
|---|---|---|
| Harness HEAD at start | `48164d1f8b000c4b2b56851cb7d4a7e968b40be6`, tree clean | plan §2 |
| Target `main`, before | `2c745310a97a551acc834e4b299a676536ea1f07` | plan §2 |
| Target `main`, after | `2c745310a97a551acc834e4b299a676536ea1f07` — unchanged | plan §4 task 2 |
| `git merge-base --is-ancestor origin/main 'v0.1.0^{}'` | exit **1** | plan §4 task 2 |
| `git merge-base origin/main 'v0.1.0^{}'` | no output, exit 1 — no common ancestor | plan §4 task 2 |
| Root commits | two: `2c745310` (GitHub "Initial commit") and `ea4c4fd4` ("Seed", by `Reset-Target`) | plan §4 task 2 |
| `git push --dry-run` | `! [rejected] v0.1.0^{} -> main (non-fast-forward)` | plan §4 task 2 |
| D-6 fix | 9 insertions, 7 deletions across 2 files | plan §4 task 3 |
| Pushes to PSAzureDevOpsGraph | **0** | plan §7 |

## Learned

**`Reset-Target.ps1` produces run branches with their own root commit, and
nothing downstream knew that.** It materialises the seed into a fresh
repository with its own `git init`, so `run-002-first-build` shares no ancestry
with the remote's `main`. The authorship makes it unambiguous: the tagged line's
root is `ea4c4fd4 Seed` by `Reset-Target <reset-target@localhost>`, while
`main`'s root is `2c745310 Initial commit` by the operator's GitHub account, a
day earlier. Every future run branch will have this property until
`Reset-Target.ps1` or the push step is changed to start from the remote's
`main`.

**This makes decision 0008 unsatisfiable as written for `v0.1.0`, and only
conditionally satisfiable later.** The rule says fast-forward `main` to each
newly pushed tag. No tag on an independently rooted run branch can ever
fast-forward `main`. The rule becomes workable from the next tag onward if the
default branch is repointed or the histories are joined now, and from the next
*run* onward if the seeding is re-rooted. The last is the only fix to the cause,
and it changes an executable, so it is a full-tier pass.

**The prompt guarded against the wrong failure.** Its precondition asks whether
`main` has *moved* — the operator getting there first — but not whether `main` is
*related*. The ancestry check appeared only in the constraints, as a pre-push
verification. It fired and it worked, but a hard stop is cheaper at
preconditions than three tasks in.

**A `--dry-run` push is the right way to ask git a question about a remote.** It
negotiates for real and reports the verdict without changing anything, which
turned an inference from `merge-base` into git's own rejection message. Re-reading
the remote afterwards is what makes "nothing changed" an observation rather than
a claim.

## Capability

None. This pass records a policy and corrects two sentences; it adds nothing the
plugin or the harness can do that it could not before. The policy it records is
not yet satisfiable — see Learned — so it does not yet confer the capability it
describes either.
