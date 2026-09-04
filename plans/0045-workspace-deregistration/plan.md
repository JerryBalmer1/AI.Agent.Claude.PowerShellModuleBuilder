# Pass 0045 — PSGraphRender workspace deregistration

## 1. Prompt

```
# PASS 0045 — PSGraphRender workspace deregistration (backlog 60)

## Signals

🔴 hard stop (report, never resolve) · 🟠 operator action · 🟢 agent task · 🔵 evidence gate · ⛔ never, whole pass. Per PLAN-PROTOCOL as amended by 0044.

**Tier:** Repository. One tracked configuration file changes; no module source, no build.

**Target repositories:** `PSGraphRender` (writable — this one file only) and `AI.Agent.Claude.PowerShellModuleBuilder` (plan record, LEDGER, journal only). ⛔ Everything else read-only; ⛔ `scratch/PSModuleGraph` untouched.

**Purpose.** Pass 0044's workspace-composition assertion found one real red on its first run: `PSGraphRender.code-workspace` has registered `../PSModuleGraph` since that repository's initial commit — currently inert because 0043 relocated the clone, which is exactly the condition under which it goes unnoticed. This pass deletes the entry and closes backlog 60. Backlog 61 (the suite cannot discover against the harness) is ⛔ out of scope — it changes cases-run and gets its own red-first pass.

## 0. Sync

🟢 Parallel fetch per workspace repo (`--all --tags --prune`), ff-only updates. 🔵 Report. 🔴 Divergence or dirt.

## 1. Preconditions

1. **Frontier, three sources:** 🔴 any source shows 0045 assigned. 🔴 Any disagreement about the frontier — all three read **0044** (harness `main` `140aea8`) when this prompt was authored. 🔵 Record the three values.
2. 🔴 Harness or PSGraphRender not on `main`, not clean, or not ff-synced. Expected HEADs at authoring: harness `140aea8`, PSGraphRender `c7f382f` — 🔴 if PSGraphRender's `main` has moved, stop and report; the edit below was specified against that tree.
3. 🔴 `PSGraphRender.code-workspace` at HEAD does not contain the `../PSModuleGraph` folder entry (nothing to do → report, no work).
4. **Sequencing gate:** 🔴 any task-3 work before the acceptance red of section 2 is observed.

## 2. Acceptance test — the 0044 assertion itself, observed red first

🟢 The instrument already exists and was falsified five ways in 0044: the workspace-composition assertion in the harness conformance suite at `140aea8`. Derive the invocation from `evals/conformance/` as it stands — do not re-derive the assertion logic. Run it against the PSGraphRender working tree. 🔵 Record the **red** result verbatim before any edit. (This is a genuine observed red, not a manufactured one — the violation predates the pass.)

## 3. Tasks (serial; the pass is one edit and its records)

1. 🟢 Branch `pass-0045-workspace-deregistration` in PSGraphRender; first commit pushed immediately.
2. 🟢 Edit `PSGraphRender.code-workspace`: delete the `{ "path": "../PSModuleGraph" }` object from `folders`, leaving `{ "path": "." }` and the `settings` block byte-identical. Valid JSONC after the edit. This edit is the commit's only change.
3. 🟢 Re-run the acceptance instrument. 🔵 Record the **green** result verbatim.
4. 🟢 `docs/HANDOFF.md` state section: one line under a pass-0045 heading — the entry removed, backlog 60 closed, nothing else touched. Its own commit.
5. 🟢 Harness: `plans/0045-workspace-deregistration/plan.md` (prompt verbatim, evidence, Deviations), `plans/0045-workspace-deregistration/verify.ps1` (decision 0004 path; `-FailCheck` re-runs the assertion against a scratch copy of the workspace file with the entry restored — the polarity pair, both exits recorded 🔵), LEDGER (counter to 0045; backlog 60 marked resolved-by-0045 in place, number consumed not reused), journal (six fields, Capability never benefit).
6. 🟢 Fast-forward PSGraphRender `main` per decision 0010 — **no tag**: a workspace-file edit is not module semver material (0038 precedent: docs/config sync earns no minor). Harness `main` ff per 0009.

## 4. Spot-checks (🔵 each; red-capability stated per METHOD as amended)

- **SC1 — minimal diff:** `git diff` of the workspace commit touches exactly one file and removes exactly one folder object. Red demo: scratch diff that also edits `settings`.
- **SC2 — suite health on the target:** the conformance suite still discovers and runs against PSGraphRender after the edit, and the workspace assertion is the only score line that moved. Red demo: the 0044 falsification fixture.

## 5. Constraints

⛔ No other file in PSGraphRender changes. ⛔ No tag. ⛔ `scratch/PSModuleGraph`, the fixtures, and the other three ecosystem repos untouched. ⛔ No force/reset/rebase anywhere. PAT rules stand (nothing here needs it — 🔴 if anything in this pass tries to reach Azure DevOps).

## 6. Local handoff — the last act

🟢 Every workspace repo: checkout `main`, `pull --ff-only`, `fetch --tags --prune`, status clean; 🔵 LOCAL STATE table. Divergence or dirt reported, never resolved.
```

