# Handoff · REV-02 (API)

## Hecho (T1: S1, S2, S12)
- 9 tests de T1 en verde (`tests/escenarios/test_operacion.py`, ~162 s): base inalcanzable, consulta >10 s, pool, bloqueo, `/ready`, render.yaml, arranque sin base / sin esquema.
- Código: `app/infraestructura/db.py` (pool 5+5, timeouts, `base_disponible`, `esquema_al_dia`), `app/config.py` (`RAIZ_API`, `version` desde pyproject, `database_url_app`, `metricas_token`, env_file absoluto), `app/interfaz/salud.py` (`/health` con versión, `/ready`), `app/main.py` (lifespan que registra `arranque_sin_base`/`arranque_sin_esquema` y sigue, handlers 503 de SQLAlchemy con referencia, `version=config.version`, responses 500/503, router salud), `render.yaml` (`/ready`, `DATABASE_URL_APP`, `METRICAS_TOKEN`).
- Entorno: `.venv` y `club_rev02_test` creados. `TEST_DATABASE_URL=postgresql+psycopg://club:club@127.0.0.1:8703/club_rev02_test FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702`; correr con `apps/api/.venv/Scripts/python.exe -m pytest ...` en background con log y `wait.mjs <log> --until "^exit"`.

## Falta
- T2 (`registro_errores.py`, `metricas.py`): ContextVar con el id y `X-Request-ID` en toda respuesta (más externo: `RegistroDeErrores` último `add_middleware`), registro JSON con `referencia`/`version`, 500 con `{"mensaje","referencia"}` registrado una vez, `/metrics` con bearer (404 sin token) y series; incluir `metricas.router` en `main.py`. Los handlers 503 de `main.py` y `/ready` usan hoy `x-request-id` del pedido o un uuid4: pasarlos al id del contexto. No se registra en el handler (el middleware ya registra el 5xx una vez).
- T3: `barrido.py --una-vez`, aviso `aviso_sin_enviar`, `scripts/respaldo.py` (pg_dump no existe en esta máquina: test «could not run»), `scripts/usuario_de_la_app.py`, `apps/api/README.md` (variables DATABASE_URL_APP, METRICAS_TOKEN, VERSION, DETRAS_DE_PROXY, RPO/RTO, ASM).
- Ajenos: `test_requisitos_no_funcionales::test_toda_operacion...` falla por `/health` y `/ready` públicos (PUBLICAS es de REV-01 grupo 2); el del README es de T3.
- Gate completo sin correr.
