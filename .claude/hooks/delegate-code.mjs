#!/usr/bin/env node
// PreToolUse on Edit and Write: who writes production code during a card.
// - A `builder` or a `grunt` does, in its own context, from card.md.
// - The main thread does only when `risk.json` says `size: small` and a commit already holds the card's tests
//   (`@<ID>-S<n>`): RED comes before the code. On a `large` card, or before that commit, it launches the `builder`.
// - A `designer` writes only the files `## Tasks` marks `(presentation)`.
// - Any other subagent (a scout, a runner, an oracle) writes it without the card in front of it: refused.
// A subagent's hook input has `agent_id` and `agent_type`; the main thread's has neither.
// Measured: in three runs the code was written by the main thread with 90 to 410 thousand tokens of context re-read on
// every request.
// Contract: exit 0 lets it through; exit 2 blocks and Claude reads stderr. On its own error it lets it through: it is a
// saving, the guards that protect the card are others.
import { readFileSync } from 'node:fs';

try {
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
  const card = await import('../tools/card.mjs');
  await card.delegateToRepo(import.meta.url, raw, input);
  if (input.agent_id && ['builder', 'grunt'].includes(input.agent_type)) process.exit(0);
  const designing = input.agent_id && input.agent_type === 'designer';
  const path = input.tool_input?.file_path ?? input.tool_input?.notebook_path;
  if (!path) process.exit(0);
  const root = card.rootOf(path);
  if (!root || !card.isProductionPath(root, path)) process.exit(0);
  const cardDir = card.currentCard(root);
  if (!cardDir) process.exit(0);
  if (designing) {
    const { readCard, rolesOf } = await import('../tools/card-doc.mjs');
    const { roleFor } = await import('../tools/gate-checks.mjs');
    if (roleFor(rolesOf(readCard(cardDir) ?? ''), path.replaceAll('\\', '/')) === 'presentation') process.exit(0);
    process.stderr.write('The `designer` writes only the files `## Tasks` marks `(presentation)`: not rules, data or tests. A change that needs one goes to the Log as `OUT · <what>`.\n');
    process.exit(2);
  }
  if (card.actsAsMain(input)) {
    const risk = (await import('../tools/card-doc.mjs')).riskOf(cardDir);
    if (risk?.size === 'small' && card.redCommitted(root, cardDir)) process.exit(0);
    const why = !risk ? 'there is no risk.json yet: `node .claude/tools/risk.mjs specs/<card>` classifies the card'
      : risk.size === 'small' ? 'the card is small, and no commit holds its tests yet (`@<ID>-S<n>`): write them, run them red and commit them first'
        : 'the card is large';
    process.stderr.write(`The main thread does not write production code here: ${why}. A large card goes to the \`builder\` with card.md, its task IDs and the gate command.\n`);
    process.exit(2);
  }
  process.stderr.write('Only the `builder` and the `grunt` write production code during a card; not another subagent. Launch the `builder` with the path of card.md, its task IDs and the gate command.\n');
  process.exit(2);
} catch {
  process.exit(0);
}
