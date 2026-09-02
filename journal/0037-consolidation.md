---
pass: 0037
title: Put the instrument where the next run will find it, and bound the claim
date: 2026-09-02
artifacts:
  - evals/tf/fixture2/Test-TfFixture2Case.ps1
  - evals/tf/fixture2/Invoke-TfFixture2CaseFalsification.ps1
  - evals/tf/fixture2/cases.md
  - evals/tf/Invoke-TfSuite.ps1
  - plans/0037-consolidation/plan.md
  - plans/0037-consolidation/case-scorer.txt
  - plans/0037-consolidation/case-layer-falsification.txt
  - plans/0037-consolidation/suites.txt
  - plans/0037-consolidation/tf-003-rescore.txt
  - plans/0037-consolidation/verify.ps1
  - plans/0037-consolidation/verify-falsification.txt
  - runs/tf-003-generalisation/README.md
---

# Pass 0037 — Put the instrument where the next run will find it, and bound the claim

## Asked

Promote the fixture-2 case scorer out of `plans/0036-tf-003/` into `evals/`,
correcting the one false case rule and falsifying it in place; re-score tf-003
with the promoted scorer from a fresh built clone and append the result to the
run record; rewrite the README's generalisation section around what tf-003
supports and the bound in the same breath; fold the pass into chapters 02, 03,
07 and docs/testing; release v1.1.1; and queue the plugin-off control as an
operator decision rather than taking it.

## Done

- Branch `pass-0037-consolidation`; acceptance test committed as supplied and
  run red — 7 of 8, with the eighth recorded as green-for-the-wrong-reason.
- Promoted the scorer to `evals/tf/fixture2/Test-TfFixture2Case.ps1` with its
  falsification beside it, corrected `cases.md` case 6, added a duplicate-id
  refusal, wired the case layer into `Invoke-TfSuite.ps1` and re-pinned
  fixture 2 8 → 18.
- Re-scored tf-003 from fresh built clones of `d788f7c` and `d76d16b`; appended
  a dated correction note to the run record.
- Rewrote the README's Terraform section; replaced one stale *Status, honestly*
  bullet with three.
- Chapter 02 stage 7b and a stage 8 correction; chapter 03 section (e); two
  chapter 07 entries; docs/testing's seventh layer.
- Released **v1.1.1**, annotated tag pushed. `skills/` and `commands/`
  unedited.
- `verify.ps1`, five checks, all falsified; the LEDGER; this entry.

## Why

**The scorer was promoted as a second file rather than as a `-Fixture` switch.**
Backlog 36 offered both. Fixture 1's scorer is the instrument tf-001 and tf-002
were scored with, and the two fixtures' cases differ in substance rather than in
ids — fixture 2's case 1 is four levels deep, its case 3 lands in outputs as
well as locals, its case 7 has two shapes. One script with two rule sets would
have had to say which fixture each clause belonged to on every line, which is
what two files already say.

**The correction to `cases.md` had to be stricter, and the strictness had to be
a row rather than a sentence.** A rewritten discriminator that happens to be
easier to satisfy cannot be told apart from quietly dropping the case. So the
promoted case 6 pins the whole edgeless set by id, and the falsification report
carries a graph the plans-era form scores 7 / 7 which the promoted form reddens.
That was worth the extra check: without it "stricter" is a claim in a commit
message.

**The prose lost, not the oracle.** Ten nodes satisfy the old clause literally,
and the nine that are not the unused variable were read out of the frozen
oracle. A document that disagrees with a frozen oracle is the document that
changes. The superseded wording is struck through rather than deleted, for the
reason the LEDGER strikes closed items rather than rewriting them.

**tf-003's numbers were re-derived rather than re-read.** The promoted scorer is
not the instrument that produced them — its case 6 is stricter and it refuses a
duplicated id — so quoting the record forward would have been quoting a number
taken with a tool that no longer exists in that form.

**The claim was not allowed to grow.** The numbers would support a strong
sentence and the README now refuses it in the same paragraph that states them:
the `tf-*` skills were written from tf-001 and tf-002 and cite their findings by
count, so what is measured is recurrence prevention on an unseen fixture in a
domain the plugin already carries — not generalisation.

