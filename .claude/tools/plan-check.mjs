#!/usr/bin/env node
// plan-check.mjs — run from the repo root, with a card in progress.
//
// What the committed plan has to say before an `implementer` or the `conductor` starts, from the same
// readings the close and `require-bar.mjs` use, so it is asked once, at the start, and not by a block in the
// middle of the code (a write refused by `require-bar` costs the implementer its lap):
// - `## Bar` answers every criterion `bar.mjs` lists, and has the line of every module that is off and of every
//   block the grade leaves out;
// - every `ASM-NN ·` line of the plan carries `any-answer: yes` or `any-answer: no — <why>` (check 6 of `/close`);
// - `## Time plan` has a readable cap, within the grade's multiple of the likely time (the same reading as `require-bar.mjs`);
// - the `stable:` line has the shape `required.mjs` asks for (T8): the card's browser scenarios repeated at least
//   3 times; `node --test` has no repeat flag and runs a file named three times once, so it goes through
//   `node .claude/tools/repeat.mjs 3 -- node --test <files>`.
// `review-cap.mjs` runs it at the first launch of an implementer or the conductor and blocks with the list.
// Exits 0 if nothing is missing, 1 if something is, 2 if there is no card in progress or no plan yet.
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { IS_TEST, MIGRATE_UPGRADE, cardFiles, cardStart, currentCard, mapHasMigration, timePlanProblems } from './card.mjs';
import { active, addedOf, gradeLines } from './kit.mjs';
import { laneOf } from './lane.mjs';
import { cardIdOf } from './refreeze.mjs';

// A scenario driven through a browser; one of these in a test with the card's tag makes `stable:` necessary.
export const BROWSER_TEST = /@playwright\/test|\bplaywright\b|\bcypress\b|\bpuppeteer\b|\bpage\.goto\b|\bwebdriver/i;
const REPEATS = /--repeat-each[=\s]+(\d+)|\brepeat(?:\.mjs)?\s+(\d+)\b/;

const section = (text, title) => text.split(/^## /m).find((s) => s.startsWith(title));

// The `stable:` line of the plan's `## Verification` block, or null.
export const stableLine = (plan) => {
  const block = (section(plan, 'Verification') ?? '').match(/```[^\n]*\n([\s\S]*?)```/)?.[1] ?? '';
  return block.split('\n').map((l) => l.trim()).find((l) => /^stable\b[^:]*:/.test(l)) ?? null;
};

// What is wrong with the command of a `stable:` line, as a line the plan can act on; null when it is fine.
export const stableShape = (command) => {
  const viaTool = /\brepeat(?:\.mjs)?\s+\d+\b/.test(command);
  if (/\bnode\b[^|;&\n]*--test\b/.test(command) && !viaTool)
    return 'the `stable:` line runs `node --test`, which has no repeat flag and runs a file named three times once: `node .claude/tools/repeat.mjs 3 -- node --test <files>` repeats it (T8)';
  const times = Number((command.match(REPEATS) ?? []).slice(1).find(Boolean) ?? 0);
  return times < 3 ? 'the `stable:` line repeats the scenarios at least 3 times (`--repeat-each=3`) (T8)' : null;
};

// The unanswered criteria and the lines of the modules that are off and of the blocks the grade leaves out. `modules`
// is `kit.mjs`'s `active(root)`.
export const barProblems = (root, text, modules) => {
  const list = join(root, '.claude', 'reference', 'criteria.md');
  const lines = text.split('\n');
  const start = lines.findIndex((l) => l.trim() === '## Bar' || l.startsWith('## Bar '));
  if (start < 0 || !existsSync(list)) return [];
  const problems = [];
  const skipped = new Set([...modules.off.keys()].flatMap((name) => modules.map.modules[name].criteria).concat([...modules.exempt.criteria]));
  const ids = [...new Set([...readFileSync(list, 'utf8').matchAll(/^\| ([A-Z]\d+) \|/gm)].map((m) => m[1]))].filter((id) => !skipped.has(id));
  const end = lines.findIndex((l, i) => i > start && /^## /.test(l));
  const bar = lines.slice(start, end < 0 ? undefined : end).join('\n');
  const ranges = [...bar.matchAll(/\b([A-Z])(\d+)\s*[–-]\s*\1?(\d+)\b/g)]
    .map(([, area, from, to]) => ({ area, from: +from, to: +to }));
  const answered = (id) => new RegExp(`(^|[^A-Za-z0-9])${id}([^0-9]|$)`).test(bar) ||
    ranges.some((r) => id[0] === r.area && +id.slice(1) >= r.from && +id.slice(1) <= r.to);
  const missing = ids.filter((id) => !answered(id));
  if (missing.length)
    problems.push(`in “## Bar”, ${missing.length} criteria unanswered: ${missing.join(', ')} — one line each, \`- <ID> · <how it is met in this card, or not applicable · why>\`; a whole area on one line, \`I1–I32 · not applicable · <why>\`; \`node .claude/tools/bar.mjs\` ends with the skeleton to paste`);
  const unsaid = [...modules.off.keys()].filter((name) => !new RegExp(`^\\W*${name}\\s*·\\s*off\\b`, 'im').test(bar));
  if (unsaid.length) problems.push(`in “## Bar”, one line per module that is off, to be copied from \`node .claude/tools/bar.mjs\`: ${unsaid.map((n) => `\`${n} · off by decision · ${modules.off.get(n).reason}\``).join(', ')}`);
  const unsaidByGrade = modules.exempt.blocks.filter((b) => !new RegExp(`^\\W*${b.name.replace(/[.+^${}()|[\]\\-]/g, '\\$&')}\\s*·\\s*off by grade\\b`, 'im').test(bar));
  if (unsaidByGrade.length) {
    const wanted = new Set(unsaidByGrade.map((b) => b.name));
    problems.push(`in “## Bar”, one line per block the grade ${modules.grade} leaves out, to be copied from \`node .claude/tools/bar.mjs\`: ${gradeLines(modules.exempt).filter((l) => wanted.has(l.split(' · ')[0])).map((l) => `\`${l}\``).join(', ')}`);
  }
  return problems;
};

