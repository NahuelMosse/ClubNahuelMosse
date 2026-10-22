// The checks of the gate that are not a command of `## Gate`: they read what the card and the probe left on disk.
// Each returns `{ name, state: 'passed' | 'failed' | 'could not run', detail }`; verify.mjs prints one line per check.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { basename, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { cardIdOf, gateBlock, readCard, riskOf, rolesOf, specTagsIn, specsOf } from './card-doc.mjs';
import { IS_CODE, NOT_PRODUCTION, cardFiles, cardStart } from './card.mjs';
import { IS_MIGRATION, migrationsOutlook } from './migrations.mjs';
import { SCREEN_MARKUP } from './signals.mjs';


const ok = (name, detail = '') => ({ name, state: 'passed', detail });
const failed = (name, detail) => ({ name, state: 'failed', detail });
const couldNot = (name, detail) => ({ name, state: 'could not run', detail });

// Every `S#` of `## Specs` has a test that carries `@<ID>-S<n>`. The files looked at are those git knows (tracked or
// not yet), outside specs/ and the kit.
export const specsCheck = (root, cardDir) => {
  const doc = readCard(cardDir);
  const id = cardIdOf(cardDir);
  if (doc === null) return couldNot('specs', 'the card has no card.md');
  if (!id) return couldNot('specs', `the folder ${basename(cardDir)} has no card ID`);
  const specs = specsOf(doc);
  if (!specs.length) return failed('specs', 'card.md has no `S1 · "<quote>"` line under ## Specs');
  const grep = spawnSync('git', ['grep', '-l', '-I', '-F', '--untracked', '-e', `@${id}-S`, '--', ':(exclude)specs', ':(exclude).claude'], { cwd: root, encoding: 'utf8' });
  if (grep.status !== 0 && grep.status !== 1) return couldNot('specs', `git grep failed: ${(grep.stderr ?? '').trim().split('\n')[0]}`);
  const tagged = new Set((grep.stdout ?? '').split('\n').filter(Boolean).flatMap((f) => {
    try { return specTagsIn(id, readFileSync(join(root, f), 'utf8')); } catch { return []; }
  }));
  const lacking = specs.filter((s) => !tagged.has(s.id)).map((s) => `${s.id}: no test tagged`);
  return lacking.length ? failed('specs', `${lacking.join('; ')} (tag a test with @${id}-S<n>)`) : ok('specs', `${specs.length} specs, each with a tagged test`);
};

// What `app.mjs probe` wrote (`.validation/probe/w<width>-step<NN>.json`), and in each `--out .validation/probe/<state>/` folder.
export const probeRecords = (root) => {
  const dir = join(root, '.validation', 'probe');
  if (!existsSync(dir)) return [];
  const folders = ['', ...readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory()).map((e) => e.name).sort()];
  return folders.flatMap((sub) => readdirSync(join(dir, sub)).filter((f) => /^w\d+(?:x\d+)?-step\d+\.json$/.test(f)).sort().flatMap((f) => {
    try { return [{ file: (sub ? `${sub}/` : '') + f.replace(/\.json$/, ''), ...JSON.parse(readFileSync(join(dir, sub, f), 'utf8')) }]; } catch { return []; }
  }));
};

const lensesOf = (cardDir) => riskOf(cardDir)?.lenses ?? [];
export const gateLinesOf = (doc) => (gateBlock(doc) ?? '').split('\n').map((l) => l.trim()).filter(Boolean);

