// SQL Server rehearsal engine: reached with `docker exec <container> sqlcmd`. The edition is chosen with
// MSSQL_PID: Express (2019, 2022) or StandardDeveloper (2025) behave like a non-Enterprise edition, Developer
// like Enterprise; the running edition is read back with SERVERPROPERTY and a mismatch is a rehearsal that
// cannot run.
import { RehearsalUsageError } from '../rehearse.mjs';
import { parseServerVersion } from '../server-version.mjs';
import { MIGRATION_APP, POLLER_APP, PROBE_TABLE, SEED_APP, docker, firstLines } from './shared.mjs';

const PASSWORD = 'Msafe#Rehearsal1';
const DATABASE = 'rehearsal';
const SQLCMD = ['/opt/mssql-tools18/bin/sqlcmd', '/opt/mssql-tools/bin/sqlcmd'];
const EXPRESS_LIMIT_BYTES = 10 * 1024 ** 3; // 10 GB per database in Express 2019 and 2022 (50 GB in 2025, which uses StandardDeveloper here)
const quote = (id) => `[${id.replaceAll(']', ']]')}]`;
const literal = (s) => `N'${s.replaceAll("'", "''")}'`;
const BINARY = /^(?:binary|varbinary|image|timestamp|rowversion)\b/i;
const NOCOUNT = 'SET NOCOUNT ON;\n';

// TRY_CAST: resource_associated_entity_id is a bigint and only OBJECT locks hold an object id that fits an int
const pollSql = `SELECT x.m + CHAR(9) + x.s + '.' + x.n FROM (SELECT l.request_mode AS m, OBJECT_SCHEMA_NAME(TRY_CAST(l.resource_associated_entity_id AS int), l.resource_database_id) AS s, OBJECT_NAME(TRY_CAST(l.resource_associated_entity_id AS int), l.resource_database_id) AS n FROM sys.dm_tran_locks l JOIN sys.dm_exec_sessions se ON se.session_id = l.request_session_id WHERE l.resource_type = 'OBJECT' AND l.resource_database_id = DB_ID('${DATABASE}') AND se.host_name = '${MIGRATION_APP}' AND l.request_mode IN ('Sch-M', 'X', 'SIX', 'S') AND (l.request_status = 'GRANT' OR l.request_mode = 'Sch-M')) x WHERE x.n IS NOT NULL AND x.s NOT IN ('sys', 'INFORMATION_SCHEMA');`;
const go = (sql) => `${NOCOUNT}${sql}\nGO\n`;

const mark = (tag) => `SELECT CONCAT('@@${tag} ', CONVERT(varchar(40), CAST(DATEDIFF_BIG(microsecond, '1970-01-01', SYSUTCDATETIME()) AS decimal(30, 0)) / 1000000.0));\nGO\n`;

