# Falsification pass

Phase 2 of the baseline. A gate that has only ever been green is
indistinguishable from a gate that cannot go red, so each assertion was broken
on purpose in a scratch clone and the suite re-run to see whether it noticed.

Target: `./scratch/PSModuleGraph` at `d39b125`. One break at a time.

Protocol per row, enforced by the driver rather than trusted:

1. `git checkout -- .` then `git clean -fd`, and assert the clone is clean.
2. Run the suite and assert the failure set is exactly the one known Bucket B
   failure — `Get-PSModuleAssembly`. Anything else aborts the row.
3. Apply exactly one break. The break asserts it actually changed the file.
4. Re-run.
5. Restore, re-run, assert the known-good failure set again before moving on.

Rows tagged **rebuild** rebuild (`./build.ps1 -Task Build`) after the break and
again after the restore.

Outcomes: **Fires** — the expected assertion goes red and nothing else does.
**Does not fire** — the assertion stays green through its own break.
**Over-fires** — other assertions go red too.

Control rows invert the requirement: the break is one the named assertion must
*not* notice, and the required outcome is **correctly stays green**. Row 8c is
one. Every assertion narrow enough to be worth having should be able to carry
one.

## Results

| # | Break applied | Expected assertion | Outcome | Collateral reds | Notes |
|---|---|---|---|---|---|
| 1 | Set `FunctionsToExport = '*'` in the manifest | exports functions by explicit name, never by wildcard | **Over-fires** | `Public surface.defines every function the manifest exports somewhere in source`; `House style: source layout.agrees three ways` | Three assertions for one defect. See below. |
| 2 | Delete `Get-PSModuleEnum` from `FunctionsToExport` | agrees three ways: Public filenames, manifest exports, and their count | Fires | — | |
| 3 | Add `src/PSModuleGraph/Public/Sub/Get-Thing.ps1` | keeps `Public/` flat | Fires | — | |
| 4 | Put two `function` definitions in `Public/Get-PSModuleEnum.ps1` | defines exactly one function in `Get-PSModuleEnum.ps1` | Fires | — | |
| 5 | Strip the `<# .SYNOPSIS #>` block from `Public/Get-PSModuleEnum.ps1` | gives `Get-PSModuleEnum.ps1` comment-based help with a synopsis | Fires | — | |
| 6 | Remove every invocation of `Get-PSModuleEnum` from the test tree | exercises the exported command `Get-PSModuleEnum` somewhere in tests | Fires | — | Replaces the obsolete filename-convention row. |
| 7 | Change `Run.Throw` to `Run.Exit` in the build file | throws rather than exits when tests fail | Fires | — | |
| 8a | Delete the coverage `throw`, keep the comment above it | throws on coverage below target rather than only reporting it | Fires | — | Defeated the old text-match form. |
| 8b | Delete the coverage `throw` and the comment above it | throws on coverage below target rather than only reporting it | Fires | — | Defeated the old form. |
| 8c | **Control.** Coverage gate intact; delete both `throw 'Pester 6.x is required'` guards | throws on coverage below target rather than only reporting it | **Correctly stays green** | — | One of the two is inside the Test task, outside the gate. |
| 9 | Remove `Filter.ExcludeTag = 'PreTag'` | excludes PreTag-tagged tests from the Test task | Fires | — | |
| 10 | Remove `RequiredVersion` from the Pester entry in `Requirements.psd1` | pins build dependencies only in Requirements.psd1 | Fires | — | |
| 11 | Rename `PSScriptAnalyzerSettings.psd1` | has analyzer settings at the repository root | Fires | — | |
| 12 | Delete the `$script:ModuleRoot` line from the psm1 emitter, rebuild | sets `$script:ModuleRoot` | Fires | — | **rebuild** |

12 breaks turn exactly their assertion red, 1 break over-fires by design,
nothing is inert.

Every row also carries a negative control — a break the named assertion must
*not* notice. All twelve are now correct; row 7's was failing until Pass 0008
converted that assertion to AST.

Pass 0008 added five more rows covering the rest of the build-file block, each
with both probe directions. See "Row 7's control failed" below.

