# 10 — Using this as a template

This repository is two things bolted together: a method for making an
agent's output measurable, and one particular measurement of one particular
agent building one particular kind of thing. The first travels. The second
does not, and most of the bytes here are the second.

So the job of templating is subtraction, and the hard part is knowing what
to subtract. This chapter does not invent a scheme for that. The repository
already has one, applied line by line, and it is the only one you should
use.

---

## Start from METHOD.md's three labels

Every rule in [method/METHOD.md](../../method/METHOD.md) carries one of
three labels, stated at the top of that file:

> - **PORTABLE** — survives a domain change unedited. Copy as-is.
> - **TUNE** — right shape, wrong specifics. Keep the structure, replace the
>   nouns.
> - **DOMAIN** — does not travel. Listed so it is visible as something to
>   replace, not silently inherited.

In the terms of the job in front of you:

- **PORTABLE is what you keep verbatim.** Do not paraphrase it, do not
  "adapt" it, do not shorten it. These rules are the ones that were paid
  for by a failure somewhere in this repository's history, and rewriting one
  in your own words is how the failure comes back.
- **TUNE is what keeps its shape and changes its nouns.** The structure is
  the finding; the specifics are this project's. A universality ladder for
  assertions is TUNE: the ladder is real, the rung names are PowerShell's.
- **DOMAIN is what you must replace.** Not delete and forget — replace.
  Every DOMAIN item is a thing this project supplied that your project has
  to supply for itself, and a template that quietly leaves them behind is a
  template that will fail at the first measurement without telling you why.

Read METHOD.md once end to end, and then read it a second time reading only
the labels. That second pass is your strip-down guide. It is more reliable
than any checklist in this chapter, including the one below, because it is
attached to the rules themselves rather than to a document about them.

### The DOMAIN list, in full

METHOD.md names what it supplied and you do not get, under the heading
"What this project supplied that you must replace":

> **DOMAIN.** Three repositories with fixed roles: a reference
> implementation (read-only), the thing under test, and a target rebuilt
> from nothing.
>
> **DOMAIN.** The domain itself: PowerShell, InvokeBuild, Pester, the
> manifest schema, the build conventions extracted from one reference.
>
> **DOMAIN.** Target-specific environment requirements discovered by
> failing: dependency paths, tool versions, shell availability.
>
> **DOMAIN.** The corpus used to break the closed loop.

Four items, and the fourth is the one people skip. The corpus is the set of
artifacts you did not write, which is what stops your grader from being a
mirror. METHOD.md is explicit that it is the cheapest part of the method
when one already exists, and it says what happened when this project finally
used one — see the closing section.

---

## The marker convention

Reading labels works for METHOD.md because METHOD.md was written with
labels. The rest of the repository was not. So there is a second, cruder
convention for prose: two HTML comments that mark a passage for whoever is
stripping the repository down.

```
<!-- TEMPLATE:remove -->   project-specific; delete when templating
<!-- TEMPLATE:replace -->  keep the shape, swap the content
```

They are HTML comments, so they render as nothing and are invisible to a
reader of the finished page. A marker sits on the line immediately before
the passage it governs.

**They are used in `README.md` and in these chapters, and nowhere else.**
Not in `skills/`, not in `commands/`, not in `evals/`, not in `method/`. The
reason is mechanical rather than stylistic: everything under `skills/`,
`commands/` and `evals/` is pinned by SHA for the measured runs — see the
Pins section of [LEDGER.md](../../LEDGER.md), where the ladder plugin SHA
and the assertion that a diff over those paths is empty are both recorded.
A comment added to a skill for the convenience of a future templater changes
the blob, breaks the pin, and invalidates the comparison the runs exist to
make. The markers stay in the documentation tier, which is not pinned.

### An example of each, from real content

**`<!-- TEMPLATE:remove -->`.** README.md's "With the plugin and without it"
table is the four-run comparison: `19 / 33` against `33 / 33` on shape,
`0 / 12` against `1 / 12` on first-shot behaviour, with a row for wall-clock
per run. Every cell of it is a measurement of *this* agent against *this*
fixture. There is no version of that table a new project can keep. It is not
a shape to fill in — a new project has taken no measurements, and a table of
scores with the numbers blanked out is worse than no table, because it
invites filling them in with guesses. Marked `remove`, and gone on the first
day.

**`<!-- TEMPLATE:replace -->`.** README.md's "The ecosystem" table is six
rows: a repository, what it is, and what state it is in. The *content* is
this project's — `PSAzureDevOpsGraph`, `PSGraphRender`, and the rest — and
none of it survives. The *shape* is worth keeping exactly as it is: a new
project also has more than one repository, also needs one place that says
which they are and which is governed from where, and will otherwise
rediscover that need three months in. Marked `replace`: swap the rows, keep
the table.

