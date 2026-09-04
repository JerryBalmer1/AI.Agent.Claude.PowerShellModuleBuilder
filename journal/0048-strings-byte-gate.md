# 0048 — the STRINGS block joins the byte gate

## Asked

Close LEDGER backlog 64. `tests/LinkMode.Tests.ps1` in PSGraphRender asserts
that an `editor`-mode document is byte-identical to the base commit's for the
same payload — the strongest gate that repository has against a refactor that
claims to preserve behaviour and does not. `Get-DocumentCode` removes the whole
`STRINGS` block before that comparison, because acceptance B's carve-out for
`vscode://` prose is exactly that block and one helper serves both. So every
user-visible string in the renderer was invisible to it. Backlog 64 named the
shape of the fix: compare `STRINGS` the way `CONFIG` is already compared, where
an existing key may not change value and only additions are permitted.

Tier full. PSGraphRender writable at `tests/` and `CHANGELOG.md` only; no `src/`
change; `Get-DocumentCode` unchanged; acceptance C's base SHA stays `cd4857d`;
no tag, no version bump; backlog 65 logged, not taken.

## Done

- `tests/LinkMode.Tests.ps1` — one `It` inside `Describe 'Acceptance C: editor
  mode preserves the base document exactly'`, beside the CONFIG one, against the
  base document that `Describe` already builds. It asserts the `STRINGS` keys
  present at head and absent at base are exactly `MenuCopyLink`, `MenuOpenLink`
  and `ReasonNoTemplate`; that those three carry their shipped values; and that
  no key present at base has a different value at head, with the key and both
  values in the message. 53 lines. `Get-DocumentCode` untouched.
- `CHANGELOG.md` — one entry under `## [Unreleased]`. No tag, no version bump.
- `plans/0048-strings-byte-gate/` — `plan.md`, `verify.ps1`, and the scripts and
  captured runs behind every number in it: `observe.ps1` /
  `observe-blindness.txt`, `probes.ps1` / `probes-run.txt`, `spotchecks.ps1` /
  `spotchecks-run.txt`, `test-task.txt`, `conformance-base.txt`,
  `verify-run.txt`, `verify-failcheck.txt`, `verify-landed-main.txt`.
- `LEDGER.md` — backlog 64 RESOLVED by dated append, never rewritten; backlog 65
  opened; head entry and numbering note updated.

## Why

**Why one `It` in that `Describe` rather than a file of its own.** The base
document costs a fresh clone plus a full build in a child process. A second file
pays for it twice, and the assertion needs exactly the artifact this `Describe`
already has in `$script:BaseDoc`.

**Why `Get-DocumentCode` was not widened instead.** It is the obvious fix and it
is wrong. Acceptance B asserts no `vscode://` occurs outside the renderer's
static UI strings, and the carve-out that makes that assertion meaningful *is*
the `STRINGS` block. Removing it turns acceptance B red against correct work.
Two checks needed different treatment of the same region, so the region gets a
second check rather than the first check getting a wider mouth.

**Why the additions are named rather than counted.** A count passes just as
happily when one addition is swapped for another, and the whole claim of an
additive change is about which keys arrived.

**Why the additions are also pinned by value.** Not the original design — see
Learned. The value loop iterates the keys present at base, so it is structurally
silent about anything added. Pinning the three mirrors what the CONFIG case
beside it already does with `$head.LinkMode | Should-Be 'editor'`, described in
its own comment as "the half of the control that pins WHICH value the default
is".

**Why acceptance C's base stayed `cd4857d`.** Re-baselining to `3f2ec85` would
empty the additions list, leaving a gate whose expectation is "nothing was
added" — vacuous by construction on the day it ships. At `cd4857d` the gate
asserts 0047's three additions from its first run.

**Why the red-first artifact is a green run.** There is no failing new assertion
to commit here. The thing to demonstrate is the *existing* suite passing while
the thing it should catch has already happened, so the artifact is that pass,
with the mutation proved to be in the document.

**Rejected: mutating the shipped template set to falsify.** Every probe mutates
a scratch clone. A suite that rewrites `src/` to make its own assertion move has
stopped testing the thing that ships.

**Rejected: taking backlog 65.** Repairing the workspace-composition assertion
changes a conformance assertion and therefore the denominator, which wants its
own red-first iteration with cases-run stated at both ends.

## Measured

- **The blindness, before anything was written** — `observe-blindness.txt`. With
  `MenuOpenLink` changed from `Open Link` to `MUTATED BY D1`, and separately with
  `D2AddedKey` added, the shipped acceptance-C comparisons against the base both
  came back **GREEN**. Each mutation was asserted present in the rendered
  document first.
