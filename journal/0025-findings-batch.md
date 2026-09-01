---
pass: 0025
title: Turn a run's findings into the plugin, repair the case nobody could pass, and give the score a denominator that holds still
date: 2026-08-31
artifacts:
  - plans/0025-findings-batch/plan.md
  - plans/0025-findings-batch/accept.Tests.ps1
  - plans/0025-findings-batch/verify.ps1
  - plans/0025-findings-batch/mutations.txt
  - plans/0025-findings-batch/readback.txt
  - plans/0025-findings-batch/denominator.txt
  - decisions/0012-fixture-case3-repair.md
  - runs/tf-002-convention-and-case3/README.md
  - runs/tf-002-convention-and-case3/findings.md
  - skills/producer-contract/SKILL.md
  - evals/tf/Invoke-TfOracleFalsification.ps1
  - evals/tf/Update-TfFixture.ps1
  - evals/tf/Test-TfFixtureCase.ps1
  - LEDGER.md
---

# Pass 0025 — Findings into the plugin, and a score with a stable denominator

## Asked

Take run tf-001's findings and land them: repair the fixture case no parser
could pass, fix the two producer defects the run recorded but could not fix,
re-score as tf-002, fold four findings into skills, give the conformance suite a
denominator that does not move with the target's shape, and start a LEDGER.

## Done

```
functional-tf:  6 / 7  ->  7 / 7
differences:    31     ->  0
oracle:         78 nodes, 57 edges  ->  78 nodes, 59 edges
PSTerraformGraph:                      v0.1.0 -> v0.2.0
skills:                                13 -> 14
```

All 31 of tf-001's remaining differences are accounted for, and they were three
different kinds of thing:

- **28** were one convention — the producer wrote `hasValidation: false` where
  the oracle said nothing. The contract says an absent optional field means NOT
  STATED, so the oracle was right. One line of code.
- **2** were a fixture case that no implementation could pass: case 3's
  cross-repository tie existed only in a variable's *description string*. Prose.
  Repaired under decision 0012, the one amendment decision 0011 provides for.
- **1** was the actual bug. `module.subnet[*].id` — the reference pattern
  matched the module name and lost the member, so the reference resolved to no
  output and the edge vanished in silence.

## What this pass is actually about

**The smallest number on the page was the only real defect.**

That is the finding, and it generalised into the pass's one new skill. A count of
31 invites starting with the group of 28. The group of 28 was a convention
mismatch between two documents; the group of 2 was a broken instrument; the group
of 1 was the code being wrong. Group by mechanism before reading the number, and
then read the group of one.

The corollary is uncomfortable and is written into the tf-002 record: a run that
scores 0 tests *less* than a run that scores 31. tf-002 iterated zero times
because the first score was perfect, which proves the fixes were right and proves
nothing about whether the harness would have caught them had they been wrong. The
comparator's re-falsification against the **amended** oracle is what carries that
claim — seven mutations, seven mechanisms, control at zero — and it was not a
formality, because the oracle changed and the previous falsification did not
transfer with it.

## Three gates that had never been able to fail

None of these came from the fixture. All three came from running something
nobody had run.

**PSTerraformGraph's `PreTag` task had no PreTag-tagged test.** Declared from
v0.1.0, so `-Task PreTag` could only ever throw its own guard — *"the PreTag
filter selected no test at all"* — and v0.1.0 was tagged without the gate that
seals a tag ever having run. Found only because this pass tried to run it. The
conformance suite could not have caught it: it asserts the task is *declared* and
that the default excludes PreTag-tagged tests, and both were true the whole time.
**An assertion about a declaration is not an assertion about the thing declared.**

**A test that passed vacuously.** The first `hasValidation` assertion reached for
`PSObject.Properties.Name` on a hashtable — which lists `Count` and `Keys` and
never the keys — and went green against a producer still writing the field.

**A loop variable that was silently a parameter.** `foreach ($tag in $Tag)`:
PowerShell names are case-insensitive, so `$tag` *is* `$Tag`, and the loop
rebound the parameter to its last element. Every tag but one stopped being
selected; the run reported 17 cases instead of 57 and read exactly like a Pester
filter bug. No analyzer catches it. What caught it was that the falsification had
a **predicted number** — 57 and 55, from the committed records of runs 002 and
003 — and 17 was not it. A control with an expected value catches what a control
with a green light does not.

## The denominator

`CasesRun` depends on the shape of the target: an `It` with `-ForEach` over the
public functions makes seven cases against a module with seven commands and two
against a module with two. Runs 002 and 003 are two builds of the *same* module
and reported 57 and 55. The denominator was moving underneath the score, so
57/57 and 39/55 were never two points on one scale.

`CasesDefined` is parsed out of the suite's own source by AST. The target is
never consulted — no file of it read, no `-ForEach` expanded — which is exactly
why it cannot move with the target. Three differently shaped targets: 33, 33, 33,
with cases-run 57, 55 and 41. And the control the other way, because a number
that never moves is stable and useless: it tracks the tag *selection* — 9, 23,
33.

Reporting only. Nothing was weakened, nothing skipped, and the two
PSAzureDevOpsGraph rows reproduce the committed results of runs 002 and 003
exactly.

## What was deliberately not done

**The three `tf-<role>` skills tf-001 proposed were not written**, and this is
the pass's largest judgment call.

They would carry this fixture's specific answers. tf-003 is meant to be the
blind measurement against that same fixture. Writing them first and then scoring
measures the plugin's memory of tf-001 rather than its generality — run 002's
record already carries that caveat once, about a builder who read the cases, and
this would make it permanent.

The knowledge is in PSTerraformGraph's worklogs, where a module's reasoning about
its own domain belongs. It is LEDGER backlog item 9, with the two clean orders:
after tf-003, or against a second fixture the skills were not written against.
**Recorded, not taken. The operator should overrule it if the intent was to
ship them.**

Also recorded and not fixed: `Export-TfConfigurationGraphHtml` is exported and no
test invokes it — PSTerraformGraph scores conformance **40/41** on that
assertion, found while using it as a third denominator target. v0.2.0 was already
tagged and pushed, and fixing it means rewriting a pushed tag or landing on
`main` past the tag it follows. Both are worse than a recorded gap. Backlog item
8.

The shape is worth sitting with: three green numbers — 7/7 functional, 7/7
battery, 0 differences — on a module half of whose public surface no test calls.
Scores measure what they measure.

## The fixture is frozen again

Amended exactly once, by decision 0012, in one commit on one repository:
`TfFixtureApp` at `44ea933…`. The other two are untouched at their original SHAs.
Byte read-back reads `BYTE-IDENTICAL`, and `verify.ps1` re-asserts all three
against the AzDO API rather than against this document.

**Azure DevOps objects created or modified: 1. Builds queued: 0**, confirmed by
reading the builds API rather than by asserting it. `ClaudeTesting` was not
touched.

## Cost

Roughly 2 hours 20 minutes. 21 verify checks, 0 failed, 0 skipped. 11 gate
falsification probes across two suites, every one of which broke something,
proved the break landed, and drove its check red.
