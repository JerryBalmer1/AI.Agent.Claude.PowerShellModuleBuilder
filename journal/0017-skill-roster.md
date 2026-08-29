---
pass: 0017
title: Name the skills, build the ordered runner, pay the tag debt
date: 2026-08-29
artifacts:
  - plans/0017-skill-roster/plan.md
  - plans/0017-skill-roster/verify.ps1
  - plans/0017-skill-roster/accept.Tests.ps1
  - plans/0017-skill-roster/ordered-run-demo.txt
  - decisions/0006-target-versioning-and-tags.md
  - decisions/0007-skill-taxonomy-and-naming.md
  - skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1
  - evals/conformance/Invoke-Conformance.ps1
  - evals/conformance/README.md
---

# Pass 0017 — Name the skills, build the ordered runner, pay the tag debt

## Asked

Four things. Rename the five existing skills to a scope-carrying convention
(`powershell-module-<role>` for the generic, `azdo-<role>` for the target) and
grow the set to thirteen, distilling the roster out of the PSModuleGraph
reference and the conformance suite. Ship `Invoke-OrderedTests.ps1`: layered
dependency-ordered test execution that stops at the first failing layer and
prints only that layer's failures. Fix run 002's findings F-8 — conformance
discovery cannot name the module in a run directory — and the README layout it
compounds with. And pay a standing debt: annotated tag `v0.1.0` on
PSAzureDevOpsGraph's `run-002-first-build`, plus the two decision records that
authorise it and record the naming rule.

Full tier: preconditions, red-first acceptance, per-task evidence, verify
script, deviations.

## Done

- **Tagged** `PSAzureDevOpsGraph` `v0.1.0` (annotated) at
  `79e02fba9dffd976bccf507d531f59303cc58f9d` and pushed it. No commit, no
  branch, nothing else touched on that remote.
- **`decisions/0006-target-versioning-and-tags.md`** and
  **`decisions/0007-skill-taxonomy-and-naming.md`**, both verbatim from the
  prompt.
- **Renamed four skills** with `git mv`, so history follows:
  `module-scaffold`→`powershell-module-scaffold`,
  `build-script`→`powershell-module-build`,
  `pipeline-yaml-refs`→`azdo-pipeline-yaml-refs`,
  `graph-assembly`→`azdo-graph-assembly`. References updated in all five
  original `SKILL.md` files and `commands/build.md`.
- **Eight new skills**: `powershell-module-test`, `-deploy`, `-release`,
  `-architect`, `-analyzer`, `-plan`, `-docs`, and `task-tree-reporting`.
- **`skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1`**, 518
  lines: five layers (`manifest-parses`, `files-parse`, `module-imports`,
  `unit`, `integration`), stop at the first failure, `STOPPED AT LAYER <name>`
  plus only that layer's failures, `INAPPLICABLE` kept distinct from `PASSED`.
- **`skills/powershell-module-plan/templates/module-plan.md`**, whose
  definition-of-done section is mandatory and red-first.
- **Extended `powershell-module-build`** with the `ParseError` severity rule,
  the coverage gate reading its own declared threshold, task ordering, and
  exit-code discipline.
- **`evals/conformance/Invoke-Conformance.ps1`**: `-ModuleName` defaults from
  `src/<Name>/<Name>.psd1` when the suite's own two rules cannot fire.
  `Conformance.Tests.ps1` untouched.
- **`evals/conformance/README.md`**: corrected the run-directory path it
  documented, which `Reset-Target.ps1` cannot produce.
- **`README.md`**: a `## The skills` roster table and the `Layout` row.
- Plan, verify script, acceptance test, demo transcript, this entry.

## Why

**The derivation for F-8 is a rule, not a fallback, and that distinction is the
whole design.** The suite deliberately has no third discovery rule: "if exactly
one candidate survives, take it" once graded a vendored `corpus/PSCorpus`
module, silently, after the reference's own manifest was deleted. Reinstating
that would reopen the exact defect the no-guess rule exists for. So the new rule
is *exactly one candidate manifest under `<target>/src/`* — a positive claim
about a location the scaffold mandates and the suite grades — and it is tried
**last**, only after both existing rules have failed. It lives in the runner,
not in `Conformance.Tests.ps1`, so the oracle is unchanged.

