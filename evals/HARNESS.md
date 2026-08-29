# Run harness — specification

What the harness must do. **Specification only. No code here, and none written
yet.** This is the write-up of doing two conformance passes by hand; the hazards
below are the ones that actually bit, each with the failure it produces, not a
list of things that might in principle go wrong.

The harness's job: take a module repository, produce a conformance score that
means something, and record enough alongside it that the score can be read later
without the run being repeated.

## What a run consists of

1. **Place the target.** A scratch clone at a known commit. Never the operator's
   working checkout — see hazard 5 for why the clone's *location* is itself a
   variable that has to be handled.
2. **Phase 0: does it build?** Run the target's own build. Record each command,
   its exit status, and for any red the failing test names.
3. **Gate on Phase 0.** If the default build task is red, stop. A conformance
   failure against a target that does not build is unattributable: a suite bug
   and a genuine divergence from a broken reference look identical. Distinguish
   the target's *sealing* tasks (PreTag and similar) — those may be red without
   blocking, and the harness needs to know which is which per target rather than
   assuming.
4. **Score.** Run the conformance suite at both tag sets, writing each result to
   an explicit path.
5. **Sort the failures** into suite bugs and real findings.
6. **Falsify anything new or changed** before the score is recorded.

Step 6 is not optional and not last-if-there-is-time. Two assertions have
already entered a scoring run without a confirmed red, and one of them was inert
from the day it was written — it passed every green run for free and contributed
a point to a published figure while testing nothing. The rule in the suite README
is the load-bearing one: **an assertion does not count until it has a
falsification row.**

## Falsification: what the harness runs

Per row: confirm the clone is at known-good, apply exactly one break, re-run,
record, restore, confirm known-good again. Every one of those steps is an
assertion the harness makes, not an assumption it holds.

Outcomes it must distinguish:

- **Fires** — the expected assertion goes red, nothing else does.
- **Does not fire** — the assertion stays green through its own break. The
  finding that matters most, and the one a careless harness reports as success.
- **Over-fires** — other assertions go red too. Name them. Sometimes correct
  (see the wildcard-export coupling in FALSIFICATION.md), so this is a fact to
  record and judge, not an automatic fault.
- **Correctly stays green** — a *control* row, where the break is one the named
  assertion must not notice.

A harness that only knows "should go red" cannot express a control row, and
without controls an over-broad assertion passes every probe. That is hazard 6.

## The hazards

### 1. `git checkout -- .` does not restore the clone

**Failure it causes:** silent cross-contamination between rows. A break that adds
an untracked file (a nested `Public/Sub/Get-Thing.ps1`) or renames one
(`PSScriptAnalyzerSettings.psd1`) survives the restore, so the next row runs
against a target that is still broken from the last one, and its result is
attributed to the wrong break.

**Requirement:** restore is `git checkout -- .` **and** `git clean -fd`,
followed by an assertion that `git status --porcelain` is empty. Restoration is
verified, never assumed.

**And never `-x`.** Build output is gitignored in a typical module repo.
`git clean -fdx` deletes it, and every subsequent `RequiresBuild` row then
grades an absent psm1 — silently, because the assertions read a missing file as
empty string rather than erroring. The result is a plausible-looking run of
false reds attributed to whatever break happened to be current.

### 2. "Green" is the known-failure set, not zero failures

**Failure it causes:** a real target has standing findings. The reference has
one: an exported command no test invokes. A harness that checks "zero failures"
before each row either never starts, or — if someone relaxes it to a count — will
happily proceed when one failure is silently swapped for a different one.

**Requirement:** known-good is an explicit *set* of failure names, compared by
name. Any failure not in the set aborts the row and says which. Never a count.

### 3. A rebuild row needs two rebuilds

**Failure it causes:** rows that break the psm1 emitter need the target rebuilt
after the break — and again after the restore. Skip the second and a psm1 built
from broken source stays on disk, so the *next* row fails. The symptom appears
one row late, attributed to an innocent break.

**Requirement:** rebuild after break and after restore, both. The build-only task
is sufficient and much faster than the full default task; nothing about the
generated-module assertions needs the target's test run. The harness should know
which rows are build-dependent rather than rebuilding unconditionally.

### 4. A regex-applied break needs a did-this-change-anything guard

**Failure it causes:** the worst one available. A substitution that silently
matches nothing leaves the target unbroken, the suite runs green, and the row is
recorded as **does not fire** — a false report of exactly the defect the whole
protocol exists to detect. It fails toward the alarming answer, so it will not
be caught by someone eyeballing results for anomalies.

**Requirement:** every break asserts the file actually changed before the suite
is re-run, and aborts the row if not. Two breaks were caught by this guard
during development of the Pass 1 driver.

### 5. `$env:PSGRAPHRENDER_MODULE_PATH` — unpublished dependencies and clone location

**Failure it causes:** the reference resolves an unpublished `RequiredModules`
dependency from a *sibling checkout*. A scratch clone has no sibling, so the
build throws — correctly, and for a reason that has nothing to do with the suite
or the target. Phase 0 goes red and every rebuild fails. Read naively, this is a
broken reference; it is actually the harness's own choice of clone location.

**Requirement:** the harness must know, per target, which unpublished
dependencies exist and where to point them, and set the documented environment
variable before any build. It must record that it did so alongside the Phase 0
results, because a later reader comparing scores needs to know the build was
given a dependency it could not have found itself.

**Generalise this.** The specific variable is PSModuleGraph's; the shape is not.
Any target with a dependency resolved by convention from its own location has a
convention that a clone breaks. The harness should treat "this target builds only
at its original path" as a property to discover and satisfy, not a surprise.

### 6. A red probe alone does not finish an assertion

**Failure it causes:** an assertion scoped too widely passes every break aimed at
it and is still wrong. The coverage assertion scoped to the whole Test task,
rather than to the coverage gate inside it, goes red under both of the breaks
that target it — and also goes red when an unrelated `throw` elsewhere in the
same task is deleted. Red probes cannot tell those two assertions apart.

**Requirement:** support control rows — a break plus the requirement that a named
assertion stays green — as a first-class outcome. Without the distinct outcome
type, a control row's correct result is recorded as "does not fire" and reads as
a failure.

## What a run must record

Enough that the score can be read months later without rerunning it:

- target identity and commit; the exact clone path
- every Phase 0 command, exit status, failing test names, and any environment
  the harness supplied to make the build work (hazard 5)
- both result files, at explicit paths — never a default path relative to the
  working directory, which is how a zero-test result once ended up tracked at a
  repo root
- the failure sort: suite bugs fixed, real findings left alone, with reasoning
- the falsification table, including controls, and including which assertions
  were new or changed in this pass

## Open questions

Things this spec does not settle, flagged rather than guessed:

- **Where the known-failure set lives.** Checked-in per target, or derived from
  the previous run's result file? Derived is less to maintain and much easier to
  corrupt — a bad run becomes the next run's definition of good.
- **Whether the harness should sort failures at all.** Bucket A/B sorting was a
  judgement call both passes; it may not be automatable, in which case the
  harness should present failures for sorting rather than attempt it.
- **Multiple targets.** Everything above assumes one target at a time. The
  `Universal` tag's whole purpose is a second, deliberately dissimilar target,
  and nothing here has been tested against one.
