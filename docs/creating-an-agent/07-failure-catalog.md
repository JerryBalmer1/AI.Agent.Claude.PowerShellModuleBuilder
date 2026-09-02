# The failure catalog

Every rule in this manual exists because something below happened first.

That sentence is the whole point of this chapter, so it is worth spelling
out before you read a single entry. The method in
[method/METHOD.md](../../method/METHOD.md) and the thirteen hazards in
[evals/HARNESS.md](../../evals/HARNESS.md) look, on the page, like a list of
sensible precautions somebody thought up in advance. They are not. Each one
is a scar. Somebody wrote a check that could not fail, or graded the wrong
file, or reported a probe as run when it had never applied, and the rule is
what was left after the wreckage was cleared away.

If you skip to the rules you get the conclusions without the evidence. You
will read "an assertion does not count until it has a falsification row" and
think it sounds like ceremony, because at that point it is ceremony — it
stays ceremony until the day one of your own green checks turns out to have
been green since birth, for free. This chapter is here so you can borrow the
evidence instead of generating your own.

Nothing here is an embarrassment. A project with no recorded failures reads
as untested, and experienced readers assume the failures were hidden rather
than absent — that judgement is in
[method/METHOD.md](../../method/METHOD.md) under Records, and it is why the
journal has a **Learned** field that is required to include what went wrong.
Every entry below is quoted or paraphrased from a file in this repository
that was written at the time, by the pass that got it wrong.

---

## How to read an entry

Every entry has the same three parts, in the same order:

- **Happened** — the defect, concretely, with its mechanism.
- **Caught by** — what actually surfaced it. This is usually the more
  interesting half, because most of these defects were invisible to
  inspection and several were invisible to a passing test suite.
- **Rule** — what the project changed as a result: a hazard, a method rule,
  a decision record, or a line in a protocol.

Each entry links the journal entry, run finding, or hazard it comes from.
Where two entries are the same shape, they say so and link both. A defect
that recurs is a stronger finding than a defect that happens once, and
several of the shapes below recur four and five times.

Two words you need. **Red** means a check failed; **green** means it passed.
A **probe** or a **break** is a deliberate injected defect, used to find out
whether a check can go red at all. Chapter
[09](./09-try-before-you-trust.md) is about that practice; this chapter is
what the practice found.

---

## Gates that could not fail

A gate is a check that stops something bad from shipping. The recurring
lesson of this group: **a gate that has only ever been green is
indistinguishable from a gate that cannot go red.** You cannot tell the two
apart by reading. You can only tell them apart by breaking the thing the
gate guards and watching what happens.

**The coverage assertion that matched the word "throw".** *Happened:* the
assertion `throws on coverage below target rather than only reporting it`
matched the regex `(?s)CoveragePercent.*throw` against the reference's build
file. `(?s)` plus an unbounded `.*` means any `throw` anywhere after the
first mention of `CoveragePercent` satisfies it, and that build file
contains nine. *Caught by:* two checks past what the falsification row
required. With the coverage `throw` deleted, the assertion stayed green on
the word "throw" in the *comment explaining the throw*; with that comment
also deleted, it stayed green on a Pester version guard thirty-odd lines
further down. No edit to the coverage gate could turn it red. *Rule:* an
assertion does not count until it has a falsification row, now stated in
both [method/METHOD.md](../../method/METHOD.md) and
[evals/HARNESS.md](../../evals/HARNESS.md). The assertion had passed in
every green run since it was written, contributing a point while testing
nothing.
([journal 0005](../../journal/0005-establish-the-baseline.md))

**The repair that passed both its probes and was still wrong.**
*Happened:* the fix for the assertion above was scoped to the whole `Test`
task rather than to the coverage gate inside it. That version passes both
red probes aimed at it and is still wrong — it would also go red when an
unrelated `throw` in the same task is deleted. *Caught by:* a third row, a
*control*, which breaks something the assertion must **not** notice and
requires it to stay green. One of the two guards that control deletes sits
inside the `Test` task but outside the gate, which is what makes it a
discriminator rather than a formality. *Rule:* a red probe alone does not
finish an assertion — hazard 7, and the two-kinds-of-control rule in
[method/METHOD.md](../../method/METHOD.md).
([journal 0006](../../journal/0006-fix-the-inert-assertion.md))

**A control that failed after twelve breaks had found nothing.**
*Happened:* adding a *comment* reading "never set `Run.Exit = $true` here",
with no code changed at all, turned the assertion `throws rather than exits
when tests fail` red. A build file whose author documented the hazard would
fail the assertion that checks for the hazard. *Caught by:* the control
sweep; twelve preceding breaks had all behaved. *Rule:* controls became a
first-class outcome in the harness rather than an optional extra. This is
the exact mirror of the inert coverage assertion — one fired on something it
should ignore, the other ignored everything, and only a control could see
either.
([journal 0007](../../journal/0007-controls-tag-split-corpus.md); the sweep
itself is
[CONTROL-SWEEP.md](../../evals/conformance/baseline/CONTROL-SWEEP.md))

**The prescribed control was the weaker of the two probes.** *Happened:*
the control protocol at the time added a comment mentioning a setting while
the setting itself was still present. That cannot break a positive
assertion, so it passes assertions that are wholly inert. *Caught by:*
running the other polarity — deleting the behaviour and leaving text
resembling it. Five assertions passed the comment control and failed the
deletion probe in one pass;
[journal 0009](../../journal/0009-correct-the-control-protocol.md) records
that twelve assertions carrying only the weak control had missed three
defects the stronger one found in one sitting, and
[method/METHOD.md](../../method/METHOD.md) states that twelve assertions in
this project passed a scope control and failed a substitution control.
*Rule:* a positive assertion needs **both** controls, and they are
independent questions — a scope control (add a mention, must stay green) and
a substitution control (remove the behaviour, must go red).
([journal 0008](../../journal/0008-repair-universal-tag.md))

**An assertion that passed against nothing.** *Happened:* `node ids are
unique` passed with no fixture on disk, because zero ids contain no
duplicates. *Caught by:* the red-first rule — the test was run against
nothing before it was run against something. *Rule:* the assertion now
carries a count guard. Written after the fixture it would have been green
from birth and indistinguishable from a working assertion. This was the
third inert assertion the project had found by that point.
([journal 0011](../../journal/0011-fixture-design.md))

**An assertion that produced zero cases and read as part of a green run.**
*Happened:* a comment-based-help assertion enumerated `Public/*.ps1`, which
six of the eight corpus modules do not have. It did not pass and it did not
fail; it did not run — and a check that does not run reads, inside a total,
exactly like a check that agreed with you. *Caught by:* the corpus pass,
which put the suite in front of modules shaped unlike the reference. *Rule:*
**zero cases is not a pass.** An assertion that produced no cases is
inapplicable and must report as such, and scores state cases-run beside
cases-passed ([method/METHOD.md](../../method/METHOD.md)).
([journal 0007](../../journal/0007-controls-tag-split-corpus.md))

**A lint gate green on a file that does not parse.** *Happened:*
`Severity = @('Error','Warning')` in the analyzer settings — the idiom every
example shows — filters out `ParseError`, which is its own severity. The
`Lint` task reported clean on a source file that produced nine cascading
parse errors on import. *Caught by:* one stage later, by the tests, and only
because the tests import the *built* module. A repository whose tests did
not would have shipped a green build over an unparseable file. *Rule:*
`ParseError` belongs in the severity list, and the
`powershell-module-build` skill now says so. The uncomfortable part is in
the journal: the skill that prescribed the wrong setting was written by the
same pass, four hours earlier.
([journal 0016](../../journal/0016-first-build.md))

**A sealing gate that had never run, twice.** *Happened:* a `PreTag` task
existed with no `PreTag`-tagged test, so the task's own zero-test guard
failed it on every invocation — a task that can only fail is not a gate. The
same shape appeared again in PSTerraformGraph, where `PreTag` had been
declared since v0.1.0, and v0.1.0 was tagged without the gate that seals a
tag ever having run. *Caught by:* somebody running it. In the second case
the conformance suite could not have caught it: the suite asserts the task
is *declared*, and that the default task excludes `PreTag`-tagged tests, and
both were true the whole time. *Rule:* **an assertion about a declaration is
not an assertion about the thing declared**
([method/METHOD.md](../../method/METHOD.md)) — for every gate, name the
observation that would be different if the gate were removed, and produce
it.
([journal 0022](../../journal/0022-tohtml-contract.md),
[journal 0025](../../journal/0025-findings-batch.md))

