# 02 — Order of operations

You are building two things, not one: an agent that produces something, and
an instrument that says whether what it produced is right. The order you
build them in decides what your numbers are worth at the end. Build the
instrument second and you will have scores nobody can attribute to anything;
build it first and never break it on purpose, and you will have scores that
are worse than none, because they look like evidence.

This chapter is the build order, numbered, with this repository's real pass
numbers beside each stage. Every stage links the pass that did it, so you can
read what actually happened rather than take the ordering on trust.

## Two words you need first

A **pass** is one unit of work in this repository: one prompt, one directory
under `plans/`, one entry under `journal/`, all sharing a four-digit number.
The format is [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md). Plans are
verification and are disposable; journal entries are narrative and permanent
— [plans/README.md](../../plans/README.md) sets out the difference.

An **oracle** is a declared right answer, written by hand, that a produced
artifact is compared against. Two live in this repository: a *conformance
suite* that grades an artifact's shape, and a *fixture* plus a hand-written
graph that grade its behaviour.

## Why the order is the method

Before any of it, check the precondition.
[METHOD.md](../../method/METHOD.md) opens by asking whether the method
applies at all: it depends on the agent's output being machine-checkable. A
PowerShell module either builds, lints and exports what its manifest claims,
or it does not. Where output cannot be checked by a program — copy, design,
strategy, most writing — there is no oracle, and the method degrades to
rubrics and blind comparison. Decide that first. If the answer is no, use a
different method.

Given a yes, two rules under METHOD.md's *Sequencing* heading generate the
whole order:

> Nothing is added until there is a way to tell whether it worked. The grader
> comes before the first capability, so every capability can be judged by the
> score it moves.

> Establish a baseline with zero capabilities before adding the first one.
> What the bare model achieves is what every addition must beat.

Everything below is those two sentences with the work filled in.

---

## 1. Definition of done, written before anything is built

If you cannot say what "done" looks like before you start, you will decide it
afterwards — and you will decide it in a form that whatever you happened to
build satisfies. Writing it first is the only cheap moment: at that point you
have no work to protect.

"Done" is a file, not an intention. In this repository it is two files. The
brief, [evals/functional/BRIEF.md](../../evals/functional/BRIEF.md), states
what the module is for and what its command surface is, and says in its own
opening that nothing in it is a conformance assertion — the shape grader and
the behaviour grader are held apart from the first sentence. The case list,
[evals/functional/fixture/cases.md](../../evals/functional/fixture/cases.md),
states twelve claims about a correct answer, and each case names the specific
wrong implementation it catches, because "a case that no plausible wrong
implementation fails is a case that cannot discriminate, and is worth
nothing."

The general form of the rule lives in the pass protocol, written at pass 0010
([plan](../../plans/0010-plan-protocol/plan.md),
[journal](../../journal/0010-plan-protocol.md)): a pass that changes
executable behaviour requires an acceptance test that was **red before the
work began**. [Chapter 03](./03-test-first-or-nothing.md) is about that rule
and why it is the load-bearing one.

## 2. A conformance suite — and falsified, not merely written

The grader comes before the first capability, so that every capability can be
judged by the score it moves. But a grader you have only *written* is not yet
a grader. Until you have broken the thing an assertion is about and watched
that assertion go red, a green tells you nothing: a working assertion and an
assertion that cannot fail produce identical output on a good target.

That is why this stage is seven passes long and produces no capability at
all:

- **0002** authored the suite — 33 `It` blocks across six `Describe` blocks,
  reading the source tree, manifest, build file and generated module as text,
  never importing or executing the module.
  [journal](../../journal/0002-first-conformance-suite.md)
- **0004** fixed five defects in it, including a manifest resolver that
  tie-broke on shortest path and so graded a vendored module rather than the
  repository's own. [journal](../../journal/0004-five-suite-fixes.md)
- **0005** ran the first falsification: twelve breaks, of which ten fire
  cleanly, one over-fires, and one **does not fire at all**.
  [journal](../../journal/0005-establish-the-baseline.md),
  [FALSIFICATION.md](../../evals/conformance/baseline/FALSIFICATION.md)
- **0006** rewrote the assertion that could not fire, and proved the
  replacement with two reds and one control that had to stay green.
  [journal](../../journal/0006-fix-the-inert-assertion.md)
- **0007** gave every row a control, ran the suite against an eight-module
  corpus, and found that the corpus's designated control module failed the
  tag. [journal](../../journal/0007-controls-tag-split-corpus.md),
  [UNIVERSAL-CORPUS.md](../../evals/conformance/baseline/UNIVERSAL-CORPUS.md)
- **0008** repaired the tag against that corpus evidence rather than against
  taste. [journal](../../journal/0008-repair-universal-tag.md)
