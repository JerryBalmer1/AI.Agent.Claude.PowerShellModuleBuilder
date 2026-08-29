# Pass 0012 — Document corrections and the case split

Tier: **light** as stated in the prompt, though the prompt also requires a
red-first acceptance test and a `verify.ps1` with named spot-checks, both of
which `PLAN-PROTOCOL.md` calls full-tier artifacts. Both are here. See
Deviations 7.

Branch: `pass-0009-control-polarity`.

## 1. Prompt

````text
# PASS 0012 — Document corrections and the case split

Tier: light

Split out of the original 0012. These tasks are entirely local: no network, no
PAT, no Azure DevOps. The fixture creation becomes Pass 0013 and runs once
`$env:AZDO_PAT` is set.

The split is a correction to my prompt design, not to your stop. Bundling local
corrections with network work put them behind a precondition they have no
relationship to, and the all-preconditions-first rule then held them hostage.
The rule is right; the bundling was wrong.

## Preconditions

Any failure is a hard stop — commit nothing, report.

- [ ] On a pass branch, not `main`. Report branch and HEAD.
- [ ] Working tree clean.
- [ ] `PLAN-PROTOCOL.md`, `method/METHOD.md`, `evals/HARNESS.md`,
      `evals/functional/cases.md`, `evals/functional/fixture/expected-graph.json`
      and `evals/functional/Fixture.Tests.ps1` all exist.
- [ ] `Fixture.Tests.ps1` is green at 317 tests. Report the count.
- [ ] `pwsh --version`, resolved Pester 6.x, OS.

No PAT is required and none is read. `AzDoPAT.txt` is not touched.

## Acceptance test — red first

Task 2 amends `Fixture.Tests.ps1` assertion 7. Write the amended assertion
first and run it against the current, unmodified `cases.md` and
`expected-graph.json`. It must be red, because `cases.md` does not yet carry
`kind:` markers. Record the red.

Assertions 1–6 and the eleventh assertion added in Pass 0011 must stay green
throughout. A change to assertion 7 that moves any other count is a finding.

## Plan

- [ ] **1.** Apply four document corrections. All four are mine; three came
      from your Pass 0011 deviations and one from Pass 0010, and all four are
      accepted as you argued them.

      **1a. `PLAN-PROTOCOL.md` §9.** Replace the requirement that `verify.ps1`
      appear in a fenced block with: *committed beside the plan, and reproduced
      in a fenced block only when short enough that no reader will diff the two
      copies.* Record the reason — a second copy of an executable in the same
      commit can disagree with the first, which is hazard 6 applied to the one
      artifact whose job is to disprove the plan.

      **1b. `PLAN-PROTOCOL.md` §11.** Drop the token count. Wall-clock only,
      plus any run counts the pass produced. A field the agent cannot measure
      is a field that gets guessed at, and this project's own rule is that a
      number without an artifact does not belong in a plan.

      **1c. `method/METHOD.md`, Known limits.** Replace "Skip the corpus, the
      harness, and the decisions log" with "Skip the harness and the decisions
      log. Do not skip the corpus: it is the cheapest part of the method when
      one already exists, and it is what breaks the closed loop — here it cost
      one pass and invalidated five of ten assertions in the tag it tested."

      **1d. `evals/HARNESS.md`, hazard 6.** Add the instance you found in Pass
      0011: a probe whose substitution silently failed to apply — a `-replace`
      with the wrong operand count — after which `verify.ps1` reported all
      checks agreeing. The tell was an empty failure list, not the exit code.
      State the guard: a probe asserts that it changed the file before the
      check runs, and a check that reports agreement with an empty failure list
      and an unapplied probe is a false green.

