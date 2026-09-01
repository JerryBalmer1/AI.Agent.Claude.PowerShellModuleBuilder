# Pass 0025 — Findings to skills, oracle repair, tf-002, stable denominator, LEDGER

Tier: **full**. Changes executable behaviour in four places — the producer, the
conformance runner, two new harness scripts, and a new PreTag suite.

> **This plan replaces the one committed at `116d50c`.** That commit recorded a
> correct stop: the prompt arrived truncated mid-task-2 with every item after it
> missing, and PLAN-PROTOCOL's file-supply rule says a pass stops loudly rather
> than inferring. The full prompt then arrived and the pass resumed from its
> already-red acceptance test.

## 1. Prompt

The prompt as received is reproduced in the pass record kept with the operator's
conversation. Its plan, verbatim in structure, is the ten-task list executed
below; the acceptance test it specified is committed unmodified at
`plans/0025-findings-batch/accept.Tests.ps1` and is quoted in §4.

## 2. Preconditions

| Precondition | Command | Result |
| --- | --- | --- |
| Six repositories synced, no divergence | `git fetch --all --prune --tags` in parallel across 6 | clean; no divergence, no dirty tree |
| Harness `main` = `fc27c53…` | `git rev-parse main origin/main fc27c53…` | all three identical |
| PSTerraformGraph `main` = `05fb60d…` | `git rev-parse main origin/main 05fb60d…` | all three identical |
| `$env:AZDO_PAT` | presence test only, never printed | **set** |
| PSTerraformGraph tag `v0.2.0` absent | `git tag -l` | only `v0.1.0` |
| `LEDGER.md` absent at harness root | `ls LEDGER.md` | absent |
| Fixture repos reachable at pass 0023's SHAs | `evals/tf/Test-TfFixtureReadBack.ps1` | **BYTE-IDENTICAL**, 40 files, 3 repos, at `0af6ee3…` / `24f27be…` / `187ff22…` |

**One precondition did not hold, and it was expected to.**
`plans/0025-findings-batch/` was **not absent**: commit `116d50c` had already
created it with `accept.Tests.ps1` and a plan recording the stop. Not a failure —
it is the artifact of the truncated-prompt stop the prompt itself refers to. The
acceptance test found there is byte-identical to the one the prompt specifies,
and was reused rather than rewritten.

## 3. Environment

```
pwsh              7.6.5
Pester            6.1.0
OS                Microsoft Windows 10.0.26200 (Windows 11 Home)
model-version     claude-opus-5[1m]
Claude Code       NOT OBSERVABLE from inside the session - `claude` is not on
                  the reachable PATH and $env:CLAUDE_CODE_VERSION is empty.
                  $env:CLAUDE_CODE_ENTRYPOINT = claude-vscode is recorded instead.
harness branch    pass-0025-findings-batch
harness HEAD      116d50ca3c7e371067867f3bed0d5e8ca620870c at start
tf branch         pass-0025-hasvalidation
tf HEAD           05fb60d5286e99b302afbfaf5eee87c866ecd14c at start
```

## 4. Acceptance test — red first

`plans/0025-findings-batch/accept.Tests.ps1`, unmodified from `116d50c`.

```
Invoke-Pester -Path plans/0025-findings-batch/accept.Tests.ps1 -Output Detailed
```

**7 of 7 red before any work**, and each for the right reason — an absent
artifact, not a broken assertion:

| # | Assertion | Failure |
| --- | --- | --- |
| 1 | decision 0012 exists | `Expected $true, but got $false` |
| 2 | tf-002 is 7/7 | `Cannot find path …runs\tf-002-convention-and-case3\README.md` |
| 3 | tf-002 records the model version | same missing path |
| 4 | oracle re-falsified after amendment | `Cannot find path …mutations.txt` |
| 5 | new and amended skills exist | `Expected $true, but got $false` (`skills/producer-contract/SKILL.md`) |
| 6 | conformance states a stable denominator | `Cannot find path …denominator.txt` |
| 7 | LEDGER exists with the four registers | `Cannot find path …LEDGER.md` |

