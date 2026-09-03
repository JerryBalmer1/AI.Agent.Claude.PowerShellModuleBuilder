#Requires -Version 7.2
param([string]$RepoRoot = "$PSScriptRoot/../..",
      [string]$Sib = "$PSScriptRoot/../../..")
Describe 'Pass 0041 delivered' {
    It 'README front door + badges + hero' {
        $r = Get-Content "$RepoRoot/README.md" -Raw
        $r | Should -Match 'How to read this repository.s signals'
        $r | Should -Match 'img\.shields\.io'
        $r | Should -Match 'docs/media/' }
    It 'no untagged code fences remain in the README' {
        ([regex]::Matches((Get-Content "$RepoRoot/README.md" -Raw),
            '(?m)^```\s*$')).Count | Should -Be 0 }
    It 'the Mermaid is layer-colored with a legend line' {
        $r = Get-Content "$RepoRoot/README.md" -Raw
        $r | Should -Match 'classDef'
        $r | Should -Match 'layer colors' }
    It 'skills table rows hyperlink their SKILL.md' {
        (Get-Content "$RepoRoot/README.md" -Raw) |
            Should -Match '\[.?powershell-module-ux.?\]\(skills/powershell-module-ux' }
    It 'link map has descriptions and a layer link' {
        $r = Get-Content "$RepoRoot/README.md" -Raw
        $r | Should -Match 'What it does'
        $r | Should -Match '\(docs/diagram' }
    It 'the legend exists once, canonical, in the kit' {
        $p = Get-Content "$RepoRoot/prompts/README.md" -Raw
        foreach ($m in 'NEW SESSION','SAME SESSION','NOT A PROMPT',
                       'DIRECTOR','PLUGIN','AGENT','ENDS WITH',
                       'one visual channel','STOPPED') {
            $p | Should -Match $m } }
    It 'UX records exist with the required shape' {
        $files = Get-ChildItem "$RepoRoot/docs/ux" -Filter 'UX-*.md'
        $files.Count | Should -BeGreaterOrEqual 6
        foreach ($f in $files) {
            $c = Get-Content $f.FullName -Raw
            foreach ($h in '## Problem','## Why','## What it solves','## Evidence') {
                $c | Should -Match ('(?m)^' + [regex]::Escape($h)) } } }
    It 'kit prompts carry routing + tripwire; template carries trust' {
        foreach ($f in 'first-module','new-feature','release','troubleshoot') {
            $c = Get-Content "$RepoRoot/prompts/$f.md" -Raw
            $c | Should -Match '(NEW SESSION|SAME SESSION)'
            $c | Should -Match 'ENDS WITH:' }
        (Get-Content "$RepoRoot/prompts/project-context-template.md" -Raw) |
            Should -Match 'Untagged suggestions are defects' }
    It 'PLAN-PROTOCOL carries the three sections' {
        $p = Get-Content "$RepoRoot/PLAN-PROTOCOL.md" -Raw
        foreach ($m in 'YOUR NEXT ACTION','STOPPED —','heartbeat',
                       'UX conventions have records') { $p | Should -Match $m } }
    It 'decision 0013 amendment settles LEDGER 49' {
        (Get-Content "$RepoRoot/decisions/0013-harness-release-tagging.md" -Raw) |
            Should -Match 'decision 0009 governs' }
    It 'ToHtml ColorBy fixed and tagged' {
        (git ls-remote --tags https://github.com/JerryBalmer1/PSGraphRenderToHtml.git 'v0.1.1*') |
            Should -Not -BeNullOrEmpty }
    It 'no dead links in touched files' {
        (Get-Content "$RepoRoot/plans/0041-operator-ux/linkcheck.txt" -Raw) |
            Should -Match 'DEAD LINKS: 0' }
}
