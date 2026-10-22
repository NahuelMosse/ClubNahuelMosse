# Database: rules a card can meet and a reviewer can check

**When it is read:** when the card touches stored data —a table, a column, a query, a
migration, a connection, a backup—. **How:** only the sections the card touches, with `Read` and a
line range of the heading; never whole. `card.md` names the rule IDs that apply, and the
`builder` receives those IDs and their ranges. **The commands are options, not obligations:**
PostgreSQL is the main example, with MySQL/MariaDB and SQL Server where the command differs; what
applies to NoSQL is named in its rule. **[NV] marks guidance not verified** —from general knowledge or
from a source that could not be opened—: it is a hypothesis, never the only evidence of a `meets`.

How each rule is checked: `J` judgment with written evidence, `C` a command that exits 0 or not, `T` an
automated test that fails if the rule breaks. The examples use `rg`, code under `src/` and migrations
under `migrations/`: adjust the paths to the stack. Source numbers `Bn` are in Sources.

## Rules that are criteria

| Rule | Criterion |
|---|---|
| DB-SEC-01, DB-SEC-02 | S3 |
| DB-MIG-02, DB-MIG-11, DB-MIG-16 | P4 |
| DB-MIG-09, DB-MIG-10, DB-MIG-15 | P5 |
| DB-MIG-12, DB-MIG-13, DB-MIG-14, DB-MIG-15, DB-MIG-17, DB-MIG-19, DB-MIG-20 | P16 |
| DB-MOD-04 | P6 |
| DB-OPS-04, DB-OPS-05, DB-OPS-07 | P7 |
| DB-MOD-05 | P8 |
| DB-IDX-01, DB-IDX-02, DB-IDX-03, DB-IDX-05 | P9 |
| DB-IDX-06 | P10 |
| DB-IDX-04, DB-IDX-07 | P11 |
| DB-MIG-03, DB-MIG-04, DB-MIG-05 | P12 |
| DB-TX-05, DB-TX-06 | P13 |
| DB-OPS-04 | P14 |
| DB-SEC-07 | P15 |
| DB-TX-03 | E3 |
| DB-TX-04 | E4 |
| DB-OPS-01, DB-OPS-02 | E8 |
| DB-SEC-05 | S9 |
| DB-SEC-04 | S20 |
| DB-OWN-01, DB-OWN-02 | D11 |
| DB-ENG-01, DB-ENG-02, DB-ENG-03, DB-ENG-04 | D14 (the ADR template) |
| DB-OPS-03 | O19 |
| DB-MIG-01 | O28 |

The rules outside this table are judgment or guidance, with no criterion of their own.

## 1. Modeling

**DB-MOD-01** — Normalize to 3NF/BCNF by default; denormalize only with a measured query that justifies it and the mechanism that keeps the copy, written next to it. · How J+C · criterion none · Check: no business datum repeated in two tables without a materialized view, trigger or event; every denormalized column carries the query and the `EXPLAIN` behind it: PG `COMMENT ON COLUMN pedidos.total_cache IS 'denormalized: order list, see EXPLAIN in docs/…'` then `rg -n "denormalized" migrations/`. NoSQL: documents are denormalized around the access pattern, but the sync mechanism is still mandatory · Source B9, B10, B8, B22.

**DB-MOD-02** — One atomic value per column: no comma-separated lists, JSON as a substitute for a relation, nor `tag1, tag2, tag3` columns. · How C+J · criterion none · Check: `rg -n "FIND_IN_SET|LIKE '%,|string_to_array|\.split\(','\)" src/ migrations/`. JSON/JSONB is for data with no schema, not for what is filtered or joined · Source B3 [NV Karwin detail].

**DB-MOD-03** — Every table has a primary key; use identity/`bigint` (or UUID with distributed generation), never `serial` or `int` for tables that grow. · How C · criterion none · Check: PG `SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE c.relkind='r' AND n.nspname='public' AND NOT EXISTS (SELECT 1 FROM pg_constraint p WHERE p.conrelid=c.oid AND p.contype='p');` returns 0 rows; `squawk migrations/*.sql`. MySQL `SELECT t.table_name FROM information_schema.tables t LEFT JOIN information_schema.table_constraints c ON c.table_schema=t.table_schema AND c.table_name=t.table_name AND c.constraint_type='PRIMARY KEY' WHERE t.table_schema=DATABASE() AND t.table_type='BASE TABLE' AND c.constraint_name IS NULL;` · Source B11, B16, B3.

**DB-MOD-04** — Declare every relation as a FOREIGN KEY and every business rule expressible as `NOT NULL`, `UNIQUE` or `CHECK` in the database, not only in the application. · How C+T · criterion P6 · Check: a test inserts an invalid row straight through SQL and expects the constraint error; PG `SELECT table_name, column_name FROM information_schema.columns c WHERE column_name LIKE '%\_id' AND table_schema='public' AND NOT EXISTS (SELECT 1 FROM information_schema.key_column_usage k JOIN information_schema.table_constraints t USING (constraint_name, table_schema) WHERE t.constraint_type='FOREIGN KEY' AND k.table_name=c.table_name AND k.column_name=c.column_name);` The same query works in MySQL and SQL Server with the right schema. Declared exception: tables of another service (DB-OWN-02) · Source B3, B8, B11.

**DB-MOD-05** — Use the type that describes the datum: `numeric`/`DECIMAL` for money, `timestamptz` for instants, `date` for dates without time, `boolean`, `uuid`; never `float`/`double` or `money` for amounts. · How C · criterion P8 · Check: PG `SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema='public' AND data_type IN ('money','real','double precision','timestamp without time zone','character');` and review each row; `squawk` covers the new migrations. MySQL `… WHERE data_type IN ('float','double')`; instants as `DATETIME` in UTC or `TIMESTAMP` (range to 2038) [NV]. SQL Server `datetimeoffset` or `datetime2` in UTC, `decimal(19,4)` for money [NV]. Store the currency (ISO 4217) in another column when there is more than one · Source B11, B3, B16.

**DB-MOD-06** — Store instants in UTC with zone (`timestamptz`) and convert to the user's zone only when showing; for future events at local time (shifts, appointments) store local time plus the IANA zone. · How C+T · criterion P8 · Check: a test with a date that crosses a daylight-saving change; PG `SHOW timezone;` in the app's session is `UTC`; `rg -n "timestamp without time zone|::timestamp\b" migrations/ src/` · Source B11.

