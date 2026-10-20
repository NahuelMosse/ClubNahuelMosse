# Profile: Node and TypeScript

The commands for each `/validate` item on this stack. **It is the tested profile**: it came out of
more than twenty measured runs. `$ID` is the card; `$E2E`, the scenarios folder fixed by
`METHOD.md`. A command marked **Untested on this machine** is written from the tool's documentation and
has not run here: the first card that uses it confirms or adjusts it. Every product named is an option,
never an obligation.

**Read only the section of the step you are in** —`Read` with the line range of its heading—: the
whole profile would be re-read on every request of the card.

## At a glance

- `tsconfig.json` with `strict` and `noUncheckedIndexedAccess`; `npm test` = types + unit tests + screen gate (captures outside it);
  the verification commands live once as `verify:*` scripts of `package.json`.
- `node --test` lines run with `--test-concurrency=1`, or 4 (or half the cores) when the tests isolate their own port and database
  and a stable ×3 run (`tools/repeat.mjs`) confirms it. Playwright and axe are development dependencies; browsers install with
  `PLAYWRIGHT_SKIP_BROWSER_GC=1 npx playwright install chromium`. Several tags: `--grep "@A|@B"` with double quotes.
- The plan's `## Verification` lines, one per check, run by `verify.mjs`: `suite: npm test`, `lint: npx eslint <src test e2e>`,
  `mutate <file>: node --test <that file's unit tests>` (production: every production file; mvp: the domain; poc: none),
  `attacks: npm run attacks`, `motion: npm run motion`, `app: node src/main.mjs` (takes `PORT` and `DATA_DIR` from the environment).
- Before freezing the scenarios: `npx tsc --noEmit`; the linter (eslint-plugin-playwright, no loops or conditionals in tests); the
  new scenarios ×3 stable (`npx playwright test --grep "@$ID" --repeat-each=3`, or
  `node .claude/tools/repeat.mjs 3 -- node --test --test-concurrency=1 <files>`); the red run with `--timeout=5000 --retries=0`
  (Node: `timeout 30 node --test --test-timeout=5000 --test-force-exit <files>`), never in the final suite.
- S1 `node .claude/tools/once.mjs suite -- npm test`; S2 `once.mjs scenarios -- npx playwright test --grep "@$ID"`; T1 mutation
  `node .claude/tools/mutate.mjs <file> --since <card-start> --equivalents specs/<card>/equivalents.md -- <unit suite>`, never over the
  browser suite. ZAP: once per card, at the end.

Read the rest only when an item of the plan's bar needs a command not listed here (read just its Pause section, by line range), or the card has a screen (`## Screen: states and motion`).

## Configuration the profile requires

- `tsconfig.json` with `strict` **and `noUncheckedIndexedAccess`** — the second is the one that
  catches `list[i]` and `map.get(k)` treated as if they were always there.
- `npm test` = types + unit tests + screen gate. Captures stay outside the gate.
- **`node --test` lines run with `--test-concurrency=4`** (or half the cores) when the tests isolate their own port and database;
  the condition is a stable ×3 run (`tools/repeat.mjs`) that confirms it, and the plan's `## Verification` declares it. Without that run, `--test-concurrency=1`.
  *Measured: 949 tests went from 10.9 to 7.0 minutes.*
- Playwright and `@axe-core/playwright` as **development dependencies**, never production ones.
- Browsers are installed with `PLAYWRIGHT_SKIP_BROWSER_GC=1 npx playwright install chromium`:
  without the variable, Playwright deletes from the machine's cache the versions this repo does
  not use, and other projects or agents on the same machine may be using them. *Measured:* a run
  deleted somebody else's Chromium version.
- Several tags in one filter: `--grep "@A|@B"` with **double** quotes; cmd.exe, which runs npm scripts and
  `verify.mjs` lines on Windows, takes an unquoted `|` as a pipe. Repeating `--grep` does not add up: only the
  last one counts. *Verified on this machine.*
- The scenarios server's port comes from an environment variable, with a default value: that way
  two runs —the suite and a mutation that uses the scenarios— do not collide.
- The verification commands live once, as `verify:*` scripts of `package.json` (`verify:suite`, `verify:lint`,
  `verify:contract`…); the plan's `## Verification` lines and the pipeline both invoke them.

## The plan's `## Verification` section

What `verify.mjs` runs in parallel. An example for a card with a domain module, a server and a
screen:

