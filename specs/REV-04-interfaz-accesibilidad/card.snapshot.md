---
card: REV-04
extracted: 2026-10-20T21:46:12-03:00
sources:
  - "REVISION-kit3.md · D:/Temp/w/rev04/specs/REVISION-kit3.md @ 138bc54 · líneas 1-5 y hallazgos 17, 18 y 27 (completos)"
  - "pedido (texto) · pedido del coordinador, recibido como texto en la sesión"
  - "enunciado · D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf · pdftotext -enc UTF-8 -layout, texto entero"
  - "CU-03 Registrar usuario · D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-03 Registrar usuario.pdf · pdftotext -enc UTF-8 -layout, entero"
  - "CU-09 Reservar cancha · D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-09_Reservar_cancha_MartinGaser .pdf · pdftotext -enc UTF-8 -layout, entero"
  - "CU-11 Modificar reserva · D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-11 - Modificar reserva.md · leído como texto (Read), entero"
  - "CU-12 Consultar horarios disponibles · D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-12 - Consultar horarios disponibles.pdf · pdftotext -enc UTF-8 -layout, entero"
  - "CU-17 Alta de sede · D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-17-Alta de sede.docx.pdf · pdftotext -enc UTF-8 -layout, entero"
  - "CU-18 Editar sede · D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-18 - Editar sede.md · leído como texto (Read), entero"
  - "CU-21 Alta de espacio deportivo · D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-21 - Alta Espacio Deportivo.pdf · pdftotext -enc UTF-8 -layout, entero"
not_read:
  - "figuras e imágenes de los PDF del enunciado y de los CU (pantallas de Figma y capturas): pdftotext extrae sólo texto y no se abrieron las páginas como imagen; afecta sobre todo a CU-09 (pantallas 1 a 3), CU-12 (pantallas 1 a 6 con capturas), CU-17 (capturas del flujo) y CU-21 (pantallas P-01 a P-03 y Alt-1 a Alt-3)"
  - "Figma, citado por los CU como «Resolución en Figma»: no consultado; el pedido sólo indicó archivos locales"
  - "Jira: no consultado; la card llega como texto, sin ticket"
  - "código citado dentro de los hallazgos (lib/…, apps/api/…): no abierto; este snapshot transcribe los hallazgos y no verifica el código"
  - "resto de REVISION-kit3.md (hallazgos 1 a 16, 19 a 26 y 28 y secciones siguientes): leído completo con Read pero no transcrito, porque el pedido sólo incluía las líneas 1-5 y los hallazgos 17, 18 y 27"
  - "CU de CU/ y CU-nuevos/ distintos de CU-03, CU-09, CU-11, CU-12, CU-17, CU-18 y CU-21 (por ejemplo CU-01, CU-02, CU-04, CU-04b, CU-05 a CU-08, CU-10, CU-13 a CU-16, CU-19, CU-20, CU-22 a CU-24.3): fuera del pedido, no abiertos"
  - "CU/Distribucion CUs.jpeg: fuera del pedido, no abierto"
status: proposed
---

# Snapshot — REV-04 · interfaz y accesibilidad

Escrito una vez; no se edita. Si la card cambia, se renombra a `card.snapshot.<fecha>.md` y se escribe uno nuevo.
`status: proposed` significa: lo escribió un modelo y ninguna persona lo aprobó.

Transcripción sin interpretación, con la fuente de cada bloque. Los bloques están en español o en el idioma de su
fuente (el enunciado y los CU están en español; el hallazgo y el pedido, también). Se omitieron sólo los caracteres
de ancho cero (U+200B) que pdftotext extrae de las viñetas y del encabezado de CU-17; no tienen contenido visible.

## Card, as written

### Bloque 1 · encabezado de REVISION-kit3.md (líneas 1-5)

Fuente: `D:/Temp/w/rev04/specs/REVISION-kit3.md` @ 138bc54, líneas 1 a 5.

```text
# Revisión general · ClubNahuelMosse · kit SDD 3.0.0 · grado production

Rama `kit-3` @ 932cf77 · 2026-10-20 · módulos activos: ui, api, data, infra, observability, security-l2 (ci, docs e
i18n apagados por decisión). Revisión de la app entera —API, app Flutter, datos, despliegue y seguridad— contra los
177 criterios activos de `node .claude/tools/bar.mjs`. No se corrigió código ni se abrieron cards.
```

### Bloque 2 · hallazgos 17, 18 y 27 de REVISION-kit3.md

Fuente: `D:/Temp/w/rev04/specs/REVISION-kit3.md` @ 138bc54, líneas 174 a 179 (hallazgo 17), 181 a 191 (hallazgo 18) y
263 a 270 (hallazgo 27). Sin líneas intermedias.

Hallazgo 17 (fuente: REVISION-kit3.md, líneas 174-179):

```text
17. El registro no muestra qué falta al enviar · I22 · falló · medido
    - `apps/mobile/lib/usuarios/pantalla_registro.dart:67-68,117-119,331`: al salir de un campo vacío aparece el error,
      CREAR CUENTA está deshabilitado, y tocarlo con el formulario vacío muestra 0 errores.
    - Contradice CU-03 FA1 («presiona crear cuenta → se muestran los campos faltantes»). La edición de sede repite el
      patrón (`admin/pantalla_formulario_sede.dart:90-91,491`) y el alta no: dos formularios iguales se comportan
      distinto.
```

Hallazgo 18 (fuente: REVISION-kit3.md, líneas 181-191):

