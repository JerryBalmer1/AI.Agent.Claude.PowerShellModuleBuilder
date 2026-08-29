<#
    ReadBack.Tests.ps1 - the acceptance test for the Azure DevOps fixture.

    WHAT THIS TEST PROVES, AND WHAT IT DOES NOT.

    It proves the push landed: that the objects named in AZDO-FIXTURE.md exist in
    Azure DevOps and that the bytes on the server are the bytes in this
    repository. It does NOT prove the graph is correct. The hand-authored
    fixture/expected-graph.json is the only claim about correctness, and a green
    run here says nothing about it. The two claims are separate and must stay
    separate: read-back green plus expected-graph wrong is a perfectly possible
    state, and this file cannot detect it.

    It reads Azure DevOps and compares against committed files. It never writes,
    never creates, and never queues. Assertion 7 exists to catch it if that ever
    stops being true.

    HOW ASSERTION 3 COMPARES BYTES (the load-bearing one). Both sides are read as
    raw bytes with no line-ending translation, no encoding detection and no
    string conversion: the committed side with [IO.File]::ReadAllBytes, the
    server side with HttpClient's ReadAsByteArrayAsync. Each is hashed with
    SHA-256 and the hashes compared, with lengths reported on failure. Nothing in
    the path calls Get-Content, -split, -replace, Set-Content or Out-File, each
    of which translates line endings on Windows by default - and a comparison
    that translates both sides identically passes while the server is wrong. The
    fixture is canonically UTF-8 without BOM, LF-only, with a final newline. See
    AZDO-FIXTURE.md, "How assertion 3 compares bytes".

    Helpers are dot-sourced from AzdoClient.ps1 rather than declared here: a
    top-level `function` in a Pester 6.1.0 test file breaks every BeforeAll in
    the file, with a misleading loop-label error.

    Requires $env:AZDO_PAT. The PAT is never echoed, logged or written.
#>

BeforeDiscovery {
    . (Join-Path $PSScriptRoot 'AzdoClient.ps1')

    $spec = Get-FixtureSpec

    # Discovery-time data comes from committed files and AZDO-FIXTURE.md only.
    # Nothing here touches the network; the network is a run-time concern.
    $FixtureRepoNames = @($spec.Repositories | ForEach-Object { $_.Name })

    $CommittedFiles = @(Get-CommittedFixtureFile | ForEach-Object {
        @{ Repository = $_.Repository; Path = $_.Path; FullName = $_.FullName }
    })

    $DefinitionRows = @($spec.Definitions | ForEach-Object {
        @{ Name = $_.Name; Repository = $_.Repository; YamlPath = $_.YamlPath }
    })
}

