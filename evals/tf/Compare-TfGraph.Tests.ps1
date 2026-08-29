#Requires -Version 7.2
<#
    The comparator's own suite. Written and run RED before Compare-TfGraph.ps1
    and Mutate-TfGraph.ps1 existed.

    A comparator is the one tool in a scoring harness that nothing else checks.
    If it under-reports, every score it produces is flattering and nothing says
    so; the seven mutations exist because "it found the differences we showed
    it" is not the same claim as "it finds differences".
#>

BeforeAll {
    $script:Root = $PSScriptRoot
    $script:Compare = Join-Path $script:Root 'Compare-TfGraph.ps1'
    $script:Mutate = Join-Path $script:Root 'Mutate-TfGraph.ps1'
    $script:Oracle = Join-Path $script:Root 'fixture/expected-graph.json'
}

Describe 'The comparator exists and is runnable' {
    It 'has both scripts' {
        Test-Path -LiteralPath $script:Compare | Should-BeTrue
        Test-Path -LiteralPath $script:Mutate | Should-BeTrue
    }
}

Describe 'Oracle against itself is the control' {
    It 'reports zero differences comparing the oracle with itself' {
        # The control. Every red below is meaningless if this is not green:
        # a comparator that reports differences between a document and itself
        # is reporting on its own defects.
        $result = & $script:Compare -Expected $script:Oracle -Actual $script:Oracle
        $result.DifferenceCount | Should-Be 0
        $result.IsMatch | Should-BeTrue
    }

    It 'states what it compared, not just that it matched' {
        # A comparator that says "match" without saying how much it looked at
        # passes an empty document against an empty document.
        $result = & $script:Compare -Expected $script:Oracle -Actual $script:Oracle
        $result.ExpectedNodeCount | Should-Be 78
        $result.ExpectedEdgeCount | Should-Be 57
    }
}

Describe 'Every mutation mechanism is detected' -ForEach @(
    @{ Mutation = 'missing-node'; Category = 'MissingNode' }
    @{ Mutation = 'extra-node'; Category = 'ExtraNode' }
    @{ Mutation = 'wrong-attribute'; Category = 'WrongAttribute' }
    @{ Mutation = 'wrong-parent'; Category = 'WrongParent' }
    @{ Mutation = 'missing-edge'; Category = 'MissingEdge' }
    @{ Mutation = 'extra-edge'; Category = 'ExtraEdge' }
    @{ Mutation = 'wrong-edge-kind'; Category = 'WrongEdgeKind' }
) {
    It 'detects <Mutation> and categorises it as <Category>' {
        $mutated = & $script:Mutate -Path $script:Oracle -Mutation $Mutation

        # The probe's own control: the mutation must have changed the document
        # before its detection means anything.
        $original = Get-Content -LiteralPath $script:Oracle -Raw
        ($mutated | ConvertTo-Json -Depth 30) | Should-NotBe $original

        $result = & $script:Compare -Expected $script:Oracle -ActualObject $mutated
        $result.IsMatch | Should-BeFalse
        $result.DifferenceCount | Should-BeGreaterThan 0
        @($result.Differences | ForEach-Object { $_.Category }) | Should-ContainCollection $Category
    }
}

Describe 'A difference names the thing that differs' {
    It 'names the node id for a missing node' {
        $mutated = & $script:Mutate -Path $script:Oracle -Mutation 'missing-node'
        $result = & $script:Compare -Expected $script:Oracle -ActualObject $mutated
        $missing = @($result.Differences | Where-Object { $_.Category -eq 'MissingNode' })
        @($missing).Count | Should-BeGreaterThan 0
        $missing[0].Id | Should-NotBeEmptyString
    }

    It 'produces a human diff as well as an object' {
        $mutated = & $script:Mutate -Path $script:Oracle -Mutation 'missing-edge'
        $result = & $script:Compare -Expected $script:Oracle -ActualObject $mutated
        $result.Diff | Should-NotBeEmptyString
        $result.Diff | Should-MatchString 'MissingEdge'
    }

    It 'sorts stably, so two runs produce the same diff' {
        # A diff whose order changes between runs cannot be compared against a
        # committed one, and every scoring run would look like a regression.
        $mutated = & $script:Mutate -Path $script:Oracle -Mutation 'extra-node'
        $first = (& $script:Compare -Expected $script:Oracle -ActualObject $mutated).Diff
        $second = (& $script:Compare -Expected $script:Oracle -ActualObject $mutated).Diff
        $first | Should-Be $second
    }
}

Describe 'The comparator does not confuse one mechanism for another' {
    It 'reports a changed edge kind as WrongEdgeKind, not as one missing and one extra' {
        # The distinction that makes a score readable. An edge whose kind moved
        # is one defect; reported as a removal plus an addition it reads as two,
        # and the reader cannot tell it from an unrelated pair.
        $mutated = & $script:Mutate -Path $script:Oracle -Mutation 'wrong-edge-kind'
        $result = & $script:Compare -Expected $script:Oracle -ActualObject $mutated
        @($result.Differences | Where-Object { $_.Category -eq 'WrongEdgeKind' }).Count | Should-Be 1
        @($result.Differences | Where-Object { $_.Category -eq 'MissingEdge' }).Count | Should-Be 0
        @($result.Differences | Where-Object { $_.Category -eq 'ExtraEdge' }).Count | Should-Be 0
    }

    It 'reports a moved parent as WrongParent, not as a missing and an extra node' {
        $mutated = & $script:Mutate -Path $script:Oracle -Mutation 'wrong-parent'
        $result = & $script:Compare -Expected $script:Oracle -ActualObject $mutated
        @($result.Differences | Where-Object { $_.Category -eq 'WrongParent' }).Count | Should-Be 1
        @($result.Differences | Where-Object { $_.Category -eq 'MissingNode' }).Count | Should-Be 0
    }
}
