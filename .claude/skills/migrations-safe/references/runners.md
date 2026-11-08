# Runners and dialects

Load this when the project uses one of these tools, or when the linter's runner or dialect guess looks
wrong. `--runner <id>` and `--dialect postgres|sqlite|mysql|mssql|oracle|db2` override detection.

Detection order: `--runner`; the project's config files (searched upwards from the file to the repository
root, including a `.sqlproj`, a `*ModelSnapshot.cs` and a `.csproj` that references `dbup-`); markers inside the
file (`-- +goose`, `-- migrate:up`, `__EFMigrationsHistory`, `tmp_ms_xx_`); the file name; otherwise `raw`.
Dialect: `--dialect`; a `-- migration-lint: dialect sqlite` line; `migration_lock.toml` (provider `sqlserver`
too) or the Drizzle config; the migration tool's own configuration (below); the syntax; the other files of the
project; otherwise PostgreSQL, and then the run prints `dialect assumed to be PostgreSQL` with how to change it.
The project's files are read in every directory from the file up to the repository root, and rank comes before
nearness: the most specific rank found anywhere on the way wins (a compose file in `services/web` does not shadow
the Flyway config at the root), and the nearest directory only breaks ties within a rank. Hints that name another
engine are listed in a warning. The ranks, most specific first:
1. The migration tool's configuration, which outranks the syntax: when the syntax contains a marker the project's
   engine cannot parse, the run says so and uses the project's engine (Oracle's `MODIFY col NOT NULL` is read as
   Oracle, not MySQL): the jdbc URL in `flyway.conf` / `flyway.toml` / `liquibase.properties`, a Liquibase changelog
   `dbms`, an SSDT `.sqlproj`; the EF Core / DbUp provider package in a `.csproj`; Spring Boot's
   `application*.properties|yml` (`spring.datasource.url`, `spring.flyway.url`, a jdbc URL, a driver class) in the
   directory, `src/main/resources` or `config`; Flyway's database module in `pom.xml` / `build.gradle(.kts)`
   (`flyway-sqlserver`, `flyway-database-oracle`, `flyway-database-db2`, `flyway-mysql`, `flyway-database-postgresql`).
2. What the application references, which yields to engine-specific syntax: a JDBC driver in `pom.xml` /
   `build.gradle(.kts)` (`ojdbc*`, `mssql-jdbc`, `jcc`, `postgresql`, `mysql-connector-j`, `mariadb-java-client`;
   test-scoped and Testcontainers dependencies are ignored), plain .NET drivers, and the values under
   `ConnectionStrings` in `appsettings*.json`.
3. The `image:` of a compose file (`mcr.microsoft.com/mssql/server`, `gvenzl/oracle-*`,
   `container-registry.oracle.com/database`, `icr.io/db2_community/db2`, `postgres`, `mysql`, `mariadb`).

A syntax marker only counts against a hint when the hinted engine cannot parse it: each marker lists the engines
that accept it (`RENAME TABLE` is MySQL and Db2, `NVARCHAR` is SQL Server, Db2, MySQL and SQLite, `EXECUTE IMMEDIATE`
and `DBMS_*` are Oracle and Db2, `FROM dual` is Oracle and MySQL, `[x]` is SQL Server and SQLite, backticks are MySQL
and SQLite), so a Db2 compose file keeps Db2 for a file with `RENAME TABLE`, while `GO` or `VARCHAR2` override it.
Rank 1 is kept even then (with a warning); ranks 2 and 3 give way to the syntax, and the note says which engine
was used and why. If a more specific source disagrees with a less specific one the first wins and the run warns,
naming the other. If
sources of the same rank disagree (a compose file with SQL Server and Oracle) and the SQL has no engine-specific
syntax, nothing can be chosen: the run exits 2 listing the candidates, and `--dialect` or the directive settles it.
Syntax markers, strongest first: `--#SET
TERMINATOR`, `ADMIN_CMD`, `SYSPROC.`, `SET CURRENT LOCK TIMEOUT` mean Db2; `GO` alone on a line, a `[bracketed]`
identifier, `sp_rename`, `nvarchar` mean SQL Server; `/` alone on a line, `VARCHAR2`, `EXECUTE IMMEDIATE`,
`FROM dual` mean Oracle; backticks, `AUTO_INCREMENT`, `MODIFY COLUMN` mean MySQL; `PRAGMA`, `AUTOINCREMENT` mean
SQLite. `GENERATED ... IDENTITY` and `int[]` say nothing: PostgreSQL has both.