The same distinction appears in this chapter's neighbour. In
[09 — try before you trust](./09-try-before-you-trust.md), the clone command
carries a `replace` marker: every reader of a templated copy still needs a
clone command in that exact position, and the URL in it is the one thing
that must change.

The test to apply when you are unsure: **ask whether a reader of the
templated repository would be worse off if the passage were simply absent.**
If yes, it is `replace` and you owe it new content. If no, it is `remove`.

---

## The one grep

Every marker in the repository, listed:

```bash
grep -rn "TEMPLATE:\(remove\|replace\)" README.md docs/
```

The PowerShell equivalent, which is what the pass's own acceptance test
uses:

```powershell
Select-String -Path ./README.md, ./docs/creating-an-agent/*.md `
    -Pattern 'TEMPLATE:(remove|replace)'
```

Both print one line per marker: the file, the line number, and the marker
itself. That is the whole output — a marker is a line of its own, so there
is no surrounding text on the line to read. Sort the list by file and work
down it; the passage each marker governs starts on the line after.

Two honest notes about that command.

- **Scope it to the two places markers are allowed.** Running it across the
  whole repository is not more thorough, it is just slower, and a hit
  outside `README.md` or `docs/` is a bug in the convention rather than a
  passage to strip.
- **A grep that returns nothing is a result, not a failure.** It means the
  markers have not been applied to the file set you pointed at — which is a
  state this repository has been in — and not that the repository has
  nothing project-specific in it. Point it at `README.md` and `docs/`
  separately if you want to know which of the two is bare.

---

## The stripping checklist

Four parts, in the order that hurts least.

### What to rename

- **The repositories.** Six names, from README.md's ecosystem table:
  `AI.Agent.Claude.PowerShellModuleBuilder` (this one — the harness, the
  oracle, and the plugin), `PSAzureDevOpsGraph` (the build target),
  `PSGraphRender` (the renderer), `PSGraphRenderToHtml` (the producer /
  renderer contract), `PSModuleGraph` (the first producer) and
  `PSTerraformGraph` (the second). The names are load-bearing in more places
  than a search-and-replace will reach: skill names, the plugin manifest,
  run directory names, and the governance decisions in
  [decisions/](../../decisions/) that name them.
- **The plugin's own identity.** `psmodule`, its `displayName`, and the
  slash-command prefix that follows from it (`/psmodule:build`).
- **The Azure DevOps fixture coordinates.** Organisation
  `https://dev.azure.com/jlbalmerjr1`; project `ClaudeTesting` for the
  fifteen-pipeline fixture; project `ClaudeTestingTerraform` with the three
  repositories `TfFixtureNetwork`, `TfFixtureApp` and `TfFixtureShared`.
  These are named in the fixture creation plan, the troubleshooting
  document, and
  [decision 0011](../../decisions/0011-terraform-fixture-and-run-ledger.md),
  which is also where the rule that fixture definitions are created and
  never queued is written down. If your domain has a live system behind its
  fixture, write the equivalent constraint before you write the fixture.
- **The credential.** `$env:AZDO_PAT`, which README.md's Guardrails section
  makes the only channel — "Never a parameter, never a file, never in a
  URL", because a value passed as a parameter reaches `PSReadLine` history,
  `Start-Transcript` output and the ScriptBlock logging event log. Rename
  the variable to yours and keep the rule verbatim; the rule is PORTABLE
  even though the name is not.
- **The run ledgers.** Runs are numbered in two independent series —
  `runs/NNN-<slug>` for the PSAzureDevOpsGraph measurements and
  `runs/tf-NNN-<slug>` for the Terraform ones, split deliberately in
  decision 0011. A run number is allocated in order and never reused, and
  [runs/README.md](../../runs/README.md) adds the rule worth carrying: the
  slug says what was run, not how well it went — `002-first-resolver`, not
  `002-still-broken`.

### What to reset

Reset means the file stays and its contents go. Each of these accumulates,
and an inherited accumulation is worse than an empty one because it reads as
evidence about a project that has not run yet.

- **[LEDGER.md](../../LEDGER.md)** — four counters and a pin list.
  - *Passes* names the last landed pass and the next one. Here that is
    "Last landed: 0029. Next: 0030 — packaging". It exists so a fresh
    session with no memory of the last one can find out where the work
    stopped. Yours starts at your first pass.
  - *Runs* names, per series, the last run and what the next one is. It
    resets because a run number is a claim about measurements taken.
  - *Versions* holds the current version of each governed repository,
    including `psmodule manifest: 0.1.0`, which the ledger says is
    "re-versioned at packaging, 0030" with `v1.0.0` reserved for "passed the
    ladder". A version reserved for a result you have not achieved is a good
    convention to copy and a terrible number to inherit.
  - *Pins* records the SHAs a measured run is valid against — the plugin
    SHA, the model version, the oracle blob. They are the identity of your
    instrument, and inheriting another project's is meaningless. Note what
    this section does *not* do: it refuses to quote its own repository's
    HEAD, on the grounds that a file cannot know a SHA about itself, and
    tells the reader to verify by ancestry and `git ls-remote` instead.
    Carry that habit.
