#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0040 delivered' {
    It 'decision 0015 exists' {
        Test-Path "$RepoRoot/decisions/0015-falsifying-against-a-red-target.md" | Should -BeTrue }
    It 'LEDGER 47 resolved with evidence' {
        (Get-Content "$RepoRoot/plans/0040-flow-docs/splat-coverage.txt" -Raw) |
            Should -Match 'SPLAT EXAMPLE: (passes as shipped|repaired and falsified)' }
    It 'the diagram exists in both renderings' {
        (Get-Content "$RepoRoot/README.md" -Raw) | Should -Match '```mermaid'
        Test-Path "$RepoRoot/docs/diagram/flow.html" | Should -BeTrue
        Test-Path "$RepoRoot/docs/diagram/flow-graph.json" | Should -BeTrue
        Test-Path "$RepoRoot/tools/diagram/Build-Diagram.ps1" | Should -BeTrue }
    It 'the diagram link map exists' {
        (Get-Content "$RepoRoot/README.md" -Raw) | Should -Match 'link map' }
    It 'the prompts kit exists in one directory' {
        foreach ($f in 'README.md','project-context-template.md',
                       'first-module.md','new-feature.md','release.md',
                       'troubleshoot.md') {
            Test-Path "$RepoRoot/prompts/$f" | Should -BeTrue } }
    It 'chapter 11 exists and README points at the flow' {
        Test-Path "$RepoRoot/docs/creating-an-agent/11-your-first-module.md" | Should -BeTrue
        (Get-Content "$RepoRoot/README.md" -Raw) | Should -Match 'The flow' }
    It 'the hybrid design note exists' {
        Test-Path "$RepoRoot/docs/design/hybrid-modules.md" | Should -BeTrue }
    It 'chapter 01 carries the human-paced paragraph' {
        (Get-Content "$RepoRoot/docs/creating-an-agent/01-the-two-claudes.md" -Raw) |
            Should -Match 'human-paced' }
    It 'the stranded-branch check joined the sync step' {
        (Get-Content "$RepoRoot/PLAN-PROTOCOL.md" -Raw) |
            Should -Match 'not an ancestor of.*main' }
    It 'no dead links in anything this pass touched' {
        (Get-Content "$RepoRoot/plans/0040-flow-docs/linkcheck.txt" -Raw) |
            Should -Match 'DEAD LINKS: 0' }
    It 'the local handoff rule exists where it binds' {
        (Get-Content "$RepoRoot/PLAN-PROTOCOL.md" -Raw) |
            Should -Match '(?m)^### Local handoff'
        (Get-Content "$RepoRoot/prompts/project-context-template.md" -Raw) |
            Should -Match 'LOCAL STATE' }
}
