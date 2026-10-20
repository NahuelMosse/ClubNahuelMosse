# Step 1 · The whole card, frozen

## At a glance

`/card <ID>` fetches the whole card over MCP —description, comments, attachments, links— and writes
`card.snapshot.md` in `specs/<ID>-<slug>/` with `sources:` and `not_read:`. It is born `status: proposed` and
is never edited: a changed card gets a new snapshot, and what the change affects is computed, not remembered.
The commit goes to `ambiguities.md` as `<ID>-AMB-00 · <date> · snapshot · frozen at <hash>`.

**Closes with:** `git diff --name-only <snapshot-commit>..HEAD -- specs/<feature>/card.snapshot.md` lists nothing.

Most broken:
- Coding from a summary or memory; with no MCP there is no requirement.
- Card files are created with `Write`, one per call; the shell's `>>` only appends an event line.
- What takes long and depends on nothing (installs, browsers) starts now, in the background.
- A card that names another language, currency, time zone or right-to-left text states the i18n level in the plan.
- A requirement that arrived as text is frozen the same: `sources:` where and when; `not_read:` comments, attachments, links.
- The first card of a repo creates the scaffolding and says so; what did not run for lack of it is `could not run`.
- A commit with a lone subject is refused (`commit-why.mjs`): every commit carries a second `-m` with the why.

Read the rest only when it is the first card of a repo (scaffolding), the card changed after its snapshot, or the requirement arrived as text with no Jira.

## Full rules

`/card <ID>` creates the folder `specs/<ID>-<short-slug>/` —it does not exist yet, this step
creates it— and fetches via MCP the description, comments, attachments and Confluence links
—never from memory— and writes `card.snapshot.md` there with two lists: where each thing came
from (`sources:`) and what exists and you could not read (`not_read:`). If the card changes, the
old one is renamed with its date and a new one is written. It is never edited. **And what the
change affects is computed**: which scenarios of the new snapshot differ from the old one, which
tests carry those tags and which assumptions rested on what changed. It is listed, not deduced
from memory. On commit, `/card` records the commit hash in `ambiguities.md` as an event:
`<ID>-AMB-00 · <date> · snapshot · frozen at <hash>`.

The card is identified by the `card:` field of the snapshot's frontmatter, not by the folder
name. If spec-kit creates its own numbered folder (`001-`), `card.snapshot.md` and
`ambiguities.md` are moved to that folder and work continues there.

→ **Validate:** `git diff --name-only <snapshot-commit>..HEAD -- specs/<feature>/card.snapshot.md`
must list nothing. The commit comes from the `AMB-00` event in `ambiguities.md`, not from the
session's memory. If something shows up, the snapshot was touched after being frozen: revert it
and re-extract.

**Files of the card —snapshot, `ambiguities.md`, tests— are created with the `Write` tool, one file
per call.** Never with a heredoc or a redirection in the shell: `guard-shell` rejects it. The shell's
`>>` is only for appending one event line to `ambiguities.md`.

**What takes long and depends on nothing starts here, in the background**: installing
dependencies, downloading browsers, setting up the scaffolding. It runs while the ten questions
are answered, and by step 4 it is ready. Waiting for it later is in the foreground, never with
`sleep` loops.

**If the card names another language, country, currency, time zone or right-to-left text**, the
plan states the i18n level and the locales (module i18n: `## Step 1` of `steps/m-i18n.md`); if the
card does not say which locales, it is an ambiguity.

**Each active module, its part:** `## Step 1` of `steps/m-<module>.md` for the modules of
that are on (`node .claude/tools/kit.mjs status`), when they have one. The first card of a repo also reads
that output: which modules were chosen at install, and why the others are off.

**What the repo already has is used, not redone.** If there is already a suite, a linter,
`design/line.md` and its tokens, the card works with that: it extends it if something is missing
—a token, a component, a rule— and never rewrites it. The scaffolding is the first card's work;
from the second on, each card pays only for its own.

## The first card of a repo

**If it does not exist, it is created — do not stop.** In a project that starts from zero, none
of the things the method validates exist: no tests folder, no suite, no command that runs it, no
`specs/`. **The first card of a new repo creates the scaffolding as part of its work**, and says
so in the closing comment: what there was and what had to be set up. What you **cannot** do is
take as verified something that did not run because the scaffolding was not there: that is *could
not run*, and it does not close.

And it leaves written in the plan the decisions that are most expensive to undo —the *Design ×
Start* cell of `.claude/MATRIX.md`—:

- **Doctor first**: `node .claude/tools/doctor.mjs` says what the machine lacks; what is missing
  goes to a background install or is declared `could not run`.
- **The stack profile**: `.claude/stacks/<stack>.md`. If there is no proven profile for the
  stack, start from `others.md` and confirm each command in this card.
- **The ADR of the stack and the hosting** with `.claude/templates/adr.md`; the system design
  with `.claude/templates/system-design.md` (`docs/technical/system-design.md`) —both only if the card
  changes the architecture: a new module, process, store or external dependency, or a change of
  boundary; a form over a stack that already exists changes none—; the policy for
  dependencies, licenses and versioning, from `.claude/reference/dependencies.md`. The modules add
  their own (each one's `## Step 1`):
  module infra, `.claude/templates/runbook.md` and `.claude/templates/infra-cost.md`;
  module docs, `.claude/templates/docs.md`.
- **The layers and who knows whom**, which is what the dependency test later asserts.
- **What a business enumeration looks like**: where it lives, what it carries —the name yes, the
  appearance no— and how it is walked.
- **The `paths:` of `.claude/rules/`**, adjusted to the paths just invented.
