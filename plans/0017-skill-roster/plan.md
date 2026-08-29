# Pass 0017 — Skill roster, naming convention, tag debt, and the ordered test runner

Tier: **full** (the prompt says full, and it is: a new script, an amended
`evals/` runner, and thirteen skills).

## 1. Prompt

```
# PASS 0017 — Skill roster, naming convention, tag debt, and the ordered test runner
Tier: full

## Repositories

- `AI.Agent.Claude.PowerShellModuleBuilder` — all new content, on branch
  `pass-0017-skill-roster` cut from `4bcb0ed4fd25026cd48bed28fd2a8a92a35d5f15`.
- `PSAzureDevOpsGraph` — receives exactly one thing: annotated tag `v0.1.0`
  on existing commit `79e02fba9dffd976bccf507d531f59303cc58f9d`. No commits,
  no branches, no other changes.
- `PSModuleGraph` — read-only, from the clone under `scratch/` only
  (clone it there if absent). This pass is the extraction the reference
  exists for: read its build and test infrastructure and distill it into
  skills. Never modify it, never add it to the workspace, and ignore
  everything under its `.claude/skills/`.

## Preconditions — hard stop on failure

1. Harness HEAD `4bcb0ed4fd25026cd48bed28fd2a8a92a35d5f15`, tree clean
   (rule 13 if not). Create and switch to `pass-0017-skill-roster`.
2. `git ls-remote --tags` on PSAzureDevOpsGraph shows no `v0.1.0`;
   `git ls-remote` shows `run-002-first-build` at `79e02fb…`.
3. `skills/` contains exactly: module-scaffold, build-script, azdo-rest,
   pipeline-yaml-refs, graph-assembly. `decisions/` ends at 0005.
4. pwsh ≥ 7.2, Pester, git. Record versions. `$env:AZDO_PAT`: report
   set/unset only; nothing here needs it except the final validation's
   loud-skip path.

## Acceptance test — red first

`plans/0017-skill-roster/accept.Tests.ps1`, exactly this, run it, report red:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")

    Describe 'Pass 0017 delivered' {
        It 'renamed skills exist and old names are gone' {
            foreach ($s in 'powershell-module-scaffold','powershell-module-build',
                           'azdo-rest','azdo-pipeline-yaml-refs','azdo-graph-assembly') {
                Test-Path "$RepoRoot/skills/$s/SKILL.md" | Should -BeTrue
            }
            foreach ($s in 'module-scaffold','build-script','pipeline-yaml-refs','graph-assembly') {
                Test-Path "$RepoRoot/skills/$s" | Should -BeFalse
            }
        }
        It 'new roster exists' {
            foreach ($s in 'powershell-module-test','powershell-module-deploy',
                           'powershell-module-release','powershell-module-architect',
                           'powershell-module-analyzer','powershell-module-plan',
                           'powershell-module-docs','task-tree-reporting') {
                Test-Path "$RepoRoot/skills/$s/SKILL.md" | Should -BeTrue
            }
        }
        It 'ordered test runner ships as a script' {
            Test-Path "$RepoRoot/skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1" |
                Should -BeTrue
        }
        It 'plan intake template exists' {
            Test-Path "$RepoRoot/skills/powershell-module-plan/templates/module-plan.md" |
                Should -BeTrue
        }
        It 'decisions 0006 and 0007 exist' {
            Test-Path "$RepoRoot/decisions/0006-target-versioning-and-tags.md" | Should -BeTrue
            Test-Path "$RepoRoot/decisions/0007-skill-taxonomy-and-naming.md"  | Should -BeTrue
        }
        It 'v0.1.0 is on the module remote' {
            (git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git v0.1.0) |
                Should -Match '79e02fba9dffd976bccf507d531f59303cc58f9d|v0.1.0\^\{\}'
        }
        It 'ordered runner demonstrated fail-fast' {
            Get-Content "$RepoRoot/plans/0017-skill-roster/ordered-run-demo.txt" -Raw |
                Should -Match 'STOPPED AT LAYER'
        }
    }

## Plan

- [ ] 1. Acceptance red; report it.
- [ ] 2. **Pay the tag debt.** Create
      `decisions/0006-target-versioning-and-tags.md`, exactly:

          # 0006 — PSAzureDevOpsGraph keeps its files and is tagged per plan

          Operator-directed, 2026-08-29. From run 002 onward,
          PSAzureDevOpsGraph is no longer wipe-and-rebuild between plans:
          the module files persist in the repository, each plan commits its
          modifications there, and each plan that touches the target
          concludes with an annotated tag `v0.<minor>.0`, minor
          incrementing by one per such plan, message carrying the three
          scores. The operator's assistant assigns the minor number in the
          prompt, as it assigns pass numbers. Each tagged plan also writes
          `docs/worklog/v0.<minor>.0.md` in the target: thoughts,
          considerations, and decisions made while working, committed with
          the work so each tag carries its reasoning. This amends rule 14
          for exactly this case: the agent creates and pushes annotated
          tags on PSAzureDevOpsGraph when the pass prompt names the
          version. Rule 14 is otherwise unchanged — no `main`, no
          `Publish-Module`, no tags anywhere else.

          Wiped-state reliability runs (the three-consecutive bar) use
          `Reset-Target.ps1` into `scratch/` as before; the tagged
          repository is the deliverable line, scratch resets are the
          measurement line, and the two are never compared to each other.

          Applied retroactively: `v0.1.0` tagged onto run 002's commit
          `79e02fb` after the fact, because the directive predated the
          pass but did not reach its prompt.

      Then tag: `git tag -a v0.1.0 79e02fba9dffd976bccf507d531f59303cc58f9d
      -m "Plan 0016 first build — build exit 0, conformance 57/57,
      functional 12/12"` in a clone of PSAzureDevOpsGraph, push the tag,
      quote `git ls-remote --tags` output as evidence.
