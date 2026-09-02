# 03 — Test first, or nothing

A test that has only ever passed is indistinguishable from a test that cannot
fail. You cannot tell them apart by reading either one, and you cannot tell
them apart by looking at the output, because both print green.

This chapter is the whole of the defence against that: write the test first
and watch it fail, then break the thing it guards and watch it fail again.
It is stage 2 of the build order in
[chapter 02](./02-order-of-operations.md), and it is the stage nobody may
skip. This repository keeps finding assertions that were incapable of
failing — by pass 0011 the journal is already numbering them, calling the
fixture's `node ids are unique` "the third this project has found" — and each
of them was contributing to a published number at the time.

Some vocabulary, defined once and used throughout. An **assertion** is one
check with a name — "throws on coverage below target rather than only
reporting it". A **red** is that assertion failing; a **green** is it
passing. A **gate** is a check that stops the build or the release when it
goes red. A **probe** is a deliberate, temporary change you make in order to
find out what an assertion notices.

---

## (a) Red first, and why a green test stops the pass

The rule is in [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) §4, which describes
what a full-tier pass must record before it does any work:

> The test as run, the command, and the failure output proving it was red
> before any work began. A test already green stops the pass: either the work
> is unnecessary or the test cannot fail. Both are findings and both go in
> Deviations.

Read the middle sentence slowly, because it is doing more than it looks. You
have written a test for work you have not done yet. You run it. It passes.
There are exactly two explanations and no third:

1. **The work is unnecessary.** The behaviour you were about to add is
   already there. Good news, and worth knowing before you spend an afternoon
   re-adding it. Stop and go and look at why.
2. **The test cannot fail.** It is inert: it would pass against your code,
   against an empty directory, against a file of nonsense. This is the bad
   case, and it is bad in a specific way — you were seconds away from writing
   the feature, seeing green, and filing that green as evidence.

There is no third option, because a test that can fail and has not is a test
whose subject is already satisfied, which is option 1. That is why a green at
the start is not a pleasant surprise to be waved through. It is a stop, and
what you learned goes in the plan's *Deviations* section, which in this
repository has carried more signal than any other section
([plans/README.md](../../plans/README.md) says to start reading a plan
there).

### What this looks like in practice

Every full-tier pass here committed its acceptance test red before the work,
and the number is in the plan:

- **Pass 0011**, the fixture design, ran its acceptance test against a disk
  with no fixture on it: 1 passed, 6 failed, 1 container failed. After the
  fixture existed: 317 passed, 0 failed.
  [journal](../../journal/0011-fixture-design.md),
  [plan](../../plans/0011-fixture-design/plan.md)
- **Pass 0014**, the graph comparator, ran 28 assertions before the
  comparator existed: 1 passed, 27 failed. Green afterwards: 28 of 28. The
  one early pass was the guard asserting the comparator does not modify its
  inputs, "trivially true because nothing had run" — an inert green in
  miniature, and it was visible only because the suite ran before the code.
  [journal](../../journal/0014-seed-and-comparator.md)
- **The three ladder runs** each committed their acceptance test red before
  the clock started: 0 of 10 for [pass 0026](../../journal/0026-run-004.md),
  0 of 11 for [0027](../../journal/0027-run-005.md), 0 of 11 for
  [0028](../../journal/0028-run-006.md).
- **Pass 0029**, which wrote the final README, was red at 21 of 24 and green
  at 24 of 24. [journal](../../journal/0029-final-readme.md)

### Where the rule deliberately does not apply

A pass that only writes documents — journal, decisions, method, protocol —
runs at *light* tier and has no acceptance test. PLAN-PROTOCOL.md gives the
reason, and it is not laziness: "A test asserting that a document contains a
heading proves only that a heading exists, and invites writing to the test."
At that tier the honest artifact is the diff and the operator's reading of
it.

The tier is decided by whether the pass changes executable behaviour, never
by how many documents it writes. The protocol carries pass 0012 as its worked
example: a pass labelled light, whose bulk was prose, which also amended one
assertion — and which flagged its own mislabelling in Deviations rather than
absorbing it.

---

## (b) Falsification rows, in plain words

Writing the test first proves the test can fail *at the moment the feature is
absent*. That is necessary and it is not sufficient. Once the feature exists,
you still have to prove the assertion is watching the feature and not
something next to it. That is what a falsification row is.

