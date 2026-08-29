# Conformance suite

The oracle. It decides whether a module repository — one a human wrote, or one
the `psmodule` plugin generated — meets the conventions this plugin teaches.

Nothing here imports or executes the module under test. Every assertion reads
the source tree, the manifest, the build file, or the generated `psm1` as text.
A suite that has to run arbitrary build code to grade a run is a suite that can
be made to pass by a run that breaks it.

## Tags

| Tag | Meaning | Needs a source tree? | Needs a build? |
|---|---|---|---|
| `Universal` | True of any PowerShell module — a source tree or a published package. Reads the manifest and whatever source it can find. | No | No |
| `Repository` | True of any module *repository*. Build entrypoint, analyzer settings, tests. | Yes | No |
| `HouseStyle` | Specific to the PSModuleGraph build conventions. | Yes | No |
| `RequiresBuild` | Reads `output/<Name>/`. | Yes | Yes |

`Universal` and `Repository` were one tag. The split was forced by the corpus
run: a published package has no build file and no tests, and failing it for that
says nothing about the module. Run `-Tag Universal` alone against anything that
is not a repository.

**Validation status, as of the corpus pass.** Five of the ten `Universal`
assertions have survived all nine targets tried so far — the reference plus the
eight-module gallery corpus. The other five have not, and one of them has only
ever run against three. The per-assertion counts are in
[`baseline/UNIVERSAL-CORPUS.md`](baseline/UNIVERSAL-CORPUS.md), and that table is
the honest confidence level for this tag. `Repository` and `HouseStyle` have been
validated against one repository.

If a rule cannot survive a module shaped unlike PSModuleGraph, it belongs in
`Repository` or `HouseStyle`, and the plugin should say so out loud rather than
presenting it as a fact about PowerShell. Moving an assertion *into* `Universal`
is a claim; make it deliberately, and only after dissimilar targets have passed
it.

## Running it

```powershell
# Against the reference. This must be green before the suite is trusted.
./Invoke-Conformance.ps1 -Path ../../../PSModuleGraph

# Against a generated run, after its build has been run.
./Invoke-Conformance.ps1 -Path ./scratch/runs/<id>/PSAzureDevOpsGraph `
                         -Tag Universal,HouseStyle,RequiresBuild `
                         -ResultPath ./scratch/runs/<id>/result.json
```

The runner does not use `Run.Throw`. A red conformance run is data, not a build
failure — the harness records the score and moves to the next run.

It exits `0` on a red run too, which is the same claim made where a caller can
act on it. `Invoke-Pester` sets `$LASTEXITCODE` to the failure count even with
`Run.Throw` and `Run.Exit` both off, so until this was fixed the runner
contradicted itself: the comment said a red run is data, the exit code said the
run crashed. Pass `-PassExitCode` if you want the failure count — for a CI step
that should genuinely go red, and nothing else. Read the score from
`result.json`.

## Falsification protocol

A gate that has only ever been green is indistinguishable from a gate that
cannot go red. Before this suite grades anything, break the reference in a
scratch clone — one break at a time, restore between — and confirm each break
turns exactly the expected assertion red and nothing else.

**An assertion does not count until it has a falsification row.** Any assertion
that is added or changed gets a break, a confirmed red, and a restore before any
score including it is recorded.

**A falsification row needs a negative control, not just a break.** A break that
must go red proves the assertion *can* fail. A control that must stay green
proves it fails *for the right reason*. The two are not the same claim and the
first does not imply the second.

The worked example is the coverage assertion. Scoped to the Test task rather
than to the if-statement inside it, an assertion passes both breaks aimed at
it — and also goes red when an unrelated `throw` in the same task is deleted.
Red probes alone cannot tell the correct scoping from the over-broad one; only
the green control can. Every row in the table below carries one, and one of
those controls is currently failing.

**The control's shape is determined by the assertion's polarity.** For a
*positive* assertion — must match X — remove X and leave text resembling X; the
assertion must go **red**. For a *negative* assertion — must not match X — add
text mentioning X without the behaviour; the assertion must stay **green**.

A comment-only probe against a positive assertion cannot fail while the code is
present, and will pass an assertion that is inert. Five build-file assertions
passed exactly that probe and then stayed green with their code deleted and a
comment left in its place — which is the inert-assertion defect, found only by
the polarity-correct probe.

**Zero cases is not a pass.** An assertion whose `-ForEach` produced no cases is
*inapplicable* to this target. It must be reported as such — never counted as a
pass, and never allowed to fail its container. Scores state cases-run alongside
cases-passed: `result.json` carries `CasesRun` beside `Total`, and an
`Assertions` breakdown in which an assertion that produced nothing is simply
absent. The comment-based-help assertion silently did not apply to six of eight
corpus modules while appearing to be part of a green run.

**Ambiguous discovery fails loudly.** When the suite cannot determine which
module it is grading, it stops and names every candidate. It does not pick.
SqlServerDsc ships 51 manifests; the old shortest-path tie-break graded a
bundled helper module and reported 81.82% with nothing in the output to say so.
Reporting nothing is better than reporting a number about the wrong thing.
`-ModuleName` is the way to answer the question when it is genuinely ambiguous.

