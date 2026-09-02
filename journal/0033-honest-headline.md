# 0033 — the headline came down, and two of the numbers under it were wrong

Pass 0032 ran the control and drafted the sentence the README would need. It
deliberately did not apply it: the release surface was tagged and rewriting it
is a pass that owns the release. This is that pass. It turned out to be three
jobs, not one, because you cannot honestly rewrite a claim without first
checking that the numbers under it were measured the same way — and two of them
were not.

## The claim that came down

The README said the plugin's effect was large on shape and "nearly flat" on
behaviour, with a table whose plugin-off column had no final cell. That table
compared a first shot against a converged result and called the difference the
plugin.

What five runs actually support:

> All four runs that were permitted to iterate reached the functional oracle
> exactly — 12/12, zero differences — within two fix iterations, and the
> control's first shot was the closest of the four. What the plugin reliably
> supplies is first-shot conformance to house style: 33/33 against 19/33, about
> fourteen assertions not derivable from the brief. **It buys shape, not
> correctness** — and a single control cannot tell us whether that is because
> the conventions are the hard part or because the dependency computation was
> never the hard part for this model.

The last clause is the one worth defending. It would have been easy to write
"the plugin does not help with correctness" and stop; that is a stronger claim
than one control against three runs of one instrument on one fixture can carry.
The honest version says which question is still open.

## Then the numbers moved

Backlog 24 said `RequiresBuild` and the three-clone scoring rule were
incompatible and the gap was overstated by four. Working it produced something
sharper than expected.

Four assertions read `output/`, which is gitignored. The protocol said "score
from a fresh clone" and said nothing about building it. So run 007's conformance
clone was never built and those four graded the absence of a directory: 28/33
reported, 32/33 for the same commit built first.

The obvious story — *the ladder had the same bug and nobody noticed* — is false,
and the transcripts say so. Each ladder run had build output in its conformance
tree by a **different improvised route**: 004 ran the build inside the
conformance clone, 005 scored a snapshot of an already-built tree, 006 built all
three clones. The written rule permitted all four readings and named none.

That is the actual finding and it is bigger than four assertions. **An
unspecified step does not stay unspecified.** Each run invents it, the
inventions differ, and the scores stop being comparable without any of them
looking wrong. Nothing goes red. Nobody is careless. The comparison is just
quietly not a comparison.

The fix is a script, `evals/conformance/Score-Clone.ps1`, because a sentence in
a document is what four runs each interpreted differently.

## Making a number go up is not evidence

A procedure change that improves a score is the most suspicious artifact this
project can produce. From the outside it is indistinguishable from quietly
weakening the assertions.

So: three rows plus a gate control, before any new number was believed. An
unbuilt clone must **still** fail those four — it does, at exactly the 28/33 the
old procedure produced, which is the row that matters. A sabotaged build must
fail them — it does. Without `-ScoreAnyway`, a red build must refuse to become a
score at all — it does. A built conforming clone must pass — run 006, 33/33,
zero failed assertions.

And run 006 was re-scored **because it was expected not to move**. A re-score
that touches only the number you suspect has told you nothing about whether the
new procedure is sane. It read 33/33 at both its commits, unchanged. That is the
control on the repair, and it cost two extra clones.

The wrapper also taught something on its first run. It passed `-Task .` to the
target's build, and run 007's *first shot* declares
`[ValidateSet('Clean','Build','Test','All')]` with no `.` task — so the build
failed on parameter validation and the gate correctly refused to score it. A
scoring wrapper must invoke the target's **own** default, because a
non-house-style build file is one of the things being graded. The bug was in the
instrument, aimed at exactly the commits the instrument exists to measure.

## What re-deriving the first shots cost

The prompt asked for both finals. Both first shots were scored too, because the
README's headline is a first-shot comparison and would otherwise have inherited
the defect this pass exists to fix.

007's first shot moves 19/33 → 20/33. One of the four recovers; the other three
stay red on their merits, because the psm1 that first shot produced is not
marked generated, does not set `$script:ModuleRoot`, and does not export exactly
the manifest surface.

And that one assertion breaks a nice observation. Run 007's record says it and
run 003 "scored identically on conformance at first shot — 19/33". They did not:
003's clone was built (its own result file shows `produced output/...psm1`
passing) and 007's was not. Under one procedure they are 19 and 20. The larger
point — two blind sessions, the same five mistakes, one property apart — is
untouched, and the correction is in both records.

