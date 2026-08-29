---
decision: 0001
title: Universal is a claim about modules; Repository is a claim about repositories
date: 2026-08-28
status: accepted, provisional on the control passing
passes: 0007, 0008
artifacts:
  - evals/conformance/baseline/UNIVERSAL-CORPUS.md
  - evals/conformance/baseline/known-failures.json
  - evals/conformance/README.md
---

# Universal, split and validated against a corpus

## Context

`Universal` was defined as "true of any well-formed PowerShell module
repository" and had been validated against exactly one repository — the one it
was written alongside. The README said so, and called the tag an intention
rather than a fact, but the score it produced was reported as though it measured
something general.

Two things forced the question. Every assertion in the suite had by then been
falsified against that one repository, so the remaining doubt was not "does this
assertion work" but "is this assertion about anything beyond PSModuleGraph". And
the repository already carried a reproducible eight-module gallery corpus with a
SHA-256 lock, built for a different purpose, that could answer it.

## Decision

**Split the tag.** `Universal` means true of any PowerShell module, source tree
or published package. `Repository` means true of any module repository, and
needs a source tree: a build entrypoint, analyzer settings, a tests directory,
tests that invoke the exported commands. `HouseStyle` and `RequiresBuild` are
unchanged.

The split was made on evidence, not taste. A published package has no build
file and no tests. Failing it for their absence says nothing about the module,
and a tag that does so is not measuring what its name claims.

**Validate against the corpus, and state the count.** The README now carries the
per-assertion survives-N-targets table rather than a general claim. Seven of the
nine `Universal` assertions survive all nine targets tried. That number is the
tag's confidence level and is expected to be quoted rather than summarised.

## What the corpus showed

The first corpus run could not measure anything: all eight modules failed at
discovery, because the suite required a manifest's directory to be named for the
module, and a published package is `<name>/<version>/<name>.psd1`. Worse than
failing — on SqlServerDsc, which ships 51 manifests, the suite found a bundled
helper module whose layout did fit, graded that, and reported 81.82% with
nothing in the output to indicate it had graded the wrong thing.

With that fixed, seven distinct defects in the suite surfaced (A-C1 to A-C7 in
UNIVERSAL-CORPUS.md), of which the load-bearing ones were: the definition scan
read only `.ps1` and so could not see any module defining its exports in a
`.psm1`; scope-qualified definitions (`function Global:Write-VcsStatus`) never
matched their exported name; and the comment-based-help assertion enumerated a
`Public/` directory that six of the eight modules do not have, producing zero
cases and reading as part of a green run.

That last one is the most instructive. The assertion was not wrong and was not
failing. It was inapplicable, silently, and inapplicability was indistinguishable
from success. Standing rule 9 — *zero cases is not a pass* — comes directly from
it, as does `CasesRun` in `result.json`.

Six Bucket B findings remain, unfixed by design, declared in
`known-failures.json`.

## What was rejected

**Deleting the `CompatiblePSEditions` assertion outright.** Six of eight modules
omit the key, including the corpus control and Pester; it is optional in the
manifest schema; and asserting it as universal was, in the operator's words, a
preference wearing a fact's clothes. Deletion was rejected anyway. It is a
defensible house convention, and the honest response to "this is not universal"
is to move it to the tag that says whose preference it is, not to discard the
preference. It is now `HouseStyle`, with a `ContainsKey` guard so an absent key
fails cleanly instead of throwing under StrictMode.

**Splitting `exports functions by explicit name, never by wildcard` into two
assertions.** The `It` carried two claims: no wildcard, and at least one
exported function. Az is a rollup with no code; Az.Accounts exports cmdlets
implemented in C#. Both legitimately export zero functions. The proposal was to
split, keeping the count clause under a narrower tag. Rejected: the count clause
is not true under any tag the suite has. It was deleted. There is nothing to
split when one of the two claims is simply wrong.

**Decoupling the three assertions that `FunctionsToExport = '*'` turns red.**
A wildcard export genuinely violates all three, and each is independently worth
asserting. Special-casing `'*'` in two places to produce a tidier failure list
buys a nicer report and costs suite complexity. Recorded as expected coupling
instead.

**Fixing the corpus modules, or writing tests for the reference.** Out of scope
by standing constraint, and the constraint is right: a suite that edits its
targets to make them pass is not measuring them.

## What remains provisional

**The control does not pass.** posh-git, the corpus's designated control, fails
comment-based help on five exported commands. Those failures are genuine — the
module documents 20 functions and leaves five exported ones undocumented — and
every *suite* defect the control exposed has been fixed. But the standing gate
is that the control passes clean, and until it does, `Universal` is better
evidenced than it was and is not signed off.

**Nine targets is not many, and they are not independent.** All eight corpus
modules come from one gallery and were selected to stress a dependency graph
tool, not a conformance suite. They are dissimilar to each other, which is what
was needed, but they are not a sample of anything.

**`Repository` and `HouseStyle` have been validated against one repository.**
The split moved the unvalidated claims out of `Universal`; it did not validate
them. Everything the old README said about `Universal` being an intention now
applies to `Repository`, and should be read that way until a second repository
passes it.

**AST assertions check assignment, not behaviour.** The build-file block no
longer confuses a comment for code in either direction. It still checks that
`CodeCoverage.Path` is assigned something ending in `psm1`, which is not proof
that coverage was measured against the built module.