```text
18. Accesibilidad de formularios, avisos y diálogos · I7, I20, I24, I9 · falló · medido
    - **I7:** el error de cada campo es un nodo aparte, y el formato esperado («DD / MM / AAAA») queda oculto para el
      lector (`lib/comun/campo_texto.dart:66-70,83-93,117-143`; igual en `selector.dart:104-129`). Afecta a todos los
      formularios.
    - **I20:** el rechazo de una reserva sale en un SnackBar de 4 s y la pantalla vuelve atrás al mismo tiempo
      (`lib/reservas/pantalla_confirmar_reserva.dart:93-96`, `pantalla_confirmar_cambio.dart:88-90`).
    - **I24:** en las confirmaciones irreversibles ningún botón tiene `autofocus` y el primer Tab cae en el destructivo
      (`lib/comun/dialogo_error.dart:316-345`).
    - **I9:** con el texto al 200 %, la barra inferior corta «RESERVAS» en «RESERV», y en el panel de admin «ESPACIOS»
      toca el borde (`lib/comun/barra_inferior.dart:137-141`).
    - I7, I20 e I24 salen de sondas de semántica y foco en widget tests; falta el recorrido real con TalkBack.
```

Hallazgo 27 (fuente: REVISION-kit3.md, líneas 263-270):

```text
27. Interfaz menor · I1, I26 · falló
    - El botón `atenuado` en modo oscuro da 4,06:1 con 15 px en negrita, debajo de AA (`lib/comun/boton.dart:44-47`;
      GUARDAR SEDE y GUARDAR ESPACIO).
    - Las fechas y la plata se arman a mano: −3 h fijo, sin zona IANA, sin `DateFormat` con locale ni ISO 4217
      (`lib/reservas/fechas.dart`, `reservas.dart:110`). `lib/comun/calendario.dart:11` toma el día del dispositivo, no el
      del club.
    - 24 capturas commiteadas cambian al regenerarlas porque dependen de la fecha del día, y 6 de alta de espacio fallan
      a 320×568, sin analizar.
```

### Bloque 3 · pedido del coordinador

Fuente: pedido (texto). Llegó como texto en el mensaje de la sesión; no hay otro documento.

```text
Corregir los hallazgos 17 (registro: CU-03 FA1), 18 (error atado al campo, SnackBar de rechazo, foco en Cancelar, barra al 200 %) y 27 (contraste del botón atenuado, día del club, capturas que dependen de la fecha) siguiendo el kit. Archivos principales: lib/comun/*, lib/usuarios/pantalla_registro.dart, lib/admin/pantalla_formulario_sede.dart, lib/reservas/pantalla_confirmar_*.dart. Mover la llamada HTTP fuera de PantallaRegistro es de otra card (arquitectura).
```

### Bloque 4 · enunciado

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/Trabajo Práctico_2026.docx.pdf`, con
`pdftotext -enc UTF-8 -layout`, texto entero.

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

### Bloque 5 · CU-03 Registrar usuario

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-03 Registrar usuario.pdf`, con
`pdftotext -enc UTF-8 -layout`, entero.

```text
ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Gonzalo Gil
Matrícula: 5301-1995
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): Registrarse en la aplicacion
Definición General del Caso de Uso

     ● Nombre del Caso de Uso: Registrarse en la aplicacion

     ● ID / Código: CU-03

     ● Actor(es) Principal(es): Usuario

     ● Objetivo: Permitir que un nuevo usuario cree una cuenta dentro de la aplicación móvil
        ingresando su nombre, apellido, dni, fecha de nacimiento, correo electrónico y contraseña,
        para así poder acceder a la plataforma y realizar reservas deportivas.

     ● ¿Qué problema resuelve?: Resuelve la necesidad de autenticar e identificar de manera
        única a los usuarios en el sistema, permitiéndoles acceder a funcionalidades personalizadas
        como la consulta de disponibilidad, gestión de reservas y edición del perfil de usuario.

Precondiciones y Poscondiciones

Precondiciones

     ● La aplicación móvil debe estar instalada y ejecutándose en el dispositivo.
     ● El dispositivo debe contar con conexión activa a internet.

Poscondiciones (Estado final del sistema)

     ● Se crea con éxito la cuenta del usuario en la base de datos y backend del sistema.
     ● El sistema devuelve al usuario a la pantalla de login

Flujo Principal (Camino Feliz)

               Paso          Acción del Actor           Respuesta / Validación del
1                                                                   Sistema
                     El usuario selecciona la opción
2                    para registrarse.                 El sistema muestra el
3                                                      formulario de registro
                     El usuario ingresa los datos y    solicitando nombre, apellido,
                     presiona el botón de "crear       dni, fecha de nacimiento,
                     cuenta".                          correo electrónico y
                     El backend procesa la             contraseña.
                     solicitud, crea el nuevo perfil   El sistema valida el formato de
                     de usuario y autentica la sesión  los datos ingresados y envía la
                                                       solicitud al servidor/backend.
                                                       El sistema notifica al usuario
                                                       que su cuenta fue registrada
                                                       con exito

4                    El usuario presiona el boton de El sistema carga la pantalla de

                     “Volver al login”                 inicio de sesion de la

                                                       aplicacion
Flujos Alternativos y Excepciones

Flujo Alternativo 1: Datos incompletos

     ● Paso de origen: Paso 2 del flujo principal.
     ● Condición: Falta completar algún campo obligatorio.
     ● Acción del sistema: Se muestra un mensaje/tooltip en pantalla indicando los campos

        faltantes

Flujo Alternativo 2: Usuario ya registrado

     ● Paso de origen: Paso 3 del flujo principal
     ● Condición: El correo electrónico y/o el dni ingresado ya se encuentra registrado

        previamente en la base de datos del sistema
     ● Acción del sistema: El sistema retorna un mensaje de error indicando que el usuario ya está

        registrado, permaneciendo en la pantalla de registro para permitir modificar los datos.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas

     ● Pantalla 1: [Pantalla de login]
● Pantalla 2: [Pantalla de inicio de registro]
● Pantalla 3: [Registro – datos parciales]
● Pantalla 4: [Registro – error campos vacios]
● Pantalla 5: [Registro – datos ingresados]
● Pantalla 6: [Registro – usuario ya registrado]
● Pantalla 7: [Registro – usuario cambia email y dni]
● Pantalla 8: [Registro – exitoso]
Componentes del Sistema de Diseño Utilizados

     ● Criterio Unificado:
              ● Botones: Boton "Crear cuenta” con los datos ingresados, boton “Volver” para
                 regresar a la pantalla de login y boton “volver al login” para regresar a la pantalla de
                 login

              ● Campos / Inputs: Campos para ingresar el nombre, apellido, dni, email y contraseña

              ● Mensajes / Feedback: mensaje de error al no completar todos los campos o al
                 intentar registrar un usuario ya existente
```

