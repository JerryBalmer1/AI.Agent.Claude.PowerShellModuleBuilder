#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0' }

<#
    Conformance suite for PowerShell module repositories.

    The target repository is passed in $env:CONFORMANCE_TARGET. Nothing here
    imports or executes the module under test; every assertion reads the source
    tree, the manifest, the build file, or the generated psm1 as text.

    Tags:
      Universal    - true of any PowerShell module, source tree or published
                     package. Reads the manifest and the source it can find.
      Repository   - true of any module repository. Needs a source tree: build
                     entrypoint, analyzer settings, tests.
      HouseStyle   - specific to the PSModuleGraph build conventions
      RequiresBuild- needs output/<Name>/ to exist, so run after a build

    Universal and Repository were one tag until the split showed what the
    conflation was hiding: a published package has no build file and no tests,
    and failing it for that says nothing about the module.

    Written in Pester v5 assertion style on purpose. The suite is tooling, not a
    module's own tests, and it has to keep running if a target repository turns
    Should.DisableV5 on or off. Revisit only if that stops being true.
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

    # Find the module manifest without assuming the layout. Two layouts count:
    #
    #   source tree       <name>/<name>.psd1
    #   published module  <name>/<version>/<name>.psd1
    #
    # The second is the standard on-disk shape of an installed or downloaded
    # module, and accepting only the first is why all eight gallery corpus
    # modules failed discovery: a package's manifest sits in a directory named
    # for its version, not for itself.
    #
    # Build output, scratch, vendored galleries and test fixtures all contain
    # well-formed manifests that are not the repository's own module. Matched
    # against the path RELATIVE to the target, not the absolute path: the
    # harness runs targets from ./scratch/runs/<id>/, so an absolute match let
    # the target's own container exclude every candidate inside it.
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

    # Selection, most specific first. Ambiguity is a hard stop, never a guess.
    # Shortest path used to be the tie-break, and SqlServerDsc - which ships 51
    # manifests - was silently graded on a bundled helper module, reporting
    # 81.82% for the wrong target with nothing in the output to say so. A suite
    # that cannot tell what it is grading must say so rather than pick.
    $requested = $env:CONFORMANCE_MODULE_NAME
    $repoName = Split-Path -Leaf $Target
    $script:Manifest = $null

    if ($requested) {
        $named = @($candidates | Where-Object { $_.BaseName -eq $requested })
        if ($named.Count -ne 1) {
            throw ("-ModuleName '$requested' matched $($named.Count) manifests under '$Target'.")
        }
        $script:Manifest = $named[0]
    }
    else {
        # The repository's own module is the one named for the repository.
        $byRepoName = @($candidates | Where-Object { $_.BaseName -eq $repoName })
        # A manifest sitting directly in the target is that target's module.
        # This is what resolves <name>/<version>/, where the leaf is a version
        # and so matches no name.
        $atRoot = @($candidates | Where-Object { $_.Directory.FullName -eq $Target })

        $script:Manifest =
            if ($byRepoName.Count -eq 1) { $byRepoName[0] }
            elseif ($atRoot.Count -eq 1) { $atRoot[0] }
            elseif ($candidates.Count -eq 1) { $candidates[0] }
            else { $null }

        # No candidates at all is not ambiguity - it is absence, and the
        # Manifest assertion below reports it. Only an undecidable choice throws.
        if (-not $Manifest -and $candidates.Count -gt 1) {
            $names = @($candidates | ForEach-Object {
                    $_.FullName.Substring($Target.Length).TrimStart('\', '/')
                })
            throw ("Cannot determine which module '$Target' is: $($candidates.Count) candidate " +
                "manifests, none preferred. Candidates: $($names -join '; '). " +
                'Pass -ModuleName to choose.')
        }
    }

    $script:ModuleName   = if ($Manifest) { $Manifest.BaseName } else { $null }
    $script:SrcRoot      = if ($Manifest) { $Manifest.Directory.FullName } else { $null }
    $script:PublicDir    = if ($SrcRoot) { Join-Path $SrcRoot 'Public' } else { $null }
    $script:PrivateDir   = if ($SrcRoot) { Join-Path $SrcRoot 'Private' } else { $null }
    $script:TestsRoot    = Join-Path $Target 'tests'
    $script:OutRoot      = if ($ModuleName) { Join-Path (Join-Path $Target 'output') $ModuleName } else { $null }
    $script:BuiltPsm1    = if ($OutRoot) { Join-Path $OutRoot "$ModuleName.psm1" } else { $null }
    $script:BuildFile    = if ($ModuleName) { Join-Path $Target "$ModuleName.build.ps1" } else { $null }

    $script:PublicFiles = @()
    if ($PublicDir -and (Test-Path -LiteralPath $PublicDir)) {
        # Not recursive. If the target nests Public/, the house-style test below
        # is what reports it; discovery should not quietly paper over it.
        $script:PublicFiles = @(Get-ChildItem -Path $PublicDir -Filter *.ps1 -File | Sort-Object Name)
    }

    $script:ManifestData = $null
    if ($Manifest) {
        try { $script:ManifestData = Import-PowerShellDataFile -LiteralPath $Manifest.FullName } catch { }
    }

    $script:ExportedFunctions = @()
    if ($ManifestData -and $ManifestData.ContainsKey('FunctionsToExport')) {
        $script:ExportedFunctions = @($ManifestData.FunctionsToExport)
    }

    # One index of what this module defines, built once, used by every assertion
    # that needs to know. Two separate defects came from not having it:
    #
    #   - the scan globbed *.ps1 only, so every module that defines its exports
    #     in the .psm1 looked undefined - Pester's Invoke-Pester, all 161 of
    #     SqlServerDsc's exports, ImportExcel's New-Plot.
    #   - FunctionDefinitionAst.Name carries the scope qualifier, so posh-git's
    #     'function Global:Write-VcsStatus' never matched the exported name.
    #
    # $false on FindAll: top-level definitions only. A function defined inside
    # another function is not part of the file's surface.
    $script:DefinedFunctions = @{}
    if ($SrcRoot -and (Test-Path -LiteralPath $SrcRoot)) {
        $sourceFiles = @(
            Get-ChildItem -Path $SrcRoot -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in '.ps1', '.psm1' }
        )
        foreach ($file in $sourceFiles) {
            $ft = $null
            $fe = $null
            $fileAst = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName, [ref]$ft, [ref]$fe)
            if ($fe) { continue }
            foreach ($fn in $fileAst.FindAll({
                        param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
                    }, $false)) {
                $plain = $fn.Name -replace '^(global|script|local|private):', ''
                if (-not $DefinedFunctions.ContainsKey($plain)) {
                    $DefinedFunctions[$plain] = $file.FullName
                }
            }
        }
    }

    # Exports resolved to the file that defines them, and exports that resolve
    # nowhere. The help assertion runs over the first; the definition assertion
    # asserts the second is empty.
    $script:ExportedWithSource = @()
    $script:MissingExports = @()
    foreach ($exported in $ExportedFunctions) {
        if (-not $exported) { continue }
        if ($DefinedFunctions.ContainsKey($exported)) {
            $script:ExportedWithSource += [pscustomobject]@{
                Name = $exported
                File = $DefinedFunctions[$exported]
            }
        }
        else {
            $script:MissingExports += $exported
        }
    }
}