| Runner | Detected by | Lint input | Downs | Wraps each file in a transaction | Order |
|---|---|---|---|---|---|
| `prisma` | `prisma/schema.prisma`, `migration_lock.toml` | `prisma/migrations/*/migration.sql` | no | one statement or implicit multi-statement transaction | strict |
| `drizzle` | `drizzle.config.*`, `drizzle/meta/_journal.json` | `drizzle/*.sql` | no | yes | strict |
| `flyway` | `flyway.conf`, `V1__x.sql` names | `V*__*.sql`; `R__*.sql` repeatable | no (Community) | yes (`executeInTransaction=false` opts out) | strict; `V1` equals `V1_0` |
| `liquibase` | `liquibase.properties`, master changelog | formatted SQL changelogs | yes (rollback) | per changeset | graph (changelog order) |
| `goose` | `-- +goose` markers | one file, Up and Down sections | yes | yes (`-- +goose NO TRANSACTION` opts out) | strict |
| `dbmate` | `-- migrate:up` markers | one file, up and down sections | yes | yes (`transaction:false` opts out) | lenient |
| `golang-migrate` | `x.up.sql` / `x.down.sql` names | the pair of files | yes | implicit when the file has several statements | strict |
| `atlas` | `atlas.hcl`, `atlas.sum` | versioned `.sql` files | no | yes (`-- atlas:txmode none`) | strict |
| `alembic` | `alembic.ini` | `alembic upgrade A:B --sql` piped to `-` | yes | yes | graph |
| `django` | `manage.py` | `python manage.py sqlmigrate <app> <n>` piped to `-` | yes | yes (`atomic`) | graph |
| `knex` | `knexfile.*` | statements logged while it runs on a scratch database, piped to `-` | yes | yes | strict |
| `rails` | `config/application.rb`, `db/migrate/*.rb` | SQL logged while `rails db:migrate` runs on a scratch database, piped to `-` | yes | yes | lenient |
| `efcore` | `*ModelSnapshot.cs`, `__EFMigrationsHistory` in the SQL | `dotnet ef migrations script --idempotent` piped to `-` | yes | no (the script shows its own) | strict |
| `dbup` | a `.csproj` with `dbup-*` | the script files | no | no | lenient |
| `sqlpackage` | a `.sqlproj`, `tmp_ms_xx_`, `:setvar DatabaseName` | `sqlpackage /Action:Script` piped to `-` | no | no (the script shows its own) | graph |
| `raw` | nothing found | any `.sql` | yes | no | strict |

What a profile changes in the findings:

- `missing-down` only for runners with downs.
- Oracle commits every DDL implicitly, so no runner wraps a file on Oracle, whatever its profile says; Django and
  Alembic do not wrap on MySQL either.
- A batch separator the runner does not understand is `unsupported-separator`: Flyway splits on `GO` (SQL
  Server) and `/` (Oracle); Liquibase on those and on `endDelimiter:`; DbUp, `sqlpackage` and EF Core scripts
  use `GO`; goose, dbmate, golang-migrate, Atlas, Prisma and Drizzle send the file to the driver whole (read from
  each project's documentation, not run here). `raw` is applied by something this tool cannot see (sqlcmd,
  SQL*Plus, the Db2 CLP) and reads all of them. Liquibase formatted SQL also reads `runInTransaction:false`.
- `not-atomic` and `transaction-conflict` depend on whether the runner already wraps the file; a
  `CONCURRENTLY` statement in a wrapped file is `concurrently-in-transaction` even with no `BEGIN`.
- `--history` ignores manifests (`_journal.json`, snapshots, `atlas.sum`, `migration_lock.toml`, master
  changelogs, Flyway `R__` files), treats `out-of-order` as a warning for lenient runners and skips it for
  graph runners.
- The rehearsal wraps each file the way the runner does and uses its `PRAGMA foreign_keys` setting.

## Runners that generate their SQL

The linter reads SQL. For Alembic, Django, Knex, Rails and similar tools, produce the SQL for the
migration and pipe it in:

```bash
python manage.py sqlmigrate shop 0042 | node "${CLAUDE_SKILL_DIR}/scripts/migration-lint.mjs" - --runner django
alembic upgrade head --sql | node "${CLAUDE_SKILL_DIR}/scripts/migration-lint.mjs" - --runner alembic
```

- On stdin the generated SQL shows what the runner does: a `BEGIN`/`COMMIT` in it means it is wrapped, its
  absence means it is not. No `missing-down` is reported for stdin, and empty stdin is exit 2.
- Flyway runs a script outside a transaction when every statement in it is `CONCURRENTLY`, or when a
  `V2__x.sql.conf` next to it has `executeInTransaction=false`; the linter reads both.
- **Rails**: `strong_migrations` sees the DSL and is the primary check. To lint the SQL, run
  `rails db:migrate` on a scratch database with the statements logged (`ActiveRecord::Base.logger =
  Logger.new($stdout)` in an initializer for the run) and pipe the `CREATE`/`ALTER` lines in. `rails
  db:migrate:status` only lists versions; it prints no SQL.
- **Knex**: no dry-run SQL. Run `knex migrate:latest` on a scratch database with `DEBUG=knex:query`, or
  write the risky steps as `knex.raw` SQL and lint that.
- **EF Core and SqlPackage**: `dotnet ef migrations script --idempotent` and `sqlpackage /Action:Script` produce
  T-SQL; pipe it to `migration-lint.mjs -`. The `IF NOT EXISTS (...) BEGIN ... END` guard and `EXEC(N'...')`
  wrapper EF writes are looked through; a DACPAC table rebuild (`tmp_ms_xx_<table>`, `sp_rename`) is checked for
  columns the new table drops.
- **Prisma, Drizzle, EF Core, Django**: generated migrations are drafts. Generate without applying
  (`prisma migrate dev --create-only`, `drizzle-kit generate`), read the SQL, split or edit it before it
  reaches main. `prisma db push` and `drizzle-kit push` never touch a shared database.

## PostgreSQL second opinion

The linter is regex-based and reads standard DDL. For PostgreSQL, run `squawk` as well: it parses with
the real PostgreSQL parser and covers rules this tool does not.
