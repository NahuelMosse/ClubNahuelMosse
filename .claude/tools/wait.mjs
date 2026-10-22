#!/usr/bin/env node
// wait.mjs <log> [--until <regex>] [--fail <regex>] [--max 570] [--ignore-case]
// wait.mjs --agent <agentId> [--agent <agentId> ...] [--max 570]
// wait.mjs <log> --until <regex> --agent <agentId> [--agent <agentId> ...] [--any | --all] [--max 570]
//
// Waits in ONE process for a log to show a line, or for background subagents to finish, and ends with the state.
// It is how to wait for something running in the background (verify.mjs, mutate.mjs, a suite, a subagent) without
// polling: every poll is a turn, and each wake-up past the prompt cache rewrites the whole context (the main
// thread, builder, runner and executor keep it an hour). Measured: 949 polling turns, USD 85 of one card.
// Give the call `timeout: 600000` (--max 570 plus a margin); the shell guard allows the wait.
//
// <log>      the file to read; it may not exist yet, but if nothing writes it within 15 s it is not a wait (exit 3).
//            An agent's output file (`tasks/<id>.output`, or any file with `--agent-output`) that is still at 0 bytes
//            after 15 s is exit 3 too. An ordinary log that is empty is a normal wait: a suite may write only at the end.
// --until    regex (multiline: ^ and $ match at lines) whose first match means “done, as expected”. Optional for the
//            log of a kit tool (verify, mutate, once, attack, repeat, probe, pairs, showreel): each ends with the fixed
//            line `<tool>: exit <N> in <X> min` (final-line.mjs), and the wait ENDS ON IT whatever --until says:
//            exit 0 → wait exits 0 (and says so when --until never matched: read the log); any other exit → 1.
//            --fail and --until are checked first, so a regex that matches earlier decides. A log that is not a kit
//            tool's has no such line: give it --until.
// --fail     regex whose match means “done, and bad”; checked before --until, so a failure is never masked.
// --agent    the id of a subagent launched in the background (the `agentId` its launch returns); repeat it to wait on
//            several. An agent is done when
//            `<claude home>/projects/*/*/subagents/agent-<id>.meta.json` has `"finished": true`. A subagent's
//            `tasks/<id>.output` stays at 0 bytes, so it cannot be waited on through its output. The claude home is
//            `$KIT_CLAUDE_HOME`, else `$CLAUDE_CONFIG_DIR`, else `~/.claude`. No such meta: exit 3.
// --any      with several things to wait on (agents, or a log and agents), end when the FIRST is done, and print which
//            one (the default). The rest keep running: wait again for them with the ids that were not printed.
// --all      end when EVERY one is done, and print one line for each; a log that matched --fail is exit 1.
// --max      seconds to wait, at most 570 (10 minutes, one turn); default 570. An agent without a one-hour cache
//            (no `cacheTtl: 1h` in its frontmatter) waits at most 270: wait.mjs cannot tell, guard-shell enforces it.
// Exit 0: --until matched, or the agent(s) finished; 1: --fail matched; 2: --max seconds passed with neither;
// 3: wrong usage, a log that did not appear or an agent output file empty for 15 s, or an agent with no meta.json.
// It prints the line that decided, or the last lines of the log when time ran out.
import { existsSync, openSync, readSync, closeSync, statSync, readFileSync, readdirSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { finalLineOf } from './final-line.mjs';

const MAX_S = 570;
// Past this a missing or empty log is a wait on something nobody runs: blind sleeping, not waiting.
const APPEARS_S = 15;
const usage = (why) => {
  console.error(`${why}\nusage: node wait.mjs <log> [--until <regex>] [--fail <regex>] [--max ${MAX_S}] [--ignore-case]\n       node wait.mjs --agent <agentId> [--agent <agentId> ...] [--any | --all] [--max ${MAX_S}]`);
  process.exit(3);
};

const args = process.argv.slice(2);
const flag = (name) => {
  const i = args.indexOf(name);
  if (i < 0) return null;
  const [, value] = args.splice(i, 2);
  return value ?? usage(`${name} needs a value`);
};
const bare = (name) => {
  const present = args.includes(name);
  while (args.includes(name)) args.splice(args.indexOf(name), 1);
  return present;
};
const ignoreCase = bare('--ignore-case');
const withAgentOutput = bare('--agent-output');
const wantAny = bare('--any');
const wantAll = bare('--all');
if (wantAny && wantAll) usage('--any and --all exclude each other');
const agents = [];
for (let a = flag('--agent'); a !== null; a = flag('--agent')) agents.push(a);
const untilText = flag('--until');
const failText = flag('--fail');
const maxText = flag('--max');
const max = maxText === null ? MAX_S : Number(maxText);
if (!(max > 0)) usage('--max is a number of seconds');
if (max > MAX_S) usage(`--max ${max} is over ${MAX_S} s: a longer wait holds the turn until the prompt cache can lapse, and the context is rewritten at every wake-up; wait ${MAX_S} s and ask again, or launch the work in the background and let it notify`);
const sleep = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
const start = Date.now();
const elapsed = () => ((Date.now() - start) / 1000).toFixed(0);
const pause = () => sleep(Math.min(500, Math.max(10, max * 1000 - (Date.now() - start))));
const timedOut = () => Date.now() - start >= max * 1000;

const home = process.env.KIT_CLAUDE_HOME || process.env.CLAUDE_CONFIG_DIR || join(homedir(), '.claude');
// The meta sits in `projects/<project>/<session>/subagents/`; the session of the agent is not known here.
const metaOf = (id) => {
  const projects = join(home, 'projects');
  let found = null;
  try {
    for (const project of readdirSync(projects)) {
      let sessions = [];
      try { sessions = readdirSync(join(projects, project)); } catch { continue; }
      for (const session of sessions) {
        const file = join(projects, project, session, 'subagents', `agent-${id}.meta.json`);
        if (existsSync(file)) found = file;
      }
    }
  } catch { /* no projects folder: no meta */ }
  return found;
};
const finished = (file) => {
  try { return JSON.parse(readFileSync(file, 'utf8')).finished === true; } catch { return false; }
};

// Each thing waited on: `poll()` returns null while it runs, or `{ code, line }` when it is done (0 as expected, 1 bad).
const targets = [];

for (const raw of agents) {
  const id = raw.replace(/^agent-/, '');
  if (!/^[\w.-]+$/.test(id)) usage(`${raw} is not an agent id`);
  targets.push({
    name: `agent ${id}`,
    poll: () => {
      const file = metaOf(id);
      if (!file) {
        console.error(`no meta.json for agent ${id} under ${join(home, 'projects')}: the id is not a background subagent of this machine (check the agentId its launch returned)`);
        process.exit(3);
      }
      return finished(file) ? { code: 0, line: `agent ${id} finished after ${elapsed()} s` } : null;
    },
    over: () => `agent ${id} has not finished`,
  });
}

if (agents.length && !args.length && (untilText !== null || failText !== null)) usage('--until and --fail need a log');
if (args.length || !agents.length) {
  const [log, ...extra] = args;
  if (!log || extra.length) usage('exactly one log file is expected');
  // Only an agent's output file is known to stay at 0 bytes whatever happens; a suite or a build may write its log at the end.
  const agentOutput = withAgentOutput || /(^|[\\/])tasks[\\/][^\\/]+\.output$/.test(log);
  const compile = (text, name) => {
    try { return new RegExp(text, `m${ignoreCase ? 'i' : ''}`); } catch (e) { return usage(`${name} is not a regular expression (${e.message})`); }
  };
  const until = untilText === null ? null : compile(untilText, '--until');
  const fail = failText === null ? null : compile(failText, '--fail');
  // The last 4 MB of the log: a build log can be large, and what decides is at its end.
  const TAIL = 4 << 20;
  const read = () => {
    if (!existsSync(log)) return '';
    const size = statSync(log).size;
    const fd = openSync(log, 'r');
    try {
      const length = Math.min(size, TAIL);
      const buffer = Buffer.alloc(length);
      readSync(fd, buffer, 0, length, size - length);
      return buffer.toString('utf8');
    } finally {
      closeSync(fd);
    }
  };
  const lineAt = (text, match) => {
    const from = text.lastIndexOf('\n', match.index) + 1;
    const end = text.indexOf('\n', match.index + match[0].length);
    return text.slice(from, end < 0 ? text.length : end).trim();
  };
  let text = '';
  targets.push({
    name: log,
    poll: () => {
      text = read();
      const bad = fail?.exec(text);
      if (bad) return { code: 1, line: `failed after ${elapsed()} s: ${lineAt(text, bad)}` };
      const found = until?.exec(text);
      if (found) return { code: 0, line: `found after ${elapsed()} s: ${lineAt(text, found)}` };
      const ended = finalLineOf(text);
      if (ended) {
        if (ended.exit !== 0) return { code: 1, line: `the tool finished with an error after ${elapsed()} s: ${ended.line}` };
        return { code: 0, line: `the tool finished (${ended.line}) after ${elapsed()} s${until ? ' but --until never matched: read the log' : ''}` };
      }
      const idle = Date.now() - start >= APPEARS_S * 1000 && max > APPEARS_S;
      if (idle && !existsSync(log)) {
        console.error(`nothing writes ${log}: to wait for a subagent launched in the background use \`node .claude/tools/wait.mjs --agent <agentId>\`; a log is for what a command writes to it`);
        process.exit(3);
      }
      if (idle && agentOutput && statSync(log).size === 0) {
        console.error(`${log} is still empty after ${APPEARS_S} s: nothing writes it. A subagent's output file stays at 0 bytes whatever it does; to wait for one use \`node .claude/tools/wait.mjs --agent <agentId>\``);
        process.exit(3);
      }
      return null;
    },
    over: () => {
      const last = text.trimEnd().split('\n').slice(-5).join('\n');
      return `without ${existsSync(log) ? 'a match' : 'the file'}${last ? `; last lines of ${log}:\n${last}` : ` (${log} is empty or does not exist)`}`;
    },
  });
}

const several = targets.length > 1;
const done = new Map();
for (;;) {
  for (const t of targets) {
    if (done.has(t)) continue;
    const r = t.poll();
    if (r) done.set(t, r);
  }
  if (done.size && (!several || !wantAll || done.size === targets.length)) {
    if (!several) {
      const [r] = done.values();
      console.log(r.line);
      process.exit(r.code);
    }
    const lines = [...done].map(([t, r]) => `${t.name}: ${r.line}`);
    if (wantAll) {
      console.log(lines.join('\n'));
      process.exit(Math.max(...[...done.values()].map((r) => r.code)));
    }
    const [[first, r]] = done;
    console.log(`${first.name} ended first: ${r.line}\nstill waiting: ${targets.filter((t) => !done.has(t)).map((t) => t.name).join(', ')}`);
    process.exit(r.code);
  }
  if (timedOut()) break;
  pause();
}
if (!several) {
  const [t] = targets;
  console.log(`timed out after ${max} s${t.name.startsWith('agent ') ? `: ${t.over()}` : ` ${t.over()}`}`);
  process.exit(2);
}
const pending = targets.filter((t) => !done.has(t)).map((t) => t.name);
console.log(`timed out after ${max} s: ${done.size ? `ended: ${[...done].map(([t, r]) => `${t.name} (${r.line})`).join('; ')}; ` : ''}still running: ${pending.join(', ')}`);
process.exit(2);
