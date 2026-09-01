# Run 005 findings

By mechanism, observed separated from inferred. Run 004's findings are cited
where this run met the same thing; that citation was written after the gate
lifted, and every mechanism below was hit before `runs/004-plugin-on/` was
opened.

The headline: **every one of run 004's eight findings recurred**, at the same
sites, from the same instructions, in a session that had not read them. The
plugin SHA is unchanged, so this is what a fixed instruction set reproduces.

---

## F-1. The build skill's `Test` template still ships a coverage gate that cannot fail

**Severity: high. Observed, falsified in both directions. Recurrence of 004 F-1.**

`skills/powershell-module-build/SKILL.md` gives the `Test` task as

```powershell
$result = Invoke-Pester -Configuration $cfg
$coverage = $result.CodeCoverage
$percent  = [math]::Round($coverage.CoveragePercent, 2)
$target   = $coverage.CoveragePercentTarget
if ($percent -lt $target) { throw "..." }
```

and never sets `Run.PassThru`. `Invoke-Pester -Configuration` returns nothing
without it, so `$result` is `$null`, `$percent` rounds `$null` to `0`, `$target`
is empty, and `0 -lt $null` is `$false`. The gate never fires.

Copied faithfully, it produced this on the first green build of this run:

```
Line coverage: 0% (target %)
Build succeeded. 5 tasks, 0 errors, 0 warnings
```

Both halves of the line are empty and the build is green. A reader scanning for
a number sees one.

**Falsified after fixing it**, because a gate that has only ever passed is
indistinguishable from one that cannot:

| | Target | Actual | Exit | Message |
|---|---|---|---|---|
| control | 40% | 94.26% | 0 | `Line coverage: 94.26% (target 40%)` |
| broken | 99% | 94.26% | 1 | `Line coverage 94.26% is below the target of 99%.` |

The same was done to the `PreTag` guard — control `PreTag: 5 passed`, exit 0;
with the tag filter pointed at a tag no test carries, exit 1 and *The PreTag
filter selected no test at all.*

**Worth more than the fix:** run 004 reported this finding and the skill still
contains the defect, because `skills/` is frozen behind the ladder at
`f25d05d`. Run 005 walked into it independently. That is the clearest evidence
the ladder can produce that the finding is a property of the instruction rather
than of a session.

**Near-miss worth recording.** The first attempt to falsify the gate was itself
a false red. `pwsh -NoProfile -File ./build.ps1 -Task Build,Test` invoked from
bash passes `Build,Test` as a single token, and InvokeBuild aborted with
*Missing task 'Build,Test'* — exit 1, before either gate ran. Both falsifications
appeared to pass and had proved nothing. Only reading the log rather than the
exit code caught it. A falsification that is not itself checked is the same
hazard one level up.

---

## F-2. `azdo-graph-assembly`'s repository-node rule is too narrow

**Severity: medium. Observed. Recurrence of 004 F-2 — the same single node.**

The skill is unambiguous:

> **A repository nothing references is not in the graph.** Repository nodes exist
> because pipeline YAML references them through `resources.repositories` or
> `checkout` — never because the project contains them.

Followed exactly, the graph came back with three repository nodes. The oracle has
four. `repo:consumer-app` has **zero inbound edges** in the oracle: nothing
references it. It is there because it *hosts* two pipeline definitions.

The rule the oracle actually follows is *referenced by a pipeline, or hosting
one*. Both readings still exclude the empty `ClaudeTesting` repository, which is
case 12 and which passed at first shot under the narrow rule.

This was **the single difference** among 26 at first shot — the one real defect,
and the smallest number on the page, exactly as `producer-contract` predicts.

**Inferred, not observed:** the skill's sentence is probably defending against
enumerating the repositories endpoint into nodes, which is a different and worse
error. The narrow phrasing catches a correct implementation on the way past.

---

## F-3. The plugin teaches the optional-field principle and then contradicts it by example

**Severity: medium. Observed twice, in opposite directions. Recurrence of 004 F-3.**

