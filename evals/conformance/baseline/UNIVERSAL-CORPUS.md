# Universal, against eight dissimilar modules

Closing the loop flagged since the first baseline: `Universal` encoded one
repository's idea of universal and had been validated against exactly one
module.

Targets: the eight modules in `gallery/corpus.json`, fetched by
`gallery/fetch.ps1` and verified against `gallery/corpus.lock.json`. Nothing
from `gallery/modules/` is committed and no corpus module was modified.

**These numbers come from the committed suite**, run against
`gallery/modules/<name>/<version>/` with no restaging and no runner flags. The
first corpus pass could not do that — it needed two blockers neutralised outside
the tree — and both are now fixed.

## The gate is not met

**posh-git, the corpus control, does not pass every `Universal` assertion.** It
fails `comment-based help with a synopsis` on five exported commands:
`Expand-GitCommand`, `Get-PromptPath`, `Update-AllBranches`, `TabExpansion`,
`tgit`.

Those five failures are **genuine** — Bucket B, entry B-C6. posh-git documents
20 functions with `.SYNOPSIS` and leaves these five exported ones undocumented;
it ships no external help directory. This is not the previous situation, where
the control failed because the suite could not read a `.psm1` or a scope
qualifier. Every suite defect the control exposed has been fixed and it now
passes eight of nine assertions.

But the standing gate is that the control passes, and it does not. `Universal`
is better evidenced than it was and is **not signed off**.

## Confidence level

Nine `Universal` assertions — `CompatiblePSEditions` moved to `HouseStyle` this
pass. Nine targets: the reference plus the eight corpus modules.

| Assertion | Ran on | Passed on | Cases | Failed on |
|---|---|---|---|---|
| `exists, and its base name matches its directory` | 9 | **9** | 9 | — |
| `parses as PowerShell data` | 9 | **9** | 9 | — |
| `declares a RootModule` | 9 | **9** | 9 | — |
| `declares a ModuleVersion that parses as a version` | 9 | **9** | 9 | — |
| `declares a GUID that parses as a GUID` | 9 | **9** | 9 | — |
| `exports functions by explicit name, never by wildcard` | 9 | **9** | 9 | — |
| `defines every function the manifest exports somewhere in source` | 9 | 8 | 9 | ImportExcel |
| `exports no cmdlets, variables, or aliases implicitly` | 9 | 4 | 27 | Az, Az.Accounts, ImportExcel, Crescendo, SqlServerDsc |
| `gives <_.Name> comment-based help with a synopsis` | **7** | 4 | **312** | ImportExcel, Crescendo, posh-git |

**Seven of nine survive all nine targets**, up from five of ten. Both remaining
failures are Bucket B — real properties of those modules, recorded in
[`known-failures.json`](known-failures.json). No `Universal` assertion is now
failing for a suite reason.

The last row is where the repair shows most. It previously ran on **three**
targets and 63 cases, because it enumerated `Public/*.ps1` — a house style
directory six of the eight modules do not have. Driven by the exported surface
instead, it runs on **seven** targets and **312** cases. It does not run on Az or
Az.Accounts, which export zero functions: correctly *inapplicable*, which is not
the same as passing, and is why `CasesRun` exists.

## Scores

| Module | Role | Score | Before this pass |
|---|---|---|---|
| Pester | generated single file | **36/36 (100%)** | 9/11 |
| PSDepend | dynamic dispatch | **18/18 (100%)** | 18/19 |
| SqlServerDsc | using-module chain | **170/171 (99.42%)** | 8/11 |
| Az.Accounts | cmdlets from a binary | **9/10 (90%)** | 9/11 |
| Az | manifest only | **9/10 (90%)** | 9/11 |
| posh-git | **control** | **28/33 (84.85%)** | 9/11 |
| Crescendo | classes and enums | **7/20 (35%)** | 6/11 |
| ImportExcel | binary assemblies | **17/79 (21.52%)** | 17/67 |

The case counts moved more than the scores. SqlServerDsc went from 11 cases to
171 because its 161 exports live in a `.psm1` the suite could not previously
read; Pester from 11 to 36 for the same reason. A score computed over 11 cases
when 171 applied was not a lenient measurement, it was a different one.

Crescendo and ImportExcel fell because the help assertion now reaches their
exported surface. Both are Bucket B.

## Per module

### posh-git 1.1.0 — *control* — 28/33

- `comment-based help` × 5 — **B-C6**, genuine. See the gate note above.

