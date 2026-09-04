# 0047 — link mode

## Asked

Make a node link declared configuration in PSGraphRender instead of a hardcoded
editor scheme. Three modes: `editor` preserved exactly, `hrefTemplate` building
a per-node URL from a template over view-model fields, `none`. Close the
**large** item in `docs/improvements.md` and the backlog entry pass 0043 filed,
earn the feature with a real example, release it, and record it.

Operator-complete item 1, and the prerequisite for item 2 (the 3D template set).

The re-issue carried a recovery preamble: re-read the 0046 frontier, and execute
the workspace-file ruling that was the one survivor of the 0046 completion
prompt's task 6.

## Done

`*.code-workspace` ignored in the harness, its own commit on `main` (`eef6e80`),
after re-deriving that suite `d5a90b2` discovers by `git ls-files` and so
constrains tracked files only. The harness's own tracked workspace file stays
tracked, which is the correct outcome rather than an oversight.

In PSGraphRender, `cd4857d` → `3f2ec85`, tagged `v0.14.0`, four commits:

- `7d924d8` the acceptance tests, red, before any implementation
- `b6fd92c` link mode itself
- `68a34dc` the examples
- `3f2ec85` docs, changelog, version — the release commit the tag names

`LinkMode` is an Enum of `editor | hrefTemplate | none` defaulting to `editor`,
with `LinkHrefTemplate` beside it, both declared as data in
`settings.schema.psd1`. No new validator type: `Enum` and `String` already
existed. No contract change: every token resolves from a field the view model
already carries, checked before code was written.

The mode is resolved at **assembly**, by `SlotsBySetting` in `templateset.psd1`,
not by a branch in the browser. `editor-link.js` became `link/common.js` plus
one file per mode, and the menu entries, selection action and diagnostics row
became slots filled at the positions they already occupied.

Two harnesses: `tests/LinkMode.Tests.ps1` for what is in the document,
`tests/browser/link-mode.cjs` plus `./build.ps1 -Task TestLinkMode` for what it
does in Chromium. A seventh example, `examples/links/forge-links.html`, with
live GitHub links from a committed file.

`verify.ps1`, six checks and six probes, green and falsified twice against the
tagged commit.

## Why

**Why the mode is chosen at assembly rather than at load.** This was put to the
operator as a fork, because acceptance B's carve-out — "no `vscode://` beyond
the renderer's static UI strings" — is drawn precisely around the five
`strings.psd1` messages and precisely *outside* the one live scheme literal in
`editor-link.js`. A runtime branch leaves that literal in every document, inert
but present. The operator ruled for assembly-time selection: the acceptance's
literal reading was achievable, so the implementation moves rather than the
acceptance. A report is one self-contained file that gets forwarded, so "the
action absent, not stubbed" has to be a fact about the artifact.

**Why the refactor is a directory of small files instead of one file per mode.**
Acceptance C requires an `editor`-mode document to stay byte-identical to the
base. That forbids code *moving* within the assembled document. The obvious
design — each mode exporting `LINK_NODE_ACTIONS` and `menu.js` doing a
`concat` — changes `menu.js`'s bytes for no behavioural reason, and C would
have caught it. Slot composition keeps every byte where it was. The cost is
real; what it buys is a behaviour-preserving refactor *proved* byte for byte
rather than argued.

**Why `link/common.js` ends with a newline when the convention forbids it.**
That trailing newline is the blank line that separated `isEmbeddedContext` from
`vsCodeUriFor` in the original file. The slot join supplies one newline; the
file supplies the other. Without it the split is not lossless.

**Why the split was carved by script and asserted lossless.** Retyping 89 lines
into two files is exactly the operation that introduces a byte nobody meant. The
extraction asserts
`'\n'.join(lines[0:66]) + '\n' + '\n'.join(lines[66:]) == original` before
deleting the original.

**Why `{path}` and `{relativePath}` both exist when the contract makes them the
same field.** The prompt defined `{relativePath}` as `path` made relative to
`meta.rootPath`; the contract says `path` is already relative to it, so that
derivation is a no-op. Rather than ship one token twice, `{path}` is the
payload's own bytes and `{relativePath}` is the URL-shaped form. The fixtures
emit `private\ConvertTo-SampleName.ps1`, and a forge URL needs forward slashes.

**Why the template is not escaped and the token values are.** Different trust.
The template is configuration written by whoever runs the render and must keep
its `://`, `?` and `&` to be a URL. A node's label and path come from a producer
and are never trusted. What makes it safe rather than merely escaped is one
layer down: the result is assigned to an anchor's `href` **property**, never
interpolated into markup, so there is no attribute for a quote to escape from.

**Rejected: exposing `cy` or the resolvers for the browser probe.** It would have
made the probe trivial. It would also put a global into every shipped report —
and acceptance C would then have caught it, correctly, as a change to the
document. The probe right-clicks like a person instead.

**Rejected: listing fragment file paths in `LintJavaScript`.** `FragmentSlots`
is keyed by slot, so a fourth mode's parts arrive checked. A list is a second
place to forget something.

## Measured

Conformance, the 0046-repaired runner, all four tags, measured at base and head
in the same verify run:

```
base: 66.27% over 166 case(s), 110/56
head: 66.27% over 166 case(s), 110/56
no assertion that passed at base fails at head
```

`CasesDefined = 42` at both ends, which independently reproduces the measurement
behind LEDGER backlog 63 — the Pins section still says 41.

Acceptance suite: 21 cases. Red run 5 passed / 16 failed; green run 21 / 0. The
five green in the red run are acceptance C, which is the control and is required
green at both ends.

