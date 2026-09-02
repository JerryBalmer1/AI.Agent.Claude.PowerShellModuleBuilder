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
    <Name>.psm1                 # DEV LOADER, committed. See below — without it
                                # `Import-Module src/<Name>/<Name>.psd1` fails.
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
this is the seam where they drift. The committed dev loader below adds a fourth
corner that the suite does **not** grade — keep it in step by hand.

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

`RootModule` names a psm1 the build writes into `output/<Name>/`. **A psm1 of
that name must also exist in `src/`, and it is not the same file** — see the
next section.

## The dev loader, and why `src/` is otherwise un-importable

`RootModule = '<Name>.psm1'` is a relative reference resolved beside the
manifest. The build generates that file into `output/`, so if `src/` holds only
the manifest then

```powershell
Import-Module ./src/<Name>/<Name>.psd1
```

**fails outright** — the manifest points at a file that is not there. Everything
downstream fails for a reason that looks like something else: an acceptance test
that imports from source, a unit test run before a build, a quick REPL check.

Commit a dev loader at `src/<Name>/<Name>.psm1`:

```powershell
# DEV LOADER. Not the build product.
#
# The build concatenates Private/** then Public/* into
# output/<Name>/<Name>.psm1 and that generated file is what ships. This exists
# so the manifest in src/ is importable directly.
#
# It DOT-SOURCES rather than concatenating, so $script:ModuleRoot means the same
# thing under both loaders and any asset resolves either way.
$script:ModuleRoot = $PSScriptRoot

foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -Recurse -File | Sort-Object FullName) +
    @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Public') -Filter *.ps1 -File | Sort-Object Name)) {
    . $file.FullName
}

Export-ModuleMember -Function 'Get-Thing', 'Set-Thing'
```

Three properties are load-bearing, and each is a way the loader can be wrong
while appearing to work:

1. **Private then Public, Private recursively.** The same order the build uses.
   A different order works until a public function calls a private one at load
   time.
2. **Dot-source, do not concatenate.** Under concatenation `$PSScriptRoot` is
   the *generated* file's directory; under dot-sourcing it is each source file's
   own. Setting `$script:ModuleRoot = $PSScriptRoot` once at the top, before the
   loop, is what makes the two agree — so a module that resolves a template or a
   culture directory from `$script:ModuleRoot` finds it under both.
3. **The export list is the same set as the manifest's `FunctionsToExport`.**
   Three-way agreement now has a fourth corner. A dev loader exporting more than
   the manifest lets a test pass against a function that is not shipped.

**Two modules in two consecutive passes needed this, and both times it was found
by an acceptance test failing rather than by reading a skill.** That is why it is
in the scaffold rather than in a troubleshooting note.

Its cost is a fourth place the export list is written. Worth it: the failure it
prevents is silent at scaffold time and loud much later, and it is the only way
to import a module before it has ever been built.

## Tests mirror src

`tests/` must exist, and every public command must be **invoked** somewhere in
it. Naming the command in a string does not count — the assertion parses the
test files and looks for a `CommandAst` whose command name matches. A test that
only asserts `'Get-Thing' -in $module.ExportedCommands` leaves `Get-Thing`
recorded as untested.

Write tests that call the command, even when the call is inside
`{ ... } | Should -Throw`.

## A command that takes a `-Path` must handle an absolute one

```powershell
# WRONG. Produces C:\here\C:\there when $Path is already rooted.
$full = Join-Path (Get-Location) $Path
```

```powershell
# RIGHT.
$full = [System.IO.Path]::IsPathRooted($Path) ? $Path : (Join-Path (Get-Location).ProviderPath $Path)
```

Two defects in one line, and both are worth stating separately.

**`Join-Path` does not check whether its second argument is already rooted.** It
concatenates, and the result is a path that cannot exist, so the failure surfaces
later as a file-not-found somewhere unrelated to the command that built it.

**`(Get-Location)` and the process working directory are different things.**
PowerShell's `Set-Location` moves the former and does not move the latter, so
anything that resolves a relative path through .NET — `[System.IO.Path]`,
`File.WriteAllText`, most things a module reaches for — is working from a
directory the user cannot see and did not choose. Use
`(Get-Location).ProviderPath`, which is the filesystem path of the location
PowerShell believes it is at.

This shipped in a run's `Export-*` command and **never fired**, because every
call in the run passed a relative path. The first absolute path came from
`$TestDrive` in the test suite written two iterations later.

That is the argument for the mocked end-to-end tests in the section above, made
concretely: they were written to satisfy a conformance assertion about exercising
every exported command, and they found a real defect in the one command the
happy path could not reach. **A command whose only caller is you is a command
whose parameters have only ever been given the values you had in mind.**

## Related

- `powershell-module-build` — the `build.ps1` and `<Name>.build.ps1` this layout expects.
- `azdo-rest`, `azdo-pipeline-yaml-refs`, `azdo-graph-assembly` — what goes *in* the files.
