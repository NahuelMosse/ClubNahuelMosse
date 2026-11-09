# MySQL and MariaDB: what can run online

Load this when `migration-lint` reports a `mysql-*` rule, or before writing DDL for a MySQL or MariaDB table
that holds real data. Sources: MySQL 8.0 and 8.4 "Online DDL Operations", MariaDB `ALTER TABLE` and InnoDB
instant ALTER documentation, the gh-ost requirements and the pt-online-schema-change manual.

## Server version

The rules depend on the server. `--mysql-version <v>` (`8.0` default, `8.0.28`, `8.4`, `5.7`, `mariadb-10.6`)
sets it; without the flag the linter reads an `image: mysql:<tag>` or `mariadb:<tag>` from a compose file or
CI workflow next to the migrations (or `.tool-versions`) when every declaration agrees, and says which it
used in a `note:` line. A series without a patch (`8.0`) means its newest patch.

| Server | Behaviour the rules assume |
|---|---|
| MySQL before 8.0.12, MariaDB before 10.3 | no `ALGORITHM=INSTANT` |
| MySQL 8.0.12 to 8.0.27 | instant `ADD COLUMN` only as the last column |
| MySQL 8.0.28 | adds instant `RENAME COLUMN` |
| MySQL 8.0.29 and 8.4 | instant add at any position, instant drop; 64 row versions per table |
| MariaDB 10.4 and later | instant add at any position, drop and reorder; no row-version limit |

## Per operation

| Operation | Algorithm | Concurrent DML | Rule |
|---|---|---|---|
| Add column | `INSTANT` (8.0.12+) | yes (not with `AUTO_INCREMENT`) | `mysql-column-position`, `mysql-instant-row-versions` |
| Drop column | `INSTANT` (8.0.29+), else `INPLACE` rebuild | yes | `drop-column`, `mysql-instant-row-versions` |
| Rename column | `INSTANT` (8.0.28+), else `INPLACE` | yes if the definition is unchanged | `rename-column`, `mysql-change-column-rename` |
| Change data type | `COPY` | no | `change-column-type` |
| Extend `VARCHAR` | `INPLACE`, only within 0-255 bytes or from 256 up; crossing 255 bytes is `COPY` | yes | `change-column-type` |
| `ENUM`/`SET` append | `INSTANT`, same storage size | yes | `mysql-enum-change` |
| `ENUM`/`SET` reorder, insert, remove, grow storage | `COPY` | no | `mysql-enum-change` |
| Convert or change character set, collation | rebuild | no | `mysql-charset-conversion` |
| Add secondary index | `INPLACE` | yes | `mysql-no-algorithm` |
| Add `FULLTEXT` or `SPATIAL` index | `INPLACE` | no | `mysql-fulltext-spatial-index` |
| Add primary key | `INPLACE` rebuild | yes | `mysql-add-primary-key` |
| Drop primary key alone | `COPY` | no | `mysql-drop-primary-key` |
| Add foreign key | `INPLACE` only with `foreign_key_checks=0`, else `COPY` | yes | `mysql-add-foreign-key`, `mysql-fk-implicit-index` |
| `OPTIMIZE TABLE`, `FORCE`, `ENGINE=InnoDB`, `ROW_FORMAT` | `INPLACE` rebuild | yes | `mysql-table-rebuild` |
| `RENAME TABLE` | metadata only | yes | `rename-table` |

Anything the table marks `INPLACE` still takes a brief exclusive metadata lock at the start and at the end.

## Metadata locks

Every `ALTER` waits for the metadata lock of its table, behind any transaction that touched the table, even
one that is idle. While it waits, new queries on that table queue behind it: a DDL that runs in
milliseconds becomes an outage. Start with `SET SESSION lock_wait_timeout = 5;` (MariaDB also takes
`ALTER TABLE ... WAIT 5`) and retry with backoff (`mysql-lock-wait-timeout`). Declare the algorithm so the
statement fails instead of copying: `ALGORITHM=INSTANT`, or `ALGORITHM=INPLACE, LOCK=NONE`
(`mysql-no-algorithm`). `LOCK=NONE` is not allowed on tables with `ON ... CASCADE` or `SET NULL` foreign keys.

## Tables too big for ALTER

- **gh-ost** (MySQL 5.7+): needs row-based binlogs, a primary or non-null unique key shared by the old and new
  table; no foreign keys, no triggers; cut-over can be postponed and throttled.
- **pt-online-schema-change**: triggers copy writes, so the table must have no triggers (or use
  `--preserve-triggers` on 5.7.2+); needs a primary key or unique index; foreign keys that point at the table
  need `--alter-foreign-keys-method`; bound the load with `--max-load`, `--critical-load`, `--chunk-time`;
  dry-run with `--dry-run` before `--execute`.
- A rename or `CHANGE COLUMN` is still an expand/contract change: the tools only make the copy online.

## Character sets

`utf8` is `utf8mb3`. Converting to `utf8mb4` rewrites every text column, grows indexed `VARCHAR` columns
(a `VARCHAR(255)` key is 1020 bytes in `utf8mb4`: over the 767-byte limit of `COMPACT`/`REDUNDANT` rows, under
the 3072 of `DYNAMIC`), and a join between columns with different collations cannot use the index. Convert
the parent and the child of a foreign key together.
