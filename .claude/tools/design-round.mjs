#!/usr/bin/env node
// design-round.mjs <url> --out <dir> [--steps <steps.json>] [--widths 1440x900,1024x768,768x1024,390x844] [--gpu] [--grain baked]
// `--grain baked` (also what a card's `## Look` declares when the grain is baked into the image files) makes the grain rule pass
// without a global layer and prints «grain: baked (declared)».
// One whole capture round of a screen in a single call, so the designer spends its turns looking and fixing, not taking captures.
// Per width it writes viewport captures, never a full page: the load at 0, 600 and 2000 ms; one per visible `section` or
// `[data-section]`, scrolled to the top of the viewport; and, with --steps, the ones of a probe steps file (`help.mjs judge`
// lists the actions; `{ "scroll": "<locator>" }` and `{ "wait": <ms> }` among them; a capture after every step).
// It measures with `page.evaluate`, against the ranges of `.claude/reference/excellence.md`: display/body ratio and display
// line height, display and body tracking, distinct font sizes in the first viewport, grain (a `grain` or `noise` class,
// `feTurbulence` or a `url(*noise*)`). It runs `motion-audit.mjs <url> --measure` and summarizes the load: waves (`startMs`
// grouped every 100 ms), their gap and the total duration. It lists the console errors and warnings.
// The WebGL renderer (`UNMASKED_RENDERER`) is always in the summary; a software one (SwiftShader) is flagged, because with it
// the motion times mean nothing. --gpu launches Chromium with `--use-angle=d3d11 --enable-gpu-rasterization
// --ignore-gpu-blocklist` on Windows (the last two elsewhere).
// By window class (`.claude/reference/responsive-classes.md`): widths under 600 (compact) measure tap targets under 44x44,
// hover-only reveals, inputs under 16 px, document overflow, media queries (min-width against max-width), the share of the viewport
// covered by fixed layers, where the first primary button falls and the navigation (bottom bar or labeled menu, not a bare
// hamburger); from 840 up, no hamburger; from 1200, clicks of 24 px or more and buttons that do not all measure 48 or more.
// Output: `<dir>/round.json` with everything, a short table on stdout (each rule: value, range, pass or fail; then the captures).
// Exit 0 whenever it ran, a failed rule included; 2 when it could not run (bad arguments, no Playwright, the URL does not answer).
// Run from the root of the repo of the card; Playwright is found there or at KIT_PLAYWRIGHT_ROOT.
// Measured: a designer round spent most of its turns writing a capture script and a measuring script, and ran out of turns
// before it corrected anything.
import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { parseSteps } from './probe.mjs';

const USAGE = 'usage: node design-round.mjs <url> --out <dir> [--steps <steps.json>] [--widths 1440x900,1024x768,768x1024,390x844] [--gpu] [--grain baked]';
const LOAD_MARKS = [0, 600, 2000];
const STEP_TIMEOUT_MS = 5000;

const playwright = () => {
  for (const root of [process.cwd(), process.env.KIT_PLAYWRIGHT_ROOT].filter(Boolean)) {
    const req = createRequire(join(root, 'package.json'));
    for (const name of ['playwright', '@playwright/test']) {
      try { return req(name); } catch { /* next */ }
    }
  }
  return null;
};

