# Pass 0046 — runner exclusion regex repair (backlog 62)

Tier: **full** (repository). One character of executable behaviour changed, so
a red-first acceptance test, per-task evidence, a verify script and a command
transcript are all required regardless of how much of the diff is prose.

## 1. Prompt

```
# PASS 0046 — runner exclusion regex repair (backlog 62)

## Signals

🔴 hard stop (report, never resolve) · 🟠 operator action · 🟢 agent task · 🔵 evidence gate · ⛔ never, whole pass. Per PLAN-PROTOCOL as amended by 0044.

**Tier:** Repository (instrument repair in the harness; no conformance assertion changes, no release).

**Target repositories:** `AI.Agent.Claude.PowerShellModuleBuilder` only. Ecosystem repos read-only (one is cloned to `scratch/` as a test subject). ⛔ `scratch/PSModuleGraph` untouched. ⛔ Nothing reaches Azure DevOps.

**Purpose.** Backlog 62: `Invoke-Conformance.ps1:122` writes the path-exclusion character class as `[\/]` where `Conformance.Tests.ps1:61`, `:148`, and `Help.Tests.ps1:55` write `[\\/]`. Inside a class, `[\/]` is an escaped forward slash only — the runner's `output|scratch|.git|gallery|fixtures|node_modules` exclusion has never fired on a Windows path. The observed symptom (0045) was the lucky direction: a refusal to derive `-ModuleName` for PSGraphRender because `output/PSGraphRender/PSGraphRender.psd1` counted as a second candidate. The unlucky direction admits a `scratch/` or `gallery/` manifest into the candidate set, where the suite's own F-8 comment calls the outcome worse than grading nothing. The durable form is the one-character repair **plus the tests whose absence let four copies of one regex drift** — a one-character fix with no test is how this happened, per the finding's own words.

**Series guard, binding:** ⛔ `cases-defined` does not move. No file this pass adds may enter `Invoke-Conformance.ps1`'s inventory. The new tests live outside whatever scope that inventory reads — task 1 establishes the scope from the runner's own code before anything is placed, and the acceptance test asserts the denominator is unchanged.

## 0. Sync

🟢 Parallel fetch per workspace repo, ff-only updates. 🔵 Report. 🔴 Divergence or dirt.

## 1. Preconditions

1. **Frontier, three sources:** 🔴 any source shows 0046 assigned. 🔴 Any frontier disagreement — all three read **0045** (harness `main` `13e1ea9`) at authoring. 🔵 Record the values.
2. 🔴 Harness not on `main`, not clean, or not ff-synced. 🔴 Harness HEAD has moved from `13e1ea9` — the line numbers and the four-site inventory below were read from that tree.
3. 🔵 **Inventory scope established:** read `Invoke-Conformance.ps1`'s test-file discovery (the every-`*.Tests.ps1` inventory) and record verbatim whether it is directory-only or recursive. The placement of this pass's new test file is derived from that answer, not assumed. 🔴 The scope cannot be determined unambiguously from the code.
4. **Sequencing gate:** 🔴 any task-3 work before section 2's reds are observed.

## 2. Acceptance — both defect directions observed red first

🟢 Commit `plans/0046-runner-regex/accept.ps1` before any repair. Against a scratch clone of PSGraphRender at its current `main` (`cd4857d`), with two planted manifests — `output/PSGraphRender/PSGraphRender.psd1` (copy of the real one) and `scratch/Fake/Fake.psd1`:

- **Red A (refusal direction):** the runner, as it stands, refuses `-ModuleName` derivation because the `output/` manifest survives exclusion. 🔵 Record the refusal verbatim.
- **Red B (admission direction, the dangerous one):** demonstrate that the current `[\/]` class fails to match a Windows-style path (backslash separators) containing `scratch`, i.e. the planted `scratch/` manifest survives the exclusion filter that the three correct copies would remove. 🔵 Record the match results for the broken and correct patterns side by side.
- **Denominator baseline:** 🔵 record `CasesDefined` global and per-target for PSGraphRender at base (0045 recorded 36 there).

Green criteria, checked after task 3: the runner derives `-ModuleName` cleanly against the same planted clone; the `scratch/` manifest is excluded; all four regex sites are byte-identical; `CasesDefined` unchanged at every scope.

## 3. Tasks (serial)

1. 🟢 Branch `pass-0046-runner-regex`; first commit pushed immediately.
2. 🟢 **The repair:** `Invoke-Conformance.ps1:122` → `[\\/]`, matching the other three sites byte-for-byte. This one character is the commit's only change to the runner.
3. 🟢 **The tests that keep it fixed**, placed per precondition 3 so they are ⛔ outside the conformance inventory, their own commit:
   - **Polarity pair:** a Windows-style path under each excluded segment (`output`, `scratch`, `.git`, `gallery`, `fixtures`, `node_modules`) is excluded, and a legitimate `src/`-side manifest path is not. Red-capability: the pair run against the pre-repair pattern must fail — 🔵 record that run.
   - **Copies-agree:** the exclusion regex extracted from all four sites (`Invoke-Conformance.ps1`, `Conformance.Tests.ps1` ×2, `Help.Tests.ps1`) is one identical string. Red demo: a scratch copy with any one site altered. This is the check whose absence let the drift happen; it fails loudly the next time any copy is edited alone.
4. 🟢 Re-run section 2 against the planted clone: 🔵 both greens, denominator unchanged, recorded verbatim.
5. 🟢 Records: `plans/0046-runner-regex/plan.md` (prompt verbatim, evidence, Deviations); `plans/0046-runner-regex/verify.ps1` (decision 0004 path; `-FailCheck` restores `[\/]` in a scratch copy and must go red on both the polarity pair and copies-agree — 🔵 both exits recorded); LEDGER (counter 0046; backlog 62 RESOLVED in place; if the four-site count corrects the item's "three copies", amend by dated append, never rewrite); journal (six fields, Capability never benefit).
6. 🟢 Fast-forward harness `main` per 0009. ⛔ No tag — the installed plugin surface does not change (`git diff v1.2.0..HEAD -- skills/ commands/ .claude-plugin/` stays empty; 🔵 assert and record it, the 0040-pattern spot-check).

## 4. Spot-checks (🔵 each; red-capability stated per METHOD)

- **SC1 — minimal repair diff:** the task-2 commit touches one file, one line, one character class. Red demo: scratch diff touching a second site.
- **SC2 — no inventory growth:** `CasesDefined` identical at base and head, globally and against the planted PSGraphRender clone; the new test file absent from the runner's discovered set (🔵 print the discovered list). Red demo: scratch copy of the new test file dropped into the inventoried scope.
- **SC3 — plugin surface frozen:** the three-path diff against `v1.2.0` is empty at head. Red demo: the check run against a scratch tree with one skill file touched.

## 5. Constraints

⛔ No conformance assertion text changes — `Conformance.Tests.ps1` and `Help.Tests.ps1` are untouched (their copies are already correct; the copies-agree test reads them, never edits them). ⛔ Nothing lands inside the conformance inventory scope. ⛔ Backlog 61 (harness discoverability) out of scope — its own pass. ⛔ No force/reset/rebase; planted clones and all scratch work under `scratch/` only.

## 6. Local handoff — the last act

🟢 Every workspace repo: checkout `main`, `pull --ff-only`, `fetch --tags --prune`, status clean; 🔵 LOCAL STATE table. Divergence or dirt reported, never resolved.
```

