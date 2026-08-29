---
name: powershell-module-build
description: Write build.ps1 and <Name>.build.ps1 for a PowerShell module — InvokeBuild tasks Clean/Lint/Build/Test/PreTag, PSScriptAnalyzer as a gate with ParseError in its severity list, Pester with a coverage threshold that throws, exit-code discipline. Use when creating or fixing a module build, when a lint gate goes green on a file that will not parse, or when a conformance failure names a build task, Run.Throw, coverage, or the psm1 emitter.
---

# Build script

Two files. `build.ps1` at the repository root is the entrypoint anyone runs;
`<Name>.build.ps1` beside it holds the InvokeBuild tasks. The conformance suite
reads the second one **as syntax, not as text** — every assertion here was once
a regex, and every one of them was defeated by a block comment quoting the line
it looked for. A comment is not a task, an assignment, or a gate.

## `build.ps1` — the entrypoint

Its job is to make the build runnable from nothing: resolve the pinned
dependencies in `Requirements.psd1`, then hand off to InvokeBuild. It must exit
nonzero when anything fails.

```powershell
#Requires -Version 7.2
[CmdletBinding()]
param([string[]] $Task = '.')

$ErrorActionPreference = 'Stop'
foreach ($name in (Import-PowerShellDataFile "$PSScriptRoot/Requirements.psd1").Keys) {
    if (-not (Get-Module -ListAvailable $name)) {
        throw "Missing dependency '$name'. Install it and re-run."
    }
    Import-Module $name -Force
}
try {
    Invoke-Build -Task $Task -File "$PSScriptRoot/<Name>.build.ps1"
    exit 0
} catch {
    Write-Error $_
    exit 1
}
```

Resolve dependencies rather than installing them silently. A build that reaches
the gallery on its own can change what it is testing between two runs.

## `Requirements.psd1`

Every entry must state `RequiredVersion` or `MinimumVersion`. An unpinned
dependency is the assertion's failure case.

```powershell
@{
    InvokeBuild        = @{ MinimumVersion = '5.10.0' }
    Pester             = @{ MinimumVersion = '5.5.0' }
    PSScriptAnalyzer   = @{ MinimumVersion = '1.21.0' }
    'powershell-yaml'  = @{ MinimumVersion = '0.4.7' }
}
```

This is the **only** place dependencies are pinned. Do not also pin them in the
manifest's `RequiredModules` — the assertion is about having one source of truth.

`RequiredModules` in the manifest is for **runtime** dependencies, which are a
different thing from build ones. A module that imports `powershell-yaml` when it
parses a document but declares nothing has a real gap: `Import-Module` succeeds
on a machine without it and fails only when a document is parsed. Declare a
runtime dependency in the manifest and a build dependency in `Requirements.psd1`;
neither is a reason to write the other one twice.

**Finding a module is not the same as finding the right one.** A resolution step
that checks a path exists and stops is a step that cannot fail:

```powershell
$found    = [version](Import-PowerShellDataFile $resolvedManifest).ModuleVersion
$declared = @((Import-PowerShellDataFile $ManifestPath).RequiredModules |
    Where-Object { $_ -is [System.Collections.IDictionary] -and $_['ModuleName'] -eq $name })
if ($declared.Count -ne 1) {
    throw "The manifest declares $($declared.Count) RequiredModules entries for '$name'. The version this build resolved cannot be checked against a requirement that is not there."
}
# Every constraint RequiredModules can express, not the one written today.
foreach ($key in 'RequiredVersion', 'ModuleVersion', 'MaximumVersion') { ... }
Write-Build Green "  ${name}: $found at $resolved"      # the version, out loud
```

A sibling checkout drifted three minor versions past its pin and the build went
on using it until a golden comparison broke somewhere unrelated. Check every
constraint the requirement *can* express, not the one that happens to be written
today — a requirement that stops being checked when its shape changes is a
requirement nobody is checking. And print the resolved version, so the fact sits
next to the failure rather than three tasks away from it.

## `<Name>.build.ps1` — the tasks

Five tasks must exist by name: `Clean`, `Lint`, `Build`, `Test`, `PreTag`. The
default task must declare exactly these dependencies, in this order:

```powershell
task . Clean, Lint, Build, Test
```

The suite parses the default task's dependency list as an array literal and
compares `'Clean,Lint,Build,Test'` as names. Adding `PreTag` to the default
breaks it — `PreTag` exists precisely so that a half-finished iteration can
still build green.

### `PSScriptAnalyzerSettings.psd1` — and the severity that is not there

At the repository root, so editors and CI lint identically to the build.

