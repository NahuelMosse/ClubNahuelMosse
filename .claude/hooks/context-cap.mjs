#!/usr/bin/env node
// PreToolUse on every tool: the context of the main thread, a `builder`, a `grunt` and a `designer` is capped, because every request re-reads
// it. The context is estimated from the `usage` of the last assistant message of its own transcript —input, cache read and
// cache creation tokens—: the main thread is warned once at 80k and, past 120k, refused every tool but a `git add`,
// `git commit` or `git status` and a Write of `specs/<card>/handoff*.md`; a `builder` or `grunt` is warned at 90k and cut at 120k
// the same way, and returns so the main thread launches a fresh one with that handoff.
// The main thread is capped only with a card in progress (a session with no card has nothing to hand over).
// The subagent's transcript is `agent_transcript_path` when the input has it, else the one next to the session transcript:
// `<session>/subagents/agent-<agent_id>.jsonl`. Without a readable transcript the hook says nothing: it is a saving, the guards
// that protect the card are others.
// Measured: an agent that reached 303 thousand tokens re-read on every request; the main thread of a card averaged 265k.
// Contract: exit 0 lets it through (stdout JSON carries the warning); exit 2 blocks and Claude reads stderr.
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { contextTokens, onlyCommit, transcriptOf } from '../tools/transcript.mjs';

const MAIN = { warn: 80_000, stop: 120_000 };
const SUB = { warn: 90_000, stop: 120_000 };
const CAPPED = new Set(['builder', 'grunt', 'designer']);

const HANDOFF = /(^|[\\/])specs[\\/][^\\/]+[\\/]handoff[^\\/]*\.md$/;

let input;
let raw;
try { raw = readFileSync(0, 'utf8'); input = JSON.parse(raw); } catch { process.exit(0); }
try {
  const card = await import('../tools/card.mjs');
  await card.delegateToRepo(import.meta.url, raw, input);
  const main = card.actsAsMain(input);
  if (!main && !CAPPED.has(input.agent_type)) process.exit(0);
  const file = input.agent_id ? transcriptOf(input) : input.transcript_path;
  if (!file || !existsSync(file)) process.exit(0);
  const { warn, stop } = main ? MAIN : SUB;
  const used = contextTokens(file);
  if (used === null || used < warn) process.exit(0);
  if (main) {
    const open = card.hookCard(input.cwd ?? process.cwd(), process.env, input);
    if (!open || existsSync(join(open.card, 'closing.md'))) process.exit(0);
  }
  const who = main ? 'main thread' : input.agent_type;
  const k = `${Math.round(used / 1000)}k`;

  if (used >= stop) {
    const data = input.tool_input ?? {};
    const commits = ['Bash', 'PowerShell'].includes(input.tool_name) && onlyCommit(String(data.command ?? ''));
    const handoff = input.tool_name === 'Write' && HANDOFF.test(String(data.file_path ?? ''));
    if (commits || handoff) process.exit(0);
    process.stderr.write(
      `The context of the ${who} is about ${k} tokens, past the cap of ${stop / 1000}k: commit, write the handoff and ${main ? 'stop; a fresh session continues from it' : 'return; the main thread launches a fresh builder with it'}. ` +
      'Allowed now: git add, git commit, git status, and a Write to `specs/<card>/handoff.md` with what is done, what is left, the files, and the gate lines that pass and how to run them.\n'
    );
    process.exit(2);
  }

  const marker = join(tmpdir(), 'kit-context-cap');
  const id = !input.agent_id ? `main-${createHash('sha256').update(String(file)).digest('hex').slice(0, 16)}` : String(input.agent_id).replace(/[^\w.-]/g, '_');
  const warned = join(marker, `${id}.warned`);
  if (existsSync(warned)) process.exit(0);
  mkdirSync(marker, { recursive: true });
  writeFileSync(warned, k);
  const message = `Context of the ${who}: about ${k} tokens, past ${warn / 1000}k. At ${stop / 1000}k every tool but the commit and the handoff is refused: ` +
    `wrap up, commit and write \`specs/<card>/handoff.md\`${main ? '' : ' and return so the main thread launches a fresh one'}.`;
  process.stdout.write(JSON.stringify({ systemMessage: message, hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: message } }));
} catch { /* a saving: without a reading, it says nothing */ }
process.exit(0);