- [ ] 3. **Record the taxonomy.** Create
      `decisions/0007-skill-taxonomy-and-naming.md`, exactly:

          # 0007 — Skill taxonomy and naming

          Operator-directed, 2026-08-29. Skills generic to PowerShell
          module building are named `powershell-module-<role>`; skills
          specific to the Azure DevOps target are named `azdo-<role>`.
          Dots are not legal in skill names, which rules out the
          `powershell.module.x` form. Rule 9 governs the internal split:
          judgment is the SKILL.md, deterministic mechanics are scripts
          under the skill's `scripts/`, user entry points are commands.
          Renamed this pass: module-scaffold → powershell-module-scaffold,
          build-script → powershell-module-build, pipeline-yaml-refs →
          azdo-pipeline-yaml-refs, graph-assembly → azdo-graph-assembly.

          Rejected: `powershell.module.x` (illegal characters); putting
          the domain only in the plugin name (operator wants it readable
          in the skill list); one mega-skill per lifecycle (defeats
          on-demand loading and reviewability).

- [ ] 4. **Rename** the four skills with `git mv`, updating any references
      in commands and plugin.json.
- [ ] 5. **Author the roster.** Each is a directory with SKILL.md; scripts
      under `scripts/`; keep each SKILL.md tight and operational — what to
      do, in what order, with the sharp edges named. Extract real patterns
      from PSModuleGraph (`scratch/` clone) wherever it has one — its
      build script, analyzer settings, test layout, requirements handling —
      and from the conformance suite's assertions, which are the house
      rules in executable form. Cite the source file for anything
      extracted.
      - `powershell-module-build` (extend the renamed skill): the build
        engineer. InvokeBuild task structure, restore/lint/test/package
        order, PSScriptAnalyzer severity including ParseError (keep 0016's
        F-3 correction), coverage gate reading its own declared threshold,
        exit-code discipline.
      - `powershell-module-test`: the Pester engineer. Layered,
        dependency-ordered execution — and ship
        `scripts/Invoke-OrderedTests.ps1`, extracted from PSModuleGraph's
        test infrastructure: run layers in order (manifest parses → files
        parse → module imports → unit → integration/contract), stop at
        the first failing layer, print `STOPPED AT LAYER <name>` plus only
        that layer's failures. The point is one named failure instead of a
        wall of downstream red. Layer membership by directory convention
        and/or Pester tags; document both in the SKILL.md.
      - `powershell-module-deploy`: staging and output layout, what a
        publishable artifact contains, prerequisites verified before any
        deploy, and the standing rule that `Publish-Module` is
        operator-only, from the operator's shell, never the agent.
      - `powershell-module-release`: semver rules, release-notes
        aggregation by change type (major/minor/patch), changelog
        conventions, where notes live in-repo, what a release checklist
        verifies.
      - `powershell-module-architect`: command-surface design (verb-noun,
        one command one question), parameter design, pipeline support,
        when to split a command (the parse-vs-resolve split from BRIEF.md
        is the worked example), public/private function boundaries.
      - `powershell-module-analyzer`: AST-driven. Walk the module's AST for
        commands invoked, native executables referenced, modules required;
        for an external dependency it does not have knowledge of (the
        sqlpackage.exe case), research it at that moment — web
        documentation — and write a focused knowledge doc into the target
        at `docs/knowledge/<tool>.md` plus troubleshooting entries, so
        knowledge appears when a dependency appears and never before.
      - `powershell-module-plan`: intake and planning. A fixed question
        set for a new module (purpose, command surface, external systems,
        auth, constraints, definition of done); answers generate a plan
        file from `templates/module-plan.md` saved to the target at
        `docs/plans/NNNN-<slug>.md`; for a feature on an existing module,
        a shorter delta-plan variant. The template's definition-of-done
        section is mandatory and red-first: it must name how the work will
        be tested before the work starts.
      - `powershell-module-docs`: comment-based help standards, when
        platyPS, README structure for a module, examples that are real
        (runnable against something) rather than invented.
      - `task-tree-reporting`: response formatting during multi-skill
        work. Parent tasks as `## Task N — <name>`; each skill invocation
        under it as an indented `→ <skill-name>: <one-line what/why>`;
        nested invocations indent further; a closing status line per
        parent task. No colors — markdown structure only, so the tree
        survives transcripts and commits.
