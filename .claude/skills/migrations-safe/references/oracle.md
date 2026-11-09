# Oracle Database: DDL, locks and editions

Load this when `migration-lint` reports an `oracle-*` rule, or before writing DDL for an Oracle table that holds
real data. Sources: Oracle Database 23 "Licensing Information" (Table 1-5, High Availability), Oracle Database
SQL Language Reference (ALTER TABLE, CREATE INDEX), `DDL_LOCK_TIMEOUT` in the Reference. The behaviour of
`ADD COLUMN ... DEFAULT` before 12.1 is documented in secondary sources only (oracle-base "Default Values for
Table Columns Enhancements in Oracle Database 12c Release 1"; Oracle Magazine, "On Oracle Database 12c, Part 1").

## Server version and edition

`--server-version <v>` (`19` default, `11.2`, `12.1`, `23`) and `--edition se2|ee` (`se2` default). Without
`--server-version` the linter reads a `gvenzl/oracle-free`, `gvenzl/oracle-xe` or
`container-registry.oracle.com/database/*` image from a compose file or CI workflow next to the migrations.

| Feature | Enterprise (EE), Free | Standard Edition 2 |
|---|---|---|
| Online index rebuild (`CREATE INDEX ... ONLINE`, `ALTER INDEX ... REBUILD ONLINE`) | yes | no (ORA-00439) |
| Online table organization (`ALTER TABLE ... MOVE ONLINE`) | yes | no |
| Online table redefinition (`DBMS_REDEFINITION`) | yes | no |

Oracle Free has the Enterprise features, so SE2 cannot be rehearsed with it: `--edition se2` runs on Free and the
run says that what `oracle-online-unsupported-edition` reports passes there and fails on SE2.

## Per operation

| Operation | Locks | Rule |
|---|---|---|
| `ADD` NOT NULL column with a `DEFAULT` | metadata only since 11.1 | none |
| `ADD` nullable column with a `DEFAULT` | before 12.1: every row is updated (row locks, redo). 12.1 and later: metadata only | `oracle-add-column-default` |
| `ADD` NOT NULL column without a default | fails on a populated table | `not-null-without-default` |
| `CREATE INDEX`, `ALTER INDEX ... REBUILD` | DML blocked while it builds unless `ONLINE` (EE) | `oracle-index-not-online`, `oracle-online-unsupported-edition` |
| `ADD` FOREIGN KEY or CHECK | validates every row while blocking DML | `oracle-constraint-validate` |
| `DROP COLUMN` | rewrites every row; `SET UNUSED` is a dictionary change | `oracle-drop-column-rewrites`, `drop-column` |
| Any DDL on an existing table | no queueing: ORA-00054 at once if the table is in use, unless `ALTER SESSION SET DDL_LOCK_TIMEOUT` | `oracle-ddl-lock-timeout` |
| Any DDL | commits the transaction: earlier DML in the file is committed | `oracle-ddl-commits-dml` |
| PL/SQL block, procedure, function, package, trigger, type | ends at `/` on a line of its own | `oracle-missing-slash` |

Oracle commits implicitly on every DDL, so no runner can wrap a file in a transaction and `BEGIN`/`COMMIT` cannot make
several statements atomic: `not-atomic` is not reported for Oracle. A failure halfway leaves the first statements applied,
so keep one DDL per migration or make each step safe to re-run.

## Reading Oracle scripts

- `/` alone on a line runs the buffer. PL/SQL blocks (`BEGIN`, `DECLARE`) and `CREATE [OR REPLACE] PROCEDURE |
  FUNCTION | TRIGGER | PACKAGE | TYPE` keep their semicolons until the `/`. A DDL statement that starts a line
  inside a block that never got its `/` ends the block and is reported.
- `EXECUTE IMMEDIATE '...'` inside a block is also read as a statement.
- SQL*Plus commands (`SET DEFINE OFF`, `PROMPT`, `WHENEVER`, `SPOOL`, `@file`) are not SQL and are skipped.
- `q'[...]'` strings are understood. Names are compared without case: unquoted names are upper case, and
  `"Orders"` is treated as `ORDERS`.
- Flyway and Liquibase split on `/`. goose, dbmate and golang-migrate do not (`unsupported-separator`).

## Rehearsal

`rehearse.mjs --engine oracle:23.5-slim-faststart` runs `gvenzl/oracle-free` and reaches it with `sqlplus`
(`WHENEVER SQLERROR EXIT FAILURE`, `SET DEFINE OFF`, the session tagged with `DBMS_APPLICATION_INFO.SET_MODULE`).
Locks are read from `v$lock` (TM locks in modes 4, 5 and 6) and `dba_ddl_locks` as SYSTEM. The container runs on
a private network with no outside access (Oracle's instance does not start without a non-loopback interface); the
network is removed with the container. The first start takes minutes. See [rehearsal.md](rehearsal.md).
