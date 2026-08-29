# Run 003 — findings

Sorted by mechanism, most consequential first. Each is marked **observed** (it
is in the run record and re-derivable) or **inferred** (my reading of why).

The headline: **the graph is structurally complete.** Compare-Graph reports
zero `missingNode` and zero `missingEdge`. All 29 differences are extra
attributes, naming conventions, one extra node and one extra edge. A blind
build got the dependency computation right and the recording conventions wrong.

---

## Mechanism 1 — Unstated recording conventions on nodes and edges

25 of 29 differences. This mechanism alone fails all twelve cases.

### 1a. Pipeline nodes carry no `repo` (15 differences — every case)

**Observed.** Every one of the fifteen `pipeline` nodes is reported
`has repo '', expected '<repository>'`:

    node 'pipeline:p01-simple-include' has repo '', expected 'pipelines-main'  [case-01]
    ... through ...
    node 'pipeline:x04-cross-trigger'  has repo '', expected 'templates-platform'  [case-05]

**Inferred.** `graph.schema.json` declares `repo` on the generic node, then
requires it only for `kind: yaml` (`if kind == yaml then required [path, repo]`).
I read the conditional as the specification and put `repo` on yaml nodes alone.
The oracle also puts it on pipeline nodes, where the schema permits but does not
require it. The schema is a floor, not a description.

This is the single most expensive item in the run. Because the case tags live on
the pipeline nodes, one omitted property fails **case-01 through case-12** —
every case, including ones whose actual subject matter the module got right.
A one-line change would move the functional score a long way, which is exactly
why the score must not be re-run: 0/12 is the honest number for a blind build.

### 1b. Edges carry an `alias` the oracle omits (8 differences)

**Observed.** Eight edges differ only by `has alias '<x>', expected ''`:

| Edge | Alias | Case |
|---|---|---|
| `nightly.yml` → `pipelines-main/templates/steps-build.yml` | `mainPipelines` | case-01 |
| `release.yml` → `templates-platform/jobs/release.yml` | `platformTemplates` | — |
| `azure-pipelines.yml` → `pipelines-main/templates/steps-build.yml` | `mainPipelines` | case-01 |
| `azure-pipelines.yml` → `repo:templates-shared` (checkout) | `sharedTemplates` | case-11 |
| `p04.yml` → `templates-platform/steps/deploy.yml` | `platformTemplates` | case-04 |
| `p04.yml` → `templates-shared/steps/common.yml` | `sharedTemplates` | case-04 |
| `p03.yml` → `templates-platform/jobs/release.yml` (extends) | `platformTemplates` | case-03 |
| `p09.yml` → unresolved `steps/common.yml@ghostTemplates` | `ghostTemplates` | case-09 |

**Inferred.** `alias` is a declared, optional edge property, so emitting it was
schema-valid and looked like useful information. The oracle treats the alias as
already recoverable from `ref` (`steps/common.yml@sharedTemplates` contains it)
and does not duplicate it. Optional-and-permitted is not the same as wanted;
with a set comparison, every volunteered attribute is a way to be wrong.

### 1c. Unresolved `reason` is free prose, not a coded reason (2 differences, case-09)

**Observed.**

| Mine | Oracle |
|---|---|
| `alias 'ghostTemplates' is not declared in resources.repositories` | `alias-not-declared: 'ghostTemplates' is not in resources.repositories of pipelines/p09.yml, so the repository is unknown and the path cannot be resolved at all` |
| `file 'pipelines/templates/missing-steps.yml' does not exist in repository 'pipelines-main'` | `file-not-found: resolved to pipelines/templates/missing-steps.yml in pipelines-main, which does not exist` |

**Inferred.** The oracle uses a machine-readable code (`alias-not-declared:`,
`file-not-found:`) followed by prose. I diagnosed both failures *correctly* —
same alias, same resolved path, same repository — and wrote the sentence in my
own words. The diagnosis is right; the vocabulary is not shared. Free-text
reasons cannot be compared across implementations, which is presumably why the
oracle codes them.

---

## Mechanism 2 — Unresolved edges point at a synthetic id, not the would-be target

2 differences, both case-09. **Observed:**

    resolves to 'unresolved:steps/common.yml@ghostTemplates'
      expected 'yaml:@ghostTemplates/steps/common.yml'
    resolves to 'unresolved:templates/missing-steps.yml'
      expected 'yaml:pipelines-main/pipelines/templates/missing-steps.yml'

**Inferred.** The schema requires `to` on every edge but defines no node kind for
a target that does not exist, so I minted `unresolved:<raw ref>`. The oracle
instead names *where the reference would have landed*, keeping the `yaml:` id
shape and substituting `@alias` for the repository when even the repository is
unknown.

The oracle's choice is the better one and the second line proves why: its
expected id is `yaml:pipelines-main/pipelines/templates/missing-steps.yml` —
**exactly the repository and path my resolver computed.** The relative-path
arithmetic was right to the character. Only the id convention differed, so a
correct resolution was recorded in a form that could not be matched.

---

## Mechanism 3 — Scope judgements that the brief leaves open

### 3a. The empty repository is not a node (1 extraNode, case-12)

**Observed.** `node 'repo:ClaudeTesting' is in the candidate and not in the
expected graph [case-12]`.

**Inferred.** The project holds five repositories; the fifth is empty and its
REST payload omits `defaultBranch` entirely. I handled that deliberately —
`Get-AzDoRepository` reports it with `IsEmpty = $true`, and the walk skips
listing its items rather than erroring — and then included it as a node, on the
seed's reasoning that a thing which exists should not silently vanish.

