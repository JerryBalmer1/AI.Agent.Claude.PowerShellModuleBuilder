# TfFixtureShared

Reusable child modules for the PSTerraformGraph fixture. Part of a
three-repository configuration graph; see `evals/tf/fixture/cases.md` in the
harness for what each part is a case for.

| Module | Holds |
| --- | --- |
| `modules/naming` | a `random_string` resource, a local computed from two variables, two outputs |
| `modules/tags` | a `time_static` resource and a tag map local |

Both are sourced across repositories by TfFixtureApp using a `git::` URL. The
root here is a caller so the repository is a valid configuration; nothing
outside sources it.

`variables.tf` declares `unused_retention_days`, which nothing references. That
is deliberate: a graph that invents a reference for it is wrong, and the
absence is a case.

**Nothing here is ever applied.** No terraform binary runs against this
fixture; it is parsed as configuration text.
