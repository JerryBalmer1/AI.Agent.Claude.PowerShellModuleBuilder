---
pass: 0039
title: The UX and help batch, and a denominator that moved on purpose
date: 2026-09-02
artifacts:
  - plans/0039-ux-help-batch/plan.md
  - plans/0039-ux-help-batch/accept.Tests.ps1
  - plans/0039-ux-help-batch/accept-red.txt
  - plans/0039-ux-help-batch/accept-green.txt
  - plans/0039-ux-help-batch/verify.ps1
  - plans/0039-ux-help-batch/pre-inventory.json
  - plans/0039-ux-help-batch/help-falsification.txt
  - plans/0039-ux-help-batch/tidy-falsification.txt
  - plans/0039-ux-help-batch/settings-falsification.txt
  - plans/0039-ux-help-batch/denominator-v2.txt
  - plans/0039-ux-help-batch/refscore.txt
  - evals/conformance/Help.Tests.ps1
  - evals/conformance/Get-PSModuleSetting.ps1
  - skills/powershell-module-ux/SKILL.md
  - skills/powershell-module-tidy/SKILL.md
  - CHANGELOG.md
---

# Pass 0039 — The UX and help batch, and a denominator that moved on purpose

## Asked

Two new skills — `powershell-module-ux` for argument completion, distilled from
powershell.one and never reproduced from it, and `powershell-module-tidy` for
the pre-release sweep. Four skill amendments, plus a fifth carrying a settings
table. A new block of help conformance assertions, falsified with
polarity-correct controls. An optional `psmodule.settings.psd1` whose unknown
keys are refused by name. Re-derive `cases-defined`, declare the series
boundary, prove the new assertions on a commit that predates them without
rewriting it, and release `v1.2.0`.

## Done

- **Two new skills, nineteen now.** `powershell-module-ux` (322 lines) — three
  conditions before a completer earns its place, the three mechanisms with a
  worked example each, a ~200ms cache threshold, six guardrails of which the
  third forbids caching a secret, credential, token or anything derived from
  one, and the rule that a completer without a test does not ship. Every code
  example was **run before it was written down**. Three powershell.one articles
  fetched, read and linked; the one place the skill contradicts its source is
  marked as deliberate. `powershell-module-tidy` — four deterministic sweeps
  under `scripts/` per rule 9, plus a conformance run that refuses to bless
  while any Bucket-A item is open, including on a green run.
- **Five skills amended.** The class-candidate rule with its four costs
  attached and a *checked* counterexample (analyzer); the enumerator rule with
  its declared exception mechanism (architect); the house `.EXAMPLE` standard,
  full help for private functions as well as public, and the class-help honesty
  (docs); the `docs/PLAN.md` obligation (plan); the settings table naming what
  each switch invalidates (build).
- **`evals/conformance/Help.Tests.ps1`**, eight assertions, all `HouseStyle`,
  the tag argued from METHOD's ladder rather than assumed. `cases-defined`
  **33 → 41**, `HouseStyle` **14 → 22**, the other three tags unmoved and
  `Conformance.Tests.ps1` untouched.
- **`psmodule.settings.psd1`**, three enumerated keys, precedence parameter >
  file > default, unknown key refused by name, values and provenance echoed
  into every score and run record.
- **31 falsification rows fired**: 13 tidy (7/7 red, 6/6 green), 12 help (7/7
  red, 5/5 green), 6 settings (3 breaks, 3 controls). Plus two probes on the new
  container guard.
- **Run 006's final, freshly cloned and built: 38 / 41, three failures declared
  Bucket B, none fixed.** Series boundary recorded in three places.
- **`v1.2.0`** — three version strings, README pin, CHANGELOG, annotated tag
  pushed. Acceptance 10/10 green, `verify.ps1` exit 0.

## Why

**The falsification target for the help assertions is a purpose-built fixture
rather than the reference, and that is not a shortcut.** The reference predates
these rules and fails 219 of their cases, so a break against it turns red a case
that was already red — unobservable. A row needs a known-good, and for a new
rule the known-good has to be built. The reference's actual behaviour under the
new rules is not skipped; it is the whole of the run-006 rescore.

**The Bucket-B failures were declared rather than fixed.** Editing a scored
commit to satisfy an assertion written after it would destroy the only thing
that commit is good for — being a fixed point earlier numbers were taken
against. METHOD's rule runs both ways: never weaken an assertion because a
target fails it, and never rewrite a target because an assertion is new.

**Two tidy rules were scoped rather than exempted.** `en-US` is a culture
directory the build is required to copy, and a fixture named `res one` exists to
carry a hostile path. Scoping a rule to what it is actually about, and exempting
a directory from a rule that still applies, look identical in a diff and are
opposite acts — only the second stops a check firing where it should. The
`no-space-in-filename` rule now reads only files something executes or imports;
that is a narrower rule, not a list of places it is allowed to be wrong.

**Rejected: promoting any help assertion to `Universal`.** The existing
`Universal` synopsis rule already fails posh-git on five commands, and every
assertion here is strictly stronger. Promotion is a claim and needs a second
dissimilar target. Starting them there would have been assuming the answer.