## 2. Preconditions

### Section 0 — sync 🔵

Five repositories fetched with `--prune --tags`, every one already at its
remote tip. Nothing needed fast-forwarding.

| repo | branch | HEAD | ahead/behind | dirty |
|---|---|---|---|---|
| AI.Agent.Claude.PowerShellModuleBuilder | main | `13e1ea9` | 0 / 0 | no |
| PSAzureDevOpsGraph | main | `5551a20` | 0 / 0 | no |
| PSGraphRender | main | `cd4857d` | 0 / 0 | no |
| PSGraphRenderToHtml | main | `55deb28` | 0 / 0 | no |
| PSTerraformGraph | main | `74d85ac` | 0 / 0 | no |

`PSGraphRender` at `cd4857d` is the commit the prompt names for the planted
clone, confirmed rather than assumed.

**Stranded branches.** Every `pass-*` branch in all five repositories has its
tip as an ancestor of that repository's `main`, with one exception:
`pass-0042-philosophy`, local and remote. That is not a finding — it is
`decisions/0016-abandon-pass-0042.md`, which preserves the branch unmerged on
purpose as the record of an abandoned pass. Reported here because the sync rule
says to report it, and resolved nowhere.

### Precondition 1 — the frontier, three sources 🔵

| source | command | value |
|---|---|---|
| LEDGER | `grep -n 'Last landed' LEDGER.md` | `Last landed: **0045**` |
| plans tree | `ls -d plans/[0-9]* \| sort \| tail -1` | `plans/0045-workspace-deregistration` |
| journal tree | `ls journal/[0-9]*.md \| sort \| tail -1` | `journal/0045-workspace-deregistration.md` |

All three read **0045**. They agree, and they agree with the value the prompt
states.

**Is 0046 free?** Yes, in all four senses and across all five repositories. No
`plans/0046-*`, no `journal/0046-*`, no LEDGER citation (`grep -c '0046'
LEDGER.md` → `0`), and no `pass-0046-*` branch anywhere, local or remote.

### Precondition 2 — the harness tree 🔵

On `main`, `git status --porcelain` empty, `git rev-list --left-right --count
HEAD...@{u}` → `0	0`, HEAD `13e1ea9`. Unmoved from the commit the prompt's line
numbers and four-site inventory were read against.

### Precondition 3 — the inventory scope 🔵

Read from `evals/conformance/Invoke-Conformance.ps1:239-242`, verbatim:

```powershell
$script:SuiteFiles = @(
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.Tests.ps1 -File |
        Sort-Object Name
)
```

