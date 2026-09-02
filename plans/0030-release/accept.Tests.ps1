#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0030 delivered' {
    It 'marketplace exists and parses' {
        Test-Path "$RepoRoot/.claude-plugin/marketplace.json" | Should -BeTrue
        { Get-Content "$RepoRoot/.claude-plugin/marketplace.json" -Raw | ConvertFrom-Json } |
            Should -Not -Throw }
    It 'manifest is 1.0.0' {
        (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version |
            Should -Be '1.0.0' }
    It 'adoption boilerplate exists' {
        foreach ($f in 'SECURITY.md','CHANGELOG.md','LICENSE') {
            Test-Path "$RepoRoot/$f" | Should -BeTrue }
        (Get-Content "$RepoRoot/README.md" -Raw) | Should -Match '(?m)^## Support' }
    It 'prerequisite checker exists with falsification evidence' {
        Test-Path "$RepoRoot/tools/publish/Test-Prerequisites.ps1" | Should -BeTrue
        (Get-Content "$RepoRoot/plans/0030-release/hostile-first-run.txt" -Raw) |
            Should -Match 'ALL PROBES: named one-line errors' }
    It 'backlog 20 fixed: TF comparator tests green' {
        (Invoke-Pester "$RepoRoot/evals/tf/Compare-TfGraph.Tests.ps1" -PassThru).FailedCount |
            Should -Be 0 }
    It 'backlog 22 fixed: PLAN-PROTOCOL clause corrected' {
        (Get-Content "$RepoRoot/PLAN-PROTOCOL.md" -Raw) |
            Should -Not -Match 'shipped without the red-first test' }
    It 'decision 0013 exists' {
        Test-Path "$RepoRoot/decisions/0013-harness-release-tagging.md" | Should -BeTrue }
    It 'install docs give the three commands' {
        (Get-Content "$RepoRoot/README.md" -Raw) |
            Should -Match '/plugin marketplace add JerryBalmer1/AI\.Agent\.Claude\.PowerShellModuleBuilder' }
    It 'v1.0.0 on the remote' {
        (git ls-remote --tags origin 'v1.0.0*') | Should -Not -BeNullOrEmpty }
    It 'docs updated in the same pass (item 19)' {
        (Get-Content "$RepoRoot/docs/creating-an-agent/09-try-before-you-trust.md" -Raw) |
            Should -Match 'PublishReal' 
        (Get-Content "$RepoRoot/docs/creating-an-agent/09-try-before-you-trust.md" -Raw) |
            Should -Not -Match 'guarded until packaging lands' }
}
