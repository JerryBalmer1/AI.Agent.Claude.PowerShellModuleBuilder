# Pass 0022 — PSGraphRenderToHtml: producer contract, options, battery

Tier: full. Executed 2026-08-29, resumed after an interrupted overnight batch.

## 1. Prompt

The pass was issued twice: once in the overnight batch, then again as a
recovery batch after a session limit cut the first attempt off mid-pass. The
recovery prompt restated the pass in full and added resume semantics. Both are
reproduced.

### Recovery context and rules, as received

```
The overnight batch was interrupted during PASS 0022, before any commit or
push. Verified remote state: harness `main` = `05ede93…`; PSGraphRenderToHtml
remote = `abc9d9d…` (bare README, no other refs); PSTerraformGraph remote =
`b6e8dd8…` (bare); PSGraphRender `main` = `v0.13.0` = `964d73a…`. Local
working trees are expected to hold uncommitted 0022 work: ~33 files in
PSGraphRenderToHtml on local branch `pass-0022-contract`, and the 0022
acceptance test in the harness on local branch `pass-0022-tohtml-contract`.

Recovery rules, overriding the sync step's dirty-tree hard stop for exactly
these two trees:
- The uncommitted ToHtml and harness files are **inherited pass-0022 work**,
  not rule-13 unrelated changes. Do not delete them, do not commit them
  blindly. First action in 0022: `git status --porcelain` in both repos,
  recorded verbatim in the plan under "Inherited from interrupted session".
- **An inherited file is a draft, not evidence.** Nothing inherited is
  trusted until this batch's own tasks exercise it: the build must go green,
  the falsification sets must run, the battery must pass — on the files as
  they are or as you repair them. Repairs to inherited files are normal work,
  recorded per task, not Deviations.
- If any *other* repo's tree is dirty, or any local branch has diverged from
  its remote, that stays a hard stop per the standing sync rule.
- Acceptance-test resume semantics: run each pass's acceptance test first as
  always and record the red/green split as the starting state. Partial green
  from inherited work does **not** stop the pass (the green-at-start rule
  assumes a clean start); the remaining reds define the remaining work, and
  every already-green item must still be re-proved by the tasks that own it.
```

Batch rules, abbreviated to what bears on this pass: sync first (parallel
fetch per repo, fast-forward only); serial 0022 → 0023 → 0024; every pass ends
acceptance green with plan, verify, journal, branch pushed and mains
fast-forwarded per decisions 0009/0010, ancestry checked and never forced;
**push early — the first commit of each pass goes to its remote branch
immediately, and pushes follow every task group, because an interrupted
session must never again leave zero remote evidence.**

### The pass, as received

