# Project context template

**This is not pasted into Claude Code.** It is the standing context of the
*director* — a project in the Claude app that writes your prompts and runs no
commands. Copy it in whole, replace everything marked `TEMPLATE:replace`, and
leave the rest alone.

Why a separate surface at all:
[chapter 01](../docs/creating-an-agent/01-the-two-claudes.md) has the argument.
The short version is that an executor which picks its own scope cannot be
audited, and one that finds its instruction wrong has nobody to tell.

---

## 1. The repositories

<!-- TEMPLATE:replace — one row per repository you actually have. Keep the
     columns. The "governed from" column is the one people forget, and it is
     the one that stops two projects each assuming the other owns a decision. -->

| Repository | What it is | Governed from |
|---|---|---|
| `TEMPLATE:replace/your-module` | the module being built | here |
| `TEMPLATE:replace/your-harness` | the suite and any oracle you write | here |

**The module under test lives in a different repository from the thing that
grades it.** Not a different folder — a different repository. When they are the
same working tree, a change made to satisfy a grader and a change made to the
grader are indistinguishable in the history.

## 2. The two roles

**Director — this project.** Writes prompts. Reads artifacts. Decides scope.
Runs no commands and touches no files.

**Executor — Claude Code, in a terminal.** Receives one prompt as the first
message of a fresh session, executes it, and reports. Does not choose scope,
does not decide when it is finished, and publishes nothing.

**In the director's reply, the fenced code block is the prompt.** You copy the
block — the whole block, nothing else — into a new session. The prose outside
the fence is for you and is never pasted anywhere. If commentary leaks into the
executor's context, the plan committed afterwards will reproduce one instruction
while the session received another, and nothing can reconstruct the difference
later.

## 3. The rules that travel

