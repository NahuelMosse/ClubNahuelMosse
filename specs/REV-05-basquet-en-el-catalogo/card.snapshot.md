---
card: REV-05
extracted: 2026-10-20T22:45:50-03:00
sources:
  - specs/REVISION-kit3.md @ commit 138bc54 — líneas 1-5 (encabezado) y 193-197 (hallazgo 19)
  - pedido (texto) — pedido del coordinador, recibido como texto; no hay issue de Jira
  - specs/CU-21-alta-de-espacio/ambiguedades.md — línea 43 (CU-21-SUP-04, registrado en la línea CU-21-AMB-08 · vencida → CU-21-SUP-04)
  - specs/CU-13-consultar-canchas/ambiguedades.md — líneas 26, 33 y 34 (todos los eventos de CU-13-AMB-09)
  - Trabajo Práctico_2026.docx.pdf (carpeta Electiva general) — enunciado, pdftotext -enc UTF-8 -layout, 4 páginas
  - CU/CU-13 - Consultar Canchas.pdf — pdftotext -layout, 6 páginas
  - CU/CU-20 - Filtrar espacios deportivos.pdf — pdftotext -layout, 11 páginas
  - CU/CU-21 - Alta Espacio Deportivo.pdf — pdftotext -layout, 13 páginas
not_read:
  - Jira: no aplica. La card llegó como texto (pedido del coordinador); no se consultó Jira.
  - CU-13, CU-20 y CU-21 (PDF): las imágenes de pantallas incrustadas (8, 19 y 10 imágenes según pdfimages -list) no se abrieron; pdftotext extrae sólo texto.
  - CU-21 (PDF), Pantalla 10 «Alt-3»: el texto llega cortado en el PDF («Snackbar-Error, datos )»); no se completó ni se interpretó.
  - CU-13, CU-20 y CU-21 en formato .md o .docx: no existen. CU-nuevos/ no contiene estos CU y CU/ sólo tiene PDF para ellos; se leyó la versión .pdf de CU/.
  - apps/api/app/dominio/espacios.py (citado en el hallazgo 19 y en el pedido) y los iconos y fotos de la app (citados en el pedido): no leídos. Este snapshot congela el requisito, no el código.
  - specs/CU-21-alta-de-espacio/plan.md (mapea CU-21-SUP-04 al código) y specs/CU-21-alta-de-espacio/card.snapshot*.md: no leídos.
  - specs/CU-20-filtrar-espacios-deportivos/ambiguedades.md: no leído. Contiene CU-20-AMB-04 y CU-20-AMB-05 (esta última cita CU-21-SUP-04); CU-21-AMB-08 cita CU-20-AMB-04.
  - specs/CU-13-consultar-canchas/ambiguedades.md: sólo se transcribieron las líneas de CU-13-AMB-09; el resto del archivo no se transcribió.
  - CU/Distribucion CUs.jpeg: no leído (no pedido).
status: proposed
---

# Snapshot — REV-05 · Básquet en el catálogo

## Card, as written

Transcripción sin interpretación. Cada bloque indica de qué fuente sale. El texto está como en la fuente.

**Encabezado de la revisión** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 1-5)

```text
# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.
```

**Hallazgo 19** (fuente: specs/REVISION-kit3.md @ 138bc54, líneas 193-197)

```text
19. **El catálogo de deportes deja afuera Básquet** · R3 · falló · medido
    - `apps/api/app/dominio/espacios.py:90` y `specs/CU-21-alta-de-espacio/ambiguedades.md:43` (CU-21-SUP-04).
    - El enunciado lo da como ejemplo de tipo filtrable («Fútbol, Paddle, Básquet, etc.») y CU-13-AMB-09 lo preguntó;
      incluirlo servía con cualquier respuesta. `GET /espacios/catalogo` devuelve Futbol, Tenis, Padel, Voley, Hockey y
      Golf.
```

**Pedido del coordinador** (fuente: pedido (texto))

```text
Corregir el hallazgo 19 (el catálogo de deportes deja afuera Básquet) siguiendo el kit. Archivos principales: dominio/espacios.py, iconos y fotos de la app.
```

