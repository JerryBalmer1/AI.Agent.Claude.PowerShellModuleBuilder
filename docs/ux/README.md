# Operator-experience records

One numbered record per convention that governs how this repository talks to
the person running it. Problem, why, what it solves, evidence — in that order,
every time.

**The rule this registry exists to enforce: a convention without a problem
statement is decoration, and decoration does not land.**

It is easy to add a marker, a heading or a required line because it looks
tidier. Tidier is not a reason. Each record below names a specific thing that
went wrong, or would have, and the convention is what that thing cost. A
proposal that cannot fill in `## Problem` with something that actually happened
is a proposal to make the documents busier.

The records are **written before the convention ships**, not after. Writing the
problem down first is what catches the conventions that turn out to be
preferences.

| | Convention | The problem it answers |
|---|---|---|
| [UX-001](UX-001-routing-signals.md) | routing signals — 🔴 🟢 🔵 | a prompt's text does not say which session it belongs in, and pasting it into the wrong one is invisible afterwards |
| [UX-002](UX-002-ends-with-tripwire.md) | `ENDS WITH:` | truncated text looks exactly like complete text |
| [UX-003](UX-003-report-contract.md) | `## YOUR NEXT ACTION`, `⛔ STOPPED` | a report that ends in analysis leaves the reader to work out what to do |
| [UX-004](UX-004-heartbeats.md) | `[n/N] <task>` heartbeats | a long silent run is indistinguishable from a hung one |
| [UX-005](UX-005-local-handoff.md) | the `LOCAL STATE` table | "done" that needs four commands before you can see it is a different word |
| [UX-006](UX-006-presentation-standard.md) | the presentation standard | a repository that grades other people's output shipped a front door nobody had graded |

## The shape

Four headings, in this order, and none of them optional:

- **`## Problem`** — what goes wrong without this. A specific event where
  possible, and named as hypothetical where not.
- **`## Why`** — why it goes wrong. The mechanism, not the symptom, because
  the mechanism is what says whether the convention actually addresses it.
- **`## What it solves`** — what the convention is, precisely enough to follow,
  and what it deliberately does not cover.
- **`## Evidence`** — the artifacts. A record whose evidence is "it feels
  better" is one of the decorations this registry exists to catch, and saying
  so in the record is better than leaving it out.

Numbers are never reused and never renumbered. A convention that is withdrawn
keeps its record and gains a line saying it was withdrawn and why — a number
that disappears takes its reasoning with it.
