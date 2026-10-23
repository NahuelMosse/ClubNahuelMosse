# Handoff REV-01 · T3 y T4 (builder 2)

Worktree D:/Temp/w/rev01. Entorno: ver el mensaje del coordinador (TEST_DATABASE_URL, FIREBASE_AUTH_EMULATOR_HOST, PATH de flutter).

## Hecho
- RED commiteado: `apps/api/tests/escenarios/test_seguridad_entradas_extra.py` (12 tests con los títulos de la card; `test_seguridad_entradas.py` está congelado porque ya tiene el test de /health en un commit, por eso los nuevos van en un archivo aparte con las mismas etiquetas). No corridos todavía: confirmar que fallan por la razón correcta.
- Leído, sin tocar: correo.py, identidad.py, notificaciones.py (infra), main.py, protecciones.py, limites.py, entradas.py, registro_errores.py, config.py, render.yaml, conftest.py.

## Falta (código)
1. `infraestructura/correo.py`: `smtp.starttls(context=ssl.create_default_context())`; en `enviar`, no loguear la excepción con la dirección: `correo_log.error("no se pudo enviar el correo «%s»: %s", asunto, type(e).__name__)` sin `exc_info` (el traceback de SMTPRecipientsRefused y del SSLCertVerificationError lleva la dirección); el test exige `caplog.records` no vacío.
2. `infraestructura/identidad.py` + `main.py`/`config.py`: con `FIREBASE_AUTH_EMULATOR_HOST` en el entorno, `crear_app()` lanza `RuntimeError("... emulador ...")` si `config.firebase_credenciales_json` o `GOOGLE_APPLICATION_CREDENTIALS` están definidas, o si `config.firebase_project_id` no empieza con `demo-` (ASM-10). Poner la comprobación como función pura en `config.py` (rule) o en identidad.py y llamarla al inicio de `crear_app()`.
3. `infraestructura/notificaciones.py` `registrar_dispositivo`: el `ON CONFLICT (token) WHERE activo DO UPDATE` debe llevar `WHERE dispositivo.usuario_id = EXCLUDED.usuario_id` (un token activo ajeno no cambia de dueño; la baja ya filtra por usuario). La ruta responde 204 igual.
4. `render.yaml`: agregar `DOCUMENTACION_INTERACTIVA` value "false" y `DETRAS_DE_PROXY` value "true"; `healthCheckPath: /health`.
5. `apps/api/uv.lock`: certifi >= 2026.10.18 (`cd apps/api && uv lock --upgrade-package certifi`; si no hay red, declararlo en `could not run`).
6. `apps/api/openapi.json`: generarlo con `crear_app().openapi()` (json, utf-8, indent 2, `ensure_ascii=False`, salto final); el test compara el dict. Documentar el comando en `apps/api/README.md` junto a los supuestos de operación (límites, documentación, /health, Host, proxy, emulador). Considerar un script/flag en el README, p. ej. `uv run --no-sync python -c "..."`.
7. Contrato: el test `test_el_contrato_documenta_el_429_el_400_por_host_y_el_422` pide 400 en todas las operaciones salvo /health, 422+429 en POST /registro y /recuperacion, 429 en PUT /yo. Hoy 429 de /registro y /recuperacion ya está; falta el 400 global (agregar `responses={400: {...}}` a `FastAPI(...)` no existe: usar `app.openapi` personalizado o `responses=` en cada router `include_router(..., responses={400: {"description": "Host no permitido"}})`), y revisar el 422 (`Errores` en `ErroresDeCampo`).
8. Regenerar `openapi.json` DESPUÉS de cualquier cambio de contrato.

## Falta (app)
- `apps/mobile/test/limite_de_frecuencia_test.dart` con título `la app muestra el 429 con el mensaje del servidor en su diálogo de error @REV-01-S6 @assumption:REV-01-ASM-14`. Modelo: `errores_compartidos_test.dart` (MockClient devolviendo 429 con `{"mensaje": "Hiciste demasiados intentos. Esperá un minuto y volvé a probar."}`, `ClienteApi` en `apps/mobile/lib/api/cliente_api.dart`, líneas 85-105 convierten respuestas; `comun/dialogo_error.dart` tiene `mostrarErrorDeRed`). Commit RED, luego ajustar `cliente_api.dart`/pantalla de registro o recuperación solo si el 429 no llega al diálogo con el mensaje del servidor (sin pantalla nueva). Correr con `flutter test test/limite_de_frecuencia_test.dart` desde apps/mobile.

## Gate (no corrido)
`node .claude/tools/verify.mjs` en background con `VERIFY_TIMEOUT_MIN=45`; `attacks:` ahora debe bloquear el Host ajeno. Líneas lint: ruff check, `ruff format --check app tests/escenarios/test_seguridad_api.py`, `mypy --strict app`.

## Log
Todavía no se agregó ninguna línea de T3/T4 al `## Log` de card.md. Agregar una por tarea con la evidencia, y una `OUT` si corresponde. Anotar también que los tests nuevos están en `test_seguridad_entradas_extra.py` porque `test_seguridad_entradas.py` quedó congelado.
