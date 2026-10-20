#!/usr/bin/env node
// review-range.mjs [<card folder | repo>] — read-only.
//
// What a review of the card's diff (/code-review, design-review, the inspector's diff) has to look at:
// the repo of the card in progress, its base, and the files changed since. A review that takes the
// session's cwd or `main` looks at the wrong code. Measured: a session opened in the kit's repo, with
// the card in another repo, ran /code-review over the kit; and stacked branches listed the files of
// the cards below as if they were this one's.
// The repo is the one the argument sits in; without it, the one `hookCard` finds from the cwd.
// `--base` prints only the base ref. Exits 2 when there is no card to review. The `args:` line is what the call
// to `/code-review` carries: the hook that counts the lap reads the repo from it.
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { cardFiles, cardStart, currentCard, hookCard, kitRootOf, rootOf } from './card.mjs';

export const reviewRange = (arg, cwd = process.cwd(), env = process.env) => {
  let root;
  let cardDir;
  if (arg) {
    const path = resolve(cwd, arg);
    root = (existsSync(path) && rootOf(resolve(path, '_'))) || kitRootOf(path);
    cardDir = root && currentCard(root);
  } else {
    const found = hookCard(cwd, env);
    if (found) ({ root, card: cardDir } = found);
  }
  if (!root || !cardDir) return null;
  const base = cardStart(root, cardDir);
  return { root, cardDir, base, files: cardFiles(root, base) };
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  const r = reviewRange(args.find((a) => !a.startsWith('--')));
  if (!r) {
    console.error('No card in progress found. Pass the card folder or its repo: review-range.mjs <path>.');
    process.exit(2);
  }
  if (args.includes('--base')) {
    console.log(r.base);
    process.exit(0);
  }
  const cardName = r.cardDir.split(/[\\/]/).pop();
  console.log(`repo: ${r.root}\ncard: ${r.cardDir}\nbase: ${r.base}\ndiff: git -C "${r.root}" diff ${r.base}`);
  // What `/code-review` is given: review-cap.mjs finds the card's repo in these args and counts the lap.
  console.log(`args: review the diff of repo ${r.root} (card ${cardName}) against base ${r.base}: git -C "${r.root}" diff ${r.base}`);
  console.log(`files (${r.files.length}):`);
  for (const f of r.files) console.log(`  ${f}`);
}
