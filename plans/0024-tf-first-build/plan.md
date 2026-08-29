# Pass 0024 — PSTerraformGraph first build, with the plugin, scored

Tier: full. Executed 2026-08-29 as the third pass of the recovery batch.

## 1. Prompt

Reproduced in the batch issue that carried it. Its sections: Repositories
(PSTerraformGraph branch `pass-0024-first-build` from `main`
`b6e8dd871b6b780331e58fd634b1a4d3b1fc7bbf`, first tag `v0.1.0`; harness run
record `runs/tf-001-first-build` on branch `pass-0024-tf-first-build`;
PSGraphRenderToHtml v0.1.0 and PSGraphRender v0.13.0 read-only), Preconditions
(sync, SHAs recorded, clean trees, the plugin SHA pinned into the run record,
fresh fixture clones under `scratch/tf-fixture/`), the acceptance test quoted
below, an eight-task plan, five named spot-checks, and the constraints: no
terraform binary, fixture and oracle read-only, dependencies read-only except
the named README lines, no assertion weakened anywhere.

**Start condition.** The prompt says to start only if 0022 and 0023 are green.
Both were: 0022 closed with acceptance 6/6 and verify 17/17, 0023 with
acceptance 5/5 and verify 13/13.

The acceptance test, exactly as given and as written:

```powershell
#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..",
      [string]$T = "$PSScriptRoot/../../../PSTerraformGraph")
Describe 'Pass 0024 delivered' {
    It 'module builds and exports the surface' {
        $m = Import-Module "$T/src/PSTerraformGraph/PSTerraformGraph.psd1" -Force -PassThru
        $m.ExportedCommands.Keys | Should -Contain 'Get-TfConfigurationGraph'
        $m.ExportedCommands.Keys | Should -Contain 'Export-TfConfigurationGraphHtml'
    }
    It 'run record complete' {
        $r = Get-Content "$RepoRoot/runs/tf-001-first-build/README.md" -Raw
        $r | Should -Match 'plugin-sha:\s*[0-9a-f]{40}'
        $r | Should -Match 'build:\s*exit \d+'
        $r | Should -Match 'functional-tf:\s*\d+\s*/\s*\d+'
        $r | Should -Match 'not the generalisation measurement'
    }
    It 'graph artifacts exist' {
        Test-Path "$RepoRoot/runs/tf-001-first-build/graph.json" | Should -BeTrue
        (Get-ChildItem "$RepoRoot/runs/tf-001-first-build" -Filter *.html).Count |
            Should -BeGreaterOrEqual 3
    }
    It 'v0.1.0 on the remote' {
        (git ls-remote --tags https://github.com/JerryBalmer1/PSTerraformGraph.git 'v0.1.0*') |
            Should -Not -BeNullOrEmpty
    }
}
```

## 2. Preconditions

**Branches and SHAs.** PSTerraformGraph `pass-0024-first-build` from `main`
`b6e8dd871b6b780331e58fd634b1a4d3b1fc7bbf`, exactly as the prompt names.
Harness `pass-0024-tf-first-build` from `main`
`0c9d8c059564c153c90062b87425cb9b7cee742f`.

**Plugin SHA, pinned.** `0c9d8c059564c153c90062b87425cb9b7cee742f` — harness
`main` at the moment the pass began — written into the run record and asserted
by both the acceptance test and `verify.ps1`.

**Fresh fixture clones** into `scratch/tf-fixture/`, straight from AzDO:

```
TfFixtureShared      0af6ee33854bedb4147d0b13cc6db1311687775b  13 files
TfFixtureNetwork     24f27be92e583b6dfc9208bca42f8ec0baf5004b  14 files
TfFixtureApp         187ff229c0ad908eb39822f1bb78b6c0e3a206b3  13 files
```

Identical to the SHAs pass 0023's read-back verified. `scratch/` is gitignored
and is not committed.

**No terraform binary** was installed or invoked at any point in the pass.

## 3. Environment

pwsh 7.6.5, Pester 6.1.0, InvokeBuild 5.14.23, PSScriptAnalyzer, git
2.41.0.windows.1, Windows 11 Home 10.0.26200.

## 4. Acceptance test — red first

```
  [-] module builds and exports the surface 274ms
  [-] run record complete 39ms
  [-] graph artifacts exist 28ms
  [-] v0.1.0 on the remote 648ms
Tests Passed: 0, Failed: 4, Skipped: 0, Inconclusive: 0, NotRun: 0
```

## 5. Tasks

- [x] **1. Acceptance red.** Above, 4/4.

- [x] **2. Scaffold with the plugin.** Layout, `build.ps1`,
      `PSTerraformGraph.build.ps1` and the Pester configuration follow
      `powershell-module-scaffold`, `-build` and `-test`: five tasks by name, a
      default of exactly `Clean, Lint, Build, Test`,
      `Severity = @('ParseError','Error','Warning')`, `Run.Throw` and never
      `Run.Exit`, `Should.DisableV5`, `Filter.ExcludeTag = 'PreTag'`, coverage
      against the built psm1 with the threshold read back off the result.

      Architecture decided before any code: **parse, model, resolve as three
      stages**, on the AzDO brief's parse-versus-resolve precedent.

