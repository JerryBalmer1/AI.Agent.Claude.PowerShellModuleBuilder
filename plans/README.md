# plans/

One directory per pass, `plans/NNNN-<slug>/`, holding the plan file, its verify
script where the tier requires one, and any output the plan cites. The format is
[`PLAN-PROTOCOL.md`](../PLAN-PROTOCOL.md) at the repository root.

## What a plan is for

**A plan is verification.** It exists so the operator can disprove the pass
without reading the diff line by line: the prompt as received, the preconditions
and their output, per-task evidence with commands, and — at full tier — a script
that re-derives every number rather than reading it back.

A plan is written to be checked, and it is **disposable**. Once a pass is
reviewed and its work is merged, the plan has done its job. Nothing later in the
project should need to read one. If a plan turns out to be the only place some
fact is recorded, that fact was filed in the wrong place.

## How that differs from journal/

**A journal entry is narrative.** It is what the project's final README and its
summary are written from, and it is written to be read months later by someone
who was not here.

| | `plans/` | `journal/` |
|---|---|---|
| Purpose | verification | narrative |
| Audience | the operator reviewing this pass | a reader afterwards |
| Lifetime | disposable once reviewed | permanent, append-only |
| Contains | prompt verbatim, preconditions, commands, evidence, transcript | Asked, Done, Why, Measured, Learned, Capability |
| Numbers | the command that produced them | the artifact that holds them |
| Written from | the pass as it happened | the pass's committed artifacts |

The overlap is deliberate and the emphasis differs. A plan says *this command
printed 74/75*. A journal entry says *74/75, in `baseline/psmodulegraph-result.json`*.
One is a receipt; the other is a citation.

## What does not go here

- Anything another document is authoritative for. `METHOD.md` holds the general
  method, `HARNESS.md` the harness specification, `decisions/` the choices that
  outlive a pass, `evals/conformance/TASK.md` the standing instruction. A plan
  cites them; it does not restate them.
- Benefit or value claims. Those are derived once, at the end, from the journal.
- Anything that must survive the pass. Put it in a committed artifact and cite
  it from the plan.

## Reading one

Start at **Deviations**. It is the section where a pass reports that an
instruction was wrong, unclear, or impossible, and in this project that section
has carried more signal than any other — several of the strongest findings began
as a pass saying the prompt asked for the wrong thing.