```
# PASS 0022 — PSGraphRenderToHtml: producer contract, options, battery (resume)
Tier: full

## Repositories
- `PSGraphRenderToHtml` — subject. Local `pass-0022-contract` (keep it; its
  base must be `abc9d9d83fe3baf8c06034c3a7b0cca27f9aa606`). First tag
  `v0.1.0`.
- `PSGraphRender` — read-only at v0.13.0 (`964d73a…`);
  `contract/viewmodel.schema.json` 1.1.0 is the mapping target.
- Harness — records on local `pass-0022-tohtml-contract` (keep; base
  `05ede93d148365c57b800bb2bcefea8ee373ffbc`).

## Preconditions (after sync + recovery inventory; hard stop on failure)
1. Branch bases as above; PSGraphRender clean at v0.13.0.
2. `Test-Json` accepts one of PSGraphRender's `docs/samples` viewmodels
   against its schema (proves tooling before building on it).
3. pwsh ≥ 7.2, Pester, git recorded. No PAT needed this pass.

## Acceptance test — red first (inherited copy may exist; overwrite with this)
`plans/0022-tohtml-contract/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$T = "$PSScriptRoot/../../../PSGraphRenderToHtml")
    Describe 'Pass 0022 delivered' {
        It 'producer contract exists and is versioned' {
            Test-Path "$T/contract/producer-graph.schema.json" | Should -BeTrue
            (Get-Content "$T/contract/producer-graph.schema.json" -Raw) |
                Should -Match '0\.1\.0'
        }
        It 'module builds' {
            Test-Path "$T/build.ps1" | Should -BeTrue
            Test-Path "$T/src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1" | Should -BeTrue
        }
        It 'public surface exists' {
            $m = Import-Module "$T/src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1" -Force -PassThru
            foreach ($f in 'Test-ProducerGraph','New-GraphRenderOptions',
                           'ConvertTo-GraphRenderViewModel','Export-ProducerGraphHtml') {
                $m.ExportedCommands.Keys | Should -Contain $f
            }
        }
        It 'battery exists for producers' {
            Test-Path "$T/tests/ProducerContract.Battery.ps1" | Should -BeTrue
        }
        It 'handoff and sample exist' {
            Test-Path "$T/docs/HANDOFF.md" | Should -BeTrue
            Test-Path "$T/docs/samples/sample-graph.json" | Should -BeTrue
        }
        It 'v0.1.0 on the remote' {
            (git ls-remote --tags https://github.com/JerryBalmer1/PSGraphRenderToHtml.git 'v0.1.0*') |
                Should -Not -BeNullOrEmpty
        }
    }

Run it; record the red/green split as the resume starting state.

## Plan (∥ = parallel jobs, outputs captured; commit+push after each group)
- [ ] 1. Recovery inventory (both porcelain outputs) + acceptance starting
      state. First commit of the inherited scaffold as-is, message
      "Inherited from interrupted batch, unverified", pushed — evidence
      before repair.
- [ ] 2. Scaffold to standard via the plugin's skills (/build, /test;
      powershell-module-scaffold/-build/-test/-architect/-docs): InvokeBuild,
      analyzer with ParseError severity, ordered tests, declared coverage
      threshold. Repair inherited files to this bar.
- [ ] 3. `contract/producer-graph.schema.json` semver `0.1.0`: `nodes[]`
      (required `id`,`label`,`type`,`scope`; optional nullable `parentId`;
      **no depth field, stored depth is invalid**), `edges[]` (`from`,`to`,
      `kind`), optional `meta`. Semantic rules in `Test-ProducerGraph`:
      edges resolve, parent chains acyclic, ids unique — every violation
      named with a JSON path. Bump protocol in the file header per the
      project context.
- [ ] 4. Public surface: `Test-ProducerGraph`; `New-GraphRenderOptions`
      (every layout the v0.13.0 cytoscape template set actually exposes —
      read it, don't guess — plus `plain`; interaction knobs incl. wheel/
      scroll speed as in PSModuleGraph's examples; theme; per-node
      `vscode://file/` links from a node→absolute-path map);
      `ConvertTo-GraphRenderViewModel` (depth derived here and only here;
      output valid against render schema 1.1.0);
      `Export-ProducerGraphHtml` (delegates to PSGraphRender; honours
      `graphrender.defaults.psd1` at the producer repo root — explicit
      param beats file beats built-ins, precedence tested).
- [ ] 5. `tests/ProducerContract.Battery.ps1` — parameterised (`-GraphPath`)
      Pester file any producer invokes: schema validity, semantic rules,
      conversion smoke against the render schema. Header states it is the
      ecosystem's enforcement point.
- [ ] 6. Falsification, ∥ two jobs then serial review:
      F1 eight violating graphs (missing id, duplicate id, dangling edge,
      parent cycle, stored depth, unknown top-level key, wrong type shape,
      empty label) each rejected with its named reason; one conforming
      `docs/samples/sample-graph.json` (≥12 nodes, parents/children/cross-
      links) accepted.
      F2 integration: `Export-ProducerGraphHtml` once per available layout
      into `docs/samples/` (committed), each HTML nonzero with its layout
      marker; one render carrying a vscode link, link present in the HTML.
- [ ] 7. Records: `docs/HANDOFF.md` (boundaries: never parses producer
      domains, never emits HTML except via PSGraphRender; contract
      location; ledger; next: producer adoption); README cross-refs
      (consumes PSGraphRender v0.13.0; consumers: PSTerraformGraph next,
      PSModuleGraph/PSAzureDevOpsGraph future); `docs/worklog/v0.1.0.md`.
      ∥ PSGraphRender README consumer line (own branch
      `pass-0022-consumer-ref`, main fast-forwarded) + harness README
      ecosystem section.
