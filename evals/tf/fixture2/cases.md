# Fixture 2 — the unannotated Terraform fixture, and what each part is a case for

Three repositories in AzDO project `ClaudeTestingTerraform` — `TfSiteCore`,
`TfSiteEdge`, `TfSiteOps` — authored here and pushed. **The harness copy under
`repos/` is the source of truth**, verified by byte read-back after every push.

`expected-graph.json` beside this file is the **oracle**: the combined
configuration graph of all three repositories, in PSGraphRenderToHtml's
producer-contract shape (`producer-graph.schema.json` 0.1.0).

**The oracle is hand-authored and was never produced by parsing the fixture.**
Written from reading the configuration, exactly as fixture 1's was, and for the
same reason: an oracle derived from a parser is a second copy of the thing under
test, and two copies of one mistake agree with each other.

## Why this file, and why the fixture says nothing

This document is the **only** place fixture 2's case knowledge lives. Decision
0014 makes that a design rule rather than a habit:

> No comment, string, identifier, README line or commit message in fixture 2
> may name a case, name the oracle, describe presence or absence as a case, use
> the word *graph*, or point into the harness.

Fixture 1 does all of those things. Pass 0033's scan
(`plans/0033-honest-headline/tf-fixture-comments.txt`) found case numbers in
comments, the wrong answer spelled out in a variable's `description`, the
dependency chain drawn as a numbered arrow diagram, and one README naming
`evals/tf/fixture/cases.md` **by path**. Fixture 1 is frozen and stays
annotated; its bound is disclosed, not repaired. Fixture 2 is the instrument
that bound was costing, and it is written mute.

The consequence for anyone maintaining it: **if writing a fixture file ever
seems to require explaining a case, the explanation goes here.** Never in the
fixture. `evals/tf/Test-FixtureSanitization.ps1` is the standing gate, and it
runs against the fixture-2 source, not against this file.

## What is deliberately different from fixture 1

Fixture 2 exercises the **same seven mechanism classes**. Every surface they sit
on is different, so a producer that passed fixture 1 by remembering fixture 1
does not pass this.

| | Fixture 1 | Fixture 2 |
| --- | --- | --- |
| Vocabulary | network / app / shared | site / edge / ops |
| Deepest nesting | 3 module levels | **4** (`.` → `edge` → `pop` → `probe`) |
| Module topology | a tree; every module's caller is its parent | a **diamond**: `collector` and `reporter` both call `common`, whose **parent is the root, not either caller** |
| Cross-repo output reference | into two `local`s, through a root-module call | into a `local` **and** directly into two `output`s, through a root-module call **and** a `//subdirectory` call |
| Unresolved sources | one, a relative path | **two**, a relative path **and** a `git::` URL naming a repository that does not exist |
| Providers | random, time, null, local | tls, archive, http, external |
| `required_version` | `>= 1.3.0, < 2.0.0` / `>= 1.5.0` / `~> 1.0.11` | `>= 1.6.0` / `~> 1.7.0` / `>= 1.4.0, < 1.10.0` |
| Pipeline pins | 0.13.7, 1.0.11, 1.5.7, 1.9.8 | 1.4.6, 1.6.6, 1.7.5, 1.8.5 |
| Repositories that publish | Shared and Network | **all three** — Core is consumed by both others, Edge by Ops |

## The node id scheme

Unchanged from fixture 1, because it is contract shape rather than fixture
surface. A scheme that changed between fixtures would make the two
incomparable for no gain.

| Shape | Means | Example |
| --- | --- | --- |
| `repo:<Name>` | a repository | `repo:TfSiteOps` |
| `<Name>:<dir>` | a module, by directory relative to the repository root; the root module is `.` | `TfSiteOps:modules/common` |
| `<Name>:<dir>#var.<name>` | an input variable | `TfSiteOps:.#var.site_name` |
| `<Name>:<dir>#local.<name>` | a local value | `TfSiteOps:.#local.edge_pop_ids` |
| `<Name>:<dir>#output.<name>` | an output | `TfSiteEdge:.#output.pop_ids` |
| `<Name>:<dir>#provider.<name>` | a declared provider requirement | `TfSiteCore:.#provider.tls` |

`scope` is the repository name. `type` is one of `repository`, `module`,
`variable`, `local`, `output`, `provider`.

An **unresolvable** module target takes the id `<referencing scope>:<the source
string exactly as written>`, its `label` is the last path segment of that
source, and it carries `attributes.unresolved: true`. Both of fixture 2's
unresolved targets follow that rule, which is why one of them is a node id with
a URL in it.

## Containment is `parentId`, never an edge

A repository contains its root module; a module contains the modules **in its
own directory tree**, and its variables, locals, outputs and provider
requirements.

