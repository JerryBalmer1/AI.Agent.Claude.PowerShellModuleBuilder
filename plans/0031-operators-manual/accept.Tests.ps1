#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..")
Describe 'Pass 0031 delivered' {
    It 'README has the entry points' {
        $r = Get-Content "$RepoRoot/README.md" -Raw
        $r | Should -Match 'Creating a new agent, start here'
        $r | Should -Match 'docs/testing/' }
    It 'the manual exists with every chapter' {
        foreach ($f in '00-start-here','01-the-two-claudes',
                       '02-order-of-operations','03-test-first-or-nothing',
                       '04-fresh-sessions-and-contamination',
                       '05-calling-bullshit-verification',
                       '06-the-pass-protocol','07-failure-catalog',
                       '08-glossary','09-try-before-you-trust',
                       '10-using-as-a-template') {
            Test-Path "$RepoRoot/docs/creating-an-agent/$f.md" | Should -BeTrue } }
    It 'testing docs exist' {
        Test-Path "$RepoRoot/docs/testing/README.md" | Should -BeTrue }
    It 'chapters cite real artifacts' {
        foreach ($f in Get-ChildItem "$RepoRoot/docs/creating-an-agent" -Filter '0*.md') {
            (Get-Content $f.FullName -Raw) |
                Should -Match '\((\.\./)+(plans|runs|decisions|journal|evals|method|LEDGER)' } }
    It 'no dead relative links in either docs tree' {
        $bad = foreach ($f in Get-ChildItem "$RepoRoot/docs/creating-an-agent","$RepoRoot/docs/testing" -Filter *.md) {
            foreach ($m in [regex]::Matches((Get-Content $f.FullName -Raw), '\]\((\.\.?/[^)#]+)')) {
                $p = Join-Path $f.DirectoryName $m.Groups[1].Value
                if (-not (Test-Path $p)) { "$($f.Name): $($m.Groups[1].Value)" } } }
        $bad | Should -BeNullOrEmpty }
    It 'build tasks exist' {
        $b = Get-Content "$RepoRoot/.build.ps1" -Raw
        $b | Should -Match 'task PublishLocal'
        $b | Should -Match 'task PublishReal' }
    It 'PublishLocal stages a marketplace under scratch' {
        Test-Path "$RepoRoot/plans/0031-operators-manual/publishlocal-transcript.txt" | Should -BeTrue }
    It 'PublishReal guard is red until 0030' {
        (Get-Content "$RepoRoot/plans/0031-operators-manual/publishreal-guard.txt" -Raw) |
            Should -Match 'GUARD: refused' }
    It 'template markers are enumerable' {
        (Select-String -Path "$RepoRoot/README.md","$RepoRoot/docs/creating-an-agent/*.md" -Pattern 'TEMPLATE:(remove|replace)' -AllMatches).Count |
            Should -BeGreaterThan 0 }
}