## 2. Preconditions

### Sync — the first act

`git fetch --all --tags --prune` in all five workspace repositories, in parallel.
Every one was already level with its upstream, so no fast-forward was needed and
none was taken.

| Repository | Branch | HEAD | Upstream | ahead/behind | Dirt |
|---|---|---|---|---|---|
| AI.Agent.Claude.PowerShellModuleBuilder | `main` | `140aea8` | `140aea8` | `0 0` | clean |
| PSAzureDevOpsGraph | `main` | `5551a20` | `5551a20` | `0 0` | clean |
| PSGraphRender | `main` | `c7f382f` | `c7f382f` | `0 0` | clean |
| PSGraphRenderToHtml | `main` | `55deb28` | `55deb28` | `0 0` | clean |
| PSTerraformGraph | `main` | `74d85ac` | `74d85ac` | `0 0` | clean |

🔴 Divergence — none. 🔴 Dirt — none.

### 1. Frontier, three sources 🔵

| Source | Command | Value |
|---|---|---|
| LEDGER `Last landed:` | `sed -n '1,40p' LEDGER.md` | **0044** |
| Highest `plans/NNNN-*` | `ls -1 plans \| tail -8` | **0044**-method-corrections |
| Highest `journal/NNNN-*.md` | `ls -1 journal \| tail -8` | **0044**-method-corrections |

All three agree. 🔴 Disagreement — none.

**0045 is free.** `ls -d plans/0045-*` and `ls journal/0045-*` both report no such
file; `grep -n "0045" LEDGER.md` returns nothing; and
`git branch -a --list '*0045*'` is empty in all five repositories. The branch
check is included because a stranded pass branch is the one form of "already
taken" that leaves nothing in a working tree to notice.

### 2. HEADs and cleanliness

Both writable repositories are on `main`, clean, and level with their upstream.
Both HEADs match the values the prompt recorded at authoring: harness `140aea8`,
PSGraphRender `c7f382f`. PSGraphRender's `main` has not moved, so the edit
specified against that tree is the edit that applies.

### 3. The entry is present

`git -C PSGraphRender show HEAD:PSGraphRender.code-workspace` — 99 bytes, blob
`b2ac63d`, tabs and LF line endings, no final newline:

```jsonc
{
	"folders": [
		{
			"path": "."
		},
		{
			"path": "../PSModuleGraph"
		}
	],
	"settings": {}
}
```

The `../PSModuleGraph` folder object is present. 🔴 "nothing to do" does not fire.

### 4. Sequencing gate

No task-3 work ran before the acceptance red of section 4 was observed. The
command transcript in section 8 is in execution order and shows the red run
preceding `git checkout -b`. The independent record of the same fact is the
timestamp pair: the red baseline's `result.json` carries
`RunAt = 2026-09-03T20:07:08-07:00`, and the workspace commit `3973644` is dated
`2026-09-03 20:08:19 -0700`.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| git | 2.41.0.windows.1 |
| OS | Microsoft Windows NT 10.0.26200.0 (Windows 11 Home) |
| Agent | Claude Code, Opus 5 (1M context) |
| Harness branch / HEAD at start | `main` / `140aea8` |
| PSGraphRender branch / HEAD at start | `main` / `c7f382f` |

