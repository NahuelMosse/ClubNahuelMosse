# REV-08 · tests

card: REV-08
status: proposed
cap: 12 h
sources:
  - "specs/REVISION-kit3.md @ 138bc54 (D:/Temp/w/rev08, rama card/REV-08, worktree limpio): líneas 1-5, hallazgo 23 (líneas 225-237) y «## CU sin cubrir por los tests» (líneas 301-318). Leído con Read."
  - "pedido (texto): mensaje del coordinador, transcripto tal cual."
  - "enunciado: D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf · pdftotext -enc UTF-8 -layout, texto entero (4 páginas)."
  - "specs/RNF-01-requisitos-no-funcionales/card.snapshot.md (congelado): escenario RNF-01-H06-02 y bloque «RNF 5 · Cloud». Leído con Read."
  - "specs/CU-14-historial-global-de-reservas/card.snapshot.md (congelado): escenarios CU-14-H01-07 y CU-14-H08-01 y bloques que los definen (Poscondiciones, Flujo principal, Flujos alternativos FA7, Pantallas del prototipo). Leído con Read."
  - "CU: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-14_Especificacion_Francisco_Luciano.pdf · pdftotext -enc UTF-8 -layout, texto entero (21 páginas)."
  - "CU: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-15-Anular-reserva-admin.docx.pdf · pdftotext -enc UTF-8 -layout, texto entero (6 páginas)."
not_read:
  - "CU-14 (CU/CU-14_Especificacion_Francisco_Luciano.pdf): las 18 capturas P-01 a P-18 embebidas en el PDF. pdftotext sólo extrae texto; las imágenes no se abrieron."
  - "CU-15 (CU/CU-15-Anular-reserva-admin.docx.pdf): las capturas de «Capturas del flujo» (Panel ADMIN, Confirmar anulación) y de «Resultado y manejo de errores» (Reserva anulada, Error al anular). Son imágenes; no se abrieron."
  - "CU-14: el «Flujo Principal» sale de pdftotext -layout con columnas intercaladas. Se transcribió tal como salió; no se verificó visualmente el orden de la tabla."
  - "CU-14 y CU-15 en .../Electiva general/CU-nuevos/: no hay copia. El listado de esa carpeta no contiene ningún archivo CU-14 ni CU-15."
  - "Figma (los nodos citados en el snapshot de CU-14, p. ej. 55:251, 58:957, 59:1252): no accedido. No es fuente de este snapshot."
  - "Enunciado: los caracteres de ancho cero que pdftotext emite junto a las viñetas no se transcriben. No cambian el texto."
  - "Citados por la revisión y no leídos: specs/CU-14-historial-global-de-reservas/plan.md:42 (CU-14-SUP-04); apps/api/tests/escenarios/test_requisitos_no_funcionales.py:186; apps/api/tests/integracion/test_restricciones.py:78,152; apps/api/tests/conftest.py:72-76; apps/api/tests/unit/ y apps/mobile/integration_test (tags de CU-14). Son estado actual del código, no fuente del requisito."
  - "Otros archivos del repo (TRAZABILIDAD.md, demás snapshots, specs/CU-19 y CU-15 en specs/) no leídos. No son fuente de esta card."

## Specs

