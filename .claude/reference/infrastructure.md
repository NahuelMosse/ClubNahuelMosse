# Infrastructure and cost: rules a card can meet and a reviewer can check

**When it is read:** when the card adds or changes a piece of infrastructure (hosting, a
database, a queue, a cache, a managed service, a region, a plan) or introduces a technology; and in the
first card of a repo, which chooses the stack and the hosting. **How:** only the sections the card
touches, with `Read` and a line range of the heading; never whole. `card.md` names the rule IDs that
apply, and the `builder` receives those IDs and their ranges. The price search goes to a `scout`
with web access; the decision is the main thread's. Deployment rules (DPL-*) are in
`reference/ci-cd.md` (module ci); performance and load rules in `reference/performance.md`. **Providers are examples
of a price or a mechanism, never a recommendation:** AWS, Azure, GCP, Fly, Render, Railway, Vercel,
Hetzner or DigitalOcean appear as options. **[NV] marks guidance not verified**: a hypothesis, never the
only evidence of a `meets`; **[kit convention]** marks a threshold of the kit that does not come from a
source. The templates are `templates/adr.md` (the stack ADR on six axes), `templates/infra-cost.md` (the
cost model) and `templates/system-design.md` (the Infrastructure section). How each rule is checked: `J`
judgment with written evidence, `C` a command that exits 0 or not, `T` an automated test. Source numbers
`Bn` are in Sources. None of the example commands was run.

## Rules that are criteria

| Rule | Criterion |
|---|---|
| INF-01, INF-02, INF-03, INF-04, INF-09, INF-10, INF-11, INF-12 | D14 |
| INF-07 | D15 |
| INF-05 | O1 |
| INF-06 | O2 |
| INF-08 | O14 |
| COST-01, COST-02, COST-03, COST-04, COST-05, COST-06, COST-07, COST-08, COST-09, COST-10 | O13 |

The rules outside this table are judgment or guidance, with no criterion of their own.

## 1. Choosing technology and infrastructure (INF)

**INF-01** — Every stack or hosting choice the card introduces stays in an ADR with the six axes of the ADR template: it meets the requirement, deployment, monthly cost, cost to operate, corrective maintenance, lock-in and exit. · How J · criterion D14 · Check: the ADR exists in `docs/adr/` (or in the plan) and each axis has a value or “does not apply: <reason>”; an empty axis rejects it; `rg -l "## Lock-in" docs/adr/` lists the card's ADR. O8 only forbids changing the deployment without a request · Source B1, B3, B7.

**INF-02** — By default choose what the team already operates; each new technology spends one of about 3 *innovation tokens* and is justified in writing with the requirement the existing one does not meet and how it would be solved without adding anything. · How J · criterion D14 · Check: the ADR lists the new technologies (runtime dependency, service, database, language) and for each: requirement, alternative with what exists, who operates it; node-ts `git diff main -- package.json` shows new runtime dependencies, each named in the ADR or the plan; generic the same with `go.mod`, `pyproject.toml`, `docker-compose.yml`, `*.tf`. D7 covers code, not technology · Source B1.

**INF-03** — Start with a modular monolith deployed as one unit; splitting into services requires the requirement that forces it (measured independent scale, a separate team, failure isolation) written in the ADR. · How J · criterion D14 · Check: count the new deployable units in the diff (Dockerfile, service in compose, function, app in the PaaS): `rg --files -g "Dockerfile*" -g "fly*.toml" -g "render.yaml" -g "serverless.yml"` before and after. D1/D2 cover the internal modularity, not the cut into services · Source B8, B7.

**INF-04** — Choose the hosting model by the table below and leave written why not the other three (PaaS, serverless/FaaS, VPS, IaaS/orchestrated containers). · How J · criterion D14 · Check: the ADR has the row of the chosen model and a line for each discarded one · Source B3, B7, B15.