A **falsification row** is one recorded experiment against one assertion:

1. Confirm the target is in its known-good state.
2. Apply exactly one **break** — change the thing the assertion is about.
3. Re-run the grader. The named assertion must go **red**.
4. Restore, and confirm the restore worked.

METHOD.md's rule: an assertion does not count until it has a falsification
row. Any assertion added or changed gets a break, a confirmed red, and a
restore before any score including it is recorded.

But a break alone only proves the assertion can fail *somehow*. It does not
prove it fails for the right reason. So a row also needs a **control**: a
change the assertion must *not* notice, after which it must stay **green**.
[METHOD.md](../../method/METHOD.md): "The break proves the assertion can
fail. The control proves it fails for the right reason."

### Polarity: the part everybody gets wrong first

There are two kinds of control, and which one you need depends on what the
assertion claims. METHOD.md states both:

> A **scope control** adds text mentioning X while the behaviour is still
> present. The assertion must stay **green**. It guards against matching too
> much — against an assertion that fires on a comment, a neighbour, or a
> mention.

> A **substitution control** removes the behaviour and leaves text resembling
> it. The assertion must go **red**. It guards against inertness — against an
> assertion that a resemblance satisfies.

Now the part that decides whether your controls are worth running:

- For a **negative** assertion — "this file must **not** do X" — the two
  collapse into a single probe. Adding a mention of X *is* the interesting
  perturbation, and the answer you want is one answer.
- For a **positive** assertion — "this file must do X" — they are two
  independent questions, and **neither result implies the other**. An
  assertion can pass a scope control and be completely inert; an assertion
  can be defeated by a substitution control and still be far too broad.

The trap is that the scope control is the intuitive one, and it is the weaker
one. A comment mentioning X cannot break a positive assertion while X's code
is still sitting there, so *any* wholly inert assertion sails through it.
METHOD.md records the count: **twelve assertions in this project passed a
scope control and failed a substitution control.**

Both directions have bitten here, which is why both are written down:

- **Too broad.** In pass 0007, a control added a *comment* reading "never set
  `Run.Exit = $true` here", changing no code — and the assertion checking for
  that hazard went red. A build file whose author documented the hazard would
  have failed the assertion that checks for the hazard. Twelve breaks had not
  found it; one control did.
  [journal 0007](../../journal/0007-controls-tag-split-corpus.md)
- **Inert.** In pass 0008, five build-file assertions passed the specified
  comment-only control and were then defeated by the mirror probe — delete
  the code, leave the comment. All five stayed green.
  [journal 0008](../../journal/0008-repair-universal-tag.md). Pass 0009 then
  swept every positive assertion in the suite with the polarity-correct
  control: 22 probes, three more defects, in one sitting.
  [journal 0009](../../journal/0009-correct-the-control-protocol.md),
  [CONTROL-SWEEP.md](../../evals/conformance/baseline/CONTROL-SWEEP.md)

### The four outcomes, and the one that lies

[evals/HARNESS.md](../../evals/HARNESS.md) names what a row can report:

- **Fires** — the expected assertion goes red, nothing else does.
- **Does not fire** — the assertion stays green through its own break. "The
  finding that matters most, and the one a careless harness reports as
  success."
- **Over-fires** — other assertions go red too. Name them; sometimes that is
  correct, so it is a fact to record and judge rather than an automatic
  fault.
- **Correctly stays green** — a control row, where the break is one the named
  assertion must not notice.

Two guards keep those outcomes honest, and both are in HARNESS.md because
both have already produced false results here:

- **A break must assert that it actually changed the target** before the
  grader re-runs (hazard 4). A substitution that matches nothing leaves the
  target intact, the run comes back green, and the row records *does not
  fire* — a false report of the exact defect the protocol exists to detect.
  It fails toward the alarming answer, which is the answer nobody
  double-checks. One probe in this repository was a PowerShell parse error
  that never applied at all; the script printed that all checks agreed, and
  the only tell was an empty failure list.
- **Every expected assertion name is resolved against the names the grader
  actually produces**, with a hard stop on any that does not (hazard 6).
  Rename an assertion during a repair and every row naming the old name
  silently stops matching: the genuine red lands in the collateral column and
  the row reports *does not fire*. And guard row selection the same way — a
  typo in one filter selected zero rows and reported a clean run. **A run of
  zero rows is not a pass.**

