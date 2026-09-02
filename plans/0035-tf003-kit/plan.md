# Pass 0035 — Instrument repair and the tf-003 kit

Tier: full. Harness only, branch `pass-0035-tf003-kit` from `main`
(`a1735b0`). No release: `skills/`, `commands/` and `.claude-plugin/` are
byte-identical to `v1.1.0` and `verify.ps1` asserts it.

## Preconditions, measured at start

| Claim | How |
|---|---|
| Trees clean, harness and all five siblings | `git status --porcelain`, empty everywhere |
| `main` at `a1735b0`, in sync with origin | `git status -sb` |
| `evals/tf/BRIEF.md` and `evals/tf/seed/` absent | `test -e`, both absent |
| `git diff v1.1.0..main -- skills/ commands/ .claude-plugin/` empty | run, empty |
| Fixture-1 comparator suite green **before** the repair | 15 passed, 0 failed |
| Both oracles duplicate-free before the repair | 78/78 and 99/99 unique ids |

The last two are the baseline the repair is measured against. A repair that
moved either number changed the instrument while claiming to fix it.

## Acceptance — red first

[`accept.Tests.ps1`](./accept.Tests.ps1), exactly as the prompt specified.
Run before any work: **7 of 7 failing**, recorded in
[`accept-red.txt`](./accept-red.txt). Green at start would have stopped the
pass.

## What was done

### 1. Backlog 32 — the comparator could not see a duplicate node id

`Compare-TfGraph.ps1` keyed both graphs into an ordered dictionary by id
before comparing anything. `$byId[$node.id] = $node` discards the earlier
entry, so a duplicated id deleted itself **on both sides** and even the
oracle-against-itself control stayed green over a document that had grown by
a node. Found in pass 0034 by a probe that did not fire.

**Stage 0** now asserts uniqueness on both graphs before the first assignment
into a hashtable. `DuplicateId` is its own category, naming every duplicated
id and which side carries it.

- **Its own category, not a nearby one.** Neither copy is the extra one. The
  id is ambiguous, so every comparison keyed on it is meaningless rather than
  wrong, and calling it an `ExtraNode` would name a defect that is not the
  defect.
- **The category over the count proxy.** Backlog 32 also offered
  `ActualNodeCount -eq ExpectedNodeCount`. Not taken: a graph with one node
  duplicated and one missing has the right total and two defects.
- **`IsMatch` states the check twice.** Equivalent to the difference count
  today; the redundancy is the point, so a later change that filtered the
  list fails loudly rather than quietly restoring the blindness.

Mutation 8 (`duplicate-id`) duplicates a node **byte-identically** — a copy
with a changed field would also read as a `WrongAttribute` on whichever copy
the dictionary kept, and a mutation detected by two mechanisms cannot say
which one you have.

It is **two-directional** and therefore not in the seven-mutation driver: a
duplicated id is the same defect whichever side carries it, and the direction
that driver cannot express is the one that made the control green.
[`Invoke-TfDuplicateIdFalsification.ps1`](../../evals/tf/Invoke-TfDuplicateIdFalsification.ps1)
runs both, with both clean oracles matching themselves **before and after** —
so a "repair" that made every document differ from itself would fail rather
than look like success.

Verdicts, [`mutation8.txt`](./mutation8.txt):

    DUPLICATE-ID: detected on producer side
    DUPLICATE-ID: detected on oracle side
    MUTATION 8: detected in BOTH directions, controls green before and after.

Nothing weakened, [`suites.txt`](./suites.txt):

    FIXTURE1: 15 passed, 0 failed
    FIXTURE2: 8 passed, 0 failed

Both counts are **pinned** in
[`Invoke-TfSuite.ps1`](../../evals/tf/Invoke-TfSuite.ps1): a suite that
gained or lost a test is itself reported as a failure. Fixture 1's
seven-mutation falsification is still 7 / 7, and so is fixture 2's.

### 2. Backlog 31 — pipeline definitions

Settled by **narrowing, not building**, as an amendment to decision 0014:
*pipeline definitions are outside the TF measurement surface.*

Checked rather than assumed: both oracles hold six node types — `local`,
`module`, `output`, `provider`, `repository`, `variable` — and **zero**
pipeline nodes, while both fixtures carry four pipeline YAML files as
content. Fixture 1's four AzDO definitions are an artifact of the order pass
0023 did things in, not part of what tf-001 or tf-002 scored. Creating four
more would have bought parity in a dimension no oracle reads, at the cost of
editing a frozen fixture.

The amendment closes the cheap path in advance: a capability that reads
definitions through the REST API gets its own fixture decision before it gets
a run. Mirrored into `docs/testing/README.md` beside the fixture-comparison
table.

### 3. The tf-003 kit

