# 5. Calling bullshit — verification

An agent's report is a claim about work you did not watch. It is written by
the thing being graded, in the same session that did the work, and it is
almost always cheerful. This chapter is about not believing it.

That is not a statement about honesty. A session that has genuinely lost
track of what it did will report confidently anyway, because reporting is
what it was asked to do last. The report is downstream of the work; the
remotes are the work. Read the remotes.

> **The rule, in one line.** A number is believed when a command you ran
> produces it, not when a document states it.

---

## Why the report is the wrong artifact

This repository has three recorded cases of a report being right about
everything except the thing that mattered.

- **A remedy recorded as applied that was never applied.** Run 002's finding
  F-3 said of a lint fix: *"Remedy — skill, and it is already applied."* The
  target carried the fix. The skill never did. It was wrong for a pass and a
  half before anyone checked the skill itself.
  ([journal 0017](../../journal/0017-skill-roster.md))
- **A falsification that reported green without ever running.** A probe was
  meant to inject a stylesheet reference into an HTML file and confirm a check
  went red. The substitution was a parse error, so the injection never
  happened, the script ran against an unmodified file, and it printed *all
  checks agree*. The exit code was correct for the file as it actually stood.
  The tell was that the failure list was empty.
  ([evals/HARNESS.md](../../evals/HARNESS.md), hazard 6;
  [journal 0011](../../journal/0011-fixture-design.md))
- **A gate that printed its whole refusal and reported success.** This is from
  the pass that wrote this chapter. `Invoke-Build PublishReal` printed
  `GUARD: refused` and twenty lines of explanation, and then reported *Build
  succeeded. 1 tasks, 0 errors, 0 warnings*, because a script invoked with `&`
  runs in-process and its `exit 1` sets nothing InvokeBuild can see. The
  message was right and the exit code was wrong.
  ([the transcript](../../plans/0031-operators-manual/publishreal-guard.txt))

The shape is the same every time. **An unobserved exit code is a claim.** So
is an unread result file, and so is a remedy written in the past tense.

---

## The director's audit loop

These are the commands. They are paste-able, they are cheap, and they run
against the remote rather than against your own working copy — which is the
point, because your working copy is where the executor was standing.

### 1. Does the branch exist, at the SHA that was claimed?

```bash
git ls-remote https://github.com/<owner>/<repo>.git refs/heads/<branch>
```

`ls-remote` asks the server and touches nothing locally. Compare its answer
to the SHA in the report. A branch that does not exist, or exists at a
different commit, ends the audit here.

### 2. Clone at that commit — not at the branch name

```bash
git -c core.longpaths=true clone -q --branch <branch> <url> scratch/audit
git -C scratch/audit rev-parse HEAD
```

A branch name is a moving target; the claim is about a commit. `rev-parse
HEAD` is how you confirm the tree in front of you is the one being described.
(`core.longpaths=true` is a Windows necessity here — cloning into a deep
scratch path fails as *Filename too long* without it, which
[journal 0028](../../journal/0028-run-006.md) records costing real time.)

### 3. Re-run the scoring yourself

```powershell
./evals/conformance/Invoke-Conformance.ps1 `
    -Path scratch/audit -ModuleName PSAzureDevOpsGraph `
    -Tag @('Universal','Repository','HouseStyle','RequiresBuild') `
    -ResultPath scratch/audit-conformance.json
