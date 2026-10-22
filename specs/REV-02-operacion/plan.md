# Plan — REV-02 · operación

## Time plan

1. Size and risk: unos 24 archivos (API: configuración, base, salud, registro y correlación, métricas, arranque, barrido; scripts de respaldo y de usuario de base; render.yaml; app: cliente, diálogo de error, captura de errores, sesión y cuatro `catch` mudos) · riesgo: operación en producción, datos personales en logs, decisión de gasto pendiente
2. without method: 180–300–480 min · goal: 1500 min · cap: 20 h
3. Critical path: rebase sobre `card/REV-01` cerrada → tests en rojo → plan → implementer por grupos (base y salud; registro, correlación y métricas; arranque, versión y configuración; barrido, respaldo y usuario; app) → verify → juicio · on the side from the start: `uv sync` y `flutter pub get`
4. Split: plan 60 · code 480 · verification 480 · correction 300 min
5. Cut if it does not fit: el histograma por ruta de `/metrics` (quedan contadores); nunca un chequeo de la vara

## Verification

```
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync mypy --strict app
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_operacion.py
mutate apps/api/app/infraestructura/db.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_operacion.py -k "base or disponibilidad"
mutate apps/api/app/interfaz/registro_errores.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_operacion.py tests/escenarios/test_registro_de_errores.py tests/escenarios/test_seguridad_api.py -k "registro or referencia or correlacion or log"
mutate apps/api/app/interfaz/metricas.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_operacion.py -k metricas
mutate apps/api/app/interfaz/salud.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_operacion.py -k "disponibilidad or version"
mutate apps/api/app/main.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_operacion.py tests/escenarios/test_seguridad_api.py
mutate apps/api/app/config.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_operacion.py -k "configuracion or version"
mutate apps/api/app/interfaz/barrido.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_operacion.py -k recordatorios
app: cd apps/api && uv run --no-sync uvicorn app.main:app --host 127.0.0.1 --port $PORT
```

Dart sin mutador: «no se pudo correr» para los archivos de la app. Los scripts de `scripts/` no son producción para el kit; se prueban con H04-01 y H08-01.

## File map

Grupo 1 · base y salud
- apps/api/app/infraestructura/db.py — engine con `pool_pre_ping`, `pool_timeout=5`, `connect_args={"connect_timeout": 5, "options": "-c statement_timeout=10000 -c lock_timeout=5000"}`; `base_disponible()` con un `SELECT 1` acotado · rule · test: apps/api/tests/escenarios/test_operacion.py
- apps/api/app/interfaz/salud.py — `GET /health` suma `version`; nuevo `GET /ready`: 200 si la base responde y el esquema está en la cabeza de las migraciones, 503 si no
- apps/api/app/main.py — un `OperationalError` o un tiempo agotado de la base responde 503 con `{"mensaje", "referencia"}`; el arranque falla con «no hay base» o «la base no tiene el esquema» si faltan; la versión sale de la configuración
- render.yaml — `healthCheckPath: /ready`; `DATABASE_URL_APP` (`sync: false`) para la app; el build migra con `DATABASE_URL`

Grupo 2 · registro, correlación y métricas
- apps/api/app/interfaz/registro_errores.py — id de correlación por pedido (de `X-Request-ID` si viene válido, si no un uuid4) en un `ContextVar`, en la cabecera de la respuesta y en cada línea de log con un filtro; registro en JSON por línea (`nivel`, `evento`, `mensaje`, `referencia`, `version`); un error no manejado se registra una sola vez, con referencia y versión, y la respuesta es `{"mensaje": "Ocurrió un error. Si le escribís a soporte, pasale esta referencia.", "referencia": <id>}` sin traza
- apps/api/app/interfaz/metricas.py — nuevo: `GET /metrics` en formato Prometheus (`solicitudes_total{metodo,ruta,codigo}`, `solicitud_segundos_bucket{ruta}`, `pool_conexiones_en_uso`, `pool_conexiones_libres`), con `Authorization: Bearer <METRICAS_TOKEN>`; sin token configurado responde 404
- apps/api/app/config.py — `version` desde `importlib.metadata` (el `pyproject.toml` es la única fuente), `env_file` absoluto (`apps/api/.env`), `metricas_token`, `database_url_app` opcional