**CU-21-SUP-04** (fuente: specs/CU-21-alta-de-espacio/ambiguedades.md, línea 43; el ID aparece en esa línea, el archivo no tiene una sección propia para SUP-04)

```text
CU-21-AMB-08 · 2026-09-28 · vencida → CU-21-SUP-04 · el catálogo es el del prototipo más el pádel del CU: Fútbol (F5 Fútbol 5, F7 Fútbol 7, F8 Fútbol 8, F11 Fútbol 11), Tenis (PDL Polvo de ladrillo, CEM Cemento), Pádel (PAD Pádel), Vóley (IND Indoor, PLA Vóley playa), Hockey (H7 Hockey 7) y Golf (DR Driving range, 9H 9 hoyos); vive en el código de la API y la app lo pide
```

**CU-13-AMB-09** (fuente: specs/CU-13-consultar-canchas/ambiguedades.md, líneas 26, 33 y 34; todos los eventos del ID)

```text
CU-13-AMB-09 · 2026-09-27 · abierta · ¿cuáles son los deportes y tipos del club: los del prototipo (fútbol, tenis, hockey, vóley, golf) o también pádel y básquet?
CU-13-AMB-09 · 2026-09-27 · preguntada · al usuario, en la ronda de decisiones transversales
CU-13-AMB-09 · 2026-09-27 · resuelta · cada cancha es un espacio; deporte y tipo salen de un catálogo fijo; el nombre lleva la altura, sin tildes ni espacios; el número no se reutiliza; el nombre no cambia si se edita la sede; el alta pide techada o al aire libre e iluminación (decisión 8)
```

**Enunciado** (fuente: Trabajo Práctico_2026.docx.pdf, pdftotext -enc UTF-8 -layout, 4 páginas)

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

**CU-13 Consultar canchas** (fuente: CU/CU-13 - Consultar Canchas.pdf, pdftotext -layout, 6 páginas)

