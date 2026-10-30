# ENG-20 handoff

## Done (committed on ENG-20-textos-api-en-ingles)
- RED: `apps/api/tests/escenarios/test_english_texts.py` (all S1..S7 / ASM tags). The scan exempts the CLI interface names (`correo`, `--promover`, `ADMIN_CONTRASENA`, `--una-vez`, `clubnahuelmosse.correo`).
- Production: every Spanish literal in `apps/api/app/**` translated (errors, email, push, catalog names, OpenAPI summaries/descriptions, seed CLI output). The AST scan (`test_no_string_literal_of_the_api_code_is_spanish`) was clean. Keys, routes, options and env vars unchanged. `apps/api/openapi.json` regenerated.
- Lint: `sh D:/Temp/w/herramientas/eng17-ruff-mypy.sh` passed (ruff + mypy strict) after the production edits. Re-run it after the latest test edits.
- T4 (tests): bulk-translated expected texts in `apps/api/tests/**` (unit suite: 15 failures left, most pre-existing: missing `apps/mobile/...` files, readme captures, `test_sin_supresiones` / `test_capas_funcionalidades` which read `test_english_texts.py`).

## Left (not covered, could not run)
- `tests/escenarios` and `tests/integracion` runs were in flight: logs `.validation/esc.log`, `.validation/int.log` (read with `Grep "^FAILED"`). Fix each remaining Spanish expected text in those tests (old texts to new: see the app diff). Tests that still hold weekday/month names, `Hola`, `Sede` prefixes in expected values.
- Check `tests/unit/test_sin_supresiones.py::test_no_queda_una_supresion_de_tipos` after the `cast` change in `test_english_texts.py`; also `# fmt: skip` in that file may trip a "no suppressions" test: replace with a multi-line set if so.
- Full gate `node .claude/tools/verify.mjs` (suite, lint, app, attacks) not run; Log lines (`node .claude/tools/log.mjs specs/ENG-20-textos-api-en-ingles "T<n> · ..."`) not written; `app` / `attacks` lines not run.
- Temporary helper scripts are outside the repo in `D:/Temp/w/eng20_*.py`.
