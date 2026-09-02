# 09 — Try before you trust

You do not have to trust this repository, or the model that helped write it,
in order to find out what it does. Not trusting an AI-authored toolchain
enough to install it is a reasonable starting position, and this chapter is
not going to argue you out of it. It gives you something better than an
argument: a way to run the whole thing on your own machine, watch it work,
and take it off again, with nothing leaving the machine and nothing
published anywhere.

Two words before the steps, because both are used throughout.

- A **plugin** is a folder Claude Code can load. It contains skills
  (markdown files of instructions) and commands (markdown files that define
  a slash command such as `/psmodule:build`). Nothing in it is compiled and
  nothing in it is binary.
- A **marketplace** is a folder containing a `marketplace.json` that lists
  one or more plugins and where to find them. Claude Code adds a
  marketplace, then installs plugins from it. A marketplace can be a public
  GitHub repository, and it can equally be a directory on your own disk.
  This chapter uses the second kind.

The repository ships a build task that constructs a marketplace of the
second kind under `scratch/`, and a second task that refuses to publish the
first kind. Both are in [.build.ps1](../../.build.ps1); their logic lives in
[tools/publish/](../../tools/publish/), where it can be read without
InvokeBuild in the way.

---

## Before you start

The repository's own "Running it" section lists what the harness needs:
**PowerShell 7.2+, Pester 6.x, PSScriptAnalyzer, InvokeBuild**
([README.md](../../README.md)). The staging task itself needs PowerShell
7.2 and InvokeBuild; the other two are needed once you start building
modules with it.

Check what you have:

```powershell
$PSVersionTable.PSVersion
Get-Module -ListAvailable Pester, PSScriptAnalyzer, InvokeBuild |
    Select-Object Name, Version
```

If InvokeBuild is missing:

```powershell
Install-Module InvokeBuild -Scope CurrentUser
```

You also need Claude Code itself for steps 3 and 4. Steps 1 and 2 are plain
PowerShell and do not involve Claude at all.

---

## Step 1 — clone it

<!-- TEMPLATE:replace -->

```powershell
git clone https://github.com/JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder
cd AI.Agent.Claude.PowerShellModuleBuilder
```

That URL is the `repository` field of
[.claude-plugin/plugin.json](../../.claude-plugin/plugin.json). It is worth
knowing where it comes from: README.md's ecosystem table lists the other
five repositories by URL and names this one only as "this one", so the
canonical URL for the repository you are reading is in the manifest — and
it is echoed back at you by the publication guard in
[publishreal-guard.txt](../../plans/0031-operators-manual/publishreal-guard.txt).

Cloning gives you the harness, the evaluation suites, the records, and the
plugin. Nothing runs on clone.

---

## Step 2 — stage a local marketplace

**What this does, before you run it:** it copies the plugin manifest, the 14
skills and the 2 commands into `scratch/local-marketplace/` beside a
`marketplace.json` it generates, validates that JSON itself, and prints two
commands for you to paste into Claude Code. It writes nothing outside
`scratch/`, and it pushes nothing.

From the repository root:

```powershell
Invoke-Build PublishLocal
```

The real output, captured in
[publishlocal-transcript.txt](../../plans/0031-operators-manual/publishlocal-transcript.txt),
is:

```
Repository: C:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\AI.Agent.Claude.PowerShellModuleBuilder
Staging to: C:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\AI.Agent.Claude.PowerShellModuleBuilder\scratch\local-marketplace
Staged 14 skills and 2 commands.
Validation passed: both JSON files parse, the source path resolves, skills and commands are present.
```

Those paths are the machine this was recorded on. Yours will differ; the
counts should not.

**One honest caveat about the validation.** Claude Code's own CLI can check
a plugin against the real schema, which is a stronger check than the four
things the script verifies for itself. The script attempts it, and when the
CLI is not available it says so out loud rather than skipping quietly. The
next line of the same transcript is:

```
claude CLI: not on PATH. Skipped the CLI schema check - the JSON checks above are what ran, and they are weaker.
```

That sentence is the point. A missing tool that silently skips its own
check is the failure mode this repository keeps recording; a missing tool
that names itself is a result you can act on. If you want the stronger
check, put `claude` on your `PATH` and re-run — the script will use it and
print its exit code.

---

## Step 3 — add and install it, inside Claude Code

