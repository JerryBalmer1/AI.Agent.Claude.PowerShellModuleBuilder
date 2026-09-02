# Pass 0030 — Release: packaging, adoption boilerplate, v1.0.0

Tier: **full**. Executable behaviour changes (a test assertion amended, two
publish scripts changed, one new script added), so full-tier artifacts are
required and are here: red-first acceptance test, per-task evidence, diff
summary, deviations, `verify.ps1` with falsification probes.

Branch: `pass-0030-release`, from `main` at `c8330d772174c58a73f48b66588735db0c9ba8c5`.

## 1. Preconditions

All four held, each re-derived rather than assumed.

| Precondition | Required | Measured |
|---|---|---|
| Sync; tree clean | clean | `git status --porcelain` empty; `main...origin/main` level |
| Branch created from `main` tip | `c8330d7…` | `git rev-parse HEAD` = `c8330d772174c58a73f48b66588735db0c9ba8c5` |
| No `v1.0.0` on the harness remote | absent | `git ls-remote --tags origin` returned **nothing at all** — the repository had no tags of any kind |
| `.claude-plugin/marketplace.json` absent | absent | directory held `plugin.json` only |
| TF comparator currently **red** | 14 / 1 | `Invoke-Pester evals/tf/Compare-TfGraph.Tests.ps1` → **Passed 14, Failed 1**, the failure being `states what it compared, not just that it matched`: `Expected [int] 57, but got [int] 59` at line 41 |

The last one is the stop condition, and it did not trigger: the suite was red,
so backlog 20 had not been fixed elsewhere and this prompt was not stale.

Environment: pwsh **7.6.5**, Pester **6.1.0**, InvokeBuild **5.14.23**,
Microsoft Windows 10.0.26200. `claude` CLI **not on PATH** — see Deviations 1.

## 2. Acceptance test — red first

`plans/0030-release/accept.Tests.ps1`, written **verbatim** from the prompt and
run before any work:

```text
RED-FIRST: Passed=1 Failed=9 Total=10

Failed   marketplace exists and parses
Failed   manifest is 1.0.0
Failed   adoption boilerplate exists
Failed   prerequisite checker exists with falsification evidence
Failed   backlog 20 fixed: TF comparator tests green
Failed   backlog 22 fixed: PLAN-PROTOCOL clause corrected
Failed   decision 0013 exists
Failed   install docs give the three commands
Failed   v1.0.0 on the remote
Passed   docs updated in the same pass (item 19)
```

**Nine of ten red is the right red, and the tenth is worth naming rather than
glossing.** `docs updated in the same pass (item 19)` passed at red-first
because chapter 09 already mentioned `PublishReal` and never contained the
string `guarded until packaging lands`. The assertion was satisfied by the
starting state, so it graded nothing for this pass. It is recorded here rather
than quietly counted as a win, and the chapter was updated anyway — see task 6
— because the obligation is backlog item 19, not the assertion.

Green at start would have stopped the pass. It was not green.

## 3. Tasks

### - [x] 1. Acceptance red

Above. 1 passed, 9 failed.

### - [x] 2. Repair before release

**Backlog 20 — the stale edge count.** `Compare-TfGraph.Tests.ps1` line 41
asserted `ExpectedEdgeCount | Should-Be 57`. Decision 0012 re-authored the
oracle under the case-3 amendment and records the change in terms: *"Node count
is unchanged at 78… Edges go from 57 to 59."* Re-derived from the file rather
than taken from the decision: the committed oracle holds **78 nodes and 59
edges**, and the comparator returns 59. The assertion was left stale when the
oracle was amended.

Corrected to 59, **hard-coded, with a comment citing decision 0012**. The prompt
allowed either a derived or a hard-coded number and asked for the derivation if
reasonable. It is not, and the reason is the freeze: the fixture is frozen under
decision 0011 and amendable only by a new decision. A count derived from the
oracle file would agree with the oracle whatever the oracle became, which is
precisely what the freeze exists to prevent. Written down, the numbers are a
tripwire on the freeze. The comment in the file says so.

**This is staleness repair, not assertion-weakening, and that claim is proved
rather than asserted.** Changing a `Should-Be` from a failing number to a
passing one is indistinguishable, on the diff, from weakening a test to make it
go green. The distinguishing evidence is that the comparator still discriminates
after the change, so the seven mutations were re-run:

