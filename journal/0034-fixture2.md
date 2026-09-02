---
pass: 0034
title: Build the second Terraform fixture, write the skills it unblocks, release 1.1.0
date: 2026-09-02
artifacts:
  - decisions/0014-second-unannotated-fixture.md
  - evals/tf/fixture2/cases.md
  - evals/tf/fixture2/expected-graph.json
  - evals/tf/Test-FixtureSanitization.ps1
  - skills/tf-hcl-parse/SKILL.md
  - skills/tf-module-resolve/SKILL.md
  - skills/tf-graph-assembly/SKILL.md
  - plans/0034-fixture2/plan.md
  - plans/0034-fixture2/sanitization.txt
  - plans/0034-fixture2/sanitization-fixture1-control.txt
  - plans/0034-fixture2/mutations2.txt
  - plans/0034-fixture2/readback2.txt
  - plans/0034-fixture2/verify.ps1
---

# Pass 0034 — Build the second Terraform fixture, write the skills it unblocks, release 1.1.0

## Asked

Take decision 0014 — the option pass 0033's scan recommended and did not take.
Build a second, unannotated Terraform fixture in three new Azure DevOps
repositories, with its own hand-authored oracle and case list, a sanitization
scan proving it says nothing about its own cases, a falsification proving the
comparator still detects all seven mechanisms against it, and a byte read-back
proving the push is the harness copy. Then write the three `tf-<role>` skills
backlog item 9 had deliberately withheld, land two hardening lines from run 007
into existing skills, release v1.1.0, and maintain the documents that describe
any of it.

Constraints: fixture 1 and its AzDO repositories untouched; `ClaudeTesting`
untouched; nothing ever queued, run or triggered; PAT hygiene absolute; no
assertion weakened, and the tooling parameterization must leave fixture-1
results byte-stable.

## Done

**Decision 0014** (`decisions/0014-second-unannotated-fixture.md`), in two
commits: the body before the push, the frozen SHAs as a marked amendment after
it.

**Fixture 2** under `evals/tf/fixture2/repos/` — `TfSiteCore`, `TfSiteEdge`,
`TfSiteOps`, 46 files. Created in Azure DevOps project
`ClaudeTestingTerraform` and pushed, one API call per repository.

**Oracle and case list** — `evals/tf/fixture2/expected-graph.json`
(hand-authored, 99 nodes, 88 edges) and `evals/tf/fixture2/cases.md`, which is
the only place fixture 2's case knowledge lives and says so.

**`evals/tf/Test-FixtureSanitization.ps1`** — pass 0033's hand-scan promoted to
a script. 38 patterns, four categories, commit messages in scope, two allowlist
entries stated in the report it prints.

**Tooling parameterized on `-Fixture`, defaulting to `fixture1`:**
`Mutate-TfGraph.ps1`, `Invoke-TfOracleFalsification.ps1`,
`Publish-TfFixture.ps1`, `Test-TfFixtureReadBack.ps1`, and
`TfAzdoClient.ps1` (which gains `Get-TfFixtureCommitMessage`).
`Compare-TfGraph.ps1` needed no change — it was already parameterized.

**Three skills:** `skills/tf-hcl-parse/`, `skills/tf-module-resolve/`,
`skills/tf-graph-assembly/`.

**Two hardening lines:** `skills/azdo-rest/SKILL.md` gains *"Read a response
property that may not be there, or lose the object"*;
`skills/powershell-module-scaffold/SKILL.md` gains *"A command that takes a
`-Path` must handle an absolute one"*.

**Release v1.1.0:** all three version strings in `.claude-plugin/`, a
user-facing `## 1.1.0` CHANGELOG section, the README install pin moved to
`@v1.1.0`, and an annotated tag.

**Documents:** `README.md` (three new skill rows, the `tf-` prefix in the
taxonomy paragraph, the withheld-skills note, the counts), `SECURITY.md`,
chapters 02 / 04 / 07 / 08 / 09, `docs/testing/README.md`, `LEDGER.md`.

