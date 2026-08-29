#Requires -Version 7.2
param([string]$T = "$PSScriptRoot/../../../PSGraphRenderToHtml")
Describe 'Pass 0022 delivered' {
    It 'producer contract exists and is versioned' {
        Test-Path "$T/contract/producer-graph.schema.json" | Should -BeTrue
        (Get-Content "$T/contract/producer-graph.schema.json" -Raw) |
            Should -Match '0\.1\.0'
    }
    It 'module builds' {
        Test-Path "$T/build.ps1" | Should -BeTrue
        Test-Path "$T/src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1" | Should -BeTrue
    }
    It 'public surface exists' {
        $m = Import-Module "$T/src/PSGraphRenderToHtml/PSGraphRenderToHtml.psd1" -Force -PassThru
        foreach ($f in 'Test-ProducerGraph','New-GraphRenderOptions',
                       'ConvertTo-GraphRenderViewModel','Export-ProducerGraphHtml') {
            $m.ExportedCommands.Keys | Should -Contain $f
        }
    }
    It 'battery exists for producers' {
        Test-Path "$T/tests/ProducerContract.Battery.ps1" | Should -BeTrue
    }
    It 'handoff and sample exist' {
        Test-Path "$T/docs/HANDOFF.md" | Should -BeTrue
        Test-Path "$T/docs/samples/sample-graph.json" | Should -BeTrue
    }
    It 'v0.1.0 on the remote' {
        (git ls-remote --tags https://github.com/JerryBalmer1/PSGraphRenderToHtml.git 'v0.1.0*') |
            Should -Not -BeNullOrEmpty
    }
}