**Directory-only.** There is no `-Recurse`, and `$PSScriptRoot` is
`evals/conformance/`. A file is inventoried if and only if it sits *directly*
in that directory.

This is the only `*.Tests.ps1` discovery anywhere in the repository —
`grep -rn "Filter \*\.Tests\.ps1" evals/ tools/ skills/` returns this line and
no other. There is no CI configuration (`.github/` does not exist) and
`.build.ps1` has two tasks, both publishing, neither running Pester.

The scope is therefore unambiguous, and the placement follows from it rather
than from preference: **`evals/harness/`**, a sibling of `evals/conformance/`,
`evals/functional/` and `evals/tf/`, all of which already carry their own
`*.Tests.ps1`.

### Precondition 4 — the sequencing gate

Honoured. The commit order in `git log` is the evidence: `318b95a` (accept.ps1)
and `7bd3a6c` (the red-first run) both precede `a2d258a` (the repair), which
precedes `f5821ab` (the task-3 tests).

### The four sites, confirmed at `13e1ea9` 🔵

```
evals/conformance/Conformance.Tests.ps1:61   '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'
evals/conformance/Conformance.Tests.ps1:148  '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'
evals/conformance/Help.Tests.ps1:55          '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'
evals/conformance/Invoke-Conformance.ps1:122 '[\/](output|scratch|\.git|gallery|fixtures|node_modules)[\/]'
```

Four sites, three correct, one wrong, exactly at the lines the prompt named.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 (also present: 5.7.1, 3.4.0; the runner selects 6.x) |
| OS | Microsoft Windows NT 10.0.26200.0 (Windows 11 Home) |
| git | 2.41.0.windows.1 |
| model | claude-opus-5[1m] |
| branch | `pass-0046-runner-regex`, from `main` at `13e1ea9` |

## 4. Acceptance test — red first

`plans/0046-runner-regex/accept.ps1`, committed as `318b95a` **before any
repair**. It clones PSGraphRender at `main` into `scratch/accept-0046/`, plants
`output/PSGraphRender/PSGraphRender.psd1` and `scratch/Fake/Fake.psd1` (both
copies of the real manifest), and asserts what a repaired runner would do. Exit
0 is green; non-zero, naming the disagreeing checks, is red.

The exclusion patterns are **extracted from source**, never retyped. A test
that retypes the pattern it grades grades the retyped copy.

Full transcript: `accept-red.txt`. **Exit 6.**

### Red B — the admission direction 🔵

Recorded first because it is the direction nobody had seen, and it needs no run
of anything: the character class either matches a backslash or it does not.

```
  runner: [\/](output|scratch|\.git|gallery|fixtures|node_modules)[\/]
  suite:  [\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]

Path                                     RunnerExcludes SuiteExcludes
----                                     -------------- -------------
\output\PSGraphRender\PSGraphRender.psd1          False          True
\scratch\Fake\Fake.psd1                           False          True
```

And end to end, through the runner's own filter shape with only the pattern
varying:

```
  candidate set under the RUNNER's pattern (4):
    output\PSGraphRender\PSGraphRender.psd1
    scratch\Fake\Fake.psd1
    src\PSGraphRender\PSGraphRender.psd1
    src\PSGraphRender\TemplateSets\cytoscape\vendor\vendor.psd1
  candidate set under the SUITE's pattern (2):
    src\PSGraphRender\PSGraphRender.psd1
    src\PSGraphRender\TemplateSets\cytoscape\vendor\vendor.psd1
```

The planted `scratch/` manifest is a candidate for the runner and is not one
for the suite. That is the defect in the direction rule F-8's own comment calls
worse than grading nothing, observed rather than argued.

### Red A — the refusal direction 🔵

```
Cannot derive -ModuleName: 2 manifests under
'…\scratch\accept-0046\PSGraphRender\src', none preferred.
Candidates: src\PSGraphRender\PSGraphRender.psd1;
src\PSGraphRender\TemplateSets\cytoscape\vendor\vendor.psd1.
Pass -ModuleName to choose.
```

Verbatim, and it is worth reading closely because **the message names neither
plant**. The causal chain has two links, and the prompt and LEDGER item 62 both
compress them into one:

1. The `output/` manifest survives exclusion, so two candidates are named for
   the target, so `$suiteCanDecide` is false. *This* is the regex defect.
2. Falling into the `src/` rule, the runner finds two manifests under `src/` —
   the module's own and `TemplateSets/cytoscape/vendor/vendor.psd1`, whose base
   name equals its directory name — and refuses.

The vendored manifest is not a defect and is not this pass's business; it is
only ever reached because link 1 put the runner there. Repairing the regex
makes `$suiteCanDecide` true, and the `src/` block never executes. Pass 0045
saw exactly this message and recorded it as the `output/` symptom, which is
right about the cause and imprecise about the text.

### Denominator baseline 🔵

