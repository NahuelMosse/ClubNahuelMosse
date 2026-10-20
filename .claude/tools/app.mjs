#!/usr/bin/env node
// app.mjs up|down|status|probe|pairs — one running app for every judge of the card, a shared probe of it and the pairs of captures.
//
// Measured: six agents of one verdict lap (inspector, verdict reviewer, visual judge, screen audit,
// accessibility, confirm-suspect) each started its own app, its own browser and its own data, and the
// setup errors of each cost more than the judgment. Now the main thread starts the app once and passes
// `APP_URL` to the judges.
//
// The plan's `## Verification` block says how, one line each (verify.mjs does not run them as checks):
//   app:  <command that starts the app>   it receives PORT (a free one) and DATA_DIR (a new folder
//                                         under .validation/app/) in its environment
//   seed: <command>                       optional; runs once after the app answers, with APP_URL, PORT
//                                         and DATA_DIR
// up:     nothing to do if the app of `.validation/app.json` lives, answers and was started from the
//         same code (the key of once.mjs); otherwise it brings the old one down by PID, starts a new one,
//         waits up to 60 s for the port, seeds, writes app.json and prints `APP_URL=<url>`.
// down:   brings the app down by PID and removes app.json (the data folder stays).
// status: app.json, and whether the app lives and is up to date. Exit 0 only if both.
// probe <steps.json> [--widths 320,390,1280] [--route "POST /x=201|500|hold"] [--axe] [--watch <locator>] [--contrast "<sel>,<sel>"]
//         drives the app of app.json (Playwright from the repo or KIT_PLAYWRIGHT_ROOT) through the steps —a JSON list of
//         {goto|fill|click|press|select|wait} with Playwright selectors; `goto` stays inside the app— at each width, and
//         writes `.validation/probe/w<width>-step<NN>.png` and `.json`: the focused element and its aria attributes, the
//         role=status/alert texts, scrollWidth against clientWidth, the animations running, axe violations with --axe,
//         and the count of each --watch locator at t=0 and +500 ms. --route answers requests of that method and path with
//         the status, or never (`hold`); repeat it per route. `--contrast` adds, per selector, the text color, the effective
//         background, size, weight, ratio and AA yes or no. `help.mjs judge` lists every flag. `--url <app url>` probes another app than the shared one and
//         `--out <folder>` writes there; `--quiet` prints nothing. It serves the main thread for the closing captures
//         (`once.mjs captures -- node .claude/tools/app.mjs probe <steps.json>` is what close.mjs check 17 cites) and the
//         judges, who use it before writing a script of their own.
// pairs <base> <steps.json> [--widths 320,390,1280]
//         the pairs the PAIRWISE reviewer compares: the base of the card (a commit: `review-range.mjs --base`) and HEAD through
//         the same steps. The base is checked out in a worktree under .validation/pairs and started with the plan's `app:`
//         line; if it does not start, does not serve a `goto` route of the steps or does not show the first `click` or `wait`
//         locator of the steps (a bare page at that route), `pairwise.md` is written «not applicable ·
//         no previous screen at <route>» and no reviewer is launched. Otherwise each pair is `<name>-X.png` and `<name>-Y.png`
//         in .validation/pairs, base and HEAD assigned at random, and the key is `.validation/pairs/key.json`. Needs the
//         shared app up (HEAD) for the pairs, not for the not-applicable verdict.
//         steps.json, one action per object (a selector is a Playwright one: css, `text=Save`, `role=button[name="Save"]`):
//           [ { "goto": "/" },
//             { "fill": "input[name=title]", "value": "Buy milk" },
//             { "click": "role=button[name=\"Add\"]" },
//             { "press": "Enter", "on": "input[name=title]" },
//             { "select": "select#status", "value": "done" },
//             { "wait": 300 } ]
//         `fill` and `select` take their text in `value`; `press` a key, to the page or to the locator in `on`; `wait`
//         milliseconds or a locator to wait for.
// Exit codes: 0 ok; 1 the app or the seed could not start (probe: no app, or a step failed); 3 the plan has no `app:` line
// (probe: 2 for a bad steps file or arguments, or no Playwright).
import { spawn, spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, openSync, closeSync, readFileSync, readdirSync, writeFileSync, rmSync, symlinkSync, unlinkSync, rmdirSync, copyFileSync } from 'node:fs';
import { createServer, connect } from 'node:net';
import { join } from 'node:path';
import { currentCard, keyOf } from './card.mjs';
import { endsWithLine } from './final-line.mjs';

const START_TIMEOUT_MS = 60_000;
const POLL_MS = 250;
const root = process.cwd();
const stateFile = join(root, '.validation', 'app.json');
const pause = (ms) => new Promise((done) => setTimeout(done, ms));

