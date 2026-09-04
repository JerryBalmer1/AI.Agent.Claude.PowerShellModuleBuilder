#Requires -Version 7.2
<#
    PASS 0048 - Task 4. Falsifying the new STRINGS gate.

    Every probe mutates a SCRATCH CLONE, never src/ of the repository under
    test, and every probe asserts its mutation reached the RENDERED DOCUMENT
    before the suite is re-run. A break that did not break anything produces a
    result that says nothing, and it says it in the confident direction.

    P1 a changed value goes RED, naming the key and both values.
    P2 an added key goes RED, naming the unexpected key.
    P3 a removed key goes RED - and the probe states WHICH clause caught it.
    P4 scope control, and the load-bearing one: a mutation OUTSIDE STRINGS
       leaves the new It GREEN while the check that OWNS that region goes RED.
       Two halves, because the pass prompt named the wrong region and this is
       where that showed:
         P4a a theme value - every theme value the page uses is emitted into
             the CONFIG block, so CONFIG goes red and the body stays green;
         P4b a script line, which really does land in the compared body.
       Together they are what proves the checks divide the document between
       them rather than being one check written twice.
#>
[CmdletBinding()]
param(
    # Mandatory, with no default: a machine path baked into a committed
    # artifact is exactly what SC4 exists to catch.
    [Parameter(Mandatory)][string] $Repo,
    [Parameter(Mandatory)][string] $Work
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$STRINGS_IT = 'changes STRINGS only by adding the three link strings, and moves no shipped value'
$BODY_ITS = @(
    'renders identically to the base with linkMode absent entirely'
    'renders identically to the base with linkMode set explicitly to editor'
)
$CONFIG_IT = 'changes CONFIG only by adding the two link settings, and defaults the mode to editor'

# ------------------------------------------------------------------ scaffolding
if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force }
New-Item -ItemType Directory -Path $Work -Force | Out-Null

$clone = Join-Path $Work 'head'
& git clone --quiet --no-hardlinks $Repo $clone 2>&1 | Out-Null
& git -C $clone checkout --quiet (& git -C $Repo rev-parse HEAD).Trim() 2>&1 | Out-Null

''
'PASS 0048 - TASK 4: falsifying the STRINGS gate, in a scratch clone.'
"  clone of : $Repo"
"  at       : $((& git -C $clone rev-parse --short HEAD).Trim())"
"  work     : $Work"
''

& pwsh -NoProfile -NonInteractive -Command "& '$(Join-Path $clone 'build.ps1')' -Task Build" 2>&1 | Out-Null
$builtSet = Join-Path $clone 'output/PSGraphRender/TemplateSets/cytoscape'
$stringsFile = Join-Path $builtSet 'Config/strings.psd1'
$themeFile = Join-Path $builtSet 'Config/theme.psd1'
if (-not (Test-Path -LiteralPath $stringsFile)) { throw "no built strings.psd1 at $stringsFile" }

$scriptFile = Join-Path $builtSet 'scripts/sidebar.js'
$pristineStrings = [System.IO.File]::ReadAllText($stringsFile)
$pristineTheme = [System.IO.File]::ReadAllText($themeFile)
$pristineScript = [System.IO.File]::ReadAllText($scriptFile)

# ------------------------------------------------------------------- helpers
Import-Module (Join-Path $clone 'output/PSGraphRender/PSGraphRender.psd1') -Force
$fixture = Join-Path $clone 'tests/fixtures/viewmodels/sample-module.json'
$vm = Get-Content -LiteralPath $fixture -Raw | ConvertFrom-Json

function Get-BlockText {
    param([string] $Document, [string] $Name)
    $lines = @($Document -split "`r?`n")
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^const $Name = ") { $start = $i; break }
    }
    if ($start -lt 0) { throw "No $Name assignment in the document." }
    for ($j = $start; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match '^\};?\s*$') { return ($lines[$start..$j] -join "`n") }
    }
    throw "The $Name block is never closed."
}

# Renders with the CURRENT state of the built template set, in a child process
# so the mutated set is read fresh every time.
function Get-CurrentRender {
    $out = Join-Path $Work 'probe-render.html'
    if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force }
    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module '$(Join-Path $clone 'output/PSGraphRender/PSGraphRender.psd1')' -Force