- S1 · "la cota de rendimiento de RNF-01-H06-02 vuelve a la medida y no se ablanda"
- S2 · "el test de duración de una reserva prueba los dos bordes"
- S3 · "el test de baja muestra el DNI bloqueado antes y liberado después"
- S4 · "el requisito de la app documentada se prueba por su comportamiento y no leyendo código"
- S5 · "sin el emulador de autenticación la suite no sale verde"
- S6 · "los pedidos calientes hacen una cantidad fija de consultas"
- S7 · "los casos de uso de reservas tienen unitarios que permiten medir la mutación"
- S8 · "el administrador anula una reserva desde el detalle del historial global y ve quién y cuándo"
- S9 · "cancelar la anulación deja la reserva igual"
- REV-08-ASM-01 · la anulación desde el detalle del historial (CU-14-H01-07 y H08-01) se prueba con tag de esta card aunque ya funcione: faltaba el test · S8,S9
- REV-08-ASM-02 · toda operación no pública responde 401 sin sesión y se cuentan todas las del contrato; hoy son 28; RNF-01-H06-02 se recongela a `>= 28` · S1
- REV-08-ASM-03 · sin el emulador, la corrida falla con un mensaje claro; saltarse los tests de API sólo pasa con `--sin-emulador` · S5
- REV-08-ASM-04 · la app declara sus rutas en `lib/api/rutas.dart`; su cliente falla en debug si pide otra, así todos los widget tests lo vigilan; un test compara el manifiesto con `apps/api/openapi.json` · S4
- REV-08-ASM-05 · los pedidos de uso diario con consultas fijas son `GET /reservas`, `GET /sedes` y `GET /reservas/todas` · S6
- REV-08-ASM-06 · los dos tests engañosos de `test_restricciones.py` se quitan, porque los escenarios nuevos prueban lo que sus nombres prometían · S2,S3
- REV-08-ASM-07 · la app suma su manifiesto de rutas y el control en debug aunque el pedido apunte a `apps/api/tests/**`: S4 no se prueba por comportamiento sin que la app declare sus rutas; en release la app se comporta como hoy · S4
- REV-08-ASM-08 · RNF-01-H04-01 deja de leer el README con regex: se prueba contra el contrato que la API publica · S4
- REV-08-ASM-09 · «los casos de uso de reservas» son las funciones públicas de `aplicacion/reservas.py`; cada una tiene al menos un unitario sin base ni emulador · S7
- REV-08-ASM-10 · «sin el emulador» es tanto la variable ausente como el emulador apagado; en los dos casos la corrida falla con un mensaje claro · S5
- REV-08-ASM-11 · las operaciones públicas son las que el contrato publica sin seguridad; un token inválido cuenta como sin sesión · S1
- REV-08-ASM-12 · el manifiesto se compara por método y ruta, con los parámetros como plantilla (`/reservas/{id}`) · S4

## Tasks

