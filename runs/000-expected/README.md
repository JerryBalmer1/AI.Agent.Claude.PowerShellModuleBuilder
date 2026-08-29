# 000-expected — the declared answer

Not a module output. This is `evals/functional/fixture/expected-graph.json`,
the hand-written oracle, rendered.

## Command

    ./runs/Render-Graph.ps1 `
        -GraphPath evals/functional/fixture/expected-graph.json `
        -OutputPath runs/000-expected/000.html `
        -Title 'ClaudeTesting fixture (expected)'

Run from the repository root, on pwsh 7.6.5. It reads one file and writes one
file; it does not touch Azure DevOps and needs no credential.

## What it returned

    Nodes    49
    Edges    51
    Pseudo    2
    Columns   5

`Pseudo` counts the two targets of unresolved edges. They are drawn, dashed and
red, but they are not nodes of the graph: in the HTML they carry
`data-unresolved-id`, while the 49 real nodes carry `data-node-id`. Counting
`data-node-id` in `000.html` gives exactly the node count in
`expected-graph.json`, which is what `verify.ps1` checks.

## What to look at

The five columns are breadth-first depth from the pipelines that nothing
triggers. `pipeline:p01-simple-include` is not in the first column, because two
other pipelines declare a `resources.pipelines` dependency on it — that is
case 5 visible in the layout rather than only in the JSON.

The cycle between `cycle-a.yml` and `cycle-b.yml` is the pair of edges bowing
left. The renderer draws the closing edge and does not follow it a second time;
that is the whole of case 8's "terminates".

The two red dashed edges out of `p09.yml` are case 9. They end at boxes that
exist nowhere else in the graph, which is the point of them.

`p10-orphan` and its YAML are joined by one grey edge and touch nothing else.
That is case 10: an isolated node that a graph built from an edge list would not
contain at all.

## No diff

There is no `diff.txt` here. The diff of the oracle against itself is empty by
construction, and a file asserting that would look like evidence without being
any.
