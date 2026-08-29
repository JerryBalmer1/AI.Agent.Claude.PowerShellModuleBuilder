# Conformance baseline — findings

Target: `./scratch/PSModuleGraph`, clone of the reference at `d39b125`.
Suite: `evals/conformance/Conformance.Tests.ps1` as of the corrections below.
Phase 0: default task green — see [PHASE0.md](PHASE0.md). Bucket sorting is
therefore meaningful; a failure here is a statement about the suite or about
the reference, not fallout from a broken build.

| Run | Tags | Score |
|---|---|---|
| `psmodulegraph-result.json` | `Universal,HouseStyle` | 74/75 — 98.67% |
| `psmodulegraph-build-result.json` | `Universal,HouseStyle,RequiresBuild` | 80/81 — 98.77% |

Before the B1 replacement, the same no-build invocation scored 69/75 — 92%.

**Read the Pass 1 figure of 74/75 as 73/74 plus one unknown.** It included
`throws on coverage below target`, an assertion that could not fail — see A7. Its
pass was not earned and carried no information about the target either way. The
number above is numerically identical but is now the whole of it: every
assertion in it has a falsification row, and the coverage one has a confirmed
red and a green control.

---

## Bucket A — suite bugs

The assertion tested the wrong thing, or was written wrongly. Fixed.

### A1. Manifest resolution picked the wrong module

**Was:** candidate manifests filtered on absolute path, tie-broken by shortest
path.

**Symptom:** `corpus/PSCorpus/PSCorpus.psd1` beat
`src/PSModuleGraph/PSModuleGraph.psd1` on path length, so the whole suite
graded a vendored corpus fixture instead of the module under test.

**Fix:** prefer the manifest whose base name matches the repository directory
name; fall back to shortest path only when nothing matches, so a renamed
checkout still resolves. Exclusions (`output|scratch|.git|gallery|fixtures|node_modules`)
match against the path *relative* to the target — an absolute match let the
target's own container directory exclude every candidate inside it, which is
exactly what happens when the harness runs targets from `./scratch/`.
`Select-Object -First 1` rather than `[0]`, because indexing an empty array
throws under `Set-StrictMode -Version Latest`, which the runner sets.

### A2. `.Count` on a scalar threw under StrictMode

**Was:** helper return values used directly, e.g. `(Get-HelpComment -Path ...).Count`.

**Symptom:** a helper returning a one-element array has it unrolled to a scalar
by the pipeline. `.Count` on a scalar throws under `Set-StrictMode -Version Latest`.
The assertion errored instead of passing or failing.

**Fix:** `@()` around every helper return before counting.

### A3. Test names were not stable across targets

**Was:** `-ForEach $PublicFiles` with `<_>` in the test name.

**Symptom:** expanding a `FileInfo` stamps its absolute `FullName` into the test
name, so the name recorded in `result.json` changed with the target's location
and scores could not be diffed between runs.

**Fix:** `<_.Name>` (or `<_.BaseName>`), which is stable.

### A4. `House style: generated module` ran without a build

**Was:** `Describe 'House style: generated module' -Tag 'HouseStyle', 'RequiresBuild'`.

**Symptom:** Pester's tag filter is an OR, not an AND. Carrying `HouseStyle`
made the block run under the README's own documented no-build invocation
(`-Tag Universal,HouseStyle`), where every assertion reads an absent psm1 as
empty string and fails. Six guaranteed false failures on any no-build run.

**Fix:** `-Tag 'RequiresBuild'` alone. The tag that gates the block has to be
the one that describes its precondition.

### A5. `ScorePct` charged the score for tests nobody ran

**Was:** `TotalCount - SkippedCount` as the denominator.

**Symptom:** `TotalCount` includes tests filtered out by `-Tag` (`NotRun`), so a
`Universal,HouseStyle` run was divided by the full 81 rather than the 75 it
selected. It scored 85% instead of 92% purely because `RequiresBuild` was
excluded — a number that moved when the caller changed tags, not when the
target changed.

**Fix:** `PassedCount + FailedCount`. The denominator is what actually executed.

### A6. `has a test file for the exported command` tested an invented convention

**Was:**

```powershell
It 'has a test file for the exported command <_.BaseName>' -ForEach $PublicFiles {
    $candidates = @(Get-ChildItem -Path $TestsRoot -Filter "$($_.BaseName).Tests.ps1" -File -Recurse ...)
    $candidates.Count | Should -BeGreaterThan 0
}
```

**Symptom:** all six failures against the reference were this one assertion, and
all six were wrong. The rule — one test file named for each exported command —
was invented by the suite, not extracted from the reference. The reference
groups tests by subsystem, which is the better convention:

- `EditorLink.Tests.ps1` covers both `Enable-` and `Test-PSModuleGraphEditorLink`
- `Export-PSModuleDependencyGraph.Html.Tests.ps1` carries an infix qualifier
- the two `Knowledge` commands are exercised from `tests/Private/`

An assertion that a repository must be laid out the way the suite guessed is
not a conformance test; it is the suite asserting its own preferences.

