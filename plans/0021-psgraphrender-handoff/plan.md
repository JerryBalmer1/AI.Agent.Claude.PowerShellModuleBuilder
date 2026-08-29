# Pass 0021 — PSGraphRender handoff

Tier: full. Executed 2026-08-29.

## 1. Prompt

```
# PASS 0021 — PSGraphRender handoff: begin tag, vendor tooling, strip the resident workflow
Tier: full

## Repositories
- `PSGraphRender` — the subject. Branch `pass-0021-handoff` cut from `main`
  (`4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995`). Tags `handoff-begin-2026-08-29`
  and `v0.13.0`; `main` fast-forwarded at the end per decision 0010 (task 2).
- `AI.Agent.Claude.PowerShellModuleBuilder` — records only: branch
  `pass-0021-psgraphrender-handoff` from `main`
  (`641bc8358cec822a873c01c72561dd07e5e70cc2`), carrying plan, journal,
  decision 0010, verify script.
- PSModuleGraph, PSAzureDevOpsGraph, ToHtml, PSTerraformGraph — untouched.

## Preconditions — hard stop on failure
1. Both repos on the SHAs above, trees clean (rule 13 if not). Create both
   branches.
2. PSGraphRender remote: tag `v0.12.0` present at `main`; no
   `handoff-begin-2026-08-29`, no `v0.13.0`.
3. **Baseline green before any change:** `./build.ps1` in PSGraphRender at
   `v0.12.0` exits 0, full test run, counts recorded. If the environment
   cannot run the browser gate, stop and report — do not skip it.
4. `vendor.psd1` parses via `Import-PowerShellDataFile` and lists exactly 2
   files. pwsh ≥ 7.2, Pester, node (for the browser gate), git versions
   recorded. Internet reachable (jsdelivr) for the vendor-fetch falsification.

## Acceptance test — red first
`plans/0021-psgraphrender-handoff/accept.Tests.ps1` in the harness, exactly:

    #Requires -Version 7.2
    param([string]$Render = "$PSScriptRoot/../../../PSGraphRender",
          [string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0021 delivered' {
        It 'begin tag exists and marks the pre-handoff main' {
            (git -C $Render rev-parse 'handoff-begin-2026-08-29^{}') |
                Should -Be '4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995'
        }
        It 'workflow machinery is gone' {
            foreach ($p in 'CLAUDE.md','.claude','docs/threads.json',
                           'tools/threads.ps1','tests/Ledger.Tests.ps1',
                           'tests/Instructions.Tests.ps1','knowledge') {
                Test-Path (Join-Path $Render $p) | Should -BeFalse
            }
        }
        It 'knowledge survives as archive' {
            (Get-ChildItem "$Render/docs/ledger-archive" -Filter *.md).Count |
                Should -BeGreaterThan 10
        }
        It 'vendor tooling exists' {
            Test-Path "$Render/tools/Update-Vendor.ps1" | Should -BeTrue
            Test-Path "$Render/docs/vendoring.md"       | Should -BeTrue
        }
        It 'handoff file exists and carries the essentials' {
            $h = Get-Content "$Render/docs/HANDOFF.md" -Raw
            $h | Should -Match 'viewmodel\.schema\.json'
            $h | Should -Match '1\.1\.0'
            $h | Should -Match '(?m)^## Boundaries'
            $h | Should -Match '(?m)^## Open'
        }
        It 'v0.13.0 exists and main follows it' {
            $tag = git -C $Render rev-parse 'v0.13.0^{}' 2>$null
            $tag | Should -Match '^[0-9a-f]{40}$'
            (git -C $Render rev-parse origin/main) | Should -Be $tag
        }
        It 'decision 0010 exists in the harness' {
            Test-Path "$RepoRoot/decisions/0010-ecosystem-repo-governance.md" |
                Should -BeTrue
        }
    }

Run it, report the red with messages. Green at start stops the pass.

## Plan
Serial spine; groups marked ∥ run as parallel jobs, outputs captured per job.

- [ ] 1. Acceptance red; report it.
- [ ] 2. Create `decisions/0010-ecosystem-repo-governance.md` in the
      harness, verbatim:

          # 0010 — Ecosystem repo governance

          Operator-directed, 2026-08-29. PSGraphRender, PSGraphRenderToHtml
          and PSTerraformGraph are governed like the target: work on
          `pass-NNNN-*` branches; after a green pass the agent
          fast-forwards that repo's `main` (ancestry verified with
          `git merge-base --is-ancestor`, never forced) and pushes tags the
          pass prompt names. No history rewrites, no `Publish-Module`, no
          force pushes, ever. Each repo keeps its own version cadence and
          carries `docs/HANDOFF.md` per the project context. Decisions
          0005/0008/0009 are unchanged for the repos they already name.

- [ ] 3. Push annotated tag `handoff-begin-2026-08-29` onto `4a367c6…`,
      message: "Begin marker: state before the handoff pass stripped the
      resident agentic workflow. Everything before this tag was operated by
      the in-repo thread-ledger process; everything after is operated
      plan-by-plan from the harness project." Quote `ls-remote --tags`.
- [ ] 4. ∥ Group A — three parallel jobs, then review serially:
      - A1 `tools/Update-Vendor.ps1`: reads `vendor.psd1` as data; modes
        `-Verify` (re-hash every listed file, sha384, compare, name each
        mismatch, nonzero exit on any), `-Update [-Name <n>] [-PinVersion
        <v>]` (fetch the manifest URL — or the URL with the new version
        substituted — to a temp file, compute integrity, replace file and
        rewrite that entry's Version/Url/Integrity in the same operation,
        refuse on download failure or on a hash that matches the old
        recorded value when a new version was requested), `-WhatIf`
        honoured. Per-file work fans out via ThreadJob. Never touches a
        file not listed in the manifest.
      - A2 `docs/vendoring.md`: every vendored file (both cytoscape libs),
        how obtained, how pinned (manifest + SRI + `Vendor.Tests.ps1`),
        how updated (the new function, exact commands), the dagre
        sourceMappingURL caveat carried over from the manifest comments,
        and the statement that the `plain` template set vendors nothing by
        design. State where a new template set must register its vendor
        manifest.
      - A3 Extract from `docs/threads.json` every thread not closed/retired
        into a draft Open list (id, one-line summary); extract from
        `CLAUDE.md` and the five skills any *fact or rule* not already in
        `docs/` (the core node/edge constraint, the producer-agnosticism
        boundary, tier structure of the docs) into a draft for task 6.
        Read-only job.
- [ ] 5. **Strip.** Delete `CLAUDE.md`, `.claude/` entirely,
      `docs/threads.json`, `tools/threads.ps1`, `tests/Ledger.Tests.ps1`,
      `tests/Instructions.Tests.ps1`. `git mv knowledge/ledger
      docs/ledger-archive` and remove the now-empty `knowledge/`; add a
      three-line `docs/ledger-archive/README.md`: archived post-mortems,
      no live workflow, see HANDOFF.md. Then ∥ grep jobs across build
      scripts, tests, docs, CI for `threads`, `ledger`, `CLAUDE`,
      `\.claude`, `skills` — every surviving reference to removed
      machinery is removed and named in the plan. Removing a reference to
      deleted machinery is not weakening an assertion; changing what any
      surviving test asserts about the *renderer* is forbidden.
- [ ] 6. `docs/HANDOFF.md` with sections: What this is; Contract
      (`contract/viewmodel.schema.json`, 1.1.0, change protocol per the
      project context); **## Boundaries** (never parses a module, never
      learns producer kinds, vendored files never hand-edited); Version
      ledger (v0.12.0 = pre-handoff, `handoff-begin-2026-08-29`, v0.13.0 =
      this pass); How it is operated now (plan-by-plan, decision 0010);
      **## Open** (the task-4 A3 thread list, plus consumers to come:
      ToHtml battery, Terraform producer). Fold in the A3 facts the docs
      did not already hold.
- [ ] 7. Falsify the vendor tool, in `scratch/` copies only: (a) flip one
      byte in a copied `cytoscape.min.js` → `-Verify` exits nonzero naming
      exactly that file; (b) point a copied manifest entry at a 404 URL →
      `-Update` refuses naming the entry; (c) control: untouched copy →
      `-Verify` green. Capture all three.
- [ ] 8. Full `./build.ps1` green (this also runs `Vendor.Tests.ps1` and
      the browser gate). Record counts against the precondition-3
      baseline; the delta must be exactly the two deleted machinery test
      files and nothing else.
- [ ] 9. Update PSGraphRender's `README.md`: one paragraph on operation
      (HANDOFF.md, no resident workflow) and the cross-reference section
      per the standing rule (consumers: PSModuleGraph today; ToHtml and
      the producers to come; back-reference to the harness). Update
      `CHANGELOG.md` and write `docs/worklog/v0.13.0.md` (why the handoff,
      what was stripped, what was kept and where it went).
- [ ] 10. Commit; annotated tag `v0.13.0`, message carrying the test
      counts and "handoff complete: vendor tooling added, resident
      workflow removed, knowledge archived". Push branch and both tags;
      fast-forward PSGraphRender `main` (ancestry verified) and push.
- [ ] 11. Acceptance green; report it. Harness: plan (prompt verbatim,
      per-task evidence including all parallel job transcripts and their
      degree of parallelism), verify script, `journal/0021-…md`. Push the
      harness pass branch; fast-forward harness `main` per decision 0009.

## Named spot-checks — verify.ps1 (harness) must re-derive
1. Fresh clone of PSGraphRender at `v0.13.0`: `./build.ps1` green; absent
   paths absent; `docs/ledger-archive` populated.
2. Both vendored files re-hashed by verify itself (sha384, independent of
   the tool and the tests) and matched to the manifest.
3. Tamper-a-byte in verify's own scratch clone → `Update-Vendor.ps1
   -Verify` nonzero naming the file; clean copy → zero. (`-FailCheck`
   probes assert each tamper changed something before checking.)
4. Tag topology: `handoff-begin-2026-08-29^{}` = `4a367c6…`; `v0.13.0^{}`
   descends from it; `origin/main` = `v0.13.0^{}`.
5. Harness decision 0010 present; parallel checks aggregate to one exit
   code, each output naming its check.

## Constraints
The two vendored .js files are never edited — the tool replaces whole
files, hash-verified, or nothing. `contract/viewmodel.schema.json` is not
touched this pass (no version bump without a consumer-driven reason).
`docs/constraints.md` and `tools/shoot.cjs` stay. No force pushes, no
rewrites; every `main` move ancestry-checked first. AZDO not contacted.

## Deviations
Required. Especially: any surviving test that gated removed machinery in a
way this prompt did not predict; any open thread whose knowledge could not
be carried into HANDOFF.md; anything here that was wrong.

## Report back
Both pushed mains and all three tag refs (`ls-remote` quoted); baseline vs
final test counts with the exact delta; the three falsification outputs;
the Open-list size carried into HANDOFF.md; wall-clock with degree of
parallelism per group.
```

