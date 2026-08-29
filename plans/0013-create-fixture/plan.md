# Pass 0013 — Create the fixture in Azure DevOps

Tier: **full** (creates executable scripts, an acceptance suite, and assertions).

## 1. Prompt

```
# PASS 0013 — Create the fixture in Azure DevOps

Tier: full

Normalises line endings, then pushes four repositories and creates fifteen
pipeline definitions in `ClaudeTesting`, and verifies by read-back.

Read-back proves the push landed. It does not prove the graph is correct. The
hand-authored `expected-graph.json` is the only claim about correctness, and
nothing in this pass may derive it, regenerate it, or treat a green read-back as
confirming it. Keep the two claims apart everywhere in the plan.

`$env:AZDO_PAT` is now set at User scope in the registry, verified at 84
characters from a fresh VS Code integrated terminal. It survives `-NoProfile`.

## Tier rule correction

Your Deviation 7 in Pass 0012 is accepted. Amend `PLAN-PROTOCOL.md`: the tier is
decided by whether the pass changes executable behaviour — an assertion, a
script, a hook, a skill, a manifest, a runner — not by whether it writes
documents. Pass 0012 amended an assertion and was full tier mislabeled as light.
Add that as the worked example.

## Preconditions

Any failure is a hard stop — commit nothing, create nothing, report.

- [ ] On a pass branch, not `main`. Report branch and HEAD.
- [ ] Working tree clean.
- [ ] `Fixture.Tests.ps1` green at 346. Report the count.
- [ ] `evals/functional/AZDO-FIXTURE.md`, `expected-graph.json` and
      `fixture/cases.md` exist. Note the path is `fixture/cases.md`; Pass 0012's
      precondition named it wrongly and you were right to flag rather than
      resolve it.
- [ ] `pwsh --version`, resolved Pester 6.x, OS.
- [ ] `$env:AZDO_PAT` set and non-empty. Report its length and that it is set —
      never the value, never a prefix, never a hash. Expect 84.
- [ ] `GET https://dev.azure.com/jlbalmerjr1/_apis/projects/ClaudeTesting?api-version=7.1`
      returns 200. Report the project id only. A **203** means the PAT is missing
      a scope or expired — Azure DevOps returns a sign-in page rather than a 401.
      Treat 203 as a hard stop and say which it is.
- [ ] List the project's repositories and build definitions. Expected: exactly
      one repository, `ClaudeTesting`, and zero definitions. Anything else is a
      hard stop — report what is there and change nothing.

## Acceptance test — red first

Write `evals/functional/ReadBack.Tests.ps1` before creating anything and run it.
It must be red. Record the red with failure messages. It reads Azure DevOps and
compares against committed files; it never writes.

1. The four fixture repositories exist by name.
2. Each has default branch `main`.
3. Every one of the 30 committed fixture files exists at the same path on `main`
   in its repository, and its content is **byte-identical**. Load-bearing: it is
   the only assertion proving the module will later read what Pass 0011
   authored. Comparison is defined in task 1 and must be stated in the test.
4. No file exists in any of the four repositories other than those 30.
5. All fifteen definitions exist by name, each pointing at the repository and
   YAML path `AZDO-FIXTURE.md` declares.
6. No definition exists beyond those fifteen.
7. Every definition's build count is zero. Nothing has ever run. A safety
   assertion, not a correctness one; it stays in the suite permanently.
8. The `ClaudeTesting` repository exists, is empty, and no definition targets
   it. This is case 12's external half.

## Plan

- [ ] **1.** Fix the CRLF exposure before anything reaches the network. Your
      Pass 0013-preflight measurement was better than my amendment; use its
      shape as the evidence.

      - Evidence is the two-sided byte measurement, not the renormalise. Report
        bytes, CR count and LF count for at least two fixture files, read three
        ways: this working tree, `git show HEAD:<path>`, and a FRESH CLONE of
        the branch. The working tree and blob agree here because these files
        were written into the tree rather than checked out — the gap only
        appears in a clone. Expect roughly 449 → 461 bytes and CR 0 → 12 for
        `p01.yml` in the clone.
      - Add `.gitattributes` at the repository root: `* text=auto`, plus
        `*.yml text eol=lf`, `*.json text eol=lf`, `*.md text eol=lf`,
        `*.ps1 text eol=lf`.
      - Re-clone and re-measure. Both files must return to origin byte counts
        with CR=0, hashes matching.
      - `git add --renormalize .` is corroborating, not load-bearing. Report its
        output; expect no change. Say plainly that a no-op renormalise proves
        blob and working tree agree, and nothing more.
      - A clone-and-compare check needs a short destination path. The scratch
        prefix plus the deepest fixture path exceeds the 260-character limit and
        fails with `Filename too long`. Clone to a short path and record it.
      - `core.autocrlf=true` comes from **system** scope — the Git for Windows
        installer default, confirmed by measurement — so this is what any
        Windows clone gets, not a local misconfiguration.
      - Re-run `Fixture.Tests.ps1`. It must still be 346. Any movement is a
        finding, not something to absorb.
      - State in `AZDO-FIXTURE.md` how assertion 3 compares bytes: read both
        sides as raw bytes with no line-ending translation, compare hashes, and
        name which encoding and which newline the fixture is canonical in.
        Ambiguity here is what makes a byte comparison meaningless.
      - Keep Pass 0012's CRLF regression guard assertion. `.gitattributes` is
        prevention; the assertion is detection, and prevention that nothing
        detects is prevention nobody notices failing.

- [ ] **2.** Write the acceptance test. Run it. Record the red.

- [ ] **3.** Harden the `**checked by:**` pointer, your Pass 0012 reservation.
      Add an assertion that every test name quoted in a `**checked by:**` line
      resolves against a real test name in the suites named — `Fixture.Tests.ps1`
      and now `ReadBack.Tests.ps1`. Hard-stop on one that does not. This is
      hazard 6 for the fourth time and the read-back assertion it names now
      exists. Falsify it: rename a quoted test and confirm red; add prose
      mentioning a test name outside a `**checked by:**` line and confirm green.

