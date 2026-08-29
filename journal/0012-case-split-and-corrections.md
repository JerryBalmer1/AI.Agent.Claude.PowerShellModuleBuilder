---
pass: 0012
title: Split the case set by presence and absence; correct four documents
date: 2026-08-28
artifacts:
  - PLAN-PROTOCOL.md
  - method/METHOD.md
  - evals/HARNESS.md
  - evals/functional/fixture/cases.md
  - evals/functional/fixture/expected-graph.json
  - evals/functional/Fixture.Tests.ps1
  - evals/functional/FixtureCase.ps1
  - evals/functional/AZDO-FIXTURE.md
  - plans/0012-case-split-and-corrections/plan.md
  - plans/0012-case-split-and-corrections/verify.ps1
---

# Pass 0012 — Split the case set by presence and absence; correct four documents

## Asked

Apply four document corrections carried over from Pass 0010 and Pass 0011
deviations; split case 10 into case 10 and case 11; add case 12, an *absence*
case; amend assertion 7 of `Fixture.Tests.ps1` to enforce presence and absence in
the direction each names; falsify the amended assertion before recording it
green; record the pre-existing `ClaudeTesting` repository in `AZDO-FIXTURE.md`.
Entirely local — no network, no PAT, no Azure DevOps.

Split out of an earlier Pass 0012 that bundled these with fixture creation and
so put them behind a precondition they had no relationship to. That pass stopped
at its preconditions with `$env:AZDO_PAT` unset and committed nothing.

## Done

- `PLAN-PROTOCOL.md`: §9 no longer requires `verify.ps1` in a fenced block
  unconditionally; §11 no longer asks for a token count and asks for run counts
  instead. Both carry their reason.
- `method/METHOD.md`, Known limits: the corpus is off the skip list.
- `evals/HARNESS.md`, hazard 6: a third instance and an explicit guard — a probe
  asserts it changed the file before the check under test runs.
- `evals/functional/fixture/cases.md`, +157 −60: twelve cases, each with a
  `**kind:**` marker; a *Presence and absence* section stating the rule; case 10
  split; case 11 and case 12 new.
- `evals/functional/fixture/expected-graph.json`: four `cases` tags moved from
  `case-10` to `case-11`. Nothing else in the file changed; nodes 49, edges 51.
- `evals/functional/Fixture.Tests.ps1`: assertion 7 rewritten, 5 assertions to
  34, plus a CRLF regression guard.
- `evals/functional/FixtureCase.ps1`, new: the case-declaration reader, in its
  own file for a reason recorded in its header.
- `evals/functional/AZDO-FIXTURE.md`: a section on the pre-existing
  `ClaudeTesting` repository; read-back check 1 corrected from four repositories
  to five; renumbered Pass 0012 → 0013.
- `plans/0012-case-split-and-corrections/`: plan and a six-check `verify.ps1`
  that makes no network call.

No network call was made. No PAT was read. No fixture YAML changed.

## Why

The original assertion 7 — every case id appears on at least one node or edge —
can only express a presence claim. An absence case tagged onto a node would
assert the opposite of itself. So the kind is declared in `cases.md` and the
assertion enforces it in whichever direction the kind names.

An absence case must also name, on a `**checked by:**` line, the assertion that
does check it. Without that, "nothing carries this tag" is satisfied by a case
that nothing checks at all, which is a case that cannot fail.

The three `-ForEach` assertions over presence and absence carry
`-AllowNullOrEmptyForEach`, which looks like a weakening and is not. Left to
Pester's default, an empty list aborts *discovery* and takes assertions 1 to 6
down with it — hiding six working assertions to report one empty list. Two
explicit count assertions above them are what keep zero cases from passing.

Rejected: putting absence cases in a separate file. A case is a claim about what
a correct implementation outputs, and "must not contain X" is as much a claim
about output as "must contain Y". Two files would make a reader consult two
places to know what the module is judged on, and would tempt someone into
treating absence as a lesser category. Case 12 catches the *obvious* first
implementation — enumerate the project's repositories rather than derive them
from pipeline references — so it is not lesser.

Rejected this pass: adding a `.gitattributes`. It is the systemic fix for the
CRLF defect below and it changes how every file in the repository is stored,
which is more than this pass was asked for. Flagged for Pass 0013 instead.

## Measured

- Preconditions: `Fixture.Tests.ps1` green at **317** before anything was
  touched (`plan.md` §2).
- Red first, amended assertion 7 against unmodified inputs: **315 passed, 15
  failed, 330 total**, every failure in assertion 7 (`plan.md` §3).
- Green: **346 passed, 0 failed, 0 containers failed** in 4.17s (`plan.md` §4,
  task 4). Per context: 4 / 2 / 80 / 104 / 31 / 30 / 61 / 34.
