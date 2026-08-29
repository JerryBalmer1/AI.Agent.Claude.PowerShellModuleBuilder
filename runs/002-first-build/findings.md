# Run 002 — findings

Sorted by **mechanism**, not by which score line they touched. Each says what
was observed versus what is inferred, which check caught it or `uncaught`, and a
candidate remedy under rule 9 (script, skill, subagent, or hook).

Twelve findings. Six are about the module, three about the plugin's own skills,
three about the harness and the specification.

---

## Mechanism A — the specification under-determines the answer

### F-1. `cases.md` specifies the graph's *structure* but not its *field conventions*

**Observed.** Iteration 1 produced 49 nodes and 51 edges — the oracle's exact
counts — with every edge pairing by `from`/`to`/`kind`, and still scored 1/12.
All 60 differences were attribute conventions that `cases.md` never states:

| Convention | `cases.md` says | The oracle does |
|---|---|---|
| `pipeline` node `repo` | nothing | carries the defining repository |
| `refKind` | nothing | present on `unresolved` edges **only** |
| `repositoryResource` `ref` | nothing | the `name:` value, `ClaudeTesting/templates-shared` |
| `checkout` `alias` | `ref: sharedTemplates` | `ref` only, no `alias` field |
| `unresolved` `reason` | `reason: file-not-found` | `file-not-found: resolved to … which does not exist` |

The `reason` row is the sharpest: `cases.md` documents the *code*, the oracle
stores a *sentence*, and `Compare-Graph.ps1` compares the field exactly. Nothing
readable under the Phase-1 rules could have produced that sentence.

**Observed vs inferred.** The five rows are observed — read from
`expected-graph.json` after iteration 1 scored 1/12. That a blind run could not
have derived them is **inferred**, but strongly: four of the five conventions
appear in no prose anywhere in `evals/`.

**Caught by.** `Compare-Graph.ps1`, iteration 1. Also **uncaught** in the sense
that matters — nothing warned before the run that the spec was insufficient.

**Coin-flip forced.** Node `name` for `yaml` nodes: repository-relative path, or
basename? Guessed path-relative and was right by luck. Had it been wrong, all 30
yaml nodes would have been a sixth convention row.

**Remedy — script.** Extend `Compare-Graph.ps1` with a `-ExplainConventions`
mode that emits a field-by-field contract derived from the oracle (which fields
appear on which edge kinds, with one example each). That is a fact about the
oracle and can be generated, so it cannot rot the way prose does. **Secondarily,
skill:** `graph-assembly` should carry the convention table above — it now
does not.

### F-2. The brief's command surface omits the two commands the graph needs

**Observed.** `BRIEF.md` lists seven commands. Building the graph needed two
private helpers with no home in that table: a path normaliser (`..` and `.`
collapsing, needed by `../steps/deploy.yml` in `templates-platform` and
`../steps/common.yml` in `templates-shared`) and a cycle detector. Both ended
up in `Private/`, which is right — but the brief's line "the final surface is
whatever the twelve cases require" invites putting them in `Public/`, where they
would have broken the three-way agreement assertion.

**Observed vs inferred.** Observed that both were needed. Inferred that another
builder might expose them.

**Caught by.** `uncaught` — known only from having built the thing.

**Remedy — skill.** `module-scaffold` should state the rule explicitly: a
helper that is not an answer to a user's question goes in `Private/`, because
`Public/` is the graded export surface.

---

## Mechanism B — a gate that cannot fail the way you think

### F-3. `Severity = @('Error','Warning')` in the analyzer settings silently drops `ParseError`

**The most serious finding in this run.** The `Lint` task reported **clean** on a
source file that could not be parsed at all. The build only failed later, in
`Test`, when the generated psm1 refused to import with nine cascading parse
errors.

**Observed.** With `Severity = @('ParseError','Error','Warning')` the same file
is reported. With `@('Error','Warning')` it is not. Both states were run.

**Cause.** `Invoke-ScriptAnalyzer -Settings` filters diagnostics by severity, and
`ParseError` is its own severity outside `Error`. A settings file that lists
severities explicitly — which is the idiom every example shows — turns the lint
gate off for the one class of defect that makes a module unloadable.

**Caught by.** The `Test` task, one stage too late, and only because the tests
import the built module. A repository whose tests did not import the module
would have shipped a green build over an unparseable file.

**This is the harness's own falsification lesson recurring.** The conformance
README says an assertion that has only ever been green is indistinguishable from
one that cannot go red. This gate had only ever been green.

**Remedy — skill, and it is already applied.** `build-script` must ship
`Severity = @('ParseError','Error','Warning')` as the required form, with this
finding as the reason. **Additionally hook:** a pre-commit hook running
`[Parser]::ParseFile` over changed `.ps1` files would catch it at the point of
edit rather than at build time.