- [ ] **4.** Write `evals/functional/Sync-Fixture.ps1`. One script does all
      creation, so the transcript carries one invocation rather than forty-five
      REST calls each bearing an Authorization header.

      - PAT from `$env:AZDO_PAT` only. Never a parameter, never a file, never a
        default. If unset, throw naming the variable.
      - Never write the PAT anywhere: not a log, not a temp file, not a git
        remote URL. Header only. If a command it shells out to would receive the
        PAT as an argument, restructure rather than accept it.
      - `-DryRun` reporting exactly what it would create, so the plan shows
        intent before effect.
      - Idempotent: check existence before creating. Re-running against a
        complete fixture is a no-op reporting "already present" per item.
      - Ordered per `AZDO-FIXTURE.md`: four repositories created and thirty
        files pushed first, then fifteen definitions. Two pipelines declare
        `trigger: - main`, so a push after their definitions exist would queue a
        run. You found this; the ordering is the fix.
      - Pushes bytes as canonicalised in task 1, explicitly, not whatever the
        working tree happens to hold.
      - Never queues, triggers, or runs anything. No POST to any `builds`
        endpoint under any circumstance.
      - Asserts organisation `jlbalmerjr1` and project `ClaudeTesting` at the
        top and refuses otherwise.
      - Emits `runs/001-fixture-create/create-summary.json`: every object,
        whether created or already present, and its Azure DevOps id.

- [ ] **5.** Run `Sync-Fixture.ps1 -DryRun`. Record the full output. This is the
      last point before anything external changes.

- [ ] **6.** Run it for real. Report counts: repositories created, files pushed,
      definitions created.

- [ ] **7.** Run the acceptance test. Record green with per-assertion case
      counts.

- [ ] **8.** Run `Sync-Fixture.ps1` again, unchanged. It must create nothing,
      report every object already present, and leave the acceptance test green.
      Idempotency claimed and not demonstrated is idempotency assumed.

- [ ] **9.** Create `runs/001-fixture-create/` with `create-summary.json`, the
      commands that produced it, and a `README.md` stating what this run is: the
      fixture's creation, not a module output, and no graph JSON because no
      module exists yet.

- [ ] **10.** Update `AZDO-FIXTURE.md` with what creation actually required —
      API versions, endpoints, anything the documented schema got wrong, and the
      rebuild-after-wipe procedure as executed rather than as planned.

- [ ] **11.** Write `evals/functional/TROUBLESHOOTING.md`. This pass ships a
      surface that can fail on someone else's machine, so METHOD.md's
      diagnosability definition of done applies: symptom, the named command that
      reveals why, and the prerequisite check. At minimum — `AZDO_PAT` unset or
      expired; the environment-inheritance trap, since a profile-set variable is
      invisible to `pwsh -NoProfile` and User-scope registry plus a full editor
      restart is what works; PAT lacking Code or Build scope; the 203
      sign-in-page response and why it reads as a parse failure; wrong project
      name; a partially created fixture; and a CRLF round-trip failing assertion
      3, with the command that shows which side normalised.

- [ ] **12.** Record what outlives this pass.

      Correct the PAT-shape scan everywhere it appears, including `verify.ps1`
      and every earlier plan's copy. The pattern assumed a 52-character base32
      token; the actual PAT is 84 characters, mixed-case alphanumeric, measured.
      A scan that cannot match the secret it scans for is worse than no scan,
      because it reports clean. Widen it, re-scan every tracked file and
      everything under `runs/`, and falsify it: plant an 84-character
      alphanumeric string in a scratch copy of a tracked file and confirm the
      scan goes red. This is the fifth check in this project found unable to
      fail, and the first one guarding a live secret.

      `evals/HARNESS.md`: a check asserting the absence of a phrase must be
      case-sensitive and run against a whitespace-collapsed copy, because
      `-match` is case-insensitive — a check for the absence of "Skip the
      corpus" matches "Do not skip the corpus" — and hard-wrapped prose breaks
      phrase matching across lines.

      `TROUBLESHOOTING.md` or `PLAN-PROTOCOL.md`: a top-level `function` in a
      Pester 6.1.0 test file breaks every `BeforeAll` in that file, with the
      misleading loop-label error and the dot-sourced-helper fix.

- [ ] **13.** Run the acceptance test once more. Record green. Commit and push.
      Report the pushed SHA.

## Named spot-checks

`verify.ps1` must independently re-derive, by name:

1. `Fixture.Tests.ps1` green at its full case count, and the count.
2. Read-back assertion 3 over all 30 files, hashing each remote file and each
   committed file independently rather than reading the test's result.
3. Read-back assertion 7: every definition's build count is zero.
4. Read-back assertion 8: `ClaudeTesting` exists, is empty, no definition
   targets it.
5. Case 12's absence: no node in `expected-graph.json` has an id, name or repo
   equal to `ClaudeTesting`.
6. Every `**checked by:**` test name resolves against a real test name.
7. `create-summary.json` lists exactly 4 repositories, 30 files, 15 definitions,
   and every id in it resolves in Azure DevOps.
8. No PAT-shaped string, under the corrected pattern, in any tracked file, in
   `create-summary.json`, or anywhere under `runs/`.

Checks 2, 3, 4 and 7 need the network and `$env:AZDO_PAT`. State that at the top
of the script and **skip** those checks with a clear message when the variable is
unset rather than failing — a reader without a PAT should still get 1, 5, 6 and
8. A skipped check reports as skipped, never as agreeing.

Prove `verify.ps1` capable of failing with at least two probes, each asserting it
changed something before the check runs.

## Constraints

- Organisation `jlbalmerjr1`, project `ClaudeTesting`, nothing else.
- Never queue, run, or trigger a pipeline. Definitions only. No POST to any
  `builds` endpoint.
- Nothing that meters or bills: no Artifacts feeds, no Test Plans, no
  self-hosted or scale-set pools, no service connections, no marketplace
  extensions, no agent pool changes.
- Do not delete, modify, or push to the `ClaudeTesting` repository.
- The PAT is read from `$env:AZDO_PAT`, never echoed, never written to any file,
  never placed in a URL, redacted from every transcript and plan entry. If a
  redaction happens, say that it happened.
- `expected-graph.json` is not modified this pass. Nothing derived from Azure
  DevOps may change it.
