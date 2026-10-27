# ENG-02 handoff

Done (committed): RED `535551c`; rename of venues/users/session/password_recovery, explicit operation_id on 13 routes, openapi.json regenerated, docs (mapa-del-codigo, README, glosario) and tests refactored (second commit).
Uncommitted: tests/unit/test_sedes.py fake `insert(author=...)` fix.

Left:
1. Commit the test_sedes fix. Read the result of the verify run (`/tmp/eng02-verify.log`, `.validation/verify/*.log`); it was started WITHOUT `UV_PROJECT_ENVIRONMENT` exported, so fmt/lint ran in a wrong env (fmt: ruff not found; lint: dart analyze noise from apps/mobile). Rerun the gate lines with the shared venv exported.
2. attacks line fails: `D:/Temp/w/herramientas/api-attacks.sh:26-27` only knows `app/modules/usuarios/sembrar_admin.py`; it must also try `app.modules.users.seed_admin` (shared tool outside the repo, lead's call).
3. Failing unit tests (run `uv run --no-sync pytest -q -p no:cacheprovider tests/unit`): test_arquitectura_funcionalidades contract-vs-main (schema names; extend RENOMBRADOS), test_codigo_legible signatures-vs-main (already red at ENG-01 base: crear_app, shared/db), test_base_en_ingles contract/_pruebas (red at ENG-01 base: `_IncludedRouter`), type:ignore in test_config_en_ingles (test_sin_supresiones x2, pre-existing), test_sin_sobreingenieria (DB port 8703 env).
4. apps/api/pyproject.toml per-file-ignores `app/modules/*/rutas*.py` no longer matches routes.py/account_routes.py (test_codigo_legible:28 asserts it).
5. Run integracion + escenarios with the gate's Postgres/emulator; append T1 Log line to card.md with Edit.
6. Cross-branch: venues/users call espacios/reservas names that ENG-03/05 rename (dar_de_baja_de_sede, parte_de_calle, cancelar_futuras_de).
