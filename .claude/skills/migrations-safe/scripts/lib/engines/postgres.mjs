// PostgreSQL rehearsal engine: reached with `docker exec <container> psql`.
import { MIGRATION_APP, POLLER_APP, PROBE_TABLE, lockList } from './shared.mjs';

const PASSWORD = 'msafe';
const DATABASE = 'rehearsal';
const pgQuote = (id) => `"${id.replaceAll('"', '""')}"`;
const pgLiteral = (s) => `'${s.replaceAll("'", "''")}'`;
const PG_LOCKS = ['AccessExclusiveLock', 'ExclusiveLock', 'ShareRowExclusiveLock', 'ShareLock'];
const pollSql = `SELECT l.mode || E'\\t' || n.nspname || '.' || c.relname FROM pg_locks l JOIN pg_stat_activity a ON a.pid = l.pid JOIN pg_class c ON c.oid = l.relation JOIN pg_namespace n ON n.oid = c.relnamespace WHERE l.locktype = 'relation' AND l.granted AND c.relkind IN ('r', 'p') AND a.application_name = '${MIGRATION_APP}' AND l.mode IN (${lockList(PG_LOCKS)}) AND n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg\\_%';`;

export const makePostgres = ({ kind, image }) => {
  const base = (c, { app } = {}) => ['exec', '-i', '-e', `PGPASSWORD=${PASSWORD}`, ...(app ? ['-e', `PGAPPNAME=${app}`] : []), c,
    'psql', '-h', '127.0.0.1', '-U', 'postgres', '-d', DATABASE, '-X', '-q', '-A', '-t', '-F', '\t'];
  const mark = (tag) => `SELECT '@@${tag} ' || extract(epoch from clock_timestamp());\n`;
  return {
    kind, image, label: 'PostgreSQL', dialect: 'postgres', password: PASSWORD, database: DATABASE,
    runArgs: ({ tmpfs }) => [...(tmpfs ? ['--tmpfs', '/var/lib/postgresql/data', '-e', 'PGDATA=/var/lib/postgresql/data/pgdata'] : []), '-e', `POSTGRES_PASSWORD=${PASSWORD}`, '-e', `POSTGRES_DB=${DATABASE}`, image, 'postgres', '-c', 'fsync=off', '-c', 'synchronous_commit=off', '-c', 'full_page_writes=off'],
    setup: async () => null,
    base,
    readyArgs: (c) => [...base(c), '-c', 'SELECT 1'],
    scriptArgs: (c, { app, stopOnError, wrap }) => [...base(c, { app }), ...(stopOnError ? ['-v', 'ON_ERROR_STOP=1'] : []), ...(wrap ? ['-1'] : []), '-f', '-'],
    // an empty statement after the file ends a last statement that lacks its semicolon
    scriptInput: (sql, { marks }) => ({ input: marks ? `${mark('T0')}${sql}\n;\n${mark('T1')}` : sql, marked: marks }),
    queryArgs: (c) => [...base(c), '-v', 'ON_ERROR_STOP=1', '-f', '-'],
    pollerArgs: (c) => [...base(c, { app: POLLER_APP }), '-v', 'ON_ERROR_STOP=1', '-f', '-'],
    pollInput: () => `${pollSql}\n\\echo @@END\n`,
    errorLines: (stderr) => stderr.split(/\r?\n/).filter((l) => /\bERROR:/.test(l)),
    // statement number only: an error text can quote row data
    describeError: (line) => `at line ${line.match(/:(\d+): ERROR/)?.[1] ?? '?'}`,
    metaSql: "SELECT n.nspname, c.relname, a.attname, format_type(a.atttypid, a.atttypmod) FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname NOT IN ('pg_catalog', 'information_schema') AND n.nspname NOT LIKE 'pg\\_%' AND c.relkind IN ('r', 'p') AND a.attnum > 0 AND NOT a.attisdropped ORDER BY n.nspname, c.relname, a.attnum;",
    tableKey: (schema, table) => (schema === 'public' ? table : `${schema}.${table}`),
    statsSql: (key, { schema, name }, cols) => `SELECT row_to_json(x)::text FROM (SELECT ${pgLiteral(key)} AS t, count(*) AS n${cols.map((c, i) => `, count(${pgQuote(c.name)}) AS c${i}, count(DISTINCT ${pgQuote(c.name)}::text) AS d${i}, coalesce(sum(length(${pgQuote(c.name)}::text)), 0) AS l${i}, min(${pgQuote(c.name)}::text) AS lo${i}, max(${pgQuote(c.name)}::text) AS hi${i}`).join('')} FROM ${pgQuote(schema)}.${pgQuote(name)}) x;`,
    normalizeLockTable: (t) => t.replace(/^public\./, ''),
    shell: (c) => `docker exec -it -e PGPASSWORD=${PASSWORD} ${c} psql -h 127.0.0.1 -U postgres ${DATABASE}`,
    restoreArgs: (c) => ['exec', '-i', '-e', `PGPASSWORD=${PASSWORD}`, c, 'pg_restore', '-h', '127.0.0.1', '-U', 'postgres', '-d', DATABASE, '--no-owner', '--no-privileges'],
    probe: {
      create: `CREATE TABLE ${PROBE_TABLE} (id int);`, drop: `DROP TABLE ${PROBE_TABLE};`,
      hold: `BEGIN;\nLOCK TABLE ${PROBE_TABLE} IN ACCESS EXCLUSIVE MODE;\nSELECT pg_sleep(3);\nCOMMIT;\n`,
    },
  };
};