### F-4. `Run.Throw = $true` makes a red Pester run fail the build, which is right — and makes coverage unmeasurable when tests fail

**Observed.** When two tests failed at iteration 2, `Run.Throw` aborted the
`Test` task before the coverage gate ran, so the run reported no coverage number
at all. The build correctly exited 1; the coverage figure for that build does
not exist.

**Observed vs inferred.** Observed. Inferred that this matters — for a red build
nobody wants a coverage number anyway. Recorded because a reader comparing the
iteration table will notice coverage is absent for failed builds and should know
it is structural, not an omission.

**Caught by.** The build, iteration 2.

**Remedy — none.** Working as designed. Documented in `build-script` instead.

---

## Mechanism C — the traversal was right, the reporting was not

### F-5. "Already visited" was reported as a cycle, so every diamond was a cycle

**Observed.** Iteration 1's graph command reported **7 back edges** including
`p07b.yml -> diamond-shared.yml` (a diamond), `nightly.yml -> common.yml`, and
`chain-b.yml -> chain-c.yml`. Exactly **one** of the seven was a real cycle.
After replacing the test with depth-first colouring, it reports one:
`cycle-b.yml -> cycle-a.yml`, which is what Pass 0011's verify independently
asserts the back edge to be.

**Cause.** A breadth-first walk's visited set answers "have I seen this node",
which is not "is this node on the current path". The first is true for every
shared template; only the second is a cycle.

**Note the graph itself was never wrong.** Both cycle edges were always present
and the walk always terminated — case-08 passed in both iterations. Only the
`BackEdge` report was wrong, and it is not part of the exported JSON, so no
score moved. It would have been wrong in front of a user.

**Caught by.** `uncaught` by any assertion — noticed by reading the command's own
verbose output. No case tests the cycle *report*, only the cycle *edges*.

**Remedy — skill.** `graph-assembly` now carries the three-colour algorithm and
states why BFS visited-sets cannot report cycles. **Secondarily script:** a
thirteenth case asserting the reported cycle set equals `{cycle-b -> cycle-a}`
would turn this from a reading-comprehension catch into a graded one.

### F-6. `[Parameter(Mandatory)]` rejects an empty collection, killing the accumulator pattern

**Observed.** `Find-AzDoYamlReference` passes a `List[object]` accumulator to its
recursive helper. On the first call the list is empty, and
`Cannot bind argument to parameter 'Found' because it is an empty collection`
aborted every parse. Fixed with `[AllowEmptyCollection()]`.

**Second-order observation.** In Pester the same failure surfaced inside the
graph tests as
`A 'break' or 'continue' statement with a label that does not match any
enclosing loop escaped from your code` — an error message with no relationship
to the cause. Chasing that message rather than the binding failure would have
cost far more than the fix did.

**Caught by.** The module's own tests, immediately.

**Remedy — skill.** `module-scaffold` should note that `Mandatory` implies
non-empty for collections, and that an accumulator parameter needs
`[AllowEmptyCollection()]`.

### F-7. `-f` inside a hashtable literal needs parentheses

**Observed.** `reason = '{0}: {1}' -f $a, $b` inside `@{ }` parses the comma as a
hashtable separator: `Unexpected token ',' in expression or statement`.
`reason = ('{0}: {1}' -f $a, $b)` is correct.

**Caught by.** The module import, via F-3's route — one stage later than it
should have been.

**Remedy — skill.** One line in `build-script` or `module-scaffold`. Low value
individually; recorded because it is the defect F-3 let through, and the pair is
the actual story.

---

## Mechanism D — the harness assumes a directory name it does not get

### F-8. Conformance discovery cannot find the module in a run directory

**Observed.** `Invoke-Conformance.ps1 -Path ./scratch/runs/002-first-build`
without `-ModuleName` finds **no manifest** and fails essentially every
assertion. Discovery prefers a manifest whose base name matches the target
directory (`002-first-build`), then one sitting directly in the target root
(there is none — it is at `src/PSAzureDevOpsGraph/`). Neither rule can fire, and
there is deliberately no "lone candidate wins" fallback.

**This is not a defect in either component.** The no-fallback rule exists
because a lone surviving candidate silently misgraded a vendored module once
before. The run directory is named by run id because runs must not collide. The
two are individually right and jointly broken.

**Compounding.** `evals/conformance/README.md` documents the invocation as
`-Path ./scratch/runs/<id>/PSAzureDevOpsGraph` — a path with the module name as
a subdirectory. `Reset-Target.ps1` does not create that layout; it materialises
the seed **at** the destination. The documented command cannot work against a
directory `Reset-Target` produced.

**Caught by.** The first conformance invocation of this run, which failed
loudly — the good outcome the no-guess rule was built for.

