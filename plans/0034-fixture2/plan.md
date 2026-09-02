# Pass 0034 — Decision 0014: the unannotated fixture, the tf skills, v1.1.0

Tier: **full**. The pass changes executable behaviour — five scripts under
`evals/tf/`, three new skills, two edited skills, three version strings — so the
tier is correct as stated and the acceptance test and verify script are
required, not optional.

## 1. Prompt

```
# PASS 0034 — Decision 0014: the unannotated fixture, the tf skills, v1.1.0
Tier: full

## Repositories
- Harness — branch `pass-0034-fixture2` from `main` (`9a2deee…`).
  Decision 0014, fixture-2 source + oracle + comparator wiring, the tf
  skill batch, release v1.1.0.
- (AzDO) `ClaudeTestingTerraform` — three NEW repos for fixture 2.
  Fixture 1's repos are frozen (decision 0011) and untouched.
- PSTerraformGraph, PSGraphRender*, PSModuleGraph, ClaudeTesting —
  untouched.

This is a constructive pass: no session gate, no blind phase, read
anything. The blindness it creates is for tf-003, not for itself.

## Preconditions
Sync; trees clean; branch created; `$env:AZDO_PAT` set ("set" only);
no tag `v1.1.0`; `decisions/0014-*` absent; the three fixture-2 repo
names below absent from the AzDO project; the 0033 sanitization
scanner exists (the tooling behind `tf-fixture-comments.txt` — locate
it in plans/0033; if it was ad-hoc commands rather than a script,
promote it to `evals/tf/Test-FixtureSanitization.ps1` as task 4's
first step).

## Acceptance test — red first
`plans/0034-fixture2/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0034 delivered' {
        It 'decision 0014 exists' {
            Test-Path "$RepoRoot/decisions/0014-second-unannotated-fixture.md" | Should -BeTrue }
        It 'fixture-2 source committed' {
            foreach ($r in 'TfSiteCore','TfSiteEdge','TfSiteOps') {
                Test-Path "$RepoRoot/evals/tf/fixture2/repos/$r/main.tf" | Should -BeTrue } }
        It 'fixture-2 oracle and cases exist' {
            Test-Path "$RepoRoot/evals/tf/fixture2/expected-graph.json" | Should -BeTrue
            Test-Path "$RepoRoot/evals/tf/fixture2/cases.md" | Should -BeTrue }
        It 'sanitization scan of fixture 2 is clean' {
            (Get-Content "$RepoRoot/plans/0034-fixture2/sanitization.txt" -Raw) |
                Should -Match 'FIXTURE2 SANITIZATION: clean' }
        It 'oracle falsified' {
            (Get-Content "$RepoRoot/plans/0034-fixture2/mutations2.txt" -Raw) |
                Should -Match 'DETECTED: 7 / 7' }
        It 'read-back verified' {
            (Get-Content "$RepoRoot/plans/0034-fixture2/readback2.txt" -Raw) |
                Should -Match 'BYTE-IDENTICAL' }
        It 'tf skill batch exists' {
            (Get-ChildItem "$RepoRoot/skills" -Directory |
                Where-Object Name -like 'tf-*').Count | Should -BeGreaterOrEqual 2 }
        It 'the two candidate skill lines landed' {
            $b = Get-Content "$RepoRoot/skills/powershell-module-build/SKILL.md","$RepoRoot/skills/powershell-module-scaffold/SKILL.md","$RepoRoot/skills/azdo-rest/SKILL.md" -Raw
            ($b -join ' ') | Should -Match 'StrictMode'
            ($b -join ' ') | Should -Match 'Join-Path' }
        It 'manifest is 1.1.0 with a CHANGELOG entry' {
            (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version |
                Should -Be '1.1.0'
            (Get-Content "$RepoRoot/CHANGELOG.md" -Raw) | Should -Match '(?m)^## 1\.1\.0' }
        It 'v1.1.0 on the remote' {
            (git ls-remote --tags origin 'v1.1.0*') | Should -Not -BeNullOrEmpty }
    }

Run it; report the red. Green at start stops the pass.

## Plan (∥ marked; push per group)
- [ ] 1. Acceptance red.
- [ ] 2. **Decision 0014**,
      `decisions/0014-second-unannotated-fixture.md`: records the 0033
      scan findings (case-naming comments, the absence-case
      description, the numbered arrow diagram, the README path pointer
      into cases.md); that fixture 1 stays frozen and annotated —
      tf-001/002's referent is preserved and their blindness bound is
      disclosed, not repaired; that fixture 2 is built unannotated for
      measurement, with the sanitization scanner as a standing gate;
      that measurement runs (tf-003+) target fixture 2 while fixture 1
      remains the deliverable-line example; and that this unblocks the
      backlog-9 tf skills, which may now encode fixture-1 lessons
      because fixture 2 has never been seen by anything. Alternatives
      rejected: disclose-and-run (permanent asterisk on the
      generalisation measurement); amend fixture 1 (destroys the
      tf-001/002 referent). The costed options from the 0033 plan are
      cited.
- [ ] 3. **Fixture 2** under `evals/tf/fixture2/repos/` — repos
      `TfSiteCore`, `TfSiteEdge`, `TfSiteOps` (∥ one job per repo,
      serial cross-wiring). Same mechanism classes as fixture 1,
      DIFFERENT surface everywhere: different topology (e.g. four-level
      nesting somewhere, a diamond module dependency, two unresolved
      sources instead of one, the cross-repo output reference through a
      different construct), different domain vocabulary (site/edge/ops,
      not network/app/shared), different provider mix from the
      auth-free set, different variable names, different pipeline pins.
      Sanitization is a design rule, not a cleanup: no comment, string,
      identifier, README line, or commit message may reference cases,
      the oracle, absence/presence, "graph", or point into the harness.
      Each repo's README describes the module as a module, nothing
      else. `versions.tf`, `.gitattributes` LF, fixture-1 conventions
      minus the annotations.
