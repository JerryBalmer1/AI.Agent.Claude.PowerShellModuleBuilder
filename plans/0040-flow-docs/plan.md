# Plan 0040 — the flow made visible

Tier: **full**. The prompt states it, and it is correct: the pass adds
executable artifacts — a renderer script, three checks and a verify script —
even though its visible bulk is documents. PLAN-PROTOCOL's *What decides the
tier* section is explicit that documents do not lower a tier.

## 1. Prompt

The prompt as received, verbatim, in two messages. The first arrived
**truncated** mid-assertion; the pass stopped there and reported the gap, and
the operator resent from the truncation point. Both are reproduced because the
stop is part of the record.

### Message one, as received

```
# PASS 0040 — The flow made visible: diagram, prompts kit, chapter 11, decision 0015
Tier: full

## Repositories
Harness only — branch `pass-0040-flow-docs` from `main` (`f14c297…`).
skills/ and commands/ untouched; `.claude-plugin/` untouched (no
release — docs, one decision, one possible assertion repair). If the
assertion repair in task 2 fires, evals/ changes; cases-defined must
remain 41 either way.

## Preconditions
Sync; trees clean; branch created; `docs/diagram/`, `prompts/`,
`docs/creating-an-agent/11-your-first-module.md`,
`decisions/0015-falsifying-against-a-red-target.md` all absent.
Probe LEDGER 47's state and record it: build a minimal two-parameterset
fixture whose examples follow the house splat standard exactly, run
`Help.Tests.ps1`'s set-coverage assertion against it — PASSES (47 was
repaired in 0039; task 2 becomes evidence-only) or FAILS (task 2
repairs).

## Acceptance test — red first
`plans/0040-flow-docs/accept.Tests.ps1`, exactly:

    #Requires -Version 7.2
    param([string]$RepoRoot = "$PSScriptRoot/../..")
    Describe 'Pass 0040 delivered' {
        It 'decision 0015 exists' {
            Test-Path "$RepoRoot/decisions/0015-falsifying-against-a-red-target.md" | Should -BeTrue }
        It 'LEDGER 47 resolved with evidence' {
            (Get-Content "$RepoRoot/plans/0040-flow-docs/splat-coverage.txt" -Raw) |
                Should -Match 'SPLAT EXAMPLE: (passes as shipped|repaired and falsified)' }
        It 'the diagram exists in both renderings' {
            (Get-Content "$RepoRoot/README.md" -Raw) | Should -Match '```mermaid'
            Test-Path "$RepoRoot/docs/diagram/flow.html" | Should -BeTrue
            Test-Path "$RepoRoot/docs/diagram/flow-graph.json" | Should -BeTrue
            Test-Path "$RepoRoot/tools/diagram/Build-Diagram.ps1" | Should -BeTrue }
        It 'the diagram link map exists' {
            (Get-Content "$RepoRoot/README.md" -Raw) | Should -Match 'link map' }
        It 'the prompts kit exists in one directory' {
            foreach ($f in 'README.md','project-context-template.md',
                           'first-module.md','new-feature.md','release.md',
                           'troubleshoot.md') {
                Test-Path "$RepoRoot/prompts/$f" | Should -BeTrue } }
        It 'chapter 11 exists and README points at the flow' {
            Test-Path "$RepoRoot/docs/creating-an-agent/11-your-first-module.md" | Should -BeTrue
            (Get-Content "$RepoRoot/README.md" -Raw) | Should -Match 'The flow' }
        It 'the hybrid design note exists' {
            Test-Path "$RepoRoot/docs/design/hybrid-modules.md" | Should -BeTrue }
        It 'chapter 01 carries the human-paced paragraph' {
            (Get-Content "$RepoRoot/docs/creating-an-agent/01-the-two-claudes.md" -Raw) |
                Should -Match 'human-paced' }
        It 'the stranded-branch check joined the sync step' {
            (Get-Content "$RepoRoot/PLAN-PROTOCOL.md" -Raw) |
                Should -Match 'not an ancestor of.*main' }
        It 'no dead links in anything this pass touched' {
            (Get-Content "$RepoRoot/plans/0040-flow-docs/linkcheck.txt" -Raw) |
```

**The message ended there**, mid-expression, with the task list and the
remainder of the assertion absent.

### Message two, as received

```
## PASS 0040 — resend from the truncation point. Task 2 is confirmed
evidence-only per your probe (SPLAT EXAMPLE: passes as shipped); copy
the probe fixture + transcript from scratch into plans/0040-flow-docs/.

## Acceptance test — completion (the final two It blocks and close)

        It 'no dead links in anything this pass touched' {
            (Get-Content "$RepoRoot/plans/0040-flow-docs/linkcheck.txt" -Raw) |
                Should -Match 'DEAD LINKS: 0' }
        It 'the local handoff rule exists where it binds' {
            (Get-Content "$RepoRoot/PLAN-PROTOCOL.md" -Raw) |
                Should -Match '(?m)^### Local handoff'
            (Get-Content "$RepoRoot/prompts/project-context-template.md" -Raw) |
                Should -Match 'LOCAL STATE' }
    }