**DB-MOD-07** — Filter date ranges with `>= start AND < end`, never `BETWEEN`. · How C · criterion none · Check: `rg -n -i "between" src/ --glob "*.{sql,ts,js,py,java,cs,rb,go}"` and review those that touch dates · Source B11.

**DB-MOD-08** — Use `NOT EXISTS` instead of `NOT IN (subquery)`: one `NULL` in the list empties the result. · How C · criterion none · Check: `rg -n -i "not in\s*\(\s*select" src/ migrations/` · Source B11.

**DB-MOD-09** — Decide `NULL` column by column: `NOT NULL` by default; `NULL` only when “unknown / does not apply” is a real state of the domain; compare with `IS NULL`, never `= NULL`. · How C+J · criterion none · Check: `rg -n -i "=\s*null|<>\s*null|!=\s*null" src/ --glob "*.sql"`; PG `SELECT table_name, column_name FROM information_schema.columns WHERE table_schema='public' AND is_nullable='YES';` each row justified in the plan · Source B3, B8.

**DB-MOD-10** — Model sets of values with a reference table plus FK when the set changes or has attributes; `CHECK (col IN (...))` or a native enum only if it is closed and stable. · How J+C · criterion none · Check: PG `SELECT typname FROM pg_type WHERE typtype='e';` MySQL `SELECT table_name,column_name FROM information_schema.columns WHERE data_type='enum' AND table_schema=DATABASE();` review the change history of each enum (in MySQL only appending to the end of an `ENUM` is instant) · Source B3, B14, B16.

**DB-MOD-11** — If there is soft delete, make it a decision of the requirement (recovery, audit, retention) with a `deleted_at timestamptz` column, partial indexes/uniqueness that exclude the deleted, a scheduled hard purge, and every query filtering the deleted in one place. · How T+C · criterion none · Check: a test creates, deletes and recreates with the same unique key and it works; the list does not return the deleted; the purge job has a declared term. PG `CREATE UNIQUE INDEX … ON usuarios (email) WHERE deleted_at IS NULL;` SQL Server: filtered index. MySQL has no partial indexes: uniqueness over a generated column `(email, IF(deleted_at IS NULL, 1, NULL))` [NV]. PII with a right to erasure: soft delete is not enough, purge or anonymize (DB-SEC-07) · Source B24, B3 [NV soft delete and FK].

**DB-MOD-12** — Avoid EAV, polymorphic associations (`entity_type` + `entity_id` with no FK) and tables “per client / per year”. · How C+J · criterion none · Check: `rg -n -i "(entity|owner|target|commentable)_type" migrations/`; PG `SELECT relname FROM pg_class WHERE relname ~ '_(19|20)[0-9]{2}$' AND relkind='r';` (Postgres uses native partitioning instead) · Source B3, B11.

**DB-MOD-13** — Lowercase `snake_case` names, unquoted. · How C · criterion none · Check: `rg -n '"[A-Z][A-Za-z]*"' migrations/*.sql` · Source B11.

## 2. Indexes and queries

**DB-IDX-01** — Create each index from a concrete query (the access pattern) and name it in the migration; do not index columns “just in case”. · How J+C · criterion P9 · Check: every `CREATE INDEX` of the migration has the query it serves next to it; PG `SELECT relname, indexrelname, idx_scan FROM pg_stat_user_indexes WHERE idx_scan = 0 ORDER BY pg_relation_size(indexrelid) DESC;` MySQL `SELECT * FROM sys.schema_unused_indexes;` [NV]; SQL Server `sys.dm_db_index_usage_stats` [NV] · Source B1, B3.

**DB-IDX-02** — Every FK has an index that covers it as its leading column (joins and cascading deletes). · How C · criterion P9 · Check: PG `SELECT c.conrelid::regclass, a.attname FROM pg_constraint c JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1] WHERE c.contype='f' AND NOT EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid=c.conrelid AND i.indkey[0]=c.conkey[1]);` returns 0 rows; InnoDB creates the FK index by itself [NV] · Source B1, B12.

**DB-IDX-03** — In composite indexes put first the columns filtered by equality and then the range or order one; keep them to three columns or fewer unless there is evidence. · How C+J · criterion P9 · Check: `EXPLAIN` shows an `Index Cond` over every equality column: PG `EXPLAIN SELECT … WHERE tenant_id=$1 AND estado=$2 ORDER BY creado_en DESC LIMIT 20;` over `(tenant_id, estado, creado_en)` · Source B12, B15.

**DB-IDX-04** — On hot queries fetch only the necessary columns; when the plan justifies it, cover them with `INCLUDE` for an index-only scan. · How C · criterion P11 · Check: `rg -n -i "select\s+\*" src/` (and, in ORMs, whole-entity loads in list endpoints); PG `CREATE INDEX CONCURRENTLY … ON pedidos (cliente_id) INCLUDE (total, estado);` and look for `Index Only Scan` in `EXPLAIN`; SQL Server `INCLUDE` too; MySQL has no `INCLUDE`: add the column to the key [NV] · Source B1, B12, B3.

**DB-IDX-05** — Before accepting a new or modified query on a hot path, look at its plan with realistic volume and compare estimated against actual rows. · How C · criterion P9 · Check: the plan saved in the plan or PR, no `Seq Scan` over large tables on the hot query: PG `EXPLAIN (ANALYZE, BUFFERS) SELECT …;` for DML `BEGIN; EXPLAIN ANALYZE UPDATE …; ROLLBACK;` (ANALYZE **executes** the statement). MySQL 8 `EXPLAIN ANALYZE SELECT …;` / `EXPLAIN FORMAT=TREE` [NV]. SQL Server `SET STATISTICS IO, TIME ON;` plus the actual plan [NV] · Source B12.

**DB-IDX-06** — No N+1: a collection is loaded with a join, `IN (…)` or the ORM's eager load, not with one query per row. · How T · criterion P10 · Check: a test counts the queries per request: listing N items emits a constant number. Django `assertNumQueries`, Rails `bullet`, Hibernate `Statistics`, Prisma/TypeORM with a counting logger, or `pg_stat_statements.calls` before and after; the exact tool per ORM is [NV] · Source B1.

