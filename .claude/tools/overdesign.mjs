// Overdesign signals the gate can read without judgment (`rules/architecture.md`, «Simplest structure that works»):
//  - a method that only forwards to another of the same name with the same arguments,
//  - an interface or abstract class with exactly one implementation in the repo (a test fake counts as a second),
//  - a layer folder (or a folder inside a module) whose only file is a wrapper (re-exports or forwards) of fewer than 20 lines,
//  - a layer folder of a module that holds no file.
// What the card added fails; what was already in the repo is only reported. `kit-overdesign: <reason>` anywhere in a file declares it.
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { IS_CODE, IS_TEST, NOT_PRODUCTION, cardFiles, cardStart, existedAt, git, originOf } from './card.mjs';
import { IS_MIGRATION } from './migrations.mjs';

export const TINY_LINES = 20;
const LAYER_DIRS = /^(?:domain|application|infrastructure|interfaces?|services|use-?cases|repositories|ports|adapters|entities|dtos|mappers|factories|handlers|core)$/;
const EMPTY_LAYERS = /^(?:domain|application|infrastructure|interfaces?)$/;
const posix = (f) => f.split('\\').join('/').replace(/^\.\//, '');
const blank = (code) => code.replace(/\/\*[\s\S]*?\*\/|(^|[^:'"`])\/\/[^\n]*|^[ \t]*#[^\n]*/gm, (m, lead) => (lead ?? '') + m.slice((lead ?? '').length).replace(/[^\n]/g, ' '));
const declared = (text) => /kit-overdesign:\s*\S/.test(text);

// A parameter or argument down to its name: `@Param('id') id: string`, `long id`, `id=id`, `readonly x?: T = 1`.
const nameOf = (p) => {
  let s = p.replace(/@\w+(?:\([^)]*\))?\s*/g, '').replace(/^\s*\w+\s*=\s*(?=\w+\s*$)/, '').replace(/=.*$/, '').trim();
  if (s.includes(':')) s = s.split(':')[0];
  return s.replace(/\?$/, '').trim().split(/\s+/).pop() ?? '';
};
const namesOf = (list) => list.split(',').map(nameOf).filter((n) => n && n !== 'self' && n !== 'cls');
const argsOf = (list) => list.split(',').map((a) => a.trim().replace(/^\w+\s*=\s*(?!=)/, '')).filter(Boolean);
const PARAMS = '((?:[^()]|\\([^()]*\\))*)';
const CALL = '([\\w$]+(?:\\.[\\w$]+)*)';
const PASS_THROUGH = [
  // function or method: `[modifiers] [type] name(params) [: type] { return [await] a.b.name(args); }`
  new RegExp(`(?:^|\\n)([ \\t]*)(?:(?:export|default|public|private|protected|static|async|readonly|function|override)\\s+)*(?:[\\w<>\\[\\],.?]+\\s+)?([\\w$]+)\\s*\\(${PARAMS}\\)\\s*(?::\\s*[^{=;]+?)?\\s*\\{\\s*return\\s+(?:await\\s+)?${CALL}\\(${PARAMS}\\)\\s*;?\\s*\\}`, 'g'),
  // arrow: `const name = [async] (params) => [{ return] [await] a.name(args)`
  new RegExp(`(?:^|\\n)([ \\t]*)(?:export\\s+)?(?:const|let)\\s+([\\w$]+)\\s*=\\s*(?:async\\s*)?\\(${PARAMS}\\)\\s*(?::\\s*[^=]+?)?=>\\s*(?:\\{\\s*return\\s+)?(?:await\\s+)?${CALL}\\(${PARAMS}\\)[ \\t]*;?[ \\t]*\\}?[ \\t]*(?=\\r?\\n|$)`, 'g'),
  // C# and Java expression body: `Type Name(params) => a.Name(args);`
  new RegExp(`(?:^|\\n)([ \\t]*)(?:(?:public|private|protected|internal|static|async|override)\\s+)*(?:[\\w<>\\[\\],.?]+\\s+)?([\\w$]+)\\s*\\(${PARAMS}\\)\\s*=>\\s*(?:await\\s+)?${CALL}\\(${PARAMS}\\)\\s*;`, 'g'),
];
const PY_PASS_THROUGH = new RegExp(`^([ \\t]*)(?:async\\s+)?def\\s+(\\w+)\\s*\\(${PARAMS}\\)\\s*(?:->\\s*[^:]+)?:[ \\t]*\\n?[ \\t]*return\\s+(?:await\\s+)?${CALL}\\(${PARAMS}\\)[ \\t]*$`, 'gm');
const NOT_METHODS = new Set(['if', 'for', 'while', 'switch', 'catch', 'constructor', 'function', 'return']);

// Methods and functions of a file whose whole body forwards to a call of the same name with the same arguments: [{ line, name }].
export const passThroughs = (file, text) => {
  if (declared(text)) return [];
  const code = blank(text);
  const out = [];
  const isPy = /\.py$/.test(file);
  for (const re of isPy ? [PY_PASS_THROUGH] : PASS_THROUGH) {
    re.lastIndex = 0;
    for (const m of code.matchAll(re)) {
      const [, , name, params, callee, args] = m;
      if (NOT_METHODS.has(name) || callee.split('.').length < 2 || callee.split('.').at(-1) !== name) continue;
      const head = code.slice(0, m.index + (m[0].startsWith('\n') ? 1 : 0));
      const above = head.split('\n').slice(-2, -1)[0]?.trim() ?? '';
      if (above.startsWith('@')) continue; // a routed or decorated method adapts, it does not only forward
      const p = namesOf(params);
      const a = argsOf(args);
      if (p.length !== a.length || p.some((x, i) => x !== a[i])) continue;
      out.push({ line: head.split('\n').length, name });
    }
  }
  return out;
};

const DECLARES = [
  /^[ \t]*(?:export\s+)?(?:default\s+)?(?:public\s+)?interface\s+(\w+)/gm,
  /^[ \t]*(?:export\s+)?(?:default\s+)?(?:public\s+)?abstract\s+class\s+(\w+)/gm,
  /^class\s+(\w+)\((?:[\w.]+,\s*)*(?:ABC|abc\.ABC|Protocol)\b/gm,
];
const bareName = (s) => s.trim().replace(/<.*$/, '').split('.').pop().trim();
const implementorsIn = (text) => {
  const code = blank(text);
  const names = [];
  for (const m of code.matchAll(/\bclass\s+\w+(?:<[^>{]*>)?(?:\s+extends\s+[\w.<>, ]+?)?\s+implements\s+([^{]+)\{/g)) names.push(...m[1].split(',').map(bareName));
  for (const m of code.matchAll(/\bclass\s+\w+(?:<[^>{]*>)?\s+extends\s+([\w.]+)/g)) names.push(bareName(m[1]));
  for (const m of code.matchAll(/\bclass\s+\w+(?:<[^>{]*>)?\s*:\s*([^{;]+?)\s*\{/g)) names.push(...m[1].split(',').map(bareName));
  for (const m of code.matchAll(/^[ \t]*class\s+\w+\(([^)]*)\)\s*:/gm)) names.push(...m[1].split(',').map(bareName));
  return names;
};
const fakesOf = (text, name) => (blank(text).match(new RegExp(`:\\s*${name}\\s*=\\s*\\{|\\bsatisfies\\s+${name}\\b|\\bas\\s+${name}\\b|<${name}>\\s*\\{`, 'g')) ?? []).length;

// Interfaces and abstract classes declared in `files` with exactly one implementing class in `all` and no fake: [{ file, name, by }].
// `all` is [{ file, text }] of every code file of the repo, tests included.
export const singleImplementations = (files, all) => {
  const implementors = new Map();
  for (const { file, text } of all) for (const n of implementorsIn(text)) implementors.set(n, [...(implementors.get(n) ?? []), file]);
  const declarations = new Map();
  const where = new Map(all.map((x) => [x.file, x.text]));
  for (const { file, text } of all) {
    if (IS_TEST.test(file) || NOT_PRODUCTION.test(file) || declared(text)) continue;
    const code = blank(text);
    for (const re of DECLARES) { re.lastIndex = 0; for (const m of code.matchAll(re)) declarations.set(m[1], [...(declarations.get(m[1]) ?? []), file]); }
  }
  return files.flatMap((file) => {
    const text = where.get(file) ?? '';
    const code = blank(text);
    const names = new Set();
    for (const re of DECLARES) { re.lastIndex = 0; for (const m of code.matchAll(re)) names.add(m[1]); }
    return [...names].flatMap((name) => {
      if (declarations.get(name)?.length !== 1 || declared(text)) return [];
      const by = implementors.get(name) ?? [];
      if (by.length !== 1) return [];
      if (all.some((x) => x.file !== file && fakesOf(x.text, name) > 0)) return [];
      return [{ file, name, by: by[0] }];
    });
  });
};

const significant = (text) => text.split('\n').filter((l) => l.trim()).length;
const isProduction = (f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f) && !IS_TEST.test(f) && !IS_MIGRATION.test(f);

// A file that only re-exports, or whose methods only forward: it adds nothing the parent folder would not hold.
const isWrapper = (file, text) => {
  const lines = blank(text).split('\n').map((l) => l.trim()).filter(Boolean);
  return lines.every((l) => /^(?:import\b|export\b.*\bfrom\b)/.test(l)) || passThroughs(file, text).length > 0;
};

// Layer folders (or any folder inside a module) whose only file is a wrapper of fewer than TINY_LINES lines: [{ dir, file }].
// A small file alone in the folder of a new module is not flagged: only a wrapper is.
export const tinyFolders = (repo, readText) => {
  const byDir = new Map();
  for (const f of repo) { const dir = f.slice(0, f.lastIndexOf('/')); if (dir) byDir.set(dir, [...(byDir.get(dir) ?? []), f]); }
  const out = [];
  for (const [dir, list] of byDir) {
    const name = dir.split('/').at(-1);
    const inModule = /(?:^|\/)modules\/[^/]+\//.test(`${dir}/`);
    if (!(LAYER_DIRS.test(name) || (inModule && !/(?:^|\/)modules\/[^/]+$/.test(dir)))) continue;
    if (list.length !== 1 || repo.some((f) => f !== list[0] && f.startsWith(`${dir}/`))) continue;
    const [file] = list;
    if (!isProduction(file)) continue;
    const text = readText(file);
    if (text !== null && !declared(text) && significant(text) < TINY_LINES && isWrapper(file, text)) out.push({ dir, file });
  }
  return out;
};

// Layer folders of a module (`modules/<m>/domain`…) on disk with no file in them: [dir].
export const emptyLayerDirs = (root) => {
  const out = [];
  const walk = (rel, depth) => {
    let entries;
    try { entries = readdirSync(join(root, rel), { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (!e.isDirectory() || /^(?:node_modules|\.git|\.claude|specs|\.validation|dist|build|coverage)$/.test(e.name)) continue;
      const path = rel ? `${rel}/${e.name}` : e.name;
      if (EMPTY_LAYERS.test(e.name) && /(?:^|\/)modules\/[^/]+\/[^/]+$/.test(path) && !hasFile(path)) out.push(path);
      if (depth < 7) walk(path, depth + 1);
    }
  };
  const hasFile = (rel) => {
    let entries;
    try { entries = readdirSync(join(root, rel), { withFileTypes: true }); } catch { return false; }
    return entries.some((e) => (e.isDirectory() ? hasFile(`${rel}/${e.name}`) : !/^\.(?:gitkeep|keep)$/.test(e.name)));
  };
  walk('', 0);
  return out;
};

const read = (root, f) => { try { return readFileSync(join(root, f), 'utf8'); } catch { return null; } };

// `{ blocking, notes }`: what the card added, and what was already there.
export const overdesignFindings = (root, cardDir) => {
  const base = cardStart(root, cardDir);
  const mine = cardFiles(root, base).map(posix);
  // A file the card only moved is not created: what it carried was already in the repo.
  const created = new Set(mine.filter((f) => existsSync(join(root, f)) && !existedAt(root, base, f) && !originOf(root, base, f)));
  const repo = (git(root, ['ls-files', '-co', '--exclude-standard']).stdout ?? '').split(/\r?\n/).map(posix).filter(Boolean);
  const code = repo.filter((f) => IS_CODE.test(f) && !/^(?:specs|\.claude)\//.test(f));
  const texts = code.map((file) => ({ file, text: read(root, file) ?? '' }));
  const blocking = [];
  const notes = [];
  const put = (file, message, touched = created.has(file)) => (touched ? blocking : notes).push(`${file}: ${message}`);
  const production = texts.filter((x) => isProduction(x.file));

  for (const { file, text } of production) {
    for (const p of passThroughs(file, text)) put(file, `line ${p.line}: \`${p.name}\` only forwards to another \`${p.name}\` with the same arguments · call the callee from where \`${p.name}\` is called and delete it`, created.has(file));
  }
  for (const s of singleImplementations(production.map((x) => x.file), texts)) put(s.file, `\`${s.name}\` has one implementation (${s.by}) and no test fake · export the concrete one; the interface is born with the second implementation or the fake`);
  for (const t of tinyFolders(repo, (f) => read(root, f))) put(t.file, `the only file of \`${t.dir}/\`, a wrapper under ${TINY_LINES} lines · keep it in the parent folder; a folder is born with its second file`);
  for (const dir of emptyLayerDirs(root)) put(dir, 'a layer folder of a module with no file in it · delete it; a layer appears when the module has something for it', mine.some((f) => f.startsWith(`${dir.split('/').slice(0, -1).join('/')}/`)));
  return { blocking, notes };
};
