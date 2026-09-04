#Requires -Version 7.2
<#
    PASS 0048 - Section 2. The blindness observed BEFORE anything is written.

    D1 a changed STRINGS value is invisible to acceptance C's byte comparison.
    D2 an added STRINGS key is invisible to it.
    D3 the mutation actually reached the rendered document - without this, a
       substitution that matched nothing produces a green that proves nothing.

    The comparison logic below is copied VERBATIM from tests/LinkMode.Tests.ps1
    (Get-DocumentBlockRange, Get-DocumentBlock, Get-DocumentCode,
    Get-FirstDifference, and the $strip scriptblock at lines 330 and 341).
    A probe running different code from the check it probes proves nothing.
#>
[CmdletBinding()]
param(
    [string] $Repo = 'c:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\PSGraphRender',
    [Parameter(Mandatory)][string] $Work,
    [string] $BaseSha = 'cd4857d'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --------------------------------------------- helpers, verbatim from the suite
function Get-DocumentBlockRange {
    param([string[]] $Lines, [string] $Name)
    $start = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^const $Name = ") { $start = $i; break }
    }
    if ($start -lt 0) { throw "No $Name assignment in the document." }
    for ($j = $start; $j -lt $Lines.Count; $j++) {
        if ($Lines[$j] -match '^\};?\s*$') { return @($start, $j) }
    }
    throw "The $Name block is never closed."
}

function Get-DocumentBlock {
    param([string] $Document, [string] $Name)
    $lines = $Document -split "`r?`n"
    $range = Get-DocumentBlockRange -Lines $lines -Name $Name
    $text = ($lines[$range[0]..$range[1]] -join "`n") -replace "^const $Name = ", '' -replace ';\s*$', ''
    $text | ConvertFrom-Json
}

function Get-DocumentCode {
    param([string] $Document)
    $lines = @($Document -split "`r?`n")
    $range = Get-DocumentBlockRange -Lines $lines -Name 'STRINGS'
    $keep = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($i -lt $range[0] -or $i -gt $range[1]) { $keep += $lines[$i] }
    }
    $keep -join "`n"
}

function Get-FirstDifference {
    param([string] $Expected, [string] $Actual)
    if ($Expected -ceq $Actual) { return $null }
    $e = @($Expected -split "`r?`n")
    $a = @($Actual -split "`r?`n")
    $n = [Math]::Min($e.Count, $a.Count)
    for ($i = 0; $i -lt $n; $i++) {
        if ($e[$i] -cne $a[$i]) { return "line $($i + 1): base [$($e[$i])] head [$($a[$i])]" }
    }
    "line counts differ: base $($e.Count), head $($a.Count)"
}

# The exact scriptblock acceptance C's two byte comparisons use.
$strip = { param($d) (Get-DocumentCode -Document $d) -replace '(?ms)^const CONFIG = \{.*?^\};', '' }

# ------------------------------------------------------------------ scaffolding
if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force }
New-Item -ItemType Directory -Path $Work -Force | Out-Null

$fixture = Join-Path $Repo 'tests/fixtures/viewmodels/sample-module.json'
if (-not (Test-Path -LiteralPath $fixture)) { throw "fixture missing: $fixture" }

''
'PASS 0048 - SECTION 2: the blindness, observed against the shipped suite.'
"  repo     : $Repo"
"  head     : $((& git -C $Repo rev-parse --short HEAD).Trim()) ($((& git -C $Repo rev-parse --abbrev-ref HEAD).Trim()))"
"  base sha : $BaseSha  (acceptance C's, tests/LinkMode.Tests.ps1:286)"
''

# ---------------------------------------------------------------- the base doc
# Built by the clone's OWN build script and rendered by a CHILD process, exactly
# as the suite does it - src/ is not importable and two module versions cannot
# share a session.
$baseClone = Join-Path $Work 'base-clone'
$baseDocPath = Join-Path $Work 'base.html'
& git clone --quiet --no-hardlinks $Repo $baseClone 2>&1 | Out-Null
& git -C $baseClone checkout --quiet $BaseSha 2>&1 | Out-Null
"base clone at $((& git -C $baseClone rev-parse --short HEAD).Trim())"

