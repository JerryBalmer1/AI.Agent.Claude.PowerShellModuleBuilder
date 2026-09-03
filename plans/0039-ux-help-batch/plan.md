# 0039 — The UX and help batch: skills, assertions, settings, v1.2.0

Tier: **full**. The pass changes executable behaviour — two conformance
containers, the runner, the scorer, a new settings reader and two skill scripts.

## 1. Prompt

```
# PASS 0039 — The UX and help batch: skills, assertions, settings, v1.2.0
Tier: full

## Repositories
Harness only — branch `pass-0039-ux-help-batch` from `main`
(`a01e079…`). Installed surface changes (skills/, conformance) — this
pass releases. Fixtures, oracles, AzDO objects, sibling repos:
untouched.

## Preconditions
Sync; trees clean; branch created; no tag `v1.2.0`;
`skills/powershell-module-ux` and `skills/powershell-module-tidy`
absent; `evals/conformance/` currently defines cases-defined = 33
(record the exact figure and its per-tag split before any change).

## Acceptance test — red first
`plans/0039-ux-help-batch/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0039 delivered' {
        It 'the two new skills exist' {
            Test-Path "$RepoRoot/skills/powershell-module-ux/SKILL.md"   | Should -BeTrue
            Test-Path "$RepoRoot/skills/powershell-module-tidy/SKILL.md" | Should -BeTrue }
        It 'ux skill cites its source and carries the cache guardrails' {
            $s = Get-Content "$RepoRoot/skills/powershell-module-ux/SKILL.md" -Raw
            $s | Should -Match 'powershell\.one'
            $s | Should -Match 'never cache.*(secret|credential|token)' }
        It 'analyzer gained the class-candidate rule' {
            (Get-Content "$RepoRoot/skills/powershell-module-analyzer/SKILL.md" -Raw) |
                Should -Match 'PSCustomObject' }
        It 'docs skill carries the house example standard' {
            (Get-Content "$RepoRoot/skills/powershell-module-docs/SKILL.md" -Raw) |
                Should -Match 'splat' }
        It 'plan skill owns the master plan' {
            (Get-Content "$RepoRoot/skills/powershell-module-plan/SKILL.md" -Raw) |
                Should -Match 'docs/PLAN\.md' }
        It 'help assertions exist with falsification evidence' {
            Test-Path "$RepoRoot/evals/conformance/Help.Tests.ps1" | Should -BeTrue
            $f = Get-Content "$RepoRoot/plans/0039-ux-help-batch/help-falsification.txt" -Raw
            $f | Should -Match 'BREAKS: \d+ / \d+ red'
            $f | Should -Match 'CONTROLS: \d+ / \d+ green' }
        It 'settings file support exists and is asserted' {
            (Get-Content "$RepoRoot/plans/0039-ux-help-batch/settings-falsification.txt" -Raw) |
                Should -Match 'UNKNOWN KEY: refused' }
        It 'the denominator boundary is recorded' {
            $d = Get-Content "$RepoRoot/plans/0039-ux-help-batch/denominator-v2.txt" -Raw
            $d | Should -Match 'cases-defined \(pre\):\s*33'
            $d | Should -Match 'cases-defined \(post\):\s*\d+'
            $d | Should -Match 'series boundary: v1\.2\.0' }
        It 'reference target still scores clean on the new suite' {
            (Get-Content "$RepoRoot/plans/0039-ux-help-batch/refscore.txt" -Raw) |
                Should -Match 'RUN-006 CLONE \(built\): \d+ / \d+ .* Bucket B declared' }
        It 'manifest is 1.2.0 with a CHANGELOG entry and v1.2.0 on the remote' {
            (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version |
                Should -Be '1.2.0'
            (Get-Content "$RepoRoot/CHANGELOG.md" -Raw) | Should -Match '(?m)^## 1\.2\.0'
            (git ls-remote --tags origin 'v1.2.0*') | Should -Not -BeNullOrEmpty }
    }

Run it; report the red. Green at start stops the pass.

## Plan (∥ = parallel drafting, serial review; push per group)
- [ ] 1. Acceptance red. Record the pre-change cases-defined split.
- [ ] 2. ∥ **Skill batch A — new content:**
      - `powershell-module-ux`: argument-completion judgment. When
        completion earns its place (enumerable/discoverable value
        sets, stable within a session); ValidateSet vs
        [ArgumentCompleter] vs class-based completers, each with a
        tested example; the session-cache pattern — `$script:` cache
        populated on first real call so completion feels instant,
        with guardrails stated as rules: expose a refresh/clear path,
        document staleness, NEVER cache secrets, credentials, tokens,
        or PAT-derived values; cost threshold (enumeration over
        ~200ms → cache, else live). Completers are testable —
        `[System.Management.Automation.CommandCompletion]::CompleteInput`
        from Pester — and the skill says a completer without a test
        does not ship. Sources line: techniques distilled from
        powershell.one (link the auto-completion article and any
        siblings actually consulted); all prose and examples original,
        nothing reproduced.
      - `powershell-module-tidy`: the pre-release aggregation verb.
        Directory and file-naming conformance sweep, public-surface
        vs docs parity, dead-file detection, `docs/PLAN.md` currency
        check (stale plan = release blocker), and it ends by running
        the conformance suite and refuses to bless with open
        Bucket-A items. Deterministic checks delegated to scripts
        under `scripts/` per rule 9.
