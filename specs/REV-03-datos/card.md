# REV-03 · datos

card: REV-03
status: proposed
cap: 14 h
sources:
  - "specs/REVISION-kit3.md @ 138bc54 (HEAD de card/REV-03): encabezado, lineas 1-5, y hallazgos 10, 11, 12 y 13 completos"
  - "pedido (texto): pedido del coordinador, en el mensaje de encargo de esta congelacion"
  - "enunciado: D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf, pdftotext -enc UTF-8 -layout, texto completo"
  - "CU: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-08 Consultar Historial de Reservas Individual.pdf, pdftotext -layout, texto completo"
  - "CU: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-14_Especificacion_Francisco_Luciano.pdf, pdftotext -layout, texto completo"
  - "CU: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-24.1 - Notificacion recordatoria.md, lectura directa del Markdown"
  - "CU: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-24.2 - Notificacion de cancelacion forzosa.md, lectura directa del Markdown"
not_read:
  - "Jira: la card llega como texto en el pedido; no hay ticket de Jira que leer (sin Jira por instrucción)."
  - "CU-08 (PDF de 8 paginas): 5 imagenes incrustadas (paginas 3 a 7), capturas de pantalla. pdftotext solo extrae texto; las imagenes no se abrieron ni se transcriben."
  - "CU-14 (PDF de 21 paginas): 19 imagenes incrustadas, capturas de pantalla y prototipos. pdftotext solo extrae texto; las imagenes no se abrieron ni se transcriben."
  - "Figma: las pantallas P-01 a P-18 de CU-14 y las de CU-08 se nombran en el texto, pero el diseño en Figma no se consulto."
  - "Enunciado: sin imagenes incrustadas (pdfimages no lista ninguna). Se transcribe el texto tal como sale de pdftotext."
  - "CU citados dentro de los CU leidos y no abiertos (fuera de los CU pedidos): CU-03, CU-10, CU-11, CU-15, CU-19, CU-23 y CU-24 (generico) y CU-24.3, mencionados en CU-24.1 y CU-24.2."
  - "Codigo referenciado en los hallazgos (apps/api/..., apps/mobile/..., migraciones/versions/0004 a 0007, infraestructura/*.py, lib/reservas/*): no se abrio. Se transcribe el hallazgo, no el codigo."
  - "specs/REVISION-kit3.md: el resto del documento (hallazgos 1 a 9 y 14 a 28, costos, que corrio, sin hallazgo, CU sin cubrir) no se transcribe: esta fuera del pedido. Si se lo quiere, se lee en el mismo commit 138bc54."

## Specs

Cada spec cita un escenario de la card tal como está escrito. Un test lleva su tag: `@REV-03-S1`.

- S1 · "el historial propio de reservas se resuelve con un índice por socio, sin recorrer toda la tabla"
- S2 · "el historial propio de reservas se entrega por páginas"
- S3 · "una página avanzada del historial global se resuelve sin recorrer ni contar toda la tabla"
- S4 · "quién canceló una reserva y qué aviso reemplazó a otro se consultan por índice"
- S5 · "un aviso que quedó «enviando» por una caída del proceso se vuelve a enviar"
- S6 · "un recordatorio registrado y no enviado se reintenta"
- S7 · "la migración nueva no bloquea las tablas con datos mientras la versión anterior atiende"
- S8 · "la suite vigila la ida y vuelta de todas las migraciones con datos"
- REV-03-ASM-01 · un marcador que no se lee es 422 con `{"errores": {"despues": "El marcador de página no es válido"}}`; uno válido después del final trae lista vacía y `siguiente: null` · S2
- REV-03-ASM-02 · un aviso de cancelación varado en `enviando` se vuelve a mandar (puede llegar dos veces); un recordatorio varado queda `fallida` y no se repite, por «Se envía una sola vez» de CU-24.1 · S6
- REV-03-ASM-03 · el historial propio trae tandas de 20, igual que el global; una app vieja que no manda `despues` ve las 20 más recientes · S2
- REV-03-ASM-04 · un aviso `enviando` hace más de 5 minutos se da por varado · S5
- REV-03-ASM-05 · cada toma suma un intento; con 3 intentos el aviso queda `fallida` y se registra `aviso_sin_enviar` · S5
- REV-03-ASM-06 · la ida y vuelta de cada migración se prueba con datos en las tablas de 0001; bajar una migración que creó una tabla borra sus datos, y alcanza con que el esquema vuelva y los datos de las otras tablas sigan · S8
- REV-03-ASM-07 · con el mismo inicio, va primero el id más alto (ya era así) · S3
- REV-03-ASM-08 · una reserva que entra mientras alguien recorre el historial no aparece en las tandas que ya vio; aparece al volver a abrirlo · S2
- REV-03-ASM-09 · de cada intento queda `tomada_en` e `intentos`; el detalle del error va al log, no a la base · S5
- REV-03-ASM-10 · el total y los contadores del historial global siguen exactos (CU-14), contados en una sola consulta en vez de dos · S3
- REV-03-ASM-11 · el historial global acepta `despues` y sigue aceptando `pagina` para las apps ya instaladas; con los dos, manda `despues` · S3
- REV-03-ASM-12 · el total y los contadores exactos de ASM-10 mandan sobre «sin contar toda la tabla» de S3: se cuentan con el índice del filtro, sin tope; lo que S3 asegura es que la página avanzada no recorre las filas anteriores · S3
- REV-03-ASM-13 · el historial propio desempata como el global: con el mismo inicio, va primero el id más alto · S2
- REV-03-ASM-14 · un recordatorio cuya reserva ya empezó no se reintenta: queda `fallida` · S6
- REV-03-ASM-15 · la migración 0008 fija `lock_timeout` y corta si espera un lock detrás de una transacción larga; volver a correrla es de quien despliega · S7
- REV-03-ASM-16 · sólo el historial (`cuando=historial`) llega por tandas; las próximas reservas siguen llegando enteras · S2
- REV-03-ASM-17 · la trazabilidad que lee el admin devuelve el estado `fallida` del aviso, que deja de figurar como pendiente · S5

## Tasks

