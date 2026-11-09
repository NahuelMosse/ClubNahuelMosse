# Infrastructure cost · ClubNahuelMosse

Describes the `kit-3` branch. Cost model of the API and its database. Today everything runs on the Render `free` plans and costs USD 0 per month; the model
says how much it would cost to sustain the app in production with the smallest paid plans and what would happen with ten times the
volume. The current architecture is in `docs/technical/system-design.md` (`## Infrastructure`); the hosting, in
`docs/adr/0002-hosting-on-render.md`. It is updated in every card that touches the infrastructure.

The Render prices come from https://render.com/pricing.md, consulted on 2026-10-20. What that page does not say, or what
was not consulted, is marked `not verified`.

## Volume assumptions

None of this is measured: the app was not deployed on Render (`docs/technical/system-design.md`, `## Infrastructure`) and there are no
usage metrics. They are assumptions of this card (REV-07-ASM-01), and the capacity targets are those of
`## Performance and capacity budget` of the system design.

| Assumption | Today | Growth per month | Source |
|---|---|---|---|
| Active users | no real use: `not verified` | not estimated | REV-07-ASM-01; target of 20 people with a session at the same time (`system-design.md`, capacity budget) |
| Orders (bookings) per day | no real use: `not verified` | not estimated | REV-07-ASM-01 |
| Stored data (GB) | below 1 GB, assumption: the capacity ceiling is 100 000 bookings | not estimated | REV-07-ASM-01; the size on disk was not measured (`not verified`) |
| Outbound traffic (GB per month) | `not verified`: not measured | not estimated | REV-07-ASM-01 |
| Logs, metrics and traces ingested (GB per month) | 0: there is no production observability, only the text log of the API (`system-design.md`, `## Observability`) | not applicable | review, finding 15 |

At 10x, ten times the capacity target is taken: 200 people with a session at the same time and 50 simultaneous requests. With the API's pool
of 15 connections (`system-design.md`, `## Infrastructure`) that volume does not fit in a single instance without
changing the configuration: it is an estimate, not a measurement.

## Cost per component

| Component | Provider | Plan | Public price | URL | Date checked | Cost today | Cost at 10x |
|---|---|---|---|---|---|---|---|
| Compute: API web service | Render | `free` (`render.yaml:7`) | free: USD 0. Alternatives: `0.5c-512mb` USD 7/month; `1c-2g` USD 25/month | https://render.com/pricing.md | checked: 2026-10-20 | USD 0 | USD 25/month (`1c-2g`), assumption: the small instance is not enough for 200 people; not measured |
| Database: managed Postgres | Render | `free` (`render.yaml:47`) | free: USD 0 and expires after 30 days with 14 of grace. Alternatives: `0.1c-256mb` USD 6/month; `0.5c-1g` USD 19/month | https://render.com/pricing.md | checked: 2026-10-20 | USD 0 | USD 19/month (`0.5c-1g`) |
| Storage and backups | Render | database storage | USD 0.30 per GB per month, 1 GB included. Logical backups on paid instances and point-in-time recovery of 3 days (Hobby) or 7 (Pro). The page does not say whether the free database has backups | https://render.com/pricing.md | checked: 2026-10-20 | USD 0: the free database has no backups (review, finding 4) | USD 0 if the database stays below 1 GB (assumption); USD 0.30 for each extra GB |
| Network and CDN | Render | bandwidth included in the plan | `not verified`: the price of outbound traffic was not read | https://render.com/pricing.md | checked: 2026-10-20 | USD 0 | `not verified` |
| Observability: ingest and retention of logs, metrics and traces | none | there is no production observability | not applicable | not applicable | checked: 2026-10-20 | USD 0 | `not verified`: no provider chosen; REV-02 decides it |
| Third-party services (mail, push) | Firebase (Authentication and Cloud Messaging) and an SMTP server | plans of the Firebase account and of the mail account | `not verified`: the prices of Firebase and of the mail provider were not consulted | not consulted | not consulted | `not verified` | `not verified` |

Alternative for the reminder sweep (finding 3 of the review: today it runs inside the web process, which the free
plan puts to sleep): a Render cron at USD 0.00016 per minute, every minute, is 43 200 minutes per month, about USD 6.91 per month.
It is a calculation on the price per minute; the minimum charge per execution is `not verified`. No decision has been made.

## Totals

The totals add only the verified prices: Render web and database. Firebase and mail are left out (`not verified`).

| | Per month | Per year |
|---|---|---|
| Today (free plans) | USD 0 | USD 0 |
| Production with the smallest paid plans (`0.5c-512mb` USD 7 plus `0.1c-256mb` USD 6) | USD 13 | USD 156 |
| At 10x (`1c-2g` USD 25 plus `0.5c-1g` USD 19) | USD 44 | USD 528 |

## What breaks first

What the free plan gives runs out before the budget does: the free database expires after 30 days and is deleted 14 days
later, with no backups or data rollback (review, finding 4), and the service goes to sleep after 15 minutes without traffic
(`apps/api/README.md`, "Free plan limits"). To operate for real the database has to move to a paid plan, USD 6 per month
at least, and the web service to one that does not sleep, USD 7 per month at least. With ten times the volume the fastest-growing
item is the database (USD 19 per month and USD 0.30 per GB), and the limit reached first is the pool of 15 connections per
instance, not the price.
