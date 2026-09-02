# TfSiteEdge

The edge tier of a site estate. The root calls `modules/edge`, which creates a
point of presence per `pop_count`, and each point of presence runs a probe.

```
modules/edge
  modules/edge/modules/pop
    modules/edge/modules/pop/modules/probe
```

The root also calls the shared label module from TfSiteCore and a probe module
supplied by a vendor.

Inputs are `site_name`, `region`, `pop_count`, `probe_interval_seconds` and
`enable_tls`. Outputs are `edge_endpoint`, `pop_ids`, `label_prefix` and
`region`.

`required_version` is `~> 1.7.0`. Providers are `http` and `tls`.
