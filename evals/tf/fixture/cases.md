# The Terraform fixture, and what each part is a case for

Three repositories in AzDO project `ClaudeTestingTerraform`, authored here and
pushed. **The harness copy under `repos/` is the source of truth**, verified by
byte read-back after every push.

`expected-graph.json` beside this file is the **oracle**: the combined
configuration graph of all three repositories, in PSGraphRenderToHtml's
producer-contract shape (`producer-graph.schema.json` 0.1.0).

**The oracle is hand-authored and was never produced by parsing the fixture.**
An oracle derived from a parser is a second copy of the thing under test, and
two copies of one mistake agree with each other. Every node and edge below was
written from reading the configuration, and the count of each is stated so a
reader can check the total rather than trust it.

## The node id scheme

| Shape | Means | Example |
| --- | --- | --- |
| `repo:<Name>` | a repository | `repo:TfFixtureApp` |
| `<Name>:<dir>` | a module, by directory relative to the repository root; the root module is `.` | `TfFixtureApp:modules/service` |
| `<Name>:<dir>#var.<name>` | an input variable | `TfFixtureApp:.#var.tags` |
| `<Name>:<dir>#local.<name>` | a local value | `TfFixtureApp:.#local.merged_tags` |
| `<Name>:<dir>#output.<name>` | an output | `TfFixtureNetwork:.#output.segment_id` |
| `<Name>:<dir>#provider.<name>` | a declared provider requirement | `TfFixtureShared:.#provider.random` |

Ids are unique across the whole combined graph because every one carries its
repository. That is deliberate: the harness's own thread ledger lost nine ids to
collision between two repositories, and an id scheme that cannot be merged is a
scheme that has to be reworked the first time two producers meet.

`scope` is the repository name. `type` is one of `repository`, `module`,
`variable`, `local`, `output`, `provider`.

## Containment is `parentId`, never an edge

A repository contains its root module; a module contains the modules it
declares *in its own directory tree*, and its variables, locals, outputs and
provider requirements. The chain is:

```
repo:TfFixtureApp
  TfFixtureApp:.
    TfFixtureApp:.#var.tags, #local.merged_tags, #output.*, #provider.*
    TfFixtureApp:modules/service
      TfFixtureApp:modules/service#var.tags, #local.service_tags, #output.*
      TfFixtureApp:modules/service/modules/worker
        ...
```

**Depth is not stored.** It is a function of this chain and is derived by
`ConvertTo-GraphRenderViewModel`. The contract refuses a node that carries one.

## Edge kinds

| Kind | From → to | Means |
| --- | --- | --- |
| `sources` | module → module | the first declares a `module` block whose source resolves to the second |
| `references` | variable/local/output → local/output | the second's expression reads the first, inside one module |
| `passes-to` | variable/local → variable | a value crosses a module boundary as an argument |

`contains` is not an edge kind here and the contract refuses it by name.

## The cases

### 1. Nested-module chain — three levels

`TfFixtureNetwork:.` sources `modules/segment`, which sources
`modules/segment/modules/subnet`. Three `module` nodes on one `parentId` chain,
two `sources` edges. TfFixtureApp has the same shape with
`modules/service/modules/worker`.

**What it catches:** a producer that flattens nested modules, or that treats a
module call as containment.

### 2. Cross-repository source

`TfFixtureApp:.` sources `TfFixtureShared:modules/naming` and
`TfFixtureShared:modules/tags` by `git::` URL:

```
git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfFixtureShared//modules/naming?ref=main
```

The URL carries a username and **no credential**, and to a parser it is inert
text. The `//modules/naming` subdirectory and the `?ref=main` are both part of
what has to be understood to resolve it to a node.

**What it catches:** a producer that only resolves relative paths, or that
resolves the repository and loses the subdirectory.

### 3. Cross-repository output reference

`TfFixtureNetwork` publishes `output.segment_id` and `output.subnet_ids`.
`TfFixtureApp` declares `var.network_segment_id` and `var.network_subnet_ids`
whose descriptions say they carry them. Two `references` edges cross the
repository boundary.

**What it catches:** a producer that treats each repository as a closed world.
This is the case a single-repository parser cannot see at all.

### 4. Provider version pin

Three repositories, three distinct `required_version` constraints
(`>= 1.3.0, < 2.0.0`, `>= 1.5.0`, `~> 1.0.11`) and six provider requirements
across four distinct providers, pinned three different ways — exact (`3.6.0`),
pessimistic (`~> 0.11.1`) and ranged (`>= 3.0.0, < 4.0.0`). Five pipeline
definitions pin four distinct Terraform versions: 0.13.7, 1.0.11, 1.5.7, 1.9.8.

**What it catches:** a producer that records the provider and drops the
constraint, or that only understands one pin syntax.

### 5. variable → local → module → nested module

The showcase, in TfFixtureApp:

```
var.tags  →  local.merged_tags  →  modules/service#var.tags
          →  local.service_tags  →  modules/service/modules/worker#var.tags
```

Four nodes, three edges — one `references`, two `passes-to` — crossing a module
boundary twice.

**What it catches:** a producer that finds nodes and no relationships. This is
the whole reason the graph is worth drawing.

### 6. Unused variable — the absence case

`TfFixtureShared:.#var.unused_retention_days` is declared and referenced by
nothing. It is a node with **no outgoing edge**.

**What it catches:** a producer that invents an edge for every declaration.
This case has no positive evidence; it is only checkable by the absence of
something, which is why it is stated as a case rather than left to chance.

### 7. Unresolved module source

`TfFixtureApp:.` declares `module "legacy"` sourcing
`../shared-legacy/modules/archive`, which exists in no repository in this
fixture.

The producer contract requires **every edge endpoint to resolve to a node id**,
so an unresolved reference is not modelled as a dangling edge. A node is
emitted for the unresolvable target, and the `sources` edge to it carries
`resolved: false` and a `reason`. The node's `type` is `module` and its `scope`
is the repository that referenced it.

**What it catches:** a producer that silently drops what it cannot resolve, and
reports a graph that looks complete and is not.

## Counts

The oracle holds, and `Compare-TfGraph.ps1` checks:

| | TfFixtureShared | TfFixtureNetwork | TfFixtureApp | Total |
| --- | --- | --- | --- | --- |
| repository | 1 | 1 | 1 | 3 |
| module | 3 | 3 | 4 | 10 |
| variable | 8 | 12 | 13 | 33 |
| local | 3 | 3 | 3 | 9 |
| output | 5 | 6 | 6 | 17 |
| provider | 2 | 2 | 2 | 6 |
| **nodes** | **22** | **27** | **29** | **78** |

The `module` count for TfFixtureApp includes the unresolvable `legacy` target.

## Frozen

Per decision 0011, once `mutations.txt` records the oracle falsified, this
fixture is frozen like `ClaudeTesting`: changes require a new decision. Pass
0024 may not edit anything under `evals/tf/fixture/`, and a defect found there
is a finding, not an edit.
