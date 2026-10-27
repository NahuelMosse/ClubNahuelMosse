// The checks of the gate that are not a command of `## Gate`: they read what the card and the probe left on disk.
// Each returns `{ name, state: 'passed' | 'failed' | 'could not run', detail }`; verify.mjs prints one line per check.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { basename, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { cardIdOf, gateBlock, readCard, riskOf, rolesOf, specTagsIn, specsOf, tasksOf } from './card-doc.mjs';
import { IS_CODE, IS_TEST, NOT_PRODUCTION, cardFiles, cardStart } from './card.mjs';
import { IS_MIGRATION, migrationsOutlook } from './migrations.mjs';
import { overdesignFindings } from './overdesign.mjs';
import { active, profileStates } from './kit.mjs';
import { IS_SCREEN, SCREEN_MARKUP } from './signals.mjs';
import { sectionOf } from './card-doc.mjs';

// bot-wall.mjs and copy-lint.mjs come with the web profile: the base alone installs without them, and their checks only run on visual cards.
const optional = async (file) => { try { return await import(file); } catch { return null; } };
const botWall = await optional('./bot-wall.mjs');
const copyLint = await optional('./copy-lint.mjs');


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
// The instrument of the visual lens depends on the profiles that are on: `probe` for web (the browser probe), `golden` for flutter
// (`kitGolden` in test/kit). Both when both profiles are on; with no kit.json to say, `probe`, as it always was. Given the card,
// one whose task files have Dart and no web screen is a Flutter screen even with web on: goldens and kitA11y, no browser.
export const visualInstruments = (root, doc = null) => {
  let states = {};
  try { states = root ? profileStates(root) : {}; } catch { states = {}; }
  const flutter = states.flutter?.state === 'on';
  const web = states.web?.state === 'on';
  const files = doc ? tasksOf(doc).flatMap((t) => t.files) : [];
  if (flutter && web && files.some((f) => f.endsWith('.dart')) && !files.some((f) => IS_SCREEN.test(f))) return { probe: false, golden: true };
  return { probe: web || !flutter, golden: flutter };
};

