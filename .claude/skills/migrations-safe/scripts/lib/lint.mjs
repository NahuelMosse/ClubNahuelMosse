// Lints a set of migration files: finds them, picks the runner profile and dialect of each, runs the rules,
// and adds the checks that need the neighbouring files (down siblings, earlier schema, git history).
import { existsSync, readdirSync, readFileSync, realpathSync, statSync } from 'node:fs';
import { basename, dirname, join, relative, resolve } from 'node:path';
import { UsageError } from './errors.mjs';
import { HistoryError, historyFindings, isMigrationFile } from './history.mjs';
import { decodeSql, flat, parse } from './parse.mjs';
import { ERROR, WARN, lintSql } from './rules.mjs';
import { PROFILES, RUNNER_IDS, DIALECTS, decideDialect, detectRunner, fileDialectDirective, profileOf, projectDialect, runnerFromMarkers, sniffDialect } from './runners.mjs';
import { learnTsql } from './mssql.mjs';
import { applySql, cloneSchema } from './schema.mjs';
import { DEFAULT_MYSQL_VERSION, learnStatement, mysqlVersionOrThrow, parseMysqlVersion } from './mysql.mjs';
import { DEFAULT_EDITION, DEFAULT_SERVER_VERSION, EDITIONS, editionOrThrow, parseServerVersion, projectServerVersion, serverVersionOrThrow } from './server-version.mjs';

const DIALECT_LABEL = { postgres: 'PostgreSQL', sqlite: 'SQLite', mysql: 'MySQL', mssql: 'SQL Server', oracle: 'Oracle', db2: 'Db2' };
const HOW_TO_SET = 'pass --dialect <name> or add `-- migration-lint: dialect <name>` to the file';

// What to tell the reader about how the dialect was chosen, when it was not stated outright or not certain.
const dialectNotes = (d) => {
  const name = DIALECT_LABEL[d.dialect];
  if (d.source === 'assumed')
    return [`dialect assumed to be ${name}: nothing in the project or the SQL names the engine; if that is wrong the ${name} rules misjudge the file — ${HOW_TO_SET}`];
  if (d.source === 'syntax' && d.project)
    return [`the syntax suggests ${name} but the project files say ${DIALECT_LABEL[d.project]} (${d.evidence}): using ${name}, the project's declaration is not strong enough to override it — ${HOW_TO_SET} if that is wrong`];
  if (d.source !== 'inferred') return [];
  const out = [`dialect ${name} inferred from ${d.evidence}; ${HOW_TO_SET} to override`];
  if (d.syntax) out.push(`the syntax suggested ${DIALECT_LABEL[d.syntax]} but the project says ${name} (${d.evidence}): using ${name}, because the migration tool is configured for it — ${HOW_TO_SET} if that is wrong`);
  if (d.conflict) out.push(`other project files point to another engine (${d.conflict.join('; ')}): using ${name}, from the most specific source (migration tool config, then .NET project, then compose file) — ${HOW_TO_SET} if that is wrong`);
  return out;
};

const DISPLAY_NAME = { mysql: 'MySQL', mssql: 'SQL Server', oracle: 'Oracle', db2: 'Db2' };

export { UsageError };

const SKIP_DIRS = new Set(['node_modules', '.git']);
export const isDownFile = (f) => /\.down\.sql$/i.test(basename(f)) || /^down\.sql$/i.test(basename(f)) || /^U\d+(?:[._]\d+)*__/.test(basename(f));

const sqlFiles = (path) => {
  if (statSync(path).isFile()) return [path];
  return readdirSync(path).filter((n) => !SKIP_DIRS.has(n)).sort().flatMap((n) => sqlFiles(join(path, n)));
};

// A down that sits next to the file: x.down.sql, folder/down.sql, Flyway's U<n>__x.sql.
const hasDownSibling = (file) => {
  const b = basename(file);
  const dir = dirname(file);
  const candidates = [];
  if (/\.up\.sql$/i.test(b)) candidates.push(join(dir, b.replace(/\.up\.sql$/i, '.down.sql')));
  if (/^up\.sql$/i.test(b)) candidates.push(join(dir, 'down.sql'));
  if (/^V\d/.test(b)) candidates.push(join(dir, b.replace(/^V/, 'U')));
  return candidates.some(existsSync);
};