- No fixture YAML content changes. Line-ending normalisation in task 1 is the
  sole exception and must not alter any file's parsed content — assert it.
- Push to the pass branch. No tags, no `main`, nothing published.

## Deviations

Required. Flag specifically: any of the fifteen definitions Azure DevOps refuses
to create and why — `p08-cycle` and `p09-unresolved` are expected to be flagged
in the UI, and that is the correct result, not a defect to fix. Also flag
anything `AZDO-FIXTURE.md` got wrong about an endpoint, payload, or ordering,
and whether `git add --renormalize` changed anything.

## Journal

Write `journal/0013-create-fixture.md` from this pass's artifacts using
`journal/TEMPLATE.md`. Capability only.

## Report back

Branch and pushed SHA; the plan path; the three-way byte measurement before and
after `.gitattributes`, and whether `Fixture.Tests.ps1` stayed at 346; red-first
and green output for the read-back test with per-assertion counts; the dry-run
output; created counts for repositories, files and definitions; confirmation the
second `Sync-Fixture.ps1` run created nothing; the falsification result for the
corrected PAT scan; which definitions Azure DevOps flagged and how; and anything
in `AZDO-FIXTURE.md` that turned out wrong.
```

## 2. Preconditions

One failed. It was reported to the operator, who directed that the offending
change be committed alone before the pass began, and gave a standing rule now
recorded in `PLAN-PROTOCOL.md`. Nothing was created and nothing was committed as
pass work until the tree was clean.

| # | Precondition | Command | Result |
|---|---|---|---|
| 1 | On a pass branch | `git rev-parse --abbrev-ref HEAD` / `git rev-parse HEAD` | **pass** — `pass-0009-control-polarity` @ `c9853493b5f8ab0a200be396aaaa4633cc31ccc0` |
| 2 | Working tree clean | `git status --porcelain` | **FAIL** — ` M AI.Agent.Claude.PowerShellModuleBuilder.code-workspace` |
| 3 | `Fixture.Tests.ps1` green at 346 | `Invoke-Pester` | **pass** — `TOTAL=346 PASSED=346 FAILED=0 SKIPPED=0` |
| 4 | Three documents exist | `test -f` each | **pass** — `AZDO-FIXTURE.md` 10,977 B; `fixture/expected-graph.json` 19,474 B; `fixture/cases.md` 15,394 B |
| 5 | pwsh / Pester / OS | `$PSVersionTable`, `Get-Module -ListAvailable Pester` | **pass** — pwsh 7.6.5; Pester **6.1.0** resolved (also present: 5.7.1, 3.4.0); Windows NT 10.0.26200.0 |
| 6 | `$env:AZDO_PAT` set | `$env:AZDO_PAT.Length` | **pass** — **set, length 84**. Value never read, echoed, prefixed or hashed. |
| 7 | Project GET returns 200 | `Invoke-WebRequest .../projects/ClaudeTesting?api-version=7.1` | **pass** — **200**, not 203. Project id `d24e1e58-2489-4f25-aef2-387ce48864f4` |
| 8 | One repository, zero definitions | `GET git/repositories`, `GET build/definitions` | **pass** — repos count 1: `ClaudeTesting` id `b9cabd5e-71e3-45e1-a7d7-3762a2718c97`, `defaultBranch` empty, `size` 0. Definitions count **0**. |

Precondition 4 note: the prompt's path `fixture/cases.md` is correct, resolving
to `evals/functional/fixture/cases.md`. Pass 0012's precondition named it
wrongly; this one does not.

### Resolution of the failed precondition

The modified file was the VS Code workspace file, with an editor-scope setting:

```diff
-	"settings": {}
+	"settings": {
+		"powershell.cwd": "AI.Agent.Claude.PowerShellModuleBuilder"
+	}
```

Committed alone, ahead of the pass, as `8c62ae6`. The operator's standing rule —
not reverted, not stashed, not carried — is now a section in `PLAN-PROTOCOL.md`.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 (resolved), from `~\OneDrive\Documents\PowerShell\Modules\Pester\6.1.0` |
| OS | Microsoft Windows NT 10.0.26200.0 |
| git | 2.41.0.windows.1 |
| Claude Code | not resolvable from the session shell; not guessed |
| Branch | `pass-0009-control-polarity` |
| HEAD at start | `c9853493b5f8ab0a200be396aaaa4633cc31ccc0` |

## 4. Acceptance test — red first

`evals/functional/ReadBack.Tests.ps1` was written and run **before** anything was
created in Azure DevOps.

```
==========================================
RED-FIRST RESULT
TOTAL=76 PASSED=3 FAILED=73 SKIPPED=0
==========================================
  [4 failing] Assertion 1: the four fixture repositories exist by name
  [4 failing] Assertion 2: each fixture repository has default branch main
  [30 failing] Assertion 3: every committed file exists on main and is byte-identical
  [4 failing] Assertion 4: no file exists in the four repositories other than those 30
  [15 failing] Assertion 5: all fifteen definitions exist, on the declared repository and path
  [1 failing] Assertion 6: no definition exists beyond those fifteen
  [15 failing] Assertion 7: every definition build count is zero
------ first failure message per context ------
### Assertion 1: the four fixture repositories exist by name
    test: repository pipelines-main exists
    Expected $true, because AZDO-FIXTURE.md declares repository 'pipelines-main'; the project has: ClaudeTesting, but got $false.
### Assertion 2: each fixture repository has default branch main
    test: repository pipelines-main defaults to refs/heads/main
    Expected $true, because repository 'pipelines-main' must exist before its default branch can be checked, but got $false.
### Assertion 3: every committed file exists on main and is byte-identical
    test: consumer-app/azure-pipelines.yml is byte-identical on the server
    Expected $true, because repository 'consumer-app' must exist before its files can be compared, but got $false.
### Assertion 4: no file exists in the four repositories other than those 30
    test: pipelines-main contains no file beyond the committed fixture
    Expected 21, because repository 'pipelines-main' should hold exactly 21 files, but got 0.
