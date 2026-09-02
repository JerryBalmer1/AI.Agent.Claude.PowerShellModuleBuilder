# TfSiteOps

The operations tier of a site estate. The root calls `modules/collector` and
`modules/reporter`; both of them call `modules/common`, which builds the tag
they share.

The root also calls TfSiteEdge for the points of presence it collects from,
the policy module from TfSiteCore, and a vault module kept in a neighbouring
checkout.

Inputs are `site_name`, `region`, `retention_days` and `report_format`.
Outputs are `edge_endpoint`, `collected_ids`, `report` and `policy_steward`.

`required_version` is `>= 1.4.0, < 1.10.0`. Providers are `external` and
`archive`.
