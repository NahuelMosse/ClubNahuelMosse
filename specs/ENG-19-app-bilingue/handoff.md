# Handoff ENG-19 · T1 and T5 (done); T2-T4 left to the next builders

Done (committed): the l10n setup (`apps/mobile/l10n.yaml`, `lib/l10n/app_{en,es}.arb` and the generated `app_localizations*.dart`), `lib/common/app_language.dart` (`resolveLanguage`, `useLanguage`, `currentLanguage`), `app.dart`, `main.dart`, `dates.dart` following the language, the login screen and its strings, `test/flutter_test_config.dart` and `integration_test/flutter_test_config.dart` (device es-AR), `test/soporte/montar.dart` (mounts with the app's delegates and the device's language; exports `invalidCredentialsMessage` in Spanish).

Regenerate after adding keys to the `.arb`: `cd apps/mobile && flutter gen-l10n` (Flutter at /d/projects/flutter/bin).

Tests: `test/bilingual_app_test.dart` (T1 and T5), `test/bilingual_price_test.dart`; replaced login copies: `pantalla_inicio_sesion_es_test.dart`, `teclado_en_el_login_es_test.dart`, `rediseno/movimiento_login_es_test.dart`, `rediseno/login_marca_es_test.dart` (Log L8-L24).

Left: T2-T4 move every other literal (the T5 scan lists them with file:line); `dates.dart` `duration()` still says `hora/horas`; `common/snackbar.dart` ('Cerrar aviso') and `common/text_field.dart` (password toggle tooltips) feed the T5 tooltips test; `rediseno/movimiento_pantallas_test.dart` @RED-04-S14 fails and its cause is not checked.
Every frozen test that mounts its own `MaterialApp` without `AppLocalizations.localizationsDelegates` breaks when its screen converts: copy it to a new file mounted with the delegates and add a `replaces:` Log line.
