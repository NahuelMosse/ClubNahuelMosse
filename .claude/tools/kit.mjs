#!/usr/bin/env node
// kit.mjs — which modules of the kit are on in this repo, and the only way to change it.
//
//   kit.mjs status                       the grade, then one line per module: state, reason, signals seen now
//   kit.mjs on <module>                  copies the module's files from the registered source
//   kit.mjs off <module> --reason "…"    removes the files that are as installed; a person, no open card
//   kit.mjs confirm-off <module> --reason "…"
//                                        a signal that appeared after the decision does not change it
//   kit.mjs grade <poc|mvp|production> --reason "…"
//                                        how much the bar asks; it only goes up; a person, no open card
//   kit.mjs repair                       copies what an active module lacks
//   kit.mjs e2e <path>                   the folder of the scenario tests, in kit.json and in METHOD.md; allowed
//                                        with a card open, because a wrong folder is found while one is
//
// `.claude/kit.json` is written only here and by install.mjs: the guards refuse any other write.
// Without it every module is on, which is how the kit worked before there were modules; a module the
// manifest does not know counts as on, so a new version of the kit never turns one off in silence.
// Two states, `on` and `off`: `on` has the force of the core (its criteria enter the bar, its checks
// block the close); `off` is a human decision with its reason, repeated in every closing.
// The grade (`poc`, `mvp`, `production`; production without one) is another source of `off`: modules.json
// says which modules and which blocks of core criteria a grade leaves out, and every consumer asks
// `active()` / `offCriteria()` instead of knowing the grades. What a grade leaves out is named in the bar
// as `<block> · off by grade: <grade> — <reason>`; it is never removed in silence.
// Unattended (`SDD_UNATTENDED=1`) nobody decides to turn a check off: `off` exits 2, and so does
// `confirm-off` above poc; `on` passes and leaves an assumption event in the card, and so does `confirm-off`
// at poc, which only keeps off what a person turned off. Nobody lowers the grade or chooses poc either.
// Importing this file never writes anything.
import { createHash } from 'node:crypto';
import { copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync, appendFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { cardFiles, cardStart, currentCard, fileMapLines, git, pathTokens } from './card.mjs';
import { describe, detect, detectIn, evidenceOf, kindOf } from './signals.mjs';

export const KIT_JSON = '.claude/kit.json';

const readJson = (path) => JSON.parse(readFileSync(path, 'utf8'));

// The modules.json of a repo (installed or source): null if it has none.
export const readModules = (root) => {
  try { return readJson(join(root, '.claude', 'modules.json')); } catch { return null; }
};

// The hashes of the installed files live apart, so kit.json stays small enough to read.
export const KIT_FILES_JSON = '.claude/kit-files.json';

// The manifest: null without one; `{ invalid: true }` if it does not parse, which counts as «all on».
// `files` comes from kit-files.json; a kit.json written before the split still carries them inline.
export const readManifest = (root) => {
  const path = join(root, KIT_JSON);
  if (!existsSync(path)) return null;
  try {
    const manifest = readJson(path);
    const apart = join(root, KIT_FILES_JSON);
    if (existsSync(apart)) manifest.files = readJson(apart);
    return manifest;
  } catch { return { invalid: true }; }
};

export const writeManifest = (root, manifest) => {
  const { files, ...rest } = manifest;
  mkdirSync(join(root, '.claude'), { recursive: true });
  writeFileSync(join(root, KIT_JSON), `${JSON.stringify(rest, null, 2)}\n`);
  if (files) writeFileSync(join(root, KIT_FILES_JSON), `${JSON.stringify(files, null, 2)}\n`);
};

// Where a repo keeps its scenario tests, by the folders teams usually use, the most specific first.
// A hint only: `close.mjs` finds the card's tests by their tag.
// Flutter keeps its e2e in `integration_test/`, at the root or inside the app (`apps/<app>/integration_test`).
export const E2E_FOLDERS = ['apps/e2e', 'e2e', 'tests/e2e', 'test/e2e', 'integration_test', 'tests', 'test', '__tests__', 'spec'];
const isDir = (root, d) => existsSync(join(root, d)) && statSync(join(root, d)).isDirectory();
const nestedIntegration = (root) => {
  try {
    return readdirSync(join(root, 'apps')).sort().map((a) => `apps/${a}/integration_test`).find((d) => isDir(root, d));
  } catch { return undefined; }
};
export const detectE2e = (root) => E2E_FOLDERS.slice(0, 5).find((d) => isDir(root, d)) ?? nestedIntegration(root) ?? E2E_FOLDERS.slice(5).find((d) => isDir(root, d)) ?? null;

export const GRADES = ['poc', 'mvp', 'production'];
const rank = (grade) => GRADES.indexOf(grade);

// The grade the manifest records; what it does not say, or says wrongly, is production.
export const recordedGrade = (manifest) => (GRADES.includes(manifest?.grade?.level) ? manifest.grade.level : null);
export const gradeOf = (manifest) => recordedGrade(manifest) ?? 'production';

// What a grade leaves out, from modules.json: the modules whose `grades` say `off` at that grade or above
// (a module with no entry is on) and the blocks of `core.byGrade` of that grade and the ones above it.
// `skip` are modules a person already turned off: their line is theirs. Every block is
// `{ name, reason, criteria, module? }`; `without` are the agents the grade does not launch.
export const exemption = (map, grade, skip = new Set()) => {
  const level = map?.grades?.levels?.[grade] ?? null;
  const upward = GRADES.slice(rank(grade));
  const blocks = [];
  const modules = new Set();
  for (const [name, m] of Object.entries(map?.modules ?? {})) {
    if (m.installable === false || skip.has(name)) continue;
    if (upward.map((g) => m.grades?.[g]).find((s) => s !== undefined) !== 'off') continue;
    modules.add(name);
    // A module that owns no criterion (the opt-in ASVS level) has nothing to answer in the bar.
    if (m.criteria.length) blocks.push({ name, module: true, reason: m.gradeNote ?? `not part of the grade ${grade}`, criteria: m.criteria });
  }
  for (const g of upward)
    for (const [name, b] of Object.entries(map?.core?.byGrade?.[g] ?? {})) blocks.push({ name, reason: b.reason, criteria: b.criteria });
  // What a module that is on asks to build, not to meet, and the grade leaves out (a design line, a
  // component set, an audit, a capture width): a block with no criteria, from the lowest grade naming it.
  const procedures = new Set();
  for (const [name, m] of Object.entries(map?.modules ?? {})) {
    if (m.installable === false || skip.has(name) || modules.has(name)) continue;
    for (const g of upward)
      for (const [procedure, p] of Object.entries(m.gradeProcedures?.[g] ?? {})) {
        if (procedures.has(procedure)) continue;
        procedures.add(procedure);
        blocks.push({ name: procedure, procedure: true, reason: p.reason, criteria: [] });
      }
  }
  return {
    grade, level, blocks,
    procedures,
    modules,
    criteria: new Set(blocks.flatMap((b) => b.criteria)),
    without: new Set(level?.without ?? []),
  };
};

// `<block> · off by grade: <grade> — <reason>`: the line the bar, the plan and the closing carry for each block.
export const gradeLines = (exempt) => exempt.blocks.map((b) => `${b.name} · off by grade: ${exempt.grade} — ${b.reason}`);

export const active = (root) => {
  const map = readModules(root);
  const known = Object.entries(map?.modules ?? {}).filter(([, m]) => m.installable !== false).map(([name]) => name);
  const manifest = readManifest(root);
  const on = new Set();
  const off = new Map();
  for (const name of known) {
    const m = manifest?.modules?.[name];
    // An `off` without a reason is not a decision: it counts as on.
    if (m?.state === 'off' && String(m.reason ?? '').trim())
      off.set(name, { reason: m.reason, signalsAtDecision: m.signalsAtDecision ?? [], at: m.at, by: m.by });
  }
  // The grade leaves out the modules that no person turned off already.
  const exempt = exemption(map, gradeOf(manifest), new Set(off.keys()));
  for (const name of known) {
    if (off.has(name) || exempt.modules.has(name)) continue;
    // A module that raises the bar for a reason no file shows (the ASVS level) is on only when chosen.
    if (map.modules[name].optIn && manifest?.modules?.[name]?.state !== 'on') continue;
    on.add(name);
  }
  return { on, off, known, map, manifest, grade: exempt.grade, exempt };
};

// criterion ID → the module that owns it; what is not here is core.
export const ownerOf = (map) => {
  const owner = new Map();
  for (const [name, m] of Object.entries(map?.modules ?? {})) for (const id of m.criteria) owner.set(id, name);
  return owner;
};

// The criteria not required in the bar: those of the modules that are off and those the grade leaves out.
export const offCriteria = (root) => {
  const { off, map, exempt } = active(root);
  return new Set([...off.keys()].flatMap((name) => map.modules[name].criteria).concat([...exempt.criteria]));
};

const globRe = (g) => new RegExp(`^${g.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*\*/g, '\u0000').replace(/\*/g, '[^/]*').replaceAll('\u0000', '.*')}$`);

const SKIP = new Set(['worktrees', '.kit-incoming', '.validation', 'node_modules']);
// Every file of a kit, relative to the repo, with `/`.
export const listKit = (root) => {
  const out = [];
  const walk = (dir, rel) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (SKIP.has(e.name) || (rel === '.claude' && ['settings.local.json', 'kit.json', 'kit-files.json'].includes(e.name))) continue;
      const r = `${rel}/${e.name}`;
      if (e.isDirectory()) walk(join(dir, e.name), r); else out.push(r);
    }
  };
  walk(join(root, '.claude'), '.claude');
  return out.sort();
};