Run it; report the red. Green at start stops the pass.

## Plan (∥ = parallel drafting, serial review; push per group)
- [ ] 1. Acceptance red. Commit the pre-branch LEDGER-47 probe
      evidence into plans/0040-flow-docs/ (fixture, generator,
      transcript, splat-coverage.txt reading
      `SPLAT EXAMPLE: passes as shipped`).
- [ ] 2. (Discharged — evidence-only, per task 1.)
- [ ] 3. **Decision 0015**, verbatim:

          # 0015 — Falsifying a new assertion against an already-red
          # target

          Operator-decided, from pass 0039's LEDGER 48. When a new
          assertion's reference target already violates it, the
          falsification and the measurement are two claims and get two
          artifacts. The assertion's capability is proven on a
          purpose-built known-good fixture: the break must go red
          there, the control must stay green there, polarity rules
          unchanged. The reference target's real behaviour is then
          measured and Bucket-sorted separately, with the boundary
          rationale stated (it predates the rule). Neither artifact
          substitutes for the other: falsifying only against the red
          target proves nothing about the green path, and fixing the
          target to falsify the assertion rewrites history to fit the
          grader. Pass 0039's Help block is the worked example.

      Fold one paragraph into method/METHOD.md's falsification
      section, citing the decision.
- [ ] 4. **The diagram — one source, two renderings.** Author
      `docs/diagram/flow-graph.json` in the producer contract
      (ToHtml's schema): bottom-up layers so the gravity reads —
      method/rules (METHOD, PLAN-PROTOCOL, decisions) as the
      foundation; the instruments above (conformance @ cases-defined
      41, functional oracles, TF fixtures 1+2, comparators); the
      plugin above (v1.2.0, the 19 skills grouped by role, /build
      /test); the built module above; the end user on top. Nodes
      carry who/what/why one-liners; edges carry the flow
      (new → plan → build → test → tidy → release), the skills each
      stage invokes named IN ORDER on that stage's node (plan intake
      first; scaffold/architect before build; docs+ux with build;
      test; tidy last — state where order is real and where it is
      not). `tools/diagram/Build-Diagram.ps1` renders it through
      PSGraphRenderToHtml → PSGraphRender to
      `docs/diagram/flow.html` (repo-relative links, not vscode:// —
      this artifact is for strangers), committed. Then the SAME
      graph hand-mirrored as Mermaid in a new README section headed
      exactly "The flow". TEST GitHub's Mermaid click support on a
      scratch branch before relying on it: if node links survive,
      use them; if GitHub strips them, say so in one line. Either
      way ship the link-map table immediately below the diagram —
      every node → its doc/artifact — labeled "link map", with
      flow.html linked beside it as the full-fidelity interactive
      version, the dogfooding named for what it is.
- [ ] 5. **The prompts kit — `prompts/`, one directory, flat.** ∥
      Author (yours to draft, to these specs, self-contained and
      paste-able): `README.md` (what each file is, the order, one
      paragraph on why fresh sessions); `project-context-template.md`
      (the end-user's Claude-project context for building THEIR
      module with psmodule: repo table, transferable rules,
      director/executor split, ledger stub, AND the Local handoff
      rule with its LOCAL STATE table verbatim from PLAN-PROTOCOL —
      built from chapter 10's PORTABLE tier, TEMPLATE:replace
      markers where their names go); `first-module.md` (message one
      for their first module: install pin @v1.2.0, prerequisites
      check, plan-skill intake, ends with docs/PLAN.md existing and
      the local handoff performed); `new-feature.md` (delta-plan
      variant); `release.md` (tidy → conformance → the operator's
      publish verbs, marked human-only); `troubleshoot.md`
      (symptom → which artifact to read → which command re-derives;
      the calling-bullshit loop condensed, PLUS the first symptom
      being exactly the operator's: "the agent says done but I
      don't see it locally" → the LOCAL STATE table is the
      contract; if it wasn't printed, the pass isn't done). Every
      file honest that their module earns its own numbers.
