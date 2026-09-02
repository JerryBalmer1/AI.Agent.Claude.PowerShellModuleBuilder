# Pass 0031 — Operator's manual, testing docs, template markers, local publish

Tier: **full**. The pass adds executable surfaces — a root `.build.ps1` and
two scripts under `tools/publish/` — so it carries preconditions, a red-first
acceptance test, per-task evidence, a command transcript, a verify script,
Deviations and cost.

## 1. Prompt

```
# PASS 0031 — Operator's manual, testing docs, template markers, local publish
Tier: full

## Repositories
Harness only — branch `pass-0031-operators-manual` from `main`. The
instrument pin holds: `git diff f25d05d..HEAD -- skills/ commands/
.claude-plugin/ evals/` must be empty at start AND at end of this pass.
New executable content lives at root (`.build.ps1`) and `tools/publish/`
only.

## Voice, binding for every doc
"This is what I was able to build with Claude — here's how you can too."
The reader is the hero. Beginner-proof without condescension: every term
defined at first use, every command paste-able, every why before its how.
Every concept links the real pass/run/decision in THIS repo as its worked
example. Honest about failure — the recorded mistakes are teaching
material, not embarrassments. Second person, no hype, no emoji.

## Preconditions
Sync; tree clean; branch created; `docs/creating-an-agent/`,
`docs/testing/`, `tools/publish/`, root `.build.ps1` all absent.

## Acceptance test — red first
`plans/0031-operators-manual/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0031 delivered' {
        It 'README has the entry points' {
            $r = Get-Content "$RepoRoot/README.md" -Raw
            $r | Should -Match 'Creating a new agent, start here'
            $r | Should -Match 'docs/testing/' }
        It 'the manual exists with every chapter' {
            foreach ($f in '00-start-here','01-the-two-claudes',
                           '02-order-of-operations','03-test-first-or-nothing',
                           '04-fresh-sessions-and-contamination',
                           '05-calling-bullshit-verification',
                           '06-the-pass-protocol','07-failure-catalog',
                           '08-glossary','09-try-before-you-trust',
                           '10-using-as-a-template') {
                Test-Path "$RepoRoot/docs/creating-an-agent/$f.md" | Should -BeTrue } }
        It 'testing docs exist' {
            Test-Path "$RepoRoot/docs/testing/README.md" | Should -BeTrue }
        It 'chapters cite real artifacts' {
            foreach ($f in Get-ChildItem "$RepoRoot/docs/creating-an-agent" -Filter '0*.md') {
                (Get-Content $f.FullName -Raw) |
                    Should -Match '\((\.\./)+(plans|runs|decisions|journal|evals|method|LEDGER)' } }
        It 'no dead relative links in either docs tree' {
            $bad = foreach ($f in Get-ChildItem "$RepoRoot/docs/creating-an-agent","$RepoRoot/docs/testing" -Filter *.md) {
                foreach ($m in [regex]::Matches((Get-Content $f.FullName -Raw), '\]\((\.\.?/[^)#]+)')) {
                    $p = Join-Path $f.DirectoryName $m.Groups[1].Value
                    if (-not (Test-Path $p)) { "$($f.Name): $($m.Groups[1].Value)" } } }
            $bad | Should -BeNullOrEmpty }
        It 'build tasks exist' {
            $b = Get-Content "$RepoRoot/.build.ps1" -Raw
            $b | Should -Match 'task PublishLocal'
            $b | Should -Match 'task PublishReal' }
        It 'PublishLocal stages a marketplace under scratch' {
            Test-Path "$RepoRoot/plans/0031-operators-manual/publishlocal-transcript.txt" | Should -BeTrue }
        It 'PublishReal guard is red until 0030' {
            (Get-Content "$RepoRoot/plans/0031-operators-manual/publishreal-guard.txt" -Raw) |
                Should -Match 'GUARD: refused' }
        It 'template markers are enumerable' {
            (Select-String -Path "$RepoRoot/README.md","$RepoRoot/docs/creating-an-agent/*.md" -Pattern 'TEMPLATE:(remove|replace)' -AllMatches).Count |
                Should -BeGreaterThan 0 }
    }

Run it; report the red. Green at start stops the pass.

