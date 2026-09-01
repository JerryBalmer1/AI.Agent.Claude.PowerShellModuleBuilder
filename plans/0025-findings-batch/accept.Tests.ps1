#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0025 delivered' {
    It 'decision 0012 exists' {
        Test-Path "$RepoRoot/decisions/0012-fixture-case3-repair.md" | Should -BeTrue }
    It 'tf-002 is 7/7' {
        (Get-Content "$RepoRoot/runs/tf-002-convention-and-case3/README.md" -Raw) |
            Should -Match 'functional-tf:\s*7\s*/\s*7' }
    It 'tf-002 records the model version' {
        (Get-Content "$RepoRoot/runs/tf-002-convention-and-case3/README.md" -Raw) |
            Should -Match 'model-version:\s*\S+' }
    It 'oracle re-falsified after amendment' {
        (Get-Content "$RepoRoot/plans/0025-findings-batch/mutations.txt" -Raw) |
            Should -Match 'DETECTED: 7 / 7' }
    It 'new and amended skills exist' {
        Test-Path "$RepoRoot/skills/producer-contract/SKILL.md" | Should -BeTrue
        (Get-Content "$RepoRoot/skills/powershell-module-scaffold/SKILL.md" -Raw) |
            Should -Match 'dev.?loader' }
    It 'conformance states a stable denominator' {
        (Get-Content "$RepoRoot/plans/0025-findings-batch/denominator.txt" -Raw) |
            Should -Match 'cases-defined identical across shapes: True' }
    It 'LEDGER exists with the four registers' {
        $l = Get-Content "$RepoRoot/LEDGER.md" -Raw
        $l | Should -Match '(?m)^## Passes'
        $l | Should -Match '(?m)^## Runs'
        $l | Should -Match '(?m)^## Versions'
        $l | Should -Match '(?m)^## Backlog' }
}
