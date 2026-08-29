# 0009 — The agent moves both mains, fast-forward only

Operator-directed, 2026-08-29. Amends rule 14: at the end of every
pass whose acceptance test is green, the agent fast-forwards
`main` — on the harness to the pass tip, on PSAzureDevOpsGraph to
the newest `v0.<minor>.0` tag — and pushes it. Fast-forward only,
verified with `git merge-base --is-ancestor` before every push; a
non-fast-forward is a hard stop and a finding, never forced.
History is never rewritten. `Publish-Module` and all other
publication remain operator-only. Rationale: both landing pages
chronically lagged the work, and the operator is the bottleneck
the previous rule created.