// `remove-only: <what goes>` in `## Look`: the card only takes something off a screen (a notice, an error screen). There is no new
// look to bring to a reference, so no `ref:`, no design rounds and no round.json; the states, a11y and screen checks still run on
// what remains. This check holds it against the diff: the card's presentation files lose more lines than they gain.
export const removeOnlyOf = (doc) => sectionOf(doc ?? '', 'Look')?.match(/^\s*(?:[-*]\s*)?remove-only:\s*(\S.*)$/im)?.[1].trim() ?? null;
export const removeOnlyCheck = (root, cardDir) => {
  const doc = readCard(cardDir) ?? '';
  if (!removeOnlyOf(doc)) return [];
  const roles = rolesOf(doc);
  const files = [...new Set(tasksOf(doc).flatMap((t) => t.files))].filter((f) => roleFor(roles, f) === 'presentation' || IS_SCREEN.test(f) || f.endsWith('.dart'));
  if (!files.length) return [failed('remove-only', 'no presentation file in ## Tasks to take something off')];
  const diff = spawnSync('git', ['diff', '--numstat', `${cardStart(root, cardDir)}..HEAD`, '--', ...files], { cwd: root, encoding: 'utf8', maxBuffer: 1 << 28 });
  if (diff.status !== 0) return [couldNot('remove-only', `git diff failed: ${(diff.stderr ?? '').trim().split('\n')[0]}`)];
  const [added, removed] = diff.stdout.split('\n').filter(Boolean).reduce(([a, r], l) => { const [x, y] = l.split('\t'); return [a + (Number(x) || 0), r + (Number(y) || 0)]; }, [0, 0]);
  return [removed > added ? ok('remove-only', `the presentation files lose ${removed} lines and gain ${added}`) : failed('remove-only', `the presentation files gain ${added} lines and lose ${removed}: the card adds look, so it needs ## Look with ref: and the rounds`)];
};
const instrumentList = (instruments) => [...(instruments.probe ? ['probe'] : []), ...(instruments.golden ? ['golden'] : [])];
export const statesLacking = (doc, instruments = { probe: true, golden: false }) => {
  const kinds = instrumentList(instruments);
  const covered = new Set(gateLinesOf(doc).map((l) => l.match(new RegExp(`^(?:${kinds.join('|')})\\s+([^:[]+?)\\s*(?:\\[[^\\]]*\\])?\\s*:`, 'i'))?.[1]?.toLowerCase()).filter(Boolean));
  return statesNamed(doc).filter((x) => !covered.has(x.toLowerCase()));
};
export const statesCheck = (cardDir, root) => {
  if (!lensesOf(cardDir).includes('visual')) return [];
  const doc = readCard(cardDir) ?? '';
  const named = statesNamed(doc);
  if (!named.length) return [];
  const instruments = visualInstruments(root, doc);
  const lacking = statesLacking(doc, instruments);
  const kind = instrumentList(instruments).join(' or ');
  const hints = [
    instruments.probe ? 'probe <state>: node .claude/tools/app.mjs probe <steps>.json --axe --contrast "…" --out .validation/probe/<state>' : null,
    instruments.golden ? 'golden <state>: flutter test <file> (kitGolden)' : null,
  ].filter(Boolean).map((h) => `\`${h}\``).join(' or ');
  return [lacking.length ? couldNot('states', lacking.map((x) => `no ${kind} for state ${x}`).join('; ') + ` (add ${hints} to ## Gate)`) : ok('states', `${named.length} states, each with its ${kind}`)];
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
  if (!lensesOf(cardDir).includes('visual') || removeOnlyOf(readCard(cardDir))) return [];
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

// `ref-genre: <genre>` in `## Look` declares the field of the reference. `ref/` then holds its captures, named
// `<genre>-<site>-<width>-<NN>.png`, 8 or more per width (390 and 1440), none a bot wall or an error page: the capture tool writes
// `ref/captures.json` (`[{ "file", "status", "title", "text" }]`) and bot-wall.mjs reads each entry. No declaration, no check.
export const REF_FRAMES = 8;
export const REF_WIDTHS = [390, 1440];
export const refGenreOf = (doc) => sectionOf(doc, 'Look')?.match(/^\s*(?:[-*]\s*)?ref-genre:\s*(\S.*)$/im)?.[1].trim() ?? null;
export const refGenreCheck = (cardDir) => {
  if (!lensesOf(cardDir).includes('visual')) return [];
  const genre = refGenreOf(readCard(cardDir) ?? '');
  if (!genre) return [];
  const slug = genre.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  const dir = join(cardDir, 'ref');
  const files = existsSync(dir) ? readdirSync(dir).filter((f) => f.startsWith(`${slug}-`) && IMAGE.test(f)) : [];
  const per = (w) => files.filter((f) => new RegExp(`-${w}-\\d+\\.\\w+$`).test(f)).length;
  const short = REF_WIDTHS.filter((w) => per(w) < REF_FRAMES).map((w) => `${w} px has ${per(w)} captures of ${genre} (${REF_FRAMES} at least, named ${slug}-<site>-${w}-<NN>.png)`);
  if (short.length) return [failed('ref', short.join('; '))];
  let manifest = null;
  try { manifest = JSON.parse(readFileSync(join(dir, 'captures.json'), 'utf8')); } catch { /* absent */ }
  if (!Array.isArray(manifest)) return [couldNot('ref', `${files.length} captures of ${genre}, but ref/captures.json is missing: no way to tell a bot wall or an error page`)];
  if (!botWall) return [couldNot('ref', 'bot-wall.mjs is not installed (web profile off): no way to tell a bot wall or an error page')];
  const walls = manifest.flatMap((c) => { const why = botWall.reasonOf({ status: Number(c.status ?? 0), title: String(c.title ?? ''), text: String(c.text ?? ''), html: '' }); return why ? [`${c.file}: ${why}`] : []; });
  const unlisted = files.filter((f) => !manifest.some((c) => c.file === f));
  if (walls.length) return [failed('ref', `bot wall or error page in ref/: ${walls.slice(0, 5).join('; ')}`)];
  if (unlisted.length) return [couldNot('ref', `${unlisted.length} captures not in ref/captures.json (${unlisted.slice(0, 3).join(', ')}): not checked for a bot wall`)];
  return [ok('ref', `${files.length} captures of ${genre}, ${REF_FRAMES}+ at each of ${REF_WIDTHS.join(' and ')} px, none a bot wall`)];
};

// What design-round.mjs measured (`specs/<card>/rondas/r<k>/round.json`, the last round): the dead-click sweep fails on one
// dead control, the copy lint on any finding. No round.json is a check that could not run, never a pass.
export const lastRound = (cardDir) => {
  const dir = join(cardDir, 'rondas');
  const folders = existsSync(dir) ? readdirSync(dir, { withFileTypes: true }).filter((e) => e.isDirectory() && /^r\d+$/.test(e.name)).map((e) => e.name).sort((a, b) => Number(a.slice(1)) - Number(b.slice(1))) : [];
  try { return folders.length ? { name: folders.at(-1), round: JSON.parse(readFileSync(join(dir, folders.at(-1), 'round.json'), 'utf8')) } : null; } catch { return null; }
};
// The sweep and the copy lint read a page in a browser: a Flutter screen or a remove-only card has no round.json.
export const designRoundChecks = (cardDir, root) => {
  const doc = readCard(cardDir);
  if (!lensesOf(cardDir).includes('visual') || removeOnlyOf(doc) || !visualInstruments(root, doc).probe) return [];
  const last = lastRound(cardDir);
  const none = 'no rondas/r<k>/round.json: run `node .claude/tools/design-round.mjs <url> --out specs/<card>/rondas/r<k>`';
  if (!last) return [couldNot('dead-clicks', none), couldNot('copy', none)];
  const out = [];
  const sweeps = Object.entries(last.round.widths ?? {}).filter(([, w]) => w.sweep);
  if (!sweeps.length) out.push(couldNot('dead-clicks', `${last.name}/round.json has no sweep (widths 390 touch and 1440)`));
  else {
    const dead = sweeps.flatMap(([key, w]) => w.sweep.dead.map((d) => `${d.selector} (${key}, ${d.reason}, ${d.capture})`));
    out.push(dead.length ? failed('dead-clicks', `${dead.length} dead controls: ${dead.slice(0, 5).join('; ')}`) : ok('dead-clicks', `${sweeps.map(([key, w]) => `${key}: ${w.sweep.checked}`).join(', ')} controls, each with an effect`));
  }
  if (!last.round.copy) out.push(couldNot('copy', `${last.name}/round.json has no copy`));
  else if (!copyLint) out.push(couldNot('copy', 'copy-lint.mjs is not installed (web profile off)'));
  else {
    const found = copyLint.lintCopy(last.round.copy);
    out.push(found.length ? failed('copy', found.slice(0, 5).map((c) => `${c.rule}: ${c.detail}`).join('; ')) : ok('copy', 'copy lint: 0 findings'));
  }
  return out;
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

// Readability: a file is one concept. A production file that has a top-level class and a top-level function, more than one class, or
// a name of a grab-bag (utils, helpers, manager, misc, common) fails; `kit-shape: <reason>` anywhere in the file declares it.
const GRAB_BAG = /(^|\/)(utils?|helpers?|managers?|misc|common)(\.[a-z]+)*\.[a-z]+$/i;
const TOP_CLASS = /^(?:export\s+)?(?:default\s+)?(?:abstract\s+)?class\s+\w+/;
const TOP_FN = /^(?:export\s+)?(?:default\s+)?(?:async\s+)?function\b|^export\s+const\s+\w+\s*=\s*(?:async\s*)?(?:\([^)]*\)|\w+)\s*(?::[^=]+)?=>|^(?:async\s+)?def\s+\w+/;
export const shapeProblems = (file, text) => {
  if (/kit-shape:\s*\S/.test(text)) return [];
  const lines = blankComments(text).split('\n');
  const classes = lines.filter((l) => TOP_CLASS.test(l)).length;
  const fns = lines.filter((l) => TOP_FN.test(l)).length;
  const out = [];
  if (GRAB_BAG.test(file)) out.push(`${file}: a grab-bag file name (utils, helpers, manager, misc, common) · name the file for the one concept it holds`);
  if (classes && fns) out.push(`${file}: a class and ${fns} top-level function(s) in one file · the class alone, the functions in their own module file`);
  if (classes > 1) out.push(`${file}: ${classes} classes in one file · one class per file`);
  return out;
};
// Only what the card made worse: a file that already had two classes before the card is the repo's, not the card's, and asking a
// card to annotate it cost a whole suite run per round (the annotation changes the code's key).
export const shapeCheck = (root, cardDir) => {
  const base = cardStart(root, cardDir);
  const files = cardFiles(root, base).filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && existsSync(join(root, f)));
  const before = (f) => { const r = spawnSync('git', ['show', `${base}:${f}`], { cwd: root, encoding: 'utf8', maxBuffer: 1 << 26 }); return r.status === 0 ? r.stdout : null; };
  const found = files.flatMap((f) => {
    try {
      const now = shapeProblems(f, readFileSync(join(root, f), 'utf8'));
      const old = before(f);
      // Compared by kind, not by count: one more function in a file that already mixed them is not a new problem.
      const kind = (p) => p.replace(/\d+/g, 'N');
      const had = new Set(old === null ? [] : shapeProblems(f, old).map(kind));
      return now.filter((p) => !had.has(kind(p)));
    } catch { return []; }
  });
  return found.length ? failed('shape', found.slice(0, 5).join('; ')) : ok('shape', `${files.length} production files, one concept each`);
};

