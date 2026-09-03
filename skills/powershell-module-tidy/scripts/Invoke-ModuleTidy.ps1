#Requires -Version 7.2
<#
.SYNOPSIS
    The pre-release sweep: naming, surface/docs parity, dead files, plan
    currency, and a final conformance run that refuses to bless an open
    Bucket-A item.
.DESCRIPTION
    The deterministic half of `powershell-module-tidy`. The skill holds the
    judgment - what each finding means and when to override it - and this holds
    the mechanics, per rule 9 of the plugin's taxonomy. Mechanics written as
    prose drift; mechanics written as a script fail loudly instead.

    It CHANGES NOTHING. Every check reads. A sweep that edits while it reports
    makes its own next run meaningless, and there is no -Fix switch for that
    reason.

    Matching is structural wherever a name is involved: function definitions and
    command references come from the AST, never from a text search. A name
    inside a comment is not a reference, and a regex says it is - which is the
    defect that made five build-file assertions in this project's own
    conformance suite inert.

.PARAMETER Path
    Repository root of the module under test.
.PARAMETER ModuleName
    Which module the repository contains, when src/<Name>/<Name>.psd1 cannot
    decide. Ambiguity stops and names every candidate rather than picking one.
.PARAMETER Check
    Which sweeps to run. Default is all of them. Conformance is only run when
    it is selected AND -ConformanceRunner resolves.
.PARAMETER ConformanceRunner
    Path to evals/conformance/Invoke-Conformance.ps1. When omitted the
    Conformance check reports as NotRun - which is not a pass, and is recorded
    as such.
.PARAMETER KnownFailurePath
    The module's declared Bucket-B failures. Default <Path>/tidy-known-failures.json.
    Absent means every conformance failure is new, which is the correct default:
    a missing declaration file may not silently license anything.
.PARAMETER ReportPath
    Where the JSON report goes. Default <Path>/tidy-report.json.
.PARAMETER CommandPrefix
    The module's command prefix or prefixes, when the derivation from the
    exported surface cannot find one. Derivation is the default and is right
    for any module following the one-prefix-per-module convention.
.PARAMETER NoExitCode
    Report without exiting 1 on a blocker, for a caller that wants the JSON
    only. Refusing to bless is the default.
.EXAMPLE
    $Path       = 'C:/repos/PSModuleGraph'
    $ReportPath = 'C:/repos/PSModuleGraph/tidy-report.json'
    $Runner     = 'C:/repos/harness/evals/conformance/Invoke-Conformance.ps1'

    $tidyResult = try {

        $params = @{
            Path              = $Path
            ReportPath        = $ReportPath
            ConformanceRunner = $Runner
        }

        ./Invoke-ModuleTidy.ps1 @params

    }
    catch {
        Write-Error "The tidy sweep could not complete: $_"
        $null
    }

    $tidyResult.Blessed
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string] $Path,

    [string] $ModuleName,

    [ValidateSet('Naming', 'Parity', 'DeadFile', 'PlanCurrency', 'Conformance')]
    [string[]] $Check = @('Naming', 'Parity', 'DeadFile', 'PlanCurrency', 'Conformance'),

    [string] $ConformanceRunner,

    [string] $KnownFailurePath,

    [string] $ReportPath,

    [string[]] $CommandPrefix,

    # Inverted rather than defaulted to $true: PSScriptAnalyzer's
    # PSAvoidDefaultValueSwitchParameter is right that a switch defaulting to on
    # cannot be turned off by omitting it, which is the one thing a switch is
    # supposed to mean. Refusing to bless is the default; this opts out of the
    # exit code, not out of the refusal.
    [switch] $NoExitCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $Path).Path
if (-not $ReportPath) { $ReportPath = Join-Path $root 'tidy-report.json' }
if (-not $KnownFailurePath) { $KnownFailurePath = Join-Path $root 'tidy-known-failures.json' }

$findings = [System.Collections.Generic.List[object]]::new()
$checkStatus = [ordered]@{}

