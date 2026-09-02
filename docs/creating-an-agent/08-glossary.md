# Glossary

Every term of art this repository and this manual use, in plain English,
each with a link to somewhere it is used for real. Nothing here is defined
from a dictionary; every entry points at an artifact you can open.

The terms are **grouped by what they are for** and alphabetical inside each
group, because that is how you will look them up — you know you are trying
to understand "the thing that proves a check can fail", not that the word
begins with F. If you know the word already, use your browser's find.

Watch for the entries marked **counter-intuitive**. Several words in this
repository do not mean what the same word means elsewhere, and two of them
have cost real time: "green" is a *set* here, not a zero, and a "pass" is a
unit of work, not a test result.

---

## The people and the work

**agent.** A Claude Code process handed a prompt in a fixed format, a
repository it can read and write, and a definition of done that existed
before the work started. Not a chatbot and not autonomous: it does not
choose what to work on, decide when it is finished, or publish anything.
See: [00-start-here.md](./00-start-here.md), and
[PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) for the format it receives.

**backlog.** The numbered list of work the project knows it has not done,
kept in one file so it survives session restarts, with the operator free to
reorder it. Items enter it when a pass finds something real that is out of
its own scope — recording is not the same as fixing, and the repository
prefers a recorded gap to a silent one.
See: [LEDGER.md](../../LEDGER.md), the Backlog section.

**decision record.** An append-only note for a choice that outlives a single
pass, stating the context, the decision, and the alternatives rejected. A
pass may not quietly reverse one; it amends it, in the open.
See: [decisions/](../../decisions/), for example
[decision 0004](../../decisions/0004-plan-artifacts-are-frozen.md).

**definition of done.** The check that says the work is finished, written
*before* the work starts. This is the load-bearing idea of the whole method:
a definition of done written afterwards is written to fit the work, so
satisfying it proves only that the work satisfies a standard chosen by the
work.
See: [method/METHOD.md](../../method/METHOD.md) under Diagnosability, and
the `powershell-module-plan` skill in [skills/](../../skills/).

**deviations.** A required section of every plan, listing anything in the
prompt that was wrong, unclear or impossible, anything done differently and
why, anything discovered that the prompt did not ask about, and any
instruction followed that seems mistaken. Empty means writing "none", not
deleting the heading. The protocol calls it the most valuable section and
names four of the project's strongest findings as having come from it.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) section 10, and the
director's-mistakes group in
[07-failure-catalog.md](./07-failure-catalog.md).

**director.** The person who writes the prompts, decides what is measured,
and is the only one allowed to publish. This manual uses the word for the
role; **the repository's own artifacts call it the operator**, and the two
mean the same thing. The director is inside the system being measured, not
above it, which is why their mistakes are catalogued alongside the agent's.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md), which says throughout what
the operator does, and
[07-failure-catalog.md](./07-failure-catalog.md).

**executor.** The agent session that carries out one pass. This manual uses
the word to separate the two roles clearly; the repository's own artifacts
say "the pass" or "the agent" for the same thing. The distinction matters
because several findings are attributed to the prompt rather than to the
pass that executed it.
See: [journal 0014](../../journal/0014-seed-and-comparator.md), which
records a finding "attributed to the prompt rather than to the pass".

**journal.** One append-only entry per pass, written from that pass's
committed artifacts and never from memory, with six fields: Asked, Done,
Why, Measured, Learned, Capability. The **Learned** field is required to
include what went wrong.
See: [journal/](../../journal/) and its
[TEMPLATE.md](../../journal/TEMPLATE.md). The difference from a plan is set
out in [plans/README.md](../../plans/README.md): a plan is a receipt, a
journal entry is a citation.

**LEDGER.** The single file the agent maintains as the last task of every
pass, holding the counters and pins that the next session needs and cannot
recompute: which pass landed last, which run is next, the version numbers,
the pinned SHAs, and the backlog. It exists because a session restart clears
the conversation and not the repository.
See: [LEDGER.md](../../LEDGER.md).

**operator.** See **director**. This is the repository's own word.

