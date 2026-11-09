// Splits a command line held in an environment variable into arguments, the way a POSIX shell would quote it and
// without any of its expansion: `$VAR`, `$(cmd)`, backticks, `;`, `|` and `*` are ordinary characters.
// Whitespace separates words; 'single quotes' are literal; "double quotes" keep everything but `\"` and `\\`;
// outside quotes a backslash makes the next character literal.
import { UsageError } from './errors.mjs';

export const splitArgs = (text) => {
  const words = [];
  let word = null;
  let quote = null;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quote === "'") { if (c === "'") quote = null; else word += c; continue; }
    if (quote === '"') {
      if (c === '"') quote = null;
      else if (c === '\\' && (text[i + 1] === '"' || text[i + 1] === '\\')) word += text[++i];
      else word += c;
      continue;
    }
    if (c === "'" || c === '"') { quote = c; word ??= ''; continue; }
    if (c === '\\' && i + 1 < text.length) { word = (word ?? '') + text[++i]; continue; }
    if (/\s/.test(c)) { if (word !== null) { words.push(word); word = null; } continue; }
    word = (word ?? '') + c;
  }
  if (quote) throw new UsageError(`unterminated ${quote} quote in the arguments`);
  if (word !== null) words.push(word);
  return words;
};

// Replaces `--args-from-env NAME` with the words of $NAME.
export const expandArgsFromEnv = (argv, env = process.env) => {
  const i = argv.indexOf('--args-from-env');
  if (i === -1) return argv;
  const name = argv[i + 1];
  if (!name) throw new UsageError('--args-from-env needs the name of an environment variable');
  return [...argv.slice(0, i), ...splitArgs(env[name] ?? ''), ...argv.slice(i + 2)];
};
