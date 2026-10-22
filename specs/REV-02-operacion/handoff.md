# Handoff · REV-02 (API)

## Hecho (T1: S1, S2, S12)
- 9 tests de T1 en verde (`tests/escenarios/test_operacion.py`, ~162 s): base inalcanzable, consulta >10 s, pool, bloqueo, `/ready`, render.yaml, arranque sin base / sin esquema.
- Código: `app/infraestructura/db.py` (pool 5+5, timeouts, `base_disponible`, `esquema_al_dia`), `app/config.py` (`RAIZ_API`, `version` desde pyproject, `database_url_app`, `metricas_token`, env_file absoluto), `app/interfaz/salud.py` (`/health` con versión, `/ready`), `app/main.py` (lifespan que registra `arranque_sin_base`/`arranque_sin_esquema` y sigue, handlers 503 de SQLAlchemy con referencia, `version=config.version`, responses 500/503, router salud), `render.yaml` (`/ready`, `DATABASE_URL_APP`, `METRICAS_TOKEN`).
- Entorno: `.venv` y `club_rev02_test` creados. `TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev02_test FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702`; correr con `apps/api/.venv/Scripts/python.exe -m pytest ...` en background con log y `wait.mjs <log> --until "^exit"`.

## Hecho (T2: S7, S9, S10, S13, S14, S15)
- 19 tests en verde. `app/interfaz/registro_errores.py` (ContextVar, `referencia_actual()`, JSON por línea, 500 con referencia, métricas por pedido), `app/interfaz/metricas.py` (`/metrics` con bearer, 404 sin token), `main.py` (router, handlers 503 solo OperationalError/InterfaceError/Timeout), `salud.py`.

## Falta
- T3: `barrido.py --una-vez`, aviso `aviso_sin_enviar`, `scripts/respaldo.py` (pg_dump no existe en esta máquina: test «could not run»), `scripts/usuario_de_la_app.py`, `apps/api/README.md` (variables DATABASE_URL_APP, METRICAS_TOKEN, VERSION, DETRAS_DE_PROXY, RPO/RTO, ASM).
- Ajenos: `test_requisitos_no_funcionales::test_toda_operacion...` falla por `/health` y `/ready` públicos (PUBLICAS es de REV-01 grupo 2); el del README es de T3.
- Gate completo sin correr.
