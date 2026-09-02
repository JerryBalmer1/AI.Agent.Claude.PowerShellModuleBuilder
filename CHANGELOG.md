# Changelog

What changed for you, the person installing this. Written for someone who has
not read the repository. The pass-by-pass record lives in
[`journal/`](journal/) and the reasoning in [`decisions/`](decisions/); this
file is not a summary of either.

Versions follow [semantic versioning](https://semver.org/) as described in
[Versioning](README.md#versioning) — MAJOR when something you rely on breaks,
MINOR when capability is added, PATCH for corrections.

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
