# Start here

This repository is a worked example of one method: build something with an
AI coding agent, then measure what the agent actually produced, then keep
the measurement honest enough that a stranger would believe it.

The example happens to be a PowerShell module. The method is the part worth
copying, and it does not care what language you use — see "You do not need
PowerShell" below.

This chapter gives you the vocabulary the rest of the manual uses, the loop
you will actually run, an honest list of what you need before you start,
and the numbers this project reached — including the unflattering ones.

---

## What "an agent" means here

The word "agent" is used loosely everywhere else. Here it means one thing.

An **agent** is a Claude Code process handed exactly three things:

1. **a prompt in a fixed format** — not a chat message, but a document with
   a pass number, a tier, preconditions, a task list, and a section where
   it must report anything that was wrong with its own instructions;
2. **a repository** it can read and write, whose history is the record of
   what it did;
3. **a definition of done that existed before the work started.**

It is not a chatbot: you are not having a conversation with it, you are
issuing one instruction and reading the artifacts afterwards. It is not an
autonomous robot either: it does not choose what to work on, it does not
decide when it is finished, and it does not publish anything. Somebody else
settled all three before the session opened.

### "Existed first" is the whole method

Item 3 is load-bearing, and it is the single idea everything else in this
manual is built on. A definition of done written **after** the work is
written to fit the work. You then learn only that the agent can satisfy a
standard chosen by the thing being graded, which is not a measurement.

[PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) — the pass format this project
runs on — makes that mechanical. For any pass that changes executable
behaviour, section 4 of its plan must contain:

> The test as run, the command, and the failure output proving it was red
> before any work began. A test already green stops the pass: either the
> work is unnecessary or the test cannot fail. Both are findings and both
> go in Deviations.

**Red** means the test failed; **green** means it passed. Requiring a
recorded red first sounds like ceremony until it catches something, so here
is the first time it caught something in this repository, on the first pass
that used it. From
[journal/0011-fixture-design.md](../../journal/0011-fixture-design.md):

> **The red-first rule paid for itself in the first run.** With no fixture
> on disk, `node ids are unique` passed — zero ids contain no duplicates.
> That is an inert assertion, the third this project has found, and it was
> visible only because the test ran against nothing before it ran against
> something.

An assertion that cannot fail passes every run for free and adds a point to
every score. Written after the thing it grades, it would have been green
from birth and indistinguishable from a working check.
Chapter [03](./03-test-first-or-nothing.md) is entirely about this: proving
a check can fail before you believe that it passed.

### Four words you will need immediately

- **pass** — one unit of work against one prompt, numbered `NNNN`. It
  produces `plans/NNNN-<slug>/` (the receipt) and `journal/NNNN-<slug>.md`
  (the narrative). [plans/README.md](../../plans/README.md) explains why
  those are two different documents rather than one.
- **run** — a scored build of the target module, from a wiped starting
  state, recorded under [runs/](../../runs/README.md). A pass may contain a
  run; most passes do not.
- **the target** — the module being built. It lives in a *second*
  repository, so the thing under test and the thing measuring it are never
  the same working tree.
- **oracle** — the hand-written right answer that output is compared
  against. This project has two: a conformance suite that grades *shape*,
  and a 49-node, 51-edge expected graph that grades *behaviour*, written by
  hand from the fixture rather than generated from it
  ([journal/0011](../../journal/0011-fixture-design.md)).

Chapter [08](./08-glossary.md) collects every term in one place.

---

## The loop, in three steps

Everything else in this manual is a detail of these three steps.

**1. The director writes the prompt.** A Claude project in the Claude app
holds the methodology and produces a prompt carrying a pass number, a tier
and a definition of done. It runs no commands.

**2. The executor runs it in a fresh session.** Claude Code, in your
terminal, receives that prompt as the first message of a brand-new session
and executes it. It does not choose scope.

**3. The director audits the remotes, not the report.** "The remotes" means
the things that exist outside the conversation: the pushed branch, the
committed plan, the result JSON, the scored diff. The executor's summary of
its own work is prose it wrote about itself. The artifacts are not.

That third step is the one people skip, and it is the one that decides
whether any of this was worth doing. PLAN-PROTOCOL.md says it twice — once
about the verify script every full-tier pass must commit:

> The script exists so the operator can disprove this plan without reading
> it. Write it to be capable of failing.

and once at the end, about where the truth lives:

> The repository is the record; a pasted report is a convenience.