```
  per-target (default tags): CasesDefined = 36  (HouseStyle=23, Repository=4, Universal=9)
  per-target (default tags): CasesRun     = 161   Passed=105 Failed=56 ScorePct=65.22
  global (all four tags):    CasesDefined = 42  (HouseStyle=23, Repository=4, RequiresBuild=6, Universal=9)
  inventoried containers (2): Conformance.Tests.ps1, Help.Tests.ps1
```

Per-target 36 reproduces the figure pass 0045 recorded for this target, from a
clone rather than from that plan.

## 5. Tasks

- [x] **1. Branch, first commit pushed immediately**

  `git checkout -b pass-0046-runner-regex`, then `git rev-parse --show-toplevel`
  to confirm *which* repository the branch had been created in before anything
  was written to it — the check pass 0045 added after moving its shell around.
  It answered the harness root. The first commit `318b95a` was pushed with `-u`
  the moment it existed.

- [x] **2. The repair**

  `evals/conformance/Invoke-Conformance.ps1:122`, commit `a2d258a`:

  ```diff
  -                    '[\/](output|scratch|\.git|gallery|fixtures|node_modules)[\/]'
  +                    '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'
  ```

  One file, one line, `1 insertion(+), 1 deletion(-)`. Byte-identity across all
  four sites, counted rather than eyeballed:

  ```
  $ grep -rho "'\[[^']*node_modules[^']*\]'" evals/conformance/*.ps1 | sort | uniq -c
        4 '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'
  ```

  One distinct string, four occurrences.

- [x] **3. The tests that keep it fixed**

  Commit `f5821ab`. Three files, all under `evals/harness/` — outside the
  inventory scope precondition 3 established.

  | file | what it is |
  |---|---|
  | `evals/harness/ExclusionSites.ps1` | the extractor: `Get-ExclusionSite`, `Get-ExclusionSegment` |
  | `evals/harness/ExclusionPattern.Tests.ps1` | the two checks, 93 cases |
  | `evals/harness/Invoke-HarnessTests.ps1` | the named command that runs them |

  Three design decisions, each with a reason that cost something to learn:

  **The sites are discovered, not listed.** `Get-ExclusionSite` searches every
  `*.ps1` in the conformance directory for a single-quoted literal containing
  the alternation. A fifth copy added later is graded the day it appears. And
  the search is by *content*, not by character class — a search that could only
  find correct copies would report a drifted one as no copy at all, which is
  the false-negative shape `evals/HARNESS.md` keeps recording.

  **The extractor is dot-sourced from `BeforeDiscovery` and `BeforeAll` both.**
  Pester 6 does not carry a discovery-scope variable into an `It` body. The
  first draft set `$script:Sites` in `BeforeDiscovery` alone; discovery expanded
  93 cases correctly and every one of them then failed with *The variable
  '$script:Sites' cannot be retrieved because it has not been set*. The
  alternative to calling one extractor twice is writing two, which is the exact
  disease this directory exists to prevent.

  **`-ForEach` collections are hashtables.** Pester binds named variables from
  hashtable keys and only `$_` from anything else; with `[pscustomobject]` the
  case names rendered as the literal `<Site>` and `$Pattern` was unset.

  The polarity check runs against **every discovered site**, not only the
  runner's, so any of the four going wrong is caught. 6 segments × 4 sites × 3
  path shapes (leading-Windows, leading-POSIX, nested) = 72 exclusion cases; 4
  sites × 3 shapes = 12 substitution controls; 5 near-miss segment names = 5
  scope controls; 4 agreement cases. **93 total.**

  Green against the repaired tree, `harness-tests-green.txt`:

  ```
  Describe=Path exclusion copies agree Passed=4 Failed=0
  Describe=Path exclusion polarity Passed=89 Failed=0
  Passed=93 Failed=0 Ran=93 BrokenContainers=0
  VERDICT=GREEN
  ```

  **Red-capability, three probes, all recorded** 🔵

  | probe | what was broken | result | file |
  |---|---|---|---|
  | A | the pre-repair `[\/]` restored in a scratch copy | **exit 1**, 13 red: 12 polarity + 1 copies-agree | `probe-a-pre-repair.txt` |
  | B | one site changed to `[/\\]` — a *semantically identical* spelling | **exit 1**, 1 red: copies-agree alone, polarity green | `probe-b-one-site.txt` |
  | C | the separators dropped, leaving the bare alternation | **exit 1**, 5 red: 4 scope controls + copies-agree, all 18 exclusion cases for that site green | `probe-c-no-separators.txt` |

  Probe A is the one the prompt asked for and it goes red on both named checks.
  Probe B is what makes them two checks rather than one: an alteration that
  changes no behaviour still fails copies-agree, and fails nothing else. Probe C
  answers the question METHOD asks about every positive assertion — the scope
  controls are not inert, and they are what catches a pattern that matches too
  much.

  Each probe asserts that it actually changed the file before running anything,
  because a substitution that matched nothing leaves the target intact and the
  green that follows records a probe that "does not fire".

