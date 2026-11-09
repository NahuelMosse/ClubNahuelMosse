// Migration runner profiles and dialect detection.
//
// A profile says how a runner treats files, so the rules do not guess:
//   downs     the runner has a notion of a down migration (missing-down only applies then)
//   wraps     each file runs inside a transaction: true, false, or 'multi' (implicit transaction only
//             when the file holds more than one statement)
//   manifests files that change with every migration and are not migrations themselves
//   order     'strict'  an older new migration is skipped or rejected (error)
//             'lenient' an older pending migration is applied anyway (warning)
//             'graph'   order comes from a dependency graph, not from names (not checked)
//   foreignKeys  SQLite foreign_keys setting of the runner's connections
//   generatesSql the migrations are code, the SQL is produced at run time
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { hintedDialect } from './dialect-hints.mjs';

export const PROFILES = {
  prisma: {
    label: 'Prisma Migrate', downs: false, wraps: 'multi', order: 'strict', foreignKeys: 'on', generatesSql: false,
    layout: 'one directory per migration with migration.sql', manifests: [/(^|\/)migration_lock\.toml$/],
    config: ['prisma/schema.prisma', 'prisma.config.ts', 'prisma.config.js', 'migration_lock.toml'],
  },
  drizzle: {
    label: 'Drizzle Kit', downs: false, wraps: true, order: 'strict', foreignKeys: 'on', generatesSql: false,
    layout: 'NNNN_name.sql plus meta/_journal.json', manifests: [/(^|\/)meta\/[^/]+\.json$/],
    config: ['drizzle.config.ts', 'drizzle.config.js', 'drizzle.config.mjs', 'drizzle.config.cjs', 'drizzle.config.json', 'meta/_journal.json'],
  },
  flyway: {
    label: 'Flyway', downs: false, wraps: true, order: 'strict', foreignKeys: 'off', generatesSql: false,
    layout: 'V<version>__name.sql, R__name.sql (repeatable), U<version>__name.sql',
    manifests: [/(^|\/)R__[^/]*$/, /(^|\/)flyway\.(conf|toml)$/],
    config: ['flyway.conf', 'flyway.toml', 'conf/flyway.conf'],
  },
  liquibase: {
    label: 'Liquibase', downs: true, wraps: true, order: 'graph', foreignKeys: 'off', generatesSql: false,
    layout: 'changelog files included from a master changelog', manifests: [/(^|\/)(db\.)?changelog-master\.[^/]+$/, /(^|\/)[^/]*master[^/]*\.(xml|ya?ml|json)$/],
    config: ['liquibase.properties', 'db.changelog-master.xml', 'db.changelog-master.yaml', 'db.changelog-master.yml', 'db.changelog-master.json'],
  },
  goose: {
    label: 'goose', downs: true, wraps: true, order: 'strict', foreignKeys: 'off', generatesSql: false,
    layout: 'one file with -- +goose Up / Down sections', manifests: [], config: [],
  },
  dbmate: {
    label: 'dbmate', downs: true, wraps: true, order: 'lenient', foreignKeys: 'off', generatesSql: false,
    layout: 'one file with -- migrate:up / migrate:down sections', manifests: [], config: [],
  },
  'golang-migrate': {
    label: 'golang-migrate', downs: true, wraps: 'multi', order: 'strict', foreignKeys: 'off', generatesSql: false,
    layout: '<version>_name.up.sql and .down.sql', manifests: [], config: [],
  },
  atlas: {
    label: 'Atlas', downs: false, wraps: true, order: 'strict', foreignKeys: 'off', generatesSql: false,
    layout: 'versioned .sql files plus atlas.sum', manifests: [/(^|\/)atlas\.sum$/, /(^|\/)atlas\.hcl$/],
    config: ['atlas.hcl', 'atlas.sum'],
  },
  alembic: {
    label: 'Alembic', downs: true, wraps: true, order: 'graph', foreignKeys: 'off', generatesSql: true,
    layout: 'Python revisions linked by down_revision', manifests: [], config: ['alembic.ini'],
    hint: 'alembic upgrade <from>:<to> --sql',
  },
  django: {
    label: 'Django', downs: true, wraps: true, order: 'graph', foreignKeys: 'on', generatesSql: true,
    layout: 'Python migrations linked by dependencies', manifests: [], config: ['manage.py'],
    hint: 'python manage.py sqlmigrate <app> <migration>',
  },
  knex: {
    label: 'Knex', downs: true, wraps: true, order: 'strict', foreignKeys: 'off', generatesSql: true,
    layout: 'JS/TS migrations with up and down', manifests: [],
    config: ['knexfile.js', 'knexfile.ts', 'knexfile.cjs', 'knexfile.mjs'],
    hint: 'run knex migrate:latest on a scratch database with DEBUG=knex:query and pipe the statements',
  },
  rails: {
    label: 'Rails', downs: true, wraps: true, order: 'lenient', foreignKeys: 'off', generatesSql: true,
    layout: 'db/migrate/<timestamp>_name.rb', manifests: [/(^|\/)db\/(schema\.rb|structure\.sql)$/], config: ['config/application.rb'],
    hint: 'run rails db:migrate on a scratch database with the SQL logged and pipe the statements',
  },
  efcore: {
    label: 'EF Core migrations', downs: true, wraps: false, order: 'strict', foreignKeys: 'off', generatesSql: true,
    layout: 'C# migrations with a *ModelSnapshot.cs and the __EFMigrationsHistory table', manifests: [/ModelSnapshot\.cs$/], config: [],
    hint: 'dotnet ef migrations script --idempotent',
  },
  dbup: {
    label: 'DbUp', downs: false, wraps: false, order: 'lenient', foreignKeys: 'off', generatesSql: false,
    layout: 'script files run in name order, journaled in the SchemaVersions table', manifests: [], config: [],
  },
  sqlpackage: {
    label: 'SqlPackage (DACPAC)', downs: false, wraps: false, order: 'graph', foreignKeys: 'off', generatesSql: true,
    layout: 'a .sqlproj compared against the database', manifests: [/\.sqlproj$/], config: [],
    hint: 'sqlpackage /Action:Script',
  },
  raw: {
    label: 'plain SQL files', downs: true, wraps: false, order: 'strict', foreignKeys: 'off', generatesSql: false,
    layout: 'any .sql files, applied in name order by something else', manifests: [], config: [],
  },
};