// Schema of the tables as earlier migrations of the same folder left them.
const createSchemaSource = (seed, learn) => {
  const groups = new Map();
  const groupFiles = (file) => {
    if (/^migration\.sql$/i.test(basename(file))) {
      const root = dirname(dirname(file));
      return readdirSync(root).sort().map((d) => join(root, d, 'migration.sql')).filter(existsSync);
    }
    const dir = dirname(file);
    return readdirSync(dir).filter((n) => /\.sql$/i.test(n) && !isDownFile(n)).sort().map((n) => join(dir, n));
  };
  return (file) => {
    const abs = resolve(file);
    const files = groupFiles(abs);
    const idx = files.indexOf(abs);
    const key = dirname(files[0] ?? abs);
    let state = groups.get(key);
    if (!state || state.i > idx) { state = { i: 0, schema: cloneSchema(seed) }; groups.set(key, state); }
    for (; state.i < idx; state.i++) {
      const sql = decodeSql(readFileSync(files[state.i]));
      applySql(state.schema, sql, sniffDialect(sql));
      learn(sql, files[state.i]);
    }
    return cloneSchema(state.schema);
  };
};

export const loadSchemaSeed = (paths, learn = () => {}) => {
  const seed = new Map();
  for (const p of paths) {
    if (!existsSync(p)) throw new UsageError(`--schema ${p} does not exist`);
    for (const f of sqlFiles(p).filter((x) => !isDownFile(x))) {
      const sql = decodeSql(readFileSync(f));
      applySql(seed, sql, sniffDialect(sql));
      learn(sql, f);
    }
  }
  return seed;
};

// Flyway reads `V2__x.sql.conf` beside a script; executeInTransaction=false runs it outside a transaction.
const flywayNoTransaction = (file) => {
  const conf = `${file}.conf`;
  return existsSync(conf) && /^\s*executeInTransaction\s*=\s*false\s*$/im.test(readFileSync(conf, 'utf8'));
};

// git reports the repository's real path; the working directory may sit behind a symlink (macOS /var → /private/var).
// Resolve the deepest existing ancestor, so deleted files still get a path relative to the working directory.
const realPath = (path) => {
  try {
    return realpathSync(path);
  } catch (e) {
    if (e.code !== 'ENOENT') throw e;
    const parent = dirname(path);
    return parent === path ? path : join(realPath(parent), basename(path));
  }
};

const relPath = (file) => relative(realPath(process.cwd()), realPath(resolve(file))).replaceAll('\\', '/') || file;

