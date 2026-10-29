#!/usr/bin/env node
// log.mjs <card-dir> "<line>" ["<line>" ...] — appends lines at the end of `## Log` of the card's card.md, numbered and dated:
// `- L<n> · <today> · <line>`. A line that already starts with `- L<n> ·` or with its date keeps its text and gets the next
// number. The way to add to the Log without reading card.md first: an Edit needs a Read of the whole card, and a `>>` from the
// shell is refused by guard-shell (it cannot tell an append from a rewrite). Measured: 36 of 52 refused shell writes of
// card.md in one repo were Log lines appended with `cat >>` or `printf >>`.
// Exits 0 with the lines written, 2 on a wrong call (no card.md, no `## Log`, a line with a line break or a heading).
import { readFileSync, writeFileSync } from 'node:fs';
import { isAbsolute, join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { CARD_FILE, logOf } from './card-doc.mjs';

const NUMBERED = /^\s*[-*]\s*L(\d+)\b/gm;
const today = () => new Date().toISOString().slice(0, 10);

export const appendLog = (cardDir, lines, date = today()) => {
  const path = join(cardDir, CARD_FILE);
  let doc;
  try { doc = readFileSync(path, 'utf8'); } catch { return { code: 2, message: `${path}: no card.md here` }; }
  if (!/^## Log\b/m.test(doc)) return { code: 2, message: `${path} has no \`## Log\`: it is the last section of the card` };
  if (!lines.length) return { code: 2, message: 'usage: node .claude/tools/log.mjs <card-dir> "<line>" ["<line>" ...]' };
  const bad = lines.find((l) => /[\r\n]/.test(l) || /^\s*#/.test(l) || !l.trim());
  if (bad !== undefined) return { code: 2, message: `A Log line is one non-empty line and not a heading: pass each line as its own argument (${JSON.stringify(bad.slice(0, 60))})` };
  let n = Math.max(0, ...[...logOf(doc).matchAll(NUMBERED)].map((m) => Number(m[1])));
  const written = lines.map((l) => {
    const text = l.trim().replace(/^[-*]\s*/, '').replace(/^L\d+\s*·\s*/, '');
    return `- L${++n} · ${/^\d{4}-\d{2}-\d{2}\s*·/.test(text) ? text : `${date} · ${text}`}`;
  });
  writeFileSync(path, `${doc}${doc.endsWith('\n') ? '' : '\n'}${written.join('\n')}\n`);
  return { code: 0, written };
};

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [dir, ...lines] = process.argv.slice(2);
  if (!dir) { console.error('usage: node .claude/tools/log.mjs <card-dir> "<line>" ["<line>" ...]'); process.exit(2); }
  const r = appendLog(isAbsolute(dir) ? dir : resolve(process.cwd(), dir), lines);
  if (r.code) { console.error(r.message); process.exit(r.code); }
  console.log(r.written.join('\n'));
}
