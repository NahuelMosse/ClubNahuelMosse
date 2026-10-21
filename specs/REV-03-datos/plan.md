# Plan — REV-03 · datos

## Time plan

1. Size and risk: unos 12 archivos de producción (migración nueva 0008, `env.py`, repositorios y rutas de reservas y avisos, dominio de avisos, tres archivos de la app) · riesgo: datos guardados, migración en caliente, avisos a personas
2. without method: 120–180–300 min · goal: 900 min · cap: 14 h
3. Critical path: tests en rojo → plan → implementer grupo 1 (migración e índices) → grupo 2 (historiales por marcador) → grupo 3 (cola) → grupo 4 (app) → verify → juicio · on the side from the start: base aparte `club_rev03_migraciones_test` (creada)
4. Split: plan 60 · code 300 · verification 300 · correction 240 min
5. Cut if it does not fit: el reordenamiento del contador del historial global a una sola consulta; nunca un chequeo de la vara

## Verification

```
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync ruff format --check app migraciones tests/escenarios/test_datos.py && uv run --no-sync mypy --strict app
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios --card REV-03
migrate-upgrade: uv run --directory apps/api --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_datos.py -k migracion
mutate apps/api/app/infraestructura/reservas.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_datos.py tests/escenarios/test_historial_reservas.py tests/integracion/test_historial_api.py
mutate apps/api/app/infraestructura/notificaciones.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_datos.py tests/escenarios/test_despacho_robusto.py tests/unit/test_despacho_de_confirmaciones.py
mutate apps/api/app/aplicacion/notificaciones.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_datos.py tests/unit/test_despacho_de_confirmaciones.py
mutate apps/api/app/dominio/notificaciones.py: cd apps/api && uv run --no-sync pytest -q -x tests/unit
mutate apps/api/app/interfaz/marcador.py: cd apps/api && uv run --no-sync pytest -q -x tests/unit tests/escenarios/test_datos.py
mutate apps/api/app/interfaz/reservas.py: cd apps/api && uv run --no-sync pytest -q -x tests/escenarios/test_datos.py tests/integracion/test_historial_api.py
app: cd apps/api && uv run --no-sync uvicorn app.main:app --host 127.0.0.1 --port $PORT
```

La app se muta con lo que `required.mjs` pida, o queda «no se pudo correr» si `mutate.mjs` no trae mutador de Dart.

## File map

Grupo 1 · migración
- apps/api/migraciones/versions/0008_indices_y_cola_recuperable.py — nuevo: `SET lock_timeout = '5s'`; `ALTER TABLE notificacion ADD COLUMN IF NOT EXISTS tomada_en timestamptz, ADD COLUMN IF NOT EXISTS intentos integer NOT NULL DEFAULT 0`; en un `autocommit_block`, `DROP INDEX CONCURRENTLY IF EXISTS` de un índice inválido que haya dejado un intento anterior y `CREATE INDEX CONCURRENTLY IF NOT EXISTS` de `reserva (usuario_id, inicio DESC, id DESC)`, `reserva (inicio DESC, id DESC)`, `reserva (cancelada_por) WHERE cancelada_por IS NOT NULL` y `notificacion (reemplazada_por) WHERE reemplazada_por IS NOT NULL`; el downgrade los saca igual y quita las columnas · test: apps/api/tests/escenarios/test_datos.py
- apps/api/migraciones/env.py — `transaction_per_migration=True`, para que el `autocommit_block` de 0008 no quede adentro de una transacción de todo el upgrade

Grupo 2 · historiales por marcador
- apps/api/app/interfaz/marcador.py — nuevo: codifica y lee el marcador opaco (`inicio` e `id` de la última fila, base64url); uno que no se lee es `DatosInvalidos({"despues": "El marcador de página no es válido"})` · rule · test: apps/api/tests/escenarios/test_datos.py
- apps/api/app/infraestructura/reservas.py — `de_usuario(usuario_id, cuando, despues, limite=20)` con `(inicio, id) < (:i, :id)` (o `>` en próximas) y `LIMIT 21` para saber si hay más; `historial(filtros)` con `despues` por la misma clave (`pagina` sigue para clientes viejos, acotada por REV-01); los cuatro contadores y el total en una sola consulta con `count(*) FILTER (...)` · hot-path
- apps/api/app/interfaz/reservas.py — `despues` opcional en `GET /reservas` y `GET /reservas/todas`; la respuesta suma `siguiente` (marcador o `null`); lo demás de la respuesta queda igual
- apps/api/app/aplicacion/reservas.py — pasa `despues` y `limite` a los repositorios

