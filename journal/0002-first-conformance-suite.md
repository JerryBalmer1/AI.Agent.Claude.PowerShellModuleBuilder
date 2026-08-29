---
pass: 0002
title: The conformance suite as first authored
date: 2026-08-28
artifacts:
  - git commit c1cf7ec
  - evals/conformance/Conformance.Tests.ps1 (at c1cf7ec)
  - evals/conformance/README.md (at c1cf7ec)
---

# Pass 0002 — The conformance suite as first authored

## Asked

Not recoverable. Reconstructed from `git show c1cf7ec`.

## Done

`git show --stat c1cf7ec`: 6 files, 505 insertions.

- `evals/conformance/Conformance.Tests.ps1` — 318 lines, 33 `It` blocks across
  six `Describe` blocks: `Manifest` and `Public surface` and `Repository shape`
  tagged `Universal`; `House style: source layout` and `House style: build file`
  tagged `HouseStyle`; `House style: generated module` tagged
  `'HouseStyle', 'RequiresBuild'`.
- `evals/conformance/README.md` — 77 lines, carrying the tag matrix and the
  falsification protocol as an intention.
- `Invoke-Conformance.ps1` at the **repository root**, 84 lines.
- `evals/conformance/Invoke-Conformance.ps1` — committed **empty**, 0 bytes.
- `.claude-plugin/plugin.json`, the VS Code workspace file.

## Why

Not recoverable beyond what the files themselves argue. The suite's own header
states the two load-bearing choices: nothing imports or executes the module
under test — every assertion reads the source tree, the manifest, the build
file, or the generated psm1 as text — and the assertions are written in Pester
v5 style deliberately, so the suite keeps running if a target turns
`Should.DisableV5` on or off.

The README states the reason for the tag split: "when a second eval target is
added to break the closed loop, only `Universal` should apply to it."

## Measured

None. No result file was committed with this pass.

## Learned

Not recorded at the time. Two defects are visible in the committed artifact and
were found later:

- `House style: generated module` carries **both** `HouseStyle` and
  `RequiresBuild`. Pester's tag filter is an OR, so the block ran under the
  README's own documented no-build invocation and read an absent psm1 as empty
  string. Recorded later as A4 in `baseline/FINDINGS.md`.
- The runner exists twice: 84 lines at the repository root, and a zero-byte file
  at the path the suite's own documentation names.

## Capability

A grader exists. It can be pointed at a module repository and produce a
pass/fail per assertion, without importing or executing the module.
