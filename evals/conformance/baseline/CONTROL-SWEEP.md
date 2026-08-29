# The polarity sweep

Every control recorded before this pass was a **scope** control: a near-miss
break that the named assertion must not notice. Those are worth having, and they
are not the polarity-correct control for a positive assertion.

    The control's shape is determined by the assertion's polarity.
    Positive assertion (must match X): remove X and leave text resembling X;
      the assertion must go RED.
    Negative assertion (must not match X): add text mentioning X without the
      behaviour; the assertion must stay GREEN.

A comment-only probe against a positive assertion cannot fail while the code is
present, and will pass an assertion that is inert. Every positive assertion in
`Universal`, `Repository`, `HouseStyle` and `RequiresBuild` was swept.

**Three defects found, all in assertions that had passed a scope control.**

## The sweep

Outcome is the result of the polarity-correct probe. "Defect" means the probe
gave the wrong answer and the assertion was rewritten.

| Assertion | Tag | Control applied | Outcome | Defect |
|---|---|---|---|---|
| exists, and its base name matches its directory | U | Remove the manifest, leave `PSModuleGraph.psd1.bak` beside it | **did not fire** → fires | **yes** |
| parses as PowerShell data | U | Replace with an unclosed hashtable that still looks like a manifest | fires (over) | no |
| declares a RootModule | U | Delete the key, leave it in a comment | fires | no |
| declares a ModuleVersion that parses as a version | U | Set `'not.a.version'`, leave the real one in a comment | fires | no |
| declares a GUID that parses as a GUID | U | Set `'not-a-guid'`, leave the real one in a comment | fires | no |
| exports no cmdlets, variables, or aliases implicitly | U | Delete `CmdletsToExport`, leave it in a comment | fires | no |
| defines every function the manifest exports somewhere in source | U | Rename the definition, leave the old name in a comment | fires (over) | no |
| gives &lt;name&gt; comment-based help with a synopsis | U | Strip the function's synopsis, add a detached `.SYNOPSIS` elsewhere in the file | fires | no |
| exports functions by explicit name, never by wildcard | U | *negative* — `AliasesToExport = '*'` instead | stays green | no |
| has a build entrypoint at the repository root | R | Rename to `build.ps1.bak` | fires | no |
| has analyzer settings at the repository root | R | Rename to `PSScriptAnalyzerSettings.renamed.psd1` | fires | no |
| has a tests directory | R | Rename `tests/` to `tests.bak/` | fires (over) | no |
| exercises the exported command &lt;name&gt; | R | Remove every invocation, keep the name as a string literal | fires | no |
| places source under src/&lt;ModuleName&gt;/ | H | Move the module out, leave an empty `src/` | fires | no |
| keeps `Public/` flat | H | *negative* — add `Private/Sub/` instead | stays green | no |
| defines exactly one function in &lt;file&gt;, named for the file | H | Rename the function, leave the old name in a comment | fires (over) | no |
| agrees three ways | H | *negative* — drop a name from **both** sides | stays green | no |
| declares the PowerShell editions it claims to support | H | Delete the key, leave it in a comment | fires | no |
| pins build dependencies only in Requirements.psd1 | H | Unpin, leave the pin in a comment | fires | no |
| has a build file named &lt;ModuleName&gt;.build.ps1 | H | Rename to `.build.ps1.bak` | fires (over) | no |
| declares the task &lt;name&gt; | H | Rename the task, leave a block comment quoting its declaration | fires *(defect found and fixed in 0008)* | prior |
| makes the default task Clean, Lint, Build, Test | H | Delete it, leave a block comment quoting it | fires *(0008)* | prior |
| excludes PreTag-tagged tests from the Test task | H | Delete it, leave a comment quoting it | fires *(0008)* | prior |
| disables Pester v5 assertion syntax | H | Delete it, leave a comment quoting it | fires *(0008)* | prior |
| measures coverage against the built psm1 | H | Repoint at the source tree, leave a comment quoting the psm1 line | fires *(0008)* | prior |
| throws rather than exits when tests fail | H | *negative* — comment mentioning `Run.Exit = $true` | stays green *(0008)* | prior |
| throws on coverage below target | H | Delete the throw, with and without its comment | fires *(0002)* | prior |
| produced output/&lt;Name&gt;/&lt;Name&gt;.psm1 | B | Rename the built psm1 to `.psm1.bak` | fires (over) | no |
| marks the generated file as generated | B | Emit a different comment instead of the marker | fires | no |
| sets `$script:ModuleRoot` | B | Emit `# $script:ModuleRoot = $PSScriptRoot` instead of the assignment | **did not fire** → fires | **yes** |
| exports exactly the manifest surface | B | Emit `# Export-ModuleMember -Function …` instead of the call | **did not fire** → fires | **yes** |
| includes functions from Private subfolders | B | Stop including nested files; emit `# function <name>` for every one | **did not fire** → fires | **yes** |
| copies culture directories | B | Match no culture directory; leave a file named `en-US.txt` in the output | fires | no |

