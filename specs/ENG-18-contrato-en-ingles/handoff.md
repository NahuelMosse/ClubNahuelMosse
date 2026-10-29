# Handoff · ENG-18 T3/T4 (apps/mobile)

## Done (committed)
- lib/: every contract literal of apps/mobile/lib is English (commit 5b001cc plus: `traceability.dart` `'sent'`, doc comment in
  `booking_history_entry.dart`). ASM-07 done (status chip/cards use `status.label`).
- Test fixes in this round (all in apps/mobile/test): notification kind defaults (`reminder`, `five_minute_reminder`), `/read`,
  status literals (`active`, `voided`, `canceled`, `completed`) and role default `user` (script
  `D:/Temp/w/herramientas/eng18-mobile-values.mjs`), profile key `first_name`, screen routes restored (`/sedes`, `/reservas`,
  `/notificaciones`, `/registro`; script `eng18-mobile-screen-routes.mjs`), query `when=history|upcoming`, `since`, `kind`,
  `sport`, `number`, `reason`, `/slots`, `/spaces` in fakes, delivery values `sent|no_permission|no_channel|failed`.
- Baseline: main has 26 failing tests of its own (`.validation/base-main.fail`, run of `test/` on the main repo checkout; the
  rediseno/*, skeletons_*, esqueletos_* ones are pre-existing). Compare with `comm -13 .validation/base-main.fail <new>.fail`
  (build a .fail with `grep -aE "\[E\]$" log | sed -E 's/^[0-9:]+ [+-][0-9]+( -[0-9]+)?: //; s#.*/apps/mobile/##' | sort -u`).
- Last full run (mobile5.log): +677 -57; since then ~12 more fixed, not re-run.

## Left (Not covered, turn budget: could not run)
1. Re-run `sh D:/Temp/w/herramientas/flutter-mobile.sh test/ > .validation/mobile6.log` and diff against the baseline. Known
   still failing new ones: skeletons_account_test (2: Mi perfil, skeletons de cuenta; fake probably has a Spanish key/route),
   skeletons_bookings_test "Buscar cancha" (a CircularProgressIndicator stays: fake answers 404/ErrorDelServidor, probably
   query/route keys), buscar_cancha_test:297 (200 % text), sedes_usuario "sin conexión", detalle_y_filtros_reservas
   ("detalle muestra lo vigente"), modificar_reserva/reservar ("horario se ocupó": error key `slot`), movimiento_pantallas
   "filtrar por deporte", transiciones "pantalla de resultado", limpieza_plan_test.
2. Meta tests asserting the Spanish contract: account_in_english_test, bookings_in_english_test, admin_en_ingles_test,
   base_en_ingles_test ("la base de la app no toca apps/api" fails only because the API builder works in the same worktree;
   "errores por campo ... clave errores" asserts Spanish key): replace with new files (same title + tag) and a
   `replaces:` Log line via `node .claude/tools/log.mjs`. rutas_de_la_api_test needs apps/api/openapi.json regenerated (API builder).
3. Write apps/mobile/test/contract_in_english_test.dart (4 tests of T3, tags per `tests:` line); Log: its RED came after the code.
4. Gates: `sh D:/Temp/w/herramientas/flutter-mobile.sh`, flutter analyze (`eng14-ruff-mypy-flutter-analyze.sh` flutter part),
   `node D:/Temp/w/herramientas/eng18-presentation-strings.mjs 805c7f4`; `dart format` on touched files; Log lines per task;
   docs/features under apps/mobile if any.
5. Nothing of this round is committed except what the final git commit below includes (apps/mobile + handoff only).
