# Infrastructure cost model

Saved as `docs/technical/infra-cost.md`, updated in every card that touches infrastructure (criterion O13;
the plan declares `- Infra cost: unchanged — <why>` when nothing changes). It keeps the numbers; the decision
and its alternatives are in the ADR, the current architecture in `docs/technical/system-design.md`. Prices
come from the provider's public page, searched by a `scout` with web access; the main thread decides.

## Volume assumptions

| Assumption | Today | Growth per month | Source |
|---|---|---|---|
| Active users | | | |
| Orders (or the main unit of work) per day | | | |
| Stored data (GB) | | | |
| Outbound traffic (GB per month) | | | |
| Logs, metrics and traces ingested (GB per month) | | | |

A number without a source is an assumption: label it `ASM-NN` in the card.

## Cost per component

| Component | Provider | Plan | Public price | URL | Date checked | Cost today | Cost at 10x |
|---|---|---|---|---|---|---|---|
| Compute | | | | | checked: YYYY-MM-DD | | |
| Database | | | | | checked: YYYY-MM-DD | | |
| Storage and backups | | | | | checked: YYYY-MM-DD | | |
| Network and CDN | | | | | checked: YYYY-MM-DD | | |
| Observability: ingest and retention of logs, metrics and traces | | | | | checked: YYYY-MM-DD | | |
| Third-party services (mail, payments, search) | | | | | checked: YYYY-MM-DD | | |

Every price row carries its date: a price without a date is not a price.

## Totals

| | Per month | Per year |
|---|---|---|
| Today | | |
| At 10x | | |

## What breaks first

The component whose cost grows fastest with volume, the volume at which it overtakes the rest, and what the
team would do then (a cheaper plan, a cache, a different component).
