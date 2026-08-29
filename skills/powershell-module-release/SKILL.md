---
name: powershell-module-release
description: Version and release a PowerShell module — semver rules for a module surface, release notes aggregated by change type, changelog conventions, where notes live in-repo, and what a release checklist actually verifies. Use when cutting a version, writing release notes, or deciding whether a change is major, minor, or patch.
---

# Release

## Semver, applied to a module surface

The public surface is `FunctionsToExport` plus every parameter, parameter set,
and emitted property those commands expose. Semver is decided against that
surface, not against how large the diff was.

| Bump | When | Examples |
|---|---|---|
| **major** | an existing caller breaks | a command or parameter removed or renamed; a parameter becomes mandatory; a returned property removed or retyped; a default that changes results; the minimum `PowerShellVersion` rises |
| **minor** | new surface, nothing breaks | a new command; a new optional parameter; a new property on a returned object; a new parameter set |
| **patch** | no surface change | a fix that makes a command return what it already documented; performance; internal refactoring; documentation |

Two rules that decide most arguments:

- **A bug fix that changes a documented result is minor at least.** "It was
  wrong" does not make the correction invisible to a caller who worked around
  it. If the workaround now breaks, it is major.
- **Adding a property to an emitted object is minor, not patch.** Callers
  round-trip these objects, compare them, and serialise them, and run 002's
  functional comparator fails on a single extra field. `additionalProperties`
  being false somewhere downstream is not hypothetical.

Below `1.0.0`, apply the same table with the same discipline rather than treating
`0.x` as licence to break things silently. Say in the README that the surface is
not yet stable, and still bump the minor for a break.

## Release notes, aggregated by change type

Notes are written **from the repository, not from memory** — the same rule as a
journal entry. Group by what a reader needs to decide, which is whether this
release will break them:

```markdown
## [0.2.0] - 2026-08-29

### Breaking
- `Get-AzDoPipelineReference` no longer emits `alias` on `checkout` edges.
  Read `ref` instead. (#41)

### Added
- `Resolve-AzDoPipelineReference` returns `reason` on unresolved references,
  distinguishing `file-not-found` from `alias-not-declared`. (#38)

### Fixed
- Cycle reporting used a breadth-first visited set, so every diamond was
  reported as a cycle. Depth-first colouring reports only real ones. The graph
  itself was never wrong; only the report was. (#44)

### Known limits
- Paging is implemented and has never executed: no fixture response has
  carried a continuation token.
```

**Breaking first, always**, even when it is one line under three headings of
additions. A reader scanning for whether to upgrade is reading for that.

**A "Known limits" section is not optional in this project.** A release with no
recorded limits reads as untested, and experienced readers assume the limits were
hidden rather than absent. Name what is implemented but unexercised, what is
covered by one target only, and what was a deliberate decision rather than an
oversight.

**Every entry says what a reader can do**, not what the author changed. "Fixed
cycle detection" is not an entry. The example above names the wrong behaviour,
the right one, and — in the third case — explicitly bounds the blast radius.

## Where notes live

- **`CHANGELOG.md` at the root**, Keep a Changelog headings, newest first, with
  an `[Unreleased]` section that entries are added to *as work happens*. Writing
  the changelog at tag time is writing it from memory.
- **`PrivateData.PSData.ReleaseNotes` in the manifest** carries the current
  version's section, because that is what the gallery shows. Generate it from
  the changelog rather than maintaining a second copy — two texts that must agree
  and are edited in different files will drift silently.
- **A worklog per tag**, at `docs/worklog/v<version>.md`: the thoughts,
  considerations, and decisions made while doing the work, committed with the
  work. The changelog says what changed; the worklog says why, and it is the
  thing nobody can reconstruct later. This is required for every tagged plan on
  the target repository — see `decisions/0006-target-versioning-and-tags.md`.

## What a release checklist verifies

Mechanical checks first, because they are the ones that have actually failed.

- [ ] **`ModuleVersion` equals the version about to be tagged**, and that tag
      does not exist yet. This is not paranoia: a manifest reporting `0.15.0`
      shipped as `v0.15.1` and `v0.15.2`, twice, because nothing read the field.
- [ ] **The previous tag reached the remote**, at the commit it names locally,
      **on a branch that contains it**. Two tags were cut, a push was authorised
      for each, and neither arrived; nothing noticed for three iterations. A gate
      cannot verify a push that has not happened yet, but it can verify the last
      one — one iteration late beats three.
- [ ] This check **makes a network call and fails when it cannot**. It does not
      skip when offline. Remote-tracking refs answer from the last fetch, which
      is a cache, and a cache would have passed on all three of the iterations
      this was built to catch.
- [ ] Assert the **commit**, not merely the ref. A ref cannot exist on a remote
      without its whole ancestry, so a matching commit proves the history
      transferred. And assert the **branch** too: `git push origin <tag>`
      publishes the tag and leaves the branch behind, and anyone cloning the
      default branch then gets none of the sealed work while every other
      assertion stays green.
- [ ] `CHANGELOG.md` has a heading for this version, dated, with `[Unreleased]`
      emptied into it.
- [ ] `docs/worklog/v<version>.md` exists and is committed **with** the work.
- [ ] The full build is green and the `PreTag` gates pass —
      `./build.ps1 -Task PreTag`, which the default `Test` task excludes.
- [ ] The tag is **annotated**, and its message carries the scores.

## Cutting it

```powershell
./build.ps1                       # Clean, Lint, Build, Test
./build.ps1 -Task PreTag          # the seals on a finished iteration
git tag -a v0.2.0 -m "Plan 0018 — build exit 0, conformance 57/57, functional 12/12"
```

Annotated (`-a`), never lightweight: a lightweight tag carries no author, no
date, and no message, and `git ls-remote` cannot distinguish one from a branch
ref in a way a gate can assert on. An annotated tag answers twice — the tag
object, and `^{}` for the commit it peels to — and that second answer is what
makes the remote check above possible.

Pushing the tag is the **operator's**, from their own shell, except where a pass
prompt names the version under `decisions/0006`.

## Related

- `powershell-module-test` — the `PreTag` tests these gates are made of.
- `powershell-module-deploy` — staging, and why the agent never publishes.
- `powershell-module-docs` — the changelog's relationship to the README.
