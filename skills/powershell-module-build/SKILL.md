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

### Take the dependency name as a parameter

Write the resolver **once, parameterised**, not once per dependency:

```powershell
function Resolve-BuildDependency {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $ManifestPath
    )
    # The environment variable is derived from the name, never spelled out.
    $variable = ($Name.ToUpperInvariant() -replace '[^A-Z0-9]', '') + '_MODULE_PATH'
    $override = [Environment]::GetEnvironmentVariable($variable)

    foreach ($candidate in @(
            $override
            (Join-Path (Split-Path -Parent $BuildRoot) "$Name/output/$Name/$Name.psd1")
            (Join-Path (Split-Path -Parent $BuildRoot) "$Name/src/$Name/$Name.psd1"))) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    $installed = Get-Module -ListAvailable -Name $Name | Sort-Object Version -Descending | Select-Object -First 1
    if ($installed) { return $installed.Path }

    throw "$Name was not found. Set $variable, check out $Name beside this repository, or install it."
}
```

The published example resolves one hard-coded dependency, and the way it is used
is copy-and-rename. A module two links down a chain — PSTerraformGraph depends on
PSGraphRenderToHtml, which depends on PSGraphRender — had to rename it by hand in
**four** places: the environment variable, two `throw` messages and the task
name. The second copy is exactly where the old name survives inside a message,
and a `throw` naming the wrong dependency sends a reader to the wrong repository.

If you keep a hard-coded copy anyway, the four rename points are: the
`$env:<DEP>_MODULE_PATH` variable, the sibling-checkout path, the `throw` text,
and the `Write-Build` line. Deriving the variable from `$Name` removes the one
that hides in a string.

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
        # Only with a stated reason, next to the exclusion. See
        # "Suppressing a rule" below for the format and the one recurring case.
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

### Suppressing a rule, and the one that recurs

A suppression with no reason beside it is indistinguishable from a rule somebody
could not get to pass. Write three things, in this order and in a comment
touching the exclusion:

1. **which** rule,
2. **why here** — the specific fact about this repository that makes the rule
   wrong, not a restatement of what the rule does,
3. **what would make it removable**.

```powershell
ExcludeRules = @(
    # PSUseSingularNouns: New-GraphRenderOptions is named by PSGraphRenderToHtml's
    # producer contract, not by this repository. Renaming it to satisfy the
    # analyzer would break every consumer, and a consumer cannot rename it back.
    # Removable if the contract ever renames the command.
    'PSUseSingularNouns'
)
```

**`PSUseSingularNouns` against a contract-fixed command name is the recurring
case.** The analyzer wants `New-GraphRenderOption`; the contract says
`New-GraphRenderOptions`, and a name that crosses a repository boundary is not
this repository's to change. Two modules in two passes hit the same exclusion for
the same reason.

The general rule underneath it: **when a name is fixed by a contract you do not
own, the analyzer is wrong and the suppression is the correct answer** — but only
with the reason written down, because next year the difference between "the
contract fixes this" and "we gave up" is invisible without it.

Prefer the narrowest suppression available. A rule excluded repository-wide in
`PSScriptAnalyzerSettings.psd1` is off for code that has not been written yet;
`[Diagnostics.CodeAnalysis.SuppressMessageAttribute]` on the one function says
the same thing about one place. Exclude repository-wide only when the reason
genuinely applies repository-wide, and say which case it is.

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

**Declaring the `PreTag` task is not the same as having the gate.** The task
selects tests by `-Tag 'PreTag'`, and a repository with no PreTag-tagged test
selects nothing. Guard it:

```powershell
if (($result.PassedCount + $result.FailedCount) -eq 0) {
    throw 'The PreTag filter selected no test at all. A gate that grades nothing is not a gate.'
}
```

Count what **ran**, not `TotalCount`: discovery walks the whole tests path before
the tag filter applies, so `TotalCount` is never zero and a guard written against
it can never fire.

Then write `tests/PreTag.Tests.ps1` in the same pass that declares the task. A
module shipped its first tag with the task declared and no tagged test, so
`-Task PreTag` could only ever throw its own guard, and nobody found out until
somebody ran it two versions later. **The conformance suite could not catch it**:
it asserts the task is declared and that the default `Test` task excludes
PreTag-tagged tests, both of which were true. Nothing asserts that a
PreTag-tagged test exists.

What belongs in it: claims no unit test can make, because they are about what the
code must **never** do or about agreement between documents and code. The version
in the manifest has a worklog and a ledger row; documents name no path that does
not exist; no document can publish by being followed; `src/` reaches no network
or shells out to no tool the module's boundaries say it never runs.

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

## `psmodule.settings.psd1` — optional, enumerated, and refusing

A target may carry one file at its root that both the build and the conformance
suite honour:

```powershell
# psmodule.settings.psd1
@{
    CoverageThreshold      = 75       # the Test task's throw threshold
    ModuleProfile          = 'script' # 'script' | 'hybrid' (placeholder)
    CompletionCacheDefault = $false   # generated completers cache by default
}
```

**Three keys, and only three.** The list is the contract, not a schema to grow
casually. **An unknown key is a refusal that names it** — not a warning, not
ignored. `CoverageThresold = 90` otherwise grades at 75 while the file on disk
says 90, and nothing in the output disagrees with the file. A near-miss *value*
is refused on the same terms: `'90'` as a string is not coerced, because a
reader that coerces has decided what the user meant.

**Precedence: explicit parameter > file > built-in default.**

**The defaults are the measured configuration.** Every score this plugin
publishes was taken with no settings file present and these exact values. That
is why a target shipping no file needs no thought: it is graded the way every
recorded run was graded.

### Which claim each switch invalidates when flipped

This table is the reason the settings file is worth having at all. A knob whose
consequence is not written down gets turned to make a build green.

| Setting | Flipping it invalidates |
|---|---|
| `CoverageThreshold` | **Every published conformance score.** The recorded runs were taken at 75. A target graded at another value is not on the same scale and may not be compared with them — the same rule as `cases-defined`, applied to a threshold instead of a denominator. |
| `ModuleProfile` | **Every claim this plugin makes.** All of them were measured against `script` modules. `hybrid` is *reserved and not implemented*: nothing has been built or graded under it, and setting it asserts a capability that does not exist. |
| `CompletionCacheDefault` | **Nothing measured** — no scored run has used a completer. It changes generated code, so a module built with it on and one built with it off are different artifacts and a score is about one of them. |

Lower the coverage threshold if a module genuinely warrants it — and say so in
the release notes, because you have moved the number the score is about, not
just the build's patience.

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
