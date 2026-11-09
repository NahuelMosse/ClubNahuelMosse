import { request } from 'node:http';
import { connect } from 'node:net';

export const is2xx = (s) => s >= 200 && s < 300;
export const is4xx = (s) => s >= 400 && s < 500;
export const is5xx = (s) => s >= 500;

// A login page is a Location with a whole path segment that names one: /login, /accounts/sign-in, /auth/start. Segments are
// compared whole, so /authors/3 and /processors are not login pages.
const LOGIN_SEGMENTS = new Set(['login', 'log-in', 'log_in', 'logon', 'signin', 'sign-in', 'sign_in', 'sso', 'auth', 'authenticate']);
export const isLoginLocation = (location) => {
  if (!location) return false;
  try {
    return new URL(location, 'http://local').pathname.split('/').some((segment) => LOGIN_SEGMENTS.has(decodeURIComponent(segment).toLowerCase().replace(/\.[a-z]+$/, '')));
  } catch { return false; }
};

// Access was granted: a 2xx, or a redirect that does not lead to a login page (a 303 to the created item is a grant).
export const granted = (res) => is2xx(res.s) || (res.s >= 300 && res.s < 400 && !isLoginLocation(res.headers?.location));

const BODY_CAP = 200_000;
const REQUEST_TIMEOUT_MS = 10_000;
const RAW_TIMEOUT_MS = 3000;
const STREAM_TICK_MS = 5;

const ID_SEGMENT = /\/(?:\d+|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[0-9a-f]{12,})(?=\/|$)/gi;

const ALWAYS_CREDENTIAL =['authorization', 'cookie', 'x-api-key'];

const bareHost = (hostname) => hostname.replace(/^\[|\]$/g, '');

