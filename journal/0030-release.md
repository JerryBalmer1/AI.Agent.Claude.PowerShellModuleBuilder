---
pass: 0030
title: Packaging, adoption boilerplate, and the first release tag
date: 2026-09-02
artifacts:
  - .claude-plugin/marketplace.json
  - .claude-plugin/plugin.json
  - decisions/0013-harness-release-tagging.md
  - SECURITY.md
  - CHANGELOG.md
  - LICENSE
  - README.md
  - tools/publish/Test-Prerequisites.ps1
  - tools/publish/Publish-Local.ps1
  - tools/publish/Publish-Real.ps1
  - evals/tf/Compare-TfGraph.Tests.ps1
  - PLAN-PROTOCOL.md
  - method/METHOD.md
  - docs/creating-an-agent/09-try-before-you-trust.md
  - LEDGER.md
  - plans/0030-release/plan.md
  - plans/0030-release/verify.ps1
  - plans/0030-release/accept.Tests.ps1
  - plans/0030-release/mutations.txt
  - plans/0030-release/packaging.txt
  - plans/0030-release/marketplace-falsification.txt
  - plans/0030-release/hostile-first-run.txt
---

# Pass 0030 — Packaging, adoption boilerplate, and the first release tag

## Asked

Make the repository installable by somebody else, and tag it v1.0.0. Repair two
known defects first: backlog 20, a red test committed on `main`, and backlog 22,
a false clause in `PLAN-PROTOCOL.md`'s own worked example; reconcile the LEDGER's
backlog numbering without renumbering anything. Write decision 0013 giving the
harness release tags. Commit a `marketplace.json` and re-version the manifest to
1.0.0. Write the adoption boilerplate — `SECURITY.md`, `CHANGELOG.md`, `LICENSE`,
a README support section and a versioning promise. Write a prerequisite checker
and falsify all five of its checks. Put the three install commands at the top of
the README. Update the docs the pass changes, in the same pass.

## Done

- **Repair.** `Compare-TfGraph.Tests.ps1` line 41: `57` → `59`, hard-coded with
  a comment citing decision 0012. `PLAN-PROTOCOL.md`'s tier example rewritten
  around what plan 0012 §3 records. `LEDGER.md` gained a numbering
  reconciliation.
- **Decision 0013** — `decisions/0013-harness-release-tagging.md`, 114 lines.
- **Packaging.** `.claude-plugin/marketplace.json` (marketplace
  `psmodule-builder`, one `psmodule` entry, `./` source, pinned metadata);
  `plugin.json` 0.1.0 → 1.0.0. `Publish-Local.ps1` gained
  `Test-CommittedMarketplace`; `Publish-Real.ps1`'s checklist steps 4 and 5
  corrected to match decision 0013.
- **Adoption.** `SECURITY.md`, `CHANGELOG.md` and `LICENSE` written; README
  gained `## Install`, `## Versioning` and `## Support`.
- **`tools/publish/Test-Prerequisites.ps1`** — five checks, one named line per
  failure, no `#Requires` line.
- **Docs.** Chapter 09's *Before you start* and *PublishReal* sections;
  `method/METHOD.md`'s PORTABLE publishing rail carries decision 0013's
  amendment inline.
- **`v1.0.0`**, annotated, pushed — the repository's first tag of any kind.

## Why

**The stale edge count was hard-coded rather than derived, and that is the
opposite of the instinct.** Deriving `ExpectedEdgeCount` from the oracle file
would have made the assertion self-maintaining and would never go stale again.
It would also have made it worthless: the fixture is frozen under decision 0011,
and a count read out of the oracle agrees with the oracle whatever the oracle
becomes. The written-down number is a tripwire on the freeze. Staleness is the
price of the tripwire, and the tripwire is what was being bought.

**The 57 → 59 change is indistinguishable from assertion-weakening on the
diff.** Both look like editing a failing number until it passes. Nothing in the
change itself separates them, so the seven mutations were re-run and
`DETECTED: 7 / 7` captured. The claim "this is repair" is only worth what the
re-run is worth.

**Pass 0012 was a near miss, not a casualty, and that is the better example.**
The false clause said the pass shipped untested. It did not — plan 0012 §3
records the red-first run. But the artifacts existed because the *prompt*
required them, not because the tier label did; the label said light, and light
says "no acceptance test and no verify script" in terms. The corrected example
teaches the same rule with sharper evidence: the guard that saved pass 0012 was
an accident of prompt authorship.

**v1.0.0 was not held for the missing baseline control.** Backlog 17 — a second
plugin-off run permitted to iterate — is the highest-value run remaining, and
waiting for it was seriously considered. Rejected: it would hold the release
indefinitely for a measurement that improves the *table*, not the artifact. The
gap is disclosed in the README, the CHANGELOG and the tag message itself.
Shipping with a stated gap is honest; waiting silently helps nobody.

**The marketplace pin to a tag is the whole reason the decision exists.**
Without it, every merge to `main` would be a silent release to everyone who had
ever added the marketplace, and the README's honest-status section would be
describing a tree that had already moved.

**The prerequisite checker has no `#Requires` line, alone among the scripts
here.** A checker that refuses to start when a prerequisite is missing fails
exactly when it is needed. Under Windows PowerShell 5.1 it would have emitted
the engine's `#Requires` error instead of the line naming which PowerShell to
install. The absence is load-bearing and `verify.ps1` asserts it.