- T1 · S7,S8 · apps/api/migraciones/versions/0008_indices_y_cola_recuperable.py (data), apps/api/migraciones/env.py (data), apps/api/pyproject.toml (data: ignora F811 en los escenarios de datos, que importan fixtures) · tests: apps/api/tests/escenarios/test_datos.py "la migración nueva no bloquea las tablas mientras la versión anterior atiende @REV-03-S7"; apps/api/tests/escenarios/test_datos.py "la suite vigila la ida y vuelta de las migraciones con datos @REV-03-S8 @assumption:REV-03-ASM-06"; apps/api/tests/escenarios/test_datos.py "la migración 0008 corta por lock_timeout si una transacción larga tiene la tabla @REV-03-S7 @assumption:REV-03-ASM-15"
- T2 · S1,S2,S3,S4 · apps/api/app/interfaz/marcador.py (rule), apps/api/app/infraestructura/reservas.py (data), apps/api/app/interfaz/reservas.py (presentation), apps/api/app/aplicacion/reservas.py (rule), apps/api/app/dominio/reservas.py (rule) · tests: apps/api/tests/escenarios/test_datos.py "el historial propio se resuelve con un índice por socio @REV-03-S1"; apps/api/tests/escenarios/test_datos.py "el historial propio de reservas se entrega por páginas @REV-03-S2"; apps/api/tests/escenarios/test_datos.py "un marcador de página inválido se rechaza @REV-03-S2 @assumption:REV-03-ASM-01"; apps/api/tests/escenarios/test_datos.py "un marcador inválido del historial global se rechaza @REV-03-S3 @assumption:REV-03-ASM-01"; apps/api/tests/escenarios/test_datos.py "una página avanzada del historial global se resuelve por marcador @REV-03-S3"; apps/api/tests/escenarios/test_datos.py "el historial global sigue aceptando la página de las apps instaladas @REV-03-S3 @assumption:REV-03-ASM-11"; apps/api/tests/escenarios/test_datos.py "el historial global se ordena por un índice de inicio @REV-03-S3"; apps/api/tests/escenarios/test_datos.py "quién canceló y qué aviso reemplazó a otro se consultan por índice @REV-03-S4"; apps/api/tests/escenarios/test_datos.py "el historial propio trae tandas de 20 y sin marcador las 20 más recientes @REV-03-S2 @assumption:REV-03-ASM-03"; apps/api/tests/escenarios/test_datos.py "con el mismo inicio va primero el id más alto @REV-03-S3 @assumption:REV-03-ASM-07"; apps/api/tests/escenarios/test_datos.py "una reserva nueva no aparece en las tandas ya vistas y sí al volver a abrir el historial @REV-03-S2 @assumption:REV-03-ASM-08"; apps/api/tests/escenarios/test_datos.py "el total y los contadores del historial global siguen exactos, como pide CU-14, en una sola consulta @REV-03-S3 @assumption:REV-03-ASM-10"; apps/api/tests/escenarios/test_datos.py "la página avanzada del historial global no recorre las filas anteriores y el total se cuenta con índice @REV-03-S3 @assumption:REV-03-ASM-12"; apps/api/tests/escenarios/test_datos.py "en el historial propio, con el mismo inicio va primero el id más alto y ninguna tanda saltea ni repite @REV-03-S2 @assumption:REV-03-ASM-13"; apps/api/tests/escenarios/test_datos.py "un marcador armado a mano o tomado del historial global sólo trae reservas propias @REV-03-S2 @assumption:REV-03-ASM-01"; apps/api/tests/escenarios/test_datos.py "las próximas reservas siguen llegando enteras, sin tandas @REV-03-S2 @assumption:REV-03-ASM-16"; apps/api/tests/escenarios/test_datos.py "el OpenAPI documenta despues, siguiente y el 422 del marcador @REV-03-S2 @assumption:REV-03-ASM-01"
- T3 · S5,S6 · apps/api/app/dominio/notificaciones.py (rule), apps/api/app/infraestructura/notificaciones.py (data), apps/api/app/aplicacion/notificaciones.py (rule) · tests: apps/api/tests/escenarios/test_datos.py "un aviso que quedó enviando por una caída se vuelve a enviar @REV-03-S5 @assumption:REV-03-ASM-04"; apps/api/tests/escenarios/test_datos.py "un aviso tomado hace un momento no se vuelve a tomar @REV-03-S5 @assumption:REV-03-ASM-04"; apps/api/tests/escenarios/test_datos.py "el aviso que agotó sus intentos queda fallido @REV-03-S5 @assumption:REV-03-ASM-05"; apps/api/tests/unit/test_despacho_de_confirmaciones.py "el aviso perdido se ve en el log como `aviso_sin_enviar` @REV-03-S5"; apps/api/tests/escenarios/test_datos.py "un recordatorio registrado y no enviado se reintenta @REV-03-S6"; apps/api/tests/escenarios/test_datos.py "el recordatorio pendiente de una reserva ya cancelada no se manda @REV-03-S6"; apps/api/tests/escenarios/test_datos.py "el recordatorio varado queda fallido: se envía una sola vez @REV-03-S6 @assumption:REV-03-ASM-02"; apps/api/tests/escenarios/test_datos.py "de cada intento quedan tomada_en e intentos y el error va al log, no a la base @REV-03-S5 @assumption:REV-03-ASM-09"; apps/api/tests/escenarios/test_datos.py "la línea aviso_sin_enviar no lleva el token, el correo ni el cuerpo del aviso @REV-03-S5 @assumption:REV-03-ASM-09"; apps/api/tests/escenarios/test_datos.py "el recordatorio de una reserva que ya empezó no se reintenta y queda fallido @REV-03-S6 @assumption:REV-03-ASM-14"; apps/api/tests/escenarios/test_datos.py "una confirmación de cancelación que quedó enviando se vuelve a enviar @REV-03-S5 @assumption:REV-03-ASM-04"; apps/api/tests/escenarios/test_datos.py "la trazabilidad del admin muestra el aviso fallido como fallido, no como pendiente @REV-03-S5 @assumption:REV-03-ASM-17"
- T4 · S2,S3 · apps/mobile/lib/reservas/reservas.dart (presentation), apps/mobile/lib/reservas/pantalla_mis_reservas.dart (presentation), apps/mobile/lib/admin/historial_reservas.dart (presentation) · tests: apps/mobile/test/historial_por_tandas_test.dart "el historial propio trae la tanda siguiente al llegar al final @REV-03-S2"; apps/mobile/test/historial_por_tandas_test.dart "el historial global del admin trae la tanda siguiente y conserva la posición @REV-03-S3"

## Changes to existing behavior

- README: `apps/api/README.md` suma ASM-02 a ASM-05 y ASM-11
- ASVS: unchanged — la card no toca seguridad
- `GET /reservas` deja de devolver todo el historial: trae 20 y `siguiente`
- `GET /reservas/todas` suma `despues` y `siguiente`; `pagina` sigue
- Un aviso varado en `enviando` se retoma o queda `fallida`; antes quedaba para siempre
- Un recordatorio registrado y no enviado se manda en el barrido siguiente
- Nuevo: migración 0008 con cuatro índices y dos columnas de `notificacion`
- Lo demás queda igual: permisos, orden y forma de cada reserva

## Gate

```
suite: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider --ignore-glob=tests/escenarios/test_datos*
lint: sh D:/Temp/w/herramientas/ruff-mypy-api-rev03.sh apps/api/app apps/api/migraciones apps/api/tests apps/mobile/test
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider tests/escenarios --card REV-03
migrate-upgrade: sh D:/Temp/w/herramientas/pytest-api.sh -q -p no:cacheprovider tests/escenarios/test_datos_migraciones.py
mutate apps/api/app/dominio/reservas.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/unit tests/escenarios/test_datos.py tests/integracion/test_historial_api.py --deselect tests/escenarios/test_datos.py::test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo --deselect tests/escenarios/test_datos.py::test_cada_migracion_va_y_vuelve_con_datos
mutate apps/api/app/infraestructura/reservas.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/escenarios/test_datos.py tests/escenarios/test_datos_tanda_justa.py tests/escenarios/test_datos_tanda_justa_propia.py tests/escenarios/test_historial_reservas.py tests/integracion/test_historial_api.py --deselect tests/escenarios/test_datos.py::test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo --deselect tests/escenarios/test_datos.py::test_cada_migracion_va_y_vuelve_con_datos
mutate apps/api/app/infraestructura/notificaciones.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/escenarios/test_datos.py tests/escenarios/test_despacho_robusto.py tests/unit/test_despacho_de_confirmaciones.py --deselect tests/escenarios/test_datos.py::test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo --deselect tests/escenarios/test_datos.py::test_cada_migracion_va_y_vuelve_con_datos
mutate apps/api/app/aplicacion/notificaciones.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/escenarios/test_datos.py tests/unit/test_despacho_de_confirmaciones.py --deselect tests/escenarios/test_datos.py::test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo --deselect tests/escenarios/test_datos.py::test_cada_migracion_va_y_vuelve_con_datos
mutate apps/api/app/dominio/notificaciones.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/unit
mutate apps/api/app/interfaz/marcador.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/unit/test_marcador.py
mutate apps/api/app/interfaz/reservas.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/escenarios/test_datos.py tests/integracion/test_historial_api.py --deselect tests/escenarios/test_datos.py::test_la_migracion_nueva_no_se_queda_esperando_un_bloqueo --deselect tests/escenarios/test_datos.py::test_cada_migracion_va_y_vuelve_con_datos
mutate apps/api/migraciones/versions/0008_indices_y_cola_recuperable.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/escenarios/test_datos_migraciones.py tests/escenarios/test_datos_migraciones_lock.py
mutate apps/api/migraciones/env.py: sh D:/Temp/w/herramientas/pytest-unit.sh -q -x tests/escenarios/test_datos_migraciones_transacciones.py
mutate apps/mobile/lib/reservas/reservas.dart: sh D:/Temp/w/herramientas/flutter-mobile.sh test/historial_por_tandas_test.dart
mutate apps/mobile/lib/reservas/pantalla_mis_reservas.dart: sh D:/Temp/w/herramientas/flutter-mobile.sh test/historial_por_tandas_test.dart
mutate apps/mobile/lib/admin/historial_reservas.dart: sh D:/Temp/w/herramientas/flutter-mobile.sh test/historial_por_tandas_test.dart
app: sh D:/Temp/w/herramientas/api-app.sh rev03_app
attacks: sh D:/Temp/w/herramientas/api-attacks.sh rev03_app --json --no-ambient --common-headers "Content-Security-Policy" --raw-headers-exempt "uvicorn (h11) responde los pedidos crudos mal formados antes de que lleguen a la app" --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /reservas/todas
```

