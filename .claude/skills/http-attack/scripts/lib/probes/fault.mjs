import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { wire } from '../body.mjs';
import { leaksInternals } from '../run.mjs';

const COMMAND_TIMEOUT_MS = 30_000;
const RECOVERY_MS = 300;
const SQLITE_BUSY_TIMEOUT_MS = 3000;

// Experimental on some Node versions: the warning is not the user's concern.
const importSqlite = async () => {
  const emit = process.emitWarning;
  process.emitWarning = (w, ...rest) => (String(w?.message ?? w).includes('SQLite') ? undefined : emit.call(process, w, ...rest));
  try { return await import('node:sqlite'); } catch { return null; } finally { process.emitWarning = emit; }
};

const runShell = (command) => spawnSync(command, { shell: true, encoding: 'utf8', timeout: COMMAND_TIMEOUT_MS });

// Fault injection: the database fails while a legitimate write arrives. Expected: one 5xx with the generic error body,
// and the process stays up. Two injectors: an exclusive lock on a SQLite file, or any shell command with its restore.
export async function faultProbe(run, w) {
  const { client, opts } = run;
  const how = opts.faultSqlite ? 'the SQLite file locked (BEGIN EXCLUSIVE)' : 'the configured fault command run'; // the command text can hold secrets: it stays out of reports
  const target = w ? `${w.method} ${w.path}` : 'write';
  const spec = { group: 'faults', probe: 'database-fault', target, name: `${target} with ${how}` };
  const expected = '503 or 500 with the generic error body and the common headers; the process keeps answering';
  if (!w) return run.notRun(spec, opts.writes.length ? 'no legitimate write succeeded: the fault probe sends one while the database is broken, so it has nothing to send' : 'a fault probe needs a --write');
  const st = run.settings(w.method, w.path);

  let release = () => {};
  if (opts.faultSqlite) {
    const sqlite = await importSqlite();
    if (!sqlite) return run.notRun(spec, 'node:sqlite is not available (Node 22.13+)');
    const file = resolve(opts.faultSqlite);
    if (!existsSync(file)) return run.notRun(spec, `looked for the database at "${file}" (from "${opts.faultSqlite}") and it does not exist: pass the app the same absolute path`);
    const db = new sqlite.DatabaseSync(file, { timeout: SQLITE_BUSY_TIMEOUT_MS });
    try { db.exec('BEGIN EXCLUSIVE'); } catch (e) { db.close(); return run.notRun(spec, `could not lock the database: ${e.message}`); }
    release = () => { try { db.exec('ROLLBACK'); } catch { /* the lock was already gone */ } db.close(); };
  } else {
    const started = runShell(opts.faultCmd);
    if (started.status !== 0) {
      if (opts.faultRestore) runShell(opts.faultRestore);
      return run.notRun(spec, `faultCmd failed (${started.error?.code ?? `exit ${started.status}`}): ${(started.stderr || started.stdout || '').trim().slice(0, 200)}`);
    }
    release = () => {
      if (!opts.faultRestore) return;
      const restored = runShell(opts.faultRestore);
      if (restored.status !== 0) process.stderr.write(`faultRestore failed (exit ${restored.status}): the fault may still be active.\n`);
    };
  }

  let res;
  try { const p = wire(w, st); res = await client.send(w.method, w.path, { body: p.text, type: p.type }); } finally { release(); }
  await new Promise((r) => setTimeout(r, RECOVERY_MS));
  if (!(await client.alive())) run.fail('process-died', spec, res.s ?? res.err, expected, 'the process died: an error from the database escaped a handler (unhandled rejection / uncaught exception)');
  else if (res.s === null || res.truncated) run.fail('connection-dropped', spec, res.err, expected, 'the connection was dropped instead of an error response');
  else if (res.s < 500) run.fail('fault-not-reported', spec, res.s, expected, 'a failed write was reported as something else');
  else if (leaksInternals(res.text)) run.fail('stack-leak', spec, res.s, expected, 'the 5xx body leaks internals (stack, driver error)');
  else run.pass(spec, res.s, expected);
}