## 2. Preconditions

**1. SHAs and clean trees.**

```
harness  641bc8358cec822a873c01c72561dd07e5e70cc2   (matches)
render   4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995   (matches, clean)
```

The harness tree was **not** clean: `AI.Agent.Claude.PowerShellModuleBuilder.code-workspace`
carried an editor-written change adding the four sibling repos to the workspace
`folders` list. Per PLAN-PROTOCOL.md "Uncommitted changes the pass did not
make", it was committed on its own before the pass began, named as unrelated —
not reverted, not stashed, not carried:

```
8df0d8b Unrelated: editor added the four sibling repos to the workspace file
 1 file changed, 12 insertions(+)
```

Both branches created: `pass-0021-psgraphrender-handoff` (harness),
`pass-0021-handoff` (render).

**2. Remote state before the pass.** `git ls-remote --tags origin` in
PSGraphRender showed `v0.12.0^{}` = `4a367c6a…` and `refs/heads/main` =
`4a367c6a…`; no `handoff-begin-2026-08-29`, no `v0.13.0`.

**3. Baseline green.** The first `./build.ps1` **failed**, exit 1:

```
Task /./TestBrowser
ERROR: The browser harness is not installed. Run ./build.ps1 -Task BootstrapBrowser
first. This task fails rather than skipping, deliberately.
Build FAILED. 8 tasks, 1 errors, 0 warnings
```

