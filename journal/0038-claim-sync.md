---
pass: 0038
title: The measurement history reaches the repositories it measured
date: 2026-09-02
artifacts:
  - plans/0038-claim-sync/plan.md
  - plans/0038-claim-sync/accept.Tests.ps1
  - plans/0038-claim-sync/accept-red.txt
  - plans/0038-claim-sync/accept-green.txt
  - plans/0038-claim-sync/mains-after.txt
  - LEDGER.md
---

# Pass 0038 — The measurement history reaches the repositories it measured

## Asked

Carry the harness's measurement history out to the four sibling repositories
the measurements were about, with every claim bounded exactly as the harness
bounds it and every number linking its artifact. Rewrite PSAzureDevOpsGraph's
README around the ladder, the control and the corrected scoring caveat, give it
the `docs/HANDOFF.md` decision 0010 has always required, and tag `v0.3.0`.
Bring PSTerraformGraph's README and HANDOFF up to tf-003 without letting the
claim grow. One-line consumer-row currency commits on the two renderer
repositories. Move every sibling `main`. No module code, no `evals/`, no plugin
surface, no harness tag, and no Azure DevOps contact at all.

## Done

- Branch `pass-0038-claim-sync`; acceptance test committed as supplied and run
  red — 6 of 7, with the seventh recorded as green against a working tree and
  red against every published `main`.
- **PSAzureDevOpsGraph `v0.3.0`**, annotated and pushed, `main` fast-forwarded.
  `Status` — three numbers from run 002 — became `How this module was measured`:
  the two lines, run 002 labelled as not a baseline, the 004–006 ladder, the 007
  control with its mechanism breakdown, the sentence the control forced, three
  bounds, and a link per run record. New HANDOFF, new worklog, module byte-
  identical to `v0.2.0` and the diff quoted to prove it.
- **PSTerraformGraph**, no tag, `main` fast-forwarded. The two measurements are
  now separated rather than blended, and the two false clauses are gone.
- **PSGraphRenderToHtml** and **PSGraphRender**, a row each, both mains
  fast-forwarded — and both carrying a pass-0024 commit that had been stranded
  on a pushed branch since.
- One defect repaired in the commit that was carried: a split table.
- LEDGER, backlog 43 and 44, this entry, the plan. Acceptance green 7 of 7.

## Why

**Run 002's 12/12 was the claim most in need of moving down, and it moved by
gaining a caveat that already existed.** The run's own record has carried a
standing block-quote since it was written — not a zero-skill baseline, the
plugin was seeded, the builder read the case list as a specification. The README
quoted the number and left the block-quote behind. Nothing had to be re-argued
to fix that; the bound was already written, in the artifact the README was
citing. That is the cheapest kind of correction there is and it had gone unmade
for five runs.

**The two-lines rule earned its place by being violated in the install
instructions.** The new section explains that `run-*` branches are orphan roots,
never merged and never tagged, and that they are not releases. Forty lines above
it, `Install` said `git clone --branch run-002-first-build`. Shipping the
explanation over the violation would have been worse than shipping neither.

**PSTerraformGraph got a distinction the prompt did not ask for, because the
number would have been a lie without it.** tf-003 scored **6/7 → 7/7** on an
unseen fixture, and it is tempting to write that into the producer's README as
the producer's result. It is not: tf-003 built a module from the four-file seed
in an orphan branch and *"the existing PSTerraformGraph implementation was never
read, in either phase"*. The shipped code on `main` still has exactly what
tf-002 gave it — 0 differences on a **visible** oracle. So both files say which
measurement is about which artifact, and the HANDOFF's replacement bullets say
it twice, because the honest version is the one a hurried reader will otherwise
get wrong in the flattering direction.

**Branching the consumers from the stranded tips rather than from `main` was
the call worth thinking about.** The alternative — branch from `main`, write the
tf-002 currency line from scratch, fast-forward — is what the prompt literally
describes, and it would have left two pushed commits permanently unreachable
from `main` while this pass re-derived one of them. Carrying them was checked to
be fast-forward-legal in both repositories before either push, so nothing was
rewritten and nothing was forced. The cost is that this pass's main moves ship
another pass's work, which is stated in the plan rather than absorbed.

**The split table was repaired rather than reported.** Deviating far enough to
carry a commit and then leaving a defect in it would be carrying the commit
without taking responsibility for it. The repair is a reordering with no wording
changed, on top of the original rather than rewriting it.

## Measured

| | |
|---|---|
| acceptance | red **1 of 7 passing** → green **7 of 7** ([accept-red.txt](../plans/0038-claim-sync/accept-red.txt), [accept-green.txt](../plans/0038-claim-sync/accept-green.txt)) |
| spot-check 1 | `git diff v0.2.0..v0.3.0` — 3 files, 464 insertions, 16 deletions, all docs; code paths `IDENTICAL`, exit 0 |
| spot-check 2 | 14 figure groups in the new README re-derived from the run records they link; **all match** |
| spot-check 3 | four sibling mains re-read from the remotes; `v0.3.0^{}` and `refs/heads/main` the same commit ([mains-after.txt](../plans/0038-claim-sync/mains-after.txt)) |
| mains moved | `5fd814b..fdf4a27`, `1dd4913..80fc6bb`, `2231b4b..a4c18c0`, `20877f7..ac76bc4` — every one fast-forward, ancestry gated |
| stranded commits recovered | **2** (`da89d05`, `7caf364`), pushed since pass 0024 and never on a main |
| builds, suites, scores | **none.** No number was earned or re-earned |
| AzDO contact | **zero** |

## Learned

- **A measured result stales documents in repositories the measuring pass is
  forbidden to touch, and nothing was writing down which.** The two-lines rule
  is right — a run being scored must not be editing deliverable-line documents
  in the same session — but it has a consequence nobody had recorded: the
  staling is invisible until someone reads a sibling README a year later and
  finds it quoting run 002. Five runs accumulated that way. **Backlog 43** is
  the cheap fix and it is deliberately not "fix it in the same pass": one
  LEDGER line per measured result, naming what it just made false.
- **Two mains had been a commit behind since pass 0024 and no artifact in this
  project could have told anyone.** Decisions 0009 and 0010 both say the agent
  moves the mains at the end of a green pass. Neither says anything checks. The
  gap was found by tripping over it — an acceptance assertion went green for
  the wrong reason — rather than by any gate. **Backlog 44.** The check is one
  command, `git branch --no-merged main`, and its absence hid two commits for
  fourteen passes.
- **An acceptance assertion that reads a working tree is asserting about a
  checkout, not about a repository.** Six of these seven read files, and the
  files they read are whatever branch happens to be out. That is hazard 8's
  shape again — *an assertion about a declaration is not an assertion about the
  thing declared* — arriving through `git checkout` rather than through prose.
  The same assertions phrased against `main:README.md` would have been red at
  start in all seven, which is what the pass actually wanted to know. Worth
  fixing in whatever writes the next cross-repo acceptance test.
- **The strongest available sentence and the honest one differed on
  PSTerraformGraph, and the difference was one word: "it".** *"It scored 6/7 on
  an unseen fixture"* is false about the shipped module and true about a module
  built fresh in an orphan branch. Nothing in the numbers signals which reading
  is meant. Only the run record's own sentence about never reading the
  implementation does, and it is one line deep in a long document.
- **A carried commit is a commit you are now responsible for.** Branching from
  `pass-0024-consumer-ref` meant reading it, and reading it found a table split
  in two with a row stranded below eight paragraphs of prose. Had the pass
  branched from `main` as written, the defect would have stayed on a branch
  nobody reads — which is a worse outcome that would have looked tidier.