function Add-Finding {
    param(
        [Parameter(Mandatory)] [string] $Check,
        [Parameter(Mandatory)] [string] $Rule,
        [Parameter(Mandatory)] [string] $Message,
        [string] $File,
        [int] $Line = 0,
        # Blocking is a property of the finding, not of the caller's mood. A
        # dead-file CANDIDATE is advisory because the two legitimate exceptions
        # are real; everything else here is a defect.
        [switch] $Advisory
    )
    $findings.Add([pscustomobject]@{
            Check    = $Check
            Rule     = $Rule
            Message  = $Message
            File     = if ($File) { $File.Replace($root, '').TrimStart('\', '/') } else { $null }
            Line     = $Line
            Blocking = -not $Advisory
        })
}

# ---------------------------------------------------------------------------
# Discovery. One rule, and it ends in a stop rather than a guess: the layout
# this plugin mandates is src/<Name>/<Name>.psd1. Two candidates is undecidable
# and names both. A lone-survivor fallback is exactly what once graded a
# vendored module confidently after the reference's own manifest was deleted.
# ---------------------------------------------------------------------------
$srcRoot = Join-Path $root 'src'
if (-not $ModuleName) {
    $candidates = @(
        if (Test-Path -LiteralPath $srcRoot) {
            Get-ChildItem -LiteralPath $srcRoot -Filter *.psd1 -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.BaseName -eq $_.Directory.Name }
        }
    )
    if ($candidates.Count -eq 1) {
        $ModuleName = $candidates[0].BaseName
    }
    elseif ($candidates.Count -gt 1) {
        throw ("Cannot determine the module: $($candidates.Count) manifests under 'src/', none preferred. " +
            "Candidates: $(($candidates.FullName -replace [regex]::Escape($root), '') -join '; '). Pass -ModuleName.")
    }
    else {
        throw "No manifest at src/<Name>/<Name>.psd1 under '$root'. Pass -ModuleName, or run tidy against a repository laid out to the convention."
    }
}

$moduleRoot = Join-Path $srcRoot $ModuleName
$manifestPath = Join-Path $moduleRoot "$ModuleName.psd1"
$publicDir = Join-Path $moduleRoot 'Public'
$privateDir = Join-Path $moduleRoot 'Private'
$testsDir = Join-Path $root 'tests'

Write-Host "==> tidy   $root  (module $ModuleName)"

# One parse per file, memoised on path plus last-write time, because four
# sweeps ask the same walker for the same files.
$script:AstCache = @{}
function Get-Ast {
    param([Parameter(Mandatory)] [string] $LiteralPath)

    $item = Get-Item -LiteralPath $LiteralPath
    $key = '{0}|{1}' -f $item.FullName, $item.LastWriteTimeUtc.Ticks
    if ($script:AstCache.ContainsKey($key)) { return $script:AstCache[$key] }

    $parseErrors = $null
    # ParseFile, never ParseInput: ParseInput leaves Extent.File null and every
    # finding downstream then reports a null path.
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $item.FullName, [ref] $null, [ref] $parseErrors)

    $entry = [pscustomobject]@{ Ast = $ast; Errors = @($parseErrors) }
    $script:AstCache[$key] = $entry
    $entry
}

function Get-SourceFile {
    @(
        foreach ($dir in $moduleRoot, $testsDir) {
            if (Test-Path -LiteralPath $dir) {
                Get-ChildItem -LiteralPath $dir -Filter *.ps1 -File -Recurse
            }
        }
    )
}

