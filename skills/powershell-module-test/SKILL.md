---
name: powershell-module-test
description: Write and run a PowerShell module's Pester suite — layered dependency-ordered execution that stops at the first failing layer, Pester 6 assertion syntax, what a test must invoke rather than name. Use when writing tests, when a test run produces a wall of failures with no obvious cause, or when deciding what belongs in the default run versus a pre-tag gate.
---

# Module tests

## Run the layers in order, and stop at the first one that fails

Tests fail in cascades. One unparseable source file produces a lint that reports
clean, a psm1 that will not import, nine import errors, and then every test in
the suite failing against a module that is not loaded. That is **one** defect,
and the wall of red buries the file name that would fix it.

`scripts/Invoke-OrderedTests.ps1` runs five layers in dependency order and stops
at the first failure, printing only that layer's failures:

| # | Layer | Passes when |
|---|---|---|
| 1 | `manifest-parses` | `Import-PowerShellDataFile` reads `src/<Name>/<Name>.psd1` |
| 2 | `files-parse` | `[Parser]::ParseFile` reports no errors for any `.ps1` in `src/` or `tests/` |
| 3 | `module-imports` | `Import-Module` succeeds **in a clean child process** |
| 4 | `unit` | Pester passes, excluding the integration layer |
| 5 | `integration` | Pester passes for integration and contract tests |

```powershell
./scripts/Invoke-OrderedTests.ps1 -Path <repo> -Build
```

`-Build` runs `./build.ps1 -Task Build` between layers 2 and 3, because
`output/` is a build product and is not committed — without it, layer 3 fails
naming the command to run rather than reporting a mystery. The build runs
*after* `files-parse` on purpose: a broken file should be reported by name, not
as a build failure three stages downstream.

Each layer is a precondition for the next, which is what makes stopping
correct rather than merely convenient. A failure at layer 2 says *this file,
this line*. The same defect observed at layer 4 says *37 tests failed*.

### Layer membership, two ways

Both, because neither alone covers a real repository:

- **By directory.** `tests/Integration/` and `tests/Contract/` are the
  integration layer. Everything else under `tests/` is unit. This is what a new
  repository gets for free, with no annotation.
- **By Pester tag.** An `It` or `Describe` tagged `Integration` or `Contract` is
  in the integration layer wherever its file lives. This is what lets one file
  hold a command's unit tests and its contract test without splitting it.

Both are configurable: `-IntegrationDirectory` and `-IntegrationTag`.

### Zero cases is not a pass

A layer that ran nothing graded nothing. The runner reports `INAPPLICABLE`,
never `PASSED`, and says so in the summary. An empty integration layer is
legitimate; an empty `unit` layer is a failure, because a module with no unit
tests has not been tested.

The same rule applies inside Pester. `Run.FailOnNullOrEmptyForEach` is set to
`$false` so that an `It` whose `-ForEach` collection is empty is *inapplicable*
rather than fatal — left at the default, one such `It` aborts its whole
container and takes every assertion that had already passed with it.

### Missing credentials are announced, never quietly skipped

A test tagged `RequiresPat` is excluded when `$env:AZDO_PAT` is unset, and the
runner prints which files were affected and that the layer therefore grades less
than it claims to. A layer that reports success where nothing could contradict
it is worse than one that says it did not run.

## The Pester 6 rules that actually bite

*Source: `docs/testing.md` in PSModuleGraph, and its build's Test task.*

- **Pin the version.** Pester 5 and 6 disagree on assertion syntax, discovery,
  and mocking, and several 5.x versions are usually also installed. A bare
  `Invoke-Pester` picks one silently. Pin `RequiredVersion` in
  `Requirements.psd1` and verify before handing off.
- **Discovery and run happen per file.** Every test file carries its own
  `BeforeAll` that imports the module. Nothing leaks between files; there is no
  shared setup to lean on.
- **Variables shared from `BeforeAll` into `It` need `$script:` scope.**
- **Use hyphenated `Should-*` assertions.** `Should-Be`, `Should-BeTrue`,
  `Should-MatchString`, `Should-BeCollection`. The build sets
  `Should.DisableV5 = $true`, so classic `Should -Be` throws rather than quietly
  working.