`$vm = Get-Content -LiteralPath '$fixture' -Raw | ConvertFrom-Json
`$doc = New-RenderDocument -ViewModel `$vm.data -Meta `$vm.meta -Title 'Link mode fixture' -TemplateSetPath '$builtSet'
[System.IO.File]::WriteAllText('$out', `$doc)
"@ 2>&1
    if (-not (Test-Path -LiteralPath $out)) { throw "probe render produced nothing: $($log -join ' / ')" }
    [System.IO.File]::ReadAllText($out)
}

$pristineDoc = Get-CurrentRender
$pristineStringsBlock = Get-BlockText -Document $pristineDoc -Name 'STRINGS'

# Runs ONLY the link-mode suite, in a child process, in the Pester 6 dialect the
# build sets. Returns one row per It.
function Invoke-LinkModeSuite {
    $resultPath = Join-Path $Work 'probe-result.xml'
    $jsonPath = Join-Path $Work 'probe-result.json'
    if (Test-Path -LiteralPath $jsonPath) { Remove-Item -LiteralPath $jsonPath -Force }

    $log = & pwsh -NoProfile -NonInteractive -Command @"
`$ErrorActionPreference = 'Stop'
Import-Module Pester -RequiredVersion 6.1.0 -Force
`$cfg = New-PesterConfiguration
`$cfg.Run.Path = '$(Join-Path $clone 'tests/LinkMode.Tests.ps1')'
`$cfg.Run.PassThru = `$true
`$cfg.Run.Throw = `$false
`$cfg.Should.DisableV5 = `$true
`$cfg.Output.Verbosity = 'None'
`$r = Invoke-Pester -Configuration `$cfg
`$rows = @(`$r.Tests | ForEach-Object {
    [pscustomobject]@{
        Name   = `$_.Name
        Result = `$_.Result
        Message = if (`$_.ErrorRecord) { (`$_.ErrorRecord | ForEach-Object { `$_.ToString() }) -join ' ' } else { '' }
    }
})
`$rows | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath '$jsonPath'
"@ 2>&1

    if (-not (Test-Path -LiteralPath $jsonPath)) { throw "the suite produced no result: $(($log | Select-Object -Last 5) -join ' / ')" }
    @(Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json)
}

function Get-Row {
    param($Rows, [string] $Name)
    $r = @($Rows | Where-Object { $_.Name -eq $Name })
    if ($r.Count -ne 1) { throw "expected exactly one It named '$Name', found $($r.Count)" }
    $r[0]
}

function Restore-Set {
    [System.IO.File]::WriteAllText($stringsFile, $pristineStrings)
    [System.IO.File]::WriteAllText($themeFile, $pristineTheme)
    [System.IO.File]::WriteAllText($scriptFile, $pristineScript)
}

$failures = [System.Collections.Generic.List[string]]::new()
function Assert-That {
    param([string] $What, [bool] $Ok, [string] $Detail = '')
    $suffix = ''; if ($Detail) { $suffix = " - $Detail" }
    '    [{0}] {1}{2}' -f $(if ($Ok) { 'ok  ' } else { 'FAIL' }), $What, $suffix
    if (-not $Ok) { $script:failures.Add("$What$suffix") }
}

# Every probe: mutate, prove the mutation reached the document, then run.
function Invoke-Probe {
    param(
        [string] $Id,
        [string] $Title,
        [scriptblock] $Mutate,
        [string] $LandedWhat,
        [scriptblock] $Landed,
        [scriptblock] $Expect
    )
    ''
    "$Id - $Title"
    Restore-Set
    & $Mutate
    $doc = Get-CurrentRender

    # The mutation must have reached the DOCUMENT before any suite result from
    # it is counted. A substitution that matched nothing leaves the target
    # intact and every assertion below reads as a clean pass.
    #
    # $didLand, not $landed: PowerShell variable names are case-insensitive, so
    # $landed IS the [scriptblock] $Landed parameter and assigning a bool to it
    # throws a cast error rather than shadowing it.
    $didLand = [bool] (& $Landed $doc)
    Assert-That -What "$($Id): the mutation reached the rendered document" -Ok $didLand -Detail $LandedWhat
    if (-not $didLand) {
        Restore-Set
        return
    }

    $rows = Invoke-LinkModeSuite
    & $Expect $rows
    Restore-Set
}

# ---------------------------------------------------------------------- probes
try {
    # P1 - a changed value goes red.
    Invoke-Probe -Id 'P1' -Title 'a changed value goes RED, naming the key and both values' `
        -Mutate {
        $t = [System.IO.File]::ReadAllText($stringsFile)
        $t = $t -replace "(?m)^(\s*MenuOpenLink\s*=\s*)'Open Link'", "`$1'MUTATED BY P1'"
        [System.IO.File]::WriteAllText($stringsFile, $t)
    } `
        -LandedWhat 'MenuOpenLink now reads MUTATED BY P1 in the STRINGS block' `
        -Landed { param($d) (Get-BlockText -Document $d -Name 'STRINGS').Contains('MUTATED BY P1') } `
        -Expect {
        param($rows)
        $s = Get-Row -Rows $rows -Name $STRINGS_IT
        Assert-That -What 'P1: the STRINGS gate is RED' -Ok ($s.Result -eq 'Failed') -Detail $s.Result
        Assert-That -What 'P1: the message names the key' -Ok ($s.Message -match 'MenuOpenLink') `
            -Detail $(if ($s.Message -match "MenuOpenLink") { 'named' } else { "not named: $($s.Message)" })
        Assert-That -What 'P1: the message carries both values' `
            -Ok ($s.Message -match 'Open Link' -and $s.Message -match 'MUTATED BY P1') `
            -Detail ($s.Message -replace '\s+', ' ').Substring(0, [Math]::Min(200, ($s.Message -replace '\s+', ' ').Length))
        foreach ($n in $BODY_ITS) {
            $b = Get-Row -Rows $rows -Name $n
            Assert-That -What "P1: body comparison stays GREEN - '$($n.Substring(0,34))...'" -Ok ($b.Result -eq 'Passed') -Detail $b.Result
        }
    }

    # P2 - an added key goes red.
    Invoke-Probe -Id 'P2' -Title 'an added key goes RED, naming the unexpected key' `
        -Mutate {
        $t = [System.IO.File]::ReadAllText($stringsFile)
        $t = $t.Insert($t.LastIndexOf('}'), "    P2UnexpectedKey               = 'added by P2'`n")
        [System.IO.File]::WriteAllText($stringsFile, $t)
    } `
        -LandedWhat 'P2UnexpectedKey is present in the STRINGS block' `
        -Landed { param($d) (Get-BlockText -Document $d -Name 'STRINGS').Contains('P2UnexpectedKey') } `
        -Expect {
        param($rows)
        $s = Get-Row -Rows $rows -Name $STRINGS_IT
        Assert-That -What 'P2: the STRINGS gate is RED' -Ok ($s.Result -eq 'Failed') -Detail $s.Result
        Assert-That -What 'P2: the message names the unexpected key' -Ok ($s.Message -match 'P2UnexpectedKey') `
            -Detail $(if ($s.Message -match 'P2UnexpectedKey') { 'named' } else { "not named: $($s.Message)" })
    }

    # P3 - a removed key goes red. WHICH clause catches it is the question.
    Invoke-Probe -Id 'P3' -Title 'a removed key goes RED - and which clause catches it' `
        -Mutate {
        $t = [System.IO.File]::ReadAllText($stringsFile)
        $t = $t -replace "(?m)^\s*MenuCopyPath\s*=.*\r?\n", ''
        [System.IO.File]::WriteAllText($stringsFile, $t)
    } `
        -LandedWhat 'MenuCopyPath is gone from the STRINGS block' `
        -Landed { param($d) -not (Get-BlockText -Document $d -Name 'STRINGS').Contains('MenuCopyPath') } `
        -Expect {
        param($rows)
        $s = Get-Row -Rows $rows -Name $STRINGS_IT
        Assert-That -What 'P3: the STRINGS gate is RED' -Ok ($s.Result -eq 'Failed') -Detail $s.Result
        $byValueClause = $s.Message -match "MenuCopyPath"
        Assert-That -What "P3: caught by the VALUE clause (a removed key reads null at head)" -Ok $byValueClause `
            -Detail ($s.Message -replace '\s+', ' ').Substring(0, [Math]::Min(220, ($s.Message -replace '\s+', ' ').Length))
    }

    # P4 - the scope control, and the load-bearing probe. Two halves, because
    # a theme value and a script line leave the document in DIFFERENT places:
    # every theme value the page uses is emitted INTO the CONFIG block, which
    # $strip removes, so a theme edit turns the CONFIG comparison red and the
    # body comparison stays green. The pass prompt predicted the body
    # comparison; the prompt was wrong, and this probe is where that showed.
    Invoke-Probe -Id 'P4a' -Title 'SCOPE: a theme value (outside STRINGS) leaves the gate GREEN and turns CONFIG RED' `
        -Mutate {
        $t = [System.IO.File]::ReadAllText($themeFile)
        # Every top-level colour. Any theme value would do; the point is only
        # that it is outside STRINGS.
        [System.IO.File]::WriteAllText($themeFile, ($t -replace "(?m)^(\s*\w+\s*=\s*)'#([0-9a-fA-F]{6})'", "`$1'#ABCDEF'"))
    } `
        -LandedWhat 'the document changed, the STRINGS block did not, and the change is inside CONFIG' `
        -Landed {
        param($d)
        # Three halves, and all of them matter. The document must have moved;
        # STRINGS must NOT have (or P4a proves the opposite of what it claims);
        # and the change must actually be where this probe says it is.
        $stringsSame = (Get-BlockText -Document $d -Name 'STRINGS') -ceq $pristineStringsBlock
        $docChanged = $d -cne $pristineDoc
        $inConfig = (Get-BlockText -Document $d -Name 'CONFIG').Contains('#ABCDEF')
        $docChanged -and $stringsSame -and $inConfig
    } `
        -Expect {
        param($rows)
        $s = Get-Row -Rows $rows -Name $STRINGS_IT
        Assert-That -What 'P4a: the STRINGS gate stays GREEN' -Ok ($s.Result -eq 'Passed') -Detail $s.Result
        $c = Get-Row -Rows $rows -Name $CONFIG_IT
        Assert-That -What 'P4a: the CONFIG comparison goes RED' -Ok ($c.Result -eq 'Failed') -Detail $c.Result
        foreach ($n in $BODY_ITS) {
            $b = Get-Row -Rows $rows -Name $n
            Assert-That -What "P4a: body comparison stays GREEN (theme lives in CONFIG) - '$($n.Substring(0,34))...'" `
                -Ok ($b.Result -eq 'Passed') -Detail $b.Result
        }
    }

    # P4b - the half the prompt was reaching for: a mutation that really does
    # land in the compared BODY. Without this, nothing proves the STRINGS gate
    # and the byte comparison are independent checks rather than one check
    # written twice.
    Invoke-Probe -Id 'P4b' -Title 'SCOPE: a script line (in the compared body) leaves the gate GREEN and turns the BODY RED' `
        -Mutate {
        [System.IO.File]::WriteAllText($scriptFile, $pristineScript + "`n// P4B MUTATION`n")
    } `
        -LandedWhat 'the marker is in the document body, outside CONFIG and outside STRINGS' `
        -Landed {
        param($d)
        $inBody = $d.Contains('P4B MUTATION')
        $stringsSame = (Get-BlockText -Document $d -Name 'STRINGS') -ceq $pristineStringsBlock
        $notInConfig = -not (Get-BlockText -Document $d -Name 'CONFIG').Contains('P4B MUTATION')
        $inBody -and $stringsSame -and $notInConfig
    } `
        -Expect {
        param($rows)
        $s = Get-Row -Rows $rows -Name $STRINGS_IT
        Assert-That -What 'P4b: the STRINGS gate stays GREEN' -Ok ($s.Result -eq 'Passed') -Detail $s.Result
        foreach ($n in $BODY_ITS) {
            $b = Get-Row -Rows $rows -Name $n
            Assert-That -What "P4b: body comparison goes RED - '$($n.Substring(0,34))...'" -Ok ($b.Result -eq 'Failed') -Detail $b.Result
        }
    }

    # Known-good control: nothing mutated, everything green.
    ''
    'CONTROL - nothing mutated: the whole Describe is green.'
    Restore-Set
    $rows = Invoke-LinkModeSuite
    foreach ($n in (@($STRINGS_IT, $CONFIG_IT) + $BODY_ITS)) {
        $r = Get-Row -Rows $rows -Name $n
        Assert-That -What "control: '$($n.Substring(0, [Math]::Min(44, $n.Length)))...'" -Ok ($r.Result -eq 'Passed') -Detail $r.Result
    }
}
finally {
    Restore-Set
}

''
if ($failures.Count) {
    "TASK 4: FAIL - $($failures.Count) probe expectation(s) disagreed:"
    foreach ($f in $failures) { "  - $f" }
    exit $failures.Count
}
'TASK 4: PASS - all four probes and the control behaved as the pass claims.'
exit 0
