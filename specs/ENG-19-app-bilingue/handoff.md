# Handoff T2 (ENG-19, worktree D:/Temp/w/eng19-t2, branch ENG-19-t2)

## Done
- RED committed (fe85e51); code commit: session/users/home/router converted to l10n; ~100 keys in app_en.arb and app_es.arb after appName; `FieldProblem` enum in users/domain; `fieldProblemText` in users/presentation.
- `test/soporte/montar.dart` wraps the screen in `KeyedSubtree(key: UniqueKey())` so a second mount in one test starts with a fresh state. This was the cause of the two failures of `bilingual_account_test.dart` (state reused after re-mounting). Not re-run after the change.
- registration_rules.dart uppercase regex written with \u escapes (literal scan).

## Left
1. Re-run `bilingual_account_test.dart` (expected green now) and the scan in `bilingual_app_test.dart`: confirm no file of session/users/home/router is listed.
2. Frozen tests broken by T2 that need an `_es_test.dart` copy (same title and tag, mounted in Spanish with the app delegates, `FieldProblem` values instead of strings in domain tests), plus a line in `specs/ENG-19-app-bilingue/replaces-T2.md` each (do NOT run log.mjs):
   - compile errors: capas_test (87-113), reglas_registro_test, registration_limits_rules_test (`requiredMessage` param gone, rules return FieldProblem), pantalla_registro_test:165 (`validateEmail('ana')!`), recuperacion_test:95 (`linkSentNotice` removed; use the .arb text).
   - runtime failures (probably MaterialApp without delegates -> `AppLocalizations.of` null check): accesibilidad_registro_test, errores_compartidos_test (2), interfaz_accesible_test (1), reintento_tras_corte_test (2), rediseno/movimiento_pantallas_test (7), rediseno/pantallas_test (4), rediseno/sobre_foto_test (8), rediseno/movimiento_reducido_reemplazo_test (1).
   - Likely not mine, check against main before copying: rediseno/paleta_rediseno_test (3), componentes_test, boton_deshabilitado_test.
3. `dart format`, `flutter analyze --no-pub`, commit.

## Run
`cd D:/Temp/w/eng19-t2 && sh D:/Temp/w/herramientas/flutter-mobile.sh test/<file> ... > apps/mobile/.validation/x.log 2>&1` (from the worktree root, not apps/mobile).

## Outside my folders
common/password_form.dart, snackbar.dart, text_field.dart, error_dialog, network_failure, bottom_bar, result may hold Spanish (T4). `volverA` in T3's AvailabilityScreen is a String the router passes localized. `showNetworkError(context, ErrorDelServidor(0))` is called from account_card.
