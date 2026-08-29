# NNNN — <title>

<!--
    Saved into the TARGET repository as docs/plans/NNNN-<slug>.md, committed
    with the work. NNNN is assigned by the operator and never invented.

    Delete the guidance comments as you fill each section. Do not delete a
    heading: an empty section says "we did not decide this", which is
    information. A deleted one says nothing.

    For a feature on an existing module, keep sections 1, 2, 6 and 7 and replace
    3-5 with a "What must not change" list naming the tests that already assert
    it.
-->

**Status:** draft | agreed | in progress | done
**Module:** <Name>
**Date:** YYYY-MM-DD
**Version this targets:** v0.<minor>.0

## 1. Purpose

<!-- One sentence: what question does this answer for a user? If it needs
     "and", it is two things. -->

**Not in scope:**

<!-- The things a reader would reasonably assume are included. Naming them here
     is cheaper than removing them later. -->

## 2. Command surface

| Command | Returns | Public? | Why it exists |
|---|---|---|---|
| `Get-<Noun>` | | yes | |
| `<Verb>-<Noun>` | | private | |

<!-- Approved verbs, singular nouns, module prefix on every command. A helper
     that is not an answer to a user's question is private: Public/ is the
     graded export surface and a file's location is what exports it. -->

**Splits made, and why:** <!-- e.g. parse and resolve are separate commands
because their inputs differ: one needs a file, the other needs the world. -->

## 3. External systems

| System | Access | Forbidden outright |
|---|---|---|
| | read-only / read-write | |

## 4. Authentication

<!-- Name the mechanism exactly, and the alternatives that are forbidden.
     "An environment variable" is not an answer. -->

**Credential source:**
**Never:** a parameter · a file · a URL · a log line · an exception message
**When absent:** <!-- the exact error text, naming the variable -->

## 5. Constraints

- **PowerShell version / editions:**
- **Platforms:**
- **Offline behaviour:**
- **Must never:**

## 6. Record conventions

<!-- THE SECTION THAT IS ALWAYS SKIPPED AND ALWAYS COSTS. Run 002 produced the
     oracle's exact node and edge counts and scored 1/12: all sixty differences
     were field conventions the specification never stated. -->

For each kind of record the module emits:

### `<RecordKind>`

| Field | Always present? | Value is | Example |
|---|---|---|---|
| | yes / only on <kind> | a code / a sentence / a path relative to <what> | |

**Worked example, in full:**

```json
```

**Undecided, with the default chosen here:**

<!-- A convention nobody has decided is a coin-flip. Named here, it is a
     decision. Leave this list rather than emptying it. -->

## 7. Definition of done — red first

<!-- MANDATORY. It must name how the work will be tested BEFORE the work
     starts. "Tests pass" is not a definition of done.

     A test first seen green proves nothing about whether it can fail. Five
     assertions in this project's conformance suite passed every green run and
     were inert - satisfied by a block comment quoting the code they looked
     for. -->

**The oracle.** <!-- What decides correct: a fixture with expected output, a
hand-written comparison, a schema, a specific exit code. -->

**The cases.** Each names the specific wrong answer it catches.

| # | Case | The wrong answer it catches |
|---|---|---|
| 1 | | |
| 2 | | |

**The command**, exactly as it will be typed:

```powershell
```

**Red-first evidence.** The failure output, recorded before any implementation:

```
```

**Gated vs measured.**

- Gated (the work is not done until these pass):
- Measured but not gated (recorded, not blocking):

<!-- Shape and behaviour are scored separately and never averaged. A module can
     satisfy every structural assertion and do nothing useful. -->

**Known limits accepted up front:**

<!-- What will be implemented but unexercised, covered by one target only, or
     deliberately left narrow. Recorded so the next reader knows it was a
     decision rather than an oversight. -->

## 8. Deviations

<!-- Filled in as the work happens, never omitted. Empty means writing "none".

     - anything in this plan that turned out to be wrong or impossible
     - anything done differently, and why
     - anything discovered that the plan did not ask about -->

none