### Bloque 6 · CU-09 Reservar cancha

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-09_Reservar_cancha_MartinGaser .pdf`,
con `pdftotext -enc UTF-8 -layout`, entero.

```text
ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Martín Gaser
Matrícula: 5501-2072
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-09: Reservar cancha
Nota: Todos los integrantes del equipo deben utilizar este mismo formato para
mantener el criterio unificado de presentación exigido para la entrega en PDF.

Definición General del Caso de Uso

    ● Nombre del Caso de Uso: Reservar cancha
    ● ID / Código: CU-09
    ● Actor(es) Principal(es): Usuario registrado
    ● Objetivo: Permitir que el usuario registrado reserve una cancha disponible,

         eligiendo sede, cancha, fecha y horario, para asegurarse su turno de juego.
    ● ¿Qué problema resuelve?: Elimina la necesidad de reservar turnos de forma

         manual o telefónica, permitiendo al usuario autogestionar su reserva en tiempo
         real y evitando superposiciones de horarios en una misma cancha.

Precondiciones y Poscondiciones

Precondiciones
    ● El usuario debe estar autenticado en la plataforma.
    ● Debe existir al menos una sede cargada y habilitada.
    ● La cancha debe estar en estado "Habilitada" y tener horarios cargados.

Poscondiciones (Estado final del sistema)
    ● La reserva queda registrada en estado "Confirmada", asociada al usuario, la
         cancha, la fecha y el horario elegidos.
    ● Se descuenta la disponibilidad de ese horario para esa cancha y fecha,
         quedando bloqueado para otros usuarios.
    ● Se envía una notificación/correo de confirmación de la reserva al usuario.

Flujo Principal (Camino Feliz)

Paso Acción del Actor             Respuesta / Validación del Sistema

1  El usuario selecciona la sede  El sistema carga y muestra las
   deseada.                       canchas disponibles para esa sede.

2  Selecciona la cancha deseada.  El sistema habilita el selector de fecha
                                  y muestra el calendario de
3  Selecciona la fecha deseada.   disponibilidad.

                                  El sistema consulta y despliega las
                                  franjas horarias disponibles para esa
                                  cancha y fecha.
Paso Acción del Actor              Respuesta / Validación del Sistema

4  Selecciona el horario deseado.  El sistema habilita el botón "Confirmar
                                   Reserva" y muestra el resumen
5  Presiona "Confirmar Reserva".   (cancha, fecha, horario y costo).

                                   El sistema valida los datos, registra la
                                   reserva en estado "Confirmada" e
                                   informa la confirmación al usuario.

Flujos Alternativos y Excepciones

Flujo Alternativo 1: Horario No Disponible

     ● Paso de origen: Paso 4 del flujo principal.
     ● Condición: El horario seleccionado para la cancha ya no se encuentra libre (otro usuario lo

          reservó primero).
     ● Acción del sistema: Muestra un mensaje de advertencia "El horario seleccionado ya no está

          disponible. Por favor elija otro turno", deshabilita el botón de confirmación y actualiza la grilla de
          horarios disponibles.

Flujo Alternativo 2: Datos Incompletos o Inválidos
    ● Paso de origen: Cualquier paso del flujo.
    ● Condición: Falta seleccionar algún campo obligatorio (ej. cancha, fecha u
         horario sin elegir).
    ● Acción del sistema: El botón "Confirmar Reserva" permanece deshabilitado
         (disabled). Se muestra un tooltip o mensaje indicando el campo faltante.

Flujo Alternativo 3: Usuario No Autenticado
    ● Paso de origen: Al intentar ingresar al flujo de reserva de cancha.
    ● Condición: La sesión del usuario expiró o no ha iniciado sesión.
    ● Acción del sistema: Redirecciona a la pantalla de Login, guardando el estado o
         intención previa de reserva de cancha.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas
● Pantalla 1: Confirmá tu reserva

    Muestra en pantalla a través de una tarjeta la cancha que se esta reservando, el
    día, el horario y el precio y el botón para confirmar la reserva.
● Pantalla 2: Comprobante de Reserva Confirmada
    En esta pantalla nos muestra que nuestra reserva ya fue confirmada, y
    automaticamente te redirige a la sección en la aplicación de tus reservas.

