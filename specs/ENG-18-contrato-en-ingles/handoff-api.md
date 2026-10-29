# Handoff ENG-18 (builder T1/T2/T5, API side), third round

## Done (committed)
- Production in apps/api/app, docs, tests/integracion and tests/escenarios translated (previous rounds).
- tests/unit: all green except the five mobile-path/docs tests that the gate already deselects (documentacion_del_modelo x2, integraciones_documentadas, readme_conciso, rutas_documentadas). Last run: 5 failed (those), 379 passed.
- Contract-vs-main unit tests now go through `tests/contract_renames.py::comparable` (`PERSON_SCHEMAS` includes main's Spanish schema names) and `operaciones_distintas_en(*prefixes)` of test_api_en_ingles_contrato_actual.py; the snapshots `contrato_reservas_main.json` and `contrato_cuenta_main.json` are deleted.
- Replacement tests written and logged (L9..L14): test_contract_in_english_fixed.py (409, operationId via `create_app()` and `original_router`, /_testing with http_errors), test_english_contract_over_english_schema.py (ENG-17-ASM-01 tests); the two old over_english_schema files are deleted.
- ruff (`eng17-ruff-mypy.sh` ruff part) passes on tests/integracion; mypy part not rerun after the last edits.

## Not covered
1. The full `suite` line: started in background (`.validation/api-suite.log`, command in `.validation/suite-cmd.sh`, ~50-90 min). Failures seen early (F in the first escenarios files); read `-rf` at the end.
2. `sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh` rerun (mypy --strict app + two tests).
3. Log lines for T1, T2, T5 (include the glossary additions: «Claves de error y de cuerpo», «Soporte de pruebas (`/_testing`)», `recordatorio_cinco`).
