# The ten cases

Each case is a claim about what a correct dependency graph of the fixture
contains. A case is not a test of the fixture; it is a test of whatever reads
the fixture. `Fixture.Tests.ps1` only checks that the fixture and
`expected-graph.json` describe the same thing.

Every case names the specific way a naive implementation fails it. That column
is the reason the case exists: a case that no plausible wrong implementation
fails is a case that cannot discriminate, and is worth nothing.

Case ids are the strings in the `cases` array of `expected-graph.json`. The
acceptance test requires every id here to be carried by at least one node or
edge, and every id in the graph to appear here.

---

## case-01 — Same-repo step template resolves relative to the including file

**Tests.** A template reference with no `@alias` is resolved relative to the
directory of the file that contains it, not to the root of the repository.

**Nodes and edges.**

- `yaml:pipelines-main/pipelines/p01.yml` → `yaml:pipelines-main/pipelines/templates/steps-build.yml`,
  `ref: templates/steps-build.yml`
- `yaml:consumer-app/azure-pipelines.yml` → `yaml:pipelines-main/templates/steps-build.yml`,
  `ref: templates/steps-build.yml@mainPipelines`
- `yaml:consumer-app/azure-pipelines.yml` → `yaml:consumer-app/templates/app-steps.yml`
- `yaml:templates-shared/pipelines/nightly.yml` → `yaml:pipelines-main/templates/steps-build.yml`

**A wrong answer.** p01's edge pointing at `repos/pipelines-main/templates/steps-build.yml`.

**How a naive implementation fails.** By joining the reference to the repository
root. There are two files in `pipelines-main` whose path ends
`templates/steps-build.yml`, one at the root and one under `pipelines/`. Both
exist, so a root-relative resolver does not error — it returns the wrong file,
confidently. The root file is not a decoy in the sense of being unused: a
cross-repo reference `templates/steps-build.yml@mainPipelines` *is* resolved
from the root and correctly lands there. The same text, two rules, two files.

---

## case-02 — A three-level chain is followed all the way down

**Tests.** Transitive resolution. `p02 → chain-a → chain-b → chain-c`, all in
one repository, each reference relative to the file that makes it.

**Nodes and edges.** The three `template` edges between
`yaml:pipelines-main/pipelines/templates/chain-{a,b,c}.yml`, plus p02's edge
into `chain-a`.

**A wrong answer.** A graph containing p02 → chain-a and nothing below it.

**How a naive implementation fails.** By reading the pipeline's own YAML,
recording what it references, and stopping. Depth 1 is the shape of every
first attempt, and it looks right on a fixture where nothing nests.

---

## case-03 — `extends` is its own edge kind, and a parameter is not an edge

**Tests.** Two things at once. `extends.template` is an `extends` edge rather
than a `template` edge; and a parameter whose *value* looks like a template path
is not a reference to anything.

**Nodes and edges.**

- `yaml:pipelines-main/pipelines/p03.yml` → `yaml:templates-platform/jobs/release.yml`,
  `kind: extends`
- the `repositoryResource` edge to `repo:templates-platform` that makes the
  alias resolvable
- **no** edge for `parameters.buildTemplate: templates/steps-build.yml`

**A wrong answer.** Either an edge of kind `template` where `extends` belongs,
or a fourth edge out of p03 pointing at a `steps-build.yml`.

**How a naive implementation fails.** By scanning the YAML text for anything
that looks like a path, or by matching the substring `template:` — which also
matches `buildTemplate:`. The parameter's value was chosen to be a real,
existing path so that a text scan produces an edge that resolves, and therefore
looks correct.

---

## case-04 — A cross-repo template resolves through the alias, in the right repo

**Tests.** `path@alias` is resolved from the **root** of the repository the
alias names, and the alias is looked up in the `resources.repositories` of the
file making the reference. Also that a relative reference *inside* a cross-repo
template stays in that template's repository.

**Nodes and edges.**

- `p04.yml` → `yaml:templates-shared/steps/common.yml`, `ref: steps/common.yml@sharedTemplates`
- `p04.yml` → `yaml:templates-platform/steps/deploy.yml`, `ref: steps/deploy.yml@platformTemplates`
- both `repositoryResource` edges out of `p04.yml`
- `yaml:templates-shared/steps/common.yml` → `yaml:templates-shared/steps/notify.yml`, `ref: notify.yml`

**A wrong answer.** `steps/common.yml@sharedTemplates` reported as unresolved;
or `notify.yml` resolved into `pipelines-main` because that is where the
pipeline started.

**How a naive implementation fails.** By treating `@alias` as part of the
filename, so the path does not exist; or by carrying "the current repository"
as a single value for the whole traversal instead of a property of the file
being read. p04 declares two aliases so that resolving in the wrong repo is not
merely wrong but visibly wrong: `steps/deploy.yml` exists in
`templates-platform` and not in `templates-shared`.

---

## case-05 — A pipeline resource is a pipeline-to-pipeline edge

**Tests.** `resources.pipelines` with a completion trigger produces an edge from
the consuming pipeline's YAML to another **pipeline definition**, not to a file,
and of a different kind from a template edge.

**Nodes and edges.**

- `p05.yml` → `pipeline:p01-simple-include`, `kind: pipelineResource`
- `yaml:consumer-app/pipelines/release.yml` → `pipeline:x01-consumer-build`
- `yaml:templates-platform/pipelines/trigger.yml` → `pipeline:p01-simple-include`
- `p05.yml` also has one ordinary `template` edge

