# The test stack, layer by layer

This page explains the testing in this repository: what each layer checks,
what it catches that no other layer does, and where its value is not yet
proven. It is written for someone who suspects this much apparatus cannot
possibly pay for itself, and who wants the evidence either way before
copying any of it.

Read it top to bottom. Every claim links the file it came from, so you can
disagree with the file rather than with me.

If you want the story in order — how an agent gets built this way, one
decision at a time — that is the manual, starting at
[00-start-here](../creating-an-agent/00-start-here.md). The chapter that
covers this material narratively is
[03-test-first-or-nothing](../creating-an-agent/03-test-first-or-nothing.md).
This page is the reference.

## A word you will need: oracle

An **oracle** is whatever tells you the right answer. Without one, a test
can only tell you that a program did not crash. With one, it can tell you
that the program is wrong.

Most test suites are their own oracle: somebody wrote `Should -Be 4` and
that is the answer. That works until the thing under test is written by an
agent that could also have written the assertion, at which point the suite
proves only that the agent is self-consistent.

Everything below is an attempt to buy an oracle the agent cannot have
written, and then to prove that the oracle can actually disagree.

## The seven layers, and the one thing each one caught

| Layer | The question it answers | The artifact | The instance where it earned its keep |
|---|---|---|---|
| Conformance | Is this built the way a PowerShell module should be built? | [`Conformance.Tests.ps1`](../../evals/conformance/Conformance.Tests.ps1) | [Run 003](../../runs/003-baseline-off/README.md) scored 19 / 33: fourteen house-style rules unmet. |
| Functional | Does it produce the right answer? | [`Compare-Graph.ps1`](../../evals/functional/Compare-Graph.ps1) | [Run 004](../../runs/004-plugin-on/README.md) scored 33 / 33 on shape and **1 / 12** here, first shot. |
| Falsification | Can an assertion fail at all, and only for its own reason? | [`FALSIFICATION.md`](../../evals/conformance/baseline/FALSIFICATION.md) | The coverage assertion was inert from the day it was written and passed every green run for free. |
| Ordered runner | Of fifty red lines, which one is the cause? | [`Invoke-OrderedTests.ps1`](../../skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1) | One unclosed brace: one line naming the file and column, against eighteen lines naming three innocent files. |
| Mutation testing | Can the comparator disagree with anything? | [`Invoke-TfOracleFalsification.ps1`](../../evals/tf/Invoke-TfOracleFalsification.ps1), [`Invoke-TfDuplicateIdFalsification.ps1`](../../evals/tf/Invoke-TfDuplicateIdFalsification.ps1) | Seven mutations, seven distinct mechanisms, control at zero — plus mutation 8, which is two-directional and has its own driver. |
| Sanitization | Does the fixture tell a builder its own answers? | [`Test-FixtureSanitization.ps1`](../../evals/tf/Test-FixtureSanitization.ps1) | Clean on fixture 2 and **94 findings on fixture 1**, which is what makes the clean verdict mean something. |
| Case scoring | Which of the **named cases** does this graph get right? | [`Test-TfFixtureCase.ps1`](../../evals/tf/Test-TfFixtureCase.ps1), [`fixture2/Test-TfFixture2Case.ps1`](../../evals/tf/fixture2/Test-TfFixture2Case.ps1) | The fixture-2 scorer, pointed at **the oracle itself**, came back 6 / 7 — the answer key failing its own paper. |

---

## 1. Why there are two oracles at all

There are two independent oracles here, and they are not redundant. They
ask different questions and neither can answer the other's.

**Conformance asks: is this built the way a PowerShell module should be
built.** Manifest, exported names, directory layout, the build file, the
analyzer settings, the coverage gate, the generated `psm1`. It is
[`evals/conformance/`](../../evals/conformance/README.md).

**Functional asks: does it produce the right answer.** A hand-written
expected graph, and a comparator that scores a candidate against it. It is
[`evals/functional/`](../../evals/functional/BRIEF.md).

Both are needed because each is blind exactly where the other looks.

The conformance suite never imports or runs the module. Every assertion
reads the source tree, the manifest, the build file or the generated `psm1`
as text or as a parsed syntax tree. The suite README gives the reason:

> A suite that has to run arbitrary build code to grade a run is a suite
> that can be made to pass by a run that breaks it.

That design decision buys safety and costs knowledge. A suite that never
executes the module cannot possibly know whether the module answers
correctly. It grades the container, not the contents.

The functional side is the opposite trade. Its oracle is
[`fixture/expected-graph.json`](../../evals/functional/fixture/expected-graph.json)
— the correct answer for a fixed input, written **by hand from the YAML
rather than generated by parsing it**. The twelve cases in
[`fixture/cases.md`](../../evals/functional/fixture/cases.md) each name the
specific wrong answer they catch. It knows nothing about layout, manifests
or build files, and a module that answered all twelve perfectly could be
one unreadable script.

The repository states the separation as a rule rather than leaving it to
taste. From [`BRIEF.md`](../../evals/functional/BRIEF.md):

> A module can score 100% on conformance and return an empty graph; a
> module can fail four house-style assertions and answer every one of the
> twelve cases correctly. Those are different facts and averaging them
> would destroy both.

And [`method/METHOD.md`](../../method/METHOD.md), under *Known limits of
this method*, states the reason the second oracle exists at all:

> It measures conformity, not utility. An artifact can satisfy every
> assertion and be useless. A separate functional check is required and is
> not part of the grader.

So the two scores are reported side by side and never combined. That is
mildly annoying to read and it is the entire point.

---

## 2. The shape-not-function trap

Here is the sharpest number in the repository, and it is the reason a
single oracle is not enough.

