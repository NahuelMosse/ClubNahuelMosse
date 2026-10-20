// copy-tree.mjs — the project copy mutate.mjs works on.
//
// Everything is copied except git, the dependencies and what tools write while they run: those
// folders change under the copy's feet when another command —a Playwright suite run by verify.mjs
// in parallel— is writing and erasing them. An entry that disappears or is locked during the copy
// is skipped, not fatal: the copy is of the code, and what vanishes was never code.
import { copyFileSync, lstatSync, mkdirSync, readdirSync, readlinkSync, symlinkSync } from 'node:fs';
import { join } from 'node:path';

export const EXCLUDED = new Set([
  'node_modules', '.git', '.validation',
  'test-results', 'playwright-report', 'blob-report', 'coverage',
]);
const VANISHED = new Set(['ENOENT', 'EBUSY']);

// Returns the paths it had to skip, for whoever wants to say so.
export const copyTree = (src, dest, { copyFile = copyFileSync, skipped = [] } = {}) => {
  mkdirSync(dest, { recursive: true });
  let names;
  try { names = readdirSync(src); } catch (e) {
    if (!VANISHED.has(e.code)) throw e;
    skipped.push(src);
    return skipped;
  }
  for (const name of names) {
    if (EXCLUDED.has(name)) continue;
    const from = join(src, name);
    const to = join(dest, name);
    try {
      const stat = lstatSync(from);
      if (stat.isDirectory()) copyTree(from, to, { copyFile, skipped });
      else if (stat.isSymbolicLink()) symlinkSync(readlinkSync(from), to);
      else copyFile(from, to);
    } catch (e) {
      if (!VANISHED.has(e.code)) throw e;
      skipped.push(from);
    }
  }
  return skipped;
};
