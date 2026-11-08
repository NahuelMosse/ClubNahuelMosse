# Rehearsing a migration

Load this before rehearsing, or when a rehearsal result needs interpreting.

The linter reads text; only the database knows the data. An empty test database proves almost nothing:
NOT NULL, UNIQUE, foreign keys and type changes pass on zero rows and fail on the first real one.

## SQLite (bundled)

```bash
node "${CLAUDE_SKILL_DIR}/scripts/rehearse-sqlite.mjs" app.db db/migrations/0007_due.sql db/migrations/0008_x.sql
node "${CLAUDE_SKILL_DIR}/scripts/rehearse-sqlite.mjs" seed.sql 0007.up.sql --down 0007.down.sql   # up, down, up
node "${CLAUDE_SKILL_DIR}/scripts/rehearse-sqlite.mjs" seed.sql 0007.sql --down                     # down sections of a goose/dbmate file
```

Needs Node 22.13 or newer (`node:sqlite`). The database is copied with SQLite's own `VACUUM INTO`, so a
database in WAL mode is copied with its latest writes and the original is never opened for writing. A
`.sql` argument is loaded as a seed into an empty database.

For every migration it prints whether it ran, the time, and for **every table** its rows and the columns
that were added, dropped, retyped or emptied. It fails (exit 1) when:

- a migration does not run (the rest are then skipped, not run on top of a half-applied state);
- a table lost rows or was dropped with rows in it;
- a column that held values was dropped, or its non-NULL count went down. A dropped column is treated as a
  rename (`renamed to ...?`, not a loss) only when a new column of the same table has the same non-NULL
  count **and** the same value fingerprint (distinct count, total length, smallest and largest value). That
  is evidence, not proof: columns that hold the same constant look alike, so read the `renamed` lines;
- the migration created foreign-key orphans. Orphans already in the data do not count.

`--allow-loss tasks.priority,audit` marks intended losses (a contract step after approval).

The runner is detected from the first migration (`--runner` overrides): files are wrapped in a
transaction when the runner does that, and `PRAGMA foreign_keys` is set the way the runner sets it
(`--foreign-keys on|off` overrides). So a rebuild that relies on `PRAGMA foreign_keys=OFF` inside a
wrapped file shows the cascade deletes it would cause in production.

Exit 0 all ran and nothing was lost, 1 a migration failed or lost data, 2 could not run.

## PostgreSQL, MySQL, MariaDB, SQL Server, Oracle and Db2 (Docker)

Same engine and version as production, never SQLite as a stand-in. Images: `postgres`, `mysql`, `mariadb`,
`mcr.microsoft.com/mssql/server`, `gvenzl/oracle-free`, `icr.io/db2_community/db2` (`--engine mssql:2022-CU14-ubuntu-22.04`,
`oracle:23.5-slim-faststart`, `db2:11.5.9.0`). Per-engine details are in [mssql.md](mssql.md),
[oracle.md](oracle.md) and [db2.md](db2.md):

| Engine | Client | Seed and migrations | Locks read from | Edition |
|---|---|---|---|---|
| SQL Server | `sqlcmd` (tools18 or tools) | `GO` batches, SQLCMD commands | `sys.dm_tran_locks` (Sch-M, X, SIX, S; a queued Sch-M too) | `--edition standard` runs Express (2019, 2022) or Standard Developer (2025), `enterprise` Developer; the edition read back must match, else exit 2; Express stops at 10 GB per database |
| Oracle | `sqlplus -S -L` | rebuilt from the parsed statements, `/` after PL/SQL | `v$lock` (TM, modes 4 to 6), `dba_ddl_locks` | Free only: SE2 is not emulated and the run says ONLINE, MOVE ONLINE and `DBMS_REDEFINITION` pass here and fail on SE2 |
| Db2 | `db2 -td~` as `db2inst1` | rebuilt from the parsed statements | `MON_GET_LOCKS` (Z, X, S, SIX) | Community Edition; also reads `REORG_PENDING` after each migration |

Oracle and Db2 containers run on a private Docker network with no outside access (their instances do not start
without a non-loopback interface) instead of `--network none`; the network is named like the container and is
removed with it. SQL Server and Oracle keep their data on the container's disk (O_DIRECT is not available on a
memory-backed directory) and need several minutes for a first start; Db2 needs `--privileged`. Oracle and Db2 DDL
commits implicitly, so a failed migration leaves the statements before the failing one applied, and the output
says so.

```bash
node "${CLAUDE_SKILL_DIR}/scripts/rehearse.mjs" --engine postgres:16 seed.sql 0007.up.sql 0008.up.sql
node "${CLAUDE_SKILL_DIR}/scripts/rehearse.mjs" --engine mysql:8.4 --dump subset.sql.gz 0007.sql --down --lock-budget 1s
node "${CLAUDE_SKILL_DIR}/scripts/rehearse.mjs" --engine mariadb:11 seed.sql 0007.sql --keep
```

