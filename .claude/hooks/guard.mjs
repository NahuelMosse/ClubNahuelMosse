#!/usr/bin/env node
// PreToolUse: blocks what the method forbids, on any tool that names a file: reading or writing a
// secret, and the writes that lower the bar.
// A hook cannot force anything to be done; it can prevent. Only the latter goes here.
// Contract: exit 0 lets it through, exit 2 blocks and Claude reads stderr. On its own error it
// blocks: a guard that crashes and lets things through turns the rule into a suggestion.

import { readFileSync, existsSync } from 'node:fs';
import { basename, dirname } from 'node:path';
import { spawnSync } from 'node:child_process';

const reject = (reason) => {
  process.stderr.write(reason + '\n');
  process.exit(2);
};

try {
  const { IS_TEST, IS_VERIFICATION_CONFIG, isSecret, isSecretGlob, rootOf, relativeTo, currentCard, cardStart, existedAt, pathTokens } =
    await import('../tools/card.mjs');
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
  await (await import('../tools/card.mjs')).delegateToRepo(import.meta.url, raw, input);
  const data = input.tool_input ?? {};
  const tool = input.tool_name ?? '';

  // The value of a secret is set by a person: the agent neither reads nor writes it, with any tool.
  // The same message as guard-shell.mjs; `cat .env.example` lists the names and is allowed.
  const named = [data.file_path, data.notebook_path, tool === 'Grep' ? data.path : null]
    .filter((p) => typeof p === 'string' && p);
  if (named.some(isSecret) || (tool === 'Grep' && typeof data.glob === 'string' && isSecretGlob(data.glob))) {
    reject('Secrets are not read or written by the agent. The variable names are in .env.example ' +
           '(`cat .env.example`); the value is set by a person.');
  }
  // The checks below are about writing: reading a snapshot, a test or a config is allowed.
  if (['Read', 'Grep'].includes(tool)) process.exit(0);

  const path = (data.file_path ?? data.notebook_path ?? '').replaceAll('\\', '/');
  if (!path) process.exit(0);

  // The manifest of the modules is written by `kit.mjs` and `install.mjs` only: a module is turned off
  // as a decision with its reason, never by editing a file.
  if (/(^|\/)\.claude\/kit(-files)?\.json$/.test(path)) {
    reject(
      '.claude/kit.json (and kit-files.json, the hashes of its files) is the manifest of the kit\'s modules and only `node .claude/tools/kit.mjs` writes it: ' +
      '`kit.mjs on <module>`, or `kit.mjs confirm-off <module> --reason "…"`. Turning a module off is a ' +
      'person\'s decision, between cards, with its reason.'
    );
  }

  // A migration that exists in the base (the merge-base with main) is assumed applied everywhere: it is
  // not edited, a correction is a new migration. One created in this branch is not in the base.
  const { appliedMigration, IMMUTABLE_ADVICE } = await import('../tools/migrations.mjs');
  const applied = appliedMigration(path, input.cwd ?? process.cwd());
  if (applied) reject(IMMUTABLE_ADVICE(applied));

  // Blocks editing it, not creating it: step 1 of the first card has to be able to write it.
  if (/\/card\.snapshot\.md$/.test(path) && existsSync(path)) {
    reject(
      'card.snapshot.md is never edited. If the card changed: rename the current one to ' +
      'card.snapshot.<date>.md and write a new one with /card. Editing it turns what was ' +
      'red green without leaving a trace.'
    );
  }

  if (/\/ambiguities\.md$/.test(path) && tool === 'Edit') {
    reject(
      'ambiguities.md is append-only: one line per event, and a written line is not touched. ' +
      'To record a state change, add a new event at the end.'
    );
  }

  // Rule 7 — whoever implements does not lower the bar they themselves have to clear.
  // The freeze is not a declared phase: it is the red commit of step 4. A tagged test that is
  // already committed is frozen; one that has not entered git yet is being written.
  // The one exception is the fast lane: a test may replace a string literal that the card itself
  // took out of the presentation files, and lane.mjs decides whether that is all the write does.
  const TAG = /@[A-Z]+-\d+-H\d+-\d+/;
  const { TAG_G, RFZ_FORMAT, CLEANUP_ADVICE, cardIdOf, cleanupVerdict, refreezeVerdict } = await import('../tools/refreeze.mjs');
  if (IS_TEST.test(path)) {
    const root = rootOf(path);
    const cardDir = root && currentCard(root);
    const { laneOf, testWriteViolations, OUT_OF_LANE, applyEdit } = await import('../tools/lane.mjs');
    const plan = cardDir && existsSync(`${cardDir}/plan.md`) ? readFileSync(`${cardDir}/plan.md`, 'utf8') : '';
    const fast = cardDir && existsSync(path) && laneOf(plan) === 'fast';
    if (fast) {
      const content = tool === 'Edit' ? applyEdit(readFileSync(path, 'utf8'), data) : data.content ?? '';
      const found = testWriteViolations(root, cardDir, { file: relativeTo(root, path), content });
      if (found.length) reject(OUT_OF_LANE(found));
    } else {
      // A new test file with this card's scenario tags, created after the freeze (a `-TESTS` event
      // exists), is a change to the frozen set: close check 8 diffs the tests since the last TESTS event.
      const ownId = cardDir ? cardIdOf(cardDir) : null;
      if (ownId && !existsSync(path) && tool === 'Write' && new RegExp(`@${ownId}-H\\d+-\\d+`).test(data.content ?? '')) {
        const events = existsSync(`${cardDir}/ambiguities.md`) ? readFileSync(`${cardDir}/ambiguities.md`, 'utf8').split(/\r?\n/) : [];
        const frozen = events.some((l) => l.startsWith(`${ownId}-TESTS · `));
        const rel = relativeTo(root, path);
        if (frozen && !events.some((l) => l.startsWith(`${ownId}-TESTS · `) && /refrozen at \S+/.test(l) && pathTokens(l).includes(rel))) {
          reject(
            `${rel} is a new test with scenario tags of ${ownId}, and the scenarios were already frozen: ` +
            'close check 8 would flag it. Append to ' +
            `${relativeTo(root, cardDir)}/ambiguities.md, before writing it, the event:\n` +
            `  ${ownId}-TESTS · <date> · refrozen at pending · <reason> · ${rel}\n` +
            'and after committing the file, a new `refrozen at <sha>` event (the last one wins). It is legitimate ' +
            'only for tests that an action of step 8 or 9 adds over scenarios already frozen; the frozen tests ' +
            'themselves are never changed.'
          );
        }
      }
      // Frozen is what HEAD has, by its content: the tags in HEAD freeze the file and say whose they are. A red
      // test in the index but not committed, or a versioned one that only has its tags in the working copy,
      // is still its author's.
      let headText = null;
      if (existsSync(path)) {
        const head = spawnSync('git', ['show', `HEAD:./${basename(path)}`],
                               { cwd: dirname(path), encoding: 'utf8', maxBuffer: 1 << 26 });
        if (head.error) {
          reject(`Could not query git for ${path} (${head.error.code}). ` +
                 'Without being able to verify whether the test is frozen, the guard blocks.');
        }
        if (head.status === 0) headText = head.stdout;
      }
      // The freeze is the card's: with no `specs/.current` naming a card in progress there is nothing to be frozen for.
      if (headText !== null && TAG.test(headText) && root && currentCard(root, { named: true })) {
        let current;
        try { current = readFileSync(path, 'utf8'); } catch (e) {
          reject(`Could not read ${path} to see whether it has card tags (${e.code}). ` +
                 'The guard blocks when in doubt.');
        }
        const own = cardDir ? cardIdOf(cardDir) : null;
        const foreign = own && !(headText.match(TAG_G) ?? []).some((t) => t.startsWith(`@${own}-H`));
        // A requirement of this card that contradicts a test of another, already closed, card; or, for a test of
        // this card, an ACT of step 8 that shows its locator is wrong (a critical axe finding, or a criterion).
        // The other exception is its cleanup: an edit that moves no assertion, title or tag, declared by an ACT that
        // names the file (`cleanupVerdict`). Measured: a teardown that deleted a folder before the server closed its
        // SQLite file failed with EPERM on Windows, and the reorder that fixes it was blocked as an edit of the test.
        if (cardDir) {
          // The one other change a frozen test takes: its cleanup repaired, with no assertion, title or tag moved.
          const repaired = cleanupVerdict({ cardDir, rel: relativeTo(root, path), current, next: tool === 'Edit' ? applyEdit(current, data) : data.content ?? '' });
          if (repaired.ok) process.exit(0);
        }
        if (own && cardDir) {
          const next = tool === 'Edit' ? applyEdit(current, data) : data.content ?? '';
          const verdict = refreezeVerdict({ cardDir, rel: relativeTo(root, path), current, next });
          if (verdict.ok) process.exit(0);
          if (!foreign) {
            reject(
              `${path} has tests tagged by this card and is already committed: frozen in step 4. Whoever implements does not ` +
              'edit scenario tests; if one is wrong, report it (actions.md, and the gap in `## Uncovered assumptions`). The one ' +
              'case that changes it is a locator that step 8 found wrong: a critical axe finding on what the test locates, or a ' +
              'criterion of the card that contradicts the locator (a menu item found by a role the `menu` does not allow). Then ' +
              `append to ${relativeTo(root, cardDir)}/ambiguities.md the event:\n  ${RFZ_FORMAT}\n` +
              `(file = ${relativeTo(root, path)}; the tag is this card's; the reason cites a scenario and an ACT-NN of actions.md ` +
              'whose evidence is that finding; after committing, `<ID>-TESTS · <date> · refrozen at <sha>`). ' +
              `Not allowed now: ${verdict.why}. ${CLEANUP_ADVICE}`
            );
          }
          reject(
            `${path} has tests tagged by another card and is already committed: frozen. A card changes ` +
            'it only when a requirement of THIS card contradicts it; if the other card\'s test still holds, ' +
            'this card is wrong and the test is not touched. To change it, append to ' +
            `${relativeTo(root, cardDir)}/ambiguities.md the event:\n  ${RFZ_FORMAT}\n` +
            `(file = ${relativeTo(root, path)}; the reason cites a scenario of this card's snapshot; the PR lists it under ` +
            `\`## Refrozen tests\`). Not allowed now: ${verdict.why}. ${CLEANUP_ADVICE}`
          );
        }
        reject(
          `${path} has tests tagged by card and is already committed: it was frozen in ` +
          'step 4. Whoever implements does not edit scenario tests. If the test is wrong, report it ' +
          `(actions.md, and the gap in \`## Uncovered assumptions\`: the PR lists it) — do not fix it yourself. ${CLEANUP_ADVICE}`
        );
      }
    }
  }

  // The configuration of what gets verified —linters, tests, coverage, mutation— that already
  // existed before the card only grows: rules are added to it, not removed or changed. Loosening it
  // is approving without fixing. Shrinking the command instead of the config is stopped by required.mjs.
  if (IS_VERIFICATION_CONFIG.test(path) && existsSync(path)) {
    const root = rootOf(path);
    const cardDir = root && currentCard(root);
    if (cardDir && existedAt(root, cardStart(root, cardDir), relativeTo(root, path))) {
      const linesOf = (t) => t.split('\n').map((l) => l.trim()).filter(Boolean);
      const current = readFileSync(path, 'utf8');
      const next = tool === 'Edit'
        ? (data.replace_all
          ? current.replaceAll(data.old_string ?? '', data.new_string ?? '')
          : current.replace(data.old_string ?? '', data.new_string ?? ''))
        : data.content ?? '';
      const remaining = new Set(linesOf(next));
      const lost = linesOf(current).filter((l) => !remaining.has(l));
      if (lost.length) {
        reject(
          `${relativeTo(root, path)} configures what gets verified and already existed before the card: ` +
          `lines are only added to it. This change removes or modifies ${lost.length}: “${lost[0]}”` +
          `${lost.length > 1 ? '…' : ''}. If a rule flags something, the code gets fixed. If the ` +
          'rule is wrong, record it in ambiguities.md as an `OUT` and it goes to the PR; the rule stays.'
        );
      }
    }
  }
} catch (e) {
  reject(`The guard could not evaluate this write (${e.message}). It blocks when in doubt: ` +
         'retry, and if it persists, say so instead of looking for another way to write.');
}

process.exit(0);