- [ ] 8. Build green; tag `v0.1.0` (battery + falsification counts in
      message); push branch + tag; fast-forward ToHtml `main`. Acceptance
      fully green. Harness plan/verify/journal; push; fast-forward harness
      `main`.

## Spot-checks — verify.ps1 re-derives
1. Fresh clone at v0.1.0: build green; battery green on the committed
   sample. 2. Verify regenerates the dangling-edge and parent-cycle
   violations itself; named rejection. 3. Sample viewmodel re-derived and
   re-validated against a fresh PSGraphRender clone's schema. 4. One layout
   HTML re-rendered and compared (byte, or stable-content with the reason
   recorded).

## Constraints
PSGraphRender untouched except the consumer line; render contract 1.1.0
untouched; no AzDO contact.
```

## 2. Preconditions

**Sync.** Six parallel `git fetch --all --tags --prune` jobs, all exit 0. Only
the two expected trees dirty; no repository ahead of or behind its remote.

```
AI.Agent.Claude.PowerShellModuleBuilder    pass-0022-tohtml-contract  dirty=1   ahead=0  behind=0
PSAzureDevOpsGraph                         main                       dirty=0   ahead=0  behind=0
PSGraphRender                              main                       dirty=0   ahead=0  behind=0
PSGraphRenderToHtml                        pass-0022-contract         dirty=12  ahead=0  behind=0
PSModuleGraph                              main                       dirty=0   ahead=0  behind=0
PSTerraformGraph                           main                       dirty=0   ahead=0  behind=0
```

**Inherited from interrupted session**, verbatim:

```
=== harness: git status --porcelain (branch pass-0022-tohtml-contract, base 05ede93d148365c57b800bb2bcefea8ee373ffbc) ===
?? plans/0022-tohtml-contract/

=== PSGraphRenderToHtml: git status --porcelain (branch pass-0022-contract, base abc9d9d83fe3baf8c06034c3a7b0cca27f9aa606) ===
 M README.md
?? .gitattributes
?? .gitignore
?? LICENSE
?? PSGraphRenderToHtml.build.ps1
?? PSScriptAnalyzerSettings.psd1
?? Requirements.psd1
?? build.ps1
?? contract/
?? docs/
?? src/
?? tests/
```

`--untracked-files=all` expands that to **33 files**, listed in
`scratchpad/0022-inherited-inventory.txt`. Both branch bases are exactly the
SHAs the prompt names.

**1. Branch bases and the renderer.**

```
render at: v0.13.0  clean=0
```

**2. Schema tooling, proved before anything was built on it.** The prompt says
`docs/samples`; that directory holds only PNGs in PSGraphRender, and the
viewmodels live in `tests/fixtures/viewmodels/`. All three were checked rather
than one:

```
ambiguous.json           Test-Json: True
infrastructure.json      Test-Json: True
sample-module.json       Test-Json: True
```

**3. Tools.** pwsh 7.6.5, Pester 6.1.0, git 2.41.0.windows.1. No PAT used.

## 3. Environment

pwsh 7.6.5, Pester 6.1.0, InvokeBuild 5.14.23, PSScriptAnalyzer, git
2.41.0.windows.1, Windows 11 Home 10.0.26200. ToHtml branch
`pass-0022-contract` based on `abc9d9d`; harness branch
`pass-0022-tohtml-contract` based on `05ede93`.

## 4. Acceptance test — resume starting state

The prompt's exact text overwrote the inherited copy. First run:

```
  [+] producer contract exists and is versioned
  [+] module builds
  [-] public surface exists       Expected 'Test-ProducerGraph' to be found in collection @($null)
  [+] battery exists for producers
  [+] handoff and sample exist
  [-] v0.1.0 on the remote        Expected a value, but got $null or empty
