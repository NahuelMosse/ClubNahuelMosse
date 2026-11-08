// Db2 LUW rehearsal engine (icr.io/db2_community/db2): reached with `docker exec <container> sh -c '... | su - db2inst1 -c "db2 ..."'`.
// The container needs --privileged and LICENSE=accept. The CLP reads statements ended with `~` (so compound
// statements keep their semicolons); the scripts are rebuilt from the parsed statements. Lock polling reads
// MON_GET_LOCKS for the sessions that tagged themselves with WLM_SET_CLIENT_INFO, and after each migration the
// tables left in REORG-pending state are read from SYSIBMADM.ADMINTABINFO: a table in that state is a
// migration that "worked" and left the table unusable until a REORG.
import { parse } from '../parse.mjs';
import { MIGRATION_APP, POLLER_APP, PROBE_TABLE, SEED_APP, docker } from './shared.mjs';

const OWNER = 'DB2INST1';
const PASSWORD = 'Msafe_Rehearsal1';
const DATABASE = 'REHEARSE';
const shq = (s) => `'${s.replaceAll("'", "'\\''")}'`;
// `~`, not `@`: an e-mail address in a literal must not end a statement
const T = '~';

// MON_GET_LOCKS names a table by tablespace and table id, not by name: SYSCAT.TABLES translates them
const POLL = `SELECT l.LOCK_MODE || CHR(9) || LOWER(t.TABNAME) FROM TABLE(MON_GET_LOCKS(NULL, -2)) l JOIN SYSCAT.TABLES t ON t.TBSPACEID = l.TBSP_ID AND t.TABLEID = l.TAB_FILE_ID JOIN TABLE(MON_GET_CONNECTION(NULL, -2)) c ON c.APPLICATION_HANDLE = l.APPLICATION_HANDLE WHERE l.LOCK_OBJECT_TYPE = 'TABLE' AND t.TABSCHEMA = '${OWNER}' AND c.CLIENT_APPLNAME = '${MIGRATION_APP}' AND l.LOCK_MODE IN ('Z', 'X', 'S', 'SIX')${T}`;
// the markers the shared code reads start with two at signs
const AT = 'CHR(64) || CHR(64)';
const EPOCH = (tag) => `VALUES ${AT} || '${tag} ' ||TRIM(CHAR(DECIMAL((DAYS(CURRENT TIMESTAMP - CURRENT TIMEZONE) - DAYS('1970-01-01')) * 86400 + MIDNIGHT_SECONDS(CURRENT TIMESTAMP - CURRENT TIMEZONE) + MICROSECOND(CURRENT TIMESTAMP) / 1000000.0, 20, 6)))${T}\n`;
const LOB = /^(?:CLOB|DBCLOB)$/i;
const BIN = /^(?:BLOB)$/i;
const q = (id) => `"${id.replaceAll('"', '""')}"`;
const lit = (s) => `'${s.replaceAll("'", "''")}'`;
const num = (expr) => `TRIM(CHAR(${expr}))`;

// The statements of a script as the CLP must receive them: each ended with `~`.
export const clpInput = (sql) => parse(sql, { dialect: 'db2' }).statements.filter((s) => !s.command).map((s) => `${s.text}\n${T}`).join('\n');