Provenance: rows 8a-8c were run in Pass 2, against the replacement assertion,
before any score containing it was recorded. The rest were run in Pass 1, re-run
unchanged in Pass 2 to confirm the replacement did not disturb them, and re-run
again in Pass 3 after the `Universal`/`Repository` retag. The controls were added
in Pass 3.

## Negative controls

Added after probe 8c showed that a red break alone does not finish an assertion.
Each control is chosen to be confusable with its own row's break: a near miss in
the same file, the same task, or the same manifest. A control that could not
plausibly fool the assertion proves nothing about scope.

| # | Assertion | Control applied | Required | Actual | Collateral |
|---|---|---|---|---|---|
| 1 | exports functions by explicit name | `AliasesToExport = '*'` instead of FunctionsToExport | green | **green** | `exports no cmdlets, variables, or aliases implicitly` |
| 2 | agrees three ways | drop `Get-PSModuleEnum` from the manifest **and** delete its `Public/` file | green | **green** | — |
| 3 | keeps `Public/` flat | add `Private/Sub/Get-Thing.ps1` | green | **green** | — |
| 4 | defines exactly one function | two definitions in a `Private/` file | green | **green** | — |
| 5 | comment-based help with a synopsis | strip the synopsis from a `Private/` file | green | **green** | — |
| 6 | exercises the exported command | delete the command's name as a **string literal**, keep its invocation | green | **green** | — |
| 7 | throws rather than exits | add a **comment** mentioning `Run.Exit = $true` | green | **green** (RED before the Pass 0008 AST conversion) | — |
| 8 | throws on coverage below target | delete both `Pester 6.x is required` throws, one of them inside the Test task | green | **green** | — |
| 9 | excludes PreTag-tagged tests | remove `Filter.Tag = 'PreTag'` from the **PreTag** task | green | **green** | — |
| 10 | pins build dependencies | add a new, correctly pinned `Requirements.psd1` entry | green | **green** | — |
| 11 | has analyzer settings at the root | rename a **different** root `.psd1` | green | **green** | `pins build dependencies only in Requirements.psd1` |
| 12 | sets `$script:ModuleRoot` | delete a **different** emitted line (auto-generated marker), rebuild | green | **green** | `marks the generated file as generated` |

Collateral on a control is expected and is recorded, not failed. A control asserts
only that the *named* assertion does not move. `AliasesToExport = '*'` really is a
wildcard export; it simply is not the one row 1 is about.

### Row 7's control failed, and was fixed in Pass 0008

The section below records the failure as found. The assertion has since been
converted to an AST check: within the Test task's body, `Run.Throw` must be
assigned `$true` and no assignment may target `Run.Exit`. The control now stays
green and the break still fires.

The conversion generalised. Every *other* regex assertion in
`House style: build file` was then probed the other way round — delete the code
and leave a block comment quoting the line it looks for — and **all five stayed
green**, which is the coverage assertion's original defect exactly. All five were
converted.

| Assertion | Comment only, no code change | Code deleted, comment left | After conversion |
|---|---|---|---|
| `declares the task <_>` | green (correct) | **green — defect** | red (correct) |
| `makes the default task Clean, Lint, Build, Test` | green (correct) | **green — defect** | red (correct) |
| `excludes PreTag-tagged tests from the Test task` | green (correct) | **green — defect** | red (correct) |
| `disables Pester v5 assertion syntax` | green (correct) | **green — defect** | red (correct) |
| `measures coverage against the built psm1` | green (correct) | **green — defect** | red (correct) |

Note which probe found it. The comment-only control — the one specified, and the
one that caught row 7 — passed on all five, and cannot do otherwise for a
positive assertion whose code is still present. Only deleting the code and
leaving the comment discriminates. A control is worth having in proportion to
what it perturbs.

### Row 7 as found



```powershell
# Never write $config.Run.Exit = $true here; it kills the host.
$config.Run.Throw = $true
```

That comment, with no code changed, turns
`throws rather than exits when tests fail` red. The assertion is

```powershell
$BuildText | Should -Match 'Run\.Throw\s*=\s*\$true'
$BuildText | Should -Not -Match 'Run\.Exit\s*=\s*\$true'
```