**pass.** **Counter-intuitive.** One unit of work — one prompt, one plan,
one journal entry, one commit range — numbered by the operator. It does
**not** mean "a test that passed". Pass 0016 is a piece of work; a passing
assertion is a green. The repository has twenty-nine numbered passes in
[journal/](../../journal/).
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md), Pass numbering.

**pass number.** The four-digit number the operator assigns in the prompt
header, used for `plans/NNNN-<slug>/` and `journal/NNNN-<slug>.md` alike.
The agent never invents one; a prompt arriving without one is a stop.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md), Pass numbering.

**plan.** The per-pass file that makes the pass auditable: the prompt
verbatim, the preconditions with their output, the environment, the
red-first test, per-task evidence with commands, the transcript, the verify
script, deviations, and cost. It is written to be *disproved* and is
disposable once the pass is reviewed.
See: [plans/README.md](../../plans/README.md) and
[PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md).

**precondition.** A check run before any work, with its command and its
output recorded, whose failure stops the pass with nothing committed. The
project's finding is that a gate which stops a pass is cheaper than one that
does not: the same missing file once blocked a task silently and cost a
whole pass, and later stopped a pass loudly at precondition 4.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) section 2, and
[journal 0010](../../journal/0010-plan-protocol.md).

**red-first.** The rule that an acceptance test must be shown failing, with
its output recorded, before any work begins. A test that is already green
stops the pass: either the work is unnecessary or the test cannot fail, and
both are findings.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) section 4, and chapter
[03](./03-test-first-or-nothing.md).

**spot-check.** A named check the prompt asks the pass to perform and the
verify script must re-run by name, so that the operator can confirm the
specific thing they were worried about rather than a general green.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) section 9.

**tier (full / light).** **Counter-intuitive.** How much verification
apparatus a pass owes. **Full** — the pass changes executable behaviour and
owes preconditions, a red-first acceptance test, per-task evidence, a
transcript, a verify script, deviations and cost. **Light** — the pass
writes records only and owes everything except the acceptance test and the
verify script. The tier is decided by risk, not by volume: six documents and
no executable is light, six documents and one amended assertion is full.
Tier is a floor, never a ceiling, and a pass that believes its stated tier
is wrong says so and executes higher. The known gap: the tier system has no
axis for consequence *outside* the repository, so a pass that changed two
sentences and a pass that permanently repointed a deliverable's default
branch carry the same label.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md), Tiers, and
[journal 0019](../../journal/0019-history-unification.md).

**verify script.** `verify.ps1`, committed beside a full-tier plan. It
assumes nothing but a fresh clone and the tools, **re-derives rather than
reads** — it re-runs the suite and compares against the committed result
JSON, and never parses the plan — re-runs every named spot-check, and exits
non-zero naming which check disagreed. It exists so the operator can
disprove the plan without reading it, and it is written to be capable of
failing.
See: [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) section 9. It gets the same
scrutiny as the thing it verifies —
[journal 0026](../../journal/0026-run-004.md) records two defects in one.

---

## The instruments

**absence case.** A test case asserting that something is **not** in the
answer — here, that a repository nothing references is not a node in the
graph. Harder to name and to falsify than a presence case, because nothing
in the expected answer can carry its marker without asserting the opposite
of the case.
See: [journal 0014](../../journal/0014-seed-and-comparator.md) and
[fixture/cases.md](../../evals/functional/fixture/cases.md).

**assertion.** One checkable claim, expressed as a Pester `It` block. The
unit the conformance suite is built from and the unit falsification is
performed against. An assertion does not count until it has a falsification
row.
See: [Conformance.Tests.ps1](../../evals/conformance/Conformance.Tests.ps1)
and [method/METHOD.md](../../method/METHOD.md).

**Bucket A / Bucket B.** How a failure is classified once the grader has
run. **Bucket A** — the grader is wrong; the assertion tested the wrong
thing or was written wrongly, and it gets fixed. **Bucket B** — the grader
is right and the target genuinely has the defect; it becomes a recorded
finding and the assertion is never weakened to make it go away.
**Counter-intuitive:** the sort is *not automatable* and the project settled
that in the negative, because the same assertion failing the same way is
Bucket A on one target and Bucket B on another. The harness presents
failures for sorting with enough context to sort quickly; it does not
classify.
See: [evals/HARNESS.md](../../evals/HARNESS.md), "Bucket A/B sorting is not
automatable", and
[FINDINGS.md](../../evals/conformance/baseline/FINDINGS.md).

