# PSTerraformGraph

A PowerShell module for working out what depends on what across our Terraform.

## The problem

Our Terraform is spread across several repositories. A root module calls other
modules, some of them in the same repository and some of them not; values get
declared in one place and consumed somewhere else entirely; provider versions
are pinned in files nobody looks at until something breaks.

So the question nobody here can answer is: **if I change this, what else
moves?** We have variables nobody will touch because no one can say what reads
them, and module sources pointing at addresses that may or may not still be
live.

I want to be able to point a command at our repositories and get the whole
dependency graph out — what the configuration declares, and how the parts of it
reach each other.

## What I want it to do

- Read the configuration and produce the graph, as data rather than as a
  picture.
- Export it as something I can look at, and as something I can diff.
- Tell me about module sources it could not resolve, rather than quietly
  dropping them. A dependency on something that is not there is the one I most
  want to hear about, and if it vanishes from the output it looks the same as a
  clean repository.

## Constraints I already know about

- **Read-only.** It never writes to Azure DevOps, never queues or triggers
  anything, and never runs Terraform. It reads configuration; it does not
  execute it.
- **Credentials come from the environment.** A personal access token in
  `$env:AZDO_PAT`, not a parameter and not a file. It is a bearer credential
  for a whole organisation, and anything passed as a parameter ends up in shell
  history and in transcripts.

## Status

Nothing built yet. This file is what I want; the rest is not written.