- [ ] 3. ∥ **Skill batch B — amendments:**
      - `powershell-module-analyzer`: the class-candidate rule —
        AST-detect the same key-set emitted as PSCustomObject from
        ≥3 sites → surface as a candidate WITH the tradeoffs
        (reload behavior, using-module, serialization, mocking);
        judgment, never auto-applied; note ToHtml's deliberate
        schema-over-class choice as the counterexample.
      - `powershell-module-architect`: the enumerator rule — every
        public output type gets a no-argument `Get-<Noun>` (singular
        noun, returns many; the API-wrapper pattern); singleton and
        configuration types are the named exception mechanism.
      - `powershell-module-docs`: the house `.EXAMPLE` standard —
        parameters assigned at the top with aligned `=` (the
        alignment is deliberate: values readable at a glance), splat
        via a `$params` hashtable, try/catch with a real error
        message, result displayed; copy-paste-and-edit is the design
        goal, per the operator's convention. Full comment help for
        every function public AND private (Synopsis, Description,
        .PARAMETER per parameter, Example per parameter set);
        HelpMessage on mandatory parameters; classes and enums do
        not support comment-based help — the standard is a doc
        comment block immediately preceding each type plus coverage
        in an `about_<Module>` topic, and the skill says so plainly.
      - `powershell-module-plan`: the master plan obligation —
        every module carries `docs/PLAN.md`, plain-language,
        always-current: what this module is, why it exists, where
        it stands, what is next, and where the detailed records
        live; written for a reader who will never open the
        machinery; updated whenever a plan file is added or a
        release is cut; tidy verifies it.
- [ ] 4. **Help assertions.** New `evals/conformance/Help.Tests.ps1`
      (own tag within the existing tag scheme — choose HouseStyle
      unless METHOD says otherwise, state the choice):
      every function (public and private) has comment help with
      Synopsis, Description, and ≥1 Example; examples ≥ parameter
      sets, and each named set's signature appears in some example;
      every declared parameter has a `.PARAMETER` entry; every
      class/enum immediately preceded by a doc comment block; module
      with public classes/enums ships `about_<Module>`. Falsify with
      polarity-correct controls per rule 3 — at minimum: strip one
      example from a two-set function (red naming function AND set);
      single-set function with one example (green); parameter
      missing its .PARAMETER (red naming it); a comment block that
      mentions help keywords without being attached help (scope
      control, green); class without a preceding block (red) →
      `help-falsification.txt` with `BREAKS: n/n red` and
      `CONTROLS: n/n green`.
- [ ] 5. **Settings.** Conformance + build honor an optional
      `psmodule.settings.psd1` at target root: enumerated known keys
      only (coverage threshold, module profile [script|hybrid
      placeholder], completion-cache default), precedence explicit
      param > file > built-in defaults; defaults ARE the measured
      configuration; settings echoed into every score/run record;
      unknown key = refusal naming it. Falsify: unknown key refused
      (`settings-falsification.txt` → `UNKNOWN KEY: refused`), known
      key honored, absent file = defaults (control). Skill line in
      powershell-module-build documenting which claim each switch
      invalidates when flipped.
- [ ] 6. **Denominator v2.** Re-derive cases-defined post-change →
      `denominator-v2.txt`: pre 33, post N with per-tag split, and
      the line `series boundary: v1.2.0 — conformance scores before
      and after this tag are separate series and are not compared`.
      Mirror one paragraph into docs/testing and the harness README
      table's footnotes.
- [ ] 7. **Prove it on the reference.** Fresh clone of run 006's
      final (`7066916`), built, scored under the new suite →
      `refscore.txt`. New-assertion failures on it are EXPECTED
      (it predates the rules): sort them honestly — Bucket B
      declared with the boundary rationale, not fixed, not
      weakened — `RUN-006 CLONE (built): x / N, <k> new-rule
      failures Bucket B declared`. This is the control that the new
      assertions measure something real without rewriting history.
