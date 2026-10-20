#!/usr/bin/env node
// motion-audit.mjs <url> [--only <selector>]… [--cpu <rate>] [--frames <selector>]… [--out <dir>] [--measure] [--max <n>]
// Run from the root of the repo of the card; Playwright is found there or at KIT_PLAYWRIGHT_ROOT.
//
// Whether every state change of a screen has a designed response, measured in the browser and not
// in the code. For each interactive element —or only the ones given with --only—: what changes on
// hover, on press and on focus, with what transition, curve and duration; whether the sections
// animate when they first enter on scroll; which animation frames take longer than 50 ms, also with
// the CPU throttled (--cpu 4 is the “mediocre hardware”); and what remains with
// prefers-reduced-motion. --frames builds a contact sheet of the element's hover and press, one frame
// every 40 ms, so that the motion can be looked at: a still capture does not show it.
// --measure only records what it finds, for reading a reference site; without it, exits 1 if there
// is something to fix, with one line per finding.
// Measured: a screen that passed every validation moved nothing but colors in 100 ms, and nothing
// in the kit looked at whether each element responded.
import { mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const VISIBLE_PROPS = ['transform', 'opacity', 'background-color', 'background-image', 'color', 'box-shadow', 'border-color', 'outline-style', 'outline-width', 'outline-color', 'text-decoration-color', 'filter', 'scale', 'translate'];
const LAYOUT_PROPS = /^(width|height|top|left|right|bottom|margin|padding|max-height|max-width|min-height|min-width)/;
const INTERACTIVE = 'a[href], button, input:not([type=hidden]), select, textarea, summary, [role=button], [role=tab], [role=switch], [role=menuitem], [role=checkbox], [role=link], [tabindex]:not([tabindex="-1"])';

const args = process.argv.slice(2);
const opt = (name) => args.flatMap((a, i) => (a === name ? [args[i + 1]] : []));
const url = args.find((a, i) => !a.startsWith('--') && !args[i - 1]?.startsWith('--'));
const only = opt('--only');
const frames = opt('--frames');
const cpu = Number(opt('--cpu')[0] ?? 0);
const out = resolve(opt('--out')[0] ?? join('.validation', 'motion'));
const measure = args.includes('--measure');
const max = Number(opt('--max')[0] ?? 40);

// Playwright from the repo the tool runs in; failing that, from KIT_PLAYWRIGHT_ROOT (the kit's own tests,
// a machine where Playwright lives in another repo). The output always goes under the cwd.
const playwright = () => {
  for (const root of [process.cwd(), process.env.KIT_PLAYWRIGHT_ROOT].filter(Boolean)) {
    const req = createRequire(join(root, 'package.json'));
    for (const name of ['playwright', '@playwright/test']) {
      try { return req(name); } catch {}
    }
  }
  return null;
};

// The values of a duration list like "0.15s, 200ms" in milliseconds.
const ms = (list) => String(list).split(',').map((s) => s.trim()).map((s) => (s.endsWith('ms') ? parseFloat(s) : parseFloat(s) * 1000));

export const judge = (el) => {
  const problems = [];
  const name = el.label;
  for (const [moment, data] of Object.entries(el.moments)) {
    if (!data) continue;
    if (moment === 'hover' && el.selected) continue;
    const responds = data.changed.length > 0 || data.pixels;
    if (moment !== 'focus' && !responds) problems.push(`${name} · ${moment}: nothing visible changes`);
    if (moment === 'focus' && !responds) problems.push(`${name} · focus: no visible focus`);
    const animated = data.changed.filter((p) => data.transitioned.includes(p) || data.transitioned.includes('all'));
    const teleported = data.changed.filter((p) => !animated.includes(p) && !/^outline/.test(p));
    if (moment !== 'focus' && data.changed.length && teleported.length === data.changed.length) problems.push(`${name} · ${moment}: changes without a transition (${teleported.join(', ')})`);
  }
  const t = el.transition;
  if (t.properties.includes('all') && t.durations.some((d) => d > 0)) problems.push(`${name}: \`transition: all\``);
  const layout = t.properties.filter((p) => LAYOUT_PROPS.test(p));
  if (layout.length) problems.push(`${name}: animates layout (${layout.join(', ')}) — only transform and opacity`);
  for (const d of t.durations) if (d > 0 && (d < 50 || d > 400)) problems.push(`${name}: duration ${d} ms, out of 50–400 for an interaction`);
  if (t.easings.some((e) => /^ease-in$|cubic-bezier\(0\.[4-9]\d*, 0, 1, 1\)/.test(e))) problems.push(`${name}: ease-in on an interaction: it delays the response`);
  if (t.easings.some((e) => e === 'linear')) problems.push(`${name}: linear curve on an interaction`);
  if (el.reduced?.moves) problems.push(`${name}: with prefers-reduced-motion it still moves (${el.reduced.moves})`);
  return problems;
};

const snapshotIn = (handle, props) => handle.evaluate((node, props) => {
  const cs = getComputedStyle(node);
  return Object.fromEntries(props.map((p) => [p, cs.getPropertyValue(p)]));
}, props);

const diff = (a, b) => Object.keys(a).filter((k) => a[k] !== b[k]);
const shot = async (page, box) => (await page.screenshot({ clip: { x: Math.max(0, box.x - 6), y: Math.max(0, box.y - 6), width: box.width + 12, height: box.height + 12 } })).toString('base64');

const auditElement = async (page, original, label) => {
  // A visually hidden input (custom checkbox or switch) is felt through its label.
  const proxy = await original.evaluateHandle((n) => (n.matches('input') && getComputedStyle(n).opacity === '0' ? n.closest('label') ?? n : n));
  const handle = proxy.asElement() ?? original;
  const selected = await original.evaluate((n) => n.getAttribute('aria-selected') === 'true' || n.getAttribute('aria-checked') === 'true');
  const box = await handle.boundingBox();
  if (!box || box.width < 2 || box.height < 2) return null;
  const transition = await handle.evaluate((node) => {
    const cs = getComputedStyle(node);
    return { properties: cs.transitionProperty.split(',').map((s) => s.trim()), durations: cs.transitionDuration, easings: cs.transitionTimingFunction.split(/,(?![^(]*\))/).map((s) => s.trim()) };
  });
  transition.durations = ms(transition.durations);
  // Inputs, scroll regions made focusable with tabindex and skip links only owe a visible focus.
  const kind = await handle.evaluate((n) => {
    if (/^(INPUT|SELECT|TEXTAREA)$/.test(n.tagName) && getComputedStyle(n).opacity !== '0') return 'input';
    const role = n.getAttribute('role');
    if ((!role && !/^(A|BUTTON|SUMMARY)$/.test(n.tagName)) || /^(region|group|table|figure|img|document|tabpanel|list|article)$/.test(role ?? '')) return 'focus-only';
    const cs = getComputedStyle(n);
    if (cs.opacity === '0' || n.getBoundingClientRect().bottom <= 0 || n.getBoundingClientRect().top >= innerHeight + scrollY + 2000) return 'focus-only';
    return role ?? n.tagName.toLowerCase();
  });
  const moments = {};
  const rest = await snapshotIn(handle, VISIBLE_PROPS);
  const cx = box.x + box.width / 2;
  const cy = box.y + box.height / 2;
  if (kind === 'focus-only') {
    const beforePx = await shot(page, box);
    await page.keyboard.press('Shift');
    await handle.focus().catch(() => {});
    await page.waitForTimeout(250);
    const focused = await snapshotIn(handle, VISIBLE_PROPS);
    const pixels = (await shot(page, box)) !== beforePx;
    await handle.evaluate((n) => n.blur?.());
    return { label, kind, selected, transition, moments: { focus: { changed: diff(rest, focused), pixels, transitioned: transition.properties, values: {} } } };
  }
  const restPx = await shot(page, box);
  // Hover
  await page.mouse.move(cx, cy);
  await page.waitForTimeout(450);
  const hover = await snapshotIn(handle, VISIBLE_PROPS);
  const hoverPx = await shot(page, box);
  moments.hover = { changed: diff(rest, hover), pixels: hoverPx !== restPx, transitioned: transition.properties, values: Object.fromEntries(diff(rest, hover).map((k) => [k, [rest[k], hover[k]]])) };
  // Press: down on the element, up away from it, so that nothing is clicked.
  if (kind !== 'input') {
    await page.mouse.down();
    await page.waitForTimeout(200);
    const pressed = await snapshotIn(handle, VISIBLE_PROPS);
    const pressPx = await shot(page, box);
    moments.press = { changed: diff(hover, pressed), pixels: pressPx !== hoverPx, transitioned: transition.properties, values: Object.fromEntries(diff(hover, pressed).map((k) => [k, [hover[k], pressed[k]]])) };
    await page.mouse.move(1, 1);
    await page.mouse.up();
  } else {
    await page.mouse.move(1, 1);
  }
  await page.waitForTimeout(300);
  // Focus by keyboard semantics: focus() plus a keydown elsewhere first makes :focus-visible apply.
  // The ring of a hidden input is drawn on the element after it.
  const ring = await original.evaluateHandle((n) => (n.matches('input') && getComputedStyle(n).opacity === '0' ? n.nextElementSibling ?? n : n));
  const ringEl = ring.asElement() ?? original;
  const before = await snapshotIn(ringEl, VISIBLE_PROPS);
  const beforePx = await shot(page, box);
  await page.keyboard.press('Shift');
  await original.focus().catch(() => {});
  await page.waitForTimeout(250);
  const focused = await snapshotIn(ringEl, VISIBLE_PROPS);
  moments.focus = { changed: diff(before, focused), pixels: (await shot(page, box)) !== beforePx, transitioned: transition.properties, values: Object.fromEntries(diff(before, focused).map((k) => [k, [before[k], focused[k]]])) };
  await original.evaluate((n) => n.blur?.());
  return { label, kind, selected, transition, moments };
};

const describe = (handle, i) => handle.evaluate((n, i) => {
  const text = (n.getAttribute('aria-label') || n.textContent || n.getAttribute('placeholder') || n.getAttribute('name') || '').trim().replace(/\s+/g, ' ').slice(0, 32);
  return `${n.tagName.toLowerCase()}${n.id ? `#${n.id}` : ''}${text ? ` “${text}”` : ''} [${i}]`;
}, i);

const entrances = async (page) => page.evaluate(async () => {
  // Each heading below the first screen stands for its section: its closest block container.
  const sections = [...new Set([...document.querySelectorAll('h2, h3')]
    .map((h) => h.closest('section, article, li, div') ?? h)
    .filter((c) => c.getBoundingClientRect().top + scrollY > innerHeight))]
    .filter((c, _, all) => !all.some((o) => o !== c && o.contains(c)));
  const moved = new Set();
  const owner = (t) => sections.find((s) => s === t || s.contains(t));
  const mark = (e) => { const s = owner(e.target); if (s) moved.add(s); };
  document.addEventListener('animationstart', mark, true);
  document.addEventListener('transitionstart', mark, true);
  const mo = new MutationObserver((list) => { for (const m of list) { const s = owner(m.target); if (s && m.attributeName === 'style') moved.add(s); } });
  mo.observe(document.body, { subtree: true, attributes: true, attributeFilter: ['style'] });
  for (let y = 0; y < document.documentElement.scrollHeight; y += 160) {
    window.scrollTo(0, y);
    await new Promise((r) => setTimeout(r, 90));
    for (const a of document.getAnimations()) { const s = a.effect?.target && owner(a.effect.target); if (s) moved.add(s); }
  }
  await new Promise((r) => setTimeout(r, 600));
  mo.disconnect();
  window.scrollTo(0, 0);
  return sections.slice(0, 30).map((s) => ({ section: (s.querySelector('h2, h3')?.textContent ?? s.tagName).trim().slice(0, 40), animated: moved.has(s) }));
});

const longFrames = (page) => page.evaluate(() => new Promise((done) => {
  const frames = [];
  try {
    new PerformanceObserver((list) => frames.push(...list.getEntries().map((e) => Math.round(e.duration)))).observe({ type: 'long-animation-frame', buffered: false });
  } catch { done(null); return; }
  let y = 0;
  const step = () => {
    y += innerHeight / 2;
    window.scrollTo(0, y);
    if (y < document.body.scrollHeight) setTimeout(step, 120); else setTimeout(() => { window.scrollTo(0, 0); done(frames.filter((d) => d > 50)); }, 400);
  };
  step();
}));

const SHEET_MAX_HEIGHT = 1600;
const contactSheet = async (page, browser, selector) => {
  const handle = await page.$(selector);
  if (!handle) return null;
  await handle.scrollIntoViewIfNeeded();
  const box = await handle.boundingBox();
  if (!box) return null;
  const pad = 16;
  const clip = { x: Math.max(0, box.x - pad), y: Math.max(0, box.y - pad), width: box.width + pad * 2, height: box.height + pad * 2 };
  const shots = [];
  const take = async () => shots.push((await page.screenshot({ clip })).toString('base64'));
  await take();
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  for (let i = 0; i < 8; i++) { await page.waitForTimeout(40); await take(); }
  await page.mouse.down();
  for (let i = 0; i < 5; i++) { await page.waitForTimeout(40); await take(); }
  await page.mouse.move(1, 1);
  await page.mouse.up();
  for (let i = 0; i < 6; i++) { await page.waitForTimeout(40); await take(); }
  const sheet = await browser.newPage({ viewport: { width: 1200, height: 200 } });
  await sheet.setContent(`<body style="margin:0;background:#888;display:flex;flex-wrap:wrap;align-content:flex-start;gap:4px;padding:4px">${shots.map((s, i) => `<figure style="margin:0;font:10px sans-serif;color:#fff"><img src="data:image/png;base64,${s}"><figcaption>${i * 40} ms${i === 1 ? ' hover' : i === 9 ? ' press' : i === 14 ? ' out' : ''}</figcaption></figure>`).join('')}</body>`);
  const base = join(out, selector.replace(/[^\w-]+/g, '_').slice(0, 60));
  // Each file stays within what light-images lets be read (SHEET_MAX_HEIGHT): a taller sheet goes in parts.
  const total = await sheet.evaluate(() => document.documentElement.scrollHeight);
  const parts = Math.max(1, Math.ceil(total / SHEET_MAX_HEIGHT));
  const files = [];
  for (let i = 0; i < parts; i++) {
    const file = `${base}${i ? `-${i + 1}` : ''}.png`;
    const y = i * SHEET_MAX_HEIGHT;
    await sheet.screenshot({ path: file, fullPage: true, clip: { x: 0, y, width: 1200, height: Math.min(SHEET_MAX_HEIGHT, total - y) } });
    files.push(file);
  }
  await sheet.close();
  return files;
};

export const audit = async () => {
  const pw = playwright();
  if (!pw) return { error: 'Playwright is not installed in this repo: `npm i -D playwright` and `npx playwright install chromium`.' };
  mkdirSync(out, { recursive: true });
  // The old headless shell draws WebGL black —a globe or a shader vanishes from the video—; the new
  // headless mode (`channel: 'chromium'`) renders with the real GPU. Falls back if it is not there.
  const browser = await pw.chromium.launch({ channel: 'chromium' }).catch(() => pw.chromium.launch());
  const context = await browser.newContext({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
  const page = await context.newPage();
  await page.goto(url, { waitUntil: 'load', timeout: 45000 });
  await page.waitForTimeout(1500);
  if (cpu > 1) {
    const cdp = await context.newCDPSession(page);
    await cdp.send('Emulation.setCPUThrottlingRate', { rate: cpu });
  }
  // Entrances first, on the untouched page: auditing the elements scrolls through it.
  const sections = await entrances(page);
  await page.reload({ waitUntil: 'load' });
  await page.waitForTimeout(800);
  const handles = only.length ? (await Promise.all(only.map((s) => page.$$(s)))).flat() : await page.$$(INTERACTIVE);
  const visible = [];
  for (const h of handles) {
    if (visible.length >= max) break;
    const shown = await h.evaluate((n) => {
      if (n.disabled || n.getAttribute('aria-disabled') === 'true') return false;
      const target = n.matches('input') && getComputedStyle(n).opacity === '0' ? n.closest('label') ?? n : n;
      for (let e = target; e; e = e.parentElement) {
        const c = getComputedStyle(e);
        if (c.opacity === '0' || c.visibility === 'hidden' || c.display === 'none') return false;
      }
      const r = target.getBoundingClientRect();
      return r.width > 1 && r.height > 1;
    }).catch(() => false);
    if (shown) visible.push(h);
  }
  const elements = [];
  for (const [i, h] of visible.entries()) {
    await h.scrollIntoViewIfNeeded().catch(() => {});
    const label = await describe(h, i);
    const el = await auditElement(page, h, label).catch(() => null);
    if (el) elements.push(el);
  }
  const long = await longFrames(page);

  // Reduced motion: the same elements, looking for displacement or scale on hover and press.
  const reducedContext = await browser.newContext({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
  const rpage = await reducedContext.newPage();
  await rpage.goto(url, { waitUntil: 'load', timeout: 45000 });
  await rpage.waitForTimeout(800);
  const rhandles = only.length ? (await Promise.all(only.map((s) => rpage.$$(s)))).flat() : await rpage.$$(INTERACTIVE);
  let ri = 0;
  for (const h of rhandles) {
    if (ri >= elements.length) break;
    if (!(await h.isVisible().catch(() => false))) continue;
    await h.scrollIntoViewIfNeeded().catch(() => {});
    const box = await h.boundingBox();
    if (!box) { ri++; continue; }
    const rest = await snapshotIn(h, ['transform', 'translate', 'scale']);
    await rpage.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await rpage.mouse.down();
    await rpage.waitForTimeout(250);
    const now = await snapshotIn(h, ['transform', 'translate', 'scale']);
    await rpage.mouse.move(1, 1);
    await rpage.mouse.up();
    const moved = diff(rest, now);
    elements[ri].reduced = { moves: moved.length ? moved.map((k) => `${k}: ${now[k]}`).join(', ') : '' };
    ri++;
  }
  const infinite = await rpage.evaluate(() => document.getAnimations().filter((a) => {
    const t = a.effect?.target;
    if (a.effect?.getTiming?.().iterations !== Infinity || !t) return false;
    for (let e = t; e; e = e.parentElement) { const c = getComputedStyle(e); if (c.opacity === '0' || c.display === 'none' || c.visibility === 'hidden') return false; }
    return true;
  }).length);
  await reducedContext.close();

  const sheets = [];
  for (const s of frames) sheets.push(await contactSheet(page, browser, s));
  await browser.close();

  const problems = measure ? [] : [
    ...elements.flatMap(judge),
    ...sections.filter((s) => !s.animated).map((s) => `section “${s.section}”: appears without an entrance the first time it is scrolled to`),
    ...(long?.length ? [`${long.length} animation frames over 50 ms while scrolling${cpu > 1 ? ` with the CPU ${cpu}× slower` : ''}: ${long.slice(0, 6).join(', ')} ms`] : []),
    ...(infinite ? [`${infinite} infinite animations remain with prefers-reduced-motion`] : []),
  ];
  return { url, cpu, elements, sections, longFrames: long, infiniteReduced: infinite, sheets: sheets.flat().filter(Boolean), problems };
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  if (!url || args.includes('--help')) {
    console.log('motion-audit.mjs <url> [--only <selector>]… [--cpu 4] [--frames <selector>]… [--out <dir>] [--measure] [--max 40]');
    process.exit(url ? 0 : 2);
  }
  const r = await audit();
  if (r.error) { console.error(r.error); process.exit(2); }
  writeFileSync(join(out, 'report.json'), JSON.stringify(r, null, 1));
  const resp = (m) => r.elements.filter((e) => e.moments[m]?.changed.length || e.moments[m]?.pixels).length;
  // How rich the response is, not only whether it exists: movement or depth, not only color.
  const moves = (m) => r.elements.filter((e) => (e.moments[m]?.changed ?? []).some((p) => /transform|scale|translate|box-shadow|filter/.test(p))).length;
  const actionable = r.elements.filter((e) => e.kind !== 'focus-only').length;
  console.log(`${r.elements.length} elements · respond on hover ${resp('hover')} · press ${resp('press')} · focus ${resp('focus')} · sections with entrance ${r.sections.filter((s) => s.animated).length}/${r.sections.length} · long frames ${r.longFrames?.length ?? 'n/a'}${r.cpu > 1 ? ` (CPU ${r.cpu}×)` : ''}`);
  console.log(`richness · of ${actionable} actionable elements: press with movement ${moves('press')}, hover with depth or movement ${moves('hover')} — the audit checks that what exists responds well; how alive the screen is, is judged against the references in step 9`);
  if (r.sheets.length) console.log(`contact sheets: ${r.sheets.join(', ')}`);
  console.log(`report: ${join(out, 'report.json')}`);
  if (measure) process.exit(0);
  if (!r.problems.length) { console.log('Every element responds, with transitions in range, and nothing remains with reduced motion.'); process.exit(0); }
  console.log(`\n${r.problems.length} to fix:`);
  for (const p of r.problems) console.log(`- ${p}`);
  process.exit(1);
}
