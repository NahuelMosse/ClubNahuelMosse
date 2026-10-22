# Handoff T1 (REV-08)

Entorno: TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev08_test (ya creada), FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702, PATH con /d/projects/flutter/bin. Python: apps/api/.venv/Scripts/python.exe -m pytest (uv run tarda). Corridas largas: en background con log en D:/Temp, esperar con `node .claude/tools/wait.mjs <log> --until ' in [0-9.]+s'` (sin `|` en el regex: cmd lo rompe).

Hecho (commits 1f5a738 RED, y el siguiente):
- tests/escenarios/test_suite_confiable.py (RED, committed): 10 pasan de inicio (S1 x2, S2, S3: declarar, el defecto era la falta de test), fallan S2-meta, S7-unitario-existe, S4-contrato. Los de S5 y S7-subprocess no se corrieron aún en RED (la inner run se colgaba por el advisory lock de `motor`).
- tests/conftest.py: `--sin-emulador`, `_host_emulador(config)` falla (o salta con la opción) con «hace falta el emulador de Firebase Auth» si falta la variable o el puerto no responde; `api` chequea el emulador ANTES de pedir `motor` (si no, el subproceso espera el lock de la base del padre).
- tests/integracion/test_restricciones.py: salieron los dos tests engañosos.

Falta:
1. tests/unit/test_casos_de_uso_reservas.py: unitarios sin base ni emulador de las 7 funciones públicas de app/aplicacion/reservas.py (mis_reservas, reservar, cancelar_reserva, modificar_reserva, historial_global, detalle_admin, anular_reserva) con repositorio en memoria (Protocol `Reservas`) y `ahora` fijo; cada una llamada como `nombre(`; bordes y errores de cada una (para matar mutantes: `node .claude/tools/mutate.mjs`, gate `mutate apps/api/app/aplicacion/reservas.py`).
2. Correr test_suite_confiable.py entero (S5 incluidos) y confirmar verde.
3. Frozen RNF-01 (test_requisitos_no_funcionales.py: H06-02 `>= 25`, H04-01 lee Dart con regex): no existe `refreeze.mjs`; intentar editar (cota a 28, H04-01 sin `_endpoints_que_usa_la_app`); el test S4 de la suite exige que `_endpoints_que_usa_la_app` no esté en el archivo. Si el guard lo impide: `replaces:` en el Log (nuevo archivo) y revisar el S4 test.
4. README apps/api/README.md: cómo correr sin emulador (`--sin-emulador`) y que sin él falla.
5. Gate completo (`node .claude/tools/verify.mjs`) en background; app-suite depende de T2-T3; tests de test_seguridad_api.py que fallen por REV-01 grupo 2 (apps/api/openapi.json, /health): «pending REV-01 group 2».
6. Log: una línea por tarea en card.md.