## 5. Tasks

### - [x] 1. Acceptance red

Above. `Tests Passed: 0, Failed: 7`.

### - [x] 2. Name the 31st difference

```
./evals/tf/Compare-TfGraph.ps1 -Expected evals/tf/fixture/expected-graph.json \
                               -Actual   runs/tf-001-first-build/graph.json
```

31 differences: `WrongAttribute` 28 (every one `hasValidation`), `MissingEdge` 3.
The three non-`hasValidation` differences, in full:

```
MissingEdge  TfFixtureNetwork:.#output.segment_id -> TfFixtureApp:.#var.network_segment_id
MissingEdge  TfFixtureNetwork:.#output.subnet_ids -> TfFixtureApp:.#var.network_subnet_ids
MissingEdge  TfFixtureNetwork:modules/segment/modules/subnet#output.id
          -> TfFixtureNetwork:modules/segment#output.subnet_ids
```

**The 31st is the third: the splat.** The expression is `module.subnet[*].id`.
**Classified as a producer defect** → task 5.

**The prompt was slightly wrong here, and the difference matters only to the
record.** It says tf-001 "accounts for 28 + 2 of 31", implying one was
unaccounted for. tf-001's README in fact named all three groups, including this
one, under *"1 × MissingEdge, splat syntax"* and again in `findings.md` as D-1.
Nothing was missing; it had been recorded and not fixed, because the run hit its
three-iteration cap. Re-deriving it independently was still worth doing — it
confirmed the count had not drifted and that nothing else hid behind the 28.

### - [x] 3. Decision 0012

`decisions/0012-fixture-case3-repair.md`. Records that case 3's cross-repository
tie existed only in the *description string* of `variable "network_segment_id"`,
that no parser can read prose, and that the fixture is amended exactly once under
decision 0011's provision.

**The construct chosen, and named in the decision:** a `module "network"` block
in TfFixtureApp sourcing **TfFixtureNetwork's root** by `git::` URL with no
`//subdirectory`, and two locals reading its outputs. `terraform_remote_state`
was considered and rejected in writing: it names a *state backend* rather than a
repository, and this producer never reads state.

The decision also records a third defect found while re-authoring: those two
edges were the only `references` edges in the oracle carrying `"resolved": true`,
so a producer emitting a correct edge without it would have been charged a
`WrongAttribute` on those two and no others. Dropped.

The 31st difference's disposition is recorded there as producer-side, explicitly
so the record shows all 31 accounted for.

### - [x] 4. Amend the fixture, re-falsify, re-freeze

Files changed under `evals/tf/fixture/`: `repos/TfFixtureApp/main.tf`,
`repos/TfFixtureApp/variables.tf`, `expected-graph.json`, `cases.md`.

Oracle after amendment, measured not asserted:

```
nodes 78   edges 59        (was 78 / 57)
edges with an unknown endpoint: 0
per repo:  Shared 22   Network 27   App 29
App:  variable 13 -> 11,  local 3 -> 5
```

**Re-falsification ran BEFORE the push, not after.** The prompt orders push →
read-back → re-falsify; re-falsifying first is strictly safer, because a broken
oracle discovered after a push is a second fixture commit and this fixture gets
one.

```
pwsh evals/tf/Invoke-TfOracleFalsification.ps1 -ReportPath plans/0025-findings-batch/mutations.txt
→ exit 0.  CONTROL GREEN (0 differences, 78 nodes / 59 edges)
  7 mutations, 7 detected, 7 distinct categories.  DETECTED: 7 / 7
```

Push, one repository, two edits:

```
pwsh evals/tf/Update-TfFixture.ps1 -Decision 0012 -Message '...' -WhatIf   # first
→ TfFixtureApp: push 2 change(s) on 187ff22…: 2 edit
  TfFixtureNetwork / TfFixtureShared: no differences; not pushed

pwsh evals/tf/Update-TfFixture.ps1 -Decision 0012 -Message '...' -Confirm:$false
→ TfFixtureApp  changes=2  44ea9338ff35aef328bfa8d51835fc32bea590dd  2 edit
```

