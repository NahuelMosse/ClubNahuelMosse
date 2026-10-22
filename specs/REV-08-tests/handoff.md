# Handoff T1 (REV-08), segunda tanda

Entorno: TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev08_test, FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702, PATH con /d/projects/flutter/bin. Python: `apps/api/.venv/Scripts/python.exe -m pytest`. Corridas largas en background, log /tmp/rev08-<n>.log, espera con `node .claude/tools/wait.mjs <log> --until ' in [0-9.]+s'`.

## Hecho
- Commit f5164ef: `apps/api/tests/unit/test_casos_de_uso_reservas.py`, 48 tests en memoria, pasan sin base ni emulador (6,9 s). Llama a las 7 funciones públicas como `nombre(`.
- Sin commitear: `apps/api/tests/escenarios/test_contrato_publicado.py` (reemplazos de RNF-01-H04-01 y H06-02 contra el contrato publicado, cota 28, sin leer Dart, más el reemplazo del test de S4). Falta correrlo y commitearlo.

## Hallazgos: tests congelados de test_suite_confiable.py que están mal (no se pueden editar: el guard lo impide)
Corrida entera: 13 pasan, 5 fallan.
1. `test_con_la_variable_del_emulador_ausente...` y `test_con_el_emulador_apagado...` (S5): asertan `'passed' not in salida`, pero la corrida interna muestra «1 passed, 2 errors» (pasa un test sin API). El conftest ya falla bien con el mensaje; el aserto es el equivocado.
2. `test_los_casos_de_uso_de_reservas_se_prueban_sin_base_ni_emulador` (S7): usa `CASOS_DE_USO`, no definido en el archivo: NameError. El subproceso sí sale 0.
3. `test_cada_funcion_publica_de_reservas_tiene_su_unitario` (S7): falla con las 7 funciones «faltantes» aunque `codigo` está cargado y el mismo regex las encuentra fuera de pytest. Causa sin diagnosticar (revisar si algo sombrea `re` o `_casos_de_uso` en el módulo).
4. `test_rnf_01_h04_01_se_prueba_contra_el_contrato_publicado` (S4): exige que `_endpoints_que_usa_la_app` no esté en el archivo congelado test_requisitos_no_funcionales.py, que no se puede editar.

## Falta
a. Reemplazar los 5 en un archivo nuevo (p. ej. tests/escenarios/test_suite_confiable_reemplazos.py) con el mismo tag `@REV-08-S<n>` y título distinto; una línea `replaces:` por test al final del `## Log` de card.md. Ojo: `verify.mjs` `failingTests` no parsea la salida de pytest (`FAILED ...`), así que `passed with replaced` no aplica a la línea `suite:`; si queda roja por eso, declararlo como hallazgo del kit en el reporte.
b. Correr test_contrato_publicado.py y commitear.
c. README apps/api/README.md: documentar `--sin-emulador` (salta los tests de API) y que sin él la corrida falla con «hace falta el emulador de Firebase Auth» (hay un test del README del backend: mantener «configurar/ejecutar/probar/desplegar» y las variables).
d. Gate `node .claude/tools/verify.mjs` en background (VERIFY_TIMEOUT_MIN=45); «pending REV-01 group 2» para lo que dependa de REV-01 grupo 2; `attacks: PASSED · foreign Host` es el hallazgo 25-S2 de REV-01: se deja rojo. Mutación: `mutate apps/api/app/aplicacion/reservas.py`.
e. Log: una línea por tarea (T1) con evidencia. No pushear.
