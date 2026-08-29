---
decision: 0002
title: exports no cmdlets, variables, or aliases implicitly stays Universal
date: 2026-08-28
status: accepted
passes: 0008, 0009
artifacts:
  - evals/conformance/baseline/UNIVERSAL-CORPUS.md
  - evals/conformance/baseline/known-failures.json
---

# `exports no cmdlets, variables, or aliases implicitly` stays in Universal

## Context

The assertion requires a manifest to state `CmdletsToExport`,
`VariablesToExport` and `AliasesToExport` explicitly, and to set none of them to
`'*'`.

Four of nine targets pass it. Five fail: Az, Az.Accounts, ImportExcel and
Microsoft.PowerShell.Crescendo omit one or more keys; SqlServerDsc sets one to
`'*'` outright. It is the worst-performing assertion in `Universal` by pass rate,
and the pass immediately before this one flagged it for review on exactly that
basis.

An adjacent assertion, `CompatiblePSEditions`, was moved to `HouseStyle` in Pass
0008 on a similar-looking argument: optional in the schema, omitted by six of
eight corpus modules, therefore not a fact about PowerShell modules.

## Decision

**Keep it in `Universal`. Unchanged, unweakened.**

An unset export key does not mean "export nothing". PowerShell treats an absent
`VariablesToExport` as `'*'`, and the module exports every variable it happens
to define. That has a real cost: command and variable discovery returns things
the author never intended to publish, private helpers leak into the caller's
session, and the module's surface silently grows with its internals. The
assertion is describing a defect, and the modules that fail it have that defect.

## The principle

**Prevalence is not correctness.**

A rule that most targets fail is either wrong, or the targets are. Which one is
decided by evidence about the rule, not by the failure rate. A five-of-nine
failure rate is a reason to *examine* an assertion. It is not, by itself, an
argument against it, and treating it as one converts a conformance suite into a
survey of common practice.

This is what separates this decision from `CompatiblePSEditions`, which looks
identical from the failure rate alone:

- `CompatiblePSEditions` absent has **no consequence**. The manifest is valid,
  the module loads, nothing leaks. Asserting it was a preference about
  documentation. Moved to `HouseStyle`, where preferences are labelled.
- An export key absent has a **mechanical consequence** that the module author
  did not choose. Asserting it is a claim about PowerShell. It stays in
  `Universal`.

The failure rates were comparable. The decisions differ because the evidence
about the rules differs, which is the whole point.

## What was rejected

**Moving it to `HouseStyle`.** This is the option the failure rate suggests and
it is the one that would have been wrong. `HouseStyle` means "this project's
preference"; the wildcard-export behaviour is not this project's opinion, it is
PowerShell's documented default. Filing it there would misdescribe it, and would
quietly withdraw a true claim because it is inconvenient.

**Weakening it to a warning.** Rejected on the standing constraint — no
assertion is weakened because targets fail it — and on a plainer ground: a
warning nobody is required to clear is an assertion that has stopped being one.
The suite already has one recorded case of an assertion that could not fail
being counted as evidence for three passes.

**Splitting it into "must be present" and "must not be `'*'`".** Tempting,
because the two failure modes read differently: four targets omit the key, one
sets it explicitly. Rejected because they are the same defect with the same
consequence, and separating them would produce two assertions that always agree.
The distinction is worth recording — it is B-C1 versus B-C2 in
`known-failures.json` — not worth encoding.

## Consequences

Five of nine targets fail this assertion, permanently, until those modules
change. All five failures are Bucket B and declared in `known-failures.json`
keyed by assertion plus target, so they are separable from anything new.

`Universal`'s headline number — seven of nine assertions surviving all nine
targets — counts this assertion among the two that do not survive. That is the
honest presentation: the assertion is correct and the ecosystem does not meet
it, and the number should not be improved by redefining the assertion.