`producer-contract` is explicit: *an absent optional field means NOT STATED*, and
*before writing any optional field, answer: do I have something to say here?*
`graph.schema.json` marks `repo` optional on every node kind and requires it only
on `yaml` nodes, and marks `alias` optional on every edge.

Applying the principle produced two wrong answers at once:

| Decision | Reasoning applied | Oracle |
|---|---|---|
| `repo` omitted from `pipeline` nodes | the schema requires it only on `yaml`; a pipeline is not a file | present on every `pipeline` node — **15 differences** |
| `alias` written on every aliased edge | the reference was made through an alias; that is a positive fact | present only on `repositoryResource` and `pipelineResource` — **8 differences** |

The rule the oracle follows for `alias` is *state it only where the `ref` does
not already carry it*: a template's alias is inside its `ref` text
(`templates/steps-build.yml@mainPipelines`) and a `checkout`'s `ref` **is** the
alias, so both are redundant; a resource declares an alias nothing else states.

That rule is a good one. **It is written down nowhere** — not in the schema, not
in `azdo-graph-assembly`, not in `producer-contract`. Both alternatives are
defensible from the documents, which is why 23 of the 26 first-shot differences
are here.

---

## F-4. The `reason` string is prose that nothing specifies

**Severity: medium. Observed. Recurrence of 004 F-4.**

`azdo-pipeline-yaml-refs` gives two reasons, `file-not-found` and
`alias-not-declared`, and says to keep them distinct because they need different
fixes. `graph.schema.json` says `reason` is a string of `minLength: 1`.

The oracle wants a sentence:

```
file-not-found: resolved to pipelines/templates/missing-steps.yml in pipelines-main, which does not exist
alias-not-declared: 'ghostTemplates' is not in resources.repositories of pipelines/p09.yml, so the repository is unknown and the path cannot be resolved at all
```

The token the skill teaches is the *prefix* of the value the oracle holds. A
producer that follows the skill exactly writes `file-not-found` and is marked
wrong on a string comparison.

**This is the one mechanism a plugin-on run cannot avoid.** The other three are
choices between documented alternatives; this one requires guessing hand-written
prose. Matching it — as this run did in iteration 1 — is fitting to this fixture,
not a general capability, and should be read that way. The honest fix is in the
comparator or the schema: either compare `reason` by its token, or state the
`token: explanation` format where a producer can read it.

---

## F-5. `powershell-module-build` contradicts itself on runtime dependencies, and 005 took the other fork

**Severity: low, and it is the interesting one. Observed. Recurrence of 004 F-5 —
resolved the opposite way.**

The skill's `Requirements.psd1` example lists `'powershell-yaml'` beside
InvokeBuild, Pester and PSScriptAnalyzer. Two paragraphs later the prose says
`Requirements.psd1` is *the only place dependencies are pinned*, that
`RequiredModules` is for runtime dependencies, and that neither is a reason to
write the other one twice.

`powershell-yaml` is a runtime dependency. The example puts it in the build file
anyway.

- **Run 004 followed the prose**: manifest only, removed from `Requirements.psd1`.
- **Run 005 followed the example**: both files, with a comment explaining that it
  is genuinely both — the module parses YAML at run time and the build's tests
  exercise that path.

Conformance scored **33/33 either way**. Nothing in the instrument distinguishes
them.

Run 004 predicted this exact divergence — *"the next reader will hit the same
fork and may go the other way, and then the two runs differ for a reason that is
not the model"* — and run 005 is that reader. It is the only source-level
disagreement between the two builds that the score cannot see.

---

## F-6. `/build` step 1 cannot be followed under the blind-run allowlist

**Severity: process. Declined, not breached. Recurrence of 004 F-6.**

`commands/build.md` step 1 is *Read the contract before writing code —
`evals/conformance/Conformance.Tests.ps1`*. The Phase 1 allowlist forbids it.

Declined under the declined-not-breached rule and recorded here. The conformance
number therefore measures whether the skills are a faithful proxy for assertions
that were never read. They are: 33/33, first shot, from a fresh clone.

