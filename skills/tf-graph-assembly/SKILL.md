---
name: tf-graph-assembly
description: Turn Terraform declarations and references into a graph — ids that carry their repository so two producers can merge, containment from the directory tree rather than from the module calls, parent is not caller, edge kinds by what the configuration says, and deduplicating a value referenced twice in one expression. Use when a module's parent looks wrong, when node counts disagree with an oracle, or when one fact is being counted as two edges.
---

# Assembling the configuration graph

`tf-hcl-parse` gets the declarations out; `tf-module-resolve` turns a `source`
into a target. This is the shape they go into.

## Ids carry their repository, always

```
repo:<Name>                        a repository
<Name>:<dir>                       a module, by directory relative to the repository root
<Name>:.                           that repository's root module
<Name>:<dir>#var.<name>            an input variable
<Name>:<dir>#local.<name>          a local value
<Name>:<dir>#output.<name>         an output
<Name>:<dir>#provider.<name>       a declared provider requirement
```

**Every id carries its repository, and that is not decoration.** Two
repositories both declaring `var.environment` in their root module are two
different nodes, and an id scheme without the repository silently merges them.

This project has already paid for the lesson once, in a different subsystem: a
thread ledger lost nine ids to collision between two repositories. **An id
scheme that cannot be merged is a scheme that has to be reworked the first time
two producers meet**, and reworking it invalidates every graph recorded before.

`scope` is the repository name. A provider is scoped to the module that declares
the requirement, so the *same provider* required by two repositories is two
nodes — and it can legitimately be pinned differently in each. A producer that
keys providers by name alone collapses them and loses a pin.

## Containment is `parentId`, and it comes from the directory tree

- a repository contains its root module;
- a module contains the modules **in its own directory tree**, and its
  variables, locals, outputs and provider requirements.

### Parent is not caller

This is the rule that costs the most to get wrong, and it only bites on
configurations where the two differ:

```
RepoA/
  main.tf                     calls ./modules/collector and ./modules/reporter
  modules/collector/          calls ../common
  modules/reporter/           calls ../common
  modules/common/             called by both, called by neither's parent
```

`modules/common`'s **parent is the repository root**, because that is where it
sits in the tree. Its **callers are its two siblings**. A producer that sets
`parentId` from the call has to choose one of them, and both choices are wrong.

The same rule the other way: **a module nothing calls is still contained.** A
directory holding `.tf` files is a module whether or not any `module` block
points at it, and dropping it because it has no incoming `sources` edge loses a
real part of the configuration.

The reliable statement: **a module's parent is the nearest module directory
above it in its own path.** Not its caller, not the module that happens to be
first in a traversal.

### Depth is derived, never stored

Depth is a function of the parent chain. Store the chain; let the consumer
compute the number. A node that carries its own depth has two sources of truth
for one fact, and the contract here refuses it outright.

## Edge kinds say what the configuration says

| Kind | From → to | Means |
|---|---|---|
| `sources` | module → module | the first declares a `module` block whose source resolves to the second |
| `references` | variable/local/output → local/output | the second's expression reads the first |
| `passes-to` | variable/local → variable | a value crosses a module boundary as an argument |

**`contains` is not an edge kind.** Containment is `parentId`. Emitting it as an
edge as well means every consumer has to know which one to believe.

The distinction between `references` and `passes-to` is a distinction about the
configuration, not about your traversal: `local.x` read inside an expression in
the same module is a reference; `local.x` handed to a child module as an
argument crosses a boundary and is a pass. The same local can do both, to
different targets.

**A `passes-to` edge's target is the child's declared variable**, found by the
argument's name in the child module. Which means the edge exists only when the
child resolved — see `tf-module-resolve`.

**Renaming happens.** `probe_window = var.probe_window` in one call and
`window = var.probe_window` in the next are the same value under two names, and
the second edge is the one a producer that matches by name alone drops.

## Deduplicate: one fact is one edge

```hcl
locals {
  label = "${var.name}-${var.env}-${var.name}"
}
```

`var.name` appears twice in one expression. **That is one fact — this local
reads that variable — and it is one edge.** A reference extractor that emits per
match produces two, and a comparison against a hand-authored oracle then reports
a difference that is about the extractor rather than about the configuration.

Deduplicate on `(from, to, kind)` as you build. Note that this is *not* the same
as "at most one edge between two nodes": a value both referenced and passed on
is legitimately two edges between the same pair with different kinds, and a
comparator worth having matches by endpoints before it matches by kind.

## Determinism

Sort everything before emitting — nodes by id, edges by `(from, to, kind)`,
ordinally. Two runs over the same configuration must produce a byte-identical
document, or nobody can diff a graph against a committed one and every run looks
like a change.

## The absence case is part of the answer

A variable declared and referenced by nothing is a node with **no outgoing
edge**. That is the correct output, and it is only checkable by the absence of
something.

**A producer that invents an edge for every declaration passes every positive
case and fails this one.** The failure looks like completeness. If your assembly
has a step that says "connect each declaration to the thing near it", that step
is this bug.

## Before you emit

Validate the document against itself, because these are cheap and each one has
been a real defect somewhere:

- every node id is unique;
- every `parentId` names a node that exists, and the chains terminate;
- every edge endpoint names a node that exists;
- every edge kind is one of the three;
- no node carries a depth;
- the counts you report are the counts in the document.

Then run the consumer's battery against your real output, in your own build —
not a copy of it. `producer-contract` has the argument and the task.

## Checklist

- [ ] Every id carries its repository; providers are scoped to the declaring module.
- [ ] `parentId` comes from the directory tree, never from the call.
- [ ] A module nothing calls is still emitted.
- [ ] No node stores a depth; no `contains` edge exists.
- [ ] `passes-to` targets the child's declared variable, by argument name, allowing for renames.
- [ ] Edges deduplicated on `(from, to, kind)`.
- [ ] Nodes and edges sorted ordinally before serialisation.
- [ ] Ids, parents, endpoints, kinds and counts self-checked before emitting.

## Related

- `tf-hcl-parse` — the declarations and the raw expression text.
- `tf-module-resolve` — what a `source` points at, and the unresolved node.
- `producer-contract` — the battery, absent versus `false`, and reading a
  difference count by mechanism instead of by size.
- `azdo-graph-assembly` — the same problems for a different target; the identity
  and determinism arguments are the same ones.
