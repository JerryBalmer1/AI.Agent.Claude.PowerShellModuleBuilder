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
| 8 | Remove the `throw` after the coverage comparison | throws on coverage below target rather than only reporting it | **Does not fire** | — | The important one. See below. |
| 9 | Remove `Filter.ExcludeTag = 'PreTag'` | excludes PreTag-tagged tests from the Test task | Fires | — | |
| 10 | Remove `RequiredVersion` from the Pester entry in `Requirements.psd1` | pins build dependencies only in Requirements.psd1 | Fires | — | |
| 11 | Rename `PSScriptAnalyzerSettings.psd1` | has analyzer settings at the repository root | Fires | — | |
| 12 | Delete the `$script:ModuleRoot` line from the psm1 emitter, rebuild | sets `$script:ModuleRoot` | Fires | — | **rebuild** |

10 fire cleanly, 1 over-fires, 1 does not fire.

## Row 8 — does not fire

The assertion is:

```powershell
It 'throws on coverage below target rather than only reporting it' {
    $BuildText | Should -Match '(?s)CoveragePercent.*throw'
}
```

`(?s)` makes `.` match newlines and `.*` is unbounded, so this is satisfied by
*any* `throw` anywhere after the first mention of `CoveragePercent` in the file.
Deleting the coverage gate outright leaves it green.

Two further checks, past what the row required, to establish how far the
assertion is from working:

- With the `throw` statement removed, the regex matches on the word "throw"
  inside the comment directly above it — the comment explaining why the throw
  exists satisfies the assertion that the throw exists.
- With the statement *and* that comment removed, it still matches, on
  `throw 'Pester 6.x is required. Run ./build.ps1 -Bootstrap'` in the `PreTag`
  task, 30-odd lines further down.

So the assertion cannot fail against this build file by any edit to the thing
it is about. It is not weak; it is inert. It has been counted as evidence in
every green run to date, including this baseline's 74/75.

Left unfixed in this pass by instruction. Recorded in
[FINDINGS.md](FINDINGS.md) as a known limit and as the next pass's Bucket A.

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

Worth knowing rather than worth fixing: `defines every function the manifest
exports` and `agrees three ways` are both meaningful assertions that happen to
share an input with the wildcard check. Coupling them out would mean
special-casing `'*'` in two places to preserve a nicer failure list, which is
more suite complexity than the confusion costs. Recorded so that a three-red
run is recognised as one defect.

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

7. **A PowerShell parse trap, for whoever writes the driver.**
   `-ForegroundColor ( if ($x) { 'Green' } else { 'Yellow' } )` parses `if` as a
   command name and fails at runtime, not at parse time, so it survives a
   `Parser::ParseFile` check and dies mid-row. Assign the value first. Cost one
   run and left the clone dirty, which is why step 1 of the protocol asserts
   cleanliness rather than assuming it.
