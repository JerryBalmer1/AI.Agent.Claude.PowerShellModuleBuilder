---
pass: 0013
title: Create the fixture in Azure DevOps
date: 2026-08-29
artifacts:
  - plans/0013-create-fixture/plan.md
  - plans/0013-create-fixture/verify.ps1
  - evals/functional/ReadBack.Tests.ps1
  - evals/functional/Sync-Fixture.ps1
  - evals/functional/AzdoClient.ps1
  - evals/functional/TROUBLESHOOTING.md
  - evals/functional/AZDO-FIXTURE.md
  - runs/001-fixture-create/create-summary.json
  - runs/001-fixture-create/README.md
  - .gitattributes
---

# Pass 0013 — Create the fixture in Azure DevOps

## Asked

Normalise line endings, then push four repositories and create fifteen pipeline
definitions in the Azure DevOps project `ClaudeTesting`, and verify by
read-back. Write the read-back test red first. Keep two claims apart everywhere:
read-back proves the push landed, and says nothing about whether
`expected-graph.json` is correct. Never queue, trigger or run a pipeline.
Never write the PAT anywhere. Correct the tier rule in `PLAN-PROTOCOL.md`,
harden the `**checked by:**` pointer, correct the PAT-shape scan everywhere it
appears, and write a troubleshooting document for a surface that can now fail on
someone else's machine.

## Done

- `.gitattributes` at the repository root pins `*.yml`, `*.json`, `*.md` and
  `*.ps1` to `eol=lf`.
- `evals/functional/AzdoClient.ps1` — shared Azure DevOps helpers, dot-sourced.
  Parses the fixture spec out of `AZDO-FIXTURE.md` rather than copying it.
- `evals/functional/ReadBack.Tests.ps1` — 76 assertions across the prompt's
  eight groups.
- `evals/functional/Sync-Fixture.ps1` — one script performing all creation, with
  `-DryRun`, idempotent, PAT from `$env:AZDO_PAT` only.
- `evals/functional/TROUBLESHOOTING.md` — seven failures, each with symptom, the
  command that reveals why, and the prerequisite.
- `evals/functional/FixtureCase.ps1` — captures the whole `**checked by:**`
  paragraph, not its first line; adds `Get-PesterTestName`.
- `evals/functional/Fixture.Tests.ps1` — six new assertions, 346 → 352.
- `evals/functional/fixture/cases.md` — case 12's pointer now quotes four real
  test names across two suites.
- `evals/functional/AZDO-FIXTURE.md` — how assertion 3 compares bytes; what
  creation actually required; the trigger claim corrected.
- `evals/HARNESS.md` — hazard 8: an absence check on prose is case-insensitive
  and line-broken.
- `PLAN-PROTOCOL.md` — tier decided by executable behaviour, with pass 0012 as
  the worked example; and an unrelated uncommitted change is committed alone
  before a pass begins.
- `plans/0011-*/verify.ps1`, `plans/0012-*/verify.ps1` — PAT scan corrected;
  0012's case count moved 346 → 352.
- `runs/001-fixture-create/` — `create-summary.json` and a README stating this
  is the fixture's creation, not a module output.
- In Azure DevOps: 4 repositories, 30 files, 15 definitions.

## Why

**The push goes through the REST API, not `git push`.** `git push` needs the
credential inside a remote URL, where it lands in the reflog, in `.git/config`
if the remote is saved, and in any process listing while the command runs. The
Git Pushes endpoint keeps the PAT in an Authorization header and nowhere else.
Rejected: pushing from a temporary clone with a credential helper, which trades
one place the PAT can persist for another.

**The fixture spec is parsed out of `AZDO-FIXTURE.md`, not copied into the
scripts.** A second copy of the fifteen-row definition table would be hazard 6
with nothing to make the two agree again. Rejected: a `fixture-spec.json`
generated from the document, which is a third artifact that can go stale between
regenerations.

**Definitions are created after all four pushes.** `p01.yml` and
`azure-pipelines.yml` declare `trigger: - main`, so a push landing after their
definitions existed would queue a run. Rejected: pushing with `***NO_CI***` and
creating definitions first, which relies on a commit-message convention holding
for every future push rather than on there being nothing to trigger. The marker
is still set, as a second guard for the re-run case.