**DB-IDX-07** — Paginate by keyset (`WHERE (sort, id) < (:last_sort, :last_id) ORDER BY sort DESC, id DESC LIMIT n`), not with a large `OFFSET`; include a unique tiebreaker column in the order. · How C+T · criterion P11 · Check: `rg -n -i "offset\s" src/`; a test inserts rows between pages and checks for no duplicates or gaps. PG and MySQL support tuple comparison [NV MySQL]; SQL Server does not: expand to `a < x OR (a = x AND id < y)` · Source B1.

**DB-IDX-08** — Every `ORDER BY` + `LIMIT` over a large table has an index that delivers that order. · How C · criterion none · Check: the plan shows no `Sort` over millions of rows before the `Limit` · Source B1.

**DB-IDX-09** — Do not wrap indexed columns in functions in the `WHERE` (`lower(email) = …`, `date(created) = …`); use an expression index or rewrite as a range. · How C · criterion none · Check: `rg -n -i "where\s+(lower|upper|date|cast)\(" src/` · Source B1 [NV detail].

**DB-IDX-10** — Text search with a text index (GIN/`tsvector`, FULLTEXT) or a search engine, not `LIKE '%x%'`. · How C · criterion none · Check: `rg -n -i "like\s+'%|ilike\s+'%" src/` · Source B3.

## 3. Transactions and concurrency

**DB-TX-01** — Know and declare the isolation level: Read Committed is the default in Postgres (and SQL Server), Repeatable Read in MySQL/InnoDB. If an operation reads, decides and writes, choose explicitly how to avoid the lost update / write skew. · How J+T · criterion none · Check: the plan says which anomaly is avoided and with what; a concurrency test with two simultaneous transactions. PG `SHOW default_transaction_isolation;` MySQL `SELECT @@transaction_isolation;` SQL Server `DBCC USEROPTIONS;` · Source B12, B2 [NV write skew; NV MySQL and SQL Server defaults].

**DB-TX-02** — Under Repeatable Read/Serializable, retry the whole transaction on a serialization error (`40001`) and a deadlock (`40P01` in PG; 1213 in MySQL; 1205 in SQL Server), with a limit and backoff. · How T · criterion none · Check: a test forces the conflict and expects success after the retry; `rg -n "40001|SerializationFailure|deadlock" src/` finds the handler if that level is used · Source B12 [NV MySQL and SQL Server codes].

**DB-TX-03** — For concurrent updates of one record edited by users, use optimistic locking with a `version` column (`UPDATE … SET …, version = version + 1 WHERE id = $1 AND version = $2`, 0 rows = conflict); for counters, an atomic update (`SET stock = stock - 1 WHERE stock > 0`), never read-add-write in the application. · How T · criterion E3 · Check: a test with two concurrent writers: one gets a conflict, the final value is right; `rg -n "version\s*=\s*version\s*\+\s*1|FOR UPDATE" src/` · Source B2 [NV], B25.

**DB-TX-04** — Every retryable operation that produces effects (charges, sends, creation through an API) accepts an idempotency key, persisted with a unique index per user/client, with the response stored, a 409 if reused with other parameters, and a defined expiry. · How T · criterion E4 · Check: a test: the same request twice with the same key gives one effect and the same response; the same key with another body gives 409. PG `CREATE UNIQUE INDEX ON idempotency_keys (user_id, idempotency_key);` · Source B25.

**DB-TX-05** — Call no external service inside an open database transaction; split into atomic phases with a persisted recovery point. · How J+C · criterion P13 · Check: review: no HTTP or queue inside a `transaction` block. In operation, PG `SELECT pid, state, xact_start FROM pg_stat_activity WHERE state='idle in transaction';` empty or brief; `idle_in_transaction_session_timeout` set per role · Source B25, B12.

**DB-TX-06** — To publish events or enqueue jobs from a data change use an outbox / staged jobs: write the message into a table in the same transaction and publish with a separate relay; consumers are idempotent. · How T · criterion P13 · Check: a test: rollback leaves no message, commit leaves one in the outbox, the consumer processing the same id twice leaves one effect. NoSQL: the outbox is a property of the document · Source B23, B25.

**DB-TX-07** — Keep transactions short and with no user wait; take locks in a consistent order to avoid deadlocks. · How C · criterion none · Check: PG `SELECT * FROM pg_stat_activity WHERE xact_start < now() - interval '1 minute';` MySQL `SELECT * FROM information_schema.innodb_trx WHERE trx_started < NOW() - INTERVAL 1 MINUTE;` [NV] · Source B12, B7 [NV].

## 4. Migrations

**DB-MIG-01** — Every schema and reference-data change is a versioned migration in the repo, applied by a tool, never a manual change in an environment. · How C · criterion O28 · Check: an environment's schema equals the one of the migrations applied to an empty database: PG `pg_dump --schema-only` of both and `diff`; MySQL `mysqldump --no-data`; SQL Server `sqlpackage /Action:Extract` or SSDT [NV]. A migration that exists in main is never edited: another is added (DB-MIG-12) · Source B5.

**DB-MIG-02** — Make incompatible changes with expand / migrate / contract: add the new, write to both and backfill, move the reads, and only in a later release drop the old. Never rename or change the type of a column in use in one step. · How C+J · criterion P4 · Check: `squawk` rules `renaming-column`, `changing-column-type`, `ban-drop-column`; review: the migration that drops does not ship in the same release as the code that stops using the column · Source B6, B15, B4.

**DB-MIG-03** — Create and drop indexes without blocking writes: `CREATE INDEX CONCURRENTLY` (outside a transaction) in Postgres; `ALGORITHM=INPLACE, LOCK=NONE` in MySQL; `ONLINE = ON` in SQL Server (editions that support it) [NV]. If a `CONCURRENTLY` fails, drop the `INVALID` index and retry. · How C · criterion P12 · Check: `squawk migrations/*.sql` (`require-concurrent-index-creation`); PG after deploy `SELECT indexrelid::regclass FROM pg_index WHERE NOT indisvalid;` returns 0 rows · Source B12, B14, B15.

