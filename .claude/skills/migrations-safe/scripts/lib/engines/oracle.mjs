// Oracle rehearsal engine (gvenzl/oracle-free): reached with `docker exec <container> sh -c '... | sqlplus'`.
// SQL*Plus has no command-line switch for session settings, so the shell feeds a prologue (settings, error
// handling, the DBMS_APPLICATION_INFO module that tags the session) before the script on stdin. Migrations run
// as an application user; the lock poller runs as SYSTEM, which can read v$lock and dba_ddl_locks.
// Oracle Free has the Enterprise Edition features, so Standard Edition 2 behaviour (no ONLINE index builds,
// no MOVE ONLINE, no DBMS_REDEFINITION) is not emulated: the rehearsal says so.
import { parse } from '../parse.mjs';
import { MIGRATION_APP, POLLER_APP, PROBE_TABLE, SEED_APP } from './shared.mjs';

const APP_USER = 'REHEARSAL';
const PASSWORD = 'Msafe_Rehearsal1';
const SERVICE = 'FREEPDB1';
const CONNECT = (user) => `${user}/${PASSWORD}@//127.0.0.1:1521/${SERVICE}`;
const shq = (s) => `'${s.replaceAll("'", "'\\''")}'`;
const POLL_TABLES = `SELECT DECODE(l.lmode, 4, 'S', 5, 'SSX', 6, 'X') || CHR(9) || LOWER(o.object_name) FROM v$lock l JOIN v$session s ON s.sid = l.sid JOIN dba_objects o ON o.object_id = l.id1 WHERE l.type = 'TM' AND l.lmode IN (4, 5, 6) AND s.module = '${MIGRATION_APP}' AND o.owner = '${APP_USER}' UNION ALL SELECT 'DDL-' || d.mode_held || CHR(9) || LOWER(d.name) FROM dba_ddl_locks d JOIN v$session s ON s.sid = d.session_id WHERE d.owner = '${APP_USER}' AND d.type = 'Table/Procedure/Type' AND d.mode_held = 'Exclusive' AND s.module = '${MIGRATION_APP}';`;
const EPOCH = (tag) => `SELECT '@@${tag} ' || TO_CHAR(EXTRACT(DAY FROM d) * 86400 + EXTRACT(HOUR FROM d) * 3600 + EXTRACT(MINUTE FROM d) * 60 + EXTRACT(SECOND FROM d), 'FM9999999999.999999') FROM (SELECT CAST(SYSTIMESTAMP AT TIME ZONE 'UTC' AS TIMESTAMP) - TIMESTAMP '1970-01-01 00:00:00' AS d FROM dual);\n`;
const LOB = /^(?:CLOB|NCLOB)$/i;
const RAWS = /^(?:BLOB|RAW|LONG RAW)\b/i;
const q = (id) => `"${id.replaceAll('"', '""')}"`;
const lit = (s) => `'${s.replaceAll("'", "''")}'`;

// The statements of a script as SQL*Plus must receive them: ';' after SQL, '/' after PL/SQL, commands as they are.
export const sqlplusInput = (sql) => parse(sql, { dialect: 'oracle' }).statements.filter((s) => !s.inner)
  .map((s) => (s.command ? s.text : s.plsql ? `${s.text}\n/` : `${s.text};`)).join('\n');

// Lines where a PL/SQL block ends without its `/`. SQL*Plus would keep reading past the block (and wait for
// input), so the script is not run as if it were valid: the lint rule oracle-missing-slash reports the same.
export const missingSlashLines = (sql) => parse(sql, { dialect: 'oracle' }).statements.filter((s) => !s.inner && s.plsql && s.slash === false).map((s) => s.line);

