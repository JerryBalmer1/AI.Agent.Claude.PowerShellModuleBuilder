# first-module.md — message one

Paste the fenced block below as the **first message of a brand-new Claude Code
session**, in the directory that will hold your module. Nothing before it, no
preamble of your own: see
[why fresh sessions](README.md#why-every-one-of-these-starts-a-fresh-session).

Replace every `<...>` before you paste. If you do not know an answer yet, say so
in the block — the plan skill is going to ask you anyway, and an honest "not
decided" is a better input than a guess you will not remember making.

**What you should have when it finishes:** a planned, scaffolded, building,
tested module; `docs/PLAN.md` on disk saying where it stands; and a LOCAL STATE
table as the last thing in the reply. If that table is missing, the work is not
finished — [troubleshoot.md](troubleshoot.md), symptom one.

---

```
# BUILD MY FIRST MODULE

Module name: <PSYourModule>
One-sentence purpose: <what question does this answer for a user?>
Target directory: <. or an absolute path>

## 0. Prerequisites, before anything else

Run this in a shell, not inside Claude Code, and paste me the output:

    pwsh -NoProfile -File ./tools/publish/Test-Prerequisites.ps1

If you do not have this repository cloned, check the same five by hand:
PowerShell 7.2 or later, Pester 6.x, PSScriptAnalyzer, InvokeBuild, and git.
A missing $env:AZDO_PAT does NOT matter here - it is needed only by the three
Azure DevOps skills and not to build a module.

STOP if any of the five is missing, and tell me the exact line that fixes it.
Do not work around a missing tool.

## 1. Install the plugin, pinned

Paste these inside Claude Code, in this order:

    /plugin marketplace add JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder@v1.2.0
    /plugin install psmodule@psmodule-builder

The @v1.2.0 is the pin and it is not optional. main moves whenever a pass
lands; pinning is what keeps work in progress from reaching me. Confirm with
/plugin that psmodule reports 1.2.0, and tell me if it does not.

## 2. Intake - ask before building

Use the powershell-module-plan skill and ask me ALL SIX questions. Do not
skip one because the answer looks obvious from the name above; write the
obvious answer down, because obvious is where the two of us disagree
silently.

Then ask about any convention the six questions did not cover, and name every
convention you are about to guess at. A guessed field name that nobody wrote
down is the single most common way this goes wrong.

Question 6 - the definition of done - is mandatory and is the one the rest of
the plan is for. It must name how the work will be TESTED, before the work is
written.

## 3. Write the plan down, in the repository

Two documents, and they are different things:

- docs/plans/0001-<slug>.md   this piece of work, numbered and frozen
- docs/PLAN.md                where the module stands NOW, plain language,
                              exactly one of it, always current

docs/PLAN.md carries five things and nothing else: what this module is, why
it exists, where it stands (the honest version, including what is merely
written rather than measured), what is next, and where the detailed records
live. Write it for somebody who will never open the machinery.

Commit both before writing any code.

## 4. Build it

Follow powershell-module-architect, then powershell-module-scaffold, then
powershell-module-build, with powershell-module-docs and powershell-module-ux
alongside. Then:

    /psmodule:build <PSYourModule> <target directory>

Where a skill and the conformance suite disagree, the SUITE is the oracle and
the disagreement is a finding worth telling me about rather than resolving by
preference.

## 5. Test it, and report two numbers

    /psmodule:test <target directory> <PSYourModule>

Report the build score and the conformance score as TWO numbers, never
averaged, and never a percentage on its own. For conformance, give me
cases-run and cases-defined, and the failures by name. A red conformance run
is data, not a disaster - the number is only worth having because it is
allowed to be bad.

If a suite container fails to LOAD, say so before quoting any number. A
container that never ran takes its assertions with it and leaves a score that
looks ordinary.

## 6. Close out

- Commit on a branch, not on main, and push it.
- Tell me what you did NOT do, what you guessed at, and anything in this
  prompt that was wrong, unclear or impossible. That section is mandatory and
  "none" is an acceptable answer only if it is true.
- Then perform the LOCAL HANDOFF and end your reply with the LOCAL STATE
  table: for every repository in this workspace - checkout main, git pull
  --ff-only, git fetch --tags --prune, git status clean - then a table of
  repo | branch | HEAD | clean. Report a diverged branch or a dirty tree;
  never resolve one silently.

## What I do not want

Do not tell me the module scores well because this plugin was measured. It
was measured against somebody else's module. Mine earns its own numbers, and
this run is the first of them.
```

---

## After it finishes

Read the artifacts, not the summary. The reply is prose the agent wrote about
its own work; `docs/PLAN.md`, the conformance output and the pushed branch are
not. [Chapter 05](../docs/creating-an-agent/05-calling-bullshit-verification.md)
is the audit, and [troubleshoot.md](troubleshoot.md) is what to do when
something in it does not add up.

Next change to this module: [new-feature.md](new-feature.md), which is
deliberately shorter, because the six questions have already been answered.