// Batch separators each runner understands: `GO` (SQL Server), `/` (Oracle PL/SQL) and a script-chosen statement
// terminator (Db2 `--#SET TERMINATOR`, Liquibase `endDelimiter`). A runner that sends the whole file to the driver
// as one statement understands none, and the separator reaches the server as a syntax error. `raw` is applied by
// something this tool cannot see (sqlcmd, SQL*Plus, the Db2 CLP), which reads all three.
const SEPARATORS = {
  flyway: ['GO', '/'], liquibase: ['GO', '/', 'terminator'], dbup: ['GO'], sqlpackage: ['GO'], efcore: ['GO'],
  raw: ['GO', '/', 'terminator'],
};
for (const [id, p] of Object.entries(PROFILES)) p.separators = SEPARATORS[id] ?? [];

export const RUNNER_IDS = Object.keys(PROFILES);
export const DIALECTS = ['postgres', 'sqlite', 'mysql', 'mssql', 'oracle', 'db2'];

export const profileOf = (id) => ({ id, ...PROFILES[id] });

const CONFIG_PRIORITY = ['prisma', 'drizzle', 'atlas', 'liquibase', 'flyway', 'alembic', 'knex', 'django', 'rails'];

const listDir = (dir) => { try { return readdirSync(dir); } catch { return []; } };
// Runners recognised by what a directory holds rather than by one config file name.
const DETECTORS = [
  ['sqlpackage', (dir) => listDir(dir).find((f) => /\.sqlproj$/i.test(f))],
  ['efcore', (dir) => [dir, join(dir, 'Migrations')].flatMap((d) => listDir(d)).find((f) => /ModelSnapshot\.cs$/.test(f))],
  ['dbup', (dir) => listDir(dir).find((f) => /\.csproj$/i.test(f) && /dbup-/i.test(read(join(dir, f))))],
];

