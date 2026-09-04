# 0046 — runner exclusion regex repair

## Asked

Repair backlog 62: `evals/conformance/Invoke-Conformance.ps1:122` writes the
path-exclusion character class as `[\/]` where the three copies in the
conformance suite write `[\\/]`. Inside a class that is an escaped forward
slash and nothing else, so the runner's exclusion of
`output|scratch|.git|gallery|fixtures|node_modules` had never fired on a
Windows path — and every path it tests is a Windows path.

Not the one character on its own. The prompt asked for the repair **plus the
tests whose absence let four copies of one regex drift**, both defect
directions observed red before any repair, and a binding series guard:
`cases-defined` does not move, and nothing this pass adds may enter the
conformance runner's inventory.

## Done

Branch `pass-0046-runner-regex`, five commits, harness only.

- `evals/conformance/Invoke-Conformance.ps1:122` — `[\/]` → `[\\/]`. One
  file, one line, `+1/-1`. All four copies of the regex are now one
  byte-identical string, counted with `uniq -c` rather than eyeballed.
- `evals/harness/ExclusionPattern.Tests.ps1` — 93 cases in two Describes:
  a polarity pair over every discovered site, and a copies-agree check.
- `evals/harness/ExclusionSites.ps1` — the extractor both Pester scopes
  share.
- `evals/harness/Invoke-HarnessTests.ps1` — the named command that runs
  them, with per-Describe `Passed=`/`Failed=` lines.
- `plans/0046-runner-regex/accept.ps1` — committed before the repair;
  `accept-red.txt` (exit 6), `accept-green.txt` (exit 0),
  `accept-red-first-attempt.txt` (a crash of my own making, kept).
- `plans/0046-runner-regex/verify.ps1` — six checks, five probes; exit 0
  plain and exit 0 under `-FailCheck`. `verify-run.txt`,
  `verify-failcheck.txt`.
- `plans/0046-runner-regex/probe-{a,b,c}-*.txt` — the three
  red-capability runs.
- `plans/0046-runner-regex/plan.md`, `LEDGER.md`, this file.

No tag. The pass changed no installed file: `git diff <pass base>..HEAD --
skills/ commands/ .claude-plugin/` is empty.

## Why

**Why the tests are the larger half.** Backlog 62's own last sentence says a
one-character fix with no test is how the divergence arose. Four copies of
one regex existed and one was wrong, and nothing compared them, so nothing
noticed. The repair without the comparison would leave the next drift exactly
as invisible.

**Why `evals/harness/` and not `evals/conformance/`.** Derived from the
runner's own code before anything was placed, not chosen by taste:
`Invoke-Conformance.ps1` discovers `*.Tests.ps1` in its own directory with no
`-Recurse`, and that count is `CasesDefined`, the denominator every
conformance score is reported against. A file beside the suite would move it.
`-Tag 'Harness'` is a second, independent backstop — the runner's `-Tag`
`ValidateSet` does not accept it — but placement is the guard and the tag is
only the belt, and `verify.ps1 -FailCheck` measures the difference.

**Why the sites are discovered rather than listed, and by content rather than
by character class.** A hard-coded list of three filenames would have to be
remembered, and remembering is what failed here. Searching for the *correct*
spelling would be worse still: a drifted copy would not match the search and
would be reported as no copy at all, which is a false negative in the check
whose entire job is to find drift.

**Rejected: pinning `CasesDefined`.** `verify.ps1` measures it at the pass
base and at head and compares the two, materialising the base conformance
directory under `scratch/` with `git show` per file. A count measured in one
tree and asserted in another reports the tree's shape rather than the pass's
claim — 0045's lesson, applied.

**Rejected: a merge-base against `origin/main` for the pass base.** It
collapses to HEAD once the pass lands, and would then compare nothing while
reporting green. The base is the parent of the commit that introduced the
plan directory, found from the history.

**Rejected: repairing backlog 63 in this pass.** The stale `cases-defined`
pin carries a series boundary — which scores may be compared with which — and
moving it is a claim, not a typo fix. It wants its own red-first iteration.

## Measured

Every figure from an artifact, all committed under `plans/0046-runner-regex/`.

| | red-first (`accept-red.txt`) | green (`accept-green.txt`) |
|---|---|---|
| exit | 6 | 0 |
| runner excludes `\output\…` | False | True |
| runner excludes `\scratch\Fake\Fake.psd1` | False | True |
| suite excludes both | True | True |
| runner candidate set | **4** | **2** |
| suite candidate set | 2 | 2 |
| runner resolves the target unaided | no — refused | yes |
| `CasesDefined`, per-target | 36 | 36 |
| `CasesDefined`, all four tags | 42 | 42 |
| `CasesRun` | 161 | 161 |
| Passed / Failed / ScorePct | 105 / 56 / 65.22 | 105 / 56 / 65.22 |
| inventoried containers | 2 | 2 |

