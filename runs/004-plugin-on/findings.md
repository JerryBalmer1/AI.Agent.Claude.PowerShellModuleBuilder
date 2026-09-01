# Run 004 findings

By mechanism, not by symptom. Observed is what this run reproduced; inferred is
what it concluded from one instance and has not tested twice.

---

## F-1. The build skill's `Test` task template produces a coverage gate that cannot fail

**Severity: high. Observed, reproduced in both directions.**

`skills/powershell-module-build/SKILL.md`, under *Test configures Pester, and the
coverage throw is the gate*, gives this:

```powershell
$result = Invoke-Pester -Configuration $cfg
$coverage = $result.CodeCoverage
$percent  = [math]::Round($coverage.CoveragePercent, 2)
$target   = $coverage.CoveragePercentTarget
if ($percent -lt $target) { throw "..." }
```

**`Invoke-Pester -Configuration` returns nothing unless `Run.PassThru` is set,**
and the template never sets it. The chain that follows is silent at every step:

| Step | With PassThru | Without |
|---|---|---|
| `$result` | a run object | `$null` |
| `$coverage.CoveragePercent` | `94.91` | `$null` |
| `[math]::Round($null, 2)` | `94.91` | `0` |
| `$coverage.CoveragePercentTarget` | `70` | `$null` → `''` |
| `if (0 -lt '')` | — | `''` coerces to `0`; `0 -lt 0` is **false** |

The build printed `Line coverage: 0% (target %)` and exited **0**. Pester had
computed and printed `Covered 90.31% / 70%` four lines earlier; the gate simply
never saw it.

This is the defect class the same skill warns about two sections earlier — *"An
assertion or gate that has only ever passed is indistinguishable from one that
cannot fail. Break it once on purpose and watch it go red before trusting it."*
The template ships an instance of it.

**The same omission breaks the `PreTag` guard in the opposite direction.** That
guard is `if (($result.PassedCount + $result.FailedCount) -eq 0) { throw }`. On a
null result that is `0 -eq 0`, so `-Task PreTag` throws *"The PreTag filter
selected no test at all"* on every run, including runs where every seal passed.
A repository following the skill gets one gate that can never fail and one that
can never pass, from one missing line.

**Neither the conformance suite nor a green build can catch it.** This run scored
57/57 *including* the assertion *"throws on coverage below target rather than
only reporting it"* — which is true: the `throw` is structurally present inside
an `if` reading a coverage percentage. The assertion tests that the gate exists,
not that it can fire.

**Fixed and falsified.** `Run.PassThru = $true` in both tasks; then the target
was raised to 99 against real coverage of 94.91% and the build went red with
exit 1, and restored to 70. Recorded here because the falsification is the only
evidence that the fix worked — the green run before and the green run after look
identical.

---

## F-2. `azdo-graph-assembly`'s repository-node rule is too narrow, and loses a node

**Severity: medium. Observed, one instance.**

The skill states the rule twice, absolutely:

> A repository nothing references is not in the graph. Repository nodes exist
> because pipeline YAML references them through `resources.repositories` or
> `checkout` — never because the project contains them.

The oracle has `repo:consumer-app` with **zero inbound edges**. Nothing in the
fixture references it. It is there because `consumer-app` *holds* two pipeline
definitions (`x01-consumer-build`, `x02-platform-release`) and three YAML files.

Following the skill literally produces one `missingNode` and a 48-node graph
against a 49-node oracle.

**The rule that fits both the oracle and the skill's own motivation:** a
repository is a node when the graph has something *in* it — a pipeline
definition or a YAML file — **or** when a reference names it. The empty
`ClaudeTesting` repository holds neither and is referenced by nothing, and stays
out, which is the case the "never because the project contains them" clause
exists to protect. The clause is right about the *repositories endpoint* and
wrong as a statement about repository nodes in general.

This was the single non-convention difference among 26, which is exactly where
`producer-contract` says to look: *"the single difference is where the real
defect hides."*

---

## F-3. The plugin teaches the optional-field principle and then contradicts it by example

**Severity: medium for score, low for correctness. Observed, three instances.**

`producer-contract` is unambiguous that an absent optional field means *not
stated*, and that getting one wrong costs one difference per record. It is the
most useful thing in the plugin for this problem.

`azdo-graph-assembly` then shows the output shape as a single example object
with **every** optional field present:

```json
"nodes": [ { "id": "...", "kind": "...", "name": "...", "repo": "...", "path": "repos/..." } ],
"edges": [ { "from": "...", "to": "...", "kind": "...", "ref": "...", "refKind": "...", "alias": "...", "reason": "..." } ]
```

with no statement of when each is absent. A builder reading it as a template
writes them all; a builder reading `producer-contract` writes none it cannot
justify. Both readings are defensible and both are wrong, in opposite
directions.

23 of this run's 26 first-shot differences were three such conventions:

| Field | I wrote | Oracle | Cost |
|---|---|---|---|
| `repo` on `pipeline` nodes | omitted (redundant with the definition edge) | present | 15 |
| `alias` on `template`/`extends`/`checkout` | present (for consistency with resource edges) | absent | 8 |
| `refKind` on resolved edges | omitted | absent | 0 — got this one right |

The `refKind` reasoning and the `alias` reasoning were the *same* argument —
*"kind already carries it"* / *"ref already carries it"* — and I applied it to
one and not the other. The plugin gives no way to tell which way each field
goes, and the schema's `if/then` only pins the required ones.

**What would fix it:** one table in `azdo-graph-assembly` saying, per field,
written-or-absent and why. That is a change to the instrument, not to this run.

---

## F-4. The `reason` string format is stated nowhere, and the skill teaches the wrong value