// The runner a file's own markers point to, or null.
export const runnerFromMarkers = (markers) => {
  if (markers?.liquibase) return { id: 'liquibase', evidence: '--liquibase formatted sql header' };
  if (markers?.sqlpackage) return { id: 'sqlpackage', evidence: 'tmp_ms_xx_ or :setvar DatabaseName (SqlPackage script)' };
  if (markers?.efcore) return { id: 'efcore', evidence: '__EFMigrationsHistory (EF Core script)' };
  if (markers?.goose) return { id: 'goose', evidence: '-- +goose marker' };
  if (markers?.dbmate) return { id: 'dbmate', evidence: '-- migrate: marker' };
  if (markers?.sqlMigrate) return { id: 'goose', evidence: '-- +migrate marker (sql-migrate uses goose-style sections)' };
  return null;
};

// The runner a file name points to, or null.
export const runnerFromName = (fileName) => {
  if (/^(V\d+(?:[._]\d+)*|R)__.+\.sql$/i.test(fileName)) return { id: 'flyway', evidence: `file name ${fileName}` };
  if (/\.(up|down)\.sql$/i.test(fileName)) return { id: 'golang-migrate', evidence: `file name ${fileName}` };
  return null;
};

const startDir = (path) => { try { return statSync(path).isDirectory() ? path : dirname(path); } catch { return dirname(path); } };

// Directories from `start` upwards, stopping after the one that holds `.git` (or at the root).
const ancestors = (start, limit = 8) => {
  const out = [];
  let dir = resolve(start);
  for (let n = 0; n < limit; n++) {
    out.push(dir);
    if (existsSync(join(dir, '.git')) || dirname(dir) === dir) break;
    dir = dirname(dir);
  }
  return out;
};

// Runner of the project that owns `path`: config files first, then the markers inside the file, then
// the file name. `markers` come from parse().
export const detectRunner = (path, { markers = null, fileName = '' } = {}) => {
  const dirs = ancestors(startDir(path));
  for (const id of CONFIG_PRIORITY) {
    for (const dir of dirs) {
      const hit = PROFILES[id].config.find((c) => existsSync(join(dir, c)));
      if (hit) return { id, evidence: `${hit} in ${dir}` };
    }
  }
  for (const [id, find] of DETECTORS) {
    for (const dir of dirs) {
      const hit = find(dir);
      if (hit) return { id, evidence: `${hit} in ${dir}` };
    }
  }
  return runnerFromMarkers(markers) ?? runnerFromName(fileName) ?? { id: 'raw', evidence: 'no runner config found' };
};

// Whether the runner wraps a file in a transaction on this dialect. Oracle commits implicitly on every DDL, so
// there is no transaction to wrap; Django and Alembic wrap only where the database has transactional DDL.
export const wrapsFor = (profile, dialect) => {
  if (dialect === 'oracle') return false;
  if ((profile.id === 'django' || profile.id === 'alembic') && dialect === 'mysql') return false;
  return profile.wraps;
};

export const wrapsFile = (profile, { noTransaction = false, statements = 0, dialect = null } = {}) => {
  const wraps = wrapsFor(profile, dialect);
  return !noTransaction && (wraps === true || (wraps === 'multi' && statements > 1));
};

const read = (p) => { try { return readFileSync(p, 'utf8'); } catch { return ''; } };
const PROVIDERS = { postgresql: 'postgres', postgres: 'postgres', pg: 'postgres', sqlite: 'sqlite', mysql: 'mysql', mariadb: 'mysql', turso: 'sqlite', singlestore: 'mysql',
  sqlserver: 'mssql', mssql: 'mssql', oracle: 'oracle', oracledb: 'oracle', db2: 'db2',
};

// Dialect of the project that owns `path`. `declared` ones come from a file whose job is to name the provider
// (Prisma's migration_lock.toml, a Drizzle config). The rest is inferred from the files of every directory from
// the file up to the repository root (see dialect-hints.mjs): the most specific rank anywhere on the way wins and
// nearness only breaks ties within a rank, so a compose file in services/web does not shadow the Flyway config at
// the root. Returns { dialect, evidence, conflict } or, when the hints of the winning directory disagree among
// themselves, { dialect: null, ambiguous }. `conflict` lists the hints of the walk that name another engine.
const declaredIn = (dir) => {
  const lock = read(join(dir, 'migration_lock.toml'));
  const provider = lock.match(/provider\s*=\s*"([\w]+)"/)?.[1]?.toLowerCase();
  if (provider && PROVIDERS[provider]) return { dialect: PROVIDERS[provider], evidence: `migration_lock.toml in ${dir}`, declared: true };
  for (const cfg of ['drizzle.config.ts', 'drizzle.config.js', 'drizzle.config.mjs', 'drizzle.config.cjs', 'drizzle.config.json']) {
    const m = read(join(dir, cfg)).match(/dialect['"]?\s*[:=]\s*['"]([\w]+)['"]/i);
    if (m && PROVIDERS[m[1].toLowerCase()]) return { dialect: PROVIDERS[m[1].toLowerCase()], evidence: `${cfg} in ${dir}`, declared: true };
  }
  return null;
};