— a text match over the whole file, which cannot distinguish a comment warning
against a setting from the setting itself. A build file whose author documented
the hazard would fail the assertion that checks for the hazard.

This is not the coverage assertion's defect. That one was inert: it could not go
red at all. This one fires under its own break correctly and *also* fires on
something it should ignore, which is the mirror-image failure and is only visible
through a control. It is the single reason the control column was worth
backfilling rather than writing down.

Recorded in Pass 3, fixed in Pass 0008.

## Row 8 — was inert, now fixed

### What it used to be

```powershell
It 'throws on coverage below target rather than only reporting it' {
    $BuildText | Should -Match '(?s)CoveragePercent.*throw'
}
```

`(?s)` makes `.` match newlines and `.*` is unbounded, so this was satisfied by
*any* `throw` anywhere after the first mention of `CoveragePercent` in the file.
There are nine `throw` statements in the reference's build file. The assertion
accepted all of them:

- With the `throw` statement removed, the regex matched the word "throw" inside
  the comment directly above it — the comment explaining why the throw exists
  satisfied the assertion that the throw exists.
- With the statement *and* that comment removed, it still matched, on
  `throw 'Pester 6.x is required. Run ./build.ps1 -Bootstrap'` in the `PreTag`
  task thirty-odd lines further down.

No edit to the coverage gate could turn it red. Not weak — inert. It passed in
every green run from the day it was written, including Pass 1's baseline of
74/75, contributing a point while testing nothing.

### What replaced it

Structure, not text:

- Parse the build file. Find the `CommandAst` for `task` whose second command
  element is `Test`. (InvokeBuild spells a task `task <Name> [<deps>,] { ... }`,
  so the name is element 1 whether or not dependencies follow.)
- Take its body: the first `ScriptBlockExpressionAst` under that command.
  `FindAll` is pre-order so the task's own body precedes anything nested in it,
  and it must be found by search rather than by indexing `CommandElements` —
  when dependencies are present the body sits inside an array literal, not at
  the top level.
- Within that body only, find `IfStatementAst`s whose **condition** contains
  either a variable matching `percent` or a `.CoveragePercent` member access.
  Matching the condition is what stops a comment counting.
- Assert that gate's own clause body contains a `ThrowStatementAst`. Searching
  only that body is what stops the eight unrelated throws counting.

Against the unbroken reference this finds one gate, at the `if ($percent -lt
$target)` on line 238, containing one throw on line 239 — out of nine in the
file.

### The three probes

The replacement was falsified before any score containing it was recorded, with
the two probes that defeated the old form and a control the old form would also
have passed:

| Probe | Break | Required | Actual |
|---|---|---|---|
| 8a | Delete the throw, keep the comment | red | **red** |
| 8b | Delete the throw and the comment | red | **red** |
| 8c | Gate intact, delete both `Pester 6.x is required` throws | green | **green** |

8c is the one that distinguishes a correctly scoped assertion from a merely
narrower one. One of those two deleted throws is *inside the Test task*, outside
the gate. An assertion scoped to the task rather than to the if-statement would
pass 8a and 8b and fail here. A control row that must stay green is not
optional; without it, "goes red when broken" is compatible with matching far
too much.

## Row 1 — over-fires

Setting `FunctionsToExport = '*'` turns three assertions red:

- `exports functions by explicit name, never by wildcard` — the intended one
- `defines every function the manifest exports somewhere in source` — `'*'` is
  not the name of a function defined anywhere, so the membership check fails
- `agrees three ways` — `Compare-Object` between the Public filenames and the
  single-element list `'*'` reports a difference

Not wrong, exactly: each of the three genuinely does not hold once the manifest
wildcards its exports. But it means one defect produces three reds, and the
score drops 4 points for a single edit. Anyone reading a future run's failure
list will be counting symptoms rather than causes.

**Expected coupling, not a fault. Do not decouple them.** A wildcard export
genuinely violates all three assertions, and each of the three is independently
worth asserting — none is a duplicate of another, they simply share an input.
Decoupling would mean special-casing `'*'` in two places to produce a tidier
failure list, buying nothing and costing suite complexity. Recorded here so that
a future three-red run is read as one defect rather than three.

