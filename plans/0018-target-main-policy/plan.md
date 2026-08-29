# Pass 0018 — Target main follows the tagged line

Tier: **light** (records only; no executable behaviour changed).

**Outcome: task 2 hard-stopped and is a finding.** `main` and `v0.1.0` on
PSAzureDevOpsGraph have **unrelated histories**, so the push the prompt
describes as a fast-forward is not one and cannot be one. Decision 0008 — the
document this same pass created — says a non-fast-forward push here is a hard
stop and a finding, never forced. It was not forced. The remote is byte-identical
to its precondition reading. Tasks 1, 3 and 4 are complete.

## 1. Prompt

```
# PASS 0018 — Target main follows the tagged line
Tier: light

## Repositories
- `AI.Agent.Claude.PowerShellModuleBuilder` — branch `pass-0018-target-main-policy`,
  cut from the 0017 tip (assert clean tree; record HEAD).
- `PSAzureDevOpsGraph` — push to `main` this pass, per the decision below.

## Preconditions
1. Harness tree clean on the 0017 tip; record the SHA.
2. `git ls-remote` on PSAzureDevOpsGraph: `main` at `2c745310…`,
   `run-002-first-build` at `79e02fba…`, tag `v0.1.0` present. If `main` has
   already moved past `2c74531`, stop and report — the operator did it first.

## Plan
- [ ] 1. Create `decisions/0008-target-main-follows-tags.md`, exactly:

        # 0008 — PSAzureDevOpsGraph main follows the tagged line

        Operator-directed, 2026-08-29. Amends rule 14 for one repository:
        on PSAzureDevOpsGraph only, the agent fast-forwards `main` to each
        newly pushed `v0.<minor>.0` tag at the end of every plan that tags,
        so the repository landing page always shows the latest tagged
        deliverable. Fast-forward only — a non-fast-forward push is a hard
        stop and a finding, never forced. Rule 14 is unchanged everywhere
        else: harness `main` remains operator-only, no `Publish-Module`,
        no other tags.

- [ ] 2. `git push origin v0.1.0^{}:main` on PSAzureDevOpsGraph (fast-forward
      of `2c74531` → `79e02fb`). Evidence: `git ls-remote --symref` output
      showing `main` at `79e02fba…`.
- [ ] 3. Fix 0017's D-6, exactly two lines: root README and `commands/test.md`
      both still say `-ModuleName` is required for a run directory; it now
      defaults. Nothing else in either file.
- [ ] 4. Plan file (prompt verbatim, evidence, Deviations),
      `journal/0018-target-main-policy.md`. Push the pass branch.

## Constraints
No tags this pass. No harness `main`. Fast-forward only, verified before push
with `git merge-base --is-ancestor`.

## Report back
Both `ls-remote` outputs (before/after) for target `main`; the two-line diff.
```

## 2. Preconditions

Both passed.

**1. Harness tree clean on the 0017 tip.**

```
$ git rev-parse HEAD
48164d1f8b000c4b2b56851cb7d4a7e968b40be6
$ git rev-parse --abbrev-ref HEAD
pass-0017-skill-roster
$ git status --porcelain
(empty)
$ git checkout -b pass-0018-target-main-policy
```

Recorded HEAD: `48164d1f8b000c4b2b56851cb7d4a7e968b40be6`.

**2. The target remote — BEFORE.**

```
$ git ls-remote --symref https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
ref: refs/heads/main	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	refs/heads/main
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/heads/run-002-first-build
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}
```

`main` at `2c745310…` — it has **not** moved past `2c74531`, so the "operator
did it first" stop does not apply. `run-002-first-build` at `79e02fba…`.
`v0.1.0` present and annotated. All three as the prompt required.

## 3. Environment

- Branch: `pass-0018-target-main-policy`, cut from `48164d1`
- git 2.41.0.windows.1, pwsh 7.6.5, Windows 11 Home 10.0.26200
- Target clone for inspection: `scratch/0018-target`, not committed

## 4. Tasks

### - [x] 1. Create `decisions/0008-target-main-follows-tags.md`

Created with the prompt's content, verbatim.

### - [ ] 2. Fast-forward target `main` to the tag — **HARD STOP, NOT DONE**

**The constraint required verification before the push, and the verification
failed.**

```
$ git merge-base --is-ancestor origin/main 'v0.1.0^{}'
$ echo $?
1
```

Exit 1: `main` is **not** an ancestor of the tagged commit. So the push is not a
fast-forward, and per decision 0008 — created in task 1 of this same pass — that
is "a hard stop and a finding, never forced."