The task ends by printing four commands: two to install, two to remove.
**These are pasted inside a Claude Code session, not into your shell.** They
begin with a slash because they are Claude Code commands; typed at a
PowerShell prompt they are a syntax error.

The two install commands, in the exact form the transcript records:

```
/plugin marketplace add C:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\AI.Agent.Claude.PowerShellModuleBuilder\scratch\local-marketplace
/plugin install psmodule@psmodule-local
```

Do not retype that path. It is the path on the machine where the transcript
was recorded. Copy the line your own run printed — it names your clone's
`scratch/local-marketplace` directory. The second command is the same for
everybody: `psmodule` is the plugin's name and `psmodule-local` is the name
the task gives the staged marketplace.

Nothing about this reaches the network. The marketplace you just added is a
directory on your disk that you can open in a file browser.

---

## Step 4 — drive it once

The plugin installs one command worth trying first: `/psmodule:build`. Its
definition is [commands/build.md](../../commands/build.md), and it takes two
arguments — a module name and a target directory:

```
/psmodule:build MyScratchModule C:\temp\my-scratch-module
```

Pick a directory you do not mind deleting. Here is what the command file
actually tells Claude to do, so you know what you are watching:

1. **Read the contract first.** It asks for
   `evals/conformance/Conformance.Tests.ps1` and `evals/functional/BRIEF.md`
   before any code is written, on the grounds that the conventions "are
   graded exactly" and must not be inferred from memory. In a scratch
   directory outside this repository neither file exists, so expect Claude
   to say so and continue from the skills alone. That step is also a
   recorded finding for a different reason — see F-6 in
   [runs/006-plugin-on/findings.md](../../runs/006-plugin-on/findings.md),
   where the measured runs *declined* step 1 because the blind-run rules
   forbade reading the grader.
2. **Scaffold** `src/<Name>/{<Name>.psd1,Public/,Private/}`, `tests/`,
   `build.ps1`, `<Name>.build.ps1`, `PSScriptAnalyzerSettings.psd1` and
   `Requirements.psd1`. `Public/` is flat, one function per file named for
   the file, each with `.SYNOPSIS` help.
3. **Write the commands**, one public function per file, helpers under
   `Private/`.
4. **Write tests that invoke every public command** — the assertion parses
   for a real call, so a command named only inside a string counts as
   untested.
5. **Run `./build.ps1`**, which runs Clean, Lint, Build and Test. Lint
   findings are a gate, not a report.
6. **Report** the exit code, the analyzer finding count, the Pester
   pass/fail/skip counts, and coverage against the declared target.

So what you should see is a scaffolded module, a lint pass, a Pester run
and a numeric report — not prose claiming success.

**Expect the coverage number to be wrong.** The most serious finding in
this repository is F-1: *the build skill's coverage-gate template cannot
fail as shipped*. Copied faithfully, the `Test` task prints
`Line coverage: 0% (target %)`, exits 0 and grades nothing, because
`Invoke-Pester` returns nothing without `Run.PassThru` — so the gate
compares `0 -lt $null` and never fires. One missing line, two dead gates, no
symptom. It is written down in [README.md](../../README.md), it recurred in
all three measured plugin-on runs, and it is still in the shipped skill. If
your first build reports a suspiciously round coverage figure, that is the
reason, and you have reproduced a known defect rather than found a new one.

---

## How to uninstall

The same task prints the removal pair. From the transcript:

```
/plugin uninstall psmodule@psmodule-local
/plugin marketplace remove psmodule-local
```

Paste those two inside Claude Code, then delete the staged directory from
your shell:

```powershell
Remove-Item -Recurse -Force ./scratch/local-marketplace
```

That is the whole footprint. `scratch/` is the first line of the
repository's [.gitignore](../../.gitignore), so nothing staged there was
ever a candidate for a commit, and deleting it cannot lose anything the
repository was tracking. To remove the rest, delete the clone.

---

## What you can check for yourself

This section is deliberately narrow. Everything in it is something you can
verify with a command; the last part says plainly what none of it proves.

### The staged files are the repository's own files, byte for byte

Nothing is generated except the `marketplace.json`, and that one is
generated rather than copied because this repository has no committed
`marketplace.json` at all — see the guard, below. Everything else is a
copy. Section 3 of the transcript records the comparison:

```
--- (3) Byte comparison: staged copies vs the repository's originals ---
  .claude-plugin/plugin.json         66BE6D1C0DFB9ABE  MATCH
  skills/                            16 files compared
  commands/                          2 files compared
  mismatches: 0
```

Sixteen files across fourteen skill directories: fourteen `SKILL.md` files
plus a plan template and one helper script. You can re-derive the row
yourself after staging:

```powershell
$src = (Resolve-Path ./skills).Path
$dst = (Resolve-Path ./scratch/local-marketplace/psmodule/skills).Path
Get-ChildItem $src -Recurse -File | Where-Object {
    (Get-FileHash $_.FullName).Hash -ne
    (Get-FileHash ($_.FullName.Replace($src, $dst))).Hash
}
```

No output means no mismatches.

### The marketplace points inside itself

A marketplace entry's `source` is where Claude Code goes to find the
plugin. If it were an absolute path, a URL, or a `../` escape, the staged
directory would not be self-contained. The validator in
[Publish-Local.ps1](../../tools/publish/Publish-Local.ps1) asserts that it
is a relative `./` path, and separately that the path exists:

```powershell
if ($entry.source -notmatch '^\./') {
    $bad.Add("marketplace entry '$($entry.name)' source '$($entry.source)' is not a relative './' path")
}
$resolved = Join-Path $Stage ($entry.source -replace '^\./', '')
if (-not (Test-Path -LiteralPath $resolved)) {
    $bad.Add("marketplace entry '$($entry.name)' source '$($entry.source)' does not exist at $resolved")
}
```

The generated file the transcript records has `"source": "./psmodule"`,
which resolves to the plugin directory beside it and nowhere else. Open
`scratch/local-marketplace/.claude-plugin/marketplace.json` and read it —
it is about fifteen lines.

That validator is not a decoration, and the transcript proves it can fail.
Row 1 of the falsification section corrupts one byte of the staged file —
`byte[0] before : 0x7B  '{'`, `byte[0] after  : 0x21  '!'` — then re-runs
the same validator through its `-ValidateOnly` entry point:

```
VALIDATION FAILED:
  - does not parse as JSON: ...\.claude-plugin\marketplace.json -- Conversion from JSON failed with error: Unexpected character encountered while parsing value: !. Path '', line 0, position 0.
exit: 1
```

Row 2 is the control: it restages clean, adds a harmless extra key — still
valid JSON, source still resolves — and the validator stays green:
`EXPECTED GREEN : CONFIRMED - it checks validity, not sameness`. A checker
that goes red on any change is refusing change rather than checking
validity, and the control is what tells those two apart. That distinction
is the subject of
[05 — calling bullshit](./05-calling-bullshit-verification.md).

### The skills are markdown, and you should read them

Open [skills/](../../skills/). Fourteen directories, one `SKILL.md` in
each. There is no bundled binary, no install script, and no post-install
hook. The instructions Claude will follow are the sentences in those files,
in plain English, and you can read every one of them in an afternoon. Read
them: they are the whole product. If a sentence in one of them looks wrong
to you, you have found the same class of thing the measured runs found —
several of the ten recorded findings are defects in these files' wording.

### The stager refuses to write outside `scratch/`

`Publish-Local.ps1` deletes and rewrites its stage root, which is a
dangerous verb to point at an arbitrary path. It therefore normalises the
path first — so `../` cannot walk out of it — and refuses anything that is
not under the repository's `scratch/`:

```powershell
throw "REFUSED: stage root '$normStage' is not under the scratch root '$normScratch'. This script only ever writes under scratch/."
```

The last section of the transcript is that refusal being provoked on
purpose:

```
--- Safety rail: the stage root must be under scratch/ ---
    exit: 1
    43 |      throw "REFUSED: stage root '$normStage' is not under the scratch  …

  skills/ untouched: True
```

Exit 1, and the directory it was aimed at was still there afterwards.

### What none of this proves

Be clear about the limit. Everything above is a check on *files*: the
copies match, the paths stay inside, the JSON parses, the script refuses
the paths it says it refuses. A skill is not a file that acts. It is
instructions to a model, and instructions can be followed or not followed.
No hash comparison tells you what a model will do after reading one.

This repository has evidence pointing both ways, and both are worth
knowing. The measured runs **declined** an instruction in `/build` step 1
because a different rule forbade it — an instruction not followed, and
correctly so. And runs 004, 005 and 006 all followed the repository-node
rule in `azdo-graph-assembly` exactly as written, and all three came out one
node short, because the rule as stated is wrong. That is F-2, and it is in
[README.md](../../README.md) alongside the rest.