export const makeDb2 = ({ kind, image }) => {
  // The connection banner and the client-info call print text: output is off while they run.
  const prologue = (app) => [`UPDATE COMMAND OPTIONS USING O OFF${T}`, `CONNECT TO ${DATABASE}${T}`,
    ...(app ? [`CALL SYSPROC.WLM_SET_CLIENT_INFO(NULL, NULL, '${app}', NULL, NULL)${T}`] : []), `UPDATE COMMAND OPTIONS USING O ON${T}`];
  // The CLP cannot read a script from /dev/stdin (DB21005E): a script that is sent whole is written to a file in the
  // container and run with -f. `dump` scripts keep the `;` terminator of the dump tools; every other script is sent with `~`.
  const clp = (c, { app, stopOnError = true, dump = false, script = null } = {}) => ['exec', '-i', c, 'sh', '-c',
    `f=$(mktemp /tmp/msafe.XXXXXX); { printf '%s\\n' ${(dump ? prologue(app).map((l) => l.replace(/~$/, ';')) : prologue(app)).map(shq).join(' ')}; ${script === null ? 'cat' : `printf '%s\\n' ${shq(script)}`}; } > "$f"; chmod 644 "$f"; su - db2inst1 -c "db2 -x -t${dump ? '' : 'd~'}${stopOnError ? ' -s' : ''} -f $f"; rc=$?; rm -f "$f"; if [ $rc -ge 4 ]; then exit 1; fi; exit 0`];
  // The lock poller keeps one session and sends it a query every few tenths of a second: the interactive CLP reads
  // stdin as it arrives (and prefixes its output with the `db2 => ` prompt, which the line cleaner removes).
  const interactive = (c, app) => ['exec', '-i', c, 'sh', '-c',
    `{ printf '%s\\n' ${prologue(app).map(shq).join(' ')}; cat; } | su - db2inst1 -c "db2 -x -td${T}"`];
  const eng = {
    kind, image, label: 'Db2', dialect: 'db2', password: PASSWORD, database: DATABASE, implicitCommit: false, startupMs: 600000, needsNetwork: true,
    editionNote: 'edition: Db2 Community Edition (the image limits memory and cores; the DDL behaviour the rules rely on is the same as in the licensed editions)',
    runArgs: () => ['--privileged', '-e', 'LICENSE=accept', '-e', `DB2INST1_PASSWORD=${PASSWORD}`, '-e', `DBNAME=${DATABASE}`, '-e', 'ARCHIVE_LOGS=false', '-e', 'AUTOCONFIG=false', image],
    // one CLP process does the connect and the query: separate `db2` commands do not share a connection here (SQL1024N)
    readyArgs: (c) => clp(c, { stopOnError: true, script: `VALUES 1${T}` }),
    cleanLine: (line) => line.replace(/^(?:db2 => )+/, ''),
    setup: async () => null,
    scriptArgs: (c, { app, stopOnError, dump }) => clp(c, { app, stopOnError, dump }),
    // a seed (not a dump) is rebuilt from its statements
    seedInput: (text) => clpInput(text),
    scriptInput: (sql, { wrap, marks }) => ({
      input: `${wrap ? `UPDATE COMMAND OPTIONS USING C OFF${T}\n` : ''}${marks ? EPOCH('T0') : ''}${clpInput(sql)}\n${wrap ? `COMMIT${T}\n` : ''}${marks ? EPOCH('T1') : ''}`,
      marked: marks,
    }),
    queryArgs: (c) => clp(c, { app: SEED_APP }),
    pollerArgs: (c) => interactive(c, POLLER_APP),
    pollInput: () => `${POLL}\nVALUES ${AT} || 'END'${T}\n`,
    // the CLP writes SQL errors to stdout
    errorsOnStdout: true,
    // DB21034E only announces the SQL error that follows it (the statement was sent as SQL): it is not an error of its own
    errorLines: (text) => text.split(/\r?\n/).filter((l) => /^(?:SQL|DB2)\d+[NE]\b/.test(l) && !l.startsWith('DB21034E')),
    describeError: (line) => line.match(/^(?:SQL|DB2)\d+[NE]/)?.[0] ?? 'SQL',
    failText: (r) => {
      const lines = eng.errorLines(`${r.out}\n${r.err}`).map((l) => l.replace(/\s+/g, ' '));
      return lines.length ? lines.slice(0, 3).join(' | ') : (r.err || r.out).trim().split(/\r?\n/).slice(0, 3).join(' | ');
    },
    metaSql: `SELECT c.TABSCHEMA || CHR(9) || c.TABNAME || CHR(9) || c.COLNAME || CHR(9) || c.TYPENAME || CASE WHEN c.TYPENAME IN ('VARCHAR', 'CHARACTER', 'VARGRAPHIC', 'GRAPHIC', 'VARBINARY', 'BINARY') THEN '(' || TRIM(CHAR(c.LENGTH)) || ')' WHEN c.TYPENAME = 'DECIMAL' THEN '(' || TRIM(CHAR(c.LENGTH)) || ',' || TRIM(CHAR(c.SCALE)) || ')' ELSE '' END FROM SYSCAT.COLUMNS c JOIN SYSCAT.TABLES t ON t.TABSCHEMA = c.TABSCHEMA AND t.TABNAME = c.TABNAME WHERE t.TYPE = 'T' AND t.TABSCHEMA = '${OWNER}' AND t.TABNAME NOT LIKE 'MSAFE\\_%' ESCAPE '\\' ORDER BY c.TABNAME, c.COLNO${T}`,
    fold: (s) => s.toLowerCase(),
    tableKey: (schema, table) => table.toLowerCase(),
    // JSON built by hand: numbers and hex strings need no escaping, so one row is one valid JSON object
    statsSql: (key, { schema, name }, cols) => {
      const v = (c) => (LOB.test(c.type) || BIN.test(c.type) ? `SUBSTR(${q(c.name)}, 1, 40)` : `SUBSTR(CAST(${q(c.name)} AS VARCHAR(1000)), 1, 40)`);
      const hex = (e) => `COALESCE(HEX(${e}), '')`;
      return `SELECT '{"t":"' || ${lit(key)} || '","n":' || ${num('COUNT_BIG(*)')}${cols.map((c, i) => ` || ',"c${i}":' || ${num(`COUNT(${q(c.name)})`)} || ',"d${i}":' || ${num(`COUNT(DISTINCT ${v(c)})`)} || ',"l${i}":' || ${num(`COALESCE(SUM(BIGINT(LENGTH(${v(c)}))), 0)`)} || ',"lo${i}":"' || ${hex(`MIN(${v(c)})`)} || '","hi${i}":"' || ${hex(`MAX(${v(c)})`)} || '"'`).join('')} || '}' FROM ${q(schema || OWNER)}.${q(name)}${T}`;
    },
    normalizeLockTable: (t) => t,
    // tables left in REORG-pending state by the migration that just ran
    pending: async (c) => {
      const r = await docker(clp(c, { app: SEED_APP }), { input: `SELECT LOWER(TABNAME) FROM SYSIBMADM.ADMINTABINFO WHERE TABSCHEMA = '${OWNER}' AND REORG_PENDING = 'Y'${T}\n` });
      if (r.code !== 0) throw new Error(`reading REORG_PENDING failed: ${eng.failText(r)}`);
      return r.out.split(/\r?\n/).map((l) => l.trim()).filter((l) => /^[\w$#]+$/.test(l));
    },
    // a second self-test: DROP COLUMN on the probe table must be seen as REORG-pending by the same check
    pendingProbe: { table: PROBE_TABLE, sql: `ALTER TABLE ${PROBE_TABLE} ADD COLUMN c2 INTEGER${T}\nALTER TABLE ${PROBE_TABLE} DROP COLUMN c2${T}\n` },
    shell: (c) => `docker exec -it ${c} su - db2inst1 -c "db2 connect to ${DATABASE} && db2"`,
    probe: {
      create: `CREATE TABLE ${PROBE_TABLE} (id INTEGER)${T}\n`, drop: `DROP TABLE ${PROBE_TABLE}${T}\n`,
      // autocommit off, so the table lock outlives the statement that takes it
      hold: `UPDATE COMMAND OPTIONS USING C OFF${T}\nLOCK TABLE ${PROBE_TABLE} IN EXCLUSIVE MODE${T}\nCALL DBMS_ALERT.SLEEP(3)${T}\nCOMMIT${T}\n`,
    },
  };
  return eng;
};
