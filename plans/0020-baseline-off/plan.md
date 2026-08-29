# PASS 0020 — Run 003: the plugin-off baseline

Tier: full.
Branch: `pass-0020-baseline-off`.
Pinned HEAD: `42c717b98ba048a1c8c134a480e308c310c19e9d`
(pushed tip of `pass-0019-history-unification`; `origin/main` equals it —
decision 0009's "they move together" holds, so the pass proceeds).

Target repo: `PSAzureDevOpsGraph`, branch `run-003-baseline-off` only.
No tag, no `main` — measurement line, per decision 0008's amendment.

## What this run measures

The same seed and brief as run 002, scored the same way, with the plugin's
content unread. It answers "does the plugin earn its keep". A bad score is
the wanted data as much as a good one; 12/12 would mean the model already
knew, which is worth learning before three reliability runs are spent.

## Preconditions (checked before the branch was cut)

| Check | Result |
| --- | --- |
| Tree clean | clean |
| `origin/main` == pass-0019 pushed tip | both `42c717b98ba048a1c8c134a480e308c310c19e9d` |
| `evals/functional/BRIEF.md` blob | `93c5cec3299da0ac27d3aea67f4fbcf0000001ec` — asserted |
| Oracle blob (ls-tree only, file never opened) | `bd7b3c4f4f8ce9901c7a6a02073c0cb5ff3ec4dc` at `evals/functional/fixture/expected-graph.json` — asserted |
| `$env:AZDO_PAT` | set |
| `scratch/runs/003-baseline-off` | absent |
| remote branch `run-003-baseline-off` | absent (target remote had only `main`, `run-002-first-build`, tags v0.1.0/v0.2.0) |

Local `main` sat at `51e2131626e9c424ccce3e7abdeace840ee66c57`, behind
`origin/main`; it is fast-forwarded at step 7 per decision 0009.

### Tools

- pwsh 7.6.5
- git 2.41.0.windows.1
- Pester 5.7.1 (pinned with `-RequiredVersion`; 6.1.0 and 3.4.0 also present)
- Windows NT 10.0.26200.0
- Builder: Claude Opus 5 (1M context)

## Phase 1 blindness

Read-allowlist until the built module is pushed: `evals/functional/seed/`,
`evals/functional/BRIEF.md`, `evals/functional/fixture/graph.schema.json`,
the pass prompt, this plan file, the run directory. Forbidden: `skills/`,
`commands/`, `cases.md`, `expected-graph.json`, `fixture/repos/`, every test
and script under `evals/`, `runs/`, `plans/`, `journal/`, `decisions/`,
`method/`, all of PSModuleGraph.

Two notes on how that was kept, both recorded now rather than reconstructed:

1. The acceptance test was written from the pass prompt's own field list.
   Run 002's equivalent lives under `plans/`, which is forbidden, so it was
   not opened. The prompt enumerates every field, so nothing was lost.
2. `PLAN-PROTOCOL.md` is on neither list. It is not read during Phase 1;
   this plan is conformed to it after the gate.

## Checklist

- [x] 1. Acceptance red. 0 passed / 15 failed, all for absence of the run record.
- [ ] 2. `Reset-Target.ps1 -Destination scratch/runs/003-baseline-off`. Phase 1 starts.
- [ ] 3. Build from seed and brief alone, to my own best practice. One attempt;
      no score-and-retry loop exists in a baseline. Commit at milestones.
- [ ] 4. Export graph, commit, push `run-003-baseline-off`, record SHA.
      Phase 1 ends. **Gate.**
- [ ] 5. Score: `./build.ps1` if present; `Invoke-Conformance.ps1` all four
      tags; `Compare-Graph.ps1`. First scores stand.
- [ ] 6. `runs/003-baseline-off/`: README, `graph.json`, `diff.txt`,
      `003.html`, `findings.md`.
- [ ] 7. Acceptance green. Plan, verify script, journal. Push; fast-forward
      harness `main`.

## Deviations

(none yet)