Grupo 3 · barrido, avisos, respaldo y usuario de base
- apps/api/app/interfaz/barrido.py — `python -m app.interfaz.barrido --una-vez` hace una pasada y sale; el proceso web sigue barriendo como hoy
- apps/api/app/aplicacion/notificaciones.py — un aviso que queda `fallida` se registra como `aviso_sin_enviar` (error, con id, tipo y referencia, sin datos personales)
- scripts/respaldo.py — nuevo: `guardar` (`pg_dump -Fc`) y `restaurar` (`pg_restore --no-owner --clean --if-exists`) contra una URL
- scripts/usuario_de_la_app.py — nuevo: crea o actualiza el rol `club_app` con `SELECT, INSERT, UPDATE, DELETE` en las tablas y secuencias, sin `CREATE`, y `ALTER DEFAULT PRIVILEGES` para las tablas que agreguen las migraciones
- apps/api/README.md — respaldo, usuario de la app, barrido por comando, métricas, `/ready` y los ASM de esta card

Grupo 4 · app
- apps/mobile/lib/api/cliente_api.dart — espera hasta 60 s; un tiempo agotado es `ServidorSinRespuesta` (distinto de `SinConexion`, que queda para la falta de red); un 5xx guarda la `referencia`
- apps/mobile/lib/comun/dialogo_error.dart — el error del servidor muestra «Referencia: <id>»; `ServidorSinRespuesta` dice «El servidor no responde. Probá de nuevo en unos minutos.»
- apps/mobile/lib/comun/errores_no_manejados.dart — nuevo: `instalarCapturaDeErrores(registrar)` con `FlutterError.onError` y `PlatformDispatcher.instance.onError`
- apps/mobile/lib/main.dart — instala la captura y corre la app en `runZonedGuarded`
- apps/mobile/lib/sesion/sesion.dart — retomar la sesión espera como el cliente; un tiempo agotado no manda al ingreso
- apps/mobile/lib/admin/pantalla_detalle_reserva.dart, apps/mobile/lib/notificaciones/centro.dart, apps/mobile/lib/admin/pantalla_editar_espacio.dart, apps/mobile/lib/inicio/pantalla_inicio.dart — los `catch` mudos y el `.ignore()` registran el error con la captura de la app

Tests
- apps/api/tests/escenarios/test_operacion.py, apps/mobile/test/operacion_app_test.dart — los escenarios REV-02 (rojo, del hilo principal)

- System design: unchanged here — REV-07 escribe system-design.md; esta card lista en el cierre lo que cambia (timeouts, `/ready`, métricas, correlación, usuario de base) para la integración
- ADR: unchanged — sin componente nuevo de infraestructura (el cron y el plan pago los decide una persona)

## Assumptions

- REV-02-ASM-01 · mientras no se decida el plan pago (REV-02-AMB-01), la base se respalda con `scripts/respaldo.py` antes de que venza, y la vuelta atrás se prueba restaurando en otra base · any-answer: no — con el plan pago, los backups son de Render y el script queda para llevar datos a otra base
- REV-02-ASM-02 · el barrido corre también como comando de una pasada; quién lo dispara con la API dormida (tarea de Render, servicio pago) lo decide una persona; `render.yaml` no suma una tarea paga · any-answer: no — si se paga, se agrega el bloque del cron
- REV-02-ASM-03 · la base espera 5 s para conectar y para un lugar en el pool, 10 s por consulta y 5 s por un bloqueo; si no responde, 503 con mensaje y referencia; Render chequea `/ready` · any-answer: yes
- REV-02-ASM-04 · la app entra con `club_app`, que sólo lee y escribe filas; las migraciones siguen con el dueño de la base; si Render no deja crear el rol, `DATABASE_URL_APP` queda sin definir y la app usa `DATABASE_URL` como hoy · any-answer: yes
- REV-02-ASM-05 · la referencia del error es el id de correlación del pedido · any-answer: yes
- REV-02-ASM-06 · la app espera hasta 60 s; si no hay respuesta dice «El servidor no responde. Probá de nuevo en unos minutos.»; sin red sigue diciendo «Revisá tu conexión a internet» · any-answer: yes
- REV-02-ASM-07 · el id de correlación llega en `X-Request-ID` (hasta 64 caracteres, letras, números y guiones) o se genera; las llamadas a Firebase y al SMTP no lo llevan porque sus clientes no lo permiten · any-answer: no — deja sin efecto «llega a las llamadas externas» para Firebase y el SMTP
- REV-02-ASM-08 · las métricas se exponen en `/metrics` para quien tenga `METRICAS_TOKEN`; no se agrega OpenTelemetry porque el club no tiene dónde mandar las trazas · any-answer: no — si se contrata un servicio de trazas, se agrega el exportador
- REV-02-ASM-09 · la versión vive en `pyproject.toml`; los tags de versión se crean al publicar, que en este repo hace una persona · any-answer: yes
- REV-02-ASM-10 · el registro sale en JSON por línea, con nivel, evento, referencia y versión · any-answer: yes