## 4. Acceptance test — red first

### Deriving the invocation

The prompt asks that the invocation be derived from `evals/conformance/` as it
stands, and that the assertion logic not be re-derived. Two facts from that
directory decide it:

- `Conformance.Tests.ps1:6` and `:28` — the target is passed in
  `$env:CONFORMANCE_TARGET`; `:70` reads `$env:CONFORMANCE_MODULE_NAME`.
- `Conformance.Tests.ps1:476` — the block is
  `Describe 'Workspace composition' -Tag 'HouseStyle'`, and `HouseStyle` is in
  `Invoke-Conformance.ps1`'s default tag set.

Two forms were run, and both are recorded because they answer different
questions. **Form A** runs the assertion alone, filtered with
`Filter.FullName = '*Workspace composition*'` — filtered by name rather than by
tag, so that a failure elsewhere in the suite cannot be mistaken for this one.
This is the isolation `plans/0044-method-corrections/Test-WorkspaceFalsification.ps1`
uses, and it is the acceptance instrument. **Form B** runs the whole suite
through `Invoke-Conformance.ps1`, which is what SC2 needs a baseline from.

Form B required `-ModuleName PSGraphRender`. Without it the runner refuses:

```
Cannot derive -ModuleName: 2 manifests under
'…\PSGraphRender\src', none preferred. Candidates:
src\PSGraphRender\PSGraphRender.psd1; src\PSGraphRender\TemplateSets\cytoscape\vendor\vendor.psd1.
Pass -ModuleName to choose.
```

Passing `-ModuleName` is the answer the runner's own rule 11 prescribes, so the
refusal was answered rather than worked around. **Why it had to be asked at all
is a defect in the runner, and it is Deviation 2** — not a property of this
target and not a consequence of anything this pass did.

### Form A — the assertion alone, RED 🔵

```
Describing Workspace composition
  [-] does not register PSModuleGraph as a folder: PSGraphRender.code-workspace 179ms
   Expected $null or empty, because a tracked workspace file that registers PSModuleGraph
   puts the read-only reference into the working set of everyone who clones this repository,
   where it is a writable working directory whose own instructions load into the session;
   found ../PSModuleGraph, but got '../PSModuleGraph'.
   at $registered | Should -BeNullOrEmpty -Because (, …\Conformance.Tests.ps1:516
Tests completed in 1.2s
Tests Passed: 0, Failed: 1, Skipped: 0, Inconclusive: 0, NotRun: 48

Passed=0 Failed=1 Total=49
BrokenContainers=0
VERDICT=RED
```

`BrokenContainers=0` is load-bearing, and it is the check 0044's driver added
after its own first run misreported one. A failed container is discovery blowing
up; a driver that cannot tell "the assertion failed" from "the suite never ran"
can report either colour meaninglessly. Zero broken containers means this red is
the assertion firing.

### Form B — full suite baseline, RED 🔵

```
Total=167 Passed=104 Failed=57 Skipped=0 NotRun=6
CasesRun=161 CasesDefined=36 ScorePct=64.6
```

The suite is red on this target for three further reasons, all pre-existing and
all out of scope: an exported command no test calls, an unpinned build
dependency, and a default-task mismatch.

Neither result JSON is committed beside this plan. Both were written to a session
scratch directory outside every repository, and `verify.ps1` re-measures both
numbers from a fresh clone rather than reading either file — which is the
stronger claim, and the one PLAN-PROTOCOL section 9 asks for.

## 5. Tasks

- [x] **1. Branch in PSGraphRender, first commit pushed immediately**

  `git checkout -b pass-0045-workspace-deregistration`, then
  `git rev-parse --show-toplevel` to confirm *which* repository the branch had
  been created in before anything was written to it. The shell's working
  directory had been moved several times by then, and a branch is cheap to
  create in the wrong place and expensive to notice there. The first commit
  `3973644` was pushed with `-u` the moment it existed.

