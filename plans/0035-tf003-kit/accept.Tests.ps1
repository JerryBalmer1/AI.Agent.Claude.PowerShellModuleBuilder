#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0035 delivered' {
    It 'comparator rejects duplicate ids' {
        (Get-Content "$RepoRoot/plans/0035-tf003-kit/mutation8.txt" -Raw) |
            Should -Match 'DUPLICATE-ID: detected on producer side'
        (Get-Content "$RepoRoot/plans/0035-tf003-kit/mutation8.txt" -Raw) |
            Should -Match 'DUPLICATE-ID: detected on oracle side' }
    It 'both fixture suites still green' {
        (Get-Content "$RepoRoot/plans/0035-tf003-kit/suites.txt" -Raw) |
            Should -Match 'FIXTURE1: 15 passed, 0 failed'
        (Get-Content "$RepoRoot/plans/0035-tf003-kit/suites.txt" -Raw) |
            Should -Match 'FIXTURE2: .*0 failed' }
    It 'backlog 31 settled in writing' {
        (Get-Content "$RepoRoot/decisions/0014-second-unannotated-fixture.md" -Raw) |
            Should -Match 'pipeline definitions are outside the TF measurement surface' }
    It 'the tf brief and seed exist' {
        Test-Path "$RepoRoot/evals/tf/BRIEF.md" | Should -BeTrue
        Test-Path "$RepoRoot/evals/tf/seed/README.md" | Should -BeTrue }
    It 'brief and seed are sanitized' {
        (Get-Content "$RepoRoot/plans/0035-tf003-kit/kit-sanitization.txt" -Raw) |
            Should -Match 'TF003 KIT SANITIZATION: clean' }
    It 'a reset exists for the tf measurement line' {
        Test-Path "$RepoRoot/evals/tf/Reset-TfTarget.ps1" | Should -BeTrue
        (Get-Content "$RepoRoot/plans/0035-tf003-kit/reset-falsification.txt" -Raw) |
            Should -Match 'REFUSED: outside scratch' }
    It 'pins recorded for tf-003' {
        $l = Get-Content "$RepoRoot/LEDGER.md" -Raw
        $l | Should -Match 'tf-003 brief blob:\s*[0-9a-f]{40}'
        $l | Should -Match 'tf-003 seed tree:\s*[0-9a-f]{40}' }
}
