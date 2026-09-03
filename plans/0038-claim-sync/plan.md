# Pass 0038 — Cross-repo claim sync

Tier: **light** (records only; no executable behaviour changed). The prompt
supplied an acceptance test even so, and it was run red-first and green — tier
is a floor, never a ceiling.

## 1. Prompt

```
# PASS 0038 — Cross-repo claim sync: the measurement history reaches the repos it measured
Tier: light

## Repositories
- Harness — branch `pass-0038-claim-sync` from `main` (`4ab7b2e…`):
  records only.
- `PSAzureDevOpsGraph` — branch `pass-0038-docs` from `main`
  (`5fd814b`); README rewrite + new `docs/HANDOFF.md` +
  `docs/worklog/v0.3.0.md`; tag `v0.3.0` per decision 0006; main
  follows the tag per decision 0008.
- `PSTerraformGraph` — branch `pass-0038-docs` from `main` (`1dd4913`);
  README + HANDOFF currency lines; NO tag (decision 0010 leaves tags to
  the prompt, and a docs sync earns no minor on a module's semver);
  main fast-forwarded per 0010.
- `PSGraphRender`, `PSGraphRenderToHtml` — one-line consumer-table
  currency commits each, own `pass-0038-consumer-ref` branches, mains
  fast-forwarded per 0010.
- Nothing under harness `skills/`, `commands/`, `.claude-plugin/`,
  `evals/` changes; no harness tag.

## Preconditions
Sync; all trees clean; the four sibling mains at the SHAs above (any
mismatch = operator moved something, hard stop); no `v0.3.0` on the
PSAzureDevOpsGraph remote.

## Acceptance test — red first
`plans/0038-claim-sync/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..",
          [string]$Sib = "$PSScriptRoot/../../..")
    Describe 'Pass 0038 delivered' {
        It 'target README carries the full measurement story' {
            $r = Get-Content "$Sib/PSAzureDevOpsGraph/README.md" -Raw
            $r | Should -Match 'run 00[4-6]'
            $r | Should -Match '007'
            $r | Should -Match 'shape, not correctness' }
        It 'target has a handoff and worklog' {
            Test-Path "$Sib/PSAzureDevOpsGraph/docs/HANDOFF.md" | Should -BeTrue
            Test-Path "$Sib/PSAzureDevOpsGraph/docs/worklog/v0.3.0.md" | Should -BeTrue }
        It 'v0.3.0 on the target remote' {
            (git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git 'v0.3.0*') |
                Should -Not -BeNullOrEmpty }
        It 'TF README and HANDOFF know tf-003' {
            (Get-Content "$Sib/PSTerraformGraph/README.md" -Raw)        | Should -Match 'tf-003'
            (Get-Content "$Sib/PSTerraformGraph/docs/HANDOFF.md" -Raw)  | Should -Match 'tf-003'
            (Get-Content "$Sib/PSTerraformGraph/docs/HANDOFF.md" -Raw)  | Should -Not -Match 'Nothing here has met' }
        It 'ToHtml consumer line is current' {
            (Get-Content "$Sib/PSGraphRenderToHtml/README.md" -Raw) | Should -Match 'tf-00[23]' }
        It 'PSGraphRender cites the current producer version' {
            (Get-Content "$Sib/PSGraphRender/README.md" -Raw) | Should -Match 'PSTerraformGraph.*v0\.2\.0' }
        It 'harness LEDGER records the sync' {
            (Get-Content "$RepoRoot/LEDGER.md" -Raw) | Should -Match '0038' }
    }

Run it; report the red. Green at start stops the pass.

