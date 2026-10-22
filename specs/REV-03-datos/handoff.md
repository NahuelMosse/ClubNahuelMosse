# Handoff REV-03 (builder 2)

Entorno: `TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev03_test`, `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702` (el 8701 es de otro agente), `export PATH="/d/projects/flutter/bin:$PATH"` para flutter. Los hooks de shell a veces dan timeout por carga: reintentar. Logs en `/tmp/rev03_*.log` (nombres propios: /tmp lo comparten otros agentes). El pytest de los dos archivos tarda ~15 min: correr en background con `nohup sh -c '... > /tmp/rev03_x.log; echo FIN >> ...'` y `node .claude/tools/wait.mjs /tmp/rev03_x.log --until '^FIN' --max 570`; correr tests sueltos con `-k` mientras se arregla.

## Hecho
- Bug `ReservasSql.de_usuario`: próximas sin LIMIT y `hay_mas=False` (infraestructura/reservas.py). Commiteado.
- Dart: `apps/mobile/test/historial_global_por_tandas_test.dart` (2.º test de T4, tag @REV-03-S3) pasa; `historial_por_tandas_test.dart` pasa. `lib/admin/historial_reservas.dart` ya usa `despues`/`siguiente` (sin cambios).
- Corrida de `test_datos.py` + `test_datos_tandas_y_cola.py`: 42 pasan, 4 fallan (todos error del TEST, el código no hay que tocarlo salvo que se vea lo contrario):
  1. `test_con_el_mismo_inicio_el_historial_global_pone_primero_el_id_mas_alto`: espera 21 filas y la tanda es de 20 (`assert 20 == 21`).
  2. `test_de_cada_intento_quedan_tomada_en_e_intentos_y_el_error_va_al_log`: `intentos == 2`, no 1: `_cancelar` ya despachó una vez antes de forzar `envio='pendiente'`; hay que reiniciar `intentos=0` (o esperar 2).
  3. `test_el_recordatorio_de_una_reserva_que_ya_empezo_no_se_reintenta`: el UPDATE `inicio = now() - 30 min` viola `reserva_check` (probablemente `creado_en <= inicio` o similar): mover también `creado_en` hacia atrás en el mismo UPDATE.
  4. `test_la_trazabilidad_del_admin_muestra_el_aviso_fallido_como_fallido`: `aviso_envio` es `None` en `/reservas/todas` para la cancelación del usuario; hay que usar una cancelación forzosa del admin (aviso de cancelación forzosa) o ver qué tipo de aviso expone `reserva_con_estado`.

## Falta
1. Esos 4 tests están commiteados con tag (congelados): reemplazarlos en archivo NUEVO (p. ej. `tests/escenarios/test_datos_correcciones.py`) con el mismo tag `@REV-03-S?`/`@assumption`, y agregar al Log `- L<n> · <fecha> · replaces: <archivo> "<test>" · <por qué> · by: <archivo> "<test>"`. Si el nuevo falla por el código, arreglar el código (T1..T3 files).
2. Gate: `node .claude/tools/verify.mjs` en background con log; `attacks:` va a reportar «PASSED · GET with a foreign Host» (hallazgo 25-S2, de REV-01): dejarlo fallido y reportarlo. Las líneas `mutate ... historial_por_tandas_test.dart` no incluyen el archivo nuevo del test Dart (no tocar el Gate; declararlo).
3. Log: una línea por tarea T1..T4 en `## Log` de card.md. No pushear.
