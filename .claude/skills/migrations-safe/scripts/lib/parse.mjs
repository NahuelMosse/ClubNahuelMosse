// SQL reading: decoding, statement splitting, comments, directives and runner markers.

const DOWN_MARKER = /^\s*--\s*(\+goose\s+down|\+migrate\s+down|migrate:down)\b/i;
const DIRECTIVE_AT_START = /^migration-lint:\s*(\S+)\s*(.*)$/is;

export const KNOWN_DIRECTIVES = ['allow', 'allow-file', 'irreversible', 'dialect'];

// Bytes to text: UTF-8 with or without BOM, UTF-16 with BOM, UTF-16 LE/BE without BOM (PowerShell 5.1 `>`).
export const decodeSql = (buf) => {
  if (buf.length >= 3 && buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) return buf.subarray(3).toString('utf8');
  if (buf.length >= 2 && buf[0] === 0xff && buf[1] === 0xfe) return buf.subarray(2).toString('utf16le');
  if (buf.length >= 2 && buf[0] === 0xfe && buf[1] === 0xff) return Buffer.from(buf.subarray(2)).swap16().toString('utf16le');
  if (buf.length >= 4 && buf[0] !== 0 && buf[1] === 0 && buf[3] === 0) return buf.toString('utf16le');
  if (buf.length >= 4 && buf[0] === 0 && buf[1] !== 0 && buf[2] === 0) return Buffer.from(buf).swap16().toString('utf16le');
  return buf.toString('utf8');
};

const IS_WORD = /[\w$]/;

// End index (exclusive) of the quoted token that starts at `i`.
const quotedEnd = (sql, i, dialect) => {
  const q = sql[i];
  const prev = sql[i - 1];
  if (q === '[') { // T-SQL identifier: ]] is a literal ]
    let j = i + 1;
    while (j < sql.length) {
      if (sql[j] === ']') { if (sql[j + 1] === ']') { j += 2; continue; } return j + 1; }
      j++;
    }
    return sql.length;
  }
  if (dialect === 'oracle' && q === "'" && /[qQ]/.test(prev ?? '') && !IS_WORD.test(sql[i - 2] ?? ' ') && sql[i + 1] && !/\s/.test(sql[i + 1])) {
    const close = { '[': ']', '(': ')', '{': '}', '<': '>' }[sql[i + 1]] ?? sql[i + 1]; // q'[...]' alternative quoting
    const end = sql.indexOf(`${close}'`, i + 2);
    return end === -1 ? sql.length : end + 2;
  }
  const backslash = dialect === 'mysql' && q !== '`'
    || (dialect === 'postgres' && q === "'" && /[eE]/.test(prev ?? '') && !IS_WORD.test(sql[i - 2] ?? ' '));
  let j = i + 1;
  while (j < sql.length) {
    if (backslash && sql[j] === '\\') { j += 2; continue; }
    if (sql[j] === q) {
      if (sql[j + 1] === q) { j += 2; continue; }
      return j + 1;
    }
    j++;
  }
  return sql.length;
};

const countLines = (s) => (s.match(/\n/g) || []).length;

// ── T-SQL, PL/SQL and Db2 reading helpers ────────────────────────────────────────────────────────