- [ ] 6. **Fix 0016's two named gaps.** `Invoke-Conformance.ps1` gains a
      sensible `-ModuleName` default (derive from the target's psd1) so a
      run directory works without the flag (F-8) — this is an evals change:
      falsify it (a directory whose psd1 name and folder name differ must
      still resolve; an ambiguous directory with two psd1s must hard-stop
      per rule 11, not guess). Correct `evals/conformance/README.md` where
      it documents a layout `Reset-Target.ps1` cannot produce.
- [ ] 7. **Validate the ordered runner against something real.** Clone
      `run-002-first-build` into `scratch/`, run `Invoke-OrderedTests.ps1`
      against it: all layers green, evidence captured. Then, in the
      scratch clone only — never committed anywhere — introduce a parse
      error in one src file and re-run: output must show
      `STOPPED AT LAYER files-parse` (or your layer's name) with exactly
      that file named and zero downstream noise. Save both outputs as
      `plans/0017-skill-roster/ordered-run-demo.txt`. Delete the sabotage
      with the scratch clone.
- [ ] 8. Update the harness root README's skill list and layout section to
      match the new roster — nothing else in it.
- [ ] 9. Acceptance green; report it. Plan (prompt verbatim, evidence,
      Deviations), verify script, `journal/0017-skill-roster.md`. Push
      `pass-0017-skill-roster`.

## Named spot-checks — verify.ps1 must re-derive

1. The nine roster paths and four absent old paths, from a fresh clone.
2. `Invoke-OrderedTests.ps1` re-run against a fresh clone of
   `run-002-first-build`: all layers green (PAT not needed; if any layer
   does need it, loud skip).
3. The fail-fast property re-derived, not read: verify re-introduces a
   parse error in its own scratch clone, asserts `STOPPED AT LAYER` and
   single-file naming, and cleans up.
4. `Invoke-Conformance.ps1` without `-ModuleName` against the scratch
   clone equals its result with the explicit flag; the two-psd1 ambiguity
   case hard-stops.
5. `git ls-remote --tags` shows v0.1.0 resolving to `79e02fb…`.
6. `evals/` diff this pass touches exactly two files:
   `Invoke-Conformance.ps1` and `conformance/README.md`.

Verify per decision 0004: SHA-pinned, `-FailCheck` probes, writes only under
`scratch/`, one script.

## Constraints

PSModuleGraph read-only from `scratch/`, cited when extracted, its
`.claude/skills/` ignored. No commits to PSAzureDevOpsGraph — the tag only.
No `main`, no `Publish-Module`, no other tags. PAT never echoed, written, or
in a URL. Assertions are never weakened; if the ordered runner exposes a
conformance defect, that is a finding.

## Deviations

Required. Especially: anything in PSModuleGraph's test infrastructure that
did not survive extraction and why; any skill whose content you could not
ground in either PSModuleGraph, the conformance suite, or the brief; and
anything in this prompt that was wrong.

## Report back

Pushed SHA; tag confirmation; the roster with one line each on what grounds
it; the ordered-runner demo output verbatim (both runs); the F-8
falsification results; and anything Deviations flagged.
```

## 2. Preconditions

All four passed. No stop.

**1. Harness HEAD and clean tree.**

```
$ git rev-parse HEAD
4bcb0ed4fd25026cd48bed28fd2a8a92a35d5f15
$ git status --porcelain
(empty)
$ git checkout -b pass-0017-skill-roster
Switched to a new branch 'pass-0017-skill-roster'
```

Rule 13 did not apply — the tree was clean.

**2. The module remote, before anything.**

```
$ git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
(no output — no tags at all)

$ git ls-remote https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
2c745310a97a551acc834e4b299a676536ea1f07	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	refs/heads/main
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/heads/run-002-first-build
```

No `v0.1.0`; `run-002-first-build` at `79e02fb…`. Both as required.

**3. `skills/` and `decisions/` contents.**

```
$ ls -1 skills/
azdo-rest
build-script
graph-assembly
module-scaffold
pipeline-yaml-refs

$ ls -1 decisions/
0001-universal-validated-against-corpus.md
0002-exports-no-implicit-wildcards-stays-universal.md
0003-score-comparability.md
0004-plan-artifacts-are-frozen.md
0005-branch-and-merge-policy.md
```

Exactly the five skills named; decisions end at 0005.

**4. Tooling.**

| Tool | Version |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| PSScriptAnalyzer | 1.25.0 |
| InvokeBuild | 5.14.23 |
| powershell-yaml | 0.4.12 |
| git | 2.41.0.windows.1 |
| OS | Windows 11 Home 10.0.26200 |

`$env:AZDO_PAT`: **set**. Nothing in this pass used it. Its value never
appeared in any command, artifact, or URL — see the scan in §5, task 9.

## 3. Environment

- Branch: `pass-0017-skill-roster`, cut from `4bcb0ed`
- HEAD at start: `4bcb0ed4fd25026cd48bed28fd2a8a92a35d5f15`
- Reference clone: `scratch/PSModuleGraph` at `d39b125`, read-only, never
  modified, `.claude/skills/` ignored throughout

## 4. Acceptance test — red first

`plans/0017-skill-roster/accept.Tests.ps1` was written exactly as the prompt
supplied it and run before any work.

```
$ pwsh -NoProfile -Command "Invoke-Pester ./plans/0017-skill-roster/accept.Tests.ps1 -Output Detailed"

Describing Pass 0017 delivered
  [-] renamed skills exist and old names are gone 154ms
   Expected $true, but got $false.
  [-] new roster exists 21ms
   Expected $true, but got $false.
  [-] ordered test runner ships as a script 18ms
   Expected $true, but got $false.
  [-] plan intake template exists 19ms
   Expected $true, but got $false.
  [-] decisions 0006 and 0007 exist 17ms
   Expected $true, but got $false.
  [-] v0.1.0 is on the module remote 1.36s
   Expected regular expression '79e02fba9dffd976bccf507d531f59303cc58f9d|v0.1.0\^\{\}'
   to match $null, but it did not match.
  [-] ordered runner demonstrated fail-fast 131ms
   Expected regular expression 'STOPPED AT LAYER' to match $null, but it did not match.

Tests Passed: 0, Failed: 7, Skipped: 0, Inconclusive: 0, NotRun: 0
```

**Red 0/7.** One of the seven — the remote-tag assertion — turned out to be
unpassable as supplied, for reasons unrelated to whether the tag exists. That
is deviation D-1 and it is the sharpest finding of this pass.

## 5. Tasks

### - [x] 1. Acceptance red; report it

Done, above. 0 passed, 7 failed.

### - [x] 2. Pay the tag debt

`decisions/0006-target-versioning-and-tags.md` created with the prompt's
content, verbatim, including its line breaks.

Tagged in a clone under `scratch/`, never in a working copy of the target:

```
$ git clone --no-single-branch https://github.com/.../PSAzureDevOpsGraph.git scratch/0017-target
$ git -C scratch/0017-target tag -l
(empty)
$ git -C scratch/0017-target tag -a v0.1.0 79e02fba9dffd976bccf507d531f59303cc58f9d \
    -m "Plan 0016 first build — build exit 0, conformance 57/57, functional 12/12"
$ git -C scratch/0017-target tag -l -n99 v0.1.0
v0.1.0          Plan 0016 first build — build exit 0, conformance 57/57, functional 12/12
$ git -C scratch/0017-target push origin v0.1.0
To https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
 * [new tag]         v0.1.0 -> v0.1.0
```

**Evidence — the remote after the push:**

```
$ git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}

$ git ls-remote https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
2c745310a97a551acc834e4b299a676536ea1f07	HEAD
2c745310a97a551acc834e4b299a676536ea1f07	refs/heads/main
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/heads/run-002-first-build
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}
```

The tag is annotated (it answers twice: the tag object `f1947c2…`, and
`^{}` peeling to the commit) and peels to `79e02fba…`. `main` and
`run-002-first-build` are byte-identical to the precondition reading — no
commits, no branches, nothing else changed.

### - [x] 3. Record the taxonomy

`decisions/0007-skill-taxonomy-and-naming.md` created with the prompt's
content, verbatim.

### - [x] 4. Rename the four skills

```
$ git mv skills/module-scaffold     skills/powershell-module-scaffold
$ git mv skills/build-script        skills/powershell-module-build
$ git mv skills/pipeline-yaml-refs  skills/azdo-pipeline-yaml-refs
$ git mv skills/graph-assembly      skills/azdo-graph-assembly
```

Git records all four as renames (`R`), so history follows the files.

References updated in six files: the `name:` frontmatter of each renamed
skill, the "Related" cross-references in all five original skills, and
`commands/build.md` (its description and three body references).

```
$ grep -rn "module-scaffold|build-script|pipeline-yaml-refs|graph-assembly" commands/ skills/ \
    | grep -vE "powershell-module-scaffold|powershell-module-build|azdo-pipeline-yaml-refs|azdo-graph-assembly"
