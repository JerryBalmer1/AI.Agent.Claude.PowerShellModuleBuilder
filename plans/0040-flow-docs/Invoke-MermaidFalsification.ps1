#Requires -Version 7.2
<#
.SYNOPSIS
    Break the mirror four ways and confirm Compare-Mermaid.ps1 goes red for
    each, then confirm the control is green.
.DESCRIPTION
    A comparison that has only ever agreed is not evidence that it can
    disagree. Each break perturbs a COPY of README.md in a temporary root and
    asserts three things in order: that the substitution actually changed the
    file, that the check went red, and that it named the right node or edge.
    A break that matched nothing leaves the target intact and the resulting
    green would record as "does not fire" - the failure this harness exists to
    detect, manufactured by its own bookkeeping.
.PARAMETER RepoRoot
    Repository root. Defaults to two levels above this script.
#>
[CmdletBinding()]
param([string] $RepoRoot = "$PSScriptRoot/../..")

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$checker = Join-Path $RepoRoot 'plans/0040-flow-docs/Compare-Mermaid.ps1'
$readme = Get-Content -LiteralPath (Join-Path $RepoRoot 'README.md') -Raw

$rows = @(
    @{ Name = 'control - nothing changed'; Find = $null; Replace = $null; Expect = 'green'; Names = @() }
    @{ Name = 'a node deleted from the mirror'
       Find = "    skill-task-tree[`"task-tree-reporting`"]`n"; Replace = ''
       Expect = 'red'; Names = @('skill-task-tree') }
    @{ Name = 'a node moved to the wrong layer'
       Find = "  subgraph layer_module[`"4 · what gets built`"]`n    module-yours[`"your module`"]`n"
       Replace = "  subgraph layer_module[`"4 · what gets built`"]`n"
       Extra  = @{ Find = "    conformance[`"conformance suite`"]`n"
                   Replace = "    conformance[`"conformance suite`"]`n    module-yours[`"your module`"]`n" }
       Expect = 'red'; Names = @('LAYER differs', 'module-yours') }
    @{ Name = 'an edge reversed'
       Find = "  stage-new -->|1| stage-plan`n"; Replace = "  stage-plan -->|1| stage-new`n"
       Expect = 'red'; Names = @('stage-plan->stage-new', 'stage-new->stage-plan') }
    @{ Name = 'a label retyped'
       Find = "    tf-fixture-2[`"TF fixture 2`"]`n"; Replace = "    tf-fixture-2[`"TF fixture two`"]`n"
       Expect = 'red'; Names = @('label differs', 'tf-fixture-2') }
)

$work = Join-Path ([IO.Path]::GetTempPath()) ("mermaid-falsify-" + [guid]::NewGuid().ToString('n'))
$null = New-Item -ItemType Directory -Path (Join-Path $work 'docs/diagram') -Force
Copy-Item (Join-Path $RepoRoot 'docs/diagram/flow-graph.json') (Join-Path $work 'docs/diagram/flow-graph.json')

$failures = 0
try {
    'FALSIFICATION OF Compare-Mermaid.ps1'
    ''
    foreach ($row in $rows) {
        $text = $readme
        if ($row.Find) {
            if (-not $text.Contains($row.Find)) { throw "BREAK '$($row.Name)' matched nothing. The target is intact and any red below would be about something else." }
            $text = $text.Replace($row.Find, $row.Replace)
            if ($text -eq $readme) { throw "BREAK '$($row.Name)' changed nothing." }
        }
        if ($row.Contains('Extra')) {
            if (-not $text.Contains($row.Extra.Find)) { throw "BREAK '$($row.Name)' second substitution matched nothing." }
            $text = $text.Replace($row.Extra.Find, $row.Extra.Replace)
        }
        Set-Content -LiteralPath (Join-Path $work 'README.md') -Value $text -Encoding utf8NoBOM -NoNewline

        $output = & pwsh -NoProfile -File $checker -RepoRoot $work 2>&1
        $code = $LASTEXITCODE
        $observed = if ($code -eq 0) { 'green' } else { 'red' }
        $named = @($row.Names | Where-Object { ($output -join "`n") -notmatch [regex]::Escape($_) })

        $ok = ($observed -eq $row.Expect) -and $named.Count -eq 0
        if (-not $ok) { $failures++ }
        "[{0}] {1}" -f $(if ($ok) { 'OK  ' } else { 'FAIL' }), $row.Name
        "       expected $($row.Expect), observed $observed (exit $code)"
        if ($row.Names.Count) { "       named: $(($row.Names | ForEach-Object { $_ }) -join ' | ')$(if ($named.Count) { "  MISSING: $($named -join ', ')" })" }
        foreach ($line in @($output | Where-Object { $_ -match 'DISAGREE|AGREE|^  ' })) { "       $line" }
        ''
    }
}
finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
}

if ($failures -eq 0) { 'FALSIFICATION: all rows behaved as declared'; exit 0 }
"FALSIFICATION: $failures row(s) did not"; exit 1