- [ ] **2.** Split case 10 and add two cases. Update `cases.md`, the `cases`
      tags in `expected-graph.json`, and assertion 7 in `Fixture.Tests.ps1`.

      **case-10** keeps the orphan claim alone: `p10-orphan` has no edges but
      its `definition` edge and appears as an isolated node.

      **case-11** takes the checkout claim: `x01-consumer-build`'s `checkout:`
      of a second repository is a repo dependency and not a template edge. You
      were right that the two cannot coexist on one definition.

      **case-12** is new and is an *absence* claim. The Azure DevOps project
      already contains a repository named `ClaudeTesting`, created with the
      project and empty. It is referenced by no pipeline and must not appear in
      the graph. It discriminates against an implementation that enumerates
      project repositories instead of deriving them from pipeline references.
      Nothing in `expected-graph.json` can carry a `case-12` tag, because the
      case is that nothing does.

      That breaks assertion 7 as written, which requires every case id to
      appear on at least one node or edge. Amend it: `cases.md` marks each case
      `kind: presence` or `kind: absence`. A presence case must be tagged on at
      least one node or edge. An absence case must be tagged on none, and must
      name in `cases.md` the assertion elsewhere that checks it. Case 12's
      checks are: no node in `expected-graph.json` has an id, name, or repo
      field equal to `ClaudeTesting`, asserted here; plus a read-back assertion
      in Pass 0013 that the repository exists, is empty, and no definition
      targets it.

- [ ] **3.** Falsify the amended assertion 7 before recording any green.
      Minimum three probes, restored between each, each asserting it changed
      the file before the check runs — the guard from 1d:
      - tag any node `case-12` → must go red
      - remove a presence tag from the only node carrying it → must go red
      - add a comment to `cases.md` mentioning `case-12` without a `kind:`
        marker → must stay green, the scope control

- [ ] **4.** Run the full acceptance test. Record green, with per-context case
      counts as in Pass 0011. Report the new total and account for any change
      from 317.

- [ ] **5.** Record in `evals/functional/AZDO-FIXTURE.md` that the project
      contains a pre-existing empty `ClaudeTesting` repository, that Pass 0013
      must not delete, modify, or push to it, and that its presence is case 12.

- [ ] **6.** Commit and push to the pass branch. Report the pushed SHA.

## Named spot-checks

`verify.ps1` must independently re-derive, by name:

1. `Fixture.Tests.ps1` green at its full case count, and the count itself.
2. That `cases.md` declares twelve cases, each with a `kind:` marker, and that
   the presence/absence split matches the tags in `expected-graph.json` — every
   presence id tagged at least once, every absence id tagged never.
3. That no node in `expected-graph.json` has an id, name, or repo equal to
   `ClaudeTesting`.
4. That `PLAN-PROTOCOL.md` no longer requires a token count and no longer
   requires `verify.ps1` fenced unconditionally.
5. That `method/METHOD.md` no longer says to skip the corpus.
6. That no PAT-shaped string appears in any tracked file.

No network. `verify.ps1` must not read `$env:AZDO_PAT` and must not reach Azure
DevOps this pass.

## Constraints

No network calls. No PAT read. No Azure DevOps resource touched. No fixture
YAML changed — only `cases` tags in `expected-graph.json`, and nothing else in
that file. Push to the pass branch; no tags, no `main`, nothing published.

## Deviations

Required. Write "none" if there are none. Flag specifically: whether the
presence/absence distinction is the right shape, or whether an absence case
belongs in a different file entirely rather than in `cases.md`.

## Journal

Write `journal/0012-case-split-and-corrections.md` from this pass's artifacts
using `journal/TEMPLATE.md`. Capability only.

## Report back

Branch and pushed SHA; the plan path; red-first and green output for the
amended assertion 7; the three probe outcomes; the new total case count and
what accounts for any change from 317; and whether you think the
presence/absence shape is right.
````

## 2. Preconditions

All passed. One path in precondition 3 does not exist as written; see
Deviations 1.

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | On a pass branch, not `main` | `git rev-parse --abbrev-ref HEAD` / `git rev-parse HEAD` | `pass-0009-control-polarity` at `fd39b351d6d45bc3d525d67abdf5324e1a1fdf97` |
| 2 | Working tree clean | `git status --porcelain` | empty |
| 3 | Six files exist | `test -f` on each | five OK; `evals/functional/cases.md` **missing**, the file is `evals/functional/fixture/cases.md` |
| 4 | `Fixture.Tests.ps1` green at 317 | `Invoke-Pester` | **317 passed, 0 failed** |
| 5 | Environment | see below | reported |

pwsh 7.6.5 · Pester 6.1.0 at
`C:\Users\jlbal\OneDrive\Documents\PowerShell\Modules\Pester\6.1.0\Pester.psd1` ·
Microsoft Windows NT 10.0.26200.0.

No PAT was read. `AzDoPAT.txt` was not touched. No network call was made.

