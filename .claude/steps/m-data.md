# Module data · what it adds to the steps

Read the section of the step you are on, only while `data` is on in `.claude/kit.json`. It is about
what a card stores. Its criteria: P4 to P14, P16, S20 and D11; its items: Q7, Q19, R5 and R6 of
`.claude/reference/validate-mechanical.md`. The rules are in `.claude/reference/database.md`, read
by section (`Read` with the line range of the heading), never whole.

## Step 1 · The first card of a repo

The engine and the data ownership are decisions of the ADR and of `docs/technical/system-design.md`:
which engine and why (`database.md` section 8), and which module owns which table (D11, section 7).

## Step 5 · The plan

- **The data model is written before the code** (P14): entities, owner module, volume, the queries
  with their index (P9), the migrations. A File map that names a schema file asks for the line
  `- System design: <what changes>` or `- System design: unchanged — <why>`.
- **A change to something that already stores data** goes expand, migrate, contract (P4), with a
  migration that is tested up, down and up on data that exists (P5). Money in decimal, instants in
  UTC (P8, I26); integrity in the schema, not only in the code (P6).
- **A migration that exists in main is never touched** (P16): a correction is a new migration, and the
  hooks block the write. The plan's Verification carries `migrate-upgrade: <command>`, the upgrade from
  main's last state with seeded data (Q19, DB-MIG-15).
- Retention, backups and the RPO and RTO of what is new go in the system design (P7).

## Step 6 · Implementing

The app connects with its own least-privilege user, distinct from the migrations user (S20). Growing
lists paginate by keyset (P11); no N+1 (P10); nothing external inside an open transaction (P13);
indexes and constraints are created without blocking where the engine allows it (P12).

## Step 8 · Verifying

Q7: the migration linter over the card's migrations. R5: the tests against the real engine —EXPLAIN
without full scans, query count per request, privileges—. R6: backup, restore and a validation
query, only if the card adds or changes a store; the restore finishes within the RTO. Q19: the new
migrations applied over the merge-base with main with seeded data, through `once.mjs migrate-upgrade`;
`required.mjs` also reads the diff against main for the migrations edited (DB-MIG-12) and their order
(DB-MIG-14).