// Runs in the page: the typography and grain numbers of the first viewport.
export const measure = () => {
  const visible = (el) => {
    const r = el.getBoundingClientRect(); const cs = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight && cs.visibility !== 'hidden' && cs.display !== 'none';
  };
  const sizes = new Set();
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  for (let n = walker.nextNode(); n; n = walker.nextNode()) {
    const el = n.parentElement;
    if (!n.textContent.trim() || !el || !visible(el)) continue;
    sizes.add(Math.round(parseFloat(getComputedStyle(el).fontSize)));
  }
  const em = (cs) => (cs.letterSpacing === 'normal' ? 0 : parseFloat(cs.letterSpacing) / parseFloat(cs.fontSize));
  const lineHeight = (cs) => (cs.lineHeight === 'normal' ? 1.2 : parseFloat(cs.lineHeight) / parseFloat(cs.fontSize));
  let display = [...document.querySelectorAll('h1')].find(visible);
  if (!display) {
    let best = 0;
    for (const el of document.querySelectorAll('h2, h3, p, span, div, a')) {
      if (!visible(el) || ![...el.childNodes].some((c) => c.nodeType === 3 && c.textContent.trim())) continue;
      const size = parseFloat(getComputedStyle(el).fontSize);
      if (size > best) { best = size; display = el; }
    }
  }
  const body = getComputedStyle(document.body);
  const bodyPx = parseFloat(body.fontSize);
  const dcs = display ? getComputedStyle(display) : null;
  const displayPx = dcs ? parseFloat(dcs.fontSize) : null;
  const round = (v, d) => (v == null ? null : +v.toFixed(d));
  const grain = !!document.querySelector('.grain, [class*="grain"], [class*="noise"]')
    || !!document.querySelector('feTurbulence')
    || [...document.styleSheets].some((s) => { try { return [...s.cssRules].some((r) => /feTurbulence|url\([^)]*noise/i.test(r.cssText)); } catch { return false; } })
    || [...document.querySelectorAll('[style]')].some((e) => /url\([^)]*noise/i.test(e.getAttribute('style')));
  return {
    displayPx, bodyPx, ratio: round(displayPx && displayPx / bodyPx, 2),
    displayLineHeight: round(dcs && lineHeight(dcs), 3), displayTrackingEm: round(dcs && em(dcs), 3), bodyTrackingEm: round(em(body), 3),
    sizes: [...sizes].sort((a, b) => a - b), sizeCount: sizes.size, grain,
  };
};

// Runs in the page: what `responsive-classes.md` asks of the window class. Same-origin style sheets only.
export const measureResponsive = () => {
  const vw = innerWidth; const vh = innerHeight;
  const shown = (el) => {
    const r = el.getBoundingClientRect(); const cs = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none' && cs.opacity !== '0';
  };
  const label = (el) => `${el.tagName.toLowerCase()}${el.id ? `#${el.id}` : ''}${el.classList.length ? `.${[...el.classList].slice(0, 2).join('.')}` : ''}`;
  const rectOf = (el) => el.getBoundingClientRect();
  const size = (el) => `${label(el)} ${Math.round(rectOf(el).width)}x${Math.round(rectOf(el).height)}`;
  // Inline links inside running text are exempt from the target size (WCAG 2.5.8).
  const interactive = [...document.querySelectorAll('a[href], button, input:not([type=hidden]), select, textarea, summary, [role=button], [tabindex]:not([tabindex="-1"])')]
    .filter((el) => shown(el) && !(el.tagName === 'A' && getComputedStyle(el).display === 'inline'));
  const tapSmall = interactive.filter((el) => rectOf(el).width < 44 || rectOf(el).height < 44).map(size);
  const clickSmall = interactive.filter((el) => rectOf(el).width < 24 || rectOf(el).height < 24).map(size);
  // A card that is a button as a whole (a plan, a product) is not a control: past 64 px tall it is left out of the median.
  const heights = interactive.filter((el) => el.matches('button, [role=button], input[type=submit], input[type=button]')).map((el) => rectOf(el).height)
    .filter((h) => h <= 64).sort((a, b) => a - b);
  const medianButton = heights.length ? Math.round(heights[Math.floor(heights.length / 2)]) : null;

  const rules = [];
  const walk = (list) => { for (const r of list) { rules.push(r); if (r.cssRules) walk(r.cssRules); } };
  for (const sheet of document.styleSheets) { try { walk(sheet.cssRules); } catch { /* cross-origin sheet */ } }
  const styled = rules.filter((r) => r.selectorText);
  const tailsOf = (sel, pseudo) => sel.split(',').map((part) => { const i = part.lastIndexOf(pseudo); return i < 0 ? null : part.slice(i + pseudo.length).trim(); }).filter((t) => t);
  const focusTails = new Set(styled.flatMap((r) => [':focus-within', ':focus-visible', ':focus'].flatMap((p) => tailsOf(r.selectorText, p))));
  const hoverOnly = [];
  for (const r of styled) {
    if (!r.selectorText.includes(':hover') || !(r.style.display || r.style.visibility || r.style.opacity)) continue;
    if (tailsOf(r.selectorText, ':hover').some((tail) => !focusTails.has(tail))) hoverOnly.push(r.selectorText);
  }
  const smallFields = [...document.querySelectorAll('input:not([type=hidden]):not([type=checkbox]):not([type=radio]):not([type=range]), select, textarea')]
    .filter((el) => shown(el) && parseFloat(getComputedStyle(el).fontSize) < 16).map((el) => `${label(el)} ${parseFloat(getComputedStyle(el).fontSize)}px`);
  const queries = rules.filter((r) => r.media).map((r) => r.media.mediaText);
  const minQ = queries.filter((q) => /min-width/.test(q)).length;
  const maxQ = queries.filter((q) => /max-width/.test(q)).length;

  const pinned = (el) => ['fixed', 'sticky'].includes(getComputedStyle(el).position);
  let covered = 0;
  for (const el of document.body.querySelectorAll('*')) {
    if (!pinned(el) || !shown(el)) continue;
    const r = rectOf(el);
    covered += Math.max(0, Math.min(r.right, vw) - Math.max(r.left, 0)) * Math.max(0, Math.min(r.bottom, vh) - Math.max(r.top, 0));
  }
  const primary = interactive.find((el) => el.matches('[type=submit], [class*=primary], [class*=cta], [class*=btn], [class*=button]'))
    || interactive.find((el) => el.matches('button, a[href]') && !el.closest('nav, header'));
  let cta = null;
  if (primary) {
    let fixedBottom = false;
    for (let p = primary; p; p = p.parentElement) if (pinned(p) && rectOf(p).bottom >= vh - 4) fixedBottom = true;
    cta = { name: size(primary), topPct: Math.round((rectOf(primary).top / vh) * 100), pinned: fixedBottom };
  }
  const bottomBar = [...document.body.querySelectorAll('*')].some((el) => pinned(el) && shown(el) && rectOf(el).bottom >= vh - 4 && rectOf(el).width >= vw * 0.8 && el.querySelectorAll('a[href], button').length >= 3);
  const burger = interactive.find((el) => /burger|menu-toggle|nav-toggle|menu-btn|toggle-menu|menu-button|navbar-toggler/i.test(`${el.className} ${el.id}`)
    || (el.matches('button, [role=button]') && /^(menu|menú|open menu|toggle menu|navigation)$/i.test((el.getAttribute('aria-label') || '').trim()))
    || (el.matches('button, [role=button]') && el.hasAttribute('aria-expanded') && el.closest('header, nav') && !(el.textContent || '').trim()));
  return {
    width: vw, tapSmall, clickSmall, medianButton, hoverOnly, smallFields,
    overflow: { scrollWidth: document.documentElement.scrollWidth, clientWidth: document.documentElement.clientWidth },
    queries: { min: minQ, max: maxQ }, coveredPct: Math.min(100, Math.round((covered / (vw * vh)) * 100)), cta,
    nav: { bottomBar, hamburger: !!burger, hamburgerLabeled: !!burger && /menu|menú/i.test((burger.textContent || '').trim()) },
  };
};