**case.** One numbered thing the fixture is designed to exercise — a cycle,
a diamond, an unresolvable alias, a repository nothing references. The
functional score is stated over cases, and the final surface of the module
is "whatever the twelve cases require".
See: [fixture/cases.md](../../evals/functional/fixture/cases.md) and
[BRIEF.md](../../evals/functional/BRIEF.md).

**cases-defined.** The denominator that cannot move with the target: the
number of distinct assertions the suite *defines*, parsed out of the suite's
own source by AST, with no file of the target read and no `-ForEach`
expanded. Three differently shaped targets read 33, 33 and 33 on it.
See: [journal 0025](../../journal/0025-findings-batch.md).

**cases-run.** **Counter-intuitive.** The number of test cases actually
executed, which depends on the *shape of the target*: an assertion iterating
over public functions makes seven cases against a module with seven commands
and two against a module with two. Two builds of the same module reported 57
and 55, so cases-run figures from different targets are not two points on
one scale.
See: [decision 0003](../../decisions/0003-score-comparability.md).

**comparator.** The script that scores a produced graph against the oracle
and reports the differences by mechanism. It is itself falsified, by
mutating the expected graph one way at a time and confirming the comparator
notices.
See: [Compare-Graph.ps1](../../evals/functional/Compare-Graph.ps1) and
[Mutate-Graph.ps1](../../evals/functional/Mutate-Graph.ps1).

**conformance suite.** The **shape** oracle: a Pester suite that decides
whether a module repository meets the conventions the plugin teaches.
Nothing in it imports or executes the module under test — every assertion
reads the source tree, the manifest, the build file or the generated module
as text, because a suite that has to run the target's build code can be made
to pass by a target that breaks it.
See: [evals/conformance/README.md](../../evals/conformance/README.md).

**corpus.** A set of artifacts you did **not** make, used to break the
closed loop. Here it is eight dissimilar published PowerShell modules,
fetched and lock-verified, none of them committed. It is the cheapest part
of the method when one already exists: it cost one pass and invalidated five
of the ten assertions in the tag it tested.
See:
[UNIVERSAL-CORPUS.md](../../evals/conformance/baseline/UNIVERSAL-CORPUS.md)
and [method/METHOD.md](../../method/METHOD.md), Known limits.

**denominator.** The bottom half of a score. It is a live variable here, not
a constant, and a repair that lets an assertion reach more of a target
changes it. Note the direction of the risk: an assertion that silently stops
producing cases makes a score go **up**.
See: [decision 0003](../../decisions/0003-score-comparability.md).

**fixture.** The hand-built world the target is measured against: fifteen
Azure DevOps pipeline definitions across several repositories, with cycles,
diamonds, cross-repository templates and one repository nothing references.
It is **frozen** once its oracle is falsified against it, and re-freezing
requires a decision record.
See: [evals/functional/fixture/](../../evals/functional/fixture/),
[AZDO-FIXTURE.md](../../evals/functional/AZDO-FIXTURE.md), and
[decision 0012](../../decisions/0012-fixture-case3-repair.md) for a
deliberate amendment.

**functional oracle.** The **behaviour** oracle, as distinct from the shape
one: a hand-written expected graph plus the comparator that scores a
candidate against it. Conformance says the module is built correctly;
the functional oracle says it produces the right answer.
See: [expected-graph.json](../../evals/functional/fixture/expected-graph.json)
and [evals/functional/](../../evals/functional/).

**gate.** A check that stops something from shipping — a coverage
threshold, a lint task, a pre-tag seal. **Counter-intuitive:** asserting that
a gate is *declared* is a different claim from asserting that it *can fail*,
and the first is routinely mistaken for the second because both go green.
For every gate, name the observation that would be different if the gate
were removed, and produce it.
See: [method/METHOD.md](../../method/METHOD.md), the falsification harness
section, and the "gates that could not fail" group in
[07-failure-catalog.md](./07-failure-catalog.md).