- [ ] 4. **Oracle + cases + falsification.**
      `evals/tf/fixture2/cases.md` (harness-side ONLY — case knowledge
      lives here now) with the case list covering the same mechanism
      classes; hand-author `expected-graph.json` in producer-contract
      shape, battery-validated. Run the sanitization scanner against
      the fixture-2 SOURCE → `plans/0034-fixture2/sanitization.txt`
      ending `FIXTURE2 SANITIZATION: clean` — falsify the scanner
      first if newly promoted (plant one case-comment in a scratch
      copy, watch it flag, remove). Wire `Compare-TfGraph.ps1` /
      `Mutate-TfGraph.ps1` to fixture 2 (parameterize if hard-wired;
      fixture-1 tests stay green — both suites run). Mutations: 7/7
      detected → `mutations2.txt`; control oracle-vs-self = 0.
- [ ] 5. **Push + freeze.** Create the three AzDO repos, push (∥, ≤8
      concurrent, retry-on-429), byte read-back → `readback2.txt`
      `BYTE-IDENTICAL`; record the frozen SHAs in decision 0014
      (amend the file, note the amendment inline) and LEDGER Pins.
      From this moment fixture 2 is frozen: changes only by new
      decision.
- [ ] 6. **The tf skill batch (backlog 9, unblocked).** From
      runs/tf-001 findings and the tf-001/002 journals, author the
      proposed `tf-<role>` skills (the three from tf-001's findings —
      names per the 0007 taxonomy; consolidate if two overlap, say
      so). Ground every line in a cited finding; nothing speculative.
      Plus the two candidate lines from run 007 Part 4 into the
      generic skills where each belongs: StrictMode-safe reads of
      possibly-absent properties (the dropped empty repository, one
      level up), and Join-Path against already-rooted paths. These
      are installed-surface changes — that is why this pass releases.