- [x] **4. Acceptance re-run — green** 🔵

  `accept-green.txt`, **exit 0**, same script, same planted clone:

  ```
    runner: [\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]
    suite:  [\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]

  Path                                     RunnerExcludes SuiteExcludes
  ----                                     -------------- -------------
  \output\PSGraphRender\PSGraphRender.psd1           True          True
  \scratch\Fake\Fake.psd1                            True          True

    candidate set under the RUNNER's pattern (2):
      src\PSGraphRender\PSGraphRender.psd1
      src\PSGraphRender\TemplateSets\cytoscape\vendor\vendor.psd1
    candidate set under the SUITE's pattern (2):
      src\PSGraphRender\PSGraphRender.psd1
      src\PSGraphRender\TemplateSets\cytoscape\vendor\vendor.psd1

  A. REFUSAL DIRECTION - does the runner resolve the target unaided?
    no refusal; the run completed

  C. DENOMINATOR - CasesDefined, per-target and global
    per-target (default tags): CasesDefined = 36  (HouseStyle=23, Repository=4, Universal=9)
    per-target (default tags): CasesRun     = 161   Passed=105 Failed=56 ScorePct=65.22
    global (all four tags):    CasesDefined = 42  (HouseStyle=23, Repository=4, RequiresBuild=6, Universal=9)
    inventoried containers (2): Conformance.Tests.ps1, Help.Tests.ps1
  ```

  Every figure identical to the red-first run: **CasesDefined 36 per-target, 42
  global, CasesRun 161, Passed 105, Failed 56, ScorePct 65.22.** The runner and
  the suite now agree on the candidate set. The denominator did not move and
  neither did the score, which is the point: this repair changes what the
  *runner* decides, and nothing about what the suite grades.

  See Deviation 1 on the word "derives" in the prompt's green criterion.

- [x] **5. Records**

  `plan.md` (this file), `verify.ps1`, LEDGER, journal. `verify.ps1` is
  described in section 9.

- [x] **6. Fast-forward `main`; no tag**

  Per decision 0009. SC3 recorded below — and see Deviation 2, because the form
  the prompt asked for is not true of this repository and has not been since
  pass 0041.

## 6. Acceptance test — green

Section 5 task 4. `accept-green.txt`, exit 0.

## 7. Command transcript

```powershell
# --- section 0: sync, five repositories
cd c:/__Code/__AI.Agent.Claude.PowerShellModuleBuilder
for r in AI.Agent.Claude.PowerShellModuleBuilder PSAzureDevOpsGraph PSGraphRender PSGraphRenderToHtml PSTerraformGraph; do
  (cd "$r" && git fetch --all --prune --tags -q && git status --porcelain && git rev-parse --short HEAD &&
   git rev-list --left-right --count HEAD...@{u})
done
# stranded-branch report
for r in ...; do (cd "$r" && for b in $(git branch -a --list '*pass-*' --format='%(refname:short)'); do
   git merge-base --is-ancestor "$b" main && echo "$b merged" || echo "$b STRANDED"; done); done

# --- preconditions
grep -n 'Last landed' LEDGER.md
ls -d plans/[0-9]* | sort | tail -3
ls journal/[0-9]*.md | sort | tail -3
grep -c '0046' LEDGER.md
cat -n evals/conformance/Invoke-Conformance.ps1      # lines 239-242, the inventory scope
grep -rn 'output|scratch' evals/conformance/*.ps1    # the four sites

# --- task 1
cd AI.Agent.Claude.PowerShellModuleBuilder
git checkout -b pass-0046-runner-regex
git rev-parse --show-toplevel

# --- section 2, red first
git add plans/0046-runner-regex/accept.ps1
git commit -m 'Pass 0046: acceptance test, committed before the repair'
git push -u origin pass-0046-runner-regex
pwsh -NoProfile -File ./plans/0046-runner-regex/accept.ps1     # EXIT 6, red
git add -A plans/0046-runner-regex/
git commit -m 'Pass 0046: RED-FIRST - both directions of backlog 62 observed'

# --- task 2, the repair
# Invoke-Conformance.ps1:122  '[\/]...[\/]'  ->  '[\\/]...[\\/]'
grep -rho "'\[[^']*node_modules[^']*\]'" evals/conformance/*.ps1 | sort | uniq -c   # 4 of one string
git diff --stat                                                 # 1 file, +1/-1
git add evals/conformance/Invoke-Conformance.ps1
git commit -m 'Pass 0046: the repair - one character class, matching the other three sites'

# --- task 3, the tests and their three probes
pwsh -NoProfile -File ./evals/harness/Invoke-HarnessTests.ps1 -Output Normal            # 93/93 GREEN, exit 0
# probe A: pre-repair spelling restored in scratch/probe-0046/pre-repair/conformance
pwsh -NoProfile -File ./evals/harness/Invoke-HarnessTests.ps1 -ConformanceDir ./scratch/probe-0046/pre-repair/conformance    # exit 1, 13 red
# probe B: one site -> [/\\] in scratch/probe-0046/one-site/conformance
pwsh -NoProfile -File ./evals/harness/Invoke-HarnessTests.ps1 -ConformanceDir ./scratch/probe-0046/one-site/conformance      # exit 1, 1 red
# probe C: separators dropped in scratch/probe-0046/no-separators/conformance
pwsh -NoProfile -File ./evals/harness/Invoke-HarnessTests.ps1 -ConformanceDir ./scratch/probe-0046/no-separators/conformance # exit 1, 5 red
git add evals/harness plans/0046-runner-regex
git commit -m 'Pass 0046: the tests that keep it fixed, outside the conformance inventory'

# --- task 4, acceptance green
pwsh -NoProfile -File ./plans/0046-runner-regex/accept.ps1     # EXIT 0, green

# --- task 5, verify
pwsh -NoProfile -File ./plans/0046-runner-regex/verify.ps1                # EXIT 0
pwsh -NoProfile -File ./plans/0046-runner-regex/verify.ps1 -FailCheck     # EXIT 0, every probe fired
git add -A evals/harness plans/0046-runner-regex
git commit -m 'Pass 0046: verify.ps1, GREEN acceptance, and per-Describe reporting'

# --- SC3, both forms
git diff --stat v1.2.0..HEAD    -- skills/ commands/ .claude-plugin/   # NOT empty: 1 file (backlog 56)
git diff --stat 13e1ea9..HEAD   -- skills/ commands/ .claude-plugin/   # empty: this pass touched none
```