## What was fiddly

Notes for the later pass that turns this protocol into a script and a skill.
Not built now.

1. **`git checkout -- .` does not restore the clone.** Rows 3 and 11 leave an
   untracked file and a renamed file respectively. `git clean -fd` is also
   required — and it must never be `-x`, because `output/` is gitignored in the
   clone and `-x` would delete the build, silently invalidating every
   `RequiresBuild` row that follows. This is the single sharpest edge in the
   protocol.

2. **"Green" is not "zero failures."** The clone has a standing Bucket B failure
   (`Get-PSModuleAssembly`). Every pre- and post-restore check has to compare
   against a known-failure *set*, not a count. A count-based check would have
   passed the whole pass while quietly hiding a second failure.

3. **A rebuild row needs two rebuilds, not one.** After the break, and again
   after the restore. Skipping the second leaves a psm1 built from broken source
   in place, which poisons the next row rather than the current one — a failure
   that shows up attributed to the wrong break. The full default task takes
   ~100s; `-Task Build` takes ~15s and is sufficient, since nothing about the
   psm1 assertions needs the test run.

4. **`$env:PSGRAPHRENDER_MODULE_PATH` has to be set for every build.** Any clone
   outside `C:\__Code\` breaks the sibling-checkout convention the `Dependencies`
   task resolves against. Without it Phase 0 and every rebuild fail for a reason
   that has nothing to do with the suite. See [PHASE0.md](PHASE0.md).

5. **Choosing what to un-invoke for row 6 took real care.** The break has to
   remove *every* invocation of one command while removing no other command's
   invocations. `Get-PSModuleEnum` worked because its only call site is one
   file, and the sole remaining mention afterwards is a string literal in the
   `Module.Quality` export list — which has to stay, or the break stops testing
   what it claims to. Any command whose calls are spread across files, or whose
   test file also calls other public commands, would over-fire for reasons that
   say nothing about the assertion.

6. **Every regex-applied break needs a did-this-change-anything guard.** A
   silently non-matching substitution produces a clean green run that reads as
   "does not fire" — the worst possible false result, because it is the outcome
   the pass exists to detect. Each break asserts the file changed before the
   suite is re-run. Two breaks were caught by this guard during development.

7. **A red probe alone does not finish an assertion.** An assertion scoped to
   the Test task rather than to the coverage gate passes probes 8a and 8b and is
   still wrong. Only the green control, 8c, separates them. The driver needs an
   explicit "this must stay green" outcome type, or control rows get recorded as
   "does not fire" and read as failures.

   Backfilling controls across all twelve rows found one more defect that twelve
   red breaks had not: row 7 fires on a comment. Note also that a control must
   pass when only its *named* assertion stays green — three of the twelve
   controls legitimately turn other assertions red, and an implementation that
   required zero collateral would have rejected all three.

   One control was rejected by the hazard-4 guard on its first run: it tried to
   strip a synopsis from a private file that had none, so the substitution
   matched nothing. Without the guard it would have been recorded as a passing
   control, which is the same false-green the guard exists to prevent.

8. **A PowerShell parse trap, for whoever writes the driver.**
   `-ForegroundColor ( if ($x) { 'Green' } else { 'Yellow' } )` parses `if` as a
   command name and fails at runtime, not at parse time, so it survives a
   `Parser::ParseFile` check and dies mid-row. Assign the value first. Cost one
   run and left the clone dirty, which is why step 1 of the protocol asserts
   cleanliness rather than assuming it.

## Rows 18a-18e — Workspace composition (pass 0044)

The assertion: **`Workspace composition.does not register PSModuleGraph as a
folder`**, `HouseStyle`. A tracked `*.code-workspace` must not list the
read-only reference among its folders — a reference in the editor's workspace is
a writable working directory and its own instructions load into the session.

Numbered from 18 rather than from 13. The table above ends at 12, and the note
under it records that pass 0008 added five more rows for the build-file block
which were never tabulated here; leaving 13-17 to them costs nothing and
guarantees no collision.

Driver: [`plans/0044-method-corrections/Test-WorkspaceFalsification.ps1`](../../../plans/0044-method-corrections/Test-WorkspaceFalsification.ps1).
Each fixture is a **minimal module repository** built under `scratch/` at run
time, not a bare directory — see 18e's note for why that is not incidental.

| # | Break applied | Expected assertion | Outcome | Collateral reds | Notes |
|---|---|---|---|---|---|
| 18a | Workspace file registers `../PSModuleGraph` as a folder | does not register PSModuleGraph as a folder | Fires | — | passed 0, failed 1 |
| 18b | **Restore.** Same file, that folder entry removed | does not register PSModuleGraph as a folder | **Correctly stays green** | — | passed 1, failed 0 |
| 18c | **Control, scope.** Names `PSModuleGraph` in a `//` comment and in a settings string; registers only siblings | does not register PSModuleGraph as a folder | **Correctly stays green** | — | The row that made the assertion semantic instead of a text match |
| 18d | **Control, segment.** Registers `../PSModuleGraphTools` | does not register PSModuleGraph as a folder | **Correctly stays green** | — | A sibling whose name merely starts with the reference's is not the reference |
| 18e | **Control, absence.** No workspace file at all | does not register PSModuleGraph as a folder | **Zero cases — inapplicable** | — | Not a pass. See below. |

