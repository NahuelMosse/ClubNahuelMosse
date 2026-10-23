# REV-02 · operación

card: REV-02
status: proposed
cap: 20 h
sources: "REVISION-kit3.md @ 138bc54 (specs/REVISION-kit3.md): encabezado, líneas 1-5; hallazgos 2, 3, 4, 8, 14, 15 y 26 completos"; "handoff del coordinador (HANDOFF.md, sección «## Decisiones que son tuyas (AMB abiertas)», entera)"; "pedido (texto) del coordinador, transcripto entero"; "enunciado: Trabajo Práctico_2026.docx.pdf (pdftotext -enc UTF-8 -layout, texto entero)"; "CU-24.1: CU-nuevos/CU-24.1 - Notificacion recordatoria.md (texto entero)"; "TP-07: specs/TP-07-manejo-de-errores/card.snapshot.md, sección «## Card, tal como está escrita» (líneas 22-44)"
not_read: "Jira / Atlassian: no consultado; REV-02 no tiene card en Jira y el requisito llega como texto del coordinador."; "REVISION-kit3.md: leído entero, pero sólo se transcriben el encabezado y los hallazgos 2, 3, 4, 8, 14, 15 y 26; el resto (Costo, Qué corrió, hallazgos 1, 5-7, 9-13, 16-25, 27-28, Sin hallazgo, Qué no se pudo correr, CU sin cubrir) no está en la card por no haberse pedido."; "HANDOFF.md: sólo se transcribe la sección «Decisiones que son tuyas (AMB abiertas)»; no se transcriben «Qué hay que hacer», «Cards», «Estado del entorno al hacer el handoff» ni «Para cerrar todo»."; "Figma citado en TP-07 (VUiZR6V4USuiyxRgtshhEn; 42:384, 42:410, 42:426, 42:442, 393:6532, 30:365, 34:647): no abierto. Sólo se transcribe el texto que el snapshot de TP-07 reproduce."; "Figma citado en CU-24.1 (6 pantallas P-24.1-*, y Push-Notification, Empty-State, AppBar): no abierto. Sólo se transcribe el texto del CU."; "Código citado en el pedido y en los hallazgos (main.py, db.py, registro_errores.py, render.yaml, lib/main.dart, lib/comun/dialogo_error.dart y los path:línea de los hallazgos): no abierto; no es parte de la card, que es texto."; "TP-07: ambiguedades.md, plan.md y tasks.md de specs/TP-07-manejo-de-errores/: no leídos, no pedidos."

## Specs

- S1 · "con la base inalcanzable un pedido falla rápido con un error controlado"
- S2 · "el chequeo de disponibilidad dice que la API no está lista cuando la base no responde"
- S3 · "los recordatorios salen aunque el servicio web esté dormido"
- S4 · "un recordatorio que no salió queda a la vista de quien opera"
- S5 · "la base de producción tiene copia de seguridad y una vuelta atrás probada"
- S6 · "la app se conecta con un usuario de base que no puede cambiar el esquema"
- S7 · "un error del servidor le da a la persona un número de referencia que soporte encuentra en el log"
- S8 · "si la API tarda en despertar, la app dice que está despertando y no que falta internet"
- S9 · "cada pedido lleva un id de correlación en todas sus líneas de log y en la respuesta"
- S10 · "cada error se registra una sola vez, con la versión"
- S11 · "la app registra sus errores no manejados en vez de tragarlos"
- S12 · "la API no arranca sana si no hay base o no tiene el esquema"
- S13 · "hay métricas por ruta y del pool de conexiones"
- S14 · "la versión vive en un solo lugar y la API la expone"
- S15 · "la configuración se lee igual desde cualquier carpeta de arranque"
- REV-02-ASM-01 · mientras no se decida el plan pago (REV-02-AMB-01), la base se respalda con `scripts/respaldo.py` antes de que venza, y la vuelta atrás se prueba restaurando en otra base · S5
- REV-02-ASM-02 · el barrido corre también como comando de una pasada; quién lo dispara con la API dormida (tarea de Render, servicio pago) lo decide una persona; `render.yaml` no suma una tarea paga · S3
- REV-02-ASM-03 · la base espera 5 s para conectar y para un lugar en el pool, 10 s por consulta y 5 s por un bloqueo; si no responde, 503 con mensaje y referencia; Render chequea `/ready` · S1
- REV-02-ASM-04 · la app entra con `club_app`, que sólo lee y escribe filas; las migraciones siguen con el dueño de la base; si Render no deja crear el rol, `DATABASE_URL_APP` queda sin definir y la app usa `DATABASE_URL` como hoy · S6
- REV-02-ASM-05 · la referencia del error es el id de correlación del pedido · S7
- REV-02-ASM-06 · la app espera hasta 60 s; si no hay respuesta dice «El servidor no responde. Probá de nuevo en unos minutos.»; sin red sigue diciendo «Revisá tu conexión a internet» · S8
- REV-02-ASM-07 · el id de correlación llega en `X-Request-ID` (hasta 64 caracteres, letras, números y guiones) o se genera; las llamadas a Firebase y al SMTP no lo llevan porque sus clientes no lo permiten · S9
- REV-02-ASM-08 · las métricas se exponen en `/metrics` para quien tenga `METRICAS_TOKEN`; no se agrega OpenTelemetry porque el club no tiene dónde mandar las trazas · S13
- REV-02-ASM-09 · la versión vive en `pyproject.toml`; los tags de versión se crean al publicar, que en este repo hace una persona · S14
- REV-02-ASM-10 · el registro sale en JSON por línea, con nivel, evento, referencia y versión · S10
- REV-02-ASM-11 · si la API tarda más de 5 s, la app avisa que se está despertando y que puede tardar hasta un minuto, mientras sigue esperando · S8
- REV-02-ASM-12 · retomar la sesión espera lo mismo que cualquier pedido (hasta 60 s) y, si no hay respuesta, no manda al login: muestra el error del servidor y deja reintentar · S8
- REV-02-ASM-13 · la app registra sus errores no manejados en la consola de depuración (no tiene dónde mandarlos); pasan por ese registro los tres manejadores (`FlutterError.onError`, `PlatformDispatcher.onError`, `runZonedGuarded`) y los cuatro lugares que los tragaban (detalle de la reserva, centro de notificaciones, editar espacio, inicio) · S11
- REV-02-ASM-14 · `/metrics` sin token, con uno malo o sin `METRICAS_TOKEN` definido responde 404 · S13
- REV-02-ASM-15 · las métricas por ruta usan la plantilla de la ruta; los pedidos a rutas que no existen suman a una sola serie `sin_ruta` · S13
- REV-02-ASM-16 · el 500 y el 503 responden `{"mensaje", "referencia"}`, sin traceback ni detalle interno; el OpenAPI documenta el 500, el 503, `/ready` y `/metrics` · S7
- REV-02-ASM-17 · el log JSON no lleva DNI, correo, token de dispositivo, `Authorization` ni la contraseña de `DATABASE_URL` · S10
- REV-02-ASM-18 · «no arranca sana» quiere decir que el proceso arranca y `/ready` responde 503 hasta que haya base con esquema; el proceso no termina, así Render no lo reinicia en bucle · S12

