# Run 007 — findings by mechanism

Grouped before the counts were read. Each entry says what was observed, what was
inferred, and which channel the correction came from — that last column is the
one this run exists to record, because "the plugin was unread" is not the same
claim as "no convention information was available".

---

## Part 1 — the functional first shot: 14 differences, five mechanisms

The whole first-shot diff is in [diff-first-shot.txt](diff-first-shot.txt).

| # | Count | Mechanism | Kind |
|---|---:|---|---|
| F-1 | 8 | `alias` written on edges that *use* an alias | convention |
| F-2 | 2 | `reason` written as a bare token, not `token: explanation` | convention |
| F-3 | 2 | unresolved edge target written `unresolved:<ref>` | convention |
| F-4 | 1 | `checkout: self` emitted as an edge | judgement |
| F-5 | 1 | the empty repository emitted as a node | judgement |

**0 `missingNode`, 0 `missingEdge`, 0 `wrongEdgeKind`.** As in run 003 and as in
all three plugin-on runs, nothing the oracle has was absent and nothing was
pointing at the wrong file. Both anchoring rules resolved correctly, the cycle
terminated, the diamond collapsed to one node with in-degree 2, the `extends`
edge was not confused with a `template` edge, the parameter whose value looks
exactly like a template path was not followed, and both unresolved references
landed on the oracle's exact repository and path. The failures were all in how
facts were *recorded*, not in which facts were computed.

### F-1 — `alias` on edges that use an alias (8)

**Observed.** The schema allows `alias` on any edge, beside `ref` and `refKind`,
which are fields describing the reference as written. `steps/common.yml@shared`
names an alias; so does `checkout: shared`; so does the `repository:` key of a
repository resource. All three were treated alike and given `alias`.

**Expected.** `alias` appears only where an alias is *declared* — the
`repository:` key of a repository resource, the `pipeline:` key of a pipeline
resource. On an edge that merely uses one, it is absent; the use is already in
`ref`.

**Why the reading was wrong.** The distinction is declaration versus use, and
nothing in `BRIEF.md` or `graph.schema.json` draws it. The schema's own
description of `ref` — "the reference exactly as it appears in the YAML" —
arguably points at recording everything as written, which is what was done.

**Fixed** in iteration 1, in two passes: the first narrowed `alias` to
repository resources only, which over-corrected and left 3 differences on
pipeline resources; the second stated the rule as *declaration, not use* and got
both. That the corrected rule is one sentence, and covers both resource kinds,
is the reason to think it is the real convention rather than a fit to the diff.

### F-2 — bare `reason` (2)

**Observed.** `alias-not-declared` and `file-not-found`. Short, stable, groupable
tokens — the shape chosen deliberately because a prose sentence in a compared
field drifts and cannot be asserted on.

**Expected.** `token: explanation` —
`alias-not-declared: 'ghostTemplates' is not in resources.repositories of
pipelines/p09.yml, so the repository is unknown and the path cannot be resolved
at all`.

**Both concerns are real and the oracle serves both**: the token is still first
and still groupable, and the sentence after it means the edge can be acted on
without reopening the YAML. This is the one mechanism where the expected form is
strictly better than what was built, rather than merely different.

**Fixed** in iteration 1. **Channel: the comparator printed the expected string
verbatim.** See Part 3.

### F-3 — unresolved edge targets (2)

**Observed.** `unresolved:<ref>` — a deterministic pseudo-id, chosen because the
target does not exist and inventing a `yaml:` id for it seemed to assert
something false.

**Expected.** The id the reference *would* have had:
`yaml:pipelines-main/pipelines/templates/missing-steps.yml` for a missing file,
and `yaml:@ghostTemplates/steps/common.yml` where even the repository is unknown
— the alias standing in the repository slot.

**Why the expected form is better.** It makes the edge actionable: it says where
the file should have been. And it makes two references to the same missing file
from different documents converge on one target, which `unresolved:<ref>` does
not, because the ref text differs with the referring file.

**Fixed** in iteration 1.

### F-4 — `checkout: self` as an edge (1)

**Observed.** Every `checkout` was an edge to a repository, including `self`.

**Expected.** No edge for `self`. It names the repository the file is already in
— a build instruction, not a dependency the file would not otherwise have.
`checkout: <alias>` *is* an edge, because it pulls in a second repository.

**Fixed** in iteration 1. The rule is defensible on its own terms once stated,
and the module's README now states it.

### F-5 — the empty repository as a node (1)