const ORACLE_BLOCK = /^(?:declare|begin)\b|^create\s+(?:or\s+replace\s+)?(?:(?:non)?editionable\s+)?(?:procedure|function|trigger|package|type|library)\b/i;
const MSSQL_BODY = /^(?:create|alter)\s+(?:or\s+alter\s+)?(?:proc(?:edure)?|function|trigger)\b/i;
// A DDL statement cannot start a line inside a PL/SQL block: the block was never closed with `/`.
const ORACLE_DDL_LINE = /^(?:alter\s+(?:table|index)|create\s+(?:or\s+replace\s+)?(?:unique\s+|bitmap\s+)?(?:table|index|sequence|view|synonym|procedure|function|package|trigger|type)|drop\s+(?:table|index|view|sequence)|truncate\s+table|comment\s+on|grant)\b/i;
const SQLPLUS_COMMAND = /^(?:set\s+(?:define|serveroutput|echo|feedback|verify|sqlblanklines|termout|timing|pagesize|linesize|heading|autocommit|sqlterminator|scan|escape|trimspool|long|numwidth|space)\b|prompt\b|whenever\b|spool\b|exit\b|quit\b|rem(?:ark)?\b|define\b|undefine\b|accept\b|connect\b|conn\b|show\b|column\b|break\b|clear\b|variable\b|store\b|@|start\s+\S)/i;
const SQLCMD_COMMAND = /^:(?:setvar|on\s+error|r|connect|ed|out|quit|exit|error|list|reset|help|serverlist|xml|perftrace|listvar)\b/i;
// Words that begin a T-SQL statement. A script without `;` is split where one of them starts a line.
const TSQL_START = new Set(['alter', 'create', 'drop', 'truncate', 'exec', 'execute', 'declare', 'insert', 'update', 'delete', 'merge', 'select', 'set', 'if', 'while', 'begin', 'commit', 'rollback', 'print', 'use', 'raiserror', 'throw', 'return', 'waitfor', 'grant', 'revoke', 'deny', 'backup', 'restore', 'dbcc', 'checkpoint', 'with']);
const CONTINUES = new Set(['union', 'intersect', 'except', 'as', 'else', 'then', 'when', 'and', 'or', 'not', 'in', 'is', 'from', 'join', 'by', 'exists', 'values', 'into']);
const firstWord = (s) => s.trimStart().match(/^[A-Za-z_]\w*/)?.[0].toLowerCase();
const lastWord = (s) => s.trimEnd().match(/([A-Za-z_]\w*)\W*$/)?.[1]?.toLowerCase();