Harness tests, `harness-tests-green.txt`: `Passed=93 Failed=0 Ran=93
BrokenContainers=0`, exit 0.

Red-capability, three probes:

| probe | broken how | result |
|---|---|---|
| A | pre-repair `[\/]` restored | exit 1 — 12 polarity red, 1 copies-agree red |
| B | one site → `[/\\]`, semantically identical | exit 1 — 1 copies-agree red, **0 polarity red** |
| C | separators dropped | exit 1 — 4 scope controls red, 18 exclusion cases green |

`verify.ps1` exit 0; `verify.ps1 -FailCheck` exit 0 with every probe firing,
including `P4a: CasesDefined 36 -> 37` and `P4b: the conformance runner then
reports no score at all`.

## Learned

**The prompt's green criterion described the wrong outcome, and the right one
is better.** It asked that the runner "derives `-ModuleName` cleanly". A
repaired runner derives nothing: one candidate is named for the target, so
`$suiteCanDecide` is true, the whole `src/`-rule block never executes, and the
*suite* resolves the target unaided — which is what its own comment block says
that rule is a last resort for. Asserting "does not refuse" rather than
"derives" is the difference between grading the behaviour and grading a
sentence about it.

**The refusal message names neither plant.** Backlog 62 and the prompt both
compress a two-link chain into one: the `output/` manifest makes
`$suiteCanDecide` false, and the refusal that follows is about two manifests
under `src/`, one of them a vendored templateset file that is not a defect and
is only ever reached because link 1 put the runner there. Right about the
cause, wrong about the text — and a reader checking the prompt against the
transcript would have thought the wrong thing had been reproduced.

**A probe that reports "does not fire" is more likely to be wrong than the
thing it is probing.** The first `-FailCheck` run said "0 polarity case(s)
red" and "0 agreement case(s) red" while the suite was plainly 13 red. The
probe was scraping Pester's output, where a failure line carries the test name
and not the block it belongs to. That is the exact false signal the
falsification protocol exists to detect, manufactured by its own bookkeeping,
and it failed toward the alarming answer. The fix went into the product rather
than the probe: `Invoke-HarnessTests.ps1` now prints a machine-readable line
per Describe.

**Three `sed -i` invocations reported success and changed no bytes.** Doubled
backslashes were being collapsed before `sed` saw them, so the pattern matched
nothing. A substitution that silently matches nothing is the same failure
shape as a falsification break that silently matches nothing — exit 0, no
output, read as done. The repair was made with a precise edit and the diff was
read before committing, and every probe in this pass asserts that it actually
changed its target before running anything.

**The scope controls are what caught the interesting case.** Probe C dropped
the separators from the pattern, leaving the bare alternation. All eighteen
exclusion cases for that site stayed green; four near-miss segment names went
red. A test suite with only the exclusion half would have passed a pattern
that excludes `outputs`, `scratchpad` and `myoutput` — matching too much,
which is the failure a positive assertion cannot detect on its own.

**Two prompt premises disagreed with the repository, and both were already
written down.** SC3's `v1.2.0..HEAD` diff is not empty and has not been since
pass 0041 — that is backlog 56, recorded on purpose, and this is the third
consecutive prompt to carry the stale form of that pin. Backlog 62's own count
of "three copies" is four. Neither was a discovery; both were in the file the
prompt was derived from.

**What went wrong that was mine.** The first acceptance run crashed at exit 99
because I measured the "global" denominator by running the conformance runner
against the harness repository itself, which holds no module to resolve. Both
reds had already been observed in that run and are unchanged, and the
transcript is kept rather than discarded. The global figure now comes from
asking the runner for all four tags against the same clone, rather than from a
second implementation of the inventory that could disagree with the first.

**Something appeared that the pass did not put there.** An untracked
`PSGraphRender.code-workspace` at the harness root, mid-pass, registering a
sibling repository as a folder. Nothing this pass ran writes one. It has been
left exactly where it is and reported: PLAN-PROTOCOL's rule for an unrelated
dirty file is written for the state a pass *finds*, and a file that arrives
while the pass is running may still be in flight. Committing it would be a
decision that is not the pass's to make.

## Capability

The harness can now grade itself. `evals/harness/` is a place for tests whose
subject is the instrument rather than any target, with a runner of its own and
a demonstrated guarantee that nothing in it can reach the conformance
denominator — the guarantee measured in both directions, not asserted.

The specific thing that is now possible and was not: **any of the four copies
of the path-exclusion regex being edited alone fails loudly**, and it fails
whether the edit changes behaviour or not. Probe B is the proof — a respelling
that means exactly the same thing still turns the check red. Before this pass
the four copies could disagree indefinitely, and one of them had.

Also newly possible, and cheaply: adding a seventh excluded segment to the
pattern extends its test coverage automatically. The segments are read out of
the alternation rather than retyped, so a new one arrives graded rather than
arriving ungraded and looking graded.
