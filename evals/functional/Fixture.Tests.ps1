#Requires -Module @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0' }

<#
    Acceptance test for the PSAzureDevOpsGraph functional fixture.

    This test reads committed files only. It never contacts Azure DevOps, never
    reads a PAT, and never imports PSAzureDevOpsGraph. It asserts one thing: that
    the fixture is internally consistent — that the YAML on disk and the graph
    declared in expected-graph.json are statements about the same thing.

    The load-bearing assertion is 6. expected-graph.json is written by hand as an
    independent statement of the right answer, which is only worth something for
    as long as it still describes the YAML beside it. Assertion 6 compares the
    two in both directions, so neither can drift without a red.

    Nothing here checks that a reference *resolves* to the right target. That is
    deliberate. Resolution is what the module under test has to compute, and an
    oracle checked by a resolver is only as good as the resolver.
#>

BeforeDiscovery {
    $script:FixtureRoot = Join-Path $PSScriptRoot 'fixture'
    $script:ReposRoot = Join-Path $script:FixtureRoot 'repos'
    $script:GraphPath = Join-Path $script:FixtureRoot 'expected-graph.json'
    $script:SchemaPath = Join-Path $script:FixtureRoot 'graph.schema.json'
    $script:CasesPath = Join-Path $script:FixtureRoot 'cases.md'

    # Discovery must not throw when the fixture is absent: a missing fixture is
    # a red, not a crash, and the red has to name which file is missing.
    $script:YamlFiles = @()
    if (Test-Path -LiteralPath $script:ReposRoot) {
        $script:YamlFiles = @(
            Get-ChildItem -LiteralPath $script:ReposRoot -Recurse -File |
                Where-Object { $_.Extension -in '.yml', '.yaml' } |
                Sort-Object FullName |
                ForEach-Object {
                    [pscustomobject]@{
                        Full     = $_.FullName
                        Relative = ($_.FullName.Substring($script:FixtureRoot.Length + 1) -replace '\\', '/')
                    }
                }
        )
    }

    $script:Graph = $null
    if (Test-Path -LiteralPath $script:GraphPath) {
        try {
            $script:Graph = Get-Content -LiteralPath $script:GraphPath -Raw | ConvertFrom-Json
        }
        catch {
            $script:Graph = $null
        }
    }

    $script:NodeCases = @()
    $script:EdgeCases = @()
    if ($script:Graph) {
        if ($script:Graph.PSObject.Properties.Name -contains 'nodes') {
            $script:NodeCases = @(
                $script:Graph.nodes | ForEach-Object {
                    [pscustomobject]@{
                        Id   = $_.id
                        Kind = $_.kind
                        Path = $(if ($_.PSObject.Properties.Name -contains 'path') { $_.path } else { $null })
                    }
                }
            )
        }
        if ($script:Graph.PSObject.Properties.Name -contains 'edges') {
            $n = 0
            $script:EdgeCases = @(
                $script:Graph.edges | ForEach-Object {
                    $n++
                    [pscustomobject]@{
                        Index = $n
                        From  = $_.from
                        To    = $_.to
                        Kind  = $_.kind
                        Ref   = $(if ($_.PSObject.Properties.Name -contains 'ref') { $_.ref } else { $null })
                    }
                }
            )
        }
    }

    $script:UnresolvedEdgeCases = @($script:EdgeCases | Where-Object { $_.Kind -eq 'unresolved' })
}

