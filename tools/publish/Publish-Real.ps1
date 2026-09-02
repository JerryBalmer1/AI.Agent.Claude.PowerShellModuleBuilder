#Requires -Version 7.2
<#
.SYNOPSIS
    Guard in front of public publication. Refuses while this repository has no
    committed .claude-plugin/marketplace.json; prints the operator's checklist
    once it has one. Publishes nothing either way.

.DESCRIPTION
    Publishing is the operator's verb. METHOD.md: "Nothing publishes. No release,
    no tag, no push to the default branch, unless the operator does it from their
    own shell." This script therefore has no push path at all - not a guarded one,
    not a -Force one. Adding one would make the rule a matter of restraint rather
    than of code, and this project's whole argument is that those are different.

    The guard is red until pass 0030 lands the committed marketplace.json.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
)

$ErrorActionPreference = 'Stop'

$RepoRoot   = (Resolve-Path $RepoRoot).Path
$marketFile = Join-Path $RepoRoot '.claude-plugin/marketplace.json'
$pluginFile = Join-Path $RepoRoot '.claude-plugin/plugin.json'

if (-not (Test-Path -LiteralPath $marketFile)) {
    Write-Host 'GUARD: refused.'
    Write-Host ''
    Write-Host "  Looked for : $marketFile"
    Write-Host '  Found      : nothing.'
    Write-Host ''
    Write-Host 'Why this is a refusal and not an error:'
    Write-Host ''
    Write-Host '  A Claude Code marketplace is discovered by a marketplace.json'
    Write-Host '  committed at the repository root. This repository has plugin.json'
    Write-Host '  and no marketplace.json, so there is nothing for anyone to add.'
    Write-Host '  Generating one here would publish a file that no pass has'
    Write-Host '  falsified and that no cold install has ever been proved against.'
    Write-Host ''
    Write-Host 'What pass 0030 adds, and what makes this go green:'
    Write-Host ''
    Write-Host '  1. .claude-plugin/marketplace.json, committed, with the owner and'
    Write-Host '     the plugin entry pointing at this repository.'
    Write-Host '  2. A re-version of the psmodule manifest away from 0.1.0'
    Write-Host '     (LEDGER.md, Versions: v1.0.0 is reserved for "passed the ladder").'
    Write-Host '  3. A cold-install proof: install from the published marketplace on a'
    Write-Host '     machine that has never seen this repository, and record it.'
    Write-Host ''
    Write-Host 'Until then, use the local path:  Invoke-Build PublishLocal'
    Write-Host 'See docs/creating-an-agent/09-try-before-you-trust.md.'
    exit 1
}

# --- The committed marketplace exists: print the checklist, publish nothing ---
$plugin = Get-Content -LiteralPath $pluginFile -Raw | ConvertFrom-Json
$market = Get-Content -LiteralPath $marketFile -Raw | ConvertFrom-Json

Write-Host 'GUARD: passed. A committed marketplace.json is present.'
Write-Host ''
Write-Host "  marketplace : $($market.name)"
Write-Host "  plugin      : $($plugin.name) $($plugin.version)"
Write-Host "  repository  : $($plugin.repository)"
Write-Host ''
Write-Host 'This script still publishes nothing. Publishing is the operator''s verb,'
Write-Host 'run from the operator''s own shell, on purpose. The checklist:'
Write-Host ''
Write-Host '  1. Confirm the tree is clean and the pass is green.'
Write-Host '       git status --porcelain          # expect no output'
Write-Host ''
Write-Host '  2. Confirm the version in plugin.json is the one you mean to ship.'
Write-Host "       current: $($plugin.version)"
Write-Host ''
Write-Host '  3. Commit and push to the default branch, by fast-forward only.'
Write-Host '       git push origin main'
Write-Host ''
Write-Host "  4. Tag the release and push the tag."
Write-Host "       git tag -a v$($plugin.version) -m 'psmodule v$($plugin.version)'"
Write-Host "       git push origin v$($plugin.version)"
Write-Host ''
Write-Host '  5. Anyone installing then pastes these inside Claude Code:'
$slug = ($plugin.repository -replace '^https://github\.com/', '' -replace '\.git$', '')
Write-Host "       /plugin marketplace add $slug"
Write-Host "       /plugin install $($plugin.name)@$($market.name)"
Write-Host ''
Write-Host '  6. Prove it cold: install on a machine that has never cloned this'
Write-Host '     repository, run /psmodule:build on a scratch module, and record'
Write-Host '     the transcript. An install nobody has done from outside is a claim.'
Write-Host ''
Write-Host 'No push was made by this script.'
exit 0