Grupo 3 · cola de avisos
- apps/api/app/dominio/notificaciones.py — `TOMA_VENCIDA = timedelta(minutes=5)`, `INTENTOS_MAXIMOS = 3`, y la decisión de qué hacer con un aviso varado (`reintentar` o `dar_por_fallido`) según tipo e intentos · rule · test: apps/api/tests/unit/test_cola_de_avisos.py
- apps/api/app/infraestructura/notificaciones.py — `tomar_siguiente` toma, con `FOR UPDATE SKIP LOCKED`, el más viejo de: `pendiente` (los recordatorios sólo si su turno no empezó y se registraron hace más de 1 min), o `enviando` con `tomada_en` vencida, que no sea recordatorio y con `intentos < 3`; al tomarlo pone `tomada_en = now()` e `intentos = intentos + 1`; `marcar_varados_fallidos` pasa a `fallida` los recordatorios varados y los que agotaron intentos
- apps/api/app/aplicacion/notificaciones.py — `despachar_pendientes` llama primero a `marcar_varados_fallidos` y registra cada aviso dado por fallido como `aviso_sin_enviar` (nivel error, con id y tipo, sin datos personales)

Grupo 4 · app
- apps/mobile/lib/reservas/reservas.dart — el historial propio lee `siguiente` y pide la tanda siguiente con `despues`
- apps/mobile/lib/reservas/pantalla_mis_reservas.dart — al llegar al final de Historial pide la tanda siguiente, con indicador de carga, sin repetir reservas
- apps/mobile/lib/admin/historial_reservas.dart — si la respuesta trae `siguiente`, lo manda como `despues` junto con la página; sin `siguiente`, sigue por página como hoy

Tests
- apps/api/tests/escenarios/test_datos.py — los escenarios REV-03 de la API (rojo, del hilo principal)
- apps/mobile/test/historial_por_tandas_test.dart — REV-03-H10-02 en la app (rojo, del hilo principal)
- apps/api/tests/unit/test_cola_de_avisos.py, apps/api/tests/unit/test_marcador.py — unitarios del implementer

- System design: unchanged — el modelo de datos de las 9 tablas lo escribe REV-07; esta card agrega dos columnas y cuatro índices, que el cierre lista para que REV-07 los incluya
- ADR: unchanged — no cambia la arquitectura

## Assumptions

- REV-03-ASM-01 · un marcador que no se lee es 422 con `{"errores": {"despues": "El marcador de página no es válido"}}`; uno válido después del final trae lista vacía y `siguiente: null` · any-answer: yes
- REV-03-ASM-02 · un aviso de cancelación varado en `enviando` se vuelve a mandar (puede llegar dos veces); un recordatorio varado queda `fallida` y no se repite, por «Se envía una sola vez» de CU-24.1 · any-answer: no — si se prefiere no repetir nunca, el aviso de cancelación también queda fallido
- REV-03-ASM-03 · el historial propio trae tandas de 20, igual que el global; una app vieja que no manda `despues` ve las 20 más recientes · any-answer: yes
- REV-03-ASM-04 · un aviso `enviando` hace más de 5 minutos se da por varado · any-answer: yes
- REV-03-ASM-05 · cada toma suma un intento; con 3 intentos el aviso queda `fallida` y se registra `aviso_sin_enviar` · any-answer: yes
- REV-03-ASM-06 · la ida y vuelta de cada migración se prueba con datos en las tablas de 0001; bajar una migración que creó una tabla borra sus datos, y alcanza con que el esquema vuelva y los datos de las otras tablas sigan · any-answer: yes
- REV-03-ASM-07 · con el mismo inicio, va primero el id más alto (ya era así) · any-answer: yes
- REV-03-ASM-08 · una reserva que entra mientras alguien recorre el historial no aparece en las tandas que ya vio; aparece al volver a abrirlo · any-answer: yes
- REV-03-ASM-09 · de cada intento queda `tomada_en` e `intentos`; el detalle del error va al log, no a la base · any-answer: yes
- REV-03-ASM-10 · el total y los contadores del historial global siguen exactos (CU-14), contados en una sola consulta en vez de dos · any-answer: no — contar sigue recorriendo las filas que pasan el filtro
- REV-03-ASM-11 · el historial global acepta `despues` y sigue aceptando `pagina` para las apps ya instaladas; con los dos, manda `despues` · any-answer: yes

## Perimeter

Postgres compartido, base `club_rev03_test` y una base aparte `club_rev03_migraciones_test` que el test borra y crea; emulador de Firebase Auth en `127.0.0.1:9099`. Los avisos salen a un canal de prueba (`CanalDePrueba`). El hallazgo 12 no se corrige: editar migraciones de main reescribe la historia; se declara al cierre. Fuera: el barrido con Render dormido (hallazgo 3, REV-02), el modelo de datos documentado (REV-07).