```text
CONTROL GREEN            oracle against itself: 0 differences, 78 nodes, 59 edges
missing-node       -> MissingNode     (1 difference)
extra-node         -> ExtraNode       (1 difference)
wrong-attribute    -> WrongAttribute  (1 difference)
wrong-parent       -> WrongParent     (1 difference)
missing-edge       -> MissingEdge     (1 difference)
extra-edge         -> ExtraEdge       (1 difference)
wrong-edge-kind    -> WrongEdgeKind   (1 difference)
distinct categories exercised: 7 of 7

DETECTED: 7 / 7
```

`plans/0030-release/mutations.txt`, exit 0. Suite now **15 passed, 0 failed**.

**Backlog 22 — the false clause.** `PLAN-PROTOCOL.md`'s tier worked example
claimed pass 0012 *"shipped without the red-first test the tier requires"*.
What plan 0012 §3 actually records, under the heading *Acceptance test — red
first*:

```text
RED-FIRST: Passed=315 Failed=15 Total=330
```

with every failure in the amended assertion 7, and §7 is the verify script.
Deviations 7 of that plan records why both exist: the prompt required them
regardless of the light label.

So the correction is not a softening — it is a different and better example.
Pass 0012 is a **near miss, not a casualty**: the full-tier artifacts existed
because the *prompt* required them, not because the tier label asked for
anything (light says in terms "no acceptance test and no verify script"). Had
the prompt been consistent with its own label, the one change that could break
something would have shipped untested. The rule the section teaches is
unchanged, and `Tier is a floor, never a ceiling` still closes it.

**LEDGER backlog numbering, reconciled.** Pass 0031 recorded a 17→19 drift and
asked that numbers never move. The sequence as it actually stands, now written
down so no future pass re-derives it: **1–12 exist; 13 does not and never did**
(no entry was ever written under it — it is cited once, in *Resolved by pass
0029*, because its wording was absorbed into item 12 before either was written,
and it landed in `evals/HARNESS.md` as hazard 10); **14–22 exist**; **23 is the
next free number**. Nothing was renumbered. Pass 0030 consumes no new number:
everything it touched was already numbered.

### - [x] 3. Decision 0013 — harness release tagging

`decisions/0013-harness-release-tagging.md`. Amends rule 14 for the harness
repository and only for release tags: the agent creates and pushes annotated
`vMAJOR.MINOR.PATCH` tags at the end of a release pass **when that pass's
acceptance test is green**. `v1.0.0` is the ladder-closed release, per the
LEDGER's standing reservation (*"psmodule manifest: 0.1.0 … v1.0.0 reserved for
'passed the ladder'"*).

Tag messages carry the with/without headline and cite the 0029 table — and the
decision requires the third bullet, that the baseline is one run never permitted
to iterate, on the grounds that a message carrying the win without it is a
marketing claim.

Unchanged: no `Publish-Module`, no force pushes, no history rewrites, harness
`main` stays operator-only, and no other tags on the harness.

The consequence that makes it worth a decision: **the surface a stranger
installs changes only via a tagged release.** Consumers add the marketplace
pinned to the tag, so `main` can move — a pass lands, a document is corrected —
without any consumer's installation changing. Without the pin, every merge to
`main` would be a silent release to everyone who had ever added the marketplace.

Three alternatives are recorded as rejected, including waiting for the missing
baseline control (backlog 17) before 1.0.0: rejected because it would hold the
release indefinitely for a measurement that improves the *table*, not the
artifact, and the gap is disclosed instead.

### - [x] 4. Packaging

`.claude-plugin/marketplace.json`: marketplace `psmodule-builder`, one plugin
entry for `psmodule`, **relative `./` source** — the repository root is itself
the plugin — with pinned metadata (version, description, author, homepage,
repository, licence, keywords, category). `plugin.json` **0.1.0 → 1.0.0**.

**PublishLocal re-run end to end, and its transcript now reflects the real
marketplace file.** Before this pass the only marketplace the script could
exercise was the one it generated itself, and a generated file proves nothing
about a committed one. `Publish-Local.ps1` gained `Test-CommittedMarketplace`,
which validates the committed file — parse, name, exactly one entry matching the
manifest, relative `./` source, source resolving to a directory that really
holds a `plugin.json`, and the entry's version agreeing with `plugin.json`.
Both the staging path and `-ValidateOnly` call it.

```text
Staged 14 skills and 2 commands.
Staged validation passed: both JSON files parse, the source path resolves, skills and commands are present.

Committed marketplace validated: .claude-plugin\marketplace.json
  marketplace name : psmodule-builder
  plugin entry     : psmodule 1.0.0  source './'
  version agrees with .claude-plugin/plugin.json.
```

**The new validator was falsified on every rule it enforces** — a check that has
never been red is a claim. Six probes, each restoring the file afterwards, with
a control proving the restore worked
(`plans/0030-release/marketplace-falsification.txt`):

