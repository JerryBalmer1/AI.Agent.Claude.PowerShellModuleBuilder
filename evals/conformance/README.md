# Conformance suite

The oracle. It decides whether a module repository — one a human wrote, or one
the `psmodule` plugin generated — meets the conventions this plugin teaches.

Nothing here imports or executes the module under test. Every assertion reads
the source tree, the manifest, the build file, or the generated `psm1` as text.
A suite that has to run arbitrary build code to grade a run is a suite that can
be made to pass by a run that breaks it.

## Tags

| Tag | Meaning | Needs a build? |
|---|---|---|
| `Universal` | True of any well-formed PowerShell module repository. | No |
| `HouseStyle` | Specific to the PSModuleGraph build conventions. | No |
| `RequiresBuild` | Reads `output/<Name>/`. | Yes |

The split exists for one reason: when a second eval target is added to break
the closed loop, only `Universal` should apply to it. If a rule cannot survive
a module shaped unlike PSModuleGraph, it belongs in `HouseStyle` and the plugin
should say so out loud rather than presenting it as a fact about PowerShell.

Moving an assertion from `HouseStyle` to `Universal` is a claim. Make it
deliberately, and only after a second target has passed it.

## Running it

```powershell
# Against the reference. This must be green before the suite is trusted.
./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph

# Against a generated run, after its build has been run.
./Invoke-Conformance.ps1 -Path ./scratch/runs/<id>/PSAzureDevOpsGraph `
                         -Tag Universal,HouseStyle,RequiresBuild `
                         -ResultPath ./scratch/runs/<id>/result.json
```

The runner does not use `Run.Throw`. A red conformance run is data, not a build
failure — the harness records the score and moves to the next run.

## Falsification protocol

A gate that has only ever been green is indistinguishable from a gate that
cannot go red. Before this suite grades anything, break the reference in a
scratch clone — one break at a time, restore between — and confirm each break
turns exactly the expected assertion red and nothing else.

| Break in a scratch clone of PSModuleGraph | Expect red |
|---|---|
| Set `FunctionsToExport = '*'` in the manifest | exports functions by explicit name |
| Delete one name from `FunctionsToExport` | agrees three ways |
| Add `src/PSModuleGraph/Public/Sub/Get-Thing.ps1` | keeps `Public/` flat |
| Put two `function` definitions in one `Public/*.ps1` | defines exactly one function |
| Strip the `<# .SYNOPSIS #>` block from one public file | comment-based help with a synopsis |
| Remove every invocation of one command from the test tree | exercises the exported command &lt;name&gt; somewhere in tests |
| Change `Run.Throw` to `Run.Exit` in the build file | throws rather than exits |
| Remove the `throw` after the coverage comparison | throws on coverage below target |
| Remove `Filter.ExcludeTag = 'PreTag'` | excludes PreTag-tagged tests |
| Delete the `$script:ModuleRoot` line from the psm1 emitter, rebuild | sets `$script:ModuleRoot` |
| Remove `RequiredVersion` from one `Requirements.psd1` entry | pins build dependencies only in Requirements.psd1 |
| Rename `PSScriptAnalyzerSettings.psd1` | has analyzer settings at the repository root |

Record the result of this pass. An assertion that stays green through its own
break is worse than no assertion, because it will be counted as evidence.

The pass against the reference is recorded in
[`baseline/FALSIFICATION.md`](baseline/FALSIFICATION.md): 10 of 12 breaks fire
cleanly, one over-fires, and `throws on coverage below target` does not fire at
all.

## Known limits

- Assertions on the build file are text matches, not semantics. A build file
  that satisfies the regex and does something else passes. Accepted for now:
  the alternative is executing untrusted build code to grade it.
- `Universal` currently encodes one repository's idea of universal. It has been
  validated against exactly one module. Treat the tag as an intention until a
  second, deliberately dissimilar target passes it.
- There is no assertion that the build actually succeeds. That belongs in the
  run harness, which invokes `./build.ps1` and records the exit code alongside
  this suite's score.