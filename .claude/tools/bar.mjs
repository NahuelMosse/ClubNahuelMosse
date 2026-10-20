#!/usr/bin/env node
// bar.mjs [ID…] | --route — run from the repo root.
//
// `--route` prints who does steps 6 to 9 —the main thread, or the conductor when the plan's File map names 15 or
// more production files (`routeOf`)—; the full bar prints the same line once the plan has a File map.
// Every criterion of reference/criteria.md, to write the plan's bar without reading the whole
// table: with no arguments, the grade, then one line per criterion —ID, how it is checked (T C A J) and the
// criterion cut at its first clause—, grouped by area; with IDs, their complete rows.
// What a module that is off, or the grade, leaves out is not listed: each block gets one line. The output opens with
// `Answer these <N> IDs: …` —read it whole, in one call— and, when the plan's File map names a screen, carries the
// `stable:` line the plan's `## Verification` needs.
// Measured: criteria.md read whole at step 5 was re-read on every one of the ~150 requests that
// followed, close to a million tokens per card.
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { IS_SCREEN, MIGRATE_UPGRADE, currentCard, fileMapLines, mapHasMigration, pathTokens, routeLine } from './card.mjs';
import { active, gradeLines, ownerOf, recordedGrade } from './kit.mjs';

// ID | criterion | how | minimum grade | today | source. A table without the grade column is read as production.
const ROW = /^\| ([A-Z]\d+) \| (.+?) \| ([TCAJ](?: \+ [TCAJ])*) \| (?:(poc|mvp|production) \| )?(.*?) \| (.*?) \|$/;

export const criteria = (root) => {
  const file = join(root, '.claude', 'reference', 'criteria.md');
  if (!existsSync(file)) return null;
  return readFileSync(file, 'utf8').split(/\r?\n/).map((l) => l.match(ROW)).filter(Boolean)
    .map(([, id, text, how, grade, today, source]) => ({ id, text, how, grade: grade ?? 'production', today, source }));
};