// The rules of `responsive-classes.md` that apply to the window class of the width.
export const responsiveRules = (m) => {
  const row = (rule, value, range, pass, detail = []) => ({ rule, value, range, pass, detail });
  const out = [];
  if (m.width < 600) {
    out.push(
      row('tap targets under 44x44', m.tapSmall.length, '0', m.tapSmall.length === 0, m.tapSmall),
      row('hover-only reveals', m.hoverOnly.length, '0', m.hoverOnly.length === 0, m.hoverOnly),
      row('inputs under 16 px', m.smallFields.length, '0', m.smallFields.length === 0, m.smallFields),
      row('document overflow', m.overflow.scrollWidth > m.overflow.clientWidth ? `${m.overflow.scrollWidth} > ${m.overflow.clientWidth}` : 'none', 'none', m.overflow.scrollWidth <= m.overflow.clientWidth),
      row('media queries', `min ${m.queries.min} / max ${m.queries.max}${m.queries.max > m.queries.min ? ' · desktop-first' : ''}`, 'min >= max', m.queries.max <= m.queries.min),
      row('fixed layers (% of viewport)', m.coveredPct, '<= 20', m.coveredPct <= 20),
      m.cta
        ? row('cta reach (% of height)', m.cta.pinned ? `${m.cta.topPct} (pinned)` : m.cta.topPct, '>= 50 or pinned', m.cta.pinned || m.cta.topPct >= 50, [m.cta.name])
        : row('cta reach (% of height)', 'no button or link', 'n/a', true),
      row('navigation, compact', m.nav.bottomBar ? 'bottom bar' : m.nav.hamburger ? (m.nav.hamburgerLabeled ? 'labeled menu' : 'bare hamburger') : 'none', 'bottom bar or labeled menu', m.nav.bottomBar || !m.nav.hamburger || m.nav.hamburgerLabeled),
    );
  }
  if (m.width >= 840) out.push(row('hamburger, expanded', m.nav.hamburger ? 'yes' : 'no', 'no', !m.nav.hamburger));
  if (m.width >= 1200) {
    out.push(
      row('clicks under 24x24', m.clickSmall.length, '0', m.clickSmall.length === 0, m.clickSmall),
      row('median button height', m.medianButton ?? 'no buttons', '< 48 (all 48+ is a stretched mobile)', m.medianButton == null || m.medianButton < 48),
    );
  }
  return out;
};