Case-12's answer is the opposite: a repository that no pipeline and no template
references is not part of a *dependency* graph. The graph is what depends on
what, not an inventory. The empty repo tests that the walk survives it, not that
it records it. I got the robustness half right and the scope half wrong.

### 3b. `checkout: self` is not a dependency edge (1 extraEdge)

**Observed.** `edge 'yaml:consumer-app/azure-pipelines.yml' -[checkout]->
'repo:consumer-app' is in the candidate and not in the expected graph`.

**Inferred.** I treated all three checkout forms as a spectrum: `none` produces
nothing, `self` produces an edge to the file's own repository, an alias produces
an edge to the aliased one. The oracle keeps the aliased checkout (that edge
matched, bar its alias attribute) and drops `self`. Consistent: a file checking
out its own repository adds no dependency that the file's own location does not
already record. `self` is closer to `none` than to an alias.

---

## Mechanism 4 — House conventions absent from the brief (conformance, 16 failures)

**Observed**, 39/55. The brief says conformance "measures shape: manifest,
layout, build file, tests, exported names" and points at `PSModuleGraph` for
house style — which Phase 1 could not read. The failures cluster:

**Build file (7).** The house build is `PSAzureDevOpsGraph.build.ps1`, an
Invoke-Build file with tasks `Clean, Lint, Build, Test, PreTag`, a default task
of `Clean, Lint, Build, Test`, that *throws* rather than exits on failure,
excludes PreTag-tagged tests, disables Pester v5 assertion syntax, and measures
coverage against the built psm1 with a threshold that throws. I wrote a
hand-rolled `build.ps1` with `-Task` and `exit 1`. Note the five
`declares the task <_>` assertions passed while the file itself was absent —
worth a look from the harness side, since a missing file scoring five passes
flatters any candidate.

**Generated module (3).** The house psm1 is *generated*: marked `auto-generated`,
setting `$script:ModuleRoot`, and containing the function bodies so its exports
are statically visible. Mine is a hand-written loader that dot-sources
`Private/` then `Public/` at import time, so a static reader sees none of the
seven exports. My build stages by copying rather than concatenating — and I
wrote a comment defending that choice ("composing it any other way would mean
the shipped module and the tested module are different artifacts"). The house
answer is to generate *and* test the generated artifact.

**Repository shape (4).** Missing `PSScriptAnalyzerSettings.psd1` and
`Requirements.psd1` at the root; three exported commands
(`Get-AzDoPipeline`, `Get-AzDoPipelineYaml`, `Get-AzDoPipelineDependencyGraph`)
are never invoked by any test. That last one is a fair hit I could have taken
blind: I kept the suite offline and left the three network-touching commands
uncovered, when a mocked or `-Skip`-guarded invocation would have covered them.

**Source layout (1).** `Export-AzDoPipelineDependencyGraph.ps1` defines four
functions; the house rule is one per file, named for the file. My three renderer
helpers should have been separate Private files.

---

## Mechanism 5 — Platform, not conventions

**Observed, and the most portable thing in this run.** On **PowerShell 7.6.5**,
the array subexpression `@($x)` throws `ArgumentException: Argument types do not
match` whenever `$x` is a `System.Collections.Generic.List[object]` — regardless
of contents. `.Count`, `foreach`, the pipeline and `.ToArray()` all work on the
same value.

    $l = New-Object System.Collections.Generic.List[object]; $l.Add('a')
    $l.Count      # 1
    @($l)         # ArgumentException: Argument types do not match

This cost real time twice, because it surfaces far from its cause: the parser's
`foreach ($entry in @($resources['repositories']))` silently dropped *every*
`resources:` block in nine files, and the failure was attributed to the `foreach`
line rather than to `@()`. The graph still built, with every repository and
pipeline resource missing.

Fixed by having the parser return `.ToArray()` — ordinary PowerShell arrays —
so no caller is handed a value that behaves like a collection everywhere except
`@()`. A test now pins that contract.

**Inferred.** This looks like a regression in the 7.6.5 preview (it runs on
.NET 10). Any run on this machine will hit it, so it belongs in the method notes
rather than in one run's record.

---

## What this run says about the plugin

**Inferred, and the reason the run exists.**

The plugin is not carrying the domain reasoning. Without it the model derived
the two anchoring rules from the brief's one sentence about them, kept a cycle
from hanging, collapsed a diamond correctly, separated `extends` from
`template`, refused to read a `template:` out of a shell script, and computed
`pipelines/templates/missing-steps.yml` for a missing file — the oracle's exact
answer. Zero missing nodes, zero missing edges.

What the plugin carries is **agreement**: where `repo` goes on a node that does
not require it, that `alias` is not repeated on an edge, that an unresolved edge
names its would-be target, that reasons are coded, that an unreferenced empty
repo is out of scope, that `checkout: self` is not a dependency, and the whole
house build and generation layout. None of that is derivable from the brief and
the schema — I know, because I tried, and got 0/12 while being structurally
right.

That is a real and useful result, but it is a narrower claim than "the plugin
makes the model able to do this". A fair reading of 70.91% / 0 / 12 is: the
plugin's value on this task is convention transfer. Whether it also improves the
*graph* is not measurable from this run, because the baseline graph had no
structural errors left to improve on.

**Caveat, stated because it cuts against the above:** the builder is the same
model family that wrote the plugin's skills. Some of what looks like derivation
from the brief may be recall of the same reasoning that produced the skills.
This run cannot separate those.

One methodological note for the next pass: allowing the baseline `graph.json`
to be re-scored after a single convention fix would isolate mechanism 1 from
mechanisms 2 and 3 cheaply. It must be a *separate, labelled* number, never
replacing 0/12.