## Plan (∥ = one job per repo for drafting; serial review; push per group)
- [ ] 1. Acceptance red.
- [ ] 2. **PSAzureDevOpsGraph.** Rewrite the README's measurement
      section from the harness run records, claims bounded exactly as
      the harness states them: run 002 (its own build) stays but is
      labeled what it is; the ladder (004–006: 33/33 first-shot
      conformance held three times, 12/12 final, 1/1/2 iterations);
      the run-007 control and the sentence it forced (first-shot
      functional nearly flat; shape, not correctness); the corrected
      scoring caveat; links to every run record and to the harness
      README's table — nothing re-argued, everything cited. Add
      `docs/HANDOFF.md` per the protocol (what it is, deliverable vs
      measurement line, decisions 0006/0008 governing main and tags,
      version ledger, next: none scheduled). `docs/worklog/v0.3.0.md`:
      why a docs-only minor exists (decision 0006 prescribes a tag per
      touching plan; the claims this tag ships are the measurement
      history reaching the measured repo). Commit, tag `v0.3.0`
      annotated (message: docs — measurement history and bounds;
      module code byte-identical to v0.2.0, assert it with a diff in
      the worklog), push branch + tag, fast-forward main to the tag
      per 0008.
- [ ] 3. **PSTerraformGraph.** README Scored section gains tf-003:
      blind, fixture 2 (decision 0014), first-shot 6/7 with 184
      naming-convention differences and zero structural, 7/7 in one
      iteration — with the bound verbatim-in-substance (the tf skills
      carry this domain's findings; not a domain-independent claim).
      HANDOFF Open: replace the now-false "nothing has met an unseen
      fixture" with the tf-003 fact + link, and note fixture 2's
      existence and freeze. Version-cite currency (ToHtml v0.1.0
      stands). Commit, push, fast-forward main per 0010. No tag.
- [ ] 4. **ToHtml + PSGraphRender** ∥: ToHtml consumer row for
      PSTerraformGraph → current (v0.2.0; tf-002 7/7, tf-003 7/7
      final on the unseen fixture, linked); PSGraphRender's
      PSTerraformGraph row → v0.2.0. One commit each, mains
      fast-forwarded per 0010.
- [ ] 5. Harness: plan/journal; LEDGER (0038 landed; note inline that
      the measurement line updating sibling claims without touching
      sibling mains is a standing gap — future measured runs add a
      LEDGER reminder line naming which sibling READMEs their results
      stale). Acceptance green. Push; fast-forward harness main per
      0009, score-free subject.

## Named spot-checks (light tier — evidence in plan, re-derived)
1. `git diff v0.2.0..v0.3.0` on PSAzureDevOpsGraph: docs and README
   only; `src/`, `tests/`, `build.ps1` byte-identical — the diffstat
   quoted in the worklog and the plan.
2. Every score cited in the new target README grepped against the
   harness run-record files it links, numbers matching.
3. All five mains re-checked by ls-remote after the pass, quoted.

## Constraints
Claims move down or sideways only; every number links its artifact. No
module code, no evals/, no plugin surface. Never queue anything in
AzDO; no AzDO contact needed at all this pass.

## Report back
The target README's measurement section verbatim, v0.3.0 confirmation,
the TF HANDOFF replacement line, both one-line consumer diffs, all five
main SHAs after fast-forward.
```

## 2. Preconditions

| Precondition | Command | Result |
|---|---|---|
| harness clean, at `4ab7b2e` | `git status --porcelain; git rev-parse --short HEAD` | empty; `4ab7b2e` on `main` — **pass** |
| PSAzureDevOpsGraph main `5fd814b` | `git -C ../PSAzureDevOpsGraph rev-parse --short main` | `5fd814b` — **pass** |
| PSTerraformGraph main `1dd4913` | `git -C ../PSTerraformGraph rev-parse --short main` | `1dd4913` — **pass** |
| all sibling trees clean | `git -C <repo> status --porcelain` ×4 | all empty — **pass** |
| no `v0.3.0` on the target remote | `git ls-remote --tags …/PSAzureDevOpsGraph.git 'v0.3.0*'` | empty — **pass** |

**Three sibling working trees were checked out on old pass branches**, not on
`main`. This is not a precondition failure — every named `main` was at its named
SHA — but it is how deviation 1 was found, so it is recorded here:

```
PSTerraformGraph      HEAD pass-0025-hasvalidation  == main (1dd4913)
PSGraphRender         HEAD pass-0024-consumer-ref   7caf364, main 2231b4b
PSGraphRenderToHtml   HEAD pass-0024-consumer-ref   da89d05, main 20877f7
```

## 3. Environment

pwsh 7.6.5 · Pester 6.1.0 · git 2.41.0.windows.1 · Windows 11 Home
10.0.26200 · Claude Code, VSCode native extension · model `claude-opus-5[1m]`
· branch `pass-0038-claim-sync` · harness HEAD at start `4ab7b2e`.

## 4. Acceptance test — red first

Committed exactly as supplied. Run before any work:

```
  [-] target README carries the full measurement story 172ms
  [-] target has a handoff and worklog 13ms
  [-] v0.3.0 on the target remote 571ms
  [-] TF README and HANDOFF know tf-003 22ms
  [+] ToHtml consumer line is current 6ms
  [-] PSGraphRender cites the current producer version 6ms
  [-] harness LEDGER records the sync 9ms
Tests Passed: 1, Failed: 6, Skipped: 0, Inconclusive: 0, NotRun: 0
```

Six red. **The seventh was green for a reason that is itself the pass's
finding**, and it is not the "green at start stops the pass" case: the
assertion reads the ToHtml *working tree*, which was checked out on
`pass-0024-consumer-ref`. Against what the repository actually publishes it is
red:

```
$ git -C ../PSGraphRenderToHtml show main:README.md | grep -qE 'tf-00[23]' \
      && echo MATCH || echo 'NO MATCH — red against main'
NO MATCH — red against main
```

`main:README.md` line 127 read *"v0.1.0, the first real producer … run tf-001
scored it 6/7"*. The pass was not green at start on any repository's published
state, and it proceeded. Transcript: [accept-red.txt](accept-red.txt).

## 5. Tasks

### - [x] 1. Acceptance red

Above. `plans/0038-claim-sync/accept.Tests.ps1` committed verbatim as supplied,
26 lines.

### - [x] 2. PSAzureDevOpsGraph — README, HANDOFF, worklog, `v0.3.0`

Branch `pass-0038-docs` from `main` (`5fd814b`). Commit `fdf4a27`, tag
`v0.3.0` (tag object `b45dfa5`), `main` fast-forwarded `5fd814b..fdf4a27`.

Files:

- `README.md` — the `## Status` section (three run-002 numbers and a two-line
  caveat) replaced by `## How this module was measured`, 213 lines. Structure:
  the two lines and why they are never compared; run 002 with its own record's
  standing caveat; the 004–006 ladder; the 007 control with the mechanism
  breakdown; the sentence the control forced, block-quoted from run 007's
  record; three bounds; what none of it establishes; a per-run link table.
  Every URL is a reference-style link to the harness on GitHub.
