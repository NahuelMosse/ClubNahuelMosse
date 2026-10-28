# Handoff ENG-15 (builder 3)

Env: UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv"; Postgres 127.0.0.1:8701; auth emulator :9099. flutter/dart: D:/projects/flutter/bin (PowerShell). Nothing pushed.

## Done
- main (424319d) fully ported: lib, the 3 new tests, and the edits to inicio_test, admin/pantalla_panel_admin_test, rediseno/movimiento_pantallas_test, integration_test/inicio/home_test. dart format + flutter analyze clean. Card: T3 + Log L32-L35 written.
- Known reds (also in main): esqueletos_de_carga_test x4 (timersPending), movimiento_pantallas @RED-04-S14.

## Left
1. Gate: the API now lives in this branch (ENG-14 merged) but ENG-15 `## Gate` only has the Flutter suite. Add API lines like ENG-14's card (`suite [timeout 2 h]: sh D:/Temp/w/herramientas/arq01-pytest.sh -q -p no:cacheprovider`, the lint line eng14-ruff-mypy-flutter-analyze.sh, mutate lines for notifications) if verify needs them; L2/L3 (fault-db/attacks "la card no toca la API") may need a new Log line. Extend the `fmt:` line to the new test files if needed.
2. `node .claude/tools/verify.mjs > /tmp/verify.log 2>&1` in background; `node .claude/tools/wait.mjs /tmp/verify.log --until 'verify: ' --max 570` (repeat). Then `node .claude/tools/close.mjs` until 9/9; commit closing.md.
3. Report raw final lines of verify and close.
