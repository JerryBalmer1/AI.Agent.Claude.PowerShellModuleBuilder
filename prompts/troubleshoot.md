# troubleshoot.md — symptom, artifact, command

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
  recorded.
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

## 3. When the artifact does not exist

This is the outcome worth naming separately, because it does not feel like a
failure and it is the most useful thing you will find.

A claim with no artifact behind it is prose about the work rather than the work.
It is not necessarily wrong — but nobody, including the agent that wrote it,
knows whether it is right. The correct response is to ask for the artifact, not
for a better explanation, and if producing it turns out to be impossible then
**that** is what should have been reported in the first place.

## 4. What none of this can tell you

**Whether your module is any good.** Every command above re-derives a fact about
shape, state or process. None of them knows what your module is for. Your own
tests are the only instrument that does, and your module earns those numbers
itself — nothing measured in this repository transfers to it.