BeforeAll {
    function Get-DefinedFunctionName {
        param([Parameter(Mandatory)][string] $Path)

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        if ($errors) { return @() }

        # $false: top-level definitions only. A function defined inside another
        # function is not part of the file's surface.
        # Scope qualifiers stripped: FunctionDefinitionAst.Name for
        # 'function Global:Write-VcsStatus' is 'Global:Write-VcsStatus'.
        @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) |
            ForEach-Object { $_.Name -replace '^(global|script|local|private):', '' })
    }

    function Test-FunctionSynopsis {
        # Comment-based help for ONE named function, wherever that function
        # lives. Was a file-level check over Public/*.ps1, which is a house
        # style directory: six of eight corpus modules have no such directory,
        # so the assertion produced zero cases and said nothing at all.
        #
        # Both legal placements count. The reference writes help inside the
        # function body; posh-git writes it in a block immediately above the
        # definition. Either is comment-based help; neither is a file-level
        # property, which matters for a generated .psm1 holding hundreds of
        # functions where only some are documented.
        param(
            [Parameter(Mandatory)][string] $Path,
            [Parameter(Mandatory)][string] $Name
        )

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        if ($errors) { return $false }

        $fn = @($ast.FindAll({
                    param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }, $true) | Where-Object {
                ($_.Name -replace '^(global|script|local|private):', '') -eq $Name
            }) | Select-Object -First 1
        if (-not $fn) { return $false }

        $comments = @($tokens | Where-Object {
                $_.Kind -eq 'Comment' -and $_.Text -match '(?im)\.SYNOPSIS'
            })
        if ($comments.Count -eq 0) { return $false }

        $start = $fn.Extent.StartOffset
        $end = $fn.Extent.EndOffset
        $text = Get-Content -LiteralPath $Path -Raw

        foreach ($comment in $comments) {
            if ($comment.Extent.StartOffset -ge $start -and $comment.Extent.EndOffset -le $end) {
                return $true
            }
            if ($comment.Extent.EndOffset -le $start) {
                $between = $text.Substring($comment.Extent.EndOffset, $start - $comment.Extent.EndOffset)
                if ($between -match '^\s*$') { return $true }
            }
        }
        $false
    }

    function Get-BuildTaskCommand {
        # The CommandAst for one InvokeBuild task.
        #
        # InvokeBuild spells a task 'task <Name> [<deps>,] { ... }', so the name
        # is the second command element whether or not dependencies follow.
        # Structure, not text: every assertion in this Describe used to match a
        # regex against the whole file, and all five that remained were satisfied
        # by a block comment quoting the line they looked for, with the real code
        # deleted. A comment is not a task.
        param(
            [Parameter(Mandatory)][string] $Path,
            [Parameter(Mandatory)][string] $TaskName
        )

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        if ($errors) { return $null }

        @($ast.FindAll({
                    param($n)
                    $n -is [System.Management.Automation.Language.CommandAst] -and
                    $n.GetCommandName() -eq 'task' -and
                    @($n.CommandElements).Count -gt 1 -and
                    $n.CommandElements[1].Extent.Text -eq $TaskName
                }, $true))
    }

    function Get-BuildTaskBody {
        # The scriptblock of one InvokeBuild task, as an AST. The body has to be
        # found by search rather than by indexing CommandElements: with
        # dependencies present it sits inside an array literal, not at the top
        # level. FindAll is pre-order, so the task's own body comes before
        # anything nested inside it.
        param(
            [Parameter(Mandatory)][string] $Path,
            [Parameter(Mandatory)][string] $TaskName
        )

        $task = @(Get-BuildTaskCommand -Path $Path -TaskName $TaskName)
        if ($task.Count -ne 1) { return $null }

        @($task[0].FindAll({
                    param($n) $n -is [System.Management.Automation.Language.ScriptBlockExpressionAst]
                }, $true)) | Select-Object -First 1
    }

    function Get-ConfigAssignment {
        # Assignments of the form $<config>.<Section>.<Member> = ... within a
        # scriptblock. Structure rather than text, so that a comment mentioning
        # a setting is not mistaken for the setting.
        param(
            [Parameter(Mandatory)] $Body,
            [Parameter(Mandatory)][string] $Section,
            [Parameter(Mandatory)][string] $Member
        )

        @($Body.FindAll({
                    param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst]
                }, $true) | Where-Object {
                $left = $_.Left
                $left -is [System.Management.Automation.Language.MemberExpressionAst] -and
                $left.Member.Extent.Text -eq $Member -and
                $left.Expression -is [System.Management.Automation.Language.MemberExpressionAst] -and
                $left.Expression.Member.Extent.Text -eq $Section
            })
    }
}

