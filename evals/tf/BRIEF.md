# BRIEF — PSTerraformGraph

What the module is for, and what "it works" means. Nothing here is a
house-style assertion.

## What it is

`PSTerraformGraph` reads Terraform configuration out of cloned Git
repositories and produces a dependency graph of what that configuration
declares and how the declarations reach each other.

The question it answers is the one nobody can answer by reading a single
file: **if I change this variable, or this module, what else moves?**

Terraform composes by reference. A root module calls other modules; a value is
declared in one place, passed into another, and read somewhere else again;
providers are pinned somewhere and depended on everywhere; and a module source
can point at a directory next door, at a different repository, or at something
the reader has never heard of. None of that is visible from any single file,
and it does not stop at a repository boundary.

It is read-only. See **What it must not do**.

## What it has to read

Terraform configuration as it is actually written, not a convenient subset:

- `terraform` blocks — `required_version`, and `required_providers` with the
  version constraints they carry.
- `provider` blocks, with the arguments that say which provider configuration
  is which.
- `variable`, `local` and `output` declarations, and the references between
  them.
- `module` calls, and the values passed into them.
- Module sources of every shape Terraform accepts: a relative path, a Git URL,
  a registry-style address.
- Directories below the root of a repository. A module living inside another
  module's directory is ordinary Terraform, and a tool that reads only the top
  of a repository has not read the configuration.

A reference that crosses a repository boundary is still a reference, and it
still belongs in the graph.

## What it emits

A **producer graph**, as defined by the contract that `PSGraphRenderToHtml`
publishes:

    PSGraphRenderToHtml/contract/producer-graph.schema.json

Read that file — it is the agreement, not a summary of one. It is versioned
independently of either module, and it is stricter than it looks:
`additionalProperties` is false at every level, so a field nobody agreed to is
an error rather than a bonus. It also draws a line between what a producer
*observes* and what the consumer *derives*, and storing something derivable is
the specific mistake it was written to catch. That line is worth understanding
before writing anything that emits against it.

Both of these are requirements about the output, and neither is taste:

- **A module source that could not be resolved is carried, with a reason.** It
  is never dropped, and never quietly turned into something else. A source
  nothing can be found for is among the most interesting things this tool can
  report — it is a dependency somebody is relying on that may not be there —
  and output that omits it looks identical to output from a repository with
  nothing wrong.
- **Rendering goes through the ToHtml exporter.** Producing the graph and
  drawing it are separate jobs, and the drawing job is already done. Emit
  against the contract and hand it over; do not write a second renderer.

## The command surface

House verb-noun style, following `PSModuleGraph`: a `Get-` command per kind of
thing the tool can be asked for, one command that assembles the graph, and one
that exports it. Parsing a file on disk and resolving what a reference points
at are worth keeping as separate commands — parsing needs no credentials and no
network, resolution needs to know what exists where, and a command that does
both reports one kind of failure as the other.

That is a starting shape and not a commitment. The surface is whatever it takes
to do the job described above.

## The input

The configuration to run against lives in Azure DevOps:

| | |
|---|---|
| Organisation | `jlbalmerjr1` |
| Project | `ClaudeTestingTerraform` |
| Repositories | `TfSiteCore`, `TfSiteEdge`, `TfSiteOps` |

Clone them and read the working trees. They are ordinary Terraform
repositories, written by people doing their jobs, and nothing about them has
been simplified for the benefit of a tool.

## Authentication

A personal access token, read from an environment variable — `$env:AZDO_PAT` —
and nothing else.

Not a file path. Not a parameter with a default. Not a parameter at all on any
command somebody might run with `-Verbose`, transcribe, or paste into an issue.
A token that arrives as a parameter value ends up in `PSReadLine` history, in
`Start-Transcript` output, and in the `ScriptBlock` logging event log, and it is
a bearer credential for an entire organisation.

If the variable is absent, commands fail with a message naming the variable.
They do not prompt, do not search for a file, and do not fall back to anything.

## What it must not do

Read-only, always. Specifically, and permanently:

- **Never write to Azure DevOps.** No creating, updating or deleting a
  repository, a definition, a variable group, a service connection, or
  anything else.
- **Never queue, run, or trigger anything.** Not behind a switch, not in a
  test.
- **Never run Terraform.** No `init`, no `plan`, no `apply`, no provider
  download. This reads configuration as text; it does not execute it, and it
  does not need a state file, a backend, or credentials for any cloud.
- **Never delete anything.**

There is no `-Force` that changes this, and no command whose name begins with a
writing verb. A tool that walks an organisation's infrastructure configuration
is the kind of tool that gets run with a high-privilege token, which is the
reason for the constraint rather than an exception to it.

## What "it works" means

> The module imports, a command runs against the repositories named above, and
> what comes back validates against the producer contract and renders through
> the ToHtml exporter.

Whether the module is *shaped* the way this house shapes modules — its
manifest, its layout, its build file, its tests, the names it exports — is a
separate question with a separate answer. Both are worth knowing and neither is
an average of the other: something can satisfy every house rule and return
nothing useful, and something can answer the question properly while breaking
several style rules.
