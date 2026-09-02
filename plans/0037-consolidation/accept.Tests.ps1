#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0037 delivered' {
    It 'fixture-2 case scorer promoted and falsified' {
        Test-Path "$RepoRoot/evals/tf/fixture2/Test-TfFixture2Case.ps1" | Should -BeTrue
        (Get-Content "$RepoRoot/plans/0037-consolidation/case-scorer.txt" -Raw) |
            Should -Match 'FALSIFIED: 7 / 7 cases each defeated by its own mutation'
        (Get-Content "$RepoRoot/plans/0037-consolidation/case-scorer.txt" -Raw) |
            Should -Match 'ORACLE VS SELF: 7 / 7' }
    It 'cases.md false clause corrected' {
        (Get-Content "$RepoRoot/evals/tf/fixture2/cases.md" -Raw) |
            Should -Not -Match 'only node in the fixture with neither' }
    It 'suite counts re-pinned and green' {
        (Get-Content "$RepoRoot/plans/0037-consolidation/suites.txt" -Raw) |
            Should -Match 'FIXTURE1: 15 passed, 0 failed'
        (Get-Content "$RepoRoot/plans/0037-consolidation/suites.txt" -Raw) |
            Should -Match 'FIXTURE2: .* 0 failed' }
    It 'README carries the bounded generalisation claim' {
        $r = Get-Content "$RepoRoot/README.md" -Raw
        $r | Should -Match 'unseen fixture'
        $r | Should -Match 'third domain or a plugin-off control'
        $r | Should -Match 'tf-003' }
    It 'tf-003 record re-scored by the promoted scorer' {
        (Get-Content "$RepoRoot/runs/tf-003-generalisation/README.md" -Raw) |
            Should -Match 'rescored by evals/tf/fixture2/Test-TfFixture2Case\.ps1' }
    It 'manifest is 1.1.1 with a CHANGELOG entry' {
        (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version |
            Should -Be '1.1.1'
        (Get-Content "$RepoRoot/CHANGELOG.md" -Raw) | Should -Match '(?m)^## 1\.1\.1' }
    It 'v1.1.1 on the remote' {
        (git ls-remote --tags origin 'v1.1.1*') | Should -Not -BeNullOrEmpty }
    It 'the operator decision is queued, not taken' {
        (Get-Content "$RepoRoot/LEDGER.md" -Raw) |
            Should -Match 'tf-004 plugin-off control: OPERATOR DECISION' }
}
