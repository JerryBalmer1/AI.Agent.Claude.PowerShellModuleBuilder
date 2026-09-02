# Plan 0033 — the honest headline (STOPPED at file supply)

Tier: **full**, per the prompt header.

**Status: STOPPED before task 1.** The prompt arrived truncated in the middle of
the acceptance test it requires to be committed *exactly*. Under
`PLAN-PROTOCOL.md` §"File supply" that is a defect in the prompt and a stop, not
a reconstruction task. Nothing in `README.md`, `evals/HARNESS.md`, `runs/`,
`CHANGELOG.md` or `.claude-plugin/` was changed by this session. Preconditions
were all checked and all hold; they are recorded below so the resumed pass does
not have to re-derive them.

## 1. Prompt

As received, verbatim. The truncation is the prompt's, not this document's — the
final line is where the message ends, mid-`It`-block, with the `foreach` body
unterminated, the `Describe` unclosed, and every section after the acceptance
test absent.

```text
# PASS 0033 — The honest headline: README rewrite, scoring repair, contamination disclosures, v1.0.1
Tier: full

## Repositories
Harness only — branch `pass-0033-honest-headline` from `main`
(`5f8b514…`). No target repo is touched; no measured run occurs, so no
session gate — but this session must still not run any future blind
phase (it will read everything).

## Preconditions
Sync; trees clean; branch created; no tag `v1.0.1` on the remote;
`git diff v1.0.0..main -- skills/ commands/ .claude-plugin/` empty
(installed surface unchanged since release — this pass keeps it that
way; v1.0.1 is a docs/method patch under decision 0013).

## Acceptance test — red first
`plans/0033-honest-headline/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0033 delivered' {
        It 'README carries the controlled claim' {
            $r = Get-Content "$RepoRoot/README.md" -Raw
            $r | Should -Match 'buys shape, not correctness'
            $r | Should -Match '19\s*/\s*33'
            $r | Should -Match 'single control' }
        It 'README no longer overstates functional' {
            (Get-Content "$RepoRoot/README.md" -Raw) |
                Should -Match 'control.+first shot.+closest' }
        It 'rescore evidence exists with both protocols' {
            $t = Get-Content "$RepoRoot/plans/0033-honest-headline/rescore.txt" -Raw
            $t | Should -Match 'run 007 final \(corrected\):\s*\d+\s*/\s*33'
            $t | Should -Match 'run 006 final \(corrected\):\s*\d+\s*/\s*33'
            $t | Should -Match 'LADDER MECHANISM: (explained|unexplained)' }
        It 'HARNESS gains the two hazards' {
            $h = Get-Content "$RepoRoot/evals/HARNESS.md" -Raw
            $h | Should -Match 'prompt-borne oracle content'
            $h | Should -Match 'case-annotated comments' }
        It 'affected run records carry the caveat' {
            foreach ($n in '003-baseline-off','004-plugin-on','005-plugin-on',
                           '006-plugin-on','007-baseline-iterated') {
                (Get-Content "$RepoRoot/runs/$n/README.md" -Raw) |
                    Should -Match '(?m)^## Blindness caveats' }
```

## 2. Preconditions

All hold. Checked before the stop was declared, because a stop is worth more
when the reader knows nothing else was also wrong.

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | Sync | `git fetch --all --tags --prune` | up to date; `origin/main` = `main` = `5f8b514464bd70fe271dc032aa67e9244fd280d5` — the SHA the prompt names |
| 2 | Trees clean | `git status --porcelain` in the harness and all five sibling repos | all six empty |
| 3 | Branch created | `git checkout -b pass-0033-honest-headline main` | on `pass-0033-honest-headline` |
| 4 | No `v1.0.1` on the remote | `git ls-remote --tags origin` | only `v1.0.0` → `361bc0c…` (annotated), `^{}` → `a5aa4a9…` |
| 5 | Installed surface unchanged | `git diff --name-only v1.0.0..main -- skills/ commands/ .claude-plugin/` | **empty** |

Two facts the resumed pass will want and which cost nothing to record now:

- **Hazard 10 (poisoned memory) is clean.** The project memory directory is
  empty and carries no `MEMORY.md`; no harness `CLAUDE.md`; no harness
  `.claude/`. This session reads everything and is not a blind builder, but the
  hazard's entry says to re-verify it and it is cheap.
- **Every input the pass needs is present.** `run-006-plugin-on`
  (`70669167ea5f59a47efb282002052f9e926a34bf`) and `run-007-baseline-iterated`
  (`95ca28d76c8eeb6dc33b09f77109dc96038c76aa`) both exist on the
  `PSAzureDevOpsGraph` remote, so the corrected re-score of both is executable;
  `runs/007-baseline-iterated/conformance-result-built-clone.json` already holds
  007's built-clone figure. The stop is *only* about the missing prompt text.

## 3. Environment

- pwsh 7.6.5; Pester 6.1.0; git 2.41.0.windows.1
- Windows 11 Home 10.0.26200
- Claude Code, VSCode native extension; model `claude-opus-5[1m]`
- Branch `pass-0033-honest-headline` from `main`; HEAD at start `5f8b514`

## 4. Acceptance test — red first

**Not run. The test does not exist, because its content was not fully supplied.**
Writing it would mean inventing the part that was cut off, and the invented part
would then be the contract the rest of the pass is graded against.

## 5. Tasks

None started. The protocol section of the prompt — the `- [ ]` list, the named
spot-checks `verify.ps1` must re-derive, the constraints, and the report-back —
is entirely inside the truncated region and was never received.

## 10. Deviations

1. **The prompt is truncated mid-acceptance-test, and this pass stops on it.**
   The message ends inside the fifth `It` block: the `foreach` body has no
   closing brace, the `It` has no closing brace, the `Describe` is unclosed, and
   everything after the acceptance test is missing. The prompt says the test is
   to be committed **"exactly"**, and `PLAN-PROTOCOL.md` §"File supply" is
   explicit that a file whose full content does not appear in the prompt "is a
   defect in the prompt, not a lookup task, and the pass stops on it rather than
   searching or inventing." It also records that this rule has already cost a
   pass twice, "once silently, when a missing draft blocked a task and the pass
   carried on without saying so", and names the loud failure as the correct
   behaviour. This is the loud failure.

   What is missing is not cosmetic. The header promises four deliverables and
   the surviving text only underwrites three of them: **v1.0.1 has no assertion
   at all** in the received fragment — no `CHANGELOG.md` entry, no
   `.claude-plugin/plugin.json` version bump, no `marketplace.json`, no tag
   instruction, and no statement of whether the tag is this pass's to create.
   Pass 0030 established that publishing is the operator's and stopped at the
   tag; guessing which side of that line v1.0.1 falls on is precisely the kind
   of invention the rule forbids.

2. **The surviving fragment is nonetheless internally consistent with the
   repository**, which is worth recording because it means the resend is likely
   a delivery problem rather than a drafting one. Every assertion in the
   received text is currently red, and for a real reason:

   | Assertion | Current state |
   |---|---|
   | `buys shape, not correctness` in README | absent — the phrase exists only in `runs/007-baseline-iterated/README.md`, in the sentence 0032 drafted and deliberately did not apply |
   | `control.+first shot.+closest` in README | absent — README §"With the plugin and without it" predates run 007 and has no control column |
   | `19/33`, `single control` in README | `19 / 33` is present in the with/without table; `single control` is absent |
   | `plans/0033-honest-headline/rescore.txt` | absent |
   | two new hazards in `evals/HARNESS.md` | absent — the file stops at hazard 11 |
   | `## Blindness caveats` in runs 003–007 | absent from all five; 003 has `## Baseline caveat`, 004–006 `## Plugin-on caveat`, 007 none |

   So the pass is real work against a real gap, and it maps cleanly onto LEDGER
   items 23, 24 and 25 and onto plan 0032's Deviations 3, 5 and 7. The stop is
   about the channel, not the substance.

3. **`git diff v1.0.0..main` over the three pinned paths is empty, and the
   prompt's parenthetical is right this time.** Recorded because the two
   preceding prompts both carried a stale four-path form of this pin — the
   LEDGER's closing note says so of pass 0031, and plan 0032 Deviation 6 says
   the prompt's "one prose commit past the tag" was already two. This prompt's
   three-path form matches what the LEDGER prescribes.

4. **No push.** The branch and this plan are committed locally and not pushed.
   The protocol says to push the plan with the pass's work; there is no pass
   work yet, and a resend is expected to continue on this same branch, so one
   push at the end is the honest record rather than two.

## 11. Cost

- Wall-clock: about 12 minutes, all of it preconditions and reading.
- Suite runs: 0. Probe rows: 0. Build invocations: 0. Clones: 0.
- No token count: not measurable from inside the session.