- [x] **2. Delete the folder object**

  `PSGraphRender.code-workspace`, 99 → 60 bytes, blob `b2ac63d` → `876a149`.
  Written with `printf` rather than through an editor so that the tabs, the LF
  line endings and the absent final newline survive exactly; `cat -A` confirms
  all three before and after.

  ```diff
  @@ -2,9 +2,6 @@
   	"folders": [
   		{
   			"path": "."
  -		},
  -		{
  -			"path": "../PSModuleGraph"
   		}
   	],
   	"settings": {}
  ```

  Three lines removed, none added. The removed comma is the array separator that
  belonged to the removed element, not part of the surviving object — `{ "path":
  "." }` and the `settings` block are byte-identical, and neither appears in any
  `+`/`-` line of the diff. Leaving the comma would have produced a trailing
  comma: legal JSONC, but a `folders` array the next reader has to think about.

  Valid after the edit, checked by parsing rather than by eye:

  ```
  parses: OK
  folders count: 1
  paths: .
  settings present: True
  settings props: 0
  ```

  This edit is the commit's only change — SC1, section 7.

- [x] **3. Re-run the acceptance instrument — GREEN 🔵**

  ```
  Describing Workspace composition
    [+] does not register PSModuleGraph as a folder: PSGraphRender.code-workspace 104ms
  Tests completed in 871ms
  Tests Passed: 1, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 48

  Passed=1 Failed=0 Total=49
  BrokenContainers=0
  VERDICT=GREEN
  ```

  Same script, same filter, same target path. Only the file under test changed
  between the two runs.

- [x] **4. `docs/HANDOFF.md`, one line under a pass-0045 heading**

  Commit `cd4857d` in PSGraphRender, its own commit, six lines added and none
  removed — a `### Pass 0045` heading, a blank line, and one sentence wrapped
  over three lines. Inserted at the end of the state section, immediately before
  `## What this is`.

  The `## State, as of pass 0043` heading was deliberately **not** re-dated. The
  prompt says nothing else is touched, and re-dating that heading would make a
  claim about 0043's content that this pass did not re-check.

- [x] **5. Harness records**

  `plans/0045-workspace-deregistration/plan.md` (this file),
  `plans/0045-workspace-deregistration/verify.ps1` (sections 9 and 10),
  `LEDGER.md` (counter to 0045, backlog 60 resolved in place, 62 added),
  `journal/0045-workspace-deregistration.md`.

- [x] **6. Fast-forward both mains, no tag**

  Section 11. No tag was taken in either repository, and none was pushed.

## 6. Acceptance test — green

Section 5, task 3: same invocation, `VERDICT=GREEN`, `BrokenContainers=0`.
Re-derived independently from a fresh clone by `verify.ps1` check 2.

## 7. Spot-checks

Each is stated with what makes it capable of red, per METHOD as amended by 0044:
a named check counts only after its polarity has been shown against a known-bad
and a known-good input.

### SC1 — minimal diff 🔵

**Green — the real commit `3973644`:**

```
files touched:  PSGraphRender.code-workspace     (count=1)
numstat:        0	3	PSGraphRender.code-workspace
+/- lines matching 'settings' or '"path": "."':  none
removed '"path":' lines:  1
```

One file, zero additions, exactly one folder object removed, and neither the
surviving entry nor the `settings` block appears in any changed line.

**Red demo 🔵** — a scratch git repository outside every workspace repository,
whose second commit removes the folder object *and* edits `settings` *and*
touches a second file:

```
files touched:  Demo.code-workspace, other.txt   (count=2)
settings changed:
  -	"settings": {}
  +	"settings": {
  +		"files.autoSave": "off"
```

Both discriminating clauses fire on it: the file count is 2, and the `settings`
block appears among the changed lines. SC1 can go red. The same check, as a
function over the same two inputs, is re-run by `verify.ps1 -FailCheck`.

### SC2 — suite health on the target 🔵

The full suite was run again through `Invoke-Conformance.ps1` after the edit with
the same arguments as the red baseline, and the per-assertion score lines of the
two `result.json` files were compared with `Compare-Object`.

