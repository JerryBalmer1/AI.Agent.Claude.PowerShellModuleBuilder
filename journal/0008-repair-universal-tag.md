---
pass: 0008
title: Repair the Universal tag against corpus evidence
date: 2026-08-28
artifacts:
  - evals/conformance/Conformance.Tests.ps1
  - evals/conformance/Invoke-Conformance.ps1
  - evals/conformance/README.md
  - evals/conformance/baseline/UNIVERSAL-CORPUS.md
  - evals/conformance/baseline/known-failures.json
  - evals/conformance/baseline/FALSIFICATION.md
  - evals/conformance/baseline/psmodulegraph-result.json
  - evals/conformance/baseline/psmodulegraph-build-result.json
  - evals/HARNESS.md
  - decisions/0001-universal-validated-against-corpus.md
---

# Pass 0008 — Repair the Universal tag against corpus evidence

## Asked

Repair the seven Bucket A findings the gallery corpus produced in Pass 3, on
decisions supplied with the prompt rather than left open. Two structural
blockers (discovery of published modules; an empty `-ForEach` failing its
container), four assertion repairs, and the conversion of the `Run.Exit`
assertion to AST after its negative control failed. Add a control for every
remaining regex assertion in `House style: build file`, converting to AST only
where the control fails. Re-measure everything, including the corpus on the
committed suite with no out-of-tree neutralisation. Add two standing rules.
Create journal and decision-record scaffolding and use it. Change no corpus
module, weaken no assertion, add no assertions beyond the repairs.

## Done

Suite, `evals/conformance/Conformance.Tests.ps1`:

- Discovery accepts `<name>/<version>/<name>.psd1` as well as
  `<name>/<name>.psd1`. Selection is by `$repoName`, then by a manifest sitting
  directly in the target, then by a single surviving candidate. More than one
  candidate with none preferred throws and names them all.
- One definition index built at discovery over `.ps1` and `.psm1`, with scope
  qualifiers stripped from `FunctionDefinitionAst.Name`. `$MissingExports` and
  `$ExportedWithSource` derive from it.
- `exports functions by explicit name` lost its `Count -gt 0` clause.
- `comment-based help` is driven by `$ExportedWithSource`, not `Public/*.ps1`,
  and checks the named function via a new `Test-FunctionSynopsis` that accepts
  help inside the function body or in a block immediately above it.
- `CompatiblePSEditions` moved from `Manifest` (Universal) to
  `House style: source layout` (HouseStyle), with a `ContainsKey` guard.
- New `Get-BuildTaskCommand`, `Get-BuildTaskBody`, `Get-ConfigAssignment`
  helpers. Six assertions in `House style: build file` converted from regex to
  AST: `Run.Throw`/`Run.Exit`, task declarations, the default task,
  `Filter.ExcludeTag`, `Should.DisableV5`, `CodeCoverage.Path`. The coverage
  assertion moved onto the shared helper.

Runner, `evals/conformance/Invoke-Conformance.ps1`: `-ModuleName` passed through
as `$env:CONFORMANCE_MODULE_NAME`; `Run.FailOnNullOrEmptyForEach = $false`;
`CasesRun` and a per-assertion `Assertions` breakdown in `result.json`, keyed by
unexpanded test path.

Records: `README.md` gains standing rules 9 and 10 and a rewritten known-limits
section. `baseline/UNIVERSAL-CORPUS.md` rewritten against committed-suite
numbers. `baseline/known-failures.json` created — ten entries, six distinct
Bucket B findings across five targets. `baseline/FALSIFICATION.md` gains the
I3b rows. `evals/HARNESS.md` unchanged this pass.

Scaffolding: `journal/TEMPLATE.md`, this entry,
`decisions/0001-universal-validated-against-corpus.md`.

## Why

The four assertion repairs were decided in the prompt, not here. Where judgement
was exercised:

- **Discovery prefers a manifest sitting directly in the target** over any
  other tie-break. Rejected: preferring the shallowest path, which is what
  produced the SqlServerDsc misgrade; and preferring the version-directory
  layout specifically, which would not generalise. "The manifest at the root of
  the thing you pointed me at" is the rule that resolves both layouts without
  ranking them.
- **Zero candidates does not throw; more than one undecidable candidate does.**
  Absence is not ambiguity — the `Manifest` assertion exists to report absence,
  and making discovery throw would replace a clean failure with an aborted run.
