# Handoff REV-03 (builder 1)

Entorno para todo pytest y gate: `TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev03_test`, `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8701`.

## Hecho
- El código de T1..T3 ya existe y está commiteado (0008, marcador.py, tandas, cola recuperable). Tests S1..S8 ya existen en `apps/api/tests/escenarios/test_datos.py` (CONGELADO: el guard rechaza todo Edit; los tests nuevos van en archivo nuevo).
- Commiteado en RED: `apps/api/tests/escenarios/test_datos_tandas_y_cola.py` con los títulos que faltaban de T2 y T3 (ASM-01 a mano, 03, 07, 08, 10, 12, 13, 16, OpenAPI) y T1 (ASM-15), T3 (ASM-09 x2, ASM-14, ASM-04 confirmación, ASM-17). NO se corrió todavía: puede haber fallos por error del test (p. ej. `aviso_envio` en `/reservas/todas` para una cancelación de usuario, restricciones al mover `inicio` en ASM-14, plan EXPLAIN en ASM-12, conteo de `count(*)` en ASM-10). Si un test es incorrecto: reemplazarlo en archivo nuevo con el mismo tag y línea `replaces:` en el Log.

## Falta
1. Correr `uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_datos_tandas_y_cola.py` y arreglar.
2. Bug conocido: `ReservasSql.de_usuario` (apps/api/app/infraestructura/reservas.py:126) aplica LIMIT también a `proximas`; ASM-16 pide próximas enteras y `siguiente: null` (sólo `historial` va por tandas). Ajustar infraestructura/reservas.py (sin LIMIT en próximas) y `mis_reservas` / `interfaz/reservas.py`.
3. Dart (T4): crear el 2.º test en `apps/mobile/test/historial_por_tandas_test.dart` ("el historial global del admin trae la tanda siguiente y conserva la posición @REV-03-S3"); ese archivo ya tiene tagueado el 1.º test y está congelado: ponerlo en archivo nuevo con el mismo tag. Revisar que `lib/admin/historial_reservas.dart` use `despues`/`siguiente`.
4. Unit S5 `aviso_sin_enviar` ya existe en `tests/unit/test_despacho_de_confirmaciones.py`.
5. Gate: `node .claude/tools/verify.mjs` en background con log; `app:`/`attacks:` usan D:/Temp/w/herramientas/api-app.sh y api-attacks.sh (si fallan, reportar el error exacto). Mutaciones: ver `## Gate`. Anotar en `## Log` una línea por tarea. No pushear.

## Gates que pasan
Ninguno corrido aún.
