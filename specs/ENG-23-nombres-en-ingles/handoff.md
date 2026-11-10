# Handoff T1 + T2 + T3 (builders 1 and 2)

Done and committed:
- T1/T2: routes, params, query keys, recovery link, identifiers of apps/mobile/lib (see earlier commit de2d90ce); tests and integration tests updated in place.
- Frozen tests that a rename had altered restored: `Estás modificando` (modify_booking unit and integration tests), the old Spanish route list in contract_in_english_test.dart.
- docs/technical/app-navigation.md cites the English routes and query keys (navigation_documented_test passes).
- The 4 loading_skeletons route tests fail on main too (a 30 s timer of the hung client); their new titles are declared in Log L4-L7 as replaced by loading_skeletons_screens_test.dart.
- T3: 475 comment blocks of apps/mobile/lib in English (generator scripts in D:/Temp/w/herramientas: eng23-t3-*.mjs), developer messages (config.dart, tokens.dart, unhandled_errors.dart, api_client.dart), dead commented-out code in space_card.dart removed. `node --test tests/app-names-in-english.test.mjs`: 4 pass. `flutter analyze`: no issues. `dart format`: clean.
- Log L4-L9 written.

Not done:
- The flutter gate line (`once.mjs flutter -- sh eng23-flutter.sh`, ~18 min) was NOT run: the hook refuses a builder running the whole suite. The last builder / main thread runs `node .claude/tools/verify.mjs`. Expected open: only what was red on main (declared replaced).
- Single files verified green on their own: contract_in_english, modify_booking, navigation_documented. Other T1/T2 red tests seen by builder 1 in a full run (bilingual_*, keyboard_in_login, cleanup, architecture) were not re-checked individually; check them in the verify log against main.
- Spanish in code not translated (not T3 scope): the `AUTH_EMULADOR` dart-define name and device keys (T4), legacy API paths in integration_test (T8).
