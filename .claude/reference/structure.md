# Folder structure: slices that stay ordered as the repo grows

The rule is in `rules/architecture.md` ("Structure" and "Module boundaries"); this page holds the trees and the growth
ladder behind it. Every structure starts at its smallest valid version and climbs one step only on its signal. The trees
come from reading the layouts of real repos (paths below); the file-count thresholds are a reading of those repos, not a
published standard, and are signals to look, not limits.

## Backend (Node/TS; the same shape in Nest, .NET, Python)

**Small: CRUD slices.**
```
src/
  app.ts                        composition root: mounts each slice
  modules/
    customers/
      customers.routes.ts       receives, validates, delegates (controller in Nest)
      customers.repository.ts   the stack's ORM
      customers.schema.ts       the resource's shape (zod) and its types
      customers.test.ts
      index.ts                  what other slices may use, by name
  shared/                       only when a second slice needs it: config.ts logger.ts errors.ts
```
Smallest: `modules/customers/{customers.routes.ts, customers.test.ts}`; `index.ts` when another slice uses it.

**Medium: one slice has business rules.** Layers become folders inside that slice only; the others stay flat.
```
src/modules/
  customers/                    still flat files
  orders/
    domain/          order.ts pricing.ts pricing.test.ts      pure rules, no I/O
    application/     place-order.ts cancel-order.ts           only if a use case orchestrates
    infrastructure/  orders.repository.ts payments.client.ts
    interface/       orders.routes.ts orders.schema.ts
    index.ts
```

**Large: many use cases in a slice.** One folder per use case, its files together (`kgrzybek/modular-monolith-with-ddd`:
`Meetings/Application/<Aggregate>/<UseCase>/`).
```
src/modules/orders/
  domain/            order.ts order-status.ts
  application/
    place-order/     place-order.ts place-order.schema.ts place-order.test.ts
    cancel-order/    cancel-order.ts cancel-order.test.ts
  infrastructure/    orders.repository.ts
  interface/         orders.routes.ts
  index.ts
```

**Very large: sub-slices, then a package.**
```
src/modules/orders/
  checkout/          domain/ application/ interface/      same shape as a slice, layers only if it has them
  fulfillment/       domain/ application/ interface/
  index.ts
```
or `packages/orders/{package.json, src/…}`, whose door is the `exports` field (`medusajs/medusa`: `packages/modules/cart`).

## Frontend (React; the same idea in Vue, Svelte, Flutter `features/`)

Features do not import each other; routes compose them (`alan2207/bulletproof-react`: `src/features/<x>/{api,components}`,
composed in `src/app/routes`).
```
src/
  app/          router.tsx provider.tsx routes/orders.tsx      composes features
  features/
    orders/
      orders-page.tsx  orders-page.test.tsx  use-orders.ts      small: flat files
  shared/
    ui/         button.tsx dialog.tsx                           primitives with no domain
    lib/        api-client.ts
```
Medium: `features/orders/{api/, components/, hooks/, index.ts}`, only the subfolders that hold something. Large: split by
screen or flow (`features/orders/{list/, detail/, checkout/}`), never by kind: a `components/` of hundreds of files inside one
feature is the mess to avoid (`grafana/grafana`: `public/app/features/alerting/unified/components`, 588 files).

## Full stack

The same feature name in every root, and the contract between both sides in one place; the UI never imports the server's
repository or service.
- **One app:** `src/features/orders/{server/, ui/, orders.test.ts, index.ts}`; `ui/` imports only the resource schema.
- **Two apps:** `apps/api/src/modules/orders/` and `apps/web/src/features/orders/`, plus `packages/contracts/orders.ts` when
  both import the resource's types. End-to-end flows in `apps/e2e/<feature>/`.

## Growth ladder

Each step only with its signal; without it, the structure stays where it is.
1. **Flat files** in the slice while it has about 10–15 and they change together.
2. **A layer becomes a folder** when a rule needs a test without database or network (`why-layer:`); `domain/` first,
   `application/` only for use cases that orchestrate.
3. **A folder per use case** past about 5 use cases, or when one has 3+ files of its own.
4. **A sub-slice** when two parts of the slice change for different reasons and each has a business name. One level at most.
5. **A workspace package** when it needs its own build cache, owner or publication (about 300 files is a signal to look).
6. **A separate service** only for a scaling or deployment need; not a folder decision.
7. **Merge back**: two slices that import each other both ways, or always change together, are one slice.

## Names, tests, shared

- **Slice folder:** a business noun, plural, kebab-case (`orders`, `meeting-groups`), the same in backend and front. Never
  `common`, `core`, `utils`, `helpers`, `managers`, `misc`.
- **Files:** `<feature>.<role>.ts` in OO stacks (`customers.service.ts`), concept names in functional ones
  (`create-order.ts`); use-case folders are `verb-noun` (`place-order/`). One interface style per repo.
- **Tests:** a unit test beside its file; integration tests inside the slice; one architecture test for the whole repo;
  never a root `tests/` that mirrors layers.
- **`shared/`:** config, logging, base errors, small pure utilities (dates, money), technical clients, UI primitives. No
  entity, rule or table of a domain; no import of a slice. Something enters at its third use across slices (before that, the
  owner exports it); something that only one slice uses goes back to it. Split by concept: `shared/money/`, `shared/errors/`.

## Read by eye

1. One feature is understood without leaving its folder.
2. Folder names are business nouns; no layer folder at the root.
3. Every subfolder holds something; no layer without `why-layer:`.
4. At most three levels inside a slice; a fourth asks for a named sub-slice.
5. A folder of more than ~15 flat files, or a slice past ~100, climbs the ladder.
6. Tests live beside what they test.
7. `shared/` imports no slice and names no domain.

The gate's `boundaries` check reads the card's files for the mechanical part: a `shared/` file that imports a slice, a slice
that reaches inside another instead of its index, `export *` in a slice's index and grab-bag folders.

## Seen at scale

- A layer at the root that grows without limit: `mattermost/mattermost` `webapp/channels/src/components` (4444 files).
- One feature spread over many roots: `calcom/cal.com` `bookings` in 6 roots, `bookings/lib` with 154 files.
- Two generations of structure side by side: `immich-app/immich` `mobile/lib/{providers,services,pages}` next to
  `{presentation,domain,infrastructure}`.
- Folders of one file in a layer-first layout: `jasontaylordev/CleanArchitecture` `src/Domain/{Constants,Events,Exceptions,ValueObjects}`.
