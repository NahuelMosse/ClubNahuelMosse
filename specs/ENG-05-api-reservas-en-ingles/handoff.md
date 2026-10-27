# Handoff ENG-05 (T1, second pass)

The rename map and the original task list are in git: `git show 6bedfd8:specs/ENG-05-api-reservas-en-ingles/handoff.md`.

## Done (uncommitted, worktree D:/Temp/w/eng05)
- `git mv` reservas -> bookings with store/use_cases/rules/repository/routes; `__pycache__` removed; no `reservas/` dir remains.
- All six files in `apps/api/app/modules/bookings/` rewritten in English per the map (SQL aliases in English, `_view`/`_admin_view` copy field by field, explicit `operation_id=` and `tags=["reservas"]`, `CLUB_TIMEZONE`, constants renamed).
- `app/main.py`, `app/modules/usuarios/repositorio.py` (`BookingsSql(...).cancel_future_of`), `pyproject.toml` (per-file ignore PLR0913/PLR0917 for `app/modules/bookings/routes.py`).
- Tests (imports, symbols, fields only): escenarios/test_repositorios_propios, integracion/test_api_limpia_reservas, test_api_limpia_reserva_movida, test_reservas_api, unit/test_casos_de_uso_reservas, test_despacho_de_confirmaciones (builds `DatosDeReserva` from the Booking), test_filtros_del_historial, test_repositorios_inyectados, test_capas_funcionalidades, test_arquitectura_funcionalidades:312, test_api_limpia_plan_funcionalidades.
- Docs: guia-basica, technical/arquitectura, technical/mapa-del-codigo. No `docs/features` dir exists. `apps/api/README.md` and e2e_support/e2e.sh had no module paths.
- `apps/api/openapi.json` regenerated.
- `ruff format app tests`: clean.

## Third pass (done)
- Unit: 316 passed, 5 failed; the 5 also fail on HEAD (worktree D:/Temp/w/chk_head): test_base_en_ingles (`/_pruebas/` route missing, openapi equality passes), test_capas_funcionalidades + test_sin_supresiones (`type: ignore` in test_config_en_ingles.py), test_codigo_legible firmas (main differs), test_sin_sobreingenieria.
- Path/name fixes in tests: test_arquitectura_funcionalidades (bookings entry, RENOMBRADOS_DE_RESERVAS + `_con_esquemas_de_reservas`), capas, plan_funcionalidades, codigo_legible, despacho ("Reserva cancelada" restored). `openapi.json` regenerated. mapa-del-codigo row `bookings`, glosario names added.
- Code: `modify_booking` (lambda param `hours`, local `start`) and a comment in `BookingsSql.move` rewrapped to stay under 40 lines.
- Ruff: 6 errors left exist on HEAD (F821 CASOS_DE_USO in test_suite_confiable:437, 5 E501 in test_capas_funcionalidades); test_basquet_3x3 reverted to HEAD (format noise).
- Integration: DB club_eng05_test created on 127.0.0.1:8701 (drop it when done); run was launched to /tmp/int2.log with TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8701/club_eng05_test and FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099; result not read.

## Left
1. Add the new names to `docs/technical/glosario-ingles.md` (already there: Booking, BookingHistoryEntry, BookingHistory, HistoryFilters, Counters, BookingsSql, When). Missing: Status, StatusFilter, PAGE_SIZE, Bookings protocol and its methods, use-case names, route classes and handlers, constants, `_view`/`_admin_view`.
2. `uv run --no-sync ruff check app tests`: 9 errors remain (not read yet).
3. `tests/unit` last run (/tmp/unit2.log): 301 passed, 20 failed. Check each against main before fixing; likely caused by the file renames (tests that look for `rutas.py`, `casos_de_uso.py`, `reglas.py`, `repositorio.py` in every module, or the `reservas` folder, or the mapa lists):
   test_arquitectura_funcionalidades (7), test_mapa_por_funcionalidad (2), test_codigo_legible (4), test_capas_funcionalidades (2), test_sin_supresiones, test_despacho_de_confirmaciones, test_api_limpia_plan_funcionalidades, test_base_en_ingles (openapi vs published), test_sin_sobreingenieria. Two of them were DB-connection errors (port 8703 SSL negotiation), so they are environmental.
   `test_modulo_reservas_en_ingles.py` passes S1 and S3 as of the last run; S2 passed after renaming `_vista` (re-confirm).
4. Integration tests touching bookings not run (Postgres/auth emulator not confirmed up).
5. Gate `node .claude/tools/verify.mjs` and the `## Log` line `- L4 · <date> · T1 · <evidence>` in card.md (the main thread, not the grunt).

## Run
`cd apps/api && UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv" uv run --no-sync pytest -q -p no:cacheprovider tests/unit` in the background to a log; `node .claude/tools/wait.mjs <log> --until '^done'`.
