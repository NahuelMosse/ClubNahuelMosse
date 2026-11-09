import { is2xx } from '../http.mjs';

const HUGE = ['9'.repeat(30), '-' + '9'.repeat(30), '1e3', ''];
// Broken percent-encoding in the path is probed separately (`/%`), so it is not repeated here.
const PATH_PARAMS = [['huge-number', '9'.repeat(30)], ['negative', '-1'], ['letters', 'abc'], ['invalid-uuid', 'not-a-uuid']];

// Marker, regexp pairs: a hit on a 2xx that is not an HTML page means the file came back.
const LEAKS = [
  ['/.git/config', /\[core\]/], ['/.env', /^[A-Z][A-Z0-9_]*=/m], ['/package.json', /"(dependencies|scripts)"\s*:/],
  ['/../../etc/passwd', /root:.*:0:0:/], ['/%2e%2e/%2e%2e/etc/passwd', /root:.*:0:0:/],
  ['/..%5c..%5cwindows/win.ini', /\[fonts\]|for 16-bit app support/i],
];

// Digits and long hex/uuid runs vary between two responses of the same route; compare without them.
const shape = (text) => text.replace(/[0-9a-f-]{8,}|\d+/gi, '#');

export async function pathProbes(run, { writes, itemTemplate }) {
  const { client, opts } = run;
  const routes = [...new Set(['/', ...writes.map((w) => w.path), ...opts.reads])];
  const spec = (probe, target, name) => ({ group: 'paths', probe, target, name });
  const noFiveHundred = async (probe, target, name, path, expected) => {
    const s = spec(probe, target, name);
    const res = await client.send('GET', path);
    if (!(await run.transportFault(res, s, expected))) run.pass(s, res.s, expected);
  };

  const seenPaths = new Set(); // path-level probes run once per path; the query only matters for the query-level ones
  for (const r of routes) {
    const [p, q] = r.split('?');
    if (!seenPaths.has(p)) {
      seenPaths.add(p);
      const pathTarget = `GET ${p}`;
      const s = spec('double-slash', pathTarget, `GET /${p} (double slash)`);
      const [slash, plain] = [await client.send('GET', '/' + p), await client.send('GET', p)];
      if (!(await run.transportFault(slash, s, 'a 4xx or the same resource, never a 5xx: "//x" is a path, not a host'))) {
        if (is2xx(slash.s) && (slash.s !== plain.s || shape(slash.text) !== shape(plain.text))) {
          run.fail('double-slash-mismatch', s, slash.s, `the same answer as ${p} (${plain.s}) or a 4xx`, `//${p.slice(1)} answered something else than ${p}: it is likely parsed as a host`);
        } else run.pass(s, slash.s, 'a 4xx or the same resource');
      }
      const base = p.replace(/\/$/, '');
      await noFiveHundred('percent-path', pathTarget, `GET ${base}/% (broken percent-encoding in the path)`, `${base}/%`, '400 or 404, never a 5xx');
    }
    const target = `GET ${r}`;
    await noFiveHundred('percent-query', target, `GET ${p}?pct=%FF% (broken percent-encoding in the query)`, `${p}?${q ? `${q}&` : ''}pct=%FF%`, '400, never a 5xx');
    for (const [k] of [...new URLSearchParams(q ?? '')].filter(([, v]) => /^-?\d+$/.test(v))) {
      for (const huge of HUGE) {
        const sp = new URLSearchParams(q); sp.set(k, huge);
        await noFiveHundred(`number-${k}-${huge.slice(0, 6) || 'empty'}`, target, `GET ${p}?${k}=${huge.slice(0, 6) || '(empty)'} (number the parser cannot hold)`, `${p}?${sp}`, '400 or a clamped 2xx, never a 5xx');
      }
    }
  }

  if (itemTemplate) {
    for (const [tag, value] of PATH_PARAMS) {
      await noFiveHundred(`path-param-${tag}`, `GET ${itemTemplate}`, `GET ${itemTemplate.replace('{id}', value)} (path parameter)`, itemTemplate.replace('{id}', value), '400 or 404, never a 5xx');
    }
  } else {
    run.notRun(spec('path-params', 'GET {item}', 'path parameter probes (huge number, letters, invalid UUID)'),
      'no item route is known: pass --item-path "/items/{id}" or have the create answer a Location');
  }

  const readable = [...new Set(opts.reads.map((x) => x.split('?')[0]))];
  const all = [...new Set([...writes.map((w) => w.path), ...readable])];
  for (const r of all) for (const m of ['HEAD', 'OPTIONS']) {
    // A write-only route may refuse HEAD (405 with Allow), but never with a 5xx.
    const s = spec(m.toLowerCase(), `${m} ${r}`, `${m} ${r}`);
    const res = await client.send(m, r);
    const expected = '2xx, or 405 with Allow';
    if (await run.transportFault(res, s, expected)) continue;
    // Both findings can apply to one answer: HEAD refused, and without an Allow header.
    if (res.s === 405 && m === 'HEAD' && readable.includes(r)) run.fail('head-unsupported', s, 405, 'HEAD answered like GET without the body (RFC 9110 9.1)');
    if (res.s === 405 && !res.headers.allow) run.fail('missing-allow', s, 405, '405 must name the allowed methods in Allow (RFC 9110 15.5.6)');
    if (res.s !== 405 || (res.headers.allow && (m === 'OPTIONS' || !readable.includes(r)))) run.pass(s, res.s, expected);
  }

  for (const [p, marker] of LEAKS) {
    const s = spec('file-served', `GET ${p}`, `GET ${p} (file the app must not serve)`);
    const res = await client.send('GET', p, { common: false });
    if (await run.transportFault(res, s, '404')) continue;
    if (is2xx(res.s) && !/^\s*<(!doctype|html)/i.test(res.text) && marker.test(res.text)) run.fail('file-served', s, res.s, '404', 'the file content came back');
    else run.pass(s, res.s, '404 (an SPA index page is fine)');
  }
  for (const p of run.opts.leakPaths ?? []) {
    const s = spec('file-served', `GET ${p}`, `GET ${p} (file the app must not serve)`);
    const res = await client.send('GET', p, { common: false });
    if (await run.transportFault(res, s, '404')) continue;
    if (is2xx(res.s) && res.text.trim() && !/^\s*<(!doctype|html)/i.test(res.text)) run.fail('file-served', s, res.s, '404', 'the file content came back');
    else run.pass(s, res.s, '404 (an SPA index page is fine)');
  }
}