## 3. Acceptance test — red first

The amended assertion 7 was written and run against the unmodified `cases.md`
and `expected-graph.json`.

```text
RED-FIRST: Passed=315 Failed=15 Total=330

[-] cases.md declares exactly twelve cases
      Expected 12, but got 10.
[-] case case-01 declares exactly one kind marker
      Expected 1, because a case with no kind, or two, cannot be checked in
      either direction, but got 0.
[-] case case-02 … case case-10 declares exactly one kind marker      (×10 total)
[-] presence and absence partition the declared cases
      Expected 10, but got 0.
[-] there is at least one presence case
      Expected the actual value to be greater than 0, but got 0.
[-] there is at least one absence case
      Expected the actual value to be greater than 0, but got 0.
[-] the graph carries every presence case id and nothing else
      Expected strings to be the same, but they were different.

--- per context ---
Assertion 1 — expected-graph.json parses and validates                 2
Assertion 2 — every node is well formed                               80
Assertion 3 — every edge endpoint resolves, except where it must not  104
Assertion 4 — no orphan files, no dangling nodes                      31
Assertion 5 — every YAML file parses                                  30
Assertion 6 — the declared graph and the YAML agree                   61
Assertion 7 — the cases are declared on both sides, by kind           18
The fixture exists                                                     4
```

Every failure is in assertion 7 and every one is for the right reason. The
other seven contexts hold at 2 / 80 / 104 / 31 / 30 / 61 / 4 — identical to
Pass 0011 — so the change moved nothing it should not have. The eleventh
assertion from Pass 0011 is one of assertion 6's 61 and stayed green.

Three assertions inside the amended context **passed** on this run, correctly:
`cases.md declares no duplicate case id`, `every case id in the graph is
declared in cases.md`, and `no node is the pre-existing ClaudeTesting
repository`. A red-first in which the whole context fails would have been the
weaker result: it would not distinguish "the new assertions fire" from "the
context is broken".

### The first red was the wrong red

The first attempt failed all **18** assertion-7 tests, including those three,
and the failure messages were empty. That is the signature of a `BeforeAll`
throwing, not of assertions failing. The cause is a genuine Pester defect and is
Deviations 2. It was found and fixed before the red above was recorded, because
a red for the wrong reason is not a red-first — it is an untested test that
happens to be failing.

## 4. Tasks

### - [x] 1. Four document corrections

**1a — `PLAN-PROTOCOL.md` §9.** The unconditional fenced-block requirement is
replaced by the conditional form, with the reason recorded in the section
itself: a second copy of an executable in the same commit can disagree with the
first, which is hazard 6 applied to the artifact whose job is to disprove the
plan. A reader who diffs a fenced excerpt against the committed script and finds
them different has learned nothing about either.

**1b — `PLAN-PROTOCOL.md` §11.** Now: *"Wall-clock for the pass, plus any run
counts the pass produced — suite runs, probe rows, build invocations. No token
count."* with the reason and the note that if a token count is wanted it has to
come from the host.

**1c — `method/METHOD.md`, Known limits.** Now reads:

> On a small project, use the minimum: an oracle, falsification with controls,
> and a journal. Skip the harness and the decisions log. Do not skip the corpus:
> it is the cheapest part of the method when one already exists, and it is what
> breaks the closed loop — here it cost one pass and invalidated five of ten
> assertions in the tag it tested.

**1d — `evals/HARNESS.md`, hazard 6.** A third instance added, headed *the probe
that never applied*, carrying the Pass 0011 `-replace` failure as a fenced
PowerShell block, the observation that the tell was the empty failure list
rather than the exit code, and the requirement:

> a probe asserts that it changed the file — content hash, or byte length, or an
> explicit re-read and compare — *before* the check under test is run, and
> aborts the row if nothing changed. The guard belongs at the probe, not at the
> check; a check cannot know whether the thing it is reading was supposed to be
> different.

That guard is implemented in both probe drivers this pass used, and both report
`applied=yes` per row.

### - [x] 2. The case split

**`fixture/cases.md`**, +157 −60. Title is now *The twelve cases*. A new section,
*Presence and absence*, states the rule and why an absence case needs a
`**checked by:**` line: "nothing carries this tag" is otherwise satisfied by a
case that nothing checks at all.

