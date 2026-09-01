# Findings — run tf-002

tf-001's findings were about a module being built for the first time. These are
about what shows up once the score is at the top: what a 0 stops being able to
tell you, and three gaps found by looking at things nobody was scoring.

## A. What a perfect score does not say

### A-1. 0 differences and 7/7, and the run tests less than tf-001 did

tf-001 took three iterations to reach 31 differences. tf-002 took none: the
first score was 0. That is the right outcome and it is worth being precise about
what it establishes.

**It proves the two fixes were right.** It does not prove the harness would have
caught them had they been wrong, because nothing was wrong for it to catch. A
scoring run only demonstrates the instrument when the instrument disagrees with
something.

What carries that claim instead is the comparator's re-falsification against the
**amended** oracle: seven mutations, seven detected as seven distinct
mechanisms, control at zero. The oracle changed, so the previous falsification
did not transfer, and re-running it was not a formality.

The same logic put `evals/tf/Test-TfFixtureCase.ps1` under a control. Scoring
7/7 against the graph it was written beside proves nothing; scoring **6/7
against run tf-001's committed graph, failing exactly case 3**, proves it can
disagree.

### A-2. The single difference was the real defect

tf-001's 31 differences: 28 were one convention, 2 were a broken fixture case,
and **1 was a genuine bug in the producer**. The bug was the smallest number on
the page, and the two big numbers were both about the measuring apparatus rather
than the thing measured.

Generalised into `skills/producer-contract`, because the instinct a large count
produces — start with the biggest group — is exactly backwards for finding
defects. Group by mechanism first. Then read the group of one.

## B. Three gaps found by looking where nothing was scoring

None of these came from the fixture. All three came from running something that
had never been run.

### B-1. `PreTag` was a gate in name only, in the module about to be tagged

PSTerraformGraph's build declared a `PreTag` task from v0.1.0 and the repository
had **no PreTag-tagged test**. `./build.ps1 -Task PreTag` could only ever throw
its own guard — *"The PreTag filter selected no test at all"*. v0.1.0 was tagged
without the gate that seals a tag ever having run, and it was found only because
this pass tried to run it before tagging v0.2.0.

**The conformance suite could not have caught it.** It asserts that the build
file declares the task, and that the default `Test` task excludes PreTag-tagged
tests. Both were true the whole time. Nothing anywhere asserts that a
PreTag-tagged test *exists*.

That is a general shape worth naming: **an assertion about a declaration is not
an assertion about the thing declared.** Written into
`skills/powershell-module-build`, and eight PreTag assertions were added to
PSTerraformGraph — each broken on purpose and confirmed red before being
trusted.

### B-2. `Export-TfConfigurationGraphHtml` is exported and no test invokes it

Found while using PSTerraformGraph as a third target for the conformance
denominator falsification — a use nobody intended as a check on it.
**Conformance 40/41**, the one failure being `Repository shape.exercises the
exported command Export-TfConfigurationGraphHtml somewhere in tests`.

Half the module's public surface has no test that calls it. The battery grades
the *graph*; the module's own tests grade `Get-TfConfigurationGraph`; the HTML
export is exercised by the harness during a scoring run and by nothing that runs
in its own build.

**Not fixed, and the reason is a rule rather than a shortage of time.** v0.2.0
was already tagged and pushed when this was found. Fixing it means either
rewriting a pushed tag, which this project does not do, or landing a commit on
`main` past the tag it is supposed to follow (decision 0008). Both are worse
than a recorded gap. It is in the LEDGER backlog and belongs to the pass that
next opens that repository.

Worth noting the shape: the module was scored 7/7 functionally and 7/7 on the
battery in the same pass in which half its commands turned out to be untested.
Three green numbers and a hole underneath them.

### B-3. A loop variable that was silently the parameter

The first version of the denominator work iterated `foreach ($tag in $Tag)`.
PowerShell variable names are case-insensitive, so **`$tag` *is* `$Tag`**: the
loop rebound the parameter to its last element, and every tag but one stopped
being selected. The run reported 17 cases instead of 57 and read exactly like a
filter bug in Pester.

No analyzer rule catches it. What caught it was that the falsification had a
predicted number — 57 and 55 from the committed run records — and 17 was not it.
**A control with an expected value catches things a control with a green light
does not.**

## C. The findings from tf-001 that did not become a skill, and why

tf-001 proposed three `tf-<role>` skills: `tf-hcl-parse`, `tf-module-resolve`,
`tf-graph-assembly`. **None was written, deliberately.**

They would carry the answers to this fixture. `required_providers` is both a
block and an attribute; a registry address and `./modules/child` are the same
shape to a naive pattern; the parser spaces out an expression. Those are real
and hard-won, and they are also **precisely the answers a future Terraform build
would be scored on against the same fixture.**

The harness has one Terraform measurement instrument. tf-003 is meant to be the
blind, measured run — the one that asks whether the plugin helps an agent build
a module it has not seen the answers to. Writing this fixture's specific defects
into skills, and then scoring against this fixture, measures the plugin's memory
of tf-001 rather than its generality. Run 002's record already carries that
caveat once, about a builder who read the cases; this would bake it in
permanently.

The knowledge is not lost. It is in PSTerraformGraph's `docs/worklog/v0.1.0.md`
and `v0.2.0.md`, where it belongs — a module's own reasoning about its own
domain, readable by anyone working on that module, and not loaded into the
plugin that is supposed to be measured against it.

**This is an operator decision and it is only being recorded, not taken.** If
the three skills are wanted, the cleanest order is: build a second Terraform
fixture the skills were not written against, or write them after tf-003 has
taken its blind measurement. It is in the LEDGER backlog.

The other tf-001 findings all landed:

| Finding | Where it went |
| --- | --- |
| A-1 dev loader | `powershell-module-scaffold`; verified against ToHtml and PSTerraformGraph, pending in PSGraphRender's HANDOFF |
| A-2 dependency resolver | `powershell-module-build`, parameterised on the dependency name |
| A-3 producer with a contract | new `skills/producer-contract` |
| A-4 singular nouns | `powershell-module-build`, with the suppression-comment format |
| B-1, B-2, B-3 tf-* skills | **not written** — see above |
| C-1 case 3 | decision 0012, fixture amended once and re-frozen |
| C-2 `hasValidation` | producer fixed; the rule generalised into `producer-contract` |
| D-1 splat | producer fixed; it was the 31st difference |

## D. One thing the fixture now tests that it did not

Case 3's repair added a `git::` source with **no `//subdirectory`**, which is
what names a repository's root module. Case 2 exercises only the subdirectory
form.

`Resolve-TfModuleSource` already handled it — the search for `//` past the
scheme returns -1 and the subpath falls back to `.` — written in v0.1.0 because
it was the correct reading of the syntax, and tested by nothing.

It is the only part of v0.2.0 that was right by construction rather than by
correction, and that is not a virtue: untested correct code is luck that
happened to hold. The case exists now.
