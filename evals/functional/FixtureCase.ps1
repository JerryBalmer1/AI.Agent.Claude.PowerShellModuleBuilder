<#
    Reads the case declarations out of fixture/cases.md.

    This lives in its own file, dot-sourced by Fixture.Tests.ps1 from both
    BeforeDiscovery and BeforeAll, because the declarations are needed at
    discovery to build the -ForEach lists and again at run time.

    It is NOT in the test file itself. A `function` defined at the top level of
    a Pester 6.1.0 test file makes every BeforeAll in that file fail — with
    "A 'break' or 'continue' statement with a label that does not match any
    enclosing loop escaped from your code", which names loop labels and says
    nothing about functions. Reduced to the smallest case: a file containing
    only `function Probe-It { 'hello' }` and a Describe whose BeforeAll runs
    `Get-Command Probe-It -ErrorAction SilentlyContinue` fails the same way.
    Dot-sourcing the identical function from another file works.

    A case declaration is anchored on its level-2 heading. A case id mentioned
    in prose is not a declaration; that is what stops cases.md documenting a
    case into existence without the graph agreeing.
#>

function Get-FixtureCaseDeclaration {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }

    # Line endings are normalised before anything is matched. Every pattern
    # below is multiline-anchored, and `$` in .NET multiline mode matches
    # before the \n but AFTER the \r, so `**kind:** presence\r\n` fails a
    # pattern ending `[ \t]*$`.
    #
    # This is not hypothetical. This repository has core.autocrlf=true and no
    # .gitattributes, so cases.md arrives CRLF in any fresh clone on Windows.
    # Measured before the fix: 12 of 12 declarations carried a kind reading the
    # working copy, 0 of 12 reading a CRLF copy of the same bytes. The whole of
    # assertion 7 would have failed for the next person to clone, and passed
    # here.
    $text = (Get-Content -LiteralPath $Path -Raw) -replace "`r`n", "`n"

    $headings = [regex]::Matches($text, '(?m)^##[ \t]+(case-\d{2})\b')
    for ($i = 0; $i -lt $headings.Count; $i++) {
        $start = $headings[$i].Index
        $end = if ($i + 1 -lt $headings.Count) { $headings[$i + 1].Index } else { $text.Length }
        $section = $text.Substring($start, $end - $start)

        $kinds = [regex]::Matches($section, '(?m)^\*\*kind:\*\*[ \t]+(presence|absence)[ \t]*$')
        $checkedBy = [regex]::Match($section, '(?m)^\*\*checked by:\*\*[ \t]+(\S.*?)[ \t]*$')

        # The whole checked-by paragraph, not just its first line, collapsed to
        # single spaces.
        #
        # A quoted test name is prose and prose is hard-wrapped, so the name
        # routinely straddles a line break: `"no node is the pre-existing\n
        # ClaudeTesting repository"`. A single-line match sees only the first
        # half and would report a truncated name as unresolvable, or - worse -
        # a short truncation that happens to match something else as resolved.
        # Collapse first, match second.
        $blockMatch = [regex]::Match($section, '(?ms)^\*\*checked by:\*\*[ \t]+(.*?)(?:\r?\n[ \t]*\r?\n|\z)')
        $block = $null
        if ($blockMatch.Success) {
            $block = ($blockMatch.Groups[1].Value -replace '\s+', ' ').Trim()
        }

        # Test names quoted inside that block, as written.
        $quoted = @()
        if ($block) {
            $quoted = @([regex]::Matches($block, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
        }

        # Suites the block names, in backticks, e.g. `Fixture.Tests.ps1`.
        $suites = @()
        if ($block) {
            $suites = @([regex]::Matches($block, '`([A-Za-z0-9._-]+\.Tests\.ps1)`') |
                ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
        }

        [pscustomobject]@{
            Id              = $headings[$i].Groups[1].Value
            KindCount       = $kinds.Count
            Kind            = $(if ($kinds.Count -eq 1) { $kinds[0].Groups[1].Value } else { $null })
            CheckedBy       = $(if ($checkedBy.Success) { $checkedBy.Groups[1].Value } else { $null })
            CheckedByBlock  = $block
            QuotedTestNames = $quoted
            NamedSuites     = $suites
        }
    }
}

function Get-PesterTestName {
    <#
        Every test name declared by `It` in a Pester file, read from the
        PowerShell AST rather than by regex.

        The AST is used because a regex over test files has to guess at quoting,
        escaping and continuation, and a name it fails to extract becomes a name
        the caller reports as missing. A pointer check whose failure mode is a
        false alarm gets switched off, and then it checks nothing.
    #>
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return }

    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path -LiteralPath $Path).ProviderPath, [ref]$tokens, [ref]$errors)

    $its = $ast.FindAll({
        param($n)
        $n -is [System.Management.Automation.Language.CommandAst] -and
        $n.GetCommandName() -eq 'It'
    }, $true)

    foreach ($it in $its) {
        if ($it.CommandElements.Count -lt 2) { continue }
        $name = $it.CommandElements[1]
        if ($name -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
            $name -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
            $name.Value
        }
    }
}
