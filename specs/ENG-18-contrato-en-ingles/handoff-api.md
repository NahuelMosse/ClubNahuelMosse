# Handoff ENG-18 (builder T1/T2/T5, API side)

## Done (committed)
- Production in apps/api/app in English (`platform` key fixed); apps/api/openapi.json regenerated (34 operations).
- T5 docs: apps/api/README.md, arquitectura.md, mapa-del-codigo.md (API tables only), system-design.md, glosario-ingles.md (additions to «Campos JSON» and «Rutas»). go_router screen routes untouched (OUT L3).
- T2 partial: tests/integracion and tests/escenarios translated with `python D:/Temp/w/herramientas/eng18-translate-tests.py <files>` (token based; idempotent; also translates `?when=historial` query values). Left untranslated on purpose: meta tests (en_ingles, english_schema, glosario, sql_in_english, codigo_legible, arquitectura, documentacion, migrations, over_english, restricciones) and all tests/unit (Python kwargs there; fix by hand).
- Last full run of integracion+escenarios (before the final translator pass, which also covered test_api_limpia_*, test_uuid_y_auditoria, test_repositorios_propios*, test_datos*): 48 failed, 360 passed, 2 skipped, 6 errors in 50 min (.validation/s2.log).

## Left (all: could not run)
0. FIRST: apps/api/tests/escenarios/test_seguridad_api.py line 243 has `parametrize(("desde", "hours"), ...)` and the function arg is `horas`: change the argname back to `"horas"` (collection error otherwise).
1. Rerun the suite by files (it takes ~50 min whole; run the failing files first): remaining failures by file: test_recuperacion_api (6), test_perfil_api (4), test_contract_over_english_schema (4), test_suite_confiable (3), test_espacios_api (2), test_requisitos_no_funcionales (2), test_cancelacion_forzosa (2), and one each in historial, reservas, anular_reserva, sin_sobreingenieria, api_limpia_*, render_rehearsal, contrato_publicado, confirmacion_cancelacion, english_schema, migrations_folder (check if it is mine), the README/doc tests (some are in the gate's --deselect list).
2. tests/unit with Spanish contract keys/values: hand edits (use-case error keys, `activa`, `usuario`).
3. `test_contract_in_english.py::test_every_hand_built_409_body...` is wrong (same admin, same data repeats idempotently as 201): replace in a new file, same tag, second post with `covered: True`, plus Log `replaces:` line.
4. `test_every_operation_id_is_fastapis_default...`: the routes list is empty (check fixture / sub-app); replace if the test is wrong.
5. Replace the ENG-17-ASM-01 tests (test_contract_over_english_schema.py, test_contract_values_over_english_schema.py; L5) by new files + `replaces:` Log lines; snapshots tests/unit/contrato_*_main.json compare through `contract_renames.comparable`.
6. Lint: `sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh`.
7. Log lines per task T1, T2, T5 with `node .claude/tools/log.mjs` (include the glossary additions).

## Not covered (turn budget)
Items 0 to 7: could not run.
