---
description: Checks the card against its card.md, writes closing.md from the gate, the judge and the cost, and publishes the branch, the PR and the closing comment using only what they said.
argument-hint: <CARD-ID>
---

Card: `$1`.

1. `node .claude/tools/close.mjs` runs nine checks and writes `specs/<card>/closing.md` between its `close.mjs:begin` and `close.mjs:end`
   markers: L1 intact · every `S#` has a test · every tag is a spec · each ASM tagged or declared uncovered · no tagged test touched since
   RED · the diff and `## Tasks` agree · the gate green on this code · the plan judge (`judge.md` with every ACT closed or declared, when
   `risk.json` says high) · `required.mjs`. Paste its raw output. `--check` writes nothing; a rerun regenerates only its block.
2. Anything `failed` or `could not run` is not closed over: fix it and rerun. A check is not turned off to
   close. A step that cannot run (no remote, `gh`, Jira, CI) stays in `## Could not run`; nothing is invented.
3. Before writing under the block, list every server, port, container and shell you started and bring it down by PID
   (`node .claude/tools/app.mjs down` for the shared app). Never by process name.
4. Publish, in order (`publish.mjs` lets out exactly these): `git push -u origin <ID>-<slug>`, `gh pr create --title "<ID> · <title>"
   --body-file specs/<card>/closing.md`, CI in the background (`gh pr checks --watch > .validation/ci.log 2>&1`, awaited with
   `wait.mjs`), `gh pr comment <n> --body-file .validation/ci.md`, and the closing comment on Jira with the PR link, once. Never main,
   `--force` or a merge. With no remote, `## Could not run` gets `publish: could not run, no remote configured`; the card closes
   locally all the same and is not given as passed.