**Fixture 2 makes containment and calling disagree, which fixture 1 never
did.** `TfSiteOps:modules/common` sits directly under the repository root, so
its `parentId` is `TfSiteOps:.`; but nothing in the root calls it. Its two
callers are `modules/collector` and `modules/reporter`, its siblings. A producer
that sets `parentId` from the call rather than from the path puts `common`
under one of them — and has to pick, because there are two.

**Depth is not stored.** It is a function of the parent chain and is derived by
`ConvertTo-GraphRenderViewModel`. The contract refuses a node that carries one.

## Edge kinds

| Kind | From → to | Means |
| --- | --- | --- |
| `sources` | module → module | the first declares a `module` block whose source resolves to the second |
| `references` | variable/local/output → local/output | the second's expression reads the first |
| `passes-to` | variable/local → variable | a value crosses a module boundary as an argument |

`contains` is not an edge kind here and the contract refuses it by name.

**Meta-arguments produce no edge.** `count`, `for_each`, `providers` and
`depends_on` are not input variables of the child module.
`TfSiteEdge:modules/edge` calls `modules/pop` with `count = var.pop_count`, and
there is no edge for it — the same rule fixture 1 applies to
`module "worker"`'s `count`.

**Resources are not nodes,** so an expression that reads one produces no edge.
`TfSiteEdge:modules/edge/modules/pop#output.id` reads
`terraform_data.pop.output` and has no incoming edge at all.

## The cases

### 1. Nested-module chain — four levels

`TfSiteEdge:.` sources `modules/edge`, which sources `modules/edge/modules/pop`,
which sources `modules/edge/modules/pop/modules/probe`. Four `module` nodes on
one `parentId` chain, three `sources` edges.

Fixture 1's deepest chain is three levels. A producer that stores containment as
a parent *flag*, or that hard-codes two levels of `modules/`, passes fixture 1
and fails here.

**What it catches:** a producer that flattens nested modules, or that treats a
module call as containment.

### 2. Cross-repository source, by `git::` URL with a subdirectory

`TfSiteEdge:.` sources `TfSiteCore//modules/label` and `TfSiteOps:.` sources
`TfSiteCore//modules/policy`:

```
git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteCore//modules/label?ref=main
```

The URL carries a username and **no credential**; to a parser it is inert text.
The `//modules/label` subdirectory and the `?ref=main` are both part of what has
to be understood to resolve it to a node.

**What it catches:** a producer that only resolves relative paths, or that
resolves the repository and loses the subdirectory. Two instances, in two
different consuming repositories, so a resolver that works once by accident is
less likely to.

### 3. Cross-repository output reference — into a local *and* into outputs

Three cross-repository `references` edges, through two different constructs.

