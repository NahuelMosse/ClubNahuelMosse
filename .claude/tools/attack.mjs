#!/usr/bin/env node
// attack.mjs [<base-url>] [--json] [--no-ambient] [--header "Name: value"]... [--auth-env <VAR>] [--write "<METHOD> <path> [body]"]... [--read "<path>"]...
//
// The same attacks against any app, on every card. Measured: runs tried “request from another site”
// and called the matter closed, but a request from another port of the same host —same site,
// another origin— got through. An attack tried halfway goes unnoticed until someone tries it
// whole; this tries it whole every time.
//
// <base-url>: without it, `APP_URL` of the environment (verify.mjs sets it when the `## Gate` has an `app:` line).
// --write: a path that changes state, with its body as a form (a=1&b=2) or, if it starts with { or [, as JSON.
// --json:   send the bodies as application/json, the form fields becoming JSON fields. Without it, a write
//           whose legitimate form request gets a 415 is attacked as JSON: an API that wants JSON answers 415
//           to every form attack before looking at anything else, and nothing would have been tried.
// --read:  a path that returns personal data.
// --no-ambient: the API is reached with no credentials a browser sends on its own (cookie, HTTP auth, client
//           certificate), so there is nothing to forge from another site (criteria S1, a decision line). The origin
//           rows are replaced by one check: no legitimate response sets `Set-Cookie` or asks `WWW-Authenticate`.
//           Host, body, malformed JSON and method rows stay.
// --body-limit <bytes>: the limit the card sets for a body, in bytes. With it, a body of multibyte characters just above the limit
//           (fewer characters than the limit, more bytes) must be rejected.
// --common-headers "Name1, Name2": every response of every row (the raw ones and the ones below included) carries those headers;
//           the row of a response that lacks one fails, naming the request and the header.
// --raw-headers-exempt "<why>": the raw rows are answered by the server before the app (uvicorn/h11, a proxy) and cannot carry
//           them; their rows do not check the common headers and say so with the reason. Every other row still does.
// --unique "<METHOD> <path> <body>": sends 8 identical requests at once; exactly one may succeed (2xx or a redirect) and the others
//           must be 4xx (409 or 422); a 5xx or a second success fails. The body is a form or, if it starts with { or [, JSON.
// --fault-db <sqlite file>: opens the file with `node:sqlite`, holds `BEGIN EXCLUSIVE` and sends the first `--write` as it
//           is; the answer must be a 5xx and the app must still answer a GET afterwards. `$DATA_DIR/...` takes the DATA_DIR of
//           the environment. Without `node:sqlite`, without a `--write` or with a missing file the row is `COULD NOT RUN`.
// --openapi <file.yaml|json>: the status of every response of every row, per method and path (ids normalized to the contract's
//           template), must be one the contract documents for that operation (`default` and `2XX` style keys count); each
//           status the app answered and the contract does not list fails. An operation or path the contract lacks is not judged.
//           YAML is read by a minimal indentation parser (`paths:` > path > method > `responses:` > status keys); a file that
//           cannot be read, or has no paths, is `COULD NOT RUN`.
// --header "Name: value": a header sent on every request of the run, the legitimate one and every attack (repeatable).
//           An API that answers 401 to everything without a token would otherwise be attacked in vain: every row would
//           come out “blocked” by the missing login and none by the defense under test.
// --auth-env <VAR>: sends `Authorization: Bearer $VAR`, read from the environment, so the token stays out of the logs and
//           of the shell history. An unset or empty VAR is an error (exit 2), never a run without the header.
//           The attacks keep their own headers (Origin, Sec-Fetch, Host) on top of these ones.
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
//   --write with a JSON body, the HTTP hardening of any API that takes JSON:
//     - with a body that never ends (chunked): the server cuts it in a bounded time (`ATTACK_HANG_MS`, 6000 by default)
//     - with a body that never ends (Content-Length): the same, with a large Content-Length that does not arrive
//     - with a body over the byte limit (multibyte): only with `--body-limit <bytes>`; it must be a 4xx
//     - with invalid UTF-8 in the body: a 4xx, never a 2xx or a 5xx
//   --write with a JSON body, one more:
//     - with a 50 MB text/plain body (streamed): a 4xx before it is all out, or in under 2 s; never read whole first
//   every path given (write or read) and `/`, last:
//     - (double slashes in the path): `GET //` and `GET //<path>` never answer 5xx nor drop the connection
//   always, raw over a socket to the host of the URL: `GARBAGE`, a request line with a non-ASCII path that is not encoded, and a
//   20 KB header. Each must be answered with a 4xx (or the connection closed cleanly), never a 5xx, and a legitimate GET must
//   still be answered afterwards.
//   --read, besides the legitimate request:
//     - from another site
//     - from another port of the same host
//     - with a foreign Host
// A write with no Origin header is not an attack: it is served (criteria S1), since a browser always sends
// --strict-host: a foreign Host that is accepted is a failure. Without it (and below the production grade) the row is `info`:
//           the card does not ask to refuse a Host, and a 421 added only for this row broke legitimate clients.
// Origin on a cross-site write. It is printed as an `info` line and counts as neither blocked nor passed.
// Exits 0 if everything was blocked and the legitimate request worked, 1 if any attack got
// through, 2 if something could not run because the app did not respond.
import { request } from 'node:http';
import { connect } from 'node:net';
import { existsSync, readFileSync } from 'node:fs';
import { endsWithLine } from './final-line.mjs';
import { gradeOf, readManifest } from './kit.mjs';