**DB-MIG-04** — Add FK, CHECK and NOT NULL over existing tables in two steps: create `NOT VALID` and validate in a separate migration (NOT NULL through a validated CHECK and then `SET NOT NULL`). · How C · criterion P12 · Check: `squawk` (`constraint-missing-not-valid`, `adding-not-nullable-field`); PG `ALTER TABLE t ADD CONSTRAINT fk … FOREIGN KEY (…) REFERENCES … NOT VALID;` then `ALTER TABLE t VALIDATE CONSTRAINT fk;` MySQL has no safe equivalent for CHECK · Source B15, B16.

**DB-MIG-05** — Every migration sets a short `lock_timeout` (about 5–10 s) so that traffic does not queue behind a lock, and a `statement_timeout` that fits its duration. · How C · criterion P12 · Check: `squawk` (`require-lock-timeout`, `require-timeout-settings`); PG `SET lock_timeout = '10s';` at the start or `ALTER ROLE migrator SET lock_timeout = '10s';` MySQL `SET SESSION lock_wait_timeout = 10;` [NV value]. SQL Server `SET LOCK_TIMEOUT 10000;` [NV] · Source B15, B16, B12.

**DB-MIG-06** — In MySQL, declare `ALGORITHM` and `LOCK` on every `ALTER TABLE` so that it fails instead of copying the table with a lock; for large tables that need `COPY` use gh-ost (or pt-online-schema-change [NV]). · How C · criterion P12 · Check: `rg -n -i "alter table" migrations/ | rg -v -i "algorithm="` returns 0 lines · Source B14, B17.

**DB-MIG-07** — Backfill in batches, idempotent, with a pause between batches and outside the DDL transaction; never an `UPDATE` with no `WHERE` over a whole large table. · How C+T · criterion none · Check: `rg -n -i "update\s+\w+\s+set" migrations/` reviewed; a test that the backfill run twice leaves the same result · Source B15.

**DB-MIG-08** — Add columns with a volatile default (`now()`, `gen_random_uuid()`) in three steps: column with no default, default apart, backfill. · How C · criterion none · Check: `squawk` (`adding-field-with-default`) · Source B15, B16.

**DB-MIG-09** — Every migration has a tested way back: a `down` that runs, or an explicit statement that it is irreversible with the plan (restore/PITR). In the expand phase the rollback is going back to the previous code. · How T · criterion P5 · Check: CI `migrate up` → `migrate down` → `migrate up` over an empty database and one with test data. `npx prisma migrate reset` / `alembic downgrade -1 && alembic upgrade head` / `flyway undo` (Flyway undo is a paid edition [NV]) · Source B5, B4, B6.

**DB-MIG-10** — Test the migrations in CI against the same engine and version as production (not SQLite as a substitute), and before the deploy against a copy of production or a representative volume, measuring duration and locks. · How C · criterion P5 · Check: a pipeline with the engine container pinned by version; the migration time recorded over the latest restore (which also tests the backup, DB-OPS-05). PG `SELECT pid, mode, relation::regclass FROM pg_locks WHERE NOT granted;` during the rehearsal · Source B5, B12, B17.

**DB-MIG-11** — Never delete data (`DROP`, `TRUNCATE`, a mass `DELETE`) in a migration without a verified backup beforehand and explicit human approval. · How C · criterion P4 · Check: `squawk` (`ban-drop-table`, `ban-drop-column`, `ban-truncate-cascade`); `rg -n -i "drop table|truncate|drop column" migrations/` each finding with a recorded approval · Source B24, B20.

**DB-MIG-12** — A migration that exists on the main branch is immutable: never edit, rename, move, reorder or delete it; a correction is a new migration. This holds even if “nobody has applied it yet”: main is assumed applied everywhere. A migration created in the branch is not in main and can still be edited; a branch already deployed to a shared environment takes that branch as its base, by process [NV]. · How C · criterion P16 · Check: agnostic `git diff --name-status -M --diff-filter=MDRT "$(git merge-base origin/main HEAD)" -- migrations/` prints nothing (it compares the working tree too, so uncommitted edits count; in CI the clone needs the history of main, `fetch-depth: 0`). The kit blocks the write with `guard.mjs` and `guard-shell.mjs` and reports it at the close with `required.mjs` (base: the merge-base with `origin/main`, else `main`, else `master`, else what HEAD tracks). Per tool, as a second layer that only works against a database that already applied the file: Flyway `flyway validate` (CRC32 checksums), Liquibase `liquibase update` halts on a changed changeset, Atlas `atlas migrate validate` and `non_linear { error = true, on_edit = ERROR }` in `atlas migrate lint --git-base main`, Prisma `prisma migrate status` exits 1 on diverged history. Django, Alembic, EF Core, Rails, golang-migrate and Knex have no content checksum [NV], so the git check is the only one · Source B28, B32, B33, B34, B35, B41, B50, B52, B5.

**DB-MIG-13** — Never silence an integrity error to make a migration “apply”: `flyway repair`, `liquibase clear-checksums`, `<validCheckSum>`, `atlas migrate hash` over an existing file, `prisma migrate reset` / `migrate resolve`, `alembic stamp`, deleting rows of the history table. Each needs a person's recorded approval. · How C+J · criterion P16 · Check: `rg -n "flyway.* repair|clear-checksums|validCheckSum|migrate hash|migrate reset|migrate resolve|alembic stamp" .github/ scripts/ Makefile package.json` has no finding outside an approved runbook; `guard-shell.mjs` blocks those commands in an agent session · Source B28, B32, B35, B41, B42.

**DB-MIG-14** — New migrations sort strictly after the last migration of main and the history has one head: no timestamp or sequence number below main's last, no two migrations with the same sequence, one Alembic head, no conflicting Django leaves. Re-check against the current tip of main before merging, not only against the merge-base. · How C · criterion P16 · Check: agnostic, the new files (`git diff --name-only --diff-filter=A "$BASE" HEAD -- migrations/` plus the untracked ones) are `>` the last file of `origin/main` (`git ls-tree -r --name-only origin/main -- migrations/ | LC_ALL=C sort | tail -1`; `sort -V` with unpadded integers [NV]) and `ls migrations | sed 's/_.*//' | sort | uniq -d` is empty; `required.mjs` computes both over the diff. Alembic `test "$(alembic heads | wc -l)" -eq 1` [NV the exact line count: `heads` may print extra lines with `--verbose`]; Django `python manage.py makemigrations --check --dry-run` fails on unmerged leaf nodes [NV]; Flyway keep `outOfOrder=false` (the default) and run `validate`; Atlas keep `--exec-order linear` (the default) and lint `non_linear { error = true }`; EF Core 11 leaves a snapshot conflict on merge · Source B29, B34, B37, B45, B46, B47, B51, B56.

