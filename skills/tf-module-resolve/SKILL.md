---
name: tf-module-resolve
description: Resolve a Terraform module source to a node — the leading-dot guard that separates a relative path from a registry address, finding the // subdirectory separator past the scheme's own //, what a git:: URL with no subdirectory names, and emitting an unresolvable source as a flagged node rather than dropping it. Use when nested modules vanish into invented registry nodes, when a cross-repository source resolves to the wrong thing, or when a graph looks complete and is not.
---

# Resolving a module source

A `module` block's `source` is a string in one of five shapes, and telling them
apart is where a Terraform reader most often goes wrong **without failing**.

Everything here cites `runs/tf-001-first-build/findings.md` and
`runs/tf-002-convention-and-case3/findings.md`.

## The five shapes

| Shape | Example | Resolves to |
|---|---|---|
| Local path | `./modules/child`, `../sibling/mod` | a directory relative to the **calling module's** directory |
| Registry | `hashicorp/consul/aws`, `app.terraform.io/x/y/z` | a module outside the scanned set |
| Generic git | `git::https://host/org/repo//sub?ref=main` | a repository, optionally a subdirectory inside it |
| GitHub/Bitbucket shorthand | `github.com/org/repo//sub` | the same |
| Archive / other | `https://…/mod.zip`, `s3::…` | outside the scanned set |

## The collision that fails silently

**`namespace/name/provider` and `modules/child` are the same shape to a naive
pattern.** Both are slash-separated words. A resolver that reaches for "does it
contain a slash? then it is a registry address" turns every relative module call
into an invented registry node.

The guard is one line and it is the leading dot:

```powershell
if ($source.StartsWith('./') -or $source.StartsWith('../')) { <# local path #> }
```

Terraform's own rule is exactly this: **a local path is one that begins with
`./` or `../`, and nothing else is.** Not "contains a slash", not "exists on
disk" — the string's first two characters.

**This is not a cosmetic error.** In run tf-001's first iteration it cost 12
node differences and 6 edges, and it fails in the worst direction: every nested
module simply vanishes into a registry node nobody declared, and the graph looks
plausible. A registry node is a legitimate thing to emit, so nothing about the
output says a mistake was made.

## Finding `//` past the scheme's own `//`

In a git source the `//` separates the repository from a subdirectory inside it:

```
git::https://host/org/_git/RepoName//modules/thing?ref=main
                                   ^^
```

`IndexOf('//')` finds the one in `https://`. Search **past the scheme**:

```powershell
$schemeEnd = $source.IndexOf('://')
$start = ($schemeEnd -ge 0) ? $schemeEnd + 3 : 0
$separator = $source.IndexOf('//', $start)
```

Strip the `?ref=` query first, or take it into account — the ref is part of the
source and not part of the path.

## No `//subdirectory` means the repository's ROOT module

```
git::https://host/org/_git/RepoName?ref=main          → RepoName's root module
git::https://host/org/_git/RepoName//modules/x?ref=main → RepoName's modules/x
```

**The absence of `//` is the thing that names the root**, and it is the case
most likely to be missing from a fixture and therefore from a test. A resolver
that splits on `//` and gives up when there is none handles subdirectory sources
correctly and silently drops every root-module call.

Run tf-002 recorded this precisely: the module under test *already* handled it —
the search for `//` past the scheme returns -1 and the subpath falls back to
`.` — written in v0.1.0 because it was the correct reading of the syntax, **and
tested by nothing.** It became a case only when a fixture was amended to include
one. *Untested correct code is luck that happened to hold.*

## Normalise the resolved path, then match it

Once you have a repository and a subpath:

- combine the caller's directory with a relative path, then resolve `.` and `..`
  segments **textually** — not with the filesystem, which does not have the
  other repository checked out;
- use forward slashes throughout, and lower-case nothing (module directories are
  case-sensitive in the graph even where the filesystem is not);
- the repository root is the subpath `.`, spelled the same way every time.

An id scheme that carries the repository in every id is what makes two
producers' graphs mergeable. See `tf-graph-assembly`.

## An unresolvable source is a node, never a silence

Some sources will not resolve: a relative path pointing outside every scanned
repository, a git URL naming a repository that is not in the set, a registry
address, an archive.

**Emit them.** The producer contract requires every edge endpoint to resolve to
a node id, so an unresolved reference is not modelled as a dangling edge.
Instead:

- a **node** for the target, `type` `module`, `scope` the repository that
  referenced it, an id derived from the source string as written, and an
  attribute marking it unresolved;
- the `sources` **edge** to it carrying `resolved: false` and a **`reason`**
  stating what could not be resolved and why.

```json
{ "from": "RepoA:.", "to": "RepoA:../elsewhere/mod", "kind": "sources",
  "resolved": false,
  "reason": "source ../elsewhere/mod resolves to no directory in any scanned repository" }
```

The reason is prose for a human, and it is the whole value of the node. *"A
producer that silently drops what it cannot resolve reports a graph that looks
complete and is not"* — and a graph that looks complete is worse than one that
is visibly partial, because nobody goes looking.

**Do not invent the target's contents.** If a module does not resolve, its
variables are unknowable. A `module` block passing `interval = var.x` to an
unresolvable source produces **no** value-flow edge, because the endpoint would
have to be made up. One node and one flagged edge; nothing else.

## A well-formed URL is not a resolution

The mirror-image failure of dropping what you cannot resolve: **treating "this
parses as a git source" as "this resolves."** A `git::` URL naming a repository
that is not in the scanned set is exactly as unresolved as `../nowhere`, and it
is harder to notice because everything about it looks right.

Resolution means *"I found the node this points at."* Anything else is
`resolved: false` with a reason.

## Checklist

- [ ] Local paths are identified by a leading `./` or `../` and by nothing else.
- [ ] The `//` search starts past `://`.
- [ ] The `?ref=` query is separated from the path.
- [ ] A git source with no `//` resolves to the repository's **root** module, and there is a test for it.
- [ ] Relative paths are resolved textually against the caller's directory, not against the filesystem.
- [ ] Every unresolvable source emits a node plus an edge with `resolved: false` and a `reason`.
- [ ] No arguments of an unresolvable module call produce edges.
- [ ] "It looks like a git URL" is never treated as resolved.

## Related

- `tf-hcl-parse` — getting the `source` string out with its text intact.
- `tf-graph-assembly` — id scheme, containment, and edge deduplication.
- `producer-contract` — why the unresolved node exists, and what `resolved`
  absent versus `false` means.
