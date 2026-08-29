---
name: powershell-module-plan
description: Intake and planning for a PowerShell module — a fixed question set for a new module, a shorter delta set for a feature on an existing one, and a plan file generated into the target at docs/plans/NNNN-<slug>.md whose definition-of-done names how the work will be tested before the work starts. Use at the start of any new module or feature, before writing code.
---

# Module planning

Ask the questions, fill the template, save it into the target, then build. The
plan is not ceremony: every question here exists because leaving it unasked
forced a coin-flip later, and coin-flips are what this project measures.

## New module — the fixed question set

Ask all six. Do not skip one because the answer seems obvious; write the obvious
answer down, because "obvious" is where the two of you disagree silently.

1. **Purpose.** What question does this module answer for a user, in one
   sentence? If the sentence needs "and", it is two modules or one module and a
   command that should not exist yet.
2. **Command surface.** What commands, with what verb and noun? What does each
   return? Which are `Public/` and which are helpers? A table, not prose.
3. **External systems.** What does it talk to — a REST API, a database, a native
   executable, the filesystem? For each: read-only or read-write, and what is
   forbidden outright.
4. **Authentication.** Where does every credential come from, exactly? Name the
   mechanism and the forbidden alternatives. "An environment variable" is not an
   answer; `$env:AZDO_PAT`, never a parameter, never a file, never in a URL, is.
5. **Constraints.** Minimum PowerShell version, editions, platforms, offline
   behaviour, performance bounds, anything the module must never do.
6. **Definition of done.** How will the work be tested — *before* it is written?
   This is mandatory and it is the section the rest of the plan is for.

### Ask about conventions the answers do not cover

The failure this catches is run 002's F-1. The specification stated the graph's
*structure* completely and its *field conventions* not at all. The first
iteration produced the oracle's exact node and edge counts and still scored
1/12: all sixty differences were conventions nobody had written down — which
optional field appears on which kind of record, whether a path is
repository-relative or a basename, whether a reason is a code or a sentence.

So, for every record the module emits, ask:

- Which fields are always present, and which appear only on some kinds?
- For each field, what exactly is the value — a code, a sentence, a path, and
  relative to what?
- One worked example per kind, written out in full.

Where a convention genuinely is not decided, **write down that it is undecided**
and pick a default in the plan. Then it is a decision with a name rather than a
coin-flip nobody can find afterwards.

## Existing module — the delta plan

Shorter, and the difference is that most of the context already exists.

1. **What changes on the public surface?** Nothing, a new parameter, a new
   command, a changed return shape? This answer sets the semver bump before any
   code is written.
2. **What existing behaviour must not change?** Name the tests that already
   assert it. If none do, that is the first thing to write.
3. **What new external dependency, if any?** If there is one, the analyzer skill
   applies: research it now and write `docs/knowledge/<tool>.md`.
4. **Definition of done**, same rule, same mandatory section.

## The definition of done is red-first

**It must name how the work will be tested before the work starts**, and the
test must be written and *run* before the thing it tests exists.

A test first seen green proves nothing about whether it can fail. This is not a
process preference — it is the finding this whole project rests on. Five
assertions in the conformance suite passed every green run and were **inert**:
satisfied by a block comment quoting the code they looked for. They were caught
only by breaking the thing they claimed to check and watching them stay green.

So a definition-of-done section that says "tests pass" is not one. It must name:

- **The oracle.** What decides correct — a fixture with expected output, a
  hand-written comparison, a schema, a specific exit code.
- **The cases**, by name, each stating the specific wrong answer it catches.
- **The command** that runs them, exactly as it will be typed.
- **The red-first evidence** that will be recorded: the failure output, before
  any implementation.
- **What is measured but not gated**, and what is gated. Shape and behaviour are
  scored separately and never averaged — a module can satisfy every structural
  assertion and do nothing useful, and collapsing the two numbers into one
  destroys both.

A plan whose definition of done cannot be written is a plan whose work cannot be
graded. That is a finding, and it goes back to the operator before any code is
written — not after.

## Generating the plan file

Fill `templates/module-plan.md` and save it **into the target repository**:

```
docs/plans/NNNN-<slug>.md
```

`NNNN` is assigned by the operator, four digits, zero-padded, never invented by
the agent. `<slug>` is kebab-case and short.

It goes in the target, not in the harness: a session restart clears the
conversation and not the repository, and the plan is for whoever picks the module
up next. Commit it with the work.

## Before you write a line of code

- [ ] All six questions answered, in writing, in the target
- [ ] Field conventions written out with one worked example per record kind
- [ ] Undecided conventions named as undecided, with a chosen default
- [ ] Definition of done names the oracle, the cases, and the command
- [ ] The acceptance test exists and has been **run red**
- [ ] The plan file is committed

## Related

- `powershell-module-architect` — turning question 2 into a real surface.
- `powershell-module-analyzer` — question 3, when the answer is a tool you do
  not know.
- `powershell-module-test` — building the oracle the definition of done names.
- `task-tree-reporting` — how to report progress once the plan has tasks.