const shouldSplitTsql = (w, after, buf) => {
  if (!TSQL_START.has(w)) return false;
  const first = firstWord(buf);
  const next = after.match(/^\s+([A-Za-z_]\w*)/)?.[1].toLowerCase();
  if (CONTINUES.has(lastWord(buf)) || /\bunion\s+all\s*$/i.test(buf)) return false;
  if (w === 'select') return !['insert', 'create', 'alter', 'merge', 'declare', 'with'].includes(first);
  if (w === 'set') return first === 'alter' ? !/^\s*\(/.test(after) : !['update', 'merge'].includes(first);
  if (w === 'insert' || w === 'update' || w === 'delete') return first !== 'merge';
  if (w === 'alter') return !(first === 'alter' && next === 'column');
  if (w === 'drop') return !(first === 'alter' && ['column', 'constraint', 'index'].includes(next));
  if (w === 'with') return /^\s+[A-Za-z_]\w*\s+as\b/i.test(after);
  return true;
};

// Index after the `)` that closes the `(` at s[open], or -1.
const balancedEnd = (s, open) => {
  let depth = 0;
  for (let i = open; i < s.length; i++) {
    const c = s[i];
    if (c === "'") { i++; while (i < s.length && !(s[i] === "'" && s[i + 1] !== "'")) i += s[i] === "'" ? 2 : 1; continue; }
    if (c === '(') depth++;
    else if (c === ')' && --depth === 0) return i + 1;
  }
  return -1;
};

// The guard of an idempotent script (`IF NOT EXISTS (...)`, `ELSE`, a block's `BEGIN`) is not the statement.
const unwrapTsql = (text) => {
  let s = text.trim();
  for (let n = 0; n < 6 && s; n++) {
    let m;
    if ((m = s.match(/^else\s+/i))) s = s.slice(m[0].length);
    else if ((m = s.match(/^begin\s+(?!tran(?:saction)?\b|try\b|catch\b|distributed\b)/i))) s = s.slice(m[0].length);
    else if ((m = s.match(/^if\s+(?:not\s+)?[a-z_]*\s*\(/i))) {
      const end = balancedEnd(s, m[0].length - 1);
      if (end === -1) break;
      s = s.slice(end).replace(/^\s*(?:is\s+(?:not\s+)?null|(?:=|<>|!=|<|>)\s*[\w@.']+)/i, '').trimStart();
    } else break;
  }
  return s;
};

// The SQL a statement runs through EXEC(N'...') or sp_executesql (EF Core idempotent scripts), or null.
const dynamicTsql = (text) => {
  const m = text.match(/^exec(?:ute)?\s*\(\s*N?'((?:[^']|'')*)'\s*\)\s*$/i)
    || text.match(/^exec(?:ute)?\s+(?:sys\.)?sp_executesql\s+(?:@stmt\s*=\s*)?N'((?:[^']|'')*)'\s*(?:,.*)?$/is);
  return m ? m[1].replaceAll("''", "'") : null;
};

// SQL inside `EXECUTE IMMEDIATE '...'` (or q'[...]') in a PL/SQL block.
const oracleInner = (text) => [
  ...[...text.matchAll(/\bexecute\s+immediate\s+'((?:[^']|'')*)'/gi)].map((m) => m[1].replaceAll("''", "'")),
  ...[...text.matchAll(/\bexecute\s+immediate\s+q'\[(.*?)\]'/gis)].map((m) => m[1]),
];

// Oracle and Db2 fold unquoted names to upper case and SQL Server compares names case-insensitively: for those
// dialects every name is compared in lower case, quoted or not. Set by the entry points that read one dialect.
let caseless = false;
export const foldNames = (dialect) => { caseless = dialect === 'oracle' || dialect === 'db2' || dialect === 'mssql'; };

// Splits SQL into the statements of the "up" part. Returns statements with their first line, the
// directive comments, the block comments, the down section (single-file formats) and runner markers.
export const parse = (sql, { dialect = 'postgres' } = {}) => {
  const statements = [];
  const directives = [];
  const comments = [];
  const markers = {
    goose: false, dbmate: false, sqlMigrate: false, noTransaction: false, rollback: false, liquibase: false,
    efcore: /__EFMigrationsHistory/.test(sql), sqlpackage: /\btmp_ms_xx_|^\s*:setvar\s+DatabaseName\b/im.test(sql),
    separators: new Set(), // batch separators the file uses: GO, /, terminator
  };
  let hasDownSection = false;
  let downSql = '';
  let upEnd = sql.length;
  let buf = '';
  let start = null;
  let line = 1;
  let i = 0;
  let lastEnd = 0;
  let rawBlock = false;
  let batch = 0;
  let terminator = ';';
  let parenDepth = 0;
  let blockDepth = 0;
  let caseDepth = 0;
  const mssql = dialect === 'mssql';
  const oracle = dialect === 'oracle';
  const nested = dialect === 'postgres' || mssql;
  foldNames(dialect);

  const addAll = (inner, extra) => { for (const s of parse(inner, { dialect }).statements) statements.push({ ...s, line: start, batch, ...extra }); };
  const push = (extra = {}) => {
    const raw = buf.trim();
    if (raw) {
      const text = mssql && !extra.command ? unwrapTsql(raw) : raw;
      const dynamic = mssql && text ? dynamicTsql(text) : null;
      if (dynamic !== null) addAll(dynamic, {});
      else if (text) {
        const plsql = oracle && !extra.command && ORACLE_BLOCK.test(text);
        statements.push({ text, line: start, batch, ...(plsql ? { plsql: true, slash: extra.slash === true } : {}), ...(extra.command ? { command: true } : {}) });
        if (plsql) for (const inner of oracleInner(text)) addAll(inner, { inner: true });
      }
      lastEnd = line;
    }
    buf = '';
    start = null;
    parenDepth = 0;
  };
  const stmtIndexForComment = () => (!buf.trim() && lastEnd === line ? statements.length - 1 : statements.length);
  const onlyBlanksBefore = (at) => {
    for (let j = at - 1; j >= 0 && sql[j] !== '\n'; j--) if (!/[ \t\r]/.test(sql[j])) return false;
    return true;
  };
  const inOpenBody = () => {
    if (rawBlock) return true;
    if (oracle) return ORACLE_BLOCK.test(buf.trimStart());
    if (mssql) return MSSQL_BODY.test(buf.trimStart());
    if (!/^\s*create\s+(?:or\s+replace\s+)?(?:temp(?:orary)?\s+)?trigger\b/i.test(buf)) return false;
    const bare = buf.replace(/'(?:[^']|'')*'/g, "''");
    const opens = (bare.match(/\b(?:begin|case)\b/gi) || []).length;
    const closes = (bare.match(/\bend\b/gi) || []).length;
    return opens > closes;
  };

  while (i < sql.length) {
    const ch = sql[i];
    const two = sql.slice(i, i + 2);
    if ((mssql || oracle || dialect === 'db2') && /\S/.test(ch) && onlyBlanksBefore(i)) {
      const eol = sql.indexOf('\n', i);
      const rest = sql.slice(i, eol === -1 ? sql.length : eol).trimEnd();
      const skip = () => { i = eol === -1 ? sql.length : eol; };
      if (mssql && /^go(?:\s+\d+)?\s*(?:--.*)?$/i.test(rest)) { markers.separators.add('GO'); push(); batch++; blockDepth = 0; caseDepth = 0; skip(); continue; }
      if (oracle && rest === '/') { markers.separators.add('/'); push({ slash: true }); batch++; rawBlock = false; skip(); continue; }
      if (mssql && SQLCMD_COMMAND.test(rest)) { push(); buf = rest; start = line; push({ command: true }); skip(); continue; }
      if (oracle && !buf.trim() && SQLPLUS_COMMAND.test(rest)) { buf = rest; start = line; push({ command: true }); skip(); continue; }
      if (oracle && buf.trim() && ORACLE_BLOCK.test(buf.trimStart()) && ORACLE_DDL_LINE.test(rest)) push({ slash: false });
    }
    if (two === '--' || (dialect === 'mysql' && ch === '#')) {
      const end = sql.indexOf('\n', i);
      const comment = sql.slice(i, end === -1 ? sql.length : end);
      const body = comment.replace(/^(--|#)\s*/, '').trimEnd();
      if (dialect === 'db2') {
        const term = body.match(/^#\s*SET\s+TERMINATOR\s+(\S+)/i);
        if (term) { push(); terminator = term[1]; markers.separators.add('terminator'); }
      }
      // Liquibase formatted SQL: `--changeset a:1 endDelimiter:// runInTransaction:false`
      const changeset = body.match(/^changeset\b(.*)$/i);
      if (changeset) {
        if (/\brunInTransaction:false\b/i.test(changeset[1])) markers.noTransaction = true;
        const delimiter = changeset[1].match(/\bendDelimiter:(\S+)/i)?.[1];
        if (delimiter && !['/', ';', '\\n/', 'GO', '\\nGO'].includes(delimiter) && terminator === ';') { terminator = delimiter; markers.separators.add('terminator'); }
      }
      if (DOWN_MARKER.test(comment)) {
        hasDownSection = true;
        upEnd = i;
        downSql = end === -1 ? '' : sql.slice(end + 1);
        push();
        break;
      }
      if (/^\+goose\s+no\s+transaction\b/i.test(body) || /^\+migrate\s+up\b.*\bnotransaction\b/i.test(body)
        || /^migrate:up\b.*\btransaction:false\b/i.test(body) || /^atlas:txmode\s+none\b/i.test(body)) markers.noTransaction = true;
      if (/^rollback\b/i.test(body)) markers.rollback = true;
      if (/^liquibase formatted sql\b/i.test(body)) markers.liquibase = true;
      if (/^\+goose\b/i.test(body)) markers.goose = true;
      if (/^migrate:(up|down)\b/i.test(body)) markers.dbmate = true;
      if (/^\+migrate\b/i.test(body)) markers.sqlMigrate = true;
      if (/^\+goose\s+statementbegin\b/i.test(body)) rawBlock = true;
      if (/^\+goose\s+statementend\b/i.test(body)) { rawBlock = false; push(); }
      const d = body.match(DIRECTIVE_AT_START);
      const statement = stmtIndexForComment();
      if (d) {
        const rest = d[2].trim();
        const cut = rest.search(/(^|\s)--(\s|$)/);
        directives.push({
          kind: d[1].toLowerCase(), arg: (cut === -1 ? rest : rest.slice(0, cut)).trim(),
          reason: cut === -1 ? '' : rest.slice(cut).replace(/^\s*--\s*/, '').trim(), line, statement,
        });
      } else if (/migration-lint:/i.test(body)) {
        directives.push({ kind: 'misplaced', arg: body, reason: '', line, statement });
      }
      i = end === -1 ? sql.length : end;
      continue;
    }
    if (two === '/*') {
      let depth = 1;
      let j = i + 2;
      while (j < sql.length && depth > 0) {
        if (nested && sql.startsWith('/*', j)) { depth++; j += 2; }
        else if (sql.startsWith('*/', j)) { depth--; j += 2; }
        else j++;
      }
      const body = sql.slice(i, j);
      comments.push({ text: body, line, statement: stmtIndexForComment() });
      line += countLines(body);
      buf += ' ';
      i = j;
      continue;
    }
    if (ch === "'" || ch === '"' || ch === '`' || (ch === '[' && mssql)) {
      const j = quotedEnd(sql, i, dialect);
      const lit = sql.slice(i, j);
      if (start === null) start = line;
      line += countLines(lit);
      buf += lit;
      i = j;
      continue;
    }
    if (ch === '$' && !IS_WORD.test(sql[i - 1] ?? ' ')) {
      const dollar = sql.slice(i).match(/^\$([A-Za-z_]\w*)?\$/);
      if (dollar) {
        const tag = dollar[0];
        const end = sql.indexOf(tag, i + tag.length);
        const lit = sql.slice(i, end === -1 ? sql.length : end + tag.length);
        if (start === null) start = line;
        line += countLines(lit);
        buf += lit;
        i += lit.length;
        continue;
      }
    }
    if (terminator !== ';' && sql.startsWith(terminator, i)) { push(); i += terminator.length; continue; }
    if (ch === ';' && terminator === ';') {
      if (inOpenBody()) { buf += ch; i++; continue; }
      push();
      i++;
      continue;
    }
    if (mssql && /[A-Za-z_]/.test(ch) && !IS_WORD.test(sql[i - 1] ?? ' ')) {
      const word = sql.slice(i).match(/^[A-Za-z_][\w$]*/)[0];
      const w = word.toLowerCase();
      const after = sql.slice(i + word.length, i + word.length + 80);
      if (buf.trim() && parenDepth === 0 && blockDepth === 0 && onlyBlanksBefore(i) && !inOpenBody() && shouldSplitTsql(w, after, buf)) push();
      if (w === 'begin' && !/^\s+(?:tran(?:saction)?|distributed)\b/i.test(after)) blockDepth++;
      else if (w === 'case') caseDepth++;
      else if (w === 'end') { if (caseDepth > 0) caseDepth--; else if (blockDepth > 0) blockDepth--; }
      if (start === null) start = line;
      buf += word;
      i += word.length;
      continue;
    }
    if (ch === '(') parenDepth++;
    else if (ch === ')' && parenDepth > 0) parenDepth--;
    if (ch === '\n') line++;
    if (start === null && /\S/.test(ch)) start = line;
    buf += ch;
    i++;
  }
  push();
  return { statements, directives, comments, hasDownSection, downSql, upSql: sql.slice(0, upEnd), markers };
};

// Text of the sections of a single-file migration (goose, dbmate, sql-migrate); whole text when it has no marker.
export const upPart = (sql) => parse(sql).upSql;
export const downPart = (sql) => { const p = parse(sql); return p.hasDownSection ? p.downSql : null; };

// ── Small SQL text helpers ───────────────────────────────────────────────────────────────────────

export const ident = String.raw`(?:"[^"]+"|\`[^\`]+\`|\[[^\]]+\]|[\w$]+)(?:\.(?:"[^"]+"|\`[^\`]+\`|\[[^\]]+\]|[\w$]+))*`;
// Last part of a possibly qualified identifier: unquoted names are case-folded, quoted ones keep their case.
export const name = (raw) => {
  const last = (raw ?? '').trim().match(/("[^"]+"|`[^`]+`|\[[^\]]+\]|[\w$]+)$/)?.[1] ?? '';
  return /^["`[]/.test(last) && !caseless ? last.slice(1, -1) : (/^["`[]/.test(last) ? last.slice(1, -1) : last).toLowerCase();
};
export const flat = (s) => s.replace(/\s+/g, ' ');
export const stripLiterals = (s) => s.replace(/'(?:[^'\\]|\\.|'')*'/g, "''").replace(/\$([A-Za-z_]\w*)?\$.*?\$\1\$/gs, "''");

// Splits on `sep` outside parentheses, quotes and dollar quotes.
export const splitTopLevel = (text, sep = ',') => {
  const parts = [];
  let depth = 0;
  let from = 0;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === "'" || ch === '"' || ch === '`') {
      const escapes = ch === "'" && /[eE]/.test(text[i - 1] ?? '') && !IS_WORD.test(text[i - 2] ?? ' ');
      let j = i + 1;
      while (j < text.length && !(text[j] === ch && text[j + 1] !== ch)) {
        if (escapes && text[j] === '\\') j += 2;
        else j += text[j] === ch ? 2 : 1;
      }
      i = j;
    } else if (ch === '(' || ch === '[') depth++;
    else if (ch === ')' || ch === ']') depth--;
    else if (ch === sep && depth === 0) { parts.push(text.slice(from, i).trim()); from = i + 1; }
  }
  parts.push(text.slice(from).trim());
  return parts.filter(Boolean);
};
