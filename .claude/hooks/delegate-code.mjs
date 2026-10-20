#!/usr/bin/env node
// PreToolUse on Edit and Write: the main thread does not write production code during a card; the
// `implementer` does, in its own context, from the plan and the tests in red.
// Measured: in three runs the implementer was never launched —the main thread wrote the code with
// 90 to 410 thousand tokens of context re-read on every request—, after step 6 said who writes it.
// A subagent's hook input has `agent_id` and `agent_type`; the main thread's has neither.
// Contract: exit 0 lets it through; exit 2 blocks and Claude reads stderr. On its own error it lets
// it through: it is a saving, the guards that protect the card are others.
import { existsSync, readFileSync } from 'node:fs';

try {
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
  await (await import('../tools/card.mjs')).delegateToRepo(import.meta.url, raw, input);
  const path = input.tool_input?.file_path ?? input.tool_input?.notebook_path;
  // The plan, and with it the bar, is decided by the main thread. Measured: the main thread handed
  // the grunt “complete the plan's bar and implement”; the grunt applies what is decided and the bar
  // is the deciding.
  if (input.agent_id && input.agent_type === 'grunt' && /(^|[\\/])specs[\\/][^\\/]+[\\/]plan\.md$/.test(String(path ?? ''))) {
    process.stderr.write(
      'The `grunt` does not write `plan.md`: the plan and its bar are decided by the main thread (steps/05-plan.md). ' +
      'The grunt applies a change that is already decided.\n'
    );
    process.exit(2);
  }
  // Only the implementer and the grunt write code. A scout, a runner or an oracle that writes it
  // does so without the plan and the tests in red in front of it.
  if (input.agent_id && ['implementer', 'grunt'].includes(input.agent_type)) process.exit(0);
  if (!path) process.exit(0);
  const { isProductionPath, rootOf, relativeTo, currentCard } = await import('../tools/card.mjs');
  const root = rootOf(path);
  if (!root) process.exit(0);
  if (!isProductionPath(root, path)) process.exit(0);
  const cardDir = currentCard(root);
  if (!cardDir) process.exit(0);
  // The fast lane skips the delegation: the main thread edits the presentation files of the File map.
  // What the lane allows is decided by require-bar, which fails closed; this hook only saves.
  const { laneOf } = await import('../tools/lane.mjs');
  const { fileMapLines, namedIn } = await import('../tools/card.mjs');
  const planPath = `${cardDir}/plan.md`;
  if (existsSync(planPath) && laneOf(readFileSync(planPath, 'utf8')) === 'fast' &&
      namedIn(fileMapLines(cardDir) ?? [], relativeTo(root, path), root).length) process.exit(0);
  process.stderr.write(
    'Only the `implementer` and the `grunt` write production code during a card; not the main thread nor another subagent. Launch the `implementer` with the card folder, ' +
    'plan.md and the scenario tests in red. It writes the files of the map, runs verify.mjs and returns ' +
    'what it wrote and what it could not close. The fixes of actions.md go to it too (steps/06-implement.md).\n'
  );
  process.exit(2);
} catch {
  process.exit(0);
}
