import { granted, is2xx } from '../http.mjs';
import { switchToJsonOn415, wire } from '../body.mjs';

const snippet = (text) => text.replace(/\s+/g, ' ').slice(0, 120);

// Where a created item can be read back: the Location, else --item-path with the id from the JSON body.
export function itemUrlOf(res, { base, itemPath }) {
  if (res.headers.location) {
    try { const u = new URL(res.headers.location, base); return u.pathname + u.search; } catch { /* not a URL: fall through */ }
  }
  if (!itemPath) return null;
  try {
    const j = JSON.parse(res.text);
    const id = j?.id ?? j?.data?.id ?? j?.item?.id;
    return id === undefined ? null : itemPath.replace('{id}', encodeURIComponent(id));
  } catch { return null; }
}

// A stable label for an item URL: the id segment becomes {id}.
// The last path segment is the id, with or without a trailing slash: /items/37, /items/37/, /api/v1/items/37.
const withIdSegment = (url) => url.split('?')[0].replace(/[^/]+(\/?)$/, '{id}$1');
const lastSegment = (url) => url.split('?')[0].split('/').filter(Boolean).pop();
export const itemLabel = (url, template) => (template && url.startsWith(template.split('{id}')[0]) ? template : withIdSegment(url));

// The id-less template of an item route, learned from a created item's Location when --item-path was not given.
export const inferTemplate = (url, res) => {
  const last = lastSegment(url);
  let id;
  try { id = JSON.parse(res.text)?.id; } catch { /* no JSON body */ }
  return last && (id === undefined || decodeURIComponent(last) === String(id)) ? withIdSegment(url) : null;
};

// The legitimate create every other probe of this write depends on. { ok, res, item }.
export async function legitWrite(run, w) {
  const target = `${w.method} ${w.path}`;
  const spec = { group: 'auth', probe: 'legit-write', target, name: `${target} legitimate request` };
  const st = run.settings(w.method, w.path);
  const p = wire(w, st);
  if (p.error) { run.notRun(spec, p.error); return { ok: false }; }
  let res = await run.client.send(w.method, w.path, { body: p.text, type: p.type });
  let switched = false;
  if (switchToJsonOn415(w, res.s, st)) {
    switched = true;
    const json = wire(w, st);
    res = await run.client.send(w.method, w.path, { body: json.text, type: json.type });
  }
  if (await run.transportFault(res, spec, '2xx')) return { ok: false };
  if (!granted(res)) {
    run.notRun(spec, res.s >= 300
      ? `the legitimate request was redirected to login (${res.headers.location}): the credentials do not work, so every other row of this write is unreliable`
      : `the legitimate request answered ${res.s} (${snippet(res.text)}): every other row of this write is unreliable until it succeeds`);
    return { ok: false, res };
  }
  run.pass(spec, res.s, '2xx', switched ? 'the form answered 415: the write is sent as application/json from here on' : undefined);
  return { ok: true, res, item: itemUrlOf(res, { base: run.client.base, itemPath: run.itemPath }) };
}

// A group of probes that all depend on a legitimate write that failed.
export function notRunDependents(run, w, why) {
  const target = `${w.method} ${w.path}`;
  const { csrf, originCheck, noAmbient } = run.opts;
  const groups = [['input', 'input-probes'], ['resources', 'resource-probes'], ['auth', 'access-probes'], ['csrf', 'csrf-probes'], ['host', 'host-probes'], ['origin', 'origin-probes']];
  for (const [group, probe] of groups) {
    if (group === 'csrf' && !csrf) continue;
    if (group === 'origin' && (originCheck !== 'always' || noAmbient)) continue;
    if (group === 'host' && !run.opts.hostCheck && !run.opts.strictHost) continue;
    run.notRun({ group, probe, target, name: `${target} ${probe}` }, `the legitimate request failed: ${why}`);
  }
}

const unauthenticated = async (run, spec, method, path, expected, payload = {}) => {
  const res = await run.client.send(method, path, { auth: 'none', ...payload });
  if (await run.transportFault(res, spec, expected)) return;
  if (granted(res)) run.fail('unauthenticated-access', spec, res.s, expected, res.s >= 300 ? `redirected to ${res.headers.location ?? '(no Location)'}, not to a login page` : undefined);
  else run.pass(spec, res.s, expected);
};

