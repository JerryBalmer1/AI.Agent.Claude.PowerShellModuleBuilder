# Run tf-003 — the generalisation measurement

The first genuinely blind run in this project, and the one Line 1's
generalisation claim has been waiting for. The plugin, on, on a second domain,
against a fixture and an oracle nothing in the session had ever seen, scored by
a comparator that now refuses duplicate ids.

**One run. Its number stands whatever it is.**

```
plugin-sha:                    v1.1.0 (df63806)
brief-sha:                     dc25fcd0d1e4d5651073240374ee19c28499c70e
seed-tree:                     040ab2503aa7ccd5d67500d2e1d9983818807d86
oracle-tree:                   f470ed8561c69e3d04b4560f3e56f49d4a672f81  (identity only, never opened in phase 1)
model-version:                 claude-opus-5[1m]
entrypoint:                    claude-vscode
session-identifier:            692109bc-018c-4288-8b36-db3e3737cc01
phase-1-minutes:               31
target-sha (first shot):       d788f7c7ecb1aa471eea01de6878d253df4c4ae4
target-sha (final):            d76d16bb5083f422ccc05671e21cefde3c1a004e
build:                         exit 0
module tests:                  96 passed, 0 failed, line coverage 92.39% (target 70%)
battery:                       7 / 7
functional-tf (first-shot):    6 / 7
functional-tf (final):         7 / 7
differences (first-shot):      184
differences (final):           0
iterations allowed / used:     3 / 1
```

`plugin-sha` is the tag `v1.1.0`, whose commit is `df63806`.
`git diff v1.1.0..main -- skills/ commands/ .claude-plugin/` is **empty**: the
plugin surface is byte-identical to the tag. `brief-sha` and `seed-tree` are
`git ls-tree` derivations and both match the pins in
[the LEDGER](../../LEDGER.md). The Claude Code version is not recorded because
it is still not observable from inside the session — `$env:CLAUDE_CODE_VERSION`
is empty — so the entrypoint is recorded instead of a guess, as tf-002 did.

## What was scored against what

| | |
| --- | --- |
| Fixture | the live repositories in AzDO project `ClaudeTestingTerraform`, cloned read-only |
| Oracle | `evals/tf/fixture2/expected-graph.json` — 99 nodes, 88 edges, hand-authored, **not read until the gate lifted** |
| Comparator | `evals/tf/Compare-TfGraph.ps1`, with the Stage 0 duplicate-id detection added at pass 0035 |
| Cases | the seven in `evals/tf/fixture2/cases.md`, scored by [`Test-Tf003Case.ps1`](../../plans/0036-tf-003/Test-Tf003Case.ps1) |

Fixture clones, at the SHAs [decision 0014](../../decisions/0014-second-unannotated-fixture.md) records:

| Repository | Commit |
| --- | --- |
| `TfSiteCore` | `a228e78c247d2d4367303f303c4363d9906e06f2` |
| `TfSiteEdge` | `1ae66c2712f799a69304cb4364e91e4d10d694c4` |
| `TfSiteOps` | `fe27a34f7585b86b6fdbf12b609e17d4cb0f4b83` |

## What was built

`PSTerraformGraph` v0.1.0, from the four-file seed and `evals/tf/BRIEF.md`, in
an orphan branch that shares no history with the repository's `main`.
**The existing PSTerraformGraph implementation was never read, in either
phase** — this measures what the plugin and the model build fresh, not what
tf-001 already learned.

Six exported commands: `Get-TfRepository`, `Get-TfModule`,
`Get-TfConfiguration`, `Resolve-TfModuleSource`, `Get-TfGraph`,
`Export-TfGraph`. Parsing and resolution are separate commands because their
inputs differ. No `terraform` binary was installed or invoked; no plan, no
state, no cloud credential.

## Iterations

One, of the three the ladder's budget allows.

| # | Differences | Nodes | Edges | functional-tf | What changed |
| --- | --- | --- | --- | --- | --- |
| first shot | **184** | 99 / 99 | 88 / 88 | 6 / 7 | — |
| 1 | **0** | 99 / 99 | 88 / 88 | **7 / 7** | four naming conventions: module label is the directory leaf and the root module is `root`; a declaration is labelled by its bare name; a variable's Terraform type is `varType`; an unresolved target's id is `<Repo>:<source as written>`, contained by its caller; `resolved` is stated on every `sources` edge, true and false alike |

**The node and edge counts were right at first shot and never moved.** Every
node the oracle names was present, every edge was present, every `parentId` and
every `kind` agreed. All 184 first-shot differences were four naming
conventions — see [`findings.md`](findings.md) F-1 and F-2, including why one
renamed field scores 70.

## functional-tf: 6 / 7 first shot, 7 / 7 final