[Run 004](../../runs/004-plugin-on/README.md) scored **33 / 33 on
conformance** — every assertion in all four tags, 57 of 57 cases run, 100%,
at first shot, from a fresh clone built from nothing — and **1 / 12 on the
functional oracle on that same first shot**, with 26 differences against
the expected graph. Runs [005](../../runs/005-plugin-on/README.md) and
[006](../../runs/006-plugin-on/README.md) reproduced both numbers exactly.
The single case that passed at first shot was case 12, the absence case: a
repository nothing references must not appear in the graph. Twenty-five of
the twenty-six differences were three field conventions the brief never
states, and the twenty-sixth was one genuinely missing node — and because
the case tags live on the nodes carrying the omitted property, one absent
field failed eleven cases on its own. Ship on the conformance score and you
ship a perfect-looking module whose answer no downstream consumer can read.
The plugin-off control, [run 003](../../runs/003-baseline-off/README.md),
makes the same point from the other end: 19 / 33 on shape, 0 / 12 on
behaviour, and among its 29 differences an `extraNode` — the empty
repository sitting in the same project, emitted as though something
depended on it. As the root [README](../../README.md) puts it, "It reads as
a complete graph, and it answers a different question from the one asked."
Nothing about the output announces that; only an oracle written before the
module existed can.

---

## 3. Falsification: one break and one control, end to end

An assertion that has only ever passed is indistinguishable from an
assertion that cannot fail. This layer is how you tell the difference, and
it is the layer people skip.

Two plain definitions:

- A **break** is a deliberate edit to a known-good target that the
  assertion under test *must notice*. Apply it, re-run, and the assertion
  must go **red**. A break proves the assertion **can** fail.
- A **control** is a deliberate edit that the same assertion *must not
  notice*. Apply it, re-run, and the assertion must stay **green**. A
  control proves it fails **for the right reason** rather than because
  something nearby moved.

The two claims are different and the first does not imply the second. The
[suite README](../../evals/conformance/README.md) states the standing rules
that follow:

> **An assertion does not count until it has a falsification row.**

> **A falsification row needs a negative control, not just a break.**

### The worked pair: rows 8a, 8b and 8c

The full record is
[`baseline/FALSIFICATION.md`](../../evals/conformance/baseline/FALSIFICATION.md),
under *Row 8 — was inert, now fixed*. The assertion is `throws on coverage
below target rather than only reporting it`, and it lives in the
`House style: build file` block of
[`Conformance.Tests.ps1`](../../evals/conformance/Conformance.Tests.ps1) at
line 584.

**What the assertion used to be.** One line:

```powershell
It 'throws on coverage below target rather than only reporting it' {
    $BuildText | Should -Match '(?s)CoveragePercent.*throw'
}
```

`(?s)` makes `.` match newlines and `.*` is unbounded, so *any* `throw`
anywhere after the first mention of `CoveragePercent` satisfied it. The
reference build file has nine `throw` statements. The assertion accepted
all of them. Delete the coverage gate and the regex matched the word
"throw" inside the comment explaining why the gate exists. Delete that
comment too and it still matched, on
`throw 'Pester 6.x is required. Run ./build.ps1 -Bootstrap'` in a different
task thirty-odd lines further down.

No edit to the coverage gate could turn it red. Not weak — **inert**. It
passed in every green run from the day it was written, contributing a point
while testing nothing.

**What replaced it.** Structure instead of text. Parse the build file, find
the `task Test` command, take its body scriptblock, find the `if` whose
*condition* reads the coverage percentage, and require a `throw` inside
that `if`'s own body. Matching the condition is what stops a comment
counting. Searching only that body is what stops the other eight throws
counting. Against the unbroken reference it finds one gate and one throw,
out of nine in the file.

**The three probes, run before any score containing the assertion was
recorded:**

| Probe | The edit | Required | Actual |
|---|---|---|---|
| 8a | Delete the coverage `throw`, keep the comment above it | red | **red** |
| 8b | Delete the coverage `throw` and the comment | red | **red** |
| 8c | **Control.** Gate intact; delete both `throw 'Pester 6.x is required'` guards | green | **green** |

**8c is the one that matters, and here is why.** One of the two guards it
deletes sits *inside the Test task but outside the coverage gate*. An
assertion scoped to the whole Test task rather than to the `if` statement
inside it would pass 8a and 8b — both breaks go red — and then fail 8c by
going red on something it has no business noticing. Two red probes cannot
tell a correctly scoped assertion from an over-broad one. Only the green
control can.

[Journal 0006](../../journal/0006-fix-the-inert-assertion.md) records the
pass, and this is its one-line summary: *a red probe alone does not finish
an assertion.* It became hazard 7 in
[`evals/HARNESS.md`](../../evals/HARNESS.md).

**What this layer cost, and what it bought.** It cost one pass. It bought
the correction that a published figure of 74/75 should have been read as
73/74 plus one unknown — and later, when the same polarity-correct probe
was swept across every positive assertion in
[`baseline/CONTROL-SWEEP.md`](../../evals/conformance/baseline/CONTROL-SWEEP.md),
the discovery that five build-file assertions were satisfied by a block
comment quoting the line they looked for, with the real code deleted. Five
out of five, tested one at a time. Every one of them had been green in
every run.

---

## 4. The ordered runner, and the wall of red

One unparseable source file produces a lint that reports clean, a `psm1`
that will not import, nine import errors, and then every test in the suite
failing against a module that is not loaded. That is one defect and fifty
red lines, and the wall of red buries the filename that would fix it.

[`Invoke-OrderedTests.ps1`](../../skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1)
runs five layers in dependency order and **stops at the first one that
fails**:

1. `manifest-parses` — the manifest is readable as PowerShell data
2. `files-parse` — every `.ps1` in `src/` and `tests/` parses
3. `module-imports` — the module loads in a clean process
4. `unit` — Pester, excluding integration and contract
5. `integration` — Pester, integration and contract only

Each layer is a precondition for the next, so a failure at layer 2 makes
every result at layers 3 to 5 uninterpretable rather than informative. The
script's own docstring puts it best:

> A failure at layer 2 says "this file, this line". The same defect
> observed at layer 4 says "37 tests failed".

**The recorded demonstration** is
[`plans/0017-skill-roster/ordered-run-demo.txt`](../../plans/0017-skill-roster/ordered-run-demo.txt),
taken against a fresh clone of
[run 002](../../runs/002-first-build/README.md) with one unclosed brace
appended to a single public function. The pristine run:

