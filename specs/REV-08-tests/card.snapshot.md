---
card: REV-08
extracted: 2026-10-20T22:40:59-03:00
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
status: proposed
---

# Snapshot — REV-08 · tests

## Card, as written

Transcripción sin interpretación. Cada bloque dice de qué fuente sale.

**Encabezado** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 1-5)

```text
# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.
```

**Hallazgo 23** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 225-237)

```text
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
```

**CU sin cubrir por los tests** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 301-318)

```text
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
```

**Pedido del coordinador** (fuente: pedido (texto))

```text
«Corregir el hallazgo 23 siguiendo el kit: la cota de RNF-01-H06-02 recongelada a 28, nombres de tests que prometen más de lo que prueban, C3 sin emulador, conteo de consultas, unitarios de aplicacion/reservas.py para poder mutar. Archivos: apps/api/tests/**. Sumar los dos escenarios de CU-14 sin test (H01-07 y H08-01).»
```

**Enunciado** (fuente: D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf · pdftotext -enc UTF-8 -layout, entero)

```text
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
```

**RNF-01-H06-02 y bloque que lo define** (fuente: specs/RNF-01-requisitos-no-funcionales/card.snapshot.md, líneas 65 y 36-39)

```text
- [ ] RNF-01-H06-02 — una operación sobre usuarios o reservas sin usuario autenticado se rechaza

**RNF 5 · Cloud** (fuente: enunciado) — «La API REST y la base de datos deberán estar disponibles en
la nube.» «Se podrán utilizar servicios como Render para el despliegue de la API y base de datos, y
Firebase para autenticación y notificaciones push.» «Las operaciones de la API relacionadas con
usuarios y reservas deberán identificar al usuario autenticado.»
```

**CU-14-H01-07 y CU-14-H08-01 y bloques que los definen** (fuente: specs/CU-14-historial-global-de-reservas/card.snapshot.md, líneas 119, 129, 47-48, 52-64, 78-79 y 106-108)

Escenarios:

```text
- [ ] CU-14-H01-07 — anula una reserva vigente con confirmación y el detalle muestra quién y cuándo la anuló
- [ ] CU-14-H08-01 — cancela la anulación y la reserva queda igual
```

Bloque «Poscondiciones», viñeta de anulación (define H01-07):

```text
- Si se anula una reserva vigente, «pasa al estado Cancelada, se libera la franja horaria y la
  anulación queda registrada con su trazabilidad (autor y fecha)».
```

Bloque «Flujo principal» (define H01-07 y H08-01, pasos 8 y 9):

```text
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
```

Bloque «Flujos alternativos y de excepción», FA7 (define H08-01):

```text
- **FA7 · El administrador cancela la anulación.** Origen: paso 9. Cierra el diálogo sin cambios y
  vuelve a la vista anterior.
```

Bloque «Pantallas del prototipo», viñeta de detalle (define H01-07):

```text
- Detalle: TRAZABILIDAD con «Reserva creada · Por Nahuel Mosse · 02/11/2026 18:42»; anulada:
  «Anulada por el administrador · Por Admin Sistema · 28/10/2026 09:15 · mantenimiento de la
  cancha» y «Notificación enviada al usuario».
```

**CU-14 · Consultar historial global de reservas (entero)** (fuente: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-14_Especificacion_Francisco_Luciano.pdf · pdftotext -enc UTF-8 -layout, 21 páginas)

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

**CU-15 · Anular reserva (admin) (entero)** (fuente: D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-15-Anular-reserva-admin.docx.pdf · pdftotext -enc UTF-8 -layout, 6 páginas)

```text
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
```

## Scenarios

- [ ] REV-08-H23-01 — la cota de rendimiento de RNF-01-H06-02 vuelve a la medida y no se ablanda
- [ ] REV-08-H23-02 — el test de duración de una reserva prueba los dos bordes
- [ ] REV-08-H23-03 — el test de baja muestra el DNI bloqueado antes y liberado después
- [ ] REV-08-H23-04 — el requisito de la app documentada se prueba por su comportamiento y no leyendo código
- [ ] REV-08-H23-05 — sin el emulador de autenticación la suite no sale verde
- [ ] REV-08-H23-06 — los pedidos calientes hacen una cantidad fija de consultas
- [ ] REV-08-H23-07 — los casos de uso de reservas tienen unitarios que permiten medir la mutación
- [ ] REV-08-H30-01 — el administrador anula una reserva desde el detalle del historial global y ve quién y cuándo
- [ ] REV-08-H30-02 — cancelar la anulación deja la reserva igual

## Contradictions within the card

Sin resolver. Cada lado dice lo suyo y dice dónde está. La resolución, si la hay, va en el plan.

- **Cota de RNF-01-H06-02.** El pedido dice «la cota de RNF-01-H06-02 recongelada a 28». El hallazgo 23, T2, dice que a81ce1c la bajó de «`>= 30` a `>= 25` con 28 medidas». REV-08-H23-01 dice «la cota de rendimiento de RNF-01-H06-02 vuelve a la medida y no se ablanda». Las tres frases no fijan por sí solas un único valor de cota (28, 30 o «la medida»). · pedido (texto); specs/REVISION-kit3.md hallazgo 23, T2; REV-08-H23-01.
- **Alcance de archivos frente a los escenarios H30.** El pedido limita los cambios a «Archivos: apps/api/tests/**». REV-08-H30-01 y REV-08-H30-02 describen acciones en la pantalla de detalle del historial global, que según el CU-14 es parte del panel de administración de la app (pasos 8 a 10 y FA7). La revisión ubica los tags de CU-14 en `apps/mobile/integration_test` («CU sin cubrir por los tests»). · pedido (texto); REV-08-H30-01 y REV-08-H30-02; specs/REVISION-kit3.md «CU sin cubrir por los tests».
- **Diferimiento frente a pedido.** La revisión dice que los dos escenarios de CU-14 «se difirieron a CU-15 a propósito (CU-14-SUP-04, `specs/CU-14-historial-global-de-reservas/plan.md:42`)». El pedido dice «Sumar los dos escenarios de CU-14 sin test (H01-07 y H08-01)». · specs/REVISION-kit3.md «CU sin cubrir por los tests»; pedido (texto).

Dentro de las fuentes incorporadas (no son contradicciones de REV-08; se transcriben porque están en el CU-14 que se usa como fuente, según el snapshot congelado de CU-14, sección «Contradicciones dentro de la card»):

```text
- El CU anula dejando la reserva en estado «Cancelada»; CU-15 la deja «Anulada por
  administración»; el prototipo la muestra «ANULADA» en la pestaña «Anuladas» · CU-14 paso 9,
  CU-15 poscondiciones, Figma 55:786.
- FA8 da por hecho que se puede dar de baja un espacio o una sede con reservas, que pasan a
  Cancelada; CU-19 FA3 prohíbe la baja de una sede con reservas futuras · CU-14 FA8, CU-19 FA3.
- La anulación desde CU-14 no pide motivo; CU-15 hace el motivo obligatorio · CU-14 paso 9, CU-15
  paso 3.
- La poscondición dice que la consulta no modifica el estado del sistema y a la vez la registra en un
  log de auditoría con los filtros usados · CU-14 poscondiciones.
```
