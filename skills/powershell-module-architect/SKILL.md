---
name: powershell-module-architect
description: Design a PowerShell module's command surface — verb-noun naming, one command one question, parameter sets, pipeline support, when to split a command, and what belongs in Public versus Private. Use before writing commands, when adding one to an existing module, or when a command has grown a switch that changes what it means.
---

# Command surface design

Decide the surface before writing it. Every rule here has a downstream cost when
it is got wrong: the export list is derived from filenames, the manifest is
written by hand, and the conformance suite grades the agreement between them.

## Naming

**Approved verbs and singular nouns.** `Get-Verb` is the list.
`Get-PSModuleFunction`, never `Get-PSModuleFunctions`. PSScriptAnalyzer enforces
both — if `PSUseSingularNouns` fires, the name is wrong, so fix the name rather
than the settings file. There are no suppressions for this.

**A prefix per module, on every command.** `Get-AzDo*`, `Get-PSModule*`. Commands
land in a shared session namespace and an unprefixed `Get-Repository` collides.

**The verb states the side effect.** A read-only module has no command whose name
begins with a writing verb — no `New-`, `Set-`, `Remove-`, `Start-`, `Invoke-`
that mutates. This is a testable property: enumerate the exported surface and
assert on the verbs. A module that walks an organisation's infrastructure is
exactly the kind of thing run with a high-privilege token, which is the reason
for the constraint rather than an exception to it.

## One command, one question

A command answers one question a user actually has. The test is whether you can
state what it returns in one sentence without "and".

**Split when parsing and resolving are two questions.** The worked example is
`BRIEF.md`'s pipeline reference pair:

| Command | Answers | Needs |
|---|---|---|
| `Get-AzDoPipelineReference` | what does this YAML document reference? | a file. No network, no credentials, no knowledge of what exists. |
| `Resolve-AzDoPipelineReference` | where does this one reference point? | knowledge of which repositories and paths exist. |

Keeping them separate buys three things:

1. **Parsing is testable with no credentials**, against a file on disk.
2. **Failures are attributable.** A combined command reports resolution failures
   as parsing results, with no way to tell which half was wrong. Three of run
   002's twelve functional cases are resolution failures a combined command would
   have mislabelled.
3. **Either half can be used alone.** Resolution rules change more often than
   YAML syntax does.

The general rule: **split where the inputs differ.** One half needs a file; the
other needs the world. That is two commands.

**Do not split on a switch that changes what the command means.** A `-Resolve`
switch on the parser is the same two commands wearing one name, and every caller
has to know which mode it is in.

## Parameter design

**One parameter set per way of naming the thing.** Every module-inspecting
command in the reference implements the same three, which is what makes the
surface learnable:

| Set | Parameters | Notes |
|---|---|---|
| `ByName` | `-Name` (Mandatory, Position 0), `-RequiredVersion` | the default set |
| `ByPath` | `-Path` (Mandatory) | a directory, `.psd1`, `.psm1`, or `.ps1` |
| `ByModuleInfo` | `-ModuleInfo` (Mandatory, `ValueFromPipeline`) | takes `PSModuleInfo` from the pipeline |

Declare `[CmdletBinding(DefaultParameterSetName = 'ByName')]`, then resolve the
target in **one step** in `process` and do nothing else with the set:

```powershell
$target = Resolve-BoundParameter -Name $Name -Path $Path -ModuleInfo $ModuleInfo `
              -ParameterSetName $PSCmdlet.ParameterSetName
```

**All target resolution lives in one place.** Do not re-implement name lookup,
version selection, manifest discovery, or path probing in each command. When
resolution changes, every command must change together, and that only happens if
there is one file to change.

**`[Parameter(Mandatory)]` rejects an empty collection.** An accumulator
parameter — a `List[object]` passed to a recursive helper, empty on the first
call — needs `[AllowEmptyCollection()]`. Without it every call aborts with
`Cannot bind argument to parameter 'Found' because it is an empty collection`,
and inside Pester that surfaces as an unrelated message about a `break` or
`continue` escaping your code. This cost run 002 real time.

**Parameter shadowing is case-insensitive.** A local `$name` **is** the `$Name`
parameter. Assigning to it re-runs the parameter's validation attributes, so
`$name = $null` against a `[ValidateNotNullOrEmpty()]` parameter throws at that
assignment. Name locals distinctly: `$usingName`, `$nestedName`.

## Pipeline support

Accept from the pipeline where the command's subject is something another command
in the module emits, and declare `process` when you do. A command with
`ValueFromPipeline` and no `process` block sees only the last item.

Emit `pscustomobject` with a `PSTypeName` of `<Module>.<Thing>`, so format files
and downstream `Where-Object` filters have something stable to match on. Every
record carries the two fields that make a result traceable: `Path` and
`StartLine`.

## Public versus Private

**`Public/` is the graded export surface, and a file's location is what exports
it.** The build derives `Export-ModuleMember` from `Public/*.ps1` basenames, so a
private helper sitting in `Public/` gets exported by accident, and a public
function in a `Public/` subdirectory silently does not get exported at all.

**A helper that is not an answer to a user's question goes in `Private/`.** Run
002 needed two helpers with no home in the brief's seven-command table — a path
normaliser and a cycle detector. Both belong in `Private/`. The brief's line
"the final surface is whatever the cases require" invites putting them in
`Public/`, where they would have broken the three-way agreement between
filenames, `FunctionsToExport`, and the export call.

`Private/` may nest freely; `Public/` may not. Nest by subsystem —
`Private/Rest/`, `Private/Yaml/`, `Private/Graph/` — and the generated psm1 must
still find them, which means the build enumerates `Private/` recursively and
sorts by full path so ordering is stable across subfolders.

## Before you write the file

- [ ] Approved verb, singular noun, module prefix
- [ ] One sentence describes what it returns, with no "and"
- [ ] Parsing separated from resolution where the inputs differ
- [ ] Parameter sets match the module's other commands
- [ ] Accumulator and optional-collection parameters allow empty
- [ ] It is in `Public/` only if a user would ask this question
- [ ] Its name is in `FunctionsToExport` — adding the file is not enough
- [ ] A test **invokes** it

## Related

- `powershell-module-scaffold` — the layout these decisions are graded against.
- `powershell-module-docs` — the help every public command needs.
- `powershell-module-plan` — deciding the surface before any of this.
