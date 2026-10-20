// The browser side of `app.mjs probe`: drives the shared app (`.validation/app.json`) through a list of simple
// steps at several widths and writes, per step and width, `.validation/probe/w<width>-step<NN>.png` and `.json`.
// Playwright comes from the repo it runs in, or from KIT_PLAYWRIGHT_ROOT; axe from `axe-core` there, or AXE_CORE.
// `help.mjs judge` prints FLAGS, ACTION_DOC, EXAMPLE_STEPS, DEFAULT_OUT and RECORD_FIELDS from here: what a judge is told
// about the probe is what the code accepts.
// Measured: inspector, reviewer and judges each wrote their own script to read the same things from the app —
// the focus, what a status region says, whether the page scrolls sideways, whether a node was really gone, the
// contrast of a button —and each script's setup errors cost more than the judgment.
import { createRequire } from 'node:module';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

// One entry per flag: how it is written, what it does, and whether it may be repeated.
export const FLAGS = [
  { use: '--widths 320,390,1280', note: 'viewport widths in px (200 to 3000), comma separated; the default is 320,390,1280' },
  { use: '--route "METHOD /path=<status>|hold"', note: 'the app\'s backend answers that method and path with the status, or never (`hold`: the request stays pending)', repeat: true },
  { use: '--axe', note: 'axe violations of the page after each step' },
  { use: '--watch <locator>', note: 'count of the locator at t=0 and +500 ms after each step (a node that is really gone is 0 at t=0)', repeat: true },
  { use: '--contrast "<selector>[,<selector>…]"', note: 'per selector and step: text color, effective background, font size and weight, contrast ratio, AA yes or no' },
  { use: '--url <app url>', note: 'probe another app than the one of .validation/app.json' },
  { use: '--out <folder>', note: 'write there instead of .validation/probe' },
  { use: '--quiet', note: 'print nothing' },
];
export const USAGE = `usage: node app.mjs probe <steps.json> ${FLAGS.map((f) => `[${f.use}]${f.repeat ? '…' : ''}`).join(' ')}`;

// One action per step; `value` and `on` go beside it.
export const ACTION_DOC = {
  goto: '{ "goto": "/path" }  navigates; only inside the app',
  fill: '{ "fill": "<locator>", "value": "text" }',
  click: '{ "click": "<locator>" }',
  press: '{ "press": "Enter" }  a key to the page, or to a locator with "on": "<locator>"',
  select: '{ "select": "<locator>", "value": "option" }',
  wait: '{ "wait": 300 }  milliseconds, or { "wait": "<locator>" } until it shows',
};
const ACTIONS = Object.keys(ACTION_DOC);
export const EXAMPLE_STEPS = [
  { goto: '/' },
  { fill: 'input[name=title]', value: 'Buy milk' },
  { select: 'select#status', value: 'done' },
  { press: 'Enter', on: 'input[name=title]' },
  { click: 'role=button[name="Add"]' },
  { wait: 'text=Added' },
  { wait: 300 },
];
export const DEFAULT_OUT = '.validation/probe';
export const RECORD_FIELDS = 'width, step, action, url, error, activeElement (tag, id, role, name, aria), announcements (role=status/alert texts), scrollWidth and clientWidth, animations running, axe (null without --axe), watch (per --watch locator: t0, t500), contrast (per --contrast selector)';

const STEP_TIMEOUT_MS = 5000;
const WATCH_DELAY_MS = 500;

// The steps file, checked before a browser opens: a list of one-action objects, `goto` only inside the app.
export const parseSteps = (list, appUrl) => {
  if (!Array.isArray(list) || !list.length) return { error: 'the steps file is a non-empty JSON list of steps' };
  const origin = new URL(appUrl).origin;
  for (const [i, step] of list.entries()) {
    const n = i + 1;
    const actions = ACTIONS.filter((a) => step && typeof step === 'object' && a in step);
    if (actions.length !== 1) return { error: `step ${n}: unknown action (one of ${ACTIONS.join(', ')} per step)` };
    const value = step[actions[0]];
    if (actions[0] === 'wait' ? !(typeof value === 'number' && value >= 0 || typeof value === 'string' && value) : typeof value !== 'string' || !value)
      return { error: `step ${n}: ${actions[0]} needs ${actions[0] === 'wait' ? 'milliseconds or a locator' : 'a string'}` };
    if (actions[0] === 'goto' && new URL(value, appUrl).origin !== origin) return { error: `step ${n}: ${value} is outside the app (${origin})` };
  }
  return { steps: list };
};

