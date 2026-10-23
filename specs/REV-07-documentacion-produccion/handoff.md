# Handoff REV-07

Hecho
- RED commiteado: `apps/api/tests/escenarios/test_documentacion_supuestos.py` (19 tests ASM-01..17; test_documentacion.py está congelado, por eso van en archivo nuevo). Commit 926d225.
- Documentos completados (sin commitear): headings `#### \`tabla\`` en system-design.md, frase de claves foráneas, "kit-3" en runbook.md e infra-cost.md, filas ASVS "Sin card" -> "No figura en la revisión: sin card", V15.2.2 con "hallazgo N" repetido, apps/api/README.md sin cadena de conexión con contraseña.
- Última corrida de los dos archivos de tests de documentación (antes de los últimos 3 edits): 3 fallaban, los 3 arreglados por esos edits; hay que re-correr.

Falta
1. Re-correr: `cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_documentacion.py tests/escenarios/test_documentacion_supuestos.py` (tarda ~2 min, en background con log). Si otra fila ASVS `fails` dice "hallazgos N" en plural, pasar a "hallazgo N".
2. Commitear los documentos.
3. Gate: `export TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev07_test FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8701; node .claude/tools/verify.mjs > log` en background y `node .claude/tools/wait.mjs <log> --max 570`.
   La línea `app:` falló: "did not answer on port ... within 60 s", log vacío. La base y alembic funcionan (alembic upgrade head: 5 s). `sh D:/Temp/w/herramientas/api-app.sh rev07_app` con PORT=55111 no imprime nada en 50 s; falta ver si uvicorn arranca (probar `uvicorn app.main:app` a mano con DATABASE_URL=...club_rev07_app, a un log, y `wait.mjs --until`). Si el script falla, reportar el error exacto sin reescribir el Gate.
4. Log en card.md: una línea por T1..T4, y la deriva: el test ASM-02 acepta IDs `SUP|ASM` porque los supuestos registrados de los CU son `SUP` (L5 decía exigir ASM-NN).
5. Los `attacks:` y `app:` no corrieron aún.