| Probe | Broken | Result |
|---|---|---|
| A | entry version 9.9.9 vs manifest 1.0.0 | exit 1, names the disagreement |
| B | source `plugins/psmodule`, not `./` | exit 1, names the non-relative source |
| C | source `./docs` — exists, no `plugin.json` | exit 1, names the missing manifest |
| D | committed `marketplace.json` deleted | exit 1, names the missing file |
| E | truncated, malformed JSON | exit 1, names the parse error and position |
| F | entry renamed `psmodule-typo` | exit 1, "0 entries named 'psmodule'; expected exactly 1" |
| control | restored | **exit 0** |

**`claude plugin validate` attempted; the CLI is not on PATH here.** Recorded as
a result rather than silently skipped, and not treated as fatal. Deviations 1
states plainly what is therefore *not* claimed.

**PublishReal's guard takes its live path for the first time.** It prints the
operator's checklist and exits 0, and it still pushes nothing. That last claim
is proved by AST rather than by grep, because grep cannot tell an invocation
from a string literal:

```text
Commands the parser finds INVOKED in Publish-Real.ps1:
  ConvertFrom-Json, Get-Content, Join-Path, Resolve-Path, Test-Path, Write-Host
```

No `git`, no `Publish-Module`, no `nuget`, no `dotnet`. The one
`git push origin main` that grep finds sits inside a `Write-Host` literal.
Full transcript: `plans/0030-release/packaging.txt`.

Two checklist lines were corrected to match decision 0013: step 4 no longer
tells the operator to tag (the tag belongs to the release pass, and the step now
says how to confirm it and not to hand-tag if it is missing), and step 5's
marketplace add is pinned to the tag.

### - [x] 5. Adoption boilerplate

**`SECURITY.md`.** What the plugin touches, with the `$env:AZDO_PAT` rules
quoted **verbatim** from the standing rules — the README's Guardrails paragraph
and `evals/functional/AZDO-FIXTURE.md` — rather than paraphrased, because a
paraphrased credential rule is a new rule. What it never does: no network beyond
the Azure DevOps REST API, no telemetry, never queues or triggers a pipeline,
never writes anything to Azure DevOps, never publishes, never rewrites history.
A **"What is not claimed"** section names the cold install nobody has done, the
schema validator nobody has run, and the fact that skills are prose a model may
decline to follow. How to report, and not to paste a token into an issue.

**`CHANGELOG.md`.** 1.0.0 in consumer words: two commands, fourteen skills
described by what they do rather than by their names, conventions that are
graded rather than suggested, the measured effect **including** the nearly-flat
`0 / 12 → 1 / 12` row, prerequisites, and known limits up front. Not the
journal — the journal is linked, not summarised.

**README `## Support`.** Honest: solo project, no team, no SLA; issues read in
batches roughly **weekly**; security first; *"not planned"* is a real answer and
better than silence. What a good bug report contains, using the audit commands
from chapter 05 — version, prerequisite checker output, plugin version, clone
HEAD/describe/status, and the failure **re-run rather than remembered**. The
most useful report of all is named: a cold-install report, because nobody has
done one.

**`LICENSE`.** Was **absent**, not merely unconfirmed — the prompt said
"confirmed present" and it was not there. Added: MIT, `Copyright (c) 2026 Jerry
Balmer`. Consistency checked across all three places that assert it —
`plugin.json` `license`, the marketplace entry's `license`, and the file — and
`verify.ps1` check 2 re-derives it.

**README `## Versioning`.** A table of what MAJOR / MINOR / PATCH may change and
what the reader should do about each, the statement that **the pin is the
promise**, and a caution that a major here is not merely changed advice: a
reversed convention changes what a module must look like to score against the
conformance suite.

### - [x] 6. Hostile first run

`tools/publish/Test-Prerequisites.ps1`. Five checks — pwsh ≥ 7.2, Pester
importable, git present, InvokeBuild resolvable, `$env:AZDO_PAT` set (existence
only; the value is never read or printed, because this is a script whose output
newcomers will paste into issues). Each failure is **one line** naming the thing
and the exact install/set command.

**It carries no `#Requires -Version 7.2`, deliberately, while every other script
here does.** A prerequisite checker that refuses to start when a prerequisite is
missing fails exactly when it is needed: under Windows PowerShell 5.1 it would
emit the engine's own `#Requires` error instead of the line saying which
PowerShell to install. So it is written to run under 5.1 and does the version
check itself — which is also what makes that check falsifiable with a real host
instead of a simulated one.

**All five falsified, none simulated** (`plans/0030-release/hostile-first-run.txt`):

