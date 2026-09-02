# 06 — The pass protocol

Every unit of work in this project is a **pass**. A pass is one prompt from
you, executed by one agent session, producing one directory of evidence and
one commit. The format of that evidence is fixed, written down, and
enforced — it is [`PLAN-PROTOCOL.md`](../../PLAN-PROTOCOL.md), and this
chapter is a guided reading of it.

The protocol opens by explaining where it lives and why:

> This document is the format. It lives in the repository rather than in a
> conversation because a session restart clears the conversation and not the
> repository.

That sentence is the design in miniature. Everything an agent knows
evaporates when its session ends. Everything it committed does not. So the
rules go in the repo, the evidence goes in the repo, and the conversation is
treated as a thing you are about to lose.

Two neighbours are worth having open.
[03 — Test first, or nothing](./03-test-first-or-nothing.md) is the
red-first discipline that section 4 below depends on, and
[04 — Fresh sessions and contamination](./04-fresh-sessions-and-contamination.md)
covers the session rules that a measured pass's preconditions enforce. If
you are here to copy the machinery rather than to read about it, go to
[10 — Using this as a template](./10-using-as-a-template.md).

## Two rules that apply before the plan file exists

**Pass numbering.** You assign the four-digit number in the prompt header.
The protocol is blunt about it: "The agent never invents a pass number. A
prompt arriving without one is a stop." The number ties three artifacts
together — `plans/NNNN-<slug>/`, `journal/NNNN-<slug>.md`, and the header —
and an agent that picks its own would eventually pick one that already
exists.

**File supply.** This one saves you from a whole class of quiet failure:

> A file a pass must create is either already committed to the repository, or
> its full content appears verbatim in the prompt. There is no third channel.

There is no third channel and no informal one. The protocol singles out the
phrase *Supplied by the operator* and rules that, without content in the
prompt, it is "a defect in the prompt, not a lookup task, and the pass stops
on it rather than searching or inventing." It records that the rule was
earned twice —
once silently, when a missing draft blocked a task and the pass carried on
without saying so, and once loudly, when the same gap stopped a pass at its
preconditions. The loud failure is the correct behaviour.

You can watch it fire. Pass 0027's prompt arrived truncated: three of eleven
acceptance assertions, with no `Describe`, no `BeforeAll` and no `$RunDir`.
The pass stopped at task 1 and committed the stop.
[`journal/0027-run-005.md`](../../journal/0027-run-005.md) explains why
guessing would have been worse than stopping:

> The eight missing assertions were the eight that pin provenance — plugin
> SHA, model version, session identifier, seed/brief/target, wall-clock,
> build, conformance denominator. An agent that writes those for itself can
> omit one and pass its own grading.

Rejected, explicitly: reconstructing them from run 004's test, whose `It`
names were readable. A blind Phase 1 runs once per session, and a wrong guess
would not have surfaced until after the branch was pushed.

## The anatomy of a plan, section by section

`plan.md` has eleven numbered sections. Each exists to stop one specific way
of being wrong.

### 1. Prompt

**Why:** the prompt as received, verbatim, in a fenced block — not
summarised, not tidied — because that is "what makes the plan auditable a
month later." A summarised prompt lets an agent quietly narrow the job to
what it did.

**Seen working:** [`plans/0025-findings-batch/plan.md`](../../plans/0025-findings-batch/plan.md)
opens with §1 Prompt and reproduces the whole instruction, including the
parts the pass ended up declining.

### 2. Preconditions

**Why:** each precondition, the command that checked it, and its output —
so that "any failure stops the pass here, and the plan is committed showing
the stop," which turns a stop into an artifact rather than a lost afternoon.

**Seen working:** [`plans/0026-run-004/plan.md`](../../plans/0026-run-004/plan.md)
§2 is a twelve-row table where every row names its command and its result,
including the session gate, the plugin pin, the oracle blob located by SHA
rather than opened, and the memory directory listed by filename only.

### 3. Environment

**Why:** pwsh version, Pester version, OS, Claude Code version, branch, and
HEAD at start, because a result that cannot name the machine it ran on is
not reproducible by anyone but you.

**Seen working:** [`plans/0027-run-005/plan.md`](../../plans/0027-run-005/plan.md)
§3, and the same discipline lands in the run record — every run README's
Provenance ends with the tool list, down to `powershell-yaml 0.4.12`.

### 4. Acceptance test — red first

**Why:** the test, the command, and the failure output proving it was red
*before any work began*, because a test that has never failed is not
evidence that the work happened. The protocol adds the trap: "A test already
green stops the pass: either the work is unnecessary or the test cannot
fail. Both are findings and both go in Deviations."