Tests Passed: 4, Failed: 2
```

`public surface exists` was red for a reason worth keeping: the module declares
`RequiredModules = @{ ModuleName = 'PSGraphRender'; ModuleVersion = '0.13.0' }`
and `Get-Module -ListAvailable PSGraphRender` returned **count=0** on this
machine. `Import-Module` enforces `RequiredModules`, so the module could not
load at all. PSModuleGraph declares the identical dependency, so this is the
ecosystem's convention and correct; the renderer simply was not installed. It
was built and installed to the user module path, and the starting state
re-recorded:

```
  [+] producer contract exists and is versioned
  [+] module builds
  [+] public surface exists
  [+] battery exists for producers
  [+] handoff and sample exist
  [-] v0.1.0 on the remote
Tests Passed: 5, Failed: 1
```

**Resume starting state: 5 passed, 1 failed.** The single red is the tag, which
only task 8 can satisfy. Per the recovery rules this does not stop the pass, and
every already-green item was re-proved by the task that owns it.

## 5. Tasks

- [x] **1. Recovery inventory, and evidence before repair.** Inventory above.
      The 33 inherited files were staged path by path — never `git add -A` —
      and committed unrepaired:

      ```
      4123ea7 Inherited from interrupted batch, unverified
      ```

      Pushed immediately: `* [new branch] pass-0022-contract`. The harness
      acceptance test likewise (`5cf7f9d`, pushed). From this point the work
      had remote evidence at every step, which is what the batch rule asks.

- [x] **2. Scaffold to standard.** Re-proved rather than assumed — the build
      was run against the inherited files before anything was changed:

      ```
        PSGraphRender: 0.13.0 at .../PSGraphRender/src/PSGraphRender/PSGraphRender.psd1
      Tests Passed: 48, Failed: 0
      Line coverage: 88.14% (target 75%)
      Build succeeded. 6 tasks, 0 errors, 0 warnings
      ```

      The scaffold follows `powershell-module-scaffold` and
      `powershell-module-build`: `build.ps1` resolving pinned dependencies
      without installing, `PSGraphRenderToHtml.build.ps1` with Clean, Lint,
      Build, Test, PreTag and a default of exactly `Clean, Lint, Build, Test`;
      `Severity = @('ParseError','Error','Warning')`; `Run.Throw` and never
      `Run.Exit`; `Should.DisableV5`; `Filter.ExcludeTag = 'PreTag'`;
      coverage measured against the built psm1 with the threshold read back
      off the result rather than kept in a second place.

      A `ResolveRenderer` task checks every constraint `RequiredModules` can
      express — `RequiredVersion`, `ModuleVersion`, `MaximumVersion` — rather
      than the one written today, and prints the version it resolved.

- [x] **3. The producer contract.** `contract/producer-graph.schema.json`,
      version `0.1.0`. `additionalProperties: false` at every level, so a
      stored depth is a validation *error* rather than a field nobody reads.
      Containment is `parentId` and never an edge. An edge may carry
      `resolved: false`, and must then carry a `reason`.

      Semantic rules live in `Test-ProducerGraph`: unique ids, resolving edge
      endpoints, acyclic parent chains, `resolved: false` stating a reason,
      and `kind: contains` refused by name. The bump protocol is in the file
      header and mirrors the render contract's.

- [x] **4. The public surface.** Four commands. The layouts were **read** out
      of PSGraphRender v0.13.0 — `FLOW_LAYOUT` in
      `TemplateSets/cytoscape/scripts/render.js` gives exactly `foundation`,
      `testorder`, `callflow` — and the interaction defaults out of
      `Config/settings.psd1` (`ZoomSpeed` 1.25 within bounds 0.25–5,
      `FocusDepth` 2, `NodeLimit` 400, `MinReadableZoom` 0.45). A test asserts
      the `ValidateSet` equals the `FLOW_LAYOUT` keys, so a list written from
      memory cannot silently stop matching the renderer.

      `New-RenderDocument` has no settings parameter by design, so an option
      is applied by copying the chosen backend to a temporary overlay, merging
      the values, and passing `-TemplateSetPath` — the parameter PSGraphRender
      documents for a backend it does not ship. The overlay refuses a key the
      backend has never declared, and is removed after every render (asserted).

      Precedence — explicit beats file beats built-in, merged per key — is
      tested in five assertions including the per-key merge and an unknown key
      refused by name.

- [x] **5. The battery.** `tests/ProducerContract.Battery.ps1`, parameterised
      on `-GraphPath`, header stating it is the ecosystem's enforcement point.
      Run as a producer runs it:

      ```
      Describing The graph a producer emits
        [+] is valid against the producer contract, with every violation named
        [+] is not empty
        [+] states its own provenance
        [+] carries no node that stores its own depth
      Describing The graph converts to something the renderer accepts
        [+] maps to a view model that satisfies PSGraphRender contract 1.1.0
        [+] derives a depth for every node
        [+] carries every unresolved reference through rather than dropping it
      Tests Passed: 7, Failed: 0
      ```

- [x] **6. Falsification.** The prompt asks for two parallel jobs. Both were
      dispatched as subagents and **both died on a session rate limit**
      (HTTP 429) before producing anything. They were re-run serially in this
      session instead. **Degree of parallelism for this group: 1**, not 2, and
      the reason was an infrastructure limit rather than a choice.

      **F1 — eight violating graphs, `scratchpad/0022-F1-falsification.txt`.**
      Each starts from a known-good graph and changes exactly one thing, and
      each mutation is proved to have landed (serialised texts compared) before
      its red is trusted:

      ```
      REJECTED: missing-id    [schema]                       graph.nodes[1]
      REJECTED: duplicate-id  [edge-endpoint-resolves,unique-node-id]
      REJECTED: dangling-edge [edge-endpoint-resolves]        graph.edges[0].to
      REJECTED: parent-cycle  [acyclic-parent-chain]          all three nodes named
      REJECTED: stored-depth  [schema]                        graph.nodes[1].depth
      REJECTED: unknown-key   [schema]                        graph.vertices
      REJECTED: wrong-type    [schema]                        graph.nodes[1].scope
      REJECTED: empty-label   [schema]                        graph.nodes[1].label
      CONTROL: sample-graph.json IsValid True, 15 nodes, 10 edges, 0 violations

      REJECTED: 8 / 8   ACCEPTED: 1 / 1
      ```

      **F1's first run found a real defect.** Every schema-layer violation
      reported path `$` while the JSON Pointer naming the real location sat
      unparsed in the message — `Test-Json` on PowerShell 7 ends each line with
      `at '/graph/nodes/1/depth'`, and none of the three patterns tried matched
      that shape. The contract promises a path for every violation and the same
      path for all of them is the same as none. Fixed: the pointer is converted
      to the dotted-and-indexed form the semantic rules already emit, so a
      caller formats every violation identically regardless of which layer
      found it. 11 assertions added, including both RFC 6901 escapes and the
      fallback. Commit `95dfb75`, pushed. The paths in the table above are from
      the re-run.

      **F2 — integration, `scratchpad/0022-F2-integration.txt`.** Five renders
      into `docs/samples/`, committed:

      ```
      sample-foundation.html     616412 bytes   DefaultFlow=foundation
      sample-testorder.html      616411 bytes   DefaultFlow=testorder
      sample-callflow.html       616410 bytes   DefaultFlow=callflow
      sample-plain.html           12109 bytes   plain backend, no layouts
      sample-editorlinks.html    616488 bytes   vscode://file/... present

      RENDERED: 5 / 5   MARKERS DISCRIMINATING: yes
      ```

      Markers proved **discriminating**, not merely present — a full diagonal:

      ```
      file                        foundation    testorder     callflow
      sample-foundation.html      True          False         False
      sample-testorder.html       False         True          False
      sample-callflow.html        False         False         True
      ```

      And the link assertion is not vacuous: a render without the map does not
      contain the vscode string. The three cytoscape documents differ by one
      and two bytes — the length of the layout name in the embedded config and
      nothing else. The layout marker is `DefaultFlow` in the embedded
      configuration, **not** the `data-layout` attribute, which is set by
      script at runtime and is absent from the static document; asserting on it
      would have asserted on nothing.

- [x] **7. Records.** `docs/HANDOFF.md` (what it is, contract and change
      protocol, five boundaries, version ledger, how it is operated, the
      battery, five open items, consumers). `README.md` with the one rule, the
      contract, the commands, the defaults file, the battery, and a Related
      repositories table. `docs/worklog/v0.1.0.md`.

      ∥ arm: PSGraphRender's README consumer row on its own branch
      `pass-0022-consumer-ref`, ancestry checked, `main` fast-forwarded to
      `0156ba7be959c7873f05beb4a80c97aa6ab75277`. Harness README gained an
      ecosystem section naming all six repositories (`c12bcd7`).

- [x] **8. Build green, tagged, pushed, fast-forwarded.**

      `./build.ps1 -Task PreTag` **failed** on first run — the task existed and
      its own zero-test guard fired, because no test carried the `PreTag` tag.
      A task that can only fail is not a gate. Six seals were written, two of
      which reinstate guarantees PSGraphRender recorded as *lost* at v0.13.0
      when `tests/Instructions.Tests.ps1` went with the resident workflow:
      documentation names only paths that exist, and no document can cause a
      push by being followed.

      The path gate found two things on its first run — one real defect
      (`docs/vendoring.md`, a local vendoring document this module does not
      have and should not claim, since it vendors nothing) and one false
      positive (`graphrender.defaults.psd1`, a file a *producer* creates in its
      own repository). The defect was fixed; the gate was narrowed to paths
      carrying a directory this tree has, because a gate that cries wolf trains
      a reader to ignore it.

      The analyzer then caught `$matches` — an automatic variable holding regex
      captures — being assigned in that same file, which also uses `-match`.
      It had gone green under `-Task PreTag` and red under the default build,
      because `PreTag` depends on `Build` and not on `Lint`.

      Final:

      ```
      ./build.ps1              exit 0.  Tests Passed: 59, Failed: 0, NotRun: 6
                                        Line coverage: 87.74% (target 75%)
      ./build.ps1 -Task PreTag exit 0.  Tests Passed: 6, Failed: 0, NotRun: 59
      ```

      Annotated tag `v0.1.0` carrying the counts. Branch and tag pushed.
      Ancestry verified before moving `main`:

      ```
      $ git merge-base --is-ancestor origin/main pass-0022-contract
      ancestry OK -> fast-forward safe
      bb2fbacbc6c1cded4d49fc17e79bf54a82150281  refs/heads/main
      74131284643a2b4dcd9c84c0447d666cbd9bace3  refs/tags/v0.1.0
      bb2fbacbc6c1cded4d49fc17e79bf54a82150281  refs/tags/v0.1.0^{}
      ```

## 6. Acceptance test — green

```
  [+] producer contract exists and is versioned 179ms
  [+] module builds 15ms
  [+] public surface exists 508ms
  [+] battery exists for producers 19ms
  [+] handoff and sample exist 9ms
  [+] v0.1.0 on the remote 583ms
