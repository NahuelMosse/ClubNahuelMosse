#!/usr/bin/env node
// attack.mjs <base-url> [--json] [--no-ambient] [--write "<METHOD> <path> [body]"]... [--read "<path>"]...
//
// The same attacks against any app, on every card. Measured: runs tried “request from another site”
// and called the matter closed, but a request from another port of the same host —same site,
// another origin— got through. An attack tried halfway goes unnoticed until someone tries it
// whole; this tries it whole every time.
//
// --write: a path that changes state, with its body as a form (a=1&b=2) or, if it starts with { or [, as JSON.
// --json:   send the bodies as application/json, the form fields becoming JSON fields. Without it, a write
//           whose legitimate form request gets a 415 is attacked as JSON: an API that wants JSON answers 415
//           to every form attack before looking at anything else, and nothing would have been tried.
// --read:  a path that returns personal data.
// --no-ambient: the API is reached with no credentials a browser sends on its own (cookie, HTTP auth, client
//           certificate), so there is nothing to forge from another site (criteria S1, a decision line). The origin
//           rows are replaced by one check: no legitimate response sets `Set-Cookie` or asks `WWW-Authenticate`.
//           Host, body, malformed JSON and method rows stay.
// Every attack sends its own body (`-a<n>` added to each text field; an email gets it before the `@`), so a uniqueness
// rule never answers for the defense. A 409 or a 422 on any attack row, and a 400 on an origin row, is the app
// validating, not defending: it is `COULD NOT RUN`, never `blocked`.
// Attacks tried, each of them against every path given (`node .claude/tools/help.mjs attack` prints this list):
//   --write, besides the legitimate request from the page itself:
//     - from another site
//     - from another port of the same host
//     - with a foreign Origin and no Sec-Fetch
//     - with Origin null
//     - with a foreign Host
//     - with a 1 MB body
//     - with a malformed JSON body (only a JSON write)
//     - a method that does not apply (PUT, DELETE and PATCH, the ones that are not the write's own)
//   --read, besides the legitimate request:
//     - from another site
//     - from another port of the same host
//     - with a foreign Host
// A write with no Origin header is not an attack: it is served (criteria S1), since a browser always sends
// Origin on a cross-site write. It is printed as an `info` line and counts as neither blocked nor passed.
// Exits 0 if everything was blocked and the legitimate request worked, 1 if any attack got
// through, 2 if something could not run because the app did not respond.
import { request } from 'node:http';
import { endsWithLine } from './final-line.mjs';

endsWithLine('attack');
const args = process.argv.slice(2);
const base = args[0];
if (!base || !/^https?:\/\//.test(base)) {
  console.error('usage: node attack.mjs <base-url> [--write "POST /path a=1"]... [--read "/path"]...');
  process.exit(2);
}
// Git Bash turns “/path” into a Windows path; it is also accepted without the leading slash.
const toPath = (r) => '/' + r.replace(/^[A-Za-z]:[\\/].*?[\\/]Git[\\/]/, '').replace(/^\/+/, '');
const writes = [], reads = [];
let jsonFlag = false, noAmbient = false;
for (let i = 1; i < args.length; i++) {
  if (args[i] === '--json') jsonFlag = true;
  else if (args[i] === '--no-ambient') noAmbient = true;
  else if (args[i] === '--write') {
    const [method, r, ...body] = args[++i].split(' ');
    writes.push({ method, path: toPath(r), body: body.join(' ') });
  } else if (args[i] === '--read') reads.push(toPath(args[++i]));
}

const url = new URL(base);
const otherPort = `${url.protocol}//${url.hostname}:${Number(url.port || 80) + 1}`;
const BROWSER = { 'sec-fetch-site': 'same-origin', 'sec-fetch-mode': 'navigate', 'sec-fetch-dest': 'document', origin: url.origin };
const ORIGINS = [
  ['from another site', { 'sec-fetch-site': 'cross-site', origin: 'https://attacker.example' }],
  ['from another port of the same host', { 'sec-fetch-site': 'same-site', origin: otherPort }],
  ['with a foreign Origin and no Sec-Fetch', { origin: 'https://attacker.example' }],
  ['with Origin null', { origin: 'null' }],
];

// node:http and not fetch: fetch does not let you change Host, and the foreign-host attack would come
// out as “passed” without having been tried.
const exchange = (method, r, headers, body, type = 'application/x-www-form-urlencoded') => new Promise((done) => {
  const target = new URL(r, base);
  const data = body === undefined ? null : Buffer.from(body);
  const req = request({
    hostname: target.hostname, port: target.port, path: target.pathname + target.search, method,
    headers: { ...headers, ...(data ? { 'content-type': type, 'content-length': data.length } : {}) },
  }, (res) => { res.resume(); res.on('end', () => done({ s: res.statusCode, headers: res.headers })); });
  req.setTimeout(10_000, () => req.destroy(new Error('timeout')));
  req.on('error', (e) => done({ s: `no response (${e.code ?? e.message})`, headers: {} }));
  if (data) req.write(data);
  req.end();
});
const send = async (...a) => (await exchange(...a)).s;
const rejected = (s) => s >= 400 && s < 500;
// The app validating or refusing the body is not the defense under test.
const validation = (s, origin) => s === 409 || s === 422 || (origin && s === 400);

const alive = await send('GET', '/', BROWSER);
if (typeof alive !== 'number') { console.error(`The app does not respond at ${base}: ${alive}`); process.exit(2); }

