# Pass 0019 — Unify the target's history, and let main follow the work

Tier: **light** as the prompt states, and see D-1 — this pass writes only
records in this repository, but it performs the most consequential
outward-facing action of any pass so far.

## 1. Prompt

```
# PASS 0019 — Unify the target's history, and let main follow the work
Tier: light

## Repositories
- `AI.Agent.Claude.PowerShellModuleBuilder` — branch `pass-0019-history-unification`
  cut from `621d72eb26a890b1eec8eb79b29f68711742da8d`.
- `PSAzureDevOpsGraph` — receives one merge commit on `main`, tag `v0.2.0`,
  and `docs/worklog/v0.2.0.md`. Nothing else.

## Preconditions — hard stop on failure
1. Harness HEAD `621d72eb…`, tree clean (rule 13 if not). Create the branch.
2. Target remote: `main` at `2c745310…`, `run-002-first-build` at
   `79e02fba…`, tag `v0.1.0` present, no `v0.2.0`. If `main` has moved,
   stop — the operator acted first.
3. `git merge-base origin/main 'v0.1.0^{}'` in a target clone exits 1
   (confirming the two-root state this pass exists to fix).
4. pwsh, git versions recorded. No PAT needed; report set/unset only.

## Acceptance test — red first
`plans/0019-history-unification/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0019 delivered' {
        BeforeAll {
            $script:refs = git ls-remote https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
            $script:joined = ($refs | Out-String)
        }
        It 'target main moved off the orphan root' {
            $joined | Should -Not -Match '2c745310a97a551acc834e4b299a676536ea1f07\s+refs/heads/main'
        }
        It 'v0.2.0 exists on the remote' {
            $joined | Should -Match 'refs/tags/v0\.2\.0'
        }
        It 'decision 0009 exists' {
            Test-Path "$RepoRoot/decisions/0009-agent-moves-both-mains.md" | Should -BeTrue
        }
        It 'decision 0008 carries the amendment' {
            Get-Content "$RepoRoot/decisions/0008-target-main-follows-tags.md" -Raw |
                Should -Match 'allow-unrelated-histories'
        }
    }

Run it, report the red. Green at start stops the pass.

## Plan
- [ ] 1. Acceptance red; report it.
- [ ] 2. Append to `decisions/0008-target-main-follows-tags.md`, verbatim:

        ## Amendment — 2026-08-29, operator-directed

        Run branches produced by `Reset-Target.ps1` are orphan roots, so no
        fast-forward from the original `main` can exist (pass 0018's
        finding). Resolution: one merge with `--allow-unrelated-histories`,
        performed once by pass 0019, joining `v0.1.0^{}` and the original
        `main`. Both roots are preserved; nothing is forced or rewritten.
        Thereafter `main` follows tags by fast-forward as this decision
        already states, which is possible because every future deliverable
        plan branches from the unified `main` (decision 0006's deliverable
        line). `Reset-Target.ps1` is unchanged and remains the measurement
        line only: its orphan-root property is now load-bearing, marking
        measurement branches as structurally distinct from the deliverable
        line. Measurement branches are never merged to `main` and never
        tagged.

- [ ] 3. Create `decisions/0009-agent-moves-both-mains.md`, verbatim:

        # 0009 — The agent moves both mains, fast-forward only

        Operator-directed, 2026-08-29. Amends rule 14: at the end of every
        pass whose acceptance test is green, the agent fast-forwards
        `main` — on the harness to the pass tip, on PSAzureDevOpsGraph to
        the newest `v0.<minor>.0` tag — and pushes it. Fast-forward only,
        verified with `git merge-base --is-ancestor` before every push; a
        non-fast-forward is a hard stop and a finding, never forced.
        History is never rewritten. `Publish-Module` and all other
        publication remain operator-only. Rationale: both landing pages
        chronically lagged the work, and the operator is the bottleneck
        the previous rule created.

