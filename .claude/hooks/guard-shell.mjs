#!/usr/bin/env node
// PreToolUse on Bash and PowerShell: the file guard only sees Edit/Write, so a `cat > file` or a `sed -i` dodges
// it entirely. This closes that path.
// Contract: exit 0 lets it through, exit 2 blocks and Claude reads stderr. On its own error it blocks.

import { readFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const reject = (reason) => {
  process.stderr.write(reason + '\n');
  process.exit(2);
};

let cmd;
let background = false;
let input = {};
try {
  const raw = readFileSync(0, 'utf8');
  input = JSON.parse(raw);
  await (await import('../tools/card.mjs')).delegateToRepo(import.meta.url, raw, input);
  const data = input.tool_input ?? {};
  cmd = data.command ?? '';
  background = data.run_in_background === true;
} catch (e) {
  reject(`The guard could not read the command (${e.message}). It blocks when in doubt: retry.`);
}
if (!cmd) process.exit(0);

// Redirection, sed -i, tee, mv/cp onto a destination: the ways to write without Edit/Write.
// The operator and the file go on the same line: if the search crosses line breaks, a `>` from any
// text and a mention of the file ten lines later count as a write.
// PowerShell reaches the same files with its own cmdlets: they are matched alongside.
const POWERSHELL_WRITE = 'Set-Content|Add-Content|Out-File|Tee-Object|Move-Item|Copy-Item';
const writesTo = (filePattern) =>
  new RegExp(
    `(>>?|\\btee\\b(\\s+-a)?|\\bsed\\b[^|;\\n]*\\s-i|\\bmv\\b|\\bcp\\b|\\b(?:${POWERSHELL_WRITE})\\b)[^|;&\\n]*${filePattern}`, 'i',
  ).test(cmd);

if (writesTo('card\\.snapshot\\.md')) {
  reject(
    'Writing card.snapshot.md through the shell dodges the guard. If the card changed: rename the ' +
    'current one to card.snapshot.<date>.md and write a new one with /card. Creating it for the ' +
    'first time can be done with Write.'
  );
}

// What rewrites it: `sed -i`, and in PowerShell a `>`, `Set-Content` or `Out-File` without `-Append`.
// `sed -i` counts only when ambiguities.md is a file the command edits: per command segment, and with
// the quoted script out of the way (a script or another file's name that mentions it edits nothing of it).
const sedEditsAmbiguities = cmd.split(/[|;&\n]+/).some((segment) => {
  const args = segment.replace(/(['"])([^'"]*)\1/g, (_, __, inner) => (/ambiguities\.md$/.test(inner) ? ` ${inner} ` : ' '));
  return /\bsed\b[^|;]*\s(?:-[a-zA-Z]*i|--in-place)\b/.test(args) && /(^|\s)\S*ambiguities\.md(?=\s|$)/.test(args);
});
const rewritesAmbiguities = sedEditsAmbiguities ||
  /(?<![>\d])>(?![>&])[^|;&\n]*ambiguities\.md/.test(cmd) ||
  /\bSet-Content\b[^|;&\n]*ambiguities\.md/i.test(cmd) ||
  /\bOut-File\b(?![^|;&\n]*-Append)[^|;&\n]*ambiguities\.md/i.test(cmd);
if (rewritesAmbiguities) {
  reject(
    'ambiguities.md is append-only. `sed -i`, `>`, `Set-Content` and `Out-File` rewrite lines already ' +
    'recorded. To change a state, add a new event at the end with `>>`, `Add-Content` or `Out-File -Append`.'
  );
}

// Verification configs only grow, and that is checked by the Edit/Write guard, which can compare
// before and after. Through the shell it cannot compare: they are rewritten with Edit.
const CONFIG = '(eslint\\.config\\.[cm]?[jt]s|\\.eslintrc[\\w.]*|playwright\\.config\\.[cm]?[jt]s|stryker\\.conf[\\w.]*|\\.c8rc[\\w.]*|\\.nycrc[\\w.]*|jest\\.config\\.[cm]?[jt]s|vitest\\.config\\.[cm]?[jt]s|tsconfig[\\w.-]*\\.json|ruff\\.toml|mypy\\.ini|pytest\\.ini|\\.golangci\\.\\w+)\\b';
// With `cp` and `mv` the config counts only as the destination —the last argument—: copying it
// elsewhere does not change it. Measured: the guard blocked a `cp` that took the config to a test copy.
const writesConfig = new RegExp(`(>>?|\\btee\\b(\\s+-a)?|\\bsed\\b[^|;\\n]*\\s-i)[^|;&\\n]*${CONFIG}`).test(cmd) ||
  new RegExp(`\\b(cp|mv)\\b[^|;&\\n]*\\s\\S*${CONFIG}\\s*($|[|;&\\n])`).test(cmd);
if (writesConfig) {
  reject(
    'That is a configuration of what gets verified, and through the shell the guard cannot see what ' +
    'changes. Edit it with Edit or Write: if it only adds rules, it goes through.'
  );
}

// The manifest of the modules is written by `kit.mjs` and `install.mjs`, nothing else. With `cp` and
// `mv` it counts only as the destination.
const MANIFEST = 'kit(?:-files)?\\.json\\b';
if (new RegExp(`(>>?|\\btee\\b(\\s+-a)?|\\bsed\\b[^|;\\n]*\\s-i|\\b(?:${POWERSHELL_WRITE})\\b)[^|;&\\n]*${MANIFEST}`, 'i').test(cmd) ||
    new RegExp(`\\b(cp|mv)\\b[^|;&\\n]*\\s\\S*${MANIFEST}\\s*($|[|;&\\n])`).test(cmd)) {
  reject(
    '.claude/kit.json (and kit-files.json, the hashes of its files) is the manifest of the kit\'s modules, and through the shell it is not written: ' +
    '`node .claude/tools/kit.mjs on <module>` or `kit.mjs confirm-off <module> --reason "…"`. Turning a ' +
    'module off is a person\'s decision, between cards, with its reason.'
  );
}

// Migrations that exist in the base are assumed applied everywhere (DB-MIG-12): through the shell they
// are not edited, renamed, moved or deleted either, and the commands that silence the integrity check of
// the history are not run (DB-MIG-13). A regex over a shell line is incomplete by nature: this is the
// first layer, and the close compares the working tree with the base, which no other route dodges.
try {
  const { shellViolation, IMMUTABLE_ADVICE, ESCAPE_ADVICE } = await import('../tools/migrations.mjs');
  const where = typeof input.cwd === 'string' && existsSync(input.cwd) ? input.cwd : process.cwd();
  const found = shellViolation(cmd, where);
  if (found?.escape) reject(ESCAPE_ADVICE(found.escape));
  if (found) reject(IMMUTABLE_ADVICE(found));
} catch (e) {
  reject(`The guard could not evaluate the migrations (${e.message}). It blocks when in doubt: retry.`);
}

// Secrets: the agent neither reads nor writes them, so the value never enters the context. They are
// blocked as the destination of a write, or as the argument of something that reads or copies them.
// Naming them to a program that loads them itself (`node --env-file=.env app.js`,
// `docker compose --env-file .env up`) is allowed: the agent does not see the content.
// Declared holes: `git diff` or `git show` of a versioned `.env`, a script that reads the file, and
// `env` or `printenv` after loading it.
const { isSecret, hookCard } = await import('../tools/card.mjs').catch((e) => reject(`The guard could not load the secret list (${e.message}). It blocks when in doubt: retry.`));
const READERS = 'cat|type|less|more|head|tail|bat|nl|od|xxd|hexdump|strings|base64|grep|rg|egrep|sed|awk|cut|sort|diff|cmp|cp|mv|scp|rsync|tar|zip|7z|openssl|source|Get-Content|gc|Select-String|Copy-Item|Move-Item|code|notepad|vim|nano';
const READER = new RegExp(`(^|[\\s;&|(])(${READERS})(?=\\s)|^\\s*\\.\\s`, 'i');
const wordsOf = (segment) => segment.split(/[\s"'`]+/).map((t) => t.replace(/^>+/, '')).filter(Boolean);
const segments = cmd.split(/[|;&\n]+/);
const secretReach = segments.some((segment) => {
  const words = wordsOf(segment);
  const curl = /(^|\s)curl\s/i.test(segment) && /\s(-d\s*@|-F|-T|--data\S*\s+@|--upload-file)/.test(segment);
  const named = words.filter((w) => isSecret(w) || (curl && isSecret(w.split(/[=@]/).pop())));
  return named.length > 0 && (READER.test(segment) || curl);
});
const writtenSecret = wordsOf(cmd).filter(isSecret).some((w) => writesTo(w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')));
if (secretReach || writtenSecret) {
  reject('Secrets are not read or written by the agent. The variable names are in .env.example ' +
         '(`cat .env.example`); the value is set by a person.');
}

// A check is never skipped to make a commit or a push go through.
if (/\bgit\s+(commit|push)\b[^|;&\n]*--no-verify\b/.test(cmd)) {
  reject('`--no-verify` skips the hooks that protect the card. Fix what the hook reports; if the hook is ' +
         'wrong, record it in ambiguities.md as an `OUT` and it goes to the PR; the hook stays.');
}

// A stash changes the tree under the runs in the background (verify, a suite): measured, a false red on a
// real card. With a card in progress only the read-only forms go through.
const stashes = segments.some((segment) => {
  const tokens = segment.trim().split(/\s+/);
  if (!/^git(\.exe)?$/i.test(tokens[0] ?? '')) return false;
  let i = 1;
  while (i < tokens.length && tokens[i].startsWith('-')) i += ['-C', '-c', '--git-dir', '--work-tree'].includes(tokens[i]) ? 2 : 1;
  return tokens[i] === 'stash' && !['list', 'show'].includes(tokens[i + 1]);
});
if (stashes) {
  let inProgress = false;
  try { inProgress = Boolean(hookCard(input.cwd ?? process.cwd(), process.env, input)); } catch {}
  if (inProgress) {
    reject('git stash changes the working tree under the runs in the background (verify, a suite) and turns them red for nothing. ' +
           'Commit what you have, or work in a separate checkout with git worktree add; git stash list and git stash show are fine.');
  }
}

// A suite or a check that is a line of the plan's `## Verification` runs through once.mjs or verify.mjs: a
// bare run leaves no record, so verify.mjs runs the same thing again. Measured: a card ran its whole suite by
// hand three times, and verify.mjs ran it once more each time. Only the exact command of a line (or the
// `npm run <script>` of a line that is a script) is refused: a bounded run (`npx playwright test --grep @X`,
// `node --test one.test.mjs`) is not that line.
// Inside a subagent the rule is wider: what is equivalent to a whole line (an npm script a line reaches, its body,
// `playwright test -c <config>` or `node --test <globs>` with no filter) is refused as well, and an implementer or a
// grunt runs neither verify.mjs nor a line through once.mjs: the first whole run is the main thread's, in step 8.
// For a subagent a parser that fails refuses; for the main thread it does not stop the shell, the rule is about cost.
const agentType = String(input.agent_type ?? '');
const noSuites = Boolean(input.agent_id) && /^(?:implementer|grunt)$/.test(agentType);
try {
  const found = hookCard(input.cwd ?? process.cwd(), process.env, input);
  const planPath = found && `${found.card}/plan.md`;
  if (planPath && existsSync(planPath)) {
    const plan = readFileSync(planPath, 'utf8');
    const section = plan.split(/^## /m).find((s) => s.startsWith('Verification')) ?? '';
    const clean = (c) => c.trim().replace(/^cd\s+\S+\s*&&\s*/, '').replace(/\s*\|\s*(?:tail|head)\b[^|]*$/, '')
      .replace(/(?:\s+(?:\d*>>?|&>)\s*&?\S+)+\s*$/, '').replace(/\s+/g, ' ').trim();
    const { planCommands, scriptNamed, wholeRunOf } = await import('../tools/verify.mjs');
    const { commandsOf } = await import('../tools/shell-writes.mjs');
    const { records } = await import('../tools/once.mjs');
    const planned = section && planCommands(plan, { base: 'HEAD', cardDir: found.card });
    const norm = (c) => c.replace(/\s+/g, ' ').trim();
    // Short: named lint, types or format, or measured under 30 s by verify.mjs (durations.json, by command) or once.mjs
    // (its records, by name); with several measures the longest counts. A line nobody has run is not short.
    const SHORT_MIN = 0.5;
    const shortLine = (root, line) => {
      if (/^(?:lint|types|format)$/i.test(line.name)) return true;
      let durations = {};
      try { durations = JSON.parse(readFileSync(join(root, '.validation', 'verify', 'durations.json'), 'utf8')); } catch {}
      const measures = Object.entries(durations).filter(([known]) => known && line.command.includes(known)).map(([, m]) => Number(m));
      for (const r of records(root)) if (r.name === line.name) measures.push(Number(r.minutes));
      const known = measures.filter(Number.isFinite);
      return known.length > 0 && Math.max(...known) < SHORT_MIN;
    };
    // A round of actions.md is over when it has action lines and every one of them is closed with its output.
    const roundClosed = (card) => {
      try {
        const lines = readFileSync(join(card, 'actions.md'), 'utf8').split(/\r?\n/).filter((l) => /^\W*ACT-\w+\b/.test(l));
        return lines.length > 0 && lines.every((l) => /· closed\b/.test(l) && !/· (?:open|suspect)\s*$/.test(l));
      } catch { return false; }
    };
    const MAIN_THREAD ='A whole run is the main thread\'s: verify.mjs in step 8; a runner or an executor it sends runs a line through once.mjs. ';
    const BOUNDED = 'A bounded run goes through: one spec file, `--grep` or `-g` on a tag, node --test over one file or with `--test-name-pattern`, tsc and eslint on what you touched.';
    // Each command the line runs is compared on its own: parentheses, a trailing `&`, `nohup`, `sh -c '…'`, an
    // environment prefix and `cd x &&` do not make a whole line another command.
    for (const asked of [...new Set(commandsOf(cmd).map(clean))].filter(Boolean)) {
      if (planned && noSuites && /\bnode\s+(?:-\S+\s+)*\S*verify\.mjs(?:\s|$)/.test(asked) && !(agentType === 'implementer' && roundClosed(found.card))) {
        reject(`An implementer or a grunt does not run verify.mjs (an implementer closes a round of actions.md with it, once every line is \`closed · <output>\`). ${MAIN_THREAD}${BOUNDED}`);
      }
      // Through once.mjs the command is what comes after `--`.
      const viaOnce = noSuites && /\bnode\s+(?:-\S+\s+)*\S*once\.mjs\s/.test(asked);
      const inner = viaOnce ? clean(asked.replace(/^.*?\bonce\.mjs\s+\S+\s+--\s+/, '')) : asked;
      if (planned && inner && (viaOnce || !/\b(?:once|verify)\.mjs\b/.test(asked))) {
        const exact = (/^(?:npm|pnpm|yarn)\s/.test(inner) || section.replace(/\s+/g, ' ').includes(inner)) &&
          planned.find((c) => c.file === undefined && (norm(c.command) === inner || (scriptNamed(inner) && scriptNamed(inner) === scriptNamed(norm(c.command)))));
        const equivalent = exact ? { line: exact.name, what: 'its exact command' } : input.agent_id ? wholeRunOf(inner, planned, found.root) : null;
        // A subagent may run a short line: one named lint, types or format, or one measured under 30 s.
        const reached = input.agent_id && equivalent ? planned.find((c) => c.file === undefined && c.name === equivalent.line) : null;
        if (reached && shortLine(found.root, reached)) continue;
        // To an implementer or a grunt, once.mjs is refused as well: it is not recommended.
        if (exact && !viaOnce && !noSuites) {
          reject(
            `That is the command of the verification line “${exact.name}” of the plan, run on its own: it leaves no record and verify.mjs repeats it. ` +
            'Run it as `node .claude/tools/once.mjs <name> -- <command>` (name: the line\'s, here ' + `“${exact.name}”), or let node .claude/tools/verify.mjs run it with the other lines. ` +
            'A bounded run (one test file, `--grep` on one tag) goes through as it is.'
          );
        }
        if (equivalent) {
          reject(
            `That is the whole of the verification line “${equivalent.line}” of the plan (${equivalent.what})${viaOnce ? ', even through once.mjs' : ' run bare inside a subagent'}: ` +
            (noSuites ? 'an implementer or a grunt does not run whole suites. ' : 'it leaves no record and verify.mjs repeats it: run it as `node .claude/tools/once.mjs <name> -- <command>`. ') +
            MAIN_THREAD + BOUNDED
          );
        }
      }
    }
  }
} catch (e) {
  if (input.agent_id) reject(`The guard could not evaluate the verification lines of the plan (${e.message}). It blocks a subagent when in doubt: retry.`);
}

// `node --test` waits for every handle its tests leave open: a server or a browser kept one agent's call blocked for its whole
// timeout, 6.8 minutes, after the tests had ended in 14 seconds. An agent runs it with `--test-force-exit`; the commands of the kit
// (`mutate.mjs … -- node --test …`, verify.mjs) carry their own flags and are not a `node --test` of the agent.
if (input.agent_id) {
  const { commandsOf } = await import('../tools/shell-writes.mjs');
  const NODE_TEST = /^(?:npx\s+(?:-\S+\s+)*)?node(?:@\S+)?(?:\.exe)?\s+(?:-\S+\s+)*?--test(?=\s|$)/;
  if (commandsOf(cmd).some((c) => NODE_TEST.test(c) && !/(?:^|\s)--test-force-exit(?=[\s=]|$)/.test(c))) {
    reject('node --test without `--test-force-exit` waits for every handle the tests leave open (a server, a browser) and blocks the call for its whole timeout. ' +
           'Run it as `timeout <s> node --test --test-timeout=8000 --test-force-exit <files>`, and never two runs of the same browser suite at once.');
  }
}

// Two Playwright runs share `test-results/` and erase each other's output (a complete verification was repeated,
// 30 minutes). While once.mjs or verify.mjs holds the browser-run lock of the card (tools/browser-lock.mjs), a
// command that launches Playwright —`playwright test`, an `npm run` that expands to it, once.mjs of a browser
// line, verify.mjs— is refused. A saving, not a guard of the card: if it cannot read, it lets through.
try {
  const found = hookCard(input.cwd ?? process.cwd(), process.env, input);
  const lock = await import('../tools/browser-lock.mjs');
  const held = found && lock.liveLock(found.root);
  if (held) {
    const { launchesPlaywright } = lock;
    const { commandsOf } = await import('../tools/shell-writes.mjs');
    if (commandsOf(cmd).some((c) => /\bnode\s+(?:-\S+\s+)*\S*verify\.mjs(?:\s|$)/.test(c) || launchesPlaywright(c, found.root))) {
      reject(`a browser run is in progress (pid ${held.pid}: ${held.command}); wait for it with wait.mjs, they share the output dir`);
    }
  }
} catch { /* a saving: without a reading it says nothing */ }

// The captures project rewrites the PNGs of every card when it runs whole, and the diff then carries the evidence
// of earlier cards (required.mjs reports it). During a card the agent is told to run it with this card's filter:
// a warning to the agent, not a refusal.
try {
  const runsCaptures = /\bplaywright\s+test\b[^|;&\n]*(?:--project[=\s]+captures\b|captures\S*\.config)|\bnpm\s+run\s+captures\b/.test(cmd);
  const filtered = /(?:^|\s)(?:-g|--grep)(?:[=\s]|$)/.test(cmd) || /\s\S+\.(?:capture|spec)\.[cm]?[jt]sx?\b/.test(cmd);
  if (runsCaptures && !filtered && hookCard(input.cwd ?? process.cwd(), process.env, input)) {
    const advice = 'The captures project rewrites the PNGs of every card when it runs whole, and the diff would carry the evidence of earlier cards. ' +
      "During a card run it only with the card's filter: `--grep` on its views (\"@capture <view>\") or its own capture file.";
    process.stdout.write(JSON.stringify({ systemMessage: advice, hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: advice } }));
  }
} catch { /* advice only */ }

// The fast lane (steps/fast-lane.md): through the shell the diff cannot be compared with what the lane
// allows, so a write to a test or to production code goes through Edit or Write, where the hooks can.
try {
  const found = hookCard(input.cwd ?? process.cwd(), process.env, input);
  if (found) {
    const { laneOf, OUT_OF_LANE } = await import('../tools/lane.mjs');
    const { IS_TEST, NOT_PRODUCTION, relativeTo } = await import('../tools/card.mjs');
    const planPath = `${found.card}/plan.md`;
    if (existsSync(planPath) && laneOf(readFileSync(planPath, 'utf8')) === 'fast') {
      const WRITE = new RegExp(`(>>?|\\btee\\b|\\bsed\\b[^|;\\n]*\\s-i|\\bmv\\b|\\bcp\\b|\\b(?:${POWERSHELL_WRITE})\\b)`, 'i');
      const targets = segments.filter((s) => WRITE.test(s)).flatMap(wordsOf)
        .filter((w) => /[./\\]/.test(w) && !/^-/.test(w))
        .map((w) => relativeTo(found.root, resolve(input.cwd ?? process.cwd(), w)))
        .filter((rel) => !rel.startsWith('..') && (IS_TEST.test(rel) || !NOT_PRODUCTION.test(rel)));
      if (targets.length) reject(OUT_OF_LANE([`a write through the shell to ${[...new Set(targets)].join(', ')}: use Edit or Write`]));
    }
  }
} catch (e) {
  reject(`The guard could not evaluate the fast lane (${e.message}). It blocks when in doubt: retry.`);
}

// The guards of production code see Edit and Write, not the shell: a subagent that writes it with `sed -i`, a
// redirection, `tee` or a script that calls `writeFileSync` leaves no trace they can read. With a card in progress
// the forms that can be read from the text are refused (shell-writes.mjs says what changed after the ones that cannot).
try {
  const found = input.agent_id ? hookCard(input.cwd ?? process.cwd(), process.env, input) : null;
  if (found) {
    const { shellWrites } = await import('../tools/shell-writes.mjs');
    const { files, via } = shellWrites(cmd, { root: found.root, cwd: input.cwd ?? process.cwd(), tool: input.tool_name });
    if (files.length) {
      reject(`That writes production code through the shell (${via.join(', ')}: ${files.join(', ')}), where the guards that protect the card do not see it. ` +
        'Use Edit or Write for production files: whole file with Write, a small change with Edit. The shell is for running things, not for writing the product.');
    }
  }
} catch (e) {
  reject(`The guard could not evaluate the shell writes (${e.message}). It blocks a subagent when in doubt: retry.`);
}

// Waiting for another agent with a sleep loop is waiting blind, in series, and rereading context.
// Measured: a 107-minute card spent 40 in ten-minute loops asking whether a subagent's output
// existed yet. A short loop to wait for a server to come up is fine, and one that runs in the
// background blocks no one: it notifies when it finishes.
// A shell loop has its `do`; a `for` inside a script passed to `node -e` is not one.
// A PowerShell loop has its block: `while (…) { … }`, `for (…) { … }` or `do { … } while (…)`.
const loop = !background && (/\b(for|while|until)\b[^\n]*?[;\n]\s*do\b/.test(cmd) || /\b(while|until|for)\s*\([^\n]*\)\s*\{|\bdo\s*\{/i.test(cmd));
// The seconds a command sleeps: `sleep N`, PowerShell's `Start-Sleep [-Seconds|-s] N` and `-Milliseconds|-m N`,
// and cmd's `timeout /t N`.
const sleepsOf = (text) => [
  ...[...text.matchAll(/\bsleep\s+(\d+(?:\.\d+)?)/g)].map((m) => Number(m[1])),
  ...[...text.matchAll(/\bStart-Sleep\s+(?:-(?:Seconds|s)\s+)?(\d+(?:\.\d+)?)/gi)].map((m) => Number(m[1])),
  ...[...text.matchAll(/\bStart-Sleep\s+-(?:Milliseconds|m|ms)\s+(\d+)/gi)].map((m) => Number(m[1]) / 1000),
  ...[...text.matchAll(/\btimeout(?:\.exe)?\s+\/t\s+(\d+)/gi)].map((m) => Number(m[1])),
];
const wait = Math.max(0, ...sleepsOf(cmd));
// A sleep before or after a loop, outside its `do … done`, is a wait of its own: `sleep 100; for f in *.log; do tail $f; done`.
const waitOutsideLoop = Math.max(0, ...sleepsOf(cmd.replace(/\b(?:for|while|until)\b[\s\S]*?\bdone\b/g, ' ')));
const watchesAgent = /tasks[\\/][^\s"']*\.output\b|stop_reason/.test(cmd);
// A short sleep repeated for minutes is the same wait. The loop's ceiling —a `timeout N` around it,
// or a counter times its sleep— says how long it can hold the turn. Measured: a card ran
// `timeout 285 sh -c 'until …; do sleep 0.5; done'` 288 times, nine of its ten hours.
const timeoutCap = Math.max(0, ...[...cmd.matchAll(/\btimeout\s+(\d+)/g)].map((m) => Number(m[1])));
// The other ways to say how many times it goes round: `for i in $(seq 1 30)`, `{1..30}`, `for i in 1 2 3`
// and `for ((i=0; i<30; i++))`. A list it cannot count (`$(ls)`, a glob, a variable) says nothing.
const seqCount = (args) => {
  const nums = args.trim().split(/\s+/).filter((a) => !/^-[a-zA-Z]/.test(a)).map(Number);
  if (!nums.length || nums.length > 3 || nums.some(Number.isNaN)) return null;
  const [from, step, to] = nums.length === 1 ? [1, 1, nums[0]] : nums.length === 2 ? [nums[0], 1, nums[1]] : nums;
  return step === 0 ? null : Math.max(0, Math.floor((to - from) / step) + 1);
};
const iterationsOf = (text) => {
  const counts = [...text.matchAll(/\bfor\s+\w+\s+in\s+([^;\n]*?)\s*[;\n]\s*do\b/g)].map((m) => {
    let n = 0;
    let known = true;
    const rest = m[1]
      .replace(/\$\(\s*seq\s+([^)]*)\)|`\s*seq\s+([^`]*)`/g, (_, a, b) => {
        const c = seqCount(a ?? b);
        if (c === null) known = false; else n += c;
        return ' ';
      })
      .replace(/\{(-?\d+)\.\.(-?\d+)(?:\.\.(-?\d+))?\}/g, (_, a, b, s) => {
        n += Math.floor(Math.abs(Number(b) - Number(a)) / Math.abs(Number(s) || 1)) + 1;
        return ' ';
      });
    const words = rest.split(/\s+/).filter(Boolean);
    if (words.some((w) => /[$`*?()]/.test(w))) known = false;
    return known ? n + words.length : 0;
  });
  for (const m of text.matchAll(/\bfor\s*\(\(\s*\w+\s*=\s*(\d+)\s*;\s*\w+\s*(<=|<)\s*(\d+)/g))
    counts.push(Number(m[3]) - Number(m[1]) + (m[2] === '<=' ? 1 : 0));
  return Math.max(0, ...counts);
};
const counterCap = Math.max(0, ...[...cmd.matchAll(/-(?:ge|gt|lt|le)\s+(\d+)/g)].map((m) => Number(m[1])), iterationsOf(cmd)) * wait;
// A wait inside the prompt cache costs one turn; every wake-up past it rewrites the whole context. The main
// thread and the agents that wait on suites (implementer, runner, executor) keep a one-hour cache, so one
// wait of up to 10 minutes is a single turn. Measured: a card polled every 25 s for 949 turns, USD 85 of 175.
// A subagent (its hook input carries `agent_id`; the main thread's does not) that runs a card waits for its
// own agents and processes: for it, a foreground wait is allowed when it has a ceiling of at most 570 s
// —an explicit `timeout` on the tool call, or a `timeout N` / counter in the loop—. The main thread keeps the rule above.
// `wait.mjs` is the way to wait: one process that ends on the line it was told to wait for.
// Who keeps the one-hour cache is read, in this order: from the `usage` of the last assistant message of its own
// transcript (1-hour tokens written: the agent may not be defined in the repo at all, as the main thread of a run
// is not); from its frontmatter (`experimental: cacheTtl: 1h`) in the repo's `.claude/agents`, the home's and the
// kit's own; and by default the main thread has one hour and a subagent five minutes (the old ceiling of 270 s).
const hourCache = await (async () => {
  try {
    const { transcriptOf, lastUsage } = await import('../tools/transcript.mjs');
    const file = transcriptOf(input) ?? (input.agent_id ? null : input.transcript_path);
    if (file && existsSync(file) && lastUsage(file)?.cache_creation?.ephemeral_1h_input_tokens > 0) return true;
  } catch { /* no reading of the transcript: the frontmatter decides */ }
  const type = String(input.agent_type ?? '');
  if (input.agent_id && /^[\w.-]+$/.test(type)) {
    const { homedir } = await import('node:os');
    const where = typeof input.cwd === 'string' && input.cwd ? input.cwd : process.cwd();
    for (const folder of [resolve(where, '.claude', 'agents'), resolve(homedir(), '.claude', 'agents'), fileURLToPath(new URL('../agents/', import.meta.url))]) {
      let text;
      try { text = readFileSync(join(folder, `${type}.md`), 'utf8'); } catch { continue; }
      return /^\s+cacheTtl:\s*1h\s*$/m.test(text.match(/^---\r?\n([\s\S]*?)\r?\n---/)?.[1] ?? '');
    }
  }
  return !input.agent_id;
})();
const MAX_WAIT_S = hourCache ? 570 : 270;
const MAX_CALL_MS = MAX_WAIT_S * 1000 + 30000;
const MIN_POLL_S = 120;
const WAIT_WITH = 'Wait in one process that ends on the line you need: ' +
  (hourCache
    ? "`node .claude/tools/wait.mjs <log> --until '<regex>' [--fail '<regex>'] --max 570` (exit 0 found, 1 failed, 2 timed out; "
    : "`node .claude/tools/wait.mjs <log> --until '<regex>' [--fail '<regex>'] --max 270` (exit 0 found, 1 failed, 2 timed out; ") +
  `give the call \`timeout: ${MAX_CALL_MS}\`). ` +
  'For a subagent launched in the background: `node .claude/tools/wait.mjs --agent <agentId> [--max 570]` (its `tasks/<id>.output` stays at 0 bytes, so it cannot be waited on through the output). ' +
  (hourCache ? '' : 'This agent keeps a five-minute prompt cache (its frontmatter has no `cacheTtl: 1h`): a wait past 270 s rewrites its whole context. ');
// wait.mjs does not know which agent runs it: the guard holds a five-minute agent to its ceiling.
const waitMax = [...cmd.matchAll(/\bwait\.mjs\b[^|;&\n]*?--max[=\s]+(\d+(?:\.\d+)?)/g)].map((m) => Number(m[1]));
if (!hourCache && waitMax.some((n) => n > MAX_WAIT_S)) {
  reject(`wait.mjs --max ${Math.max(...waitMax)} is over ${MAX_WAIT_S} s, and this agent keeps a five-minute prompt cache (its frontmatter has no \`cacheTtl: 1h\`): ` +
    `a longer wait rewrites its whole context. Wait ${MAX_WAIT_S} s at most and ask again, or launch the work in the background and let it notify.`);
}
const cap = Math.max(timeoutCap, counterCap);
const toolTimeout = Number(input.tool_input?.timeout);
const boundedSubagent = Boolean(input.agent_id) &&
  ((toolTimeout > 0 && toolTimeout <= MAX_WAIT_S * 1000) || (cap > 0 && cap <= MAX_WAIT_S));
// What a loop that waits for a port or a URL does is a server coming up: a few seconds, and fine.
const waitsForEndpoint = /\b(curl|wget|nc|ncat|netcat|Test-NetConnection|Invoke-WebRequest|iwr)\b|\/dev\/tcp\//i.test(cmd);
// A `for` whose variable the body uses goes through items with a pause between them: that is pacing, not
// waiting for something to happen.
const pacing = /\bwhile\s+(?:IFS=\S*\s+)?read\b/.test(cmd) || (!/\b(until|while)\b/.test(cmd) &&
  [...cmd.matchAll(/\bfor\s+(\w+)\s+in\b/g)].some((m) => new RegExp(`\\$\\{?${m[1]}\\b`).test(cmd)));
const polling = loop && wait > 0 && !waitsForEndpoint && !pacing;
if (polling && cap > 0 && cap < MIN_POLL_S) {
  reject(
    `This loop polls for at most ${cap} s: too short to be worth a loop, and the agent that sees it unmet polls again, each ` +
    'time a turn. ' + WAIT_WITH + 'A loop that waits for a port or a URL (curl, nc, Test-NetConnection) is the exception.'
  );
}
if (polling && cap === 0 && !boundedSubagent) {
  reject(
    'This loop polls with no ceiling: nothing says when it stops, so it holds the turn for as long as what it waits for takes. ' +
    WAIT_WITH + 'A loop that waits for a port or a URL (curl, nc, Test-NetConnection) is the exception.'
  );
}
// A `timeout N` on each command of a loop that does not sleep bounds that command, not a wait.
if (loop && (wait > 0 || watchesAgent) && !boundedSubagent && cap >= 60) {
  reject(
    `This loop can hold the turn for ${cap} s waiting in the foreground. ` +
    'A long process runs in the background and notifies when it ends, or a subagent waits for it; ' +
    'a foreground wait is for a server coming up, a few seconds. ' + WAIT_WITH +
    `A subagent may also wait in the foreground up to ${MAX_WAIT_S} s with an explicit \`timeout\` on the call or a loop with a ceiling of at most ${MAX_WAIT_S} s.`
  );
}
if (loop && !boundedSubagent && (watchesAgent || wait >= 20)) {
  reject(
    'This loop waits blind: ' + (watchesAgent ? 'it asks whether another agent finished' : `it sleeps ${wait} s per turn`) +
    '. A subagent that what follows depends on is launched in the foreground —several in a single ' +
    'message come back together—, and a long process is awaited through its own end, not by asking ' +
    'every so often. ' + WAIT_WITH + 'If a server really has to be waited for, use a half-second loop with its condition. A subagent that waits for its own agents or processes ' +
    `may do it in the foreground up to ${MAX_WAIT_S} s with an explicit \`timeout\` on the call or a loop with a ceiling.`
  );
}

// A sleep with no loop, next to a read of a log, is the same blind wait in one line: `sleep 60; tail x.log`.
// Short sleeps (a server coming up, a pause between two calls) are not that.
if (!background && (loop ? waitOutsideLoop : wait) >= 20 && /\b(tail|grep|rg|cat|Get-Content|gc|Select-String|sls|type)\b/i.test(cmd) && /\.(log|output|txt)\b/i.test(cmd)) {
  reject(
    `This command sleeps ${wait} s and then reads a log: it waits blind, and the agent that finds it unfinished does it again, each time a turn. ` + WAIT_WITH
  );
}

// A foreground call that can hold the turn past 10 minutes is a wait: it belongs in the background.
if (!background && toolTimeout > MAX_CALL_MS) {
  reject(
    `A foreground call with \`timeout\` ${toolTimeout} ms holds the turn past ${MAX_CALL_MS / 60000} minutes, long enough for the prompt cache to lapse and the context to be rewritten when it returns. ` +
    'Run it in the background with its output to a log. ' + WAIT_WITH
  );
}

// Killing by process name takes down those of other agents and of the user.
if (/\b(taskkill\b[^|;]*\/IM|pkill\b|killall\b|Stop-Process\b[^|;\n]*-Name\b|Get-Process\b[^\n]*\|\s*Stop-Process\b)/i.test(cmd)) {
  reject(
    'Killing by process name takes down the processes of other agents, of the editor and of the ' +
    'user, and there is no way to undo it. Kill by PID: save the pid of what you start, or ' +
    'find it by the port you reserved. If you do not know the pid, leave it alive and say so.'
  );
}

process.exit(0);
