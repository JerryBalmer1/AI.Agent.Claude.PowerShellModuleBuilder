---
pass: 0003
title: Remove the duplicate runner from the repository root
date: 2026-08-28
artifacts:
  - git commit d432c38
---

# Pass 0003 — Remove the duplicate runner from the repository root

## Asked

Not recoverable. The commit subject is "force agent stop", which records how the
pass ended rather than what it was asked to do.

## Done

`git show --stat d432c38`: `Invoke-Conformance.ps1 | 84 --------`, one file
changed, 84 deletions. The copy at the repository root was deleted. The
zero-byte `evals/conformance/Invoke-Conformance.ps1` was left in place.

## Why

Not recoverable. The effect is that the runner no longer existed at two paths;
the effect is also that, at this commit, it did not exist at either — the
remaining file was empty.

## Measured

None.

## Learned

Not recorded. The commit subject "force agent stop" indicates the pass was
interrupted rather than completed, which is consistent with the state it left:
the duplicate removed, the real file not yet written.

## Capability

None. This pass removed something; it added nothing.