(empty)
```

**`.claude-plugin/plugin.json` needed no change** — it names no skills. The
prompt anticipated one; see deviation D-5.

### - [x] 5. Author the roster

Thirteen skills. Nine new files, one extended, four renamed. What grounds each:

| Skill | Grounded in |
|---|---|
| `powershell-module-build` (extended) | `PSModuleGraph.build.ps1` (task graph, the coverage `throw` vs `CoveragePercentTarget`, the `Dependencies` version check), `PSScriptAnalyzerSettings.psd1`, `Requirements.psd1`, `build.ps1`; run 002 findings F-3, F-4, F-12 |
| `powershell-module-test` | `docs/testing.md` (Pester 6 traps, the enumerated assertion list, the `BeforeAll` error shape), `tests/TestHelpers.ps1`, `tests/PreTag.Tests.ps1`, `tests/Module.Quality.Tests.ps1`; the conformance suite's invocation assertion; run 002 F-6 |
| `powershell-module-deploy` | the `Build` and `Dependencies` tasks in `PSModuleGraph.build.ps1`; the four graded psm1 facts from the conformance suite; rule 14 and decision 0006 |
| `powershell-module-release` | `tests/PreTag.Tests.ps1` (all four gates, including the remote-tag and branch-ancestry checks and why they must not skip offline); `CHANGELOG.md`; decision 0006's worklog requirement |
| `powershell-module-architect` | `docs/development.md` (the three parameter sets, `Resolve-PSModuleTarget` centralisation, verbs and singular nouns, parameter shadowing); `BRIEF.md`'s parse-vs-resolve split; run 002 F-2 and F-6 |
| `powershell-module-analyzer` | `CLAUDE.md`'s core constraint (never run the analysed code) and its instruction-tier rule; `docs/development.md` on `ParseFile` vs `ParseInput`, memoisation, parse errors as data, `Import-PowerShellDataFile -ErrorAction Stop`; run 002 F-12 |
| `powershell-module-plan` | run 002 F-1 (the conventions the spec never stated) is the whole reason for §6 of the template; `PLAN-PROTOCOL.md`'s red-first rule and `METHOD.md`'s falsification rules for §7 |
| `powershell-module-docs` | the conformance suite's comment-based-help assertion; the culture-directory copy in `PSModuleGraph.build.ps1`; `CLAUDE.md`'s tier rule; run 002 F-12 |
| `task-tree-reporting` | **operator-specified format**; its content rules (cases-run beside cases-passed, zero cases is not a pass, never averaging two scores) come from `METHOD.md` and `commands/test.md`. See deviation D-4. |
| `powershell-module-scaffold` | unchanged except references |
| `azdo-rest`, `azdo-pipeline-yaml-refs`, `azdo-graph-assembly` | unchanged except references |

**The ordered runner**, `skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1`,
518 lines. Five layers, stop at the first failure, print only that layer's
failures. Layer membership by directory (`tests/Integration/`,
`tests/Contract/`) **and** by Pester tag (`Integration`, `Contract`), both
configurable, both documented in the SKILL.md. `INAPPLICABLE` is a distinct
result from `PASSED` because zero cases is not a pass. What did and did not
survive extraction from PSModuleGraph is deviation D-3.

### - [x] 6. Fix 0016's two named gaps

**F-8, the `-ModuleName` default.** Added to `Invoke-Conformance.ps1` only —
`Conformance.Tests.ps1` is untouched, so the suite's own two rules and its
deliberate absence of a third are unchanged.

The new rule is tried **last**, after both of the suite's rules have failed to
fire, and it is a positive claim about a known location rather than a
lone-candidate fallback: *exactly one candidate manifest under `<target>/src/`*.
That distinction is the whole design. The fallback this suite deleted —
"if exactly one candidate survives anywhere, take it" — once graded a vendored
`corpus/PSCorpus` module after the reference's own manifest was deleted, and it
is not coming back.

**Falsification.** Cases-run is stated for every run, because the repair
changes the denominator and the two percentages are then not measurements of
the same thing.

| Probe | Command | Result |
|---|---|---|
| **Before**, run dir, no flag | old runner, `-Tag Universal,Repository,HouseStyle` | **6 / 30 (20%)**, 24 assertions — the F-8 symptom |
| **After**, run dir, no flag | new runner, same tags | **51 / 51 (100%)**, 27 assertions |
| **After**, run dir, explicit flag | `-ModuleName PSAzureDevOpsGraph` | **51 / 51 (100%)**, 27 assertions |
| **Equality** | field-by-field | `Passed`, `CasesRun`, `ScorePct`, `Failed` all equal; the full 27-entry `Assertions` breakdown is byte-identical |
| **Ambiguity** | second manifest at `src/SecondModule/SecondModule.psd1` | **exit 1**, `Cannot derive -ModuleName: 2 manifests under '…\src', none preferred. Candidates: src\PSAzureDevOpsGraph\PSAzureDevOpsGraph.psd1; src\SecondModule\SecondModule.psd1. Pass -ModuleName to choose.` |
| **Ambiguity answerable** | same target, `-ModuleName PSAzureDevOpsGraph` | **51 / 51 (100%)** — rule 11 satisfied: it stops, and it says how to answer |
| **Control — the reference** | PSModuleGraph, old runner | 74 / 75 (98.67%), 27 assertions |
| **Control — the reference** | PSModuleGraph, new runner | **74 / 75 (98.67%), 27 assertions — identical** |
| **Control — the historical defect** | a copy of PSModuleGraph with its *own* manifest deleted, leaving only `corpus/PSCorpus/` | derivation **stayed silent**; 2 / 10, reporting `a module repository without a manifest has no identity`. It did **not** grade the vendored module. |

The last row is the one that matters. It is the polarity-correct control for
this change: the break is removing the thing the rule reads, and the required
outcome is that the runner reports absence rather than confidently grading
something else. The new rule looks only under `src/`, so with zero candidates
there it does not fire at all.

**The README correction.** `evals/conformance/README.md` documented
`-Path ./scratch/runs/<id>/PSAzureDevOpsGraph`. `Reset-Target.ps1` materialises
the seed **at** the destination, so the module is at `<id>/src/<Name>/` and
`<id>/<Name>/` has never existed. Corrected to `-Path ./scratch/runs/<id>`,
with a paragraph naming F-8 and a paragraph on the new default and its
ambiguity stop.

**`evals/` diff — exactly two files, as the prompt required:**

```
$ git diff --stat 4bcb0ed..HEAD -- evals/
 evals/conformance/Invoke-Conformance.ps1 | 83 ++++++++++++++++++++++++++++++++
 evals/conformance/README.md              | 17 ++++++-
 2 files changed, 99 insertions(+), 1 deletion(-)