## Why

**Fixture 1 was not amended, and that was the whole decision.** Three options
were costed in pass 0033's scan. Running against the annotated fixture and
disclosing the bound is free and spends the project's one generalisation
measurement on a fixture that labels its own cases. Stripping fixture 1's
annotations destroys the referent tf-001 and tf-002 were scored against — two
runs would keep their numbers while the thing those numbers were *about*
changed underneath them. Building a second fixture costs a fixture and
preserves both the freeze and the blindness, and it answers backlog item 9 with
the same artifact.

**Fixture 2 is not fixture 1 with the nouns changed.** Same seven mechanism
classes, different surface for each: four module levels instead of three; a
diamond where `modules/common` is called by two siblings and parented by
neither; two unresolved sources of two different shapes; a cross-repository
output reference landing in an `output` as well as a `local`, through a
`//subdirectory` call as well as a root-module call; different providers,
vocabulary and pins. A second fixture that is a translation of the first
measures memory, which is the thing being controlled for.

**The sanitization scanner was falsified two ways, and the second one is the
real control.** Planting a banned comment in a scratch copy proves the scanner
reacts to something. Pointing it at fixture 1 and getting **94 findings** —
the `cases.md` pointer, the *"Case 3"* comment, the absence case's stated wrong
answer, the numbered links — proves it discriminates between two real fixtures.
A gate that has only ever said *clean* is indistinguishable from a gate that
cannot say anything else.

**Commit messages were put in scope deliberately.** Fixture 1's push message
reads *"Terraform fixture for PSTerraformGraph scoring. Authored in the harness
at evals/tf/fixture/repos/…"*. A repository whose files are mute and whose first
commit says that has leaked the same thing one `git log` later. The message now
comes from `Get-TfFixtureCommitMessage`, which the scanner also reads, so the
two cannot drift.

**Parameterization defaults to fixture 1 everywhere.** A `-Fixture` switch whose
default changed would silently repoint every caller written before this pass,
including the ones inside committed verify scripts.

**No pipeline definitions were created for fixture 2.** The plan asked for
repository creation and a push. The YAML files are in the repositories and carry
`trigger: none` / `pr: none`, which is the mechanical form of the safety
statement fixture 1 makes in a comment — and a comment saying so would have
failed the sanitization rule. The asymmetry with fixture 1, which does have four
definitions, is recorded as backlog 31 rather than resolved by quietly creating
three more objects in a project this pass was told to leave alone.

## Measured

- **Acceptance, red first:** 10 of 10 failed
  (`plans/0034-fixture2/accept-red.txt`).
- **Fixture-2 oracle:** 99 nodes, 88 edges — 14 `sources`, 47 `references`,
  27 `passes-to`, 13 of them crossing a repository boundary
  (`evals/tf/fixture2/expected-graph.json`, counts re-derived in
  `plans/0034-fixture2/plan.md` §5 task 4).
- **Producer-contract battery against the oracle:** 7 passed, 0 failed
  (`PSGraphRenderToHtml/tests/ProducerContract.Battery.ps1`).
- **Sanitization, fixture 2:** 46 files and 3 commit messages scanned,
  **0 findings**, falsification passed — `FIXTURE2 SANITIZATION: clean`
  (`plans/0034-fixture2/sanitization.txt`).
- **Sanitization, fixture 1 as control:** **94 findings**, exit 1
  (`plans/0034-fixture2/sanitization-fixture1-control.txt`).
- **Falsification, fixture 2:** control green at 0 differences over 99 nodes
  and 88 edges; **`DETECTED: 7 / 7`**, 7 distinct categories
  (`plans/0034-fixture2/mutations2.txt`).