**Through a root-module call** (no `//subdirectory`, which is what names the
repository's root rather than a directory inside it):

```
git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteEdge?ref=main
```

`TfSiteOps` reads that module's outputs in two places, and they land on two
different node kinds:

```hcl
locals {
  edge_pop_ids = module.edge.pop_ids     # -> TfSiteOps:.#local.edge_pop_ids
}

output "edge_endpoint" {
  value = module.edge.edge_endpoint      # -> TfSiteOps:.#output.edge_endpoint
}
```

**Through a `//subdirectory` call**, which fixture 1 never uses for an output
reference: `TfSiteEdge` reads the label module's output straight into its own
output, and `TfSiteOps` does the same with the policy module's:

```hcl
output "label_prefix" {
  value = module.label.prefix            # TfSiteCore:modules/label#output.prefix -> TfSiteEdge:.#output.label_prefix
}
```

Fixture 1's version of this case lands only in `local`s and only through a
root-module call. A producer that special-cased *that* shape fails all three of
these.

The calls also pass values back the other way — six `passes-to` edges crossing a
repository boundary.

**What it catches:** a producer that treats each repository as a closed world;
and a resolver that requires a `//subdirectory` — case 2 exercises only that
form, and the `TfSiteEdge` root call has none.

### 4. Provider version pin

Three repositories, three distinct `required_version` constraints
(`>= 1.6.0`, `~> 1.7.0`, `>= 1.4.0, < 1.10.0`) and six provider requirements
across four distinct providers, pinned three different ways — exact (`4.0.6`,
`2.6.0`), pessimistic (`~> 2.6`, `~> 2.3.4`) and ranged
(`>= 3.4.0, < 4.0.0`). Four pipeline definitions pin four distinct Terraform
versions — 1.4.6, 1.6.6, 1.7.5 and 1.8.5, one each — so a producer that reads
only the first finds only one.

Two providers appear in more than one repository (`tls` in Core and Edge,
`archive` in Core and Ops) and are **pinned differently in each**: `archive` is
`~> 2.6` in Core and `2.6.0` in Ops. A producer that keys providers by name
alone, rather than by name within a repository, collapses those two into one and
loses a pin.

**What it catches:** a producer that records the provider and drops the
constraint, that understands one pin syntax only, or that treats a provider name
as globally unique.

### 5. The value chain — variable → local → module → nested module

In `TfSiteEdge`, from the root down to the fourth level:

```
var.probe_interval_seconds → local.probe_window → modules/edge#var.probe_window
                           → modules/edge/modules/pop#var.probe_window
                           → modules/edge/modules/pop/modules/probe#var.window
```

Five nodes, four edges — one `references`, three `passes-to` — crossing a module
boundary three times, and **renamed on the last hop** (`probe_window` arrives as
`window`). A producer that matches arguments to child variables by name alone
loses that last edge.

A second chain runs through `TfSiteOps` and out the other side of the diamond:

```
var.site_name → local.ops_name → modules/collector#var.name → local.collector_name
              → modules/common#var.name
```

and `modules/reporter` runs the same shape into the **same** child variable, so
`TfSiteOps:modules/common#var.name` has two incoming `passes-to` edges from two
different callers.

**What it catches:** a producer that finds nodes and no relationships; and one
that assumes a child variable has at most one source.

### 6. Unused variable — the absence case

`TfSiteCore:.#var.archive_retention_weeks` is declared and referenced by
nothing. It is a node with **no outgoing edge and no incoming edge** — the only
node in the fixture with neither.

Its `description` in the fixture reads *"How many weeks archived bundles are
kept."* and says nothing else. Fixture 1's equivalent reads *"Declared and
referenced by nothing. The absence case: a graph that invents a reference for
this is wrong."* — which is the difference this fixture exists to make.

**What it catches:** a producer that invents an edge for every declaration. The
case has no positive evidence and is only checkable by the absence of something,
which is why it is stated here rather than left to chance.

### 7. Unresolved module sources — two, of two different shapes

**A relative path that exists nowhere.** `TfSiteOps:.` declares
`module "vault_archive"` sourcing `../site-archive/modules/vault`.

**A `git::` URL naming a repository that does not exist.** `TfSiteEdge:.`
declares `module "vendor_probe"` sourcing
`git::…/_git/TfSiteVendor//modules/probe?ref=main`. `TfSiteVendor` is not one of
the three repositories and never will be. This is the harder half: a resolver
that reaches "this is a git source, therefore it resolves" reports a false
positive rather than a dropped edge.

The producer contract requires **every edge endpoint to resolve to a node id**,
so an unresolved reference is not modelled as a dangling edge. A node is emitted
for the unresolvable target with `attributes.unresolved: true`, and the
`sources` edge to it carries `resolved: false` and a `reason`.

`module "vendor_probe"` also passes `interval_seconds = var.probe_interval_seconds`.
**There is no `passes-to` edge for it,** and there cannot be: the target module's
variables are unknowable, so the endpoint would have to be invented. A producer
that emits one has invented a node.

**What it catches:** a producer that silently drops what it cannot resolve and
reports a graph that looks complete and is not; and one that treats a
well-formed URL as a successful resolution.

## Counts

The oracle holds, and `Compare-TfGraph.ps1` checks:

| | TfSiteCore | TfSiteEdge | TfSiteOps | Total |
| --- | --- | --- | --- | --- |
| repository | 1 | 1 | 1 | 3 |
| module | 3 | 5 | 5 | 13 |
| variable | 9 | 15 | 11 | 35 |
| local | 3 | 4 | 5 | 12 |
| output | 7 | 13 | 10 | 30 |
| provider | 2 | 2 | 2 | 6 |
| **nodes** | **25** | **40** | **34** | **99** |

The `module` count includes one unresolvable target in `TfSiteEdge` and one in
`TfSiteOps`. It does **not** include `module "edge"` in `TfSiteOps`, which
resolves to the existing node `TfSiteEdge:.`, nor `module "label"` and
`module "policy"`, which resolve to existing nodes in `TfSiteCore`.

Edges: **88** — 14 `sources`, 47 `references`, 27 `passes-to`. Thirteen of them
cross a repository boundary.

## Frozen

Per decision 0014, once `mutations2.txt` records the oracle falsified and
`readback2.txt` records the push byte-identical, this fixture is frozen like
`ClaudeTesting` and fixture 1: **changes require a new decision.** A defect found
here is a finding, not an edit.

The frozen commit SHAs are recorded in decision 0014 and in the LEDGER's Pins
section.

## What may not be written into the fixture, restated

Anything on this list belongs in this file:

- a case name or number, or the word *case* used about the fixture
- the oracle, `expected-graph.json`, node counts, edge counts, edge kinds
- *absence*, *presence*, or "a graph that … is wrong"
- the word *graph*, *node*, *parser*, *producer*, *harness*, *fixture*
- any path into this repository
- *deliberate*, *on purpose*, or any sentence explaining why something is there

The word *edge* is the one exception, and it is domain vocabulary here:
`TfSiteEdge`, `modules/edge`, `local.edge_name`. The scanner allows the singular
and refuses the plural, which never appears in the fixture and always appears in
graph prose.
