# 04 — Fresh sessions and contamination

A number is only worth what you can say about the state of the thing that
produced it. If you cannot describe what the agent knew when it built the
module, you do not have a measurement — you have an anecdote with a
percentage attached.

This chapter is about the machinery that lets you say what the agent knew,
and about the four or five channels that leak knowledge without looking
like they leak anything. Most of them are boring. That is exactly why they
work.

If you have not read [00 — Start here](./00-start-here.md), start there;
this chapter assumes you know what a run and a pass are. The chapter that
follows this one on the same theme is
[05 — Calling bullshit](./05-calling-bullshit-verification.md), which is
about checking an agent's claims once the run is over. This one is about
the state the run began in.

## The words you need first

**Session.** One continuous conversation with the agent. Everything in it —
your messages, the agent's replies, the contents of every file it opened,
the output of every command it ran — sits in one shared buffer.

**Context window.** That buffer. The agent can read all of it, all the
time. There is no partition inside it between *things I was told* and
*things I happened to see while looking for something else*.

**`/clear`.** The Claude Code command that empties the context window and
starts a new session. It is the only thing that reliably makes an agent
forget.

**Harness and target.** In this repository the *harness* is this repo — the
plugin, the tests, the records. The *target* is the module being built,
`PSAzureDevOpsGraph`. The harness measures; the target is measured.

**Oracle.** The hand-written right answer. Here it is
[`evals/functional/fixture/expected-graph.json`](../../evals/functional/fixture/expected-graph.json)
— 49 nodes and 51 edges written by a person, against which a module's
output is diffed. An agent that has read the oracle can reproduce it
without understanding anything.

**Blind build, or Phase 1.** The stretch of a run during which the agent
builds the module having read only what it is permitted to read. It ends at
a push. After that push the score is fixed and the gate lifts.

**Allowlist.** The explicit list of what a run's session may read during
Phase 1. Everything not on it is forbidden.

**Preconditions.** Checks run before any work, each with the command that
checked it and its output. Any failure stops the pass.

**First shot.** The score of the very first version the agent pushed,
before it was allowed to look at any diff. It is the only number in a run
that is about the agent rather than about the agent plus a feedback loop.

## Why the prompt has to be message one

The rule this repository runs on is
[hazard 9 in `evals/HARNESS.md`](../../evals/HARNESS.md):

> The rule: **a measured run's prompt is the first message of a brand-new
> session**, and anything preceding it in that context - file contents,
> tool output, prior conversation - disqualifies the session.

Read that twice, because the second clause is the one people drop.
"Brand-new session" is easy. "Anything preceding it" is the hard part: it
does not say *anything you told it*, it says *anything preceding it in that
context*. A file the agent opened ten minutes ago while helping you with
something else is in the context. A command whose output scrolled past is
in the context. A conversation you had yesterday and never thought about
again is in the context if you never cleared it.

The reason is not tidiness. It is that the agent cannot un-know. Once a
score, a diff, or a field convention is in the window, every subsequent
answer is conditioned on it, and no instruction to "ignore what you saw"
changes that. There is no partial credit and no half-blind session. The
session is either clean or it is not a measurement.

So the procedure is two steps and it is not negotiable:

1. `/clear`.
2. Paste the run prompt as the first message. Nothing before it.

## What actually contaminates

The obvious sources are obvious. The oracle file. The scoring diff. The
comparison report. Nobody argues about those.

The surprising ones are the point of this section.

### Run records — including their prose

Hazard 9 puts it in five words: run records are **oracle knowledge in
prose**. Open [`runs/004-plugin-on/README.md`](../../runs/004-plugin-on/README.md)
and count what a reader learns without ever touching the oracle:

- the conformance score, 33 / 33;
- the functional score, 1 / 12 first shot and 12 / 12 final;
- the number of first-shot differences, 26;
- the four mechanisms that produced them, by name, with counts — `repo`
  omitted from `pipeline` nodes (15), `alias` written on `template` /
  `extends` / `checkout` edges (8), `reason` written as a bare code rather
  than `code: explanation` (2), and `repo:consumer-app` missing (1).

That last group is not a hint. It is the answer key for three of the four
decisions a blind builder has to make, written out in English, in a
document that looks like a project write-up rather than like a spoiler. A
session that has read it cannot produce an independent first-shot number
afterwards, whatever else it does.

