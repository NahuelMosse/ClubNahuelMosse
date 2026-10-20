#!/usr/bin/env node
// lane.mjs — run from the repo root, with a card in progress whose plan says `lane: fast`.
//
// Lists what the card's diff does that the fast lane does not allow: a file that is not presentation,
// an added line with behavior, more than 30 changed lines or 3 production files, text that carries
// business weight, an open ambiguity, colors, durations or spaces written by hand, a token whose
// value changes, an asset that changes role, proportion or license, and a test changed beyond the
// literal that the card moved in the presentation files. The classification is made over the diff,
// never by what the agent declares; the hooks call the same functions before a write.
// Exits 0 if nothing falls outside, 1 with one line per violation, 2 if there is no card or the plan
// is not `lane: fast`. A card can leave the lane at any moment, and never enter it again.
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { isAbsolute, join } from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  DECLARES_TOKEN, IS_INFRA, IS_SCHEMA, IS_TEST, IS_VERIFICATION_CONFIG, RAW_COLOR, RAW_DURATION, RAW_LAYOUT,
  cardFiles, cardStart, currentCard, fileMapLines, git, namedIn, relativeTo,
} from './card.mjs';

export const MAX_LINES = 30;
export const MAX_FILES = 3;

export const laneOf = (plan) => (/^\s*(?:[-*]\s*)?lane:\s*fast\b/im.test(plan) ? 'fast' : 'normal');

const MANIFEST = /(^|\/)(package\.json|package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|pyproject\.toml|poetry\.lock|requirements[^/]*\.txt|Pipfile(\.lock)?|go\.(mod|sum)|Cargo\.(toml|lock)|Gemfile(\.lock)?|composer\.(json|lock)|pom\.xml|build\.gradle[^/]*|[^/]+\.csproj|packages\.lock\.json)$/;
const IMAGE = /\.(svg|png|jpe?g|gif|webp|avif|ico)$/i;
const STYLE = /\.(css|scss)$/i;
const MARKUP = /\.(html?)$/i;
const COMPONENT = /\.(tsx|jsx|vue|svelte)$/;
const I18N = /(^|\/)(locales?|i18n|messages)\/.*\.(json|ya?ml|po)$/i;
const SENSITIVE_PATH = /(^|[/._-])(auth|permissions?|api|domain|application|server)([/._-]|$)/i;
const BUSINESS_PATH = /legal|terms|privacy|mail|invoice|pdf|notification/i;
const GLOBAL_STYLE = /(^|\/)(global|globals|reset|base|tokens?|theme|variables)[^/]*\.s?css$|(^|\/)design\//i;
const IN_TESTS_FOLDER = /(^|\/)(e2e|tests?|__tests__)\//;
const KIT_OR_SPECS = /^(specs|\.claude|\.specify)\/|\.md$/;