"fires (over)" means the assertion went red and other assertions did too. Every
over-fire here is expected coupling — deleting the manifest, the tests directory
or the build file genuinely invalidates everything that reads them.

## The three defects

### Discovery accepted a lone surviving candidate

Removing the reference's own manifest did not make
`exists, and its base name matches its directory` fail. The suite fell back to
the third selection rule — *if exactly one candidate manifest survives, take it* —
and graded the vendored `corpus/PSCorpus/` module instead, reporting on
`src/PSCorpus/` and `PSCorpus.build.ps1`. Silently, as a 40/51.

This is the SqlServerDsc misgrade one rule further down, and it survived the
Pass 0008 repair because that repair only fixed the *first* two rules. A lone
surviving candidate is not evidence that it is the right candidate. The rule is
gone: `$repoName`, then a manifest sitting directly in the target, then nothing.
All nine targets still resolve — the reference by name, the eight corpus modules
by position.

### Three psm1 assertions were text matches over generated content

`sets $script:ModuleRoot`, `exports exactly the manifest surface` and
`includes functions from Private subfolders` all matched regexes against the
built psm1 as text. Each was satisfied by making the build emit a **comment**
where the code should be:

- `# $script:ModuleRoot = $PSScriptRoot -- set elsewhere`
- `# Export-ModuleMember -Function @(...)`
- `# function <name>` in place of each nested private function's body

All three now parse the psm1 and ask for structure: an `AssignmentStatementAst`
to `$script:ModuleRoot`, a `CommandAst` calling `Export-ModuleMember` with the
exported names as string constants inside it, and `FunctionDefinitionAst` names.

`marks the generated file as generated` was left as a text match deliberately.
The marker *is* a comment; matching it as text is matching the thing itself.

## What the sweep says about the earlier controls

The twelve scope controls recorded in Pass 3 all still pass, and all twelve were
run again this pass. None of them would have found any of the three defects
above, because none of them removes the thing the assertion is about. Both kinds
of control are worth having and neither substitutes for the other:

- a **scope** control proves the assertion does not fire on a neighbour
- a **polarity** control proves it fires on its own absence, and not on a
  resemblance left in its place

An assertion with only the first has been shown not to be over-broad. It has not
been shown to work.

## Probe hygiene

Two probes in this sweep were wrong before they were right, both caught by
guards rather than by inspection:

- `pol-private-comment` initially decoyed **one** nested private function while
  removing all of them. It fired — on the names it had not decoyed — and would
  have been recorded as "no defect". A partial decoy is not a control. Decoying
  every name showed the assertion was in fact defeated.
- `pol-psm1-produced` renames build output, so the driver's post-break rebuild
  would have undone it. The row needed an explicit `SkipPostRebuild`.

Both are the same lesson as hazard 4 in HARNESS.md: a probe that silently fails
to perturb what it claims to perturb produces the most dangerous result the
protocol can produce, which is a clean green.

## Control coverage

One row per assertion the suite defines — 33, from the `Assertions` breakdown in
`baseline/psmodulegraph-build-result.json`. **No new controls were run to build
this table**; it records what exists.

*Polarity*: **+** positive (must match X), **−** negative (must not match X).
For a negative assertion the scope and substitution controls are the same probe,
marked *n/a — collapses*.

