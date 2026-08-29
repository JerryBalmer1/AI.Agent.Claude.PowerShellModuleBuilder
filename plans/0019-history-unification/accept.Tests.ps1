#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0019 delivered' {
    BeforeAll {
        $script:refs = git ls-remote https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git
        $script:joined = ($refs | Out-String)
    }
    It 'target main moved off the orphan root' {
        $joined | Should -Not -Match '2c745310a97a551acc834e4b299a676536ea1f07\s+refs/heads/main'
    }
    It 'v0.2.0 exists on the remote' {
        $joined | Should -Match 'refs/tags/v0\.2\.0'
    }
    It 'decision 0009 exists' {
        Test-Path "$RepoRoot/decisions/0009-agent-moves-both-mains.md" | Should -BeTrue
    }
    It 'decision 0008 carries the amendment' {
        Get-Content "$RepoRoot/decisions/0008-target-main-follows-tags.md" -Raw |
            Should -Match 'allow-unrelated-histories'
    }
}