const readState = () => { try { return JSON.parse(readFileSync(stateFile, 'utf8')); } catch { return null; } };
const alive = (pid) => { try { process.kill(pid, 0); return true; } catch (e) { return e.code === 'EPERM'; } };
const answers = (port) => new Promise((done) => {
  const s = connect({ host: '127.0.0.1', port, timeout: 1000 });
  s.on('connect', () => { s.destroy(); done(true); });
  s.on('timeout', () => { s.destroy(); done(false); });
  s.on('error', () => done(false));
});
const freePort = () => new Promise((done, fail) => {
  const s = createServer();
  s.on('error', fail);
  s.listen(0, '127.0.0.1', () => { const { port } = s.address(); s.close(() => done(port)); });
});
// The process tree, by PID: never by name, other agents run node too.
const killTree = (pid) => {
  if (!alive(pid)) return;
  if (process.platform === 'win32') spawnSync('taskkill', ['/PID', String(pid), '/T', '/F'], { stdio: 'ignore' });
  else { try { process.kill(-pid, 'SIGKILL'); } catch { try { process.kill(pid, 'SIGKILL'); } catch {} } }
};

// The `app:` and `seed:` lines of the plan's `## Verification` block.
const environmentOf = () => {
  const cardDir = currentCard(root);
  const planPath = cardDir && join(cardDir, 'plan.md');
  const plan = planPath && existsSync(planPath) ? readFileSync(planPath, 'utf8') : '';
  const section = plan.split(/^## /m).find((s) => s.startsWith('Verification')) ?? '';
  const block = section.match(/```[^\n]*\n([\s\S]*?)```/)?.[1] ?? '';
  const line = (name) => block.split('\n').map((l) => l.trim()).find((l) => l.startsWith(`${name}:`))?.slice(name.length + 1).trim();
  return { app: line('app'), seed: line('seed') };
};
const keyFor = ({ app, seed }) => keyOf(root, [app, seed].filter(Boolean).join(' && '));

const needAppLine = (env) => {
  if (env.app) return;
  console.error('The plan has no `app:` line in its `## Verification` block. Add `app: <command>` with the command that starts the app (e.g. `app: node src/main.mjs`): it receives PORT and DATA_DIR in its environment. Optionally `seed: <command>` loads data once.');
  process.exit(3);
};

const stop = () => {
  const s = readState();
  if (s) killTree(s.pid);
  rmSync(stateFile, { force: true });
  return s;
};

// Starts the app detached, its output in `logPath`, and returns its PID. On Windows a child inherits every
// inheritable handle of its parent, including the pipe of `app.mjs up | tail`: the pipe stays open while the app
// lives and the command does not return. PowerShell's Start-Process goes through ShellExecute, which inherits
// none: the app is started from there, by PID of its shell.
const launch = (command, vars, logPath, cwd = root) => {
  const environment = { ...process.env, ...vars };
  if (process.platform !== 'win32') {
    const log = openSync(logPath, 'w');
    const child = spawn(command, { cwd, shell: true, detached: true, stdio: ['ignore', log, log], env: environment });
    closeSync(log);
    child.unref();
    return { pid: child.pid };
  }
  const script = "$p = Start-Process -FilePath cmd.exe -ArgumentList ('/d /s /c \"' + $env:SDD_APP_COMMAND + '\"') -WindowStyle Hidden -PassThru; $p.Id";
  const r = spawnSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', script], {
    cwd, encoding: 'utf8', windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'], timeout: 30_000,
    env: { ...environment, SDD_APP_COMMAND: `${command} > "${logPath}" 2>&1` },
  });
  const pid = Number(r.stdout?.trim().split(/\s+/).pop());
  if (!pid) {
    console.error(`The app could not be started (${r.stderr?.trim() || `exit ${r.status}`}): ${command}`);
    process.exit(1);
  }
  return { pid };
};