```text
      ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: [Matías La Giglia]
Matrícula: [52010863]
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): [CU-13: Consultar canchas]
Definición General del Caso de Uso

     ● Nombre del Caso de Uso: [Consultar canchas]

     ● ID / Código: [CU-13]

     ● Actor(es) Principal(es): [Usuario registrado]

     ● Objetivo: [Permitir al usuario consultar la disponibilidad de canchas y espacios deportivos
        según sede, tipo de deporte, fecha y horario, antes de iniciar una reserva.]

     ● ¿Qué problema resuelve?: [Evita que el usuario intente reservar espacios ocupados, fuera
        del horario de funcionamiento o que no coinciden con sus criterios de búsqueda,
        centralizando la disponibilidad real en una única consulta.]

Precondiciones y Poscondiciones

Precondiciones

     ● [El usuario debe estar autenticado en la aplicación]

     ● [Deben existir sedes y espacios deportivos activos cargados en el sistema, con horarios de
        funcionamiento definidos.]

Poscondiciones (Estado final del sistema)

     ● [El sistema muestra el listado de canchas disponibles para los criterios seleccionados o
        informa que no existen opciones para ese horario.]

     ● [No se genera ninguna reserva hasta que el usuario confirme la operación en el caso de uso
        correspondiente.]

     ● [Los filtros seleccionados quedan visibles para que el usuario pueda modificarlos y realizar
        una nueva consulta]

Flujo Principal (Camino Feliz)

               Paso         Acción del Actor         Respuesta / Validación del
1                                                                 Sistema
                     El usuario accede a la sección
2                    "Reservas" y selecciona la      El sistema muestra los filtros
                     opción "Consultar canchas".     de búsqueda: sede, tipo de
                                                     espacio deportivo, fecha, hora
                     El usuario selecciona una       de inicio y hora de
                     sede, un tipo de cancha y el    finalización.
                     rango horario que desea
                     consultar.                      El sistema valida que la fecha
                                                     y el horario sean futuros, que
                                                     correspondan a horas
                                                     completas y que estén dentro
                                                     del horario de funcionamiento
                                                     de la sede.
               Paso         Acción del Actor           Respuesta / Validación del
3                                                                  Sistema
                     El usuario presiona el botón
4                    "Consultar disponibilidad".      El sistema consulta la API
                                                      REST enviando sede, tipo de
5                    El usuario visualiza el listado  espacio, fecha y horario, y
                     de canchas disponibles y         compara las reservas
                     revisa la información de cada    existentes para detectar
                     opción.                          superposiciones.

                     El usuario selecciona una        El sistema muestra tarjetas con
                     cancha disponible o modifica     nombre de cancha, sede, tipo
                     los filtros para realizar una    de deporte, dirección, horario
                     nueva búsqueda.                  consultado, estado de
                                                      disponibilidad y precio si
                                                      corresponde.

                                                      El sistema conserva los
                                                      criterios seleccionados y, si el
                                                      usuario elige una cancha,
                                                      habilita la continuidad hacia el
                                                      caso de uso "Reservar espacio
                                                      deportivo".

Flujos Alternativos y Excepciones

Flujo Alternativo 1: Sin canchas disponibles

    • Paso de origen: Paso 4 del flujo principal.
    • Condición: La API no encuentra canchas disponibles para la sede, tipo de deporte, fecha y

         rango horario seleccionados.
    • Acción del sistema: El sistema muestra un mensaje de disponibilidad vacía, por ejemplo

         "No hay canchas disponibles para este horario", y permite modificar fecha, horario, sede o
         tipo de deporte sin perder el contexto de búsqueda.

Flujo Alternativo 2: Fecha u horario inválido

    • Paso de origenPaso 2 del flujo principal.
    • Condición: El usuario selecciona una fecha pasada, una hora que no comienza o finaliza en

         minuto 00, una duración menor a una hora o un horario fuera del funcionamiento de la sede.
    • Acción del sistema: La aplicación bloquea la consulta, muestra el mensaje de validación

         correspondiente y solicita corregir los filtros antes de llamar al backend.

Flujo Alternativo 3: Error de conexión a Internet

    • Paso de origen: Paso 3 del flujo principal.
    • Condición: Al consultar la disponibilidad, la aplicación detecta ausencia de conectividad a

         la red móvil o Wi-Fi.
    • Acción del sistema: La aplicación muestra un modal o pantalla de error "Error de conexión"

         con opción de reintentar, manteniendo visibles los filtros ingresados por el usuario.
Flujo Alternativo 4: Error en el servidor / falla en la API

    • Paso de origen: Paso 3 del flujo principal.
    • Condición: El backend responde con timeout, error interno o datos incompletos al procesar

         la consulta de disponibilidad.
    • Acción del sistema: La aplicación informa que no se pudo consultar la disponibilidad en ese

         momento, ofrece reintentar más tarde y evita mostrar resultados desactualizados como si
         fueran confirmados.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

     ● Pantalla 1: Pantalla "Consultar canchas" con filtros de sede, tipo de deporte, fecha, hora
        inicio y hora de finalización.

     ● Pantalla 2: Listado de canchas disponibles mediante tarjetas con sede, nombre del espacio
        deportivo, dirección, horario consultado, estado y acción para continuar con la reserva.

     ● Pantalla 3: Estado vacío cuando no existen canchas disponibles para los criterios
        seleccionados, con acceso rápido para cambiar fecha u horario.

     ● Pantalla 4: Modal o pantalla de error de conectividad y error de servidor con botón de
        reintento.

Modo Oscuro  Modo Claro
Componentes del Sistema de Diseño Utilizados

    • Criterio Unificado:
    • Filtros y controles:

         • Selector de sede y chips o lista desplegable para tipo de deporte: "Fútbol", "Pádel",
             "Tenis", "Básquet", etc.

         • DatePicker y TimePicker para elegir fecha, hora de inicio y hora de finalización con
             intervalos de hora completa.

         • Botón principal "Consultar disponibilidad" y botón secundario "Limpiar filtros" o
             "Modificar búsqueda".

Mensajes / Feedback:

             • Indicador de carga mientras se consulta la disponibilidad en la API REST.
             • Estado vacío cuando no hay canchas disponibles y sugerencia de modificar filtros.
             • Banner o modal para error de conexión y error de servidor, manteniendo los filtros

                  cargados.
```

