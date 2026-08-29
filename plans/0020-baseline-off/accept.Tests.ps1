#requires -Modules Pester

# Acceptance test for PASS 0020 / run 003 (baseline-off).
# Written from the pass prompt's field list only. plans/0019-* was NOT read:
# it is forbidden under the Phase 1 read-allowlist. See plan.md, Deviations.

BeforeAll {
    $script:RepoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
    $script:RunDir     = Join-Path $script:RepoRoot 'runs/003-baseline-off'
    $script:Readme     = Join-Path $script:RunDir  'README.md'
    $script:GraphJson  = Join-Path $script:RunDir  'graph.json'
    $script:DiffTxt    = Join-Path $script:RunDir  'diff.txt'
    $script:Html       = Join-Path $script:RunDir  '003.html'
    $script:Findings   = Join-Path $script:RunDir  'findings.md'

    $script:ReadmeText = if (Test-Path -LiteralPath $script:Readme) {
        Get-Content -Raw -LiteralPath $script:Readme
    } else { '' }

    $script:BriefSha = '93c5cec3299da0ac27d3aea67f4fbcf0000001ec'
}

Describe 'PASS 0020 run 003 (baseline-off) acceptance' {

    Context 'run record files exist' {
        It 'runs/003-baseline-off/README.md exists' {
            Test-Path -LiteralPath $script:Readme | Should -BeTrue
        }
        It 'graph.json exists' {
            Test-Path -LiteralPath $script:GraphJson | Should -BeTrue
        }
        It 'diff.txt exists' {
            Test-Path -LiteralPath $script:DiffTxt | Should -BeTrue
        }
        It '003.html exists' {
            Test-Path -LiteralPath $script:Html | Should -BeTrue
        }
        It 'findings.md exists' {
            Test-Path -LiteralPath $script:Findings | Should -BeTrue
        }
        It 'graph.json parses as JSON' {
            Test-Path -LiteralPath $script:GraphJson | Should -BeTrue
            { Get-Content -Raw -LiteralPath $script:GraphJson | ConvertFrom-Json } |
                Should -Not -Throw
        }
    }

    Context 'README records the run' {
        It 'records plugin: none (baseline-off)' {
            $script:ReadmeText | Should -Match 'plugin:\s*none\s*\(baseline-off\)'
        }
        It 'records target-sha: as a 40-hex SHA' {
            $script:ReadmeText | Should -Match 'target-sha:\s*[0-9a-f]{40}\b'
        }
        It 'records seed-sha: as a 40-hex SHA' {
            $script:ReadmeText | Should -Match 'seed-sha:\s*[0-9a-f]{40}\b'
        }
        It 'records the pinned brief-sha' {
            $script:ReadmeText | Should -Match ("brief-sha:\s*" + $script:BriefSha)
        }
        It 'records phase-1-minutes: as a number' {
            $script:ReadmeText | Should -Match 'phase-1-minutes:\s*[0-9]+(\.[0-9]+)?\b'
        }
        It 'records a build: line' {
            $script:ReadmeText | Should -Match 'build:\s*\S+'
        }
        It 'records conformance: N / N' {
            $script:ReadmeText | Should -Match 'conformance:\s*[0-9]+\s*/\s*[0-9]+\b'
        }
        It 'records functional: N / 12' {
            $script:ReadmeText | Should -Match 'functional:\s*[0-9]+\s*/\s*12\b'
        }
        It 'records the baseline caveat' {
            $script:ReadmeText | Should -Match 'skills unread'
        }
    }
}