| Case | first shot | final |
| --- | --- | --- |
| 1 nested-module chain, four levels | PASS | PASS |
| 2 cross-repository source, `git::` with `//subdirectory` | PASS | PASS |
| 3 cross-repository output reference | PASS | PASS |
| 4 provider version pin | PASS | PASS |
| 5 value chain, renamed on the last hop | PASS | PASS |
| 6 unused variable, the absence case | PASS | PASS |
| 7 unresolved module sources, two shapes | **FAIL** | PASS |

Case 7 failed at first shot on the **id convention alone**: both unresolvable
targets were emitted, both flagged `resolved: false`, both carrying a reason,
and neither invented a `passes-to` edge — the mechanism was read correctly and
the node was filed under `<Repo>:unresolved:<source>` rather than
`<Repo>:<source>`. Scored strictly on the oracle's ids, as fixture 1's scorer
scores fixture 1's, that is a fail. It is worth saying plainly that a reading of
"case 7 is about carrying unresolvable sources" would score it 7 / 7 at first
shot; the strict reading is the one used, because an id is what makes two
producers' graphs mergeable.

The scorer was **falsified case by case**: seven mutations of the final graph,
each turning exactly its own case red and no other. And the **oracle scored
against itself came back 7 / 7** — after a correction the control itself
forced. See F-9.

## Artifacts

| File | What |
| --- | --- |
| `graph.json` | the final graph, byte-identical to the one produced by the scored clone: 99 nodes, 88 edges |
| `diff.txt` | `No differences.` |
| `cases.txt` | the seven-case report for the final graph |
| `tf-003.html` | 662,144 bytes, rendered through `PSGraphRenderToHtml`, no external resource |
| `findings.md` | ten findings, by mechanism |

## Wall-clock and parallelism

**Phase 1: 31 minutes** — reading the brief, the contract and all nineteen
skill files, cloning and reading three repositories, writing six commands and
ten private files, writing the fixtures and 96 tests, and getting the build
green. **Phase 2: about 55 minutes** — scoring, one iteration, the case scorer
and its falsification, and these records.

Degree of parallelism: **1 throughout.** Nothing was delegated to a subagent
and no scoring job was run concurrently. The parser, the assembler, the single
iteration and the scoring are inherently serial, each depending on the previous
answer; the reading at the start could have been parallel and was not.

## Deviations

1. **The prompt's BRIEF-blob pin arrived unsubstituted** — literally
   `<BRIEF-BLOB-FROM-0035>`. The blob was derived by `git ls-tree`
   (`dc25fcd0…`) and checked against the LEDGER **after** the gate lifted,
   since `LEDGER.md` is forbidden reading in phase 1. It matches. The seed tree
   was handled the same way and also matches.
2. **A stray `src/` directory was created at the harness root** by one
   mis-pathed write, and removed in the next command. Nothing was read from it
   and nothing was committed; the harness tree was clean before and after.
3. **The fixture-2 case scorer had to be written by this pass** and lives under
   `plans/0036-tf-003/` rather than `evals/`, because pass 0036 may not touch
   `evals/`. See F-8; promoting it is queued.
4. **`coverage.xml` was committed in the first-shot commit** — Pester writes it
   at the repository root and the seed's `.gitignore` does not name it. Added to
   `.gitignore` and removed from the index in iteration 1. It is a build
   artifact and affected no score.
5. **The scoring clones were made under `C:\Users\jlbal\AppData\Local\Temp\p0036`**,
   not under the session scratchpad, for the reason pass 0033 recorded: the
   scratchpad path is long enough that `git clone` fails writing a keep file.

Breaches of the phase-1 allowlist: **zero**. `evals/tf/fixture/`,
`evals/tf/fixture2/`, `Compare-TfGraph`, `Mutate-TfGraph`, `runs/`, `plans/`
other than this pass's own, `journal/`, `decisions/`, `method/`, `docs/`,
`LEDGER.md` and `README.md` were first opened **after** the built module was
pushed. The PSTerraformGraph repository was never read at all.

---

## Generalisation comparison

### tf-003 against tf-001 — and why the raw counts do not compare

| | tf-001 | tf-003 |
| --- | --- | --- |
| fixture | fixture 1, **annotated** | fixture 2, **written mute** (decision 0014) |
| oracle | 78 nodes, 57 edges, **visible throughout** | 99 nodes, 88 edges, **unread until the gate** |
| plugin | v1.0.x, **no `tf-*` skills** | v1.1.0, **three `tf-*` skills** |
| first-shot differences | 94 | 184 |
| final differences | 31 | **0** |
| functional-tf, first shot | not scored separately | **6 / 7** |
| functional-tf, final | 6 / 7 | **7 / 7** |
| iterations used | 3 of 3 | **1 of 3** |
| Phase 1 wall clock | ~55 min (whole run) | 31 min |