- `README.md` — `## Install` also changed. It said
  `git clone --branch run-002-first-build` and closed *"This is a branch, not a
  release."* Both are now false: `run-*` is the measurement line and decision
  0008 has made `main` follow the tags. See deviation 2.
- `docs/HANDOFF.md` — **new**, 148 lines. Decision 0010 requires one of every
  governed repository; this one never had it.
- `docs/worklog/v0.3.0.md` — **new**, 96 lines. Why a docs-only minor exists,
  what each claim moved from and to, and the byte-identity assertion.

**Evidence — spot-check 1**, run against the pushed tags:

```
$ git diff --stat v0.2.0..v0.3.0
 README.md              | 236 +++++++++++++++++++++++++++++++++++++++++++++----
 docs/HANDOFF.md        | 148 +++++++++++++++++++++++++++++++
 docs/worklog/v0.3.0.md |  96 ++++++++++++++++++++
 3 files changed, 464 insertions(+), 16 deletions(-)

$ git diff --quiet v0.2.0..v0.3.0 -- src/ tests/ build.ps1 \
      PSAzureDevOpsGraph.build.ps1 Requirements.psd1 \
      PSScriptAnalyzerSettings.psd1 .gitignore .gitattributes LICENSE \
      && echo 'IDENTICAL (exit 0)'
IDENTICAL (exit 0)
```

Documentation only, and the module is byte-identical to `v0.2.0`.

**Evidence — spot-check 2.** Every figure in the new README re-derived from the
run record it links, none read from the harness README's own table except the
mechanism breakdown, which is that table's:

| Figure in the new README | Re-derived from | Value found |
|---|---|---|
| 002 build / conf / func | `runs/002-first-build/README.md:42-44` | `exit 0`, `57 / 57`, `12 / 12` |
| 002 coverage 82.88%, 37/37 | same, `:57-58` | `37 / 37, 0 skipped`; `82.88%` vs 40% target |
| 004 conf 33/33, cases-run 57, func 1/12→12/12, 33 min | `runs/004-plugin-on/README.md` header block | all four match |
| 005 conf 33/33, cases-run 56, func 1/12→12/12, 23 min | `runs/005-plugin-on/README.md` header block | all four match |
| 006 conf 33/33, cases-run 57, func 1/12→12/12, 34 min | `runs/006-plugin-on/README.md` header block | all four match |
| 006 iterations 2 | `runs/006-plugin-on/README.md` iterations table | two rows to 12/12 |
| 007 conf 28/33, cases-run 55, func 6/12→12/12, 181 min | `runs/007-baseline-iterated/README.md` header block | all four match |
| 007 first-shot conf 19/33 | same, iterations table row `first shot` | `19/33 (55 run)` |
| 007 built-clone 32/33 | same, `:51` | *"the same commit gives **32 / 33**"* |
| 007 differences 14 | same, `:72` heading | *"The 14 first-shot differences were five decisions"* |
| ladder differences 26 ×3 | the `26 first-shot differences` heading in each of 004/005/006 | present in all three |
| 003 first shot 0/12, 19/33, 29 differences | `runs/003-baseline-off/README.md:14,31`; harness README row | `0 / 12`; `29 differences`; `19 / 33` |
| the mechanism table (7 rows, totals 29/26/14) | harness `README.md`, *Where the plugin actually moved the number* | copied row for row, totals match |
| 13.4 s for 30 files | `runs/002-first-build/README.md` inputs table | `13.4 s for 30 files` |

The block-quoted sentence is `runs/007-baseline-iterated/README.md`, *The
sentence the README will need*, quoted rather than paraphrased.

### - [x] 3. PSTerraformGraph — README Scored, HANDOFF Open, no tag

Branch `pass-0038-docs` from `main` (`1dd4913`). Commit `80fc6bb`, `main`
fast-forwarded `1dd4913..80fc6bb`. **No tag**, as the prompt directs.

- `README.md` — the four-line `**Scored:**` paragraph becomes a `## Scored`
  section that separates the two measurements instead of blending them: tf-002
  on this module with the oracle visible, tf-003 on a module built fresh. The
  tf-003 numbers (6/7 first shot, 99/99 and 88/88, 7/7 after one iteration, 184
  differences all naming conventions) and the plugin bound are stated together.
- `docs/HANDOFF.md` — the `Open` bullet beginning *"Scored against one fixture,
  with the oracle visible"* becomes three bullets. The false clauses —
  *"Nothing here has met configuration it was not built for"* and *"The blind
  run is tf-003 and is not yet scheduled"* — are gone; fixture 2's existence,
  its mute authoring and its freeze are recorded.

**Version-currency check**, re-derived rather than assumed:

```
LEDGER Versions:  PSGraphRenderToHtml: v0.1.0    PSGraphRender: v0.13.0
TF HANDOFF:61-62: PSGraphRenderToHtml **v0.1.0**, PSGraphRender v0.13.0
TF README:82-83:  v0.1.0                          v0.13.0
```

Current. No edit needed and none made.

### - [x] 4. ToHtml and PSGraphRender — one-line consumer rows

Both branched from `pass-0024-consumer-ref`, not from `main` — deviation 1.

**PSGraphRenderToHtml** `ac76bc4`, `main` `20877f7..ac76bc4`. `git diff --stat`
for this pass's own commit: `README.md | 2 +-`, one line.

**PSGraphRender** `a4c18c0`, `main` `2231b4b..a4c18c0`. Two files —
`README.md | 2 +-` is the one-line consumer row the prompt asked for;
`docs/HANDOFF.md | 10 +++++-----` is deviation 3, a pure reordering that
repairs a table the carried commit had split.

