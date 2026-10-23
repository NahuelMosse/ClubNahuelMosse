---
card: REV-07
extracted: 2026-10-20T21:39:47-03:00
sources:
  - pedido (texto) — pedido del coordinador, recibido como texto en la sesión (sin Jira)
  - file: specs/REVISION-kit3.md @ 138bc54 — líneas 1-5 (encabezado), hallazgos 21 y 22 completos, hallazgo 25 viñeta S12
  - file: "D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf" — pdftotext -enc UTF-8 -layout, entero
  - listado de nombres de archivo: "D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/" y ".../CU-nuevos/" (sólo nombres, consultables)
not_read:
  - contenido de los CU: no transcripto, la card no cambia comportamiento; consultables en esas carpetas
  - "Distribucion CUs.jpeg" (carpeta CU/): no abierto, mismo motivo
status: proposed
---

# Snapshot — REV-07 · documentación de producción

## Card, as written

**Encabezado del documento** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 1-5)

# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.

**Pedido del coordinador** (fuente: pedido (texto))

Corregir los hallazgos 21 (asvs.md L2, system-design.md con STRIDE, dependencias, SLOs y entornos; ADRs; THIRD_PARTY_NOTICES; costos; runbook; declaración de accesibilidad; modelo de datos de las 9 tablas; presupuesto de rendimiento) y 22 (supuestos en los README), más S12 del 25, siguiendo el kit. Archivos: docs/, specs/asvs.md, los README. Los snapshots viejos están congelados: lo del hallazgo 24 no se corrige. La documentación describe la app como es hoy.

**Hallazgo 21** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 210-217)

21. **Falta la documentación que el grado production pide** · R10, D8, D9, D14, S15, S19, S21, S22, O13, O14, P14, W5,
    I15, I17, V5, R9 · falló · lectura
    - No existen: `specs/asvs.md` (matriz L2, que `.claude/tools/checks/security-l2.mjs` exige), `docs/technical/system-design.md`
      (STRIDE, dependencias con timeout y reintento, entornos, SLOs), ADRs, `THIRD_PARTY_NOTICES.md`, el modelo de
      costos, el runbook (rollback, rotación de secretos, incidentes), la declaración de accesibilidad y el registro de
      accesibilidad por pantalla.
    - El modelo de datos documentado (`specs/MOD-01-modelo-de-datos/data-model.md`) cubre 4 de 9 tablas.
    - No hay presupuesto de rendimiento ni de capacidad, ni la declaración de que no lo hay.

**Hallazgo 22** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 219-223)

22. **Los supuestos no llegan a quien opera la app** · R4 · falló · lectura
    - Ninguno de los 545 supuestos está en `apps/api/README.md` ni en `apps/mobile/README.md`, y no hay README en la
      raíz. Por ejemplo: de 1 a 4 h y hasta 7 días de anticipación, el admin no reserva, catálogo fijo, sin pagos.
    - Están registrados como `SUP-NN`, no `ASM-NN`, y los snapshots usan `fuentes:` y `no_leido:` en vez de `sources:` y
      `not_read:`: las herramientas del kit 3.0.0 no los encuentran (`required.mjs`).

**Hallazgo 25, viñeta S12** (fuente: specs/REVISION-kit3.md @ 138bc54, línea 254)

    - **S12:** MPL-2.0 (certifi) y LGPL-3.0 (psycopg) sin excepción escrita, y las fuentes OFL sin su licencia.