[`evals/tf/BRIEF.md`](../../evals/tf/BRIEF.md) and
[`evals/tf/seed/`](../../evals/tf/seed/README.md) — what a builder is handed.
The brief describes the job: parse Terraform configuration from cloned
repositories, emit against `PSGraphRenderToHtml/contract/producer-graph.schema.json`,
carry an unresolvable module source with a reason rather than dropping it,
render through the ToHtml exporter, read-only, token from `$env:AZDO_PAT`.
It names the input — `jlbalmerjr1` / `ClaudeTestingTerraform` /
`TfSiteCore`, `TfSiteEdge`, `TfSiteOps` — and no case, count, mechanism or
expected shape.

**That last claim is a gate, not an intention.** The fixture rule set could
not be the gate: a brief *has* to say graph, producer, contract and
unresolved, because that is the job being asked for. So
`Test-FixtureSanitization.ps1` gained `-RuleSet Kit` and `-Path`.

Kit drops the graph-vocabulary category and the `unresolv` pattern, and adds
a category the fixture set has no equivalent of — **counts, shapes and stated
expectations**. "Twelve cases" is the obvious leak; "three repositories",
"four levels deep" and "the expected graph" are the same leak in ordinary
clothes. Neither set contains the other, and the report says so, because a
reader who assumed Kit was Fixture-minus-some would conclude it is strictly
weaker when on counts it is strictly stronger.

**The gate found three leaks in the first draft of the brief and seed, and
the prose was fixed rather than the rules.**

Controls, [`kit-sanitization.txt`](./kit-sanitization.txt):

- weak — `-FailCheck` plants a banned line in a scratch copy, and it is
  caught;
- strong — the same kit rules over the **Azure DevOps kit**, written passes
  ago without these rules in mind, report **41 findings**. Clean against one
  real kit and 41 against another is discrimination; clean against everything
  would be a gate against nothing.

The fixture gate is unmoved: still clean on fixture 2, still **94 findings**
on fixture 1, `-FailCheck` still catches its planted line.

[`Reset-TfTarget.ps1`](../../evals/tf/Reset-TfTarget.ps1) materialises the
seed into a fresh `git init` and refuses anything outside `scratch/runs/`.
Falsified **both ways** — [`reset-falsification.txt`](./reset-falsification.txt)
— because a guard that refused everything would pass a refusal-only probe and
be useless:

- six destinations REFUSED, including reaching back out through an allowed
  prefix (`scratch/runs/../../PSTerraformGraph`), the deliverable repository
  by relative *and* absolute path, a directory whose name merely starts the
  same way, and a fixture source tree;
- one legitimate destination ACCEPTED, materialised, and its tree reported.

### 4. Pins

    tf-003 brief blob: dc25fcd0d1e4d5651073240374ee19c28499c70e
    tf-003 seed tree:  040ab2503aa7ccd5d67500d2e1d9983818807d86

The seed tree is derivable **two independent ways** — `git rev-parse
HEAD:evals/tf/seed`, and the tree of the commit `Reset-TfTarget.ps1` makes —
and they agree. Comparator and mutator blobs, and the unchanged `v1.1.0`
plugin pin, are recorded alongside in `LEDGER.md`.

## Two things this pass got wrong first, and how

Both were found by the work rather than by review, and both are in the
LEDGER as items 33 and 34.

- **`git commit --date=` pins only the AUTHOR date.** The committer date
  still comes from the wall clock, so the seed commit SHA moved between two
  resets a second apart while `Reset-TfTarget.ps1` claimed reproducibility —
  and its own check agreed with it, because the two resets it ran happened
  inside the same second. Fixed by setting both git stamps, and the check now
  **reads the stamps back** instead of comparing two SHAs made at the same
  instant. Proved by resetting twice with a real gap.
- **`evals/tf/seed/LICENSE` resolved to `text=auto` with no `eol`.** A fresh
  Windows clone would have checked it out CRLF, producing a different seed
  tree from the one being pinned. The root `.gitattributes` already carried
  this exact rule for `evals/functional/seed/`; what was missing was applying
  it to the new directory. Found with `git ls-files --eol`, before the pin
  was written.

## Constraints, honoured

- No fixture file and no AzDO object touched. `evals/tf/fixture/` and
  `evals/tf/fixture2/` are unchanged; nothing reached the network.
- No assertion weakened. Detection was added; both suites returned at their
  pinned counts, and the fixture-1 sanitization control is still 94.
- No case knowledge in `BRIEF.md` or `seed/`, enforced by a scanner with two
  controls rather than by intention.
- No release. `git diff v1.1.0..HEAD -- skills/ commands/ .claude-plugin/`
  is empty.

## Verification

[`verify.ps1`](./verify.ps1) re-derives every claim above from a **fresh
clone**, regenerating reports rather than grepping them for their own
headlines. `-FailCheck` breaks what each check depends on, in the clone only,
and requires the check to go red.

## Not done, and why

- **tf-003 itself is not run.** A pass that authored the brief cannot be the
  session that builds against it.
- **Backlog 29** — no fixture-2 counterpart to `Test-TfFixtureCase.ps1` —
  stays open. tf-003 needs one; it was not in this pass's scope and
  half-generalising it would leave a scoring script that is neither.
- **Backlog 16** stays open for the AzDO line. `Reset-Target.ps1` was left
  alone on purpose: runs 004–006 were produced by it.