- [ ] 4. In a target clone: checkout `main`, then
      `git merge v0.1.0^{} --allow-unrelated-histories -m "Unify histories:
      merge run 002 (v0.1.0) into main — decision 0008 amendment"`.
      Resolve the only possible collision (README.md) by taking the
      module's README wholesale. Write `docs/worklog/v0.2.0.md`: what this
      plan did and why, the two-root finding it resolves, and the sentence
      "Scores carried from v0.1.0, not re-earned this plan." Commit, then
      `git tag -a v0.2.0 -m "Plan 0019 history unification — scores carried
      from v0.1.0: build exit 0, conformance 57/57, functional 12/12"`.
      Push `main` and the tag. Evidence: `git ls-remote --symref` before
      and after; `git log --oneline --graph -8 main` showing both roots.
- [ ] 5. Verify the landing-page content: `git show main:README.md | head`
      is the module README; `git ls-tree main` shows `src`, `tests`,
      `build.ps1`, `docs`. Quote both.
- [ ] 6. Acceptance green; report it. Plan file (prompt verbatim, evidence,
      Deviations), `journal/0019-history-unification.md`. Push
      `pass-0019-history-unification`. Then, per decision 0009:
      `git merge-base --is-ancestor origin/main HEAD` on the harness (must
      succeed against `d1647fa`'s line) and push harness `main` to the pass
      tip. Quote `ls-remote` for both mains as the final evidence.

## Constraints
No force pushes anywhere, ever. No changes to `Reset-Target.ps1`, `evals/`,
or `skills/`. Target receives exactly: one merge commit, one worklog file
inside it, one tag. If any push is rejected as non-fast-forward, stop and
report — do not resolve it.

## Deviations
Required. Especially anything in this prompt that was wrong.

## Report back
Four `ls-remote` lines (both mains, before/after), the graph log, the tag,
and the harness pass SHA.
```

## 2. Preconditions

All four passed.

**1. Harness HEAD and clean tree.**

```
$ git rev-parse HEAD
621d72eb26a890b1eec8eb79b29f68711742da8d
$ git status --porcelain
(empty)
$ git checkout -b pass-0019-history-unification
```

Rule 13 did not apply.

**2. Target remote — BEFORE.**

```
$ git ls-remote --symref https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
ref: refs/heads/main	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	refs/heads/main
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/heads/run-002-first-build
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}
```

`main` at `2c745310…` — unmoved, so the "operator acted first" stop does not
apply. `run-002-first-build` at `79e02fba…`. `v0.1.0` present. No `v0.2.0`.

**3. The two-root state, confirmed.**

```
$ git merge-base origin/main 'v0.1.0^{}'
(no output)
$ echo $?
1
```

**4. Tooling.** pwsh 7.6.5, git 2.41.0.windows.1, Windows 11 Home 10.0.26200.
`$env:AZDO_PAT`: **set**. Nothing in this pass used it; no network call here
touched Azure DevOps.

**Checked early, though the prompt puts it in task 6.** Pass 0018's D-4 said an
ancestry check belongs at preconditions, where a hard stop is cheap. Applied to
this pass's own last step:

```
$ git rev-parse origin/main
d1647fa3062fc36e6a1b6aa02a1f9e5608379d30
$ git merge-base --is-ancestor origin/main HEAD ; echo $?
0
$ git rev-list --count origin/main..HEAD    # main is behind by
29
$ git rev-list --count HEAD..origin/main    # main has that HEAD lacks
0
```

Harness `main` is a clean ancestor, 29 behind and 0 ahead, so task 6's
fast-forward was known to be possible before any work began.

## 3. Environment

- Branch `pass-0019-history-unification`, cut from `621d72eb`
- Target clone for the merge: `scratch/0019-target`, not committed
- No build, no suite run, no PAT use

## 4. Acceptance test — red first

```
$ pwsh -NoProfile -Command "Invoke-Pester ./plans/0019-history-unification/accept.Tests.ps1 -Output Detailed"

Describing Pass 0019 delivered
  [-] target main moved off the orphan root
   Expected regular expression '2c745310…\s+refs/heads/main' to not match …but it did match.
  [-] v0.2.0 exists on the remote
   Expected regular expression 'refs/tags/v0\.2\.0' to match '…refs/tags/v0.1.0^{}', but it did not match.
  [-] decision 0009 exists
   Expected $true, but got $false.
  [-] decision 0008 carries the amendment
   Expected regular expression 'allow-unrelated-histories' to match '# 0008 — PSAzureDevOpsGraph main follows the tagged line …', but it did not match.