// Everything that talks to the app. `base` is a URL; `opts` carries the credentials and the common-header list.
export function createClient(base, opts) {
  const host = bareHost(base.hostname);
  const port = Number(base.port || 80);
  const credentialNames = [...ALWAYS_CREDENTIAL, ...opts.authHeaderNames];
  const withoutCredentials = (h) => Object.fromEntries(Object.entries(h).filter(([k]) => !credentialNames.includes(k)));
  const seen = []; // { method, path, s } of every probe response, for --openapi
  const misses = new Map(); // "METHOD path" => { headers, statuses }: responses that lack a common header

  const noteHeaders = (method, path, status, headers) => {
    seen.push({ method, path: path.split('?')[0], s: status });
    const missing = opts.common.filter((h) => headers?.[h] === undefined);
    if (!missing.length) return;
    const key = `${method} ${path.split('?')[0]}`;
    const entry = misses.get(key) ?? { method, path: path.split('?')[0], headers: new Set(), statuses: new Set() };
    missing.forEach((h) => entry.headers.add(h));
    entry.statuses.add(status);
    misses.set(key, entry);
  };

  // The misses grouped by route, so one defect is one id however many ids the paths carried: a path that fits the item
  // template is that template, else numeric, UUID and long hex segments become {id}.
  const missesByRoute = (itemTemplate) => {
    const fits = itemTemplate && new RegExp(`^${itemTemplate.split('?')[0].split(/\{[^}]*\}/).map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('[^/]+')}$`);
    const routeOf = ({ method, path }) => (fits?.test(path) ? `${method} ${itemTemplate.split('?')[0]}` : `${method} ${path.replace(ID_SEGMENT, '/{id}')}`);
    const routes = new Map();
    for (const entry of misses.values()) {
      const route = routeOf(entry);
      const group = routes.get(route) ?? { headers: new Set(), statuses: new Set() };
      entry.headers.forEach((h) => group.headers.add(h));
      entry.statuses.forEach((s) => group.statuses.add(s));
      routes.set(route, group);
    }
    return routes;
  };

  // node:http, because fetch cannot send a path starting with // nor stream a slow body.
  // auth: 'a' (the default headers), 'none' (credentials removed), 'b' (the other user's credentials),
  // 'cookie' (only the session cookie, as a browser sends it: no token or API key header).
  const sendOnce = (method, path, { body, type, headers = {}, auth = 'a', common = true } = {}) => new Promise((done) => {
    const data = body === undefined ? null : Buffer.isBuffer(body) ? body : Buffer.from(body);
    const cookie = opts.headers.cookie === undefined ? {} : { cookie: opts.headers.cookie };
    const creds = auth === 'b' ? { ...withoutCredentials(opts.headers), ...opts.otherHeaders }
      : auth === 'none' ? withoutCredentials(opts.headers)
        : auth === 'cookie' ? { ...withoutCredentials(opts.headers), ...cookie } : opts.headers;
    const all = { ...creds, ...(data ? { 'content-length': data.length, ...(type ? { 'content-type': type } : {}) } : {}), ...headers };
    let settled = false;
    const settle = (v) => { if (!settled) { settled = true; done(v); } };
    let answered = false;
    const req = request({ hostname: host, port, path, method, agent: false,
      headers: Object.fromEntries(Object.entries(all).filter(([, v]) => v !== undefined)) }, (res) => {
      answered = true;
      let text = '';
      res.setEncoding('utf8');
      res.on('data', (d) => { if (text.length < BODY_CAP) text += d; });
      const result = (extra) => ({ s: res.statusCode, headers: res.headers, text, ...extra });
      res.on('end', () => {
        if (common) noteHeaders(method, path, res.statusCode, res.headers);
        settle(result());
      });
      // Headers sent, then the connection cut: the answer is the status that was seen, flagged incomplete.
      res.on('aborted', () => settle(result({ truncated: true, err: 'ECONNRESET' })));
      res.on('close', () => settle(result({ truncated: !res.complete, err: res.complete ? undefined : 'ECONNRESET' })));
    });
    req.setTimeout(REQUEST_TIMEOUT_MS, () => req.destroy(new Error('timeout')));
    // Once the status line is in, a write error (EPIPE, ECONNRESET) is the server closing after answering early,
    // as Node does for a request with "Connection: close": the response events decide the outcome.
    let written = false;
    req.on('finish', () => { written = true; });
    req.on('error', (e) => answered || settle({ s: null, err: e.code ?? e.message, headers: {}, text: '', written }));
    req.end(data ?? undefined);
  });

  // A server that rejects a large body early and closes while the client is still writing can have its answer discarded
  // by the reset (Windows drops unread data on RST): a cut with no answer counts only when a second try is cut too.
  // Only a body cut before it was fully written is sent again: the server cannot have stored it.
  const RACE_BODY = 64 << 10;
  const send = async (method, path, options = {}) => {
    const first = await sendOnce(method, path, options);
    const large = options.body !== undefined && Buffer.byteLength(options.body) > RACE_BODY;
    const cutEarly = first.s === null && !first.written && /^(ECONNRESET|EPIPE)$/.test(first.err ?? '');
    return large && cutEarly ? sendOnce(method, path, options) : first;
  };

  const alive = async () => (await send('GET', '/', { common: false })).s !== null;

  // A body that keeps coming: a server without a limit or a timeout reads it forever.
  const stream = (method, path, headers, total, pieceSize, { stopAfterMs, prefix }) => new Promise((done) => {
    const req = request({ hostname: host, port, path, method, agent: false, headers: { ...opts.headers, ...headers } });
    const piece = Buffer.alloc(pieceSize, 97);
    const t0 = Date.now();
    let sent = 0, over = false, timer;
    const finish = (v) => { if (over) return; over = true; clearInterval(pump); clearTimeout(timer); req.destroy(); done({ ...v, sent, ms: Date.now() - t0 }); };
    const pump = setInterval(() => {
      if (sent >= total) { clearInterval(pump); timer = setTimeout(() => finish({ kind: 'silent' }), stopAfterMs); return; }
      if (req.writableNeedDrain) return;
      req.write(sent === 0 && prefix ? Buffer.concat([Buffer.from(prefix), piece]) : piece);
      sent += piece.length;
    }, STREAM_TICK_MS);
    req.on('response', (res) => { res.resume(); noteHeaders(method, path, res.statusCode, res.headers); finish({ kind: 'status', s: res.statusCode, headers: res.headers }); });
    req.on('error', (e) => finish({ kind: 'closed', code: e.code ?? e.message }));
    req.on('close', () => finish({ kind: 'closed', code: 'closed' }));
  });

  // Raw requests node:http refuses to send. Most servers answer them from the parser, before any middleware.
  const raw = (payload) => new Promise((done) => {
    const socket = connect({ host, port });
    let data = Buffer.alloc(0), over = false;
    const parse = (t) => {
      const lines = t.split('\r\n');
      const s = Number(lines[0].match(/^HTTP\/\d(?:\.\d)? (\d{3})/)?.[1]);
      const headers = Object.fromEntries(lines.slice(1).filter((l) => l.includes(':'))
        .map((l) => [l.slice(0, l.indexOf(':')).trim().toLowerCase(), l.slice(l.indexOf(':') + 1).trim()]));
      return Number.isInteger(s) ? { kind: 'status', s, headers } : { kind: 'garbled', text: lines[0].slice(0, 40) };
    };
    const finish = (v) => { if (over) return; over = true; clearTimeout(timer); socket.destroy(); done(v); };
    const timer = setTimeout(() => finish({ kind: 'silent' }), RAW_TIMEOUT_MS);
    socket.on('connect', () => socket.write(payload));
    socket.on('data', (d) => { data = Buffer.concat([data, d]); const i = data.indexOf('\r\n\r\n'); if (i >= 0) finish(parse(data.subarray(0, i).toString('latin1'))); });
    socket.on('error', (e) => finish(data.length ? parse(data.toString('latin1')) : { kind: 'closed', code: e.code }));
    socket.on('close', () => finish(data.length ? parse(data.toString('latin1')) : { kind: 'closed' }));
  });

  return { base, host, port, send, alive, stream, raw, misses, missesByRoute, seen, withoutCredentials, noteHeaders,
    hasCredentials: () => Object.keys(opts.headers).some((k) => credentialNames.includes(k)) };
}