- **All five remaining regex assertions were converted**, though all five passed
  the control the prompt specified. The specified control — a comment mentioning
  the setting, no code changed — cannot fail for a positive assertion whose code
  is still present. The probe that discriminates is the mirror: delete the code
  and leave the comment. All five stayed green under that, which is the coverage
  assertion's original defect exactly. Converting on the letter of the control
  would have left five inert-on-deletion assertions in place.
- **The coverage assertion was refactored onto the shared helper** despite being
  proven. Rejected: leaving a second inline copy of the task-body search. The
  duplication would have been ~20 lines and the falsification re-run covers the
  change.
- **`Test-FunctionSynopsis` accepts help above or inside the function.** The
  reference writes it inside; posh-git writes it above. Rejected: a file-level
  check, which is what the old assertion did and what makes a 5,000-line
  generated `.psm1` look documented because one of its functions is.

## Measured

Reference, `baseline/psmodulegraph-result.json` and
`psmodulegraph-build-result.json`:

- `Universal,Repository,HouseStyle`: 74/75, 98.67% — unchanged across the pass.
- all four tags: 80/81, 98.77% — unchanged.
- `Universal` alone: 25/25, 9 assertions. Was 26 tests over 10 assertions;
  `CompatiblePSEditions` moved to HouseStyle.

Falsification, `baseline/FALSIFICATION.md`: 14 breaks fire, 12 controls stay
green, 5 substitution probes fire after conversion (all 5 failed before it).
`ctl-run-throw`, the control that failed in Pass 3, now passes.

Corpus on the committed suite, `baseline/UNIVERSAL-CORPUS.md`:

| Module | Score | Prior |
|---|---|---|
| Pester | 36/36 | 9/11 |
| PSDepend | 18/18 | 18/19 |
| SqlServerDsc | 170/171 | 8/11 |
| Az.Accounts | 9/10 | 9/11 |
| Az | 9/10 | 9/11 |
| posh-git | 28/33 | 9/11 |
| Crescendo | 7/20 | 6/11 |
| ImportExcel | 17/79 | 17/67 |

Seven of nine `Universal` assertions survive all nine targets, up from five of
ten. The comment-based-help assertion runs on 7 targets and 312 cases, up from 3
targets and 63.

## Learned

- **The prescribed control was the weaker of the two probes.** A comment
  mentioning a setting cannot break a positive assertion while the setting is
  still there. Five assertions passed that control and failed the deletion
  probe. A control is only discriminating if the thing it perturbs is the thing
  the assertion is supposed to depend on.
- **Fixing the suite changed the denominator, not just the score.** SqlServerDsc
  went from 11 cases to 171 and PSDepend from 19 to 18. A score computed over 11
  cases when 171 applied was not lenient, it was measuring something else.
  Comparing the before and after scores as though they were the same
  measurement would be wrong.
- **A stale expectation in the falsification driver read as a real defect.**
  `strip-synopsis` reported DOES NOT FIRE with the correct red listed as
  collateral, because the driver still expected the old test name
  (`Get-PSModuleEnum.ps1`) after the assertion became keyed by function name.
  The assertion was fine; the harness's idea of it was not. An assertion
  renamed by a repair invalidates every recorded expectation naming it.
- **The gate was not met.** posh-git fails comment-based help on five exported
  commands. The failures are genuine (B-C6), and every suite defect the control
  previously exposed is fixed — but the standing instruction is that the control
  passes, and it does not.

## Capability

- The suite can grade a published module — `<name>/<version>/<name>.psd1` — and
  not only a source tree.
- It can grade a module whose functions are defined in a `.psm1`, or with a
  scope qualifier, both of which were previously invisible.
- It refuses to grade when it cannot tell which module it is looking at, and
  `-ModuleName` can answer that.
- It reports how many cases an assertion actually ran (`CasesRun`, `Assertions`),
  so an assertion that did not apply is distinguishable from one that passed.
- Comment-based help can be checked per exported command wherever it is defined,
  rather than per file in a `Public/` directory.
- Every assertion in `House style: build file` distinguishes a comment from code
  in both directions.
- Expected failures are declared in `known-failures.json`, keyed by assertion
  plus target, so a new failure is separable from a known one.
