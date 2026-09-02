#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0034 delivered' {
    It 'decision 0014 exists' {
        Test-Path "$RepoRoot/decisions/0014-second-unannotated-fixture.md" | Should -BeTrue }
    It 'fixture-2 source committed' {
        foreach ($r in 'TfSiteCore','TfSiteEdge','TfSiteOps') {
            Test-Path "$RepoRoot/evals/tf/fixture2/repos/$r/main.tf" | Should -BeTrue } }
    It 'fixture-2 oracle and cases exist' {
        Test-Path "$RepoRoot/evals/tf/fixture2/expected-graph.json" | Should -BeTrue
        Test-Path "$RepoRoot/evals/tf/fixture2/cases.md" | Should -BeTrue }
    It 'sanitization scan of fixture 2 is clean' {
        (Get-Content "$RepoRoot/plans/0034-fixture2/sanitization.txt" -Raw) |
            Should -Match 'FIXTURE2 SANITIZATION: clean' }
    It 'oracle falsified' {
        (Get-Content "$RepoRoot/plans/0034-fixture2/mutations2.txt" -Raw) |
            Should -Match 'DETECTED: 7 / 7' }
    It 'read-back verified' {
        (Get-Content "$RepoRoot/plans/0034-fixture2/readback2.txt" -Raw) |
            Should -Match 'BYTE-IDENTICAL' }
    It 'tf skill batch exists' {
        (Get-ChildItem "$RepoRoot/skills" -Directory |
            Where-Object Name -like 'tf-*').Count | Should -BeGreaterOrEqual 2 }
    It 'the two candidate skill lines landed' {
        $b = Get-Content "$RepoRoot/skills/powershell-module-build/SKILL.md","$RepoRoot/skills/powershell-module-scaffold/SKILL.md","$RepoRoot/skills/azdo-rest/SKILL.md" -Raw
        ($b -join ' ') | Should -Match 'StrictMode'
        ($b -join ' ') | Should -Match 'Join-Path' }
    It 'manifest is 1.1.0 with a CHANGELOG entry' {
        (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version |
            Should -Be '1.1.0'
        (Get-Content "$RepoRoot/CHANGELOG.md" -Raw) | Should -Match '(?m)^## 1\.1\.0' }
    It 'v1.1.0 on the remote' {
        (git ls-remote --tags origin 'v1.1.0*') | Should -Not -BeNullOrEmpty }
}
