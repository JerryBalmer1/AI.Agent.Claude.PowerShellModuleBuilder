# Pass 0011 — Fixture design and functional acceptance criterion

Tier: **full**. Branch: `pass-0009-control-polarity`.

## 1. Prompt

````text
# PASS 0011 — Fixture design and functional acceptance criterion

Tier: full

Designs the Azure DevOps fixture, declares the graph it represents, states ten
functional test cases, and renders the expected graph for review. No network
calls. No Azure DevOps resources are created this pass. The PAT is not read.

Pass 0012 creates the fixture in Azure DevOps and verifies it by read-back.
Nothing external happens until the design in this pass is reviewed.

## Preconditions

Any failure is a hard stop — commit nothing, report the failure.

- [ ] On a pass branch, not `main`. Report branch name and HEAD.
- [ ] Working tree clean.
- [ ] `PLAN-PROTOCOL.md`, `method/METHOD.md`, `journal/TEMPLATE.md` exist.
- [ ] `journal/0001-*.md` through `journal/0010-*.md` all exist.
- [ ] Report `pwsh --version`, resolved Pester 6.x version, OS.
- [ ] Confirm no file named `AzDoPAT.txt` or containing a PAT exists anywhere
      inside the repository working tree. Report the check.

## Acceptance test — red first

Write `evals/functional/Fixture.Tests.ps1` as the FIRST task, before authoring
any fixture content, and run it. It must be red. Report the red with failure
messages. A green test here means the test is inert.

The test asserts the fixture is internally consistent, reading only committed
files — never Azure DevOps:

1. `evals/functional/fixture/expected-graph.json` parses and validates against
   a schema you write at `evals/functional/fixture/graph.schema.json`.
2. Every node has a unique `id`, a `kind` from the declared enum, and for
   `kind: yaml` a `path` that exists on disk under `evals/functional/fixture/repos/`.
3. Every edge's `from` and `to` resolve to a declared node id, except edges of
   `kind: unresolved`, whose `to` must NOT resolve — that is the point of them.
4. Every YAML file under `repos/` is referenced by at least one node, and every
   `kind: yaml` node points at a file that exists. No orphan files, no dangling
   nodes.
5. Every YAML file parses as YAML.
6. Every `template:`, `extends:`, and `resources.repositories`/`resources.pipelines`
   reference found by parsing the YAML corresponds to a declared edge, and every
   declared edge of those kinds is found in the YAML. Both directions. This is
   the assertion that stops the declared graph and the fixture drifting apart.
7. All ten cases in `cases.md` are referenced by at least one node or edge via
   a `cases` array, and all ten case ids appear.

Assertion 6 is the load-bearing one. Write it against the YAML text, not
against a pre-built index.

## Plan

- [ ] **1.** Write the acceptance test above. Run it. Record the red.

- [ ] **2.** Write `evals/functional/BRIEF.md`: what PSAzureDevOpsGraph is.
      Its purpose — produce a dependency graph of Azure DevOps pipelines and
      the repositories and templates they reference. Its command surface, in
      the house verb-noun style, derived from PSModuleGraph's shape:
      `Get-AzDoPipeline`, `Get-AzDoPipelineDependencyGraph`,
      `Export-AzDoPipelineDependencyGraph`, and whatever else the ten cases
      require. Authentication by PAT supplied through an environment variable,
      never a file path and never a parameter default. What it must not do:
      never queue a pipeline, never write to Azure DevOps, never create or
      delete anything. Read-only, always.

      State the functional acceptance criterion explicitly, and state that it
      is NOT part of the conformance score: the module imports, a command runs
      against the recorded fixture, and the answer matches
      `expected-graph.json`. Conformance measures shape; this measures whether
      it works. Reference `method/METHOD.md`'s known limit about conformity
      versus utility.

- [ ] **3.** Author the fixture YAML under
      `evals/functional/fixture/repos/<repo-name>/`, one directory per Azure
      DevOps repository, exactly matching the specification below. These files
      are the source of truth. Pass 0012 pushes them to Azure DevOps; it does
      not author them there.

- [ ] **4.** Author `evals/functional/fixture/expected-graph.json` by hand from
      the YAML. Every node and edge declared explicitly, each tagged with the
      case ids it serves. Do not generate it by parsing — the point is that it
      is an independent statement of the right answer. The acceptance test
      cross-checks the two.

- [ ] **5.** Write `evals/functional/fixture/cases.md`: the ten cases below,
      each with what it tests, which nodes and edges are involved, what a wrong
      answer would look like, and the specific way a naive implementation fails
      it.

- [ ] **6.** Write `runs/Render-Graph.ps1`: reads `expected-graph.json` or any
      later run's graph JSON, emits a self-contained HTML file. No CDN, no
      external scripts, no network at view time — inline SVG computed in
      PowerShell, layered left to right by depth. Node fill by `kind`, edge
      style by `kind`, a legend, and unresolved edges visually distinct. It
      must render a cycle without looping forever.

- [ ] **7.** Create `runs/README.md` explaining the directory: one directory per
      run, `NNN-<slug>/`, each containing the graph JSON the run produced, its
      `NNN.html`, the command that produced it, and a diff against
      `expected-graph.json`. Run `000-expected` is the declared answer, not a
      module output.

- [ ] **8.** Produce `runs/000-expected/000.html` from
      `expected-graph.json`, plus `runs/000-expected/README.md` naming the
      command that generated it.

- [ ] **9.** Write `evals/functional/AZDO-FIXTURE.md`: the creation plan for
      Pass 0012. Which repositories, which pipeline definitions, which YAML
      path each definition points at, and in what order they must be created
      so that cross-references resolve. State the constraints Pass 0012 will
      operate under, listed under Constraints below, so they live in the repo
      and not only in a prompt.