That is the gate refusing to skip, not an environment that cannot run it. The
build supplies its own bootstrap task; it was run (exit 0, npm + Chromium) and
the baseline re-taken:

```
./build.ps1                → exit 0. Build succeeded. 8 tasks, 0 errors, 0 warnings.
                             Tests Passed: 127, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 15
                             Line coverage: 81.75% (target 80%)
                             Browser: 6 page(s) came alive, network blocked,
                                      across 2 backend(s) and 3 fixture(s) at 1280x900@1x
./build.ps1 -Task PreTag   → exit 0. Tests Passed: 15, Failed: 0, NotRun: 127
```

Artifacts: `scratchpad/baseline-build.txt`, `scratchpad/baseline-pretag.txt`.

**4. Manifest and tools.**

```
vendor.psd1 parses: files=2
  cytoscape.min.js 3.34.2
  cytoscape-dagre.min.js 4.0.0
pwsh: 7.6.5
Pester: 6.1.0
git: git version 2.41.0.windows.1
node: v22.20.0
InvokeBuild: 5.14.23
jsdelivr reachable: HTTP 200
```

## 3. Environment

pwsh 7.6.5, Pester 6.1.0, InvokeBuild 5.14.23, node v22.20.0, git 2.41.0.windows.1.
Windows 11 Home 10.0.26200. Harness branch `pass-0021-psgraphrender-handoff` at
`641bc83` (+ the unrelated commit `8df0d8b`); render branch `pass-0021-handoff`
at `4a367c6`.

## 4. Acceptance test — red first

`plans/0021-psgraphrender-handoff/accept.Tests.ps1`, written verbatim from the
prompt.

The first run was invalid: the runner was configured with
`$c.Should.DisableV5 = $true`, copying PSGraphRender's own build convention.
That makes every `Should -Be` in the verbatim test throw a syntax error rather
than assert, so all seven "failed" for the wrong reason. Re-run with Pester
defaults, which the v5 syntax the prompt specifies requires:

```
pwsh -NoProfile -Command 'Import-Module Pester -MinimumVersion 6.0.0;
  $c = New-PesterConfiguration;
  $c.Run.Path="plans/0021-psgraphrender-handoff/accept.Tests.ps1";
  $c.Output.Verbosity="Detailed"; Invoke-Pester -Configuration $c'
```

```
Describing Pass 0021 delivered
  [-] begin tag exists and marks the pre-handoff main 211ms
   Expected strings to be the same, but they were different.
   Expected: '4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995'
   But was:  'handoff-begin-2026-08-29^{}'
  [-] workflow machinery is gone 15ms
   Expected $false, but got $true.
  [-] knowledge survives as archive 102ms
   Expected the actual value to be greater than 10, but got 0.
  [-] vendor tooling exists 7ms
   Expected $true, but got $false.
  [-] handoff file exists and carries the essentials 14ms
   Expected regular expression 'viewmodel\.schema\.json' to match $null, but it did not match.
  [-] v0.13.0 exists and main follows it 38ms
   Expected regular expression '^[0-9a-f]{40}$' to match 'v0.13.0^{}', but it did not match.
  [-] decision 0010 exists in the harness 6ms
   Expected $true, but got $false.
Tests Passed: 0, Failed: 7, Skipped: 0, Inconclusive: 0, NotRun: 0
```

