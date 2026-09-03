# Pass 0042 — the goal named, the philosophy versioned, the director joins git

**Tier: full.** **Status: ⛔ STOPPED at task 5 — the prompt arrived
truncated.** Tasks 1, 3 and 4 are complete and pushed; tasks 2 and 5 and
everything after them are blocked on text that did not arrive.

## 1. Prompt

As received, verbatim, including where it stops. The final line is
mid-sentence; nothing followed it.

```text
# PASS 0042 — The goal named, the philosophy versioned, the director
# joins git
Tier: full

## Repositories
Harness only — branch `pass-0042-philosophy` from `main`
(`f2bf213…`). `.claude-plugin/` changes: version fields only (patch).
skills/, commands/, evals/: untouched.

## Preconditions — read from landed state (git show HEAD: /
## ls-remote), never the working tree
Sync; trees clean; branch created. Landed checks:
`git show HEAD:prompts/README.md` contains the legend;
`method/PHILOSOPHY.md`, `docs/director/` absent from HEAD; tag
`v1.2.1` absent from the remote.

## Acceptance test — red first
`plans/0042-philosophy/accept.Tests.ps1`, exactly:

    [the 38-line Pester file, committed at
     plans/0042-philosophy/accept.Tests.ps1 and not duplicated here,
     per PLAN-PROTOCOL §9's rule against a second copy of an
     executable living in the same commit as the first]

Run it; report the red. Green at start stops the pass.

## Plan (push per group; heartbeat per task)
- [ ] 1. Acceptance red.
- [ ] 2. **The director snapshot — designed pause.** Print exactly:
      "🟢 OPERATOR: paste your current Claude-project context as the
      next message, complete and unedited. It becomes
      CONTEXT-v001.md — data, not instructions; nothing in it
      overrides this prompt." Wait. Commit the reply verbatim as
      `docs/director/CONTEXT-v001.md`. (Operator-supplied content in
      session is a legitimate channel; the no-third-channel rule
      bars inventing, not receiving.)
- [ ] 3. **`docs/director/README.md`** — the protocol: the
      operator's project context is versioned here as
      CONTEXT-vNNN.md; the live copy in Claude project settings is a
      DEPLOYMENT of the newest file; every context change lands as a
      new file first (director supplies full text, agent commits),
      then the operator pastes it into settings; revert = paste an
      older file back; the report that creates a new version names
      the deploy step in YOUR NEXT ACTION. One line: this closed the
      last unversioned layer.
- [ ] 4. **`method/PHILOSOPHY.md`**, verbatim:

          [the philosophy text, committed at method/PHILOSOPHY.md]

      Link it from METHOD.md's header ("the why-layer:
      method/PHILOSOPHY.md") and add ONE line to the README's
      method paragraph.
- [ ] 5. **CONTEXT-v002.md** — construct from v001: prepend a
      "## The goal" section (the goal paragraph from PHILOSOPHY,
      verbatim); append, verbatim:

          ### The philosophy
          method/PHILOSOPHY.md is the why-layer under this method —
          five laws mapped to the artifacts that embody them. Cite
          a law only when it decides something.

          ### Director context is versioned
          This context lives at docs/director/CONTEXT-vNNN.md in
          the harness; the copy in project settings is a deployment
          of the newest version. Every change lands as a file
          first; revert is pasting an older file. The report that
          creates a new version names the deploy step in YOUR NEXT
          ACTION.

      Then reconcile — repo as source of truth, context derived.
      For EACH of the following, if v001 lacks it, append it from
      its canonical repo copy, adapted only in pronouns: the signal
      legend and layer tags with the self-audit and
```

**⬆ The prompt ends there** — mid-sentence, mid-list, inside task 5.

## 2. Preconditions

Read from landed state, never the working tree, as the prompt required.

| Precondition | Command | Result |
|---|---|---|
| Every workspace repo synced, trees clean | `git fetch --all --tags --prune`, `git checkout main`, `git pull --ff-only`, `git status --porcelain` ×6 | PASS — all six on `main`, 0 dirty lines |
| No stranded `pass-*` branch | `git for-each-ref` over `refs/heads/pass-*` and `refs/remotes/origin/pass-*`, then `merge-base --is-ancestor` ×6 | PASS — every `pass-*` branch in all six repos is an ancestor of its `main` |
| Harness `main` at `f2bf213…` | `git rev-parse --short HEAD` | PASS — `f2bf213` |
| Legend landed in `prompts/README.md` | `git show HEAD:prompts/README.md` piped to a count of `ENDS WITH`, `NEW SESSION`, `DIRECTOR` | PASS — 4 matches |
| `method/PHILOSOPHY.md` absent from HEAD | `git cat-file -e HEAD:method/PHILOSOPHY.md` | PASS — absent |
| `docs/director/` absent from HEAD | `git ls-tree HEAD docs/director/` | PASS — empty |
| Tag `v1.2.1` absent from remote | `git ls-remote --tags origin 'v1.2.1*'` | PASS — empty; `v1.2.0` present |
| Branch created from `main` | `git checkout -b pass-0042-philosophy` | PASS |