**`verify.ps1` is self-contained.** It does not dot-source `AzdoClient.ps1` or
`FixtureCase.ps1`. Where the suite finds test names with the PowerShell AST,
verify uses a regex; where the suite parses a markdown table, verify re-reads it
separately. Agreement between two independent implementations is evidence;
agreement between one implementation and itself is not.

**The PAT scan was widened rather than replaced.** The measured correction is
below; widening was still right, because catching an 84-character secret with a
52-character window is an accident of length rather than a property of the
pattern.

## Measured

- **Line endings, three ways** — `plans/0013-create-fixture/plan.md`, task 1.
  Before `.gitattributes`, `pipelines/p01.yml`: working tree 449 bytes CR=0,
  git blob 449 bytes CR=0, **fresh clone 461 bytes CR=12**. After: all three 449
  bytes CR=0, hashes equal. All 30 files: 0 hash mismatches, 0 CR bytes in the
  clone. `core.autocrlf=true` resolves from **system** scope.
- **`git add --renormalize .`** changed nothing.
- **Fixture tree object id** `85300426a136d5ff88f22533a36c78a5fd934266`,
  identical at `c985349` and at `HEAD`: normalisation altered no fixture byte.
- **`Fixture.Tests.ps1`** 346 before and after task 1; 352 after task 3.
- **`ReadBack.Tests.ps1`** red first: 76 total, 3 passed, 73 failed. Green after
  creation: 76 passed, 0 failed. Per-assertion: 4 / 4 / 30 / 4 / 15 / 1 / 15 / 3.
- **Created** — `runs/001-fixture-create/create-summary.json`: 4 repositories,
  30 files, 15 definitions. Second run: 0 created, 49 already present.
- **Builds** — every one of the 15 definitions has a build count of 0.
- **PAT shape** — 84 characters, entirely `[A-Za-z0-9]`, longest alphanumeric
  run 84. Value never printed.
- **Long alphanumeric runs in the repository** — only two shapes, both lower-hex:
  40-character git object ids (×6) and 64-character SHA-256 digests (×30).
- **`verify.ps1`** — 8 checks, all agreeing, exit 0; 4 skipped with
  `AZDO_PAT` unset, still exit 0.

## Learned

**The prompt's premise about the PAT scan was wrong, and measurement said so.**
The prompt held that the committed scan "cannot match the secret it scans for"
and so "reports clean". Tested against the real value: `[a-z2-7]{52}` does not
match, but the second committed pattern `[A-Za-z0-9]{52}` **does**, because it
is unanchored and a 52-character window sits inside an 84-character run. The
scan could fail and would have. It is not the fifth check found unable to fail;
it is a check that was correct for a reason nobody had written down.

**The real defect was the opposite one.** Committing 30 SHA-256 digests in
`create-summary.json` would have made the *old* scan go red on a file containing
no secret, in all three verify scripts. A check that cries wolf gets switched
off, so the correction that mattered was an exclusion for 40- and 64-character
lower-hex runs, not a wider pattern.

**Hard-wrapped prose defeats phrase matching, twice in one pass.**
`FixtureCase.ps1` captured only the first line of a `**checked by:**` block, so
it saw half of a quoted test name. Then a `grep -c` written to confirm a
falsification probe had been applied returned 0 for a phrase that was
demonstrably in the file, because the phrase spanned a line break — the same
hazard, in the tool being used to check for the hazard. Both are now hazard 8 in
`evals/HARNESS.md`.

**The working tree and the git blob agree while a clone does not.** The fixture
files were written into the tree rather than checked out, so the two obvious
places to look were both clean and the gap only appeared on clone. A two-sided
measurement would have found nothing; it took a third side.

**A pass's own artifacts can break an earlier pass's verify script.** Adding six
assertions moved the suite to 352 and broke `plans/0012/verify.ps1`, which pinned
346. Left alone that is hazard 6 pointing at itself.

**Azure DevOps refused nothing**, including the two definitions built to be
broken. Template expansion happens at queue time, and nothing here is ever
queued, so their faults are never evaluated.

## Capability

The functional fixture now exists in Azure DevOps and can be rebuilt from the
repository with one command after a wipe, with a read-back that proves the
rebuild byte-for-byte. A module written against this project can now be run and
graded against a known corpus of pipelines whose YAML is version-controlled,
where previously there was nothing to point it at.
