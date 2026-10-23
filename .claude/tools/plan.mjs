// The plan of a card, judged before the code: what the gate would only find out after it. risk.mjs runs it before it freezes
// risk.json; a card with a gap in the plan is not built.
// One rule, two moments: the checks over `## Gate` (probe per state, attacks line) and over `## Tasks` (the layer of a file)
// are the ones gate-checks.mjs runs on the code afterwards.
import { existsSync, readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { basename, join, resolve } from 'node:path';
import { asmsOf, cardIdOf, plannedTestsOf, rolesOf, sectionOf, specTagsIn, specsOf, tasksOf } from './card-doc.mjs';
import { IS_CODE, IS_TEST, NOT_PRODUCTION } from './card.mjs';
import { gateLinesOf, hasAttacksLine, roleFor, statesLacking, visualInstruments } from './gate-checks.mjs';
import { IS_MIGRATION } from './migrations.mjs';

const escape = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export const LOOK_MAX_LINES = 15;

// The visual direction a screen is built toward: `## Look` with `ref:` (an image in `specs/<card>/ref/` or a URL),
// `behavior:` (one line per moment) and `tokens:`; short, so that it is read.
export const lookProblems = (doc, cardDir) => {
  const section = sectionOf(doc, 'Look');
  if (section === null) return ['no `## Look` section (visual lens): add `ref:`, `behavior:` and `tokens:` (template: .claude/templates/card.md)'];
  const lines = section.split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith('<!--'));
  const field = (name) => lines.flatMap((l) => { const m = l.match(new RegExp(`^(?:[-*]\\s*)?${name}:\\s*(.*)$`, 'i')); return m && m[1].trim() ? [m[1].trim()] : []; });
  const out = [];
  if (lines.length > LOOK_MAX_LINES) out.push(`## Look has ${lines.length} lines (max ${LOOK_MAX_LINES}): it is a direction, not a document`);
  const refs = field('ref');
  if (!refs.length) out.push('## Look has no `ref:` (an image in specs/<card>/ref/ or a URL)');
  for (const r of refs) {
    if (!/^https?:\/\//i.test(r) && !existsSync(join(cardDir, 'ref', basename(r)))) out.push(`## Look ref ${r}: not a URL and not a file in specs/${basename(String(cardDir))}/ref/`);
  }
  if (!field('behavior').length) out.push('## Look has no `behavior:` line (load, cursor and hover, entering the view, each action or state of the card)');
  if (!field('tokens').length) out.push('## Look has no `tokens:` (fonts, palette, spacing and easing, or "the repo\'s: <path>")');
  for (const t of field('tokens')) {
    if (/los del repo|the repo'?s|design system/i.test(t)) continue;
    const names = t.split(/[·;|]/)[0].replace(/^\s*(?:fonts?|fuentes?)\b:?\s*/i, '').split(/[,+/]|\band\b|\by\b/i).map((n) => n.replace(/^["'\s]+|["'\s]+$/g, '').toLowerCase()).filter(Boolean);
    if (names.length && names.every((n) => GENERIC_FONTS.includes(n))) out.push('## Look `tokens:` names only generic fonts: a display font with character (the generic system fonts are the default look)');
  }
  return out;
};
const GENERIC_FONTS = ['system-ui', 'sans-serif', 'serif', '-apple-system', 'segoe ui', 'inter', 'roboto', 'arial', 'helvetica'];

// A spec that talks about a set («un campo», «cada campo», «todos», «cualquier», each, every, any) is tested once per member
// the card names between «», or the card says `declared · <S#> · <why>`.
export const QUANTIFIER = /\b(?:campo|campos|cada|todos|todas|cualquier|cualquiera|field|fields|each|every|any)\b/i;
export const membersOf = (doc) => {
  const seen = new Map();
  for (const m of (sectionOf(doc, 'Specs') ?? '').matchAll(/«([^»\n]+)»/g)) seen.set(m[1].trim().toLowerCase(), m[1].trim());
  return [...seen.values()];
};
export const quantifierProblems = (doc, id, planned) => {
  const members = membersOf(doc);
  if (!id || members.length < 2) return [];
  return specsOf(doc).flatMap((s) => {
    if (!QUANTIFIER.test(s.text)) return [];
    if (new RegExp(`declared[^\\n]*\\b${s.id}\\b`, 'i').test(doc)) return [];
    const count = planned.filter((t) => specTagsIn(id, t.title).includes(s.id)).length;
    return count < members.length ? [`${s.id}: speaks of a set and the card names ${members.length} members (${members.map((x) => `«${x}»`).join(', ')}) but ${count} planned tests carry its tag · one test per member in its T line, or \`declared · ${s.id} · <why>\``] : [];
  });
};

const wordsOf = (s) => new RegExp(`(?<![\\p{L}\\d])(?:${s})(?![\\p{L}\\d])`, 'iu');
const PROMISES_RESPONSE = /\b[1-5]\d\d\b|\bdevuelv\w*|\bresponde\w*|\breturns?\b|\bresponds?\b|\bse (?:guarda|devuelve)\b|\b(?:saved|stored|returned)\b/i;
const API_TEST_FILE = /api|http|e2e|app|route|server/i;
const EVERY_RESPONSE = wordsOf('toda respuesta|todas las respuestas|every response|all responses');
const UNIQUENESS = wordsOf('ya existe|repetid[oa]s?|duplicad[oa]s?|[uú]nic[oa]s?|unique|duplicate');
const hasFlag = (lines, flag) => lines.some((l) => l.includes(flag));
const declaredFor = (doc, what) => new RegExp(`declared\\s*·[^\\n]*${what}`, 'i').test(doc);

// `<ID>-ASM-NN · <reading> · S<n>` → { id, text } with the id removed from the text.
const asmLinesOf = (doc) => (sectionOf(doc, 'Specs') ?? '').split('\n').flatMap((line) => {
  const m = line.match(/^\s*(?:[-*]\s*)?([A-Z][A-Z0-9]*-\d+[A-Za-z0-9]*-ASM-\d+)\b[\s·:.-]*(.*)$/);
  return m ? [{ id: m[1], text: m[2].trim() }] : [];
});

// The steps files the `probe <state>:` lines name, read from the repo root, the card folder or its steps/ folder; '' when none exists yet.
const probeLinesOf = (doc) => gateLinesOf(doc).filter((l) => /^probe\s+[^:[]+?\s*(?:\[[^\]]*\])?\s*:/i.test(l));
const stepsTextOf = (doc, cardDir, root) => probeLinesOf(doc).flatMap((l) => l.match(/[^\s"']+\.json\b/g) ?? []).flatMap((p) =>
  [join(root, p), join(cardDir, p), join(cardDir, 'steps', basename(p))].filter(existsSync).slice(0, 1)).map((p) => readFileSync(p, 'utf8')).join('\n');

// The behavior a card already has: a file of `## Tasks` that exists in main, in a card that touches a route or a screen.
const existsInMain = (root, file) => ['origin/main', 'main', 'master'].some((ref) => spawnSync('git', ['cat-file', '-e', `${ref}:${file}`], { cwd: root }).status === 0);

// The plan rules that read what a spec or an assumption promises against the layer of its test, the flags of `attacks:` and the steps of `probe`.
export const promiseProblems = (doc, { cardDir, lenses = [], root }) => {
  const out = [];
  const id = cardIdOf(cardDir);
  const planned = plannedTestsOf(doc);
  const tasks = tasksOf(doc);
  const roles = rolesOf(doc);
  const gate = gateLinesOf(doc);
  const attacks = gate.filter((l) => /^attacks\s*(\[[^\]]*\])?\s*:/i.test(l));
  const specs = specsOf(doc);
  const asms = asmLinesOf(doc);
  const items = [...specs.map((s) => ({ ...s, tests: id ? planned.filter((t) => specTagsIn(id, t.title).includes(s.id)) : [] })),
    ...asms.map((a) => ({ ...a, tests: planned.filter((t) => new RegExp(`@(?:assumption:)?${escape(a.id)}(?!\\d)`).test(t.title)) }))];

  if (lenses.includes('contract')) for (const it of items) {
    if (!PROMISES_RESPONSE.test(it.text) || !it.tests.length) continue;
    const observable = it.tests.some((t) => {
      const task = tasks.find((k) => k.id === t.task);
      return API_TEST_FILE.test(basename(t.file)) || (task?.files ?? []).some((f) => !IS_TEST.test(f) && roleFor(roles, f) !== 'rule');
    });
    if (!observable) out.push(`${it.id}: promises a response and its planned tests are all on rules (rule) · add a test through the app or the api (a file named api|http|e2e|app|route|server) to its T line`);
  }

  for (const a of asms) {
    if (declaredFor(doc, escape(a.id))) continue;
    const titles = planned.filter((t) => new RegExp(`@(?:assumption:)?${escape(a.id)}(?!\\d)`).test(t.title)).map((t) => t.title.toLowerCase());
    const body = a.text.replace(/·\s*S\d+\s*$/, '');
    const values = [...new Set([...(body.match(/\b\d+\b/g) ?? []), ...[...body.matchAll(/«([^»\n]+)»/g)].map((m) => m[1].trim())])];
    const ordered = /\b(?:orden|order)\b/i.test(body) ? [...body.matchAll(/`([^`\n]+)`/g)].map((m) => m[1].trim()) : [];
    const missing = [...values, ...ordered].filter((v) => !titles.some((t) => t.includes(v.toLowerCase())));
    if (titles.length && missing.length) out.push(`${a.id}: its literal values (${missing.map((v) => `«${v}»`).join(', ')}) are in no title of its planned tests · name them in the title of its test, or \`declared · ${a.id} · <why>\``);
  }

  if (specs.some((s) => EVERY_RESPONSE.test(s.text)) && !hasFlag(attacks, '--common-headers'))
    out.push(`${specs.find((s) => EVERY_RESPONSE.test(s.text)).id}: speaks of every response and \`attacks:\` has no \`--common-headers "<A, B>"\``);
  if (lenses.includes('contract')) {
    const unique = items.find((s) => UNIQUENESS.test(s.text));
    if (unique && !hasFlag(attacks, '--unique')) out.push(`${unique.id}: speaks of a duplicate or a unique value and \`attacks:\` has no \`--unique "<METHOD> <path> <body>"\``);
  }
  const hasData = tasks.some((t) => t.files.some((f) => IS_MIGRATION.test(f) || roleFor(roles, f) === 'data'));
  if ((lenses.includes('contract') || lenses.includes('integrity')) && hasData && !hasFlag(attacks, '--fault-db') && !declaredFor(doc, 'fault-db'))
    out.push('a migration or a `(data)` file in ## Tasks and `attacks:` has no `--fault-db <file>` · add it, or `declared · fault-db · <why>`');
  const mutated = gate.filter((l) => /^mutate\b/i.test(l)).join('\n');
  const unmutated = [...new Set(tasks.flatMap((t) => t.files))].filter((f) => !IS_TEST.test(f) && !IS_MIGRATION.test(f) && ['presentation', 'data'].includes(roleFor(roles, f)) && !mutated.includes(f));
  if (lenses.includes('contract') && mutated && unmutated.length && !declaredFor(doc, 'mutate'))
    out.push(`${unmutated[0]} carries behavior of the contract and no \`mutate\` line names it · add \`mutate ${unmutated[0]}: <test command>\`, or \`declared · mutate · <why>\``);
  if (lenses.includes('integrity') && gate.some((l) => /^app\s*:/i.test(l)) && !planned.some((t) => /reinici|restart|sobrevive/i.test(t.title)))
    out.push('integrity lens with an `app:` line and no planned test whose title says reinici, restart or sobrevive (a record survives restarting the app on the same database)');

  const instruments = visualInstruments(root ?? resolve(String(cardDir), '..', '..'));
  if (lenses.includes('visual') && instruments.golden) {
    if (!gate.some((l) => /^a11y\s*(\[[^\]]*\])?\s*:/i.test(l))) out.push('no `a11y:` line in ## Gate (visual lens, flutter): `a11y: flutter test <file>` with `kitA11y`');
    const moving = (sectionOf(doc, 'Look') ?? '').split('\n').some((l) => /^\W*behavior:/i.test(l.trim()) && /\b(?:hover|cursor|foco|focus|press|tap|animat\w*|transition\w*|hero|fade|slide)\b/i.test(l));
    if (moving && !gate.some((l) => /^motion\s*:/i.test(l) && /kitTrace|flutter test/i.test(l))) out.push('## Look declares movement and no `motion:` line in ## Gate runs `flutter test` with `kitTrace`');
  }
  if (lenses.includes('visual') && instruments.probe) {
    const steps = stepsTextOf(doc, cardDir, root ?? resolve(String(cardDir), '..', '..'));
    const enter = specs.find((s) => /\bEnter\b/.test(s.text));
    if (enter && !steps.includes('enter-each')) out.push(`${enter.id}: names Enter and no steps file of a \`probe <state>:\` line has an \`{ "enter-each": "<form>" }\` step`);
    const typed = specs.find((s) => /«[^»]*(?:<[^>\n]+>|\{[^}\n]+\})[^»]*»/.test(s.text));
    if (typed && !steps.includes('type-markup')) out.push(`${typed.id}: shows text the person typed and no steps file has a \`{ "type-markup": "<locator>" }\` step`);
    const moves = (sectionOf(doc, 'Look') ?? '').split('\n').some((l) => /^\W*behavior:/i.test(l.trim()) && /\b(?:hover|cursor|foco|focus|press)\b/i.test(l));
    if (moves && !gate.some((l) => /^motion\s*:/i.test(l))) out.push('## Look has a `behavior:` of hover, cursor, focus or press and no `motion:` line in ## Gate');
    const states = probeLinesOf(doc).length;
    const onLoadOnly = gate.filter((l) => /^overflow\s*:/i.test(l) && !/\.json\b/.test(l));
    if (states > 1 && onLoadOnly.length && specs.some((s) => /desbord|overflow/i.test(s.text)) && !declaredFor(doc, 'overflow'))
      out.push(`a spec speaks of overflow, \`overflow:\` measures only the page on load and the Gate has ${states} \`probe <state>:\` lines · measure the text of each state, or \`declared · overflow-states · <why>\``);
    for (const l of probeLinesOf(doc)) {
      const widths = l.match(/--widths\s+(\S+)/)?.[1];
      if (widths && !widths.split(',').some((w) => Number.parseInt(w, 10) === 320)) out.push(`${l.match(/^probe\s+([^:[]+?)\s*(?:\[[^\]]*\])?\s*:/i)[1]}: the probe measures overflow at ${widths} and not at 320 px · drop \`--widths\` or add 320`);
    }
  }

  if (root && existsSync(join(root, '.git')) && sectionOf(doc, 'Changes') === null && (lenses.includes('contract') || lenses.includes('visual'))) {
    const touched = [...new Set(tasks.flatMap((t) => t.files))].filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && !IS_TEST.test(f) && existsInMain(root, f));
    if (touched.length) out.push(`${touched[0]} exists in main and the card touches a route or a screen: add \`## Changes to existing behavior\` (\`none\` if nothing changes)`);
  }
  return out;
};

// What is missing from the plan, one line each; an empty list is a complete plan.
export const planProblems = (doc, { cardDir, lenses = [], root }) => {
  const id = cardIdOf(cardDir);
  const out = [];
  const planned = plannedTestsOf(doc);
  if (!id) out.push(`the folder ${String(cardDir).split(/[\\/]/).filter(Boolean).pop()} has no card ID: the tags of the tests cannot be checked`);
  else {
    const tagged = new Set(planned.flatMap((t) => [...specTagsIn(id, t.title), ...[...t.title.matchAll(new RegExp(`@(?:assumption:)?(${escape(id)}-ASM-\\d+)(?!\\d)`, 'g'))].map((m) => m[1])]));
    for (const s of specsOf(doc)) if (!tagged.has(s.id)) out.push(`${s.id}: no planned test · add to its T line \`· tests: <file> "<title @${id}-${s.id}>"\``);
    for (const a of asmsOf(doc)) if (!tagged.has(a)) out.push(`${a}: no planned test · add to its T line \`· tests: <file> "<title @${a}>"\``);
    for (const t of planned) if (!new RegExp(`@(?:assumption:)?${escape(id)}-(?:S|ASM-)\\d+(?!\\d)`).test(t.title)) out.push(`${t.task}: the test "${t.title}" carries no tag @${id}-S<n> or @${id}-ASM-NN`);
  }
  out.push(...quantifierProblems(doc, id, planned));
  out.push(...promiseProblems(doc, { cardDir, lenses, root }));
  const roles = rolesOf(doc);
  const unmarked = [...new Set(tasksOf(doc).flatMap((t) => t.files))].filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && !roleFor(roles, f));
  for (const f of unmarked) out.push(`${f}: no layer · mark it \`${f} (presentation|rule|data)\` in ## Tasks`);
  if (lenses.includes('visual')) {
    const instruments = visualInstruments(root ?? resolve(String(cardDir), '..', '..'));
    const kind = instruments.probe && instruments.golden ? 'probe` or `golden' : instruments.golden ? 'golden' : 'probe';
    for (const x of statesLacking(doc, instruments)) out.push(`state ${x}: no \`${kind} ${x}:\` line in ## Gate (visual lens)`);
  }
  if (lenses.includes('visual')) out.push(...lookProblems(doc, cardDir));
  if (lenses.includes('contract') && !hasAttacksLine(doc)) out.push('no `attacks:` line in ## Gate (contract lens), with `--body-limit` if the card sets a limit');
  if (lenses.includes('integrity') || tasksOf(doc).some((t) => t.files.some((f) => IS_MIGRATION.test(f)))) {
    const upgrade = gateLinesOf(doc).some((l) => /^migrate-upgrade\b/i.test(l));
    const migration = tasksOf(doc).some((t) => t.files.some((f) => IS_MIGRATION.test(f)));
    if (!migration && !upgrade) out.push('no migration file in ## Tasks and no `migrate-upgrade:` line in ## Gate (integrity lens)');
    if (migration && !upgrade) out.push('a migration in ## Tasks and no `migrate-upgrade: <command>` line in ## Gate (the upgrade from main with seeded data)');
  }
  return out;
};