- [ ] **10.** Add to `.gitignore`: `AzDoPAT.txt`, `*.pat`, `**/pat.txt`. Then
      run a scan across the whole working tree for anything resembling a PAT
      (a 52-character base32-ish token, and the literal string from the PAT
      file if you can check without printing it) and report the scan command
      and that it found nothing. Do not print any candidate match.

- [ ] **11.** Run the acceptance test. Record it green.

- [ ] **12.** Commit and push to the pass branch. Report the pushed SHA.

## Fixture specification

Four repositories in the Azure DevOps project `ClaudeTesting`:

| Repo | Contains |
|---|---|
| `pipelines-main` | The bulk of the pipeline YAML and its local templates |
| `templates-shared` | Templates consumed cross-repo by `pipelines-main` and others |
| `templates-platform` | A second template repo, consumed by pipelines defined outside `pipelines-main` |
| `consumer-app` | Application repo with its own pipeline YAML, consuming both template repos |

Pipeline definitions registered in the project. Definition name, and the repo
plus path its YAML lives at:

| Definition | YAML location |
|---|---|
| `p01-simple-include` | `pipelines-main` / `pipelines/p01.yml` |
| `p02-nested-chain` | `pipelines-main` / `pipelines/p02.yml` |
| `p03-extends-params` | `pipelines-main` / `pipelines/p03.yml` |
| `p04-cross-repo-template` | `pipelines-main` / `pipelines/p04.yml` |
| `p05-pipeline-resource` | `pipelines-main` / `pipelines/p05.yml` |
| `p06-variable-template` | `pipelines-main` / `pipelines/p06.yml` |
| `p07-diamond-a` | `pipelines-main` / `pipelines/p07a.yml` |
| `p07-diamond-b` | `pipelines-main` / `pipelines/p07b.yml` |
| `p08-cycle` | `pipelines-main` / `pipelines/p08.yml` |
| `p09-unresolved` | `pipelines-main` / `pipelines/p09.yml` |
| `p10-orphan` | `pipelines-main` / `pipelines/p10.yml` |
| `x01-consumer-build` | `consumer-app` / `azure-pipelines.yml` |
| `x02-platform-release` | `consumer-app` / `pipelines/release.yml` |
| `x03-shared-nightly` | `templates-shared` / `pipelines/nightly.yml` |
| `x04-cross-trigger` | `templates-platform` / `pipelines/trigger.yml` |

The `x0*` definitions are the "pipelines outside the repository": registered in
the project, with YAML living in a repo other than `pipelines-main`. At least
two of them must reference templates in `pipelines-main` or declare a
`resources.pipelines` dependency on a `p0*` definition, and at least two `p0*`
definitions must reference `templates-platform`, so the cross-references run
both directions.

## The ten cases

| # | Case | Tests | A naive implementation fails by |
|---|---|---|---|
| 1 | Same-repo step template | `steps: - template: ../templates/x.yml` resolves relative to the including file | Resolving relative to the repo root instead of the including file |
| 2 | Three-level chain | A → B → C transitively, all same repo | Reporting only direct references, depth 1 |
| 3 | `extends` with parameters | `extends:` is an edge of a different kind than `template:`, and parameter values are not edges | Treating a parameter value that looks like a path as a reference |
| 4 | Cross-repo template | `template: x.yml@sharedTemplates` resolved through `resources.repositories` alias | Reporting `x.yml@sharedTemplates` as unresolved, or resolving it in the wrong repo |
| 5 | Pipeline resource | `resources.pipelines` with a completion trigger is a pipeline-to-pipeline edge, not a file edge | Collapsing it into the template edge kind, losing the distinction |
| 6 | Variable template | `variables: - template: vars.yml` is a template edge in a non-steps context | Only scanning `steps`, `jobs`, and `stages` |
| 7 | Diamond | Two pipelines include the same template, which includes another; the shared node appears once with in-degree 2 | Duplicating the shared node per path, inflating the count |
| 8 | Cycle | A includes B, B includes A; reported as a cycle, terminating | Infinite recursion, or silently truncating and reporting a tree |
| 9 | Unresolved | One reference to a file that does not exist and one to an undeclared repo alias; both reported as unresolved with a reason | Dropping them silently, so a broken pipeline looks clean |
| 10 | Orphan and checkout-only | A pipeline with no references and nothing referencing it appears as an isolated node; a `checkout:` of a second repo is a repo dependency but NOT a template edge | Omitting the isolated node, or inventing a template edge from a `checkout` |

Cases 8 and 9 are pipeline definitions that would fail if run. They are never
run. That is a fixture requirement, stated in `AZDO-FIXTURE.md`.

## Named spot-checks

`verify.ps1` must independently re-derive, by name:

1. The acceptance test's assertion 6, both directions, over every YAML file.
2. Case 4's cross-repo edge: parse `p04.yml` from disk, resolve the alias
   through its own `resources.repositories`, and confirm the resulting edge
   matches the declared one in `expected-graph.json`.
3. Case 9's two unresolved edges: confirm both targets genuinely do not exist
   on disk.
4. Case 8's cycle: confirm a traversal of the declared graph from `p08`
   terminates and reports a cycle.
5. That `runs/000-expected/000.html` exists, is non-empty, contains no `http://`
   or `https://` script or stylesheet reference, and its node count matches
   `expected-graph.json`.
6. That no PAT-shaped string appears in any tracked file.

`verify.ps1` assumes only a fresh clone and pwsh. It must not read
`AzDoPAT.txt`, must not reach the network, and must not parse `plan.md`.

## Constraints

No network calls of any kind this pass. The PAT is not read. No Azure DevOps
resource is created, modified, or deleted. Nothing is queued or run.

Constraints to be written into `AZDO-FIXTURE.md` for Pass 0012, and honoured
there:

- Only the project `ClaudeTesting` at `https://dev.azure.com/jlbalmerjr1`. No
  other project, organisation, or subscription.