## Log

- L1 · **Encabezado de `specs/REVISION-kit3.md` @ 138bc54, lineas 1 a 5** (fuente: specs/REVISION-kit3.md @ 138bc54)

```text
# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.
```

**Hallazgos 10 a 13 de `specs/REVISION-kit3.md` @ 138bc54** (fuente: specs/REVISION-kit3.md @ 138bc54, completos)

```text
10. **Consultas que crecen con la tabla** · P9, P11, K10 · falló · medido
    - `reserva.usuario_id` no tiene índice (`migraciones/versions/0001_modelo_inicial.py:151`): con 200 k reservas,
      `GET /reservas?cuando=historial` da Parallel Seq Scan.
    - El historial global pagina con `OFFSET`, hace dos `count(*)` por página y ordena en disco: 1,2 s en la página 500
      (`infraestructura/reservas.py:492-509`). El historial propio no tiene paginación (`:121-137`).
    - Tampoco tienen índice las FK `reserva.cancelada_por` y `notificacion.reemplazada_por`.

11. **La cola de avisos no se recupera** · P13 · falló · lectura
    - `infraestructura/notificaciones.py:228-239`: si el proceso cae entre `tomar_siguiente` y `marcar_envio`, el aviso
      queda en `enviando` para siempre; un recordatorio registrado y no enviado tampoco se reintenta (`:141-142`,
      `:232`).
    - Impacto: la trazabilidad del admin muestra «todavía no salió» indefinidamente.

12. **Se editaron migraciones que ya estaban en main** · P16 · falló · medido sobre git
    - `0007_aviso_de_cancelacion_forzosa.py` entró con 50a4b5a (en main desde 8e64a37) y 9d97cbb la editó después;
      `0001_modelo_inicial.py` entró con 68f6956 y b10fdfa la editó.
    - Impacto: una base que ya aplicó la versión vieja queda con otro esquema. El hook del kit 3.0.0 lo bloquea de acá
      en adelante.

13. **Migraciones no seguras en caliente** · P12, P5 · falló · lectura (ida y vuelta medida)
    - Ninguna tiene `lock_timeout`; los índices sobre tablas con datos se crean sin `CONCURRENTLY` (0004:16, 0005:71,
      0006:27, 0007:41-48), el CHECK de 0006:20-24 va sin `NOT VALID`, y todo corre en una transacción
      (`migraciones/env.py:14-16`) durante el build, con la versión anterior sirviendo.
    - La ida y vuelta 0001↔0007 con datos funciona (medido), pero ningún test la vigila. Los downgrade de 0003, 0005 y
      0007 borran tablas con datos.
```

**Dato del pedido** (fuente: pedido (texto)): el hallazgo 12 no se corrige: editar migraciones de main reescribe la historia; se declara al cierre.

**Pedido del coordinador** (fuente: pedido (texto))

```text
Corregir los hallazgos 10 (índices, paginación del historial global y del propio), 11 (cola de avisos que queda en enviando) y 13 (migraciones seguras en caliente; ida y vuelta en la suite) siguiendo el kit. Migración nueva 0008; infraestructura/{reservas,notificaciones}.py; lib/reservas/*.
```

**Enunciado** (fuente: enunciado, `Trabajo Práctico_2026.docx.pdf`, `pdftotext -enc UTF-8 -layout`, texto completo; se quitaron solo los U+200B, que pdftotext emite tras los bullets)

```text
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
```

**CU-08 · Consultar Historial de Reservas Individual** (fuente: CU/CU-08 Consultar Historial de Reservas Individual.pdf, `pdftotext -layout`, texto completo; las imágenes del PDF no se transcriben: ver not_read)

```text
      ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Ramiro D’Agnone
Matrícula: 54010724
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): Caso de Uso 08 – Consultar Historial de
Reservas Individual

Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Consultar Historial de Reservas Individual
     ● ID / Código: CU-08
     ● Actor(es) Principal(es): Usuario registrado
     ● Objetivo: Permitir al usuario visualizar el historial completo de sus reservas realizadas en la

        plataforma.
     ● ¿Qué problema resuelve?: Brinda acceso a la información histórica de reservas realizadas

        por el usuario, facilitando el seguimiento de actividades realizadas, reservas vigentes y
        canceladas.

Precondiciones y Poscondiciones

Precondiciones

     ● El usuario debe estar autenticado en la plataforma.

Poscondiciones (Estado final del sistema)

     ● El historial de reservas es mostrado al usuario.

Flujo Principal (Camino Feliz)

               Paso         Acción del Actor          Respuesta / Validación del
1                                                                 Sistema
2                    El usuario accede a la sección
3                    "Mis Reservas".                 El sistema valida la sesión y
4                                                    carga la pantalla de próximas
                     Selecciona la opción            reservas.
                     "Historial".
                     Espera la carga de resultados.  El sistema consulta las
                                                     reservas asociadas al usuario.
                     El usuario puede ver sus
                     reservas pasadas.               El sistema muestra el listado
                                                     de reservas ordenadas por
                                                     fecha.

                                                     Fin caso de uso.
Flujos Alternativos y Excepciones

Flujo Alternativo 1: No Existen Reservas Registradas

     ● Paso de origen: Paso 2 del flujo principal.
     ● Condición: El usuario no posee reservas registradas.
     ● Acción del sistema: Muestra el mensaje "No se encontraron reservas asociadas a su cuenta".

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

    • Pantalla 1: [Home]
• Pantalla 2: [Mis Reservas - Próximas]
• Pantalla 3: [Mis Reservas - Historial]
• Pantalla 4: [Mis Reservas - Sin Próximas]
• Pantalla 4: [Mis Reservas – Sin Pasadas]
Componentes del Sistema de Diseño Utilizados

     ● Criterio Unificado:
              ● Botones: Tab-Toggle (Próximas / Historial): botón tipo pestaña con estado activo
                 (fondo verde lima) e inactivo (gris claro).

              ● Tarjetas: Tarjeta con ícono/imagen del deporte, nombre de la sede, código de
                 cancha, fecha y horario, precio, y un Badge-Estado (Activa / Completada).

              ● Mensajes / Feedback: Mensaje centrado en texto bold cuando no hay resultados —
                 "No se encontraron próximas reservas asociadas a su cuenta" / "No se encontraron
                 reservas pasadas asociadas a su cuenta".
```

**CU-14 · Consultar historial global de reservas (Panel de Administración)** (fuente: CU/CU-14_Especificacion_Francisco_Luciano.pdf, `pdftotext -layout`, texto completo; las imágenes del PDF no se transcriben: ver not_read; el orden de las celdas de las tablas del flujo principal es el que entrega pdftotext)

