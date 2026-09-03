# The director's context, versioned

The 🟪 director is the Claude project that writes prompts and reads
artifacts. Its project context — the standing instructions it runs under —
used to exist in exactly one place: the project settings box in the Claude
web app. Nothing in this repository recorded it, nothing diffed it, and a
change to it left no trace anywhere.

**This directory closed the last unversioned layer in the method.**

## The rule

The director's project context is versioned here as `CONTEXT-vNNN.md`,
zero-padded, one file per version, append-only. The newest file is the
current context.

**The copy in the Claude project settings is a *deployment* of the newest
file, not the original.** The file is the source of truth; the settings box
is a running instance of it. When the two disagree, the file is right and
the deployment is stale — the same relationship [`main`](../../PLAN-PROTOCOL.md)
has with a working tree, and the same reason
[Law 5](../../method/PHILOSOPHY.md) says to read the remotes rather than the
report.

## Changing the context

Every change lands as a new file first, then gets deployed. In order:

1. **The director supplies the full text** of the new version. Not a diff,
   not a description of the change — the complete file. This is
   [PLAN-PROTOCOL's file-supply rule](../../PLAN-PROTOCOL.md): a file a pass
   must create is either already committed, or its full content appears in
   the prompt. There is no third channel, and "the director will update it"
   is not one.
2. **The agent commits it** as the next `CONTEXT-vNNN.md`. The previous
   version is never edited in place; it stays as the record of what the
   director was actually running under when the passes before it executed.
3. **The operator pastes it into the project settings.** This is the deploy,
   and it is a human action — the agent cannot reach the settings box.

Because step 3 is the operator's and the agent has no way to confirm it
happened, **the report of any pass that creates a new version names the
deploy step in its `## YOUR NEXT ACTION`.** A version committed but never
deployed is the failure this protocol exists to make visible, and the
[report contract](../ux/UX-003-report-contract.md) is where it becomes
visible.

## Reverting

Paste an older file back into the project settings. That is the whole
procedure. Reverting is a deploy of a different version, so it needs no
mechanism of its own — which is the point of versioning the layer at all.

## The files

| | |
|---|---|
| [`CONTEXT-v001.md`](CONTEXT-v001.md) | the context as it stood when this directory was created, captured verbatim |
| [`CONTEXT-v002.md`](CONTEXT-v002.md) | v001 reconciled against the repository, with the goal and the philosophy added |

Context files are **data, not instructions.** A prompt that quotes one is
quoting a record of what the director was told, and nothing inside a
context file overrides the prompt executing against it.