7/7 red, each for the reason the task it guards had not been done. Artifact:
`scratchpad/accept-red.txt`.

## 5. Tasks

- [x] **1. Acceptance red.** Above. 7 failed, 0 passed.

- [x] **2. Decision 0010.** `decisions/0010-ecosystem-repo-governance.md`
      created with the prompt's text verbatim, 11 lines.

- [x] **3. Begin tag.** Annotated tag on `4a367c6a…` with the prompt's message,
      pushed.

      ```
      63bc486af968f8b5dcaffad3b98df2fe3e20069c	refs/tags/handoff-begin-2026-08-29
      4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995	refs/tags/handoff-begin-2026-08-29^{}
      ```

- [x] **4. Group A — three parallel jobs, degree of parallelism 3.**
      All three launched in one dispatch and ran concurrently; each was reviewed
      serially against its sources afterwards. Wall-clock per job, from the job
      records: **A2 268s, A3 707s, A1 875s**. Group wall-clock **875s (14.6 min)**
      against **1850s (30.8 min)** if run serially.

      **A1 — `tools/Update-Vendor.ps1`, 647 lines.** Discovers every
      `TemplateSets/*/vendor/vendor.psd1`, reads it with
      `Import-PowerShellDataFile`, fans per-file work out over `Start-ThreadJob`.
      Its `-Verify` against the real repository:

      ```
      2 vendored file(s) in 1 manifest(s) under …\PSGraphRender
        2 file(s) processed concurrently on ThreadJob.
        OK       cytoscape/vendor/cytoscape.min.js  sha384-BSWdCKSC…
        OK       cytoscape/vendor/cytoscape-dagre.min.js  sha384-ZB0G8+HS…
      2 file(s) checked, 0 failed.
      EXIT=0
      ```

      Reviewed line by line, because it downloads and replaces files. The
      properties that made it acceptable: an entry `Name` containing a path
      separator is refused where the path is *built* rather than trusted where it
      is used; the replacement manifest text is composed **before** anything is
      copied, so a manifest that cannot be rewritten stops the entry with the
      vendored file intact; the manifest is rewritten textually — three property
      lines inside a block bounded by walking back to its `@{` and forward to its
      `}` — and a key that does not appear exactly once throws rather than being
      half-rewritten; and after the copy the file is re-read from disk and
      re-hashed before the manifest is allowed to record that hash.

      The job reported two bugs it found *by running* rather than reading: a
      sequential-fallback path where array-subexpression syntax was mistaken for
      splatting and mislabelled every result, and temp files leaking under
      `-WhatIf` because the cleanup `Remove-Item` inherited `$WhatIfPreference`.
      Both fixed in the delivered file. It could not force a genuine
      `Start-ThreadJob` absence on this machine and says so.

      Judgement calls accepted on review: the aiming parameter is `-Root` (a
      checkout) rather than `-ManifestPath`, so the falsification exercises the
      real discovery path; zero manifests *overall* is exit 1 rather than a quiet
      success, matching the reason `Vendor.Tests.ps1` asserts its collection is
      non-empty; one `ShouldProcess` covers both writes, because separately
      declinable gates could leave the record disagreeing with the disk.

      **A2 — `docs/vendoring.md`, 232 lines** after review edits. Ten sections
      covering all eight required points. Its claims were checked against the
      sources rather than taken on trust: the sourceMappingURL constraint is real
      at `docs/constraints.md:86` (`0005-t4`), the `VENDOR` slot is real at
      `templateset.psd1:26`, and its "four scans" sentence is copied from
      `docs/development.md:129` and attributed there. It flagged six claims it
      could not verify directly; all six are honest attributions to the manifest
      header or CHANGELOG rather than invented facts.

      **A3 — read-only extraction**, two scratch deliverables (153 and 674
      lines). Found **41 open threads** (17 PSGraphRender, 24 PSModuleGraph) and
      **21 orphan facts**. It re-derived the file's own counts by hand and
      confirmed the status vocabulary against `tools/threads.ps1`: `open` 41,
      `closed` 46, `accepted` 24, `superseded` 1, of 112 raised, with the tool's
      three retiring verbs and `recovers_threads` applied first. Two of the three
      facts the prompt named as "known to be in there" turned out to be
      **already documented** (the core node/edge rule and producer-agnosticism);
      it reported that rather than padding the list, and salvaged four genuinely
      orphan fragments of them instead.

