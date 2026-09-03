#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..",
      [string]$Sib = "$PSScriptRoot/../../..")
Describe 'Pass 0038 delivered' {
    It 'target README carries the full measurement story' {
        $r = Get-Content "$Sib/PSAzureDevOpsGraph/README.md" -Raw
        $r | Should -Match 'run 00[4-6]'
        $r | Should -Match '007'
        $r | Should -Match 'shape, not correctness' }
    It 'target has a handoff and worklog' {
        Test-Path "$Sib/PSAzureDevOpsGraph/docs/HANDOFF.md" | Should -BeTrue
        Test-Path "$Sib/PSAzureDevOpsGraph/docs/worklog/v0.3.0.md" | Should -BeTrue }
    It 'v0.3.0 on the target remote' {
        (git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git 'v0.3.0*') |
            Should -Not -BeNullOrEmpty }
    It 'TF README and HANDOFF know tf-003' {
        (Get-Content "$Sib/PSTerraformGraph/README.md" -Raw)        | Should -Match 'tf-003'
        (Get-Content "$Sib/PSTerraformGraph/docs/HANDOFF.md" -Raw)  | Should -Match 'tf-003'
        (Get-Content "$Sib/PSTerraformGraph/docs/HANDOFF.md" -Raw)  | Should -Not -Match 'Nothing here has met' }
    It 'ToHtml consumer line is current' {
        (Get-Content "$Sib/PSGraphRenderToHtml/README.md" -Raw) | Should -Match 'tf-00[23]' }
    It 'PSGraphRender cites the current producer version' {
        (Get-Content "$Sib/PSGraphRender/README.md" -Raw) | Should -Match 'PSTerraformGraph.*v0\.2\.0' }
    It 'harness LEDGER records the sync' {
        (Get-Content "$RepoRoot/LEDGER.md" -Raw) | Should -Match '0038' }
}
