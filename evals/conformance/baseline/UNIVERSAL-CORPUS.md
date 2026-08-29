# Universal, against eight dissimilar modules

Closing the loop flagged since the first baseline: `Universal` encoded one
repository's idea of universal and had been validated against exactly one
module. This is the first run against targets nobody wrote it for.

Targets: the eight modules in `gallery/corpus.json`, fetched by
`gallery/fetch.ps1` and verified against `gallery/corpus.lock.json`. Nothing
from `gallery/modules/` is committed, nothing in any corpus module was modified,
and no assertion was changed. Collection only.

## Confidence level, stated honestly

Ten distinct `Universal` assertions. Nine targets — the reference plus eight
corpus modules. How many targets each assertion has now survived:

| Assertion | Ran on | Passed on | Failed on |
|---|---|---|---|
| `exists, and its base name matches its directory` | 9 | **9** | — |
| `parses as PowerShell data` | 9 | **9** | — |
| `declares a RootModule` | 9 | **9** | — |
| `declares a ModuleVersion that parses as a version` | 9 | **9** | — |
| `declares a GUID that parses as a GUID` | 9 | **9** | — |
| `exports functions by explicit name, never by wildcard` | 9 | 7 | Az, Az.Accounts |
| `exports no cmdlets, variables, or aliases implicitly` | 9 | 4 | Az, Az.Accounts, ImportExcel, Crescendo, SqlServerDsc |
| `declares the PowerShell editions it claims to support` | 9 | 3 | ImportExcel, Crescendo, PSDepend, Pester, SqlServerDsc, posh-git |
| `defines every function the manifest exports somewhere in source` | 9 | 4 | ImportExcel, Crescendo, Pester, SqlServerDsc, posh-git |
| `gives <file> comment-based help with a synopsis` | **3** | 2 | ImportExcel |

**Five of ten assertions survive all nine targets.** Those five are the only part
of `Universal` that has earned the name, and all five are manifest-shape checks.

The last row is the one to read carefully. It ran on **three** targets, not nine:
it is scoped to `Public/*.ps1`, and six of the eight corpus modules have no
`Public/` directory, so it produced zero test cases and neither passed nor
failed. Zero cases is not a pass. Its confidence level is three targets.

## The run collapsed before it could measure anything

Run exactly as committed, against `gallery/modules/<name>/<version>/` as
instructed, all eight targets failed at discovery:

| Module | Score, suite as committed | Container |
|---|---|---|
| posh-git | 1/11 (9.09%) | **failed** |
| ImportExcel | 1/11 (9.09%) | **failed** |
| Az.Accounts | 1/11 (9.09%) | **failed** |
| Pester | 1/11 (9.09%) | **failed** |
| Microsoft.PowerShell.Crescendo | 1/11 (9.09%) | **failed** |
| SqlServerDsc | 9/11 (81.82%) | **failed** |
| PSDepend | 1/11 (9.09%) | **failed** |
| Az | 1/11 (9.09%) | **failed** |

Two structural blockers, both Bucket A, both described below as **A-C1** and
**A-C2**. Neither is an assertion, so neither could be sorted as one, and
together they made the instructed run incapable of saying anything about the
other assertions.

To get the data H2 exists to collect, a second pass neutralised exactly those
two blockers and nothing else:

- targets restaged under `scratch/corpus-targets/<name>/` so the manifest's
  directory is named for the module — the layout the suite's own discovery
  comment documents. The module bytes are untouched.
- a scratch-only copy of the runner with `Run.FailOnNullOrEmptyForEach = $false`,
  so an `It` with an empty `-ForEach` yields zero cases instead of aborting the
  container. **Not committed.** No assertion differs between the two runners.

Every per-assertion number in this document comes from that second pass. The
scores in the table above are the honest answer to "what happens if you run this
today", and they measure the suite, not the modules.

## Per module

### posh-git 1.1.0 — *control*

> "Nothing. A plain script module of moderate size."

**9/11 (81.82%)**

- `declares the PowerShell editions it claims to support` — **A-C7**
- `defines every function the manifest exports somewhere in source` — **A-C4**.
  `Write-VcsStatus` is defined at `GitPrompt.ps1:899` as
  `function Global:Write-VcsStatus`. The suite reads `FunctionDefinitionAst.Name`
  and gets `Global:Write-VcsStatus`, which never matches the exported name.

The corpus's designated control fails two Universal assertions, both for suite
reasons. That is the finding: if the control cannot pass, the tag is not
measuring what it claims.

### ImportExcel 7.8.10 — *binary assemblies*

> "RequiredAssemblies and shipped DLLs beside a large script surface."