| | red | green |
|---|---|---|
| Total / CasesRun / CasesDefined | 167 / 161 / 36 | **167 / 161 / 36** |
| Passed / Failed | 104 / 57 | 105 / 56 |
| ScorePct | 64.6 | 65.22 |

`CasesRun` unchanged is the claim that matters: the suite still *discovers*
against this target and runs the same cases. The complete score-line diff, all of
it:

```
=>  Workspace composition.does not register PSModuleGraph as a folder: <_.Rel>|Ran=1|Passed=1|Failed=0
<=  Workspace composition.does not register PSModuleGraph as a folder: <_.Rel>|Ran=1|Passed=0|Failed=1
```

One assertion moved. The other 33 score lines are identical. Compared line by
line rather than by totals, because two offsetting changes would satisfy a total.

**Red demo 🔵** — `plans/0044-method-corrections/Test-WorkspaceFalsification.ps1`,
run from this pass against fixtures built in a session scratch directory:

```
FALSIFICATION 0044 - Workspace composition

  OK   18a  expected RED   observed RED        (passed 0, failed 1) - break: registers ../PSModuleGraph
  OK   18b  expected GREEN observed GREEN      (passed 1, failed 0) - restore: folder removed
  OK   18c  expected GREEN observed GREEN      (passed 1, failed 0) - CONTROL scope: named in a comment and a setting, not registered
  OK   18d  expected GREEN observed GREEN      (passed 1, failed 0) - CONTROL segment: registers ../PSModuleGraphTools
  OK   18e  expected ZERO CASES observed ZERO CASES (passed 0, failed 0) - CONTROL absence: no workspace file at all - inapplicable, not a pass

FALSIFICATION 0044: all 5 rows correct - the assertion fires on its break, and both controls hold.
DRIVER EXIT=0
```

Row 18a is the point. The instrument that just went green on the real repository
still goes red on a file that registers the reference, so the green is a fact
about the file rather than about an assertion that has lost the ability to fail.
`verify.ps1 -FailCheck` makes the same demonstration against a scratch copy of
the real repository rather than a fixture.

## 8. Command transcript

