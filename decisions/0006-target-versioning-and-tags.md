# 0006 — PSAzureDevOpsGraph keeps its files and is tagged per plan

Operator-directed, 2026-08-29. From run 002 onward,
PSAzureDevOpsGraph is no longer wipe-and-rebuild between plans:
the module files persist in the repository, each plan commits its
modifications there, and each plan that touches the target
concludes with an annotated tag `v0.<minor>.0`, minor
incrementing by one per such plan, message carrying the three
scores. The operator's assistant assigns the minor number in the
prompt, as it assigns pass numbers. Each tagged plan also writes
`docs/worklog/v0.<minor>.0.md` in the target: thoughts,
considerations, and decisions made while working, committed with
the work so each tag carries its reasoning. This amends rule 14
for exactly this case: the agent creates and pushes annotated
tags on PSAzureDevOpsGraph when the pass prompt names the
version. Rule 14 is otherwise unchanged — no `main`, no
`Publish-Module`, no tags anywhere else.

Wiped-state reliability runs (the three-consecutive bar) use
`Reset-Target.ps1` into `scratch/` as before; the tagged
repository is the deliverable line, scratch resets are the
measurement line, and the two are never compared to each other.

Applied retroactively: `v0.1.0` tagged onto run 002's commit
`79e02fb` after the fact, because the directive predated the
pass but did not reach its prompt.
