# ENG-22 handoff (phase 2, shared names)

## Done: API side (apps/api/tests)

98 renames recorded in `D:/Temp/w/eng22-maps/shared.tsv` (`old<TAB>new<TAB>defining file`): conftest fixtures (`motor`, `unico`,
`iniciar_sesion`, `token_admin`, `token_usuario`, `sede`), the shared names of `test_data`, `test_reminder`, `test_basketball`,
`test_notifications_api`, `test_documentation_current`, `test_base_in_english`, `test_notice_by_email` and others, the attributes of
`Member`/`FakeChannel`, and the keyword params `permission`, `days`, `minutes`, `created`.
Tools: `D:/Temp/w/eng22-maps/ren_api.py` and `ren2.py` (tokenize-based: strings and comments untouched).
Fixed after the first collect: parametrize string `"sede"` in `unit/test_name_composite.py`, `__all__` in
`integration/test_api_clean_booking_moved.py`, three E501 lines, isort (`ruff --fix`).
Checks: ruff was clean after the fixes (last run: "Found 4 errors (4 fixed, 0 remaining)", then it passed). The second collect-only
run is in `D:/Temp/w/eng22-collect2.log` (started, result not read: *could not run* to confirm 831 collected).
The first collect gave 815 collected + 1 error (fixed above), so 831 is expected only when that file collects.

## Not covered (turn budget)

- Mobile side (apps/mobile/test, integration_test): *could not run*. Nothing was applied. The tool is ready:
  `D:/Temp/w/eng22-maps/ren_dart.py` (Dart-aware lexer `dartlex.py`; dry run by default, `--write` applies; scope = defining file +
  every file that imports it). Its map covers test/support/{admin,fixed_clock,mount,user}.dart,
  integration_test/support/{actions,network}.dart, my_bookings_test, void_booking_test, interface_accessible_test,
  notifications_test and notifications_spanish_test. Dry run: 166 files, 3808 edits, no name declared in lib.
  Two collisions to fix in the map before `--write`: `montar>mount` collides with the local `mount` of
  test/bilingual_account_test.dart (use `mountScreen`), and `ahoraClub>clubNow` collides with the local `clubNow()` of
  test/redesign/motion_screens_test.dart and screen_motion_spanish_test.dart (use `noticesNow`). Both edits are one-word `sed`s in
  the map.
- Then: record the renames in `shared.tsv` (the map in `ren_dart.py` is the source), run `flutter analyze` in the background
  (~5 min) to `D:/Temp/w/`.
- Not mapped on the app side: named parameters and members of the shared helpers/classes (`concedido`, `tarda`, `olvidos`,
  `respuesta` of `SistemaFalso`/`SistemaLento`/`CredencialesLentas`, `ApiFalsa` members other than `alPedir`, the named params of
  `montar`, `montarAdmin`, `montarUsuario`, `crearCuenta`...). Each must be checked against lib (ASM-01: `oscuro:` stays).
  Private names (`_sedeJson`, `_catalogoJson`...) are file-local, left for the file-local phase.
- API names not renamed because they are file-local (defined and used in one file): the many local `_con`, `_registrar`,
  `_reservar`, `_espacio`, `socio`, `canal` fixtures of single test files; `CONTRASENA` and `RAIZ_API` of conftest, `ZONA` of
  `test_reminder`; `--sin-emulador` (CLI option string, may be read by CI and docs).