```

No assertion was weakened, and `Conformance.Tests.ps1` was not touched.

### - [x] 7. Validate the ordered runner against something real

Full transcript in [`ordered-run-demo.txt`](ordered-run-demo.txt). Both runs
are against a fresh clone of `run-002-first-build` at `79e02fba…`.

**Run 1 — pristine, all layers green:**

```
LAYER manifest-parses  PASSED       1 case(s)
LAYER files-parse      PASSED       17 case(s)
LAYER module-imports   PASSED       1 case(s)  (PSAzureDevOpsGraph)
LAYER unit             PASSED       37 case(s)
LAYER integration      INAPPLICABLE 0 case(s)  (no test in Integration/Contract and none tagged Integration/Contract)

ALL LAYERS GREEN — 4 passed, 1 inapplicable.
  inapplicable (graded nothing, not a pass): integration
exit code: 0
```

37 unit cases, which is the same 37 run 002 recorded. No layer needed a PAT,
so the loud-skip path was not exercised — run 002's only PAT-related test sets
and restores the variable itself.

**Run 2 — one unclosed brace appended to
`src/PSAzureDevOpsGraph/Public/Get-AzDoPipelineReference.ps1`:**

```
LAYER manifest-parses  PASSED       1 case(s)
LAYER files-parse      FAILED       17 case(s)

STOPPED AT LAYER files-parse

  src\PSAzureDevOpsGraph\Public\Get-AzDoPipelineReference.ps1:65:16: Missing closing '}' in statement block or type definition.
  src\PSAzureDevOpsGraph\Public\Get-AzDoPipelineReference.ps1:64:29: Missing closing '}' in statement block or type definition.

NOT RUN (a failing layer is a precondition for these): module-imports, unit, integration
exit code: 1
```

Exactly one file named, both diagnostics from it, zero downstream output. The
build never ran, because `-Build` sits after `files-parse` by design.

**The contrast, and an honest correction to what I expected.** I expected
`./build.ps1` on the same tree to produce the wall of red F-3 describes. It does
not: run 002 already carries the F-3 correction, so its analyzer settings list
`ParseError` and `Lint` does go red. The real contrast is narrower and still
worth having — the build's 18 lines name three files
(`PSAzureDevOpsGraph.build.ps1` twice, `build.ps1` once) and **none of them is
the broken one**, while the findings table the `Lint` task writes goes to the
host and never reaches the captured stream. The ordered runner's single line is
the whole diagnosis. Both outputs are in the demo file.

**Cleanup.** The sabotage lived only in `scratch/0017-ordered`, which is not
committed, and was deleted with the clone immediately after the transcript was
taken. `PSAzureDevOpsGraph` received no commit.

### - [x] 8. Update the root README

Two edits, and nothing else in the file:

- A new `## The skills` section: all thirteen in one table, one line of role
  each, introduced by the naming rule from decision 0007 and the rule-9 split.
- The `Layout` table's `skills/` row now points at that roster instead of
  listing five names.

Deviation D-6 records a sentence elsewhere in this README that this pass has
made false and that the prompt's "nothing else in it" forbids fixing.

### - [x] 9. Acceptance green, plan, verify, journal, push

**Credential scan** across `skills/`, `decisions/`, `plans/0017-skill-roster/`,
`evals/`, `commands/` and `README.md`, before committing:

```
PAT scan: 0 matches
live PAT value present in artifacts: 0
```

The second line is a direct search for the value of `$env:AZDO_PAT` itself,
which is set on this machine. Zero occurrences.

## 6. Acceptance test — green

