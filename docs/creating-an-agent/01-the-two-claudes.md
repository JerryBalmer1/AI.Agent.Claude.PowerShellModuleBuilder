# The two Claudes

Chapter [00](./00-start-here.md) named the loop: the director writes the
prompt, the executor runs it in a fresh session, the director audits the
remotes. This chapter is about the first word in each of those clauses.

Two Claudes did the work in this repository, and they never swapped jobs.
One of them decides; the other one executes. Keeping that line sharp is not
tidiness — it is the thing that makes the numbers in
[README.md](../../README.md) mean anything at all, and this chapter shows
you the three specific places it paid.

---

## The two roles

### The director — a Claude project in the Claude app

A **project** in the Claude app is a workspace whose files and standing
instructions are available to every conversation you start inside it. That
is where the methodology lives on the human side.

**What the director may do**

- hold the methodology — [method/METHOD.md](../../method/METHOD.md),
  [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) — and a pointer to the ledger
- write every prompt the executor will ever receive
- assign the pass number, the tier, and the definition of done
- read the committed artifacts afterwards and decide whether to believe
  them
- decide what a finding becomes: a decision record, a backlog item, or
  nothing
- publish. [METHOD.md](../../method/METHOD.md) reserves this to the human
  entirely: "Nothing publishes. No release, no tag, no push to the default
  branch, unless the operator does it from their own shell. Pushing a pass
  branch is expected."

**What the director may never do**

- run a command, edit a file in the repository, or push a branch
- hold a score, a fixture finding, or oracle content in its project context
  where a later prompt might carry it into a blind session
- accept the executor's summary in place of the artifact it describes

### The executor — Claude Code, in the terminal

In this project the executor ran as the VS Code extension;
[plans/0020-baseline-off/plan.md](../../plans/0020-baseline-off/plan.md)
records the environment as "Claude Code: VS Code extension; model Claude
Opus 5 (1M context)".

**What the executor may do**

- execute the prompt it was given, exactly, in a fresh session
- stop at a precondition and commit the stop as the pass's whole output
- report in the plan's Deviations section that an instruction was wrong,
  unclear, impossible, or mistaken
- refuse an instruction that conflicts with the protocol, and say what the
  refusal cost
- write the plan, the journal entry, and the ledger update

**What the executor may never do**

- invent a pass number
- widen its own scope, or narrow it quietly
- weaken the grader to improve a score. METHOD.md: "Never weaken or delete
  an assertion because a target fails it. That is a finding and it goes to
  the operator." README.md states the same rule about the behavioural
  oracle under the heading "Never edit the oracle to fit."
- publish anything

The refusal clause is real, not decorative.
[journal/0026-run-004.md](../../journal/0026-run-004.md) records one:

> **`commands/build.md` step 1 was declined, not obeyed.** It instructs
> reading `evals/conformance/Conformance.Tests.ps1`; the Phase 1 allowlist
> forbids it. The protocol wins over the plugin, and the consequence is
> stated rather than smoothed over: the conformance score measures
> skill-fidelity, with the assertions unread.

Notice the shape. The executor did not choose a different scope; it
declined one instruction because a higher rule forbade it, then wrote down
what the score therefore does and does not mean. That is the whole
permitted range of executor judgment.

---

## Why the split exists

Not for neatness. For three specific reasons, each of which left a mark in
this repository.

### (i) An executor that picks its own scope cannot be audited

PLAN-PROTOCOL.md opens its numbering rule with "The operator assigns NNNN
in the prompt header", and closes it like this:

> The agent never invents a pass number. A prompt arriving without one is a
> stop.

A pass number looks like bookkeeping. It is not. It is the smallest
possible token of *somebody else decided what this pass is*. If the
executor assigns the number, it has chosen the scope; if it has chosen the
scope, the definition of done moves to fit whatever got built; and once the
definition of done moves, no later comparison means anything, because every
run was graded against a standard the graded party selected.

The same protocol gives the executor exactly one way to disagree, and it
only points upward:

> A pass that believes its stated tier is wrong says so in Deviations and
> executes at the higher tier. Tier is a floor, never a ceiling.

**Tier** here means how much verification a pass owes: *full* for a pass
that changes executable behaviour — red-first acceptance test, per-task
evidence, a verify script — and *light* for a pass that writes records
only. The executor may raise its own bar and must say so. It may not lower
it. Chapter [06](./06-the-pass-protocol.md) covers the format in full.

