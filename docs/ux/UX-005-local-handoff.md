# UX-005 — The `LOCAL STATE` table: what "done" means

Status: **in force**. The last act of every pass, without exception.

## Problem

**"Done" that requires four commands before you can see it is a different word
from the one the operator asked for.** The reply is confident, the branch is
pushed, the summary is accurate — and the operator's editor shows a stale
branch, a detached HEAD, or a working tree still holding a scratch file from
task six.

Everything the report said is true. None of it is visible. The operator's next
move is to run `git checkout`, `git pull`, `git fetch --tags` and `git status`
across every repository in the workspace, in order to arrive at the state the
word "done" had already implied.

## Why

Because **the agent's idea of done is "the remote is correct" and the
operator's is "my editor shows it".** Those are different states, and the gap
between them is exactly the set of commands nobody ran. The agent has no reason
to notice the gap: from inside the session, pushing *is* finishing.

The gap also hides real problems. A diverged branch, a dirty tree, a repository
that failed to fast-forward — all invisible in a report that talks about what
was pushed, and all surfacing at some later pass's preconditions, sometimes
several passes later.

## What it solves

After remote pushes and `main` fast-forwards, the agent returns the workspace
to inspectable truth: for **every** repository — checkout `main`,
`git pull --ff-only`, `git fetch --tags --prune`, `git status` clean — and then
prints:

| Repo | Branch | HEAD | Clean |
|---|---|---|---|
| … | `main` | `abc1234` | yes |

**"Done" means the operator's editor already shows the result, with zero
commands to run first: inspect what you expect, with nothing to figure out
beforehand.**

**A pass that ends without that table is not done** — not "done but not handed
over". Not done. The table's absence is itself the diagnosis, which is why it
is the first symptom in the troubleshooting guide.

A diverged branch or a dirty tree is **reported, never resolved**. The handoff
is about visibility, and silently fixing something the operator has not seen is
the opposite of that.

## Evidence

- [`PLAN-PROTOCOL.md`](../../PLAN-PROTOCOL.md) — *Local handoff*, the rule, and
  *Sync* immediately above it, which is the same idea at the other end of a
  pass: report any `pass-*` branch whose tip is not an ancestor of its `main`,
  because a stranded branch surfaces at the next pass's preconditions rather
  than at the one that stranded it.
- [`prompts/troubleshoot.md`](../../prompts/troubleshoot.md) — **symptom one**,
  *"The agent says done but I don't see it locally"*, whose answer is that the
  absence of the table is the answer. It is symptom one because it is the most
  common and the most misread.
- [`prompts/first-module.md`](../../prompts/first-module.md) — the kit tells
  the operator to expect the table, and says in the prompt itself that its
  absence means the work is not finished.
- Every pass plan in [`plans/`](../../plans/README.md) since the rule landed
  ends with the table, and this pass's is in
  [`plan.md`](../../plans/0041-operator-ux/plan.md).