const rows = [], notes = [], infos = [];
// The body of a write in the wire format: the form as it was given, or the same fields as a JSON object.
const FORM = 'application/x-www-form-urlencoded';
// Attack number n (0 is the legitimate request) varies every text field: `-a<n>` at its end, before the `@` of an email.
const vary = (v, n) => {
  if (typeof v === 'string') return v.includes('@') ? v.replace('@', `-a${n}@`) : `${v}-a${n}`;
  if (Array.isArray(v)) return v.map((x) => vary(x, n));
  return v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, vary(x, n)])) : v;
};
const wire = (body, json, n = 0) => {
  const given = /^s*[{[]/.test(body);
  if (!json) return { text: n ? new URLSearchParams([...new URLSearchParams(body)].map(([k, v]) => [k, vary(v, n)])).toString() : body, type: FORM };
  let fields = given ? null : Object.fromEntries(new URLSearchParams(body));
  if (given) try { fields = JSON.parse(body); } catch { return { text: body, type: 'application/json' }; }
  return { text: JSON.stringify(n ? vary(fields, n) : fields), type: 'application/json' };
};
const big = (json) => (json ? { text: JSON.stringify({ x: 'a'.repeat(1 << 20) }), type: 'application/json' } : { text: 'x=' + 'a'.repeat(1 << 20), type: FORM });
const attack = async (name, method, r, headers, body, origin = false) => {
  const s = await send(method, r, headers, body?.text, body?.type);
  const invalid = typeof s === 'number' && validation(s, origin);
  rows.push({ name, s, invalid, bad: typeof s === 'number' && !invalid && !rejected(s) });
};
// What the legitimate responses set that a browser would send back on its own.
const ambient = [];
const legitimate = async (name, method, r, body) => {
  const { s, headers } = await exchange(method, r, BROWSER, body?.text, body?.type);
  for (const h of ['set-cookie', 'www-authenticate']) if (headers[h] !== undefined) ambient.push(`${h} on ${method} ${r}`);
  rows.push({ name, s, bad: typeof s === 'number' && s >= 400, control: true });
  return s;
};
let count = 0;

for (const { method, path: r, body } of writes) {
  const legit = `${method} ${r} legitimate, from the page itself`;
  let json = jsonFlag || /^s*[{[]/.test(body);
  const first = await legitimate(legit, method, r, wire(body, json));
  if (!json && first === 415) {
    json = true;
    rows.pop();
    await legitimate(legit, method, r, wire(body, json));
    notes.push(`${method} ${r} answered 415 to a form: attacked as application/json.`);
  }
  if (!noAmbient) {
    for (const [name, headers] of ORIGINS) await attack(`${method} ${r} ${name}`, method, r, headers, wire(body, json, ++count), true);
    const p = wire(body, json, ++count);
    infos.push({ name: `${method} ${r}`, s: await send(method, r, {}, p.text, p.type) });
  }
  await attack(`${method} ${r} with a foreign Host`, method, r, { ...BROWSER, host: 'attacker.example' }, wire(body, json, ++count));
  await attack(`${method} ${r} with a 1 MB body`, method, r, BROWSER, big(json));
  if (json) await attack(`${method} ${r} with a malformed JSON body`, method, r, BROWSER, { text: '{"x":', type: 'application/json' });
  for (const other of ['PUT', 'DELETE', 'PATCH'].filter((m) => m !== method))
    await attack(`${other} ${r} (method that does not apply)`, other, r, BROWSER, wire(body, json, ++count));
}
for (const r of reads) {
  await legitimate(`GET ${r} legitimate, from the page itself`, 'GET', r);
  if (!noAmbient) for (const [name, headers] of ORIGINS.slice(0, 2)) await attack(`GET ${r} ${name}`, 'GET', r, headers, undefined, true);
  await attack(`GET ${r} with a foreign Host`, 'GET', r, { ...BROWSER, host: 'attacker.example' });
}
if (noAmbient) rows.push({ name: `no ambient credentials: no legitimate response sets Set-Cookie or asks WWW-Authenticate${ambient.length ? ` (${ambient.join(', ')})` : ''}`, s: '-', bad: ambient.length > 0, control: true });

for (const n of notes) console.log(`note: ${n}`);
// No response is neither “passed” nor “blocked”: it could not run, and it counts as neither. Nor is an answer that
// validates the body (409, 422, a 400 on an origin row) instead of defending.
let bad = 0, notRun = 0;
for (const f of rows) {
  const responded = f.s === '-' || typeof f.s === 'number';
  const mark = !responded || f.invalid ? 'COULD NOT RUN' : f.control ? (f.bad ? 'FAILS        ' : 'ok           ') : (f.bad ? 'PASSED       ' : 'blocked      ');
  if (!responded || f.invalid) notRun++; else if (f.bad) bad++;
  console.log(`${mark}  ${String(f.s).padEnd(4)}  ${f.name}`);
}
for (const i of infos) console.log(`info · no Origin header · ${i.s} · ${i.name} · served by S1: a browser always sends Origin on a cross-site write`);
if (bad) console.log(`\n${bad} problem(s): an attack got through or the legitimate request did not work.`);
if (notRun) console.log(`${bad ? '' : '\n'}${notRun} could not run: the app did not respond, or answered the body (409, 422, 400) and not the defense.`);
if (!bad && !notRun) console.log('\nNo attack got through and the legitimate request worked.');
process.exit(bad ? 1 : notRun ? 2 : 0);
