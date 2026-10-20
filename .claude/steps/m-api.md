# Module api · what it adds to the steps

Read the section of the step you are on, only while `api` is on in `.claude/kit.json`. It is about
the HTTP surface a card adds or changes. Its criteria: S1, S2, S5, S7, S17, O7, O22, W8 and W9;
its items: G2, Q5, Q8, Q9 and R10 of `.claude/reference/validate-mechanical.md`.

## Step 5 · The plan

- **The contract is a file of the card.** A route that is added or changed brings its OpenAPI,
  AsyncAPI or GraphQL file into the File map, and the line `- API contract: <what changes>` or
  `- API contract: unchanged — <why>` under `## Changes to existing behavior` (W8).
  `.claude/reference/documentation.md` (module docs) section 2 (API) says what the contract holds.
- **The perimeter** of every route that writes —who may call it, from where, how often— is a line
  of the bar (S1, S2, S5), read from `.claude/reference/security.md`; it is not left for step 8.
  S1 asks first whether the route is reached with ambient credentials; an API called by programs answers it with a decision line, not with code.
- **A hot path** —a route the card says is called often, or a volume requirement— is marked
  `hot-path` in the File map and carries a `load:` line in `## Verification` (O22, R10). The
  budget, the profile and the thresholds are in `.claude/reference/performance.md` section 3 (LOAD);
  the report is written from `.claude/templates/load-test.md`.

## Step 6 · Implementing

The route validates what comes in at the boundary and answers a controlled error, never the trace
(K8, E6). The contract changes in the same diff as the route, not in a later card.

The perimeter of a route (S2, E5, E6) is written from these recipes, so each card does not reinvent them:

- **Host** (S2): compare the hostname only —lowercase, without port, brackets or IPv6 zone— against a set built on every request from `localhost`, `os.hostname()`, every address of `os.networkInterfaces()`, `HOSTS` (comma-separated) and the hostname of `APP_URL` (the shared app), each through the same normalization; the card's own host goes in `HOSTS`. A foreign one answers 421 with the card's error shape. Never a default that rejects `localhost`, `127.0.0.1` or the shared app's host.
- **Body cap**: 413 from `Content-Length` or from the bytes read; stop reading and answer with `Connection: close`.
- **A client that aborts** (`aborted`, `ECONNRESET`, a body cut short) is not an error: no 500 and no log line.
- **The log of a 500**: method, path without query string, request id and the error; never the query, the body or a header. A logger that throws does not take the process down.
- **E5's test** injects the failure in the same process (a repository that throws); it never starts another process. **A test that starts a server closes it in `finally`.**

```js
const hostname = (h) => {
  const v = h.trim().toLowerCase();
  const bare = v.startsWith('[') ? v.slice(1, v.indexOf(']')) : v.split(':').length > 2 ? v : v.replace(/:\d+$/, '');
  return bare.replace(/%.*$/, '');
};
const allowedHosts = () => new Set([
  'localhost', os.hostname(), ...Object.values(os.networkInterfaces()).flatMap((list) => list ?? []).map((a) => a.address),
  ...(process.env.HOSTS ?? '').split(','), process.env.APP_URL ? new URL(process.env.APP_URL).hostname : '',
].filter(Boolean).map(hostname));
// per request: if (!allowedHosts().has(hostname(req.headers.host ?? ''))) { reply(421, hostNotAllowed); return; }
```

```js
const LIMIT = 1 << 20; // the card's limit
if (Number(req.headers['content-length']) > LIMIT) return refuse(413);
let size = 0, over = false;
req.on('data', (chunk) => {
  if (over) return;                     // what keeps arriving is dropped, not buffered
  size += chunk.length;
  if (size > LIMIT) { over = true; res.writeHead(413, { connection: 'close' }); res.end(payloadTooLarge); } else chunks.push(chunk);
});
req.on('error', () => {});              // aborted, ECONNRESET: nobody is waiting for an answer
req.on('close', () => { if (!req.complete) cancel(); }); // a body cut short
const logFailure = (req, id, err) => {
  try { console.error(JSON.stringify({ method: req.method, path: new URL(req.url, 'http://x').pathname, id, error: String(err?.message ?? err) })); } catch {}
};
```

## Step 8 · Verifying

- G2: `attack.mjs` over the routes the card adds or changes; the rest of the server is an `OUT`.
- Q8 and Q9: the contract is linted, and routes and spec match in both directions.
- Q5: the dynamic scan, **once per card at the end** over the final code, never in a fix loop.
- R10: the load test of a hot path, **alone**, after everything else has finished.