- **0009** swept every positive assertion with a polarity-correct control —
  22 probes, three of which exposed defects that twelve earlier controls had
  missed. [journal](../../journal/0009-correct-the-control-protocol.md),
  [CONTROL-SWEEP.md](../../evals/conformance/baseline/CONTROL-SWEEP.md)

Note what those passes are not: none of them makes the agent better at
anything. METHOD.md says so under *Known limits* — the method "is expensive
up front. Several passes produce a grader and no capability." That cost is
the price of every number that comes later.

## 3. A fixture, a hand-written oracle, and a comparator

Shape is not behaviour. A conformance suite can tell you the artifact looks
like a module — manifest, layout, build file, exports. It cannot tell you the
module answers the question correctly. For that you need a fixture with a
declared right answer, and a comparator that scores a candidate against it.

Two properties matter more than the fixture's size. First, the oracle is
**hand-written**. An oracle generated by the thing under test is a mirror,
and it will agree with any answer that thing gives. Pass 0011 wrote 49 nodes
and 51 edges by hand from 30 YAML files rather than deriving them, and
rejected checking the fixture with a resolver on the grounds that "an oracle
checked by a resolver is worth exactly what the resolver is worth."

Second, the comparator's ability to *detect* is proved by mutation, not
assumed. Pass 0014 wrote `Mutate-Graph.ps1` with one mutation per case, each
derived from that case's own "How a naive implementation fails" paragraph and
carrying the sentence it came from — and it refuses to emit a mutation that
changed nothing, so a probe cannot silently fail to apply. Journal 0014's
reason for the design is worth memorising: "A hand-written wrong graph tests
whether the comparator agrees with the person who wrote it. One generated
from the oracle by a named mutation tests whether it detects the failure the
fixture was built to catch."

The four passes:
[0011 fixture design](../../plans/0011-fixture-design/plan.md)
([journal](../../journal/0011-fixture-design.md)),
[0012 case split](../../plans/0012-case-split-and-corrections/plan.md) —
which added an *absence* case, a claim about what must **not** appear —
[0013 create the fixture](../../plans/0013-create-fixture/plan.md), and
[0014 the seed and the comparator](../../plans/0014-seed-and-comparator/plan.md)
([journal](../../journal/0014-seed-and-comparator.md)).

## 4. Seed and reset, so a run starts from a known state

A run that starts in a directory somebody has been working in measures the
directory. You need one command that puts the target back to a known,
minimal state, and you need it before you take any measurement you intend to
compare against another.

Pass 0014 wrote it. `evals/functional/seed/` holds the starting files, and
[Reset-Target.ps1](../../evals/functional/Reset-Target.ps1) materialises them
into a run directory, initialises git and commits once. It refuses any
destination outside `scratch/runs/`, and it compares resolved paths rather
than raw strings. The journal's reason: "A prefix test on the raw text
accepts `scratch/runs/../../../PSAzureDevOpsGraph`. The accident being
prevented is a mistyped path, and a mistyped path does not read
documentation."

Starting a run is one command:

```powershell
./evals/functional/Reset-Target.ps1 -Destination scratch/runs/007-my-run
```

One hazard from this repository is worth copying along with the script. Reset
stamps wall-clock dates, so the seed *commit* SHA differs in every run — 004,
005 and 006 each got a different one — while the seed *tree* is identical in
all three. Pin the tree, not the commit; a check written against the commit
SHA fails for a reason that has nothing to do with the seed.
[LEDGER.md](../../LEDGER.md), backlog item 16.

## 5. The plugin-OFF baseline

Now, and not before, you measure what the bare model does: no skills
readable, the same seed, the same brief, the same scoring. This is the number
every later addition has to beat, and you get one honest chance at it,
because the moment you have written a skill you can no longer un-know it.

Pass 0020 did this as run 003:
[plan](../../plans/0020-baseline-off/plan.md),
[journal](../../journal/0020-baseline-off.md),
[run record](../../runs/003-baseline-off/README.md). Conformance 39 / 55
cases-run at the time, functional 0 / 12, 29 differences, 32.6 minutes of
blind build.

The protocol around the number matters as much as the number. The prompt said
one attempt, no score-and-retry, and the pass explicitly rejected a one-line
fix that would have addressed fifteen of the twenty-nine differences: "a
baseline that is quietly improved before being written down measures the
improver, not the baseline." It also rejected repairing a grader defect it
found *while being scored by it*, because changing the grader mid-measurement
would have broken comparability with the run before it — the rule in
[decision 0003](../../decisions/0003-score-comparability.md).