**Why it is not a fast-forward: the two histories are unrelated.** They do not
share a merge base at all.

```
$ git merge-base origin/main 'v0.1.0^{}'
(no output)
$ echo $?
1

$ git log --oneline origin/main
2c74531 Initial commit

$ git log --oneline 'v0.1.0^{}'
79e02fb PSAzureDevOpsGraph: pipeline dependency graph, read-only
ea4c4fd Seed

$ git rev-list --max-parents=0 origin/main      # root of main
2c745310a97a551acc834e4b299a676536ea1f07
$ git rev-list --max-parents=0 'v0.1.0^{}'      # root of the tagged line
ea4c4fd413b0c72acaf691cf2c44ad0ec87c74b3
```

**Two separate root commits.** Their authorship says exactly how this happened:

| Root | Author | Contains |
|---|---|---|
| `2c745310` "Initial commit" | `Jerry Balmer <124226382+JerryBalmer1@users.noreply.github.com>`, 2026-08-28 | `README.md` only |
| `ea4c4fd4` "Seed" | `Reset-Target <reset-target@localhost>`, 2026-08-29 | the four-file seed |

`main` is GitHub's repository-creation commit. The tagged line begins at the
`Seed` commit that `Reset-Target.ps1` makes with its own `git init`, which is
why it shares no ancestry with anything that existed on the remote beforehand.
Run 002's branch was pushed as an independent root.

**Git's own verdict**, from a `--dry-run` that changed nothing:

```
$ git push --dry-run origin 'v0.1.0^{}:main'
To https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
 ! [rejected]        v0.1.0^{} -> main (non-fast-forward)
error: failed to push some refs to '...'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart. Integrate the remote changes (e.g.
hint: 'git pull ...') before pushing again.
```

**The target remote — AFTER. Byte-identical to the BEFORE reading.**

```
$ git ls-remote --symref https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
ref: refs/heads/main	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	refs/heads/main
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/heads/run-002-first-build
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}
```

Nothing was pushed. Nothing was forced. See Deviations D-1 for the options this
leaves the operator, none of which the agent may take on its own.

### - [x] 3. Fix 0017's D-6

Two statements, one per file, and nothing else in either.

```
$ git diff --stat README.md commands/test.md
 README.md        | 7 ++++---
 commands/test.md | 9 +++++----
 2 files changed, 9 insertions(+), 7 deletions(-)
```

```diff
--- a/README.md
+++ b/README.md
@@ -132,9 +132,10 @@
-`-ModuleName` is not optional when the repository root is a run directory —
-discovery prefers a manifest named for the target directory and refuses to guess
-rather than grade the wrong module silently.
+`-ModuleName` is optional. When the repository root is a run directory the
+runner derives it from `src/<Name>/<Name>.psd1`; two manifests under `src/` is
+undecidable and stops, naming both, rather than grading the wrong module
+silently.

--- a/commands/test.md
+++ b/commands/test.md
@@ -30,10 +30,11 @@
-   Pass `-ModuleName` whenever the repository root is not named for the module.
-   Discovery prefers a manifest named for the target directory, then one sitting
-   directly in the target; a run directory called something like
-   `002-first-build` matches neither and the suite reports no manifest at all.
+   `-ModuleName` is optional. Discovery prefers a manifest named for the target
+   directory, then one sitting directly in the target; a run directory called
+   something like `002-first-build` matches neither, and the runner then derives
+   the name from `src/<Name>/<Name>.psd1` and says which manifest it read. Pass
+   it to override, or to answer an ambiguity the runner refuses to guess at.
```

Both statements now describe what pass 0017 actually shipped, including the
ambiguity stop. The `-ModuleName $2` in `commands/test.md`'s command block was
left alone: passing it is still valid as an override, and the prompt said
nothing else in the file.

### - [x] 4. Plan, journal, push

This file, `journal/0018-target-main-policy.md`, and the pass branch.

## 5. Diff summary (light tier)

```
 decisions/0008-target-main-follows-tags.md | 10 ++++++++++
 README.md                                  |  7 ++++---
 commands/test.md                           |  9 +++++----
 journal/0018-target-main-policy.md         | (new)
 plans/0018-target-main-policy/plan.md      | (new)
```