**Rejected: putting the derivation in `Conformance.Tests.ps1`.** It would have
been fewer lines and it would have meant this pass editing the assertions it is
graded by.

**Rejected: fixing F-8 in `Reset-Target.ps1` instead**, by having it create
`<destination>/<ModuleName>/`. The finding named both options. The runner is the
right place because the problem is discovery, not layout — and a run directory
is not the only target that fires neither rule.

**Rejected for the ordered runner: making the build a sixth layer.** Building is
not a check; it is what makes the next check possible. As a layer it would
report a parse error as a build failure, which is the cascade the runner exists
to prevent. It sits between layers 2 and 3, unnumbered, behind an explicit
`-Build`.

**Rejected: importing the module in-process.** Layer 3 is the first that
executes the target's own code — its top level, its `ScriptsToProcess`, its
class static constructors. A failure there would contaminate every layer after
it, so it runs in a child `pwsh`.

**Rejected: treating an empty integration layer as a pass.** Zero cases is not a
pass; it is `INAPPLICABLE`, reported distinctly and named in the summary.

**Rejected for `task-tree-reporting`: colour.** The tree has to survive being
pasted into a plan, committed, and read in a diff. A status legible only because
it is green is illegible everywhere the record actually lives.

## Measured

| Claim | Number | Artifact |
|---|---|---|
| Acceptance, before any work | 0 passed / 7 failed | `plans/0017-skill-roster/plan.md` §4 |
| Acceptance, after | 7 passed / 0 failed | `plans/0017-skill-roster/plan.md` §6 |
| Conformance on a run directory, **before** F-8 fix, no `-ModuleName` | 6 / 30 cases run, 24 assertions | plan §5 task 6 |
| Same target, **after**, no `-ModuleName` | 51 / 51 cases run, 27 assertions | plan §5 task 6 |
| Same target, **after**, explicit `-ModuleName` | 51 / 51 cases run, 27 assertions | plan §5 task 6 |
| Derived vs explicit | `Passed`, `Failed`, `CasesRun`, `ScorePct` equal; 27-entry `Assertions` breakdown byte-identical | plan §5 task 6 |
| Reference control, old runner | 74 / 75 cases run, 27 assertions | plan §5 task 6 |
| Reference control, new runner | 74 / 75 cases run, 27 assertions — identical | plan §5 task 6 |
| Reference with its own manifest deleted | 2 / 10, reports a missing manifest; did **not** grade `corpus/PSCorpus` | plan §5 task 6 |
| Ordered run, pristine run-002 clone | 4 layers passed, 1 inapplicable; 17 files parsed, 37 unit cases; exit 0 | `ordered-run-demo.txt` |
| Ordered run, one parse error | stopped at `files-parse`; 1 file named, 2 diagnostics, 0 downstream lines; exit 1 | `ordered-run-demo.txt` |
| `evals/` diff for this pass | exactly 2 files, +99 −1 | plan §5 task 6 |
| Credential scan across every artifact | 0 matches, including a direct search for the live `$env:AZDO_PAT` value | plan §5 task 9 |
| `verify.ps1` | 66 checks, 0 failures, 0 skipped | plan §8 |
| `verify.ps1 -FailCheck` | 75 checks, 0 failures, 0 skipped; every probe re-runs its check and restores | plan §8 |

Cases-run is stated on both sides of every conformance comparison. The F-8
repair changes the denominator — 30 to 51 — so the two percentages are not two
measurements of the same thing, and the raw counts are what carry the claim.

## Learned

**The acceptance test the prompt supplied could not pass, and the reference had
already documented why.** `git ls-remote` matches a pattern against the tail of
the ref name, so `--tags <url> v0.1.0` returns only the tag object and never
`refs/tags/v0.1.0^{}` — neither alternative in the supplied regex can appear.
And `Should -Match` tests each element of a piped array, so even with both lines
returned the tag-object line fails it. Two compounding defects, and the test was
red for a correct tag. PSModuleGraph's own `tests/PreTag.Tests.ps1` carries a
comment beginning *"THREE patterns, and no `--tags`"* explaining exactly this. I
had read that file for extraction earlier in the same pass and did not connect
it until the test went red. Corrected minimally, regex untouched, and the
correction itself falsified against a non-existent tag.