### (ii) A pass that finds its instruction wrong must say so

Section 10 of a plan is Deviations, and PLAN-PROTOCOL.md calls it
"Required, never omitted. Empty means writing "none," not deleting the
heading." Then it explains why:

> This is the most valuable section. Four of this project's strongest
> findings came from a pass reporting that an instruction was wrong or
> incomplete: a control probe of the wrong polarity, a comment-only control
> that could not discriminate, a refusal to author a suite the same pass
> was meant to grade with it, and a near-miss where a guard against a false
> negative was itself nearly a false positive.

Read that as a claim about the split, because that is what it is. An
executor that had written its own instructions would have nothing to
report; a mistake in the prompt and a mistake in the work would be the same
mistake, and correcting it silently would look identical to doing the job
well. Two parties make the disagreement visible, and the disagreement is
where the findings came from.

[plans/README.md](../../plans/README.md) tells a reviewer to start there:
"Start at **Deviations**."

### (iii) Separation is what makes a blind measurement possible at all

Hazard 9 in [evals/HARNESS.md](../../evals/HARNESS.md) states the problem:

> Run records are **oracle knowledge in prose**.

A run README carries the score, the difference count, the mechanisms by
name, and often the exact field conventions the oracle wants. A session
that has read one cannot produce an independent first-shot number
afterwards. So the rule is that "a measured run's prompt is the first
message of a brand-new session", and anything at all in that context ahead
of the prompt disqualifies the session.

An agent cannot do that to itself. Only a party outside the session can
open a new one and hand it a first message with nothing in front of it. The
split is not a style preference here; it is the mechanism.

And it is checkable. HARNESS.md notes that passes 0026, 0027 and 0028 each
opened a fresh session for exactly this reason, "and their three distinct
`session-identifier` values are what makes the claim checkable rather than
asserted". Run 006's is recorded in the metadata block at the top of
[runs/006-plugin-on/README.md](../../runs/006-plugin-on/README.md) as
`f0302223-28f1-436d-85f3-04e168c8534c`. Chapter
[04](./04-fresh-sessions-and-contamination.md) is about how easily that
gate is tripped.

---

## Methodology lives in files, not in a chat window

This is the pattern that makes the director's role possible without making
it fragile.

METHOD.md, under "Records":

> Instructions live in files in the repository, not in chat. A session
> restart clears the conversation and not the repository.

PLAN-PROTOCOL.md says the same thing about itself, in its second sentence:

> This document is the format. It lives in the repository rather than in a
> conversation because a session restart clears the conversation and not
> the repository.

The asymmetry is the whole point. A conversation is volatile and a
repository is not, so anything the *next* session must know goes in a file
or it is gone. That includes rules you are certain you will remember.

### What the director's project context should hold

- the method and the plan protocol — or, better, a pointer to them in the
  repository, so there is one copy rather than two that can disagree
- a pointer to the ledger. [LEDGER.md](../../LEDGER.md) says so itself in
  its opening lines: "The chat context points here; this file is the source
  of truth for counters and pins."
- standing conventions that outlive any single pass. Governance decisions
  are written as decision records for this reason; decision
  [0010](../../decisions/0010-ecosystem-repo-governance.md) says each
  governed repository "carries `docs/HANDOFF.md` per the project context",
  which is a convention stated once and then referred to.

### What it must never hold

Scores. Fixture findings. Oracle content. Anything that answers a question
a blind run is supposed to answer for itself.

Hazard 10 in HARNESS.md is the durable form of that rule:

> **No score, fixture finding, or oracle content may ever be written to
> session memory, `MEMORY.md`, `CLAUDE.md`, or any other auto-loading
> location.**

The reason it gets its own hazard rather than a footnote is that it has no
symptom:

> A context window is cleared by `/clear` and a new session genuinely
> starts blind; an auto-loading file is not cleared, so a single score
> written to memory disqualifies **every** future session, and nothing
> announces it.

A director's project context is exactly this kind of auto-loading location
on the human side. Keep the method in it and keep the answers out of it.

---

## Fenced-block routing

Here is the convention that carries a prompt from one Claude to the other,
stated plainly because it is easy to get wrong on your very first pass.

**In the director's reply, the fenced code block is the prompt.** You copy
the block — the whole block, nothing else — open a *new* Claude Code
session, and paste it as message one.

**The prose outside the fence is for you.** It is the director explaining
what it just wrote and why. It is never pasted anywhere.

