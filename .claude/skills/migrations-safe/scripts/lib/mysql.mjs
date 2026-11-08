// MySQL and MariaDB knowledge the rules need: server versions, which online DDL algorithm an operation can
// use, and column and ENUM/SET definitions.
import { UsageError } from './errors.mjs';
import { ident, name, splitTopLevel, stripLiterals } from './parse.mjs';
import { parseAlter } from './schema.mjs';

export const DEFAULT_MYSQL_VERSION = '8.0';
// InnoDB keeps 64 row versions per table (MySQL 8.0.29+); instant ADD/DROP COLUMN each use one, a rebuild resets
// the count. The linter warns from 56 on: a margin it chose, because it only sees the files it reads.
export const INSTANT_ROW_VERSION_LIMIT = 64;
export const INSTANT_ROW_VERSION_WARN = 56;

// "8.0", "8.0.28", "8", "5.7", "mariadb-10.6", "mariadb:11". A missing minor or patch means the newest of the series.
export const parseMysqlVersion = (text) => {
  const m = String(text ?? '').trim().toLowerCase().match(/^(?:(mysql|mariadb)[-:\s]?)?v?(\d+)(?:\.(\d+))?(?:\.(\d+))?(?![\d.])/);
  if (!m) return null;
  const flavor = m[1] ?? 'mysql';
  const major = Number(m[2]);
  const minor = m[3] === undefined ? null : Number(m[3]);
  const patch = m[4] === undefined ? null : Number(m[4]);
  const numbers = [major, minor, patch].filter((n) => n !== null).join('.');
  return { flavor, major, minor, patch, label: `${flavor === 'mariadb' ? 'MariaDB' : 'MySQL'} ${numbers}${minor === null ? ' (newest minor)' : ''}` };
};

export const mysqlVersionOrThrow = (text) => {
  const v = parseMysqlVersion(text);
  if (!v) throw new UsageError(`unknown MySQL version "${String(text).slice(0, 30)}" (examples: 8.0, 8.0.28, 8.4, 5.7, mariadb-10.6)`);
  return v;
};

// True when the server is `major.minor.patch` or newer (an unknown minor or patch counts as the newest).
export const atLeast = (v, major, minor, patch = 0) => {
  if (v.major !== major) return v.major > major;
  if ((v.minor ?? Infinity) !== minor) return (v.minor ?? Infinity) > minor;
  return (v.patch ?? Infinity) >= patch;
};

export const isMaria = (v) => v.flavor === 'mariadb';

export const supportsInstant = (v) => (isMaria(v) ? atLeast(v, 10, 3) : atLeast(v, 8, 0, 12));
export const instantDrop = (v) => (isMaria(v) ? atLeast(v, 10, 4) : atLeast(v, 8, 0, 29));
export const instantAnyPosition = (v) => (isMaria(v) ? atLeast(v, 10, 4) : atLeast(v, 8, 0, 29));
export const instantRenameColumn = (v) => !isMaria(v) && atLeast(v, 8, 0, 28);
export const hasRenameColumn = (v) => (isMaria(v) ? atLeast(v, 10, 5, 2) : atLeast(v, 8, 0));
export const instantIsDefault = (v) => !isMaria(v) && atLeast(v, 8, 0, 12);
export const hasRowVersionLimit = (v) => !isMaria(v) && atLeast(v, 8, 0, 29);
// MariaDB 11.2 runs ALGORITHM=COPY online (MDEV-16329): writes are not blocked, the copy is just slow.
export const onlineCopy = (v) => isMaria(v) && atLeast(v, 11, 2);

const POSITION = /\b(?:first|after\s+\S+)\s*$/i;
export const hasPosition = (action) => POSITION.test(action);

// ── action shapes ──────────────────────────────────────────────────────────────────────────────────

const NOT_COLUMN_ADD = /^(?:constraint|index|key|unique|primary|foreign|check|fulltext|spatial|partition)\b/i;
const NOT_COLUMN_DROP = /^drop (?:constraint|index|key|default|not null|primary|foreign|check|partition|expression|identity)\b/i;
export const isOption = (a) => /^(?:algorithm|lock)\b/i.test(a) || /^wait\s+\d+$/i.test(a) || /^nowait$/i.test(a);
export const isAddColumn = (a) => /^add\b/i.test(a) && !NOT_COLUMN_ADD.test(a.replace(/^add\s+(?:column\s+)?/i, ''));
export const isDropColumn = (a) => /^drop\s+\S/i.test(a) && !NOT_COLUMN_DROP.test(a);