**CU-20 Filtrar espacios deportivos** (fuente: CU/CU-20 - Filtrar espacios deportivos.pdf, pdftotext -layout, 11 páginas)

```text
      ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Nahuel Agustín Mosse
Matrícula: 53010986
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-20: Filtrar espacios deportivos
Nota: Todos los integrantes del equipo deben utilizar este mismo formato para mantener el
criterio unificado de presentación exigido para la entrega en PDF.

Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Filtrar espacios deportivos
     ● ID / Código: CU-20
     ● Actor(es) Principal(es): Usuario registrado
     ● Objetivo: Mostrar únicamente las canchas de una sede que coinciden con el

        deporte y el tipo de cancha que elige el usuario.
     ● ¿Qué problema resuelve?: La dificultad de encontrar una cancha cuando la sede

        ofrece varios deportes y modalidades.

Precondiciones y Poscondiciones

Precondiciones

     ● El usuario debe estar autenticado en la aplicación
     ● El usuario debe estar en la pantalla de una sede

Poscondiciones (Estado final del sistema)

     ● El listado muestra solo las canchas que cumplen con el filtro seleccionado.
     ● El contador refleja la cantidad de canchas y el deporte filtrado.
     ● Los chips seleccionados quedan resaltados y el filtro se mantiene mientras el

        usuario siga en la sede.
     ● No se modifica ningún dato: la operación es de solo lectura.

Flujo Principal (Camino Feliz)

               Paso        Acción del Actor         Respuesta / Validación
1                    El usuario abre la pantalla            del Sistema
                     de una sede.
2                                                 El sistema muestra los
                     El usuario presiona el chip  chips de deporte con el
                     de un deporte.               primero seleccionado y el
                                                  listado de canchas de ese
                                                  deporte.

                                                  El sistema resalta el chip,
                                                  muestra las variantes de
               Paso        Acción del Actor         Respuesta / Validación
3                                                           del Sistema
                     El usuario presiona el chip
                     de una variante.             ese deporte en "Todos" y
                                                  filtra el listado.

                                                  El sistema resalta el chip,
                                                  muestra solo las canchas
                                                  de ese tipo y actualiza el
                                                  contador.

Flujos Alternativos y Excepciones

Flujo Alternativo 1: Deporte sin variantes

     ● Paso de origen: Paso 2 del flujo principal
     ● Condición: El deporte elegido tiene una sola modalidad en esa sede.
     ● Acción del sistema: El sistema no muestra la barra de variantes y filtra solo por

        deporte. El caso de uso termina en el Paso 2.

Flujo Alternativo 2: Quitar el filtro de variante

     ● Paso de origen: Paso 3 del flujo principal
     ● Condición: El usuario presiona el chip "Todos".
     ● Acción del sistema: El sistema vuelve a mostrar todas las canchas del deporte

        seleccionado. El filtro de deporte no cambia.

Flujo Alternativo 3: Sede sin canchas

     ● Paso de origen: Paso 1 del flujo principal
     ● Condición: La sede no tiene ninguna cancha activa.
     ● Acción del sistema: El sistema no muestra los chips de filtro y avisa que la sede

        no tiene canchas disponibles.

Flujo Alternativo 4: Error de conexión a Internet

     ● Paso de origen: Pasos 1, 2 o 3 del flujo principal
     ● Condición: Al aplicar el filtro, el sistema detecta falta de conectividad a Internet.
     ● Acción del sistema: El sistema muestra una alerta y le pide al usuario que

        reintente una vez reestablecida la conexión. El listado no cambia.
Flujo Alternativo 5: Error en el servidor/falla en la API

     ● Paso de origen: Pasos 1, 2 o 3 del flujo principal
     ● Condición: La petición HTTP enviada al backend falla.
     ● Acción del sistema: El sistema informa el error del servidor y solicita el reintento

        más tarde. El listado no cambia.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

     ● Pantalla 1: Listado de canchas filtrado por Fútbol - Todos
     ● Pantalla 2: Listado de canchas filtrado por Fútbol 5
     ● Pantalla 3: Listado de canchas filtrado por Fútbol 11
     ● Pantalla 4: Listado de canchas filtrado por Hockey
     ● Pantalla 5: Listado de canchas filtrado por Vóley
     ● Pantalla 6: Sede sin canchas cargadas
     ● Pantalla 7: Mensaje de error de conexión a Internet
     ● Pantalla 8: Mensaje de error en el servidor/solicitud HTTPS
Todas las pantallas se muestran en modo nocturno y en modo claro.
Componentes del Sistema de Diseño Utilizados

Criterio Unificado: modo nocturno y modo claro del sistema de diseño, con acento lima
para el elemento seleccionado.
Botones:

     ● Chips de deporte: "Fútbol", "Hockey" y "Vóley".
     ● Chips de variante: "Todos", "Fútbol 5" y "Fútbol 11".
     ● Botón "Ver horarios / Reservar" en cada tarjeta de cancha.
     ● Botón "Aceptar" (para cerrar los mensajes de error del sistema en los casos de los

        flujos alternativos).
Mensajes / Feedback:

     ● Contador de canchas con el filtro aplicado.
     ● Mensaje de sede sin canchas disponibles.
     ● Mensaje de error de conexión a Internet.
     ● Mensaje de error en caso de fallo del servidor.
```

