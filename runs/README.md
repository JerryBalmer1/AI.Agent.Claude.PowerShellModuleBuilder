# runs/

One directory per run of the graph against the fixture, plus one for the
declared answer. Renders live here rather than under `evals/` because they are
outputs, not part of the evaluation: deleting this whole directory must not
change what any test asserts.

## Layout

    runs/Render-Graph.ps1        the renderer, shared by every run
    runs/NNN-<slug>/             one run
    runs/NNN-<slug>/graph.json   the graph that run produced
    runs/NNN-<slug>/NNN.html     that graph rendered
    runs/NNN-<slug>/diff.txt     how it differs from expected-graph.json
    runs/NNN-<slug>/README.md    the command that produced it, and what it shows

`NNN` is a run number, allocated in order and never reused. The slug says what
was run, not how well it went — `002-first-resolver`, not `002-still-broken`.

## Run 000 is not a run

`runs/000-expected/` holds the declared answer rendered, and nothing else. There
is no `graph.json` in it, because the graph is
`evals/functional/fixture/expected-graph.json` and copying it here would create
a second copy to drift. There is no `diff.txt`, because the diff of the oracle
against itself is empty by construction and a file saying so would be
misleading.

It exists so that a reader can see the shape of the right answer before any
module exists to produce a wrong one.

## Every other run

A run directory records what a command actually returned, including — especially
— when that was wrong. A run is never deleted or edited because its answer was
bad. The sequence of runs is the evidence that the module improved, and a
sequence with the failures removed is not evidence of anything.

`diff.txt` is a diff of the run's `graph.json` against `expected-graph.json`,
sorted so that the comparison is stable: nodes by id, edges by
`from`/`kind`/`to`. An unsorted diff of two JSON files reorders on every run and
buries the one line that changed.

## Rendering

    ./runs/Render-Graph.ps1 -GraphPath <graph.json> -OutputPath runs/NNN-<slug>/NNN.html

The output is a single self-contained HTML file: inline SVG computed in
PowerShell, no CDN, no external script or stylesheet, no web font, no network
access at view time. It contains no `http://` or `https://` at all. Open it with
a browser from disk.
