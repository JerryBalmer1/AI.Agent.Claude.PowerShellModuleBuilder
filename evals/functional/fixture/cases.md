# The twelve cases

Each case is a claim about what a correct dependency graph of the fixture
contains — or, for an absence case, about what it must not contain. A case is
not a test of the fixture; it is a test of whatever reads the fixture.
`Fixture.Tests.ps1` only checks that the fixture and `expected-graph.json`
describe the same thing.

Every case names the specific way a naive implementation fails it. That section
is the reason the case exists: a case that no plausible wrong implementation
fails is a case that cannot discriminate, and is worth nothing.

## Presence and absence

Every case declares a **kind**, on its own line, as `**kind:** presence` or
`**kind:** absence`.

A **presence** case claims something is in the graph. Its id appears in the
`cases` array of at least one node or edge in `expected-graph.json`, and the
acceptance test checks that it does.

An **absence** case claims something is *not* in the graph. Nothing can carry
its id — tagging a node with it would assert the opposite of the case. So an
absence case must instead name, on a `**checked by:**` line, the assertion
elsewhere that does check it. "Nothing carries this tag" is otherwise satisfied
by a case that nothing checks at all, which is the failure mode this rule
exists to prevent.

The acceptance test enforces the split in the direction the kind names: every
presence id tagged at least once, every absence id tagged never, and every
absence case carrying a `**checked by:**` line.

A case id mentioned in prose is not a declaration. Declarations are anchored on
the `##` heading, so this paragraph does not create a case.

---

## case-01 — Same-repo step template resolves relative to the including file

**kind:** presence

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

**kind:** presence

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

**kind:** presence

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

**kind:** presence

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

**kind:** presence

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

**kind:** presence

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

**kind:** presence

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

**kind:** presence

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

**kind:** presence

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

## case-10 — An orphan is still a node

**kind:** presence

**Tests.** A pipeline that references nothing, and that nothing references,
still appears in the graph.

**Nodes and edges.** `pipeline:p10-orphan` and
`yaml:pipelines-main/pipelines/p10.yml`, joined by one `definition` edge and
nothing else. No `template`, `extends`, `checkout` or resource edge touches
either.

**A wrong answer.** A graph with 47 nodes instead of 49.

**How a naive implementation fails.** By building the node set from the edge
list, so anything with no edges ceases to exist. That is the one pipeline a
reader might most want to find: nothing references it, so nothing in a
reference-derived graph will produce it, and its absence looks exactly like a
correct answer.

This case was one half of a larger case-10 in Pass 0011, which also carried the
`checkout` claim now in case-11. The two cannot live on one definition: a
pipeline that checks out a second repository has a `resources.repositories`
entry and a `checkout` edge, so it is not isolated, so it cannot be the orphan.

---

## case-11 — A `checkout` is a repository dependency, not a template edge

**kind:** presence

**Tests.** `checkout:` of a repository other than `self` is a dependency on that
repository. It is not a template reference, and no `template` edge may be
invented from it.

**Nodes and edges.**

- `yaml:consumer-app/azure-pipelines.yml` → `repo:templates-shared`,
  `kind: checkout`, `ref: sharedTemplates`
- the `repositoryResource` edge from the same file to `repo:templates-shared`,
  which is what makes the alias exist
- **no** `template` edge from `azure-pipelines.yml` into `templates-shared`.
  Nothing in that repository is included by this pipeline

**A wrong answer.** A `template` edge from `azure-pipelines.yml` into
`templates-shared`; or a `checkout` edge collapsed into the `template` kind; or
no edge at all, losing the dependency.

**How a naive implementation fails.** By treating every repository a pipeline
mentions as a source of templates. Checking out a repository to read a data file
or a script from it is ordinary, and inventing a template dependency from it
produces an edge that is plausible, resolves, and is wrong. `checkout: self`
appears in the same file and must produce nothing at all, which is the control
on the same mechanism.

---

## case-12 — A repository nothing references is not in the graph

**kind:** absence

**checked by:** `Fixture.Tests.ps1`, "no node is the pre-existing
ClaudeTesting repository"; and `ReadBack.Tests.ps1` read-back assertion 8, "the
pre-existing ClaudeTesting repository still exists", "the ClaudeTesting
repository is still empty", and "no definition targets the ClaudeTesting
repository".

Every test name quoted above is checked to resolve against a real test name in
the suite named beside it. A pointer written in prose is a pointer that rots
silently: a test can be renamed or deleted and the line that names it goes on
reading correctly. Naming the assertion is the rule; resolving the name is what
makes the rule bite.

**Tests.** The Azure DevOps project contains a repository named
`ClaudeTesting`, created with the project and empty. No pipeline references it,
no definition points at it, and it must not appear in the graph.

**Nodes and edges.** None, and that is the case. Nothing in
`expected-graph.json` carries a `case-12` tag; a node tagged `case-12` would
assert the opposite of the claim. The four `repo` nodes that *are* in the graph
are there because pipeline YAML references them through
`resources.repositories` or `checkout`, and `ClaudeTesting` is referenced by
neither.

**A wrong answer.** A fifth `repo` node, `repo:ClaudeTesting`. Five repository
nodes where the pipelines justify four.

**How a naive implementation fails.** By calling the repositories endpoint and
turning the result into nodes. It is the obvious first implementation — the
project knows its repositories, so why derive them — and it is wrong in a way
that gets worse with scale. A real project has repositories that no pipeline
touches, and a graph that includes them answers "what is in this project"
rather than "what do these pipelines depend on". The second question is the one
the module exists for, and only the second question makes
"if I change this template, which pipelines break" answerable.

The absence is deliberately not empty scenery: the repository is really there,
in the same project, visible to any call that lists repositories. An
implementation has to *not* use it.
