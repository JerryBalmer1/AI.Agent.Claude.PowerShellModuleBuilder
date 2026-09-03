# new-feature.md — the delta

> **🔴 NEW SESSION** — `/clear` first, then paste the fenced block
> below as message one.
> [What the circles mean](README.md#the-legend).
>
> **ENDS WITH: the LOCAL STATE table.** Compare that against the bottom of what
> you actually hold, before you run it.
> [UX-002](../docs/ux/UX-002-ends-with-tripwire.md).

For a change to a module that already exists. Fresh session, first message,
same as before.

**This is deliberately shorter than [first-module.md](first-module.md), and the
reason is the point of the plan skill:** the six intake questions were answered
once and written into the repository, so a change only has to state what
*differs*. If you find yourself re-answering all six, that is a signal that
`docs/PLAN.md` has gone stale rather than a signal to paste the longer prompt.

---

```
# A CHANGE TO AN EXISTING MODULE

Module: <PSYourModule>
Repository: <path>
What I want: <one sentence, in user terms, not implementation terms>

## 0. Read where the module stands before proposing anything

Read, in this order, and tell me if any of them disagree with each other:

- docs/PLAN.md            - where it stands now, and what is next
- docs/plans/             - the numbered plans, newest first
- the public surface      - src/<Name>/Public/, one file per command

If docs/PLAN.md's "what is next" does not mention anything like this change,
say so. That is not a blocker; it is a fact about the plan I need to know
before you edit anything.

## 1. The delta questions - the short set

Ask me only these, and ask all of them:

1. Does this change the PUBLIC surface? A new command, a new parameter, a
   changed return shape? If yes, which - by name.
2. Does it touch an external system, or a credential path, that the module
   did not touch before?
3. What breaks for an existing user, if anything? Say "nothing" only if you
   have checked the surface, not because it feels small.
4. How will THIS change be tested - the cases, the oracle, and the command
   that runs them? Before it is written.

Then name every convention you are about to guess at. The rule that catches
the most here: an existing module already has conventions nobody wrote down,
and a change that quietly picks a different one is indistinguishable from a
defect later.

## 2. Write the delta plan

    docs/plans/NNNN-<slug>.md

Ask me for NNNN. Do not invent a pass number.

Then update docs/PLAN.md's "what is next" in the same commit - that section
just changed by definition, and a stale plan is what powershell-module-tidy
blocks a release on.

## 3. Red first

Write the test for this change and RUN IT RED before writing the change.
Paste me the failure output. If it is green before you start, stop and tell
me: either the work is unnecessary or the test cannot fail, and both are
findings.

## 4. Make the change

Follow the skills the change actually touches - do not run the whole
scaffold flow again on a module that already has a shape.

    /psmodule:build <PSYourModule> <path>
    /psmodule:test <path> <PSYourModule>

Report both scores as two numbers, against the SAME denominator as last
time. If cases-defined has moved, say so explicitly and do not compare the
percentages: two scores on two denominators are two different measurements.

## 5. Close out

- Branch, commit, push. Not main.
- What you did not do, what you guessed at, and anything wrong with this
  prompt. Mandatory.
- Perform the LOCAL HANDOFF and end with the LOCAL STATE table: every
  repository in this workspace on main, pulled ff-only, tags fetched, status
  clean, printed as repo | branch | HEAD | clean.

## What I do not want

Do not compare this module's score to any number published by the psmodule
plugin. Those were measured against a different module. The only comparison
that means anything here is this module against itself, last time.
```

---

## When the delta set is not enough

Three cases where you should be pasting [first-module.md](first-module.md)
instead, and it is cheaper to notice now:

- **The purpose sentence changed.** That is a different module wearing the same
  name, and question 1 needs asking again.
- **The credential path changed.** Question 4 is the one question this project
  will not let an agent guess at, and a delta prompt does not ask it properly.
- **You cannot answer "what breaks for an existing user".** Not "nothing
  breaks" — *cannot answer*. That means the surface is not written down
  anywhere, and the fix is an intake rather than a feature.