Byte read-back → `plans/0025-findings-batch/readback.txt`, ending
**`BYTE-IDENTICAL`**, 40 files across 3 repositories. New fixture SHAs:

| Repository | Commit | |
| --- | --- | --- |
| TfFixtureShared | `0af6ee33854bedb4147d0b13cc6db1311687775b` | unchanged |
| TfFixtureNetwork | `24f27be92e583b6dfc9208bca42f8ec0baf5004b` | unchanged |
| TfFixtureApp | `44ea9338ff35aef328bfa8d51835fc32bea590dd` | amended |

**Fixture re-frozen from this point. Nothing after this task touched it**, and
`verify.ps1` check 6a re-asserts these three SHAs against the AzDO API.

Two scripts were added because pass 0023 kept both in `scratch/`, uncommitted:
`evals/tf/Invoke-TfOracleFalsification.ps1` (a falsification nobody can re-run is
a claim, not evidence) and `evals/tf/Update-TfFixture.ps1`.
`Publish-TfFixture.ps1` is unchanged — it can only make a first commit, and that
refusal is worth keeping.

### - [x] 5. Producer fix

`PSTerraformGraph`, branch `pass-0025-hasvalidation`, commit `0ff34c0`.

**Red first.** Six tests failed before either fix:

```
[-] omits hasValidation entirely where there is no validation block
[-] ties the counted module output to the output that splats it
[-] reads the member past a [*]  / [0] / [count.index] / [ * ]   (4 cases)
```

Fix 1 — `Get-TfConfigurationGraph.ps1`: `hasValidation` written only when true.
`hasDefault` deliberately left as an explicit `false`; the oracle draws the same
line, and it is verified — 11 oracle variables carry `hasDefault: false` and 5
carry `hasValidation: true`, none carries `hasValidation: false`.

Fix 2 — `Get-TfReference.ps1`: an optional `(?:\s*\[[^][]*\])?` between the module
name and the member. The bracket body may not contain a bracket, so a nested
index stops the match rather than running past the member.

```
pwsh ./build.ps1  →  exit 0.  41 tests passed, 0 failed.  Covered 83.56% / 70%.
```

**One test passed vacuously and was corrected.** The first `hasValidation`
assertion reached for `$attributes.PSObject.Properties.Name` — on a hashtable
that lists `Count` and `Keys`, never the keys — so it went green against a
producer still writing the field. It now checks `.Keys` and, separately, the JSON
the comparator actually reads. A test that cannot fail is worse than a missing
one, because it is counted.

### - [x] 6. Run tf-002

`runs/tf-002-convention-and-case3/`. Fixture cloned fresh from AzDO at the new
SHAs, **3 concurrent**.

```
plugin-sha:     the harness branch tip recorded in the run README
target-sha:     1dd491335f8347f3985b4a5313b0e60a3b406bd9  (tag v0.2.0)
model-version:  claude-opus-5[1m]
build:          exit 0 (41 tests, 83.56% / 70%, analyzer clean)
battery:        7 / 7
functional-tf:  7 / 7
differences:    0        (78 nodes, 59 edges, both sides)
```

**Iterations: none.** The first score was 0; the cap allowed three. The run
record says plainly that this makes the run test *less* than tf-001 did, and
that the comparator's re-falsification against the amended oracle is what carries
the instrument claim instead.

Three layouts rendered **concurrently, one ThreadJob per layout**; each carries
its own `"DefaultFlow": "<layout>"` and 74 `vscode://file/` links across 37
distinct targets. A raw grep returns 77 — three are inside the renderer's own
JavaScript — and the record says so, because the easy count was the first number
written.

**Everything was regenerated once after the version bump**: the first
`graph.json` said `producerVersion: 0.1.0` while the record claimed v0.2.0.
Identical score; an artifact that disagrees with its record is a later mystery.

