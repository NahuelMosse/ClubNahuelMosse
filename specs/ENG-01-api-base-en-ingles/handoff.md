# ENG-01 handoff (5)

## Done (commit a20bb9a + b953213)
- 13 base files in English, module second pass, mapa-del-codigo.md and glosario-ingles.md updated, ruff isort/format applied, `ruff check app` passes.
- Gate ran (verify.mjs, 54.7 min, exit 1). Log: /tmp/eng01_gate.log (may be lost; re-run).

## Gate red (from /tmp/eng01_gate.log, tail only; read the head too for suite/fmt/app/attacks)
1. `lint` line (sim01-ruff-mypy-flutter-analyze.sh apps/api/app + the two new tests) reports "linter on <file>" failed for ~35 test files (tests/unit/*, tests/integracion/*) : run `node .claude/tools/once.mjs lint -- sh D:/Temp/w/herramientas/sim01-ruff-mypy-flutter-analyze.sh apps/api/app apps/api/tests/unit/test_base_en_ingles.py apps/api/tests/unit/test_config_en_ingles.py` and read the real ruff/mypy messages (likely E501 / import order / mypy attr names from the renames, or the formatter reformatting noise in tests: consider `git checkout ca749d0~... -- <test>` restoring formatting-only diffs).
2. `apps/api/app/modules/reservas/almacen.py` is not in `## Tasks` of card.md: add it to a task line (Edit) or undo its change.
3. K4 duplications (new): reservas/rutas.py:354-359 vs 162-167 (extract or Log `declared · K4 · ...`); tests duplicates are likely formatter-induced.
4. I-line "no design line" (design/line.md): card touches no screen; declare in Log or ask the coordinator (ENG-01 has no presentation).
5. ACT-03 of judge.md must be closed in the card: `… · closed · <ASM-NN, T<n> or Gate line>` (judge.md is written via Edit, never Python/shell).
6. Not seen: suite, fmt, app, attacks lines (the log head). The first gate run failed once with "app: could not start (exit null)".
7. Then Log lines L7.. for T1..T3 in card.md with Edit; commit; no push.

## Env
UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"; Postgres 127.0.0.1:8701; Auth emulator 127.0.0.1:9099. Run the gate in background to a log.