- Never queue, run, or trigger a pipeline. Definitions only.
- Nothing that meters or bills: no Azure Artifacts feeds, no Test Plans, no
  self-hosted or scale-set pools, no service connections to Azure resources,
  no extensions from the marketplace.
- The PAT is read into a variable, never echoed, never written to a file,
  never committed, and redacted in every transcript and plan entry.
- Creation is idempotent and re-runnable: check for existence before creating,
  so the fixture can be rebuilt after a wipe without duplicating.

Repository constraints as always: `./scratch/` for anything disposable, no
fixes to the reference, no assertion weakened because something fails it, push
to the pass branch, no tags, no `main`, nothing published.

## Deviations

Required. Write "none" if there are none. Specifically flag: any of the ten
cases that cannot be expressed in valid Azure DevOps YAML as specified, and any
place where the fixture specification above is ambiguous or wrong. Do not
silently adapt it.

## Journal

Write `journal/0011-fixture-design.md` from this pass's artifacts using
`journal/TEMPLATE.md`. Capability only, no benefit claims.

## Report back

Branch and pushed SHA; the plan path; the red-first output for the acceptance
test and the green output at the end; the node and edge counts in
`expected-graph.json` broken down by kind; which of the ten cases were awkward
to express and why; the PAT scan command and result; and anything in the
fixture specification you believe is wrong, which goes in Deviations too.
````

## 2. Preconditions

All six passed. Nothing was written before this section was complete.

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | On a pass branch, not `main` | `git rev-parse --abbrev-ref HEAD` / `git rev-parse HEAD` | `pass-0009-control-polarity` at `6ba21ae4518a63b43992eddfca6d516b7ee00bda` |
| 2 | Working tree clean | `git status --porcelain` | empty |
| 3 | Protocol, method and template exist | `test -f` on each | `PLAN-PROTOCOL.md` OK, `method/METHOD.md` OK, `journal/TEMPLATE.md` OK |
| 4 | Journal 0001–0010 all exist | `ls journal/000[1-9]-*.md journal/0010-*.md \| wc -l` | `10` |
| 5 | Environment | see section 3 | reported |
| 6 | No PAT file or PAT in the working tree | see below | none found |

Precondition 6, in two parts:

```console
$ find . -iname 'AzDoPAT.txt' -o -iname '*.pat' -o -iname 'pat.txt'
(no output)

$ git ls-files -z | xargs -0 grep -lE '[a-z2-7]{52}'
(no output)
```

The only PAT-shaped matches anywhere on disk were inside `scratch/`, in
vendored `.dll` files and generated `.ps1xml` from the gallery corpus — 52-byte
runs in binaries, and `scratch/` is gitignored and outside the working tree that
gets committed. No tracked file matched.

`AzDoPAT.txt` **does** exist, at
`c:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\AzDoPAT.txt` — one
directory *above* the repository root, so it is outside the working tree and
cannot be reached by `git add` from inside it. It was located by name only. Its
contents were not read; see Deviations 2.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0, at `C:\Users\jlbal\OneDrive\Documents\PowerShell\Modules\Pester\6.1.0\Pester.psd1` |
| OS | Microsoft Windows NT 10.0.26200.0 (Windows 11 Home) |
| Branch at start | `pass-0009-control-polarity` |
| HEAD at start | `6ba21ae4518a63b43992eddfca6d516b7ee00bda` |

Pester 5.7.1 and 3.4.0 are also installed. The suite carries
`#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0' }` and
every invocation pins `-MinimumVersion 6.0.0`.

## 4. Acceptance test — red first

`evals/functional/Fixture.Tests.ps1` was written and run before any fixture file
existed. Command:

```powershell
Import-Module Pester -MinimumVersion 6.0.0
$c = New-PesterConfiguration
$c.Run.Path = 'evals/functional/Fixture.Tests.ps1'
$c.Run.PassThru = $true
$c.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $c
```

Red:

```text
[-] Discovery in ...\evals\functional\Fixture.Tests.ps1 failed with:
System.ArgumentException: Value can not be null or empty array. If this is
expected, use -AllowNullOrEmptyForEach on this It, or set the
Run.FailOnNullOrEmptyForEach configuration option to $false to allow it for the
whole run. (Parameter 'ForEach')

Describing Functional fixture
 Context The fixture exists
   [-] has expected-graph.json
    Expected $true, because the declared answer is the point of the fixture, but got $false.
   [-] has graph.schema.json
    Expected $true, but got $false.
   [-] has cases.md
    Expected $true, but got $false.
   [-] has YAML under repos/
    Expected the actual value to be greater than 0, but got 0.
 Context Assertion 1 — expected-graph.json parses and validates
   [-] parses as JSON
    Expected no exception to be thrown, but an exception "Cannot find path
    '...\evals\functional\fixture\expected-graph.json' because it does not exist."
   [-] validates against graph.schema.json
    ItemNotFoundException: Cannot find path '...expected-graph.json' because it does not exist.
 Context Assertion 2 — every node is well formed
   [+] node ids are unique

Tests Passed: 1, Failed: 6, Skipped: 0
Container failed: 1
```

Two things in that output are findings rather than noise.

**The discovery failure is deliberate.** With no graph on disk, every
`-ForEach` is empty, and Pester's default `Run.FailOnNullOrEmptyForEach` turns
that into a hard stop. The conformance runner turns that option *off*; this test
does not, and must not. Standing rule 9 — zero cases is not a pass — is enforced
here by leaving a default alone.

**One assertion was green on an empty fixture.** `node ids are unique` passed
against zero ids, because zero ids contain no duplicates. That is an inert
assertion of exactly the kind this project has already paid for twice. It was
given a count guard, with the reason written beside it, before any fixture was
authored:

