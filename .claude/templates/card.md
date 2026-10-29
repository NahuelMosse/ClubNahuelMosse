# GST-208 · customer search

status: proposed
cap: 45 min
sources: description, comments (4), attachment acceptance-criteria-v3.xlsx
not_read: attachment mockups.fig (could not be opened)

<!-- The card's single document. Headings are in English: the tools read them. The text is in the repo's language.
     Lines starting with `- S`, `- T` and `- L` are read by risk.mjs and verify.mjs: keep their shape. -->

## Specs

Each spec quotes a sentence or criterion of the card verbatim. A test carries its tag: `@GST-208-S1`.

- S1 · "Search customers by partial company name" · acceptance: case-insensitive, at least 3 characters
- S2 · "Results show tax ID and status" · acceptance: the tax ID with hyphens · state: loading, empty
- GST-208-ASM-01 · the search is by prefix, not by substring (the cheapest to undo) · S1

## Tasks

`T<n> · <specs> · <files> · tests: <file> "<title with its tag>"`: one line per group of files; several tests are separated with `;`. Every `S#` and every `ASM-NN` has its planned test in some T line (risk.mjs refuses a plan without it, and does not write risk.json).
Paths are feature-first, layers inside: `src/modules/<feature>/{presentation,domain,data}/…` (`lib/features/<feature>/…` in Flutter), `application/` for a use case that orchestrates, a small `shared/` kernel; `risk.mjs` refuses a new file under a top-level folder by layer or by kind (`domain/`, `screens/`, `services/`…) or outside its layer folder. Names are in English unless CLAUDE.md declares `Code language:`. The simplest structure that works: no use case that only forwards; a factory, strategy, adapter, bus or `I<Name>` interface file carries `why-layer: <the second variant it serves, or the test fake that needs it>` and `risk.mjs` refuses it without one: otherwise drop it. Where the card adds persistence, dependency injection, validation, auth, a client or a queue, the plan names the library per category (the repo's own, else the stack's default in `.claude/stacks/`); hand-rolling one is an `ASM`. A file carries its layer in parentheses: `(rule)` domain, no I/O (validation and calculations are pure and live here), `(data)` the only place with SQL or db access, `(presentation)` a screen. The gate's `layers` check reads them.
Every task that writes production code carries, indented under its T line, what it found when it searched the module and `shared/` before writing: `reuses: <file> <symbol it uses or extends>`, or `new: <what you searched and why nothing fits>`; `risk.mjs` refuses it without one of the two.

- T1 · S1 · src/modules/customers/domain/search.mjs (rule), test/search.test.mjs · tests: test/search.test.mjs "search by partial name @GST-208-S1"; test/search.test.mjs "search by prefix @GST-208-ASM-01"
  new: no search over a name exists (Grep search|match|filter in customers and shared/)
- T2 · S2 · src/modules/customers/presentation/customers.routes.mjs (presentation), src/modules/customers/data/customers.repository.mjs (data), test/customers.test.mjs · tests: test/customers.test.mjs "results show tax ID and status @GST-208-S2"
  reuses: src/shared/format.mjs formatTaxId

## Changes to existing behavior

A route, screen or file of main that this card changes, one line each, with the earlier test it affects; `none` if the card only adds.

- GET /api/customers · the list now takes `q` · test/customers.test.mjs "list all @GST-190-S1" stays valid

## Look

Only with the lens `visual`, 15 lines or fewer; plan.mjs refuses the plan without the four keys. `ref:` is the design the card brings (Figma, a capture) saved in `specs/<card>/ref/`, or a URL; if the card brings none, it comes from the repo's design system or `.claude/reference/design-refs.md` (profile web; a product of that level, never «the simplest» or «the cheapest to undo») and is declared as an `ASM`. One reference of the same field gives the structure; one or two lateral ones from other fields (`### Lateral` of that gallery) give the trait of excellence. A product screen (a dashboard, a list, a tool) declares `ref-kind: product`: its references are real product UI (`reference/design-refs.md`), the capture refuses a login or marketing page, `design-round --kind` measures it with the `product:` rows, and `brand-chrome: glass, gradient` lists the surfaces the brand itself asks for. A landing also declares `ref-genre: <genre>` (see the gallery) and its `ref:` is of that genre. An optional `intent: collage|statement|grid|pinned-media` says what a section family is on purpose; under it the focal, competing, axes and elements measures of `design-round` are reported, never flagged (`reference/composition.md`). `tokens:` states mood and genre, spacing and easing; it fixes font families or a palette only when the brand or the requester gives them: the designer chooses them after looking at the references, in `## Direction` of `rondas.md`, and departs from the genre's cliché. `copy:` is the concrete number of the offer and who speaks (`reference/copy.md`); template phrases fail the copy lint. A card that only takes something off a screen (a notice, an error screen) writes `remove-only: <what goes>` instead of the four keys: no `ref:` and no design rounds, the states and accessibility lines still run on what remains, and the gate fails if its presentation files gain more lines than they lose.

