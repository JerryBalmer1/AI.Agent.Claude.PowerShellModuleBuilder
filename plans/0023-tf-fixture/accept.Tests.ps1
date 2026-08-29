#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0023 delivered' {
    It 'fixture source committed' {
        foreach ($r in 'TfFixtureNetwork','TfFixtureApp','TfFixtureShared') {
            Test-Path "$RepoRoot/evals/tf/fixture/repos/$r/main.tf" | Should -BeTrue
        }
    }
    It 'oracle exists' {
        Test-Path "$RepoRoot/evals/tf/fixture/expected-graph.json" | Should -BeTrue
    }
    It 'comparator exists with mutation evidence' {
        Test-Path "$RepoRoot/evals/tf/Compare-TfGraph.ps1" | Should -BeTrue
        Test-Path "$RepoRoot/evals/tf/Mutate-TfGraph.ps1"  | Should -BeTrue
        (Get-Content "$RepoRoot/plans/0023-tf-fixture/mutations.txt" -Raw) |
            Should -Match 'DETECTED: 7 / 7'
    }
    It 'read-back verified' {
        (Get-Content "$RepoRoot/plans/0023-tf-fixture/readback.txt" -Raw) |
            Should -Match 'BYTE-IDENTICAL'
    }
    It 'decision 0011 exists' {
        Test-Path "$RepoRoot/decisions/0011-terraform-fixture-and-run-ledger.md" |
            Should -BeTrue
    }
}