**The counts are not comparable and nobody should try.** Different fixtures,
different sizes, and a comparator that has since gained a category. 184 > 94
says nothing at all: tf-001's 94 were 12 node differences and 48 missing edges —
*structure* — while tf-003's 184 were four names. Compare the mechanisms.

**tf-001's first shot, by mechanism.** Local module sources matched the registry
pattern, so every nested module resolved to an invented registry node; and
`required_providers` was read only as an attribute, so no provider was found at
all. Twelve node differences and forty-eight missing edges. Iteration 3 then
found that the parser rejoined expression tokens with spaces, so every reference
pattern missed. Three defects, each producing a wave, and the run closed on 31
differences with a real producer bug still in it (`module.subnet[*].id`).

**tf-003's first shot, by mechanism.** Nested modules resolved. Both
`required_providers` spellings read. Expressions kept their raw text.
`module.pop[*].id` resolved. `count` produced no value-flow edge. A `git::` URL
with no `//` resolved to the repository root. A module called by two siblings
took its parent from the directory tree. **Every one of tf-001's four
mechanisms is a paragraph in a `tf-*` skill, and not one of them recurred.**

That is the finding, and it is not a small one — but it is also not the
generalisation claim, because of the bound below.

### Which skills demonstrably shaped Phase 1

Demonstrable means there is a line of code or a test that exists because the
skill said so, and would plausibly not exist otherwise.

| Skill | Evidence |
| --- | --- |
| `tf-hcl-parse` | the whole state-tracking walk (`Get-TfCodeMask`); both `required_providers` spellings; raw expression text; `(?:\[[^\]]*\])?` in the module pattern; meta-arguments excluded; constraints stored verbatim. Four of tf-001's mechanisms, none recurring |
| `tf-module-resolve` | the leading-dot guard; `IndexOf('//', schemeEnd + 3)`; **no `//` means the repository root**; `?ref=` stripped; unresolvable emitted as a node with a reason; no edges from an unresolved call. Cases 2, 3 and 7 |
| `tf-graph-assembly` | repository-carrying ids; **parent is the directory tree, not the caller** — `modules/common`, called by two siblings, is the case; no stored depth; three edge kinds; dedup on `(from,to,kind)`; ordinal sort; self-validation before emit. Cases 1, 5, 6 |
| `producer-contract` | `hasDefault` written both ways and `hasValidation` only when true — **zero differences** (F-4); the consumer's battery run from the consumer's repository as a build task; the contract version declared; and the *group differences by mechanism* diagnostic, which is how 184 became four |
| `powershell-module-scaffold` | the layout; the committed dev loader — and its argument was confirmed the hard way when `PSGraphRender`'s own `src/` manifest **failed to import** for exactly the stated reason; the absolute-`-Path` rule, with a test |
| `powershell-module-build` | two build files; `ParseError` in the severity list; `Clean, Lint, Build, Test` with `PreTag` out of the default; `Run.Throw` not `Run.Exit`; the coverage `throw`; the parameterised dependency resolver. Also the source of F-5 and F-6 |
| `powershell-module-test` | *re-derive the `Should-*` list rather than remembering it* — done, and it mattered: `Should-Contain` does not exist. Fixtures as paths with their imperfections documented; PreTag written in the same pass as its task |
| `powershell-module-architect` | six commands, parse split from resolve; the `Tf` prefix; no writing verb; `[AllowEmptyCollection()]` on `-Module` |
| `azdo-rest` | `$env:AZDO_PAT` only, never a parameter or a URL; the **omitted-property** guard, tested with a repository object that has no `defaultBranch` at all; the 203 sign-in page; the header continuation token |
| `powershell-module-docs` | comment-based help with `.SYNOPSIS` on every exported command, asserted |

### Which were silent

- **`azdo-graph-assembly`** — the same arguments as `tf-graph-assembly`, which
  cites it. Read; nothing came from it that its twin had not already said.
- **`azdo-pipeline-yaml-refs`** — fixture 2 contains four pipeline YAML files
  and the oracle models none of them. Not applicable to a Terraform producer.
- **`powershell-module-analyzer`** — nothing was analysed; no unknown external
  dependency appeared.
- **`powershell-module-plan`** — its six intake questions were all answered by
  `BRIEF.md`, so the template was never filled.
- **`powershell-module-deploy`**, **`powershell-module-release`** — nothing was
  published, versioned or tagged. Their standing rules were honoured by not
  acting.
- **`task-tree-reporting`** — a format for the response, not for the build.
- **`commands/build.md` and `commands/test.md` — silent, and this one is a
  finding.** `/build` step 1 says to read
  `evals/conformance/Conformance.Tests.ps1` and `evals/functional/BRIEF.md`;
  `/test` runs `evals/conformance/Invoke-Conformance.ps1` and reports a
  conformance score. **Neither exists for a `tf` run** — the brief is
  `evals/tf/BRIEF.md` and there is no conformance suite in this measurement at
  all. The two commands are written for the AzDO ladder's shape. The skills they
  delegate to generalised to a second domain; the commands did not.