```
$ pwsh -NoProfile -Command "Invoke-Pester ./plans/0017-skill-roster/accept.Tests.ps1 -Output Detailed"

Describing Pass 0017 delivered
  [+] renamed skills exist and old names are gone 129ms
  [+] new roster exists 11ms
  [+] ordered test runner ships as a script 4ms
  [+] plan intake template exists 4ms
  [+] decisions 0006 and 0007 exist 5ms
  [+] v0.1.0 is on the module remote 566ms
  [+] ordered runner demonstrated fail-fast 10ms

Tests Passed: 7, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

**7/7 green** — with one assertion corrected mid-pass because it could not pass
as supplied. See D-1. The correction was itself falsified: against a
non-existent tag the assertion goes red, so it is not inert.

## 7. Command transcript

```powershell
# --- preconditions ---
git rev-parse HEAD
git status --porcelain
git checkout -b pass-0017-skill-roster
git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
git ls-remote https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
pwsh -NoProfile -Command "$PSVersionTable.PSVersion; (Get-Module -ListAvailable Pester | Sort-Object Version -Desc | Select -First 1).Version; git --version"

# --- acceptance, red ---
pwsh -NoProfile -Command "Invoke-Pester ./plans/0017-skill-roster/accept.Tests.ps1 -Output Detailed"

# --- task 2: the tag ---
git clone --no-single-branch https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git scratch/0017-target
git -C scratch/0017-target fetch origin run-002-first-build:run-002-first-build
git -C scratch/0017-target tag -l
git -C scratch/0017-target tag -a v0.1.0 79e02fba9dffd976bccf507d531f59303cc58f9d -m "Plan 0016 first build — build exit 0, conformance 57/57, functional 12/12"
git -C scratch/0017-target tag -l -n99 v0.1.0
git -C scratch/0017-target rev-parse "v0.1.0^{}"
git -C scratch/0017-target push origin v0.1.0
git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
git ls-remote https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git

# --- task 4: the renames ---
git mv skills/module-scaffold    skills/powershell-module-scaffold
git mv skills/build-script       skills/powershell-module-build
git mv skills/pipeline-yaml-refs skills/azdo-pipeline-yaml-refs
git mv skills/graph-assembly     skills/azdo-graph-assembly

# --- task 7: the ordered runner, green then red ---
git clone --branch run-002-first-build --single-branch https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git scratch/0017-ordered
git -C scratch/0017-ordered rev-parse HEAD
pwsh -NoProfile -File skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1 -Path scratch/0017-ordered -Build
# (parse error appended to src/PSAzureDevOpsGraph/Public/Get-AzDoPipelineReference.ps1)
pwsh -NoProfile -File skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1 -Path scratch/0017-ordered -Build
pwsh -NoProfile -File scratch/0017-ordered/build.ps1
rm -rf scratch/0017-ordered

# --- task 6: F-8 falsification ---
git clone --branch run-002-first-build --single-branch https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git scratch/0017-f8/002-first-build
git show HEAD:evals/conformance/Invoke-Conformance.ps1 > scratch/0017-f8/old-runner/Invoke-Conformance.ps1
cp evals/conformance/Conformance.Tests.ps1 scratch/0017-f8/old-runner/
pwsh -NoProfile -Command "& './scratch/0017-f8/old-runner/Invoke-Conformance.ps1' -Path scratch/0017-f8/002-first-build -Tag Universal,Repository,HouseStyle -ResultPath scratch/0017-f8/before.json"
pwsh -NoProfile -Command "& './evals/conformance/Invoke-Conformance.ps1' -Path scratch/0017-f8/002-first-build -Tag Universal,Repository,HouseStyle -ResultPath scratch/0017-f8/derived.json"
pwsh -NoProfile -Command "& './evals/conformance/Invoke-Conformance.ps1' -Path scratch/0017-f8/002-first-build -ModuleName PSAzureDevOpsGraph -Tag Universal,Repository,HouseStyle -ResultPath scratch/0017-f8/explicit.json"
# (second manifest created at src/SecondModule/SecondModule.psd1)
pwsh -NoProfile -Command "& './evals/conformance/Invoke-Conformance.ps1' -Path scratch/0017-f8/002-first-build -Tag Universal -ResultPath scratch/0017-f8/ambiguous.json"
pwsh -NoProfile -Command "& './evals/conformance/Invoke-Conformance.ps1' -Path scratch/0017-f8/002-first-build -ModuleName PSAzureDevOpsGraph -Tag Universal,Repository,HouseStyle -ResultPath scratch/0017-f8/ambiguous-answered.json"
pwsh -NoProfile -Command "& './evals/conformance/Invoke-Conformance.ps1' -Path scratch/PSModuleGraph -Tag Universal,Repository,HouseStyle -ResultPath scratch/0017-f8/ref-new.json"
pwsh -NoProfile -Command "& './scratch/0017-f8/old-runner/Invoke-Conformance.ps1' -Path scratch/PSModuleGraph -Tag Universal,Repository,HouseStyle -ResultPath scratch/0017-f8/ref-old.json"
# (copy of PSModuleGraph with its own manifest deleted, leaving corpus/PSCorpus/)
pwsh -NoProfile -Command "& './evals/conformance/Invoke-Conformance.ps1' -Path scratch/0017-f8/ref-copy/PSModuleGraph -Tag Universal -ResultPath scratch/0017-f8/ref-nomanifest.json"

# --- the acceptance-test defect, diagnosed ---
git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git v0.1.0
git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git 'v0.1.0*'