// `POST /x=201`: the method, the path and what the app's backend answers; `hold` never answers.
export const parseRoute = (text) => {
  const m = text.match(/^([A-Za-z]+)\s+(\S+?)=(\d{3}|hold)$/);
  return m ? { method: m[1].toUpperCase(), path: m[2], answer: m[3] === 'hold' ? 'hold' : Number(m[3]) } : null;
};

// WCAG 2 contrast of two [r, g, b] colors (0-255), and the AA floor: 4.5:1, or 3:1 for large text
// (24 px, or 18.66 px in bold).
const channel = (c) => { const s = c / 255; return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4; };
const luminance = ([r, g, b]) => 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
export const contrastRatio = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};
export const isLargeText = (fontSize, fontWeight) => fontSize >= 24 || (fontSize >= 18.66 && fontWeight >= 700);
const hex = (rgb) => `#${rgb.map((c) => c.toString(16).padStart(2, '0')).join('')}`;
export const contrastOf = ({ color, background, fontSize, fontWeight }) => {
  const ratio = contrastRatio(color, background);
  const large = isLargeText(fontSize, fontWeight);
  const needed = large ? 3 : 4.5;
  return { color: hex(color), background: hex(background), fontSize, fontWeight, large, ratio: Math.round(ratio * 100) / 100, needed, aa: ratio >= needed };
};
export const contrastLine = (c) => (c.found === false
  ? `  contrast ${c.selector} · not on the page`
  : `  contrast ${c.selector} · ${c.color} on ${c.background}${c.approximate ? ' (a background image is under it: approximate)' : ''} · ${c.fontSize}px/${c.fontWeight}${c.large ? ' large' : ''} · ${c.ratio}:1 · AA ${c.aa ? 'pass' : `fail (needs ${c.needed})`}`);

const playwright = () => {
  for (const root of [process.cwd(), process.env.KIT_PLAYWRIGHT_ROOT].filter(Boolean)) {
    const req = createRequire(join(root, 'package.json'));
    for (const name of ['playwright', '@playwright/test']) {
      try { return req(name); } catch { /* next */ }
    }
  }
  return null;
};
const axeFile = () => {
  for (const root of [process.cwd(), process.env.KIT_PLAYWRIGHT_ROOT].filter(Boolean)) {
    try { return createRequire(join(root, 'package.json')).resolve('axe-core/axe.min.js'); } catch { /* next */ }
  }
  return process.env.AXE_CORE && existsSync(process.env.AXE_CORE) ? process.env.AXE_CORE : null;
};

// Runs in the page.
const snapshotPage = () => {
  const el = document.activeElement;
  const aria = {};
  if (el && el !== document.body) for (const a of el.attributes) if (a.name.startsWith('aria-')) aria[a.name] = a.value;
  const focus = el && el !== document.body
    ? { tag: el.tagName.toLowerCase(), id: el.id, role: el.getAttribute('role'), name: (el.getAttribute('aria-label') || el.innerText || el.value || '').trim().slice(0, 60), aria }
    : null;
  const announcements = [...document.querySelectorAll('[role=status],[role=alert]')]
    .map((e) => ({ role: e.getAttribute('role'), text: e.textContent.trim() })).filter((a) => a.text);
  const animations = document.getAnimations().filter((a) => a.playState === 'running')
    .map((a) => ({ name: a.animationName ?? a.transitionProperty ?? 'unnamed', type: a.constructor.name }));
  const doc = document.documentElement;
  return { activeElement: focus, announcements, scrollWidth: doc.scrollWidth, clientWidth: doc.clientWidth, animations };
};

