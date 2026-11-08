# Fixes by finding and stack

Fix the cause in the app; do not special-case the probe. If a finding is correct behaviour for the route, suppress it in
`http-attack.config.json` with the reason (see SKILL.md). Rule names are the ones in the severity table.

## input: `accepted-invalid`, `server-error`, `media-type-strict`, `no-body-limit`, `limit-counts-characters`

| Probe | Correct | Fix |
|---|---|---|
| Truncated JSON | 400 with the app's error body | catch the parse error in the body middleware |
| Invalid UTF-8 inside a string | 400, nothing stored with U+FFFD | strict decoding (below), or accept the replacement on purpose and set `invalidUtf8: "replace"` for the route |
| No `Content-Type` | 415, never 5xx | read the header defensively: `(h ?? '').split(';')[0].trim().toLowerCase()` |
| `Application/JSON; charset=utf-8` | accepted | compare the media type lowercased, without parameters (RFC 9110 8.3.1) |
| String field sent as number, null, array, object | 400/422, never coerced | validate types with a schema; never `String(x)` user input |
| 1 MB body, limit+1 bytes of multibyte characters | 413 | count **bytes** while reading, not characters after decoding |
| PUT/DELETE/PATCH on a route that does not take them | 405 with `Allow` | let the router answer 405 and set `Allow` |

Strict UTF-8 and body limits per stack:

- **Express**: `express.json({ limit: '64kb', verify: (req, res, buf) => { new TextDecoder('utf-8', { fatal: true }).decode(buf); } })`
  and an error handler that maps `err.type === 'entity.too.large'` to 413 and `entity.parse.failed` or a `TypeError` from
  `verify` to 400. Without `verify`, body-parser replaces invalid bytes with U+FFFD.
- **Fastify**: `Fastify({ bodyLimit: 65536 })`; add a content-type parser with `parseAs: 'buffer'` that decodes with
  `new TextDecoder('utf-8', { fatal: true })` and calls `done(err)` on failure. The default JSON parser replaces invalid bytes.
- **FastAPI / Starlette**: a pydantic model rejects wrong types with 422 (`strict=True` for no coercion). Limit the body in
  middleware that counts `await request.stream()` bytes and answers 413, or at the proxy (`--limit-max-requests` is not a body
  limit). Invalid UTF-8 in `request.json()` raises `UnicodeDecodeError`: catch it and answer 400.
- **Django / DRF**: `DATA_UPLOAD_MAX_MEMORY_SIZE` (default 2.5 MB) answers 400 `RequestDataTooBig`; set it to the documented limit.
  DRF's JSON parser rejects invalid UTF-8 with a `ParseError` (400).
- **Go net/http**: `r.Body = http.MaxBytesReader(w, r.Body, 64<<10)` answers `*http.MaxBytesError`: map it to 413. `encoding/json`
  replaces invalid UTF-8 with U+FFFD: check `utf8.Valid(raw)` on the bytes read before `json.Unmarshal`. Use
  `dec.DisallowUnknownFields()` and typed structs so a number sent for a string is an error.
- **Rails**: wrap params in strong parameters and check types; the JSON parser raises `ActionDispatch::Http::Parameters::ParseError`
  (400). Limit the body at the proxy or with Rack middleware; Rails has no default limit.

## paths: `server-error` on path parameters, `double-slash-mismatch`, `file-served`

- Never feed `req.url` to `new URL(path, base)`: `//x` parses as a host. Use `req.url.split('?')` or the framework's router.
- Wrap `decodeURIComponent` and answer 400 on `URIError`.
- Validate path parameters before the database: `^[0-9]{1,15}$` for integer ids (a 30-digit id overflows `integer` in Postgres: 22003),
  a UUID parser for UUID ids (`not-a-uuid` is Postgres 22P02). Both are client errors: 400 or 404, not 500.
- Serve static files from a dedicated directory, never the repository root; deny dotfiles.

## search: `wildcard-unescaped`, `sql-injection`, `server-error` on quotes

Bind the term as a parameter and escape the LIKE wildcards in it. The escape character must be declared where the dialect
does not default to it:

| Database | Query | Escape the term with |
|---|---|---|
| PostgreSQL | `name ILIKE $1` | `term.replace(/[\\%_]/g, '\\$&')`; `\` is the default LIKE escape, `ESCAPE '\'` is also valid |
| MySQL / MariaDB | `name LIKE ?` | same; `\` is already the default escape. Do **not** write `ESCAPE '\'` in a MySQL string literal: the backslash escapes the closing quote. Write `ESCAPE '\\'` (or choose another character with `ESCAPE '!'`) |
| SQLite | `name LIKE ? ESCAPE '\'` | same escape; SQLite has no default escape character, so `ESCAPE` is required |
| SQL Server | `name LIKE @p ESCAPE '\'` | escape `[` too |

A quote answered with 5xx is either string-built SQL (fix: parameters) or a driver rejecting the literal (`to_tsquery` with
a bare quote: use `plainto_tsquery` or `websearch_to_tsquery`). Confirm which before calling it an injection.

