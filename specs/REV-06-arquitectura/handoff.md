# Handoff · REV-06 · mutaciones

## Hecho
- Kit 6.5.4 instalado (settings.json local conservado). Gate con envoltorios en `D:/Temp/w/herramientas/` (`lint-api-rev06.sh`, `flutter-app-rev06.sh`, `flutter-mobile.sh <test>`); no usar `sh -c` ni `cd … &&`.
- `reservas/reservas.dart`: `test/reserva_desde_json_test.dart` mata el `==`→`!=` de `_enElClub`; mutación 1/1, exit 0 (Log L90).
- `comun/tarjeta_reserva.dart`: 3 mutantes de tamaño de ícono declarados en `equivalents.md`; mutate sale 1 (0 muertos, 3 equivalentes). Es (presentation): required.mjs no lo pide (L91).
- Python: 15 archivos con exit 3 «no operator applies» (L92).
- Lint registrado: `once.mjs lint -- sh D:/Temp/w/herramientas/ruff-mypy-api-rev06.sh apps/api/tests` y `once.mjs lint -- dart analyze apps/mobile/test` (L93).
- `node .claude/tools/required.mjs` sale 0.

## Falta
- Decidir la línea `mutate apps/mobile/lib/comun/tarjeta_reserva.dart` del Gate: con los 3 mutantes equivalentes mutate.mjs sale 1 y verify la va a dar roja; el archivo es (presentation) y el kit no lo exige.
- `apps/mobile/build` está movido a `D:/Temp/w/rev06-mobile-build-aside` (copy-tree lo copiaba y la mutación no arrancaba); es salida de compilación, se regenera.
- verify y cierre: no corridos.
- Correr con FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702 y PATH="/d/projects/flutter/bin:$PATH".