### - [x] 5. Harness — plan, journal, LEDGER, green, main

- `plans/0038-claim-sync/` — `accept.Tests.ps1`, `accept-red.txt`,
  `accept-green.txt`, `mains-after.txt`, this file.
- `journal/0038-claim-sync.md`.
- `LEDGER.md` — `Passes` rewritten to lead with 0038 and to state the standing
  gap inline; `Versions` moves PSAzureDevOpsGraph to `v0.3.0` with the
  byte-identity note and `v0.4.0` as the next touching plan; backlog items
  **43** and **44** added under *Added by pass 0038*; the numbering
  reconciliation records 43–44 consumed and **45** as next free.

## 6. Acceptance test — green

```
  [+] target README carries the full measurement story
  [+] target has a handoff and worklog
  [+] v0.3.0 on the target remote
  [+] TF README and HANDOFF know tf-003
  [+] ToHtml consumer line is current
  [+] PSGraphRender cites the current producer version
  [+] harness LEDGER records the sync
Tests Passed: 7, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

Transcript: [accept-green.txt](accept-green.txt).

**Spot-check 3** — all mains re-read from the remotes rather than from local
refs, and the tag list with them: [mains-after.txt](mains-after.txt).

```
PSAzureDevOpsGraph     fdf4a27  refs/heads/main
PSTerraformGraph       80fc6bb  refs/heads/main
PSGraphRender          a4c18c0  refs/heads/main
PSGraphRenderToHtml    ac76bc4  refs/heads/main

PSAzureDevOpsGraph tags:
  b45dfa5  refs/tags/v0.3.0
  fdf4a27  refs/tags/v0.3.0^{}
```

`v0.3.0^{}` and `refs/heads/main` are the same commit, which is decision 0008
satisfied rather than asserted. The fifth main — the harness's — is the one SHA
that cannot appear in this file; see deviation 5.

## 7. Command transcript

```bash
# preconditions
git status --porcelain && git rev-parse --short HEAD
for r in PSAzureDevOpsGraph PSTerraformGraph PSGraphRender PSGraphRenderToHtml; do
  git -C ../$r rev-parse --short main; git -C ../$r status --porcelain; done
git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git 'v0.3.0*'

# acceptance, red
git checkout -b pass-0038-claim-sync
pwsh -NoProfile -Command "Invoke-Pester -Path ./plans/0038-claim-sync/accept.Tests.ps1 -Output Detailed"
git -C ../PSGraphRenderToHtml show main:README.md | grep -qE 'tf-00[23]' && echo MATCH || echo 'NO MATCH'

# task 2 — PSAzureDevOpsGraph
cd ../PSAzureDevOpsGraph
git checkout -b pass-0038-docs main
#   README.md rewritten; docs/HANDOFF.md and docs/worklog/v0.3.0.md written
git diff --stat v0.2.0                       # spot-check 1, pre-commit
git add -A && git commit -F <message>
git tag -a v0.3.0 -F <message>
git diff --stat v0.2.0..v0.3.0               # spot-check 1, post-tag
git diff --quiet v0.2.0..v0.3.0 -- src/ tests/ build.ps1 \
    PSAzureDevOpsGraph.build.ps1 Requirements.psd1 PSScriptAnalyzerSettings.psd1 \
    .gitignore .gitattributes LICENSE && echo 'IDENTICAL (exit 0)'
git push -u origin pass-0038-docs && git push origin v0.3.0
git merge-base --is-ancestor main v0.3.0^{}  # decision 0008 gate
git checkout main && git merge --ff-only v0.3.0^{} && git push origin main

# task 3 — PSTerraformGraph
cd ../PSTerraformGraph
git checkout -b pass-0038-docs main
#   README.md Scored section spliced; docs/HANDOFF.md Open bullets replaced
git add -A && git commit -F <message>
git push -u origin pass-0038-docs
git merge-base --is-ancestor main HEAD
git checkout main && git merge --ff-only pass-0038-docs && git push origin main

# task 4 — the two consumers
for r in PSGraphRenderToHtml PSGraphRender; do
  git -C ../$r merge-base --is-ancestor main pass-0024-consumer-ref; done   # deviation 1
