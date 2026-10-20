#!/usr/bin/env node
// inspectors.mjs — run from the repo root, with a card in progress.
//
// How many inspectors the card takes and which areas each one gets, counted from the plan's bar:
// the criteria that are judgment (column “How” = J in criteria.md) and that the bar did not answer
// as “not applicable”. One per 40, grouping whole areas. The mechanical ones do not count:
// verify.mjs runs them.
// Measured: a card with one text on one screen launched three inspectors because the rule said “one
// per 40” and nobody counted; the same with a single one.
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { currentCard } from './card.mjs';
import { active, offCriteria } from './kit.mjs';

export const ORDER = ['R', 'D', 'K', 'E', 'T', 'S', 'P', 'O', 'I', 'C', 'A', 'V', 'W'];

export const inspectors = (root) => {
  const cardDir = currentCard(root);
  const criteria = join(root, '.claude', 'reference', 'criteria.md');
  const plan = cardDir && join(cardDir, 'plan.md');
  if (!plan || !existsSync(plan) || !existsSync(criteria)) return null;

  // The criteria of a module that is off are not judged: the bar answered them with its one line.
  const skipped = offCriteria(root);
  const judgment = [...readFileSync(criteria, 'utf8').matchAll(/^\| ([A-Z]\d+) \|[^|]*\| ([TCAJ]) \|/gm)]
    .filter((m) => m[2] === 'J' && !skipped.has(m[1])).map((m) => m[1]);
  const bar = (readFileSync(plan, 'utf8').split(/^## /m).find((s) => s.startsWith('Bar')) ?? '').split('\n');
  const notApplicable = (id) => bar.some((l) => /not applicable/i.test(l) && (
    new RegExp(`(^|[^A-Za-z0-9])${id}([^0-9]|$)`).test(l) ||
    [...l.matchAll(/\b([A-Z])(\d+)\s*[–-]\s*\1?(\d+)\b/g)].some(([, a, from, to]) => id[0] === a && +id.slice(1) >= +from && +id.slice(1) <= +to)));
  const applicable = judgment.filter((id) => !notApplicable(id));

  // A grade without inspector (poc) judges nothing: the bar says so in its line `off by grade`.
  const { grade, exempt } = active(root);
  if (exempt.without.has('inspector')) return { applicable: applicable.length, count: 0, groups: [], grade };

  const byArea = Object.fromEntries(ORDER.map((a) => [a, applicable.filter((id) => id[0] === a).length]));
  const count = Math.max(1, Math.ceil(applicable.length / 40));
  const target = applicable.length / count;
  const groups = [[]];
  let inGroup = 0;
  for (const a of ORDER.filter((x) => byArea[x])) {
    if (inGroup >= target && groups.length < count) { groups.push([]); inGroup = 0; }
    groups.at(-1).push(a);
    inGroup += byArea[a];
  }
  // The IDs of each group, which the prompt of its inspector carries: it prints their rows with `bar.mjs <IDs>`.
  return { applicable: applicable.length, count: groups.length, groups, ids: groups.map((g) => applicable.filter((id) => g.includes(id[0]))) };
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const r = inspectors(process.cwd());
  if (!r) {
    console.error('A card in progress with plan.md and .claude/reference/criteria.md is required.');
    process.exit(2);
  }
  if (!r.count) {
    console.log(`0 inspectors: the grade ${r.grade} has none, and neither does a reviewer; what the card asked is answered by its tests.`);
    process.exit(0);
  }
  console.log(`${r.applicable} applicable judgment criteria → ${r.count} inspector${r.count > 1 ? 's' : ''}:`);
  r.groups.forEach((g, i) => console.log(`  ${i + 1}. areas ${g.join(' ')} · ${r.ids[i].join(' ')}`));
}
