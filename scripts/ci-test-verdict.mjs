#!/usr/bin/env node
// The CI verdict of a pytest or flutter test run: green when the suite passed, or when every failing test is one that a
// card's Log declares replaced (`replaces: <file> "<test>" · <why> · by: <file> "<test>"`) and its replacement passes.
// The frozen tests stay in their files after a card replaces them; the rule is the gate's own (`replacedFailures`).
// A flutter test file that does not compile fails as a whole (`loading <file> [E]`): it counts as replaced when a card's
// Log declares tests of that file replaced and the replacement file exists.
// Usage: node scripts/ci-test-verdict.mjs <pytest|flutter> <output file> <exit code>   (from the repo root)
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join, relative, resolve } from 'node:path';
import { replacedFailures, replacementsOf } from '../.claude/tools/verify.mjs';

const [runner, file, code] = process.argv.slice(2);
if (!['pytest', 'flutter'].includes(runner) || !file || code === undefined) {
  console.error('usage: node scripts/ci-test-verdict.mjs <pytest|flutter> <output file> <exit code>');
  process.exit(2);
}
const root = process.cwd();
const fail = (message) => {
  console.error(message);
  process.exit(1);
};
const output = readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
if (Number(code) === 0) {
  console.log(`${runner} passed`);
  process.exit(0);
}
// Exit 1 is "some tests failed"; anything else (collection error, interrupted, usage error) fails the job.
if (Number(code) !== 1) fail(`${runner} exited ${code}`);

let rest = output;
const unloaded = [];
if (runner === 'pytest') {
  // The last line that counts results: `19 failed, 806 passed in 1315.92s` with -q, framed in `=` without it.
  const summary = [...output.matchAll(/^=*\s*\d+ (?:failed|passed|errors?)\b.* in [\d.]+s\b.*$/gm)].at(-1)?.[0].trim() ?? '';
  if (!summary || /\berrors?\b/.test(summary)) fail(`pytest exited ${code}: ${summary || 'no summary line'}`);
} else {
  const specs = join(root, 'specs');
  const declared = existsSync(specs)
    ? readdirSync(specs, { withFileTypes: true }).filter((e) => e.isDirectory())
      .flatMap((e) => { try { return replacementsOf(readFileSync(join(specs, e.name, 'card.md'), 'utf8')); } catch { return []; } })
    : [];
  const posix = (p) => p.split('\\').join('/');
  for (const m of output.matchAll(/^\s*\d+:\d+ \+\d+(?: ~\d+)?(?: -\d+)?: loading (.+?\.dart) \[E\]\s*$/gm)) {
    const seen = posix(relative(root, resolve(root, m[1])));
    const replaced = declared.find((d) => (seen === posix(d.file) || seen.endsWith(`/${posix(d.file)}`))
      && [d.by, join('apps', 'mobile', d.by)].some((by) => existsSync(join(root, by))));
    if (!replaced) fail(`flutter test could not load ${seen} and no card declares its tests replaced`);
    unloaded.push({ file: seen, by: replaced.by });
  }
  rest = output.split('\n').filter((l) => !/: loading .+?\.dart \[E\]\s*$/.test(l)).join('\n');
  if (!/^\s*\d+:\d+ \+\d+(?: ~\d+)?(?: -\d+)?: .+? \[E\]\s*$/m.test(rest) && !unloaded.length) fail(`flutter test exited ${code} with no failing test`);
}

const anyFailing = runner === 'pytest' || /^\s*\d+:\d+ \+\d+(?: ~\d+)?(?: -\d+)?: .+?\.dart: .+? \[E\]\s*$/m.test(rest);
const replaced = anyFailing ? replacedFailures(root, rest) : [];
if (!replaced) fail(`${runner} failed with tests no card declares replaced`);
console.log(`${runner} passed with ${replaced.length} replaced tests failing, each replacement passing:`);
for (const r of replaced) console.log(`- ${r.file} "${r.name}" → ${r.by} "${r.byName}"`);
if (unloaded.length) console.log(`${unloaded.length} files that no longer compile, replaced:`);
for (const u of unloaded) console.log(`- ${u.file} → ${u.by}`);
