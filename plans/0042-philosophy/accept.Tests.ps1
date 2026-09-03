#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0042 delivered' {
    It 'the philosophy exists and maps every law to an artifact' {
        $p = Get-Content "$RepoRoot/method/PHILOSOPHY.md" -Raw
        foreach ($m in 'The goal','Law 1','Law 5','Meta-law',
                       'What this is not') { $p | Should -Match $m }
        ([regex]::Matches($p,
            '\]\((\.\./)?(evals|runs|decisions|PLAN-PROTOCOL|prompts|docs)')).Count |
            Should -BeGreaterOrEqual 5 }
    It 'METHOD links it as the why-layer' {
        (Get-Content "$RepoRoot/method/METHOD.md" -Raw) |
            Should -Match 'PHILOSOPHY\.md' }
    It 'the director store exists with protocol and both versions' {
        Test-Path "$RepoRoot/docs/director/README.md" | Should -BeTrue
        Test-Path "$RepoRoot/docs/director/CONTEXT-v001.md" | Should -BeTrue
        Test-Path "$RepoRoot/docs/director/CONTEXT-v002.md" | Should -BeTrue }
    It 'v002 carries the goal and the reconciled sections' {
        $c = Get-Content "$RepoRoot/docs/director/CONTEXT-v002.md" -Raw
        foreach ($m in '## The goal','PHILOSOPHY','Director context is versioned',
                       'routing','Local handoff','Presentation standard',
                       'self-audit') { $c | Should -Match $m } }
    It 'the template gains goal, philosophy, and versioning' {
        $t = Get-Content "$RepoRoot/prompts/project-context-template.md" -Raw
        $t | Should -Match 'The goal'
        $t | Should -Match 'PHILOSOPHY'
        $t | Should -Match 'CONTEXT-v' }
    It 'README carries one line, no more' {
        ([regex]::Matches((Get-Content "$RepoRoot/README.md" -Raw),
            'PHILOSOPHY')).Count | Should -Be 1 }
    It 'v1.2.1 released' {
        (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw |
            ConvertFrom-Json).version | Should -Be '1.2.1'
        (Get-Content "$RepoRoot/CHANGELOG.md" -Raw) |
            Should -Match '(?m)^## 1\.2\.1'
        (git ls-remote --tags origin 'v1.2.1*') |
            Should -Not -BeNullOrEmpty }
}
