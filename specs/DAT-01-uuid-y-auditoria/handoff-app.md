# Handoff T3 (apps/mobile)

Worktree D:/Temp/w/dat01app, branch card/DAT-01-app. Flutter: `export PATH=$PATH:/d/projects/flutter/bin`; `flutter pub get` already ran.
The worktree checkout took ~8 min at the start (git reset --hard running); it is finished now.

## Done
- RED committed (c841c21): `apps/mobile/test/ids_uuid_test.dart` (both planned titles; fails to compile today).
  It needs: `AvisoTocado.desdeDatos(Map<String, Object?>)` and `AvisoTocado.ruta`, String ids on all models,
  and `catalogoJson` from test/soporte/admin.dart (verify it is exported there; it is used in usuario.dart).

## Left (no lib code written yet)
1. Models id int -> String (reserva_id in Notificacion: String if present, else null):
   espacios/espacio.dart (id, sedeId), sedes/sede.dart (id), reservas/reservas.dart (id, espacioId, sedeId),
   admin/historial_reservas.dart (id, espacioId, sedeId, usuarioId, filtros sedeId, `detalle(String id)`).
2. Services/params: espacios/espacios.dart (sedeId, id params, darDeBaja), sedes/sedes.dart (id, darDeBaja),
   reservas/horarios.dart (espacioId, reservaId, sedeId), notificaciones/notificaciones.dart `leer(String id)`,
   notificaciones/centro.dart (sets `<int>` -> `<String>`; line ~221 `masNueva` fold max id: with UUIDv7 use
   string comparison or the list order, check context).
3. Screens: app.dart (drop `int.tryParse(...) ?? 0` for sede/cancha, `reservaId`; keep `horas` int),
   reservas/pantalla_horarios.dart (sedeId, espacioId, `_elegida`, `_elegirCancha`), reservas/pantalla_mis_reservas.dart
   (reservaId, `_cancelando`), reservas/cancelacion.dart (`void Function(String? id)`), sedes/pantalla_sede.dart (sedeId),
   inicio/pantalla_inicio.dart (`_cancelando`), admin/pantalla_espacios_admin.dart + pantalla_sedes_admin.dart (`_dandoDeBaja`),
   admin/pantalla_filtros_reservas.dart (`_sedeId`), sedes/fotos.dart (`portadaDeSede(String id)`: sum of code units % n).
4. DAT-01-ASM-05: in notificaciones/sistema.dart `AvisoTocado { tipo, String? reservaId, bool antiguo }`,
   `AvisoTocado.desdeDatos(Map<String,Object?> data)`: reserva_id matching a UUID regex -> reservaId; non-empty non-UUID
   (numeric) -> antiguo = true; `String get ruta => antiguo ? '/notificaciones' : rutaDelAviso(tipo, reservaId)`.
   sistema_fcm.dart `_aviso` uses desdeDatos(mensaje.data); app.dart lines ~116/121 use `aviso.ruta`.
   `rutaDelAviso(TipoDeNotificacion?, String? reservaId)` in notificacion.dart.
5. Update non-frozen tests in place (ids as strings: fixtures `"id": 1` -> `"id": "1"`, Dart `id: 1` -> `'1'`, API fake
   routes/queries). Affected: test/soporte/{usuario,montar,admin}.dart and ~28 test files (grep `"id":`, `_id":`, `id:`).
   Good job for a `grunt` after the lib compiles. Frozen tagged tests that must change: new file with same titles/tags + a
   `replaces: ... · by: ...` line in the card's ## Log.
6. Add every extra lib file changed to T3's file list in card.md (so far the card lists only 7 files; the list above is bigger).
7. Checks: `flutter analyze --no-pub` 0 issues; full `flutter test` in background with log (wait.mjs --until
   'All tests passed|Some tests failed' --max 560): only the failures already declared replaced in ARQ-03 / SIM-01 cards are
   allowed; `sh -c 'flutter test test/capturas/*_capturas.dart'` without --update-goldens, all identical.
8. Log line in card.md `## Log` for T3 and commit.