- [x] **5. Strip.** Deleted `CLAUDE.md`, `.claude/` (6 files),
      `docs/threads.json`, `tools/threads.ps1`, `tests/Ledger.Tests.ps1`,
      `tests/Instructions.Tests.ps1`. `git mv knowledge/ledger
      docs/ledger-archive` — all 13 entries recorded as renames (`R`) so history
      follows — and `knowledge/` removed. `docs/ledger-archive/README.md` added.

      Then five parallel grep jobs over `*.ps1 *.psd1 *.psm1 *.md *.yml *.js
      *.cjs *.json` for `threads`, `ledger`, `CLAUDE`, `\.claude`, `skills`.
      (The first attempt wrote two jobs' output to the same file: `CLAUDE` and
      `\.claude` reduced to the same basename on a case-insensitive filesystem.
      Re-run with distinct names.)

      Every surviving reference, and what was done:

      | File | Reference | Action |
      | --- | --- | --- |
      | `docs/testing.md:41` | `.claude/skills/instruction-prune/SKILL.md` | paragraph replaced — the gate it described is deleted |
      | `docs/testing.md:45-52` | PreTag "today that is one test" + `.claude/skills/iteration-close` | **rewritten**; see Deviations |
      | `docs/testing.md:4,26` | `CLAUDE.md` | repointed to `docs/HANDOFF.md` |
      | `docs/development.md:37` | forbidden list "in `CLAUDE.md`" | repointed to `docs/HANDOFF.md` |
      | `docs/development.md:159` | "moved down a tier from `CLAUDE.md`" | reworded; the tier no longer exists |
      | `docs/development.md:122` | manual vendor procedure | pointer added to `docs/vendoring.md` |
      | `docs/constraints.md:4,8,19` | "ledger thread", "the ledger's own measurement", "still findable" | repointed to `docs/ledger-archive/` |
      | `docs/constraints.md:95` | "The skills are a fork and nothing watches the drift" | rewritten to keep the *rule* (a sync check whose correct state is red is a gate to delete) and retire the subject |
      | `docs/improvements.md` | two backlog entries about the skills directory; one about the instruction ceiling | deleted — they describe files that no longer exist |
      | `docs/improvements.md:83` | `docs/threads.json` "knows every disposition" | rewritten: that record is gone, this file and `constraints.md` are now the only statement |
      | `docs/improvements.md:137` | `knowledge/ledger/0005` | repointed to `docs/ledger-archive/0005` |
      | `docs/improvements.md:212` | "moved out of `CLAUDE.md`" | reworded |
      | `docs/render-architecture.md:89` | `knowledge/ledger/` in the tree diagram | repointed |
      | `docs/render-architecture.md:235` | unticked checklist "CLAUDE.md pruned toward 10,000" | ticked and restated: the tier was removed rather than the bytes |
      | `docs/render-architecture.md:281` | dated decision-log entry about `knowledge/` | **left as written**; a new dated entry appended instead, because that log is append-only |
      | `docs/samples/README.md:23,43,88,89` | `knowledge/ledger/NNNN` | repointed to `docs/ledger-archive/NNNN` |
      | `docs/samples/README.md:40` | `.claude/skills/golden-recording` | rule stated inline — that skill was never in this repository, so the link was already dangling |
      | `README.md:234` | `knowledge/ledger/` table row | repointed; `HANDOFF.md`, `constraints.md`, `vendoring.md` rows added |
      | `CHANGELOG.md:17` | `knowledge/ledger/` as "the primary source" | repointed, with a note that those entries are a record and not a process |
      | `PSGraphRender.build.ps1:513` | coverage throw says "say so in the ledger" | "say so in the commit message" |
      | `scripts/foundation.js:13` | "See the gravity rule in CLAUDE.md" | repointed to `docs/HANDOFF.md` |
      | `tests/NoProducerKinds.Tests.ps1:138` | comment: "the list CLAUDE.md actually forbids" | repointed to `docs/HANDOFF.md`. **Comment only — the forbidden list is hardcoded in the test and no assertion changed.** |

      No surviving test *reads* any machinery path; this was checked by grepping
      every test for `Join-Path`/`Get-Content`/`Test-Path`/`Get-ChildItem`
      against the machinery names before deleting anything. Result: zero hits.

      CHANGELOG entries under past version headings still name the deleted files.
      Those are the record of what those releases contained; rewriting them would
      falsify history and they were deliberately left.

- [x] **6. `docs/HANDOFF.md`, 236 lines.** All six required sections, in order:
      What this is; Contract (schema path, 1.1.0, the four-point change
      protocol); `## Boundaries`; Version ledger; How it is operated now;
      `## Open`. Folded in the A3 facts the docs did not already hold — the
      six-word forbidden list with its six surfaces and the permitted allowlist,
      the contract's additive-minor/shape-major policy, the falsifiable schema
      test, the four config files stated by what they must *never* hold, the
      registry rule, gravity as a principle, commit and release conventions, and
      the gate-falsifiability method, which was the single largest orphan
      (`falsifiab` returned zero hits anywhere under `docs/`).

      `## Open` carries **17** threads — the PSGraphRender ones. See Deviations
      for the 24 PSModuleGraph threads.

