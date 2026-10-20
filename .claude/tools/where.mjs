#!/usr/bin/env node
// where.mjs — run from the repo root. Read-only.
//
// Where a card cut off by a compaction or a crash stood, deduced from what is on disk and not from
// what anyone remembers: the card, the step, the next command, the minutes since its snapshot (the
// time cap does not restart on resuming) and the `.pid` files of the cut session, which are verified
// by PID and never killed by name. With `lane: fast` in the plan it speaks in the steps of the fast
// lane (.claude/steps/fast-lane.md).
// Exits 0 whenever it could tell, 2 on its own error. The order of reading is .claude/steps/00-resume.md.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import {
  IS_TEST, NOT_PRODUCTION, cardFiles, cardStart, currentCard, git, minutesSinceSnapshot, relativeTo, capMinutes,
} from './card.mjs';
import { active } from './kit.mjs';
import { laneOf } from './lane.mjs';
import { missing } from './required.mjs';

const TEN = /^\| *(Empty case|Duplicates|Validation|Error|State|Permissions|Limits|Order|Concurrency|Trail) *\|.+[^ |]/gm;
const SCREEN = /\.(css|scss|html?|jsx|tsx|vue|svelte)$/;

const read = (path) => (existsSync(path) ? readFileSync(path, 'utf8') : '');

const committed = (root, rel) => git(root, ['ls-files', '--error-unmatch', '--', rel]).status === 0 &&
  !git(root, ['status', '--porcelain', '--', rel]).stdout.trim();

// In a commit: a file that is only staged does not count as committed.
const inGit = (root, rel) => git(root, ['cat-file', '-e', `HEAD:${rel}`]).status === 0;

const pidFiles = (root) => [root, join(root, '.validation')].filter(existsSync)
  .flatMap((dir) => readdirSync(dir).filter((f) => f.endsWith('.pid')).map((f) => relativeTo(root, join(dir, f))));

// The steps of the fast lane, in order.
export const FAST_STEPS = ['/card', 'the ten questions', 'capture before', 'the short plan', 'the edit', 'verify.mjs', 'capture after', '/close'];

// With closing.md written, what is left is publishing (the section «Publishing» of commands/close.md);
// publish.mjs leaves `<ID>-CLOSE · <date> · posted` in ambiguities.md when the comment on the card went out.
const PUBLISH = 'publish: push the card\'s branch, gh pr create, the CI result as a comment, the closing comment on Jira (.claude/commands/close.md)';
export const published = (ambiguities) => {
  const states = [...ambiguities.matchAll(/-CLOSE · [^·\n]*· (posted|failed)\b/g)].map((m) => m[1]);
  return states.at(-1) === 'posted';
};

