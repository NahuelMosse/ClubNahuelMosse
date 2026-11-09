import { is4xx, is5xx } from '../http.mjs';

const DEFAULT_HEADER_BYTES = 20 << 10;
const HEADER_SLACK = 1024;

// Raw requests node:http refuses to send. Node, uvicorn, Go and most frameworks answer these from the parser, before any
// middleware: the app's common headers (request id, CORS, cache, security headers) are missing unless the parser error is handled.
export async function parserProbes(run, { writes }) {
  const { client, opts } = run;
  const host = client.base.host;
  const bigHeader = (run.settings('GET', '/').maxHeaderBytes ?? DEFAULT_HEADER_BYTES - HEADER_SLACK) + HEADER_SLACK;
  const smuggleTarget = writes[0]?.path ?? '/';
  const RAW = [
    ['garbage-request-line', 'GARBAGE request line', 'GARBAGE\r\n\r\n', '400', false],
    ['non-ascii-path', 'non-ASCII bytes in the request path', Buffer.from(`GET /ñandú HTTP/1.1\r\nHost: ${host}\r\nConnection: close\r\n\r\n`, 'utf8'), 'any non-5xx (a 2xx is fine for a catch-all route)', true],
    ['big-header', `${Math.round(bigHeader / 1024)} KB header`, `GET / HTTP/1.1\r\nHost: ${host}\r\nConnection: close\r\nX-Big: ${'a'.repeat(bigHeader)}\r\n\r\n`, '431', false],
    ['cl-te-conflict', 'conflicting Content-Length and Transfer-Encoding', `POST ${smuggleTarget} HTTP/1.1\r\nHost: ${host}\r\nContent-Length: 4\r\nTransfer-Encoding: chunked\r\nConnection: close\r\n\r\n0\r\n\r\n`, '400 (request smuggling guard)', false],
  ];
  for (const [probe, what, payload, want, anyOk] of RAW) {
    const spec = { group: 'parser', probe, target: 'raw', name: `raw: ${what}` };
    const v = await client.raw(payload);
    const expected = `${want} with the common headers, then the connection closes`;
    if (!(await client.alive())) { run.fail('process-died', spec, v.s ?? v.kind, expected, 'the app stopped answering'); continue; }
    if (v.kind === 'closed') { run.pass(spec, 'closed', expected); continue; }
    if (v.kind !== 'status') { run.fail('parser-accepted', spec, v.kind, expected, v.text ?? 'no answer and no close in 3 s'); continue; }
    if (is5xx(v.s)) { run.fail('server-error', spec, v.s, expected); continue; }
    if (!is4xx(v.s)) {
      if (anyOk) run.pass(spec, v.s, expected);
      else run.fail('parser-accepted', spec, v.s, expected, probe === 'big-header' ? `the header limit is above ${Math.round(bigHeader / 1024)} KB: set maxHeaderBytes to the app's limit` : undefined);
      continue;
    }
    const missing = opts.common.filter((h) => v.headers[h] === undefined);
    if (missing.length && !opts.rawExempt) run.fail('parser-no-common-headers', spec, v.s, expected, `the parser's answer lacks ${missing.join(', ')}: the error is answered before the app's middleware`);
    else run.pass(spec, v.s, expected, missing.length ? `common headers exempt: ${opts.rawExempt}` : undefined);
  }
}
