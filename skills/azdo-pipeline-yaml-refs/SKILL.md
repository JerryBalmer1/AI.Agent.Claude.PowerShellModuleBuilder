---
name: azdo-pipeline-yaml-refs
description: Extract and resolve Azure Pipelines YAML references — template, extends, resources.repositories, resources.pipelines, checkout — with parsing separated from resolution and unresolved references carried with a reason. Use when building a pipeline dependency graph or debugging a wrong or missing edge.
---

# Pipeline YAML references

## Parse and resolve are two commands

`Get-AzDoPipelineReference` parses one YAML document and returns what it
references. No network, no credentials, no knowledge of what exists.
`Resolve-AzDoPipelineReference` takes one reference plus the file that made it
plus that file's declared aliases, and returns a repository and a path — or an
unresolved result carrying a reason.

Keep them separate. Parsing is testable against a file on disk with no
credentials; resolution needs to know what exists in which repository. A
combined command reports resolution failures as parsing results, with no way to
tell which half was wrong.

## Parse structurally, never by text

Walk the parsed object graph. Do not regex the file.

A reference is a **mapping key named exactly `template`**. Two traps:

- **`buildTemplate:` is not `template:`.** Substring matching on `template:`
  invents an edge from a parameter. Parameter values are chosen to be real,
  existing paths precisely so that a text scan produces an edge that resolves
  and therefore looks correct.
- **A parameter whose *value* looks like a path is not a reference.** Only the
  key matters.

Walk the **whole document**, not a hard-coded list of blocks. A `template` under
`variables` is still a template edge:

```yaml
variables:
  - template: templates/vars-common.yml
```

Hard-coding `steps`, `jobs`, `stages` is the most tempting shortcut in the
problem, covers the large majority of real references, and silently loses the
rest.

## The five reference kinds

| YAML | Kind | Points at |
|---|---|---|
| `template: path` anywhere | `template` | a YAML file |
| `extends:` → `template: path` | `extends` | a YAML file |
| `resources.repositories[]` | `repositoryResource` | a repository |
| `resources.pipelines[]` | `pipelineResource` | a **pipeline definition**, not a file |
| `checkout: <alias>` | `checkout` | a repository |

`extends.template` is an `extends` edge, not a `template` edge. Collapsing every
reference into one "depends on" kind destroys the distinction the graph exists
to make.

`checkout: self` produces **nothing at all**. `checkout: <alias>` of another
repository is a dependency on that repository — not a template reference, and no
`template` edge may be invented from it. Checking out a repository to read a
data file or a script from it is ordinary; inventing a template dependency from
it produces an edge that is plausible, resolves, and is wrong.

`resources.pipelines[]` produces an edge to a pipeline **definition** node. Its
`source:` names the definition, not a file. These run in both directions across
a project — an implementation that only walks one repository loses the inbound
ones.

## The two resolution rules

This is the core of the problem, and the two rules produce different files from
the same text.

**No `@alias` — relative to the including file.**

```
file  repos/pipelines-main/pipelines/p01.yml
ref   templates/steps-build.yml
→     repos/pipelines-main/pipelines/templates/steps-build.yml
```

Relative to the **directory of the file making the reference**, not to the root
of the repository. A repository can hold both `templates/steps-build.yml` and
`pipelines/templates/steps-build.yml`; a root-relative resolver does not error,
it returns the wrong file, confidently.

**With `@alias` — from the root of the aliased repository.**

```
file  repos/consumer-app/azure-pipelines.yml
ref   templates/steps-build.yml@mainPipelines
→     repos/pipelines-main/templates/steps-build.yml      (repo root)
```

The alias is looked up in the `resources.repositories` of **the file making the
reference**, and the path is joined to the root of the repository the alias
names.

**The current repository is a property of the file, not of the traversal.** A
relative reference inside a cross-repo template stays in *that template's*
repository. Carrying "the current repo" as one value for a whole traversal
resolves `notify.yml` inside `templates-shared/steps/common.yml` back into the
repository the pipeline started in.

## Unresolved references are results, not errors

Never drop what you cannot resolve. A broken pipeline then looks identical to a
clean one, and the tool is worst exactly where it would be most useful.

Two reasons, kept distinct because they need different fixes:

| Reason | Means | Fix |
|---|---|---|
| `file-not-found` | the alias resolved (or none was used) but no such file exists | add the file |
| `alias-not-declared` | the `@alias` has no `resources.repositories` entry | add the entry |

Reporting both as "not found" tells the reader nothing about which. Carry the
reference text exactly as it appeared, its kind, and the reason.

An unresolved edge's target must **not** collide with a real node. Synthesise a
target id that cannot be mistaken for one — for an undeclared alias, keep the
alias in the id (`yaml:@ghostTemplates/steps/common.yml`) rather than guessing a
repository.

## Checklist for a reference extractor

- [ ] Walks the entire document, not a block list
- [ ] Matches the key `template` exactly, never a substring
- [ ] `extends.template` yields kind `extends`
- [ ] `checkout: self` yields nothing
- [ ] `resources.pipelines` targets a definition, not a file
- [ ] Records the raw `ref` text and the `@alias` separately
- [ ] Returns aliases declared by the file alongside the references

## Related

- `azdo-graph-assembly` — turning these references into nodes and edges.
- `azdo-rest` — fetching the YAML.