## parser: `parser-accepted`, `parser-no-common-headers`

These answers come from the HTTP parser, before any middleware.

- **Node `http`**: handle `server.on('clientError', (err, socket) => ...)` and write the status line plus the common headers
  yourself (`HPE_HEADER_OVERFLOW` is 431). Do not raise `maxHeaderSize` to make the probe pass; if the limit is higher by design,
  set `maxHeaderBytes` in the config.
- **Express / Fastify**: Fastify has `clientErrorHandler`; Express uses the Node hook on the `http.Server` it wraps.
- **uvicorn / gunicorn (FastAPI, Django)**: the server answers parser errors itself. Put the headers in the proxy in front
  (nginx `error_page` with `add_header ... always`), then pass `--raw-exempt "nginx answers parser errors"`.
- **Go net/http**: there is no parser-error hook; the standard server answers `400 Bad Request` with no custom headers. Set
  the headers in the proxy that fronts it, or wrap the listener, and use `--raw-exempt`.
- **Rails (Puma)**: Puma answers parser errors itself; add the headers at the proxy.
- `Content-Length` together with `Transfer-Encoding` must be refused (request smuggling): keep the server's strict parsing on.

## resources: `no-body-limit`, `read-before-reject`

- Check `Content-Type` before reading the body (415 at the first bytes).
- A byte limit in the body reader: answer 413 at the limit, then close with a lingering close: keep reading and discard the rest of
  the body up to a cap. An immediate destroy resets the socket and the client loses the 413, notably with large bodies. In Node
  (all versions) a response to a request sent with `Connection: close` (any `agent: false` client, curl `-H 'Connection: close'`,
  HTTP/1.0) destroys the socket as soon as the response finishes, whatever the handler still reads, so consuming the body is not
  enough: write the 413 with its `Content-Length`, keep draining, and call `res.end()` on the request's `close`. Express and
  Fastify answering 413 from their body parser do not do this: against such a client the 413 can be lost to a reset (EPIPE
  / ECONNRESET), which is a limitation of the client's view, not a missing limit. Plus server timeouts: Node `server.requestTimeout`,
  `server.headersTimeout`; Go `ReadHeaderTimeout`, `ReadTimeout`; uvicorn `--timeout-keep-alive` and a proxy `client_body_timeout`;
  Puma `first_data_timeout`.

## concurrency: `duplicates-stored`, `server-error` on the race

A `UNIQUE` constraint in the database, and map its violation to 409: Postgres `23505`, MySQL `1062`, SQLite
`SQLITE_CONSTRAINT_UNIQUE`; check-then-insert in the app is not enough. For a create that is idempotent by design
(`ON CONFLICT DO NOTHING` answering 200 with the same item) set `idempotentCreate: true` for the route.

## faults: `process-died`, `fault-not-reported`, `stack-leak`, `server-error`

- Await every database call inside the handler's error boundary; no fire-and-forget writes. A global `unhandledRejection` logger
  is a backstop, not the fix.
- Answer a fixed body (`{"error":"internal"}`) and log the error server-side: no stack, no driver message, no SQLSTATE.
- Map "database unavailable" (pool timeout, lock, connection refused) to 503 with `Retry-After`.

## auth and csrf: `unauthenticated-access`, `idor`, `csrf`

- Deny by default: authentication middleware on the router, then opt routes out (and declare them `public` in the config).
- Scope every query by owner: `WHERE id = ? AND owner = ?`, and answer 404 (not 403) for objects of another user.
- CSRF with cookie authentication: check `Origin` (and `Sec-Fetch-Site`) against the app's own origin; `SameSite` alone does not
  cover same-site pages on another port. Django `CsrfViewMiddleware`, Rails `protect_from_forgery` (answers 422 or 403: both
  count as a refusal), Express `csurf` replacements or a custom Origin check, Go `http.CrossOriginProtection` (1.25+).
- A 302 to the login page for an unauthenticated request is a refusal.

## origin and host: `foreign-origin-accepted`, `ambient-credentials`, `foreign-host-accepted`

- `foreign-origin-accepted`: the same Origin check as for CSRF, applied to every route, whatever the credentials: refuse a
  request whose `Origin` is present and is not the app's own (`Sec-Fetch-Site: cross-site` or `same-site` too).
- `ambient-credentials`: an API declared free of ambient credentials sets no cookie (keep sessions in a bearer token) and
  never asks `WWW-Authenticate: Basic`, which makes the browser resend the credentials on its own.
- `foreign-host-accepted`: list the hosts the app serves and answer 421 (or 400) to any other: Django `ALLOWED_HOSTS`, Rails
  `config.hosts`, ASP.NET `AllowedHosts`, a `server_name` default that returns 444 in nginx. It blocks DNS rebinding.

## contract: `undocumented-status`

Either the contract is missing a status the app really answers (add it, with its body), or the app answers a status it
should not (usually a 500 or a 400 where the contract says 422): fix the app.

## durability: `not-durable`

Commit before answering; no in-memory store; migrations run on start.
