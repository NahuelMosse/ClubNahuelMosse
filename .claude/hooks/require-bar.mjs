#!/usr/bin/env node
// PreToolUse on Edit and Write: production code is not written while the plan of the card in
// progress lacks its `## Bar` —every criterion of .claude/reference/criteria.md, with how it is met
// or why it does not apply—, its `## Edges` —the catalog of failures—, `## Changes to existing behavior`,
// `## Time plan` and `## Verification`.
// The last one exists because one run changed the method that accepted an old route without saying
// so, and another touched a file that asked not to be touched: what is not declared beforehand,
// nobody reviews afterwards.
// Measured: the agent wrote against one list and was inspected against a longer one; what was not
// on its list was left undone. Before that, between 12 and 36 % of the code was redone after the
// reviews for things the list already asked for.
// A whole area that does not apply is answered in one line with its range: `I1–I12 · not applicable · reason`.
// A File map line that names a schema or an infrastructure file also asks for `- System design: …`
// under `## Changes to existing behavior`: the data model and the infrastructure are written down
// before the code that changes them.
// With `lane: fast` the plan is the short one (`## Lane`, `## File map`, `## Time plan`,
// `## Verification`, `## Changes to existing behavior`) and each write is projected over the card's
// diff: one that leaves the fast lane is blocked (steps/fast-lane.md); it is also blocked when the
// module `ui` is off, because the lane is presentation only.
// Modules (`.claude/kit.json`): the bar asks for the core criteria and those of the modules that are
// on; each module that is off is answered with a line `<module> · off by decision · <reason>`. A
// module that is off and whose signal shows up in what the plan says it will touch blocks the write:
// the person turns it on or confirms it stays off (tools/kit.mjs).
// The grade (`kit.mjs grade`) leaves out whole modules and blocks of core criteria, each answered with a
// line `<block> · off by grade: <grade> — <reason>`, and below production it also lowers the multiple of
// the likely time that the cap may reach. Everything here fails closed.
// Contract: exit 0 lets it through; exit 2 blocks and Claude reads stderr. On its own error it blocks.
import { readFileSync, existsSync } from 'node:fs';
import { join, relative } from 'node:path';

const block = (reason) => {
  process.stderr.write(reason + '\n');
  process.exit(2);
};