Previously also failed `defines every function the manifest exports` (its
`function Global:Write-VcsStatus` was invisible to a name comparison that kept
the scope qualifier) and `CompatiblePSEditions`. Both fixed; both now pass.

### ImportExcel 7.8.10 — *binary assemblies* — 17/79

- `comment-based help` × 60 — **B-C4**, genuine. No `.SYNOPSIS`, no `en-US/`.
- `exports no cmdlets, variables, or aliases implicitly` — **B-C1**
- `defines every function the manifest exports somewhere in source` — **B-C3**.
  `Export-ExcelSheet` and `Invoke-AllTests` are `[Alias()]` names listed in
  `FunctionsToExport`. `New-Plot`, which failed for suite reasons before, now
  resolves in `ImportExcel.psm1` and passes.

Lowest score in the corpus, and every failure is real.

### Az.Accounts 5.5.2 — 9/10

- `exports no cmdlets, variables, or aliases implicitly` — **B-C1**

`exports functions by explicit name` now passes: the clause demanding at least
one exported function is gone, and a module exporting cmdlets from C# with
`FunctionsToExport = @()` is no longer failed for it. The help assertion is
inapplicable — zero exported functions, zero cases.

### Pester 5.7.1 — 36/36 — clean

`Invoke-Pester` and its siblings are defined in `Pester.psm1`, which the
definition index now reads. Previously 9/11.

### Microsoft.PowerShell.Crescendo 1.1.0 — 7/20

- `comment-based help` × 10 — **B-C5**, genuine: three `.SYNOPSIS` blocks in the
  whole module against 13 exports.
- `exports no cmdlets, variables, or aliases implicitly` × 3 — **B-C1**

### SqlServerDsc 17.5.1 — 170/171

- `exports no cmdlets, variables, or aliases implicitly` — **B-C2**

The discovery case that mattered most. Run against
`gallery/modules/SqlServerDsc/17.5.1/`, the suite now selects
`SqlServerDsc.psd1` because it sits directly in the target, rather than the
bundled `Modules/SqlServerDsc.Common/SqlServerDsc.Common.psd1` it used to pick
out of 51 candidates. All 161 exports resolve in the `.psm1` and carry help.

### PSDepend 0.5.0 — 18/18 — clean

### Az 16.2.0 — 9/10

- `exports no cmdlets, variables, or aliases implicitly` — **B-C1**

A rollup with no code. Help is inapplicable; the export-count clause is gone.

---

## Bucket A — closed this pass

All seven Bucket A findings from the first corpus pass are fixed and
re-falsified.

| | Finding | Repair |
|---|---|---|
| A-C1 | Discovery could not find `<name>/<version>/<name>.psd1`, and picked a bundled helper out of 51 candidates | Both layouts accepted; a manifest directly in the target wins; genuine ambiguity throws and names every candidate; `-ModuleName` to answer it |
| A-C2 | An empty `-ForEach` failed the whole container | `Run.FailOnNullOrEmptyForEach = $false`; `CasesRun` and an `Assertions` breakdown in `result.json` |
| A-C3 | Definition scan globbed `*.ps1`, missing every `.psm1` | One definition index over `.ps1` and `.psm1`, built once at discovery |
| A-C4 | `FunctionDefinitionAst.Name` keeps scope qualifiers | Stripped in the index and in the file-level helper |
| A-C5 | `exports by explicit name` also demanded at least one export | Clause deleted. Two claims in one `It`, one of them false |
| A-C6 | Comment-based help enumerated `Public/*.ps1` | Driven by the exported surface, resolved through the definition index; checks the named function, not the file |
| A-C7 | `CompatiblePSEditions` threw under StrictMode, and was not Universal | `ContainsKey` guard, and moved to `HouseStyle` |

## Bucket B — six, none fixed

Carried in [`known-failures.json`](known-failures.json), keyed by assertion plus
target.

- **B-C1** Export keys absent — Az, Az.Accounts, ImportExcel, Crescendo. An unset
  key defaults to `'*'`.
- **B-C2** SqlServerDsc sets an export key to `'*'` outright.
- **B-C3** ImportExcel lists two `[Alias()]` names in `FunctionsToExport`.
- **B-C4** ImportExcel: 60 exported functions with no comment-based help.
- **B-C5** Crescendo: 10 of 13 exported functions undocumented.
- **B-C6** posh-git: 5 exported functions undocumented. The control's remaining
  failure.

B-C5 and B-C6 are new — not new defects, but newly *visible*, because the help
assertion previously could not reach either module's exported surface.