| Assertion | Pol | Break | Scope control | Substitution control |
|---|---|---|---|---|
| Manifest.exists, and its base name matches its directory | + | yes | **absent** | yes |
| Manifest.parses as PowerShell data | + | yes | **absent** | yes |
| Manifest.declares a RootModule | + | yes | **absent** | yes |
| Manifest.declares a ModuleVersion that parses as a version | + | yes | **absent** | yes |
| Manifest.declares a GUID that parses as a GUID | + | yes | **absent** | yes |
| Manifest.exports functions by explicit name, never by wildcard | − | yes | yes | n/a — collapses |
| Manifest.exports no cmdlets, variables, or aliases implicitly | + | yes | **absent** | yes |
| Public surface.defines every function the manifest exports somewhere in source | + | yes | **absent** | yes |
| Public surface.gives &lt;name&gt; comment-based help with a synopsis | + | yes | yes | yes |
| Repository shape.has a build entrypoint at the repository root | + | yes | **absent** | yes |
| Repository shape.has analyzer settings at the repository root | + | yes | yes | yes |
| Repository shape.has a tests directory | + | yes | **absent** | yes |
| Repository shape.exercises the exported command &lt;name&gt; | + | yes | yes | yes |
| House style: source layout.places source under src/&lt;ModuleName&gt;/ | + | yes | **absent** | yes |
| House style: source layout.keeps `Public/` flat | − | yes | yes | n/a — collapses |
| House style: source layout.defines exactly one function in &lt;file&gt;, named for the file | + | yes | yes | yes |
| House style: source layout.agrees three ways | − | yes | yes | n/a — collapses |
| House style: source layout.declares the PowerShell editions it claims to support | + | yes | **absent** | yes |
| House style: source layout.pins build dependencies only in Requirements.psd1 | + | yes | yes | yes |
| House style: build file.has a build file named &lt;ModuleName&gt;.build.ps1 | + | yes | **absent** | yes |
| House style: build file.declares the task &lt;name&gt; | + | yes | yes | yes |
| House style: build file.makes the default task Clean, Lint, Build, Test | + | yes | yes | yes |
| House style: build file.excludes PreTag-tagged tests from the Test task | + | yes | yes | yes |
| House style: build file.throws rather than exits when tests fail | − | yes | yes | n/a — collapses |
| House style: build file.disables Pester v5 assertion syntax | + | yes | yes | yes |
| House style: build file.measures coverage against the built psm1 | + | yes | yes | yes |
| House style: build file.throws on coverage below target | + | yes | yes | yes |
| House style: generated module.produced output/&lt;Name&gt;/&lt;Name&gt;.psm1 | + | yes | **absent** | yes |
| House style: generated module.marks the generated file as generated | + | yes | **absent** | **n/a — see below** |
| House style: generated module.sets `$script:ModuleRoot` | + | yes | yes | yes |
| House style: generated module.exports exactly the manifest surface | + | yes | **absent** | yes |
| House style: generated module.includes functions from Private subfolders | + | yes | **absent** | yes |
| House style: generated module.copies culture directories | + | yes | **absent** | yes |

### Counts

- **33** assertions, of which **29 are positive** and **4 are negative**.
- Every assertion has a break.
- **12 positive assertions carry both** a scope control and a substitution
  control.
- **16 positive assertions carry only one** — the substitution control, from the
  Pass 0009 polarity sweep. None of the sixteen has a scope control.
- **1 positive assertion carries only a break**, by design: the exception below.
- All **4 negative** assertions are fully covered; their single control answers
  both questions.

### What the counts say about a second sweep

Every positive assertion now has the control that guards against **inertness**.
Sixteen lack the one that guards against **matching too much**.

Those are not equally urgent. An inert assertion contributes a free point to
every score and is invisible; that is the failure this project has actually
suffered, twice, and the substitution sweep is what closed it. An over-broad
assertion produces a *red* — a false alarm, which is loud, gets investigated,
and cannot quietly inflate a score.

So a scope sweep over the sixteen is worth a pass, and it is not worth it before
anything that changes behaviour. It is a hardening pass, not a correctness one.
Note also that a scope control is cheap only where the assertion has a plausible
neighbour to confuse it with; for several of the sixteen — `parses as PowerShell
data`, `declares a GUID` — it is not obvious what a meaningful near miss would
even be, and inventing one to fill a table cell would be exactly the ceremony
this method warns against.

### The deliberate exception

**`House style: generated module.marks the generated file as generated`** keeps
its text match, and has **no substitution control**, on purpose.

The assertion is `$Psm1Text | Should -Match '(?i)auto-generated'`. What it looks
for is a marker comment at the top of the generated file — and the marker *is* a
comment. There is no "behaviour" to remove and leave a resemblance of, because
the comment is the thing itself. A substitution control would have to emit a
comment resembling a comment, which is the same comment.

It does have a break: `pol-generated-marker` makes the emitter write a different
comment, and the assertion goes red. That is the whole of what can be asked of
it.

**Do not "repair" this in a later sweep.** Converting it to an AST check would
mean asserting the presence of a `CommentToken` matching a pattern, which is a
text match with more ceremony around it, and it would break the moment the
marker's wording changed. The three sibling assertions in this Describe were
converted because they matched *code* as text; this one matches prose as prose,
which is correct.
