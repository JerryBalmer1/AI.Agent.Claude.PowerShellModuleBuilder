# Findings — run tf-001

Sorted by mechanism. The plugin findings are the product of this run: the module
is the deliverable, and what the skills did and did not carry to a non-AzDO
target is what the harness is for.

## A. The plugin skills, on a target they were not written for

The `powershell-module-*` skills were distilled from building
PSAzureDevOpsGraph. This is the first time they have driven a module with a
different domain, a different dependency shape and no REST client at all.

### A-1. `powershell-module-scaffold` makes `src/` un-importable, and says nothing about it

**Mechanism.** The skill's manifest pattern sets `RootModule = '<Name>.psm1'`
and states that the psm1 is *generated* into `output/` and does not exist in
`src/`. That is correct for the build and it means
`Import-Module src/<Name>/<Name>.psd1` fails outright.

**Cost here.** The pass's own acceptance test imports from `src/`. So does pass
0022's. PSGraphRender, built to this pattern, cannot be imported from `src/`
today either.

**What works.** A committed dev-loader `.psm1` in `src/` that dot-sources
`Private/**` then `Public/*` and exports the same list. It must dot-source
rather than concatenate, so `$script:ModuleRoot` means the same thing under both
loaders and any asset resolves either way.

**Recommendation.** The skill should carry the dev loader as part of the
scaffold. This is the second module in two passes to need it, and both times it
was found by an acceptance test failing rather than by reading the skill.

### A-2. The build skill's dependency resolver assumes one dependency name

**Mechanism.** `powershell-module-build` shows resolving a sibling checkout via
`$env:<DEP>_MODULE_PATH`. It is written for one hard-coded dependency
(`PSGraphRender`). PSTerraformGraph depends on PSGraphRenderToHtml, which itself
depends on PSGraphRender, and the pattern had to be copied and renamed by hand
in three places — the variable, two `throw` messages and the task name.

**Cost here.** Low, but it is copy-and-edit, and the second copy is where the
old name survives in a message.

**Recommendation.** Parameterise the resolver on the dependency name, or say in
the skill that it is a template to rename in four places and list them.

### A-3. Nothing in the skills covers a module whose output is *data* rather than a report

**Mechanism.** Every skill assumes the module's job ends in a document or an
object for a human. PSTerraformGraph's real output is a graph that another
module validates against a contract, and the thing that needed saying — run the
consumer's battery against your own output in your own build — is in
PSGraphRenderToHtml's HANDOFF and in no skill.

**Recommendation.** A `producer-contract` skill: how to emit against a contract
you do not own, and that the consumer's battery belongs in your build.

### A-4. `PSUseSingularNouns` versus a contract-fixed command name

Already recorded in pass 0022 and it recurred: the analyzer wants
`New-GraphRenderOption`. The exclusion is stated with its reason. Not a defect,
but it is the second module to need the same exclusion and the skill could name
it.

## B. Candidate `tf-<role>` skills

Written from what actually cost time here rather than from what a Terraform
module might plausibly need.

### B-1. `tf-hcl-parse`

**Would carry:** that a regex over a whole file cannot work, and the four
specific reasons — a brace inside a string, a `#` inside a string, a heredoc
whose terminator is a bare word on its own line, and a block comment. That
`required_providers` appears **both** as a block and as an attribute with an
object value, and a reader that handles one finds no providers at all and says
nothing. That an expression's raw text is what a reference extractor needs, and
if the parser rebuilds it by joining tokens then every pattern written against
source text will miss.

**Evidence:** iterations 2 and 3 of this run were exactly these three defects,
and together they were 63 of the 94 differences.

### B-2. `tf-module-resolve`

**Would carry:** that a Terraform registry address `namespace/name/provider` and
a relative path `./modules/child` are the same shape to a naive pattern, and the
leading-dot guard that separates them. That the `//` in a `git::` source is the
subdirectory separator and has to be searched for *past* the scheme's own `//`.
That an unresolvable source must become a node plus a flagged edge, never a
dropped reference.

**Evidence:** the registry-versus-relative collision cost 12 node differences
and 6 edges in iteration 1, and it fails silently — every nested module simply
vanishes into an invented registry node.

### B-3. `tf-graph-assembly`

**Would carry:** that containment is the directory tree and not the module
calls, so a module nothing calls is still contained; that a module's parent is
the nearest module *above it in its own path*, which is not the same as its
caller; and that deduplicating edges matters because one value referenced twice
in one expression is one fact.

## C. Defects in the fixture and the oracle — findings, not edits

The fixture is frozen by decision 0011 and was not touched.

### C-1. Case 3 is not mechanically derivable

**Mechanism.** `cases.md` case 3 says TfFixtureApp's `var.network_segment_id`
carries TfFixtureNetwork's `output.segment_id`. Nothing in the HCL says so — the
tie is made in the variable's **description**, which is prose. No parser can
find it without reading English.

**Consequence.** Case 3 cannot be passed by any producer, and it is the only
case in the fixture that a single-repository parser could not see — which is to
say, the case the three-repository fixture was built for is the one that does
not work.

**Suggested repair, for a future decision:** make the tie mechanical. A
`terraform_remote_state` data source, or a module block in TfFixtureApp sourcing
TfFixtureNetwork and passing its output, would make the reference something the
configuration actually states.

### C-2. The oracle omits `hasValidation` where it is false; the producer writes it

**Mechanism.** Absent versus `false`. 28 of the 31 remaining differences, all
one convention.

**Which is right:** the producer contract says an absent optional field means
NOT STATED, which argues for the oracle's convention and against the producer's.
The producer should omit `hasValidation` when there is no validation block. Not
changed here because the iteration cap was reached, and worth settling once in
the contract rather than per-producer.

## D. A genuine producer gap, unfixed

### D-1. Splat syntax in a module reference

`module.subnet[*].id` — the reference extractor's pattern captures
`module.<name>.<member>` and does not handle `[*]` between them, so the edge
`subnet#output.id → segment#output.subnet_ids` is missing. One difference, one
pattern to widen. Left because the three-iteration cap was reached, and recorded
rather than quietly fixed after the score was taken.
