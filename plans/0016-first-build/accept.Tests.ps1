#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")

Describe 'Pass 0016 delivered' {
    It 'has at least four skills' {
        (Get-ChildItem "$RepoRoot/skills" -Recurse -Filter SKILL.md -ErrorAction SilentlyContinue).Count |
            Should -BeGreaterOrEqual 4
    }
    It 'has build and test commands' {
        Test-Path "$RepoRoot/commands/build.md" | Should -BeTrue
        Test-Path "$RepoRoot/commands/test.md"  | Should -BeTrue
    }
    It 'has a real root README' {
        (Get-Content "$RepoRoot/README.md" -Raw).Length | Should -BeGreaterThan 3000
    }
    It 'has the run record' {
        foreach ($f in 'README.md','graph.json','diff.txt','002.html','findings.md','DEMO.md') {
            Test-Path "$RepoRoot/runs/002-first-build/$f" | Should -BeTrue
        }
    }
    It 'states all three scores' {
        $r = Get-Content "$RepoRoot/runs/002-first-build/README.md" -Raw
        $r | Should -Match 'build:\s*(exit \d+|no build script)'
        $r | Should -Match 'conformance:\s*\d+\s*/\s*\d+'
        $r | Should -Match 'functional:\s*\d+\s*/\s*12'
    }
    It 'records what this run is not' {
        Get-Content "$RepoRoot/runs/002-first-build/README.md" -Raw |
            Should -Match 'not a zero-skill baseline'
    }
    It 'records the target SHA' {
        Get-Content "$RepoRoot/runs/002-first-build/README.md" -Raw |
            Should -Match 'target-sha:\s*[0-9a-f]{40}'
    }
}