## Bar

- R1 · los escenarios recorren la API por HTTP con sesiones del emulador y la base real; la app se prueba con su pantalla de Mis reservas
- R2 · diez preguntas y AMB-01 a AMB-10 en `ambiguities.md`
- R3 · cada ASM dice si sirve con cualquier respuesta
- R4 · ASM-02, ASM-03, ASM-04, ASM-05 y ASM-11 van en `apps/api/README.md`
- R5 · preguntas en lenguaje del club
- R6 · un test con tag por escenario
- R7 · cada hunk corresponde a los hallazgos 10, 11 o 13
- R8 · lo ajeno visto va como `REV-03-OUT-NN`
- R9 · no applicable · la card no fija requisitos de volumen nuevos; el presupuesto lo escribe REV-07
- R10 · no applicable · la card no toca seguridad
- D1 · `marcador.py` en interfaz; la regla de la cola en dominio
- D2 · interfaz → aplicación → dominio; el test de capas existente lo cubre
- D3 · sin ciclos nuevos
- D4 · `de_usuario` y `historial` esconden el marcador detrás de `despues` y `siguiente`
- D5 · el marcador se codifica en un solo lugar para los dos historiales
- D6 · `pagina` sigue sólo por las apps instaladas (ASM-11)
- D7 · se reusa `tomar_siguiente`, `FOR UPDATE SKIP LOCKED` y `CanalDePrueba`
- D8 · no applicable · sin dependencias externas nuevas
- D9 · no applicable · la card no abre superficie nueva; el marcador es opaco y se valida
- D10 · el marcador sólo lleva inicio e id de una reserva que la persona ya ve
- D11 · cada repositorio escribe sus tablas
- D12 · firmas tipadas con `despues: str | None`
- D13 · la pantalla habla con `Reservas` por su API pública
- D14 · no applicable · sin módulo, proceso ni almacenamiento nuevo
- D15 · no applicable · ninguna biblioteca nueva
- K1 · `mypy --strict app` sin supresiones nuevas; `flutter analyze` limpio
- K2 · ruff y analyze; Sonar «no se pudo correr»
- K3 · funciones cortas
- K4 · el marcador y la consulta de tanda no se duplican entre historiales
- K5 · sin código muerto; las dos consultas de conteo pasan a una
- K6 · nombres del dominio
- K7 · comentarios sólo para el porqué (CONCURRENTLY, `LIMIT 21`)
- K8 · `despues` se valida al entrar
- K9 · conexiones en `with`
- K10 · ninguna consulta sin tope: las dos listas cortan en 20
- K11 · convenciones del repo
- E1 · los avisos varados sobreviven a un reinicio y se retoman
- E2 · la migración se puede reintentar si se corta
- E3 · `SKIP LOCKED` evita que dos barridos tomen el mismo aviso
- E4 · reintentar la migración no duplica nada (`IF NOT EXISTS`)
- E5 · un marcador malo es 422, no 500
- E6 · el aviso dado por fallido queda en el log
- E7 · no applicable · la card no cambia el arranque
- E8 · no applicable · sin llamadas externas nuevas
- E9 · los reintentos de un aviso de cancelación se espacian 5 minutos y terminan a los 3
- E10 · no applicable
- E11 · `DatosInvalidos` cruza a interfaz como 422
- E12 · el fallo se registra una vez
- E13 · no applicable · manejadores globales de REV-02
- E14 · la cola tiene límite de intentos, estado final `fallida` como cola muerta y alerta por log `aviso_sin_enviar`
- E15 · cada rama nueva (marcador malo, varado, agotado, recordatorio varado) con su test
- E16 · no applicable · sin mensajes nuevos a la persona
- T1 · rojo antes del código
- T2 · ningún test se ablanda
- T3 · mutación sobre cada archivo de producción con el subconjunto
- T4 · cada test afirma un resultado
- T5 · por comportamiento; los índices se miran en el catálogo porque son el requisito (P9)
- T6 · sin lógica en los tests; el servidor falso de Dart responde por tabla
- T7 · cada test crea sus datos; la base de migraciones es propia
- T8 · los nuevos tres veces
- T9 · la regla de la cola con unitarios
- T10 · cada borde con su test
- T11 · cobertura si `pytest-cov` está; si no, «no se pudo correr»
- T12 · la pantalla se busca por texto y semántica
- T13 · `dominio/notificaciones.py` y `marcador.py` marcados `rule`
- T14 · no applicable
- S1–S24 · not applicable · la card no toca autenticación, permisos, entradas de texto ni dependencias
- P1 · no applicable · sin datos personales nuevos
- P2 · no applicable · sin datos personales nuevos en el log: `aviso_sin_enviar` lleva id y tipo
- P3 · las respuestas suman sólo `siguiente`
- P4 · columnas nuevas con valor por defecto: expandir sin contraer
- P5 · ida y vuelta de cada migración con datos, en la suite (H13-02), y 0008 sobre el estado de main
- P6 · `intentos` NOT NULL DEFAULT 0
- P7 · no applicable · retención y backups son de REV-02 y REV-07
- P8 · `timestamptz` e `integer`
- P9 · cada consulta nueva o cambiada sobre `reserva` y `notificacion` tiene su índice
- P10 · una consulta por tanda; un test cuenta consultas si el inspector lo pide
- P11 · las dos listas por clave `(inicio, id)`, con `id` de desempate
- P12 · índices `CONCURRENTLY` y `lock_timeout` en 0008
- P13 · el envío del push sigue fuera de la transacción de la toma
- P14 · no applicable · el modelo de datos documentado es de REV-07
- P15 · no applicable · el inventario es de REV-07
- P16 · ninguna migración de main se toca; se agrega 0008
- O1 · `alembic upgrade head` agrega 0008 sin pasos ocultos
- O2 · sin configuración nueva
- O3 · no applicable
- O4 · no cambia el apagado
- O5 · `aviso_sin_enviar` con nombre estable
- O6 · el aviso perdido queda visible en el log y como `fallida`
- O7 · no cambia
- O8 · no cambia el despliegue: la migración corre en el build como hoy
- O9 · 0008 tiene downgrade
- O10 · no applicable · sin requisito de volumen; el plan de `EXPLAIN` con 200 k reservas lo puede correr el inspector
- O11 · la suite entera una vez
- O12 · la base de migraciones se borra en cada corrida
- O13–O29 · not applicable · operación, costos y observabilidad son de REV-02 y REV-07
- I1–I26 · la pantalla de Mis reservas suma la carga de la tanda siguiente: I23 (indicador mientras carga) y I10 aplican y se prueban; las demás no cambian
- C1 · la app lee `siguiente`; una app vieja sigue funcionando (ASM-03, ASM-11)
- C2 · no applicable
- C3 · la suite entera sigue verde
- C4 · las respuestas sólo suman `siguiente`
- A1 · cada «pasó» con su comando
- A2 · el cierre nombra sólo lo del diff
- A3 · AMB registradas, sin canal → ASM
- A4 · hooks y `verify.mjs`
- A5 · diff proporcional a tres hallazgos
- A6 · cableado de punta a punta: migración, repositorio, ruta y app
- A7 · el juicio no reemplaza un comando
- A8 · no applicable
- A9 · ningún test se apaga
- V1 · snapshot en ab84031
- V2 · este plan antes del código
- V3 · commits con qué y por qué
- V4 · registro de la sesión
- V5 · la pantalla de Mis reservas: I23 e I10 con evidencia
- V6 · el cierre sale de las validaciones
- V7 · una persona aprueba antes de integrar
- W5 · no applicable · runbook de REV-07
- W8 · `despues` y `siguiente` documentados en OpenAPI
- W9 · el contrato lo versiona REV-01; esta card actualiza `openapi.json` al integrar
- ci · off by decision · not chosen at install: no signal found in the repo
- docs · off by decision · not chosen at install: no signal found in the repo
- i18n · off by decision · not chosen at install: no signal found in the repo

