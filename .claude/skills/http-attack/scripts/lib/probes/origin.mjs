import { granted, is2xx } from '../http.mjs';
import { wire } from '../body.mjs';

const ATTACKER_ORIGIN = 'https://attacker.example';
const FOREIGN_HOST = 'attacker.example';
// A 409 or a 422 (and a 400 on an origin row) is the app validating the body, not refusing the request: not a verdict.
const validating = (s, origin) => s === 409 || s === 422 || (origin && s === 400);

const ORIGIN_CASES = (client) => [
  ['another-site', 'from another site', { origin: ATTACKER_ORIGIN, 'sec-fetch-site': 'cross-site' }],
  ['another-port', 'from another port of the same host', { origin: `http://${client.base.hostname}:${client.port + 1}`, 'sec-fetch-site': 'same-site' }],
  ['no-sec-fetch', 'with a foreign Origin and no Sec-Fetch', { origin: ATTACKER_ORIGIN }],
  ['null', 'with Origin null', { origin: 'null' }],
];
// A read is attacked from another site and another port only.
const READ_CASES = 2;

const payloadOf = (run, w) => {
  if (!w) return {};
  const p = wire(w, run.settings(w.method, w.path));
  return { body: p.text, type: p.type };
};

// `--origin-check always`: every write and read, with the given credentials, from a foreign Origin, must be refused.
export async function foreignOriginProbes(run, method, path, w) {
  const { client } = run;
  const target = `${method} ${path.split('?')[0]}`;
  const cases = ORIGIN_CASES(client).slice(0, w ? undefined : READ_CASES);
  for (const [tag, label, headers] of cases) {
    const spec = { group: 'origin', probe: `foreign-origin-${tag}`, target, name: `${method} ${path} ${label}` };
    const expected = '4xx: the Origin is not this app';
    const attempt = () => client.send(method, path, { ...payloadOf(run, w), headers });
    // A server that refuses early may reset the connection while the body is still being sent: one repeat first.
    let r = await attempt();
    if (r.s === null || r.truncated) r = await attempt();
    if (await run.transportFault(r, spec, expected)) continue;
    if (validating(r.s, true)) run.notRun(spec, `answered ${r.s}: the body was refused before the origin was looked at`);
    else if (granted(r)) run.fail('foreign-origin-accepted', spec, r.s, expected, r.s >= 300 ? `redirected to ${r.headers.location ?? '(no Location)'}` : `answered ${r.s}`);
    else run.pass(spec, r.s, expected);
  }
}

// A request whose Host is not the app's, sent as a same-origin browser would. Accepted, it is a finding with --strict-host and
// an info row without it: an app need not refuse a Host, and a 421 added only for this row breaks legitimate clients.
export async function foreignHostProbe(run, method, path, w) {
  const { client } = run;
  const target = `${method} ${path.split('?')[0]}`;
  const spec = { group: 'host', probe: 'foreign-host', target, name: `${method} ${path} with a foreign Host` };
  const expected = '4xx (421): the Host is not this app';
  const headers = { host: FOREIGN_HOST, origin: client.base.origin, 'sec-fetch-site': 'same-origin', 'sec-fetch-mode': 'navigate', 'sec-fetch-dest': 'document' };
  const r = await client.send(method, path, { ...payloadOf(run, w), headers });
  if (await run.transportFault(r, spec, expected)) return;
  if (validating(r.s, false)) { run.notRun(spec, `answered ${r.s}: the body was refused before the Host was looked at`); return; }
  if (!granted(r)) { run.pass(spec, r.s, expected); return; }
  const evidence = `answered ${r.s} to Host: ${FOREIGN_HOST}`;
  if (run.opts.strictHost) run.fail('foreign-host-accepted', spec, r.s, expected, evidence);
  else run.info(spec, r.s, expected, `${evidence}; a finding only with --strict-host`);
}

// The legitimate GET a read's origin and host rows depend on. False (and those rows NOT RUN) unless it answers 2xx.
export async function legitRead(run, path) {
  const target = `GET ${path.split('?')[0]}`;
  const spec = { group: 'origin', probe: 'legit-read', target, name: `${target} legitimate request` };
  const res = await run.client.send('GET', path);
  if (await run.transportFault(res, spec, '2xx')) return false;
  if (is2xx(res.s)) { run.pass(spec, res.s, '2xx'); return true; }
  run.notRun(spec, `the legitimate read answered ${res.s}: its origin and host rows would prove nothing`);
  return false;
}

// The HTTP authentication schemes a browser answers on its own; Bearer is never sent without the page's code.
const AMBIENT_AUTH = /(^|,\s*)(basic|digest|negotiate|ntlm)\b/i;

// `--no-ambient`: nothing a browser sends on its own reaches the API, so no legitimate response may set a cookie or ask
// for HTTP authentication. `responses` are { method, path, res } of the legitimate requests.
export function ambientProbe(run, responses) {
  const spec = (target, name) => ({ group: 'origin', probe: 'no-ambient', target, name });
  if (!responses.length) {
    run.notRun(spec('responses', 'no ambient credentials'), 'no legitimate request succeeded: there is no response to look at');
    return;
  }
  let found = false;
  for (const { method, path, res } of responses) {
    const set = ['set-cookie', 'www-authenticate'].filter((h) => res.headers?.[h] !== undefined && (h !== 'www-authenticate' || AMBIENT_AUTH.test(res.headers[h])));
    if (!set.length) continue;
    found = true;
    const target = `${method} ${path.split('?')[0]}`;
    run.fail('ambient-credentials', spec(target, `${target} sets no ambient credential`), res.s, 'no Set-Cookie and no WWW-Authenticate', `the response carries ${set.join(' and ')}`);
  }
  if (!found) run.pass(spec('responses', 'no legitimate response sets Set-Cookie or asks WWW-Authenticate'), 'all', 'no Set-Cookie and no WWW-Authenticate');
}
