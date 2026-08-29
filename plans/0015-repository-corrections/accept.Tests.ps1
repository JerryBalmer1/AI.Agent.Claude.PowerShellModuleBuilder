#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")

Describe 'Pass 0015 corrections are in place' {
    It 'BRIEF no longer says ten cases' {
        (Select-String -Path "$RepoRoot/evals/functional/BRIEF.md" -Pattern 'ten cases' -AllMatches).Count | Should -Be 0
    }
    It 'BRIEF says twelve cases three times' {
        (Select-String -Path "$RepoRoot/evals/functional/BRIEF.md" -Pattern 'twelve cases' -AllMatches).Matches.Count | Should -Be 3
    }
    It 'TASK.md opens with a supersession notice' {
        (Get-Content "$RepoRoot/evals/conformance/TASK.md" -TotalCount 4) -join ' ' | Should -Match 'Superseded'
    }
    It 'decision 0005 exists' {
        Test-Path "$RepoRoot/decisions/0005-branch-and-merge-policy.md" | Should -BeTrue
    }
    It 'verify run records exist for 0011, 0012, 0014' {
        foreach ($n in '0011','0012','0014') {
            Test-Path "$RepoRoot/plans/0015-repository-corrections/verify-runs/$n.txt" | Should -BeTrue
        }
    }
    It 'each verify run record states an observed exit code' {
        foreach ($n in '0011','0012','0014') {
            Get-Content "$RepoRoot/plans/0015-repository-corrections/verify-runs/$n.txt" -Raw | Should -Match 'EXIT CODE: \d+'
        }
    }
}
