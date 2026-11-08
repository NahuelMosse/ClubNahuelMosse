// Command line of rehearse and rehearse-sqlite: arguments and exit code (0 clean, 1 problems, 2 could not run).
import { RehearsalUsageError, rehearse } from './rehearse.mjs';
import { DEFAULT_LOCK_BUDGET_MS, parseDuration, parseEngine, rehearseDocker } from './rehearse-docker.mjs';

export const usage = (name) => `usage: ${name} [--engine <engine>] <database.sqlite | seed.sql> <migration.sql>... [--down [<down.sql>...]] [options]

  --engine <engine>   sqlite (default) | postgres:<tag> | mysql:<tag> | mariadb:<tag> | mssql:<tag> | oracle:<tag> |
                      db2:<tag>, for example postgres:16, mysql:8.4, mssql:2022-CU14-ubuntu-22.04, oracle:23.5-slim or db2:11.5.9.0.
                      A server engine runs a throwaway Docker container (name msafe-rehearse-*)
                      that is reached with docker exec only and removed at the end, also on failure, Ctrl+C or SIGTERM
  --edition <e>       mssql: standard (default, Express or Standard Developer) | enterprise (Developer);
                      oracle: se2 (default, not emulated: Oracle Free has the Enterprise features) | ee
  <database | seed>   sqlite: a database file (copied, never written) or a .sql seed loaded into an empty one;
                      server engines: a .sql seed (.sql.gz too), loaded strictly
  --dump <file>       server engines: a pg_dump (plain, custom format) or mysqldump file, optionally .gz,
                      loaded with errors tolerated and counted; then every positional argument is a migration
  --down [files]      after the ups run the downs in reverse, then the ups again; with no files, the down
                      sections of the migrations themselves (goose, dbmate, sql-migrate)
  --runner <id>       how the runner executes files (transaction wrapping); default: detected
  --allow-loss <list> table or table.column names whose loss is intended, comma separated
  --lock-budget <t>   server engines: longest a write-blocking lock may be held (default 2s; 500ms, 2s, 2)
  --keep              server engines: leave the container running and print how to connect and remove it
  --disk              server engines: keep the data on the container's disk instead of in memory (the default
                      for seeds up to 256 MB; larger seeds use the disk anyway)
  --foreign-keys on|off   sqlite: override the runner's PRAGMA foreign_keys
  -h, --help

exit: 0 all ran and nothing was lost, 1 a migration failed, lost data or held a lock over the budget,
      2 could not run (bad arguments, docker missing or unreachable, image not pullable)
sqlite needs Node 22.13+ (node:sqlite); server engines need only the docker CLI`;

const parseArgs = (argv) => {
  const opts = { engine: 'sqlite', source: null, dump: false, ups: [], downs: null, runner: null, foreignKeys: null, allowLoss: [], lockBudgetMs: null, keep: false, help: false };
  let mode = 'up';
  const value = (i, flag) => {
    if (i + 1 >= argv.length) throw new RehearsalUsageError(`${flag} needs a value`);
    return argv[i + 1];
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') opts.help = true;
    else if (a === '--down') { mode = 'down'; opts.downs = []; }
    else if (a === '--runner') opts.runner = value(i++, a);
    else if (a === '--engine') opts.engine = value(i++, a);
    else if (a === '--edition') opts.edition = value(i++, a).toLowerCase();
    else if (a === '--dump') {
      if (opts.source !== null) throw new RehearsalUsageError(`--dump ${value(i, a)} would replace the seed or migration already given (${opts.source}): put --dump before the migrations, and give no other seed`);
      opts.source = value(i++, a);
      opts.dump = true;
    }
    else if (a === '--keep') opts.keep = true;
    else if (a === '--disk') opts.disk = true;
    else if (a === '--lock-budget') opts.lockBudgetMs = parseDuration(value(i++, a));
    else if (a === '--foreign-keys') {
      opts.foreignKeys = value(i++, a);
      if (!['on', 'off'].includes(opts.foreignKeys)) throw new RehearsalUsageError('--foreign-keys takes on or off');
    } else if (a === '--allow-loss') opts.allowLoss = value(i++, a).split(',').map((s) => s.trim()).filter(Boolean);
    else if (a.startsWith('--')) throw new RehearsalUsageError(`unknown option ${a}`);
    else if (opts.source === null) opts.source = a;
    else if (mode === 'down') opts.downs.push(a);
    else opts.ups.push(a);
  }
  if (opts.downs && !opts.downs.length) opts.downs = 'sections';
  return opts;
};

export const runRehearseCli = async (argv, { out = (s) => console.log(s), err = (s) => console.error(s), name = 'rehearse.mjs' } = {}) => {
  try {
    const opts = parseArgs(argv);
    if (opts.help) { out(usage(name)); return 0; }
    if (opts.engine === 'sqlite') {
      for (const [flag, used] of [['--edition', opts.edition !== undefined], ['--dump', opts.dump], ['--keep', opts.keep], ['--lock-budget', opts.lockBudgetMs !== null], ['--disk', opts.disk === true]])
        if (used) throw new RehearsalUsageError(`${flag} needs a server engine: --engine postgres:<tag>, mysql:<tag>, mariadb:<tag>, mssql:<tag>, oracle:<tag> or db2:<tag>`);
      return await rehearse(opts, out);
    }
    const { kind } = parseEngine(opts.engine);
    const editions = { mssql: ['standard', 'enterprise'], oracle: ['se2', 'ee'] }[kind];
    if (opts.edition && !editions) throw new RehearsalUsageError(`--edition applies to mssql (standard, enterprise) and oracle (se2, ee), not to ${kind}`);
    if (opts.edition && !editions.includes(opts.edition)) throw new RehearsalUsageError(`--edition for ${kind} takes ${editions.join(' or ')} (got "${opts.edition.slice(0, 20)}")`);
    if (opts.foreignKeys) throw new RehearsalUsageError('--foreign-keys is a SQLite option');
    return await rehearseDocker({ ...opts, lockBudgetMs: opts.lockBudgetMs ?? DEFAULT_LOCK_BUDGET_MS }, out);
  } catch (e) {
    err(`could not run: ${e instanceof RehearsalUsageError ? e.message : (e.stack ?? e.message)}`);
    return 2;
  }
};