- [ ] 7. **Release v1.1.0** per decision 0013: bump all three version
      strings (LEDGER item 28's rule), CHANGELOG `## 1.1.0`
      user-facing (new tf skills; two hardening lines in existing
      skills; no command changes), README install pin → `@v1.1.0`,
      annotated tag, message naming the skill additions and that
      commands are unchanged. Push branch + tag.
- [ ] 8. **Item 19 docs** ∥: chapter 02 (the second-fixture stage now
      exists in the worked example), docs/testing (fixture 2, the
      sanitization gate, which suite measures what), chapter 04 (the
      fixture-annotation story completes: fixture 1 disclosed,
      fixture 2 designed clean). Acceptance green; plan/verify/journal;
      LEDGER (decision 0014 pinned SHAs; backlog 9 CLOSED; tf-003 top,
      now unblocked, pins v1.1.0; consume next free numbers only).
      Fast-forward main per 0009, score-free subject.

## Named spot-checks — verify.ps1 re-derives
1. Fresh clone: both fixture suites green (fixture-1 tests unmoved at
   15/15; fixture-2 comparator oracle-vs-self 0).
2. Verify regenerates fixture-2 mutations 2 and 6 itself; detection
   asserted.
3. Sanitization scanner re-run against a fresh clone of one AzDO
   fixture-2 repo (PAT-gated, loud skip without): clean. -FailCheck:
   plant a case-comment in the scratch clone, scanner flags it.
4. Read-back re-derived for one fixture-2 repo (PAT-gated).
5. `git diff v1.0.1..v1.1.0 -- commands/` empty; skills diff contains
   ONLY the new tf-* directories and the two cited hardening lines.
6. Fixture-1 repos at their decision-0012 SHAs, zero builds queued
   anywhere (PAT-gated).

## Constraints
Fixture 1 and its AzDO repos untouched. ClaudeTesting untouched. Never
queue/run/trigger anything. PAT hygiene absolute. No conformance or
comparator assertion weakened — parameterization must leave fixture-1
results byte-stable. Case knowledge lives only in
`evals/tf/fixture2/cases.md` and the oracle; if writing a fixture file
ever requires explaining a case, the explanation goes there, never in
the fixture.

## Report back
Decision 0014 summary line, fixture-2 frozen SHAs, sanitization +
mutations + readback verdicts, the tf skill names with their grounding
findings, v1.1.0 confirmation, pushed SHAs.
```

## 2. Preconditions

| Precondition | Command | Result |
|---|---|---|
| Sync | `git fetch --all --tags --prune`; `git rev-parse HEAD origin/main` | both `9a2deee2a6b6d8684326771a66d3b05c21d22690` — **in sync** |
| Tree clean | `git status --porcelain` | empty |
| Branch created | `git checkout -b pass-0034-fixture2` | `Switched to a new branch 'pass-0034-fixture2'` |
| `$env:AZDO_PAT` set | length only, never the value | `AZDO_PAT: set (length 84)` |
| No tag `v1.1.0` | `git tag -l` | `v1.0.0`, `v1.0.1` only |
| `decisions/0014-*` absent | `ls decisions/` | 0001–0013 only |
| Fixture-2 repo names absent | `GET /git/repositories?api-version=7.1` | project held `ClaudeTestingTerraform`, `TfFixtureApp`, `TfFixtureNetwork`, `TfFixtureShared`. **`TfSiteCore`, `TfSiteEdge`, `TfSiteOps` all ABSENT** |
| 0033 sanitization scanner exists | `grep -n -i 'scan\|scanner' plans/0033-honest-headline/plan.md`; `ls scratch/` | **It does not.** The 0033 plan describes the scan as *"read-only, 40 files, every comment, every `description` string, every README"* and names no script; nothing in `scratch/` corresponds. **It was reading, not tooling** — so task 4's first step applies and it was promoted to `evals/tf/Test-FixtureSanitization.ps1`. |

The last row is the only precondition that did not hold as written, and the
prompt anticipated it explicitly.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| git | 2.41.0.windows.1 |
| OS | Windows 11 Home 10.0.26200 |
| Claude Code | version not captured — the `claude` CLI is not on PATH on this machine, which `Publish-Local.ps1` also reports and skips its schema check over |
| Model | claude-opus-5[1m] |
| Branch | `pass-0034-fixture2`, cut from `main` |
| HEAD at start | `9a2deee2a6b6d8684326771a66d3b05c21d22690` |

## 4. Acceptance test — red first

`plans/0034-fixture2/accept.Tests.ps1`, written exactly as the prompt supplies
it, run before any other work:

```
Invoke-Pester -Path plans/0034-fixture2/accept.Tests.ps1
```

```
ACCEPTANCE RED (pass 0034, before any work)
Total: 10  Passed: 0  Failed: 10
Failed  decision 0014 exists
Failed  fixture-2 source committed
Failed  fixture-2 oracle and cases exist
Failed  sanitization scan of fixture 2 is clean
Failed  oracle falsified
Failed  read-back verified
Failed  tf skill batch exists
Failed  the two candidate skill lines landed
Failed  manifest is 1.1.0 with a CHANGELOG entry
Failed  v1.1.0 on the remote
```

Committed as [`accept-red.txt`](accept-red.txt). Ten of ten red; nothing was
already satisfied.

## 5. Tasks

### - [x] 1. Acceptance red

Above. Commit `03c0c73`.

### - [x] 2. Decision 0014

[`decisions/0014-second-unannotated-fixture.md`](../../decisions/0014-second-unannotated-fixture.md),
commit `5748386` (body) and `b63392d` (the SHA amendment).

It records all four of the 0033 findings the prompt names, each quoted with its
file and line: the `Case 3` comment naming the case *and* decision 0012; the
`TfFixtureShared/README.md:4-5` pointer at `evals/tf/fixture/cases.md` by path;
the `unused_retention_days` description spelling out *"The absence case: a graph
that invents a reference for this is wrong"*; and the numbered arrow diagram at
`TfFixtureApp/main.tf:5` with its *"Link one."* / *"Link two."* markers.

It settles: fixture 1 frozen and annotated, bound disclosed not repaired;
fixture 2 unannotated with the scanner as a standing gate; measurement runs
target fixture 2 while fixture 1 stays the deliverable-line example; backlog 9
unblocked, with the reason stated as a fact about time rather than an argument —
fixture 2 was authored after tf-001 and tf-002 ran and after their findings were
written down.

Alternatives rejected, both with their cost: disclose-and-run (spends the one
generalisation measurement on a fixture that labels its own cases) and amending
fixture 1 (destroys the tf-001/002 referent). Both cite
`plans/0033-honest-headline/tf-fixture-comments.txt`, which costed all three and
took none.

**Written after tasks 3–5 rather than before them.** See Deviations 1.

### - [x] 3. Fixture 2

`evals/tf/fixture2/repos/` — 46 files, commit `105b4f1`.

```
TfSiteCore   13 files    root + modules/label + modules/policy
TfSiteEdge   16 files    root + modules/edge/modules/pop/modules/probe (4 levels)
TfSiteOps    17 files    root + collector + reporter + common (a diamond)
```

Every mechanism class of fixture 1, on a different surface:

| | Fixture 1 | Fixture 2 |
|---|---|---|
| Vocabulary | network / app / shared | site / edge / ops |
| Deepest nesting | 3 module levels | **4** |
| Topology | a tree; every module's caller is its parent | a **diamond**; `modules/common` is called by two siblings and parented by neither |
| Cross-repo output ref | into two `local`s, through a root-module call | into a `local` **and** two `output`s, through a root-module call **and** a `//subdirectory` call |
| Unresolved sources | one, a relative path | **two** — a relative path, and a `git::` URL naming a repository that does not exist |
| Providers | random, time, null, local | tls, archive, http, external |
| `required_version` | `>= 1.3.0, < 2.0.0` / `>= 1.5.0` / `~> 1.0.11` | `>= 1.6.0` / `~> 1.7.0` / `>= 1.4.0, < 1.10.0` |
| Pipeline pins | 0.13.7, 1.0.11, 1.5.7, 1.9.8 | 1.4.6, 1.6.6, 1.7.5, 1.8.5 |

Sanitization was applied as a design rule while writing, not afterwards: no
file carries a comment about what anything is a case for, and the READMEs
describe each repository as a set of modules with inputs and outputs. Fixture
1's *"Nothing here is ever applied"* and *"This pipeline is created and never
queued"* safety comments were **not** copied — `trigger: none` and `pr: none` in
the YAML make the same statement mechanically, and no pipeline definitions were
created (Deviations 3). `.gitattributes` carries `* text=auto eol=lf` in all
three, as fixture 1 does.

### - [x] 4. Oracle, cases, sanitization, falsification

**The scanner, promoted first.** `evals/tf/Test-FixtureSanitization.ps1`,
commit `1e9e110`. 38 patterns in four categories — harness/oracle pointers, case
vocabulary, graph/producer vocabulary, measurement vocabulary. Commit messages
are in scope and are read from `Get-TfFixtureCommitMessage`, the function
`Publish-TfFixture.ps1` pushes with, so the scanned message and the pushed
message cannot drift. Two allowlist entries are printed in every report rather
than left implicit: `edge` singular (this fixture's domain vocabulary; the
plural `edges` is refused) and `presence` only inside `point(s) of presence`.

**The oracle**, `evals/tf/fixture2/expected-graph.json` — hand-authored from
reading the configuration, never produced by parsing it. Re-derived counts:

```
nodes: 99  edges: 88
kinds: passes-to=27  references=47  sources=14
per-scope node types:
  TfSiteCore   repository=1 module=3 variable=9  local=3 output=7  provider=2  TOTAL=25
  TfSiteEdge   repository=1 module=5 variable=15 local=4 output=13 provider=2  TOTAL=40
  TfSiteOps    repository=1 module=5 variable=11 local=5 output=10 provider=2  TOTAL=34
duplicate ids: 0        unresolvable parentId: 0
unresolvable endpoints: 0   depth fields: 0
duplicate (from,to,kind) triples: none
cross-repository edges: 13
variables with no outgoing edge:
  TfSiteCore:.#var.archive_retention_weeks  (incoming: False)
```

Exactly one node in the fixture has neither an incoming nor an outgoing edge,
and it is the absence case. Two others were found this way and repaired — see
Deviations 4.

**Battery-validated**, against the consumer's own battery rather than a copy:

```
Invoke-Pester -Container (New-PesterContainer `
  -Path ../PSGraphRenderToHtml/tests/ProducerContract.Battery.ps1 `
  -Data @{ GraphPath = evals/tf/fixture2/expected-graph.json })

Tests Passed: 7, Failed: 0
  [+] is valid against the producer contract, with every violation named
  [+] is not empty
  [+] states its own provenance
  [+] carries no node that stores its own depth
  [+] maps to a view model that satisfies PSGraphRender contract 1.1.0
  [+] derives a depth for every node
  [+] carries every unresolved reference through rather than dropping it
```

**`evals/tf/fixture2/cases.md`** carries the seven cases, the id scheme, the
containment rule with its new parent-is-not-caller clause, the edge-kind table,
the counts, and — at the end — the list of what may never be written into the
fixture. It states in its own text that it is the only place fixture 2's case
knowledge lives.

**Sanitization, fixture 2** ([`sanitization.txt`](sanitization.txt)):

```
SCANNED: 46 file(s) under 3 top-level director(ies):
         TfSiteCore, TfSiteEdge, TfSiteOps
         plus 3 commit message(s) for fixture2.
FINDINGS: none.

PLANTED into the copy at TfSiteCore/main.tf:1
  # Case 6, the absence case: a graph that invents a reference for this is wrong.
CAUGHT: 3 finding(s) on the planted line, across these rules:
  [\babsence\b]  B. names a case or its answer
  [\bcases?\b]   B. names a case or its answer
  [\bgraphs?\b]  C. graph or producer vocabulary
FALSIFICATION PASSED - the scanner can fail.

FIXTURE2 SANITIZATION: clean
FIXTURE2 FALSIFICATION: the scanner was shown to fail
```

**Sanitization, fixture 1 — the discriminating control**
([`sanitization-fixture1-control.txt`](sanitization-fixture1-control.txt)):

```
FINDINGS: 94
FIXTURE1 SANITIZATION: 94 finding(s)          exit 1
```

among them the `evals/tf/fixture/cases.md` pointer, the `Case 3` comment,
`TfFixtureApp/main.tf:12  [\blink (one|two|three|four|five)\b]  # variable ->
local. Link one.` and `TfFixtureApp/main.tf:30  [\babsence\b]`. Planting a
comment proves the scanner reacts; **94 findings on a real annotated fixture and
0 on the new one proves it discriminates**, which is the claim that matters.

**Comparator wiring.** `Compare-TfGraph.ps1` needed no change — it already takes
`-Expected` and `-Actual`. `Mutate-TfGraph.ps1`,
`Invoke-TfOracleFalsification.ps1`, `Publish-TfFixture.ps1`,
`Test-TfFixtureReadBack.ps1` and `TfAzdoClient.ps1` gained a `-Fixture` switch
**defaulting to `fixture1`**, so no caller written before this pass changes
behaviour.

Fixture 2's mutation targets are not translations of fixture 1's. Each aims at a
mechanism fixture 2 has and fixture 1 does not:

| Mutation | Fixture-2 target | Why that one |
|---|---|---|
| `missing-node` | `TfSiteOps:modules/common#output.tag` | the output both sides of the diamond read |
| `wrong-attribute` | `TfSiteOps:.#provider.archive` `2.6.0` → `9.9.9` | the same provider is `~> 2.6` in TfSiteCore; a producer keying providers by name alone has already lost |
| `wrong-parent` | `TfSiteOps:modules/common` → parented to a **caller** | containment taken from the call rather than the path — impossible to pose in fixture 1 |
| `missing-edge` / `wrong-edge-kind` | `pop#var.probe_window` → `probe#var.window` | the hop where the value is **renamed** |
| `extra-edge` | out of `archive_retention_weeks` | exactly what a producer inventing an edge per declaration emits |

**Falsification, fixture 2** ([`mutations2.txt`](mutations2.txt)):

```
CONTROL FIRST - the oracle against itself must report ZERO differences.
IsMatch:          True
compared:         99 nodes, 88 edges
CONTROL GREEN
... seven mutations, each LANDED and each detected ...
distinct categories exercised: 7 of 7
DETECTED: 7 / 7                                   exit 0
```

**Both suites run, and fixture 1 is byte-stable.** The fixture-1 falsification
was re-run after the parameterization and compared line by line against the
committed `plans/0030-release/mutations.txt`:

```
FIXTURE 1 FALSIFICATION REPORT: byte-identical to plans/0030-release/mutations.txt
  (timestamp/oracle-path/fixture lines excluded)

Compare-TfGraph.Tests.ps1: Total=15 Passed=15 Failed=0
```

No assertion was weakened: fixture 1's numbers, categories and report text are
unchanged, and its suite is still 15/15.

### - [x] 5. Push and freeze

Dry run first:

```
./evals/tf/Publish-TfFixture.ps1 -Fixture fixture2 -WhatIf
What if: ... "create the repository and push 13 file(s)" on target "TfSiteCore".
What if: ... "create the repository and push 16 file(s)" on target "TfSiteEdge".
What if: ... "create the repository and push 17 file(s)" on target "TfSiteOps".
```

Then the push — one API call per repository, so none ever exists
half-populated, three concurrent on ThreadJob:

```
TfSiteCore   created=True pushed=True files=13  a228e78c247d2d4367303f303c4363d9906e06f2
TfSiteEdge   created=True pushed=True files=16  1ae66c2712f799a69304cb4364e91e4d10d694c4
TfSiteOps    created=True pushed=True files=17  fe27a34f7585b86b6fdbf12b609e17d4cb0f4b83
```

Read-back ([`readback2.txt`](readback2.txt)) — fresh clone of each, every file
hashed on both sides with line endings normalised to LF, compared in both
directions:

```
REPOSITORY: TfSiteCore   cloned at a228e78c...   harness files: 13   remote files: 13
REPOSITORY: TfSiteEdge   cloned at 1ae66c27...   harness files: 16   remote files: 16
REPOSITORY: TfSiteOps    cloned at fe27a34f...   harness files: 17   remote files: 17
46 file(s) compared across 3 repositories.
BYTE-IDENTICAL
```

The SHAs are recorded in decision 0014 as an **amendment in its own commit**
(`b63392d`), so the git history shows the decision was written before the push
rather than around it, and in `LEDGER.md`'s Pins section.

The same check confirmed what the pass was told not to disturb:

```
TfFixtureApp      44ea9338ff35aef328bfa8d51835fc32bea590dd   (decision-0012 SHA)
TfFixtureNetwork  24f27be92e583b6dfc9208bca42f8ec0baf5004b   (decision-0012 SHA)
TfFixtureShared   0af6ee33854bedb4147d0b13cc6db1311687775b   (decision-0012 SHA)
pipeline definitions: 4 — all four are fixture 1's
builds (any state, top 20): 0
```

**Fixture 2 is frozen from this point.** Changes require a new decision.

### - [x] 6. The tf skill batch, and the two hardening lines

Three skills, named per decision 0007's pattern — `powershell-module-<role>` for
the generic, `azdo-<role>` for the AzDO target, and now `tf-<role>` for
Terraform. **They were not consolidated**: `tf-module-resolve` answers *what does
this source string point at* and `tf-graph-assembly` answers *what shape do the
declarations go into*, and the one place they touch — an unresolvable source
becoming a node plus a flagged edge — is resolution, so it lives in
`tf-module-resolve` with a cross-reference from the other.

| Skill | Grounding finding |
|---|---|
| [`tf-hcl-parse`](../../skills/tf-hcl-parse/SKILL.md) | tf-001 **B-1** — the four constructs that defeat a whole-file regex; `required_providers` as block *and* attribute; the expression's raw text. *"iterations 2 and 3 of this run were exactly these three defects, and together they were 63 of the 94 differences."* Plus tf-001 **D-1**, the `[*]` splat the reference pattern lost — *"it was the 31st difference."* |
| [`tf-module-resolve`](../../skills/tf-module-resolve/SKILL.md) | tf-001 **B-2** — registry address versus relative path and the leading-dot guard (*"cost 12 node differences and 6 edges in iteration 1, and it fails silently"*); the `//` past the scheme's own `//`; unresolvable source as node plus flagged edge. Plus tf-002 **D** — the `git::` source with no `//subdirectory` naming a repository root, *"right by construction and tested by nothing."* |
| [`tf-graph-assembly`](../../skills/tf-graph-assembly/SKILL.md) | tf-001 **B-3** — containment is the directory tree not the calls; a module's parent is the nearest module above it *in its own path*, which is not its caller; a module nothing calls is still contained; deduplicating because one value referenced twice in one expression is one fact. |

No fixture-specific node id, repository name or case number appears in any of
the three. Every rule is stated as a property of Terraform, with the run that
paid for it cited as evidence rather than as content.

**The two hardening lines**, each into the skill whose subject it is:

- `skills/azdo-rest/SKILL.md` — *"Read a response property that may not be
  there, or lose the object"*, from run 007 **D-1**. Includes the half that is
  easy to lose: the regression test must mock the failure by **omitting** the
  property, because an object setting it to `$null` does not reproduce it.
- `skills/powershell-module-scaffold/SKILL.md` — *"A command that takes a
  `-Path` must handle an absolute one"*, from run 007 **D-2**. Both halves:
  `IsPathRooted` before `Join-Path`, and `(Get-Location).ProviderPath` rather
  than the process working directory, which PowerShell does not keep in step
  with `Set-Location`.

LEDGER item 26 suggested *"`powershell-module-analysis` or the AzDO client
skill"* and item 27 suggested *"`powershell-module-commands`"*. Neither of those
skills exists; the two chosen are the AzDO client skill and the skill that owns
command authoring and the tests-mirror-src rule. See Deviations 5.

### - [x] 7. Release v1.1.0

All three version strings, per LEDGER item 28's rule that there is no single
version line:

```
.claude-plugin/plugin.json           "version": "1.1.0"
.claude-plugin/marketplace.json      metadata.version    "1.1.0"
.claude-plugin/marketplace.json      plugins[0].version  "1.1.0"
```

Validated by the tool that enforces the pair it knows about:

```
tools/publish/Publish-Local.ps1
Staged 17 skills and 2 commands.
Committed marketplace validated: plugin entry psmodule 1.1.0 source './'
  version agrees with .claude-plugin/plugin.json.                        exit 0
```

CHANGELOG `## 1.1.0`, written for someone who has not read the repository:
what the three skills carry, the two hardening lines, **"Your commands are
unchanged"**, and a *What this release does not claim* section saying plainly
that the Terraform skills are unmeasured and that tf-003 is the run that would
measure them. README install pin moved to `@v1.1.0` in all three places it
appears.

MINOR is the right increment under decision 0013's rule — *MINOR adds skills,
commands or conventions* — and nothing a consumer relies on breaks.

### - [x] 8. Documents, LEDGER, journal, acceptance, verify

| Document | What landed |
|---|---|
| ch. 02 | new **§3b, "A second fixture, once the first one has taught you something"** — the third fixture property (a fixture must not answer its own questions), what a second fixture must and must not be, and the fact that skills distilled from a first fixture cannot honestly be scored against it. New dependency line: *3 before 3b, and 3b before any skill distilled from 3's findings can be measured.* |
| ch. 04 | new **§"How that ended, so the advice has a price attached"** under the chatty-fixture section — the three options and what each cost, sanitization as a design rule including commit messages, and the gate with both its falsifications. Ends on *"a bound you have disclosed and a bound you have removed are different states, and only one of them costs a fixture."* |
| docs/testing | the layer table gains a **sixth row** (Sanitization) and the heading its count; §5 gains **"A second Terraform fixture, and a gate on what a fixture may say"** with a which-fixture-answers-which-question table; §7 gains the `-Fixture` and `-FailCheck` invocations; the tf-003-is-blocked paragraph now says the block is lifted. |
| ch. 07 / 08 / 09, README, SECURITY | the skill count, fourteen → **seventeen**, *only* where it means the roster. The *fourteen* in ablation sentences is deliberate and now reads "the fourteen skills the ladder measured"; the *fourteen house-style assertions* is a different fourteen and was not touched. Chapter 09's captured transcript is **left as captured**, with its version and the new counts stated beside it. |
| README | three new skill rows, `tf-<role>` added to the taxonomy paragraph, and a note saying why the three were withheld from v1.0.x and what changed. |
| LEDGER | passes, runs (tf-003's full precondition list), versions, Pins (fixture-2 SHAs), backlog 6 restated as unblocked, **9 / 26 / 27 CLOSED**, 28 honoured-not-closed, 19 honoured-and-open, and **29 / 30 / 31 consumed**. |

## 6. Acceptance test — green

```
Invoke-Pester -Path plans/0034-fixture2/accept.Tests.ps1

Total: 10  Passed: 10  Failed: 0
Passed  decision 0014 exists
Passed  fixture-2 source committed
Passed  fixture-2 oracle and cases exist
Passed  sanitization scan of fixture 2 is clean
Passed  oracle falsified
Passed  read-back verified
Passed  tf skill batch exists
Passed  the two candidate skill lines landed
Passed  manifest is 1.1.0 with a CHANGELOG entry
Passed  v1.1.0 on the remote
```

The tenth assertion could only pass after the tag existed, which is decision
0013's stated exception: *"a release pass whose acceptance test asserts the tag
exists runs the tag creation as a task and the assertion re-runs after it."*
Before tagging it stood at **9 / 10**, with only that assertion red.

## 7. Command transcript

```powershell
# --- preconditions
git fetch --all --tags --prune
git rev-parse HEAD origin/main
git status --porcelain
git tag -l
git checkout -b pass-0034-fixture2
pwsh -NoProfile -Command '. ./evals/tf/TfAzdoClient.ps1; $b = Get-TfAzdoBaseUri; (Invoke-TfAzdoJson -Uri "$b/git/repositories?api-version=7.1").value.name'

# --- acceptance, red
Invoke-Pester -Path plans/0034-fixture2/accept.Tests.ps1 -PassThru -Output Detailed

# --- oracle validation (task 4)
pwsh -NoProfile -Command '$g=(Get-Content evals/tf/fixture2/expected-graph.json -Raw|ConvertFrom-Json).graph; $g.nodes.Count; $g.edges.Count'
Invoke-Pester -Container (New-PesterContainer `
    -Path ../PSGraphRenderToHtml/tests/ProducerContract.Battery.ps1 `
    -Data @{ GraphPath = (Resolve-Path evals/tf/fixture2/expected-graph.json).Path }) -Output Detailed

# --- sanitization: fixture 2 clean and falsified, fixture 1 as the control
./evals/tf/Test-FixtureSanitization.ps1 -Fixture fixture2 -FailCheck -ReportPath plans/0034-fixture2/sanitization.txt
./evals/tf/Test-FixtureSanitization.ps1 -Fixture fixture1 -ReportPath plans/0034-fixture2/sanitization-fixture1-control.txt

# --- falsification: fixture 2, and fixture 1 for byte-stability
./evals/tf/Invoke-TfOracleFalsification.ps1 -Fixture fixture2 -ReportPath plans/0034-fixture2/mutations2.txt
./evals/tf/Invoke-TfOracleFalsification.ps1 -Fixture fixture1 -ReportPath $tmp
Compare-Object (Get-Content plans/0030-release/mutations.txt) (Get-Content $tmp)
Invoke-Pester -Path evals/tf/Compare-TfGraph.Tests.ps1 -PassThru -Output None

# --- push and freeze (task 5)
./evals/tf/Publish-TfFixture.ps1 -Fixture fixture2 -WhatIf
./evals/tf/Publish-TfFixture.ps1 -Fixture fixture2
./evals/tf/Test-TfFixtureReadBack.ps1 -Fixture fixture2 -ReportPath plans/0034-fixture2/readback2.txt

# --- constraint checks: fixture 1 untouched, nothing queued
pwsh -NoProfile -Command '. ./evals/tf/TfAzdoClient.ps1; $b = Get-TfAzdoBaseUri;
  (Invoke-TfAzdoJson -Uri "$b/build/definitions?api-version=7.1").value.name;
  (Invoke-TfAzdoJson -Uri "$b/build/builds?api-version=7.1&$top=20").value.Count'

# --- sanitization against a fresh clone of a pushed repository
git -c "http.extraHeader=$auth" clone --quiet https://dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfSiteOps $work/TfSiteOps
./evals/tf/Test-FixtureSanitization.ps1 -Fixture fixture2 -FixtureRoot $work -Label 'FIXTURE2-CLONE' -FailCheck

# --- release (task 7)
pwsh -NoProfile -File ./tools/publish/Publish-Local.ps1

# --- commits, tag, push
git add plans/0034-fixture2/accept.Tests.ps1 plans/0034-fixture2/accept-red.txt
git commit -m "Pass 0034 opens: the acceptance test, red on all ten"
git add decisions/0014-second-unannotated-fixture.md
git commit -m "Record decision 0014: fixture 1 stays annotated, fixture 2 is written mute"
git add evals/tf/fixture2/
git commit -m "Author fixture 2: three repositories, an oracle, and the case list"
git add evals/tf/Test-FixtureSanitization.ps1 evals/tf/TfAzdoClient.ps1 evals/tf/Mutate-TfGraph.ps1 `
        evals/tf/Invoke-TfOracleFalsification.ps1 evals/tf/Publish-TfFixture.ps1 `
        evals/tf/Test-TfFixtureReadBack.ps1 plans/0034-fixture2/*.txt
git commit -m "Promote the sanitization scan to a gate, and wire the tooling to fixture 2"
git add plans/0034-fixture2/readback2.txt decisions/0014-second-unannotated-fixture.md
git commit -m "Publish fixture 2 and freeze it at the read-back SHAs"
git push -u origin pass-0034-fixture2

git add skills/ README.md SECURITY.md CHANGELOG.md LEDGER.md .claude-plugin/ docs/ journal/ plans/
git commit -m "Write the three Terraform skills, harden two more, and release 1.1.0"
git tag -a v1.1.0 -m "..."
git push origin pass-0034-fixture2
git push origin v1.1.0

# --- acceptance, green; then verify
Invoke-Pester -Path plans/0034-fixture2/accept.Tests.ps1 -PassThru -Output None
pwsh -NoProfile -File plans/0034-fixture2/verify.ps1
pwsh -NoProfile -File plans/0034-fixture2/verify.ps1 -FailCheck

# --- main, per decision 0009
git merge-base --is-ancestor main pass-0034-fixture2
git checkout main && git merge --ff-only pass-0034-fixture2 && git push origin main
```

## 8. Verify script

[`verify.ps1`](verify.ps1), committed beside this plan. It is too long to
reproduce here without creating a second copy that can disagree with the first —
`evals/HARNESS.md` hazard 6 applied to the one artifact whose job is to disprove
this document.

What it checks, by the prompt's own numbering:

1. **Both fixture suites, from a fresh clone.** Fixture-1 comparator suite at
   exactly 15/15; fixture-1 oracle still 78 nodes and 59 edges; fixture-2
   control (oracle against itself) at 0 differences; fixture-2 oracle at the
   pinned 99/88; and a structural self-check — unique ids, resolvable parents
   and endpoints, no `depth`, three edge kinds only.
2. **Mutations 2 and 6 regenerated here**, named as well as numbered so a
   reordering cannot silently move what is exercised. Each is asserted to have
   *changed the document* before its detection is trusted. Then the whole
   fixture-2 falsification is re-run for its 7/7, and fixture 1's for its.
3. **Sanitization** — fixture 2 clean with its falsification passing; fixture 1
   reporting findings as the discriminating control; and, PAT-gated, a fresh
   clone of `TfSiteOps` scanned including its **commit message**.
4. **Read-back re-derived** (PAT-gated), asserting `BYTE-IDENTICAL` and each
   repository's frozen SHA.
5. **What the release changed** — the tag on the remote, all three version
   strings, `git diff v1.0.1..v1.1.0 -- commands/` empty, and the `skills/` diff
   containing *exactly* the three new files and the two edited ones. The two
   hardening lines are checked as **content of the diff** (`PSObject.Properties[`
   and `IsPathRooted` among the added lines), not as the existence of a changed
   file.
6. **Fixture 1 untouched** (PAT-gated) — its three SHAs, zero builds of any
   status, no fixture-2 pipeline definitions — plus the half that needs no PAT:
   `git diff v1.0.1..HEAD -- evals/tf/fixture/` empty.
7. The acceptance test, from the clone.

`-FailCheck` runs three probes instead: a duplicated node id in the fixture-2
oracle must turn check 1's control red; a comparator with its `ExtraNode` and
`ExtraEdge` categories renamed must fail check 2; and a case-naming comment
planted in the pushed clone must be caught by check 3. Each probe asserts it
changed its target before the check is re-run, and a probe's verdict is the
*change* it made to the failure list rather than the list's total — so an
unrelated earlier failure cannot be read as a probe firing.

Without `$env:AZDO_PAT`, checks 3 (the clone half), 4 and 6 (the AzDO half)
**skip loudly**: they are named in the summary and the script exits with a
"VERIFIED, with N check(s) SKIPPED" line rather than a plain green.

## 9. Deviations

**1. Tasks 3, 4 and 5 were done before task 2.** The prompt orders the decision
first. The fixture, its oracle, the scanner and the push were completed first,
and decision 0014 was written afterwards. The decision's body was still
committed on its own, before the amendment carrying the SHAs, so the git history
shows the two-step the prompt asked for — but the body describes a fixture that
already existed rather than one being decided on. Nothing in the decision is
different for it; the alternatives it rejects were costed by pass 0033 and not
by this pass. Recorded because the ordering is the kind of thing that reads as
deliberate a year later.

**2. The 0033 sanitization scanner did not exist and was promoted, as the prompt
provided for.** The 0033 plan describes the scan as reading — *"read-only, 40
files, every comment, every `description` string, every README"* — and names no
script; `scratch/` holds nothing corresponding.
`evals/tf/Test-FixtureSanitization.ps1` is new. It is not a transcription: it
mechanises the same reading and, run over fixture 1, finds **94** occurrences
where the prose scan listed roughly twenty findings by severity. Nothing new was
discovered — every one is in the 0033 scan — but the pass-1 count and the
pass-many count are different kinds of fact, and the second is what makes
fixture 2's *clean* mean something.

**3. No Azure DevOps pipeline definitions were created for fixture 2.** The
prompt's task 5 says *"create the three AzDO repos, push"* and nothing about
definitions. Fixture 1 has four, created by pass 0023. Fixture 2 has four
pipeline YAML **files** in its repositories, carrying `trigger: none` and
`pr: none`, and zero definitions. This is deliberate — fewer objects in a
project this pass was told to leave alone, and nothing to queue — and it is an
**asymmetry between the two instruments**: a producer that reads pipelines from
the REST API rather than from repository files sees fixture 1 and not fixture 2.
Recorded as backlog 31, to be settled before tf-003 rather than discovered
during it.

**4. Two variables in the first draft of fixture 2 were declared and used by
nothing, unintentionally.** `TfSiteEdge:modules/edge#var.pop_count` was consumed
only by a `count` meta-argument, and `#var.terminate_tls` by nothing at all.
Both would have been correct as oracle content — fixture 1 has the same shape at
`modules/service#var.worker_count` — but three zero-out-degree variables make
the absence case *less* distinctive, since it stops being the only one. Both were
given a real use (`plan_summary` and a conditional in `endpoint`). The fixture
now has exactly one node with no edge in either direction, and it is case 6.
**Found by an audit, not by a test**: nothing in the harness would have reported
it.

**5. The two hardening lines landed in different skills from the ones the LEDGER
named.** Item 26 suggested `powershell-module-analysis` *or the AzDO client
skill*; item 27 suggested `powershell-module-commands`. `powershell-module-analysis`
and `powershell-module-commands` do not exist — the roster has
`powershell-module-analyzer` (AST analysis that never runs code, which is not
where a REST-response rule belongs) and no commands skill. The StrictMode line
went to `azdo-rest`, which is the AzDO client skill item 26's second option
names. The `Join-Path` line went to `powershell-module-scaffold`, which owns
command authoring and the tests-mirror-src rule the finding argues for. The
acceptance test's own assertion greps exactly
`powershell-module-build`, `powershell-module-scaffold` and `azdo-rest`, so both
placements are inside what the prompt expected.

**6. A defect was found in the scanner by its own falsification, and fixed
before anything was trusted.** `Get-SanitizationFinding` returned
`, @($findings | Sort-Object …)` while its caller wrote `@(Get-SanitizationFinding …)`.
The two idioms compose into a one-element array *holding* an array: `.Count`
reads 1, which looks like one finding, and the first property access throws
*"The property 'Location' cannot be found on this object"* — an error naming the
consumer, not the producer. It surfaced on the first real run. Fixed by dropping
the comma-wrap, with the reason left in the file. Recorded as backlog 30, a
skill-line candidate, not taken.

**7. `evals/tf/Test-TfFixtureCase.ps1` was left fixture-1-only.** The prompt
named `Compare-TfGraph.ps1` and `Mutate-TfGraph.ps1` for wiring and not this
one. It scores a produced graph case by case and is fixture-1 specific
throughout; half-generalising it would have left a script that looks fixture-2
capable and is not. tf-003 needs a counterpart, and it needs the control tf-002
gave the original — score it against a graph known to be wrong in exactly one
case and confirm it fails exactly there. Backlog 29.

**8. Fixture 1's safety comments were not carried into fixture 2.** Fixture 1's
READMEs say *"Nothing here is ever applied"* and its pipeline YAMLs say
*"Definition only. This pipeline is created and never queued."* Pass 0033
classed both as benign. They were still omitted: the design rule says each
repository's README describes the module as a module and nothing else, and
`trigger: none` / `pr: none` makes the same statement in configuration rather
than in prose, where a parser can act on it. No safety was lost — no definitions
exist to queue, and the read-back and the build-list check both confirm it.

**9. The parallelism the plan marks (∥) was structural, not concurrent.** Task
3's three repositories were authored one after another by a single agent; the
`∥` is honoured where the tooling actually does it — `Publish-TfFixture.ps1`
pushes the three on `Start-ThreadJob`, three concurrent against the prompt's
limit of eight, with the client's existing 429 retry. Task 8's documents were
likewise written serially.

## 10. Cost

| | |
|---|---|
| Wall clock | ~2h10m, single session |
| Pester suite runs | 6 (acceptance ×3, producer-contract battery ×1, fixture-1 comparator suite ×2) |
| Falsification runs | 4 (fixture 2 ×2, fixture 1 ×2) |
| Sanitization scans | 6 (fixture 2 source ×3, fixture 1 control ×2, pushed clone ×1) |
| Read-backs | 1, over 46 files |
| AzDO write calls | 6 — three repository creations and three pushes. No other write, and **zero** queue/run/trigger calls |
| AzDO read calls | ~20 — repository lists, refs, build definitions, build list |
| Build invocations | 0. No module was built in this pass |

No token count: the agent cannot measure one from inside the session, and a
number without an artifact behind it does not belong in a plan.
