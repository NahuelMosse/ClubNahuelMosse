# Handoff ENG-18 (builder T1/T2/T5, API side), fourth round

## Done (committed)
- Production in apps/api/app, docs, tests/integracion and tests/escenarios translated; `use_cases.py` of notifications types `outcome: Delivery`.
- tests/unit: 379 passed, 5 failed (the mobile-path/docs ones the Gate deselects).
- Contract-vs-main unit tests go through `tests/contract_renames.py::comparable` and `operaciones_distintas_en`; snapshots of main deleted.
- Replacement tests and Log lines L9..L14; Log lines for T1, T2, T5 written (L15..L17).
- `sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh`: passed (ruff x3, mypy --strict app: no issues in 74 files).
- Full `suite` line (run once, `.validation/api-suite.log`, 84 min): **27 failed, 757 passed, 2 skipped, 13 deselected**.

## Not covered (turn budget): all *could not run*
1. Read the 27 failures: `Grep "^FAILED " .validation/api-suite.log` (and `-B` for their `E ` lines). Early failures were in tests/escenarios; the handoff of round two listed test_recuperacion_api, test_perfil_api, test_espacios_api, test_requisitos_no_funcionales, test_cancelacion_forzosa, historial, reservas, anular_reserva, render_rehearsal, contrato_publicado, confirmacion_cancelacion, english_schema, migrations_folder, suite_confiable. Rerun them by file (`sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider <file> --tb=short -rf`, in the background: each takes minutes) and fix; the command line of the suite is in `.validation/suite-cmd.sh`.
2. After the fixes, rerun the `suite` line once and add its result to the Log (`node .claude/tools/log.mjs`); update the T2 line, which says the suite did not finish.
3. Delete this file when nothing is left.