**CU-21 Alta de espacio deportivo** (fuente: CU/CU-21 - Alta Espacio Deportivo.pdf, pdftotext -layout, 13 páginas)

```text
      ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Paloma Patiño
Matrícula: 54011091
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-21: Alta de espacio deportivo
Nota: Todos los integrantes del equipo deben utilizar este mismo formato para mantener el criterio
unificado de presentación exigido para la entrega en PDF.

Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Alta de espacio deportivo

     ● ID / Código: CU-21

     ● Actor(es) Principal(es): Administrador

     ● Objetivo: Registrar un nuevo espacio deportivo en el sistema, asociándolo a una sede
        existente, para que quede disponible para ser reservado por los usuarios.

     ● ¿Qué problema resuelve?: Sin este flujo, no es posible incorporar nuevos espacios
        deportivos al catálogo de la aplicación. El alta centralizada permite al administrador
        mantener actualizada la oferta de espacios (canchas de fútbol, paddle, básquet, etc.) y
        garantizar que cada espacio quede correctamente vinculado a su sede con un nombre
        estandarizado.

Precondiciones y Poscondiciones

Precondiciones

     ● El administrador debe estar autenticado en el sistema con rol de administrador.

     ● Debe existir al menos una sede cargada en el sistema.

     ● El administrador debe tener permisos para gestionar espacios deportivos.

Poscondiciones (Estado final del sistema)

     ● El nuevo espacio deportivo queda registrado en la base de datos con estado activo.

     ● El espacio deportivo queda asociado a la sede seleccionada y visible para los usuarios en el
        listado de espacios disponibles.

     ● El nombre del espacio deportivo se genera automáticamente a partir de la sede, dirección,
        tipo y un número asignado por el sistema, con el formato
        Sede_Dirección_Deporte_Tipo_Número (ej. Moron_Rivadavia_Futbol_F5_1).

Flujo Principal (Camino Feliz)

               Paso         Acción del Actor         Respuesta / Validación del
1                                                                Sistema
                     El administrador accede al
                     módulo de gestión de espacios  El sistema muestra el
                     deportivos y selecciona la     formulario "Nuevo espacio
                     opción "+ Alta espacio ".      deportivo" con los campos:
                                                    sede, deporte, tipo, precio por
                                                    hora, y una vista previa del
               Paso         Acción del Actor           Respuesta / Validación del
2                                                                  Sistema
3                    Selecciona la sede a la que se
4                    asociará el nuevo espacio        nombre generado.
5                    deportivo.
                                                      El sistema toma la sede y su
                     Selecciona el deporte y el tipo  dirección para componer el
                     (ej. Fútbol / Fútbol 5) e        nombre, y habilita los campos
                     ingresa el precio por hora.      de deporte y tipo.

                     Verifica los datos ingresados y  El sistema asigna
                     el nombre generado               automáticamente el próximo
                     automáticamente (ej.             número disponible para ese
                     Moron_Rivadavia_Futbol_F5        tipo en esa sede y actualiza la
                     _1).                             vista previa del nombre.
                     Presiona "Guardar espacio".
                                                      El sistema mantiene la vista
                                                      previa del nombre compuesto
                                                      y habilita el botón "Guardar
                                                      espacio".

                                                      El sistema valida que no exista
                                                      un espacio duplicado, registra
                                                      el nuevo espacio deportivo
                                                      (asociado a la sede, con su tipo
                                                      y precio por hora) en la base
                                                      de datos y muestra un mensaje
                                                      de éxito.

Flujos Alternativos y Excepciones

Flujo Alternativo 1: Espacio deportivo duplicado

     ● Paso de origen: Paso 5 del flujo principal.
     ● Condición: Ya existe un espacio deportivo con el mismo nombre compuesto (misma sede,
        tipo y número).
     ● Acción del sistema: El sistema muestra un mensaje de error "Ya existe un espacio
        deportivo con ese nombre en la sede seleccionada" y recalcula el próximo número
        disponible para ese tipo de espacio en esa sede.

Flujo Alternativo 2: Datos incompletos o inválidos

     ● Paso de origen: Pasos 2, 3 o 5 del flujo principal.
     ● Condición: Falta completar la sede, el deporte, el tipo o el precio por hora.
     ● Acción del sistema: El botón "Guardar espacio" permanece deshabilitado (disabled). Se
        resalta el campo faltante con un mensaje indicando qué dato es obligatorio.

Flujo Alternativo 3: Error de conexión o servidor

     ● Paso de origen: Paso 5 del flujo principal.
     ● Condición: Se produce un error de red o el servidor no responde al intentar guardar el
        espacio deportivo.
     ● Acción del sistema: El sistema muestra un mensaje de error "No se pudo guardar el espacio
        deportivo. Verifique su conexión e intente nuevamente" y conserva los datos ingresados en
        el formulario para reintentar.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

     ● Pantalla 1: P-01: Listado de espacios deportivos (vista administrador)

     ● Pantalla 2: P-02: Formulario de alta de espacio deportivo (estado inicial vacío)
● Pantalla 3: P-03: Confirmación de alta exitosa

● Pantalla 4: P-02b: Formulario de alta - estado completo (todos los campos válidos,
   botón habilitado)
● Pantalla 5: P-02c: Dropdown Sede abierto (muestra las 4 sedes disponibles)
● Pantalla 6: P-02d: Dropdown Deporte abierto (Fútbol, Tenis, Paddle, Hockey, Vóley,
   Golf)
● Pantalla 7: P-02e: Dropdown Tipo abierto (variantes filtradas por el deporte
   seleccionado)
● Pantalla 8: Alt-1: Flujo Alternativo 1 - Espacio duplicado (Snackbar-Error en la parte
   superior)
● Pantalla 9: Alt-2: Flujo Alternativo 2 - Campo obligatorio faltante (Inline-Error
   debajo del campo Tipo)
● Pantalla 10: Alt-3: Flujo Alternativo 3 - Error de conexión (Snackbar-Error, datos )
   Componentes del Sistema de Diseño Utilizados

● Criterio Unificado:
        ● Botones: Btn-Primary "Guardar espacio" (habilitado con opacidad 100%
            cuando el formulario es válido, deshabilitado con opacidad 40% cuando faltan
            campos), Btn-Secondary "Cancelar" (sin relleno, borde blanco). En Panel
            Admin: Btn-Primary "+ Alta espacio". En P-03: Btn-Primary "Ir al listado" y
            Btn-Secondary "Crear otro". Botones por card: Editar y Baja.

        ● Campos / Inputs: Dropdown-Sede (4 sedes: Morón, Ramos Mejía, San Justo,
            Castelar), Dropdown-Deporte (Fútbol, Tenis, Paddle, Hockey, Vóley, Golf),
            Dropdown-Tipo (dependiente del deporte seleccionado: ej. Fútbol →
            F5/F7/F11), Input-Precio con prefijo "$" y validación numérica. Estados:
            normal, focus (borde neón), error (borde rojo).

        ● Tarjetas: Card-Espacio (usada en el listado del Panel Admin, con ícono, nombre
            compuesto, tipo, precio y botones Editar/Baja). Card-PreviewNombre (bloque
            destacado con el nombre auto-generado: bordes punteados si incompleto,
            sólidos si confirmado). Card-SuccessModal (modal centrado con ícono ✓, título,
            chip con el nombre creado y botones de acción).

        ● Mensajes / Feedback: Toast-Success para alta exitosa (P-03) con mensaje
"¡Espacio deportivo creado!". Snackbar-Error para duplicados (Alt-1) y
errores de conexión (Alt-3), banner rojo en la parte superior. Inline-Error para
campos obligatorios (Alt-2), mensaje "⚠ Este campo es obligatorio" debajo del
campo, en rojo.
```

