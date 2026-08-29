# METHOD — building agents that can be graded

A reusable method. Each rule is marked:

- **PORTABLE** — survives a domain change unedited. Copy as-is.
- **TUNE** — right shape, wrong specifics. Keep the structure, replace the
  nouns.
- **DOMAIN** — does not travel. Listed so it is visible as something to
  replace, not silently inherited.

## Precondition — does this method apply at all?

**PORTABLE.** This method depends on the agent's output being
machine-checkable. A PowerShell module either builds, lints, and exports
what its manifest claims, or it does not. Where output cannot be checked by
a program — copy, design, strategy, most writing — there is no oracle, and
the method degrades to rubrics and blind A/B comparison, which is far
weaker. Apply it anyway and you get the ceremony without the signal.

Decide this first. If the answer is no, use a different method.

## Sequencing

**PORTABLE.** Nothing is added until there is a way to tell whether it
worked. The grader comes before the first capability, so every capability
can be judged by the score it moves.

**PORTABLE.** Establish a baseline with zero capabilities before adding the
first one. What the bare model achieves is what every addition must beat.

**PORTABLE.** Build automation when doing it by hand becomes annoying, not
before. Notes from doing it manually are the specification for the tool.

## The grader

**TUNE.** Assertions carry a universality ladder: claims true of anything
in the domain, claims true of any project in the domain, claims that are
this organisation's convention, claims that need a built artifact. Names
are domain-specific; the ladder is not. Promotion up the ladder is a claim
and requires evidence from a second dissimilar target.

**PORTABLE.** An assertion does not count until it has a falsification row.
Any assertion added or changed gets a break, a confirmed red, and a restore
before any score including it is recorded.

**PORTABLE.** A falsification row needs a control as well as a break. The
break proves the assertion can fail. The control proves it fails for the
right reason.

**PORTABLE.** There are two kinds of control, and a positive assertion needs
both.

- A **scope control** adds text mentioning X while the behaviour is still
  present. The assertion must stay **green**. It guards against matching too
  much — against an assertion that fires on a comment, a neighbour, or a
  mention.
- A **substitution control** removes the behaviour and leaves text resembling
  it. The assertion must go **red**. It guards against inertness — against an
  assertion that a resemblance satisfies.

For a *negative* assertion — must not match X — the two collapse into one
probe. For a *positive* assertion they are independent questions and neither
implies the other. Twelve assertions in this project passed a scope control and
failed a substitution control; a comment-only probe cannot fail a positive
assertion while its code is still present, so it will pass an assertion that is
wholly inert.

**PORTABLE.** Never weaken or delete an assertion because a target fails
it. That is a finding and it goes to the operator.

**PORTABLE.** Prevalence is not correctness. A rule that most targets fail is
either wrong, or the targets are, and evidence about the rule decides — not the
failure rate. A low pass rate is a reason to examine an assertion; treating it
as an argument against one converts a grader into a survey of common practice.
Two assertions here had near-identical pass rates and went opposite ways: one
was a preference with no mechanical consequence and moved down the ladder, the
other described a real defect and stayed.

**PORTABLE.** Zero cases is not a pass. An assertion that produced no cases
is inapplicable and must report as such. Scores state cases-run beside
cases-passed.

**PORTABLE.** A score comparison is valid only when cases-run is stable between
the two runs, and any report comparing two scores states cases-run for both. A
repair that lets an assertion reach more of a target changes the denominator,
and the percentages are then not two measurements of the same thing. Note the
direction of the risk: an assertion that silently stops producing cases makes a
score go **up**.

**PORTABLE.** Ambiguous input fails loudly. A grader that silently grades
the wrong thing is worse than one that refuses. A fallback that picks the lone
remaining candidate is a fallback that picks the wrong one: deleting the
reference's own manifest here produced a confident score against a vendored
module rather than an error. Resolution rules end in a stop, never in a guess,
and the operator gets an explicit way to answer the question the grader could
not.

**PORTABLE.** Baselines are declared, not derived. The known-failure set is
a checked-in file of classified failures. Deriving it from the previous run
makes a bad run the next run's definition of good. It ratchets both ways:
an unlisted failure is new; a listed entry that stops failing is stale and
must be removed deliberately.

**PORTABLE.** Classifying a failure as "grader is wrong" versus "target is
wrong" is human judgment and is not automatable. The harness presents
failures for sorting with enough context to sort quickly; it does not
attempt to classify.

**PORTABLE.** Prefer semantic inspection over text matching. Text matching
produces both failure modes: matching something unrelated, and matching a
comment that documents the thing. Both have occurred.

## The falsification harness

**PORTABLE.** Preflight every expected assertion name against the assertions the
current grader actually produces, and hard-stop on one that does not resolve. An
assertion renamed by a repair invalidates every row naming it; the row's genuine
red then lands in the collateral column and the row reports as *does not fire* —
the exact false signal the protocol exists to detect, manufactured by its own
bookkeeping. Guard row-selection filters the same way: a typo in one silently
selected zero rows and reported a clean run. A run of zero rows is not a pass.