## Perimeter

Postgres compartido (`club_rev02_test` y `club_rev02_restaurada_test`), emulador de Auth en `127.0.0.1:9099`, uvicorn levantado por los tests con un intermediario TCP que corta la base. `pg_dump` y `pg_restore` del PATH. El plan pago de Render queda para una persona (REV-02-AMB-01). Fuera, como `REV-02-OUT-NN`: la prueba de carga (O22) y un entorno de staging con artefacto promovido (O24), que el hallazgo 26 nombra sin escenario.

## Bar

- R1 · los escenarios levantan la API como en Render y le cortan la base de verdad
- R2–R5 · diez preguntas, AMB-01 a AMB-05 (AMB-01 para una persona), preguntas en lenguaje del club
- R4 · ASM-01 a ASM-10 en `apps/api/README.md`
- R6 · un test con tag por escenario
- R7–R8 · cada hunk corresponde a los hallazgos 2, 3, 4, 8, 14, 15 o 26
- R9 · los tiempos de espera son requisitos medibles (ASM-03, ASM-06)
- R10 · no applicable · R10 lo cubre REV-01
- D1 · salud, métricas y correlación en módulos propios
- D2 · interfaz → aplicación → dominio; `db.py` en infraestructura
- D3 · sin ciclos
- D4–D7 · el registro centraliza referencia, versión y correlación; nada genérico de más
- D8 · cada dependencia externa con su tiempo de espera (base 5/10 s, Firebase 4 s, SMTP 10 s, app 60 s)
- D9 · amenazas: `X-Request-ID` inyectado (se valida), `/metrics` abierto (token)
- D10 · la respuesta 500 no lleva traza
- D11 · `club_app` sin DDL
- D12–D13 · firmas tipadas
- D14 · no applicable · sin componente de infraestructura nuevo (ASM-02)
- D15 · no applicable · sin bibliotecas nuevas
- K1–K11 · mypy, ruff, analyze; nombres del dominio; sin `catch` mudos
- E1–E4 · no cambian
- E5 · la base caída responde 503 y la API sigue
- E6 · los `catch` mudos registran; ninguna respuesta lleva traza
- E7 · la API no arranca sin base o sin esquema
- E8 · todas las llamadas externas con tiempo de espera
- E9 · not applicable · sin reintentos nuevos
- E10 · not applicable
- E11 · `OperationalError` se traduce a 503 en la interfaz
- E12 · cada error una vez, con su causa
- E13 · captura global en la app (`FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`) y en la API (manejador de excepciones)
- E14 · `aviso_sin_enviar` como alerta en el log
- E15 · cada rama nueva con su test
- E16 · el mensaje dice qué pasó, qué hacer y la referencia
- T1–T14 · rojo antes del código; cada test por comportamiento (el corte de base es real); `stable` de los nuevos tres veces; mutación con subconjuntos
- S1–S13 · not applicable · sin superficie de seguridad nueva salvo `/metrics` (token) y `X-Request-ID` (validado)
- S14 · los eventos nuevos sin datos personales
- S15–S19 · not applicable
- S20 · `club_app` con mínimo privilegio, distinto del dueño que migra
- S21 · not applicable · STRIDE de REV-07
- S22 · `METRICAS_TOKEN` y `DATABASE_URL_APP` como `sync: false`
- S24 · not applicable
- P1–P2 · el log JSON no agrega datos personales; los tests de REV-01 que mandan secretos siguen
- P3–P6 · not applicable
- P7 · respaldo y restauración probados (RPO: el último respaldo; RTO: lo que tarde `restaurar`), escritos en el README
- P8–P16 · not applicable · sin migraciones
- O1 · arranca igual; las variables nuevas son opcionales
- O2 · todo por entorno
- O3 · `.env` absoluto
- O4 · el apagado sigue ordenado
- O5 · JSON por línea con nivel y eventos con nombre estable
- O6 · lo que falla queda visible (503, `aviso_sin_enviar`, `/ready`)
- O7 · no cambia
- O8 · `render.yaml` cambia el chequeo y suma variables, que la card pide
- O9 · todo se revierte por commit o variable
- O10 · no applicable · sin requisito de volumen
- O11 · la suite entera una vez
- O12 · los logs de los tests en `tmp_path`
- O13–O14 · not applicable · de REV-07
- O15 · not applicable
- O16 · versión única expuesta en `/health` y OpenAPI; tags al publicar (ASM-09)
- O17 · id de correlación en cada pedido, cada línea y la respuesta (ASM-07)
- O18 · `/health` y `/ready`, verificados por los tests
- O19 · RED por ruta y USE del pool en `/metrics`; OpenTelemetry no (ASM-08)
- O20 · not applicable · SLOs de REV-07
- O21 · referencia en el mensaje y en el log
- O22 · OUT propuesto
- O24 · OUT propuesto
- O29 · respaldo y restauración probados; smoke post-deploy con `/ready`
- I1–I26 · la app cambia sólo mensajes de error: I12 (textos claros) aplica; las demás no cambian
- C1 · la app real con la API real si el emulador Android está; si no, «no se pudo correr»
- C2–C4 · las respuestas de éxito no cambian; los 500 pasan a JSON con referencia
- A1–A9 · cada «pasó» con su comando; diff proporcional a siete hallazgos; nada se apaga
- V1 · snapshot en 773cb4a
- V2–V7 · plan antes del código; commits con qué y por qué
- W5 · not applicable · el runbook es de REV-07; esta card deja los comandos en el README
- W8 · `/ready` y `/metrics` en el contrato; `apps/api/openapi.json` se regenera
- W9 · el test de contrato de REV-01 sigue
- ci · off by decision · not chosen at install: no signal found in the repo
- docs · off by decision · not chosen at install: no signal found in the repo
- i18n · off by decision · not chosen at install: no signal found in the repo

