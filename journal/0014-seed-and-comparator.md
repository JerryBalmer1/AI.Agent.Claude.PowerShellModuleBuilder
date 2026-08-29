---
pass: 0014
title: The seed, and the graph comparator
date: 2026-08-29
artifacts:
  - plans/0014-seed-and-comparator/plan.md
  - plans/0014-seed-and-comparator/verify.ps1
  - evals/functional/Compare.Tests.ps1
  - evals/functional/Compare-Graph.ps1
  - evals/functional/Mutate-Graph.ps1
  - evals/functional/Reset-Target.ps1
  - evals/functional/seed/
  - decisions/0004-plan-artifacts-are-frozen.md
  - evals/HARNESS.md
---

# Pass 0014 — The seed, and the graph comparator

## Asked

Two artifacts the baseline run needs and does not have: the exact clean slate a
run starts from, and the tool that scores a produced graph against the declared
one. Write the comparator's acceptance test first, red. Generate the wrong
graphs from `expected-graph.json` rather than authoring them. Falsify the
comparator itself, not only its assertions. Record two decisions from Pass 0013.
Neither the module nor the baseline run happens this pass.

## Done

- `evals/functional/Compare.Tests.ps1` — 28 assertions across the five groups.
- `evals/functional/Mutate-Graph.ps1` — one mutation per case, each derived from
  that case's *How a naive implementation fails* paragraph and carrying the
  sentence it came from. Refuses to emit a mutation that changed nothing.
- `evals/functional/Compare-Graph.ps1` — staged edge matching, JSON report plus
  human summary, exit 0 on agreement.
- `evals/functional/seed/` — `README.md`, `LICENSE`, `.gitignore`,
  `.gitattributes`. Four files, nothing else.
- `evals/functional/Reset-Target.ps1` — materialises the seed into a run
  directory, `git init`, one commit; refuses any destination outside
  `scratch/runs/`.
- `decisions/0004-plan-artifacts-are-frozen.md`, applied to all three verify
  scripts.
- `evals/HARNESS.md` — hazard 8 extended with its diagnostic rule.
- `plans/0014-seed-and-comparator/verify.ps1` — six named spot-checks.

## Why

**Edges are matched in stages, not on a composite key.** Keying an edge on
`(from, to, kind)` makes a repointed edge one missing edge plus one extra edge.
That is true and useless: it says the edge is absent when the edge is present
and pointing at the wrong file, which is a different defect with a different
fix. A wrong resolution target is precisely what cases 01 and 04 exist to catch,
so it has to be nameable on its own. Matching runs exact, then
`(from, kind, ref)` for a wrong target, then `(from, to, ref)` for a wrong kind,
then whatever is left. Rejected: reporting a similarity score per edge, which
would need a threshold nobody can justify.

**Wrong graphs are generated, never authored.** A hand-written wrong graph tests
whether the comparator agrees with the person who wrote it. One generated from
the oracle by a named mutation tests whether it detects the failure the fixture
was built to catch. Rejected: a single generic "corrupt the graph" mutation,
which would prove the comparator notices damage and nothing about whether it
notices *these twelve* failures.

**The exclusion list is data, not omission.** `cases`, `note`, `generatedBy` and
array order are listed in the script with a reason each and echoed into every
report. An exclusion nobody wrote down is indistinguishable from a field
somebody forgot to compare.

**`Reset-Target.ps1` guards on the resolved path, not the string.** A prefix
test on the raw text accepts `scratch/runs/../../../PSAzureDevOpsGraph`. The
accident being prevented is a mistyped path, and a mistyped path does not read
documentation, so the guard is a normalised-path comparison and the real
repository is never a candidate.

## Measured

- **`Compare.Tests.ps1`** red first: 28 total, **1 passed, 27 failed**. The one
  pass was the inputs-unmodified guard, trivially true because nothing had run.
  Green after the comparator: **28/28**.
- **Twelve mutations, twelve detections** — plan.md task 4 table. Every case
  produced differences, exited 1, and named itself and nothing else. Difference
  counts 1 to 4; kinds as declared per case.
- **`Fixture.Tests.ps1` 352**, **`ReadBack.Tests.ps1` 76**, both green,
  unchanged by this pass.
- **Seed**: 4 files, 0 CR bytes. `Reset-Target` copies 4, commits 4.
- **`verify.ps1`**: 6 checks, all agreeing, exit 0; 1 skipped without
  `AZDO_PAT`, still exit 0.
- **Oracle unmodified**: `expected-graph.json` blob
  `bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc` at pass start and at end.
- Fixture YAML: 0 files changed.

## Learned

**The prompt's Pass 0013 claim about the PAT scan was wrong, and the prompt says
so.** The operator's Pass 0013 prompt asserted that the committed scan could not
match an 84-character token and would therefore report clean. It was asserted
from memory; the pattern `[A-Za-z0-9]{52}` is unanchored, so a 52-character
window inside an 84-character run matches, and Pass 0013's measurement showed
the scan would have caught the real value. That is rule 8 — observed versus
inferred — broken in a prompt about a check unable to fail. Recorded here
attributed to the prompt rather than to the pass: the pass measured it and
reported it, which is the behaviour the rule asks for.

**A case-naming scheme built on tags structurally cannot name an absence case.**
Nothing in `expected-graph.json` can carry case-12's tag, because tagging a node
with it would assert the opposite of the case. So the tag lookup that names
every presence case has nothing to find, and no amount of care with the tags
fixes it. The comparator carries an explicit `$AbsenceCaseRules` table for that
one reason. This was not visible until something had to *name* the case rather
than merely check it.

**Two cases have a naive failure that no graph mutation can express.** Case-08's
first failure mode is a hang or a stack overflow, which produces no graph at
all; only its second mode — dropping the edge that closes the cycle — is
comparator-visible. Case-03 and case-11 each have a second failure mode (an
invented edge) that their single mutation does not cover. Findings about the
cases' discriminating power, in Deviations.

**A falsification probe caught a break the targeted assertion was not aimed at.**
Breaking the comparator to ignore edge targets turned assertion 4 red, as
designed — and also turned case-01 and case-08 red in assertion 2, because those
are the two whose mutation is a repointed edge. The per-case assertions turned
out to be a second, independent detector of the same defect.

**Editing an earlier pass's pinned number was the wrong instinct.** Pass 0013
edited `plans/0012`'s case count from 346 to 352 to stop it going red. That
makes the number mean less each time and the work grow without bound. Decision
0004 freezes plan artifacts instead.

## Capability

A produced graph can now be scored against the declared one automatically, with
a report that names which of the twelve declared cases it failed rather than
only that it differs — and the scoring is itself falsifiable, because a wrong
graph for every case can be generated on demand from the oracle. A baseline run
can now be started from an exact, reproducible clean slate and rebuilt after a
wipe with one command. Before this pass, both halves of "run the module and see
how it did" were missing: nothing defined where a run starts, and nothing could
say how far its answer was from the right one.