- [x] **3. The HCL parser.** `ConvertFrom-HclToken` is a character-by-character
      lexer; `ConvertFrom-HclDocument` is a recursive-descent block parser.
      Between them they handle quoted strings with escapes and interpolation,
      heredocs including the `<<-` form, `#`, `//` and `/* */` comments,
      significant newlines, and the distinction between a block and an
      attribute whose value is an object. Every token carries its line, and
      unparseable input throws naming file and line.

      Proved against the real fixture before anything was built on it:

      ```
      parsing 30 .tf files
      ...
      parse failures: 0
      ```

- [x] **4. Graph assembly and rendering delegation.**
      `Get-TfConfigurationGraph` emits the producer-contract shape;
      `Export-TfConfigurationGraphHtml` composes it with
      `Export-ProducerGraphHtml` and builds the editor-link map from the paths
      the graph already carries rather than walking the tree twice.

- [x] **5. Scored against the frozen oracle. Three iterations, the cap.**

      | # | Differences | Nodes | Edges | What changed |
      | --- | --- | --- | --- | --- |
      | 1 | 94 | 78 / 78 | 15 / 57 | first run |
      | 2 | 68 | 78 / 78 | 17 / 57 | local paths were matching the registry-address pattern; `required_providers` is a block, not an attribute |
      | 3 | 31 | 78 / 78 | 54 / 57 | the parser spaces out an expression, so every reference pattern missed |

      Then scored by the fixture's seven named cases, because 28 of the 31
      remaining differences are one mechanism repeated:

      ```
      1 nested-module chain          PASS
      2 cross-repo source            PASS
      3 cross-repo output ref        FAIL
      4 provider version pin         PASS
      5 traceability chain           PASS
      6 unused variable absence      PASS
      7 unresolved module source     PASS

      functional-tf: 6 / 7
      ```

      Nothing under `evals/tf/fixture/` was edited. The oracle blob SHA is
      asserted unchanged by `verify.ps1`.

- [x] **6. Renders and the run record.** Three layouts, one ThreadJob each:

      ```
        callflow        675614 bytes   marker=True  vscode-link=True
        foundation      675616 bytes   marker=True  vscode-link=True
        testorder       675615 bytes   marker=True  vscode-link=True
      3 layouts rendered concurrently on ThreadJob.
      ```

      `runs/tf-001-first-build/README.md` carries the pinned plugin SHA, the
      fixture SHAs, the three score lines, the iteration table, the wall-clock
      with degree of parallelism, and the sentence the acceptance test requires.
      `findings.md` sorts by mechanism: four places the `powershell-module-*`
      skills were wrong or silent for a non-AzDO target, three candidate
      `tf-<role>` skills, two fixture defects and one unfixed producer gap.

- [x] **7. Module records, tag, push, fan-out.** `docs/HANDOFF.md`,
      `README.md`, `docs/worklog/v0.1.0.md`. Build green (33 tests, 83.40%).
      Annotated `v0.1.0`. Ancestry checked before every `main` move:

      ```
      PSTerraformGraph     main 05fb60d5286e99b302afbfaf5eee87c866ecd14c  v0.1.0^{} identical
      PSGraphRenderToHtml  main 20877f759176b47bd62a0e0439e0e26a47239c64
      PSGraphRender        main 2231b4bd9905a9392e4ed3e3637b777f1768fd6a
      ```

- [x] **8. Acceptance green, harness records.**

## 6. Acceptance test — green

```
  [+] module builds and exports the surface 405ms
  [+] run record complete 18ms
  [+] graph artifacts exist 21ms
  [+] v0.1.0 on the remote 563ms
Tests Passed: 4, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

## 7. Command transcript

```bash
git -C PSTerraformGraph checkout -b pass-0024-first-build main
git checkout -b pass-0024-tf-first-build main            # plugin SHA 0c9d8c0
pwsh -NoProfile -Command 'Invoke-Pester plans/0024-tf-first-build/accept.Tests.ps1'   # 0/4
pwsh -NoProfile -File scratchpad/clonefix.ps1            # three fixture clones

# module written: tokenizer, parser, model, resolver, assembler, two commands
pwsh -NoProfile -File scratchpad/parse1.ps1              # 30 files, 0 parse failures
pwsh -NoProfile -File scratchpad/score.ps1               # iteration 1: 94
# registry-vs-relative guard, required_providers block form
pwsh -NoProfile -File scratchpad/score.ps1               # iteration 2: 68
# reference patterns made whitespace-tolerant
pwsh -NoProfile -File scratchpad/score.ps1               # iteration 3: 31
pwsh -NoProfile -File scratchpad/cases.ps1               # functional-tf 6 / 7

