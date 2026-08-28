# Phase 0 — does the reference build?

Target: `./scratch/PSModuleGraph`, a clone of the reference, at
`d39b125 Record a count that agreed and a residue that cannot be closed from inside`.
Working tree clean at the start of the pass.

Run date: 2026-08-28. `pwsh 7.6.5`, Pester 6.1.0.

## Prerequisite the clone does not satisfy on its own

The first `-Bootstrap` run failed, and not because anything is wrong with the
reference. The `Dependencies` task resolves `PSGraphRender` — a `RequiredModules`
entry with no published package — from one of two places, in order:

1. `$env:PSGRAPHRENDER_MODULE_PATH`, a directory containing `PSGraphRender/`
2. `../PSGraphRender/output`, the sibling checkout, built

Running from `./scratch/PSModuleGraph` puts candidate 2 at
`./scratch/PSGraphRender`, which does not exist. The sibling convention holds
for the reference at its own location; it cannot hold for a clone placed
somewhere else. The build says so and throws rather than falling through to
whatever is on `PSModulePath`, which is the correct behaviour:

```
ERROR: PSGraphRender could not be resolved. Expected a sibling checkout at
'...\scratch\PSGraphRender', or set $env:PSGRAPHRENDER_MODULE_PATH to a
directory containing PSGraphRender/.
```

Resolved by the documented first mechanism, not by changing anything:

```powershell
$env:PSGRAPHRENDER_MODULE_PATH = 'C:\__Code\PSGraphRender\output'
```

`PSGraphRender` there is built and satisfies the manifest floor of `0.7.0`.
Every command below was run with that variable set. **Any later run of this
protocol against a clone outside `C:\__Code\` must set it too** — otherwise
Phase 0 is red for a reason that has nothing to do with the reference.

## Results

| Command | Exit | Outcome |
|---|---|---|
| `pwsh ./build.ps1 -Bootstrap` | 0 | green |
| `pwsh ./build.ps1` | 0 | green |
| `pwsh ./build.ps1 -Task PreTag` | 1 | red, one failure, not a blocker |

### `./build.ps1 -Bootstrap` — green

6 tasks, 0 errors, 0 warnings, 00:01:55. Installed nothing: InvokeBuild,
Pester 6.1.0 and PSScriptAnalyzer were already present at the pinned versions.
`-Bootstrap` runs the default task after resolving dependencies, so this is a
superset of the next line.

Tests: 263 passed, 0 failed, 3 skipped, 5 not run.
Line coverage 77.97% against a target of 75%.

### `./build.ps1` — green

`Clean, Lint, Build, Test`. 6 tasks, 0 errors, 0 warnings, 00:01:40.

Tests: 263 passed, 0 failed, 3 skipped, 5 not run.
Line coverage 77.97% against a target of 75%.

**The default task is green, so Step E's Bucket A/B sorting is sound.** A
conformance failure against this clone is a statement about the suite or about
the reference, not an artifact of a broken build.

### `./build.ps1 -Task PreTag` — red

4 passed, 1 failed, 266 not run. 00:00:04.

Failing test:

```
The version the module reports.is the version about to be tagged, and that tag does not exist yet
  Expected [int] 0, because v0.18.6 is already tagged, so this iteration is
  about to reuse a released version, but got [int] 1.
  tests/PreTag.Tests.ps1:149
```

Passing alongside it, for the record:

- `Sealing an iteration.closes every prune proposal the previous entry left open`
- `Sealing an iteration.names a prune proposal only where a thread was opened for it`
- `The renderer this module is pinned to.agrees between the manifest floor and what CI checks out`
- `The tag before this one.is on the remote at the commit it names here, on a branch that contains it`

Not a blocker, and not a finding. `PreTag` tests seal a finished iteration. The
manifest reads `0.18.6` and `v0.18.6` is already tagged in the clone, so the
clone sits on a sealed iteration whose successor has not yet bumped the version.
That is the state PreTag is designed to refuse, and refusing it is the assertion
working. The default task excludes `PreTag` by tag filter for exactly this
reason.