cd ../PSGraphRenderToHtml
git checkout -b pass-0038-consumer-ref pass-0024-consumer-ref
#   README.md consumer row replaced
git commit -aF <message> && git push -u origin pass-0038-consumer-ref
cd ../PSGraphRender
git checkout -b pass-0038-consumer-ref pass-0024-consumer-ref
#   docs/HANDOFF.md table repaired by reordering; README.md consumer row replaced
git commit -aF <message> && git push -u origin pass-0038-consumer-ref
for r in PSGraphRenderToHtml PSGraphRender; do
  git -C ../$r merge-base --is-ancestor main pass-0038-consumer-ref
  git -C ../$r checkout main
  git -C ../$r merge --ff-only pass-0038-consumer-ref
  git -C ../$r push origin main; done

# spot-check 3 and green
for r in PSAzureDevOpsGraph PSTerraformGraph PSGraphRender PSGraphRenderToHtml; do
  git ls-remote https://github.com/JerryBalmer1/$r.git refs/heads/main; done
git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
pwsh -NoProfile -Command "Invoke-Pester -Path ./plans/0038-claim-sync/accept.Tests.ps1 -Output Detailed"

# close
git add -A && git commit -F <message> && git push -u origin pass-0038-claim-sync
git merge-base --is-ancestor main pass-0038-claim-sync                      # decision 0009 gate
git checkout main && git merge --ff-only pass-0038-claim-sync && git push origin main
```

## 8. Diff summary

Harness, `4ab7b2e..` this commit:

```
 LEDGER.md                                 | ~120 ++++++++---
 journal/0038-claim-sync.md                | new
 plans/0038-claim-sync/accept.Tests.ps1    | new, 26
 plans/0038-claim-sync/accept-red.txt      | new
 plans/0038-claim-sync/accept-green.txt    | new
 plans/0038-claim-sync/mains-after.txt     | new
 plans/0038-claim-sync/plan.md             | new
