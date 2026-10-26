# Handoff SIM-01 (API)

## Hecho
- RED (9faf496), T1-T4 en código (930724f, 56c2b97) y, en el commit siguiente: `tests/unit/test_entradas.py` y `test_casos_de_uso_reservas.py` adaptados, `tests/escenarios/test_datos_tandas_y_cola.py` reescrito (sin tandas ni marcador), `apps/api/openapi.json` regenerado, `.env.example` ya limpio. Log L10-L14 de card.md escrito.
- La suite colecta de nuevo.

## Falta (T1/T3/T4 no cerrados: suite roja por tests de lo retirado)
- La suite se CUELGA en `tests/escenarios/test_operacion.py` (tests de 503 por pool/bloqueo/timeout, `/ready`, `/metrics`, `POOL_MAXIMO`, healthCheckPath `/ready`, OpenAPI con 503). Reescribir por L2: archivo nuevo con el mismo nombre (git rm del viejo, Write) conservando sólo lo que sigue vigente (500 sin filtrar, logs, etc.) y registrar en el Log.
- Mismo tratamiento (quitar sólo lo retirado) en: `tests/unit/test_api_limpia.py` (test de métricas, l.94+), `test_api_limpia_plan.py` (métricas), `test_capas_integracion.py` (salud.py/metricas.py/registro_errores.py), `tests/integracion/test_rutas_protegidas.py` y `_con_operacion.py` (`/ready`, `/metrics`), `tests/escenarios/test_contrato_publicado_con_operacion.py` (`/ready`, `/metrics`), `test_seguridad_api.py` (caso `Clave\x00Nueva1`, ahora sin tope de control: quitarlo), `test_seguridad_entradas_extra.py`, `test_operacion_rutas_publicas.py`.
- Fallas en la primera pasada que hay que clasificar: `test_datos.py` (13), `test_datos_plan_reemplazo/reemplazos/tanda_justa/tanda_justa_propia`, `test_contrato_publicado.py`, `test_documentacion*.py`. Algunas usan `despues`/`siguiente` (quitar por L2); otras son previas (ARQ-02 L23/L24: hora, README, pg_dump). Correr con `-v` y `--maxfail` alto; usar `-k "not test_operacion"` hasta reescribirlo, porque cuelga.
- README de la API aún menciona `/metrics`, `/ready`, `DATABASE_URL_APP`, `METRICAS_TOKEN`, `DETRAS_DE_PROXY`, `DOCUMENTACION_INTERACTIVA` (T6).
- Lint `sh D:/Temp/w/herramientas/sim01-lint.sh`: no corrido.
- T5 (migración 0009, avisos sin reintentos), T6 (scripts y docs), T7/T8 (app) sin hacer. No tocar `apps/mobile`.

## Comandos
- `sh D:/Temp/w/herramientas/arq01-pytest.sh -v -p no:cacheprovider -k "not test_operacion" > /tmp/sim01-api.log 2>&1` en background; esperar con `node .claude/tools/wait.mjs /tmp/sim01-api.log --until ' in [0-9.]+s' --max 560`.
- Tests propios: `tests/unit/test_sin_sobreingenieria.py tests/integracion/test_sin_sobreingenieria_api.py`.