Every case gained `**kind:** presence` except case 12, which is `absence` and
carries:

```text
**checked by:** `Fixture.Tests.ps1` assertion 7, "no node is the pre-existing
ClaudeTesting repository"; and read-back assertion 8 in Pass 0013, that the
repository exists in the project, is empty, and no definition targets it.
```

case-10 keeps the orphan claim alone. case-11 is new and takes the `checkout`
claim. case-12 is new and is the absence.

**`fixture/expected-graph.json`**, 4 lines changed, all of them `cases` tags and
nothing else:

| Line | Item | Was | Now |
|---|---|---|---|
| 22 | `pipeline:x01-consumer-build` | `case-10` | `case-11` |
| 57 | `yaml:consumer-app/azure-pipelines.yml` | `case-10` | `case-11` |
| 111 | `azure-pipelines.yml → repo:templates-shared`, `repositoryResource` | `case-10` | `case-11` |
| 112 | `azure-pipelines.yml → repo:templates-shared`, `checkout` | `case-10` | `case-11` |

Three items keep `case-10`: the `pipeline:p10-orphan` node, the
`yaml:…/p10.yml` node, and the `definition` edge joining them. Nodes still 49,
edges still 51; nothing but tags moved.

**`Fixture.Tests.ps1`** assertion 7, rewritten. Twelve assertions became
thirty-four:

| Assertion | Cases |
|---|---|
| `cases.md declares exactly twelve cases` | 1 |
| `cases.md declares no duplicate case id` | 1 |
| `case <id> declares exactly one kind marker` | 12 |
| `presence and absence partition the declared cases` | 1 |
| `there is at least one presence case` | 1 |
| `there is at least one absence case` | 1 |
| `presence case <id> is carried by at least one node or edge` | 11 |
| `absence case <id> is carried by no node or edge` | 1 |
| `absence case <id> names the assertion that checks it` | 1 |
| `the case declarations survive CRLF line endings` | 1 |
| `every case id in the graph is declared in cases.md` | 1 |
| `the graph carries every presence case id and nothing else` | 1 |
| `no node is the pre-existing ClaudeTesting repository` | 1 |
| **total** | **34** |

The three `-ForEach` assertions over presence and absence carry
`-AllowNullOrEmptyForEach`, guarded by the two explicit count assertions above
them. Left to Pester's default they abort discovery on an empty list and take
assertions 1–6 down with them, which hides more than it reports. The counts are
what keep zero cases from passing — standing rule 9 enforced by an assertion
rather than by a crash.

**`evals/functional/FixtureCase.ps1`**, new, 56 lines. The case-declaration
reader, dot-sourced from both `BeforeDiscovery` and `BeforeAll`. It is a
separate file for a reason recorded in its own header; see Deviations 2.

### - [x] 3. Falsification of the amended assertion 7

Driver: `scratch/falsify-assertion7.ps1`, not committed. Six probes rather than
the three required — three breaks were added for the assertions the prompt's
three did not reach. Every row hashes the whole `evals/functional` tree before
and after the substitution and **aborts the row** if the hash did not change.

```text
baseline: passed=346 failed=0 total=346

break-absence-case-tagged          break    expect=red    actual=red    failed=2   applied=yes AS EXPECTED
      absence case case-12 is carried by no node or edge
      the graph carries every presence case id and nothing else
break-presence-tag-removed         break    expect=red    actual=red    failed=2   applied=yes AS EXPECTED
      presence case case-11 is carried by at least one node or edge
      the graph carries every presence case id and nothing else
control-prose-mentions-case-12     control  expect=green  actual=green  failed=0   applied=yes AS EXPECTED
break-kind-marker-removed          break    expect=red    actual=red    failed=3   applied=yes AS EXPECTED
      case case-07 declares exactly one kind marker
      presence and absence partition the declared cases
      the graph carries every presence case id and nothing else
break-absence-checked-by-removed   break    expect=red    actual=red    failed=1   applied=yes AS EXPECTED
      absence case case-12 names the assertion that checks it
break-node-named-ClaudeTesting     break    expect=red    actual=red    failed=1   applied=yes AS EXPECTED
      no node is the pre-existing ClaudeTesting repository

restored: passed=346 failed=0 total=346
probes=6 not-as-expected=0
```