---

## (c) What this buys: three assertions that could not fail

None of these were sloppy code. All three read correctly, passed review, and
had been green for a long time.

### The coverage assertion that matched a comment

The conformance suite asserted that the reference module's build file "throws
on coverage below target rather than only reporting it". It implemented that
by matching `(?s)CoveragePercent.*throw` against the build file's text. With
`(?s)` and an unbounded `.*`, *any* `throw` anywhere after the first mention
of `CoveragePercent` satisfies it — and the reference's build file contains
nine.

Pass 0005's falsification row found it, and then went two checks further to
establish how far from working it was: with the coverage `throw` deleted it
stayed green on the word "throw" in the **comment explaining the throw**;
with that comment also deleted it stayed green on a Pester version guard
thirty-odd lines further down. No edit to the coverage gate could turn it
red. It had passed in every green run since it was written, contributing a
point while testing nothing.
[journal 0005](../../journal/0005-establish-the-baseline.md)

Pass 0006 replaced it with an assertion that parses the build file, finds the
`Test` task, takes its body, finds the `if` statement whose *condition* reads
the coverage percentage, and requires a `throw` inside that `if`'s own body —
then proved the replacement with three probes: delete the throw and keep the
comment (red), delete both (red), and leave the gate intact while deleting
two unrelated guards in the same task (green). That third probe is the
control, and it is what separates "watching the gate" from "watching the
task". [journal 0006](../../journal/0006-fix-the-inert-assertion.md)

The general lesson is in METHOD.md: **prefer semantic inspection over text
matching.** Text matching produces both failure modes — matching something
unrelated, and matching a comment that documents the thing. Both have
occurred here.

### "Node ids are unique", passing against an empty fixture

Pass 0011 wrote the fixture's acceptance test before authoring any fixture
content, ran it against an empty directory, and one assertion came back
green: `node ids are unique`. Zero ids contain no duplicates, so the
assertion was satisfied by nothing at all. It now carries a count guard.

Why red-first is the only thing that could have caught it: written *after*
the fixture, it would have been green from birth and indistinguishable from a
working assertion. There would have been no moment at which it was supposed
to fail and did not. The journal states it plainly — "it was visible only
because the test ran against nothing before it ran against something."
[journal 0011](../../journal/0011-fixture-design.md)

This is also the general shape of a whole class of inert assertions: any
check that iterates over a collection is vacuously true when the collection
is empty. "Every exported command has help." "No node has a duplicate id."
"All references resolve." Each one passes perfectly against nothing.

### The PreTag gate that selected no tests

The third is the purest form, because every individual claim was true.

A repository declared a `PreTag` task — the gate that seals a tag — and its
default test task was configured to exclude `PreTag`-tagged tests. The
conformance suite asserted both facts, and both were true. But **no test
carried the tag**. The gate selected nothing, so it could only ever throw its
own guard, and it had been that way since the version it was supposed to be
sealing was tagged. Nothing in the suite could catch it, because nothing
asserted that a tagged test exists.
[METHOD.md](../../method/METHOD.md), *The falsification harness*.

It was found only because pass 0025 tried to *run* it. That journal entry
collects it with two others under the heading "Three gates that had never
been able to fail", and the sentence under the heading is the one to steal:
"None of these came from the fixture. All three came from running something
nobody had run." [journal 0025](../../journal/0025-findings-batch.md)

---

## (d) The coverage gate: one missing line, two dead gates, no symptom

This is the story to keep, because everything that could have caught it did
not, and everything looked right at every step.

**The template.** `skills/powershell-module-build/SKILL.md` gives a `Test`
task under the heading "Test configures Pester, and the coverage throw is the
gate". It configures Pester, runs it, reads the coverage percentage and the
target off the result, throws if the percentage is below the target, and
prints a coverage line. It is exactly the shape you would write yourself:

```powershell
$result   = Invoke-Pester -Configuration $cfg
$coverage = $result.CodeCoverage
$percent  = [math]::Round($coverage.CoveragePercent, 2)
$target   = $coverage.CoveragePercentTarget
if ($percent -lt $target) { throw "..." }
```

**The missing line.** `Invoke-Pester -Configuration` returns nothing unless
`Run.PassThru` is set, and the template never sets it. Every step after that
is silent, and this is run 004's own table
([findings.md](../../runs/004-plugin-on/findings.md)):

