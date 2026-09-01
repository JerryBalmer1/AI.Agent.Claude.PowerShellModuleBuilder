# 0012 — The case-3 repair, and the one amendment decision 0011 provides for

Agent-proposed from run tf-001's finding C-1, executed in pass 0025. Decision
0011 froze the Terraform fixture once its oracle was falsified and said changes
require a new decision. This is that decision, and it authorises **exactly one**
amendment, described here in full. After the re-freeze the fixture is closed
again on the same terms.

## What is wrong

`evals/tf/fixture/cases.md` case 3 — "cross-repository output reference" —
claims two `references` edges:

    TfFixtureNetwork:.#output.segment_id  ->  TfFixtureApp:.#var.network_segment_id
    TfFixtureNetwork:.#output.subnet_ids  ->  TfFixtureApp:.#var.network_subnet_ids

Nothing in the HCL states either one. The tie is made in the **description
string** of `variable "network_segment_id"` in `TfFixtureApp/variables.tf`:

    description = "TfFixtureNetwork's segment_id output, supplied by the caller. The cross-repository output-reference case."

That is prose. A configuration parser cannot find it, and one that appeared to
would be pattern-matching English rather than reading the configuration.

Two consequences, and the second is why this is a decision and not a note:

1. **No producer can pass case 3.** Run tf-001 scored 6/7 with case 3 the only
   failure, and its two missing edges were 2 of the 31 remaining differences.
   The case is not a hard case; it is an impossible one.
2. **It is the case the three-repository fixture exists for.** Case 3 is the
   only case a single-repository parser could not see at all. The fixture was
   built across three repositories to hold exactly this, and this is the part
   that does not work.

There is a third defect in the same two edges, found while re-authoring them.
They are the only `references` edges in the oracle carrying `"resolved": true`;
every other `references` edge states nothing, and `resolved` appears elsewhere
only on `sources` edges. The producer contract says an absent optional field
means NOT STATED, so a producer emitting a correct `references` edge without
`resolved` would have been charged a `WrongAttribute` difference on these two
and on no others. The re-authoring drops it.

## The amendment

**One construct is added to `TfFixtureApp`: a `module "network"` block sourcing
TfFixtureNetwork's root by `git::` URL.** The two variables that only claimed
the tie in prose become two locals that read that module's outputs, so the
reference becomes something the configuration states.

`TfFixtureApp/main.tf` gains:

```hcl
module "network" {
  source = "git::https://jlbalmerjr1@dev.azure.com/jlbalmerjr1/ClaudeTestingTerraform/_git/TfFixtureNetwork?ref=main"

  network_name = var.application_name
}
```

and, in the existing `locals` block:

```hcl
network_segment_id = module.network.segment_id
network_subnet_ids = module.network.subnet_ids
```

`local.merged_tags` reads `local.network_segment_id` where it read
`var.network_segment_id`; `module "service"` receives `local.network_subnet_ids`
where it received `var.network_subnet_ids`. `TfFixtureApp/variables.tf` loses
the two variable blocks.

### Why a module block and not terraform_remote_state

Both were considered. `data "terraform_remote_state"` is the idiomatic way one
Terraform configuration reads another's outputs, and tf-001's finding C-1
suggested it first. It is rejected here because:

- It ties the fixture to a **state backend**, and the premise of
  PSTerraformGraph is that it reads configuration and never runs terraform,
  never reads state. A case whose subject is a state reference invites a
  producer to model something this line of work has said it does not do.
- The reference it produces is `data.terraform_remote_state.<name>.outputs.<x>`,
  which names the *backend configuration*, not TfFixtureNetwork. Resolving it to
  `TfFixtureNetwork:.#output.segment_id` still requires knowing out of band that
  this backend holds that repository's state — the same prose problem in a new
  costume.

A `module` block names the source repository in the source string itself. The
resolution is mechanical end to end: source URL, repository, root module, its
declared outputs.

### What the construct also exercises, deliberately

