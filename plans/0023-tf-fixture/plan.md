# Pass 0023 — Terraform fixture: three repos, oracle, comparator, red-first

Tier: full. Executed 2026-08-29 as part of the recovery batch.

## 1. Prompt

The prompt is reproduced verbatim in the batch issue that carried it. Its
sections: Repositories (harness branch `pass-0023-tf-fixture` from the
0022-updated `main`; AzDO `ClaudeTestingTerraform` for three new repos and
pipeline definitions; `ClaudeTesting` untouched; PSGraphRenderToHtml a
dependency only), Preconditions (sync, clean trees, `$env:AZDO_PAT` set, GET
the project and attempt org-level REST creation if absent with a STOP.md on
401/403, the three repo names absent), the acceptance test quoted below in
full, a seven-task plan, four named spot-checks, and the constraints: no
terraform binary, ClaudeTesting untouched, the fixture frozen the moment
`mutations.txt` exists.

The acceptance test, exactly as given and as written:

```powershell
#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0023 delivered' {
    It 'fixture source committed' {
        foreach ($r in 'TfFixtureNetwork','TfFixtureApp','TfFixtureShared') {
            Test-Path "$RepoRoot/evals/tf/fixture/repos/$r/main.tf" | Should -BeTrue
        }
    }
    It 'oracle exists' {
        Test-Path "$RepoRoot/evals/tf/fixture/expected-graph.json" | Should -BeTrue
    }
    It 'comparator exists with mutation evidence' {
        Test-Path "$RepoRoot/evals/tf/Compare-TfGraph.ps1" | Should -BeTrue
        Test-Path "$RepoRoot/evals/tf/Mutate-TfGraph.ps1"  | Should -BeTrue
        (Get-Content "$RepoRoot/plans/0023-tf-fixture/mutations.txt" -Raw) |
            Should -Match 'DETECTED: 7 / 7'
    }
    It 'read-back verified' {
        (Get-Content "$RepoRoot/plans/0023-tf-fixture/readback.txt" -Raw) |
            Should -Match 'BYTE-IDENTICAL'
    }
    It 'decision 0011 exists' {
        Test-Path "$RepoRoot/decisions/0011-terraform-fixture-and-run-ledger.md" |
            Should -BeTrue
    }
}
```

## 2. Preconditions

**Sync.** Six parallel fetch jobs, all exit 0; every repository clean and level
with its remote after pass 0022 closed.

**Branch.** `pass-0023-tf-fixture` from `main` at
`cee8255fd005f1027bfd3991608927f6d7e2516d`, the SHA pass 0022 left.

**PAT.** `$env:AZDO_PAT` set, length 84. Never echoed, never written to a file,
never placed in a URL. The one place it reaches `git` is
`-c http.extraHeader=...`, built in memory and not persisted.

**The project did not exist.** Eight projects were visible in the organisation
and `ClaudeTestingTerraform` was not among them. Org-level REST creation was
attempted per the precondition:

```
HTTP 202
{"id":"4d48ca93-...","status":"notSet","url":".../operations/4d48ca93-..."}
attempt 1 : succeeded
project GET: HTTP 200
name=ClaudeTestingTerraform id=332ab841-d82b-4267-bac0-b2af4ec725e0 state=wellFormed
```

No 401 or 403, so no STOP.md was written.

**The three repo names were absent.**

```
repos in project: 1
  ClaudeTestingTerraform
  TfFixtureNetwork present: False
  TfFixtureApp present: False
  TfFixtureShared present: False
```

**Tools.** pwsh 7.6.5, Pester 6.1.0, git 2.41.0.windows.1. No terraform binary
was installed or run at any point.

## 3. Environment

pwsh 7.6.5, Pester 6.1.0, git 2.41.0.windows.1, Windows 11 Home 10.0.26200.
Harness branch `pass-0023-tf-fixture` based on `cee8255`.

## 4. Acceptance test — red first