- [ ] 6. **Chapter 11 — "Your first module."** The New flow walked
      end to end against the prompts kit: each stage, which skill
      fires, what artifact appears, what PLAN.md says afterward,
      the who/what/when/where/why troubleshooting table — ending
      at the LOCAL STATE table as what "done" looks like on their
      screen. README's "The flow" section links chapter 11 and the
      kit in its first breath.
- [ ] 7. **`docs/design/hybrid-modules.md`** — the what-breaks note
      for binary/hybrid modules (the Go→DLL target), enumerated
      against the real instruments: layout assertions needing a
      declared profile (the settings-file module-profile key is the
      hook), the ordered runner's parse layer, coverage gates,
      analyzer blindness + its reflect-the-DLL extension, the
      prerequisite checker, the one-machine bound. Ends: this
      becomes a discovery target when the operator schedules it;
      nothing is built before then.
- [ ] 8. **The three supplied insertions**, verbatim:
      Chapter 01, at its close:

          ## Why the director stays human-paced

          Nothing in this system runs itself, on purpose. Every
          cycle passes through a checkpoint that can say stop — the
          operator reads a report, a decision gets made, the next
          prompt is written against what actually happened rather
          than what was planned. The stops are the system: the runs
          this project trusts most are the ones where the executor
          refused to proceed. This repository once inherited a
          resident self-managing workflow (PSGraphRender's thread
          ledger) and pass 0021 stripped it, because two processes
          governing one commit is worse than one process with a
          human at the helm. If you automate the loop, you are
          building a different, riskier system — design its
          guardrails first, and falsify them.

      PLAN-PROTOCOL, in the sync step:

          After fast-forwarding, report any `pass-*` branch whose
          tip is not an ancestor of its repository's `main` — a
          stranded branch surfaces at the next pass's preconditions,
          not releases later.

      PLAN-PROTOCOL, as a new section after the sync step:

          ### Local handoff — the last act of every pass

          After remote pushes and main fast-forwards, the agent
          returns the operator's workspace to inspectable truth:
          for every workspace repository — checkout `main`,
          `git pull --ff-only`, `git fetch --tags --prune`,
          `git status` clean — then print a LOCAL STATE table
          (repo | branch | HEAD | clean) as the final output of the
          pass. "Done" means the operator's editor shows the result
          with zero commands: inspect what you expect, with nothing
          to figure out first. A diverged branch or dirty tree is
          reported, never resolved. A pass that ends without the
          LOCAL STATE table is not done.

- [ ] 9. Link-check everything touched → `linkcheck.txt`
      `DEAD LINKS: 0`. Acceptance green; plan/verify/journal;
      LEDGER (44, 47, 48 closed one-lined; item-19 note: a pass
      that changes the flow re-runs Build-Diagram.ps1 and
      re-mirrors the Mermaid). Push; fast-forward main per 0009,
      score-free subject. **Then perform the Local handoff you just
      wrote, and end the pass with the LOCAL STATE table for all
      five workspace repositories.**

## Named spot-checks — verify.ps1 re-derives
1. `Build-Diagram.ps1` re-run from a fresh clone; flow.html
   regenerated and content-stable (or the nondeterminism named);
   flow-graph.json validates against the producer schema via the
   battery.
2. The LEDGER-47 probe evidence re-fired from the committed fixture.
3. Link check re-run from the fresh clone: zero dead, every
   link-map row resolving.
4. Mermaid block and flow-graph.json agree on node count and layer
   membership (parse both, compare).
5. `git diff v1.2.0..HEAD -- skills/ commands/ .claude-plugin/`
   empty.

## Constraints
No release. No sibling repos. Fixtures/oracles untouched. Renderer
and ToHtml consumed at their pinned tags, not modified. Sources cited,
never reproduced. Claims about end-user outcomes stay conditional.

