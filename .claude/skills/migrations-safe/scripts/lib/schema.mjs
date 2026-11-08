// A light picture of the columns each table has, built from CREATE TABLE and ALTER TABLE statements.
// It exists so the linter can compare a SQLite table rebuild against the table it replaces.
import { flat, ident, name, parse, splitTopLevel } from './parse.mjs';

const ALTER_RE = new RegExp(String.raw`^alter (?:online )?(?:ignore )?table (?:if exists )?(?:only )?(${ident})(?: \*)?\s+(?:(wait\s+\d+|nowait)\s+)?(.*)$`, 'is');
const CREATE_RE = new RegExp(String.raw`^create (?:temp(?:orary)? |unlogged )?table (?:if not exists )?(${ident})\s*\((.*)\)[^)]*$`, 'is');
const CONSTRAINT_START = /^(constraint|primary|foreign|unique|check|key|index|fulltext|spatial|like|exclude)\b/i;

export const parseAlter = (text) => {
  const m = text.match(ALTER_RE);
  return m ? { table: name(m[1]), actions: splitTopLevel(m[3]), wait: m[2] !== undefined } : null;
};

export const columnsOfCreate = (text) => {
  const m = text.match(CREATE_RE);
  if (!m) return null;
  const cols = splitTopLevel(m[2]).filter((d) => !CONSTRAINT_START.test(d)).map((d) => name(d.match(new RegExp(`^(${ident})`))?.[1]));
  return { table: name(m[1]), columns: new Set(cols.filter(Boolean)) };
};

// The column names of the new table that an `INSERT INTO t (a, b) SELECT ...` fills, when it lists them.
export const insertTargets = (text) => {
  const m = text.match(new RegExp(String.raw`^insert into (${ident})\s*\(([^)]*)\)\s*select\b`, 'i'));
  return m ? { table: name(m[1]), columns: new Set(m[2].split(',').map((c) => name(c.trim()))) } : null;
};

export const applySchema = (tables, text) => {
  const create = columnsOfCreate(text);
  if (create) { tables.set(create.table, create.columns); return; }
  const drop = text.match(new RegExp(String.raw`^drop table (?:if exists )?(${ident})`, 'i'));
  if (drop) { tables.delete(name(drop[1])); return; }
  const alter = parseAlter(text);
  if (!alter) return;
  let table = alter.table;
  for (const a of alter.actions) {
    const cols = tables.get(table);
    let m;
    if ((m = a.match(new RegExp(String.raw`^rename to (${ident})`, 'i')))) {
      if (cols) { tables.set(name(m[1]), cols); tables.delete(table); }
      table = name(m[1]);
    } else if (cols && (m = a.match(new RegExp(String.raw`^add (?:column )?(?:if not exists )?(${ident})`, 'i'))) && !CONSTRAINT_START.test(a.replace(/^add /i, ''))) cols.add(name(m[1]));
    else if (cols && (m = a.match(new RegExp(String.raw`^drop column (?:if exists )?(${ident})`, 'i')))) cols.delete(name(m[1]));
    else if (cols && (m = a.match(new RegExp(String.raw`^rename (?:column )?(${ident}) to (${ident})`, 'i')))) { cols.delete(name(m[1])); cols.add(name(m[2])); }
  }
};

export const cloneSchema = (tables) => new Map([...tables].map(([t, c]) => [t, new Set(c)]));

export const applySql = (tables, sql, dialect) => {
  for (const s of parse(sql, { dialect }).statements) applySchema(tables, flat(s.text));
};