// Behavior added to a line: what makes a presentation change stop being one.
const BEHAVIOR = [
  [/\bon[A-Z]\w*\s*=/, 'an event attribute'],
  [/addEventListener/, 'addEventListener'],
  [/@click|\bv-on\b|\bv-if\b|\bv-for\b|\bv-model\b/, 'a Vue binding or condition'],
  [/\{#(if|each|await)\b/, 'a Svelte block'],
  [/\buse(State|Effect|Reducer|Memo|Callback|Ref|Context)\b/, 'a hook'],
  [/\b(if|switch|for|while)\s*\(/, 'a condition or a loop'],
  [/\{[^{}]*\?[^{}:]*:[^{}]*\}/, 'a ternary'],
  [/&&\s*</, 'a conditional render'],
  [/\bfetch\s*\(/, 'a data call'],
  [/\bhref\s*=/, 'an href'],
  [/\bdata-testid\s*=|\bid\s*=|\bname\s*=/, 'an attribute that code or tests use as a key (data-testid, id, name)'],
];
const MONEY = /[$€£¥]\s?\d|\d\s?[$€£¥]|\b\d[\d.,]*\s?(USD|ARS|EUR|MXN|GBP|BRL)\b|\b(USD|ARS|EUR|MXN|GBP|BRL)\s?\d|\d\s?%/;
const ACCESSIBLE_NAME = /\baria-(label|labelledby|describedby)\s*=|\btitle\s*=|\bplaceholder\s*=|\bvalue\s*=/;
const IMPORT = /^\s*import\s+(?:[^'"]*?\sfrom\s+)?['"]([^'"]+)['"]|\brequire\(\s*['"]([^'"]+)['"]\s*\)/;

// Lines added and removed between two texts, as multisets: order does not matter to what the lane asks.
const lineDiff = (before, after) => {
  const count = (text) => {
    const m = new Map();
    for (const l of text.split('\n')) m.set(l, (m.get(l) ?? 0) + 1);
    return m;
  };
  const a = count(before);
  const b = count(after);
  const take = (from, other) => [...from].flatMap(([l, n]) => Array(Math.max(0, n - (other.get(l) ?? 0))).fill(l)).filter((l) => l.trim());
  return { added: take(b, a), removed: take(a, b) };
};

// What a source has outside its string literals, and the literals in order: two versions of a test that
// differ only in literals have the same skeleton.
export const strings = (src) => {
  const lits = [];
  let skeleton = '';
  let i = 0;
  while (i < src.length) {
    const c = src[i];
    if (c === '/' && (src[i + 1] === '/' || src[i + 1] === '*')) {
      const line = src[i + 1] === '/';
      const end = line ? src.indexOf('\n', i) : src.indexOf('*/', i + 2);
      const j = end < 0 ? src.length : line ? end : end + 2;
      skeleton += src.slice(i, j);
      i = j;
    } else if (c === '"' || c === "'" || c === '`') {
      let j = i + 1;
      while (j < src.length && src[j] !== c) j += src[j] === '\\' ? 2 : 1;
      lits.push(src.slice(i + 1, j));
      skeleton += `${c}\0${c}`;
      i = j + 1;
    } else {
      skeleton += c;
      i++;
    }
  }
  return { skeleton, lits };
};

// What an Edit leaves in the file, as the guards compute it.
export const applyEdit = (current, input = {}) => {
  if (typeof input.content === 'string') return input.content;
  const { old_string: from = '', new_string: to = '' } = input;
  return input.replace_all ? current.replaceAll(from, to) : current.replace(from, to);
};

const baseText = (root, base, rel) => {
  const r = git(root, ['show', `${base}:${rel}`]);
  return r.status === 0 ? r.stdout : null;
};

const pngSize = (buf) => (buf.length > 24 && buf.toString('ascii', 12, 16) === 'IHDR' ? [buf.readUInt32BE(16), buf.readUInt32BE(20)] : null);
const svgRatio = (text) => {
  const box = text.match(/viewBox\s*=\s*["']\s*[-\d.]+[\s,]+[-\d.]+[\s,]+([\d.]+)[\s,]+([\d.]+)/);
  return box ? [Number(box[1]), Number(box[2])] : null;
};

// The change the card makes to each file: what it was at the start, what it is now (or will be, for
// the write that is about to happen).
const changes = (root, cardDir, pending) => {
  const base = cardStart(root, cardDir);
  const files = cardFiles(root, base).filter((f) => !KIT_OR_SPECS.test(f));
  const pendingRel = pending?.file ? (isAbsolute(pending.file) ? relativeTo(root, pending.file) : pending.file.replaceAll('\\', '/')) : null;
  if (pendingRel && !KIT_OR_SPECS.test(pendingRel) && !files.includes(pendingRel)) files.push(pendingRel);
  return files.map((file) => {
    const test = IS_TEST.test(file) || IN_TESTS_FOLDER.test(file);
    const before = baseText(root, base, file);
    const image = IMAGE.test(file) && !/\.svg$/i.test(file);
    const path = join(root, file);
    const now = file === pendingRel ? pending.content : image ? '' : existsSync(path) ? readFileSync(path, 'utf8') : '';
    const { added, removed } = image ? { added: [], removed: [] } : lineDiff(before ?? '', now);
    return { file, test, image, isNew: before === null, before: before ?? '', now, added, removed, base };
  });
};

const planText = (cardDir) => (existsSync(join(cardDir, 'plan.md')) ? readFileSync(join(cardDir, 'plan.md'), 'utf8') : '');

const productionViolations = (root, cardDir, production) => {
  const out = [];
  const map = fileMapLines(cardDir) ?? [];
  const changed = production.reduce((n, c) => n + c.added.length + c.removed.length, 0);
  if (changed > MAX_LINES) out.push(`${changed} changed lines: the fast lane allows ${MAX_LINES}`);
  if (production.length > MAX_FILES) out.push(`${production.length} production files: the fast lane allows ${MAX_FILES}`);

  const locales = production.filter((c) => I18N.test(c.file));
  for (const c of production) {
    const f = c.file;
    const why = (reason) => out.push(`${f}: ${reason}`);
    const presentationByType = STYLE.test(f) || MARKUP.test(f) || IMAGE.test(f) || I18N.test(f) ||
      (COMPONENT.test(f) && namedIn(map, f, root).some((l) => /\bpresentation\b/i.test(l)));
    if (IS_SCHEMA.test(f) || IS_INFRA.test(f)) why('schema or infrastructure');
    else if (MANIFEST.test(f)) why('manifest or lockfile: dependencies are not a fast lane change');
    else if (IS_VERIFICATION_CONFIG.test(f)) why('configuration of what gets verified');
    else if (SENSITIVE_PATH.test(f)) why('auth, permissions, API, domain, application or server');
    else if (!presentationByType) why(COMPONENT.test(f) ? 'a component whose File map line does not say `presentation`' : 'not a presentation file');
    if (BUSINESS_PATH.test(f)) why('a legal, terms, privacy, email, invoice, PDF or notification text carries business weight');

    if (!IMAGE.test(f)) {
      if (!STYLE.test(f)) {
        for (const line of c.added) {
          const hit = BEHAVIOR.find(([re]) => re.test(line));
          if (hit) { why(`adds ${hit[1]}: \`${line.trim().slice(0, 60)}\``); break; }
        }
        const imports = c.added.map((l) => l.match(IMPORT)).filter(Boolean).map((m) => m[1] ?? m[2]);
        for (const spec of imports) if (!c.before.includes(spec) && !/\.(svg|png)$/i.test(spec)) why(`imports a module the file did not import before: ${spec}`);
        if (c.added.some((l) => MONEY.test(l))) why('a price, an amount or a percentage carries business weight');
        if (c.added.some((l) => /error/i.test(l) && /(["'`])[^"'`]{2,}\1/.test(l))) why('a message on a line about an error: it explains a rule');
        if (c.added.some((l) => ACCESSIBLE_NAME.test(l))) why('an accessible name, title or placeholder: it has to match the visible label (WCAG 2.5.3)');
        if (c.added.some((l) => /<img\b(?![^>]*\balt\s*=)[^>]*>/.test(l))) why('an image without its `alt`');
      }
      const lines = c.added.filter((l) => !DECLARES_TOKEN.test(l)).join('\n');
      const raw = (lines.match(RAW_COLOR)?.length ?? 0) + (lines.match(RAW_DURATION)?.length ?? 0) + (lines.match(RAW_LAYOUT)?.length ?? 0);
      if ((STYLE.test(f) || MARKUP.test(f) || COMPONENT.test(f)) && raw) why(`${raw} color, duration or space value(s) written by hand: use the design line's tokens`);
      if (STYLE.test(f)) {
        if (c.added.some((l) => DECLARES_TOKEN.test(l))) why('declares or changes the value of a token: that spreads to every screen');
        if (GLOBAL_STYLE.test(f) || c.added.some((l) => /^\s*(:root|html|body|\*)\b/.test(l))) why('a global stylesheet or a global selector: that spreads to every screen');
      }
    }
    if (IMAGE.test(f) && !c.isNew) {
      const path = join(root, f);
      const licensed = namedIn(map, f, root).some((l) => /licen[cs]e|licencia/i.test(l));
      if (!licensed) why('an asset replaced without its license on its File map line');
      const was = /\.svg$/i.test(f) ? svgRatio(c.before) : null;
      const is = /\.svg$/i.test(f) ? svgRatio(c.now) : null;
      let ratios = was && is ? [was, is] : null;
      if (/\.png$/i.test(f) && existsSync(path)) {
        const a = pngSize(spawnSync('git', ['show', `${c.base}:${f}`], { cwd: root, maxBuffer: 1 << 28 }).stdout ?? Buffer.alloc(0));
        const b = pngSize(readFileSync(path));
        if (a && b) ratios = [a, b];
      }
      if (ratios && Math.abs(ratios[0][0] / ratios[0][1] - ratios[1][0] / ratios[1][1]) > 0.01) why('an asset replaced with another proportion: that is a layout change');
    }
  }
  if (locales.length) {
    const folders = new Set(locales.map((c) => c.file.replace(/[^/]+$/, '')));
    for (const dir of folders) {
      const siblings = git(root, ['ls-files', '--', dir]).stdout.split('\n').filter((f) => I18N.test(f) && !locales.some((c) => c.file === f));
      if (siblings.length) out.push(`${dir}: a translated text changes in every locale or it is not a fast lane change; not changed: ${siblings.slice(0, 3).join(', ')}`);
    }
  }
  return out;
};

// A test changed only in string literals, each one a text that the card took out of the presentation
// files and replaced with one it put in; the locator by accessible name is a literal like any other.
const testViolations = (root, tests, production) => {
  const removed = production.flatMap((c) => c.removed).join('\n');
  const added = production.flatMap((c) => c.added).join('\n');
  const out = [];
  for (const t of tests) {
    if (t.isNew) { out.push(`${t.file}: a new test: the fast lane brings visual evidence, not tests`); continue; }
    const a = strings(t.before);
    const b = strings(t.now);
    if (a.skeleton !== b.skeleton) { out.push(`${t.file}: changed beyond a string literal`); continue; }
    a.lits.forEach((old, i) => {
      const next = b.lits[i];
      if (old === next) return;
      if (!old.trim() || !removed.includes(old) || !added.includes(next))
        out.push(`${t.file}: the literal "${old}" → "${next}" is not a text the card took out of the presentation files and replaced with one it put in`);
    });
  }
  return out;
};

// Every violation of the diff of the card, plus the write that is about to happen when `pending`
// ({ file, content }) is given.
export const violations = (root, cardDir, pending) => {
  const all = changes(root, cardDir, pending);
  const production = all.filter((c) => !c.test);
  const out = [...productionViolations(root, cardDir, production), ...testViolations(root, all.filter((c) => c.test), production)];
  const amb = join(cardDir, 'ambiguities.md');
  if (existsSync(amb) && /-AMB-(?!00\b)\d+/.test(readFileSync(amb, 'utf8'))) out.push('ambiguities.md has an AMB-NN: a doubt takes the card out of the fast lane');
  return [...new Set(out)];
};

// What a write to a test file would leave outside the allowed literal replacement.
export const testWriteViolations = (root, cardDir, pending) => {
  const all = changes(root, cardDir, pending);
  const production = all.filter((c) => !c.test);
  return testViolations(root, all.filter((c) => c.test && c.file === (isAbsolute(pending.file) ? relativeTo(root, pending.file) : pending.file.replaceAll('\\', '/'))), production);
};

// The literals each existing test of the diff replaced: required.mjs asks for each one's event.
export const literalChanges = (root, cardDir) => changes(root, cardDir).filter((c) => c.test && !c.isNew).flatMap((t) => {
  const a = strings(t.before);
  const b = strings(t.now);
  return a.skeleton === b.skeleton ? a.lits.flatMap((old, i) => (old === b.lits[i] ? [] : [{ file: t.file, old, next: b.lits[i] }])) : [];
});

export const OUT_OF_LANE = (list) =>
  `This change is outside the fast lane: ${list.join('; ')}. Switch to the normal lane: remove \`lane: fast\` from plan.md and write the full plan (steps/05-plan.md); the code goes through the implementer. \`node .claude/tools/lane.mjs\` lists what falls outside.`;

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const root = process.cwd();
  const cardDir = existsSync(join(root, 'specs')) ? currentCard(root) : null;
  if (!cardDir) { console.error('No card in progress.'); process.exit(2); }
  if (laneOf(planText(cardDir)) !== 'fast') { console.error('The plan of the card does not say `lane: fast`: the normal lane applies.'); process.exit(2); }
  const found = violations(root, cardDir);
  if (!found.length) { console.log('Every change of the card is inside the fast lane.'); process.exit(0); }
  console.log(`${found.length} outside the fast lane:`);
  for (const v of found) console.log(`- ${v}`);
  process.exit(1);
}