```bash
# --- sync
for r in AI.Agent.Claude.PowerShellModuleBuilder PSAzureDevOpsGraph PSGraphRender \
         PSGraphRenderToHtml PSTerraformGraph; do
  ( cd "$r" && git fetch --all --tags --prune ) &
done; wait
for r in ...; do git -C "$r" rev-parse --abbrev-ref HEAD; git -C "$r" rev-parse --short HEAD; \
                 git -C "$r" rev-list --left-right --count HEAD...@{u}; git -C "$r" status --porcelain; done

# --- preconditions
sed -n '1,40p' LEDGER.md                                       # Last landed: 0044
ls -1 plans | tail -8; ls -1 journal | tail -8                 # highest 0044, both
ls -d plans/0045-*; ls journal/0045-*; grep -n "0045" LEDGER.md    # all empty
git branch -a --list '*0045*'                                  # empty, all five repos
git -C ../PSGraphRender show HEAD:PSGraphRender.code-workspace
git -C ../PSGraphRender hash-object PSGraphRender.code-workspace   # b2ac63d…, 99 bytes

# --- acceptance, RED, before any edit
pwsh -c '$env:CONFORMANCE_TARGET="…/PSGraphRender"; $env:CONFORMANCE_MODULE_NAME="PSGraphRender";
  $cfg = New-PesterConfiguration
  $cfg.Run.Path = "…/evals/conformance/Conformance.Tests.ps1"
  $cfg.Run.PassThru = $true
  $cfg.Filter.FullName = "*Workspace composition*"
  $cfg.Output.Verbosity = "Detailed"
  $r = Invoke-Pester -Configuration $cfg'                      # Failed=1, VERDICT=RED
./evals/conformance/Invoke-Conformance.ps1 -Path ../PSGraphRender \
  -ModuleName PSGraphRender -ResultPath <scratch>/red-full.json    # ScorePct 64.6

# --- tasks, in PSGraphRender
git checkout -b pass-0045-workspace-deregistration
git rev-parse --show-toplevel                                  # confirms which repo
printf '{\n\t"folders": [\n\t\t{\n\t\t\t"path": "."\n\t\t}\n\t],\n\t"settings": {}\n}' \
  > PSGraphRender.code-workspace
cat -A PSGraphRender.code-workspace; wc -c PSGraphRender.code-workspace   # tabs, LF, 60 bytes
git add PSGraphRender.code-workspace && git commit -F -        # 3973644
git push -u origin pass-0045-workspace-deregistration

# --- acceptance, GREEN
pwsh -c '…the same Pester invocation…'                         # Passed=1, VERDICT=GREEN
./evals/conformance/Invoke-Conformance.ps1 -Path ../PSGraphRender \
  -ModuleName PSGraphRender -ResultPath <scratch>/green-full.json   # ScorePct 65.22
Compare-Object (red score lines) (green score lines)           # exactly 2 lines, both the same assertion

# --- spot-check red demos
git init <scratch>/sc1/demo; …two commits…; git diff --name-only HEAD~1 HEAD   # 2 files
./plans/0044-method-corrections/Test-WorkspaceFalsification.ps1 \
  -ScratchRoot <scratch>/scratch/falsify-0045                  # exit 0, 5 rows

# --- HANDOFF, its own commit
git add docs/HANDOFF.md && git commit -F -                     # cd4857d
git push origin pass-0045-workspace-deregistration

# --- harness records
git checkout -b pass-0045-workspace-deregistration
# plans/0045-workspace-deregistration/{plan.md,verify.ps1}, LEDGER.md,
# journal/0045-workspace-deregistration.md

# --- verify, both polarities
./plans/0045-workspace-deregistration/verify.ps1               # exit 0
./plans/0045-workspace-deregistration/verify.ps1 -FailCheck    # exit 0

# --- fast-forward both mains, no tag
git -C ../PSGraphRender checkout main
git -C ../PSGraphRender merge --ff-only pass-0045-workspace-deregistration
git -C ../PSGraphRender push origin main
git checkout main && git merge --ff-only pass-0045-workspace-deregistration && git push origin main

# --- local handoff
for r in ...; do git -C "$r" checkout main; git -C "$r" pull --ff-only; \
                 git -C "$r" fetch --tags --prune; git -C "$r" status --porcelain; done
```

## 9. Verify script

`plans/0045-workspace-deregistration/verify.ps1`, at the decision-0004 path,
committed beside this plan and **not** reproduced in a fenced block here.
PLAN-PROTOCOL section 9 permits a copy only when no reader would diff the two,
and this one is long enough that a reader would — and a second copy of an
executable in the same commit is hazard 6 applied to the one artifact whose job
is to disprove the plan.

Five checks, each re-derived from a **fresh clone of PSGraphRender taken from its
remote**, never from a tree on this machine and never by parsing this plan:

1. The workspace file at the pass branch registers no PSModuleGraph folder, read
   semantically — JSONC stripped, `folders[].path` split on separators — by the
   same rule the suite's assertion uses. A text match would fire on any file that
   *documents* the rule, this plan included.
2. The acceptance instrument: the harness's `Workspace composition` assertion,
   run against the clone, green, with broken containers counted separately so a
   discovery failure can never surface as a green, and case count asserted so
   ZERO CASES cannot surface as one either.
3. SC1 — the workspace commit touches one file, adds no lines, removes exactly
   one folder object, and changes no line mentioning `settings`.
4. SC2 — `CasesRun`, `CasesDefined`, the failure count and every per-assertion
   score line are **measured twice**, at the base commit and at the branch head,
   and compared. Nothing is pinned. A count measured in one tree and asserted in
   another reports the tree's shape rather than the pass's claim, and this target
   has an untracked `output/` directory locally that a fresh clone does not — the
   exact condition that makes a pinned count lie. Both runs happen to give 161,
   which is a result of the check rather than an input to it.
5. The entry was present at the base commit and absent at the branch head — an
   amendment, not an invention. The base is re-derived with `merge-base` rather
   than named, so a re-base cannot silently make this compare nothing to nothing.

Only PSGraphRender is cloned. The harness is the *instrument* — it supplies the
suite — and is used where the script sits, because a script cannot verify an
instrument by fetching a second copy of itself.