BeforeAll {
    $script:FixtureRoot = Join-Path $PSScriptRoot 'fixture'
    $script:ReposRoot = Join-Path $script:FixtureRoot 'repos'
    $script:GraphPath = Join-Path $script:FixtureRoot 'expected-graph.json'
    $script:SchemaPath = Join-Path $script:FixtureRoot 'graph.schema.json'
    $script:CasesPath = Join-Path $script:FixtureRoot 'cases.md'

    # ------------------------------------------------------------------
    # A deliberately small block-YAML reader.
    #
    # There is no YAML parser in a fresh pwsh, and verify.ps1 may assume
    # nothing but a fresh clone. So the fixture is held to a subset this
    # reader accepts, and the reader is strict: tabs, stray indentation,
    # duplicate keys and lines that are neither a mapping entry nor a
    # sequence item all throw. That strictness is what makes "parses as
    # YAML" an assertion rather than a formality.
    # ------------------------------------------------------------------

    $script:KeyPattern = [regex]'^([A-Za-z0-9_.$-]+)[ ]*:(?:[ ]+(.*))?$'
    $script:KeyStartPattern = [regex]'^([A-Za-z0-9_.$-]+)[ ]*:([ ]|$)'

    function Remove-FixtureYamlComment {
        param([string]$Line)
        $inSingle = $false
        $inDouble = $false
        for ($k = 0; $k -lt $Line.Length; $k++) {
            $c = $Line[$k]
            if ($c -eq "'" -and -not $inDouble) { $inSingle = -not $inSingle; continue }
            if ($c -eq '"' -and -not $inSingle) { $inDouble = -not $inDouble; continue }
            if ($c -eq '#' -and -not $inSingle -and -not $inDouble) {
                if ($k -eq 0 -or $Line[$k - 1] -eq ' ') { return $Line.Substring(0, $k) }
            }
        }
        return $Line
    }

    function ConvertTo-FixtureYamlScalar {
        param([string]$Text)
        $t = $Text.Trim()
        if ($t.Length -ge 2 -and $t.StartsWith("'") -and $t.EndsWith("'")) { return $t.Substring(1, $t.Length - 2) }
        if ($t.Length -ge 2 -and $t.StartsWith('"') -and $t.EndsWith('"')) { return $t.Substring(1, $t.Length - 2) }
        return $t
    }

    function Read-FixtureYamlMapping {
        param($Lines, [ref]$Index, [int]$Indent, [string]$Source)
        $map = [ordered]@{}
        while ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -eq $Indent) {
            $line = $Lines[$Index.Value]
            if ($line.Text -eq '-' -or $line.Text.StartsWith('- ')) { break }
            $m = $script:KeyPattern.Match($line.Text)
            if (-not $m.Success) {
                throw "${Source}: line $($line.Number) is neither a mapping entry nor a sequence item: '$($line.Text)'"
            }
            $key = $m.Groups[1].Value
            if ($map.Contains($key)) { throw "${Source}: line $($line.Number) repeats the key '$key' in one mapping." }
            $inline = if ($m.Groups[2].Success) { $m.Groups[2].Value.Trim() } else { '' }
            $Index.Value++
            if ($inline -ne '') {
                $map[$key] = ConvertTo-FixtureYamlScalar $inline
                continue
            }
            if ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -gt $Indent) {
                $map[$key] = Read-FixtureYamlBlock -Lines $Lines -Index $Index -Indent $Lines[$Index.Value].Indent -Source $Source
            }
            elseif ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -eq $Indent -and
                ($Lines[$Index.Value].Text -eq '-' -or $Lines[$Index.Value].Text.StartsWith('- '))) {
                $seq = Read-FixtureYamlSequence -Lines $Lines -Index $Index -Indent $Indent -Source $Source
                $map[$key] = $seq
            }
            else {
                $map[$key] = $null
            }
        }
        return $map
    }

    function Read-FixtureYamlSequence {
        param($Lines, [ref]$Index, [int]$Indent, [string]$Source)
        $items = [System.Collections.Generic.List[object]]::new()
        while ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -eq $Indent -and
            ($Lines[$Index.Value].Text -eq '-' -or $Lines[$Index.Value].Text.StartsWith('- '))) {
            $line = $Lines[$Index.Value]
            $after = if ($line.Text -eq '-') { '' } else { $line.Text.Substring(2) }
            $rest = $after.TrimStart()
            if ($rest -eq '') {
                $Index.Value++
                if ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -gt $Indent) {
                    $items.Add((Read-FixtureYamlBlock -Lines $Lines -Index $Index -Indent $Lines[$Index.Value].Indent -Source $Source))
                }
                else {
                    $items.Add($null)
                }
                continue
            }
            $inner = $Indent + 2 + ($after.Length - $rest.Length)
            if ($script:KeyStartPattern.IsMatch($rest)) {
                # An inline mapping. Rewrite this line as the mapping's first
                # entry at the column the content actually starts in, so the
                # item's continuation lines fall out of the normal indent rule.
                $line.Indent = $inner
                $line.Text = $rest
                $items.Add((Read-FixtureYamlMapping -Lines $Lines -Index $Index -Indent $inner -Source $Source))
                continue
            }
            $items.Add((ConvertTo-FixtureYamlScalar $rest))
            $Index.Value++
            if ($Index.Value -lt $Lines.Count -and $Lines[$Index.Value].Indent -gt $Indent) {
                throw "${Source}: line $($Lines[$Index.Value].Number) is indented under the scalar sequence item on line $($line.Number)."
            }
        }
        return , $items
    }

    function Read-FixtureYamlBlock {
        param($Lines, [ref]$Index, [int]$Indent, [string]$Source)
        $first = $Lines[$Index.Value]
        if ($first.Text -eq '-' -or $first.Text.StartsWith('- ')) {
            $seq = Read-FixtureYamlSequence -Lines $Lines -Index $Index -Indent $Indent -Source $Source
            return , $seq
        }
        return Read-FixtureYamlMapping -Lines $Lines -Index $Index -Indent $Indent -Source $Source
    }

    function ConvertFrom-FixtureYaml {
        param([Parameter(Mandatory)][AllowEmptyString()][string]$Text, [string]$Source = '<text>')
        $raw = $Text -split "`r?`n"
        $lines = [System.Collections.Generic.List[object]]::new()
        for ($n = 0; $n -lt $raw.Count; $n++) {
            $line = $raw[$n]
            if ($line -match "`t") { throw "${Source}: line $($n + 1) contains a tab character." }
            $stripped = Remove-FixtureYamlComment $line
            if ($stripped.Trim() -eq '') { continue }
            if ($stripped -eq '---') { continue }
            $indent = $stripped.Length - $stripped.TrimStart(' ').Length
            $lines.Add([pscustomobject]@{
                    Indent = $indent
                    Text   = $stripped.Trim()
                    Number = $n + 1
                })
        }
        if ($lines.Count -eq 0) { throw "${Source}: no YAML content." }
        if ($lines[0].Indent -ne 0) { throw "${Source}: line $($lines[0].Number) is indented but nothing is open above it." }
        $i = 0
        $value = Read-FixtureYamlBlock -Lines $lines -Index ([ref]$i) -Indent 0 -Source $Source
        if ($i -lt $lines.Count) {
            throw "${Source}: line $($lines[$i].Number) ('$($lines[$i].Text)') does not belong to any open block."
        }
        if ($value -is [System.Collections.IList]) { return , $value }
        return $value
    }

    # ------------------------------------------------------------------
    # Reference extraction, structural: walk the parsed document and emit
    # one record per reference, keyed by the exact key name and its path.
    # A parameter called `buildTemplate` is not a key called `template`,
    # which is the whole of case 3.
    # ------------------------------------------------------------------

    function Get-FixtureYamlReference {
        param($Node, [string[]]$Path = @())

        if ($Node -is [System.Collections.IDictionary]) {
            foreach ($key in @($Node.Keys)) {
                $value = $Node[$key]
                $childPath = @($Path) + $key
                if ($value -is [string]) {
                    if ($key -eq 'template') {
                        $kind = if ($Path.Count -gt 0 -and $Path[-1] -eq 'extends') { 'extends' } else { 'template' }
                        [pscustomobject]@{ Kind = $kind; Ref = $value; Alias = $null; At = ($childPath -join '.') }
                    }
                    elseif ($key -eq 'checkout') {
                        [pscustomobject]@{ Kind = 'checkout'; Ref = $value; Alias = $null; At = ($childPath -join '.') }
                    }
                    elseif ($key -eq 'name' -and $Path.Count -ge 3 -and $Path[0] -eq 'resources' -and $Path[1] -eq 'repositories') {
                        $alias = if ($Node.Contains('repository')) { $Node['repository'] } else { $null }
                        [pscustomobject]@{ Kind = 'repositoryResource'; Ref = $value; Alias = $alias; At = ($childPath -join '.') }
                    }
                    elseif ($key -eq 'source' -and $Path.Count -ge 3 -and $Path[0] -eq 'resources' -and $Path[1] -eq 'pipelines') {
                        $alias = if ($Node.Contains('pipeline')) { $Node['pipeline'] } else { $null }
                        [pscustomobject]@{ Kind = 'pipelineResource'; Ref = $value; Alias = $alias; At = ($childPath -join '.') }
                    }
                }
                else {
                    Get-FixtureYamlReference -Node $value -Path $childPath
                }
            }
        }
        elseif ($Node -is [System.Collections.IList]) {
            for ($n = 0; $n -lt $Node.Count; $n++) {
                Get-FixtureYamlReference -Node $Node[$n] -Path (@($Path) + "[$n]")
            }
        }
    }

    # ------------------------------------------------------------------
    # Fixture load
    # ------------------------------------------------------------------

    $script:Graph = $null
    if (Test-Path -LiteralPath $script:GraphPath) {
        $script:Graph = Get-Content -LiteralPath $script:GraphPath -Raw | ConvertFrom-Json
    }

    $script:NodeIds = @()
    $script:Nodes = @()
    $script:Edges = @()
    if ($script:Graph) {
        $script:Nodes = @($script:Graph.nodes)
        $script:Edges = @($script:Graph.edges)
        $script:NodeIds = @($script:Nodes | ForEach-Object { $_.id })
    }

    # Edges whose existence is a claim about the YAML text. `definition` edges
    # are a claim about the Azure DevOps project, not about a file, so they are
    # outside assertion 6 by construction.
    $script:YamlDerivedKinds = @('template', 'extends', 'repositoryResource', 'pipelineResource', 'checkout')

    function Get-FixtureDeclaredReference {
        param([string]$SourceNodeId)
        foreach ($edge in $script:Edges) {
            if ($edge.from -ne $SourceNodeId) { continue }
            $kind = $edge.kind
            if ($kind -eq 'unresolved') {
                if ($edge.PSObject.Properties.Name -notcontains 'refKind') { continue }
                $kind = $edge.refKind
            }
            if ($kind -notin $script:YamlDerivedKinds) { continue }
            if ($edge.PSObject.Properties.Name -notcontains 'ref') { continue }
            [pscustomobject]@{ Kind = $kind; Ref = $edge.ref }
        }
    }

    function Get-FixtureNodeIdForFile {
        param([string]$RelativePath)
        $match = @($script:Nodes | Where-Object { $_.kind -eq 'yaml' -and $_.path -eq $RelativePath })
        if ($match.Count -eq 1) { return $match[0].id }
        return $null
    }
}

