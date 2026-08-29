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

   > **Evidence: 1 target.** The default-versus-sealing distinction is drawn
   > from PSModuleGraph's task layout, where `PreTag` is a separate task
   > deliberately excluded from the default one. Whether other repositories
   > split their tasks that way, name the split differently, or do not split at
   > all is untested. The harness must discover this per target; it must not
   > assume a task called `PreTag` exists, nor that a red non-default task is
   > always safe to continue past.
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
without controls an over-broad assertion passes every probe. That is hazard 7.

The control's shape follows the assertion's polarity. For a positive assertion —
must match X — the control removes X and leaves text resembling X, and must go
**red**. For a negative assertion — must not match X — it adds text mentioning X
without the behaviour, and must stay **green**. A comment-only probe against a
positive assertion cannot fail while the code is present, and will pass an
assertion that is inert.

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

#### What the known-failure set is

**The persisted Bucket B classifications.** A checked-in file, not something
derived from a previous run — a run cannot be its own authority, or one bad run
silently becomes the next run's definition of good.

One entry per expected failure, keyed by **assertion name plus target**. Each
entry carries:

- the assertion's full name, exactly as it appears in `result.json`
- the target it applies to (the same assertion may be Bucket B on one module and
  a suite bug on another — `defines every function the manifest exports` is
  Bucket B against ImportExcel's two aliased exports and Bucket A against
  Pester's `.psm1`, and the key has to be able to say so)
- the reason, in a sentence
- a pointer to its FINDINGS entry

**It ratchets both ways.**

- A failure **not** in the file is new. It blocks. The run stops and reports it
  rather than folding it into a score.
- An entry that **stops failing** is stale. It also blocks — removing it is a
  deliberate act, because an expected failure that quietly disappeared is either
  a fix worth recording or a test that stopped running. Two of the corpus
  assertions produced zero cases rather than passing, which is exactly how a
  stale entry hides.

Neither direction may be resolved by the harness on its own.

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

**A partial decoy is the same defect wearing a better disguise.** One probe
removed every nested private function from the generated module but left a
decoy comment naming only *one* of them. It went red — on the names it had not
decoyed — and would have been recorded as "no defect found". Decoying all of
them showed the assertion was in fact satisfied by comments. A control must
perturb the whole of what the assertion reads, or its red proves nothing about
the question being asked.

### 5. `$env:PSGRAPHRENDER_MODULE_PATH` — unpublished dependencies and clone location

> **Evidence: 1 target.** Observed on PSModuleGraph only. The mechanism is
> confirmed; the generalisation at the end of this hazard is inference from a
> single example and has not been tested against a second module with an
> unpublished dependency. Treat it the way the suite README treats `Universal`:
> an intention until a second target shows the same shape.

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

### 6. A stale expectation reports a correct red as a missed one

**Failure it causes:** the harness records, per row, the name of the assertion
the break is supposed to turn red. Repair an assertion and rename it — as
happened when comment-based help was rekeyed from filename to function name —
and every row naming the old name silently stops matching. The row's genuine red
lands in the *collateral* column and the row is reported **does not fire**.

That is the precise false signal the whole protocol exists to detect,
manufactured by the protocol's own bookkeeping, and it fails toward the alarming
answer, so nobody eyeballing results for anomalies will dismiss it. It cost one
investigation of a healthy assertion.

**Requirement:** before running any row, resolve every expected-assertion name
against the assertions the current suite actually produces, and **hard stop** on
any that does not resolve. Not a warning: a warning is indistinguishable from
noise in a run that prints a hundred lines.

Two implementation notes, both learned the hard way:

- The name list must come from a **real run**, not from discovery. Pester's
  `Run.SkipRun` does not expand `-ForEach` names — they come back as the literal
  template, `gives <_.Name> ...` — so a discovery-only preflight hard-stops on
  every parameterised row. The guard against a false negative becomes a false
  positive.
- The same reasoning applies to row *selection*. A typo in the driver's
  `-Only` filter selected zero rows and reported a clean run. A run of zero rows
  is not a pass, and an unrecognised row name is an error.

### 7. A red probe alone does not finish an assertion

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

## Bucket A/B sorting is not automatable

Settled, in the negative. Three passes of sorting have produced no rule a
machine could apply, and the corpus run showed why: the same assertion failing
the same way is Bucket A on one target and Bucket B on another.
`defines every function the manifest exports somewhere in source` fails on
Pester because the suite globs `*.ps1` and misses the `.psm1` — a suite bug — and
on ImportExcel because two names in `FunctionsToExport` are aliases, not
functions — a real finding. The failure messages are near-identical. Nothing in
the result file distinguishes them; only reading the module does.

**The harness presents failures for sorting. It does not sort them.** For each
failure it must show:

- the assertion's full name and the text of the assertion itself
- the relevant excerpt from the target — the manifest lines, the file the
  assertion was reading, the definition it failed to find
- any prior classification of the same key (assertion + target), so a failure
  already sorted once is not re-litigated from scratch

That last point is what keeps the sorting cost from growing with every run.
A new key is the only thing that needs a human.

## Open questions

Things this spec does not settle, flagged rather than guessed:

- **Multiple targets, partly answered.** `Universal` has now run against nine
  targets — the reference plus the eight-module gallery corpus. Five of its ten
  assertions survive all nine; one has been exercised on only three, because it
  is scoped to a directory six of the targets do not have. See
  `conformance/baseline/UNIVERSAL-CORPUS.md`. What is still open is whether the
  harness should run corpus targets routinely or only when a tag's claims
  change.
- **Whether the harness should fix the two blockers it just found.** Running
  against a published module currently requires restaging the target and a
  runner flag (`Run.FailOnNullOrEmptyForEach`). Both were done by hand and
  outside the committed tree for the corpus pass. Whether they become harness
  responsibilities or suite fixes is a decision about where the boundary sits,
  not a detail.
- **Per-target expected-failure files versus one file.** The known-failure set is
  keyed by assertion plus target; whether that lives as one file or one per
  target is unresolved. Nine targets is where the question starts to matter.