Describe 'Manifest' -Tag 'Universal' {

    It 'exists, and its base name matches its directory' {
        $Manifest | Should -Not -BeNullOrEmpty -Because 'a module repository without a manifest has no identity'
    }

    It 'parses as PowerShell data' {
        $ManifestData | Should -Not -BeNullOrEmpty
    }

    It 'declares a RootModule' {
        $ManifestData.RootModule | Should -Not -BeNullOrEmpty
    }

    It 'declares a ModuleVersion that parses as a version' {
        { [version] $ManifestData.ModuleVersion } | Should -Not -Throw
    }

    It 'declares a GUID that parses as a GUID' {
        { [guid] $ManifestData.GUID } | Should -Not -Throw
    }

    It 'exports functions by explicit name, never by wildcard' {
        # A wildcard export defeats command discovery and leaks private helpers.
        #
        # There used to be a second assertion here requiring at least one
        # exported function. It was not a universal truth and it is gone: Az is
        # a rollup with no code at all, Az.Accounts exports cmdlets implemented
        # in C#, and both legitimately export zero functions. Two claims in one
        # It, one of them false.
        $ExportedFunctions | Should -Not -Contain '*'
    }

    It 'exports no cmdlets, variables, or aliases implicitly' -ForEach @(
        @{ Key = 'CmdletsToExport' }
        @{ Key = 'VariablesToExport' }
        @{ Key = 'AliasesToExport' }
    ) {
        $ManifestData.ContainsKey($Key) | Should -BeTrue -Because "$Key left unset defaults to a wildcard"
        @($ManifestData[$Key]) | Should -Not -Contain '*'
    }

}