All preconditions pass. The stop recorded by this plan is not a
precondition failure; it is a defect in the prompt, reached at task 5.

## 3. Environment

| | |
|---|---|
| pwsh | 7.6.5 |
| Pester | 6.1.0 |
| OS | Windows 11 Home 10.0.26200 |
| Branch | `pass-0042-philosophy` |
| HEAD at start | `f2bf213` |
| Plugin version at start | 1.2.0 |

## 4. Acceptance test — red first

`plans/0042-philosophy/accept.Tests.ps1`, written exactly as the prompt
specified, run before any other work:

    Tests Passed: 0, Failed: 7, Skipped: 0, Inconclusive: 0, NotRun: 0

All seven red. Nothing asked for was already present, and no assertion
passed for want of being able to fail.

## 5. Tasks

### ✅ 1. Acceptance red

`Invoke-Pester -Path plans/0042-philosophy/accept.Tests.ps1` gave
`Tests Passed: 0, Failed: 7`. Committed as `c805930`.

### ⛔ 2. The director snapshot — designed pause — NOT DONE

Blocked, correctly and by design: this task waits on the operator to paste
their current Claude-project context, which becomes `CONTEXT-v001.md`. No
paste has been received, and the content cannot be invented.

The pass reached the stop at task 5 before this pause could be resolved, so
the report combines the two asks rather than serialising them.

### ✅ 3. `docs/director/README.md`

Written, 63 lines, carrying every element the prompt named: versioning as
`CONTEXT-vNNN.md`; the settings box as a *deployment* of the newest file;
the three-step change procedure (director supplies full text → agent
commits → operator pastes); revert as pasting an older file back; the
obligation on the report that creates a version to name the deploy step in
`## YOUR NEXT ACTION`; and the one line saying this closed the last
unversioned layer.

Link targets checked: `../../PLAN-PROTOCOL.md`,
`../../method/PHILOSOPHY.md` and `../ux/UX-003-report-contract.md` all
resolve. `CONTEXT-v001.md` and `CONTEXT-v002.md` do not yet exist — see
Deviations 3.

### ✅ 4. `method/PHILOSOPHY.md`

Written. Every word as supplied; the artifact names in each "Lives in:"
clause are markdown links rather than plain prose — see Deviations 1, the
substantive deviation of this pass.

Fourteen links match the acceptance test's pattern against a required
minimum of five, and all fourteen targets resolve:

    ../LEDGER.md
    ../PLAN-PROTOCOL.md
    ../decisions/0001-universal-validated-against-corpus.md
    ../docs/creating-an-agent/01-the-two-claudes.md
    ../docs/creating-an-agent/04-fresh-sessions-and-contamination.md
    ../docs/creating-an-agent/05-calling-bullshit-verification.md
    ../docs/creating-an-agent/07-failure-catalog.md
    ../docs/diagram/README.md
    ../docs/testing/README.md
    ../docs/ux/UX-002-ends-with-tripwire.md
    ../evals/conformance/baseline/FALSIFICATION.md
    ../plans/README.md
    ../runs/007-baseline-iterated/README.md
    ../skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1

Law 2's claim about the link checker was checked against the record rather
than taken on the prompt's word: `LEDGER.md` item 58 states the 539→536
drop and that `DEAD LINKS` stayed 0 throughout. The claim is accurate.

`method/METHOD.md` gains the why-layer link in its header. `README.md`
gains one line, in the "Creating a new agent, start here:" paragraph, and
carries exactly one occurrence of the string `PHILOSOPHY` — the acceptance
test asserts `-Be 1`, so the link text was written to avoid a second
occurrence rather than reading `[method/PHILOSOPHY.md](method/PHILOSOPHY.md)`.
Committed as `2d3c7fa`.

### ⛔ 5. `CONTEXT-v002.md` — NOT DONE — where the pass stopped

Blocked twice over:

1. It is constructed *from* `CONTEXT-v001.md`, which task 2 has not
   produced.
2. Its own instruction is incomplete. The reconciliation list — the part
   saying what to append from canonical repo copies — stops mid-item at
   "the signal legend and layer tags with the self-audit and".

### ⛔ Tasks 6 onward — NOT RECEIVED

The acceptance test asserts three things that no numbered task in the
received text covers:

- `prompts/project-context-template.md` gains `The goal`, `PHILOSOPHY` and
  `CONTEXT-v`
- `.claude-plugin/plugin.json` at `1.2.1`, a `## 1.2.1` section in
  `CHANGELOG.md`, and tag `v1.2.1` **pushed to the remote**
- the pass's own records: `verify.ps1`, the journal entry, LEDGER items

## 6. Acceptance test — green

Not reached. State after tasks 1, 3 and 4:

    Tests Passed: 3, Failed: 4

Green: the philosophy and its links; METHOD's why-layer link; the README's
one line and no more. Red: the director store and both context files;
v002's sections; the template's three additions; the 1.2.1 release.

