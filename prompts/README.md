# The prompts kit

Five paste-able documents for building **your** module with the `psmodule`
plugin. They are not documentation about the method; they are the text you
actually paste, in the order you actually paste it.

If you want the reasoning instead, start at
[docs/creating-an-agent/00-start-here.md](../docs/creating-an-agent/00-start-here.md).
If you want the walk-through of what each stage does to your repository,
[chapter 11](../docs/creating-an-agent/11-your-first-module.md) follows this kit
end to end. If you want the shape of the whole thing on one page, the README's
[flow diagram](../README.md#the-flow) is that.

## What is here, and the order

| File | When | What it produces |
|---|---|---|
| [project-context-template.md](project-context-template.md) | **once, before anything else** | the standing instructions your director project holds. Not pasted into Claude Code. |
| [first-module.md](first-module.md) | message one of a brand-new module | a planned, scaffolded, building, tested module — and `docs/PLAN.md` |
| [new-feature.md](new-feature.md) | any change to a module that already exists | a delta plan, then the change, against the same gates |
| [release.md](release.md) | immediately before a version | a tidy report, a conformance score, and a tag **you** push |
| [troubleshoot.md](troubleshoot.md) | when something looks wrong | which artifact to read and which command re-derives it |

**The order is not a suggestion for the first two.** The context template holds
the rules that make every later prompt short; `first-module.md` assumes they are
already in place, and pasted without them it will ask you for things the
template would have answered.

## Why every one of these starts a fresh session

**A prompt is only what the session actually received.** Anything ahead of it in
the context — an earlier attempt, a conversation about what you meant, a summary
of a previous run — is part of the instruction whether you meant it to be or
not, and it will not appear in any record afterwards. That is why each file here
is written to be the *first message* of a new session rather than a follow-up:
paste it whole, into an empty session, and what the agent was asked is exactly
what is written down. It is also the only way to find out whether the plugin
alone is enough, because a session that was told the answer in the previous
message will produce it either way.
[Chapter 04](../docs/creating-an-agent/04-fresh-sessions-and-contamination.md)
is the long version, with what it cost this project when it was got wrong.

## What these prompts will not do for you

**Your module earns its own numbers.** Every score in this repository was
measured against one Azure DevOps grapher and one Terraform fixture, by one
person, on one machine. None of it transfers to your module by being adjacent to
it. The conformance suite will grade your repository honestly whatever it finds,
and what it finds is a fact about your module and nothing else — which is the
only reason the number is worth having.

The README's
[Status, honestly](../README.md#status-honestly) section is the list of what is
still unproven here, and it is worth reading before you depend on any of this.
