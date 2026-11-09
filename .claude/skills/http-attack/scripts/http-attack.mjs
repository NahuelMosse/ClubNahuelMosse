#!/usr/bin/env node
// http-attack: adversarial probes against an HTTP API running on this machine. Run with --help for the options.
import { realpathSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { main } from './lib/cli.mjs';

// Runs when this file is the entry point, also when it is reached through a symlink or a junction.
// If the paths cannot be resolved the file still runs: a silent exit 0 would read as a clean result.
const isEntry = () => {
  try { return realpathSync(process.argv[1]) === realpathSync(fileURLToPath(import.meta.url)); } catch { return true; }
};

if (isEntry()) process.exitCode = await main(process.argv.slice(2));