| Step | With `PassThru` | Without |
|---|---|---|
| `$result` | a run object | `$null` |
| `$coverage.CoveragePercent` | `94.91` | `$null` |
| `[math]::Round($null, 2)` | `94.91` | `0` |
| `$coverage.CoveragePercentTarget` | `70` | `$null` → `''` |
| `if (0 -lt '')` | — | `''` coerces to `0`; `0 -lt 0` is **false** |

The percentage comes out `0`. The target comes out empty. The gate compares
`0` against nothing — run 006 records the same comparison as `0 -lt $null`
— and the answer is false, so the `throw` is never reached. The build printed

    Line coverage: 0% (target %)

and exited 0, four lines after Pester itself had printed `Covered 90.31% /
70%`. The gate simply never saw it.

**And the same omission breaks a second gate in the opposite direction.** The
`PreTag` guard is written to catch an empty selection:
`if (($result.PassedCount + $result.FailedCount) -eq 0) { throw }`. On a null
result that is `($null + $null) -eq 0`, which is true, so the guard fires on
every run — including runs where every seal passed. One gate that can never
fail and one that can never pass, from one missing line. Run 006 states the
mechanism on its own as F-11, because it is not specific to coverage: *every*
gate written against `$result` compares against `$null`.
[runs/006-plugin-on/findings.md](../../runs/006-plugin-on/findings.md)

**Now the part that matters for this chapter.** The conformance suite scored
the repository **33 / 33 cases-defined, 57 / 57 cases-run**, and that score
*included* the assertion "throws on coverage below target rather than only
reporting it". That assertion was not wrong. The `throw` is structurally
present, inside an `if` whose condition reads a coverage percentage, inside
the `Test` task. It is a true statement about the file. It is simply a
different claim from the one anybody wanted, which is that the gate can fire.

Nothing announced the difference. The build was green. The suite was green.
The coverage line printed a number. Three independent blind sessions built
the module from the same template and all three shipped both dead gates —
F-1 in the recurring-findings table of [README.md](../../README.md), ticked
for runs 004, 005 and 006.

**What did find it, all three times: falsifying the gate on purpose.** Run
004 raised the target to 99 against real coverage of 94.91% and watched the
build go red with exit 1, then restored it to 70. Run 006 did the same at 99%
against 90.13% and recorded the message it got back — `Line coverage 90.13%
is below the target of 99%`. Run 004's note on why that is in the record at
all is the entire argument of this chapter in one sentence: "the falsification
is the only evidence that the fix worked — the green run before and the green
run after look identical."
[journal 0026](../../journal/0026-run-004.md),
[journal 0028](../../journal/0028-run-006.md)

The rule this lands on is METHOD.md's, stated there in bold:

> **An assertion about a declaration is not an assertion about the thing
> declared.** Checking that a gate is *declared* is a different claim from
> checking that the gate *can fail*, and the first is routinely mistaken for
> the second because both go green.

---

## The operational rule

METHOD.md turns all of the above into one thing you can actually do, for
every gate you own:

> The rule that follows: for every gate, name the observation that would be
> different if the gate were removed, and produce it. Declaration is evidence
> about the document. Only a red is evidence about the gate.

Three practical readings of that:

- **"Name the observation" comes first.** If you cannot say what would look
  different, you do not yet understand what the gate does, and no amount of
  reading the code will tell you.
- **"And produce it" is the whole job.** Break the thing, watch the red,
  restore it, verify the restore, and write down all four. A row you did not
  run is a row you did not run.
- **A green is never evidence about a gate.** It is compatible with a working
  gate, an inert gate, a gate that selected zero tests, and a gate whose
  input was `$null`. Only a red discriminates.

[Chapter 04](./04-fresh-sessions-and-contamination.md), on fresh sessions and
contamination, is about the other way a measurement quietly stops measuring:
not an assertion that cannot fail, but a run that already knows the answer.
[Chapter 05](./05-calling-bullshit-verification.md) is the habit that follows
from both — how to check a claim, including one of your own.

<!-- TEMPLATE:replace — the assertion names, probe counts and run numbers
     here are this repository's. Keep the polarity rules and the operational
     rule; replace the worked examples with your own falsification records. -->
