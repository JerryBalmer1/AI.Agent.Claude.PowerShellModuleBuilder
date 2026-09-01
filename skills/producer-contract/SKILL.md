---
name: producer-contract
description: Emit data against a schema or contract another repository owns — absent versus false for optional fields, running the consumer's battery inside your own build, and never renaming what the contract names. Use when a module's output is consumed by another module rather than read by a person, when a score against a hand-authored oracle shows the same difference many times, or when deciding whether to write a field you have nothing to say about.
---

# Producing against a contract you do not own

Most module skills assume the output ends in a document or an object for a
person. This one is for the other case: **the output is data, and something else
validates it.** A graph a renderer consumes, a manifest a deployer reads, a
result file a harness scores.

The difference that matters: when a person reads your output, a wrong field is
noticed and worked around. When a machine reads it against a contract, a wrong
field is a failure — or worse, is accepted and means something you did not
intend.

## The rule that costs the most to learn late

**An absent optional field means NOT STATED. Writing `false` is a different
claim, and a louder one.**

A producer emitted `hasValidation: false` for every input that had no validation
rule. The hand-authored oracle omitted the field entirely. Scored against each
other: **28 differences, one per input** — on a producer that was otherwise
right. It reads on a score line like a catastrophe and it is one line of code.

Before writing any optional field, answer: *do I have something to say here?*

- **Yes, and it is a positive fact.** Write it. "This input is required"
  (`hasDefault: false`) is a fact about the configuration; something is true of
  it.
- **No, there is simply nothing.** Omit it. "Nothing validates this" is the
  absence of a fact, and the contract's word for absence is absence.

Those two look identical in code — both are a false boolean — and they are not
the same claim. Expect the line to fall in a place that seems arbitrary, and
expect to have to defend it. The producer above omits `hasValidation` when false
and writes `hasDefault: false`, and that asymmetry is deliberate and written
down in its HANDOFF, because the alternative is that the next person "tidies" it
and moves 28 differences back.

**Read the contract before choosing.** The rule is usually stated once, about
one field, and meant generally — that schema said of an edge's `resolved` flag
that *absent means NOT STATED rather than true, the same rule the render
contract uses for its optional fields*. The general rule was in a sentence about
a specific field, and nobody read it as general until a score forced it.

### The diagnostic

**Many identical differences are one convention. One difference is a defect.**

When a comparison reports N differences, group them by mechanism before reading
the number. 28 × the same field name is a *convention mismatch* and one decision.
A count without that grouping tells you how bad it looks, not how much work it
is — and it invites fixing 28 things.

The converse is the more dangerous half: **the single difference is where the
real defect hides.** In the run above, 28 were a convention, 2 were a broken
fixture case, and exactly 1 was a genuine bug in the producer. The bug was the
smallest number on the page.

## Run the consumer's battery in your own build

If the consumer publishes a battery — a test suite it intends producers to run
against their own output — **your build runs it, against your real output, every
time.**

```powershell
task Battery Build, {
    $graph = Get-MyOutput -Path $fixture
    $graph | ConvertTo-Json -Depth 30 | Set-Content "$BuildRoot/output/graph.json"

    Invoke-Pester -Container (New-PesterContainer `
        -Path "$consumerRepo/tests/ProducerContract.Battery.ps1" `
        -Data @{ GraphPath = "$BuildRoot/output/graph.json" }) -Throw
}
```

Not a copy of it. A copy stops being the consumer's battery the day the consumer
changes it, and it goes on passing.

Validating against the schema is not the same test. A payload can satisfy every
schema rule and still be something the consumer refuses — because the consumer
derives things from it, and the derivation has its own preconditions. The
assertion that earns its keep in a battery is usually the last one: *does this
map to what the consumer actually builds from it?* Schema-valid and
consumer-acceptable are two claims, and only the second one is the one you care
about.

## Never rename what the contract names

Command names, field names and enum values that cross the boundary belong to the
contract. When a linter objects — `PSUseSingularNouns` against a contract-fixed
`New-GraphRenderOptions` is the recurring one — **the linter is wrong and the
suppression is the answer**, with the reason written beside it. See
`powershell-module-build`'s "Suppressing a rule" for the format.

A consumer cannot rename it back. That asymmetry is the whole argument.

## Declare the contract version, and mean it

Say which version of the contract you emit against, in the manifest's
`RequiredModules` and in the HANDOFF. It is the only thing that says what your
output *means*.

Know whether the entry is a floor or a pin. `RequiredModules` with
`ModuleVersion` is a **floor** and accepts everything above it, so the version
you tested against and the version that will be used are different facts. Print
the resolved version during the build (see `powershell-module-build`) so the one
actually used is visible rather than assumed.

## When the oracle is wrong

A hand-authored oracle is a second implementation of the reading, written by
hand, and it can be wrong. Two rules keep this from becoming a licence:

- **The oracle is right until a decision says otherwise.** Not until it is
  inconvenient. If it is wrong, that is a finding, recorded with the mechanism,
  and the fixture is amended by a decision that names what changed and why — not
  edited by the pass that is being scored. A producer that edits its own oracle
  is scoring itself.
- **A case no implementation can pass is broken, not hard.** One fixture asserted
  a relationship stated only in a prose *description*. No parser could find it,
  so the case could never be passed and the score could never reach its top. That
  is a defect in the fixture, and it took a decision to repair. But notice the
  order: the finding was recorded in one pass and repaired in the next, by a
  decision, with the oracle re-falsified afterwards.

## Checklist

- [ ] Read the contract's rule on optional and absent fields **before** emitting.
- [ ] For each optional field: is this a positive fact, or nothing to say?
- [ ] The consumer's battery runs in your build, from its repository.
- [ ] The contract version is declared, and you know whether it is a floor.
- [ ] No contract-owned name renamed; suppressions carry their reason.
- [ ] Differences grouped by mechanism before the count is reported anywhere.

## Related

- `powershell-module-build` — running the battery as a task, suppression format,
  printing the resolved dependency version.
- `powershell-module-test` — falsifying an assertion before trusting it.
- `powershell-module-scaffold` — the layout; the dev loader that lets a battery
  import your module before it is built.