- **`STRINGS` at head over base** — `observe-blindness.txt`: added
  `MenuCopyLink`, `MenuOpenLink`, `ReasonNoTemplate`; none removed; none changed;
  78 keys → 81.
- **The suite** — `test-task.txt`: 144 passed, 0 failed, line coverage **81.36%**
  against an 80% threshold that throws.
- **Falsification** — `probes-run.txt`: P1 changed value RED naming key and both
  values; P2 added key RED naming it; P3 removed key RED, caught by the value
  clause (`null` at head against `"Copy Path"` at base); P4a theme value → gate
  GREEN, CONFIG **RED**, body GREEN; P4b script line → gate GREEN, body **RED**;
  control all green.
- **Spot-checks** — `spotchecks-run.txt`: SC3 known-good green, known-bad
  (additions list emptied) RED with the message naming what actually arrived;
  SC4 clean over 7 files, red demo catching a planted drive path, home dir and
  `vscode://` URI, known-good producing no hit.
- **Conformance** — `verify-run.txt`, measured at both commits in-run rather
  than quoted: base **66.27% over 166 cases**, head **66.27% over 166 cases**,
  `CasesDefined` **42** at both ends, no assertion that passed at base failing at
  head. Fourth independent reproduction of backlog 63.
- **Verify** — `verify-run.txt` PASS exit 0 against the pass tip;
  `verify-failcheck.txt` PASS exit 0 with F1 and F2 both firing;
  `verify-landed-main.txt` against landed `main`.

## Learned

**The fix as specified could not see the keys it was about, and only the probe
said so.** Backlog 64 described the fix precisely — additions permitted, existing
keys pinned by value — and written exactly that way, the gate stayed green when
`MenuOpenLink`'s value was changed. The value clause iterates the keys present at
*base*, and all three keys pass 0047 added are by definition not among them. The
three strings whose arrival the entry was about were the only user-visible
strings the new gate still could not see: the same class of hole it was written
to close, on exactly the keys in question. A correct-sounding specification, read
carefully and implemented faithfully, produced a gate with a hole in the middle
of its own subject. Nothing but running the probe would have found it.

**A theme value is not a body change.** The pass prompt's scope control predicted
that mutating `theme.psd1` would turn the *body* comparison red while the new
gate stayed green. Every theme value the page uses is emitted into the `CONFIG`
block, which the byte comparison strips before comparing — so a theme edit turns
the *CONFIG* comparison red and the body stays green, measured as eight mutated
colours all landing at lines 802–846 inside a `CONFIG` block spanning 798–851.
The prediction was about where a value lives in the output, and the only way to
know that is to look at the output. This is the second consecutive pass whose
load-bearing scope probe was written asserting the wrong thing; 0047's P1b was
the first, and it recorded the same lesson.

**Splitting it made the claim stronger than the original probe would have.**
Theme→CONFIG and script→body are two probes where the prompt asked for one, and
together they assert that three checks *partition* the document rather than that
two checks differ. That is the division of labour the prompt was reaching for.

**A detector cannot be scanned by itself.** SC4 greps everything the pass commits
for drive paths, home directories and `vscode://` URIs carrying real paths — and
fired on the file that defines the grep, which necessarily contains all three as
a regex and as its own red demo. Carved out by exact leaf name, and the carve-out
held to acceptance B's standard: one assertion proves it excludes something that
really does match, another proves it left the pass's own files scanned. The same
shape as the carve-out this whole pass exists to compensate for.

**A console log is something a pass commits.** Captured output is full of machine
paths, and SC4 does not exempt it. Scrubbed to placeholders with a header saying
so. Noted while doing it: `plans/0047-link-mode/probe-red-full.txt` carries five
drive-path lines, so either SC4 has not in practice been run over log artifacts
or 0047 shipped a violation. Not fixed — plan artifacts are frozen by decision
0004.

**A typed parameter is not shadowed by a same-named local.** `$landed = & $Landed
$doc` assigns a boolean into the `[scriptblock] $Landed` parameter, because
PowerShell variable names are case-insensitive, and the cast throws. It reads as
a parameter-binding failure at the call site and is a variable-naming bug inside
the function.

## Capability

The renderer's user-visible strings are now inside the byte gate. A change to any
of the 81 strings in the shipped `cytoscape` set — a reworded message, an added
key, a deleted one — turns `tests/LinkMode.Tests.ps1` red against the base
document, naming the key and both values, instead of passing silently as it did
through pass 0047. What the gate still cannot do is speak for a second template
set: it is one document from one backend, and whether it should generalise across
*n* sets is logged in backlog 64's closing note for the pass that brings a third.