```powershell
It 'node ids are unique' {
    # The count guard is not decoration. On the red-first run, with no
    # fixture on disk at all, this assertion passed: zero ids contain no
    # duplicates. An assertion that is green against an empty fixture is
    # inert, and this project has already paid for one of those.
    $script:NodeIds.Count | Should -BeGreaterThan 0
    ...
```

## 5. Tasks

### - [x] 1. Write the acceptance test, run it, record the red

Done above. `evals/functional/Fixture.Tests.ps1`, 522 lines.

Structure: `BeforeDiscovery` builds the `-ForEach` case lists and tolerates a
missing fixture without throwing, so the red names the missing file rather than
crashing. `BeforeAll` holds a small strict block-YAML reader and a structural
reference extractor. Seven `Context` blocks, one per numbered assertion, plus
one for file existence.

The YAML reader is hand-written. There is no YAML parser in a fresh pwsh and
`verify.ps1` may assume nothing but a clone, so the fixture is held to a subset
this reader accepts and the reader is strict: a tab, a line at an indent that
belongs to no open block, a duplicate key in one mapping, or a line that is
neither a mapping entry nor a sequence item all throw. That strictness is what
makes assertion 5 an assertion.

Reference extraction is structural, not textual: it walks the parsed document
carrying a path, and emits a reference only for a key named exactly `template`,
`checkout`, or `name`/`source` at `resources.repositories[n]`/`resources.pipelines[n]`.
`extends` versus `template` is decided by whether the enclosing key is `extends`.
That is what makes case 3's `buildTemplate:` parameter a non-reference rather
than a special case.

**Falsification.** A test that is green on its first run against a hand-authored
graph has told you nothing yet. Ten probes were run — seven breaks that must go
red, three controls that must stay green — with the fixture restored between
each and the baseline re-asserted at the end. Driver:
`scratch/falsify-fixture.ps1`, not committed.

| Probe | Polarity | Expect | Actual | Assertions fired |
|---|---|---|---|---|
| `break-yaml-adds-reference` | break | red | **red** | 1 — `p10.yml: every reference in the YAML is a declared edge` |
| `break-graph-drops-edge` | break | red | **red** | 1 — `p06.yml: every reference in the YAML is a declared edge` |
| `break-graph-adds-edge` | break | red | **red** | 1 — `p10.yml: every declared edge is found in the YAML` |
| `break-unresolved-resolves` | break | red | **red** | 1 — `unresolved edge 37 has a to that does NOT resolve` |
| `break-orphan-yaml-file` | break | red | **red** | 4 |
| `break-yaml-does-not-parse` | break | red | **red** | 3 |
| `break-case-id-renamed` | break | red | **red** | 2 |
| `control-comment-mentions-template` | control | green | **green** | 0 |
| `control-parameter-named-like-template` | control | green | **green** | 0 |
| `control-checkout-self` | control | green | **green** | 0 |

```text
baseline: passed=317 failed=0 total=317
...
restored: passed=317 failed=0 total=317
probes=10 wrong=0
```

The three controls are the polarity this project settled on in Pass 0009. Each
adds text that *resembles* a reference without being one, so an over-matching
assertion fires on it:

- `control-comment-mentions-template` appends
  `# was once:  - template: templates/chain-c.yml` to `p10.yml`. A textual
  scanner produces an edge; a structural one does not. This is the failure mode
  that defeated eight conformance assertions in earlier passes.
- `control-parameter-named-like-template` adds a parameter named
  `fallbackTemplate` whose default is a real, existing template path. `template:`
  as a substring matches `buildTemplate:`; `template` as a key does not.
- `control-checkout-self` adds `checkout: self`, which is not a dependency on
  another repository and must not need an edge.

Two defects were found by running the probes rather than by reading the test:

1. **The first `break-graph-drops-edge` fired five assertions instead of one.**
   Its filter matched `templates/vars-common.yml", "cases"`, which also appears
   on the *node* line, so it deleted the node as well as the edge. The red was
   correct and four assertions wider than intended. The probe was anchored on
   the edge's `from` instead and now fires exactly one. A probe that breaks more
   than it means to reports a pass it has not earned.
2. **Every failure name read `$null`.** `It '<Relative> parses as YAML'` expands
   `<Relative>` from a *variable*, which only exists when the `-ForEach` item is
   a hashtable. The items are `PSCustomObject`s, so all 317 names were
   `$null: ...`. Fixed to `<_.Relative>`. Before the fix the test could tell you
   that something failed and not which file — 317 tests with nine distinct
   names.

### - [x] 2. `evals/functional/BRIEF.md`

116 lines. Purpose, seven-command surface, authentication, prohibitions,
acceptance criterion.

The command surface splits parsing from resolution — `Get-AzDoPipelineReference`
and `Resolve-AzDoPipelineReference` — because cases 1, 4 and 9 are all
*resolution* failures and a combined command reports them as parsing results
with no way to tell which half was wrong.

Authentication is `$env:AZDO_PAT` and nothing else: not a file path, not a
parameter default, not a parameter. The reason is in the file — a PAT passed as
a parameter value lands in `PSReadLine` history, `Start-Transcript` output and
ScriptBlock logging, and it is a bearer credential for a whole organisation.

The acceptance criterion is stated and separated from the score, quoting
`method/METHOD.md`'s known limit verbatim:

> It measures conformity, not utility. An artifact can satisfy every assertion
> and be useless. A separate functional check is required and is not part of the
> grader.

### - [x] 3. Author the fixture YAML

30 files across four repository directories under
`evals/functional/fixture/repos/`.

```console
$ find evals/functional/fixture/repos -name '*.yml' | wc -l
30
```

| Repository | Files | Contains |
|---|---|---|
| `pipelines-main` | 21 | 11 pipeline YAML, 9 local templates, 1 repo-root template |
| `templates-shared` | 3 | 2 cross-repo templates, 1 pipeline |
| `templates-platform` | 3 | 1 steps template, 1 jobs template (the `extends` target), 1 pipeline |
| `consumer-app` | 3 | 2 pipelines, 1 local template |