| Probe | Made absent how | Result |
|---|---|---|
| 1/5 pwsh ≥ 7.2 | run under the real Windows PowerShell **5.1.26100.9168** already on the machine | exit 1, one named line, `winget install --id Microsoft.PowerShell` |
| 2/5 Pester | `PSModulePath` masked in a child process to a root holding **InvokeBuild only** | exit 1, one named line, `Install-Module Pester -MinimumVersion 5.0` |
| 3/5 git | `PATH` masked in a child process to System32 | exit 1, one named line, `winget install --id Git.Git` |
| 4/5 InvokeBuild | `PSModulePath` masked to a root holding **Pester only** | exit 1, one named line, `Install-Module InvokeBuild` |
| 5/5 `$env:AZDO_PAT` | cleared in a child process | exit 1, one named line, `[Environment]::SetEnvironmentVariable(…)` |
| control | nothing masked | **exit 0**, `ALL PREREQUISITES PRESENT. (5 of 5 checked, 0 missing.)` |

Record ends `ALL PROBES: named one-line errors`.

**Two details in that table are the point of it.** The module probes use two
separate roots, each holding a junction to exactly one module, so that Pester
and InvokeBuild are made absent *independently* — masking `PSModulePath`
wholesale removes both at once and would let one probe take credit for the
other's line. And the PAT probe clears the variable **in a child process only**;
the record confirms afterwards that the parent still holds the real token, which
was never read or printed.

**Wired in.** README's install section says to run it first. Chapter 09's
*Before you start* gains it, including why it has no `#Requires` and how it was
falsified.

### - [x] 7. Install docs

README top, `## Install`, the three commands verbatim:

```text
/plugin marketplace add JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder@v1.0.0
/plugin install psmodule@psmodule-builder
/psmodule:build
```

with the prerequisite checker run **before** them in the reader's own shell, the
pin explained and attributed to decision 0013, the uninstall pair, the local-only
alternative (chapter 09), and a pointer to the with/without table and the honest
status list before the reader commits.

### - [x] 8. Doc maintenance in the same pass (backlog 19)

Not a numbered task in the prompt, but the standing obligation, and this pass
changed behaviour that the docs describe.

- **Chapter 09** — the prerequisite checker and its falsification; the
  `PublishReal` section rewritten. It said *"today it refuses"* and *"the guard
  goes green when pass 0030 lands"*. Both states are now shown, in order,
  because a guard seen in only one state is a guard not seen working. Two of the
  three things the refusal demanded are done; **the third, the cold-install
  proof, is not**, and the chapter says the guard going green moved that from
  *blocked* to *outstanding* rather than making it true.
- **`method/METHOD.md`** — the PORTABLE safety rail says *"No release, no tag …
  unless the operator does it from their own shell."* Decision 0013 amends it,
  so the amendment is quoted inline under the rail. Backlog 21 is a record of
  three documents disagreeing with each other; leaving METHOD.md and decision
  0013 in contradiction would have created a fourth. The amendment is marked
  **not portable** — a project without a release pass should keep the unamended
  rule.

### - [x] 9. The tag

Created only after the acceptance test was green in every respect except the
tag's own assertion — 9 of 10, with `v1.0.0 on the remote` the sole failure,
which is the sequence decision 0013 prescribes. Annotated, message carrying the
with/without headline, the citation to the 0029 table, and the baseline caveat.

## 4. Diff summary

23 files, +1264 / −30 before the plan artifacts and tag.

| Area | Files |
|---|---|
| Packaging | `.claude-plugin/marketplace.json` (new), `.claude-plugin/plugin.json` |
| Decision | `decisions/0013-harness-release-tagging.md` (new) |
| Repair | `evals/tf/Compare-TfGraph.Tests.ps1`, `PLAN-PROTOCOL.md`, `LEDGER.md` |
| Adoption | `SECURITY.md`, `CHANGELOG.md`, `LICENSE` (all new), `README.md` |
| Tooling | `tools/publish/Test-Prerequisites.ps1` (new), `Publish-Local.ps1`, `Publish-Real.ps1` |
| Docs | `docs/creating-an-agent/09-try-before-you-trust.md`, `method/METHOD.md` |
| Plan | `plans/0030-release/` — `plan.md`, `accept.Tests.ps1`, `verify.ps1`, and four evidence files |

## 5. Deviations

**1. `claude plugin validate` could not be run: the CLI is not on PATH in this
environment.** Attempted, and the absence is recorded in
`plans/0030-release/packaging.txt` rather than skipped quietly. The prompt
allowed this ("absence of the CLI recorded not fatal"). What follows from it is
stated so nobody has to infer it: **this pass does not claim the marketplace
file passes the official schema validator.** The JSON checks that did run are
named, and they are weaker. If the file is malformed in a way only the schema
would catch, this pass would not have caught it.