**Observed.** All five repositories in the project became `repo` nodes,
including `ClaudeTesting`, which has no commits and which nothing references.
This was a deliberate, argued choice: the first draft of the module's README
said "a project with an empty repository must not look identical to a project
without one."

**Expected.** Four nodes. A repository earns a node by taking part — by holding
one of the YAML files, or by being the target of an edge.

**The argument was sound and the scope was wrong.** "Which repositories exist"
is a question about the project and is what `Get-AzDoRepository` answers; it
still lists the empty one. "Which repositories are depended on" is the question
the *graph* answers, and an unreferenced empty repository is a node with no path
to any pipeline. Both facts are still available, from the command that owns each.

**Fixed** in iteration 1.

---

## Part 2 — the mechanism that did not occur

### F-0 — `repo` on `pipeline` nodes (0 differences)

This is the largest single mechanism in run 003 (15 of 29) and in every
plugin-on first shot (15 of 26). It did not occur here.

`repo` was written onto `pipeline` nodes at first shot, from one line of
`BRIEF.md`: *"`Get-AzDoPipeline` — the pipeline definitions registered in a
project, **each with the repository and path its YAML lives at**."* A pipeline
definition is a registration pointing at a file in a repository; the repository
is half of what the definition *is*, so it went on the node.

Because the case tags live on `pipeline` nodes, this one property is worth
eleven of the twelve cases on its own. Its presence is the entire difference
between this run's first shot (6/12) and run 003's (0/12): **strip F-0 from run
003's 29 differences and the remaining 14 are, mechanism for mechanism and count
for count, exactly this run's 14.** The two blind runs made the same five
mistakes and differed on one property.

That is a single observation, not a trend. It is as consistent with variance
between two blind sessions as with anything about this run's reading of the
brief, and it should not be quoted as though the brief reliably yields it.

---

## Part 3 — the channel the corrections came through

**The plugin was never opened, before or after the gate.** That is true and
verifiable: `git diff v1.0.0..HEAD -- skills/ commands/ .claude-plugin/` is empty
and no read of those paths appears in the transcript.

**It does not follow that no convention information was available.** Two other
channels carried it, and the honest reading of "12/12 without the plugin"
depends on saying so.

**C-1. `Compare-Graph` prints the expected value.** For `wrongEdgeAttribute` and
`wrongEdgeTarget` it names the field, the candidate's value and the oracle's
value. F-2's exact 30-word reason string was not re-derived from the brief; it
was read out of the diff and reproduced. F-1, F-3, F-4 and F-5 were also
diagnosed from the diff, though each of those is a rule that can be stated in one
sentence and defended, which the reason string is not.

This is not a breach — it is what an iteration *is*, and the plugin-on runs had
the same comparator and the same three-iteration budget. But "converged to 12/12
without the conventions being readable anywhere" is false as stated. The
conventions were readable *from the scorer*, one difference at a time, after the
first shot. What the control shows is that they were **not needed in advance**,
not that they were absent.

**C-2. This pass's own prompt named the mechanisms.** The prompt is on the Phase
1 read-allowlist and its step 7 lists *"the four convention mechanisms (15
repo-on-pipeline, 8 alias-edge, 2 bare-reason, 1 consumer-app)"* so that this
document can report against them. A builder reading its instructions therefore
saw the names and counts of three of the five mechanisms it was about to be
scored on, before writing a line.

Three of the four named were reproduced anyway (F-1 at 8, F-2 at 2, and a
consumer-app difference at 1), which is weak evidence the leak did not steer the
build. The fourth, F-0, was *not* reproduced — and F-0 is precisely the one a
leak would most plausibly have prevented. **This run cannot separate "read the
brief carefully" from "was told the answer" for F-0, and its 6/12 first shot must
be read with that attached.** It is a defect in the pass design, not in the
build; the fix is to keep the mechanism list out of the builder's prompt and put
it in the scoring instructions instead.

**C-3. The live fixture is annotated.** Reading the fixture through the module —
which the protocol requires — returns YAML whose leading comments name the cases
and state what each is for: *"`templates/steps-build.yml` from pipelines/p01.yml
is pipelines/templates/steps-build.yml. There is a second file at the repo root
… Both exist, so the wrong answer is a wrong file rather than an error."* Any
blind builder sees these. They explain the resolution semantics but say nothing
about output conventions, which fits the observed result: the traversal was right
first time in every run, blind or not, and the conventions were not.

---

## Part 4 — two defects the oracle never saw