**The control was queued, not taken.** It is one fresh session, and the session
is spent permanently once used. That is the operator's call, and it is written
down with its cost rather than as a wish.

## Measured

| | |
|---|---|
| acceptance | red 7 of 8 → green **8 of 8** ([accept-green.txt](../plans/0037-consolidation/accept-green.txt)) |
| case scorer | oracle vs self **7 / 7**; seven mutations each defeating its own case and no other; mutation 8 **refused**; the strictening demonstrated ([case-scorer.txt](../plans/0037-consolidation/case-scorer.txt)) |
| case layer, falsified | **2 / 2** breaks turn it red and it comes back green ([case-layer-falsification.txt](../plans/0037-consolidation/case-layer-falsification.txt)) |
| suites | `FIXTURE1: 15 passed, 0 failed`; `FIXTURE2: 18 passed, 0 failed` ([suites.txt](../plans/0037-consolidation/suites.txt)) |
| tf-003 rescore | **6 / 7 → 7 / 7**, 184 → 0, 99/99 and 88/88, every number held; final graph byte-identical to the record ([tf-003-rescore.txt](../plans/0037-consolidation/tf-003-rescore.txt)) |
| verify | **5 / 5**, each falsified alone ([verify.txt](../plans/0037-consolidation/verify.txt), [verify-falsification.txt](../plans/0037-consolidation/verify-falsification.txt)) |
| release | `v1.1.1`; `git diff v1.1.0..v1.1.1 -- skills/ commands/` **empty**; six changed `.claude-plugin/` lines, all version fields |
| AzDO | six read-only clones, **zero** builds queued, zero writes |

## Learned

- **An acceptance assertion can be green at start for the wrong reason, and the
  reason was hazard 8 again.** *"cases.md false clause corrected"* passed before
  any work, because the clause it names is line-wrapped in the file and the
  literal pattern never had anything to match. It cannot witness the correction
  in either direction. Hazard 8 is about asserting on prose; this is the same
  hazard arriving in the *acceptance test* rather than in a verify script, which
  is a place it had not been seen before.
- **A stricter rule can entangle cases, and that has to be checked before it is
  adopted.** Pinning the whole edgeless set by id would have reddened case 6
  whenever a mutation isolated a node — which would have broken "each mutation
  defeats its own case and no other". It does not here, and that was established
  by reading the oracle's edge degrees for every node the mutations touch rather
  than by running the suite and seeing green.
- **PowerShell variable names are case-insensitive, so `$l` and `$L` are one
  variable.** A `foreach ($l in …)` loop silently overwrote a
  `List[string]` accumulator called `$L`, and the error surfaced as *"[String]
  does not contain a method named 'Add'"* — pointing at the accumulator, three
  screens from the loop that destroyed it. Skill-line candidate for a PowerShell
  authoring skill.
- **`New-Object System.Collections.Generic.List[string]` is not the same as
  `[System.Collections.Generic.List[string]]::new()`.** The first was a red
  herring while chasing the above; it is worth knowing which of the two forms
  survives an unquoted generic type argument.
- **A large heredoc through `bash -c` is a worse tool than the file writer for a
  PowerShell script.** One 270-line quoted heredoc failed to parse and wrote
  nothing, and the failure looked like a syntax error in the PowerShell rather
  than in the shell wrapping it.
- **The pass that promotes an instrument is the pass that discovers what the
  promotion is worth.** The scorer had been green in its plan directory. Moving
  it, re-pinning the suite, and breaking both new checks on purpose is what
  turned "there is a scorer" into "there is a scorer the suite would notice the
  loss of".

## Capability

The project can now score a fixture-2 graph case by case **from `evals/`**,
where a run will find it, with a falsification and an oracle-against-itself
control that travel with the scorer rather than with the pass that wrote it.
The fixture-2 suite has two layers and a pin that would notice either being
lost.

`runs/tf-003-generalisation/` now carries numbers re-derived under a stricter
instrument than the one that produced them, and `README.md` states what those
numbers license and what they do not — with the one measurement that would
settle the difference written down as a costed decision instead of an aspiration.