### Assertion 5: all fifteen definitions exist, on the declared repository and path
    test: definition p01-simple-include targets pipelines-main/pipelines/p01.yml
    Expected $true, because AZDO-FIXTURE.md declares definition 'p01-simple-include'; the project has:, but got $false.
### Assertion 6: no definition exists beyond those fifteen
    test: the project holds exactly the fifteen declared definitions
    Expected 15, because AZDO-FIXTURE.md declares fifteen definitions, but got 0.
### Assertion 7: every definition build count is zero
    test: definition p01-simple-include has never run
    Expected $true, because definition 'p01-simple-include' must exist before its run history can be checked, but got $false.
```

**The three that passed are all of assertion 8**, and that is correct rather
than a weakness. Assertion 8 claims the pre-existing `ClaudeTesting` repository
exists, is empty and is targeted by no definition — an invariant this pass must
**preserve**, not create. It is true before the pass and must still be true
after. A red there would have meant the project was not in its expected state,
which precondition 8 had already ruled out.

## 5. Tasks

### [x] 1. Fix the CRLF exposure

**`core.autocrlf` resolves from system scope**, confirmed by measurement:

```
system  : true
global  : (unset)
local   : (unset)
=== effective ===
true
=== eol ===
(unset)
```

This is the Git for Windows installer default, so it is what any Windows clone
gets — not a local misconfiguration.

**Short clone path.** `C:\t13\before` and `C:\t13\after`. The scratchpad prefix
plus the deepest fixture path exceeds the 260-character limit and fails with
`Filename too long`.

**Three-way measurement, BEFORE `.gitattributes`:**

```
=== BEFORE : three-way raw byte measurement ===

File                Side          Bytes CR LF SHA256
----                ----          ----- -- -- ------
p01.yml             working-tree    449  0 12 27e454c9f561c756
p01.yml             git-blob-HEAD   449  0 12 27e454c9f561c756
p01.yml             fresh-clone     461 12 12 1d644ffc4131cefb
common.yml          working-tree    275  0  6 52d4f730cf423abf
common.yml          git-blob-HEAD   275  0  6 52d4f730cf423abf
common.yml          fresh-clone     281  6  6 3d6ff5ecf6a1c124
azure-pipelines.yml working-tree    779  0 25 56f48cdecbc8d382
azure-pipelines.yml git-blob-HEAD   779  0 25 56f48cdecbc8d382
azure-pipelines.yml fresh-clone     804 25 25 db71519f002c7635
```

`p01.yml` 449 → **461** bytes, CR 0 → **12**, exactly as the prompt predicted.
The working tree and the blob agree, and only the clone differs, because these
files were written into the tree rather than checked out.

**`.gitattributes` added** at the repository root with `* text=auto` plus
`eol=lf` for `*.yml`, `*.json`, `*.md`, `*.ps1`.

**Three-way measurement, AFTER, from a fresh re-clone:**

```
=== AFTER : three-way raw byte measurement ===

File                Side          Bytes CR LF SHA256
----                ----          ----- -- -- ------
p01.yml             working-tree    449  0 12 27e454c9f561c756
p01.yml             git-blob-HEAD   449  0 12 27e454c9f561c756
p01.yml             fresh-clone     449  0 12 27e454c9f561c756
common.yml          working-tree    275  0  6 52d4f730cf423abf
common.yml          git-blob-HEAD   275  0  6 52d4f730cf423abf
common.yml          fresh-clone     275  0  6 52d4f730cf423abf
azure-pipelines.yml working-tree    779  0 25 56f48cdecbc8d382
azure-pipelines.yml git-blob-HEAD   779  0 25 56f48cdecbc8d382
azure-pipelines.yml fresh-clone     779  0 25 56f48cdecbc8d382
```

All three sides agree, byte counts back to origin, hashes matching. Extended to
the whole fixture:

```
=== all 30 fixture files: clone vs blob, raw bytes ===
files checked      : 30
hash mismatches    : 0
total CR bytes in clone: 0
```

**`git add --renormalize .`** produced **no output** and left no fixture file
modified. Stated plainly, as the prompt requires: *a no-op renormalise proves
that the blob and the working tree agree, and nothing more.* It says nothing
about what a clone receives, which is the side that was actually wrong — and
which is why the measurement above, not the renormalise, is the evidence.

**Normalisation altered no parsed content**, asserted at the object level, which
is stronger than a parse comparison:

```
=== fixture tree OID: pre-pass c985349 vs HEAD ===
c985349: 85300426a136d5ff88f22533a36c78a5fd934266
HEAD   : 85300426a136d5ff88f22533a36c78a5fd934266
IDENTICAL - normalisation changed no fixture byte in the object store
fixture blobs whose object id changed: 0
```

If no blob's object id changed, no byte changed, so no parsed content could
have.

**`Fixture.Tests.ps1` after task 1: `TOTAL=346 PASSED=346 FAILED=0`.** Unmoved,
as required. (It moves to 352 in task 3, by adding assertions.)

**Canonical form documented.** `AZDO-FIXTURE.md` gained *How assertion 3
compares bytes*, stating that the fixture is canonically UTF-8 without BOM,
LF-only, with a final newline, and that both sides are read as raw bytes and
compared by SHA-256 with no call to `Get-Content`, `-split`, `-replace`,
`Set-Content` or `Out-File`. Measured, not assumed:

```
files            : 30
with BOM         : 0
with non-ASCII   : 0
without final LF : 0
with any CR      : 0
```

**Pass 0012's CRLF regression assertion was kept**, untouched, in
`FixtureCase.ps1`'s comment and the suite. `.gitattributes` is prevention; the
assertion is detection.

### [x] 2. Write the acceptance test, run it, record the red

Recorded in §4. `evals/functional/ReadBack.Tests.ps1`, 76 assertions, plus
`evals/functional/AzdoClient.ps1` for the shared helpers.

The helpers live in a dot-sourced file rather than in the test, because a
top-level `function` in a Pester 6.1.0 test file breaks every `BeforeAll` in
that file.

The spec is **parsed out of `AZDO-FIXTURE.md`** rather than copied:

```
repos parsed: 4
   pipelines-main = 21
   templates-shared = 3
   templates-platform = 3
   consumer-app = 3