```text
      ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Francisco Luciano
Matrícula: 54010262
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-14: Consultar el historial de todas las
reservas del sistema (Administrador)
Nota: Todos los integrantes del equipo deben utilizar este mismo formato para mantener el criterio
unificado de presentación exigido para la entrega en PDF.

Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Consultar historial global de reservas (Panel de Administración)
     ● ID / Código: CU-14
     ● Actor(es) Principal(es): Administrador del club (usuario autenticado con rol de

        administración). Actor secundario: el sistema de reservas, que provee los datos consultados.
     ● Objetivo: Acceder a la totalidad de las reservas registradas en el sistema de todas las sedes,
        todos los espacios y todos los usuarios, poder filtrarlas y consultar el detalle de cualquiera de
        ellas, para controlar el uso de las instalaciones y responder consultas o reclamos.
     ● ¿Qué problema resuelve?: Un administrador no puede gestionar el club viendo únicamente
        sus propias reservas: la pantalla "Mis reservas" está acotada al usuario que la consulta. Sin
        una vista global no hay forma de saber quién reservó cada espacio, con qué frecuencia se usa
        cada cancha, ni qué pasó con una reserva cancelada. Este caso de uso resuelve necesidades
        concretas del negocio: auditar la actividad del club, resolver reclamos de socios sobre
        reservas puntuales, detectar usos indebidos o cancelaciones reiteradas, y obtener evidencia
        para decidir horarios, precios y mantenimiento. Es principalmente un flujo de consulta y
        auditoría; además, desde la misma vista el administrador puede anular una reserva vigente
        mediante una acción con confirmación, que libera la franja horaria.

Precondiciones y Poscondiciones

Precondiciones

     ● El administrador se encuentra autenticado en la plataforma y su sesión está vigente.
     ● La cuenta posee rol de Administrador, que habilita el permiso de lectura sobre las reservas

        de todos los usuarios y la acción de anular.
     ● Existe al menos una sede cargada y habilitada en el sistema.
     ● Existe al menos una reserva registrada, vigente o histórica, sobre la cual consultar.
     ● La aplicación tiene conexión con la API de reservas.

Poscondiciones (Estado final del sistema)

     ● La consulta del historial no modifica el estado del sistema: no crea ni edita reservas.
     ● Se muestra el listado de reservas de todos los usuarios, agrupado por fecha y ordenado de la

        más reciente a la más antigua, con un contador de resultados.
     ● Los filtros y la búsqueda aplicados quedan visibles en pantalla y pueden limpiarse para

        volver al listado completo.
     ● Si el administrador anula una reserva vigente, esta pasa al estado Cancelada, se libera la
   franja horaria y la anulación queda registrada con su trazabilidad (autor y fecha).

● La operación queda registrada en el log de auditoría del backend (fecha, administrador,
   filtros utilizados y acción realizada).

Flujo Principal (Camino Feliz)

               Paso  Acción del Actor                  Respuesta / Validación del
1                                                                  Sistema
2
3                    Desde el Panel de                 El sistema valida que la sesión
                     Administración, el                tenga rol de Administrador y
4                    administrador entra a la          solicita a la API el historial
5                    pestaña "Reservas".               completo de reservas.
6
7                    Aguarda la respuesta del          El sistema muestra el estado
                     sistema.                          de carga mientras resuelve la
8                                                      consulta, evitando una pantalla
                                                       en blanco.

                     Visualiza el listado de reservas  El sistema despliega las
                     ("Todas").                        reservas de todos los usuarios,
                                                       mostrando en cada tarjeta el
                                                       deporte, la sede, el nombre
                                                       técnico del espacio, el usuario
                                                       que reservó, la franja horaria,
                                                       el precio y el estado de la
                                                       reserva. Encabeza el listado el
                                                       contador total.

                     Usa las pestañas de estado        El sistema filtra el listado por

                     (Todas, Activas, Completadas, el estado elegido y actualiza el

                     Anuladas).                        contador de resultados.

                     Presiona el botón "Filtros".      El sistema despliega el panel
                                                       de filtros con los criterios
                                                       disponibles: buscador por
                                                       texto, sede, deporte, estado y
                                                       rango de fechas.

                     Selecciona los criterios          El sistema valida el rango de
                     deseados y presiona "Aplicar".    fechas, cierra el panel y
                                                       solicita a la API el listado
                                                       filtrado. Muestra una barra de
                                                       filtros activos y la cantidad de
                                                       resultados obtenidos.

                     Escribe el nombre de un           El sistema filtra el listado en
                     usuario, sede o espacio en el     vivo y muestra solo las
                     campo de búsqueda.                reservas que coinciden con el
                                                       texto ingresado, actualizando
                                                       el contador. La búsqueda se
                                                       combina con los filtros que ya
                                                       estuvieran aplicados.

                     Toca una de las reservas del El sistema abre el detalle en
               Paso         Acción del Actor        Respuesta / Validación del
9                    listado.                                   Sistema
10
                     Sobre una reserva vigente,    modo lectura: deporte y
                     presiona "Anular" y confirma  espacio, sede y dirección,
                     la acción.                    usuario, fecha y horario,
                     precio, estado y la trazabilidad
                     Presiona "Volver".            de la reserva (creación y, si
                                                   corresponde, anulación).

                                                   El sistema pide confirmación;
                                                   al confirmar, cambia el estado
                                                   de la reserva a Cancelada,
                                                   libera la franja horaria y
                                                   muestra el detalle con la
                                                   trazabilidad de la anulación
                                                   ("Anulada por el
                                                   administrador").

                                                   El sistema regresa al listado
                                                   conservando los filtros
                                                   aplicados y la posición en la
                                                   que estaba el administrador.

Flujos Alternativos y Excepciones

Flujo Alternativo 1: Sin resultados para los criterios aplicados

     ● Paso de origen: Pasos 6 o 7 del flujo principal.

     ● Condición: La combinación de filtros seleccionada, o el texto buscado, no arroja ninguna
        reserva.

     ● Acción del sistema: El sistema muestra un estado vacío con el mensaje "Sin resultados",
        mantiene visibles los filtros activos para que el administrador entienda por qué no hay
        coincidencias, y ofrece la acción "Limpiar filtros", que restaura el listado completo. El
        mismo estado cubre el caso en que la búsqueda por texto no encuentra coincidencias. Se
        resuelve en la pantalla P-12.

Flujo Alternativo 2: Error de conexión con el servidor

     ● Paso de origen: Pasos 1, 2, 6 o 7 del flujo principal.

     ● Condición: La API no responde, se agota el tiempo de espera o devuelve un error del
        servidor.

     ● Acción del sistema: El sistema muestra una pantalla de error explicando que no se pudo
        cargar el historial, con un botón "Reintentar" que repite la última consulta. No se muestran
        datos parciales ni desactualizados que puedan inducir a error. Se resuelve en la pantalla P-
        14.
Flujo Alternativo 3: Rango de fechas inválido

     ● Paso de origen: Paso 6 del flujo principal.

     ● Condición: La fecha "desde" seleccionada es posterior a la fecha "hasta".

     ● Acción del sistema: El botón "Aplicar" permanece deshabilitado, los campos de fecha se
        marcan en rojo y se muestra un mensaje de error en línea indicando que el rango es inválido.
        No se envía la consulta al servidor. Se resuelve en la pantalla P-15.

Flujo Alternativo 4: Usuario sin rol de Administrador

     ● Paso de origen: Paso 1 del flujo principal.

     ● Condición: La sesión activa corresponde a un usuario sin permisos de administración.

     ● Acción del sistema: La entrada al Panel de Administración no se muestra en la interfaz. Si
        se intenta acceder directamente por enlace profundo, el sistema muestra la pantalla "Acceso
        denegado" y redirige a "Mis reservas". Se resuelve en la pantalla P-16.

Flujo Alternativo 5: Sesión expirada

     ● Paso de origen: Cualquier paso del flujo.

     ● Condición: El token de sesión venció y la API responde con un error de autenticación.

     ● Acción del sistema: El sistema redirige a la pantalla de Login conservando la intención
        previa. Una vez reautenticado, el administrador vuelve al historial con los filtros que tenía
        aplicados.

Flujo Alternativo 6: Historial vacío

     ● Paso de origen: Paso 3 del flujo principal.

     ● Condición: El sistema todavía no tiene ninguna reserva registrada.

     ● Acción del sistema: El sistema muestra un estado vacío diferenciado del anterior, con el
        mensaje "No hay reservas". No se ofrece la acción de limpiar filtros, porque no hay filtros
        aplicados: la lista está vacía en origen. Se resuelve en la pantalla P-17.

Flujo Alternativo 7: El administrador cancela la anulación

     ● Paso de origen: Paso 9 del flujo principal.

     ● Condición: Tras presionar "Anular", el administrador decide no continuar y presiona
        "Cancelar" en el diálogo de confirmación.

     ● Acción del sistema: El sistema cierra el diálogo sin modificar la reserva: el estado y la
        franja horaria se mantienen sin cambios y se regresa a la vista anterior (listado o detalle). La
        confirmación evita anulaciones accidentales sobre reservas ajenas.

Flujo Alternativo 8: Baja del espacio deportivo o de la sede

     ● Paso de origen: Pasos 3, 7 u 8 del flujo principal.

     ● Condición: Un administrador da de baja un espacio deportivo o una sede que tenía reservas
        registradas. La baja se gestiona en un caso de uso a cargo de otro integrante del equipo, de
        modo que este flujo es el punto de integración entre ambos.
     ● Acción del sistema: Las reservas afectadas pasan al estado Cancelada pero permanecen en
        el historial como registro histórico, y la tarjeta indica "Baja del espacio deportivo" en lugar
        de una cancelación del usuario, de modo que no se le atribuye al socio. El historial es un
        registro de auditoría: si las reservas desaparecieran junto con el espacio se perdería la
        trazabilidad. El nombre técnico del espacio se conserva tal como estaba al momento de
        reservar. Se resuelve en la pantalla P-04 (Anuladas).

Justificación de Decisiones de Diseño

              ● Anulación con confirmación y trazabilidad: Anular es la única acción de escritura
                 del caso de uso y recae sobre reservas ajenas, así que exige un diálogo de
                 confirmación para evitar errores. Además, la reserva no se elimina: pasa a Cancelada
                 y el detalle registra quién la anuló y cuándo, en una línea de tiempo. Así el historial
                 sigue siendo auditable.

              ● Dos estados vacíos diferenciados: La pantalla de sin resultados conserva los filtros
                 aplicados y ofrece limpiarlos; la de historial vacío no ofrece esa acción porque no
                 hay filtros que quitar. Si fueran la misma pantalla, el administrador podría interpretar
                 que un sistema sin reservas es un problema de filtros mal puestos.

              ● Validación del rango de fechas antes de consultar: El botón "Aplicar" se
                 deshabilita en lugar de permitir el envío y devolver un error del servidor. El
                 problema se explica junto a los campos que lo causan, se evita una llamada
                 innecesaria a la API y el administrador entiende qué corregir sin cambiar de pantalla.

              ● Identificación del usuario en cada tarjeta: Es la diferencia central con la pantalla
                 "Mis reservas". Sin saber quién reservó, el administrador no puede resolver un
                 reclamo, contactar al socio ni detectar un uso indebido, que son los motivos por los
                 que este caso de uso existe.

              ● Motivo visible en las cancelaciones: Distinguir una cancelación del usuario de una
                 "Baja del espacio deportivo" evita atribuirle al socio una cancelación originada por el
                 club, y es lo que vuelve utilizable el historial ante un reclamo.

              ● La búsqueda se combina con los filtros en lugar de reemplazarlos: Sobre un
                 volumen alto de reservas, buscar a un usuario dentro de un período y una sede ya
                 acotados es una necesidad más frecuente que buscar sobre el histórico completo.

              ● Filtro rápido por estado y filtro avanzado separados: Las pestañas de estado
                 (Todas/Activas/Completadas/Anuladas) resuelven el corte más común en un toque, y
                 el panel de filtros queda para las búsquedas combinadas por sede, deporte, fecha y
                 texto.

              ● Modo día y modo nocturno: Todas las pantallas se entregan en ambos modos,
                 respetando el criterio de sistema de diseño común del equipo, para que el caso de uso
                 se integre sin costuras con el resto de la aplicación.
Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

     ● Pantalla 1: P-01: Panel de Administración — Reservas (Todas). Listado global de todas las
        reservas del sistema, con pestañas de estado, contador, buscador y acceso a filtros.

     ● Pantalla 2: P-02: Reservas — Activas. El listado filtrado por la pestaña de estado "Activas".

     ● Pantalla 3: P-03: Reservas — Completadas. El listado filtrado por la pestaña
        "Completadas".

     ● Pantalla 4: P-04: Reservas — Anuladas. El listado filtrado por la pestaña "Anuladas"
        (incluye las bajas por espacio/sede).

     ● Pantalla 5: P-05: Panel de filtros. Hoja inferior con buscador y criterios de sede, deporte,
        estado y rango de fechas, sobre el listado atenuado.

     ● Pantalla 6: P-06: Filtros — con selección. El panel de filtros con criterios elegidos (sede y
        deporte marcados, rango de fechas cargado).

     ● Pantalla 7: P-07: Resultados filtrados. El listado acotado por los filtros, con la barra de
        filtros activos y el total de coincidencias.

     ● Pantalla 8: P-08: Búsqueda activa. El listado acotado por el texto ingresado en el buscador,
        combinado con los filtros vigentes.

     ● Pantalla 9: P-09: Detalle de reserva. Vista con los datos completos de una reserva puntual y
        su trazabilidad.

     ● Pantalla 10: P-10: Detalle — reserva anulada. La misma reserva luego de anularla: estado
        Cancelada, línea de tiempo de trazabilidad ("Anulada por el administrador") y aviso de que
        se liberó el horario.

     ● Pantalla 11: P-11: Confirmar anulación. Modal de confirmación sobre el listado atenuado,
        antes de anular una reserva vigente.

     ● Pantalla 12: P-12: Sin resultados. Estado vacío cuando los filtros o la búsqueda no arrojan
        coincidencias.

     ● Pantalla 13: P-13: Cargando. Estado de carga mientras se resuelve la consulta.

     ● Pantalla 14: P-14: Error de conexión. Estado de error con la acción de reintentar.

     ● Pantalla 15: P-15: Rango de fechas inválido. Variante del panel de filtros con el error en
        línea y el botón "Aplicar" deshabilitado.

     ● Pantalla 16: P-16: Acceso denegado. Bloqueo a pantalla completa cuando la sesión no tiene
        rol de administrador, con salida hacia "Mis reservas".

     ● Pantalla 17: P-17: Historial vacío. Estado inicial cuando el sistema todavía no registra
        ninguna reserva, diferenciado del estado sin resultados por filtros.

     ● Pantalla 18: P-18: Modo nocturno. Variante del historial según el modo oscuro del sistema
        de diseño del equipo (todas las pantallas se entregan en modo día y modo nocturno).
(A continuación, adjuntar las capturas de pantalla o prototipos exportados desde Figma)
                           P-01: Panel de Administración — Reservas (Todas)

                                            P-02: Reservas — Activas
P-03: Reservas — Completadas
P-04: Reservas — Anuladas
P-05: Panel de filtros
P-06: Filtros — con selección
P-07: Resultados filtrados
P-08: Búsqueda activa
     P-09: Detalle de reserva
P-10: Detalle — reserva anulada
P-11: Confirmar anulación
    P-12: Sin resultados
       P-13: Cargando
    P-14: Error de conexión
P-15: Rango de fechas inválido
P-16: Acceso denegado
            P-17: Historial vacío
P-18: Historial global — modo nocturno
Componentes del Sistema de Diseño Utilizados

     ● Criterio Unificado:
              ● Botones: Btn/Filtros (abre el panel de criterios), Btn/Aplicar y Btn/Limpiar
                 (confirman o restauran la selección), Btn/Anular con su diálogo de confirmación
                 (anulan una reserva vigente), Btn/Reintentar (repite la consulta fallida) y Btn/Volver
   (regresa del detalle al listado). Pestañas de estado (Todas, Activas, Completadas,
   Anuladas) que filtran el listado.

● Campos / Inputs: Campo de búsqueda por usuario, sede o espacio, con estado activo
   cuando contiene texto; chips de selección múltiple para sede, deporte y estado;
   selector de rango de fechas con validación; y grabber de la hoja inferior de filtros.

● Tarjetas: Tarjeta de reserva: emoji del deporte, sede, nombre técnico del espacio en
   tipografía monoespaciada, usuario, franja horaria, precio y chip de estado (Activa,
   Completada o Cancelada). Barra de filtros activos con chips removibles sobre el
   listado. Detalle con línea de tiempo de trazabilidad (creación y, si corresponde,
   anulación por el administrador).

● Mensajes / Feedback: Estado de carga; estado vacío "Sin resultados" y estado
   "Historial vacío" diferenciados; pantalla de error de conexión con acción de
   reintento; y velo oscurecido (scrim) detrás del panel de filtros y del modal de
   confirmación de anulación, que también permite cerrarlos.

● Modos: La aplicación contempla modo claro (día) y modo oscuro (nocturno) para
   todas las pantallas del caso de uso, siguiendo el sistema de diseño común del equipo.

● Navegación: Panel de Administración con tres pestañas —Reservas, Sedes y
   Espacios—. La pestaña Reservas corresponde a este caso de uso; Sedes y Espacios
   pertenecen a casos de uso de otros integrantes del equipo.

● Integración: El punto de contacto con los casos de uso del equipo son las pestañas
   Sedes y Espacios del panel, y la baja de un espacio o sede (a cargo de otro
   integrante), que impacta en las reservas asociadas marcándolas como Cancelada por
   "Baja del espacio deportivo". A su vez, la anulación de una reserva desde este caso
   de uso libera la franja horaria, que vuelve a estar disponible para los casos de uso de
   reserva.

● Prototipo: Las pantallas están conectadas entre sí en Figma, en modo día y modo
   nocturno, con dos puntos de inicio ("Demo — Día" y "Demo — Noche"). Recorrido:
   el listado abre el panel de Filtros; al elegir criterios se pasa a Filtros con selección y,
   al aplicar, a Resultados filtrados; el buscador abre la Búsqueda activa; una tarjeta
   abre el Detalle; desde el listado o el detalle, "Anular" abre la confirmación y, al
   confirmar, se llega al Detalle con la reserva Cancelada y su trazabilidad. Caminos
   alternativos cableados: filtro sin coincidencias (Sin resultados), rango de fechas
   inválido, y los estados de carga y error.
```