pwsh -NoProfile -Command './build.ps1'                   # 33 passed, 83.40%
pwsh -NoProfile -File scratchpad/render.ps1              # 3 layouts, ThreadJob

git add <paths, individually> && git commit -F - && git push -u origin pass-0024-first-build
git tag -a v0.1.0 -m '...' && git push origin v0.1.0
git merge-base --is-ancestor origin/main pass-0024-first-build
git checkout main && git merge --ff-only pass-0024-first-build && git push origin main

# consumer fan-out, one branch each, ancestry checked
cd PSGraphRenderToHtml && git checkout -b pass-0024-consumer-ref main && ... && git push origin main
cd PSGraphRender        && git checkout -b pass-0024-consumer-ref main && ... && git push origin main

pwsh -NoProfile -Command 'Invoke-Pester plans/0024-tf-first-build/accept.Tests.ps1'   # 4/4
pwsh -NoProfile -File plans/0024-tf-first-build/verify.ps1                            # 12 checks, 0 failed
```

## 9. Verify script

`plans/0024-tf-first-build/verify.ps1`, committed beside this plan.

It clones **all three** repositories at their tags, builds the two
dependencies (the renderer must be built, not merely cloned), builds the
subject, regenerates the graph from the committed fixture, re-scores it against
the frozen oracle, and re-renders a layout checking both its marker and a
`vscode://file/` link. It asserts the **oracle blob SHA is unchanged** first,
because every score below it is against that file. Its AzDO half re-clones the
fixture and queries the project's whole build history, and skips loudly without
a PAT.

```
12 check(s), 0 failed, 0 skipped.
```

## 10. Deviations

**1. Three defects were found, and all three failed silently.** A local path
`./modules/service` matches the Terraform registry pattern
`namespace/name/provider` exactly, so every nested module resolved to a registry
address that does not exist. `required_providers` is a block and not an
attribute, so no provider was found at all. And the parser rebuilds an
expression by joining tokens, so `var.tags` arrives as `var . tags`. None
produced an error, a warning, or an obviously empty result. The oracle is the
only thing that found them.

**2. Case 3 of the fixture cannot be passed by any parser.** It ties
TfFixtureApp's `var.network_segment_id` to TfFixtureNetwork's
`output.segment_id` through the variable's **description** — prose. Nothing in
the HCL states it. This is the only case a single-repository parser could not
see, so the case the three-repository fixture was built for is the one that does
not work. **The fixture is frozen by decision 0011 and was not edited.**
Recorded as a finding with a suggested repair for a future decision: a
`terraform_remote_state` data source, or a module block that actually passes the
output, would make the tie mechanical.

**3. 28 of the 31 remaining differences are one convention mismatch, not 28
defects.** The oracle omits `hasValidation` where a variable has no validation
block; the producer writes `hasValidation: false`. Absent versus false. The
producer contract says an absent optional field means NOT STATED, which argues
the oracle is right and the producer should omit it. Not changed: the iteration
cap was reached and it should be settled once in the contract rather than
per-producer.

**4. One genuine gap was left unfixed on purpose.** `module.subnet[*].id` — the
reference extractor does not handle the splat between name and member, so one
edge is missing. One pattern to widen. The cap was three iterations and the
score was taken; a defect quietly fixed after the measurement makes the
measurement a different thing. Recorded in `findings.md` and in the module's
HANDOFF.

**5. Scored by case as well as by raw difference count.** The prompt asks for
`functional-tf: N / N`. A raw count of 31 reads as 31 defects and is three
mechanisms, so the score reported is against the fixture's seven named cases —
**6 / 7** — and the raw count is reported beside it. Both numbers are in the run
record.

**6. The acceptance test needed a dependency installed, as in pass 0022.**
`Import-Module` enforces `RequiredModules`, and PSGraphRenderToHtml was not on
the module path. It was built and installed to the user module path. A
machine-local fact, not a repository change; `verify.ps1` avoids it by building
its own clones.

**7. Degree of parallelism was 3 for the render group and 1 everywhere else.**
The parser, the assembler and the three scoring iterations are inherently
serial — each depends on the previous answer — and the plan says so rather than
claiming a parallelism that did not happen.

**8. The renderer's boundary held, and this is the first evidence for it.**
PSTerraformGraph drives PSGraphRender through PSGraphRenderToHtml and **not one
line of either changed** to allow it. That rule has been an assertion since the
extraction; a second producer in an unforeseen domain is its first measurement.
The one-line consumer commits in both repositories are the only changes made
there, as the constraints allow.

## 11. Cost

Wall-clock: approximately 55 minutes.

Run counts: `./build.ps1` 3 (two during development, one final) plus 1 inside
verify's fresh clone; scoring iterations 3, plus 1 case-scoring pass and 1
inside verify; parse smoke 1 over 30 files; renders 3, concurrent; acceptance 3
(one red, one failed on the missing dependency, one green); `verify.ps1` 1 with
12 checks; fresh clones 6 (3 fixture, 3 repositories inside verify).

No token count: the session cannot measure one.