Chapter [01](./01-the-two-claudes.md) covers the director/executor split
and why the two are never the same session. Chapter
[05](./05-calling-bullshit-verification.md) covers the audit itself.

Here is what a properly audited run leaves behind:
[runs/006-plugin-on/README.md](../../runs/006-plugin-on/README.md) opens
with a metadata block pinning `plugin-sha`
`f25d05d8eb219c9b0009a85d39918214f6b3b681`, `model-version`
`claude-opus-5[1m]`, a `session-identifier`, the `seed-sha`, the
`target-sha`, `phase-1-minutes: 34`, and its three score lines. Every one
of those is checkable by somebody who was not there.

---

## What you actually need

### Two Claude surfaces

- **The Claude app**, for the director. You need the project feature: a
  workspace that keeps files and standing instructions available to every
  conversation you start inside it.
- **Claude Code**, for the executor. It runs in a terminal. In this project
  it ran as the VS Code extension — recorded in
  [plans/0020-baseline-off/plan.md](../../plans/0020-baseline-off/plan.md)
  section 3 as "Claude Code: VS Code extension; model Claude Opus 5 (1M
  context)".

Both are covered by a Claude subscription, and that is the part of this
list that costs money. This manual does not quote a price, because prices
change and a wrong number here would be worse than none; check Anthropic's
current plans yourself.

### Git and a GitHub account

Free at the tier this needs. Runs push to their own branch rather than to
`main` — run 006's target branch is `run-006-plugin-on` — so you need
somewhere to push. The audit in step 3 reads pushed commits, not your
working tree.

### For this example specifically

[README.md](../../README.md), under "Running it", states the requirement:

> Needs PowerShell 7.2+, Pester 6.x, PSScriptAnalyzer, InvokeBuild.

All four are free and open source. **Pester** is PowerShell's test
framework, **PSScriptAnalyzer** its linter, and **InvokeBuild** its build
task runner. The versions actually used are recorded rather than assumed:
[plans/0026-run-004/plan.md](../../plans/0026-run-004/plan.md) section 3
lists pwsh 7.6.5, Pester 6.1.0, InvokeBuild 5.14.23, PSScriptAnalyzer
1.25.0, powershell-yaml 0.4.12 and git 2.41.0.windows.1, on Windows 11.

### What you can skip

An Azure DevOps token. One of the three checking suites needs it —
README.md's "Running it" marks `ReadBack.Tests.ps1` as "76 cases, needs
AZDO_PAT" — and it exists to check the fixture against the real service.
The conformance score and the functional score are both reproducible
without it.

So, plainly: the subscription costs money, and nothing else on this list
does.

---

## You do not need PowerShell

The stack is the example. The method is the product, and
[method/METHOD.md](../../method/METHOD.md) is written so you can tell which
is which. Every rule in it carries one of three marks:

> - **PORTABLE** — survives a domain change unedited. Copy as-is.
> - **TUNE** — right shape, wrong specifics. Keep the structure, replace
>   the nouns.
> - **DOMAIN** — does not travel. Listed so it is visible as something to
>   replace, not silently inherited.

That marking is the mechanism that makes the method reusable. Take the
PORTABLE rules unchanged, re-noun the TUNE ones, and treat the DOMAIN ones
as a list of things you must supply yourself. METHOD.md carries a section
titled "What this project supplied that you must replace", so the
domain-specific parts are enumerated rather than left for you to discover
by failing.

There is one honest limit, and METHOD.md leads with it rather than burying
it. Its first section is "Precondition — does this method apply at all?":

> This method depends on the agent's output being machine-checkable. A
> PowerShell module either builds, lints, and exports what its manifest
> claims, or it does not. Where output cannot be checked by a program —
> copy, design, strategy, most writing — there is no oracle, and the method
> degrades to rubrics and blind A/B comparison, which is far weaker. Apply
> it anyway and you get the ceremony without the signal.
>
> Decide this first. If the answer is no, use a different method.

Take that seriously before copying anything. The overhead is real:
METHOD.md's own "Known limits" section says several passes produce a grader
and no capability at all. Paying that price buys you a number you can
defend. Paying it where no program can check the output buys you paperwork.

---

## What this repository actually achieved

<!-- TEMPLATE:replace — every number in this section belongs to this
     project. A repository reused as a template replaces the section
     wholesale rather than editing the figures. -->

