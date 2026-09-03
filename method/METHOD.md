# METHOD — building agents that can be graded

The why-layer under this file is [method/PHILOSOPHY.md](PHILOSOPHY.md) — five
laws mapped to the artifacts that embody them. It explains this method; it
never overrides it, and a law is cited in a prompt only when it decides
something.

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

**PORTABLE. An assertion about a declaration is not an assertion about the thing
declared.** Checking that a gate is *declared* is a different claim from checking
that the gate *can fail*, and the first is routinely mistaken for the second
because both go green.

Two of this project's own gates were inert for exactly this reason. A `PreTag`
task was asserted to exist, and the default `Test` task was asserted to exclude
`PreTag`-tagged tests — both true — while no test carried the tag, so the gate
selected nothing and could only ever throw its own guard; nothing in the suite
could catch it, because nothing asserted that a tagged test exists. Separately, a
coverage gate copied from a skill compared a percentage against a threshold
inside an `if`, structurally exactly as specified, and could not fire: the test
runner returned nothing, so the comparison was `0 -lt $null`, and the build
printed a plausible coverage line and graded nothing across three independent
runs.

The rule that follows: for every gate, name the observation that would be
different if the gate were removed, and produce it. Declaration is evidence about
the document. Only a red is evidence about the gate.

**PORTABLE. Parallel scoring jobs must be isolated per clone.** When more than
one job scores the same artifact concurrently, each gets its own fresh clone of
the commit under test and touches no other job's working tree.

This is not tidiness. Three jobs sharing one tree produced a **false 51/56**: the
build job's `Clean` task deleted `output/` while the conformance job's
build-dependent assertions were reading it, and the resulting failures were
indistinguishable from real defects in the artifact. The score was wrong in the
direction that looks like a finding, which is the direction that costs the most
to chase.

Isolating the *tree* is necessary and not sufficient: the same defect recurs one
level up when two builds share a **process**, because the module imported by the
first build is still loaded when the second build's assertions run, and they
then grade the wrong artifact. Give each job its own clone and its own process,
and pay the wall-clock — about a minute, against a score nobody can trust.

**PORTABLE. An isolated clone must still be put into the state the assertions
grade — for a build-dependent assertion, that means building it.** "Each job
gets its own fresh clone" says where the job works; it does not say what the
job does there, and the two are not the same instruction. Four assertions in
this project's suite read `output/`, which is gitignored, so a conformance job
that clones and scores without building grades an empty directory and reports
the module as failing. **Run 007 reported 28/33 that way; the same commit built
first scores 32/33.** The three runs before it were unaffected only by accident
— each had build output in its conformance tree by a *different* improvised
route, so nothing in the record said which route was the rule.

The general form: **a scoring procedure is not fully specified until it says
what state the artifact is in when the assertions run.** An unspecified step
does not stay unspecified; each run invents it, the inventions differ, and the
scores stop being comparable without any of them being obviously wrong. Write
the procedure down as an executable — this project's is
`evals/conformance/Score-Clone.ps1` — so that the next run inherits the step
instead of re-deriving it.

Falsify the fix like any other gate. The unbuilt clone must still fail the
build-dependent assertions, a sabotaged build must fail them, and a built
conforming clone must pass; if the first row goes green, the "repair" quietly
weakened the assertions instead of correcting the procedure.

**PORTABLE. A NEW assertion whose reference target is already red is falsified
on a purpose-built known-good, and the target is measured separately.** The
protocol says break the reference; that instruction has no meaning when the case
a break would turn red is red before the break. Falsifying only against the red
target proves nothing about the green path, and repairing the target so that a
break has something to break rewrites history to fit the grader. So the
assertion's capability is proven on a fixture built to satisfy it — break goes
red there, control stays green there, polarity rules unchanged — and the
reference's real behaviour is then measured and Bucket-sorted as its own claim,
with the boundary said out loud: it predates the rule. Two claims, two
artifacts, and neither substitutes for the other. Recorded as
[decision 0015](../decisions/0015-falsifying-against-a-red-target.md), from the
eight help assertions of pass 0039 that first hit it.

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

> **Amended for this repository only, by
> [decision 0013](../decisions/0013-harness-release-tagging.md) (pass 0030).**
> One exception, and it is narrow: on a **release pass**, once that pass's
> acceptance test is green, the agent creates and pushes the annotated release
> tag `vMAJOR.MINOR.PATCH`. Nothing else moves — the default branch is still
> the operator's, `Publish-Module` is still never run, no tag is ever moved or
> forced, and no other kind of tag is created. The reason the exception is
> narrow enough to be safe: a tag is immutable and additive, so the agent can
> create one but cannot change what anyone already has, and consumers pin to
> tags precisely so that unreleased work never reaches them.
>
> The PORTABLE rule above is the one to copy into a new project. This
> amendment is not portable — it is earned by having a release pass with an
> acceptance test, and a project without one should keep the unamended rule.

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