- [x] **7. Falsification, in scratch copies only.** Three copies of the two
      template sets, none of them the repository.

      **(c) Control — untouched copy:**
      ```
      2 file(s) checked, 0 failed.
      EXIT=0
      ```

      **(a) One byte flipped** (byte 1000 of the copied `cytoscape.min.js`,
      XOR 1). The probe asserts the break landed before checking:
      ```
      md5 before=4303050f33335de74038a25ec2c784df
      md5 after =708282b82ed0f9910629fd9557cf8371
      PROBE VALID: the tamper changed the file
      ```
      ```
        MISMATCH cytoscape/vendor/cytoscape.min.js
                   the bytes on disk are not the bytes the manifest recorded
                   recorded sha384-BSWdCKSCDnBW0jqCFJdI+wvv6v62CWMcVb9LSwnq973ykOGAzHY5tQMOjvOTJNpj
                   on disk  sha384-aPHzAtHUKRhx+QbjRY/JXHuN8ISV3gRDryAoOGx8frLiFudocHtF2nvpZGp16BZO
        OK       cytoscape/vendor/cytoscape-dagre.min.js  sha384-ZB0G8+HS…
      2 file(s) checked, 1 failed.
      Files that do not match what the manifest recorded:
        cytoscape/vendor/cytoscape.min.js
      EXIT=1
      ```
      Nonzero, naming exactly the tampered file, and the other file still green —
      so the check discriminates rather than failing wholesale.

      The **first attempt at this probe proved nothing** and is recorded in
      Deviations: a git-bash path reached PowerShell as `C:\c\Users\…`, the write
      failed, the file was unchanged, and `-Verify` came back green. The
      before/after hash comparison is what caught it, which is why it is in the
      probe and in `verify.ps1 -FailCheck`.

      **(b) A manifest entry pointed at a 404 URL:**
      ```
        FAILED   cytoscape/vendor/cytoscape.min.js
                   https://cdn.jsdelivr.net/npm/cytoscape@3.34.2/dist/no-such-file-here.min.js
                   Response status code does not indicate success: 404 (Not Found).
        CURRENT  cytoscape/vendor/cytoscape-dagre.min.js  sha384-ZB0G8+HS…
      2 entry(ies) considered, 0 updated, 1 refused or failed.
      Entries that were not updated:
        cytoscape/vendor/cytoscape.min.js
      EXIT=1
      ```
      The refusal left the copy's vendored `.js` byte-identical to the
      repository's and did not rewrite the manifest. `git status` over
      `src/PSGraphRender/TemplateSets/` after all three probes showed only the
      one-line `foundation.js` comment repoint — the vendored files were never
      touched.

- [x] **8. Build green, delta exact.**

      ```
      ./build.ps1              → exit 0. 8 tasks, 0 errors, 0 warnings.
                                 Tests Passed: 122, Failed: 0, Skipped: 0, NotRun: 9
                                 Line coverage: 81.75% (target 80%)
                                 Browser: 6 page(s) came alive, network blocked,
                                          across 2 backend(s) and 3 fixture(s)
      ./build.ps1 -Task PreTag → exit 0. Tests Passed: 9, Failed: 0
      ```

      | | baseline | final | delta |
      | --- | --- | --- | --- |
      | default, passed | 127 | 122 | −5 |
      | default, not-run | 15 | 9 | −6 |
      | PreTag, passed | 15 | 9 | −6 |
      | coverage | 81.75% | 81.75% | 0 |
      | browser pages | 6 | 6 | 0 |

      −5 passed is `tests/Instructions.Tests.ps1` exactly: three `It`s under
      "The always-loaded instruction tier" and two under "What a document can
      make happen", all five confirmed passing in the baseline transcript.
      −6 not-run is `tests/Ledger.Tests.ps1` exactly: six `It`s, all tagged
      `PreTag` and therefore excluded from the default run and counted as
      not-run. The two figures are the same six tests seen from the two runs.
      Nothing else moved.

- [x] **9. README, version, CHANGELOG, worklog.** `README.md` gained a
      "How this repository is operated" paragraph and a "Related repositories"
      cross-reference table (PSModuleGraph as today's only consumer, ToHtml and
      PSTerraformGraph to come, and the harness that now governs it), plus a
      restated "Where the reasoning lives" table led by `HANDOFF.md`.
      `CHANGELOG.md` gained a `[0.13.0]` entry. `docs/worklog/v0.13.0.md`
      written, 111 lines, with a "What could not be verified" section.
      `ModuleVersion` corrected `0.11.0` → `0.13.0`; see Deviations.

- [x] **10. Commit, tag, push, fast-forward.** Staged path by path.

      ```
      964d73a Remove the resident workflow before two processes govern one commit
       41 files changed, 1403 insertions(+), 3365 deletions(-)
      ```

      Annotated `v0.13.0` carrying the counts and the required phrase. Branch and
      tag pushed. Ancestry verified **before** moving `main`:

      ```
      $ git merge-base --is-ancestor origin/main pass-0021-handoff
      origin/main IS an ancestor of pass-0021-handoff -> fast-forward is safe
      $ git push origin main
         4a367c6..964d73a  main -> main
      ```

- [x] **11. Acceptance green.**

      ```
      Describing Pass 0021 delivered
        [+] begin tag exists and marks the pre-handoff main 196ms
        [+] workflow machinery is gone 38ms
        [+] knowledge survives as archive 26ms
        [+] vendor tooling exists 23ms
        [+] handoff file exists and carries the essentials 60ms
        [+] v0.13.0 exists and main follows it 112ms
        [+] decision 0010 exists in the harness 18ms
      Tests Passed: 7, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
      ```

## 6. Acceptance test — green

Above, task 11. Same file, same command as the red run. 7/7.

## 7. Command transcript