## Report back
The Mermaid click-support finding (one line, tested not assumed),
node/layer counts in both renderings, the prompts-kit file list,
chapter-11 one-liner, pushed SHAs — and the LOCAL STATE table as the
final lines.
```

## 2. Preconditions

Every one checked before the branch existed. The LEDGER-47 probe was run at
this point, deliberately, because its answer decides whether task 2 is a repair
or a record.

| Precondition | Command | Output |
|---|---|---|
| harness in sync with origin | `git fetch --all; git status --porcelain=v1 -b` | `## main...origin/main`, no ahead/behind |
| working tree clean | same | no entries |
| no stranded `pass-*` branch | `git merge-base --is-ancestor <b> main` over all 28 | none reported |
| `docs/diagram/` absent | `test -e` | absent |
| `prompts/` absent | `test -e` | absent |
| `docs/creating-an-agent/11-your-first-module.md` absent | `test -e` | absent |
| `decisions/0015-falsifying-against-a-red-target.md` absent | `test -e` | absent |
| `docs/design/hybrid-modules.md` absent | `test -e` | absent |
| `tools/diagram/` absent | `test -e` | absent |
| `plans/0040-flow-docs/` absent | `test -e` | absent |
| branch created | `git checkout -b pass-0040-flow-docs` | `Switched to a new branch`, from `f14c297` |

**The LEDGER-47 probe — PASSES.** A minimal module was built to the CONVENTION
and the CHECK was run against it, which is what item 47 demands and what
reading the assertion would not have established:

```
DASH FORM IN FIXTURE: 0 occurrence(s)
CONTAINERS FAILED: 0
[Passed] shows every named parameter set of Get-ProbeThing in an example
PASSED=1 FAILED=0 SELECTED=1

SPLAT EXAMPLE: passes as shipped
```

Task 2 is therefore evidence-only. Nothing under `evals/` was changed by this
pass and `cases-defined` stands at 41. Full record:
`plans/0040-flow-docs/splat-coverage.txt`.

**One precondition failure, and it was in the prompt.** The prompt arrived
truncated mid-assertion. Under PLAN-PROTOCOL's file-supply rule that is a
defect in the prompt rather than a lookup task, and the pass stopped and
reported it rather than inventing the remainder. See Deviations 1.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| InvokeBuild | 5.14.23 |
| OS | Microsoft Windows NT 10.0.26200.0 |
| git | 2.41.0.windows.1 |
| Claude Code | VS Code extension; model `claude-opus-5[1m]` |
| Branch | `pass-0040-flow-docs` |
| HEAD at start | `f14c29798b5e83b9e9ebd05575df392306ca8311` |
| PSGraphRenderToHtml | consumed at `v0.1.0` = `bb2fbacbc6c1cded4d49fc17e79bf54a82150281` |
| PSGraphRender | consumed at `v0.13.0` = `964d73a4db2d13ed6a5873a53a8607a1ecc1a71a` |

The extension's own version is not recorded because the session cannot measure
it, and PLAN-PROTOCOL's rule about unmeasurable fields applies to this one the
same way it applies to a token count.

## 4. Acceptance test — red first

The supplied test, written verbatim to `plans/0040-flow-docs/accept.Tests.ps1`,
run before any task work:

```
ACCEPTANCE TEST - RED FIRST, before any task work
command: Invoke-Pester -Path plans/0040-flow-docs/accept.Tests.ps1

[Failed] decision 0015 exists
[Failed] LEDGER 47 resolved with evidence
[Failed] the diagram exists in both renderings
[Failed] the diagram link map exists
[Failed] the prompts kit exists in one directory
[Failed] chapter 11 exists and README points at the flow
[Failed] the hybrid design note exists
[Failed] chapter 01 carries the human-paced paragraph
[Failed] the stranded-branch check joined the sync step
[Failed] no dead links in anything this pass touched
[Failed] the local handoff rule exists where it binds

RED-FIRST: Passed=0 Failed=11 Total=11
```

Full record with each failure's first line:
`plans/0040-flow-docs/accept-red.txt`. It carries the first line of each
failure rather than the console dump, because `Should -Match` quotes the whole
file it was matched against and the raw output was 140KB of quoted README that
proves nothing the first line does not.

## 5. Tasks

- [x] **1. Acceptance red; commit the LEDGER-47 probe evidence.**
  `accept.Tests.ps1` red at 11/11 (§4). `New-SplatProbeFixture.ps1`,
  `Invoke-SplatProbe.ps1`, `splat-probe.txt` and `splat-coverage.txt` committed
  under `plans/0040-flow-docs/`. `Invoke-SplatProbe.ps1` exists so `verify.ps1`
  re-fires the probe rather than retyping the commands that produced it — two
  copies of one check drift, and the drift is silent. Commit `c3c7020`.

