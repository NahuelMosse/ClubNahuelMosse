// RFZ: the append-only event with which a card legitimately changes a frozen test of ANOTHER card.
//   <ID>-RFZ-NN · <file>:<test or tag> · <tag of the other card> · reason: <scenario ID of this card> · change: <one line>
// One reading for the guard (which lets the write through) and for required.mjs (which asks the PR to
// list it), so what is asked to be written is what gets read.

import { existsSync, readFileSync } from 'node:fs';
import { basename, join } from 'node:path';

export const TAG_G = /@[A-Z][A-Z0-9]*-\d+-H\d+-\d+/g;
const RFZ = /^([A-Z][A-Z0-9]*-\d+)-RFZ-(\d+) · (\S+?):(\S[^·]*?) · (@?[A-Z][A-Z0-9]*-\d+-H\d+-\d+) · reason: ([^·]+?) · change: (\S.*)$/;

export const RFZ_FORMAT =
  '<ID>-RFZ-NN · <file>:<test or tag> · @<other card>-H<NN>-<NN> · reason: <scenario of this card, by ID> · change: <one line>';

export const cardIdOf = (cardDir) => basename(cardDir).match(/^[A-Z][A-Z0-9]*-\d+/)?.[0] ?? null;

const textOf = (file) => (existsSync(file) ? readFileSync(file, 'utf8') : '');

