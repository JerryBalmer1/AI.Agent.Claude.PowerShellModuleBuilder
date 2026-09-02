# 0013 — The harness gains release tags

Operator-directed, executed in pass 0030. Every prior decision about tags
concerns a *target* repository — 0006 tags PSAzureDevOpsGraph, 0010 extends the
same governance to the three ecosystem repos. The harness itself has never been
tagged, because until the ladder closed there was nothing to tag: a plugin whose
effect was unmeasured had no release worth a version number.

The ladder is closed. This decision amends rule 14 for the harness repository,
and only for release tags.

## What is now permitted

**The agent creates and pushes annotated tags `vMAJOR.MINOR.PATCH` on the
harness repository, at the end of a release pass, when that pass's acceptance
test is green.**

Green first, then the tag. Not the other way around, and not "green except for
the tag's own assertion" — a release pass whose acceptance test asserts the tag
exists runs the tag creation as a task and the assertion re-runs after it. The
tag names a commit whose evidence already stands.

`v1.0.0` is the **ladder-closed release**, per the reservation the LEDGER has
carried since packaging was scheduled: *"psmodule manifest: 0.1.0 (re-versioned
at packaging, 0030; v1.0.0 reserved for 'passed the ladder')."* It is not 1.0.0
because the code is finished. It is 1.0.0 because the claim on the tin has been
measured three consecutive times from fresh clones, and the measurement is
published alongside it — including the parts that are unflattering.

The tag and `.claude-plugin/plugin.json`'s `version` field state the same
number. A tag whose manifest disagrees with it is a defect.

## What a tag message must carry

**The with/without headline, and a citation to the 0029 table.** Not a summary
of the diff — the diff is in the log. A release tag on this repository is a
claim about what installing the plugin does, so the message states the measured
effect and where the evidence is:

- shape: **19 / 33 → 33 / 33**, three consecutive blind runs, first shot, from
  fresh clones;
- functional first-shot: **0 / 12 → 1 / 12** — nearly flat, and stated as
  nearly flat;
- the baseline is one run that was never permitted to iterate, so the "final"
  column has no plugin-off entry and the fair comparison is the first-shot row.

The citation is `README.md`'s *With the plugin and without it* table and the
four run records it links. A tag message that carries the win without the third
bullet is a marketing claim, and this repository does not make those.

## What is unchanged

Rule 14 otherwise stands, in full:

- **No `Publish-Module`.** Nothing here goes to the PowerShell Gallery, ever.
  Publishing a module remains the operator's, from their own shell.
- **No force pushes, no history rewrites.** A tag, once pushed, is immutable.
  A release that was wrong is superseded by a new version, never by moving a
  tag. A non-fast-forward push is a hard stop and a finding.
- **Harness `main` remains operator-only.** This decision permits tags. It does
  not permit the agent to move `main`. Decision 0008's fast-forward permission
  is for PSAzureDevOpsGraph and decision 0010's for the three ecosystem repos;
  neither extends here.
- **No other tags on the harness.** Release tags only. Not per-pass tags, not
  per-run tags.

## The consequence that makes this worth a decision

**The surface a stranger installs changes only via a tagged release.**

`.claude-plugin/marketplace.json` pins its plugin source to the tag, not to a
branch. Someone running `/plugin marketplace add` and `/plugin install` gets the
tagged tree and nothing else. This is the property that makes the rest of the
method survivable now that the repository is installable:

- `main` can move — a pass lands, a document is corrected, a backlog item is
  fixed — and **no consumer's installation changes**. Work in progress is not
  shipped by virtue of being merged.
- A blind run's instrument pin and a consumer's installed version become
  independent. The ladder pinned a plugin SHA; consumers pin a tag. Neither
  constrains the other.
- The release becomes a deliberate act with its own acceptance test, rather
  than a side effect of merging.

Without the pin, every merge to `main` would be a silent release to everyone who
had ever added the marketplace, and the honest-status section of the README
would be making claims about a tree that had already moved underneath it.

## Alternatives rejected

**Pin the marketplace to `main`.** Rejected for the reason above. It is the
default and it is the one that quietly ships unreleased work.

**Tag every pass, `v1.0.<pass>`.** Rejected. Most passes change documents. A
version number that increments when prose changes tells a consumer nothing about
whether to upgrade, and it would make the tag list unreadable at exactly the
moment it starts being read by strangers.

**Wait for a second baseline run before 1.0.0** (backlog 17). Considered
seriously, and rejected on the grounds that it would hold the release
indefinitely for a measurement that improves the *table*, not the artifact. The
missing control is disclosed in the README, in the CHANGELOG and in the tag
message itself. Shipping with a stated gap is honest; shipping with the gap
hidden would not be, and waiting silently is a third thing that helps nobody.

## What the next major means

Stated here so it is settled before anyone asks: **MAJOR increments when a
consumer's existing use breaks** — a skill removed or renamed, a command's
contract changed, a convention the conformance suite enforces reversed. MINOR
adds skills, commands or conventions. PATCH corrects documents and fixes defects
without changing what the plugin asks a builder to do. The README's versioning
promise states the same thing in consumer words and is the copy a consumer
reads; this paragraph is the one a future pass reads.