// Runs in the page: the colors, size and weight of the first element of each selector. The background is the
// effective one: the element's own and each ancestor's, up to the first opaque one (white under the page),
// composited from the bottom. Any CSS color is read through a canvas, so oklch(), color-mix() and the rest arrive as sRGB.
const measureContrast = (selectors) => {
  const ctx = document.createElement('canvas').getContext('2d', { willReadFrequently: true });
  const rgba = (value) => {
    ctx.clearRect(0, 0, 1, 1);
    ctx.fillStyle = '#000';
    ctx.fillStyle = value;
    ctx.fillRect(0, 0, 1, 1);
    const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data;
    return a === 0 ? [0, 0, 0, 0] : [r, g, b, a / 255];
  };
  const over = (top, under) => [0, 1, 2].map((i) => Math.round(top[i] * top[3] + under[i] * (1 - top[3])));
  return selectors.map((selector) => {
    const el = document.querySelector(selector);
    if (!el) return { selector, found: false };
    const style = getComputedStyle(el);
    const layers = [];
    let approximate = false;
    for (let node = el; node; node = node.parentElement) {
      const s = getComputedStyle(node);
      const layer = rgba(s.backgroundColor);
      if (s.backgroundImage !== 'none') approximate = true;
      if (layer[3] > 0) layers.push(layer);
      if (layer[3] === 1) break;
    }
    let background = [255, 255, 255];
    for (const layer of layers.reverse()) background = over(layer, background);
    const text = rgba(style.color);
    return { selector, found: true, color: over(text, background), background, fontSize: parseFloat(style.fontSize), fontWeight: Number(style.fontWeight) || 400, approximate };
  });
};

const run = async (page, step, appUrl) => {
  const loc = (s) => page.locator(s).first();
  if ('goto' in step) await page.goto(new URL(step.goto, appUrl).href, { waitUntil: 'load', timeout: STEP_TIMEOUT_MS * 3 });
  else if ('fill' in step) await loc(step.fill).fill(step.value ?? '', { timeout: STEP_TIMEOUT_MS });
  else if ('click' in step) await loc(step.click).click({ timeout: STEP_TIMEOUT_MS });
  else if ('press' in step) await (step.on ? loc(step.on).press(step.press, { timeout: STEP_TIMEOUT_MS }) : page.keyboard.press(step.press));
  else if ('select' in step) await loc(step.select).selectOption(step.value ?? '', { timeout: STEP_TIMEOUT_MS });
  else if (typeof step.wait === 'number') await page.waitForTimeout(step.wait);
  else await loc(step.wait).waitFor({ timeout: STEP_TIMEOUT_MS });
};

// Whether `selector` is on the page the app at `appUrl` serves at `route`, within a few seconds. `app.mjs pairs` asks it of the
// base: true when it cannot tell (no Playwright), so the pairs go on and the probe reports the missing browser.
export const shownAt = async (appUrl, route, selector) => {
  const pw = playwright();
  if (!pw) return true;
  const browser = await (pw.chromium ?? pw.default.chromium).launch();
  try {
    const page = await browser.newPage();
    await page.goto(new URL(route, appUrl).href, { waitUntil: 'load', timeout: STEP_TIMEOUT_MS * 3 });
    await page.locator(selector).first().waitFor({ state: 'attached', timeout: STEP_TIMEOUT_MS / 2 });
    return true;
  } catch { return false; } finally { await browser.close(); }
};