- [x] **2. Discharged — evidence-only.** No file under `evals/` was opened.
  Asserted rather than claimed: `git diff v1.2.0..HEAD -- skills/ commands/
  .claude-plugin/` is empty, and `git diff --stat f14c297..HEAD` lists no path
  under `evals/`. `cases-defined` remains 41.

- [x] **3. Decision 0015 and the METHOD paragraph.**
  `decisions/0015-falsifying-against-a-red-target.md` carries the supplied text.
  `method/METHOD.md`'s falsification section gains a PORTABLE paragraph citing
  the decision, placed after the build-state rule and before *Evidence
  discipline*. Commit `711f53f`. The supplied title arrived wrapped across two
  `#` lines; written as one heading — Deviations 2.

- [x] **4. The diagram, one source and two renderings.** Commit `94d115c`, with
  `5376e97` and `b796ebb` fixing what verify found.
  - `docs/diagram/flow-graph.json`: **39 nodes, 49 edges, 5 scopes, 11 kinds**,
    counted from the file and re-derived from the rendered page's own payload
    (`"NodeCount": 39`, `"EdgeCount": 49`, `"ScopeCount": 5`, `"KindCount": 11`
    in `docs/diagram/flow.html`). Layers bottom to top in `scope`: `method` 3,
    `instruments` 5, `plugin` 28, `module` 2, `user` 1. All 19 skills present,
    grouped by family in `type`: `powershell-module` 11, `azdo` 3, `tf` 3,
    `cross-cutting` 2.
  - Every node carries `who`, `what`, `why` and a repo-relative `doc`. Each
    stage carries a `skills` attribute naming them in order and saying where the
    order is real and where it is not.
  - `tools/diagram/Build-Diagram.ps1` renders through PSGraphRenderToHtml
    v0.1.0 and PSGraphRender v0.13.0, materialised from their tags with
    `git archive` — read-only, no worktree and no ref written — and
    version-checked after import:
    `versions verified: PSGraphRender 0.13.0, PSGraphRenderToHtml 0.1.0`.
  - The producer battery runs before every render: `BATTERY: Passed=7 Failed=0
    Total=7` (`plans/0040-flow-docs/diagram-build.txt`).
  - README gains `## The flow` with the hand-mirrored Mermaid block and the
    39-row link map. `Compare-Mermaid.ps1` reports `nodes: mermaid 39, json 39
    / edges: mermaid 49, json 49 / layers: mermaid 5, json 5` and
    `MERMAID AND JSON AGREE`.
  - That comparison was then **broken four ways and went red for each**, with
    the control green: `plans/0040-flow-docs/mermaid-falsification.txt`,
    `FALSIFICATION: all rows behaved as declared`.
  - **Mermaid click support: tested, not relied on.**
    `plans/0040-flow-docs/mermaid-click.txt` records the probe branch, the
    fetches, GitHub's render path and its `securityLevel`. Deviations 4.

- [x] **5. The prompts kit.** `prompts/` holds `README.md`,
  `project-context-template.md`, `first-module.md`, `new-feature.md`,
  `release.md` and `troubleshoot.md`. The context template carries the LOCAL
  STATE rule verbatim from PLAN-PROTOCOL and `TEMPLATE:replace` markers.
  `troubleshoot.md` leads with the operator's own symptom. Commit `8404c35`.
  Two command forms were corrected against the artifacts — Deviations 6.

- [x] **6. Chapter 11.** `docs/creating-an-agent/11-your-first-module.md`,
  listed in chapter 00's index; README now says *twelve chapters*. README's
  *The flow* links chapter 11 and the kit in its opening paragraph. Commit
  `8404c35`.

- [x] **7. The hybrid note.** `docs/design/hybrid-modules.md`, enumerated
  against the named instruments: four layout assertions by name, the ordered
  runner's parse layer, both coverage assertions, analyzer blindness with
  `MetadataLoadContext` as the one extension that keeps the never-execute rule,
  the prerequisite checker, and the one-machine bound. Ends where the prompt
  said. Commit `8404c35`.

- [x] **8. The three supplied insertions.** Chapter 01 closes on *Why the
  director stays human-paced*, before its navigation footer. PLAN-PROTOCOL
  gains `## Sync and handoff` holding `### Sync — the first act of every pass`
  and `### Local handoff — the last act of every pass`. Commit `711f53f`. The
  protocol had no sync step to insert into and the stranded-branch paragraph
  had to be rewrapped — Deviations 3 and 5.