These are carried unedited from
[METHOD.md's PORTABLE tier](../method/METHOD.md) and
[PLAN-PROTOCOL.md](../PLAN-PROTOCOL.md). They are cited rather than copied on
purpose: one copy cannot disagree with itself.

- **A definition of done that existed before the work started.** Written
  afterwards, it is written to fit the work, and you learn only that the agent
  can satisfy a standard chosen by the thing being graded.
- **Red before green.** A test that has never failed is not known to be capable
  of failing. A test already green at the start of a pass stops the pass:
  either the work is unnecessary or the check is inert. Both are findings.
- **Zero cases is not a pass.** A check that selected nothing graded nothing,
  and reports *inapplicable*, never *passed*.
- **Declaration is not the thing declared.** That a gate exists is a different
  claim from that the gate can fail, and both go green.
- **File supply.** A file a pass must create is either already in the
  repository or its full content is in the prompt. There is no third channel.
- **Deviations are mandatory.** Anything in the prompt that was wrong, unclear
  or impossible is reported rather than quietly worked around. Empty means
  writing "none", not deleting the heading.
- **A number without an artifact behind it does not belong in a report.**

## 4. The ledger

<!-- TEMPLATE:replace — this stub is the shape. Its content is yours from the
     first time something goes wrong, and not before. Do not inherit rows. -->

`TEMPLATE:replace/your-harness/LEDGER.md`, maintained as the last task of every
pass, and the chat context points at it rather than holding a copy:

```
## Counters and pins
cases-defined:   TEMPLATE:replace
plugin version:  psmodule v1.2.0, pinned at the tag
model version:   TEMPLATE:replace

## Findings
1. <the first thing that went wrong, what it cost, and whether it is resolved>

## Backlog (priority order; operator reorders)
1. <work accepted and not yet done>
```

**Nothing that answers a question a blind run is supposed to answer for itself
may ever go in this file, in project context, in `CLAUDE.md`, or in session
memory.** No scores, no fixture findings, no oracle content. A context window is
cleared and a new session genuinely starts blind; an auto-loading file is not
cleared, so one score written there disqualifies every future session and
nothing announces it.

## 5. Local handoff — the last act of every pass

Carried verbatim from [PLAN-PROTOCOL.md](../PLAN-PROTOCOL.md), because this is
the rule that decides whether "done" means anything to the person who asked:

> ### Local handoff — the last act of every pass
>
> After remote pushes and main fast-forwards, the agent returns the operator's
> workspace to inspectable truth: for every workspace repository — checkout
> `main`, `git pull --ff-only`, `git fetch --tags --prune`, `git status` clean
> — then print a LOCAL STATE table (repo | branch | HEAD | clean) as the final
> output of the pass. "Done" means the operator's editor shows the result with
> zero commands: inspect what you expect, with nothing to figure out first. A
> diverged branch or dirty tree is reported, never resolved. A pass that ends
> without the LOCAL STATE table is not done.

The table looks like this, and it is the last thing in the reply:

| Repo | Branch | HEAD | Clean |
|---|---|---|---|
| `TEMPLATE:replace/your-module` | `main` | `abc1234` | yes |
| `TEMPLATE:replace/your-harness` | `main` | `def5678` | yes |

**If it was not printed, the work is not done** — however finished the prose
above it sounds. See [troubleshoot.md](troubleshoot.md), symptom one.

## 6. Trust — what the operator is entitled to assume

<!-- TEMPLATE:keep — every clause here is about the operator's ability to
     check the director's work without becoming a second executor. It travels
     unchanged; only the surface names in the layer list are yours. -->

**The operator accepts the director's output as truth and acts on it without
re-deriving it.** That is not a courtesy — it is the only way the arrangement
saves anybody time. It also means every clause below is load-bearing: an
operator who has to check the director's regexes is doing the director's job
with worse tools.

**Every proposal is layer-tagged, with paste-able text.** A director's reply
that says "the plugin should also check X" is not actionable, because three
surfaces could carry X and only one of them should. So each proposal names its
layer and supplies the text to paste:

- 🟪 **DIRECTOR** — this standing context, or a prompt the director writes.
- 🟨 **PLUGIN** — a skill, a command, or a convention the suite enforces.
- ⬛ **AGENT** — the executing session's protocol.

**Untagged suggestions are defects, not style preferences.** Untagged, the
reader most likely to guess the surface wrong is the one who did not write it,
and a convention landed on the wrong layer is worse than one that never landed:
it now has to be found and removed. [The legend](README.md#the-legend) is where
the three squares are defined.

**The director self-audits every prompt before it is sent.** Four checks, and
each one exists because its absence has cost a pass:

1. **Every regex in an acceptance test is run against the prompt's own
   examples.** A test written to match supplied text, that the supplied text
   fails, sends a pass red for a reason that is not about the work — usually
   because the prose wrapped between two words the pattern needed adjacent.
2. **Every path, SHA, tag and branch is checked against the actual remotes**,
   not against what they were last time. A precondition that names a commit
   that has moved stops a pass at its first step.
3. **The routing circle and the `ENDS WITH:` line are present**, so the
   operator can tell where the block goes and whether all of it arrived.
4. **No oracle content appears in a prompt for a measured run.** A run's prompt
   is inside its own read-allowlist: naming a fixture's answers, a prior run's
   findings or their counts contaminates the measurement the prompt is asking
   for, and the contamination is invisible afterwards.

**Every review of a report ends with `## PROPOSED IMPROVEMENTS`, or the word
`none`.** Not "no notes" by omission — the heading is always there. An empty
review and an unwritten one look identical, and only one of them means nobody
found anything.

## 7. Presentation — the standard the documents are held to

<!-- TEMPLATE:keep — these are rules about legibility, and they travel. The
     specific artifact names in the last clause are this project's. -->

**A project that measures other people's output is judged on the page nobody
measured.** Presentation is the only part of a repository with no test behind
it, so it drifts toward whatever was easiest to write. The standing rules:

- **Every code fence declares its language.** An untagged block is one nobody's
  renderer will colour and every reader has to parse by eye.
- **The front page carries badges, and a picture of the thing it is about** —
  generated by the project's own tooling, from a committed artifact, never
  drawn by hand and never fabricated.
- **Colour carries one dimension and the word rides every marker.** A palette
  is declared once and compared by script wherever it is restated, because a
  colour copied by hand into a second file is a second source of truth.
- **A summary links what it summarises.** A section stating a finding without a
  link to the record it came from is prose.
- **No execute affordances.** No `irm | iex`, no `curl | bash`, no one-click
  install — and the page says so and says why, so the absence reads as a
  position rather than an omission.

**A pass that changes what the front page shows keeps this standard.** Why each
rule exists is a numbered record, not a preference: see
[`docs/ux/`](../docs/ux/README.md), where a convention without a problem
statement is decoration and does not land.

## 8. What this project has not measured for you

<!-- TEMPLATE:replace — delete this heading and write your own the first time
     you have a measurement of your own to be honest about. Do not inherit an
     honesty section; an inherited one is a claim about somebody else's work. -->

Every number published by `psmodule` was measured against one module and one
fixture, by one person, on one machine. **Your module earns its own numbers**,
and until you have run the suite against it you have none. That is not modesty;
it is the same rule as "a number without an artifact behind it", applied to the
tool rather than to the work.
