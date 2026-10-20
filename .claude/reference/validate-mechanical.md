# The mechanical items of `/validate`

Nobody reads this in a normal card: `node .claude/tools/verify.mjs` runs the commands of these
items —the ones the plan wrote under `## Verification`— in parallel, and returns an action for each
one that fails. It is opened when `verify.mjs` returns an action about one of them and the command
or what it must give has to be understood.

**The command of each item is in the stack profile**, `.claude/stacks/<stack>.md`; the table says
which tool or profile row answers it and what *passing* means. The four states, and `not
applicable` only when the requirement says the feature does not exist, are those of
`commands/validate.md`. **An item that belongs to a module** (`items` in `.claude/modules.json`) runs
while the module is on; the plan's `## Verification` carries it only then.

## Pause 1 · The suite

| Item | Command | Passing means |
|---|---|---|
| **S1** | the profile's default command, through `once.mjs suite` | it runs **everything** that counts: types, unit tests and the screen suite |
| **S2** | the profile's scenario filter by `@<ID>`, through `once.mjs scenarios` | this card's scenarios pass |
| **S3** | the same run as S1 | the **whole** suite passes: the S2 filter excludes exactly the old scenario that this card broke |
| **S4** | the scenario filter, piping the output to a count of *not found*, *timeout* and *more than one element* | **0** failures of that kind. If not 0: does the element exist and the selector is wrong, or does it lack an accessible name? The latter is fixed **in the product**. The former **is not touched**: the test is frozen; report it with file, line and minimal fix, and follow the refreeze of step 6 |
| **S5** | the plan's `## Verification` | if the whole suite does not fit per card: gate by area now and full sweep before merging. **Never half reported as all** |
| **S6** | clean clone, install and start (profile) | it works **with no step that is not written down** |

## Pause 2 · What the suite does not see even when green

| Item | Command | Passing means |
|---|---|---|
| **T1** | `mutate.mjs <file>` for **each production file in the diff**, through `once.mjs`; `required.mjs` asks for it | mutation over the **domain** —the logic, not the view: a CSS value that no unit test sees is noise—: each surviving mutant is killed with a new test or declared **equivalent, with the reason**. Coverage says what was executed; this says what was verified |
| **T3** | the profile's import comparison between the seed and its test | empty: the seed's test **does not import** what the seed uses to compute |

## Pause 3 · The code

| Item | Command | Passing means |
|---|---|---|
| **C2** | the profile's grep over the diff | each compiler or linter suppression, and each empty `catch`, is removed or carries a line saying why |
| **C5** | the profile's check of declared tools | no tool declared in the project goes unrun in S1 |
| **C6** | the profile's count of uses per exported symbol | no public symbol unused outside its file. **Fewer lines is not the goal; fewer lines that do nothing, yes** |
| **C8** | the layers' import test, in the default suite | the direction of dependencies between layers is **asserted by a test that exists and passes**; also that a module is imported only through its public index, that each table is touched only by its owner module (the “table → owner module” of `system-design.md`), and that domain and application import no package outside the declared allow-list |
| **C9** | the profile's duplication measure over the production code | the percentage is measured; a duplicated block in the diff is merged or carries why |
| **C10** | the profile's cycle detector over the source | no cycles between modules |
| **C11** | the profile's error-handling rules over the diff | no `catch` that only logs, no promise left unhandled, the cause chain kept (an empty `catch` stays in C2) |
| **C12** | the profile's detector, informative | interfaces with at most one implementation and no fake in tests are listed; each one is justified or the interface is removed (`reference/code-patterns.md`) |
| **C13** | the profile's detector, informative | abstract classes with at most one subclass are listed |
| **C14** | the profile's detector, informative | methods that only forward to the same-named method of a collaborator are listed |
| **C15** | the profile's detector, informative | impurity in the domain (clock, randomness, environment) is listed |
| **C16** | the profile's detector, informative | class names that announce a pattern the card did not need are listed: an alert, not a verdict |
| **C17** | `git diff -U0 <card start> -- <tests folder>` read by the profile's weakened-test detector (D18 of `reference/testing.md`) | the diff removes no assertion, adds no `.skip`/`.only`, no weak matcher (`toBeDefined`, `toBeTruthy`), no regenerated snapshot and deletes no test file; the by-command complement of the hook that freezes tests |
| **C18** | the suite a second time with `TZ=America/St_Johns` (an offset of half an hour, with daylight saving) and `LANG=tr_TR.UTF-8` (the Turkish `i`), through `once.mjs` | it passes the same as the first run: nothing depends on the zone or the locale of the machine (I26). A dotted `I` in Turkish and a day moved by a zone are the two bugs it finds; a card with no dates, times, money or text comparisons answers it `not applicable` |