Both were found by this run's own tests, not by scoring, and both would have been
real bugs in a real deployment.

### D-1 — the empty repository was silently dropped

`Get-AzDoRepository` read `$repo.defaultBranch` directly. A repository with no
commits has no `defaultBranch` **property at all** — not a null one — so under
`Set-StrictMode -Version Latest` the read threw, and the pipeline swallowed the
terminating error per object: four repositories came back where five exist, with
a `PropertyNotFoundException` on the console and no gap in the output.

Caught on the first live query, by counting. Fixed by testing
`PSObject.Properties[...]` before reading. The regression test uses a mock whose
third repository object omits the property entirely, because one that sets it to
`$null` does not reproduce the failure.

This is the exact failure mode the module exists to avoid, one level up: a thing
that is missing looks identical to a thing that is fine.

### D-2 — `Export` concatenated an absolute path onto the working directory

`Join-Path (Get-Location) $Path` produces `C:\here\C:\there` when `$Path` is
already rooted. Every use in this run passed a relative path, so it never fired;
the first absolute path came from `$TestDrive` in the iteration-2 test suite.

Fixed by testing `IsPathRooted` first, and by resolving against
`(Get-Location).ProviderPath` rather than the process working directory, which
PowerShell does not keep in step with `Set-Location`.

Worth recording because it is an argument for the mocked end-to-end tests as
such: they were written to satisfy a conformance assertion about exercising every
exported command, and they found a defect in the one command the fixture walk
could never have exercised.

---

## Part 5 — conformance, and one artefact of the scoring rule

First shot **19/33** cases-defined; final **28/33**. The full first-shot result is
[conformance-result-first-shot.json](conformance-result-first-shot.json).

### C-4 — thirteen of fourteen house-style failures were recoverable

First shot had no `PSAzureDevOpsGraph.build.ps1`, no `Requirements.psd1`, no
`PSScriptAnalyzerSettings.psd1`, a `build.ps1` that staged a file tree instead of
generating a single `.psm1`, and four exported commands no test invoked. All are
conventions of a house whose other repository was not readable. Thirteen were
recovered across iterations 2 and 3, from the grader's failure messages — the
same channel as C-1, and the same caveat.

### C-5 — four `RequiresBuild` cases are unreachable under the scoring rule

*produced output/…psm1*, *marks the generated file as generated*, *sets
`$script:ModuleRoot`* and *exports exactly the manifest surface* all read
`output/`, which is `.gitignore`d and therefore absent from a fresh clone. The
protocol scores in three **independent** clones — build in one, conformance in
another — so the conformance clone never has build output. The assertion's own
message says so: *"because run the build before the RequiresBuild tag"*.

Re-scored in one clone with the build run first, the same commit gives **32/33**
— [conformance-result-built-clone.json](conformance-result-built-clone.json). The
module satisfies all four; the protocol cannot see it.

**28/33 is the number this run reports**, because it is what the protocol
prescribes and what the ladder was scored under. But the gap between 28 and 32 is
a property of the scoring procedure, and comparing 28 against the ladder's 33/33
overstates the difference by four. The three plugin-on runs reported 33/33 with
`RequiresBuild` counted as passing, which means their conformance job saw build
output; how, given the same three-clone rule, is not recorded in their READMEs
and is worth resolving before the next comparison. Run 005's README documents the
opposite failure — a race where `Clean` deleted `output/` *while* the
`RequiresBuild` tag was reading it — which implies its jobs shared a tree at that
point. **The three-clone rule and the `RequiresBuild` tag are incompatible, and
the ladder's conformance numbers may not all have been produced the same way.**

### C-6 — one assertion unmet after three iterations

*throws on coverage below target rather than only reporting it.* The Test task
does compare and does throw:

```powershell
$covered = [math]::Round($result.CodeCoverage.CoveragePercent, 2)
$target  = $config.CodeCoverage.CoveragePercentTarget.Value
if ($covered -lt $target) { throw "Coverage $covered% is below the target of $target%." }
```

The assertion inspects the task body's AST and reports *"nothing in the Test task
compares coverage against a target"*. Two shapes were tried — a comparison
against the `$CoverageTarget` parameter, then against the configuration value —
and neither matched. Without reading the assertion's implementation there is no
third guess to make from the message alone, and the budget was spent. It is
recorded unmet rather than worked around.

This is the clearest single measurement of what the plugin is worth: an assertion
about a convention, whose failure message does not contain enough to reconstruct
the convention. Every other house-style failure did.
