# Observability and supportability: rules a card can meet and a reviewer can check

**When it is read:** when the card adds or changes an endpoint, a job, an external call, a
log, an alert or an error the user sees. **How:** only the sections the card touches, with `Read` and a
line range of the heading; never whole. `card.md` names the rule IDs that apply, and the `builder`
receives those IDs and their ranges. **Vendors and commands are options, not obligations:** the common
vocabulary is OpenTelemetry (OTel) and W3C Trace Context; Prometheus appears only as metric and alert
syntax because its format is the most widespread; the code example is Node + TypeScript with `pino`.
**[NV] marks guidance not verified**: a hypothesis, never the only evidence of a `meets`. **[kit
convention]** marks a design of the kit that does not come from a source: nobody cites it as “it says so
in Google”. How each rule is checked: `J` judgment with written evidence, `C` a command that exits 0 or
not, `T` an automated test, `A` an attack or probe against the running app. Source numbers `Bn` are in
Sources.

Two questions order the document: **can a human understand quickly what is happening** —looking at a
dashboard, receiving an alert or reading a log, without knowing the code—, and **can support answer the
customer** —levels 1, 2 and 3 diagnose with what they see, without reading code and without access to
production—. The operating templates live in `templates/system-design.md` (log fields, alert anatomy,
SLOs) and `templates/runbook.md` (module infra) (runbook per symptom, support view, escalation); they are cited here, not
repeated. The `rg` examples assume code under `src/`, alert rules under `observability/alerts/`,
dashboards under `observability/dashboards/` and runbooks under `docs/runbooks/`: adjust them to the repo.

## Rules that are criteria

| Rule | Criterion |
|---|---|
| OBS-LOG-01, OBS-LOG-02, OBS-LOG-03, OBS-LOG-04, OBS-LOG-05, OBS-LOG-06, OBS-LOG-07, OBS-LOG-12 | O5 |
| OBS-IA-05, OBS-COS-05 | E12 |
| OBS-IA-02 | E6 |
| OBS-IA-03 | E13 |
| OBS-LOG-08, OBS-LOG-09, OBS-LOG-10, OBS-IA-07 | P2 |
| OBS-LOG-13 | S14 |
| OBS-TRZ-01, OBS-TRZ-02, OBS-TRZ-03, OBS-TRZ-07 | O17 |
| OBS-SAL-01, OBS-SAL-02, OBS-SAL-03 | O18 |
| OBS-MED-01, OBS-MED-02, OBS-MED-04, OBS-MED-05, OBS-TRZ-04, OBS-TRZ-10 | O19 |
| OBS-MED-06, OBS-MED-07, OBS-ALR-01, OBS-ALR-04 | O20 |
| OBS-SUP-01, OBS-SUP-02, OBS-SUP-03, OBS-ALR-05, OBS-ALR-06 | O21 |
| OBS-SUP-06, OBS-SUP-07 | W5 |
| OBS-COS-01, OBS-COS-03, OBS-COS-04 | O13 |

The rules outside this table are judgment or guidance, with no criterion of their own.

## 1. What to measure (MED)

**OBS-MED-01** — Every service that answers requests exposes RED: rate, errors and duration distribution, per route of low cardinality. · How C+T · criterion O19 · Check: a test makes a request and checks that the counter and the histogram of the route went up; node-ts `@opentelemetry/sdk-node` with the HTTP/Express instrumentation gives `http.server.request.duration` (the count comes from the histogram); read the in-memory exporter and expect `http.route="/orders/:id"` · Source B1, B20, B29, B23.

**OBS-MED-02** — Measure latency as a histogram and look at percentiles (p50, p95, p99), never the average alone. · How C · criterion O19 · Check: `rg -n "avg\(|mean\(" observability/` over latency rules and panels is empty or justified; node-ts `meter.createHistogram('checkout.duration', { unit: 's', advice: { explicitBucketBoundaries: [0.005,0.01,0.025,0.05,0.1,0.25,0.5,1,2.5,5,10] } })`; PromQL `histogram_quantile(0.99, sum by (le, http_route) (rate(http_server_request_duration_seconds_bucket[5m])))` · Source B1, B3, B10.

**OBS-MED-03** — Separate the latency of successes from that of errors (“a slow error is worse than a fast one”). · How C · criterion none · Check: the latency panels and SLIs filter or group by `error.type`/status; PromQL `… by (le) (rate(…_bucket{http_response_status_code!~"5.."}[5m]))` and another panel for `=~"5.."` · Source B1.

**OBS-MED-04** — For resources (CPU, memory, disk, connection pool, queues) measure USE: utilization, saturation and errors; they are diagnosis signals, not page signals. · How J · criterion O19 · Check: the dashboard has a USE row under the RED one; no `page` alert uses only a USE metric; node-ts `pool.totalCount`, `pool.waitingCount` of `pg.Pool` as observable gauges, event-loop lag with `perf_hooks.monitorEventLoopDelay()`; OTel `db.client.connection.count` with `db.client.connection.state=idle|used` [NV exact name] · Source B19, B20, B29, B30.

**OBS-MED-05** — Instrument the business events that define whether the product works (orders created, payments approved, mails delivered) as metrics, besides the technical ones. · How J+T · criterion O19 · Check: every main use case of the card has a business counter with an outcome (`outcome=ok|rejected|failed`) and a test that checks it; node-ts `ordersCounter.add(1, { outcome: 'ok', 'payment.method': 'card' })` · Source B35, B36.

**OBS-MED-06** — Define each SLI as good events over valid events, measured as close to the user as possible, and no more than five types per service. · How J · criterion O20 · Check: the SLI is written (numerator, denominator, what is excluded, where it is measured) in the repo next to its rule; `availability = requests with status < 500 / valid requests (excludes /health and synthetic traffic)` · Source B11.