`evals/tf/Test-TfFixtureCase.ps1` is committed rather than run from a shell, and
is falsified: it scores **6/7 against tf-001's committed graph, failing exactly
case 3**.

Tagged `v0.2.0` (annotated, scores in the message), `docs/worklog/v0.2.0.md`
written, HANDOFF version ledger and Open list updated, pushed, `main`
fast-forwarded with ancestry verified:

```
git merge-base --is-ancestor main v0.2.0^{}   →  FAST-FORWARD SAFE
origin/main   1dd491335f8347f3985b4a5313b0e60a3b406bd9
origin v0.2.0 → 1dd4913…
```

**A gate that had never been able to run was found here.** PSTerraformGraph
declared a `PreTag` task from v0.1.0 with **no PreTag-tagged test**, so
`-Task PreTag` could only throw its own guard. v0.1.0 was tagged without it ever
having run. `tests/PreTag.Tests.ps1` was written — 8 assertions, and **each was
broken on purpose and confirmed red** before the tag:

```
worklog missing        broken -> 1 failed  GATE FIRED
HANDOFF ledger row     broken -> 1 failed  GATE FIRED
absent path named      broken -> 1 failed  GATE FIRED
document pushes        broken -> 1 failed  GATE FIRED
terraform invoked      broken -> 1 failed  GATE FIRED
network from src       broken -> 1 failed  GATE FIRED
restored -> 8 passed, 0 failed
```

### - [x] 7. Skill batch

The **full** `runs/tf-001-first-build/findings.md` list was worked, and what did
not become a skill change is in Deviations.

| Finding | Change |
| --- | --- |
| A-1 dev loader | `powershell-module-scaffold`: the committed `src/<Name>/<Name>.psm1`, its three load-bearing properties, and the fourth corner it adds to three-way agreement |
| A-2 dependency resolver | `powershell-module-build`: parameterised on `$Name`, deriving `$env:<DEP>_MODULE_PATH` from it; the four rename points named for anyone keeping a hard-coded copy |
| A-3 producer contract | **new** `skills/producer-contract/SKILL.md` |
| A-4 singular nouns | `powershell-module-build`: the three-part suppression comment, with `PSUseSingularNouns` against a contract-fixed name as the recurring case |
| — (found here) | `powershell-module-build`: declaring `PreTag` is not having the gate |

A-1 verified rather than assumed:

```
PSGraphRenderToHtml    src IMPORT OK   exports=4  matches manifest=True
PSTerraformGraph       src IMPORT OK   exports=2  matches manifest=True
PSGraphRender          src IMPORT FAILED: … no valid module was found …
```

PSGraphRender noted as **pending** in its own `docs/HANDOFF.md` (commit
`7caf364`), code untouched.

### - [x] 8. Stable conformance denominator

`Invoke-Conformance.ps1` gains `CasesDefined` and `CasesDefinedPerTag`, parsed
from `Conformance.Tests.ps1` **by AST**. The target is never consulted — no file
of it read, no `-ForEach` expanded — which is the whole property.

Falsified against **three** differently shaped targets, one more than the prompt
asked for:

```
  target                             defined  run    passed   score
  run-002 (79e02fb, 7 public fns)    33       57     57       100%
  run-003 (d852abc, 7 public fns)    33       55     39       70.91%
  PSTerraformGraph (2 public fns)    33       41     40       97.56%
```

The two PSAzureDevOpsGraph rows **reproduce the committed results of runs 002 and
003 exactly**. Controlled the other way, because a number that never moves is
stable and useless: `-Tag Universal` → 9, `+HouseStyle` → 23, all four → 33.

→ `plans/0025-findings-batch/denominator.txt`, ending
**`cases-defined identical across shapes: True`**, with the runs 004–006
comparison rule stated in full.

**No assertion weakened.** `CasesRun` and `ScorePct` are computed exactly as
before.

### - [x] 9. LEDGER

