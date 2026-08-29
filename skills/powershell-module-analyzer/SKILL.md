---
name: powershell-module-analyzer
description: Analyse a PowerShell module from its AST — commands invoked, native executables referenced, modules required — and when an external dependency turns up that you have no knowledge of, research it then and write docs/knowledge/<tool>.md into the target. Use when auditing a module's dependencies, when a build fails on a tool nobody documented, or before touching a module you have not read.
---

# Module analyzer

## Never run the code you are analysing

**No `Import-Module`, no dot-sourcing, no `Invoke-Expression`, no reflection
load, no `Add-Type` against the target, and no invocation of anything the target
defines.** Every fact comes from the AST, `Import-PowerShellDataFile`, or the
filesystem.

Importing a module executes its top level, its `ScriptsToProcess`, and any class
static constructors. That is arbitrary code execution, against a repository the
user has not read and does not trust — which is the normal case for analysis.

If answering a question would require importing the target, **return less
information instead.** An incomplete-but-honest result is correct; an accurate
result obtained by executing untrusted code is a security bug. Report what cannot
be resolved statically as unresolved, rather than resolving it dynamically.

Two deliberate exceptions, and only these:

- **`Import-PowerShellDataFile`** parses `.psd1` as restricted data and does not
  execute it. Do not replace it with `Invoke-Expression` or with dot-sourcing.
- **`Get-Module -ListAvailable`** reads manifest metadata without importing. Use
  it for path discovery only — never call `Import-Module` to "just check"
  something.

## Parsing

**Always `[Parser]::ParseFile`, never `[Parser]::ParseInput`.** `ParseInput`
leaves `$ast.Extent.File` null, so every node parsed that way loses its path, and
every record downstream reports a null `Path`. The whole value of an analysis is
that a result traces back to a file and a line number.

```powershell
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $path, [ref] $tokens, [ref] $errors)
```

**Route every parse through one helper**, and memoise on path plus last-write
time: an unchanged file is parsed once no matter how many walkers ask for it,
while an edited file is re-parsed. This matters more than it sounds — a single
dependency graph can call seven getters, each walking every file in the module.

**Parse errors are data, not failures.** A file that does not parse is reported
with its errors attached; it does not abort the run. A module with one broken
file still yields results for the others.

**`.psd1` files are parsed but skipped by most walkers.** Manifest *content*
comes from `Import-PowerShellDataFile`, not from walking its AST.

**`Import-PowerShellDataFile` needs `-ErrorAction Stop`.** A `.psd1` that will
not parse raises a **non-terminating** error, so without it the `catch` never
runs and a broken manifest falls back in total silence.

**Reading manifest data needs a helper under `Set-StrictMode -Version Latest`**,
which turns a missing key into a terminating error. A plain property access
throws on any manifest omitting an optional key.

## What to walk for

| Question | AST node | Watch for |
|---|---|---|
| Which commands does it invoke? | `CommandAst` → `GetCommandName()` | a name built at runtime returns `$null`; report it unresolved, do not guess |
| Which are external? | `CommandAst` where the name resolves to nothing in the module | this is the dependency list |
| Which native executables? | `CommandAst` whose name ends `.exe`/`.cmd`/`.bat`, and `&` invocations of a literal path | a path in a variable is unresolvable; report it |
| Which modules are required? | manifest `RequiredModules`, plus `Import-Module` / `#Requires` in the AST | the manifest and the code disagreeing is the finding |
| What does it export? | manifest `FunctionsToExport` vs `Public/*.ps1` basenames | this is the seam where they drift |
| What types does it define? | `TypeDefinitionAst` | classes and enums both |
| What does it `using`? | `UsingStatementAst` | assemblies are a deployment dependency |

**Match structurally, never by text.** Text matching produces both failure modes,
and both have happened: matching something unrelated, and matching a comment that
documents the thing. Five build-file assertions in this project's own conformance
suite were satisfied by a block comment quoting the code they looked for.

**The manifest and the code disagreeing is the result, not an error.** A module
that imports `powershell-yaml` at first use and declares no `RequiredModules`
imports fine on a machine without it and fails only when a document is parsed.
That is finding F-12 from run 002, and an analyzer that reconciles the two lists
silently would have hidden it.

## When a dependency turns up that you have no knowledge of

The case that motivates this: the AST names `sqlpackage.exe`. You do not know its
flags, its exit codes, where it installs, or what its failures look like.
**Research it at that moment** — the vendor's documentation on the web — and
write what you learned into the target repository:

```
docs/knowledge/sqlpackage.md          what it is, install locations, the flags
                                      this module uses, exit codes, version
                                      differences that matter here
docs/TROUBLESHOOTING.md               one entry per symptom: what the user sees,
                                      the command that reveals why, the fix
```

**Knowledge appears when a dependency appears, and never before.** Writing a
tooling reference for something the module does not use costs every future reader
who has to decide whether it is relevant. This is the same tiering rule the
reference implementation applies to its own instructions: a fact needed only
while performing a specific task lives with that task, not in the always-loaded
tier.

What a knowledge doc must contain to be worth its cost:

- **Where the tool actually is.** Named install paths, the environment variable
  that overrides them, and what to do when it is on none of them.
- **The exact invocation this module uses**, with every argument explained. Not
  a link to the full reference — the subset that is used here.
- **Exit codes and what they mean**, including the ones that are not zero and not
  a failure.
- **What a failure looks like on the console**, verbatim, so a search finds it.
- **The version you checked, and the date.** A knowledge doc without those is a
  claim with no expiry, and it will be wrong before anyone notices.
- **What you could not determine.** Distinguish observed from inferred, and say
  which is which.

Then add the troubleshooting entries, per the diagnosability rule: the failure is
visible, there is a **named command** that reveals why, and the prerequisite is
either checked or its absence produces an error naming what is missing.

```markdown
### `sqlpackage.exe` is not recognised

**Symptom.** `The term 'sqlpackage.exe' is not recognized...`

**Reveal it.** `Get-Command sqlpackage.exe -ErrorAction SilentlyContinue`
and `Test-Path $env:SQLPACKAGE_PATH`

**Fix.** Install DacFramework, or set `$env:SQLPACKAGE_PATH` to the directory
holding it. The build resolves it in that order and throws naming both.
```

## Reporting an analysis

- **Distinguish observed from inferred.** Anything claimed from one target is a
  hypothesis with an evidence count attached, not a fact.
- **Say what did not resolve**, by name and location. A dependency list with the
  unresolvable entries dropped looks complete and is not.
- **Zero findings is a result, and so is zero cases.** An analysis that walked
  nothing must say so rather than reporting a clean bill.

## Related

- `powershell-module-architect` — what the surface *should* look like.
- `powershell-module-docs` — where the knowledge doc sits among the others.
- `powershell-module-build` — declaring what the analysis found.