export const filesOfModule = (map, name, all) => {
  const globs = map.modules[name].files;
  const include = globs.filter((g) => !g.startsWith('!')).map(globRe);
  const exclude = globs.filter((g) => g.startsWith('!')).map((g) => globRe(g.slice(1)));
  return all.filter((f) => include.some((r) => r.test(f)) && !exclude.some((r) => r.test(f)));
};

// Of the core's stack profiles, only the chosen one stays; the one a module owns comes with the module.
export const forStack = (map, files, stack) => {
  const chosen = map.stacks?.[stack];
  return chosen ? files.filter((f) => !f.startsWith('.claude/stacks/') || chosen.includes(f)) : files;
};

// The modules a file belongs to: none means the core.
export const modulesOfFile = (map, file, all = [file]) =>
  Object.keys(map.modules).filter((name) => filesOfModule(map, name, all).includes(file));

// The core: everything no module owns; of the stack profiles, only the chosen one.
export const coreFiles = (map, all, stack) => {
  const owned = new Set(Object.keys(map.modules).flatMap((name) => filesOfModule(map, name, all)));
  return forStack(map, all.filter((f) => !owned.has(f)), stack);
};

export const sha256 = (path) => createHash('sha256').update(readFileSync(path)).digest('hex');

// Copies `files` from one repo to another. A file already there that differs from the source is a
// local edition: it is kept and listed, never overwritten, unless `overwrite`.
export const copyFiles = (from, to, files, { overwrite = false } = {}) => {
  const copied = [];
  const kept = [];
  for (const f of files) {
    const target = join(to, f);
    if (existsSync(target) && !overwrite) {
      if (sha256(target) !== sha256(join(from, f))) kept.push(f);
      continue;
    }
    mkdirSync(dirname(target), { recursive: true });
    copyFileSync(join(from, f), target);
    copied.push(f);
  }
  return { copied, kept };
};

