# Db2 for Linux, UNIX and Windows: REORG-pending and locks

Load this when `migration-lint` reports a `db2-*` rule, or before writing DDL for a Db2 LUW table that holds real
data. Sources: IBM Docs, Db2 11.5, "ALTER TABLE statement" (REORG-recommended operations, constraints),
"CREATE INDEX statement", "locktimeout - Time to wait on a lock configuration parameter". Db2 for z/OS and Db2
for i are out of scope: z/OS materialises pending changes with the REORG utility (SQLCODE -20385) and has no
Docker image.

## Server version

`--server-version <v>` (`11.5` default, `11.1`, `10.5`). Without it the linter reads an
`icr.io/db2_community/db2` or `ibmcom/db2` image from a compose file or CI workflow next to the migrations.
Db2 files are recognised by `--#SET TERMINATOR`, `ADMIN_CMD`, `SYSPROC.`, `SYSIBM.`, `SET CURRENT LOCK TIMEOUT`,
`SET INTEGRITY` or `REORG TABLE`; `GENERATED ... IDENTITY` is not a marker (PostgreSQL has it). Otherwise pass
`--dialect db2` or `-- migration-lint: dialect db2`.

## REORG-recommended operations

`DROP COLUMN`, `ALTER COLUMN ... SET NOT NULL`, `DROP NOT NULL` and `SET DATA TYPE` (except increasing the
length of a `VARCHAR`, `VARGRAPHIC` or `VARBINARY`) put the table in REORG-pending state. Until a classic offline
`REORG TABLE` completes, most operations on it fail with SQLSTATE 57007 (table scans still work). At most three
units of work with such operations are allowed before the REORG is required (SQLSTATE 55019); several in one unit
of work count once. The linter counts units of work per table across the migrations of the run: with a runner
that wraps the file, a unit is the file (or the span between `COMMIT`s); otherwise each statement. A `SET DATA TYPE`
to a `VARCHAR`-family type is not counted, because whether it widens is not known without the earlier definition.

| Operation | Effect | Rule |
|---|---|---|
| REORG-recommended operation | table unusable until REORG | `db2-reorg-pending` (no `CALL SYSPROC.ADMIN_CMD('REORG TABLE t')` after it), `db2-reorg-limit` |
| `REORG TABLE` (classic) | rewrites the table; writers blocked. `INPLACE` cannot be used to leave the pending state | `db2-reorg-offline` |
| `ADD` FOREIGN KEY or CHECK | existing rows are checked at once (SQLSTATE 23512); `NOT ENFORCED` skips the check, `SET INTEGRITY` validates later | `db2-constraint-check` |
| `CREATE INDEX` | readers and writers are admitted during the build; writers are blocked at its end | none |
| Any DDL on an existing table | waits for its lock without limit: `locktimeout` defaults to -1 | `db2-lock-timeout` |

## Reading Db2 scripts

`--#SET TERMINATOR x` changes the statement terminator, so `BEGIN ATOMIC ... END` bodies keep their semicolons
(`db2 -td@ -f`). Liquibase reads `endDelimiter:`. Flyway, goose, dbmate and golang-migrate have no terminator
setting (`unsupported-separator`).

## Rehearsal

`rehearse.mjs --engine db2:11.5.9.0` runs `icr.io/db2_community/db2` with `--privileged`, `LICENSE=accept` and a
database, and reaches it with `su - db2inst1 -c "db2 -td~ -f"`. Locks are read from `MON_GET_LOCKS` (Z, X, S and
SIX on tables) for the session whose `CLIENT_APPLNAME` is `msafe-migration` (`WLM_SET_CLIENT_INFO`). After each
migration the tables with `REORG_PENDING = 'Y'` in `SYSIBMADM.ADMINTABINFO` are read: a migration that leaves one
is a problem (exit 1). Two self-tests run first, a held lock that must be seen and a `DROP COLUMN` on a probe
table that must show REORG-pending; either failing is exit 2. The container needs a private network (no outside
access) and many minutes to start, which is why it runs on a schedule and on demand in CI, not on every pull
request. See [rehearsal.md](rehearsal.md).
