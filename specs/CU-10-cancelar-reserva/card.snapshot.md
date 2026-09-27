---
card: CU-10
extraido: 2026-09-27T12:05:00-03:00
fuentes:
  - CU/CU-10 - Cancelar Reserva.pdf
  - "enunciado: Trabajo Práctico_2026.docx.pdf § RF 3 («Cancelar una reserva. Al cancelar una reserva, el espacio deportivo deberá volver a estar disponible para ese mismo horario.») · § RF 6 Historial · § RF 7"
  - "Figma VUiZR6V4USuiyxRgtshhEn · 49:434 CU-08 · Mis reservas · Próximas (origen: botón CANCELAR)"
  - "Figma · 42:296 CU-10 · Cancelar reserva · Confirmar (overlay)"
  - "Figma · 42:312 CU-10 · Cancelar reserva · Éxito (overlay)"
  - "Figma · 393:6532 Compartido · Algo cambió mientras tanto (overlay)"
  - "Figma · 42:384 Error de conexión · 42:410 Error del servidor (overlays compartidos)"
no_leido:
  - "las imágenes de pantalla embebidas en el PDF del CU (pdftotext solo extrae texto)"
estado: propuesta
---

# Snapshot — CU-10 · Cancelar reserva

Doble lectura: dos lecturas independientes del CU y del enunciado, más la propia contra Figma.

## Card, tal como está escrita

**Definición** (fuente: CU-10)
- Actor principal: Usuario registrado.
- Objetivo: «Permitir al usuario dar de baja una reserva activa que haya realizado previamente,
  liberando automáticamente el espacio deportivo y la franja horaria para que quede disponible para
  otros usuarios».
- Problema que resuelve: «Permite gestionar imprevistos del usuario cuando no puede asistir al
  horario acordado y maximiza la disponibilidad de las canchas para el resto de la comunidad del
  club».

**Precondiciones** (fuente: CU-10)
- El usuario debe estar autenticado en la aplicación.
- El usuario debe contar con al menos una reserva activa (con fecha, horario futuro y monto).

**Poscondiciones** (fuente: CU-10)
- El estado de la reserva cambia a cancelada en la base de datos.
- El espacio deportivo en la fecha y rango horario cancelado queda inmediatamente liberado y
  disponible para nuevas reservas.
- La reserva deja de mostrarse en la sección de reservas activas y se refleja en el historial.

**Flujo principal** (fuente: CU-10)
| Paso | Actor | Sistema |
|---|---|---|
| 1 | El usuario accede a la sección "Mis Reservas" desde la barra de navegación o la Home Page. | El sistema consulta el backend y lista las reservas vigentes del usuario con: sede, espacio deportivo, fecha, horario y monto. |
| 2 | El usuario localiza la reserva que desea cancelar y presiona el botón "Cancelar reserva". | El sistema despliega un diálogo modal/popup de confirmación advirtiendo sobre la cancelación y solicitando reconfirmar la acción. |
| 3 | El usuario confirma la cancelación presionando "Confirmar" o "Aceptar". | El sistema envía la solicitud DELETE/PATCH a la API REST, actualiza el estado de la reserva, libera el cupo en la base de datos, muestra un mensaje de éxito ("Reserva cancelada con éxito") y actualiza la lista visual sin la reserva cancelada. |

**Flujos alternativos y de excepción** (fuente: CU-10)
- **FA1 · Desistimiento voluntario de la cancelación.** Origen: paso 3. Condición: presiona «Volver»
  o «Cancelar» en el diálogo. Sistema: cierra el diálogo sin peticiones al backend. «La reserva
  permanece activa en el listado y la franja horaria sigue bloqueada para terceros.»
- **FA2 · Error de conexión a Internet.** Origen: paso 3. Sistema: modal o pantalla «Error de
  conexión» con opción de reintentar. «La reserva permanece inalterada en el servidor.»
- **FA3 · Error en el servidor / falla en la API.** Origen: paso 3. Condición: timeout. Sistema:
  diálogo o banner «No se pudo cancelar la reserva en este momento. Intente más tarde» y «mantiene
  los datos locales consistentes con el servidor».
- **FA4 · Intento de cancelación sobre horario vencido o en curso.** Origen: paso 3. Condición: el
  horario ya se cumplió o comenzó mientras el usuario estaba en la pantalla. Sistema: el backend
  rechaza con código de validación de negocio (ej. HTTP 400); la app notifica que no es posible
  cancelar turnos pasados o en curso y recarga el listado moviendo la reserva al historial.

**Diseño declarado en el CU** (fuente: CU-10)
- Pantallas: «¿Querés cancelar la reserva?» con sede, cancha, fecha, hora y monto · modal o
  BottomSheet de confirmación · error de conectividad con reintento · error de servidor.
- Botones «Cancelar reserva» en la tarjeta y en el diálogo; «Volver» / «No cancelar».

**Reglas que sólo están en el enunciado** (fuente: enunciado)
- RF 3: «Al cancelar una reserva, el espacio deportivo deberá volver a estar disponible para ese
  mismo horario.» No fija plazo para cancelar.
- RF 6: el historial incluye las reservas cuyo horario ya finalizó.

**Pantallas del prototipo** (fuente: Figma)
- Confirmación: «¿Cancelar la reserva?» · «Fútbol 5 · Sede Morón · Jue 12, 21:00 – 22:00 · $38.000.
  El horario vuelve a quedar libre.» · CANCELAR RESERVA · NO CANCELAR.
- Éxito: «Reserva cancelada con éxito» · «El horario quedó liberado y la reserva pasó a tu
  historial.» · ACEPTAR.
- Historial (CU-08): estados COMPLETADA y ANULADA; no aparece un estado de cancelada por el usuario.

## Escenarios

- [ ] CU-10-H01-01 — cancela una reserva futura, ve el éxito y la reserva pasa al historial como cancelada
- [ ] CU-10-H01-02 — después de cancelar, otro usuario puede reservar ese mismo horario
- [ ] CU-10-H02-01 — desiste en la confirmación y la reserva sigue activa y el horario ocupado
- [ ] CU-10-H03-01 — sin conexión al confirmar, ve el error con reintento y la reserva sigue activa
- [ ] CU-10-H04-01 — el servidor falla al cancelar y la reserva sigue activa
- [ ] CU-10-H05-01 — intenta cancelar una reserva que ya empezó y se le informa que no se puede

## Contradicciones dentro de la card

- El paso 3 envía «DELETE/PATCH»; la poscondición cambia el estado a cancelada y la muestra en el
  historial, lo que un borrado no permite · CU-10 paso 3, poscondiciones.
- El CU rechaza cancelar una reserva vencida o en curso; el enunciado no fija ningún plazo para
  cancelar · CU-10 FA4, enunciado RF 3.
- La poscondición manda la reserva cancelada al historial; el historial del prototipo sólo tiene los
  estados COMPLETADA y ANULADA · CU-10 poscondiciones, Figma 49:544.
- El CU nombra el mensaje de error de servidor «No se pudo cancelar la reserva en este momento.
  Intente más tarde»; el prototipo usa el overlay compartido «No pudimos procesar la operación en
  este momento. Intentá más tarde.» · CU-10 FA3, Figma 42:410.
