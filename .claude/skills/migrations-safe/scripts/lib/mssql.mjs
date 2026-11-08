// SQL Server knowledge the rules need: which editions run operations online, what an ALTER TABLE action
// is, and the shape of CREATE INDEX, ALTER INDEX and sp_rename. Edition facts: Enterprise (and Developer,
// Evaluation, Azure SQL) run online index operations and online schema changes; Standard and Express do not
// (Editions and supported features of SQL Server 2022 and 2025, "High availability" table).
import { ident, name, splitTopLevel, stripLiterals } from './parse.mjs';

export const isEnterprise = (edition) => edition === 'enterprise' || edition === 'azure';
export const ONLINE_ON = /\bonline\s*=\s*on\b/i;
export const RESUMABLE_ON = /\bresumable\s*=\s*on\b/i;
export const WAIT_AT_LOW_PRIORITY = /\bwait_at_low_priority\b/i;
// ALTER COLUMN ... WITH (ONLINE = ON) exists from SQL Server 2016.
export const ONLINE_ALTER_COLUMN_YEAR = 2016;

// Words that start an ALTER TABLE action; anything else after a comma continues the previous ADD or DROP COLUMN.
const ACTION_START = /^(?:add|drop|alter|with|set|check|nocheck|enable|disable|switch|rebuild|reorganize|trigger|no|lock_escalation|change_tracking|sparse|on|partition|data_deletion|system_versioning)\b/i;

// `ADD a int, b int` and `DROP COLUMN a, b` list their elements without repeating the verb.
export const normalizeTsqlActions = (actions) => {
  let last = null;
  return actions.map((a) => {
    if (!ACTION_START.test(a) && last) return `${last} ${a}`;
    if (/^add\b/i.test(a)) last = 'add';
    else if (/^drop\s+column\b/i.test(a)) last = 'drop column';
    else if (/^drop\s+constraint\b/i.test(a)) last = 'drop constraint';
    else last = null;
    return a;
  });
};

const EXPRESSION = /\bdefault\s*(\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)|[\w@.$]+(?:\s*\([^)]*\))?)/i;
// Not a runtime constant (the same value for every row): NEWID(), NEXT VALUE FOR, RAND(), a subquery.
const VOLATILE = /\b(?:newid|newsequentialid|rand|crypt_gen_random|next\s+value\s+for|select)\b/i;

// { present, constant } for the DEFAULT of a column definition.
export const defaultOf = (def) => {
  const m = stripLiterals(def).match(EXPRESSION);
  return m ? { present: true, constant: !VOLATILE.test(m[1]) } : { present: false, constant: true };
};