Full default build: 143 passed, 0 failed, 9 not run. `PreTag`: 9 passed.
`TestBrowser`: 6 pages alive across 2 backends and 3 fixtures. `TestLinkMode`: 5
cases. `LintJavaScript`: 24 scripts, 7 of them as declared fragments.

Resolved links, read off the DOM in Chromium:

```
editor        vscode://file/C:/fixtures/LinkMode/src/Public/Get-Thing.ps1:12:1
hrefTemplate  https://example.invalid/src/Public/Get-Thing.ps1
none          (no link action)
```

The committed forge example, verified the same way:
`https://github.com/JerryBalmer1/PSGraphRender/blob/main/src/PSGraphRender/Private/Contract/Test-RenderViewModel.ps1#L1`

44 files changed, 4,675 insertions, 125 deletions. Tag `v0.14.0` on `3f2ec85`,
which is the tip.

## Learned

**A falsification probe disproved a claim this pass had written down, twice.**
P1b asserted that flipping the shipped default would slip past the byte
comparison, "because the mode is one value in one blob" — and the same sentence
was sitting in a test comment. It is true of a runtime design and false of the
one that was built: assembly picks the *files*, so a flipped default moves the
document body too. Both were corrected to say what is true. This is the second
pass running where the probe found the mistake in the *record* rather than in
the code, which is an argument for probes that assert the division of labour
between checks and not only that each check works.

**The browser gate caught the one defect that would have mattered.**
`{relativePath}` first rendered as `src%2FPublic%2FGet-Thing.ps1`.
`encodeURIComponent` over a whole path escapes its separators — right for a
query value, useless for a `/blob/main/{relativePath}` URL, which is the single
use case the feature was built for. Every PowerShell-side assertion was green at
that moment: the template was in CONFIG, the resolver had shipped, four tokens
resolved. Only resolving a link in a browser said the number was wrong. A string
in a document is not a link.

**Adding a mechanism opens holes in the gates that already exist, and they do
not announce themselves as related.** Three fell out of one change:
`node --check` rejecting seven fragment files, `Module.Quality` walking only
`Slots` so two of three modes would have shipped unasserted, and the vocabulary
check flagging a Verb-Noun name in one of my own comments. All three were right.
The second is the one worth remembering, because it fails *silently* — a file
nothing asserts is indistinguishable from a file that passed.

**A duplicate key in a PowerShell data file is a parse error, not an override,
and it fails misleadingly.** The test helper appended settings, which worked
until `LinkMode` shipped and the appended key collided. `Import-PowerShellDataFile`
then refuses the whole file, `Resolve-RenderConfiguration` warns and falls back
to schema defaults, and every case renders the *default* mode — so the suite
reported the feature missing at the exact moment it started working. The warning
was on screen the whole time and read like noise.

**Verifiers fail in ways that look like the thing they verify.** Three defects
in `verify.ps1`, each producing a plausible wrong story: `line counts differ:
base 3174, head 3174` (a line-ending difference, since `ConvertTo-Json` emits
CRLF while `.gitattributes` stores LF); a `ValidateSet` rejecting
`"Universal,Repository,HouseStyle,RequiresBuild"` against a set that is
literally a comma-join of it (`pwsh -File` passes every argument as one string);
and StrictMode refusing `.Count` on an empty array returned from a function. The
first two each cost a diagnosis aimed at the wrong layer.

**A verifier that clones `main` cannot verify a pass before `main` lands it.**
Task 6 wants the falsification before the release commit; task 8 fast-forwards
`main` after. `-HeadRef` resolves it, and the script now refuses to run when
head and base are the same commit — six green checks over an unchanged tree is
the most confident wrong answer it could give.

**What went wrong that was mine.** I wrote the byte-comparison claim into a test
comment and into a probe without checking it against the architecture I had just
chosen, and it took the probe to catch it. I also drafted `verify.ps1` with
`-BaseRef` defaulting to the `v0.13.0` tag out of habit, in a pass whose prompt
amended that exact baseline in two places and explained why — the tag is eight
commits behind the base and its tree predates the examples this pass had to
regenerate. Both were caught here, neither by me reading carefully the first
time.

**A near miss worth recording.** Section 0's `PSModuleGraph` stop did not fire,
but a `PSModuleGraph` directory does exist one level above both repositories, in
`scratch/`. Out of scope by the rule as written, and reported rather than
skipped, because "absent" and "present but out of scope" are different facts.

## Capability

The renderer can now be told **where a node lives** rather than assuming the
reader has a clone. A report attached to a pull request can point at the forge;
a report leaving the building can point nowhere at all; a report built by
someone reading the code still opens their editor. Which of those it is, is one
line of data.

The specific thing that is now possible and was not: **a committed report can
carry working links.** Every previous link example shipped inert, because the
only available scheme needed an absolute path and an absolute path in a
committed artifact names the machine that made it. `hrefTemplate` never reads
`meta.rootPath`, so `examples/links/forge-links.html` has live links and the
placeholder that keeps a machine path out of the repository stays exactly where
pass 0043 put it. That example is the report 0043 wanted and had to stop short
of.

Newly possible in the assembly itself: **a setting can decide which files a
document is built from.** `SlotsBySetting` is not link-specific — any backend
can declare that a slot's contents depend on a setting's value, and a backend
that declares none is unaffected. That is the seam item 2's template set
consumes, and it arrives with a fragment-aware linter and a manifest-walking
ship assertion already covering it.

And the harness can now check what a report *does*, not only what it says.
`tests/browser/link-mode.cjs` drives the real UI — right-clicks a node, reads
the href off the anchor the registry built — without the page cooperating.
Anything a future mode claims about a link is checkable the same way.
