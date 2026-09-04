#Requires -Version 7.0
<#
    Where the path-exclusion regex lives, and what each copy says.

    Dot-sourced by ExclusionPattern.Tests.ps1 from BOTH BeforeDiscovery and
    BeforeAll, and by any falsification probe. Pester 6 keeps discovery scope
    and run scope apart - a variable set in BeforeDiscovery is not there when an
    It body executes - so the extraction has to be callable twice. One
    implementation called from two scopes; not two implementations, which is the
    shape this whole directory exists to prevent.

    Nothing here writes anything, and nothing here knows which spelling is
    correct. It finds the copies and reports them; the tests decide.
#>

function Get-ExclusionSite {
    <#
    .SYNOPSIS
        Every copy of the path-exclusion regex in a conformance directory.
    .DESCRIPTION
        Sites are DISCOVERED, not listed. A fifth copy added later is graded
        the day it appears; a hard-coded list of three filenames would have to
        be remembered, and remembering is what failed here the first time -
        Invoke-Conformance.ps1 carried '[\/]' where the other three carried
        '[\\/]' for eleven passes.

        The literal is found by its CONTENT - a single-quoted string containing
        the alternation - and not by its character class, so a copy that has
        drifted in the class is found and then compared, rather than filtered
        out by the search and reported as absent. A search that can only find
        correct copies would report a drifted one as no copy at all.

        Returns a hashtable per site: File, Line, Site ("File:Line"), Pattern.
        Hashtables rather than objects because Pester's -ForEach binds named
        variables from hashtable keys and only $_ from anything else.
    .PARAMETER ConformanceDir
        The directory to search. Every *.ps1 in it, non-recursive.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $ConformanceDir)

    $resolved = (Resolve-Path -LiteralPath $ConformanceDir).Path
    @(Get-ChildItem -LiteralPath $resolved -Filter *.ps1 -File |
        Sort-Object Name |
        ForEach-Object {
            $name = $_.Name
            $text = Get-Content -LiteralPath $_.FullName -Raw
            foreach ($m in [regex]::Matches($text, "'[^']*output\|scratch[^']*'")) {
                $line = ($text.Substring(0, $m.Index) -split "`n").Count
                @{
                    File    = $name
                    Line    = $line
                    Site    = "${name}:$line"
                    Pattern = $m.Value.Trim("'")
                }
            }
        })
}

function Get-ExclusionSegment {
    <#
    .SYNOPSIS
        The directory names one exclusion pattern names, read out of it.
    .DESCRIPTION
        Read from the alternation rather than retyped, so that a seventh
        segment added to the pattern is graded automatically instead of being
        silently ungraded. Backslash escapes are stripped: the pattern spells
        the git directory '\.git' and the segment is '.git'.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Pattern)

    $alternation = [regex]::Match($Pattern, '\(([^)]*)\)')
    if (-not $alternation.Success) { return @() }
    @($alternation.Groups[1].Value -split '\|' | ForEach-Object { $_ -replace '\\', '' })
}
