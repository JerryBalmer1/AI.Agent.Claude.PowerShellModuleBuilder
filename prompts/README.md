# The prompts kit

Five paste-able documents for building **your** module with the `psmodule`
plugin. They are not documentation about the method; they are the text you
actually paste, in the order you actually paste it.

If you want the reasoning instead, start at
[docs/creating-an-agent/00-start-here.md](../docs/creating-an-agent/00-start-here.md).
If you want the walk-through of what each stage does to your repository,
[chapter 11](../docs/creating-an-agent/11-your-first-module.md) follows this kit
end to end. If you want the shape of the whole thing on one page, the README's
[flow diagram](../README.md#the-flow) is that.

## The legend

**Stated once, here.** Every prompt in this kit, every report a pass hands
back, and every proposal a director writes uses these marks and no others. A
mark that means one thing in one document and something else in another is
worse than no mark at all, so this page is the only place any of them is
defined.

**One visual channel per dimension.** Shape says what KIND of signal it is,
colour says WHICH one, and size says how deep it sits. Nothing carries two
jobs, and **the word always rides the marker** — the marker is the second
channel, never the only one. A reader with no colour, a terminal with no emoji
and a screen reader all still get the answer, because the answer is written
next to the picture of it.

### ● Routing — where a block of text goes

| | | |
|---|---|---|
| 🔴 | **NEW SESSION** | `/clear` first, then paste it as message one. Nothing of your own before it. |
| 🟢 | **SAME SESSION** | paste into the session already waiting. Do **not** `/clear`. |
| 🔵 | **NOT A PROMPT** | for the human. It is pasted nowhere. |

Why it is the first line of every prompt and not the last: a prompt is only
what the session actually received, so *where* it goes is part of what it says.
Pasting a 🔴 into a session that has already been talking is how a measured run
stops being blind, and nothing about the transcript afterwards shows it
happened. [UX-001](../docs/ux/UX-001-routing-signals.md).

### ENDS WITH — the tripwire

Every prompt states its own last line, up front:

    ENDS WITH: the LOCAL STATE table.

**Check the bottom of what you pasted against that line before you run it.** A
chat client, a scroll region and a copy that stopped early all fail the same
silent way: the text looks complete because text always looks complete. Four
deliveries were cut short before this rule existed, and every one of them was
found by its consequences rather than by its absence.
[UX-002](../docs/ux/UX-002-ends-with-tripwire.md).

### ■ Layers — which surface a thing belongs to

| | | |
|---|---|---|
| 🟪 | **DIRECTOR** | the project that writes prompts and reads artifacts. Runs no commands. |
| 🟨 | **PLUGIN** | `psmodule` — a skill, a command, a convention it enforces. |
| ⬛ | **AGENT** | the executing session: Claude Code in a terminal. |

**Every proposal is layer-tagged, and an untagged suggestion is a defect.** Not
a style preference — an untagged improvement cannot be actioned, because
nobody knows which of three surfaces to change, and the reader most likely to
guess wrong is the one who did not write it.

Square means *layer* here and in [the flow diagram](../README.md#the-flow) too,
where it carries the repository's five —
[🟪 method · 🟩 instruments · 🟨 plugin · 🟦 module · 🟥 user](../docs/diagram/README.md#the-layer-palette).
Same channel, narrowed: a prompt can only belong to three of them. The word
beside the square says which system, and 🟨 plugin is the same plugin in both.

### ◆ Depth — how far down a nested thing sits

| | | |
|---|---|---|
| 🔶 | **top** | a top-level item. |
| 🔸 | **nested** | one level in. |
| — | *below that* | a dash. Nothing is marked past two levels. |

**Two levels marked, and no more.** A third size is a size nobody can tell
from the second at a glance, and a marker that has to be measured is not a
marker.

### Status

| | | |
|---|---|---|
| ⛔ | **STOPPED** | a hard stop. It leads the report and the forensics go below it. |
| ✅ | **DONE** | finished, and the artifact proving it is named beside this. |

A hard stop reads `⛔ STOPPED — <one line why> — YOU NEED TO: <one line>`,
first, before the evidence. Putting the action underneath the analysis is how a
stop gets read as a status update. [UX-003](../docs/ux/UX-003-report-contract.md).

### The rule that makes the rest of it work

**A block without a routing circle is asked about, never guessed at.** One
question costs a message. A guess costs a `/clear` at best, and at worst a
measurement that is quietly no longer blind and no longer says what it claims.

Why each of these exists and what it cost to find out is
[`docs/ux/`](../docs/ux/README.md), one numbered record each. A convention
without a problem statement is decoration and does not land.

---

## What is here, and the order

| | File | When | What it produces |
|---|---|---|---|
| 🔵 | [project-context-template.md](project-context-template.md) | **once, before anything else** | the standing instructions your director project holds. Pasted into no session. |
| 🔴 | [first-module.md](first-module.md) | message one of a brand-new module | a planned, scaffolded, building, tested module — and `docs/PLAN.md` |
| 🔴 | [new-feature.md](new-feature.md) | any change to a module that already exists | a delta plan, then the change, against the same gates |
| 🔴 | [release.md](release.md) | immediately before a version | a tidy report, a conformance score, and a tag **you** push |
| 🔵 | [troubleshoot.md](troubleshoot.md) | when something looks wrong | which artifact to read and which command re-derives it. Two 🟢 blocks inside it. |

**The order is not a suggestion for the first two.** The context template holds
the rules that make every later prompt short; `first-module.md` assumes they are
already in place, and pasted without them it will ask you for things the
template would have answered.

## Why every one of these starts a fresh session

**A prompt is only what the session actually received.** Anything ahead of it in
the context — an earlier attempt, a conversation about what you meant, a summary
of a previous run — is part of the instruction whether you meant it to be or
not, and it will not appear in any record afterwards. That is why each file here
is written to be the *first message* of a new session rather than a follow-up:
paste it whole, into an empty session, and what the agent was asked is exactly
what is written down. It is also the only way to find out whether the plugin
alone is enough, because a session that was told the answer in the previous
message will produce it either way.
[Chapter 04](../docs/creating-an-agent/04-fresh-sessions-and-contamination.md)
is the long version, with what it cost this project when it was got wrong.

## What these prompts will not do for you

**Your module earns its own numbers.** Every score in this repository was
measured against one Azure DevOps grapher and one Terraform fixture, by one
person, on one machine. None of it transfers to your module by being adjacent to
it. The conformance suite will grade your repository honestly whatever it finds,
and what it finds is a fact about your module and nothing else — which is the
only reason the number is worth having.

The README's
[Status, honestly](../README.md#status-honestly) section is the list of what is
still unproven here, and it is worth reading before you depend on any of this.
