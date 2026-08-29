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

    # Find the module manifest without assuming the layout, so the Universal
    # tags can run against a repository that does not follow the house style.
    # A manifest is a .psd1 whose base name matches its own directory name.
    # Build output, scratch, vendored galleries and test fixtures all contain
    # well-formed manifests that are not the repository's own module.
    # Matched against the path RELATIVE to the target, not the absolute path.
    # The harness runs targets from ./scratch/runs/<id>/, so an absolute match
    # let the target's own container exclude every candidate inside it.
    $candidates = @(
        Get-ChildItem -Path $Target -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -eq $_.Directory.Name } |
            Where-Object {
                $_.FullName.Substring($Target.Length) -notmatch
                    '[\\/](output|scratch|\.git|gallery|fixtures|node_modules)[\\/]'
            }
    )

    # Shortest path is not a sufficient tie-break: a repository can carry a
    # second module at a shallower path than its own (PSModuleGraph vendors
    # corpus/PSCorpus/, which wins on length over src/PSModuleGraph/). The
    # repository's own module is the one named for the repository; fall back to
    # shortest path only when nothing matches, so a repository whose directory
    # has been renamed still resolves.
    # Select-Object -First 1, not [0]: indexing an empty array throws under
    # Set-StrictMode -Version Latest, which the runner sets.
    $repoName = Split-Path -Leaf $Target
    $script:Manifest = $candidates | Where-Object { $_.BaseName -eq $repoName } | Select-Object -First 1
    if (-not $Manifest) {
        $script:Manifest = $candidates | Sort-Object { $_.FullName.Length } | Select-Object -First 1
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
        @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) |
            ForEach-Object { $_.Name })
    }

    function Get-HelpComment {
        param([Parameter(Mandatory)][string] $Path)

        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
        @($tokens | Where-Object {
            $_.Kind -eq 'Comment' -and $_.Text -match '(?im)^\s*<#[\s\S]*\.SYNOPSIS'
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
        $ExportedFunctions | Should -Not -Contain '*'
        $ExportedFunctions.Count | Should -BeGreaterThan 0
    }

    It 'exports no cmdlets, variables, or aliases implicitly' -ForEach @(
        @{ Key = 'CmdletsToExport' }
        @{ Key = 'VariablesToExport' }
        @{ Key = 'AliasesToExport' }
    ) {
        $ManifestData.ContainsKey($Key) | Should -BeTrue -Because "$Key left unset defaults to a wildcard"
        @($ManifestData[$Key]) | Should -Not -Contain '*'
    }

    It 'declares the PowerShell editions it claims to support' {
        $ManifestData.CompatiblePSEditions | Should -Not -BeNullOrEmpty
    }
}

Describe 'Public surface' -Tag 'Universal' {

    It 'defines every function the manifest exports somewhere in source' {
        $defined = @(
            Get-ChildItem -Path $SrcRoot -Filter *.ps1 -File -Recurse |
                ForEach-Object { Get-DefinedFunctionName -Path $_.FullName }
        )
        $missing = @($ExportedFunctions | Where-Object { $_ -notin $defined })
        $missing | Should -BeNullOrEmpty -Because 'an exported function that does not exist fails at import, not at call'
    }

    # <_.Name>, not <_>: expanding a FileInfo stamps its absolute FullName into
    # the test name, so the name recorded in result.json changed with the
    # target's location and scores could not be diffed between runs.
    It 'gives <_.Name> comment-based help with a synopsis' -ForEach $PublicFiles {
        # $_ is the FileInfo for one public function file.
        # @() around the call: a function returning a one-element array has it
        # unrolled to a scalar by the pipeline, and .Count on a scalar throws
        # under Set-StrictMode -Version Latest.
        @(Get-HelpComment -Path $_.FullName).Count |
            Should -BeGreaterThan 0 -Because 'Get-Help on an exported command should return something'
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
        $BuildText | Should -Match "(?m)^\s*task\s+$_\b"
    }

    It 'makes the default task Clean, Lint, Build, Test' {
        $BuildText | Should -Match '(?m)^\s*task\s+\.\s+Clean,\s*Lint,\s*Build,\s*Test'
    }

    It 'excludes PreTag-tagged tests from the Test task' {
        # A half-finished iteration must still be able to build green.
        $BuildText | Should -Match "Filter\.ExcludeTag\s*=\s*'PreTag'"
    }

    It 'throws rather than exits when tests fail' {
        # Run.Exit makes Pester call exit, which can kill the host process.
        $BuildText | Should -Match 'Run\.Throw\s*=\s*\$true'
        $BuildText | Should -Not -Match 'Run\.Exit\s*=\s*\$true'
    }

    It 'disables Pester v5 assertion syntax' {
        $BuildText | Should -Match 'Should\.DisableV5\s*=\s*\$true'
    }

    It 'measures coverage against the built psm1, not the source tree' {
        $BuildText | Should -Match 'CodeCoverage\.Path\s*=.*psm1'
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

        $tokens = $null
        $errors = $null
        $buildAst = [System.Management.Automation.Language.Parser]::ParseFile(
            $BuildFile, [ref]$tokens, [ref]$errors)
        @($errors).Count | Should -Be 0 -Because 'a build file that does not parse cannot be checked'

        # InvokeBuild spells a task 'task <Name> [<deps>,] { ... }', so the name
        # is the second command element whether or not dependencies follow.
        $testTask = @($buildAst.FindAll({
                    param($n)
                    $n -is [System.Management.Automation.Language.CommandAst] -and
                    $n.GetCommandName() -eq 'task' -and
                    @($n.CommandElements).Count -gt 1 -and
                    $n.CommandElements[1].Extent.Text -eq 'Test'
                }, $true))
        $testTask.Count | Should -Be 1 -Because 'the coverage gate lives in the Test task'

        # FindAll is pre-order, so the task's own body comes before anything
        # nested in it. Not CommandElements: with dependencies present the body
        # is inside an array literal, not a top-level element.
        $body = @($testTask[0].FindAll({
                    param($n) $n -is [System.Management.Automation.Language.ScriptBlockExpressionAst]
                }, $true)) | Select-Object -First 1
        $body | Should -Not -BeNullOrEmpty -Because 'the Test task must have a body to gate anything'

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
