#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")

Describe 'Pass 0029 — the final README and its folds' {

    BeforeAll {
        $script:Readme = Get-Content "$RepoRoot/README.md" -Raw -ErrorAction SilentlyContinue
        $script:Method = Get-Content "$RepoRoot/method/METHOD.md" -Raw -ErrorAction SilentlyContinue
        $script:Harness = Get-Content "$RepoRoot/evals/HARNESS.md" -Raw -ErrorAction SilentlyContinue
        $script:Ledger = Get-Content "$RepoRoot/LEDGER.md" -Raw -ErrorAction SilentlyContinue

        # Whitespace-collapsed copies for assertions about PROSE. A sentence in
        # a wrapped document spans a line break, and a regex written as one line
        # then reports a phrase that is demonstrably present as absent. That is
        # hazard 8 in evals/HARNESS.md, and the prescribed protection is to
        # collapse whitespace before matching rather than to reflow the prose to
        # suit the check.
        $script:MethodFlat = ($script:Method -replace '\s+', ' ')
        $script:HarnessFlat = ($script:Harness -replace '\s+', ' ')
    }

    Context 'README — the with/without table' {
        It 'has a with/without section' { $Readme | Should -Match '(?m)^## .*[Ww]ith(out)? the plugin' }
        It 'names the baseline run and all three plugin runs' {
            foreach ($r in '003-baseline-off', '004-plugin-on', '005-plugin-on', '006-plugin-on') {
                $Readme | Should -Match ([regex]::Escape($r))
            }
        }
        It 'scores conformance on the stable denominator' { $Readme | Should -Match 'cases-defined' }
        It 'prints the baseline conformance number' { $Readme | Should -Match '19\s*/\s*33' }
        It 'prints the plugin-on conformance number' { $Readme | Should -Match '33\s*/\s*33' }
        It 'separates first-shot from final' {
            $Readme | Should -Match '(?i)first[- ]shot'
            $Readme | Should -Match '(?i)final'
        }
        It 'prints the ugly number: first-shot functional is 1/12 with the plugin' { $Readme | Should -Match '1\s*/\s*12' }
        It 'says the baseline was never allowed a final score' { $Readme | Should -Match '(?i)no fixes, no re-runs|not permitted|never permitted|forbade' }
    }

    Context 'README — variance, cost, findings' {
        It 'states that 004 and 005 were identical difference-for-difference' { $Readme | Should -Match '(?i)difference[- ]for[- ]difference' }
        It 'explains F-5' { $Readme | Should -Match 'F-5' }
        It 'states the wall-clock cost of a run' { $Readme | Should -Match '(?i)wall.clock|minutes' }
        It 'lists the recurring findings' { $Readme | Should -Match 'F-1\b'; $Readme | Should -Match 'F-2\b' }
    }

    Context 'README — usability' {
        It 'has three paste-able commands' {
            $blocks = [regex]::Matches($Readme, '(?s)```powershell(.*?)```')
            @($blocks).Count | Should -BeGreaterOrEqual 1
            $Readme | Should -Match 'Invoke-Conformance\.ps1'
            $Readme | Should -Match 'Compare-Graph\.ps1'
            $Readme | Should -Match 'Reset-Target\.ps1'
        }
        It 'answers why not just prompt Claude' { $Readme | Should -Match '(?i)why not just (prompt|ask)' }
        It 'states the guardrails' { $Readme | Should -Match 'AZDO_PAT'; $Readme | Should -Match '(?i)read-only' }
        It 'gives tf-001/tf-002 and the ecosystem their own section with links' {
            $Readme | Should -Match '(?m)^## .*[Ee]cosystem'
            $Readme | Should -Match 'tf-001'
            $Readme | Should -Match 'tf-002'
            $Readme | Should -Match 'PSGraphRender'
        }
        It 'cites artifacts rather than asserting numbers bare' { $Readme | Should -Match 'runs/006-plugin-on/' }
    }

    Context 'METHOD.md folds' {
        It 'folds in the declaration-versus-thing rule' {
            $MethodFlat | Should -Match '(?i)an assertion about a declaration is not an assertion about the thing declared'
        }
        It 'folds in per-clone isolation for parallel scoring' {
            $MethodFlat | Should -Match '(?i)parallel scoring jobs must be isolated per clone'
        }
    }

    Context 'HARNESS.md hazards' {
        It 'adds three numbered hazards' {
            $Harness | Should -Match '(?m)^### 9\.'
            $Harness | Should -Match '(?m)^### 10\.'
            $Harness | Should -Match '(?m)^### 11\.'
        }
        It 'names the blind-session gate' { $HarnessFlat | Should -Match '(?i)oracle knowledge in prose|blind builder' }
        It 'names the memory-poisoning vector' { $Harness | Should -Match '(?i)MEMORY\.md|auto-loading' }
        It 'names the commit-subject convention' { $HarnessFlat | Should -Match '(?i)commit subject' }
    }

    Context 'LEDGER' {
        It 'records 0029 landed and 0030 next' {
            $Ledger | Should -Match 'Last landed:\s*0029'
            $Ledger | Should -Match '0030'
        }
    }
}
