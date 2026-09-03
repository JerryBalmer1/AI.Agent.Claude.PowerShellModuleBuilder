---
name: powershell-module-ux
description: Argument completion for a PowerShell module — deciding when a parameter earns a completer at all, choosing between ValidateSet, [ArgumentCompleter] and a class implementing IArgumentCompleter, the session-cache pattern that makes a slow enumeration feel instant, the Pester test every completer must ship with, and the error standard — every terminal error states the fix or names the doc, in one line, before any detail. Use when adding a completer, when tab-completion is slow enough to be noticed, when a parameter's valid values come from somewhere expensive, or when writing the message a user sees when something fails.
---

# Argument completion

Completion is the only part of a module most users experience before they read
any help. It is also the part most likely to be added on feel, because nothing
grades it and nothing breaks when it is wrong — it just quietly gets slower, or
quietly suggests values that no longer exist.

This skill is judgment about **when** and **which**. The mechanics are three
attributes, and they are the short part.

## When completion earns its place

A parameter earns a completer when all three are true:

1. **The value set is enumerable.** You can produce the candidate list from
   somewhere — a fixed list, a directory, an API, the module's own state.
   "Any string the user thinks of" earns nothing.
2. **The value set is discoverable only by asking.** If the user already knows
   the value because they typed it two commands ago, completion saves a few
   keystrokes and nothing else. Completion pays when it *answers a question* —
   which projects exist, which of my subscriptions is this, what did I call
   that resource.
3. **The set is stable within a session.** Not immutable — stable. If a value
   can appear and disappear between two presses of Tab, completion will suggest
   something the next line rejects, and the user learns to distrust it.

The counter-case is worth stating because it comes up constantly: **a `-Path`
parameter typed as `[string]` should not get a custom completer.** PowerShell
already completes paths for a parameter named `Path`, and a custom completer on
it replaces something good with something worse.

**Completion is not validation.** Deciding a parameter should suggest values is
a different decision from deciding it should reject values, and conflating them
is how a module ends up unable to accept a legitimate value that was created
after the module shipped. Make the two decisions separately, in that order.

## Choosing the mechanism

| | Use when | Costs |
|---|---|---|
| `[ValidateSet()]` | the set is closed, known at authoring time, and you *want* to reject anything else | changing the list is a breaking change; a valid new value is rejected until you ship |
| `[ArgumentCompleter()]` | the set is computed, or open — you suggest, the user may still type anything | one scriptblock per parameter, and no reuse |
| a class implementing `IArgumentCompleter` | the same set completes more than one parameter, or the completer is complex enough to want its own tests | the type must be loadable where the attribute is parsed |

`[ArgumentCompletions()]` (PowerShell 7+) is the fourth, and it is
`[ValidateSet()]` with the validation removed: a literal list, suggested and not
enforced. Reach for it when the list is literal *and* open. If you are writing a
scriptblock whose entire body is a literal array, this is the attribute you
wanted.

### `[ValidateSet()]` — closed sets only

```powershell
function Get-PSModuleReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Text', 'Json', 'Html')]
        [string] $Format
    )
    "rendering $Format"
}
```

Correct here because `Format` is genuinely closed — the module implements three
renderers and a fourth does not exist until the module ships one. That is the
test: **would a value outside the set be a user error, or just a value you have
not heard of yet?** Only the first case is a `ValidateSet`.

### `[ArgumentCompleter()]` — computed or open sets

The scriptblock is handed five arguments, positionally, and the order is fixed:

```powershell
function Get-PSModuleReport {
    [CmdletBinding()]
    param(
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

            Get-PSModuleProfileName |
                Where-Object { $_ -like "$wordToComplete*" } |
                ForEach-Object {
                    [System.Management.Automation.CompletionResult]::new(
                        $_,          # what is inserted
                        $_,          # what the menu shows
                        'ParameterValue',
                        "profile $_" # the tooltip
                    )
                }
        })]
        [string] $Profile
    )
}
```