Needs only the `docker` CLI: the database is reached with `docker exec <container> psql|mysql`, no port is
published, and nothing but the standard images is used. The container is named `msafe-rehearse-<pid>-<id>`,
started fresh with no network (Oracle and Db2: a private `--internal` network, see above), and removed at the end, also when a migration fails, the run errors, or it gets
Ctrl+C or SIGTERM (exit 130 and 143). A hard kill (TerminateProcess, `Stop-Process`, a CI cancel, an IDE stop)
cannot be caught and leaves the container; every start removes the `msafe-rehearse-*` containers (and private
networks) started on the same system whose process is gone. The system is the label `msafe-owner`
(`<hostname>/<platform>/<WSL distro>`): Windows and a WSL distro that share one Docker daemon never remove each
other's live containers. `--keep` leaves it running after a run that finished and prints `docker exec` and `docker rm -f -v` lines.
Exit 2: docker is not installed, its daemon does not answer, the image cannot be pulled, the seed does not
load, bad arguments. An image that is not present is pulled first; it is left in the local cache.

**Seed.** A `.sql` or `.sql.gz` file loads strictly: any error is exit 2. `--dump <file>` takes `pg_dump`
output (plain or custom format) or `mysqldump` output, `.gz` allowed, goes before the migrations, and tolerates
errors, counting them (`ALTER ... OWNER`, missing roles and extensions are common in a scratch server); only
the line and error code of the first one are printed, since an error text can quote rows. A seed or dump that
leaves no tables is exit 2. A `pg_restore` that exits non-zero is reported but not fatal while tables were loaded. The data must hold the cases that break DDL:
NULLs, duplicates, orphans, the longest values, the maximum ids. The data directory is kept in memory (fast
start and load) for seeds up to 256 MB; `--disk` or a bigger seed uses the container's disk.

**What runs.** The runner is detected from the first migration (`--runner` overrides). A file is wrapped in
a transaction when the runner does that (`psql --single-transaction`; `START TRANSACTION ... COMMIT` for MySQL,
whose DDL commits implicitly anyway), so `CREATE INDEX CONCURRENTLY` in a wrapped file fails as it would in
production. A failed migration stops the run; the rest is `SKIPPED`. With `--down` the downs run in reverse,
then the ups again, and the tables and columns are compared with the seed.

**What is measured.**

- Duration of each migration, taken inside the server between two timestamps of the same session
  (`clock_timestamp()`, `SYSDATE(6)`), so the `docker exec` round trip is not in it; a file that sets its own
  MySQL `DELIMITER` is timed from outside, minus the round trip.
- Locks: a second session polls while the migration runs (the output says the measured interval, about
  50 ms). Before the first migration the tool proves the measurement works: another session holds a lock on a
  probe table for 3 s and the polling session must see it, otherwise exit 2 (MySQL 5.7 ships the metadata-lock
  instrument disabled, so it is switched on first; MariaDB needs its `metadata_lock_info` plugin). During a
  run, a polling session that reports an error, ends, or returns too few polls for the length of a migration
  makes that migration `UNMEAS.`: its locks are unknown, the run fails, and "no lock" is never printed.
  A lock on several modes of one table is one line (`AccessExclusiveLock + ShareLock on t`). PostgreSQL: `pg_locks` joined with
  `pg_stat_activity` for the migration's session, modes that block writes (`AccessExclusiveLock`,
  `ExclusiveLock`, `ShareRowExclusiveLock`, `ShareLock`). SQL Server, Oracle and Db2 are in the table above; each has
  its own self-test (a table lock held with `TABLOCKX, HOLDLOCK` plus `WAITFOR`, `LOCK TABLE ... EXCLUSIVE MODE`
  plus `DBMS_SESSION.SLEEP`, `LOCK TABLE` plus `DBMS_ALERT.SLEEP`), and Db2 has a second one for REORG-pending. MySQL: `performance_schema.metadata_locks`
  (`EXCLUSIVE`, `SHARED_NO_WRITE`, `SHARED_NO_READ_WRITE`, `SHARED_READ_ONLY`). MariaDB:
  `information_schema.METADATA_LOCK_INFO` from its `metadata_lock_info` plugin. The time a lock is held is
  first to last poll plus one poll interval, so a lock shorter than the interval may not be seen, and the numbers
  are those of an idle scratch server: on a loaded one, waits behind other transactions come on top. Only
  tables that existed before the migration are reported. A lock held longer than `--lock-budget` (default
  2s; `500ms`, `2s`) is a failure (`LOCKED`).
- Per table the rows, and per column the type, the non-NULL count and a fingerprint (distinct values, total
  length, smallest and largest value as text). The same rules as SQLite decide what is a loss: a dropped
  table or column that held data, a row count that went down, a non-NULL count that went down; a dropped
  column that reappears under another name with the same fingerprint is reported as `renamed ...?`.
  `--allow-loss tasks.priority,audit` marks intended losses. PostgreSQL: every schema except the system ones
  (a table outside `public` is named `schema.table`); MySQL: the `rehearsal` database. Foreign-key orphans are
  not checked because the engine enforces its constraints.

Not covered: waits behind other transactions (the scratch server has none), replication lag, and the N-1
code's tests: run main's test suite against the migrated schema yourself (`--keep` leaves the database).

In CI: `--engine postgres:<tag>` and `mysql:<tag>` with the same tags as production, a seed in the repository,
`--down` for reversible migrations, and the linter (or squawk, Atlas lint, strong_migrations) as a required check.