```

Not "open the committed `result.json` and read it". Run the scorer, in your
clone, now. Use `-Command` rather than `pwsh -File`: `-File` flattens a
comma-separated `-Tag` into a single token and the filter then selects the
wrong set, silently. That bit one pass three times
([LEDGER](../../LEDGER.md), item 15).

### 4. Diff the claimed numbers against the result FILES

Two files, compared field by field: the one you just produced and the one the
run committed. Not the run's prose — the prose is the thing under audit.

### 5. Never believe a fast-forward without asking git

```bash
git merge-base --is-ancestor <claimed-sha> origin/main
echo $?
```

Exit 0 means it really is an ancestor. Exit 1 means it is not — **and also
means the ref did not resolve**, which looks identical. A clone without tags
fetched produces the second while wearing the face of the first
([journal 0019](../../journal/0019-history-unification.md)). Fetch first, then
ask.

---

## Verify scripts: what "re-derive" means

Every full-tier pass here ships a `verify.ps1` beside its plan. Its job is to
let the operator **disprove the plan without reading it**. The rules, from
[PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md):

- **Assume nothing but a fresh clone** and the tools. Never depend on
  `scratch/`, which is not committed and does not exist in a fresh clone.
- **Re-derive rather than read.** Re-run the suite and compare against the
  committed result JSON. Never parse the plan — a script that reads the
  document it is checking has verified the document's internal consistency and
  nothing else.
- **SHA-pinned.** Check out the commit under test, not the branch tip.
- **Exit 0 when everything agrees, non-zero otherwise, printing which check
  disagreed.** A script that only ever prints "all checks agree" has not been
  shown to be capable of printing anything else.
- **`-FailCheck` probes.** A switch that deliberately breaks something and
  asserts the check goes red. This is the verify script falsifying itself.

That last one is not optional decoration. A verify script wrote *all checks
agree* against a file its probe had never touched, and passed a control it
never ran. The fix is that a probe **asserts the break landed** — by hash, or
byte length, or an explicit re-read — *before* the check under test runs. The
guard belongs at the probe, because a check cannot know whether the thing it
is reading was supposed to be different
([evals/HARNESS.md](../../evals/HARNESS.md), hazards 4 and 6).

---

## A worked audit, end to end

The full transcript, every command with its real output, is committed beside
this pass's plan:
**[plans/0031-operators-manual/audit-run-006.txt](../../plans/0031-operators-manual/audit-run-006.txt)**

It audits [run 006](../../runs/006-plugin-on/README.md), the last rung of the
measurement ladder. Here is what it established and — more usefully — what it
did not.

**What agreed.** The remote tip of `run-006-plugin-on` is
`70669167ea5f59a47efb282002052f9e926a34bf`, exactly the `target-sha` the
record claims. A clone at that branch rev-parses to the same SHA. The clone
builds from nothing, exit 0, 95 tests passed, coverage 89.81% against a
declared target of 70%. Re-running the conformance suite against that clone
produced 57/57 tests, `CasesDefined` 33, `CasesRun` 57, `ScorePct` 100 —
field-for-field identical to the run's committed
`conformance-result.json`. Re-scoring the run's committed `graph.json` with
the comparator produced `agree: true` and `differenceCount: 0`.

**What disagreed with an expectation, correctly.** `merge-base --is-ancestor`
returns 1: the run branch is *not* an ancestor of the target's `main`. That is
the right answer. [Decision 0008](../../decisions/0008-target-main-follows-tags.md)
and [decision 0009](../../decisions/0009-agent-moves-both-mains.md) make
measurement branches structurally incapable of reaching `main`, so a
reliability run can never be mistaken for a deliverable. Checking it is how
you tell a deliberate orphan from an accidental one.

**What the audit nearly got wrong, twice.** Both are in the transcript on
purpose.

1. It printed a field called `CasesPassed` and got a blank, because the result
   file has no such field — it has `Passed`, `Failed`, `CasesRun`,
   `CasesDefined`. A blank where a number belongs is the exact shape of a check
   that did not run. The fix was to read the schema, not to squint at the gap.
2. Looking for the functional `12 / 12` in the compare report, it found
   `cases: []` and nearly concluded the claim was unsupported by its artifact.
   It is not. Reading
   [Compare-Graph.ps1](../../evals/functional/Compare-Graph.ps1) settles it:
   that array holds the cases a difference *touched*, so an empty array is what
   twelve of twelve passing looks like. **The score is recorded as an absence.**

   The rule that comes out of it is worth more than the audit: when an artifact
   does not contain the number you expected, read the code that *writes* the
   artifact before concluding the number is missing. An audit that had stopped
   at "cases is empty, so the claim is unsupported" would have manufactured a
   finding out of its own ignorance of the format — which is worse than not
   auditing, because it looks like rigour.

**What the audit could not establish, stated as such.**

- That run 006's session was blind. Freshness is unprovable from outside the
  session; the session identifier shows *separateness*, not freshness. See
  [chapter 4](./04-fresh-sessions-and-contamination.md).
- That its first-shot number is independent. The run's own record says it is
  weakened, because its prompt named the earlier runs' difference mechanisms.
- That Phase 1 took 34 minutes. No artifact carries a clock.

An audit that reported those three as verified would be worth less than one
that says which claims it could not reach.

---

## Re-derive, don't quote — the worked example

"Re-derive rather than read" sounds like fussiness until it changes a number.
Pass 0033 is the case where it did, and it is worth walking because the
quotable number was not wrong by carelessness. It was wrong by *procedure*,
and only re-running it could say so.

Run 007 reported **28 / 33** conformance. That figure is in its record, in
its `conformance-result.json`, and in the README table. Nothing about it
looks suspect: the result file is real, the clone was fresh and SHA-pinned,
and the run's own findings even sort the five failures by name.

The defect was one level below the number. Four assertions read the module's
build output directory, which is gitignored and therefore absent from any
clone that has not been built — and the scoring protocol said "score from a
fresh clone" without ever saying to build it. So those four assertions were
grading the absence of a directory. Re-cloned and **built** before scoring,
the same commit scores **32 / 33**.

Three things about how that was established, each of which is the chapter's
rule doing work:

**The number was re-derived, not re-read.** Both affected runs — 007 and 006
— were re-cloned from their pushed SHAs and re-scored under one procedure.
006 was included precisely because it was *expected not to move*: a re-score
that only touches the number you suspect has told you nothing about whether
the new procedure is sane. It read 33 / 33 both times, and that is the
control.

**The repair was falsified before it was trusted.** A procedure change that
makes a score go up is the most suspicious thing in this book — it is
indistinguishable, from the outside, from quietly weakening the assertions.
So three rows were run
([rescore.txt](../../plans/0033-honest-headline/rescore.txt)): an unbuilt
clone must **still** fail those four (it does, at exactly the 28 / 33 the old
procedure produced); a sabotaged build must fail them (it does); a built
conforming clone must pass (it does, 33 / 33). If the first row had gone
green, the "repair" would have been a cheat. **Making a number go up is not
evidence; making it go up while the control still goes down is.**

**The mechanism was investigated rather than assumed.** The obvious story —
"the ladder runs had the same bug and nobody noticed" — is false, and the
transcripts say so. Each ladder run had build output in its conformance tree
by a *different improvised route*: 004 ran the build inside the conformance
clone, 005 scored a snapshot of an already-built tree, 006 built all three
clones. The written rule permitted all four readings and named none. That is
the actual finding, and it is bigger than the four assertions: **an
unspecified step does not stay unspecified — each run invents it, the
inventions differ, and the scores stop being comparable without any of them
looking wrong.**

The general lesson for an auditor: when two numbers from the same instrument
disagree, the interesting question is rarely "which is right". It is "what
did each of them actually measure", and the only way to answer it is to run
both yourself.

---

## The instrument pin, and a director's mistake caught by this method

Runs 004–006 each assert that the plugin was unchanged from a pinned commit:

```bash
git diff f25d05d..HEAD -- skills/ commands/ .claude-plugin/
```

That is empty, and it is the claim that decides whether the three runs
measured the same instrument at all. But the pass prompt that produced *this
chapter* specified a four-path form with `evals/` included — and that form is
**not** empty, because [pass 0029](../../plans/0029-final-readme/plan.md)
landed 69 lines in `evals/HARNESS.md`.

The [LEDGER](../../LEDGER.md) already records this and prescribes the
three-path form. The prompt did not. Running the audit is what surfaced the
discrepancy, and reporting it rather than quietly using the working form is
what [chapter 6](./06-the-pass-protocol.md) calls the Deviations doctrine.

A verification method that never catches the person who wrote the instructions
is not being run properly.

---

## Checklist

Before you believe a report:

- [ ] `git ls-remote` — the branch exists, at the claimed SHA
- [ ] cloned, and `rev-parse HEAD` matches
- [ ] the scoring re-run **by you**, in that clone
- [ ] your result file diffed against the committed result file, field by field
- [ ] `merge-base --is-ancestor` for any ancestry claim, with tags fetched first
- [ ] every gate's exit code **observed**, not assumed
- [ ] the claims you could *not* verify, written down as unverified
- [ ] for any number that *moved*: the old procedure re-run as a control, and
      an unrelated subject re-measured to show the new procedure does not
      move everything it touches

Next: [6. The pass protocol](./06-the-pass-protocol.md) — how the prompt is
shaped so that there is something to audit in the first place.
