---
description: Build a PowerShell module repository to the house conventions, using the powershell-module-scaffold and powershell-module-build skills.
argument-hint: [module name] [target directory]
---

# /build — build a module to the house conventions

Build or extend the PowerShell module at `$2` (default: the current directory),
named `$1`. Follow the `powershell-module-scaffold` and `powershell-module-build` skills; where a
skill and the conformance suite disagree, the suite is the oracle and the
disagreement is a finding worth reporting.

## Steps

1. **Read the contract before writing code.**
   - `evals/conformance/Conformance.Tests.ps1` — the shape assertions.
   - `evals/functional/BRIEF.md` — what the module is for, if one exists.
   Do not infer the conventions from memory. They are graded exactly.

2. **Scaffold**, per `powershell-module-scaffold`:
   `src/<Name>/{<Name>.psd1,Public/,Private/}`, `tests/`, `build.ps1`,
   `<Name>.build.ps1`, `PSScriptAnalyzerSettings.psd1`, `Requirements.psd1`.
   `Public/` is flat, one function per file named for the file, each with
   `.SYNOPSIS` help. The manifest's base name must equal its directory name.

3. **Write the commands**, one public function per file. Private helpers go
   under `Private/`, nesting freely.

4. **Write tests that invoke every public command.** The assertion parses for a
   real call — a command named only in a string counts as untested.

5. **Run `./build.ps1`.** Clean, Lint, Build, Test. Lint findings are a gate,
   not a report. Fix them; do not suppress a rule to get past it without saying
   so.

6. **Report**: the exit code, the analyzer finding count, the Pester
   pass/fail/skip counts, and coverage against the declared target. If coverage
   is below target the build fails — write tests, do not lower the number.

## Rules

- Never weaken, skip, or annotate an assertion because the module fails it.
- The credential rule in `azdo-rest` is not negotiable if the module talks to
  Azure DevOps: `$env:AZDO_PAT` only, never a parameter, never in a URL.
- No `Publish-Module`, no tags, no pushing to `main`.
- If the target directory already contains a module, extend it rather than
  overwriting; report what was there first.