Describe 'Public surface' -Tag 'Universal' {

    It 'defines every function the manifest exports somewhere in source' {
        # $MissingExports is resolved once at discovery against the definition
        # index, which scans .psm1 as well as .ps1 and strips scope qualifiers.
        # Doing it here with Get-ChildItem also meant an absent $SrcRoot threw
        # rather than failing.
        $MissingExports | Should -BeNullOrEmpty -Because 'an exported function that does not exist fails at import, not at call'
    }

    # Driven by the exported surface, not by Public/*.ps1. The directory is a
    # house style convention; the export list is what the module promises.
    #
    # <_.Name>, not <_>: expanding an object stamps its ToString into the test
    # name, so the name recorded in result.json changed with the target's
    # location and scores could not be diffed between runs.
    It 'gives <_.Name> comment-based help with a synopsis' -ForEach $ExportedWithSource {
        Test-FunctionSynopsis -Path $_.File -Name $_.Name |
            Should -BeTrue -Because 'Get-Help on an exported command should return something'
    }
}

# Repository, not Universal. Every assertion here needs a source tree: a build
# entrypoint, analyzer settings, a tests directory, tests that call the command.
# A published package satisfies none of them and is not thereby a bad module -
# it is a module rather than a module repository. Conflating the two made
# 'Universal' a claim the tag could not support.
Describe 'Repository shape' -Tag 'Repository' {

    It 'has a build entrypoint at the repository root' {
        Test-Path -LiteralPath (Join-Path $Target 'build.ps1') | Should -BeTrue
    }

    It 'has analyzer settings at the repository root' {
        # At the root so editors and CI lint identically to the build.
        Test-Path -LiteralPath (Join-Path $Target 'PSScriptAnalyzerSettings.psd1') | Should -BeTrue
    }

    It 'has a tests directory' {
        Test-Path -LiteralPath $TestsRoot | Should -BeTrue
    }

    It 'exercises the exported command <_.BaseName> somewhere in tests' -ForEach $PublicFiles {
        # Not a filename convention and not a text search. A command named in a
        # string - the export list in Module.Quality.Tests.ps1, for instance - is
        # not a command under test. Only an actual invocation counts.
        $name = $_.BaseName
        $invoked = $false
        foreach ($file in (Get-ChildItem -Path $TestsRoot -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue)) {
            $tokens = $null; $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            if ($errors) { continue }
            $calls = @($ast.FindAll({
                param($n) $n -is [System.Management.Automation.Language.CommandAst]
            }, $true))
            if ($calls | Where-Object { $_.GetCommandName() -eq $name }) { $invoked = $true; break }
        }
        $invoked | Should -BeTrue -Because 'an exported command no test ever calls is untested'
    }
}

