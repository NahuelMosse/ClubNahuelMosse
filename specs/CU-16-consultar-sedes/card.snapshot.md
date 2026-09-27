---
card: CU-16
extraido: 2026-09-27T11:40:00-03:00
fuentes:
  - CU/CU-16 - Consultar sedes.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 4 Módulo de Sedes · § RF 5 Módulo de Espacios deportivos · § RF 3 («consultar la disponibilidad de espacios deportivos según la sede»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 53:319 CU-16 · Todas las sedes"
  - "Figma · 54:986 CU-16 · Sede sin canchas"
  - "Figma · 406:6534 CU-20 · Sede Ramos Mejía · 53:431 CU-20 · Sede Morón · Fútbol · Todos (pantalla de sede)"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-16 · Consultar sedes

## Card, tal como está escrita

**Definición** (fuente: CU-16)
- Actor principal: «Usuario registrado con sesión activa. El prototipo muestra la barra de
  navegación inferior en todas las pantallas del flujo, lo que implica sesión iniciada.»
- Objetivo: «Explorar las sedes del club, conocer sus datos y recorrer las canchas con las que
  cuenta cada una, hasta identificar la que le sirve para reservar.»
- Problema que resuelve: antes de reservar, el socio necesita saber qué sedes hay, dónde quedan,
  qué deportes ofrece cada una y con qué canchas cuenta. «El caso de uso es la puerta de entrada a
  la reserva: no modifica datos». «El acotamiento del listado mediante selectores de deporte y tipo
  no forma parte de este caso de uso: se especifica en el CU-20».

**Precondiciones** (fuente: CU-16)
- El usuario está autenticado en la plataforma y su sesión es válida.
- Existe al menos una sede cargada y habilitada, con sus canchas asociadas.
- Cada cancha tiene definidos deporte, tipo, condición indoor u outdoor, iluminación, franja
  horaria y precio por hora.

**Poscondiciones** (fuente: CU-16)
- El sistema muestra la sede elegida con el listado completo de sus canchas y los datos de cada una.
- No se modifica ningún dato: el caso de uso es de solo lectura.
- El usuario queda en condiciones de iniciar la reserva sobre la cancha elegida, lo que da paso al
  caso de uso de consulta de horarios.

**Flujo principal** (fuente: CU-16)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | Presiona Sedes en la barra de navegación inferior. | El sistema carga el listado de todas las sedes, cada una con su foto, nombre, dirección, cantidad de canchas y los deportes que ofrece. |
| 2 | Recorre el listado e identifica la sede que le interesa. | El sistema mantiene visible el resumen de cada sede junto al acceso Ver canchas. |
| 3 | Presiona Ver canchas en la sede elegida. | El sistema abre la pantalla de esa sede con su foto de portada, nombre y dirección. |
| 4 | Recorre el listado de canchas de la sede. | El sistema muestra todas las canchas de la sede con el contador total y, por cada una, su identificador y sus atributos. |
| 5 | Consulta la ficha de una cancha en particular. | El sistema muestra condición indoor u outdoor, iluminación, franja horaria y precio por hora, con el botón Ver horarios / Reservar habilitado, que entrega el control al caso de uso de consulta de horarios. |

**Flujos alternativos y de excepción** (fuente: CU-16)
- **FA1 · Sede sin canchas habilitadas.** Origen: paso 3. Condición: la sede existe y está
  habilitada pero no tiene ninguna cancha asociada. Sistema: muestra la portada con nombre y
  dirección y, en lugar del listado, un mensaje indicando que todavía no hay canchas disponibles.
  El contador queda en cero.
- **FA2 · El usuario vuelve al listado de sedes.** Origen: paso 5. Sistema: el control Todas las
  sedes de la cabecera devuelve al listado general «conservando la posición de lectura previa».
- **Excepción 1 · Sin conexión.** Origen: cualquier paso. Sistema: modal «Error de conexión» con
  opción de reintentar, conservando la pantalla en la que estaba el usuario.
- **Excepción 2 · Error del servidor.** Origen: pasos 1 o 5. Sistema: modal «Error del servidor».
  «No se muestran datos parciales ni desactualizados.»

**Diseño declarado en el CU** (fuente: CU-16)
- Pantallas: todas las sedes · Sede Morón con sus canchas · Sede Ramos Mejía con sus canchas · Sede
  Castelar · Sede Ramos Mejía sin canchas · error de conectividad · error del servidor.
- Btn-Primary «Ver horarios / Reservar» habilitado y deshabilitado; Btn-Text «Ver canchas» y «Todas
  las sedes». Card-Sede (foto, nombre, dirección, contador, chips de deportes) y Card-Cancha
  (insignia de tipo, identificador, condición, iluminación, franja horaria, precio por hora).
  Empty-State para el listado sin sedes y para la sede sin canchas. Badge-Estado sobre la tarjeta
  cuando la cancha no está disponible.

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 4: «Cada sede deberá contar, como mínimo, con un nombre, una dirección y horarios de
  funcionamiento.» «Mostrar el listado de sedes, sus horarios de funcionamiento y permitir
  seleccionar una sede para consultar sus espacios deportivos y horarios disponibles.»
- RF 5: «Mostrar el listado de espacios deportivos indicando la sede donde se ubica cada uno.»
  Nombre compuesto por sede, dirección, tipo y número, por ejemplo `Moron_Rivadavia_19850_Paddle_1`.

**Pantallas del prototipo** (fuente: Figma)
- Listado: «4 sedes · 17 canchas · cada una con su horario»; por sede: puntaje (4,8 · 4,5 · 4,6 ·
  4,7), nombre, dirección, días y horario (por ejemplo «Lunes a sábado · 09:00 a 22:00»), cantidad
  de canchas, chips de deportes, «Ver canchas».
- Sede sin canchas: Sede Haedo, «0 CANCHAS», «Todavía no hay canchas», «Esta sede no tiene canchas
  disponibles por el momento.»
- Tarjeta de cancha: identificador, «Al aire libre» / «Techada», «Iluminada», precio «/ HORA»,
  descripción, «VER HORARIOS / RESERVAR».

## Escenarios

- [ ] CU-16-H01-01 — ve el listado de sedes con nombre, dirección, horario, cantidad de canchas y deportes
- [ ] CU-16-H01-02 — entra a una sede y ve todas sus canchas con el contador total y los datos de cada una
- [ ] CU-16-H01-03 — una sede recién cargada con su cancha aparece en el listado con esa cancha
- [ ] CU-16-H01-04 — desde una cancha pasa a consultar sus horarios
- [ ] CU-16-H02-01 — entra a una sede sin canchas y ve el aviso con el contador en cero
- [ ] CU-16-H03-01 — vuelve a «Todas las sedes» desde una sede
- [ ] CU-16-H04-01 — sin conexión, ve el error con opción de reintentar y sigue en la misma pantalla
- [ ] CU-16-H05-01 — el servidor falla y no se muestran datos parciales

## Contradicciones dentro de la card

- El enunciado pide mostrar en el listado «sus horarios de funcionamiento»; el paso 1 del CU lista
  foto, nombre, dirección, cantidad de canchas y deportes, sin horario · enunciado RF 4, CU-16
  paso 1.
- El CU atribuye una «franja horaria» a cada cancha; el enunciado pone los horarios de
  funcionamiento en la sede · CU-16 precondiciones y paso 5, enunciado RF 4.
- El CU ubica el caso «sin canchas» en la Sede Ramos Mejía; en el prototipo la sede sin canchas es
  Sede Haedo, que además no aparece en el listado de «4 sedes» · CU-16 diseño, Figma 54:986 y 53:319.
- El prototipo muestra un puntaje por sede (4,8, 4,5…) que ningún CU ni el enunciado define · Figma
  53:319.
- El CU prevé un Badge-Estado para «cancha no disponible» y el botón Ver horarios / Reservar
  deshabilitado, sin decir cuándo una cancha no está disponible · CU-16 diseño.
