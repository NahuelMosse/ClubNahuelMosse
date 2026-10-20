// Module `ui`: what a card that touches a screen leaves as evidence. Loaded by required.mjs only when
// the module is on. Each check receives the context of required.mjs and returns the lines it finds
// missing; this file imports nothing from the other modules.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const pngsUnder = (dir) => readdirSync(dir, { recursive: true }).some((f) => /\.png$/i.test(String(f)));
const cardName = (cardDir) => cardDir.split(/[\\/]/).pop();

// The evidence a screen leaves. Measured: a card closed with the accessibility report and the
// captures “pending”; captures saved in another card's folder in 3 runs; step 9 had rules and no
// mechanism, so the audit exists, none of its cells is blank, and the judge spoke.
// Each report names who writes it (`owned`, from required.mjs): the inspector writes inspection.md and
// accessibility.md, the verdict reviewer review.md, the VISUAL-JUDGE reviewer judge.md, screen-audit.md and the captures,
// the PAIRWISE reviewer pairwise.md.
const screenEvidence = ({ cardDir, screen, procedures, without, owned = (_owner, line) => line }) => {
  if (!screen) return [];
  const card = cardName(cardDir);
  const lacking = [];
  if (!existsSync(join(cardDir, 'accessibility.md')))
    lacking.push(owned('inspector', `specs/${card}/accessibility.md, the WCAG criteria the screen change brings into play, each with its evidence (V5)`));
  if (!pngsUnder(cardDir))
    lacking.push(owned('judge', `no .png capture under specs/${card}/: save the screen's captures in that folder`));
  const audit = join(cardDir, 'screen-audit.md');
  // Where the grade leaves the audit out (poc) it is not asked.
  if (!procedures?.has('screen-audit')) {
    if (!existsSync(audit)) {
      lacking.push(owned('judge', `specs/${card}/screen-audit.md, the audit of every screen state, with no blank cell`));
    } else {
      const blank = readFileSync(audit, 'utf8').split('\n').map((l) => l.trim()).filter((l) => l.startsWith('|') && !/^[|\s:-]+$/.test(l))
        .find((l) => l.replace(/^\||\|$/g, '').split('|').some((c) => c.trim() === '' || c.trim() === '…'));
      if (blank) lacking.push(`specs/${card}/screen-audit.md has a blank cell: ${blank}`);
    }
  }
  if (!existsSync(join(cardDir, 'judge.md')))
    lacking.push(owned('judge', `specs/${card}/judge.md, the visual judge's verdict against the plan's visual brief`));
  // The blind comparison against the previous screen is a reviewer of its own (prompt `PAIRWISE`), whose file
  // says `not applicable · <reason>` when there is no previous screen. A grade without reviewer launches none.
  if (!without?.has('reviewer') && !existsSync(join(cardDir, 'pairwise.md')))
    lacking.push(owned('pairwise', `specs/${card}/pairwise.md, the blind pairwise comparison against the previous screen, in both orders`));
  return lacking;
};

// The captures of another card are its evidence, not this card's: a run of the captures project with no filter
// rewrites them. Measured: a correction round reran every capture of the repo and the diff carried the PNGs of
// earlier cards. The rounds run the captures with the card's filter (`--grep` on its views).
const otherCardsCaptures = ({ cardDir, touched }) => {
  const card = cardName(cardDir);
  return touched.filter((f) => /^specs\/[^/]+\/.*\.png$/i.test(f) && f.split('/')[1] !== card).map((f) =>
    `${f} is a capture of another card and the diff changes it: restore it with \`git checkout <base> -- ${f}\` and run the captures only with this card's filter (\`--grep\` on its views), never the whole project (V5)`);
};

export const evidence = [screenEvidence, otherCardsCaptures];

// The one width a grade with `capture-widths` captures: the phone width the card names (320, 360…),
// 390 when it names none.
const phoneWidth = (cardDir) => {
  const snapshot = join(cardDir, 'card.snapshot.md');
  return Number((existsSync(snapshot) ? readFileSync(snapshot, 'utf8') : '').match(/\b(2[89]\d|3\d\d|4[0-7]\d)\s?px\b/)?.[1] ?? 390);
};

// The fast lane: the before and after captures at both widths and in both themes.
const beforeAfterCaptures = ({ cardDir, plan, procedures }) => {
  const card = cardName(cardDir);
  const themes = /^\s*-\s*Dark mode:\s*none/im.test(plan) ? ['light'] : ['light', 'dark'];
  const out = [];
  for (const when of ['before', 'after'])
    for (const width of procedures?.has('capture-widths') ? [phoneWidth(cardDir)] : [1280, 390])
      for (const theme of themes) {
        const name = `${when}-${width}-${theme}.png`;
        if (!existsSync(join(cardDir, name))) out.push(`specs/${card}/${name}: the ${when} capture at ${width} px, ${theme} theme`);
      }
  return out;
};

// The fast lane: one accessibility line per WCAG criterion the change brings into play.
const accessibilityLines = ({ cardDir }) => {
  const card = cardName(cardDir);
  const a11y = join(cardDir, 'accessibility.md');
  return !existsSync(a11y) || !/\b\d\.\d\.\d+\b/.test(readFileSync(a11y, 'utf8'))
    ? [`specs/${card}/accessibility.md with one line per WCAG criterion the change brings into play`]
    : [];
};

// The fast lane: the overflow run, through once.mjs and passing.
const overflowRun = ({ passed }) =>
  passed(/overflow\.mjs/, [0]).length
    ? []
    : ['the output of `node .claude/tools/overflow.mjs <url> --only <selectors>` (the plan\'s `overflow:` line), run through once.mjs and passing'];

export const fast = [beforeAfterCaptures, accessibilityLines, overflowRun, otherCardsCaptures];