// Boundaries between slices (rules/architecture.md, "Module boundaries"): `shared/` imports no slice, a slice enters another
// only by its public index, a slice's index lists what it exports (no `export *`), and no folder is a grab-bag. It reads only
// the card's files, so what the repo already had is not this card's failure. `kit-boundary: <reason>` in the file declares it.
const SLICE = /(?:^|\/)(modules|features)\/([^/]+)(?:\/(.*))?$/;
const IN_SHARED = /(?:^|\/)shared\//;
const GRAB_DIR = /(?:^|\/)(common|core|utils?|helpers?|misc|managers?)\//i;
const SPECIFIERS = /\bfrom\s*['"]([^'"]+)['"]|\bimport\s*\(\s*['"]([^'"]+)['"]\s*\)|\brequire\s*\(\s*['"]([^'"]+)['"]\s*\)|^\s*import\s+['"]([^'"]+)['"]/gm;
const resolveSpecifier = (file, spec) => {
  if (!spec.startsWith('.')) return spec;
  const parts = file.split('/').slice(0, -1);
  for (const p of spec.split('/')) { if (p === '..') parts.pop(); else if (p !== '.') parts.push(p); }
  return parts.join('/');
};
const isIndex = (rest) => !rest || /^index(\.[a-z]+)?$/i.test(rest);
export const boundaryProblems = (file, text) => {
  if (/kit-boundary:\s*\S/.test(text)) return [];
  const code = blankComments(text);
  const out = [];
  const own = file.match(SLICE);
  const grab = file.match(GRAB_DIR);
  if (grab) out.push(`${file}: a grab-bag folder (${grab[1]}/) · name the folder for the concept it holds (shared/money/, shared/errors/)`);
  if (own && isIndex(own[3]) && /^\s*export\s*\*\s*from\b/m.test(code)) out.push(`${file}: \`export *\` in a slice's public index · list what is public by name`);
  for (const m of code.matchAll(SPECIFIERS)) {
    const target = resolveSpecifier(file, m[1] ?? m[2] ?? m[3] ?? m[4]).match(SLICE);
    if (!target) continue;
    if (IN_SHARED.test(file) && !own) out.push(`${file}: shared/ imports the slice ${target[2]} · shared knows no slice; move the piece into it or pass it as a parameter`);
    else if (own && own[2] !== target[2] && !isIndex(target[3])) out.push(`${file}: reaches inside the slice ${target[2]} (${target[3]}) · import its public index`);
  }
  return [...new Set(out)];
};
export const boundariesCheck = (root, cardDir) => {
  const files = cardFiles(root, cardStart(root, cardDir)).filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && existsSync(join(root, f)));
  const found = files.flatMap((f) => { try { return boundaryProblems(f, readFileSync(join(root, f), 'utf8')); } catch { return []; } });
  return found.length ? failed('boundaries', found.slice(0, 5).join('; ')) : ok('boundaries', `${files.length} production files, each slice entered by its index`);
};

