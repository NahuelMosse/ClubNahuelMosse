---
card: CU-14
extraido: 2026-09-27T12:50:00-03:00
fuentes:
  - CU/CU-14_Especificacion_Francisco_Luciano.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 6 Historial de reservas · § RF 3 · § RF 7 · § RNF 5"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 55:251 CU-14 · Panel admin · Reservas · Todas · 55:482 · Activas · 55:656 · Completadas · 55:786 · Anuladas"
  - "Figma · 58:957 CU-14 · Panel admin · Cargando · 58:881 · Búsqueda activa · 58:798 · Resultados filtrados"
  - "Figma · 58:1140 CU-14 · Panel admin · Sin resultados · 58:1339 · Historial vacío"
  - "Figma · 60:1257 CU-14 · Panel admin · Panel de filtros · 60:1441 · Rango de fechas inválido"
  - "Figma · 59:1252 CU-14 · Panel admin · Detalle de reserva · 59:1336 · Detalle · Anulada"
  - "Figma · 42:442 Acceso denegado · 42:384 Error de conexión · 42:426 Sesión expirada (overlays compartidos)"
no_leido:
  - "las 18 capturas P-01 a P-18 embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-14 · Consultar historial global de reservas (admin)

## Card, tal como está escrita

**Definición** (fuente: CU-14)
- Actor principal: administrador del club (usuario autenticado con rol de administración). Actor
  secundario: el sistema de reservas, que provee los datos.
- Objetivo: «Acceder a la totalidad de las reservas registradas en el sistema de todas las sedes,
  todos los espacios y todos los usuarios, poder filtrarlas y consultar el detalle de cualquiera de
  ellas, para controlar el uso de las instalaciones y responder consultas o reclamos.»
- Problema que resuelve: «Mis reservas» está acotada al usuario; sin vista global no se sabe quién
  reservó, con qué frecuencia se usa cada cancha ni qué pasó con una reserva cancelada. Sirve para
  auditar, resolver reclamos, detectar usos indebidos o cancelaciones reiteradas y decidir horarios,
  precios y mantenimiento. «Es principalmente un flujo de consulta y auditoría; además, desde la
  misma vista el administrador puede anular una reserva vigente mediante una acción con
  confirmación, que libera la franja horaria.»

**Precondiciones** (fuente: CU-14)
- El administrador está autenticado y su sesión está vigente.
- La cuenta posee rol de Administrador, que habilita leer las reservas de todos y anular.
- Existe al menos una sede cargada y habilitada.
- Existe al menos una reserva registrada, vigente o histórica.
- La aplicación tiene conexión con la API de reservas.

**Poscondiciones** (fuente: CU-14)
- La consulta no modifica el estado del sistema: no crea ni edita reservas.
- Se muestra el listado de todos los usuarios, «agrupado por fecha y ordenado de la más reciente a la
  más antigua, con un contador de resultados».
- Los filtros y la búsqueda quedan visibles y pueden limpiarse.
- Si se anula una reserva vigente, «pasa al estado Cancelada, se libera la franja horaria y la
  anulación queda registrada con su trazabilidad (autor y fecha)».
- «La operación queda registrada en el log de auditoría del backend (fecha, administrador, filtros
  utilizados y acción realizada).»

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

**Flujos alternativos y de excepción** (fuente: CU-14)
- **FA1 · Sin resultados.** Origen: pasos 6 o 7. Estado vacío «Sin resultados», filtros activos
  visibles y «Limpiar filtros». Cubre también la búsqueda sin coincidencias.
- **FA2 · Error de conexión con el servidor.** Origen: pasos 1, 2, 6 o 7. Pantalla de error con
  «Reintentar» que repite la última consulta. Sin datos parciales ni desactualizados.
- **FA3 · Rango de fechas inválido.** Origen: paso 6. «desde» posterior a «hasta»: «Aplicar»
  deshabilitado, fechas en rojo, error en línea. No se consulta al servidor.
- **FA4 · Usuario sin rol de Administrador.** Origen: paso 1. La entrada al panel no se muestra; por
  enlace profundo, pantalla «Acceso denegado» y redirección a «Mis reservas».
- **FA5 · Sesión expirada.** Origen: cualquier paso. Al login conservando la intención; al volver,
  el historial con los filtros que tenía.
- **FA6 · Historial vacío.** Origen: paso 3. «No hay reservas», sin «Limpiar filtros».
- **FA7 · El administrador cancela la anulación.** Origen: paso 9. Cierra el diálogo sin cambios y
  vuelve a la vista anterior.
- **FA8 · Baja del espacio deportivo o de la sede.** Origen: pasos 3, 7 u 8. Las reservas afectadas
  pasan a Cancelada pero permanecen en el historial, y la tarjeta indica «Baja del espacio
  deportivo» para no atribuírselo al socio. El nombre técnico del espacio se conserva tal como
  estaba al reservar.