C12 to C16 do not block: the inspector reads their output and answers D4, D6, D12 or D15. Q17 and Q18
do not block either. Q19 does: `required.mjs` asks for it whenever the diff has a migration.

## Pause 3b · The analyzers

What SonarQube, Semgrep, CodeQL, Snyk or Codacy look at, with tools that run on the machine and do
not send the code to any service. Everything is measured **over what the card touched**: old code
does not stop this card, and what is wrong outside is an `OUT-NN`.

| Item | Command | Passing means |
|---|---|---|
| **Q1** | the linter with the Sonar rules, through `once.mjs lint`; `required.mjs` asks that every test in the diff went through it | **Sonar's quality rules** over the diff: zero bugs, zero vulnerabilities, zero *code smells* —including the **cognitive complexity** of each function below the rule's threshold |
| **Q2** | the profile's SAST with community rules | zero findings over the diff, or each one with its false-positive reason |
| **Q3** | the profile's coverage with a threshold | **coverage of the new lines**, 80% or more —the *Sonar way* threshold—. It does not replace T1: coverage says what was executed; mutation, what was verified |
| **Q4** | the profile's license check | **licenses** of what the card added —dependencies, and fonts, icons, images or copied fragments— are within the default list of `reference/dependencies.md` or the one the repo overrides in `docs/technical/dependencies.md`; enabling a blocked one is an `AMB-NN` |
| **Q5** | the profile's baseline dynamic scan (DAST) against the running app | zero alerts of medium or high risk, or each one with its reason. **Once per card, at the end, over the final code; never in a fix loop** (it is slow and each lap rerun costs as much as the first). Its findings follow the scope rule of step 8: an alert on what the card did not create or change is an `OUT` or `AMB`, not an action |
| **Q6** | the company's SonarQube, if it has one | the **Sonar way** quality gate passes over the new code: no new issues, all security hotspots reviewed, coverage of 80% or more and duplication of 3% or less. With no server: `not applicable` with that reason —Q1 to Q3 measure the same locally— |
| **Q7** | the profile's migration linter over the card's migrations | no findings over the card's migrations |
| **Q8** | the profile's API-contract linter | the contract is valid and linted |
| **Q9** | the profile's contract test | routes and spec match in both directions and the responses are valid; run alone |
| **Q10** | the profile's strict docs build, link check and diagram render | the docs build in strict mode, every link is valid and every diagram renders |
| **Q11** | regenerate the notices with the profile's command, then `git diff --exit-code THIRD_PARTY_NOTICES.md` | the regenerated notices equal the committed ones |
| **Q12** | the profile's commit-convention check from the card's start | the card's commits follow the convention |
| **Q13** | the profile's pipeline linter | the pipeline is linted, actions are pinned by SHA, `permissions:` is explicit, required checks and migrations are in the pipeline |
| **Q14** | the profile's image and IaC scanners and the Dockerfile linter | the image is scanned, the IaC is scanned and the container does not run as root |
| **Q15** | the profile's alert-rule validator and a script over `runbook_url` | the alerts as code are valid and each one links to a section that exists in the runbook |
| **Q16** | the profile's catalog comparison (I18N-TST-01), through `once.mjs`; the plan's `i18n-keys:` line | every catalog has the keys of the source locale: no missing, no extra, no placeholder different from the source (I31). `required.mjs` asks for the line when the diff touches a catalog, in the fast lane too |
| **Q17** | the profile's literal-string detector over the diff (I18N-STR-01, I18N-ACT-03). Informative | the count of user-visible literals outside a catalog is recorded and does not grow between cards; the inspector answers I27 with it |
| **Q18** | the profile's front-end detectors, FE-DET-01 to FE-DET-22 of `reference/performance.md` section 5, over the front-end files of the diff. Informative | the matches are listed and each one is fixed or justified in the card; the inspector answers O15, I25 and D13 with them. A detector points, the measurement decides (the lab test of the plan's `vitals:` line) |
| **Q19** | the profile's upgrade from main with data, through `once.mjs` under the name `migrate-upgrade` (the plan's Verification line `migrate-upgrade: <command>`); module data | the new migrations apply, from the merge-base with main, on a database seeded with representative data (DB-MIG-15) and the suite passes; `required.mjs` asks for its log when the diff has a migration, together with what git alone shows: no migration of main edited, renamed or deleted (DB-MIG-12), and the new ones after main's last, with one head and no repeated sequence (DB-MIG-14) |