- [ ] 8. **Release v1.2.0** per decision 0013: three version
      strings, CHANGELOG `## 1.2.0` user-facing (two new skills,
      five amended, help conformance block, settings file — and the
      denominator note), README pin → `@v1.2.0`, annotated tag,
      push branch + tag.
- [ ] 9. Item 19 docs ∥ (testing doc: the help block + settings +
      denominator boundary; chapter 03: the class-help honesty as a
      worked "assert the checkable equivalent" example). Acceptance
      green; plan/verify/journal; LEDGER (items closed/opened;
      Pins: new cases-defined; note pass 0040 queued for the
      diagram/prompts/flow docs). Fast-forward main per 0009,
      score-free subject.

## Named spot-checks — verify.ps1 re-derives
1. Fresh clone: verify regenerates the two-set-example break and the
   scope control itself; red/green as recorded.
2. Settings triple re-fired (unknown refused / known honored /
   absent defaults).
3. cases-defined post-figure re-derived and equal to
   denominator-v2.txt across two differently-shaped clones.
4. run-006 clone rescored; matches refscore.txt including the
   Bucket-B count.
5. `git diff v1.1.1..v1.2.0 -- commands/` empty; skills diff = the
   two new directories plus the five named amendments; every
   `.claude-plugin/` change a version field.

## Constraints
No existing assertion weakened or removed — this pass only adds.
Fixture-1/2, both oracles, ClaudeTesting, all AzDO: untouched. No
sibling repo touched (their READMEs cite the plugin by tag, so no
claim moves). powershell.one is cited and distilled, never
reproduced. Claims move down or sideways.

## Report back
The new cases-defined figure and split, the falsification tallies,
the run-006 rescore line with its Bucket-B sort, the two new skill
names, v1.2.0 confirmation, pushed SHAs.
```

## 2. Preconditions

| Precondition | Command | Result |
|---|---|---|
| Sync | `git rev-parse HEAD` | `a01e0792f0986564b3e359206d1a880826b85164`, `main` up to date with `origin/main` |
| Trees clean | `git status --porcelain` | **One untracked file at preconditions — `.build copy.ps1`.** See Deviations 1. Empty by the time the branch was cut. |
| Branch created | `git checkout -b pass-0039-ux-help-batch` | `pass-0039-ux-help-batch` |
| No tag `v1.2.0` | `git tag --list 'v1.*'` / `git ls-remote --tags origin 'v1.2.0*'` | `v1.0.0 v1.0.1 v1.1.0 v1.1.1`; remote listing empty |
| The two skills absent | `ls skills/` | 17 directories, neither `powershell-module-ux` nor `powershell-module-tidy` present |
| cases-defined = 33 | `./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph -Tag Universal,Repository,HouseStyle,RequiresBuild` | **33**, split `HouseStyle 14, Universal 9, RequiresBuild 6, Repository 4`. Committed verbatim as [`pre-inventory.json`](pre-inventory.json). |

Sibling repositories at start and at end, unchanged throughout:

```
PSModuleGraph        0 changed, HEAD 2d97a27
PSAzureDevOpsGraph   0 changed, HEAD fdf4a27
PSGraphRender        0 changed, HEAD a4c18c0
PSGraphRenderToHtml  0 changed, HEAD ac76bc4
PSTerraformGraph     0 changed, HEAD 80fc6bb
```

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 (5.7.1 and 3.4.0 also installed; the runner selects 6.x) |
| OS | Microsoft Windows NT 10.0.26200.0 |
| Branch | `pass-0039-ux-help-batch` |
| HEAD at start | `a01e0792f0986564b3e359206d1a880826b85164` |

## 4. Acceptance test — red first

```
pwsh -NoProfile -Command "Invoke-Pester -Path ./plans/0039-ux-help-batch/accept.Tests.ps1 -Output Detailed"