# ---------------------------------------------------------------------------
# 1. Naming and layout
# ---------------------------------------------------------------------------
if ($Check -contains 'Naming') {
    $approvedVerb = @((Get-Verb).Verb)

    # Scoped to files something EXECUTES or IMPORTS, not to every file in the
    # tree. A fixture named 'res one' is data, and a fixture whose whole purpose
    # is to carry a hostile path is legitimate - the reference has one. Scoping
    # the rule to what it is actually about is not the same as exempting a
    # directory from it, and only the second kind of narrowing stops a check
    # firing where it should.
    foreach ($item in Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Extension -in '.ps1', '.psm1', '.psd1' -and
            $_.FullName -notmatch '[\\/](\.git|output|scratch|node_modules)([\\/]|$)'
        }) {

        if ($item.Name -match '\s') {
            Add-Finding -Check Naming -Rule 'no-space-in-filename' -File $item.FullName `
                -Message "'$($item.Name)' contains a space. It survives every tool on Windows and breaks the first unquoted path on Linux."
        }
    }

    if (Test-Path -LiteralPath $srcRoot) {
        # A culture directory is PowerShell's own naming, not this project's:
        # en-US, fr-FR, and anything else Get-Help resolves. The build is
        # REQUIRED to copy them, so a rule that calls them misnamed would be a
        # rule against a mandated convention. Same pattern the emitter uses.
        $culturePattern = '^[a-z]{2}(-[A-Za-z]{2,4})?$'
        foreach ($dir in Get-ChildItem -LiteralPath $srcRoot -Directory -Recurse) {
            if ($dir.Name -cmatch $culturePattern) { continue }
            if ($dir.Name -cnotmatch '^[A-Z][A-Za-z0-9]*$') {
                Add-Finding -Check Naming -Rule 'pascalcase-directory' -File $dir.FullName `
                    -Message "Directory '$($dir.Name)' is not PascalCase and is not a culture directory. Case-insensitive on Windows and case-sensitive in git is how two directories become one."
            }
        }
    }

    foreach ($dir in $publicDir, $privateDir) {
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $dir -Filter *.ps1 -File -Recurse) {
            $parts = $file.BaseName -split '-', 2
            if ($parts.Count -ne 2 -or $parts[0] -notin $approvedVerb) {
                Add-Finding -Check Naming -Rule 'approved-verb-noun' -File $file.FullName `
                    -Message "'$($file.Name)' is not Verb-Noun with a verb from Get-Verb. Conformance grades Public/; Private/ is where the unapproved verb accumulates."
            }
        }
    }

    if (Test-Path -LiteralPath $testsDir) {
        foreach ($file in Get-ChildItem -LiteralPath $testsDir -Filter *.ps1 -File -Recurse) {
            if ($file.Name -like '*.Tests.ps1') { continue }
            $parsed = Get-Ast -LiteralPath $file.FullName
            $describes = @($parsed.Ast.FindAll({
                        $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                        $args[0].GetCommandName() -eq 'Describe'
                    }, $true))
            if ($describes.Count -gt 0) {
                Add-Finding -Check Naming -Rule 'test-file-discoverable' -File $file.FullName `
                    -Line $describes[0].Extent.StartLineNumber `
                    -Message "'$($file.Name)' contains $($describes.Count) Describe block(s) and is not named *.Tests.ps1. Pester does not discover it, and a test that does not run is indistinguishable from one that passes."
            }
        }
    }

    $checkStatus['Naming'] = 'Ran'
}

# ---------------------------------------------------------------------------
# 2. Surface / docs parity, both directions
# ---------------------------------------------------------------------------
if ($Check -contains 'Parity') {
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "No manifest at '$manifestPath'. Parity is a claim about the export list and cannot be made without one."
    }
    # Restricted data, not executed. Never Invoke-Expression, never dot-source.
    $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath -ErrorAction Stop
    $exported = @(
        if ($manifest.ContainsKey('FunctionsToExport')) {
            $manifest.FunctionsToExport | Where-Object { $_ -and $_ -ne '*' }
        }
    )

    # The two directions read DIFFERENT document sets, and the asymmetry is
    # deliberate rather than an oversight.
    #
    # Direction 1 asks "can a user find this at all", so anything written down
    # counts - README, docs/, about_ topic.
    #
    # Direction 2 asks "did we promise something that does not exist", and only
    # a document a USER reads can make that promise. An architecture note under
    # docs/ naming a private helper is correct writing, and blocking a release
    # on it would train people to stop writing them. The reference has exactly
    # that case: docs/html-architecture.md discusses Get-PSModuleGraphAsset,
    # which is private and should be.
    function Get-DocText {
        param([object[]] $File)
        ($File | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
    }

    $aboutFiles = @(
        if (Test-Path -LiteralPath $moduleRoot) {
            Get-ChildItem -LiteralPath $moduleRoot -Filter 'about_*.help.txt' -File -Recurse -ErrorAction SilentlyContinue
        }
    )
    $userFacingFiles = @(
        if (Test-Path -LiteralPath (Join-Path $root 'README.md')) { Get-Item -LiteralPath (Join-Path $root 'README.md') }
    ) + $aboutFiles

    $allDocFiles = $userFacingFiles + @(
        if (Test-Path -LiteralPath (Join-Path $root 'docs')) {
            Get-ChildItem -LiteralPath (Join-Path $root 'docs') -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in '.md', '.txt' }
        }
    )

    $anyDocText = Get-DocText -File $allDocFiles
    $userDocText = Get-DocText -File $userFacingFiles

    foreach ($name in $exported) {
        if ($anyDocText -notmatch [regex]::Escape($name)) {
            Add-Finding -Check Parity -Rule 'exported-undocumented' -File $manifestPath `
                -Message "'$name' is exported and appears in no README table, doc or about_ topic. The user cannot discover it."
        }
    }

    # The direction hand-rolled versions of this check leave out, and the one
    # that produces a bug report.
    #
    # It has to be scoped to THIS module's surface, or a README mentioning
    # Get-ChildItem becomes a finding. The scoping is the whole difficulty, and
    # the obvious answer is wrong: the command prefix is not the module name.
    # `powershell-module-architect` mandates "a prefix per module, on every
    # command" and the reference's is Get-PSModule*, in a module called
    # PSModuleGraph. Deriving the prefix from the module name misses every
    # command it is supposed to catch - the falsification row for this rule did
    # not fire until the derivation was replaced.
    #
    # Derived from the exported surface instead: group the exported nouns by
    # their first four characters, and any group with two or more members
    # contributes its longest common prefix. PSModuleGraph yields
    # {PSModule, Knowledge} - both real, neither guessable from the name.
    if (-not $CommandPrefix) {
        $nouns = @($exported | ForEach-Object { ($_ -split '-', 2)[-1] } | Where-Object { $_.Length -ge 4 })
        $CommandPrefix = @(
            $nouns | Group-Object { $_.Substring(0, 4) } | Where-Object Count -ge 2 | ForEach-Object {
                $members = @($_.Group)
                $length = $members[0].Length
                foreach ($member in $members) {
                    $i = 0
                    while ($i -lt $length -and $i -lt $member.Length -and
                        $members[0][$i] -ceq $member[$i]) { $i++ }
                    $length = $i
                }
                $members[0].Substring(0, $length)
            }
        )
    }

    if ($CommandPrefix.Count -eq 0) {
        # Not derivable is not a pass. Say so, and let the operator answer the
        # question the script could not, rather than reporting a clean sweep.
        Add-Finding -Check Parity -Rule 'command-prefix-underivable' `
            -File $manifestPath `
            -Message "Cannot derive a command prefix from $($exported.Count) exported name(s), so 'documented-unexported' did not run. Not a pass. Pass -CommandPrefix to say what this module's commands are called."
    }
    else {
        $pattern = '\b([A-Z][a-z]+)-(' +
            (($CommandPrefix | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')[A-Za-z0-9]*\b'
        $mentioned = @(
            [regex]::Matches($userDocText, $pattern) | ForEach-Object { $_.Value } | Sort-Object -Unique
        )
        foreach ($name in $mentioned) {
            if ($name -notin $exported) {
                Add-Finding -Check Parity -Rule 'documented-unexported' -File (Join-Path $root 'README.md') `
                    -Message "'$name' is named in user-facing documentation and is not exported. The user tries it because the README said to, and it does not exist."
            }
        }
    }

    $checkStatus['Parity'] = 'Ran'
}

# ---------------------------------------------------------------------------
# 3. Dead files
# ---------------------------------------------------------------------------
if ($Check -contains 'DeadFile') {
    $allFiles = Get-SourceFile

    $definitions = @(
        foreach ($file in $allFiles) {
            $parsed = Get-Ast -LiteralPath $file.FullName
            foreach ($fn in $parsed.Ast.FindAll({
                        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                    }, $true)) {
                [pscustomobject]@{
                    Name = $fn.Name
                    File = $file.FullName
                    Line = $fn.Extent.StartLineNumber
                    # Private/ is the only place a dead function is interesting.
                    # A dead Public/ function is a conformance failure already.
                    IsPrivate = $file.FullName.StartsWith($privateDir, [StringComparison]::OrdinalIgnoreCase)
                }
            }
        }
    )

    # Structural: every CommandAst name in the tree. A name in a comment is not
    # here, which is the whole reason this is not a grep.
    $referenced = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $allFiles) {
        $parsed = Get-Ast -LiteralPath $file.FullName
        foreach ($cmd in $parsed.Ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst]
                }, $true)) {
            $name = $cmd.GetCommandName()
            if ($name) { [void] $referenced.Add($name) }
        }
    }

    foreach ($def in ($definitions | Where-Object IsPrivate)) {
        # Its own definition file counts as a reference only if something other
        # than the definition invokes it, which the CommandAst walk already
        # enforces - a FunctionDefinitionAst is not a CommandAst.
        if (-not $referenced.Contains($def.Name)) {
            Add-Finding -Check DeadFile -Rule 'unreferenced-private-function' -Advisory `
                -File $def.File -Line $def.Line `
                -Message "'$($def.Name)' is defined in Private/ and invoked nowhere in src/ or tests/. Candidate, not a verdict: a name built at runtime and a type reached through 'using module' are both legitimate."
        }
    }

    $checkStatus['DeadFile'] = 'Ran'
}

# ---------------------------------------------------------------------------
# 4. Plan currency
# ---------------------------------------------------------------------------
if ($Check -contains 'PlanCurrency') {
    $planScript = Join-Path $PSScriptRoot 'Test-PlanCurrency.ps1'
    $currency = & $planScript -Path $root | Select-Object -Last 1
    if (-not $currency.IsCurrent) {
        Add-Finding -Check PlanCurrency -Rule 'plan-current' -File 'docs/PLAN.md' `
            -Message $currency.Reason
    }
    $checkStatus['PlanCurrency'] = 'Ran'
}

# ---------------------------------------------------------------------------
# 5. Conformance, and the refusal
# ---------------------------------------------------------------------------
$conformance = $null
if ($Check -contains 'Conformance') {
    if (-not $ConformanceRunner -or -not (Test-Path -LiteralPath $ConformanceRunner)) {
        # NotRun is not a pass. Rule: zero cases is not a pass, and neither is
        # zero runs. It is recorded as a blocker so a release cannot be blessed
        # by a sweep that never graded anything.
        $checkStatus['Conformance'] = 'NotRun'
        Add-Finding -Check Conformance -Rule 'conformance-ran' `
            -Message 'The conformance suite did not run: -ConformanceRunner was not supplied or did not resolve. Not a pass. A release is not blessed by a sweep that graded nothing.'
    }
    else {
        $resultPath = Join-Path ([System.IO.Path]::GetDirectoryName($ReportPath)) 'tidy-conformance-result.json'
        $conformanceArgs = @{ Path = $root; ResultPath = $resultPath; ModuleName = $ModuleName }
        $summary = & $ConformanceRunner @conformanceArgs | Select-Object -Last 1

        $known = @(
            if (Test-Path -LiteralPath $KnownFailurePath) {
                (Get-Content -LiteralPath $KnownFailurePath -Raw | ConvertFrom-Json).failures
            }
        )
        $openBucketA = @($known | Where-Object { $_.PSObject.Properties['bucket'] -and $_.bucket -eq 'A' -and -not $_.resolved })

        foreach ($entry in $openBucketA) {
            Add-Finding -Check Conformance -Rule 'open-bucket-a' `
                -Message "Bucket A open: $($entry.id) - $($entry.reason). The grader is known wrong, so the score above is partly a measurement of nothing. This blocks whatever the score says, including a green one."
        }

        $declaredB = @($known |
                Where-Object { -not $_.PSObject.Properties['bucket'] -or $_.bucket -eq 'B' } |
                ForEach-Object { $_.assertion })

        foreach ($failure in @($summary.Failures)) {
            $matched = @($declaredB | Where-Object { $failure.Name -like "$_*" -or $failure.Name -eq $_ })
            if ($matched.Count -eq 0) {
                Add-Finding -Check Conformance -Rule 'undeclared-failure' `
                    -Message "New conformance failure, in no bucket: $($failure.Name) - $($failure.Message). An undeclared failure blocks; declare it as Bucket B with a reason, or fix it."
            }
        }

        $conformance = [pscustomobject]@{
            Score        = "$($summary.Passed)/$($summary.CasesRun)"
            CasesDefined = [int]$summary.CasesDefined
            CasesRun     = [int]$summary.CasesRun
            Failed       = [int]$summary.Failed
            OpenBucketA  = $openBucketA.Count
            ResultPath   = $resultPath
        }
        $checkStatus['Conformance'] = 'Ran'
    }
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
$blocking = @($findings | Where-Object Blocking)
$advisory = @($findings | Where-Object { -not $_.Blocking })
$blessed = $blocking.Count -eq 0

$report = [pscustomobject]@{
    Target      = $root
    ModuleName  = $ModuleName
    RunAt       = (Get-Date).ToString('o')
    Checks      = [pscustomobject]$checkStatus
    Blessed     = $blessed
    Blocking    = $blocking.Count
    Advisory    = $advisory.Count
    Conformance = $conformance
    Findings    = @($findings)
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding utf8

Write-Host ''
foreach ($finding in $findings) {
    $label = if ($finding.Blocking) { 'BLOCK' } else { 'note ' }
    $where = if ($finding.File) { " [$($finding.File)$(if ($finding.Line) { ":$($finding.Line)" })]" } else { '' }
    Write-Host "  $label $($finding.Check)/$($finding.Rule)$where  $($finding.Message)"
}
Write-Host ''
Write-Host ("TIDY  $(if ($blessed) { 'BLESSED' } else { 'REFUSED' })   " +
    "blocking $($blocking.Count)   advisory $($advisory.Count)   ->  $ReportPath")

$report

if (-not $NoExitCode -and -not $blessed) { exit 1 }
exit 0
