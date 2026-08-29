#Requires -Version 7.2
param([string]$Render = "$PSScriptRoot/../../../PSGraphRender",
      [string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0021 delivered' {
    It 'begin tag exists and marks the pre-handoff main' {
        (git -C $Render rev-parse 'handoff-begin-2026-08-29^{}') |
            Should -Be '4a367c6a56957dc8ccf8beeaa1ff39c8b4ba9995'
    }
    It 'workflow machinery is gone' {
        foreach ($p in 'CLAUDE.md','.claude','docs/threads.json',
                       'tools/threads.ps1','tests/Ledger.Tests.ps1',
                       'tests/Instructions.Tests.ps1','knowledge') {
            Test-Path (Join-Path $Render $p) | Should -BeFalse
        }
    }
    It 'knowledge survives as archive' {
        (Get-ChildItem "$Render/docs/ledger-archive" -Filter *.md).Count |
            Should -BeGreaterThan 10
    }
    It 'vendor tooling exists' {
        Test-Path "$Render/tools/Update-Vendor.ps1" | Should -BeTrue
        Test-Path "$Render/docs/vendoring.md"       | Should -BeTrue
    }
    It 'handoff file exists and carries the essentials' {
        $h = Get-Content "$Render/docs/HANDOFF.md" -Raw
        $h | Should -Match 'viewmodel\.schema\.json'
        $h | Should -Match '1\.1\.0'
        $h | Should -Match '(?m)^## Boundaries'
        $h | Should -Match '(?m)^## Open'
    }
    It 'v0.13.0 exists and main follows it' {
        $tag = git -C $Render rev-parse 'v0.13.0^{}' 2>$null
        $tag | Should -Match '^[0-9a-f]{40}$'
        (git -C $Render rev-parse origin/main) | Should -Be $tag
    }
    It 'decision 0010 exists in the harness' {
        Test-Path "$RepoRoot/decisions/0010-ecosystem-repo-governance.md" |
            Should -BeTrue
    }
}