## 8. Spot-checks

Each was run inside `verify.ps1` — which is where its red demo lives too, so
the check and its falsification cannot drift apart. Transcripts:
`verify-run.txt` and `verify-failcheck.txt`.

### SC1 — minimal repair diff 🔵

The repair commit is **found** from the history (`git log -1 --format=%H --
evals/conformance/Invoke-Conformance.ps1`) rather than named, so a rebase
cannot make this compare nothing.

```
  [ok  ] SC1: minimal repair diff - 1 file, +1/-1, the exclusion literal only
```

Red demo (P3): a synthetic diff touching a second file and an unrelated
verbosity line.

```
  [ok  ] P3: SC1 goes red on a diff touching a second file and an unrelated line -
         touches 2 file(s): …Invoke-Conformance.ps1, …Help.Tests.ps1;
         adds 2 line(s), expected 1; removes 2 line(s), expected 1;
         2 changed line(s) are not the exclusion literal
```

### SC2 — no inventory growth 🔵

Both figures **measured** at base and at head against the same planted clone,
neither pinned. The conformance directory as it stood at the pass base is
materialised under `scratch/` with `git show` per file, so the base runner
grades the same tree the head runner does.

```
  base: CasesDefined=36 CasesRun=161
  head: CasesDefined=36 CasesRun=161
  [ok  ] SC2: CasesDefined unchanged between base and head - base 36, head 36
  [ok  ] SC2: CasesRun unchanged between base and head - base 161, head 161
  discovered containers (2): Conformance.Tests.ps1, Help.Tests.ps1
  harness test files (1): ExclusionPattern.Tests.ps1
  [ok  ] SC2: no file this pass added is in the discovered set
  [ok  ] SC2: the discovered set is the two known containers
```

Red demos, and there are two because SC2 has two clauses:

```
  P4a: CasesDefined 36 -> 37
  [ok  ] P4a: SC2 goes red - CasesDefined moves when a tagged container enters the scope
  [ok  ] P4b probe actually grew the discovered set - 2 -> 3: Conformance.Tests.ps1,
         ExclusionPattern.Tests.ps1, Help.Tests.ps1
  [ok  ] P4b: SC2 goes red - a harness test file inside the scope is discovered
  [ok  ] P4b: the conformance runner then reports no score at all -
         refused: a container that did not run is a missing measurement
```

P4b is worth reading twice. Dropping *this pass's own test file* into
`evals/conformance/` does not merely move the denominator — the conformance
runner discovers it, its `BeforeDiscovery` looks for a conformance directory
beside itself and finds none, the container fails to load, and the runner
refuses to report any score. The `-Tag 'Harness'` backstop holds the denominator
still and does nothing whatever about that. **Placement is the guard; the tag is
only the belt**, and P4b is the measurement that says so.

### SC3 — plugin surface 🔵

See Deviation 2. What is asserted is that **this pass** changed nothing under
the three paths; what the prompt asked for is separately measured and reported.

```
  [ok  ] SC3: this pass changed nothing under skills/, commands/, .claude-plugin/ - 0 file(s):
  for the record, v1.2.0..HEAD over the same paths: 1 file(s) - skills/powershell-module-ux/SKILL.md
```

Red demo (P5): the `v1.2.0..HEAD` range is itself the known-bad input, and it is
non-empty for a reason this pass did not create.

```
  [ok  ] P5: SC3 goes red on a range that does touch skills/ -
         v1.2.0..HEAD: skills/powershell-module-ux/SKILL.md
```

## 9. Verify script

`plans/0046-runner-regex/verify.ps1`, committed beside this plan. Not
reproduced here: it is 588 lines, and a second copy in the same commit can
disagree with the first with nothing to make them agree again — hazard 6 in
`evals/HARNESS.md`, applied to the one artifact whose job is to disprove this
plan.

