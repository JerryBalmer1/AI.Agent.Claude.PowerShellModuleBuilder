# UX-001 — Routing signals: 🔴 NEW SESSION · 🟢 SAME SESSION · 🔵 NOT A PROMPT

Status: **in force**. Applies to every prompt in [`prompts/`](../../prompts/README.md),
every block a director hands to an operator, and every report that asks for one
back.

## Problem

**A block of text does not say which session it belongs in, and the text is
identical either way.** The operator receives something that looks like a
prompt and has to decide three things the block itself never states: does this
go into a fresh session, into the one already waiting, or nowhere at all
because it was addressed to them.

Getting it wrong is not loud. Pasting a fresh-session prompt into a session
that has been talking produces a perfectly plausible run — the agent answers,
the work happens, and nothing in the transcript afterwards records that the
context it started from was not empty.

## Why

Because **a prompt is only what the session actually received.** Everything
ahead of it in the context window — an earlier attempt, a conversation about
what was meant, a summary of a previous run — is part of the instruction
whether anyone intended it or not, and none of it appears in the record.

That makes routing a property of the *instruction*, not of the operator's
workflow. An instruction that omits half of itself and relies on the reader to
supply the rest is incomplete, and it is incomplete in the direction that is
hardest to detect: the failure produces output, and the output looks right.

For a measured run it is worse than untidy. This project's whole claim rests on
runs that were blind, and blindness is a fact about what was in the context
window. Two of this project's own runs had prompts that leaked oracle content
into their own blind phases, and both were caught only because the runs
themselves flagged it.

## What it solves

Every prompt leads with one of three circles, and the word rides the circle:

- **🔴 NEW SESSION** — `/clear` first, paste as message one, nothing before it.
- **🟢 SAME SESSION** — paste into the waiting session; do not `/clear`.
- **🔵 NOT A PROMPT** — for the human; it is pasted nowhere.

Shape carries the dimension (a circle is always routing) and colour carries the
value, so the three never collide with the layer squares or the depth diamonds.
The word is always present, so colour is a second channel and never the only
one.

**The closing rule is the load-bearing one: a block without a routing circle is
asked about, never guessed at.** One question costs a message. A guess costs a
`/clear` at best, and at worst a measurement that is quietly no longer blind.

It does **not** cover what happens inside a session once the prompt has landed,
and it does not make a fresh session verifiably fresh — nothing here can
observe the operator's context window. It removes the ambiguity in the
instruction, not the possibility of error.

## Evidence

- [`docs/creating-an-agent/04-fresh-sessions-and-contamination.md`](../creating-an-agent/04-fresh-sessions-and-contamination.md)
  — the long-form argument, with what it cost this project when it was got
  wrong.
- [`prompts/README.md`](../../prompts/README.md#why-every-one-of-these-starts-a-fresh-session)
  — why every document in the kit is written to be a first message.
- Hazard 12 in [`evals/HARNESS.md`](../../evals/HARNESS.md), and the
  `<sup>c</sup>` caveat in the [README's headline table](../../README.md#with-the-plugin-and-without-it):
  two runs' prompts leaked oracle content into their own blind phases, and
  run 007's first-shot figures are the ones the headline comparison rests on.
  Both runs flagged it themselves; nothing else would have.
- The circles are declared once in
  [the kit's legend](../../prompts/README.md#the-legend) and nowhere else.
