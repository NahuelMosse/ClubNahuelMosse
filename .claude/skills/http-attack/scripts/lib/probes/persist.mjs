import { readFileSync, realpathSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, isAbsolute, join, relative, resolve } from 'node:path';
import { UsageError } from '../errors.mjs';
import { granted, is2xx } from '../http.mjs';
import { wire } from '../body.mjs';
import { itemLabel, itemUrlOf } from './auth.mjs';

const real = (p) => { try { return realpathSync(p); } catch { return p; } };

// The state file is read and written by the tool: keep it inside the working directory, the temp directory or the config's persistDir.
export const checkPersistPath = (file, config, cwd) => {
  const abs = resolve(cwd, file);
  const target = join(real(dirname(abs)), basename(abs));
  const roots = [cwd, tmpdir(), config.persistDir].filter(Boolean).map(real);
  const inside = roots.some((root) => { const rel = relative(root, target); return rel !== '' && !rel.startsWith('..') && !isAbsolute(rel); });
  if (!inside) throw new UsageError(`${file} is outside the working directory and the temp directory: set "persistDir" in the config file to allow it.`);
};

const canonical = (value, ignore) => {
  if (Array.isArray(value)) return value.map((v) => canonical(v, ignore));
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).filter((k) => !ignore.includes(k)).sort().map((k) => [k, canonical(value[k], ignore)]));
  }
  return value;
};

// Compares two bodies; JSON bodies ignore the named fields (timestamps, request ids) at any depth.
export const sameBody = (a, b, ignore = []) => {
  try { return JSON.stringify(canonical(JSON.parse(a), ignore)) === JSON.stringify(canonical(JSON.parse(b), ignore)); } catch { return a === b; }
};

// Persistence is a two-step run around a restart. Returns { ok, message, data } for the CLI to print.
// A file that is not a previous persist state is never overwritten (it could be a package.json).
const refuseToOverwrite = (file) => {
  let existing;
  try { existing = readFileSync(file, 'utf8'); } catch (e) { if (e.code === 'ENOENT') return; throw new UsageError(`--persist-save: cannot read ${file}: ${e.code ?? e.message}`); }
  let state;
  try { state = JSON.parse(existing); } catch { /* not JSON */ }
  if (typeof state?.item !== 'string' || !('status' in state) || !('body' in state)) throw new UsageError(`--persist-save: ${file} exists and is not a state file written by --persist-save: it is not overwritten.`);
};

export async function persistSave(run, file) {
  const w = run.opts.writes[0];
  if (!w) throw new UsageError('--persist-save needs a --write.');
  refuseToOverwrite(file);
  const p = wire(w, run.settings(w.method, w.path));
  const res = await run.client.send(w.method, w.path, { body: p.text, type: p.type, common: false });
  if (res.s === null) throw new Error(`the create did not answer: ${res.err}`);
  if (!granted(res)) throw new UsageError(res.s >= 300 ? `The create was redirected to login (${res.headers.location}): the credentials do not work.` : `The create answered ${res.s}: nothing was saved.`);
  const item = itemUrlOf(res,{ base: run.client.base, itemPath: run.itemPath });
  if (!item) throw new UsageError(`The create answered ${res.s} without a readable location (give --item-path).`);
  const read = await run.client.send('GET', item, { common: false });
  try { writeFileSync(file, JSON.stringify({ item, status: read.s, body: read.text }, null, 2)); } catch (e) { throw new Error(`cannot write ${file}: ${e.code ?? e.message}`); }
  return { ok: is2xx(read.s), message: `saved ${item} (${read.s}) to ${file}. Restart the app, then run --persist-verify ${file}.`, data: { mode: 'persist-save', item, status: read.s } };
}

export async function persistVerify(run, file) {
  let saved;
  try { saved = JSON.parse(readFileSync(file, 'utf8')); } catch (e) { throw new UsageError(`--persist-verify: cannot read ${file}: ${e.code ?? e.message}`); }
  if (typeof saved?.item !== 'string') throw new UsageError(`--persist-verify: ${file} is not a file written by --persist-save.`);
  const now = await run.client.send('GET', saved.item, { common: false });
  const same = now.s === saved.status && sameBody(now.text, saved.body, run.config.persistIgnore);
  return {
    ok: same,
    message: `${same ? 'PASS' : 'FAIL critical'}  GET ${saved.item} after restart: ${now.s} (before: ${saved.status})${same ? '' : ' - expected the same status and body: the data is not durable'}`,
    data: { mode: 'persist-verify', ...(same ? {} : { id: `not-durable:persist-verify:GET ${itemLabel(saved.item)}`, rule: 'not-durable', severity: 'critical' }), item: saved.item, status: now.s, savedStatus: saved.status },
  };
}
