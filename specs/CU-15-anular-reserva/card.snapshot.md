---
card: CU-15
extraido: 2026-09-27T12:50:00-03:00
fuentes:
  - CU/CU-15-Anular-reserva-admin.docx.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 («Al cancelar una reserva, el espacio deportivo deberá volver a estar disponible para ese mismo horario.») · § RF 7"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 55:482 CU-14 · Panel admin · Reservas · Activas (origen: «ANULAR RESERVA»)"
  - "Figma · 60:1559 CU-15 · Anular reserva · Con motivo"
  - "Figma · 60:1595 CU-15 · Anular reserva · Sin motivo"
  - "Figma · 59:1336 CU-14 · Panel admin · Detalle · Anulada"
  - "Figma · 393:6532 Algo cambió mientras tanto · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las capturas del flujo embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-15 · Anular reserva (admin)

## Card, tal como está escrita

**Definición** (fuente: CU-15)
- Actor principal: Administrador.
- Objetivo: «Permitir que un administrador anule una reserva activa por una causa operativa, deje
  registrado el motivo y libere el turno para nuevas reservas.»
- Problema que resuelve: «Permite actuar ante mantenimiento, indisponibilidad del espacio, errores
  de carga u otras situaciones que impiden cumplir una reserva confirmada.»

**Precondiciones** (fuente: CU-15)
- El administrador debe estar autenticado y contar con permisos de administración.
- La reserva debe existir, estar activa y corresponder a un horario futuro.
- El sistema debe haber cargado los datos de la reserva.

**Poscondiciones** (fuente: CU-15)
- La reserva queda registrada como Anulada por administración, con motivo, fecha, hora y
  administrador responsable.
- El espacio y la franja horaria quedan disponibles para nuevas reservas.
- La reserva deja de aparecer entre las activas y pasa al listado de anuladas.
- El sistema solicita el envío de una notificación al usuario afectado.

**Flujo principal** (fuente: CU-15)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El administrador abre la sección Reservas desde el panel de administración. | El sistema valida la sesión y muestra las reservas del club. |
| 2 | El administrador localiza una reserva activa y presiona Anular. | El sistema abre la confirmación con la sede, la cancha, el usuario, la fecha, el horario y el importe de la reserva. |
| 3 | El administrador escribe el motivo de la anulación. | El sistema exige un motivo antes de habilitar la confirmación. |
| 4 | El administrador presiona Confirmar anulación. | El sistema comprueba que la reserva siga activa y envía la solicitud al servidor. |
| 5 | El administrador espera el resultado. | El sistema registra la anulación administrativa, libera el turno, solicita la notificación al usuario y muestra el mensaje Reserva anulada correctamente. |

**Flujos alternativos y de excepción** (fuente: CU-15)
- **FA1 · El administrador desiste.** Origen: paso 4. Presiona Volver antes de confirmar: cierra la
  confirmación y vuelve a la pantalla de origen. La reserva no cambia.
- **FA2 · Falta el motivo.** Origen: paso 3. Indica que el campo es obligatorio y no envía la
  solicitud.
- **FA3 · La reserva ya no está activa.** Origen: paso 4. Condición: fue modificada, cancelada o
  comenzó antes de procesar la solicitud. Rechaza la anulación, informa que ya no puede anularse y
  actualiza el listado.
- **FA4 · Error al procesar la anulación.** Origen: paso 5. Condición: se pierde la conexión o el
  servidor devuelve un error. Pantalla «No pudimos anular la reserva», con reintentar o volver. La
  reserva conserva su estado anterior mientras no haya confirmación del servidor.

**Diseño declarado en el CU** (fuente: CU-15) — Panel admin · Confirmar anulación · Reserva anulada ·
Error al anular.

**Pantallas del prototipo** (fuente: Figma)
- Confirmación: «¿Anular esta reserva?» con Usuario, Sede, Cancha («Fútbol 5 · Cancha 1»), Cuándo,
  Importe; MOTIVO DE LA ANULACIÓN; CONFIRMAR ANULACIÓN · VOLVER.
- Sin motivo: «El motivo es obligatorio para anular».
- Detalle anulada (CU-14): «Anulada por el administrador · Por Admin Sistema · 28/10/2026 09:15 ·
  mantenimiento de la cancha» y «Notificación enviada al usuario · 28/10/2026 09:15».

## Escenarios

- [ ] CU-15-H01-01 — anula una reserva activa con motivo y queda anulada con motivo, fecha, hora y administrador
- [ ] CU-15-H01-02 — después de anular, otro usuario puede reservar ese horario
- [ ] CU-15-H01-03 — el usuario afectado ve la reserva anulada en su historial con el motivo
- [ ] CU-15-H01-04 — la API rechaza la anulación pedida por un usuario sin rol de administrador
- [ ] CU-15-H02-01 — vuelve atrás desde la confirmación y la reserva sigue activa
- [ ] CU-15-H03-01 — intenta confirmar sin motivo, ve que es obligatorio y no se anula
- [ ] CU-15-H04-01 — la reserva fue cancelada por el usuario mientras tanto y la anulación se rechaza
- [ ] CU-15-H04-02 — la reserva ya empezó y la anulación se rechaza
- [ ] CU-15-H05-01 — falla la conexión o el servidor y la reserva queda como estaba

## Contradicciones dentro de la card

- El CU deja la reserva «Anulada por administración»; CU-14 la deja «Cancelada»; el prototipo, «ANULADA»
  · CU-15 poscondiciones, CU-14 paso 9, Figma 55:786.
- La precondición exige horario futuro y FA3 rechaza una reserva que «comenzó»; CU-14 permite anular
  una reserva «vigente» · CU-15 precondiciones, CU-14 paso 9.
- El CU cierra con el mensaje «Reserva anulada correctamente»; el prototipo no tiene esa pantalla y
  muestra directamente el detalle anulado · CU-15 paso 5, Figma 59:1336.
- El CU nombra la pantalla «No pudimos anular la reserva»; el prototipo usa los overlays compartidos
  · CU-15 FA4, Figma 42:384 y 42:410.