```powershell
@{
    # ParseError is listed EXPLICITLY. See below.
    Severity     = @('ParseError', 'Error', 'Warning')

    ExcludeRules = @(
        # Only with a stated reason, next to the exclusion.
        'PSUseShouldProcessForStateChangingFunctions'
    )

    Rules        = @{
        PSPlaceOpenBrace           = @{ Enable = $true; OnSameLine = $true }
        PSUseConsistentIndentation = @{ Enable = $true; IndentationSize = 4 }
    }
}
```

**`Severity = @('Error','Warning')` turns the lint gate off for the one class of
defect that makes a module unloadable.** `Invoke-ScriptAnalyzer -Settings`
filters diagnostics by severity, and `ParseError` is its own severity outside
`Error`. A settings file that lists severities explicitly — the idiom every
example shows — silently drops every parse error.

This is finding F-3 from run 002, and it is the most serious defect that run
produced. The `Lint` task reported **clean** on a source file that could not be
parsed at all. The build failed later, in `Test`, when the generated psm1 refused
to import with nine cascading errors pointing at the generated file rather than
the source. A repository whose tests did not import the module would have shipped
a green build over an unparseable file.

Both states were run: with `ParseError` listed the file is reported; without it,
it is not.

Two corollaries:

- **The gate had only ever been green.** An assertion or gate that has only ever
  passed is indistinguishable from one that cannot fail. Break it once on
  purpose and watch it go red before trusting it.
- **A lint gate is not a parse check.** Even with `ParseError` listed, the
  failure names the analyzer's finding count and not always the file. Run the
  `files-parse` layer of `powershell-module-test` first when a build fails in a
  way that does not name a source file.

### Lint is a gate, not a report

