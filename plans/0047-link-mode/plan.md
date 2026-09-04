# Pass 0047 — PSGraphRender link-mode registry (operator-complete item 1)

**Tier:** RequiresBuild. **Target:** PSGraphRender `cd4857d` → `3f2ec85`, tagged
`v0.14.0`. **Harness:** `db5a97d` → this record, plus the R2 small at `eef6e80`.

Written against harness `eef6e80` and target `3f2ec85` (decision 0004).

---

## 1. Prompt

Verbatim, as issued. This is the RE-ISSUE after the 0046 stop cycle; the prompt
carries its own note of what changed from the original.

<!-- PROMPT-VERBATIM-BEGIN -->

# PASS 0047 — PSGraphRender link-mode registry (operator-complete item 1) — RE-ISSUE

Re-issue after the 0046 stop cycle. Changes from the original 0047 prompt, exhaustively: the **Recovery preamble** below (new), the **acceptance-C baseline named** per stop-report F3, and **SC1's clone target** matching it. Nothing else is altered; every unamended section stands verbatim.

## Recovery preamble (runs before Section 0)

R1. 🔵 Frontier three-source read from `origin/main`: all three must read **0046** (LEDGER `Last landed:`, highest `plans/NNNN-*`, highest `journal/NNNN-*.md`). 🔴 Any other value or disagreement — the 0046 completion state has moved again; report and stop. Expected true: 0046 landed at `db5a97d`, mains level.

