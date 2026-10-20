# Module observability · what it adds to the steps

Read the section of the step you are on, only while `observability` is on in `.claude/kit.json`. It is
about a process that stays alive: it serves routes, listens on a port, consumes a queue or runs on a
schedule. Its criteria: O6, O17 to O21; its items: R8, R9 and Q15 of
`.claude/reference/validate-mechanical.md`. The rules are in `.claude/reference/observability.md`,
read by section.

## Step 5 · The plan

What fails in the new feature has to be visible (O6): the plan names the metric or the trace, the
log line and, if it pages someone, the alert with its `runbook_url`. A new endpoint or integration
without a metric or a trace in the diff is reported at the close, unless the plan says
`- Observability: unchanged — <why>` (O19). The SLOs live in `docs/technical/system-design.md` and
agree with the budget of O10 (O20).

## Step 6 · Implementing

Every request carries a correlation id that reaches the calls it makes and the jobs it starts, and
appears in every log line (O17). `/health` and `/ready` exist (O18). RED per endpoint and USE for the
pool and the queues, with OpenTelemetry (O19). What an on-call person needs to understand a failure is
in the log: the error reference id the user sees appears in it (O21).

## Step 8 · Verifying

R8: `/health` answers 200 and `/ready` answers 200 with the dependencies up and 503 with the database
down. R9: JSON log lines with level, the id propagated to an external call and to a job, no sensitive
data, a span exported. Q15: the alerts as code are valid and each links to a section that exists.