**Seen working:** pass 0028 recorded "Acceptance red — 0 passed, 11 failed"
before Phase 1 started
([`plans/0028-run-006/plan.md`](../../plans/0028-run-006/plan.md)).

### 5. Tasks, with evidence

**Why:** a ticked checklist with the command and its output under each item,
because — and this is the sentence to remember —

> Evidence is what a reader needs in order to believe the task happened
> without trusting the sentence above it.

Numbers cite artifacts. "Never a figure without a file behind it."

**Seen working:** [`plans/0022-tohtml-contract/plan.md`](../../plans/0022-tohtml-contract/plan.md)
§5, where each task carries the transcript that proves it, including a build
re-run against inherited files *before* anything was changed.

### 6. Acceptance test — green

**Why:** the same test, the same command, passing. Same test and same
command are the load-bearing words — a green from a different invocation
proves nothing about the red.

**Seen working:** pass 0028 closed at "Acceptance green — 11 passed, 0
failed," against the 0-passed/11-failed run from §4.

### 7. Command transcript

**Why:** every command that changed state, and every command whose output
produced a number appearing anywhere in the plan, in one fenced block "so it
copies in a single action." Exploratory reads are excluded, which keeps it
short enough to actually be used.

**Seen working:** [`plans/0022-tohtml-contract/plan.md`](../../plans/0022-tohtml-contract/plan.md)
§7 — one block, from the parallel fetch to the final push.

### 8. Diff summary (light tier)

**Why:** `git diff --stat` plus one line per file on what changed and why.
This replaces the acceptance test at the light tier, and the protocol
explains the refusal to fake one: "the diff and the operator's reading of it
are the honest artifact, and dressing that up as a green test would be worse
than not having one."

**Seen working:** [`plans/0019-history-unification/plan.md`](../../plans/0019-history-unification/plan.md)
§6, headed "Diff summary (light tier)".

### 9. Verify script (full tier)

**Why:** a committed `verify.ps1` beside the plan, so the operator can
disprove the plan without reading it. Its requirements get their own section
below.

**Seen working:** [`plans/0026-run-004/verify.ps1`](../../plans/0026-run-004/verify.ps1),
[`plans/0027-run-005/verify.ps1`](../../plans/0027-run-005/verify.ps1) and
[`plans/0028-run-006/verify.ps1`](../../plans/0028-run-006/verify.ps1).

### 10. Deviations

**Why:** the most valuable section in the file. Its own doctrine is below.

### 11. Cost

**Why:** wall-clock plus any run counts the pass produced — suite runs, probe
rows, build invocations. And explicitly **no token count**, for a reason
worth quoting in full:

> The agent cannot measure one from inside the session, and a field it cannot
> measure is a field it guesses at. This project's own rule is that a number
> without an artifact behind it does not belong in a plan, and that rule does
> not stop applying because the number is about the agent.

**Seen working:** [`journal/0025-findings-batch.md`](../../journal/0025-findings-batch.md)
closes with "Roughly 2 hours 20 minutes. 21 verify checks, 0 failed, 0
skipped. 11 gate falsification probes across two suites" — a duration and
three counts, each of which came from something that ran.

## Tiers, and the rule that decides them

You state the tier in the prompt. There are two.

**full** — the pass changes executable behaviour: an assertion, a script, a
hook, a skill, a manifest, a runner. It requires preconditions, a red-first
acceptance test, per-task evidence, a command transcript, a verify script,
deviations, cost.

**light** — the pass writes records only: journal, decisions, method, briefs,
protocol. It requires preconditions, per-task evidence, a diff summary,
deviations, cost. No acceptance test and no verify script, for a reason worth
internalising: "A test asserting that a document contains a heading proves
only that a heading exists, and invites writing to the test."

### The rule

> The tier is decided by whether the pass changes executable behaviour. It is
> not decided by whether the pass writes documents, nor by how many, nor by
> their length. A pass that writes six documents and touches no executable is
> light. A pass that writes six documents and amends one assertion is full,
> and the six documents do not make it any less so.

The failure this prevents is stated just as plainly: a pass whose bulk is
prose acquiring "the tier of its bulk rather than the tier of its risk, so
that the one change that could break something ships without a red-first test
or a verify script."

### The worked example, and what checking it turns up

`PLAN-PROTOCOL.md` names pass 0012. The prompt labelled it light. Its visible
bulk was documents — it split the fixture's case set by presence and absence
and corrected four documents. But it also amended an assertion in
`evals/functional/Fixture.Tests.ps1`, and that single amendment makes it a
full-tier pass wearing a light label.

