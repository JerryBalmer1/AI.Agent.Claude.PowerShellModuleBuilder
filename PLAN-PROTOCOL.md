# Plan protocol

Every pass executes against a prompt and produces a plan file. This
document is the format. It lives in the repository rather than in a
conversation because a session restart clears the conversation and not the
repository.

## Pass numbering

The operator assigns NNNN in the prompt header. `plans/NNNN-<slug>/`,
`journal/NNNN-<slug>.md` and the header all use it. The agent never invents
a pass number. A prompt arriving without one is a stop.

### The frontier is read from three sources, every pass

Before anything else, the pass establishes what the last landed number actually
is, from three independent sources:

1. **LEDGER** — the `Last landed:` line.
2. **The plans tree** — the highest `plans/NNNN-*` directory.
3. **The journal tree** — the highest `journal/NNNN-*.md`.

Two checks on what comes back, and they are different checks:

- **Is the assigned number free?** A `plans/NNNN-*`, a `journal/NNNN-*`, a
  LEDGER citation, or a `pass-NNNN-*` branch **in any workspace repository**
  bearing the number the prompt assigned is a stop. Branches count because a
  stranded pass branch is the one form of "already taken" that leaves nothing
  in the working tree to notice.
- **Do the three sources agree with each other?** A disagreement is a stop and a
  finding, and it is reported rather than resolved inside the pass. Which source
  is right is not always the majority: "landed" means a plan *and* a journal
  entry, so the trees carry the fact and the LEDGER line carries a summary of
  it. Record all three values in the plan either way, agreeing or not.

The reason for three sources rather than the counter alone is that the counter
is the one that drifts, and it drifts silently. Commit `b404734`, immediately
before pass 0044, is a correction of exactly that: LEDGER read `Last landed:
0040` while `git ls-tree origin/main` answered `plans/0041-operator-ux` and
`journal/0041-operator-ux.md`. Nothing was wrong with the work; one line
summarising it had fallen a pass behind, and any pass that had taken the counter
at its word would have re-used a number that was already spent.

The same disease reaches the backlog numbering, where it is worse because the
numbers are cited. Pass 0031's prompt asked for a backlog item as "17"; 17 and
18 were already taken by pass 0029, and it landed as 19 with its wording
unchanged — recorded rather than silently renumbered, because a backlog item
whose number moved is one somebody will cite wrongly later. Read the next free
number off the file, never off the prompt.

## File supply

A file a pass must create is either already committed to the repository, or its
full content appears verbatim in the prompt. There is no third channel.
"Supplied by the operator" without content in the prompt is a defect in the
prompt, not a lookup task, and the pass stops on it rather than searching or
inventing.

This rule exists because it has already cost a pass twice: once silently, when
a missing draft blocked a task and the pass carried on without saying so, and
once loudly, when the same gap stopped a pass at its preconditions. The loud
failure is the correct behaviour.

