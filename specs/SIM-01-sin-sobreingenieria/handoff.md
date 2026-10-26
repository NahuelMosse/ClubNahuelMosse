# Handoff SIM-01 app (T8 hecho en lib y tests)

Worktree rama `worktree-agent-ae2dd4c7a05e957e7`. Flutter: `export PATH="$PATH:/d/projects/flutter/bin"`, desde `apps/mobile`.

## Hecho (commiteado)
- T8 en lib: `reservas.dart` (`mias` pide `/reservas?cuando=` y lee `reservas`; sin `TandaDeReservas`/`tanda`/`despues`), `pantalla_mis_reservas.dart` (sin carga de más), `inicio/pantalla_inicio.dart` (sin `hayMas`, marcador PRÓXIMAS = cantidad), `admin/historial_reservas.dart` (sin marcadores `despues`/`siguiente`, queda `pagina`).
- `main.dart`: `_retomar` pasó a `retomarConReintento` (pública, para el test de ASM-08).
- Tests nuevos: `test/arranque_sin_conexion_test.dart` (ASM-08 widget), `test/mensaje_sin_red_test.dart`, `test/limite_de_espera_test.dart` (30 s; reemplaza el RED `sin_sobreingenieria_test.dart` "a los 30 s…" que falla por un bug del test: `onError` devuelve Object).
- git rm: `operacion_cliente_test`, `operacion_cliente_sin_verificar_rutas_test`, `operacion_registro_test`, `operacion_cliente_limite_test`, `historial_por_tandas_test`, `historial_global_por_tandas_test`.
- `flutter analyze --no-pub`: 0 issues. Suite completa antes de los últimos cambios: +596 -27; las fallas ajenas (rediseno/*, limpieza*, interfaz_accesible, tarjeta_reserva, horarios/tiles de pantallas_test) están sustituidas en ARQ-03 (L2-L19 de esa card).

## Falta
1. Log de la card (Edit al final de `## Log`, hoy el último es L16): líneas `replaces:` para cada archivo git rm de arriba, `sin_sobreingenieria_test.dart "a los 30 s…"` por `limite_de_espera_test.dart`, y `rediseno/pantallas_test.dart "inicio con más de una tanda de próximas el marcador dice 20+ @RED-03-ASM-13"` (ya no aplica; el archivo es mixto frozen: reemplazo sin ese test), más una línea de evidencia de T8.
2. Capturas: `flutter test --no-pub test/capturas/*_capturas.dart` sin --update-goldens (no llegó a correr); no hay captura de error de arranque en `test/capturas`.
3. Re-correr `flutter test --no-pub` completo en background (`node .claude/tools/wait.mjs <log> --until 'All tests passed|Some tests failed' --max 560`) y reportar fallas.
4. `integration_test/**` menciona tandas/referencia en 4 archivos (alta_espacio, notificaciones, consultar_horarios, soporte/acciones): revisar con grep si dependen de `despues`/`siguiente`/`referencia`.
