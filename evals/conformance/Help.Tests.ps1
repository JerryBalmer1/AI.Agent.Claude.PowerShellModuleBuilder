#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0' }

<#
    Help conformance for PowerShell module repositories.

    A second container beside Conformance.Tests.ps1, run by the same
    Invoke-Conformance.ps1 and counted in the same cases-defined inventory. It
    is a separate FILE rather than another Describe because the help standard is
    a coherent subject with its own discovery, and because a file that can be
    pointed at on its own is easier to falsify.

    TAG: HouseStyle, for all eight assertions, and the choice is deliberate.

    METHOD's universality ladder says claims true of anything in the domain are
    Universal, claims true of any project are Repository, and claims that are
    this organisation's convention are HouseStyle. These are conventions. The
    evidence is already on the record: the existing Universal assertion asks
    only for a .SYNOPSIS on exported functions and posh-git fails even that on
    five commands, with the failure classified Bucket B - genuine, but a
    property of the module rather than a defect. Everything here is strictly
    stronger than that assertion. Help on PRIVATE functions, a .PARAMETER entry
    per parameter, examples counted against parameter sets, and a doc block
    before every type are house rules, and promoting any of them would be a
    claim this project cannot support against a second dissimilar target.

    Moving one up the ladder later is a claim and needs evidence from dissimilar
    targets. Starting them at Universal would be assuming the answer.

    Nothing here imports or executes the module under test. Every fact comes
    from the AST and the token stream.
#>

