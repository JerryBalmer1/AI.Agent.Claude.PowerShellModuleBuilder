#Requires -Version 7.2
param([string]$RunDir = "$PSScriptRoot/../../runs/004-plugin-on")
Describe 'Run 004 is complete' {
    It 'has a run README' { Test-Path "$RunDir/README.md" | Should -BeTrue }
    BeforeAll { $script:r = Get-Content "$RunDir/README.md" -Raw -ErrorAction SilentlyContinue }
    It 'records the pinned plugin sha' { $r | Should -Match 'plugin-sha:\s*f25d05d8eb219c9b0009a85d39918214f6b3b681' }
    It 'records the model version'     { $r | Should -Match 'model-version:\s*\S+' }
    It 'records a session identifier'  { $r | Should -Match 'session-identifier:\s*\S+' }
    It 'records seed, brief, target'   { $r | Should -Match 'seed-sha:'; $r | Should -Match 'brief-sha:\s*93c5cec'; $r | Should -Match 'target-sha:\s*[0-9a-f]{40}' }
    It 'records phase wall-clock'      { $r | Should -Match 'phase-1-minutes:\s*\d+' }
    It 'states build'                  { $r | Should -Match 'build:\s*(exit \d+|no build script)' }
    It 'states conformance on the stable denominator' { $r | Should -Match 'conformance:\s*\d+\s*/\s*33 \(cases-defined\)'; $r | Should -Match 'cases-run:\s*\d+' }
    It 'states first-shot and final functional lines' { $r | Should -Match 'functional \(first-shot\):\s*\d+\s*/\s*12'; $r | Should -Match 'functional \(final\):\s*\d+\s*/\s*12' }
    It 'has graph, diff, html, findings' {
        foreach ($f in 'graph.json','diff.txt','004.html','findings.md') {
            Test-Path "$RunDir/$f" | Should -BeTrue } }
}