```
  [-] fixture source committed 239ms          Expected $true, but got $false.
  [-] oracle exists 20ms                      Expected $true, but got $false.
  [-] comparator exists with mutation evidence 18ms   Expected $true, but got $false.
  [-] read-back verified 229ms                Expected 'BYTE-IDENTICAL' to match $null
  [-] decision 0011 exists 17ms               Expected $true, but got $false.
Tests Passed: 0, Failed: 5, Skipped: 0, Inconclusive: 0, NotRun: 0
```

5/5 red before any work.

## 5. Tasks

- [x] **1. Acceptance red.** Above.

- [x] **2. Decision 0011.** `decisions/0011-terraform-fixture-and-run-ledger.md`
      written with the prompt's text verbatim. Committed and pushed with the
      acceptance test as the pass's first commit (`10bc117`), before any
      fixture work, per the batch's push-early rule.

- [x] **3. The fixture, three repositories.** Authored under
      `evals/tf/fixture/repos/`. 40 files.

      **TfFixtureShared** (13 files) — `modules/naming` and `modules/tags`,
      each with typed variables, a validation block, locals and outputs;
      `random` and `time` providers pinned exactly and pessimistically.
      `variables.tf` declares `unused_retention_days`, referenced by nothing,
      which is case 6.

      **TfFixtureNetwork** (14 files) — three module levels: root →
      `modules/segment` → `modules/segment/modules/subnet`. Uses `null`,
      `local` and `terraform_data`; two locals chained from variables, one of
      them from another local.

      **TfFixtureApp** (13 files) — the traceability showcase. `var.tags`
      reaches a worker four levels down through two module boundaries. Two
      cross-repository `git::` sources into TfFixtureShared, two variables
      carrying TfFixtureNetwork's outputs, and `module "legacy"` sourcing
      `../shared-legacy/modules/archive`, which exists nowhere — case 7, and
      deliberate.

      Every repository carries `versions.tf` with a distinct
      `required_version`, `.gitattributes` pinning LF, a README stating that
      nothing here is ever applied, and pipeline YAML. Verified:

      ```
      TfFixtureShared:  13 files, required_version = ">= 1.3.0, < 2.0.0"
      TfFixtureNetwork: 14 files, required_version = ">= 1.5.0"
      TfFixtureApp:     13 files, required_version = "~> 1.0.11"
      pipeline terraform versions: 0.13.7, 1.0.11, 1.5.7, 1.9.8
      credential scan across the fixture: none found
      ```

- [x] **4. The oracle.** `evals/tf/fixture/expected-graph.json`, hand-authored
      from reading the configuration and **never produced by parsing it**.
      Validated with PSGraphRenderToHtml's own `Test-ProducerGraph`:

      ```
      IsValid=True  nodes=78  edges=57  violations=0
      by type:   local 9, module 10, output 17, provider 6, repository 3, variable 33
      by scope:  TfFixtureApp 29, TfFixtureNetwork 27, TfFixtureShared 22
      by kind:   passes-to 20, references 28, sources 9
      unresolved edges:
        TfFixtureApp:. -> TfFixtureApp:../shared-legacy/modules/archive:
          source ../shared-legacy/modules/archive resolves to no directory in any scanned repository
      ```

      Every count matches `cases.md` exactly. `cases.md` documents the node-id
      scheme, why containment is `parentId` and never an edge, the three edge
      kinds, and all seven cases with what each catches.

- [x] **5. Comparator and mutator, red first.** The 15 assertions in
      `evals/tf/Compare-TfGraph.Tests.ps1` were written and run **before either
      script existed**: 15 failed, 0 passed. After implementation: 15 passed,
      0 failed.

      Falsification, `plans/0023-tf-fixture/mutations.txt`:

      ```
      CONTROL GREEN                       (oracle vs itself: 0 differences)
      DETECTED: missing-node    [MissingNode]     31595 -> 31364 chars
      DETECTED: extra-node      [ExtraNode]       31595 -> 31820 chars
      DETECTED: wrong-attribute [WrongAttribute]  31595 -> 31595 chars
      DETECTED: wrong-parent    [WrongParent]     31595 -> 31581 chars
      DETECTED: missing-edge    [MissingEdge]     31595 -> 31438 chars
      DETECTED: extra-edge      [ExtraEdge]       31595 -> 31767 chars
      DETECTED: wrong-edge-kind [WrongEdgeKind]   31595 -> 31596 chars
      distinct categories exercised: 7 of 7

      DETECTED: 7 / 7
      ```

      Each mutation is proved to have landed before its detection is trusted.
      `wrong-attribute` changes the document without changing its length —
      `3.6.0` to `9.9.9` — so the proof compares text and not size. A length
      comparison would have passed it while proving nothing.