Losing a coincidence to a corrected procedure is the right trade, but it is
worth noticing how attractive the coincidence was. It made a better story than
the truth does.

## The two disclosures, and why one of them stings

**Hazard 12 — a measured run's own prompt is inside its own allowlist.** Run 006
recorded this against itself and hazard 9 was amended with the prescription:
write the comparison requirement without the answers. Pass 0032's prompt then
did the same thing to run 007, for the same reason, in nearly the same words.

The cost was not the same, and that is the part to carry. Run 006 was the third
of three identical runs; its first-shot number was already corroborated twice.
Run 007 is **one** run, the only control the project has, and its first-shot
figures are the whole evidence for the sentence now on the front page. Three of
the four leaked mechanisms recurred anyway; the fourth — the 15-difference
`repo`-on-`pipeline` mechanism — did not, and it is most of why 007's first shot
beat the ladder's. It is also exactly what a leak would most plausibly have
prevented.

Writing a rule down was not enough to stop it happening a second time. That is
why it is a hazard now instead of a corollary.

**Hazard 13 — the fixture names its own cases.** The `ClaudeTesting` YAML
carries comments identifying each case and stating what it is for, and reading
the fixture *is* the task, so every run since 002 has read them by design. The
fixture is frozen. Stripping it now would invalidate five runs' comparability,
which costs more than the bound.

So it is disclosed, and the vocabulary is corrected with it: **"blind" means the
oracle, the run records and the plugin were unread. It has never meant the
fixture was unread.** A bound that has always applied and gets written down only
when it becomes inconvenient reads, later, exactly like a bound that was
invented then. Run 007 wrote it down; this pass put it where it belongs.

## The Terraform fixture is worse

The same scan against `evals/tf/fixture/repos/`, read-only, 40 files. Not clean.
One comment reads *"Case 3, the cross-repository output reference"* — the case
number, by name. A variable description reads *"The absence case: a graph that
invents a reference for this is wrong"*. The case-5 dependency chain is drawn as
an arrow diagram in a comment on line 5 of the file a builder opens first, with
each link numbered at the site where it occurs. And `TfFixtureShared/README.md`
tells the reader to *"see `evals/tf/fixture/cases.md` in the harness for what
each part is a case for"* — a pointer from inside the fixture to the oracle.

Nothing was amended; decision 0011 freezes it. But tf-003 was the blind
generalisation measurement, and a fixture that labels its own cases measures
parsing rather than generalisation. It moves to the top of the backlog as a
**decision**, not a run, with three costed options. The recommendation is a
second, unannotated fixture, because it also answers backlog item 9 — the three
`tf-<role>` skills that were deliberately not written for the same family of
reason. Two open questions, one artifact.

The general rule, now in chapter 04: the commentary is genuinely useful, so put
it in the **oracle** and leave the fixture mute. The cost of a chatty fixture is
paid at the moment you want a blind measurement, which is long after the moment
it is cheap to fix.

## v1.0.1, and the release that would not validate

A docs/method patch under decision 0013. `skills/` and `commands/` byte-identical
to `v1.0.0`; only the manifest version moves.

Except the prompt pinned the release to "the single version line" under
`.claude-plugin/`, and there is no single version line. There are three:
`plugin.json.version`, `marketplace.json.metadata.version`, and
`marketplace.json.plugins[0].version`. Bumping only the manifest makes
`Publish-Local.ps1` go red — *"committed entry 'psmodule' version '1.0.0'
disagrees with plugin.json version '1.0.1'"* — which was observed rather than
predicted, and which is the validator pass 0030 falsified on all six of its
rules doing its job.

All three were bumped, the validator passes, and `verify.ps1` asserts the
stronger form the constraint was reaching for: `skills/` and `commands/`
byte-identical, and every changed line under `.claude-plugin/` a version field
going 1.0.0 → 1.0.1. It is LEDGER item 28, because the one-line rule is written
down in more than one place and is not true of the tree.

## What this pass is really about

Three of its six tasks were corrections to things this repository had already
written down and already believed. The claim was overstated. The scoring
procedure had a hole nobody could see because four runs each filled it
differently. Two contamination channels had been true for five runs and named in
one record.

None of that surfaced from a red test. It surfaced from run 007 writing down the
*channels* its corrections came through instead of only its score, and from this
pass re-running numbers it could have quoted. That is the whole argument for
re-derive-don't-quote, and it is now a worked example in chapter 05 rather than
a rule in a list.

The headline is smaller than it was. It is also the first one that five runs
support.
