---
card: CU-09
extraido: 2026-09-27T14:20:00-03:00
fuentes:
  - CU/CU-09_Reservar_cancha_MartinGaser .pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 Gestión de reservas · § RF 7 Manejo de errores · § RNF 5 («Las operaciones de la API relacionadas con usuarios y reservas deberán identificar al usuario autenticado.»)"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 48:123 CU-09 · Confirmar reserva · 334:6366 · 2 horas · 334:6410 · 3 horas"
  - "Figma · 48:183 CU-09 · Reserva confirmada · 334:6454 · 2 horas · 334:6493 · 3 horas"
  - "Figma · 393:6553 CU-09 · Horario ya reservado (overlay)"
  - "Figma · 45:359 CU-12 · Horarios disponibles · Grilla (origen)"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor · 42:426 Sesión expirada (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-09 · Reservar cancha

Doble lectura: dos lecturas independientes del CU y del enunciado, más la propia contra Figma.

## Card, tal como está escrita

**Definición** (fuente: CU-09)
- Actor principal: Usuario registrado.
- Objetivo: «Permitir que el usuario registrado reserve una cancha disponible, eligiendo sede,
  cancha, fecha y horario, para asegurarse su turno de juego.»
- Problema que resuelve: «Elimina la necesidad de reservar turnos de forma manual o telefónica,
  permitiendo al usuario autogestionar su reserva en tiempo real y evitando superposiciones de
  horarios en una misma cancha.»

**Precondiciones** (fuente: CU-09)
- El usuario debe estar autenticado en la plataforma.
- Debe existir al menos una sede cargada y habilitada.
- La cancha debe estar en estado "Habilitada" y tener horarios cargados.

**Poscondiciones** (fuente: CU-09)
- La reserva queda registrada en estado "Confirmada", asociada al usuario, la cancha, la fecha y el
  horario elegidos.
- Se descuenta la disponibilidad de ese horario para esa cancha y fecha, quedando bloqueado para
  otros usuarios.
- Se envía una notificación/correo de confirmación de la reserva al usuario.

**Flujo principal** (fuente: CU-09)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario selecciona la sede deseada. | El sistema carga y muestra las canchas disponibles para esa sede. |
| 2 | Selecciona la cancha deseada. | El sistema habilita el selector de fecha y muestra el calendario de disponibilidad. |
| 3 | Selecciona la fecha deseada. | El sistema consulta y despliega las franjas horarias disponibles para esa cancha y fecha. |
| 4 | Selecciona el horario deseado. | El sistema habilita el botón "Confirmar Reserva" y muestra el resumen (cancha, fecha, horario y costo). |
| 5 | Presiona "Confirmar Reserva". | El sistema valida los datos, registra la reserva en estado "Confirmada" e informa la confirmación al usuario. |

**Flujos alternativos y de excepción** (fuente: CU-09)
- **FA1 · Horario No Disponible.** Origen: paso 4. Condición: el horario ya no está libre (otro
  usuario lo reservó primero). Sistema: advertencia «El horario seleccionado ya no está disponible.
  Por favor elija otro turno», deshabilita el botón de confirmación y actualiza la grilla.
- **FA2 · Datos Incompletos o Inválidos.** Origen: cualquier paso. Condición: falta seleccionar algún
  campo obligatorio (cancha, fecha u horario). Sistema: «Confirmar Reserva» permanece deshabilitado;
  tooltip o mensaje indicando el campo faltante.
- **FA3 · Usuario No Autenticado.** Origen: al intentar ingresar al flujo. Condición: la sesión expiró
  o no inició sesión. Sistema: redirecciona al Login, «guardando el estado o intención previa de
  reserva de cancha».

**Diseño declarado en el CU** (fuente: CU-09)
- Pantalla 1 «Confirmá tu reserva»: tarjeta con la cancha, el día, el horario, el precio y el botón
  de confirmar. Pantalla 2 «Comprobante de Reserva Confirmada»: «automaticamente te redirige a la
  sección en la aplicación de tus reservas». Variantes en modo nocturno.
- Stepper de 3 pasos (Elegí cancha / Confirmás / ¡Listo!); Link-Breadcrumb «< Sedes»; Card-Reserva
  con banner del deporte y la sede; filas Cancha, Fecha, Horario, Total (ejemplo «$7.600» en lima);
  Btn-Primary «CONFIRMAR RESERVA»; Btn-Outline-Danger «Cancelar».

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 3: «Una reserva corresponde a un espacio deportivo, una fecha, una hora de inicio y una hora de
  finalización.» Mínimo una hora; inicio y fin en minuto 00; fin no posterior al cierre de la sede;
  «Las reservas deberán realizarse para horarios futuros»; «dicho espacio no podrá ser reservado por
  otro usuario para la misma fecha si existe superposición de horarios. El backend deberá validar la
  disponibilidad del espacio deportivo antes de registrar una reserva.» «Recibir notificaciones push
  sobre reservas próximas.»
- RF 7: manejar sin conexión y servidor caído.
- RNF 5: la API identifica al usuario autenticado.

**Pantallas del prototipo** (fuente: Figma)
- Confirmación: stepper, «Fútbol 5 · SEDE MORÓN», filas Cancha («Cancha 1 · Al aire libre»), Fecha,
  Horario («18:00 – 19:00 · 1 hora»), TOTAL; CONFIRMAR RESERVA · CANCELAR. Variantes de 2 y 3 horas
  con sus totales.
- Confirmada: «¡Reserva confirmada!» · «Te esperamos. Te vamos a avisar una hora antes.» · Espacio
  (código completo), Fecha, Horario, Total · VER MIS RESERVAS · Volver al inicio.
- Horario ocupado: «Ese horario se ocupó» · «Mientras confirmabas, otra persona reservó Cancha 1 ·
  Jue 12, 18:00 – 19:00. Elegí otro horario disponible.» · ELEGIR OTRO HORARIO.

## Escenarios

`H01` es el flujo principal; `H02` a `H04` son FA1 a FA3; `H05` son los errores que pide el
enunciado (RF 7) y el CU no trae.

- [ ] CU-09-H01-01 — confirma la reserva y aparece activa en Mis reservas con sede, espacio, fecha, horario y total
- [ ] CU-09-H01-02 — después de reservar, ese horario aparece no disponible para otro usuario
- [ ] CU-09-H01-03 — reserva varias horas seguidas y el total es el precio por hora por la duración
- [ ] CU-09-H01-04 — el backend rechaza una reserva en un horario pasado
- [ ] CU-09-H01-05 — el backend rechaza una reserva que termina después del cierre de la sede
- [ ] CU-09-H01-06 — el backend rechaza una reserva que no empieza o no termina en hora completa
- [ ] CU-09-H01-07 — toca Cancelar en la confirmación y no se crea ninguna reserva
- [ ] CU-09-H01-08 — el backend rechaza una reserva de menos de una hora
- [ ] CU-09-H01-09 — desde el comprobante va a Mis reservas o vuelve al inicio
- [ ] CU-09-H02-01 — otra persona reservó ese horario mientras confirmaba: ve el aviso y no se crea la reserva
- [ ] CU-09-H02-02 — el backend rechaza una reserva que se superpone en parte con otra del mismo espacio
- [ ] CU-09-H03-01 — sin horario elegido, el botón de confirmar está deshabilitado
- [ ] CU-09-H04-01 — con la sesión vencida va al login y, al volver a entrar, retoma la reserva que tenía en curso
- [ ] CU-09-H05-01 — sin conexión al confirmar, ve el error y la reserva no se crea
- [ ] CU-09-H05-02 — el servidor falla al confirmar y la reserva no se crea

## Contradicciones dentro de la card

- El CU modela el horario como una franja de la grilla; el enunciado define la reserva con hora de
  inicio y de finalización, de una hora o más · CU-09 pasos 3–4, enunciado RF 3.
- La poscondición envía «notificación/correo de confirmación»; el enunciado pide notificaciones push
  de reservas próximas, y el prototipo dice «Te vamos a avisar una hora antes» · CU-09
  poscondiciones, enunciado RF 3, Figma 48:183.
- El CU registra la reserva en estado «Confirmada»; el prototipo la muestra como «ACTIVA» en Mis
  reservas y CU-11 habla de «estado Activa» · CU-09 poscondiciones, Figma 49:434, CU-11
  precondiciones.
- El CU dice que el comprobante «automaticamente te redirige» a Mis reservas; el prototipo espera
  que el usuario toque VER MIS RESERVAS o «Volver al inicio» · CU-09 diseño, Figma 48:183.
- El mensaje de FA1 del CU es «El horario seleccionado ya no está disponible. Por favor elija otro
  turno»; el prototipo dice «Ese horario se ocupó […] Elegí otro horario disponible.» · CU-09 FA1,
  Figma 393:6553.
- El enunciado no menciona precio ni costo; el CU y el prototipo muestran costo y total · CU-09
  paso 4, enunciado RF 3.
- El CU no trae flujos de error de conexión ni de servidor; el enunciado los exige · CU-09, enunciado
  RF 7.