// A spec names its states in the line: `S2 · "…" · state: sending, empty`. With the `visual` lens, each one needs its own
// `probe <state>: <command>` line in `## Gate` (the command writes to `.validation/probe/<state>/`). The same rule judges the
// plan (risk.mjs, before the code) and the gate (after it).
export const statesNamed = (doc) => [...new Set(specsOf(doc).flatMap((s) => (s.text.match(/\bstates?:\s*([^·]+)/i)?.[1] ?? '').split(/[,;]/).map((x) => x.trim()).filter(Boolean)))];
export const statesLacking = (doc) => {
  const probed = new Set(gateLinesOf(doc).map((l) => l.match(/^probe\s+([^:[]+?)\s*(?:\[[^\]]*\])?\s*:/i)?.[1]?.toLowerCase()).filter(Boolean));
  return statesNamed(doc).filter((x) => !probed.has(x.toLowerCase()));
};
export const statesCheck = (cardDir) => {
  if (!lensesOf(cardDir).includes('visual')) return [];
  const doc = readCard(cardDir) ?? '';
  const named = statesNamed(doc);
  if (!named.length) return [];
  const lacking = statesLacking(doc);
  return [lacking.length ? couldNot('states', lacking.map((x) => `no probe for state ${x}`).join('; ') + ' (add `probe <state>: node .claude/tools/app.mjs probe <steps>.json --axe --contrast "…" --out .validation/probe/<state>` to ## Gate)') : ok('states', `${named.length} states, each with its probe`)];
};

// The `contract` lens asks for the HTTP attacks: `attacks: node .claude/tools/attack.mjs <url> … --body-limit <bytes>` in `## Gate`.
export const hasAttacksLine = (doc) => gateLinesOf(doc).some((l) => /^attacks\s*(\[[^\]]*\])?\s*:/i.test(l));
export const attacksCheck = (cardDir) => {
  if (!lensesOf(cardDir).includes('contract')) return [];
  return [hasAttacksLine(readCard(cardDir) ?? '') ?ok('attacks', 'the gate has its attacks line') : failed('attacks', 'contract lens without attacks line')];
};

// The visual rounds: with the `visual` lens the designer leaves the capture of the reference in `specs/<card>/ref/`, and
// `specs/<card>/rondas.md` with one `## Round <k>` per round (2 at least), each with 3 differences or more that carry a change
// (a line that says «sin cambios», «correcto» or «ok» is not one; round 1 alone may carry one `at level · <evidence>` line instead); the captures of the last round are in
// `specs/<card>/rondas/r<k>/` (one folder per round, the probe's `--out`). A form check: it counts headings, lines and files.
export const MIN_ROUNDS = 2;
export const MIN_DIFFERENCES = 3;
const NO_CHANGE = /sin cambios|sin diferencias|no changes?\b|unchanged|correcto|\bok\b/i;
const IMAGE = /\.(?:png|jpe?g|webp)$/i;
// The only way out of a round 1 with no change: `at level · <evidence>` that names 3 aspects at least (hierarchy, typography,
// depth or color, composition, motion or states) and the capture of the reference in `ref/` it was compared with.
const ASPECTS = [/hierarch|jerarqu/i, /typograph|tipograf/i, /depth|profundidad|color/i, /composition|composici/i, /motion|states?\b|estados?/i];
export const atLevelEvidence = (line) => {
  const m = line.match(/^\s*(?:(?:\d+[.)]|[-*])\s+)?at level\s*·\s*(.+)$/i);
  return Boolean(m) && /\bref\/\S+\.(?:png|jpe?g|webp)/i.test(m[1]) && ASPECTS.filter((a) => a.test(m[1])).length >= 3;
};
export const roundsCheck = (cardDir) => {
  if (!lensesOf(cardDir).includes('visual')) return [];
  const dir = join(cardDir, 'rondas');
  const folders = existsSync(dir) ? readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory() && /^r\d+$/.test(e.name)).map((e) => e.name).sort((a, b) => Number(a.slice(1)) - Number(b.slice(1))) : [];
  const last = folders.at(-1);
  const images = (d, pattern) => existsSync(d) && readdirSync(d, { withFileTypes: true }).some((e) => (e.isFile() && pattern.test(e.name)) || (e.isDirectory() && images(join(d, e.name), pattern)));
  const notes = existsSync(join(cardDir, 'rondas.md')) ? readFileSync(join(cardDir, 'rondas.md'), 'utf8') : '';
  const blocks = notes.split(/^(?=##\s+(?:Round|Ronda)\s+\d+)/im).filter((b) => /^##\s+(?:Round|Ronda)\s+\d+/i.test(b));
  const thin = blocks.flatMap((b) => {
    const lines = b.split(/\r?\n/).slice(1);
    const first = /^##\s+(?:Round|Ronda)\s+1\b/i.test(b);
    const changes = first && lines.some(atLevelEvidence) ? MIN_DIFFERENCES : lines.filter((l) => /^\s*(?:\d+[.)]|[-*])\s+\S/.test(l) && !NO_CHANGE.test(l)).length;
    return changes < MIN_DIFFERENCES ? [`${b.match(/^##\s+(\S+\s+\d+)/)[1]} has ${changes} differences with a change (${MIN_DIFFERENCES} at least)`] : [];
  });
  const problems = [
    blocks.length < MIN_ROUNDS ? `${blocks.length} rounds in rondas.md (${MIN_ROUNDS} at least)` : null,
    ...thin,
    images(join(cardDir, 'ref'), IMAGE) ? null : 'no capture of the reference in ref/',
    last && images(join(dir, last), /\.png$/i) ? null : 'no captures of the last round (rondas/r<k>/)',
  ].filter(Boolean);
  return [problems.length ? failed('rounds', `visual rounds: ${problems.join('; ')}`) : ok('rounds', `${blocks.length} rounds, the reference in ref/ and the captures of ${last} are there`)];
};

