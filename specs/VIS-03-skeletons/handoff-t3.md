# Handoff T3 (account skeletons)

## Done (committed)
- `home_skeleton.dart`, `notice_card_skeleton.dart`, `my_profile_skeleton.dart` wired into their screens; `home_hero.dart` reserves the marker space (`_markerSpace` 136) while there is no data.
- `apps/mobile/test/skeletons_account_closed_test.dart`: replaces the profile and ASM-05 tests of `skeletons_account_test.dart` (they fail only from test defects: pending 30 s timer, semantics handle). Log L4/L5 in card.md. Passing: `sh D:/Temp/w/herramientas/flutter-mobile.sh test/skeletons_account_closed_test.dart` (2/2); `skeletons_account_test.dart` home and notifications tests pass (2/4; the other 2 are superseded).
- The lead must drop the two superseded tests from the gate (the old file cannot be edited).

## Left
1. `apps/mobile/test/capturas/skeletons_account_capturas.dart`: dark 393x852 golden, loading next to loaded for home, notifications, profile; style of `reservas_admin_capturas.dart` (`setUpAll(cargarFuentes)`, `expectLater(find.byType(MaterialApp), matchesGoldenFile(...))`); open the app like `_open` in `skeletons_account_closed_test.dart`; generate with `--update-goldens`.
2. Gate: also run `test/esqueletos_de_carga_test.dart test/perfil_test.dart test/inicio_test.dart test/notificaciones_test.dart`; `dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test/skeletons_account_test.dart`; `flutter analyze --no-pub apps/mobile`.
3. Log line for the captures, commit only own paths.
