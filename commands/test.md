---
description: Run a module's own build and then the conformance suite against it, reporting both scores uncollapsed.
argument-hint: [target directory] [module name]
---

# /test — build score and conformance score, side by side

Run both gates against the module repository at `$1` (default: the current
directory) and report them as **two numbers**, never averaged.

## Steps

1. **Build.**

   ```
   pwsh -NoProfile -File $1/build.ps1
   ```

   Record: exit code, analyzer finding count, Pester pass/fail/skip, coverage
   percent against the declared target.

2. **Conformance.**

   ```
   pwsh -NoProfile -File evals/conformance/Invoke-Conformance.ps1 `
        -Path $1 -ModuleName $2 `
        -Tag Universal,Repository,HouseStyle,RequiresBuild `
        -ResultPath $1/conformance-result.json
   ```

   Run it **after** the build — the `RequiresBuild` tag reads `output/<Name>/`.

   `-ModuleName` is optional. Discovery prefers a manifest named for the target
   directory, then one sitting directly in the target; a run directory called
   something like `002-first-build` matches neither, and the runner then derives
   the name from `src/<Name>/<Name>.psd1` and says which manifest it read. Pass
   it to override, or to answer an ambiguity the runner refuses to guess at.

3. **Read the score from `result.json`, never from the exit code.** The runner
   exits 0 on a red run on purpose — a red conformance run is data, not a build
   failure. `-PassExitCode` changes that and is for CI steps only.

## Reporting

State both, and state cases-run beside cases-passed:

```
build:       exit 0 | analyzer 0 findings | pester 41/41 | coverage 62% (target 40%)
conformance: 34 / 36 cases run
  FAILED  House style: build file / throws on coverage below target
  FAILED  Public surface / gives Get-Thing comment-based help with a synopsis
```

**Never collapse the two into one percentage.** Conformance measures shape —
manifest, layout, build file, tests, exported names. The build measures whether
the thing assembles and its own tests pass. A module can score 100% on
conformance and do nothing useful; a module can fail four house-style
assertions and work perfectly. Averaging them destroys both.

**Zero cases is not a pass.** An assertion that produced no cases is
*inapplicable* to this target — report it as such, never as a pass.

Name every failing assertion in full. A bucket count with the names collapsed
is not a result anyone can act on.
