---
description: Freezes the requirement into a snapshot and lists the ambiguities. Fetches it from Jira over MCP if there is a card; if it arrived as text, freezes that text.
argument-hint: <CARD-ID>
---

Card: `$1`.

## At a glance

Fetch the whole card (Jira over MCP: description, all comments with author and date, attachments, linked pages; text that
arrived in the prompt is the source, frozen all the same, with `not_read:` for what has no channel). Write, with `Write`, whole,
`specs/$1-<slug>/card.snapshot.md` from `.claude/templates/card.snapshot.md`: `sources:` never empty, `not_read:` present,
`status: proposed`, one `- [ ] $1-H<NN>-<NN> — <title>` line per scenario (two digits), the card transcribed, not interpreted.
Write the folder name alone on one line to `specs/.current`; switch to branch `$1-<slug>` if on the default branch. Answer the
ten questions (`steps/02-ambiguities.md`), commit the snapshot alone and append
`$1-AMB-00 · <date> · snapshot · frozen at <hash>` to `ambiguities.md`.

**Closes with:** `git diff --name-only <hash>..HEAD -- specs/$1-<slug>/card.snapshot.md` lists nothing; report the scenario count,
the open ambiguities and `not_read:`.

Read the rest only when the card changed after its snapshot (the old one is renamed `card.snapshot.<old-date>.md`).

## 1 · Fetch, never remember

**If `$1` is a Jira card:** fetch over the Atlassian MCP the whole card; **all** the comments with
author and date; **all** the attachments —open the ones you can—; the linked Confluence pages. If
the MCP does not respond, stop and say so: without the requirement there is no card. No memory,
no summaries.

**If the requirement arrived as text** —pasted in the prompt, an email, a message— **that text is
the source and it is frozen all the same.** There is nothing to fetch and you do not stop:
`sources:` says where it came from, and `not_read:` lists what could not be consulted because the
channel does not exist —comments, attachments, Confluence—. The rest of the command stays
identical.

*Not having Jira is not not having a card. Stopping here leaves the method with no input in any
project that does not have a board yet.*

## 2 · Write the snapshot

Create the folder `specs/$1-<short-slug>/` —it does not exist yet, this step creates it— and write
`card.snapshot.md` there, with the template `.claude/templates/card.snapshot.md`. The plan
(`plan.md`) goes in this same folder; if `/speckit-plan` is invoked in step 5 and creates its own,
the files of this method are moved there at that point. Write the folder name, alone on one line, to
`specs/.current`: the hooks take the card in progress from it.

- **The snapshot is created with the `Write` tool, whole, in one call.** Not with a heredoc, `cat >`
  or `echo >` in the shell: `guard-shell` rejects it and the file would be generated again.
- `sources:` cannot be empty. `not_read:` can be empty but cannot be missing: what exists and you
  could not open is declared there.
- `status: proposed` — you wrote it, and it stays so: the review is the PR's.
- Under `## Scenarios`, one line per scenario: `- [ ] $1-H<NN>-<NN> — <title in the card's
  language>`. Always two digits: `H01`, not `H1`.
- Transcribe the card; do not interpret it. What gets resolved, gets resolved in the plan.

If a snapshot already exists and the card changed: rename it to `card.snapshot.<old-date>.md`
and write a new one. **Never edit it.**

**The card's branch.** Work goes on a branch named like the folder, `$1-<short-slug>`: if HEAD is on
the default branch, `git switch -c $1-<short-slug>` before the first commit; if it is already on a
branch that starts with `$1-`, stay. The close pushes that branch and nothing else
(`.claude/AUTONOMY.md`).

## 3 · Ambiguities

**Do not reread "looking for them": answer the ten questions** of
`.claude/steps/02-ambiguities.md`, which is where they live, with the format of the
`## The ten questions` block and of the events under `## Events`. No row is left unanswered, not
even the ones the card does answer. Do not resolve any ambiguity on your own: all of them go in
**one** comment on the card, posted without asking approval (invariant 5 of `CLAUDE.md`; how, in
`.claude/steps/02-ambiguities.md`). That is the only round: after it, a doubt is an `ASM-NN`.

## 4 · Close the step

Commit the snapshot alone, keep the commit hash and add it as an event in `ambiguities.md`:

```
$1-AMB-00 · 2026-09-01 · snapshot · frozen at <hash>
```

Verify:

```
git diff --name-only <hash>..HEAD -- specs/$1-<short-slug>/card.snapshot.md
```

It cannot list anything. Report: how many scenarios, how many open ambiguities, what ended up in
`not_read:`. If you could not run some command, say so and do not go on.