- [x] **6. Publish and read back.** `-WhatIf` first, which reported the exact
      file counts and created nothing. Then:

      ```
      TfFixtureApp      created=True pushed=True files=13  187ff229c0ad908eb39822f1bb78b6c0e3a206b3
      TfFixtureNetwork  created=True pushed=True files=14  24f27be92e583b6dfc9208bca42f8ec0baf5004b
      TfFixtureShared   created=True pushed=True files=13  0af6ee33854bedb4147d0b13cc6db1311687775b
      3 repositories, run concurrently on ThreadJob.
      ```

      Four pipeline definitions created (ids 16–19). Read-back,
      `plans/0023-tf-fixture/readback.txt`:

      ```
      TfFixtureShared   cloned at 0af6ee33...  harness 13, remote 13
      TfFixtureNetwork  cloned at 24f27be9...  harness 14, remote 14
      TfFixtureApp      cloned at 187ff229...  harness 13, remote 13
      40 file(s) compared across 3 repositories.
      BYTE-IDENTICAL
      ```

      And, queried rather than asserted:

      ```
      builds ever queued in ClaudeTestingTerraform: 0
      pipeline definitions: 4
      repositories: 4  (the three fixture repos plus the project default)
      ```

- [x] **7. Records.** Plan, `verify.ps1`, journal. Pushed after each group.

## 6. Acceptance test — green

```
  [+] fixture source committed 103ms
  [+] oracle exists 4ms
  [+] comparator exists with mutation evidence 20ms
  [+] read-back verified 6ms
  [+] decision 0011 exists 5ms
Tests Passed: 5, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

## 7. Command transcript

```bash
git fetch --all --tags --prune                       # x6, parallel
git checkout -b pass-0023-tf-fixture main
pwsh -NoProfile -File scratchpad/proj.ps1            # 8 projects, target absent
pwsh -NoProfile -File scratchpad/mkproj.ps1          # HTTP 202
pwsh -NoProfile -File scratchpad/waitproj.ps1        # succeeded, wellFormed
pwsh -NoProfile -File scratchpad/repos.ps1           # three names absent

pwsh -NoProfile -Command 'Invoke-Pester plans/0023-tf-fixture/accept.Tests.ps1'   # 0/5
git add decisions/0011-... plans/0023-tf-fixture/accept.Tests.ps1
git commit && git push -u origin pass-0023-tf-fixture

# fixture authored under evals/tf/fixture/repos/
git add evals/tf/fixture/repos && git commit && git push

pwsh -NoProfile -File scratchpad/oracle.ps1                     # 78/57/0 violations
pwsh -NoProfile -Command 'Invoke-Pester evals/tf/Compare-TfGraph.Tests.ps1'  # 0/15 RED
# Compare-TfGraph.ps1 and Mutate-TfGraph.ps1 written
pwsh -NoProfile -Command 'Invoke-Pester evals/tf/Compare-TfGraph.Tests.ps1'  # 15/15
pwsh -NoProfile -File scratchpad/mutations.ps1 > plans/0023-tf-fixture/mutations.txt
git add evals/tf plans/0023-tf-fixture/mutations.txt && git commit && git push

pwsh -NoProfile -Command './evals/tf/Publish-TfFixture.ps1 -WhatIf'
pwsh -NoProfile -Command './evals/tf/Publish-TfFixture.ps1'
pwsh -NoProfile -Command './evals/tf/New-TfFixturePipeline.ps1'
pwsh -NoProfile -Command './evals/tf/Test-TfFixtureReadBack.ps1 -ReportPath ./plans/0023-tf-fixture/readback.txt'
pwsh -NoProfile -File scratchpad/noqueue.ps1                    # 0 builds ever