**OBS-MED-07** — Every SLO declares objective, window and scope, never 100 %, and has a written error-budget policy with actions and approvers. · How C+J · criterion O20 · Check: `rg -n "objective:|window:" observability/slo/` per service; a `docs/slo/<service>.md` exists with the actions on exhaustion; generic `slo: { sli: availability, objective: 99.9, window: 30d }` (OpenSLO/Sloth-like format [NV]) · Source B3, B11.

**OBS-MED-08** — Prefer monotonic counters to gauges for whatever can be counted. · How C · criterion none · Check: the `*_total` metrics are counters; no “number of errors” is a gauge that resets; node-ts `meter.createCounter('app.payments.failed')`, not an up-down counter for events · Source B4, B10.

**OBS-MED-09** — Use base units and declare them: seconds and bytes, with the unit in the name or the metadata. · How C · criterion none · Check: `rg -n "_ms\b|_millis|Ms'" src/ observability/` is empty for new metrics; node-ts `{ unit: 's' }`; Prometheus `http_request_duration_seconds`, `http_requests_total` · Source B31, B23.

**OBS-MED-10** — Monitor changes: the deployed version, the flags and the active config are visible as a metric or an annotation on every dashboard. · How C · criterion none · Check: a `build_info{version,commit}` metric exists or the OTel resource has `service.version`; the dashboard has deploy annotations; node-ts `new Resource({ 'service.version': process.env.GIT_SHA })` · Source B10.

**OBS-MED-11** — Monitor dependencies with RED from the client side (database, external APIs, queues). · How T · criterion none · Check: a test with the dependency simulated down: the client error counter rises with the provider's `server.address`; OTel `http.client.request.duration`; the instrumentation packages for undici/pg are [NV names] · Source B35, B36.

**OBS-MED-12** — Measure that the monitoring works: alert if a target stops reporting or a batch job did not finish well for longer than expected. · How C · criterion none · Check: a missing-data rule and a “last success” rule per job; PromQL `absent(up{job="checkout"})`, `time() - batch_last_success_timestamp_seconds{job="nightly"} > 26*3600` · Source B4, B31.

## 2. Logs (LOG)

**OBS-LOG-01** — Every log is structured (JSON, one object per line) and goes to stdout; the app does not rotate or ship files. · How C · criterion O5 · Check: `rg -n "createWriteStream|winston\.transports\.File|appendFile.*\.log" src/` is empty; one output line parses with `JSON.parse`; node-ts `pino({ base: {...} })` with the default destination; OTel: export over OTLP or let the collector read stdout · Source B33, B34, B36.

**OBS-LOG-02** — Every log carries the minimum fields of the log schema in `templates/system-design.md` (UTC timestamp, level, service, version, environment, trace/span, tenant/pseudonymized user, event with a stable name, readable message). · How T · criterion O5 · Check: a test captures a line emitted inside a request and validates the schema (Zod/JSON Schema); OTel resource (`service.*`, `deployment.environment.name`) plus LogRecord (`TraceId`, `SpanId`, `SeverityNumber`, `EventName`, `Body`) · Source B22, B23, B27, B28, B36.

**OBS-LOG-03** — Timestamps in UTC, ISO 8601 with an explicit offset (`Z`); never local time nor an epoch with no unit. · How C+T · criterion O5 · Check: `rg -n "toLocaleString|toLocaleTimeString" src/**/log*`; a test checks `/Z$/` on `time`; node-ts `pino({ timestamp: pino.stdTimeFunctions.isoTime })` · Source B27, B28, B36.

