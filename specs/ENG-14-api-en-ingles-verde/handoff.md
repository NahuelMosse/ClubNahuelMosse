# Handoff ENG-14 (builder, T1) - segunda tanda

Worktree D:/Temp/w/ingles-api, branch `ingles-api`. Never push/PR/touch main. Env: UV_PROJECT_ENVIRONMENT=".../app-tp/apps/api/.venv", FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099. Unit files run fast from apps/api: `uv run --no-sync pytest -q -p no:cacheprovider --tb=short tests/unit/<file>`. DB tests: `sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider --tb=line <files rel. to apps/api>` from the worktree root, one at a time. Full suite is ~7 min (background to D:/Temp/w/full.log, `node .claude/tools/wait.mjs D:/Temp/w/full.log --max 570`). Main for comparison: D:/Temp/w/main (commit 88d1a9c).

## Done
- apps/api/openapi.json regenerated. Paths/methods/codes identical to main 88d1a9c; only diffs: schema names, `recordatorio_cinco` enum value (main's API publishes it, main's json is stale), and 5 error-body schemas named ErrorBody/Errors (glossary) vs main's single `Errores` shape.
- Replacements (new files, same titles/tags; old tests removed from old files; Log L4 has the first `replaces:` line):
  - tests/unit/test_api_en_ingles_contrato_actual.py (replaces the 1ee70de contract test; passes)
  - tests/unit/test_modulos_cuenta_en_ingles_actual.py (3 tests, replaces the 3 failing ones of test_modulos_cuenta_en_ingles.py: `email.py` no longer exists in password_recovery on main; contract with baseline patched for recordatorio_cinco and set-compare of schema shapes; pass). **Still to write in the Log (Edit only): the 3 `replaces:` lines for these (reason: main moved the recovery email to notifications/email; contrato_cuenta_main.json predates NOT-05 and the 4 same-named `Errores` collapse to 1 schema).**
- Last full-suite run (before these edits): 17 failed.

## Left (current failing, run each file alone)
1. test_arquitectura_funcionalidades::test_el_contrato_es_el_de_main_salvo_los_cuatro_nombres_de_esquema (BASE 612d445; same cause: NOT-05 `recordatorio_cinco` + new schemas since; needs a replacement test file with same title/tag comparing with main 88d1a9c, like test_api_en_ingles_contrato_actual).
2. test_base_en_ingles::test_el_contrato_la_salud_y_la_ruta_de_pruebas_responden_igual_que_en_main (line ~148-154; same kind, replacement).
3. test_capas_funcionalidades::test_la_anticipacion_sale_de_las_reglas: expects constant `LEAD_TIME` in rules (names in English now `LEAD_TIME_BY_KIND`, `FIVE_MINUTE_LEAD_TIME`); fails on main too? check in D:/Temp/w/main; if only a name, add `LEAD_TIME` alias/constant in notifications/rules.py or replacement test.
4. test_codigo_legible 40 lines: notifications/repository.py `_due_of` 41 lines (main's `_vencidos...` check on main; if main also exceeds, Log it, else shorten it).
5. test_mapa_por_funcionalidad: map doc (docs/technical/mapa-del-codigo.md) lists notifications `email.py`; code has no such file in notifications? compare sets and fix the doc (or file) - check main as well.
6. DB files: test_cancelacion_forzosa_agrupado::test_un_aviso_leido..., test_documentacion_supuestos_vigente (ASVS matrix evidence paths with old names -> update docs/asvs matrix), test_repositorios_propios::test_el_recordatorio_sale_una_hora_antes (ANTICIPACION monkeypatch; also fails on main? run there), test_suite_confiable (5 tests incl. `_reemplazos` ones; run on main to see which also fail; fix the paths otherwise).
7. Anything that fails on main too: `## Log` line with the main run (Edit only).
8. `ruff format`/check on touched test files (old files lost imports), then `node .claude/tools/verify.mjs`, then `node .claude/tools/close.mjs` (offline: no push).