`LEDGER.md` at the harness root, with the four registers and the prompt's
content, bracketed values resolved: PSTerraformGraph `v0.2.0`, the three
decision-0012 fixture SHAs, and four backlog items this pass added.

**The `Harness main` pin is not a SHA, deliberately.** A file cannot name the
commit that contains it. It names the branch and the rule, and `verify.ps1`
check 5 grades the pins that *can* be checked — the tag against
`git ls-remote`, and the three fixture SHAs against the AzDO API.

### - [x] 10. Records

Harness README (repository table, the renderer-boundary claim), ToHtml README
and HANDOFF (`da89d05`), PSTerraformGraph README/HANDOFF/worklog, this plan,
`verify.ps1`, the journal, and both mains fast-forwarded.

## 6. Acceptance test — green

```
Invoke-Pester -Path plans/0025-findings-batch/accept.Tests.ps1 -Output Detailed
Tests Passed: 7, Failed: 0, Skipped: 0
```

## 7. Command transcript

```powershell
# preconditions
git fetch --all --prune --tags                       # x6, parallel
git rev-parse main origin/main fc27c53b066473d58d793470fb132feb388ac214
git -C ../PSTerraformGraph rev-parse main origin/main 05fb60d5286e99b302afbfaf5eee87c866ecd14c
git -C ../PSTerraformGraph tag -l
pwsh evals/tf/Test-TfFixtureReadBack.ps1

# 1 acceptance red
Invoke-Pester -Path plans/0025-findings-batch/accept.Tests.ps1 -Output Detailed

# 2 the 31st difference
pwsh evals/tf/Compare-TfGraph.ps1 -Expected evals/tf/fixture/expected-graph.json -Actual runs/tf-001-first-build/graph.json

# 3-4 amend, re-falsify, push, read back
pwsh evals/tf/Invoke-TfOracleFalsification.ps1 -ReportPath plans/0025-findings-batch/mutations.txt
pwsh evals/tf/Update-TfFixture.ps1 -Decision 0012 -Message 'Case 3 gains a mechanical cross-repository tie.' -WhatIf
pwsh evals/tf/Update-TfFixture.ps1 -Decision 0012 -Message 'Case 3 gains a mechanical cross-repository tie.' -Confirm:$false
pwsh evals/tf/Test-TfFixtureReadBack.ps1 -ReportPath plans/0025-findings-batch/readback.txt
git add -A && git commit && git push origin pass-0025-findings-batch      # 5ac73ba

# 5 producer fix, red first
Invoke-Pester -Path ../PSTerraformGraph/tests            # 6 failed, red first
pwsh ../PSTerraformGraph/build.ps1                       # 41 passed, 83.56%
git -C ../PSTerraformGraph add -A && git commit && git push origin pass-0025-hasvalidation   # 0ff34c0

# 6 run tf-002
git -c http.extraHeader=<PAT header> clone <3 fixture repos>              # 3 concurrent
Get-TfConfigurationGraph -Path <3 roots> -RepositoryName <3 names>
pwsh evals/tf/Compare-TfGraph.ps1 -Expected <oracle> -Actual scratch/tf-002/graph.json
pwsh evals/tf/Test-TfFixtureCase.ps1 -Path <graph> -ReportPath runs/tf-002-convention-and-case3/cases.txt
Invoke-Pester -Container (New-PesterContainer -Path ../PSGraphRenderToHtml/tests/ProducerContract.Battery.ps1 -Data @{ GraphPath = <graph> })
Export-TfConfigurationGraphHtml -Path <3 roots> -OutputPath <html> -Options (New-GraphRenderOptions -Layout <l>)   # 3 concurrent
pwsh ../PSTerraformGraph/build.ps1 -Task PreTag           # 8 passed after tests/PreTag.Tests.ps1
git -C ../PSTerraformGraph tag -a v0.2.0 -F -
git -C ../PSTerraformGraph merge-base --is-ancestor main v0.2.0^{}
git -C ../PSTerraformGraph push origin pass-0025-hasvalidation v0.2.0
git -C ../PSTerraformGraph branch -f main v0.2.0^{} && git push origin main      # 1dd4913

# 7 skills
git add -A && git commit && git push origin pass-0025-findings-batch      # 95f0623
git -C ../PSGraphRender add -A && git commit && git push origin pass-0024-consumer-ref   # 7caf364

# 8 denominator
git clone <PSAzureDevOpsGraph> x2 at 79e02fb and d852abc                  # 2 concurrent
pwsh <each>/build.ps1
pwsh evals/conformance/Invoke-Conformance.ps1 -Path <target> -Tag Universal,Repository,HouseStyle,RequiresBuild -ModuleName PSAzureDevOpsGraph
git add -A && git commit && git push origin pass-0025-findings-batch      # 1f68009

# 9-10 records, verify, acceptance green
git -C ../PSGraphRenderToHtml add -A && git commit && git push origin pass-0024-consumer-ref   # da89d05
pwsh plans/0025-findings-batch/verify.ps1 -FailCheck                      # 5 probes, all fired
pwsh plans/0025-findings-batch/verify.ps1                                 # 21 checks, 0 failed, 0 skipped
Invoke-Pester -Path plans/0025-findings-batch/accept.Tests.ps1            # 7 passed
```

