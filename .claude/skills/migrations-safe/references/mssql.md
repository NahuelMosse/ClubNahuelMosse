# SQL Server: what runs online, by edition and version

Load this when `migration-lint` reports a `mssql-*` rule, or before writing DDL for a SQL Server table that
holds real data. Sources: Microsoft Learn, "Editions and supported features of SQL Server 2022" and "2025"
(High availability table), "ALTER TABLE (Transact-SQL)", "ALTER COLUMN ... WITH (ONLINE = ON)" (SQL Server 2016),
"Perform index operations online", "SET LOCK_TIMEOUT".

## Server version and edition

`--server-version <year>` (`2022` default, `2016`, `2019`, `2025`) and `--edition standard|enterprise|azure`
(`standard` default) set what the rules assume. Without `--server-version` the linter reads an
`image: mcr.microsoft.com/mssql/server:<tag>` from a compose file or CI workflow next to the migrations and says
which one it used in a `note:` line. The edition is never read from a compose file: a Developer image does not
prove production is Enterprise, so the default is the conservative edition. Enterprise covers Developer and
Evaluation; `azure` is Azure SQL Database and Managed Instance.

| Feature | Enterprise, Developer, Azure SQL | Standard, Express |
|---|---|---|
| Online index create and rebuild (`WITH (ONLINE = ON)`) | yes | no (2022, 2025) |
| Resumable online index create and rebuild, resumable `ADD CONSTRAINT` | yes | no |
| Online schema change: `ADD` NOT NULL column with a runtime-constant default as a metadata change | yes | no: every row is written under Sch-M |
| `ALTER COLUMN ... WITH (ONLINE = ON)` | 2016 and later | no |
| `WAIT_AT_LOW_PRIORITY` on online rebuild and `SWITCH` | 2014 and later | no (needs ONLINE) |

## Per operation

| Operation | Locks | Rule |
|---|---|---|
| `ADD` nullable column, with or without `DEFAULT` | metadata only, every edition | none |
| `ADD` NOT NULL column with a `DEFAULT` | Enterprise and Azure, runtime-constant default: metadata only. Otherwise (Standard, Express, or `NEWID()`, `NEXT VALUE FOR`, `RAND()`): size-of-data under Sch-M | `mssql-add-not-null-default` |
| `ADD` NOT NULL column without a default | fails on a populated table | `not-null-without-default` |
| `ALTER COLUMN` (type, nullability, collation) | offline: rewrite under Sch-M. Widening `varchar`/`nvarchar`/`varbinary` to a longer fixed length, with the same nullability and collation, stays a metadata change and is not reported when the linter knows the old definition (same file, earlier migrations of the folder, `--schema`); `varchar(max)`, shortening, `NULL` to `NOT NULL` and a new collation rewrite. With an unknown old definition the finding stays and says so. With `ONLINE = ON` (2016+, Enterprise): second copy of the column, double space and log | `mssql-alter-column` |
| `CREATE INDEX`, `ALTER INDEX ... REBUILD`, `ALTER TABLE ... REBUILD`, `ADD PRIMARY KEY/UNIQUE` | writes blocked while it builds (clustered key: table rebuild) unless `ONLINE = ON` (Enterprise). `ALTER INDEX ... REORGANIZE` is always online | `mssql-index-offline`, `mssql-online-unsupported-edition` |
| `ADD` FOREIGN KEY or CHECK | `WITH CHECK` is the default: scans every row under Sch-M | `mssql-constraint-with-check` |
| `WITH NOCHECK` | no scan; the constraint is untrusted until `WITH CHECK CHECK CONSTRAINT` | `mssql-constraint-nocheck` |
| `DROP COLUMN` | metadata change; the space is freed only when the clustered index is rebuilt | `drop-column` |
| `sp_rename` | renames at once; code using the old name breaks | `rename-column`, `rename-table` |
| Any DDL on an existing table | waits for its schema lock without limit unless `SET LOCK_TIMEOUT` (or `WAIT_AT_LOW_PRIORITY`) | `mssql-lock-timeout` |

## Reading T-SQL

- Batches end at `GO` (or `GO n`) on a line of its own; `GO` is a client command (sqlcmd, SSMS, Flyway, DbUp),
  not T-SQL. goose, dbmate and golang-migrate send the whole file to the driver and fail at `GO`
  (`unsupported-separator`).
- Statements without `;` are split at the keywords that start a statement (`ALTER`, `CREATE`, `INSERT`, `IF`, ...)
  at the start of a line, outside parentheses and `BEGIN ... END`. This is a heuristic: a script formatted in an
  unusual way can be read as fewer statements than it has.
- `CREATE PROCEDURE`, `FUNCTION` and `TRIGGER` run to the end of the batch, as in SQL Server.
- `EXEC(N'...')` and `sp_executesql N'...'` (EF Core idempotent scripts) are read as the SQL they run; the
  `IF NOT EXISTS (...) BEGIN ... END` guard around a statement is not the statement.
- `[bracketed;identifiers]`, `N'...'` strings, `:setvar` and `:on error` (SQLCMD) are understood.

## Tools that produce T-SQL

| Tool | How to lint it |
|---|---|
| EF Core | `dotnet ef migrations script --idempotent`, piped to `migration-lint.mjs - --runner efcore` |
| SqlPackage / DACPAC | `sqlpackage /Action:Script`; a table rebuild (`tmp_ms_xx_<table>`, `sp_rename`) is checked for lost columns |
| DbUp | `.sql` scripts; runs in name order, no wrapping transaction |
| Flyway, Liquibase | read natively; both split on `GO` |

## Rehearsal

`rehearse.mjs --engine mssql:2022-CU14-ubuntu-22.04` runs `mcr.microsoft.com/mssql/server:<tag>` and reaches it with
`sqlcmd`. `--edition standard` (default) starts Express (2019, 2022) or Standard Developer (2025);
`--edition enterprise` starts Developer. The edition the server reports (`SERVERPROPERTY('Edition')`) is
compared with the one asked for, and a mismatch is exit 2. Express stops at 10 GB per database: a larger seed
is exit 2 with that reason. Locks are read from `sys.dm_tran_locks` (Sch-M, X, SIX and S on tables, a queued
Sch-M included) for the session tagged `msafe-migration`. See [rehearsal.md](rehearsal.md).