## Edges

- Defense against legitimate data · un `X-Request-ID` largo o con caracteres raros se reemplaza por uno nuevo, sin error
- State after the action · con la base de vuelta, el siguiente pedido anda (pool con `pre_ping`)
- Honest notices · 503 dice que el servicio no está disponible; la app distingue «no responde» de «sin conexión»
- What does not exist · `/metrics` sin token configurado es 404
- Writes · not applicable
- Origin of the request · `X-Request-ID` ajeno se valida
- What travels to another program · el log JSON; el respaldo
- Restart · la API no arranca sin base y Render reintenta
- What no test notices · el rol `club_app` en la base de Render y la tarea programada: «no se pudo correr» sin despliegue

## Changes to existing behavior

- README: `apps/api/README.md` suma respaldo, usuario de la app, barrido por comando, métricas, `/ready` y los ASM
- ASVS: unchanged here — REV-07 actualiza V16 y S20 al integrar
- Render chequea `/ready` en vez de `/health`
- Los 500 pasan de texto a JSON con referencia; los errores de base dan 503
- El registro pasa a JSON por línea
- La app espera hasta 60 s y muestra la referencia en el error del servidor
- Nuevo: `/ready`, `/metrics`, `--una-vez` del barrido, `scripts/respaldo.py`, `scripts/usuario_de_la_app.py`
