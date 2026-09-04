# UX-007 — The five task signals: what kind of step this is

Status: **in force**. Every step in every prompt, and every step in the plan
that answers it.

## Problem

**A prompt is a flat list of sentences, and the sentences do very different
things.** "Fetch every repository" and "PSModuleGraph is never touched" and
"the operator removes it from the session list" and "record both exit codes"
read as one undifferentiated instruction stream. They are not one kind of
thing, and the differences are the ones that matter most when a pass goes
wrong:

- a step the agent performs, versus one it may only **verify** — an agent that
  performs an operator-only step has done something the operator cannot see and
  did not authorise;
- a step whose failure means **stop**, versus one whose failure means carry on
  and record — an agent that resolves a hard stop has removed the evidence the
  stop existed to preserve;
- a prohibition that lasts the **whole pass**, versus one scoped to a task;
- a point where evidence must be **observed and written down before the next
  step opens**, versus a step that merely produces output.

Without markers, all four distinctions live in the reader's attention, and the
reader is an agent several thousand tokens into a prompt. Pass 0043 records the
shape this takes: its Phase R stopped on a dirty tree, and the question of
whether the agent was permitted to resolve it or obliged to report it was
answered by a signal, not by prose — and the prose, read alone, pointed the
other way.

## Why

Because **the cost of the four confusions is asymmetric and the prose does not
say so.** Getting an agent task wrong wastes a step. Getting an operator action
wrong performs an unauthorised act. Getting a hard stop wrong destroys the
evidence of the condition that fired it. Getting an evidence gate wrong lets a
pass reach its landing with a number nobody recorded the provenance of.

Prose weights all four the same, because prose has one register. A marker is a
second channel, and it is the channel that carries the consequence rather than
the instruction. That is why the word rides the marker rather than replacing
it: the marker is scannable, the word is unambiguous, and a reader who has
learned neither can still read the sentence.

The routing circle (UX-001) already established that this repository signals
with colour and shape. These signals reuse three of its markers, which is the
one real hazard in the convention and is addressed below rather than
apologised for.

## What it solves

Five markers, and the word always rides the marker:

| | Meaning |
|---|---|
| 🔴 | **Hard stop.** Fails → stop, report, never resolve. |
| 🟠 | **Operator action.** Agent verifies, never performs. |
| 🟢 | **Agent task.** |
| 🔵 | **Evidence gate.** Observed and recorded in `plan.md` before the next step opens. |
| ⛔ | **Never**, for the pass's whole duration. |

**The overlap with UX-001 is resolved by position, not by colour.** 🔴, 🟢 and
🔵 mean NEW SESSION, SAME SESSION and NOT A PROMPT in the routing circle, and
hard stop, agent task and evidence gate here. The routing circle leads the
block and appears exactly once; task signals appear inline against steps. A
task signal never appears on the routing line, and the routing circle never
appears against a step. Anything else is ambiguous and is asked about rather
than guessed at.

**What it deliberately does not cover.** It does not grade the *content* of a
step, only its kind — a 🟢 can still be a bad instruction. It does not replace
the Deviations section: a step whose marker looks wrong is flagged there and
executed at the stricter reading, the same way tier is a floor and never a
ceiling. And it makes no claim to be machine-enforced. Nothing asserts that a
prompt's steps carry markers at all; that is the same gap
[backlog 57](../../LEDGER.md) records for this registry as a whole, and it is
named here rather than papered over.

## Evidence

- [`PLAN-PROTOCOL.md`](../../PLAN-PROTOCOL.md) — *The five task signals*, the
  standing rule, beside *Routing signals and the tripwire* whose markers it
  shares.
- [`plans/0043-examples-showcase/plan.md`](../../plans/0043-examples-showcase/plan.md)
  — Deviation 1. Phase R's 🔴 dirty-tree stop fired on a change that the
  prompt's own operator action had necessarily produced. The agent stopped and
  asked instead of resolving, which is what the marker required and what the
  surrounding prose did not say. Letter and intent disagreed and the marker is
  the reason the disagreement surfaced at all.
- [`plans/0044-method-corrections/accept.ps1`](../../plans/0044-method-corrections/accept.ps1)
  — the markers are checkable. The acceptance test matches them by Unicode code
  point rather than by literal, so the script's own file encoding cannot be the
  reason it answers wrongly. On its red-first run it found 🔴, 🟢, 🔵 and ⛔
  already present in `PLAN-PROTOCOL.md` and reported only 🟠 missing: a check
  that discriminates, on the convention it is checking.
- [`plans/0044-method-corrections/plan.md`](../../plans/0044-method-corrections/plan.md)
  — this pass, whose every step is signalled and whose evidence gates are
  recorded in the order the markers required.
