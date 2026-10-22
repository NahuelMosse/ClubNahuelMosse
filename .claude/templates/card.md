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
A file carries its layer in parentheses: `(rule)` domain, no I/O (validation and calculations are pure and live here), `(data)` the only place with SQL or db access, `(presentation)` a screen. The gate's `layers` check reads them.

- T1 · S1 · src/search.mjs (rule), test/search.test.mjs · tests: test/search.test.mjs "search by partial name @GST-208-S1"; test/search.test.mjs "search by prefix @GST-208-ASM-01"
- T2 · S2 · src/api/customers.mjs, src/db/customers.mjs (data), test/customers.test.mjs · tests: test/customers.test.mjs "results show tax ID and status @GST-208-S2"

## Changes to existing behavior

A route, screen or file of main that this card changes, one line each, with the earlier test it affects; `none` if the card only adds.

- GET /api/customers · the list now takes `q` · test/customers.test.mjs "list all @GST-190-S1" stays valid

## Look

Only with the lens `visual`, 15 lines or fewer; plan.mjs refuses the plan without the three keys. `ref:` is the design the card brings (Figma, a capture) saved in `specs/<card>/ref/`, or a URL; if the card brings none, it comes from the repo's design system or `.claude/reference/design-refs.md` (profile web; a product of that level, never «the simplest» or «the cheapest to undo») and is declared as an `ASM`.

- ref: specs/GST-208/ref/search.png · https://linear.app/issues
- behavior: load · the rows enter in a 60 ms stagger, once
- behavior: cursor · a row lifts 2 px on hover; the buttons answer to press and focus
- behavior: view · the table enters once, on first sight
- behavior: loading, empty · skeleton with the shape of a row; the empty state offers the action
- tokens: fonts Fraunces + Instrument Sans · ink #1b1a17, accent #d4552b · spacing 4 8 12 16 24 32 · easing out cubic-bezier(.22,1,.36,1) 200 ms (or: the repo's, in <path>)

## Gate

One command per line, as verify.mjs runs them: `suite:`, `lint:`, `mutate <file>: <suite>`, `app:`, `probe:`, `attacks:`. With `app:`, verify.mjs starts the app once and brings it down at the end; every line gets `APP_URL`, `PORT` and `DATA_DIR` in its environment (`$APP_URL`, `${APP_URL}` and `%APP_URL%` also work in the text, in any shell), and `attack.mjs`, `overflow.mjs`, `motion-audit.mjs` and `app.mjs probe` take the URL from `APP_URL` when none is given.
Planned here, before the code, so the gate and the judge find them done: a screen (lens `visual`) has one `probe <state>:` line for each state a spec names (`state: …`), the transient ones with the route held (`--route "GET /api/x=hold"`). An API (lens `contract`) must have the `attacks:` line; `--body-limit` is the limit the card sets, in bytes; `--common-headers` the headers every response carries, `--unique` the write that must answer a duplicate, `--fault-db` the database file to damage, `--openapi` the contract to compare.
The steps of a `probe` can press Enter from each control and type markup: `[{ "enter-each": "form" }, { "type-markup": "input[name=q]" }]`; `--enter-skip` lists the controls where Enter does not submit.

```
suite: npm test
lint: npx eslint src test
mutate src/search.mjs: node --test test/search.test.mjs
app: node src/main.mjs
probe loading: node .claude/tools/app.mjs probe steps/loading.json --axe --contrast "[role=status]" --route "GET /api/customers=hold" --out .validation/probe/loading
probe empty: node .claude/tools/app.mjs probe steps/empty.json --axe --contrast "[role=status]" --out .validation/probe/empty
probe typed: node .claude/tools/app.mjs probe steps/typed.json --enter-skip "textarea" --out .validation/probe/typed
attacks: node .claude/tools/attack.mjs --json --body-limit 1024 --write "POST /api/customers name=Ana" --read "/api/customers" --common-headers "content-type, cache-control" --unique "POST /api/customers name=Ana" --fault-db $DATA_DIR/customers.db --openapi openapi.json
overflow: node .claude/tools/overflow.mjs
```

## Log

L1 is the requirement, verbatim and whole. Then one line per answer from Jira, decision or evidence. A frozen test of an earlier card that this card contradicts is declared before building: `Grep` its `@<ID>-S` tags in the files the Tasks touch.

- L1 · Search customers by partial company name. Results show tax ID and status. <rest of the card as written>
- L2 · 2026-08-31 · Jira answer: …
- L3 · 2026-09-01 · replaces: test/search.test.mjs "search is exact @GST-190-S2" · the new S1 asks for partial match · by: test/search.test.mjs "search by partial name @GST-208-S1"
