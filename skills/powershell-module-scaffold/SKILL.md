---
name: powershell-module-scaffold
description: Lay out a PowerShell module repository — src/<Name>/Public flat one-function-per-file, Private nested, manifest with explicit exports, tests mirroring src. Use when creating a new PowerShell module repository, adding a command to one, or fixing a conformance failure about layout, manifest, or exports.
---

# Module scaffold

The layout the conformance suite grades. Every rule here is an assertion
somewhere in `evals/conformance/Conformance.Tests.ps1`; none of it is taste.

## The tree

```
<Repo>/
  build.ps1                     # entrypoint — Repository tag asserts this exact name
  <Name>.build.ps1              # InvokeBuild file — see the powershell-module-build skill
  PSScriptAnalyzerSettings.psd1 # at the ROOT, so editors and CI lint identically
  Requirements.psd1             # the only place build dependencies are pinned
  src/<Name>/
    <Name>.psd1                 # manifest — basename MUST equal its directory name
    Public/                     # FLAT. One file per exported function.
      Get-Thing.ps1
    Private/                    # may nest; the build must still find these
      Rest/Invoke-Something.ps1
    en-US/                      # optional; if present the build must copy it
  tests/
    Get-Thing.Tests.ps1
  output/<Name>/                # build product, never committed
```

## Rules that are graded

**The manifest's base name must equal its directory name.** Discovery looks for
`*.psd1` where `BaseName -eq Directory.Name`. `src/PSAzureDevOpsGraph/PSAzureDevOpsGraph.psd1`
is found; `src/module/PSAzureDevOpsGraph.psd1` is not found at all, and every
downstream assertion then fails for a reason that looks like something else.

**Discovery does not guess.** The suite prefers a manifest named for the
repository directory, then a manifest sitting directly in the target. If neither
rule fires it reports no manifest — there is no "if only one candidate survives,
take it" fallback. When the repository root is a run directory named something
like `002-first-build`, neither rule can fire, and the caller must pass
`-ModuleName <Name>`. This is a property of the harness, not a defect in the
module.

**`Public/` is flat.** A subdirectory under `Public/` silently drops commands
from the export list, because the list is derived from the filenames. Nest under
`Private/` instead — the suite has a dedicated assertion that private functions
in subfolders still reach the built psm1.

**One function per public file, named for the file.** `Get-Thing.ps1` defines
exactly one top-level function and it is called `Get-Thing`. Helper functions go
in `Private/`, not below the public one.

**Three-way agreement.** `Public/*.ps1` basenames, `FunctionsToExport` in the
manifest, and their count must be the same set. The build derives
`Export-ModuleMember` from the filenames while the manifest is written by hand;
this is the seam where they drift.

**Every exported function needs comment-based help with `.SYNOPSIS`.** Either
inside the function body or in a block immediately above the definition — both
placements count, and nothing may sit between the comment and the `function`
keyword but whitespace.

**Export nothing implicitly.** All four keys must be present and none may be
`'*'`:

```powershell
FunctionsToExport = @('Get-Thing', 'Set-Thing')   # explicit names
CmdletsToExport   = @()
VariablesToExport = @()
AliasesToExport   = @()
```

A key left unset defaults to a wildcard. `VariablesToExport = @()` is not the
default and must be written.

**`CompatiblePSEditions` must be declared.** House style, not a universal truth —
most of the gallery omits it.

## The manifest

```powershell
@{
    RootModule            = 'PSAzureDevOpsGraph.psm1'
    ModuleVersion         = '0.1.0'
    GUID                  = '...'            # a real GUID; [guid] must parse it
    Author                = '...'
    CompatiblePSEditions  = @('Core')
    PowerShellVersion     = '7.2'
    FunctionsToExport     = @('Get-Thing')
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    PrivateData           = @{ PSData = @{ Tags = @(); LicenseUri = ''; ProjectUri = '' } }
}
```

`RootModule` names the *generated* psm1, which the build writes into
`output/<Name>/`. It does not exist in `src/`.

## Tests mirror src

`tests/` must exist, and every public command must be **invoked** somewhere in
it. Naming the command in a string does not count — the assertion parses the
test files and looks for a `CommandAst` whose command name matches. A test that
only asserts `'Get-Thing' -in $module.ExportedCommands` leaves `Get-Thing`
recorded as untested.

Write tests that call the command, even when the call is inside
`{ ... } | Should -Throw`.

## Related

- `powershell-module-build` — the `build.ps1` and `<Name>.build.ps1` this layout expects.
- `azdo-rest`, `azdo-pipeline-yaml-refs`, `azdo-graph-assembly` — what goes *in* the files.
