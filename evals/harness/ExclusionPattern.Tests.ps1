#Requires -Version 7.2
<#
    Tests of the HARNESS, not of any target.

    These grade the path-exclusion regex that the conformance runner and the
    conformance suite each use to keep build output, scratch trees, vendored
    galleries and fixtures out of manifest discovery. There are four copies of
    that regex and pass 0045 found that one of them had been wrong since it was
    written: Invoke-Conformance.ps1 spelled the character class '[\/]', which
    inside a class is an escaped forward slash and nothing else, so it never
    matched a Windows path - and every path it is applied to is a Windows path,
    built by .Substring() on a FileInfo.FullName.

    Two things are asserted, and they are different claims.

    POLARITY - the pattern actually excludes what it names, on a Windows path
    as well as a POSIX one, and does NOT exclude a legitimate src/-side
    manifest, a manifest at the target root, or a directory whose name merely
    begins or ends with an excluded word. A pattern that excluded everything
    would pass the first half on its own.

    COPIES AGREE - all four copies are one identical string. This is the check
    whose absence let the drift happen. A one-character fix with no test is how
    the divergence arose; this fails loudly the next time any copy is edited
    alone.

    WHERE THIS FILE LIVES, AND WHY IT IS NOT IN evals/conformance/.
    Invoke-Conformance.ps1 inventories every *.Tests.ps1 in ITS OWN directory -
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter *.Tests.ps1 -File, with no
    -Recurse - and the count of It statements it finds there is CasesDefined,
    the denominator every conformance score is reported against. A file placed
    beside the suite would move that denominator and make this pass's scores
    incomparable with every score before it. Placement is the guard.

    The -Tag 'Harness' below is a second, independent backstop: 'Harness' is
    not in Invoke-Conformance.ps1's -Tag ValidateSet, so even a copy of this
    file that somehow reached the inventoried directory would contribute to no
    selected tag. Placement is the guard; the tag is the belt.

    Run with evals/harness/Invoke-HarnessTests.ps1.

    HARNESS_CONFORMANCE_DIR overrides which conformance directory is graded, so
    that a falsification probe can point these tests at a scratch copy with one
    site deliberately broken. Nothing here writes anything.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot 'ExclusionSites.ps1')

    $dir = $env:HARNESS_CONFORMANCE_DIR
    if (-not $dir) { $dir = Join-Path $PSScriptRoot '../conformance' }
    if (-not (Test-Path -LiteralPath $dir)) { throw "Conformance directory not found: $dir" }

    $sites = @(Get-ExclusionSite -ConformanceDir $dir)

    # The segments the exclusion names, read out of the first site's alternation
    # rather than retyped, so a seventh segment is graded automatically.
    $segments = @()
    if ($sites.Count -gt 0) { $segments = @(Get-ExclusionSegment -Pattern $sites[0].Pattern) }

    # The cross product these tests grade. Built here so a run with zero sites
    # or zero segments produces an EMPTY -ForEach - and Invoke-HarnessTests.ps1
    # leaves FailOnNullOrEmptyForEach at its default ON, so empty is a failure
    # and not a pass. Zero cases is not a pass.
    $siteSegments = @(
        foreach ($site in $sites) {
            foreach ($segment in $segments) {
                @{ Site = $site.Site; Pattern = $site.Pattern; Segment = $segment }
            }
        }
    )

    # Scope controls: directory names that CONTAIN an excluded word without
    # being one. A pattern that dropped its separators - the bare alternation
    # (output|scratch|...) with no character classes at all - would pass every
    # exclusion case above and fail every one of these.
    $nearMisses = @(
        @{ Name = 'outputs' }              # excluded word, then more
        @{ Name = 'scratchpad' }
        @{ Name = 'galleries' }
        @{ Name = 'myoutput' }             # more, then excluded word
        @{ Name = 'node_modules_backup' }
    )
}

BeforeAll {
    # The same extraction again, in RUN scope. Pester 6 does not carry a
    # BeforeDiscovery variable into an It body, and the alternative to calling
    # the extractor twice is writing it twice.
    . (Join-Path $PSScriptRoot 'ExclusionSites.ps1')

    $dir = $env:HARNESS_CONFORMANCE_DIR
    if (-not $dir) { $dir = Join-Path $PSScriptRoot '../conformance' }
    $script:Sites = @(Get-ExclusionSite -ConformanceDir $dir)
    $script:GradedDir = (Resolve-Path -LiteralPath $dir).Path
}

