# Handoff REV-03 (builder 3)

Entorno igual que antes: TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev03_test, FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702, PATH con /d/projects/flutter/bin, VERIFY_TIMEOUT_MIN=45. Python 3.13 en apps/api/.venv.

## Hecho
- `apps/api/tests/escenarios/test_datos_reemplazos.py`: los 4 reemplazos pasan (4 passed). Log L15 a L18 con `replaces:`.
- `pyproject.toml`: F811 ignorado en `tests/escenarios/test_datos_*.py` (imports de fixtures); ruff check pasa.
- `tests/conftest.py`: `--card` acepta `@<ID>-S<n>` además de `-H` (antes `scenarios` deseleccionaba los 121 tests).
- `tests/integracion/test_historial_api.py`: test de próximas (@REV-03-S2) para matar el mutante `hay_mas=False` de reservas.py:156.
- Commits: 529b722, 788f1a8.

## Gate (corrida 4, log /tmp/rev03-gate4.log; la 2 y la 3 cayeron por `app:` que no arrancó en 60 s por carga; a mano sí arranca)
Fallos de la corrida 1 que NO son de esta card o del entorno: `suite` con 256 errors de setup (corrió a la vez que el mutate sobre la misma base), `attacks` (foreign Host 25-S2, de REV-01), K4/linter de `required` sobre archivos congelados o previos.
Falta: leer /tmp/rev03-gate4.log al terminar (`FIN`), arreglar lo propio, agregar al Log una línea por T1..T4 con evidencia (T1 migrate-upgrade passed; T2/T3 test_datos + reemplazos; T4 app-suite passed). No pushear.