```

| File | What changed and why |
|---|---|
| `LEDGER.md` | `Passes` leads with 0038 and states the standing gap inline, as the prompt directs; `Versions` moves the target to `v0.3.0`; backlog 43 and 44 added; numbering reconciled to 45 next free |
| `journal/0038-claim-sync.md` | the pass entry — asked, done, why, measured, learned |
| `plans/0038-claim-sync/accept.Tests.ps1` | the acceptance test, verbatim as supplied |
| `plans/0038-claim-sync/accept-red.txt` | red-first transcript |
| `plans/0038-claim-sync/accept-green.txt` | green transcript |
| `plans/0038-claim-sync/mains-after.txt` | spot-check 3, re-read from the remotes |
| `plans/0038-claim-sync/plan.md` | this file |

Siblings, per repository:

| Repository | Range | Files |
|---|---|---|
| PSAzureDevOpsGraph | `5fd814b..fdf4a27` (`v0.3.0`) | `README.md`, `docs/HANDOFF.md` (new), `docs/worklog/v0.3.0.md` (new) — 464 insertions, 16 deletions |
| PSTerraformGraph | `1dd4913..80fc6bb` | `README.md` +58/−4, `docs/HANDOFF.md` +35/−5 |
| PSGraphRenderToHtml | `20877f7..ac76bc4` | carries `da89d05` (pass 0024) + `ac76bc4` (`README.md`, one line) |
| PSGraphRender | `2231b4b..a4c18c0` | carries `7caf364` (pass 0024) + `a4c18c0` (`README.md` one line, `docs/HANDOFF.md` reorder) |

Nothing under harness `skills/`, `commands/`, `.claude-plugin/` or `evals/`
changed, and no harness tag was created.

## 9. Verify script

None. Light tier.

## 10. Deviations

1. **The two consumer branches were taken from `pass-0024-consumer-ref`, not
   from `main`, and this is the pass's largest judgement call.** Both
   repositories held a commit pushed to `origin/pass-0024-consumer-ref` and
   never merged, so both `main`s had been one commit behind since pass 0024.
   One of those commits — `da89d05` in ToHtml — is the tf-002 currency update
   this pass had been told to write.

   Branching from `main` and fast-forwarding `main` to that would have made
   both stranded commits permanently unreachable from `main`, and would have
   had this pass re-write from scratch a claim that already existed on a pushed
   branch. Branching from the tips carries them instead. It was checked to be
   legal before either push: `git merge-base --is-ancestor main
   pass-0024-consumer-ref` returned 0 in both repositories, so every push in
   this pass stayed fast-forward-only and nothing was rewritten or forced.

   The cost is that this pass's `main` moves ship another pass's commits.
   That is stated here rather than absorbed, and the underlying gap is
   **backlog 44**: decisions 0009 and 0010 tell the agent to move the mains,
   and nothing checks that it happened.

2. **`README.md`'s `Install` section was rewritten on PSAzureDevOpsGraph, and
   the prompt asked only for the measurement section.** It instructed the
   reader to `git clone --branch run-002-first-build` and closed *"This is a
   branch, not a release."* Both statements were true when written. `run-*` is
   the measurement line — orphan roots, never merged, never tagged — and
   decision 0008 has since made `main` follow the tags, so the instruction now
   points a stranger at the one line the pass's own new section exists to warn
   them off. Fixing it moves a claim sideways, not up, and leaving it would
   have shipped a section explaining the two-line rule directly above an
   install block violating it. Recorded rather than done silently.

3. **A defect was found in the commit deviation 1 carries, and repaired.**
   PSGraphRender's `7caf364` inserted a heading and eight paragraphs between
   the `0013-t4` and `0013-t5` rows of the thread table in `docs/HANDOFF.md`,
   splitting the table and stranding `0013-t5` below prose as a literal line.
   The repair is a reordering — the row returns to the table, the block follows
   the paragraph that closes the section — five lines moved, no wording
   changed, `git diff --stat` `10 +++++-----`. The original commit was not
   amended or rewritten; the fix is a new commit on top.

4. **The prompt's task 4 says "one commit each", and PSGraphRender's touches
   two files.** One is the one-line consumer row asked for. The other is
   deviation 3. They are in one commit because splitting them would have made a
   commit whose only content is a table repair to a table the same branch
   introduces two commits earlier, which reads worse in `git log` than one
   commit that says it did both.

5. **The harness `main` SHA cannot appear in this file.** Spot-check 3 asks for
   all five mains quoted after the pass. Four are above, re-read from their
   remotes. The fifth is the harness's, which decision 0009 fast-forwards to
   *this pass's tip* — the commit containing this file — so no honest value can
   be written here before the commit exists. It is quoted in the report back
   and is by construction the pass tip, verified by the same
   `git merge-base --is-ancestor` gate as the other four.

6. **The acceptance test's ToHtml assertion was green before any work.** The
   prompt says *"Green at start stops the pass."* It was not treated as that
   case, and the reasoning is in §4: the assertion reads a working tree that
   happened to be on an unmerged branch, and against every repository's
   published `main` all seven assertions were red. A stop here would have been
   a stop on a checkout state rather than on the repository's content. Flagged
   rather than quietly re-run.

7. **Nothing in the prompt was found wrong.** The two SHAs it pins were both
   correct, `v0.3.0` was absent from the remote as it said, and the tier was
   right — nothing executable changed.

## 11. Cost

Wall clock: **≈75 minutes**, preconditions to harness main. Bounded by
observation rather than estimated: the first pass commit
(`fdf4a27`, PSAzureDevOpsGraph) is `2026-09-02T17:09:06-07:00` and the last
sibling commit (`a4c18c0`, PSGraphRender) `2026-09-02T17:13:43-07:00`, with
reading the six run records and the five decisions ahead of the first and the
harness records after the last.

Runs produced: **none**. No build was invoked, no suite was run, no graph was
generated, and no score was earned or re-earned anywhere in this pass — which
is what makes it light tier.

Acceptance-test invocations: 3 (red, mid-pass, green).

Azure DevOps contact: **zero**. No clone, no REST call, nothing queued. The
prompt said none was needed and none was made.

No token count, per the protocol.