## Tasks

- T1 · S1,S2,S12 · apps/api/app/infraestructura/db.py (data), apps/api/app/interfaz/salud.py (presentation), apps/api/app/main.py (presentation), render.yaml · tests: apps/api/tests/escenarios/test_operacion.py "con la base inalcanzable un pedido falla rápido, en 5 s, con un 503 controlado @REV-02-S1 @assumption:REV-02-ASM-03"; apps/api/tests/escenarios/test_operacion.py "una consulta que pasa de 10 s se corta con un 503 @REV-02-S1 @assumption:REV-02-ASM-03"; apps/api/tests/escenarios/test_operacion.py "esperar un lugar en el pool más de 5 s da un 503 @REV-02-S1 @assumption:REV-02-ASM-03"; apps/api/tests/escenarios/test_operacion.py "esperar un bloqueo más de 5 s da un 503 @REV-02-S1 @assumption:REV-02-ASM-03"; apps/api/tests/escenarios/test_operacion.py "sin base o sin esquema la API no arranca sana: el proceso sigue y /ready responde 503 @REV-02-S12 @assumption:REV-02-ASM-18"; apps/api/tests/escenarios/test_operacion.py "el chequeo de disponibilidad dice que la API no está lista sin base @REV-02-S2"; apps/api/tests/escenarios/test_operacion.py "Render reinicia la API cuando no está lista @REV-02-S2 @assumption:REV-02-ASM-03"; apps/api/tests/escenarios/test_operacion.py "la API no arranca sana si la base no tiene el esquema @REV-02-S12"; apps/api/tests/escenarios/test_operacion.py "la API no arranca sana si no hay base @REV-02-S12"
- T2 · S7,S9,S10,S13,S14,S15 · apps/api/app/interfaz/registro_errores.py (presentation), apps/api/app/interfaz/metricas.py (presentation), apps/api/app/config.py (rule) · tests: apps/api/tests/escenarios/test_operacion.py "un error del servidor da un número de referencia que soporte encuentra en el log @REV-02-S7 @REV-02-S10"; apps/api/tests/escenarios/test_operacion.py "cada pedido lleva un id de correlación en sus líneas de log y en la respuesta @REV-02-S9 @assumption:REV-02-ASM-07"; apps/api/tests/escenarios/test_operacion.py "un X-Request-ID de más de 64 caracteres o con otros signos se reemplaza por uno generado @REV-02-S9 @assumption:REV-02-ASM-07"; apps/api/tests/escenarios/test_operacion.py "la referencia del error es el id de correlación del pedido @REV-02-S7 @assumption:REV-02-ASM-05"; apps/api/tests/escenarios/test_operacion.py "la versión vive en pyproject.toml y la API la expone @REV-02-S14 @assumption:REV-02-ASM-09"; apps/api/tests/escenarios/test_operacion.py "el registro sale en JSON por línea con nivel, evento, referencia y versión @REV-02-S10 @assumption:REV-02-ASM-10"; apps/api/tests/escenarios/test_operacion.py "/metrics sin token, con uno malo o sin METRICAS_TOKEN responde 404 @REV-02-S13 @assumption:REV-02-ASM-14"; apps/api/tests/escenarios/test_operacion.py "las métricas usan la plantilla de la ruta y las rutas que no existen suman a sin_ruta @REV-02-S13 @assumption:REV-02-ASM-15"; apps/api/tests/escenarios/test_operacion.py "el 500 y el 503 responden mensaje y referencia, sin traceback @REV-02-S7 @assumption:REV-02-ASM-16"; apps/api/tests/escenarios/test_operacion.py "el OpenAPI documenta el 500, el 503, /ready y /metrics @REV-02-S7 @assumption:REV-02-ASM-16"; apps/api/tests/escenarios/test_operacion.py "el log JSON no lleva DNI, correo, token de dispositivo, Authorization ni la contraseña de la base @REV-02-S10 @assumption:REV-02-ASM-17"; apps/api/tests/escenarios/test_operacion.py "el 500 y el 503 llevan X-Request-ID @REV-02-S9 @assumption:REV-02-ASM-07"; apps/api/tests/escenarios/test_operacion.py "hay métricas por ruta y del pool de conexiones @REV-02-S13 @assumption:REV-02-ASM-08"; apps/api/tests/escenarios/test_operacion.py "la versión vive en un solo lugar y la API la expone @REV-02-S14"; apps/api/tests/escenarios/test_operacion.py "la configuración se lee igual desde cualquier carpeta de arranque @REV-02-S15"
- T3 · S3,S4,S5,S6 · apps/api/app/interfaz/barrido.py (presentation), apps/api/app/aplicacion/notificaciones.py (rule), scripts/respaldo.py (data), scripts/usuario_de_la_app.py (data), apps/api/README.md · tests: apps/api/tests/escenarios/test_operacion.py "los recordatorios salen aunque el servicio web esté dormido @REV-02-S3 @assumption:REV-02-ASM-02"; apps/api/tests/escenarios/test_operacion.py "un recordatorio que no salió queda a la vista de quien opera @REV-02-S4"; apps/api/tests/escenarios/test_operacion.py "la base de producción tiene copia de seguridad y una vuelta atrás probada @REV-02-S5 @assumption:REV-02-ASM-01"; apps/api/tests/escenarios/test_operacion.py "la app se conecta con un usuario de base que no puede cambiar el esquema @REV-02-S6 @assumption:REV-02-ASM-04"
- T4 · S7,S8,S11 · apps/mobile/lib/api/cliente_api.dart (presentation), apps/mobile/lib/comun/dialogo_error.dart (presentation), apps/mobile/lib/comun/errores_no_manejados.dart (presentation), apps/mobile/lib/main.dart (presentation), apps/mobile/lib/app.dart (presentation), apps/mobile/lib/comun/aviso_despertando.dart (presentation), apps/mobile/lib/comun/pantalla_error_de_arranque.dart (presentation), apps/mobile/lib/sesion/sesion.dart (presentation), apps/mobile/lib/admin/pantalla_detalle_reserva.dart (presentation), apps/mobile/lib/notificaciones/centro.dart (presentation), apps/mobile/lib/admin/pantalla_editar_espacio.dart (presentation), apps/mobile/lib/inicio/pantalla_inicio.dart (presentation) · tests: apps/mobile/test/operacion_app_test.dart "un pedido que tarda 40 s porque la API está despertando no se corta @REV-02-S8 @assumption:REV-02-ASM-06"; apps/mobile/test/operacion_app_test.dart "a los 60 s sin respuesta dice El servidor no responde. Probá de nuevo en unos minutos. @REV-02-S8 @assumption:REV-02-ASM-06"; apps/mobile/test/operacion_app_test.dart "sin red sigue diciendo Revisá tu conexión a internet @REV-02-S8 @assumption:REV-02-ASM-06"; apps/mobile/test/operacion_app_test.dart "si la API tarda más de 5 s la app avisa que se está despertando y que puede tardar hasta un minuto @REV-02-S8 @assumption:REV-02-ASM-11"; apps/mobile/test/operacion_app_test.dart "retomar la sesión espera hasta 60 s y sin respuesta no manda al login @REV-02-S8 @assumption:REV-02-ASM-12"; apps/mobile/test/operacion_app_test.dart "un error de Flutter queda registrado @REV-02-S11 @assumption:REV-02-ASM-13"; apps/mobile/test/operacion_app_test.dart "un error de la plataforma queda registrado @REV-02-S11 @assumption:REV-02-ASM-13"; apps/mobile/test/operacion_app_test.dart "un error de una zona queda registrado @REV-02-S11 @assumption:REV-02-ASM-13"; apps/mobile/test/operacion_app_test.dart "el detalle de la reserva registra el error que ignoraba @REV-02-S11 @assumption:REV-02-ASM-13"; apps/mobile/test/operacion_app_test.dart "el centro de notificaciones registra los errores que tragaba @REV-02-S11 @assumption:REV-02-ASM-13"; apps/mobile/test/operacion_app_test.dart "editar espacio registra el error que tragaba @REV-02-S11 @assumption:REV-02-ASM-13"; apps/mobile/test/operacion_app_test.dart "el inicio registra el error que tragaba @REV-02-S11 @assumption:REV-02-ASM-13"; apps/mobile/test/operacion_app_test.dart "si la API no responde en un minuto, el error dice que no responde y no que falta internet @REV-02-S8 @assumption:REV-02-ASM-06"; apps/mobile/test/operacion_app_test.dart "un error del servidor le muestra a la persona su número de referencia @REV-02-S7"; apps/mobile/test/operacion_app_test.dart "la app registra sus errores no manejados en vez de tragarlos @REV-02-S11"

