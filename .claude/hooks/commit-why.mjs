#!/usr/bin/env node
// PreToolUse on Bash and PowerShell: during a card, a `git commit` carries the why in its body.
// Measured: in two runs the history had only subjects, and the decision behind each change was lost.
// A single -m with no blank-line body, no second -m and no -F is blocked. Exempt: --no-edit, -C, -c
// and --reuse-message (amends and merges that keep a message), and repos without a current card.
// Contract: exit 0 lets it through, exit 2 blocks and Claude reads stderr. On its own error it blocks.
import { readFileSync } from 'node:fs';
import { hookCard } from '../tools/card.mjs';

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
if (messages.length === 0 || messages.length > 1) process.exit(0);
if (/\n\s*\n\s*\S/.test(messages[0])) process.exit(0);

// Only a card in progress asks for it.
if (!hookCard(cwd, process.env, { tool_name: 'Bash', tool_input: { command: cmd } })) process.exit(0);

reject('The commit needs the why in its body: a second -m with what the change decides and why.');
