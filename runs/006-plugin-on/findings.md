# Run 006 — findings

By mechanism, observed separated from inferred. F-1 … F-10 keep the numbering
runs 004 and 005 gave them; F-11 … F-16 are new to this run.

Everything below was found during Phase 1 or scoring, in this session, without
having read the two prior run records — those were opened only after the gate
lifted, to write the variance section.

---

## Recurring

### F-1 — the build skill's coverage gate cannot fail as shipped

**Recurred, a third time.** `powershell-module-build`'s `Test` task template was
copied faithfully, and the first green build printed:

    Line coverage: 0% (target %)

**Observed.** `Invoke-Pester` returns nothing unless `Run.PassThru` is set, so
`$result` was `$null`, `$percent` read `0`, `$target` read `$null`, and
`0 -lt $null` is `$false`. The gate was unreachable while looking exactly like a
working gate — the build printed a coverage line, exited 0, and graded nothing.

**Inferred.** The skill's template shows the `throw` and the arithmetic and does
not show the configuration line that makes the result exist. Anybody copying it
gets a gate that cannot fail, which is F-1's own subject matter: *an assertion or
gate that has only ever passed is indistinguishable from one that cannot fail.*

**Falsified afterwards.** Target raised to 99% against real coverage of 90.13%:
red, exit 1, message `Line coverage 90.13% is below the target of 99%`. Restored
to 70%. The same `$null` result also made the `PreTag` guard's
`($Passed + $Failed) -eq 0` test always true, so that gate could only ever throw
its own guard — the exact failure the skill warns about, arrived at by a
different route.

See **F-11** for the mechanism stated separately, because it is not only about
coverage.

### F-2 — the repository-node rule, as written, is short by one node

**Recurred, a third time, identically.** `azdo-graph-assembly` says repository
nodes exist "because pipeline YAML references them through
`resources.repositories` or `checkout` — never because the project contains
them". Implemented exactly, that produces **three** repo nodes. The oracle has
**four**.

**Observed.** `repo:consumer-app` is in `expected-graph.json` with **in-degree
zero** — no edge in the oracle points at it. `cases.md` case 12 states the four
repo nodes "are there because pipeline YAML references them through
`resources.repositories` or `checkout`", and for `consumer-app` that sentence is
not true of the oracle it describes.

**Inferred.** The rule that produces exactly the oracle's four is *referenced by
`resources.repositories`/`checkout`, **or** hosts a pipeline definition*.
`consumer-app` hosts `x01-consumer-build` and `x02-platform-release`. That rule
still satisfies case 12's actual test, because the empty `ClaudeTesting`
repository neither hosts a definition nor is referenced.

**Not repaired here.** The oracle is right until a decision says otherwise, and
nothing under `evals/` was touched. This is recorded as a defect in the
fixture's *stated justification*, not in its contents: the graph is defensible,
the sentence explaining it is not.

### F-3 — the optional-field principle is contradicted by the schema it cites

**Recurred, a third time, on the same two fields and in opposite directions.**

`producer-contract` says an absent optional field means NOT STATED, and to ask
"do I have something to say here?". Applied honestly to `graph.schema.json`:

- **`repo` on a `pipeline` node** — omitted, reasoning that the schema's own
  comment says `path` is "Present on yaml nodes only" and the definition edge
  already states the repository. The oracle writes it. **15 differences.**
- **`alias` on `template`/`extends`/`checkout` edges** — written, reasoning that
  the alias genuinely appears in the YAML. The oracle omits it there and writes
  it only on `repositoryResource` and `pipelineResource`. **8 differences.**

**Inferred.** The distinguishing rule is *declared versus used*: on a resource
entry the alias is the fact being stated; on a template reference it is already
inside `ref` as the `@suffix`, so writing it restates. That rule is nowhere in
the skill or the schema, and it is not derivable from "is this a positive fact?"
— both readings are positive facts.

### F-4 — the `reason` format is stated nowhere

**Recurred, a third time.** `azdo-pipeline-yaml-refs` tabulates the two reasons
as the bare tokens `file-not-found` and `alias-not-declared`, so that is what was
emitted. The oracle wants `token: explanation`:

    file-not-found: resolved to pipelines/templates/missing-steps.yml in pipelines-main, which does not exist

**Observed.** 2 differences, both on the same file's two unresolved edges.

**Inferred.** The oracle's form is better — it says which alias, in which file,
and what follows — and nothing in the instrument asks for it. A producer has no
way to learn the shape except by being scored.

### F-5 — the runtime-dependency fork, and which way this run went

**Recurred. This run took 005's fork.** `powershell-module-build` says
`Requirements.psd1` is "the **only** place dependencies are pinned. Do not also
pin them in the manifest's `RequiredModules`", and then, two paragraphs later,
that a runtime dependency belongs in the manifest and a build dependency in
`Requirements.psd1`.