defs parsed : 15
committed files: 30
   consumer-app = 3
   pipelines-main = 21
   templates-platform = 3
   templates-shared = 3
```

### [x] 3. Harden the `**checked by:**` pointer

A prerequisite surfaced first: `FixtureCase.ps1` matched only the **first line**
of a `**checked by:**` block, so the quoted name `"no node is the pre-existing
ClaudeTesting repository"` was truncated at the line break. Fixed to capture the
whole paragraph and collapse whitespace before matching.

`Get-PesterTestName` was added, reading test names from the PowerShell **AST**
rather than by regex, so that a name the extractor fails to parse cannot be
reported as a missing test.

Case 12's pointer now quotes four real test names across two suites:

```
case-12: suites=[Fixture.Tests.ps1, ReadBack.Tests.ps1]
      quoted: "no node is the pre-existing ClaudeTesting repository"
      quoted: "the pre-existing ClaudeTesting repository still exists"
      quoted: "the ClaudeTesting repository is still empty"
      quoted: "no definition targets the ClaudeTesting repository"
--- It names discovered ---
Fixture.Tests.ps1 : 32 It names
ReadBack.Tests.ps1 : 10 It names
```

Six assertions added. **`Fixture.Tests.ps1` 346 → 352, `TOTAL=352 PASSED=352
FAILED=0`.**

**Falsification, probe A — rename a quoted test, expect red:**

```
--- assert the probe changed something ---
 evals/functional/ReadBack.Tests.ps1 | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
TOTAL=352 PASSED=351 FAILED=1
FAIL: case-12 pointer "the ClaudeTesting repository is still empty" resolves to a real test
      Expected $true, because cases.md case-12 quotes the test name "the ClaudeTesting repository is still empty" on a **checked by:** line, but no It with that name exists in Fixture.Tests.ps1, ReadBack.Tests.ps1. Either the test was renamed and the pointer was not, or the pointer names a test that was never written., but got $false.
```

**Falsification, probe B — prose quoting a nonexistent test name outside any
`**checked by:**` line, expect green:**

```
phrase present in collapsed copy: True
naive line-wise grep would find it: False
TOTAL=352 PASSED=352 FAILED=0
```

Probe B produced an unplanned finding. The `grep -c` first written to confirm
the probe had been applied returned **0**, because the planted phrase was
hard-wrapped across a line break — the exact hazard being documented, occurring
inside the check for that hazard. The whitespace-collapsed check above is what
actually confirmed it. This is now hazard 8 in `evals/HARNESS.md`.

Both files were restored with `git checkout --` and the tree confirmed clean
after each probe.

### [x] 4. Write `Sync-Fixture.ps1`

`evals/functional/Sync-Fixture.ps1`. Against each requirement:

- **PAT from `$env:AZDO_PAT` only** — no parameter, no file, no default; throws
  naming the variable when unset.
- **Never written anywhere** — header only. Files are pushed through the Git
  Pushes REST API rather than `git push`, precisely so that no credential ever
  enters a remote URL, the reflog, or a process argument list. This is the
  "restructure rather than accept it" case the prompt names.
- **`-DryRun`** — §5.
- **Idempotent** — §8.
- **Ordered** — all four repositories pushed before any definition exists;
  `***NO_CI***` in every push comment as a second guard for the re-run case.
- **Pushes canonical bytes explicitly** — `[IO.File]::ReadAllBytes` then base64,
  never read as text and re-encoded.
- **Never queues** — no POST to any `builds` endpoint exists in the file. The
  only `builds` call anywhere in this pass is the read-only `GET
  build/builds?definitions=` used to prove the count is zero.
- **Asserts scope** — `Assert-AzdoScope` refuses any organisation but
  `jlbalmerjr1` and any project but `ClaudeTesting`, case-sensitively.
- **Emits `create-summary.json`** — §9.

### [x] 5. Dry run

```
Sync-Fixture: DRY RUN - nothing will be created
  organisation : jlbalmerjr1
  project      : ClaudeTesting
  AZDO_PAT     : set, length 84 (value never read, logged or written)
  project id   : d24e1e58-2489-4f25-aef2-387ce48864f4
  declared     : 4 repositories, 15 definitions
  committed    : 30 files

== Repositories ==
  WOULD CREATE    : pipelines-main
  WOULD CREATE    : templates-shared
  WOULD CREATE    : templates-platform
  WOULD CREATE    : consumer-app

== Files ==
  WOULD PUSH      : 21 files to pipelines-main (repository would be created first)
  WOULD PUSH      : 3 files to templates-shared (repository would be created first)
  WOULD PUSH      : 3 files to templates-platform (repository would be created first)
  WOULD PUSH      : 3 files to consumer-app (repository would be created first)

== Definitions ==
  (created last, so that no push can trigger one)
  WOULD CREATE    : p01-simple-include -> pipelines-main/pipelines/p01.yml
  WOULD CREATE    : p02-nested-chain -> pipelines-main/pipelines/p02.yml
  WOULD CREATE    : p03-extends-params -> pipelines-main/pipelines/p03.yml
  WOULD CREATE    : p04-cross-repo-template -> pipelines-main/pipelines/p04.yml
  WOULD CREATE    : p05-pipeline-resource -> pipelines-main/pipelines/p05.yml
  WOULD CREATE    : p06-variable-template -> pipelines-main/pipelines/p06.yml
  WOULD CREATE    : p07-diamond-a -> pipelines-main/pipelines/p07a.yml
  WOULD CREATE    : p07-diamond-b -> pipelines-main/pipelines/p07b.yml
  WOULD CREATE    : p08-cycle -> pipelines-main/pipelines/p08.yml
  WOULD CREATE    : p09-unresolved -> pipelines-main/pipelines/p09.yml
  WOULD CREATE    : p10-orphan -> pipelines-main/pipelines/p10.yml
  WOULD CREATE    : x01-consumer-build -> consumer-app/azure-pipelines.yml
  WOULD CREATE    : x02-platform-release -> consumer-app/pipelines/release.yml
  WOULD CREATE    : x03-shared-nightly -> templates-shared/pipelines/nightly.yml
  WOULD CREATE    : x04-cross-trigger -> templates-platform/pipelines/trigger.yml

== Summary ==
  repositories : 4 declared, 0 created this run
  files        : 30 declared, 0 pushed this run
  definitions  : 15 declared, 0 created this run

DRY RUN complete. Nothing was created and no summary was written.
```

