#!/usr/bin/env node
// Static linter for SQL migrations. Usage and options: `migration-lint.mjs --help`.
import { runLintCli } from './lib/lint-cli.mjs';

process.exitCode = runLintCli(process.argv.slice(2));
