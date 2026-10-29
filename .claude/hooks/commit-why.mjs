#!/usr/bin/env node
// PreToolUse on Bash and PowerShell: during a card, a `git commit` carries the why in its body.
// Measured: in two runs the history had only subjects, and the decision behind each change was lost.
// A single -m with no blank-line body, no second -m and no -F is blocked. Exempt: --no-edit, -C, -c
// and --reuse-message (amends and merges that keep a message), and repos without a current card.
// In the kit's own source repo the subject must also be a Conventional Commit (see tools/release.mjs).
// Contract: exit 0 lets it through, exit 2 blocks and Claude reads stderr. On its own error it blocks.
import { readFileSync, existsSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { hookCard } from '../tools/card.mjs';

const CONVENTIONAL = /^(feat|fix|perf|refactor|docs|test|chore|style|build|ci|revert)(\([^)]+\))?!?: .+/;

// The source repo of the kit has its tests and installer and no kit.json; an installed repo has kit.json.
const isKitSource = (from) => {
  let dir = resolve(from);
  for (;;) {
    if (existsSync(join(dir, '.claude', 'tools', 'install.mjs'))) {
      return existsSync(join(dir, '.claude', 'tests')) && !existsSync(join(dir, '.claude', 'kit.json'));
    }
    const up = dirname(dir);
    if (up === dir) return false;
    dir = up;
  }
};

const reject = (reason) => {
  process.stderr.write(reason + '\n');
  process.exit(2);
};

let cmd;
let cwd;
try {
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
  await (await import('../tools/card.mjs')).delegateToRepo(import.meta.url, raw, input);
  cmd = input.tool_input?.command ?? '';
  cwd = input.cwd ?? process.cwd();
} catch (e) {
  reject(`The commit check could not read the command (${e.message}). It blocks when in doubt: retry.`);
}

const start = cmd.match(/\bgit\s+(?:[^|;&\n"']*?\s)?commit\b/);
if (!start) process.exit(0);

// A heredoc message —"$(cat <<'EOF' … EOF)"— becomes one quoted word with its own text.
const flat = cmd.slice(start.index + start[0].length)
  .replace(/"\$\(\s*cat\s*<<-?\s*['"]?(\w+)['"]?\n([\s\S]*?)\n\s*\1\s*\n?\s*\)"/g, (_, __, body) => `"${body.replace(/["\\$`]/g, '')}"`);

// The words of the commit, up to the first unquoted operator.
const words = [];
let word = null;
for (let i = 0; i < flat.length; i++) {
  const c = flat[i];
  if (c === '"' || c === "'") {
    let j = i + 1;
    while (j < flat.length && flat[j] !== c) j += c === '"' && flat[j] === '\\' ? 2 : 1;
    word = (word ?? '') + flat.slice(i + 1, j);
    i = j;
  } else if (/\s/.test(c)) {
    if (c === '\n' && word === null) break;
    if (word !== null) words.push(word);
    word = null;
    if (c === '\n') break;
  } else if (/[;|&]/.test(c)) {
    break;
  } else word = (word ?? '') + c;
}
if (word !== null) words.push(word);

if (words.some((w) => /^(--no-edit|--file(=.*)?|-F.*|-C.*|-c.*|--reuse-message(=.*)?|--reedit-message(=.*)?)$/.test(w))) process.exit(0);

const messages = [];
for (let i = 0; i < words.length; i++) {
  const w = words[i];
  if (/^--message=/.test(w)) messages.push(w.slice(10));
  else if (w === '--message' || /^-[a-zA-Z]*m$/.test(w)) messages.push(words[++i] ?? '');
}

// The kit's source repo: its commits are Conventional Commits, which tools/release.mjs reads to set the version.
if (messages.length > 0 && isKitSource(cwd) && !CONVENTIONAL.test(messages[0].split('\n')[0])) {
  reject('Commits in this repo are Conventional Commits: `type(scope)!: subject`, with type feat | fix | perf | refactor | docs | test | chore | style | build | ci | revert.\n'
    + 'feat raises the minor, fix and perf the patch. A major is marked with `!` after the type (`feat(card)!: ...`) or a `BREAKING CHANGE: ...` line in the body.\n'
    + 'tools/release.mjs sets the kit version from them. Example: git commit -m "feat(release): the version follows the commits" -m "why".');
}

if (messages.length === 0 || messages.length > 1) process.exit(0);
if (/\n\s*\n\s*\S/.test(messages[0])) process.exit(0);

// Only a card in progress asks for it.
if (!hookCard(cwd, process.env, { tool_name: 'Bash', tool_input: { command: cmd } })) process.exit(0);

reject('The commit needs the why in its body: a second -m with what the change decides and why. Example: git commit -m "<subject>" -m "<why>"');
