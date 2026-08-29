# 0008 — PSAzureDevOpsGraph main follows the tagged line

Operator-directed, 2026-08-29. Amends rule 14 for one repository:
on PSAzureDevOpsGraph only, the agent fast-forwards `main` to each
newly pushed `v0.<minor>.0` tag at the end of every plan that tags,
so the repository landing page always shows the latest tagged
deliverable. Fast-forward only — a non-fast-forward push is a hard
stop and a finding, never forced. Rule 14 is unchanged everywhere
else: harness `main` remains operator-only, no `Publish-Module`,
no other tags.