pwsh -NoProfile -Command 'Invoke-Pester plans/0023-tf-fixture/accept.Tests.ps1'   # 5/5
pwsh -NoProfile -File plans/0023-tf-fixture/verify.ps1          # 13 checks, 0 failed
git merge-base --is-ancestor origin/main pass-0023-tf-fixture
git checkout main && git merge --ff-only pass-0023-tf-fixture && git push origin main
```

## 9. Verify script

`plans/0023-tf-fixture/verify.ps1`, committed beside this plan.

It re-derives rather than reads: it regenerates mutations 2 and 5
(`extra-node` and `missing-edge`) **itself** and asserts their detection,
rather than reading what `mutations.txt` concluded; it re-clones all three
AzDO repositories and re-hashes every file rather than reading
`readback.txt`; and it queries the project's entire build history rather
than trusting that no queue call exists. Its AzDO checks **skip loudly**
without a PAT and the summary says the run graded less than a full one.

```
13 check(s), 0 failed, 0 skipped.
```

## 10. Deviations

**1. The AzDO project did not exist and was created.** The precondition
allowed for it. Creation returned 202 and the operation succeeded; the
project is `wellFormed` with id `332ab841-d82b-4267-bac0-b2af4ec725e0`. No
STOP.md was needed.

**2. A `Terraform` project already exists in the organisation and was not
used.** The prompt names `ClaudeTestingTerraform`. A project with a similar
name is not the one authorised, and reusing it would have put fixture
repositories somewhere nobody agreed to.

**3. A separate AzDO client was written rather than reusing the existing
one.** `evals/functional/AzdoClient.ps1` hard-refuses any project but
`ClaudeTesting`. Loosening that guard so one client could serve both would
remove the only thing standing between a script and the frozen AzDO fixture.
The new client refuses `ClaudeTesting` **by name**, so its failure message
says what went wrong rather than only what was permitted. The duplication is
deliberate and is cheaper than the guard it preserves.

**4. `cases.md` claimed five pipeline definitions; there are four.** Found by
counting them during verification and corrected. Recorded because it is the
argument for stating counts at all: a vague "several" could not have been
wrong, and could not have been caught.

**5. The unresolvable module needed a node, which the prompt did not
specify.** The producer contract requires every edge endpoint to resolve to a
node id, so an unresolved module source cannot be a dangling edge. The
fixture emits a node for the unresolvable target and marks the `sources` edge
`resolved: false` with a reason. This is a decision the contract forced; it
is documented as case 7 so that PSTerraformGraph in pass 0024 implements the
same reading rather than inventing one at scoring time.

**6. Four pipeline definitions, not five.** The prompt asked for "1–2
pipeline definition YAMLs" per repository across three repositories, and for
four distinct Terraform versions. Four definitions carry four distinct
versions, one each. A fifth would have had to repeat a version.

**7. Read-back normalises line endings on both sides.** Every fixture
repository carries `.gitattributes` with `* text=auto eol=lf`, so git checks
out LF while a Windows working copy may hold CRLF. Comparing raw bytes would
report a mismatch that is about line endings and nothing else — the same trap
that made pass 0022's verify report a 428-character difference which turned
out to be exactly 428 carriage returns. The normalisation is stated in the
script rather than applied quietly.

**8. No terraform binary was installed or run**, as the batch requires. The
fixture is parsed as configuration text and nothing else. Its READMEs say so,
so a later reader does not assume a plan was ever produced.

## 11. Cost

Wall-clock for the pass: approximately 45 minutes.

Run counts: comparator suite 2 (one red, one green); mutation falsification 1
(7 mutations plus a control plus a discrimination pass, so 15 comparisons);
acceptance 2; `verify.ps1` 1 (13 checks); AzDO REST calls approximately 25,
none of them a queue; repository pushes 3, concurrent on ThreadJob; fresh
clones 3.

No token count: the session cannot measure one.