Three rules that are not obvious and cost a bug each:

- **Filter on `$wordToComplete`, always.** A completer that returns the whole
  set regardless of what has been typed makes the menu useless at exactly the
  point the user has narrowed it. `-like "$wordToComplete*"` is the whole fix.
- **Quote a value containing a space in the *first* argument.** The first
  argument is inserted into the command line verbatim; if the value can contain
  a space, emit the quoted form there and the bare value as the list item.
- **`$fakeBoundParameters` is a hashtable of what has been typed so far, and
  the values in it are not validated or coerced.** Use it to make one
  parameter's completion depend on another — complete `-Project` from whatever
  `-Organisation` currently says — and guard every read of it, because the user
  may not have typed that parameter yet.

### A class implementing `IArgumentCompleter` — for reuse and for tests

When the same set completes three parameters across four commands, the
scriptblock has been copied three times and the copies have already drifted.

```powershell
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

class ProfileNameCompleter : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string] $commandName,
        [string] $parameterName,
        [string] $wordToComplete,
        [CommandAst] $commandAst,
        [IDictionary] $fakeBoundParameters)
    {
        $results = [List[CompletionResult]]::new()
        foreach ($name in [ProfileNameCompleter]::GetNames()) {
            if ($name -like "$wordToComplete*") {
                $results.Add([CompletionResult]::new(
                    $name, $name, [CompletionResultType]::ParameterValue, "profile $name"))
            }
        }
        return $results
    }

    static [string[]] GetNames() { return @('default', 'ci', 'local') }
}
```

Applied as `[ArgumentCompleter([ProfileNameCompleter])]`.

**The trap that makes this the third choice rather than the first:** the
attribute is resolved when the *file is parsed*, so the type must already exist
at that moment. Inside a module built to this plugin's conventions, that means
the completer class lives in a file the generated psm1 dot-sources **before**
the functions that reference it, and a consumer who wants the type in their own
session needs `using module <Name>` rather than `Import-Module`. Put the class
in `Private/Completers/`, keep the psm1 emitter's sorted, deterministic
ordering, and assert the ordering in the build — a completer that works in your
session and not in a fresh one is this, every time.

**The payoff is that `CompleteArgument` is a method you can call directly.**
That is a unit test with no shell, no command line, and no cursor position, and
it is why a complex completer belongs in a class even when only one parameter
uses it.

## The session cache

Completion runs on the keystroke. A user who presses Tab does not know they are
triggering an API call, and will press it again when nothing happens.

**Cost threshold: if producing the candidate list takes more than about 200ms,
cache it. If it is faster than that, do not** — a cache is state, state goes
stale, and staleness is a worse failure than a pause nobody notices. Measure
before you decide; `Measure-Command` on the enumeration is the whole decision.

The pattern is a `$script:` cache populated on the first *real* call — the
command's own execution — rather than on the first completion, so the expensive
work happens where the user is already waiting:

```powershell
# Private/Cache/Get-PSModuleProfileName.ps1
function Get-PSModuleProfileName {
    [CmdletBinding()]
    param([switch] $Refresh)

    if ($Refresh -or $null -eq $script:ProfileNameCache) {
        $script:ProfileNameCache = @{
            At    = [datetime]::UtcNow
            Names = @(Read-ProfileNameFromSource)   # the expensive call
        }
    }
    $script:ProfileNameCache.Names
}
```

### Guardrails, stated as rules

These are rules, not preferences. Each one exists because the cheap version of
the pattern violates it.

1. **Expose a refresh path and a clear path, both public.** `-Refresh` on the
   producer is not enough — a user whose completion is wrong needs a command
   they can find. Ship `Clear-<Prefix>Cache` and name it in the `about_` topic.
   A cache with no user-reachable reset is a bug report you cannot answer.
2. **Document staleness where the user reads, not where you wrote it.** State
   in the parameter's `.PARAMETER` help that completion is served from a
   session cache, and name the command that refreshes it.