## 8. Verify script

`plans/0025-findings-batch/verify.ps1`, 21 checks, SHA-pinned, writes only under
`scratch/verify-0025/`, one exit code. Not reproduced here: it is long enough
that a second copy in this file could disagree with the committed one, which is
hazard 6 applied to the artifact whose job is to disprove this plan.

```
pwsh plans/0025-findings-batch/verify.ps1 -FailCheck
→ 5 probes. Each broke something, each proved the break landed, each drove
  its check red. P1 comparator, P2 case scorer, P3 x2 mutations, P4 inventory.

pwsh plans/0025-findings-batch/verify.ps1
→ 21 check(s), 0 failed, 0 skipped.
```

The AzDO check is the one worth naming: **6b confirms 0 build runs have ever
existed in ClaudeTestingTerraform**, read from the builds API rather than
asserted.

## 9. Deviations

**1. A precondition did not hold, and correctly so.**
`plans/0025-findings-batch/` already existed, from commit `116d50c`'s
truncated-prompt stop. The acceptance test there is byte-identical to the
prompt's and was reused. This plan replaces that commit's `plan.md`.

**2. The prompt's "28 + 2 of 31" was slightly wrong.** tf-001 had already named
all three groups including the splat, in its README *and* in `findings.md` as
D-1. Nothing was unaccounted for. Re-deriving it was still worthwhile —
it confirmed the count had not drifted and that nothing hid behind the 28.

**3. Task 4's steps were reordered.** The prompt says push → read-back →
re-falsify. Re-falsification ran **first**, because a broken oracle discovered
after a push needs a second fixture commit and this fixture gets one. All three
were done; only the order changed.

**4. The three `tf-<role>` skills tf-001 proposed were deliberately NOT written.**
This is the largest judgment call in the pass and it is a recommendation, not a
decision taken.

They would encode this fixture's specific answers — `required_providers` is both
a block and an attribute; a registry address and `./modules/child` are the same
shape to a naive pattern; the parser spaces out expressions. **tf-003 is meant to
be the blind generalisation measurement against that same fixture.** Writing
those skills first and then scoring against that fixture measures the plugin's
memory of tf-001 rather than its generality — the same contamination run 002's
record already carries once, about a builder who read the cases, made permanent.

The knowledge is not lost: it is in PSTerraformGraph's `docs/worklog/v0.1.0.md`
and `v0.2.0.md`, which is where a module's reasoning about its own domain
belongs. Recorded in LEDGER backlog item 9 with the two clean orders — after
tf-003, or against a second Terraform fixture. **The operator should overrule
this if the intent was to ship them.**

