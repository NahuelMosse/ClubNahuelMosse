# Handoff ENG-13 API (builder 5)

Worktree D:/Temp/w/ingles-api, branch `ingles-api`. Never push/PR/touch main or `ingles`. Env: `UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"`,
`FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`. Run files from the worktree ROOT: `sh D:/Temp/w/herramientas/arq01-pytest.sh -v -p no:cacheprovider --tb=line <files relative to apps/api> > /tmp/x.log` in background, wait with `node .claude/tools/wait.mjs /tmp/x.log --until "DONE exit" --max 570` (append `echo DONE exit $?`). Do not run two runs at once (shared DB).

## Done (commit 3a1005e)
Fixed and passing: test_config_en_ingles, test_mapa_por_funcionalidad, test_glosario_ingles(_completo), test_sin_supresiones, test_capas_funcionalidades, test_codigo_legible, test_api_limpia_funcionalidades, test_brevo_email, test_modulo_reservas_en_ingles. Edits: mapa-del-codigo.md, glosario row (`Errores` for spaces written `(espacios y horarios) → ErrorBody` so it no longer joins), tests paths rutas->routes, signature compare skips renamed names.

## Open: 26 failures in files run here (/tmp/g6.log), compare each with D:/Temp/w/main before fixing (only fix those that pass on main)
Causes seen:
- Old attribute names left in tests: test_api_limpia_reservas.py (`Booking.inicio` -> English field), test_notificaciones_api.py:186 (`Notice.datos` -> `data`), :325.
- escenarios/test_cancelacion_forzosa*.py, test_confirmacion_cancelacion_reglas, test_despacho_robusto: sent notices end 'fallida' instead of 'enviada' (a real behavior difference or test double using old names: e.g. a fake channel/sender with old method names; inspect traceback with -x on one test).
- test_suite_confiable*.py: refer to `modules/reservas/casos_de_uso.py` (-> bookings/use_cases.py) and `_endpoints_que_usa_la_app` text at :416.
- test_documentacion_supuestos_vigente.py:142 (ASVS evidence paths with old module paths, e.g. `..._uso.py`), :191 and test_documentacion_vigente.py:129 (`pantalla_de_carga`: probably main also fails; check mobile docs on main).
- test_requisitos_no_funcionales.py:323: README env var set lacks `DATABASE_URL`/`URL_PUBLICA` names (README now English names; test expects the old set or both).
- test_base_en_ingles.py:154 and test_modulos_cuenta_en_ingles.py:127 (`password_recovery/email.py` expected by test file list? check), :152 ('email.py: no existe'), :163 (contract schema compare with main).
Passed in that run (111): the rest of those files incl. test_confirmacion_cancelacion, _atomicidad, _agrupado partial, test_requisitos_no_funcionales_con_salud/_readme_app, test_documentacion_modelo_*, test_documentacion_del_modelo.