**Justificación de decisiones de diseño** (fuente: CU-14) — Anular exige confirmación y no elimina:
pasa a Cancelada con línea de tiempo de quién y cuándo. Dos estados vacíos distintos. Validación
del rango antes de consultar. Usuario visible en cada tarjeta. Motivo visible en las cancelaciones.
La búsqueda se combina con los filtros. Pestañas de estado separadas del panel de filtros. Modo día
y noche.

**Diseño declarado en el CU** (fuente: CU-14) — P-01 a P-18: Todas, Activas, Completadas, Anuladas,
panel de filtros, filtros con selección, resultados filtrados, búsqueda activa, detalle, detalle
anulada, confirmar anulación, sin resultados, cargando, error de conexión, rango inválido, acceso
denegado, historial vacío, modo nocturno. Chip de estado Activa, Completada o Cancelada. Panel con
pestañas Reservas, Sedes y Espacios.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 6: el historial incluye las reservas cuyo horario ya finalizó.
- RNF 5: las operaciones de la API sobre reservas identifican al usuario autenticado.

**Pantallas del prototipo** (fuente: Figma)
- Pestañas «Todas (48) · Activas (12) · Completadas (31) · Anuladas (5)», «48 RESERVAS EN TOTAL»,
  buscador «Buscar reserva…», «Filtros»; tarjetas con usuario y «ANULAR RESERVA» en las activas;
  pill ACTIVA, COMPLETADA, ANULADA.
- Detalle: TRAZABILIDAD con «Reserva creada · Por Nahuel Mosse · 02/11/2026 18:42»; anulada:
  «Anulada por el administrador · Por Admin Sistema · 28/10/2026 09:15 · mantenimiento de la
  cancha» y «Notificación enviada al usuario».
- Rango inválido: «Desde no puede ser posterior a Hasta».

## Escenarios

- [ ] CU-14-H01-01 — ve las reservas de todos los usuarios con usuario, sede, espacio, horario, precio y estado, y el total
- [ ] CU-14-H01-02 — una reserva recién hecha por un usuario aparece en el panel
- [ ] CU-14-H01-03 — las pestañas de estado filtran el listado y actualizan el contador
- [ ] CU-14-H01-04 — aplica filtros de sede, deporte y fechas y ve sólo las reservas que cumplen todos
- [ ] CU-14-H01-05 — busca por nombre de usuario y la búsqueda se combina con los filtros
- [ ] CU-14-H01-06 — abre el detalle y ve cuándo y quién creó la reserva
- [ ] CU-14-H01-07 — anula una reserva vigente con confirmación y el detalle muestra quién y cuándo la anuló
- [ ] CU-14-H01-08 — vuelve del detalle al listado con los mismos filtros
- [ ] CU-14-H02-01 — los filtros no encuentran nada y ve «Sin resultados» con «Limpiar filtros»
- [ ] CU-14-H03-01 — falla el servidor y ve el error con «Reintentar», sin datos parciales
- [ ] CU-14-H04-01 — pone «desde» después de «hasta» y no puede aplicar
- [ ] CU-14-H05-01 — un usuario sin rol de administrador no ve el panel y, si entra por enlace, ve «Acceso denegado»
- [ ] CU-14-H05-02 — la API rechaza la consulta global de reservas a un usuario sin rol de administrador
- [ ] CU-14-H06-01 — con la sesión vencida va al login y vuelve al historial con sus filtros
- [ ] CU-14-H07-01 — sin ninguna reserva en el sistema ve «No hay reservas», sin «Limpiar filtros»
- [ ] CU-14-H08-01 — cancela la anulación y la reserva queda igual
- [ ] CU-14-H09-01 — las reservas de un espacio dado de baja siguen en el historial marcadas «Baja del espacio deportivo»

## Contradicciones dentro de la card

- El CU anula dejando la reserva en estado «Cancelada»; CU-15 la deja «Anulada por
  administración»; el prototipo la muestra «ANULADA» en la pestaña «Anuladas» · CU-14 paso 9,
  CU-15 poscondiciones, Figma 55:786.
- FA8 da por hecho que se puede dar de baja un espacio o una sede con reservas, que pasan a
  Cancelada; CU-19 FA3 prohíbe la baja de una sede con reservas futuras · CU-14 FA8, CU-19 FA3.
- La anulación desde CU-14 no pide motivo; CU-15 hace el motivo obligatorio · CU-14 paso 9, CU-15
  paso 3.
- La poscondición dice que la consulta no modifica el estado del sistema y a la vez la registra en un
  log de auditoría con los filtros usados · CU-14 poscondiciones.
- En el prototipo, «Resultados filtrados» con «Sede: Morón» muestra reservas de Ramos Mejía;
  «Búsqueda activa» con «Nahuel» muestra reservas de otros usuarios; «Historial vacío» y «Sin
  resultados» mantienen los contadores en 48 · Figma 58:798, 58:881, 58:1339, 58:1140.
