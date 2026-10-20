#!/usr/bin/env node
// help.mjs [tool] — how a kit tool is used, without reading its code.
// help.mjs step <1-9|close> — the package of a phase: what the documents that phase touches say «at a glance».
// help.mjs grid — the grid of scenarios of commands/scenarios.md, alone (the coverage a screen is checked against).
// help.mjs judge — what an inspector or a reviewer needs of the tools in one read: judge-context, `app.mjs probe` (every flag,
// the steps format with an example, where the captures and JSON go), motion-audit and overflow. Their first call.
//
// With no argument, one line per tool; with a name, the comment at the head of that tool, which says
// what it runs, its arguments and its exit codes.
// With `step <N>`, the `## At a glance` of each document the phase of the card uses, in the order it uses them (steps 6 and 7
// are one phase), cut at 12000 characters (`KIT_HELP_STEP_CAP`): what every card needs, in one read instead of one read per
// document. The rest of a document is read only for the rare case its last glance line names. A module that is off
// (`kit.mjs status`) has no part in it.
// Measured: the main thread of a small card read 100 to 165k characters of the kit's documents, piece by piece, and
// all of it was re-read on every request of the card.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const DIR = import.meta.dirname;
const head = (file) => {
  const lines = readFileSync(join(DIR, file), 'utf8').split('\n');
  const out = [];
  for (const l of lines.slice(l0(lines))) {
    if (!l.startsWith('//')) break;
    out.push(l.replace(/^\/\/ ?/, ''));
  }
  return out;
};
const l0 = (lines) => (lines[0].startsWith('#!') ? 1 : 0);

const CAP = Number(process.env.KIT_HELP_STEP_CAP) || 12000;
const KIT = join(DIR, '..');
// The documents each phase touches, in order; `m-…` ones only while their module is on.
const PLAN = ['steps/05-plan.md', ['ui', 'steps/m-ui.md']];
const IMPLEMENT = ['steps/06-implement.md', ['ui', 'steps/m-ui.md']];
const PHASES = {
  1: ['commands/card.md', 'steps/01-card.md'],
  2: ['steps/02-ambiguities.md', 'AUTONOMY.md'],
  // Step 3 reads the answers and expires the rest: AUTONOMY has it; the glance of 02 was printed by step 2.
  3: ['AUTONOMY.md'],
  4: ['steps/04-scenarios.md', 'commands/scenarios.md', ['stack', 'stacks/node-ts.md']],
  5: PLAN,
  6: IMPLEMENT,
  7: IMPLEMENT,
  8: ['steps/08-verify.md', 'commands/validate.md'],
  9: [['ui', 'steps/m-ui-screen.md'], ['ui', 'steps/m-ui-craft.md']],
  close: ['commands/close.md', 'AUTONOMY.md'],
};

