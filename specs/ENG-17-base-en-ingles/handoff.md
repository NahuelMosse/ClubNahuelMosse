# Handoff ENG-17 · T1 and T2 (builder 3)

## Done
- `apps/api/migrations/env.py` translated (run, engine, app_config).
- `apps/api/migrations/versions/0012_english_schema.py` written: generic `_migrate(move, functions, view)` with `TO_ENGLISH` / `TO_SPANISH = _reversed(...)`; drops triggers/value constraints/value indexes/view/functions, translates values, renames tables/columns/constraints/indexes, recreates in the target names.
- First full group run (before the last refactor of `_migrate` into `_drop_definitions`/`_rename_in_place`/`_create_triggers`): 19 passed, 2 failed, both TEST bugs:
  - `test_english_schema.py::test_the_migration_translates_the_rows...` compares `counts` dicts keyed by table name (Spanish vs English) and so never reaches the downgrade half.
  - `test_migrations_folder.py::test_the_migrations_live...` uses `ConfigParser()` with `%(here)s` in alembic.ini (needs `interpolation=None`).
- Replacements written (NOT yet committed, not yet confirmed green): `apps/api/tests/escenarios/test_english_schema_rows.py` and `test_migrations_folder_ini.py` (same `@ENG-17-S1`/`@ENG-17-S3` tags).

## Left
1. Check `/tmp/g2.log` (run of the two new test files; ends with `done`) or rerun: `cd D:/Temp/w/eng17 && sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/escenarios/test_english_schema_rows.py tests/escenarios/test_migrations_folder_ini.py` (background + log; ~10 min for the schema file). If the rows test fails after the translation step, the downgrade half is the thing to debug.
2. `sh D:/Temp/w/herramientas/eng17-lint.sh`: last run had 4 errors in 0012 (3 E501 and C901 on `_migrate`); the refactor just made fixes them, confirm. Run `ruff format` on 0012 and the two new tests if the tool is available.
3. `sh D:/Temp/w/herramientas/eng17-render-rehearsal.sh` (not yet run).
4. Log lines in card.md for T1/T2 including the `replaces:` lines: `- L<n> · <date> · replaces: apps/api/tests/escenarios/test_english_schema.py "test_the_migration_translates_the_rows..." · counts compared by table name · by: test_english_schema_rows.py "..."` and the same for `test_migrations_folder.py` -> `test_migrations_folder_ini.py` (ConfigParser interpolation).
5. Commit in Spanish with trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push.
- Group gate lines passing in the first run: all of test_english_schema (except the replaced one), test_datos_migraciones (all), test_migrations_folder (except the replaced one).