● Pantalla 3: Variantes en Modo Nocturno
Componentes del Sistema de Diseño Utilizados
● Criterio Unificado: Estilo visual sobre interfaz clara/blanca en la vista de
    confirmación, manteniendo como color de acento principal el verde lima
    (#D4FF3D) para acciones primarias y estados activos, texto oscuro/negrito para
    los títulos e información clave, gris intermedio para las etiquetas secundarias, y
    rojo para las acciones destructivas o de cancelación. AppBar-Simple: Barra
    superior con botón circular de "volver" y título en negrita (ej. "Confirmá tu
    reserva")

● AppBar-Simple: Barra superior de navegación en fondo claro que incluye el
    botón de retroceso (<) y el título principal en negrita "Confirmá tu reserva".

● Stepper de progreso: Componente Stepper-Progreso de 3 pasos (1. Elegí
    cancha / 2. Confirmás / 3. ¡Listo!), con ícono de check en lima sobre los pasos
    completados, número dentro de círculo lima resaltando el paso activo, y línea de
    progreso lima entre pasos cumplidos (gris en los pendientes)

● Link-Breadcrumb: Enlace de retorno interno (< Sedes) situado dentro de la
    cabecera de la tarjeta para navegar hacia atrás sin perder la referencia de la
    ubicación.

● Card-Reserva: Componente de tarjeta estructurado como resumen de reserva,
    compuesto por:

○ Header visual: Banner superior con imagen temática, superposición

azulada, etiqueta de categoría     (FÚTBOL - FÚTBOL 5) y el

nombre destacado de la sede (SEDE MORÓN).

○ Cuerpo de información: Contenedor claro con bordes redondeados y
    división por líneas horizontales.

● Row-DetalleReserva: Filas de información estructuradas con la etiqueta en gris
    a la izquierda (Cancha, Fecha, Horario, Total) y los valores alineados a la
    derecha en tipografía oscura en negrita. La fila Total resalta su valor ($7.600)
    utilizando el color de acento verde lima.

● Botones (Acciones principales):

○ Btn-Primary: Botón de acción principal de ancho completo en color verde
    lima (#D4FF3D), esquinas redondeadas y texto en negrita negra:
    "CONFIRMAR RESERVA".

○ Btn-Outline-Danger: Botón secundario de cancelación de ancho completo
    con fondo transparente, contorno rojo y texto rojo: "Cancelar".
```

### Bloque 7 · CU-11 Modificar reserva

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-11 - Modificar reserva.md`,
leído como texto (Read), entero. Es Markdown; se transcribe tal cual, sin renderizar.

```text
# CU-11 · Modificar reserva

**Módulo:** Reservas · **Actor principal:** Usuario registrado
**Alumno asignado:** Sofía Mailén Granero
**Estado:** es el único caso de uso de la lista que no tenía **ni especificación en PDF ni diseño en el Figma grupal**. Se derivó de CU-09, CU-12 y las reglas de negocio del enunciado.

## Objetivo
Permitir que el usuario cambie la fecha o el horario de una reserva vigente sin tener que cancelarla y volver a crearla, liberando el turno anterior solo cuando el nuevo queda confirmado.

## Problema que resuelve
Si el usuario tiene que cancelar y reservar de nuevo, corre el riesgo de perder el horario anterior sin conseguir el nuevo, porque entre una operación y la otra alguien más puede tomarlo. Modificar resuelve las dos cosas en una sola transacción.

## Precondiciones
- El usuario tiene la sesión iniciada.
- Existe al menos una reserva en estado Activa, con fecha y horario futuros.
- El espacio deportivo sigue habilitado y su sede también.

## Postcondiciones
- La reserva conserva su identificador: se modifica, no se crea otra.
- El horario anterior queda liberado y disponible para otros usuarios.
- El horario nuevo queda bloqueado a nombre del usuario.
- Si no se pudo tomar el horario nuevo, **la reserva queda exactamente como estaba**.

## Reglas de negocio que hereda del enunciado
- El horario nuevo tiene que ser futuro respecto del momento de la modificación.
- Inicio y fin en horas completas, mínimo una hora (Requerimientos Funcionales, punto 3).
- El fin no puede superar el horario de cierre de la sede.
- El horario nuevo no puede superponerse con otra reserva del mismo espacio. **La validación la hace el backend**, igual que en CU-09.
- Una reserva cuyo horario ya empezó o ya pasó no se puede modificar.

## Flujo principal

| # | Acción del usuario | Respuesta del sistema |
|---|---|---|
| 1 | En "Mis reservas", presiona "Modificar" en una reserva activa. | Abre la grilla de horarios del mismo espacio, con un aviso de que se está modificando y con el horario actual marcado como disponible. |
| 2 | Elige otra fecha o toca otra franja libre. | Marca la franja nueva y actualiza el resumen. |
| 3 | Presiona "Continuar con el cambio". | Muestra la pantalla de confirmación con la comparación Antes / Ahora. |
| 4 | Revisa el cambio y presiona "Guardar el cambio". | Valida contra el backend, libera el horario anterior, bloquea el nuevo y vuelve a Mis reservas con la reserva actualizada. |

## Flujos alternativos
- **FA1 · El usuario desiste** (origen pasos 3 y 4). Presiona "Dejar la reserva como está". El sistema vuelve a Mis reservas sin tocar nada.
- **FA2 · El horario nuevo se ocupó mientras elegía** (origen paso 4). El backend rechaza el cambio. El sistema informa que ese horario ya no está disponible, **conserva la reserva original intacta** y vuelve a la grilla con la disponibilidad actualizada.
- **FA3 · No eligió un horario distinto** (origen paso 3). El botón permanece deshabilitado: no tiene sentido guardar un cambio que no cambia nada.
- **FA4 · La reserva dejó de ser modificable** (origen paso 4). El horario ya empezó, o un administrador la anuló (CU-15), o se dio de baja el espacio (CU-23). El sistema informa que ya no se puede modificar y recarga el listado.
- **FA5 · Error de conexión o del servidor** (origen paso 4). Se abre el overlay compartido correspondiente. La reserva queda como estaba.

## Relación con otros casos de uso
- Reutiliza la grilla de **CU-12** en modo edición, distinguida por la variable de prototipo `modo-reserva`.
- Comparte la tarjeta de reserva con **CU-08**, donde se agregó la acción "Modificar" junto a "Cancelar".
- No dispara la notificación de **CU-24.2**, porque el cambio lo hace el propio usuario y no el club.

## Pantallas
`CU-11 · Modificar reserva · Elegir nuevo horario` · `CU-11 · Modificar reserva · Confirmar cambio`

## Componentes
`Card-Reserva` con la acción "Modificar" · `Snackbar` Info con el aviso de modificación · `Slot-Horario` · `Chip-Fecha` · `Segmented` de duración · filas Antes / Ahora con `Icon/x` e `Icon/check` · `Btn` Primary y Outline-Danger.

## Mensajes
- "Estás modificando tu reserva del Mié 12, 21:00 – 22:00. El horario anterior se libera al guardar."
- "El horario seleccionado ya no está disponible. Tu reserva original no se modificó."
```

### Bloque 8 · CU-12 Consultar horarios disponibles

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-12 - Consultar horarios disponibles.pdf`,
con `pdftotext -enc UTF-8 -layout`, entero. Los pies de página repetidos del PDF se transcriben donde aparecen.

```text
ESPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Martiniano Hereñu
Matrícula: 53010288
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-12: Consultar horarios disponibles
Nota: Todos los integrantes del equipo deben utilizar este mismo formato para mantener el criterio unificado de
presentación exigido para la entrega en PDF.

Definición General del Caso de Uso

    • Nombre del Caso de Uso: Consultar horarios disponibles
    • ID / Código: CU-12
    • Actor(es) Principal(es): Usuario registrado
    • Objetivo: Mostrar al usuario las franjas horarias libres de un espacio deportivo —pudiendo filtrar
    por cancha (cuando el espacio tiene más de una del mismo tipo), fecha y duración—, respetando
    el horario de funcionamiento de la sede, para que pueda decidir si quiere reservar.
    • ¿Qué problema resuelve?: El usuario necesita saber, antes de reservar, qué horarios están
    realmente disponibles —libres, dentro del horario de la sede y en el futuro— para un espacio
    deportivo, evitando intentar reservar sobre horarios inválidos u ocupados.

Precondiciones y Poscondiciones

Precondiciones
    • El usuario debe estar autenticado en la aplicación.
    • Debe existir al menos una sede con espacios deportivos habilitados.
    • El usuario ya se encuentra en la pantalla de horarios de un espacio deportivo (sede y espacio
    ya elegidos).

Poscondiciones (Estado final del sistema)
    • El sistema muestra la grilla de horarios disponibles para el espacio, la fecha y la duración
    seleccionados.
    • Si el usuario seleccionó una franja, el sistema la refleja en la tarjeta de resumen y habilita la
    continuación hacia la reserva.
    • Ninguno de estos pasos modifica el estado del sistema: la selección no crea, bloquea ni
    reserva horarios (sigue siendo, hasta acá, una operación de solo lectura). La creación y
    confirmación de la reserva quedan a cargo de un caso de uso distinto.

Flujo Principal (Camino Feliz)

Paso                            Acción del Actor  Respuesta / Validación del Sistema

1     El usuario ingresa a la pantalla El sistema muestra la grilla de horarios

      de horarios del espacio                     con los valores por defecto (cancha

      deportivo.                                  única o principal, fecha actual,

                                                  duración de 1 hora): habilita las franjas

                                                  de hora completa libres y futuras, y

                                                  muestra deshabilitadas las ya

                                                  ocupadas, dentro del horario de la

                                                  sede.

Gestión de espacios deportivos                    CU-12 · Consultar horarios disponibles · Martiniano Hereñu
2  El usuario toca una franja    El sistema marca la franja
                                 seleccionada y actualiza la tarjeta de
   horaria disponible.           resumen (espacio, precio, horario
                                 elegido y total), habilitando el botón de
                                 acción.

3  El usuario presiona el botón  El sistema da lugar al caso de uso

   habilitado.                   Reservar cancha, transfiriéndole la

                                 sede, el espacio, la fecha y el horario

                                 seleccionados. Aclaración: seleccionar

                                 una franja no modifica el estado del

                                 sistema (no crea la reserva); la

                                 creación y confirmación de la reserva

                                 corresponden a ese caso de uso.

Flujos Alternativos y Excepciones

Flujo Alternativo 1: El usuario cambia la fecha de consulta
    • Paso de origen: Paso 1 del flujo principal
    • Condición: El usuario quiere ver la disponibilidad en otro día.
    • Acción del sistema: El sistema recalcula y muestra la grilla de horarios para la fecha elegida,
    respetando las mismas reglas (horas completas, dentro del horario de la sede, futuras, libres
    habilitadas y ocupadas deshabilitadas).

Flujo Alternativo 2: El usuario cambia la cancha consultada
    • Paso de origen: Paso 1 del flujo principal
    • Condición: El espacio tiene más de una cancha del mismo tipo (ej. Cancha 1 / Cancha 2) y el
    usuario quiere ver la disponibilidad de otra.
    • Acción del sistema: El sistema recalcula y muestra la grilla de horarios correspondiente a la
    cancha elegida.

Flujo Alternativo 3: El usuario cambia la duración de la consulta
    • Paso de origen: Paso 1 del flujo principal
    • Condición: El usuario quiere consultar franjas de 2 horas en lugar de 1.
    • Acción del sistema: El sistema recalcula las franjas disponibles: para 2 horas, solo habilita
    inicios cuya franja siguiente también esté libre y cuya finalización no supere el cierre de la sede.

Flujo Alternativo 4: No hay horarios disponibles para la combinación elegida
    • Paso de origen: Paso 1 del flujo principal, o tras los Flujos Alternativos 1 a 3
    • Condición: Para la cancha, fecha y duración vigentes no queda ninguna franja libre —ya sea
    porque todas están ocupadas, la sede no opera ese día, o, tratándose de 2 horas, no hay dos
    franjas contiguas libres antes del cierre.
    • Acción del sistema: El sistema reemplaza la grilla por un estado vacío indicando que no hay
    horarios disponibles y sugiere cambiar la fecha. No se habilita ninguna franja.

Gestión de espacios deportivos   CU-12 · Consultar horarios disponibles · Martiniano Hereñu
Flujo Alternativo 5: Error de conexión a Internet
    • Paso de origen: Paso 1 del flujo principal (al cargar los horarios)
    • Condición: El sistema detecta falta de conectividad.
    • Acción del sistema: Muestra una alerta de falta de conexión y solicita reintentar una vez
    reestablecida. No se muestran horarios.

Flujo Alternativo 6: Error en el servidor / falla en la API
    • Paso de origen: Paso 1 del flujo principal (al cargar los horarios)
    • Condición: La petición HTTP al backend falla.
    • Acción del sistema: Informa el error del servidor y solicita reintentar más tarde. No se
    muestran horarios.

Justificación de Decisiones de Diseño

    • El selector de cancha se integra en la misma pantalla de horarios, no en una pantalla aparte: al
    ser un filtro más de la consulta —igual que fecha y duración— no amerita una navegación extra.
    • El selector de fecha siempre arranca en el día actual y muestra los próximos días en chips
    horizontales, evitando que el usuario pueda elegir una fecha pasada.
    • La duración se elige con un toggle simple (1 hora / 2 horas) en lugar de un selector de horario
    libre, reflejando la regla del negocio: las reservas son de hora completa, con un mínimo de 1
    hora.
    • La grilla no diferencia visualmente los horarios ocupados de los disponibles —comparten el
    mismo estilo— y la nota “Algunos horarios están ocupados · N no disponibles” informa la
    proporción general sin sobrecargar la vista con estados adicionales por celda.
    • Cuando no queda ningún horario disponible, la grilla se reemplaza por un estado dedicado
    (“No hay horarios disponibles”) con una sugerencia concreta de acción —cambiar de fecha—, en
    vez de dejar al usuario con una pantalla vacía sin guía.
    • El botón principal permanece deshabilitado mientras no exista una selección válida, evitando
    que el usuario avance con datos incompletos.
    • Los mensajes de error (conexión y servidor) comparten el mismo formato de tarjeta —título en
    rojo, texto explicativo y botón “Aceptar”—, dando previsibilidad al usuario ante cualquier falla del
    sistema, sin importar la causa.

Diseño UX/UI (Resolución en Figma)

Pantallas y Vistas Involucradas
Ejemplo de referencia: Sede Morón, Fútbol 5. La Pantalla 1 (flujo principal) usa la Cancha 1 por
defecto; cada Flujo Alternativo se documenta con una captura real, en modo claro.

Gestión de espacios deportivos  CU-12 · Consultar horarios disponibles · Martiniano Hereñu
                                Pantalla 1 — Flujo Principal (Sede Morón, Fútbol
                                             5, Cancha 1, Mié 12, 1 hora)

Gestión de espacios deportivos  CU-12 · Consultar horarios disponibles · Martiniano Hereñu
                                Flujo Alternativo 1 — Cambio de fecha (Cancha
                                                      1, Jueves 13)

Gestión de espacios deportivos  CU-12 · Consultar horarios disponibles · Martiniano Hereñu
                                Flujo Alternativo 2 — Cambio de cancha (Cancha
                                                     2, Mié 12, 1 hora)

Gestión de espacios deportivos  CU-12 · Consultar horarios disponibles · Martiniano Hereñu
                                Flujo Alternativo 3 — Cambio de duración
                                              (Cancha 1, 2 horas)

Gestión de espacios deportivos  CU-12 · Consultar horarios disponibles · Martiniano Hereñu
                                Flujo Alternativo 4 — No hay horarios disponibles
                                                 (Cancha 2, Jueves 13)

                                Flujo Alternativo 5 — Error de conexión a Internet

                                                         Flujo Alternativo 6 — Error del servidor

Componentes del Sistema de Diseño Utilizados

Gestión de espacios deportivos  CU-12 · Consultar horarios disponibles · Martiniano Hereñu
Criterio Unificado:
Botones / Controles:

    • Selector de fecha (chips de días).
    • Toggle de duración “1 hora / 2 horas”.
    • Tarjetas de franja horaria con estados: disponible, no disponible/deshabilitada.
    • Botón principal deshabilitado hasta que exista una selección válida.
    • Botón “Aceptar” para cerrar los mensajes de error.
Mensajes / Feedback:
    • Nota informativa “Algunos horarios están ocupados · N no disponibles”.
    • Estado vacío “No hay horarios disponibles”.
    • Mensaje de error de conexión a Internet.
    • Mensaje de error del servidor.
Modos: la aplicación contempla modo claro y modo oscuro para todas las pantallas del caso de uso.

Gestión de espacios deportivos  CU-12 · Consultar horarios disponibles · Martiniano Hereñu
```

### Bloque 9 · CU-17 Alta de sede

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-17-Alta de sede.docx.pdf`, con
`pdftotext -enc UTF-8 -layout`, entero.

```text
E SPECIFICACIÓN DE CU

Nombre del Proyecto / Sistema: Gestión de espacios deportivos
Nombre del Alumno: Jonatan Medrano
Matrícula: 54010094
Fecha de Entrega: 08-09-2026
Caso(s) de Uso Asignado(s): CU-17: Alta de sede (admin)
Definición General del Caso de Uso

 • Nombre del Caso de Uso: Alta de sede (admin)
 • ID / Código: CU-17
 • Actor Principal: Administrador
 • Objetivo: Permitir que un administrador registre una nueva sede al sistema
 • ¿Qué problema resuelve?: Permite expandir la disponibilidad del sistema al incorporar

     nuevas ubicaciones del club, habilitando la carga de su nombre, dirección y horarios
     para que posteriormente los usuarios puedan consultar sus espacios deportivos y
     disponibilidad.

Precondiciones y Poscondiciones

Precondiciones

 • El administrador debe estar autenticado y contar con permisos de administración.

Poscondiciones Estado final del sistema

 • La nueva sede queda registrada permanentemente en la base de datos con su nombre,
     dirección y horarios de funcionamiento.

• La nueva sede pasa a mostrarse en el listado general de sedes.
Flujo Principal Camino Feliz

Paso  Acción del Actor                 Respuesta / Validación del
                                                    Sistema
 1
 2    El administrador accede a la     El sistema valida la sesión y
      sección de "Sedes" o             muestra el listado actual de
 3    "Gestionar Sedes" desde el       sedes del club junto con la
      menú.                            opción "Agregar Sede".

      El administrador presiona el     El sistema despliega el
      botón "Agregar Sede".            formulario de alta, solicitando
                                       los campos obligatorios:
                                       Nombre, Dirección y Horarios
                                       de funcionamiento.

      El administrador completa los    El sistema valida que todos los
      datos (Nombre, Dirección y       campos obligatorios estén
      Horarios) y presiona "Guardar".  completos, confirma el registro,
                                       muestra un mensaje de éxito y
                                       actualiza el listado de sedes
                                       mostrando la nueva
                                       incorporación.
Flujos Alternativos y Excepciones

Flujo Alternativo 1: El administrador desiste

 • Paso de origen: Paso 1 del flujo principal.
 • Condición: El administrador presiona Volver antes de confirmar.
 • Acción del sistema: El sistema descarta los datos ingresados, cierra el formulario y

     retorna a la pantalla del listado de sedes sin realizar cambios .

Flujo Alternativo 2: Faltan datos obligatorios

 • Paso de origen: Paso 3 del flujo principal.
 • Condición: El administrador intenta guardar omitiendo el nombre, la dirección o las

     horarios

 • Acción del sistema: El sistema detiene el envío, resalta en rojo que hay campos

     faltantes e indica que son obligatorios para continuar.

Flujo Alternativo 3: Error al procesar el alta

 • Paso de origen: Paso 3 del flujo principal.
 • Condición: Se pierde la conexión o el servidor devuelve un error.
 • Acción del sistema: El sistema muestra una pantalla o alerta de "Error al guardar la

     sede". El administrador conserva los datos en el formulario y puede pulsar
     "Reintentar" o "Volver".
Diseño UX UI Resolución en Figma

Pantallas y Vistas Involucradas

   ●  Pantalla 1: Listado de Sedes (Admin), mostrando las sedes existentes, sus horarios
         y el botón "Agregar Sede".

   ●  Pantalla 2: Formulario Agregar Sede, con campos vacíos para Nombre, Dirección y
         selectores para Horarios de funcionamiento.

   ●  Pantalla 3: Notificación / Cambio Guardado, confirmando el éxito de la operación.
   ●  Pantalla 4: Error de carga, permitiendo reintentar.

Componentes del Sistema de Diseño Utilizados

    ●  Navegación: Menú lateral o barra de navegación inferior (BottomNav) para
         acceder a Gestión de Sedes.

    ●  Tarjetas: Tarjetas de visualización para el listado de sedes (mostrando nombre,
         dirección, horarios).

    ●  Formulario: Campos de texto (Inputs) para nombre y dirección; selectores
         (Dropdowns o Time pickers) para horarios.

    ●  Botones: "Agregar Sede", "Guardar", "Volver" y "Reintentar".
    ●  Mensajes: Notificaciones tipo Toast o modales para el éxito o error de la operación.
Capturas del flujo

                    ALTA DE NUEVA SEDE

GESTION DE SEDES
Resultado y manejo de errores

CONFIRMA SEDE NUEVA

                     Flujo Alternativo 2: CAMPOS FALTANTES
                                       OBLIGATORIOS
Flujo Alternativo 3: ERROR AL CREAR SEDE
```

### Bloque 10 · CU-18 Editar sede

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU-nuevos/CU-18 - Editar sede.md`, leído como
texto (Read), entero. Es Markdown; se transcribe tal cual, sin renderizar.

```text
# CU-18 · Editar sede (admin)

**Módulo:** Sedes y espacios deportivos · **Actor principal:** Administrador
**Alumno asignado:** Matías Navarro
**Estado:** estaba diseñado en el Figma grupal (32 frames "Editar Sede (Modo Admin)") pero no tenía especificación escrita. CU-19 depende de este caso de uso: su precondición dice textualmente que "el administrador debe haber ingresado a la pantalla de edición de la sede".

## Objetivo
Permitir que el administrador corrija el nombre, la dirección o los horarios de funcionamiento de una sede ya cargada.

## Problema que resuelve
Los datos de una sede cambian: se corrige una dirección mal cargada, se amplía el horario de verano, se renombra la sede. Sin edición habría que dar de baja y volver a crear, lo que arrastraría las reservas asociadas.

## Precondiciones
- El administrador tiene la sesión iniciada con rol de administrador.
- La sede existe y está activa.

## Postcondiciones
- Los datos de la sede quedan actualizados.
- El listado de sedes y las pantallas de usuario reflejan los datos nuevos.
- **Las reservas existentes no se alteran**: siguen apuntando a la misma sede.

## Regla de negocio sobre los horarios
Si el horario de funcionamiento se achica y quedan reservas futuras fuera del nuevo rango, el sistema avisa cuántas son y pide confirmación antes de guardar. Las reservas ya confirmadas se respetan: el enunciado dice que la hora de finalización no puede superar el cierre de la sede, pero esa validación corre al momento de reservar, no en forma retroactiva.

## Flujo principal

| # | Acción del administrador | Respuesta del sistema |
|---|---|---|
| 1 | Desde el panel admin, entra a la pestaña "Sedes". | Muestra el listado de sedes con sus acciones. |
| 2 | Presiona "Editar sede" en una de ellas. | Abre el formulario con los datos actuales cargados. |
| 3 | Modifica uno o más campos. | Valida en vivo y mantiene habilitado "Guardar cambios" mientras los obligatorios estén completos. |
| 4 | Presiona "Guardar cambios". | Guarda, muestra la confirmación y vuelve al listado con los datos nuevos. |

## Flujos alternativos
- **FA1 · El administrador desiste** (origen pasos 3 y 4). Vuelve atrás sin guardar. Los cambios se descartan.
- **FA2 · Vacía un campo obligatorio** (origen paso 3). El campo queda marcado en rojo con el mensaje de obligatorio y "Guardar cambios" se deshabilita.
- **FA3 · Achica el horario y hay reservas afuera** (origen paso 4). El sistema informa cuántas reservas futuras quedan fuera del rango nuevo y pide confirmación explícita.
- **FA4 · La sede fue dada de baja desde otra sesión** (origen paso 4). El sistema informa que la sede ya no está disponible y vuelve al listado.
- **FA5 · Error de conexión o del servidor** (origen paso 4). Overlay compartido; los datos del formulario se conservan para reintentar.
- **FA6 · El administrador da de baja la sede** (origen paso 3). Presiona "Dar de baja la sede" y el control pasa a **CU-19**.

## Pantallas
`CU-18 · Editar sede` · `CU-18 · Editar sede · Campo vacío`
Overlays: `CU-19 · Baja de sede · Confirmar`, error de conexión, error del servidor.

## Componentes
`AppBar` · `Input` de nombre y dirección · `Input` de horarios con `Icon/clock` · `Btn` Primary "Guardar cambios" · `Btn` Outline-Danger "Dar de baja la sede" · `Card-Sede-Admin` en el listado · `Modal` para confirmaciones y errores.

## Mensajes
- "La dirección es obligatoria"
- "Los cambios se guardaron correctamente"
```

### Bloque 11 · CU-21 Alta de espacio deportivo

Fuente: `D:/desktop folders/estudio/Universidad de moron/Electiva general/CU/CU-21 - Alta Espacio Deportivo.pdf`, con
`pdftotext -enc UTF-8 -layout`, entero.

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
errores de conexión (Alt-3), banner rojo en la parte superior. Inline-Error
para campos obligatorios (Alt-2), mensaje "⚠ Este campo es obligatorio" debajo del
campo, en rojo.
```

## Scenarios

- [ ] REV-04-H17-01 — tocar CREAR CUENTA con datos faltantes muestra cuáles faltan
- [ ] REV-04-H17-02 — guardar la edición de una sede con datos faltantes muestra cuáles faltan, igual que el alta
- [ ] REV-04-H18-01 — el lector de pantalla anuncia el error de un campo junto con el campo
- [ ] REV-04-H18-02 — el lector de pantalla anuncia el formato esperado de una fecha
- [ ] REV-04-H18-03 — el rechazo de una reserva queda a la vista hasta que la persona lo lee y lo cierra
- [ ] REV-04-H18-04 — el rechazo de un cambio de reserva queda a la vista hasta que la persona lo lee y lo cierra
- [ ] REV-04-H18-05 — en una confirmación irreversible el foco empieza en la opción que no destruye
- [ ] REV-04-H18-06 — con el texto al 200 % la barra inferior muestra cada destino completo
- [ ] REV-04-H27-01 — el botón atenuado en modo oscuro se lee con contraste suficiente
- [ ] REV-04-H27-02 — el calendario de reservas parte del día del club, no del día del teléfono
- [ ] REV-04-H27-03 — las capturas de pantalla no cambian según el día en que se generan
- [ ] REV-04-H27-04 — el alta de espacio se ve entera en una pantalla de 320 × 568

## Contradictions within the card

Sin resolver. Cada punto dice qué afirma cada lado y dónde está. La resolución va en el plan.

- **H17-02 frente a CU-18 FA2.** H17-02 dice «guardar la edición de una sede con datos faltantes muestra cuáles faltan, igual que el alta». CU-18 FA2 (origen paso 3) dice «El campo queda marcado en rojo con el mensaje de obligatorio y "Guardar cambios" se deshabilita». El hallazgo 17 también describe el botón deshabilitado en la edición (`admin/pantalla_formulario_sede.dart:90-91,491`) y no en el alta. Fuentes: scenario REV-04-H17-02; CU-18 (CU-nuevos/CU-18 - Editar sede.md); REVISION-kit3.md hallazgo 17.
- **Los CU afectados no coinciden entre sí sobre qué pasa al faltar datos.** CU-17 FA2 (alta de sede): «El sistema detiene el envío, resalta en rojo que hay campos faltantes». CU-21 FA2 y CU-09 FA2: el botón de guardar o confirmar «permanece deshabilitado (disabled)». CU-03 FA1: «Se muestra un mensaje/tooltip en pantalla indicando los campos faltantes». El hallazgo 17 dice que el alta no tiene el patrón de botón deshabilitado, y la card pide que el registro y la edición muestren cuáles faltan. Fuentes: CU-17, CU-21, CU-09, CU-03 y REVISION-kit3.md hallazgo 17.
- **La cita de CU-03 FA1 en el hallazgo 17 no es textual.** El hallazgo dice «Contradice CU-03 FA1 («presiona crear cuenta → se muestran los campos faltantes»)». El texto de CU-03 FA1 dice: paso de origen «Paso 2 del flujo principal»; condición «Falta completar algún campo obligatorio»; acción «Se muestra un mensaje/tooltip en pantalla indicando los campos faltantes». Fuentes: REVISION-kit3.md hallazgo 17; CU-03 (CU/CU-03 Registrar usuario.pdf).
- **Qué botón es «Cancelar» frente a «la opción que no destruye».** El pedido dice «foco en Cancelar» y REV-04-H18-05 dice «el foco empieza en la opción que no destruye». En CU-09, «Cancelar» es un Btn-Outline-Danger (texto y contorno rojo) y el texto dice «rojo para las acciones destructivas o de cancelación». En CU-21, «Cancelar» es Btn-Secondary sin relleno. La card no dice cuál botón de qué confirmación es la destructiva. Fuentes: pedido (texto); REV-04-H18-05; CU-09 (Componentes del Sistema de Diseño); CU-21 (Componentes).
- **«Botón atenuado» frente a «deshabilitado».** REV-04-H27-01 y el hallazgo 27 hablan de «el botón atenuado» (GUARDAR SEDE y GUARDAR ESPACIO). La card no dice si «atenuado» es el estado deshabilitado. CU-21 especifica «deshabilitado con opacidad 40% cuando faltan campos» para «Guardar espacio». Fuentes: REV-04-H27-01; REVISION-kit3.md hallazgo 27; CU-21 (Componentes del Sistema de Diseño).

Estas son las únicas que se ven en la lectura. No se encontró ninguna otra contradicción dentro de la card.