## Pause 4 · Security, against the running app

| Item | Command | Passing means |
|---|---|---|
| **G2** | `attack.mjs` over the routes the card adds or changes —the rest of the server is an `OUT`— | what ASVS does not ask for and the method does: timeouts **tested** with a slow client; a **declared** huge body is rejected before reading it; a foreign `Host` is rejected; a request **that changes state** from another origin **or without origin headers** gives 403 —a read does not: rejecting a `GET` without `Sec-Fetch-Site` leaves out browsers that do not send it—; the same token **twice and three at once** creates a single record. **A route that requires JSON** is attacked with JSON bodies (`attack.mjs --json`; it also switches by itself when the form gets a 415): a 415 is not a defense. **An output with personal data** —an export, a download— rejects the request that arrives marked as from another site (`Sec-Fetch-Site: cross-site`), is not stored in caches (`no-store`) and carries CSP |
| **G3** | the profile's SBOM and audit | **generated inventory** (SBOM), **audited** against known vulnerabilities, and each dependency **exists in the registry and is needed** —models invent packages |
| **G4** | the profile's secret search over the code and the history | no secret in the code, in a URL or in the git history |
| **G9** | the profile's outdated-packages report | the report is produced; what the card added or changed is on the latest major; what is old and out of policy is an `OUT` |

## Pause 5 · Accessibility — if the diff touches a screen

Playwright with axe, one view per test, at 1280 and 390 px.

| Item | Command | Passing means |
|---|---|---|
| **A1** | axe per view | automatic analysis per view; the severities that are excluded are **listed with their reason** |
| **A2** | keyboard walkthrough in the browser | it reaches the content and each control; the skip link works |
| **A3** | a test of its own per required field | each required field announces it: the automatic analysis does not flag it if the field has a label |
| **A4** | contrast computed over the declared colors | every pair meets its WCAG 2.2 AA ratio |
| **A5** | the suite with forced colors emulated | with the system's high-contrast mode, no distinction that depended on background or shadow disappears |
| **A6** | scripted checks: a 320 px viewport, the WCAG 1.4.12 text-spacing CSS, `getBoundingClientRect` | **visible focus, reflow at 320 px, text spacing, target size**: the criteria that automatic analysis does not cover and can be automated anyway |

## Pause 6 · Endurance, against the running app

R1, R4 and R10 run alone at the end (`verify.mjs` runs the commands named `p95`, `budget`, `vitals` or `load`
after everything else, one at a time): with other suites running, the number measures the machine and not the app.

| Item | Command | Passing means |
|---|---|---|
| **R1** | the profile's p95 script, run **alone** at the end | **performance as a smoke**: each main screen, with the data volume the card asked for, requested many times — the 95th percentile of response time, measured, reported and under the budget of O10 |
| **R2** | the profile's corrupt-data and cut-write probes | **reliability**: with the data store corrupted, the app does not start halfway nor overwrite the file —it says so and stops—. A record with a null, missing or odd-character field does not blow up any screen or output that shows it. If generating an output fails, the response is a clear error and the server keeps running. A write cut off halfway does not leave broken data |
| **R3** | the profile's port listing during the run | **coexistence**: it listens only on the port it declares, and does not write outside its folder |
| **R4** | the profile's bundle and Web Vitals measure, run alone | initial JS per route and LCP, INP and CLS are under the budget, in a production build |
| **R5** | the profile's tests against the real engine | EXPLAIN without full scans on growing tables, query count per request, types, foreign keys and privileges of `reference/database.md` (module data) |
| **R6** | backup, restore and a validation query | the restore finishes within the RTO; only if the card adds or changes a store |
| **R7** | the profile's version probe | the version the app answers is the manifest's |
| **R8** | the profile's probe of `/health` and `/ready` | `/health` gives 200; `/ready` gives 200 with the dependencies up and 503 with the database down |
| **R9** | the profile's probe of logs and traces | JSON log lines with level; the correlation id propagated to a simulated external call and to a job; the sensitive data sent does not appear; a span is exported; a provoked error shows a reference id that appears in the logs |
| **R10** | the profile's load test with thresholds as the gate, run alone | the full load test passes its thresholds; only when O22 applies |
| **R11** | the pipeline's smoke against staging and the runbook's rollback | the post-deploy smoke and the rollback work in staging; only when the card changes the deployment |