3. **Never cache secrets, credentials, tokens, or PAT-derived values — not in a
   variable, not on disk, not for the length of one session.** This includes
   anything *derived* from one: a list of resources a token was authorised for
   is a description of that token's scope. A completer's cache is a
   process-lifetime variable that no code path clears on sign-out, and it will
   be dumped by the first `Get-Variable` in a diagnostic script.
4. **Cache the answer, never the authorisation.** If the candidate list depends
   on who is signed in, the cache key includes that identity, or the cache is
   cleared when it changes. Completion that suggests the previous account's
   resources is a disclosure, not a glitch.
5. **A cache miss must be silent and must not throw.** Completion runs inside
   the reader's keystroke handling; an exception there produces a corrupted
   prompt rather than an error message. Wrap the body, return nothing on
   failure, and let the real invocation report the problem properly.
6. **Timestamp the cache.** Not to expire it automatically — a completer that
   re-fetches on a timer reintroduces the pause you cached to avoid — but so
   that the refresh command can say how old the data was.

## A completer without a test does not ship

Completion is invisible to every other gate in this plugin. The build does not
run it, the analyzer does not execute it, and the conformance suite reads
source. Nothing but a test will tell you a completer broke.

It is testable, and the entry point is
`[System.Management.Automation.CommandCompletion]::CompleteInput` — the same
call the shell makes:

```powershell
Describe 'Get-PSModuleReport -Profile completion' {
    BeforeAll {
        Import-Module "$PSScriptRoot/../output/PSModuleDemo" -Force
    }

    It 'offers the known profiles' {
        $line = 'Get-PSModuleReport -Profile '
        $completion = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $line, $line.Length, $null)

        $completion.CompletionMatches.CompletionText | Should -Contain 'default'
    }

    It 'narrows to what has been typed' {
        $line = 'Get-PSModuleReport -Profile c'
        $completion = [System.Management.Automation.CommandCompletion]::CompleteInput(
            $line, $line.Length, $null)

        $completion.CompletionMatches.CompletionText | Should -Be @('ci')
    }
}
```

The second test is the one that matters and the one that gets left out. **A
completer that returns everything passes the first test**, which is why the
narrowing case is mandatory rather than thorough — it is the substitution
control for a completer, in exactly the sense `powershell-module-test` means it.

For a class-based completer, add the direct-call test as well; it runs without
importing anything and it is where the interesting cases go:

```powershell
It 'quotes a value containing a space' {
    $results = [ProfileNameCompleter]::new().CompleteArgument(
        'Get-PSModuleReport', 'Profile', '', $null, $null)
    ($results | Where-Object { $_.ListItemText -eq 'my profile' }).CompletionText |
        Should -Be "'my profile'"
}
```

Three cases, minimum, per completer:

- [ ] empty `$wordToComplete` returns the full set
- [ ] a partial word **narrows** the set
- [ ] a word matching nothing returns empty and does not throw

And for a cached completer, a fourth: **the refresh path actually re-reads.**
Clear the cache, mock the source to return something different, and assert the
completion changed. A cache whose refresh is inert is the same defect class as
an assertion that cannot go red.

## The error standard: state the fix, or name the doc, first

Completion is what a user meets before reading any help. **An error message is
what they meet before reading anything at all**, and they are already blocked
when they meet it. Both are this skill's subject for the same reason: nothing
grades either one, and nothing breaks when either is wrong.

**Every terminal error states the fix, or names the document that has it, in
one line, before any detail.**

Write for the person who will paste your message into a search box. Yours
should answer before the search does. That is not a stylistic aspiration; it is
what determines whether the next thing that happens is a fix or a tab.

