# Run tf-003 — findings, by mechanism

Grouped by mechanism before any count is read. 184 first-shot differences are
**four conventions**, not 184 defects, and the number that matters is the one at
the bottom: *zero of them were structural*.

---

## F-1. Every first-shot difference was a naming convention. Zero were structural.

**Mechanism.** The comparator reported 184 differences at first shot. Node count
99 / 99, edge count 88 / 88, duplicate ids 0 / 0. Every node the oracle names
was present, every edge the oracle names was present, every `parentId` agreed,
and every edge `kind` agreed. The differences were entirely in what things are
*called*.

| Mechanism | Differences | What differed |
|---|---|---|
| M1 node `label` | 94 | oracle labels a module by its directory **leaf** (`pop`, `common`), the root module `root`, and a declaration by its **bare name** (`slug`). The producer wrote the full relative directory and the qualified form (`var.slug`). |
| M2 `attributes.varType` | 70 | oracle names a variable's Terraform type `varType`; the producer wrote `type`. Scored as 35 missing + 35 extra — **one decision, counted twice by construction.** |
| M3 edge `resolved` | 12 | oracle states `resolved: true` on every resolved `sources` edge; the producer omitted it. |
| M4 unresolved node id | 8 | oracle id is `<Repo>:<source as written>`; the producer wrote `<Repo>:unresolved:<source>`. Scored as 2 MissingNode + 2 ExtraNode + 2 MissingEdge + 2 ExtraEdge. |

94 + 70 + 12 + 8 = 184, exactly. **All four were fixed in one iteration.**

**Why this is the finding and not the footnote.** The producer read a
configuration it had never seen — four levels of nesting, two cross-repository
`git::` shapes, a diamond, a rename, an unused variable and two unresolvable
sources — and got the *entire* structure right first time. What it got wrong was
vocabulary, which is the half a brief cannot supply and a contract does not
fix.

---

## F-2. M2 and M4 show why a difference count needs its denominator explained

`varType` is **one** decision and it scored **70**: the comparator walks the
union of attribute names on both sides, so a renamed field is reported once as
"expected `varType`, got ''" and once as "expected '', got `type`". The
unresolved-id convention is **one** decision and it scored **8** for the same
reason across four categories.

Reported honestly, the first shot is **four decisions**. Reported as a count, it
is 184. Both are true; only one is actionable. This is the diagnostic in
`producer-contract` — *many identical differences are one convention* — arriving
with a multiplier nobody had costed: **the count is not merely inflated, it is
inflated by a factor that depends on the comparator's internals.**

---

## F-3. The contract's own sentence pointed the wrong way on `resolved`

The producer contract says of the edge flag:

> Absent means NOT STATED rather than true, the same rule the render contract
> uses for its optional fields.

Read before emitting — as `producer-contract` instructs — that sentence argues
for writing `resolved` **only** where it is false. The producer did exactly
that, wrote it down in its HANDOFF, and was wrong: the oracle states `true` on
all twelve resolved `sources` edges.

**Both readings are defensible and the contract does not separate them.** The
distinction that does is not *optional versus required*, it is *is there a fact
here*: resolution is something the producer **did** — it went looking for the
node the `source` names and either found it or did not — so both outcomes are
positive facts about that call. `references` and `passes-to` are not
resolutions, and the oracle states nothing on them either. The rule that
reproduces the oracle exactly is **"state it on every `sources` edge and on no
other kind"**, and that is a sharper rule than the one the contract's sentence
suggests.

The comparator is explicit that a producer *may* say more than the oracle does —
it only compares `resolved` where the oracle states one — so the cost was
entirely one-directional. Silence was the expensive choice.

**Worth carrying:** `hasValidation` and `resolved` are the same shape of
question and they resolve **opposite ways**, in the same payload, against the
same contract sentence. "Absent means not stated" tells you how to write down an
answer; it does not tell you whether you have one.

---

## F-4. `hasDefault` / `hasValidation` cost nothing — the tf-001 lesson held

Zero differences on either field. The producer wrote `hasDefault` both ways and
`hasValidation` only when true; the oracle draws exactly the same line.

This is the one place a prior run's finding is *visibly* load-bearing: tf-001
closed on 28 identical `hasValidation` differences, tf-002 settled it, and the
skill states the asymmetry with the number attached. It did not recur. See the
blindness bound in the run record — this is also the clearest case of the
plugin carrying a previous fixture's answer forward.

---

## F-5. The build's coverage gate could not fail, and printed that it could not

`Invoke-Pester -Configuration $cfg` returns **nothing** unless
`$cfg.Run.PassThru = $true`. Without it `$result` is `$null`, so:

```powershell
$percent = [math]::Round($null, 2)   # 0
$target  = $null
if ($percent -lt $target) { throw ... }   # 0 -lt $null is FALSE
```

The gate passed on every run and could not have done otherwise. It printed
`Line coverage: 0% (target %)` for one build — the defect was visible on the
console and invisible in the exit code, and it was found by reading the line
rather than the status.

