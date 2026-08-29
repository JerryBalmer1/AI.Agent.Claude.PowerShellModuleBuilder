---
pass: 0000
title: Short title, imperative
date: YYYY-MM-DD
artifacts:
  - path/to/the/thing/this/entry/cites
---

# Pass 0000 — Short title

## Asked

What the prompt required. The scope as given, not as it turned out. Enough that
a reader can judge whether Done matches it.

## Done

What changed, with paths. Facts only.

## Why

The reasoning. What was rejected, and on what grounds — a rejected option with
its reason is worth more here than a chosen one without.

## Measured

Numbers, each citing an artifact that contains them. A number without a file
behind it does not belong in this field. If nothing was measured, write "none."

## Learned

What was learned, including what went wrong: wrong predictions, defects found in
work from an earlier pass, steps that had to be redone. A pass that learned
nothing says "none."

## Capability

What the plugin can now do that it could not before, stated as what is now
possible. Not a benefit, not a value claim, not an improvement narrative — a
capability. If nothing new is possible, write "none."

---

Notes on using this file:

- Write entries from the pass's artifacts, not from memory.
- If a field has nothing real in it, write "none." Padding a field is worse than
  an empty one, because it survives into the derived benefit pass as though it
  were evidence.
- Benefit is **not** written here. It is derived at the end, from the whole
  journal, in its own pass. Capability is the input to that; a benefit claim
  written now would prejudge it.
- `journal/` and `decisions/` are append-only, and are never loaded into
  context.