### Does the ladder's shape-not-correctness claim hold on a second domain?

**It is not tested here, and the reason is worth stating precisely rather than
hedging.**

The ladder's claim — *the plugin buys shape, not correctness* — is a claim about
a **difference between plugin-on and plugin-off**, and it was measured by
running both. tf-003 is a single plugin-on run with no control. Nothing in it
can support or refute a comparative claim.

What tf-003 does show is **consistent with the claim's second half and awkward
for its first**:

- **Shape came free, again.** Build exit 0, lint clean, 96 tests, coverage
  92.39%, `PreTag` populated, the dev loader present — all at first shot, none
  derivable from the brief. That is the ladder's 19 → 33 effect, unmeasured here
  for want of a control but visibly present.
- **Correctness also came at first shot, and that is the awkward part.** The
  ladder's plugin-on runs scored **1 / 12** functional at first shot. tf-003
  scored **6 / 7**, with node and edge counts exact. On the ladder the plugin
  did not buy correctness; here, correctness arrived first time.

The honest reading is that the two are **not measuring the same thing**, and
the difference is the bound below: the ladder's plugin contained no skill
written from a previous run of its own fixture, and v1.1.0's `tf-*` skills are
exactly that. A first shot that clears every mechanism a previous run recorded
is not evidence that the plugin generalises. It is evidence that a plugin
carrying a domain's findings prevents that domain's findings from recurring —
which is worth having and is a weaker claim.

### Blindness bounds that still apply

1. **The `tf-*` skills carry fixture 1's answers, by mechanism and by count.**
   This is the binding one. `tf-hcl-parse` names the four constructs that defeat
   a regex, states that `required_providers` has two spellings, and gives the
   splat-tolerant reference pattern — citing *"63 of that run's 94 differences"*
   and *"the 31st of that run's 31 remaining differences"*.
   `tf-module-resolve` gives the leading-dot guard and the no-`//`-means-root
   rule with tf-001's and tf-002's costs attached. `producer-contract` states
   the `hasValidation` asymmetry with *"28 differences"* beside it — and F-4
   records that it cost nothing here.
   **The fixture was unseen; the mechanism catalogue was not.** This is exactly
   what tf-002 predicted when it recorded that the `tf-*` skills were
   deliberately not written, *"because writing them first would measure the
   plugin's memory of tf-001 rather than its generality"*. They were written
   between then and now. This run measures the plugin **with** that memory, and
   the README's current wording does not say so.
2. **One run, one model, no control.** No plugin-off arm, no second session, no
   variance estimate. Nothing here separates the plugin from the model.
3. **The two fixtures are siblings.** Fixture 2 was authored by this project to
   exercise *"the same seven mechanism classes"* as fixture 1. Generalising
   across two fixtures built to the same case taxonomy is a narrower claim than
   generalising to Terraform.
4. **The domain was not new to the model, only to the session.** Terraform HCL
   is public and heavily represented in training data. The blind thing here is
   the fixture and the oracle, not the language.
5. **Only the last hop was blind.** The oracle was unread until the gate, but
   one iteration was then run against it. The first-shot line is the blind
   measurement; the final line is not, and the two are reported separately for
   that reason.
6. **Case 7's first-shot FAIL is a scoring judgement**, stated above, and it is
   the difference between reporting 6 / 7 and 7 / 7 blind.

### The sentence the README's generalisation section needs

Drafted, and it is a smaller claim than the section it replaces:

> **tf-003** is the first blind run: v1.1.0, on a second domain, against
> [fixture 2](evals/tf/fixture2/) and an oracle the session did not read until
> its module was built and pushed. It came back **6 / 7 functional-tf at first
> shot with node and edge counts exact — 99 / 99 and 88 / 88 — and 7 / 7 after
> one of its three permitted iterations**, the 184 first-shot differences being
> four naming conventions and no structural error. Every mechanism tf-001 lost
> a wave of edges to was read correctly first time. **That is not yet a
> generalisation result, and the reason is in the plugin:** v1.1.0's three
> `tf-*` skills were written from tf-001 and tf-002 and cite their findings by
> count, so the fixture was unseen but the mechanism catalogue was not — the
> thing [tf-002 warned about](runs/tf-002-convention-and-case3/) when it left
> those skills unwritten. What tf-003 establishes is that **a plugin carrying a
> domain's recorded findings stops those findings recurring on a fresh fixture
> in that domain**, which is worth having and is not the same claim. The
> generalisation claim needs a third domain the `tf-*` skills say nothing
> about, or a plugin-off control on this one.
