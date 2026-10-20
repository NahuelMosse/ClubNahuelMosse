#!/usr/bin/env node
// PreToolUse on Read: a capture much larger than a screen, the criteria table, or (in a subagent) a file of
// more than 25,000 characters is not read whole into the context.
// Measured: two full-page strips of 11 thousand tokens each were read in the main thread and
// re-read on every request until the close, after the step said to look at viewport captures.
// It is a saving, not a guard: if it cannot read the image it lets it through.
import { openSync, readSync, closeSync, readFileSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

const WHOLE_FILE_CHARS = 25_000;
const MAX_HEIGHT = 1600;
const MAX_REFERENCE_HEIGHT = 2000;
const MAX_PIXELS = 2_600_000;

try {
  const raw = readFileSync(0, 'utf8');
  const input = JSON.parse(raw);
  await (await import('../tools/card.mjs')).delegateToRepo(import.meta.url, raw, input);
  const path = String(input.tool_input?.file_path ?? '');
  // The criteria table read whole is re-read on every request until the close.
  // Measured: close to a million tokens per card, after step 5 said to use bar.mjs.
  if (/[\\/]reference[\\/]criteria\.md$/i.test(path) && !input.tool_input?.limit) {
    process.stderr.write('criteria.md is not read whole: `node .claude/tools/bar.mjs` lists every criterion in one line each, and `node .claude/tools/bar.mjs <ID>…` gives the complete rows of the ones that apply.\n');
    process.exit(2);
  }
  // A subagent reads a big file by its range: whole, it stays in its context for every request that follows.
  // Not images or PDFs (read by pages), nor the card's plan and snapshot, which the agent has to read whole.
  const absolute = resolve(input.cwd ?? process.cwd(), path);
  if (input.agent_id && path && input.tool_input?.offset === undefined && input.tool_input?.limit === undefined &&
      !/\.(png|jpe?g|gif|webp|svg|pdf)$/i.test(path) && statSync(absolute).size > WHOLE_FILE_CHARS &&
      readFileSync(absolute, 'utf8').length > WHOLE_FILE_CHARS) {
    const found = (await import('../tools/card.mjs')).hookCard(input.cwd ?? process.cwd(), process.env, input);
    const own = (name) => found && resolve(found.card, name) === absolute;
    if (!own('plan.md') && !own('card.snapshot.md')) {
      process.stderr.write(
        `This file has more than ${WHOLE_FILE_CHARS.toLocaleString('en-US')} characters and read whole it stays in your context for every request that follows. ` +
        'Grep first, then Read the range with offset/limit.\n'
      );
      process.exit(2);
    }
  }
  if (!/\.png$/i.test(path)) process.exit(0);
  const fd = openSync(path, 'r');
  const head = Buffer.alloc(24);
  readSync(fd, head, 0, 24, 0);
  closeSync(fd);
  if (head.toString('ascii', 12, 16) !== 'IHDR') process.exit(0);
  const width = head.readUInt32BE(16);
  const height = head.readUInt32BE(20);
  if (height <= MAX_HEIGHT && width * height <= MAX_PIXELS) process.exit(0);
  // Read has no way to read an image by parts, and the judge needs the design references whole.
  if (/[\\/]design[\\/]references[\\/]/i.test(path) && height <= MAX_REFERENCE_HEIGHT && width * height <= MAX_PIXELS) process.exit(0);
  const tokens = Math.round((Math.min(width, 1568) * Math.min(height, 1568 * (height / width))) / 750 / 1000);
  process.stderr.write(
    `This capture is ${width} × ${height}: about ${Math.max(tokens, 5)} thousand tokens, re-read on every request that follows. ` +
    'Look at a capture of the viewport (`fullPage: false`, deviceScaleFactor 1) of the state the card changed, ' +
    'or have a subagent look at the full strip against the visual brief and report what it found (steps/m-ui-screen.md).\n'
  );
  process.exit(2);
} catch {
  process.exit(0);
}