None of this is style preference. Two assertions have already gone into a
scoring run without a confirmed red: the invocation check, which was new, and
`throws on coverage below target`, which was inert from the day it was written
and passed every green run for free. Same defect both times. A score containing
an unfalsified assertion is not a measurement of the target; it is partly a
measurement of nothing.

| # | Break — must go **red** | Assertion | Negative control — must stay **green** |
|---|---|---|---|
| 1 | Set `FunctionsToExport = '*'` | exports functions by explicit name | Set `AliasesToExport = '*'` instead |
| 2 | Delete one name from `FunctionsToExport` | agrees three ways | Delete that name from **both** the manifest and `Public/` |
| 3 | Add `Public/Sub/Get-Thing.ps1` | keeps `Public/` flat | Add `Private/Sub/Get-Thing.ps1` instead |
| 4 | Two `function` definitions in one `Public/*.ps1` | defines exactly one function | Two definitions in a `Private/*.ps1` instead |
| 5 | Strip the `<# .SYNOPSIS #>` block from a public file | comment-based help with a synopsis | Strip it from a private file instead |
| 6 | Remove every invocation of one command from the test tree | exercises the exported command &lt;name&gt; | Remove that command's name as a **string literal**, keep its invocation |
| 7 | Change `Run.Throw` to `Run.Exit` | throws rather than exits | Add a **comment** mentioning `Run.Exit = $true`, change no code — **currently fails, see below** |
| 8 | Delete the coverage `throw`, with or without the comment above it | throws on coverage below target | Delete an unrelated `throw` elsewhere, including one inside the Test task |
| 9 | Remove `Filter.ExcludeTag = 'PreTag'` from the Test task | excludes PreTag-tagged tests | Remove `Filter.Tag = 'PreTag'` from the **PreTag** task instead |
| 10 | Remove `RequiredVersion` from a `Requirements.psd1` entry | pins build dependencies only in Requirements.psd1 | Add a new, correctly pinned entry |
| 11 | Rename `PSScriptAnalyzerSettings.psd1` | has analyzer settings at the repository root | Rename a **different** root `.psd1` instead |
| 12 | Delete the `$script:ModuleRoot` line from the psm1 emitter, rebuild | sets `$script:ModuleRoot` | Delete a **different** emitted line (the auto-generated marker), rebuild |

Every control is chosen to be *confusable* with its break — a near miss in the
same file, the same task, or the same manifest. A control that could not
plausibly fool the assertion proves nothing about its scope.

The controls in the table above are **scope** controls: they prove an assertion
does not fire on a neighbour. They are not polarity-correct controls for the
positive assertions among them, and the two are not substitutes. See
[`baseline/CONTROL-SWEEP.md`](baseline/CONTROL-SWEEP.md) for the polarity sweep
across every positive assertion in the suite.

Record the result of this pass. An assertion that stays green through its own
break is worse than no assertion, because it will be counted as evidence.

A control row — a break that must leave a named assertion **green** — is as much
a part of the protocol as a break that must turn it red. An assertion scoped too
widely passes every red probe and is still wrong; only a control catches it.

The pass against the reference is recorded in
[`baseline/FALSIFICATION.md`](baseline/FALSIFICATION.md). Every break turns its
assertion red. Eleven of the twelve controls stay green.

**Row 7's control fails.** Adding a comment that mentions `Run.Exit = $true`,
without changing a line of code, turns `throws rather than exits` red. The
assertion is a text match over the whole build file and cannot tell a comment
from a setting. It is not inert — its break does fire — but it fires on the
wrong thing, and it is the only row where the break and the control disagree.
Recorded, not yet fixed.

## Known limits

- The `House style: build file` assertions are now AST checks, not text matches.
  Every one of them was defeated by a block comment quoting the line it looked
  for, with the real code deleted — five out of five, tested one at a time. The
  regexes are gone from that Describe.
- What is *not* covered: an AST assertion still checks that a setting is
  assigned, not that the build behaves. `CodeCoverage.Path` pointing at a psm1
  is not proof coverage was measured against it.
- `Universal` is nine assertions and has run against nine targets. **Seven
  survive all nine.** The two that do not fail only on Bucket B grounds — real
  properties of the modules, recorded in
  [`baseline/known-failures.json`](baseline/known-failures.json), not suite
  defects. See [`baseline/UNIVERSAL-CORPUS.md`](baseline/UNIVERSAL-CORPUS.md)
  for cases-run per assertion.
- **The corpus control does not pass clean.** posh-git fails
  comment-based help on five exported commands. The failures are genuine, but
  the standing gate is that the control passes, and it does not. `Universal`
  is better evidenced than it was and is not yet signed off.
- There is no assertion that the build actually succeeds. That belongs in the
  run harness, which invokes `./build.ps1` and records the exit code alongside
  this suite's score.