Be as honest about your baseline's limits as this repository is about its
own. Run 003 was never permitted to iterate, so the with-and-without table
has no plugin-off final column and cannot have one. That missing control is
[LEDGER](../../LEDGER.md) backlog item 17, recorded as the highest-value
single run remaining.

## 6. The findings-to-skills batch

**Why 5 must come first.** A skill written before the baseline is a guess
about what the model gets wrong. You can write a dozen of them, watch the
score go up, and be unable to say which one moved it — or whether the model
could always do that and the skill changed nothing. The baseline is the
denominator of every claim this stage makes.

Skills are written *from* measured failures. Pass 0025 took a run's recorded
findings and landed them: two producer defects fixed, one fixture case
repaired under a decision record, four findings folded into skills, and the
roster taken from 13 skills to 14.
[plan](../../plans/0025-findings-batch/plan.md),
[journal](../../journal/0025-findings-batch.md).

The same pass is this repository's best example of a skill deliberately
**not** written. Three domain skills had been proposed by the preceding run;
writing them would have baked that run's specific answers into the plugin
before the blind measurement against the same fixture, which "measures the
plugin's memory of tf-001 rather than its generality." They were recorded in
the [LEDGER](../../LEDGER.md) backlog as an operator decision, recorded and
not taken. If you take one habit from this stage, take that one: a skill that
encodes the answers to the test you are about to sit is not a capability.

## 7. The measurement ladder

**Why 6 must come first, and must then stop.** A ladder is N consecutive
blind runs at *fixed inputs*: same seed, same brief, same pinned plugin
commit, same pinned model version, each in a distinct session — the session
rule has a chapter of its own,
[04](./04-fresh-sessions-and-contamination.md). The ladder's whole value is
that when two rungs differ, the difference is information about the
instrument rather than noise. Change a skill halfway up and you no longer
have a ladder; you have two single runs of two different things.

This repository's ladder is three rungs — passes 0026, 0027 and 0028,
recorded as runs 004, 005 and 006:

| | [004](../../runs/004-plugin-on/README.md) | [005](../../runs/005-plugin-on/README.md) | [006](../../runs/006-plugin-on/README.md) |
|---|---|---|---|
| conformance (cases-defined) | 33 / 33 | 33 / 33 | 33 / 33 |
| functional, first shot | 1 / 12 | 1 / 12 | 1 / 12 |
| functional, final | 12 / 12 | 12 / 12 | 12 / 12 |
| iterations used | 1 | 1 | 2 |
| Phase 1 wall clock | 33 min | 23 min | 34 min |

Those figures are the four-run table in [README.md](../../README.md), which
cites each run's own artifacts. The journals are
[0026](../../journal/0026-run-004.md),
[0027](../../journal/0027-run-005.md) and
[0028](../../journal/0028-run-006.md).

The pins are what make it a ladder: plugin SHA
`f25d05d8eb219c9b0009a85d39918214f6b3b681` and model version
`claude-opus-5[1m]`, both recorded in [LEDGER.md](../../LEDGER.md), with three
pairwise-distinct session identifiers as the evidence that there were three
sessions. Each run asserts at its preconditions that the diff between the
pinned SHA and `main`, over the plugin's own paths, is empty.

The instructive part is what happened next. Pass 0029 landed one sanctioned
documentation change *inside* that path, so the assertion as written stops
being true, and the LEDGER records the consequence and the corrected form
rather than quietly relaxing the check. That is what "the instrument is
frozen for the duration" costs in practice, and it is cheaper than the
alternative: a later run hard-stopping for a reason that is not about the
instrument.

## 8. Packaging

Packaging is distribution, and there is nothing worth distributing until you
know what the thing does. Nothing at this stage moves a score; done early, it
is work you redo when the measurement changes what ships.

Read this stage as a plan and not as evidence: it has **not** landed here.
[LEDGER.md](../../LEDGER.md) says so in its first section — last landed 0029,
next 0030, packaging with a marketplace file and a cold-install proof. When a
chapter of this manual has nothing measured behind it, it says so, and this
is one of those places.

## 9. The README, last, written from the journal

Benefit claims written mid-project are predictions, and several of them will
be wrong. METHOD.md's rule is "Capability, not benefit": each pass records
what is now *possible* that was not, and the summary document is written once
at the end, from the journal.

Pass 0029 did that: [journal](../../journal/0029-final-readme.md),
[plan](../../plans/0029-final-readme/plan.md). It is also the proof of why
the rule exists. Until that pass, the README still described run 002 as "the
latest run" and still said the plugin's effect was unmeasured. A README
written from the journal at the end can also refuse the flattering reading:
this one says plainly that reading its own table as `0 → 12` is wrong twice
over, and that the comparable row moves 0 / 12 to 1 / 12.