```
LAYER manifest-parses  PASSED       1 case(s)
LAYER files-parse      PASSED       17 case(s)
LAYER module-imports   PASSED       1 case(s)  (PSAzureDevOpsGraph)
LAYER unit             PASSED       37 case(s)
LAYER integration      INAPPLICABLE 0 case(s)  (no test in Integration/Contract and none tagged Integration/Contract)

ALL LAYERS GREEN — 4 passed, 1 inapplicable.
  inapplicable (graded nothing, not a pass): integration
```

The sabotaged run:

```
LAYER manifest-parses  PASSED       1 case(s)
LAYER files-parse      FAILED       17 case(s)

STOPPED AT LAYER files-parse

  src\PSAzureDevOpsGraph\Public\Get-AzDoPipelineReference.ps1:65:16: Missing closing '}' in statement block or type definition.
  src\PSAzureDevOpsGraph\Public\Get-AzDoPipelineReference.ps1:64:29: Missing closing '}' in statement block or type definition.

NOT RUN (a failing layer is a precondition for these): module-imports, unit, integration
```

The same sabotaged tree through `./build.ps1` does go red — that clone's
analyzer settings list `ParseError` explicitly — but the transcript records
that **eighteen lines of InvokeBuild and PowerShell error-record chrome
name three files, and none of them is the broken one.** The findings table
the Lint task writes goes to the host and is absent from the captured
stream entirely.

Two details in that output are load-bearing beyond the diagnosis:

- `INAPPLICABLE` is a third outcome, not a pass. A layer that produced zero
  cases graded nothing, and reporting it as green is how a suite that has
  quietly stopped running starts looking healthy. The same principle
  returns in section 6.
- `NOT RUN` names what was skipped and why. A runner that stops silently
  looks identical to a runner that finished.

**Honest limit.** The evidence for this layer is one recorded sabotage
transcript against one clone, not a scored run. It is a clear
demonstration, not a measurement, and nothing in this repository quantifies
how much time it saves.

---

## 5. Does the pattern transfer? The Terraform oracle

Everything above was built around one PowerShell module and one Azure
DevOps fixture. A method validated only against the thing it was written
for proves self-consistency and nothing else.
[`evals/tf/`](../../evals/tf/fixture/cases.md) is a second oracle, in a
different language domain — Terraform HCL — built the same way: a
hand-authored expected graph across three repositories, a comparator, and
its own mutation set.

**Mutation testing**, in one sentence: instead of breaking the *target* to
test an assertion, you break the *oracle* to test the **comparator**, and
require that the comparator notices each break and names it correctly.
[`Mutate-TfGraph.ps1`](../../evals/tf/Mutate-TfGraph.ps1) states the reason
in its own docstring:

> A comparator that has only ever agreed with itself is indistinguishable
> from one that cannot disagree.

[`Invoke-TfOracleFalsification.ps1`](../../evals/tf/Invoke-TfOracleFalsification.ps1)
is the driver, and it exists because the first version of this
falsification was run from an uncommitted scratch script: *a falsification
nobody can re-run is a claim, not evidence.* It runs three checks in a
fixed order, each earning the next:

1. **Control.** The oracle compared against itself must report zero
   differences. Every detection below is meaningless if a document differs
   from itself.
2. **Landing.** Each mutation must prove it *changed the document* before
   its detection is trusted. A mutation that silently did nothing would
   otherwise be reported as a comparator that found nothing, which is the
   opposite conclusion.
3. **Discrimination.** Each mutation must come back as its **own**
   category. A comparator that reported everything as `MissingNode` would
   score 7 / 7 and be useless.

Run it against the committed oracle and it reports `CONTROL GREEN`,
`DETECTED: 7 / 7`, and `distinct categories exercised: 7 of 7`. One line of
that output is worth reading twice:

```
MUTATION: wrong-attribute
CHANGED:  change the random provider pin from 3.6.0 to 9.9.9
LANDED:   document changed, 21017 -> 21017 chars
```

Same length, different content. [Journal
0023](../../journal/0023-tf-fixture.md) records why that matters: a landing
check written as a length comparison would have passed this mutation while
proving nothing.

### Mutation 8, and the hazard that hid from all seven

Those seven mutations were 7 / 7 for four passes, and the comparator was
blind the whole time.

Pass 0034's `verify.ps1` carried a probe that duplicated a node id in the
fixture-2 oracle and expected the control — the oracle against itself — to go
red. **It stayed green**, over a document that had just grown from 99 nodes to
100. Both graphs were keyed into an ordered dictionary by id before anything
was compared, and `$byId[$node.id] = $node` discards the earlier entry, so the
duplicate deleted itself on *both* sides and the two sides agreed.

> **A dictionary is a deduplicator. A comparator that keys by id must assert
> uniqueness before it keys anything.**

The evidence was on screen throughout: `expected: 99 node(s)` printed directly
above `actual: 100 node(s)`, with a clean verdict underneath. That is the worst
combination available, because a reader who trusts the verdict never reads the
header. A producer emitting a node twice would have scored clean.

Pass 0035 added **Stage 0** to the comparator — uniqueness asserted on both
graphs before the first assignment into a hashtable — and `DuplicateId` as its
own category, naming every duplicated id and which side carries it. Three
details are the whole lesson:

- **Its own category, not a nearby one.** A duplicate is not an `ExtraNode`
  and not a `WrongAttribute` on the survivor. Neither copy is the extra one;
  the id is ambiguous, so every comparison keyed on it is *meaningless* rather
  than merely wrong. Reporting it as something else names a defect that is not
  the defect, and a reader cannot act on it.
- **The category was taken over the cheap proxy.** The obvious alternative was
  asserting `ActualNodeCount -eq ExpectedNodeCount`. It is wrong in exactly the
  case that matters: a graph with one node duplicated and one node missing has
  the right total and two defects.