```bash
# --- preconditions
git rev-parse HEAD                                   # both repos
git checkout -b pass-0021-psgraphrender-handoff main
git add AI.Agent.Claude.PowerShellModuleBuilder.code-workspace
git commit -m "Unrelated: editor added the four sibling repos to the workspace file …"
git -C ../PSGraphRender checkout -b pass-0021-handoff main
git -C ../PSGraphRender ls-remote --tags origin
pwsh -NoProfile -Command '$v = Import-PowerShellDataFile "src/PSGraphRender/TemplateSets/cytoscape/vendor/vendor.psd1"; $v.Files.Count'
pwsh -NoProfile -Command './build.ps1'                       # exit 1: browser harness absent
pwsh -NoProfile -Command './build.ps1 -Task BootstrapBrowser'
pwsh -NoProfile -Command './build.ps1'                       # baseline: 127 passed / 15 not-run
pwsh -NoProfile -Command './build.ps1 -Task PreTag'          # baseline: 15 passed

# --- acceptance, red
pwsh -NoProfile -Command 'Import-Module Pester -MinimumVersion 6.0.0; $c = New-PesterConfiguration; $c.Run.Path="plans/0021-psgraphrender-handoff/accept.Tests.ps1"; $c.Output.Verbosity="Detailed"; Invoke-Pester -Configuration $c'

# --- tags
git -C ../PSGraphRender tag -a handoff-begin-2026-08-29 4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995 -m "Begin marker: …"
git -C ../PSGraphRender push origin handoff-begin-2026-08-29

# --- strip
git rm -r -q CLAUDE.md .claude docs/threads.json tools/threads.ps1 tests/Ledger.Tests.ps1 tests/Instructions.Tests.ps1
git mv knowledge/ledger docs/ledger-archive
rmdir knowledge

# --- falsification (scratch copies only)
pwsh -NoProfile -File tools/Update-Vendor.ps1 -Verify -Root "$SP/falsify/control"   # exit 0
pwsh -NoProfile -Command "<flip byte 1000 of the copied cytoscape.min.js>"
md5sum "$F"                                                                         # before != after
pwsh -NoProfile -File tools/Update-Vendor.ps1 -Verify -Root "$SP/falsify/tamper"    # exit 1
sed -i "s|…/cytoscape.min.js|…/no-such-file-here.min.js|" "$M"
pwsh -NoProfile -File tools/Update-Vendor.ps1 -Update -Root "$SP/falsify/url404"    # exit 1

# --- build, commit, tag, push
pwsh -NoProfile -Command './build.ps1'                       # final: 122 passed / 9 not-run
pwsh -NoProfile -Command './build.ps1 -Task PreTag'          # final: 9 passed
git add <each path individually>
git commit -F -
git tag -a v0.13.0 -m "v0.13.0 - handoff complete: …"
git push -u origin pass-0021-handoff
git push origin v0.13.0
git merge-base --is-ancestor origin/main pass-0021-handoff   # exit 0 before any main move
git checkout main && git merge --ff-only pass-0021-handoff && git push origin main
git ls-remote origin

# --- acceptance green, verify
pwsh -NoProfile -Command '…Invoke-Pester…'                   # 7/7
pwsh -NoProfile -File plans/0021-psgraphrender-handoff/verify.ps1 -FailCheck
```

## 9. Verify script

`plans/0021-psgraphrender-handoff/verify.ps1`, committed beside this plan. Not
reproduced here: at ~250 lines a fenced copy would be a second executable in the
same commit that can disagree with the first.

It clones PSGraphRender from the remote at `v0.13.0` into a temp directory,
builds it, re-hashes both vendored files with its own sha384 implementation,
tampers a byte in its own scratch copy and confirms the tool goes red naming the
file, checks the tag topology and the harness decision, and confirms
`docs/HANDOFF.md` carries the four things the acceptance test names. It reads no
number this pass wrote down. `-FailCheck` adds the probe's own control: that the
tamper actually changed the bytes before the tool is asked about them.

Run at the end of the pass:

```
22 check(s), 0 failed.
```

Every check named its own verdict; the exit code is the aggregate (0).

## 10. Deviations

**1. The harness tree was dirty at preconditions.** An editor-written change to
the workspace file. Committed on its own before the pass, per PLAN-PROTOCOL.md.
Not a deviation from the prompt so much as the prompt's "rule 13" branch being
taken; recorded because the pass has an extra commit because of it.

**2. The baseline build failed on the first run, and the prompt's stop
condition did not apply.** Precondition 3 says to stop if the environment
*cannot* run the browser gate. The gate was merely not installed, and the build
ships `-Task BootstrapBrowser` for exactly that. Bootstrapping and re-taking the
baseline is not skipping the gate. Had the bootstrap failed, the pass would have
stopped.

**3. The first acceptance run was misconfigured by me.** I set
`Should.DisableV5 = $true`, copying PSGraphRender's build convention into the
harness. The prompt's test is written in Pester v5 `Should -Be` syntax, so every
test failed with a syntax error instead of an assertion. Re-run with defaults.
Worth noting for future passes: **the harness and PSGraphRender have opposite
Pester assertion conventions**, and an acceptance test written in the prompt is
in the harness's.

**4. `docs/testing.md` was about to ship 100% wrong about a gate.** It said the
`PreTag` gate is "one test — an open prune proposal that a second iteration
ignored". That test lives in `tests/Ledger.Tests.ps1`, which this pass deletes,
and the doc omitted the three `Describe` blocks in `tests/PreTag.Tests.ps1` that
survive. Left alone, the repository would have shipped a document describing
only the deleted test. Rewritten to describe what `PreTag` actually contains.
The prompt did not predict this; it is the "surviving test that gated removed
machinery in a way this prompt did not predict" the Deviations section asked
for, inverted — the *test* was fine, the *documentation of it* was not. Found
independently by job A3 and by my own pre-strip survey.