---

## F-7. `.GetNewClosure()` is present in this build too, and is latent rather than fixed

**Severity: medium, and it is a near-miss. Observed. Same site as 004 F-7.**

Run 004 found that a closure is rebound to a fresh dynamic module, so
module-private functions stop being visible from it, and that nothing in the
plugin says so.

Run 005 wrote the same `.GetNewClosure()` at the same place — the file-existence
predicate handed to `Resolve-AzDoPipelineReference` — and did **not** hit the
failure, for one reason: the closure calls `Get-AzDoPipelineYaml`, which is
exported, so it resolves from the caller's session state. Had the same code
called a private helper, the same opaque
*break or continue statement … escaped from your code* would have followed.

So the hazard is not absent from this run; it is one refactor away, and the
module ships it. That is worse than hitting it, because nothing marks it.

**Recommendation unchanged from 004:** one line in
`powershell-module-architect` or `powershell-module-scaffold`.

---

## F-8. Re-deriving the Pester assertion list worked again

**Severity: none — a thing that went right. Recurrence of 004 F-8.**

`powershell-module-test` says to re-derive the `Should-*` list rather than
remember it. Done, and it immediately contradicted three names written from
memory in the first draft of the suite:

| Written from memory | Actually exists |
|---|---|
| `Should-Contain` | `Should-ContainCollection` |
| `Should-Not-Contain` | `Should-NotContainCollection` |
| `Should-NotBeNullOrEmpty` | does not exist — `Should-NotBeNull` |

The skill also states outright that `Should-NotBeNullOrEmpty` does not exist, and
it was still written. The instruction that saved it was the one that said *run
this command*, not the one that said *this is the list*.

---

## F-9. A culture directory is optional, and its absence makes a graded case inapplicable

**Severity: low, and it is the first exercise of pass 0025's denominator.**

`powershell-module-scaffold` lists `en-US/` as *optional; if present the build
must copy it*. Run 004 shipped one; run 005 did not.

The conformance case *copies culture directories so Get-Help finds about_ topics*
calls `Set-ItResult -Skipped` when a module ships none. So:

| | cases-defined | cases-run | passed | skipped |
|---|---|---|---|---|
| run 004 | 33 | 57 | 57 | 0 |
| run 005 | 33 | 56 | 56 | 1 |

Per-assertion `Ran` counts were compared across the two result files and differ
nowhere else; the whole of the difference is that one skip.

**This is the case pass 0025 was written for.** `cases-run` moved with an
optional feature of the target and `cases-defined` did not, so the two runs are
comparable at 33/33 and would have been incomparable at 57 versus 56. Reported as
*inapplicable*, never as a pass, per `/test`.

---

## F-10. The back-edge report cannot tell a cycle from a diamond

**Severity: low. Observed in this module, and it is this run's own defect.**

`azdo-graph-assembly` says *report the back edges you found*, because *a cycle
that terminates silently is indistinguishable from no cycle*. This module reports
every edge whose target was already visited. On the live fixture that is seven
edges, of which the genuine cycle is one:

```
yaml:pipelines-main/pipelines/templates/cycle-b.yml -> …/cycle-a.yml   <- a cycle
yaml:pipelines-main/pipelines/p07b.yml -> …/diamond-shared.yml         <- a diamond
yaml:templates-shared/pipelines/nightly.yml -> …/steps/common.yml      <- a shared template
```

In a breadth-first walk an edge to a visited node is usually a *cross* edge — a
diamond or a shared template, which is the structure the graph exists to show —
and only an edge to an ancestor closes a cycle. Warning about all of them
reports five ordinary shared templates as if they were cycles.

The graph itself is unaffected: every edge is recorded before the visited check,
both cycle edges are present, and the comparison is 0 differences. Only the
warning is wrong. Distinguishing them needs the path to the current node, which
the queue does not carry.

Left as a finding rather than fixed: the iteration budget was spent on
differences against the oracle, and nothing grades this.