// Starts the plan's app from `cwd` on a free port with a new data folder, waits for the port and seeds it. Returns
// `{ ok: true, url, port, pid, dataDir, stamp }`, or `{ ok: false, why, tail, logPath }` with the app already brought down.
const startApp = async ({ app, seed }, cwd = root) => {
  const port = await freePort();
  const stamp = Date.now();
  const dataDir = join(root, '.validation', 'app', String(stamp));
  mkdirSync(dataDir, { recursive: true });
  const logPath = `${dataDir}.log`;
  const url = `http://127.0.0.1:${port}`;
  const child = launch(app, { PORT: String(port), DATA_DIR: dataDir }, logPath, cwd);
  const failed = (why) => {
    killTree(child.pid);
    const tail = existsSync(logPath) ? readFileSync(logPath, 'utf8').trim().split('\n').slice(-8).join('\n') : '';
    return { ok: false, why, tail, logPath };
  };
  const deadline = Date.now() + START_TIMEOUT_MS;
  while (!await answers(port)) {
    if (!alive(child.pid)) return failed(`The app exited before answering on port ${port}: ${app}`);
    if (Date.now() > deadline) return failed(`The app did not answer on port ${port} within ${START_TIMEOUT_MS / 1000} s: ${app}`);
    await pause(POLL_MS);
  }
  if (seed) {
    const r = spawnSync(seed, { cwd, shell: true, stdio: ['ignore', 2, 2], timeout: 120_000,
      env: { ...process.env, APP_URL: url, PORT: String(port), DATA_DIR: dataDir } });
    if (r.status !== 0) return failed(`The seed failed (exit ${r.status ?? r.signal}): ${seed}`);
  }
  return { ok: true, url, port, pid: child.pid, dataDir, stamp };
};

const up = async () => {
  const env = environmentOf();
  needAppLine(env);
  const key = keyFor(env);
  const current = readState();
  if (current && alive(current.pid) && await answers(current.port) && current.key === key) {
    console.log(`APP_URL=${current.url}`);
    return;
  }
  stop();
  const started = await startApp(env);
  if (!started.ok) {
    console.error(`${started.why}\n${started.tail}\nlog: ${started.logPath}`);
    process.exit(1);
  }
  const { url, port, pid, dataDir, stamp } = started;
  mkdirSync(join(root, '.validation'), { recursive: true });
  writeFileSync(stateFile, JSON.stringify({ url, port, pid, dataDir, key, startedAt: new Date(stamp).toISOString() }, null, 1));
  console.log(`APP_URL=${url}`);
};

