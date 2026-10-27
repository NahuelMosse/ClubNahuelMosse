# ENG-02 handoff

Done (committed): RED, renames (venues/users/session/password_recovery), explicit operation_id, openapi.json, docs, tests; `93331f8` adds the `*routes.py` per-file-ignores and the schema-name map in test_arquitectura_funcionalidades (11 passed). `flutter pub get` done; fmt and lint pass.

Gate (run with `UV_PROJECT_ENVIRONMENT` exported to the shared venv; log in `.eng02-verify.log`, untracked):
- passed: fmt, lint, specs, layers, migrations, boundaries, attacks (second line).
- failed: `attacks` first line (Auth emulator 127.0.0.1:9099 was not up); `suite` (`ModuleNotFoundError: psycopg` in the gate's python for the DB probe); `shape` (session/use_cases.py and users/rules.py mix classes and functions); `overdesign` (`UserRepository` in users/registration.py has one implementation); `required` (mutation of 12 renamed modules not run; Tasks of card.md do not list main.py, pyproject.toml and the espacios/horarios/reservas/notificaciones route/use-case import edits; K4 clones in reservas/rutas.py and four unit tests; I-line/I-motion look like false positives for a backend rename).
- Unit tests still red, same as on the ENG-01 base per the previous handoff (not re-verified: time cap hit): test_base_en_ingles, test_codigo_legible signatures, test_sin_supresiones x2, test_sin_sobreingenieria (DB port 8703 vs 8701).

Next: start the emulator, fix shape/overdesign, list the touched files in Tasks, run the mutations via once.mjs, close.