// The layers: a `rule` file (domain) does no I/O, SQL lives only in `data` files, a `presentation` file has no db access.
// The roles come from `## Tasks` (`src/db.mjs (data)`); the files looked at are the card's production files in the diff.
const NO_IO = [
  ['fetch', /\bfetch\s*\(/],
  ['fs', /\bfrom\s+['"](?:node:)?fs(?:\/promises)?['"]|\brequire\s*\(\s*['"](?:node:)?fs(?:\/promises)?['"]|\bfs(?:\.promises)?\.\w+\s*\(/],
  ['process.env', /\bprocess\.env\b/],
  ['console', /\bconsole\.\w+/],
  ['document', /\bdocument\./],
  ['window', /\bwindow\./],
  ['localStorage', /\blocalStorage\b/],
  ['Date.now', /\bDate\.now\s*\(/],
  ['new Date()', /\bnew\s+Date\s*\(\s*\)/],
  ['Math.random', /\bMath\.random\s*\(/],
];
const SQL = /\b(?:SELECT|INSERT|UPDATE|DELETE)\b[\s\S]{0,80}\b(?:FROM|INTO|SET)\b/i;
const DB_CALL = /\b[\w.]*db\w*\.(?:prepare|exec|query)\s*\(/i;
// Comments are blanked (line numbers stay) so that a word in a comment does not count.
const blankComments = (code) => code.replace(/\/\*[\s\S]*?\*\/|(^|[^:'"`])\/\/[^\n]*/g, (m, lead) => (lead ?? '') + m.slice((lead ?? '').length).replace(/[^\n]/g, ' '));

// The layer a production file has in `## Tasks`: its own path, or the path it ends with.
export const roleFor = (roles, file) => roles.get(file) ?? [...roles].find(([f]) => file.endsWith(`/${f}`))?.[1];

export const layersCheck = (root, cardDir) => {
  const roles = rolesOf(readCard(cardDir) ?? '');
  if (!roles.size) return couldNot('layers', 'no file roles in ## Tasks');
  const files = cardFiles(root, cardStart(root, cardDir)).filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && existsSync(join(root, f)));
  const found = [];
  for (const file of files) {
    const role = roleFor(roles, file);
    if (role === 'data') continue;
    let text;
    try { text = blankComments(readFileSync(join(root, file), 'utf8')); } catch { continue; }
    const lines = text.split('\n');
    const at = (re) => { const i = lines.findIndex((l) => re.test(l)); return i < 0 ? null : i + 1; };
    if (role === 'rule') for (const [name, re] of NO_IO) { const n = at(re); if (n) found.push(`${file}:${n} rule file does I/O (${name})`); }
    const hit = SQL.exec(text);
    const sql = hit ? text.slice(0, hit.index).split('\n').length : at(DB_CALL);
    if (sql) found.push(`${file}:${sql} ${role === 'presentation' ? 'presentation file has SQL or db access' : 'SQL outside a data file'}`);
  }
  return found.length ? failed('layers', found.slice(0, 5).join('; ')) : ok('layers', `${files.length} production files, the layers hold`);
};

// A fresh migration with more than one statement runs inside a transaction: `BEGIN`/`COMMIT` in the file, or a runner in
// the card's production code that wraps each migration in one.
const statementsIn = (sql) => sql.replace(/--[^\n]*|\/\*[\s\S]*?\*\//g, '').split(';').filter((s) => s.trim()).length;
const WRAPS = /\b(?:BEGIN|START\s+TRANSACTION|COMMIT)\b|\.transaction\s*\(|\b(?:with|in)Transaction\b|\bbeginTransaction\b/i;
export const migrationsCheck = (root, cardDir) => {
  const fresh = migrationsOutlook(root).fresh.filter((f) => /\.sql$/i.test(f));
  const read = (f) => { try { return readFileSync(join(root, f), 'utf8'); } catch { return ''; } };
  const open = fresh.filter((f) => statementsIn(read(f)) > 1 && !WRAPS.test(read(f)));
  if (!open.length) return ok('migrations', `${fresh.length} fresh migrations, each atomic`);
  const runner = cardFiles(root, cardStart(root, cardDir)).some((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && !IS_MIGRATION.test(f) && existsSync(join(root, f)) && /migrat/i.test(read(f)) && WRAPS.test(read(f)));
  return runner ? ok('migrations', `${fresh.length} fresh migrations, wrapped by the runner`) : failed('migrations', `${open.slice(0, 5).join(', ')}: more than one statement outside a transaction (BEGIN/COMMIT in the file, or a runner that wraps it)`);
};

// `no-visual: <why>` in `## Gate` says the card touches code files that build markup without changing what a screen shows. It is a
// declaration, not a command: risk.mjs keeps the visual lens off for it and this check holds it against the card's diff.
export const noVisualOf = (doc) => gateLinesOf(doc).map((l) => l.match(/^no-visual\s*:\s*(\S.*)$/i)?.[1]?.trim()).find(Boolean) ?? null;
const declaredVisual = (cardDir) => riskOf(cardDir)?.declared?.find((d) => d.lens === 'visual') ?? null;
export const noVisualCheck = (root, cardDir) => {
  const declared = declaredVisual(cardDir);
  if (!declared) return [];
  const diff = spawnSync('git', ['diff', '-U0', '--no-color', `${cardStart(root, cardDir)}..HEAD`, '--', ...declared.files], { cwd: root, encoding: 'utf8', maxBuffer: 1 << 28 });
  if (diff.status !== 0) return [couldNot('no-visual', `git diff failed: ${(diff.stderr ?? '').trim().split('\n')[0]}`)];
  let file = '';
  for (const l of diff.stdout.split('\n')) {
    if (l.startsWith('+++ ')) { file = l.slice(4).replace(/^b\//, ''); continue; }
    if (l.startsWith('--- ') || !/^[+-]/.test(l)) continue;
    if (SCREEN_MARKUP.test(l.slice(1))) return [failed('no-visual', `${file} changes markup: ${l.slice(1).trim()}`)];
  }
  return [ok('no-visual')];
};

// The checks that read the card: verify.mjs adds them to the gate's. `layers` and `migrations` read the repo too, so they need `root`.
export const cardChecks = (cardDir, root) => [...statesCheck(cardDir), ...attacksCheck(cardDir), ...roundsCheck(cardDir), ...(root ? [layersCheck(root, cardDir), migrationsCheck(root, cardDir), ...noVisualCheck(root, cardDir)] : [])];

const NO_PROBE = 'no record in .validation/probe: run `node .claude/tools/app.mjs probe <steps.json> --axe --contrast "<status selectors>"` (a `probe:` line in ## Gate does it)';

// The four checks of the computed CSS the probe records on every step. `fonts`: two type families at most (icon fonts and
// code monospace aside). `sizes`: information for the judge, never a failure (fluid type multiplies the computed sizes;
// a `passed` whose detail starts `info:`). `controls`: fails when more than half of the action controls have no transition
// or animation, otherwise it lists them as info. `reduced-motion`: fails on large or continuous movement (infinite or over
// 1 s, on transform or position) under prefers-reduced-motion. Cheap and deterministic; none for a probe from before it
// recorded `design`.
export const MAX_FAMILIES = 2;
export const MAX_SIZES = 8;
export const designChecks = (records) => {
  const seen = records.filter((r) => r.design);
  if (!seen.length) return [];
  const out = [];
  const families = [...new Set(seen.flatMap((r) => r.design.families))];
  out.push(families.length > MAX_FAMILIES ? failed('fonts', `${families.length} type families (max ${MAX_FAMILIES}): ${families.slice(0, 5).join(', ')}`) : ok('fonts', `${families.length} type families`));
  const worst = seen.reduce((a, r) => (r.design.sizes.length > a.design.sizes.length ? r : a));
  out.push(ok('sizes', `info: ${worst.design.sizes.length} font sizes at most per step (${worst.file}, soft max ${MAX_SIZES}): ${worst.design.sizes.join(', ')}`));
  const still = seen.filter((r) => r.design.unanimatedCount > 0);
  const lack = (r) => `${r.file}: ${r.design.unanimatedCount} of ${r.design.controls} action controls with no transition or animation (${r.design.unanimated.slice(0, 8).join(', ')})`;
  const mostly = still.filter((r) => r.design.unanimatedCount * 2 > r.design.controls);
  if (mostly.length) out.push(failed('controls', mostly.slice(0, 3).map(lack).join('; ')));
  else out.push(ok('controls', still.length ? `info: ${still.slice(0, 3).map(lack).join('; ')}` : `${seen.reduce((n, r) => Math.max(n, r.design.controls), 0)} action controls at most, each with its response`));
  const reduced = seen.filter((r) => r.reduced);
  if (!reduced.length) out.push(couldNot('reduced-motion', 'the probe did not measure prefers-reduced-motion'));
  else {
    const moving = reduced.filter((r) => r.reduced.moving > 0);
    out.push(moving.length ? failed('reduced-motion', moving.slice(0, 3).map((r) => `${r.file}: ${r.reduced.moving} large or continuous movements still run with prefers-reduced-motion (${(r.reduced.items ?? []).join(', ')})`).join('; ')) : ok('reduced-motion', 'no large or continuous movement with prefers-reduced-motion'));
  }
  return out;
};

// The three checks of a screen, over the probe's records: axe violations, the contrast of the status texts, and the
// focus after a failed submit (a step that leaves an alert on the page must leave the focus on an element).
export const screenChecks = (records) => {
  if (!records.length) return ['axe', 'contrast', 'focus'].map((n) => couldNot(n, NO_PROBE));
  const out = [];
  if (records.every((r) => r.axe === null || r.axe === undefined)) out.push(couldNot('axe', 'the probe ran without --axe'));
  else {
    const bad = records.flatMap((r) => (r.axe?.violations ?? []).map((v) => `${r.file} ${v.id} (${v.impact ?? 'n/a'})`));
    out.push(bad.length ? failed('axe', bad.slice(0, 5).join('; ')) : ok('axe', `${records.length} steps, no violation`));
  }
  const measured = records.flatMap((r) => [...(r.contrast ?? []), ...(r.statusContrast ?? [])].map((c) => ({ ...c, file: r.file })));
  if (!measured.length) out.push(couldNot('contrast', 'the probe ran without --contrast over the status texts'));
  else {
    const bad = measured.filter((c) => c.found !== false && c.aa === false).map((c) => `${c.file} ${c.selector} ${c.ratio}:1 (needs ${c.needed})`);
    out.push(bad.length ? failed('contrast', bad.slice(0, 5).join('; ')) : ok('contrast', `${measured.length} measures, all AA`));
  }
  const alerts = records.filter((r) => (r.announcements ?? []).some((a) => a.role === 'alert'));
  if (!alerts.length) out.push(couldNot('focus', 'no probe step leaves a role=alert on the page: there is no failed submit to look at'));
  else {
    const lost = alerts.filter((r) => !r.activeElement).map((r) => `${r.file} shows an alert and the focus is on nothing`);
    out.push(lost.length ? failed('focus', lost.slice(0, 5).join('; ')) : ok('focus', `${alerts.length} steps with an alert keep the focus on an element`));
  }
  return [...out, ...designChecks(records)];
};