Tests Passed: 0, Failed: 10, Skipped: 0, Inconclusive: 0, NotRun: 0
```

Full output: [`accept-red.txt`](accept-red.txt). Ten of ten red, none for an
accidental reason — every failure names the artifact that does not yet exist.

## 5. Tasks

### 1. Acceptance red; pre-change split recorded — done

`cases-defined` **33**, `HouseStyle 14 / Universal 9 / RequiresBuild 6 /
Repository 4`, read from the runner's own AST inventory against the reference
and committed as [`pre-inventory.json`](pre-inventory.json). Commit `a0cd1f9`.

### 2. Skill batch A — the two new skills — done

`skills/powershell-module-ux/SKILL.md` (322 lines) and
`skills/powershell-module-tidy/SKILL.md` (157 lines) plus
`skills/powershell-module-tidy/scripts/{Invoke-ModuleTidy.ps1,Test-PlanCurrency.ps1}`.
Commit `c2847c4`.

**Every ux code example was executed before it was written down.** The
scriptblock completer, the class completer, `ValidateSet`, and both
`CompleteInput` cases:

```
FULL  : default,ci,local
NARROW: ci
EMPTY : count=0
CLASS : ci
```

**Sources actually consulted**, all three fetched and read, all three linked in
the skill: the powershell.one *Argument Completion Attributes*, *Creating
Custom Attributes* and *Auto-Learning Auto-Completion* articles. The skill marks
one deliberate departure from its source — that article persists learned
credentials to `$env:TEMP`, which guardrail 3 forbids.

**The tidy sweep is falsified, not asserted.** 13 rows, **7/7 breaks red, 6/6
controls green**, no collateral, known-good re-asserted around every row:
[`tidy-falsification.txt`](tidy-falsification.txt),
[`tidy-falsify.ps1`](tidy-falsify.ps1).

That run is why the skill is worth anything. **One rule shipped inert and the
probe caught it.** `documented-unexported` derived the module's command prefix
from the module NAME, and this plugin's own convention is a command prefix that
is *not* the module name — the reference is `PSModuleGraph` and its commands are
`Get-PSModule*`. Every command the rule existed to catch fell outside its own
pattern. The derivation now groups the exported nouns by their first four
characters and takes each group's longest common prefix, which yields
`{PSModule, Knowledge}` for the reference.

Running the sweep against the reference *before any probe* found two more, both
defects in rules this pass wrote: the PascalCase rule failed `en-US`, a culture
directory the build is **required** to copy, and the space rule failed
`tests/fixtures/res one`, a fixture whose whole purpose is a hostile path. Both
are now **scoped** rather than exempted — the space rule reads only
`.ps1`/`.psm1`/`.psd1`, and the PascalCase rule skips the same culture pattern
the psm1 emitter uses. Scoping a rule to what it is about and exempting a
directory from it are different acts, and only the second stops a check firing
where it should.

### 3. Skill batch B — four amendments — done

Commit `d15b5f4`. `analyzer`, `architect`, `docs`, `plan`. (The fifth named
amendment, `build`, lands with the settings group in task 5, since its content
is the settings table.)

The analyzer's AST snippet was run before it was written down — a two-key
`[pscustomobject]` literal returns `A,B` through the published code. The
counterexample was **checked rather than asserted**: `class` appears nowhere in
`PSGraphRenderToHtml`'s source, and the shape lives in
`contract/producer-graph.schema.json`, which its README calls "the authority".

The docs skill's class-help claim was likewise verified rather than recalled:

```
matches for 'ZzUniqueThing': 0
type resolves: True
typed lookup threw: HelpNotFoundException
```

A complete help block above a class produces no help at all. That is why the
standard asserts the checkable equivalent and says out loud that it is one.

### 4. Help assertions — done

`evals/conformance/Help.Tests.ps1`, eight assertions, **all tagged
`HouseStyle`**. Commit `bddcb2f`.

**The tag choice, stated as the prompt asks.** METHOD's ladder puts
organisation convention at `HouseStyle`, and every assertion here is strictly
stronger than the existing `Universal` synopsis rule that posh-git already fails
on five commands (declared Bucket B). Help on *private* functions, a
`.PARAMETER` per parameter, examples counted against parameter sets, and a doc
block before every type are house rules. Promoting one later is a claim needing
evidence from a second dissimilar target; starting them at `Universal` would be
assuming the answer.

`cases-defined` **33 → 41**, `HouseStyle` **14 → 22**.
`Invoke-Conformance.ps1` now inventories and runs **every** `*.Tests.ps1` in the
directory rather than naming one file — see Deviations 3.

**Falsification: 7/7 breaks red, 5/5 controls green, 12/12 case names
preflighted, known-good re-materialised before every row.**
[`help-falsification.txt`](help-falsification.txt),
[`help-falsify.ps1`](help-falsify.ps1),
[`New-HelpFixture.ps1`](New-HelpFixture.ps1). Every row the prompt names is
present: H1/H2 strip one example from a two-set function and go red naming the
function *and* the set (`ByPath`); H3 is the single-set function with one
example staying green; H4 removes a `.PARAMETER` and goes red naming `Detailed`;
H5 is the unattached comment block quoting help keywords, staying green; H7
removes the block above a class and goes red. H6 is a **substitution** control
per METHOD — the real help deleted and a detached block still saying
`.SYNOPSIS` left in its place — which a comment-only probe cannot supply.

**Why a purpose-built fixture rather than the reference**, and it is item 7's
point rather than an evasion of it: the reference predates these rules and fails
219 of their cases, so a break against it is *unobservable* — the case it would
turn red is already red. A falsification row needs a known-good, and for a new
rule the known-good has to be built. The reference's standing behaviour is
recorded separately as declared Bucket B in task 7.

**The fixture earned its cost on its first run.** It was **not** green, and the
failure was a rule this same pass wrote: set coverage looked for the `-Name`
dash form, while the house `.EXAMPLE` standard mandates **splatting**, so a
conforming example names its parameters as hashtable keys and never writes
`-Name` at all. The assertion was unsatisfiable by exactly the examples it
rewards. Two rules shipped in one pass contradicted each other and read as
entirely consistent side by side; only running one against the other found it.

### 5. Settings — done

`evals/conformance/Get-PSModuleSetting.ps1`, one reader owning the enumerated
key list, the precedence rule and the refusal. Wired into
`Invoke-Conformance.ps1` (echoed into `result.json` with the **provenance** of
every value) and carried through by `Score-Clone.ps1` rather than re-resolved,
so a run record and the result JSON beside it cannot state different settings.
`powershell-module-build` gains the table of what each switch invalidates.
Commit `553f6bf`.

**The defaults are the measured configuration.** `CoverageThreshold = 75` is
Pester's own default, is what the reference's build file sets, and is what every
published score here was taken under.

Falsification, 3 breaks and 3 controls
([`settings-falsification.txt`](settings-falsification.txt)):

```
ABSENT FILE: defaults  CoverageThreshold=75 source=default IsMeasuredConfiguration=True
UNKNOWN KEY: refused. 'CoverageThresold' ... is not a setting this plugin has.
KNOWN KEY: honoured   CoverageThreshold=90 source=file IsMeasuredConfiguration=False
INVALID VALUE: refused. 'CoverageThreshold' ... is '90'; expected an integer from 0 to 100.
PARAM > FILE: CoverageThreshold=60 source=parameter
UNKNOWN KEY: refused. 'Nonsense' was passed as an override ...
```

Two controls beyond what the prompt asked for, and both matter. Row 4 is the
**near miss**: `'90'` as a *string* on a correctly spelled key, which PowerShell
would coerce to `90` without complaint — a reader that coerces has decided what
the user meant. Row 6 applies the rule to the **caller**: a typo in a script
invoking the grader is not more acceptable than a typo in a user's file.

### 6. Denominator v2 — done

[`denominator-v2.txt`](denominator-v2.txt). Commit `1fb939a`.

```
cases-defined (pre):  33
cases-defined (post): 41

  Tag             pre   post   delta
  HouseStyle       14     22      +8
  Universal         9      9       0
  RequiresBuild     6      6       0
  Repository        4      4       0
  TOTAL            33     41      +8