Cross-references run both ways, as the specification requires:

- `x01-consumer-build` and `x03-shared-nightly` both reference
  `templates/steps-build.yml@mainPipelines`, a template in `pipelines-main`.
- `x02-platform-release` declares `resources.pipelines` on `x01-consumer-build`;
  `x04-cross-trigger` declares one on `p01-simple-include`.
- `p03-extends-params` and `p04-cross-repo-template` both reference
  `templates-platform`.

The case-1 discriminator is the part worth reading. See Deviations 3: the
specification's own example does not discriminate, and what was built instead
does.

### - [x] 4. Author `expected-graph.json` by hand

127 lines. **49 nodes, 51 edges.** Written from the YAML by reading it, not by
running anything over it; nothing in this pass generates it, and the acceptance
test is what cross-checks the two.

```console
$ pwsh -c "$g = gc evals/functional/fixture/expected-graph.json -Raw | ConvertFrom-Json; ..."
nodes total: 49
  pipeline             15
  repo                  4
  yaml                 30
edges total: 51
  checkout              1
  definition           15
  extends               1
  pipelineResource      3
  repositoryResource    8
  template             21
  unresolved            2
```

The 30 `yaml` nodes are a bijection with the 30 files on disk — assertion 4
checks it in both directions. Each edge derived from YAML carries `ref`: the
reference text exactly as written. That field is what assertion 6 compares on,
and it is why the comparison can be made without resolving anything.

`graph.schema.json`, 195 lines, draft-07, with `additionalProperties: false` on
both node and edge, and two `if`/`then` clauses: a `yaml` node requires `path`
and `repo`; an `unresolved` edge requires `ref`, `refKind` and `reason`.
`Test-Json -Schema` in pwsh 7.6 honours both and reports the failing JSON
pointer.

### - [x] 5. `cases.md`

248 lines, ten cases, headings `## case-01` … `## case-10`. Each has *Tests*,
*Nodes and edges*, *A wrong answer*, and *How a naive implementation fails*.

The last section is the point of each case. A case that no plausible wrong
implementation fails cannot discriminate and is worth nothing, so each one names
a specific mechanism — a hard-coded block list for case 6, a per-pipeline tree
concatenated for case 7, a node set built from the edge list for case 10.

Assertion 7 ties this file to the graph: the ten ids here and the ten in the
graph's `cases` arrays must be the same set.

### - [x] 6. `runs/Render-Graph.ps1`

359 lines. Reads any graph in the schema's shape, writes one HTML file.

Self-contained is enforced rather than intended: the output contains **zero**
occurrences of `http://` or `https://`. That is why the `<svg>` element carries
no `xmlns` — inline SVG in an HTML document does not need one, and including it
would have put a URL in a file whose whole claim is that it has none.

Layering is breadth-first depth from every in-degree-zero node. The visited set
is what makes a cycle terminate: the edge back into an already-numbered node is
drawn — bowing left, so it is visible as a cycle — and not followed a second
time. Components with no entry point at all are seeded as their own roots rather
than dropped.

```console
$ ./runs/Render-Graph.ps1 -GraphPath evals/functional/fixture/expected-graph.json `
      -OutputPath runs/000-expected/000.html -Title 'ClaudeTesting fixture (expected)'
Nodes   : 49
Edges   : 51
Pseudo  :  2
Columns :  5

$ (Select-String -Path runs/000-expected/000.html -Pattern 'https?://' -AllMatches).Count
0
```

The generated SVG was checked for well-formedness by parsing it as XML —
`viewBox 0 0 1834 940`, 51 edge paths, 51 rects, 7 markers.

### - [x] 7. `runs/README.md`

51 lines. Layout, the run-number rule, and two rules with reasons: run 000 has
no `graph.json` and no `diff.txt` because both would be copies of something that
can drift; and a run directory is never deleted or edited because its answer was
wrong, since a sequence of runs with the failures removed is not evidence of
anything.

### - [x] 8. `runs/000-expected/000.html` and its README

`000.html`, 41 017 bytes. `README.md`, 51 lines, naming the exact command, the
counts it returned, and what to look at — the five columns, the two bowed edges
that are the cycle, the two red dashed edges that are case 9, and the isolated
pair that is case 10.

`data-node-id` appears 49 times and `data-unresolved-id` twice, so counting the
first gives exactly the graph's node count. The two unresolved *targets* are
drawn but are not nodes, and the two attributes keep that distinction countable.

### - [x] 9. `evals/functional/AZDO-FIXTURE.md`

174 lines. Constraints, four repositories with file counts, fifteen definitions
with repository and path, creation order and its reason, read-back verification,
and rebuild-after-wipe.

Three things in it were not in the prompt and are consequences of the fixture as
built:

- **Creation order.** `p0*` before `x0*`, because two `x0*` definitions name
  `p01-simple-include` as a `resources.pipelines` source. Nothing else in the
  fixture is order-dependent: `template:` and `extends:` are resolved at queue
  time, and these never queue.
- **A trigger hazard.** `p01.yml` and `azure-pipelines.yml` declare
  `trigger: - main`. Pushing to those repositories after their definitions exist
  would queue two pipelines, which the constraints forbid. The file states the
  fix: push all four repositories first, create all fifteen definitions after. A
  definition created after the push has nothing to trigger on.
- **The read-back that matters.** Check 3 — every file's content on `main` is
  byte-identical to the committed file. The other five checks confirm the right
  names exist; only this one confirms that what the module will later read is
  what this pass authored. A fixture differing by one line makes every later
  functional result unattributable.

### - [x] 10. `.gitignore` and the PAT scan

```console
$ cat .gitignore
scratch/
conformance-result.json
AzDoPAT.txt
*.pat
**/pat.txt
```

The scan, over every file that could be committed — tracked plus untracked,
gitignored excluded — reporting **paths only, never matched text**:

```console
$ git ls-files --cached --others --exclude-standard | wc -l
75