Tests Passed: 0, Failed: 4, Skipped: 0, Inconclusive: 0, NotRun: 0
```

**Red 0/4.** Not green at start, so the pass proceeded.

## 5. Tasks

### - [x] 1. Acceptance red

Done, above.

### - [x] 2. Append the amendment to decision 0008

Appended verbatim, including its line breaks. `decisions/0008-target-main-follows-tags.md`
now carries the original decision followed by
`## Amendment — 2026-08-29, operator-directed`.

### - [x] 3. Create decision 0009

`decisions/0009-agent-moves-both-mains.md`, verbatim.

### - [x] 4. The merge, the worklog, the tag, the push

**The collision was exactly the one predicted, and only that one.**

```
$ git checkout main && git merge 'v0.1.0^{}' --allow-unrelated-histories \
      -m "Unify histories: merge run 002 (v0.1.0) into main — decision 0008 amendment"
Auto-merging README.md
CONFLICT (add/add): Merge conflict in README.md
Automatic merge failed; fix conflicts and then commit the result.
```

28 paths added cleanly; `README.md` alone was `AA`. `main`'s side held one line
(`# PSAzureDevOpsGraph`); the module's side is the full README. Resolved
wholesale from the module:

```
$ git show 'v0.1.0^{}:README.md' > README.md && git add README.md
IDENTICAL to v0.1.0's README - wholesale, no conflict markers
$ grep -c '^<<<<<<<\|^=======\|^>>>>>>>' README.md
0
```

`docs/worklog/v0.2.0.md` written and committed **with** the merge, so the
worklog is inside the commit it describes. It contains the required sentence
verbatim (`grep -c` → 1): *"Scores carried from v0.1.0, not re-earned this
plan."*

**The merge commit, with both parents:**

```
$ git log -1 --format='%H%n parents: %P%n %s'
5fd814b464272aa6e282ea46884546e8f8e736c9
 parents: 2c745310a97a551acc834e4b299a676536ea1f07 79e02fba9dffd976bccf507d531f59303cc58f9d
 Unify histories: merge run 002 (v0.1.0) into main — decision 0008 amendment
```

**The graph, showing both roots preserved:**

```
$ git log --oneline --graph -8 main
*   5fd814b Unify histories: merge run 002 (v0.1.0) into main — decision 0008 amendment
|\
| * 79e02fb PSAzureDevOpsGraph: pipeline dependency graph, read-only
| * ea4c4fd Seed
* 2c74531 Initial commit
```

`2c74531` and `ea4c4fd` are both still roots. Nothing was rewritten.

**The tag:**

```
$ git tag -l -n99 v0.2.0
v0.2.0          Plan 0019 history unification — scores carried from v0.1.0: build exit 0, conformance 57/57, functional 12/12
$ git rev-parse 'v0.2.0^{}'
5fd814b464272aa6e282ea46884546e8f8e736c9
```

**Fast-forward verified before pushing, per the constraint, then dry-run:**

```
$ git merge-base --is-ancestor origin/main HEAD ; echo $?
0

$ git push --dry-run origin main v0.2.0
   2c74531..5fd814b  main -> main
 * [new tag]         v0.2.0 -> v0.2.0
```

The two-dot range `2c74531..5fd814b` is git's own statement that this is a
fast-forward. Then the real push:

```
$ git push origin main v0.2.0
   2c74531..5fd814b  main -> main
 * [new tag]         v0.2.0 -> v0.2.0
```

**Target remote — AFTER:**

```
$ git ls-remote --symref https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
ref: refs/heads/main	HEAD
5fd814b464272aa6e282ea46884546e8f8e736c9	HEAD
5fd814b464272aa6e282ea46884546e8f8e736c9	refs/heads/main
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/heads/run-002-first-build
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}
89e14387c0e775ed131f276f308e97c4efa8b22f	refs/tags/v0.2.0
5fd814b464272aa6e282ea46884546e8f8e736c9	refs/tags/v0.2.0^{}
```

`v0.2.0` is annotated — it answers twice, and peels to the merge commit.
`run-002-first-build` and `v0.1.0` are untouched. The target received exactly
what the prompt allowed: one merge commit, one worklog file inside it, one tag.