```

Re-derived across three differently shaped targets — `cases-run` **477 / 154 /
60**, `cases-defined` **41** in all three.

The boundary line, mirrored into
[`docs/testing/README.md`](../../docs/testing/README.md) (three new sections:
the boundary, the settings file, and the container guard) and quoted above the
`README.md` score table where the affected figures actually are:

> series boundary: v1.2.0 - conformance scores before and after this tag are separate series and are not compared

All three places say the same thing about what it does **not** license: the
boundary is not a reset, the ladder's numbers stand on the 33-case series, and
nothing earlier is restated or re-derived.

### 7. Prove it on the reference — done

[`refscore.txt`](refscore.txt). Commit `1fb939a`.

```
./Score-Clone.ps1 -Source https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git \
                  -Ref 70669167ea5f59a47efb282002052f9e926a34bf -WorkDir C:/w39/r6

SCORE  38 / 41 (cases-defined)   cases-run 128/154   build exit 0
       settings: defaults (the measured configuration)
```

**RUN-006 CLONE (built): 38 / 41 with 3 new-rule failures, all Bucket B
declared.** Under the pre-change suite the same commit scores 33 / 33.

The sort is unusually clean, and the cleanliness is itself the evidence:

- **B-H1** `at least one example` — 12 of 19 cases red, and the twelve are
  **exactly the twelve private functions**, with no public one among them. The
  commit was built to a docs skill that required help on the exported surface
  and said nothing about private functions, and the module did precisely that.
- **B-H2** `at least as many examples as parameter sets` — 13 red: the same
  twelve, plus `Get-AzDoPipelineYaml`, public, two named sets, one example.
- **B-H3** `shows every named parameter set` — 1 of 2 red:
  `Get-AzDoPipelineYaml` again, whose one example shows `ByPath` and nothing
  demonstrates `ByDefinition`.

Bucket B, declared, none fixed and none weakened. Editing a scored commit to
satisfy an assertion written after it would destroy the only thing that commit
is good for. Five of the eight new assertions pass **clean** on it — synopsis,
description, `.PARAMETER`, the type doc block and the `about_` topic — including
on all twelve of those private functions.

### 8. Release v1.2.0 — done

Commit `dfacf77`. Three version strings (`plugin.json`, and both of
`marketplace.json`'s) to `1.2.0`; README pin to `@v1.2.0`; skill count 17 → 19
with two new table rows; `## 1.2.0` CHANGELOG entry written for someone who has
not read the repository, leading with the boundary rather than burying it.