Tests Passed: 6, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
```

## 7. Command transcript

```bash
# --- sync and inventory
for r in <six repos>; do ( git -C "$r" fetch --all --tags --prune ) & done; wait
git -C AI.Agent.Claude.PowerShellModuleBuilder status --porcelain
git -C PSGraphRenderToHtml status --porcelain --untracked-files=all

# --- preconditions
pwsh -NoProfile -Command 'Get-Content tests/fixtures/viewmodels/*.json -Raw | Test-Json -SchemaFile contract/viewmodel.schema.json'
pwsh -NoProfile -Command 'Get-Module -ListAvailable PSGraphRender'          # count=0
cd PSGraphRender && pwsh -NoProfile -Command './build.ps1 -Task Build'
# renderer installed to the user module path, so RequiredModules can resolve

# --- acceptance, resume starting state
pwsh -NoProfile -Command '...Invoke-Pester plans/0022-tohtml-contract/accept.Tests.ps1'   # 5 passed 1 failed

# --- task 1: evidence before repair
git add <33 paths, individually>
git commit -F -                      # 4123ea7 Inherited from interrupted batch, unverified
git push -u origin pass-0022-contract

# --- task 2: re-prove the inherited build
pwsh -NoProfile -Command './build.ps1'                    # 48 passed, 88.14%