export const CREATE_INDEX = new RegExp(String.raw`^create\s+(?:unique\s+)?(?:(?:non)?clustered\s+)?(?:(?:non)?clustered\s+)?(?:columnstore\s+)?index\s+(?:${ident})\s+on\s+(${ident})`, 'i');
export const ALTER_INDEX = new RegExp(String.raw`^alter\s+index\s+(?:${ident}|all)\s+on\s+(${ident})\s+(rebuild|reorganize|disable|set|resume|abort|pause)\b`, 'i');
const SP_RENAME = /^exec(?:ute)?\s+(?:sys\.)?sp_rename\s+(?:@objname\s*=\s*)?N?'([^']*)'\s*,\s*(?:@newname\s*=\s*)?N?'([^']*)'(?:\s*,\s*(?:@objtype\s*=\s*)?N?'(\w+)')?/i;

const parts = (qualified) => qualified.split('.').map((p) => p.replace(/^\[|\]$/g, '').replace(/^"|"$/g, ''));

// { kind: 'column' | 'object', table, from, to } for EXEC sp_rename, or null; other object types (INDEX, STATISTICS) are not renames of data the code reads.
export const spRename = (text) => {
  const m = text.match(SP_RENAME);
  if (!m) return null;
  const type = (m[3] ?? 'OBJECT').toUpperCase();
  const old = parts(m[1]);
  if (type === 'COLUMN') return { kind: 'column', table: name(old.at(-2) ?? ''), from: old.at(-1), to: m[2] };
  if (type === 'OBJECT') return { kind: 'object', table: name(old.at(-1)), from: old.at(-1), to: m[2] };
  return null;
};

// ── Column definitions, so ALTER COLUMN can tell a metadata-only widening from a rewrite ──────────────────

const COLUMN_DEF = new RegExp(String.raw`^(${ident})\s+\[?(\w+)\]?(?:\s*\(\s*(max|\d+)\s*(?:,\s*\d+\s*)?\))?(.*)$`, 'i');
// Types whose length can grow in place: the length lives in the column metadata, rows are not rewritten.
const GROWS_IN_PLACE = new Set(['varchar', 'nvarchar', 'varbinary']);

// { column, type, length ('max' or a number or null), nullable, collation } of `col type(len) [COLLATE c] [NOT] NULL ...`.
// Without NULL/NOT NULL the column is nullable (the default of ANSI_NULL_DFLT_ON), unless it is a PRIMARY KEY.
export const tsqlColumn = (def) => {
  const m = stripLiterals(def.trim()).match(COLUMN_DEF);
  if (!m) return null;
  const rest = m[4];
  const collation = rest.match(/\bcollate\s+([\w]+)/i)?.[1]?.toLowerCase() ?? null;
  const notNull = /\bnot\s+null\b/i.test(rest) || /\bprimary\s+key\b/i.test(rest);
  return {
    column: name(m[1]), type: m[2].toLowerCase(), length: m[3] === undefined ? null : /^max$/i.test(m[3]) ? 'max' : Number(m[3]),
    nullable: !notNull, collation,
  };
};

const CREATE_TABLE = new RegExp(String.raw`^create\s+table\s+(${ident})\s*\((.*)\)[^)]*$`, 'is');
const ADD_COLUMN = /^add\s+(?:column\s+)?(.*)$/is;
const NOT_A_COLUMN = /^(?:constraint|index|key|unique|primary|foreign|check|period|periodic|system_time)\b/i;

// Replays one statement (earlier migration, --schema file, or the file being read) into `defs` (`table.column` → column).
export const learnTsql = (text, defs) => {
  const create = text.match(CREATE_TABLE);
  if (create) {
    const table = name(create[1]);
    for (const key of [...defs.keys()].filter((k) => k.startsWith(`${table}.`))) defs.delete(key);
    const elements = splitTopLevel(create[2]);
    for (const el of elements.filter((e) => !NOT_A_COLUMN.test(e))) { const c = tsqlColumn(el); if (c) defs.set(`${table}.${c.column}`, c); }
    for (const el of elements.filter((e) => /^(?:constraint\s+\S+\s+)?primary\s+key\b/i.test(e)))
      for (const col of (el.match(/\(([^)]*)\)/)?.[1] ?? '').split(',')) { const c = defs.get(`${table}.${name(col.trim().split(/\s+/)[0])}`); if (c) c.nullable = false; }
    return;
  }
  const alter = text.match(new RegExp(String.raw`^alter\s+table\s+(${ident})\s+(.*)$`, 'is'));
  if (!alter) return;
  const table = name(alter[1]);
  for (const a of normalizeTsqlActions(splitTopLevel(alter[2]))) {
    const add = a.match(ADD_COLUMN);
    const change = a.match(/^alter\s+column\s+(.*?)(?:\s+with\s*\(.*\))?$/is);
    const drop = a.match(new RegExp(String.raw`^drop\s+column\s+(?:if\s+exists\s+)?(${ident})`, 'i'));
    const def = add && !NOT_A_COLUMN.test(add[1]) ? add[1] : change?.[1];
    const c = def ? tsqlColumn(def) : null;
    if (c) defs.set(`${table}.${c.column}`, c);
    else if (change) defs.delete(`${table}.${name(change[1].split(/\s+/)[0])}`);
    else if (drop) defs.delete(`${table}.${name(drop[1])}`);
  }
};

// Why `next` is not a metadata-only change of `prev`, or null when it is: the same variable-length type with a
// longer length, the same nullability and the same collation. varchar(n) -> varchar(max) is not (the values
// move to LOB storage), and neither is shortening, another type, NULL -> NOT NULL, or a changed collation.
export const widenOnlyProblem = (prev, next) => {
  if (!next) return 'its new definition could not be read';
  if (prev.type !== next.type) return `the type changes from ${prev.type} to ${next.type}`;
  if (!GROWS_IN_PLACE.has(next.type)) return `${next.type} is a fixed-size type`;
  if (prev.length === null || next.length === null) return 'a length is not stated';
  if (next.length === 'max' && prev.length !== 'max') return `${prev.type}(${prev.length}) to ${next.type}(max) moves the values to LOB storage`;
  if (prev.length !== 'max' && next.length !== 'max' && next.length < prev.length) return `the length shrinks from ${prev.length} to ${next.length}, which scans the data`;
  if (prev.length === 'max' && next.length !== 'max') return `${prev.type}(max) shrinks to ${next.type}(${next.length}), which scans the data`;
  if (prev.nullable !== next.nullable) return `nullability changes to ${next.nullable ? 'NULL' : 'NOT NULL'}`;
  if (prev.collation !== next.collation) return `the collation changes (an ALTER COLUMN without COLLATE resets it to the database default)`;
  return null;
};