**known-failure set.** **Counter-intuitive.** The explicit, checked-in
*set* of failure names that a healthy run is allowed to produce — because a
real target has standing findings, and "zero failures" is not a state any
real target is in. It ratchets both ways: a failure not in the file is new
and blocks, and an entry that stops failing is stale and also blocks.
Critically, it is **declared, not derived** — deriving it from the previous
run makes a bad run the next run's definition of good.
See: [evals/HARNESS.md](../../evals/HARNESS.md) hazard 2, and
[known-failures.json](../../evals/conformance/baseline/known-failures.json).

**oracle.** The declared right answer, written before the thing being graded
exists. Everything in this method hangs off having one: where output cannot
be checked by a program there is no oracle, the method degrades to rubrics
and blind comparison, and you get the ceremony without the signal. The rule
that keeps it honest is **never edit the oracle to fit** — when a run found
that the fixture's case document justified four nodes with a rule producing
three, nothing under `evals/` was touched and it was recorded as a finding.
See: [method/METHOD.md](../../method/METHOD.md), the Precondition section,
and [README.md](../../README.md), Guardrails.

**reference implementation.** The existing, human-written module the
conventions were extracted from, held read-only. **Counter-intuitive:** on
its own it is a closed loop — rules extracted from it, enforced by a grader
derived from it, verified against output built to satisfy it, prove only
self-consistency. A second dissimilar target is required before any claim of
generality.
See: [method/METHOD.md](../../method/METHOD.md), Evidence discipline.

**score.** A pair of numbers, never a percentage on its own: cases-passed
over cases-run, and here also over cases-defined. Percentages are compact,
comparable-looking, and the thing a reader remembers, which is exactly why
the decision record insists on both figures side by side.
See: [decision 0003](../../decisions/0003-score-comparability.md).

**seed.** The minimal starting state a measured run is reset to before it
begins — here four files, materialised into a fresh repository by a script.
**Counter-intuitive:** the seed *tree* is identical in every run and
is the thing pinned; the seed *commit* SHA is irreproducible by design,
because the reset script stamps wall-clock dates, so a check written against
the commit SHA fails for a reason that is not about the seed.
See: [Reset-Target.ps1](../../evals/functional/Reset-Target.ps1) and
[LEDGER.md](../../LEDGER.md), backlog item 16.

