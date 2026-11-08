// The SQL Server rules. `add(rule, message, { level })` reports a finding for the statement being read.
import { name, stripLiterals } from './parse.mjs';
import { versionAtLeast } from './server-version.mjs';
import {
  ALTER_INDEX, CREATE_INDEX, ONLINE_ALTER_COLUMN_YEAR, ONLINE_ON, RESUMABLE_ON, defaultOf, isEnterprise, tsqlColumn, widenOnlyProblem,
} from './mssql.mjs';

const WARN = 'warning';
const EDITION_NAME = { standard: 'Standard', enterprise: 'Enterprise', azure: 'Azure SQL' };
const NOT_COLUMN_ADD = /^(?:constraint|index|key|unique|primary|foreign|check|period|periodic|system_time)\b/i;
const METADATA_ONLY = /^alter\s+column\s+\S+\s+(?:add|drop)\s+(?:rowguidcol|persisted|not\s+for\s+replication|sparse|masked|hidden)\b/i;

// ONLINE = ON and RESUMABLE = ON need Enterprise; Standard and Express fail with Msg 1712 / 40517-style errors.
const onlineEdition = ({ add, text, edition }) => {
  if (isEnterprise(edition)) return;
  const what = ONLINE_ON.test(text) ? 'ONLINE = ON' : RESUMABLE_ON.test(text) ? 'RESUMABLE = ON' : null;
  if (what)
    add('mssql-online-unsupported-edition', `${what} is not available in ${EDITION_NAME[edition]} edition (online index operations and online schema changes are Enterprise features in SQL Server 2022 and 2025): the statement fails at once — drop the option and schedule the offline window, or pass --edition enterprise if production is Enterprise`);
};