| Model | Fits when | Cost paid | Signal to leave |
|---|---|---|---|
| **PaaS** (Fly, Render, Railway, Heroku, App Runner/Cloud Run as an app) | A team with no dedication to operation; small or medium traffic; one app and one database | A higher unit price than the VM; platform limits; egress at its own rate | The monthly cost exceeds a person-day of operation per month, or a requirement does not fit the platform |
| **Serverless / FaaS** (Lambda, Cloud Functions, Vercel functions) | Very intermittent load or peaks; event work; scaling to zero has value | Cold start; duration limits; observability and local reproduction harder (it weighs in INF-09); high lock-in in the glue | High sustained use (the cost per invocation exceeds a fixed instance) or a need for long connections |
| **VPS** (Hetzner, DigitalOcean, Linode) | Cost dominant and stable load; the team knows how to run Linux; a fixed bill ceiling | OS patches, backups, TLS, monitoring and failover on you (axis 4); one node is one point of failure | A high-availability requirement that demands several nodes and orchestration |
| **IaaS + orchestrated containers** (managed Kubernetes, ECS) | Several services, a team with a dedicated platform, network or compliance requirements | Maximum cognitive load (B7); fixed costs (control plane, NAT, LB) before the first user | If the team has nobody to operate it, it is not an option: go back to a PaaS |

This table is the study's judgment from B1, B3, B7, B8 and B15 [kit convention], not a table from a source.

