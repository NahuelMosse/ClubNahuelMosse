#!/usr/bin/env node
// affected.mjs [--tests <regex>] <touched file…> — the tests a change can break, one path per line.
// A test is affected when it imports a touched file, through any chain of relative imports (`from`, `import()`,
// `require`, a folder's index, a `.js` specifier that is a `.ts` file), or when its text names a touched file by its
// path or its file name: a spec that reads `openapi.yaml` is not an importer of it. A touched test is listed.
// What counts as a test file is `IS_TEST` of card.mjs (`*.test.*`, `*.spec.*`, `test_*.py`, `*_test.go`, …); `--tests`
// gives a stack its own pattern. The list is what a bounded run of a group takes as its tests:
//   node --test $(node .claude/tools/affected.mjs src/a.mjs docs/openapi.yaml)
// Exits 0 (an empty list says why on stderr), 2 without files.
import { existsSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, posix } from 'node:path';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { IS_TEST } from './card.mjs';

const MODULE = /\.(?:[cm]?[jt]sx?)$/;
const EXTENSIONS = ['.mjs', '.js', '.cjs', '.ts', '.tsx', '.jsx', '.mts', '.cts'];
const SPECIFIER = /(?:\bfrom\s*|\bimport\s*\(\s*|\brequire\s*\(\s*|\bimport\s+)(["'])(\.{1,2}\/[^"'\n]*|\.{1,2})\1/g;
const MAX_BYTES = 2_000_000;

const norm = (p) => p.replace(/\\/g, '/').replace(/^\.\//, '');
const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export const affected = (root, touched, isTest = IS_TEST) => {
  const listing = spawnSync('git', ['ls-files', '-co', '--exclude-standard', '-z'], { cwd: root, encoding: 'utf8', maxBuffer: 1 << 28 });
  const repo = (listing.status === 0 ? listing.stdout.split('\0') : []).filter((f) => f && !/(^|\/)node_modules\//.test(f));
  const inRepo = new Set(repo);
  const text = (f) => {
    try { return statSync(join(root, f)).size <= MAX_BYTES ? readFileSync(join(root, f), 'utf8') : ''; } catch { return ''; }
  };
  // The file a relative specifier names, as the repo has it: the exact path, with an extension, a `.js` that is a
  // `.ts`, or the index of a folder.
  const resolveSpecifier = (from, spec) => {
    const base = posix.normalize(posix.join(posix.dirname(from), spec));
    const bare = base.replace(/\.[cm]?jsx?$/, '');
    for (const c of [base, ...EXTENSIONS.map((e) => base + e), ...EXTENSIONS.map((e) => bare + e), ...EXTENSIONS.map((e) => `${base}/index${e}`)])
      if (inRepo.has(c) && MODULE.test(c)) return c;
    return null;
  };
  // Who imports whom: importedBy[file] = the files that import it.
  const importedBy = new Map();
  const sources = new Map();
  for (const f of repo.filter((x) => MODULE.test(x) || isTest.test(x))) {
    const body = text(f);
    sources.set(f, body);
    if (!MODULE.test(f)) continue;
    for (const m of body.matchAll(SPECIFIER)) {
      const target = resolveSpecifier(f, m[2]);
      if (target) importedBy.set(target, [...(importedBy.get(target) ?? []), f]);
    }
  }
  const touchedFiles = touched.map(norm);
  const reach = new Set(touchedFiles);
  const queue = [...touchedFiles];
  for (let f = queue.shift(); f !== undefined; f = queue.shift())
    for (const parent of importedBy.get(f) ?? []) if (!reach.has(parent)) { reach.add(parent); queue.push(parent); }
  const names = touchedFiles.map((f) => ({ path: f, name: posix.basename(f) })).filter((n) => n.name);
  const namesIt = (body) => names.some((n) => new RegExp(`(?<![\\w.-])${escapeRegex(n.name)}(?![\\w])`).test(body.replace(/\\/g, '/')) ||
    body.replace(/\\/g, '/').includes(n.path));
  return repo.filter((f) => isTest.test(f) && (reach.has(f) || namesIt(sources.get(f) ?? text(f)))).sort();
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  let isTest = IS_TEST;
  const at = args.indexOf('--tests');
  if (at >= 0) { isTest = new RegExp(args[at + 1] ?? '$^'); args.splice(at, 2); }
  if (!args.length) {
    console.error('affected.mjs: name the files that were touched: node .claude/tools/affected.mjs <file…>');
    process.exit(2);
  }
  const found = affected(process.cwd(), args, isTest);
  if (!found.length) console.error(`affected.mjs: no test imports or names ${args.join(', ')}`);
  for (const f of found) console.log(f);
}
