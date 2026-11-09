// Rehearses migrations on a throwaway copy of a SQLite database (or of a database built from a seed).
// Everything it reports comes from the data: rows and non-NULL values per column before and after each
// migration, orphan foreign keys the migration created, and whether the file ran.
import { existsSync, mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { decodeSql, parse } from './parse.mjs';
import { detectRunner, profileOf, wrapsFile, RUNNER_IDS } from './runners.mjs';

export class RehearsalUsageError extends Error {}

const MIN_NODE = [22, 13];
const q = (id) => `"${id.replaceAll('"', '""')}"`;

const loadSqlite = async () => {
  const [major, minor] = process.versions.node.split('.').map(Number);
  if (major < MIN_NODE[0] || (major === MIN_NODE[0] && minor < MIN_NODE[1]))
    throw new RehearsalUsageError(`node:sqlite needs Node ${MIN_NODE.join('.')} or newer without flags (this is ${process.versions.node})`);
  process.removeAllListeners('warning'); // node:sqlite prints an ExperimentalWarning on import
  return (await import('node:sqlite')).DatabaseSync;
};

// Tables with their row count, and for each column its declared type and number of non-NULL values.
const snapshot = (db) => {
  const tables = new Map();
  const names = db.prepare("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name").all();
  for (const { name } of names) {
    const cols = db.prepare(`PRAGMA table_info(${q(name)})`).all();
    // A column's fingerprint (distinct values, total text length, smallest and largest value) tells a renamed
    // column, whose values survive, from a dropped one and a new one that merely has as many non-NULL values.
    const per = (c, i) => `, count(${q(c.name)}) AS c${i}, count(DISTINCT ${q(c.name)}) AS d${i}, total(length(quote(${q(c.name)}))) AS l${i}, min(quote(${q(c.name)})) AS lo${i}, max(quote(${q(c.name)})) AS hi${i}`;
    const counts = cols.length ? db.prepare(`SELECT count(*) AS n${cols.map(per).join('')} FROM ${q(name)}`).get() : { n: 0 };
    tables.set(name, {
      rows: Number(counts.n),
      columns: new Map(cols.map((c, i) => [c.name, {
        type: c.type, notnull: c.notnull === 1, nonNull: Number(counts[`c${i}`]),
        fingerprint: [counts[`d${i}`], counts[`l${i}`], counts[`lo${i}`], counts[`hi${i}`]].join('|'),
      }])),
    });
  }
  return tables;
};

const orphanKeys = (db) => new Set(db.prepare('PRAGMA foreign_key_check').all().map((r) => `${r.table}|${r.rowid}|${r.parent}|${r.fkid}`));

// What changed between two snapshots: lines to print, and the losses among them.
export const diff = (before, after, kind, allowLoss) => {
  const lines = [];
  const lost = [];
  const allowed = (t, c) => allowLoss.has(t) || (c && allowLoss.has(`${t}.${c}`));
  for (const [t, b] of before) {
    const a = after.get(t);
    if (!a) {
      lines.push(`${t}: dropped (${b.rows} row(s))`);
      if (b.rows > 0 && kind === 'up' && !allowed(t)) lost.push(`${t} ${b.rows}→dropped`);
      continue;
    }
    const notes = [];
    const removed = [...b.columns].filter(([c]) => !a.columns.has(c));
    const added = [...a.columns].filter(([c]) => !b.columns.has(c));
    const paired = new Map();
    for (const [c, info] of removed) {
      const twin = added.find(([n, x]) => x.nonNull === info.nonNull && x.fingerprint === info.fingerprint && info.nonNull > 0 && ![...paired.values()].includes(n));
      if (twin) paired.set(c, twin[0]);
    }
    for (const [c, info] of removed) {
      if (paired.has(c)) { notes.push(`${c} renamed to ${paired.get(c)}?`); continue; }
      notes.push(`-${c}${info.nonNull ? ` (${info.nonNull} non-NULL)` : ''}`);
      if (info.nonNull > 0 && kind === 'up' && !allowed(t, c)) lost.push(`${t}.${c} dropped with ${info.nonNull} non-NULL value(s)`);
    }
    for (const [c] of added) if (![...paired.values()].includes(c)) notes.push(`+${c}`);
    for (const [c, info] of b.columns) {
      const now = a.columns.get(c);
      if (!now) continue;
      if (now.type !== info.type) notes.push(`${c} ${info.type || '-'}→${now.type || '-'}`);
      if (now.nonNull < info.nonNull && a.rows >= b.rows) {
        notes.push(`${c} non-NULL ${info.nonNull}→${now.nonNull}`);
        if (kind === 'up' && !allowed(t, c)) lost.push(`${t}.${c} non-NULL ${info.nonNull}→${now.nonNull}`);
      }
    }
    if (a.rows < b.rows && kind === 'up' && !allowed(t)) lost.push(`${t} ${b.rows}→${a.rows} rows`);
    lines.push(`${t.padEnd(18)} rows ${b.rows === a.rows ? b.rows : `${b.rows}→${a.rows}`}${notes.length ? `  columns: ${notes.join(', ')}` : ''}`);
  }
  for (const [t, a] of after) if (!before.has(t)) lines.push(`${t.padEnd(18)} new, ${a.rows} row(s), columns: ${[...a.columns.keys()].join(', ')}`);
  return { lines, lost };
};

export const partFor = (file, kind, dialect = 'sqlite') => {
  const parsed = parse(decodeSql(readFileSync(file)), { dialect });
  if (kind === 'up') return { sql: parsed.upSql, markers: parsed.markers, statements: parsed.statements.length };
  return { sql: parsed.hasDownSection ? parsed.downSql : parsed.upSql, markers: parsed.markers, statements: parsed.statements.length, hasDown: parsed.hasDownSection };
};

// opts: { source, ups, downs (array of files, 'sections' for the down sections of the ups, or null),
//         runner, foreignKeys ('on'|'off'|null), allowLoss: [] }. Returns { code, lines }.
export const rehearse = async (opts, print) => {
  const { source, ups, downs = null } = opts;
  if (!source || !ups.length) throw new RehearsalUsageError('a database or seed and at least one migration are needed');
  if (opts.runner && !RUNNER_IDS.includes(opts.runner)) throw new RehearsalUsageError(`unknown runner ${opts.runner}`);
  for (const f of [source, ...ups, ...(Array.isArray(downs) ? downs : [])]) if (!existsSync(f)) throw new RehearsalUsageError(`${f} does not exist`);
  const downFiles = downs === 'sections' ? ups : downs;
  if (downs === 'sections') for (const f of ups) if (!partFor(f, 'down').hasDown) throw new RehearsalUsageError(`${f} has no down section: pass the down files after --down`);
  const DatabaseSync = await loadSqlite();

  const detected = opts.runner ? { id: opts.runner, evidence: '--runner' } : detectRunner(ups[0], { markers: partFor(ups[0], 'up').markers, fileName: ups[0].split(/[\\/]/).at(-1) });
  const profile = profileOf(detected.id);
  const foreignKeys = opts.foreignKeys ?? profile.foreignKeys;
  const allowLoss = new Set(opts.allowLoss ?? []);

  const dir = mkdtempSync(join(tmpdir(), 'rehearse-'));
  const copy = join(dir, 'copy.sqlite');
  let db;
  try {
    if (/\.sql$/i.test(source)) {
      db = new DatabaseSync(copy);
      db.exec('PRAGMA foreign_keys = OFF');
      db.exec(decodeSql(readFileSync(source)));
    } else {
      const src = new DatabaseSync(source, { readOnly: true });
      try { src.exec(`VACUUM INTO '${copy.replaceAll("'", "''")}'`); } finally { src.close(); }
      db = new DatabaseSync(copy);
    }
    print(`runner: ${profile.label} (${detected.evidence}) · foreign_keys=${foreignKeys}`);
    let failed = 0;
    let orphans = orphanKeys(db);
    const apply = (file, kind) => {
      const part = partFor(file, kind);
      const wrap = wrapsFile(profile, { noTransaction: part.markers.noTransaction, statements: part.statements });
      const before = snapshot(db);
      db.exec(`PRAGMA foreign_keys = ${foreignKeys === 'on' ? 'ON' : 'OFF'}`);
      const t0 = performance.now();
      try {
        if (wrap) db.exec('BEGIN');
        db.exec(part.sql);
        if (wrap) db.exec('COMMIT');
      } catch (e) {
        if (wrap || db.isTransaction) { try { db.exec('ROLLBACK'); } catch { /* the failure already closed the transaction */ } }
        failed++;
        print(`FAILED  ${kind.padEnd(4)} ${file}: ${e.message}`);
        return false;
      }
      const ms = (performance.now() - t0).toFixed(1);
      const { lines, lost } = diff(before, snapshot(db), kind, allowLoss);
      const now = orphanKeys(db);
      const fresh = [...now].filter((k) => !orphans.has(k));
      orphans = now;
      const bad = lost.length || fresh.length;
      if (bad) failed++;
      print(`${bad ? 'LOST   ' : 'ran    '} ${kind.padEnd(4)} ${file} in ${ms} ms`);
      lines.forEach((l) => print(`          ${l}`));
      lost.forEach((l) => print(`          lost: ${l}`));
      if (fresh.length) print(`          new orphan foreign key row(s): ${fresh.length}, first in ${fresh[0].split('|')[0]} (rows that were already orphans are not counted)`);
      return true;
    };

    let stopped = null;
    for (const f of ups) if (!apply(f, 'up')) { stopped = f; break; }
    if (stopped) {
      ups.slice(ups.indexOf(stopped) + 1).forEach((f) => print(`SKIPPED up   ${f}: an earlier migration failed`));
    } else if (downFiles) {
      for (const f of [...downFiles].reverse()) if (!apply(f, 'down')) { stopped = f; break; }
      if (!stopped) for (const f of ups) if (!apply(f, 'up')) break;
    }
    const nDown = downFiles ? downFiles.length : 0;
    print(`${ups.length} up(s)${nDown ? `, ${nDown} down(s)` : ''} on a copy of ${source}: ${failed ? `${failed} problem(s)${stopped ? `, stopped at ${stopped}` : ''}` : 'all ran, no rows or values lost, no new orphans'}`);
    return failed ? 1 : 0;
  } finally {
    db?.close();
    rmSync(dir, { recursive: true, force: true });
  }
};