One honest wrinkle in the ordering. Here the README landed at 0029, ahead of
packaging at 0030, which has not landed. The rule is *README after the
measurement*, which both orders satisfy. What the rule forbids is a README
written before the runs it summarises.

---

## What depends on what

- 1 before everything: without a written definition of done, the later
  stages have nothing to be right about.
- 2 before 3, 4 and 5: a score from an unfalsified grader is not evidence.
- 3 and 4 before 5: you cannot take a baseline without a right answer to
  score against, or without a known state to start from.
- **5 before 6:** a skill added before the baseline can never be attributed.
- **6 before 7:** the ladder measures a fixed instrument, so the last skill
  change lands before the first rung and nothing changes until the last rung
  is recorded.
- 7 before 8 and 9: packaging and prose describe a result you do not have
  until the runs are done.

## Do not

**Do not write skills before failures exist.** The failure it prevents is
unattributable capability: you cannot say what a skill bought, because you
never measured the model without it. METHOD.md's *Sequencing* section states
both halves — the grader comes before the first capability, and the baseline
before the first addition. The instance in this repository is a refusal: pass
0025 declined to write three proposed skills because they would have carried
the coming measurement's answers, and recorded the refusal in the
[LEDGER](../../LEDGER.md) backlog for the operator to overrule.

**Do not fix the grader to make the target pass.** The failure it prevents is
a grader trained to agree with whatever the agent produced, after which every
green is self-congratulation. METHOD.md:

> Never weaken or delete an assertion because a target fails it. That is a
> finding and it goes to the operator.

[README.md](../../README.md) states the same rule for the behaviour oracle
under *Guardrails*: "Never edit the oracle to fit." The instance is run 006,
which found that `cases.md` justifies four repository nodes with a rule that
produces three. That is a real contradiction in the oracle, discovered by a
run that was being scored by it — and nothing under `evals/` was touched. It
is recorded as a finding for a decision to repair
([journal 0028](../../journal/0028-run-006.md),
[run record](../../runs/006-plugin-on/README.md)).

The distinction a beginner needs here: *evidence about the assertion* is a
legitimate reason to change it; *a target failing it* is not. Pass 0005
replaced an assertion after six failures exposed it as a rule the suite had
invented rather than extracted, and wrote up the evidence for doing so. Pass
0020 refused to repair a grader defect it had found, because repairing it
mid-measurement would have broken comparability. Same repository, opposite
actions, one rule.

**Do not average variance away.** The failure it prevents is a comparison
between two numbers that were never measuring the same thing. Across the
three ladder runs `cases-run` reads 57, 56, 57 — run 005 shipped no culture
directory, so one assertion graded nothing and reported skipped rather than
passed. At `cases-run` the three runs are incomparable. At `cases-defined` —
the denominator parsed from the suite's own source, with the target never
consulted — they read 33, 33 and 33. That is what the stable denominator is
for, and it is why the ladder can claim that every graded line matches.

The governing rule is METHOD.md's: a score comparison is valid only when
cases-run is stable between the two runs, and any report comparing two scores
states cases-run for both. Its reasoning is
[decision 0003](../../decisions/0003-score-comparability.md), which is the
arithmetic version of the inert-assertion problem. Repairing one assertion
moved a corpus module from 8 / 11 to 170 / 171 and another from 17 / 67 to
17 / 79. As percentages that is "improved by 27 points" and "got worse by 4".
Neither statement means anything, because the denominator moved. Note the
direction of the risk, which is the one that will bite you: an assertion that
silently stops producing cases makes a score go **up**.

The same section of METHOD.md carries the companion rule, and it is the one
people argue with: **"Prevalence is not correctness."** A rule most targets
fail is either wrong, or the targets are, and evidence about the rule decides
— not the failure rate. Two assertions here had near-identical pass rates and
went opposite ways, because one was a preference with no mechanical
consequence and the other described a real defect.

## The minimum version

Nine stages is what this repository did, with one operator, one pass at a
time, across the sequence recorded in [journal/](../../journal/). If your
project is smaller, METHOD.md's *Known limits* says what to cut:

> On a small project, use the minimum: an oracle, falsification with
> controls, and a journal. Skip the harness and the decisions log. Do not
> skip the corpus: it is the cheapest part of the method when one already
> exists, and it is what breaks the closed loop — here it cost one pass and
> invalidated five of ten assertions in the tag it tested.

The stage nobody may skip is 2, and specifically the falsification half of
it. [Chapter 03](./03-test-first-or-nothing.md) is that half: how to prove an
assertion can fail, and the times in this repository when a green light
turned out to be nothing at all.

<!-- TEMPLATE:replace — the pass numbers in this chapter are this
     repository's. In a copy, keep the order and the dependencies, and
     replace the numbers and links with your own. -->