**5. `ModuleVersion` was a release behind, and I bumped it two.**
`src/PSGraphRender/PSGraphRender.psd1` read `0.11.0` at tag `v0.12.0`. Every tag
through v0.11.0 bumped it; v0.12.0 missed it and nothing gates the agreement
between manifest and tag. Set to `0.13.0`. The prompt did not ask for a version
bump; shipping a tag `v0.13.0` whose manifest says `0.11.0` seemed worse than
correcting an inherited miss, and `docs/improvements.md` already carries the
general observation that nothing enforces this agreement. **No gate was added**
— that would be scope creep — so the same miss can happen again.

**6. Only 17 of the 41 open threads went into `## Open`.** `docs/threads.json`
was a *merged* record across two repositories: 17 PSGraphRender threads and 24
PSModuleGraph ones. Carrying another repository's threads into this
repository's handoff would misfile them, and job A3 established that the
PSModuleGraph half of that file is **stale** — it was generated from 20 ledger
entries when that repository now has 33, and PSModuleGraph `0014-t1` was closed
at its entry `0022` and is listed as open here. Those threads are live in
PSModuleGraph and are not lost. Four of them bear directly on this seam, so they
are carried into `HANDOFF.md` as a named subsection ("What our only consumer is
still carrying about us") rather than as this repository's open threads. The
Open-list size the prompt asked to be reported is therefore **17**, plus 4
cross-referenced and 2 stub consumers.

**7. My first tamper probe proved nothing and reported green.** A git-bash path
(`/c/Users/…`) passed into `pwsh` was resolved as `C:\c\Users\…`; the write
failed, the file was never modified, and `-Verify` returned exit 0 — which was
*correct for an unmodified file* and completely meaningless as a falsification.
The before/after hash comparison caught it. This is the failure mode the whole
falsifiability practice exists to catch, reproduced by the person applying it,
and it is why `verify.ps1` carries `-FailCheck` asserting the break landed
before the check is trusted.

**8. Two parallel grep jobs wrote to one file.** In task 5's sweep, the patterns
`CLAUDE` and `\.claude` reduced to the same output basename, and on a
case-insensitive filesystem one silently overwrote the other. The counts looked
plausible. Re-run with distinct names; the second run found 7 `.claude` hits the
first had lost.

**9. `docs/contract.md` is stale and I left it that way.** Line 9 says "the
contract is 1.0.0 while PSGraphRender is 0.3.0". Both halves are wrong — the
contract is 1.1.0 and the module is now 0.13.0. The pass constraints say the
schema is not touched this pass and a contract document is not machinery, so
correcting it was out of scope. It is recorded here and in
`docs/worklog/v0.13.0.md`'s "what could not be verified" section. **Someone
should fix it.**

**10. A guarantee was genuinely lost, not migrated.**
`tests/Instructions.Tests.ps1` enforced "no instruction file may cause a push by
being followed". There are no instruction files left for it to scan, so deleting
it is right, but the rule is still true and is now stated in `docs/HANDOFF.md`
**unenforced**. Nothing checks that `HANDOFF.md` stays true either; the file it
replaces had a test asserting every path it named existed, and `HANDOFF.md`
names about a dozen. Recorded rather than glossed.

**11. A1 could not falsify one branch of its own tool.**
`Start-ThreadJob`'s absence has never been observed on this machine — PowerShell
7.6 ships the module in `$PSHOME\Modules` and it could not be removed from the
module path. The sequential *fallback* was exercised by forcing the flag (and
doing so found a real bug in it), but the *detection* has never returned false.

**12. `tools/threads.ps1` had invisible comment-based help.** Found by A1 while
matching house style: a `<# .SYNOPSIS #>` block butted against `#Requires`, or
separated from it only by a `#` comment, yields no comment-based help at all on
PowerShell 7.6.5 — `Get-Help` returns the syntax line as the synopsis. The
affected file was deleted this pass so nothing was done about it, but the trap
applies to anything else written to that template. `tools/Update-Vendor.ps1`
carries the blank line and a comment saying why.

## 11. Cost

Wall-clock for the pass: approximately 65 minutes, of which group A was 14.6
minutes at degree of parallelism 3 (875s wall against 1850s of job time — the
three jobs' own durations were 875s, 707s and 268s).

Run counts:

- `./build.ps1` full invocations: **5** (1 failed baseline, 1 green baseline,
  2 post-strip, 1 inside `verify.ps1`'s fresh clone) plus 1 `BootstrapBrowser`
  and 1 more inside verify's clone.
- `./build.ps1 -Task PreTag`: **2**.
- Acceptance suite runs: **3** (one invalid, one red, one green).
- `Update-Vendor.ps1` invocations during falsification and verify: **7**.
- `verify.ps1`: **2** (one syntax failure, one clean) — 22 checks.
- Parallel grep jobs: **10** (5 discarded to the filename collision, 5 kept).

No token count: the session cannot measure one, and a number without an
artifact behind it does not belong in a plan.