Six checks, five probes. It assumes a fresh clone of this repository plus a
clone of PSGraphRender from its remote, re-derives rather than reads, parses no
part of this plan, writes only under `scratch/` and deletes what it wrote.

1. Four or more copies of the exclusion regex, exactly one distinct string, and
   that string both excludes a Windows path under `scratch` and does not
   exclude a `src/`-side manifest. Both halves are needed: four copies of an
   equally wrong regex would satisfy the first alone.
2. The harness's own tests: exit 0, `Ran > 0`, `BrokenContainers=0`.
3. SC1.
4. SC2, both clauses.
5. SC3, amended form, with the prompt's form measured and reported beside it.
6. Acceptance re-derived both directions: against the planted clone the runner
   **refuses at base and resolves at head**, and the `scratch/` plant **is a
   candidate at base and is not at head**.

Two commits are derived rather than named, and they are different commits
answering different questions: the *repair* commit's parent for SC1 (which is
about one commit) and the *pass* base — the parent of the commit that
introduced this plan directory — for SC2 and SC3 (which are about the whole
pass). A merge-base against `origin/main` was rejected: it collapses to HEAD
once the pass lands, and would then compare nothing while reporting green.

Exits recorded 🔵:

| run | exit |
|---|---|
| `verify.ps1` | **0** — `VERIFY 0046: PASS - every check re-derived and agreed.` |
| `verify.ps1 -FailCheck` | **0** — every probe fired; a probe that did *not* fail would itself be a failure |

Inside `-FailCheck`, the two exits the prompt asked for by name, from the
pre-repair scratch copy:

```
  P1: Passed=80 Failed=13 Ran=93 BrokenContainers=0  exit=1
  [ok  ] P1: the harness tests go red on the pre-repair spelling - exit 1, VERDICT=RED
  [ok  ] P1: the POLARITY pair is among the reds - 12 polarity case(s) red
  [ok  ] P1: COPIES-AGREE is among the reds - 1 agreement case(s) red
```

## 10. Deviations

**1. "Derives `-ModuleName` cleanly" is not what a repaired runner does, and
the difference matters.** Section 2's green criterion says the runner "derives
`-ModuleName` cleanly against the same planted clone". It does not derive
anything, and it should not. With the regex repaired, exactly one candidate is
named for the target, so `$suiteCanDecide` is **true**, the entire `if (-not
$suiteCanDecide)` block — the `src/` rule and its refusal — never executes,
`$ModuleName` stays empty, and the *suite* resolves the target unaided, as it
does for the reference and every gallery target. That is the correct and better
outcome: the runner's `src/` rule is the last rule tried, and a repaired runner
not needing it is the whole point of its own comment block. The acceptance test
therefore asserts *"the runner does not refuse to resolve the planted clone"*
rather than *"derives"*. Recorded rather than quietly reinterpreted.

**2. SC3's premise is false, and has been since pass 0041.** The prompt states
`git diff v1.2.0..HEAD -- skills/ commands/ .claude-plugin/` "stays empty". It
is not empty and was not empty at the pass base: `skills/powershell-module-ux/SKILL.md`
differs by 63 insertions, introduced by commit `ff82bc1` in pass 0041. This is
not a discovery — it is **LEDGER backlog 56**, "The error standard in
`powershell-module-ux` is written and unreleased. STANDING", recorded there
deliberately so that the gap is written down rather than implied by a version
number that did not move.

Per METHOD's rule that conventions and state come from the repository and never
from recall, the repository wins and the disagreement is the finding. Asserting
the prompt's form would have failed for a reason that has nothing to do with
this pass. SC3 was amended to this pass's own claim — `git diff <pass base>..HEAD`
over the same three paths is empty — which is what the prompt was reaching for,
and the prompt's form is measured and printed beside it so nothing is hidden.
Pass 0031 met the same stale pin and did the same thing; LEDGER's own
"Precondition note for any pass written against the four-path pin" warns about
it. **This is the third consecutive prompt to carry a stale form of this pin**,
and the note should probably say so.

The prompt's conclusion is unaffected: no tag, because this pass changes no
installed file.

**3. The LEDGER's `cases-defined` pin is stale by one.** The Pins section reads
**"cases-defined: 41** (new at 0039…). Per tag: `HouseStyle` 22, `Universal` 9,
`RequiresBuild` 6, `Repository` 4." Measured this pass, at the base commit and
at head, and reproduced in 0045's own recorded figure of 36 for the default tag
set: it is **42**, with `HouseStyle` **23**. Pass 0044 added the `Workspace
composition` assertion — one `HouseStyle` `It` — and did not move the pin. New
backlog item, not repaired here: correcting a pin is a claim about a series
boundary and wants its own red-first iteration rather than a drive-by edit
inside a pass about a regex.

**4. Backlog 62 undercounts the sites.** The item names
`Conformance.Tests.ps1:61` and `:148` and says "these three regexes". There are
**four** copies: `Help.Tests.ps1:55` is a third correct one. The prompt already
anticipated this and asked for a dated append rather than a rewrite, which is
what LEDGER now carries.

