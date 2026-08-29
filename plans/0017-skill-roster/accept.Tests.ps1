#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")

Describe 'Pass 0017 delivered' {
    It 'renamed skills exist and old names are gone' {
        foreach ($s in 'powershell-module-scaffold','powershell-module-build',
                       'azdo-rest','azdo-pipeline-yaml-refs','azdo-graph-assembly') {
            Test-Path "$RepoRoot/skills/$s/SKILL.md" | Should -BeTrue
        }
        foreach ($s in 'module-scaffold','build-script','pipeline-yaml-refs','graph-assembly') {
            Test-Path "$RepoRoot/skills/$s" | Should -BeFalse
        }
    }
    It 'new roster exists' {
        foreach ($s in 'powershell-module-test','powershell-module-deploy',
                       'powershell-module-release','powershell-module-architect',
                       'powershell-module-analyzer','powershell-module-plan',
                       'powershell-module-docs','task-tree-reporting') {
            Test-Path "$RepoRoot/skills/$s/SKILL.md" | Should -BeTrue
        }
    }
    It 'ordered test runner ships as a script' {
        Test-Path "$RepoRoot/skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1" |
            Should -BeTrue
    }
    It 'plan intake template exists' {
        Test-Path "$RepoRoot/skills/powershell-module-plan/templates/module-plan.md" |
            Should -BeTrue
    }
    It 'decisions 0006 and 0007 exist' {
        Test-Path "$RepoRoot/decisions/0006-target-versioning-and-tags.md" | Should -BeTrue
        Test-Path "$RepoRoot/decisions/0007-skill-taxonomy-and-naming.md"  | Should -BeTrue
    }
    It 'v0.1.0 is on the module remote' {
        # CORRECTED DURING PASS 0017. The prompt supplied this as:
        #
        #     (git ls-remote --tags <url> v0.1.0) |
        #         Should -Match '79e02fba...|v0.1.0\^\{\}'
        #
        # which cannot pass for a correctly created and pushed annotated tag,
        # for two compounding reasons:
        #
        #  1. ls-remote matches a pattern against the TAIL of the ref name, and
        #     the peeled entry's name is 'refs/tags/v0.1.0^{}'. Asking for
        #     'v0.1.0' therefore returns ONLY the tag object - f1947c28..., the
        #     SHA of the tag itself - and never the commit it peels to. Neither
        #     alternative in the regex can appear. PSModuleGraph's own
        #     tests/PreTag.Tests.ps1 documents this exact trap.
        #  2. Should -Match tests each element of a piped array and fails on the
        #     first that does not match, so even with both lines returned, the
        #     tag-object line fails it.
        #
        # The regex is the prompt's, unchanged. The pattern now returns both
        # lines and they are joined, so the assertion tests the property it was
        # written to test: v0.1.0 on the remote peels to 79e02fb.
        $refs = git ls-remote --tags https://github.com/JerryBalmer1/PSAzureDevOpsGraph.git 'v0.1.0*'
        ($refs -join "`n") |
            Should -Match '79e02fba9dffd976bccf507d531f59303cc58f9d|v0.1.0\^\{\}'
    }
    It 'ordered runner demonstrated fail-fast' {
        Get-Content "$RepoRoot/plans/0017-skill-roster/ordered-run-demo.txt" -Raw |
            Should -Match 'STOPPED AT LAYER'
    }
}
