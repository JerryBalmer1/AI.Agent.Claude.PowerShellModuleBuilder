# 0010 — Ecosystem repo governance

Operator-directed, 2026-08-29. PSGraphRender, PSGraphRenderToHtml
and PSTerraformGraph are governed like the target: work on
`pass-NNNN-*` branches; after a green pass the agent
fast-forwards that repo's `main` (ancestry verified with
`git merge-base --is-ancestor`, never forced) and pushes tags the
pass prompt names. No history rewrites, no `Publish-Module`, no
force pushes, ever. Each repo keeps its own version cadence and
carries `docs/HANDOFF.md` per the project context. Decisions
0005/0008/0009 are unchanged for the repos they already name.
