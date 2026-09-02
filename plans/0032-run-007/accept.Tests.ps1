#Requires -Version 7.2
param([string]$RunDir = "$PSScriptRoot/../../runs/007-baseline-iterated")
Describe 'Run 007 is complete' {
    It 'has a run README' { Test-Path "$RunDir/README.md" | Should -BeTrue }
    BeforeAll { $script:r = Get-Content "$RunDir/README.md" -Raw -ErrorAction SilentlyContinue }
    It 'records the unread plugin surface' { $r | Should -Match 'plugin-surface:\s*v1\.0\.0 \(present but UNREAD' }
    It 'records the pinned model version' { $r | Should -Match 'model-version:\s*claude-opus-5\[1m\]' }
    It 'records a fourth distinct session identifier' {
        $r | Should -Match 'session-identifier:\s*\S+'
        foreach ($id in 'b0a48c69-0c6c-4c8e-8d6c-2998ea9f76db',
                        'cc4d301c-ed6d-476f-90d9-63b324a62658',
                        'f0302223-28f1-436d-85f3-04e168c8534c') {
            $r | Should -Not -Match $id } }
    It 'records seed, brief, target' { $r | Should -Match 'seed-sha:'; $r | Should -Match 'brief-sha:\s*93c5cec'; $r | Should -Match 'target-sha:\s*[0-9a-f]{40}' }
    It 'records phase wall-clock' { $r | Should -Match 'phase-1-minutes:\s*\d+' }
    It 'states build' { $r | Should -Match 'build:\s*(exit \d+|no build script)' }
    It 'states conformance on the stable denominator' { $r | Should -Match 'conformance:\s*\d+\s*/\s*33 \(cases-defined\)'; $r | Should -Match 'cases-run:\s*\d+' }
    It 'states first-shot and final functional lines' { $r | Should -Match 'functional \(first-shot\):\s*\d+\s*/\s*12'; $r | Should -Match 'functional \(final\):\s*\d+\s*/\s*12' }
    It 'has the control comparison section' { $r | Should -Match '(?m)^## Control comparison' }
    It 'has graph, diff, html, findings' {
        foreach ($f in 'graph.json','diff.txt','007.html','findings.md') {
            Test-Path "$RunDir/$f" | Should -BeTrue } }
}