**Rejected: making the container guard key on Pester's `Result`.** A container
holding a merely failing test also reports `Failed`, so that guard would turn
every red conformance run into a crash — the exact opposite of the contract the
runner states three comments above it. It keys on the container's `ErrorRecord`.

**Rejected: an exemption list for the plan-currency check.** It will produce
false positives; the response is a one-line edit to the plan saying the work
landed, which is the behaviour the rule exists to produce. An exemption list is
how a check stops firing.

## Measured

| | |
|---|---|
| `cases-defined` | **33 → 41** (`HouseStyle` 14 → 22; Universal 9, Repository 4, RequiresBuild 6 unmoved) — `denominator-v2.txt`, `pre-inventory.json` |
| re-derived across shapes | `cases-run` **477 / 154 / 98 / 60**, `cases-defined` **41** in every one — `verify.ps1` spot-check 3 |
| run 006 final, cloned and built | **38 / 41**, `cases-run` 128/154, build exit 0, 3 declared Bucket-B failures — `refscore.txt` |
| the same commit, pre-change suite | 33 / 33 — and **not comparable**, which is what the boundary says |
| help falsification | **BREAKS 7 / 7 red, CONTROLS 5 / 5 green**, preflight 12 / 12 — `help-falsification.txt` |
| tidy falsification | **BREAKS 7 / 7 red, CONTROLS 6 / 6 green**, no collateral — `tidy-falsification.txt` |
| settings falsification | 3 breaks fired, 3 controls held — `settings-falsification.txt` |
| acceptance | 0 / 10 red → **10 / 10 green** — `accept-red.txt`, `accept-green.txt` |
| verification | 6 checks, all agree, exit 0 — `verify.ps1` |

## Learned

**A pass that writes both a convention and its assertion must run them against
each other, not review them against each other.** The set-coverage assertion
looked for the `-Name` dash form. The house `.EXAMPLE` standard, written the
same day in the same pass, mandates splatting — so a conforming example names
its parameters as hashtable keys and never writes `-Name` at all. The assertion
was **unsatisfiable by exactly the examples it rewards**, and read side by side
the two rules look entirely consistent. Nothing found it but building a fixture
to one and running the other against it.

**A container that fails discovery is invisible, and the score looks normal.**
`Help.Tests.ps1` lost its whole container to a member access on an empty array
during discovery. Every one of its assertions vanished from the run;
`cases-defined` still counted them, because it is parsed from source and does
not know a file failed to load; numerator and denominator shrank together and
the percentage looked fine. Pester printed `Container failed: 1` in its own
output and nothing downstream read it. This is *not run is not a pass*, one
level above the zero-cases rule the suite already had — and it went undetected
for one full scoring run of the reference.

**A rule can be inert because it was scoped by the wrong noun.** Tidy's
`documented-unexported` derived the module's command prefix from the module
NAME. This plugin's own convention is a command prefix that is *not* the module
name — the reference is `PSModuleGraph` and its commands are `Get-PSModule*`.
Every command the rule existed to catch fell outside its own pattern. It would
have shipped green forever. The catalogue of ways an assertion can be inert now
has a third entry beside "satisfied by a comment" and "compared against
`$null`": **scoped by a plausible identifier that is the wrong one**.

**Running a new sweep against the reference before writing a single probe is
cheap and finds a different class of defect.** Three of tidy's rules were wrong
on first contact. Two produced false positives visible immediately; the third
produced nothing, which is the one a green run would have hidden.

**A prompt's prose example can contradict the prompt's own regex.** The
suggested refscore wording put a comma where `\d+ / \d+ .*` requires a space.
The regex is the specification; the example was wrong. Written as suggested, the
acceptance test failed 9/10 — which is the correct behaviour and the reason the
regex, not the prose, is what the test contains.

**Three clones were lost to `MAX_PATH` before the cause was legible.** Git
reports `Filename too long` and says nothing about the scratch root. Both the
reference and PSAzureDevOpsGraph carry paths long enough that any temp directory
under `AppData/Local/Temp/claude/<long session id>` overflows. `verify.ps1`
documents its short default with that reason and no other.

## Capability

**Help is now graded, and the grading is bounded honestly.** Eight assertions
covering the whole function surface public and private, parameter documentation,
examples against parameter sets, and types — with the one property that *cannot*
be asserted (`Get-Help` on a class) replaced by a stated equivalent rather than
by silence or by a weaker assertion wearing the stronger name.

**A target can now configure the grader without being able to confuse it.**
Three enumerated keys, a refusal for anything else, and every score record
carrying the configuration it was taken under with the provenance of each value.

**A score can no longer be reported for a run that did not happen.** The runner
refuses and writes no result file.

**Two capabilities the plugin did not have at all:** judgment about argument
completion, which nothing else here covers and which no other gate can see; and
a single pre-release verb that aggregates the checks too small to remember, with
`docs/PLAN.md` currency as a release blocker.

**And a boundary that lets the suite grow without corrupting the record.**
`cases-defined` moved for the first time since it was introduced. The rule it
was introduced for — a change in the denominator means the suite changed, and
has to be said out loud — has now been exercised rather than merely stated, in
the CHANGELOG, the README, `docs/testing/`, the tag message and
`denominator-v2.txt`, each saying in the same breath what the boundary does not
license.
