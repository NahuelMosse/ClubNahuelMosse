// The Oracle rules. `add(rule, message, { level })` reports a finding for the statement being read.
import { name, splitTopLevel } from './parse.mjs';
import { versionAtLeast } from './server-version.mjs';
import { ALTER_INDEX_REBUILD, CREATE_INDEX, ONLINE, REDEFINITION, isEE } from './oracle.mjs';

const WARN = 'warning';
const NOT_COLUMN_ADD = /^(?:constraint|primary|foreign|unique|check|supplemental|ref|scope)\b/i;

const onlineEdition = ({ add, text, edition }) => {
  if (isEE(edition)) return;
  const what = REDEFINITION.test(text) ? 'DBMS_REDEFINITION' : /\bmove\b.*\bonline\b/i.test(text) ? 'MOVE ONLINE' : ONLINE.test(text) && /^(?:create|alter)\s+(?:(?:unique|bitmap)\s+)?index\b/i.test(text) ? 'ONLINE index build/rebuild' : null;
  if (what)
    add('oracle-online-unsupported-edition', `${what} is an Enterprise Edition feature (Oracle Database Licensing Information, High Availability table): Standard Edition 2 fails with ORA-00439 (feature not enabled) — drop ONLINE and plan the window, or pass --edition ee if production is Enterprise (Oracle Free, which the rehearsal runs, has these features, so the rehearsal cannot show this failure)`);
};

// Rules for one ALTER TABLE on an existing table.
export const oracleAlterRules = ({ add, table, actions, version, text, edition }) => {
  onlineEdition({ add, text, edition });
  for (const a of actions) {
    const addMatch = a.match(/^add\s*(?:column\s+)?(.*)$/is);
    if (addMatch && !NOT_COLUMN_ADD.test(addMatch[1].replace(/^\(\s*/, ''))) {
      const defs = addMatch[1].startsWith('(') ? splitTopLevel(addMatch[1].replace(/^\(|\)$/g, '')) : [addMatch[1]];
      for (const def of defs) {
        if (NOT_COLUMN_ADD.test(def)) continue;
        if (/\bdefault\b/i.test(def) && !/\bnot\s+null\b/i.test(def) && !versionAtLeast(version, 12, 1))
          add('oracle-add-column-default', `adds a nullable column with a DEFAULT to ${table} on ${version.label}: before 12.1 the default is written into every row (a full-table update holding row locks and generating redo); only NOT NULL with a DEFAULT is metadata-only since 11.1 — add the column NOT NULL DEFAULT, or add it plain, backfill in batches and set the default afterwards`);
      }
    }
    if (/^drop\s+(?:column\b|\()/i.test(a))
      add('oracle-drop-column-rewrites', `DROP COLUMN on ${table} rewrites every row while it blocks DML on the table: SET UNUSED first (a dictionary change; ONLINE from 12c when the edition has it), drop the unused columns in a window or never`, { level: WARN });
    if (/^set\s+unused\b/i.test(a))
      add('drop-column', `marks columns of ${table} unused: the data stays on disk but nothing can read it again, and the running code that selects or inserts them breaks — contract step only, after a release that stopped using them, with a backup and a recorded approval`);
    const constraint = a.match(/^add\s+(?:constraint\s+\S+\s+)?(foreign\s+key|check)\b/i);
    if (constraint && !/\bnovalidate\b/i.test(a) && !/\bdisable\b/i.test(a))
      add('oracle-constraint-validate', `adding a ${/foreign/i.test(constraint[1]) ? 'FOREIGN KEY' : 'CHECK'} to ${table} validates every row while it holds a lock that blocks DML: ADD ... ENABLE NOVALIDATE (new rows are checked, old ones are not), then ALTER TABLE ${table} MODIFY CONSTRAINT <name> VALIDATE in a separate step, which does not block DML`);
  }
};

// CREATE INDEX and ALTER INDEX ... REBUILD, DBMS_REDEFINITION anywhere. Returns true when the statement takes a DDL lock on an existing table.
export const oracleStatementRules = ({ add, text, isExisting, edition }) => {
  if (REDEFINITION.test(text)) onlineEdition({ add, text, edition });
  const create = text.match(CREATE_INDEX);
  const rebuild = ALTER_INDEX_REBUILD.test(text);
  if (create && isExisting(name(create[1]))) {
    onlineEdition({ add, text, edition });
    if (!ONLINE.test(text))
      add('oracle-index-not-online', `CREATE INDEX on ${name(create[1])} without ONLINE blocks DML on the table for the whole build${isEE(edition) ? ' — add ONLINE' : ' — Standard Edition 2 has no online build: schedule a window, or build it while the table is small'}`);
    return true;
  }
  if (rebuild) {
    onlineEdition({ add, text, edition });
    if (!ONLINE.test(text))
      add('oracle-index-not-online', `ALTER INDEX ... REBUILD without ONLINE blocks DML on the table for the whole rebuild${isEE(edition) ? ' — add ONLINE' : ' — Standard Edition 2 has no online rebuild: schedule a window'}`);
    return true;
  }
  return false;
};