**5. The refusal message names neither plant.** Recorded in section 4 rather
than here as well, but it belongs in this list too: the prompt's Red A
description — "refuses because `output/PSGraphRender/PSGraphRender.psd1`
counted as a second candidate" — is right about the cause and does not match
the text of the refusal, which names the two `src/` manifests. The chain has
two links and the plant is the first. A reader checking the prompt against the
transcript would otherwise think the wrong thing had been reproduced.

**6. The first acceptance run crashed in a section of my own making, at exit
99.** `accept.ps1`'s original section C measured the "global" denominator by
running the conformance runner *against the harness repository itself* with
`-ModuleName PSGraphRender`, which cannot resolve and throws. Both reds had
already been observed and recorded in that run and are unchanged by the fix;
the transcript is kept as `accept-red-first-attempt.txt` rather than discarded,
and the clean red run is `accept-red.txt`. The global figure is now taken by
asking the *runner* for all four tags against the same clone, rather than by
re-deriving the inventory in a second implementation that could disagree with
the first.

**7. Two probe-harness defects, both found by the probes not firing.** On the
first `-FailCheck` run, P1 and P2 reported "0 polarity case(s) red" and "0
agreement case(s) red" while the suite was plainly red — because the probe was
scraping Pester's own output, where a failure line carries the *test name* and
not the *block* it belongs to. That is precisely the false "does not fire" the
falsification protocol exists to detect, manufactured by its own bookkeeping,
and it failed toward the alarming answer, which is the one that gets
double-checked. The fix is in the product, not in the probe:
`Invoke-HarnessTests.ps1` now prints a machine-readable `Describe=<name>
Passed=n Failed=n` line per block, and the probe reads that. Separately, P4
merged two clauses into one directory and crashed when the copied harness test
file broke the conformance run outright; splitting it into P4a and P4b turned
the crash into the sharper measurement recorded under SC2.

**8. Backslash handling through the shell layer is unreliable, and one repair
attempt silently did nothing.** Three `sed -i` invocations against line 122
reported success and changed no bytes, because doubled backslashes were being
collapsed before `sed` saw them (`s|\\|B|g` came back as *unterminated `s'
command*, which is what a collapsed `\\|` parses as). The repair was made with
a precise file edit instead and the diff was read before committing. Worth
recording because a `sed` that silently matches nothing is the same failure
shape as a falsification probe that silently matches nothing — the command
exits 0 and the operator reads it as done.

**9. An untracked file appeared at the repository root, mid-pass, that this
pass did not create.** `PSGraphRender.code-workspace`, 99 bytes, timestamp
21:02, registering `.` and `../PSGraphRender` as folders. It is untracked, has
never been tracked on any branch, and nothing this pass ran writes a
`.code-workspace` — the only such write site in the repository is a frozen pass
0044 plan artifact that writes under its own scratch directory and was not run.
The tree *was* clean at preconditions, verified.

It has been left exactly where it is, and no pass commit contains it.
PLAN-PROTOCOL's rule for an unrelated dirty file prescribes committing it on
its own, but that rule is written for the state a pass *finds*, and this file
arrived while the pass was running — plausibly an editor or the operator
creating a workspace, possibly still in flight. Committing an in-flight file
into the record is a decision that is not the pass's to make, and the handoff
rule says a dirty tree is reported and never resolved. It is reported in the
LOCAL STATE table. **It needs the operator's ruling: keep it and commit it, or
delete it.**

**10. Two files were added beyond the two the prompt implies.** Task 3 asks for
"the tests". It landed as three files: the test container, the extractor it
shares between Pester's two scopes (Deviation-worthy only because it is a file
the prompt did not name, and the reason it exists is in task 3's evidence), and
`Invoke-HarnessTests.ps1`, a named command to run them. The runner is a
judgment call: a Pester file in a directory nothing runs is a test that never
runs, and there is no existing command that would have picked these up — which
is the whole reason they are safe to put there. It is also the surface backlog
61 will have to make discoverable, and it is deliberately not documented beyond
its own header, because 61 is out of scope by the prompt's own ⛔.

## 11. Cost

Wall-clock **21 minutes**, 20:49 (first commit) to 21:10, plus roughly ten
minutes of reading before the branch existed.

Runs the pass produced:

| what | count |
|---|---|
| `accept.ps1` runs | 3 (one crashed at 99, one red at 6, one green at 0) |
| harness test runs | 13 (1 green + 3 standalone probes + 9 inside verify) |
| full conformance suite runs, via the runner | 10 (base and head denominators, base and head derivations, the probes) |
| `verify.ps1` runs | 4 (2 plain, 2 `-FailCheck`) |
| PSGraphRender clones | 5, all under `scratch/`, all deleted |
| conformance cases executed | 161 per suite run, denominator 36, unchanged throughout |

No token count: the agent cannot measure one from inside the session, and a
number without an artifact behind it does not belong in a plan.
