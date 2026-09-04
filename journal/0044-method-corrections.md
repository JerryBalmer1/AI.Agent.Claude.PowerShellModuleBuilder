# 0044 — method corrections from 0043

## Asked

Write pass 0043's durable corrections into the standing documents and the
conformance suite. Two rules into `method/METHOD.md` — that a named check counts
only once its polarity has been shown, and that conventions come from the
repository rather than from recall. Three additions to `PLAN-PROTOCOL.md` — the
five task signals, a multi-source frontier precondition, and the recovery-phase
pattern. One conformance assertion with its falsification control: a tracked
workspace file must not register PSModuleGraph. LEDGER backlog entries from 59.
Harness writable, the four ecosystem repositories read-only.

## Done

Nine commits on `pass-0044-method-corrections`, no module source anywhere.

- `method/METHOD.md` — two rules, one commit each (`606b68a`, `2a50443`). Written
  in the document's own form: bold-tagged paragraphs, 42 rules to 44.
- `PLAN-PROTOCOL.md` — three sections, one commit each (`4b7cebb`, `6830a75`,
  `5f1f42b`): *The five task signals*, *The frontier is read from three sources*,
  *The recovery phase*.
- `docs/ux/UX-007-task-signals.md` and an index row in `docs/ux/README.md` — not
  asked for, required by the section the legend was added to.
- `evals/conformance/Conformance.Tests.ps1` — `Describe 'Workspace composition'`,
  tagged `HouseStyle`, plus a `$WorkspaceFiles` discovery collection (`d5a90b2`).
- `evals/conformance/baseline/FALSIFICATION.md` — rows 18a-18e and the
  real-repository sweep.
- `plans/0044-method-corrections/` — `accept.ps1`, `verify.ps1`,
  `Test-WorkspaceFalsification.ps1`, `plan.md`.
- `LEDGER.md` — counter to 0044, backlog 59, 60, 61, next-free note (`76fdf3a`).

## Why

The two METHOD rules went where their siblings already live rather than at the
end of the file: polarity beside the falsification-row rule it generalises, and
conventions-from-the-repository beside the file-supply rule, which is the other
prompt-authoring rule in the document.

**Rejected: introducing rule numbering to METHOD.md.** The prompt asked for the
rules to be "numbered continuously after its current last rule" and there is no
numbering to continue — inventing one to satisfy a string would have been the
exact failure the second new rule forbids. The repository had already ruled on
this shape at commit `64fee46`, *"Replace an invented convention with the
assertion it was standing in for"*.

**Rejected: a text match for the assertion.** Matching `PSModuleGraph` passes the
break and fails the scope control, and an assertion that fails the scope control
fires on every file that *documents* the rule — including `FALSIFICATION.md`,
`UX-007` and the METHOD rule. It parses the workspace file as JSONC and compares
`folders[].path` by segment instead.

**Rejected: repairing `PSGraphRender.code-workspace`.** The assertion found a
real violation there. The repository is read-only this pass, and METHOD is
explicit that an assertion is never weakened, and a failing target never quietly
fixed, because it fails. It went to the operator as backlog 60.

**Rejected: making the suite runnable against the harness.** The cheap fix is
`-AllowNullOrEmptyForEach` on three existing assertions, which would change
cases-run for other targets inside a pass scoped to adding one assertion. Backlog
61, wanting its own red-first iteration.

## Measured

| | |
|---|---|
| Acceptance test, red first | exit **17**, 17 findings — `plan.md` §4 |
| Acceptance test, green | exit **0**, 21 checks — re-run from a fresh clone in `verify.ps1` check 1 |
| Falsification rows | **5 of 5 correct**, driver exit 0 — `FALSIFICATION.md` rows 18a-18e |
| METHOD tagged rules | **42 → 44** |
| `docs/ux/` records | **6 → 7**, index matching disk |
| LEDGER backlog | 58 → **61**, next free 62 |
| `verify.ps1` | **PASS**, exit 0, with `-FailCheck`, both probes red |

The assertion against the five workspace repositories: three inapplicable (no
tracked workspace file), one **red** (PSGraphRender), one **ungradeable** (the
harness). Recorded in `FALSIFICATION.md` and in `plan.md` §5.

## Learned

**Three named checks in this pass answered wrongly, and the pass exists because
three named checks in the last one did.** The acceptance test reported both
METHOD rules missing while both were present — `Where-Object` yields `$null` when
it filters everything out, and `$null.Count` throws under StrictMode. The
falsification driver reported ZERO CASES on all four of its rows when the truth
was that discovery had failed on an unrelated assertion. And `verify.ps1` printed
an error and exited 0, because a terminating error skipped its exit lines. The
first new METHOD rule found its own author, twice in his own tooling.

The most useful of the three is the driver's, because it names a distinction
worth keeping: **"this check had nothing to look at" and "this check never ran"
produce the same silence, and only one of them is a legitimate result.** Row 18e
exists to hold that distinction, and the driver now fails loudly on a failed
container rather than reporting an empty count.

**Pester 6 treats an empty `-ForEach` as a discovery error that fails the entire
file**, not as zero cases. That single behaviour is why the new assertion carries
`-AllowNullOrEmptyForEach`, and why the conformance suite cannot run against the
harness at all — which in turn is why the one `.code-workspace` that motivated
the assertion is the one file the assertion structurally cannot reach.

**The prompt carried three requirements written from recall** — a rule numbering
METHOD.md has never had, a "0032 misnumbering" that is 0031's and is about
backlog numbers, and a precondition whose literal reading would have hard-stopped
the pass on the very finding it was commissioning. Each was reported rather than
worked around, and the second METHOD rule this pass wrote is the one that says
what to do about them: the repository wins, and the disagreement is a finding.

**The signal legend collides with the routing circle on three of its five
markers.** Nobody had noticed because the two never appear in the same position.
Writing UX-007 is what surfaced it, which is the argument for the rule requiring
the record.

## Capability

The repository can now tell whether a check can fail before it counts the check's
answer — the rule is written down, and one assertion carries a five-row proof of
it that includes a scope control, a segment control and an absence control.

A tracked workspace file that registers the read-only reference is now a red test
rather than something two sessions can look for and miss. It found one on its
first run.

A prompt whose pass number, backlog number or frontier disagrees with the
repository now stops at a stated precondition with all three sources recorded,
instead of proceeding on a counter that had drifted.

A hard-stop report can now carry a recovery phase to its own re-issue under
written rules — idempotent, check-then-act, pre-ratified where a standing
decision already covers it, and terminating at any step the session cannot reach.

Not yet: the suite still cannot grade the repository that hosts it, and the
PSGraphRender violation is recorded rather than fixed. Both are numbered.
