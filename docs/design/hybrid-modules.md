# Hybrid modules — what breaks

A **hybrid** module ships compiled code alongside PowerShell: a Go program built
to a DLL, a C# assembly, a native binary the module shells out to. Nothing in
this repository supports one, and nothing here has been built or graded that
way.

This note exists so that the cost is enumerated against the **real instruments**
rather than estimated. Every item below names the assertion, script or gate that
would actually have to change, and what it currently assumes. It is a survey of
damage, not a design, and it deliberately stops short of proposing one.

**The hook already exists and is deliberately inert.**
`psmodule.settings.psd1` carries a `ModuleProfile` key, validated against
`'script'` and `'hybrid'`, defaulting to `'script'`, and its own record says
what setting it to would mean:

> `'script'` is the measured one; `'hybrid'` is a PLACEHOLDER for a module
> carrying compiled assemblies and is not implemented

with the consequence stated in the same entry:

> every claim this plugin makes, all of which were measured against `'script'`
> modules. `'hybrid'` is reserved, not supported: nothing has been built or
> graded under it, and setting it asserts a capability that does not exist yet.

That is the seam. Everything below is what would have to be true on the other
side of it.

---

## 1. The layout assertions, and why a declared profile is unavoidable

Four `HouseStyle` assertions in
[`evals/conformance/Conformance.Tests.ps1`](../../evals/conformance/Conformance.Tests.ps1)
are statements about a **script** module's shape, and a hybrid one violates them
by being correct:

| Assertion | What it assumes |
|---|---|
| `keeps Public/ flat` | every exported command is a `.ps1` file |
| `defines exactly one function in <file>, named for the file` | commands are functions, and functions live in files |
| `agrees three ways: Public filenames, manifest exports, and their count` | the exported surface can be counted by listing a directory |
| `defines every function the manifest exports somewhere in source` (`Universal`) | the definition is in text the parser can find |

A module whose commands are **cmdlets in an assembly** has no `Public/*.ps1` for
them, exports them through `CmdletsToExport` rather than `FunctionsToExport`,
and the third assertion — the strongest of the four, because it triangulates —
fails on a module that is entirely correct.

**This is why the profile has to be declared rather than sniffed.** The
alternative is a suite that infers "there is a DLL here, so relax the layout
rules", and an assertion that relaxes itself when it finds evidence of the thing
it was meant to grade is not an assertion. Under a declared profile the four
above become profile-scoped, a hybrid profile states its own equivalents, and
**the two profiles are separate score series** on
[decision 0003](../../decisions/0003-score-comparability.md)'s terms — a
`cases-defined` under `hybrid` is not the denominator the published numbers were
taken on, and comparing across them would be the same error as comparing across
the v1.1/v1.2 boundary.

## 2. The ordered runner's parse layer stops being sufficient

`scripts/Invoke-OrderedTests.ps1` runs five layers and stops at the first
failure, and the second is `files-parse`: `[Parser]::ParseFile` reports no errors
for any `.ps1` under `src/` or `tests/`.

The layer exists because one unparseable file otherwise reports as thirty-seven
failing tests. **For a hybrid module it is no longer the cheapest failure.** The
compiled half fails to *compile*, and a compile error is precisely the kind of
defect the layer's whole argument says should be reported by name at its own
level rather than three stages downstream as "the module would not import".

So layer 2 grows a sibling — compile the assembly, report by file and line — and
`-Build`, which today runs `./build.ps1 -Task Build` between layers 2 and 3,
acquires a toolchain it does not currently know exists. The layer *ordering*
argument survives intact; it is the layer *membership* that changes.

## 3. Coverage gates measure a file that is no longer the module

`It 'measures coverage against the built psm1, not the source tree'` and
`It 'throws on coverage below target rather than only reporting it'` both point
Pester's code coverage at `output/<Name>/<Name>.psm1`.

For a hybrid module that file covers **the PowerShell half only**, and the
percentage it produces is a true number about a shrinking fraction of the
module. A module that moves logic into the assembly would watch its coverage go
*up* as the covered surface shrank.

This is the same shape as the coverage gate this project already caught being
inert: a plausible number, printed confidently, measuring nothing that matters.
The gate would need either two coverage figures reported separately — never
averaged, for the same reason `/psmodule:test` reports two scores — or a stated
refusal to gate on the compiled half, said out loud rather than left as an
absence.

## 4. Analyzer blindness, and the one extension that is safe

`powershell-module-analyzer`'s first rule is **never run the code you are
analysing**: everything comes from the AST, because reading a module by
importing it executes whatever that module executes on import.

A DLL is invisible to that. There is no AST, and the analyzer's whole reason for
being trustworthy — it never executes — is also the reason it cannot see inside
a compiled assembly at all.

**The one extension that does not break the rule is reflection over metadata.**
`System.Reflection.MetadataLoadContext` reads an assembly's types, members and
attributes **without running any of its code or its static constructors**. That
is enough to answer the questions the analyzer actually asks of the PowerShell
half — what does this export, what does it claim about its parameters, does the
declared surface match the manifest — and it preserves the property that makes
the answer worth having.

What it will not give you is the analyzer's other half: what the code *does*.
`Assembly.LoadFrom` would, and it runs the assembly's initialisation to do it,
which trades the entire premise for the convenience. That trade is not available
here.

## 5. The prerequisite checker becomes a different claim

[`tools/publish/Test-Prerequisites.ps1`](../../tools/publish/Test-Prerequisites.ps1)
checks five things and names the exact line that fixes each: PowerShell 7.2+,
Pester, InvokeBuild, git, `$env:AZDO_PAT`.

A hybrid module adds a **compiler toolchain** to that list — the Go toolchain,
or the .NET SDK, at a version — and the checker's most useful property is the
one that gets harder: it currently runs under Windows PowerShell 5.1 so that it
starts on the wrong PowerShell and still tells you why. A toolchain check has to
keep that property while asking questions about tools that may not be on `PATH`,
may be several versions, and may differ between the machine that builds and the
machine that runs.

There is also a new *kind* of prerequisite. Today every one of the five is
present or absent. A toolchain is present **at a version**, and a module built
with one version and graded on a machine with another is a reproducibility
question this project has not had to answer yet.

## 6. The one-machine bound, which is the real cost

Every number in this repository was produced on one machine, by one person, with
one model family. That bound is already stated in the README's honest-status
section, and for script modules it is tolerable: a `.psd1` and a `.psm1` are text
that behaves the same everywhere PowerShell 7.2 runs.

**A compiled artifact is not.** It has a target architecture, a runtime version,
and a build machine, and "it built" stops being a portable claim. The instant a
hybrid profile exists, the honest report needs a second axis — *which platform
was this scored on* — and a single-machine measurement stops being weak evidence
and starts being **inapplicable** to anybody on a different one.

This is the item that makes hybrid support expensive, and it is not a matter of
assertions. Nothing in the enumerated list above costs more than a few passes.
Grading an artifact that means different things on different machines, honestly,
with one machine available, is a measurement problem rather than an engineering
one.

---

## Where this stops

**This becomes a discovery target when the operator schedules it, and nothing is
built before then.**

Not a backlog item quietly acquiring implementation, not a profile half-wired
into the suite, not a `hybrid` branch of one assertion added because it was easy.
The `ModuleProfile` key stays a placeholder that refuses to mean anything, and
its record keeps saying so. When the target is scheduled, this note is the input
to the discovery, and the first question it should be asked is item 6 — because
if that one has no honest answer, the other five are work in service of a number
nobody can defend.
