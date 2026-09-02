#Requires -Version 7.2
param([string]$RunDir = "$PSScriptRoot/../../runs/tf-003-generalisation")
Describe 'Run tf-003 is complete' {
    It 'has a run README' { Test-Path "$RunDir/README.md" | Should -BeTrue }
    BeforeAll { $script:r = Get-Content "$RunDir/README.md" -Raw -ErrorAction SilentlyContinue }
    It 'records the plugin pin' { $r | Should -Match 'plugin-sha:\s*v1\.1\.0' }
    It 'records the model pin' { $r | Should -Match 'model-version:\s*claude-opus-5\[1m\]' }
    It 'records a fifth distinct session identifier' {
        $r | Should -Match 'session-identifier:\s*\S+'
        foreach ($id in 'b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db',
                        'cc4d301c-ed6d-476f-90d9-63b324a62658',
                        'f0302223-28f1-436d-85f3-04e168c8534c',
                        'c0002fae-addf-4ff6-847e-9faf5d6aa05e') {
            $r | Should -Not -Match $id } }
    It 'records brief and seed pins' { $r | Should -Match 'brief-sha:'; $r | Should -Match 'seed-tree:' }
    It 'records phase wall-clock' { $r | Should -Match 'phase-1-minutes:\s*\d+' }
    It 'states build and battery' {
        $r | Should -Match 'build:\s*(exit \d+|no build script)'
        $r | Should -Match 'battery:\s*\S+' }
    It 'states first-shot and final functional lines' {
        $r | Should -Match 'functional-tf \(first-shot\):\s*\d+\s*/\s*\d+'
        $r | Should -Match 'functional-tf \(final\):\s*\d+\s*/\s*\d+' }
    It 'has the generalisation comparison section' {
        $r | Should -Match '(?m)^## Generalisation comparison' }
    It 'has graph, diff, html, findings' {
        foreach ($f in 'graph.json','diff.txt','tf-003.html','findings.md') {
            Test-Path "$RunDir/$f" | Should -BeTrue } }
}