- 317 → 346 accounted for exactly: −5 for assertion 7 as it was, +34 for
  assertion 7 as amended. Contexts 1–6 unchanged at 2 / 80 / 104 / 31 / 30 / 61.
- Falsification: **6 probes, 0 not-as-expected**, every row reporting
  `applied=yes` (`plan.md` §4, task 3).
- CRLF measurement, before the fix: **12 of 12** declarations carried a kind
  reading the working copy; **0 of 12** reading a CRLF copy of the same bytes
  (`plan.md` Deviations 3).
- `verify.ps1`: 6 checks, 28 assertions, exit 0; proved capable of failing by 2
  hash-guarded probes (`plan.md` §7).
- Network calls: **0**. Azure DevOps resources touched: **0**.

## Learned

**A top-level `function` in a Pester 6.1.0 test file breaks every `BeforeAll` in
that file.** The first red-first run failed all 18 assertion-7 tests with empty
error messages — the signature of a throwing `BeforeAll`, not of failing
assertions. Reduced to a file whose only top-level statement is
`function Probe-It { 'hello' }` and a `Describe` whose `BeforeAll` merely runs
`Get-Command Probe-It -ErrorAction SilentlyContinue`: it fails. The error is
"A 'break' or 'continue' statement with a label that does not match any enclosing
loop escaped from your code", which names loop labels, mentions neither functions
nor `BeforeAll`, and points at nothing that is wrong. Three loop-shaped variants
were bisected before the shape became visible; none was the cause. Dot-sourcing
the identical function from another file works in both phases.

**The kind marker regex did not survive CRLF, and this repository is configured
to produce CRLF.** `core.autocrlf` is true and there is no `.gitattributes`, so
`cases.md` arrives CRLF in any fresh clone on Windows; in .NET multiline mode `$`
matches before the `\n` but after the `\r`, so a pattern ending `[ \t]*$` fails
on every marker. The whole of assertion 7 would have failed for the next person
to clone, and passed here. It was found only because a probe *over-fired*: a
break meant to fail one assertion failed sixteen, and the extra fifteen were the
defect rather than the probe. A probe that fires more widely than intended is
usually a bad probe; this time it was the only thing looking at the file through
a different set of line endings.

**`verify.ps1` failed three of its own checks against correct documents.** All
three were defects in how prose is asserted on: a grep for "token count" cannot
tell a requirement from a sentence saying there is none; `-match` is
case-insensitive in PowerShell, so a check for the absence of "Skip the corpus"
matched the corrected text's "Do not skip the corpus"; and a check for a phrase
that markdown had hard-wrapped failed on the line break rather than the content.
Asserting on prose needs whitespace normalisation and case-sensitivity, and
neither is obvious until a correct document is reported wrong.

**The stale-pointer hazard has now appeared a fourth time, and is not closed.**
An absence case names its checking assertion in prose, and nothing verifies that
the named assertion exists. Rename the test and the pointer becomes silently
false. That is hazard 6 again — the same shape as the renamed comment-based-help
assertion in Pass 0009 and the unapplied probe in Pass 0011. The fix is the one
hazard 6 already states for the falsification driver: resolve every named
assertion against the suite's real test names and hard stop on any that does not
resolve. Not built this pass, because half of case 12's pointer names a read-back
assertion that does not exist until Pass 0013.

**A gate that stops a pass is cheaper than one that does not — second
occurrence.** The earlier Pass 0012 stopped at `$env:AZDO_PAT` and committed
nothing, and the operator's response was to split the prompt rather than to relax
the rule. The bundling was the defect, not the stop.

## Capability

- A case can claim that something is *absent* from the graph, and that claim is
  checkable. The suite enforces presence and absence in the direction each case
  declares, and an absence case that names no checking assertion fails.
- The fixture's case set carries twelve discriminating cases rather than ten,
  with the two claims that could not coexist on one pipeline separated onto two.
- `Fixture.Tests.ps1` reads its case declarations identically under LF and CRLF,
  so it gives the same answer in a fresh clone on Windows as on the machine that
  authored it — which it did not before this pass.
- `PLAN-PROTOCOL.md` no longer requires a field the agent cannot measure, and no
  longer requires an executable to exist twice in one commit.
- `method/METHOD.md` no longer tells a reader to skip the step that broke this
  project's closed loop.
- `evals/HARNESS.md` states the did-it-change guard, and both probe drivers this
  pass used implement it and report per row whether the probe applied.
- Pass 0013 can be given the pre-existing `ClaudeTesting` repository as a
  written constraint and a case, rather than as a surprise during creation.
