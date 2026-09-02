# TfSiteCore

Shared building blocks for a site estate. Two child modules, both intended for
reuse from other configurations.

| Module | Holds |
| --- | --- |
| `modules/label` | builds a name prefix from a slug and a region |
| `modules/policy` | assembles the operating policy document |

The root calls both and republishes what they emit, so the repository stands on
its own as a configuration.

Inputs are `site_code`, `region`, `steward` and `archive_retention_weeks`.
Outputs are `label_prefix`, `label_short` and `policy_document`.

`required_version` is `>= 1.6.0`. Providers are `tls` and `archive`.