**DB-MIG-15** — Prove that the migrations new in the branch apply on top of main's last state **with data**, not only from an empty database: check out the merge-base, migrate, load representative seed data, switch to the branch, apply only the new migrations, run the tests. The seed is versioned and holds the cases that break DDL: populated tables, NULLs, duplicates, rows that look orphaned. · How T · criterion P16 · Check: the stack's command (item Q19) in CI and in the plan's Verification under the name `migrate-upgrade`: `git worktree add ../_base "$(git merge-base origin/main HEAD)"`, migrate there, load the seed, apply the branch's new files in order, run the suite. For `NOT NULL`, `UNIQUE`, `FK`, `CHECK`, type changes and backfills the seed holds a row that would violate them; the test fails if the seed table is empty. `required.mjs` asks for the log of that run on the code as it is now · Source B57, B5, B44, B33, B34.

**DB-MIG-16** — The application version on main (N-1) keeps working against the schema of the branch (N): run main's test suite against a database migrated by the branch, and the branch's suite against main's schema when the change is a contract step. · How T · criterion P4 · Check: a CI job: worktree at the merge-base, its test configuration pointed at the database produced in DB-MIG-15, its suite run; a failure means the change is not expand-compatible (DB-MIG-02) [NV: no source describes this exact job; it follows from Parallel Change and the transition phase] · Source B6, B5, B4, B59, B56.

**DB-MIG-17** — On a conflict between branches (same sequence, out of order, two heads, diverged snapshot) the **branch's** migration is regenerated or renumbered on top of main's; main's is never touched, and the file is never merged by “keeping both”. · How J+C · criterion P16 · Check: after the fix DB-MIG-12 and DB-MIG-14 pass and DB-MIG-15 is run again; Alembic `alembic merge heads -m "merge"` and Django `makemigrations --merge` are the exception that adds a join revision, both new files; EF Core: abort the merge, remove your migration keeping the model, merge, add it again · Source B51, B45, B47, B35.

**DB-MIG-18** — A migration is self-contained: it does not import the application's current models, services or enums, so an old migration keeps running after the code changes. Use SQL or the historical models of the tool. · How C · criterion none · Check: Django `rg -n "^from (app|myapp)\.models|import .*\.models" */migrations/` finds nothing (use `apps.get_model`); EF Core: no `DbContext` or entity types in `Up`/`Down` for data moves; `rg -n "from app|import app" migrations/` for Alembic, Knex and Prisma seed code · Source B45, B50.

**DB-MIG-19** — The migration history matches the model: no model change without its migration, and no migration that the model would not generate. · How C · criterion P16 · Check: Django `makemigrations --check --dry-run`; Alembic `alembic check` [NV that it exits non-zero]; EF Core `dotnet ef migrations has-pending-model-changes`; Prisma `prisma migrate diff --from-migrations prisma/migrations --to-schema prisma/schema.prisma --exit-code` (exit 2 = drift; v6 needs `--shadow-database-url`); Atlas `atlas migrate diff` creates no file [NV as a check]; agnostic: the DB-MIG-01 schema dump diff · Source B46, B48, B50, B42, B38, B5.

**DB-MIG-20** — Squash or baseline only as a human-approved card of its own, in two releases: the squashed migration ships next to the old ones (`replaces` in Django; the baseline row in `__EFMigrationsHistory`, `flyway baseline`, `prisma migrate resolve --applied`, an Atlas checkpoint), every environment is confirmed to have applied the old ones, and only then the old files go. Both paths are tested: a new database from the squash, and an existing database with the history already applied. · How J+T · criterion P16 · Check: the plan names the environments and the last version applied in each; CI runs “empty → squash” and “main's state → squash” and compares the `pg_dump --schema-only` of both; DB-MIG-12 is waived only for that card, recorded in the plan · Source B45, B50, B49, B43, B39, B31 [NV for the Flyway text].

## 5. Operation

**DB-OPS-01** — Use a small, sized connection pool (starting point `cores × 2 + disks`) with a timeout to obtain a connection; behind many processes, a pooler (PgBouncer / ProxySQL / RDS Proxy [NV]). · How C · criterion E8 · Check: PG `SELECT count(*), state FROM pg_stat_activity GROUP BY state;` against `SHOW max_connections;` MySQL `SHOW STATUS LIKE 'Threads_connected';` · Source B27.

**DB-OPS-02** — Set `statement_timeout` / `lock_timeout` / `idle_in_transaction_session_timeout` per role or session of the application (not global on the server). · How C · criterion E8 · Check: PG `SELECT rolname, rolconfig FROM pg_roles WHERE rolname='app';` lists the timeouts. MySQL `max_execution_time`, `lock_wait_timeout`. SQL Server: command timeout in the client plus `LOCK_TIMEOUT` [NV] · Source B12, B15.

**DB-OPS-03** — Have query observability: statistics per normalized query and a slow-query log, with a defined threshold. · How C · criterion O19 · Check: PG `SELECT query, calls, mean_exec_time FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;` plus `log_min_duration_statement`. MySQL `slow_query_log=ON`, `long_query_time`, `performance_schema.events_statements_summary_by_digest` [NV]. SQL Server Query Store (`sys.query_store_runtime_stats`) [NV] · Source B12, B7 [NV].

**DB-OPS-04** — Define RPO and RTO per database from the business criticality, and choose backups/replication that meet them (PITR if RPO is under 24 h). · How J · criterion P7 · Check: an operations document with RPO/RTO signed off; a backup configuration coherent with it (frequency at most the RPO) · Source B20, B21.

**DB-OPS-05** — Test the backups by restoring them, periodically and automatically, in a separate environment, querying the restored data (the last expected row, counts, checksums) and measuring the time against the RTO; alert if the restore fails or does not run. · How C+T · criterion P7 · Check: a scheduled job: restore → validation queries → record the duration → alert. PG `pg_restore -d restore_check backup.dump && psql -d restore_check -c "SELECT max(created_at) FROM orders;"`. MySQL: restore of `mysqldump`/XtraBackup plus the same query [NV tools]. SQL Server: `RESTORE VERIFYONLY` is not enough: restore and query [NV] · Source B20, B24, B21.

