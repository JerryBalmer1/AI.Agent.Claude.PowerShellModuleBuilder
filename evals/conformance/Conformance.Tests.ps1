#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0' }

<#
    Conformance suite for PowerShell module repositories.

    The target repository is passed in $env:CONFORMANCE_TARGET. Nothing here
    imports or executes the module under test; every assertion reads the source
    tree, the manifest, the build file, or the generated psm1 as text.

    Tags:
      Universal    - true of any well-formed PowerShell module repository
      HouseStyle   - specific to the PSModuleGraph build conventions
      RequiresBuild- needs output/<Name>/ to exist, so run after a build

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
    $script:Manifest = Get-ChildItem -Path $Target -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.BaseName -eq $_.Directory.Name } |
        Where-Object { $_.FullName -notmatch '[\\/](output|scratch|\.git)[\\/]' } |
        Sort-Object { $_.FullName.Length } |
        Select-Object -First 1

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

    It 'gives <_> comment-based help with a synopsis' -ForEach $PublicFiles {
        # $_ is the FileInfo for one public function file.
        (Get-HelpComment -Path $_.FullName).Count |
            Should -BeGreaterThan 0 -Because 'Get-Help on an exported command should return something'
    }
}

Describe 'Repository shape' -Tag 'Universal' {

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

    It 'has a test file for the exported command <_.BaseName>' -ForEach $PublicFiles {
        $candidates = @(Get-ChildItem -Path $TestsRoot -Filter "$($_.BaseName).Tests.ps1" -File -Recurse -ErrorAction SilentlyContinue)
        $candidates.Count | Should -BeGreaterThan 0
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
        $names = Get-DefinedFunctionName -Path $_.FullName
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
        # against a target of 75 through three green builds.
        $BuildText | Should -Match '(?s)CoveragePercent.*throw'
    }
}

Describe 'House style: generated module' -Tag 'HouseStyle', 'RequiresBuild' {

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