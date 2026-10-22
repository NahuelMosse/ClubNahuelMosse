// What the hooks read from a transcript: where it is and the `usage` of its last assistant message.
// context-cap.mjs measures the context with it; guard-shell.mjs reads which prompt cache the author writes.
import { closeSync, fstatSync, openSync, readFileSync, readSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';

const TAIL_BYTES = 512 * 1024;

// The subagent's transcript is `agent_transcript_path` when the input has it, else the one next to the session
// transcript: `<session>/subagents/agent-<agent_id>.jsonl`. The main thread has no `agent_id`: null.
export const transcriptOf = (input) => {
  if (input.agent_transcript_path) return input.agent_transcript_path;
  const main = input.transcript_path;
  if (!main || !input.agent_id || !/^[\w.-]+$/.test(String(input.agent_id))) return null;
  if (/[\\/]subagents[\\/]agent-[\w.-]+\.jsonl$/.test(main)) return main;
  return join(dirname(main), basename(main, '.jsonl'), 'subagents', `agent-${input.agent_id}.jsonl`);
};

// The `usage` of the last assistant message that has one, or null. A compact boundary met first is null: the usage
// before it measures the context that was compacted, not the one in use.
export const lastUsage = (file) => {
  const fd = openSync(file, 'r');
  try {
    const size = fstatSync(fd).size;
    const length = Math.min(size, TAIL_BYTES);
    const buffer = Buffer.alloc(length);
    readSync(fd, buffer, 0, length, size - length);
    const lines = buffer.toString('utf8').split('\n');
    if (size > length) lines.shift();
    for (const line of lines.reverse()) {
      if (line.includes('"compact_boundary"')) {
        try { if (JSON.parse(line).subtype === 'compact_boundary') return null; } catch { /* a half-written line */ }
      }
      if (!line.includes('"usage"')) continue;
      let entry;
      try { entry = JSON.parse(line); } catch { continue; }
      const usage = entry.type === 'assistant' ? entry.message?.usage : null;
      if (usage) return usage;
    }
    return null;
  } finally { closeSync(fd); }
};

// The turns a subagent has used: its assistant messages with a distinct `message.id` (one turn is split in several lines).
export const countTurns = (file) => {
  const ids = new Set();
  for (const line of readFileSync(file, 'utf8').split('\n')) {
    if (!line.includes('"assistant"')) continue;
    try {
      const entry = JSON.parse(line);
      if (entry.type === 'assistant') ids.add(entry.message?.id ?? `line-${ids.size}`);
    } catch { /* a half-written last line */ }
  }
  return ids.size;
};

// A command that is only `git add`, `git commit` and `git status`, perhaps after a `cd`: heredocs and quoted
// strings (a commit message) are taken out before it is split.
const GIT_ONLY = /^git(?:\s+-C\s+\S+)?\s+(?:add|commit|status)\b/;
export const onlyCommit = (command) => {
  const bare = command.replace(/<<-?\s*['"]?(\w+)['"]?[\s\S]*?\n\s*\1\b/g, '').replace(/"[^"]*"|'[^']*'/g, '""');
  const segments = bare.split(/&&|;|\||\n/).map((s) => s.trim()).filter(Boolean);
  return segments.some((s) => GIT_ONLY.test(s)) && segments.every((s) => GIT_ONLY.test(s) || /^cd\s+\S+$/.test(s));
};

// The context the last assistant message with usage was sent with.
export const contextTokens = (file) => {
  const usage = lastUsage(file);
  return usage ? (usage.input_tokens ?? 0) + (usage.cache_read_input_tokens ?? 0) + (usage.cache_creation_input_tokens ?? 0) : null;
};