The `git::` URL carries **no `//subdirectory`**, which is what says "the
repository's root module". Case 2's cross-repository source
(`…/TfFixtureShared//modules/naming?ref=main`) exercises the subdirectory form
only. A resolver that splits on `//` and requires a subdirectory passes case 2
and fails this. The distinction is real Terraform semantics, and the fixture now
holds both forms.

## The oracle, re-authored

Node count is unchanged at **78**: two variables become two locals.

| | Removed | Added |
| --- | --- | --- |
| nodes | `TfFixtureApp:.#var.network_segment_id`, `TfFixtureApp:.#var.network_subnet_ids` | `TfFixtureApp:.#local.network_segment_id`, `TfFixtureApp:.#local.network_subnet_ids` |

Edges go from **57 to 59**. Four removed, six added.

Removed:

    references  TfFixtureNetwork:.#output.segment_id -> TfFixtureApp:.#var.network_segment_id   [resolved: true]
    references  TfFixtureNetwork:.#output.subnet_ids -> TfFixtureApp:.#var.network_subnet_ids   [resolved: true]
    references  TfFixtureApp:.#var.network_segment_id -> TfFixtureApp:.#local.merged_tags
    passes-to   TfFixtureApp:.#var.network_subnet_ids -> TfFixtureApp:modules/service#var.subnet_ids

Added:

    sources     TfFixtureApp:. -> TfFixtureNetwork:.                                            [resolved: true]
    passes-to   TfFixtureApp:.#var.application_name -> TfFixtureNetwork:.#var.network_name
    references  TfFixtureNetwork:.#output.segment_id -> TfFixtureApp:.#local.network_segment_id
    references  TfFixtureNetwork:.#output.subnet_ids -> TfFixtureApp:.#local.network_subnet_ids
    references  TfFixtureApp:.#local.network_segment_id -> TfFixtureApp:.#local.merged_tags
    passes-to   TfFixtureApp:.#local.network_subnet_ids -> TfFixtureApp:modules/service#var.subnet_ids

The two cross-repository `references` edges no longer state `resolved`, matching
every other `references` edge in the oracle.

`cases.md` case 3 is rewritten to state the mechanical construct rather than the
prose one, and its counts table moves two nodes from the variable row to the
local row.

## The 31st difference is not part of this

Run tf-001 closed on 31 differences: 28 `hasValidation` convention, 2 case 3,
and one more. Pass 0025 re-ran `Compare-TfGraph` against the committed tf-001
graph and named it:

    MissingEdge  TfFixtureNetwork:modules/segment/modules/subnet#output.id
              -> TfFixtureNetwork:modules/segment#output.subnet_ids    kind=references

The expression is `module.subnet[*].id`. It is a **producer defect** — the
reference extractor's pattern does not tolerate a splat or an index between the
module name and the member — and it is fixed in PSTerraformGraph, not here. The
oracle is right about it. It is named in this decision only so the record shows
all 31 accounted for, and that only case 3's two reached the fixture.

## Alternatives rejected

**Leave case 3 permanently unpassable.** Rejected. A case no implementation can
pass is not a hard case, it is a broken one, and a 6/7 whose missing point is
unreachable teaches a reader nothing about the producer. It would also mean
functional-tf can never be 7/7, so the score loses its top and stops
discriminating at the interesting end.

**Delete case 3.** Rejected under rule 4 — the fixture does not shrink to make a
score go up. Deleting it would also delete the only case that justifies the
fixture being three repositories rather than one, which is a far larger loss
than the defect.

**Amend the producer instead, to read descriptions.** Not seriously considered,
and recorded so that it is visibly not an option: a parser that infers edges
from English prose in a description would score well here and be wrong
everywhere else. It is the failure mode the fixture exists to catch.

## The freeze

The push, the byte read-back, the re-falsification of the amended oracle (all
seven mutations, plus the oracle-against-itself control at zero) and the new
SHAs are recorded in `plans/0025-findings-batch/`. From the moment that
read-back reads `BYTE-IDENTICAL`, the fixture is frozen again on decision 0011's
terms and nothing later in pass 0025 touches it — including the scoring run,
which takes the number it gets.