The `PreTag` guard had the same defect with the opposite sign: `$null.PassedCount
+ $null.FailedCount` is `0`, so the guard would have thrown *"selected no test at
all"* on a green run.

**Fixed, then falsified:** target raised 70 → 99 against 92.48% actual, build
went red naming both numbers; restored, green. `powershell-module-build` states
the gate's shape and the assertion it is graded by, and neither of those catches
a gate reading a null.

---

## F-6. InvokeBuild's `Write-Build` writes to the OUTPUT stream

Colouring the console is all it adds. A function that calls `Write-Build` **and**
returns a value returns both, as a two-element array. `Resolve-BuildDependency`
— written from `powershell-module-build`'s worked example, which has this shape
— returned `@('  PSGraphRenderToHtml: 0.1.0 at C:\...', 'C:\...psd1')`.

The failure surfaced three tasks later as:

    Cannot find drive. A drive with the name '  PSGraphRenderToHtml' does not exist.

Nothing in that message points at the resolver, and the resolver's own log line
had *silently vanished from the build output* because it had been captured — the
one visible symptom was a missing line nobody was looking for.

**The published example carries the defect.** `powershell-module-build`'s
`Resolve-BuildDependency` ends with `Write-Build Green "..."` followed by
`$resolved`. It is only harmless while nothing uses the return value as a path.
Recorded as a plugin finding, not a target one.

---

## F-7. An object written on one line separates its entries with commas

`required_providers = { random = { source = "hashicorp/random", version = "3.6.0" } }`

An expression walk that ends at a newline or a closing bracket reads `source` as
everything after the first `=`, giving `hashicorp/random", version = "3.6.0`, and
finds no `version` at all. Commas inside a function call, a list or a string are
at a depth above zero or are not code positions, so `>= 3.4.0, < 4.0.0` survives
whole.

Found by the **test fixture**, not by the live repositories — fixture 2 writes
`required_providers` only in its block form, across three lines. A reader tested
only against the measured fixture would have shipped this.

`tf-hcl-parse` names the block/attribute duality and the four constructs that
defeat a regex. It does not name the separator, and the separator is a third
spelling inside the attribute form.

---

## F-8. Fixture 2 has seven named cases and no case scorer

`evals/tf/Test-TfFixtureCase.ps1` is hard-coded to fixture 1's repository names.
Fixture 2 arrived at pass 0035 with `cases.md`, an oracle, a sanitization gate
and an eight-way falsification driver — and nothing from which
`functional-tf: N / 7` could be computed.

This run wrote its own at
[`plans/0036-tf-003/Test-Tf003Case.ps1`](../../plans/0036-tf-003/Test-Tf003Case.ps1),
because pass 0036 may not touch `evals/`. **A scorer living in a plan directory
is a scorer the next run will not find.** Promoting it is queued.

---

## F-9. The control run caught the scorer, not the graph

Scored against itself, the **oracle failed case 6**.

`cases.md` says `TfSiteCore:.#var.archive_retention_weeks` is *"a node with no
outgoing edge and no incoming edge — the only node in the fixture with
neither."* Read literally that is false of the oracle: the three `repository`
nodes and all six `provider` nodes have neither either, because they take part
in containment rather than in value flow. Nine other nodes satisfy the sentence
as written.

The claim the case is making is about value flow, and scoped to
`variable`/`local`/`output` it holds exactly — one node, that node. The scorer
was corrected; the fixture and the oracle were not touched.

**The order matters.** Had the control not been run, case 6 would have read FAIL
against the producer on both shots and the run would have reported
`functional-tf 5 / 7 → 6 / 7` — a wrong number in the direction of modesty,
which is the direction nobody audits. *An oracle scored against itself must come
back perfect, and a scorer that fails it is the thing that is broken.*

---

## F-10. Cloning without putting the token in a URL

`azdo-rest` forbids a PAT in a URL and the brief repeats it, and both are about
the REST client. Cloning needs the same credential and neither says how.

    $env:GIT_CONFIG_COUNT   = '1'
    $env:GIT_CONFIG_KEY_0   = 'http.extraHeader'
    $env:GIT_CONFIG_VALUE_0 = 'Authorization: Basic ' + <base64 of ":$env:AZDO_PAT">

Environment only — not a URL, and not a command line either, so it survives
`ps`, shell history and a transcript. `git -c http.extraHeader=...` would put
the credential in the process arguments, which is the same class of mistake one
layer down.

---

## What did not go wrong, and is worth saying

- **No AzDO write of any kind.** Three `git clone` operations and nothing else;
  zero REST calls were made against the live organisation in the whole run, and
  zero builds were queued.
- **The comparator's duplicate-id assertion was exercised** and refused a
  planted duplicate. See `verify.ps1` check 3.
- **The producer battery was green on the first graph the module ever
  produced**, 7 / 7, and stayed green.
- **Determinism held.** Two runs over the same configuration produce
  byte-identical files; the graph carries no absolute path and no timestamp.