Annotated tag created **after** the work it names, and pushed:

```
git tag -a v1.2.0 -F -   (message: the MINOR claim, the two new skills, the
                          measured effect unchanged, the boundary, the
                          falsification tallies, and the harness defect found)
git push origin v1.2.0   ->  * [new tag]  v1.2.0 -> v1.2.0
```

### 9. Docs, acceptance green, records — done

`docs/creating-an-agent/03-test-first-or-nothing.md` gains **section (f), *When
the thing you want to assert cannot be asserted*** — three responses to an
unassertable property, of which only one is honest, worked through the
class-help case. `docs/testing/README.md` covered in task 6. Commit `fa82731`.

## 6. Acceptance test — green

```
pwsh -NoProfile -Command "Invoke-Pester -Path ./plans/0039-ux-help-batch/accept.Tests.ps1 -Output Detailed"

  [+] the two new skills exist
  [+] ux skill cites its source and carries the cache guardrails
  [+] analyzer gained the class-candidate rule
  [+] docs skill carries the house example standard
  [+] plan skill owns the master plan
  [+] help assertions exist with falsification evidence
  [+] settings file support exists and is asserted
  [+] the denominator boundary is recorded
  [+] reference target still scores clean on the new suite
  [+] manifest is 1.2.0 with a CHANGELOG entry and v1.2.0 on the remote
Tests Passed: 10, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

Full output: [`accept-green.txt`](accept-green.txt).

## 7. Command transcript

```powershell
# --- preconditions
git status --porcelain
git rev-parse HEAD
git tag --list 'v1.*'
git ls-remote --tags origin 'v1.2.0*'
git checkout -b pass-0039-ux-help-batch

cd evals/conformance
./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph `
    -Tag Universal,Repository,HouseStyle,RequiresBuild `
    -ResultPath ../../plans/0039-ux-help-batch/pre-inventory.json
# cases-defined: 33  (HouseStyle=14, Repository=4, RequiresBuild=6, Universal=9)

# --- acceptance, red
pwsh -NoProfile -Command "Invoke-Pester -Path ./plans/0039-ux-help-batch/accept.Tests.ps1 -Output Detailed"
# Tests Passed: 0, Failed: 10
git commit -m "Write the pass 0039 acceptance test, and run it red"

# --- the ux skill's examples, executed before being written down
pwsh -NoProfile -File ./ux-check.ps1
# FULL : default,ci,local / NARROW: ci / EMPTY: count=0 / CLASS: ci