So the guarantee on offer is not "the model will behave". It is narrower
and it is mechanical: **nothing here pushes**. That is the next section.

---

## PublishReal — the guard in front of publication

The second build task is the one that would take this repository public. It
is called `PublishReal`, and today it refuses.

```powershell
Invoke-Build PublishReal
```

What that prints, from
[publishreal-guard.txt](../../plans/0031-operators-manual/publishreal-guard.txt):

```
GUARD: refused.

  Looked for : C:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\AI.Agent.Claude.PowerShellModuleBuilder\.claude-plugin\marketplace.json
  Found      : nothing.
```

The refusal is not a bug and not a missing feature. A Claude Code
marketplace is discovered by a `marketplace.json` committed at a
repository's root; this repository has a `plugin.json` and no
`marketplace.json`, so there is nothing for anyone to add. The guard's own
words for why generating one would be wrong: it "would publish a file that
no pass has falsified and that no cold install has ever been proved
against."

The guard goes green when pass **0030 — packaging** lands, which is the next
pass in [LEDGER.md](../../LEDGER.md). Three things make it green: a
committed `marketplace.json`; a re-version of the `psmodule` manifest away
from `0.1.0` (the LEDGER reserves `v1.0.0` for "passed the ladder"); and a
cold-install proof on a machine that has never seen this repository.

**The guard was falsified, not merely observed refusing.** A guard that has
only ever refused is indistinguishable from one that always refuses. So
section 3 of the same file clones the repository into `scratch/`, drops a
dummy `marketplace.json` into the *clone only*, and runs the guard again:

```
after flip:
  GUARD: passed. A committed marketplace.json is present.

    marketplace : dummy-marketplace
    plugin      : psmodule 0.1.0
```

It flips to the operator's checklist and exits 0. The working repository was
left alone — `Test-Path .claude-plugin/marketplace.json -> False` — and the
clone was removed. The conclusion the file records: "GUARD IS FALSIFIABLE:
refuses (exit 1) without the file, prints the operator's checklist (exit 0)
with it, and publishes nothing on either path."

### It publishes nothing on either path, and that is structural

Read [Publish-Real.ps1](../../tools/publish/Publish-Real.ps1) yourself; it
is ninety-two lines. On the green path it prints a six-step checklist that
*mentions* `git push origin main` and `git tag`. Those are text inside
`Write-Host` string literals. The script executes no `git` command, makes no
network call, and has no push path at all — not a guarded one, not a
`-Force` one. Its own header says why:

> Publishing is the operator's verb. METHOD.md: "Nothing publishes. No
> release, no tag, no push to the default branch, unless the operator does
> it from their own shell." This script therefore has no push path at all -
> not a guarded one, not a -Force one. Adding one would make the rule a
> matter of restraint rather than of code, and this project's whole argument
> is that those are different.

The rule it quotes is a **PORTABLE** safety rail in
[method/METHOD.md](../../method/METHOD.md), where the full text is:

> **PORTABLE.** Nothing publishes. No release, no tag, no push to the
> default branch, unless the operator does it from their own shell. Pushing
> a pass branch is expected.

Read that as a two-part claim. The rule says the agent does not publish; the
absence of a code path says the agent *cannot*, from this script, whatever
it is asked. You do not have to trust the first to get the second. Verify it
the cheap way:

```powershell
Select-String -Path ./tools/publish/Publish-Real.ps1 -Pattern '^\s*(&\s*)?git\s'
```

No output. Every `git` in that file sits inside a quoted string being
printed to your screen, for you to run yourself, deliberately, from your own
shell, if and when you decide to.

---

## Where to go next

If you have got this far you have run it, seen its output, verified four
things about it mechanically, and removed it. That is a better basis for a
decision than either trust or suspicion.

- To understand *why* the repository is shaped this way before adopting any
  of it, [02 — order of operations](./02-order-of-operations.md).
- For the list of ways this project's own gates have failed, so you know
  what to watch for in yours,
  [07 — failure catalog](./07-failure-catalog.md).
- For any term above that was new,
  [08 — glossary](./08-glossary.md).
- To take the method and leave the domain,
  [10 — using this as a template](./10-using-as-a-template.md).