- ref: specs/GST-208/ref/search.png · https://linear.app/issues
- behavior: load · the rows enter in a 60 ms stagger, once
- behavior: cursor · a row lifts 2 px on hover; the buttons answer to press and focus
- behavior: view · the table enters once, on first sight
- behavior: loading, empty · skeleton with the shape of a row; the empty state offers the action
- tokens: mood warm, artisanal · genre drink-food · spacing 4 8 12 16 24 32 · easing out cubic-bezier(.22,1,.36,1) 200 ms (or: the repo's, in <path>)
- copy: 1,884 events in 13 days · the brand speaks in first person, one quote from a named attendee

## Gate

One command per line, as verify.mjs runs them: `suite:`, `lint:`, `mutate <file>: <suite>`, `app:`, `probe:`, `attacks:`. `suite:` runs the tests the card can break, `{affected}` standing for them (`node --test {affected}`, `npx vitest run {affected}`, `pytest {affected}`, `flutter test {affected}`); the whole suite runs once in the CI of the PR, which `/close` waits for. `refactor-tests: <why>` lets a mechanical change edit frozen tests in place; the close lists each for a person. With `app:`, verify.mjs starts the app once and brings it down at the end; every line gets `APP_URL`, `PORT` and `DATA_DIR` in its environment (`$APP_URL`, `${APP_URL}` and `%APP_URL%` also work in the text, in any shell), and `attack.mjs`, `overflow.mjs`, `motion-audit.mjs` and `app.mjs probe` take the URL from `APP_URL` when none is given.
`no-visual: <why>` declares that the card touches code files that build markup (an HTML string in a `.py`) without changing what a screen shows: the `visual` lens stays off while no `## Tasks` file is a view, and the gate fails if the card's diff changes a markup line of those files. `no-docs: <why>` declares a card that changes no behavior: without it, from mvp the `docs` check wants the feature page, the contract and the data model the card touched (`templates/docs.md`, module docs).
Planned here, before the code, so the gate and the judge find them done: a screen (lens `visual`) has one `probe <state>:` line for each state a spec names (`state: …`), the transient ones with the route held (`--route "GET /api/x=hold"`). An API (lens `contract`) must have the `attacks:` line; `--body-limit` is the limit the card sets, in bytes; `--common-headers` the headers every response carries, `--unique` the write that must answer a duplicate, `--search` a read with a free-text parameter, `--fault-db` the database file to damage, `--openapi` the contract to compare.
The steps of a `probe` can press Enter from each control and type markup: `[{ "enter-each": "form" }, { "type-markup": "input[name=q]" }]`; `--enter-skip` lists the controls where Enter does not submit.

```
suite: node --test {affected}
fmt: npx prettier --check .
lint: npx eslint src test
mutate src/modules/customers/domain/search.mjs: node --test test/search.test.mjs
app: node src/main.mjs
probe loading: node .claude/tools/app.mjs probe steps/loading.json --axe --contrast "[role=status]" --route "GET /api/customers=hold" --out .validation/probe/loading
probe empty: node .claude/tools/app.mjs probe steps/empty.json --axe --contrast "[role=status]" --out .validation/probe/empty
probe typed: node .claude/tools/app.mjs probe steps/typed.json --enter-skip "textarea" --out .validation/probe/typed
attacks: node .claude/tools/attack.mjs --json --body-limit 1024 --write "POST /api/customers name=Ana" --read "/api/customers" --common-headers "content-type, cache-control" --unique "POST /api/customers name=Ana" --search "/api/customers q" --fault-db $DATA_DIR/customers.db --openapi openapi.json
overflow: node .claude/tools/overflow.mjs
```

## Log

L1 is the requirement, verbatim and whole. Then one line per answer from Jira, decision or evidence. A frozen test of an earlier card that this card contradicts is declared before building: `Grep` its `@<ID>-S` tags in the files the Tasks touch. A line is appended with `node .claude/tools/log.mjs specs/<card> "<text>"`, which numbers and dates it.

- L1 · Search customers by partial company name. Results show tax ID and status. <rest of the card as written>
- L2 · 2026-08-31 · Jira answer: …
- L3 · 2026-09-01 · replaces: test/search.test.mjs "search is exact @GST-190-S2" · the new S1 asks for partial match · by: test/search.test.mjs "search by partial name @GST-208-S1"