Describe 'Azure DevOps read-back' {

    BeforeAll {
        . (Join-Path $PSScriptRoot 'AzdoClient.ps1')

        # Refuse to read anything outside the fixture's organisation and project.
        Assert-AzdoScope

        if (-not $env:AZDO_PAT) {
            throw 'AZDO_PAT is not set. See evals/functional/TROUBLESHOOTING.md.'
        }

        $script:Spec           = Get-FixtureSpec
        $script:FixtureRepos   = @($script:Spec.Repositories | ForEach-Object { $_.Name })
        $script:Committed      = @(Get-CommittedFixtureFile)

        # One fetch of remote state, shared by every assertion below.
        $script:AllRepos = @(Get-AzdoRepository)
        $script:RepoByName = @{}
        foreach ($r in $script:AllRepos) { $script:RepoByName[$r.name] = $r }

        $script:AllDefs = @(Get-AzdoDefinition -Full)
        $script:DefByName = @{}
        foreach ($d in $script:AllDefs) { $script:DefByName[$d.name] = $d }

        $script:RemoteItems = @{}
        foreach ($n in $script:FixtureRepos) {
            if ($script:RepoByName.ContainsKey($n)) {
                $script:RemoteItems[$n] = @(Get-AzdoRepoItem -RepositoryId $script:RepoByName[$n].id -Branch 'main')
            }
            else {
                $script:RemoteItems[$n] = @()
            }
        }
    }

    Context 'Assertion 1: the four fixture repositories exist by name' {
        It 'repository <_> exists' -ForEach $FixtureRepoNames {
            $script:RepoByName.ContainsKey($_) |
                Should -BeTrue -Because "AZDO-FIXTURE.md declares repository '$_'; the project has: $(($script:AllRepos | ForEach-Object { $_.name }) -join ', ')"
        }
    }

    Context 'Assertion 2: each fixture repository has default branch main' {
        It 'repository <_> defaults to refs/heads/main' -ForEach $FixtureRepoNames {
            $script:RepoByName.ContainsKey($_) |
                Should -BeTrue -Because "repository '$_' must exist before its default branch can be checked"
            $script:RepoByName[$_].defaultBranch |
                Should -Be 'refs/heads/main' -Because "the fixture is pushed to main and read back from main"
        }
    }

    Context 'Assertion 3: every committed file exists on main and is byte-identical' {
        It '<Repository>/<Path> is byte-identical on the server' -ForEach $CommittedFiles {
            $script:RepoByName.ContainsKey($Repository) |
                Should -BeTrue -Because "repository '$Repository' must exist before its files can be compared"

            $localBytes = [IO.File]::ReadAllBytes($FullName)
            $remoteBytes = Get-AzdoFileBytes -RepositoryId $script:RepoByName[$Repository].id -Path $Path -Branch 'main'

            $localHash  = Get-Sha256Hex -Bytes $localBytes
            $remoteHash = Get-Sha256Hex -Bytes $remoteBytes

            $remoteHash | Should -Be $localHash -Because @"
raw bytes differ for $Repository/$Path
  committed: $($localBytes.Length) bytes, CR=$(@($localBytes | Where-Object { $_ -eq 13 }).Count), LF=$(@($localBytes | Where-Object { $_ -eq 10 }).Count)
  server   : $($remoteBytes.Length) bytes, CR=$(@($remoteBytes | Where-Object { $_ -eq 13 }).Count), LF=$(@($remoteBytes | Where-Object { $_ -eq 10 }).Count)
A CR count of 0 on one side and non-zero on the other means a line-ending
translation happened somewhere between this repository and Azure DevOps.
"@
        }
    }

    Context 'Assertion 4: no file exists in the four repositories other than those 30' {
        It '<_> contains no file beyond the committed fixture' -ForEach $FixtureRepoNames {
            # Captured before any Where-Object, which rebinds $_ to its own
            # pipeline item and would otherwise silently compare a repo name
            # against a file object.
            $repoName = $_

            $expected = @($script:Committed |
                          Where-Object { $_.Repository -ceq $repoName } |
                          ForEach-Object { $_.Path } | Sort-Object)
            $actual = @($script:RemoteItems[$repoName] | Sort-Object)
            $extra  = @($actual | Where-Object { $expected -notcontains $_ })

            $extra.Count |
                Should -Be 0 -Because "these paths are on the server but not in fixture/repos/$repoName : $($extra -join ', ')"
            $actual.Count |
                Should -Be $expected.Count -Because "repository '$repoName' should hold exactly $($expected.Count) files"
        }
    }

    Context 'Assertion 5: all fifteen definitions exist, on the declared repository and path' {
        It 'definition <Name> targets <Repository>/<YamlPath>' -ForEach $DefinitionRows {
            $script:DefByName.ContainsKey($Name) |
                Should -BeTrue -Because "AZDO-FIXTURE.md declares definition '$Name'; the project has: $(($script:AllDefs | ForEach-Object { $_.name }) -join ', ')"

            $def = $script:DefByName[$Name]
            $def.repository.name |
                Should -Be $Repository -Because "definition '$Name' must be built from repository '$Repository'"
            $def.process.yamlFilename |
                Should -Be $YamlPath -Because "definition '$Name' must point at YAML path '$YamlPath'"
        }
    }

    Context 'Assertion 6: no definition exists beyond those fifteen' {
        It 'the project holds exactly the fifteen declared definitions' {
            $declared = @($script:Spec.Definitions | ForEach-Object { $_.Name } | Sort-Object)
            $actual   = @($script:AllDefs | ForEach-Object { $_.name } | Sort-Object)
            $extra    = @($actual | Where-Object { $declared -notcontains $_ })

            $extra.Count | Should -Be 0 -Because "undeclared definitions exist: $($extra -join ', ')"
            $actual.Count | Should -Be 15 -Because "AZDO-FIXTURE.md declares fifteen definitions"
        }
    }

    Context 'Assertion 7: every definition build count is zero' {
        # A safety assertion, not a correctness one. Nothing in this fixture may
        # ever run: two definitions would fail and thirteen would burn agent
        # minutes, and neither is the reason - the rule is the same for all
        # fifteen. This assertion stays in the suite permanently.
        It 'definition <Name> has never run' -ForEach $DefinitionRows {
            $script:DefByName.ContainsKey($Name) |
                Should -BeTrue -Because "definition '$Name' must exist before its run history can be checked"
            Get-AzdoBuildCount -DefinitionId $script:DefByName[$Name].id |
                Should -Be 0 -Because "no pipeline in this fixture may ever be queued, triggered or run"
        }
    }

    Context 'Assertion 8: ClaudeTesting exists, is empty, and no definition targets it' {
        # Case 12's external half. The repository is an absence case: it exists
        # in the project, no pipeline references it, and it must therefore not
        # appear in the graph. Nothing in expected-graph.json carries a case-12
        # tag, because tagging a node with it would assert the opposite.
        It 'the pre-existing ClaudeTesting repository still exists' {
            $script:RepoByName.ContainsKey('ClaudeTesting') |
                Should -BeTrue -Because 'it is case 12 and must be left exactly as found'
        }

        It 'the ClaudeTesting repository is still empty' {
            $repo = $script:RepoByName['ClaudeTesting']
            @(Get-AzdoRepoItem -RepositoryId $repo.id -Branch 'main').Count |
                Should -Be 0 -Because 'Pass 0013 must not push to it'
            [int]$repo.size |
                Should -Be 0 -Because 'an empty repository reports size 0'
        }

        It 'no definition targets the ClaudeTesting repository' {
            @($script:AllDefs | Where-Object { $_.repository.name -ceq 'ClaudeTesting' }).Count |
                Should -Be 0 -Because 'no pipeline may reference it, or it would stop being an absence case'
        }
    }
}