// A card is open while it has no closing.md. `named`: only the one specs/.current names, for a repo
// adopted from an older method whose finished cards never had a closing.md.
export const openCard = (root, { named = false } = {}) => {
  const card = currentCard(root, { named });
  return card && !existsSync(join(card, 'closing.md')) ? card : null;
};

const BINARY = /\.(png|jpe?g|gif|webp|avif|ico|woff2?|ttf|pdf|zip|gz)$/i;
// The lines the card added to a file, with their numbers; a file new to git counts as all added.
export const addedOf = (root, base, f) => {
  if (BINARY.test(f)) return [];
  const d = git(root, ['diff', '-U0', base, '--', f]).stdout ?? '';
  if (!d) {
    const path = join(root, f);
    return existsSync(path) ? (() => { try { return readFileSync(path, 'utf8').split('\n').map((text, i) => ({ n: i + 1, text })); } catch { return []; } })() : [];
  }
  const out = [];
  let n = 0;
  for (const l of d.split('\n')) {
    const h = l.match(/^@@ -\S+ \+(\d+)/);
    if (h) { n = Number(h[1]); continue; }
    if (l.startsWith('+') && !l.startsWith('+++')) out.push({ n: n++, text: l.slice(1) });
  }
  return out;
};

const merge = (a, b) => {
  for (const [id, list] of Object.entries(b)) a[id] = [...new Set([...(a[id] ?? []), ...list])];
  return a;
};