export const probe = async (argv, root = process.cwd()) => {
  const args = [...argv];
  const take = (name) => { const found = []; for (let i = args.indexOf(name); i >= 0; i = args.indexOf(name)) found.push(args.splice(i, 2)[1]); return found; };
  const axe = args.includes('--axe');
  if (axe) args.splice(args.indexOf('--axe'), 1);
  const widths = (take('--widths')[0] ?? '320,390,1280').split(',').map(Number);
  const routeTexts = take('--route');
  const watches = take('--watch');
  const contrastFlags = take('--contrast');
  const contrasts = contrastFlags.flatMap((v) => String(v ?? '').split(',').map((s) => s.trim()).filter(Boolean));
  // `--url` probes another app than the shared one and `--out` writes elsewhere: `app.mjs pairs` takes the base this way.
  const [urlFlag] = take('--url');
  const [outFlag] = take('--out');
  const quiet = args.includes('--quiet');
  if (quiet) args.splice(args.indexOf('--quiet'), 1);
  const log = (...a) => { if (!quiet) console.log(...a); };
  const [stepsPath, ...extra] = args;
  if (!stepsPath || extra.length || widths.some((w) => !(w >= 200 && w <= 3000)) || [...routeTexts, ...watches].some((v) => !v)
    || contrastFlags.length && !contrasts.length) {
    console.error(USAGE);
    return 2;
  }
  const routes = routeTexts.map(parseRoute);
  if (routes.includes(null)) { console.error(`${USAGE}\n--route is METHOD /path=<status>|hold`); return 2; }

  let appUrl = urlFlag;
  if (!appUrl) try { appUrl = JSON.parse(readFileSync(join(root, '.validation', 'app.json'), 'utf8')).url; } catch { /* no state */ }
  if (!appUrl) { console.error('No app: `node .claude/tools/app.mjs up` writes .validation/app.json first.'); return 1; }
  let list;
  try { list = JSON.parse(readFileSync(join(root, stepsPath), 'utf8')); } catch (e) { console.error(`${stepsPath}: ${e.message}`); return 2; }
  const parsed = parseSteps(list, appUrl);
  if (parsed.error) { console.error(parsed.error); return 2; }

  const pw = playwright();
  if (!pw) { console.error('could not run: Playwright is not installed here nor at KIT_PLAYWRIGHT_ROOT'); return 2; }
  const axePath = axe ? axeFile() : null;
  if (axe && !axePath) { console.error('could not run --axe: axe-core is not installed here nor at KIT_PLAYWRIGHT_ROOT, and AXE_CORE does not name an axe.min.js'); return 2; }

  const out = outFlag ? join(root, outFlag) : join(root, DEFAULT_OUT);
  rmSync(out, { recursive: true, force: true });
  mkdirSync(out, { recursive: true });
  const browser = await (pw.chromium ?? pw.default.chromium).launch();
  let failed = false;
  try {
    for (const width of widths) {
      const context = await browser.newContext({ viewport: { width, height: 900 } });
      const page = await context.newPage();
      for (const r of routes) {
        await page.route(`**${r.path}`, (route) => {
          if (route.request().method() !== r.method) return route.continue();
          if (r.answer === 'hold') return undefined;
          return route.fulfill({ status: r.answer, contentType: 'application/json', body: '{}' });
        });
      }
      for (const [i, step] of parsed.steps.entries()) {
        const name = `w${width}-step${String(i + 1).padStart(2, '0')}`;
        let error = null;
        try { await run(page, step, appUrl); } catch (e) { error = `${JSON.stringify(step)}: ${String(e.message).split('\n')[0]}`; }
        const record = { width, step: i + 1, action: step, url: page.url(), error };
        try {
          const t0 = {};
          for (const w of watches) t0[w] = await page.locator(w).count();
          Object.assign(record, await page.evaluate(snapshotPage));
          if (contrasts.length) record.contrast = (await page.evaluate(measureContrast, contrasts)).map((c) => (c.found ? { selector: c.selector, ...contrastOf(c), approximate: c.approximate } : c));
          if (axePath) {
            if (await page.evaluate(() => typeof window.axe) === 'undefined') await page.addScriptTag({ path: axePath });
            const result = await page.evaluate(() => window.axe.run());
            record.axe = { violations: result.violations.map((v) => ({ id: v.id, impact: v.impact, help: v.help, nodes: v.nodes.slice(0, 5).map((n) => n.target.join(' ')) })) };
          } else record.axe = null;
          await page.screenshot({ path: join(out, `${name}.png`) });
          record.watch = {};
          if (watches.length) await page.waitForTimeout(WATCH_DELAY_MS);
          for (const w of watches) record.watch[w] = { t0: t0[w], t500: await page.locator(w).count() };
        } catch (e) { record.error ??= String(e.message).split('\n')[0]; }
        writeFileSync(join(out, `${name}.json`), JSON.stringify(record, null, 1));
        log(`${name} ${Object.keys(step)[0]} · focus ${record.activeElement ? `${record.activeElement.tag}${record.activeElement.id ? `#${record.activeElement.id}` : ''}` : 'none'} · announcements ${record.announcements?.length ?? 0} · scroll ${record.scrollWidth}/${record.clientWidth} · animations ${record.animations?.length ?? 0}${record.axe ? ` · axe ${record.axe.violations.length}` : ''}${error ? ` · ERROR ${error}` : ''}`);
        for (const c of record.contrast ?? []) log(contrastLine(c));
        if (error || record.error) { failed = true; break; }
      }
      await context.close();
    }
  } finally {
    await browser.close();
  }
  log(`probe written to ${out}`);
  return failed ? 1 : 0;
};