The same applies to [run 005](../../runs/005-plugin-on/README.md) and
[run 006](../../runs/006-plugin-on/README.md), and to their `findings.md`
files, which are longer and worse.

### Commit subjects

This is the one that catches people who did everything else right.

[Hazard 11](../../evals/HARNESS.md) states the mechanism: `git log` runs at
the preconditions of every measured run, so **a commit subject is read by
sessions that must not read run records**. Checking that the tree is clean
and the branch is right requires looking at the log. The allowlist cannot
forbid the log, because the log is how the allowlist's own preconditions
get checked.

The hazard gives the bad subject as its example — a subject of the form
*"Run 004: 12/12 functional, 33/33 conformance"* — and the convention that
replaces it:

> The convention: **run and pass commits carry no scores in their
> subjects.** Scores live in run README bodies and plan bodies, which the
> allowlist does forbid.

The real commit that landed run 006 is the model:

    Run 006: the last plugin-on rung, and the one thing that varied

It says what the commit is. It does not say how it scored. Something
*varied* — you cannot get a number out of that.

This is not theoretical. Pass 0027 found it live and could not fix it from
inside. [`journal/0027-run-005.md`](../../journal/0027-run-005.md) records
that `git log` at preconditions is unavoidable and that one earlier
commit's subject carries run 004's totals. It was written down as a
convention for future commits rather than patched, because rewriting
history to hide a score is worse than the score.

You can watch the channel working correctly in pass 0026's own
preconditions table, in
[`plans/0026-run-004/plan.md`](../../plans/0026-run-004/plan.md). The
session-gate row reads:

> **held.** No file content, tool output or prior turn preceded it. The
> environment block carried commit *subject lines* only, which are
> repository metadata, not run-record prose.

The agent's opening context genuinely contained recent commit subjects. The
gate held only because those subjects had been written to be safe.

### Branch names and tag names

Hazard 11 closes with the corollary: the same applies to branch names and
tag names, which `git branch -a` and `git tag -l` surface just as readily.
The measurement branches here are named `run-004-plugin-on`,
`run-005-plugin-on` and `run-006-plugin-on` — a rung, not a result.

One caution follows from the same logic and is worth carrying: an annotated
tag has a *message*, and this project's tag messages do carry scores.
[`journal/0017-skill-roster.md`](../../journal/0017-skill-roster.md) records
`v0.1.0` "carrying its three scores in the tag message", and
[`journal/0019-history-unification.md`](../../journal/0019-history-unification.md)
records `v0.2.0`'s "message carrying the carried-forward scores." A tag
message is a body, like a README body. `git tag -l` shows you names and is
safe; anything that prints the message is a read of a run record.

### The fixture, when the fixture is chatty

The three channels above can all be closed. This one cannot, and the reason
it belongs here is that it went unwritten for five runs.

**The thing under test is inside the allowlist too.** A functional run's
task is to read the fixture and produce a graph of it; forbidding the
fixture forbids the run. So whatever the fixture *says* is inside the blind
phase, permanently.

This project's AzDO fixture is annotated. Its YAML carries leading comments
that name the cases and state what each one is for — one reads, in part,
*"Both exist, so the wrong answer is a wrong file rather than an error."*
Every run from 002 onward has read them, by design of its own task. The
fixture is frozen, so this cannot be fixed without invalidating five runs'
worth of comparability; it is
[hazard 13](../../evals/HARNESS.md), and it is disclosed rather than
repaired.

Two things follow that generalise past this project.

**Fix your vocabulary to what is actually true.** "Blind" here means the
oracle, the prior run records and the plugin were unread. It has never meant
the fixture was unread, and saying "blind" without that qualifier was an
overstatement in every run record written before 007.

**Write the next fixture without the annotations.** The commentary is
genuinely useful — it is how a maintainer remembers what each part is for —
so put it in the *oracle* document, on the far side of the gate, and leave
the fixture mute. Pass 0033 scanned this project's second fixture, the
Terraform one, for the same vector and found it worse: it names cases by
number and one of its READMEs points at the oracle by path
([the scan](../../plans/0033-honest-headline/tf-fixture-comments.txt)). That
fixture is frozen too, so a blind run against it is now blocked on a
decision rather than merely unscheduled. **The cost of a chatty fixture is
paid at the moment you want a blind measurement, which is long after the
moment it is cheap to fix.**

