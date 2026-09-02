# 0014 — A second Terraform fixture, written mute

Operator-directed, executed in pass 0034. Decision 0011 froze the Terraform
fixture; decision 0012 amended it once, for case 3, and re-froze it. This
decision does not touch either. It adds a **second** fixture, and it says which
of the two each future question is asked of.

## What pass 0033 found

Pass 0033 applied hazard 13 — *the live fixture carries case-annotated comments*
— to the Terraform line for the first time. It read all 40 files of
`evals/tf/fixture/repos/`: every comment, every `description` string, every
README, against `evals/tf/fixture/cases.md`, which is the oracle's own case list.

**The verdict was not clean, and it was worse than the AzDO fixture on this
vector.** The full scan is
[`plans/0033-honest-headline/tf-fixture-comments.txt`](../plans/0033-honest-headline/tf-fixture-comments.txt).
Four findings carry this decision:

1. **A comment naming a case by number, and the decision that amended it.**
   `TfFixtureApp/main.tf:20-24` reads *"Case 3, the cross-repository output
   reference. The tie is the module "network" block below … see decision 0012."*

2. **A README pointing at the oracle by path.**
   `TfFixtureShared/README.md:4-5` tells any reader to *"see
   `evals/tf/fixture/cases.md` in the harness for what each part is a case
   for."* That document holds the case list, the node-id scheme, the edge kinds
   and the exact counts.

3. **The absence case, with its wrong answer spelled out.**
   `TfFixtureShared/variables.tf:25` gives a variable the description *"Declared
   and referenced by nothing. The absence case: a graph that invents a reference
   for this is wrong."*

4. **The dependency chain drawn as a numbered arrow diagram.**
   `TfFixtureApp/main.tf:5` draws
   `var.tags -> local.merged_tags -> module.service.tags -> module.worker.tags`
   in a comment on the file a builder opens first, and then numbers each link at
   the site where it occurs — *"Link one."*, *"Link two."*, *"Link three:"*,
   *"Link four."*

A builder reading that fixture — which every protocol requires it to do — is
told which cases exist, what each is for, what the wrong answer looks like, and
where the answer sheet lives.

## What this decision settles

### Fixture 1 stays frozen, and stays annotated

**Nothing under `evals/tf/fixture/` is amended, now or by this decision.**

Runs tf-001 and tf-002 were both scored against the annotated form. Stripping
the comments would change the instrument between tf-002 and tf-003 and make the
three incomparable — the same argument that kept `ClaudeTesting` intact under
hazard 13, and the same one decision 0011 was written to enforce. The fixture is
also authored here and *published* to AzDO, so an edit is a push to three frozen
repositories rather than a local change.

**The bound is disclosed, not repaired.** tf-001's and tf-002's records keep
their numbers and gain the caveat that the fixture named its own cases. That is
a permanent asterisk on those two runs and this decision accepts it, because
those two runs are not the generalisation measurement.

### Fixture 2 is built unannotated, and the gate is standing

Three new repositories — `TfSiteCore`, `TfSiteEdge`, `TfSiteOps` — in the same
AzDO project, authored at `evals/tf/fixture2/repos/`, exercising the **same
seven mechanism classes** on a different surface everywhere: four-level nesting
instead of three, a diamond in which a module's parent is not either of its
callers, two unresolved sources of two different shapes instead of one, a
different provider mix, a different vocabulary, different pins.

**Sanitization is a design rule, not a cleanup.** No comment, string,
identifier, README line **or commit message** may name a case, name the oracle,
describe presence or absence as a case, use the word *graph*, or point into the
harness. Each repository's README describes the module as a module.

The rule is enforced by `evals/tf/Test-FixtureSanitization.ps1`, which is pass
0033's hand-reading promoted to something anyone can re-run. It is a **standing
gate**, not a one-off: it runs against the fixture-2 source and against fresh
clones, it has a `-FailCheck` that plants a banned comment and requires the
catch, and it reports **94 findings against fixture 1** — the same annotations
0033 found by hand. A scanner that says *clean* about one fixture and *94* about
the other is discriminating between fixtures, not between a planted line and
nothing.

Commit messages are in scope deliberately. A repository whose files say nothing
and whose first commit says *"Terraform fixture for PSTerraformGraph scoring"*
has leaked the same thing one `git log` later.

### Which fixture answers which question

- **Measurement runs — tf-003 and everything after — target fixture 2.** It is
  the only Terraform instrument this project has that a builder has not been
  told the answers to.
- **Fixture 1 remains the deliverable-line example.** It is what
  PSTerraformGraph's own tests, worklogs and documentation are written against,
  it is what tf-001 and tf-002 measured, and it stays exactly where it is. Its
  annotations are a liability for measurement and an asset for a reader learning
  what the cases are.

Fixture 2's case knowledge lives in `evals/tf/fixture2/cases.md` and in the
oracle beside it, and nowhere else. **If writing a fixture file ever seems to
require explaining a case, the explanation goes in `cases.md`.**

### This unblocks the `tf-<role>` skills

Backlog item 9 recorded that the three skills tf-001 proposed were deliberately
not written, because they would carry fixture 1's specific answers into a plugin
that was about to be scored against fixture 1.

**That objection does not apply to fixture 2, and the reason is a fact about
time rather than an argument.** Fixture 2 was authored in pass 0034, after
tf-001 and tf-002 were run and after their findings were written down. Nothing
that produced those findings has ever seen it. Skills grounded in fixture 1's
lessons therefore encode *what parsing Terraform is like*, not *what this
fixture's answers are* — and tf-003 measures them against a configuration none
of them was written against.

The skills land in this pass, and it is why pass 0034 releases: they are
installed surface.

## Alternatives rejected

**(a) Run tf-003 against the frozen fixture and disclose the bound.** The
cheapest option, and comparable with tf-001 and tf-002. Rejected because the
resulting number would measure *can it parse Terraform* far more than *can it
generalise*, and would carry that asterisk permanently. The one measurement the
project has queued is the generalisation claim; spending it on a fixture that
labels its own cases spends it on nothing.

**(b) A new decision unfreezing fixture 1 to strip the annotations, with a
re-falsification and a re-freeze, as decision 0012 did.** Rejected because it
destroys the referent tf-001 and tf-002 were scored against. Two runs would keep
their numbers while the thing they were numbers *about* had changed underneath
them, and no later reader could tell. Decision 0012's amendment was justified by
a case no implementation could pass; comments a builder can read are not that.

**(c) A second unannotated fixture.** Taken. It preserves both the freeze and
the blindness, and it answers backlog item 9 with the same artifact. Its cost is
a fixture — three repositories, an oracle, a case list, a scanner, and a
falsification — and that cost was paid in pass 0034.

All three options are costed in
[`plans/0033-honest-headline/tf-fixture-comments.txt`](../plans/0033-honest-headline/tf-fixture-comments.txt),
which recommended (c) and took none of them; the choice was the operator's and
this decision is it.

## Frozen

Once `plans/0034-fixture2/mutations2.txt` records the oracle falsified 7/7 and
`plans/0034-fixture2/readback2.txt` records the push byte-identical, fixture 2
is frozen on decision 0011's terms: **changes require a new decision.** A defect
found in it is a finding, not an edit.

Pipeline **definitions** were not created in Azure DevOps for fixture 2. The
pipeline YAML files exist in the repositories, carry `trigger: none` and
`pr: none`, and are configuration a reader parses — nothing was queued, run or
triggered, and no build object exists in the project for these three
repositories.

The SHAs the freeze names are appended to this file as an amendment once the
push has been read back, and are pinned in `LEDGER.md`.