**A test that passed vacuously on a hashtable.** *Happened:* the first
`hasValidation` assertion reached for `PSObject.Properties.Name` on a
hashtable — which lists `Count` and `Keys` and never the keys themselves —
and went green against a producer that was still writing the field.
*Caught by:* the same pass that went looking for gates nobody had ever
run. *Rule:*
prefer semantic inspection over shape or text matching, and treat a green
that nothing has ever broken as unverified.
([journal 0025](../../journal/0025-findings-batch.md))

**F-1: the coverage gate in the plugin's own template.** *Happened:* the
`Test` task template shipped by `powershell-module-build` omits
`Run.PassThru`, so `Invoke-Pester -Configuration` returns nothing. The
coverage comparison then runs against an empty result and never fires, and
the `PreTag` guard evaluates `($null + $null) -eq 0` and always fires: one
missing line, two dead gates in opposite directions, no symptom. The build
printed `Line coverage: 0% (target %)` and exited 0 four lines after Pester
had printed `Covered 90.31% / 70%`. *Caught by:* each run deliberately
falsifying its own gate afterwards and watching it go red — and by nothing
else. The conformance suite scored that repository 57/57 *including* the
assertion "throws on coverage below target rather than only reporting it",
which is true, and which tests that the gate exists rather than that it can
fire. *Rule:* the mechanism is written up separately as F-11 so it is not
filed as a coverage-specific quirk. It recurred in all three plugin-on runs
and is the most serious finding the ladder produced.
([F-1 and F-11 in run 006's findings](../../runs/006-plugin-on/findings.md),
and the findings table in [README.md](../../README.md))

---

## Graders that graded the wrong thing

A grader that refuses is annoying. A grader that confidently grades the
wrong artifact is worse, because the number it produces looks exactly like a
number you can use.

**The vendored module that won a tie-break, four times.** *Happened:*
module discovery in the conformance suite picked the wrong module. First, a
vendored module won a shortest-path tie-break and the suite reported a
confident score about it. Second, SqlServerDsc ships 51 manifests, one of
which — a bundled helper — satisfied the base-name-matches-directory rule,
so the suite graded that and reported 81.82% with nothing in the output to
say so. Third, a lone surviving candidate in the control sweep. Fourth,
after a repair: deleting the reference's own manifest produced a confident
score against a vendored `PSCorpus` module instead of an error, because the
repair had fixed the first two selection rules and left the third.
*Caught by:* each time, removing the thing the assertion was about —
never by a
normal run, because every corpus target resolved on the earlier rules.
*Rule:* **ambiguous input fails loudly.** Resolution rules end in a stop,
never in a guess, and the operator gets an explicit way to answer the
question the grader could not
([method/METHOD.md](../../method/METHOD.md)). The recurrence is itself the
finding: each occurrence sat one selection rule further down than the last
repair had reached.
([journal 0004](../../journal/0004-five-suite-fixes.md),
[journal 0009](../../journal/0009-correct-the-control-protocol.md),
[FINDINGS.md](../../evals/conformance/baseline/FINDINGS.md),
[UNIVERSAL-CORPUS.md](../../evals/conformance/baseline/UNIVERSAL-CORPUS.md))

**One block, two tags, and Pester's OR.** *Happened:* a test block named
`House style: generated module` carried **both** the `HouseStyle` and
`RequiresBuild` tags. Pester's tag filter is an OR, so the block ran under
the suite README's own documented no-build invocation and read an absent
`psm1` as the empty string. *Caught by:* a later pass reading the committed
artifact — not by any run at the time. *Rule:* recorded as A4 in
[FINDINGS.md](../../evals/conformance/baseline/FINDINGS.md), and part of why
the tag taxonomy is now explicit about which tags need a build.
([journal 0002](../../journal/0002-first-conformance-suite.md))

**A result file written wherever you happened to be standing.**
*Happened:* `conformance-result.json` was committed at the repository root,
from a run with no tests in it, because the runner's default `-ResultPath`
was relative to the working directory. *Caught by:* noticing a tracked file
that should not exist. *Rule:* result files go to **explicit paths**, never
to a default relative to the working directory. It is in the "what a run
must record" list in [evals/HARNESS.md](../../evals/HARNESS.md).
([journal 0004](../../journal/0004-five-suite-fixes.md))

**The corpus control that failed for the grader's reasons, not its own.**
*Happened:* posh-git, the module deliberately chosen as the corpus control,
failed two `Universal` assertions. `function Global:Write-VcsStatus` keeps
its scope qualifier in `FunctionDefinitionAst.Name` and so never matched the
exported name; and reading an absent manifest key throws under StrictMode,
failing the editions assertion. *Caught by:* running the suite against eight
modules nobody in the project had written. *Rule:* the sentence in
[UNIVERSAL-CORPUS.md](../../evals/conformance/baseline/UNIVERSAL-CORPUS.md)
is the rule — if the control cannot pass, the tag is not measuring what it
claims. This is also what forced `Universal` and `Repository` apart into
separate tags.
([journal 0007](../../journal/0007-controls-tag-split-corpus.md))

**`@($null).Count` is 1.** *Happened:* an assertion wrote
`@(Get-BuildTaskCommand …).Count | Should -BeGreaterThan 0`.
`Get-BuildTaskCommand` returns `$null` for a file that will not parse, and
wrapping `$null` in `@()` produces a one-element array. Five "declares the
task …" assertions therefore passed against a build file that did not exist
— about nine points on 55. *Caught by:* being scored by it; the run that
found it was the one whose target had no usable build file. *Rule:*
recorded as a grader defect that flatters two published scores, with the
explicit note that both need recomputing if it is fixed. The same block's
comment already recorded an earlier hardening against exactly this class of
false pass, which is the part worth sitting with.
([journal 0020](../../journal/0020-baseline-off.md))

**A schema report that named the document root every time.** *Happened:* a
falsification set for the render contract rejected all eight graphs on its
first run — correctly — but every schema-layer violation reported the
document root, while the JSON Pointer naming the real location sat unparsed
in the message. *Caught by:* running the falsification set even though the
same author had written the thing it tests, and then reading the transcript
rather than the pass/fail column. *Rule:* the reds being right is not the
same as the report being usable. A grader's output is part of the grader.
([journal 0022](../../journal/0022-tohtml-contract.md))

**Three producer defects, none of which produced an error.** *Happened:* in
the Terraform producer, a local path `./modules/service` is literally
`namespace/name/provider`, so it matched the registry-address pattern and
every nested module resolved to a registry address that does not exist;
`required_providers` is a *block*, not an attribute, so a reader looking for
an attribute found no providers at all — indistinguishable from a repository
that pins none; and the parser rebuilds expressions by joining tokens, so
`var.tags` reached the reference extractor as `var . tags` and every pattern
written against source text missed, costing 37 edges, the entire
traceability chain. *Caught by:* the hand-authored oracle, and nothing else.
None of the three produced an error, a warning, or an empty result that
looked wrong. *Rule:* build the oracle before the producer. This is the
whole argument for it, in one pass.
([journal 0024](../../journal/0024-tf-first-build.md))

---

## Scores that were not comparable

These are not defects in code. They are defects in arithmetic, and they are
the easiest kind of mistake to publish.

**74/75, which should be read as 73/74 plus one unknown.** *Happened:* a
published baseline figure included the inert coverage assertion. Its pass
was not earned and carried no information about the target either way.
*Caught by:* the falsification pass that found the assertion inert. *Rule:*
the figure after the repair is numerically identical and is now the whole of
it — every assertion in it has a falsification row. The correction is stated
in [FINDINGS.md](../../evals/conformance/baseline/FINDINGS.md) rather than
quietly absorbed.
([journal 0006](../../journal/0006-fix-the-inert-assertion.md))

**Repairing the suite moved the denominator, not just the score.**
*Happened:* a repair let assertions reach source they previously could not
open. SqlServerDsc went from 8/11 to 170/171 and ImportExcel from 17/67 to
17/79. Read as percentages that is a 27-point improvement and a 4-point
regression, and neither statement means anything: SqlServerDsc's 161
exported functions live in a `.psm1` the suite could not previously read,
and ImportExcel's help assertion reached 60 more functions that were always
undocumented. *Caught by:* comparing the two runs case by case instead of
percentage to percentage. *Rule:*
[decision 0003](../../decisions/0003-score-comparability.md) — a score
comparison is valid only when cases-run is stable between the two runs, and
any report comparing two scores states cases-run for both. Note the
direction of the risk: an assertion that silently stops producing cases
makes a score go **up**.
([journal 0008](../../journal/0008-repair-universal-tag.md))

**cases-run against cases-defined.** *Happened:* `cases-run` depends on the
shape of the target — an `It` with `-ForEach` over public functions makes
seven cases against a module with seven commands and two against a module
with two — so two builds of the same module reported 57 and 55 and were
never two points on one scale. *Caught by:* trying to put two runs in one
table. *Rule:* `cases-defined` is parsed out of the suite's own source by
AST, so the target is never consulted and the denominator cannot move with
it. Three differently shaped targets read 33, 33 and 33 where cases-run read
57, 55 and 41. The control the other way matters too, because a number that
never moves is stable and useless: it tracks tag *selection* at 9, 23 and
33. It earned itself immediately — run 005 shipped no culture directory, so
one case was skipped, and the three ladder runs read 57 / 56 / 57 at
cases-run and 33 / 33 / 33 at cases-defined.
([journal 0025](../../journal/0025-findings-batch.md),
[journal 0027](../../journal/0027-run-005.md))

**Editing an earlier pass's pinned number.** *Happened:* adding six
assertions moved the suite's case count to 352 and turned an earlier pass's
verify script red, because that script pinned 346. The instinct — and the
action taken at the time — was to edit the old number. *Caught by:* the next
pass, which named it as the wrong instinct: it makes the number mean less
each time and makes the work grow without bound. *Rule:*
[decision 0004](../../decisions/0004-plan-artifacts-are-frozen.md) freezes
plan artifacts instead. A verify script is a record of what was true at its
landing commit, not a live check.
([journal 0013](../../journal/0013-create-fixture.md),
[journal 0014](../../journal/0014-seed-and-comparator.md))

**A baseline that was never allowed to iterate.** *Happened:* the
plugin-off run was executed under a protocol that said "No fixes, no re-runs
— the first scores stand", while the three plugin-on runs were each allowed
up to three iterations. The with/without table therefore has no plugin-off
final column and cannot have one. *Caught by:* finishing the ladder and
writing the comparison down, which made the asymmetry obvious rather than
hiding it. *Rule:* the table in [README.md](../../README.md) says so in
place, and the missing control — a second plugin-off run under the same
rules — is [LEDGER](../../LEDGER.md) backlog item 17, described there as the
highest-value single run remaining. Nobody knows what run 003 would have
scored with three iterations, and the repository says so rather than
implying an answer.
([journal 0029](../../journal/0029-final-readme.md),
[the run 003 plan](../../plans/0020-baseline-off/plan.md))

**28 / 33 and 33 / 33 were not the same measurement, and the rule that was
supposed to make them one is what allowed it.** *Happened:* four conformance
assertions read the module's build output directory, which is gitignored.
The scoring protocol said "score from a fresh clone" and never said to build
it, so run 007's conformance clone was never built and those four graded the
absence of a directory: 28 / 33 reported, **32 / 33** for the same commit
built first. The three runs before it were unaffected — but not because the
rule protected them. Each got build output into its conformance tree by a
different improvised route: 004 ran the build inside the conformance clone,
005 scored a snapshot of an already-built tree, 006 built all three clones.
*Caught by:* the fourth run reading the failure messages instead of the
score. One of them says, in the assertion's own words, *"because run the
build before the RequiresBuild tag"* — the suite had been saying so all
along, once per failure, to nobody. *Rule:* **a scoring procedure is not
fully specified until it says what state the artifact is in when the
assertions run.** An unspecified step does not stay unspecified; each run
invents it, the inventions differ, and the scores stop being comparable
without any of them looking wrong. The step is now an executable
([`Score-Clone.ps1`](../../evals/conformance/Score-Clone.ps1)) rather than a
sentence, both affected runs were re-scored under it, and the repair was
falsified three ways before the new numbers were believed — including the
control that the *unbuilt* clone must still fail, or the repair is an
assertion-weakening in disguise.
([rescore.txt](../../plans/0033-honest-headline/rescore.txt),
[run 007 findings C-5](../../runs/007-baseline-iterated/findings.md))

---

## Probes that never applied, and expectations that went stale

This is the most dangerous group in the catalog, because every failure in it
**fails toward the alarming answer**. A probe that silently does not apply
reports the check it was supposed to break as *does not fire* — the exact
finding the whole protocol exists to detect, manufactured by the protocol's
own bookkeeping. Nobody eyeballing results for anomalies dismisses it,
because it looks like the thing you were hunting for.

**A renamed assertion turned a correct red into a missed one.**
*Happened:* a repair rekeyed the comment-based-help assertion from filename
to function name. The falsification driver still named the old test,
`Get-PSModuleEnum.ps1`, so the row reported `strip-synopsis` as DOES NOT
FIRE with the genuine red listed as collateral. The assertion was fine; the
harness's idea of it was not. *Caught by:* investigating a healthy assertion
— which is what it cost. *Rule:* hazard 6 — preflight every expected
assertion name against the assertions the current grader actually produces,
and **hard stop** on any that does not resolve. Not a warning: a warning is
indistinguishable from noise in a run that prints a hundred lines.
([journal 0008](../../journal/0008-repair-universal-tag.md),
[hazard 6](../../evals/HARNESS.md))

**The guard against a false negative was very nearly a false positive.**
*Happened:* the preflight built to implement hazard 6 was first written with
Pester's `Run.SkipRun`, which does not expand `-ForEach` names — they come
back as the literal template — so it would have hard-stopped on every
parameterised row in the driver. *Caught by:* its own first use. *Rule:* the
name list must come from a **real run**, not from discovery. The same
reasoning is now applied to row *selection*: a typo in a `-Only` filter once
selected zero rows and reported a clean run, and a run of zero rows is not a
pass.
([journal 0009](../../journal/0009-correct-the-control-protocol.md))

**A partial decoy is worse than none.** *Happened:* the probe for
`includes functions from Private subfolders` removed every nested private
function but left a decoy comment naming only *one* of them. It went red —
on the names it had not decoyed — and would have been filed as "no defect
found". *Caught by:* decoying every name, which showed the assertion was in
fact satisfied by comments. *Rule:* a control must perturb the whole of what
the assertion reads, or its red proves nothing about the question being
asked. It is the second half of hazard 4.
([journal 0009](../../journal/0009-correct-the-control-protocol.md))

**Two probes corrupted the target before they tested it.** *Happened:* one
probe left an unbalanced brace in the build file; another mangled a string
through a nested escaping layer. In both cases the "target" being graded was
not the target plus one break, it was rubble. *Caught by:* the rebuild
failing, rather than by inspection. *Rule:* rebuild inside the row rather
than trusting the edit — which is also why a rebuild row needs two rebuilds,
one after the break and one after the restore (hazard 3).
([journal 0009](../../journal/0009-correct-the-control-protocol.md))

**The probe that never applied, and the check that agreed with it.**
*Happened:* a control probe meant to inject a stylesheet reference into
rendered HTML was written like this:

```powershell
Set-Content $html -Value ($text -replace '<style>', '<link ...>' + "`n" + '<style>')
```

which is a parse error — `-replace` takes two operands, and the
concatenation after the comma supplies a third. The injection never
happened. `verify.ps1` then ran against an
unmodified file and printed "all checks agree", and reading that line alone
would have recorded the check as falsified when it had never been exercised.
*Caught by:* the empty failure list. Not the exit code, which was correct
for the file as it actually stood. *Rule:* a probe asserts that it changed
the file — content hash, byte length, or an explicit re-read — *before* the
check under test runs, and aborts the row if nothing changed. The guard
belongs at the probe, not at the check; a check cannot know whether the
thing it is reading was supposed to be different.
([journal 0011](../../journal/0011-fixture-design.md), written up as the
third instance under [hazard 6](../../evals/HARNESS.md))

**A prose pointer that nothing resolves.** *Happened:* an absence case in
the fixture names its checking assertion in prose, and nothing verifies that
the named assertion exists. Rename the test and the pointer becomes silently
false. *Caught by:* recognising the shape — it is the renamed assertion and
the unapplied probe again, in a document. *Rule:* the fix is the one hazard
6 already states for the falsification driver: resolve every named assertion
against the suite's real test names and hard stop on any that does not
resolve. The journal records honestly that it was **not** built that pass,
because half of one case's pointer named a read-back assertion that did not
exist until the following pass.
([journal 0012](../../journal/0012-case-split-and-corrections.md))

**A pass's own artifacts broke an earlier pass's verify script.**
*Happened:* adding six assertions moved the suite to 352 cases and broke a
verify script that pinned 346. *Caught by:* running it. *Rule:* the journal
calls it "hazard 6 pointing at itself", and the resolution was
[decision 0004](../../decisions/0004-plan-artifacts-are-frozen.md) rather
than an edit — see the scores group above.
([journal 0013](../../journal/0013-create-fixture.md))

**A tamper probe that tampered with nothing.** *Happened:* the first tamper
probe for a render-integrity check passed a git-bash-style path into `pwsh`,
which resolved it as `C:\c\Users\…`. The write failed, the file was never
modified, and `-Verify` returned 0 — the correct answer for an unmodified
file and a worthless falsification. *Caught by:* a before/after hash
comparison. *Rule:* `verify.ps1` now asserts the break landed before
trusting the check. The journal's own summary is the lesson: this is the
exact failure the practice exists to prevent, committed while applying the
practice.
([journal 0021](../../journal/0021-psgraphrender-handoff.md))

**A falsification that proved nothing because its own invocation was
broken.** *Happened:* `pwsh -File` flattens a comma-separated array into one
token, so `-Task Build,Test` arrived as a single task name and aborted
InvokeBuild. The same shape then made both of that pass's gate
falsifications look red while proving nothing, and made a `-Tag` list fail a
`ValidateSet` inside `verify.ps1`. Three times in one pass. *Caught by:*
reading the log instead of the exit code. *Rule:* use `-Command` with a real
`@(...)`, or call the script in-process. It is [LEDGER](../../LEDGER.md)
backlog item 15, and the run README repeats the warning at the point of use.
The first occurrence is the dangerous one: a falsification that is not
itself checked is the hazard it exists to prevent, one level up.
([journal 0027](../../journal/0027-run-005.md), and the earlier
array-binding instance in [journal 0026](../../journal/0026-run-004.md))

**The recurrence is the finding.** This one shape — the bookkeeping around a
probe fails, and the probe's result is reported as though the probe ran —
accounts for the majority of this group.
[journal 0011](../../journal/0011-fixture-design.md) counts it as having
cost time in pass 0009, in a preflight, and in that pass;
[journal 0012](../../journal/0012-case-split-and-corrections.md) records it
as "the fourth time" and names the renamed comment-based-help assertion and
the unapplied probe as two of the earlier ones; the broken verify pin in
pass 0013 is a fifth. If you take one operational habit from this chapter,
take this one: **make every probe prove it changed something before you
believe what the check said afterwards.**

---

## Prose assertions that lied

Documents get checked too — that a plan says what it must, that a record
does not leak an answer, that a README names only paths that exist. Checking
prose has two failure modes that are both silent and both point the wrong
way.

**Three checks that failed against correct documents.** *Happened:* a
verify script failed three of its own checks against documents that were
right. A grep for "token count" could not tell a requirement from a sentence
saying there is none. PowerShell's `-match` is case-insensitive, so a check
for the *absence* of "Skip the corpus" matched the corrected text's "Do not
skip the corpus" — the sentence with the opposite meaning. And a check for a
phrase that markdown had hard-wrapped failed on the line break rather than
on the content. *Caught by:* the checks going red against text the author
knew was correct. *Rule:* hazard 8. Asserting on prose needs whitespace
normalisation *and* case sensitivity, and neither is obvious until a correct
document is reported wrong.
([journal 0012](../../journal/0012-case-split-and-corrections.md))

**Hard wrapping defeated the tool that was checking for hard wrapping.**
*Happened:* twice in one pass. `FixtureCase.ps1` captured only the first
line of a `**checked by:**` block, so it saw half of a quoted test name.
Minutes later, a `grep -c` written to confirm that a falsification probe had
been applied returned 0 for a phrase that was demonstrably in the file,
because the phrase spanned a line break. *Caught by:* disbelieving the zero.
*Rule:* the diagnostic rule now stated in hazard 8 — *a phrase check
returning zero matches for text known to be present is a defect in the
check, not evidence about the file.* Reach for that reading first. The
instinct runs the other way, because a zero result looks like an answer.
([journal 0013](../../journal/0013-create-fixture.md),
[hazard 8](../../evals/HARNESS.md))

**Hazard 8 caught the pass that was writing hazards 9 to 11.** *Happened:*
while folding three new hazards into the harness document, two acceptance
assertions reported a phrase absent that was demonstrably present, because
the sentence wrapped across a line break. *Caught by:* the same disbelief,
faster this time. *Rule:* the documented protection — collapse whitespace
before matching — was the fix, and the entry is recorded because writing the
hazard down had **not** been enough to avoid it. That is the second time
this project has recorded the hazard recurring inside work on the hazard
itself, which is why hazard 8 is phrased as an instruction rather than an
observation.
([journal 0029](../../journal/0029-final-readme.md))

**The kind-marker regex that did not survive CRLF.** *Happened:*
`core.autocrlf` was true with no `.gitattributes`, so a fixture document
arrives CRLF in any fresh clone on Windows. In .NET multiline mode `$`
matches before the `\n` but after the `\r`, so a pattern ending `[ \t]*$`
fails on every marker. The whole of one assertion would have failed for the
next person to clone the repository, and passed on the author's machine.
*Caught by:* a probe that *over-fired*. A break meant to fail one assertion
failed sixteen, and the extra fifteen were the defect rather than the probe.
*Rule:* line endings are pinned by `.gitattributes`, and an over-firing
probe is a fact to record and judge, not an automatic fault. A probe that
fires more widely than intended is usually a bad probe; this time it was the
only thing looking at the file through a different set of line endings.
([journal 0012](../../journal/0012-case-split-and-corrections.md))

**Documentation of a gate that rotted independently of the gate.**
*Happened:* a testing document described a `PreTag` gate as "one test",
naming the only `PreTag` test that the pass in progress was deleting and
omitting the three that survive. The gate itself was green throughout and
never wrong; only the prose was. *Caught by:* a subagent and the author's
own survey, independently — which is the only reason it did not ship.
*Rule:* documentation is an artifact with its own failure modes, and a
document naming paths or tests is worth a check that resolves them.
([journal 0021](../../journal/0021-psgraphrender-handoff.md))

**An assertion about a document cannot tell whose id it is reading.**
*Happened:* a run record's acceptance test asserts that the whole document
does not contain the two previous runs' session identifiers, to establish
that this run was a third distinct session. The first draft of the record
proved its own claim by quoting both predecessors' identifiers in one
sentence, and the assertion went red. *Caught by:* the assertion, correctly.
*Rule:* the assertion was **not** weakened — it was specified verbatim in
the prompt and left exactly as given. The record was changed instead to name
the two files the other identifiers live in, and the pairwise-distinctness
claim is carried by a spot-check that reads all three ids out of all three
records. This is the same shape as *an assertion about a declaration is not
an assertion about the thing declared*, arrived at from the other side.
([F-17 in run 006's findings](../../runs/006-plugin-on/findings.md))

---

## PowerShell and platform traps that failed silently

Every entry here shares one property: **no error, no warning, no empty
result that looked wrong.** They are collected in one place because a
newcomer to PowerShell will otherwise meet them one at a time, at the worst
possible moment, and several of them present as "the algorithm found
nothing".

**A top-level `function` breaks every `BeforeAll` in the file.**
*Happened:* under Pester 6.1.0, a top-level `function` statement in a test
file made all 18 tests in that file fail with empty error messages — the
signature of a throwing `BeforeAll`, not of failing assertions. *Caught by:*
reduction, to a file whose only top-level statement is
`function Probe-It { 'hello' }` and a `Describe` whose `BeforeAll` merely
runs `Get-Command Probe-It -ErrorAction SilentlyContinue`. It fails. The
error is *"A 'break' or 'continue' statement with a label that does not
match any enclosing loop escaped from your code"* — which names loop labels,
mentions neither functions nor `BeforeAll`, and points at nothing that is
wrong. Three loop-shaped variants were bisected before the shape became
visible; none was the cause. *Rule:* dot-source the function from another
file, which works in both phases. Chase the shape, not the message.
([journal 0012](../../journal/0012-case-split-and-corrections.md))

**The same misleading message, from a mandatory collection parameter.**
*Happened:* a `[Parameter(Mandatory)]` collection parameter rejects an empty
collection, which is correct and documented — and inside Pester the binding
failure surfaced as the same `break`/`continue` message. *Caught by:*
recognising it from the previous entry. *Rule:* `[AllowEmptyCollection()]`.
The journal's note is the general one: a PowerShell error message can point
almost anywhere but at the cause, and chasing the message rather than the
binding failure costs far more than the fix.
([journal 0016](../../journal/0016-first-build.md))

**The same misleading message again, from `.GetNewClosure()`.**
*Happened:* a `-ModuleName` mock ran in module session state, where the test
file's `$script:` variables do not exist. It surfaced as the
`break`/`continue` message against a whole container, with 21 blank failure
messages. *Caught by:* the `powershell-module-test` skill naming that exact
symptom and saying to call the code under test directly, which produced
`CommandNotFoundException: Get-AzDoCachedYaml` immediately. *Rule:* a skill
that names a symptom converts an opaque failure into a two-minute fix. The
underlying cause — `.GetNewClosure()` rebinding a scriptblock to a fresh
dynamic module where module-private functions vanish — is in no skill, and
the journal says it should be. This is F-7 in the run findings, and one of
only two of the ten recurring findings that did *not* recur in run 006.
([journal 0026](../../journal/0026-run-004.md))

**Variable names are case-insensitive, three times.** *Happened:* a
parameter and a loop variable that differ only in case are one variable.
`Get-ProducerGraphDepth` took `$Node` and looped `foreach ($node in $Node)`:
fifteen nodes produced a depth table with one entry, with no error and no
warning, surfacing three layers later as a null `metrics.depth`. The same
shape hit `foreach ($tag in $Tag)` in a conformance runner, where the run
reported 17 cases instead of 57 and read exactly like a Pester filter bug.
And again, in a plain script, where a `$root` local silently overwrote the
`$Root` parameter of a `verify.ps1`. *Caught by:* in the first case,
running rather than reading; in the second, a falsification that had a
**predicted number** — 57 and 55, from the committed records of two earlier
runs — and 17 was not it; in the third, the same hazard that
`powershell-module-architect` documents for parameters, met in a plain
script. *Rule:* the second catch is the transferable one: **a control with
an expected value catches what a control with a green light does not.**
([journal 0022](../../journal/0022-tohtml-contract.md),
[journal 0025](../../journal/0025-findings-batch.md),
[journal 0028](../../journal/0028-run-006.md))

**`@($x)` throws for a `List[object]` on pwsh 7.6.5.** *Happened:* the
array-subexpression operator throws `ArgumentException` for any
`List[object]` on that build, while `.Count`, `foreach` and the pipeline all
work. It silently dropped every `resources:` block in nine fixture files,
and the exception was attributed to the `foreach` line rather than to the
`@()`. *Caught by:* the graph coming out wrong, twice, and real time spent
both times. *Rule:* it belongs in the method rather than in one run's
record, because any run on that machine can hit it.
([journal 0020](../../journal/0020-baseline-off.md))

**A single-element `List[T]` unrolls, and indexing the scalar yields a
`[char]`.** *Happened:* `$children = if ($adjacency.ContainsKey($n)) {
$adjacency[$n] } else { @() }` returns a bare `string` when the list holds
exactly one item. Indexing a `string` returns a `[char]`, and
`$state[[char]'b']` and `$state['b']` are different keys. Cycle detection
found nothing at all — not the real cycle, not even a self-loop — and
terminated normally. `$children.Count` read `1` throughout, which is what
makes it hard to see: the count is right and the element type is wrong. The
same family bit the pass's `verify.ps1` twice more, where
`(… | Sort-Object -Unique).Count` throws under StrictMode for a single item.
*Caught by:* the oracle comparison, which knew there was a cycle. *Rule:*
declare `[string[]]` and cast. Any graph or tree walk that pulls adjacency
out of a dictionary through an `if` expression has this bug latent, and it
presents as "the algorithm finds nothing", never as an error.
([F-13 in run 006's findings](../../runs/006-plugin-on/findings.md))

**`Write-Build` swallowed by an assignment.** *Happened:* a build task
printed its header and then nothing. The function ended with
`Write-Build Green "…"` and then returned a value, and the caller wrote
`$null = Resolve-BuildDependency …`. In a non-interactive host `Write-Build`
falls back to the output stream, so `$null =` swallowed the message along
with the return value. The build stayed green and the resolved version
silently stopped being printed — precisely the fact the build skill says to
print so it "sits next to the failure". *Caught by:* reading the build
transcript. *Rule:* return a record and let the caller print it. The skill's
own example has the broken shape.
([F-14 in run 006's findings](../../runs/006-plugin-on/findings.md))

**A credential guard masked by the transport error handler.** *Happened:*
with the token variable unset, commands failed with a message naming an
empty HTTP status rather than the message naming the variable, because the
auth-header call sat *inside* the `try` and its `throw` was caught by the
transport handler and rewritten. *Caught by:* running the module with the
variable unset, deliberately. *Rule:* the one error that names the fix must
not be replaceable by one that names nothing.
([F-15 in run 006's findings](../../runs/006-plugin-on/findings.md))

**A check that reported a disagreement it could not name.** *Happened:* a
roster evaluator ended `, $problems`. The unary comma wraps the array, so an
empty result arrived as one element that was an empty array: the check
reported `1 disagreement(s)` and then printed a blank line where the name
should have been. *Caught by:* strengthening the failure probes to re-run
the check rather than restate the sabotage — the first run of those probes
reported a failing **baseline**, and a baseline that fails before any break
is a broken probe, not a broken repository. *Rule:* the journal's own note
is the reason this entry matters. This bug failed toward the alarming
answer. The same bug with reversed polarity would have been a check that
could not go red — the defect this repository exists to find, and the one
that would not have announced itself.
([journal 0017](../../journal/0017-skill-roster.md))

**Line endings, four times.** *Happened:* the CRLF regex failure above; a
428-character difference between a committed file and a fresh render, which
turned out to be exactly 428 carriage returns, because `.gitattributes`
stores LF and a Windows render writes CRLF; the same trap anticipated and
fenced off in the Terraform fixture, where every repository carries
`* text=auto eol=lf` and read-backs normalise on both sides; and an exported
artifact that does not byte-compare across a git round-trip, where raw
comparison says "different" and parsed comparison says identical.
*Caught by:* measuring the difference rather than assuming it. *Rule:*
normalise
line endings on both sides of a read-back, and write down why — otherwise
the next reader spends the same hour.
([journal 0012](../../journal/0012-case-split-and-corrections.md),
[journal 0022](../../journal/0022-tohtml-contract.md),
[journal 0023](../../journal/0023-tf-fixture.md),
[F-16 in run 006's findings](../../runs/006-plugin-on/findings.md))

**Two parallel jobs that silently shared an output file.** *Happened:* a
sweep ran patterns `CLAUDE` and `\.claude` whose output basenames collided
on a case-insensitive filesystem. One overwrote the other, and the surviving
counts looked entirely plausible. *Caught by:* re-running it, which found 7
hits the first pass had lost. *Rule:* parallelism that writes to derived
filenames needs the filenames proved distinct.
([journal 0021](../../journal/0021-psgraphrender-handoff.md))

**Three scoring jobs sharing one tree produced a false 51/56.**
*Happened:* the build job's `Clean` task deleted the output directory while
the conformance job's build-dependent assertions were reading it. The
resulting failures were indistinguishable from real defects in the artifact.
*Caught by:* the score being wrong in the direction that looks like a
finding, which is the direction that costs the most to chase. *Rule:*
parallel scoring jobs are isolated per clone **and** per process — the same
defect recurs one level up when two builds share a process, because the
module imported by the first build is still loaded when the second build's
assertions run. Pay the wall-clock, about a minute, against a score nobody
can trust.
([method/METHOD.md](../../method/METHOD.md), under the falsification
harness)

**A machine decision taken on a human-facing string.** *Happened:*
rewording a `reason` field from `alias-not-declared` to a full sentence
broke an unrelated equality test in the graph builder. The `else` branch ran
with two nulls and an unresolved edge acquired the target id `yaml:/` — one
difference where there had been twenty-six. *Caught by:* re-scoring after
the iteration, which is the only reason it did not ship. *Rule:* split the
machine-readable code from the human-readable message. `reason` was doing
two jobs and nothing marked the coupling. This is the single reason run 006
needed two iterations where runs 004 and 005 needed one, and the general
shape — *a decision taken on text written for a human breaks the moment the
text improves* — is why the oracle's own `token: explanation` format is
worth imitating.
([F-12 in run 006's findings](../../runs/006-plugin-on/findings.md))

**Two output captures that came back empty.** *Happened:* the first
`diff.txt` and the first-shot compare transcript of a measured run were both
written empty, because the comparator writes to the host rather than to the
pipeline and `Out-String` captured nothing. In the same pass, `git clone`
into the session scratchpad failed as "Filename too long" and needed
`core.longpaths`. *Caught by:* looking at the files. *Rule:* an artifact a
run promises to produce is checked for content, not just for existence.
([journal 0028](../../journal/0028-run-006.md))

---

## Fixtures and oracles that could not be satisfied

An oracle is the declared right answer. When the oracle is wrong, every
score computed against it is wrong in a way no amount of care in the
producer can fix — and the temptation to quietly edit the oracle is the
strongest temptation in the whole method.

**The case the fixture was built for is the one that does not work.**
*Happened:* the Terraform fixture's case 3 ties a variable to another
repository's output through the variable's *description* — prose. No parser
can read that. It was also the only case a single-repository parser could
not see, which is to say the case the three-repository fixture existed to
exercise. *Caught by:* building a producer against it. A fixture case can be
unpassable, and only a producer finds out. *Rule:* written as a finding
against a frozen fixture rather than fixed in place, and repaired later,
deliberately, under
[decision 0012](../../decisions/0012-fixture-case3-repair.md) — after which
the re-score reached 0 differences and 7/7.
([journal 0024](../../journal/0024-tf-first-build.md),
[tf-002](../../runs/tf-002-convention-and-case3/))

**A count that was wrong because it was stated.** *Happened:* the fixture's
case document claimed five pipeline definitions; there are four. *Caught by:*
somebody counting them, which is possible only because a number was written
down. *Rule:* the journal's phrasing is the rule — stating a count is what
makes it checkable. Nothing would have noticed if the number had been left
vague.
([journal 0023](../../journal/0023-tf-fixture.md))

**F-2: a rule that produces three nodes for a fixture that has four.**
*Happened:* the graph-assembly skill states the repository-node rule too
narrowly, and every run that follows it exactly is missing one node. Run 006
went further and found that the fixture's own case document justifies four
repository nodes with a rule that produces three. *Caught by:* three
independent blind runs producing the same missing node, and then one of them
reading the case document closely. *Rule:* **never edit the oracle to fit.**
Nothing under `evals/` was touched; it is recorded as a finding for a
decision to repair. It is the one error the plugin introduced, and it is
stated as such in the with/without table rather than netted off against the
four it fixed.
([README.md](../../README.md),
[F-2 in run 006's findings](../../runs/006-plugin-on/findings.md))

**Cases whose real failure mode no mutation can express.** *Happened:* the
comparator is falsified by mutating the expected graph, one mutation per
case. Two cases have a naive failure that no graph mutation reaches: one
case's first failure mode is a hang or a stack overflow, which produces no
graph at all, and only its second mode is comparator-visible; two others
each have an invented-edge failure their single mutation does not cover.
*Caught by:* writing the mutations and asking what each one actually proves.
*Rule:* recorded as findings about the cases' discriminating power, in the
plan's Deviations, rather than left as an implied "every case is falsified".
([journal 0014](../../journal/0014-seed-and-comparator.md))

**A naming scheme that structurally cannot name an absence case.**
*Happened:* every presence case is named by a tag on a node in the expected
graph. Nothing in the expected graph can carry the absence case's tag,
because tagging a node with it would assert the opposite of the case. The
tag lookup therefore has nothing to find, and no amount of care with tags
fixes it. *Caught by:* something finally having to *name* the case rather
than merely check it. *Rule:* the comparator carries an explicit absence-case
rules table for that one reason.
([journal 0014](../../journal/0014-seed-and-comparator.md))

**The oracle failed its own case, and the case document was the thing that was
wrong.** *Happened:* fixture 2's case 6 — the absence case — was described as
*"the only node in the fixture with neither"* an incoming nor an outgoing edge.
Read literally that is false of the oracle: **ten** nodes have neither, because
three repository nodes and six provider nodes take part in containment rather
than in value flow. The claim was true only of nodes that carry a value, and the
scope had never been written down. *Caught by:* **scoring the oracle against
itself.** The first time that control was run it returned 6 / 7 — the answer key
failing its own paper. No producer and no review found it, and nothing else
would have: every producer scored against the case was scored by a rule the
document did not state. *Rule:* the prose loses. The oracle and the fixture are
frozen, so what changed was the sentence, and the nine nodes read out of the
oracle are the evidence it was wrong. Two conditions on that kind of repair,
both now enforced: the rewritten discriminator must be **stricter or equally
strict** — a correction that makes a case easier to pass is indistinguishable
from abandoning it, so the strictness gets a falsification row of its own — and
the superseded wording is struck through rather than deleted, because a
corrected sentence whose old form is gone stops explaining what was wrong with
it. Note the direction of the error: uncorrected, the run would have reported
`5 / 7 → 6 / 7` instead of `6 / 7 → 7 / 7`. **Too modest is the direction nobody
audits.**
([LEDGER backlog 40](../../LEDGER.md),
[the control](../../plans/0036-tf-003/cases-oracle-control.txt),
[the correction and its falsification](../../plans/0037-consolidation/case-scorer.txt))

**A platform that refused nothing.** *Happened:* the fixture includes two
pipeline definitions built to be broken. Azure DevOps accepted both.
Template expansion happens at queue time, and nothing in this project is
ever queued, so their faults are never evaluated. *Caught by:* pushing them
and watching nothing happen. *Rule:* recorded, because "the platform
accepted it" is not evidence that a definition is valid, and a fixture that
relies on the platform to reject something is relying on a check that does
not run.
([journal 0013](../../journal/0013-create-fixture.md))

---

## Contamination and blindness

A measured run is only a measurement if the session doing it does not
already know the answer. Everything in this group is a way that knowledge
leaked, or nearly leaked, into a session that was supposed to be blind.

**A pass that contaminated the session for the next run.** *Happened:*
capturing three verify scripts' complete output — required by that pass's
own task list — printed fixture repository names, aliases, unresolved
targets and the cycle into the session. Harmless there; disqualifying for
the discovery run that was meant to follow. *Caught by:* the plan saying so.
Nothing in the repository would have recorded it otherwise. *Rule:* the
discovery run needs a fresh session, and this is the observation hazard 9
was later written from.
([journal 0015](../../journal/0015-repository-corrections.md))

**A `git` command that printed the fixture's shape.** *Happened:* a blind
run used `git ls-tree -r --name-only` to locate the oracle blob, which
printed every filename under the fixture, disclosing that cycles and
diamonds are tested and that one template exists at two depths — the two
areas where that run's correctness results are strongest. *Caught by:* the
run's own breach reporting, which the journal states plainly: the breach was
mine and it was avoidable. *Rule:* `git rev-parse <ref>:<path>` asserts the
blob and leaks nothing. Preconditions that must confirm a run record exists
check it by **line count**, never by reading it.
([journal 0020](../../journal/0020-baseline-off.md))

**The gate that stopped a pass for reading run records legitimately.**
*Happened:* a pass had read two run READMEs in order to rebuild those clones
for a denominator falsification. The reading had nothing to do with the
fixture's answers, and it burned the session anyway: the next pass stopped
at its own session gate. *Caught by:* the gate. *Rule:* hazard 9 — a
measured run's prompt is the first message of a brand-new session, and
anything preceding it in that context disqualifies the session. The three
ladder passes each opened a fresh session for exactly this reason, and their
three distinct session identifiers are what make the claim checkable rather
than asserted.
([hazard 9 in evals/HARNESS.md](../../evals/HARNESS.md))

**Commit subjects that leak scores into every future session.**
*Happened:* `git log` runs at the preconditions of every measured run, so a
commit subject is read by sessions that must not read run records. One
subject carried a previous run's totals. *Caught by:* a later run noticing
that its own preconditions had shown it a number. *Rule:* hazard 11 — run
and pass commits carry no scores in their subjects; scores live in run
README bodies and plan bodies, which the allowlist does forbid. The same
applies to branch names and tag names. The journal records it as something
no session can fix from inside, which is why it went to the
[LEDGER](../../LEDGER.md) as a backlog item and then into the harness.
([journal 0027](../../journal/0027-run-005.md))

**The contamination vector with no failure mode at all.** *Happened:*
nothing — and that is the entry. A context window is cleared by starting a
new session; an auto-loading memory file is not. A single score written to
memory disqualifies **every** future session, and there is no red, no
warning, and no artifact that looks wrong. The runs simply stop measuring
what they claim to measure. *Caught by:* reasoning about it before it
happened, which is the only way it can be caught: there is no way to check
afterwards whether a past run was contaminated by a memory file that has
since been deleted. *Rule:* hazard 10. Nothing may write scores, fixture
findings or oracle content to session memory or any auto-loading location,
and the locations are verified empty at every blind run's preconditions.
([hazard 10 in evals/HARNESS.md](../../evals/HARNESS.md))

**The word `main` denoted two different histories.** *Happened:* checking a
decision record's claims against the local `main` produced two apparent
factual errors in an operator-supplied file — a commit count and a tip that
did not match. Both dissolved against `origin/main`. *Caught by:* checking
the other ref before reporting the errors. *Rule:* this is the exact hazard
[decision 0005](../../decisions/0005-branch-and-merge-policy.md) was written
to fence off, and it demonstrated itself during the act of recording the
decision. Name the ref.
([journal 0015](../../journal/0015-repository-corrections.md))

**The blind run could not start from its own allowlist.** *Happened:* a
discovery run was designed to locate its fixture from scratch. Nothing on
its allowlist names the organisation or the project, the environment carries
only the token, and the token lacks the scope that would let the accounts
API enumerate its own organisations — it returns 401. A blind first phase
therefore had no way to locate the fixture it existed to read. *Caught by:*
attempting it. *Rule:* recorded as a finding against a prompt that produced
no plan of its own, rather than solved by widening the allowlist, because
widening the allowlist is how a blind run stops being blind.
([journal 0015](../../journal/0015-repository-corrections.md))

**The fixture told every blind run what its own cases were, for five runs,
and no record said so.** *Happened:* the live AzDO fixture is annotated —
its YAML carries leading comments naming each case and stating what it is
for, including which of two plausible answers is the wrong one. Reading the
fixture through the module is the task, so the allowlist cannot exclude it:
every run from 002 onward has read them by design. *Caught by:* the control
run, run 007, writing down the channels its corrections came through instead
of only its score — four runs had the same exposure and none had mentioned
it. *Rule:* the fixture is frozen, so this is **disclosed, not repaired**:
stripping the comments now would invalidate the comparability of five runs,
which costs more than the bound. Two things change instead. The vocabulary
is fixed — "blind" means the oracle, the run records and the plugin were
unread, and has never meant the fixture was unread. And every fixture
written from now on keeps its commentary in the *oracle* document, on the
far side of the gate. A bound that has always applied and was written down
only when it became inconvenient reads, later, exactly like a bound that was
invented then.
([hazard 13](../../evals/HARNESS.md),
[run 007 findings C-3](../../runs/007-baseline-iterated/findings.md),
[the Terraform fixture scan](../../plans/0033-honest-headline/tf-fixture-comments.txt))

---

## The director's own mistakes

The operator who writes the prompts — this manual calls that role the
**director** — is not outside the system being measured. Their instructions
are an artifact like any other, and they have been wrong at least as often
as the code.

This group exists because a record that only catalogues the agent's errors
is a dishonest record. It is also the most practically useful group in the
chapter, because it tells you what to expect from your own prompts. Every
entry here was found and reported by the pass that received the instruction,
under [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) section 10, **Deviations**
— a required section that asks for anything in the prompt that was wrong,
unclear or impossible, and anything followed that seems mistaken. The
protocol calls it the most valuable section, and names four of the project's
strongest findings as having come from it. If you take one structural idea
from this manual, consider taking that one: **give the agent a required
place to tell you that you were wrong.**

**A file promised and not supplied, twice.** *Happened:* a prompt named a
file as "supplied by the operator" without its content appearing anywhere.
The first time, the missing draft blocked a task and the pass carried on
without saying so — it cost a pass, silently. The second time, the same gap
stopped a pass at its preconditions with nothing committed. *Caught by:* the
precondition. *Rule:* [PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md) — a file a
pass must create is either already committed or its full content appears
verbatim in the prompt, and there is no third channel. The difference
between the two outcomes was entirely whether the requirement was stated as
a precondition. A gate that stops a pass is cheaper than one that does not.
([journal 0010](../../journal/0010-plan-protocol.md))

**Two documents that asked for things that cannot both be done.**
*Happened:* the prompt's Constraints said the credential is not read; task
10 asked for a scan of the tree against the credential's literal content,
which requires reading it. Separately, the plan protocol at the time
required a token count the agent has no way to measure. *Caught by:* the
pass, which stopped and stated the conflict rather than picking one silently.
*Rule:* the constraint won, the check was not performed, and the gap is
stated in the plan. This is the behaviour the Deviations section exists to
produce.
([journal 0011](../../journal/0011-fixture-design.md))

**A requirement flagged twice before it changed.** *Happened:* the token
count above was flagged in one pass, left unchanged, and flagged again in
the next. *Caught by:* two consecutive passes reporting the same impossible
field. *Rule:* the protocol now reads *"No token count. The agent cannot
measure one from inside the session, and a field it cannot measure is a
field it guesses at"*, with the note that a number without an artifact
behind it does not belong in a plan, and that the rule does not stop
applying because the number is about the agent. The lesson for a director is
the lag: a flagged defect in your own instructions does not fix itself, and
the agent will keep obeying the document until you change it.
([journal 0010](../../journal/0010-plan-protocol.md),
[journal 0011](../../journal/0011-fixture-design.md),
[PLAN-PROTOCOL.md section 11](../../PLAN-PROTOCOL.md))

**A backfill that would have required backdating.** *Happened:* a prompt
required four findings to be written into the backfilled journal entries for
early passes. One of them had been discovered later, in pass 0009, and
putting it into entries for passes 0001 to 0007 would have been exactly the
reconstruction the same task forbade. *Caught by:* the pass, which refused
and said why. *Rule:* what went in instead was the finding's *lineage* —
the same shape appearing three times in three different documents, each one
selection rule further down. An honest smaller claim beat a tidier false
one.
([journal 0010](../../journal/0010-plan-protocol.md))

**The PAT-scan premise, asserted from memory.** *Happened:* the operator's
prompt for one pass asserted that the committed credential scan could not
match the real 84-character token and would therefore report clean. Measured
against the real value, one committed pattern indeed does not match — and
the second, `[A-Za-z0-9]{52}`, **does**, because it is unanchored and a
52-character window sits inside an 84-character run. The scan could fail and
would have. *Caught by:* the pass testing the premise instead of inheriting
it. *Rule:* this is the project's own observed-versus-inferred rule broken
in a prompt about a check unable to fail, and
[journal 0014](../../journal/0014-seed-and-comparator.md) records it
"attributed to the prompt rather than to the pass: the pass measured it and
reported it, which is the behaviour the rule asks for." The real defect
turned out to be the opposite one — committing 30 SHA-256 digests would have
made the *old* scan go red on a file containing no secret, in all three
verify scripts, and a check that cries wolf gets switched off — so the
correction that mattered was an exclusion for 40- and 64-character lower-hex
runs, not a wider pattern.
([journal 0013](../../journal/0013-create-fixture.md),
[journal 0014](../../journal/0014-seed-and-comparator.md))

**A prompt that bundled two jobs into one pass.** *Happened:* a pass
stopped at a missing credential variable and committed nothing. *Caught by:*
the precondition, again. *Rule:* the operator's response was to **split the
prompt** rather than to relax the rule, and the journal names the reason:
the bundling was the defect, not the stop. A director's instinct when a gate
fires is to weaken the gate; this is the recorded counter-example.
([journal 0012](../../journal/0012-case-split-and-corrections.md))

**An old-string that was a prefix of the real line.** *Happened:* a prompt
supplied an exact line to replace, quoted up to the end of a sentence. The
file's line continued past that point. Because the edit was applied as a
substring substitution at a named line address, it succeeded and produced
the right bytes. *Caught by:* nothing — and that is the finding. A stricter
whole-line replacement would have failed loudly. *Rule:* the looser tool got
the right answer and told the pass less, which is worth remembering the next
time an edit method is chosen for a prompt that supplies exact old-strings.
([journal 0015](../../journal/0015-repository-corrections.md))

**An acceptance test that could not pass, and a roster count that
disagreed with its own lists.** *Happened:* the prompt supplied an
acceptance test that was red for a correct tag, for two compounding reasons:
`git ls-remote --tags <url> v0.1.0` matches a pattern against the tail of
the ref name and so returns only the tag object, never the dereferenced
form, so neither alternative in the supplied regex can appear; and
`Should -Match` tests each element of a piped array, so even with both lines
returned the tag-object line fails it. The same prompt's spot-check 1 said
"the nine roster paths" while its acceptance test checked thirteen.
*Caught by:* the test going red against a tag that was correct — and by
the pass
counting the prompt's own lists against each other. *Rule:* the test was
corrected minimally with the regex untouched, and the correction itself
falsified against a non-existent tag. Thirteen were built, and the verify
script asserts the roster holds *exactly* those thirteen so that a leftover
directory fails as loudly as a missing one; the roster is seventeen today.
The sharpest detail is in the journal: the reference repository's own test
file carries a comment beginning *"THREE patterns, and no `--tags`"*
explaining exactly this, and the pass had read that file earlier in the same
session without connecting it until the test went red.
([journal 0017](../../journal/0017-skill-roster.md))

**A prompt that scoped the pass out of the documents it falsified.**
*Happened:* the same pass made two committed documents false — a README
sentence and a slash-command's guidance about an option that had stopped
being mandatory — and the prompt's scope forbade touching either.
*Caught by:* the pass noticing. *Rule:* flagged in Deviations rather than
silently
fixed or silently ignored. Both remedies are worse than the flag: the fix is
out of scope, and the silence would have left two documents lying.
([journal 0017](../../journal/0017-skill-roster.md))

**The prompt guarded against the wrong failure.** *Happened:* a pass about
moving a default branch had a precondition asking whether `main` had
*moved* — the operator getting there first — but not whether `main` was
*related*. The run branches are created with their own root commit, so no
tag on one can ever fast-forward `main`. The ancestry check existed only in
the constraints, as a pre-push verification. *Caught by:* the pre-push
check, which fired and worked. *Rule:* the journal's sentence is the rule —
a hard stop is cheaper at preconditions than three tasks in. A director
writes preconditions for the failure they imagined; the failure that arrives
is usually one category over.
([journal 0018](../../journal/0018-target-main-policy.md))

**Three SHA-level claims, two wrong and one right.** *Happened:* three
consecutive prompts each contained a claim at the level of a specific
commit. The first was the unmatchable tag regex above; the second described
a move as a fast-forward that was not one; the third was exactly correct.
*Caught by:* checking each against git rather than accepting it. *Rule:*
recorded together, deliberately, and the journal says why: *"Recording the
hit alongside the misses, because a record that only notes prompts being
wrong misrepresents the rate."* Two in three is the honest number, and a
catalogue that only listed the failures would have implied three in three.
([journal 0019](../../journal/0019-history-unification.md))

**A prompt that leaked the answers into its own blind phase.**
*Happened:* the third ladder run's prompt named the two previous runs' four
difference mechanisms and their counts, because the variance section it
asked for needs them — and a run's prompt is inside its own allowlist.
*Caught by:* the run, which flagged it before any code was written.
*Rule:* deliberately **not** acted on, and stated as weakened rather than
quietly relied on: three of the four conventions were still chosen wrongly,
but the independence of that run's first-shot number is compromised, and
[README.md](../../README.md) says so in its status section. The general
form is in hazard 9: write the variance requirement without the answers, or
accept that the third run's first-shot line is not independent.
([journal 0028](../../journal/0028-run-006.md),
[hazard 9 in evals/HARNESS.md](../../evals/HARNESS.md))

**The most recent one: an instrument pin that is no longer empty.**
*Happened:* the prompt for the pass that produced this chapter states the
instrument pin as

```
git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/ evals/
```

and asserts it is empty. It is not. Running it in this repository at the
start of the pass returns `evals/HARNESS.md | 69 ++++…`, one file changed,
69 insertions — pass 0029 landed its one sanctioned documentation change
inside that path when it folded hazards 9, 10 and 11 into the harness
document. *Caught by:* running the command instead of quoting it. *Rule:*
[LEDGER.md](../../LEDGER.md) had already recorded this, under **Pins**,
before the prompt was written: it states that the ladder pin check must be
amended before the next blind run, and prescribes the three-path form

```
git diff f25d05d..main -- skills/ commands/ .claude-plugin/
```

which does still check empty — verified here — with the oracle and brief
blobs re-verified separately. The plugin proper is untouched and the pinned
SHA still names the instrument that produced all three ladder runs. A future
run written against the four-path form would hard-stop for a reason that is
not about the instrument, which is the same failure shape as every stale
expectation in this chapter, aimed this time at a prompt.
([LEDGER.md](../../LEDGER.md))

**The mechanism list, put into the builder's prompt twice — the second time
into the run the headline depends on.** *Happened:* a measured run's prompt
is inside its own read-allowlist by construction; the agent must read its
instructions. Pass 0028's prompt named runs 004 and 005's first-shot
difference mechanisms *and their counts* to run 006's builder, because the
variance section it asked for needs them. The run flagged it, did not act on
it, and recorded its own first-shot number as weakened. Hazard 9 was then
amended with the prescription: write the comparison requirement without the
answers. **Pass 0032's prompt did the same thing to run 007**, for the same
reason and in the same words. *Caught by:* both runs, against their own
prompts, in their own findings — which is what a required Deviations
section buys. *Rule:* the cost is not constant, and that is the part worth
carrying. Run 006 was the third of three identical runs and its first-shot
number was already corroborated twice; run 007 was **one** run, the only
control the project has, and its first-shot figures are the whole evidence
for the sentence now on the front page. Three of the four leaked mechanisms
recurred anyway; the fourth did not, and it is the one that made 007's first
shot look best. The rule is now [hazard 12](../../evals/HARNESS.md) rather
than a corollary at the end of hazard 9, on the principle that something two
runs have tripped over is not a corollary: **a comparison specification goes
after the gate**, referring to prior run records generically so the scorer
resolves the reference and the builder never sees what it resolves to.
Writing a rule down was not enough to stop it happening a second time, which
is itself the entry.
([hazard 12](../../evals/HARNESS.md),
[run 007 findings C-2](../../runs/007-baseline-iterated/findings.md),
[run 006 record](../../runs/006-plugin-on/README.md))

**A pin that arrived as its own placeholder.** *Happened:* the tf-003 prompt
carried the instrument pin the run was supposed to check itself against, and it
arrived **unsubstituted** — literally `<BRIEF-BLOB-FROM-0035>`. A template that
was never filled in. *Caught by:* the run trying to use it. This is the easy
case of the failure: it could not be mistaken for a value. *Rule:* **derive and
then verify, rather than trusting or stopping.** The pass computed both pins
itself with `git ls-tree`, proceeded on the derived values, and checked them
against the LEDGER's recorded ones **after** the blind gate lifted — the LEDGER
being forbidden reading during phase 1 — where both matched. The general form is
worth the entry even though the defect was obvious: **a prompt is not a pin.** A
pin that a run reads out of its instructions has been asserted; a pin the run
re-derives from the repository has been measured, and the prompt's copy is then
a cross-check rather than a source. Which means the *dangerous* version of this
defect is not the empty placeholder — it is a substituted value that is simply
stale, which looks exactly like a good pin and which only re-derivation
catches.
([pass 0036 §2](../../plans/0036-tf-003/plan.md),
[run record deviation 1](../../runs/tf-003-generalisation/README.md))

---

## Why this catalog is the argument

Read the list again and notice what almost never appears: a defect that
announced itself. Almost nothing here produced an error, a crash, or an
obviously wrong number. The overwhelming majority were **green**. The lint
gate was green over a file that would not parse. The coverage gate was green
on every build for three passes. The falsification probe was green because
it had never applied. The score was green because the denominator had
quietly shrunk. The blind run was green because nobody had checked what the
session had already read.

That is the whole case for the method. If defects announced themselves you
would not need a falsification harness, or controls of two polarities, or a
declared known-failure set, or a session gate, or a required Deviations
section. You would just look. The reason
[method/METHOD.md](../../method/METHOD.md) and
[evals/HARNESS.md](../../evals/HARNESS.md) read as heavy is that every rule
in them is buying back a specific green that turned out to mean nothing, and
each of those greens is listed above with the pass that found it.

So when a rule in this manual seems disproportionate, come back here and
find the entry it came from. And when you build your own version of this and
a rule seems disproportionate then too — keep it anyway until you have your
own catalog. You will not believe any of it until it happens to you. That is
not a criticism of you; it is the observation
[journal 0029](../../journal/0029-final-readme.md) makes about this
project's own author, who documented hazard 8 and then tripped over it in
the act of writing it down.

Next: chapter [08](./08-glossary.md) defines every term this chapter used.
Chapter [09](./09-try-before-you-trust.md) is the practice — how to prove a
check can fail before you believe that it passed.