**INF-05** — The app starts locally with the same types and major versions of backing services as production (Postgres with Postgres, Redis with Redis), with one command. · How C · criterion O1 · Check: `docker compose up -d && npm run dev` (or the README's command) from a clean clone; the image's major version in compose equals the production one declared in the ADR; node-ts `rg -n "image: postgres:" docker-compose.yml` against the managed service's version; generic Testcontainers with the same image. O1 covers starting, not version parity · Source B5.

**INF-06** — Configuration and secrets come from the environment; the same artifact runs in every environment changing only variables. · How C · criterion O2 · Check: `rg -n "https?://[a-z0-9.-]+\.(com|io|app|dev|net)" src/ --glob "!**/*.test.*"` shows no fixed environment URLs; the build receives no target-environment variables (except the frontend's public ones, listed) · Source B5.

**INF-07** — Map the lock-in: each proprietary service (an API with no open standard) is listed with its portable equivalent and the estimated cost of leaving; prefer standard interfaces (SQL, S3-compatible, OCI, OpenTelemetry, SMTP) when they cost the same. · How J · criterion D15 · Check: the ADR's “Lock-in” table: service · standard or proprietary API · alternative · exit effort (days) · exportable data (format); node-ts `rg -n "from '@vercel/|from '@aws-sdk/|from '@google-cloud/|from '@azure/" src/` and each proprietary import appears in the table and lives behind an own module (adapter) · Source B3, B1.

**INF-08** — All infrastructure that is not a one-click panel of a PaaS is in versioned code (Terraform/OpenTofu, Pulumi, CDK, `fly.toml`, `render.yaml`, compose); nothing is created by hand in the console without recording it. · How C+J · criterion O14 · Check: the ADR's resources appear in repo files; `terraform plan` with no changes (zero *drift*) against production · Source B6 [NV content], B27.

**INF-09** — Estimate the corrective maintenance cost before choosing: how a production bug is reproduced locally, where the logs are and for how long, whether a debugger or a profiler can be run, and how long a rollback takes. · How J · criterion D14 · Check: the ADR answers the four questions with a value; “it cannot” is a valid answer and weighs against · Source B9 (failed deployment recovery time), B22, B5.

**INF-10** — Before choosing, review the decision against the Well-Architected pillars (operations, security, reliability, performance, cost, sustainability) and note the trade-off accepted in each. · How J · criterion D14 · Check: six lines in the ADR · Source B3, B4.

**INF-11** — The whole stack fits in the cognitive load of the team that will operate it: count the distinct technologies to operate (languages, databases, queues, platforms) and justify each one that raises the number. · How J · criterion D14 · Check: an inventory in the ADR (“before: 4, after: 5, the new one is X for Y”) · Source B7, B1.

**INF-12** — Classify each technology of the stack as Adopt / Trial / Assess / Caution for *this* team; nothing in Assess reaches production without passing through Trial with a review date. · How J · criterion D14 · Check: an own radar in `docs/` updated by the card that introduces something · Source B2.

## 2. Cost (COST)

**COST-01** — Every card that adds or changes infrastructure delivers a cost model with the template: assumptions with a number, price per component with a URL and a date, total today and at 10x. · How J+C · criterion O13 · Check: `rg -n "checked: 20[0-9]{2}-[0-9]{2}-[0-9]{2}" docs/technical/infra-cost.md` finds the date in every price row; the model is `templates/infra-cost.md` · Source B11, B14.

**COST-02** — No price without a source and a date; re-verify it if it is older than 90 days when deciding [kit convention]. · How C · criterion O13 · Check: price rows with no `http` or no date are rejected. Evidence that a price without a date is a false price: Hetzner re-priced in June 2026 and marked its CX/CAX plans “currently not available” [V the mark; amounts NV from a secondary source]; Render showed no amounts on its page [NV] · Source B15.

**COST-03** — The model includes the hidden costs of the list and declares which are 0 and why: egress, NAT, IPv4, logs and retention, metrics and traces, backups and snapshots, image storage, non-production environments, DNS/certificates, support, tax (VAT). · How J · criterion O13 · Check: each item of the list has a row or “0: <reason>”. In AWS a private subnet with NAT costs about USD 32.85 a month per gateway before processing a byte (USD 0.045/h, Ohio), plus USD 0.045/GB; each public IPv4 about USD 3.65 a month [V] · Source B12, B13, B3.

**COST-04** — Express the cost per business unit (per active user, per order, per 1000 requests) besides the total, and the unit comes from the requirement. · How J · criterion O13 · Check: the model has the row “cost per <unit>” today and at 10x; if at 10x the unit cost rises, say which component scales worse than linearly · Source B11 (Unit Economics), B3.

**COST-05** — Model 10x with the same method: which component changes step (plan, instance size, egress tier) and which architecture stops serving; mark the volume threshold at which another hosting model pays. · How J · criterion O13 · Check: “today” and “10x” columns with each assumption's volume multiplied; a line “change when: …”. R9 asks for a measurable value of the non-functional requirement, not 10x · Source B11 (Forecasting).

**COST-06** — If there is IaC, the PR shows the cost difference (Infracost or equivalent) and an increase above the agreed threshold needs explicit approval. · How C · criterion O13 · Check: CI with `infracost` over the plan; the PR comment is the evidence. Without IaC, the COST-01 table in the plan serves the purpose · Source B16.

**COST-07** — Every paid environment has a budget with alerts on real and forecast spend, and the team knows that an alert does not cut the spend; if the provider offers a hard cap or an automatic action, decide in writing whether it is used. · How J+C · criterion O13 · Check: a capture or export of the budget configuration; IaC of the budget if it exists (`aws_budgets_budget`, `google_billing_budget`). “Setting an alerts-only budget doesn't automatically cap spending”; default alerts at 50 %, 90 % and 100 % (GCP); AWS Budgets data updates up to 3 times a day, 8–12 h between updates, and has *budget actions*; Vercel's on-demand budget defaults to USD 200 with an optional pause at 100 % [V] · Source B17, B18, B15.

**COST-08** — Non-production environments are turned off or scaled to zero out of hours, or it is justified why not. · How J · criterion O13 · Check: a schedule in IaC or the PaaS's `auto_stop`/scale to zero (Fly `auto_stop_machines`, Render/Railway suspended services [NV option names]). Dev/test used about 8 h a workday: turning them off saves about 75 % (40 h against 168 h) [V] · Source B3.

**COST-09** — Tag every resource with owner, environment and product so that spend can be attributed. · How C · criterion O13 · Check: `rg -n "tags\s*=|labels\s*=" infra/` and a mandatory tags policy (Infracost policies flag “tagging violations” [V]) · Source B11, B3.

**COST-10** — Logs and telemetry with defined retention and sampling: default level `info`, no request bodies, retention declared in days. · How J+C · criterion O13 · Check: `rg -n "level:\s*['\"]debug" src/` is empty in the production configuration; retention in IaC or the ADR. O5 asks for logs with a level, not retention or volume; ingest and retention enter the cost model · Source B3, B22.

## Sources

- B1 — Dan McKinley, “Choose Boring Technology”, 2015 — https://mcfunley.com/choose-boring-technology
- B2 — ThoughtWorks Technology Radar, vol. 34 — https://www.thoughtworks.com/radar
- B3 — AWS Well-Architected Framework (six pillars; Cost Optimization design principles) — https://docs.aws.amazon.com/wellarchitected/latest/performance-efficiency-pillar/welcome.html · https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/design-principles.html
- B4 — Azure Well-Architected Framework — https://learn.microsoft.com/en-us/azure/well-architected/
- B5 — Adam Wiggins, The Twelve-Factor App — https://12factor.net/
- B6 — Kief Morris, *Infrastructure as Code*, 3rd ed., O'Reilly, 2025 [NV chapter content] — https://www.oreilly.com/library/view/-/9781098150341/
- B7 — Matthew Skelton and Manuel Pais, *Team Topologies*, key concepts — https://teamtopologies.com/key-concepts
- B8 — Martin Fowler, “MonolithFirst”, 2015 — https://martinfowler.com/bliki/MonolithFirst.html
- B9 — DORA, software delivery metrics — https://dora.dev/guides/dora-metrics/
- B11 — FinOps Foundation, FinOps Framework — https://www.finops.org/framework/
- B12 — AWS VPC pricing — https://aws.amazon.com/vpc/pricing/
- B13 — AWS EC2 on-demand pricing, Data Transfer [NV the first-tier rate] — https://aws.amazon.com/ec2/pricing/on-demand/
- B14 — Pricing calculators: AWS, Azure, Google Cloud — https://calculator.aws/ · https://azure.microsoft.com/pricing/calculator/ · https://cloud.google.com/products/calculator
- B15 — PaaS/VPS prices as of 2026-10-13 — https://docs.fly.io/about/pricing · https://railway.com/pricing · https://vercel.com/pricing · https://www.digitalocean.com/pricing/droplets · https://www.hetzner.com/cloud/ · https://render.com/pricing
- B16 — Infracost — https://www.infracost.io/docs/
- B17 — Google Cloud Billing, “Create, edit, or delete budgets” — https://docs.cloud.google.com/billing/docs/how-to/budgets
- B18 — AWS Budgets — https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html
- B22 — Google SRE Book, ch. 6 “Monitoring Distributed Systems” — https://sre.google/sre-book/monitoring-distributed-systems/
- B27 — AWS, “Disaster Recovery of Workloads on AWS” — https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html

## Not verified

- The inner content of *Accelerate*, *Continuous Delivery*, *Infrastructure as Code* 3rd ed., *Release It!* (index only) and *Systems Performance* (record and the author's pages only).
- Prices: Render (the official page showed no amounts), Hetzner (amounts only in secondary sources; the June 2026 re-pricing confirmed by third parties), AWS egress by tier, the Azure and GCP calculators. Reference prices go stale: re-verify before use (COST-02).
- Infracost: support for OpenTofu/Pulumi, the `breakdown`/`diff` commands and the usage file for consumption resources.
- Exact names of the scale-to-zero options per PaaS (COST-08).
- Google Cloud Architecture Framework was not opened; AWS/Azure were used.
- Thresholds of the kit that do not come from a source: the 90-day validity of a price.
- None of the example commands was run.