### [x] 6. Run it for real

```
== Repositories ==
  created         : pipelines-main (id 8e1ffaab-45e2-4342-ba5c-befcf3bf8e3d)
  created         : templates-shared (id ac59c97a-3768-4ab6-a12f-7d6382e9c289)
  created         : templates-platform (id 151fdd15-bc74-44ef-8837-f80ae45429bf)
  created         : consumer-app (id d0098877-0e7e-4363-93a8-44704b2baf28)

== Files ==
  pushed          : 21 files to pipelines-main on refs/heads/main (commit c094f7c310)
  pushed          : 3 files to templates-shared on refs/heads/main (commit 8af0197b95)
  pushed          : 3 files to templates-platform on refs/heads/main (commit c348991ca5)
  pushed          : 3 files to consumer-app on refs/heads/main (commit 5992b3dd30)

== Definitions ==
  created         : p01-simple-include (id 1) -> pipelines-main/pipelines/p01.yml
  ... (ids 2..15, one per declared definition, in p0* then x0* order)
  created         : x04-cross-trigger (id 15) -> templates-platform/pipelines/trigger.yml

== Summary ==
  repositories : 4 declared, 4 created this run
  files        : 30 declared, 30 pushed this run
  definitions  : 15 declared, 15 created this run
```

**Repositories created 4. Files pushed 30. Definitions created 15. Pipelines
queued 0.**

### [x] 7. Acceptance test — green

Recorded in §6 below.

### [x] 8. Second run, unchanged

```
== Repositories ==
  already present : pipelines-main (id 8e1ffaab-45e2-4342-ba5c-befcf3bf8e3d)
  already present : templates-shared (id ac59c97a-3768-4ab6-a12f-7d6382e9c289)
  already present : templates-platform (id 151fdd15-bc74-44ef-8837-f80ae45429bf)
  already present : consumer-app (id d0098877-0e7e-4363-93a8-44704b2baf28)

== Files ==
  already present : pipelines-main holds 21 files on main; not pushing
  already present : templates-shared holds 3 files on main; not pushing
  already present : templates-platform holds 3 files on main; not pushing
  already present : consumer-app holds 3 files on main; not pushing

== Definitions ==
  already present : p01-simple-include (id 1)
  ... (all fifteen, ids 1..15)

== Summary ==
  repositories : 4 declared, 0 created this run
  files        : 30 declared, 0 pushed this run
  definitions  : 15 declared, 0 created this run
```

**Nothing created; all 49 objects reported already present.** The re-run was
given `-SummaryPath` pointing at the scratchpad so that a run which created
nothing could not overwrite the creation record; `create-summary.json` was
confirmed byte-identical to a copy taken before the second run. The acceptance
test was re-run immediately afterwards: `TOTAL=76 PASSED=76 FAILED=0`.

### [x] 9. `runs/001-fixture-create/`

`create-summary.json` (4 repositories, 30 files, 15 definitions, each with its
Azure DevOps id and whether it was created or already present) and `README.md`
stating that this is the fixture's creation and not a module output, that there
is no graph JSON because no module exists, and that a green read-back does not
confirm `expected-graph.json`.

### [x] 10. `AZDO-FIXTURE.md` updated

New section *What creation actually required*: the endpoint and API-version
table, the two endpoints that are easy to get wrong, the push payload, the
definition payload, what Azure DevOps refused (nothing), and where the plan was
wrong. The trigger paragraph was corrected in place. See Deviations.

### [x] 11. `evals/functional/TROUBLESHOOTING.md`

Seven failures, each as symptom / the named command that reveals why /
prerequisite: `AZDO_PAT` unset; the environment-inheritance trap; HTTP 203 and
why it reads as a parse failure; a PAT lacking Code or Build scope; wrong
project or organisation; a partially created fixture; a CRLF round trip failing
assertion 3, with `git check-attr` as the command that shows which side
normalised. An eighth covers the Pester 6.1.0 top-level-`function` trap.

### [x] 12. What outlives this pass

- **PAT scan corrected** in `plans/0013-*/verify.ps1`,
  `plans/0012-*/verify.ps1` and `plans/0011-*/verify.ps1`. See Deviations —
  the prompt's premise was measurably wrong, and the defect was the opposite one.
- **`evals/HARNESS.md`** gained hazard 8, covering both causes: `-match` is
  case-insensitive, and hard-wrapped prose breaks phrase matching across lines.
- **`TROUBLESHOOTING.md`** records the Pester 6.1.0 top-level-`function` trap,
  the misleading loop-label error, and the dot-sourced-helper fix.
- **`PLAN-PROTOCOL.md`** gained the tier rule with pass 0012 as worked example,
  and the standing rule on unrelated uncommitted changes.

### [x] 13. Final green, commit, push

§6 and the transcript.

## 6. Acceptance test — green

```
==========================================
READ-BACK RESULT
TOTAL=76 PASSED=76 FAILED=0 SKIPPED=0
==========================================
per-assertion counts:
    4 passed   0 failed  Assertion 1: the four fixture repositories exist by name
    4 passed   0 failed  Assertion 2: each fixture repository has default branch main
   30 passed   0 failed  Assertion 3: every committed file exists on main and is byte-identical
    4 passed   0 failed  Assertion 4: no file exists in the four repositories other than those 30
   15 passed   0 failed  Assertion 5: all fifteen definitions exist, on the declared repository and path
    1 passed   0 failed  Assertion 6: no definition exists beyond those fifteen
   15 passed   0 failed  Assertion 7: every definition build count is zero
    3 passed   0 failed  Assertion 8: ClaudeTesting exists, is empty, and no definition targets it
```

**This proves the push landed. It does not prove the graph is correct.**
`expected-graph.json` was not modified, not derived from, and not confirmed by
anything in this pass. A green read-back with a wrong oracle is a possible state
and nothing above would detect it.

## 7. Command transcript

