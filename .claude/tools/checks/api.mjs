// Module `api`: what a card that adds or changes HTTP routes leaves. Loaded by required.mjs only when
// the module is on; it imports nothing from the other modules.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { declaredUnchanged, git, ROUTE } from '../card.mjs';

// A file with routes brings the API contract into the diff (W8).
const apiContract = ({ root, plan, production, inDiff }) => {
  const contracts = git(root, ['ls-files']).stdout.split('\n').filter((f) => /(^|\/)(openapi|asyncapi)[^/]*\.(ya?ml|json)$|\.graphql$/.test(f));
  return contracts.length && production.some((f) => ROUTE.test(readFileSync(join(root, f), 'utf8'))) &&
      !contracts.some(inDiff) && !declaredUnchanged(plan, 'API contract')
    ? [`${contracts[0]} in the diff: the card touches a file with routes (W8), or declare \`- API contract: unchanged — <why>\``]
    : [];
};

// A hot path carries its load test, and the test ran and passed (O22, R10).
const hotPathLoadTest = ({ plan, map, passed }) => {
  if (!map.some((l) => /\bhot-path\b/i.test(l))) return [];
  const block = (plan.split(/^## /m).find((s) => s.startsWith('Verification')) ?? '').match(/```[^\n]*\n([\s\S]*?)```/)?.[1] ?? '';
  const load = block.split('\n').map((l) => l.trim()).find((l) => /^load\s*:/.test(l));
  if (!load) return ['a `load:` line in the plan\'s ## Verification: the File map names a hot-path (O22)'];
  const command = load.slice(load.indexOf(':') + 1).trim();
  return passed(/./, [0]).some((r) => r.command === command || r.command.includes(command))
    ? []
    : [`the load test ran and passed through once.mjs: \`${command}\` (R10)`];
};

export const structure = [apiContract, hotPathLoadTest];