| File | What changed, and why |
|---|---|
| `decisions/0008-target-main-follows-tags.md` | New. The operator's policy, verbatim: target `main` follows the tagged line, fast-forward only, non-fast-forward is a hard stop. |
| `README.md` | One statement corrected. `-ModuleName` was documented as mandatory for a run directory; pass 0017 made it derive. Closes 0017's D-6. |
| `commands/test.md` | The same statement, corrected the same way, and extended to name the ambiguity stop. Closes the other half of D-6. |
| `journal/0018-target-main-policy.md` | New. Six fields, written from this plan. |
| `plans/0018-target-main-policy/plan.md` | This file. |

No executable file was touched, which is what makes this pass light. Task 2
would not have changed that — it changes a remote ref, not this repository.

## 6. Deviations

**D-1. Task 2 is impossible as specified, and this is the pass's finding.**

The prompt calls the push a "fast-forward of `2c74531` → `79e02fb`". It is not
one. `main` and the tagged line have **no common ancestor** — two separate root
commits, `2c745310` (GitHub's "Initial commit", `README.md` only) and `ea4c4fd4`
("Seed", written by `Reset-Target.ps1`'s own `git init`). `Reset-Target.ps1`
materialises the seed into a fresh repository, so every run branch it produces is
an independent root. Run 002 was pushed to the remote as exactly that.

I verified with `git merge-base --is-ancestor` as the constraint required (exit
1), confirmed the absence of any merge base, inspected both root commits, and
took git's own verdict from a `--dry-run`: `! [rejected] ... (non-fast-forward)`.
The remote was re-read afterwards and is unchanged.

**I did not force the push**, and decision 0008 — the document this pass was
asked to create — is explicit that I must not. The intent behind task 2 is sound
and unmet: the landing page still shows an empty initial commit rather than the
tagged deliverable. Four ways to meet it, all the operator's call:

1. **Change the repository's default branch** to `run-002-first-build`, or to a
   branch at the tag, in GitHub's settings. Destroys nothing, needs no force,
   and makes the landing page show the deliverable immediately. This is the
   option I would take.
2. **Force-push the tag onto `main`** (`git push --force origin v0.1.0^{}:main`).
   Discards `2c74531`, which holds one `README.md` and nothing else. Cheap in
   substance, but it is a force-push and decision 0008 forbids the agent from
   doing it.
3. **Merge with `--allow-unrelated-histories`**, giving `main` a merge commit
   over both roots. Preserves the initial commit and makes every future
   fast-forward work, at the cost of a merge commit that means nothing.
4. **Re-root future runs on `main`** so this stops recurring: have
   `Reset-Target.ps1` (or the push step) start the run branch from the remote's
   `main` rather than from a fresh `git init`. This is the only option that
   fixes the *cause* rather than this instance. It changes `Reset-Target.ps1`,
   which is executable, so it is a full-tier pass and not this one.

Whichever is chosen, **decision 0008's rule only becomes satisfiable from the
next tag onward** if option 1 or 3 is taken now, and only from the next *run*
onward if option 4 is taken. As written, the decision cannot be honoured for
`v0.1.0`.

**D-2. Decision 0008 was still created, and I think that is right.** It records
a standing policy that outlives this pass, and its hard-stop clause is precisely
what governed the outcome. A decision document that is written and then
immediately exercised — correctly, in the refusing direction — is better
evidence that the rule works than one written against a case that succeeded.

**D-3. "Exactly two lines" was two statements, not two physical lines.** Each
stale claim was a wrapped paragraph — three lines in `README.md`, four in
`commands/test.md`. I replaced each paragraph with a corrected one and touched
nothing else in either file. The diff is 9 insertions and 7 deletions across the
two, which is the smallest honest expression of "correct these two statements".

**D-4. The precondition that would have caught this does not exist.** The prompt
guards against `main` having *moved* (the operator getting there first) but not
against `main` being *unrelated*. The ancestry check appears only in the
constraints, as a pre-push verification. It fired, and it worked — this is a
note that it belonged one section earlier, where a hard stop is cheaper.

**D-5. Nothing else in the prompt was wrong.** The preconditions were accurate,
both target SHAs were correct, and the decision text transcribed cleanly.

## 7. Cost

- Wall clock: approximately 20 minutes.
- Pushes: **1 branch** to this repository. **Zero** to PSAzureDevOpsGraph — one
  `--dry-run`, which changed nothing.
- Clones: 1, under `scratch/`, removed.
- No suite runs, no builds, no probe rows. Light tier: no acceptance test and no
  verify script, per PLAN-PROTOCOL.

No token count: the agent cannot measure one from inside the session.
