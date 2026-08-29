# TfFixtureNetwork

Three module levels for the PSTerraformGraph fixture: the root calls
`modules/segment`, which calls `modules/segment/modules/subnet`. That chain is
the nested-module case, and it is the reason `parentId` in the producer graph
has to be a chain rather than a flag.

Providers are `null` and `local`, pinned exactly; `required_version` is
`>= 1.5.0`, deliberately different from the other two repositories so a
version-pin case has something to discriminate.

`outputs.tf` publishes `segment_id`, `subnet_ids` and `network_name`.
TfFixtureApp consumes them through variables, which is the cross-repository
output-reference case.

**Nothing here is ever applied.** No terraform binary runs against this
fixture; it is parsed as configuration text.
