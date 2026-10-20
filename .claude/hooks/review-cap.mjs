#!/usr/bin/env node
// PreToolUse on Skill and Agent: the same review does not run more than CAP times per card, and the
// judges that carry a pinned model are not launched with another one.
// Measured: one card ran /code-review sixteen times in a row; every round found something small,
// it was fixed and reviewed again. The “one round” rule was written and was not enough.
// Measured: the main thread launched the `inspector` with `model: sonnet` and `haiku`, overriding the
// `model: opus` of its frontmatter, and the verdict came out of a weaker judge.
// Measured: two rounds of `reviewer` over the scenarios in red used the card's cap of two, and the
// verdict reviewer that the grade asks for was refused. The reviewer counts per stage: the scenarios in
// red (the prompt starts with `RED-REVIEW`) have one round; the closing, two. At poc, where the grade
// launches no reviewer, the review of the red is not asked either.
// The verdict reviewer's second lap is allowed only when it adds something: an action of `actions.md` closes with
// something that is not a command, or the File map names 15 or more production files (`secondLap`, tools/card.mjs);
// the first lap always goes, and `review.md` is still required before the implementer's round of actions.
// The blind pairwise comparison (`PAIRWISE`) is a stage of its own, two rounds, apart from the verdict reviewer's.
// `/code-review` has one lap per card, counted from the repo its args name (`namedInPrompt` reads a Skill's `args`) so a
// session opened elsewhere still counts it; a call that names no repo and does not stand in the card's is refused.
// The visual judges (`VISUAL-JUDGE`) are not counted here: with 12 or fewer production files one goes, which
// `steps/m-ui-screen.md` and `steps/m-ui-craft.md` say, and the step holds the count.
// The card is the one `specs/.current` names, in the repo that holds it: the count is per card and
// per repo. It lives inside that repo's git folder: it is not committed and no cleanup of validation
// leftovers erases it — in .validation/ the close erased it and the cap reset. The branch is not the
// key: every card of a repo that works on `main` would share one count.
// Contract: exit 0 lets it through; exit 2 blocks and Claude reads stderr. If it cannot read what is
// being asked, it blocks: a cap that crashes and lets things through is not a cap.
import { readFileSync, writeFileSync, mkdirSync, existsSync, realpathSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
import { delegateToRepo } from '../tools/card.mjs';

const CAP = 2;
const REVIEWS = new Set(['code-review', 'simplify', 'design-review', 'accessibility-audit', 'design-deslop', 'architecture-review']);

const JUDGES = new Set(['reviewer', 'inspector', 'code-review']);

// Agents whose model is part of what they are: the judge, the second reader, the hard problem and the
// plan are as good as the model they run on. Their frontmatter decides; a call does not override it.
const PINNED = new Set(['inspector', 'reviewer', 'oracle', 'planner', 'conductor']);

// A prompt that pastes what the agent can read costs its length once in the caller's context and again in every
// request of the agent. Past this many characters the call is warned, not blocked.
const LONG_PROMPT = 3000;

// What the hook only advises is gathered and said in one message at the end: two JSON objects on stdout are not one.
const advice = [];
const finish = () => {
  if (advice.length) {
    const message = advice.join(' ');
    process.stdout.write(JSON.stringify({
      systemMessage: message,
      hookSpecificOutput: { hookEventName: 'PreToolUse', additionalContext: message },
    }));
  }
  process.exit(0);
};

let input;
let raw;
try { raw = readFileSync(0, 'utf8'); input = JSON.parse(raw); } catch (e) {
  process.stderr.write(`The review cap could not read what is being asked (${e.message}). It blocks when in doubt: retry.\n`);
  process.exit(2);
}
await delegateToRepo(import.meta.url, raw, input);
const { tool_name: tool, tool_input: data = {}, cwd = process.cwd() } = input;

if (tool === 'Agent' && PINNED.has(data.subagent_type) && data.model) {
  let pinned = null;
  try {
    const head = readFileSync(new URL(`../agents/${data.subagent_type}.md`, import.meta.url), 'utf8').match(/^---\r?\n([\s\S]*?)\r?\n---/);
    pinned = head?.[1].match(/^model:\s*(\S+)/m)?.[1] ?? null;
  } catch {}
  if (pinned && data.model !== pinned) {
    process.stderr.write(
      `The ${data.subagent_type} runs on ${pinned}, set in its frontmatter; the call asked for ${data.model}. Do not pass \`model\`: ` +
      'a judge on a weaker model gives a weaker verdict, and the cost of the lap is the same.\n'
    );
    process.exit(2);
  }
}

if (tool === 'Agent' && String(data.prompt ?? '').length > LONG_PROMPT) {
  advice.push(`The prompt of this agent is ${String(data.prompt).length} characters: point to files instead of pasting them (plan.md, handoff.md, the tests in red); the agent reads them in its own context.`);
}

// Measured: the visual judge and the accessibility and motion audits went to `general-purpose`, which
// inherits Opus and the whole context of the main thread. During a card every launch names its agent.
if (tool === 'Agent' && /^(general-purpose)?$/.test(String(data.subagent_type ?? '').trim())) {
  let open = null;
  try {
    const found = (await import('../tools/card.mjs')).hookCard(cwd, process.env, input);
    if (found && !existsSync(join(found.card, 'closing.md'))) open = found;
  } catch {}
  if (open) {
    process.stderr.write(
      'No `general-purpose` agent during a card: it inherits Opus and the whole context. Name the agent: `reviewer` for a judge with vision ' +
      '(prompt starting `VISUAL-JUDGE`), `inspector` for the judgment criteria, `executor` for commands such as motion-audit or axe, ' +
      '`runner` for suites and logs, `scout` to search, `grunt` for a decided change.\n'
    );
    process.exit(2);
  }
}

// Measured: the main thread sent a `scout` to read the kit's documents (`.claude/steps`, `.claude/commands`) and read the
// same documents again from the scout's report. `help.mjs step N` prints what every card needs from them in one read.
if (tool === 'Agent' && data.subagent_type === 'scout' && /\.claude\//.test(String(data.prompt ?? ''))) {
  let open = null;
  try {
    const found = (await import('../tools/card.mjs')).hookCard(cwd, process.env, input);
    if (found && !existsSync(join(found.card, 'closing.md'))) open = found;
  } catch {}
  if (open) {
    process.stderr.write(
      'The kit\'s documents are not delegated to a `scout`: during a card read them with `node .claude/tools/help.mjs step N` ' +
      '(N from 1 to 9, or `close`), which prints what that phase needs from them in one read. A tool: `node .claude/tools/help.mjs <tool>`.\n'
    );
    process.exit(2);
  }
}

// Measured: the reviewer of a card with a screen went out after the first round of actions.md, which forced a
// second round and a third complete verification (CRM-7: 240 min). The verdict reviewer goes out with the
// inspector and verify.mjs, and its findings join the same round.
if (tool === 'Agent' && data.subagent_type === 'implementer' && /actions\.md|\bACT-\d+/i.test(String(data.prompt ?? ''))) {
  let open = null;
  try { open = (await import('../tools/card.mjs')).hookCard(cwd, process.env, input); } catch {}
  if (open && !existsSync(join(open.card, 'closing.md')) && !existsSync(join(open.card, 'review.md'))) {
    let waits = false;
    try {
      const { cardFiles, cardStart, IS_CODE, NOT_PRODUCTION, reviewKinds } = await import('../tools/card.mjs');
      const { laneOf } = await import('../tools/lane.mjs');
      const kit = (await import('../tools/kit.mjs')).active(open.root);
      const plan = join(open.card, 'plan.md');
      if (!kit.exempt.without.has('reviewer') && !(existsSync(plan) && laneOf(readFileSync(plan, 'utf8')) === 'fast')) {
        const code = cardFiles(open.root, cardStart(open.root, open.card)).filter((f) => IS_CODE.test(f) && !NOT_PRODUCTION.test(f));
        const kinds = reviewKinds(open.root, code);
        waits = (kinds.screen && (!kit.known.includes('ui') || kit.on.has('ui'))) || kinds.writingRoute;
      }
    } catch {}
    if (waits) {
      process.stderr.write(
        'The card has a screen or a route that writes, and the verdict reviewer has not reported (no specs/<card>/review.md). ' +
        'Launch the verdict reviewer in the same message as the inspector and verify.mjs, and gather its findings with theirs into one round of actions.md: ' +
        'a reviewer that comes after the first round forces a second round and another complete verification.\n'
      );
      process.exit(2);
    }
  }
}

// Measured: a plan whose bar lacked lines, whose assumptions lacked `any-answer:` or whose `stable:` line could not
// run was found out by `require-bar` in the middle of the code and by the close at the end, each a lap. The first
// implementer or conductor of a card starts only on a plan that has them (tools/plan-check.mjs); once it passes,
// the card is not asked again.
if (tool === 'Agent' && ['implementer', 'conductor'].includes(data.subagent_type)) {
  let open = null;
  try { open = (await import('../tools/card.mjs')).hookCard(cwd, process.env, input); } catch {}
  if (open && !existsSync(join(open.card, 'closing.md'))) {
    const gitFolder = spawnSync('git', ['rev-parse', '--absolute-git-dir'], { cwd: open.root, encoding: 'utf8' }).stdout?.trim();
    const checked = join(gitFolder || join(open.root, '.validation'), 'sdd-plan-checked.json');
    const name = open.card.split(/[\\/]/).pop();
    let seen = {};
    try { if (existsSync(checked)) seen = JSON.parse(readFileSync(checked, 'utf8')); } catch {}
    if (!seen[name]) {
      let problems;
      try { problems = (await import('../tools/plan-check.mjs')).planProblems(open.root, open.card); } catch (e) {
        process.stderr.write(`The plan check could not read the plan of ${name} (${e.message}). It blocks when in doubt: retry.\n`);
        process.exit(2);
      }
      if (problems?.length) {
        process.stderr.write(
          `Not launching the ${data.subagent_type}: the plan of ${name} is missing\n${problems.map((p) => `- ${p}`).join('\n')}\n` +
          'It is the list `require-bar.mjs` and the close ask for, written beforehand so that it does not stop the code half-way. Fix specs/' +
          `${name}/plan.md, commit it and launch again; \`node .claude/tools/plan-check.mjs\` prints this list.\n`
        );
        process.exit(2);
      }
      if (problems) {
        mkdirSync(join(checked, '..'), { recursive: true });
        seen[name] = new Date().toISOString();
        writeFileSync(checked, JSON.stringify(seen, null, 1));
      }
    }
  }
}

let review = null;
if (tool === 'Skill') {
  const name = String(data.skill ?? '').split(':').pop();
  if (REVIEWS.has(name)) review = name;
} else if (tool === 'Agent' && ['reviewer', 'inspector'].includes(data.subagent_type)) {
  // The second judge that confirms or refutes the `suspect` findings (steps/08-verify.md) is not a
  // lap of its judge: it has a cap of its own, one per card, so that inspector lap 1, the
  // confirmation and the confirmation lap of a G or M action do not exceed the cap of 2.
  // The reviewer on the scenarios in red is not a lap of the verdict reviewer either: its own stage.
  // The visual judges of step 9 (`VISUAL-JUDGE`) are capped by that step, not by the verdict reviewer's count.
  const prompt = String(data.prompt ?? '');
  review = data.subagent_type === 'reviewer' && /^\s*VISUAL-JUDGE\b/.test(prompt) ? null
    : /^\s*CONFIRM-SUSPECT\b/.test(prompt) ? 'confirm-suspect'
    : data.subagent_type === 'reviewer' && /^\s*RED-REVIEW\b/.test(prompt) ? 'red-review'
      : data.subagent_type === 'reviewer' && /^\s*PAIRWISE\b/.test(prompt) ? 'pairwise'
        : data.subagent_type;
}
const STAGE = {
  'confirm-suspect': { cap: 1, label: 'the confirmation of `suspect` findings (CONFIRM-SUSPECT)' },
  'red-review': { cap: 1, label: 'the review of the scenarios in red (reviewer, RED-REVIEW)' },
  // The blind comparison of the screen against the previous one: its own reviewer, because the visual judge cannot
  // launch agents. Lap 0 and, when the judges' second lap is due, one more; neither uses the verdict reviewer's rounds.
  pairwise: { cap: CAP, label: 'the blind pairwise comparison (reviewer, PAIRWISE)' },
  reviewer: { cap: CAP, label: 'the verdict reviewer (reviewer)' },
  // One lap per card, in the message of step 8: its findings join the one round of actions.md and their ACTs close them.
  // Measured: five laps on one card, each of the later ones finding a line of prose or a space after a comma.
  'code-review': { cap: 1, label: '/code-review' },
  // One lap per close: as many launches as inspectors.mjs says for the card, once. The fixes of a G or
  // M action are confirmed by their test and verify.mjs, not by a second lap of the judge. Measured: three
  // laps of judges over one card.
  inspector: { cap: 1, label: 'the inspector (one lap per close)' },
};
const stageOf = (name) => STAGE[name] ?? { cap: CAP, label: name };
if (!review) finish();

// Past the cap of the plan's time plan, no new lap starts: the card closes with what it has and
// says what did not run. It does not rush the work in progress; it stops the laps that come after.
// Measured: a card with a 2-hour cap ran three rounds of comparison and verification for ten hours.
// Without a card in progress there is nothing to cap: the laps are the card's, and a count kept
// under the branch name was shared by every card and every run that happened on `main`.
let found;
try {
  found = (await import('../tools/card.mjs')).hookCard(cwd, process.env, input);
} catch (e) {
  process.stderr.write(`The review cap could not find the card (${e.message}). It blocks when in doubt: retry.\n`);
  process.exit(2);
}
if (!found) finish();
const { root, card } = found;
// A closed card has no laps left to count: its caps stay as they were, and judging the finished run
// from outside is not blocked by them.
if (existsSync(join(card, 'closing.md'))) finish();
const cardName = card.split(/[\\/]/).pop();

// A /code-review reads the repo it is given. A session opened in another directory runs it over that one:
// the args have to name the card's repo, unless the call already stands in it.
// Measured: a lap of /code-review over the kit's repo while the card was in another.
if (tool === 'Skill' && review === 'code-review') {
  const real = (p) => { try { return realpathSync.native(p); } catch { return p; } };
  const { namedInPrompt, rootOf } = await import('../tools/card.mjs');
  const isCardRepo = (p) => { const r = rootOf(join(p, '_')); return Boolean(r) && real(r) === real(root); };
  if (!namedInPrompt(input).some(isCardRepo) && !isCardRepo(cwd)) {
    process.stderr.write(
      `This /code-review would read ${cwd}, not the card's repo (${root}): pass the card's repo: \`node .claude/tools/review-range.mjs\` prints the args.\n`
    );
    process.exit(2);
  }
}

try {
  const { capMinutes, minutesSinceSnapshot } = await import('../tools/card.mjs');
  const plan = join(card, 'plan.md');
  if (existsSync(plan)) {
    const capMin = capMinutes(readFileSync(plan, 'utf8'));
    const elapsedMin = minutesSinceSnapshot(root, card);
    if (capMin !== null && elapsedMin !== null) {
      if (elapsedMin > capMin) {
        process.stderr.write(
          `The card is past its cap: ${Math.round(elapsedMin)} min since the snapshot, cap ${Math.round(capMin)} min. ` +
          `No new ${review} lap starts. Close with what there is: what was found and not fixed goes to the close ` +
          'as a finding, and what did not run is declared “could not run”. No more laps: what remains goes to the PR.\n'
        );
        process.exit(2);
      }
    }
  }
} catch {}

// The grade that launches no reviewer (poc) does not ask for the review of the scenarios in red.
if (review === 'red-review') {
  let without = new Set();
  try { without = (await import('../tools/kit.mjs')).active(root).exempt.without; } catch {}
  if (without.has('reviewer')) {
    process.stderr.write('The review of the scenarios in red is not asked at this grade: it launches no reviewer. Commit the scenarios in red without it.\n');
    process.exit(2);
  }
}

const gitDir = spawnSync('git', ['rev-parse', '--absolute-git-dir'], { cwd: root, encoding: 'utf8' }).stdout?.trim();
const dir = gitDir || join(root, '.validation');
const file = join(dir, 'sdd-reviews.json');
let counts = {};
try { if (existsSync(file)) counts = JSON.parse(readFileSync(file, 'utf8')); } catch {}
const key = `${cardName} · ${review}`;
const done = counts[key] ?? 0;
const stage = stageOf(review);
let cap = stage.cap;
if (review === 'inspector') {
  try { cap = Math.max(cap, (await import('../tools/inspectors.mjs')).inspectors(root)?.count ?? 0); } catch {}
}
const { label } = stage;

if (done >= cap) {
  process.stderr.write(
    `${label} already ran ${done} ${done === 1 ? 'time' : 'times'} on this card (${cardName}); the cap of that stage is ${cap}` +
    `${review === 'red-review' ? ' (the verdict reviewer has its own cap of 2)' : ''}. ` +
    'Another round will not leave it spotless: it will find something else small. What is left from ' +
    'the earlier reviews gets fixed without reviewing again if it does not change behavior, or is ' +
    'recorded as a finding at close. No more rounds: the PR is the review of what remains.\n'
  );
  process.exit(2);
}
// The verdict reviewer's second lap verifies what a command cannot: some action closes with something that is not a
// command, or the card is big. Otherwise the commands of the actions and the final verify.mjs verify the fixes.
if (review === 'reviewer' && done >= 1) {
  let lap = { needed: true };
  try { lap = (await import('../tools/card.mjs')).secondLap(root, card); } catch {}
  if (!lap.needed) {
    process.stderr.write(
      `${label} already ran once on this card (${cardName}), and a second lap is for what only a judge can verify: no action of actions.md closes ` +
      'with something that is not a command, and the File map has under 15 production files. The close conditions of the actions and the final ' +
      'verify.mjs verify the fixes; the card goes on with the first lap.\n'
    );
    process.exit(2);
  }
}
mkdirSync(dir, { recursive: true });
counts[key] = done + 1;
writeFileSync(file, JSON.stringify(counts, null, 1));

// The judges of a lap go out together, in one message. One launched more than two minutes after
// another of the same card and lap was waited for in series. Measured: reviewer and inspector
// launched one after the other cost about a minute and a half per card. The reviewer is optional
// at closing (a screen or a route that writes); when it runs, it goes in this same message.
// A lap is the n-th run of that judge on the card; the launches live next to the counts.
if (JUDGES.has(review)) {
  const timesFile = join(dir, 'sdd-review-times.json');
  let times = {};
  try { if (existsSync(timesFile)) times = JSON.parse(readFileSync(timesFile, 'utf8')); } catch {}
  const lap = `${cardName} · lap ${done + 1}`;
  const now = Date.now();
  const late = (times[lap] ?? []).some((l) => JUDGES.has(l.judge) && now - l.at > 2 * 60_000);
  times[lap] = [...(times[lap] ?? []), { judge: review, at: now }];
  writeFileSync(timesFile, JSON.stringify(times, null, 1));
  if (late) {
    advice.push('The verdict goes out in one message: inspector, /code-review and, if the card has a screen or a route that writes, reviewer together.');
  }
}
finish();
