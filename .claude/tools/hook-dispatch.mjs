#!/usr/bin/env node
// hook-dispatch.mjs <event> — the one process that answers an event of settings.json: it reads the
// call once, picks the hooks that apply to the tool, runs each in its own thread of this process
// and answers with the sum: exit 2 if any blocks, else 0 with what they printed.
// Events: PreToolUse, PostToolUse, Stop, SubagentStop, SessionStart, and `close` —an alias of the checks that
// open the close, which PreToolUse now runs itself; a settings.json that still registers `close` keeps working.
//
// Why one process: every hook used to be a node process of its own, and a call to Edit started five.
// Measured: 47 hooks hit their 10 s timeout in a card, and a hook that is cancelled lets the call
// through: a guard that blocks has to block also when it does not answer. Here a guard that throws,
// ends with a code other than 0 or 2, or does not finish in time (25 s; 55 s for require-at-close)
// blocks. The hooks that only save or record (SOFT in card.mjs) go on alone.
// A hook that cannot decide anything for this call is not started (`skips`): a worker costs a thread and the
// import of its modules, and a call to Bash started seven of them to hear that there was no card.
// `--dir <hooks folder>` runs the hooks of another folder and `--deadline <s>` sets one deadline for all
// (the tests).
import { existsSync, readFileSync, writeSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { Worker } from 'node:worker_threads';

// Which hooks apply to which tool: what settings.json said with its matchers, in order. require-at-close goes
// last: it used to be a second process after the others, and its answer still merges after theirs.
export const ROUTES = {
  PreToolUse: [
    ['Edit|Write|NotebookEdit', ['guard', 'require-bar', 'delegate-code', 'session-record']],
    ['Edit', ['edit-count']],
    ['Bash|PowerShell', ['guard-shell', 'trim-output', 'commit-why', 'shell-writes']],
    ['Bash|PowerShell|mcp__.*addComment.*', ['publish']],
    ['Read|Grep', ['guard']],
    ['Read', ['light-images']],
    ['Skill|Agent', ['review-cap']],
    ['Agent|Skill|Bash|PowerShell', ['time-cap']],
    ['.*', ['context-cap', 'turn-budget']],
    // /close never ran as a Skill in three cards: the same check also opens the close when closing.md is
    // written and when the card is published.
    ['Skill|Edit|Write|Bash|PowerShell', ['require-at-close']],
  ],
  // After a shell call: what it did to the production files (advice, never a block).
  PostToolUse: [['Bash|PowerShell', ['shell-writes']]],
  close: [['Skill|Edit|Write|Bash|PowerShell', ['require-at-close']]],
  Stop: [[null, ['no-pending-close']]],
  SubagentStop: [[null, ['no-pending-close']]],
  SessionStart: [[null, ['session-record']]],
};
export const DEADLINE_S = { default: 25, 'require-at-close': 55 };

export const hooksFor = (event, tool = '') => [...new Set((ROUTES[event] ?? [])
  .filter(([matcher]) => matcher === null || new RegExp(`^(?:${matcher})$`).test(tool))
  .flatMap(([, names]) => names))];

const GUARDING = new Set(['PreToolUse', 'close']);

// A shell command that only reads: one simple command, no redirect, pipe, substitution or second command.
const READ_ONLY = /^\s*(?:(?:ls|cat|head|tail|pwd|wc|grep)(?:\s+[^;&|<>`$()\n\\"']*)?|sed\s+-n\s+'?\d+(?:,\d+)?p'?\s+[^\s;&|<>`$()\\"']+|node\s+\.claude\/tools\/help\.mjs(?:\s+[\w.-]+)*)\s*$/;
// Same list as `CAPPED` in hooks/context-cap.mjs (a test keeps them equal).
export const CAPPED = new Set(['builder', 'grunt', 'designer', 'design-critic']);

// Whether a hook has nothing to say about this call, from what the hook itself would read first and end on
// with exit 0 and no output. Each rule repeats the early exit of its hook; none of them changes a verdict.
// Never when another kit's version of the hook would take the call over (`delegationTarget`).
export const skips = (name, input, card, hookUrl) => {
  try {
    if (!['shell-writes', 'commit-why', 'time-cap', 'context-cap', 'turn-budget', 'require-at-close', 'publish', 'trim-output'].includes(name)) return false;
    if (card.delegationTarget(hookUrl, input)) return false;
    const data = input.tool_input ?? {};
    const command = String(data.command ?? '');
    const cardOf = () => card.hookCard(input.cwd ?? process.cwd(), process.env, input);
    switch (name) {
      // Advice on what a subagent's shell call wrote: the main thread never gets any, and a call that only
      // reads writes nothing (it is skipped before and after, so no snapshot is left behind).
      case 'shell-writes': return !input.agent_id || READ_ONLY.test(command);
      case 'commit-why': return !/\bgit\s+(?:[^|;&\n"']*?\s)?commit\b/.test(command);
      // publish judges a shell line only where a `git push` or a `gh` call sits, bare or inside a wrapper; a Jira comment always.
      case 'publish': return ['Bash', 'PowerShell'].includes(input.tool_name) && !/\bgh\b|\bpush\b/i.test(command);
      // trim-output leaves alone what runs in the background and what only reads.
      case 'trim-output': return Boolean(data.run_in_background) || READ_ONLY.test(command);
      case 'time-cap': {
        const found = cardOf();
        return !found?.card || existsSync(join(found.card, 'closing.md')) || !['card.md', 'plan.md'].some((f) => existsSync(join(found.card, f)));
      }
      // The main thread is never capped.
      case 'context-cap': return !input.agent_id || !CAPPED.has(input.agent_type);
      // Only a subagent has turns; the main thread never has an `agent_id`.
      case 'turn-budget': return !input.agent_id;
      case 'require-at-close': {
        const tool = input.tool_name;
        const closingFile = ['Write', 'Edit'].includes(tool) && /(^|\/)specs\/[^/]+\/closing\.md$/.test(String(data.file_path ?? '').replaceAll('\\', '/'));
        const opens = (tool === 'Skill' && String(data.skill ?? '').split(':').pop() === 'close') ||
          closingFile || (['Bash', 'PowerShell'].includes(tool) && card.publishes(data.command ?? ''));
        return !opens;
      }
      default: return false;
    }
  } catch { return false; }
};

const runHook = (dir, name, raw, deadline) => new Promise((resolve) => {
  const seconds = deadline ?? DEADLINE_S[name] ?? DEADLINE_S.default;
  const result = { name, out: '', err: '', code: null, why: null };
  let worker;
  let timer;
  const done = (why) => {
    clearTimeout(timer);
    if (why && !result.why) result.why = why;
    setImmediate(() => resolve(result));
  };
  try {
    worker = new Worker(new URL('./hook-worker.mjs', import.meta.url), {
      workerData: { raw, hook: pathToFileURL(join(dir, `${name}.mjs`)).href }, stdout: true, stderr: true,
    });
  } catch (e) { result.why = `could not start (${e.message})`; resolve(result); return; }
  worker.stdout.on('data', (d) => { result.out += d; });
  worker.stderr.on('data', (d) => { result.err += d; });
  worker.on('error', (e) => { result.why = `threw: ${e?.message ?? e}`; });
  worker.on('exit', (code) => { result.code = code; done(); });
  timer = setTimeout(() => { result.why = `did not finish in ${seconds} s`; worker.terminate().then(() => done(), () => done()); }, seconds * 1000);
});

// The answers that are JSON —updatedInput, additionalContext— merge; anything else is joined as text.
const merge = (outputs) => {
  const texts = outputs.map((o) => o.trim()).filter(Boolean);
  if (texts.length < 2) return texts[0] ?? '';
  let parsed;
  try { parsed = texts.map((t) => JSON.parse(t)); } catch { return texts.join('\n'); }
  const out = {};
  for (const p of parsed) {
    for (const [key, value] of Object.entries(p)) {
      if (key === 'hookSpecificOutput' && out[key]) {
        const a = out[key];
        out[key] = {
          ...a, ...value,
          ...(a.updatedInput || value.updatedInput ? { updatedInput: { ...a.updatedInput, ...value.updatedInput } } : {}),
          ...(a.additionalContext && value.additionalContext ? { additionalContext: `${a.additionalContext}\n${value.additionalContext}` } : {}),
        };
      } else out[key] = value;
    }
  }
  return JSON.stringify(out);
};

export const dispatch = async (event, raw, dir, deadline) => {
  let tool = '';
  let input = null;
  try { input = JSON.parse(raw); tool = String(input.tool_name ?? ''); } catch {
    if (GUARDING.has(event)) return { code: 2, stderr: 'The call to the hooks could not be read. It blocks when in doubt: retry.\n', stdout: '' };
  }
  // Loaded here and not at the top: a card.mjs that does not load must end in a block, not in the exit 1
  // of an import that failed, which lets the call through.
  const card = await import('./card.mjs');
  const { SOFT } = card;
  // Every hook of the call lives in `dir`, so the kit that governs the call is the same for all: asked once.
  let target;
  const once = { ...card, delegationTarget: (url, call) => (target === undefined ? (target = card.delegationTarget(url, call)) : target) };
  const names = hooksFor(event, tool).filter((name) => !(input && typeof input === 'object' && skips(name, input, once, pathToFileURL(join(dir, `${name}.mjs`)).href)));
  const results = await Promise.all(names.map((name) => runHook(dir, name, raw, deadline)));
  const blocked = [];
  const notes = [];
  const outputs = [];
  for (const r of results) {
    if (r.code === 2 && !r.why) blocked.push(r.err.trim() || `The hook ${r.name} blocked this call without saying why.`);
    else if (r.code !== 0 || r.why) {
      if (!SOFT.has(r.name)) {
        blocked.push(`The hook ${r.name} ${r.why ?? `ended with exit ${r.code}`}${r.err.trim() ? `: ${r.err.trim().split('\n').slice(-3).join(' ')}` : ''}. It blocks when in doubt: retry.`);
      }
    } else {
      outputs.push(r.out);
      if (r.err.trim()) notes.push(r.err.trim());
    }
  }
  if (blocked.length) return { code: 2, stderr: `${blocked.join('\n')}\n`, stdout: '' };
  return { code: 0, stderr: notes.length ? `${notes.join('\n')}\n` : '', stdout: merge(outputs) };
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const args = process.argv.slice(2);
  const option = (name) => { const at = args.indexOf(name); return at >= 0 ? args.splice(at, 2)[1] : undefined; };
  const dir = option('--dir') ?? join(import.meta.dirname, '..', 'hooks');
  const deadline = Number(option('--deadline')) || undefined;
  const [event] = args;
  const answer = (code, stdout, stderr) => {
    if (stdout) writeSync(1, stdout);
    if (stderr) writeSync(2, stderr);
    process.exit(code);
  };
  try {
    if (!ROUTES[event]) answer(2, '', `hook-dispatch.mjs: ${event ?? '(no event)'} is not an event of settings.json (${Object.keys(ROUTES).join(', ')}).\n`);
    const r = await dispatch(event, readFileSync(0, 'utf8'), dir, deadline);
    answer(r.code, r.stdout, r.stderr);
  } catch (e) {
    answer(GUARDING.has(event) ? 2 : 0, '', `The hook dispatcher failed (${e.message}).${GUARDING.has(event) ? ' It blocks when in doubt: retry.' : ''}\n`);
  }
}