## Hazard 10 — the half with no visible failure mode

Everything above has a symptom you could in principle notice. This one does
not.

[Hazard 10](../../evals/HARNESS.md) states the rule in one sentence:

> **No score, fixture finding, or oracle content may ever be written to
> session memory, `MEMORY.md`, `CLAUDE.md`, or any other auto-loading
> location.**

The asymmetry is the whole hazard. A context window is cleared by `/clear`
and a new session genuinely starts blind. An auto-loading file is not
cleared by anything. It is re-read at the start of every session, forever —
that is what "auto-loading" means. So one score written to memory does not
contaminate one run. It disqualifies every future session, and nothing
announces it. There is no red test, no warning, and no artifact that looks
wrong. The runs simply stop measuring what they claim to measure.

Say the last part of hazard 10 out loud before you build anything on top of
it:

> There is no way to check afterwards whether a past run was contaminated
> by a memory file that has since been deleted.

You cannot audit this after the fact. Deleting the file removes the evidence
along with the problem. The only defence is that the locations were empty at
the time, verified then, and recorded then.

### The check, concretely

Hazard 10 names three paths and the state each must be in. Verify them at
every blind run's preconditions:

    <project>/memory/           empty, no MEMORY.md
    harness CLAUDE.md           absent
    harness .claude/            absent

Two notes on doing this without defeating it. List *filenames only* — if you
print the contents of a memory file to check what is in it, you have just
loaded whatever it says into the session you were about to measure. And run
the check in the measuring session, not in a helper session, because the
claim you need is about this window.

That is how pass 0026 did it. Its preconditions table in
[`plans/0026-run-004/plan.md`](../../plans/0026-run-004/plan.md) carries a
memory-directory row whose command column reads "listing of filenames only"
and whose result reads "**empty.** No `MEMORY.md`, no memory files". The
method is in the middle column. "Filenames only" is the part that makes the
check safe to perform.

## The observable controls

Now the useful half of the chapter: what you can actually check, as opposed
to what you have to take on trust.

### Session identifiers

Each of the three plugin-on runs records the identifier of the session that
produced it, in its README's metadata block:

| Run | `session-identifier` |
|---|---|
| [004](../../runs/004-plugin-on/README.md) | `b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db` |
| [005](../../runs/005-plugin-on/README.md) | `cc4d301c-ed6d-476f-90d9-63b324a62658` |
| [006](../../runs/006-plugin-on/README.md) | `f0302223-28f1-436d-85f3-04e168c8534c` |

Three distinct values. Run 004's README states the requirement plainly:
`session-identifier` must differ in each of the three, which is what proves
they were three sessions. Hazard 9 says the same from the other end — the
three distinct values "are what makes the claim checkable rather than
asserted."

**The trap run 006 records is worth the detour**, because it is the kind of
thing you only meet by building the check. Run 006's acceptance test asserts
that its record does not match either predecessor's identifier, and it
matches against the *whole document*. So the obvious way to prove the
point — writing "differs from run 004's `b0a48c69…` and run 005's
`cc4d301c…`" — makes the assertion go red, because a document that quotes
both strings is indistinguishable, to a whole-document regex, from a
document that is one of those runs.

[`runs/006-plugin-on/README.md`](../../runs/006-plugin-on/README.md) states
it in the record itself:

> The other two identifiers are deliberately **not** quoted here. The
> acceptance test asserts that this record does not match either of them,
> and it matches the whole document — so a record that quoted its
> predecessors' ids to prove it differs from them would fail the assertion
> that checks it differs from them.

The assertion was not weakened. It was specified verbatim in the pass prompt
and was left exactly as given; the *record* was rewritten to name the two
files rather than reproduce the strings. That decision is recorded as F-17
in [`runs/006-plugin-on/findings.md`](../../runs/006-plugin-on/findings.md),
whose one-line summary is the general lesson: the check can see the
document, it cannot see the run.

The table above quotes all three ids because this chapter is not graded by
that assertion. Run 006's record is.

### Allowlists