// Rules for one ALTER TABLE on an existing table; `actions` come from normalizeTsqlActions.
export const mssqlAlterRules = ({ add, table, actions, version, edition, defs = new Map() }) => {
  const enterprise = isEnterprise(edition);
  const editionName = EDITION_NAME[edition];
  for (const a of actions) {
    onlineEdition({ add, text: a, edition });
    const addMatch = a.match(/^add\s+(?:column\s+)?(.*)$/is);
    if (addMatch && !NOT_COLUMN_ADD.test(addMatch[1])) {
      const def = addMatch[1];
      const notNull = /\bnot\s+null\b/i.test(stripLiterals(def));
      const withValues = /\bwith\s+values\b/i.test(def);
      const dflt = defaultOf(def);
      if (dflt.present && (notNull || withValues) && (!enterprise || !dflt.constant))
        add('mssql-add-not-null-default', `adds a ${notNull ? 'NOT NULL column with a DEFAULT' : 'column with DEFAULT ... WITH VALUES'} to ${table}: ${dflt.constant ? `${editionName} edition writes the default into every row while holding a schema modification lock (Sch-M), which blocks every reader and writer; only Enterprise and Azure SQL do it as a metadata change` : 'the default is not a runtime constant (NEWID(), NEXT VALUE FOR, RAND()), so every row is written under Sch-M even on Enterprise'} — add the column NULL (a nullable ADD, with or without DEFAULT, is metadata-only), backfill in batches, then enforce NOT NULL (itself a size-of-data check: do it through a validated CHECK first, or during a window)`);
    }
    if (/^alter\s+column\b/i.test(a) && !METADATA_ONLY.test(a)) {
      const online = ONLINE_ON.test(a);
      const next = tsqlColumn(a.replace(/^alter\s+column\s+/i, ''));
      const prev = next && defs.get(`${table}.${next.column}`);
      const problem = prev ? widenOnlyProblem(prev, next) : null;
      // a longer varchar/nvarchar/varbinary with the same nullability and collation only changes metadata
      if (prev && !problem) continue;
      const why = !next ? '' : prev
        ? ` Not a metadata-only change here: ${problem}.`
        : ` The previous definition of ${next.column} is unknown (no CREATE TABLE, ADD or ALTER COLUMN for it in this file, the earlier migrations or --schema), so a widening that only changes metadata cannot be told apart from a rewrite: pass the earlier SQL with --schema to let the linter check.`;
      if (!online ||!versionAtLeast(version, ONLINE_ALTER_COLUMN_YEAR))
        add('mssql-alter-column', `ALTER COLUMN on ${table} without WITH (ONLINE = ON) ${versionAtLeast(version, ONLINE_ALTER_COLUMN_YEAR) ? '' : `(it does not exist before SQL Server ${ONLINE_ALTER_COLUMN_YEAR}; ${version.label} given) `}can rewrite the column under a schema modification lock (Sch-M) that blocks all access for the whole operation: widening a varchar/nvarchar/varbinary keeps it a metadata change, anything else (type, nullability, collation, narrowing) is size-of-data — new column, backfill, switch, drop later; or ${enterprise ? 'add WITH (ONLINE = ON)' : 'a maintenance window (this edition has no ONLINE)'}.${why}`);
      else if (enterprise)
        add('mssql-alter-column', `ALTER COLUMN ... WITH (ONLINE = ON) on ${table} keeps the table readable and writable but builds a second copy of the column: it doubles the space and the log for the duration, and still takes Sch-M briefly at both ends — run it off-peak with a LOCK_TIMEOUT`, { level: WARN });
    }
    if (/^add\s+(?:constraint\s+(?:\[[^\]]+\]|\S+)\s+)?(?:primary\s+key|unique)\b/i.test(a) && !ONLINE_ON.test(a))
      add('mssql-index-offline', `ADD PRIMARY KEY / UNIQUE on ${table} builds its index without WITH (ONLINE = ON): the table is locked against writes (a clustered key rebuilds the whole table) for the whole build${enterprise ? ' — add WITH (ONLINE = ON)' : ` — ${editionName} edition has no online build: use a maintenance window, or create the index in advance on a copy`}; existing duplicates make it fail at the end`);
    if (/^rebuild\b/i.test(a) && !ONLINE_ON.test(a))
      add('mssql-index-offline', `ALTER TABLE ${table} REBUILD without WITH (ONLINE = ON) rewrites the table and its indexes under a lock that blocks writes${enterprise ? ' — add WITH (ONLINE = ON)' : ` (${editionName} edition has no online rebuild)`}`);
    const constraint = a.match(/^(?:with\s+(no)?check\s+)?add\s+(?:constraint\s+(?:\[[^\]]+\]|\S+)\s+)?(foreign\s+key|check)\b/i);
    if (constraint) {
      const kind = /foreign/i.test(constraint[2]) ? 'FOREIGN KEY' : 'CHECK';
      if (constraint[1])
        add('mssql-constraint-nocheck', `WITH NOCHECK adds the ${kind} on ${table} without validating existing rows, so it stays untrusted: the optimizer ignores it for plans and it may not hold for old data — validate later with ALTER TABLE ... WITH CHECK CHECK CONSTRAINT (off-peak), or allow this finding with that follow-up recorded`, { level: WARN });
      else
        add('mssql-constraint-with-check', `adding a ${kind} to ${table} validates every existing row (WITH CHECK is the default for new constraints) while holding a schema modification lock: add it WITH NOCHECK, then validate in a later step; or run it in a window on a small table`);
    }
  }
};

// CREATE INDEX, ALTER INDEX and index options outside ALTER TABLE. Returns true when the statement locks an existing table.
export const mssqlIndexRules = ({ add, text, isExisting, edition }) => {
  const enterprise = isEnterprise(edition);
  const create = text.match(CREATE_INDEX);
  const alter = text.match(ALTER_INDEX);
  const table = name((create ?? alter)?.[1] ?? '');
  if (!create && !alter) return false;
  if (!isExisting(table)) return false;
  onlineEdition({ add, text, edition });
  if (create && !ONLINE_ON.test(text))
    add('mssql-index-offline', `CREATE INDEX on ${table} without WITH (ONLINE = ON) blocks writes (a shared table lock) for the whole build${enterprise ? ' — add WITH (ONLINE = ON), and WAIT_AT_LOW_PRIORITY or a LOCK_TIMEOUT for the lock at the end' : ` — ${EDITION_NAME[edition]} edition has no online build: schedule a window, build the index while the table is small, or use a smaller covering index`}`);
  if (alter && /^rebuild$/i.test(alter[2]) && !ONLINE_ON.test(text))
    add('mssql-index-offline', `ALTER INDEX ... REBUILD on ${table} without WITH (ONLINE = ON) takes the index offline for the rebuild${enterprise ? ' — add WITH (ONLINE = ON), or use REORGANIZE (always online)' : ` (${EDITION_NAME[edition]} edition has no online rebuild; REORGANIZE is online)`}`);
  return true;
};

export const DROP_COLUMN_NOTE = ' (SQL Server frees the space only when the clustered index is rebuilt)';
