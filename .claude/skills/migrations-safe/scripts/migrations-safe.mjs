#!/usr/bin/env node
// The package's one command: `migrations-safe lint ...` and `migrations-safe rehearse ...`. Usage: `migrations-safe --help`.
import { runLintCli } from './lib/lint-cli.mjs';
import { runRehearseCli } from './lib/rehearse-cli.mjs';
import { expandArgsFromEnv } from './lib/args-env.mjs';
import { UsageError } from './lib/errors.mjs';

const USAGE = `usage: migrations-safe <command> [arguments]

  lint        static checks over SQL migrations and their git history; \`migrations-safe lint --help\`
  rehearse    apply migrations to a copy of a SQLite database or to a throwaway Docker database (--engine);
              \`migrations-safe rehearse --help\`

  --args-from-env NAME   (after the command) take the arguments from the environment variable NAME, split like a
                         shell would quote them but without expanding anything: for CI wrappers that hold the
                         arguments in a variable.

Exit codes: 0 nothing at the failure level, 1 findings, 2 could not run (never a pass).`;

const main = async (argv) => {
  const [command, ...rest] = argv;
  if (command === '--help' || command === '-h' || command === 'help') { console.log(USAGE); return 0; }
  if (command !== 'lint' && command !== 'rehearse') {
    console.error(command ? `unknown command: ${command}\n\n${USAGE}` : USAGE);
    return 2;
  }
  let args;
  try { args = expandArgsFromEnv(rest); } catch (e) {
    if (!(e instanceof UsageError)) throw e;
    console.error(e.message);
    return 2;
  }
  return command === 'lint'
    ? runLintCli(args, { name: 'migrations-safe lint' })
    : runRehearseCli(args, { name: 'migrations-safe rehearse' });
};

process.exitCode = await main(process.argv.slice(2));