BeforeDiscovery {
    $script:Target = $env:CONFORMANCE_TARGET
    if (-not $Target) {
        throw 'Set $env:CONFORMANCE_TARGET to the repository root of the module under test.'
    }
    if (-not (Test-Path -LiteralPath $Target)) {
        throw "CONFORMANCE_TARGET does not exist: $Target"
    }
    $script:Target = (Resolve-Path -LiteralPath $Target).Path

    # The same discovery rules as Conformance.Tests.ps1, and for the same
    # reason: two graders that must agree on what they are grading will drift.
    # Ambiguity is a hard stop, never a guess.
    $candidates = @(
        Get-ChildItem -Path $Target -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.BaseName -eq $_.Directory.Name -or
                ($_.Directory.Name -match '^\d+(\.\d+)*([-+].*)?$' -and
                    $_.Directory.Parent -and $_.BaseName -eq $_.Directory.Parent.Name)
            } |
            Where-Object {
                $_.FullName.Substring($Target.Length) -notmatch
                    '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'
            }
    )

    $requested = $env:CONFORMANCE_MODULE_NAME
    $repoName = Split-Path -Leaf $Target
    $script:Manifest = $null

    if ($requested) {
        $named = @($candidates | Where-Object { $_.BaseName -eq $requested })
        if ($named.Count -ne 1) {
            throw "-ModuleName '$requested' matched $($named.Count) manifests under '$Target'."
        }
        $script:Manifest = $named[0]
    }
    else {
        $byRepoName = @($candidates | Where-Object { $_.BaseName -eq $repoName })
        $atRoot = @($candidates | Where-Object { $_.Directory.FullName -eq $Target })
        $script:Manifest =
            if ($byRepoName.Count -eq 1) { $byRepoName[0] }
            elseif ($atRoot.Count -eq 1) { $atRoot[0] }
            else { $null }

        if (-not $Manifest -and $candidates.Count -gt 1) {
            $names = @($candidates | ForEach-Object {
                    $_.FullName.Substring($Target.Length).TrimStart('\', '/')
                })
            throw ("Cannot determine which module '$Target' is: $($candidates.Count) candidate " +
                "manifests, none preferred. Candidates: $($names -join '; '). Pass -ModuleName to choose.")
        }
    }

    $script:ModuleName = if ($Manifest) { $Manifest.BaseName } else { $null }
    $script:SrcRoot = if ($Manifest) { $Manifest.Directory.FullName } else { $null }

    # -----------------------------------------------------------------------
    # Help extraction, from the TOKEN stream rather than by matching text.
    #
    # A comment is a token; a string that looks like one is not. The rule
    # PowerShell itself applies is positional - a help block is either the last
    # comment before the definition with nothing but whitespace between, or the
    # first comment inside the body before any statement - and position is
    # exactly what a regex over the file cannot see.
    #
    # This is what makes the scope control possible. A block comment quoting
    # ".SYNOPSIS" somewhere else in the file is a comment token that is attached
    # to nothing, and every assertion here must ignore it.
    # -----------------------------------------------------------------------
    function Get-AttachedHelp {
        param(
            [Parameter(Mandatory)] [object] $Node,
            [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $Token,
            [Parameter(Mandatory)] [string] $Text,
            [object] $BodyExtent
        )

        $comments = @($Token | Where-Object { $_.Kind -eq 'Comment' })

        # 1. Immediately above: the last comment ending at or before the start of
        #    the definition, with only whitespace in between.
        $start = $Node.Extent.StartOffset
        $above = @($comments | Where-Object { $_.Extent.EndOffset -le $start }) |
            Sort-Object { $_.Extent.EndOffset } | Select-Object -Last 1
        if ($above) {
            $between = $Text.Substring($above.Extent.EndOffset, $start - $above.Extent.EndOffset)
            if ($between -notmatch '\S') { return $above.Extent.Text }
        }

        # 2. Inside the body, before the first statement.
        if ($BodyExtent) {
            $inside = @($comments | Where-Object {
                    $_.Extent.StartOffset -gt $BodyExtent.StartOffset -and
                    $_.Extent.EndOffset -lt $BodyExtent.EndOffset
                }) | Sort-Object { $_.Extent.StartOffset } | Select-Object -First 1
            if ($inside) { return $inside.Extent.Text }
        }

        $null
    }

    function Get-HelpSection {
        param([string] $Help, [Parameter(Mandatory)] [string] $Keyword)
        if (-not $Help) { return @() }
        # Each section runs from its own keyword to the next one or the end.
        # Anchored to the start of a line: ".EXAMPLE" inside a code sample is
        # not a section header, and counting it would inflate the example count
        # of exactly the functions whose examples are richest.
        $pattern = '(?ms)^\s*\.' + $Keyword + '\b[^\r\n]*\r?\n(.*?)(?=^\s*\.[A-Z]+\b|\z)'
        @([regex]::Matches($Help, $pattern) | ForEach-Object { $_.Groups[1].Value })
    }

    function Get-ParameterFact {
        param([Parameter(Mandatory)] [object] $Function)

        $paramBlock = if ($Function.Body -and $Function.Body.ParamBlock) { $Function.Body.ParamBlock } else { $null }
        $parameters = @(
            if ($paramBlock) { $paramBlock.Parameters }
            elseif ($Function.Parameters) { $Function.Parameters }
        )

        $facts = foreach ($parameter in $parameters) {
            $name = $parameter.Name.VariablePath.UserPath
            $sets = [System.Collections.Generic.List[string]]::new()
            $mandatoryIn = [System.Collections.Generic.List[string]]::new()

            foreach ($attribute in @($parameter.Attributes |
                    Where-Object { $_ -is [System.Management.Automation.Language.AttributeAst] -and
                        $_.TypeName.Name -eq 'Parameter' })) {

                $setName = '__AllParameterSets'
                $mandatory = $false
                foreach ($named in @($attribute.NamedArguments)) {
                    switch ($named.ArgumentName) {
                        'ParameterSetName' { $setName = $named.Argument.Value }
                        # `Mandatory` with no value is `Mandatory = $true`;
                        # ExpressionOmitted is how the AST says so.
                        'Mandatory' {
                            $mandatory = $named.ExpressionOmitted -or
                                ($named.Argument.Extent.Text -match '\$true')
                        }
                    }
                }
                $sets.Add($setName)
                if ($mandatory) { $mandatoryIn.Add($setName) }
            }
            if ($sets.Count -eq 0) { $sets.Add('__AllParameterSets') }

            [pscustomobject]@{
                Name        = $name
                Sets        = @($sets)
                MandatoryIn = @($mandatoryIn)
            }
        }
        @($facts)
    }

    # Common parameters are supplied by CmdletBinding and are not the author's
    # to document. Asserting a .PARAMETER for -Verbose would make every
    # advanced function fail for a reason that is not about this module.
    $script:CommonParameter = @(
        'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction',
        'ProgressAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable',
        'OutVariable', 'OutBuffer', 'PipelineVariable', 'WhatIf', 'Confirm'
    )

    $script:Functions = @()
    $script:Types = @()

    if ($SrcRoot -and (Test-Path -LiteralPath $SrcRoot)) {
        $sourceFiles = @(
            Get-ChildItem -Path $SrcRoot -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in '.ps1', '.psm1' } |
                Sort-Object FullName
        )

        foreach ($file in $sourceFiles) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName, [ref]$tokens, [ref]$errors)
            # A file that does not parse is reported by the suite's own parse
            # assertions, not silently graded as help-less here.
            if ($errors) { continue }
            $text = [System.IO.File]::ReadAllText($file.FullName)
            $relative = $file.FullName.Substring($Target.Length).TrimStart('\', '/')

            # $false: top-level only. A function defined inside another function
            # is not part of the file's surface.
            foreach ($fn in $ast.FindAll({
                        param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
                    }, $false)) {

                $help = Get-AttachedHelp -Node $fn -Token $tokens -Text $text `
                    -BodyExtent $(if ($fn.Body) { $fn.Body.Extent } else { $null })
                $examples = @(Get-HelpSection -Help $help -Keyword 'EXAMPLE')
                $documented = @(
                    [regex]::Matches($(if ($help) { $help } else { '' }), '(?m)^\s*\.PARAMETER\s+(\S+)') |
                        ForEach-Object { $_.Groups[1].Value }
                )
                $facts = @(Get-ParameterFact -Function $fn)
                $declared = @($facts | Where-Object { $_.Name -notin $CommonParameter })

                # ForEach-Object rather than $facts.Sets. Member enumeration
                # over an empty array raises "The property 'Sets' cannot be
                # found on this object" here, and it took down the whole
                # container's DISCOVERY - every assertion in this file vanished
                # from the run while the score printed as though nothing was
                # missing. A function with no parameters is the common case.
                $namedSets = @($facts | ForEach-Object { $_.Sets } |
                        Where-Object { $_ -ne '__AllParameterSets' } | Sort-Object -Unique)
                $setCases = foreach ($set in $namedSets) {
                    # Discriminators: what makes THIS set the one being shown.
                    # Mandatory parameters first, because a reader recognises a
                    # set by what it forces them to supply. Failing that, the
                    # parameters unique to it. A set with neither is
                    # indistinguishable in an example and is not asserted on -
                    # reported as nothing to check rather than passed for free.
                    $mandatory = @($facts | Where-Object { $set -in $_.MandatoryIn } | ForEach-Object Name)
                    $unique = @($facts | Where-Object {
                            $set -in $_.Sets -and @($_.Sets | Where-Object { $_ -ne $set }).Count -eq 0
                        } | ForEach-Object Name)
                    [pscustomobject]@{
                        Set            = $set
                        Discriminators = @(if ($mandatory.Count) { $mandatory } else { $unique })
                    }
                }

                $script:Functions += [pscustomobject]@{
                    Name         = $fn.Name -replace '^(global|script|local|private):', ''
                    File         = $relative
                    Line         = $fn.Extent.StartLineNumber
                    HasHelp      = [bool]$help
                    HasSynopsis  = @(Get-HelpSection -Help $help -Keyword 'SYNOPSIS').Count -gt 0
                    HasDescription = @(Get-HelpSection -Help $help -Keyword 'DESCRIPTION').Count -gt 0
                    Examples     = $examples
                    ExampleCount = $examples.Count
                    Parameters   = @($declared | ForEach-Object Name)
                    Documented   = $documented
                    NamedSets    = $namedSets
                    SetCases     = @($setCases)
                }
            }

            foreach ($type in $ast.FindAll({
                        param($n) $n -is [System.Management.Automation.Language.TypeDefinitionAst]
                    }, $true)) {

                $help = Get-AttachedHelp -Node $type -Token $tokens -Text $text
                $script:Types += [pscustomobject]@{
                    Name    = $type.Name
                    File    = $relative
                    Line    = $type.Extent.StartLineNumber
                    Kind    = if ($type.IsEnum) { 'enum' } else { 'class' }
                    HasHelp = [bool]$help
                }
            }
        }
    }

    # Only functions with at least one named set have anything to say about set
    # coverage. Zero cases is INAPPLICABLE and is reported as such by the
    # runner, never counted as a pass.
    $script:FunctionsWithNamedSets = @($Functions | Where-Object { $_.NamedSets.Count -gt 0 })
    $script:FunctionsWithParameters = @($Functions | Where-Object { $_.Parameters.Count -gt 0 })
}

Describe 'House style: help' -Tag 'HouseStyle' {

    # <_.Name>, not <_>: expanding an object stamps its ToString into the test
    # name, so the recorded name would change with the target's location and
    # scores could not be diffed between runs.
    It 'gives <_.Name> comment-based help with a synopsis' -ForEach $Functions -AllowNullOrEmptyForEach {
        $_.HasSynopsis | Should -BeTrue -Because (
            "$($_.File):$($_.Line) defines $($_.Name) with " +
            $(if ($_.HasHelp) { 'a help block that has no .SYNOPSIS' } else { 'no attached help block' }) +
            '. Private is not an exemption - the helper nobody wrote help for is the one nobody recognises later')
    }

    It 'gives <_.Name> a help description' -ForEach $Functions -AllowNullOrEmptyForEach {
        $_.HasDescription | Should -BeTrue -Because (
            "$($_.File):$($_.Line) - .DESCRIPTION carries what a reader cannot infer from the signature, " +
            'and a function whose description would be redundant has not been read by anyone but its author')
    }

    It 'gives <_.Name> at least one example' -ForEach $Functions -AllowNullOrEmptyForEach {
        $_.ExampleCount | Should -BeGreaterThan 0 -Because (
            "$($_.File):$($_.Line) - an example is the only part of help most readers read")
    }

    It 'gives <_.Name> at least as many examples as parameter sets' -ForEach $Functions -AllowNullOrEmptyForEach {
        $expected = [math]::Max(1, $_.NamedSets.Count)
        $_.ExampleCount | Should -BeGreaterOrEqual $expected -Because (
            "$($_.File):$($_.Line) - $($_.Name) declares $($_.NamedSets.Count) named parameter set(s) " +
            "[$($_.NamedSets -join ', ')] and carries $($_.ExampleCount) example(s). " +
            'A set added without an example is a set nobody knows exists')
    }

    It 'shows every named parameter set of <_.Name> in an example' -ForEach $FunctionsWithNamedSets -AllowNullOrEmptyForEach {
        $uncovered = foreach ($case in $_.SetCases) {
            # A set with no discriminating parameter cannot be shown in an
            # example distinctly. Nothing to check is not the same as passing,
            # and it is not counted as either.
            if ($case.Discriminators.Count -eq 0) { continue }
            $shown = $false
            foreach ($example in $_.Examples) {
                # Two syntaxes count, and missing the second would make this
                # assertion unsatisfiable by a CONFORMING example: the house
                # .EXAMPLE standard mandates splatting, so a correct example
                # names its parameters as hashtable keys and never writes the
                # dash form at all. Looking only for the dash form failed a
                # fixture built to the standard - found by falsifying this
                # assertion before it shipped rather than after.
                $missing = @($case.Discriminators | Where-Object {
                        $example -notmatch "-$_\b" -and $example -notmatch "(?m)^\s*$_\s*="
                    })
                if ($missing.Count -eq 0) { $shown = $true; break }
            }
            if (-not $shown) { "$($case.Set) (needs -$($case.Discriminators -join ' -'))" }
        }
        @($uncovered) | Should -BeNullOrEmpty -Because (
            "$($_.File):$($_.Line) - $($_.Name) has no example showing parameter set(s): " +
            "$(@($uncovered) -join '; '). The set exists, and no example demonstrates it")
    }

    It 'gives every parameter of <_.Name> a .PARAMETER entry' -ForEach $FunctionsWithParameters -AllowNullOrEmptyForEach {
        # Bound to $case first: inside the Where-Object scriptblock $_ is the
        # parameter name being tested, not the case, so $_.Documented there
        # reads a property of a string and is silently $null under StrictMode's
        # absence - which would pass this assertion for every function.
        $case = $_
        $undocumented = @($case.Parameters | Where-Object { $_ -notin $case.Documented })
        @($undocumented) | Should -BeNullOrEmpty -Because (
            "$($case.File):$($case.Line) - $($case.Name) declares parameter(s) with no .PARAMETER entry: " +
            "$(@($undocumented) -join ', ')")
    }

    It 'precedes <_.Kind> <_.Name> with a doc comment block' -ForEach $Types -AllowNullOrEmptyForEach {
        $_.HasHelp | Should -BeTrue -Because (
            "$($_.File):$($_.Line) - PowerShell classes and enums support no comment-based help at all, " +
            'so the block immediately above the type is the only documentation a reader of the source ever ' +
            'gets. This asserts the checkable equivalent, and says so rather than pretending Get-Help works')
    }

    It 'ships about_<ModuleName> when the module defines types' {
        # Deliberately not -Skip when there are no types. A module with no types
        # passes this because the claim - "types are documented where a user can
        # find them" - is true of it, which is a different statement from the
        # assertion not applying.
        if (@($Types).Count -eq 0) {
            $true | Should -BeTrue -Because 'the module defines no classes or enums'
            return
        }
        $topics = @(
            Get-ChildItem -Path $SrcRoot -Filter "about_$ModuleName.help.txt" `
                -File -Recurse -ErrorAction SilentlyContinue
        )
        @($topics).Count | Should -BeGreaterThan 0 -Because (
            "the module defines $(@($Types).Count) type(s) - $(@($Types | ForEach-Object Name) -join ', ') - " +
            "and about_$ModuleName.help.txt is the only place a USER can read about them. " +
            'Source comments are for whoever opens the file, which is not the same person')
    }
}