// The pairs of the blind comparison: the card's base and HEAD through the same steps. The base is checked out beside the
// repo's work (a detached worktree under .validation/pairs, its node_modules linked), started with the plan's `app:` line
// and asked for each route of the steps; a base with no screen there, or that does not start, has no previous screen and
// `pairwise.md` says so without a reviewer. Otherwise both sides are probed, each pair gets a random X/Y and the key goes to
// `.validation/pairs/key.json`, which the PAIRWISE reviewer is never shown.
const PAIRS_USAGE = 'usage: node app.mjs pairs <base> <steps.json> [--widths 320,390,1280]  (base: `node .claude/tools/review-range.mjs --base`)';
const dropBaseSource = async (source, link) => {
  if (link) { try { unlinkSync(link); } catch { try { rmdirSync(link); } catch { /* not a link */ } } }
  for (let i = 0; i < 5; i++) {
    if (spawnSync('git', ['worktree', 'remove', '--force', source], { cwd: root, stdio: 'ignore' }).status === 0) break;
    await pause(300);
  }
  rmSync(source, { recursive: true, force: true });
  spawnSync('git', ['worktree', 'prune'], { cwd: root, stdio: 'ignore' });
};
const pairs = async (argv) => {
  const [base, stepsPath, ...widths] = argv;
  if (!base || !stepsPath || (widths.length && !(widths.length === 2 && widths[0] === '--widths'))) { console.error(PAIRS_USAGE); return 2; }
  let list;
  try { list = JSON.parse(readFileSync(join(root, stepsPath), 'utf8')); } catch (e) { console.error(`${stepsPath}: ${e.message}`); return 2; }
  const { firstTarget, gotoRoutes, labelPairs, notApplicable } = await import('./pairs.mjs');
  const routes = gotoRoutes(Array.isArray(list) ? list : []);
  if (!routes.length) { console.error('The steps file needs a `goto` step: the route is what the base is asked for.'); return 2; }
  const sha = spawnSync('git', ['rev-parse', '--verify', '--quiet', `${base}^{commit}`], { cwd: root, encoding: 'utf8' });
  if (sha.status !== 0) { console.error(`${base} is not a commit of this repo: pass the card's base (\`node .claude/tools/review-range.mjs --base\`).`); return 2; }
  const cardDir = currentCard(root);
  if (!cardDir) { console.error('No card in progress: pairwise.md belongs to the card.'); return 2; }
  const env = environmentOf();
  needAppLine(env);

  const dir = join(root, '.validation', 'pairs');
  const source = join(dir, 'base-src');
  rmSync(dir, { recursive: true, force: true });
  spawnSync('git', ['worktree', 'prune'], { cwd: root, stdio: 'ignore' });
  mkdirSync(dir, { recursive: true });
  const added = spawnSync('git', ['worktree', 'add', '--detach', source, sha.stdout.trim()], { cwd: root, encoding: 'utf8' });
  if (added.status !== 0) { console.error(`Could not check out ${base}: ${added.stderr.trim()}`); return 1; }
  let link = null;
  if (existsSync(join(root, 'node_modules'))) {
    try { symlinkSync(join(root, 'node_modules'), join(source, 'node_modules'), 'junction'); link = join(source, 'node_modules'); } catch { /* the base starts without them */ }
  }
  const { probe, shownAt } = await import('./probe.mjs');
  const rel = (name) => `.validation/pairs/${name}`;
  let started = null;
  try {
    started = await startApp(env, source);
    let missing = null;
    if (!started.ok) missing = { route: routes[0], why: `The base ${base} did not start: ${started.why}` };
    else {
      for (const route of routes) {
        const status = await fetch(new URL(route, started.url)).then((r) => r.status, () => 0);
        if (!(status >= 200 && status < 400)) { missing = { route, why: `The base ${base} answered ${status || 'nothing'} at ${route}.` }; break; }
      }
    }
    // A route that answers is not a screen: the base also has to show the first thing the steps wait for or click.
    const target = missing ? null : firstTarget(list);
    if (target && !(await shownAt(started.url, target.route, target.selector)))
      missing = { route: target.route, why: `The base ${base} answers ${target.route} but does not show ${target.selector}, the first thing the steps wait for or click.` };
    if (!missing && !readState()) { console.error('No app: `node .claude/tools/app.mjs up` writes .validation/app.json first.'); return 1; }
    if (missing) {
      writeFileSync(join(cardDir, 'pairwise.md'), notApplicable(missing.route, missing.why));
      console.log(`not applicable · no previous screen at ${missing.route}\n${missing.why}\nspecs/${cardDir.split(/[\\/]/).pop()}/pairwise.md written: no PAIRWISE reviewer is launched.`);
      return 0;
    }
    await probe([stepsPath, '--url', started.url, '--out', rel('base'), '--quiet', ...widths], root);
  } finally {
    if (started?.pid) killTree(started.pid);
    await dropBaseSource(source, link);
  }
  const headCode = await probe([stepsPath, '--out', rel('head'), '--quiet', ...widths], root);
  const captured = (side) => (existsSync(join(dir, side)) ? readdirSync(join(dir, side)).filter((n) => n.endsWith('.png')).map((n) => n.slice(0, -4)) : []);
  const names = captured('base').filter((n) => captured('head').includes(n)).sort();
  if (!names.length) {
    const why = `The base ${base} answered at ${routes[0]}, but none of the steps left a capture on both sides.`;
    writeFileSync(join(cardDir, 'pairwise.md'), notApplicable(routes[0], why));
    console.log(`not applicable · no previous screen at ${routes[0]}\n${why}`);
    return headCode === 0 ? 0 : 1;
  }
  const key = labelPairs(names);
  for (const name of names) for (const label of ['X', 'Y']) copyFileSync(join(dir, key[name][label], `${name}.png`), join(dir, `${name}-${label}.png`));
  writeFileSync(join(dir, 'key.json'), JSON.stringify(key, null, 1));
  console.log(`${names.length} pair${names.length === 1 ? '' : 's'} captured; the reviewer gets the images, never the key:`);
  for (const name of names) console.log(`${name} ${rel(`${name}-X.png`)} ${rel(`${name}-Y.png`)}`);
  console.log(`key: ${rel('key.json')} (yours: it says which side is X and which is Y, to turn a loss of the new screen into an ACT)`);
  if (headCode !== 0) console.error('The steps stopped before the end on the new screen: only the steps that left a capture on both sides are paired.');
  return 0;
};

const status = async () => {
  const s = readState();
  if (!s) { console.log('No app running: `node .claude/tools/app.mjs up` starts it.'); process.exit(1); }
  const lives = alive(s.pid) && await answers(s.port);
  const env = environmentOf();
  const fresh = env.app ? s.key === keyFor(env) : false;
  console.log(JSON.stringify(s, null, 1));
  console.log(`${lives ? 'alive' : 'not alive'}, ${fresh ? 'up to date' : 'out of date'}`);
  process.exit(lives && fresh ? 0 : 1);
};

const command = process.argv[2];
if (command === 'up') await up();
else if (command === 'down') { const s = stop(); console.log(s ? `Brought down ${s.url} (pid ${s.pid}).` : 'No app was running.'); }
else if (command === 'status') await status();
else if (command === 'probe') { endsWithLine('probe'); process.exit(await (await import('./probe.mjs')).probe(process.argv.slice(3), root)); }
else if (command === 'pairs') { endsWithLine('pairs'); process.exit(await pairs(process.argv.slice(3))); }
else { console.error('usage: node app.mjs up|down|status|probe|pairs'); process.exit(2); }
// The app lives on its own: the CLI must not wait for its pipes or timers.
process.exit(0);