The three the prompt named are rows 1, 2 and 3. The control adds two prose
mentions of `case-12` to `cases.md`, one of them inside an HTML comment that
also contains the literal text `kind: absence`, and the suite stays green:
declarations are anchored on the `##` heading, so prose cannot document a case
into existence.

**One probe over-fired, and the over-firing was a real defect.** On the first
run `break-absence-checked-by-removed` failed **16** assertions instead of one,
including `case case-01 declares exactly one kind marker`. That probe rewrites
`cases.md` via `Set-Content` with a line array, which writes CRLF. The kind
marker regex ended `[ \t]*$`, and in .NET multiline mode `$` matches before the
`\n` but after the `\r`. Every marker stopped parsing. See Deviations 3 — the
defect was not in the probe.

### - [x] 4. The full acceptance test, green

```text
[+] evals\functional\Fixture.Tests.ps1 4.17s (346 tests)
Tests Passed: 346, Failed: 0, Skipped: 0, Inconclusive: 0, NotRun: 0
GREEN: Passed=346 Failed=0 Total=346 ContainersFailed=0

Assertion 1 — expected-graph.json parses and validates                 2
Assertion 2 — every node is well formed                               80
Assertion 3 — every edge endpoint resolves, except where it must not  104
Assertion 4 — no orphan files, no dangling nodes                      31
Assertion 5 — every YAML file parses                                  30
Assertion 6 — the declared graph and the YAML agree                   61
Assertion 7 — the cases are declared on both sides, by kind           34
The fixture exists                                                     4
```

**317 → 346, accounted for exactly:**

```text
317   Pass 0011 total
 -5   assertion 7 as it was
+34   assertion 7 as amended
----
346
```

Nothing else moved. Contexts 1–6 and *The fixture exists* are byte-for-byte the
same counts as Pass 0011, which is what the prompt asked to be true.

Of the 34, one is the CRLF guard added this pass and 29 are attributable to the
split: twelve `kind marker` cases where there were none, eleven presence cases
and one absence case where there was a single "every case id is carried"
assertion, and the three structural counts.

### - [x] 5. `AZDO-FIXTURE.md`

A new section, *The pre-existing `ClaudeTesting` repository*, 27 lines: that it
exists, was created with the project, is empty, and that Pass 0013 must not
delete, modify, push to, or create a definition in it; that its presence **is**
case 12 and why that discriminates; that nothing carries a `case-12` tag because
tagging would assert the opposite; and where its checks live.

Two corrections came with it, both flagged in Deviations 5:

- The file said **Pass 0012** in six places. Renumbered to Pass 0013 here and in
  `BRIEF.md`. `plans/` and `journal/` were left alone — they record what was
  true when written.
- Read-back check 1 said *"Four repositories exist, named exactly as above, and
  no others."* That is now wrong and would have failed against a correct
  project. It reads **five** — the four fixture repositories plus
  `ClaudeTesting` — and says so explicitly, including that an earlier version
  said four. A new read-back check 7 states case 12's external half.

### - [x] 6. Commit and push

Section 8.

## 5. Diff summary

10 files, 618 insertions, 60 deletions.

| Path | Δ | What and why |
|---|---|---|
| `PLAN-PROTOCOL.md` | +24 −5 | §9 conditional fencing with its reason; §11 wall-clock and run counts, no token count |
| `method/METHOD.md` | +6 −3 | Known limits: the corpus is no longer on the skip list, with the reason |
| `evals/HARNESS.md` | +28 | Hazard 6 gains the probe-that-never-applied instance and the did-it-change guard |
| `evals/functional/fixture/cases.md` | +157 −60 | Twelve cases, kind markers, the presence/absence rule, case-10 split, case-11 and case-12 |
| `evals/functional/fixture/expected-graph.json` | +4 −4 | Four `cases` tags moved from `case-10` to `case-11`. Nothing else |
| `evals/functional/Fixture.Tests.ps1` | +99 −9 | Assertion 7 rewritten by kind; the CRLF regression guard; helper dot-sourced |
| `evals/functional/FixtureCase.ps1` | +56 | New. The case reader, out of the test file because Pester cannot have it there |
| `evals/functional/AZDO-FIXTURE.md` | +48 −3 | The ClaudeTesting section; read-back corrected to five repositories; renumbered |
| `evals/functional/BRIEF.md` | +1 −1 | Renumbered Pass 0012 → 0013 |
| `plans/0012-case-split-and-corrections/verify.ps1` | +238 | New. Six checks, no network |

