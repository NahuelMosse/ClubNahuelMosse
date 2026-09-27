---
card: CU-17
extraido: 2026-09-27T12:30:00-03:00
fuentes:
  - CU/CU-17-Alta de sede.docx.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 4 Módulo de Sedes («Cada sede deberá contar, como mínimo, con un nombre, una dirección y horarios de funcionamiento.»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 62:1648 CU-17 · Gestionar sedes"
  - "Figma · 62:1828 CU-17 · Alta de sede · Formulario"
  - "Figma · 62:1903 CU-17 · Alta de sede · Campos faltantes"
  - "Figma · 64:2050 CU-17 · Alta de sede · Éxito"
  - "Figma · 42:442 Compartido · Acceso denegado · 42:384 Error de conexión · 42:410 Error del servidor (overlays)"
no_leido:
  - "las capturas del flujo embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-17 · Alta de sede

## Card, tal como está escrita

**Definición** (fuente: CU-17)
- Actor principal: Administrador.
- Objetivo: «Permitir que un administrador registre una nueva sede al sistema».
- Problema que resuelve: expandir la disponibilidad incorporando nuevas ubicaciones, «habilitando la
  carga de su nombre, dirección y horarios para que posteriormente los usuarios puedan consultar sus
  espacios deportivos y disponibilidad».

**Precondiciones** (fuente: CU-17) — El administrador debe estar autenticado y contar con permisos de
administración.

**Poscondiciones** (fuente: CU-17)
- La nueva sede queda registrada permanentemente en la base de datos con su nombre, dirección y
  horarios de funcionamiento.
- La nueva sede pasa a mostrarse en el listado general de sedes.

**Flujo principal** (fuente: CU-17)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El administrador accede a la sección de "Sedes" o "Gestionar Sedes" desde el menú. | El sistema valida la sesión y muestra el listado actual de sedes del club junto con la opción "Agregar Sede". |
| 2 | El administrador presiona el botón "Agregar Sede". | El sistema despliega el formulario de alta, solicitando los campos obligatorios: Nombre, Dirección y Horarios de funcionamiento. |
| 3 | El administrador completa los datos (Nombre, Dirección y Horarios) y presiona "Guardar". | El sistema valida que todos los campos obligatorios estén completos, confirma el registro, muestra un mensaje de éxito y actualiza el listado de sedes mostrando la nueva incorporación. |

**Flujos alternativos y de excepción** (fuente: CU-17)
- **FA1 · El administrador desiste.** Origen: paso 1. Condición: presiona Volver antes de confirmar.
  Sistema: descarta los datos, cierra el formulario y vuelve al listado sin cambios.
- **FA2 · Faltan datos obligatorios.** Origen: paso 3. Condición: intenta guardar sin nombre,
  dirección u horarios. Sistema: detiene el envío, resalta en rojo los campos faltantes e indica que
  son obligatorios.
- **FA3 · Error al procesar el alta.** Origen: paso 3. Condición: se pierde la conexión o el servidor
  devuelve un error. Sistema: pantalla o alerta «Error al guardar la sede»; el administrador conserva
  los datos y puede pulsar «Reintentar» o «Volver».

**Diseño declarado en el CU** (fuente: CU-17)
- Pantallas: listado de sedes (admin) con sus horarios y «Agregar Sede» · formulario con Nombre,
  Dirección y selectores de horario · confirmación de éxito · error de carga con reintento.
- BottomNav o menú lateral; tarjetas con nombre, dirección y horarios; Inputs y Dropdowns o Time
  pickers; botones «Agregar Sede», «Guardar», «Volver», «Reintentar»; Toast o modal de éxito y error.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 4: nombre, dirección y horarios de funcionamiento como mínimo.

**Pantallas del prototipo** (fuente: Figma)
- Gestionar sedes: «PANEL ADMIN · Sedes · + AGREGAR SEDE · 4 SEDES ACTIVAS»; por sede nombre,
  dirección, cantidad de canchas (7, 4, 8, 5), días y horario, «Editar sede», «Dar de baja».
- Formulario: «Nombre, dirección y horarios son obligatorios.»; NOMBRE DE LA SEDE, DIRECCIÓN
  («Calle y altura»), HORARIO DE APERTURA, HORARIO DE CIERRE; GUARDAR SEDE.
- Faltantes: «La dirección es obligatoria», «El horario de cierre es obligatorio».
- Éxito: «¡Sede creada!» · «La sede ya aparece en el listado y podés empezar a cargarle espacios
  deportivos.» · IR AL LISTADO · Crear otra sede.

## Escenarios

- [ ] CU-17-H01-01 — da de alta una sede con nombre, dirección y horario, y aparece en el listado de sedes de los usuarios
- [ ] CU-17-H01-02 — la sede recién creada aparece sin canchas hasta que se le cargan espacios
- [ ] CU-17-H01-03 — un usuario sin rol de administrador no puede dar de alta una sede
- [ ] CU-17-H02-01 — vuelve atrás desde el formulario y no se crea nada
- [ ] CU-17-H03-01 — intenta guardar sin dirección o sin horario y se le marcan los campos obligatorios
- [ ] CU-17-H04-01 — sin conexión o con el servidor caído al guardar, ve el error y conserva lo cargado

## Contradicciones dentro de la card

- El listado del panel admin del prototipo cuenta 7, 4, 8 y 5 canchas por sede; el listado de
  usuario cuenta 7, 2, 4 y 4 para las mismas sedes · Figma 62:1648, Figma 53:319.
- El listado del prototipo muestra días de funcionamiento («Lunes a sábado»); el formulario sólo
  pide apertura y cierre · Figma 62:1648, Figma 62:1828.
- El CU pide «Error al guardar la sede» con «Reintentar» o «Volver»; el prototipo usa los overlays
  compartidos de conexión y servidor · CU-17 FA3, Figma 42:384 y 42:410.
- El CU no pide foto de la sede; el listado de usuario muestra una foto por sede · CU-17 paso 2,
  Figma 53:319.