R2. 🟢 **Workspace-file ruling, executed here (the one survivor of the 0046 completion prompt's task 6).** The operator's approval of this re-issue is the ruling: `PSGraphRender.code-workspace` becomes **untracked-and-ignored**, not committed. Add `*.code-workspace` to the harness `.gitignore`, its own commit, directly on harness `main`, pushed — a small riding along per the improvements-log size rule, its ride-along host being this pass, whose records land in the harness anyway. Rationale on record: content verified clean (two repos, no PSModuleGraph); suite `d5a90b2` constrains only a tracked workspace file, so ignoring removes it from that suite's scope by construction; the 0046 session's refusal to decide this ("a decision that is not the pass's to make") was correct and is now superseded by this explicit 🟠 ruling. 🔵 `git check-ignore PSGraphRender.code-workspace` exits 0 after the commit; harness status clean.

R3. Section 0's dirt check below then runs against the post-R2 state — it must find both repos clean with no carve-outs.

---

## Signals

🔴 hard stop (report, never resolve) · 🟠 operator action · 🟢 agent task · 🔵 evidence gate · ⛔ never, whole pass. Per PLAN-PROTOCOL.

**Tier:** RequiresBuild — this pass changes `src/` and the shipped template set, builds, and tests. The first behavior-changing pass in PSGraphRender since the 0021 handoff.

**Target repositories:** `PSGraphRender` (writable) and `AI.Agent.Claude.PowerShellModuleBuilder` (plan record, LEDGER, journal, and the R2 gitignore small only). This workspace holds exactly those two. ⛔ The viewmodel contract (`contract/viewmodel.schema.json`) does not change this pass — see task 2's hard stop. ⛔ Nothing reaches Azure DevOps; no other repository is touched.

**Purpose.** A node link can only ever be an editor scheme: `vsCodeUriFor` in `scripts/editor-link.js` hardcodes `vscode://file/`, `NODE_ACTIONS` in `menu.js` binds to it, and no configuration names an alternative. Logged **large** in `docs/improvements.md`; the backlog item pass 0043 filed in this repo's HANDOFF ("configurable node-link mode — editor scheme vs. href template — future red-first pass") is this pass. Link mode becomes declared configuration: `editor` (current behavior, preserved exactly), `hrefTemplate` (per-node URL from a template over viewmodel fields), `none`. This is operator-complete item 1 and the prerequisite for item 2 (the 3D template set).

## 0. Sync

🟢 Fetch both workspace repos (`--all --tags --prune`), ff-only updates. 🔵 Report. 🔴 Divergence or dirt. 🔴 `PSModuleGraph` present in this workspace's folders or the session's directory list.

## 1. Preconditions

1. **Frontier, three sources:** 🔴 any source shows 0047 assigned. 🔴 Sources disagree with each other. 🔴 **The frontier reads below 0046** — pass 0046 (runner regex repair) must be landed before this pass, because the conformance runner that grades this repository is the instrument 0046 fixes. Record the three values 🔵.
2. 🔴 Either repo not on `main`, not clean, or not ff-synced. PSGraphRender expected at `cd4857d` / v0.13.0 at authoring; 🔴 if `main` has moved, stop and report — this prompt's file citations were read from that tree.
3. 🔵 **Constraints read first:** read `docs/constraints.md` in full and record in `plan.md` either "no conflict" or the specific entry any task below collides with. 🔴 A collision — an accepted limitation is a ruling; the operator reopens it, not this pass.
4. 🔵 **Design surface derived, not recalled:** before writing any code, read and record verbatim excerpts of: `vsCodeUriFor` and its callers in `scripts/editor-link.js`; the `NODE_ACTIONS` binding in `menu.js`; the shipped template set's `Config/settings.psd1` shape (how existing settings are declared, typed, and consumed — the link-mode setting must be declared the same way, not a new mechanism); how `meta.rootPath` and per-node `path` reach the rendered document; and the repository's own test layout and invocation (how a red test is written and run here — note backlog 10: not importable from `src/`, so use whatever loader the repo itself uses). 🔴 Any of these cannot be established unambiguously.
5. **Sequencing gate:** 🔴 any task-3 implementation before section 2's reds are observed.

## 2. Acceptance — red first, all three modes

🟢 Commit the acceptance tests (in the repository's own test form, placed per precondition 4's findings) before any implementation. Three behaviors, each observed red against the base:

- **A — `hrefTemplate`:** with the template set configured `linkMode = 'hrefTemplate'` and a template such as `https://example.invalid/{relativePath}`, the rendered document's node action navigates to the resolved URL — `{relativePath}` derived as the node's `path` made relative to `meta.rootPath`, plus at minimum `{path}`, `{id}`, `{label}` as resolvable tokens. Red today: no such setting exists.
- **B — `none`:** configured `linkMode = 'none'`, the rendered document carries no editor-link action and no `vscode://` occurrence beyond the renderer's static UI strings. Red today.
- **C — `editor` preservation (baseline amended per stop-report F3):** configured `linkMode = 'editor'` **and** with the setting entirely absent, the rendered document is identical to the output of **`main@cd4857d`** — the v0.13.0 codebase this prompt's citations were read from — for the same viewmodel (byte-comparable modulo already-declared varying fields). Note: tag `v0.13.0` points at `964d73a`, 8 documentation/examples commits behind `cd4857d`; the tag's tree predates the 0043 examples task 4 upgrades, so the tag is **not** the control. This is the tag-behind-tip pattern at base, per the 0046-stop report F3, not introduced by this pass. This test must be **green before and green after** — it is the no-regression control, and its red-capability is demonstrated instead by running it against a scratch render with the default deliberately flipped. 🔵 All observed results recorded.

🔵 Also record the conformance baseline: the (0046-repaired) runner against PSGraphRender at base — score and cases-run.

## 3. Tasks (serial unless marked)

1. 🟢 Branch `pass-0047-link-mode` in PSGraphRender; first commit (the red acceptance tests) pushed immediately; push after every task.
2. 🟢 **Implement the registry.** `linkMode` declared in the template set's `Config/settings.psd1` exactly as its sibling settings are declared; default `editor`. `editor-link.js` (or its successor) resolves the mode: `editor` → current `vsCodeUriFor` behavior unchanged; `hrefTemplate` → token resolution over the fields precondition 4 established, template string itself a setting beside the mode; `none` → the action absent, not stubbed. All resolution from fields the viewmodel **already carries**. 🔴 If any needed datum is not already in the viewmodel, STOP and report — a contract change is cross-repo (PSGraphRenderToHtml consumes the schema) and belongs to a decision, not to this pass's momentum.
3. 🟢 Green the acceptance tests. 🔵 All three modes' results verbatim.
4. 🟢 **Examples earn the feature** (parallel with 5): upgrade the 0043 node-link example — the `REPLACE-WITH-YOUR-CLONE-PATH` placeholder demo — to a real `hrefTemplate` example linking `https://github.com/JerryBalmer1/PSGraphRender/blob/main/{relativePath}`, live links, committed HTML + screenshot + regen command per the examples-index form; keep one `editor`-mode example demonstrating the preserved behavior (placeholder rootPath, per the public-artifact rule — no machine paths, and SC2's machine-identifying grep from 0043 applies to everything committed). Examples index and README Examples table updated.
5. 🟢 Docs (parallel with 4): `docs/improvements.md` — the large item closed with this pass's reference, superseded text struck not deleted; `docs/HANDOFF.md` state section updated; `CHANGELOG.md` in the repository's own form.
6. 🟢 **Release:** version per the repo's tag list at run time — expected **v0.14.0** unless `git tag` says otherwise (🔴 if LEDGER's version line and the tag list disagree with each other). Annotated tag; run the verify falsification **before** the release commit so the tag names the pass tip — adopting the recorded cheap fix for the tag-behind-tip pattern, and 🔵 note in the plan that this ordering was used.
7. 🟢 Harness records: `plans/0047-link-mode/plan.md` (prompt verbatim, evidence, Deviations); `plans/0047-link-mode/verify.ps1` (decision 0004; `-FailCheck`; scratch-only writes) — checks: three acceptance modes, examples regenerate, conformance at head ≥ base 🔵 (both scores recorded; touched-area improvements welcome, regression is a finding), editor-mode byte-comparison green, machine-identifying grep clean; LEDGER (counter 0047; version line to the task-6 tag; the 0043-filed backlog item resolved in place); journal (six fields, Capability never benefit).
8. 🟢 Fast-forward both mains per 0009/0010. ⛔ Never force.

## 4. Spot-checks (🔵 each; red-capability stated per METHOD)

- **SC1 — default is invisible (clone target amended per F3):** a viewmodel rendered with no `linkMode` setting anywhere produces output identical to the base's (the acceptance-C control, re-run from a fresh clone at **`cd4857d`**). Red demo: flipped default in a scratch copy.
- **SC2 — nothing machine-identifying:** the 0043 grep (drive-absolute paths; `vscode://` carrying a real path) across everything this pass commits. Red demo: the 0044-era fixture form.
- **SC3 — template injection surface:** a template containing quotes/angle-brackets and a node label containing HTML render without script execution — resolved URLs are attribute-encoded. Red demo: the encoding step disabled in a scratch render.
- **SC4 — `none` means none:** DOM of a `none`-mode render carries no link action handler. Red demo: `editor`-mode render run through the same check.

## 5. Constraints

⛔ No `contract/` change (task 2's stop). ⛔ No changes to PSGraphRenderToHtml, producers, or fixtures. ⛔ The cytoscape template set remains the shipped default; no new template set this pass (that is item 2 / pass next). ⛔ No conformance assertion or harness instrument changes. Improvements-log size rules apply to anything discovered en route: small rides along in its own commit, medium and large are logged, not taken. Public-artifact rule stands for every committed artifact.

## 6. Local handoff — the last act

🟢 Both workspace repos: checkout `main`, `pull --ff-only`, `fetch --tags --prune`, status clean; 🔵 LOCAL STATE table (repo | branch | HEAD | clean). Divergence or dirt reported, never resolved.

<!-- PROMPT-VERBATIM-END -->

---

## 2. Recovery preamble

### R1 — frontier, three sources from `origin/main` 🔵

| Source | Value |
| --- | --- |
| `LEDGER.md:8` `Last landed:` | **0046** |
| highest `plans/NNNN-*` | `plans/0046-runner-regex` |
| highest `journal/NNNN-*.md` | `journal/0046-runner-regex.md` |

All three agree. `origin/main` at `db5a97d`; `main...origin/main` = `0 0`. The
prompt's "expected true" held exactly.

### R2 — the workspace-file ruling 🟢

Content verified **before** the ruling was applied, not after:

```json
{ "folders": [ { "path": "." }, { "path": "../PSGraphRender" } ], "settings": {} }
```

Two folders, no `PSModuleGraph`, empty settings — matching the rationale the
prompt states.

The claim that ignoring removes it from `d5a90b2`'s scope was re-derived rather
than accepted. That suite's discovery is:

```powershell
$wsPaths = @(& git -C $Target ls-files '*.code-workspace' 2>$null)
```

`git ls-files` lists **tracked** files, so an untracked-and-ignored file
produces zero cases and reports inapplicable. The suite's own comment says why:

> Tracked, because an untracked `.code-workspace` is the operator's own business
> and never reaches anyone else; a committed one composes the workspace of every
> person who clones.

Landed as `eef6e80` on harness `main`, its own commit, pushed. Evidence gate:

```
$ git check-ignore -v PSGraphRender.code-workspace
.gitignore:18:*.code-workspace   PSGraphRender.code-workspace
CHECK_IGNORE_EXIT=0
$ git status --porcelain
(empty)
```

**Noted, not acted on:** the harness's *other* workspace file,
`AI.Agent.Claude.PowerShellModuleBuilder.code-workspace`, is **tracked** and
stays tracked — a `.gitignore` rule does not untrack a tracked file. That is the
correct outcome and not an oversight: the published workspace file stays inside
`d5a90b2`'s scope, the operator-local one leaves it. Its content was checked and
registers the four ecosystem repositories and no `PSModuleGraph`.

### R3 / Section 0 — sync 🔵

| Repo | Fetch | Branch | HEAD | vs origin | Clean |
| --- | --- | --- | --- | --- | --- |
| harness | exit 0 | `main` | `eef6e80` | `0 0` | yes |
| PSGraphRender | exit 0 | `main` | `cd4857d` | `0 0` | yes |

No carve-outs; the dirt check found both repos clean, which is what R2 bought.

**PSModuleGraph 🔴 — did not fire, and the near miss is recorded.** A
`PSModuleGraph` directory *does* exist on disk at
`c:\__Code\__AI.Agent.Claude.PowerShellModuleBuilder\scratch\PSModuleGraph` —
one level **above** both repositories, in the containing folder. It is not in
the session's directory list (primary: the harness; additional: PSGraphRender)
and no workspace file registers it, so the stop condition as written does not
fire. Reported because "absent" and "present but out of scope" are different
facts and the second is the one that is true.

---

## 3. Preconditions

### 1 — frontier 🔵

Recorded in R1. No source shows 0047 assigned:
`git ls-tree origin/main plans/ journal/ | grep 0047` → empty. The frontier
reads 0046, which is the floor this pass requires, not below it.

### 2 — repository state 🔵

PSGraphRender at `cd4857d`, clean, ff-synced, tags through `v0.13.0` — exactly
what the prompt expected at authoring. `main` had not moved, so this prompt's
file citations were read from the tree that is still there.

### 3 — constraints read first 🔵

`docs/constraints.md` read in full, 120 lines. **No conflict.**

Two entries are adjacent and are recorded because they bear on this pass rather
than because they collide with it:

- **`0007-t3` — "The contract is not edited to make a panel richer."** This
  *reinforces* task 2's 🔴 rather than colliding with it. The stop is the same
  rule the constraint states, and this pass never approached it (see §5).
- **`0003-t1` — "byte identity was tried and could not survive a deliberate
  rename."** Relevant to acceptance C's method and worth stating precisely: that
  entry is about *semantic equivalence between two documents from different
  producers*, where byte identity was the wrong instrument. Acceptance C compares
  one renderer against its own previous commit on one fixed payload, which is the
  case byte identity is right for. Different comparison, so no collision — but
  the entry is why C's failure mode was checked rather than assumed.

### 4 — design surface, derived 🔵

Every excerpt below was read from `cd4857d` before any code was written.

**`vsCodeUriFor` and its callers** — `scripts/editor-link.js:75-80`:

```js
    function vsCodeUriFor(node) {
        var abs = absolutePathFor(node);
        if (!abs) { return null; }
        var line = node.data('startLine') || 1;
        return 'vscode://file/' + encodeURI(abs.replace(/^\/+/, '')) + ':' + line + ':1';
    }
```

Callers, found by search rather than recall — and this is what made the shape of
the change: `vsCodeUriFor` is referenced in **three** files, not one.

```
diagnostics.js:8   ['vsCodeUriFor', vsCodeUriFor(node)],
menu.js:39         href: vsCodeUriFor,
menu.js:43         attemptEditorLaunch(vsCodeUriFor(node), reportNoLaunch);
menu.js:54         copyText(vsCodeUriFor(node));
selection.js:156   if (!editorLinkCheck(n)) { uris.push(vsCodeUriFor(n)); }
```

**The `NODE_ACTIONS` binding** — `menu.js:19-45`, with the registry note above it:

```js
    //   check    returns null when applicable, or the reason it is not
    //   href     returns a URI; the item renders as a real link
    //   run      performs the action for that node; the item renders as a button

    var NODE_ACTIONS = [
        {
            id: 'open-in-vscode',
            ...
            href: vsCodeUriFor,
```

**How a setting is declared, typed and consumed.** `settings.schema.psd1`'s
header states the rule this pass had to obey:

> Adding a setting means adding an entry here and a value in `settings.psd1` or
> `theme.psd1`, and nothing else.

Types available: `Number | Integer | Boolean | String | Color | ColorList |
Enum`, plus `ColorMap` and `StyleMap`. `Test-RenderSettingValue.ps1` has working
validators for `Enum` (line 171) and `String` (line 60), so **both settings this
pass adds are pure data changes** — no validator was written. Consumption is
`Resolve-RenderConfiguration` → `ConvertTo-EscapedHtmlJson` → the
`/*__CONFIG__*/` marker, read in the page by `cfgText(key, fallback)`
(`bootstrap.js:44`), which exists precisely for "a string or enum setting".

**How `meta.rootPath` and per-node `path` reach the document.**
`New-RenderDocument` replaces four markers; `bootstrap.js:122` does
`var meta = META || {}`, and `elements.js:99-105` maps the payload onto
Cytoscape data keys `id`, `name`, `kind`, `isExported`, `path`, `startLine`.
The contract says `path` is *already* relative to `meta.rootPath` — which is why
`{relativePath}` is a spelling question and not a path-resolution one.

**Test layout and invocation.** Pester 6 (`Should-Be`, `Should-MatchString`,
`Should-BeCollection`; `Should.DisableV5 = $true`), suites in `tests/`,
`TestHelpers.ps1` dot-sourced. Backlog 10 confirmed live and load-bearing:
`Import-PSGraphRenderUnderTest` prefers `output/` and falls back to `src/`, and
`src/` is **not** importable on its own — the manifest names a `.psm1` the build
composes. Verified by trying it:

```
The module to process 'PSGraphRender.psm1', listed in field 'RootModule' of
module manifest '...\src\PSGraphRender\PSGraphRender.psd1' was not processed
because no valid module was found in any module directory.
```

That is why acceptance C builds its base clone before rendering it.

### 5 — sequencing gate

Honoured. `7d924d8` (acceptance, red) precedes `b6fd92c` (implementation), and
no `src/` or template-set file is touched in `7d924d8`.

---

## 4. The operator ruling that decided the architecture

Precondition 4 surfaced a genuine fork that the prompt did not settle, and it
was put to the operator before any test was written rather than resolved by
this session's preference.

Acceptance B requires "no `vscode://` occurrence beyond the renderer's static UI
strings". Measured against the base, a `none`-mode document would carry:

- **5** occurrences in `Config/strings.psd1` — UI messages about what a blocked
  `vscode://` link looks like. Inside B's carve-out.
- **1** live scheme literal at `editor-link.js:79`. **Code, not a UI string** —
  outside the carve-out.

So B's wording is precise, and two architectures answer it differently:
resolving the mode at **runtime** leaves that literal inert but present, failing
B as worded; resolving it at **assembly** removes it, passing B as worded and
costing a mode-aware extension to template-set assembly.

**The operator ruled: render-time slot selection**, with three reasons on
record — B passes as worded and amending an acceptance to fit an implementation
is the move red-first exists to prevent; task 2's "absent, not stubbed" already
implies it, because a document still carrying URI-construction code is "a stub
with extra steps"; and mode-aware assembly is a seam the 3D template set (item
2) consumes directly, so the cost is prepaid rather than overhead. The operator
also directed that the `strings.psd1` hits sit inside the carve-out as-is, so
**no acceptance text changed.**

---

## 5. Task 2's 🔴 — the contract stop, resolved before code

Every token acceptance A requires was checked against
`contract/viewmodel.schema.json` **before** implementation:

| Token | Field | In contract? |
| --- | --- | --- |
| `{id}` | `data.nodes[].id` | yes — the only required node field |
| `{label}` | `data.nodes[].name` | yes |
| `{path}` | `data.nodes[].path` | yes |
| `{line}` | `data.nodes[].startLine` | yes |
| `{relativePath}` | `data.nodes[].path` | yes — see below |

**No contract change, so the stop did not fire.**

One derivation is worth stating because the prompt's wording and the contract
disagree, and the contract won. The prompt defines `{relativePath}` as "the
node's `path` made relative to `meta.rootPath`". The contract already says
`path` is *"Where the subject lives, **relative to meta.rootPath**"* — so that
derivation is a no-op. `{relativePath}` was therefore implemented as the
**URL-shaped** form of the same value (separators normalised, leading `./`
dropped, each segment escaped) and `{path}` as the payload's own bytes. They
differ on exactly the payloads that matter: the fixtures emit
`private\ConvertTo-SampleName.ps1`, and a forge URL needs forward slashes.

---

## 6. Acceptance — red first

Two harnesses, because they answer different questions.
`tests/LinkMode.Tests.ps1` asserts what is **in** the document;
`tests/browser/link-mode.cjs` asserts what the document **does**, in Chromium.

### Red run, at `cd4857d` (21 cases)

```
Passed=5  Failed=16  Total=21

[-] Acceptance A ... ships the href-template resolver
      Expected [bool] $true, because the hrefTemplate mode script must be the one assembled in, but got: [bool] $false.
[-] Acceptance A ... resolves relativePath as a token
      Expected [bool] $true, because {relativePath} is a token the href template must resolve, but got: [bool] $false.
[-] Acceptance B ... carries no function vsCodeUriFor
      Expected [bool] $false, because the action is absent in none mode, not stubbed, but got: [bool] $true.
[-] Acceptance B ... carries no vscode:// occurrence outside the renderer's static UI strings
      Expected [bool] $false, because none mode constructs no editor URI anywhere in the document, but got: [bool] $true.
[+] Acceptance C ... renders identically to the base with linkMode absent entirely
[+] Acceptance C ... renders identically to the base with linkMode set explicitly to editor
```

**Acceptance C is green in the red run, by design** — it is the no-regression
control, and the prompt requires it green before and after.

### Browser red run, same commit — `probe-red-full.txt`

```
editor         GREEN
hrefTemplate   RED    expected every href to start with https://example.invalid/, got: vscode://file/C:/fixtures/LinkMode/src/Public/Get-Thing.ps1:12:1
none           RED    expected no link action, found 1: vscode://file/C:/fixtures/LinkMode/src/Public/Get-Thing.ps1:12:1
injection      RED    expected every href to start with https://example.invalid/, got: vscode://file/C:/fixtures/LinkMode/src/a%22b%3Cc%3E.ps1:1:1
```

The `editor` row is green here for the same reason: it is the preserved
behaviour.

### Conformance baseline 🔵

Measured with the 0046-repaired runner against PSGraphRender at `cd4857d`, all
four tags — `conformance-base.txt`:

```
ScorePct     : 66.27
CasesRun     : 166
Passed/Failed: 110/56
CasesDefined : 42
```

53 of the 56 failures are one systemic `House style: help` gap, pre-existing and
outside this pass. `CasesDefined = 42` independently reproduces the measurement
behind LEDGER backlog 63 (the Pins figure says 41).

---

## 7. What was built

Two settings, declared as data exactly as the schema header requires:

```powershell
LinkMode         = @{
    Type = 'Enum'; Default = 'editor'
    Values = @('editor', 'hrefTemplate', 'none')
    In = 'Settings'; Group = 'Links'
}
LinkHrefTemplate = @{ Type = 'String'; Default = ''; In = 'Settings'; Group = 'Links' }
```

The mode is chosen by `SlotsBySetting` in `templateset.psd1`, applied in
`Get-RenderTemplateSet`; `New-RenderDocument` now resolves configuration
**before** assembling, because a slot's contents depend on a setting's value.

**Byte identity is what shaped the refactor, and it is the part worth reading.**
Because an `editor`-mode document had to stay byte-identical to `cd4857d`'s,
code could not *move* within the assembled document — only into files
re-inserted at the position it already occupied. So:

- `editor-link.js` → `link/common.js` + `link/editor.js`, split at line 66. The
  split was performed programmatically and asserted lossless before the original
  was deleted, rather than retyped:
  `assert '\n'.join(el[0:66]) + '\n' + '\n'.join(el[66:]) == rd('editor-link.js')`.
- `link/common.js` **keeps a trailing newline on purpose.** That newline is the
  blank line that separated `isEmbeddedContext` from `vsCodeUriFor`, and the
  slot join reproduces the original because of it. It is the one deliberate
  exception to the "a part must not end with a trailing newline" convention in
  `Get-RenderTemplateSet`, and it is why the exception exists.
- The two editor menu entries, the selection action and the diagnostics row
  became slots (`NODE_LINK_ACTIONS`, `SELECTION_LINK_ACTIONS`,
  `LINK_DIAGNOSTIC_ROWS`) filled at their existing positions. The obvious
  design — `var NODE_ACTIONS = LINK_NODE_ACTIONS.concat([...])` in `menu.js` —
  was rejected because it changes bytes that have no business changing.

An empty slot list is a real answer: `none` clears the action slots, which is
how it removes the link actions without removing the menu.

### Green 🔵 — all three modes

```
Passed=21  Failed=0  Total=21
```

Browser, five cases including both SC3 payloads:

```
  link mode editor: vscode://file/C:/fixtures/LinkMode/src/Public/Get-Thing.ps1:12:1
  link mode hrefTemplate: https://example.invalid/src/Public/Get-Thing.ps1
  link mode none: (no link action)
  link mode injection: https://example.invalid/src/a%22b%3Cc%3E.ps1?l=%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E
  link mode injection-template: https://example.invalid/src/a%22b%3Cc%3E.ps1?q="><script>alert(2)</script>&l=%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E
```

Full default build: **143 passed, 0 failed**; `TestBrowser` 6 pages alive;
`PreTag` 9 passed.

---

## 8. Three gaps this opened, and the defect the probe caught

Each was found by a gate rather than by inspection, and each is closed here.

**Slot fragments do not parse alone.** `node --check` rejected 7 files — the
action parts are runs of array elements. `FragmentSlots` in `templateset.psd1`
declares which slots take fragments and `LintJavaScript` wraps them before
parsing. Declared **by slot**, not by listing paths, so a fourth mode's parts
arrive checked instead of arriving unchecked and looking checked.

**`Module.Quality.Tests.ps1` walked `Slots` only.** Files reachable only through
`SlotsBySetting` — two of the three modes — would have shipped unasserted. It
walks both now. This is a hole the pass would otherwise have *introduced*.

**A producer-shaped name in a comment.** The vocabulary check flagged
`href.js names Get-Thing` from an example path in a comment. It scans comments
deliberately ("two script comments named a third command"), and it was right;
the example is `Widget.ps1` now.

**The defect the browser probe caught, which is the one that mattered.**
`{relativePath}` first rendered as `src%2FPublic%2FGet-Thing.ps1`.
`encodeURIComponent` over a whole path escapes the separators — correct for a
query value, useless for the one thing that token exists for, since
`/blob/main/src%2F...` resolves to nothing on any forge. Each token now escapes
for its own shape: a path per segment, everything else whole. **This would have
shipped broken in exactly the case the feature was built for**, and the only
reason it did not is the decision to assert that a link resolves in a browser
rather than that a template string appears in a config blob.

---

## 9. Spot-checks 🔵

| SC | Where it is checked | Result | Red capability, demonstrated |
| --- | --- | --- | --- |
| **SC1** default is invisible | `verify.ps1` check 3, from fresh clones at `cd4857d` | byte-identical outside CONFIG; CONFIG gained exactly `LinkHrefTemplate`, `LinkMode`; nothing else moved | probes P1 + P1b |
| **SC2** nothing machine-identifying | `verify.ps1` check 6, over all 39 changed files | clean; 4 placeholder/doc `vscode://` forms only | probe P4 |
| **SC3** template injection | browser `injection` + `injection-template` | node data escaped; hostile template raw in href and **no dialog, no page error** | escaping disabled in a scratch render → RED |
| **SC4** `none` means none | browser `none` | no anchor, no editor entry, menu still present | editor render under the `none` check → RED |

SC3 and SC4 red demos — `sc-red-demos.txt`:

```
SC3-red-escaping-disabled  RED (correct)
     href carries an unencoded character: https://example.invalid/src/a%22b%3Cc%3E.ps1?l="><script>alert(1)</script>
SC4-red-editor-as-none     RED (correct)
     expected no link action, found 1: vscode://file/C:/fixtures/LinkMode/src/Public/Widget.ps1:12:1
```

**SC3's two halves are different claims and are recorded as such.** Token values
are escaped because a producer's label is untrusted. The template is *not*
escaped — it is configuration and has to keep its `://`, `?` and `&` to be a URL
— so the second case asserts the weaker, true thing: whatever the template
contains, the result is assigned to an anchor's `href` **property** rather than
interpolated into markup, so nothing executes. The probe watches for dialogs and
page errors, and both stayed empty.

---

## 10. Verify 🔵

`verify.ps1` — six checks, six probes, scratch-only writes, run twice against
`3f2ec85`.

```
VERIFY 0047: PASS - every check re-derived and agreed.             (exit 0)
VERIFY 0047: PASS - every check re-derived and agreed.  -FailCheck (exit 0)
```

Conformance, both scores **measured in that run**, not quoted:

```
     base: 66.27% over 166 case(s)
     head: 66.27% over 166 case(s)
  [ok  ] head conformance is not below base - 66.27 -> 66.27
  [ok  ] no assertion that passed at base fails at head - none
```

**A probe disproved a claim this pass had written down, and that is the most
useful thing in this record.** P1b originally asserted that flipping the shipped
default would slip past the byte comparison "because the mode is one value in
one blob" — the same claim appeared as a comment in `tests/LinkMode.Tests.ps1`.
It is true of a design that resolves the mode in the browser and **false of this
one**: assembly picks the *files*, so a flipped default moves the document body
as well as CONFIG.

```
[ok  ] P1b: the byte comparison catches a flipped default as well - the body differs too:
       line 2225: base [    // vscode://file/{path}:{line}:{column}. Kept separate from the action that]
                  head [    // No node link at all. Not a disabled action and not a link that goes]
```

Both the probe and the test comment were corrected to say what is true. The
byte comparison is stronger than it was credited with being; the CONFIG check
still earns its place, because it pins *which* value the default is.

Three defects in the verifier itself were found by running it, and are recorded
because each produced a *misleading* signal rather than an obvious one:

1. `Get-FirstDifference` reported `line counts differ: base 3174, head 3174`.
   Every line was equal and the raw strings were not — a line-ending
   difference. `ConvertTo-Json` emits CRLF on Windows while `.gitattributes`
   stores LF, so comparing a fresh render against a checkout measures the
   checkout. Check 4 now normalises and says so in its own name.
2. The conformance runner was invoked with `pwsh -File`, which passes every
   argument as one string, so the tag array arrived as
   `"Universal,Repository,HouseStyle,RequiresBuild"` and the runner's own
   `ValidateSet` rejected it against a set that is literally a comma-join of it.
   Reads like a bug in the runner; was a bug in the call.
3. StrictMode plus an empty array returned from a function: `@()` unrolls to
   `$null` and `.Count` then throws.

`-HeadRef` exists because of the ordering task 6 requires: verify clones the
remote, and `main` does not carry this pass until task 8. It defaults to `main`
— what a later reader wants — and was run with the branch for the release. It
also refuses to run when head and base resolve to the same commit, because six
green checks over an unchanged tree is the most confident wrong answer this
script could give.

---

## 11. Release 🔵

**Task 6's ordering was used, and it worked.** Verify green + falsification both
ran **before** the tag, against the exact commit the tag would name.

```
tag:  3f2ec85
tip:  3f2ec85
```

The tag-behind-tip pattern — recorded at 0033, 0034 and again as 0046-stop F3 —
is **broken this time**. Version checked against the repo's tag list at run time
(`v0.13.0` latest) and against LEDGER's version line (`PSGraphRender: v0.13.0`);
they agreed, so no 🔴, and `v0.14.0` is the next.

Commits, `cd4857d..3f2ec85`:

```
7d924d8 Pass 0047: the acceptance tests, committed red before the repair
b6fd92c Pass 0047: link mode, resolved when the document is assembled
68a34dc Pass 0047: the examples earn the feature
3f2ec85 Pass 0047: v0.14.0 - docs, changelog and the version
```

44 files changed, 4,675 insertions, 125 deletions.

---

## 12. Deviations

**1. `verify.ps1` gained a `-HeadRef` parameter the prompt did not describe.**
Task 6 wants verification before the release commit; task 8 lands `main`
afterwards. A verifier that only reads `main` therefore cannot run when task 6
needs it. Default is `main`; the branch was passed for the release runs. Recorded
rather than hidden because it means the tagged commit was verified through the
*branch* ref, not through `main` — the same commit either way (`3f2ec85`).

**2. Acceptance C compares the CONFIG block separately from the rest.** The
prompt says "byte-comparable modulo already-declared varying fields". There are
no already-declared varying fields — `New-RenderDocument` is fully
deterministic; the only `Get-Date` in `src/` is in `New-RenderDocumentPath`,
which does not touch the document. But *any* implementation of this feature must
add keys to CONFIG, since the setting has to reach the page. So the permitted
delta was drawn at exactly what is unavoidable: everything outside CONFIG is
byte-identical, and CONFIG may gain the two new keys and change nothing else.
Both halves are asserted. The `menu.js` delta was *avoidable* and so was not
permitted — which is what forced slot composition rather than a `concat`.

**3. Acceptance C's comparison also excludes the STRINGS block, and this pass
adds three strings.** `Get-DocumentCode` drops STRINGS because acceptance B's
carve-out is that block. That leaves added UI strings unasserted by C. Stated as
a known limit of the control rather than papered over: the three added strings
(`MenuOpenLink`, `MenuCopyLink`, `ReasonNoTemplate`) are additive and no existing
string changed, but C is not what proves it.

**4. Two committed test/probe files were edited after their red run.** Both were
harness corrections, not acceptance changes: `New-ConfiguredTemplateSet`
*appended* settings, which becomes a duplicate hash key once `LinkMode` ships —
a parse error, not an override, whose symptom is every case silently rendering
the default mode and the suite reporting the feature missing when it is present.
And one comment stated the P1b falsehood above. The assertions themselves are
unchanged from `7d924d8`.

**5. `Module.Quality.Tests.ps1` was tightened, which is a test change inside a
pass that owns an acceptance.** It walks `SlotsBySetting` now. This closes a
coverage hole the pass itself would have opened, so it is part of the work
rather than an adjustment to make the work pass.

**6. `tools/shoot.cjs` gained a `menuAt` step, and `editor-links.png` was
re-shot.** Task 4 asks for a screenshot "per the examples-index form"; the
existing form is a plain page shot, which for a *links* example showed nothing
about links. Both link screenshots now show the open menu. The 0043 example's
HTML is unchanged in substance — only its title and its picture — and it remains
`editor` mode with the placeholder `rootPath`, as task 4 requires.

**7. `docs/worklog/v0.14.0.md` was added, which task 5 does not list.** The
worklog series was opened at v0.13.0 stating "worklogs record a release", and
this is the first release since. Judgment call, recorded as one.

**8. `examples/input/links-viewmodel.json` was edited — title and version.** The
shared payload's title said "open a node's source in your editor", which is
false on the GitHub example, and its `version` said `0.13.0` while describing
this module's own functions. Per-example titles now come from the build matrix.
This is a committed input pass 0043 produced; changing it changes
`editor-links.html`, which is why it is called out.

**9. The pass base is `cd4857d`, not the `v0.13.0` tag, everywhere.** Applied as
the prompt's F3 amendment directs — including inside `verify.ps1`, whose
`-BaseRef` default was corrected from the tag to the SHA after the first draft
used the tag out of habit.

**10. Nothing was found that required a contract change**, so task 2's 🔴 never
fired and no decision was raised. Recorded because the stop existing and not
firing is itself the evidence that the tokens were checked first.
