// Command line of migration-lint: arguments, stdin, output, exit code (0 clean, 1 findings, 2 could not run).
import { readFileSync } from 'node:fs';
import { HistoryError, UsageError, lintTargets } from './lint.mjs';
import { FORMATS, exitCodeFor, parseFailOn, renderFailure, renderResult } from './report.mjs';
import { decodeSql } from './parse.mjs';

export const USAGE = `usage: migration-lint.mjs <file|dir|->... [options]

  --dialect postgres|sqlite|mysql|mssql|oracle|db2
                                    default: from the file, the project (migration_lock.toml, drizzle config, flyway/liquibase/
                                    Spring jdbc URL, .sqlproj, EF Core provider, Flyway module, compose image) or its syntax;
                                    PostgreSQL is assumed, and said so, when nothing names the engine; project files that
                                    name several engines (and no syntax decides) are exit 2
  --runner <id>                     prisma|drizzle|flyway|liquibase|goose|dbmate|golang-migrate|atlas|alembic|django|knex|
                                    efcore|dbup|sqlpackage|raw; default: detected from the project's config files
  --server-version <v>              server the rules assume: MySQL 8.0 (default), 8.0.28, 8.4, 5.7, mariadb-10.6;
                                    SQL Server 2022 (default), 2016, 2019, 2025; Oracle 19 (default), 12.1, 23; Db2 11.5
                                    (default), 11.1. Default: the image in a compose file or CI workflow next to the migrations
  --mysql-version <v>               same as --server-version, for MySQL and MariaDB files only
  --edition <e>                     standard (default) | enterprise | azure for SQL Server; se2 (default) | ee for Oracle.
                                    The default is the conservative edition: a Developer image does not prove production
  --history                         also run the git checks; with no paths, lint the migrations new in the branch
  --repo <dir>                      repository for --history (default: the cwd)
  --base <ref>                      base for --history (default: origin/main, origin/master, main, master)
  --schema <file|dir>               SQL that defines the tables as they are before the migrations (rebuild checks)
  --fail-on <list>                  warning, error and/or rule ids, comma separated (default: error)
  --strict                          same as --fail-on warning
  --format text|json|sarif|github   default: text (--json is --format json)
  -                                 read one migration from stdin
  -h, --help                        this text

exit: 0 nothing at the failure level, 1 findings, 2 could not run (never a pass)`;

const parseArgs = (argv) => {
  const opts = { paths: [], format: 'text', failOn: null, history: false, schema: [], help: false };
  const value = (i, flag) => {
    if (i + 1 >= argv.length || (argv[i + 1].startsWith('--') && argv[i + 1].length > 2)) throw new UsageError(`${flag} needs a value`);
    return argv[i + 1];
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') opts.help = true;
    else if (a === '--dialect') opts.dialect = value(i++, a);
    else if (a === '--runner') opts.runner = value(i++, a);
    else if (a === '--mysql-version') opts.mysqlVersion = value(i++, a);
    else if (a === '--server-version') opts.serverVersion = value(i++, a);
    else if (a === '--edition') opts.edition = value(i++, a);
    else if (a === '--repo') opts.repo = value(i++, a);
    else if (a === '--base') opts.base = value(i++, a);
    else if (a === '--schema') opts.schema.push(value(i++, a));
    else if (a === '--fail-on') opts.failOn = parseFailOn(value(i++, a));
    else if (a === '--format') opts.format = value(i++, a);
    else if (a === '--strict') opts.failOn = parseFailOn('warning');
    else if (a === '--json') opts.format = 'json';
    else if (a === '--history') opts.history = true;
    else if (a !== '-' && a.startsWith('-')) throw new UsageError(`unknown option ${a}`);
    else opts.paths.push(a);
  }
  if (!FORMATS.includes(opts.format)) throw new UsageError(`unknown format ${opts.format} (${FORMATS.join(', ')})`);
  if (!opts.paths.length && !opts.history && !opts.help) throw new UsageError('no files given');
  return opts;
};

// The requested format, read before the arguments are validated so a failure can still be reported in it.
const formatFrom = (argv) => {
  if (argv.includes('--json')) return 'json';
  const i = argv.indexOf('--format');
  return i !== -1 && FORMATS.includes(argv[i + 1]) ? argv[i + 1] : 'text';
};

export const runLintCli = (argv, { out = (s) => console.log(s), err = (s) => console.error(s), name = 'migration-lint.mjs' } = {}) => {
  const format = formatFrom(argv);
  try {
    const opts = parseArgs(argv);
    if (opts.help) { out(USAGE.replace('usage: migration-lint.mjs', `usage: ${name}`)); return 0; }
    opts.stdin = opts.paths.includes('-') ? decodeSql(readFileSync(0)) : null;
    const result = lintTargets(opts);
    out(renderResult(result, opts.format));
    return exitCodeFor(result.findings, opts.failOn ?? undefined);
  } catch (e) {
    const known = e instanceof UsageError || e instanceof HistoryError;
    (format === 'text' ? err : out)(renderFailure(known ? e.message : `unexpected error: ${e.stack ?? e.message}`, format));
    return 2;
  }
};