- T1 · S1,S2,S3,S5,S6,S7 · apps/api/tests/conftest.py, apps/api/tests/escenarios/test_requisitos_no_funcionales.py, apps/api/tests/integracion/test_restricciones.py, apps/api/tests/unit/test_casos_de_uso_reservas.py · tests: apps/api/tests/escenarios/test_suite_confiable.py "toda operación no pública responde 401 sin sesión y se cuentan las 28 del contrato, como pide RNF-01-H06-02 @REV-08-S1 @assumption:REV-08-ASM-02"; apps/api/tests/escenarios/test_suite_confiable.py "test_restricciones ya no trae los dos tests engañosos de duración y de baja @REV-08-S2 @assumption:REV-08-ASM-06"; apps/api/tests/escenarios/test_suite_confiable.py "test_la_base_acepta_reservas_de_una_a_cuatro_horas @REV-08-S2"; apps/api/tests/escenarios/test_suite_confiable.py "test_la_base_rechaza_reservas_de_menos_de_una_o_mas_de_cuatro_horas @REV-08-S2"; apps/api/tests/escenarios/test_suite_confiable.py "test_la_baja_libera_el_dni_que_antes_estaba_bloqueado @REV-08-S3"; apps/api/tests/escenarios/test_suite_confiable.py "la baja libera el correo que antes estaba bloqueado @REV-08-S3"; apps/api/tests/escenarios/test_suite_confiable.py "con la variable del emulador ausente la corrida falla con un mensaje claro @REV-08-S5 @assumption:REV-08-ASM-10"; apps/api/tests/escenarios/test_suite_confiable.py "con el emulador apagado la corrida falla con un mensaje claro @REV-08-S5 @assumption:REV-08-ASM-10"; apps/api/tests/escenarios/test_suite_confiable.py "un token inválido cuenta como sin sesión y responde 401 @REV-08-S1 @assumption:REV-08-ASM-11"; apps/api/tests/escenarios/test_suite_confiable.py "cada función pública de aplicacion/reservas.py tiene su unitario @REV-08-S7 @assumption:REV-08-ASM-09"; apps/api/tests/escenarios/test_suite_confiable.py "RNF-01-H04-01 se prueba contra el contrato publicado y no leyendo el README @REV-08-S4 @assumption:REV-08-ASM-08"; apps/api/tests/escenarios/test_suite_confiable.py "test_sin_el_emulador_de_autenticacion_la_corrida_falla @REV-08-S5 @assumption:REV-08-ASM-03"; apps/api/tests/escenarios/test_suite_confiable.py "test_sin_el_emulador_se_puede_saltar_a_pedido_y_queda_dicho @REV-08-S5 @assumption:REV-08-ASM-03"; apps/api/tests/escenarios/test_suite_confiable.py "test_mis_reservas_hace_las_mismas_consultas_con_pocas_o_muchas @REV-08-S6 @assumption:REV-08-ASM-05"; apps/api/tests/escenarios/test_suite_confiable.py "test_las_sedes_y_el_historial_global_hacen_consultas_fijas @REV-08-S6 @assumption:REV-08-ASM-05"; apps/api/tests/escenarios/test_suite_confiable.py "test_los_casos_de_uso_de_reservas_se_prueban_sin_base_ni_emulador @REV-08-S7"
- T2 · S4 · apps/mobile/lib/api/rutas.dart (rule), apps/mobile/lib/api/cliente_api.dart (data) · tests: apps/mobile/test/rutas_de_la_api_test.dart "cada ruta que la app declara está publicada en el contrato de la API @REV-08-S4 @assumption:REV-08-ASM-04"; apps/mobile/test/rutas_de_la_api_test.dart "un pedido a una ruta que la app no declara falla en sus propios tests @REV-08-S4 @assumption:REV-08-ASM-04"; apps/mobile/test/rutas_de_la_api_test.dart "en release un pedido a una ruta no declarada sale como hoy @REV-08-S4 @assumption:REV-08-ASM-07"; apps/mobile/test/rutas_de_la_api_test.dart "el manifiesto se compara por método y por plantilla de ruta @REV-08-S4 @assumption:REV-08-ASM-12"
- T3 · S8,S9 · apps/mobile/test/anular_desde_el_detalle_test.dart · tests: apps/mobile/test/anular_desde_el_detalle_test.dart "el administrador anula una reserva desde el detalle del historial @REV-08-S8 @assumption:REV-08-ASM-01"; apps/mobile/test/anular_desde_el_detalle_test.dart "el detalle de una reserva anulada dice quién la anuló, cuándo y por qué @REV-08-S8"; apps/mobile/test/anular_desde_el_detalle_test.dart "volver sin confirmar la anulación deja la reserva igual @REV-08-S9"; apps/mobile/test/anular_desde_el_detalle_test.dart "cancelar el diálogo de anulación deja la reserva igual y la franja ocupada @REV-08-S9"; apps/mobile/test/anular_desde_el_detalle_test.dart "tocar fuera del diálogo de anulación deja la reserva igual y vuelve al detalle @REV-08-S9"

## Changes to existing behavior

- README: `apps/api/README.md` dice cómo correr la suite sin emulador (`--sin-emulador`) y que sin él falla
- ASVS: unchanged
- La suite falla sin emulador en vez de salir verde
- RNF-01-H06-02 y RNF-01-H04-01 recongelados
- La app falla en debug si pide una ruta no declarada; en release, igual que hoy

## Gate

```
suite: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider
lint: cd apps/api && uv run --no-sync ruff check . && uv run --no-sync mypy --strict app
app-suite: cd apps/mobile && flutter analyze && flutter test
scenarios: cd apps/api && uv run --no-sync pytest -q -p no:cacheprovider tests/escenarios/test_suite_confiable.py
mutate apps/api/app/aplicacion/reservas.py: cd apps/api && uv run --no-sync pytest -q -x tests/unit/test_casos_de_uso_reservas.py
mutate apps/mobile/lib/api/cliente_api.dart: cd apps/mobile && flutter test test/rutas_de_la_api_test.dart
mutate apps/mobile/lib/api/rutas.dart: cd apps/mobile && flutter test test/rutas_de_la_api_test.dart
app: sh D:/Temp/w/herramientas/api-app.sh rev08_app
attacks: sh D:/Temp/w/herramientas/api-attacks.sh rev08_app --json --no-ambient --write 'POST /sedes {"nombre": "Sede Ataque", "direccion": "Calle 1", "apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7]}' --read /reservas --read /yo --read /reservas/todas
```

## Log

- L1 · # Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.