## Edges

- Defense against legitimate data · dos reservas con el mismo inicio no se pierden ni se repiten entre tandas (desempate por id)
- State after the action · un aviso reintentado queda `enviada`; uno agotado, `fallida`
- Honest notices · el admin ve `fallida` en vez de «todavía no salió» para siempre
- What does not exist · un marcador después del final trae lista vacía
- Writes · `tomada_en` e `intentos` se escriben en la misma toma
- Origin of the request · no applicable
- What travels to another program · el push sale una vez por toma
- Restart · un aviso tomado antes de un reinicio se retoma a los 5 minutos
- What no test notices · el tiempo real de la migración con 200 k reservas en Render: «no se pudo correr» sin despliegue

## Changes to existing behavior

- README: `apps/api/README.md` suma ASM-02 a ASM-05 y ASM-11
- ASVS: unchanged — la card no toca seguridad
- `GET /reservas` deja de devolver todo el historial: trae 20 y `siguiente`
- `GET /reservas/todas` suma `despues` y `siguiente`; `pagina` sigue
- Un aviso varado en `enviando` se retoma o queda `fallida`; antes quedaba para siempre
- Un recordatorio registrado y no enviado se manda en el barrido siguiente
- Nuevo: migración 0008 con cuatro índices y dos columnas de `notificacion`
- Lo demás queda igual: permisos, orden y forma de cada reserva