`-FailCheck` is the polarity pair the prompt asked for. It copies the whole clone
to scratch, **restores** the `../PSModuleGraph` entry in the copy, and re-runs
both check 1 and the acceptance assertion against it; each must go red. The copy
is a whole repository rather than a lone file because the assertion discovers its
subject with `git ls-files`, and a bare file would never reach the assertion at
all — the false ZERO CASES 0044's first falsification run reported. The SC1 probe
feeds the same function a diff that edits `settings` and touches a second file.
Every probe first asserts that it actually changed its input, so a substitution
that matched nothing cannot be recorded as a passing check.

The script writes only under `scratch/`, refuses any path without a `scratch`
segment, removes what it wrote in a `finally`, and exits 99 rather than 0 if it
crashes — the false green 0044's own verifier committed against itself.

## 10. Verify results 🔵

Both polarities, run against the pass branch at `cd4857d`:

| Invocation | Exit | Result |
|---|---|---|
| `./plans/0045-workspace-deregistration/verify.ps1` | **0** | `VERIFY 0045: PASS — every check re-derived and agreed.` 11 assertions. |
| `./plans/0045-workspace-deregistration/verify.ps1 -FailCheck` | **0** | Same 11, plus 4 probe assertions. Every probe landed. |

```
  verifying: pass-0045-workspace-deregistration @ cd4857d

1. The workspace file does not register PSModuleGraph
  [ok  ] workspace file registers no PSModuleGraph folder - folders: .

2. Acceptance: the harness assertion, against the clone
  [ok  ] Workspace composition is GREEN - GREEN - passed 1, failed 0
  [ok  ] the assertion ran at all (not ZERO CASES, not a discovery failure) - cases: 1

3. SC1 - the workspace commit is one file and one folder object
  [ok  ] workspace commit resolved - 3973644 Deregister PSModuleGraph from the workspace file
  [ok  ] SC1: one file, no additions, one folder object removed, settings untouched - 1 file, +0/-3, one folder object removed, settings untouched

4. SC2 - the suite still discovers against the target
  [ok  ] CasesRun is unchanged by the edit - base 161, head 161
  [ok  ] CasesDefined is unchanged by the edit - base 36, head 36
  [ok  ] exactly one failure fewer at head than at base - base failed 57, head failed 56
  [ok  ] the workspace assertion is red at base - ran 1, passed 0, failed 1
  [ok  ] the workspace assertion is green at head - ran 1, passed 1, failed 0
  [ok  ] no other assertion score line moved - 0 other line(s) differ

5. An amendment: the entry was present at the base commit
  [ok  ] the entry WAS registered at base c7f382f - registers ../PSModuleGraph

-FailCheck: the deliberate-failure probes
  [ok  ] probe actually restored the entry - a substitution that matched nothing would be recorded as a passing check
  [ok  ] probe: check 1 goes red on the restored entry - registers ../PSModuleGraph
  [ok  ] probe: the acceptance assertion goes RED on the restored entry - RED - passed 0, failed 1
  [ok  ] probe: SC1 goes red on a diff that edits settings and a second file - touches 2 files: Demo.code-workspace, other.txt; adds 3 line(s); changes 2 line(s) mentioning settings

VERIFY 0045: PASS - every check re-derived and agreed.
```

Both invocations exit 0 by design, and the second is not a red run: `-FailCheck`
asserts that the probes go red, so a probe that *failed* to fail would be the
thing that took the exit code non-zero.

The fresh clone reports `CasesRun = 161` at both commits — the same figure the
local working tree gave — which retires a worry rather than confirming a
prediction: the clone has no `output/` directory and the local tree does, and the
count is insensitive to it.

## 11. Deviations

1. **The prompt was accurate in every checkable particular, which is worth
   recording because the last two passes' were not.** Both expected HEADs
   matched, the frontier read 0044 from all three sources, the entry was where
   the prompt said it was and had the shape the prompt described, and no hard
   stop fired. Nothing in the prompt had to be reinterpreted to run it.

