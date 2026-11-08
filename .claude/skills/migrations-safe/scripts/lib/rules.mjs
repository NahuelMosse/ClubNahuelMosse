// The rule registry and the per-file rules. Every rule id that can be emitted is listed in RULES; the
// table in references/rules.md is checked against it by the test suite.
import { DIALECTS, profileOf, resolveDialect, wrapsFile, wrapsFor } from './runners.mjs';
import { flat, ident, name, parse, splitTopLevel, stripLiterals } from './parse.mjs';
import { applySchema, cloneSchema, insertTargets, parseAlter } from './schema.mjs';
import { DEFAULT_MYSQL_VERSION, INDEX_STATEMENT, enumOf, learnStatement, parseMysqlVersion } from './mysql.mjs';
import { GOT, mysqlAlterRules as mysqlRules } from './mysql-rules.mjs';
import { DEFAULT_EDITION, DEFAULT_SERVER_VERSION, parseServerVersion } from './server-version.mjs';
import { learnTsql, normalizeTsqlActions, spRename } from './mssql.mjs';
import { DROP_COLUMN_NOTE, mssqlAlterRules, mssqlIndexRules } from './mssql-rules.mjs';
import { COMMITS, DDL_LOCK_TIMEOUT, isDdl, isDml } from './oracle.mjs';
import { oracleAlterRules, oracleStatementRules } from './oracle-rules.mjs';
import { COMMIT, INPLACE, LOCK_TIMEOUT as DB2_LOCK_TIMEOUT, REORG_STATEMENT, REORG_UNIT_LIMIT } from './db2.mjs';
import { db2AlterRules } from './db2-rules.mjs';

export const ERROR = 'error';
export const WARN = 'warning';

export const RULES = [
  { id: 'drop-table', level: ERROR, area: 'data loss' },
  { id: 'drop-column', level: ERROR, area: 'data loss' },
  { id: 'drop-schema-cascade', level: ERROR, area: 'data loss' },
  { id: 'drop-materialized-view', level: ERROR, area: 'data loss' },
  { id: 'truncate', level: ERROR, area: 'data loss' },
  { id: 'delete-all', level: ERROR, area: 'data loss' },
  { id: 'update-all', level: ERROR, area: 'data loss' },
  { id: 'rebuild-drops-column', level: ERROR, area: 'data loss' },
  { id: 'prisma-data-loss-warning', level: ERROR, area: 'data loss' },
  { id: 'rename-column', level: ERROR, area: 'running code' },
  { id: 'rename-table', level: ERROR, area: 'running code' },
  { id: 'change-column-type', level: ERROR, area: 'running code' },
  { id: 'not-null-without-default', level: ERROR, area: 'running code' },
  { id: 'set-not-null', level: ERROR, area: 'lock' },
  { id: 'constraint-without-not-valid', level: ERROR, area: 'lock' },
  { id: 'constraint-builds-index', level: ERROR, area: 'lock' },
  { id: 'primary-key-using-index', level: ERROR, area: 'lock' },
  { id: 'index-without-concurrently', level: ERROR, area: 'lock' },
  { id: 'drop-index-without-concurrently', level: ERROR, area: 'lock' },
  { id: 'volatile-default', level: ERROR, area: 'lock' },
  { id: 'rewriting-column', level: ERROR, area: 'lock' },
  { id: 'mysql-no-algorithm', level: WARN, area: 'lock' },
  { id: 'mysql-algorithm-unsupported', level: ERROR, area: 'lock' },
  { id: 'mysql-lock-wait-timeout', level: WARN, area: 'lock' },
  { id: 'mysql-add-foreign-key', level: ERROR, area: 'lock' },
  { id: 'mysql-fk-implicit-index', level: WARN, area: 'lock' },
  { id: 'mysql-fulltext-spatial-index', level: ERROR, area: 'lock' },
  { id: 'mysql-drop-primary-key', level: ERROR, area: 'lock' },
  { id: 'mysql-add-primary-key', level: WARN, area: 'lock' },
  { id: 'mysql-charset-conversion', level: ERROR, area: 'lock' },
  { id: 'mysql-enum-change', level: ERROR, area: 'lock' },
  { id: 'mysql-table-rebuild', level: WARN, area: 'lock' },
  { id: 'mysql-column-position', level: WARN, area: 'lock' },
  { id: 'mysql-instant-row-versions', level: WARN, area: 'lock' },
  { id: 'mysql-change-column-rename', level: WARN, area: 'running code' },
  { id: 'mssql-add-not-null-default', level: ERROR, area: 'lock' },
  { id: 'mssql-alter-column', level: ERROR, area: 'lock' },
  { id: 'mssql-index-offline', level: ERROR, area: 'lock' },
  { id: 'mssql-online-unsupported-edition', level: ERROR, area: 'lock' },
  { id: 'mssql-lock-timeout', level: WARN, area: 'lock' },
  { id: 'mssql-constraint-with-check', level: ERROR, area: 'lock' },
  { id: 'mssql-constraint-nocheck', level: WARN, area: 'lock' },
  { id: 'oracle-add-column-default', level: ERROR, area: 'lock' },
  { id: 'oracle-ddl-lock-timeout', level: WARN, area: 'lock' },
  { id: 'oracle-ddl-commits-dml', level: WARN, area: 'transaction' },
  { id: 'oracle-index-not-online', level: ERROR, area: 'lock' },
  { id: 'oracle-online-unsupported-edition', level: ERROR, area: 'lock' },
  { id: 'oracle-constraint-validate', level: ERROR, area: 'lock' },
  { id: 'oracle-drop-column-rewrites', level: WARN, area: 'lock' },
  { id: 'oracle-missing-slash', level: ERROR, area: 'tool' },
  { id: 'db2-reorg-pending', level: ERROR, area: 'lock' },
  { id: 'db2-reorg-offline', level: WARN, area: 'lock' },
  { id: 'db2-reorg-limit', level: ERROR, area: 'lock' },
  { id: 'db2-constraint-check', level: ERROR, area: 'lock' },
  { id: 'db2-lock-timeout', level: WARN, area: 'lock' },
  { id: 'missing-lock-timeout', level: WARN, area: 'lock' },
  { id: 'concurrently-in-transaction', level: ERROR, area: 'transaction' },
  { id: 'transaction-conflict', level: WARN, area: 'transaction' },
  { id: 'not-atomic', level: WARN, area: 'transaction' },
  { id: 'missing-down', level: WARN, area: 'rollback' },
  { id: 'applied-migration-changed', level: ERROR, area: 'history' },
  { id: 'out-of-order', level: ERROR, area: 'history' },
  { id: 'duplicate-sequence', level: ERROR, area: 'history' },
  { id: 'unsupported-separator', level: WARN, area: 'transaction' },
  { id: 'invalid-directive', level: WARN, area: 'tool' },
  { id: 'unlinted-migration', level: WARN, area: 'tool' },
];
export const RULE_IDS = new Set(RULES.map((r) => r.id));
export const ruleLevel = (id) => RULES.find((r) => r.id === id).level;

