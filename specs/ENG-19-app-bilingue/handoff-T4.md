# Handoff T4 (admin) — builder ran out of turns

Worktree D:/Temp/w/eng19-t4, branch ENG-19-t4. Scope: apps/mobile/lib/features/admin/** only.

## Done (committed, except the last .arb edit)
- RED commit 4d97688, two code commits after it.
- All admin presentation files converted to l10n (`AppLocalizations.of(context).adminXxx`), incl. forms, traceability, void dialog, created screens, deactivation.
- Domain: `venue_problem.dart` (enum) + `venue_rules.dart` returns `VenueProblem?` (names `venueNameProblem`, `venueAddressProblem`, `opensAtProblem`, `closesAtProblem`); `space_price.dart` (`validPricePerHour`); `name_missing.dart`; `outside_hours.dart` holds `OutsideHours.of(...)` (old `outside_hours_text.dart` removed).
- Presentation: `venue_problem_text.dart`, `outside_hours_message.dart` (implemented with ICU plural keys), `space_form_fields.dart` (`priceError(l10n, text)`, `nameMissingText`).
- `flutter analyze --no-pub lib/features/admin lib/l10n` was clean before the last arb edit.
- Corrected S1 test: `test/bilingual_admin_panel_test.dart` (same title/tag, `textContaining('1 ACTIVE SPACE')`), replaces line written in `replaces-T4.md`.

## UNCOMMITTED / MUST DO FIRST
1. gen-l10n sorts placeholders alphabetically when the .arb has no `@key` metadata. I added `@key` placeholder-order metadata in `app_en.arb` for adminVenueSchedule, adminVenueScheduleShort, adminVoidBookingLabel, adminDeactivateVenueText, adminTraceBy, adminTraceByReason, adminOutsideNotice. **Run `cd apps/mobile && PATH=/d/projects/flutter/bin:$PATH flutter gen-l10n`** (not yet run after that edit), check the generated signatures follow the declared order (days, opening, closing / user, sport, date, schedule / name, address / who, date[, reason] / subject, reason, keeps) and that Spanish still loads; commit generated files. The `@key` blocks sit inside my contiguous block after "loginStart".

## Test run results (before the metadata fix; run from worktree root: `sh D:/Temp/w/herramientas/flutter-mobile.sh test/<file> ...`, paths relative to apps/mobile; ~9 min for 16 files, background + wait.mjs)
Failures all trace to the alphabetical-placeholder bug (swapped arguments), except those marked:
- bilingual_admin_test S1 (frozen, fails only on `'1 ACTIVE SPACE'`, replaced by bilingual_admin_panel_test; this one also showed "VOID BOOKING" not found in bilingual_admin_panel_test: the panel route `/admin` button `VOID BOOKING` — the semanticLabel/`adminVoidBookingLabel` order bug is the likely cause; re-check after regen).
- ASM-05: "La dirección es obligatoria" not found (Spanish run) — recheck after regen; may be a real issue (first tap with empty form, check `venue_form.dart` `error()` shows address when attempted).
- ASM-06: arg order bug of adminOutsideNotice.
- sedes_admin_test "cada sede con sus canchas, días y horario", editar_sede_test (3 tests), baja_sede_test, anular_desde_el_detalle_test (Por Ana Díaz): arg order.
- admin_en_ingles_test @ENG-09-S3 (frozen): expects the Spanish literal `'El motivo es obligatorio para anular'` inside a lib/features/admin source file. It now lives in the arb. This frozen test is broken by the change: copy it to `test/admin_en_ingles_es_test.dart`? It reads source text, so the copy must look the string up in `lib/l10n/app_es.arb` instead; append a `replaces:` line to `replaces-T4.md`.
- Passed in that run: 131 tests; remaining failures: 11 (list above).

## Left to do
- Re-run: bilingual_admin_test, bilingual_admin_panel_test, sedes_admin_test, editar_sede_test, baja_sede_test, anular_desde_el_detalle_test, admin_en_ingles_test, plus the 16-file batch.
- Run `test/bilingual_app_test.dart` scan: `features/admin` must not appear (single-word strings are not flagged, but all were moved).
- Each other frozen test the change breaks gets a `_es_test.dart` copy with app delegates + a `replaces:` line in `replaces-T4.md`.
- `dart format` on features/admin and test files; `flutter analyze --no-pub apps/mobile` clean.
- Strings of other builders still Spanish on admin screens (report them): `weekdaysLabel`, `OpenDays.text`, `venue.daysLabel`, `space.description(catalog)`, `readableDate`/`longDate`/`shortTime`, `confirmNewSchedule`, `showChangedMeanwhile`, `showBookingVoided`, `ErrorSnackbar`/`ResultScreen` (lib/common).