An allowlist turns "be careful what you read" into a list you can check
against. Pass 0028's is two sentences, in
[`plans/0028-run-006/plan.md`](../../plans/0028-run-006/plan.md):

> Allowlist: the seed, `BRIEF.md`, `graph.schema.json`, the plugin, this
> prompt, the run directory. Everything else forbidden, explicitly
> including `runs/`, `cases.md`, `expected-graph.json` and
> `fixture/repos/`.

Two features make it work. It is *positive* — a short list of what is
allowed, not a long list of what is not, so a file nobody thought of is
forbidden by default. And it names the four dangerous paths explicitly
anyway, so nobody can argue the edge cases afterwards.

### Existence by line count

Sometimes a precondition has to confirm that a run record *exists* without
reading it. Hazard 9 gives the technique in one clause:

> Preconditions that must confirm a run record exists check it by **line
> count** (`git show main:<path> | wc -l`), never by reading it.

The output is an integer. An integer is not oracle knowledge. You have
proved the file is there and learned nothing about what it says.

Pass 0028 used it. Its precondition 6 reads "004 and 005 READMEs exist on
`main`, by line count only", with the result "135 and 257 lines, contents
not read." The same idea is applied one row up in the same table: the oracle
blob was located by SHA with `git ls-tree | grep`, which the plan notes
"finds the path without opening the file."

    git show main:runs/004-plugin-on/README.md | wc -l

Paste that instead of opening the file, every time.

### "Declined, not breached"

The most interesting control is the one where two instructions disagree and
the agent has to choose in the open.

The plugin's own `/build` command, at step 1, tells the builder to read the
conformance suite before writing code. The run's allowlist forbids reading
it. So a blind run faces an instruction from the tool it is being measured
on, telling it to do the thing the measurement forbids.

The recorded behaviour is to decline and to say so.
[`runs/006-plugin-on/findings.md`](../../runs/006-plugin-on/findings.md)
records it as F-6:

> **Recurred, a third time. Declined, not breached.** `commands/build.md`
> step 1 says to read `evals/conformance/Conformance.Tests.ps1` before
> writing code. The Phase 1 allowlist forbids it. It was declined, the
> consequence was stated at the time, and the module was built from the
> skills alone.

The run's Provenance section carries the count that goes with it: allowlist
breaches, **zero**.

Those two facts belong together. "Zero breaches" on its own would be a
suspiciously clean number. "Zero breaches, and here is the specific
instruction we refused and what refusing it cost" is a claim you can
inspect. The cost is stated too, and it is not small: the conformance score
therefore measures whether the skills are a faithful proxy for assertions
the session never read. Run 006's answer to that question is 33/33 at first
shot, from a fresh clone.

The distinction generalises. A **breach** is reading something forbidden. A
**decline** is refusing an instruction that would have caused a breach, and
recording the refusal and its consequence. A run reporting zero of both is
either very well specified or not telling you something.

## The honest limit

Say this part plainly, because it is easy to bury under the controls above.

**Freshness is not provable from inside the session.** An agent asked "was
your context clean when this prompt arrived?" is being asked to audit the
one thing it cannot see from outside. Look again at pass 0026's session-gate
row: its command column reads "inspection of the context." That is the agent
examining its own window and reporting. It is the honest method and it is
also the weakest row in the table.

What you *can* check is **separateness**. Three distinct session identifiers
prove three sessions. They do not prove that any one of the three began
empty. The identifiers make one specific lie — running three "independent"
runs inside one session — impossible to tell without being caught. They do
nothing about a session that started dirty.

So the correct summary of the evidence is: separateness is demonstrated,
freshness is asserted by the party with the incentive, and the hygiene rules
in hazards 9, 10 and 11 exist to make the asserted half as small as
possible. Anyone claiming their agent evaluation proves more than that has
not looked closely at the same problem.

And there is a second limit, added by pass 0033 after two more channels were
found: **even a genuinely fresh session is not an uninformed one.** Its
prompt is inside its own allowlist (hazard 12) and so is the fixture it must
read (hazard 13). Freshness bounds what the session *remembers*; it says
nothing about what the session is *handed*. Both halves have to be checked,
and only the first one has a control.

## The real self-stop

The reason this chapter lives in a repository rather than in a style guide
is that the gate fired, cost a session, and was written down.

