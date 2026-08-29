# 0011 — Terraform fixture governance and run ledger

Operator-directed, 2026-08-29. The Terraform fixture is three
repos — TfFixtureNetwork, TfFixtureApp, TfFixtureShared — in
AzDO project ClaudeTestingTerraform, authored in the harness at
evals/tf/fixture/repos/ and pushed; the harness copy is the
source of truth, verified by byte read-back. Once its oracle is
falsified, the fixture is frozen like ClaudeTesting: changes
require a new decision. Pipeline definitions are created and
never queued. PSTerraformGraph scoring runs are recorded in the
harness as runs/tf-NNN-<slug>, a ledger separate from the
PSAzureDevOpsGraph NNN series; tf-001 is the first build.
Line 1's runs 004–006 remain reserved for the plugin-on
PSAzureDevOpsGraph measurements.