**Remedy — script.** Either `Reset-Target.ps1` should create
`<destination>/<ModuleName>/`, or `Invoke-Conformance.ps1` should accept the
module name from a run manifest. The README's example should be corrected either
way. Until then `-ModuleName` is mandatory for every run and `commands/test.md`
says so.

### F-9. `pwsh -File` flattens an array argument into one string

**Observed.** `pwsh -NoProfile -File Invoke-Conformance.ps1 -Tag A,B,C,D` fails
`ValidateSet` with the message
`The argument "Universal,Repository,HouseStyle,RequiresBuild" does not belong to
the set "Universal,Repository,HouseStyle,RequiresBuild"` — a message that names
the value and the set as identical strings. `-File` passes every argument as a
string. Calling the script directly with `-Tag @('Universal',…)` works.

**Caught by.** The runner's own `ValidateSet`, loudly, with a confusing message.

**Remedy — script.** `Invoke-Conformance.ps1` could split a comma-containing
single-element `-Tag`. **Or hook/doc:** the invocation in `commands/test.md`
now shows the array form.

---

## Mechanism E — the module works but its evidence is thin

### F-10. Paging is written but never exercised

**Observed.** `Invoke-AzDoRestMethod` implements `x-ms-continuationtoken`
following, and `Invoke-WebRequest` is used instead of `Invoke-RestMethod`
specifically to reach the response headers. The fixture returns 15 definitions
and 5 repositories — **no response in this run ever carried a continuation
token**, so the loop's second iteration has never executed.

**Observed vs inferred.** Observed that it never paged. That the paging code is
*correct* is **inferred from reading it**, and is exactly the kind of claim this
project exists to distrust.

**Caught by.** `uncaught`. No assertion covers it; the mocked tests mock at the
`Get-AzDo*` layer, above the paging.

**Remedy — script.** A unit test mocking `Invoke-WebRequest` to return a
continuation token on the first call and none on the second. Cheap, and it turns
an inferred claim into an observed one.

### F-11. `parameters:` subtrees are skipped wholesale, which is broader than the case requires

**Observed.** The walker does not descend into any `parameters` key. Case-03 only
requires that `buildTemplate:` produce no edge, which exact-key matching on
`template` already guarantees. The extra skip means a genuine
`parameters: { template: ... }` — legal YAML, rare in practice — would be
missed silently.

**Observed vs inferred.** Observed that the skip is wider than the case.
Inferred that it could matter in a real repository; no fixture file exercises it.

**Caught by.** `uncaught` — a deliberate choice at write time, recorded rather
than discovered.

**Remedy — none now.** Recorded so the next reader knows it was a decision, not
an oversight. If a real project hits it, exact-key matching alone is the
narrower fix.

### F-12. `powershell-yaml` is an undeclared runtime dependency of the module

**Observed.** `Requirements.psd1` pins it as a **build** dependency, and the
module imports it lazily at first parse with a clear error if absent. But the
manifest declares no `RequiredModules`, so `Import-Module PSAzureDevOpsGraph`
succeeds on a machine without it and fails only when a document is parsed.

**Why it is not simply fixed.** Adding `RequiredModules` to the manifest risks
the house-style assertion "pins build dependencies only in `Requirements.psd1`".
That assertion reads only `Requirements.psd1` today, so adding it would in fact
pass — but the rule's *intent* is one source of truth, and a runtime dependency
is genuinely a different thing from a build dependency. The distinction is not
drawn anywhere in the conformance suite or the brief.

**Caught by.** `uncaught` by any assertion; noticed while writing `DEMO.md`,
which has to tell a stranger to install it.

**Remedy — skill.** `module-scaffold` should say where a *runtime* dependency is
declared, as distinct from a build one. That gap is real and this run had to
guess: the guess was to document it in the README and `DEMO.md` rather than
declare it in the manifest.

---

## What the plugin got right

Recorded because a findings list that only lists faults misrepresents the run.

- **Node identity keyed by id, seeded from the definition list.** `graph-assembly`
  states both, and case-07 (diamond, in-degree 2) and case-10 (orphan) passed in
  iteration 1 with no rework.
- **Repository nodes never from the repositories endpoint.** Case-12 — the
  absence case, and the one a naive implementation fails hardest — passed in both
  iterations. The skill's phrasing ("use the endpoint to look files up; do not
  use it to emit nodes") is what made this a non-decision.
- **Record the edge, then decline to descend.** Case-08 passed in iteration 1;
  the traversal terminated in 13.4 s on the first attempt, and the known first
  failure mode (a hang) never occurred.
- **PAT never a parameter.** `azdo-rest` is unambiguous, and the module carries
  its own test enumerating the exported surface for `Pat`/`Token` parameters and
  writing verbs.