**tag.** A label on a conformance assertion saying how universal its claim
is: `Universal` (true of any PowerShell module), `Repository` (true of any
module repository), `HouseStyle` (this project's convention), `RequiresBuild`
(needs a built artifact). Promotion up that ladder is a *claim* and requires
evidence from a second dissimilar target.
See: [evals/conformance/README.md](../../evals/conformance/README.md).

**target.** The repository being measured. Never the operator's working
checkout — a scratch clone at a known commit, because the clone's *location*
is itself a variable that has to be handled.
See: [evals/HARNESS.md](../../evals/HARNESS.md), "What a run consists of".

---

## Proving a check can fail

**break.** The single deliberate defect injected into a target so you can
find out whether an assertion notices. One break per row, applied to a
confirmed-clean clone, with the clone restored and re-verified afterwards.
**Every break must assert that it actually changed the file before the
grader is re-run** — a substitution that matches nothing leaves the target
intact and the row records "does not fire".
See: [evals/HARNESS.md](../../evals/HARNESS.md), hazard 4.

**control.** A falsification row where the break is one the named assertion
must **not** notice, so the expected result is that the assertion stays
**green**. Without a distinct outcome type for it, a control's correct
result is recorded as "does not fire" and reads as a failure. A green
control is a positive result, not a non-result.
See: [evals/HARNESS.md](../../evals/HARNESS.md) hazard 7, and
[CONTROL-SWEEP.md](../../evals/conformance/baseline/CONTROL-SWEEP.md).

**falsification.** The practice of proving a check can fail before you
believe that it passed: break the thing the check guards, confirm red,
restore, confirm clean, and write down what you broke and what happened.
See: [method/METHOD.md](../../method/METHOD.md), the grader and the
falsification harness, and chapter
[09](./09-try-before-you-trust.md).

**falsification row.** One recorded break: the assertion it targets, the
exact perturbation, the outcome, and the restore. **An assertion does not
count until it has one.** Any assertion added or changed gets a break, a
confirmed red and a restore before any score including it is recorded.
See:
[FALSIFICATION.md](../../evals/conformance/baseline/FALSIFICATION.md).

**fires / does not fire / over-fires / correctly stays green.** The four
outcomes a falsification row can have. *Fires* — the expected assertion goes
red and nothing else does. *Does not fire* — the assertion stayed green
through its own break; **the finding that matters most, and the one a
careless harness reports as success.** *Over-fires* — other assertions went
red too; name them, because it is sometimes correct coupling and sometimes a
defect. *Correctly stays green* — a control behaved.
See: [evals/HARNESS.md](../../evals/HARNESS.md), "Falsification: what the
harness runs".

**green / red.** Green means a check passed; red means it failed.
**Counter-intuitive:** in a measured run, "green" does not mean zero
failures. It means the failure set matched the checked-in known-failure set
**by name**. A harness that checks for a count will happily proceed when one
failure is silently swapped for a different one.
See: [evals/HARNESS.md](../../evals/HARNESS.md), hazard 2.

**hard stop.** An abort, as opposed to a warning. Used deliberately: a
warning is indistinguishable from noise in a run that prints a hundred
lines, so the preflight that resolves expected assertion names against the
grader's real names stops the run rather than logging.
See: [evals/HARNESS.md](../../evals/HARNESS.md), hazard 6.

**hazard.** One of the eleven numbered failure modes in the harness
specification, each written from something that actually bit, with the
failure it produces and the requirement it imposes. They are not a list of
things that might in principle go wrong.
See: [evals/HARNESS.md](../../evals/HARNESS.md), "The hazards".

**inert assertion.** An assertion that cannot fail — it passes every run for
free, contributes a point to every score, and tests nothing. It is
indistinguishable from a working assertion by reading, and the only thing
that separates them is a confirmed red. The project has found several; the
first is written up as Row 8.
See: [journal 0005](../../journal/0005-establish-the-baseline.md) and
[07-failure-catalog.md](./07-failure-catalog.md).

**mutation.** The falsification technique used on an oracle rather than on a
target: change the *expected* answer one way at a time and confirm the
comparator reports the difference. **Counter-intuitive:** a mutation that
changes nothing is the failure mode of a falsification set, so every
mutation proves it changed the document first — and one of them changes the
document without changing its length, so the proof has to compare text
rather than size.
See: [journal 0023](../../journal/0023-tf-fixture.md) and
[Mutate-Graph.ps1](../../evals/functional/Mutate-Graph.ps1).

**polarity.** Whether an assertion is *positive* (must match X) or *negative*
(must not match X). It decides the shape of the control: for a positive
assertion, remove X and leave text resembling X, and the assertion must go
red; for a negative assertion, add text mentioning X without the behaviour,
and it must stay green. For a negative assertion the two control types
collapse into one probe; for a positive assertion they are independent
questions and neither implies the other.
See: [evals/HARNESS.md](../../evals/HARNESS.md) and
[method/METHOD.md](../../method/METHOD.md).

**probe.** A break plus its expectation, run as one row. Used
interchangeably with "row" in the records. The recurring failure is a probe
that silently fails to apply and reports the check it never exercised as
falsified.
See: [evals/HARNESS.md](../../evals/HARNESS.md), hazard 6.

**scope control.** The control that adds text *mentioning* X while the
behaviour is still present, and requires the assertion to stay **green**. It
guards against matching too much — an assertion that fires on a comment, a
neighbour, or a mention. **Counter-intuitive:** on its own it is the weaker
of the two, because a comment cannot break a positive assertion while the
code is still there, so a scope control passes an assertion that is wholly
inert.
See: [method/METHOD.md](../../method/METHOD.md), the grader section.

**substitution control.** The control that removes the behaviour and leaves
text resembling it, and requires the assertion to go **red**. It guards
against inertness. Twelve assertions in this project passed a scope control
and failed a substitution control.
See: [method/METHOD.md](../../method/METHOD.md), the grader section.

---

## Running a measured run

**ablation.** Removing one component to find out how much of the measured
effect it carried. The fourteen skills the ladder measured have not been ablated, so
which of them carries the shape improvement is unknown, and it is recorded
as unmeasured rather than attributed.
See: [LEDGER.md](../../LEDGER.md), backlog item 18.

**allowlist.** The explicit list of files a blind run's session is permitted
to read. Everything outside it is forbidden, and a read outside it is
declared rather than quietly taken. **Counter-intuitive:** a run's own
*prompt* is inside its allowlist, so a prompt that quotes a previous run's
findings has leaked oracle knowledge into the blind phase.
See: [evals/HARNESS.md](../../evals/HARNESS.md) hazard 9, and
[journal 0028](../../journal/0028-run-006.md).

**blind run.** A measured run whose session has read nothing that could
contain the answer. Run records are oracle knowledge in prose — a run README
states the score, the difference count and often the exact field conventions
the oracle wants — so **a session that has read anything under `runs/` is
disqualified as a blind builder**, whatever else it does. A measured run's
prompt is therefore the first message of a brand-new session.
See: [evals/HARNESS.md](../../evals/HARNESS.md), hazard 9, and chapter
[04](./04-fresh-sessions-and-contamination.md).

**finding (F-number).** A numbered, recorded observation from a run about
the *instrument* — the plugin, the brief, the skills — as opposed to a
defect in the run's own output. F-1 is the coverage-gate template that
cannot fail; F-2 is the repository-node rule that is short by one node.
Eight of the ten findings from the first two ladder runs recurred in the
third, in a session that had not read either record.
See: [runs/006-plugin-on/findings.md](../../runs/006-plugin-on/findings.md)
and the findings table in [README.md](../../README.md).

**first-shot / final.** Two scores from the same run. **First-shot** is what
the blind build produced before any feedback from the oracle. **Final** is
what it reached after the permitted iterations. They answer different
questions, and mixing them flatters the result: the honest comparison
between the plugin-off and plugin-on runs is the first-shot row, which is
nearly flat, not the final row, which the plugin-off run was never permitted
to have at all.
See: [README.md](../../README.md), "With the plugin and without it".

**iteration.** One permitted cycle of scoring, reading the differences, and
fixing. The ladder runs allowed up to three and used one, one and two. The
run that needed two needed it because its single iteration introduced a
regression the others did not have.
See: [runs/006-plugin-on/findings.md](../../runs/006-plugin-on/findings.md),
F-12.

**ladder.** The series of consecutive blind runs at a fixed seed, brief,
plugin SHA and model version, run to find out whether the result reproduces.
Its headline result is reliability: three sessions produced the same 26
first-shot differences by the same four mechanisms at the same counts.
See: [README.md](../../README.md) and [LEDGER.md](../../LEDGER.md), Runs.

**PAT.** Personal Access Token — the bearer credential for an Azure DevOps
organisation. Handled by one rule with no exceptions: it lives in an
environment variable and nowhere else. Never a parameter, never a file,
never in a URL, because a value passed as a parameter reaches shell history,
transcript output and the script-block logging event log. Every run scans
its own artifacts, clones and tracked blobs for it **by value** before
committing.
See: [README.md](../../README.md), Guardrails, and the `azdo-rest` skill in
[skills/](../../skills/).

**Phase 0 / Phase 1.** The two halves of a run. **Phase 0** asks whether the
target builds at all, and gates on it: a conformance failure against a
target that does not build is unattributable, because a suite bug and a
genuine divergence look identical. **Phase 1** is the blind build itself,
timed.
See: [evals/HARNESS.md](../../evals/HARNESS.md), "What a run consists of",
and [PHASE0.md](../../evals/conformance/baseline/PHASE0.md).

**pin.** A recorded exact value — a commit SHA, a tree hash, a model version
— that a later run asserts is unchanged, so that a difference between runs
is attributable. **Counter-intuitive:** a pin can go stale in a way that
makes a correct run stop, which is a failure of the pin and not of the
instrument. The ladder's instrument pin covered four paths, one of which
later received a sanctioned documentation change, so the pin was amended to
the three paths that name the plugin proper.
See: [LEDGER.md](../../LEDGER.md), the Pins section.

**plugin.** The Claude Code plugin distilled from what the harness measured:
a manifest, seventeen skills and two commands. It is deliberately *not* the
interesting artifact in this repository — the measurement is.
See: [.claude-plugin/](../../.claude-plugin/), [skills/](../../skills/),
[commands/](../../commands/), and [README.md](../../README.md).

**run.** **Counter-intuitive.** One scored build of the target against the
fixture — not the same thing as a **pass**. A pass is a unit of work on
*this* repository; a run is a measurement of the *target*. They are numbered
in separate sequences, and one pass usually conducts one run.
See: [runs/README.md](../../runs/README.md).

**run record.** The directory holding everything one run produced: the
graph, the render, the diff against expected, the result JSON, the findings,
and a README saying what command produced it. A run is never deleted or
edited because its answer was bad — a sequence of runs with the failures
removed is not evidence of anything.
See: [runs/README.md](../../runs/README.md) and, for example,
[runs/003-baseline-off/](../../runs/003-baseline-off/).

**session identifier.** A unique value recorded in each measured run's
record, so that "three blind sessions" is checkable rather than asserted.
The three ladder runs carry three pairwise-distinct ones.
See: [evals/HARNESS.md](../../evals/HARNESS.md) hazard 9, and
[journal 0028](../../journal/0028-run-006.md).

**skill.** A markdown document of judgment-shaped guidance that the agent
loads when it is relevant — as distinct from a script, which is for
deterministic work, a subagent, which is for noisy or capability-restricted
work, and a hook, which is for must-never-happen. Choosing prose for
deterministic work is the most common error.
See: [skills/](../../skills/), the roster in [README.md](../../README.md),
and [method/METHOD.md](../../method/METHOD.md), Mechanism selection.

---

## Method vocabulary

**capability, not benefit.** The rule that a journal entry records what is
now *possible* that was not, rather than what the project will *gain*.
Benefit claims written mid-project are predictions, and several will be
wrong; the summary is written once at the end, from the journal.
See: [method/METHOD.md](../../method/METHOD.md), Records.

**closed loop.** A measurement in which the rules, the grader and the output
all descend from the same source, so agreement proves only self-consistency.
Breaking it requires a second dissimilar target you did not make.
See: [method/METHOD.md](../../method/METHOD.md), Evidence discipline.

**observed versus inferred.** The discipline of marking which claims were
measured and which were reasoned. Anything claimed from a single target is a
hypothesis with an evidence count attached, not a fact — which is why the
harness carries explicit "**Evidence: 1 target**" notes inline.
See: [method/METHOD.md](../../method/METHOD.md) and
[evals/HARNESS.md](../../evals/HARNESS.md), hazards 3 and 5.

**PORTABLE / TUNE / DOMAIN.** The three-way marking on every rule in the
method file. **PORTABLE** — survives a domain change unedited; copy as-is.
**TUNE** — right shape, wrong specifics; keep the structure and replace the
nouns. **DOMAIN** — does not travel; listed so it is visible as something to
replace rather than silently inherited. If you are lifting this method for
your own project, this marking is the map.
See: [method/METHOD.md](../../method/METHOD.md), and chapter
[10](./10-using-as-a-template.md).

**prevalence is not correctness.** The rule that a check most targets fail
is either wrong, or the targets are, and evidence about the rule decides —
not the failure rate. Two assertions here had near-identical pass rates and
went opposite ways.
See: [method/METHOD.md](../../method/METHOD.md), the grader section.

**zero cases is not a pass.** **Counter-intuitive, and the most easily
missed rule in the method.** An assertion that produced no cases did not
pass; it was inapplicable, and it must report as such. The same reasoning
applies one level up: a falsification run that selected zero rows is not a
clean run either.
See: [method/METHOD.md](../../method/METHOD.md) and
[evals/HARNESS.md](../../evals/HARNESS.md), hazard 6.

---

## PowerShell and tooling, for readers who do not write PowerShell

You do not need any of this to follow the method. It is here so that the
worked examples in the other chapters do not stop you.

**AST.** Abstract Syntax Tree — the parsed structure of a script, as opposed
to its text. Reading the AST is how an analyzer inspects code without
running it, and it is how `cases-defined` counts assertions without
consulting the target.
See: the `powershell-module-analyzer` skill in [skills/](../../skills/).

**comment-based help.** PowerShell's convention of documenting a function in
a specially formatted comment block above it, with fields such as
`.SYNOPSIS`. Several conformance assertions read it.
See: the `powershell-module-docs` skill in [skills/](../../skills/).

**culture directory.** A folder such as `en-US/` holding external help,
which the build must copy into the output. One run shipped without one, so
one assertion graded nothing and was reported skipped rather than passed —
the event that made `cases-defined` earn itself.
See: [journal 0027](../../journal/0027-run-005.md).

**dev loader.** A committed module file that lets a repository be imported
from source without building first. It exists because the standard manifest
pattern names a module file the build generates, so a fresh clone cannot be
imported until it is built — which surprises consumers and acceptance tests
alike.
See: [journal 0022](../../journal/0022-tohtml-contract.md) and
[LEDGER.md](../../LEDGER.md), backlog item 10.

**InvokeBuild.** The task-runner this project's build files are written for.
"The default task" means what runs when you invoke the build with no task
named; a **sealing task** such as `PreTag` is deliberately excluded from it.
See: the `powershell-module-build` skill in [skills/](../../skills/).

**manifest (`.psd1`).** The data file declaring a module's name, version,
dependencies and — critically for this project — exactly which functions it
exports. Its base name must equal its directory name, and ambiguity about
which manifest is the module's is the source of the misgrade lineage in the
failure catalog.
See: [evals/conformance/README.md](../../evals/conformance/README.md).

**Pester.** The PowerShell test framework. `Describe` groups tests, `It` is
one assertion, `BeforeAll` sets up, `-ForEach` parameterises one `It` over
many inputs, and `-Tag` selects subsets. **Counter-intuitive:** the tag
filter is an **OR**, so a block carrying two tags runs under either.
See: [Conformance.Tests.ps1](../../evals/conformance/Conformance.Tests.ps1)
and the `powershell-module-test` skill in [skills/](../../skills/).

**PreTag.** By convention here, the task and test tag for checks that seal a
release — the things that must be true before a version is tagged. It is
excluded from the default task on purpose, which is exactly why it can rot
unnoticed: two separate repositories declared it with no test carrying the
tag, so it could only ever fail its own zero-test guard.
See: [journal 0022](../../journal/0022-tohtml-contract.md) and
[journal 0025](../../journal/0025-findings-batch.md).

**`psm1` / root module.** The single module file a build generates by
concatenating the source functions. Several assertions read it, which is why
deleting build output invalidates every build-dependent row.
See: [evals/HARNESS.md](../../evals/HARNESS.md), hazard 1.

**PSScriptAnalyzer.** The PowerShell linter. **Counter-intuitive:** its
`Severity` setting, written the way every example shows it, filters out
`ParseError` — which is its own severity — so a lint gate can report clean
on a file that does not parse at all.
See: [journal 0016](../../journal/0016-first-build.md).

**`Public/` and `Private/`.** The convention that exported functions live
one-per-file in `Public/` and internal ones in `Private/`, which may nest.
Six of the eight corpus modules have no `Public/` directory, which is how an
assertion scoped to it came to produce zero cases.
See: [journal 0007](../../journal/0007-controls-tag-split-corpus.md).

**StrictMode.** A PowerShell setting that turns silent nulls into errors.
Useful, and a source of surprises: reading an absent manifest key throws
under it, and several single-item collection operations throw under it that
work otherwise.
See: [journal 0007](../../journal/0007-controls-tag-split-corpus.md) and
[runs/006-plugin-on/findings.md](../../runs/006-plugin-on/findings.md), F-13.

---

## Where to go next

If a term sent you here from the failure catalog, go back to
[07-failure-catalog.md](./07-failure-catalog.md) — the entries are where
these words were earned. If you are here early, chapter
[00](./00-start-here.md) sets out the loop these terms describe, and chapter
[02](./02-order-of-operations.md) puts them in the order you will meet them.