# --- the tidy sweep against the reference, then falsified
pwsh -NoProfile -Command "& ./skills/powershell-module-tidy/scripts/Invoke-ModuleTidy.ps1 -Path ../PSModuleGraph -Check Naming,Parity,DeadFile,PlanCurrency"
pwsh -NoProfile -File plans/0039-ux-help-batch/tidy-falsify.ps1 `
    -Harness $PWD -Reference ../PSModuleGraph -WorkDir C:/w39
# BREAKS: 7 / 7 red     CONTROLS: 6 / 6 green
git commit -m "Add powershell-module-ux and powershell-module-tidy, and falsify the sweep"

# --- the analyzer AST snippet and the class-help claim, both verified
pwsh -NoProfile -Command "...ConvertExpressionAst probe..."   # keys: A,B
pwsh -NoProfile -File ./clshelp2.ps1                          # 0 matches, HelpNotFoundException
git commit -m "Amend four skills: class candidate, enumerator, house example, master plan"

# --- help assertions, and the runner's two containers
cd evals/conformance
./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph -Tag Universal,Repository,HouseStyle,RequiresBuild
# cases-defined: 41  (HouseStyle=22, Repository=4, RequiresBuild=6, Universal=9)
pwsh -NoProfile -File plans/0039-ux-help-batch/help-falsify.ps1 -Harness $PWD -WorkDir C:/w39
# KNOWN-GOOD: 19 cases, 0 failing / PREFLIGHT: 12 / 12
# BREAKS: 7 / 7 red     CONTROLS: 5 / 5 green

# the container guard, falsified on its own
cp -r evals/conformance C:/w39/conf
./C:/w39/conf/Invoke-Conformance.ps1 -Path C:/w39/fx -Tag HouseStyle -ModuleName PSHelpFixture
# CONTROL: guard silent, 38 cases
printf '\nBeforeDiscovery { throw "deliberate discovery failure" }\n' >> C:/w39/conf/Help.Tests.ps1
./C:/w39/conf/Invoke-Conformance.ps1 -Path C:/w39/fx -Tag HouseStyle -ModuleName PSHelpFixture
# BREAK: guard fired, no result.json written
git commit -m "Add the help conformance block, and refuse to score a container that did not run"

# --- settings
pwsh -NoProfile -File plans/0039-ux-help-batch/settings-falsify.ps1 -Harness $PWD -Fixture C:/w39/fx
# 3 breaks fired, 3 controls held
git commit -m "Honour psmodule.settings.psd1, and refuse an unknown key by name"

# --- run 006 rescored, and the denominator re-derived on three shapes
cd evals/conformance
./Score-Clone.ps1 -Source https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git `
                  -Ref 70669167ea5f59a47efb282002052f9e926a34bf `
                  -WorkDir C:/w39/r6 -ResultPath C:/w39/r6-result.json
# SCORE 38 / 41, cases-run 128/154, build exit 0
./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph -Tag Universal,Repository,HouseStyle,RequiresBuild   # 41, run 477
./Invoke-Conformance.ps1 -Path C:/w39/fx -ModuleName PSHelpFixture -Tag Universal,Repository,HouseStyle,RequiresBuild  # 41, run 60
git commit -m "Rescore run 006 under the new suite, and set the v1.2.0 series boundary"

# --- release
git commit -m "Release 1.2.0 - two new skills, help conformance, and a settings file"
git commit -m "Document the checkable equivalent, and write the pass verification"
git push -u origin pass-0039-ux-help-batch
git tag -a v1.2.0 -F -   # message in full in the tag
git push origin v1.2.0

# --- acceptance, green
pwsh -NoProfile -Command "Invoke-Pester -Path ./plans/0039-ux-help-batch/accept.Tests.ps1 -Output Detailed"
# Tests Passed: 10, Failed: 0

# --- verification
pwsh -NoProfile -File ./plans/0039-ux-help-batch/verify.ps1
# VERIFY 0039: every check agrees.   exit 0
```

## 8. Diff summary

Full tier; the acceptance test above is the artifact. `git diff --stat
main..HEAD`: **32 files changed, 4414 insertions, 15 deletions**. The 15
deletions are the README pin, the skill-count words, the two `.claude-plugin`
version fields, one docs table row replaced by three, and the three lines the
runner's inventory call replaced.

## 9. Verify script

[`verify.ps1`](verify.ps1), committed beside this plan. It is too long to
reproduce here without risking a second copy that disagrees with the first —
hazard 6 applied to the one artifact whose job is to disprove this plan.

It re-derives rather than reads: it re-runs both falsification harnesses, it
re-scores the run-006 clone from the remote, it re-computes `cases-defined`
against two targets it **builds** rather than clones, and it compares what it
gets against the committed artifacts. It never parses this file.

Three places it is deliberately harder to satisfy than it needs to be:

- it checks the individual rows the prompt names (H1, H2, H5), not only the
  totals — a row flipping while the totals hold would otherwise pass;
- it asserts the two denominator targets produce **different** `cases-run`,
  because two targets of the same shape would make that check prove nothing;
- it checks every run-006 failure is one of the **three declared** ones, since
  a different failure of the same count would pass a count-only check.

`-SkipNetwork` reports `SKIPPED` and never `passed`.

```
=== Spot-check 1: the help falsification re-runs, red/green as recorded          OK
=== Spot-check 2: the settings triple re-fires                                   OK
=== Spot-check 3: cases-defined is 41 across differently shaped targets
    PSHelpFixture: cases-defined 41, cases-run 60
    PSShapeTwo:    cases-defined 41, cases-run 98                                OK
=== Spot-check 4: the run-006 clone rescores to 38 / 41 with 3 Bucket-B failures
    scored 38 / 41, cases-run 128/154, build exit 0                              OK
=== Spot-check 5: the v1.1.1..v1.2.0 diff is exactly what the release claims     OK
=== Constraint: no existing assertion weakened or removed                        OK

VERIFY 0039: every check agrees.
```

## 10. Deviations

**1. The tree was not clean at preconditions, and then it was.** An untracked
`.build copy.ps1` sat at the repository root — the operator's own crib for the
copy-paste-and-edit example convention, which is the source material for task
3's house `.EXAMPLE` standard. PLAN-PROTOCOL's rule is to commit such a change
on its own, before the pass, naming it as unrelated. That commit was attempted
and failed: **the file was deleted from disk between the precondition check and
the `git add`**, presumably by the operator, and the tree was clean at
`a01e079` by the time the branch was cut. Nothing was reverted, stashed or
carried. The file's content was already read and is what the docs standard is
written from; it is reproduced in the skill as the worked example.