- [x] **9. Link check, green, records, push, handoff.**
  `plans/0040-flow-docs/linkcheck.txt`: `links resolved: 245`,
  `39 rows for 39 nodes`, `DEAD LINKS: 0`. Acceptance green (§6). `verify.ps1`
  from a fresh clone: `checks: 6, failed: 0`. LEDGER, journal and this plan
  written. Push, fast-forward and handoff in §7.

## 6. Acceptance test — green

Same test, same command, after every task:

```
ACCEPTANCE TEST - GREEN, after every task
command: Invoke-Pester -Path plans/0040-flow-docs/accept.Tests.ps1

CONTAINERS FAILED: 0
[Passed] decision 0015 exists
[Passed] LEDGER 47 resolved with evidence
[Passed] the diagram exists in both renderings
[Passed] the diagram link map exists
[Passed] the prompts kit exists in one directory
[Passed] chapter 11 exists and README points at the flow
[Passed] the hybrid design note exists
[Passed] chapter 01 carries the human-paced paragraph
[Passed] the stranded-branch check joined the sync step
[Passed] no dead links in anything this pass touched
[Passed] the local handoff rule exists where it binds

GREEN: Passed=11 Failed=0 Total=11
```

`CONTAINERS FAILED: 0` is printed above the counts on purpose. A container that
fails discovery reports neither passes nor failures, and `Failed=0` alone would
read as a green run — LEDGER 45.

## 7. Command transcript

Every command that changed state, and every command whose output produced a
number in this plan. Exploratory reads excluded.

```bash
# Preconditions, before the branch existed.
git fetch --all
git status --porcelain=v1 -b
for b in $(git for-each-ref --format='%(refname:short)' refs/heads/); do \
  git merge-base --is-ancestor "$b" main || echo "STRANDED: $b"; done

# The LEDGER-47 probe, in the session scratchpad, before any repository change.
pwsh -NoProfile -File New-SplatProbeFixture.ps1 -Path ./fixture
pwsh -NoProfile -Command "Invoke-Pester -Path evals/conformance/Help.Tests.ps1 \
  -FullNameFilter '*shows every named parameter set*'"

# The branch.
git checkout -b pass-0040-flow-docs
mkdir -p plans/0040-flow-docs docs/diagram docs/design tools/diagram prompts

# Red first.
pwsh -NoProfile -Command "Invoke-Pester -Path plans/0040-flow-docs/accept.Tests.ps1" \
  | tee plans/0040-flow-docs/accept-red.txt

# Task 1.
pwsh -NoProfile -File plans/0040-flow-docs/Invoke-SplatProbe.ps1 \
  | tee plans/0040-flow-docs/splat-probe.txt
git add plans/0040-flow-docs && git commit    # c3c7020

# Tasks 3 and 8.
git add -A && git commit                      # 711f53f

# Task 4 - the diagram.
pwsh -NoProfile -File tools/diagram/Build-Diagram.ps1 \
  | tee plans/0040-flow-docs/diagram-build.txt
pwsh -NoProfile -File tools/diagram/Build-Diagram.ps1 -Check
pwsh -NoProfile -File plans/0040-flow-docs/Compare-Mermaid.ps1
pwsh -NoProfile -File plans/0040-flow-docs/Invoke-MermaidFalsification.ps1 \
  | tee plans/0040-flow-docs/mermaid-falsification.txt

# Task 4 - the Mermaid click probe, on a scratch branch, since deleted.
git checkout -b scratch-0040-mermaid-probe main
git add MERMAID-PROBE.md && git commit && git push origin scratch-0040-mermaid-probe
curl -sS -o blob.html -w "HTTP %{http_code}\n" \
  "https://github.com/JerryBalmer1/AI.Agent.Claude.PowerShellModuleBuilder/blob/scratch-0040-mermaid-probe/MERMAID-PROBE.md"
curl -sS -X POST ".../markdown/mermaid?docs_host=..." --data-urlencode "code=$SRC"
curl -sS -o vs-shell.html ".../markdown/mermaid?docs_host=..."
curl -sS -o vs-bundle.js ".../static/assets/mermaidMarkdown-<hash>.js"
git push origin --delete scratch-0040-mermaid-probe
git branch -D scratch-0040-mermaid-probe

git add -A && git commit                      # 94d115c
git push origin pass-0040-flow-docs

# Tasks 5, 6, 7 and the checks.
pwsh -NoProfile -File plans/0040-flow-docs/Test-Links.ps1 \
  | tee plans/0040-flow-docs/linkcheck.txt
pwsh -NoProfile -Command "Invoke-Pester -Path plans/0040-flow-docs/accept.Tests.ps1" \
  | tee plans/0040-flow-docs/accept-green.txt
git add -A && git commit                      # 8404c35

# What verify found, and the two commits that fixed it.
pwsh -NoProfile -File plans/0040-flow-docs/verify.ps1
git check-attr -a docs/diagram/flow.html
git add --renormalize .gitattributes docs/diagram/flow.html
git add -A && git commit                      # 5376e97
pwsh -NoProfile -File tools/diagram/Build-Diagram.ps1
git add -A && git commit                      # b796ebb
pwsh -NoProfile -File plans/0040-flow-docs/verify.ps1 \
  | tee plans/0040-flow-docs/verify-run.txt

# Environment.
pwsh -NoProfile -Command '$PSVersionTable.PSVersion; (Get-Module -ListAvailable Pester).Version'
```

