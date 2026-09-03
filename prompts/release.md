# release.md — cutting a version

Fresh session, first message. Run it immediately before a version and not as a
routine sweep — tidy grades the *repository* against itself, and most of what it
finds is drift between two things that were both correct when they were written.

**The last two steps are yours and the agent will not do them.** Publishing is
not a step this plugin performs, ever, from anybody's session. That is not a
limitation to be worked around; it is the one boundary that makes the rest of it
safe to run unattended.

---

```
# CUT A VERSION

Module: <PSYourModule>
Repository: <path>
Version I think this is: <x.y.z>, because <one sentence>

## 1. Tidy - the pre-release sweep

Run it the way the powershell-module-tidy skill states - the skill names
its own script path, and where that script lives depends on whether you
installed the plugin or cloned the repository. It takes the repository root
and writes a JSON report:

    Invoke-ModuleTidy.ps1 -Path <path> -ReportPath ./tidy-report.json

Exit 0 means blessed. Exit 1 means at least one blocker. Give me the
findings by check, not a summary:

- naming and layout conformance
- public surface versus documentation parity, BOTH directions - a documented
  command that does not exist is as much a defect as an undocumented one
- dead files
- docs/PLAN.md currency. Stale is mechanical: the newest commit touching
  src/ is newer than the newest commit touching docs/PLAN.md. If it fires,
  the fix is a one-line edit saying the work landed, not an argument.

An open Bucket-A item blocks the release. Do not bless around it.

## 2. Conformance - the shape score

    pwsh -NoProfile -Command "& ./evals/conformance/Invoke-Conformance.ps1 `
        -Path <path> -ModuleName <PSYourModule> `
        -Tag @('Universal','Repository','HouseStyle','RequiresBuild') `
        -ResultPath <path>/conformance-result.json"

Use -Command and not `pwsh -File`: -File flattens the comma-separated -Tag
into one token and the filter then silently selects the wrong set. And name
-ResultPath explicitly, because the default writes into the CURRENT
directory rather than the target's.

Report cases-run over cases-DEFINED, and the failures by name. Two things I
want said out loud before the number:

- whether every suite container LOADED. One that failed discovery takes its
  assertions with it and leaves a score that looks entirely normal.
- whether cases-defined has moved since the last release. If it has, this
  score and the last one are separate series and must not be compared.

Read the score from the result JSON, never from the exit code. A red run
exits 0 on purpose - the run succeeded, the module failed, and those are
different facts.

## 3. Version, changelog, worklog

Decide the number against the SURFACE, not against how much work it felt
like:

- PATCH - defects fixed, documents corrected. Nothing a user does changes.
- MINOR - new commands, new parameters, new conventions. Existing use keeps
  working.
- MAJOR - a command removed or renamed, a return shape changed, a convention
  reversed. Existing use can break.

Then: CHANGELOG entry, worklog entry, and the version in the manifest. The
manifest version and the tag must state the same number - if they ever
disagree that is a defect, not a variant.

## 4. Stop here, and hand back

Prepare the annotated tag and SHOW me the command. Do not run it.

Then perform the LOCAL HANDOFF and end with the LOCAL STATE table - every
repository on main, pulled ff-only, tags fetched, status clean, as
repo | branch | HEAD | clean - so I can see exactly what I am about to tag.
```

---

## The two verbs that are yours alone

**HUMAN ONLY. Do not put either of these in a prompt, and do not accept a
session's offer to run them.**

```powershell
# 1. Tag the release, from your own shell, after you have read the tidy
#    report and the conformance score yourself.
git tag -a v<x.y.z> -m "<what changed, and what it was measured against>"
git push origin v<x.y.z>

# 2. Publish, if you publish at all.
Publish-Module -Name <PSYourModule> -NuGetApiKey <your key>
```

Why this line and not another: everything above it is reversible inside your own
repository, and everything below it reaches other people. A tag, once pushed, is
immutable — a release that was wrong is superseded by a new version, never by
moving a tag. And a module on a gallery cannot be recalled from the machines
that have already installed it.

There is a second reason, and it is about evidence rather than safety. **The
green run is not the release decision.** Tidy and conformance tell you the
repository is internally consistent and conforms to a set of conventions; neither
of them knows whether this version is one anybody should install. That judgement
has no oracle, which is exactly why it belongs to a person.

**Nothing here is a claim that your module is ready.** A blessed tidy report and
a full conformance score are two measurements of shape. They say nothing about
whether the module does the thing it exists to do — that is what your own tests
are for, and your module earns those numbers itself.
