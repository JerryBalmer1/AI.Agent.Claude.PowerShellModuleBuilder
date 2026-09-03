# 11 — Your first module

Every other chapter is about building an agent you can grade. This one is about
using the agent that already exists.

It walks the **New** flow — `new → plan → build → test → tidy → release` — end
to end, against the paste-able text in [`prompts/`](../../prompts/README.md).
The kit is what you paste; this chapter is what each paste is *for*, what lands
on your disk afterwards, and how to tell whether it actually happened.

The same flow is drawn in [README's "The flow"](../../README.md#the-flow), one
picture, with a link map to every artifact named below.

---

## Before you start

Two things, and both of them are cheap to get wrong.

**Check your prerequisites in a shell, not inside Claude Code.**

```
pwsh -NoProfile -File ./tools/publish/Test-Prerequisites.ps1
```

Five things: PowerShell 7.2+, Pester, InvokeBuild, git, and `$env:AZDO_PAT`. The
PAT is needed only by the three Azure DevOps skills and **not** to build a
module, so a missing one is a `1 of 5 missing` you can knowingly ignore rather
than a mystery. The checker runs under Windows PowerShell 5.1 on purpose — one
that will not start on the wrong PowerShell is useless exactly when you need it.

**Install pinned, and check the pin took.**

```
/plugin marketplace add JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder@v1.2.0
/plugin install psmodule@psmodule-builder
```

`main` moves whenever a pass lands. The `@v1.2.0` is what keeps work in progress
from reaching you, and `/plugin` is how you confirm it: if it does not say
`1.2.0`, the pin did not take and you are running something nobody released.
[Chapter 09](./09-try-before-you-trust.md) does the whole thing locally first,
if you would rather not add a marketplace yet.

---

## The five stages, and what each leaves behind

The table first, because it is the part worth having open while you work. Then
one section per stage on the part that is not obvious.

| Stage | Skills, in order | What appears on disk | What `docs/PLAN.md` says afterwards |
|---|---|---|---|
| **new** | none | nothing — an empty directory and a decision not yet made | it does not exist yet |
| **plan** | `powershell-module-plan` | `docs/plans/0001-<slug>.md`, `docs/PLAN.md` | all five sections, "what is next" naming this work |
| **build** | `architect`, `scaffold`, `build`, then `docs` + `ux` alongside, `analyzer` inside the build | `src/<Name>/`, the manifest, `build.ps1`, `<Name>.build.ps1`, `PSScriptAnalyzerSettings.psd1`, `Requirements.psd1`, `output/` | unchanged — building is not a status change |
| **test** | `powershell-module-test` | `tests/`, a conformance result JSON | unchanged |
| **tidy** | `powershell-module-tidy` | `tidy-report.json` | **must** be current, or the release is blocked |
| **release** | `release`, then `deploy` | `CHANGELOG.md`, a worklog entry, a bumped manifest | "where it stands" rewritten |

**Where the order is real, and where it is not.** Intake before everything, or
the rest is a coin-flip nobody recorded. Architect and scaffold before build —
you cannot emit a module for a surface nobody has designed. Test after build,
because the runner's third layer imports what build emitted. Tidy last. But
`docs` and `ux` run *alongside* build rather than after it, `analyzer` is a task
*inside* the build rather than a stage following it, and `release` and `deploy`
have no order between them at all. A flow that claims more sequence than it has
teaches you to wait for things that are not coming.

### new — the stage that exists so the next one is not skipped

Nothing happens here, which is the point. You have a directory and a sentence
about what the module is for, and the temptation is to start typing commands.

Paste [`first-module.md`](../../prompts/first-module.md) instead, into a **new**
session, as the first message. Not after a conversation about what you meant —
[chapter 04](./04-fresh-sessions-and-contamination.md) is the long version of
why, and the short version is that anything ahead of the prompt is part of the
instruction and appears in no record afterwards.

### plan — six questions, and the sixth is the one

`powershell-module-plan` asks six: purpose, command surface, external systems,
authentication, constraints, and definition of done. **Answer all six even when
the answer is obvious**, because obvious is precisely where you and the agent
disagree without noticing.

Question 6 is mandatory and the others exist to make it answerable: *how will
this be tested, before it is written?* A definition of done written afterwards
is written to fit the work, and then the only thing you have learned is that the
agent can satisfy a standard chosen by the thing being graded. That is the
single idea the rest of this manual rests on —
[chapter 03](./03-test-first-or-nothing.md).

Two documents come out of this stage and they are different things:

- **`docs/plans/0001-<slug>.md`** — this piece of work, numbered and frozen. You
  supply the number; the agent never invents one.
- **`docs/PLAN.md`** — where the module stands *now*, in plain language, exactly
  one of it, always current. Five sections: what it is, why it exists, where it
  stands (the honest version, including what is written rather than measured),
  what is next, and where the detailed records live.

Write `PLAN.md` for somebody who will never open the machinery — who came back
after three months, or inherited the repository, or is deciding whether to
depend on it. If the only way to know where a module stands is to read seven
plan files in order, nobody knows where it stands.

### build — and the one thing to watch for

`/psmodule:build` follows the scaffold and build skills. What lands is the tree
the conformance suite grades: a manifest whose base name equals its directory
name, `Public/` flat with one function per file, `Private/` nesting freely,
explicit exports, and a committed dev loader so `src/` is importable without a
build.

**The thing to watch for is a disagreement.** The command's own instructions say
it: where a skill and the conformance suite disagree, **the suite is the oracle**
and the disagreement is a finding worth reporting rather than a preference to
resolve. If your session quietly picks the skill's side, you have lost the only
signal that would have told you a skill is wrong.

### test — two numbers, never one

`/psmodule:test` runs the module's own build and then the conformance suite, and
reports them as **two numbers, never averaged**. Averaging a build score with a
conformance score hides which one moved, and the whole reason for having two is
that they fail for different reasons.

Underneath, the ordered runner does five layers and stops at the first failure:
manifest parses, files parse, module imports in a clean child process, unit,
integration. One unparseable file otherwise reports as thirty-seven failing
tests, and the wall of red buries the filename that would fix it.

Three readings that matter more than the score:

- **Did every container load?** One that fails discovery takes its assertions
  with it, and the numerator and denominator shrink together, so the percentage
  looks unremarkable. This project survived a full scoring run that way.
- **`cases-run` and `cases-defined`, both.** `cases-defined` is the denominator
  that does not move with your module's shape, and
  [decision 0003](../../decisions/0003-score-comparability.md) requires both
  wherever two scores are compared.
- **A red run is data.** The runner exits 0 on purpose — the run succeeded, the
  module failed, and those are different facts. Read the score from the result
  JSON, never from the exit code.

### tidy — where a stale plan stops you

Run once, immediately before a version. It is not the conformance suite and it
is not a linter; it grades the *repository against itself*, and most of what it
finds is drift between two things that were both correct when they were written.

The check that catches people is `docs/PLAN.md` currency, and it is deliberately
mechanical: the newest commit touching `src/` is newer than the newest commit
touching `docs/PLAN.md`. It cannot be argued with, only satisfied, and the
response to a false positive is a one-line edit saying the work landed. That
ten-second edit is exactly the behaviour the rule exists to produce.

### release — and the line the agent does not cross

The agent prepares: semver against the surface, the changelog entry, the worklog
entry, the manifest bump, and the tag command **shown rather than run**.

**Tagging and publishing are yours.** Not because the agent cannot type them,
but because everything before that line is reversible inside your own repository
and everything after it reaches other people. A pushed tag is immutable — a
release that was wrong is superseded by a new version, never by moving a tag —
and a module on a gallery cannot be recalled from the machines that already
installed it. [`release.md`](../../prompts/release.md) marks both verbs
human-only and says so twice.

---

## When something looks wrong — the five questions

[`troubleshoot.md`](../../prompts/troubleshoot.md) is the working version, keyed
by symptom. This is the same content keyed the other way, for when you do not
yet know what the symptom is.

| | Ask | And the answer is an artifact |
|---|---|---|
| **Who** | Who made this claim — the agent about its own work, or a file? | The agent's summary is prose it wrote about itself. `docs/PLAN.md`, the result JSON, the pushed ref and the tidy report are not. |
| **What** | What exactly is being claimed — a number, a state, or a "done"? | A number needs `cases-run` **and** `cases-defined`. A state needs a git command. A "done" needs the LOCAL STATE table. |
| **When** | When was it true? | `git log --oneline -1` on the repository in question. A claim from before the last commit is a claim about a different tree. |
| **Where** | Where does the artifact live — locally, or on the remote? | `git ls-remote origin <branch>`. A local branch that was never pushed looks identical in your own log. |
| **Why** | Why should this check have caught it? | Name the observation that would be different if the check were removed, then produce it. Declaration is evidence about the document; only a red is evidence about the gate. |

If a claim has no artifact behind it, **that is the finding**, and it is a
bigger one than whatever you were originally checking. Ask for the artifact
rather than a better explanation.

---

## What "done" looks like on your screen

Not a paragraph. A table, as the last thing in the reply:

| Repo | Branch | HEAD | Clean |
|---|---|---|---|
| `PSYourModule` | `main` | `abc1234` | yes |

`PLAN-PROTOCOL.md`'s **Local handoff** rule is what produces it: after the
pushes, every workspace repository is put back on `main`, pulled
fast-forward-only, tags fetched, `git status` clean — and then that table is
printed. "Done" means your editor shows the result with zero commands: inspect
what you expect, with nothing to figure out first.

Two properties of the rule are worth knowing before you rely on it. **A diverged
branch or a dirty tree is reported and never resolved** — the agent tells you
and stops, because silently reconciling either one destroys the evidence of how
it happened. And **a pass that ends without the table is not done**, however
finished the prose above it sounds. That is symptom one in
[`troubleshoot.md`](../../prompts/troubleshoot.md), because it is the most
common and the most misread.

---

## What this chapter cannot promise you

**Your module earns its own numbers.**

Everything measured in this repository was measured against one Azure DevOps
grapher and one Terraform fixture, by one person, on one machine, with the same
model family that wrote the skills. The plugin's demonstrated effect is on
**shape** — first-shot conformance to house conventions — and on behaviour it is
[nearly flat](../../README.md#with-the-plugin-and-without-it), and the README
says so at length under
[Status, honestly](../../README.md#status-honestly). Nobody has yet installed
this cold on a machine that has never cloned the repository.

None of that transfers to your module by being adjacent to it. What transfers is
the flow: a definition of done that existed first, a check proved capable of
failing, two numbers instead of one, and a table at the end saying where
everything actually is. The score your module gets will be a fact about your
module, which is the only reason it is worth having.

---

Next: nothing — this is the last chapter. Back to
[00 — Start here](./00-start-here.md) for the map, or
[10 — Using as a template](./10-using-as-a-template.md) if what you want is not
a module but a method of your own.