## Measured

- **Acceptance**: **1 passed, 9 failed** at red-first; **10 passed, 0 failed**
  after the tag. The one initial pass was vacuous — chapter 09 already satisfied
  it, so it graded nothing for this pass.
- **Preconditions**: tree clean at `c8330d772174c58a73f48b66588735db0c9ba8c5`;
  `git ls-remote --tags origin` returned **nothing** — no tags of any kind;
  no `marketplace.json`; TF comparator **14 passed, 1 failed**.
- **Backlog 20**: comparator suite **15 passed, 0 failed** after the fix. Oracle
  re-derived from the file: **78 nodes, 59 edges**, matching decision 0012.
  Seven mutations re-run: **DETECTED: 7 / 7**, each as its own category, control
  at 0 differences (`plans/0030-release/mutations.txt`).
- **Committed-marketplace validator, falsified 6 / 6**: version disagreement,
  non-`./` source, source without a `plugin.json`, missing file, malformed JSON,
  no matching entry — each exit 1 with a named complaint; control restored,
  exit 0 (`plans/0030-release/marketplace-falsification.txt`).
- **Prerequisite checker, falsified 5 / 5**, none simulated: version probe under
  a real Windows PowerShell **5.1.26100.9168**; Pester and InvokeBuild masked
  **independently** via `PSModulePath` roots holding only the other module; git
  via `PATH` masking; PAT cleared in a child process with the parent's token
  confirmed intact afterwards. Each **exit 1 with exactly one named line**;
  control **exit 0**, 5 of 5 present. Record ends
  `ALL PROBES: named one-line errors` (`plans/0030-release/hostile-first-run.txt`).
- **PublishLocal**: 14 skills, 2 commands staged; staged tree valid; committed
  marketplace validated, `psmodule 1.0.0`, source `./`, versions agree.
  `claude` CLI **not on PATH** — recorded, not skipped.
- **PublishReal, live path**: exit 0, prints the checklist, pushes nothing.
  Proved by AST: the only commands the parser finds **invoked** are
  `ConvertFrom-Json, Get-Content, Join-Path, Resolve-Path, Test-Path,
  Write-Host` (`plans/0030-release/packaging.txt`).
- **Diff**: 23 files, **+1264 / −30**, before plan artifacts and tag.

## Learned

- **A comment I added silently falsified a lesson in chapter 09.** The chapter
  teaches readers to verify the no-push claim with
  `Select-String -Pattern '^\s*(&\s*)?git\s'` over `Publish-Real.ps1` and
  promises no output. A sentence in a header comment wrapped so a line began
  with the word `git`, and the check started returning a hit — the file's
  behaviour unchanged, the documented verification broken. Found by re-running
  the chapter's own command rather than assuming a comment could not matter.
  Fixed by rewrapping the prose, not by loosening the pattern; `verify.ps1` now
  re-runs that command so it cannot rot again silently. **A documented check is
  part of the file's contract, and prose edits can break it.**
- **Masking `PSModulePath` wholesale would have let one probe take credit for
  another's line.** Removing both Pester and InvokeBuild at once produces two
  named errors from one break, and each probe would have looked like it fired.
  Two roots, each junctioned to exactly one module, were needed for the probes
  to be independent — the same shape as hazard 6's *a run of zero rows is not a
  pass*, arriving in the falsification harness itself.
- **`Test-StagedTree` returns its list via the `, $list` idiom, and piping it
  destroys the result.** My first call site piped it to `ForEach-Object`, which
  unrolls only the outer array and hands the `List` down as a single object; an
  empty list became one empty-string complaint, and `PublishLocal` failed
  validation reporting a defect that read as `-`. The bug was in the new code,
  not the old, and it announced itself immediately — but a slightly different
  shape would have made it report *green* over an unexamined list.
- **The acceptance test's item-19 assertion was already green at red-first.**
  Nine of ten red is a good red, but the tenth graded nothing for this pass. The
  work was done against the backlog item rather than against the assertion, and
  the vacuity is recorded rather than counted.
- **`LICENSE` was absent, and the prompt presupposed it was present.** "Confirmed
  present and MIT-consistent" describes a check, not a creation. There was no
  licence file at any casing, while `plugin.json` and the README both asserted
  MIT. The repository had been claiming a licence it did not carry.
- **Amending METHOD.md was not in the prompt and was necessary anyway.** Its
  PORTABLE rail says "no tag … unless the operator does it from their own
  shell", which decision 0013 contradicts. Backlog 21 is a standing record of
  three documents disagreeing; landing a decision that contradicts a fourth
  without saying so would have added to exactly the pile the backlog is
  complaining about.

## Capability

The plugin can now be installed by someone who has never met this repository:
there is a marketplace file, a version, a licence, a security statement, a
changelog in consumer words, and three commands at the top of the README —
pinned to a tag, so `main` can move without shipping to anyone. A newcomer whose
environment is wrong now gets one line naming the missing thing and the command
that fixes it, on any PowerShell including the wrong one, instead of a stack
trace. And the release itself became a deliberate, testable act: decision 0013
gives the agent release tags on a green acceptance test only, so "released" is
now a state something can be checked against rather than a thing that happens
when a branch merges.

What is still not possible, and is now the loudest gap: nobody has installed it
cold. Every claim above is about the file being correct, not about the install
working on a machine that has never cloned this repository.