- **Mutation 8 is two-directional, so it has its own driver.** The other seven
  break the graph under test. A duplicated id is the same defect whichever side
  carries it, and the side nobody thinks about is the *oracle* — which is
  precisely the direction that made the control green.
  [`mutation8.txt`](../../plans/0035-tf003-kit/mutation8.txt) records
  `DUPLICATE-ID: detected on producer side` and `…on oracle side`, with both
  clean oracles matching themselves before *and* after, so a repair that had
  made every document differ from itself would fail rather than look like
  success. `Invoke-TfOracleFalsification.ps1` now says in its own report that
  it covers seven of eight, because a green there is no longer a falsified
  comparator on its own.

Both suites re-run at their pinned counts afterwards —
[`suites.txt`](../../plans/0035-tf003-kit/suites.txt), `FIXTURE1: 15 passed,
0 failed` and `FIXTURE2: 8 passed, 0 failed`. The pinning matters as much as
the numbers: a suite that gained or lost a test is itself reported as a
failure, because a repair that quietly moved a count would have changed the
instrument while claiming to fix it.

**What found it was a probe that did not fire.** The comparator's suite was
15 / 15 and its mutations 7 / 7 before and after the defect was known. The
finding came from writing something that was *supposed* to turn red, and then
reading the result honestly instead of filing it as a broken probe.

**What the Terraform runs actually showed.**
[tf-001](../../runs/tf-001-first-build/README.md) took a producer from 94
differences to 68 to 31 across three iterations, and every one of the three
defects it found had failed **silently**. A local path `./modules/service`
is literally `namespace/name/provider`, so it matched the Terraform
registry pattern and every nested module resolved to a registry address
that does not exist. `required_providers` is a *block*, not an attribute,
so a reader looking for an attribute found no providers at all —
indistinguishable from a repository that pins none. And the parser rebuilt
expressions by joining tokens, so `var.tags` reached the reference
extractor as `var . tags` and every pattern written against source text
missed, costing 37 edges. None produced an error, a warning, or an empty
result that looked wrong. The hand-authored oracle is the only thing that
found them.
[tf-002](../../runs/tf-002-convention-and-case3/README.md) then re-scored
at **0 differences and 7 / 7**, after
[decision 0012](../../decisions/0012-fixture-case3-repair.md) repaired a
fixture case that no parser could pass and two producer defects were
closed.

**Be careful what you take from this.** The root
[README](../../README.md) states the limit and this page does not go past
it: **the oracle was visible for both tf-001 and tf-002, so this is a
statement about one fixture and not a generalisation claim; tf-003 is the
blind measurement and has not been run.** It was also **blocked** for a
while: pass 0033 scanned the Terraform fixture for the vector hazard 13
describes and found it names its own cases by number, states what the wrong
answer to several of them looks like, and — in one README — points at the
oracle document by path. The fixture is frozen, so nothing was changed and
the operator had a decision to make before a blind run against it meant
anything. [The scan](../../plans/0033-honest-headline/tf-fixture-comments.txt).
**That decision was taken and the block is lifted** — see *A second
Terraform fixture* below.
tf-002 also iterated zero
times, which — as [journal 0025](../../journal/0025-findings-batch.md) puts
it — means a run that scores 0 tests *less* than a run that scores 31. What
carries the claim in that run is the comparator's re-falsification against
the amended oracle, not the score itself.

**And one thing in this layer is currently wrong.** The committed oracle
holds 78 nodes and **59** edges after the decision-0012 amendment, and
running the comparator against it returns 59 — but
[`Compare-TfGraph.Tests.ps1`](../../evals/tf/Compare-TfGraph.Tests.ps1) at
line 41 still asserts `$result.ExpectedEdgeCount | Should-Be 57`. That
assertion is red as committed: a check that drifted from the artifact it
checks, which is the same species of defect as everything else on this
page, found the same way. *(Fixed in pass 0030; the paragraph is left
standing because it is how the defect was found, and the fix is the boring
half.)*

### A second Terraform fixture, and a gate on what a fixture may say

Pass 0034 took the decision the scan left open
([0014](../../decisions/0014-second-unannotated-fixture.md)) and built a
second Terraform fixture — `TfSiteCore`, `TfSiteEdge`, `TfSiteOps`, at
[`evals/tf/fixture2/`](../../evals/tf/fixture2/cases.md) — written mute from
the start.

**Which of the two answers which question:**

| | Fixture 1 (`evals/tf/fixture/`) | Fixture 2 (`evals/tf/fixture2/`) |
|---|---|---|
| Repositories | TfFixtureShared / Network / App | TfSiteCore / Edge / Ops |
| Annotated? | **Yes**, and stays that way | **No**, by design rule |
| What it is for | the deliverable-line example, and what tf-001 and tf-002 were scored against | **measurement** — tf-003 and after |
| Oracle | 78 nodes, 59 edges | **99 nodes, 88 edges** |
| Frozen by | decision 0011, amended once by 0012 | decision 0014 |

The two exercise the **same seven mechanism classes** on deliberately
different surfaces: four module levels instead of three, a diamond in which a
module's parent is neither of its two callers, two unresolved sources of two
different shapes instead of one, a cross-repository output reference landing
in an output as well as a local, a different provider mix and different pins.
A second fixture that is the first with the nouns changed would measure
memory.

**The sanitization gate.**
[`Test-FixtureSanitization.ps1`](../../evals/tf/Test-FixtureSanitization.ps1)
is pass 0033's hand-reading promoted to a script: 38 patterns in four
categories, run over every file and over the commit messages the publisher
pushes with. It is a further thing this stack does, and it belongs on this page
because of *how it was falsified* rather than because of what it checks:

- `-FailCheck` plants a case-naming comment in a scratch copy and requires the
  catch. That is the weak control — it proves the scanner reacts to something.
- Pointed at **fixture 1**, it reports **94 findings**: the `cases.md`
  pointer, the *"Case 3"* comment, the absence case's stated wrong answer, the
  numbered links. Pointed at **fixture 2**, it reports **clean**. That is the
  strong control, because it discriminates between two real fixtures rather
  than between a planted line and nothing.