**PORTABLE.** Every break asserts that it actually changed the target before the
grader is re-run. A substitution that matches nothing leaves the target intact,
the run comes back green, and the row records *does not fire* — failing toward
the alarming answer, which is the one nobody double-checks. The same applies to
partial perturbation: a decoy covering one of the things an assertion reads,
while removing all of them, produces a red that proves nothing.

**PORTABLE.** Restoration is verified, not assumed, and the harness re-asserts
known-good before every row.

## Evidence discipline

**PORTABLE.** Distinguish observed from inferred. Anything claimed from a
single target is a hypothesis with an evidence count attached, not a fact.

**PORTABLE.** A single reference implementation is a closed loop. Rules
extracted from it, enforced by a grader derived from it, verified against
output built to satisfy it, prove only self-consistency. A second
dissimilar target is required before any claim of generality.

**TUNE.** The cheapest second target is usually an existing artifact you
did not make, not one you author. Look for a corpus you already have.

## Mechanism selection

**PORTABLE.** Deterministic work is a script. Judgment is a skill. Noisy or
capability-restricted work is a subagent. Must-never-happen is a hook.
Choosing prose for deterministic work is the most common error; the output
drifts where a script's would not.

**PORTABLE.** Prefer mechanical enforcement to instruction. Where a rule
can be made into a failing check, make it one. Where it cannot, say plainly
that you have guidance and not a guarantee.

## Diagnosability

**PORTABLE.** Trigger: any pass that adds a surface which can fail on
someone else's machine — a skill, hook, script, or server. Not passes that
fix the grader or write records.

**PORTABLE.** Definition of done for such a pass:
1. The failure is visible. It does not fail silently.
2. There is a named command that reveals why.
3. The symptom and its diagnostic are added to the troubleshooting document.
4. Prerequisites the surface assumes are checked, or their absence produces
   a clear error naming what is missing.

**TUNE.** Ship a domain doctor: one command that checks the prerequisites
your own thing needs, distinct from the platform's general diagnostics.

**PORTABLE.** Audit late. One pass near the end walks every shipped surface
and asks what a user sees when it breaks.

## Records

**PORTABLE.** Instructions live in files in the repository, not in chat. A
session restart clears the conversation and not the repository. Long
instructions go to a task file with a checklist the agent ticks.

**PORTABLE.** A file a pass must create is either already committed or its
full content appears verbatim in the prompt. There is no third channel.

**PORTABLE.** One journal entry per pass, written from that pass's
artifacts, never from memory. Six fields: Asked, Done (with paths), Why
(including what was rejected), Measured (citing an artifact, or "none"),
Learned (including what went wrong), Capability (what is now possible that
was not).

**PORTABLE.** Capability, not benefit. Benefit claims written mid-project
are predictions and several will be wrong. The summary document is written
once at the end, from the journal.

**PORTABLE.** A separate decisions log for choices that outlive a pass,
each with the alternatives rejected.

**PORTABLE.** Record failures. A project with no recorded failures reads as
untested, and experienced readers assume they were hidden rather than
absent.

## Safety rails

**PORTABLE.** Nothing publishes. No release, no tag, no push to the default
branch, unless the operator does it from their own shell. Pushing a pass
branch is expected.

**PORTABLE.** Destructive work happens in a disposable copy, never in
place. Refuse to run if the path is not under the scratch root or the tree
is dirty.

**TUNE.** Restoring a scratch copy needs more than reverting tracked files.
Untracked and renamed files survive a checkout. Know what your clean
command deletes and what it must not delete.

**PORTABLE.** Read-only references are read-only by configuration, not by
restraint. A reference in the editor's workspace is a writable working
directory and its own instructions load into the session.

## What this project supplied that you must replace

**DOMAIN.** Three repositories with fixed roles: a reference implementation
(read-only), the thing under test, and a target rebuilt from nothing.

**DOMAIN.** The domain itself: PowerShell, InvokeBuild, Pester, the
manifest schema, the build conventions extracted from one reference.

**DOMAIN.** Target-specific environment requirements discovered by failing:
dependency paths, tool versions, shell availability.

**DOMAIN.** The corpus used to break the closed loop.

## Known limits of this method

- It measures conformity, not utility. An artifact can satisfy every
  assertion and be useless. A separate functional check is required and is
  not part of the grader.
- It is expensive up front. Several passes produce a grader and no
  capability. On a small project, use the minimum: an oracle, falsification
  with controls, and a journal. Skip the harness and the decisions log. Do
  not skip the corpus: it is the cheapest part of the method when one
  already exists, and it is what breaks the closed loop — here it cost one
  pass and invalidated five of ten assertions in the tag it tested.
- It assumes one operator and one machine until a second person runs it.
  Absolute paths, tool versions, and install scopes are untested until then.
