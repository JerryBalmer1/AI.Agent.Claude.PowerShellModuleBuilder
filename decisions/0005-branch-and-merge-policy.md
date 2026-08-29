# 0005 — Branch and merge policy

## The problem this records

Every pass from 0001 to 0014 landed on a single branch named
`pass-0009-control-polarity`. The name identifies nothing: the
branch carries six passes that are not pass 0009. Meanwhile `main`
is 21 commits behind, and its tip is two commits named "force
agent stop". A fresh clone — the stated foundation of every verify
script — lands on `main` and contains none of the project.

## The policy

1. Each pass runs on its own branch, `pass-NNNN-<slug>`, cut from
   the tip of the previous pass's branch, or from `main` once
   `main` has caught up. The pass prompt names the branch; the
   agent creates it as a precondition.
2. Only the operator moves `main`, from their own shell, and only
   after a pass's verify exit code has been observed (rule 14 is
   unchanged). Fast-forward where possible.
3. "Fresh clone" in every verify script spec means a fresh clone
   with the pass branch checked out; the verify record names the
   branch alongside the SHA.
4. History is never rewritten. The "force agent stop" commits
   stand; their messages are the record of what happened.

## Rejected

- Keeping one rolling branch: the name drifts from the content,
  as it already has.
- Having the agent merge or push `main`: violates rule 14, which
  exists precisely so no automated action can publish.
- Rewriting `main` to remove the stop commits: invalidates every
  SHA recorded in plans, journals, and decisions 0001–0004.