**DB-OPS-06** — Encrypt and protect the backups, keep them outside the primary account/region, and do not consider them replaced by replicas. · How C+J · criterion P7 · Check: verify encryption and location in the provider's configuration · Source B20, B19, B24.

**DB-OPS-07** — Define retention per type of data (operational, backups, logs, PII) and automate the purge. · How J+C · criterion P7 · Check: a purge job with a test; the written policy · Source B21, B24, B19.

**DB-OPS-08** — Validate critical invariants out of band (cross counts, references between stores) and alert on divergence. · How C · criterion none · Check: a job that runs invariant queries and fails if they return rows · Source B24.

**DB-OPS-09** — Keep statistics and vacuum up to date (autovacuum on; `ANALYZE` after mass loads). · How C · criterion none · Check: PG `SELECT relname, last_autovacuum, last_autoanalyze, n_dead_tup FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 10;` MySQL `ANALYZE TABLE t;` · Source B12.

## 6. Security

**DB-SEC-01** — Always use parameterized queries (or the query builder/ORM without interpolation); never concatenate or interpolate input into SQL. · How C+T · criterion S3 · Check: `rg -n -e "(query|execute|raw|sql)\s*\(\s*[\`'\"].*\$\{" -e "f\"(SELECT|INSERT|UPDATE|DELETE)" -e "\+\s*req\.(query|body|params)" src/` and review each line; a test with the payload `' OR '1'='1` over each endpoint with filters; `semgrep --config p/sql-injection` [NV ruleset name] · Source B18, B3.

**DB-SEC-02** — For what cannot be parameterized (sort column, direction, table), use an allow-list against fixed values. · How T+C · criterion S3 · Check: a test: `?sort=name;DROP` gives 400; `rg -n "ORDER BY \$\{|ORDER BY \" ?\+" src/` · Source B18.

**DB-SEC-03** — Do not escape by hand as a defense; escaping is a last resort and discouraged. · How C · criterion S3 · Check: `rg -n -i "escape(String|Sql)|mysql_real_escape|replace\(\"'\"" src/` · Source B18.

**DB-SEC-04** — The application connects with its own least-privilege user (DML over its tables), distinct from the migrations user; never superuser, `root`, `sa` or the owner of the database. · How C · criterion S20 · Check: PG `SELECT rolname, rolsuper, rolcreaterole, rolcreatedb FROM pg_roles WHERE rolname = current_user;` all `f`; `SELECT tableowner FROM pg_tables WHERE schemaname='public';` is not the app's user. MySQL `SHOW GRANTS FOR CURRENT_USER();` with no `ALL`, `SUPER`, `FILE`, `GRANT OPTION`. SQL Server `SELECT IS_SRVROLEMEMBER('sysadmin'), IS_ROLEMEMBER('db_owner');` gives 0 · Source B19, B18.

**DB-SEC-05** — Credentials outside the code and the repo (a secrets manager or environment variables), with rotation; separate accounts and databases per environment. · How C · criterion S9 · Check: `gitleaks detect` / `rg -n -i "(postgres|mysql|sqlserver)://[^:]+:[^@]+@" .` returns 0 · Source B19.

**DB-SEC-06** — Require TLS on connections and verify the server certificate; no `trust` over TCP in Postgres. · How C · criterion none · Check: connection string with `sslmode=verify-full` (PG) / `ssl-mode=VERIFY_IDENTITY` (MySQL) / `Encrypt=True;TrustServerCertificate=False` (SQL Server) [NV exact MySQL and SQL Server names]; PG `SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid();` is `t`; `rg -n "trust" pg_hba.conf` · Source B19, B11.

**DB-SEC-07** — Classify PII when modeling: minimize what is stored, encrypt at rest (disk/backup) and sensitive data at column level, never store passwords but hashes with a password algorithm, do not dump it to logs, and have a delete/anonymize path. · How J+T+C · criterion P15 · Check: an inventory of PII columns in the plan; a test that deleting a user removes/anonymizes their PII including derived tables; `rg -n -i "password" migrations/` only `password_hash`. The OWASP Password Storage and User Privacy cheat sheets are reference [NV, not opened] · Source B19, B3, B13.

**DB-SEC-08** — The database is not reachable from the Internet nor from the client: only the API talks to it. · How C · criterion none · Check: a network/firewall rule; no database secret in the frontend bundle: `rg -n -i "DATABASE_URL" dist/ build/ public/` returns 0. NoSQL: injection exists too (`$where`, `$ne` operators in Mongo); apply the NoSQL Security Cheat Sheet that B19 references · Source B19.

## 7. Data ownership

**DB-OWN-01** — Each module/service owns its tables and is the only one that writes them; the others read through its API, events or a view explicitly published as a contract. · How C+J · criterion D11 · Check: an ownership map table → module in the repo (the table of `system-design.md`); search for cross references: `rg -n "FROM\s+(other_module\.|foreign_table)" src/module_x/` · Source B22, B23.

**DB-OWN-02** — Do not share schema or tables between separately deployed services; sharing the physical server is allowed. Isolate with a schema and a database user per service with restricted grants. · How C · criterion D11 · Check: PG `SELECT grantee, table_schema, privilege_type FROM information_schema.role_table_grants WHERE grantee='svc_orders' AND table_schema <> 'orders';` returns 0 rows · Source B22, B23.

**DB-OWN-03** — For consistency between services use events with an outbox, sagas or compensating transactions; no distributed transactions (2PC) nor joins across databases. · How J · criterion none · Check: design review · Source B22, B23.

**DB-OWN-04** — One source of truth per entity; the copies in other services are derived, eventually consistent and rebuildable. · How J · criterion none · Check: the plan names the source of truth and how the copy is rebuilt · Source B22, B2 [NV].

**DB-OWN-05** — Inside a monolith, each module's data access lives in its data access layer; no SQL scattered in controllers or views. · How C · criterion D11 · Check: `rg -n -i "select .* from|insert into|update .* set" src/ --glob "!**/repositories/**" --glob "!**/migrations/**"` · Source B5.

## 8. Engine choice