Both reports are committed:
[`sanitization.txt`](../../plans/0034-fixture2/sanitization.txt) and
[`sanitization-fixture1-control.txt`](../../plans/0034-fixture2/sanitization-fixture1-control.txt).

**The comparator was re-falsified against the new oracle,** because an oracle
that changed does not inherit the previous falsification:
[`mutations2.txt`](../../plans/0034-fixture2/mutations2.txt) records
`DETECTED: 7 / 7`, seven distinct mechanisms, control at zero over 99 nodes
and 88 edges. Fixture 1's falsification re-runs byte-identical against the
copy committed at v1.0.0, which is what says the parameterization added a
fixture rather than weakening a check.

### The case layer, and the scorer that had to be graded first

Everything above this line is the **oracle layer**: it grades the comparator, by
breaking the oracle and requiring the break to be named. That answers *"do this
graph and the right answer differ, and how?"* It does not answer *"which of the
seven named cases does this graph get right?"*, and those are different
questions — a graph can match the oracle exactly and the cases still be worth
stating separately, and a case can pass while other differences remain.

Fixture 1 has had a case scorer since tf-001. **Fixture 2 shipped without one,**
so `functional-tf: N / 7` had nothing to compute it from, and the run that
needed the number had to write the scorer itself — into a plan directory, where
the next run would not have found it. Pass 0037 promoted it:

| | |
|---|---|
| [`fixture2/Test-TfFixture2Case.ps1`](../../evals/tf/fixture2/Test-TfFixture2Case.ps1) | the seven cases, each by its own assertions over the graph, using the oracle's **literal ids** |
| [`fixture2/Invoke-TfFixture2CaseFalsification.ps1`](../../evals/tf/fixture2/Invoke-TfFixture2CaseFalsification.ps1) | what makes the seven trustworthy, promoted alongside it |

Fixture 1's scorer was **left alone** rather than given a `-Fixture` switch: it
is the instrument tf-001 and tf-002 were scored with, and the two fixtures'
cases differ in substance, not only in ids.

The case falsification is four claims, and each is a different one:

1. **Control — the oracle scored against itself must be 7 / 7.** It was not,
   the first time it was run, and the defect was in `cases.md`'s prose rather
   than in any producer. [Chapter 3](../creating-an-agent/03-test-first-or-nothing.md#e-grade-the-grader-before-the-graded)
   has the whole story; the short form is **grade the grader before the
   graded**, and skipping it here would have published a number that was wrong
   in the modest direction.
2. **Seven mutations, one per case, each reddening its own case and no other.**
   A mutation that reddens two has not shown that either case is checked — it
   has shown they are entangled.
3. **The duplicate-id refusal.** The scorer keys every node by id, so a
   duplicate overwrites its own entry and a defective graph scores clean —
   [the same blindness](#mutation-8-and-the-hazard-that-hid-from-all-seven) the
   comparator carried for four passes, in a second instrument. Here the
   required outcome is not a failed case but a **throw**: an unscoreable graph
   is not a graph with a low score.
4. **That the corrected case 6 is stricter than the form it replaced** —
   demonstrated by a graph the old form calls clean at 7 / 7 which the new one
   reddens, not asserted.

**Fixture 2's suite is therefore two layers, and its pinned count moved 8 → 18**
(oracle 8, case 10) in [`Invoke-TfSuite.ps1`](../../evals/tf/Invoke-TfSuite.ps1).
Fixture 1 stays pinned at 15. A gained check reads as a failure until the pin
moves, which is the point of pinning; the move is stated in the runner, in the
report it prints and in the LEDGER, because **a pin that follows whatever ran is
not a pin.** Both new checks were broken on purpose and seen red before the 18
was trusted:
[`case-layer-falsification.txt`](../../plans/0037-consolidation/case-layer-falsification.txt).

**One asymmetry between the two, and why it is not one.** Fixture 1 has four
AzDO pipeline definitions and fixture 2 has none, which looks like an
instrument difference and was carried as LEDGER backlog 31 until pass 0035
settled it in decision 0014: *pipeline definitions are outside the TF
measurement surface.* Both fixtures carry four pipeline YAML files as file
content; **neither oracle holds a single pipeline node** — six node types
each, all of them HCL — so the four definitions contribute nothing to what
tf-001 or tf-002 measured. The TF oracles score HCL parsed from clones. A
capability that reads definitions through the REST API is a different surface
and gets its own fixture decision before it gets a run.

---

## 6. What each number in a run record means

Run records carry four numbers that are easy to misread. Here is each one,
and the trap it exists to prevent.

| Number | What it is | Where it comes from |
|---|---|---|
| `CasesDefined` | The count of `It` statements the selected tags select, parsed out of the suite's own source by AST. The target is never consulted. | [`Invoke-Conformance.ps1`](../../evals/conformance/Invoke-Conformance.ps1) |
| `CasesRun` | Passed plus failed — what actually executed against this target. | same |
| first-shot | The functional score of the very first build, before any iteration. | each run's `README.md` |
| final | The functional score after the run's permitted iterations. | same |

### cases-defined versus cases-run

**`CasesRun` depends on the shape of the target.** An `It` with `-ForEach`
over the public functions makes seven cases against a module with seven
commands and two against a module with two. Runs 002 and 003 are two builds
of the *same* module and reported 57 and 55, so the denominator moved
underneath the score.

**`CasesDefined` cannot move with the target**, because no file of the
target is read and no `-ForEach` is expanded to compute it. Three
differently shaped targets report `CasesDefined` 33 with `CasesRun` 57, 55
and 41. For [run 004](../../runs/004-plugin-on/conformance-result.json) the
per-tag breakdown is `Universal` 9, `Repository` 4, `HouseStyle` 14,
`RequiresBuild` 6 — which is 33.

Three reasons the distinction exists, in the order they were learned:

1. **Zero cases is not a pass.** An assertion whose `-ForEach` produced no
   cases is *inapplicable* to this target — never a pass, never a failure
   of its container. The comment-based-help assertion silently did not
   apply to six of eight corpus modules while appearing to be part of a
   green run. See
   [`baseline/UNIVERSAL-CORPUS.md`](../../evals/conformance/baseline/UNIVERSAL-CORPUS.md).
2. **A suite repair that reaches more of a target changes the
   denominator,** so two percentages stop being two measurements of the
   same thing. When the definition index was repaired to read `.psm1`
   files, SqlServerDsc went from 8/11 to 170/171 and ImportExcel from 17/67
   to 17/79. Neither module changed. The correct sentence, per
   [decision 0003](../../decisions/0003-score-comparability.md), is "the
   suite now measures 171 cases where it measured 11", not "SqlServerDsc
   improved".
3. **The risk runs in the flattering direction.** From the same decision:
   *an assertion that stops producing cases makes a score go up.* Had the
   help assertion been broken rather than repaired, every corpus module
   would have scored better, and a report tracking percentages would have
   recorded an improvement.

The rule that follows, stated in
[decision 0003](../../decisions/0003-score-comparability.md) and again in
[`method/METHOD.md`](../../method/METHOD.md): **a score comparison is valid
only when cases-run is stable between the two runs, and any report
comparing two scores states cases-run for both.** Compare on
`CasesDefined`; report `CasesRun` beside it.

One consequence you will hit immediately if you go looking:
[run 003's `conformance-result.json`](../../runs/003-baseline-off/conformance-result.json)
has no `CasesDefined` field at all, because it predates the change. Its
19 / 33 in the root README's table was **re-derived** by re-scoring its
pushed branch with today's suite, and the table says so.

### The v1.2.0 series boundary

**cases-defined moved from 33 to 41 at `v1.2.0`, and scores either side of that
tag are separate series that are not compared.**

The eight are the help block in
[`evals/conformance/Help.Tests.ps1`](../../evals/conformance/Help.Tests.ps1),
all tagged `HouseStyle`, taking that tag from 14 to 22. `Universal` 9,
`Repository` 4 and `RequiresBuild` 6 are unchanged. No existing assertion was
weakened, renamed or removed — the pass only adds.

A score of 33 / 33 and a score of 38 / 41 are therefore not two measurements of
the same thing, and no arithmetic relates them. Every figure taken before the
tag belongs to the 33-case series; every figure after it belongs to the 41-case
series. Both series stand: the boundary is not a reset, and the ladder's
recorded numbers are neither restated nor re-derived. A boundary used to retire
inconvenient earlier figures would be worse than no boundary at all.

The derivation itself did change in one way worth knowing about. The runner used
to inventory one named file; it now inventories **every `*.Tests.ps1` in the
directory** and runs that same list. Naming one file would have let a second
container run its assertions while being absent from `cases-defined` — the
numerator growing while the denominator held still, which reads as an
improvement and is a bookkeeping error. The full derivation, and the figure
re-derived across three differently shaped targets (cases-run 477, 154 and 60;
cases-defined 41 in all three), is in
[`plans/0039-ux-help-batch/denominator-v2.txt`](../../plans/0039-ux-help-batch/denominator-v2.txt).

### An optional settings file, and why its defaults are the measured ones

A target may carry `psmodule.settings.psd1` at its root. Three enumerated keys —
`CoverageThreshold`, `ModuleProfile`, `CompletionCacheDefault` — resolved
explicit parameter > file > built-in default by
[`Get-PSModuleSetting.ps1`](../../evals/conformance/Get-PSModuleSetting.ps1), and
**an unknown key is a refusal that names it** rather than a warning. A
misspelled key silently ignored means the grader ran with settings the file on
disk says it did not have, and nothing in the output would disagree with the
file.

**The defaults are the measured configuration.** Every score published here was
taken with no settings file present and those exact values, so a target shipping
no file is graded the way every recorded run was graded. The values and the
provenance of each are echoed into `result.json` and carried into the run record
by `Score-Clone.ps1` — because a score whose configuration is not recorded
beside it cannot be compared with another score, which is the same argument
`cases-defined` already won about the denominator. Falsification: three breaks,
three controls, in
[`plans/0039-ux-help-batch/settings-falsification.txt`](../../plans/0039-ux-help-batch/settings-falsification.txt).

### A fourth thing: a container that did not run

`CasesDefined` is parsed from the suite's source and does not know whether a file
loaded. When `Help.Tests.ps1` lost its discovery to a member access on an empty
array, every one of its assertions vanished from the run, `CasesRun` shrank with
them, and the score printed as entirely normal. Pester said `Container failed: 1`
in its own output and nothing downstream read it.

The runner now hard-stops on a container-level `ErrorRecord` and writes no
`result.json`. **Not run is not a pass**, one level up from zero cases — and the
guard keys on the ErrorRecord rather than on the container's `Result`, because a
container holding a merely failing test also reports `Failed`, and turning every
red run into a crash is the opposite of what this runner promises.

### A third thing the denominator does not protect you from

`CasesDefined` holds the denominator still. It says nothing about whether the
target was in the right *state* when the assertions ran, and that turned out
to be the next way two scores stopped being one measurement.

Six of the 33 assertions carry the `RequiresBuild` tag, and four of those
read `output/<Name>/` — the build's product, which is gitignored and so
absent from any clone that has not been built. The scoring protocol said
"score from a fresh clone" and never said to build it. Run 007's conformance
clone was not built, so those four graded a missing directory: **28 / 33
reported, 32 / 33 for the same commit built first.** Runs 004, 005 and 006
were unaffected, but each by a different accident — one built inside the
conformance clone, one scored a snapshot of a built tree, one built all three
clones — so nothing in the record said which was the rule.

The fix is a procedure, not an assertion: the conformance clone is built
before it is scored, and the sequence is one script,
[`Score-Clone.ps1`](../../evals/conformance/Score-Clone.ps1), so runs cannot
each improvise it. Both affected runs were re-scored under it and the repair
was falsified in three rows before the new numbers were used — including the
control that an unbuilt clone must *still* fail those four, which is what
distinguishes a corrected procedure from a weakened assertion. The evidence
is [rescore.txt](../../plans/0033-honest-headline/rescore.txt).

**The generalisation, if you take one thing from this section:** a score is
`(assertions) × (denominator) × (state of the thing being graded)`, and only
the first two are usually written down.

### first-shot versus final

`first-shot` is what the agent produced before it was allowed to see any
score. `final` is what it produced after iterating within the run's cap.
They measure different things, and only the first is comparable across the
plugin-on and plugin-off runs.

**Run 003 has no final score, and not because it failed to reach one.** Its
protocol said *"No fixes, no re-runs — the first scores stand"*. It was
never permitted an iteration. That is the most common way a comparison table
lies, and it is worth checking for in anyone else's numbers too.

**[Run 007](../../runs/007-baseline-iterated/README.md) is what happened when
the missing column was finally measured**, and it is the strongest argument
in this document for keeping first-shot and final apart. Plugin off, same
seed and brief, the ladder's three-iteration budget:

| | plugin on (004 / 005 / 006) | plugin off, iterated (007) |
|---|---|---|
| functional, first shot | 1 / 12 | 6 / 12 |
| functional, final | 12 / 12 | **12 / 12** |
| iterations to 12 / 12 | 1 / 1 / 2 | 1 |
| conformance, first shot | 33 / 33 | 19 / 33 |

**On `final`, the plugin's measured effect is nothing.** On `first-shot`
conformance it is thirteen or fourteen assertions. A table that reported only
`final` would say the plugin does nothing; one that reported only
`first-shot` would say it does everything. Both would be quoting real numbers
from the same five runs.

Two caveats travel with 007's first-shot row and are stated wherever it is
quoted: its own prompt named several of the convention mechanisms to the
builder before it wrote a line, and the comparator prints the oracle's
expected value for every wrong attribute, so the conventions were legible
from the scorer during iteration. See the run's
[findings](../../runs/007-baseline-iterated/findings.md) Part 3 and hazards
12 and 13 in [`evals/HARNESS.md`](../../evals/HARNESS.md).

---

## 7. Running it yourself

Needs PowerShell 7.2+, Pester 6.x, PSScriptAnalyzer, InvokeBuild. Three
commands reproduce a run end to end. These are the root
[README](../../README.md)'s commands verbatim, warnings included.

```powershell
# 0. To score a PUSHED commit rather than a working tree, use the one command
#    that clones, builds and scores in the same clone. The build is not
#    optional: four assertions read output/, which is gitignored.
./evals/conformance/Score-Clone.ps1 `
    -Source https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git `
    -Ref <sha> -WorkDir $env:TEMP/score-run

# The steps below are the same thing unrolled, for a run in progress.

# 1. Wipe the target back to the four-file seed. This is the start of a run.
./evals/functional/Reset-Target.ps1 -Destination scratch/runs/007-my-run

# 2. Shape. Read the score from result.json, never from the exit code — a red
#    conformance run is data, and the runner exits 0 on purpose.
#    Use -Command, never `pwsh -File`: -File flattens the comma-separated -Tag
#    into a single token and the filter then selects the wrong set, silently.
./evals/conformance/Invoke-Conformance.ps1 `
    -Path scratch/runs/007-my-run -ModuleName PSAzureDevOpsGraph `
    -Tag @('Universal','Repository','HouseStyle','RequiresBuild') `
    -ResultPath scratch/runs/007-my-run/conformance-result.json

# 3. Behaviour. Scores a produced graph against the hand-written oracle.
./evals/functional/Compare-Graph.ps1 `
    -CandidatePath scratch/runs/007-my-run/artifacts/graph.json `
    -ReportPath scratch/runs/007-my-run/compare-report.json
```

Four things in that block are not decoration:

- **Build the clone you are about to score.** Step 2 grades `output/` in six
  of its 33 assertions, and `output/` is gitignored. Running the conformance
  suite in a clone that has not been built scores those four as failures of
  the module rather than of the procedure — which is exactly what happened
  to run 007, at a cost of four assertions. `Score-Clone.ps1` exists so that
  this cannot be forgotten.
- **Read the score from `result.json`, never from the exit code.** The
  runner exits 0 on a red run on purpose, because a red conformance run is
  data and not a crash. Pass `-PassExitCode` if you genuinely want the
  failure count.
- **Use `-Command`, never `pwsh -File`.** `-File` flattens the
  comma-separated `-Tag` into a single token, and the filter then selects
  the wrong set, silently.
- **`Reset-Target.ps1` refuses any destination outside `scratch/runs/`.**
  A path-shaped guard is worth more than a sentence in a README, because
  the accident it prevents is a mistyped path, and a mistyped path does not
  read documentation. See
  [`Reset-Target.ps1`](../../evals/functional/Reset-Target.ps1).

The fixture and the oracle also check each other, in both directions:

```powershell
Invoke-Pester ./evals/functional/Fixture.Tests.ps1     # 352 cases
Invoke-Pester ./evals/functional/ReadBack.Tests.ps1    #  76 cases, needs AZDO_PAT
Invoke-Pester ./evals/functional/Compare.Tests.ps1     #  28 cases
```

`-ModuleName` is optional. When the repository root is a run directory the
runner derives it from `src/<Name>/<Name>.psd1`; two manifests under `src/`
is undecidable and stops, naming both, rather than grading the wrong module
silently.

What those three suites are each for:

- [`Fixture.Tests.ps1`](../../evals/functional/Fixture.Tests.ps1) checks
  that the YAML on disk and the hand-written oracle beside it are
  statements about the same thing, **in both directions**, so neither can
  drift without a red. It deliberately does *not* check that a reference
  resolves to the right target: that is what the module has to compute, and
  an oracle checked by a resolver is worth no more than the resolver.
- [`ReadBack.Tests.ps1`](../../evals/functional/ReadBack.Tests.ps1) checks
  that the bytes in Azure DevOps are the bytes in this repository — SHA-256
  over raw bytes on both sides, with no encoding detection and no
  line-ending translation, because a comparison that translates both sides
  identically passes while the server is wrong. It proves the push landed
  and says nothing about whether the graph is correct.
  [`AZDO-FIXTURE.md`](../../evals/functional/AZDO-FIXTURE.md) is what it
  reads back against.
- [`Compare.Tests.ps1`](../../evals/functional/Compare.Tests.ps1) is the
  AzDO comparator's own mutation suite, the counterpart to section 5's
  Terraform driver. Its wrong graphs are **generated** by
  [`Mutate-Graph.ps1`](../../evals/functional/Mutate-Graph.ps1) from the
  oracle, one mutation per declared case, each derived from that case's own
  "How a naive implementation fails" paragraph — never hand-authored,
  because a hand-written wrong graph tests only whether the comparator
  agrees with the person who wrote it.

The Terraform comparator's falsification runs on its own, and writes
nothing but its report. It takes a fixture, and defaults to the first:

```powershell
./evals/tf/Invoke-TfOracleFalsification.ps1
./evals/tf/Invoke-TfOracleFalsification.ps1 -Fixture fixture2
```

The sanitization gate is the same shape — a report, an exit code, and a
`-FailCheck` that proves it can fail before you believe a clean verdict:

```powershell
./evals/tf/Test-FixtureSanitization.ps1 -Fixture fixture2 -FailCheck
./evals/tf/Test-FixtureSanitization.ps1 -Fixture fixture1   # exits 1, and should
```

---

## 8. What this stack does not prove

Every figure below is from the root [README](../../README.md)'s *Status,
honestly* and [`method/METHOD.md`](../../method/METHOD.md)'s *Known
limits*. If you are weighing whether to copy this method, these are the
lines to weigh.

- **Conformity is not utility.** An artifact can satisfy every assertion
  and be useless. That is why there are two oracles, and it remains true of
  each of them separately.
- **The functional oracle covers one fixture.** One 15-pipeline fixture,
  and it contains a known contradiction — finding F-2, where the oracle's
  own `cases.md` justifies four repository nodes with a rule that produces
  three, so no implementation following the stated rule can satisfy it. It
  was recorded as a finding for a decision to repair; nothing under
  `evals/` was touched to make a run look better. See
  [run 006's findings](../../runs/006-plugin-on/findings.md).
- **The conformance suite is falsified against one reference module**;
  eleven of twelve controls stay green and the twelfth is documented as
  failing.
- **`Universal` has run against nine targets** — the reference plus an
  eight-module gallery corpus — and **seven of nine assertions survive all
  nine**. Both remaining failures are real properties of those modules
  rather than suite defects, carried in
  [`known-failures.json`](../../evals/conformance/baseline/known-failures.json).
  The corpus control does not pass clean: posh-git fails comment-based help
  on five exported commands. `Repository` and `HouseStyle` have been
  validated against one repository, and no target has yet been a repository
  built by this plugin.
- **Per-skill ablation is unmeasured.** Which of the fourteen skills the ladder measured
  carries the 19 → 33 is not known, and is the next question worth a run.
- **The baseline is one run and it was not allowed to iterate.** A second
  plugin-off run, permitted the same three iterations, is the missing
  control.
- **The builder is the same model family that wrote the skills.** None of
  the runs can separate reading the plugin from recalling the reasoning
  that produced it. What they measure is reliability at fixed inputs.
- **Run 006's prompt leaked** the prior runs' difference mechanisms into
  its own blind phase. Flagged and deliberately not acted on, and that
  run's first-shot number is stated as weakened in
  [its own record](../../runs/006-plugin-on/README.md).
- **The method is expensive up front.** Several passes produce a grader and
  no capability at all. `METHOD.md`'s own advice for a small project is the
  minimum: an oracle, falsification with controls, and a journal — skip the
  harness and the decisions log, and do not skip the corpus.

### Two places the records disagree with each other

Reading this stack end to end turned up two internal contradictions. They
are small and neither changes a score, but a page arguing for rigour should
not quietly tidy them away.

- **Eleven of twelve controls, or twelve of twelve.** The root README and
  [the suite README](../../evals/conformance/README.md) both say eleven of
  twelve controls stay green, and the suite README's account of row 7's
  failing control ends "Recorded, not yet fixed."
  [`FALSIFICATION.md`](../../evals/conformance/baseline/FALSIFICATION.md)
  says "All twelve are now correct; row 7's was failing until Pass 0008
  converted that assertion to AST", and
  [`TASK.md`](../../evals/conformance/TASK.md)'s Pass 0008 outcome agrees
  with it. The two summaries appear to predate the repair.
- **Five of ten, or seven of nine `Universal` assertions.** The suite
  README's *Validation status* paragraph says five of the ten `Universal`
  assertions survived all nine targets; its own *Known limits* section
  further down says seven of nine, as do
  [`UNIVERSAL-CORPUS.md`](../../evals/conformance/baseline/UNIVERSAL-CORPUS.md)
  ("up from five of ten") and the root README. Five-of-ten is the
  pre-repair figure, and
  [`evals/HARNESS.md`](../../evals/HARNESS.md)'s open questions carry it
  too.

Both are documentation drift rather than measurement error, and both are
the same thing as section 5's stale `ExpectedEdgeCount` assertion: a
statement about an artifact that stopped tracking the artifact. Which is,
in the end, the argument this whole page has been making.

---

## Where to go next

- The narrative, in order: the manual at
  [00-start-here](../creating-an-agent/00-start-here.md), and
  [03-test-first-or-nothing](../creating-an-agent/03-test-first-or-nothing.md)
  for this material as a story rather than a reference.
- How to check any of this rather than believe it:
  [05-calling-bullshit-verification](../creating-an-agent/05-calling-bullshit-verification.md)
  and [09-try-before-you-trust](../creating-an-agent/09-try-before-you-trust.md).
- Everything that went wrong and what it cost:
  [07-failure-catalog](../creating-an-agent/07-failure-catalog.md), and the
  thirteen hazards in [`evals/HARNESS.md`](../../evals/HARNESS.md).
- Terms defined once, in one place:
  [08-glossary](../creating-an-agent/08-glossary.md).
- Using this repository as a starting point for your own:
  [10-using-as-a-template](../creating-an-agent/10-using-as-a-template.md).
