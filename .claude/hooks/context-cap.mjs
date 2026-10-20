#!/usr/bin/env node
// PreToolUse on every tool: the context of an `implementer`, a `grunt` or a `conductor` is capped. One of them reached 303 thousand
// tokens re-read on every request. Its context is estimated from the `usage` of the last assistant message of its own
// transcript —input, cache read and cache creation tokens—: past 250k it is warned once; past 300k the next tool is
// refused unless it is a `git add`, `git commit` or `git status`, or a Write of its handoff
// `specs/<card>/handoff-*.md`, and it returns so the main thread launches a fresh one with that handoff.
// The main thread is never blocked: with a card in progress, past 230k it is warned once per session to write
// `specs/<card>/handoff.md` and launch the conductor, whose fresh context carries steps 6 to 9 (METHOD.md).
// The subagent's transcript is `agent_transcript_path` when the input has it, else the one next to the session
// transcript: `<session>/subagents/agent-<agent_id>.jsonl`. Without a readable transcript the hook says nothing:
// it is a saving, the guards that protect the card are others.
// Contract: exit 0 lets it through (stdout JSON carries the warning); exit 2 blocks and Claude reads stderr.
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { contextTokens, transcriptOf } from '../tools/transcript.mjs';

const MAIN_WARN_AT = 230_000;
const WARN_AT = 250_000;
const STOP_AT = 300_000;
const CAPPED = new Set(['implementer', 'grunt', 'conductor']);

// A command that is only `git add`, `git commit` and `git status`, perhaps after a `cd`: heredocs and quoted
// strings (a commit message) are taken out before it is split.
const GIT_ONLY = /^git(?:\s+-C\s+\S+)?\s+(?:add|commit|status)\b/;
const onlyCommit = (command) => {
  const bare = command.replace(/<<-?\s*['"]?(\w+)['"]?[\s\S]*?\n\s*\1\b/g, '').replace(/"[^"]*"|'[^']*'/g, '""');
  const segments = bare.split(/&&|;|\||\n/).map((s) => s.trim()).filter(Boolean);
  return segments.some((s) => GIT_ONLY.test(s)) && segments.every((s) => GIT_ONLY.test(s) || /^cd\s+\S+$/.test(s));
};
const HANDOFF = /(^|[\\/])specs[\\/][^\\/]+[\\/]handoff-[^\\/]*\.md$/;

let input;
let raw;
try { raw = readFileSync(0, 'utf8'); input = JSON.parse(raw); } catch { process.exit(0); }
try {
  await (await import('../tools/card.mjs')).delegateToRepo(import.meta.url, raw, input);
  if (!input.agent_id) {
    // The main thread is not capped: it is told, once, to hand what is left to the conductor.
    const file = input.transcript_path;
    if (!file || !existsSync(file)) process.exit(0);
    const used = contextTokens(file);
    if (used === null || used < MAIN_WARN_AT) process.exit(0);
    const card = (await import('../tools/card.mjs')).hookCard(input.cwd ?? process.cwd(), process.env, input);
    if (!card || existsSync(join(card.card, 'closing.md'))) process.exit(0);
    const marker = join(tmpdir(), 'kit-context-cap');
    const warned = join(marker, `main-${createHash('sha256').update(String(file)).digest('hex').slice(0, 16)}.warned`);
    if (existsSync(warned)) process.exit(0);
    mkdirSync(marker, { recursive: true });
    writeFileSync(warned, `${used}`);
    const message = `Context of the main thread: about ${Math.round(used / 1000)}k tokens, past ${MAIN_WARN_AT / 1000}k, and every request re-reads it. ` +
      'Write specs/<card>/handoff.md from templates/handoff.md, commit it and launch the conductor in the foreground with its path for steps 6 to 9 (or what is left of them): ' +
      'a fresh context carries the card from there to closing.md. Nothing is blocked.';
    process.stdout.write(JSON.stringify({
      systemMessage: message,
      hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: message },
    }));
    process.exit(0);
  }
  if (!CAPPED.has(input.agent_type)) process.exit(0);
  const file = transcriptOf(input);
  if (!file || !existsSync(file)) process.exit(0);
  const used = contextTokens(file);
  if (used === null || used < WARN_AT) process.exit(0);
  const k = `${Math.round(used / 1000)}k`;

  if (used >= STOP_AT) {
    const tool = input.tool_name;
    const data = input.tool_input ?? {};
    const commits = (tool === 'Bash' || tool === 'PowerShell') && onlyCommit(String(data.command ?? ''));
    const handoff = tool === 'Write' && HANDOFF.test(String(data.file_path ?? ''));
    if (commits || handoff) process.exit(0);
    const conducting = input.agent_type === 'conductor';
    process.stderr.write(
      `This ${input.agent_type}'s context is about ${k} tokens, past the cap of ${STOP_AT / 1000}k: commit, write the handoff, and return; the main thread launches a fresh ${conducting ? 'conductor with the same handoff.md and yours' : 'implementer'}. ` +
      (conducting
        ? 'Allowed now: git add, git commit, git status, and a Write to `specs/<card>/handoff-conductor.md` with the step you are in, the groups and rounds done, the open ACT and OUT, the validations that ran with their result, and the logs to read.\n'
        : 'Allowed now: git add, git commit, git status, and a Write to `specs/<card>/handoff-<group>.md` with what is done, what is left, the files, ' +
          'and the bounded checks that pass and how to run them.\n')
    );
    process.exit(2);
  }

  const marker = join(tmpdir(), 'kit-context-cap');
  const warned = join(marker, `${String(input.agent_id).replace(/[^\w.-]/g, '_')}.warned`);
  if (existsSync(warned)) process.exit(0);
  mkdirSync(marker, { recursive: true });
  writeFileSync(warned, k);
  const message = `Context of this ${input.agent_type}: about ${k} tokens, past ${WARN_AT / 1000}k. At ${STOP_AT / 1000}k every tool but the commit and the handoff is refused: ` +
    (input.agent_type === 'conductor'
      ? 'wrap up the round, commit, write `specs/<card>/handoff-conductor.md` and return so the main thread launches a fresh one.'
      : 'wrap up the group, commit, write `specs/<card>/handoff-<group>.md` and return so the main thread launches a fresh one.');
  process.stdout.write(JSON.stringify({
    systemMessage: message,
    hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: message },
  }));
} catch { /* a saving: without a reading, it says nothing */ }
process.exit(0);