export const makeMssql = ({ kind, image, tag }, { edition = 'standard' } = {}) => {
  const year = parseServerVersion('mssql', tag)?.major ?? 2022;
  const enterprise = edition === 'enterprise';
  const pid = enterprise ? 'Developer' : year >= 2025 ? 'StandardDeveloper' : 'Express';
  const eng = {
    kind, image, label: 'SQL Server', dialect: 'mssql', password: PASSWORD, database: DATABASE, implicitCommit: false,
    sqlcmd: SQLCMD[0],
    // the container needs O_DIRECT, which a tmpfs does not offer: data stays on the container's disk
    runArgs: () => ['-e', 'ACCEPT_EULA=Y', '-e', `MSSQL_SA_PASSWORD=${PASSWORD}`, '-e', `MSSQL_PID=${pid}`, image],
    // 127.0.0.1, not localhost: a container with no network has no IPv6 loopback and sqlcmd tries ::1 first.
    // -y 0 prints values at full width, unpadded and without headers (it cannot be combined with -h or -W).
    base: (c, { app, db = DATABASE, extra = [] } = {}) => ['exec', '-i', '-e', `SQLCMDPASSWORD=${PASSWORD}`, c, eng.sqlcmd, '-S', '127.0.0.1', '-U', 'sa',
      ...(eng.sqlcmd.includes('tools18') ? ['-C'] : []), '-d', db, '-s', '\t', '-y', '0', '-r0', ...(app ? ['-H', app] : []), ...extra],
    detect: async (c) => {
      if (eng.found) return;
      const r = await docker(['exec', c, 'sh', '-c', `ls ${SQLCMD.join(' ')} 2>/dev/null | head -1`]);
      if (r.code === 0 && r.out.trim()) { eng.sqlcmd = r.out.trim(); eng.found = true; }
    },
    readyArgs: (c) => eng.base(c, { db: 'master', extra: ['-Q', 'SET NOCOUNT ON; SELECT 1'] }),
    // the database is created once the server answers
    setup: async (c) => {
      const r = await docker(eng.base(c, { db: 'master', extra: ['-b', '-Q', `SET NOCOUNT ON; CREATE DATABASE ${DATABASE}`] }));
      return r.code === 0 ? null : firstLines(r.err || r.out, 2);
    },
    verify: async (c) => {
      const r = await docker(eng.base(c, { extra: ['-b', '-Q', "SET NOCOUNT ON; SELECT CAST(SERVERPROPERTY('Edition') AS varchar(100))"] }));
      const running = r.out.trim().split(/\r?\n/)[0]?.trim() ?? '';
      const ok = enterprise ? /^(Developer|Enterprise)/i.test(running) : /^(Express|Standard)/i.test(running);
      return {
        error: ok ? null : `--edition ${edition} asked for ${enterprise ? 'Developer (Enterprise features)' : 'a non-Enterprise edition'} but the server reports "${running.slice(0, 60)}"`,
        note: `edition: ${running} (MSSQL_PID=${pid} for --edition ${edition})`,
      };
    },
    // Express stops at 10 GB per database: a bigger seed cannot load, and a rehearsal that cannot load says so
    checkSeed: (bytes) => {
      if (pid === 'Express' && bytes > EXPRESS_LIMIT_BYTES)
        throw new RehearsalUsageError(`the seed is ${(bytes / 1024 ** 3).toFixed(1)} GB unpacked and SQL Server Express (${year}, which --edition standard uses) stops at 10 GB per database: rehearse on --edition enterprise (Developer, no limit), or with a smaller seed`);
    },
    scriptArgs: (c, { app, stopOnError }) => eng.base(c, { app, extra: stopOnError ? ['-b'] : [] }),
    scriptInput: (sql, { wrap, marks }) => ({
      input: `${NOCOUNT}${wrap ? 'SET XACT_ABORT ON;\nBEGIN TRANSACTION;\nGO\n' : ''}${marks ? mark('T0') : ''}${sql}\nGO\n${marks ? mark('T1') : ''}${wrap ? 'COMMIT TRANSACTION;\nGO\n' : ''}`,
      marked: marks,
    }),
    queryArgs: (c) => eng.base(c, { app: SEED_APP, extra: ['-b'] }),
    pollerArgs: (c) => eng.base(c, { app: POLLER_APP, extra: ['-b'] }),
    pollInput: () => `${go(pollSql)}SELECT '@@END';\nGO\n`,
    errorLines: (stderr) => stderr.split(/\r?\n/).filter((l) => /^Msg \d+/.test(l)),
    describeError: (line) => {
      const m = line.match(/^Msg (\d+), Level \d+, State \d+, Server [^,]*, (?:Procedure [^,]*, )?Line (\d+)/);
      return m ? `Msg ${m[1]} at line ${m[2]}` : 'Msg';
    },
    q: go,
    metaSql: go(`SELECT SCHEMA_NAME(t.schema_id), t.name, c.name, ty.name + CASE WHEN ty.name IN ('varchar', 'nvarchar', 'char', 'nchar', 'varbinary', 'binary') THEN '(' + CASE WHEN c.max_length = -1 THEN 'max' ELSE CAST(CASE WHEN ty.name LIKE 'n%' THEN c.max_length / 2 ELSE c.max_length END AS varchar(10)) END + ')' WHEN ty.name IN ('decimal', 'numeric') THEN '(' + CAST(c.precision AS varchar(5)) + ',' + CAST(c.scale AS varchar(5)) + ')' ELSE '' END FROM sys.tables t JOIN sys.columns c ON c.object_id = t.object_id JOIN sys.types ty ON ty.user_type_id = c.user_type_id WHERE t.is_ms_shipped = 0 ORDER BY SCHEMA_NAME(t.schema_id), t.name, c.column_id;`),
    tableKey: (schema, table) => (schema === 'dbo' ? table : `${schema}.${table}`),
    statsSql: (key, { schema, name }, cols) => {
      const v = (c) => (BINARY.test(c.type) ? `CONVERT(varchar(max), ${quote(c.name)}, 1)` : /^(?:geometry|geography|hierarchyid)\b/i.test(c.type) ? `${quote(c.name)}.ToString()` : `CAST(${quote(c.name)} AS nvarchar(max))`);
      return `SELECT (SELECT ${literal(key)} AS t, COUNT_BIG(*) AS n${cols.map((c, i) => `, COUNT(${quote(c.name)}) AS c${i}, COUNT(DISTINCT ${v(c)}) AS d${i}, ISNULL(SUM(CAST(LEN(${v(c)}) AS bigint)), 0) AS l${i}, MIN(${v(c)}) AS lo${i}, MAX(${v(c)}) AS hi${i}`).join('')} FROM ${quote(schema)}.${quote(name)} FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);`;
    },
    normalizeLockTable: (t) => t.replace(/^dbo\./i, ''),
    startupMs: 600000,
    shell: (c) => `docker exec -it -e SQLCMDPASSWORD='${PASSWORD}' ${c} ${eng.sqlcmd} -S 127.0.0.1 -U sa${eng.sqlcmd.includes('tools18') ? ' -C' : ''} -d ${DATABASE}`,
    probe: {
      create: go(`CREATE TABLE ${PROBE_TABLE} (id int);`),
      drop: go(`DROP TABLE ${PROBE_TABLE};`),
      hold: go(`BEGIN TRANSACTION;\nSELECT 1 FROM ${PROBE_TABLE} WITH (TABLOCKX, HOLDLOCK);\nWAITFOR DELAY '00:00:03';\nCOMMIT TRANSACTION;`),
    },
  };
  return eng;
};