## Changes to existing behavior

- README: `apps/api/README.md` suma respaldo, usuario de la app, barrido por comando, métricas, `/ready` y los ASM
- ASVS: unchanged here — REV-07 actualiza V16 y S20 al integrar
- Render chequea `/ready` en vez de `/health`
- Los 500 pasan de texto a JSON con referencia; los errores de base dan 503
- El registro pasa a JSON por línea
- La app espera hasta 60 s y muestra la referencia en el error del servidor
- Nuevo: `/ready`, `/metrics`, `--una-vez` del barrido, `scripts/respaldo.py`, `scripts/usuario_de_la_app.py`

## Gate

```
suite: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync mypy --strict app
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider tests/escenarios/test_operacion.py
mutate apps/api/app/infraestructura/db.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py -k "base or disponibilidad"
mutate apps/api/app/interfaz/registro_errores.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py tests/escenarios/test_registro_de_errores.py tests/escenarios/test_seguridad_api.py -k "registro or referencia or correlacion or log"
mutate apps/api/app/interfaz/metricas.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py -k metricas
mutate apps/api/app/interfaz/salud.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py -k "disponibilidad or version"
mutate apps/api/app/main.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py tests/escenarios/test_seguridad_api.py
mutate apps/api/app/config.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py -k "configuracion or version"
mutate apps/api/app/interfaz/barrido.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py -k recordatorios
mutate scripts/respaldo.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py
mutate scripts/usuario_de_la_app.py: sh D:/Temp/w/herramientas/pytest-api.sh -q -x tests/escenarios/test_operacion.py
mutate apps/mobile/lib/api/cliente_api.dart: cd apps/mobile && flutter test test/operacion_app_test.dart
mutate apps/mobile/lib/comun/dialogo_error.dart: cd apps/mobile && flutter test test/operacion_app_test.dart
mutate apps/mobile/lib/comun/errores_no_manejados.dart: cd apps/mobile && flutter test test/operacion_app_test.dart
app: sh D:/Temp/w/herramientas/api-app.sh rev02_app
attacks: sh D:/Temp/w/herramientas/api-attacks.sh rev02_app --json --no-ambient --common-headers "X-Request-ID, Content-Security-Policy" --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo
```

## Log

