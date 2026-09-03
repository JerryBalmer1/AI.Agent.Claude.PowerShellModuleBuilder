# UX-004 — Heartbeats: `[n/N] <task> — <estimate>`

Status: **in force**. Printed at every task boundary during a pass.

## Problem

**A long silent run is indistinguishable from a hung one.** A full-tier pass
can spend twenty minutes with nothing appearing on screen: cloning, building,
rendering, running a suite. From the outside, a session that is working and a
session that is stuck look the same — nothing.

The operator's only options are to wait longer or to interrupt. Both are
guesses, and interrupting a pass mid-task is how a working tree ends up in a
state nobody planned.

## Why

Because **progress is information the session has and the operator does not.**
The agent knows how many tasks there are, which one it is on, and roughly what
that one costs. None of that reaches the terminal unless it is deliberately
printed — and the natural thing to print, the output of whatever is running, is
silent for exactly the long steps where silence is worst.

This is not the same problem a progress bar solves. The question is not "how
far along" but "is this still moving, and is it moving through the thing I
approved". A boundary marker answers both. A spinner answers neither.

## What it solves

At every task boundary the session prints one line:

    [n/N] <task> — <estimate>

`n` of `N` gives silence a shape: the operator can tell a slow task from a
stuck one, and can see that the pass is working through the plan they agreed to
rather than something else.

**Heartbeats carry no scores on measurement lines.** A progress line that names
a run's score leaks oracle knowledge into every future session that reads the
log, which is hazard 11's whole point. A heartbeat says what is being done,
never what it came out as.

It does not replace the report, and an estimate is an estimate — a heartbeat
that promises two minutes and takes ten is still a heartbeat that told the
operator which task was slow.

## Evidence

- [`PLAN-PROTOCOL.md`](../../PLAN-PROTOCOL.md) — *The report contract*, where
  the heartbeat rule sits alongside `YOUR NEXT ACTION`, because they are the
  same concern at two timescales: during, and after.
- **Pass 0041 is the first pass to print them**, and the record is this pass's
  own transcript in [`plan.md`](../../plans/0041-operator-ux/plan.md). Stated
  as first use, not as a measured improvement — nothing here has measured one,
  and a UX record that claims an effect it did not measure is the decoration
  this registry exists to catch.
- The no-scores clause comes from **[LEDGER item 14](../../LEDGER.md)** and
  hazard 11 in [`evals/HARNESS.md`](../../evals/HARNESS.md): run-record commit
  subjects leaked scores into every future session via `git log` at
  preconditions. A heartbeat is a commit subject that has not been committed
  yet, and the same rule applies for the same reason.