### - [x] 5. Landing-page content

```
$ git show main:README.md | head
# PSAzureDevOpsGraph

Works out which Azure DevOps pipelines depend on what.

## The question it answers

Azure DevOps pipeline YAML composes by reference. A pipeline pulls in templates,
templates pull in other templates, and those references cross repository
boundaries — so the thing you most want to know is not visible from any one
file:
```

```
$ git ls-tree main
100644 blob 3f1a22fd…	.gitattributes
100644 blob d59ab5f9…	.gitignore
100644 blob a8ddfa84…	LICENSE
100644 blob 0854dc62…	PSAzureDevOpsGraph.build.ps1
100644 blob 3f9d6405…	PSScriptAnalyzerSettings.psd1
100644 blob 60e43fc8…	README.md
100644 blob d595db6a…	Requirements.psd1
100644 blob 59b88182…	build.ps1
040000 tree 15058359…	docs
040000 tree fb103bff…	src
040000 tree dbd07281…	tests
```

`src`, `tests`, `build.ps1` and `docs` are all present, and the README is the
module's rather than the one-line placeholder.

### - [x] 6. Acceptance green, records, both mains

```
$ pwsh -NoProfile -Command "Invoke-Pester ./plans/0019-history-unification/accept.Tests.ps1 -Output Detailed"

Describing Pass 0019 delivered
  [+] target main moved off the orphan root 204ms
  [+] v0.2.0 exists on the remote 5ms
  [+] decision 0009 exists 9ms
  [+] decision 0008 carries the amendment 9ms

Tests Passed: 4, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

Harness branch push, ancestry re-verification, and harness `main` — see §7.

## 6. Diff summary (light tier)

```
 decisions/0008-target-main-follows-tags.md         | 17 +++++++++++++++++
 decisions/0009-agent-moves-both-mains.md           | (new, 13 lines)
 journal/0019-history-unification.md                | (new)
 plans/0019-history-unification/accept.Tests.ps1    | (new)
 plans/0019-history-unification/plan.md             | (new)
```

| File | What changed, and why |
|---|---|
| `decisions/0008-…` | Amendment appended: the orphan-root finding, the one-off unrelated-histories merge as its resolution, and the deliverable/measurement split that makes `Reset-Target.ps1`'s orphan root deliberate rather than a defect. |
| `decisions/0009-…` | New. The agent now fast-forwards both `main`s at the end of a green pass, fast-forward only, verified before every push. |
| `journal/0019-…` | New. Six fields, written from this plan. |
| `plans/0019-…/accept.Tests.ps1` | New. Four assertions, run red before any work. |
| `plans/0019-…/plan.md` | This file. |

No executable file in this repository changed. `Reset-Target.ps1`, `evals/` and
`skills/` are untouched, as the constraints required:

```
$ git diff --name-only 621d72eb..HEAD -- evals/ skills/ evals/functional/Reset-Target.ps1
(empty)
```

## 7. Both mains — the final evidence

Ancestry re-verified immediately before the harness push, per decision 0009,
then a dry-run, then the push:

```
$ git fetch origin main && git rev-parse origin/main
d1647fa3062fc36e6a1b6aa02a1f9e5608379d30
$ git merge-base --is-ancestor origin/main HEAD ; echo $?
0
$ git push --dry-run origin HEAD:main
   d1647fa..eb4969f  HEAD -> main
$ git push origin HEAD:main
   d1647fa..eb4969f  HEAD -> main
