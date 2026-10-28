# Handoff ENG-14 (cuarta tanda)

Hecho
- Gate: `publish:` fuera; `lint:` usa `D:/Temp/w/herramientas/eng14-ruff-mypy-flutter-analyze.sh` con los archivos tocados (ruff, mypy estricto, flutter analyze: pasan; `flutter pub get --offline` ya corrido en apps/mobile); tres líneas `mutate ...: sh D:/Temp/w/herramientas/eng14-notif-tests.sh`.
- Tests nuevos: apps/api/tests/unit/test_notificaciones_reglas_bordes.py y test_notificaciones_casos_de_uso_bordes.py. Mutación: rules 18/19, use_cases 17/18, equivalentes en equivalents.md; store.py es un Protocol (exit 3, aceptado).
- `node .claude/tools/required.mjs`: sólo falta K4 (2 pares). Log L20-L27 escrito.
- verify (10.6 min): suite sólo falla los 2 de L11; attacks, lint, mutate, specs, layers, shape, overdesign, migrations, boundaries pasan; `required` falla sólo por K4.

Pendiente
1. K4: los Log `declared · K4 · <file> · ...` (L22-L27) no los reconoce required.mjs. Ver en `.claude/tools/required.mjs` / `verify.mjs` (Grep `K4`, `declared`) qué formato exacto espera (¿ruta con `:líneas`? ¿un solo archivo con ambos?) y ajustar la línea del Log (append) o, si no, extraer el bloque duplicado a un módulo común importado por ambos tests (son tests de main; preferible declarar).
2. Rerun `node .claude/tools/verify.mjs` (fondo, log, `node .claude/tools/wait.mjs <log> --until 'vdone' --max 570`), luego `node .claude/tools/close.mjs` y commit de closing.md. Nunca push ni PR.
Env: UV_PROJECT_ENVIRONMENT="D:/desktop folders/estudio/Universidad de moron/Electiva general/app-tp/apps/api/.venv".
