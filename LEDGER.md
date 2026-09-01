# LEDGER — maintained by the agent as the last task of every pass

The chat context points here; this file is the source of truth
for counters and pins. Update it in the same commit as the work
that changes it.

## Passes
Last landed: 0025. Next: 0026.

## Runs
AzDO-module (runs/NNN-*): last 003, next 004 (passes 0026-0028;
0029 final-README rider on 006).
Terraform (runs/tf-NNN-*): last tf-002, next tf-003 (measured,
blind — not yet scheduled).

## Versions
PSAzureDevOpsGraph: v0.2.0 (next touching plan: v0.3.0)
PSGraphRender: v0.13.0
PSGraphRenderToHtml: v0.1.0 (next: v0.2.0)
PSTerraformGraph: v0.2.0
psmodule manifest: 0.1.0 (re-versioned at packaging, 0030;
v1.0.0 reserved for "passed the ladder")

## Pins
Harness main: pass-0025-findings-batch tip — the commit that adds
this file, fast-forwarded at pass close. Verified by ancestry and
by `git ls-remote`, never by quoting a SHA this file cannot know
about itself.
Ladder plugin SHA: unset until run 004 records it
Oracle blob (AzDO): bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc
TF fixture SHAs (decision-0012 re-freeze):
  TfFixtureShared   0af6ee33854bedb4147d0b13cc6db1311687775b  (unchanged)
  TfFixtureNetwork  24f27be92e583b6dfc9208bca42f8ec0baf5004b  (unchanged)
  TfFixtureApp      44ea9338ff35aef328bfa8d51835fc32bea590dd  (amended)

## Backlog (priority order; operator reorders)
1. Runs 004-006 + 0029 final README
2. 0030 packaging: marketplace.json, cold-install proof
3. Fixture restore drill (Sync-Fixture restore direction)
4. Per-skill ablation runs (suspects first)
5. Mirror assertion + dependency-wave ordering (post-ladder)
6. tf-003 generalisation measurement (blind Phase 1)
7. Portability / non-graph functional layer (on trigger only)

### Added by pass 0025

8. **PSTerraformGraph: `Export-TfConfigurationGraphHtml` is exported
   and no test invokes it.** Conformance 40/41 on that repository, the
   one failure being the invocation check. Found after v0.2.0 was
   tagged and pushed; fixing it would have meant rewriting a pushed tag
   or landing on `main` past the tag it follows, so it was recorded
   instead. Belongs to the next pass that opens that repository.
9. **The three `tf-<role>` skills tf-001 proposed were deliberately not
   written.** They would carry this fixture's specific answers, and
   tf-003 is meant to be the blind measurement against that same
   fixture. Writing them first measures the plugin's memory of tf-001
   rather than its generality. An operator decision, recorded not
   taken — see `runs/tf-002-convention-and-case3/findings.md` section C.
   Cleanest orders: write them after tf-003, or build a second Terraform
   fixture they were not written against.
10. **PSGraphRender cannot be imported from `src/`.** The third module
    to need the committed dev loader; noted as pending in its own
    HANDOFF and not applied, because pass 0025 was scoped to leave that
    repository's code untouched.
11. **Decision 0007's skill taxonomy has no bucket for a cross-cutting
    skill.** `producer-contract` is neither `powershell-module-<role>`
    nor `azdo-<role>`. Left as-is and flagged in the README rather than
    bent into a name that lies; worth settling if a second one appears.
