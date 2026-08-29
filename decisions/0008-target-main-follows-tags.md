# 0008 — PSAzureDevOpsGraph main follows the tagged line

Operator-directed, 2026-08-29. Amends rule 14 for one repository:
on PSAzureDevOpsGraph only, the agent fast-forwards `main` to each
newly pushed `v0.<minor>.0` tag at the end of every plan that tags,
so the repository landing page always shows the latest tagged
deliverable. Fast-forward only — a non-fast-forward push is a hard
stop and a finding, never forced. Rule 14 is unchanged everywhere
else: harness `main` remains operator-only, no `Publish-Module`,
no other tags.

## Amendment — 2026-08-29, operator-directed

Run branches produced by `Reset-Target.ps1` are orphan roots, so no
fast-forward from the original `main` can exist (pass 0018's
finding). Resolution: one merge with `--allow-unrelated-histories`,
performed once by pass 0019, joining `v0.1.0^{}` and the original
`main`. Both roots are preserved; nothing is forced or rewritten.
Thereafter `main` follows tags by fast-forward as this decision
already states, which is possible because every future deliverable
plan branches from the unified `main` (decision 0006's deliverable
line). `Reset-Target.ps1` is unchanged and remains the measurement
line only: its orphan-root property is now load-bearing, marking
measurement branches as structurally distinct from the deliverable
line. Measurement branches are never merged to `main` and never
tagged.
