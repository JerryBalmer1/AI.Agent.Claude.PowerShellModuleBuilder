#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0033 delivered' {
    It 'README carries the controlled claim' {
        $r = Get-Content "$RepoRoot/README.md" -Raw
        $r | Should -Match 'buys shape, not correctness'
        $r | Should -Match '19\s*/\s*33'
        $r | Should -Match 'single control' }
    It 'README no longer overstates functional' {
        (Get-Content "$RepoRoot/README.md" -Raw) |
            Should -Match 'control.+first shot.+closest' }
    It 'rescore evidence exists with both protocols' {
        $t = Get-Content "$RepoRoot/plans/0033-honest-headline/rescore.txt" -Raw
        $t | Should -Match 'run 007 final \(corrected\):\s*\d+\s*/\s*33'
        $t | Should -Match 'run 006 final \(corrected\):\s*\d+\s*/\s*33'
        $t | Should -Match 'LADDER MECHANISM: (explained|unexplained)' }
    It 'HARNESS gains the two hazards' {
        $h = Get-Content "$RepoRoot/evals/HARNESS.md" -Raw
        $h | Should -Match 'prompt-borne oracle content'
        $h | Should -Match 'case-annotated comments' }
    It 'affected run records carry the caveat' {
        foreach ($n in '003-baseline-off','004-plugin-on','005-plugin-on',
                       '006-plugin-on','007-baseline-iterated') {
            (Get-Content "$RepoRoot/runs/$n/README.md" -Raw) |
                Should -Match '(?m)^## Blindness caveats' } }
    It 'TF fixture inspected for the same vector' {
        (Get-Content "$RepoRoot/plans/0033-honest-headline/tf-fixture-comments.txt" -Raw) |
            Should -Match 'TF FIXTURE CASE-COMMENT SCAN: (clean|findings listed)' }
    It 'CHANGELOG has a user-facing 1.0.1 entry' {
        (Get-Content "$RepoRoot/CHANGELOG.md" -Raw) | Should -Match '(?m)^## 1\.0\.1' }
    It 'manifest is 1.0.1' {
        (Get-Content "$RepoRoot/.claude-plugin/plugin.json" -Raw | ConvertFrom-Json).version |
            Should -Be '1.0.1' }
    It 'v1.0.1 on the remote' {
        (git ls-remote --tags origin 'v1.0.1*') | Should -Not -BeNullOrEmpty }
    It 'docs maintained in the same pass (item 19)' {
        (Get-Content "$RepoRoot/docs/creating-an-agent/04-fresh-sessions-and-contamination.md" -Raw) |
            Should -Match 'prompt itself' }
}