- L1 · **Encabezado de la revisión** (fuente: REVISION-kit3.md @ 138bc54, líneas 1-5)

    # Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

    Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
    i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
    177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.

  **Hallazgo 2** (fuente: REVISION-kit3.md @ 138bc54, líneas 60-66)

  2. **Un corte de red con la base cuelga la API y el health check sigue en verde** · E8, O18 · falló · medido
     - `apps/api/app/infraestructura/db.py:12` crea el engine sin `connect_timeout` ni `pool_timeout`; el rol no tiene
       `statement_timeout` ni `lock_timeout`. `render.yaml:14` usa `/docs` como health check.
     - Evidencia: con la base en 10.255.255.1, `GET /reservas` tardó 131 s en dar 500 mientras `/docs` respondía 200 en
       5 ms.
     - Impacto: cada pedido retiene un hilo del pool 130 s (la app se rinde a los 15 s); con pocos usuarios la API se
       satura y Render la ve sana, así que no la reinicia.

  **Hallazgo 3** (fuente: REVISION-kit3.md @ 138bc54, líneas 68-74)

  3. **En Render los recordatorios de una hora antes no salen** · E14 · falló · lectura más la doc de Render
     - `apps/api/app/interfaz/barrido.py:38-45` y `app/main.py:26-31`: el barrido corre dentro del proceso web, y el plan
       free lo duerme a los 15 min sin tráfico (lo dice `apps/api/README.md:139-141`). La ventana de vencidos es
       (ahora, ahora + 1 h] (`infraestructura/notificaciones.py:137`), y un push fallido queda «fallida» sin reintento ni
       alerta (`aplicacion/notificaciones.py:110-130`).
     - Impacto: CU-24.1 se cumple en la nube sólo si alguien usa la API en la hora previa a cada turno, y nadie se entera
       cuando no.

  **Hallazgo 4** (fuente: REVISION-kit3.md @ 138bc54, líneas 76-82)

  4. **La base de producción no tiene backups, vence, y no hay vuelta atrás de datos** · O29, P7, P15 · falló · lectura más
     la doc de Render
     - `render.yaml:45-49` usa `plan: free`: sin backups, vence a los 30 días y se borra 14 días después
       (`apps/api/README.md:142`). Las migraciones corren en el build contra esa base (`render.yaml:11`).
     - Tampoco hay RPO ni RTO, restore probado, ni inventario, retención o clasificación de los datos personales (DNI,
       nacimiento, correo, token de dispositivo); la Ley 25.326 no figura en el repo.
     - Impacto: entre los días 30 y 44 se pierden todas las cuentas y reservas, y una migración mala no tiene vuelta.

  **Hallazgo 8** (fuente: REVISION-kit3.md @ 138bc54, líneas 110-113)

  8. **Un solo usuario de base migra y atiende la app** · S20 · falló · lectura
     - `render.yaml:11,45-49`: el usuario `club` corre `alembic upgrade head` en el build y es el de la app; en local es
       superusuario.
     - Impacto: una inyección o un RCE tendría DDL completo sobre la base.

  **Hallazgo 14** (fuente: REVISION-kit3.md @ 138bc54, líneas 150-156)

  14. **El error que ve la persona no tiene referencia y, con Render dormido, dice algo falso** · O21, E16 · falló · lectura
      - El 500 es «Internal Server Error» sin id, y el overlay (`apps/mobile/lib/comun/dialogo_error.dart:36-43`) no
        muestra ninguno.
      - Render tarda ~1 min en despertar y el cliente corta a los 15 s (`lib/api/cliente_api.dart:28`): se ve «Revisá tu
        conexión a internet». Retomar la sesión corta a los 3 s (`lib/sesion/sesion.dart:128`) y manda al login aunque la
        sesión siga viva.
      - Impacto: soporte no puede ubicar el caso, y el primer uso del día falla con un diagnóstico equivocado.

  **Hallazgo 15** (fuente: REVISION-kit3.md @ 138bc54, líneas 158-166)

  15. **No hay observabilidad de producción** · O6, O17, O19, O20, E13, E6, E12, E7 · falló · medido
      - Los pedidos no llevan id de correlación: `X-Request-ID` y `traceparent` se ignoran (`interfaz/registro_errores.py:47-59`).
      - Los errores no llevan la versión. No hay métricas, OpenTelemetry, SLOs ni alertas.
      - La app no instala `FlutterError.onError`, `PlatformDispatcher.onError` ni `runZonedGuarded`
        (`apps/mobile/lib/main.dart:15-46`), y traga errores sin rastro: `.ignore()` en
        `admin/pantalla_detalle_reserva.dart:55-60`, y `on Exception {}` en `notificaciones/centro.dart:189,210`,
        `admin/pantalla_editar_espacio.dart:78` e `inicio/pantalla_inicio.dart:141`.
      - Cada error no manejado se registra dos veces con el traceback completo (E12).
      - La API arranca «sana» sin base o sin esquema, y falla recién en el primer pedido (E7, `app/main.py:25-38`).

  **Hallazgo 26** (fuente: REVISION-kit3.md @ 138bc54, líneas 257-261)

  26. **Operación menor** · O3, O16, O22, O24 · falló
      - `env_file=".env"` se resuelve contra el cwd (`app/config.py:8`, medido con dos cwd).
      - La versión está repetida a mano (`app/main.py:45`, `pyproject.toml:3`) y no hay tags.
      - No hay prueba de carga del camino caliente (p95 local de ~55 ms, con 4 filas).
      - No hay staging ni un artefacto único promovido (`lib/configuracion.dart:21-34`).

  **Decisiones que son tuyas** (fuente: handoff del coordinador, HANDOFF.md, sección «## Decisiones que son tuyas (AMB abiertas)», entera)

    ## Decisiones que son tuyas (AMB abiertas)

    - **Plan pago de Render.** Base con backups y un servicio que no se duerma, o un Cron Job para el barrido. Hoy la base
      free vence a los 30 días, no tiene backups y los recordatorios no salen con el servicio dormido (hallazgos 3 y 4).
      Mientras no decidas, REV-02 deja el ASM más barato de deshacer y lo declara.

  **Pedido del coordinador** (fuente: pedido (texto))

  Corregir los hallazgos 2 (timeouts de base, health check real), 3 (recordatorios con Render dormido), 4 (backups), 8 (un solo usuario de base migra y atiende la app), 14 (id de referencia del error, mensaje con Render dormido), 15 (observabilidad, captura de errores de la app, log doble, arranque sin base) y 26 (fuente única de versión, .env según el cwd) siguiendo el kit, sobre la rama de REV-01 (que ya agregó GET /health). Archivos principales: main.py, db.py, registro_errores.py, render.yaml, lib/main.dart, lib/comun/dialogo_error.dart. El plan pago de Render lo decide una persona: mientras tanto, la opción más barata de deshacer, declarada.

  **Enunciado** (fuente: enunciado, Trabajo Práctico_2026.docx.pdf, pdftotext -enc UTF-8 -layout, texto entero)

                               Universidad de Morón - Docente: Marcelo Camicha

               ELECTIVA GENERAL
                   Trabajo Práctico

    Gestión de espacios deportivos

    Desarrollar una aplicación móvil para la gestión de espacios deportivos

    La aplicación permitirá:
        ● que los usuarios reserven espacios deportivos desde sus celulares
        ● consultar disponibilidad de espacios deportivos de diferentes sedes
        ● recibir notificaciones push sobre reservas próximas.

    El sistema deberá incluir tanto el desarrollo de APIs para la gestión de reservas, sedes,
    espacios deportivos y perfiles de usuarios, como el desarrollo de la aplicación móvil en
    Flutter.

    Requerimientos Funcionales

    1. Registración, inicio de sesión y recuperación de contraseña
        ● Registro de usuarios mediante correo electrónico y contraseña.
        ● Una vez iniciada la sesión, la aplicación deberá mostrar una página inicial (Home

             Page).
        ● Los usuarios que olviden su contraseña deberán disponer de un mecanismo seguro

             para recuperarla o establecer una nueva contraseña.

    2. Perfil de usuario:
        ● Se deben mostrar todos los datos del perfil de usuario y permitir su edición, salvo la

             dirección de correo electrónico.

        ● El perfil deberá incluir, como mínimo, nombre, apellido y fecha de nacimiento.
        ● Se deberá poder cerrar la sesión.

    3. Gestión de reservas
        ● Los horarios disponibles para las reservas deberán estar comprendidos dentro de
             los horarios de funcionamiento de la sede correspondiente.

        ● Una reserva corresponde a un espacio deportivo, una fecha, una hora de inicio y una
             hora de finalización.

        ● La duración mínima de una reserva será de una hora. Los horarios de inicio y
             finalización deberán corresponder a horas completas, es decir, deberán comenzar y
             finalizar en el minuto 00. Por ejemplo: 18:00 a 19:00, 18:00 a 20:00, etc.

                                                                                                                              1
                              Universidad de Morón - Docente: Marcelo Camicha

        ● La hora de finalización de una reserva no podrá superar el horario de cierre de la
             sede.

        ● Las reservas deberán realizarse para horarios futuros respecto del momento en que
             se efectúa la reserva.

        ● Al reservar un espacio deportivo para una fecha y horario determinados, dicho
             espacio no podrá ser reservado por otro usuario para la misma fecha si existe
             superposición de horarios. El backend deberá validar la disponibilidad del espacio
             deportivo antes de registrar una reserva.

        ● Se deberá:
                  ○ Poder consultar la disponibilidad de espacios deportivos según la sede.
                  ○ Reservar un espacio deportivo para una fecha y horario determinados.
                  ○ Listar las reservas realizadas por el usuario, indicando sede, espacio
                       deportivo, fecha y horario.
                  ○ Cancelar una reserva. Al cancelar una reserva, el espacio deportivo deberá
                       volver a estar disponible para ese mismo horario.
                  ○ Recibir notificaciones push sobre reservas próximas.

    4. Módulo de Sedes
        ● Cada sede deberá contar, como mínimo, con un nombre, una dirección y horarios de
             funcionamiento.

        ● Mostrar el listado de sedes, sus horarios de funcionamiento y permitir seleccionar
             una sede para consultar sus espacios deportivos y horarios disponibles.

    5. Módulo de Espacios deportivos
        ● Mostrar el listado de espacios deportivos indicando la sede donde se ubica cada
             uno.

        ● Cada espacio deportivo deberá estar asociado a una sede y contar, como mínimo,
             con un tipo y un nombre compuesto por la sede, dirección, tipo de espacio deportivo
             y un número. Por ejemplo: Moron_Rivadavia_19850_Paddle_1.

        ● Permitir filtrar los espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.).

    6. Historial de reservas
        ● Acceder al historial de reservas realizadas, incluyendo las reservas cuyo horario ya
             haya finalizado.

    7. Manejo de errores
        ● Se debe poder manejar los errores que puedan surgir durante el uso de la
             aplicación. Por ejemplo sin conexión a internet, servidor caído, login incorrecto,
             usuario ya registrado, etc.

                                                                                                                             2
                               Universidad de Morón - Docente: Marcelo Camicha

    8. Nombre de la aplicación
        ● El nombre de la aplicación debe ser Club [Nombre y Apellido del alumno o alumna].
             Por ejemplo: ClubJuanaGonzalez.

    9. Nombre del repositorio GITHUB
        ● El nombre del repositorio de GitHub deberá coincidir con el nombre de la aplicación.
             Por ejemplo: ClubJuanaGonzalez.

    Requerimientos No Funcionales

    1. Aplicación móvil
        ● El diseño de UX/UI se deberá realizar utilizando Figma
        ● La aplicación móvil se deberá realizar utilizando Flutter
    2. Repositorio
        ● El proyecto deberá gestionarse mediante un repositorio GitHub.
        ● Cada alumno deberá utilizar su propia cuenta de GitHub y realizar commits durante

             el desarrollo del proyecto.

        ● El historial del repositorio podrá ser considerado como parte del proceso de

             evaluación.
    3. REST API:
        ● La API REST deberá estar documentada mediante Swagger/OpenAPI.
        ● Se podrá elegir el lenguaje que se desee. (Preferentemente Python)
    4. BBDD:
        ● Se podrá elegir cualquier base de datos relacional. (Preferentemente PostgreSQL)
    5. Cloud
        ● La API REST y la base de datos deberán estar disponibles en la nube.
        ● Se podrán utilizar servicios como Render para el despliegue de la API y base de

             datos, y Firebase para autenticación y notificaciones push.

        ● Las operaciones de la API relacionadas con usuarios y reservas deberán identificar

             al usuario autenticado.

                                                                                                                              3
                               Universidad de Morón - Docente: Marcelo Camicha

    6. Readme
        ● Tanto la aplicación móvil como el backend deberán contar con un archivo README
             que explique todos los pasos necesarios para configurar, ejecutar y, cuando
             corresponda, desplegar cada proyecto.

    Entregables para evaluación

    1. Entrega 1 (Diseño)
        ● Mockup y prototipo navegable desarrollado en Figma.
        ● La Entrega 1 será presentada y defendida grupalmente.
        ● Cada alumno deberá subir a Blackboard la documentación que se indicará luego de
             la presentación.

    2. Entrega 2 (Desarrollo y Modelo)
        ● Backend desplegado en la nube y aplicación móvil conectada a la API REST.
        ● Aplicación móvil en Flutter
        ● Icono
        ● Inicio de sesión, registración y recuperación de contraseña
        ● Gestión de reservas
        ● Modelo de datos de la aplicación, incluyendo entidades, atributos y relaciones.
        ● Manejo de errores (sin conexión a internet, servidor caído, login incorrecto, usuario
             ya registrado, etc.)
        ● Mostrar aplicación funcionando en emulador.
        ● Subir a la plataforma Blackboard, antes de la exposición, el código del backend (ZIP)
          y el código de la aplicación móvil (ZIP).
        ● La Entrega 2 será individual y deberá ser defendida individualmente. Cada alumno
             deberá demostrar conocimiento del funcionamiento general de su aplicación y de las
             decisiones de diseño e implementación adoptadas.

                                                                                                                              4

  **CU-24.1 · Recibir notificación recordatoria de reserva próxima** (fuente: CU-nuevos/CU-24.1 - Notificacion recordatoria.md, texto entero)

    # CU-24.1 · Recibir notificación recordatoria de reserva próxima

    **Módulo:** Notificaciones · **Actor principal:** Usuario registrado · **Actor secundario:** el sistema, que la dispara sola
    **Alumnos asignados:** Nahuel Alejandro Mlakar y Jerónimo Zarlenga
    **Estado:** estaba diseñado en el Figma grupal (6 pantallas `P-24.1-*`) pero no tenía especificación escrita.

    ## Por qué CU-24 se separa en tres
    La lista de casos de uso define el CU-24 como genérico, con la nota *"separar en 3 si resulta necesario: notif. recordatoria, notif. de cancelación forzosa y notificar cancelación de reserva"*. **Resulta necesario**, porque son tres notificaciones con disparador, emisor y momento distintos:

    | | Quién la dispara | Cuándo | Tono |
    |---|---|---|---|
    | **24.1** Recordatoria | el sistema, solo | una hora antes de la reserva | informativo |
    | **24.2** Cancelación forzosa | el club (CU-15, CU-19, CU-23) | cuando el admin actúa | alerta |
    | **24.3** Confirmación de cancelación | el propio usuario (CU-10) | inmediatamente | confirmación |

    Tratarlas como una sola llevaría a un componente que dice tres cosas distintas con el mismo color y el mismo icono.

    ## Objetivo
    Avisar al usuario, una hora antes, que tiene una reserva próxima, para que no la olvide y para reducir las canchas que quedan vacías.

    ## Problema que resuelve
    El enunciado lo pide de forma explícita (Requerimientos Funcionales, punto 3: "Recibir notificaciones push sobre reservas próximas"). Para el club, una reserva olvidada es una cancha ocupada que nadie usa.

    ## Precondiciones
    - El usuario tiene una reserva en estado Activa con horario futuro.
    - El usuario concedió el permiso de notificaciones del sistema operativo.
    - El dispositivo tiene un token de notificaciones registrado en el backend.

    ## Postcondiciones
    - La notificación queda registrada como enviada y aparece en el centro de notificaciones de la app.
    - No cambia el estado de la reserva: es solo un aviso.

    ## Regla de disparo
    Se envía **una sola vez, una hora antes del inicio**. Si la reserva se cancela o se modifica antes de ese momento, el recordatorio pendiente se descarta o se reprograma con el horario nuevo.

    ## Flujo principal

    | # | Acción | Respuesta del sistema |
    |---|---|---|
    | 1 | — | Una hora antes del inicio, el backend dispara la notificación al dispositivo del usuario. |
    | 2 | El usuario ve el aviso en la pantalla bloqueada o sobre la app. | Muestra el deporte, la sede y el rango horario. |
    | 3 | Toca la notificación. | Abre la app en "Mis reservas", con la reserva correspondiente a la vista. |

    ## Flujos alternativos
    - **FA1 · La app está abierta** (origen paso 2). El aviso se muestra como una tarjeta en la parte superior, sin salir de la pantalla en la que está el usuario.
    - **FA2 · El usuario no concedió el permiso** (origen paso 1). No se envía nada. El centro de notificaciones de la app muestra el estado "Notificaciones desactivadas" con la acción para activarlas.
    - **FA3 · El usuario ignora la notificación** (origen paso 2). Queda en el centro de notificaciones marcada como no leída.
    - **FA4 · La reserva se canceló o se modificó** (origen paso 1). El recordatorio pendiente se descarta, o se reprograma con el horario nuevo si la reserva se modificó (CU-11).
    - **FA5 · El dispositivo está sin conexión** (origen paso 1). El servicio de notificaciones reintenta según su propia política. Es un comportamiento del sistema operativo, no de la app.

    ## Pantallas
    `CU-24.1 · Pantalla bloqueada (contexto del sistema)` · `CU-24.1 · Push recordatoria (en la app)` · `CU-24 · Centro de notificaciones` · `CU-24 · Notificaciones desactivadas` · `CU-24 · Notificaciones in-app (overlay)`

    ## Componentes
    `Push-Notification` en la variante Recordatoria (icono de reloj, acento lima) · `Empty-State` para el caso sin permiso · `AppBar`.

    ## Mensajes
    - Título: "Tu reserva es en 1 hora"
    - Cuerpo: "Fútbol 5 · Sede Morón · 21:00 – 22:00"

  **Snapshot de TP-07, sección de la card** (fuente: TP-07 specs/TP-07-manejo-de-errores/card.snapshot.md, sección «## Card, tal como está escrita», líneas 22-44; el encabezado de esa sección está en español en el archivo fuente)

    ## Card, tal como está escrita

    **Requerimiento funcional 7** (fuente: enunciado)
    > «Se debe poder manejar los errores que puedan surgir durante el uso de la aplicación. Por ejemplo
    > sin conexión a internet, servidor caído, login incorrecto, usuario ya registrado, etc.»

    **Entrega 2** (fuente: enunciado)
    > «Manejo de errores (sin conexión a internet, servidor caído, login incorrecto, usuario
    > ya registrado, etc.)»

    **Pantallas compartidas del prototipo** (fuente: Figma)
    - Error de conexión: «No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.» ·
      REINTENTAR · Volver.
    - Error del servidor: «No pudimos procesar la operación en este momento. Intentá más tarde.» ·
      ACEPTAR.
    - Sesión expirada: «Tu sesión expiró · Por seguridad cerramos tu sesión. Volvé a iniciar sesión para
      continuar.» · IR AL INICIO DE SESIÓN.
    - Acceso denegado: «Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.» · IR A
      MIS RESERVAS.
    - Algo cambió: «Esto cambió mientras tanto · Otra persona modificó estos datos mientras los estabas
      viendo. Los actualizamos para que veas el estado real.» · VER LO ACTUALIZADO.
    - Login incorrecto: «No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.» (CU-01).
    - Usuario ya registrado: «El usuario ya está registrado. Modificá el correo o el DNI.» (CU-03).
- L2 · 2026-10-22 · kit updated d7c92c83fa055a140ca5dca9c16c1899c6d45191 → 6b982a3b4efec0cc0a103964973e3e9a074c6422 · kit 5.0.1: context-cap blocked the main thread after /compact
- L3 · 2026-10-22 · declared · S9, S10, S15 · los dos textos entre «» son los mensajes de la app de ASM-06, no miembros de «cada pedido», «cada error» ni «cualquier carpeta»; S9 lo mide además `--common-headers "X-Request-ID"` en cada respuesta de `attacks:`
- L4 · 2026-10-22 · declared · fault-db · la base es Postgres y `--fault-db` sólo daña un archivo SQLite; la base caída la cubren los tests de S1, S2 y S12
- L5 · 2026-10-22 · los tests de esta card se escriben a partir de los borradores de D:/Temp/w/borradores/rev02/, con los títulos de `## Tasks`. `app:` y `attacks:` usan D:/Temp/w/herramientas/api-app.sh y api-attacks.sh: base propia `club_rev02_app` migrada, admin sembrado y su token del emulador de Auth; el gate corre con `TEST_DATABASE_URL=…/club_rev02_test` y `FIREBASE_AUTH_EMULATOR_HOST` en el entorno
- L6 · 2026-10-22 · declared · mutate · de T4 se mutan el cliente, el diálogo de error y el registro de errores no manejados, donde vive el comportamiento; main.dart, sesion.dart, centro.dart y las tres pantallas sólo pasan sus errores a esos tres, y mutarlas con `flutter test` cuesta minutos por mutante sin medir otra cosa
- L7 · 2026-10-22 · judge ACT-01 a ACT-08, ACT-11 y ACT-12 · se cierran con REV-02-ASM-11 a ASM-18 y los tests nuevos de T1, T2 y T4
- L8 · 2026-10-22 · declared · ACT-09 · OUT · RPO/RTO, dónde queda la copia, inventario y retención de datos personales y la Ley 25.326: el pedido acota el hallazgo 4 a las copias, y cada cuánto se respalda depende del plan pago (REV-02-AMB-01), que decide una persona
- L9 · 2026-10-22 · declared · ACT-10 · OUT · `traceparent`, SLOs y alertas: el club no tiene dónde mandar trazas (ASM-08) ni a quién alertar; REV-07 escribe los objetivos de servicio como meta sin medir
- L10 · 2026-10-22 · kit updated 6b982a3b4efec0cc0a103964973e3e9a074c6422 → 0a8f6431dd7b130c87980f69f9122b45794f6b70 · kit 6.0.0: nested test folders need no layer
- L11 · 2026-10-22 · kit updated 0a8f6431dd7b130c87980f69f9122b45794f6b70 → 1117da7bd97604f13460f467d8a02afaeb6d299a · kit 6.0.0: nested test folders need no layer
- L12 · 2026-10-22 · T1 · pytest tests/escenarios/test_operacion.py -k "inalcanzable or 10_s or pool or bloqueo or disponibilidad or despliegue or sin_base or sin_el_esquema": 9 passed (S1 x4, S2 x2, S12 x3), 162 s; ASM-03 y ASM-18 cubiertos. render.yaml healthCheckPath pasa de /docs a /ready: contradice el test de REV-01 (ASM-03). test_requisitos_no_funcionales: `/health` y `/ready` sin sesión rompen "toda operación sin usuario se rechaza" (PUBLICAS es de REV-01 grupo 2) y el README sin DATABASE_URL_APP/METRICAS_TOKEN/VERSION/DETRAS_DE_PROXY es de T3.
- L13 · 2026-10-22 · kit updated 1117da7bd97604f13460f467d8a02afaeb6d299a → 9e4b31bfe1ca75be41e8fbcf6ec1196c5c3b545a · kit 6.0.1: passed with replaced reads flutter test
- L14 · 2026-10-22 · T2 · `pytest tests/escenarios/test_operacion.py -k "referencia or correlacion or 500 or openapi or registro_sale or log_json or metricas or version or configuracion"` (TEST_DATABASE_URL a club_rev02_test): 19 passed, 113 s (S7, S9, S10, S13, S14, S15; ASM-05/07/08/09/10/14/15/16/17). test_registro_de_errores* pasan. Los handlers 503 pasan de DBAPIError a OperationalError/InterfaceError/TimeoutError para que un SQL mal armado siga en 500 (test TP-07 `test_el_error_de_la_base_no_deja_datos_personales...`). El código se escribió antes de correr los tests, sin observar el rojo previo. Con la máquina cargada `mas_de_10_s` dio 16,7 s en la corrida larga y pasa solo (33 s).
- L15 · 2026-10-22 · replaces: apps/api/tests/escenarios/test_operacion.py "test_los_recordatorios_salen_con_un_comando_fuera_del_servicio_web" · el dato de prueba rompe el check de sede (cierre 23:59 no es hora en punto) · by: apps/api/tests/escenarios/test_operacion_barrido.py "test_los_recordatorios_salen_con_un_comando_fuera_del_servicio_web"
- L16 · 2026-10-22 · replaces: apps/api/tests/escenarios/test_operacion.py "test_un_aviso_que_no_salio_queda_a_la_vista" · el tipo cancelacion_usuario exige reserva (check) y no hay usuario si corre solo · by: apps/api/tests/escenarios/test_operacion_aviso_sin_enviar.py "test_un_aviso_que_no_salio_queda_a_la_vista" (test_operacion_aviso.py, mío y también inválido por no crear usuario, queda superado)
- L17 · 2026-10-22 · T3 · pytest test_operacion_barrido + test_operacion_aviso_sin_enviar + respaldo + usuario_de_la_app: 4 passed (S3, S4, S5, S6; ASM-01/02/04). S5 corrió con RESPALDO_PREFIJO="docker exec -i rg-clubnahuelmosse-postgres-test" RESPALDO_HOST_INTERNO=127.0.0.1:5432 porque pg_dump/pg_restore no existen en esta máquina; sin esas variables el script sale con error claro (could not run). README del backend: test_el_readme_del_backend... passed. Fuera de T3: ruff/mypy de T2 (metricas.py:43, registro_errores.py:108, main.py:1 y :49, mypy metricas.py:42 y registro_errores.py:54).
- L18 · 2026-10-22 · kit updated 9e4b31bfe1ca75be41e8fbcf6ec1196c5c3b545a → 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 · kit 6.1.0: no-visual for a code file with markup
- L19 · 2026-10-22 · replaces: apps/mobile/test/operacion_app_test.dart (los 15 tests) · no compilaba (faltaban imports de PantallaInicio, Reservas, Sedes); además el de ASM-11 usaba montarUsuario, cuyo pumpAndSettle deja correr los 40 s antes del aviso; el del inicio buscaba CANCELAR RESERVA sin la tarjeta (es CANCELAR primero), no cerraba el aviso de error y codificaba el cuerpo en latin1 · by: apps/mobile/test/operacion_registro_test.dart (mismos 15 títulos; el del inicio "…tragaba al releer…")
- L20 · 2026-10-22 · OUT · apps/mobile/lib/app.dart monta AvisoDespertando (ASM-11, cambio mínimo) y se suman lib/comun/aviso_despertando.dart y pantalla_error_de_arranque.dart; ServidorSinRespuesta extiende ErrorDelServidor (lo atrapan los handlers existentes, no es SinConexion); errores_compartidos_test.dart y sesion_test.dart (retomar con 503 ahora lanza; se quitó el test de limiteAlRetomar) actualizados al contrato nuevo.
- L21 · 2026-10-22 · T4 · RED: operacion_app_test.dart no compilaba (errores_no_manejados.dart inexistente); GREEN: `flutter test test/operacion_registro_test.dart` 15 passed; `flutter analyze` No issues found; `flutter test` completo sin fallos tras actualizar los dos tests viejos (S7, S8, S11; ASM-06/11/12/13). Archivos de presentación listos para el designer: aviso_despertando.dart, pantalla_error_de_arranque.dart.
- L22 · 2026-10-22 · T4 cambió dos tests sin tag de cards anteriores que pedían lo que ASM-12 deja sin efecto: `sesion_test.dart` «una API que no contesta no traba el arranque ni cierra la sesión» (cortaba a los 3 s) y `errores_compartidos_test.dart` «una API que no responde en el límite se trata como inalcanzable» (ahora es `ServidorSinRespuesta`, un error del servidor). Quedan para la revisión del PR. La card no lleva lente visual: el aviso y la pantalla de error de arranque no pasan por el designer
- L23 · 2026-10-23 · kit updated 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 → 7a91c9699fa944f754191f53f20a024663a607bd · kit 6.1.1: Dart tests, pytest failures, replacements by file, migrated card start
- L24 · 2026-10-23 · kit updated 7a91c9699fa944f754191f53f20a024663a607bd → c3b49d603591e5747683ff5c839f33e26a20502c · kit 6.1.2: Dart in close and required, replaced tests need no lint
- L25 · 2026-10-23 · gate · `node .claude/tools/verify.mjs` (2 vueltas; la 1.ª invalidada porque se corrigió ruff/mypy en cb59b37 durante la corrida): passed app-suite, specs, attacks, layers, migrations; mutate skipped (no exigida en production). failed: lint (B008/I001 solo en tests/escenarios/test_operacion.py, congelado, ya reemplazado); suite (colisión de basename tests/escenarios/test_seguridad_api.py de REV-01 vs tests/integracion/test_seguridad_api.py; el de integración pasa solo, 11 passed); scenarios (3 failed, 29 passed: los 2 reemplazados de L15-L16, que pasan en sus archivos nuevos, más 1 sin identificar); required (K4 clones entre tests de test_operacion*.py y protecciones.py vs registro_errores.py:83-91; linter sobre los 3 archivos de reemplazo). ruff y mypy sobre app/: limpios
- L26 · 2026-10-23 · kit updated c3b49d603591e5747683ff5c839f33e26a20502c → 720d5e70b54968dbbdd1989cc041eb6fa1089c43 · kit 6.2.0: declared K4 for a clone with a frozen test
- L27 · 2026-10-23 · kit updated 720d5e70b54968dbbdd1989cc041eb6fa1089c43 → 1594a34f3e4027e9e7085fad559488f69ae6d96a · kit 6.3.1: kit 3 tags in replaces, no-visual skips design, flutter profile
- L28 · 2026-10-23 · rebase sobre card/REV-01 (fb2bd64) · conflictos de código resueltos conservando ambos comportamientos (salud.py, main.py, protecciones.py con /ready fuera del filtro de Host, registro_errores.py, cliente_api.dart, dialogo_error.dart, render.yaml con /ready); openapi.json regenerado; API 589 pasaron y 12 fallaron en la corrida completa, 4 de ellos (tiempos y ReadTimeout) pasan solos (14 passed); app 430 pasaron (corrida registrada de once.mjs); pg_dump no está en esta máquina; los 2 CheckViolation son los de L15 y L16, ya reemplazados
- L29 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_requisitos_no_funcionales_con_salud.py "test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza" · /ready y /metrics (404 sin token) tampoco piden sesión (REV-02-ASM-03) · by: apps/api/tests/escenarios/test_operacion_rutas_publicas.py "test_toda_operacion_de_la_api_sin_usuario_autenticado_se_rechaza"
- L30 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_seguridad_api.py "test_el_despliegue_en_render_apaga_la_documentacion_interactiva" · REV-02-ASM-03 pide a Render chequear /ready · by: apps/api/tests/escenarios/test_operacion_rutas_publicas.py "test_el_despliegue_en_render_apaga_la_documentacion_interactiva"
- L31 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_seguridad_entradas_extra.py "test_el_contrato_documenta_el_429_el_400_por_host_y_el_422" · /ready queda fuera del filtro de Host igual que /health, sin 400 documentado · by: apps/api/tests/escenarios/test_operacion_rutas_publicas.py "test_el_contrato_documenta_el_429_el_400_por_host_y_el_422"
- L32 · 2026-10-23 · replaces: apps/api/tests/integracion/test_rutas_protegidas.py "test_cada_ruta_registrada_fuera_de_las_publicas_rechaza_sin_sesion" · /ready y /metrics son públicas · by: apps/api/tests/integracion/test_rutas_protegidas_con_operacion.py "test_cada_ruta_registrada_fuera_de_las_publicas_rechaza_sin_sesion"
- L33 · 2026-10-23 · `attacks:` exige también `Content-Security-Policy` (viene de REV-01) y deja exentas, con su razón, las respuestas de uvicorn a pedidos crudos mal formados, que no pasan por la app y no llevan `X-Request-ID`; `lint:` deja fuera de I001 y B008 a `tests/escenarios/*`, congelados en rojo