23. **La mutación no se pudo medir y algunos tests prometen más de lo que prueban** · T3, T2, T10, T5, T6, C3, P10 ·
    falló / no se pudo correr
    - **T3:** la suite de la API tarda de 178 a 475 s y `mutate.mjs` corta en 10 min. Los casos de uso de
      `aplicacion/reservas.py` no tienen unitarios. Además, sobre Python la herramienta no muta `==`, `!=`, `and`/`or`,
      `not` ni `is None`, y 7 de sus 23 mutantes caen en comentarios: no hay score de mutación en ningún archivo.
    - **T2:** a81ce1c bajó la cota de RNF-01-H06-02 de `>= 30` a `>= 25` con 28 medidas
      (`tests/escenarios/test_requisitos_no_funcionales.py:186`).
    - **T10:** `test_la_reserva_dura_entre_una_y_cuatro_horas` sólo prueba 5 h, y `test_la_baja_libera_el_correo_y_el_dni`
      nunca muestra el DNI bloqueado (`tests/integracion/test_restricciones.py:78,152`).
    - **T5, T6:** RNF-01-H04-01 lee el código Dart y el README con regex (`:56-68`, `:303-326`); 40 de 305 tests tienen
      lógica.
    - **C3:** sin el emulador de Auth los tests de API se saltan y la corrida sale verde (`tests/conftest.py:72-76`).
    - **P10:** ningún test cuenta consultas por pedido.

## CU sin cubrir por los tests

Se cruzaron los escenarios de los 32 snapshots con los tags de los tests versionados
(`apps/mobile/integration_test`, `apps/mobile/test`, `apps/api/tests`). Que un escenario figure como cubierto quiere
decir que su tag está en algún test. No se corrieron los e2e.

- **269 escenarios: 267 con test y 2 sin test.** No hay tags que apunten a un escenario inexistente. 31 de las 32 cards
  están completas.
- **CU-14 · Historial global de reservas:** 16 de 18.
  - `CU-14-H01-07`: anular desde el historial con confirmación y ver quién y cuándo la anuló.
  - `CU-14-H08-01`: cancelar la anulación y que la reserva quede igual (FA7 del CU).
  - Los dos se difirieron a CU-15 a propósito (CU-14-SUP-04, `specs/CU-14-historial-global-de-reservas/plan.md:42`), y
    los escenarios de CU-15 cubren la anulación desde el panel. Sin embargo, ningún test ejercita la anulación desde el
    detalle de CU-14 con su tag.
- **Flujo de un CU sin escenario:** CU-24.1 FA5, el reintento del envío. Su snapshot lo declara: el reintento lo hace el
  servicio de notificaciones del sistema operativo, no la app.
- **Cobertura sólo nominal:** `RNF-01-H06-01` (API y base en la nube) tiene test, pero se saltea sin `API_URL_NUBE`: el
  despliegue en Render no se hizo.

Pedido del coordinador:

«Corregir el hallazgo 23 siguiendo el kit: la cota de RNF-01-H06-02 recongelada a 28, nombres de tests que prometen más de lo que prueban, C3 sin emulador, conteo de consultas, unitarios de aplicacion/reservas.py para poder mutar. Archivos: apps/api/tests/**. Sumar los dos escenarios de CU-14 sin test (H01-07 y H08-01).»

Enunciado:

Universidad de Morón - Docente: Marcelo Camicha

ELECTIVA GENERAL
Trabajo Práctico

Gestión de espacios deportivos

Desarrollar una aplicación móvil para la gestión de espacios deportivos

La aplicación permitirá:
    ●  que los usuarios reserven espacios deportivos desde sus celulares
    ●  consultar disponibilidad de espacios deportivos de diferentes sedes
    ●  recibir notificaciones push sobre reservas próximas.

El sistema deberá incluir tanto el desarrollo de APIs para la gestión de reservas, sedes,
espacios deportivos y perfiles de usuarios, como el desarrollo de la aplicación móvil en
Flutter.

Requerimientos Funcionales

1.  Registración, inicio de sesión y recuperación de contraseña

    ●  Registro de usuarios mediante correo electrónico y contraseña.
    ●  Una vez iniciada la sesión, la aplicación deberá mostrar una página inicial (Home

         Page).
    ●  Los usuarios que olviden su contraseña deberán disponer de un mecanismo seguro

         para recuperarla o establecer una nueva contraseña.

2.  Perfil de usuario:

    ●  Se deben mostrar todos los datos del perfil de usuario y permitir su edición, salvo la
         dirección de correo electrónico.

    ●  El perfil deberá incluir, como mínimo, nombre, apellido y fecha de nacimiento.
    ●  Se deberá poder cerrar la sesión.

3.  Gestión de reservas

    ●  Los horarios disponibles para las reservas deberán estar comprendidos dentro de
         los horarios de funcionamiento de la sede correspondiente.

    ●  Una reserva corresponde a un espacio deportivo, una fecha, una hora de inicio y una
         hora de finalización.

    ●  La duración mínima de una reserva será de una hora. Los horarios de inicio y
         finalización deberán corresponder a horas completas, es decir, deberán comenzar y
         finalizar en el minuto 00. Por ejemplo: 18:00 a 19:00, 18:00 a 20:00, etc.

                                                                                                                          1
                          Universidad de Morón - Docente: Marcelo Camicha

    ●  La hora de finalización de una reserva no podrá superar el horario de cierre de la
         sede.

    ●  Las reservas deberán realizarse para horarios futuros respecto del momento en que
         se efectúa la reserva.

    ●  Al reservar un espacio deportivo para una fecha y horario determinados, dicho
         espacio no podrá ser reservado por otro usuario para la misma fecha si existe
         superposición de horarios. El backend deberá validar la disponibilidad del espacio
         deportivo antes de registrar una reserva.

    ●  Se deberá:
              ○  Poder consultar la disponibilidad de espacios deportivos según la sede.
              ○  Reservar un espacio deportivo para una fecha y horario determinados.
              ○  Listar las reservas realizadas por el usuario, indicando sede, espacio
                   deportivo, fecha y horario.
              ○  Cancelar una reserva. Al cancelar una reserva, el espacio deportivo deberá
                   volver a estar disponible para ese mismo horario.
              ○  Recibir notificaciones push sobre reservas próximas.

4.  Módulo de Sedes

    ●  Cada sede deberá contar, como mínimo, con un nombre, una dirección y horarios de
         funcionamiento.

    ●  Mostrar el listado de sedes, sus horarios de funcionamiento y permitir seleccionar
         una sede para consultar sus espacios deportivos y horarios disponibles.

5.  Módulo de Espacios deportivos

    ●  Mostrar el listado de espacios deportivos indicando la sede donde se ubica cada
         uno.

    ●  Cada espacio deportivo deberá estar asociado a una sede y contar, como mínimo,
         con un tipo y un nombre compuesto por la sede, dirección, tipo de espacio deportivo
         y un número. Por ejemplo: Moron_Rivadavia_19850_Paddle_1.

    ●  Permitir filtrar los espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.).

6.  Historial de reservas

    ●  Acceder al historial de reservas realizadas, incluyendo las reservas cuyo horario ya
         haya finalizado.

7.  Manejo de errores

    ●  Se debe poder manejar los errores que puedan surgir durante el uso de la
         aplicación. Por ejemplo sin conexión a internet, servidor caído, login incorrecto,
         usuario ya registrado, etc.

                                                                                                                         2
                           Universidad de Morón - Docente: Marcelo Camicha

8.  Nombre de la aplicación

    ●  El nombre de la aplicación debe ser Club [Nombre y Apellido del alumno o alumna].
         Por ejemplo: ClubJuanaGonzalez.

9.  Nombre del repositorio GITHUB

    ●  El nombre del repositorio de GitHub deberá coincidir con el nombre de la aplicación.
         Por ejemplo: ClubJuanaGonzalez.

Requerimientos No Funcionales

1.  Aplicación móvil

    ●  El diseño de UX/UI se deberá realizar utilizando Figma
    ●  La aplicación móvil se deberá realizar utilizando Flutter
2.  Repositorio

    ●  El proyecto deberá gestionarse mediante un repositorio GitHub.
    ●  Cada alumno deberá utilizar su propia cuenta de GitHub y realizar commits durante

         el desarrollo del proyecto.
    ●  El historial del repositorio podrá ser considerado como parte del proceso de

         evaluación.
3.  REST API:

    ●  La API REST deberá estar documentada mediante Swagger/OpenAPI.
    ●  Se podrá elegir el lenguaje que se desee. (Preferentemente Python)
4.  BBDD:

    ●  Se podrá elegir cualquier base de datos relacional. (Preferentemente PostgreSQL)
5.  Cloud

    ●  La API REST y la base de datos deberán estar disponibles en la nube.
    ●  Se podrán utilizar servicios como Render para el despliegue de la API y base de

         datos, y Firebase para autenticación y notificaciones push.
    ●  Las operaciones de la API relacionadas con usuarios y reservas deberán identificar

         al usuario autenticado.

                                                                                                                         3
                           Universidad de Morón - Docente: Marcelo Camicha

6.  Readme
    ●  Tanto la aplicación móvil como el backend deberán contar con un archivo README
         que explique todos los pasos necesarios para configurar, ejecutar y, cuando
         corresponda, desplegar cada proyecto.

Entregables para evaluación

1.  Entrega 1 (Diseño)
    ●  Mockup y prototipo navegable desarrollado en Figma.
    ●  La Entrega 1 será presentada y defendida grupalmente.
    ●  Cada alumno deberá subir a Blackboard la documentación que se indicará luego de
         la presentación.

2.  Entrega 2 (Desarrollo y Modelo)
    ●  Backend desplegado en la nube y aplicación móvil conectada a la API REST.
    ●  Aplicación móvil en Flutter
    ●  Icono
    ●  Inicio de sesión, registración y recuperación de contraseña
    ●  Gestión de reservas
    ●  Modelo de datos de la aplicación, incluyendo entidades, atributos y relaciones.
    ●  Manejo de errores (sin conexión a internet, servidor caído, login incorrecto, usuario
         ya registrado, etc.)
    ●  Mostrar aplicación funcionando en emulador.
    ●  Subir a la plataforma Blackboard, antes de la exposición, el código del backend (ZIP)
         y el código de la aplicación móvil (ZIP).
    ●  La Entrega 2 será individual y deberá ser defendida individualmente. Cada alumno
         deberá demostrar conocimiento del funcionamiento general de su aplicación y de las
         decisiones de diseño e implementación adoptadas.

                                                                                                                          4

RNF-01-H06-02 y bloque que lo define:

- [ ] RNF-01-H06-02 — una operación sobre usuarios o reservas sin usuario autenticado se rechaza

**RNF 5 · Cloud** (fuente: enunciado) — «La API REST y la base de datos deberán estar disponibles en
la nube.» «Se podrán utilizar servicios como Render para el despliegue de la API y base de datos, y
Firebase para autenticación y notificaciones push.» «Las operaciones de la API relacionadas con
usuarios y reservas deberán identificar al usuario autenticado.»

CU-14-H01-07 y CU-14-H08-01 y bloques que los definen:

- [ ] CU-14-H01-07 — anula una reserva vigente con confirmación y el detalle muestra quién y cuándo la anuló
- [ ] CU-14-H08-01 — cancela la anulación y la reserva queda igual

Bloque «Poscondiciones», viñeta de anulación (define H01-07):

- Si se anula una reserva vigente, «pasa al estado Cancelada, se libera la franja horaria y la
  anulación queda registrada con su trazabilidad (autor y fecha)».

Bloque «Flujo principal» (define H01-07 y H08-01, pasos 8 y 9):

**Flujo principal** (fuente: CU-14)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | Desde el Panel de Administración, entra a la pestaña "Reservas". | Valida que la sesión tenga rol de Administrador y solicita a la API el historial completo. |
| 2 | Aguarda la respuesta. | Muestra el estado de carga, evitando una pantalla en blanco. |
| 3 | Visualiza el listado ("Todas"). | Despliega las reservas de todos los usuarios: deporte, sede, nombre técnico del espacio, usuario, franja horaria, precio y estado. Encabeza el contador total. |
| 4 | Usa las pestañas de estado (Todas, Activas, Completadas, Anuladas). | Filtra por el estado elegido y actualiza el contador. |
| 5 | Presiona "Filtros". | Despliega el panel: buscador por texto, sede, deporte, estado y rango de fechas. |
| 6 | Selecciona criterios y presiona "Aplicar". | Valida el rango de fechas, cierra el panel, pide a la API el listado filtrado y muestra la barra de filtros activos y la cantidad de resultados. |
| 7 | Escribe el nombre de un usuario, sede o espacio en la búsqueda. | Filtra en vivo, actualiza el contador; la búsqueda se combina con los filtros aplicados. |
| 8 | Toca una reserva. | Abre el detalle en modo lectura: deporte y espacio, sede y dirección, usuario, fecha y horario, precio, estado y trazabilidad (creación y, si corresponde, anulación). |
| 9 | Sobre una reserva vigente, presiona "Anular" y confirma. | Pide confirmación; al confirmar cambia el estado a Cancelada, libera la franja y muestra el detalle con «Anulada por el administrador». |
| 10 | Presiona "Volver". | Regresa al listado conservando filtros y posición. |

Bloque «Flujos alternativos y de excepción», FA7 (define H08-01):

- **FA7 · El administrador cancela la anulación.** Origen: paso 9. Cierra el diálogo sin cambios y
  vuelve a la vista anterior.

Bloque «Pantallas del prototipo», viñeta de detalle (define H01-07):

- Detalle: TRAZABILIDAD con «Reserva creada · Por Nahuel Mosse · 02/11/2026 18:42»; anulada:
  «Anulada por el administrador · Por Admin Sistema · 28/10/2026 09:15 · mantenimiento de la
  cancha» y «Notificación enviada al usuario».

CU-14 · Consultar historial global de reservas (entero):

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

CU-15 · Anular reserva (admin) (entero):

ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Sebastián Amaray
Matrícula: [Completar]
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-15: Anular reserva (admin)
Definición General del Caso de Uso

 • Nombre del Caso de Uso: Anular reserva (admin)
 • ID / Código: CU-15
 • Actor Principal: Administrador
 • Objetivo: Permitir que un administrador anule una reserva activa por una causa

     operativa, deje registrado el motivo y libere el turno para nuevas reservas.

 • ¿Qué problema resuelve?: Permite actuar ante mantenimiento, indisponibilidad del

     espacio, errores de carga u otras situaciones que impiden cumplir una reserva
     confirmada.

Precondiciones y Poscondiciones

Precondiciones

 • El administrador debe estar autenticado y contar con permisos de administración.

 • La reserva debe existir, estar activa y corresponder a un horario futuro.

 • El sistema debe haber cargado los datos de la reserva.

Poscondiciones Estado final del sistema

 • La reserva queda registrada como Anulada por administración, con motivo, fecha, hora
     y administrador responsable.

 • El espacio y la franja horaria quedan disponibles para nuevas reservas.

 • La reserva deja de aparecer entre las activas y pasa al listado de anuladas.

 • El sistema solicita el envío de una notificación al usuario afectado.
Flujo Principal Camino Feliz

Paso          Acción del Actor        Respuesta / Validación del
                                                   Sistema
 1    El administrador abre la
 2    sección Reservas desde el      El sistema valida la sesión y
      panel de administración.       muestra las reservas del club.

      El administrador localiza una  El sistema abre la confirmación
      reserva activa y presiona      con la sede, la cancha, el
      Anular.                        usuario, la fecha, el horario y el
                                     importe de la reserva.
3     El administrador escribe el
                                     El sistema exige un motivo
      motivo de la anulación.        antes de habilitar la
                                     confirmación.
4     El administrador presiona
                                     El sistema comprueba que la
      Confirmar anulación.           reserva siga activa y envía la
                                     solicitud al servidor.
5     El administrador espera el
      resultado.                     El sistema registra la anulación
                                     administrativa, libera el turno,
                                     solicita la notificación al usuario
                                     y muestra el mensaje Reserva
                                     anulada correctamente.
Flujos Alternativos y Excepciones

Flujo Alternativo 1: El administrador desiste

 • Paso de origen: Paso 4 del flujo principal.
 • Condición: El administrador presiona Volver antes de confirmar.
 • Acción del sistema: El sistema cierra la confirmación y vuelve a la pantalla desde la

     cual se inició la acción. La reserva no cambia.

Flujo Alternativo 2: Falta el motivo

 • Paso de origen: Paso 3 del flujo principal.
 • Condición: El administrador intenta confirmar sin completar el motivo.
 • Acción del sistema: El sistema indica que el campo es obligatorio y no envía la solicitud.

Flujo Alternativo 3: La reserva ya no está activa

 • Paso de origen: Paso 4 del flujo principal.
 • Condición: La reserva fue modificada, cancelada o comenzó antes de procesar la

     solicitud.

 • Acción del sistema: El sistema rechaza la anulación, informa que la reserva ya no

     puede anularse y actualiza el listado.

Flujo Alternativo 4: Error al procesar la anulación

 • Paso de origen: Paso 5 del flujo principal.
 • Condición: Se pierde la conexión o el servidor devuelve un error.
 • Acción del sistema: El sistema muestra la pantalla No pudimos anular la reserva. El

     administrador puede reintentar o volver. La reserva conserva su estado anterior
     mientras no exista confirmación del servidor.
Capturas del flujo
Panel ADMIN         Confirmar anulación
Resultado y manejo de errores

Reserva anulada                Error al anular
- L2 · 2026-10-22 · kit updated d7c92c83fa055a140ca5dca9c16c1899c6d45191 → 6b982a3b4efec0cc0a103964973e3e9a074c6422 · kit 5.0.1: context-cap blocked the main thread after /compact
- L3 · 2026-10-22 · declared · fault-db · la base es Postgres y `--fault-db` sólo daña un archivo SQLite; la card no cambia el acceso a datos
- L4 · 2026-10-22 · los tests de esta card se escriben a partir de los borradores de D:/Temp/w/borradores/rev08/, con los títulos de `## Tasks`. `app:` y `attacks:` usan D:/Temp/w/herramientas/api-app.sh y api-attacks.sh: base propia `club_rev08_app` migrada, admin sembrado y su token del emulador de Auth; el gate corre con `TEST_DATABASE_URL=…/club_rev08_test` y `FIREBASE_AUTH_EMULATOR_HOST` en el entorno
- L5 · 2026-10-22 · kit updated 6b982a3b4efec0cc0a103964973e3e9a074c6422 → 0a8f6431dd7b130c87980f69f9122b45794f6b70 · kit 6.0.0: nested test folders need no layer
- L6 · 2026-10-22 · kit updated 0a8f6431dd7b130c87980f69f9122b45794f6b70 → 1117da7bd97604f13460f467d8a02afaeb6d299a · kit 6.0.0: nested test folders need no layer
- L7 · 2026-10-22 · declared · REV-08-ASM-01 · «14» y «07» son de los IDs CU-14-H01-07 que el supuesto cita, no valores del comportamiento
- L8 · 2026-10-22 · el gate corre con `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702` y Flutter en el PATH (`/d/projects/flutter/bin`)
- L9 · 2026-10-22 · judge ACT-01, ACT-02, ACT-04 a ACT-08 · se cierran con REV-08-ASM-07 a ASM-12 y los tests nuevos de T1, T2 y T3
- L10 · 2026-10-22 · declared · ACT-03 · RNF-01-H04-01 con el README pasa a ASM-08; «40 de 305 tests tienen lógica» es una medida del hallazgo, no un comportamiento; el mutador del kit actual ya muta `==`, `!=`, `and`/`or`, `not` e `is None` y no toca comentarios
- L11 · 2026-10-22 · declared · REV-08-ASM-11 · «401» lo nombra el título del test; el supuesto no trae otros valores
- L12 · 2026-10-22 · declared · REV-08-ASM-09, REV-08-ASM-10 · «los casos de uso de reservas» y «sin el emulador» citan las frases de S7 y S5 que el supuesto interpreta, no son valores del comportamiento
- L13 · 2026-10-22 · T2 · cd apps/mobile && flutter test test/rutas_de_la_api_test.dart: 4 passed (contrato generado con app.openapi() en apps/api/openapi.json, sin versionar: REV-01 lo trae); flutter analyze: No issues; flutter test completo: 425 passed
- L14 · 2026-10-22 · T3 · flutter test test/anular_desde_el_detalle_test.dart: 5 passed al primer intento (ASM-01: el comportamiento ya existía); se quitó un import sin uso de soporte/admin.dart que hacía fallar flutter analyze