**A wrong answer.** A `pipelineResource` edge whose `to` is a `yaml` node, or an
edge of kind `template`.

**How a naive implementation fails.** By flattening every reference into one
"depends on" kind. p05 carries one edge of each kind precisely so the collapse
shows up as two edges of the same kind out of one file. The three pipeline
resources run in both directions across the fixture — one from `pipelines-main`
outward and two from outside it inward — so an implementation that only walks
`pipelines-main` loses two of them.

---

## case-06 — A template in the `variables` block is still a template edge

**Tests.** Template references are found wherever they occur, not only under
`steps`, `jobs` and `stages`.

**Nodes and edges.** `p06.yml` → `yaml:pipelines-main/pipelines/templates/vars-common.yml`,
`kind: template`, found at `variables[0].template`.

**A wrong answer.** p06 with no outgoing edges.

**How a naive implementation fails.** By walking a hard-coded list of blocks. It
is the most tempting shortcut in the whole problem, because `steps`, `jobs` and
`stages` cover the large majority of real references, and the assertion still
passes on almost every pipeline. `variables` templates are common enough in real
repositories that missing them silently is a serious answer to give.

---

## case-07 — A diamond shares one node, with in-degree 2

**Tests.** Two pipelines include the same template, which includes a third. The
shared template is one node reached twice, not two nodes.

**Nodes and edges.** `p07a.yml` and `p07b.yml` both →
`yaml:pipelines-main/pipelines/templates/diamond-shared.yml`, which →
`diamond-leaf.yml`. `diamond-shared` has in-degree 2; `diamond-leaf` has
in-degree 1 and is reachable by two paths.

**A wrong answer.** Two `diamond-shared` nodes, or two `diamond-leaf` nodes, or
a node count that changes when a third pipeline includes the same template.

**How a naive implementation fails.** By building the graph as a tree per
pipeline and concatenating the results, so a node's identity is its position in
one traversal rather than its file. The count inflates, and every metric
computed from the graph — fan-in, "how many pipelines would this template
change break" — is then wrong in the direction that looks busiest.

---

## case-08 — A cycle is reported as a cycle, and the traversal ends

**Tests.** `cycle-a` includes `cycle-b`, which includes `cycle-a`. Both edges
appear, the traversal terminates, and the cycle is reported rather than hidden.

**Nodes and edges.** `p08.yml` → `cycle-a.yml` → `cycle-b.yml` → `cycle-a.yml`.

**A wrong answer.** A hang; a stack overflow; or a graph containing
`cycle-a → cycle-b` and not `cycle-b → cycle-a`, which is a tree and is a lie.

**How a naive implementation fails.** By recursing without a visited set, or by
adding one and then *dropping* the edge that closes the cycle instead of
recording it and not descending. The second failure is worse than the first,
because it produces a clean-looking answer. `p08-cycle` is a definition that
would fail if it were ever run. It is never run.

---

## case-09 — Unresolved references are reported, with a reason

**Tests.** Two references that cannot be resolved, for two different reasons: a
file that does not exist in a repository that does, and an alias that was never
declared. Both appear in the graph, marked unresolved, each with a reason.

**Nodes and edges.**

- `p09.yml` → `yaml:pipelines-main/pipelines/templates/missing-steps.yml`,
  `kind: unresolved`, `reason: file-not-found`
- `p09.yml` → `yaml:@ghostTemplates/steps/common.yml`, `kind: unresolved`,
  `reason: alias-not-declared`
- the `repositoryResource` edge to `repo:templates-shared`, declared in p09 and
  never used — the alias that *is* declared is not the alias that is referenced

**A wrong answer.** p09 with one outgoing edge and no unresolved edges; or an
"unresolved" edge whose `to` happens to match a real node.

**How a naive implementation fails.** By dropping what it cannot resolve. A
broken pipeline then looks identical to a clean one, and the tool is worst
exactly where it would be most useful. The two reasons are kept distinct because
they need different fixes: one is a missing file, the other is a missing
`resources.repositories` entry, and reporting both as "not found" tells the
reader nothing about which. `p09-unresolved` would fail if it were run. It is
never run.

---

## case-10 — An orphan is still a node, and a `checkout` is not a template edge

**Tests.** Two claims. A pipeline that references nothing and is referenced by
nothing still appears. And `checkout:` of a second repository is a repository
dependency, not a template reference.

**Nodes and edges.**

- `pipeline:p10-orphan` and `yaml:pipelines-main/pipelines/p10.yml`, joined by
  one `definition` edge and nothing else
- `yaml:consumer-app/azure-pipelines.yml` → `repo:templates-shared`,
  `kind: checkout`, `ref: sharedTemplates` — with **no** template edge into
  `templates-shared` from that file

**A wrong answer.** A graph with 48 nodes instead of 49; or a `template` edge
from `azure-pipelines.yml` into `templates-shared`.

**How a naive implementation fails.** By building the node set from the edge
list, so anything with no edges ceases to exist — which is the one pipeline a
reader might most want to find. The `checkout` half fails the other way: by
treating every repository mentioned in a pipeline as a source of templates, so
checking out a repository to read a file from it invents a dependency that is
not there.

The two halves are on different pipelines on purpose. p10 has to have no edges
at all to be an orphan, so it cannot also carry the `checkout` claim.