Describe 'House style: source layout' -Tag 'HouseStyle' {

    It 'places source under src/<ModuleName>/' {
        $SrcRoot | Should -BeLike (Join-Path (Join-Path $Target 'src') '*')
    }

    It 'keeps Public/ flat' {
        # The export list is derived from these filenames, so a subdirectory
        # here silently drops commands from the module surface.
        $nested = @(Get-ChildItem -Path $PublicDir -Directory -ErrorAction SilentlyContinue)
        $nested | Should -BeNullOrEmpty
    }

    It 'defines exactly one function in <_.Name>, named for the file' -ForEach $PublicFiles {
        # @(): see the note on comment-based help above. Without it a file
        # defining exactly one function returns a scalar and .Count throws.
        $names = @(Get-DefinedFunctionName -Path $_.FullName)
        $names.Count | Should -Be 1
        $names[0] | Should -Be $_.BaseName
    }

    It 'agrees three ways: Public filenames, manifest exports, and their count' {
        # The build derives Export-ModuleMember from filenames and the manifest
        # is written by hand. This is the seam where they drift.
        $fromFiles = @($PublicFiles.BaseName | Sort-Object)
        $fromManifest = @($ExportedFunctions | Sort-Object)
        Compare-Object -ReferenceObject $fromFiles -DifferenceObject $fromManifest |
            Should -BeNullOrEmpty -Because 'the manifest and Public/ must name the same commands'
    }

    It 'declares the PowerShell editions it claims to support' {
        # HouseStyle, not Universal. CompatiblePSEditions is optional in the
        # manifest schema and six of the eight corpus modules omit it, including
        # posh-git - the corpus control - and Pester. Asserting it as a fact
        # about PowerShell modules was a preference wearing a fact's clothes.
        #
        # ContainsKey first: reading an absent key throws PropertyNotFound under
        # Set-StrictMode -Version Latest, so the assertion errored instead of
        # failing.
        $ManifestData.ContainsKey('CompatiblePSEditions') |
            Should -BeTrue -Because 'the house style declares the editions it supports'
        $ManifestData.CompatiblePSEditions | Should -Not -BeNullOrEmpty
    }

    It 'pins build dependencies only in Requirements.psd1' {
        $req = Join-Path $Target 'Requirements.psd1'
        Test-Path -LiteralPath $req | Should -BeTrue
        $data = Import-PowerShellDataFile -LiteralPath $req
        $data.Keys.Count | Should -BeGreaterThan 0
        foreach ($key in $data.Keys) {
            $entry = $data[$key]
            $pinned = ($entry -is [string]) -or
                      ($entry -is [System.Collections.IDictionary] -and
                       ($entry.Contains('RequiredVersion') -or $entry.Contains('MinimumVersion')))
            $pinned | Should -BeTrue -Because "$key must state RequiredVersion or MinimumVersion"
        }
    }
}