**OBS-LOG-04** — Every event has a stable name `domain.object.action` (or OWASP's `<prefix>_<action>` for security) that does not change when the text changes. · How C · criterion O5 · Check: `rg -n "log\.(info|warn|error)\(\s*['\`]" src/` (calls with no object carrying `event`) is empty; a list of events in one file; node-ts `log.info({ event: 'order.payment.declined', orderId }, 'The bank declined the payment')`; security `authn_login_fail` · Source B22, B28.

**OBS-LOG-05** — The message answers who, what, about what and why, in readable language; the variable data goes in fields, not interpolated. · How C+J · criterion O5 · Check: ``rg -n "log\.\w+\(`[^`]*\$\{" src/`` is empty (template strings in the message); bad `log.info(\`Address ${id} removed\`)`, good `log.info({ event:'address.removed', addressId:id, actor:'customer' }, 'Address removed by the customer')` · Source B34, B27, B16.

**OBS-LOG-06** — Use the levels with their defined meaning (the level table in `templates/system-design.md`); ERROR only when there is user impact or an unhandled failure. · How J+C · criterion O5 · Check: review each `log.error` of the diff; `rg -c "log\.error" src/` against the paths that really fail; a rejected input validation is `warn` or `info` (expected), a timeout to the payment provider after retries is `error`; OTel `SeverityNumber` 13 for handled exceptions, 17 for unhandled, 21 for the ones that bring the process down · Source B22, B23, B34.

**OBS-LOG-07** — One wide event per request per service at the end (canonical log line), with all the accumulated context; intermediate logs are the exception. · How T · criterion O5 · Check: a test makes a request and checks exactly one `event:"http.request.completed"` line with method, route, status, duration, tenant, pseudonymized user, query count and `error.code` if there was one; node-ts a middleware creates `res.locals.wide = {}` on entry and emits it on `res.on('finish')` · Source B16, B17, B15.

**OBS-LOG-08** — Never log secrets or authentication data: passwords, tokens, session cookies, `Authorization`, API keys, connection strings, keys, card data. · How C+T · criterion P2 · Check: redaction configured in the logger and a test that logs a request with `Authorization` and checks `[Redacted]`; `gitleaks` or similar over a log sample [NV tool over logs]; node-ts `pino({ redact: { paths: ['req.headers.authorization','req.headers.cookie','*.password','*.token','*.cardNumber'], censor: '[Redacted]' } })`; OTel collector `attributes` processor with `action: delete` [NV syntax] · Source B27, B34, B36, B43.

**OBS-LOG-09** — Do not log PII in clear: email, name, document, phone, address, full IP when not needed. Identify the user with an internal id or a salted hash. · How C+T · criterion P2 · Check: `rg -n "email|dni|phone|fullName" src/**/*log*`; a test checks the fixture's email does not appear in any captured line; node-ts `userRef: hmac(env.LOG_PSEUDO_KEY, user.id).slice(0,16)`; OTel `user.id` only if an opaque internal id, otherwise `user.hash` · Source B27, B34, B36, B23.

**OBS-LOG-10** — Sanitize what comes from the user before logging it (line breaks, control characters) and do not log whole bodies. · How T · criterion P2 · Check: a test sends `"\r\nINFO fake"` in a field and checks it does not break the JSON line; `console.log(req.body)` and `log.info(req.body)` are forbidden · Source B27.

**OBS-LOG-11** — Logging cannot bring the app down or block it: asynchronous or non-blocking logging, and a failure of the destination does not propagate. · How T · criterion none · Check: a test with a destination that throws: the request answers anyway; node-ts `pino.destination({ sync: false })` or a transport; OTel `BatchLogRecordProcessor` in production · Source B27, B36.

**OBS-LOG-12** — The log level changes by configuration, hot or per environment, with no redeploy; production at `info`. · How C · criterion O5 · Check: `rg -n "level:\s*['\"]debug" src/` is empty; the level comes from `LOG_LEVEL`; node-ts `pino({ level: process.env.LOG_LEVEL ?? 'info' })` plus an authenticated admin endpoint that changes it · Source B6, B36.

**OBS-LOG-13** — Record the security events of the OWASP vocabulary (login ok/fail, access denied, privilege changes, high-risk actions) with their stable name. · How T · criterion S14 · Check: a failed-login test expects `event:"authn_login_fail"`; node-ts `log.warn({ event: 'authn_login_fail', userRef }, 'Failed login')` · Source B27, B28.

**OBS-LOG-14** — Classify telemetry by purpose (operation, security, audit, business) and do not mix audit with legal value with sampleable operational logs. · How J · criterion none · Check: the `log.category` field (or a separate stream) exists and the audit does not go through sampling; node-ts `log.child({ 'log.category': 'audit' })` to an unsampled destination · Source B36.

**OBS-LOG-15** — Sample the high-volume success logs, never the error, audit or security ones; traces are sampled keeping errors and slow ones. · How J+T · criterion none · Check: a sampler test: an ERROR always passes, a successful-request INFO passes at the configured rate; OTel tail sampling in the collector with `status_code: ERROR` and `latency` policies [NV policy names] · Source B16, B25, B36.

**OBS-LOG-16** — Define retention by type of data and by obligation: short for debug, longer for aggregates and audit; neither less nor more than required. · How J · criterion O13 · Check: a retention table in the repo (type → days → reason) and the backend config matches; kit convention values: debug 7 d, operational 30 d, aggregated metrics 13 months, audit per regulation · Source B27, B36.

## 3. Traces and correlation (TRZ)

**OBS-TRZ-01** — Propagate context with W3C `traceparent`/`tracestate` on every outgoing and incoming HTTP call; never an own header in parallel. · How T · criterion O17 · Check: an integration test calls a simulated service and checks it received `traceparent` with the same trace-id as the active span; node-ts `NodeSDK` with the default (W3C) propagator plus the HTTP instrumentation, `expect(req.headers.traceparent).toMatch(/^00-[0-9a-f]{32}-[0-9a-f]{16}-0[01]$/)`; OTel `OTEL_PROPAGATORS=tracecontext,baggage` · Source B21, B36.

**OBS-TRZ-02** — If the request enters with no context, generate it at the edge; if it enters with the context of an untrusted third party, start a new trace and link the external one. · How T · criterion O17 · Check: a request-without-header test: the response and the log have a valid, non-zero trace-id; at the public gateway a propagator that drops the incoming `traceparent` and adds a span link [kit convention] · Source B21, B36.

**OBS-TRZ-03** — Propagate the context through queues, jobs and asynchronous events too (in the message), not only through HTTP. · How T · criterion O17 · Check: publish → consume → the consumer's span has the same trace-id or a link; node-ts `propagation.inject(context.active(), msg.headers)` on publish and `propagation.extract(ROOT_CONTEXT, msg.headers)` on consume; OTel `messaging.*` conventions [NV detail] · Source B36.

**OBS-TRZ-04** — Name spans with low cardinality: `{method} {route}` for HTTP, the operation for the database; never the path with ids. · How C+T · criterion O19 · Check: a test checks `span.name === 'GET /orders/:id'`; ``rg -n "startSpan\(`" src/`` is empty; node-ts `tracer.startActiveSpan('payment.authorize', …)`, ids as attributes · Source B23.

**OBS-TRZ-05** — Create manual spans only where they add value: uninstrumented external calls, long business steps, batch work; not for every function. · How J · criterion none · Check: every `startActiveSpan` of the diff answers a concrete diagnostic question; one `invoice.render` span around the PDF generation, not one per helper · Source B23, B15.

**OBS-TRZ-06** — Mark the span status by the rule: 5xx or an unhandled exception is `Error` with `error.type`; a 4xx on the server stays with no error status. · How T · criterion none · Check: a test: 404 gives status `UNSET`, 500 gives `ERROR` with `error.type`; node-ts `span.recordException(err); span.setStatus({ code: SpanStatusCode.ERROR })` in the error handler · Source B23.

**OBS-TRZ-07** — Every log emitted inside a request carries `trace_id` and `span_id`. · How T · criterion O17 · Check: a test emits a log inside a span and checks `trace_id` equals the active span's; node-ts `@opentelemetry/instrumentation-pino` injects `trace_id`, `span_id`, `trace_flags` · Source B22, B26, B36.

**OBS-TRZ-08** — Link metric → trace → log: exemplars on latency histograms and dashboard links to the trace and log search by trace-id. · How J · criterion none · Check: from a spike in the latency panel one reaches a concrete trace and from it its logs in two clicks at most; exemplars [NV detail] · Source B15, B29, B36.

**OBS-TRZ-09** — No PII or secrets in `tracestate`, baggage or span attributes. · How C+T · criterion P2 · Check: `rg -n "baggage|setAttribute\(['\"](user\.email|user\.name|user\.full_name)" src/`; a test inspects the attributes of a login span; node-ts `span.setAttribute('user.hash', userRef)`, never the email; the collector deletes `user.email` and `user.full_name` as a safety net · Source B21, B23.

**OBS-TRZ-10** — Use the attribute names of the semantic conventions and the stable resource attributes (`service.name`, `service.version`, `deployment.environment.name`); do not invent synonyms. · How C · criterion O19 · Check: `rg -n "'(env|environment|app|svc|appVersion)'\s*:" src/**/telemetry*` is empty; `OTEL_SERVICE_NAME`, `OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=prod`; the exact `resourceFromAttributes` signature depends on the SDK version [NV] · Source B23, B24.

## 4. Alerts (ALR)

**OBS-ALR-01** — Alert on symptoms the user sees (SLO, errors, latency at the edge), not on causes (CPU, memory, a machine down). · How C+J · criterion O20 · Check: `rg -n "cpu|memory|node_load|disk" observability/alerts/` over `severity: page` rules is empty or has a written justification; PromQL page on `error_ratio > 14.4 * 0.001`, not `cpu > 90%` · Source B1, B4, B29, B30, B31.

**OBS-ALR-02** — Every alert has an explicit urgency: `page` (act now) or `ticket` (act in days); what needs no action is not an alert, it is a panel. · How C · criterion none · Check: every rule has a `severity` label in `{page,ticket}`; `rg -L "severity:" observability/alerts/*.yaml` is empty · Source B2, B4, B30.

**OBS-ALR-03** — Every page is actionable, needs human judgment and passes the three questions of B1; if the answer is mechanical, it is automated. · How J · criterion none · Check: the PR that adds an alert answers in writing: does it detect something urgent, actionable and visible that nothing else detects? can I ignore it knowing it is benign? does it indicate without doubt that users are affected? · Source B1, B2.

**OBS-ALR-04** — Alert on the SLO with multi-window burn rate: page at 14.4× (1 h and 5 min) and 6× (6 h and 30 min); ticket at 1× (3 d and 6 h), adjusted to the objective. · How C+T · criterion O20 · Check: the rules exist with the short window equal to 1/12 of the long one; `promtool test rules` with synthetic series that cross each threshold [NV flags]; PromQL `(error_ratio:1h > 14.4*0.001) and (error_ratio:5m > 14.4*0.001)` · Source B12.

**OBS-ALR-05** — Every alert follows the alert anatomy of `templates/system-design.md`: what happens, impact, who is affected, since when, first step, link to the runbook and the dashboard, owner. · How C · criterion O21 · Check: a validator walks the rules and requires `summary`, `impact`, `first_step`, `runbook_url`, `dashboard_url`, `owner`; `rg -L "runbook_url" observability/alerts/` is empty · Source B1, B10, B30, B35, B40.

**OBS-ALR-06** — Every alert has a runbook that exists and answers that symptom; a broken or generic link fails CI. · How C · criterion O21 · Check: a script extracts the `runbook_url` of each rule and checks the file `docs/runbooks/<id>.md` exists and has the sections of the runbook template; node-ts `node scripts/check-runbooks.mjs` (reads YAML, `fs.existsSync`) [kit convention] · Source B2, B35, B40.

**OBS-ALR-07** — Require a minimum duration (`for`) before firing and group/inhibit related alerts so that one problem gives one notification. · How C · criterion none · Check: every `page` rule has `for:` of 2m or more or uses multi-window burn rate; grouping config by `service`/`team`; Prometheus `for: 5m`, Alertmanager `group_by: [service, alertname]` · Source B4, B30, B36.

**OBS-ALR-08** — Test the logic of every alert with synthetic series before merging. · How T · criterion none · Check: a test file per rules file, run by CI; Prometheus `promtool test rules alerts.test.yaml` [NV]; generic: a test that feeds the evaluator a fixture · Source B10.

**OBS-ALR-09** — Measure the alert load: pages per shift, percentage of pages with no action, alerts that repeat; prune what leads to no action. · How J · criterion none · Check: a periodic review with the count and the list of alerts deleted or adjusted; at most 2 incidents per 12 h shift, 1 alert : 1 incident · Source B5, B30, B35.

**OBS-ALR-10** — Alerts live as code, reviewed in a PR, next to the service. · How C · criterion none · Check: the rules are in the repo (`observability/alerts/`); no rule created by hand in the UI without a versioned counterpart; Terraform/YAML/Jsonnet of the provider · Source B10, B29.

**OBS-ALR-11** — For low-traffic services, do not page for a single error: synthetic traffic, grouping of services or longer windows. · How J · criterion none · Check: the SLO declares the expected volume and the chosen strategy; a synthetic probe every minute that contributes events to the SLI · Source B12.

**OBS-ALR-12** — When in doubt about severity, treat the incident as the highest level and discuss it in the postmortem. · How J · criterion none · Check: the repo's severity matrix includes the rule · Source B37.

## 5. Dashboards for humans (DSH)

The layout of a service dashboard, from top to bottom (what is above the line fits one screen): **0 header** (purpose, owner, links to runbooks, the support view and traces; variables for environment, region, version) · **1 health** (SLO state, remaining budget of the month, burn rate 1 h and 6 h, active alerts) · **2 RED** (requests/s against a week ago; % errors against the SLO; p50/p95/p99 of successes and of errors with a threshold; deploy annotations) · **3 business** (orders created, payments approved/rejected by reason, in the business's names) · *first-screen line* · **4 per route/operation** (top routes by errors and by p99) · **5 dependencies** (RED per dependency) · **6 resources (USE)** (utilization and saturation: CPU, memory, event loop, connection pool, queue; restarts) · **7 drill-down** (links to logs and traces with the current filters; exemplars).

**OBS-DSH-01** — Every service has a dashboard that follows the layout above: health and SLO at the top, RED with a baseline, business, dependencies, resources, and drill-down downwards. · How C+J · criterion none · Check: the dashboard JSON has the rows with those titles in that order (a script reads the row titles) · Source B1, B29, B32, B36.

**OBS-DSH-02** — The first screen answers “is the service OK now?” without scrolling. · How J · criterion none · Check: a capture at 1920×1080 shows the SLO state, the remaining budget and RED · Source B32, B36.

**OBS-DSH-03** — Each panel answers a question, written as the title or the description (“how many payments fail?”), not the name of the metric. · How C · criterion none · Check: every panel has a non-empty `description`; `rg -n '"title": "[a-z_]+_total"' observability/dashboards/` is empty · Source B29, B32.

**OBS-DSH-04** — Units on every axis and visible thresholds (the SLO line or color) on the panels that have an objective. · How C · criterion none · Check: every time-series panel has a `unit` other than `short`/`none`, and the latency/error ones have `thresholds` · Source B29, B32, B36.

**OBS-DSH-05** — Show the current value against a baseline: the same hour of the previous week, or the objective. · How J · criterion none · Check: the RED panels have an `offset 1w` series or the SLO threshold; PromQL `sum(rate(http_server_request_duration_seconds_count[5m])) offset 1w` · Source B32, B36.

**OBS-DSH-06** — No vanity metrics or decoration: no accumulated historical totals, 3D gauges, counters that only go up; every panel has a possible action. · How J · criterion none · Check: a review with the question “what would I do if this number changes?” · Source B32, B36.

**OBS-DSH-07** — Proportionate precision: percentages with one or two decimals, latencies in ms or s rounded; no 0.99734218. · How C · criterion none · Check: `decimals` defined in stat panels · Source B32.

**OBS-DSH-08** — Color with meaning (green/amber/red for state against the objective) and consistent between dashboards; never decorative color. · How J · criterion none · Check: review · Source B32, B36.

**OBS-DSH-09** — Dashboards as code, generated or versioned, with no direct edit in production; template variables (environment, region, version) instead of copies. · How C · criterion none · Check: the JSON/Jsonnet are in the repo; CI applies them; there are no “Copy of …” dashboards · Source B29, B10.

**OBS-DSH-10** — One view per audience: engineering (RED/USE, traces), operation (SLO, alerts), support (the support view, in the business's language), business (KPIs). · How J · criterion none · Check: the views exist and each names its audience in the description · Source B10, B36.

**OBS-DSH-11** — On the support and business views, names in the business's language (“payments rejected by the bank”), not `payment_gateway_errors_total{code="51"}`. · How J · criterion none · Check: review the titles with someone from support · Source B36 [kit convention wording].

**OBS-DSH-12** — Annotate deploys, config changes and incidents on the charts. · How C · criterion none · Check: the dashboard has a deploy annotation source · Source B10, B29.

**OBS-DSH-13** — Every dashboard has an owner, a purpose and links to runbooks; temporary ones carry a `TMP` prefix and are deleted. · How C · criterion none · Check: a validator: `tags` include `owner:` and the first text panel has the purpose and links · Source B29.

## 6. Support (SUP)

**OBS-SUP-01** — Every error the user sees shows a reference code (see “The error reference id” below) that support searches and finds in the logs. · How T · criterion O21 · Check: an e2e test forces a 500, the UI shows `Ref: XXXX-XXXX`, and searching that ref in the captured logs returns the line with `trace_id`, `error.code` and tenant; node-ts: the error handler generates `ref`, logs it as `error.ref` and answers RFC 9457 with `instance: "urn:ref:7K3F-9QX2"` · Source B42, B34 [kit convention format].

**OBS-SUP-02** — The error to the user says what happened in their language, what they can do and the reference; never stack traces, SQL or internal names. · How T · criterion O21 · Check: a test: the 500 response contains no `at `, `Error:`, `SELECT` or file paths; node-ts `res.status(500).type('application/problem+json').json({ type, title:'We could not process the payment', detail:'Try again in a few minutes. If it persists, contact support with this reference.', instance, ref })` · Source B42, B27.

**OBS-SUP-03** — Each stable error code (`PAY-002`) has an entry in the error catalog with meaning, probable cause, what to tell the customer and when to escalate. · How C · criterion O21 · Check: a script: every `code` used in `src/errors/` appears in `docs/support/errors.md` · Source B35, B40 [kit convention catalog].

**OBS-SUP-04** — Support has a per-customer/per-order view that shows the timeline of business events, errors with their ref and the state of dependencies, with no access to production. · How J+T · criterion none · Check: a test searches by a fixture's order id and gets its events; a review with support; the zones of the view are in `templates/runbook.md` (module infra) · Source B36, B17 [kit convention view].

**OBS-SUP-05** — What support sees is defined: allowed fields per level (N1, N2, N3), PII masked, access audited; nobody on N1/N2 needs a production console. · How J · criterion none · Check: a written access matrix; support queries recorded · Source B27, B36.

**OBS-SUP-06** — Every runbook follows the runbook skeleton of `templates/runbook.md` (module infra): symptoms, impact, confirm, mitigate, verify, escalate, communicate, with owner and review date, validated by someone who did not write it. · How C+J · criterion W5 · Check: a script checks the sections; the runbook PR has a reviewer other than the author · Source B2, B35, B40.

**OBS-SUP-07** — A written escalation matrix: severity × support level → who, through which channel, in how long and which data package is passed. · How J · criterion W5 · Check: `docs/support/escalation.md` exists with the table of `templates/runbook.md` (module infra) · Source B5, B8, B35, B37, B38.

**OBS-SUP-08** — On escalating, the ticket carries the minimum package: error ref or trace-id, tenant, UTC time, what the customer expected, what happened, steps to reproduce. · How J · criterion none · Check: a ticket template with those fields required · Source B6.

**OBS-SUP-09** — Declare an incident if the customer sees it, another team is needed or it is still unresolved after an hour; on declaring, roles and a living document. · How J · criterion none · Check: a written procedure with those criteria · Source B8.

**OBS-SUP-10** — Customer communication with templates per state (Investigating, Identified, Monitoring, Resolved), first message in 5 min or less, updates at least every 20 min the first 2 h, always with the time of the next one, and a closing that says whether there was data loss. · How J · criterion none · Check: templates in `docs/support/statuspage.md` · Source B37, B39.

**OBS-SUP-11** — A blameless postmortem for every incident that meets the triggers defined beforehand, with impact, a timeline backed by data, causes, actions with an owner, and reviewed. · How J · criterion none · Check: a template and a list of postmortems with state `Reviewed` · Source B9, B37.

**OBS-SUP-12** — First stop the bleeding (rollback, divert traffic, disable the feature) and preserve the evidence; the root cause comes afterwards. · How J · criterion none · Check: every runbook has the “Mitigate” section before any deep diagnosis · Source B6, B8.

## 7. Health checks and readiness (SAL)

**OBS-SAL-01** — Separate liveness (the process can advance), readiness (it can take traffic now) and startup (it finished starting). · How T · criterion O18 · Check: tests of the three endpoints with the dependency down: liveness 200, readiness 503; node-ts `GET /livez` is 200 if the event loop answers, `GET /readyz` checks the database pool and required caches, `GET /startupz` after migrations/load · Source B41.

**OBS-SAL-02** — Liveness never checks external dependencies: a database down must not restart every pod. · How C+T · criterion O18 · Check: `rg -n "livez|liveness" -A15 src/` contains no `query(`, `fetch(` or `redis` · Source B41.

**OBS-SAL-03** — Health checks are cheap, with a short timeout, do not expose internal details to the public and do not count in the SLI. · How T · criterion O18 · Check: a test: `/readyz` answers in under 100 ms with the dependency slow (timeout) [kit convention threshold]; the public answer has no versions or hosts · Source B11, B42.

**OBS-SAL-04** — Expose an authenticated internal status endpoint for diagnosis (version, active config, dependency state, a sample of recent requests). · How J · criterion none · Check: an `/internal/status` behind auth exists · Source B6, B10.

**OBS-SAL-05** — Black-box monitoring: a synthetic probe of the critical journey from outside feeds the page; the white box feeds the diagnosis. · How C · criterion none · Check: a synthetic check of the main flow with an alert exists · Source B1, B11.

## 8. Cost and retention (COS)

**OBS-COS-01** — No metric label/attribute of unbounded cardinality: user, order or request ids, email, full URL, error message. · How C+T · criterion O13 · Check: `rg -n "(userId|orderId|requestId|email|url|message)\s*[:,]" src/**/metrics*`; a test emits 3000 distinct values and checks `otel.metric.overflow` does not appear; node-ts `counter.add(1, { route: req.route.path })`, never `{ path: req.originalUrl }` · Source B23, B24, B31.

**OBS-COS-02** — High cardinality yes, but in events and traces (where it helps to slice), not in metrics (where it multiplies series). · How J · criterion none · Check: review: every id useful to support is in the wide event, not in a label · Source B15, B16, B24.

**OBS-COS-03** — Estimate the telemetry volume when designing and review cost against value periodically. · How J · criterion O13 · Check: the card's plan estimates lines per request and new series; the cost model counts ingest and retention · Source B36.

**OBS-COS-04** — Tiered retention: high resolution short, aggregates and downsampling for the long term, cheap archive for audit. · How J · criterion O13 · Check: the retention table (OBS-LOG-16) applied in the backend · Source B10, B36.

**OBS-COS-05** — Do not re-emit the same thing several times: an error is logged once, where it is handled, not in every layer that rethrows it. · How C · criterion E12 · Check: ``rg -n "catch.*\{[^}]*log\.\w+\([^}]*throw" -U src/`` is empty (log-and-rethrow) · Source B24, B23 [kit convention rule].

**OBS-COS-06** — Limit the dashboard refresh to what the data needs. · How C · criterion none · Check: `refresh` of `30s` or more in the JSON · Source B29.

## 9. Typical errors in AI-generated code (IA)

Frequencies are the study's judgment, not a measured figure.

**OBS-IA-01** — No `console.log`/`console.error` in production code: everything goes through the structured logger. · How C · criterion O5 · Check: `rg -n "console\.(log|info|warn|error|debug)\(" src/ --glob '!**/*.test.ts' --glob '!**/*.spec.ts'` is empty; ESLint `no-console: error` [NV config] · Source B33, B34, B36.

**OBS-IA-02** — No swallowed errors: every `catch` rethrows, converts to a domain error with its cause, or logs with level and event; never `catch {}` nor `catch (e) { return null }` with no trace. · How C · criterion E6 · Check: `rg -nU "catch\s*(\([^)]*\))?\s*\{\s*\}" src/`; `rg -nU "catch\s*\([^)]*\)\s*\{\s*return (null|undefined|\[\]|false);?\s*\}" src/`; ESLint `no-empty` [NV config] · Source B1, B27.

**OBS-IA-03** — No floating promises or unhandled rejections; global handlers log as FATAL/ERROR with context and exit cleanly. · How C · criterion E13 · Check: `@typescript-eslint/no-floating-promises` [NV config]; `rg -n "unhandledRejection|uncaughtException" src/` finds the handler · Source B23.

**OBS-IA-04** — No logs without context (`"Error"`, `"Something went wrong"`, `"here"`): every log has an event, correlation ids and the cause. · How C · criterion O5 · Check: `rg -ni "log\.\w+\(\s*['\"](error|failed|something went wrong|here|test)['\"]\s*\)" src/` is empty · Source B34, B36.

**OBS-IA-05** — No `log.error(err.message)`: log the error object (type, message, stack, cause) in the `err` field. · How C · criterion E12 · Check: `rg -n "log\.\w+\([^)]*\.message\)" src/` is empty; node-ts `log.error({ err, event: 'payment.authorize.failed', orderId }, 'Payment authorization failed')` · Source B23.

**OBS-IA-06** — No alerts on CPU, memory or “any error”: the generated alert is on the SLO or a symptom, with the full anatomy. · How C · criterion O20 · Check: as OBS-ALR-01 and OBS-ALR-05 · Source B1, B30.

**OBS-IA-07** — No PII or secrets in logs from logging the whole object (`log.info(user)`, `log.debug(req)`, `log.info({ body })`). · How C · criterion P2 · Check: `rg -n "log\.\w+\(\s*\{?\s*(req|request|user|body|headers|config|process\.env)\s*\}?\s*[,)]" src/` is empty · Source B27, B34.

**OBS-IA-08** — No exploding cardinality: ids, URLs or messages as metric labels. · How C · criterion O13 · Check: as OBS-COS-01 · Source B24, B31.

**OBS-IA-09** — No `debug` left on and no logs inside hot loops. · How C · criterion none · Check: `rg -nU "for\s*\(.*\)\s*\{[^}]*log\.(info|debug)" src/` reviewed; the level comes from `LOG_LEVEL` · Source B36.

**OBS-IA-10** — No invented instrumentation next to the standard one: no home-made `x-request-id` in parallel to `traceparent`, no own names where a semantic convention exists. · How C · criterion O17 · Check: `rg -n "x-request-id|x-correlation-id|uuidv4\(\).*(request|correlation)" src/` is empty or justified (if a third party requires it, it is logged besides the trace-id) · Source B21, B23, B24.

**OBS-IA-11** — No ERROR for expected client errors (400, 404, validation): that is INFO/WARN; an inflated ERROR hides the real ones and fires false alerts. · How T · criterion O5 · Check: a test: a 404 produces no line with `level >= 50` (pino: error = 50) [NV pino numbering] · Source B23, B34.

**OBS-IA-12** — No health check that queries the database in liveness nor one that always answers 200 without looking at anything. · How C+T · criterion O18 · Check: as OBS-SAL-01 and OBS-SAL-02 · Source B41.

## The error reference id

What the user sees: “We could not process the payment. Try again in a few minutes. If it keeps happening, contact support with this reference: **PAY-002 · 7K3F-9QX2**”. [kit convention]

| Part | Format | What for |
|---|---|---|
| Error code | `<DOMAIN>-<NNN>` stable, from the catalog (`PAY-002`) | N1 support knows what to say without searching anything |
| Reference | 8 Crockford Base32 characters (no I, L, O, U) in two groups of 4: `7K3F-9QX2` (40 random bits) | Unique per occurrence; dictated by phone without ambiguity; searched in the logs as `error.ref` |

It is generated in the edge error handler, once per failed request, and logged in the same line as `trace_id`, `error.code`, tenant and `user.hash`. It contains no user data and is not derivable from it (B21). It is not the trace-id (32 hex characters are not dictated); the log joins them. In APIs: RFC 9457 with `instance: "urn:ref:7K3F-9QX2"` and the extensions `code`, `ref` (B42). The support search is bounded by date: 40 bits make collisions within the retention irrelevant, and if one happens, the date and the tenant disambiguate.

```ts
const ALPHABET = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford
export function newErrorRef(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(5)); // 40 bits
  let n = 0n; for (const b of bytes) n = (n << 8n) | BigInt(b);
  let s = ''; for (let i = 0; i < 8; i++) { s = ALPHABET[Number(n & 31n)] + s; n >>= 5n; }
  return `${s.slice(0, 4)}-${s.slice(4)}`;
}
```

## Sources

- B1 — Google SRE Book, ch. 6 “Monitoring Distributed Systems” — https://sre.google/sre-book/monitoring-distributed-systems/
- B2 — SRE Book, ch. 1 “Introduction” — https://sre.google/sre-book/introduction/
- B3 — SRE Book, ch. 4 “Service Level Objectives” — https://sre.google/sre-book/service-level-objectives/
- B4 — SRE Book, ch. 10 “Practical Alerting” — https://sre.google/sre-book/practical-alerting/
- B5 — SRE Book, ch. 11 “Being On-Call” — https://sre.google/sre-book/being-on-call/
- B6 — SRE Book, ch. 12 “Effective Troubleshooting” — https://sre.google/sre-book/effective-troubleshooting/
- B7 — SRE Book, ch. 13 “Emergency Response” — https://sre.google/sre-book/emergency-response/
- B8 — SRE Book, ch. 14 “Managing Incidents” — https://sre.google/sre-book/managing-incidents/
- B9 — SRE Book, ch. 15 “Postmortem Culture” — https://sre.google/sre-book/postmortem-culture/
- B10 — SRE Workbook, “Monitoring” — https://sre.google/workbook/monitoring/
- B11 — SRE Workbook, “Implementing SLOs” — https://sre.google/workbook/implementing-slos/
- B12 — SRE Workbook, “Alerting on SLOs” — https://sre.google/workbook/alerting-on-slos/
- B13 — Rob Ewaschuk, “My Philosophy on Alerting”, 2014 [NV: the document could not be read] — https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q
- B14 — Charity Majors, Liz Fong-Jones and George Miranda, *Observability Engineering*, O'Reilly, 2022 [NV inner content] — https://www.oreilly.com/library/view/observability-engineering/9781492076438/
- B15 — Liz Fong-Jones, “Authors' Cut: Structured Events Are the Basis of Observability”, Honeycomb — https://www.honeycomb.io/blog/structured-events-basis-observability
- B16 — Charity Majors, “Logs vs Structured Events”, 2019 — https://charity.wtf/2019/02/05/logs-vs-structured-events/
- B17 — Brandur Leach, “Fast and flexible observability with canonical log lines”, Stripe, 2019 — https://stripe.com/blog/canonical-log-lines
- B18 — Cindy Sridharan, *Distributed Systems Observability*, O'Reilly, 2018 [NV inner content] — https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/
- B19 — Brendan Gregg, “The USE Method” — https://www.brendangregg.com/usemethod.html
- B20 — Tom Wilkie, “The RED Method: How to Instrument Your Services”, Grafana, 2018 — https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/
- B21 — W3C, *Trace Context*, Recommendation 2021-11-23 — https://www.w3.org/TR/trace-context/
- B22 — OpenTelemetry, “Logs Data Model” — https://opentelemetry.io/docs/specs/otel/logs/data-model/
- B23 — OpenTelemetry Semantic Conventions (service, deployment, user attributes; HTTP spans and metrics; exceptions) — https://opentelemetry.io/docs/specs/semconv/registry/attributes/service/ · https://opentelemetry.io/docs/specs/semconv/http/http-spans/ · https://opentelemetry.io/docs/specs/semconv/http/http-metrics/ · https://opentelemetry.io/docs/specs/semconv/exceptions/exceptions-logs/
- B24 — OpenTelemetry, Metrics SDK and “Supplementary Guidelines” — https://opentelemetry.io/docs/specs/otel/metrics/sdk/ · https://opentelemetry.io/docs/specs/otel/metrics/supplementary-guidelines/
- B25 — OpenTelemetry, “Sampling” — https://opentelemetry.io/docs/concepts/sampling/
- B26 — `@opentelemetry/instrumentation-pino` — https://github.com/open-telemetry/opentelemetry-js-contrib/tree/main/packages/instrumentation-pino
- B27 — OWASP Logging Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- B28 — OWASP Logging Vocabulary Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/Logging_Vocabulary_Cheat_Sheet.html
- B29 — Grafana, “Dashboard best practices” — https://grafana.com/docs/grafana/latest/visualizations/dashboards/build-dashboards/best-practices/
- B30 — Grafana, “Alerting best practices” — https://grafana.com/docs/grafana/latest/alerting/guides/best-practices/
- B31 — Prometheus, “Metric and label naming” and “Alerting” — https://prometheus.io/docs/practices/naming/ · https://prometheus.io/docs/practices/alerting/
- B32 — Stephen Few, “Common Pitfalls in Dashboard Design”, Perceptual Edge, 2006 — https://www.perceptualedge.com/articles/Whitepapers/Common_Pitfalls.pdf
- B33 — The Twelve-Factor App, XI “Logs” — https://12factor.net/logs
- B34 — Heroku Dev Center, “Writing Best Practices For Application Logs” — https://devcenter.heroku.com/articles/writing-best-practices-for-application-logs
- B35 — AWS Well-Architected, Operational Excellence: OPS04-BP02, OPS07-BP03, OPS08-BP04, OPS10-BP02 — https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/ops_observability_application_telemetry.html · https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/ops_ready_to_support_use_runbooks.html
- B36 — Azure Well-Architected, OE:07 “Designing a monitoring system” and “Build a monitoring system” — https://learn.microsoft.com/en-us/azure/well-architected/operational-excellence/observability · https://learn.microsoft.com/en-us/azure/well-architected/design-guides/monitoring
- B37 — PagerDuty Incident Response documentation — https://response.pagerduty.com/
- B38 — Atlassian Incident Management Handbook [NV body] — https://www.atlassian.com/incident-management/handbook
- B39 — Atlassian Statuspage, “Incident communication” [NV full text] — https://www.atlassian.com/incident-management/tutorials/incident-communication
- B40 — GitLab, `gitlab-com/runbooks` (“Runbooks for the stressed on-call”) — https://gitlab.com/gitlab-com/runbooks
- B41 — Kubernetes, “Liveness, Readiness, and Startup Probes” — https://kubernetes.io/docs/concepts/configuration/liveness-readiness-startup-probes/
- B42 — RFC 9457, *Problem Details for HTTP APIs*, 2023 — https://www.rfc-editor.org/rfc/rfc9457.html
- B43 — pino, “Redaction” — https://github.com/pinojs/pino/blob/main/docs/redaction.md

## Not verified

- “My Philosophy on Alerting” (B13): the document gave no text; its ideas are taken from B1, by the same author.
- The inner content of *Observability Engineering* (B14) and *Distributed Systems Observability* (B18): the publisher answered 403; only records, partial indexes and summaries by the author or by third parties.
- The Atlassian Incident Handbook and Statuspage (B38, B39): the pages returned only navigation; the severities and the four states come from search results, and Atlassian's postmortem process and action deadlines are not verified. GitLab's incident handbook redirects to a login; the runbooks repo README (B40) was used.
- No primary source by Charity Majors with the exact term “wide events”; her 2019 post (B16) and the book summary (B15) were used.
- Names of tools and options not opened: `promtool test rules` flags, ESLint rules (`no-console`, `no-empty`, `@typescript-eslint/no-floating-promises`), OTel Collector processor syntax (`attributes`, `tail_sampling`), the instrumentation names for undici/pg, the exact `resourceFromAttributes` signature, `db.client.connection.count`, pino's level numbering, the OpenSLO/Sloth format, the `messaging.*` conventions and exemplars.
- Values marked kit convention (retention per type, the 100 ms readiness threshold, the reference id format, the error catalog, the escalation matrix, the support view) are a design of the study.
- No command or code fragment was run.
