// Reading of `specs/<card>/card.md`, the card's single document: `## Specs`, `## Tasks`, `## Gate` and `## Log`.
// One reading for risk.mjs (classification), verify.mjs (the gate) and card.mjs (the File map of a card with no plan).
// The tag a test carries for a spec is `@<ID>-S<n>` (the shape of the scenario tags, `@<ID>-H<NN>-<NN>`).
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

export const CARD_FILE = 'card.md';

export const readCard = (cardDir) => {
  const path = join(cardDir, CARD_FILE);
  return existsSync(path) ? readFileSync(path, 'utf8') : null;
};

// The lines of a `## <name>` section, up to the next `## ` heading. Null when the section is missing.
export const sectionOf = (text, name) => {
  const section = String(text).split(/^## /m).slice(1).find((s) => s.split('\n')[0].trim().split(/\s/)[0] === name);
  return section ? section.split('\n').slice(1).join('\n') : null;
};

// `- S1 · "quote" · acceptance: …` → { id: 'S1', text }. The ASM lines of the same section are not specs.
export const specsOf = (text) => (sectionOf(text, 'Specs') ?? '').split('\n').flatMap((line) => {
  const m = line.match(/^\s*(?:[-*]\s*)?(S\d+)\b[\s·:.-]*(.*)$/);
  return m ? [{ id: m[1], text: m[2].trim() }] : [];
});

// A file of a Tasks line may carry its role: `src/db.mjs (data)`, `src/rules.mjs (rule)`, `src/screen.mjs (presentation)`.
export const ROLES = ['presentation', 'rule', 'data'];
const ROLE_MARK = new RegExp(`([^\\s,\`]+)\`?\\s*\\((${ROLES.join('|')})\\)`, 'g');
export const rolesOf = (text) => {
  const roles = new Map();
  for (const line of (sectionOf(text, 'Tasks') ?? '').split('\n')) {
    for (const m of line.matchAll(ROLE_MARK)) roles.set(m[1].replaceAll('\\', '/'), m[2]);
  }
  return roles;
};

const TESTS_MARK = /\s*·\s*tests:/i;
// `- T1 · S1,S2 · src/a.mjs, test/a.test.mjs · tests: test/a.test.mjs "title @ID-S1"` → { id: 'T1', specs: ['S1', 'S2'], files: [...] }.
// What follows `· tests:` is the planned tests (plannedTestsOf), not files.
export const tasksOf = (text) => (sectionOf(text, 'Tasks') ?? '').split('\n').flatMap((line) => {
  const m = line.match(/^\s*(?:[-*]\s*)?(T\d+)\s*·\s*([^·]*?)\s*·\s*(.+?)\s*$/);
  if (!m) return [];
  return [{
    id: m[1],
    specs: m[2].split(/[\s,]+/).filter((s) => /^S\d+$/.test(s)),
    files: m[3].split(TESTS_MARK)[0].replace(ROLE_MARK, '$1').split(/[\s,]+/).map((f) => f.replace(/^`|`$/g, '').replaceAll('\\', '/')).filter(Boolean),
  }];
});

// The tests `## Tasks` plans: after `· tests:`, `<file> "<title with its tag>"` separated by `;` → [{ task, file, title }].
export const plannedTestsOf = (text) => (sectionOf(text, 'Tasks') ?? '').split('\n').flatMap((line) => {
  const id = line.match(/^\s*(?:[-*]\s*)?(T\d+)\s*·/)?.[1];
  const at = line.search(TESTS_MARK);
  if (!id || at < 0) return [];
  return [...line.slice(at).matchAll(/([^\s"“;:]+)\s+["“]([^"”]+)["”]/g)].map((m) => ({ task: id, file: m[1].replace(/^`|`$/g, '').replaceAll('\\', '/'), title: m[2] }));
});

// The assumptions `## Specs` declares: `<ID>-ASM-NN · <reading> · S<n>`.
export const asmsOf = (text) => [...new Set((sectionOf(text, 'Specs') ?? '').match(/[A-Z][A-Z0-9]*-\d+[A-Za-z0-9]*-ASM-\d+/g) ?? [])];

export const hasTasksSection = (text) => sectionOf(text, 'Tasks') !== null;

// The commands of the first code block of `## Gate`.
export const gateBlock = (text) => sectionOf(text, 'Gate')?.match(/```[^\n]*\n([\s\S]*?)```/)?.[1] ?? null;

// The words of the card's own text —its specs and the verbatim requirement L1— that bring risk with them.
// Whole words, with boundaries that hold for accents (`\b` does not); `rol`, `roles` and `role` do not count as the
// attribute name of an HTML `role="…"`.
const L = '[\\p{L}\\d_]';
const AUTH_PAYMENT = `auth(?:entic${L}*|oriz${L}*|n|z)?|login|log-in|contrase[nñ]a${L}*|password${L}*|token${L}*|pago${L}*|payment${L}*|sesi[oó]n|sesiones|session${L}*`;
const EDGE = (words) => `(?<![\\p{L}\\d])(${words})(?![\\p{L}\\d])`;
export const RISK_WORDS = new RegExp(EDGE(`${AUTH_PAYMENT}|migraci[oó]n${L}*|migration${L}*|permiso${L}*|permission${L}*|(?:rol|roles|role)(?!\\s*=)`), 'giu');
export const AUTH_OR_PAYMENT = new RegExp(EDGE(AUTH_PAYMENT), 'iu');

// `L1 · <verbatim requirement>` of `## Log`, the last section: everything after its heading, so a `## ` inside the
// verbatim text does not cut it. The lines that continue L1 are part of it, up to the next `L<n> ·`.
export const requirementOf = (text) => {
  const log = String(text).split(/^## Log\b.*$/m)[1] ?? '';
  const start = log.search(/^\s*(?:[-*]\s*)?L1\b/m);
  if (start < 0) return '';
  return log.slice(start).split(/^\s*(?:[-*]\s*)?L(?!1\b)\d+\b/m)[0];
};

// The spec tags a test text carries for `id`: `@<ID>-S<n>` not followed by a digit.
export const specTagsIn = (id, text) => [...String(text).matchAll(new RegExp(`@${id.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}-(S\\d+)(?!\\d)`, 'g'))].map((m) => m[1]);

// `specs/GST-208-customer-search` → `GST-208`: the ID is the `card:` line of its card.md, else the H1 of card.md,
// else the start of the folder name, with an alphanumeric suffix glued to the number (`MC-2b-edit` → `MC-2b`).
const ID_SHAPE = /^[A-Z][A-Z0-9]*-\d+[A-Za-z0-9]*$/;
export const cardIdOf = (cardDir) => {
  const folder = String(cardDir).split(/[\\/]/).filter(Boolean).pop() ?? '';
  const text = readCard(cardDir);
  if (text) {
    const header = text.match(/^card:\s*(\S+)/m)?.[1] ?? text.match(/^#\s+(\S+)/m)?.[1];
    if (header && ID_SHAPE.test(header) && folder.startsWith(header)) return header;
  }
  return folder.match(/^[A-Z][A-Z0-9]*-\d+[A-Za-z0-9]*/)?.[0] ?? null;
};

// The classification `risk.mjs` froze, or null when the card has none yet.
// What the diff raised (`escalated`, written by `risk.mjs --diff`) is what counts: review and lenses come out already raised.
export const riskOf = (cardDir) => {
  try {
    const frozen = JSON.parse(readFileSync(join(cardDir, 'risk.json'), 'utf8'));
    return frozen.escalated ? { ...frozen, review: frozen.escalated.review, lenses: frozen.escalated.lenses } : frozen;
  } catch { return null; }
};

// The text a file would have after an Edit or a Write call.
export const applyEdit = (current, input = {}) => {
  if (typeof input.content === 'string') return input.content;
  const { old_string: from = '', new_string: to = '' } = input;
  return input.replace_all ? current.replaceAll(from, to) : current.replace(from, to);
};

// What `## Log` holds, from its heading to the end of the file (the last section).
export const logOf = (text) => String(text).split(/^## Log\b.*$/m)[1] ?? '';

// Why a write to card.md is not allowed, or null: L1 never changes and `## Log` only grows at its end.
export const logViolation = (current, next) => {
  if (requirementOf(current).trim() && requirementOf(next).trim() !== requirementOf(current).trim()) return 'L1, the requirement as the card gave it, is never edited';
  const before = logOf(current).trimEnd();
  if (before.trim() && !logOf(next).startsWith(before)) return '`## Log` only grows: a line written there is not changed or removed';
  return null;
};

// The findings of judge.md: `- ACT-01 · H · <what fails> · <path:line> · open` and, once fixed, `… · closed · <output of
// the command or the test>` or `… · declared · <why it is not fixed>`.
export const actsOf = (text) => String(text).split('\n').flatMap((line) => {
  const m = line.match(/^\s*(?:[-*]\s*)?(ACT-\d+)\b(.*)$/);
  if (!m) return [];
  const parts = m[2].split('·').map((p) => p.trim()).filter(Boolean);
  const at = parts.findIndex((p) => /^(open|closed|declared)\b/i.test(p));
  const state = at < 0 ? 'open' : parts[at].toLowerCase().match(/^\w+/)[0];
  const evidence = at < 0 ? '' : [parts[at].replace(/^\w+\s*/, ''), ...parts.slice(at + 1)].join(' · ').trim();
  return [{ id: m[1], severity: parts.find((p) => /^[HML]$/.test(p)) ?? '', state, evidence, plan: parts.some((p) => /^plan$/i.test(p)), line: line.trim() }];
});

// What a plan ACT closed in the card points at: an `ASM-NN` of the card, a task `T<n>` or a Gate line.
const PLAN_EVIDENCE = /\b(?:[A-Z][A-Z0-9]*-\d+-)?ASM-\d+\b|\bT\d+\b|\bprobe\b|\battacks:|\bmigrate-upgrade\b/;

// Why an ACT still holds the close, or null. A code ACT closed carries the output of its command or test; a plan ACT closed
// carries where the card now answers it (`doc` is card.md: an `ASM-NN` it cites must be there).
export const actHold = (a, doc = null) => {
  if (a.state === 'open') return 'open';
  if (!a.evidence) return `${a.state} with no ${a.state === 'closed' ? 'output' : 'reason'}`;
  if (a.plan && a.state === 'closed') {
    if (!PLAN_EVIDENCE.test(a.evidence)) return 'a plan ACT closed in the card cites the `ASM-NN`, the task `T<n>` or the Gate line that answers it';
    const missingAsm = doc === null ? [] : (a.evidence.match(/\b(?:[A-Z][A-Z0-9]*-\d+-)?ASM-\d+\b/g) ?? []).filter((x) => !String(doc).includes(x));
    if (missingAsm.length) return `${missingAsm.join(', ')} is not in card.md`;
  }
  return null;
};

// The ACT that still hold the close: open, or `closed`/`declared` without its output or reason.
export const actsHolding = (text, doc = null) => actsOf(text).filter((a) => actHold(a, doc));

// The line `install.mjs --update --card-open` leaves in the card's `## Log`.
export const kitLogLine = (text, from, to, reason) => `- L${(String(text).match(/^\s*[-*]\s*L\d+\b/gm) ?? []).length + 1} · ${new Date().toISOString().slice(0, 10)} · kit updated ${from} → ${to} · ${reason}\n`;
