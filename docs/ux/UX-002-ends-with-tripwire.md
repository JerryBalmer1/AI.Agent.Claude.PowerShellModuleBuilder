# UX-002 — `ENDS WITH:` — the truncation tripwire

Status: **in force**. Every prompt in the kit states its own final line, up
front.

## Problem

**Truncated text looks exactly like complete text.** A prompt that lost its
last third to a copy that stopped early, a scroll region that did not reach the
bottom, or a chat client's own limit arrives looking finished. There is no
ragged edge, no ellipsis, and no error. The operator pastes it, the agent
executes what it was given, and both of them are working from a document
neither knows is short.

The failure surfaces later and somewhere else: a step that was never performed,
a handoff that never happened, a report missing a section nobody remembers
asking for.

## Why

Because **the reader's evidence of completeness is the same in both cases.**
Text ends. That is what text does. Nothing about a document's last line says
whether it is the last line the author wrote.

Every other integrity check this project uses works by comparing two things — a
score against an oracle, a render against a committed copy, a mirror against
its source. Truncation had no second thing to compare against, so it had no
check, and it is the one class of delivery failure that costs the whole
delivery.

The fix has to be **stated by the author and checkable by the reader before
execution**, because after execution the cost has already been paid.

## What it solves

Every prompt declares its own last line near the top:

    ENDS WITH: the LOCAL STATE table.

The reader compares that against the bottom of what they actually hold. It
takes one glance, it needs no tooling, and it turns an invisible failure into a
visible one **before anything runs**.

It is a tripwire, not a checksum: it catches text that stopped early, which is
the observed failure. It does not catch text that was altered in the middle,
and it does not catch a prompt that was complete and wrong.

## Evidence

- **Four deliveries were cut short before this rule existed** — operator-
  reported, and recorded here as such rather than reconstructed. The individual
  transcripts are not in the repository; what is in the repository is the rule
  they produced, and this record exists so the rule is not mistaken for a
  preference later.
- The same *class* of failure is documented twice inside this repository's own
  machinery, which is why the rule generalises rather than being one person's
  bad afternoon:
  - **Hazard 8**, an absence check on prose defeated by a line break — it has
    now recurred inside the falsification of its own fix (pass 0035) and inside
    a supplied insertion (pass 0040).
  - **[LEDGER item 52](../../LEDGER.md)** — a verbatim paragraph supplied in a
    prompt broke the acceptance test written to check for it, because it
    wrapped between two words the regex needed adjacent. The delivery was
    complete and the *shape* of the failure was identical: text that looked
    right, and a check that could not see the difference.
- Every file in [`prompts/`](../../prompts/README.md) carries an `ENDS WITH:`
  line, and
  [`plans/0041-operator-ux/accept.Tests.ps1`](../../plans/0041-operator-ux/accept.Tests.ps1)
  asserts that they do.
