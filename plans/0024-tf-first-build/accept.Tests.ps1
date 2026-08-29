#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..",
      [string]$T = "$PSScriptRoot/../../../PSTerraformGraph")
Describe 'Pass 0024 delivered' {
    It 'module builds and exports the surface' {
        $m = Import-Module "$T/src/PSTerraformGraph/PSTerraformGraph.psd1" -Force -PassThru
        $m.ExportedCommands.Keys | Should -Contain 'Get-TfConfigurationGraph'
        $m.ExportedCommands.Keys | Should -Contain 'Export-TfConfigurationGraphHtml'
    }
    It 'run record complete' {
        $r = Get-Content "$RepoRoot/runs/tf-001-first-build/README.md" -Raw
        $r | Should -Match 'plugin-sha:\s*[0-9a-f]{40}'
        $r | Should -Match 'build:\s*exit \d+'
        $r | Should -Match 'functional-tf:\s*\d+\s*/\s*\d+'
        $r | Should -Match 'not the generalisation measurement'
    }
    It 'graph artifacts exist' {
        Test-Path "$RepoRoot/runs/tf-001-first-build/graph.json" | Should -BeTrue
        (Get-ChildItem "$RepoRoot/runs/tf-001-first-build" -Filter *.html).Count |
            Should -BeGreaterOrEqual 3
    }
    It 'v0.1.0 on the remote' {
        (git ls-remote --tags https://github.com/JerryBalmer1/PSTerraformGraph.git 'v0.1.0*') |
            Should -Not -BeNullOrEmpty
    }
}