## Location

    plans/NNNN-<slug>/plan.md      one directory per pass
    plans/NNNN-<slug>/verify.ps1   the verification script, full tier only
    plans/NNNN-<slug>/*            any output the plan cites

Nothing to do with plans goes in the repository root.

## Tiers

The prompt states the tier.

**full** — the pass changes executable behaviour: an assertion, a script, a
hook, a skill, a manifest, a runner. Requires preconditions, a red-first
acceptance test, per-task evidence, a command transcript, a verify script,
deviations, cost.

**light** — the pass writes records only: journal, decisions, method,
briefs, protocol. Requires preconditions, per-task evidence, a diff
summary, deviations, cost. No acceptance test and no verify script. A test
asserting that a document contains a heading proves only that a heading
exists, and invites writing to the test.

### What decides the tier

The tier is decided by whether the pass changes executable behaviour. It is
not decided by whether the pass writes documents, nor by how many, nor by
their length. A pass that writes six documents and touches no executable is
light. A pass that writes six documents and amends one assertion is full,
and the six documents do not make it any less so.

The failure mode this rule prevents is a pass whose bulk is prose acquiring
the tier of its bulk rather than the tier of its risk, so that the one
change that could break something ships without a red-first test or a
verify script.

**Worked example — pass 0012.** The prompt labelled it light. Its visible
bulk was documents: it split the case set by presence and absence and
corrected four of them. But it also amended an assertion in
`Fixture.Tests.ps1`. That single amendment made it a full-tier pass
mislabelled as light.

It is a near miss and not a casualty, which is the more useful half of the
example. The pass shipped the full-tier artifacts anyway — plan 0012 §3
records the red-first run at `RED-FIRST: Passed=315 Failed=15 Total=330`,
every failure in the amended assertion, and §7 is the verify script. They
exist because the *prompt* happened to require them, not because the tier
label asked for anything: the label said light, and light says in terms
"no acceptance test and no verify script". Had the prompt been consistent
with its own label, the one change that could break something would have
shipped untested.

The pass flagged the disagreement in Deviations 7 rather than absorbing it,
and named the rule this section now states — that "changes an assertion"
should decide the tier rather than "writes documents". That is the correct
behaviour and the reason the rule is written down here.

A pass that believes its stated tier is wrong says so in Deviations and
executes at the higher tier. Tier is a floor, never a ceiling.

## Uncommitted changes the pass did not make

A pass begins on a clean working tree. When the tree is dirty at
preconditions with a change the pass did not make and which is not pass
work — an editor-written setting, a stray local edit — that change is
committed on its own, before the pass begins, with a message naming it as
unrelated.

Not reverted: it may be deliberate, and the pass does not get to decide
that.

Not stashed: a mid-pass failure strands it in the stash, where the next
session will not find it.

Not carried: staging paths individually to keep it out of the pass commit
puts it one mistake away from being in the pass commit, and the pass commit
is the record of what the pass did. That record is worth more than the
convenience of not making a second commit.

## The recovery phase

A hard stop ends a pass. The next prompt then has to get the repositories from
wherever the stop left them back to a state a pass can start from, and writing
that as prose for a human to perform by hand wastes the one artifact the stopped
session produced: it knew exactly what it had and had not done.

So a hard-stop report **may** carry a recovery phase for its own re-issue — a
numbered, machine-executable sequence placed ahead of Section 0, which the
re-issued prompt runs before its preconditions. Five rules govern it.

**It is idempotent, and every step is check-then-act.** The phase is pasted into
whatever session comes next, at whatever state that session finds. A step reads
the state first and skips itself when its work is already done, so a second run
of the same file is a no-op that reports "nothing to do" rather than an error or
a repeat. This is not a nicety: the phase's whole purpose is to be safe to run
when nobody is certain what the previous session finished.

**Operations already authorized by a standing decision are pre-ratified.** A
recovery step that does what a committed decision already says to do needs no
new approval — it is the decision being carried out, late.

**Ruling-class operations are not.** Abandoning a pass, changing the composition
of the workspace, anything adjacent to a ⛔ — these execute only under the
operator's approval of the re-issue itself, and the phase says so at the step.
The distinction is who decided, not how risky it looks: a pre-ratified step is
one the operator has already ruled on, and a ruling-class step is one where
running it *is* the ruling.

**A one-time authorization is scoped to the file it appears in.** Where a
recovery step needs an act that is otherwise never an agent action, the prompt
grants it explicitly, once, for that act only, and restates that every other
prohibition on the same object stays in force.

**A session-unreachable step terminates the phase.** Anything baked in at launch
— the session's working-directory list, its permissions, its model — cannot be
changed by any prompt run inside that session. A phase reaching such a step does
not attempt it, does not work around it, and does not continue past it: it
prints the operator's remaining touches and ends with a **stop-and-relaunch**
instruction, and the re-issued prompt is pasted into the fresh session. A phase
that carried on here would be reporting success on a condition it cannot see.

**Worked example — Phase R, pass 0043.** Six steps: state check, two commits,
relocate a reference clone out of the workspace (the one-time authorization,
move-not-copy, no git operation against the clone), a recovery state table, and
R6, a session gate. First run: R1–R5 executed and R6 stopped the session dead,
printing the two operator touches. Second run, in the fresh session: R1–R5 each
found their work already done and skipped, R6 passed, and the pass proper began
at Section 0. Both runs are recorded in that pass's plan, and the second run is
the evidence that check-then-act was real rather than intended.

## Sync and handoff

The two acts that bracket a pass. Both are about the state a pass finds the
repositories in and the state it leaves them in, and neither belongs to any
one task.

### Sync — the first act of every pass

Before preconditions are recorded, every workspace repository is fetched and
its `main` fast-forwarded, so the pass branches from what is actually there
rather than from what was there last session.

After fast-forwarding, report any `pass-*` branch whose tip is
not an ancestor of its repository's `main` — a stranded branch
surfaces at the next pass's preconditions, not releases later.

### Local handoff — the last act of every pass

After remote pushes and main fast-forwards, the agent returns the operator's
workspace to inspectable truth: for every workspace repository — checkout
`main`, `git pull --ff-only`, `git fetch --tags --prune`, `git status` clean
— then print a LOCAL STATE table (repo | branch | HEAD | clean) as the final
output of the pass. "Done" means the operator's editor shows the result with
zero commands: inspect what you expect, with nothing to figure out first. A
diverged branch or dirty tree is reported, never resolved. A pass that ends
without the LOCAL STATE table is not done.

## plan.md structure

### 1. Prompt

The prompt as received, verbatim, in a fenced block. Not summarised, not
tidied. This is what makes the plan auditable a month later.

### 2. Preconditions

Each precondition, the command that checked it, and its output. Any failure
stops the pass here, and the plan is committed showing the stop.

### 3. Environment

pwsh version, Pester version, OS, Claude Code version, branch, HEAD at
start.

### 4. Acceptance test — red first (full tier)

The test as run, the command, and the failure output proving it was red
before any work began. A test already green stops the pass: either the work
is unnecessary or the test cannot fail. Both are findings and both go in
Deviations.

### 5. Tasks

The `- [ ] Task` list, ticked as completed, with evidence directly under
each item:

- the command run and its relevant output
- files created or changed, by path
- for any number stated, the artifact it came from and the command that
  produced it

Evidence is what a reader needs in order to believe the task happened
without trusting the sentence above it. Numbers cite artifacts. Never a
figure without a file behind it.

### 6. Acceptance test — green (full tier)

The same test, the same command, passing.

### 7. Command transcript

Every command that changed state, and every command whose output produced a
number appearing anywhere in this plan. Exploratory reads are excluded.
One fenced block, so it copies in a single action.

### 8. Diff summary (light tier)

`git diff --stat` for the pass, plus one line per file on what changed and
why. This replaces the acceptance test at this tier: the diff and the
operator's reading of it are the honest artifact, and dressing that up as a
green test would be worse than not having one.

### 9. Verify script (full tier)

`verify.ps1`, committed beside the plan, and reproduced in a fenced block
only when short enough that no reader will diff the two copies. Otherwise
the plan names its path and says what it checks.

The reason for the exception: a second copy of an executable in the same
commit can disagree with the first, and nothing makes them agree again.
That is hazard 6 in `evals/HARNESS.md` — a stale expectation reporting the
wrong answer confidently — applied to the one artifact whose job is to
disprove the plan. A reader who diffs a fenced excerpt against the
committed script and finds them different has learned nothing about
either.

It must:

- assume nothing but a fresh clone of this repository and the tools
- re-derive rather than read: re-run the suite and compare against the
  committed result JSON; never parse this plan
- re-run every spot-check the prompt named, by name
- exit 0 when everything it checks agrees, non-zero otherwise, printing
  which check disagreed
- never depend on `scratch/`, which is not committed and does not exist in
  a fresh clone

The script exists so the operator can disprove this plan without reading
it. Write it to be capable of failing.

### 10. Deviations

Required, never omitted. Empty means writing "none," not deleting the
heading.

- anything in the prompt that was wrong, unclear, or impossible
- anything done differently from the prompt, and why
- anything discovered that the prompt did not ask about
- any instruction followed that seems mistaken, flagged rather than
  silently obeyed

This is the most valuable section. Four of this project's strongest
findings came from a pass reporting that an instruction was wrong or
incomplete: a control probe of the wrong polarity, a comment-only control
that could not discriminate, a refusal to author a suite the same pass was
meant to grade with it, and a near-miss where a guard against a false
negative was itself nearly a false positive.

### 11. Cost

Wall-clock for the pass, plus any run counts the pass produced — suite
runs, probe rows, build invocations.

No token count. The agent cannot measure one from inside the session, and a
field it cannot measure is a field it guesses at. This project's own rule
is that a number without an artifact behind it does not belong in a plan,
and that rule does not stop applying because the number is about the agent.
If a token count is wanted it has to come from the host.

## Signals, reports and records

The four conventions that govern how a pass talks to the operator. Each has a
numbered record in `docs/ux/` saying what went wrong without it.

### Routing signals and the tripwire

Every prompt leads with a routing circle — 🔴 NEW SESSION
(/clear first, paste as message one, nothing before it),
🟢 SAME SESSION (paste into the waiting session, do not
/clear), or 🔵 NOT A PROMPT (for the human; paste
nowhere) — and states its final line up front as
"ENDS WITH: <line>" so a truncated delivery is visible
before anything runs. Shape is the kind of signal, color
is the value, and the word always rides the marker. A
block without a routing circle is asked about, never
guessed at.

### The five task signals

Every step in a prompt carries one of five markers,
and the word always rides the marker:

- 🔴 **Hard stop.** Fails → stop, report, never
  resolve.
- 🟠 **Operator action.** Agent verifies, never
  performs.
- 🟢 **Agent task.**
- 🔵 **Evidence gate.** Observed and recorded in
  `plan.md` before the next step opens.
- ⛔ **Never**, for the pass's whole duration.

These are *task* signals and are distinct from the
routing circle above, which says where a whole block
goes. Three markers are common to both and mean
different things — 🔴 is NEW SESSION in the routing
circle and a hard stop here — so the disambiguator is
position, not colour: the routing circle leads the
block and appears once; task signals appear inline
against steps. Never put a task signal on the routing
line.

The constraint the legend survived: the markers passed
every grep and parse they met in passes 0043 and 0044,
including a red-first acceptance test that matched them
by Unicode code point and correctly reported four of
five present and one absent. A convention that a
checker cannot see is a convention that only holds
while people are watching.

### The report contract

Every pass report ends with "## YOUR NEXT ACTION" — one
plainly-stated action for the operator, or "none: hand
this report to the director." A hard stop leads with
"⛔ STOPPED — <one line why> — YOU NEED TO: <one line>"
and puts the forensics below it. During execution the
session prints a heartbeat at every task boundary
("[n/N] <task> — <estimate>") so silence has a shape;
heartbeats carry no scores on measurement lines.

### UX conventions have records

Every operator-experience convention in this repository
has a numbered record in docs/ux/ — problem, why, what
it solves, evidence — written before the convention
ships. A convention without a problem statement is
decoration and does not land.

## Formatting

Every block the operator may copy — the transcript, the verify script — is
a fenced code block with a language tag, so it copies in one action. Never
split a copyable block with prose.

## Commit

Commit the plan and the verify script with the pass's work, and push to the
pass branch. The repository is the record; a pasted report is a
convenience.

**Commit and push after every task, in every pass.** A task is not done until
its commit is on the remote — not when the edit is made, not when the gate goes
green. Work that lives only in a working tree is invisible to `git status` *as
progress*: it is indistinguishable from work not started, and unrecoverable by
anyone but the process holding it.

This is here rather than in a prompt because a rule that lives only in prompts
is repealed by the first prompt that forgets it. **No prompt's brevity overrides
it, and a prompt that omits it has not repealed it.** Pass 0052 was stopped by
its operator on twenty-three files of finished, unpushed work; the cause was an
authoring defect, its task spine compressed past the line that says to push.
Finding 73 in `LEDGER.md` carries the account, and `PSGraphRender/docs/HANDOFF.md`
repeats the rule beside that repository's own commit conventions — repeated
deliberately, because a pass targeting a different repository reads a different
handoff and must still meet this.