- **There is no `Should-NotThrow` and no `Should-NotBeNullOrEmpty`.** To assert
  something does not throw, just call it — an exception fails the test on its
  own. Do not wrap it in `try`/`catch` and assert in the catch, which passes
  when the code is broken a different way. Re-derive the real list rather than
  remembering it:

  ```powershell
  Get-Command -Module Pester -Name 'Should-*' | Select-Object -ExpandProperty Name | Sort-Object
  ```

- **Mocks no longer fall through** to the real command when a `-ParameterFilter`
  does not match. Verify filters rather than assuming a fallthrough.
  `Assert-MockCalled` is gone; use `Should-Invoke` / `Should-NotInvoke`.
- **Piping an empty array sends nothing down the pipeline.** `@() | Should-NotBeNull`
  fails because the assertion never receives a value — it is asserting about
  nothing. Compare, do not pipe: `($null -eq $value) | Should-BeFalse`, or
  `@($x).Count | Should-Be 0`.
- **A terminating error inside `BeforeAll` surfaces as
  `a 'break' or 'continue' statement ... escaped from your code`** on the whole
  `Describe`, with no relationship to the cause. When a `Describe` fails that
  way, call the code under test directly to find the real error. This cost a
  run once already: an empty-collection parameter binding failure surfaced under
  that message and nothing about it named the parameter.

## What a test must do to count

**Invoke the command.** The conformance suite parses test files for a
`CommandAst` whose name matches a public command. Naming the command in a string
does not count — a test that only asserts
`'Get-Thing' -in $module.ExportedCommands` leaves `Get-Thing` recorded as
untested. Write tests that call it, even when the call is inside
`{ ... } | Should-Throw`.

**Test the built module, not the source.** `tests/` imports from
`output/<Name>/`, because that is the artifact users get and the only place the
generated `Export-ModuleMember` exists. Fall back to `src/` only where a dev
loader exists. Coverage is measured against the built psm1 for the same reason —
coverage against `src/` counts lines the build never assembled.

A stale `output/` masks source edits. Build, then test.

## The default run and the pre-tag gate

*Source: `tests/PreTag.Tests.ps1` and the `PreTag` task in PSModuleGraph.*

Two sets, and the split is deliberate:

- The **default** `Test` task excludes tag `PreTag`. The build should stay green
  while an iteration is half done — that is most of what a build is for.
- **`PreTag`** tests are seals on a *finished* iteration. They run immediately
  before a tag and nowhere else. The tag is the claim that the iteration is
  done, so these gate the tag rather than the build.

What belongs in `PreTag`: the version the manifest reports matches the tag about
to be applied and that tag does not exist yet; the previous tag actually reached
the remote at the commit it names, on a branch that contains it. Both of those
caught real releases that shipped wrong — two tags that never left the machine,
and a manifest reporting a version that was already released twice over.

A `PreTag` gate that makes a network call and cannot reach the remote **fails**.
It does not skip. Remote-tracking refs answer from the last fetch, which is a
cache, and a cache would have passed that gate on all three of the iterations it
was built to catch.

## Test layout

```
tests/
  Public/                  mirrors src/<Name>/Public/
  Private/                 mirrors src/<Name>/Private/
  Integration/             the integration layer, by directory
  Module.Quality.Tests.ps1 asserts on the BUILT module, not source
  PreTag.Tests.ps1         everything here is tagged PreTag
  TestHelpers.ps1          dot-sourced by every file's BeforeAll
  fixtures/<Name>/         input data, never imported and never executed
```

**A fixture is input data, not a module anyone maintains.** Tests pass its
*path*. Do not "fix" a fixture's deliberate imperfections — a pinned dependency
that is deliberately the wrong version, functions deliberately absent from
`FunctionsToExport`, a function that throws because it exists only to be parsed.
Several assertions depend on exact counts of what a fixture contains, so adding
a class or a function to one breaks tests that are not obviously related to it.
Say in the fixture's own documentation which imperfections are load-bearing.

## Related

- `powershell-module-build` — the `Test` task that configures Pester and the
  coverage gate.
- `powershell-module-scaffold` — the tree `tests/` mirrors.
- `powershell-module-release` — what a `PreTag` gate is sealing.