export const projectDialect = (path) => {
  const found = [];
  for (const dir of ancestors(startDir(path))) {
    const declared = declaredIn(dir);
    if (declared) { found.push({ ...declared, tier: 0 }); continue; }
    const hinted = hintedDialect(dir);
    if (hinted) found.push(hinted);
  }
  if (!found.length) return null;
  const best = found.reduce((a, b) => (b.tier < a.tier ? b : a));
  if (best.declared) return best;
  const elsewhere = found.filter((f) => f !== best).flatMap((f) => f.hints)
    .filter((h) => h.dialect !== best.dialect).map((h) => `${h.dialect} from ${h.from} in ${h.dir}`);
  const conflict = [...new Set([...(best.conflict ?? []), ...elsewhere])];
  return { ...best, conflict: conflict.length ? conflict : null };
};

// Dialect from the syntax of a file; comments are ignored (Prisma writes backticks in its warnings).
// Markers that belong to one product come first, and only markers PostgreSQL does not use: `[x]` must be an
// identifier (PostgreSQL has `int[]` and `a[1]`), and GENERATED ... IDENTITY says nothing about Db2.
export const sniffDialect = (sql) => sniffMarkers(sql) ?? 'postgres';

// What each marker of the syntax proves. A marker lists the engines that can parse it, first the one it is most
// typical of: the first marker that matches decides the engine when nothing else is known, and a file's
// compatible engines are those every marker accepts (RENAME TABLE is MySQL and Db2, NVARCHAR is SQL Server, Db2,
// MySQL and SQLite, EXECUTE IMMEDIATE and DBMS_* are Oracle and Db2). Markers must be ones PostgreSQL does not use:
// `[x]` must be an identifier (PostgreSQL has `int[]` and `a[1]`), and GENERATED ... IDENTITY says nothing.
const PLSQL_PRAGMA = /\bpragma\s+(?:exception_init|autonomous_transaction|serially_reusable|restrict_references|udf)\b/i;
const MARKERS = [
  // [where to look, pattern, engines]; `sql` is the raw text, `code` has no comments, `bare` no string literals either
  ['sql', /^\s*--#\s*SET\s+TERMINATOR\b/im, ['db2']],
  ['pragma', /\bpragma\b/i, ['sqlite']],
  ['code', /\bautoincrement\b|\bwithout rowid\b/i, ['sqlite']],
  ['bare', /\badmin_cmd\b|\bsysproc\.|\bsysibm\.|\bwlm_set_client_info\b|\bcurrent\s+lock\s+timeout\b|\bset\s+integrity\b|\breorg\s+table\b/i, ['db2']],
  ['bare', /^\s*go(?:\s+\d+)?\s*$/im, ['mssql']],
  ['bare', /(?:^|[\s.(,])\[[A-Za-z_][\w ]*\](?=[\s.,;)=]|$)/, ['mssql', 'sqlite']],
  ['bare', /\bsp_rename\b|\bidentity\s*\(\s*\d|\bgetdate\s*\(|\bset\s+nocount\b|\bwith\s*\(\s*online\s*=/i, ['mssql']],
  ['bare', /\bnvarchar\b/i, ['mssql', 'db2', 'mysql', 'sqlite']],
  ['bare', /^\s*\/\s*$/m, ['oracle']],
  ['bare', /\bvarchar2\b|\bnvarchar2\b|\bddl_lock_timeout\b|\bset\s+unused\b|\benable\s+novalidate\b|\bmodify\s*\(/i, ['oracle']],
  ['bare', PLSQL_PRAGMA, ['oracle']],
  // MODIFY col NOT NULL / DEFAULT ...: MySQL's MODIFY always restates the type
  ['bare', /\bmodify\s+(?:\w+|"[^"]+")\s+(?:not\s+null|null|default|constraint|encrypt|decrypt|invisible|visible)\b/i, ['oracle']],
  ['bare', /\bexecute\s+immediate\b|\bdbms_\w+/i, ['oracle', 'db2']],
  ['bare', /\bfrom\s+dual\b/i, ['oracle', 'mysql']],
  ['bare', /\bnumber\s*\(\s*\d/i, ['oracle', 'db2', 'sqlite']],
  ['code', /\bengine\s*=|\bauto_increment\b|\bunsigned\b/i, ['mysql']],
  ['code', /\bmodify\s+(?:column\s+)?[\w`]/i, ['mysql', 'oracle']],
  ['code', /\brename\s+table\b/i, ['mysql', 'db2']],
  ['code', /`\w+`/, ['mysql', 'sqlite']],
];

// The markers of `sql` that match, in order, each as the list of engines that accept it.
const matchedMarkers = (sql) => {
  const code = sql.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/--[^\n]*/g, ' ');
  const bare = code.replace(/'(?:[^']|'')*'/g, "''");
  // PL/SQL has its own pragmas (EXCEPTION_INIT, AUTONOMOUS_TRANSACTION): they are Oracle, not SQLite
  const pragma = code.replace(new RegExp(PLSQL_PRAGMA, 'gi'), ' ');
  const text = { sql, code, bare, pragma };
  return MARKERS.filter(([where, re]) => re.test(text[where])).map(([, , engines]) => engines);
};

// The engine the syntax points to, or null when it carries no marker of any engine (plain SQL that every engine
// accepts).
export const sniffMarkers = (sql) => matchedMarkers(sql)[0]?.[0] ?? null;

// The engines that can parse every marker in `sql`: null without markers (all of them), an empty set when the
// markers contradict each other.
export const compatibleEngines = (sql) => {
  const matched = matchedMarkers(sql);
  if (!matched.length) return null;
  return new Set(matched.reduce((acc, engines) => acc.filter((e) => engines.includes(e)), matched[0]));
};

export const fileDialectDirective = (sql) => sql.match(/^\s*--\s*migration-lint:\s*dialect\s+(\w+)/im)?.[1]?.toLowerCase();

// The dialect the rules use for one file: the explicit one, the file's directive, the project's, or its syntax.
export const resolveDialect = (sql, { dialect, projectDialect } = {}) => {
  const requested = dialect ?? fileDialectDirective(sql) ?? projectDialect;
  return DIALECTS.includes(requested) ? requested : sniffDialect(sql);
};

// Like resolveDialect for the lint driver, but says where the answer came from. Order: --dialect, the file's
// directive, a provider the project declares (Prisma, Drizzle), markers in the syntax, the engine inferred from
// the project's files, and last PostgreSQL as an assumption. `project` is what projectDialect returned.
export const decideDialect = (sql, { dialect, project } = {}) => {
  if (DIALECTS.includes(dialect)) return { dialect, source: 'option' };
  const directive = fileDialectDirective(sql);
  if (DIALECTS.includes(directive)) return { dialect: directive, source: 'directive' };
  if (project?.declared) return { dialect: project.dialect, source: 'declared', evidence: project.evidence };
  const marked = sniffMarkers(sql);
  const compatible = compatibleEngines(sql);
  const named = project?.dialect ?? null;
  if (named) {
    // A marker only counts against the project when the engine the project names cannot parse it: RENAME TABLE is
    // valid Db2, so a Db2 project keeps its engine. The migration tool's own configuration (a strong hint) is
    // trusted even then, and the run says the syntax disagreed; a weaker hint (compose, a driver) gives way.
    const excluded = Boolean(compatible) && !compatible.has(named);
    if (!excluded) return { dialect: named, source: 'inferred', evidence: project.evidence, conflict: project.conflict };
    if (project.strong) return { dialect: named, source: 'inferred', evidence: project.evidence, conflict: project.conflict, syntax: marked };
    return { dialect: marked, source: 'syntax', project: named, evidence: project.evidence };
  }
  if (marked) return { dialect: marked, source: 'syntax' };
  if (project?.ambiguous) return { dialect: null, source: 'ambiguous', ambiguous: project.ambiguous };
  return { dialect: 'postgres', source: 'assumed' };
};