**17/67 (25.37%)** — the only module with enough `Public/*.ps1` to exercise the
help assertion at scale, and the lowest score in the corpus.

- `gives <file> comment-based help with a synopsis` × **47** — **B-C4**. Real:
  47 of its public function files carry no `.SYNOPSIS` block.
- `defines every function the manifest exports somewhere in source` — mixed.
  `New-Plot` is defined in `ImportExcel.psm1` (**A-C3**). `Export-ExcelSheet` and
  `Invoke-AllTests` are **B-C3**: both are `[Alias()]` names on other functions,
  listed in `FunctionsToExport` as though they were functions.
- `exports no cmdlets, variables, or aliases implicitly` — **B-C1**
- `declares the PowerShell editions it claims to support` — **A-C7**

### Az.Accounts 5.5.2 — *azure-style, cmdlets from a binary*

> "A large Azure module whose exports are cmdlets implemented in C#, not
> functions written in PowerShell."

**9/11 (81.82%)**

- `exports functions by explicit name, never by wildcard` — **A-C5**.
  `FunctionsToExport = @()` and `CmdletsToExport` lists 60-odd cmdlets. Exporting
  zero *functions* is correct for this module; the assertion's
  `Count -gt 0` clause is not a universal truth.
- `exports no cmdlets, variables, or aliases implicitly` — **B-C1**.
  `VariablesToExport` is commented out at line 115, so the key is absent and does
  default to a wildcard. Real, and the assertion caught it.

One of the two the brief flagged. It does stress `defines every function the
manifest exports` — and passes it, vacuously, because it exports no functions at
all. The assertion that actually engages is the wildcard one, and it engages
wrongly.

### Pester 5.7.1 — *generated single file, very large*

> "A .psm1 generated at build time, holding several hundred functions in one
> file."

**9/11 (81.82%)**

- `defines every function the manifest exports somewhere in source` — **A-C3**.
  `function Invoke-Pester` is in `Pester.psm1`. The suite globs `*.ps1` only.
- `declares the PowerShell editions it claims to support` — **A-C7**

### Microsoft.PowerShell.Crescendo 1.1.0 — *classes and enums*

**6/11 (54.55%)**

- `exports no cmdlets, variables, or aliases implicitly` × 3 — **B-C1**. All
  three keys absent.
- `defines every function the manifest exports somewhere in source` — **A-C3**
- `declares the PowerShell editions it claims to support` — **A-C7**

### SqlServerDsc 17.5.1 — *using module chain and class inheritance*

**8/11 (72.73%)**

- `exports no cmdlets, variables, or aliases implicitly` — **B-C2**. Explicitly
  `'*'`.
- `defines every function the manifest exports somewhere in source` — **A-C3**.
  All 161 exports live in `SqlServerDsc.psm1`.
- `declares the PowerShell editions it claims to support` — **A-C7**

**Read this module's as-is run before trusting any score.** Run against
`gallery/modules/SqlServerDsc/17.5.1/`, discovery did not fail — it succeeded on
the wrong module. It selected
`Modules/SqlServerDsc.Common/SqlServerDsc.Common.psd1`, a bundled helper, and
returned 81.82% for it. Of the 51 `.psd1` files in the package, that is the one
whose base name matches its own directory. See **A-C1**.

### PSDepend 0.5.0 — *dynamic dispatch*

**18/19 (94.74%)** — the highest score in the corpus.

- `declares the PowerShell editions it claims to support` — **A-C7**

The second of the two modules with a `Public/` directory, and it passes the help
assertion on all of them.

### Az 16.2.0 — *manifest only*

> "A rollup module with no code at all: a manifest listing eighty
> RequiredModules and nothing else."

**9/11 (81.82%)**

- `exports functions by explicit name, never by wildcard` — **A-C5**. A rollup
  with no code correctly exports no functions.
- `exports no cmdlets, variables, or aliases implicitly` — **B-C1**

The other module the brief flagged. It passes `defines every function the
manifest exports` for the same vacuous reason as Az.Accounts: no exports, nothing
to find.

---

## Bucket A — the assertion is wrong, or is repo-level and was mistagged

Nothing here was changed. Collected for your decision.

### A-C1. Manifest discovery cannot find a published module

`BeforeDiscovery` accepts a `.psd1` only when its base name equals its own
directory name. The standard on-disk layout for a published module is
`<name>/<version>/<name>.psd1`, whose parent is a version number. **All eight
corpus modules fail this**, so the suite grades a target it never located.

