# Handoff ENG-17 · T1 and T2 (builder 2)

## Done (committed)
- T2 RED + `git mv` to `apps/api/migrations/` + `alembic.ini` (builder 1).
- T1 RED, commit "RED del esquema en inglés...": `tests/escenarios/test_english_schema.py` (12 tests, expected names written out; S7 test translates the 0011 catalogs with maps inside the test and also checks the downgrade returns the same catalog) and `tests/escenarios/test_render_rehearsal.py` (2 tests). Verified: the first test fails on names (right reason). Not yet run: the rest of the file (typos possible: if a test is wrong, replace it in a new file with the same tag and log it).

## Left
1. `apps/api/migrations/env.py`: translate (`run`, `engine`, `app_config`, English comments; keep `transaction_per_migration=True`); the test checks the words "motor" and "correr" are gone and `def run_migrations` is not in it.
2. `apps/api/migrations/versions/0012_english_schema.py` (revision "0012", down_revision "0011"). Design: one `_migrate(src, dst)` used by upgrade (Spanish->English) and downgrade (reverse), with two vocabularies as data:
   - `SET LOCAL lock_timeout = '5s'` first (SET LOCAL, so it does not outlive the txn).
   - drop in src names: view, ALL triggers (so `updated_at` is untouched, ASM-05), value-dependent constraints and indexes.
   - translate values with UPDATE ... CASE in src names (usuario->user, activa->active, cancelada->canceled, anulada->voided, recordatorio->reminder, recordatorio_cinco->five_minute_reminder, cancelacion_forzosa->forced_cancellation, cancelacion_usuario->user_cancellation, pendiente->pending, enviando->sending, enviada->sent, sin_permiso->no_permission, sin_canal->no_channel, fallida->failed); reset column defaults (booking.status 'active', app_user.role 'user').
   - rename tables, columns (glossary `docs/technical/glosario-ingles.md`, sections Tablas/Columnas), constraints (explicit list in the test: `CONSTRAINTS`; per table old prefix -> new prefix + suffix pairs), plain indexes (`ALTER INDEX ... RENAME`).
   - create in dst names: functions (`touch_updated_at`, `forbid_delete`, `email_immutable`, `space_identity_immutable`, English messages; `CREATE OR REPLACE uuid_v7()` with English variable names, since column defaults depend on it), triggers (`<t>_updated`, `<t>_no_delete`, `app_user_email_immutable`, `space_name_immutable`), dependent constraints/indexes (booking_status_check, booking_check3, booking_space_id_tstzrange_excl, notification_delivery_check, notification_kind_check, notification_check, notification_cancellation_has_booking, app_user_role_check; indexes in the test's `INDEX_PREDICATES`), view `booking_with_status` (`current_status`, 'completed').
   - drop the src functions (not uuid_v7). Downgrade restores Spanish bodies exactly as in 0011 (dump in `/tmp/eng17_schema.sql`, Git Bash path; function bodies there with 8-space indent).
   - Constraint DDL lines <= 100 columns (ruff E501 applies to migrations).
3. Run the group gate: `sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider tests/escenarios/test_english_schema.py tests/escenarios/test_migrations_folder.py tests/escenarios/test_datos_migraciones.py` (background + log, ~1 min per 10 tests), then `sh D:/Temp/w/herramientas/eng17-render-rehearsal.sh` and `sh D:/Temp/w/herramientas/eng17-lint.sh`. test_datos_migraciones failures from the old SQL are T4, not yours.
4. Append Log lines for T1 and T2 to card.md; fill `reuses`/`new` for T1 already present. Commit in Spanish, trailer `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push.

## Notes
- Do not read the Render URL file or the dump.
- Python/ruff: the tests carry `# fmt: skip` blocks; run ruff on the 0012 file only.
