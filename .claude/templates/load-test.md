# Load test: plan and report

Saved as `specs/<card>/load-test.md`. A full load test applies to a release, to a card that changes a hot path
(the File map line says `hot-path`) or to a card with a volume requirement (criterion O22); R1 stays as the
per-card smoke. The plan is written before the run, the report after, and the report states what was measured
and what was not. Rules: `reference/performance.md` (LOAD-*, PERF-*).

## Plan

**Type and question.** One of load, stress, spike, soak, and the question it answers in one sentence. A smoke
is not a load test.

**Objective.** A number and its origin for each: latency percentile (p95 or p99) at a rate, maximum error
rate, throughput, data volume. The origin is the SLO, the card or an `ASM-NN`.

| Metric | Threshold | Origin |
|---|---|---|

**Model.** Open (arrival rate) or closed (fixed users), and why that is how real traffic arrives. Public
traffic is open: the latency is measured from each request's scheduled instant (no coordinated omission).

**Scenario and mix.** Operations, their proportions, the think time, and how the input varies (ids, filters,
users from a file or random over the seed), so that one hot row is not measured.

**Data.** Volume and distribution of the database before measuring (and at 10x if growth is evaluated), the
seed versioned with a fixed seed.

**Dependencies.** One line per external dependency: real, or simulated with realistic latency (p50 and p99
measured from the third party). Never an instant mock without saying so.

**Environment.** What runs where. The generator runs on a machine other than the measured one; if it cannot,
say so here: the absolute gate is then `could not run` and the numbers are reported as *measured locally*.

**Gate.** The command that fails when a threshold is not met (k6 `thresholds`, autocannon with a check and
`process.exit(1)`, Gatling assertions, Locust or NBomber equivalent), run through `node .claude/tools/once.mjs`.

**Stages.** Ramp-up, steady state with its duration, ramp-down; the warm-up discarded.

## Report

| Item | Value |
|---|---|
| Date, commit, version | |
| Machine of the system and of the generator | |
| Rows in the main tables | |
| Rate achieved vs rate planned | |
| p50 / p95 / p99 of successes and of errors | |
| Error rate | |
| Throughput | |
| Resources at the end (CPU, memory, pool, queue depth) | |
| Thresholds | passed / failed, each one |

**Reading.** What the numbers mean against the objective, the first bottleneck seen, and what to do about it.

**Limits of the measurement.** What was simulated, what differed from production, what was not measured.
Anything that did not run is declared `could not run`, never `passed`.
