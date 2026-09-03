# Changelog

What changed for you, the person installing this. Written for someone who has
not read the repository. The pass-by-pass record lives in
[`journal/`](journal/) and the reasoning in [`decisions/`](decisions/); this
file is not a summary of either.

Versions follow [semantic versioning](https://semver.org/) as described in
[Versioning](README.md#versioning) — MAJOR when something you rely on breaks,
MINOR when capability is added, PATCH for corrections.

## 1.2.0 — 2026-09-02

**MINOR: capability is added and nothing you rely on breaks.** Two new skills,
five amended, a new block of help conformance assertions, and an optional
settings file. No skill was removed or renamed, no command's contract changed,
and no convention the conformance suite enforces was reversed.
`git diff v1.1.1..v1.2.0 -- commands/` is empty.

### Two new skills — nineteen now, from seventeen

**`powershell-module-ux`** is about argument completion, and mostly about when
*not* to add it. Three conditions a parameter has to meet before a completer
earns its place; `[ValidateSet()]` versus `[ArgumentCompleter()]` versus a class
implementing `IArgumentCompleter`, with a worked example of each; a ~200ms cost
threshold for reaching for a session cache; and six guardrails on that cache
stated as rules rather than advice. The third of them is absolute: **a completer
never caches a secret, a credential, a token, or anything derived from one** —
not in a variable, not on disk, not for the length of one session. It also says
that a completer without a test does not ship, and shows the test, because
completion is invisible to every other gate here.

Every code example on that page was run before it was written down. The
techniques are distilled from three [powershell.one](https://powershell.one)
articles, each linked and each actually read; nothing is reproduced, and the one
place the skill contradicts its source is marked as a deliberate departure.

**`powershell-module-tidy`** is the pre-release sweep, as one verb. Naming and
layout conformance, public surface versus documentation parity **in both
directions** — the second direction, a README naming a command that does not
exist, is the one hand-rolled versions leave out and the one that produces a bug
report — dead-file detection, a `docs/PLAN.md` currency check that blocks a
release when the plan has gone stale, and a final conformance run that refuses
to bless while any Bucket-A item is open. It changes nothing; there is no `-Fix`
switch, on purpose.

### Five skills amended

- **`powershell-module-analyzer`** gains the class-candidate rule: the same key
  set emitted as `PSCustomObject` from three or more sites is surfaced *with its
  four costs attached* — reload behaviour, `using module`, serialization
  fidelity, mockability — and never applied for you. The counterexample ships
  with it, because repeated shape is evidence of a schema at least as often as
  it is evidence of a missing class.
- **`powershell-module-architect`** gains the enumerator rule: every public
  output type gets a no-argument `Get-<Noun>`. Singletons, contexts and computed
  aggregates are the exception, declared in one line where the type is.
- **`powershell-module-docs`** gains the house `.EXAMPLE` standard — parameters
  at the top with aligned `=`, splatted through a `$params` hashtable,
  `try`/`catch` with a real message, the result displayed, so an example can be
  copied and edited rather than retyped. Full help is now the standard for
  private functions as well as public, with `HelpMessage` on mandatory
  parameters. And it says plainly that **PowerShell classes and enums support no
  comment-based help at all** — a full help block above a class produces zero
  `Get-Help` matches — so the standard asserts the checkable equivalent and says
  out loud that it is an equivalent.
- **`powershell-module-plan`** gains the master-plan obligation: every module
  carries `docs/PLAN.md`, in plain language, written for a reader who will never
  open the machinery, updated when a plan is added or a release is cut.
- **`powershell-module-build`** documents the settings file below, including a
  table of what each switch invalidates when it is flipped.

### Help conformance — and a denominator that moved

Eight new assertions in `evals/conformance/Help.Tests.ps1`, all tagged
`HouseStyle`: help on every function public and private, `.PARAMETER` per
declared parameter, examples counted against parameter sets with each named set
demonstrated, a doc block before every class and enum, and an `about_` topic
when a module ships types.

**`cases-defined` moves from 33 to 41, and that is a boundary rather than an
improvement.** Scores taken before this tag and after it are separate series and
are not compared. Nothing earlier is restated or re-derived — the ladder's
numbers stand exactly as measured, on the 33-case series, and the README says so
above the table they are in. If a boundary were used to retire inconvenient
figures it would be worse than no boundary at all.

For what the new series looks like on a commit that predates it: run 006's final
scores **38 / 41**, with three failures declared Bucket B and none fixed. The
sort is worth reading — all twelve `at least one example` failures are exactly
the twelve *private* functions, because the module was built to a docs skill that
required help on the exported surface and said nothing about the rest.

### An optional `psmodule.settings.psd1`

Three enumerated keys at your repository root — `CoverageThreshold`,
`ModuleProfile`, `CompletionCacheDefault` — resolved explicit parameter > file >
built-in default. **An unknown key is a refusal that names it**, not a warning:
`CoverageThresold = 90` would otherwise grade at 75 while the file on disk says
90, with nothing in the output to disagree. A near-miss value is refused on the
same terms rather than coerced.

**The defaults are the measured configuration**, so a repository that ships no
settings file is graded exactly the way every published run here was graded, and
needs no decision from you. The values and where each came from are echoed into
every score record.

### One thing that was wrong and is now a hard stop

While the second suite container was being added, it lost its discovery to a
member access on an empty array — and **every one of its assertions vanished
from the run while the score printed as entirely normal.** `cases-defined` is
parsed from the suite's source and does not know a file failed to load, so the
numerator and denominator shrank together. Pester reported `Container failed: 1`
and nothing downstream read it.

The runner now refuses to report a score at all when a container did not run,
and writes no result file. Not run is not a pass.

## 1.1.1 — 2026-09-02

**Nothing you install changes.** `skills/` and `commands/` are byte-identical to
1.1.0 — the same seventeen skills, the same two commands, the same conventions.
`git diff v1.1.0..v1.1.1 -- skills/ commands/` is empty. Only the manifest
version moves. Upgrade freely, or don't; the plugin behaves the same either way.

What changed is what this repository **claims**, and the claim it can now make
is one it could not make before.

### The Terraform skills have now been measured

1.1.0 shipped three `tf-*` skills and said, in this file, that they were
**unmeasured** — that no run had scored a Terraform build with them readable.
That was true then. A blind run has since been taken.

[**tf-003**](runs/tf-003-generalisation/) built a Terraform producer from a
four-file seed and a brief, with the plugin readable, against a **second
Terraform fixture and an oracle the session did not open until its module was
built and pushed**. It came back **6 / 7 on the named cases at first shot** with
node and edge counts exact, and **7 / 7 after one of three permitted
iterations**. All 184 first-shot differences were four naming conventions;
**not one was structural**. Every mechanism the first Terraform run lost a wave
of edges to was read correctly the first time.

### And here is what that does not mean

**It is not evidence that the plugin generalises**, and the reason is in the
plugin rather than in the run. Those three `tf-*` skills were written *from* the
earlier Terraform runs and cite their findings by mechanism and by count. So the
fixture was unseen and **the catalogue of mistakes was not**.

What the run supports is narrower and still useful to you: **a plugin carrying a
domain's recorded findings stops those findings recurring on a fixture in that
domain it has never seen.** If you are adopting this method for your own domain,
that is the effect you can expect from writing your findings down — and it is
not the same as "the agent got better at the domain".

Settling the bigger question needs a third domain the skills say nothing about,
or the same run again with the plugin unread. Neither has been done, and the
[README](README.md#tf-003--the-blind-run-and-exactly-what-it-licenses) now says
so in the same paragraph as the result rather than in a footnote.

### One correction, in the harness rather than in the plugin

The document describing the second fixture's cases contained a false sentence:
it called the unused variable *"the only node in the fixture with neither"* an
incoming nor an outgoing edge, when ten nodes satisfy that literally. It was
caught by scoring the oracle **against itself** — the answer key failing its own
paper — and the scoring instrument is now stricter than the one that produced
the numbers above, which were re-derived under it and did not move. This affects
no installed file. It is here because this project's changelogs say when a
number was wrong, not only when a feature was added.

## 1.1.0 — 2026-09-02

**Three new skills, for Terraform.** The plugin now carries seventeen skills
instead of fourteen. **Your commands are unchanged** — `/psmodule:build` and
`/psmodule:test` do exactly what they did in 1.0.1, and nothing that worked
before behaves differently. This is additive; upgrade whenever suits you.

### What is new

If you are building a PowerShell module that reads Terraform configuration, the
agent now has three skills it did not have:

- **`tf-hcl-parse`** — reading `.tf` files as blocks rather than with a regex
  over the whole file, and the four constructs that defeat one (a brace inside a
  string, a `#` inside a string, a heredoc, a block comment). Also:
  `required_providers` is legal both as a block *and* as an attribute, and a
  reader that handles one finds **no providers at all** in a file written the
  other way, with no error.
- **`tf-module-resolve`** — what a module `source` actually points at. A
  registry address `namespace/name/provider` and a relative path
  `./modules/child` are the same shape to a naive pattern, and the guard is the
  leading `./` or `../` and nothing else. Also: the `//` that separates a
  repository from a subdirectory has to be searched for *past* the scheme's own
  `//`, and a `git::` source with no `//` names the repository's **root**
  module.
- **`tf-graph-assembly`** — ids that carry their repository so two producers'
  output can be merged, containment taken from the directory tree rather than
  from the module calls (**a module's parent is not its caller**), and
  deduplicating a value that a single expression happens to mention twice.

Every line in all three is grounded in a specific failure from a recorded run,
not in what Terraform tooling might plausibly need.

### Two hardening lines in skills you already have

- **`azdo-rest`** now says that a REST response *omits* properties it has
  nothing to say about rather than setting them to `$null`, so under
  `Set-StrictMode -Version Latest` reading one throws — per object, in a
  pipeline, which quietly returns a shorter list that looks like a complete one.
  It cost a real run an entire repository. The regression test has to mock the
  failure by **omitting** the property; an object with the property set to
  `$null` does not reproduce it.
- **`powershell-module-scaffold`** now says that a command taking a `-Path` must
  test `IsPathRooted` before `Join-Path`, and must resolve against
  `(Get-Location).ProviderPath` rather than the process working directory, which
  PowerShell does not keep in step with `Set-Location`.

### What this release does not claim

**The three Terraform skills are unmeasured.** Every number in this
repository's [with/without table](README.md#with-the-plugin-and-without-it)
comes from the Azure DevOps line; no run has yet scored a Terraform build with
these skills readable against one without. They were withheld from 1.0.x on
purpose, because the only Terraform fixture that existed was the one their
lessons came from, and scoring them against it would have measured memory rather
than generality. A second Terraform fixture now exists that none of them was
written against
([decision 0014](decisions/0014-second-unannotated-fixture.md)), which is what
makes the measurement possible — but it has not been taken.

So: three skills that encode hard-won, specific knowledge, and no evidence yet
about how much they help. If that distinction matters to you, it is the same
one [Status, honestly](README.md#status-honestly) makes about everything else
here.

## 1.0.1 — 2026-09-02

**Nothing you install changes.** `skills/` and `commands/` are byte-identical to
1.0.0 — the same fourteen skills, the same two commands, the same conventions.
Only the manifest version moves. Upgrade freely, or don't; the plugin behaves
the same either way.

What changed is what this repository **claims** about the plugin, and one thing
was overstated.

### The measured claim is corrected, and it moved down

1.0.0 shipped with one plugin-off baseline that had never been allowed to fix
its own mistakes. A control run has since been done properly — plugin unread,
same seed and brief, and the same three-iteration budget the plugin-on runs
had. It reached the functional oracle exactly, 12 / 12, in one iteration.

So: **all four runs that were permitted to iterate reached 12 / 12, and the
control's first shot was the closest of them.** The plugin's effect on
correctness, on this fixture, is not measurable. What it does supply, large and
repeatably, is first-shot conformance to house style — 33 / 33 against the
control's 19 / 33, about fourteen assertions that are not derivable from the
brief and that the control needed two extra iterations to recover most of.

**The plugin buys shape, not correctness.** If you installed 1.0.0 expecting it
to make the agent write correct code first time, the README now says plainly
that it will not, and that a single control cannot say whether the conventions
are the hard part or the traversal was never hard for this model. The
[with/without table](README.md#with-the-plugin-and-without-it) is rewritten
around that, with every caveat attached to the number it qualifies.

### The conformance score was measured wrongly for one run, and is fixed

Four of the 33 conformance assertions grade the module's **build output**, which
is gitignored. The scoring procedure said "score from a fresh clone" and never
said to build it, so one run's clone was never built and those four assertions
graded a missing directory: 28 / 33 reported where the same commit scores
32 / 33 when built first.

The procedure is corrected, not the suite — **no assertion was added, removed,
weakened or edited.** The clone is now built before it is scored, by one script
(`evals/conformance/Score-Clone.ps1`) rather than by four runs each improvising
it. Both affected runs were re-scored under the corrected procedure and the
repair was falsified three ways first, including the control that an unbuilt
clone must *still* fail those four.

This matters to you only if you run the conformance suite against your own
module: **build it before you score it, or six assertions grade nothing.**

### Two limits on the measurements are now disclosed

Neither is new. Both had always been true and neither had been written down.

- **A measured run's own prompt is inside its own read-allowlist.** Two runs'
  prompts named the earlier runs' mistakes to the builder before it wrote a
  line. Both runs flagged it themselves; both records say the affected numbers
  are weakened.
- **The test fixture names its own cases in comments,** and reading the fixture
  is the task, so every run has read them. The fixture is frozen, so this is
  permanent: "blind", in this project, means the oracle and the plugin were
  unread. It has never meant the fixture was unread.

Both are now hazards in the harness specification, and every affected run record
carries a `## Blindness caveats` section saying which apply to it.

### Nothing else moved

No skill text, no command text, no conformance assertion, no fixture. The
[known limits](#known-limits-stated-up-front) listed under 1.0.0 all still
stand, including that nobody has yet installed this cold on a machine that has
never cloned the repository.

---

## 1.0.0 — 2026-09-02

The first release anyone else can install. Everything below already existed;
what is new is that it is packaged, versioned, licensed and pinned to a tag.

### What you get

**Two commands.** `/psmodule:build` and `/psmodule:test`.

**Fourteen skills** that Claude Code loads when the work matches them. Nine are
about building a PowerShell module to a fixed set of conventions — planning,
command-surface design, project layout, the InvokeBuild build file, the Pester
suite and its ordered five-layer runner, AST-driven analysis, comment-based help
and `about_` topics, staging for delivery, and semver against a module surface.
Three are about reading Azure DevOps: the REST API read-only, extracting
pipeline YAML references, and assembling those references into a graph. One is
about emitting against a schema another repository owns. One formats responses
during multi-skill work.

**Conventions that are graded, not suggested.** The point of the plugin is a
module that comes out the same shape every time: a manifest with explicit
exports and no wildcards, `Public/` flat and one function per file, `Private/`
nested by concern, a committed dev loader, `ParseError` in the analyzer severity
list, a coverage gate, and exit codes that mean what they say. A conformance
suite in this repository grades all of it, and you can run it against your own
module.

### What it does for you, measured

Three consecutive blind runs, same seed and brief and fixture, each scored from
a fresh clone, against one baseline run with the plugin unread:

- **Project shape: 19 / 33 → 33 / 33.** Repeatable, first shot, three times.
  This is the part that works.
- **Behaviour, first attempt: 0 / 12 → 1 / 12.** Nearly flat. The plugin moved
  the functional score by one case out of twelve. If you install this expecting
  it to make the agent write correct Azure DevOps traversal code first time, it
  will not.

The full table, and what is wrong with it, is in the
[README](README.md#with-the-plugin-and-without-it). The honest summary: the
baseline was a single run that was never permitted to iterate, so nobody knows
what it would have reached given the same budget, and this release does not
claim to know.

### Before you install

- Run `tools/publish/Test-Prerequisites.ps1` first. It checks the five things
  that make a first run fail confusingly and names each one with the exact
  command to fix it.
- Requires PowerShell **7.2 or later**, Pester, InvokeBuild and git.
  `$env:AZDO_PAT` is needed only for the Azure DevOps skills.

### Known limits, stated up front

- **Nobody has installed this cold.** There is no transcript of a stranger
  adding the marketplace on a clean machine. It is the next thing to prove.
- **`azdo-graph-assembly` states the repository-node rule too narrowly.** Every
  run that follows it exactly emits one node too few. Known, reproduced three
  times, unfixed in this release.
- **`powershell-module-build` carries a known defect** in the same way. Both are
  labelled in the README's skill table so you can see which advice is suspect.
- **The conformance suite's `Universal` set passes seven of nine** targets it
  has been run against, not nine of nine.
- **Which skills carry the improvement is unmeasured.** Installing all fourteen
  is the only configuration anyone has scored.

### Security and licence

MIT. See [SECURITY.md](SECURITY.md) for what the plugin touches — the short
version is one credential, `$env:AZDO_PAT`, never as a parameter or a file; no
network beyond the Azure DevOps REST API; no telemetry; and it never queues a
pipeline or writes anything to Azure DevOps.

---

## Before 1.0.0

The plugin was developed in the open across thirty-one numbered passes and four
scored runs, at manifest version 0.1.0, with no marketplace file and no tags. It
was not installable by anyone else and there is no consumer-facing history to
report for that period. [`journal/`](journal/) has the pass-by-pass record if
you want it.
