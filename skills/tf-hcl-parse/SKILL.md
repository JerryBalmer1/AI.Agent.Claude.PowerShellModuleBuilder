---
name: tf-hcl-parse
description: Read Terraform HCL as blocks rather than with a whole-file regex — the four constructs that defeat one, required_providers appearing as both a block and an attribute, and keeping an expression's raw source text so reference extraction has something to match. Use when writing or fixing a .tf reader, when a nested block or a provider comes back empty with no error, or when a reference pattern that looks right finds nothing.
---

# Reading Terraform configuration

Everything here was paid for on a real build. The numbers cite
`runs/tf-001-first-build/findings.md`, which is where they were recorded.

## A regex over a whole file cannot work, and here is exactly why

The temptation is `(?ms)^variable\s+"([^"]+)"\s*\{(.*?)^\}` over the file text.
It works on the first fixture you try and then fails on real configuration.
**Four constructs defeat it, and each one fails silently** — a block goes
missing, or swallows the next three:

- **A brace inside a string.** `error_message = "use {name} instead"` closes a
  block that is not finished.
- **A `#` inside a string.** `default = "cidr#1"` starts a comment that is not
  one, and the rest of the line disappears.
- **A heredoc.** `<<-EOT … EOT` — the terminator is a bare word on its own line
  and everything between it and the opener is content, braces included.
- **A block comment.** `/* … */` spanning lines, with anything at all inside it.

**Track state instead.** Walk the text once, carrying four flags — in a string,
in a line comment, in a block comment, in a heredoc (and which terminator you
are waiting for) — and only count braces when none of them is set. That is
about forty lines and it is the difference between a reader that works and one
that works on the file you tested it on.

The same walk gives you block boundaries for free, and block boundaries are what
every extraction below wants.

**Iterations 2 and 3 of run tf-001 were exactly these defects, and together they
were 63 of that run's 94 differences.** Not 63 separate mistakes — three, each
producing a wave.

## `required_providers` is a block *and* an attribute

Both of these are legal and both are common:

```hcl
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
```

```hcl
terraform {
  required_providers = {
    random = { source = "hashicorp/random", version = "3.6.0" }
  }
}
```

A reader that handles one **finds no providers at all in a file written the
other way, and says nothing.** There is no parse error and no warning; the
provider list is simply empty, and the failure looks like "this configuration
declares no providers" rather than "I cannot read this".

Handle both. Then test both — a reader that has only ever seen the block form
has not been shown to handle the attribute form, and a fixture written by the
same person who wrote the reader will use whichever form they had in mind.

**The general shape, worth carrying beyond Terraform:** when a language offers
two spellings of one thing, the reader that supports one of them fails by
returning *nothing* rather than by failing. Nothing is indistinguishable from a
correct answer about an empty file.

## Keep the expression's raw text

Reference extraction is pattern-matching over expression source:
`var.name`, `local.thing`, `module.child.output`, `data.type.name.attr`.

**If the parser rebuilds an expression by joining tokens, every pattern written
against source text will miss.** Tokenise-then-rejoin puts spaces where the
source had none — `module . network . segment_id` — and a pattern looking for
`module\.(\w+)\.(\w+)` finds nothing in a file that is full of them. Again: no
error, just an empty result.

Store the raw substring the expression occupied. Extract from that.

## Reference patterns, and the one that is usually forgotten

```
var\.([A-Za-z_][A-Za-z0-9_-]*)
local\.([A-Za-z_][A-Za-z0-9_-]*)
module\.([A-Za-z_][A-Za-z0-9_-]*)(?:\[[^\]]*\])?\.([A-Za-z_][A-Za-z0-9_-]*)
```

**The `(?:\[[^\]]*\])?` in the middle is not optional to get right.** A module
called with `count` or `for_each` is referenced as `module.child[*].id`,
`module.child[0].id` or `module.child["a"].id`, and a pattern that expects
`module.<name>.<member>` with nothing between them misses every one of them.

Run tf-001 shipped without it; `module.subnet[*].id` was the single reference it
lost, and it was **the 31st of that run's 31 remaining differences** — the one
genuine producer bug on a page where the other 30 were a convention and a broken
fixture case. See `producer-contract`'s *"the single difference is where the
real defect hides"*.

## Meta-arguments are not inputs

`count`, `for_each`, `depends_on`, `providers` and `lifecycle` are arguments to
Terraform, not variables of the child module. **A `module` block's `count =
var.n` must not produce a value-flow edge to the child**, because there is no
child variable named `count` to flow into.

The same goes for `count.index` and `each.key` inside an argument's expression:
they are references to the meta-argument's own scope and resolve to nothing in
your graph.

## What to record for each declaration

Only what you can state as a fact from the text:

| Declaration | Record |
|---|---|
| `variable` | name, `type` as written, whether a `default` is present, whether a `validation` block is present |
| `local` | name (one per key in each `locals` block) |
| `output` | name |
| `terraform.required_version` | the constraint string, verbatim |
| `required_providers` entry | name, `source`, `version` constraint, all verbatim |
| `module` block | label, the `source` string exactly as written, the arguments and their raw expressions |

**Constraint strings are recorded verbatim, never normalised.** `~> 1.0.11`,
`>= 3.0.0, < 4.0.0` and `3.6.0` are three different claims and a reader that
canonicalises them has destroyed the thing a version case exists to check.

**Whether to write a field you have nothing to say about is a contract question,
not a parsing one** — see `producer-contract`. Emitting `hasValidation: false`
for every input with no validation block cost one run 28 identical differences
against an oracle that omitted the field.

## Resources are read, and are usually not nodes

`resource` and `data` blocks matter for two reasons and probably not a third:
their expressions can reference variables and locals, and their presence
justifies a provider. Whether they become nodes is a decision for the graph
shape you emit — most producers here do not emit them, and an expression that
reads `null_resource.thing.id` therefore resolves to nothing and yields no edge.

Decide it once, write it down, and be consistent: half a rule produces edges
whose endpoints do not exist.

## Checklist

- [ ] Block boundaries come from a state-tracking walk, not a regex over the file.
- [ ] Strings, `#`/`//` comments, `/* */` comments and heredocs all suppress brace counting.
- [ ] `required_providers` is read in **both** its block and attribute forms, and both are tested.
- [ ] Expressions keep their raw source text.
- [ ] The reference pattern tolerates `[*]`, `[0]` and `["key"]` between the module name and the member.
- [ ] Meta-arguments produce no value-flow edges.
- [ ] Version and type strings are stored verbatim.

## Related

- `tf-module-resolve` — what to do with the `source` string once you have it.
- `tf-graph-assembly` — turning declarations and references into nodes and edges.
- `producer-contract` — absent versus `false`, and grouping differences by
  mechanism before reading a count.
