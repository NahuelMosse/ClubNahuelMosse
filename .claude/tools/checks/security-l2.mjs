// Module `security-l2`: the ASVS matrix of the repo is the level 2 one. Loaded by required.mjs only
// when the module is on; it imports nothing from the other modules.
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

// On only when a person chose it (R10): without a manifest that says so, it does not run.
export const optIn = true;

// With the module on, specs/asvs.md declares level 2 (from templates/asvs-level-2.md) and is answered
// for the chapters the card touches (S15).
const level2Matrix = ({ root }) => {
  const matrix = join(root, 'specs', 'asvs.md');
  return !existsSync(matrix) || !/\blevel\s*2\b|\bL2\b/i.test(readFileSync(matrix, 'utf8'))
    ? ['specs/asvs.md answered with the level 2 matrix (`.claude/templates/asvs-level-2.md`): the module security-l2 is on (S15)']
    : [];
};

export const structure = [level2Matrix];