`powershell-yaml` is honestly both: the module parses YAML at run time, and the
build needs it present to build. Run 004 read the prose and declared it in the
manifest only. Runs 005 and 006 read the second paragraph and declared it in
**both files**.

**Observed.** 33/33 conformance either way, in all three runs. The instrument
cannot see this disagreement at all.

**Inferred.** Two of three blind sessions took the second fork. The split is not
random noise between runs so much as a genuine ambiguity that the reader
resolves late, after deciding whether their dependency is "really" a runtime one.

### F-6 — `/build` step 1 instructs a read the measurement forbids

**Recurred, a third time. Declined, not breached.** `commands/build.md` step 1
says to read `evals/conformance/Conformance.Tests.ps1` before writing code. The
Phase 1 allowlist forbids it. It was declined, the consequence was stated at the
time, and the module was built from the skills alone.

**Observed.** 33/33 at first shot, from a fresh clone. The skills are a faithful
proxy for assertions this session never read.

### F-7 — the `.GetNewClosure()` hazard

**Did not recur as that construct.** This run used a plain scriptblock —
`$addNode = { … }` invoked with `& $addNode …` — which captures the defining
scope without `.GetNewClosure()`, and mutates the `$nodes` hashtable through the
captured reference. It works for a different reason than 004's and 005's version
did, so this run is not evidence either way about the hazard.

### F-8 — the Pester 6 assertion list still cannot be written from memory

**Recurred.** The list *was* re-derived at the start with
`Get-Command -Module Pester -Name 'Should-*'`, exactly as
`powershell-module-test` instructs — and three invented names were written
anyway, after that:

- `Should-BeIn` — does not exist
- `Should-NotBeNullOrWhiteSpace` — does not exist (`Should-NotBeWhiteSpaceString` does)
- `Should-BeLike` — does not exist (`Should-BeLikeString` does; Pester's own
  `Should-Throw` help example uses the non-existent name)

**Inferred.** Deriving the list once is not enough; the failure is at the moment
of writing each assertion, not at the start of the file. Two of the three were
caught by running the suite, one by re-reading the derived list.

### F-9 — the culture-directory skip

**Did not recur.** This run shipped
`src/PSAzureDevOpsGraph/en-US/about_PSAzureDevOpsGraph.help.txt` and the build
copies culture directories, so *copies culture directories so Get-Help finds
about_ topics* graded a real case. `cases-run` is **57**, matching run 004; run
005's 56 remains the only one of the three that skipped it.

### F-10 — a back-edge report that cannot tell a cycle from a diamond

**Recurred as an introduced defect, and was caught inside Phase 1.** The first
implementation reported every arrival at an already-visited node as a back edge,
and duly announced seven "back edges" for a fixture containing **one** cycle —
`p07b → diamond-shared`, two independent template reuses and the real
`cycle-a ↔ cycle-b` all reported alike.

**Observed.** Replaced with a three-colour depth-first search over the assembled
edges, which reports exactly one cycle and reports nothing for a diamond. Both
behaviours are pinned by unit tests.

**Inferred.** The skill's traversal snippet is correct about *edges* — record
before the visited check — and silent about *reporting*. "Report the back edges
you found" reads as "report the revisits", and a revisit is usually a diamond.
Calling a diamond a cycle is the same defect as reporting no cycle, in the other
direction.

---

## New in run 006

### F-11 — `Run.Throw` without `Run.PassThru` returns nothing, and every gate reading the result dies silently

**Observed.** This is the mechanism under F-1, stated on its own because it is
not specific to coverage. With `Run.Throw = $true` and no `Run.PassThru`,
`Invoke-Pester` raises on failure and returns **nothing** on success. Every gate
written against `$result` therefore compares against `$null`:

| Gate | What it did |
|---|---|
| coverage | `0 -lt $null` → `$false` — never fired |
| PreTag | `($null + $null) -eq 0` → `$true` — always fired |

Both are invisible: the coverage gate prints a plausible line and passes, and
the PreTag gate is not in the default task so nobody runs it.

**Inferred.** Any module built from this skill has both defects unless its author
added `PassThru` for a different reason. The skill's `Test` task template should
carry the line.

### F-12 — a machine decision taken on a human-facing string, and the second iteration it cost

**Observed.** This is the only reason run 006 needed **two** iterations where
004 and 005 needed one.

Iteration 1 fixed all four first-shot mechanisms at once — and rewording
`reason` from `alias-not-declared` to `alias-not-declared: '…' is not in …`
broke an unrelated decision in the graph builder:

```powershell
if ($resolution.Reason -eq 'alias-not-declared') { "yaml:@$alias/$path" }
else                                             { "yaml:$repo/$path" }
```