Check that against the artifacts, because the artifacts are richer than the
summary.

[`journal/0012-case-split-and-corrections.md`](../../journal/0012-case-split-and-corrections.md)
confirms the amendment — "assertion 7 rewritten, 5 assertions to 34, plus a
CRLF regression guard" — and confirms the pass ran a red-first test anyway:
"Red first, amended assertion 7 against unmodified inputs: **315 passed, 15
failed, 330 total**, every failure in assertion 7."

So the protocol's worked example adds a clause the plan and journal do not
support: that pass 0012 "shipped without the red-first test the tier
requires." It did not. The prompt required a red-first acceptance test and a
`verify.ps1` regardless of the label, and
[`plans/0012-case-split-and-corrections/plan.md`](../../plans/0012-case-split-and-corrections/plan.md)
carries both. Flagging that is not pedantry — a manual that says "check the
example against the artifact" has to do it on its own examples.

What the artifacts *do* support is the more interesting half. The pass
noticed the disagreement and wrote it up as Deviations 7:

> The prompt says `Tier: light`. `PLAN-PROTOCOL.md` says light requires
> "preconditions, per-task evidence, a diff summary, deviations, cost" and
> explicitly "no acceptance test and no verify script" — while this prompt
> requires a red-first acceptance test *and* a `verify.ps1` with six named
> spot-checks. Both are here, and the diff summary is too. Not a problem in
> practice, and the prompt is right: this pass changed executable behaviour,
> so full-tier evidence is what it needed. The label is what is wrong. If
> tiers are to keep meaning anything, "changes an assertion" should decide
> the tier rather than "writes documents", and by that rule this was a
> full-tier pass.

That paragraph is where the rule in `PLAN-PROTOCOL.md` came from. An agent
noticed its instructions were internally inconsistent, executed at the higher
bar, and wrote down which half was wrong. The protocol then absorbed it as a
rule so nobody has to rediscover it.

### Tier is a floor, never a ceiling

The protocol's closing line on tiers: "A pass that believes its stated tier is
wrong says so in Deviations and executes at the higher tier. **Tier is a
floor, never a ceiling.**"

Practically: if you label a pass light and the agent finds it must touch an
executable, the right behaviour is to produce full-tier evidence and tell you
the label was wrong. It should never be to quietly produce less evidence
because the label permitted less.

### The gap the tier system still has

Worth knowing before you rely on tiers.
[`journal/0019-history-unification.md`](../../journal/0019-history-unification.md)
records: "The tier system has no axis for consequence outside the
repository." Pass 0019 was *light* by the rule — it changed no executable —
and it permanently moved the deliverable repository's default branch and
created a tag. Pass 0018, which fixed two sentences, carries the same label.
The tier measures risk to this repository's behaviour, not blast radius
elsewhere. Design your prompts knowing that.

## What `verify.ps1` has to be

The verify script is the artifact whose job is to disprove the plan. The
protocol's requirements, in the terms that matter to you as the person who
will run it:

- **Assume nothing but a fresh clone** of this repository and the tools.
  Not your machine, not your paths, not a module you happen to have
  installed.
- **Re-derive rather than read.** Re-run the suite and compare against the
  committed result JSON. "Never parse this plan." A script that reads the
  plan's own numbers and confirms they equal themselves checks nothing.
- **Re-run every spot-check the prompt named, by name**, so the operator's
  specific doubts are each answered.
- **Exit 0 when everything agrees, non-zero otherwise, printing which check
  disagreed.** An exit code with no name attached sends you back to read the
  script.
- **Never depend on `scratch/`**, "which is not committed and does not exist
  in a fresh clone."

And the instruction that sets the attitude: "The script exists so the
operator can disprove this plan without reading it. Write it to be capable of
failing."

Reading a verify script's output sceptically is its own skill, and it has
its own chapter:
[05 — Calling bullshit](./05-calling-bullshit-verification.md). For where
`verify.ps1` sits among the other layers of checking in this repository —
acceptance tests, the conformance suite, the functional oracle — see
[the test stack, layer by layer](../testing/README.md). If you would rather
run one yourself before believing any of this, see
[09 — Try before you trust](./09-try-before-you-trust.md).

Capable of failing is checkable, and this project checks it. Every ladder
verify script ships a `-FailCheck` mode that deliberately breaks things and
confirms the guarded checks go red. The recorded results:
pass 0026, 16 checks / 0 failed / 0 skipped, and `-FailCheck` 23 / 0 failed;
pass 0027, exit 0 across 31 checks with `-FailCheck` across 5 probes;
pass 0028, 7 of 7 checks passing with 4 of 4 probes demonstrating the guarded
checks can go red.

