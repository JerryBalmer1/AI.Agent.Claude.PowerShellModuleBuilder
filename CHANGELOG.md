# Changelog

What changed for you, the person installing this. Written for someone who has
not read the repository. The pass-by-pass record lives in
[`journal/`](journal/) and the reasoning in [`decisions/`](decisions/); this
file is not a summary of either.

Versions follow [semantic versioning](https://semver.org/) as described in
[Versioning](README.md#versioning) — MAJOR when something you rely on breaks,
MINOR when capability is added, PATCH for corrections.

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
