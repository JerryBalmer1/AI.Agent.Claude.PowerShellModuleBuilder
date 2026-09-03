# UX-003 — The report contract: `## YOUR NEXT ACTION` and `⛔ STOPPED`

Status: **in force**. Applies to every pass report, every hard stop, and every
terminal error the plugin's own modules raise.

## Problem

**A report that ends in analysis leaves the reader to work out what to do.**
The evidence is complete, the reasoning is sound, the artifacts are all linked
— and the operator still has to read the whole thing to discover whether
anything is required of them, and if so what.

The hard-stop case is worse. A pass that cannot continue has, by definition,
the most detail to report: what it tried, what it found, why it stopped. If
that detail comes first, the one line the operator has to act on sits at the
bottom of the longest section in the document, and a stop gets read as a status
update.

The same problem has a third form, and it is the one a stranger meets first: a
terminal error that describes a condition and not a fix.

## Why

Because **the writer and the reader want opposite orders.** The writer arrives
at the action last — it is the conclusion of the investigation, and writing it
first feels like asserting it without support. The reader wants it first,
because everything above it is only interesting once they have decided to care.

Left to itself, a report is written in the order things were discovered. That
order is right for the evidence and wrong for the person, and the report is for
the person.

For errors the asymmetry is sharper still: **a terminal error is read by
somebody who is already blocked.** Anything printed before the fix is in their
way. The reader most likely to see it is a sysadmin who will paste it into a
search box — so the error had better answer before the search does.

## What it solves

Every pass report ends with **`## YOUR NEXT ACTION`** — one plainly-stated
action for the operator, or `none: hand this report to the director.` The
"none" case is not filler; it is the difference between "nothing is needed" and
"nobody said".

A hard stop leads with:

    ⛔ STOPPED — <one line why> — YOU NEED TO: <one line>

and puts the forensics underneath it. Why, and what to do, in the first two
lines. Everything that justifies them below.

The same shape governs errors: **every terminal error states the fix or names
the document, in one line, before any detail.** The worked example is
[`Test-Prerequisites.ps1`](../../tools/publish/Test-Prerequisites.ps1), which
reports each missing prerequisite with the exact line that installs it, and
says in so many words which of the five can be knowingly ignored — so a missing
PAT is a `1 of 5 missing` the reader can dismiss on purpose rather than a
mystery.

It does not govern the body of a report and it does not shorten one. A long
report with a clear first line is fine; a short one that buries the action is
not.

## Evidence

- [`PLAN-PROTOCOL.md`](../../PLAN-PROTOCOL.md) — *The report contract*, which
  states the rule for every pass.
- [`prompts/troubleshoot.md`](../../prompts/troubleshoot.md) — built entirely
  as symptom → artifact → the command that re-derives it, which is this
  ordering applied to the operator's own debugging.
- [`tools/publish/Test-Prerequisites.ps1`](../../tools/publish/Test-Prerequisites.ps1)
  — the worked example, and the reason it runs under Windows PowerShell 5.1 on
  purpose: a prerequisite checker that will not start on the wrong PowerShell
  is useless exactly when it is needed.
- [`skills/powershell-module-ux/SKILL.md`](../../skills/powershell-module-ux/SKILL.md)
  — carries the error standard for modules the plugin builds, and cites this
  record.
- A worked instance from this pass: PSGraphRenderToHtml's `-ColorBy` refusal
  names both repositories and both accepted sets, because a caller reading it
  is looking at the wrong repository's documentation. The transcript is
  [`colorby-falsification.txt`](../../plans/0041-operator-ux/colorby-falsification.txt).