Worse than failing: **it can succeed on the wrong module.** SqlServerDsc ships 51
manifests, one of which — a bundled helper at
`Modules/SqlServerDsc.Common/SqlServerDsc.Common.psd1` — satisfies the rule. The
suite graded that and reported 81.82% with no indication it had done so. This is
the same defect class as the original A1 (`corpus/PSCorpus` winning on path
length), which was fixed by preferring the manifest named for the repository
directory — a fix that works only when the directory *is* named for the module.

Note that the `$repoName` preference does its job once the layout is right: on the
restaged SqlServerDsc, discovery selected `SqlServerDsc.psd1` correctly despite
the 50 other candidates.

### A-C2. An empty `-ForEach` aborts the whole run

`It ... -ForEach $PublicFiles` with `$PublicFiles` empty is a container failure in
Pester 6, not zero test cases. Six of eight corpus modules have no `Public/`
directory. The result is that every assertion in the file stops, including ones
that had already passed, and the score reflects where the run died.

This is a property of running the suite against any module that is not laid out
in house style — which is precisely what `Universal` is supposed to be for.

### A-C3. `defines every function the manifest exports` ignores `.psm1`

The assertion globs `*.ps1` under the manifest's directory. Most published
modules define their exported functions in the `.psm1`: Pester's `Invoke-Pester`,
all 161 of SqlServerDsc's exports, ImportExcel's `New-Plot`. Four of the five
failures on this assertion are this and nothing else.

### A-C4. Scope-qualified function definitions are not recognised

`function Global:Write-VcsStatus` in posh-git parses to a `FunctionDefinitionAst`
whose `Name` is `Global:Write-VcsStatus`. The suite compares that against the
exported name and finds no match. Any `global:`, `script:` or `local:` prefix
defeats it.

### A-C5. `exports functions by explicit name` also demands at least one

```powershell
$ExportedFunctions | Should -Not -Contain '*'
$ExportedFunctions.Count | Should -BeGreaterThan 0
```

The first line is universal. The second is not: a rollup module (Az) and a binary
module exporting cmdlets (Az.Accounts) both legitimately export zero functions.
Two assertions share one `It`, and only one of them is true of any PowerShell
module.

### A-C6. `comment-based help` is scoped to `Public/` and is therefore not Universal

It enumerates `Public/*.ps1`. That directory is a house-style convention; a
published module has no such thing. On six of eight targets the assertion
produced **zero test cases** — it did not pass, it did not run. Under the H1
split this belongs in `Repository`, or needs rewriting against the exported
surface rather than a directory name.

Its practical confidence is three targets, and it is currently the weakest claim
carrying the `Universal` tag.

### A-C7. `declares the PowerShell editions it claims to support` errors, and may not be Universal at all

Two separate problems.

**Robustness:** when `CompatiblePSEditions` is absent the assertion does not fail,
it throws `PropertyNotFoundException` under `Set-StrictMode -Version Latest`. That
is a defect regardless of whether the rule is right.

**The rule itself:** `CompatiblePSEditions` is optional in a module manifest, and
**six of the eight corpus modules omit it** — including posh-git, the designated
control, and Pester. Three of nine targets pass.

This is the assertion with the weakest claim to `Universal` in the whole set, and
per your standing instruction it is yours to decide, not mine to weaken. I have
changed nothing.

---

## Bucket B — the assertion is right and the module genuinely violates it

### B-C1. Export keys left unset default to a wildcard

Az, Az.Accounts, ImportExcel, Crescendo. `VariablesToExport`, `CmdletsToExport`
or `AliasesToExport` absent from the manifest. PowerShell does treat an unset key
as `'*'`, so the assertion is correct and the modules do leak. Common practice in
the wild, and still a real property.

### B-C2. SqlServerDsc exports by explicit wildcard

Sets a key to `'*'` outright rather than omitting it.

### B-C3. ImportExcel lists two aliases in `FunctionsToExport`

`Export-ExcelSheet` is an `[Alias()]` on `ConvertFrom-ExcelSheet`;
`Invoke-AllTests` is an `[Alias()]` on a function in `InferData/InferData.ps1`.
Neither is a function, and both are named in `FunctionsToExport`. The assertion is
right: those names are not defined as functions anywhere.

### B-C4. ImportExcel: 47 public functions with no comment-based help

Real, and the largest single block of failures in the corpus. `Get-Help` on those
commands returns nothing useful.

---

## What I did not do

- Changed no assertion, no tag, and no corpus module.
- Committed nothing from `gallery/modules/` or `scratch/corpus-targets/`.
- Did not touch `corpus.json` or `corpus.lock.json`.
- Did not commit the probe runner. It exists only at
  `scratch/Invoke-Conformance.probe.ps1` and differs from the committed runner in
  two lines, both noted above.