**CU-24.1 · Recibir notificación recordatoria de reserva próxima** (fuente: CU-nuevos/CU-24.1 - Notificacion recordatoria.md, lectura directa; las imágenes y el Figma citados no se abrieron)

```text
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
```

**CU-24.2 · Recibir notificación de cancelación forzosa** (fuente: CU-nuevos/CU-24.2 - Notificacion de cancelacion forzosa.md, lectura directa; las imágenes y el Figma citados no se abrieron)

```text
# CU-24.2 · Recibir notificación de cancelación forzosa

**Módulo:** Notificaciones · **Actor principal:** Usuario registrado afectado · **Actor que la origina:** Administrador
**Alumnos asignados:** Nahuel Alejandro Mlakar y Jerónimo Zarlenga
**Estado:** NUEVO. No tenía ni especificación ni diseño. Surge de la nota de la lista de casos de uso ("separar en 3 si resulta necesario") y de que **CU-15 lo exige en su postcondición**: "el sistema solicita el envío de una notificación al usuario afectado".

## Objetivo
Avisarle al usuario que el club dio de baja su reserva por una decisión propia, explicando el motivo, para que no se presente a una cancha que ya no tiene.

## Problema que resuelve
Es la única notificación que el usuario **no puede anticipar**: él no hizo nada, la reserva se cayó por una decisión del club. Sin aviso, el usuario se entera al llegar a la cancha. Por eso lleva el motivo, que es obligatorio en CU-15.

## Disparadores
Son tres, todos del lado del administrador:
1. **CU-15** · el administrador anula una reserva puntual, escribiendo un motivo obligatorio.
2. **CU-19** · el administrador da de baja una sede, y caen todas las reservas futuras de sus espacios.
3. **CU-23** · el administrador da de baja un espacio deportivo, y caen sus reservas futuras.

En los casos 2 y 3 el motivo se genera solo: "Baja del espacio deportivo" o "Baja de la sede", que es la distinción que pide **CU-14 FA8** para que la tarjeta muestre que la cancelación no es atribuible al socio.

## Precondiciones
- Existía una reserva en estado Activa con horario futuro.
- El administrador ejecutó una de las tres acciones anteriores.
- El usuario tiene un token de notificaciones registrado.

## Postcondiciones
- La reserva pasa a estado Cancelada, con la trazabilidad de quién la anuló y cuándo.
- El horario queda liberado.
- La notificación queda registrada y el envío consta en la trazabilidad de la reserva.
- La reserva sigue apareciendo en el historial del usuario, marcada como anulada por el club.

## Flujo principal

| # | Acción | Respuesta del sistema |
|---|---|---|
| 1 | El administrador confirma la anulación en CU-15 (o la baja en CU-19 / CU-23). | Cambia el estado de la reserva a Cancelada y encola la notificación para el usuario afectado. |
| 2 | — | Envía la notificación con el motivo incluido. |
| 3 | El usuario ve el aviso. | Muestra el deporte, la sede, la fecha y el motivo, con el tratamiento visual de alerta. |
| 4 | Toca la notificación. | Abre la app en el historial de reservas, con la reserva anulada y su motivo a la vista. |

## Flujos alternativos
- **FA1 · Una baja afecta a varios usuarios** (origen paso 1, desde CU-19 o CU-23). Se envía una notificación por cada usuario afectado, cada una con los datos de su propia reserva. No se envía un aviso masivo.
- **FA2 · Un mismo usuario tiene varias reservas afectadas** (origen paso 1). Se agrupan en una sola notificación que indica la cantidad, y al tocarla se abre el historial filtrado por anuladas.
- **FA3 · El usuario no concedió el permiso** (origen paso 2). No se envía el push, pero **la notificación igual queda en el centro de notificaciones de la app**, porque esta información el usuario no puede perdérsela.
- **FA4 · El usuario ya había cancelado esa reserva** (origen paso 1). No se envía nada: la reserva ya estaba cancelada por el propio usuario.

## Diferencia con CU-24.3
Las dos hablan de una reserva cancelada, pero no son lo mismo y no se ven igual:
- **24.2** la canceló el club, el usuario no lo esperaba, lleva motivo, usa el color de alerta.
- **24.3** la canceló el propio usuario hace dos segundos, es una confirmación, usa el color de éxito.

## Pantallas
`CU-24.2 · Push cancelación forzosa` · `CU-24 · Centro de notificaciones` · `CU-14 · Panel admin · Detalle · Anulada` (donde consta el envío en la trazabilidad)

## Componentes
`Push-Notification` en la variante Cancelacion-forzosa (icono de triángulo de alerta, tinte rojo) · `Card-Reserva` en estado Anulada con la fila de motivo.

## Mensajes
- Título: "El club anuló tu reserva"
- Cuerpo: "Hockey 7 · Sede Ramos Mejía · Jue 30, 19:00. Motivo: mantenimiento de la cancha."
```
- L2 · 2026-10-22 · kit updated d7c92c83fa055a140ca5dca9c16c1899c6d45191 → 6b982a3b4efec0cc0a103964973e3e9a074c6422 · kit 5.0.1: context-cap blocked the main thread after /compact
- L3 · 2026-10-22 · declared · S8 · «enviando» y «Se envía una sola vez» son textos de S5 y de ASM-02, no miembros de «todas las migraciones»; S8 se prueba con la ida y vuelta de cada migración en un solo test
- L4 · 2026-10-22 · declared · REV-03-ASM-01 · el 422 y el mensaje del marcador los afirma el cuerpo de los dos tests del marcador inválido
- L5 · 2026-10-22 · declared · REV-03-ASM-02 · «24» y «1» vienen de «CU-24.1», el CU citado, no son valores del comportamiento
- L6 · 2026-10-22 · declared · REV-03-ASM-06 · «0001» nombra la migración cuyas tablas se cargan con datos; el test de la ida y vuelta la usa en su cuerpo
- L7 · 2026-10-22 · declared · fault-db · la base es Postgres y `--fault-db` sólo daña un archivo SQLite; la caída de la base la cubren REV-02 (`/ready`) y los tests de la cola
- L8 · 2026-10-22 · `app:` y `attacks:` usan D:/Temp/w/herramientas/api-app.sh y api-attacks.sh: base propia `club_rev03_app` migrada, admin sembrado y su token del emulador de Auth; el gate corre con `TEST_DATABASE_URL=…/club_rev03_test` y `FIREBASE_AUTH_EMULATOR_HOST` en el entorno
- L9 · 2026-10-22 · judge ACT-01 a ACT-08, ACT-10, ACT-11 y ACT-12 · se cierran con REV-03-ASM-12 a ASM-17 y los tests nuevos de T1, T2, T3 y T4
- L10 · 2026-10-22 · declared · ACT-09 · por `pagina` las apps instaladas siguen con OFFSET y la página 500 cuesta lo que costaba; S3 vale para `despues`, el que la app de esta rama manda (ASM-11)
- L11 · 2026-10-22 · declared · REV-03-ASM-12 · «10» y «14» nombran ASM-10 y CU-14, no son valores del comportamiento
- L12 · 2026-10-22 · kit updated 6b982a3b4efec0cc0a103964973e3e9a074c6422 → 0a8f6431dd7b130c87980f69f9122b45794f6b70 · kit 6.0.0: nested test folders need no layer
- L13 · 2026-10-22 · kit updated 0a8f6431dd7b130c87980f69f9122b45794f6b70 → 1117da7bd97604f13460f467d8a02afaeb6d299a · kit 6.0.0: nested test folders need no layer
- L14 · 2026-10-22 · kit updated 1117da7bd97604f13460f467d8a02afaeb6d299a → 9e4b31bfe1ca75be41e8fbcf6ec1196c5c3b545a · kit 6.0.1: passed with replaced reads flutter test
- L15 · 2026-10-22 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "con el mismo inicio va primero el id más alto" · esperaba 21 filas en una sola tanda y la tanda es de 20 · by: apps/api/tests/escenarios/test_datos_reemplazos.py "con el mismo inicio va primero el id más alto"
- L16 · 2026-10-22 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "de cada intento quedan tomada_en e intentos y el error va al log, no a la base" · _cancelar ya despachó una vez: intentos arrancaba en 1 · by: apps/api/tests/escenarios/test_datos_reemplazos.py "de cada intento quedan tomada_en e intentos y el error va al log, no a la base"
- L17 · 2026-10-22 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "el recordatorio de una reserva que ya empezó no se reintenta y queda fallido" · el UPDATE dejaba un inicio que no es hora completa y violaba el CHECK de reserva · by: apps/api/tests/escenarios/test_datos_reemplazos.py "el recordatorio de una reserva que ya empezó no se reintenta y queda fallido"
- L18 · 2026-10-22 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "la trazabilidad del admin muestra el aviso fallido como fallido, no como pendiente" · la cancelación del usuario no deja aviso en la trazabilidad; hace falta la anulación del admin · by: apps/api/tests/escenarios/test_datos_reemplazos.py "la trazabilidad del admin muestra el aviso fallido como fallido, no como pendiente"
- L19 · 2026-10-22 · kit updated 9e4b31bfe1ca75be41e8fbcf6ec1196c5c3b545a → 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 · kit 6.1.0: no-visual for a code file with markup
- L20 · 2026-10-23 · kit updated 7e565f2e177ab0e2a9136d1e4daeb4c62a064ac4 → 7a91c9699fa944f754191f53f20a024663a607bd · kit 6.1.1: Dart tests, pytest failures, replacements by file, migrated card start
- L21 · 2026-10-22 · T1 · gate (/tmp/rev03-gate4.log): mutate 0008 y env.py passed; migrate-upgrade failed con errores de setup bajo carga (8 errors en la fixture de migraciones, 62 s), no de assert
- L22 · 2026-10-22 · T2 · gate: mutate marcador.py e interfaz/reservas.py passed; test_datos_reemplazos.py 4 passed; mutate infraestructura/reservas.py failed (survivor en :156 pese al test de próximas agregado en test_historial_api.py; sin confirmar)
- L23 · 2026-10-22 · T3 · gate: mutate de los tres archivos de notificaciones passed
- L24 · 2026-10-22 · T4 · gate: app-suite passed; mutate de los tres .dart passed
- L25 · 2026-10-22 · gate red · suite y migrate-upgrade con errores de setup bajo carga, scenarios con los 4 tests congelados que fallan (los reemplazos pasan), attacks por foreign Host (25-S2, REV-01); required pide pyproject.toml en Tasks y clones K4 en tests
- L26 · 2026-10-23 · kit updated 7a91c9699fa944f754191f53f20a024663a607bd → c3b49d603591e5747683ff5c839f33e26a20502c · kit 6.1.2: Dart in close and required, replaced tests need no lint
- L27 · 2026-10-23 · kit updated c3b49d603591e5747683ff5c839f33e26a20502c → 720d5e70b54968dbbdd1989cc041eb6fa1089c43 · kit 6.2.0: declared K4 for a clone with a frozen test
- L28 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_datos.py "la migración nueva no bloquea las tablas mientras la versión anterior atiende @REV-03-S7" · la fixture creaba una base de nombre fijo (club_rev03_migraciones_test) y dos corridas a la vez se pisaban (UniqueViolation en el setup) · by: apps/api/tests/escenarios/test_datos_migraciones.py "la migración nueva no bloquea las tablas mientras la versión anterior atiende @REV-03-S7"
- L29 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_datos.py "@REV-03-S8 @assumption:REV-03-ASM-06" · misma base de nombre fijo que L28 · by: apps/api/tests/escenarios/test_datos_migraciones.py "@REV-03-S8 @assumption:REV-03-ASM-06"
- L30 · 2026-10-23 · kit updated 720d5e70b54968dbbdd1989cc041eb6fa1089c43 → 1594a34f3e4027e9e7085fad559488f69ae6d96a · kit 6.3.1: kit 3 tags in replaces, no-visual skips design, flutter profile
- L31 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "la migración 0008 corta por lock_timeout si una transacción larga tiene la tabla @REV-03-S7 @assumption:REV-03-ASM-15" · usaba la base de nombre fijo de test_datos.py (misma colisión que L28) · by: apps/api/tests/escenarios/test_datos_migraciones_lock.py "la migración 0008 corta por lock_timeout si una transacción larga tiene la tabla @REV-03-S7 @assumption:REV-03-ASM-15"
- L32 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_datos_reemplazos.py · repite el armado de un test congelado de test_datos_tandas_y_cola.py que reemplaza; el original no se puede editar
- L33 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_datos_migraciones.py · repite el cuerpo de los tests congelados de migraciones de test_datos.py y test_datos_tandas_y_cola.py que reemplaza; el original no se puede editar
- L34 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_datos.py · test congelado: su armado se parece al de integracion/conftest.py, test_confirmacion_cancelacion_atomicidad.py y a su reemplazo, y no se puede editar
- L35 · 2026-10-23 · declared · K4 · apps/api/tests/unit/test_despacho_de_confirmaciones.py · test congelado con el armado de test_recordatorios.py; no se puede editar
- L36 · 2026-10-23 · declared · K4 · apps/api/tests/integracion/test_historial_api.py · test congelado con el armado de test_reservas_api.py y test_anular_reserva_api.py; no se puede editar
- L37 · 2026-10-23 · declared · K4 · apps/mobile/test/historial_por_tandas_test.dart · test congelado con el armado de horarios_test.dart; no se puede editar
- L38 · 2026-10-23 · rebase sobre card/REV-01 (f2b90cf) · resuelto: interfaz/reservas.py y aplicacion/reservas.py conservan los imports de REV-01 y el marcador de REV-03 (el 422 del marcador usa datos_invalidos, que faltaba tras el merge: NameError JSONResponse); openapi.json regenerado con despues/siguiente (test REV-01-S15 pasa) · integracion+unit 469 passed; escenarios (sin migraciones) 12 failed antes del arreglo: 5 marcador y contrato ya pasan (99 passed en test_datos, reemplazos, seguridad_api, historial, reservas), quedan los 4 congelados con reemplazo (L15-L18) y el congelado de REV-01 sin /health (reemplazado en test_requisitos_no_funcionales_con_salud.py por REV-01); test_la_pagina_avanzada... pasa solo y falla bajo carga (plan EXPLAIN) · Dart historial_por_tandas_test 1 passed · pendiente: mutaciones de env.py, 0008 y los archivos de dominio/infraestructura/interfaz/dart, design/line.md y K4 de producción
- L39 · 2026-10-23 · kit updated 84b012c6b61f3235df5e6d5637a5070deedf29b7 → 657ff3db69738f58a980615b84f7264952c0c979 · kit 6.4.0: design() fuera de Dart y arranque de la app
- L40 · 2026-10-23 · T1 a T3 · mutate: dominio/notificaciones.py 5/5 detected (exit 0); marcador.py, dominio/reservas.py, interfaz/reservas.py, infraestructura/reservas.py, infraestructura/notificaciones.py, aplicacion/notificaciones.py, migraciones/env.py y 0008 could not run: mutate.mjs exit 4 (19 mutantes x 195 a 512 s de baseline; ni tests/unit/test_marcador.py solo baja de 312 s por el arranque de la base) sobre el presupuesto de 10 min · lock test recreado (1 passed) · K4 en producción: jscpd sin clones fuera de tests
- L41 · 2026-10-23 · T1 a T4 · baseline chico: pytest-unit.sh (sin crear base por corrida; 4 bases fijas club_rev03_N_test con candado) baja el baseline de 195-312 s a 4-60 s · mutate una a una (emulador 8702): interfaz/marcador.py 19/19, interfaz/reservas.py 7/7, infraestructura/notificaciones.py 2/2, migraciones/env.py 1/1 (con test_datos_migraciones_transacciones.py), infraestructura/reservas.py 6/7 + 1 equivalente (tests test_datos_tanda_justa*.py), dominio/reservas.py 1/2 + 1 equivalente, 0008 1/2 + 1 equivalente, aplicacion/notificaciones.py sin operadores, los tres .dart could not run (mutate.mjs no tiene operadores Dart) · equivalentes en equivalents.md
- L42 · 2026-10-23 · kit updated 657ff3db69738f58a980615b84f7264952c0c979 → e5818794483826acc7ac09b20b84b1c1884cb38c · kit 6.5.3: mutación de Dart, && en mutate y reemplazos en toda línea
- L43 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "con el mismo inicio va primero el id más alto @REV-03-S3 @assumption:REV-03-ASM-07" · esperaba 21 filas en una sola tanda y la tanda es de 20 (título de L15 con las etiquetas) · by: apps/api/tests/escenarios/test_datos_reemplazos.py "con el mismo inicio va primero el id más alto @REV-03-S3 @assumption:REV-03-ASM-07"
- L44 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "de cada intento quedan tomada_en e intentos y el error va al log, no a la base @REV-03-S5 @assumption:REV-03-ASM-09" · _cancelar ya despachó una vez: intentos arrancaba en 1 (título de L16 con las etiquetas) · by: apps/api/tests/escenarios/test_datos_reemplazos.py "de cada intento quedan tomada_en e intentos y el error va al log, no a la base @REV-03-S5 @assumption:REV-03-ASM-09"
- L45 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "el recordatorio de una reserva que ya empezó no se reintenta y queda fallido @REV-03-S6 @assumption:REV-03-ASM-14" · el UPDATE dejaba un inicio que no es hora completa y violaba el CHECK de reserva (título de L17 con las etiquetas) · by: apps/api/tests/escenarios/test_datos_reemplazos.py "el recordatorio de una reserva que ya empezó no se reintenta y queda fallido @REV-03-S6 @assumption:REV-03-ASM-14"
- L46 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_datos_tandas_y_cola.py "la trazabilidad del admin muestra el aviso fallido como fallido, no como pendiente @REV-03-S5 @assumption:REV-03-ASM-17" · la cancelación del usuario no deja aviso en la trazabilidad; hace falta la anulación del admin (título de L18 con las etiquetas) · by: apps/api/tests/escenarios/test_datos_reemplazos.py "la trazabilidad del admin muestra el aviso fallido como fallido, no como pendiente @REV-03-S5 @assumption:REV-03-ASM-17"
- L47 · 2026-10-23 · replaces: apps/api/tests/escenarios/test_requisitos_no_funcionales.py "una operación sobre usuarios o reservas sin usuario autenticado se rechaza @RNF-01-H06-02 @supuesto:RNF-01-SUP-01" · `/health` es público (REV-01-ASM-07, REV-01-ASM-13) y el viejo lo cuenta como operación aceptada sin sesión; ya reemplazado en REV-01 · by: apps/api/tests/escenarios/test_requisitos_no_funcionales_con_salud.py "una operación sobre usuarios o reservas sin usuario autenticado se rechaza @RNF-01-H06-02 @supuesto:RNF-01-SUP-01"
- L48 · 2026-10-23 · declared · K4 · apps/mobile/lib/reservas/pantalla_mis_reservas.dart · los bloques repetidos (cabecera con título y BotonCuenta, padding de pantalla, spinner y REINTENTAR, tarjeta de reserva) son el armado común de las pantallas con el mismo diseño y ya estaban antes de REV-03; REV-03 sólo cambió el cuerpo de la lista (tandas), y extraer el armado de pantalla es un refactor que el pedido no hace
- L49 · 2026-10-23 · declared · K4 · apps/mobile/lib/inicio/pantalla_inicio.dart · duplicación previa a REV-03 (no tocó el archivo): comparte con pantalla_mis_reservas.dart el armado de la tarjeta de reserva
- L50 · 2026-10-23 · declared · K4 · apps/mobile/lib/reservas/reservas.dart · los bloques repetidos con historial_reservas.dart y entre sí son del parseo de la reserva, anteriores a REV-03, que sólo agregó el marcador de tanda
- L51 · 2026-10-23 · declared · K4 · apps/mobile/lib/admin/historial_reservas.dart · el bloque que comparte con reservas.dart es previo a REV-03, que sólo agregó 10 líneas para el marcador de tanda
- L52 · 2026-10-23 · declared · K4 · apps/mobile/lib/sedes/pantalla_sede.dart · duplicación previa a REV-03 (no tocó el archivo) con el armado de pantalla_mis_reservas.dart
- L53 · 2026-10-23 · declared · K4 · apps/mobile/lib/admin/pantalla_sedes_admin.dart · armado de pantalla (padding, Column, Row de cabecera) igual al de pantalla_mis_reservas.dart; REV-03 no tocó este archivo
- L54 · 2026-10-23 · declared · K4 · apps/mobile/lib/admin/pantalla_panel_admin.dart · bloque previo a REV-03 (no tocó el archivo) igual a uno de pantalla_mis_reservas.dart
- L55 · 2026-10-23 · declared · K4 · apps/mobile/lib/admin/pantalla_detalle_reserva.dart · bloque previo a REV-03 (no tocó el archivo) igual a uno de pantalla_mis_reservas.dart
- L56 · 2026-10-23 · declared · K4 · apps/mobile/lib/admin/estado_reserva_chip.dart · bloque previo a REV-03 (no tocó el archivo) igual a uno de otro archivo de la app
- L57 · 2026-10-23 · T1 a T4 · arreglos del gate 2: lint y attacks pasan en wrappers (lint-api-rev03.sh; attacks con `--common-headers "Content-Security-Policy"`, sin X-Request-ID que es de REV-02; corrido a mano: exit 0, el timeout del JSON mal formado no se repitió); suite ignora tests/escenarios/test_datos* (los corre scenarios; el basename fijo de test_datos.py chocaba y dejaba conexiones abiertas que rompían tests ajenos: test_historial_reservas y test_datos_migraciones_lock pasan juntos, 2 passed); replaces L43-L47 con los títulos con etiquetas; mutate 0008: la línea corre los tests (0/2 vivos en :12 y :13, ambos equivalentes, declarados); K4 declarados L48-L56
- L58 · 2026-10-23 · `lint:` corre por `ruff-mypy-api-rev03.sh`, que nombra lo que cubre: required.mjs sólo cuenta como linter un comando que dice ruff y las carpetas
- L59 · 2026-10-23 · declared · K4 · apps/api/app/infraestructura/reservas.py · los tramos repetidos (71-106 contra 91-106, 278-288 contra 388-398) vienen de CU-09 y CU-11, anteriores a esta card; REV-03 sólo agrega el marcador y las tandas
- L60 · 2026-10-23 · declared · K4 · apps/api/app/interfaz/reservas.py · el tramo 423-429 repite el de 250 desde CU-09 y CU-11, anteriores a esta card
- L61 · 2026-10-23 · declared · K4 · apps/api/tests/escenarios/test_datos_migraciones_lock.py · reemplazo (L31) del test congelado de test_datos_tandas_y_cola.py: conserva su preparación
- L62 · 2026-10-23 · kit updated e5818794483826acc7ac09b20b84b1c1884cb38c → b927271509c3ed9cdb1322253e90cd8f7cf17123 · kit 6.5.5: mutantes todos equivalentes