endsWithLine('attack');
const args = process.argv.slice(2);
const given = /^https?:\/\//.test(args[0] ?? '');
const base = given ? args[0] : process.env.APP_URL;
if (!base || !/^https?:\/\//.test(base)) {
  console.error('usage: node attack.mjs [<base-url>] [--header "Name: value"]... [--auth-env VAR] [--write "POST /path a=1"]... [--read "/path"]... [--common-headers "A, B"] [--raw-headers-exempt "<why>"]');
  process.exit(2);
}
// Git Bash turns “/path” into a Windows path; it is also accepted without the leading slash.
const toPath = (r) => '/' + r.replace(/^[A-Za-z]:[\\/].*?[\\/]Git[\\/]/, '').replace(/^\/+/, '');
const writes = [], reads = [];
let jsonFlag = false, noAmbient = false, bodyLimit = 0, strictHost = false, faultDb = null, openapi = null;
const commonHeaders = [], uniques = [];
let rawHeadersExempt = '';
const extra = {};
const addHeader = (line) => {
  const at = line.indexOf(':');
  const key = line.slice(0, at).trim().toLowerCase();
  if (at < 1 || !/^[a-z0-9!#$%&'*+.^_`|~-]+$/.test(key)) { console.error(`--header wants "Name: value", got a header without a valid name.`); process.exit(2); }
  extra[key] = line.slice(at + 1).trim();
};
for (let i = given ? 1 : 0; i < args.length; i++) {
  if (args[i] === '--json') jsonFlag = true;
  else if (args[i] === '--header') addHeader(args[++i] ?? '');
  else if (args[i] === '--auth-env') {
    const name = args[++i] ?? '';
    if (!process.env[name]) { console.error(`--auth-env ${name}: the variable is not set or is empty; the run would go without credentials.`); process.exit(2); }
    extra.authorization = `Bearer ${process.env[name]}`;
  }
  else if (args[i] === '--common-headers') {
    const names = (args[++i] ?? '').split(',').map((h) => h.trim().toLowerCase()).filter(Boolean);
    if (!names.length) { console.error('--common-headers wants "Name1, Name2".'); process.exit(2); }
    commonHeaders.push(...names);
  }
  else if (args[i] === '--raw-headers-exempt') {
    rawHeadersExempt = (args[++i] ?? '').trim();
    if (!rawHeadersExempt) { console.error('--raw-headers-exempt wants "<why the server answers raw requests before the app>".'); process.exit(2); }
  }
  else if (args[i] === '--unique') {
    const [method, r, ...body] = (args[++i] ?? '').split(' ');
    if (!method || !r) { console.error('--unique wants "<METHOD> <path> <body>".'); process.exit(2); }
    uniques.push({ method, path: toPath(r), body: body.join(' ') });
  }
  else if (args[i] === '--fault-db') {
    faultDb = (args[++i] ?? '').replace(/\$\{DATA_DIR\}|\$DATA_DIR(?![\w])|%DATA_DIR%/g, process.env.DATA_DIR ?? '$&');
    if (!faultDb) { console.error('--fault-db wants the path of the SQLite file.'); process.exit(2); }
  }
  else if (args[i] === '--openapi') openapi = args[++i] ?? '';
  else if (args[i] === '--no-ambient') noAmbient = true;
  else if (args[i] === '--strict-host') strictHost = true;
  else if (args[i] === '--body-limit') {
    bodyLimit = Number(args[++i]);
    if (!Number.isInteger(bodyLimit) || bodyLimit < 16) { console.error('--body-limit wants a whole number of bytes (16 or more).'); process.exit(2); }
  }
  else if (args[i] === '--write') {
    const [method, r, ...body] = args[++i].split(' ');
    writes.push({ method, path: toPath(r), body: body.join(' ') });
  } else if (args[i] === '--read') reads.push(toPath(args[++i]));
}

// A foreign Host that is accepted fails only when the card asks for it (`--strict-host`) or the grade is production:
// no card asks for a 421, and one added to satisfy this row broke legitimate clients.
try { if (gradeOf(readManifest(process.cwd())) === 'production') strictHost = true; } catch { strictHost = true; }

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
// The headers every response must carry (`--common-headers`): a response that lacks one is logged against the row that is
// pushed next (`at`), and the end of the run marks that row as failed.
const missingLog = [];
const noteMissing = (what, headers) => { for (const h of commonHeaders) if (headers[h] === undefined) missingLog.push({ at: rows.length, what, h }); };
// Every status the app answered, per method and path (`--openapi` compares them with the contract).
const seen = [];
const noteSeen = (method, r, s) => seen.push({ method: method.toUpperCase(), path: r.split('?')[0], s });
const exchange = (method, r, headers, body, type = 'application/x-www-form-urlencoded', check = true) => new Promise((done) => {
  // A path that starts with `//` is sent as it is: `new URL` would take it for another host.
  const target = new URL(r.startsWith('//') ? '/' : r, base);
  const data = body === undefined ? null : Buffer.from(body);
  const req = request({
    hostname: target.hostname, port: target.port, path: r.startsWith('//') ? r : target.pathname + target.search, method,
    headers: { ...extra, ...headers, ...(data ? { 'content-type': type, 'content-length': data.length } : {}) },
  }, (res) => {
    res.resume();
    res.on('end', () => { if (check) { noteMissing(`${method} ${r} answered ${res.statusCode}`, res.headers); noteSeen(method, r, res.statusCode); } done({ s: res.statusCode, headers: res.headers }); });
  });
  req.setTimeout(10_000, () => req.destroy(new Error('timeout')));
  req.on('error', (e) => done({ s: `no response (${e.code ?? e.message})`, headers: {} }));
  if (data) req.write(data);
  req.end();
});
const send = async (...a) => (await exchange(...a)).s;
// A legitimate GET to find out whether the app still answers: its headers are not a row's.
const ping = async () => (await exchange('GET', '/', BROWSER, undefined, undefined, false)).s;
const rejected = (s) => s >= 400 && s < 500;
// The app validating or refusing the body is not the defense under test.
const validation = (s, origin) => s === 409 || s === 422 || (origin && s === 400);

const alive = await ping();
if (typeof alive !== 'number') { console.error(`The app does not respond at ${base}: ${alive}`); process.exit(2); }

const rows = [], notes = [], infos = [];
// The body of a write in the wire format: the form as it was given, or the same fields as a JSON object.
const FORM = 'application/x-www-form-urlencoded';
// Attack number n (0 is the legitimate request) varies every free text field: `-a<n>` at its end, before the `@` of an email.
// A formatted value is left as given —a time, a date, a number written as text, a UUID—: a suffix would make it invalid and
// every attack would be refused for the format instead of for what it attacks.
const FORMATTED = /^[^\p{L}]*$|^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/iu;
const vary = (v, n) => {
  if (typeof v === 'string') return FORMATTED.test(v) ? v : v.includes('@') ? v.replace('@', `-a${n}@`) : `${v}-a${n}`;
  if (Array.isArray(v)) return v.map((x) => vary(x, n));
  return v && typeof v === 'object' ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, vary(x, n)])) : v;
};
const wire = (body, json, n = 0) => {
  const given = /^\s*[{[]/.test(body);
  if (!json) return { text: n ? new URLSearchParams([...new URLSearchParams(body)].map(([k, v]) => [k, vary(v, n)])).toString() : body, type: FORM };
  let fields = given ? null : Object.fromEntries(new URLSearchParams(body));
  if (given) try { fields = JSON.parse(body); } catch { return { text: body, type: 'application/json' }; }
  return { text: JSON.stringify(n ? vary(fields, n) : fields), type: 'application/json' };
};
const big = (json) => (json ? { text: JSON.stringify({ x: 'a'.repeat(1 << 20) }), type: 'application/json' } : { text: 'x=' + 'a'.repeat(1 << 20), type: FORM });
const attack = async (name, method, r, headers, body, origin = false, soft = false) => {
  const s = await send(method, r, headers, body?.text, body?.type);
  const invalid = typeof s === 'number' && validation(s, origin);
  const bad = typeof s === 'number' && !invalid && !rejected(s);
  rows.push({ name, s, invalid, bad: bad && !soft, info: bad && soft });
};
const hostAttack = (name, method, r, body) => attack(name, method, r, { ...BROWSER, host: 'attacker.example' }, body, false, !strictHost);
// What the legitimate responses set that a browser would send back on its own.
const ambient = [];
const legitimate = async (name, method, r, body) => {
  const { s, headers } = await exchange(method, r, BROWSER, body?.text, body?.type);
  for (const h of ['set-cookie', 'www-authenticate']) if (headers[h] !== undefined) ambient.push(`${h} on ${method} ${r}`);
  rows.push({ name, s, bad: typeof s === 'number' && s >= 400, control: true });
  return s;
};
let count = 0;
const jsonPosts = [];

// The HTTP hardening of a JSON API. A probe that cannot reach a verdict is not a pass: `invalid` is COULD NOT RUN.
const HANG_MS = Number(process.env.ATTACK_HANG_MS ?? 6000);
const BEYOND = 2 << 20;
// A body that does not end: opens with part of a JSON string and keeps sending until the server reacts or 2 MB are out,
// then waits HANG_MS for it. A server that cuts answers a status or drops the connection; one that keeps reading hangs.
const neverEnds = (r, chunked) => new Promise((done) => {
  const target = new URL(base);
  const headers = { ...extra, ...BROWSER, 'content-type': 'application/json', ...(chunked ? { 'transfer-encoding': 'chunked' } : { 'content-length': 100 << 20 }) };
  const req = request({ hostname: target.hostname, port: target.port, path: r, method: 'POST', headers });
  let sent = 0, over = false, stalled = false, waiting;
  const piece = Buffer.alloc(16 << 10, 97);
  const finish = (v) => { if (over) return; over = true; clearInterval(pump); clearTimeout(waiting); req.destroy(); done({ ...v, sent }); };
  const pump = setInterval(() => {
    if (sent >= BEYOND) {
      clearInterval(pump);
      // The chunked body is closed cleanly before the verdict, so a server that only now answers does not crash on a dropped connection.
      waiting = setTimeout(() => { stalled = true; if (chunked) req.end(); setTimeout(() => finish({ kind: 'hung' }), 500); }, HANG_MS);
      return;
    }
    req.write(sent === 0 ? Buffer.concat([Buffer.from('{"x":"'), piece]) : piece);
    sent += piece.length;
  }, 10);
  req.on('response', (res) => { res.resume(); noteMissing(`POST ${r} answered ${res.statusCode}`, res.headers); noteSeen('POST', r, res.statusCode); finish(stalled ? { kind: 'hung' } : { kind: 'status', s: res.statusCode }); });
  req.on('error', (e) => finish({ kind: 'closed', code: e.code ?? e.message }));
  req.on('close', () => finish({ kind: 'closed', code: 'closed' }));
});
// The row of a body that never ends. The probe that follows a dropped connection finds out whether the app survived it.
const hang = async (r, chunked) => {
  const v = await neverEnds(r, chunked);
  const name = `POST ${r} with a body that never ends (${chunked ? 'chunked' : 'Content-Length'})`;
  const alive = typeof (await ping()) === 'number';
  if (typeof v.code === 'string' && v.code.startsWith('ECONNREFUSED')) rows.push({ name, s: '-', bad: false, invalid: true, evidence: 'the app was already down' });
  else if (v.kind === 'hung') rows.push({ name, s: '-', bad: true, evidence: `the server kept waiting ${HANG_MS} ms after ${v.sent} bytes: no timeout, no limit${alive ? '' : '; and it stopped answering when the connection was dropped'}` });
  else if (!alive) rows.push({ name, s: '-', bad: true, evidence: `the app stopped answering after the connection was dropped (${v.kind}, ${v.sent} bytes sent)` });
  else if (bodyLimit && v.kind === 'status') rows.push({ name, s: v.s, bad: v.s !== 413, evidence: v.s === 413 ? `cut with 413 after ${v.sent} bytes` : `expected 413 (limit ${bodyLimit}): answered ${v.s} after ${v.sent} bytes` });
  else if (bodyLimit) rows.push({ name, s: '-', bad: true, evidence: `expected 413 (limit ${bodyLimit}): the connection was dropped (${v.code}) after ${v.sent} bytes` });
  else if (v.kind === 'status') rows.push({ name, s: v.s, bad: !rejected(v.s), evidence: `cut with ${v.s} after ${v.sent} bytes` });
  else rows.push({ name, s: '-', bad: false, evidence: `the server dropped the connection (${v.code}) after ${v.sent} bytes` });
};
const hardening = async (r, body) => {
  // The legitimate fields of the write, with the first text field replaced: the app does not refuse the body for a field it does not know.
  const fields = () => { const f = JSON.parse(wire(body, true, ++count).text); return [f, Object.keys(f).find((x) => typeof f[x] === 'string') ?? 'x']; };
  if (bodyLimit) {
    const [f, key] = fields();
    f[key] = 'x';
    const rest = Buffer.byteLength(JSON.stringify(f)) - 1;
    f[key] = 'é'.repeat(Math.max(Math.floor((bodyLimit - rest) / 2) + 1, 1));
    const text = JSON.stringify(f);
    const bytes = Buffer.byteLength(text);
    const name = `POST ${r} with a body over the byte limit (multibyte)`;
    if (bytes <= bodyLimit) rows.push({ name, s: '-', bad: false, invalid: true, evidence: `the limit ${bodyLimit} is too small to build the body` });
    else {
      const s = await send('POST', r, BROWSER, text, 'application/json');
      rows.push({ name, s, bad: s !== 413, evidence: `${text.length} characters, ${bytes} bytes, expected 413 (limit ${bodyLimit}): answered ${s}` });
    }
  }
  const [f, key] = fields();
  f[key] = 'MARKER';
  const [head, tail] = JSON.stringify(f).split('MARKER');
  const data = Buffer.concat([Buffer.from(head), Buffer.from([0xc3, 0x28, 0xff]), Buffer.from(tail)]);
  const s = await send('POST', r, BROWSER, data, 'application/json');
  rows.push({ name: `POST ${r} with invalid UTF-8 in the body`, s, bad: typeof s === 'number' && !rejected(s), evidence: `bytes C3 28 FF inside a string: answered ${s}` });
};

// A 50 MB `text/plain` body to a JSON endpoint, sent in a stream at about 12 MB/s: a server that looks at the content type
// answers 4xx at the first bytes; one that reads the body first answers when it is all out, 4 s later.
const BIG_TOTAL = 50 << 20;
const streamPlain = (method, r) => new Promise((done) => {
  const target = new URL(base);
  const req = request({ hostname: target.hostname, port: target.port, path: r, method, headers: { ...extra, ...BROWSER, 'content-type': 'text/plain', 'content-length': BIG_TOTAL } });
  const piece = Buffer.alloc(64 << 10, 97);
  const t0 = Date.now();
  let sent = 0, over = false, late;
  const finish = (v) => { if (over) return; over = true; clearInterval(pump); clearTimeout(late); req.destroy(); done({ ...v, sent, ms: Date.now() - t0 }); };
  const pump = setInterval(() => {
    if (sent >= BIG_TOTAL) { clearInterval(pump); late = setTimeout(() => finish({ kind: 'silent' }), 3000); return; }
    if (req.writableNeedDrain) return;
    req.write(piece);
    sent += piece.length;
  }, 5);
  req.on('response', (res) => { res.resume(); noteMissing(`${method} ${r} answered ${res.statusCode}`, res.headers); noteSeen(method, r, res.statusCode); finish({ kind: 'status', s: res.statusCode }); });
  req.on('error', (e) => finish({ kind: 'closed', code: e.code ?? e.message }));
  req.on('close', () => finish({ kind: 'closed', code: 'closed' }));
});
const bigPlain = async (method, r) => {
  const name = `${method} ${r} with a 50 MB text/plain body (streamed)`;
  const v = await streamPlain(method, r);
  const mb = (v.sent / (1 << 20)).toFixed(1);
  if (typeof v.code === 'string' && v.code.startsWith('ECONNREFUSED')) return rows.push({ name, s: '-', bad: false, invalid: true, evidence: 'the app was already down' });
  const early = v.sent < BIG_TOTAL || v.ms < 2000;
  if (v.kind === 'status' && rejected(v.s)) rows.push({ name, s: v.s, bad: !early, evidence: early ? '' : `answered ${v.s} only after reading the 50 MB (${v.ms} ms): the content type is checked after the body` });
  else if (v.kind === 'status') rows.push({ name, s: v.s, bad: true, evidence: `expected a 4xx for the wrong content type: answered ${v.s} after ${mb} MB` });
  else if (v.kind === 'closed') rows.push({ name, s: '-', bad: v.sent >= BIG_TOTAL, evidence: v.sent >= BIG_TOTAL ? 'the connection was dropped only after the 50 MB were sent' : `the server dropped the connection (${v.code}) after ${mb} MB` });
  else rows.push({ name, s: '-', bad: true, evidence: `no answer 3 s after the 50 MB were sent` });
  if (typeof (await ping()) !== 'number') Object.assign(rows.at(-1), { bad: true, evidence: `${rows.at(-1).evidence ?? ''} the app stopped answering afterwards`.trim() });
};

// Raw requests over a socket to the host of the URL: node:http cannot send them. The answer is read up to the end of its head.
const rawExchange = (payload) => new Promise((done) => {
  const target = new URL(base);
  const socket = connect({ host: target.hostname, port: Number(target.port || 80) });
  let data = Buffer.alloc(0), over = false, timer;
  const parse = (text) => {
    const lines = text.split('\r\n');
    const s = Number(lines[0].match(/^HTTP\/\d(?:\.\d)? (\d{3})/)?.[1]);
    const headers = Object.fromEntries(lines.slice(1).filter((l) => l.includes(':')).map((l) => [l.slice(0, l.indexOf(':')).trim().toLowerCase(), l.slice(l.indexOf(':') + 1).trim()]));
    return Number.isInteger(s) ? { kind: 'status', s, headers } : { kind: 'garbled', text: lines[0].slice(0, 40) };
  };
  const finish = (v) => { if (over) return; over = true; clearTimeout(timer); socket.destroy(); done(v); };
  timer = setTimeout(() => finish({ kind: 'silent' }), 3000);
  socket.on('connect', () => socket.write(payload));
  socket.on('data', (d) => { data = Buffer.concat([data, d]); const i = data.indexOf('\r\n\r\n'); if (i >= 0) finish(parse(data.subarray(0, i).toString('latin1'))); });
  socket.on('error', (e) => finish(data.length ? parse(data.toString('latin1')) : { kind: 'closed', code: e.code ?? e.message }));
  socket.on('close', () => finish(data.length ? parse(data.toString('latin1')) : { kind: 'closed', code: 'closed' }));
});
const RAW = [
  ['GARBAGE', 'GARBAGE\r\n\r\n'],
  ['a request line with a non-ASCII path, not encoded', Buffer.from(`GET /ñandú-é HTTP/1.1\r\nHost: ${url.host}\r\nConnection: close\r\n\r\n`, 'utf8')],
  ['a 20 KB header', `GET / HTTP/1.1\r\nHost: ${url.host}\r\nConnection: close\r\nX-Kit-Big: ${'a'.repeat(20 << 10)}\r\n\r\n`],
];
const rawRows = async () => {
  for (const [what, payload] of RAW) {
    const name = `raw request: ${what}`;
    const v = await rawExchange(payload);
    const up = typeof (await ping()) === 'number';
    if (typeof v.code === 'string' && v.code.startsWith('ECONNREFUSED')) { rows.push({ name, s: '-', bad: false, invalid: true, evidence: 'the app was already down' }); continue; }
    if (v.kind === 'status' && !rawHeadersExempt) noteMissing(`the answer ${v.s} to ${what}`, v.headers);
    const exempt = v.kind === 'status' && rawHeadersExempt && commonHeaders.some((h) => v.headers[h] === undefined) ? `common headers not checked (declared): ${rawHeadersExempt}` : '';
    if (v.kind === 'status') rows.push({ name, s: v.s, bad: !rejected(v.s), evidence: [rejected(v.s) ? '' : `expected a 4xx: answered ${v.s}`, exempt].filter(Boolean).join(' · ') });
    else if (v.kind === 'closed') rows.push({ name, s: '-', bad: false, evidence: '' });
    else if (v.kind === 'silent') rows.push({ name, s: '-', bad: true, evidence: 'no answer and no close in 3 s' });
    else rows.push({ name, s: '-', bad: true, evidence: `the answer is not an HTTP response: ${v.text}` });
    if (!up) Object.assign(rows.at(-1), { bad: true, evidence: `${rows.at(-1).evidence} the app stopped answering after it`.trim() });
  }
};

// Identical requests at once: a uniqueness rule that checks and then inserts lets more than one through.
const uniqueRow = async ({ method, path: r, body }) => {
  const name = `${method} ${r} 8 identical requests at once (one succeeds, the rest 4xx)`;
  let json = jsonFlag || /^\s*[{[]/.test(body);
  const burst = () => { const p = wire(body, json, ++count); return Promise.all(Array.from({ length: 8 }, () => exchange(method, r, BROWSER, p.text, p.type))); };
  let all = await burst();
  if (!json && all.every((x) => x.s === 415)) { json = true; all = await burst(); }
  const codes = all.map((x) => x.s);
  const ok = codes.filter((s) => typeof s === 'number' && s >= 200 && s < 400).length;
  const five = codes.filter((s) => typeof s === 'number' && s >= 500).length;
  const lost = codes.filter((s) => typeof s !== 'number').length;
  const list = codes.join(' ');
  if (lost === 8) rows.push({ name, s: '-', bad: false, invalid: true, evidence: `no response: ${list}` });
  else if (five || lost || ok > 1) rows.push({ name, s: '-', bad: true, evidence: `${ok} succeeded${five ? `, ${five} answered 5xx` : ''}${lost ? `, ${lost} got no response` : ''}: ${list}` });
  else if (ok === 0) rows.push({ name, s: '-', bad: false, invalid: true, evidence: `none succeeded, so the race was not tried (the body may be refused): ${list}` });
  else rows.push({ name, s: '-', bad: false, evidence: `${list}` });
};

// The database locked while a legitimate write arrives: the app answers a 5xx and stays up.
const faultRow = async () => {
  const [w] = writes;
  const name = `${w?.method ?? 'write'} ${w?.path ?? ''} with the database locked (BEGIN EXCLUSIVE on ${faultDb})`.replace('  ', ' ');
  const notRun = (why) => rows.push({ name, s: '-', bad: false, invalid: true, evidence: why });
  let sqlite;
  try { sqlite = await import('node:sqlite'); } catch { return notRun('node:sqlite is not available in this Node'); }
  if (!existsSync(faultDb)) return notRun(`${faultDb} does not exist`);
  if (!w) return notRun('--fault-db needs a --write to send');
  const db = new sqlite.DatabaseSync(faultDb);
  let json = jsonFlag || /^\s*[{[]/.test(w.body);
  let answer;
  try {
    db.exec('BEGIN EXCLUSIVE');
    const post = () => { const p = wire(w.body, json, ++count); return exchange(w.method, w.path, BROWSER, p.text, p.type); };
    answer = await post();
    if (!json && answer.s === 415) { json = true; answer = await post(); }
  } catch (e) { return notRun(`the database could not be locked: ${e.message}`); } finally { try { db.exec('ROLLBACK'); } catch { /* not locked */ } db.close(); }
  const up = typeof (await ping()) === 'number';
  const { s } = answer;
  if (typeof s !== 'number') rows.push({ name, s: '-', bad: true, evidence: `no answer while the database was locked (${s}): the process died or dropped the connection${up ? '' : '; it does not answer now'}` });
  else if (s < 500) rows.push({ name, s, bad: true, evidence: `expected a 5xx with the database locked: answered ${s}` });
  else rows.push({ name, s, bad: !up, evidence: up ? '' : `answered ${s} and then the app stopped answering` });
};

for (const { method, path: r, body } of writes) {
  const legit = `${method} ${r} legitimate, from the page itself`;
  let json = jsonFlag || /^\s*[{[]/.test(body);
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
  await hostAttack(`${method} ${r} with a foreign Host`, method, r, wire(body, json, ++count));
  await attack(`${method} ${r} with a 1 MB body`, method, r, BROWSER, big(json));
  if (json) await attack(`${method} ${r} with a malformed JSON body`, method, r, BROWSER, { text: '{"x":', type: 'application/json' });
  for (const other of ['PUT', 'DELETE', 'PATCH'].filter((m) => m !== method))
    await attack(`${other} ${r} (method that does not apply)`, other, r, BROWSER, wire(body, json, ++count));
  if (json && method === 'POST') { await hardening(r, body); await hang(r, true); jsonPosts.push(r); }
  if (json) await bigPlain(method, r);
}
for (const r of reads) {
  await legitimate(`GET ${r} legitimate, from the page itself`, 'GET', r);
  if (!noAmbient) for (const [name, headers] of ORIGINS.slice(0, 2)) await attack(`GET ${r} ${name}`, 'GET', r, headers, undefined, true);
  await hostAttack(`GET ${r} with a foreign Host`, 'GET', r);
}
// An app that dies on a double slash takes the rest of the run with it: the body with a large Content-Length that does not arrive comes after, and drops its connection.
for (const r of ['/', ...writes.map((w) => w.path), ...reads]) {
  const path = '/' + r;
  const before = await ping();
  const { s } = await exchange('GET', path, BROWSER);
  const answered = typeof s === 'number';
  if (typeof before !== 'number') rows.push({ name: `GET ${path} (double slashes in the path)`, s: '-', bad: false, invalid: true, evidence: 'the app was already down' });
  else rows.push({ name: `GET ${path} (double slashes in the path)`, s: answered ? s : '-', bad: !answered || s >= 500, evidence: answered ? `answered ${s}` : `the app answered / and then did not answer this path: ${s}` });
}
await rawRows();
for (const r of jsonPosts) await hang(r, false);
for (const u of uniques) await uniqueRow(u);
if (faultDb) await faultRow();
// The documented statuses per operation of an OpenAPI file: { 'GET /items/{id}': Set('200', '404') }.
const HTTP_METHODS = ['get', 'put', 'post', 'delete', 'patch', 'head', 'options'];
const contractOf = (text) => {
  const ops = {};
  let doc = null;
  try { doc = JSON.parse(text); } catch { /* YAML */ }
  if (doc) {
    for (const [p, item] of Object.entries(doc.paths ?? {})) for (const m of HTTP_METHODS) if (item?.[m]) ops[`${m.toUpperCase()} ${p}`] = new Set(Object.keys(item[m].responses ?? {}).map(String));
    return ops;
  }
  const unquote = (k) => k.trim().replace(/^(['"])(.*)\1$/, '$2');
  let inPaths = false, path = null, method = null, resp = null, pathIndent = -1, respIndent = -1, child = null;
  for (const raw of text.split(/\r?\n/)) {
    if (!raw.trim() || raw.trim().startsWith('#')) continue;
    const indent = raw.length - raw.trimStart().length;
    const m = raw.trim().match(/^(['"][^'"]+['"]|[^\s:'"][^:]*?)\s*:(?:\s|$)/);
    if (indent === 0) { inPaths = /^paths\s*:/.test(raw); path = method = resp = null; continue; }
    if (!inPaths || !m) continue;
    const key = unquote(m[1]);
    if (pathIndent < 0 && key.startsWith('/')) pathIndent = indent;
    if (indent === pathIndent) { path = key.startsWith('/') ? key : null; method = resp = null; continue; }
    if (!path) continue;
    if (resp && indent > respIndent) { child ??= indent; if (indent === child) ops[resp].add(key); continue; }
    resp = null;
    child = null;
    if (HTTP_METHODS.includes(key.toLowerCase()) && indent > pathIndent && (method === null || indent <= method.indent)) { method = { name: key.toUpperCase(), indent }; continue; }
    if (method && key === 'responses' && indent > method.indent) { resp = `${method.name} ${path}`; ops[resp] ??= new Set(); respIndent = indent; }
  }
  return ops;
};
// A response whose status the contract does not list for its operation is a row that fails; one row per method, path and status.
const openapiRows = () => {
  let ops = {};
  try { ops = contractOf(readFileSync(openapi, 'utf8')); } catch (e) { rows.push({ name: `--openapi ${openapi}`, s: '-', bad: false, invalid: true, evidence: `the contract cannot be read: ${e.code ?? e.message}` }); return; }
  const templates = Object.keys(ops).map((k) => { const [method, tpl] = [k.slice(0, k.indexOf(' ')), k.slice(k.indexOf(' ') + 1)]; return { key: k, method, tpl, re: new RegExp(`^${tpl.split(/\{[^}]*\}/).map((x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('[^/]+')}/?$`) }; });
  if (!templates.length) { rows.push({ name: `--openapi ${openapi}`, s: '-', bad: false, invalid: true, evidence: 'no operation found under `paths:`' }); return; }
  const reported = new Set();
  for (const { method, path: p, s } of seen) {
    const hits = templates.filter((t) => t.method === method && t.re.test(p)).sort((a, b) => a.tpl.split('{').length - b.tpl.split('{').length);
    if (!hits.length) continue;
    const documented = ops[hits[0].key];
    const code = String(s);
    if ([...documented].some((d) => d === code || d.toUpperCase() === `${code[0]}XX` || d.toLowerCase() === 'default')) continue;
    const id = `${hits[0].key} ${code}`;
    if (reported.has(id)) continue;
    reported.add(id);
    rows.push({ name: `${hits[0].key} answered ${code}, which the contract does not document`, s, bad: true, evidence: `documented: ${[...documented].join(', ') || 'none'}; seen on ${method} ${p}` });
  }
  if (!reported.size) rows.push({ name: `every status answered is documented in ${openapi}`, s: '-', bad: false, control: true });
};
if (openapi) openapiRows();
// A response that lacks a common header fails the row it belongs to.
for (const m of missingLog) {
  const row = rows[m.at] ?? rows.at(-1);
  if (!row) continue;
  Object.assign(row, { bad: true, invalid: false, info: false });
  const text = `${m.what} lacks the header ${m.h}`;
  if (!row.evidence?.includes(text)) row.evidence = [row.evidence, text].filter(Boolean).join('; ');
}
if (noAmbient) rows.push({ name: `no ambient credentials: no legitimate response sets Set-Cookie or asks WWW-Authenticate${ambient.length ? ` (${ambient.join(', ')})` : ''}`, s: '-', bad: ambient.length > 0, control: true });

for (const n of notes) console.log(`note: ${n}`);
// No response is neither “passed” nor “blocked”: it could not run, and it counts as neither. Nor is an answer that
// validates the body (409, 422, a 400 on an origin row) instead of defending.
let bad = 0, notRun = 0;
for (const f of rows) {
  const responded = f.s === '-' || typeof f.s === 'number';
  const mark = !responded || f.invalid ? 'COULD NOT RUN' : f.info ? 'info         ' : f.control ? (f.bad ? 'FAILS        ' : 'ok           ') : (f.bad ? 'PASSED       ' : 'blocked      ');
  if (!responded || f.invalid) notRun++; else if (f.bad) bad++;
  console.log(`${mark}  ${String(f.s).padEnd(4)}  ${f.name}`);
  if (f.evidence && (f.bad || f.invalid)) console.log(`               evidence: ${f.evidence}`);
}
for (const i of infos) console.log(`info · no Origin header · ${i.s} · ${i.name} · served by S1: a browser always sends Origin on a cross-site write`);
if (bad) console.log(`\n${bad} problem(s): an attack got through or the legitimate request did not work.`);
if (notRun) console.log(`${bad ? '' : '\n'}${notRun} could not run: the app did not respond, or answered the body (409, 422, 400) and not the defense.`);
if (!bad && !notRun) console.log('\nNo attack got through and the legitimate request worked.');
const exempted = rows.filter((r) => /common headers not checked \(declared\)/.test(r.evidence ?? '')).map((r) => r.name.replace(/^raw request: /, ''));
if (exempted.length) console.log(`Raw requests without the common headers (${exempted.join('; ')}): common headers not checked (declared): ${rawHeadersExempt}`);
process.exit(bad ? 1 : notRun ? 2 : 0);