Pass 0025 read [`runs/002-first-build/README.md`](../../runs/002-first-build/README.md)
and [`runs/003-baseline-off/`](../../runs/003-baseline-off/) — legitimately.
It needed to rebuild those clones to falsify a change to the conformance
denominator, work described in
[`journal/0025-findings-batch.md`](../../journal/0025-findings-batch.md).
That reading had nothing whatever to do with the fixture's answers.

It burned the session anyway. Hazard 9:

> Pass 0026 stopped at its own gate because the preceding pass had
> legitimately read `runs/002-first-build/README.md` and
> `runs/003-baseline-off/` in order to rebuild those clones for a
> denominator falsification. The reading had nothing to do with the
> fixture's answers and burned the session anyway.

The same event is recorded from the operator's side as backlog item 12 in
[`LEDGER.md`](../../LEDGER.md), which is where the rule lived until it could
be folded into `evals/HARNESS.md`. `evals/` was frozen behind the ladder, so
the rule waited in the ledger and landed at pass 0029, described in
[`journal/0029-final-readme.md`](../../journal/0029-final-readme.md).

Note what the rule does *not* care about. Intent is irrelevant. Relevance is
irrelevant. The pass was not looking for answers and did not find any. The
gate is mechanical — this context has touched `runs/`, therefore this
context is not a blind builder — and a mechanical gate is the only kind that
survives an agent with a motive to keep working.

Passes 0026, 0027 and 0028 each opened a fresh session for exactly this
reason. Pass 0026's run is recorded in
[`journal/0026-run-004.md`](../../journal/0026-run-004.md).

**An accuracy note.** You may hear this described as "the session that
stopped itself three times." That is not what the artifacts say, and the
real shape is more useful. What is recorded is one session-gate stop — pass
0026's, in hazard 9 and in LEDGER item 12 — and three passes each opening a
fresh session because of it. Three other stops are recorded elsewhere and
are different animals: pass 0027 stopped at task 1 on a truncated prompt
([`journal/0027-run-005.md`](../../journal/0027-run-005.md)); an earlier
issue of pass 0012 stopped at its preconditions with `$env:AZDO_PAT` unset
([`journal/0012-case-split-and-corrections.md`](../../journal/0012-case-split-and-corrections.md));
and an earlier issue of pass 0010 stopped at precondition 4 with nothing
committed ([`journal/0010-plan-protocol.md`](../../journal/0010-plan-protocol.md)).
Four recorded stops, four different causes, one of them the session gate.
Journal 0012 draws the moral for all of them: a gate that stops a pass is
cheaper than one that does not.

## The corollary that costs the most

Here is the leak that survived every control on this page, because it came
in through the one door the allowlist has to hold open.

**A run's prompt is inside its own allowlist.** It has to be — the agent
must read its instructions. So anything you write in the prompt is inside
the blind phase by construction.

Pass 0028's prompt asked run 006 to write a variance section comparing
itself against runs 004 and 005. To specify that task, the prompt stated the
prior runs' first-shot mechanisms and counts: 15 `repo`-on-pipeline, 8
`alias`-edge, 2 bare `reason`, 1 missing `repo:consumer-app`. Those four
lines are three quarters of the answer key, and they sat inside the blind
phase's own allowlist.

Hazard 9 records this as the corollary that costs the most, and the run
recorded it against itself. From
[`runs/006-plugin-on/README.md`](../../runs/006-plugin-on/README.md):

> It was flagged before any code was written and deliberately not acted on:
> the four conventions were chosen from the schema and `producer-contract`
> alone, and three of the four were chosen *wrongly*, in the same directions
> as 004 and 005. The independence of the first-shot number is weakened by
> the prompt and is not established by this run alone — but a run steered by
> that list would have scored above 1/12, and this one did not.

Three things to take from how that was handled.

The run **flagged it and did not act on it**. It is declared in pass 0028's
Deviations ([`plans/0028-run-006/plan.md`](../../plans/0028-run-006/plan.md))
and in [`journal/0028-run-006.md`](../../journal/0028-run-006.md), before
any code was written.

The run **did not claim to be exonerated**. Getting three of four
conventions wrong is evidence the leak did not steer the build, and the
record says so while calling that evidence weak. The journal's phrasing is
the standard to hold yourself to: it is "weak evidence that the leak did not
steer, and is stated as weak in the run record rather than as exoneration."