**2. The prompt's suggested wording for the refscore headline does not satisfy
the prompt's own acceptance regex.** The prompt asks for
`RUN-006 CLONE (built): x / N, <k> new-rule failures Bucket B declared`, and the
regex is `RUN-006 CLONE \(built\): \d+ / \d+ .* Bucket B declared` — which
requires a **space** after the denominator, where the suggested wording puts a
comma. Written as suggested, the acceptance test fails; it did, on the first
green run (9/10). The regex is the specification and the prose example was
wrong, so the line reads `38 / 41 with 3 new-rule failures, all Bucket B
declared`, which says the same thing and matches. Noted in `refscore.txt` too.

**3. `Invoke-Conformance.ps1` had to change more than "add a file".** The runner
inventoried one named file and ran one named file. A second container would have
run its assertions while being absent from `cases-defined` — the numerator
growing while the denominator held still, which reads as an improvement and is a
bookkeeping error of exactly the kind `cases-defined` exists to prevent. The
runner now inventories and runs every `*.Tests.ps1` in the directory, sorted so
the figure does not depend on enumeration order. No assertion was touched.

**4. A defect found in this pass's own work, reported rather than absorbed: a
suite container that fails discovery was invisible.** When `Help.Tests.ps1` lost
its discovery to a member access on an empty array, **every one of its
assertions vanished from the run and the score printed as entirely normal** —
`cases-defined` still counted them, because it is parsed from source and does
not know a file failed to load, so numerator and denominator shrank together.
Pester reported `Container failed: 1` in its own output and nothing downstream
read it. The runner now hard-stops and writes no `result.json`. Falsified
separately: control silent, break fires, no result file. Keyed on the
container's `ErrorRecord` and **not** on its `Result`, because a container
holding a merely failing test also reports `Failed`, and turning every red run
into a crash is the opposite of what the runner promises three comments above.
This is a new LEDGER item.

**5. Two rules shipped in this pass contradicted each other.** Set coverage
looked for the `-Name` dash form; the house `.EXAMPLE` standard mandates
splatting. A conforming example never writes `-Name`, so the assertion was
unsatisfiable by exactly the examples it rewards. Nothing found it but building
a fixture to one rule and running the other against it — read side by side the
two look consistent. The general shape is worth keeping: **when one pass writes
both a convention and its assertion, they must be run against each other, not
reviewed against each other.**

**6. Three rules in `Invoke-ModuleTidy.ps1` were wrong on first contact with the
reference, and two of them were wrong in the direction that matters.** The
PascalCase rule failed `en-US`, a culture directory the build is *required* to
copy; the space rule failed a fixture whose purpose is a hostile path; and
`documented-unexported` never fired at all because it derived the command prefix
from the module name. The first two are now scoped, not exempted. The third was
inert and would have shipped green — caught only by the probe.

**7. The falsification target for the help assertions is a purpose-built
fixture, not the reference.** The protocol says break the reference. The
reference cannot serve here: it predates these rules and fails 219 of their
cases, so the case a break would turn red is already red. Recorded prominently
at the top of `help-falsification.txt` rather than left for a reader to notice.
The reference's standing behaviour under the new rules is task 7's whole
subject, so the two halves of the protocol are both satisfied — just by two
artifacts instead of one.

**8. `verify.ps1` defaults its work directory to `C:/v39`, an absolute path
outside the repository.** Not a preference: both the reference and the run-006
clone carry paths that exceed `MAX_PATH` under a long scratch root, and git
fails with `Filename too long` — a message that does not mention the length of
your temp directory. Three clone attempts were lost to this before the cause was
clear. The parameter is documented with that reason and no other.

**9. The prompt's task 3 names four amendments and task 8's CHANGELOG says
"five amended".** The fifth is `powershell-module-build`, whose amendment is
task 5's settings table. It is committed with the settings group rather than
with batch B, so the group boundary matches the work rather than the list.

## 11. Cost

Wall clock: approximately 2 hours 40 minutes, single session.

Runs produced:

| | |
|---|---|
| conformance suite runs | 14 (3 pre-change, 11 after) |
| falsification rows fired | **31** — 13 tidy, 12 help, 6 settings |
| container-guard probes | 2 (one control, one break) |
| builds invoked | 1 (the run-006 clone, exit 0) |
| clones taken | 4 (three lost to `MAX_PATH`, one scored) |
| acceptance runs | 2 (red, green) |
| verify runs | 1, exit 0 |

No token count: the agent cannot measure one from inside the session, and a
number without an artifact behind it does not belong in a plan.