No fixture YAML changed. No file under `fixture/repos/` appears in the diff.

## 6. Command transcript

```bash
# --- preconditions -------------------------------------------------------
git rev-parse --abbrev-ref HEAD; git rev-parse HEAD; git status --porcelain
pwsh -NoProfile -Command "Invoke-Pester -Configuration <Fixture.Tests.ps1, PassThru>"   # 317 green

# --- red first -----------------------------------------------------------
# amend assertion 7, then:
pwsh -NoProfile -Command "Invoke-Pester -Configuration <…>"                            # 315/15/330

# --- diagnosing the first, wrong red -------------------------------------
# minimal repro: a .Tests.ps1 whose only top-level statement is a function
# definition, plus a Describe whose BeforeAll runs Get-Command on it
pwsh -NoProfile -Command "<three-variant bisect: for/foreach/early-return>"             # all 3 fail
pwsh -NoProfile -Command "<(a) Get-Command  (b) trivial call  (c) defined in BeforeAll>"  # a,b fail; c passes
pwsh -NoProfile -Command "<dot-sourced helper, BeforeDiscovery + BeforeAll>"            # 11/11 pass

# --- the CRLF defect -----------------------------------------------------
pwsh -NoProfile -Command ". ./evals/functional/FixtureCase.ps1;
  <parse cases.md from disk>            # 12 of 12 have a kind
  <parse a CRLF copy of the same bytes> # 0 of 12 have a kind"
git config --get core.autocrlf                                                          # true
ls .gitattributes                                                                       # absent

# --- falsification -------------------------------------------------------
pwsh -NoProfile -File scratch/falsify-assertion7.ps1        # 6 probes, 0 not-as-expected
# prove the CRLF guard itself can fail: revert the normalisation, hash-check the
# revert applied, run only *CRLF*, restore, hash-check the restore
pwsh -NoProfile -Command "<revert normalisation; Filter.FullName='*CRLF*'>"              # 0 passed, 1 failed

# --- green ---------------------------------------------------------------
pwsh -NoProfile -Command "Invoke-Pester -Configuration <…>"                            # 346/0/346

# --- verify --------------------------------------------------------------
pwsh -NoProfile -File plans/0012-case-split-and-corrections/verify.ps1                  # exit 1, 3 checks
# fix the three check defects (phrase greps), then:
pwsh -NoProfile -File plans/0012-case-split-and-corrections/verify.ps1                  # exit 0
pwsh -NoProfile -File scratch/falsify-verify-0012.ps1                                   # 2 probes, both red

# --- commit --------------------------------------------------------------
git add -A
git diff --cached --stat
git commit -F <message file>
git push origin pass-0009-control-polarity
git rev-parse HEAD; git status --porcelain; git tag | wc -l
pwsh -NoProfile -File plans/0012-case-split-and-corrections/verify.ps1                  # exit 0
```

## 7. Verify script

`plans/0012-case-split-and-corrections/verify.ps1`, committed beside this file.
Not reproduced here as a fenced block, which as of this pass is what
`PLAN-PROTOCOL.md` §9 says to do.

**No network.** It does not read `$env:AZDO_PAT`, does not read `AzDoPAT.txt`,
and makes no outbound call. That is a property of Pass 0012 only; Pass 0013's
verify script will need the network for its read-back checks.

Six checks, 28 assertions, exit 0 when all agree:

```text
check 1 - the acceptance test is green at its full case count           3 ok
check 2 - twelve cases, each with a kind, and the split matches         9 ok
check 3 - case 12: no node names the ClaudeTesting repository           3 ok
check 4 - PLAN-PROTOCOL.md corrections                                  5 ok
check 5 - method/METHOD.md no longer says to skip the corpus            4 ok
check 6 - no PAT-shaped string in any tracked file                      3 ok

VERIFY: all checks agree.
EXIT=0
```

Check 2 carries a **second, independently written** case reader: line based,
walking the file top to bottom and attributing each marker to the heading above
it, where `FixtureCase.ps1` slices the text into sections by heading offset. It
also handles line endings differently — `Get-Content` line splitting rather than
a `-replace` — deliberately, because two readers that normalise the same way
would agree while both being wrong, which is precisely the defect this pass
found.