```powershell
task Lint {
    $findings = Invoke-ScriptAnalyzer -Path "$BuildRoot/src" -Recurse `
                    -Settings "$BuildRoot/PSScriptAnalyzerSettings.psd1"
    if ($findings) {
        $findings | Format-Table -AutoSize | Out-String | Write-Host
        throw "PSScriptAnalyzer reported $($findings.Count) finding(s)."
    }
}
```

### Build emits the psm1

The generated module is a concatenation of `Private/**` then `Public/*`, and it
is graded on four things, each checked structurally:

1. The text contains `auto-generated` (case-insensitive).
2. `$script:ModuleRoot = $PSScriptRoot` is a real **assignment** whose right side
   mentions `$PSScriptRoot`. Concatenation moves what `$PSScriptRoot` means, so
   assets must resolve from a variable that is the same under the build and
   under a dev loader.
3. `Export-ModuleMember -Function` is a real **call** listing every name in
   `FunctionsToExport` as string constants inside that call.
4. Functions defined in nested `Private/` subfolders are present as definitions.

Culture directories (`en-US`, `fr`, …) under `src/<Name>/` must be copied into
`output/<Name>/` or `Get-Help` will not find `about_` topics.

```powershell
task Build {
    $out = "$BuildRoot/output/<Name>"
    $null = New-Item -ItemType Directory -Path $out -Force
    $sb = [System.Text.StringBuilder]::new()
    $null = $sb.AppendLine('# This file is auto-generated by the build. Do not edit.')
    $null = $sb.AppendLine('$script:ModuleRoot = $PSScriptRoot')
    foreach ($f in @(Get-ChildItem "$src/Private" -Filter *.ps1 -Recurse -File) +
                   @(Get-ChildItem "$src/Public"  -Filter *.ps1 -File)) {
        $null = $sb.AppendLine((Get-Content $f.FullName -Raw))
    }
    $names = (Get-ChildItem "$src/Public" -Filter *.ps1 -File).BaseName
    $null = $sb.AppendLine("Export-ModuleMember -Function $(($names | ForEach-Object { "'$_'" }) -join ', ')")
    Set-Content "$out/<Name>.psm1" -Value $sb.ToString() -Encoding utf8NoBOM
}
```

Emit the export call and the `$script:ModuleRoot` assignment as **code**. A
generated file is the one place a commented-out line is cheapest to write by
accident, and all three of these assertions have been fooled by exactly that.

### Test configures Pester, and the coverage throw is the gate

```powershell
task Test {
    $cfg = New-PesterConfiguration
    $cfg.Run.Path            = "$BuildRoot/tests"
    $cfg.Run.Throw           = $true          # NOT Run.Exit — that kills the host
    $cfg.Should.DisableV5    = $true
    $cfg.Filter.ExcludeTag   = 'PreTag'
    $cfg.CodeCoverage.Enabled = $true
    $cfg.CodeCoverage.Path    = "$BuildRoot/output/<Name>/<Name>.psm1"
    $result = Invoke-Pester -Configuration $cfg

    # Read the target back off the result rather than keeping a second copy of
    # the number. Two thresholds in two places drift, and the drift is silent.
    $coverage = $result.CodeCoverage
    $percent  = [math]::Round($coverage.CoveragePercent, 2)
    $target   = $coverage.CoveragePercentTarget
    if ($percent -lt $target) {
        throw "Line coverage $percent% is below the target of $target%. Raise coverage, or lower the target deliberately and say so."
    }
    Write-Build Green "Line coverage: $percent% (target $target%)"
}
```

Four graded facts live in that task body and nowhere else:

- `Run.Throw = $true` is **assigned**, and `Run.Exit` is never assigned at all.
- `Should.DisableV5 = $true` is assigned.
- `Filter.ExcludeTag` is assigned something matching `PreTag`.
- `CodeCoverage.Path` is assigned something matching `psm1` — coverage measured
  against `src/` counts lines the build never assembled.

**`CoveragePercentTarget` only reports.** The `throw` after comparing the
percentage is the actual gate, and the assertion looks for a `throw` inside an
`if` whose *condition* reads a coverage percentage, inside the `Test` task. A
`throw` anywhere else in the file — in the dependency resolver, in the PreTag
guard — does not make this gate exist.

**The gate reads its own declared threshold.** `CodeCoverage.CoveragePercentTarget`
is set once, and the `throw` compares against what it reads back from the result.
Declaring the number twice — once to Pester, once to a `$CoverageTarget`
parameter the `throw` uses — creates two facts that must agree and are edited in
different places. They drift, and the drift is silent because both halves keep
working.

State the number you chose and report the number you got, on every run. A
threshold quietly lowered until the build passes measures nothing, and one that
is never printed is one nobody notices sitting at 74.88% against a target of 75
through three green builds.

## Task order, and what each stage guarantees

```powershell
task . Clean, Lint, Build, Test
```

Restore, lint, build, test, package — in that order, because each stage is a
precondition for the next and a failure is cheapest where it is closest to its
cause.

- **Restore** resolves pinned dependencies. It never installs silently: a build
  that reaches the gallery on its own can change what it is testing between two
  runs. `-Bootstrap` is an explicit, separate request.
- **Clean** removes `output/`. Nothing downstream should ever see a stale
  artifact.
- **Lint** runs before anything is assembled, so a defect is reported against
  the source file that holds it.
- **Build** emits the psm1. Nothing before this point needs the module to work.
- **Test** imports the built artifact and gates on coverage.
- **Package** and **PreTag** are separate tasks and are **not** in the default.
  A half-finished iteration should still be able to run a green build.

The default task's dependency list is graded as an array literal and compared as
names: `'Clean,Lint,Build,Test'`. Adding `PreTag` to it breaks that assertion,
and breaks the property the split exists for.

## Exit-code discipline

The build's contract is: **nonzero means something failed.** Three places get
this wrong by default.

- **`Run.Throw = $true`, never `Run.Exit`.** `Run.Exit` makes Pester call `exit`,
  which can terminate the host process running the build. `Run.Throw` raises
  inside InvokeBuild, which fails the task properly and lets the rest of the
  build react. One conformance assertion checks `Run.Exit` is never assigned.
- **`build.ps1` catches and exits 1.** InvokeBuild's failure has to become a
  process exit code, or a caller reading `$LASTEXITCODE` sees success.
- **A tool that reports data must not exit nonzero.** `Invoke-Pester` sets
  `$LASTEXITCODE` to the failure count even with `Run.Throw` and `Run.Exit` both
  off. A script wrapping it whose contract is "a red run is data, read the
  result file" must `exit 0` explicitly, or it contradicts itself and every
  caller treats a red run as a broken runner.

A consequence worth knowing rather than fixing: `Run.Throw` aborts the `Test`
task before the coverage gate runs, so **a build with failing tests reports no
coverage number at all.** That is correct — for a red build nobody wants one —
but a reader comparing builds will notice coverage is absent for failed ones and
should know it is structural, not an omission.

## Known trap

`Run.Throw = $true` makes Pester throw, which InvokeBuild turns into a failed
task and `build.ps1` turns into exit 1. That is the wanted behaviour. Do not
also set `Run.Exit` — one assertion checks it is absent, and it terminates the
host process rather than the build.

## Related

- `powershell-module-scaffold` — the tree these tasks operate on.
- `powershell-module-test` — the suite the `Test` task runs, and the ordered
  runner to reach for when a build fails without naming a file.
- `powershell-module-deploy` — what `output/` has to contain to be publishable.