// The signals a card shows, from card.md (the Tasks and the Gate name what it will touch; the whole text, for a language)
// and optionally from its real diff.
export const cardSignals = (root, cardDir, { diff = false } = {}) => {
  const doc = ['card.md', 'plan.md'].map((f) => join(cardDir, f)).find((p) => existsSync(p));
  const text = doc ? readFileSync(doc, 'utf8') : '';
  const sections = text.split(/^## /m).filter((s) => /^(Tasks|Gate|File map|Changes to existing behavior|Verification)\b/.test(s));
  const files = (fileMapLines(cardDir) ?? []).flatMap(pathTokens);
  const found = detectIn({ files, texts: sections });
  if (text) {
    const asked = detectIn({ asks: [text] }).i18n;
    if (asked) merge(found, { i18n: asked });
  }
  if (diff) {
    const base = cardStart(root, cardDir);
    const files2 = cardFiles(root, base);
    const added = files2.flatMap((f) => addedOf(root, base, f).map((l) => ({ ...l, f })));
    merge(found, detectIn({ files: files2, added }));
  }
  return found;
};

// For each module that is off and can block: the evidence the card shows that the decision did not
// see. Empty when the card brings nothing new.
export const lateSignals = (root, cardDir, options) => {
  const { off, map } = active(root);
  if (!off.size) return {};
  const found = cardSignals(root, cardDir, options);
  const late = {};
  for (const [name, info] of off) {
    const module = map.modules[name];
    if (module.blocksLate === false) continue;
    const seen = new Set(info.signalsAtDecision.map(kindOf));
    const fresh = evidenceOf(found, module.signals).filter((e) => !seen.has(kindOf(e)));
    if (fresh.length) late[name] = fresh;
  }
  return late;
};

// At poc a signal that shows up late does not turn a module on: the card keeps its scope and the
// finding is noted as an OUT proposal. Measured: a poc card for a form turned on api, observability
// and i18n from signals that came in while it was being written.
export const LATE_ADVICE = (mod, grade = 'production') => (grade === 'poc'
  ? `\`node .claude/tools/kit.mjs confirm-off ${mod} --reason "out of scope at poc: <what the card brings>"\`, and the finding is noted as \`<ID>-OUT-NN\` in the card's ambiguities.md; the module is not turned on at poc`
  : `\`node .claude/tools/kit.mjs on ${mod}\` or ` +
    `\`node .claude/tools/kit.mjs confirm-off ${mod} --reason "<why it stays off although the card brings this>"\``);

const today = () => new Date().toISOString().slice(0, 10);

// `<ID>-ASM-NN · <date> · <what>` at the end of the card's ambiguities.md; the number is the next free one.
const appendAssumption = (cardDir, what) => {
  const path = join(cardDir, 'ambiguities.md');
  const text = existsSync(path) ? readFileSync(path, 'utf8') : '';
  const folder = cardDir.split(/[\\/]/).pop();
  const id = folder.match(/^[A-Za-z][A-Za-z0-9]*-\d+[A-Za-z0-9]*/)?.[0] ?? folder;
  const next = Math.max(0, ...[...text.matchAll(/-ASM-(\d+)/g)].map((m) => Number(m[1]))) + 1;
  const line = `${id}-ASM-${String(next).padStart(2, '0')} · ${today()} · ${what}`;
  appendFileSync(path, `${text && !text.endsWith('\n') ? '\n' : ''}${line}\n`);
  return line;
};

const fail = (message) => {
  console.error(message);
  process.exit(2);
};

const sourceOf = (root, manifest) => {
  const path = manifest?.source?.path;
  if (!path || !existsSync(join(path, '.claude', 'modules.json')))
    fail('The source the kit was installed from is not available (kit.json `source`): give a copy of the kit with `node <kit>/.claude/tools/install.mjs --update --from <kit>`, or restore it.');
  return path;
};

const requireManifest = (root) => {
  const state = active(root);
  if (!state.manifest || state.manifest.invalid) fail('This repo has no valid .claude/kit.json: every module is on, as it always was. Adopt the modules with `node <kit>/.claude/tools/install.mjs --adopt`.');
  return state;
};

const flag = (args, name) => {
  const i = args.indexOf(name);
  return i >= 0 ? String(args[i + 1] ?? '').trim() : '';
};

const moduleArg = (state, name) => {
  if (!name || !state.known.includes(name)) fail(`Unknown module “${name ?? ''}”. Modules: ${state.known.join(', ')}.`);
  return name;
};

export const status = (root) => {
  const { on, off, known, map, manifest, grade, exempt } = active(root);
  const found = detect(root);
  const g = recordedGrade(manifest) ? manifest.grade : null;
  const head = g ? `grade · ${grade} (${g.at ?? 'undated'}) · ${g.reason}` : `grade · ${grade} (default)`;
  return [head, ...known.map((name) => {
    const seen = evidenceOf(found, map.modules[name].signals).map((e) => describe(found, e));
    const now = seen.length ? ` · signals now: ${seen.join('; ')}` : '';
    if (on.has(name)) return `${name} · on${now}`;
    const o = off.get(name);
    if (!o) {
      const block = exempt.blocks.find((b) => b.module && b.name === name);
      return block ? `${name} · off by grade: ${grade} — ${block.reason}${now}` : `${name} · not chosen (opt-in)${now}`;
    }
    return `${name} · off by ${o.by ?? 'decision'} (${o.at ?? 'undated'}) · ${o.reason}${now}`;
  })];
};

// What changes between two grades: the criteria, the agents, the mutation and the time the move
// brings in or takes out. `from` and `to` are exemptions of the same map.
export const gradeChange = (from, to) => {
  const raising = rank(to.grade) > rank(from.grade);
  const [had, has] = raising ? [from, to] : [to, from];
  const seen = new Set();
  const lines = [];
  for (const b of had.blocks) {
    const ids = b.criteria.filter((id) => !has.criteria.has(id) && !seen.has(id));
    ids.forEach((id) => seen.add(id));
    if (ids.length) lines.push(`  ${b.name} — ${ids.length} criteria (${ids.join(' ')}): ${b.reason}`);
  }
  const agents = [...had.without].filter((a) => !has.without.has(a));
  if (agents.length) lines.push(`  agents: ${agents.join(', ')}`);
  if (from.level?.mutation !== to.level?.mutation) lines.push(`  mutation: ${from.level?.mutation} → ${to.level?.mutation}`);
  if (from.level?.capTimes !== to.level?.capTimes) lines.push(`  time plan: goal ${from.level?.goalTimes}× / cap ${from.level?.capTimes}× → goal ${to.level?.goalTimes}× / cap ${to.level?.capTimes}×`);
  return { raising, lines };
};

const turnGrade = (root, target, reason) => {
  const manifest = readManifest(root);
  const map = readModules(root);
  if (manifest?.invalid) fail('.claude/kit.json does not parse: fix it with `node <kit>/.claude/tools/install.mjs --adopt` before choosing a grade.');
  if (!map?.grades) fail('This kit has no grades: .claude/modules.json has no `grades`.');
  if (!GRADES.includes(target)) fail(`Unknown grade “${target ?? ''}”. Grades: ${GRADES.join(', ')}.`);
  const recorded = recordedGrade(manifest);
  const current = recorded ?? 'production';
  const unattended = process.env.SDD_UNATTENDED === '1';
  if (unattended && target === 'poc') fail('Unattended nobody chooses poc: the lightest bar is a person\'s decision. The card goes to review (`.claude/AUTONOMY.md`).');
  if (unattended && rank(target) < rank(current)) fail(`Unattended nobody lowers the grade (${current} → ${target}): that decision is a person's.`);
  // The first choice is free; after it the grade only goes up, because a bar once lowered and raised again
  // would hide the debt of the cards written in between.
  if (recorded && rank(target) < rank(recorded)) fail(`Grades only go up: ${recorded} → ${target} would lower the bar. ${GRADES.slice(rank(recorded) + 1).length ? `From ${recorded} the next ones are ${GRADES.slice(rank(recorded) + 1).join(', ')}.` : `${recorded} is the highest.`}`);
  if (!reason) fail('Choosing a grade needs its reason: `kit.mjs grade <poc|mvp|production> --reason "<why>"`. It is written in the manifest and repeated in every closing.');
  if (openCard(root)) fail('There is a card open: the grade changes between cards, so the bar the card was planned with does not change under it. Close the card first.');
  if (recorded === target) { console.log(`The grade is already ${target}.`); return; }
  const change = gradeChange(exemption(map, current), exemption(map, target));
  const previous = manifest?.grade && recorded ? [{ level: recorded, reason: manifest.grade.reason, at: manifest.grade.at }] : [];
  writeManifest(root, {
    ...(manifest ?? {}),
    grade: { level: target, reason, by: unattended ? 'unattended' : 'person', at: today(), history: [...(manifest?.grade?.history ?? []), ...previous] },
  });
  console.log(`The grade is ${target} (it was ${recorded ?? 'production by default'}).`);
  if (change.lines.length) console.log(`${change.raising ? 'Now required, and not before (the debt to close)' : 'No longer required'}:\n${change.lines.join('\n')}`);
};

const turnOn = (root, name) => {
  const state = requireManifest(root);
  moduleArg(state, name);
  const source = sourceOf(root, state.manifest);
  const sourceMap = readModules(source);
  const card = openCard(root);
  // What the card brings that the decision to turn it off did not see, read while it is still off.
  const brought = card && state.off.has(name) ? (lateSignals(root, card, { diff: true })[name] ?? []) : [];
  const files = filesOfModule(sourceMap, name, listKit(source));
  const { copied, kept } = copyFiles(source, root, files);
  const manifest = state.manifest;
  manifest.modules[name] = { state: 'on', version: sourceMap.modules[name].version, since: `kit.mjs on ${today()}` };
  manifest.files ??= {};
  for (const f of [...copied, ...files.filter((x) => !kept.includes(x) && existsSync(join(root, x)))])
    manifest.files[f] = { module: name, sha256: sha256(join(root, f)) };
  writeManifest(root, manifest);
  console.log(`${name} is on: ${copied.length} file(s) copied${kept.length ? `; ${kept.length} already there with local changes, left as they are: ${kept.join(', ')}` : ''}.`);
  if (process.env.SDD_UNATTENDED === '1' && card)
    console.log(appendAssumption(card, `module ${name} activated: signal ${brought[0] ?? 'the card brings it'} · undo: kit.mjs off ${name} --reason …`));
};

const turnOff = (root, name, reason) => {
  const state = requireManifest(root);
  moduleArg(state, name);
  if (process.env.SDD_UNATTENDED === '1') fail('Unattended nobody turns a module off: that decision is a person\'s. `kit.mjs on <module>` is the way to resolve it.');
  if (!reason) fail('Turning a module off needs its reason: `kit.mjs off <module> --reason "<why>"`. It is written in the manifest and repeated in every closing.');
  if (openCard(root)) fail('There is a card open: a module is turned off between cards, so the bar the card was planned with does not change under it. Close the card first.');
  const manifest = state.manifest;
  const removed = [];
  const modified = [];
  for (const [f, rec] of Object.entries(manifest.files ?? {}).filter(([, r]) => r.module === name)) {
    const path = join(root, f);
    if (!existsSync(path)) { delete manifest.files[f]; continue; }
    if (sha256(path) === rec.sha256) { rmSync(path); removed.push(f); delete manifest.files[f]; } else modified.push(f);
  }
  const found = detect(root);
  manifest.modules[name] = {
    state: 'off', reason, by: 'person', at: today(),
    signalsAtDecision: evidenceOf(found, state.map.modules[name].signals),
  };
  writeManifest(root, manifest);
  console.log(`${name} is off: ${removed.length} file(s) removed.${modified.length ? ` Modified, not touched: ${modified.join(', ')}.` : ''}`);
};

const confirmOff = (root, name, reason) => {
  const state = requireManifest(root);
  moduleArg(state, name);
  const unattended = process.env.SDD_UNATTENDED === '1';
  if (unattended && gradeOf(state.manifest) !== 'poc') fail('Unattended nobody confirms a module stays off. `kit.mjs on <module>` resolves it.');
  if (!state.off.has(name)) fail(`${name} is not off: there is nothing to confirm.`);
  if (!reason) fail('`kit.mjs confirm-off <module> --reason "<why it stays off although the card brings the signal>"`: the reason is the point.');
  const card = openCard(root) ?? currentCard(root);
  if (!card) fail('There is no card in progress whose signals could be confirmed.');
  const fresh = lateSignals(root, card, { diff: true })[name] ?? [];
  const manifest = state.manifest;
  const entry = manifest.modules[name];
  entry.signalsAtDecision = [...new Set([...(entry.signalsAtDecision ?? []), ...fresh])];
  (entry.confirmed ??= []).push({ at: today(), card: card.split(/[\\/]/).pop(), reason, signals: fresh });
  writeManifest(root, manifest);
  console.log(`${name} stays off, confirmed for ${card.split(/[\\/]/).pop()}: ${fresh.length ? fresh.join('; ') : 'no new signal'}.`);
  if (unattended) console.log(appendAssumption(card, `module ${name} kept off at poc: signal ${fresh[0] ?? 'the card brings it'} · undo: kit.mjs on ${name}`));
};

const setE2e = (root, given) => {
  const path = String(given ?? '').trim().replaceAll('\\', '/').replace(/\/+$/, '');
  if (!path || path.startsWith('/') || /^[A-Za-z]:/.test(path) || path.split('/').includes('..'))
    fail('`kit.mjs e2e <path>`: the folder of the scenario tests, relative to the repo root (for example `test` or `apps/e2e`).');
  if (!existsSync(join(root, path)) || !statSync(join(root, path)).isDirectory()) fail(`${path} is not a folder of this repo.`);
  const manifest = readManifest(root);
  const method = join(root, '.claude', 'METHOD.md');
  const hasMethodLine = existsSync(method) && /^E2E=\S+/m.test(readFileSync(method, 'utf8'));
  if ((!manifest || manifest.invalid) && !hasMethodLine) fail('There is no kit.json and no `E2E=` line in .claude/METHOD.md to change.');
  if (manifest && !manifest.invalid) writeManifest(root, { ...manifest, e2e: path });
  if (hasMethodLine) writeFileSync(method, readFileSync(method, 'utf8').replace(/^E2E=\S+/m, () => `E2E=${path}`));
  console.log(`The scenario tests folder is ${path}.`);
};

const repair = (root) => {
  const state = requireManifest(root);
  const source = sourceOf(root, state.manifest);
  const sourceMap = readModules(source);
  const all = listKit(source);
  const wanted = [
    ...coreFiles(sourceMap, all, state.manifest.stack),
    ...[...state.on].flatMap((name) => filesOfModule(sourceMap, name, all)),
  ];
  const { copied, kept } = copyFiles(source, root, wanted.filter((f) => !existsSync(join(root, f))));
  state.manifest.files ??= {};
  for (const f of copied) state.manifest.files[f] = { module: modulesOfFile(sourceMap, f, all)[0] ?? 'core', sha256: sha256(join(root, f)) };
  writeManifest(root, state.manifest);
  console.log(copied.length ? `Restored ${copied.length} missing file(s): ${copied.join(', ')}.` : 'Nothing is missing.');
  if (kept.length) console.log(`Left as they are: ${kept.join(', ')}.`);
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [command, name, ...rest] = process.argv.slice(2);
  const root = process.cwd();
  try {
    if (command === 'status') console.log(status(root).join('\n'));
    else if (command === 'on') turnOn(root, name);
    else if (command === 'off') turnOff(root, name, flag(rest, '--reason'));
    else if (command === 'confirm-off') confirmOff(root, name, flag(rest, '--reason'));
    else if (command === 'grade') turnGrade(root, name, flag(rest, '--reason'));
    else if (command === 'repair') repair(root);
    else if (command === 'e2e') setE2e(root, name);
    else fail('kit.mjs status | on <module> | off <module> --reason "…" | confirm-off <module> --reason "…" | grade <poc|mvp|production> --reason "…" | repair | e2e <path>');
  } catch (e) {
    fail(`kit.mjs failed: ${e.message}`);
  }
}
