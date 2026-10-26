#!/usr/bin/env node
// flutter-gate: runs `flutter analyze` and `flutter test` of a Flutter repo and writes one state line per
// check: `<name>: passed`, `<name>: failed: <why>` or `<name>: could not run: <why>`.
//   node .claude/tools/flutter-gate.mjs [--dir <repo>] [--accept] [--help]
// `--accept` adds --update-goldens to `flutter test`: the goldens are rewritten, a person reviews the diff.
// The SDK is looked up on the PATH and then in FLUTTER_ROOT (<root>/bin/flutter).
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { delimiter, join, resolve } from 'node:path';
import { endsWithLine } from './final-line.mjs';

const HELP = `flutter-gate: flutter analyze and flutter test, one state line each.
Usage: node .claude/tools/flutter-gate.mjs [--dir <repo>] [--accept] [--help]
  --dir <repo>  the Flutter repo (default: the current folder)
  --accept      runs flutter test with --update-goldens: it rewrites the goldens
Lines: <name>: passed | <name>: failed: <why> | <name>: could not run: <why>
The SDK comes from the PATH or from FLUTTER_ROOT.`;

const args = process.argv.slice(2);
if (args.includes('--help') || args.includes('-h')) { console.log(HELP); process.exit(0); }
endsWithLine('flutter-gate');

const dirAt = args.indexOf('--dir');
const dir = resolve(dirAt >= 0 ? args[dirAt + 1] ?? '.' : '.');
const accept = args.includes('--accept');

const names = process.platform === 'win32' ? ['flutter.bat', 'flutter.cmd', 'flutter.exe'] : ['flutter'];
const inFolder = (folder) => names.map((n) => join(folder, n)).find((p) => existsSync(p));
const findFlutter = () => {
  for (const folder of (process.env.PATH ?? process.env.Path ?? '').split(delimiter).filter(Boolean)) { const hit = inFolder(folder); if (hit) return hit; }
  const root = process.env.FLUTTER_ROOT;
  return root ? inFolder(join(root, 'bin')) ?? null : null;
};

const lastLines = (r) => `${r.stdout ?? ''}${r.stderr ?? ''}`.trim().split(/\r?\n/).filter(Boolean).slice(-3).join(' | ').slice(0, 300);

const flutter = findFlutter();
if (!flutter) {
  console.log('flutter: could not run: flutter is not on the PATH');
  process.exit(2);
}
if (!existsSync(join(dir, 'pubspec.yaml'))) {
  console.log(`flutter: could not run: there is no pubspec.yaml in ${dir}`);
  process.exit(2);
}

let code = 0;
for (const [name, argv] of [['analyze', ['analyze']], ['test', ['test', ...(accept ? ['--update-goldens'] : [])]]]) {
  const r = spawnSync(flutter, argv, { cwd: dir, encoding: 'utf8', shell: /\.(bat|cmd)$/i.test(flutter), maxBuffer: 64 * 1024 * 1024 });
  if (r.error) { console.log(`${name}: could not run: ${r.error.message}`); code = Math.max(code, 2); continue; }
  if (r.status === 0) { console.log(`${name}: passed`); continue; }
  console.log(`${name}: failed: exit ${r.status}${lastLines(r) ? `: ${lastLines(r)}` : ''}`);
  code = Math.max(code, 1);
}
process.exit(code);