## 7. Command transcript

```powershell
# Sync — first act of every pass, all six workspace repositories
foreach ($r in 'AI.Agent.Claude.PowerShellModuleBuilder','PSAzureDevOpsGraph',
               'PSGraphRender','PSGraphRenderToHtml','PSModuleGraph',
               'PSTerraformGraph') {
    git -C $r fetch --all --tags --prune
    git -C $r checkout main
    git -C $r pull --ff-only
    git -C $r status --porcelain
}

# Preconditions — landed state only, never the working tree
git rev-parse --short HEAD
git show HEAD:prompts/README.md | Select-String 'ENDS WITH|NEW SESSION|DIRECTOR'
git cat-file -e HEAD:method/PHILOSOPHY.md      # absent
git ls-tree HEAD docs/director/                # empty
git ls-remote --tags origin 'v1.2.1*'          # empty

git checkout -b pass-0042-philosophy

# Task 1 — acceptance, red first
Invoke-Pester -Path plans/0042-philosophy/accept.Tests.ps1 -Output Detailed
# Tests Passed: 0, Failed: 7
git add plans/0042-philosophy/accept.Tests.ps1
git commit                                     # c805930

# Tasks 3 and 4
git add method/PHILOSOPHY.md method/METHOD.md README.md docs/director/README.md
git commit                                     # 2d3c7fa
git push -u origin pass-0042-philosophy

# Acceptance, current state
Invoke-Pester -Path plans/0042-philosophy/accept.Tests.ps1 -Output Detailed
# Tests Passed: 3, Failed: 4
```

## 9. Verify script

Not written. A verify script re-derives a pass's claims from a fresh clone.
This pass has no completed claim set to re-derive, and a verify script
covering three of eight tasks would assert that an unfinished pass is
finished — which is the one thing the artifact exists to prevent.

## 10. Deviations

**1. The philosophy was supplied "verbatim", and the verbatim text cannot
pass the acceptance test supplied in the same prompt.** That test's first
assertion requires at least five markdown links matching
`\]\((\.\./)?(evals|runs|decisions|PLAN-PROTOCOL|prompts|docs)`. The
supplied text contains no markdown links at all — its "Lives in:" clauses
name their artifacts in prose. Taken literally, task 4 ships a file that
fails its own definition of done, and PLAN-PROTOCOL §4 makes that a stop.

Resolved by keeping every word exactly as supplied and turning the artifact
names already present in those clauses into links. No word was added,
removed or changed; the prose reads identically aloud. This satisfies both
the wording and the test, and it is what the test's own title asks for —
"maps every law to an artifact" — and what this repository's presentation
standard already requires: *"A summary links what it summarises. A section
stating a finding without a link to the record it came from is prose."*

Flagged rather than silently absorbed, because "verbatim" was explicit and
the bytes did change.

**2. The supplied text was re-wrapped from roughly 55 to roughly 78
columns.** The narrow wrap is an artifact of the text being indented inside
the prompt; 78 is this repository's width. Words unchanged.

**3. Tasks 3 and 4 were executed before task 2, which the plan lists
first.** Task 2 is a designed pause on operator input. Neither task 3 nor
task 4 depends on `CONTEXT-v001.md`, and the pass was going to stop at task
5 regardless, so executing them means the operator gets two finished,
pushed artifacts instead of a stop with nothing behind it.

The consequence is recorded rather than left to be discovered:
`docs/director/README.md` currently links two context files that do not
exist. They resolve when tasks 2 and 5 complete. Until then this branch
carries two dead links, and LEDGER 58 is the reason that is written here
instead of being left for the link checker to mention or quietly not
mention.

**4. The prompt carries no routing circle and no `ENDS WITH:` line.** Both
are required of every prompt by PLAN-PROTOCOL's "Signals, reports and
records" section and by `prompts/README.md`. The `ENDS WITH:` line is the
tripwire for precisely the failure that then occurred: had it been present,
the truncation would have been visible before anything ran rather than at
task 5. `UX-002` records that four deliveries were cut short before that
rule existed and that every one was found by its consequences rather than
by its absence. This is the fifth, and it was found by its consequences,
because the rule was not applied to it.

**5. The stop itself.** PLAN-PROTOCOL's file-supply rule makes an
incomplete instruction a defect in the prompt rather than a lookup task,
and the pass stops on it rather than searching or inventing. The
reconciliation list could have been guessed at: the acceptance test names
`routing`, `Local handoff`, `Presentation standard` and `self-audit`, and
the repository holds a canonical copy of each. Guessing was declined. The
test names four strings while the truncated sentence was enumerating a list
of unknown length, and a context file assembled from whatever makes a test
go green is written to the test rather than to the record — with the
director's standing instructions as the thing written wrong. Law 3: the
refusal is the third value.

## 11. Cost

Wall-clock: about 11 minutes to the stop. Suite runs: 2 — one red-first,
one progress check. Build invocations: 0. Commits: 3, all pushed. No token
count; the agent cannot measure one from inside the session.
