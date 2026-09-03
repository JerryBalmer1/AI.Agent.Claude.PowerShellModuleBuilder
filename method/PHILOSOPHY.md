# PHILOSOPHY — the why under the method

Version 1. This file explains the method; it never overrides it. A law is
cited in a prompt only when it decides something.

## The goal

Verifiable delegation: work you can hand off — to an AI, to a future you, to
a stranger — and still trust, because trust here is never requested, it is
re-derivable. Every claim checkable by anyone with a clone and a shell; the
method itself packaged, versioned, and clonable. The module is the proof,
the plugin is the product, the method is the point.

## The laws, and where they already live

**Law 1 — Order is discovered, not imposed.** Dependency exists before you
diagram it; read it, then honor it. Lives in: [the ordered test
runner](../skills/powershell-module-test/scripts/Invoke-OrderedTests.ps1),
[the diagram's layers](../docs/diagram/README.md), [the pass
sequence](../PLAN-PROTOCOL.md) (definition of done before anything).

**Law 2 — A yes means nothing until it can be a no.** Any check that cannot
fail is decoration. Lives in: [red-first](../PLAN-PROTOCOL.md), [the
falsification rows](../evals/conformance/baseline/FALSIFICATION.md), every
[`-FailCheck` probe](../docs/testing/README.md), [the coverage gate that
could not fail](../docs/creating-an-agent/07-failure-catalog.md) and fooled
every run until it was broken on purpose — and the link checker that
silently examined three fewer links until an assertion on the count was
named as its fix ([LEDGER 58](../LEDGER.md)).

**Law 3 — The refusal is the third value.** Beyond yes and no there is
decline: "this question is malformed as asked." Systems without it are
obedient; systems with it are trustworthy. Lives in: [the session
gates](../docs/creating-an-agent/04-fresh-sessions-and-contamination.md),
[the truncation stops](../docs/ux/UX-002-ends-with-tripwire.md),
[PLAN-PROTOCOL's defect-in-the-prompt rule](../PLAN-PROTOCOL.md) — the
most-trusted runs in this record are the ones that refused.

**Law 4 — Print the dark number next to the light one.** Credibility
compounds from confession, not polish. Lives in: [run 007 halving the
headline](../runs/007-baseline-iterated/README.md) and the README getting
stronger; every [Bucket-B
declaration](../decisions/0001-universal-validated-against-corpus.md); [the
failure catalog](../docs/creating-an-agent/07-failure-catalog.md) including
the director's own.

**Law 5 — Never trust the report; read the remotes.** About agents, tools,
claims, and the claimant. Lives in: [the verify scripts](../plans/README.md),
[the calling-bullshit
chapter](../docs/creating-an-agent/05-calling-bullshit-verification.md), [the
operator's audit loop](../docs/creating-an-agent/01-the-two-claudes.md) — and
the recovery that found a precondition passing against a working tree while
`git show HEAD:` told the truth.

**Meta-law:** reality is the oracle; everything else is a claim awaiting its
diff.

## What this is not

A metaphysics. These laws say how to know and how to build; they do not say
why there is something rather than nothing, and any framework claiming to
derive that from a pattern is selling. Adjacent rabbit holes are declined by
name: numerology (3-6-9 and kin) — the instinct that shapes recur at every
scale is real, and its rigorous homes are order theory and the Theory of
Constraints, Popper's falsifiability, Stoic assent and three-valued logic,
Jung's integration read as engineering, Tetlock's calibration, and complexity
science. Follow the instinct there. And no Grand Unified Framework: five laws
that each survived contact with reality beat one theory of everything that
has not met it.
