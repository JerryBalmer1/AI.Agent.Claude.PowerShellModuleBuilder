# BRIEF — PSAzureDevOpsGraph

The module this plugin is about to build, and the criterion by which it will be
judged to work. Nothing here is a conformance assertion.

## What it is

`PSAzureDevOpsGraph` produces a dependency graph of Azure DevOps pipelines and
the repositories and templates they reference.

The question it answers is the one nobody can answer by reading a repository:
*if I change this template, which pipelines break?* Azure DevOps pipeline YAML
composes by reference — `template:`, `extends:`, `resources.repositories`,
`resources.pipelines` — and those references cross repository boundaries,
resolve by two different rules depending on whether an `@alias` is present, and
are not visible from any one file. A project of any age has pipelines nobody can
account for and templates nobody dares change.

It is read-only. See **What it must not do**.

## Command surface

House verb-noun style, following `PSModuleGraph`: a `Get-` command per kind of
thing, one command that assembles the graph, one that exports it.

| Command | Does |
|---|---|
| `Get-AzDoRepository` | The Git repositories in a project. |
| `Get-AzDoPipeline` | The pipeline definitions registered in a project, each with the repository and path its YAML lives at. |
| `Get-AzDoPipelineYaml` | The YAML text of a definition, or of a path in a repository, at a given ref. |
| `Get-AzDoPipelineReference` | The references in one YAML document: `template`, `extends`, `resources.repositories`, `resources.pipelines`, `checkout`. Parsing only — no resolution, no network. |
| `Resolve-AzDoPipelineReference` | One reference plus the file that made it plus that file's declared aliases, to a repository and path — or to an unresolved result carrying a reason. |
| `Get-AzDoPipelineDependencyGraph` | The graph: nodes and edges, as in `fixture/graph.schema.json`. |
| `Export-AzDoPipelineDependencyGraph` | The graph as JSON, DOT or HTML. |

`Get-AzDoPipelineReference` and `Resolve-AzDoPipelineReference` are separate on
purpose. Parsing is testable against a file on disk with no credentials and no
network; resolution needs to know what exists in which repository. Cases 1, 4
and 9 are all resolution failures that a combined command would report as
parsing results, with no way to tell which half was wrong.

The final surface is whatever the ten cases require. The table above is the
starting shape, not a commitment; a case that cannot be served by any of these
commands is a reason to add one.

## Authentication

A personal access token, read from an environment variable —
`$env:AZDO_PAT` — and nothing else.

Not a file path. Not a parameter with a default. Not a parameter at all on any
command that a user might run with `-Verbose`, transcribe, or paste into an
issue. A PAT that arrives as a parameter value ends up in `PSReadLine` history,
in `Start-Transcript` output, and in the `ScriptBlock` logging event log, and it
is a bearer credential for an entire organisation.

If the variable is absent, commands fail with a message naming the variable.
They do not prompt, do not search for a file, and do not fall back to anything.

## What it must not do

Read-only, always. Specifically, and permanently:

- **Never queue, run, or trigger a pipeline.** Not with `-WhatIf` off, not
  behind a switch, not in a test.
- **Never write to Azure DevOps.** No creating, updating or deleting a
  repository, definition, variable group, service connection, or anything else.
- **Never delete anything.**

There is no `-Force` that changes this and no command whose name begins with a
writing verb. A module that walks an organisation's pipelines is exactly the
kind of tool that gets run with a high-privilege token, which is the reason for
the constraint rather than an exception to it.

## The functional acceptance criterion

> The module imports, a command runs against the recorded fixture, and the
> answer matches `fixture/expected-graph.json`.

Concretely: `Get-AzDoPipelineDependencyGraph` run against the fixture produces a
graph whose nodes and edges equal those in `expected-graph.json` — same ids,
same kinds, same endpoints, same unresolved edges with the same reasons. Not a
superset, not a subset. The ten cases in `fixture/cases.md` say what each part
of that equality is for, and each names the specific wrong answer it catches.

**This is not part of the conformance score.** It is a separate check with a
separate result, and it must not be folded into the percentage the conformance
suite reports. Conformance measures shape: manifest, layout, build file, tests,
exported names. This measures whether the thing works.

`method/METHOD.md`, under *Known limits of this method*, states the reason:

> It measures conformity, not utility. An artifact can satisfy every assertion
> and be useless. A separate functional check is required and is not part of the
> grader.

This directory is that separate functional check. A module can score 100% on
conformance and return an empty graph; a module can fail four house-style
assertions and answer every one of the ten cases correctly. Those are different
facts and averaging them would destroy both.

## The fixture

`fixture/repos/` holds the YAML of four Azure DevOps repositories, and is the
source of truth for them. Pass 0012 pushes these files to Azure DevOps and
registers fifteen pipeline definitions against them; it does not author anything
there. `AZDO-FIXTURE.md` is that creation plan.

`fixture/expected-graph.json` is the oracle: the correct answer, written by hand
from the YAML rather than generated by parsing it. `Fixture.Tests.ps1` checks
that the two still describe the same thing, in both directions, so the oracle
cannot drift away from the fixture unnoticed.

Nothing in this directory checks that a reference resolves to the right target.
That is what the module has to compute, and an oracle checked by a resolver is
worth no more than the resolver.