**Fix:** assert the thing actually worth asserting — that some test somewhere
*invokes* the command. Not a filename convention and not a text search: the
replacement parses every `.ps1` under `tests/` and looks for a `CommandAst`
whose command name matches. A command named in a string — the export list in
`Module.Quality.Tests.ps1`, for instance — is not a command under test.

Five of the six failures were convention noise and disappeared. The sixth,
`Get-PSModuleAssembly`, survived and is Bucket B below.

### A7. `throws on coverage below target` could not fail

**Was:**

```powershell
$BuildText | Should -Match '(?s)CoveragePercent.*throw'
```

**Symptom:** `(?s)` makes `.` match newlines and `.*` is unbounded, so any
`throw` anywhere after the first mention of `CoveragePercent` satisfied it.
There are nine `throw` statements in the reference's build file and the
assertion accepted all of them. Three probes, all confirmed against the clone:

- delete the coverage `throw`, keep the comment → still green, matching the word
  "throw" in the comment that explains the throw
- delete the `throw` and that comment → still green, matching
  `throw 'Pester 6.x is required'` in the `PreTag` task thirty lines down
- there is no edit to the coverage gate that turns it red

Not a weak assertion — an inert one. It passed in every green run since it was
written, including Pass 1's baseline, and contributed a point to a score while
testing nothing.

**Fix:** structure instead of text. Parse the build file, find the `task Test`
command, take its body scriptblock, find the `IfStatementAst` whose *condition*
reads the coverage percentage — a `percent`-ish variable, or a
`.CoveragePercent` member — and assert that if's own body contains a
`ThrowStatementAst`. Matching the condition is what stops a comment counting;
searching only that if's body is what stops the eight unrelated throws counting.

Falsified before the score was recorded, with all three probes that defeated the
old form plus a control. See [FALSIFICATION.md](FALSIFICATION.md) rows 8a-8c.

**This is why the standing rule in the suite README exists.** Two assertions had
by then entered a scoring run without a confirmed red: A6, which was new, and
this one, inert since it was written. An assertion does not count until it has a
falsification row.

---

## Bucket B — real findings

The assertion is correct and the reference fails it. Recorded, unfixed.

### B-1. `Get-PSModuleAssembly` is exported but never invoked by any test

```
Repository shape.exercises the exported command Get-PSModuleAssembly somewhere in tests
  Expected $true, because an exported command no test ever calls is untested, but got $false.
```

Confirmed independently of the suite. `Get-PSModuleAssembly` appears exactly
once in the entire test tree:

```
tests/Module.Quality.Tests.ps1:47:            'Get-PSModuleAssembly'
```

— a string literal inside the `$expected` export-list array that
`Module.Quality.Tests.ps1` compares against the module's actual exports. That
test asserts the command is *exported*. Nothing anywhere calls it.

This is the exact case the replacement assertion was written to catch, and it
is the case a filename-convention check would also have flagged, for the wrong
reason. It is a genuine gap: a public command with no behavioural test, whose
line coverage is supplied entirely by other commands happening to route
through it, if at all.

**Not fixed.** Writing tests for the reference is out of scope for this pass,
and the standing constraints forbid touching the reference.

---

## Known limits

### The B1 invocation check is a floor, not coverage measurement

It detects a `CommandAst` whose `GetCommandName()` matches the exported command.
It does **not** detect:

- invocation through the call operator with a variable, `& $name`
- a splatted or otherwise computed command name
- invocation through an alias
- invocation from a file the parser rejects (those are skipped, silently)

So it can report "exercised" only when it sees a literal call, and a command
genuinely exercised by one of the above reads as untested. It cannot do the
reverse — it will not call something exercised when nothing invokes it — which
is the direction that matters for a floor. Do not read a pass as evidence the
command is *well* tested; read it as evidence it is called at all.

### The remaining build-file assertions are still text matches

The coverage assertion is now AST-scoped (A7), but the rest of the
`House style: build file` Describe still matches regexes against the file as
text: the task declarations, the default task composition, `Run.Throw`,
`Should.DisableV5`, `Filter.ExcludeTag`, and the coverage *path*. A build file
that satisfies those regexes and does something else passes.

They all fire under their own breaks, so none is inert in the way A7 was. But
they are checking that some text appears, not that the build does something, and
the difference is exactly the one A7 was hiding in. Each is a candidate for the
same treatment; none has yet shown a reason to need it.

### Coupled assertions on the manifest export list, kept coupled

`FunctionsToExport = '*'` turns three assertions red: the wildcard check, `defines
every function the manifest exports somewhere in source`, and `agrees three
ways`. This is expected coupling, not a fault — a wildcard export genuinely
violates all three, and each of the three is independently worth asserting.
Decoupling them would mean special-casing `'*'` in two places to produce a
tidier failure list, which buys nothing and costs suite complexity.

Recorded so a future three-red run is read as one defect. See
[FALSIFICATION.md](FALSIFICATION.md) row 1.

### Everything under `Universal` has been validated against one repository

Unchanged from the suite README, and still the largest limit on how much this
baseline means. `Universal` currently encodes one repository's idea of
universal. Treat the tag as an intention until a second, deliberately
dissimilar target passes it.