**Severity: medium. Observed.**

`azdo-pipeline-yaml-refs` gives the two reasons as a table of bare codes:

| Reason | Means |
|---|---|
| `file-not-found` | the alias resolved (or none was used) but no such file exists |
| `alias-not-declared` | the `@alias` has no `resources.repositories` entry |

`graph.schema.json` says only `"type": "string", "minLength": 1`. Both are
consistent with writing `reason: "file-not-found"`, which is what I wrote.

The oracle writes a code **and** an explanation:

```
file-not-found: resolved to pipelines/templates/missing-steps.yml in pipelines-main, which does not exist
alias-not-declared: 'ghostTemplates' is not in resources.repositories of pipelines/p09.yml, so the repository is unknown and the path cannot be resolved at all
```

The explanation is not decoration: it names the **resolved** path and
repository, which is the output of whichever of the two resolution rules ran,
and is the half a reader cannot reconstruct from the reference text. The
`alias-not-declared` form names the file that made the reference, which is where
the fix goes.

Cost: 2 differences, and both fall on `case-09`, so the case fails on the
formatting alone even though the resolution was exactly right.

The skill's table is presented as *the* reason values. It should say the code is
a prefix.

---

## F-5. `powershell-module-build`'s example contradicts its own prose on runtime dependencies

**Severity: low. Observed. Nothing grades it either way.**

The skill's `Requirements.psd1` example lists `'powershell-yaml'` alongside
InvokeBuild, Pester and PSScriptAnalyzer. Two paragraphs later:

> This is the **only** place dependencies are pinned. Do not also pin them in
> the manifest's `RequiredModules` […] `RequiredModules` in the manifest is for
> **runtime** dependencies, which are a different thing from build ones.

`powershell-yaml` is a runtime dependency of this module — it is imported to
parse a document, not to build one. The example puts a runtime dependency in the
build-tool file; the prose says runtime dependencies belong in the manifest and
must not be written twice.

I followed the prose: `powershell-yaml` in `RequiredModules`, build tools in
`Requirements.psd1`. Conformance scored 33/33 either way, so nothing in the
instrument distinguishes them. Recorded because the next reader will hit the
same fork and may go the other way, and then the two runs differ for a reason
that is not the model.

---

## F-6. `/build` step 1 cannot be followed under the blind-run allowlist

**Severity: process. Not a defect in either artifact.**

`commands/build.md` step 1 is *"Read the contract before writing code —
`evals/conformance/Conformance.Tests.ps1`"*, with *"Do not infer the conventions
from memory. They are graded exactly."*

This run's Phase 1 allowlist forbids everything under `evals/` except the seed,
`BRIEF.md` and `fixture/graph.schema.json`. So the plugin-on run cannot follow
the plugin's own build command, and the conventions had to come from the skills
alone.

**That makes the conformance score a measurement of skill-fidelity rather than
suite-fidelity** — of whether the skills are a faithful proxy for the assertions.
The result is that they are: 33/33 cases-defined, 57/57 cases-run, first shot,
with the suite unread. That is now a measured claim rather than an assumption,
and it is arguably a more interesting number than one obtained by reading the
assertions first.

The collision should be resolved deliberately: either the command's step 1 gets
a blind-run carve-out, or the allowlist admits the suite and the conformance
number stops meaning this.

---

## F-7. Two failure modes the plugin does and does not cover

**Severity: low. Observed. One success, one gap.**

**Covered, and it paid.** The mock declared with `-ModuleName` runs in the
*module's* session state, where the test file's `$script:Files` does not exist.
The null reference surfaced as:

```
A 'break' or 'continue' statement with a label that does not match any
enclosing loop escaped from your code.
```

against the whole container, naming nothing — 21 tests failed with blank
messages. `powershell-module-test` names this exact symptom and prescribes the
fix: *"When a `Describe` fails that way, call the code under test directly to
find the real error."* Doing precisely that produced `CommandNotFoundException:
Get-AzDoCachedYaml` in one step. Without the skill this would have been a long
detour; with it, it was two minutes.

**Not covered.** The real error underneath was `.GetNewClosure()`. A closure is
rebound to a **fresh dynamic module**, so module-private functions are no longer
visible from it — which makes `GetNewClosure` actively wrong for any predicate
built inside a module that calls the module's own private helpers. Nothing in
the plugin mentions it. It is a good candidate for a line in
`powershell-module-architect` or `powershell-module-scaffold`, because the
failure is silent at authoring time and surfaces under F-7's opaque message.

---

## F-8. The instruction to re-derive the Pester assertion list is the thing that worked

**Severity: none. Observed. Recorded as a plugin success.**

`powershell-module-test` says *"Re-derive the real list rather than remembering
it"* and gives the command. I ran it, and still wrote `Should-NotThrow` and
`Should-NotBeNullOrEmpty` from habit in a later file; the build caught both, and
the derived list was already on hand to fix them against.

For the record, and because the skill's phrasing is easy to misread:
`Should-NotBeNull` **does** exist in Pester 6.1.0. `Should-NotBeNullOrEmpty` and
`Should-NotThrow` do not. The skill is accurate; the near-miss is in the reader.

---

## Not a plugin finding: a tooling hazard in this run

Two source files reached disk with a regex backslash consumed — `-replace '\',
'/'` instead of `-replace '\\', '/'` — because they were written through a shell
heredoc. Both failed loudly and immediately (`The regular expression pattern \ is
not valid`), and both were rewritten through a path that does not re-interpret
the content.

Recorded because it is a hazard of *how* a run writes files rather than of what
it writes, it is invisible in the finished repository, and a run that hit it in a
regex that still compiled would not have found out.