```powershell
# --- preconditions -------------------------------------------------------
git rev-parse --abbrev-ref HEAD; git rev-parse HEAD; git status --porcelain
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
pwsh -NoProfile -Command 'Get-Module -ListAvailable Pester | Sort-Object Version -Descending'
pwsh -NoProfile -Command 'if ($env:AZDO_PAT) { "set, length=$($env:AZDO_PAT.Length)" } else { "NOT SET" }'
pwsh -NoProfile -Command '<GET /_apis/projects/ClaudeTesting?api-version=7.1>'   # 200, id d24e1e58-...
pwsh -NoProfile -Command '<GET git/repositories, GET build/definitions>'          # 1 repo, 0 definitions
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/Fixture.Tests.ps1'       # 346/346

# --- clearing the failed precondition ------------------------------------
git add AI.Agent.Claude.PowerShellModuleBuilder.code-workspace
git commit -F -   # 8c62ae6, unrelated change committed alone

# --- task 1: line endings -------------------------------------------------
for sc in system global local; do git config --$sc --get core.autocrlf; done     # system: true
git clone -q --branch pass-0009-control-polarity <repo> C:/t13/before
pwsh -NoProfile -File <scratch>/measure.ps1 -Label BEFORE                        # p01 449/449/461
printf ... > .gitattributes
git add --renormalize .                                                          # no output
git add .gitattributes PLAN-PROTOCOL.md; git commit -F -                         # 130c160
git clone -q --branch pass-0009-control-polarity <repo> C:/t13/after
pwsh -NoProfile -File <scratch>/measure.ps1 -Clone C:\t13\after -Label AFTER      # 449/449/449
git rev-parse c985349:evals/functional/fixture HEAD:evals/functional/fixture      # identical
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/Fixture.Tests.ps1'       # 346/346

# --- task 2: acceptance test, red first -----------------------------------
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/ReadBack.Tests.ps1'      # 76: 3 passed, 73 failed

# --- task 3: checked-by pointer + falsification ---------------------------
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/Fixture.Tests.ps1'       # 352/352
git add -A evals/functional; git commit -F -                                      # cdd1cc9
# probe A: rename a quoted test -> 352: 351 passed, 1 failed; git checkout --
# probe B: prose outside a checked-by line -> 352/352 green;   git checkout --

# --- tasks 5, 6, 8: create ------------------------------------------------
pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1 -DryRun
pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1                           # 4 / 30 / 15 created
pwsh -NoProfile -File evals/functional/Sync-Fixture.ps1 -SummaryPath <scratch>/create-summary.run2.json

# --- task 7: acceptance test, green ---------------------------------------
pwsh -NoProfile -Command 'Invoke-Pester evals/functional/ReadBack.Tests.ps1'      # 76/76

# --- task 12: verify + falsification --------------------------------------
pwsh -NoProfile -File plans/0013-create-fixture/verify.ps1                        # exit 0, 0 skipped
pwsh -NoProfile -File plans/0013-create-fixture/verify.ps1 -FailCheck pat-scan    # exit 1
pwsh -NoProfile -File plans/0013-create-fixture/verify.ps1 -FailCheck checked-by  # exit 1
pwsh -NoProfile -Command '$env:AZDO_PAT=$null; ./plans/0013-create-fixture/verify.ps1'  # exit 0, 4 skipped
pwsh -NoProfile -File plans/0011-fixture-design/verify.ps1                        # exit 0
pwsh -NoProfile -File plans/0012-case-split-and-corrections/verify.ps1            # exit 0
```

No command in this transcript echoes the PAT, and none writes it. The
`Authorization` header is constructed inside PowerShell from the environment
variable and never rendered. **No redaction was necessary, because no command
was run whose output could have contained it.**

## 8. Diff summary

Not applicable — full tier.

## 9. Verify script

`plans/0013-create-fixture/verify.ps1`, committed beside this plan. It is not
reproduced here: a second copy of an executable in the same commit can disagree
with the first, and nothing makes them agree again.

It is **deliberately self-contained** — it does not dot-source `AzdoClient.ps1`
or `FixtureCase.ps1`. Where the suites use the PowerShell AST to find test
names, verify uses a regex; where the suites parse a markdown table, verify
re-reads it separately. Agreement between two independent implementations is
evidence.

It re-derives the eight named spot-checks. Checks 2, 3, 4 and 7 need the network
and `$env:AZDO_PAT`; without it they are **skipped with a clear message**,
reported as skipped and never as agreeing, and checks 1, 5, 6 and 8 still run.

**With `AZDO_PAT` set:** all checks agree, exit 0, 0 skipped.
**Without it:** exit 0, **4 skipped**, checks 1, 5, 6, 8 still verified.

**Falsification, two probes, each asserting it changed something first:**

| Probe | Assertion that it changed something | Result |
|---|---|---|
| `-FailCheck pat-scan` | `PROBE pat-scan actually planted an 84-char token` — ok | `FAIL no scanned file contains a PAT-shaped string`, **exit 1** |
| `-FailCheck checked-by` | `PROBE checked-by actually removed a test name` — ok | `FAIL every quoted checked-by test name resolves -- the ClaudeTesting repository is still empty`, **exit 1** |

The `pat-scan` probe plants the synthetic token in a scratch **copy** of a
tracked file, never in the repository, and deletes it after the scan so no
PAT-shaped string is left on disk.

## 10. Deviations

**1. A precondition failed, and the pass stopped.** The working tree was dirty
with `AI.Agent.Claude.PowerShellModuleBuilder.code-workspace` modified — an
editor-scope `powershell.cwd` setting, not pass work. Nothing was created or
committed; the failure was reported and the operator directed that it be
committed alone before the pass began, and issued a standing rule now recorded
in `PLAN-PROTOCOL.md`.

**2. The prompt's premise about the PAT scan is wrong, measurably.** The prompt
states that the committed pattern "cannot match the secret it scans for" and
therefore "reports clean", calling it "the fifth check in this project found
unable to fail". Tested against the **real** value:

```
[a-z2-7]{52}                                  : False
[A-Za-z0-9]{52}                               : True
eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}     : False
CAUGHT BY OLD SCAN: True
```