## 8. Diff summary

Not required at this tier; `git diff --stat f14c297..HEAD` reports
**34 files changed, 7268 insertions(+), 2 deletions(-)**, with no path under
`evals/`, `skills/`, `commands/` or `.claude-plugin/`.

## 9. Verify script

`plans/0040-flow-docs/verify.ps1`, committed beside this plan and **not
reproduced here**. It is 200 lines, and PLAN-PROTOCOL's exception applies: a
second copy of an executable in the same commit can disagree with the first,
and nothing makes them agree again.

What it does: clones this repository into a temporary directory — so an
uncommitted working-tree file cannot make it pass — and runs six checks. The
acceptance test, then the five spot-checks the prompt named, in the prompt's
order. It re-derives rather than reads: the probe's reading is recomputed and
`splat-coverage.txt` is then required to agree with it, rather than being read
as the evidence. Each check tests the claims it is really making rather than an
exit code — that the tags consumed were the pinned ones, that the battery
graded something rather than nothing, that the mirror comparison is itself
capable of failing. It exits non-zero naming which check disagreed.

The two sibling repositories are the one thing it cannot get from a clone, and
that is stated rather than hidden: they are read from the operator's own clones
at their tags, and `-SkipDiagram` runs everything else on a machine without
them, recording the skip in the summary instead of passing quietly.

Result on this pass:

```
checks: 6, failed: 0
VERIFY 0040: every check agrees
```

Its first run failed spot-check 1, which is the outcome that made it worth
having — see Deviations 7.

## 10. Deviations

1. **The prompt arrived truncated, and the pass stopped.** Message one ended
   mid-expression inside the acceptance test's tenth `It`, with the task list
   absent. PLAN-PROTOCOL's file-supply rule makes that a defect in the prompt
   rather than a lookup task, and the loud failure is the correct behaviour.
   The preconditions and the LEDGER-47 probe were completed first, because
   neither depended on the missing text and the probe's answer was needed to
   report the stop usefully. Nothing was written to the repository and the
   branch was not created until the resend arrived.

2. **Decision 0015's title was supplied wrapped across two `#` lines.** Written
   as one H1, matching every other decision record. Two H1 lines would have
   rendered as two headings and neither would have been the title.

3. **PLAN-PROTOCOL had no sync step to insert into.** The prompt directs one
   insertion "in the sync step" and another "as a new section after the sync
   step"; the protocol described the tree a pass begins on and never the fetch
   that established it. A `## Sync and handoff` section was written to receive
   both, holding `### Sync — the first act of every pass` and the supplied
   `### Local handoff — the last act of every pass` as siblings, so that the
   supplied heading level is exact and "after the sync step" is literally true.

4. **GitHub Mermaid click support could not be settled from a terminal, and
   the answer is *unproven* rather than *works* or *stripped*.** The probe
   established that the click lines reach the page; that GitHub renders the
   block client-side in a cross-origin frame on
   `viewscreen.githubusercontent.com`, fed by postMessage, so there is no
   server-side render to fetch; that its bundle initialises mermaid at
   `securityLevel: "antiscript"` and sanitises click URLs rather than dropping
   them; and therefore that a **relative** click target cannot resolve to this
   repository under any security level. Whether an absolute one becomes a
   working link needs a browser. No `click` directive ships, because thirty-nine
   untested click lines are a claim nobody here has checked. Full record:
   `plans/0040-flow-docs/mermaid-click.txt`.

