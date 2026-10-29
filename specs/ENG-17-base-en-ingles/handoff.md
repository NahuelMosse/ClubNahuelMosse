# Handoff T4 (tests SQL to English schema)

Done (committed): SQL inside `text(...)`, `_falla(...)`, `_uno(...)` translated in 43 test files under apps/api/tests
(script: D:/Temp/w/herramientas/t4_sql.py, `write <files>`; idempotent), plus row attribute reads and stored-value
asserts fixed by hand in the files that failed. test_uuid_y_auditoria.py keeps the 0009 flow with old names
(`_sembrar_0009`, `TABLAS_CON_ID`, `REFERENCIAS`) and has head versions (`_sembrar`, `*_ACTUAL`).
test_sin_sobreingenieria_api.py keeps old names in the 0009 migration test only.

Left:
1. Path `migraciones` -> `migrations` (NOT yet applied; the sed was blocked by the context cap):
   unit/test_base_en_ingles.py:191, unit/test_documentacion_del_modelo.py:9, unit/test_glosario_ingles_completo.py:72
   (string "apps/api/migraciones/versions"), unit/test_modulos_cuenta_en_ingles_actual.py:32,
   unit/test_modulo_notificaciones_en_ingles.py:68, unit/test_modulo_reservas_en_ingles.py:86,
   escenarios/test_documentacion_modelo_uuid.py:21, escenarios/test_documentacion_vigente.py:134,143.
2. Run the 43 changed files (`git diff --name-only HEAD~1 -- apps/api/tests`, paths relative to apps/api):
   `sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider <files>` in background (about 10 min), then
   fix failures that are not from app/ repositories. Check test_datos.py / test_datos_tandas_y_cola.py /
   test_datos_migraciones*.py: helpers at head (e.g. test_datos.py:71-234, test_datos_tandas_y_cola.py:37,108)
   may still use old names while tests below 0012 must keep them.
3. Still to review: quoted index/constraint names in non-text SQL, `SELECT ... AS tipo` alias in
   test_uuid_y_auditoria.py (alias kept, reads `f.tipo`), tests asserting stored values via helper functions.
4. Commit: "ENG-17: el SQL de los tests sigue al esquema en inglés (T4)" + Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>.