$manifest = Join-Path $baseClone 'output/PSGraphRender/PSGraphRender.psd1'
$baseSet = Join-Path $baseClone 'output/PSGraphRender/TemplateSets/cytoscape'
$log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
& '$(Join-Path $baseClone 'build.ps1')' -Task Build | Out-Null
Import-Module '$manifest' -Force
`$vm = Get-Content -LiteralPath '$fixture' -Raw | ConvertFrom-Json
`$doc = New-RenderDocument -ViewModel `$vm.data -Meta `$vm.meta -Title 'Link mode fixture' -TemplateSetPath '$baseSet'
[System.IO.File]::WriteAllText('$baseDocPath', `$doc)
"@ 2>&1
if (-not (Test-Path -LiteralPath $baseDocPath)) { throw "base render produced nothing: $($log -join ' / ')" }
$base = [System.IO.File]::ReadAllText($baseDocPath)
"base document: $($base.Length) bytes"
''

# ------------------------------------------------------------- the head renders
Import-Module (Join-Path $Repo 'output/PSGraphRender/PSGraphRender.psd1') -Force
$vm = Get-Content -LiteralPath $fixture -Raw | ConvertFrom-Json
$shipped = Join-Path $Repo 'output/PSGraphRender/TemplateSets/cytoscape'

function New-MutatedSet {
    param([string] $Name, [scriptblock] $Mutate)
    $dest = Join-Path $Work $Name
    if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
    Copy-Item -LiteralPath $shipped -Destination $dest -Recurse -Force
    if ($Mutate) {
        $f = Join-Path $dest 'Config/strings.psd1'
        $text = [System.IO.File]::ReadAllText($f)
        $new = & $Mutate $text
        [System.IO.File]::WriteAllText($f, $new)
    }
    $dest
}

function New-Doc {
    param([string] $SetPath)
    New-RenderDocument -ViewModel $vm.data -Meta $vm.meta -Title 'Link mode fixture' -TemplateSetPath $SetPath
}

$plainSet = New-MutatedSet -Name 'set-unmutated' -Mutate $null
$plainDoc = New-Doc -SetPath $plainSet
"unmutated head document: $($plainDoc.Length) bytes"

# D1 - change an EXISTING value. MenuOpenLink, strings.psd1:139, added by 0047.
$d1Set = New-MutatedSet -Name 'set-d1' -Mutate {
    param($t) $t -replace "(?m)^(\s*MenuOpenLink\s*=\s*)'Open Link'", "`$1'MUTATED BY D1'"
}
$d1Doc = New-Doc -SetPath $d1Set

# D2 - ADD a key that does not exist anywhere in the shipped file.
$d2Set = New-MutatedSet -Name 'set-d2' -Mutate {
    param($t) $t.Insert($t.LastIndexOf('}'), "    D2AddedKey                    = 'added by D2'`n")
}
$d2Doc = New-Doc -SetPath $d2Set
''

# ------------------------------------------- D3 FIRST: did the mutation land?
'D3 - the mutation reached the rendered document (checked BEFORE any green is trusted).'
$plainStrings = Get-DocumentBlock -Document $plainDoc -Name 'STRINGS'
foreach ($case in @(
        @{ Name = 'D1'; Doc = $d1Doc; Expect = 'MenuOpenLink changed value' }
        @{ Name = 'D2'; Doc = $d2Doc; Expect = 'D2AddedKey present' })) {

    $mutStrings = Get-DocumentBlock -Document $case.Doc -Name 'STRINGS'
    $plainJson = $plainStrings | ConvertTo-Json -Depth 10
    $mutJson = $mutStrings | ConvertTo-Json -Depth 10
    $landed = $plainJson -cne $mutJson

    $names = @($mutStrings.PSObject.Properties.Name)
    $baseNames = @($plainStrings.PSObject.Properties.Name)
    $added = @($names | Where-Object { $_ -notin $baseNames })
    $changed = @($baseNames | Where-Object {
            $_ -in $names -and ($plainStrings.$_ | ConvertTo-Json -Compress) -cne ($mutStrings.$_ | ConvertTo-Json -Compress)
        })

    "  [$(if ($landed) { 'ok  ' } else { 'FAIL' })] $($case.Name): STRINGS block of the render differs from the unmutated render"
    "         expected      : $($case.Expect)"
    "         keys added    : $(if ($added.Count) { $added -join ', ' } else { '(none)' })"
    "         keys changed  : $(if ($changed.Count) { $changed -join ', ' } else { '(none)' })"
    foreach ($k in $changed) {
        "         $k : [$($plainStrings.$k)] -> [$($mutStrings.$k)]"
    }
    if (-not $landed) { throw "$($case.Name): the mutation did not reach the document - every result below it would be meaningless." }
}
''

# --------------------------------- D1 / D2: the CURRENT comparisons, vs the base
'D1 / D2 - the shipped acceptance-C comparisons, run against the base document.'
'          GREEN here is the hole: a mutated shipped string changes nothing they can see.'
''
foreach ($case in @(
        @{ Name = 'D1 (changed value)'; Doc = $d1Doc }
        @{ Name = 'D2 (added key)'; Doc = $d2Doc }
        @{ Name = 'control (unmutated)'; Doc = $plainDoc })) {

    $diff = Get-FirstDifference -Expected (& $strip $base) -Actual (& $strip $case.Doc)
    $green = ($null -eq $diff)
    "  $($case.Name.PadRight(22)) : $(if ($green) { 'GREEN - Should-BeNull passes' } else { "RED   - $diff" })"
}
''

# ------------------------------------------------- what the STRINGS delta is
'For the record - STRINGS additions head(3f2ec85) over base(cd4857d), the three 0047 added:'
$baseStrings = Get-DocumentBlock -Document $base -Name 'STRINGS'
$baseKeys = @($baseStrings.PSObject.Properties.Name)
$headKeys = @($plainStrings.PSObject.Properties.Name)
"  added   : $(@($headKeys | Where-Object { $_ -notin $baseKeys } | Sort-Object) -join ', ')"
"  removed : $(@($baseKeys | Where-Object { $_ -notin $headKeys } | Sort-Object) -join ', ')"
$moved = @($baseKeys | Where-Object {
        $_ -in $headKeys -and ($baseStrings.$_ | ConvertTo-Json -Compress) -cne ($plainStrings.$_ | ConvertTo-Json -Compress)
    })
"  changed : $(if ($moved.Count) { $moved -join ', ' } else { '(none)' })"
"  counts  : base $($baseKeys.Count) keys, head $($headKeys.Count) keys"
''
'SECTION 2 observation complete.'