**DB-ENG-01** — Choose by default a mature relational database the team knows (PostgreSQL, or MySQL/SQL Server if it is the organization's standard); a new engine is justified in writing with the requirement the relational one does not meet. · How J · criterion D14 · Check: a recorded decision (the ADR template) that names the requirement, the known failure mode and who operates it · Source B26, B22, B2 [NV].

**DB-ENG-02** — Before adding another store, test whether the relational one covers it: JSONB for semi-structured data, native text search, queue tables with `SKIP LOCKED` [NV this session], native partitioning. · How J · criterion D14 · Check: the ADR lists what was tried · Source B26, B25.

**DB-ENG-03** — Use NoSQL when the requirement really asks for it and name which: documents for aggregates read whole with no joins or referential integrity (the “package service” case of B22); key-value (Redis) for ephemeral state or a high-throughput cache; columnar/data lake for analytics; time series for metrics. Design the model from the queries and assume that the integrity the engine does not give is given by the code and its tests. · How J · criterion D14 · Check: the ADR lists the queries and how each invariant is guaranteed · Source B22.

**DB-ENG-04** — A cache is not a source of truth: whatever lives only in Redis/memory can be lost and rebuilt. · How J+T · criterion D14 · Check: a test: emptying the cache neither breaks nor loses data · Source B22.

## Sources

- B1 — Markus Winand, *Use The Index, Luke* / *SQL Performance Explained* — https://use-the-index-luke.com/
- B2 — Martin Kleppmann (and Chris Riccomini, 2nd ed.), *Designing Data-Intensive Applications* — https://dataintensive.net/ · https://martin.kleppmann.com/2026/03/24/designing-data-intensive-applications-2e.html
- B3 — Bill Karwin, *SQL Antipatterns, Volume 1*, Pragmatic Bookshelf, 2022 — https://pragprog.com/titles/bksap1/sql-antipatterns-volume-1/
- B4 — Scott Ambler and Pramod Sadalage, *Refactoring Databases*, Addison-Wesley, 2006 — https://www.martinfowler.com/books/refactoringDatabases.html
- B5 — Pramod Sadalage and Martin Fowler, “Evolutionary Database Design”, 2016 — https://martinfowler.com/articles/evodb.html
- B6 — Danilo Sato, “Parallel Change” (expand / migrate / contract), 2014 — https://martinfowler.com/bliki/ParallelChange.html
- B7 — Laine Campbell and Charity Majors, *Database Reliability Engineering*, O'Reilly, 2017 — https://www.oreilly.com/library/view/database-reliability-engineering/9781491925935/
- B8 — Michael J. Hernandez, *Database Design for Mere Mortals*, 4th ed. — https://www.informit.com/store/database-design-for-mere-mortals-9780136788096
- B9 — E. F. Codd, “A Relational Model of Data for Large Shared Data Banks”, CACM 13(6), 1970 — https://doi.org/10.1145/362384.362685
- B10 — C. J. Date, *Database Design and Relational Theory*, 2nd ed., Apress, 2019 — https://www.oreilly.com/library/view/-/9781484255407/
- B11 — PostgreSQL wiki, “Don't Do This” — https://wiki.postgresql.org/wiki/Don't_Do_This
- B12 — PostgreSQL documentation: multicolumn indexes, CREATE INDEX, EXPLAIN, isolation, timeouts, pg_stat_statements — https://www.postgresql.org/docs/current/indexes-multicolumn.html · https://www.postgresql.org/docs/current/sql-createindex.html · https://www.postgresql.org/docs/current/using-explain.html · https://www.postgresql.org/docs/current/transaction-iso.html · https://www.postgresql.org/docs/current/runtime-config-client.html · https://www.postgresql.org/docs/current/pgstatstatements.html
- B13 — Silvia Botros and Jeremy Tinley, *High Performance MySQL*, 4th ed., O'Reilly, 2021 — https://www.oreilly.com/library/view/-/9781492080503
- B14 — MySQL 8.4 documentation, “Online DDL Operations” — https://dev.mysql.com/doc/refman/8.4/en/innodb-online-ddl-operations.html
- B15 — strong_migrations (Andrew Kane) — https://github.com/ankane/strong_migrations
- B16 — Squawk, a migration linter for Postgres — https://squawkhq.com/docs/rules
- B17 — gh-ost (GitHub) — https://github.com/github/gh-ost
- B18 — OWASP SQL Injection Prevention Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
- B19 — OWASP Database Security Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/Database_Security_Cheat_Sheet.html
- B20 — AWS Well-Architected, Reliability, REL09 “Back up data” and REL09-BP04 — https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/back-up-data.html · https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_backing_up_data_periodic_recovery_testing_data.html
- B21 — Azure Well-Architected, “Architecture strategies for disaster recovery” (RE:09) — https://learn.microsoft.com/en-us/azure/well-architected/reliability/disaster-recovery
- B22 — Azure Architecture Center, “Data considerations for microservices” — https://learn.microsoft.com/en-us/azure/architecture/microservices/design/data-considerations
- B23 — Chris Richardson, microservices.io: “Database per service” and “Transactional outbox” — https://microservices.io/patterns/data/database-per-service.html · https://microservices.io/patterns/data/transactional-outbox.html
- B24 — Google SRE Book, ch. 26 “Data Integrity: What You Read Is What You Wrote” — https://sre.google/sre-book/data-integrity/
- B25 — Brandur Leach (Stripe), “Designing robust and predictable APIs with idempotency”, “Implementing Stripe-like Idempotency Keys in Postgres”, “Transactionally Staged Job Drains in Postgres” — https://stripe.com/blog/idempotency · https://brandur.org/idempotency-keys · https://brandur.org/job-drain
- B26 — Dan McKinley, “Choose Boring Technology”, 2015 — https://mcfunley.com/choose-boring-technology
- B27 — HikariCP wiki, “About Pool Sizing” — https://github.com/brettwooldridge/HikariCP/wiki/About-Pool-Sizing
- B28 — Flyway, `validate` — https://documentation.red-gate.com/fd/validate-277578898.html
- B29 — Flyway, `outOfOrder` — https://documentation.red-gate.com/fd/flyway-out-of-order-setting-277579015.html
- B30 — Flyway, `ignoreMigrationPatterns` — https://documentation.red-gate.com/fd/flyway-ignore-migration-patterns-setting-277579002.html
- B31 — Flyway, `baseline` (seen only in search results) — https://documentation.red-gate.com/fd/baseline-277578867.html
- B32 — Liquibase, changeset checksums — https://docs.liquibase.com/concepts/changelogs/changeset-checksums.html
- B33 — Atlas, `migrate lint` — https://atlasgo.io/versioned/lint
- B34 — Atlas, analyzers (`non_linear`, `destructive`, `data_depend`, `incompatible`) — https://atlasgo.io/lint/analyzers
- B35 — Atlas, migration directory integrity (`atlas.sum`) — https://atlasgo.io/concepts/migration-directory-integrity
- B36 — Atlas, CLI reference (`migrate validate|hash|test|checkpoint|status`) — https://atlasgo.io/cli-reference
- B37 — Atlas, `migrate apply` (`--baseline`, `--exec-order`) — https://atlasgo.io/versioned/apply
- B38 — Atlas, `migrate diff` — https://atlasgo.io/versioned/diff
- B39 — Atlas, checkpoints — https://atlasgo.io/versioned/checkpoint
- B40 — Atlas, agent skills for schema migrations — https://www.atlasgo.io/guides/ai-tools/agent-skills
- B41 — Prisma, troubleshooting (history conflicts, drift) — https://www.prisma.io/docs/orm/v6/prisma-migrate/workflows/troubleshooting
- B42 — Prisma, CLI reference (`migrate diff --exit-code`, `status`, `deploy`, `resolve`) — https://www.prisma.io/docs/orm/reference/prisma-cli-reference · mental model https://www.prisma.io/docs/orm/prisma-migrate/understanding-prisma-migrate/mental-model
- B43 — Prisma, baselining (through search) — https://www.prisma.io/docs/orm/prisma-migrate/workflows/baselining
- B44 — Prisma, “What to Put in Your AGENTS.md So Your Agent Handles the Database Right” — https://www.prisma.io/blog/agents-md-for-databases
- B45 — Django, Migrations — https://docs.djangoproject.com/en/stable/topics/migrations/
- B46 — Django, `django-admin` (`makemigrations --check/--merge`, `migrate --check`) — https://docs.djangoproject.com/en/stable/ref/django-admin/
- B47 — Alembic, Working with Branches — https://alembic.sqlalchemy.org/en/latest/branches.html
- B48 — Alembic, commands API (`check`, `heads`) — https://alembic.sqlalchemy.org/en/latest/api/commands.html
- B49 — Alembic, cookbook — https://alembic.sqlalchemy.org/en/latest/cookbook.html
- B50 — EF Core, Managing Migrations — https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/managing
- B51 — EF Core, Migrations in Team Environments — https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/teams
- B52 — Rails Guides, Active Record Migrations — https://guides.rubyonrails.org/active_record_migrations.html
- B53 — golang-migrate, MIGRATIONS.md — https://github.com/golang-migrate/migrate/blob/master/MIGRATIONS.md
- B54 — Knex, Migrations — https://knexjs.org/guide/migrations.html
- B55 — Sqitch, tutorial — https://sqitch.org/docs/manual/sqitchtutorial/
- B56 — GitLab, Migration style guide — https://docs.gitlab.com/development/migration_style_guide/
- B57 — GitLab, `db:migrate:multi-version-upgrade` job — https://docs.gitlab.com/development/database/dbmigrate_multi_version_upgrade_job/
- B58 — Prisma, team development (the “contract” flow) — https://www.prisma.io/docs/orm/prisma-migrate/workflows/team-development
- B59 — Jacqueline Xu (Stripe), “Online migrations at scale”, 2017 — https://stripe.com/blog/online-migrations

## Not verified

- The inner content of the books (Kleppmann, Karwin beyond the index, Campbell and Majors, Hernandez, Codd, *High Performance MySQL*): only their records and tables of contents were checked. The rules that depend only on them are marked [NV].
- The “transition period” of *Refactoring Databases*: it did not appear in the pages opened.
- The individual description of each squawk rule: only the names were verified.
- MySQL and SQL Server commands and defaults outside Online DDL (default isolation, `sys.schema_unused_indexes`, slow log, Query Store, `ONLINE = ON`, deadlock codes, TLS connection parameters): general knowledge, not opened.
- The tools that count queries per ORM (N+1) and the semgrep ruleset name.
- The OWASP Password Storage and User Privacy cheat sheets: referenced, not opened.
- That Django, Alembic, EF Core, Rails, golang-migrate and Knex have no content check of an applied migration: the docs read do not mention one, which is not proof it does not exist. Liquibase's `validate` command was not opened.
- Django `makemigrations --check` failing on unmerged leaf nodes, and `alembic check` exiting non-zero (its page does not say); `alembic heads | wc -l` as “one head” depends on the output format.
- The default of `on_edit` in the Atlas `non_linear` analyzer, whether `atlas migrate lint` without `--git-base` sees edits, and whether `atlas migrate validate` compares against a merge-base. Atlas lint and test need a Pro account according to their pages.
- Flyway: the literal text of `baseline` (seen in search snippets), `validate` rejecting an ignored migration by default, and custom validation rules being Teams-only.
- Prisma: the team-development page describes the new “contract” flow, not classic `migrate dev/deploy`; the `_prisma_migrations` checksum appears only in a third-party blog that is not cited; the baselining page was seen through a search summary.
- Sqitch: how change IDs are computed, and whether `sqitch.plan` detects edits. Rails: `ActiveRecord::PendingMigrationError` and `maintain_test_schema`.
- How Knex, Rails and golang-migrate behave with a migration whose version is below the last applied one.
- A CI job that runs main's suite against the branch's schema (DB-MIG-16) and a GitHub or Shopify source for “upgrade from main”: none found; the GitLab job (B57) is the closest primary source.
- Empirical studies of agents editing applied migrations: none found. The failure modes behind DB-MIG-12, 13 and 14 —fixing a test by editing the migration, silencing a checksum with a repair command, generating from a stale main, testing only from empty— are inference, except what B40 and B44 state.
- The git commands of DB-MIG-12 and DB-MIG-14 and the seed-and-upgrade run of DB-MIG-15 were tried on Git Bash for Windows with sqlite3, not with PostgreSQL or MySQL; `sort -V` and shallow clones in CI were not tried.
- Pages of B28 to B59 were read through a tool that returns a model's summary of each page: the quotes are faithful to what it returned and were not checked against the raw HTML.
- None of the example commands was run against a database: they are syntax to validate on first use.