# --- credential scan, acceptance green, verify ---
git diff --stat 4bcb0ed..HEAD -- evals/
pwsh -NoProfile -Command "Invoke-Pester ./plans/0017-skill-roster/accept.Tests.ps1 -Output Detailed"
pwsh -NoProfile -File plans/0017-skill-roster/verify.ps1
pwsh -NoProfile -File plans/0017-skill-roster/verify.ps1 -FailCheck
```

## 8. Verify script

[`verify.ps1`](verify.ps1), beside this plan. It is too long to reproduce here
without risking a second copy that disagrees with the first — PLAN-PROTOCOL §9,
and hazard 6 in `evals/HARNESS.md`.

It re-runs all six named spot-checks by name, re-deriving rather than reading:
it clones this repository to check the roster, clones `run-002-first-build` to
re-run the ordered runner, **introduces its own parse error** and asserts the
break landed before re-running, verifies the restoration, re-runs both
conformance invocations and compares the full per-assertion breakdown, builds
its own two-manifest ambiguity case, reads the remote tag, and counts the
`evals/` diff. It creates and removes `scratch/verify-0017` itself and never
assumes `scratch/` exists. `-FailCheck` runs four probes.

It is SHA-pinned per decision 0004 and prints a drift notice when HEAD has
moved.

```
$ pwsh -NoProfile -File plans/0017-skill-roster/verify.ps1
checks: 66   failures: 0   skipped: 0
VERIFY OK

$ pwsh -NoProfile -File plans/0017-skill-roster/verify.ps1 -FailCheck
checks: 75   failures: 0   skipped: 0
VERIFY OK
```

The four probes re-run the checks rather than restating the sabotage. Probe A
removes a roster skill and re-runs check 1's own `Measure-RosterDisagreement`,
asserting it goes red **and names that skill**; probe B resurrects a retired
name, which is the scope control — a check that only counted missing skills
would stay green there. Both re-assert known-good before the break and verify
the restoration after it.

**One deliberate difference from the acceptance test.** Spot-check 5 asserts the
tag peels to `79e02fb…` — the **commit**. The acceptance test's regex is an
alternation, so its `v0.1.0^{}` branch is satisfied by any annotated tag of that
name whatever it points at. The prompt's regex was kept verbatim in the
acceptance test; the real property is pinned here.

## 9. Deviations

**D-1. The acceptance test as supplied cannot pass. Corrected, minimally.**

This is the most important item in this section. The assertion

```powershell
(git ls-remote --tags <url> v0.1.0) | Should -Match '79e02fba…|v0.1.0\^\{\}'
```

is red for a correctly created, correctly pushed annotated tag, for two
compounding reasons:

1. `git ls-remote` matches a pattern against the **tail of the ref name**, and
   the peeled entry's name is `refs/tags/v0.1.0^{}`. Asking for `v0.1.0`
   therefore returns **only the tag object** — `f1947c28…`, the SHA of the tag
   itself — and never the commit. Neither alternative in the regex can appear.
2. Even with both lines returned, `Should -Match` tests **each element** of a
   piped array and fails on the first that does not match. The tag-object line
   matches neither alternative, so it fails.

Demonstrated:

```
$ git ls-remote --tags <url> v0.1.0
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0        <- one line only

$ git ls-remote --tags <url> 'v0.1.0*'
f1947c28f80389eacc356a1f1c6470c77615fbfc	refs/tags/v0.1.0
79e02fba9dffd976bccf507d531f59303cc58f9d	refs/tags/v0.1.0^{}     <- both