```powershell
# No. Each of these describes a condition and leaves the reader to find a fix.
throw "Invalid configuration."
throw "Cannot bind argument to parameter 'Path' because it is null."
throw "Operation failed: the specified item was not found in the collection."

# Yes. The fix is the first thing; the diagnosis follows it.
throw "Set `$env:AZDO_PAT to a personal access token with Code (read), then re-run. It is unset, and every command in this module authenticates with it."
throw "Run 'Install-Module Pester -MinimumVersion 6.0' and re-run. Pester 6 is required, $found is installed, and the ordered runner uses Should-Be, which 5.x does not have."
throw "'$Path' has two manifests under src/: '$first' and '$second'. Pass -ModuleName to say which one to grade. Grading the wrong one silently is the failure this refuses to commit."
```

Three rules, and the third is the one people skip:

1. **The fix precedes the diagnosis.** Not after it, not in a `.NOTES` block,
   not in the documentation the message links to. First.
2. **Name the thing, with its value.** `'$Path'` and not "the path"; both
   manifests and not "multiple manifests". A reader who has to work out which
   of their inputs you mean has been handed a second problem.
3. **When there is no one-line fix, name the document that has it** — a path in
   the repository or an `about_` topic, never "see the documentation". An error
   that says a fix exists somewhere is an error that has told the reader they
   are on their own.

**The worked example is `Test-Prerequisites.ps1`** in this repository's
`tools/publish/`. It checks five prerequisites and reports each missing one
with the exact line that installs it. Two details in it are the whole standard:

- It says **in so many words** which of the five can be knowingly ignored, and
  why — so `1 of 5 missing` is a decision the reader makes rather than a
  mystery they have to resolve.
- It runs under **Windows PowerShell 5.1 on purpose.** A prerequisite checker
  that will not start on the wrong PowerShell is useless exactly when it is
  needed, and "upgrade PowerShell, then run the thing that tells you to upgrade
  PowerShell" is the error standard failing in its purest form.

**For a completer specifically**: a completer never throws. It returns nothing.
So when the expensive enumeration behind one fails, the failure belongs on the
*command's* error path, not swallowed in the completer and not surfaced as an
empty list — an empty completion list is indistinguishable from "there are no
valid values", which is a different and much more confusing statement.

This is the module-facing half of the report contract that governs this
project's own passes: `docs/ux/UX-003-report-contract.md`, where the same rule
is why a hard stop leads with what to do and puts the forensics underneath.

## Sources

The technique catalogue here is distilled from Tobias Weltner's
**powershell.one**, which is the clearest published treatment of these
attributes. Nothing on this page is reproduced from it — the prose, the
examples, the thresholds and the guardrails are this plugin's, and where they
disagree with the source that is deliberate and marked.

- [Argument Completion Attributes](https://powershell.one/powershell-internals/attributes/auto-completion)
  — the five scriptblock arguments and their order, `CompletionResult`,
  respecting user input, responding to other arguments via
  `$fakeBoundParameters`, and the PowerShell 7 `[ArgumentCompletions()]`
  shortcut.
- [Creating Custom Attributes](https://powershell.one/powershell-internals/attributes/custom-attributes)
  — implementing `IArgumentCompleter` in a PowerShell class, and deriving from
  `ArgumentCompleterAttribute` so a completer can take constructor arguments.
- [Auto-Learning Auto-Completion](https://powershell.one/code/14.html)
  — a completer that learns values from use and persists them.

**Where this skill deliberately departs from its source.** The auto-learning
article persists learned values to `$env:TEMP`, including credentials, as
encrypted XML. That is a fine trick for a personal profile and it is
**forbidden** in a module built to these conventions: rule 3 above is absolute,
and it is absolute because a module is installed by people who did not read its
source and cannot know that tab-completion wrote something to disk. Learn values
if you like; learn them in memory, for the session, and never learn a
credential.

## Related

- `powershell-module-architect` — the parameter sets a completer completes.
- `powershell-module-docs` — the `.PARAMETER` entry that documents the cache.
- `powershell-module-test` — the narrowing case as a substitution control.
- `powershell-module-build` — psm1 emitter ordering, which is what makes a
  class-based completer resolve in a fresh session.
- `powershell-module-docs` — an error that names a document needs the document
  to exist, and `about_` topics are where a fix too long for one line lives.