const short = (text) => {
  const plain = text.replace(/\*\*/g, '').replace(/`/g, '');
  const cut = plain.split(/: | — |; /)[0].trim();
  return cut.length > 120 ? `${cut.slice(0, 117)}…` : cut;
};

export const compact = (list) => {
  const lines = [];
  let area = '';
  for (const c of list) {
    if (c.id[0] !== area) { area = c.id[0]; lines.push(`\n${area}`); }
    lines.push(`${c.id} ${c.how.replace(/ \+ /g, '+')} ${short(c.text)}`);
  }
  return lines.join('\n').trim();
};

// Which files of the plan carry a `mutate <file>:` line in `## Verification`, by the grade's `mutation` level
// (modules.json). verify.mjs does not run a line for a file the grade does not ask to mutate.
const MUTATION_LINE = {
  none: 'Mutation: none at this grade — the plan has no `mutate` line.',
  domain: 'Mutation: the domain only — one `mutate <file>:` line for each file under `domain/` or marked `rule` in the File map, and none for the rest (verify.mjs skips them).',
  all: 'Mutation: every production file — one `mutate <file>:` line for each, except the files marked `presentation` in the File map.',
};
export const mutationLine = (level) => {
  if (!level) return null;
  const line = MUTATION_LINE[level.mutation];
  if (!line) throw new Error(`modules.json: unknown mutation level “${level.mutation}” (none, domain, all)`);
  return line;
};

// ADR and system design follow the architecture, not the card's size. Measured: an ADR for a form of
// three fields. The line is printed on every bar so the plan answers it explicitly.
export const ARCHITECTURE_LINE = 'Architecture: the ADR (D14) and docs/technical/system-design.md only if the card changes the architecture —a new module, process, store or external dependency, or a change of boundary—; otherwise `- ADR: unchanged — <why>` and `- System design: unchanged — <why>`.';

// A File map that names a screen (markup, a component, a stylesheet; not a test) means browser scenarios, and the plan's
// `## Verification` needs the `stable:` line that runs them 3 times; the first implementer is not launched without it.
export const STABLE_LINE = 'Verification: a `stable:` line when the card adds browser scenarios —`npx playwright test --grep "@<ID>" --repeat-each=3`, the card\'s scenarios 3 times (T8)—; the File map names a screen, and the first implementer is not launched without it.';
export const mapHasScreen = (cardDir) => (cardDir ? fileMapLines(cardDir) ?? [] : []).flatMap(pathTokens).some((t) => IS_SCREEN.test(t) && !/\.(?:test|spec)\./.test(t));

// The body of the plan's `## Bar`, one line per applicable criterion, `—` to be replaced by how the
// criterion is met in the card or `not applicable · <why>`; the lines off by decision or by grade listed
// above are pasted as they are.
export const skeleton = (list) => [
  'Skeleton of ## Bar (replace each — with how it is met here, or `not applicable · <why>`; add the lines off by decision or by grade above):',
  ...list.map((c) => `- ${c.id} · —`),
].join('\n');

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const list = criteria(process.cwd());
  if (!list) {
    console.error('No .claude/reference/criteria.md under the current folder: run it from the repo root.');
    process.exit(2);
  }
  const ids = process.argv.slice(2).map((a) => a.toUpperCase());
  if (ids.includes('--HELP')) {
    console.log('bar.mjs            the grade, the route and one line per criterion, to decide what applies\nbar.mjs E3 S2      the complete rows of those criteria\nbar.mjs --route    who does steps 6 to 9: the main thread, or the conductor from 15 production files in the File map');
    process.exit(0);
  }
  const card = currentCard(process.cwd());
  const route = card && routeLine(process.cwd(), card);
  if (ids.includes('--ROUTE')) {
    console.log(route ?? 'Route: main thread · no File map yet: the route is decided by the production files the plan\'s File map names (the conductor from 15)');
    process.exit(0);
  }
  // The criteria of a module that is off, or that the grade leaves out, are not listed: the bar answers
  // them with one line per module or block.
  const { off, map, manifest, grade, exempt } = active(process.cwd());
  const owner = ownerOf(map);
  if (!ids.length) {
    const skipped = new Set([...off.keys()].flatMap((name) => map.modules[name].criteria).concat([...exempt.criteria]));
    const lines = [...off].map(([name, o]) => `${name} · off by decision · ${o.reason}`);
    const byGrade = gradeLines(exempt);
    const set = recordedGrade(manifest) ? manifest.grade : null;
    const applicable = list.filter((c) => !skipped.has(c.id));
    const mutation = mutationLine(exempt.level);
    console.log([
      `Answer these ${applicable.length} IDs: ${applicable.map((c) => c.id).join(', ')}`,
      `Grade: ${grade}${set ? ` — ${set.reason}` : ' (default)'}`,
      ...(mutation ? [mutation] : []),
      ARCHITECTURE_LINE,
      ...(route ? [route] : []),
      ...(mapHasScreen(card) ? [STABLE_LINE] : []),
      ...(mapHasMigration(card) && !off.has('data') ? [`Verification: ${MIGRATE_UPGRADE}; the File map has a migration.`] : []),
      '',
      compact(applicable),
      ...(lines.length ? ['', `Modules that are off (one line each in the bar):\n${lines.join('\n')}`] : []),
      ...(byGrade.length ? ['', `Off by grade (one line each in the bar):\n${byGrade.join('\n')}`] : []),
      '',
      'How: T test · C command · A against the running app · J judgment. Full row: node .claude/tools/bar.mjs <ID>…',
      '',
      skeleton(applicable),
    ].join('\n'));
    process.exit(0);
  }
  const unknown = ids.filter((id) => !list.some((c) => c.id === id));
  for (const c of list.filter((x) => ids.includes(x.id)))
    console.log(`${c.id} · ${c.how} · ${c.text}\n  today: ${c.today} · source: ${c.source} · module: ${owner.get(c.id) ?? 'core'} · min grade: ${c.grade}${exempt.criteria.has(c.id) ? ` (off by grade: ${grade})` : ''}`);
  if (unknown.length) {
    console.error(`Unknown: ${unknown.join(', ')}`);
    process.exit(1);
  }
}
