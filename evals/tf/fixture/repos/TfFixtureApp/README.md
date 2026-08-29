# TfFixtureApp

The traceability showcase of the PSTerraformGraph fixture.

## The chain

```
var.tags -> local.merged_tags -> module.service (var.tags)
         -> local.service_tags -> module.worker (var.tags)
```

Four levels, crossing a module boundary twice. A graph that carries it as
`references` and `passes-to` edges has understood the configuration; one that
reports four unrelated nodes has not.

## What else is a case here

- **Cross-repository sources.** `module.naming` and `module.tags` are sourced
  from TfFixtureShared by `git::` URL. The URL carries no credential and never
  will; to a parser it is inert text.
- **Cross-repository output references.** `network_segment_id` and
  `network_subnet_ids` are variables whose values are TfFixtureNetwork's
  outputs, supplied by whoever calls this root.
- **An unresolved module source.** `module.legacy` sources
  `../shared-legacy/modules/archive`, which exists in no repository in this
  fixture. Deliberate. A producer that silently drops it reports a graph that
  looks complete and is not; the contract's `resolved: false` plus a `reason`
  is where it belongs.

`required_version` is `~> 1.0.11`, distinct from the other two repositories.

**Nothing here is ever applied.** No terraform binary runs against this
fixture; it is parsed as configuration text.
