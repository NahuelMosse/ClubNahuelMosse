#!/usr/bin/env node
// once.mjs <name> -- <command>
// Run from the repo root.
//
// Runs the command, unless it already passed on exactly this same code. “The same code” is the
// content of the repo's files, without documentation or screenshots (`keyOf`, in card.mjs).
// If it passed, it is not repeated: it says when it passed and returns 0. If it failed, or if
// something changed, it runs again. A failure is never remembered as a result: it always runs again.
//
// It exists because the screen suite was run a dozen times per card on the same code —the
// validation, the fix, the close—, and in a real project every round is hours.
// Each record is its own file in `.validation/once/`: several running at once do not overwrite each
// other. Measured: with a single file for all of them, verify.mjs ran them in parallel and the last
// to finish erased what the others had noted. With the command saved, required.mjs checks at close
// what ran on the code being delivered.
// The output of the last real run is kept next to the record (`<record>.log`): verify.mjs shows the
// log of the run that passed, not that of an earlier one that failed. A record may carry `flaky`
// (tests that failed and then passed on re-run) or `coveredBy` (a line that another line includes):
// the run is still a pass, and the note travels with it.
import { spawn } from 'node:child_process';
import { createHash } from 'node:crypto';
import { createWriteStream, existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { launchesPlaywright, takeLock } from './browser-lock.mjs';
import { keyOf } from './card.mjs';

export const DIR = join('.validation', 'once');

// All the records, of any command, for whoever needs to know what ran.
export const records = (root) => {
  const dir = join(root, DIR);
  if (!existsSync(dir)) return [];
  return readdirSync(dir).filter((f) => f.endsWith('.json'))
    .flatMap((f) => { try { return [JSON.parse(readFileSync(join(dir, f), 'utf8'))]; } catch { return []; } });
};

// One record per name and command: the same name with another command does not overwrite what
// already ran.
const stem = (name, command) => createHash('sha256').update(`${name} · ${command}`).digest('hex').slice(0, 16);
export const recordPath = (root, name, command) => join(root, DIR, `${stem(name, command)}.json`);
export const logPath = (root, name, command) => join(root, DIR, `${stem(name, command)}.log`);

export const readRecord = (root, name, command) => {
  try { return JSON.parse(readFileSync(recordPath(root, name, command), 'utf8')); } catch { return null; }
};

export const writeRecord = (root, { name, command, exit, minutes = 0, ...extra }) => {
  mkdirSync(join(root, DIR), { recursive: true });
  const record = { name, command, key: keyOf(root, command), exit, when: new Date().toISOString(), minutes: +minutes.toFixed(1), ...extra };
  writeFileSync(recordPath(root, name, command), JSON.stringify(record, null, 1));
  return record;
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const sep = process.argv.indexOf('--');
  const name = process.argv[2];
  const command = sep > 0 ? process.argv.slice(sep + 1).join(' ') : '';
  if (!name || !command) {
    console.error('usage: node once.mjs <name> -- <command>');
    process.exit(2);
  }

  const root = process.cwd();
  const previous = readRecord(root, name, command);
  if (previous?.key === keyOf(root, command) && previous.exit === 0) {
    const note = previous.flaky?.length ? ` — passed with flaky: ${previous.flaky.map((f) => `${f.test} (${f.failed}/3)`).join(', ')}` : '';
    console.log(`${name}: already passed on this same code (${previous.when}) — not repeated.${note}`);
    process.exit(0);
  }

  // A browser run marks itself while it lasts (browser-lock.mjs): another one would erase its `test-results/`.
  const releaseLock = launchesPlaywright(command, root) ? takeLock(root, command) : () => {};
  const start = Date.now();
  mkdirSync(join(root, DIR), { recursive: true });
  const log = createWriteStream(logPath(root, name, command));
  const p = spawn(command, { shell: true, stdio: ['inherit', 'pipe', 'pipe'] });
  p.stdout.on('data', (d) => { process.stdout.write(d); log.write(d); });
  p.stderr.on('data', (d) => { process.stderr.write(d); log.write(d); });
  const code = await new Promise((done) => { p.on('close', (c) => done(c ?? 1)); p.on('error', () => done(1)); });
  const exit = code;
  releaseLock();
  const minutes = (Date.now() - start) / 60000;
  const record = writeRecord(root, { name, command, exit, minutes });
  const summary = `${name}: exit ${exit} in ${record.minutes} min\n`;
  process.stdout.write(summary);
  log.end(summary);
  await new Promise((done) => log.on('close', done));
  process.exit(exit);
}