**Enunciado** (fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf`, pdftotext -enc UTF-8 -layout, entero)

                           Universidad de Morón - Docente: Marcelo Camicha

           ELECTIVA GENERAL​
               Trabajo Práctico

Gestión de espacios deportivos

Desarrollar una aplicación móvil para la gestión de espacios deportivos

La aplicación permitirá:
    ●​ que los usuarios reserven espacios deportivos desde sus celulares
    ●​ consultar disponibilidad de espacios deportivos de diferentes sedes
    ●​ recibir notificaciones push sobre reservas próximas.

El sistema deberá incluir tanto el desarrollo de APIs para la gestión de reservas, sedes,
espacios deportivos y perfiles de usuarios, como el desarrollo de la aplicación móvil en
Flutter.

Requerimientos Funcionales

1.​ Registración, inicio de sesión y recuperación de contraseña​

    ●​ Registro de usuarios mediante correo electrónico y contraseña.
    ●​ Una vez iniciada la sesión, la aplicación deberá mostrar una página inicial (Home

         Page).
    ●​ Los usuarios que olviden su contraseña deberán disponer de un mecanismo seguro

         para recuperarla o establecer una nueva contraseña. ​

2.​ Perfil de usuario:​

    ●​ Se deben mostrar todos los datos del perfil de usuario y permitir su edición, salvo la
         dirección de correo electrónico.

    ●​ El perfil deberá incluir, como mínimo, nombre, apellido y fecha de nacimiento.
    ●​ Se deberá poder cerrar la sesión.​

3.​ Gestión de reservas​

    ●​ Los horarios disponibles para las reservas deberán estar comprendidos dentro de
         los horarios de funcionamiento de la sede correspondiente.

    ●​ Una reserva corresponde a un espacio deportivo, una fecha, una hora de inicio y una
         hora de finalización.

    ●​ La duración mínima de una reserva será de una hora. Los horarios de inicio y
         finalización deberán corresponder a horas completas, es decir, deberán comenzar y
         finalizar en el minuto 00. Por ejemplo: 18:00 a 19:00, 18:00 a 20:00, etc.

                                                                                                                          1
                          Universidad de Morón - Docente: Marcelo Camicha

    ●​ La hora de finalización de una reserva no podrá superar el horario de cierre de la
         sede.

    ●​ Las reservas deberán realizarse para horarios futuros respecto del momento en que
         se efectúa la reserva.

    ●​ Al reservar un espacio deportivo para una fecha y horario determinados, dicho
         espacio no podrá ser reservado por otro usuario para la misma fecha si existe
         superposición de horarios. El backend deberá validar la disponibilidad del espacio
         deportivo antes de registrar una reserva.

    ●​ Se deberá:
              ○​ Poder consultar la disponibilidad de espacios deportivos según la sede.
              ○​ Reservar un espacio deportivo para una fecha y horario determinados.
              ○​ Listar las reservas realizadas por el usuario, indicando sede, espacio
                   deportivo, fecha y horario.
              ○​ Cancelar una reserva. Al cancelar una reserva, el espacio deportivo deberá
                   volver a estar disponible para ese mismo horario.
              ○​ Recibir notificaciones push sobre reservas próximas. ​

4.​ Módulo de Sedes​

    ●​ Cada sede deberá contar, como mínimo, con un nombre, una dirección y horarios de
         funcionamiento.

    ●​ Mostrar el listado de sedes, sus horarios de funcionamiento y permitir seleccionar
         una sede para consultar sus espacios deportivos y horarios disponibles.​

5.​ Módulo de Espacios deportivos​

    ●​ Mostrar el listado de espacios deportivos indicando la sede donde se ubica cada
         uno.

    ●​ Cada espacio deportivo deberá estar asociado a una sede y contar, como mínimo,
         con un tipo y un nombre compuesto por la sede, dirección, tipo de espacio deportivo
         y un número. Por ejemplo: Moron_Rivadavia_19850_Paddle_1.

    ●​ Permitir filtrar los espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.).​

6.​ Historial de reservas​

    ●​ Acceder al historial de reservas realizadas, incluyendo las reservas cuyo horario ya
         haya finalizado. ​

7.​ Manejo de errores​

    ●​ Se debe poder manejar los errores que puedan surgir durante el uso de la
         aplicación. Por ejemplo sin conexión a internet, servidor caído, login incorrecto,
         usuario ya registrado, etc.​

                                                                                                                         2
                           Universidad de Morón - Docente: Marcelo Camicha

8.​ Nombre de la aplicación​

    ●​ El nombre de la aplicación debe ser Club [Nombre y Apellido del alumno o alumna].
         Por ejemplo: ClubJuanaGonzalez. ​

9.​ Nombre del repositorio GITHUB​

    ●​ El nombre del repositorio de GitHub deberá coincidir con el nombre de la aplicación.
         Por ejemplo: ClubJuanaGonzalez.

Requerimientos No Funcionales

1.​ Aplicación móvil​

    ●​ El diseño de UX/UI se deberá realizar utilizando Figma
    ●​ La aplicación móvil se deberá realizar utilizando Flutter​
2.​ Repositorio​

    ●​ El proyecto deberá gestionarse mediante un repositorio GitHub.
    ●​ Cada alumno deberá utilizar su propia cuenta de GitHub y realizar commits durante

         el desarrollo del proyecto.
    ●​ El historial del repositorio podrá ser considerado como parte del proceso de

         evaluación. ​
3.​ REST API:​

    ●​ La API REST deberá estar documentada mediante Swagger/OpenAPI.
    ●​ Se podrá elegir el lenguaje que se desee. (Preferentemente Python)​
4.​ BBDD:​

    ●​ Se podrá elegir cualquier base de datos relacional. (Preferentemente PostgreSQL)​
5.​ Cloud​

    ●​ La API REST y la base de datos deberán estar disponibles en la nube.
    ●​ Se podrán utilizar servicios como Render para el despliegue de la API y base de

         datos, y Firebase para autenticación y notificaciones push.
    ●​ Las operaciones de la API relacionadas con usuarios y reservas deberán identificar

         al usuario autenticado. ​

6.​ Readme​
    ●​ Tanto la aplicación móvil como el backend deberán contar con un archivo README
         que explique todos los pasos necesarios para configurar, ejecutar y, cuando
         corresponda, desplegar cada proyecto.

Entregables para evaluación

1.​ Entrega 1 (Diseño)​
    ●​ Mockup y prototipo navegable desarrollado en Figma.
    ●​ La Entrega 1 será presentada y defendida grupalmente.
    ●​ Cada alumno deberá subir a Blackboard la documentación que se indicará luego de
         la presentación.​

2.​ Entrega 2 (Desarrollo y Modelo)​
    ●​ Backend desplegado en la nube y aplicación móvil conectada a la API REST.
    ●​ Aplicación móvil en Flutter
    ●​ Icono
    ●​ Inicio de sesión, registración y recuperación de contraseña
    ●​ Gestión de reservas
    ●​ Modelo de datos de la aplicación, incluyendo entidades, atributos y relaciones.
    ●​ Manejo de errores (sin conexión a internet, servidor caído, login incorrecto, usuario
         ya registrado, etc.)
    ●​ Mostrar aplicación funcionando en emulador.
    ●​ Subir a la plataforma Blackboard, antes de la exposición, el código del backend (ZIP)
         y el código de la aplicación móvil (ZIP).
    ●​ La Entrega 2 será individual y deberá ser defendida individualmente. Cada alumno
         deberá demostrar conocimiento del funcionamiento general de su aplicación y de las
         decisiones de diseño e implementación adoptadas.

                                                                                                                          4

**Listado de los CU como fuente consultable** (fuente: listado de nombres de archivo de `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/` y `.../CU-nuevos/`; contenido no transcripto)

CU/
- CU - 01 Login - Acosta Noemi.pdf
- CU - 02 Log out.pdf
- CU-03 Registrar usuario.pdf
- CU-05 - Consultar perfil - Berazategui.pdf
- CU-06 - Editar perfil.pdf
- CU-07 - Dar cuenta de Baja.pdf
- CU-08 Consultar Historial de Reservas Individual.pdf
- CU-09_Reservar_cancha_MartinGaser .pdf
- CU-10 - Cancelar Reserva.pdf
- CU-12 - Consultar horarios disponibles.pdf
- CU-13 - Consultar Canchas.pdf
- CU-14_Especificacion_Francisco_Luciano.pdf
- CU-15-Anular-reserva-admin.docx.pdf
- CU-16 - Consultar sedes.pdf
- CU-17-Alta de sede.docx.pdf
- CU-19 - Dar de baja sede (Admin).pdf
- CU-20 - Filtrar espacios deportivos.pdf
- CU-21 - Alta Espacio Deportivo.pdf
- CU-23 - Baja Espacio Deportivo.pdf
- Distribucion CUs.jpeg

CU-nuevos/
- CU-04 - Cambiar contraseña.md
- CU-04b - Recuperar contraseña.md
- CU-11 - Modificar reserva.md
- CU-18 - Editar sede.md
- CU-22 - Editar espacio deportivo.md
- CU-24.1 - Notificacion recordatoria.md
- CU-24.2 - Notificacion de cancelacion forzosa.md
- CU-24.3 - Confirmacion de cancelacion.md

Fuera de la transcripción: el resto de specs/REVISION-kit3.md (hallazgos 1-20, 23-28, secciones de costo, qué corrió, grupos de criterios y CU sin cubrir) fue leído y no se transcribe porque no pertenece a la card pedida.

## Scenarios

- [ ] REV-07-H21-01 — la matriz ASVS de nivel 2 existe y cubre cada requisito con su estado y evidencia
- [ ] REV-07-H21-02 — el diseño del sistema describe amenazas, dependencias con su timeout y reintento, entornos y objetivos de servicio
- [ ] REV-07-H21-03 — las decisiones de arquitectura de stack y hosting están registradas
- [ ] REV-07-H21-04 — las licencias de terceros están declaradas
- [ ] REV-07-H21-05 — el costo de operar la app está calculado
- [ ] REV-07-H21-06 — el runbook dice cómo volver atrás, rotar secretos y atender un incidente
- [ ] REV-07-H21-07 — la declaración de accesibilidad y el registro por pantalla están publicados
- [ ] REV-07-H21-08 — el modelo de datos documenta las nueve tablas
- [ ] REV-07-H21-09 — el presupuesto de rendimiento y capacidad está escrito
- [ ] REV-07-H22-01 — quien opera la app encuentra los supuestos que la limitan en los README
- [ ] REV-07-H25-01 — las licencias MPL, LGPL y OFL tienen su excepción o su texto

## Contradictions within the card

- El encabezado de specs/REVISION-kit3.md (línea 3) dice que el módulo `docs` está apagado por decisión, y el pedido del coordinador dice «Archivos: docs/» y pide corregir el hallazgo 21, que exige `docs/technical/system-design.md`. Lo que dice cada lado: encabezado (apagado) frente a pedido y hallazgo 21 (documentación en `docs/`). Sin resolver.
- El pedido dice «La documentación describe la app como es hoy», pero el hallazgo 21 y los escenarios REV-07-H21-02 (objetivos de servicio, SLOs) y REV-07-H21-09 (presupuesto de rendimiento y capacidad) piden objetivos y presupuestos, que son metas y no descripción del estado actual. Sin resolver.
- El pedido dice «supuestos en los README» (hallazgo 22) y corrige el 22, pero el hallazgo 22 también señala que los supuestos están registrados como `SUP-NN` en vez de `ASM-NN` y que los snapshots usan `fuentes:` y `no_leido:` en vez de `sources:` y `not_read:`. El pedido dice que los snapshots viejos están congelados. Ningún escenario cubre el cambio de nombre de IDs ni de claves. Sin resolver.
