#!/usr/bin/env node
// The same command as rehearse.mjs. Usage and options: `rehearse-sqlite.mjs --help`.
import { basename } from 'node:path';
import { runRehearseCli } from './lib/rehearse-cli.mjs';

process.exitCode = await runRehearseCli(process.argv.slice(2), { name: basename(process.argv[1]) });
