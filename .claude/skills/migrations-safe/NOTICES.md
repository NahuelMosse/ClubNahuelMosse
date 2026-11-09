# Notices

No third-party text or code is included. `scripts/migration-lint.mjs` and `scripts/rehearse-sqlite.mjs` are original;
the history checks (applied migration changed, out of order, duplicate sequence) are rewritten from the SDD kit's
`migrations.mjs` to run standalone.

Ideas that also appear in published work, credited here:

- The catalogue of risky PostgreSQL DDL (rename, type change, NOT NULL, NOT VALID constraints, concurrent indexes,
  lock and statement timeouts, volatile defaults): squawk (https://squawkhq.com/docs/rules) and strong_migrations
  (https://github.com/ankane/strong_migrations).
- Classifying changes as destructive, backward-incompatible, data-dependent and blocking, per engine, including the
  MySQL table-copy cases: Atlas migration lint (https://atlasgo.io/lint/analyzers).
- Expand–contract executed by the tool with versioned views and triggers: pgroll (https://github.com/xataio/pgroll).
- Online schema change for MySQL through a ghost table and the binlog: gh-ost (https://github.com/github/gh-ost).
- Parallel change (expand, migrate, contract): Martin Fowler, https://martinfowler.com/bliki/ParallelChange.html.
- No-transaction modes for concurrent indexes: Rails `disable_ddl_transaction!`, Django `atomic = False`
  (https://docs.djangoproject.com/en/stable/howto/writing-migrations/), dbmate `transaction:false`.
- Generated migrations as drafts to review (`--create-only`): Prisma Migrate docs
  (https://www.prisma.io/docs/orm/prisma-migrate/workflows/customizing-migrations).
