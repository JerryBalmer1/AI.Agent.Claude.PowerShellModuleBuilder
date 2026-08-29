---
name: task-tree-reporting
description: Format a response during multi-skill work as a task tree — parent tasks as headings, each skill invocation as an indented line saying what and why, nested invocations indented further, one status line per parent task. Markdown structure only, no colour. Use whenever a response covers more than one task or invokes more than one skill.
---

# Task tree reporting

## The shape

```markdown
## Task 1 — Scaffold the module

  → powershell-module-plan: intake questions, because the brief names no field conventions
  → powershell-module-architect: seven commands, splitting parse from resolve
    → powershell-module-scaffold: src/PSAzureDevOpsGraph, Public flat, Private nested

**Status: done.** 7 public commands, 3 private helpers, manifest exports 7.

## Task 2 — Make it build

  → powershell-module-build: InvokeBuild tasks, ParseError in the analyzer severity list
  → powershell-module-test: 37 unit cases, ordered runner green through all five layers

**Status: done.** build exit 0, analyzer 0 findings, coverage 82.88% (target 40%).
```

Four rules, and nothing else:

1. **Parent tasks are `## Task N — <name>`.** Numbered, in the order they were
   done, matching the plan's task numbers where a plan exists.
2. **Each skill invocation is an indented `→ <skill-name>: <one line>`.** The
   line says *what* and *why* — what it produced, and what made it necessary. A
   line that only names the skill is noise.
3. **A nested invocation indents further.** A skill that another skill reached
   for sits under it, so the reader can see what called what.
4. **One status line closes each parent task**, in bold, carrying the numbers
   that task produced.

## What a good invocation line looks like

The line is one sentence and it earns its place by carrying a fact.

| | |
|---|---|
| ✗ | `→ powershell-module-build: building the module` |
| ✗ | `→ powershell-module-test: running tests` |
| ✓ | `→ powershell-module-build: added ParseError to the severity list — Lint was green on a file that would not parse` |
| ✓ | `→ powershell-module-test: 37/37, stopped nowhere; integration layer inapplicable (no cases)` |

The second column is not longer because it is more verbose. It is longer because
it says something.

## The status line carries numbers, and they cite something

```markdown
**Status: done.** build exit 0, conformance 51/51, functional 12/12.
**Status: blocked.** Conformance 6/30 — discovery cannot name the module in a run directory (F-8).
**Status: partial.** 4 of 5 layers green; integration inapplicable, 0 cases — not a pass.
```

- **Never a figure without an artifact behind it.** If the status line says
  `51/51`, the file that says so exists and the reader can be told where.
- **State cases-run beside cases-passed.** A score comparison is only valid when
  the denominator is stable between the two runs, and a repair that lets an
  assertion reach more of a target changes it. Note the direction of the risk:
  an assertion that silently stops producing cases makes a score go **up**.
- **Zero cases is not a pass.** Report it as inapplicable, distinctly.
- **Never collapse two scores into one percentage.** Shape and behaviour are
  different measurements. A module can score 100% on one and zero on the other,
  in either direction.

## No colour, ever

Markdown structure only. No ANSI escapes, no terminal colour codes, no emoji
carrying meaning that plain text does not also carry.

The tree has to survive being pasted into a plan, committed to a repository,
read in a diff, and read by someone six months later in a viewer that renders
none of it. A status that is only legible because it is green is a status that is
illegible everywhere the record actually lives.

Bold for the status line, and that is the only emphasis the format uses.

## When to use it

Whenever the response covers **more than one task or more than one skill**. Below
that it is overhead — a single-skill answer is a paragraph.

Use it while work is in progress too, not only at the end: a tree with three
tasks done and the fourth showing `**Status: in progress.**` is exactly what
tells a reader where to interrupt.

## Related

- `powershell-module-plan` — where the task numbers come from.