// Runs in the page: the WebGL renderer, or null without WebGL.
const rendererOf = () => {
  try {
    const gl = document.createElement('canvas').getContext('webgl');
    const info = gl && gl.getExtension('WEBGL_debug_renderer_info');
    return info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : (gl ? gl.getParameter(gl.RENDERER) : null);
  } catch { return null; }
};

// The rules of `excellence.md` that a measure decides: value, range and whether it passes.
export const rulesOf = (m, grainBaked = false) => {
  const row = (rule, value, range, pass) => ({ rule, value, range, pass: value == null ? false : pass });
  return [
    row('display/body ratio', m.ratio, '5-9', m.ratio >= 5 && m.ratio <= 9),
    row('display line height', m.displayLineHeight, '<= 0.95', m.displayLineHeight <= 0.95),
    row('display tracking (em)', m.displayTrackingEm, '-0.03..-0.02', m.displayTrackingEm <= -0.02 && m.displayTrackingEm >= -0.05),
    row('body tracking (em)', m.bodyTrackingEm, '-0.03..-0.01', m.bodyTrackingEm <= -0.01 && m.bodyTrackingEm >= -0.05),
    row('font sizes, first viewport', m.sizeCount, '<= 9', m.sizeCount <= 9),
    row('grain or noise', m.grain ? 'yes' : grainBaked ? 'baked (declared)' : 'no', 'yes or baked', m.grain || grainBaked),
  ];
};

// The load waves out of motion-audit's `load` list: `startMs` grouped every 100 ms.
export const loadWaves = (load) => {
  const moving = load.filter((l) => l.endMs > l.startMs);
  if (!moving.length) return { waves: [], gapsMs: [], totalMs: 0 };
  const starts = moving.map((l) => l.startMs).sort((a, b) => a - b);
  const waves = [...new Set(starts.map((s) => Math.floor(s / 100) * 100))];
  return { waves, gapsMs: waves.slice(1).map((w, i) => w - waves[i]), totalMs: Math.round(Math.max(...moving.map((l) => l.endMs)) - starts[0]) };
};
const loadRules = (w) => {
  const row = (rule, value, range, pass) => ({ rule, value, range, pass });
  return [
    row('load waves', w.waves.length, '2-3', w.waves.length >= 2 && w.waves.length <= 3),
    row('load wave gap (ms)', w.gapsMs.length ? w.gapsMs.join('/') : '-', '200-300', w.gapsMs.length > 0 && w.gapsMs.every((g) => g >= 200 && g <= 300)),
    row('load total (ms)', w.totalMs, '900-2000', w.totalMs >= 900 && w.totalMs <= 2000),
  ];
};

const runStep = async (page, step, base) => {
  const loc = (s) => page.locator(s).first();
  if ('goto' in step) await page.goto(new URL(step.goto, base).href, { waitUntil: 'load', timeout: STEP_TIMEOUT_MS * 3 });
  else if ('fill' in step) await loc(step.fill).fill(step.value ?? '', { timeout: STEP_TIMEOUT_MS });
  else if ('click' in step) await loc(step.click).click({ timeout: STEP_TIMEOUT_MS });
  else if ('press' in step) await (step.on ? loc(step.on).press(step.press, { timeout: STEP_TIMEOUT_MS }) : page.keyboard.press(step.press));
  else if ('select' in step) await loc(step.select).selectOption(step.value ?? '', { timeout: STEP_TIMEOUT_MS });
  else if ('scroll' in step) { await loc(step.scroll).evaluate((el) => el.scrollIntoView({ block: 'start' })); await page.waitForTimeout(400); }
  else if (typeof step.wait === 'number') await page.waitForTimeout(step.wait);
  else if ('wait' in step) await loc(step.wait).waitFor({ timeout: STEP_TIMEOUT_MS });
};

