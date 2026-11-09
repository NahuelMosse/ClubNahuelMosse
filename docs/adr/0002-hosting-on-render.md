# ADR-0002: Render for the API and the database in the cloud

## Status

`accepted` · 2026-10-03 · NahuelMosse (repo author), when resolving RNF-01-AMB-05 (commit eb1041f); `render.yaml` came in with 5ab2343 the
same day.

## Problem and requirement

The assignment requires the REST API and the database to be available in the cloud and names Render as an example. Scenario
RNF-01-H06-01 (API and database in the cloud) asks for it. The constraint is the budget: the author has no planned monthly
spend for the demonstration.

## Alternatives

### Alternative A — Render: Python web service and managed Postgres, with a `render.yaml`

| Axis | Answer |
|---|---|
| Meets the requirement | yes: the `render.yaml` Blueprint defines the API and the database; the real deployment was not made and scenario RNF-01-H06-01 is skipped without `API_URL_NUBE` (review, "Nominal coverage only") |
| Deployment ease | one Blueprint and the `sync: false` variables; later deployments go out by themselves with each commit of the branch (`apps/api/README.md`, "Deploy on Render") |
| Monthly infra cost | today USD 0 with `free` web and database; with a paid plan, web USD 7 and Postgres USD 6 per month at least, according to https://render.com/pricing.md consulted on 2026-10-20 (`docs/technical/infra-cost.md`) |
| Cost to operate | on the free plan the service sleeps after 15 minutes, the reminder sweep stops, the database has no backups and expires after 30 days (findings 3 and 4); `preDeployCommand` does not exist, so the migrations run in the build (`render.yaml:9-11`) |
| Corrective maintenance cost | the author has not used it in production yet; the configuration is reproduced from the repo; the documentation and support are Render's (`not verified`) |
| Lock-in and exit | low: the API is a `uvicorn` process with `DATABASE_URL` and the database is standard Postgres; migrating is dump and restore plus another host, but there are no backups today to try it with |

### Alternative B — Railway, Fly.io or a separate free database (Neon or Supabase) with the API on another service

| Axis | Answer |
|---|---|
| Meets the requirement | yes in general; the assignment mentions Render as an example, not as an obligation |
| Deployment ease | several services, or an own container with a Dockerfile that the repo does not have |
| Monthly infra cost | according to question RNF-01-AMB-05: Railway without a permanent free plan and from about USD 5 per month; Fly.io about USD 5 to 15 per month; the prices were not consulted again (`not verified`) |
| Cost to operate | with the database separate from the API, two accounts and two dashboards to look after |
| Corrective maintenance cost | the author does not know them (`not verified`) |
| Lock-in and exit | similar to A as long as the database is standard Postgres |

## Decision and why

Alternative A was chosen: it is the example in the assignment, it costs nothing for the demonstration and a single Blueprint describes the
API and the database. The cost accepted is that the free plan puts the service to sleep, that reminders do not go out with the service asleep
and that the database has no backups and expires after 30 days. It is reviewed as soon as a real installation for the club is wanted: the
move to paid plans for web and database, or to a cron for the sweep, stays a decision for a person (`docs/technical/infra-cost.md`
and `docs/technical/runbook.md`).