# --- task 6: falsification, run serially after both subagents hit a rate limit
pwsh -NoProfile -File scratchpad/f1.ps1                   # REJECTED 8/8 ACCEPTED 1/1
pwsh -NoProfile -File scratchpad/f2.ps1                   # RENDERED 5/5, discriminating
git add src/.../Get-SchemaViolationPath.ps1 tests/Contract.Tests.ps1
git commit -F - && git push origin pass-0022-contract     # 95dfb75
git add docs/samples/sample-*.html
git commit -F - && git push origin pass-0022-contract     # 0a50f8c

# --- task 7: the parallel arm
cd PSGraphRender && git checkout -b pass-0022-consumer-ref main
git commit -am '...' && git push -u origin pass-0022-consumer-ref
git merge-base --is-ancestor origin/main pass-0022-consumer-ref
git checkout main && git merge --ff-only pass-0022-consumer-ref && git push origin main

# --- task 8
pwsh -NoProfile -Command './build.ps1 -Task PreTag'       # failed: selected no test
# six seals written, README defect fixed, gate narrowed, $matches renamed
pwsh -NoProfile -Command './build.ps1'                    # 59 passed, 87.74%
pwsh -NoProfile -Command './build.ps1 -Task PreTag'       # 6 passed
git tag -a v0.1.0 -m '...'
git push origin pass-0022-contract && git push origin v0.1.0
git merge-base --is-ancestor origin/main pass-0022-contract
git checkout main && git merge --ff-only pass-0022-contract && git push origin main