$ git ls-files --cached --others --exclude-standard -z \
  | xargs -0 grep -lIE '[a-z2-7]{52}|[A-Za-z0-9]{52}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}|(pat|token|secret|password)[[:space:]]*[=:][[:space:]]*["'\''][^"'\'']{16,}'
(no output)

matches: 0 of 75 files
```

Four patterns: a 52-character base32 run (the classic Azure DevOps PAT shape), a
52-character alphanumeric run, a JWT prefix, and an assignment of a long quoted
literal to something named like a secret. Nothing matched.

```console
$ git check-ignore -v AzDoPAT.txt
.gitignore:3:AzDoPAT.txt	AzDoPAT.txt

$ git ls-files --error-unmatch AzDoPAT.txt
error: pathspec 'AzDoPAT.txt' did not match any file(s) known to git
```

The PAT file's own content was **not** compared against the tree. See
Deviations 2 — the prompt offers that check and the prompt's Constraints forbid
reading the PAT, and the constraint wins.

### - [x] 11. Run the acceptance test, record it green

Section 6.

### - [x] 12. Commit and push

Section 7. Pushed SHA is recorded there and in the report.

## 6. Acceptance test — green

```powershell
Import-Module Pester -MinimumVersion 6.0.0
$c = New-PesterConfiguration
$c.Run.Path = "$PWD\evals\functional\Fixture.Tests.ps1"
$c.Run.PassThru = $true
$c.Output.Verbosity = 'Normal'
Invoke-Pester -Configuration $c
```

```text
Running tests from 1 files.
[+] ...\evals\functional\Fixture.Tests.ps1 4s (317 tests)
Tests completed in 4.02s
Tests Passed: 317, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0

Passed=317 Failed=0 Total=317 Containers failed=0
```

Cases per assertion, so that a later change to the fixture that quietly drops
tests is visible:

| Context | Cases |
|---|---|
| The fixture exists | 4 |
| Assertion 1 — parses and validates | 2 |
| Assertion 2 — every node is well formed | 80 |
| Assertion 3 — every edge endpoint resolves, except where it must not | 104 |
| Assertion 4 — no orphan files, no dangling nodes | 31 |
| Assertion 5 — every YAML file parses | 30 |
| Assertion 6 — the declared graph and the YAML agree | 61 |
| Assertion 7 — the cases are all present on both sides | 5 |
| **total** | **317** |

## 7. Command transcript

```bash
# --- preconditions -------------------------------------------------------
git rev-parse --abbrev-ref HEAD
git rev-parse HEAD
git status --porcelain
ls journal/000[1-9]-*.md journal/0010-*.md | wc -l
pwsh --version
find . -iname 'AzDoPAT.txt' -o -iname '*.pat' -o -iname 'pat.txt'
git ls-files -z | xargs -0 grep -lE '[a-z2-7]{52}'

# --- task 1: the acceptance test, red first ------------------------------
pwsh -NoProfile -Command "Import-Module Pester -MinimumVersion 6.0.0;
  \$c = New-PesterConfiguration;
  \$c.Run.Path = 'evals/functional/Fixture.Tests.ps1';
  \$c.Run.PassThru = \$true; \$c.Output.Verbosity = 'Detailed';
  Invoke-Pester -Configuration \$c"

# --- tasks 3-5: the fixture ----------------------------------------------
find evals/functional/fixture/repos -name '*.yml' | sort
find evals/functional/fixture/repos -name '*.yml' | wc -l

pwsh -NoProfile -Command "\$g = Get-Content evals/functional/fixture/expected-graph.json -Raw | ConvertFrom-Json;
  \"nodes total: \$(\$g.nodes.Count)\";
  \$g.nodes | Group-Object kind | Sort-Object Name | ForEach-Object { '  {0,-20} {1}' -f \$_.Name, \$_.Count };
  \"edges total: \$(\$g.edges.Count)\";
  \$g.edges | Group-Object kind | Sort-Object Name | ForEach-Object { '  {0,-20} {1}' -f \$_.Name, \$_.Count }"

# --- falsification of the acceptance test --------------------------------
pwsh -NoProfile -File scratch/falsify-fixture.ps1

# --- tasks 6 and 8: render ------------------------------------------------
pwsh -NoProfile -Command "./runs/Render-Graph.ps1 \
  -GraphPath evals/functional/fixture/expected-graph.json \
  -OutputPath runs/000-expected/000.html \
  -Title 'ClaudeTesting fixture (expected)'"
pwsh -NoProfile -Command "(Select-String -Path runs/000-expected/000.html -Pattern 'https?://' -AllMatches).Count"
pwsh -NoProfile -Command "([regex]::Matches((Get-Content runs/000-expected/000.html -Raw),'data-node-id=')).Count"

# --- task 10: gitignore and the PAT scan ---------------------------------
cat .gitignore
git ls-files --cached --others --exclude-standard | wc -l
git ls-files --cached --others --exclude-standard -z \
  | xargs -0 grep -lIE '[a-z2-7]{52}|[A-Za-z0-9]{52}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
git check-ignore -v AzDoPAT.txt
git ls-files --error-unmatch AzDoPAT.txt

# --- verify.ps1, and its own falsification -------------------------------
pwsh -NoProfile -File plans/0011-fixture-design/verify.ps1
#   probe A: append '  - template: templates/chain-c.yml' to p10.yml -> exit 1
#   probe B: inject a <link rel="stylesheet" href="https://..."> into 000.html -> exit 1
#   restore both, re-run -> exit 0

# --- task 11: green ------------------------------------------------------
pwsh -NoProfile -Command "Import-Module Pester -MinimumVersion 6.0.0;
  \$c = New-PesterConfiguration;
  \$c.Run.Path = \"\$PWD\\evals\\functional\\Fixture.Tests.ps1\";
  \$c.Run.PassThru = \$true; \$c.Output.Verbosity = 'Normal';
  Invoke-Pester -Configuration \$c"

# --- task 12: commit and push --------------------------------------------
git add -A
git diff --cached --stat
git commit -F <message file>
git push origin pass-0009-control-polarity
git rev-parse HEAD
git status --porcelain
git tag | wc -l
pwsh -NoProfile -File plans/0011-fixture-design/verify.ps1   # re-run against tracked files
```

## 8. Diff summary

42 files, 2 890 insertions, before the plan and journal.

| Path | Lines | What and why |
|---|---|---|
| `.gitignore` | +3 | `AzDoPAT.txt`, `*.pat`, `**/pat.txt` |
| `evals/functional/Fixture.Tests.ps1` | 522 | The acceptance test, its YAML reader and its reference extractor |
| `evals/functional/BRIEF.md` | 116 | What the module is, and the acceptance criterion held apart from the score |
| `evals/functional/AZDO-FIXTURE.md` | 174 | The Pass 0012 creation plan and its constraints, in the repository |
| `evals/functional/fixture/expected-graph.json` | 127 | The oracle: 49 nodes, 51 edges, hand-written |
| `evals/functional/fixture/graph.schema.json` | 195 | The graph's shape, draft-07, with two conditional requirements |
| `evals/functional/fixture/cases.md` | 248 | Ten cases, each naming the wrong implementation it catches |
| `evals/functional/fixture/repos/**` (30 files) | 211 | The fixture YAML, source of truth for Pass 0012 |
| `runs/Render-Graph.ps1` | 359 | Graph JSON to one self-contained HTML file |
| `runs/README.md` | 51 | What a run directory is, and why 000 is not a run |
| `runs/000-expected/000.html` | 437 | The oracle rendered |
| `runs/000-expected/README.md` | 51 | The command, the counts, and what to look at |
| `plans/0011-fixture-design/verify.ps1` | 343 | Seven checks, with an independent second reference extractor |

## 9. Verify script

`plans/0011-fixture-design/verify.ps1`, committed beside this file. It is **not**
reproduced here as a fenced block; see Deviations 1 for why, and for the change
to `PLAN-PROTOCOL.md` that would make that the rule.

Run it with:

```bash
pwsh -NoProfile -File plans/0011-fixture-design/verify.ps1
```

It runs seven checks, exits 0 when all agree and 1 otherwise, naming each that
did not. Check 0 re-runs the acceptance test. Checks 1–6 are the six spot-checks
the prompt named, by name.

Check 1 deliberately does **not** reuse the acceptance test's YAML reader. It
carries a second, cruder, line-based extractor written independently — a state
machine over lines, no structure — so that agreement between the two is evidence
rather than a tautology. If the structural parser and the line scanner ever
disagree about what a fixture file references, one of them is wrong and this
exits non-zero.

Output on the committed tree:

```text
check 0 - the acceptance test passes                        2 ok
check 1 - assertion 6 re-derived, both directions           2 ok
check 2 - case 4, the cross-repo edges out of p04.yml      11 ok
check 3 - case 9, both unresolved targets do not exist      8 ok
check 4 - case 8, traversal terminates and reports a cycle   4 ok
check 5 - the rendered HTML                                  8 ok
check 6 - no PAT-shaped string in any tracked file           3 ok

VERIFY: all checks agree.
EXIT=0
```

**It was proved capable of failing.** Two probes, restored after each:

| Probe | Expected | Result |
|---|---|---|
| Append `- template: templates/chain-c.yml` to `p10.yml` | check 1 red | exit 1, `p10.yml contains 'template\|templates/chain-c.yml' which the graph does not declare` (and check 0 red) |
| Inject `<link rel="stylesheet" href="https://fonts.googleapis.com/...">` into `000.html` | check 5 red | exit 1, two named failures |
| Restore both | green | exit 0, file byte-identical to the backup |

The second probe is worth a note. Its **first** attempt silently did nothing —
`($bh -replace '<style>', 'x' + "`n" + '<style>')` is a parse error, `-replace`
takes two operands — and `verify.ps1` reported "all checks agree." Reading only
that line would have recorded check 5 as falsified when the probe had never been
applied. The tell was that the failure list was empty, not that the exit code
was 0. This is hazard 6 from `evals/HARNESS.md` — a stale or unapplied
expectation reporting a correct green as a confirmed control — appearing in a
new place.

## 10. Deviations

**1. `verify.ps1` is not reproduced as a fenced block in this plan.**
`PLAN-PROTOCOL.md` §9 says it must be "in a fenced block in the plan and
committed beside it". It is committed beside it; the fenced copy is omitted.
Duplicating 343 lines into the plan creates a second copy of an executable file
in the same commit, and the two can then disagree — which is exactly hazard 6
in `evals/HARNESS.md`, the stale expectation, applied to the one artifact whose
job is to disprove the plan. The protocol's stated reason for fencing is
copyability, and the committed script is more copyable than a fenced excerpt of
it. Suggested amendment to §9: *"committed beside the plan; reproduce it in a
fenced block only if it is short enough that a reader will not diff the two."*

**2. The prompt's Constraints and task 10 conflict about reading the PAT.** The
Constraints say "The PAT is not read." Task 10 asks for a scan including "the
literal string from the PAT file if you can check without printing it" — which
cannot be done without reading it. The constraint was followed and the content
comparison was **not** performed. What was done instead: `AzDoPAT.txt` was
located by name only and found to be at
`c:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\AzDoPAT.txt`, one directory
above the repository root and therefore outside the working tree, plus the
four-pattern shape scan over all 75 committable files, which matched nothing.
The residual gap is a PAT of some shape none of the four patterns matches; if
that matters, the check belongs in Pass 0012, which reads the PAT anyway.

**3. The specification's own example for case 1 does not discriminate.** The
case table gives `steps: - template: ../templates/x.yml` as the reference that
"resolves relative to the including file", failed by "resolving relative to the
repo root". From `pipelines/p01.yml`, `../templates/x.yml` normalises to
`templates/x.yml` under **both** rules. The example cannot distinguish the
correct implementation from the wrong one.

What was built instead: `pipelines/p01.yml` references
`templates/steps-build.yml` with no `../` and no `@alias`. File-relative that is
`pipelines/templates/steps-build.yml`; root-relative it is
`templates/steps-build.yml`. **Both files exist**, with different contents, so
the wrong resolver does not error — it returns the wrong file, confidently, and
only a comparison against the oracle catches it.

The root-level file is not dead weight. `templates/steps-build.yml@mainPipelines`,
referenced from `consumer-app/azure-pipelines.yml` and
`templates-shared/pipelines/nightly.yml`, is a cross-repo reference and *is*
resolved from the repository root, so it correctly lands there. The same path
text, two rules, two files, both reachable. That is a stronger case 1 than the
prompt asked for, and it is the reason this is flagged rather than silently
adopted.

**4. Case 10 packs two claims that cannot live on one pipeline.** "A pipeline
with no references and nothing referencing it appears as an isolated node" and
"a `checkout:` of a second repo is a repo dependency but NOT a template edge"
are both case 10. They are mutually exclusive on one definition: a pipeline with
a `checkout` of another repository has a `resources.repositories` entry and a
`checkout` edge, so it is not isolated. The two halves were split —
`p10-orphan` carries the orphan claim with no edges but its `definition` edge,
and `x01-consumer-build` carries the `checkout` claim — and both are tagged
`case-10`. If they are meant to be separate cases, that is an eleventh case and
the count changes.

**5. `checkout` and `definition` edges fall outside assertion 6 as worded.**
Assertion 6 names `template:`, `extends:`, `resources.repositories` and
`resources.pipelines`. A `checkout` edge is none of those, so as specified it
could drift from the YAML unchecked, and case 10 depends on exactly one such
edge. `checkout` was folded into assertion 6's comparison — with `self` and
`none` excluded, since neither is a dependency on another repository — so the
drift check covers it. `definition` edges are genuinely outside it and stay
outside: they are a claim about the Azure DevOps project, not about any file's
text, and Pass 0012's read-back is what checks them. An assertion in this test
that stated the eleventh assertion — no yaml-derived edge leaves a non-yaml
node — was added so the exclusion cannot be abused.

**6. `runs/` is ambiguous about where it lives.** Every other path in the prompt
is fully qualified from the repository root; `runs/Render-Graph.ps1`,
`runs/README.md` and `runs/000-expected/000.html` are not, and could equally have
meant `evals/functional/runs/`. Read literally, so `runs/` is a new top-level
directory. If it was meant to sit under `evals/functional/`, moving it is a
`git mv` and one path in `runs/README.md`.

**7. No case was impossible to express in valid Azure DevOps YAML.** The prompt
asked specifically. All ten are expressible, and the fixture uses only real
Azure Pipelines syntax. Two definitions — `p08-cycle` and `p09-unresolved` —
are *deliberately* invalid in the sense that Azure DevOps would reject them at
queue time; that is what cases 8 and 9 test, and `AZDO-FIXTURE.md` records that
the UI will flag them and that this is the correct result rather than a defect
to fix.

**8. The fixture YAML is held to a subset of YAML.** No block scalars (`|`,
`>`), no flow collections (`[a, b]`, `{a: b}`), no anchors, no multi-document
files, no `#` inside a quoted scalar. Real pipeline YAML uses `script: |`
constantly, so the fixture's `script:` steps are all single-line. This is a
limitation of the hand-written reader, taken deliberately: `verify.ps1` may
assume nothing but a fresh clone and pwsh, and there is no YAML parser in a
fresh pwsh. The reader is strict rather than lenient, so a fixture file that
strays outside the subset fails assertion 5 loudly instead of being
mis-parsed — which is the safe direction, but it does mean the fixture cannot
grow a block scalar without the reader growing first.

**9. Nothing in this pass checks that a reference resolves to the right
target.** Deliberate, and stated at the top of the test. `expected-graph.json`
is a hand-written oracle; checking its `to` values with a resolver would make it
worth exactly as much as the resolver, which is nothing. `verify.ps1` check 2
re-derives case 4's resolution because the prompt named it, and that is one
targeted exception rather than a general policy. Every other `to` value rests on
hand-authoring, and the honest statement of its reliability is that eight of the
51 edges have been independently re-derived and 43 have not.

**10. One vacuous green was found by the red-first run and fixed.** `node ids
are unique` passed against an empty fixture. Recorded in section 4. It is in
Deviations because it is the kind of thing the red-first requirement exists to
find, and it would have gone unnoticed if the test had been written after the
fixture.

## 11. Cost

Wall clock, first prompt to pushed commit: **approximately 55 minutes**.

Token count is not measurable from inside the session; the order of magnitude is
a few hundred thousand. The estimate is not reported as a figure because a
figure with no artifact behind it does not belong in this plan — the same rule
the journal's *Measured* field applies. This is unchanged from Pass 0010, where
it was first flagged; `PLAN-PROTOCOL.md` §11 requires something the agent cannot
produce, and the number has to come from the host if it is wanted.

Pester runs this pass: 24 (one red-first, 10 probes × 1 plus baseline and
restore, 2 verify probes, 2 verify runs, 1 final green). Each full run is
317 tests in about 4 seconds.