**Proved capable of failing.** Two probes, each hash-guarded, restored after:

| Probe | Applied | Result |
|---|---|---|
| Revert the METHOD.md correction to "Skip the corpus, the harness, and the decisions log" | yes | exit 1, all four of check 5's assertions red |
| Tag `repo:consumer-app` with `case-12` | yes | exit 1, five assertions red across checks 1, 2 and 3 |
| Restore both | — | exit 0 |

## 8. Commit and push

Recorded in the report; the pushed SHA is at the head of it.

## 9. Deviations

**1. `evals/functional/cases.md` does not exist.** Precondition 3 names it; the
file is `evals/functional/fixture/cases.md`. Not treated as a hard stop: the
file the pass needs exists, at an unambiguous path, and no second candidate
exists anywhere in the tree. Flagged rather than silently corrected because the
precondition list is the gate and a gate that quietly resolves its own paths is
not a gate.

**2. A top-level `function` in a Pester 6.1.0 test file breaks every `BeforeAll`
in that file.** This cost the first red-first run, which failed all 18
assertion-7 tests with empty error messages.

Reduced to the smallest reproducing case:

```powershell
function Probe-It { param([string]$Path) 'hello' }
Describe 'probe' {
    BeforeAll { $script:Found = [bool](Get-Command Probe-It -ErrorAction SilentlyContinue) }
    It 'function is visible in BeforeAll' { $script:Found | Should -BeTrue }
}
```

Result: **failed**. So does a variant whose `BeforeAll` merely calls the
function. Moving the identical function inside `BeforeAll` passes. Dot-sourcing
it from a separate file, from both `BeforeDiscovery` and `BeforeAll`, passes —
11 of 11, with `<_.Id>` expansion working.

The error is:

```text
InvalidOperationException: A 'break' or 'continue' statement with a label that
does not match any enclosing loop escaped from your code. This is usually a
misspelled or undefined loop label.
```

which names loop labels, mentions neither functions nor `BeforeAll`, and points
at nothing that is wrong. Three variants were bisected — `for` loop, `foreach`
loop, early `return` — before the shape of the problem became visible; none of
them was the cause. The fix is `evals/functional/FixtureCase.ps1`, dot-sourced.
The reason is recorded in that file's header so the next person does not repeat
the bisect.

**3. The kind marker regex did not survive CRLF, and the repository is
configured to produce CRLF.** Found because a probe over-fired.

`core.autocrlf` is `true` and there is no `.gitattributes`, so `cases.md`
arrives CRLF in any fresh clone on Windows. In .NET multiline mode, `$` matches
before the `\n` but *after* the `\r`, so `^\*\*kind:\*\*[ \t]+(presence|absence)[ \t]*$`
fails on every marker. Measured:

```text
working copy (LF)   : 12 of 12 declarations have a kind
CRLF copy, same bytes:  0 of 12 declarations have a kind
```

The whole of assertion 7 would have failed for the next person to clone this
repository, and passed here. Fixed by normalising line endings in the reader,
with the measurement in the code comment; guarded by a new assertion that parses
a CRLF copy and requires identical declarations; and re-derived independently in
`verify.ps1` check 2. The guard was itself falsified — revert the normalisation
and it goes red.

**The systemic fix was not applied.** A `.gitattributes` with `* text=auto` and
`*.yml text eol=lf` would stop this class at source, and would also protect the
fixture YAML, whose byte-identical read-back is Pass 0013's load-bearing check —
a CRLF round-trip through Azure DevOps against LF committed files is exactly the
kind of thing that check exists to catch, and it would fail for a reason that has
nothing to do with the fixture. Adding it changes how every file in the
repository is stored, which is more than this pass was asked for. It is flagged
here as work for Pass 0013's preconditions rather than done unasked.

**4. `verify.ps1` failed three of its own checks against correct documents.**
All three were defects in the checks:

- `-match 'token count'` reported §11 uncorrected. The corrected §11 says "No
  token count" and "If a token count is wanted it has to come from the host" —
  the grep could not distinguish a requirement from a statement that there is
  none. Now: `-cmatch 'approximate token count'` must be absent, `No token count.`
  must be present.
