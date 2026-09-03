# troubleshoot.md — symptom, artifact, command

> **🔵 NOT A PROMPT** — this page is for you. Paste the page nowhere.
> Most of the blocks in it are commands you run in **your own shell**; two are
> marked 🟢 SAME SESSION and go into the session that is already open.
> Every block says which. [What the circles mean](README.md#the-legend).
>
> **ENDS WITH: "nothing measured in this repository transfers to it."** If this
> page stops before that line, you are missing symptoms rather than reading a
> shorter guide. [UX-002](../docs/ux/UX-002-ends-with-tripwire.md).

Three columns, and the third is the one that matters: **which command
re-derives the answer**, so you are reading a fresh fact rather than somebody's
account of one.

The loop underneath all of this is
[chapter 05](../docs/creating-an-agent/05-calling-bullshit-verification.md),
condensed to four moves:

1. **Find the claim.** A sentence with a number, a state, or a "done" in it.
2. **Name the artifact that would settle it** — a file, a result JSON, a
   pushed ref. Not a paragraph.
3. **Re-derive it yourself**, with the command in the third column. Never
   re-read the sentence.
4. **If there is no artifact, the claim is prose.** That is the finding, and it
   is a bigger one than whatever you were originally checking.

---

## 1. "The agent says done but I don't see it locally"

**The first symptom, because it is the most common and the most misread.** The
reply is confident, the branch is pushed, the summary is accurate — and your
editor shows none of it.

**The artifact is the LOCAL STATE table**, and its absence is the answer.
`PLAN-PROTOCOL.md`'s local handoff rule says a pass ends by putting every
workspace repository back on `main`, pulled fast-forward-only, tags fetched,
status clean, and printing:

| Repo | Branch | HEAD | Clean |
|---|---|---|---|
| … | `main` | `abc1234` | yes |

**If that table was not printed, the pass is not done** — however finished the
prose above it reads. Not "done but not handed over": not done. The rule exists
because "done" that requires you to run four commands before you can see it is a
different word from the one you asked for.

Re-derive it in one line per repository:

```powershell
git -C <repo> rev-parse --abbrev-ref HEAD
git -C <repo> log --oneline -1
git -C <repo> status --porcelain
```

Three outcomes, and only the first is the agent's fault:

- **On a pass branch, or behind `origin/main`.** The handoff was skipped. Ask
  for it; do not do it yourself, or the next pass inherits a state nobody
  recorded. 🟢 **SAME SESSION** — into the session that said it was done:

      Perform the local handoff and end with the LOCAL STATE table.
      Report a diverged branch or a dirty tree; do not resolve one.
- **A dirty tree.** Reported, never resolved by the agent — deliberately. Look
  at what is uncommitted before anything else touches it.
- **A diverged branch.** Also reported and never resolved. `git log --oneline
  main..HEAD` and `HEAD..main` say which way, and it is yours to settle.

## 2. Everything else

| Symptom | The artifact that settles it | The command that re-derives it |
|---|---|---|
| "The conformance score improved" | the result JSON, not the transcript | `Get-Content <the -ResultPath you passed> \| ConvertFrom-Json` — read `cases-run` **and** `cases-defined` |
| A score moved and you cannot say why | the denominator | compare `cases-defined` across the two runs. If it moved, the two scores are separate series and must not be compared at all |
| A suite looks like it passed suspiciously fast | the container list | the runner reports a container-level error and writes **no** result JSON. No JSON is the signal; a normal-looking score with missing assertions is what this prevents |
| "That assertion covers it" | the assertion body | run it against something you *know* is wrong. A check that has only ever been green is not known to be capable of red |
| A gate is "in place" | a red | remove what the gate guards and confirm it fires. Declaration is evidence about the document; only a red is evidence about the gate |
| A test passed with no cases | the case count | `PassedCount + FailedCount`. Zero is *inapplicable*, never *passed*. `TotalCount` is never zero and a guard written against it can never fire |
| "The build is green" | the exit code **and** the coverage line | `pwsh -NoProfile -File ./build.ps1; $LASTEXITCODE`. A coverage gate comparing against `$null` prints a plausible line and grades nothing |
| "It's pushed" | the remote ref, not the local one | `git ls-remote origin <branch>` — a local branch that was never pushed looks identical in your log |
| "`main` was fast-forwarded" | ancestry, from git | `git merge-base --is-ancestor <old> <new>; echo $?`. This project recorded two moves reported as fast-forwards that were not |
| A `pass-*` branch you thought had landed | ancestry again | `git branch --no-merged main` — a stranded branch surfaces at the next pass's preconditions, not releases later |
| "The plugin is installed" | the version, not the install message | `/plugin` inside Claude Code. If it does not say `1.2.0`, the pin did not take |
| A skill's advice contradicts the suite | both, read side by side | run the suite. **The suite is the oracle** and the disagreement is a finding worth reporting, not a preference to resolve |
| "It works on my machine" | which machine, exactly | `$PSVersionTable.PSVersion` and `pwsh -NoProfile -File ./tools/publish/Test-Prerequisites.ps1`, pasted whole |

## 3. "A block arrived and I don't know where to paste it"

**The answer is to ask, and that is the whole rule.** Every prompt this project
produces leads with a routing circle — 🔴 NEW SESSION, 🟢 SAME SESSION or
🔵 NOT A PROMPT. A block that arrived without one is not a block whose
routing you are supposed to infer from its contents; it is an incomplete
delivery, and the fix is one message back to whoever sent it.

**Why guessing is the expensive option.** Pasting a 🔴 into a session that
has already been talking produces a run that works. The agent answers, the
files change, and nothing in the transcript afterwards records that the context
it started from was not empty. If the run was meant to be a measurement, it has
quietly stopped being one.
[UX-001](../docs/ux/UX-001-routing-signals.md).

Send this back to whoever sent you the block. 🔵 It goes to a person, not
into a session:

    Which is this: NEW SESSION, SAME SESSION, or not a prompt at all?
    And what is its ENDS WITH line, so I can check I have all of it?

## 4. "It has been silent for a long time and I can't tell if it is stuck"

**The artifact is the heartbeat line, and its absence is most of the answer.**
A pass prints `[n/N] <task> — <estimate>` at every task boundary, so silence
has a shape: you can see which task is running and how many are left. Between
two heartbeats a pass may legitimately be quiet for many minutes — cloning,
building, rendering and running a suite all produce nothing until they finish.

- **Heartbeats appearing, long gap since the last one** — it is working, and
  the last heartbeat says on what. Wait, or ask it what that task involves.
- **No heartbeats at all** — the session is not following the protocol, which
  is worth knowing on its own. 🟢 **SAME SESSION**:

      Where are you? Print the heartbeat: [n/N] <task> - <estimate>.
      No scores on that line.
- **Heartbeat count exceeded the plan's task count** — the pass has grown work
  it was not asked for. That is a scope question, not a progress question.

[UX-004](../docs/ux/UX-004-heartbeats.md).

**And when it says it has finished: `LOCAL STATE` is the proof of done.** Not
the summary, not the pushed branch — the table. It is symptom 1 above, and it
is worth restating here because the two failures feel identical from the
outside: a session that is quiet because it is working, and a session that has
stopped without handing back. The table is what distinguishes a finished pass
from a stalled one.
[UX-005](../docs/ux/UX-005-local-handoff.md).

## 5. When the artifact does not exist

This is the outcome worth naming separately, because it does not feel like a
failure and it is the most useful thing you will find.

A claim with no artifact behind it is prose about the work rather than the work.
It is not necessarily wrong — but nobody, including the agent that wrote it,
knows whether it is right. The correct response is to ask for the artifact, not
for a better explanation, and if producing it turns out to be impossible then
**that** is what should have been reported in the first place.

## 6. What none of this can tell you

**Whether your module is any good.** Every command above re-derives a fact about
shape, state or process. None of them knows what your module is for. Your own
tests are the only instrument that does, and your module earns those numbers
itself — nothing measured in this repository transfers to it.
