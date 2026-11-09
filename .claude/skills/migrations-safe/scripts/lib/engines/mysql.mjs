// MySQL and MariaDB rehearsal engine: reached with `docker exec <container> mysql|mariadb`.
import { parse } from '../parse.mjs';
import { PROBE_TABLE, docker, firstLines, lockList } from './shared.mjs';

const PASSWORD = 'msafe';
const DATABASE = 'rehearsal';
const myQuote = (id) => `\`${id.replaceAll('`', '``')}\``;
const myLiteral = (s) => `'${s.replaceAll('\\', '\\\\').replaceAll("'", "''")}'`;
const GEOMETRY = /^(?:geometry|point|linestring|polygon|multipoint|multilinestring|multipolygon|geometrycollection)\b/i;
const MY_LOCKS = ['EXCLUSIVE', 'SHARED_NO_WRITE', 'SHARED_NO_READ_WRITE', 'SHARED_READ_ONLY'];
const pollSqlMysql = `SELECT CONCAT(m.LOCK_TYPE, '\\t', m.OBJECT_NAME) FROM performance_schema.metadata_locks m WHERE m.OBJECT_TYPE = 'TABLE' AND m.OBJECT_SCHEMA = '${DATABASE}' AND m.LOCK_STATUS = 'GRANTED' AND m.LOCK_TYPE IN (${lockList(MY_LOCKS)}) AND m.OWNER_THREAD_ID <> (SELECT t.THREAD_ID FROM performance_schema.threads t WHERE t.PROCESSLIST_ID = CONNECTION_ID());`;
const pollSqlMaria = `SELECT CONCAT(REPLACE(LOCK_MODE, 'MDL_', ''), '\\t', TABLE_NAME) FROM information_schema.METADATA_LOCK_INFO WHERE TABLE_SCHEMA = '${DATABASE}' AND LOCK_MODE IN (${lockList(MY_LOCKS.map((m) => `MDL_${m}`))}) AND THREAD_ID <> CONNECTION_ID();`;

// The statements a MySQL client runs: every statement ends with `;;`, so compound statements (procedures
// from goose StatementBegin/End) keep their inner semicolons. A file that sets its own DELIMITER is sent as it is.
export const mysqlInput = (sql, { wrap, marks }) => {
  if (/^\s*delimiter\b/im.test(sql)) return { input: wrap ? `START TRANSACTION;\n${sql}\nCOMMIT;\n` : sql, marked: false };
  const statements = parse(sql, { dialect: 'mysql' }).statements.map((s) => s.text);
  const mark = (tag) => `SELECT CONCAT('@@${tag} ', UNIX_TIMESTAMP(SYSDATE(6)));;\n`;
  const body = `DELIMITER ;;\n${marks ? mark('T0') : ''}${statements.map((s) => `${s};;\n`).join('')}${marks ? mark('T1') : ''}DELIMITER ;\n`;
  return { input: wrap ? `START TRANSACTION;\n${body}COMMIT;\n` : body, marked: marks };
};

export const makeMysql = ({ kind, image }) => {
  const maria = kind === 'mariadb';
  const eng = {
    kind, image, label: maria ? 'MariaDB' : 'MySQL', dialect: 'mysql', bin: 'mysql', password: PASSWORD, database: DATABASE, implicitCommit: true,
    runArgs: ({ tmpfs }) => [...(tmpfs ? ['--tmpfs', '/var/lib/mysql'] : []), '-e', `${maria ? 'MARIADB' : 'MYSQL'}_ROOT_PASSWORD=${PASSWORD}`, '-e', `${maria ? 'MARIADB' : 'MYSQL'}_DATABASE=${DATABASE}`, image],
    base: (c, extra = []) => ['exec', '-i', '-e', `MYSQL_PWD=${PASSWORD}`, c, eng.bin, '-h127.0.0.1', '-uroot', '--batch', '--raw', '--skip-column-names', '--default-character-set=utf8mb4', '-D', DATABASE, ...extra],
    readyArgs: (c) => eng.base(c, ['-e', 'SELECT 1']),
    scriptArgs: (c, { stopOnError }) => eng.base(c, stopOnError ? [] : ['--force']),
    scriptInput: (sql, { wrap, marks }) => mysqlInput(sql, { wrap, marks }),
    queryArgs: (c) => eng.base(c),
    pollerArgs: (c) => eng.base(c, ['--unbuffered']),
    pollInput: () => `${maria ? pollSqlMaria : pollSqlMysql}\nSELECT '@@END';\n`,
    errorLines: (stderr) => stderr.split(/\r?\n/).filter((l) => /^ERROR \d+/.test(l)),
    describeError: (line) => line.match(/^(ERROR \d+(?: \(\w+\))?)(?: at line (\d+))?/)?.slice(1).filter(Boolean).join(' at line ') ?? 'ERROR',
    metaSql: `SELECT '', c.TABLE_NAME, c.COLUMN_NAME, c.COLUMN_TYPE FROM information_schema.COLUMNS c JOIN information_schema.TABLES t ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME WHERE c.TABLE_SCHEMA = DATABASE() AND t.TABLE_TYPE = 'BASE TABLE' ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;`,
    tableKey: (schema, table) => table,
    statsSql: (key, { name }, cols) => `SELECT JSON_OBJECT('t', ${myLiteral(key)}, 'n', COUNT(*)${cols.map((c, i) => {
      const v = GEOMETRY.test(c.type) ? `ST_AsText(${myQuote(c.name)})` : `CAST(${myQuote(c.name)} AS CHAR)`;
      return `, 'c${i}', COUNT(${myQuote(c.name)}), 'd${i}', COUNT(DISTINCT ${myQuote(c.name)}), 'l${i}', COALESCE(SUM(LENGTH(${v})), 0), 'lo${i}', MIN(${v}), 'hi${i}', MAX(${v})`;
    }).join('')}) FROM ${myQuote(name)};`,
    normalizeLockTable: (t) => t,
    shell: (c) => `docker exec -it ${c} ${eng.bin} -h127.0.0.1 -uroot -p${PASSWORD} ${DATABASE}`,
    // Newer MariaDB images ship `mariadb` without the `mysql` name.
    detect: async (c) => {
      if (eng.binFound) return;
      const found = await docker(['exec', c, 'sh', '-c', 'command -v mariadb || command -v mysql']);
      if (found.code === 0 && found.out.trim()) { eng.bin = found.out.trim().split('/').pop(); eng.binFound = true; }
    },
    // The metadata-lock instrument is off by default in MySQL 5.7, and MariaDB reports locks through a plugin.
    // Returns why locks cannot be read, or null.
    setup: async (c) => {
      const sql = maria ? "INSTALL SONAME 'metadata_lock_info'" : "UPDATE performance_schema.setup_instruments SET ENABLED = 'YES', TIMED = 'YES' WHERE NAME = 'wait/lock/metadata/sql/mdl'";
      const r = await docker(eng.base(c, ['-e', sql]));
      return r.code === 0 ? null : firstLines(r.err || r.out, 2);
    },
    probe: {
      create: `CREATE TABLE ${PROBE_TABLE} (id int) ENGINE=InnoDB;`, drop: `DROP TABLE ${PROBE_TABLE};`,
      hold: `LOCK TABLES ${PROBE_TABLE} WRITE;\nSELECT SLEEP(3);\nUNLOCK TABLES;\n`,
    },
  };
  return eng;
};
