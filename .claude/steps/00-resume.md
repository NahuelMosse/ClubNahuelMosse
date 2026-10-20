# Resuming a card that was cut

## At a glance

A cut card resumes from the disk, not from the summary: what is on disk wins, and what is not on disk was
not done. `node .claude/tools/where.mjs` names the card, the step, the next command and the minutes since
the snapshot. Then read, in this order: the whole snapshot, `ambiguities.md`, `plan.md`, `git log` and
`git status`, `actions.md`, and `node .claude/tools/required.mjs`.

- A process is checked by its PID and stopped only if it is yours; never by name.
- A quiet subagent: `SendMessage` at 20 minutes, `TaskStop` at 30, launched again with its context.
- A cut conductor: a fresh one gets `specs/<card>/handoff.md` plus its `handoff-conductor.md`, if it wrote one.

Read the rest only when the order of reading or the fast lane is not clear.

## Full rules

A compaction or a crash cuts a card in the middle. What is on disk is what happened; what the
summary remembers is a hypothesis. **What is on disk wins; what is not on disk was not done.**

Read in this order, and nothing before:

1. `node .claude/tools/where.mjs`: the card, the step it stood at, the next command, the minutes since the
   snapshot —the time cap does not restart on resuming— and the `*.pid` files of the cut session. A
   process is checked by its PID; it is never killed by name, and only if it is yours.
2. `card.snapshot.md`, **whole**: invariant 1 asks for the requirement to be read again in this session,
   not recalled from the summary.
3. `ambiguities.md`: the events, the last state of each `AMB`, `ASM` and `OUT`, the hashes, and whether
   the questions were posted (`ASK`: they are not posted again) and the closing published (`CLOSE`).
4. `plan.md`.
5. `git log --oneline <card-start>..HEAD` and `git status`: what was committed and what was left half done.
6. `actions.md`, if it exists.
7. `node .claude/tools/required.mjs`: what is still missing on the code as it is now.

**A quiet subagent is not left waiting.** If a subagent changes no file and sends no notification in
20 minutes, the main thread sends it a `SendMessage`; at 30 minutes, `TaskStop` and it is launched
again with its context (the plan, its group, what is already on disk). It does not poll `git status`
in a loop: one look when the 20 minutes are up.

Then go on from the step `where.mjs` named. A card in the fast lane resumes through the steps of
`.claude/steps/fast-lane.md`. If the disk and the summary disagree, the disk is right: write down what
the summary claimed that is not there, and do it again.

Why each rule of steps 0 to 4 is there: `.claude/reference/why-card-start.md`.