```

**Harness remote — after:**

```
ref: refs/heads/main	HEAD
eb4969f66f27c3fc86e113e02580c273303e349b	HEAD
eb4969f66f27c3fc86e113e02580c273303e349b	refs/heads/main
```

**Target remote — after:**

```
ref: refs/heads/main	HEAD
5fd814b464272aa6e282ea46884546e8f8e736c9	HEAD
5fd814b464272aa6e282ea46884546e8f8e736c9	refs/heads/main
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/heads/run-002-first-build
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}
89e14387c0e775ed131f276f308e97c4efa8b22f	refs/tags/v0.2.0
5fd814b464272aa6e282ea46884546e8f8e736c9	refs/tags/v0.2.0^{}
```

**The four lines the prompt asked for:**

| Remote | Before | After |
|---|---|---|
| harness `main` | `d1647fa3062fc36e6a1b6aa02a1f9e5608379d30` | `eb4969f66f27c3fc86e113e02580c273303e349b` |
| target `main` | `2c745310a97a551acc834e4b299a676536ea1f07` | `5fd814b464272aa6e282ea46884546e8f8e736c9` |

Both moves were fast-forwards, both verified with `merge-base --is-ancestor` and
a `--dry-run` first, and no push anywhere in this pass used `--force`.

This section was written after those pushes, so the commit carrying it is one
ahead of `eb4969f`; `main` was fast-forwarded again to include it, by the same
verified procedure.

## 8. Deviations

**D-1. The tier is right by the letter of the rule and worth questioning.**
PLAN-PROTOCOL decides tier by whether the pass changes executable behaviour.
This one changes none, so *light* is correct, and light explicitly requires no
acceptance test — yet the prompt mandates one and I ran it. Tier is a floor, so
an extra test is harmless.

The uncomfortable part is that the taxonomy has no axis for **consequence
outside this repository**. This pass permanently altered the default branch of
the deliverable repository and created a tag, both irreversible in practice, and
it is filed at the same tier as a pass that fixes two sentences (0018). I am not
proposing a new tier here; I am recording that the two dimensions came apart
visibly for the first time, and that the acceptance test the prompt added is
doing the job the tier system did not.

**D-2. `git merge-base origin/main 'v0.1.0^{}'` needs the tags fetched, and a
default clone does not fetch them into a usable ref.** `git clone` fetches tags,
but this pass's clone used `--no-single-branch` and I still ran an explicit
`git fetch origin '+refs/tags/*:refs/tags/*'` before precondition 3 to be
certain `v0.1.0^{}` resolved. Anyone re-running precondition 3 from a
minimal or single-branch clone will get a "not a valid object name" error rather
than the exit 1 the prompt predicts — a different failure with the same exit
code, which is the kind of thing that reads as confirmation when it is not.
Worth an explicit fetch in any future prompt that names `merge-base` against a
tag.

**D-3. The ancestry check for the harness `main` was moved to preconditions.**
The prompt puts it in task 6, at the very end. Pass 0018's D-4 recorded that
this is the wrong place — a hard stop is cheaper before the work than after it —
and this pass is the first opportunity to act on that. Checked at preconditions
(`is-ancestor` exit 0, 29 behind, 0 ahead) and re-checked immediately before the
push, since the branch push between them moves nothing on `main` but the
re-check costs nothing. No behaviour changed; only the ordering.

**D-4. The prompt's `d1647fa` was correct.** Recorded because the previous two
passes each contained a SHA-level claim that turned out to be wrong, and this
one did not: harness `main` was at `d1647fa3062fc36e6a1b6aa02a1f9e5608379d30`
exactly as stated.

**D-5. Decision 0009 has a consequence the prompt does not state, and it starts
now.** "At the end of every pass whose acceptance test is green" means
**light-tier passes that write no acceptance test have no trigger**. Pass 0018
was such a pass. Read literally, a records-only pass never moves `main`, so the
harness landing page will still lag whenever a pass is light — the exact problem
the decision's rationale names. Two readings are available (treat a light pass
as trivially green, or require an acceptance test on every pass) and I did not
choose between them, because both change how future passes run. Flagging it as
the first thing to settle when it next matters.

**D-6. Nothing in this prompt was wrong.** The preconditions were accurate, the
single predicted collision was the only collision, both target SHAs and the
harness `main` SHA were correct, and both decision texts transcribed cleanly.

## 9. Cost

- Wall clock: approximately 25 minutes.
- Pushes: **1 branch + 1 main + 1 tag** to PSAzureDevOpsGraph's remote
  (`main` and `v0.2.0` in one invocation); **1 branch + 1 main** to this
  repository.
- Dry-runs: 1, before the target push.
- Clones: 1, under `scratch/`, removed.
- Pester runs: 2 (red, green). No build, no conformance run, no probe rows.

No token count: the agent cannot measure one from inside the session.