5. **The supplied stranded-branch paragraph was rewrapped.** As given it broke
   the line between "not an" and "ancestor"; the supplied assertion matches
   `not an ancestor of.*main` against the raw file, where `.` does not cross a
   newline. The verbatim text would have failed the check written for it. Words
   unchanged, wrapping changed. LEDGER 52.

6. **Two command forms in the prompts kit were corrected against the
   artifacts.** `Invoke-Conformance.ps1` takes `-Path`, not `-Target`, and its
   `-ResultPath` defaults to the *current* directory rather than the target's,
   so the kit names it explicitly. The tidy invocation no longer hard-codes a
   harness-relative script path that is wrong for a plugin install. Neither was
   in the prompt; both would have been wrong in a document whose whole purpose
   is to be pasted and run.

7. **`verify.ps1` failed its own spot-check 1 twice, and both causes were
   real.** `.gitattributes` had no `*.html` rule, so a Windows checkout gave
   the generated document CRLF against the renderer's LF; then
   `Export-ProducerGraphHtml`'s `Set-Content` appended the platform's newline,
   leaving a one-byte difference at the end of the file. Both produced identical
   line counts and no differing line. Neither was visible from the working
   tree — `-Check` passed there throughout. Fixed by adding the rule and by
   writing the bytes rather than by normalising the comparison. LEDGER 51.

8. **`-ColorBy` was requested by the prompt's design and could not be used.**
   The pass wanted colour to carry the skill families while position carried the
   layer. PSGraphRenderToHtml v0.1.0 validates `-ColorBy` against
   `{ structure, scope, type }`; PSGraphRender v0.13.0's settings schema accepts
   `{ structure, dependents, blastRadius, dependencies, reach }`. Passing `type`
   is accepted, warned about, and silently downgraded. The option was dropped
   rather than shipped as a request that never arrives. LEDGER 50, and it is a
   defect in a sibling repository rather than here.

9. **Two decision records disagree about who may move the harness `main`.**
   0009 grants it to the agent in terms; 0013 says it is operator-only and
   justifies that by enumerating 0008 and 0010 — omitting 0009, the decision
   that grants it. The prompt directs "fast-forward main per 0009", practice has
   followed 0009 since pass 0035, and this pass did the same. Flagged rather
   than settled: a pass does not get to decide a decision. LEDGER 49, STANDING.

10. **Two edges named in the prompt's design were changed.** The flow
    `new → plan → build → test → tidy → release` is stated in the JSON in the
    opposite orientation, as `plan --follows--> new`, because the producer
    contract's edge means *from depends on to* and PSGraphRender draws `to`
    below `from`. Same pairs, opposite orientation, and both files say so.
    Separately, a `you --starts-at--> new` edge was removed: it is true, and it
    renders as an arrow from `new` up to `you` in a diagram where every other
    upward arrow means *and then this*. The fact moved into the node's
    attributes.

11. **A Mermaid node id beginning `end` collides with the subgraph
    terminator.** The `end-user` node was renamed `you` in both renderings
    before the mirror was written.

12. **The 4 skill-family group nodes in the first design were dropped.**
    Grouping by role is carried by each skill's `type` and by the link map
    instead. Nested subgraphs would have made "layer membership" ambiguous in
    exactly the check the prompt asked for, and four container nodes existing in
    one rendering and not the other would have made the node counts disagree
    for a reason that is not a defect.

## 11. Cost

Wall clock: **about 3 hours 20 minutes**, from the first precondition command to
the local handoff, including the stop and resend.

Run counts:

| | |
|---|---|
| acceptance-test runs | 3 (red, green, and inside verify) |
| LEDGER-47 probe runs | 3 (precondition, committed re-run, verify) |
| diagram renders | 6 (4 authoring, 2 inside `-Check`) |
| producer-battery runs | 6, one per render, 7 cases each |
| mirror comparisons | 3, plus 5 falsification rows (1 control, 4 breaks) |
| link-check runs | 3 |
| `verify.ps1` runs | 3, of which the first two failed spot-check 1 |
| module builds | 6 — PSGraphRender built from its tag once per render |

No token count: the session cannot measure one, and a field it cannot measure
is a field it guesses at.