export const where = (root) => {
  const cardDir = existsSync(join(root, 'specs')) ? currentCard(root) : null;
  const pids = pidFiles(root);
  if (!cardDir) return { card: null, step: 1, what: 'no card in progress', next: '/card <ID>', pids, minutes: null, cap: null, lane: 'normal' };
  const card = cardDir.split(/[\\/]/).pop();
  const rel = (f) => relativeTo(root, join(cardDir, f));
  const plan = read(join(cardDir, 'plan.md'));
  const ambiguities = read(join(cardDir, 'ambiguities.md'));
  const lane = laneOf(plan);
  const base = cardStart(root, cardDir);
  const production = cardFiles(root, base).filter((f) => !NOT_PRODUCTION.test(f) && !IS_TEST.test(f));
  const minutes = minutesSinceSnapshot(root, cardDir);
  const cap = plan ? capMinutes(plan) : null;
  const extra = { card, pids, minutes, cap, lane };
  let note = '';
  const at = (step, what, next) => ({ ...extra, step, what: what + note, next });
  const pngs = (prefix) => existsSync(cardDir) && readdirSync(cardDir).some((f) => f.startsWith(prefix) && f.endsWith('.png'));

  if (!/AMB-00 · .*frozen at/.test(ambiguities))
    return at(1, 'the snapshot is not frozen: no AMB-00 event with its commit', `/card ${card}`);
  if ((ambiguities.match(TEN)?.length ?? 0) < 10)
    return at(2, 'the ten questions are not all answered in ambiguities.md', 'answer the ten questions (.claude/steps/02-ambiguities.md)');
  if (lane === 'fast') {
    const hasPlan = plan && inGit(root, rel('plan.md'));
    if (hasPlan && !committed(root, rel('plan.md'))) note = ' (plan.md has uncommitted changes)';
    if (!pngs('before-')) return at(3, 'fast lane: no before capture', 'capture before-<width>-<theme>.png in specs/<card>/');
    if (!hasPlan) return at(4, 'fast lane: the short plan is not committed', 'write and commit specs/<card>/plan.md (## Lane, File map, Time plan, Verification, Changes to existing behavior)');
    if (!production.length) return at(5, 'fast lane: no edit yet', 'edit the presentation files of the File map');
    const lacking = missing(root) ?? [];
    if (lacking.some((l) => !/after-/.test(l))) return at(6, `fast lane: ${lacking.length} thing(s) missing`, 'node .claude/tools/verify.mjs');
    if (lacking.length) return at(7, 'fast lane: no after capture', 'capture after-<width>-<theme>.png in specs/<card>/');
    if (!read(join(cardDir, 'closing.md'))) return at(8, 'fast lane: verified, not closed', `/close ${card}`);
    if (published(ambiguities)) return at(8, 'fast lane: closing.md written and published', 'nothing: the card is closed');
    return at(8, 'fast lane: closing.md written', PUBLISH);
  }
  if (!/-TESTS · /.test(ambiguities)) return at(4, 'the scenarios are not frozen: no TESTS event', `/scenarios ${card}`);
  if (!plan || !inGit(root, rel('plan.md'))) return at(5, 'plan.md is missing or not committed', 'write specs/<card>/plan.md (.claude/steps/05-plan.md) and commit it');
  if (!committed(root, rel('plan.md'))) note = ' (plan.md has uncommitted changes)';
  if (!production.length) return at(6, 'no production code in the diff yet', 'launch the implementer for the first group of the File map (.claude/steps/06-implement.md)');
  const lacking = missing(root) ?? [];
  const inspected = existsSync(join(cardDir, 'inspection.md'));
  if (lacking.length && !inspected) return at(6, `${lacking.length} thing(s) missing and no inspection yet`, 'node .claude/tools/verify.mjs');
  if (/·\s*(open|suspect)\s*$/m.test(read(join(cardDir, 'actions.md'))))
    return at(8, 'actions.md has open or suspect actions', 'correct them through the implementer, then node .claude/tools/verify.mjs');
  if (!inspected || lacking.length) return at(8, `${lacking.length} thing(s) missing in the verdict`, 'node .claude/tools/verify.mjs; /validate ' + card);
  const screen = production.some((f) => SCREEN.test(f));
  if (screen && !active(root).exempt.procedures.has('screen-audit') && !existsSync(join(cardDir, 'screen-audit.md'))) return at(9, 'a screen without screen-audit.md', 'steps/m-ui-screen.md');
  if (!existsSync(join(cardDir, 'closing.md'))) return at('close', 'verified, not closed', `/close ${card}`);
  if (published(ambiguities)) return at('close', 'closing.md written and published', 'nothing: the card is closed');
  return at('close', 'closing.md written', PUBLISH);
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const w = where(process.cwd());
    console.log(w.card ? `Card: ${w.card}` : 'Card: none');
    console.log(`Lane: ${w.lane}`);
    console.log(`Step: ${w.step}${w.lane === 'fast' && typeof w.step === 'number' ? ` of ${FAST_STEPS.length} (${FAST_STEPS[w.step - 1]})` : ''} — ${w.what}`);
    console.log(`Next: ${w.next}`);
    if (w.minutes !== null) console.log(`Minutes since the snapshot: ${Math.round(w.minutes)}${w.cap ? ` of a ${w.cap} min cap: the cap does not restart on resuming` : ''}`);
    if (w.pids.length) console.log(`Processes of the cut session (verify by PID, never kill by name): ${w.pids.join(', ')}`);
  } catch (e) {
    console.error(`where.mjs failed on its own: ${e.message}`);
    process.exit(2);
  }
}