- **Falsification, fixture 1 after parameterization:** re-run and compared line
  by line against `plans/0030-release/mutations.txt` — identical except the
  generated-timestamp, oracle-path and new fixture lines.
- **Fixture-1 comparator suite:** 15 passed, 0 failed.
- **Read-back:** 46 files across 3 repositories, **`BYTE-IDENTICAL`**
  (`plans/0034-fixture2/readback2.txt`). Frozen at `a228e78c…` (TfSiteCore),
  `1ae66c27…` (TfSiteEdge), `fe27a34f…` (TfSiteOps).
- **Azure DevOps state after the push:** fixture 1's three repositories at their
  decision-0012 SHAs; 4 pipeline definitions, all fixture 1's; **0 builds** of
  any status in the project.
- **Skill roster:** 17 directories staged by `Publish-Local.ps1`, versions
  agreeing across the manifest and marketplace.
- **Acceptance, green:** 10 of 10.

## Learned

**The oracle's own cross-check found two real defects in the fixture before
anything else could.** A typo probe — declarations read from the HCL, compared
against the oracle's node set, deriving no edges — caught nothing, but the
degree-0 audit beside it caught two variables that were declared, passed in, and
then used by nothing: `modules/edge#var.terminate_tls` and, earlier,
`modules/edge#var.pop_count`. Neither was intended. A fixture with three
zero-out-degree variables has a *weaker* absence case than one with exactly one,
because the case stops being distinctive. Both were given a real use. **The
absence case is only sharp if absence is rare in the fixture**, and nothing
about the fixture announces when it stops being.

**A comma-wrapped array return, called inside `@(...)`, produces one element
that is an array.** `Test-FixtureSanitization.ps1` returned
`, @($findings | Sort-Object …)` and the caller wrote
`@(Get-SanitizationFinding …)`. `.Count` read 1 — which looks like one finding —
and the first property access threw *"The property 'Location' cannot be found on
this object"*, an error naming the consumer rather than the producer. Twenty
minutes, and it is now a comment in the file and backlog 30.

**Fixture 1's annotations were worse than the prose summary suggested.** The
0033 scan listed findings by severity and read as perhaps twenty. Mechanised, it
is **94**, because the same file trips several patterns per line. Nothing was
newly discovered — every one of them is in the 0033 scan — but the count is a
different kind of fact from a list, and it is the number that makes the
fixture-2 verdict mean something.

**One task was done out of order and it cost nothing except honesty.** The
fixture, the oracle and the push (tasks 3–5) were completed before decision 0014
was written (task 2). The decision was then written and committed on its own,
before the amendment carrying the SHAs, so the git history shows the two-step —
but the body was authored after the thing it decides about existed. Recorded in
Deviations rather than presented as the plan's order.

**A "different surface" is easy to claim and easy to under-deliver.** The first
draft of fixture 2 had four-level nesting and a diamond and was otherwise
fixture 1 with site/edge/ops vocabulary. What made it a genuinely different
instrument were the choices that create *new failure modes*: parent ≠ caller, a
provider pinned differently in two repositories, a value renamed on its last
hop, an unresolved source that is a well-formed URL. Each of those is a way to
be wrong that fixture 1 cannot pose.

## Capability

An agent installing v1.1.0 can now be told how to read Terraform configuration
without discovering the same four things the hard way: that a regex over a whole
`.tf` file is defeated by a brace in a string, a `#` in a string, a heredoc and
a block comment; that `required_providers` has two legal spellings and a reader
supporting one returns *no providers* rather than an error; that
`namespace/name/provider` and `./modules/child` are the same shape to a naive
pattern and the guard is the leading dot; and that a module's parent is the
nearest module above it in its own path, which is not its caller.

The project can now take a Terraform generalisation measurement at all.
Before this pass there was one Terraform instrument and it told a builder what
its own cases were; tf-003 against it would have measured parsing. There are now
two, and the one measurement runs point at has never been seen by anything that
produced the skills being measured.