## Scenarios

- [ ] REV-05-H19-01 — el catálogo de deportes ofrece Básquet con su tipo de cancha
- [ ] REV-05-H19-02 — el administrador da de alta una cancha de Básquet
- [ ] REV-05-H19-03 — el socio filtra los espacios por Básquet
- [ ] REV-05-H19-04 — la app muestra Básquet con su ícono y su foto

## Contradictions within the card

Sin resolver: qué dice cada lado y dónde está. La resolución va en el plan.

- El hallazgo 19 y CU-21-SUP-04 dicen que el catálogo no incluye Básquet (CU-21-SUP-04: «Fútbol …, Tenis …, Pádel …, Vóley …, Hockey … y Golf …»; `GET /espacios/catalogo` devuelve Futbol, Tenis, Padel, Voley, Hockey y Golf) · specs/REVISION-kit3.md líneas 193-197 y specs/CU-21-alta-de-espacio/ambiguedades.md línea 43. El enunciado (Requerimiento 5) dice «Permitir filtrar los espacios deportivos por tipo (Fútbol, Paddle, Básquet, etc.)» · Trabajo Práctico_2026.docx.pdf. El CU-13 dice en su selector «"Fútbol", "Pádel", "Tenis", "Básquet", etc.» · CU/CU-13 - Consultar Canchas.pdf. El pedido dice «el catálogo de deportes deja afuera Básquet».
- CU-13-AMB-09 (pregunta abierta, línea 26) pregunta si el club tiene «pádel y básquet»; su línea «resuelta» (línea 34) dice «deporte y tipo salen de un catálogo fijo» y no nombra ningún deporte. La línea 37 de CU-21-ambiguedades (CU-21-AMB-08 · resuelta) repite el mismo texto genérico y tampoco nombra deportes. · specs/CU-13-consultar-canchas/ambiguedades.md líneas 26 y 34; specs/CU-21-alta-de-espacio/ambiguedades.md línea 37.
- Dentro de CU-21: «¿Qué problema resuelve?» menciona «canchas de fútbol, paddle, básquet, etc.», pero el dropdown Deporte (Pantalla 6, y Dropdown-Deporte en Componentes) lista «Fútbol, Tenis, Paddle, Hockey, Vóley, Golf», sin Básquet. · CU/CU-21 - Alta Espacio Deportivo.pdf.
- Dentro de CU-21: el dropdown Tipo para Fútbol se describe como «F5/F7/F11» (Componentes), y el catálogo de CU-21-SUP-04 incluye Fútbol con F5, F7, F8 y F11. · CU/CU-21 - Alta Espacio Deportivo.pdf y specs/CU-21-alta-de-espacio/ambiguedades.md línea 43.
- Nombre del deporte de pádel: «Paddle» en el enunciado y en CU-21 (dropdown); «Pádel» en CU-13 y en CU-21-SUP-04; «Padel» en `GET /espacios/catalogo` (hallazgo 19). Nombres transcriptos tal como aparecen en cada fuente.
- CU-21-AMB-08 pregunta «¿cuál es el catálogo cerrado de deportes y tipos, y quién lo mantiene? (ver CU-13-AMB-09 y CU-20-AMB-04)», pero CU-20-AMB-04 no fue leído (ver not_read).