// ── column definitions ──────────────────────────────────────────────────────────────────────────────

const COLUMN_DEF = /^(?:(?:add|modify)\s+(?:column\s+)?(?:if (?:not )?exists\s+)?(\S+)|change\s+(?:column\s+)?(?:if exists\s+)?(\S+)\s+(\S+)|(\S+))\s+([a-z]+(?:\s*\([^)]*\))?(?:\s+unsigned)?)/i;

// { column, oldColumn, type, nullable } of an ADD/MODIFY/CHANGE action or a CREATE TABLE element, or null.
export const colDef = (text) => {
  const t = text.trim();
  if (NOT_COLUMN_ADD.test(t.replace(/^(?:add|modify)\s+(?:column\s+)?/i, '')) && /^add\b/i.test(t)) return null;
  const m = t.match(COLUMN_DEF);
  if (!m) return null;
  const column = name(m[3] ?? m[1] ?? m[4]);
  return {
    column, oldColumn: name(m[2] ?? m[1] ?? m[4]), type: m[5].toLowerCase().replace(/\s+/g, ''),
    nullable: !/\bnot null\b/i.test(stripLiterals(t)),
  };
};

// Why `action` cannot run with ALGORITHM=INSTANT, INPLACE or NOCOPY on this server: { why, level } or null.
// `before` is the column's known earlier definition (colDef) when the action changes a column.
export const algorithmProblem = (action, algorithm, v, { addsPrimaryKey, fkChecksOff, before }) => {
  const a = action.trim();
  const maria = isMaria(v);
  const addIndex = /^add (?:unique |fulltext |spatial )?(?:index|key)\b|^add (?:constraint \S+ )?unique\b|^add (?:fulltext|spatial)\b/i.test(a);
  const err = (why) => ({ why, level: 'error' });
  if (algorithm === 'instant') {
    if (isAddColumn(a) && hasPosition(a) && !instantAnyPosition(v))
      return err(`adding a column at FIRST/AFTER is not instant before ${maria ? 'MariaDB 10.4' : 'MySQL 8.0.29'} (only as the last column)`);
    if (/^drop column\b/i.test(a) && !instantDrop(v)) return err(`dropping a column is not instant before ${maria ? 'MariaDB 10.4' : 'MySQL 8.0.29'}`);
    if (/^rename column\b/i.test(a) && !maria && !instantRenameColumn(v)) return err('renaming a column is not instant before MySQL 8.0.28 (INPLACE only)');
    if (addIndex || /^(?:add|drop) primary key\b/i.test(a) || /^drop (?:index|key)\b/i.test(a)) return err('index and primary key changes are INPLACE, never INSTANT');
    if (/^add (?:constraint \S+ )?foreign key\b/i.test(a)) return err('adding a foreign key is never INSTANT');
    if (/^(?:force$|engine\s*=)/i.test(a) || /^(?:row_format|key_block_size)\b/i.test(a)) return err('a table rebuild is never INSTANT');
    if (/^convert to\b/i.test(a) && !(maria && atLeast(v, 10, 4))) return err('converting the character set copies the table');
    if (/^(?:modify|change)\b/i.test(a) && !/\b(?:enum|set)\s*\(/i.test(a)) {
      const now = colDef(a);
      const renameOnly = /^change\b/i.test(a) && now && now.column !== now.oldColumn;
      const same = before && now && before.type === now.type && before.nullable === now.nullable;
      const moves = hasPosition(a) || /\b(?:character set|charset|collate)\s+\w/i.test(stripLiterals(a));
      if (before && now && !same) {
        const what = before.type !== now.type ? `its type (${before.type} to ${now.type})` : 'its nullability';
        return maria && atLeast(v, 10, 4) ? { why: `changing ${what} is not INSTANT on most MariaDB versions`, level: 'warning' } : err(`changing ${what} is not INSTANT, only the default, ENUM/SET members at the end and (8.0.28+) names are`);
      }
      if (!maria && !same && !renameOnly) return { why: 'cannot tell whether only the default changes (a type, nullability, charset or position change is not INSTANT): the earlier definition of the column is not in the files read', level: 'warning' };
      if (!maria && same && moves) return err('a character set, collation or position change is not INSTANT');
    }
  }
  if (algorithm === 'inplace' || algorithm === 'nocopy') {
    if (/^drop primary key\b/i.test(a) && !addsPrimaryKey) return err('dropping a primary key without adding one in the same statement only works with ALGORITHM=COPY');
    if (/^add (?:constraint \S+ )?foreign key\b/i.test(a) && !fkChecksOff) return err('adding a foreign key with foreign_key_checks=1 only works with ALGORITHM=COPY');
    if (/^convert to\b/i.test(a) && !maria)
      return { why: 'CONVERT TO CHARACTER SET runs INPLACE only when no text column is indexed and the change is utf8mb3 to utf8mb4; otherwise the server asks for COPY', level: 'warning' };
  }
  return null;
};

// ── ENUM and SET ───────────────────────────────────────────────────────────────────────────────────

const ENUM_DEF = /^(?:(?:modify|add)\s+(?:column\s+)?(?:if not exists\s+)?(\S+)|change\s+(?:column\s+)?\S+\s+(\S+)|(\S+))\s+(enum|set)\s*\(((?:\s*'(?:[^'\\]|\\.|'')*'\s*,?)+)\s*\)/i;

// { column, kind, members, nullable } when `text` (an ALTER action or a CREATE TABLE element) defines an ENUM or SET column.
export const enumOf = (text) => {
  const m = text.trim().match(ENUM_DEF);
  if (!m) return null;
  const members = [...m[5].matchAll(/'((?:[^'\\]|\\.|'')*)'/g)].map((x) => x[1]);
  return { column: name(m[1] ?? m[2] ?? m[3]), kind: m[4].toLowerCase(), members, nullable: !/\bnot null\b/i.test(stripLiterals(text)) };
};

export const storageBytes = (e) => {
  if (e.kind === 'enum') return e.members.length <= 255 ? 1 : 2;
  const n = e.members.length;
  return n <= 8 ? 1 : n <= 16 ? 2 : n <= 24 ? 3 : n <= 32 ? 4 : 8;
};

// 'append' (instant), 'resize' (appended but the storage grows: copy), 'reorder' (members renumbered, removed or kind changed: copy), 'same'.
export const enumChange = (before, after) => {
  if (before.kind !== after.kind) return 'reorder';
  const prefix = before.members.length <= after.members.length && before.members.every((m, i) => m === after.members[i]);
  if (!prefix) return 'reorder';
  if (after.members.length === before.members.length) return 'same';
  return storageBytes(before) === storageBytes(after) ? 'append' : 'resize';
};

const CREATE_BODY = new RegExp(String.raw`^create (?:temp(?:orary)? )?table (?:if not exists )?(${ident})\s*\((.*)\)[^)]*$`, 'is');

// Leading column of an index (or key, unique, primary key, foreign key) definition, or null.
export const indexedColumn = (def) => {
  const m = def.trim().match(/^(?:add\s+)?(?:constraint\s+(?:\S+\s+)?)?(?:primary key|unique(?:\s+(?:key|index))?|fulltext(?:\s+(?:key|index))?|spatial(?:\s+(?:key|index))?|key|index|foreign key)\b[^()]*\(\s*([^),\s(]+)/i);
  return m ? name(m[1]) : null;
};

// The ENUM/SET and other columns, and the leading columns of every index, a CREATE TABLE declares.
export const createFacts = (text) => {
  const m = text.match(CREATE_BODY);
  if (!m) return null;
  const enums = new Map();
  const defs = new Map();
  const indexed = new Set();
  for (const el of splitTopLevel(m[2])) {
    if (!/^(?:constraint|primary|foreign|unique|check|key|index|fulltext|spatial)\b/i.test(el)) {
      const e = enumOf(el);
      if (e) enums.set(e.column, e);
      const d = colDef(el);
      if (d) defs.set(d.column, d);
      if (/\b(?:primary key|unique(?: key)?)\b/i.test(stripLiterals(el))) indexed.add(name(el.match(new RegExp(`^(${ident})`))?.[1]));
    } else {
      const c = indexedColumn(el);
      if (c) indexed.add(c);
    }
  }
  return { table: name(m[1]), enums, defs, indexed };
};

// ── what a statement teaches about the schema ───────────────────────────────────────────────────────────

// Whether the actions make one instant ADD/DROP COLUMN on this server (one row version), and whether they rebuild the table.
export const instantStatement = (actions, algo, v) => {
  if (!hasRowVersionLimit(v)) return false;
  const real = actions.filter((a) => !isOption(a));
  const instantKinds = real.every((a) => isAddColumn(a) || /^drop column\b/i.test(a) || /^rename column\b/i.test(a) || /^alter (?:column )?\S+ (?:set default|drop default)\b/i.test(a));
  return instantKinds && real.some((a) => isAddColumn(a) || /^drop column\b/i.test(a)) && (algo === 'instant' || algo === undefined);
};
export const rebuildsTable = (actions, algo) => actions.some((a) => /^(?:force|engine\s*=\s*innodb|row_format|key_block_size|(?:add|drop) primary key)\b/i.test(a))
  || ((algo === 'inplace' || algo === 'copy') && actions.some((a) => isAddColumn(a) || /^drop column\b/i.test(a)));

// Records the columns, ENUMs, indexes and instant row versions the actions of an ALTER leave behind; returns the
// table's instant row-version count when this statement added one, else null.
export const learnActions = (table, actions, { enums, indexed, defs, instantVersions }, v) => {
  let idx = indexed.get(table);
  if (!idx) { idx = new Set(); indexed.set(table, idx); }
  for (const a of actions) {
    if (/^add\b/i.test(a) && !/\bforeign key\b/i.test(a)) { const c = indexedColumn(a); if (c) idx.add(c); }
    if (/^add (?:constraint \S+ )?foreign key\b/i.test(a)) { const c = indexedColumn(a); if (c) idx.add(c); }
    if (!/^(?:add|modify|change)\b/i.test(a)) continue;
    const e = enumOf(a);
    const d = colDef(a);
    if (/^change\b/i.test(a) && d) { enums.delete(`${table}.${d.oldColumn}`); defs.delete(`${table}.${d.oldColumn}`); }
    if (e) enums.set(`${table}.${e.column}`, e);
    if (d) defs.set(`${table}.${d.column}`, d);
  }
  const algo = actions.map((a) => a.match(/^algorithm\s*=?\s*(\w+)/i)?.[1]?.toLowerCase()).find(Boolean);
  let count = null;
  if (instantStatement(actions, algo, v)) { count = (instantVersions.get(table) ?? 0) + 1; instantVersions.set(table, count); }
  else if (rebuildsTable(actions, algo)) instantVersions.set(table, 0);
  return count;
};

const INDEX_STATEMENT = new RegExp(String.raw`^create (?:(?:unique|fulltext|spatial) )?index (?:if not exists )?\S+ (?:using \w+ )?on (${ident})\s*\(\s*([^),\s(]+)`, 'i');

// Replays one statement of an earlier migration (or of a --schema file) into the shared maps.
export const learnStatement = (t, maps, v) => {
  const facts = createFacts(t);
  if (facts) {
    for (const key of [...maps.enums.keys()].filter((e) => e.startsWith(`${facts.table}.`))) maps.enums.delete(key);
    for (const key of [...maps.defs.keys()].filter((e) => e.startsWith(`${facts.table}.`))) maps.defs.delete(key);
    for (const [c, e] of facts.enums) maps.enums.set(`${facts.table}.${c}`, e);
    for (const [c, d] of facts.defs) maps.defs.set(`${facts.table}.${c}`, d);
    maps.indexed.set(facts.table, facts.indexed);
    maps.instantVersions.delete(facts.table);
    return;
  }
  const index = t.match(INDEX_STATEMENT);
  if (index) {
    const table = name(index[1]);
    if (!maps.indexed.has(table)) maps.indexed.set(table, new Set());
    maps.indexed.get(table).add(name(index[2]));
    return;
  }
  const alter = parseAlter(t);
  if (alter) learnActions(alter.table, alter.actions, maps, v);
};
export { INDEX_STATEMENT };