const parseArgs = (argv) => {
  const args = [...argv];
  const take = (name) => { const i = args.indexOf(name); return i < 0 ? undefined : args.splice(i, 2)[1]; };
  const gpu = args.includes('--gpu');
  if (gpu) args.splice(args.indexOf('--gpu'), 1);
  const out = take('--out'); const steps = take('--steps'); const widths = take('--widths') ?? '1440x900,1024x768,768x1024,390x844';
  const grainFlag = take('--grain');
  const [url, ...extra] = args;
  const viewports = widths.split(',').map((v) => { const [w, h = '900'] = v.trim().split('x'); return { width: Number(w), height: Number(h) }; });
  if (!url || extra.length || !out || (grainFlag !== undefined && grainFlag !== 'baked') || viewports.some(({ width, height }) => !(width >= 200 && width <= 3000 && height >= 200 && height <= 3000))) return { error: USAGE };
  return { url, out: resolve(out), steps, viewports, gpu, grainBaked: grainFlag === 'baked' };
};

export const round = async (argv) => {
  const a = parseArgs(argv);
  if (a.error) return { code: 2, message: a.error };
  let steps = null;
  if (a.steps) {
    let list;
    try { list = JSON.parse(readFileSync(resolve(a.steps), 'utf8')); } catch (e) { return { code: 2, message: `${a.steps}: ${e.message}` }; }
    const parsed = parseSteps(list, a.url);
    if (parsed.error) return { code: 2, message: `${a.steps}: ${parsed.error}` };
    steps = parsed.steps;
  }
  const pw = playwright();
  if (!pw) return { code: 2, message: 'could not run: Playwright is not installed here nor at KIT_PLAYWRIGHT_ROOT' };
  mkdirSync(a.out, { recursive: true });
  const launchArgs = a.gpu ? (process.platform === 'win32' ? ['--use-angle=d3d11', '--enable-gpu-rasterization', '--ignore-gpu-blocklist'] : ['--enable-gpu-rasterization', '--ignore-gpu-blocklist']) : [];
  const browser = await pw.chromium.launch({ channel: 'chromium', args: launchArgs }).catch(() => pw.chromium.launch({ args: launchArgs }));
  const result = { url: a.url, gpu: a.gpu, renderer: null, software: null, widths: {}, console: [], captures: [], load: null, motion: null };
  try {
    for (const { width, height } of a.viewports) {
      const key = `${width}x${height}`;
      const dir = join(a.out, key);
      mkdirSync(dir, { recursive: true });
      const ctx = await browser.newContext({ viewport: { width, height }, deviceScaleFactor: 1, isMobile: width < 700, hasTouch: width < 700 });
      const page = await ctx.newPage();
      page.on('console', (m) => { if (['error', 'warning'].includes(m.type())) result.console.push({ width: key, type: m.type(), text: m.text().slice(0, 300) }); });
      page.on('pageerror', (e) => result.console.push({ width: key, type: 'error', text: String(e.message).slice(0, 300) }));
      const shot = async (name) => { const file = join(dir, `${name}.png`); await page.screenshot({ path: file }); result.captures.push(file); };
      const t0 = Date.now();
      try { await page.goto(a.url, { waitUntil: 'commit', timeout: 20000 }); } catch (e) { await ctx.close(); return { code: 2, message: `could not run: ${a.url} does not answer (${String(e.message).split('\n')[0]})` }; }
      for (const mark of LOAD_MARKS) {
        const wait = mark - (Date.now() - t0);
        if (wait > 0) await page.waitForTimeout(wait);
        await shot(`load-${String(mark).padStart(4, '0')}ms`);
      }
      await page.waitForLoadState('load', { timeout: 20000 }).catch(() => {});
      if (result.renderer === null) {
        result.renderer = await page.evaluate(rendererOf).catch(() => null);
        result.software = result.renderer ? /swiftshader|llvmpipe|software/i.test(result.renderer) : null;
      }
      const m = await page.evaluate(measure);
      const responsive = await page.evaluate(measureResponsive);
      result.widths[key] = { measure: m, responsive, rules: [...rulesOf(m, a.grainBaked), ...responsiveRules(responsive)] };
      const sections = await page.evaluate(() => {
        const els = [...document.querySelectorAll('section, [data-section]')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 && getComputedStyle(e).display !== 'none' && getComputedStyle(e).visibility !== 'hidden'; });
        els.forEach((e, i) => e.setAttribute('data-design-round', String(i)));
        return els.length;
      });
      for (let i = 0; i < sections; i++) {
        await page.locator(`[data-design-round="${i}"]`).evaluate((el) => el.scrollIntoView({ block: 'start' }));
        await page.waitForTimeout(500);
        await shot(`section-${String(i + 1).padStart(2, '0')}`);
      }
      await page.evaluate(() => { document.querySelectorAll('[data-design-round]').forEach((e) => e.removeAttribute('data-design-round')); window.scrollTo(0, 0); });
      if (steps) {
        for (const [i, step] of steps.entries()) {
          try { await runStep(page, step, a.url); } catch (e) { result.console.push({ width: key, type: 'step-error', text: `${JSON.stringify(step)}: ${String(e.message).split('\n')[0]}` }); }
          await shot(`step-${String(i + 1).padStart(2, '0')}-${Object.keys(step)[0]}`);
        }
      }
      await ctx.close();
    }
  } finally { await browser.close(); }

  const motionDir = join(a.out, 'motion');
  const ma = spawnSync(process.execPath, [join(import.meta.dirname, 'motion-audit.mjs'), a.url, '--measure', '--out', motionDir], { encoding: 'utf8', timeout: 180000, env: process.env });
  const reportFile = join(motionDir, 'report.json');
  if (existsSync(reportFile)) {
    const r = JSON.parse(readFileSync(reportFile, 'utf8'));
    result.load = loadWaves(r.load ?? []);
    result.load.rules = loadRules(result.load);
    result.motion = { report: reportFile, staggerMs: r.grammar?.staggerMs ?? null };
  } else result.motion = { error: `motion-audit did not write a report (exit ${ma.status}): ${(ma.stderr || ma.stdout || '').trim().split('\n')[0]}` };

  writeFileSync(join(a.out, 'round.json'), JSON.stringify(result, null, 1));
  const lines = [`design-round · ${a.url}`, `renderer: ${result.renderer ?? 'none (no WebGL)'}${result.software ? ' · SOFTWARE: motion times do not count' : ''}`];
  for (const [key, w] of Object.entries(result.widths)) {
    lines.push(`-- ${key}`);
    for (const r of w.rules) {
      if (r.value === 'baked (declared)') lines.push('  pass  grain: baked (declared)');
      else lines.push(`  ${r.pass ? 'pass' : 'FAIL'}  ${r.rule}: ${r.value ?? 'n/a'} (range ${r.range})`);
      if (!r.pass && r.detail?.length) lines.push(...r.detail.slice(0, 8).map((d) => `        ${d}`));
    }
  }
  lines.push('-- load');
  if (result.load) for (const r of result.load.rules) lines.push(`  ${r.pass ? 'pass' : 'FAIL'}  ${r.rule}: ${r.value} (range ${r.range})`);
  else lines.push(`  could not measure: ${result.motion.error}`);
  lines.push(`-- console: ${result.console.length} error or warning lines`);
  for (const c of result.console.slice(0, 10)) lines.push(`  [${c.width}] ${c.type}: ${c.text}`);
  lines.push(`-- captures (${result.captures.length})`, ...result.captures.map((f) => `  ${f}`), `round.json: ${join(a.out, 'round.json')}`);
  return { code: 0, message: lines.join('\n') };
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const argv = process.argv.slice(2);
  if (argv.includes('--help') || argv.includes('-h')) {
    const doc = [];
    for (const l of readFileSync(import.meta.filename, 'utf8').split('\n').slice(1)) { if (!l.startsWith('//')) break; doc.push(l.replace(/^\/\/ ?/, '')); }
    console.log(doc.slice(0, doc.findIndex((l) => l.startsWith('Measured'))).join('\n'));
    process.exit(0);
  }
  try {
    const { code, message } = await round(argv);
    (code === 0 ? console.log : console.error)(message);
    process.exit(code);
  } catch (e) { console.error(`could not run: ${e.message}`); process.exit(2); }
}