ARRAY PIPED: fail -> ...to match 'f1947c28...	refs/tags/v0.1.0', but it did not match.
JOINED:      pass
```

**PSModuleGraph's own `tests/PreTag.Tests.ps1` documents this exact trap**, in a
comment beginning *"THREE patterns, and no `--tags`"* — the reference had
already paid for this lesson. Cited in the corrected test.

**What I changed, and what I did not.** The regex is the prompt's, unchanged.
The pattern became `'v0.1.0*'` and the lines are joined. The correction and its
reasoning are recorded in a comment in `accept.Tests.ps1` itself, so a reader
diffing it against the prompt finds the explanation in place. I then falsified
the corrected assertion — against a non-existent tag it goes red — because a
corrected assertion that has only ever been green is exactly the defect this
project exists to catch.

**A residual weakness I did not fix.** The regex is an alternation, so the
`v0.1.0^{}` branch is satisfied by *any* annotated tag named `v0.1.0`, whatever
commit it points at. The assertion proves the tag exists, not where it points.
I left it — narrowing it would be rewriting the prompt's assertion rather than
repairing it — and pinned the commit in `verify.ps1` instead, which is where the
prompt asked for that property anyway (spot-check 5).

**D-2. The prompt's own count of the roster is inconsistent, and I followed the
lists rather than the number.** Spot-check 1 says "the nine roster paths". The
acceptance test checks five renamed plus eight new = **thirteen** skills, and
task 5 names nine roles under "author the roster" while also extending a tenth.
I built and verified all thirteen. `verify.ps1` additionally asserts that
`skills/` holds *exactly* those thirteen, so a stray leftover directory fails as
loudly as a missing one.

**D-3. What did not survive extraction from PSModuleGraph, and why.**

The prompt describes `Invoke-OrderedTests.ps1` as "extracted from PSModuleGraph's
test infrastructure". **PSModuleGraph has no such script**, and I want that on
the record rather than implied. What it has, and what the runner is distilled
from:

- **The InvokeBuild task graph is the ordering.** `task Test Build, Dependencies`
  and `task . Clean, Lint, Build, Test` already express "each stage is a
  precondition for the next, and a failure stops the rest". The runner makes
  that explicit for tests specifically, at a finer grain, and below the level
  where a build can run at all.
- **The precondition-throw pattern** from `Module.Quality.Tests.ps1`
  (`throw "Built module not found... Run ./build.ps1 first."`) and from the
  `Dependencies` task's named, ordered, hinted throw. That is where the
  runner's "no importable module — run ./build.ps1, or pass `-Build`" comes
  from.
- **The cascade this exists to prevent** is documented twice: `docs/testing.md`
  on a `BeforeAll` failure surfacing as an unrelated `break`/`continue` message
  across a whole `Describe`, and run 002's F-3, where one unparseable file
  produced nine downstream import errors.
- **Layer membership by tag** is the `PreTag` split, generalised.
- **Layer membership by directory** is `tests/Public` and `tests/Private`
  mirroring `src/`, generalised.

**What did not survive, and why:**

- **`tests/Corpus/`, the golden-file suites, and the knowledge-store tests** are
  specific to what PSModuleGraph *is* — an analyser with a corpus and a
  generated knowledge store. There is nothing to generalise.
- **`Import-PSModuleGraphUnderTest`'s built-then-src fallback** is in the runner
  in spirit, but PSModuleGraph has a dev-loader `src/<Name>.psm1` and
  PSAzureDevOpsGraph does not, so the fallback cannot fire for the target this
  pass validated against. That is why `-Build` exists and why its absence is a
  loud, named failure rather than a silent one.
- **The `Knowledge` and `Import` tasks** are repository-specific and were not
  extracted.
- **`Instructions.Tests.ps1`, the always-loaded byte ceiling.** Genuinely
  interesting and deliberately left out: it enforces a budget on an agent
  instruction tier, which is a property of how PSModuleGraph is *worked on*, not
  of PowerShell module testing. Recording it here because it is the one thing I
  read, wanted, and decided against.
- **`Should-BeFasterThan` / performance assertions** exist in Pester 6 and in
  the reference's vocabulary list, but no layer uses them; a performance layer
  with no cases would be a layer that always reports inapplicable.

**D-4. One skill I could not fully ground.** `task-tree-reporting` is a
**format the operator specified**, and neither PSModuleGraph, the conformance
suite, nor `BRIEF.md` contains anything resembling it. I implemented the format
as described and grounded only what could be grounded: the *content* rules —
cases-run beside cases-passed, zero cases is not a pass, never averaging two
scores, never a figure without an artifact — all come from `METHOD.md`,
`decisions/0003-score-comparability.md`, and `commands/test.md`. The tree shape
itself rests on the prompt alone.

Two smaller cases, flagged for the same reason:

- **`powershell-module-release`'s semver table** is standard practice plus this
  project's own evidence for two rows (the "adding a property is minor" rule
  comes from run 002's comparator failing on a single extra field). The other
  rows are conventional and are not grounded in an artifact here.
- **`powershell-module-docs`'s platyPS section** is grounded in the *absence* of
  platyPS from PSModuleGraph, which uses comment-based help throughout. I made
  that absence the recommendation and named the three conditions that would
  change it. That is a judgment call, stated as one.

**D-5. `.claude-plugin/plugin.json` names no skills**, so task 4's "updating any
references in commands and plugin.json" had nothing to do there. `commands/build.md`
did, and was updated. No change to `plugin.json` was needed or made.

**D-6. The prompt's "nothing else in it" leaves a now-false sentence in the root
README, and I left it.** `README.md` says:

> `-ModuleName` is not optional when the repository root is a run directory —
> discovery prefers a manifest named for the target directory and refuses to
> guess rather than grade the wrong module silently.

Task 6 made the first clause false. Task 8 restricts me to the skill list and
layout section. I followed the instruction and am flagging it rather than
silently obeying or silently exceeding scope. **`commands/test.md` carries the
same now-stale guidance** in its step 2 and its "Pass `-ModuleName` whenever the
repository root is not named for the module" paragraph; the prompt does not
mention that file at all, so I left it too. Both are one-line fixes for a
follow-up pass.

**D-7. The `evals/README` correction is a documentation fix to a defect that
`Reset-Target.ps1` could equally have fixed.** F-8's remedy offered two options:
change `Reset-Target.ps1` to create `<destination>/<ModuleName>/`, or make the
runner accept the name. The prompt chose the runner. I note that the other half
is now closed by documentation only — `Reset-Target.ps1` still materialises the
seed at the destination, which is the behaviour the corrected README now
describes, so nothing is inconsistent. Recording the choice because the finding
named two and only one was taken.

**D-8. The repository numbers its standing rules inconsistently, and the prompt
inherits it.** "Rule 9" means *mechanism selection* in `runs/002-first-build/findings.md`
and in this prompt's decision 0007 text, but means *zero cases is not a pass* in
`decisions/0001` and `journal/0007`. Both readings appear in committed
artifacts. I used the prompt's reading, which matches `findings.md`. There is no
committed file that numbers the rules, so neither usage can be checked; worth
one pass to write the list down.

**D-9. The `Lint`-versus-`files-parse` contrast is weaker than I expected, and I
have said so above rather than presenting the stronger version.** See task 7.

**D-11. A defect I introduced and caught, recorded because it is this project's
own failure mode.** The first version of `verify.ps1`'s roster evaluator ended
`, $problems`. The unary comma wraps the array, so an **empty** result reached
the call site as one element that was an empty array — and the check reported
`1 disagreement(s)` with a blank line where the disagreement's name should have
been. It failed toward the alarming answer, which is the direction that gets
noticed, and it was found immediately. Had the polarity been reversed it would
have been a check that could not go red. Fixed to `return $problems`, with the
reason in a comment at the site. The strengthened probes are what exposed it:
the first probe run reported six failures including a *baseline* failure, and a
baseline that fails before any break is a broken probe, not a broken repository.

**D-10. Nothing else in the prompt was wrong.** The preconditions were accurate,
the target SHAs were correct, the tag message was well-formed, and the two
decision texts transcribed cleanly.

## 10. Cost

- Wall clock: approximately 2 hours 10 minutes, single session.
- Conformance suite runs: **9** (1 before-state, 2 on the run directory, 1
  ambiguity stop, 1 ambiguity answered, 2 reference controls, 1 deleted-manifest
  control, 1 re-run to check the derivation stayed silent).
- Ordered-runner invocations: **4** (2 for the demo transcript, 2 exploratory).
- Module builds invoked: **3** (twice via the runner's `-Build`, once for the
  contrast).
- Pester acceptance runs: **3** (red, red-with-the-defect, green).
- Git clones made: **5**, all under `scratch/`, all removed except
  `scratch/PSModuleGraph` and `scratch/0017-target`.
- Pushes: **1 tag** to `PSAzureDevOpsGraph`, **1 branch** to this repository.

No token count: the agent cannot measure one from inside the session, and a
number without an artifact behind it does not belong in a plan.
