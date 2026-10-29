# Handoff ENG-19 · T4b (notifications, common, Role and NotificationKind labels)

Worktree D:/Temp/w/eng19-t4b, branch ENG-19-t4b. Commits: 47afbcb RED, the .arb block + generated files, 3fe668c code.

## Done
- RED: `test/bilingual_common_test.dart` (committed, frozen); fixed copy `test/bilingual_common_fixed_test.dart` passes (2/2). `test/bilingual_replacements_t4_test.dart` passes. `bilingual_app_test.dart` tooltips test passes; notifications and common no longer appear in the literal scan.
- .arb: one block after `loginEmailRequired` in app_en.arb and app_es.arb, regenerated and committed.
- Code: all of lib/common (error_dialog, bottom_bar `Section.title(l10n)`/`AdminSection.title(l10n)`, day_timeline, dates `duration()` through `lookupAppLocalizations`, snackbar, text_field, top_bar, password_form, ...), features/notifications (domain `Arrival`/`ArrivalWhen`/`dayOf`/`arrivalOf`/`DayGroup.arrival`, presentation `arrival_text.dart`, bell, card, panel, screen, disabled), `Role` and `NotificationKind` lost `label`. `flutter analyze` is clean for lib; the only errors are in the frozen originals `test/notificaciones_test.dart` and `test/account_in_english_test.dart`, which no longer compile.
- Replaces: `specs/ENG-19-app-bilingue/replaces-T4b.md` (7 lines); copies `test/notificaciones_es_test.dart` (64 tests, pass), `test/account_in_english_t4_test.dart`.

## Not covered (turn budget), each *could not run*
- Frozen test files that `import 'notificaciones_test.dart' show ...` no longer compile (e.g. `skeletons_account_test.dart`); find them with Grep `notificaciones_test.dart` in apps/mobile/test and copy each to a `_es_test.dart` importing `notificaciones_es_test.dart`, same titles and tags, plus a `replaces:` line each in replaces-T4b.md.
- Affected batch run (`.validation/batches.log`): 22 failures among 128 passes. Not yet triaged: `sin_sobreingenieria_test.dart` "a los 30 s sin respuesta la app avisa que el servidor no responde @SIM-01-S4", `skeletons_bookings_test.dart` "Buscar cancha carga los resultados ... @VIS-03-S1", `teclado_en_el_login_test.dart` (3, replaced already by `_es_test`, L19-L21), plus the importers above. Several may be failures of the base (ARQ-03, RED, VIS, SIM listed in Log L25) or a dialog that now reads l10n without the app delegates (a frozen test mounting its own MaterialApp: copy it with the delegates).
- Strings of other tasks the notification and common screens show: none found; `common/missing_fields.dart` untouched (T4 admin design said to change `focusFirstMissing` to a record parameter; that belongs to the admin builder).
- Run `dart format` and `flutter analyze --no-pub apps/mobile` once more after the copies.
