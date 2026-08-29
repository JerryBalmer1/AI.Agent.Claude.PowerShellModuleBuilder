---
name: graph-assembly
description: Assemble a pipeline dependency graph — nodes keyed by identity not traversal position, cycle-safe walk that reports the cycle, orphans kept, unreferenced repositories excluded. Use when building or debugging the graph a module emits, or a node/edge count that disagrees with an oracle.
---

# Graph assembly

The output shape is `evals/functional/fixture/graph.schema.json`. Read it; it is
the contract, and a graph must validate against it before it can be compared
with anything.

```json
{
  "version": 1,
  "organisation": "...",
  "project": "...",
  "generatedBy": "Get-AzDoPipelineDependencyGraph",
  "nodes": [ { "id": "...", "kind": "pipeline|yaml|repo", "name": "...", "repo": "...", "path": "repos/..." } ],
  "edges": [ { "from": "...", "to": "...", "kind": "...", "ref": "...", "refKind": "...", "alias": "...", "reason": "..." } ]
}
```

`version` is the integer `1`. `additionalProperties` is false at every level —
an extra field fails validation. A `yaml` node **must** carry `repo` and `path`,
and `path` must start `repos/`. An `unresolved` edge **must** carry `ref`,
`refKind` and `reason`.

## Node identity is the thing, never its position

Three kinds, three id shapes:

```
pipeline:<definition name>
yaml:<repo>/<path within repo>
repo:<repository name>
```

**A node is identified by what it is, not by where a traversal reached it.**
Building a tree per pipeline and concatenating the results gives two nodes for a
template that two pipelines include. The count inflates, and every metric
computed from the graph — fan-in, "how many pipelines would this change break" —
is then wrong in the direction that looks busiest.

Use a dictionary keyed by id. Adding a node that already exists is a no-op, not
a duplicate.

A shared template has in-degree 2 because two edges point at **one** node. That
is the whole point of the structure.

## Edge kinds

`definition`, `template`, `extends`, `pipelineResource`, `repositoryResource`,
`checkout`, `unresolved`.

A `definition` edge joins `pipeline:<name>` to the `yaml:` node its YAML lives
at. It is a claim about the Azure DevOps project rather than about a file, so it
carries no `ref`.

Every other edge carries `ref` — the reference exactly as it appeared in the
YAML, `templates/steps-build.yml@mainPipelines` and not a normalised form.

## Cycle-safe traversal

`cycle-a` includes `cycle-b`, which includes `cycle-a`. Both edges must appear,
the traversal must terminate, and the cycle must be reported.

Two failures, and the second is worse:

1. Recursing with no visited set — a hang or a stack overflow.
2. Adding a visited set and then **dropping the edge that closes the cycle** —
   a clean-looking tree, which is a lie.

The rule: record the edge, then decline to descend.

```powershell
$queue = [System.Collections.Generic.Queue[object]]::new()
$visited = [System.Collections.Generic.HashSet[string]]::new()
while ($queue.Count) {
    $file = $queue.Dequeue()
    foreach ($ref in Get-Reference $file) {
        Add-Edge $file $ref              # ALWAYS record the edge
        if ($visited.Add($ref.TargetId)) {
            $queue.Enqueue($ref.Target)  # descend only the first time
        }
    }
}
```

`HashSet.Add` returns `$false` when the item was already present, which is
exactly the "have I been here" test — and it does it without a second lookup.

Report the back edges you found. A cycle that terminates silently is
indistinguishable from no cycle.

## Orphans are nodes; unreferenced repositories are not

**An orphan is still a node.** A pipeline that references nothing and that
nothing references still appears, joined to its YAML by one `definition` edge.
Building the node set from the edge list makes anything with no edges cease to
exist — and that is the one pipeline a reader might most want to find, because
nothing references it, so nothing in a reference-derived graph produces it. Its
absence looks exactly like a correct answer.

Seed the node set from the **definition list**, then add what references
discover.

**A repository nothing references is not in the graph.** Repository nodes exist
because pipeline YAML references them through `resources.repositories` or
`checkout` — never because the project contains them.

Calling the repositories endpoint and turning the result into nodes is the
obvious first implementation, and it is wrong in a way that gets worse with
scale. A real project has repositories no pipeline touches. A graph that
includes them answers "what is in this project" rather than "what do these
pipelines depend on", and only the second question makes *if I change this
template, which pipelines break* answerable.

Use the repositories endpoint to **look files up**. Do not use it to emit nodes.

## Determinism

Sort nodes and edges before writing. A comparator should be order-insensitive,
but a graph that changes order between two runs cannot be diffed by eye or by
`git`, which is half of what the export is for.

## Export

`Export-AzDoPipelineDependencyGraph` writes JSON, DOT, or HTML. The JSON is the
schema above. Keep the HTML self-contained — no external script, stylesheet,
`@import`, or `http(s)://` reference at all — so it renders from a file:// URL
with no network. Draw unresolved targets as pseudo-nodes, visibly distinct from
real ones: they are the answer the tool exists to give.

## Checklist

- [ ] Nodes in a dictionary keyed by id, never a list appended per traversal
- [ ] Node set seeded from definitions, so orphans survive
- [ ] Repository nodes only from `resources.repositories` and `checkout`
- [ ] Every edge recorded before the visited check
- [ ] Back edges reported
- [ ] `unresolved` edges carry `ref`, `refKind`, `reason`
- [ ] Output sorted, and validating against the schema

## Related

- `pipeline-yaml-refs` — where the edges come from.