Describe 'Path exclusion polarity' -Tag 'Harness' {

    Context 'the pattern excludes what it names' {

        It '<Site> excludes a Windows-style path under <Segment>' -ForEach $siteSegments {
            "\$Segment\Thing\Thing.psd1" | Should -Match $Pattern -Because (
                'every path this pattern is applied to is a Windows path - it is built by ' +
                '.Substring() on a FileInfo.FullName - so a class that cannot see a backslash ' +
                "excludes nothing. '[\/]' is an escaped forward slash and NOTHING ELSE; the " +
                "correct class is '[\\/]'. LEDGER backlog 62.")
        }

        It '<Site> excludes a forward-slash path under <Segment>' -ForEach $siteSegments {
            "/$Segment/Thing/Thing.psd1" | Should -Match $Pattern -Because (
                'a target cloned or unpacked on a POSIX host yields forward slashes, and the ' +
                'exclusion has to hold for both')
        }

        It '<Site> excludes a nested path under <Segment>' -ForEach $siteSegments {
            # The real shape: the excluded segment is not always at the front.
            # output/ sits at the repository root; fixtures/ and node_modules/
            # do not.
            "\src\Thing\$Segment\Thing\Thing.psd1" | Should -Match $Pattern
        }
    }

    Context 'the pattern does not exclude what it does not name' {

        # The substitution controls. Without these, a pattern that matched
        # everything - or a check that never fired - would look identical to a
        # correct one.

        It '<Site> does not exclude a legitimate src/-side manifest (Windows)' -ForEach $sites {
            '\src\PSGraphRender\PSGraphRender.psd1' | Should -Not -Match $Pattern -Because (
                'the module under test lives under src/, and a pattern that excluded it would ' +
                'leave the suite with nothing to grade')
        }

        It '<Site> does not exclude a legitimate src/-side manifest (forward slash)' -ForEach $sites {
            '/src/PSGraphRender/PSGraphRender.psd1' | Should -Not -Match $Pattern
        }

        It '<Site> does not exclude a manifest at the target root' -ForEach $sites {
            '\PSGraphRender.psd1' | Should -Not -Match $Pattern -Because (
                "the suite's second resolution rule prefers a manifest sitting directly in the " +
                'target, so excluding one would disable that rule')
        }
    }

    Context 'the pattern matches whole path segments, not substrings' {

        It 'no site excludes a directory merely named <Name>' -ForEach $nearMisses {
            foreach ($site in $script:Sites) {
                "\src\$Name\Thing\Thing.psd1" | Should -Not -Match $site.Pattern -Because (
                    "'$Name' is not one of the excluded segments, and $($site.Site) says it is. " +
                    'The separators in the character classes are what make this a segment match ' +
                    'rather than a substring match')
            }
        }
    }
}

Describe 'Path exclusion copies agree' -Tag 'Harness' {

    # The check whose absence let the drift happen. Four copies of one regex
    # existed and one of them was wrong the whole time, because nothing
    # compared them.

    It 'finds the exclusion literal in at least three files' {
        $files = @($script:Sites | ForEach-Object { $_.File } | Sort-Object -Unique)
        $files.Count | Should -BeGreaterOrEqual 3 -Because (
            'an extraction that found nothing would make every comparison below vacuous and ' +
            "would report that as a pass. Graded $script:GradedDir; found: $($files -join ', ')")
    }

    It 'finds at least four copies of the exclusion literal' {
        $script:Sites.Count | Should -BeGreaterOrEqual 4 -Because (
            'there are four known sites: Invoke-Conformance.ps1 once, Conformance.Tests.ps1 ' +
            'twice, Help.Tests.ps1 once. Fewer means the extraction stopped seeing one, which ' +
            "is a silent loss of coverage. Found: $(@($script:Sites | ForEach-Object { $_.Site }) -join ', ')")
    }

    It 'every known site is present with its known count' {
        # A floor per file, not an equality: a fifth CORRECT copy added later is
        # not a defect and must not fail this. A copy that goes missing is.
        $counts = @{}
        foreach ($site in $script:Sites) {
            if (-not $counts.ContainsKey($site.File)) { $counts[$site.File] = 0 }
            $counts[$site.File]++
        }

        foreach ($expected in @(
                @{ File = 'Invoke-Conformance.ps1'; Min = 1 }
                @{ File = 'Conformance.Tests.ps1'; Min = 2 }
                @{ File = 'Help.Tests.ps1'; Min = 1 }
            )) {
            $counts.ContainsKey($expected.File) | Should -BeTrue -Because (
                "$($expected.File) is a known site of the exclusion regex and none was found in it")
            $counts[$expected.File] | Should -BeGreaterOrEqual $expected.Min -Because (
                "$($expected.File) carries at least $($expected.Min) copy or copies of it")
        }
    }

    It 'all copies are one identical string' {
        $distinct = @($script:Sites | ForEach-Object { $_.Pattern } | Sort-Object -Unique)
        $detail = @($script:Sites | ForEach-Object { "$($_.Site) = $($_.Pattern)" }) -join ' | '
        $distinct.Count | Should -Be 1 -Because (
            'four copies of one regex drifted here once already and nothing noticed. ' +
            "Sites: $detail")
    }
}