The equality stopped matching, the `else` branch ran with two `$null`s, and the
unresolved edge acquired the target id **`yaml:/`**. One difference, where there
had been twenty-six.

**Inferred.** `Reason` was doing two jobs: a code for the program and a sentence
for a person. Improving the sentence broke the program, and nothing marked the
coupling. Fixed by adding `ReasonCode` and branching only on that. The general
shape — *a decision taken on text written for a human breaks the moment the text
improves* — is why the oracle's own `token: explanation` format is worth
imitating: the token survives the prose.

### F-13 — a single-element `List[T]` from an `if` expression unrolls, and indexing the scalar yields a `[char]`

**Observed.** Cycle detection silently found nothing — not the real cycle, not
even a self-loop. The cause:

```powershell
$children = if ($adjacency.ContainsKey($n)) { $adjacency[$n] } else { @() }
$child    = $children[$i]
```

When the `List[string]` holds exactly one item, PowerShell unrolls it to a bare
`string`. Indexing a `string` returns a **`[char]`**. `$state[[char]'b']` and
`$state['b']` are different keys, so every lookup missed, every node looked
unvisited, and the walk reported no cycles at all while terminating normally.

`$children.Count` was `1` throughout, which is what makes it hard to see: the
count is right, the element type is wrong.

**Inferred.** Fixed by declaring `[string[]] $children` and casting. Any
graph/tree walk that pulls adjacency out of a dictionary through an `if`
expression has this bug latent, and it presents as "the algorithm finds
nothing", never as an error.

### F-14 — `Write-Build` inside a function whose output is assigned is swallowed

**Observed.** The `Resolve` task printed its header and then nothing:

    Task /./Build/Resolve
    Runtime dependencies:
    Done /./Build/Resolve

`Resolve-BuildDependency` ended with `Write-Build Green "…: $found at $resolved"`
and then returned `$resolved`, and the caller wrote
`$null = Resolve-BuildDependency …`. In a non-interactive host `Write-Build`
falls back to the output stream, so `$null =` swallowed the message along with
the return value. The build stayed green and the resolved version silently
stopped being printed — which is precisely the fact
`powershell-module-build` says to print so it "sits next to the failure".

**Inferred.** The skill's own example has this shape: it both `Write-Build`s and
returns a value, and shows the caller discarding the result. Fixed by making the
function return a record and the caller print it.

### F-15 — the credential guard was masked by the transport error handler

**Observed.** With `$env:AZDO_PAT` unset, commands failed with

    Azure DevOps returned HTTP  for a /someorg/someproject/_apis/git/repositories request.

rather than the message naming the variable. `Get-AzDoAuthHeader` was called as
an argument *inside* the `try`, so its `throw` was caught by the transport
handler and rewritten into an HTTP status that did not exist.

**Inferred.** The one error that names the fix was replaced by one that names
nothing — the opposite of what `azdo-rest`'s "fail by naming the variable" is
for. A missing credential is not a transport failure and must be raised outside
the handler that interprets transport failures. Found by the module's own test,
which is what that test was written for.

### F-16 — two scoring-environment hazards, neither about the module

**Observed, and recorded so the next run does not spend time on them.**

- **`git clone` into the session scratchpad fails**: `cannot write keep file …
  Filename too long`. The scratchpad path is long enough that the pack `.keep`
  path exceeds the limit. `git -c core.longpaths=true clone` succeeds. Two of
  three clones failed and one succeeded, because the third directory name was
  one character shorter — which is how a path-length limit presents.
- **An exported artifact does not byte-compare across a git round-trip.** The
  committed `graph.json` checks out as LF; a fresh export on Windows writes
  CRLF. Raw comparison says "different"; parsed comparison and `Compare-Graph`
  both say identical. Compare parsed content, or normalise first.

### F-17 — an assertion about a document cannot tell whose id it is reading

**Observed.** The acceptance test for this run asserts

    $r | Should -Not -Match 'b0a48c69-…'
    $r | Should -Not -Match 'cc4d301c-…'

against the **whole** README, to establish that run 006's session identifier is
a third distinct one. The first draft of this record quoted both predecessors'
identifiers in one sentence — *"differs from run 004's … and run 005's …"* — in
order to show that it differs from them. The assertion went red.

**Inferred.** The check can see the document; it cannot see the run. A record
that proves its claim by quoting what it differs from is indistinguishable, to a
whole-document regex, from a record that *is* one of those runs. This is the same
shape as METHOD.md's *an assertion about a declaration is not an assertion about
the thing declared*, arrived at from the other side.

The assertion was **not** weakened — it is specified verbatim in the pass prompt
and is left exactly as given. The record was changed instead: it names the two
files the other identifiers live in rather than reproducing the strings, and says
why. The pairwise-distinctness claim is carried by spot-check 5, which reads all
three ids out of all three records and compares them, which is a check on the
runs rather than on this document's prose.