Describe 'Functional fixture' {

    Context 'The fixture exists' {

        It 'has expected-graph.json' {
            Test-Path -LiteralPath $script:GraphPath | Should -BeTrue -Because 'the declared answer is the point of the fixture'
        }

        It 'has graph.schema.json' {
            Test-Path -LiteralPath $script:SchemaPath | Should -BeTrue
        }

        It 'has cases.md' {
            Test-Path -LiteralPath $script:CasesPath | Should -BeTrue
        }

        It 'has YAML under repos/' {
            @(Get-ChildItem -LiteralPath $script:ReposRoot -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in '.yml', '.yaml' }).Count |
                Should -BeGreaterThan 0
        }
    }

    Context 'Assertion 1 — expected-graph.json parses and validates' {

        It 'parses as JSON' {
            { Get-Content -LiteralPath $script:GraphPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop } |
                Should -Not -Throw
        }

        It 'validates against graph.schema.json' {
            $json = Get-Content -LiteralPath $script:GraphPath -Raw -ErrorAction Stop
            $schema = Get-Content -LiteralPath $script:SchemaPath -Raw -ErrorAction Stop
            Test-Json -Json $json -Schema $schema -ErrorAction Stop | Should -BeTrue
        }
    }

    Context 'Assertion 2 — every node is well formed' {

        It 'node ids are unique' {
            # The count guard is not decoration. On the red-first run, with no
            # fixture on disk at all, this assertion passed: zero ids contain no
            # duplicates. An assertion that is green against an empty fixture is
            # inert, and this project has already paid for one of those.
            $script:NodeIds.Count | Should -BeGreaterThan 0
            $dupes = @($script:NodeIds | Group-Object | Where-Object Count -GT 1 | ForEach-Object Name)
            $dupes -join ', ' | Should -BeNullOrEmpty -Because 'a repeated id silently merges two nodes'
        }

        It 'node <_.Id> has a kind in the declared enum' -ForEach $script:NodeCases {
            $_.Kind | Should -BeIn @('pipeline', 'yaml', 'repo')
        }

        It 'yaml node <_.Id> points at a file that exists' -ForEach @($script:NodeCases | Where-Object Kind -EQ 'yaml') {
            $_.Path | Should -Not -BeNullOrEmpty
            $_.Path | Should -BeLike 'repos/*' -Because 'yaml node paths are relative to the fixture root'
            Test-Path -LiteralPath (Join-Path $script:FixtureRoot $_.Path) | Should -BeTrue
        }
    }

    Context 'Assertion 3 — every edge endpoint resolves, except where it must not' {

        It 'edge <_.Index> (<_.Kind>) has a from that resolves: <_.From>' -ForEach $script:EdgeCases {
            $script:NodeIds | Should -Contain $_.From
        }

        It 'edge <_.Index> (<_.Kind>) has a to that resolves: <_.To>' -ForEach @($script:EdgeCases | Where-Object Kind -NE 'unresolved') {
            $script:NodeIds | Should -Contain $_.To
        }

        It 'unresolved edge <_.Index> has a to that does NOT resolve: <_.To>' -ForEach $script:UnresolvedEdgeCases {
            $script:NodeIds | Should -Not -Contain $_.To -Because 'an unresolved edge that resolves is not testing anything'
        }

        It 'every unresolved edge states a reason' -ForEach $script:UnresolvedEdgeCases {
            $edge = @($script:Edges)[$_.Index - 1]
            $edge.reason | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Assertion 4 — no orphan files, no dangling nodes' {

        It 'YAML file <_.Relative> has a declared node' -ForEach $script:YamlFiles {
            Get-FixtureNodeIdForFile -RelativePath $_.Relative | Should -Not -BeNullOrEmpty
        }

        It 'every yaml node corresponds to a file on disk' {
            $declared = @($script:Nodes | Where-Object kind -EQ 'yaml' | ForEach-Object { $_.path })
            $onDisk = @(Get-ChildItem -LiteralPath $script:ReposRoot -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.Extension -in '.yml', '.yaml' } |
                    ForEach-Object { ($_.FullName.Substring($script:FixtureRoot.Length + 1) -replace '\\', '/') })
            $missing = @($declared | Where-Object { $_ -notin $onDisk })
            $extra = @($onDisk | Where-Object { $_ -notin $declared })
            "declared-but-absent: $($missing -join ', '); on-disk-but-undeclared: $($extra -join ', ')" |
                Should -Be 'declared-but-absent: ; on-disk-but-undeclared: '
        }
    }

    Context 'Assertion 5 — every YAML file parses' {

        It '<_.Relative> parses as YAML' -ForEach $script:YamlFiles {
            $text = Get-Content -LiteralPath $_.Full -Raw
            { ConvertFrom-FixtureYaml -Text $text -Source $_.Relative } | Should -Not -Throw
        }
    }

    Context 'Assertion 6 — the declared graph and the YAML agree' {

        It '<_.Relative>: every reference in the YAML is a declared edge' -ForEach $script:YamlFiles {
            $nodeId = Get-FixtureNodeIdForFile -RelativePath $_.Relative
            $nodeId | Should -Not -BeNullOrEmpty -Because 'a file with no node cannot have its references checked'

            $doc = ConvertFrom-FixtureYaml -Text (Get-Content -LiteralPath $_.Full -Raw) -Source $_.Relative
            $found = @(Get-FixtureYamlReference -Node $doc |
                    Where-Object { -not ($_.Kind -eq 'checkout' -and $_.Ref -in 'self', 'none') })
            $declared = @(Get-FixtureDeclaredReference -SourceNodeId $nodeId)

            $foundKeys = @($found | ForEach-Object { "$($_.Kind)|$($_.Ref)" } | Sort-Object)
            $declaredKeys = @($declared | ForEach-Object { "$($_.Kind)|$($_.Ref)" } | Sort-Object)

            $undeclared = @($foundKeys | Where-Object { $_ -notin $declaredKeys })
            $undeclared -join ' ; ' | Should -BeNullOrEmpty -Because "the YAML of $($_.Relative) references something the graph does not declare"
        }

        It '<_.Relative>: every declared edge is found in the YAML' -ForEach $script:YamlFiles {
            $nodeId = Get-FixtureNodeIdForFile -RelativePath $_.Relative
            $nodeId | Should -Not -BeNullOrEmpty

            $doc = ConvertFrom-FixtureYaml -Text (Get-Content -LiteralPath $_.Full -Raw) -Source $_.Relative
            $found = @(Get-FixtureYamlReference -Node $doc |
                    Where-Object { -not ($_.Kind -eq 'checkout' -and $_.Ref -in 'self', 'none') })
            $declared = @(Get-FixtureDeclaredReference -SourceNodeId $nodeId)

            $foundKeys = @($found | ForEach-Object { "$($_.Kind)|$($_.Ref)" } | Sort-Object)
            $declaredKeys = @($declared | ForEach-Object { "$($_.Kind)|$($_.Ref)" } | Sort-Object)

            $phantom = @($declaredKeys | Where-Object { $_ -notin $foundKeys })
            $phantom -join ' ; ' | Should -BeNullOrEmpty -Because "the graph declares an edge out of $($_.Relative) that its YAML does not contain"
        }

        It 'no declared yaml-derived edge leaves a node that is not a yaml file' {
            $yamlNodeIds = @($script:Nodes | Where-Object kind -EQ 'yaml' | ForEach-Object { $_.id })
            $stray = @(
                $script:Edges | Where-Object {
                    $k = $(if ($_.kind -eq 'unresolved') { $_.refKind } else { $_.kind })
                    $k -in $script:YamlDerivedKinds -and $_.from -notin $yamlNodeIds
                } | ForEach-Object { "$($_.from) -> $($_.to)" }
            )
            $stray -join ' ; ' | Should -BeNullOrEmpty
        }
    }

    Context 'Assertion 7 — the cases are all present on both sides' {

        BeforeAll {
            $script:DeclaredCaseIds = @()
            if (Test-Path -LiteralPath $script:CasesPath) {
                $script:DeclaredCaseIds = @(
                    [regex]::Matches((Get-Content -LiteralPath $script:CasesPath -Raw), '(?m)^##\s+(case-\d{2})\b') |
                        ForEach-Object { $_.Groups[1].Value }
                )
            }
            $script:GraphCaseIds = @(
                @($script:Nodes) + @($script:Edges) |
                    Where-Object { $_ -and $_.PSObject.Properties.Name -contains 'cases' } |
                    ForEach-Object { $_.cases } |
                    Sort-Object -Unique
            )
        }

        It 'cases.md declares exactly ten cases' {
            $script:DeclaredCaseIds.Count | Should -Be 10
        }

        It 'cases.md declares no duplicate case id' {
            @($script:DeclaredCaseIds | Sort-Object -Unique).Count | Should -Be $script:DeclaredCaseIds.Count
        }

        It 'every case id in cases.md is carried by at least one node or edge' {
            $orphanCases = @($script:DeclaredCaseIds | Where-Object { $_ -notin $script:GraphCaseIds })
            $orphanCases -join ', ' | Should -BeNullOrEmpty
        }

        It 'every case id in the graph is declared in cases.md' {
            $inventedCases = @($script:GraphCaseIds | Where-Object { $_ -notin $script:DeclaredCaseIds })
            $inventedCases -join ', ' | Should -BeNullOrEmpty
        }

        It 'the graph carries all ten case ids' {
            $script:GraphCaseIds.Count | Should -Be 10
        }
    }
}