const VOLATILE_FN = /\b(?:random|setseed|gen_random_uuid|uuid_generate_v\w+|clock_timestamp|timeofday|nextval|txid_current)\s*\(/i;
const DEFAULT_END = /\b(?:not null|null|check|references|unique|primary key|constraint|collate|generated|on update)\b/i;
const NON_COLUMN_ADD = /^(?:constraint|index|key|unique|primary|foreign|check|fulltext|spatial|partition)\b/i;
const NOT_COLUMN_DROP = /^drop (?:constraint|index|key|default|not null|primary|foreign|check|partition|expression|identity)\b/i;
const NON_DDL = /^(?:begin|start transaction|commit|rollback|alter\s+session\b|call\b|reorg\b|runstats\b|connect\b|terminate\b|end\b|if\b|else\b|use\b|print\b|declare\b|:\w|@|prompt\b|whenever\b|spool\b|exit\b|quit\b|rem\b|define\b|set\b|pragma\b|select\b)/i;
const TX_START =/^(?:begin|start transaction)\b/i;
const LOCK_TIMEOUT = /^(?:set\s+(?:session\s+|local\s+)?lock_timeout\b|select\s+set_config\s*\(\s*'lock_timeout')/i;
const MYSQL_LOCK_WAIT = /^(?:set\s+(?:session\s+|local\s+|@@session\.|@@local\.|@@)?lock_wait_timeout\s*=|set\s+statement\b.*\block_wait_timeout\s*=)/i;
const FK_CHECKS = /^set\s+(?:session\s+|@@session\.|@@)?foreign_key_checks\s*=\s*(0|1|on|off|true|false)\b/i;
const TABLE_ALL = String.raw`(?:only )?(${ident})`;

const unbounded = (bare, { nullChecks }) => {
  const where = bare.match(/\bwhere\b(.*)$/i)?.[1]?.trim();
  if (where === undefined) return true;
  if (/^\(?\s*(?:true|1\s*=\s*1)\s*\)?$/i.test(where)) return true;
  return nullChecks && /^\(?\s*[\w".]+\s+is\s+(?:not\s+)?null\s*\)?$/i.test(where);
};

const sourceTables = (texts) => {
  const copiedFrom = new Map();
  const renamedTo = new Map();
  for (const t of texts) {
    const ins = t.match(new RegExp(String.raw`^insert into (${ident})[^;]*?\bselect\b[^;]*?\bfrom (${ident})`, 'i'));
    if (ins) copiedFrom.set(name(ins[2]), name(ins[1]));
    const ren = t.match(new RegExp(String.raw`^alter table (${ident}) rename to (${ident})`, 'i'));
    if (ren) renamedTo.set(name(ren[1]), name(ren[2]));
    const sp = spRename(t);
    if (sp?.kind === 'object') renamedTo.set(sp.table, name(sp.to));
  }
  return { copiedFrom, renamedTo };
};

// Text taken from a file and shown in a message is cut short: say what is wrong, not what the file holds.
const clip = (text) => (text.length > 40 ? `${text.slice(0, 40)}...` : text);

const parseDirectives = (directives, add) => {
  const allowFile = new Set();
  const allowAt = [];
  let irreversible = null;
  const bad = (d, msg) => add(null, 'invalid-directive', msg, { line: d.line });
  for (const d of directives) {
    if (d.kind === 'misplaced') { bad(d, 'migration-lint directive must be a comment of its own that starts with `migration-lint:`; this one is ignored'); continue; }
    if (d.kind === 'dialect') { if (!DIALECTS.includes(d.arg.split(/\s/)[0]?.toLowerCase())) bad(d, `unknown dialect "${clip(d.arg)}"`); continue; }
    if (d.kind === 'irreversible') {
      if (d.reason.length < 3) bad(d, 'irreversible needs a recovery plan: `-- migration-lint: irreversible -- <plan>`');
      else irreversible = d;
      continue;
    }
    if (d.kind !== 'allow' && d.kind !== 'allow-file') { bad(d, `unknown directive "${clip(d.kind)}"`); continue; }
    const rules = d.arg.split(/[\s,]+/).filter(Boolean);
    const unknown = rules.filter((r) => !RULE_IDS.has(r));
    if (!rules.length) { bad(d, `${d.kind} names no rule`); continue; }
    if (unknown.length) { bad(d, `${d.kind} names unknown rule(s) ${clip(unknown.join(', '))}; nothing is silenced`); continue; }
    if (d.reason.length < 3) { bad(d, `${d.kind} ${rules.join(', ')} has no reason: \`-- migration-lint: ${d.kind} ${rules[0]} -- <who, when, why>\`; nothing is silenced`); continue; }
    if (d.kind === 'allow-file') rules.forEach((r) => allowFile.add(r));
    else allowAt.push({ statement: d.statement, rules });
  }
  return { allowFile, allowAt, irreversible };
};

// Lints the up part of one migration. ctx: { dialect, projectDialect, profile, schema, createdBefore }.
export const lintSql = (sql, ctx = {}) => {
  const dialect = resolveDialect(sql, ctx);
  const pg = dialect === 'postgres';
  const my = dialect === 'mysql';
  const ms = dialect === 'mssql';
  const ora = dialect === 'oracle';
  const db2 = dialect === 'db2';
  // REORG-recommended units of work per table since its last REORG, kept across the files of one run
  const reorgUnits = ctx.reorgUnits ?? new Map();
  const pendingReorg = new Map();
  const countedUnit = new Map();
  let unit = 0;
  const serverVersion = ctx.serverVersion ?? parseServerVersion(dialect, DEFAULT_SERVER_VERSION[dialect]);
  const edition = ctx.edition ?? DEFAULT_EDITION[dialect];
  const mysqlVersion = ctx.mysqlVersion ?? parseMysqlVersion(DEFAULT_MYSQL_VERSION);
  // State that outlives one file: instant row versions, ENUM definitions and indexed columns per table.
  const instantVersions = ctx.instantVersions ?? new Map();
  const enums = ctx.enums ?? new Map();
  const indexed = ctx.indexed ?? new Map();
  const defs = ctx.defs ?? new Map();
  // SQL Server column definitions per `table.column`, kept across the files of one run
  const tsql = ctx.tsql ?? new Map();
  const maps = { enums, indexed, defs, instantVersions };
  let fkChecksOff = false;
  const profile = ctx.profile ?? profileOf('raw');
  const parsed = parse(sql, { dialect });
  const { statements, hasDownSection, markers } = parsed;
  const findings = [];
  const texts = statements.map((s) => flat(s.text));
  const bare = texts.map(stripLiterals);
  const created = new Set(ctx.createdBefore ?? []);
  const createdHere = new Set();
  const tables = cloneSchema(ctx.schema ?? new Map());
  // Flyway runs a script outside a transaction when every statement in it cannot run inside one.
  const flywayAutoCommit = profile.id === 'flyway' && texts.length > 0
    && texts.filter((t) => !NON_DDL.test(t)).every((t) => /\bconcurrently\b/i.test(t));
  const noTransaction = markers.noTransaction || ctx.noTransaction === true || flywayAutoCommit;
  // SQL a runner generated (stdin) shows its own transaction: BEGIN/COMMIT present means wrapped.
  const generated = ctx.generated === true && profile.generatesSql;
  const wrapped = !generated && wrapsFile(profile, { noTransaction, statements: statements.length, dialect });
  const explicitWrap = !generated && wrapsFor(profile, dialect) === true && !noTransaction;
  // in Oracle BEGIN opens a PL/SQL block, never a transaction (there is no BEGIN TRANSACTION)
  const explicitTx = !ora && texts.some((t) => TX_START.test(t));

  let directiveState;
  const add = (k, rule, message, extra = {}) => {
    const line = extra.line ?? statements[k]?.line ?? 1;
    if (rule !== 'invalid-directive' && directiveState) {
      if (directiveState.allowFile.has(rule) || directiveState.allowAt.some((a) => a.statement === k && a.rules.includes(rule))) return;
    }
    findings.push({ level: extra.level ?? ruleLevel(rule), rule, line, message });
  };
  directiveState = { allowFile: new Set(), allowAt: [], irreversible: null };
  directiveState = parseDirectives(parsed.directives, add);

  const { copiedFrom, renamedTo } = sourceTables(texts);
  const rebuilt = (table) => copiedFrom.has(table) && renamedTo.get(copiedFrom.get(table)) === table;
  const isExisting = (table) => table !== null && !created.has(table);
  const validated = new Set();
  const notNullSeen = new Set();

  // Prisma writes what its generated SQL loses in a comment at the top of the file.
  for (const c of parsed.comments) {
    if (!/\bWarnings:/.test(c.text)) continue;
    const bullets = c.text.replace(/\*\/\s*$/, '').split(/\n\s*-\s+/).slice(1).map((b) => flat(b).trim());
    bullets.forEach((b) => add(c.statement, 'prisma-data-loss-warning', `Prisma warns: ${b}`, {
      line: c.line, level: /about to drop|will be lost|cannot be cast|data in|dropped/i.test(b) ? ERROR : WARN,
    }));
  }

  const mysqlAlterRules = (k, table, actions) => mysqlRules({
    add: (rule, message, extra) => add(k, rule, message, extra), table, actions, version: mysqlVersion, fkChecksOff,
    state: { enums, indexed, defs, instantVersions },
  });

  const alterRules = (k, table, rawActions, text) => {
    const existing = isExisting(table);
    const actions = ms ? normalizeTsqlActions(rawActions) : rawActions;
    if (my && existing) mysqlAlterRules(k, table, actions);
    if (db2 && existing) {
      const ops = db2AlterRules({ add: (rule, message, extra) => add(k, rule, message, extra), table, actions });
      if (ops.length) {
        if (!pendingReorg.has(table)) pendingReorg.set(table, { k, op: ops[0] });
        if (countedUnit.get(table) !== unit) {
          countedUnit.set(table, unit);
          const n = (reorgUnits.get(table) ?? 0) + 1;
          reorgUnits.set(table, n);
          if (n > REORG_UNIT_LIMIT)
            add(k, 'db2-reorg-limit', `this is the ${n}th unit of work with a REORG-recommended operation (${ops[0]}) on ${table} since its last REORG TABLE: Db2 allows ${REORG_UNIT_LIMIT} and then fails with SQLSTATE 55019 until a classic offline REORG TABLE has run — put CALL SYSPROC.ADMIN_CMD('REORG TABLE ${table}') between the groups, or group the operations into one unit of work (they count once)`);
        }
      }
    }
    if (ora && existing) oracleAlterRules({ add: (rule, message, extra) => add(k, rule, message, extra), table, actions, version: serverVersion, text, edition });
    if (ms && existing) mssqlAlterRules({ add: (rule, message, extra) => add(k, rule, message, extra), table, actions, version: serverVersion, edition, defs: tsql });
    if (dialect === 'mysql' && !/\balgorithm\s*=/i.test(text))
      add(k, 'mysql-no-algorithm', `ALTER TABLE ${table} without ALGORITHM/LOCK may copy the table under lock: declare ALGORITHM=INSTANT (alone, it takes no LOCK clause) or ALGORITHM=INPLACE, LOCK=NONE so it fails instead; for a COPY on a big table use gh-ost`);
    for (const a of actions) {
      let m;
      if (/^drop column\b/i.test(a) || (/^drop\s+\S/i.test(a) && !NOT_COLUMN_DROP.test(a)))
        add(k, 'drop-column', `drops a column of ${table}: the running code still selects or inserts it — contract step only, after a release that stopped using it, with a backup and a recorded approval${ms ? DROP_COLUMN_NOTE : ''}`);
      const renamesColumn = a.match(/^rename (?:column )?(?!to\b|constraint\b|as\b|index\b|key\b)\S+ to \S+/i)
        || (dialect === 'mysql' && (m = a.match(/^change (?:column )?(\S+) (\S+)/i)) && name(m[1]) !== name(m[2]));
      if (renamesColumn)
        add(k, 'rename-column', `renames a column of ${table} in one step: the code in production still uses the old name — expand (add new, write both, backfill), switch reads, contract later`);
      if (existing && (/^rename (?:to|as)\b/i.test(a) || /^set schema\b/i.test(a)) && !rebuilt(renamedTo.get(table)))
        add(k, 'rename-table', `${/^set schema/i.test(a) ? 'moves' : 'renames'} table ${table} in one step: create the new one (or a view with the old name) and move readers first`);
      if (/^alter (?:column )?\S+ (?:set data )?type\b/i.test(a) || (dialect === 'mysql' && /^(?:modify|change) (?:column )?\w/i.test(a) && !enumOf(a)))
        add(k, 'change-column-type', `changes a column type of ${table}: can rewrite the table under an exclusive lock and break readers — new column, backfill, switch, drop later (widening varchar(n) or varchar→text is the safe exception: allow it with a reason)`);

      const addMatch = a.match(/^add (?:column )?(?:if not exists )?(.*)$/is);
      if (addMatch && !NON_COLUMN_ADD.test(addMatch[1])) {
        const defs = addMatch[1].startsWith('(') ? splitTopLevel(addMatch[1].replace(/^\(|\)$/g, '')) : [addMatch[1]];
        for (const def of defs) columnDefRules(k, table, existing, def);
      }
      if (pg && existing && /^alter (?:column )?\S+ set not null\b/i.test(a)) {
        const cheap = validated.has(table) || [...texts].some((t) => new RegExp(String.raw`^alter table .*\b${table}\b.*drop constraint \S*not_?null`, 'i').test(t));
        if (!cheap) add(k, 'set-not-null', `SET NOT NULL scans ${table} under ACCESS EXCLUSIVE: first ADD CONSTRAINT … CHECK (col IS NOT NULL) NOT VALID, VALIDATE it in a later migration, then SET NOT NULL (PG 12+ skips the scan when the validated check exists; allow this finding with that reason)`);
      }
      if (/set not null\b|is not null\b/i.test(a)) notNullSeen.add(table);
      if (/^validate constraint\b/i.test(a)) validated.add(table);
      if (pg && existing && /^add (?:constraint \S+ )?(foreign key|check)\b/i.test(a) && !/\bnot valid\b/i.test(a))
        add(k, 'constraint-without-not-valid', `adds a ${/foreign/i.test(a) ? 'FOREIGN KEY' : 'CHECK'} to ${table} validating every row under lock: add it NOT VALID, then VALIDATE CONSTRAINT in a separate migration`);
      if (pg && existing && /^add (?:constraint \S+ )?(unique|primary key)\b/i.test(a)) {
        if (!/\busing index\b/i.test(a))
          add(k, 'constraint-builds-index', `adds a UNIQUE/PRIMARY KEY to ${table}, building its index under ACCESS EXCLUSIVE: CREATE UNIQUE INDEX CONCURRENTLY, then ADD CONSTRAINT … USING INDEX (and existing duplicates make it fail — check first)`);
        else if (/primary key/i.test(a) && !notNullSeen.has(table))
          add(k, 'primary-key-using-index', `ADD PRIMARY KEY … USING INDEX makes its columns NOT NULL, scanning ${table} under ACCESS EXCLUSIVE unless they are already NOT NULL (or have a validated IS NOT NULL check): do that first, or allow this finding saying so`);
      }
    }
  };

  const columnDefRules = (k, table, existing, def) => {
    if (!existing) return;
    const hasDefault = /\bdefault\b/i.test(stripLiterals(def));
    const generated = /\b(?:generated|identity|serial|bigserial|smallserial|autoincrement|auto_increment)\b/i.test(def);
    if (/\bnot null\b/i.test(def) && !hasDefault && !generated)
      add(k, 'not-null-without-default', `adds a NOT NULL column with no DEFAULT to ${table}: fails on a populated table, and old code that inserts without it breaks — add it nullable (or with a constant default), backfill, then enforce`);
    if (pg && hasDefault) {
      const expr = stripLiterals(def.split(/\bdefault\b/i)[1] ?? '').split(DEFAULT_END)[0];
      if (VOLATILE_FN.test(expr))
        add(k, 'volatile-default', `adds a column to ${table} with a volatile default: rewrites the whole table under ACCESS EXCLUSIVE (now() and CURRENT_TIMESTAMP do not, since PG 11) — add without default, set the default apart, backfill in batches`);
    }
    if (pg && /\b(?:serial|bigserial|smallserial|generated always as \(.*\) stored|generated (?:always|by default) as identity)\b/i.test(def))
      add(k, 'rewriting-column', `adds a serial, identity or stored generated column to ${table}: rewrites the table under ACCESS EXCLUSIVE`);
  };

  let firstLock = -1;
  let lockTimeoutAt = -1;
  let pendingDml = -1;
  let reportedTx = false;
  let reportedPragma = false;
  texts.forEach((t, k) => {
    const b = bare[k];
    if (db2 && k > 0 && (!wrapped || COMMIT.test(texts[k - 1]))) unit++;
    if (ora && !statements[k].command) {
      if (pendingDml !== -1 && isDdl(t))
        add(k, 'oracle-ddl-commits-dml', `a DDL statement commits the transaction: the DML at line ${statements[pendingDml].line} (and everything since the last COMMIT) is committed here, so a failure afterwards does not roll it back — COMMIT it on purpose before the DDL, or move the data change to its own migration`);
      if (isDml(t) && !statements[k].inner) { if (pendingDml === -1) pendingDml = k; }
      else if (isDdl(t) || COMMITS.test(t)) pendingDml = -1;
    }
    const fkSwitch = t.match(FK_CHECKS);
    if (fkSwitch) fkChecksOff = /^(?:0|off|false)$/i.test(fkSwitch[1]);
    const create = t.match(new RegExp(String.raw`^create (?:temp(?:orary)? |unlogged )?table (?:if not exists )?(${ident})`, 'i'));
    if (create) {
      created.add(name(create[1])); createdHere.add(name(create[1])); applySchema(tables, t);
      if (ms) learnTsql(t, tsql);
      if (my) learnStatement(t, maps, mysqlVersion);
      return;
    }

    const alter = parseAlter(t);
    if (alter) {
      alterRules(k, alter.table, alter.actions, t);
      if (isExisting(alter.table) && firstLock === -1) firstLock = k;
      if (alter.wait && lockTimeoutAt === -1) lockTimeoutAt = k;
      if (my && !isExisting(alter.table)) learnStatement(t, maps, mysqlVersion);
      if (ms) learnTsql(t, tsql);
    }
    if (ms) {
      if (mssqlIndexRules({ add: (rule, message, extra) => add(k, rule, message, extra), text: t, isExisting, edition }) && firstLock === -1) firstLock = k;
      if (/\bwait_at_low_priority\b/i.test(t) && lockTimeoutAt === -1) lockTimeoutAt = k;
      const sp = spRename(t);
      if (sp?.kind === 'column' && isExisting(sp.table))
        add(k, 'rename-column', `renames a column of ${sp.table} in one step (sp_rename): the code in production still uses the old name — expand (add new, write both, backfill), switch reads, contract later`);
      if (sp?.kind === 'object' && !created.has(sp.table) && !rebuilt(name(sp.to)))
        add(k, 'rename-table', `renames table ${sp.table} in one step (sp_rename): create the new one (or a view with the old name) and move readers first`);
      if (sp && firstLock === -1 && isExisting(sp.table)) firstLock = k;
    }
    if (db2) {
      const reorg = t.match(REORG_STATEMENT);
      if (reorg) {
        const table = name(reorg[1]);
        pendingReorg.delete(table);
        reorgUnits.set(table, 0);
        if (isExisting(table) && firstLock === -1) firstLock = k;
        if (!INPLACE.test(t))
          add(k, 'db2-reorg-offline', `a classic REORG TABLE rewrites ${table} and blocks writers for as long as it takes (the table is read-only at best): run it in a window, and size the window from a rehearsal on a copy of production data`, { level: WARN });
      }
    }
    if (ora) {
      const stmt = statements[k];
      if (stmt.plsql && stmt.slash === false)
        add(k, 'oracle-missing-slash', 'a PL/SQL block (or CREATE PROCEDURE/FUNCTION/TRIGGER/PACKAGE/TYPE) must end with a `/` on a line of its own: without it SQL*Plus and Flyway keep reading, and the statements that follow become part of the block');
      if (oracleStatementRules({ add: (rule, message, extra) => add(k, rule, message, extra), text: t, isExisting, edition }) && firstLock === -1) firstLock = k;
    }
    if (my) {
      const optimize = t.match(new RegExp(String.raw`^optimize (?:(?:no_write_to_binlog|local) )?table (.*)$`, 'i'));
      for (const raw of optimize ? splitTopLevel(optimize[1]) : []) {
        const table = name(raw);
        if (!isExisting(table)) continue;
        instantVersions.set(table, 0);
        if (firstLock === -1) firstLock = k;
        add(k, 'mysql-table-rebuild', `OPTIMIZE TABLE rebuilds ${table} (online for InnoDB, but it copies every page, doubles disk use, replays serially on replicas and waits for metadata locks at both ends); it takes no ALGORITHM or LOCK clause — run it off-peak under SET SESSION lock_wait_timeout, or rebuild with ${GOT}`);
      }
      const myIndex = t.match(INDEX_STATEMENT);
      if (myIndex) {
        const table = name(myIndex[1]);
        const kind = t.match(/^create (fulltext|spatial) index/i)?.[1];
        learnStatement(t, maps, mysqlVersion);
        if (isExisting(table) && firstLock === -1) firstLock = k;
        if (isExisting(table) && kind)
          add(k, 'mysql-fulltext-spatial-index', `${kind.toUpperCase()} index on ${table} blocks writes while it builds (LOCK=NONE is not allowed): build it on a shadow table with ${GOT}, or accept the window with a recorded reason`);
      }
      const dropIndex = t.match(new RegExp(String.raw`^drop index \S+ on (${ident})`, 'i'));
      if (dropIndex && isExisting(name(dropIndex[1])) && firstLock === -1) firstLock = k;
      const renameTables = t.match(/^rename table (.*)$/i);
      if (renameTables && firstLock === -1 && isExisting(name(renameTables[1].split(/\s+to\s+/i)[0]))) firstLock = k;
    }

    const drop = t.match(new RegExp(String.raw`^drop table (?:if exists )?(.*)$`, 'i'));
    if (drop) {
      for (const raw of splitTopLevel(drop[1].replace(/\s+(cascade|restrict)\s*$/i, ''))) {
        const table = name(raw);
        if (!rebuilt(table)) { if (!created.has(table)) add(k, 'drop-table', `drops table ${table} and its data: only in a contract step, after the code stopped using it, with a verified backup and a recorded approval`); continue; }
        const oldCols = tables.get(table);
        const fresh = tables.get(copiedFrom.get(table));
        if (!oldCols || !fresh) continue;
        const gone = [...oldCols].filter((c) => !fresh.has(c));
        const inserted = texts.map(insertTargets).find((x) => x?.table === copiedFrom.get(table));
        const uncopied = inserted ? [...oldCols].filter((c) => fresh.has(c) && !inserted.columns.has(c)) : [];
        if (gone.length || uncopied.length)
          add(k, 'rebuild-drops-column', `the rebuild of ${table} loses the data of column(s) ${[...gone, ...uncopied].join(', ')}: ${gone.length ? 'the new table does not have them' : 'the INSERT … SELECT does not copy them'}`);
      }
    }
    if (/^drop schema\b/i.test(t) && /\bcascade\b/i.test(t)) add(k, 'drop-schema-cascade', 'DROP SCHEMA … CASCADE drops every table and object in the schema: needs a verified backup and a recorded approval');
    if (/^drop materialized view\b/i.test(t)) add(k, 'drop-materialized-view', 'drops a materialized view and the data it stores: the code that reads it breaks — contract step, with a recorded approval');
    if (/^truncate\b/i.test(t)) add(k, 'truncate', 'deletes every row: needs a verified backup and a recorded approval');
    if (/^delete from\b/i.test(t) && unbounded(b, { nullChecks: false })) add(k, 'delete-all', 'DELETE with no WHERE (or a WHERE that is always true) removes every row');
    const upd = t.match(new RegExp(String.raw`^update ${TABLE_ALL}`, 'i'));
    if (upd && !created.has(name(upd[1])) && unbounded(b, { nullChecks: true }))
      add(k, 'update-all', 'UPDATE with no WHERE (or one that selects every row to fill) rewrites the whole table in one transaction: backfill in batches by key range, outside the DDL migration, idempotent');
    const rename = t.match(/^rename table (\S+)/i);
    if (rename && !created.has(name(rename[1])))
      add(k, 'rename-table', `renames table ${name(rename[1])} in one step: create the new one (or a view with the old name) and move readers first`);

    const index = t.match(new RegExp(String.raw`^create (unique )?index (concurrently )?(?:if not exists )?(?:${ident} )?on ${TABLE_ALL}`, 'i'));
    if (pg && index && !index[2] && !created.has(name(index[3])))
      add(k, 'index-without-concurrently', `builds an index on ${name(index[3])} blocking writes for the whole build: CREATE INDEX CONCURRENTLY, outside a transaction${index[1] ? ' (unique: existing duplicates make it fail — check first)' : ''}`);
    if (pg && /^drop index\b/i.test(t) && !/\bconcurrently\b/i.test(t))
      add(k, 'drop-index-without-concurrently', 'DROP INDEX takes ACCESS EXCLUSIVE on its table: DROP INDEX CONCURRENTLY');
    if (pg && /\bconcurrently\b/i.test(t) && (explicitTx || wrapped))
      add(k, 'concurrently-in-transaction', explicitTx && !wrapped
        ? 'CONCURRENTLY cannot run inside a transaction: put it in its own migration with the runner\'s no-transaction mode'
        : `CONCURRENTLY cannot run inside a transaction, and ${profile.label} runs this file in one: put it in its own migration with the runner's no-transaction mode (goose \`-- +goose NO TRANSACTION\`, dbmate \`transaction:false\`, Atlas \`-- atlas:txmode none\`, Flyway \`executeInTransaction=false\`)`);

    if (explicitWrap && !reportedTx && (TX_START.test(t) || /^commit\b/i.test(t))) {
      reportedTx = true;
      add(k, 'transaction-conflict', `${profile.label} already runs the file in a transaction: ${dialect === 'sqlite' ? 'a nested BEGIN fails with "cannot start a transaction within a transaction"' : 'BEGIN/COMMIT inside it end the transaction early or warn'} — remove them`, { level: dialect === 'sqlite' ? ERROR : WARN });
    }
    if (wrapped && !reportedPragma && /^pragma\s+foreign_keys\b/i.test(t)) {
      reportedPragma = true;
      add(k, 'transaction-conflict', `PRAGMA foreign_keys is a no-op inside the transaction ${profile.label} wraps around the file, so DROP TABLE still runs ON DELETE CASCADE / SET NULL on child rows. Run the rebuild in the runner's no-transaction mode, where foreign_keys=OFF takes effect (PRAGMA defer_foreign_keys only helps plain NO ACTION foreign keys), and rehearse it with real child rows`, { level: copiedFrom.size ? ERROR : WARN });
    }
    if ((my ? MYSQL_LOCK_WAIT : ora ? DDL_LOCK_TIMEOUT : db2 ? DB2_LOCK_TIMEOUT : LOCK_TIMEOUT).test(t) && lockTimeoutAt === -1) lockTimeoutAt = k;
    applySchema(tables, t);
  });

  if (my && firstLock !== -1 && (lockTimeoutAt === -1 || lockTimeoutAt > firstLock))
    add(firstLock, 'mysql-lock-wait-timeout', lockTimeoutAt === -1
      ? `DDL on an existing table without SET SESSION lock_wait_timeout: the statement waits for the table's metadata lock behind any open transaction (even an idle one) and every later query on the table queues behind it — SET SESSION lock_wait_timeout = 5 (MariaDB also accepts \`WAIT 5\` on the ALTER) and retry with backoff`
      : 'lock_wait_timeout is set after the first DDL on an existing table, so that statement waits for its lock without a limit: move the SET before it', { line: statements[firstLock].line });

  for (const [table, p] of pendingReorg)
    add(p.k, 'db2-reorg-pending', `${p.op} puts ${table} in REORG-pending state: until a classic REORG TABLE completes, most operations on it fail with SQLSTATE 57007 (reads are limited to table scans) — follow the statement with CALL SYSPROC.ADMIN_CMD('REORG TABLE ${table}') in this migration, and rehearse how long it takes`);

  if (db2 && firstLock !== -1 && (lockTimeoutAt === -1 || lockTimeoutAt > firstLock))
    add(firstLock, 'db2-lock-timeout', lockTimeoutAt === -1
      ? "DDL on an existing table without SET CURRENT LOCK TIMEOUT: LOCKTIMEOUT defaults to -1, so the statement waits for its lock without limit behind any transaction holding the table, and every later query queues behind it — SET CURRENT LOCK TIMEOUT 5 first, and retry on failure"
      : 'CURRENT LOCK TIMEOUT is set after the first DDL on an existing table, so that statement waits for its lock without a limit: move the SET before it', { line: statements[firstLock].line });

  if (ora && firstLock !== -1 && (lockTimeoutAt === -1 || lockTimeoutAt > firstLock))
    add(firstLock, 'oracle-ddl-lock-timeout', lockTimeoutAt === -1
      ? "DDL on an existing table without ALTER SESSION SET DDL_LOCK_TIMEOUT: Oracle does not queue the statement, it fails at once with ORA-00054 (resource busy) when any transaction holds the table — the risk is a half-applied deploy (each DDL committed, the rest not run); ALTER SESSION SET DDL_LOCK_TIMEOUT = 30 makes it wait up to 30 s instead, and retry the whole migration on failure"
      : 'DDL_LOCK_TIMEOUT is set after the first DDL on an existing table, so that statement fails at once on a busy table: move the ALTER SESSION before it', { line: statements[firstLock].line });

  if (ms && firstLock !== -1 && (lockTimeoutAt === -1 || lockTimeoutAt > firstLock))
    add(firstLock, 'mssql-lock-timeout', lockTimeoutAt === -1
      ? "DDL on an existing table without SET LOCK_TIMEOUT: the statement waits for its schema lock behind any open transaction without a limit, and every later query on the table queues behind it — SET LOCK_TIMEOUT 5000 (milliseconds) first, or WAIT_AT_LOW_PRIORITY on the online rebuild / SWITCH (SQL Server 2014+), and retry on failure"
      : 'LOCK_TIMEOUT is set after the first DDL on an existing table, so that statement waits for its lock without a limit: move the SET before it', { line: statements[firstLock].line });

  if (pg && firstLock !== -1 && (lockTimeoutAt === -1 || lockTimeoutAt > firstLock))
    add(firstLock, 'missing-lock-timeout', lockTimeoutAt === -1
      ? "ALTER TABLE on an existing table without SET lock_timeout: a long query ahead of it makes every read and write queue behind its lock — SET lock_timeout = '5s' and retry on failure"
      : 'lock_timeout is set after the first ALTER TABLE on an existing table, so that ALTER waits for its lock without a limit: move the SET before it', { line: statements[firstLock].line });

  const ddl = texts.filter((t) => !NON_DDL.test(t));
  const concurrent = texts.some((t) => /\bconcurrently\b/i.test(t));
  const missing = profile.id === 'raw' ? [] : [...markers.separators].filter((s) => !profile.separators.includes(s));
  if (missing.length)
    add(0, 'unsupported-separator', `${missing.map((s) => (s === 'terminator' ? 'a custom statement terminator' : `\`${s}\``)).join(' and ')} in the file, but ${profile.label} does not split on it: the whole file reaches the driver as one statement and the server answers with a syntax error — use a runner that does (Flyway, Liquibase, DbUp), or send the file with sqlcmd/SQL*Plus/the Db2 CLP`);
  if (dialect !== 'mysql' && dialect !== 'oracle' && ddl.length > 1 && !explicitTx && !concurrent && !wrapped)
    add(0, 'not-atomic', `${ddl.length} statements outside a transaction: a failure halfway leaves the schema between versions — BEGIN/COMMIT, or pass --runner (or add the runner's config file) when the runner wraps each file`);

  findings.sort((a, b) => a.line - b.line);
  return {
    findings, hasDownSection, dialect, statements: statements.length, markers, downSql: parsed.downSql,
    irreversible: directiveState.irreversible !== null, createdTables: createdHere, schema: tables,
  };
};