### Why the plan does not reproduce a long verify script

The protocol requires `verify.ps1` to be reproduced in a fenced block "only
when short enough that no reader will diff the two copies." Otherwise the
plan names its path and says what it checks. The reason:

> a second copy of an executable in the same commit can disagree with the
> first, and nothing makes them agree again.

It ties that to [hazard 6 in `evals/HARNESS.md`](../../evals/HARNESS.md) — a
stale expectation reporting the wrong answer confidently — "applied to the
one artifact whose job is to disprove the plan." And it names the outcome:
"A reader who diffs a fenced excerpt against the committed script and finds
them different has learned nothing about either."

This is the general shape of a whole family of bugs. Two copies of a truth in
one commit is one copy of a truth and one time bomb. Link, do not duplicate.

## The Deviations doctrine

### The rule

Deviations is **required, never omitted**. "Empty means writing 'none,' not
deleting the heading." Four things belong in it:

- anything in the prompt that was wrong, unclear, or impossible;
- anything done differently from the prompt, and why;
- anything discovered that the prompt did not ask about;
- any instruction followed that seems mistaken, flagged rather than silently
  obeyed.

The protocol calls it "the most valuable section" and backs the claim with a
count:

> Four of this project's strongest findings came from a pass reporting that
> an instruction was wrong or incomplete: a control probe of the wrong
> polarity, a comment-only control that could not discriminate, a refusal to
> author a suite the same pass was meant to grade with it, and a near-miss
> where a guard against a false negative was itself nearly a false positive.

Four of the strongest findings in a project built to find things. Not from
the agent doing what it was told well — from the agent saying the
instruction was wrong.

### Worked case: the acceptance test that could not pass

Pass 0017's prompt supplied an acceptance test. The test was red. The tag it
was checking was correct.
[`journal/0017-skill-roster.md`](../../journal/0017-skill-roster.md):

> `git ls-remote` matches a pattern against the tail of the ref name, so
> `--tags <url> v0.1.0` returns only the tag object and never
> `refs/tags/v0.1.0^{}` — neither alternative in the supplied regex can
> appear. And `Should -Match` tests each element of a piped array, so even
> with both lines returned the tag-object line fails it. Two compounding
> defects, and the test was red for a correct tag.

Two independent bugs in one supplied assertion, compounding, and a red that
meant nothing about the thing under test. The pass corrected the test
minimally, left the regex untouched, and falsified the correction against a
non-existent tag — so the fixed test was shown capable of failing before it
was trusted.

The same journal records a second, smaller deviation of the same species:
"The prompt's roster count disagrees with its own lists." Spot-check 1 said
nine roster paths; the acceptance test checked thirteen. The pass built
thirteen, said so, and made `verify.ps1` assert the directory holds *exactly*
those thirteen, so a leftover fails as loudly as a missing one.

### Worked case: the operator's own memory, contradicted by measurement

Pass 0013's prompt asserted something about the credential scan from memory.
Measurement disagreed.
[`journal/0014-seed-and-comparator.md`](../../journal/0014-seed-and-comparator.md):

> The operator's Pass 0013 prompt asserted that the committed scan could not
> match an 84-character token and would therefore report clean. It was
> asserted from memory; the pattern `[A-Za-z0-9]{52}` is unanchored, so a
> 52-character window inside an 84-character run matches, and Pass 0013's
> measurement showed the scan would have caught the real value.

Note where the record puts the fault: "Recorded here attributed to the prompt
rather than to the pass: the pass measured it and reported it, which is the
behaviour the rule asks for." The pass is not blamed for the operator being
wrong, and the operator being wrong is not quietly dropped either. Both facts
are in the journal, attributed.

### Worked case: recording the hit alongside the misses

The temptation, once a project starts logging bad instructions, is to log
only those.
[`journal/0019-history-unification.md`](../../journal/0019-history-unification.md)
declines:

> **Three consecutive passes each contained a SHA-level claim; the first two
> were wrong and this one was right.** 0017's acceptance regex could not
> match a correct tag, 0018's "fast-forward of `2c74531` → `79e02fb`" was not
> a fast-forward, and 0019's `d1647fa` was exactly correct. Recording the hit
> alongside the misses, because a record that only notes prompts being wrong
> misrepresents the rate.

One in three of those SHA-level claims was right, and the record says so.
A Deviations log that only ever fires on failures is a biased sample, and a
biased sample of your own instructions will teach you the wrong lesson about
how much to trust them.

