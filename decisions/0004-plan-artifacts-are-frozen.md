---
decision: 0004
title: A plan and its verify script are frozen at the commit that pass pushed
date: 2026-08-29
status: accepted
passes: 0013, 0014
artifacts:
  - plans/0013-create-fixture/verify.ps1
  - plans/0012-case-split-and-corrections/verify.ps1
  - plans/0011-fixture-design/verify.ps1
  - PLAN-PROTOCOL.md
---

# A plan and its verify script are frozen at the commit that pass pushed

## Context

Pass 0013 added six assertions to `Fixture.Tests.ps1`, taking it from 346 cases
to 352. `plans/0012-case-split-and-corrections/verify.ps1` asserted:

    Assert-True 'Fixture.Tests.ps1 runs 346 cases' ($result.TotalCount -eq 346)

and went red. Nothing was wrong. Pass 0012 was a correct pass, its verify script
was a correct verification of it, and the suite had legitimately grown since.

Pass 0013 edited the pin to 352 and moved on. That was the wrong instinct, and
it is worth naming why before it becomes the habit.

Editing the pin makes the number mean less each time. `352` in a pass-0012
artifact does not describe pass 0012; it describes whatever the suite happened
to contain when someone last ran an old script and disliked the colour of the
output. And the work grows without bound: every pass that adds an assertion
would have to walk back through every previous pass's verify script. With
thirteen passes that is a chore. It does not get smaller.

The deeper error is a category error. A verify script exists to let the operator
disprove **one plan**, which described **one set of changes**, which landed at
**one commit**. Run against a later HEAD it is not verifying anything: it is
comparing a past claim against a present repository and reporting the difference
as a failure of the past claim.

## Decision

**A plan and its verify script are valid against the commit that pass pushed,
and are not maintained forward.**

Concretely:

1. Every `verify.ps1` records the SHA it was written against, in a variable at
   the top of the file.
2. On startup it compares that SHA with the current HEAD. When they differ it
   prints a plain notice saying so, and that any disagreement below may be the
   repository having moved on rather than the pass having been wrong.
3. It still runs, and it still exits non-zero on disagreement. The notice
   changes how a reader interprets a failure; it does not suppress one.
4. Pinned numbers are **not** edited as the repository grows. A pin that no
   longer matches is information about drift, which is the thing the script is
   for.

Running a verify script against a later HEAD is a legitimate thing to do — it is
how you find out what has moved. It is reading its red as "pass 0012 was wrong"
that is the category error.

## Why a notice rather than a refusal

A verify script that refused to run against a different HEAD would be useless in
the one situation where running it is most informative: checking whether an old
pass's claims still hold. The notice preserves that use and removes the wrong
reading.

## What was rejected

**Maintaining pins forward.** Every pass updates every earlier verify script so
they all stay green. Rejected: the work grows linearly with the number of
passes, and — worse — it destroys the artifact. A pass-0011 script asserting the
pass-0014 case count is no longer evidence about pass 0011. The green becomes a
statement that someone did the maintenance, which is not a claim anyone needs
verified.

**Removing the pins.** Assert only "green, and more than 300 cases", so nothing
can drift. Rejected: the pin is doing real work. A suite whose case count
silently drops is exactly the failure this project has hit before — the inert
coverage assertion, and the score comparison of decision 0003, are both cases of
a denominator moving unnoticed. A loose bound would have caught neither. The
pin's precision is the point; the mistake was reading its red as a fault rather
than as a report.

**Deleting old verify scripts once their pass is merged.** Rejected without much
deliberation: the plan cites the script, and a plan citing a deleted artifact is
worse than one citing a stale artifact.

## Consequences

- `plans/0013-create-fixture/verify.ps1` carries `$WrittenAgainstSha` and the
  HEAD-differs notice.
- `plans/0011-fixture-design/verify.ps1` and
  `plans/0012-case-split-and-corrections/verify.ps1` carry a header note
  recording that they were edited during Pass 0013, before this rule existed,
  and that the edits are visible in that pass's commit. They are not reverted:
  reverting them would make them red for a reason this decision says is not a
  fault, and the honest record is the note.
- Future passes leave earlier plans and verify scripts alone. A pass that
  believes an earlier plan is *wrong* — as opposed to superseded — says so in
  its Deviations and in the journal, and still does not edit the artifact.