// Authentication and object ownership on the item a legitimate write created.
export async function accessProbes(run, w, legit) {
  const { client, opts } = run;
  const target = `${w.method} ${w.path}`;
  const spec = (probe, name, t = target) => ({ group: 'auth', probe, target: t, name });
  const st = run.settings(w.method, w.path);
  const label = legit.item ? itemLabel(legit.item, run.itemTemplate) : null;

  if (client.hasCredentials()) {
    if (st.public) run.skipped(spec('write-without-credentials', `${target} without credentials`), 'the route is configured public');
    else {
      const p = wire(w, st);
      await unauthenticated(run, spec('write-without-credentials', `${target} without credentials`), w.method, w.path, '401 (or a redirect to login)', { body: p.text, type: p.type });
    }
    if (legit.item) {
      const itemSpec = spec('item-without-credentials', `GET ${label} without credentials`, `GET ${label}`);
      if (run.settings('GET', legit.item).public) run.skipped(itemSpec, 'the item route is configured public');
      else await unauthenticated(run, itemSpec, 'GET', legit.item, '401 (or a redirect to login)');
    }
  } else if (!run.state.noCredentialsReported) {
    run.state.noCredentialsReported = true;
    run.notRun(spec('no-credentials', 'authentication probes', '*'),
      'no credentials were given (--header, --auth-env, --auth-header-name): the rows without credentials prove nothing. Suppress this row if the API is open by design');
  }

  const idor = spec('idor', `${target} ownership`);
  if (!Object.keys(opts.otherHeaders).length) { run.notRun(idor, 'no credentials for user B (--other-header or --other-auth-env): the ownership probes were skipped'); return; }
  if (!legit.item) { run.notRun(idor, `the create answered no Location${opts.itemPath || run.itemPath ? ' and its body has no id for --item-path' : ' and --item-path was not given'}`); return; }
  const own = await client.send('GET', legit.item);
  if (!is2xx(own.s)) { run.notRun(idor, `user A cannot read the item it created (${own.s ?? own.err}): the ownership probes would prove nothing`); return; }
  const p = wire(w, st);
  const bCreate = await client.send(w.method, w.path, { body: p.text, type: p.type, auth: 'b' });
  const bItem = bCreate.s !== null && granted(bCreate) ? itemUrlOf(bCreate, { base: client.base, itemPath: run.itemPath }) : null;
  const bOwn = bItem ? await client.send('GET', bItem, { auth: 'b' }) : null;
  if (!bOwn || !is2xx(bOwn.s)) {
    run.notRun(idor, `user B's credentials cannot create and read their own item (create ${bCreate.s ?? bCreate.err}${bOwn ? `, read ${bOwn.s}` : ''}): a 401/403 below would be a bad token, not ownership`);
    return;
  }
  for (const m of ['GET', 'DELETE']) {
    const s = spec(`idor-${m.toLowerCase()}`, `${m} ${label} as another user (IDOR / BOLA)`, `${m} ${label}`);
    const r = await client.send(m, legit.item, { auth: 'b' });
    const expected = '404 (or 403)';
    if (await run.transportFault(r, s, expected)) continue;
    if (!granted(r)) { run.pass(s, r.s, expected); continue; }
    if (m === 'DELETE') {
      // A 2xx proves nothing unless the object is gone: some routes answer 2xx to any method and delete nothing.
      const after = await client.send('GET', legit.item);
      if (is2xx(after.s)) { run.pass(s, r.s, expected, `answered ${r.s} but the item still exists: nothing was deleted`); continue; }
    }
    run.fail('idor', s, r.s, expected, "another user's credentials reach this object");
  }
}

export async function readsWithoutCredentials(run) {
  const { client, opts } = run;
  if (!client.hasCredentials()) return;
  for (const r of opts.reads) {
    const spec = { group: 'auth', probe: 'read-without-credentials', target: `GET ${r.split('?')[0]}`, name: `GET ${r} without credentials` };
    if (run.settings('GET', r).public) run.skipped(spec, 'the route is configured public');
    else await unauthenticated(run, spec, 'GET', r, '401 (or a redirect to login)');
  }
}

// Cookie-authenticated apps: a write from another origin must be refused (CSRF). "Same site" includes another port.
export async function csrfProbes(run, w) {
  const { client } = run;
  const st = run.settings(w.method, w.path);
  if (!Object.hasOwn(run.opts.headers, 'cookie')) {
    run.notRun({ group: 'csrf', probe: 'cookie-required', target: `${w.method} ${w.path}`, name: `${w.method} ${w.path} CSRF probes` },
      '--csrf tests cookie authentication and no Cookie header was given: a browser does not attach a Bearer token to a cross-site request. Pass the session cookie with --header "Cookie: ..."');
    return;
  }
  const origins = [
    ['another-site', 'from another site', { origin: 'https://attacker.example', 'sec-fetch-site': 'cross-site' }],
    ['another-port', 'from another port of the same host', { origin: `http://${client.base.hostname}:${client.port + 1}`, 'sec-fetch-site': 'same-site' }],
    ['null-origin', 'with Origin: null', { origin: 'null' }],
  ];
  for (const [tag, label, headers] of origins) {
    const target = `${w.method} ${w.path}`;
    const s = { group: 'csrf', probe: `origin-${tag}`, target, name: `${target} ${label}` };
    const p = wire(w, st);
    const attempt = () => client.send(w.method, w.path, { body: p.text, type: p.type, headers, auth: 'cookie' });
    // A server that refuses early may reset the connection while the body is still being sent: one repeat before a drop is judged.
    let r = await attempt();
    if (r.s === null || r.truncated) r = await attempt();
    const expected = '403 (any 4xx): the Origin is not this app';
    if (await run.transportFault(r, s, expected)) continue;
    if (granted(r)) run.fail('csrf', s, r.s, expected, r.s >= 300 ? `redirected to ${r.headers.location ?? '(no Location)'}: the write was accepted` : undefined);
    else if (r.s === 409) run.notRun(s, 'answered 409: the body was refused before the origin check, so the check was not reached');
    else run.pass(s, r.s, expected);
  }
}
