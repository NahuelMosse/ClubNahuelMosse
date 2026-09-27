---
card: CU-12
extraido: 2026-09-27T11:40:00-03:00
fuentes:
  - CU/CU-12 - Consultar horarios disponibles.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 Gestión de reservas · § RF 4 («permitir seleccionar una sede para consultar sus espacios deportivos y horarios disponibles»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 45:359 CU-12 · Horarios disponibles · Grilla"
  - "Figma · 67:984 CU-12 · Horarios disponibles · Duración 2 horas"
  - "Figma · 334:6228 CU-12 · Horarios disponibles · Duración 3 horas"
  - "Figma · 47:555 CU-12 · Horarios disponibles · Sin horarios"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las capturas de cada flujo embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-12 · Consultar horarios disponibles

## Card, tal como está escrita

**Definición** (fuente: CU-12)
- Actor principal: Usuario registrado.
- Objetivo: «Mostrar al usuario las franjas horarias libres de un espacio deportivo —pudiendo
  filtrar por cancha (cuando el espacio tiene más de una del mismo tipo), fecha y duración—,
  respetando el horario de funcionamiento de la sede, para que pueda decidir si quiere reservar.»
- Problema que resuelve: saber, antes de reservar, qué horarios están realmente disponibles —libres,
  dentro del horario de la sede y en el futuro—, evitando intentar reservar sobre horarios inválidos
  u ocupados.

**Precondiciones** (fuente: CU-12)
- El usuario debe estar autenticado en la aplicación.
- Debe existir al menos una sede con espacios deportivos habilitados.
- El usuario ya se encuentra en la pantalla de horarios de un espacio deportivo (sede y espacio ya
  elegidos).

**Poscondiciones** (fuente: CU-12)
- El sistema muestra la grilla de horarios disponibles para el espacio, la fecha y la duración
  seleccionados.
- Si el usuario seleccionó una franja, el sistema la refleja en la tarjeta de resumen y habilita la
  continuación hacia la reserva.
- «Ninguno de estos pasos modifica el estado del sistema: la selección no crea, bloquea ni reserva
  horarios». La creación y confirmación de la reserva quedan a cargo de un caso de uso distinto.

**Flujo principal** (fuente: CU-12)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario ingresa a la pantalla de horarios del espacio deportivo. | El sistema muestra la grilla de horarios con los valores por defecto (cancha única o principal, fecha actual, duración de 1 hora): habilita las franjas de hora completa libres y futuras, y muestra deshabilitadas las ya ocupadas, dentro del horario de la sede. |
| 2 | El usuario toca una franja horaria disponible. | El sistema marca la franja seleccionada y actualiza la tarjeta de resumen (espacio, precio, horario elegido y total), habilitando el botón de acción. |
| 3 | El usuario presiona el botón habilitado. | El sistema da lugar al caso de uso Reservar cancha, transfiriéndole la sede, el espacio, la fecha y el horario seleccionados. Seleccionar una franja no modifica el estado del sistema. |

**Flujos alternativos y de excepción** (fuente: CU-12)
- **FA1 · Cambia la fecha de consulta.** Origen: paso 1. Sistema: recalcula la grilla para la fecha
  elegida con las mismas reglas (horas completas, dentro del horario de la sede, futuras, libres
  habilitadas y ocupadas deshabilitadas).
- **FA2 · Cambia la cancha consultada.** Origen: paso 1. Condición: el espacio tiene más de una
  cancha del mismo tipo (ej. Cancha 1 / Cancha 2). Sistema: recalcula la grilla para la cancha
  elegida.
- **FA3 · Cambia la duración de la consulta.** Origen: paso 1. Condición: quiere franjas de 2 horas
  en lugar de 1. Sistema: «para 2 horas, solo habilita inicios cuya franja siguiente también esté
  libre y cuya finalización no supere el cierre de la sede.»
- **FA4 · No hay horarios disponibles para la combinación elegida.** Origen: paso 1 o tras FA1 a
  FA3. Condición: no queda ninguna franja libre —todas ocupadas, la sede no opera ese día, o para 2
  horas no hay dos franjas contiguas libres antes del cierre. Sistema: reemplaza la grilla por un
  estado vacío indicando que no hay horarios disponibles y sugiere cambiar la fecha.
- **FA5 · Error de conexión a Internet.** Origen: paso 1. Sistema: alerta de falta de conexión y pide
  reintentar. No se muestran horarios.
- **FA6 · Error en el servidor / falla en la API.** Origen: paso 1. Sistema: informa el error del
  servidor y pide reintentar más tarde. No se muestran horarios.

**Justificación de decisiones de diseño** (fuente: CU-12)
- El selector de cancha va en la misma pantalla de horarios.
- El selector de fecha arranca siempre en el día actual y muestra los próximos días en chips
  horizontales, evitando elegir una fecha pasada.
- La duración se elige con un toggle simple (1 hora / 2 horas) en lugar de un selector de horario
  libre: «las reservas son de hora completa, con un mínimo de 1 hora».
- «La grilla no diferencia visualmente los horarios ocupados de los disponibles —comparten el mismo
  estilo— y la nota "Algunos horarios están ocupados · N no disponibles" informa la proporción
  general».
- Sin horarios: estado dedicado «No hay horarios disponibles» con la sugerencia de cambiar de fecha.
- El botón principal queda deshabilitado mientras no haya una selección válida.
- Errores de conexión y servidor con el mismo formato: título en rojo, texto y botón «Aceptar».

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 3: dentro del funcionamiento de la sede; mínimo una hora; inicio y fin en minuto 00; fin no
  posterior al cierre; horarios futuros; sin superposición en el mismo espacio y fecha.

**Pantallas del prototipo** (fuente: Figma)
- SELECCIONÁ CANCHA (Cancha 1 · Al aire libre / Cancha 2 · Techada), FECHA en chips de siete días,
  DURACIÓN con stepper («1 hora» … «4 horas») y la leyenda «Horas completas, de 1 a 4 h. La sede
  cierra a las 23:00.»
- Grilla de todas las horas de 08:00 a 23:00 y la nota «Algunos horarios ya están ocupados · 6 no
  disponibles»; resumen «$38.000 × 1 · TOTAL $38.000»; botón CONTINUAR.
- 2 y 3 horas: «Con 2 horas hay menos inicios posibles · 9 no disponibles», totales $76.000 y
  $114.000.
- 4 horas: «No hay horarios disponibles · Con 4 horas seguidas no entra ningún turno antes del
  cierre. Probá con una duración menor, otra fecha u otra cancha.»

## Escenarios

- [ ] CU-12-H01-01 — abre los horarios con cancha, fecha de hoy y 1 hora por defecto, y sólo puede elegir franjas libres y futuras
- [ ] CU-12-H01-02 — una franja que otra persona ya reservó aparece no disponible
- [ ] CU-12-H01-03 — elige una franja y el resumen muestra el horario y el total; continuar lleva a reservar
- [ ] CU-12-H01-04 — el botón para continuar está deshabilitado mientras no eligió franja
- [ ] CU-12-H02-01 — cambia la fecha y la grilla se recalcula para ese día
- [ ] CU-12-H03-01 — cambia de cancha y la grilla se recalcula para esa cancha
- [ ] CU-12-H04-01 — con 2 horas sólo se ofrecen inicios con las dos horas libres y fin antes del cierre
- [ ] CU-12-H04-02 — con más horas vale la misma regla y el total es precio por hora por duración
- [ ] CU-12-H05-01 — no queda ninguna franja libre y ve el estado vacío con la sugerencia
- [ ] CU-12-H05-02 — elige un día en que la sede no abre y ve el estado vacío
- [ ] CU-12-H06-01 — sin conexión, ve la alerta y ningún horario
- [ ] CU-12-H07-01 — el servidor falla y no se muestran horarios

## Contradicciones dentro de la card

- El CU fija la duración en un toggle «1 hora / 2 horas»; el prototipo tiene un stepper de 1 a 4
  horas; el enunciado sólo pone mínimo una hora y el cierre de la sede como tope · CU-12 FA3 y
  justificación, Figma 45:359 y 334:6228, enunciado RF 3.
- El paso 1 muestra «deshabilitadas las ya ocupadas»; la justificación dice que la grilla «no
  diferencia visualmente los horarios ocupados de los disponibles» · CU-12 paso 1, justificación.
- El CU habla de un «espacio» con varias canchas del mismo tipo; el enunciado define el espacio con
  un nombre que ya lleva número (`…_Paddle_1`), o sea cada cancha es un espacio · CU-12 FA2,
  enunciado RF 5.
- FA4 contempla que «la sede no opera ese día»; ningún CU de sedes (CU-17, CU-18) carga días de
  funcionamiento, y el prototipo sí los muestra («Lunes a sábado») · CU-12 FA4, Figma 53:319.
- Los errores se cierran con «Aceptar» según el CU; el overlay compartido de conexión tiene
  «REINTENTAR» y «Volver» · CU-12 justificación, Figma 42:384.