And the limitation **survives into the top-level summary**. The root
[`README.md`](../../README.md), under "Status, honestly", carries the line:

> **Run 006's prompt leaked** the prior runs' difference mechanisms into its
> own blind phase. Flagged and deliberately not acted on — three of four
> conventions were still chosen wrongly — but the independence of that run's
> first-shot number is weakened and is stated as weakened in its record.

That is the test of whether a caveat is real. A caveat that lives only in
the artifact nobody reads is decoration. This one is on the front page.

Hazard 9's own prescription for next time is one sentence, and it is the
thing to write on a card: write the variance requirement without the
answers, or accept that the third run's first-shot line is not independent.

### It happened again, on the run the headline depends on

The prescription above was written after run 006 and was not followed. Run
007's prompt — the control run, the one the project had been waiting for —
named the same four mechanisms and their counts, for the same reason: its
task 7 asked for a comparison, and the comparison needed the list.

The damage is worse this time, and the reason is worth understanding. Run
006 was the third of three identical runs; its first-shot number was already
corroborated twice over. Run 007 was **one** run, and its first-shot figures
are the entire evidence for the sentence now on the front page — that the
control's first shot was the closest of the five. Three of the four leaked
mechanisms recurred anyway. The fourth, the 15-difference
`repo`-on-`pipeline` mechanism, did **not** — and that absence is most of
why 007's first shot beat the ladder's. It is also precisely what a leak
would most plausibly have prevented.
[`runs/007-baseline-iterated/findings.md`](../../runs/007-baseline-iterated/findings.md)
C-2 states it flatly: the run cannot separate "read the brief carefully"
from "was told the answer" for that mechanism.

So the same defect, committed twice, cost a corroborated number the first
time and an uncorroborated one the second. That is the shape of this kind of
mistake: it does not get more likely, it gets more expensive, because you
only build a control once.

Pass 0033 promoted the rule out of hazard 9's tail and into a hazard of its
own — **hazard 12, "prompt-borne oracle content"** — on the principle that a
corollary two runs have tripped over is not a corollary. Its wording is the
generalisation: **the prompt itself is a contamination channel**, and it is
the only one an allowlist cannot close, because the allowlist is written in
the thing being read. Mechanism lists, difference counts, expected values,
convention names and prior scores do not go in a measured run's prompt. A
comparison specification goes **after the gate**, referring to prior run
records generically — "compare against the mechanisms recorded in the prior
run records" — so the *scorer* resolves the reference and the builder never
sees what it resolves to.

The cheapest test, which is step 6 of the checklist below and which nobody
ran twice in a row: read the prompt as if it were the only thing you knew,
and ask what it just told you about the answers.

## A checklist you can actually run

Before a measured run, in the session that will do the measuring:

1. `/clear`. The run prompt is the next thing typed.
2. Confirm the three auto-loading locations from hazard 10 are empty, by
   listing filenames only — never by printing their contents.
3. Check the tree and branch with `git status --porcelain` and
   `git log --oneline -5`, knowing that the subjects you are about to read
   are inside the measurement. If a subject carries a score, the session is
   already spent.
4. Confirm any run record you need to *exist* with
   `git show main:<path> | wc -l`. Never open it.
5. Write the allowlist into the prompt as a positive list, and name the
   dangerous paths explicitly anyway.
6. Read your own prompt back and ask what it tells the agent that the agent
   is supposed to work out for itself. That is where the leak will be. Two
   runs have now failed this step — 006 and 007 — so treat it as the step
   most likely to be skipped, not the one most likely to be clean. If
   deleting a phrase would cost the builder information about the oracle,
   that phrase belongs in the scoring instructions instead.
7. Record the session identifier in the run record, so the next run can be
   shown to be a different one.

Afterwards, when you write the commit: say what the commit is, not how it
scored.

The mechanics of the pass that wraps all of this — the plan file, the
preconditions table, the deviations section — are
[06 — The pass protocol](./06-the-pass-protocol.md). The red-first
discipline that the acceptance tests in this chapter depend on is
[03 — Test first, or nothing](./03-test-first-or-nothing.md).