## Plan (∥ chapter drafting by parallel subagents, serial review; push
per group)
- [ ] 1. Acceptance red.
- [ ] 2. **The manual**, `docs/creating-an-agent/`: [chapters 00-10 as
      specified in the prompt header, reproduced in the task evidence below]
- [ ] 3. **Markers.** Apply `TEMPLATE:remove/replace` comments to the
      project-specific spans of README and the manual chapters (repo
      names, AzDO coordinates, this project's scores). Docs and README
      only — never skills/, commands/, evals/, method/.
- [ ] 4. **`docs/testing/README.md`** — the why of the whole test stack.
- [ ] 5. **Publish tooling.** Root `.build.ps1` (thin — tasks only, logic
      hidden in `tools/publish/`): `task PublishLocal`, `task PublishReal`.
      Falsify both.
- [ ] 6. README: near the top, heading exactly "Creating a new agent,
      start here:".
- [ ] 7. Acceptance green. Plan/verify/journal. LEDGER. Push;
      fast-forward main per 0009, score-free subject.

## Named spot-checks — verify.ps1 re-derives
1. Link-checker re-run from a fresh clone: zero dead links.
2. PublishLocal re-run in the fresh clone: staged marketplace present,
   JSON parses, plugin dir contains plugin.json + 14 skills + 2
   commands, byte-compared to the repo's copies.
3. PublishReal re-run: nonzero exit, `GUARD: refused` in output
   (-FailCheck: drop a dummy marketplace.json into the CLONE's
   .claude-plugin/, guard must flip to the checklist path — clone-only,
   never the working repo).
4. Instrument diff vs f25d05d over the four pinned paths: empty.
5. Template-marker grep yields a non-empty, enumerated list.

## Constraints
No writes to skills/, commands/, .claude-plugin/, evals/, method/ —
readers, yes; writers, no. Scratch-only staging. No score claims beyond
run-record text; every number linked. No pushes by the publish tooling
ever.

## Report back
Chapter list one-lined, the README section verbatim, both publish
transcripts' paths, the worked-audit path, marker count, link-check
result, pushed SHA.
```

*(The prompt's task 2 enumerates each chapter's required content at length.
It is reproduced in full in the pass branch's first commit message chain and
in the per-chapter evidence below rather than duplicated here.)*

## 2. Preconditions

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | synced with origin | `git fetch origin && git status -sb` | `## main...origin/main` — level |
| 2 | tree clean | `git status --porcelain` | no output |
| 3 | branch created | `git checkout -b pass-0031-operators-manual` | `Switched to a new branch` |
| 4 | `docs/creating-an-agent/` absent | `ls docs/` | `no docs/` |
| 5 | `docs/testing/` absent | `ls docs/` | `no docs/` |
| 6 | `tools/publish/` absent | `ls tools/` | `no tools/` |
| 7 | root `.build.ps1` absent | `ls .build.ps1` | `no .build.ps1` |
| 8 | instrument pin | `git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/` | **NOT empty** — see Deviations 1 |

Precondition 8 did not hold as the prompt states it. It is a known,
recorded condition rather than a surprise, and the pass proceeded on the
LEDGER's prescribed form. Full reasoning in Deviations 1.

The plugin-proper form is clean:

```
$ git diff --stat f25d05d..HEAD -- skills/ commands/ .claude-plugin/
(no output)
```

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| InvokeBuild | 5.14.23 |
| OS | Windows 11 Home 10.0.26200 |
| Claude Code | VS Code extension; model `claude-opus-5[1m]` |
| branch | `pass-0031-operators-manual` |
| HEAD at start | `180b717` |
| `claude` CLI | **not on PATH** — `Get-Command claude` returns nothing |

## 4. Acceptance test — red first

```
$ Invoke-Pester ./plans/0031-operators-manual/accept.Tests.ps1 -Output Detailed

  [-] README has the entry points 120ms
  [-] the manual exists with every chapter 53ms
  [-] testing docs exist 26ms
  [+] chapters cite real artifacts 102ms
  [+] no dead relative links in either docs tree 27ms
  [-] build tasks exist 19ms
  [-] PublishLocal stages a marketplace under scratch 15ms
  [-] PublishReal guard is red until 0030 27ms
  [-] template markers are enumerable 27ms

Tests Passed: 2, Failed: 7, Skipped: 0
```

Committed red as `6ec7dc4`.

**The two green ones are vacuous, and that is worth stating rather than
counting as passes.** Both iterate `Get-ChildItem` over
`docs/creating-an-agent` and `docs/testing`, which did not exist;
`Get-ChildItem` errored, the loop body never ran, and an assertion that
grades nothing reports green. This is `method/METHOD.md`'s *zero cases is
not a pass* and `evals/HARNESS.md` hazard 6's *a run of zero rows is not a
pass*, arriving inside this pass's own acceptance test. They become real
assertions only once the trees exist, which is the state they are in at
green. No test was rewritten to fix this: the prompt supplied the file
verbatim and `PLAN-PROTOCOL.md`'s file-supply rule makes it the pass's job
to run it as given and report, not to improve it.

## 5. Tasks

### - [x] 1. Acceptance red

Above. `6ec7dc4`.

### - [x] 2. The manual — `docs/creating-an-agent/`

Eleven chapters. Drafted by six parallel subagents against per-chapter
briefs, then reviewed serially by this session: every quotation re-checked
against its source with whitespace collapsed and a case-sensitive operator
(`evals/HARNESS.md` hazard 8's prescribed protection), every number traced
to the file it came from, every relative link resolved.

| Chapter | Lines | What it is |
|---|---:|---|
| `00-start-here.md` | 324 | What "an agent" means here; the three-step loop; honest prerequisites; the method-not-the-stack argument; the real result; the chapter map; the maintenance rule. |
| `01-the-two-claudes.md` | 348 | Director vs executor, what each may and may never do, the project-context pattern, fenced-block routing, the real routing failures. |
| `02-order-of-operations.md` | 400 | The numbered build order with this repo's pass numbers beside each stage, and the do-nots with the failure each prevents. |
| `03-test-first-or-nothing.md` | 390+ | Red-first; falsification rows and polarity in plain words; the inert-assertion catches; the coverage-gate story end to end. |
| `04-fresh-sessions-and-contamination.md` | 508 | Why the prompt is message one; what contaminates; the observable controls; the honest limit; the recorded self-stops. |
| `05-calling-bullshit-verification.md` | 241 | Never trust the report. The director's audit loop as paste-able commands, verify-script rules, and a full worked audit of run 006. |
| `06-the-pass-protocol.md` | 539 | Prompt anatomy section by section, tiers, the Deviations doctrine with real examples, push-early. |
| `07-failure-catalog.md` | 1184 | Every recorded mistake, grouped, three-part shape, director's mistakes included and attributed. |
| `08-glossary.md` | see green | Every term of art in plain English, linked to where it lives. |
| `09-try-before-you-trust.md` | 467 | A fully local install and uninstall for a reader who does not trust AI yet, and what PublishReal is. |
| `10-using-as-a-template.md` | 386 | METHOD.md's PORTABLE/TUNE/DOMAIN taxonomy, the marker convention, the one grep, the stripping checklist. |

Three corrections applied during review:

1. Chapter 00 described chapter 09 twice as being about falsification. It is
   the local-install chapter. Both descriptions corrected.
2. Chapter 09's pointers to chapters 07 and 08 had been written as unlinked
   prose because those files did not exist when its agent verified. Promoted
   to links once they landed.
3. Nothing else. Every other flagged item was a discrepancy in the
   repository or the prompt, not in the drafting — see Deviations.

### - [x] 3. Markers

Eight marker blocks in `README.md`, at the eight project-specific spans;
four in the manual, applied by the chapters' own authors. Each marker
carries its reason, not just its verb.

```
$ (Select-String -Path ./README.md,./docs/creating-an-agent/*.md `
      -Pattern 'TEMPLATE:(remove|replace)' -AllMatches).Count
19
```

The applying script was run four times and the file hash compared:

```
run 1: markers inserted: 8   |   markers in README now: 8
run 2: markers inserted: 0   |   markers in README now: 8
run 3: markers inserted: 0   |   markers in README now: 8
README unchanged by a further run: True
```

Its first two idempotence guards both **failed silently while reporting
success** — the first looked at the line immediately above the heading and
found the block's trailing blank; the second looked back further and broke
on the block's own continuation lines. Both printed `markers inserted: 8` on
a second run and duplicated every marker. Caught by running it twice and
counting, not by reading it. The third guard tests whole-file content.
This is the same shape as `evals/HARNESS.md` hazard 4, met in a tool nobody
would have thought to falsify.

No marker appears under `skills/`, `commands/`, `evals/` or `method/`;
`verify.ps1` check 5 asserts this, because a comment added to a pinned path
changes the blob and breaks the ladder's pin.

### - [x] 4. `docs/testing/README.md`

655 lines. Conformance vs functional and why both; the shape-not-function
trap; falsification with one worked break and control; the ordered
fail-fast runner; the mutation-tested Terraform oracle with its
generalisation limit stated; what each number in a run record means; how to
run it; and what the stack does not prove. Every section links its artifact
under `evals/` or `runs/`.

It re-ran the artifacts rather than quoting them —
`Invoke-TfOracleFalsification.ps1` live (`CONTROL GREEN`, `DETECTED: 7 / 7`)
and `Compare-TfGraph.ps1` against the oracle (`nodes=78 edges=59 diffs=0`) —
and that is how it found three pieces of drift, one of them a red test.
Deviations 4, 5 and 6.

### - [x] 5. Publish tooling

`.build.ps1` at the root, thin: two tasks and a helper, no logic.
`tools/publish/Publish-Local.ps1` (183 lines) and
`tools/publish/Publish-Real.ps1` (92 lines).

**PublishLocal.** Stages `.claude-plugin/plugin.json`, `skills/` and
`commands/` into `scratch/local-marketplace/psmodule/` beside a generated
`.claude-plugin/marketplace.json` whose `source` is the relative `./psmodule`.
Refuses any stage root not under `scratch/`. Validates the staged tree
itself. Attempts `claude plugin validate` only if the CLI resolves, and says
so when it does not — which on this machine it does not. Prints the two
`/plugin` commands for the human to paste inside Claude Code, and the two
that remove it again.

Evidence: `publishlocal-transcript.txt`. 20 files staged, 14 skills, 2
commands, byte-identical to the repository's copies across 19 files, and
the tree hash identical across two consecutive runs.

**Falsification, both rows, in `publishlocal-transcript.txt`:**

| Row | Probe | Break landed? | Expected | Result |
|---|---|---|---|---|
| 1 (break) | `marketplace.json` byte 0: `0x7B '{'` → `0x21 '!'` | yes, sha256 changed | RED | **CONFIRMED** — exit 1, "does not parse as JSON" |
| 2 (control) | add a harmless extra key; still valid JSON | yes, sha256 changed | GREEN | **CONFIRMED** — exit 0; it checks validity, not sameness |

Restored clean afterwards and re-validated at exit 0. A third row exercises
the scratch-root rail: `-StageRoot ./skills` exits 1 with `REFUSED`, and
`git status --porcelain skills` stays empty.

The validator is one function reachable from both the staging path and
`-ValidateOnly`, so the control grades exactly the code the publish path
runs. Restaging would have erased the corruption and proved nothing.

**PublishReal.** A guard with no push path at all — not a guarded one, not a
`-Force` one. Evidence: `publishreal-guard.txt`, three sections.

```
GUARD: refused.

  Looked for : .../.claude-plugin/marketplace.json
  Found      : nothing.
```

exit 1, via InvokeBuild and directly. Section 3 falsifies it in a clone: a
dummy `marketplace.json` flips it to the checklist path at exit 0, still
publishing nothing, and the working repository is confirmed unchanged
afterwards. A guard that has only ever refused is indistinguishable from one
that always refuses.

**A defect found and fixed inside this task.** The first `.build.ps1` called
its scripts with `&` in-process. `Invoke-Build PublishReal` then printed
`GUARD: refused` and its whole twenty-line explanation, and reported
**`Build succeeded. 1 tasks, 0 errors, 0 warnings`**, because `exit 1` inside
a `&`-invoked script unwinds that script and sets no `$LASTEXITCODE`
InvokeBuild can see. The message was right and the exit code was wrong.
Found by observing the exit code rather than reading the output. Both tasks
now invoke a child `pwsh` and throw on non-zero. `-File` is safe here because
every argument is a single string; it would not be for an array
(LEDGER item 15).

### - [x] 6. README

The section, verbatim as landed:

```markdown
## Creating a new agent, start here:

Everything here was built by directing Claude, and the method is written down
so you can do the same thing on your own domain. Start at
[docs/creating-an-agent/00-start-here.md](docs/creating-an-agent/00-start-here.md)
— eleven chapters, each one worked against a real pass, run or decision in this
repository, including the mistakes.

**Deciding whether this much testing is worth it?**
[docs/testing/](docs/testing/README.md) explains what each layer of the stack
catches that the others do not, with the artifact behind every claim.

**Try it locally first.**
[Chapter 9](docs/creating-an-agent/09-try-before-you-trust.md) installs and
drives the plugin entirely on your own machine, and shows you how to remove it
again, before anything public is involved.
```

Nothing else in README changed except the eight marker blocks from task 3.

### - [x] 7. Acceptance green, records, LEDGER, push

See section 6 below.

## 6. Acceptance test — green

Same test, same command:

```
$ Invoke-Pester ./plans/0031-operators-manual/accept.Tests.ps1 -Output Detailed

Describing Pass 0031 delivered
  [+] README has the entry points 98ms
  [+] the manual exists with every chapter 19ms
  [+] testing docs exist 4ms
  [+] chapters cite real artifacts 56ms
  [+] no dead relative links in either docs tree 292ms
  [+] build tasks exist 10ms
  [+] PublishLocal stages a marketplace under scratch 6ms
  [+] PublishReal guard is red until 0030 7ms
  [+] template markers are enumerable 26ms

Tests Passed: 9, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

The two assertions that were vacuously green at red-first now grade real
content: `chapters cite real artifacts` iterates eleven files, and
`no dead relative links` walks both trees — its run time moved from 27 ms
over nothing to 292 ms over the real link set, which is the observable
difference between an assertion that ran and one that did not.

## 7. Command transcript

Every command that changed state, and every command whose output produced a
number in this plan. Exploratory reads excluded.

```powershell
# --- preconditions -------------------------------------------------------
git fetch origin; git status -sb
git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/   # NOT empty
git diff --stat f25d05d..HEAD -- skills/ commands/ .claude-plugin/   # empty
git checkout -b pass-0031-operators-manual

# --- acceptance, red -----------------------------------------------------
Invoke-Pester ./plans/0031-operators-manual/accept.Tests.ps1 -Output Detailed
git add plans/0031-operators-manual/accept.Tests.ps1
git commit -m "Pass 0031 acceptance test, red"          # 6ec7dc4

# --- publish tooling -----------------------------------------------------
Invoke-Build PublishLocal
Invoke-Build PublishReal                                 # printed the refusal,
                                                         # reported SUCCESS - the
                                                         # defect; fixed below
git add .build.ps1 tools/publish/
git commit -m "Publish tooling: a local staging task and a guard that refuses"
git push -u origin pass-0031-operators-manual

# --- publish falsification (all writes under scratch/) -------------------
pwsh -NoProfile -File tools/publish/Publish-Local.ps1 -ValidateOnly
#   after corrupting marketplace.json byte 0 -> exit 1, "does not parse as JSON"
pwsh -NoProfile -File tools/publish/Publish-Local.ps1 -ValidateOnly
#   after adding a harmless key      -> exit 0  (control stays green)
pwsh -NoProfile -File tools/publish/Publish-Local.ps1
pwsh -NoProfile -File tools/publish/Publish-Local.ps1 -StageRoot ./skills
#   -> exit 1, REFUSED; git status --porcelain skills  -> empty
pwsh -NoProfile -File tools/publish/Publish-Real.ps1                  # exit 1
git clone . scratch/guard-falsification
#   dummy marketplace.json into the CLONE only -> guard exits 0, checklist path
#   Test-Path .claude-plugin/marketplace.json (working repo) -> False

# --- worked audit of run 006 --------------------------------------------
git ls-remote https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git refs/heads/run-006-plugin-on
git -c core.longpaths=true clone -q --branch run-006-plugin-on <url> scratch/audit-006
git -C scratch/audit-006 rev-parse HEAD
git -C scratch/audit-006 fetch -q origin main
git -C scratch/audit-006 merge-base --is-ancestor 7066916 origin/main   # exit 1
pwsh -NoProfile -Command "Set-Location scratch/audit-006; ./build.ps1"  # exit 0
./evals/conformance/Invoke-Conformance.ps1 -Path scratch/audit-006 `
    -ModuleName PSAzureDevOpsGraph `
    -Tag @('Universal','Repository','HouseStyle','RequiresBuild') `
    -ResultPath scratch/audit-006-conformance.json
./evals/functional/Compare-Graph.ps1 `
    -CandidatePath runs/006-plugin-on/graph.json `
    -ReportPath scratch/audit-006-compare.json

# --- markers -------------------------------------------------------------
#   applying script run four times; file hash compared after each
Select-String -Path ./README.md,./docs/creating-an-agent/*.md `
    -Pattern TEMPLATE:(remove|replace) -AllMatches       # 19

# --- the red test found while writing docs/testing -----------------------
Invoke-Pester ./evals/tf/Compare-TfGraph.Tests.ps1        # 14 passed, 1 failed

# --- acceptance, green ---------------------------------------------------
Invoke-Pester ./plans/0031-operators-manual/accept.Tests.ps1 -Output Detailed

# --- verification --------------------------------------------------------
pwsh -NoProfile -File plans/0031-operators-manual/verify.ps1
pwsh -NoProfile -File plans/0031-operators-manual/verify.ps1 -FailCheck
```

## 9. Verify script

`plans/0031-operators-manual/verify.ps1`, committed beside this plan. It is
too long to reproduce here without risking two copies that disagree — the
reason `PLAN-PROTOCOL.md` §9 gives, which is hazard 6 pointed at the one
artifact whose job is to disprove the plan.

What it checks, from a **fresh clone at a pinned SHA** in a temp directory,
never the working tree and never `scratch/`:

1. zero dead relative links across both docs trees
2. `PublishLocal` in the clone: staged marketplace present, both JSON files
   parse, 14 skills and 2 commands, byte-compared against the clone's own
   copies
3. `PublishReal`: non-zero exit and `GUARD: refused` present
4. the instrument pin — three-path form empty; four-path form confined to
   the documented `evals/HARNESS.md`; and the assertion that actually
   belongs to this pass, that pass 0031 changed nothing under any of the
   four
5. template markers enumerated, and none leaked into pinned paths
6. the acceptance test itself, re-run against the clone

`-FailCheck` runs a probe per check: a link repointed at a non-existent
file, a corrupted staged byte, a dummy `marketplace.json` dropped into the
**clone**. Each probe asserts it changed the target before the check is
re-run, and reports `PROBE DID NOT APPLY` rather than a green if it did not.
The `PublishReal` probe additionally asserts afterwards that the working
repository did not grow a `marketplace.json`.

## 10. Deviations

**1. The prompt's instrument pin was already broken at preconditions, and
the LEDGER says so.** The prompt requires
`git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/` to be
empty at start and at end. It is not empty at start: pass 0029 landed +69
lines in `evals/HARNESS.md`. `LEDGER.md`'s Pins section records exactly this
and prescribes the three-path form, which is empty and stayed empty. The
pass proceeded on the LEDGER's form and `verify.ps1` asserts both — plus the
claim that actually belongs here, that pass 0031 changed nothing under any
of the four paths. Reported rather than silently substituted.

**2. "The session that stopped itself three times" is not what the artifacts
record.** The prompt's chapter 04 brief asks for this. What is recorded is
**one** session-gate stop — pass 0026, because pass 0025 had legitimately
read two run records for a denominator falsification — and passes 0026, 0027
and 0028 each opening a fresh session because of it. Three further stops
exist with three different causes: pass 0027 at task 1 on a truncated
prompt, an earlier issue of pass 0012 at preconditions with `$env:AZDO_PAT`
unset, and an earlier issue of pass 0010 at precondition 4. Four stops, four
causes, one of them the session gate. Chapter 04 writes what is recorded and
flags the discrepancy in the text.

**3. "The batch that died with 33 untracked files" is pass 0022, not 0025.**
The count is right and the rule is right; the pass number in the retelling
was not. `journal/0022-tohtml-contract.md` and
`plans/0022-tohtml-contract/plan.md` carry it; pass 0025's records describe
an entirely different pass and mention no such incident. Chapter 06 tells it
accurately and notes the misattribution. (The prompt named the event without
a pass number; the misattribution to 0025 was in this session's own briefing
of the drafting subagent, and the subagent caught it.)

**4. `evals/tf/Compare-TfGraph.Tests.ps1` is RED as committed on `main`.**
Line 41 asserts `$result.ExpectedEdgeCount | Should-Be 57`; the oracle
amended under decision 0012 holds **59**, and the comparator returns 59.
Confirmed by execution, not inference:

```
$ Invoke-Pester ./evals/tf/Compare-TfGraph.Tests.ps1
PassedCount : 14
FailedCount : 1
  states what it compared, not just that it matched
  Line 41 | $result.ExpectedEdgeCount | Should-Be 57
```

Found by the testing document re-running the artifact rather than quoting
it. **Not fixed here** — `evals/` is read-only to this pass by its own
constraints, and a one-line edit to a test in a pinned path is exactly the
thing the pin exists to prevent. Recorded as backlog 20.

**5. `README.md` and `evals/` disagree on the control count.** README says
"eleven of twelve controls stay green and the twelfth is documented as
failing", and `evals/conformance/README.md` agrees; but
`evals/conformance/baseline/FALSIFICATION.md` says "All twelve are now
correct; row 7's was failing until Pass 0008 converted that assertion to
AST", and `TASK.md`'s pass 0008 outcome says "control now green". The
testing document used README's figure as instructed and named the
contradiction. Recorded as backlog 21.

**6. `Universal` corpus figure has drifted in two places.**
`evals/conformance/README.md`'s *Validation status* paragraph says five of
ten survive all nine targets; its own *Known limits* section, `README.md`
and `UNIVERSAL-CORPUS.md` all say seven of nine, and UNIVERSAL-CORPUS.md
explicitly records it as "up from five of ten". `evals/HARNESS.md`'s Open
questions also still carries the stale five-of-ten. Recorded as backlog 21.

**7. `PLAN-PROTOCOL.md`'s own worked example contains a false clause.** Its
tier section says pass 0012 "shipped without the red-first test the tier
requires". `plans/0012-case-split-and-corrections/plan.md` §3 is headed
*Acceptance test — red first* and records `RED-FIRST: Passed=315 Failed=15
Total=330`; its prompt required both a red-first test and a `verify.ps1`
regardless of the light label, and both are present. Everything else in the
worked example checks out, including that the pass amended an assertion and
flagged the mislabel itself. Not corrected here — amending the protocol
document is a deliberate act and outside a documentation pass's scope.
Recorded as backlog 22.

**8. The LEDGER backlog item number the prompt supplies is taken.** The
prompt says to append "17. Doc maintenance is a standing obligation…".
Items 17 and 18 already exist (the missing baseline control, and per-skill
ablation). The text was appended as **item 19**, unchanged in substance.

**9. Two acceptance assertions are vacuously green at red-first.** Stated in
section 4 rather than repaired, because the prompt supplied the test file
verbatim and the file-supply rule makes running it as given the pass's job.
They grade honestly at green, when the directories exist.

**10. Chapters were drafted by parallel subagents, per the prompt's plan
header.** This is worth recording because it changes what the review means:
no chapter's prose was written by the session that reviewed it, and the
review re-derived every quotation and number rather than trusting the
drafting agent's report. Two drafting agents reported near-false-greens in
their own link checks — one where `Get-ChildItem -Filter '0[01]-*.md'`
matched zero files because the filesystem filter does not support character
classes, and reported ALL LINKS RESOLVE over an empty set. That is hazard
6's *a run of zero rows is not a pass*, twice, inside the tooling written to
check this pass's own work.

**11. This session has read `runs/` extensively and is disqualified as a
blind builder.** Expected and necessary for a documentation pass that must
cite the run records, and stated here so nobody reuses the session. See
`evals/HARNESS.md` hazard 9.

## 11. Cost

| | |
|---|---|
| Wall clock | one session |
| Acceptance runs | 3 (red, mid-pass debug, green) |
| Falsification rows | 5 — 2 for PublishLocal (break + control), 1 scratch-root rail, 1 for the PublishReal guard, 1 idempotence probe on the marker script |
| Suite runs | conformance 1 (audit, in a fresh clone of the target at run 006's SHA); `Compare-Graph` 1; `Compare-TfGraph.Tests.ps1` 2 |
| Target builds | 1 (`./build.ps1` in the audit clone, exit 0, 43 s) |
| `PublishLocal` invocations | 9 across staging, idempotence, falsification and verification |
| Drafting subagents | 6, in parallel |

No token count. The agent cannot measure one from inside the session.
