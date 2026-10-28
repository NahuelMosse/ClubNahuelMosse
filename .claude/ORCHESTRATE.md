# One card or several

The method runs the same in two modes. Which one is yours comes from what you were asked, before your first tool call.

| You were asked for | Your mode |
|---|---|
| One card: `/card <ID>`, one Jira key, one requirement pasted | **You run it**, steps 1 to 5 of `METHOD.md`, in this session. |
| Several: a list of keys, a board or a filter («the To Do», «the sprint»), «these three» | **You orchestrate**: one `card-runner` per card runs it; you never run a card's steps in your own context. |
| You are a `card-runner` | One card, always: the one your prompt names. |

A request that starts as one card and grows («and also PRJ-12») becomes orchestration from that moment: the card already
in progress stays yours until its close, and the new one goes to a `card-runner`.

## Orchestrating

1. **One worktree per card,** from the up-to-date default branch: `git worktree add ../<repo>-<ID> -b <ID>-<slug> origin/<default>`.
   Cards that touch the same files, or one that needs another merged, run one after the other; the rest, in parallel, at most
   three at once unless the person says otherwise (the machine and the prompt cache are shared).
2. **One `card-runner` per card,** launched with `run_in_background`, its prompt only the card key and the absolute path of
   its worktree. It reads the method itself, asks its one round of questions on Jira and publishes its own PR.
3. **End your turn.** Each runner's notification wakes you; the person can talk to you meanwhile. Pass each report on in one
   line per card: key, passed / failed / could not run, PR and whether it merged, what waits for a person.
4. **You do not repair a card.** A runner that stopped (turn or context cap, a crash) is relaunched once with the same key and
   worktree, plus `continue from specs/<card>/handoff.md`; a second stop goes to the person as is. A question about a card
   goes to its runner by `SendMessage`, which resumes it with its context.
5. **Close the worktree** once its PR merged: `git worktree remove ../<repo>-<ID>` (never `--force`: it may hold the only
   copy of unpublished work).

Each card's `closing.md` carries its own `Cost:`: with worktrees, only the messages that name the card or run in its
checkout count, and its runner and builders whole.
