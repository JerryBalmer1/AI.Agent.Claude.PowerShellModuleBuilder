# 001-fixture-create — the fixture's creation

**Not a module output.** No module exists yet. This run records the creation of
the Azure DevOps fixture that a module will later be graded against: four
repositories, thirty files and fifteen pipeline definitions in the project
`ClaudeTesting` of the organisation `jlbalmerjr1`.

**There is no `graph.json` here, and no `diff.txt`.** Both would require a
module to produce a graph, and none exists. A file named `graph.json` holding
anything derived from Azure DevOps would be worse than absent: it would look
like a result and would in fact be a copy of the input.

**There is no rendered HTML.** `runs/000-expected/000.html` renders the declared
answer; this run produced no graph to render.

## What this run proves, and what it does not

It proves the push landed — that the declared objects exist in Azure DevOps and
that the bytes on the server are byte-identical to the bytes committed in
`evals/functional/fixture/repos/`.

It proves nothing about whether the graph is correct. The hand-authored
`evals/functional/fixture/expected-graph.json` is the only claim about
correctness in this project, and it was not derived from Azure DevOps, is not
modified by this run, and is not confirmed by it. A green read-back with a wrong
oracle is a perfectly possible state and nothing here would detect it. The two
claims are separate and are kept separate deliberately.

## Commands

Run from the repository root, on pwsh 7.6.5 with Pester 6.1.0, with
`$env:AZDO_PAT` set at User scope.

    # 1. Dry run. Reports what would be created; changes nothing.
    pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1 -DryRun

    # 2. Create for real. Writes create-summary.json in this directory.
    pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1

    # 3. Read back and verify.
    pwsh -NoProfile -Command "Import-Module Pester -MinimumVersion 6.0.0; \
      Invoke-Pester -Path evals/functional/ReadBack.Tests.ps1"

    # 4. Idempotency: re-run unchanged, sending the summary elsewhere so the
    #    creation record above is not overwritten by a run that created nothing.
    pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1 \
      -SummaryPath <scratch>/create-summary.run2.json

## What it returned

    Repositories created     4
    Files pushed            30
    Definitions created     15
    Pipelines queued         0
    Read-back               76 assertions, 76 passed, 0 failed

The second run created nothing and reported all 49 objects already present.

## `create-summary.json`

Every object this run touched, whether created or already present, with its
Azure DevOps id. It carries no credential: the PAT is read from `$env:AZDO_PAT`,
travels only in an Authorization header, and is never written to any file. This
file is covered by the PAT-shape scan in `plans/0013-create-fixture/verify.ps1`
along with everything else under `runs/`.

The repository ids are GUIDs assigned by Azure DevOps. The definition ids are
the small integers 1–15, because this project had never held a definition
before; they are not stable across a wipe and rebuild, and nothing should assume
them. The read-back resolves definitions **by name**, never by id, for exactly
that reason.

## Rebuilding after a wipe

`Sync-Fixture.ps1` is idempotent and re-runnable end to end. If `ClaudeTesting`
is emptied, running it again reproduces the fixture from
`evals/functional/fixture/repos/` with no manual step, and the read-back proves
the rebuild. The definition ids will differ; nothing depends on them.
