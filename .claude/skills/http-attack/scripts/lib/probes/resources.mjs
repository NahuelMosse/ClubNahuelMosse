import { is4xx } from '../http.mjs';
import { isJsonBody, wire } from '../body.mjs';

const MIB = 1 << 20;
const BIG = 50 * MIB;
const DEFAULT_LIMIT = 2 * MIB;
const MAX_STREAM = 64 * MIB;
const TEXT_PLAIN_WAIT_MS = 3000;
const FAST_REJECT_MS = 2000;
const CLAIMED_LENGTH = 100 * MIB;

const mb = (n) => (n / MIB).toFixed(1);

// Bodies that cost the server something: a big one with the wrong media type, and one that never ends.
export async function resourceProbes(run, w) {
  const { client, opts } = run;
  const target = `${w.method} ${w.path}`;
  const st = run.settings(w.method, w.path);
  const spec = (probe, name) => ({ group: 'resources', probe, target, name: `${target} ${name}` });
  const json = isJsonBody(w);
  const p = wire(w, st);

  const big = spec('text-plain-50mb', '50 MB text/plain body');
  if (!json) run.notRun(big, 'the write body is not JSON: the wrong-media-type probe sends text/plain to a JSON route');
  else {
    const expected = '415 (or 413) at the first bytes, before reading the body';
    const v = await client.stream(w.method, w.path, { 'content-type': 'text/plain', 'content-length': BIG }, BIG, 64 << 10, { stopAfterMs: TEXT_PLAIN_WAIT_MS });
    if (!(await client.alive())) run.fail('process-died', big, v.s ?? v.code, expected, 'the app stopped answering');
    else if (v.kind === 'status' && is4xx(v.s) && (v.sent < BIG || v.ms < FAST_REJECT_MS)) run.pass(big, v.s, expected);
    else if (v.kind === 'status' && is4xx(v.s)) run.fail('read-before-reject', big, v.s, expected, `answered only after reading all 50 MB (${v.ms} ms)`);
    else if (v.kind === 'closed' && v.sent < BIG) run.pass(big, 'closed', expected);
    else run.fail('no-body-limit', big, v.s ?? v.kind, expected, `${mb(v.sent)} MB sent`);
  }

  // Chunked, and with a large Content-Length that never arrives. With a declared limit the answer must be a 413: a reset
  // leaves the client without a status to act on.
  const limit = st.bodyLimit ?? DEFAULT_LIMIT;
  const framings = [['body-never-ends', 'chunked', { 'transfer-encoding': 'chunked' }], ['body-never-ends-length', 'Content-Length', { 'content-length': CLAIMED_LENGTH }]];
  for (const [probe, label, framing] of framings) {
    const endless = spec(probe, `body that never ends (${label})`);
    if (limit + 1 > MAX_STREAM) { run.notRun(endless, `bodyLimit ${limit} is above the ${mb(MAX_STREAM)} MB this probe will send`); continue; }
    const expected = st.bodyLimit ? '413 once over the limit' : '413 once over the limit, or 408 / connection closed within the request timeout';
    const send = () => client.stream(w.method, w.path, { 'content-type': p.type, ...framing }, limit + 1, 64 << 10,
      { stopAfterMs: opts.hangMs, prefix: json ? '{"x":"' : 'x=' });
    // A server that answers 413 and closes while the client is still writing can have that answer discarded by the
    // reset (Windows drops unread data on RST): a cut counts only when a second try is cut too.
    let v = await send();
    if (st.bodyLimit && v.kind === 'closed' && await client.alive()) v = await send();
    if (!(await client.alive())) run.fail('process-died', endless, v.s ?? v.code, expected, 'the app stopped answering');
    else if (v.kind === 'silent') run.fail('no-body-limit', endless, 'no answer', expected, `still reading after ${mb(v.sent)} MB (the limit is ${st.bodyLimit ? `${limit} bytes` : 'unknown: 2 MB assumed'}) and ${opts.hangMs} ms: no body limit, no timeout`);
    else if (v.kind === 'status' && !is4xx(v.s)) run.fail('no-body-limit', endless, v.s, expected);
    else if (st.bodyLimit && v.kind === 'status' && v.s !== 413) run.fail('no-body-limit', endless, v.s, expected, `answered ${v.s} after ${mb(v.sent)} MB, not 413 (limit ${limit} bytes)`);
    else if (st.bodyLimit && v.kind !== 'status') run.fail('connection-dropped', endless, v.code, expected, `the connection was cut (${v.code}) after ${mb(v.sent)} MB instead of a 413 (limit ${limit} bytes)`);
    else run.pass(endless, v.s ?? 'closed', expected);
  }
}