try {
  const { NOT_PRODUCTION, IS_INFRA, IS_SCHEMA, IS_TEST, rootOf, relativeTo, currentCard, timePlanProblems, fileMapLines, pathTokens } =
    await import('../tools/card.mjs');
  const { laneOf, violations, OUT_OF_LANE, applyEdit } = await import('../tools/lane.mjs');
  const { active, lateSignals, LATE_ADVICE } = await import('../tools/kit.mjs');
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
  await (await import('../tools/card.mjs')).delegateToRepo(import.meta.url, raw, input);
  const toolInput = input.tool_input;
  const path = toolInput?.file_path ?? toolInput?.notebook_path;
  if (!path) process.exit(0);
  const root = rootOf(path);
  if (!root) process.exit(0);
  const rel = relativeTo(root, path);
  const cardDir = currentCard(root);
  if (!cardDir) process.exit(0);
  // The modules that are off by a person's decision: their criteria are not asked for, and the plan
  // says so in one line each. The grade leaves out more, with its own lines.
  const modules = active(root);

  const plan = join(cardDir, 'plan.md');
  const text = existsSync(plan) ? readFileSync(plan, 'utf8') : '';
  const lines = text.split('\n');
  const has = (title) => lines.some((l) => l.trim() === title || l.startsWith(`${title} `));
  // The cap is what the time-cap and review-cap hooks enforce: if it cannot be read, they would
  // silently do nothing, so it is asked for here, at plan time (the same reading as plan-check.mjs).
  const timePlan = () => timePlanProblems(text, modules);
  const verification = () => (has('## Verification') ? [] : ['“## Verification” (the commands for what is mechanical, one per line `name: command`, which verify.mjs runs)']);
  const changes = () => (has('## Changes to existing behavior') ? [] : ['“## Changes to existing behavior” (what the card adds, modifies or removes of what already existed —routes, methods, responses, generated files— and what stays the same)']);
  const refuse = (problems) => block(
    `Not writing ${rel} yet: the plan of the card in progress (${relative(root, plan)}) is missing ` +
    problems.join(' and ') +
    '. It is the same list the delivery is inspected with: written beforehand, it does not come back as a finding. ' +
    'The headings and formats are in .claude/templates/plan.md.');

  // The fast lane: its short plan, and what the card's diff would be once this write happens.
  const isTest = IS_TEST.test(rel) || /(^|\/)(e2e|tests?|__tests__)\//.test(rel);
  if (laneOf(text) === 'fast') {
    if (/^(specs|\.claude|\.specify)\/|\.md$/.test(rel) || isTest) process.exit(0);
    const laneModule = modules.map?.laneRequires;
    if (laneModule && modules.off.has(laneModule))
      block(`Not writing ${rel}: the fast lane is for presentation and the module ${laneModule} is off (“${modules.off.get(laneModule).reason}”). The card takes the normal lane, or ${LATE_ADVICE(laneModule).split(' or ')[0]}.`);
    const problems = [];
    if (!has('## Lane')) problems.push('“## Lane” (`lane: fast · <text|layout|style|asset> · <why it fits>`)');
    if (!has('## File map')) problems.push('“## File map” (3 production files at most, each line with `presentation`)');
    problems.push(...timePlan(), ...verification(), ...changes());
    if (problems.length) refuse(problems);
    const current = existsSync(path) ? readFileSync(path, 'utf8') : '';
    const content = input.tool_name === 'Edit' ? applyEdit(current, toolInput) : toolInput.content ?? '';
    const found = violations(root, cardDir, { file: rel, content });
    if (found.length) block(OUT_OF_LANE(found));
    process.exit(0);
  }

  if (NOT_PRODUCTION.test(rel)) process.exit(0);

  // A signal that shows up after a module was turned off is not decided by the agent: the person turns
  // the module on, or confirms it stays off with the reason.
  const late = Object.entries(lateSignals(root, cardDir));
  if (late.length)
    block(`Not writing ${rel}: ${late.map(([mod, found]) => `the module ${mod} is off (“${modules.off.get(mod).reason}”) and the card brings ${found.join('; ')}`).join('; and ')}. ` +
      `Resolve it with ${late.map(([mod]) => LATE_ADVICE(mod, modules.grade)).join('; and ')}.`);

  const problems = [];
  if (!has('## Bar')) problems.push('“## Bar” (every criterion of .claude/reference/criteria.md: how it is met or why it does not apply)');
  if (!has('## Edges')) problems.push('“## Edges” (the edge catalog of .claude/steps/05-plan.md, one line per category)');
  problems.push(...timePlan(), ...verification(), ...changes());

  // The data model and the infrastructure are described before the code that changes them.
  const map = fileMapLines(cardDir) ?? [];
  const designed = (t) => (modules.on.has('data') || !modules.known.includes('data') ? IS_SCHEMA.test(t) : false) ||
    (modules.on.has('infra') || !modules.known.includes('infra') ? IS_INFRA.test(t) : false);
  if (map.some((l) => pathTokens(l).some(designed)) && !/^\s*-\s*System design\b/im.test(text))
    problems.push('a `- System design: …` line under “## Changes to existing behavior” (the File map names a schema or infrastructure file: the data model and the infrastructure of docs/technical/system-design.md change, or `- System design: unchanged — <why>`)');

  // Every ID in the list has to appear in the bar, alone or inside a range of its area: the list is
  // known whole, nothing is skipped. The same reading runs before an implementer starts (plan-check.mjs).
  if (has('## Bar')) problems.push(...(await import('../tools/plan-check.mjs')).barProblems(root, text, modules));

  if (problems.length) refuse(problems);
} catch (e) {
  block(`Could not check the plan's bar (${e.message}). It blocks when in doubt: retry.`);
}
process.exit(0);
