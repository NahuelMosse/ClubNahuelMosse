# ENG-01 handoff (4)

## Done (commit a20bb9a)
- All 13 base files written in English (shared/*, config.py with Settings + AliasChoices, main, health, e2e_support with Field aliases); second pass over app/modules by grunt; mapa-del-codigo.md and glosario-ingles.md updated; ruff isort + format applied to app/tests (test_basquet_3x3.py and test_suite_confiable.py restored from HEAD because the formatter broke their noqa lines); test_api_limpia_plan_funcionalidades.py now expects `http_errors.py`.
- `ruff check app` passes. tests/unit first 8 tests passed (stopped at the map test, now fixed).

## Left
1. Gate: `node .claude/tools/verify.mjs` was started in background (log /tmp/eng01_gate.log, ends with `exit N`). The first run failed only with "`app:` line could not start the app (exit null)" (verify waits 60 s; the script `sh D:/Temp/w/herramientas/arq01-app.sh eng01_app` does start when run by hand). Read the log lines for suite / fmt / lint / app / attacks and fix what is red. Do not run pytest bare: it needs `TEST_DATABASE_URL` for the club_test db that `arq01-pytest.sh` prepares (the hook only lets a builder run bounded tests; use `node .claude/tools/affected.mjs`).
2. Append L7.. lines (T1..T3 evidence) at the end of `## Log` of card.md with Edit.
3. Commit; no push.

## Env
UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"; Postgres 127.0.0.1:8701; Auth emulator 127.0.0.1:9099.
