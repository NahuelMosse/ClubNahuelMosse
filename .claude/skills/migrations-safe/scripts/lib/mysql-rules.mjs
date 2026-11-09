// The MySQL/MariaDB rules for one ALTER TABLE on an existing table. `add(rule, message, { level })` reports a
// finding; `state` holds what earlier statements taught (enums, indexed, defs, instantVersions).
import { name, stripLiterals } from './parse.mjs';
import {
  INSTANT_ROW_VERSION_LIMIT, INSTANT_ROW_VERSION_WARN, algorithmProblem, colDef, enumChange, enumOf, hasPosition, hasRenameColumn, indexedColumn,
  instantAnyPosition, isAddColumn, isMaria, learnActions, onlineCopy, supportsInstant,
} from './mysql.mjs';

export const GOT = 'gh-ost or pt-online-schema-change';
const WARN = 'warning';

const ordinal = (n) => `${n}${n % 10 === 1 && n !== 11 ? 'st' : n % 10 === 2 && n !== 12 ? 'nd' : n % 10 === 3 && n !== 13 ? 'rd' : 'th'}`;

export const mysqlAlterRules = ({ add, table, actions, version: v, fkChecksOff, state }) => {
  const maria = isMaria(v);
  const algo = actions.map((a) => a.match(/^algorithm\s*=?\s*(\w+)/i)?.[1]?.toLowerCase()).find(Boolean);
  const lock = actions.map((a) => a.match(/^lock\s*=?\s*(\w+)/i)?.[1]?.toLowerCase()).find(Boolean);
  const addsPk = actions.some((a) => /^add (?:constraint \S+ )?primary key\b/i.test(a));
  const copies = onlineCopy(v) ? 'copies the table (online on MariaDB 11.2+, but slow and doubling disk use)' : 'copies the table while writes are blocked';
  const known = new Set(state.indexed.get(table) ?? []);
  for (const a of actions) { const c = /^add\b(?!.*\bforeign key\b)/i.test(a) ? indexedColumn(a) : null; if (c) known.add(c); }

  if (algo === 'instant' && !supportsInstant(v))
    add('mysql-algorithm-unsupported', `ALGORITHM=INSTANT does not exist on ${v.label} (${maria ? 'MariaDB 10.3' : 'MySQL 8.0.12'} and later): the statement fails with ERROR 1800 (unknown ALGORITHM) — use ALGORITHM=INPLACE, LOCK=NONE, or ${GOT} for a big table`);
  if (algo === 'instant' && !maria && supportsInstant(v) && lock && lock !== 'default')
    add('mysql-algorithm-unsupported', `ALGORITHM=INSTANT cannot be combined with LOCK=${lock.toUpperCase()}: the statement fails with ERROR 1221 (incorrect usage) — write ALGORITHM=INSTANT alone; INSTANT needs no lock clause`);

  for (const a of actions) {
    const bare = stripLiterals(a);
    const changesColumn = /^(?:modify|change)\b/i.test(a);
    const def = changesColumn ? colDef(a) : null;
    const before = def ? state.defs.get(`${table}.${def.oldColumn}`) : undefined;
    if (algo && ['instant', 'inplace', 'nocopy'].includes(algo) && !(algo === 'instant' && !supportsInstant(v))) {
      const problem = algorithmProblem(a, algo, v, { addsPrimaryKey: addsPk, fkChecksOff, before });
      if (problem)
        add('mysql-algorithm-unsupported', `ALGORITHM=${algo.toUpperCase()} on ${v.label}: ${problem.why}. ${problem.level === WARN ? 'The statement can fail' : 'The statement fails'} with ERROR 1845 or 1846 (operation not supported) instead of running — pick the algorithm the operation supports, or use ${GOT} for a big table`, { level: problem.level });
    }
    if (/^drop primary key\b/i.test(a) && !addsPk)
      add('mysql-drop-primary-key', `drops the PRIMARY KEY of ${table} without adding one: only ALGORITHM=COPY supports it, so the server ${copies} (and the table has no clustered key meanwhile) — replace the key in one statement (DROP PRIMARY KEY, ADD PRIMARY KEY (...)), or use ${GOT}`);
    if (/^add (?:constraint \S+ )?primary key\b/i.test(a))
      add('mysql-add-primary-key', `adding a PRIMARY KEY to ${table} rebuilds the whole table in place (concurrent DML is allowed, but disk use doubles and the metadata lock waits behind long transactions; NULL columns need NOT NULL first, and duplicates fail at the end): run it off-peak with LOCK=NONE, or use ${GOT}`);
    if (/^add (?:fulltext|spatial)\b/i.test(a))
      add('mysql-fulltext-spatial-index', `${/fulltext/i.test(a) ? 'FULLTEXT' : 'SPATIAL'} index on ${table} blocks writes while it builds (LOCK=NONE is not allowed${/fulltext/i.test(a) ? '; the first FULLTEXT index also rebuilds the table unless FTS_DOC_ID exists' : ''}): build it on a shadow table with ${GOT}, or accept the window with a recorded reason`);
    if (/^add (?:constraint \S+ )?foreign key\b/i.test(a)) {
      if (!fkChecksOff)
        add('mysql-add-foreign-key', `adding a FOREIGN KEY to ${table} with foreign_key_checks=1 makes the server copy the whole table (ALGORITHM=INPLACE needs foreign_key_checks=0, which skips validating existing rows): validate orphans first with a query, then SET SESSION foreign_key_checks=0 around an ALGORITHM=INPLACE, LOCK=NONE ALTER — gh-ost does not support foreign keys, pt-online-schema-change needs --alter-foreign-keys-method`);
      const col = indexedColumn(a);
      if (col && !known.has(col))
        add('mysql-fk-implicit-index', `no index on ${table}(${col}) in the migrations read (earlier migrations of the folder and --schema count): if there is none, MySQL builds one inside the same ALTER and the build lengthens the lock — add the index first (ALTER TABLE ... ADD INDEX, ALGORITHM=INPLACE, LOCK=NONE), then the key`);
      if (col) known.add(col);
    }
    if (/^convert to (?:character set|charset)\b/i.test(a))
      add('mysql-charset-conversion', `CONVERT TO CHARACTER SET rewrites every text column of ${table}: the server ${copies} (utf8/utf8mb3 to utf8mb4 also grows keys: indexed VARCHAR(255) goes past 767 bytes on COMPACT/REDUNDANT rows, and joins with columns that keep the old collation stop using indexes): convert with ${GOT}, column by column, and keep collations of joined columns equal`);
    else if (changesColumn && /\b(?:character set|charset|collate)\s+\w/i.test(bare))
      add('mysql-charset-conversion', `changes the character set or collation of a column of ${table}: the server rebuilds the table (${onlineCopy(v) ? 'online on MariaDB 11.2+' : 'writes are blocked'}), indexed columns can exceed the key length, and joins against columns with another collation lose their index — ${GOT}, with the same collation on both sides of every join`);
    if (/^force$/i.test(a) || /^engine\s*=\s*innodb$/i.test(a) || /^(?:row_format|key_block_size)\b/i.test(a))
      add('mysql-table-rebuild', `${/^force/i.test(a) ? 'ALTER TABLE ... FORCE' : /^engine/i.test(a) ? 'ENGINE=InnoDB' : 'changing the row format or key block size'} rebuilds ${table}: ALGORITHM=INPLACE allows DML but copies every page, doubles disk use and queues behind long transactions at both ends — off-peak with LOCK=NONE, or ${GOT}`);
    if (isAddColumn(a) && hasPosition(a) && !instantAnyPosition(v))
      add('mysql-column-position', `ADD COLUMN ... FIRST/AFTER on ${v.label} is not instant (only as the last column before ${maria ? 'MariaDB 10.4' : 'MySQL 8.0.29'}): the table is rebuilt — add the column last, or ${GOT}`);
    if (changesColumn && hasPosition(a))
      add('mysql-column-position', `moving a column of ${table} (FIRST/AFTER) rebuilds the table: column order is not part of any contract, so leave it where it is`);
    const change = a.match(/^change (?:column )?(\S+)\s+(\S+)/i);
    if (change && name(change[1]) !== name(change[2]) && hasRenameColumn(v))
      add('mysql-change-column-rename', `CHANGE COLUMN restates the whole definition to rename ${name(change[1])}: any difference from the real definition becomes a type or nullability change (a table copy) — use RENAME COLUMN ${name(change[1])} TO ${name(change[2])}${maria ? '' : ' (instant since 8.0.28)'}`);
    const enumDef = changesColumn ? enumOf(a) : null;
    if (enumDef) {
      const kind = enumDef.kind.toUpperCase();
      const was = state.enums.get(`${table}.${def?.oldColumn ?? enumDef.column}`);
      if (!was) {
        add('mysql-enum-change', `cannot tell whether this ${kind} change on ${table}.${enumDef.column} only appends members (appending at the end is instant, anything else copies the table): the earlier definition is not in the files read — check SHOW CREATE TABLE, or pass the CREATE TABLE with --schema`, { level: WARN });
      } else {
        const how = enumChange(was, enumDef);
        if (how === 'resize')
          add('mysql-enum-change', `appending to the ${kind} of ${table}.${enumDef.column} changes its storage size (${kind === 'ENUM' ? '255 to 256 members' : 'the member count crosses a multiple of 8'}): the server ${copies} — ${GOT}`);
        else if (how === 'reorder')
          add('mysql-enum-change', `this ${kind} change on ${table}.${enumDef.column} removes, reorders or inserts members before the end: every stored value is renumbered, so the server ${copies} and rows can change meaning — only append at the end, or use ${GOT}`);
        else if (algo === 'instant' && was.nullable !== enumDef.nullable)
          add('mysql-algorithm-unsupported', `ALGORITHM=INSTANT on ${v.label}: changing the nullability of ${table}.${enumDef.column} together with its members is not INSTANT. The statement fails with ERROR 1845 or 1846 (operation not supported) — append the members alone, or use ${GOT}`);
      }
    }
  }
  const n = learnActions(table, actions, state, v);
  if (n !== null && n >= INSTANT_ROW_VERSION_WARN)
    add('mysql-instant-row-versions', `this is the ${ordinal(n)} instant ADD/DROP COLUMN on ${table} in the migrations read: InnoDB keeps ${INSTANT_ROW_VERSION_LIMIT} row versions per table (MySQL 8.0.29+), then ALGORITHM=INSTANT fails with ERROR 4092 (read INFORMATION_SCHEMA.INNODB_TABLES.TOTAL_ROW_VERSIONS; a rebuild with ALTER TABLE ... FORCE resets it) — schedule the rebuild before this one. The warning starts at ${INSTANT_ROW_VERSION_WARN}, a margin for statements the linter does not see`);
};
