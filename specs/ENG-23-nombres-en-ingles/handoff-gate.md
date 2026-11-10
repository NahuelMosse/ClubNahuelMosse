# Handoff ENG-23 (gate closing)

## Done
- Item 1 (suite, 9 failures): the stale frozen tests stay in their files (the CI verdict and the ENG-24 census need them); each is declared `replaces:` in the Log (L38-L44) with its passing replacement. Updated in place: `intent://app/recover?code=` in test_recovery_api.py and test_contract_texts_in_english.py. New: apps/api/tests/scenarios/test_render_connection_string.py (matches `dpg-` plus an id). The 7 related files: 41 passed, 1 skipped (the Render rehearsal needs ENG17_REHEARSAL_URL).
- Item 2: docs/getting-started.md cites api_routes.dart; `npm ci --prefix docs-site` done. `node --test tests/*.test.mjs docs-site/tests/*.test.mjs`: 58 pass, 0 fail.
- Item 3: overdesign for `close()` declared (L37): ApiClient owns the private http.Client; removing it would expose the client.
- Item 4: seed_admin.py usage text uses admin@example.com.
- Item 5: K4 declared (L33-L36); also renamed the leftover Spanish `vencida` to `expired` in availability_screen, space_search_screen, home_screen and my_bookings_screen.
- Item 6 (API): mutate on password_recovery/use_cases.py and users/password.py gives exit 3 (no operator), declared (L45, L46).

## Not covered (turn budget), each *could not run*
- Dart mutation: `sh D:/Temp/w/herramientas/eng23-mut-dart.sh` was started in the background; per-file logs in .validation/mut-dart-<name>.log, index in .validation/mut-dart.index, `.validation/mut-dart.done` when finished. redirect.dart survived 3/3 because no test exercised it: apps/mobile/test/redirect_by_role_test.dart was written (cases is `final`) and not yet run. Rerun the redirect.dart mutation with that test. For every other file read its log, add a test per survivor or declare `declared · mutate · <file> · <why>` for exit 3.
- Check the test selection of each file in mut-dart.index (some may be empty or too narrow).
- `dart format lib` (the four screens edited for `vencida`), then `node .claude/tools/once.mjs lint -- sh D:/Temp/w/herramientas/eng23-ruff-mypy-flutter-analyze.sh`.
- Full gate: `KIT_APP_START_TIMEOUT_S=480 node .claude/tools/verify.mjs > D:/Temp/w/eng23-verify2.log 2>&1` in the background, then `node .claude/tools/required.mjs`.
