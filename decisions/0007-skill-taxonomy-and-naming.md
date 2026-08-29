# 0007 — Skill taxonomy and naming

Operator-directed, 2026-08-29. Skills generic to PowerShell
module building are named `powershell-module-<role>`; skills
specific to the Azure DevOps target are named `azdo-<role>`.
Dots are not legal in skill names, which rules out the
`powershell.module.x` form. Rule 9 governs the internal split:
judgment is the SKILL.md, deterministic mechanics are scripts
under the skill's `scripts/`, user entry points are commands.
Renamed this pass: module-scaffold → powershell-module-scaffold,
build-script → powershell-module-build, pipeline-yaml-refs →
azdo-pipeline-yaml-refs, graph-assembly → azdo-graph-assembly.

Rejected: `powershell.module.x` (illegal characters); putting
the domain only in the plugin name (operator wants it readable
in the skill list); one mega-skill per lifecycle (defeats
on-demand loading and reviewability).