- **[decisions/](../../decisions/)** — twelve append-only records here, each
  a choice that outlives the pass that made it, with the alternatives it
  rejected. Empty in a new project by definition: you have not rejected
  anything yet. Keep the numbering scheme and the rejected-alternatives
  field; drop every record.
- **[journal/](../../journal/)** — one entry per pass, six fields, written
  from that pass's artifacts and never from memory. Empty for the same
  reason. The one file that carries is
  [journal/TEMPLATE.md](../../journal/TEMPLATE.md), which holds the six
  headings and, more usefully, the instruction under *Measured*: "A number
  without a file behind it does not belong in this field."
- **[runs/](../../runs/)** and **[plans/](../../plans/)** — the same logic
  taken to its conclusion. Both are records of work that did not happen in
  your project.

### What to keep verbatim

Three bodies of text. Copy them unedited, then edit only where a sentence
names something that no longer exists.

- **METHOD.md's PORTABLE tier.** Every rule marked PORTABLE, including the
  ones that will look like overkill on day one — "An assertion does not
  count until it has a falsification row", "Zero cases is not a pass",
  "Prevalence is not correctness", "Baselines are declared, not derived".
  These travel because none of them mentions PowerShell. They are claims
  about measurement, and your domain does not get a discount on them.
- **[PLAN-PROTOCOL.md](../../PLAN-PROTOCOL.md).** The format every pass
  executes against, and in particular two rules with scar tissue on them:
  the file-supply rule ("A file a pass must create is either already
  committed to the repository, or its full content appears verbatim in the
  prompt. There is no third channel"), which the protocol says has already
  cost a pass twice; and the tier rule, which decides *full* versus *light*
  by whether the pass changes executable behaviour and explicitly not by how
  many documents it writes. Both are about the agent's failure modes, not
  PowerShell's.
- **The falsification rules.** METHOD.md's "The falsification harness"
  section and the eleven hazards in
  [evals/HARNESS.md](../../evals/HARNESS.md). This is the part most likely
  to be skipped and least safe to skip. The hazards are not hypotheticals:
  hazard 4 is a break that changed nothing producing a green that proves
  nothing; hazard 8 is an absence check on prose being defeated by a line
  break — and it recurred *inside the falsification of its own fix*, with
  the check for the hazard written with the hazard in it. Knowing about a
  hazard is not protection against it, which is exactly why the list is
  written down rather than remembered.

Why these three and not others: each of them is a rule about how you find
out whether something worked, and none of them contains a fact about
PowerShell modules, Azure DevOps, or graphs. That is the whole test. If a
passage would still be true for an agent generating SQL migrations, it
travels.

### What to rebuild from scratch, in order

The order matters more than any individual step, and it is the subject of
its own chapter — [02 — order of operations](./02-order-of-operations.md)
has the reasoning, the failure modes of getting it wrong, and this
project's own record of doing so. The sequence itself, so you can see the
shape of the work:

1. **Answer the precondition question.** METHOD.md's first rule: is your
   agent's output machine-checkable at all? If not, the method degrades to
   "rubrics and blind A/B comparison, which is far weaker", and applying it
   anyway buys "the ceremony without the signal". Decide this first.
2. **Build the oracle** — the thing that says whether an output is right.
   Before any capability, so that every capability can be judged by the
   score it moves.
3. **Falsify the oracle**, with a break *and* a control for every
   assertion.
4. **Take a baseline with zero capabilities.** What the bare model achieves
   is the number every addition has to beat.
5. **Add the first capability**, and measure it against that baseline.
6. **Automate when doing it by hand becomes annoying, and not before** —
   the notes from doing it manually are the specification for the tool.
7. **Break the closed loop with a corpus** you did not write.

---

## Start smaller than this

One last thing, and it is METHOD.md's own warning about itself, from "Known
limits of this method":

> - It is expensive up front. Several passes produce a grader and no
>   capability. On a small project, use the minimum: an oracle,
>   falsification with controls, and a journal. Skip the harness and the
>   decisions log. Do not skip the corpus: it is the cheapest part of the
>   method when one already exists, and it is what breaks the closed loop —
>   here it cost one pass and invalidated five of ten assertions in the tag
>   it tested.

Take that literally. The minimum viable subset is three things: **an
oracle, falsification with controls, and a journal.** No harness, no
decisions log, no run ledger, no plan protocol. Start there, on something
small, and let the rest arrive when doing without it becomes annoying —
which is rule 6 above, applied to the method rather than to the tooling.

And note which item the warning refuses to let you drop. The corpus cost
one pass and invalidated five of ten assertions in the tag it tested. A
grader you wrote, checked against output built to satisfy it, proves only
that you are self-consistent. Everything else in this repository is
optional next to that.