**A finding's remedy can be recorded as applied and not be applied.** Run 002's
F-3 says of the `ParseError` severity fix: *"Remedy — skill, and it is already
applied."* The **target** carries the fix; the **skill** never did. `build-script`
had no mention of `ParseError` at all before this pass. A remedy written in
past tense in a findings document is a claim, and this one was wrong for a pass
and a half.

**My prediction about the contrast case was wrong, in the useful direction.** I
expected `./build.ps1` on a sabotaged run-002 tree to produce F-3's wall of red.
It does not — run 002 already carries the `ParseError` fix, so `Lint` correctly
goes red. The real contrast is narrower: the build's 18 lines name three files
and **none of them is the broken one**, while the findings table the `Lint` task
writes never reaches the captured stream. The honest version is a weaker claim
and is in the plan; the version I expected would have been a better story and
untrue.

**The prompt's roster count disagrees with its own lists.** Spot-check 1 says
"the nine roster paths"; the acceptance test checks thirteen. I built thirteen
and made `verify.ps1` assert `skills/` holds *exactly* those thirteen, so a
leftover directory fails as loudly as a missing one.

**"Extracted from PSModuleGraph's test infrastructure" overstates what was
there.** There is no ordered runner in the reference. What exists is the
InvokeBuild task graph's ordering, the `PreTag` tag split, the
`tests/Public`/`tests/Private` mirror, and two documented instances of the
cascade — a `BeforeAll` failure surfacing as an unrelated `break`/`continue`
message, and F-3's nine downstream import errors. The runner is distilled from
those. Recorded in the plan's Deviations, item by item, including what I read,
wanted, and deliberately left out.

**Two documents in this repository now carry statements this pass made false**
— the root `README.md`'s "`-ModuleName` is not optional when the repository root
is a run directory", and the same guidance in `commands/test.md`. The prompt
scoped me out of both. Flagged rather than silently fixed or silently ignored.

**A check can report a disagreement it cannot name, and that is the tell.** The
first roster evaluator in `verify.ps1` ended `, $problems`. The unary comma
wraps the array, so an empty result arrived as one element that was an empty
array: the check reported `1 disagreement(s)` and then printed a blank line
where the name should have been. It was caught by strengthening the `-FailCheck`
probes to re-run the check rather than restate the sabotage — the first run of
those probes reported a failing **baseline**, and a baseline that fails before
any break is a broken probe, not a broken repository. This failed toward the
alarming answer. The same bug with reversed polarity would have been a check
that could not go red, which is the defect this repository exists to find and
would not have announced itself.

**The standing rules are numbered inconsistently in committed artifacts.**
"Rule 9" means *mechanism selection* in `runs/002-first-build/findings.md` and in
this pass's decision 0007, and *zero cases is not a pass* in `decisions/0001`
and `journal/0007`. No committed file numbers the rules, so neither usage can be
checked against anything.

## Capability

The plugin can now be **asked for a role rather than a file**. Thirteen skills
name the lifecycle — plan, architect, scaffold, build, test, analyze, document,
deploy, release — so a request that spans several loads only the ones it needs,
and the name says whether a skill is generic to PowerShell or specific to the
Azure DevOps target.

A module repository can now be **tested in dependency order from one command**,
so a single defect reports as one file and one line instead of as a wall of
downstream failures. `Invoke-OrderedTests.ps1` runs against any repository
laid out to the scaffold, needs no configuration, and distinguishes a layer that
graded nothing from a layer that passed.

The conformance suite can now **grade a run directory without being told the
module name**, which removes the mandatory `-ModuleName` from every scored run,
while still refusing — loudly, naming every candidate — to guess when the answer
is genuinely undecidable.

`PSAzureDevOpsGraph` now has a **version line**: `v0.1.0` on the remote, peeling
to run 002's commit, carrying its three scores in the tag message, with the rule
for the next one written down.