Describe 'House style: build file' -Tag 'HouseStyle' {

    BeforeAll {
        $script:BuildText = if ($BuildFile -and (Test-Path -LiteralPath $BuildFile)) {
            Get-Content -LiteralPath $BuildFile -Raw
        } else { '' }
    }

    It 'has a build file named <ModuleName>.build.ps1' {
        Test-Path -LiteralPath $BuildFile | Should -BeTrue
    }

    It 'declares the task <_>' -ForEach @('Clean', 'Lint', 'Build', 'Test', 'PreTag') {
        # Was a regex. Renaming the real task and leaving a block comment that
        # quoted its declaration kept the assertion green.
        @(Get-BuildTaskCommand -Path $BuildFile -TaskName $_).Count |
            Should -BeGreaterThan 0 -Because 'a commented-out task is not a task'
    }

    It 'makes the default task Clean, Lint, Build, Test' {
        # The default task is 'task . <deps>'. Its dependency list parses as an
        # array literal, so the names can be compared as names rather than
        # matched as a line of text that a comment can also supply.
        $default = @(Get-BuildTaskCommand -Path $BuildFile -TaskName '.')
        $default.Count | Should -Be 1 -Because 'exactly one default task'

        $elements = @($default[0].CommandElements)
        $elements.Count | Should -BeGreaterThan 2 -Because 'the default task must name its dependencies'

        $deps = @(
            if ($elements[2] -is [System.Management.Automation.Language.ArrayLiteralAst]) {
                $elements[2].Elements | ForEach-Object { $_.Extent.Text }
            }
            else {
                $elements[2..($elements.Count - 1)] | ForEach-Object { $_.Extent.Text }
            }
        )
        ($deps -join ',') | Should -Be 'Clean,Lint,Build,Test'
    }

    It 'excludes PreTag-tagged tests from the Test task' {
        # A half-finished iteration must still be able to build green.
        # Scoped to the Test task's body, and to an actual assignment: the regex
        # form was satisfied by a comment quoting the line.
        $body = Get-BuildTaskBody -Path $BuildFile -TaskName 'Test'
        $body | Should -Not -BeNullOrEmpty -Because 'the Test task configures the run'

        @(Get-ConfigAssignment -Body $body -Section 'Filter' -Member 'ExcludeTag' |
                Where-Object { $_.Right.Extent.Text -match 'PreTag' }).Count |
            Should -BeGreaterThan 0 -Because 'PreTag tests must not run in the default build'
    }

    It 'throws rather than exits when tests fail' {
        # Run.Exit makes Pester call exit, which can kill the host process.
        #
        # This was two regexes over the whole file, and its negative control
        # failed: a COMMENT reading "never set Run.Exit = $true here" turned it
        # red without a line of code changing. A build file whose author
        # documented the hazard failed the assertion that checks for the hazard.
        # The coverage assertion had the mirror-image defect - a comment
        # satisfying it. One cause, both directions, so this gets the same
        # treatment: ask the syntax, not the text.
        $body = Get-BuildTaskBody -Path $BuildFile -TaskName 'Test'
        $body | Should -Not -BeNullOrEmpty -Because 'the Test task is where Pester is configured'

        $throwAssign = @(Get-ConfigAssignment -Body $body -Section 'Run' -Member 'Throw')
        @($throwAssign | Where-Object { $_.Right.Extent.Text -eq '$true' }).Count |
            Should -BeGreaterThan 0 -Because 'Run.Throw must be set, not merely mentioned'

        @(Get-ConfigAssignment -Body $body -Section 'Run' -Member 'Exit').Count |
            Should -Be 0 -Because 'Run.Exit makes Pester kill the host process'
    }

    It 'disables Pester v5 assertion syntax' {
        $body = Get-BuildTaskBody -Path $BuildFile -TaskName 'Test'
        $body | Should -Not -BeNullOrEmpty -Because 'the Test task configures the run'

        @(Get-ConfigAssignment -Body $body -Section 'Should' -Member 'DisableV5' |
                Where-Object { $_.Right.Extent.Text -eq '$true' }).Count |
            Should -BeGreaterThan 0 -Because 'v5 assertion syntax must be off, not merely mentioned'
    }

    It 'measures coverage against the built psm1, not the source tree' {
        # Coverage measured against src/ counts lines the build never assembled.
        $body = Get-BuildTaskBody -Path $BuildFile -TaskName 'Test'
        $body | Should -Not -BeNullOrEmpty -Because 'the Test task configures coverage'

        @(Get-ConfigAssignment -Body $body -Section 'CodeCoverage' -Member 'Path' |
                Where-Object { $_.Right.Extent.Text -match 'psm1' }).Count |
            Should -BeGreaterThan 0 -Because 'coverage must read the built module'
    }

    It 'throws on coverage below target rather than only reporting it' {
        # CoveragePercentTarget reports and nothing else. It sat at 74.88
        # against a target of 75 through three green builds, so the throw after
        # the comparison is the actual gate.
        #
        # This was '(?s)CoveragePercent.*throw' and could not fail. (?s) plus an
        # unbounded .* meant any throw anywhere later in the file satisfied it:
        # deleting the gate left it green on the word "throw" in the comment
        # explaining the gate, and with that comment gone it still matched the
        # Pester guard in the PreTag task thirty lines down. Nine throws in this
        # build file, and the assertion accepted all of them.
        #
        # Structure instead of text. The throw has to be inside the if that
        # compares the coverage percentage, inside the Test task, or it is not
        # this gate.
        Test-Path -LiteralPath $BuildFile | Should -BeTrue

        # Same helper as the Run.Exit assertion above. Both need the Test task's
        # body and nothing outside it.
        $body = Get-BuildTaskBody -Path $BuildFile -TaskName 'Test'
        $body | Should -Not -BeNullOrEmpty -Because 'the coverage gate lives in the Test task'

        # The gate is an if whose CONDITION reads the coverage percentage -
        # a $percent-ish variable, or the .CoveragePercent member off the Pester
        # result. Matching the condition is what keeps a comment from counting.
        $gates = @($body.FindAll({
                    param($n)
                    if ($n -isnot [System.Management.Automation.Language.IfStatementAst]) { return $false }
                    $hits = @($n.Clauses | ForEach-Object {
                            $_.Item1.FindAll({
                                    param($c)
                                    ($c -is [System.Management.Automation.Language.VariableExpressionAst] -and
                                    $c.VariablePath.UserPath -match 'percent') -or
                                    ($c -is [System.Management.Automation.Language.MemberExpressionAst] -and
                                    $c.Member.Extent.Text -match 'CoveragePercent')
                                }, $true)
                        })
                    $hits.Count -gt 0
                }, $true))
        $gates.Count | Should -BeGreaterThan 0 -Because 'nothing in the Test task compares coverage against a target'

        # Only that if's own body. A throw in the Dependencies resolver, the
        # PreTag guard, or anywhere else in the file is a different statement
        # and does not make this gate exist.
        $throws = @($gates | ForEach-Object {
                $_.Clauses | ForEach-Object {
                    $_.Item2.FindAll({
                            param($t) $t -is [System.Management.Automation.Language.ThrowStatementAst]
                        }, $true)
                }
            })
        $throws.Count | Should -BeGreaterThan 0 -Because 'CoveragePercentTarget only reports; the throw is the gate'
    }
}