Four measured runs of the same task: one with the plugin unreadable, three
with it readable. Same seed, same brief, same fixture, same scoring, one
blind session each.

| | 003 off | 004 on | 005 on | 006 on |
|---|---|---|---|---|
| conformance (cases-defined) | 19 / 33 | 33 / 33 | 33 / 33 | 33 / 33 |
| functional (first-shot) | 0 / 12 | 1 / 12 | 1 / 12 | 1 / 12 |
| functional (final) | *never permitted* | 12 / 12 | 12 / 12 | 12 / 12 |

Every column has a record holding the artifacts behind it:
[003](../../runs/003-baseline-off/README.md),
[004](../../runs/004-plugin-on/README.md),
[005](../../runs/005-plugin-on/README.md),
[006](../../runs/006-plugin-on/README.md).

Read the last row carefully, because it is the row most likely to mislead
you. Run 003 has no final score because its protocol did not allow one:
"No fixes, no re-runs — the first scores stand"
([plans/0020-baseline-off/plan.md](../../plans/0020-baseline-off/plan.md)).
Nobody knows what run 003 would have reached with three iterations, and the
table cannot say. **The fair comparison is the first-shot row, and it is
nearly flat: 0 / 12 against 1 / 12.**

This is a narrow and uneven result, and [README.md](../../README.md) says
so at length under "Status, honestly". The parts worth carrying away:

- The large, repeatable win is on **shape**: 19 / 33 to 33 / 33, three
  times, first shot, from a fresh clone.
- On **behaviour** the effect is four specific rules fixed and one new
  error introduced by the plugin's own wording. Three field conventions the
  instrument never states were guessed wrongly by every run, plugin or no
  plugin, in the same direction each time.
- The baseline is **one run** that was never allowed to iterate. A second
  plugin-off run under the same rules is the missing control, and it is
  recorded as outstanding in [the LEDGER](../../LEDGER.md).
- The builder is the same model family that wrote the skills, so none of
  the runs can separate reading the plugin from recalling the reasoning
  that produced it.
- Run 006's own prompt leaked earlier runs' findings into its blind phase.
  That is flagged in its record, and its first-shot number is stated as
  weakened rather than quietly used.

The last two bullets are the interesting ones. A project with no recorded
failures reads as untested; this manual treats the recorded mistakes as
teaching material, and chapter [07](./07-failure-catalog.md) collects them.

---

## The chapters

- [00 — Start here](./00-start-here.md). This page: vocabulary, the loop,
  prerequisites, and the real result.
- [01 — The two Claudes](./01-the-two-claudes.md). Director and executor:
  who writes, who runs, and why they are never the same session.
- [02 — Order of operations](./02-order-of-operations.md). What has to
  exist before what, and why the grader comes first.
- [03 — Test first or nothing](./03-test-first-or-nothing.md). The
  red-first rule, and why a test that was green from birth tells you
  nothing.
- [04 — Fresh sessions and contamination](./04-fresh-sessions-and-contamination.md).
  What a blind run is, and how cheaply it is spoiled.
- [05 — Calling bullshit: verification](./05-calling-bullshit-verification.md).
  Auditing artifacts instead of believing a report.
- [06 — The pass protocol](./06-the-pass-protocol.md). The prompt format,
  the two tiers, and the Deviations section.
- [07 — Failure catalog](./07-failure-catalog.md). The mistakes this
  project recorded, and what each one cost.
- [08 — Glossary](./08-glossary.md). Every term of art, defined once.
- [09 — Try before you trust](./09-try-before-you-trust.md). Installing and
  driving the plugin entirely on your own machine, and removing it again,
  before anything public is involved.
- [10 — Using as a template](./10-using-as-a-template.md). Reusing this
  repository for a domain of your own.

Read 00 to 03 in order. After that, take them as you need them.

---

## Keeping this manual true

One rule, and it is a rule rather than an aspiration:

**These docs are updated by any pass that changes what they describe.**

A chapter that describes a protocol, a score, or a file layout is a claim
about this repository, and a claim that has drifted from the repository is
worse than no claim, because it reads exactly like a correct one. If a pass
changes what a chapter describes, that pass updates the chapter, in the
same commit as the change.

The standing obligation is carried in the backlog of
[the LEDGER](../../LEDGER.md), whose first line records that it is
"maintained by the agent as the last task of every pass". That is where
this project keeps work it has accepted but not yet done, so an obligation
recorded there survives the session that noticed it.