// opts: { paths, stdin (string|null), dialect, runner, history, repo, base, schema: [] }
export const lintTargets = (opts) => {
  if (opts.runner && !RUNNER_IDS.includes(opts.runner)) throw new UsageError(`unknown runner ${opts.runner} (${RUNNER_IDS.join(', ')})`);
  if (opts.dialect && !DIALECTS.includes(opts.dialect)) throw new UsageError(`unknown dialect ${opts.dialect} (${DIALECTS.join(', ')})`);
  const findings = [];
  const notes = [];
  let history = null;
  let paths = [...opts.paths];
  let fresh = new Set();
  const repo = resolve(opts.repo ?? '.');
  if (opts.history) {
    history = historyFindings(repo, opts.base, { runner: opts.runner });
    findings.push(...history.findings.map((f) => ({ ...f, file: relPath(resolve(repo, f.file)) })));
    fresh = new Set(history.fresh.map((f) => resolve(repo, f)));
    if (!paths.length) paths = history.fresh.filter((f) => /\.sql$/i.test(f)).map((f) => join(repo, f));
    for (const f of history.fresh.filter((x) => !/\.sql$/i.test(x) && isMigrationFile(x))) {
      const hint = PROFILES[opts.runner ?? detectRunner(join(repo, dirname(f))).id].hint;
      findings.push({ level: WARN, rule: 'unlinted-migration', file: relPath(resolve(repo, f)), line: 1, message: `${f} is not SQL, so the linter did not read it: lint the SQL its runner produces (pipe it to \`migration-lint.mjs -\`)${hint ? `, for example \`${hint}\`` : ''}` });
    }
  }

  const inputs = [];
  if (opts.stdin !== null && opts.stdin !== undefined) inputs.push({ label: '<stdin>', sql: opts.stdin, file: null });
  const list = paths.filter((p) => p !== '-').flatMap((p) => {
    if (!existsSync(p)) throw new UsageError(`${p} does not exist`);
    return sqlFiles(p).filter((f) => /\.sql$/i.test(f) && !isDownFile(f));
  });
  const sorted = [...new Set(list.map((f) => resolve(f)))].sort();
  for (const f of sorted) inputs.push({ label: relPath(f), sql: decodeSql(readFileSync(f)), file: f });

  if (!inputs.length) {
    if (opts.history && !opts.paths.length) {
      const unread = history.fresh.filter(isMigrationFile);
      if (unread.length) throw new UsageError(`${unread.length} new migration file(s) (${unread.slice(0, 3).join(', ')}) but none is SQL, so nothing was linted: pipe the SQL their runner produces to \`migration-lint.mjs -\` (with --history to keep the git checks)`);
      notes.push(`no new migrations since ${history.base.label} (merge-base ${history.base.mergeBase.slice(0, 8)})`);
    } else {
      const hint = opts.paths.map((p) => (existsSync(p) ? detectRunner(p) : null)).find((d) => d && PROFILES[d.id].generatesSql);
      throw new UsageError(`0 SQL migration files found in ${opts.paths.join(', ') || 'the arguments'}, so nothing was checked${hint ? `: ${PROFILES[hint.id].label} generates its SQL at run time — pipe it to \`migration-lint.mjs -\` (${PROFILES[hint.id].hint})` : ''}`);
    }
  }

  if (opts.mysqlVersion) mysqlVersionOrThrow(opts.mysqlVersion);
  const requestedFor = (dialect) => {
    const text = dialect === 'mysql' ? (opts.mysqlVersion ?? opts.serverVersion) : opts.serverVersion;
    return text ? { v: serverVersionOrThrow(dialect, text), flag: dialect === 'mysql' && opts.mysqlVersion ? '--mysql-version' : '--server-version' } : null;
  };
  const versionOfDir = new Map();
  // What earlier files and --schema files taught about ENUMs, indexes, column types and instant row versions.
  const shared = { instantVersions: new Map(), enums: new Map(), indexed: new Map(), defs: new Map(), reorgUnits: new Map(), tsql: new Map() };
  const serverNow = { v: parseMysqlVersion(opts.mysqlVersion ?? opts.serverVersion) ?? parseMysqlVersion(DEFAULT_MYSQL_VERSION) };
  const linted = new Set(); // files the rules already learned from, so replaying them would count twice
  const learn = (sql, file) => {
    if (file && linted.has(file)) return;
    const dialect = decideDialect(sql, { dialect: opts.dialect, project: file ? projectDialect(file) : undefined }).dialect;
    if (dialect === 'mssql') { for (const s of parse(sql, { dialect }).statements) learnTsql(flat(s.text), shared.tsql); return; }
    if (dialect !== 'mysql') return;
    for (const s of parse(sql, { dialect }).statements) learnStatement(flat(s.text), shared, serverNow.v);
  };
  const seed = loadSchemaSeed(opts.schema ?? [], learn);
  const schemaOf = createSchemaSource(seed, learn);
  const createdBefore = new Set();
  const dialectOfDir = new Map();
  let editionUsed = false;
  for (const input of inputs) {
    const markers = parse(input.sql).markers;
    const detected = input.file ? detectRunner(input.file, { markers, fileName: basename(input.file) }) : (runnerFromMarkers(markers) ?? { id: 'raw' });
    const profile = profileOf(opts.runner ?? detected.id);
    if (input.file && !dialectOfDir.has(dirname(input.file))) dialectOfDir.set(dirname(input.file), projectDialect(input.file));
    const project = input.file ? dialectOfDir.get(dirname(input.file)) : undefined;
    const decided = decideDialect(input.sql, { dialect: opts.dialect, project });
    if (decided.source === 'ambiguous')
      throw new UsageError(`cannot tell which database engine ${input.label} is for: the project files name more than one (${decided.ambiguous.join('; ')}) and the SQL has no engine-specific syntax — ${HOW_TO_SET}`);
    const dialect = decided.dialect;
    const projectDialectHere = project?.dialect ?? undefined;
    for (const n of dialectNotes(decided)) if (!notes.includes(n)) notes.push(n);
    const dirKey = input.file ? `${dirname(input.file)}|${dialect}` : null;
    if (dirKey && !versionOfDir.has(dirKey)) versionOfDir.set(dirKey, projectServerVersion(dirname(input.file), dialect));
    const declared = dirKey ? versionOfDir.get(dirKey) : null;
    const requested = requestedFor(dialect);
    const serverVersion = requested?.v ?? declared?.version ?? parseServerVersion(dialect, DEFAULT_SERVER_VERSION[dialect]);
    const mysqlVersion = dialect === 'mysql' ? serverVersion : undefined;
    const edition = EDITIONS[dialect] ? (opts.edition ? editionOrThrow(dialect, opts.edition) : DEFAULT_EDITION[dialect]) : null;
    if (edition && opts.edition) editionUsed = true;
    if (mysqlVersion) serverNow.v = mysqlVersion;
    const schema = input.file ? schemaOf(input.file) : cloneSchema(seed);
    if (input.file) linted.add(input.file);
    const r = lintSql(input.sql, {
      dialect, projectDialect: projectDialectHere, profile,
      schema, createdBefore,
      generated: !input.file, noTransaction: input.file ? flywayNoTransaction(input.file) : false,
      serverVersion, edition, ...(mysqlVersion ? { mysqlVersion } : {}), ...shared,
    });
    if (r.dialect !== 'postgres' && r.dialect !== 'sqlite') {
      const source = requested ? requested.flag : declared ? declared.evidence : `default, pass ${r.dialect === 'mysql' ? '--mysql-version' : '--server-version'} to change it`;
      const editionNote = edition ? `, ${edition} edition, ${opts.edition ? 'from --edition' : 'the conservative default, pass --edition to change it'}` : '';
      const note = `${DISPLAY_NAME[r.dialect]} rules assume ${serverVersion.label} (${source})${editionNote}`;
      if (!notes.includes(note)) notes.push(note);
      if (!requested && declared?.conflict) {
        const warning = `the server versions declared next to the migrations disagree (${declared.conflict.join(', ')}): using the oldest, ${serverVersion.label}, so the rules hold on every one of them — pass ${r.dialect === 'mysql' ? '--mysql-version' : '--server-version'} to choose`;
        if (!notes.includes(warning)) notes.push(warning);
      }
    }
    if (!input.file && r.statements === 0) throw new UsageError('stdin held no SQL statements, so nothing was checked');
    if (input.file && fresh.has(input.file)) r.createdTables.forEach((t) => createdBefore.add(t));
    findings.push(...r.findings.map((f) => ({ ...f, file: input.label })));
    if (profile.downs && input.file && !r.hasDownSection && !r.markers.rollback && !r.irreversible && !hasDownSibling(input.file))
      findings.push({ level: WARN, rule: 'missing-down', file: input.label, line: 1, message: 'no way back: add a down (x.down.sql, down.sql, a Down section) that runs, or declare `-- migration-lint: irreversible -- <recovery plan>`' });
  }

  if (opts.edition && !editionUsed) editionOrThrow('postgres', opts.edition);
  const errors = findings.filter((f) => f.level === ERROR).length;
  return {
    files: inputs.length, errors, warnings: findings.length - errors, findings, notes,
    history: history ? { base: history.base.label, mergeBase: history.base.mergeBase, tip: history.base.tip } : null,
  };
};

export { HistoryError };