export const makeOracle = ({ kind, image }, { edition = 'se2' } = {}) => {
  // prologue: output settings for machine reading, the session tag, and (for strict runs) stop at the first error
  const prologue = (app, stopOnError) => [
    'SET ECHO OFF HEADING OFF PAGESIZE 0 FEEDBACK OFF VERIFY OFF DEFINE OFF SQLBLANKLINES ON TRIMSPOOL ON LINESIZE 32767 LONG 100000000 LONGCHUNKSIZE 32767',
    ...(stopOnError ? ['WHENEVER SQLERROR EXIT FAILURE', 'WHENEVER OSERROR EXIT FAILURE'] : []),
    ...(app ? [`EXEC DBMS_APPLICATION_INFO.SET_MODULE('${app}', NULL)`] : []),
  ];
  const sqlplus = (c, { user = APP_USER, app, stopOnError = true } = {}) => ['exec', '-i', c, 'sh', '-c',
    `{ printf '%s\\n' ${prologue(app, stopOnError).map(shq).join(' ')}; cat; } | sqlplus -S -L ${CONNECT(user)}`];
  const eng = {
    kind, image, label: 'Oracle', dialect: 'oracle', password: PASSWORD, database: SERVICE, implicitCommit: true, startupMs: 900000, needsNetwork: true,
    editionNote: edition === 'ee'
      ? 'edition: Oracle Free, which has the Enterprise Edition features (ONLINE, MOVE ONLINE, DBMS_REDEFINITION)'
      : 'edition: --edition se2 is not emulated: Oracle Free has the Enterprise Edition features, so ONLINE, MOVE ONLINE and DBMS_REDEFINITION pass here and fail on Standard Edition 2 (the lint rule oracle-online-unsupported-edition reports them)',
    // data files stay on the container's disk: Oracle opens them with direct I/O, which a tmpfs does not offer
    runArgs: () => ['-e', `ORACLE_PASSWORD=${PASSWORD}`, '-e', `APP_USER=${APP_USER}`, '-e', `APP_USER_PASSWORD=${PASSWORD}`, image],
    readyArgs: (c) => ['exec', '-i', c, 'sh', '-c', `echo "SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT 1 FROM dual;" | sqlplus -S -L ${CONNECT(APP_USER)}`],
    setup: async () => null,
    scriptArgs: (c, { app, stopOnError }) => sqlplus(c, { app, stopOnError }),
    scriptInput: (sql, { marks }) => {
      const lines = missingSlashLines(sql);
      if (lines.length) return { input: '', marked: false, error: `PL/SQL block without its closing \`/\` on a line of its own (line ${lines.join(', ')}): SQL*Plus and Flyway keep reading past it and the migration would hang or run the following statements as part of the block — add the \`/\` (lint rule oracle-missing-slash); not run` };
      return { input: `${marks ? EPOCH('T0') : ''}${sqlplusInput(sql)}\n${marks ? EPOCH('T1') : ''}`, marked: marks };
    },
    queryArgs: (c) => sqlplus(c, { app: SEED_APP }),
    pollerArgs: (c) => sqlplus(c, { user: 'SYSTEM', app: POLLER_APP, stopOnError: false }),
    pollInput: () => `${POLL_TABLES}\nSELECT '@@END' FROM dual;\n`,
    // SQL*Plus writes its errors to stdout
    errorsOnStdout: true,
    errorLines: (text) => text.split(/\r?\n/).filter((l) => /^(?:ORA|SP2|PLS)-\d+/.test(l)),
    describeError: (line) => line.match(/^(?:ORA|SP2|PLS)-\d+/)?.[0] ?? 'ORA',
    failText: (r) => {
      const lines = `${r.out}\n${r.err}`.split(/\r?\n/).filter((l) => /^(?:ORA|SP2|PLS)-\d+/.test(l));
      return lines.length ? lines.slice(0, 3).join(' | ') : (r.err || r.out).trim().split(/\r?\n/).slice(0, 3).join(' | ');
    },
    metaSql: `SELECT CHR(9) || c.table_name || CHR(9) || c.column_name || CHR(9) || c.data_type || CASE WHEN c.data_type IN ('VARCHAR2', 'NVARCHAR2', 'CHAR', 'NCHAR', 'RAW') THEN '(' || c.data_length || ')' WHEN c.data_type = 'NUMBER' AND c.data_precision IS NOT NULL THEN '(' || c.data_precision || ',' || NVL(c.data_scale, 0) || ')' ELSE '' END FROM user_tab_columns c JOIN user_tables t ON t.table_name = c.table_name WHERE c.table_name NOT LIKE 'MSAFE\\_%' ESCAPE '\\' ORDER BY c.table_name, c.column_id;`,
    fold: (s) => s.toLowerCase(),
    tableKey: (schema, table) => table.toLowerCase(),
    statsSql: (key, { name }, cols) => {
      const v = (c) => (LOB.test(c.type) ? `DBMS_LOB.SUBSTR(${q(c.name)}, 100, 1)` : RAWS.test(c.type) ? `RAWTOHEX(${/^BLOB/i.test(c.type) ? `DBMS_LOB.SUBSTR(${q(c.name)}, 100, 1)` : q(c.name)})` : `SUBSTR(TO_CHAR(${q(c.name)}), 1, 100)`);
      return `SELECT JSON_OBJECT('t' VALUE ${lit(key)}, 'n' VALUE COUNT(*)${cols.map((c, i) => `, 'c${i}' VALUE COUNT(${q(c.name)}), 'd${i}' VALUE COUNT(DISTINCT ${v(c)}), 'l${i}' VALUE NVL(SUM(LENGTH(${v(c)})), 0), 'lo${i}' VALUE MIN(${v(c)}), 'hi${i}' VALUE MAX(${v(c)})`).join('')} RETURNING CLOB) FROM ${q(name)};`;
    },
    normalizeLockTable: (t) => t,
    shell: (c) => `docker exec -it ${c} sqlplus ${CONNECT(APP_USER)}`,
    probe: {
      create: `CREATE TABLE ${PROBE_TABLE} (id NUMBER);\n`, drop: `DROP TABLE ${PROBE_TABLE};\n`,
      hold: `LOCK TABLE ${PROBE_TABLE} IN EXCLUSIVE MODE;\nEXEC DBMS_SESSION.SLEEP(3);\nCOMMIT;\n`,
    },
  };
  return eng;
};
