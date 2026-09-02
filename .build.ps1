<#
    InvokeBuild entry point for the harness repository.

    Thin on purpose. A task here is a name and a call; the logic lives in
    tools/publish/, where it can be read, tested and falsified without
    InvokeBuild in the way. See docs/creating-an-agent/09-try-before-you-trust.md.

    Neither task pushes anything, ever. Publishing is the operator's verb.

    Both tasks invoke their script in a CHILD pwsh process and throw on a
    non-zero exit. The reason is a defect found while writing this file:
    `& script.ps1` runs in-process, so a script's `exit 1` unwinds that script
    and sets no `$LASTEXITCODE` InvokeBuild can see. PublishReal printed
    `GUARD: refused` in full and the build reported *succeeded, 0 errors*. The
    refusal was visible and the failure was not, which is exactly the shape
    evals/HARNESS.md keeps recording: an unobserved exit code is a claim.

    `-File` is deliberate and safe here because every argument is a single
    string. It would not be safe for an array parameter - LEDGER item 15:
    `pwsh -File` flattens `-Tag a,b,c` into one token, silently.
#>

$ErrorActionPreference = 'Stop'

function Invoke-PublishScript {
    param([string]$Script, [string[]]$Arguments = @())
    & pwsh -NoProfile -File (Join-Path $PSScriptRoot "tools/publish/$Script") -RepoRoot $PSScriptRoot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Script exited $LASTEXITCODE." }
}

# Stage a local marketplace under scratch/ and print the two /plugin commands
# to paste inside Claude Code. Writes nothing outside scratch/.
task PublishLocal {
    Invoke-PublishScript -Script 'Publish-Local.ps1'
}

# Guard. Refuses while .claude-plugin/marketplace.json is absent (true until
# pass 0030); once present, prints the operator's checklist and still publishes
# nothing itself.
task PublishReal {
    Invoke-PublishScript -Script 'Publish-Real.ps1'
}

task . PublishLocal
