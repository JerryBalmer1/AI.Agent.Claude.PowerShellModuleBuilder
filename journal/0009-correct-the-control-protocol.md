---
pass: 0009
title: Correct the control protocol, consolidate the record
date: 2026-08-28
artifacts:
  - evals/conformance/Conformance.Tests.ps1
  - evals/conformance/README.md
  - evals/conformance/TASK.md
  - evals/conformance/baseline/CONTROL-SWEEP.md
  - evals/conformance/baseline/psmodulegraph-result.json
  - evals/conformance/baseline/psmodulegraph-build-result.json
  - evals/HARNESS.md
  - decisions/0002-exports-no-implicit-wildcards-stays-universal.md
  - decisions/0003-score-comparability.md
---

# Pass 0009 — Correct the control protocol, consolidate the record

## Asked

Correct two rules that were defects in the instructions rather than the work:
the "no push" rule, and the gate wording that assumed a perfect control target.
Add the control-polarity rule, and sweep every positive assertion in the suite
with the polarity-correct control, converting any the correct control defeats.
Add a stale-expectation guard to the falsification driver and record the hazard.
Write two decision records. Create METHOD.md from a supplied draft and backfill
journal entries 0001-0007. Finish the sweep and stop rather than truncating it
to reach the last two items.

## Done

Suite, `evals/conformance/Conformance.Tests.ps1`:

- Discovery's third selection rule — take the lone surviving candidate — removed.
  Selection is now `$repoName`, then a manifest sitting directly in the target,
  and nothing else.
- Three `House style: generated module` assertions converted from regexes over
  the psm1 text to AST checks over a parsed psm1: `sets $script:ModuleRoot`
  (an `AssignmentStatementAst`), `exports exactly the manifest surface` (a
  `CommandAst` for `Export-ModuleMember` with the exported names as string
  constants inside it), and `includes functions from Private subfolders`
  (`FunctionDefinitionAst` names). The psm1 is parsed once in the Describe's
  `BeforeAll`.
- `marks the generated file as generated` deliberately left as a text match: the
  marker is a comment, so matching text is matching the thing itself.

Driver, `scratch/falsify-driver.ps1` (not committed — scratch):

- A preflight that resolves every row's expected-assertion name against the
  assertions the current suite produces, and throws on any that does not
  resolve.
- A guard rejecting unknown `-Only` names and a zero-row selection.
- 22 polarity-correct probes covering every positive assertion outside the
  build-file block, plus `SkipPostRebuild` for rows that edit build output.

Records: `README.md` gains the control-polarity rule and a note distinguishing
scope controls from polarity controls. `baseline/CONTROL-SWEEP.md` is new — the
full sweep table and the three defects. `HARNESS.md` gains hazard 6 (stale
expectations) and a partial-decoy note under hazard 4; the control-polarity rule
is folded into the falsification section. `decisions/0002` and `decisions/0003`.
`TASK.md` records the corrected gate and ticks it.

Branch `pass-0009-control-polarity` pushed to origin, before the pass and again
after it.

## Why

- **The lone-candidate rule was removed rather than narrowed.** The alternative
  was to keep it but require the candidate to be somehow plausible — nearer the
  root, or matching a fuzzy name. Rejected: every version of "plausible" is a
  guess, and rule 10 already says the suite stops rather than guessing. All nine
  targets still resolve without it, so it was buying nothing but the misgrade.
- **Three psm1 assertions converted, one left as text.** The distinction is
  whether the artifact being matched *is* prose. `auto-generated` is a comment by
  design; matching it as text is correct. An `Export-ModuleMember` call is code,
  and a comment that looks like it is not it.
- **`exports no cmdlets, variables, or aliases implicitly` kept in Universal**
  despite the worst pass rate in the tag — see decision 0002. The failure rate
  looked identical to `CompatiblePSEditions`, which moved to HouseStyle last
  pass; the decisions differ because an absent export key has a mechanical
  consequence and an absent `CompatiblePSEditions` has none.
- **The specified control was implemented as specified *and* supplemented.** The
  prompt's comment-only probe was run against all five build-file assertions in
  Pass 0008 and all five passed it; the deletion probe found all five defective.
  Running only what was asked would have recorded five defective assertions as
  sound. This pass took the same approach to the psm1 block, which is where the
  three new defects came from.

## Measured

Reference, unchanged across the pass — `baseline/psmodulegraph-result.json` and
`psmodulegraph-build-result.json`:

- `Universal,Repository,HouseStyle`: 74/75, 27 assertions.
- all four tags: 80/81, 33 assertions.

Corpus, unchanged after the discovery repair — posh-git 28/33, ImportExcel
17/79, Az.Accounts 9/10, Pester 36/36, Crescendo 7/20, SqlServerDsc 170/171,
PSDepend 18/18, Az 9/10.

Falsification, all re-run: 24 non-rebuild rows and 5 rebuild rows behave; 12
scope controls stay green; 5 build-file substitution probes fire; 22
polarity probes run, of which 3 exposed defects and now fire after repair.
`baseline/CONTROL-SWEEP.md` carries the row-by-row table.

## Learned

- **A scope control and a polarity control answer different questions, and
  twelve of the former missed three defects the latter found in one sitting.**
  An assertion with only a scope control has been shown not to be over-broad. It
  has not been shown to work.
- **The Pass 0008 discovery repair was incomplete and looked complete.** It fixed
  the first two selection rules and left the third, which then produced the same
  class of misgrade — grading the vendored PSCorpus module — the repair was
  written to eliminate. Nothing in the corpus run could have surfaced it, because
  every corpus target resolves on the first two rules. Only removing the thing
  the assertion is about surfaced it.
- **The guard against a false negative was very nearly a false positive.** The
  stale-expectation preflight was first implemented with `Run.SkipRun`, which
  does not expand `-ForEach` names; it would have hard-stopped on every
  parameterised row. Caught on its first use.
- **A partial decoy is worse than none.** The probe for
  `includes functions from Private subfolders` initially removed every nested
  private function but decoyed only one name. It went red on the others and
  would have been filed as "no defect". Decoying every name showed the assertion
  was satisfied by comments.
- **Two probes of mine corrupted the target before they tested it** — one left an
  unbalanced brace in the build file, one mangled a string through a nested
  escaping layer. Both were caught by the rebuild failing rather than by
  inspection, which is the argument for rebuilding inside the row rather than
  trusting the edit.

## Capability

- The suite refuses to grade a module it cannot identify, including the case
  where exactly one wrong candidate remains.
- Every assertion over generated module content distinguishes a comment from
  code.
- Every positive assertion in the suite has a falsification row proving it fails
  on its own absence, and not on a resemblance left in its place.
- The falsification driver cannot silently run against a renamed assertion, or
  against zero rows.
- The work is on a branch on origin and can be reviewed without access to this
  machine.

## Not done

- **K4, METHOD.md.** Blocked: the draft the prompt says the operator will supply
  was not supplied. Nothing was written, and the control-polarity rule that K1
  asks to place there is currently only in `README.md`.
- **K5, journal backfill 0001-0007.** Deferred to Pass 0010, on the prompt's own
  precedence — the sweep was not truncated to reach it.