**5. `producer-contract` fits neither prefix in decision 0007's taxonomy.** It is
neither a PowerShell-module lifecycle stage nor target-specific. The prompt names
the path and the acceptance test pins it, so it was created as specified and the
gap flagged in the harness README and LEDGER backlog item 11 rather than bent
into a name that lies.

**6. Two scripts were added that the prompt did not ask for**, both because pass
0023 left them in `scratch/` where nothing could re-run them:
`Invoke-TfOracleFalsification.ps1` and `Update-TfFixture.ps1`. The second exists
because `Publish-TfFixture.ps1` can only make a first commit — a limit worth
keeping, so amending needed its own louder path that refuses to run without a
`-Decision` naming a decision file that exists.

**7. Found, not asked about: PSTerraformGraph's `PreTag` gate had never been able
to run.** The task was declared from v0.1.0 with no PreTag-tagged test, so it
could only throw its own guard, and v0.1.0 was tagged without it. Conformance
could not catch it — it asserts the task is *declared* and excluded from the
default, both of which stayed true. Fixed here with 8 assertions, each proved
able to fail.

**8. Found, not fixed: `Export-TfConfigurationGraphHtml` is exported and no test
invokes it.** PSTerraformGraph scores conformance **40/41** on that one
assertion. Found while using it as a third denominator target — a use nobody
intended as a check on it. Not fixed because v0.2.0 was already tagged and
pushed, and fixing it means either rewriting a pushed tag or landing on `main`
past the tag it follows. Recorded in LEDGER backlog item 8. The shape is worth
noting: three green numbers — 7/7, 7/7, 0 differences — over a module half of
whose public surface is untested.

**9. A silent PowerShell bug worth publishing.** The first denominator
implementation wrote `foreach ($tag in $Tag)`. Variable names are
case-insensitive, so `$tag` **is** `$Tag`: the loop rebound the parameter to its
last element and every tag but one stopped being selected. The run reported 17
cases instead of 57 and read exactly like a Pester filter bug. No analyzer rule
catches it. What caught it was that the falsification had a *predicted* number
from the committed run records, and 17 was not it.

**10. A test that passed vacuously.** The first `hasValidation` assertion used
`PSObject.Properties.Name` on a hashtable, which lists `Count` and `Keys` and
never the keys, so it went green against a producer still writing the field.
Corrected to check `.Keys` and the serialised JSON.

**11. The Claude Code version could not be recorded.** `claude` is not on the
PATH the session can reach and `$env:CLAUDE_CODE_VERSION` is empty. The
observable `$env:CLAUDE_CODE_ENTRYPOINT = claude-vscode` is recorded instead.
This is the plan protocol's own rule about token counts applied to a different
field, and it wants fixing at the host end rather than in the record.

**12. The prompt's `-FailCheck` requirement was met with 5 probes rather than one
per check.** Each probe asserts the break landed before requiring red; a probe
whose break changed nothing reports `PROBE-VOID` and fails the run, which is the
polarity defect this project has hit twice before.

## 10. Cost

Wall-clock: roughly 2 hours 20 minutes, preconditions to acceptance green.

| Thing run | Count |
| --- | --- |
| PSTerraformGraph builds | 4 (2 red-first, 2 green) + 2 PreTag |
| Module test-suite runs | 7 |
| Oracle falsification runs | 1 (7 mutations + control) |
| Comparator scoring runs | 6 |
| Conformance runs | 7 (3 targets × tag selections) |
| Byte read-backs of the fixture | 2 (before and after the amendment) |
| HTML renders | 7 (3 + 3 regenerated + 1 in verify) |
| verify.ps1 runs | 2 (`-FailCheck`, then full) |
| Gate falsification probes | 6 (PreTag) + 5 (verify) |
| AzDO objects created or modified | **1** — one commit on TfFixtureApp |
| AzDO builds queued | **0**, confirmed against the builds API |

Degree of parallelism: **6** (repository fetch), **3** (fixture clones),
**3** (layout renders), **2** (run-target clones), **1** elsewhere — the parser,
the scoring and the iterations are serial by nature.

No token count. The agent cannot measure one from inside the session.
