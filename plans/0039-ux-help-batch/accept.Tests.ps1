#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0039 delivered' {
    It 'the two new skills exist' {
        Test-Path "$RepoRoot/skills/powershell-module-ux/SKILL.md"   | Should -BeTrue
        Test-Path "$RepoRoot/skills/powershell-module-tidy/SKILL.md" | Should -BeTrue }
    It 'ux skill cites its source and carries the cache guardrails' {
        $s = Get-Content "$RepoRoot/skills/powershell-module-ux/SKILL.md" -Raw
        $s | Should -Match 'powershell\.one'
        $s | Should -Match 'never cache.*(secret|credential|token)' }
    It 'analyzer gained the class-candidate rule' {
        (Get-Content "$RepoRoot/skills/powershell-module-analyzer/SKILL.md" -Raw) |
            Should -Match 'PSCustomObject' }
    It 'docs skill carries the house example standard' {
        (Get-Content "$RepoRoot/skills/powershell-module-docs/SKILL.md" -Raw) |
            Should -Match 'splat' }
    It 'plan skill owns the master plan' {
        (Get-Content "$RepoRoot/skills/powershell-module-plan/SKILL.md" -Raw) |
            Should -Match 'docs/PLAN\.md' }
    It 'help assertions exist with falsification evidence' {
        Test-Path "$RepoRoot/evals/conformance/Help.Tests.ps1" | Should -BeTrue
        $f = Get-Content "$RepoRoot/plans/0039-ux-help-batch/help-falsification.txt" -Raw
        $f | Should -Match 'BREAKS: \d+ / \d+ red'
        $f | Should -Match 'CONTROLS: \d+ / \d+ green' }
    It 'settings file support exists and is asserted' {
        (Get-Content "$RepoRoot/plans/0039-ux-help-batch/settings-falsification.txt" -Raw) |
            Should -Match 'UNKNOWN KEY: refused' }
    It 'the denominator boundary is recorded' {
        $d = Get-Content "$RepoRoot/plans/0039-ux-help-batch/denominator-v2.txt" -Raw
        $d | Should -Match 'cases-defined \(pre\):\s*33'
        $d | Should -Match 'cases-defined \(post\):\s*\d+'
        $d | Should -Match 'series boundary: v1\.2\.0' }
    It 'reference target still scores clean on the new suite' {
        (Get-Content "$RepoRoot/plans/0039-ux-help-batch/refscore.txt" -Raw) |
            Should -Match 'RUN-006 CLONE \(built\): \d+ / \d+ .* Bucket B declared' }
    It 'manifest is 1.2.0 with a CHANGELOG entry and v1.2.0 on the remote' {
        (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version |
            Should -Be '1.2.0'
        (Get-Content "$RepoRoot/CHANGELOG.md" -Raw) | Should -Match '(?m)^## 1\.2\.0'
        (git ls-remote --tags origin 'v1.2.0*') | Should -Not -BeNullOrEmpty }
}
