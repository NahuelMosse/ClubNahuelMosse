#!/usr/bin/env node
// Rehearses migrations on a throwaway SQLite copy or a Docker PostgreSQL/MySQL/MariaDB. Usage: `rehearse.mjs --help`.
import { basename } from 'node:path';
import { runRehearseCli } from './lib/rehearse-cli.mjs';

process.exitCode = await runRehearseCli(process.argv.slice(2), { name: basename(process.argv[1]) });
