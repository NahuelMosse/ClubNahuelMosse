#!/usr/bin/env node
// judge-context.mjs <inspector|reviewer|visual> [ID…] — run from the repo of the card, with a card in progress.
//
// Everything a judge reads of the card, in one call and in one output, so it neither guesses paths nor reads them one by one:
//   inspector  the snapshot, ambiguities.md, the plan, `bar.mjs <ID…>` (the IDs of its prompt), the card's diff since its start
//              and the files it created and git does not follow yet.
//   reviewer   the verdict reviewer: the snapshot, ambiguities.md and, of the plan, only `## Assumptions` and `## Perimeter`
//              (its source of truth is the snapshot, not the plan or the code), and the list of files the card changed.
//   visual     the VISUAL-JUDGE: the snapshot, the plan (its `## Visual brief` is what it looks against), `design/line.md`
//              and the screen files the File map names (markup, styles) and the scripts they name, whole.
// Each part is headed `=== <path or command> ===`; one that does not exist says so. The output is cut at 150000 characters
// (`KIT_JUDGE_CONTEXT_CAP`), with what was left out named. Exits 2 with no card, an unknown role or a malformed ID.
// Measured: the visual judge read the snapshot, the plan, the design line, the markup, the script and the styles in six
// separate reads, and the inspector took five calls to gather the template, snapshot, bar and diff; each call re-reads the
// whole context.
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { SCREEN_MARKUP, cardFiles, git, mapProductionFiles, relativeTo } from './card.mjs';
import { IS_SCREEN } from './signals.mjs';
import { reviewRange } from './review-range.mjs';

export const ROLES = ['inspector', 'reviewer', 'visual'];
const CAP = Number(process.env.KIT_JUDGE_CONTEXT_CAP) || 150000;
const TOOLS = import.meta.dirname;

const section = (plan, name) => {
  const found = plan.split(/^## /m).find((s) => s.startsWith(name));
  return found ? `## ${found.trimEnd()}` : `(the plan has no ## ${name})`;
};
const file = (root, rel) => {
  const path = join(root, rel);
  return { title: rel, body: existsSync(path) ? readFileSync(path, 'utf8').trimEnd() : '(does not exist)' };
};

export const parts = (role, ids, range) => {
  const { root, cardDir, base } = range;
  const rel = (name) => relativeTo(root, join(cardDir, name));
  const plan = existsSync(join(cardDir, 'plan.md')) ? readFileSync(join(cardDir, 'plan.md'), 'utf8') : '';
  const out = [file(root, rel('card.snapshot.md')), file(root, rel('ambiguities.md'))];
  if (role === 'reviewer') {
    out.push({ title: `${rel('plan.md')} (## Assumptions and ## Perimeter only)`, body: `${section(plan, 'Assumptions')}\n\n${section(plan, 'Perimeter')}` });
    out.push({ title: 'files the card changed', body: cardFiles(root, base).join('\n') || '(none)' });
  } else if (role === 'inspector') {
    out.push(file(root, rel('plan.md')));
    const bar = ids.length ? spawnSync(process.execPath, [join(TOOLS, 'bar.mjs'), ...ids], { cwd: root, encoding: 'utf8' }) : null;
    out.push({ title: `bar.mjs ${ids.join(' ')}`, body: bar ? (bar.stdout + bar.stderr).trimEnd() : '(no IDs given: pass the IDs of your prompt)' });
    const diff = git(root, ['diff', base, '--', '.', ':(exclude)specs', ':(exclude).claude']).stdout.trimEnd();
    out.push({ title: `git diff ${base}`, body: diff || '(empty)' });
    const tracked = new Set(git(root, ['diff', '--name-only', base]).stdout.split('\n'));
    const fresh = cardFiles(root, base).filter((f) => !tracked.has(f) && !f.startsWith('specs/'));
    out.push({ title: 'new files git does not follow yet', body: fresh.join('\n') || '(none)' });
  } else {
    out.push(file(root, rel('plan.md')), file(root, 'design/line.md'));
    const mapped = mapProductionFiles(root, cardDir).filter((f) => existsSync(join(root, f)));
    const text = (f) => readFileSync(join(root, f), 'utf8');
    const screens = mapped.filter((f) => IS_SCREEN.test(f) || SCREEN_MARKUP.test(text(f)));
    // A script or stylesheet a screen file names (`<script src>`, `import`, `<link href>`) is part of the screen.
    const named = mapped.filter((f) => !screens.includes(f) && screens.some((s) => text(s).includes(f.split('/').pop())));
    for (const f of [...screens, ...named]) out.push(file(root, f));
    if (!screens.length) out.push({ title: 'screen files', body: '(the File map names none that exists)' });
  }
  return out;
};

export const render = (list, cap = CAP) => {
  const left = [];
  let size = 0;
  const kept = [];
  for (const { title, body } of list) {
    const block = `=== ${title} ===\n${body}\n`;
    if (size + block.length > cap && kept.length) { left.push(title); continue; }
    kept.push(size + block.length > cap ? `${block.slice(0, cap - size)}\n[cut at ${cap} characters]\n` : block);
    size += block.length;
  }
  if (left.length) kept.push(`left out by the cap: ${left.join(', ')} (read them yourself)\n`);
  return kept.join('\n');
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [role, ...ids] = process.argv.slice(2);
  if (!ROLES.includes(role) || ids.some((id) => !/^[A-Z]\d+$/.test(id))) {
    console.error(`usage: node .claude/tools/judge-context.mjs <${ROLES.join('|')}> [ID…]`);
    process.exit(2);
  }
  const range = reviewRange();
  if (!range) {
    console.error('No card in progress found: run it from the repo of the card.');
    process.exit(2);
  }
  console.log(render(parts(role, ids, range)));
}
