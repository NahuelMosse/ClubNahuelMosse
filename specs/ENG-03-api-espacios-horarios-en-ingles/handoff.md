# Handoff ENG-03 (builder 2, stopped at the context cap)

## Done (commits 88f013e RED, 9a90356 code)
- card.md has ASM-05..10; test `apps/api/tests/unit/test_modulos_espacios_en_ingles.py` (3 tests) passes.
- `spaces/` and `availability/` migrated (11 files), 8 routes with explicit operation_id, openapi.json regenerated, glossary/docs updated,
  other modules and tests adapted (names/paths only). Pydantic fields and query/path params stay Spanish through aliases.
- Gate log: /tmp/eng03-gate.log (full verify took 54 min; the suite alone ~50 min: run it in background, wait.mjs).
  Verify needs the app to start: a first run died with `uuid_v7 already exists` (two concurrent alembic runs); a rerun was fine.

## Gate lines still red (from the last verify)
- fmt: lists files "not counted" (apps/api/README.md, main.py, availability/*, ...): the `fmt:` line in card.md only checks `app tests/unit/test_modulos...`; run
  `cd apps/api && uv run --no-sync ruff format app tests` and check what `fmt` line reports.
- lint: "Found 1 error" (run the lint line, see the error). `required` also wants a linter pass on each touched test file
  (test_modelo, test_repositorios_propios, test_api_limpia_reservas, test_api_limpia_plan_funcionalidades, test_arquitectura_funcionalidades,
  test_capas_funcionalidades, test_casos_de_uso_reservas, test_espacios, test_horarios, test_nombre_compuesto, test_sin_sobreingenieria):
  add them to the card's `lint:` line (Edit, card Gate section) so they are linted.
- suite: errors in tests/integracion/test_uuid_api.py (ERROR in setup, likely DB env, check it is not rename related; run alone) and the 4 unrelated
  failures seen before (`# type: ignore` in test_config_en_ingles.py; DB connection on 8703 in test_base_en_ingles contract test and
  test_sin_sobreingenieria metrics test; test_codigo_legible signatures of crear_app/cambiar_contrasena/uid_del_token). Check whether they fail the same on main; if so declare them in the Log.
- layers: `reservas/repositorio.py:78` and `sedes/repositorio.py:72` "SQL outside a data file" (probably pre-existing, they are not ours: compare with main).
- shape: `availability/rules.py` has a class and 9 top-level functions in one file (+ 3 more findings, read the line): split the class (OpeningHours/Slot/SlotGrid
  dataclasses) from the functions (e.g. a `models.py`/`slots.py`) or same as the original horarios layout; add the file to the card Tasks.
- required: (a) card.md Tasks must list main.py, notificaciones/reglas.py, reservas/{almacen,casos_de_uso,repositorio}.py, sedes/{reglas,repositorio}.py
  (add them to T1 with their reason: "import and renamed symbol lines", Edit with a single-line anchor, CRLF); (b) mutation of availability/{rules,slots,use_cases}.py and
  spaces/{rules,use_cases}.py: `node .claude/tools/once.mjs mutate -- node .claude/tools/mutate.mjs <file> --since 722d3cd4...` in background (see the full
  command in the log lines 80-84); (c) judge.md: risk.json says review high -> main thread must launch the judge in plan mode (not mine).
- attacks: first line said "could not run ... did not respond" but the later `attacks: passed`; recheck.

## Left
Log line `- L4 · 2026-10-27 · T1 · <evidence>` in card.md (Edit append after L3). Rename-caused things are done; remaining is gate hygiene above.
Never write card.md with shell. Venv: UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv".