The second committed pattern is unanchored, so a 52-character window inside the
84-character run matches. **The scan could fail, and would have.** It is not a
check unable to fail; it is a check that was correct for a reason nobody had
written down. Flagged rather than silently obeyed, and rather than silently
contradicted.

The scan was corrected anyway, for a reason the prompt did not give: catching an
84-character secret with a 52-character window is an accident of length, not a
property of the pattern. A PAT containing one non-alphanumeric character would
break into runs shorter than 52 and slip through.

**3. The real defect was the opposite of the one described.** This pass commits
`create-summary.json`, carrying thirty 64-character SHA-256 digests, and
`AZDO-FIXTURE.md`, documenting 40-character git object ids. Every one matches
`[A-Za-z0-9]{52}`. Committing them would have turned all three verify scripts
**red on files containing no secret**. The correction that mattered was
therefore an *exclusion* for 40- and 64-character lower-hex runs, not a wider
pattern. A check that cries wolf is a check that gets switched off. Verified: a
PAT cannot hide behind the exclusion, since 84 is neither 40 nor 64 and a
mixed-case token is not lower-hex.

**4. `AZDO-FIXTURE.md`'s trigger claim was wrong.** It stated that "a definition
with no trigger at all is a slightly different object in the Azure DevOps API,
and the fixture should contain both shapes". Measured on definitions 1 and 12:
the `triggers` property is **absent entirely** from every one of the fifteen,
including both pipelines whose YAML declares `trigger: - main`. Not an empty
array — not present. The trigger difference is real only in the YAML. Corrected
in place.

**5. Azure DevOps refused nothing.** All four repositories, all four pushes and
all fifteen definitions were accepted first time. In particular **`p08-cycle`
and `p09-unresolved` were created without complaint**, which is the expected
result and not a defect to fix: their faults are template-expansion faults,
expansion happens at queue time, and neither is ever queued. The UI may flag
them if someone opens one and asks to validate its YAML; that too is correct.

**6. `git add --renormalize .` changed nothing**, as the prompt predicted. Its
output was empty and no fixture file was modified. Recorded as corroborating
only: it proves the blob and working tree agree and nothing more, and in
particular says nothing about the clone, which was the side that was wrong.

**7. A prerequisite to task 3 that the prompt did not anticipate.**
`FixtureCase.ps1` captured only the **first line** of a `**checked by:**` block,
so the quoted test name — hard-wrapped prose — was truncated mid-phrase. The
pointer assertion could not have been written correctly without fixing this
first.

**8. The hazard recurred inside its own falsification.** The `grep -c` written
to confirm probe B had been applied returned 0 for a phrase demonstrably present
in the file, because the phrase spanned a line break. Discovered by accident,
and the strongest available argument for hazard 8.

**9. Adding assertions broke an earlier pass's verify script.** Task 3 moved
`Fixture.Tests.ps1` from 346 to 352; `plans/0012-*/verify.ps1` pinned 346 and
went red. Updated to 352 with a comment explaining what moved and why. Left
alone it would have been hazard 6 pointing at itself. Flagged because it edits a
previous pass's artifact, which is not something to do silently.

**10. `cases.md` was edited beyond what task 3 literally asked.** Case 12's
`**checked by:**` line named "read-back assertion 8 in Pass 0013" in prose. For
the new assertion to resolve anything, the line had to quote real test names, so
it now quotes four across two suites. This is within task 3's intent — the
prompt says "the read-back assertion it names now exists" — but it is a content
change to a fixture document and is flagged as such. No case, kind, id or
expected-graph tag was touched.

**11. `AZDO-FIXTURE.md` and `ReadBack.Tests.ps1` number read-back checks
differently.** The document numbers 1–7 and calls case 12's check "assertion 8";
the prompt and the suite number 1–8. The suite's context names are the
authority; the discrepancy is now recorded in the document.

**12. The second `Sync-Fixture.ps1` run was given `-SummaryPath`.** Run
unchanged in every other respect, but writing its summary to the scratchpad, so
that a run which created nothing could not overwrite the record of the run that
created everything. `create-summary.json` was verified byte-identical to a copy
taken beforehand. `-SummaryPath` defaults to the committed location and was not
used during creation.

**13. `Sync-Fixture.ps1`'s summary writer emitted CRLF.** `Set-Content` writes
CRLF on Windows, which `.gitattributes` then normalises on commit, leaving the
working tree and the blob disagreeing about a file this pass generated — the
very condition task 1 exists to remove. Changed to write LF explicitly, and the
existing file normalised in place. Not a fixture file, so assertion 3 was never
at risk.

**14. The corrected scan flagged `verify.ps1` itself, and was right to.** On the
first full-tree run after staging, all three verify scripts went red on
`plans/0013-create-fixture/verify.ps1`. The cause was the probe's alphabet,
written as the literal
`'abcdefghijklmnopqrstuvwxyz...0123456789'` — a 62-character alphanumeric run,
and a true positive by the pattern's own rules. Rebuilt from character ranges so
that no long literal run exists in the file. Re-verified afterwards: all three
scripts exit 0, and the `pat-scan` probe still goes red, so the fix removed the
false positive without blinding the check. Worth recording as the first thing
the corrected scan actually caught.

## 11. Cost

| | |
|---|---|
| Wall clock | ~1h 26m (`8c62ae6` at 2026-08-28 22:16:13 −0700 to final commit) |
| `Fixture.Tests.ps1` runs | 8 (346 ×3, 352 ×5, including two falsification probes) |
| `ReadBack.Tests.ps1` runs | 4 (1 red, 3 green) |
| `Sync-Fixture.ps1` runs | 3 (1 dry, 1 creating, 1 idempotent) |
| `verify.ps1` runs | 4 (1 full, 2 probes, 1 no-PAT) |
| Earlier verify scripts re-run | 4 (0011 ×2, 0012 ×2) |
| Fresh clones for measurement | 2 (`C:\t13\before`, `C:\t13\after`) |
| Azure DevOps objects created | 49 (4 repositories, 30 files, 15 definitions) |
| Pipelines queued, triggered or run | **0** |

No token count: the agent cannot measure one from inside the session, and this
project's rule is that a number without an artifact behind it does not belong in
a plan.