# RequiresBuild only. Pester's tag filter is an OR: carrying 'HouseStyle' here
# too made this block run under the documented no-build invocation
# (-Tag Universal,HouseStyle), where every assertion reads an absent psm1 as
# empty string and fails. The README's own tag matrix says this block needs a
# build, so the tag has to be the one that gates it.
Describe 'House style: generated module' -Tag 'RequiresBuild' {

    BeforeAll {
        $script:Psm1Text = if ($BuiltPsm1 -and (Test-Path -LiteralPath $BuiltPsm1)) {
            Get-Content -LiteralPath $BuiltPsm1 -Raw
        } else { '' }
    }

    It 'produced output/<ModuleName>/<ModuleName>.psm1' {
        Test-Path -LiteralPath $BuiltPsm1 | Should -BeTrue -Because 'run the build before the RequiresBuild tag'
    }

    It 'marks the generated file as generated' {
        $Psm1Text | Should -Match '(?i)auto-generated'
    }

    It 'sets $script:ModuleRoot' {
        # Concatenation moves what $PSScriptRoot means, so assets must resolve
        # from a variable that is the same under the build and the dev loader.
        $Psm1Text | Should -Match '\$script:ModuleRoot\s*=\s*\$PSScriptRoot'
    }

    It 'exports exactly the manifest surface' {
        $Psm1Text | Should -Match 'Export-ModuleMember\s+-Function'
        foreach ($fn in $ExportedFunctions) {
            $Psm1Text | Should -Match ([regex]::Escape("'$fn'"))
        }
    }

    It 'includes functions from Private subfolders' {
        $nestedPrivate = @(
            Get-ChildItem -Path $PrivateDir -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Directory.FullName -ne $PrivateDir }
        )
        if ($nestedPrivate.Count -eq 0) {
            Set-ItResult -Skipped -Because 'this module has no nested Private subfolders'
            return
        }
        foreach ($file in $nestedPrivate) {
            foreach ($name in (Get-DefinedFunctionName -Path $file.FullName)) {
                $Psm1Text | Should -Match ([regex]::Escape("function $name"))
            }
        }
    }

    It 'copies culture directories so Get-Help finds about_ topics' {
        $cultures = @(Get-ChildItem -Path $SrcRoot -Directory | Where-Object { $_.Name -match '^[a-z]{2}(-[A-Za-z]{2,4})?$' })
        if ($cultures.Count -eq 0) {
            Set-ItResult -Skipped -Because 'this module ships no culture directories'
            return
        }
        foreach ($culture in $cultures) {
            Test-Path -LiteralPath (Join-Path $OutRoot $culture.Name) | Should -BeTrue
        }
    }
}