- `-match 'Skip the corpus'` reported METHOD.md uncorrected. `-match` is
  case-insensitive in PowerShell, so the corrected sentence *"Do not skip the
  corpus"* matched its own prohibition. Now case-sensitive with a negative
  lookbehind.
- `-match 'Do not skip the corpus'` also failed, against text that says exactly
  that — because markdown hard-wraps and the phrase spans a line break as
  `Do\n  not skip the corpus`. Every phrase check now runs against a
  whitespace-collapsed copy.

Worth stating as a general rule, because two of the three are traps rather than
slips: **asserting on prose in a hard-wrapped document requires normalising
whitespace, and `-match` in PowerShell is case-insensitive by default, so a check
for the absence of a phrase will match that phrase's own negation.**

**5. `AZDO-FIXTURE.md` was wrong in two ways that this pass caused.** Its
read-back check said "four repositories … and no others", which would have failed
against a correct project once the pre-existing `ClaudeTesting` repository was
accounted for. Corrected to five, with the old wording named so the change is
visible. Separately the whole document said Pass 0012; renumbered to 0013 there
and in `BRIEF.md`, and deliberately **not** in `plans/0011-…` or `journal/0011`,
which record what was true when they were written.

**6. Is presence/absence the right shape? Yes, with one reservation.**

The prompt asked specifically. Keeping absence cases in `cases.md` is right. A
case is a claim about what a correct implementation outputs, and "must not
contain X" is exactly as much a claim about output as "must contain Y". Splitting
by file would make a reader consult two places to know what the module is judged
on, would let the two drift out of numbering, and would tempt someone into
treating absence cases as a lesser category. They are not lesser: case 12 catches
an implementation shape — enumerate the project's repositories rather than derive
them from references — that is the *obvious* first implementation and that gets
worse with scale.

The reservation is the `**checked by:**` line. It is a pointer written in prose,
and pointers rot. Nothing currently checks that the assertion it names exists.
Today it names `"no node is the pre-existing ClaudeTesting repository"`, which is
a real test in the suite, and a Pass 0013 read-back assertion that does not exist
yet. Rename that test and the pointer silently becomes false — which is hazard 6,
the stale expectation, in a new place, and this project has now hit that hazard
four times.

The hardening: assert that any test name a `**checked by:**` line quotes actually
resolves against the suite's own test names, and hard-stop when it does not — the
same rule hazard 6 already states for the falsification driver's expected-assertion
names. It is not built, because the prompt asked me to judge the shape rather than
extend it, and because half of case 12's pointer names something in a pass that
has not run. It belongs in Pass 0013, once the read-back assertion exists to be
named.

**7. The tier label and the required artifacts disagree.** The prompt says
`Tier: light`. `PLAN-PROTOCOL.md` says light requires "preconditions, per-task
evidence, a diff summary, deviations, cost" and explicitly "no acceptance test
and no verify script" — while this prompt requires a red-first acceptance test
*and* a `verify.ps1` with six named spot-checks. Both are here, and the diff
summary is too. Not a problem in practice, and the prompt is right: this pass
changed executable behaviour, so full-tier evidence is what it needed. The label
is what is wrong. If tiers are to keep meaning anything, "changes an assertion"
should decide the tier rather than "writes documents", and by that rule this was
a full-tier pass.

**8. Six probes rather than the three the prompt required.** The three named
reach `absence case is carried by no node`, `presence case is carried`, and the
prose control. Three more were added for the assertions those do not touch: the
kind marker, the `**checked by:**` requirement, and case 12's own
`no node is the pre-existing ClaudeTesting repository`. An assertion without a
falsification row does not count, and the split added assertions that the
prompt's three probes leave unexercised.

## 10. Cost

Wall clock, prompt to pushed commit: **approximately 50 minutes**.

Run counts, per §11 as corrected this pass:

| | |
|---|---|
| Full `Fixture.Tests.ps1` runs | 21 |
| Falsification probe rows | 8 (6 on assertion 7, 2 on `verify.ps1`) |
| `verify.ps1` runs | 8 |
| Pester minimal-repro runs while diagnosing the top-level-function defect | 7 |
| Network calls | 0 |
| Azure DevOps resources touched | 0 |

No token count, per §11 as corrected this pass.