All five behave as required; driver exit 0.

**18c is the row that changed the assertion.** A text match for `PSModuleGraph`
passes 18a and 18b and fails 18c, and an assertion that fails 18c fires on every
file that *documents* the rule — including this one, `UX-007`, and the METHOD
rule that motivates it. The assertion therefore parses the workspace file as
JSONC and reads `folders[].path`, comparing path segments. Registration is a
folder entry; a mention is not one.

**18e is a control on the suite, not on the assertion.** Zero cases must report
as inapplicable and must never be counted as a pass. Getting there exposed a
Pester 6 behaviour worth writing down: **an empty `-ForEach` is a discovery
error that fails the entire file**, not zero cases. Without
`-AllowNullOrEmptyForEach` on this `It`, every target with no tracked workspace
file — three of the four ecosystem repositories, and every gallery corpus
package — would have taken the whole conformance suite down rather than
reporting one assertion as inapplicable.

**The first run of the driver reported ZERO CASES on all four rows, and it was
wrong.** Discovery was failing on an unrelated assertion's empty `-ForEach`, and
the driver could not tell "this assertion had nothing to check" from "the suite
never ran". A driver that cannot separate those can report a green that means
nothing — the same false-green that hazard 6 above exists to prevent, arriving
from a new direction. The driver now fails loudly on a failed container, and
that check is why 18e can be trusted.

### The assertion against the real repositories

Run once per repository, filtered to this block. Recorded because two of the
five results are findings rather than passes.

| Repository | Result | |
|---|---|---|
| PSAzureDevOpsGraph | zero cases | no tracked workspace file — inapplicable |
| PSGraphRenderToHtml | zero cases | no tracked workspace file — inapplicable |
| PSTerraformGraph | zero cases | no tracked workspace file — inapplicable |
| PSGraphRender | **RED** | `PSGraphRender.code-workspace` registers `../PSModuleGraph` |
| AI.Agent.Claude.PowerShellModuleBuilder | **cannot run** | the suite fails discovery against the harness |

**PSGraphRender is a real violation and it is not repaired here.** The file has
carried `../PSModuleGraph` since that repository's initial commit, and pass 0044
holds the ecosystem repositories read-only. Never weaken an assertion because a
target fails it: the finding goes to the operator, as LEDGER backlog 60.

**The harness cannot be graded by its own suite.** `AI.Agent.Claude.PowerShellModuleBuilder`
has no module manifest, so `$ExportedWithSource` and `$PublicFiles` are both
empty and discovery fails on assertions this pass did not touch. The one
repository whose `.code-workspace` produced the 0043 finding is therefore the
one repository this assertion structurally cannot reach. Covered instead by a
direct check in `plans/0044-method-corrections/verify.ps1`, and recorded as
LEDGER backlog 61.