**2. `LICENSE` was absent, not merely unconfirmed.** The prompt said "LICENSE
file confirmed present and MIT-consistent with the manifest", which presupposes
it existed. It did not — the repository had no `LICENSE`, `LICENCE` or `COPYING`
at any casing. Written rather than reported as a blocker, since MIT was already
asserted by `plugin.json` and by the README, so the content was determined and
only the file was missing. Flagged because a precondition-shaped phrase that
turns out to be false is worth saying out loud.

**3. The acceptance test's item-19 assertion passed at red-first and therefore
graded nothing.** Recorded in §2 rather than counted as a win. The file was
supplied verbatim by the prompt and was run as given; the work it was meant to
grade was done anyway, against the backlog item rather than against the
assertion.

**4. A comment added to `Publish-Real.ps1` silently falsified a lesson in
chapter 09.** The chapter teaches readers to verify the no-push claim with
`Select-String -Pattern '^\s*(&\s*)?git\s'` over that file and promises no
output. A sentence in a header comment I added wrapped so that a line began with
the word `git`, and the check started returning a hit. Caught by re-running the
chapter's own command instead of trusting that a comment could not matter. Fixed
by rewrapping the sentence — **not** by loosening the pattern — with a comment
in the file explaining why the wrapping is load-bearing. `verify.ps1` check 6
now re-runs the chapter's command so this cannot rot again silently.

**5. Pass 0031's acceptance test asserts the `PublishReal` guard is red, and it
still passes.** It reads `plans/0031-operators-manual/publishreal-guard.txt`, a
frozen transcript of that pass, and asserts it matches `GUARD: refused`. That
remains a true statement about what happened in pass 0031. Decision 0004 makes
plan artifacts frozen, so it is correct that this pass did not touch it. Noted
because a reader who sees "the guard now passes" and then finds a green test
asserting it refuses should know the two are not in conflict.

**6. `verify.ps1` found a defect in this pass's own correction, and the tag was
already pushed when it did.** Check 4 went red: the corrected worked example in
`PLAN-PROTOCOL.md` quoted plan 0012's red-first line as
`Passed=315 Failed=15 Total=330`, dropping the `RED-FIRST: ` prefix the source
line actually carries — while the same check confirmed the full string *does*
exist in plan 0012. A quotation not matching its source is precisely the defect
this pass was fixing one clause over. **The document was corrected, not the
check.**

The fix landed at `1f3804f`, one commit after `v1.0.0` was tagged at `a5aa4a9`.
**The tag was not moved**, because decision 0013 — written in this same pass —
says a tag once pushed is immutable and that a release that was wrong is
superseded by a new version, never by moving a tag. Applying that rule to itself
on the day it was written is the point of writing it down.

What this means for anyone installing `v1.0.0`, stated exactly:

    git diff v1.0.0..HEAD -- skills/ commands/ .claude-plugin/    # empty
    git diff --stat v1.0.0..HEAD                                  # PLAN-PROTOCOL.md only

The **plugin surface a consumer installs is byte-identical** between the tag and
`HEAD`. The sole difference is six lines of prose in `PLAN-PROTOCOL.md`, a
harness document that is not part of the plugin and is not installed. No patch
release is warranted for it; it rides along with whatever ships next.

One consequence to know before re-running the verification: `verify.ps1` defaults
to `HEAD`. Run it at `v1.0.0` explicitly and **check 4 will be red**, correctly,
for the reason above.

## 6. Journal

`journal/0030-release.md`.

## 7. Verify script

`plans/0030-release/verify.ps1`. Eight checks, all from a **fresh clone** in a
temp directory, none of them parsing this document. Check 7 is deliberately run
against the **origin**, not the clone, because a tag that exists only locally is
exactly the failure it is for. `-FailCheck` runs seven falsification probes,
each of which asserts it actually changed its target before re-running the check
it is probing.

**Result at `1f3804f`: all checks agree, exit 0**; `-FailCheck`: **all seven
probes fired**, exit 0. Transcript: `plans/0030-release/verify-run.txt`.

The two checks worth noting: check 3 does not stop at the comparator suite being
green — it re-runs the seven mutations and requires `DETECTED: 7 / 7`, so a
future weakening of that assertion is caught rather than congratulated; and
check 4 requires not only that the false clause is gone but that the rule and
the new citation survive, and that plan 0012 really does contain the line the
correction quotes.