```
suite: npm test
lint: npx eslint src test e2e
# production grade: every production file; at mvp only the domain one (src/telefono.mjs), at poc none
mutate src/telefono.mjs: node --test test/telefono.test.mjs
mutate src/app.mjs: node --test test/app.http.test.mjs
attacks: npm run attacks
motion: npm run motion
app: node src/main.mjs
seed: node scripts/seed.mjs
cycles: npx madge --circular --extensions ts,tsx,js,mjs src
contract: npm run verify:contract
docs: npm run verify:docs
budget: npm run verify:budget
vitals: npm run verify:vitals
load: npm run verify:load
```

`npm run attacks` starts the app on a free port, runs `attack.mjs` against the card's routes and
stops it by PID. `npm run motion` does the same with `node .claude/tools/motion-audit.mjs <url>
--only <selectors of what the card added> --cpu 4`, or over `design/components/gallery.html` when
the card changed the set. What uses a browser or starts the app goes one at a time; the rest, in
parallel. The commands named `p95`, `budget`, `vitals` or `load` run alone, after everything else.

`app:` (`node src/main.mjs`, or `npm start`) is not a check: `node .claude/tools/app.mjs up` runs it
with `PORT` and `DATA_DIR` in the environment, so the app must take both from there; the optional
`seed:` loads data once and sees `APP_URL`. The judges of step 8 share that one app. `npm run attacks`
and `npm run motion` may point at `APP_URL` when it is set and start their own app only without it.
`attack.mjs --json` sends the bodies as JSON (it also switches by itself when the form gets a 415).

## Screen: states and motion

If the card touches a screen, the `screen:` line of `## Verification` runs a Playwright spec that
walks every new control and asserts:

- **states**: with `page.mouse.move`, `locator.focus()` and `mouse.down`, that hover, focus and
  press change what the state matrix says (`toHaveCSS`), and that focus is visible
  (`toBeFocused` plus the outline's width and color);
- **motion**: each control's transition is between 1 and 400 ms (`transitionDuration`), and with
  `page.emulateMedia({ reducedMotion: 'reduce' })` no infinite or displacing animation remains
  (`document.getAnimations()`);
- **stability**: cumulative layout shift (`PerformanceObserver` of `layout-shift`) is 0.1 or less
  on load and on scroll; it is the evidence of O15 for CLS;
- **accessibility**: axe with no violations, also with `colorScheme: 'dark'` if the project has a
  dark mode.

Colors and durations written by hand in what the card adds are flagged by `verify.mjs`; with
stylelint, `declaration-property-value-disallowed-list` with `/#[0-9a-f]{3,8}/i` and `/rgb\(/` for
color, and the same for durations, it also stops them in the editor.

**Captures** (`--project=captures`): the strip of each view, full page, at 1280×900 and 390×844, for
whoever looks first; and for the main thread, one capture per state the card changed with
`page.screenshot({ fullPage: false })` and `deviceScaleFactor: 1`. A 1280×900 viewport is about 1.5
thousand tokens; a long full page, ten.

## Before freezing the scenarios (`/scenarios`)

| What | Command | Must give |
|---|---|---|
| test types | `npx tsc --noEmit` (the `tsconfig`/`jsconfig` includes `e2e/`) | 0 errors |
| test linter | **eslint-plugin-playwright** with `playwright/missing-playwright-await` (`includePageLocatorMethods: true`), `playwright/no-useless-await` and `playwright/no-conditional-in-test`, over the scenario files; for unit tests, `no-conditional-in-test` from `eslint-plugin-jest`. **In both**, `no-restricted-syntax` over `ForStatement`, `ForOfStatement`, `ForInStatement`, `WhileStatement` and `CallExpression[callee.property.name='forEach']` inside tests: the conditional rules do not see loops, and two runs let them through | 0 errors. It does not see an `await` on a locator returned from your own function: the `reviewer` checks that |
| expected value | in the spec files' block of the ESLint config, a `no-restricted-syntax` selector `CallExpression[callee.name='expect'] CallExpression[callee.property.name=/^(filter\|map\|reduce\|sort\|find)$/]` with the message “the expected value is written, not computed with the logic under test”. *Measured: in two runs the e2e computed the expected value with the same filter it tests.* A locator's `.filter(...)` inside `expect(...)` also matches: it is assigned to a `const` first | 0 errors |
| stable | the card's new scenarios run **3 times** before they are frozen: Playwright `npx playwright test --grep "@$ID" --repeat-each=3`; node tests `node .claude/tools/repeat.mjs 3 -- node --test --test-concurrency=1 <files>` (`node --test` de-duplicates a file named three times and has no repeat flag, so `repeat.mjs` runs the command three times in a row and stops at the first failure). A test that fails once is **“could not run: unstable”**, never frozen: it is fixed or its order dependence removed. *Measured elsewhere: LLM-written tests are flakier than human ones, and order dependence is the main cause.* | 3 of 3 green |
| red run | node tests in red, with a server they may leave open: `timeout 30 node --test --test-timeout=5000 --test-force-exit <files>`. Playwright reds: `npx playwright test --grep "@$ID" --timeout=5000 --retries=0`: a red test that waits for a locator that does not exist is cut at 5 s and is not retried. A red test that waits for a server that does not exist hangs the run for minutes; the timeout makes it fail on the assertion. Only here: **never in the final suite**, where `--test-force-exit` would hide an open handle | fails in under 30 s, on the assertion |
| test smells | the detectors D01 to D24 of `reference/testing.md` over the new tests, when the linter does not cover them. Untested on this machine as a set; each one was tried over a sample | no finding that is not a justified false positive |

## Pause 1

| ID | Command | Must give |
|---|---|---|
| S1 | `node .claude/tools/once.mjs suite -- npm test` | exit 0, and the script includes `tsc --noEmit`, the unit tests and `playwright test --project=gate`. `once` does not repeat it if it already passed on the same code; it stores in `.validation/`, which goes in `.gitignore` |
| S2 | `node .claude/tools/once.mjs scenarios -- npx playwright test --grep "@$ID"` | exit 0 |
| S3 | the same run as S1: the gate is already inside `npm test`, it is not run twice | exit 0 of S1 |
| S4 | `npx playwright test --grep "@$ID" 2>&1 \| grep -cE "TimeoutError\|resolved to 0 elements\|strict mode violation"` | `0` |
| S6 | `git clone . /tmp/clean && cd /tmp/clean && npm ci && npm start` | starts with no further step |

## Pause 2

| ID | Command |
|---|---|
| T1 | For **every file in the diff the grade asks to mutate** (production: every production file; mvp: the domain; poc: none): `node .claude/tools/once.mjs mutate:<file> -- node .claude/tools/mutate.mjs <file> --since <card-start> --equivalents specs/<card>/equivalents.md -- <suite that covers it>`. The suite is that file's unit suite; a server or a router is covered by an HTTP test with `node --test` that starts the app on a free port and requests it —never the browser suite: `mutate.mjs` refuses it, because every mutant would rerun it, and refuses any run over 10 minutes—. With a unit suite use `--parallel 4`. It mutates only the lines the card changed. A mutant that does not change behavior is declared in `equivalents.md` with its reason, and it comes into view; `mutate.mjs` prints the declaration line to copy, which identifies the mutant by its operator and the code around it, so reformatting lines does not break it. `/close` does not start until `node .claude/tools/required.mjs` gives 0. For more operators, **Stryker** (`npx stryker run --mutate <file>`) |
| T3 | `comm -12 <(grep -ohE "from '[^']+'" <seed> \| sort -u) <(grep -ohE "from '[^']+'" <seed-test> \| sort -u)` — must give empty |

## Pause 3

| ID | Command |
|---|---|
| C2 | `grep -rnE "\)!\|\]!\|\bas any\b\|as unknown as\|@ts-(ignore\|expect-error)\|eslint-disable\|catch *\([^)]*\) *\{ *\}" $(git diff --name-only <card-base>)` |
| C5 | `node -e "const p=require('./package.json');const s=Object.values(p.scripts\|\|{}).join(' ');for(const d of Object.keys(p.devDependencies\|\|{}))if(!s.includes(d.split('/').pop().replace('@','')))console.log('nobody runs:',d)"` — empty |
| C6 | for every production `export`, `git grep -wl <name> \| wc -l` greater than 1 |
| C8 | an `architecture.test` that parses the imports of each layer; or **dependency-cruiser** with `forbidden` rules: the domain and application folders to `node_modules` except the allow-list, deep imports into another module (`only-public-index`), and a table touched outside its owner module. Untested on this machine |
| C9 | `npx jscpd --min-lines 6 <production-folder>` — as a development dependency |
| C10 | `npx madge --circular --extensions ts,tsx,js,mjs <src>`, or dependency-cruiser with the `no-circular` rule — no cycles. Untested on this machine |
| C11 | **eslint** with `sonarjs`, `@typescript-eslint/no-floating-promises` and `no-misused-promises`, a `no-restricted-syntax` over a `CatchClause` whose only statement is a call to `console` or the logger, and `preserve-caught-error` if the version ships it [NV]. Untested on this machine |
| C12 | the loop of `reference/code-patterns.md` over `src`: exported interfaces with at most one implementation and no fake in tests. Informative |
| C13 | the loop of `reference/code-patterns.md`: abstract classes with at most one subclass. Informative |
| C14 | the `rg --pcre2` of `reference/code-patterns.md`: methods that only forward to a collaborator. Informative |
| C15 | `rg -n "Date\.now\(\|new Date\(\)\|Math\.random\(\|process\.env" src --glob '**/domain/**'`. Informative |
| C16 | the name-pattern `rg` of `reference/code-patterns.md`. An alert, not a verdict |
| C17 | the D18 command of `reference/testing.md`: `git diff -U0 <card-start> -- <tests folder> \| rg -nP '<D18 pattern>'` — empty, or each line justified in the card. Untested on this machine |
| C18 | `TZ=America/St_Johns LANG=tr_TR.UTF-8 npm test` through `once.mjs`: the suite a second time with an offset of half an hour and the Turkish `i`; on Windows `cross-env TZ=… LANG=…`. Untested on this machine |

## Pause 3b

| ID | Command |
|---|---|
| Q1 | `node .claude/tools/once.mjs lint -- npx eslint <production and test files in the diff>`, with **eslint-plugin-sonarjs** (`sonarjs.configs.recommended`) for all and `no-conditional-in-test` also for the unit tests — zero problems. The tests go in the same command: `required.mjs` asks that every test in the diff has passed through the linter. Tested on this machine with version 4.2.2 |
| Q2 | **Semgrep** Community Edition: `semgrep scan --config p/default --error <files in the diff>`. Untested on this machine |
| Q3 | `npx c8 --include <production files in the diff> --check-coverage --lines 80 node --test <unit-tests>` |
| Q4 | `npx @lizenz/checker --production --onlyAllow "MIT;Apache-2.0;BSD-2-Clause;BSD-3-Clause;ISC;0BSD;Unlicense;CC0-1.0;Zlib"` (successor of `license-checker-rseidelsohn`), or `npx licensee --production --errors-only` with a `.licensee.json`; the repo's own list if `docs/technical/dependencies.md` overrides it. Fonts, icons, images and copied fragments: **scancode-toolkit** or the inventory in the notices. A command not verified on this machine: **Untested on this machine** |
| Q5 | **OWASP ZAP** in baseline mode, against the running app: `zap-baseline.py -t http://127.0.0.1:<port>` — needs Docker or Java. Untested on this machine. Once per card, at the end; not rerun after fixes |
| Q6 | `sonar-scanner` against the company server, and `sonar.qualitygate.wait=true` |
| Q7 | PostgreSQL: `npx squawk-cli <migrations>/*.sql`; MySQL: every `ALTER TABLE` of the card declares `ALGORITHM` (`rg -n "ALTER TABLE" <migrations> \| rg -v "ALGORITHM"` is empty). Untested on this machine |
| Q8 | `npx @redocly/cli lint docs/api/openapi.yaml` or `npx @stoplight/spectral-cli lint docs/api/openapi.yaml`; AsyncAPI: `npx @asyncapi/cli validate docs/api/asyncapi.yaml` (the validator for AsyncAPI 3 must be confirmed, [NV]); GraphQL: the schema printed from the code against the committed one. Untested on this machine |
| Q9 | a test in the suite that compares the registered routes with the spec paths in both directions and validates the responses of the HTTP tests; alternative `schemathesis run docs/api/openapi.yaml --url http://127.0.0.1:<port>`, one at a time. Untested on this machine |
| Q10 | the generator's strict build (Docusaurus with `onBrokenLinks: 'throw'`, `mkdocs build --strict`, Starlight with `starlight-links-validator`), or `lychee --offline docs README.md`, or `npx markdown-link-check`. Diagrams as code, one render per source through `once.mjs` (W10, DOC-16): `npx -p @mermaid-js/mermaid-cli mmdc -i <file.mmd|page.md> -o <out>`, `d2 <file.d2> <out.svg>`, `likec4 build`, a request to Kroki, `node archify/bin/archify.mjs validate <name>.archify.json` [NV subcommand]. Untested on this machine; the flags of `mmdc`, `d2`, `likec4` and `archify` are [NV] |
| Q11 | `npx generate-license-file --input package.json --output THIRD_PARTY_NOTICES.md` and `git diff --exit-code THIRD_PARTY_NOTICES.md`. Untested on this machine |
| Q12 | `npx commitlint --from <card-start> --to HEAD` with `@commitlint/config-conventional`; release notes with release-please, semantic-release, changesets or git-cliff, all options. Untested on this machine |
| Q13 | `actionlint` for GitHub Actions; `rg -n "uses: " .github/workflows \| rg -v "@[0-9a-f]{40}"` is empty; `permissions:` present in every workflow; `gh api repos/<owner>/<repo>/branches/main/protection` for the required checks. Pipeline templates by provider (GitHub Actions, GitLab CI, Azure Pipelines, Bitbucket) are options. Untested on this machine |
| Q14 | `trivy image <image>` or `grype <image>`; `checkov -d <iac>` or `kics scan -p <iac>`; `hadolint Dockerfile` (a non-root `USER`). Untested on this machine |
| Q15 | `promtool check rules <alerts>` (or the provider's validator) and each alert's `runbook_url` points to an anchor that exists in `docs/technical/runbook.md`. Untested on this machine |
| Q16 | a script with no library that loads the source catalog and each other one and prints `missing`, `extra` and `bad` placeholders (I18N-TST-01), or `npx lingui extract --clean && git diff --exit-code src/locales/` / `npx formatjs extract … && git diff --exit-code`. Untested on this machine |
| Q17 | `npx eslint src --rule '{"i18next/no-literal-string":"error"}' -f json` counted, or `formatjs/no-literal-string-in-jsx`. Informative. Untested on this machine |
| Q18 | `rg --pcre2` with the 22 patterns of `reference/performance.md` section 5.15 over the diff's front-end files (`H`, `C`, `J` globs of that table), excluding `*.spec.*` and `*.test.*`; for example `rg -n --pcre2 '^(?!\s*(/\*\|\*\|//))[^\`]*?transition(-property)?\s*:\s*all\b' -g '*.css' -g '!*.spec.*'` for FE-DET-03 and `rg -n --pcre2 'will-change\s*:\s*+(?!auto\b)' -g '*.css'` for FE-DET-18. Informative; the lab tests (LoAF, lab INP, leaks in 7 cycles) are the plan's `vitals:` line. Tried on a bad and a good sample; the rest of the commands are untested on this machine |
| Q19 | the upgrade from main with data, as `node .claude/tools/once.mjs migrate-upgrade -- <script>` (the plan's Verification line `migrate-upgrade: <script>`). The script, against a throwaway database of the production engine and version (Testcontainers or a pinned container): `BASE=$(git merge-base origin/main HEAD)`; `git worktree add ../_base "$BASE"`; migrate to the base state **from `../_base`**; load the versioned seed with the rows that break DDL (populated tables, NULLs, duplicates, rows that look orphaned) and fail if a seed table is empty; apply **from the branch** only what is pending; run the suite; `git worktree remove --force ../_base`. The apply step per tool, all untested on this machine: Prisma `npx prisma migrate deploy` (base, then branch) and `npx prisma migrate diff --from-migrations prisma/migrations --to-schema prisma/schema.prisma --exit-code` for DB-MIG-19; Knex `npx knex migrate:latest`; Flyway `flyway migrate` then `flyway validate` (`outOfOrder=false`); Liquibase `liquibase update`; Atlas `atlas migrate apply --dir file://<dir>` (`../_base/migrations`, then `migrations`) with `--exec-order linear`; Alembic `alembic upgrade head` (and `alembic heads` with one line [NV]); Django `python manage.py migrate` and `makemigrations --check --dry-run`; EF Core `dotnet ef database update`; Rails `bin/rails db:migrate`; golang-migrate `migrate -path <dir> -database "$URL" up` |

## Pause 4

| ID | Command |
|---|---|
| G3 | `npm sbom --sbom-format cyclonedx > sbom.json` · `npm audit --omit=dev` · for every direct dependency, `npm view <package> name` must exist |
| G4 | `git log -p \| grep -nE "(api[_-]?key\|secret\|password\|token)\s*[:=]\s*['\"][^'\"]{8,}"` — empty. More complete: **gitleaks**, or **Betterleaks** or **trufflehog** as options; as a pre-commit hook (`pre-commit` or husky) it is the evidence of S22. Secret managers, as options: AWS Secrets Manager, Azure Key Vault, GCP Secret Manager, HashiCorp Vault, Doppler, 1Password, Infisical |
| G2 | `node .claude/tools/attack.mjs http://127.0.0.1:<port> --write "<METHOD> <route> <body>" --read "<route with personal data>"` for every route the card adds or changes — exit 0. Also, timeouts: `server.requestTimeout` and `server.headersTimeout` set, and a client that sends the headers one byte at a time sees the connection cut |
| G9 | `npm outdated --json`; Renovate (`renovate.json`) or Dependabot (`.github/dependabot.yml`) as options for the update policy |

## Pause 5

Playwright with `@axe-core/playwright`, one view per test, at 1280 and 390 px, with the tags
`wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa` and `wcag22aa`. A5 with
`page.emulateMedia({ forcedColors: 'active' })`. A6: reflow with a 320 px viewport; text spacing
by injecting the WCAG 1.4.12 CSS; target size by measuring `getBoundingClientRect`. Text zoom to 200%
(I9): a viewport with `deviceScaleFactor` 2 and the root `font-size` at 200%, no clipped or overlapping
text. Keyboard tests per APG pattern for each complex component (I16): the roles, the states and the
keys of its pattern in `reference/accessibility.md` (module ui).

## Pause 6

| ID | How |
|---|---|
| R1 | a script that requests every main screen 200 times with the seed loaded and reports the p95, as a smoke under the budget of O10. No dependencies: `fetch` and `performance.now()` |
| R2 | corrupt a copy of the data file and start against it: it must stop with a message and the file stay intact. The write, to a temp file and then `rename` |
| R3 | `netstat` during the run: a single own port, on the declared interface |
| R4 | `npx size-limit` per route, or a script over `.vite/manifest.json`; Playwright with the `web-vitals` library (`onLCP`, `onINP`, `onCLS` with `reportAllChanges`), CPU throttled x4 through CDP, the scenario's interactions; Lighthouse CI (`npx @lhci/cli autorun`) as an option, which in navigation mode gives no INP. Run alone, in a production build. Untested on this machine |
| R5 | Testcontainers (`@testcontainers/postgresql`); EXPLAIN with no `Seq Scan`, `type: ALL` or Table Scan on growing tables; count queries by wrapping `client.query` of pg, `$on('query')` of Prisma, `logging` of Sequelize or `on('query')` of Knex [NV]; the PK, FK, type and privilege queries of `reference/database.md` (module data). Untested on this machine |
| R6 | `pg_dump -Fc`, `pg_restore -d restore_check`, a validation query and the time against the RTO. Untested on this machine |
| R7 | `curl -s http://127.0.0.1:<port>/health` compared with the `version` of `package.json`; for a CLI, `--version` |
| R8 | `curl -fsS` to `/health` and `/ready`, and `/ready` with the database stopped (Testcontainers `stop`) giving 503. Untested on this machine |
| R9 | pino or the repo's logger in JSON; `@opentelemetry/sdk-node` with the auto-instrumentations and `OTEL_TRACES_EXPORTER=console`; the probe starts the app, sends a request with known sensitive data and a `traceparent`, and checks the log lines, the header in the simulated outgoing call and in the job, and the span. Backends, as options: Grafana with Prometheus and Tempo, Datadog, New Relic, Azure Monitor, CloudWatch; error tracking with Sentry or GlitchTip. Untested on this machine |
| R10 | k6 (`constant-arrival-rate`, `thresholds`) or autocannon; the generator on another machine, or declared. Run alone. Untested on this machine |
| R11 | the pipeline's smoke against staging and the runbook's rollback. Untested on this machine |

## Pause 7

| ID | Command |
|---|---|
| M1 | by name: `grep -rln -E "'(member1\|member2\|…)'" --exclude-dir=node_modules .` · by count: `grep -rn -E "repeat\( *N\|\.length *[=!]== *N\|Array\( *N" --include=*.css --include=*.ts .` |
| M3 | `Record<StageId, …>`, not `Record<string, …>` |