export const refreezes = (cardDir) => textOf(join(cardDir, 'ambiguities.md')).split(/\r?\n/)
  .map((line) => line.match(RFZ))
  .filter(Boolean)
  .map((m) => ({
    id: `${m[1]}-RFZ-${m[2]}`, card: m[1], file: m[3].replace(/^\.\//, ''), test: m[4].trim(),
    tag: m[5].startsWith('@') ? m[5] : `@${m[5]}`, reason: m[6].trim(), change: m[7].trim(),
  }));

// Scenario IDs of the snapshot of the card in progress: `- [ ] <ID>-H<NN>-<NN> — title`.
const scenariosOf = (cardDir) => new Set(
  [...textOf(join(cardDir, 'card.snapshot.md')).matchAll(/^\s*-\s*\[[ xX]\]\s*([A-Z][A-Z0-9]*-\d+-H\d+-\d+)\b/gm)].map((m) => m[1]));

// A test of the card itself, found wrong in step 8: the ACT that the RFZ cites says so with a critical axe finding
// on what the test locates, or with a criterion of the card that contradicts the locator. `ACT-NN · <criterion> ·
// <H|M|L> · <what fails> · close: … · <state>` in actions.md.
const AXE_CRITICAL = /\baxe\b[^·]*\b(?:critical|cr[ií]tic[oa]s?)\b/i;
const LOCATOR = /\b(?:locators?|localizador(?:es)?|selectors?|selector(?:es)?|getBy\w+)\b/i;
const actEvidence = (cardDir, reason) => {
  const cited = [...new Set(reason.match(/\bACT-\d+\b/g) ?? [])];
  if (!cited.length) return { ok: false, why: 'the reason cites no ACT-NN of step 8' };
  const lines = textOf(join(cardDir, 'actions.md')).split(/\r?\n/);
  for (const act of cited) {
    const line = lines.find((l) => l.startsWith(`${act} · `));
    if (!line) continue;
    const what = line.split(' · ')[3] ?? '';
    if (AXE_CRITICAL.test(what) || LOCATOR.test(what)) return { ok: true, act };
  }
  return { ok: false, why: `${cited.join(', ')} is not an ACT of actions.md whose evidence is a critical axe finding or a criterion of the card that contradicts the locator` };
};

// Returns { ok: true, rfz } or { ok: false, why }. `rel` is the test's path from the repo root,
// `current` its text on disk, `next` the text the write would leave.
export const refreezeVerdict = ({ cardDir, rel, current, next }) => {
  const id = cardIdOf(cardDir);
  if (!id) return { ok: false, why: 'the card in progress has no ID in its folder name' };
  const tags = [...new Set(current.match(TAG_G) ?? [])];
  const own = tags.filter((t) => t.startsWith(`@${id}-H`));
  const scenarios = scenariosOf(cardDir);
  const candidates = refreezes(cardDir).filter((r) => r.card === id && r.file === rel && (own.length ? own : tags).includes(r.tag));
  if (!candidates.length) return { ok: false, why: `no ${id}-RFZ-NN names ${rel} with ${own.length ? 'a tag of this card' : 'one of its tags'} (${(own.length ? own : tags).join(', ')})` };
  const rfz = candidates.find((r) => (r.reason.match(/[A-Z][A-Z0-9]*-\d+-H\d+-\d+/g) ?? []).some((s) => s.startsWith(`${id}-H`) && scenarios.has(s)));
  if (!rfz) return { ok: false, why: `the reason of ${candidates[0].id} cites no scenario of ${id}'s snapshot (\`- [ ] ${id}-H<NN>-<NN> — …\`)` };
  if (own.length) {
    const evidence = actEvidence(cardDir, rfz.reason);
    if (!evidence.ok) return { ok: false, why: `it holds tests of this card (${id}): ${evidence.why}` };
  }
  const dropped = tags.filter((t) => !next.includes(t));
  if (dropped.length) return { ok: false, why: `the new content drops ${dropped.join(', ')}: the change keeps every tag of the file; it does not delete tests` };
  return { ok: true, rfz };
};

// A frozen test whose cleanup is wrong (a temporary folder deleted before the server that holds a file in it is closed:
// EPERM on Windows) is repaired when the edit moves no line the freeze is about: an assertion (`assert`, `expect`,
// `t.assert`, `.should`, with the lines of a statement that spans several), a title of `test(`/`it(`/`describe(`, or a
// tag (`@<ID>-H…`, `@assumption:`, `@no-sentinel`). An `ACT-NN` line of actions.md naming the file and saying cleanup or
// teardown declares it. Anything else of the test stays frozen.
const ASSERTION = /\b(?:assert|expect)\b|\bt\.assert\b|\.should\b/;
const TITLE = /\b(?:test|it|describe)(?:\.\w+)*\s*\(/;
const TAGGED = /@(?:[A-Z][A-Z0-9]*-\d+-H\d+-\d+|assumption:|no-sentinel)/;
const depthOf = (text) => [...text].reduce((n, c) => n + (c === '(' ? 1 : c === ')' ? -1 : 0), 0);

export const frozenLines = (text) => {
  const lines = text.split(/\r?\n/).map((l) => l.trim());
  const out = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (ASSERTION.test(line)) {
      out.push(line);
      let depth = depthOf(line);
      while (depth > 0 && i + 1 < lines.length) { out.push(lines[++i]); depth += depthOf(lines[i]); }
    } else if (TITLE.test(line)) {
      out.push(line);
      if (/\($/.test(line) && i + 1 < lines.length) out.push(lines[++i]);
    } else if (TAGGED.test(line)) out.push(line);
  }
  return out;
};

export const CLEANUP_ADVICE =
  'A change that moves no assertion, title or tag —the order of a teardown— is allowed when an `ACT-NN` line of actions.md names the file ' +
  'and says cleanup or teardown (`ACT-NN · <criterion> · L · the teardown of <file> … · close: <command> · open`).';

export const cleanupVerdict = ({ cardDir, rel, current, next }) => {
  const declared = textOf(join(cardDir, 'actions.md')).split(/\r?\n/)
    .some((l) => /^ACT-\d+ · /.test(l) && l.includes(rel) && /clean-?up|tear-?down/i.test(l));
  if (!declared) return { ok: false, why: `no ACT of actions.md names ${rel} and says cleanup or teardown` };
  const before = frozenLines(current);
  const after = frozenLines(next);
  if (before.length !== after.length || before.some((l, i) => l !== after[i])) return { ok: false, why: 'the change moves an assertion, a title or a tag' };
  return { ok: true };
};

// KIT: the append-only event of a kit update while the card is open (`install.mjs --update --card-open`).
//   <ID>-KIT-NN · kit <old commit> → <new commit> · reason: <why the card needs it>
export const kitUpdates = (cardDir) => textOf(join(cardDir, 'ambiguities.md')).split(/\r?\n/)
  .map((line) => line.match(/^([A-Z][A-Z0-9]*-\d+)-KIT-(\d+) · /))
  .filter(Boolean)
  .map((m) => `${m[1]}-KIT-${m[2]}`);

export const kitEventLine = (cardDir, from, to, reason) => {
  const id = cardIdOf(cardDir);
  const n = String(kitUpdates(cardDir).length + 1).padStart(2, '0');
  return `${id}-KIT-${n} · kit ${from} → ${to} · reason: ${reason}\n`;
};

export const kitSectionMissing = (cardDir, closingText) => {
  const found = kitUpdates(cardDir);
  if (!found.length || /^#{2,3}\s+Kit updated during the card\b/im.test(closingText)) return null;
  return `closing.md has the section “## Kit updated during the card”: the commits and the reason of each of ${found.join(', ')}, and what the card needed from the new kit · write in closing.md: \`## Kit updated during the card\` and, for each, \`- ${found[0]}: kit <old commit> → <new commit> · reason: <why> · needed: <what the card needed from the new kit>\``;
};

// The PR lists them: closing.md has `## Refrozen tests` when the card has any RFZ.
export const refrozenSectionMissing = (cardDir, closingText) => {
  const found = refreezes(cardDir);
  if (!found.length || /^#{2,3}\s+Refrozen tests\b/im.test(closingText)) return null;
  return `closing.md has the section “## Refrozen tests”: file, tag, why and a short diff for each of ${found.map((r) => r.id).join(', ')} — the person reviewing the PR reads it there · write in closing.md: \`## Refrozen tests\` and, for each, \`- <file> · <tag of the other card> · <why: the scenario of this card that forces it> · <git diff --stat output>\``;
};