That is the entire convention, and the reason for it is this: if commentary
leaks into the executor's context, the executor is no longer running the
prompt that was written. The plan committed under `plans/` will reproduce
one instruction while the session actually received another, and the two
will disagree in a way nobody can reconstruct later. For a measured run it
is worse than untidy — anything ahead of the prompt in that context
disqualifies the session outright, per hazard 9 above.

PLAN-PROTOCOL.md states the same discipline in the return direction, for
anything the executor hands back:

> Every block the operator may copy — the transcript, the verify script —
> is a fenced code block with a language tag, so it copies in one action.
> Never split a copyable block with prose.

One fence, one copy, one action, in both directions.

### The rule the fence is enforcing

The fence is a physical form of PLAN-PROTOCOL.md's "File supply" rule:

> A file a pass must create is either already committed to the repository,
> or its full content appears verbatim in the prompt. There is no third
> channel.

There is no third channel. Not "I described it in the paragraph above the
block", not "it is in the conversation somewhere", not "the agent can
figure out what I meant". Either the repository already holds it, or the
prompt contains it in full.

The protocol says what that rule cost before it existed:

> This rule exists because it has already cost a pass twice: once silently,
> when a missing draft blocked a task and the pass carried on without
> saying so, and once loudly, when the same gap stopped a pass at its
> preconditions. The loud failure is the correct behaviour.

---

## The routing failures this project actually recorded

Two of them, both instructive, both written down at the time.

### The missing file, twice — pass 0009 and pass 0010

The "twice" in the quote above is not a figure of speech.
[journal/0010-plan-protocol.md](../../journal/0010-plan-protocol.md)
records under **Asked**: "A re-issue: the same pass stopped at its
preconditions when the method draft was named but not supplied." And under
**Learned**:

> **A gate that stops a pass is cheaper than one that does not.** The first
> issue of this pass stopped at precondition 4 with nothing committed. The
> same missing file had blocked a task in Pass 0009 *silently*, and cost a
> pass. The difference between the two outcomes was entirely whether the
> requirement was stated as a precondition.

Same defect, two outcomes. In pass 0009 the prompt named a document that
was not supplied, the pass carried on around it, and the loss was only
found afterwards. In pass 0010 the same gap hit a stated precondition, the
pass stopped with nothing committed, and the stop was itself the record.
One of those is a wasted pass; the other is a five-minute re-issue.

The repair was not "be more careful". It was to write the File supply rule
into PLAN-PROTOCOL.md as a section, and to make supply a precondition that
can stop a pass. Chapter [07](./07-failure-catalog.md) has more of these.

There is a smaller sibling worth knowing about. PLAN-PROTOCOL.md also
carries a section called "Uncommitted changes the pass did not make",
because a dirty working tree at preconditions is the other way stray
material reaches a pass. The rule is that such a change is committed on its
own, before the pass begins, with a message naming it as unrelated — not
reverted, not stashed, not carried into the pass commit. It has a real
instance:
[plans/0013-create-fixture/plan.md](../../plans/0013-create-fixture/plan.md)
records a failed precondition whose cause was an editor-written workspace
setting, committed alone ahead of the pass.

### The prompt that contradicted itself — pass 0011

From the **Learned** section of
[journal/0011-fixture-design.md](../../journal/0011-fixture-design.md):

> **Two documents in the repository asked for things that cannot both be
> done.** The prompt's Constraints say the PAT is not read; task 10 asks
> for a scan of the tree against the PAT's literal content, which requires
> reading it. The constraint won, the check was not performed, and the gap
> is stated.

Three separate things happened there, and all three are the split working.
The executor noticed the contradiction rather than resolving it by
preference. It said which side it took and why. And it recorded what was
therefore *not* checked, so the pass's own coverage claim stayed honest.

The same entry notes a second deviation of a different kind: PLAN-PROTOCOL
section 11 asks for a token count the agent has no way to measure, which
was flagged in pass 0010, was unchanged, and got flagged again. A deviation
that recurs is not nagging — it is evidence about the protocol, arriving
through the only channel that can carry it.

None of this requires the executor to be clever. It requires only that it
be a different party from the one that wrote the instruction, with a
section it is obliged to fill in.

---

Next: chapter [02](./02-order-of-operations.md), on what has to exist
before what — or chapter [05](./05-calling-bullshit-verification.md) if you
want the audit step first.