// Check 6 of `/close`: `grep -E "ASM-[0-9]+ ·" plan.md | grep -vc "any-answer: "` has to be 0.
export const assumptionProblems = (text) => {
  const bare = text.split('\n').filter((l) => /ASM-\d+ ·/.test(l) && !l.includes('any-answer: '));
  if (!bare.length) return [];
  const ids = bare.map((l) => l.match(/\b[A-Z][A-Z0-9]*(?:-\d+)?-ASM-\d+/)?.[0] ?? l.trim().slice(0, 40));
  return [`${bare.length} assumption line${bare.length > 1 ? 's' : ''} without \`any-answer: yes\` or \`any-answer: no — <why>\` (${ids.join(', ')}): check 6 of /close counts them`];
};

// A File map row under `migrations/` asks `migrate-upgrade: <command>` in `## Verification` (Q19), unless the data module is off.
const migrateProblems = (cardDir, text, modules) => {
  if (modules.off.has('data')) return [];
  const block = (section(text, 'Verification') ?? '').match(/```[^\n]*\n([\s\S]*?)```/)?.[1] ?? '';
  const line = block.split('\n').find((l) => /^\s*migrate-upgrade\b[^:]*:\s*\S/.test(l));
  // A pipe or `&` in the line is read differently by cmd.exe and by sh: measured on Windows, a `|` to filter tests ran
  // them all. One script, or `node --test --test-name-pattern=<word> <file>`.
  if (line && /[|&]/.test(line.slice(line.indexOf(':') + 1)))
    return ['the `migrate-upgrade:` line has a `|` or `&`, which cmd.exe and sh read differently (a filter ran every test): one script, or `node --test --test-name-pattern=<word> <file>`'];
  return line || !mapHasMigration(cardDir) ? [] : [`${MIGRATE_UPGRADE}: the File map has a migration`];
};

const stableProblems = (root, cardDir, text, modules) => {
  if (modules.exempt.criteria.has('T8')) return [];
  const line = stableLine(text);
  if (line) {
    const problem = stableShape(line.slice(line.indexOf(':') + 1).trim());
    return problem ? [problem] : [];
  }
  const id = cardIdOf(cardDir);
  if (!id) return [];
  const base = cardStart(root, cardDir);
  const scenario = new RegExp(`@${id}-H\\d+-\\d+`);
  const browser = cardFiles(root, base).filter((f) => IS_TEST.test(f))
    .some((f) => addedOf(root, base, f).some((l) => scenario.test(l.text)) && BROWSER_TEST.test(readFileSync(join(root, f), 'utf8')));
  return browser
    ? ['a `stable:` line in the plan\'s ## Verification that runs this card\'s browser scenarios 3 times (`npx playwright test --grep "@<ID>" --repeat-each=3`; with `node --test`, `node .claude/tools/repeat.mjs 3 -- node --test <files>`): the card adds browser scenarios (T8)']
    : [];
};

// What the plan lacks, as a list of lines; [] when nothing, null when the card has no plan yet. The fast lane's short
// plan has no bar: it is checked by `require-bar.mjs` and the lane.
export const planProblems = (root, cardDir) => {
  const path = join(cardDir, 'plan.md');
  if (!existsSync(path)) return null;
  const text = readFileSync(path, 'utf8');
  if (laneOf(text) === 'fast') return [];
  const modules = active(root);
  const hasBar = text.split('\n').some((l) => l.trim() === '## Bar' || l.startsWith('## Bar '));
  return [
    ...(hasBar ? barProblems(root, text, modules) : ['“## Bar” (every criterion of .claude/reference/criteria.md: how it is met or why it does not apply; `node .claude/tools/bar.mjs` lists them)']),
    ...assumptionProblems(text),
    ...timePlanProblems(text, modules),
    ...stableProblems(root, cardDir, text, modules),
    ...migrateProblems(cardDir, text, modules),
  ];
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const root = process.cwd();
  const cardDir = existsSync(join(root, 'specs')) ? currentCard(root) : null;
  const problems = cardDir ? planProblems(root, cardDir) : null;
  if (problems === null) {
    console.error('No card in progress with a plan.md: nothing to check.');
    process.exit(2);
  }
  if (problems.length) {
    console.log(`The plan is missing:\n${problems.map((p) => `- ${p}`).join('\n')}`);
    process.exit(1);
  }
  console.log('The plan has what an implementer needs: its bar, its assumptions and its stable line.');
}
