# Handoff ENG-18 (builder T1/T2/T5, API side)

## Done (production, apps/api/app, committed as WIP)
- Deleted shared/stored_values.py; English keys in shared/*, health, availability, bookings, notifications, session, users, venues, spaces, password_recovery (routes + use_cases link `/link/recover#code=`), e2e_support.py (`/_testing/...`, ASM-09), config.py comment.
- Routes, fields, query names and error keys follow docs/technical/glosario-ingles.md plus the names listed below.

## Left
1. `apps/api/app/modules/notifications/use_cases.py:158` still has the key `plataforma` (unit scan `tests/unit/test_error_keys_in_english.py` fails on it): rename to `platform`.
2. `test_every_operation_id_is_fastapis_default_over_the_english_handler` fails: published operationIds still exist but the test's `routes` set is empty. Check the test fixture `api` (it reads `api.app.routes`; the routes may live under a mounted sub-app or the fixture errors). 10 errors in the run come from fixtures: `tests/conftest.py` and `tests/integracion/conftest.py` still use the Spanish contract (T2).
3. main.py router mounts are unchanged and correct (no prefix change needed).
4. Regenerate apps/api/openapi.json from the app and commit it.
5. T2: update tests/** (conftest fixtures `/register`, `/venues`, English bodies; integration, scenario, unit tests; frozen snapshot JSONs via `tests/contract_renames.py::comparable`). Replace the ENG-17-ASM-01 test in `tests/integracion/test_contract_values_over_english_schema.py` by a new file with the same title/tag plus the Log line (`replaces: ...`).
6. T5: docs (apps/api/README.md, docs/technical/*.md, docs/guia-basica.md) and glossary additions.
7. Full gate: suite (`sh D:/Temp/w/herramientas/arq01-pytest.sh ...` with the card's deselect list) then `sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh`, in the background with wait.mjs.
8. One Log line per task via log.mjs (T1, T2, T5), including the glossary additions.

## Names not in the glossary (add to «Campos JSON» / «Rutas» and to the Log, ASM-01 R3)
`fechas`->`dates`, `hasta` (error key)->`until`, `cuerpo`->`body`, `horario`->`slot`, `reserva`->`booking` (error key), `hora`->`hour`, e2e: `/_testing/{emails?to=, bookings[/clear,/start,/void], venues/deactivate, spaces/deactivate, password-recovery/{code}/expire, reminders, devices?email=}`, body keys `space,date,hour,hours,email,status,reason,name,now,registered,subject,body,emails,devices,permission_granted`.

## Note for the mobile builder
Error-key vocabulary `start_hour` / `until` / `date` / `hours` is shared by body and query. Recovery link: `/link/recover#code=`; the opened intent keeps `intent://app/recuperar?codigo=`.

## Not covered (turn budget)
Items 1 to 8 above: could not run.