2. **`Invoke-Conformance.ps1`'s path-exclusion regex is inert on Windows.
   Discovered, not asked about. LEDGER backlog 62.**

   `Invoke-Conformance.ps1:122` excludes `output`, `scratch`, `.git`, `gallery`,
   `fixtures` and `node_modules` from manifest discovery with

   ```
   '[\/](output|scratch|\.git|gallery|fixtures|node_modules)[\/]'
   ```

   while `Conformance.Tests.ps1:61` and `:148` do the same job with `[\\/]`.
   Inside a character class `\/` is an escaped forward slash and nothing else, so
   the runner's version matches forward slashes only, and every path it tests is
   a Windows path built with `Substring` on a `FullName`. Demonstrated rather
   than asserted:

   ```
   path: \output\PSGraphRender\PSGraphRender.psd1
     [\/]  (Invoke-Conformance.ps1:122)  excludes it?  False
     [\\/] (Conformance.Tests.ps1:61)    excludes it?  True
   /output/PSGraphRender/PSGraphRender.psd1 with [\/] excludes it?  True
   ```

   The visible consequence is the refusal quoted in section 4: the runner counted
   `output/PSGraphRender/PSGraphRender.psd1` as a second candidate named for the
   target, decided it could not choose, and demanded `-ModuleName` for a
   repository whose layout the suite itself resolves without help. The failure
   mode is a refusal rather than a wrong answer, which is the good direction —
   but only because `output/` happened to hold a manifest named for the target.
   The same defect would let a manifest under `scratch/` or `gallery/` into the
   candidate set, where it would be a wrong answer rather than a refusal, and
   grading the wrong module silently is the thing F-8's comment says is worse
   than grading nothing.

   Not repaired here: this pass may write to the harness for its records only,
   and the fix belongs with a red-first test of the runner's discovery. Logged
   as backlog 62.

3. **Two acceptance forms, where the prompt implies one.** The prompt asks for
   the assertion run against the working tree, red then green. That is form A,
   and it is the acceptance test. Form B — the whole suite — was run at both
   colours as well, because SC2 asks whether the suite still discovers and
   whether any *other* score line moved, and neither question can be answered
   from a name-filtered run of one assertion. Both are recorded so that a reader
   can see which numbers came from which.

4. **`docs/HANDOFF.md`: a new sub-heading, not a re-dated one.** The prompt asks
   for "one line under a pass-0045 heading". The file's state section is titled
   `## State, as of pass 0043`. Re-dating that heading would have implied this
   pass re-checked what it says, which it did not; a `### Pass 0045` sub-heading
   was added at the end of the section instead. The one line is one sentence,
   wrapped over three lines at the file's prevailing width.

5. **The array separator went with the element.** The prompt requires
   `{ "path": "." }` and `settings` to stay byte-identical, and both did. The
   comma after that object also disappeared, because it is the separator between
   two array elements and one of them is gone; it is not part of either object.
   Recorded because a reader comparing the diff against the prompt's wording will
   see a fourth changed line and should not have to wonder.

6. **Nothing in this pass reached Azure DevOps**, and nothing needed a PAT. The
   only network operations were `git fetch`/`push` against `github.com` and the
   `git clone` inside `verify.ps1`.

## 12. Cost

Wall-clock, measured between two artifacts rather than estimated: the red
baseline's `result.json` carries `RunAt = 2026-09-03T20:07:08-07:00`, and the
harness's own records commit closes the pass. **About 25 minutes.** The
PSGraphRender commits bracket the edit itself at 20:08:19 (`3973644`) and
20:10:14 (`cd4857d`) — under two minutes of the total; the rest is evidence.

Runs the pass produced:

| | Count |
|---|---|
| Full conformance-suite runs (`Invoke-Conformance.ps1`) | 6 — 2 on the working tree, 4 inside the two `verify.ps1` invocations |
| Name-filtered assertion runs | 5 — red, green, one per `verify.ps1` invocation, one `-FailCheck` probe |
| Falsification-driver runs | 1, of 5 rows |
| `verify.ps1` invocations | 2, both exit 0 |
| Builds | 0 — no module source changed, and the tier calls for none |

No token count: the agent cannot measure one from inside the session, and a
number without an artifact behind it does not belong in a plan.