// The docs are a product built with the product (templates/docs.md): with the docs module on (mvp and up), a card that changes
// production code updates, in its own diff, the feature page that tells it (`docs/features/<feature>.md`, whose `tests:` names the
// card's tagged test files and whose body has its rules and edge cases), the API contract when it touches a route, and
// `docs/data-model.md` when it touches the schema. `no-docs: <why>` in `## Gate` declares a card that changes no behavior.
const FEATURE_PAGE = /^docs\/features\/.+\.md$/;
const CONTRACT = /(^|\/)(openapi|asyncapi|swagger)[^/]*\.(ya?ml|json)$|(^|\/)schema\.graphql$|^docs\/api\//i;
const DATA_MODEL = /^docs\/data-model\.md$/;
const API_FILE = /(^|\/)(api|routes?|controllers?|handlers?|endpoints?|resolvers?)\/|\.(controller|routes?|resolver)\.[a-z]+$/i;
const DATA_FILE = /(^|\/)(migrations?|schema|models?|entities)\/|\.(entity|model)\.[a-z]+$|(^|\/)schema\.prisma$|\.sql$/i;
export const noDocsOf = (doc) => gateLinesOf(doc).map((l) => l.match(/^no-docs\s*:\s*(\S.*)$/i)?.[1]?.trim()).find(Boolean) ?? null;
const frontList = (text, key) => (text.match(new RegExp(`^${key}:\\s*\\[([^\\]]*)\\]`, 'm'))?.[1] ?? '').split(',').map((s) => s.trim().replace(/^["']|["']$/g, '')).filter(Boolean);
export const docsProblems = ({ files, read, id, roles = new Map() }) => {
  const code = files.filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && !IS_TEST.test(f));
  const touchesData = files.some((f) => !IS_TEST.test(f) && (DATA_FILE.test(f) || roles.get(f) === 'data'));
  if (!code.length && !touchesData) return [];
  const out = [];
  const pages = files.filter((f) => FEATURE_PAGE.test(f));
  const tagged = files.filter((f) => IS_TEST.test(f) && id && read(f).includes(`@${id}-S`));
  if (code.length && !pages.length) out.push(`the card changes production code and no docs/features/<feature>.md in its diff · update the page of the feature it changes (template: .claude/templates/docs.md), or \`no-docs: <why>\` in ## Gate when no behavior changes`);
  for (const p of pages) {
    const text = read(p);
    if (!/^##\s+(Rules|Reglas)/im.test(text) || !/^##\s+(Edge cases|Casos borde)/im.test(text)) out.push(`${p}: no \`## Rules\` and \`## Edge cases\` sections`);
  }
  const listed = new Set(pages.flatMap((p) => frontList(read(p), 'tests')));
  const missing = tagged.filter((t) => !listed.has(t));
  if (pages.length && missing.length) out.push(`the feature page's \`tests:\` does not name ${missing.join(', ')}, the card's tests · list them, and close each edge case with \`Tested: <test>\`, \`No test.\` or \`To decide: <AMB/ASM>\``);
  if (code.some((f) => API_FILE.test(f)) && !files.some((f) => CONTRACT.test(f))) out.push('the card touches a route and the API contract (openapi.yaml under docs/api/, or the repo\'s spec) is not in its diff · update the contract');
  if (touchesData && !files.some((f) => DATA_MODEL.test(f))) out.push('the card touches the schema or a data file and docs/data-model.md is not in its diff · update the entity, its relations and its diagram');
  return out;
};
export const docsCheck = (root, cardDir) => {
  let on;
  try { ({ on } = active(root)); } catch { return []; }
  if (!on?.has('docs')) return [];
  const doc = readCard(cardDir) ?? '';
  const declared = noDocsOf(doc);
  if (declared) return [ok('docs', `declared: ${declared}`)];
  const files = cardFiles(root, cardStart(root, cardDir)).filter((f) => existsSync(join(root, f)));
  const read = (f) => { try { return readFileSync(join(root, f), 'utf8'); } catch { return ''; } };
  const found = docsProblems({ files, read, id: cardIdOf(cardDir), roles: rolesOf(doc) });
  return [found.length ? failed('docs', found.slice(0, 5).join('; ')) : ok('docs', 'the feature page, the contract and the data model follow the code')];
};

// The table baseline (DB-MOD-03, DB-MOD-14, P17) over the `CREATE TABLE` of the card's SQL migrations, which Prisma, Drizzle and
// TypeORM also write: a primary key per the repo's id decision (`ids: bigint` in docs/data-model.md allows an identity bigint;
// otherwise a UUID), never serial or an int, and `created_at`/`updated_at` with time zone. `-- kit-table: append-only` above the
// statement leaves only `created_at`; the migrations' own history table is not the app's.
const CREATE_TABLE = /(--\s*kit-table:\s*append-only\s*\n\s*)?CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([`"\w.]+)\s*\(/gi;
const HISTORY_TABLE = /^[`"]?(_prisma_migrations|schema_migrations|knex_migrations|__drizzle_migrations|flyway_schema_history|alembic_version|__efmigrationshistory|django_migrations|typeorm_migrations|migrations)[`"]?$/i;
const bodyAt = (sql, from) => { let depth = 1; let i = from; for (; i < sql.length && depth; i++) { if (sql[i] === '(') depth++; else if (sql[i] === ')') depth--; } return sql.slice(from, i - 1); };
const columnsOf = (body) => { const out = []; let depth = 0; let cur = ''; for (const c of body) { if (c === '(') depth++; if (c === ')') depth--; if (c === ',' && !depth) { out.push(cur.trim()); cur = ''; } else cur += c; } if (cur.trim()) out.push(cur.trim()); return out; };
const nameOf = (col) => col.match(/^[`"]?(\w+)[`"]?\s/)?.[1]?.toLowerCase() ?? '';
export const tableShapeProblems = (file, sql, { bigintIds = false } = {}) => {
  const out = [];
  for (const m of sql.matchAll(CREATE_TABLE)) {
    const table = m[2].split('.').pop();
    if (HISTORY_TABLE.test(table)) continue;
    const cols = columnsOf(bodyAt(sql, m.index + m[0].length));
    const plain = table.replace(/[`"]/g, '');
    const at = `${file}: table ${plain}`;
    const pkLine = cols.find((c) => /\bPRIMARY\s+KEY\b/i.test(c) && !/^(CONSTRAINT|PRIMARY)\b/i.test(c));
    const pkConstraint = cols.find((c) => /^(CONSTRAINT\s+\S+\s+)?PRIMARY\s+KEY\s*\(/i.test(c));
    const pkCols = pkLine ? [pkLine] : (pkConstraint?.match(/PRIMARY\s+KEY\s*\(([^)]*)\)/i)?.[1] ?? '').split(',').map((n) => n.trim().replace(/[`"]/g, '').toLowerCase()).filter(Boolean).map((n) => cols.find((c) => nameOf(c) === n) ?? '');
    if (!pkCols.length) out.push(`${at} has no primary key (DB-MOD-03)`);
    for (const pk of pkCols.length === 1 ? pkCols : []) {
      if (/\b(small|big)?serial\b|\bAUTO_?INCREMENT\b/i.test(pk)) out.push(`${at}: the primary key is serial or auto-increment · use UUIDv7, or \`bigint GENERATED ALWAYS AS IDENTITY\` with \`ids: bigint\` in docs/data-model.md (DB-MOD-03)`);
      else if (/^\S+\s+(int|integer|int4|smallint|mediumint)\b/i.test(pk)) out.push(`${at}: the primary key is an int · use UUIDv7 (DB-MOD-03)`);
      else if (/^\S+\s+(bigint|int8)\b/i.test(pk) && !bigintIds) out.push(`${at}: the primary key is a bigint and docs/data-model.md does not say \`ids: bigint\` · UUIDv7 is the default (DB-MOD-03)`);
    }
    const appendOnly = Boolean(m[1]);
    for (const name of appendOnly ? ['created_at'] : ['created_at', 'updated_at']) {
      const col = cols.find((c) => [name, name.replace(/_(\w)/, (_, x) => x.toUpperCase())].includes(nameOf(c)) || nameOf(c) === name.replace('_', '').toLowerCase());
      if (!col) out.push(`${at} has no ${name} · \`${name} timestamptz NOT NULL DEFAULT now()\` (DB-MOD-14), or \`-- kit-table: append-only\` above an append-only table`);
      else if (/^\S+\s+timestamp\b(?!\s*(\(\d\))?\s*with\s+time\s+zone)/i.test(col)) out.push(`${at}: ${name} is a timestamp without time zone · \`timestamptz\` (Prisma: \`@db.Timestamptz(3)\`) (DB-MOD-14)`);
      else if (!/\bNOT\s+NULL\b/i.test(col)) out.push(`${at}: ${name} may be null · NOT NULL (DB-MOD-14)`);
    }
  }
  return out;
};
export const tableShapeCheck = (root, cardDir) => {
  const files = cardFiles(root, cardStart(root, cardDir)).filter((f) => IS_MIGRATION.test(f) && /\.sql$/i.test(f) && existsSync(join(root, f)));
  if (!files.length) return [];
  const read = (f) => { try { return readFileSync(join(root, f), 'utf8'); } catch { return ''; } };
  const bigintIds = /^\s*(?:[-*]\s*)?ids:\s*bigint\b/im.test(read('docs/data-model.md'));
  const found = files.flatMap((f) => tableShapeProblems(f, read(f), { bigintIds }));
  return [found.length ? failed('table-shape', found.slice(0, 6).join('; ')) : ok('table-shape', `${files.length} migrations, every new table with its key and its timestamps`)];
};

// Overdesign (overdesign.mjs): a pass-through method, an interface with one implementation, a folder with one tiny file or an empty layer
// folder fails when the card added it; the same already in the repo is a note, printed by verify.mjs.
export const overdesignCheck = (root, cardDir) => {
  let found;
  try { found = overdesignFindings(root, cardDir); } catch (e) { return couldNot('overdesign', e.message); }
  const result = found.blocking.length ? failed('overdesign', found.blocking.slice(0, 5).join('; ')) : ok('overdesign');
  return { ...result, notes: found.notes.map((n) => `note: overdesign · already in the repo, not from this card: ${n}`) };
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
export const cardChecks = (cardDir, root) => [...statesCheck(cardDir, root), ...attacksCheck(cardDir), ...roundsCheck(cardDir), ...refGenreCheck(cardDir), ...designRoundChecks(cardDir, root), ...(root ? [layersCheck(root, cardDir), shapeCheck(root, cardDir), overdesignCheck(root, cardDir), migrationsCheck(root, cardDir), boundariesCheck(root, cardDir), ...noVisualCheck(root, cardDir), ...removeOnlyCheck(root, cardDir), ...docsCheck(root, cardDir), ...tableShapeCheck(root, cardDir)] : [])];

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