const glanceOf = (text) => text.match(/^## At a glance[^\n]*\n([\s\S]*?)(?=^## |(?![\s\S]))/m)?.[1]?.trim();

const moduleOn = async (name) => {
  if (name === 'stack') return existsSync(join(process.cwd(), 'package.json'));
  try {
    const { active } = await import('./kit.mjs');
    const { on, known } = active(process.cwd());
    return !known.length || on.has(name);
  } catch { return true; }
};

const step = async (which) => {
  const files = PHASES[which];
  if (!files) {
    console.error(`${which ? `There is no phase ${which}` : 'help.mjs step needs a phase'}. The phases: ${Object.keys(PHASES).join(', ')}`);
    process.exit(1);
  }
  const out = [];
  const left = [];
  let size = 0;
  for (const entry of files) {
    const [module, file] = Array.isArray(entry) ? entry : [null, entry];
    if (module && !(await moduleOn(module))) continue;
    const glance = glanceOf(readFileSync(join(KIT, file), 'utf8'));
    if (!glance) continue;
    const block = `=== .claude/${file} ===\n${glance}\n`;
    if (size + block.length > CAP) { left.push(`.claude/${file}`); continue; }
    out.push(block);
    size += block.length;
  }
  if (left.length) out.push(`left out by the cap: ${left.join(', ')} (read their «At a glance» yourself)\n`);
  out.push('The rest of each document: read it only for the case its last glance line names.');
  console.log(out.join('\n'));
};

// The coverage grid of /scenarios: the intro line and the table under «The card's scenarios are the floor», nothing around it.
const grid = () => {
  const lines = readFileSync(join(KIT, 'commands/scenarios.md'), 'utf8').split(/\r?\n/);
  const from = lines.findIndex((l) => l.startsWith('→ **') && l.includes('scenarios are the floor'));
  if (from < 0) { console.error('commands/scenarios.md has no «The card’s scenarios are the floor» grid'); process.exit(1); }
  let end = from + 1;
  while (end < lines.length && !lines[end].startsWith('|')) end++;
  while (end < lines.length && lines[end].startsWith('|')) end++;
  console.log(lines.slice(from, end).join('\n'));
};

// What a judge needs of the tools, in one read: everything comes from the tools themselves —the flags, the actions and the
// example of the probe are the constants its code parses with; the rest, the head comment of each tool up to its «Measured:»
// line—, so it cannot go stale. A judge starts here and does not read the tools' code.
const judge = async () => {
  const { ACTION_DOC, DEFAULT_OUT, EXAMPLE_STEPS, FLAGS, RECORD_FIELDS, USAGE } = await import('./probe.mjs');
  const usage = (file) => { const lines = head(file); const end = lines.findIndex((l) => l.startsWith('Measured')); return (end < 0 ? lines : lines.slice(0, end)).join('\n').trimEnd(); };
  console.log([
    '=== help.mjs judge · what a judge needs of the kit tools; do not read their code ===',
    'Run from the root of the repo of the card. The app is shared: `APP_URL` in your prompt, or `url` in `.validation/app.json`; start no other.',
    'Playwright is the repo\'s, or the one at `KIT_PLAYWRIGHT_ROOT`. Your own files (scripts, captures, logs) go in `.validation/<your role>/`.',
    '',
    '=== what you read of the card, in one call ===',
    usage('judge-context.mjs'),
    '',
    '=== app.mjs probe: drive the running app, measure, capture ===',
    USAGE,
    ...FLAGS.map((f) => `  ${f.use}${f.repeat ? ' (repeatable)' : ''} — ${f.note}`),
    'steps.json is a JSON list, one action per object; a locator is a Playwright one (css, `text=Save`, `role=button[name="Save"]`):',
    ...Object.values(ACTION_DOC).map((l) => `  ${l}`),
    'example:',
    JSON.stringify(EXAMPLE_STEPS, null, 1).replace(/\n\s*/g, ' ').replace(/^\[ /, '[\n  ').replace(/\}, \{/g, '},\n  {').replace(/ \]$/, '\n]'),
    `output: per step and width \`${DEFAULT_OUT}/w<width>-step<NN>.png\` and \`.json\`; the JSON has ${RECORD_FIELDS}.`,
    'A step that fails is written with its `error` and the run exits 1. Contrast: `--contrast "button,.error"` before writing a script to measure colors.',
    '',
    '=== motion-audit.mjs ===',
    usage('motion-audit.mjs'),
    '',
    '=== overflow.mjs ===',
    usage('overflow.mjs'),
  ].join('\n'));
};

const name = process.argv[2]?.replace(/\.mjs$/, '');
if (name === 'judge') {
  await judge();
  process.exit(0);
}
if (name === 'step') {
  await step(process.argv[3]);
  process.exit(0);
}
if (name === 'grid') {
  grid();
  process.exit(0);
}
const tools = readdirSync(DIR).filter((f) => f.endsWith('.mjs')).sort();
if (!name) {
  for (const f of tools) console.log(head(f)[0] ?? f);
  console.log('\nnode .claude/tools/help.mjs <tool> — how one is used');
  console.log('node .claude/tools/help.mjs step <1-9|close> — what a phase of the card reads, in one go');
  console.log('node .claude/tools/help.mjs grid — the grid of scenarios a screen is covered against');
  console.log('node .claude/tools/help.mjs judge — what a judge needs of probe, motion-audit and overflow, in one read');
  process.exit(0);
}
if (!tools.includes(`${name}.mjs`)) {
  console.error(`There is no ${name}.mjs. Tools: ${tools.map((f) => f.replace('.mjs', '')).join(', ')}`);
  process.exit(1);
}
console.log(head(`${name}.mjs`).join('\n'));