### The point

**A prompt is not scripture.** You will get things wrong. You will assert a
SHA from memory, supply a regex that cannot match, mislabel a tier, or ask
for a control of the wrong polarity. That is normal and it is survivable.

What is not survivable is an executor that silently corrects you. A silently
corrected instruction produces a green pass and destroys the only evidence
that the instruction was bad — so you write the same bad instruction again
next month, and again, and nothing in the repository ever says the
instruction was the problem. The four strongest findings above exist only
because four passes wrote down that they had been told something wrong.

Ask for that behaviour explicitly, and read the section when it arrives.

## Push early

### What the protocol says

`PLAN-PROTOCOL.md`'s Commit section is two sentences:

> Commit the plan and the verify script with the pass's work, and push to the
> pass branch. The repository is the record; a pasted report is a
> convenience.

Read that as a statement about where the truth lives. A chat summary is
something you might paste to a colleague. The commit is the thing that still
exists after the session is gone.

### What went wrong, exactly once, and what it cost

The strongest form of the rule was earned. Pass 0022 was building
`PSGraphRenderToHtml`, and its first attempt did not finish.
[`journal/0022-tohtml-contract.md`](../../journal/0022-tohtml-contract.md)
states the outcome in its opening section: the pass was "Resumed after a
session limit interrupted the first attempt with 33 files uncommitted and
nothing pushed."

The plan states it again in Deviations, with the second half that matters:

> An overnight session limit cut the first attempt off with 33 files
> uncommitted and zero remote evidence.

Zero remote evidence is the phrase to sit with. The work existed — a whole
scaffolded module, 33 files that
[`plans/0022-tohtml-contract/plan.md`](../../plans/0022-tohtml-contract/plan.md)
inventories at §2 by running
`git status --porcelain --untracked-files=all` — but nothing outside one
machine's working directory knew it existed, and nothing anywhere recorded
what state it was in or whether any of it had been checked.

### The rule that came out of it

The rule is stated in pass 0022's own prompt, in its batch rules:

> **push early — the first commit of each pass goes to its remote branch
> immediately, and pushes follow every task group, because an interrupted
> session must never again leave zero remote evidence.**

It carried forward. Pass 0027's prompt has a section headed simply
"Protocol (push early, after every group)"
([`plans/0027-run-005/plan.md`](../../plans/0027-run-005/plan.md)).

### The recovery move worth stealing

What pass 0022 did on resume is the part to copy. It did not repair the
inherited files first. It committed them **unrepaired** and pushed that
commit before touching anything:

    4123ea7 Inherited from interrupted batch, unverified

The plan labels the task "evidence before repair" and records the result:
"From this point the work had remote evidence at every step, which is what
the batch rule asks."

Two things are true at once here, and keeping them separate is the whole
trick. The inherited tree was *evidence* — the honest starting state of a
resumed pass, worth preserving exactly. It was also *unverified* — nobody had
run its build. Committing it with a subject that says `unverified` records
both. Repairing first would have destroyed the starting state; leaving it
uncommitted would have risked losing everything a second time.

The pass then re-proved the inherited work rather than assuming it: the build
was run against the untouched files before anything was changed, producing 48
passed and 88.14% coverage, and each already-green item was re-proved by the
task that owned it.

### What this means for you

1. Create the pass branch and push the first commit before the work starts —
   the acceptance test alone is enough to have something on the remote.
2. Push after every task group, not at the end. The end may not arrive.
3. If you resume an interrupted pass, commit the inherited state unrepaired
   and push it first, with a subject that says it is unverified. Then repair.
4. Re-prove inherited work by the task that owns it. Partial green from a
   previous session is a starting state, not a result.

**An accuracy note.** This event is sometimes described as "the batch that
died with 33 untracked files," and the repository does record it — but at
pass 0022, not at pass 0025. Searching the tree with
`grep -rn "untracked" plans/ journal/ decisions/` returns seven hits, and the
ones that carry the story are `plans/0022-tohtml-contract/plan.md` and
[`journal/0022-tohtml-contract.md`](../../journal/0022-tohtml-contract.md).
Pass 0025's records
([`journal/0025-findings-batch.md`](../../journal/0025-findings-batch.md),
[`plans/0025-findings-batch/plan.md`](../../plans/0025-findings-batch/plan.md))
describe an entirely different pass — findings folded into skills, a fixture
case repaired, and the stable conformance denominator — and mention no
untracked-file incident. The number 33 is right, the rule is right, and the
pass number in the retelling is not.