# --- verify
pwsh -NoProfile -File plans/0022-tohtml-contract/verify.ps1
```

## 9. Verify script

`plans/0022-tohtml-contract/verify.ps1`, committed beside this plan. Not
reproduced here: at ~280 lines a fenced copy would be a second executable in
the same commit that can disagree with the first.

It clones **both** repositories fresh — ToHtml at `v0.1.0`, PSGraphRender at
`v0.13.0` — builds the renderer, builds the subject, runs its suite and its
PreTag seals, runs the battery as a producer invokes it, builds its **own**
violating graphs rather than borrowing the subject's test helpers, re-derives
the sample view model and validates it against the freshly cloned schema,
re-renders a layout and compares it to the committed document, and checks the
tag topology.

Run at the end of the pass:

```
17 check(s), 0 failed.
```

Its **first** run reported `17 check(s), 3 failed`, and all three were verify's
own defects rather than the module's — which is the script doing its job:

- `1a/1b` — a fresh clone of PSGraphRender is not importable, because its
  manifest's `RootModule` names a psm1 the build generates. Verify now builds
  the renderer clone before pointing at it. **This is a real ecosystem fact**:
  a fresh consumer must build the renderer, not merely clone it.
- `4c` — the re-render differed from the committed document by 428 characters
  after normalising the timestamp. Measured rather than assumed: exactly 428
  carriage returns. `.gitattributes` carries `* text=auto eol=lf`, so the
  committed document is stored and checked out LF while a fresh render on
  Windows writes CRLF. Both normalisations are now applied and both are stated
  in the script, and check `4d` is the control that a genuinely different
  document still differs after the same normalisation.

## 10. Deviations

**1. The pass was resumed, not started.** An overnight session limit cut the
first attempt off with 33 files uncommitted and zero remote evidence. The
recovery rules were followed exactly: inventory first, inherited state
committed unrepaired and pushed before any repair, everything re-proved by the
task that owns it.

**2. Both falsification subagents died on a session rate limit.** HTTP 429,
before either produced output. F1 and F2 were re-run serially in this session.
**The parallel group ran at degree of parallelism 1**, and the plan says so
rather than claiming a parallelism that did not happen.

**3. The acceptance test required an environment precondition the prompt does
not list.** `Import-Module` enforces `RequiredModules`, PSGraphRender was not
installed (`Get-Module -ListAvailable` returned count=0), and the module
therefore could not load at all. The renderer was built and installed to the
user module path. This is a machine-local fact, not a repository change, and
`verify.ps1` handles it by building its own clone rather than relying on it.

**4. The scaffold skill's manifest pattern makes `src/` un-importable, and the
acceptance test imports from `src/`.** `RootModule` names the *generated* psm1,
which exists only in `output/` — PSGraphRender itself cannot be imported from
`src/` today. A committed dev-loader `.psm1` resolves it: it dot-sources rather
than concatenates, so `$script:ModuleRoot` means the same thing under both
loaders and any asset resolves either way. **`powershell-module-scaffold`
mentions neither the problem nor the fix**, and this is the most important
finding of the pass for the plugin.

**5. Two analyzer rules needed reasoned exclusions rather than silence.**
`PSUseSingularNouns` fires on `New-GraphRenderOptions`, whose name the
ecosystem's acceptance test fixes — renaming it to satisfy a style rule would
break the contract. `PSReviewUnusedParameter` is a false positive on the
battery's `param()` block, because the analyzer cannot see through Pester's
`BeforeAll`/`It` scriptblocks; it is excluded **for `tests/` only**, in the
build file rather than the settings file, so it still guards `src/`.

**6. A real bug, found by running rather than reading.**
`Get-ProducerGraphDepth` had a parameter `$Node` and a loop variable `$node`.
PowerShell variable names are case-insensitive, so those are **one variable**:
the first `foreach` overwrote the parameter with its last element and the
second then iterated a single object. The result was a depth table with 1 entry
out of 15, no error and no warning, surfacing three layers away as
`metrics.depth` being null against the render contract. The parameter is
`$InputNode` now and the reason is in the function's own help.

**7. A stray `coverage.xml` appeared at the repository root.** Pester's default
output path. This is precisely the incident `.claude/skills/README.md` records
— a blind `git add -A` sweeping one into a commit titled `asdf`. Fixed at the
cause by setting `CodeCoverage.OutputPath` into `output/`, which `Clean`
removes and `.gitignore` excludes, rather than by gitignoring the symptom.

**8. `-Task PreTag` was a task that could only fail.** It existed with no
`PreTag`-tagged test, so its own zero-test guard failed it every run. Six seals
were written. Two of them reinstate guarantees pass 0021 recorded as *lost and
unenforced* when PSGraphRender's `Instructions.Tests.ps1` was deleted. That
pass's Deviations named the loss; this one closes it in the repository that
inherited the same exposure.

**9. The PreTag task is not linted.** It depends on `Build`, not on `Lint`, so
the `$matches` automatic-variable assignment went green under `-Task PreTag`
and red under the default build. A gate that is not linted is a gate whose own
defects arrive later than everything else's.

**10. The prompt's precondition 2 names a path that holds no viewmodels.**
PSGraphRender's `docs/samples/` contains only PNGs; the viewmodels are in
`tests/fixtures/viewmodels/`. All three were validated instead of one.

**11. `New-RenderDocument` has no settings parameter**, so options cannot be
passed to a render directly. They are applied by materialising a temporary
overlay of the chosen backend and passing `-TemplateSetPath`. This respects
PSGraphRender's rule that adding a setting must require editing data files
only, and it means applying an option never edits the renderer — but it copies
a whole backend, roughly half a megabyte of vendored JavaScript, per render.
Correct, and wasteful if anything ever renders in a loop. Recorded in HANDOFF's
Open section.

## 11. Cost

Wall-clock for the resumed pass: approximately 80 minutes. Group A of the
original attempt is not counted here; its work survives as the inherited
commit.

Run counts:

- `./build.ps1` full invocations: **7** (1 on inherited files, 4 during repair,
  1 final, 1 inside verify's fresh clone).
- `./build.ps1 -Task PreTag`: **4** (1 failing on the empty filter, 1 failing
  on the path gate, 1 green, 1 inside verify).
- Battery runs: **3** (1 direct, 1 in the suite, 1 inside verify).
- Acceptance suite runs: **3** (two starting-state, one green).
- `verify.ps1`: **2** — 17 checks, 3 failed then 0 failed.
- Falsification scripts: **3** (F1 twice, either side of the path fix; F2 once).
- Parallel fetch jobs: **6**.
- Subagents dispatched: **2**, both terminated by a rate limit, **0** results.

No token count: the session cannot measure one, and a number without an
artifact behind it does not belong in a plan.
